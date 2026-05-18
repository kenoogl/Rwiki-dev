# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 7: validator integration と Run Close Boundary（controller 接続）
# 根拠: tasks.md Task 7、Requirement 6 受入 1〜9、design「Run Close Boundary」
#       設計再確定 finding 9（単一起動点・前提 3 条件・多重起動禁止・fail-closed）。
#
# 第1波 controller の Run Close Boundary 単一起動点（invoke_validator yield）に
# ValidationBridge 実体を接続し、決定的固定 validator スタブで
#   - 順序: Step D → human sign-off → freeze → validator → close
#   - 単一起動点・前提 3 条件未充足で起動しない・多重起動禁止
#   - fail-closed（orchestration_failed）＋invalidation marker
#   - 4 値（blocked / not_run）丸めなし final metadata 伝播
#   - run close 後の順: marker 付与 → triage 呼び出し位置 → manifest/review_case 更新
# を検証する。session_controller 既存テストは無回帰（本テストは追加のみ）。
class TestRunCloseBoundaryIntegration < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path

  def setup
    require_relative "../../runtime/controller/session_controller"
    require_relative "../../runtime/execution_v2/validation/validation_bridge"
    @dir = Pathname(Dir.mktmpdir)
    @ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: @dir)
    @bridge = DualReviewer::Runtime::ExecutionV2::ValidationBridge.new(
      foundation_root: ROOT + "runtime/foundation"
    )
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

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

  def driven_to_validator
    run = @ctrl.start_run(**base_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    run
  end

  # validator 実体（ValidationBridge）が単一起動点 yield に接続される
  def test_bridge_connected_at_single_invocation_point
    run = driven_to_validator
    result = run.invoke_validator do
      @bridge.validate(
        run_id: run.run_id, metadata: run.manifest_metadata, frozen_evidence: {}
      )
    end
    assert_equal "passed", result.fetch("validator_status")
    run.close
    rr = @dir + "experiments/runs/#{run.run_id}"
    saved = JSON.parse((rr + "validation/validator_result.json").read)
    assert_equal run.run_id, saved.fetch("run_id")
    assert_equal "passed", saved.fetch("validator_status")
  end

  # blocked を final metadata まで丸めずに伝播（完了条件）
  def test_blocked_propagates_to_final_metadata_unrounded
    run = driven_to_validator
    run.invoke_validator do
      @bridge.validate(
        run_id: run.run_id, metadata: run.manifest_metadata, frozen_evidence: {},
        validator: ->(_) { { "validator_status" => "blocked",
                              "insufficiency_detail" => "missing artifact",
                              "error_list" => [] } }
      )
    end
    run.close
    md = run.manifest_metadata
    assert_equal "blocked", md.fetch("validator_status")
    mp = YAML.safe_load((@dir + "experiments/runs/#{run.run_id}/run_manifest.yaml").read)
    rc = JSON.parse((@dir + "experiments/runs/#{run.run_id}/review_case.json").read)
    assert_equal "blocked", mp.fetch("metadata").fetch("validator_status")
    assert_equal "blocked", rc.fetch("metadata").fetch("validator_status")
  end

  def test_not_run_propagates_unrounded
    run = driven_to_validator
    run.invoke_validator do
      @bridge.validate(
        run_id: run.run_id, metadata: run.manifest_metadata, frozen_evidence: {},
        validator: ->(_) { { "validator_status" => "not_run", "error_list" => [] } }
      )
    end
    run.close
    assert_equal "not_run", run.manifest_metadata.fetch("validator_status")
  end

  # 前提 3 条件未充足で bridge 起動に到達しない（controller が先に fail-closed）
  def test_bridge_not_invoked_before_preconditions
    run = @ctrl.start_run(**base_inputs)
    invoked = false
    assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) do
      run.invoke_validator do
        invoked = true
        @bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                         frozen_evidence: {})
      end
    end
    refute invoked, "前提条件未充足で validator 実体が起動した"
    assert_equal "orchestration_failed", run.run_status
  end

  # 多重起動禁止（単一起動点）
  def test_double_invocation_forbidden_with_bridge
    run = driven_to_validator
    run.invoke_validator do
      @bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                       frozen_evidence: {})
    end
    assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) do
      run.invoke_validator do
        @bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                         frozen_evidence: {})
      end
    end
    assert_equal "orchestration_failed", run.run_status
  end

  # fail-closed 時に invalidation marker（finding 9）
  def test_fail_closed_emits_invalidation_marker
    run = @ctrl.start_run(**base_inputs)
    begin
      run.invoke_validator do
        @bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                         frozen_evidence: {})
      end
    rescue DualReviewer::Runtime::SessionController::CloseBoundaryViolation
      # expected
    end
    assert(run.invalidation_markers.any? do |m|
      m.fetch("reason_code") =~ /sign-?off|mismatch|close.?boundary/i
    end)
  end

  # run close 後の順: marker → triage 呼び出し位置 → manifest/review_case 更新
  def test_post_close_sequence_order
    run = driven_to_validator
    run.invoke_validator do
      @bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                       frozen_evidence: {})
    end
    run.close
    # close 後の triage 接続点（本体生成は Task 8 波。本波は呼び出し位置確定）
    note = run.finalize_post_close(validation_bridge: @bridge)
    assert_equal "closed", run.run_status
    # triage hook は close 成立後にのみ呼べる（順序保証）
    assert note.key?("invalidation_markers_applied")
    assert note.key?("triage_hook_invoked")
    assert note.key?("metadata_refreshed")
    # 順序証跡: marker 適用 → triage hook → metadata 更新
    assert_equal %w[invalidation_markers_applied triage_hook_invoked metadata_refreshed],
                 note.fetch("post_close_order")
  end

  # close 成立前に post-close を呼ぶと拒否（順序を崩さない）
  def test_post_close_rejected_before_close
    run = driven_to_validator
    assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) do
      run.finalize_post_close(validation_bridge: @bridge)
    end
  end

  # validator failure と orchestration failure を区別（受入 4）
  def test_validator_failure_keeps_run_closed_not_orchestration_failed
    run = driven_to_validator
    run.invoke_validator do
      @bridge.validate(
        run_id: run.run_id, metadata: run.manifest_metadata, frozen_evidence: {},
        validator: ->(_) { { "validator_status" => "failed",
                              "error_list" => [{ "check_id" => "schema_violation" }] } }
      )
    end
    run.close
    # validator failure でも orchestration は失敗していない（run は閉じる）
    assert_equal "closed", run.run_status
    assert_equal "failed", run.manifest_metadata.fetch("validator_status")
  end
end
