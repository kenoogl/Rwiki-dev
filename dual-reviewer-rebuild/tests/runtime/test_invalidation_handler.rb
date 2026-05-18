# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 8: invalidation handling と invalid-run triage
# 根拠: tasks.md Task 8、Requirement 6 受入 3・7・8、design「Invalidation Handling」
#       「Run Close Boundary」、設計再確定 finding 9（fail-closed marker 型一貫）、
#       基盤契約 runtime/validators/contracts/invalidation_marker.schema.json。
#
# 本テストは InvalidationHandler（runtime 所有・validation 層の独立モジュール）の
#   - invalidation を raw evidence 編集ではなく validation/invalidation_markers.json
#     への追加で表現（受入 3、raw step outputs 不変）
#   - 4 自動 marker（missing required artifact / unresolved prompt identity /
#     run close without sign-off / treatment-step mismatch）
#   - 人間判断要（contamination / hidden intervention）の human-issued marker
#   - marker が invalidation_marker.schema.json の必須形に準拠（再定義しない）
#   - derived/invalid_run_triage_note.json 4 項目（primary failure code /
#     failed validator check ids / invalidation marker linkage / operator
#     action hint）
#   - 第1波 controller fail-closed marker と reason_code 型・形式が一貫
#   - Run Close Boundary 後の生成順序（marker → triage → metadata 更新）
# を決定的に検証する。外部依存なし、repo 内完結。
class TestInvalidationHandler < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  SCHEMA_REQUIRED = %w[
    run_id reason_code reason_detail scope issued_by issued_at
  ].freeze

  def setup
    require_relative "../../runtime/execution_v2/validation/invalidation_handler"
    require_relative "../../runtime/execution_v2/validation/validation_bridge"
    require_relative "../../runtime/controller/session_controller"
    @dir = Pathname(Dir.mktmpdir)
    @handler = DualReviewer::Runtime::ExecutionV2::InvalidationHandler.new
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def schema
    JSON.parse(
      (ROOT + "runtime/validators/contracts/invalidation_marker.schema.json").read
    )
  end

  def assert_schema_conformant(marker)
    SCHEMA_REQUIRED.each do |f|
      assert marker.key?(f), "marker に必須項目 #{f} がない: #{marker.inspect}"
      refute_nil marker[f], "marker 必須項目 #{f} が nil"
    end
    enum = schema.fetch("properties").fetch("scope").fetch("enum")
    assert_includes enum, marker.fetch("scope"),
                    "scope が schema enum 外: #{marker.fetch('scope').inspect}"
  end

  # --- 4 自動 marker 型 ---

  def test_automatic_marker_missing_required_artifact
    m = @handler.automatic_marker(
      run_id: "run-x", kind: :missing_required_artifact,
      detail: "steps/step_a_independent_review.json absent"
    )
    assert_equal "missing_required_artifact", m.fetch("reason_code")
    assert_equal "runtime", m.fetch("issued_by")
    assert_schema_conformant(m)
  end

  def test_automatic_marker_unresolved_prompt_identity
    m = @handler.automatic_marker(
      run_id: "run-x", kind: :unresolved_prompt_identity,
      detail: "prompt_id missing for role=reviewer step=A"
    )
    assert_equal "unresolved_prompt_identity", m.fetch("reason_code")
    assert_schema_conformant(m)
  end

  def test_automatic_marker_run_close_without_signoff
    m = @handler.automatic_marker(
      run_id: "run-x", kind: :run_close_without_signoff,
      detail: "validator invoked before human sign-off written"
    )
    assert_equal "run_close_without_signoff", m.fetch("reason_code")
    assert_schema_conformant(m)
  end

  def test_automatic_marker_treatment_step_mismatch
    m = @handler.automatic_marker(
      run_id: "run-x", kind: :treatment_step_mismatch,
      detail: "treatment=single but step_b present"
    )
    assert_equal "treatment_step_mismatch", m.fetch("reason_code")
    assert_schema_conformant(m)
  end

  def test_unknown_automatic_kind_rejected
    assert_raises(ArgumentError) do
      @handler.automatic_marker(run_id: "run-x", kind: :not_a_real_kind,
                                detail: "x")
    end
  end

  # --- human-issued marker（contamination / hidden intervention）---

  def test_human_issued_marker_same_artifact_form
    m = @handler.human_issued_marker(
      run_id: "run-x", reason_code: "contamination",
      reason_detail: "reviewer saw target authoring history",
      issued_by: "kenji"
    )
    assert_equal "contamination", m.fetch("reason_code")
    assert_equal "kenji", m.fetch("issued_by")
    refute_equal "runtime", m.fetch("issued_by")
    assert_schema_conformant(m)
  end

  def test_human_issued_marker_hidden_intervention
    m = @handler.human_issued_marker(
      run_id: "run-x", reason_code: "hidden_intervention",
      reason_detail: "manual edit of step output detected",
      issued_by: "kenji", scope: "step"
    )
    assert_equal "hidden_intervention", m.fetch("reason_code")
    assert_equal "step", m.fetch("scope")
    assert_schema_conformant(m)
  end

  # --- 受入 3: raw evidence 非編集で別 artifact に追加 ---

  def test_markers_appended_without_mutating_raw_evidence
    run_root = @dir + "experiments/runs/run-x"
    raw = run_root + "steps/step_a_independent_review.json"
    raw.dirname.mkpath
    raw_body = JSON.pretty_generate("role" => "reviewer", "finding" => "x")
    raw.write(raw_body)

    existing = @handler.automatic_marker(
      run_id: "run-x", kind: :missing_required_artifact, detail: "first"
    )
    @handler.append_markers(
      run_root: run_root,
      markers: [existing,
                @handler.automatic_marker(run_id: "run-x",
                                          kind: :treatment_step_mismatch,
                                          detail: "second")]
    )

    # raw step output は不変
    assert_equal raw_body, raw.read

    saved = JSON.parse((run_root + "validation/invalidation_markers.json").read)
    assert_equal 2, saved.fetch("invalidation_markers").length
    saved.fetch("invalidation_markers").each { |m| assert_schema_conformant(m) }
  end

  def test_append_is_additive_not_overwrite
    run_root = @dir + "experiments/runs/run-x"
    @handler.append_markers(
      run_root: run_root,
      markers: [@handler.automatic_marker(run_id: "run-x",
                                          kind: :missing_required_artifact,
                                          detail: "a")]
    )
    @handler.append_markers(
      run_root: run_root,
      markers: [@handler.human_issued_marker(run_id: "run-x",
                                             reason_code: "contamination",
                                             reason_detail: "b",
                                             issued_by: "kenji")]
    )
    saved = JSON.parse((run_root + "validation/invalidation_markers.json").read)
    codes = saved.fetch("invalidation_markers").map { |m| m.fetch("reason_code") }
    assert_equal %w[missing_required_artifact contamination], codes
  end

  # --- triage note 4 項目 ---

  def test_triage_note_has_four_required_items
    run_root = @dir + "experiments/runs/run-x"
    markers = [@handler.automatic_marker(run_id: "run-x",
                                         kind: :missing_required_artifact,
                                         detail: "x")]
    note = @handler.write_triage_note(
      run_root: run_root, run_id: "run-x",
      validator_result: {
        "validator_status" => "failed",
        "error_list" => [{ "check_id" => "schema_violation" },
                         { "check_id" => "missing_required_metadata" }]
      },
      invalidation_markers: markers,
      operator_action_hint: "restore missing step artifact then re-run"
    )

    assert note.key?("primary_failure_code")
    assert note.key?("failed_validator_check_ids")
    assert note.key?("invalidation_marker_linkage")
    assert note.key?("operator_action_hint")

    assert_equal %w[schema_violation missing_required_metadata],
                 note.fetch("failed_validator_check_ids")
    assert_equal markers, note.fetch("invalidation_marker_linkage")
    refute_nil note.fetch("primary_failure_code")

    saved = JSON.parse(
      (run_root + "derived/invalid_run_triage_note.json").read
    )
    assert_equal note, saved
  end

  def test_triage_primary_failure_code_prefers_validator_status
    note = @handler.write_triage_note(
      run_root: @dir + "experiments/runs/run-y", run_id: "run-y",
      validator_result: { "validator_status" => "failed", "error_list" => [] },
      invalidation_markers: [], operator_action_hint: nil
    )
    assert_equal "validator_failed", note.fetch("primary_failure_code")
  end

  def test_triage_primary_failure_code_falls_back_to_marker
    markers = [@handler.automatic_marker(run_id: "run-z",
                                         kind: :run_close_without_signoff,
                                         detail: "x")]
    note = @handler.write_triage_note(
      run_root: @dir + "experiments/runs/run-z", run_id: "run-z",
      validator_result: { "validator_status" => "passed", "error_list" => [] },
      invalidation_markers: markers, operator_action_hint: nil
    )
    assert_equal "run_close_without_signoff", note.fetch("primary_failure_code")
  end

  # --- Run Close Boundary 後の生成順序（controller 接続） ---

  def base_inputs
    {
      target_id: "spec/dual-reviewer-runtime/tasks.md",
      target_artifact_hash: "sha256:deadbeef",
      source_repository_id: "Rwiki-v2-code-mod",
      source_revision: "abc1234",
      phase_profile: "design",
      treatment: "dual+judgment",
      review_mode: "runtime_mediated",
      protocol_version: "1.0.0",
      runtime_version: "0.1.0",
      prompt_set_version: "1.0.0",
      schema_set_version: "1.0.0",
      config_version: "1.0.0",
      config_hash: "sha256:cfg",
      operator_id: "kenji",
      track: "spec",
      source_refs: ["spec/x"]
    }
  end

  def test_finalize_post_close_generates_triage_note_in_order
    ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: @dir)
    bridge = DualReviewer::Runtime::ExecutionV2::ValidationBridge.new(
      foundation_root: ROOT + "runtime/foundation"
    )
    run = ctrl.start_run(**base_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    run.invoke_validator do
      bridge.validate(
        run_id: run.run_id, metadata: run.manifest_metadata, frozen_evidence: {},
        validator: ->(_) { { "validator_status" => "failed",
                              "error_list" => [{ "check_id" => "schema_violation" }] } }
      )
    end
    run.close
    note = run.finalize_post_close(validation_bridge: bridge)

    # 順序証跡: marker 適用 → triage 生成 → metadata 更新（崩さない）
    assert_equal %w[invalidation_markers_applied triage_hook_invoked metadata_refreshed],
                 note.fetch("post_close_order")

    rr = @dir + "experiments/runs/#{run.run_id}"
    # triage note 本体が生成され 4 項目を持つ
    triage = JSON.parse((rr + "derived/invalid_run_triage_note.json").read)
    %w[primary_failure_code failed_validator_check_ids
       invalidation_marker_linkage operator_action_hint].each do |k|
      assert triage.key?(k), "triage note に #{k} がない"
    end
    assert_equal "validator_failed", triage.fetch("primary_failure_code")
    assert_includes triage.fetch("failed_validator_check_ids"), "schema_violation"

    # raw step outputs を triage が編集していない（生成は derived/ 配下のみ）
    refute (rr + "steps").exist? && (rr + "steps").children.any?,
           "triage 生成が raw steps を作成・編集した"
  end

  # 第1波 fail-closed marker と reason_code 型・形式が一貫
  def test_fail_closed_marker_type_consistent_with_handler
    ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: @dir)
    bridge = DualReviewer::Runtime::ExecutionV2::ValidationBridge.new(
      foundation_root: ROOT + "runtime/foundation"
    )
    run = ctrl.start_run(**base_inputs)
    begin
      run.invoke_validator do
        bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                        frozen_evidence: {})
      end
    rescue DualReviewer::Runtime::SessionController::CloseBoundaryViolation
      # expected fail-closed
    end

    fc = run.invalidation_markers.fetch(0)
    # handler が出す run_close_without_signoff と同 reason_code 語彙
    handler_code = @handler.automatic_marker(
      run_id: run.run_id, kind: :run_close_without_signoff, detail: "x"
    ).fetch("reason_code")
    assert_equal handler_code, fc.fetch("reason_code")
    # fail-closed marker も同 schema 必須形に準拠（型一貫）
    assert_schema_conformant(fc)
  end
end
