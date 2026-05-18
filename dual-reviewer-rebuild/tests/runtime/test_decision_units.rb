# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 5: decision unit model と human sign-off record
# 根拠: tasks.md Task 5、Requirement 5 受入 1〜5、Requirement 6 受入 9、
#       design「Decision Unit Model」「Human Sign-off Record」、
#       設計再確定 finding 9（Run Close Boundary 順序＝human sign-off → validator → close）。
# 外部依存なし（gem 不使用）・repo 内で完結。
class TestDecisionUnits < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  DECISION_UNIT_FIELDS = %w[
    decision_unit_id finding_refs judgment_refs proposed_action
    human_decision human_decision_timestamp human_decision_note
  ].freeze

  SIGNOFF_FIELDS = %w[
    run_id human_signoff_status signed_off_by signed_off_at
    covered_decision_unit_ids signoff_note
  ].freeze

  SIGNOFF_STATUSES = %w[pending approved rejected deferred].freeze

  def setup
    require_relative "../../runtime/execution_v2/decisions/decision_units"
    require_relative "../../runtime/execution_v2/decisions/step_d_integration"
    require_relative "../../runtime/controller/session_controller"
    @dir = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # Step D 出力を模した raw step 入力から decision units を生成する。
  def step_d_units
    integration = DualReviewer::Runtime::StepDIntegration.new
    step_a = {
      "findings" => [
        { "finding_id" => "f1", "source_role" => "primary_reviewer",
          "requirement_link" => "REQ-1" },
        { "finding_id" => "f2", "source_role" => "primary_reviewer",
          "requirement_link" => "REQ-2" }
      ]
    }
    step_b = {
      "assessments" => [
        { "finding_id" => "f1",
          "adversarial_outcome" => "no_counter_evidence_after_challenge" },
        { "finding_id" => "f2", "adversarial_outcome" => "counter_evidence_raised" }
      ]
    }
    result = integration.integrate(
      step_a: step_a, step_b: step_b, step_c: nil, treatment: "dual"
    )
    result[:decision_units]
  end

  def model
    DualReviewer::Runtime::DecisionUnitModel.new(
      run_id: "run-test-0001", decision_units: step_d_units
    )
  end

  # 受入 1: raw finding をそのまま渡さず decision unit に束ねて提示する。
  def test_findings_are_bundled_into_decision_units
    m = model
    units = m.decision_units
    refute_empty units
    units.each do |u|
      DECISION_UNIT_FIELDS.each { |k| assert u.key?(k), "missing #{k}" }
      refute_empty u.fetch("finding_refs")
    end
    all_refs = units.flat_map { |u| u.fetch("finding_refs") }
    assert_includes all_refs, "f1"
    assert_includes all_refs, "f2"
  end

  # 受入 5: silent に LLM finding を auto-adopt しない（初期 human_decision は不在）。
  def test_no_silent_auto_adopt
    m = model
    m.decision_units.each do |u|
      assert_nil u.fetch("human_decision")
      assert_nil u.fetch("human_decision_timestamp")
      assert_nil u.fetch("human_decision_note")
    end
    refute m.fully_signed_off?, "decision なしで sign-off 完了扱いにしない"
    assert_equal "pending", m.aggregate_signoff_status
  end

  # 受入 2: 各 decision unit の human decision outcome を記録する。
  def test_records_human_decision_outcome
    m = model
    target = m.decision_units.first.fetch("decision_unit_id")
    m.record_human_decision(
      decision_unit_id: target, decision: "approved",
      note: "確認済み", at: "2026-05-19T00:00:00Z"
    )
    u = m.decision_units.find { |x| x.fetch("decision_unit_id") == target }
    assert_equal "approved", u.fetch("human_decision")
    assert_equal "2026-05-19T00:00:00Z", u.fetch("human_decision_timestamp")
    assert_equal "確認済み", u.fetch("human_decision_note")
  end

  # 受入 3: human decision 不在と明示 defer / reject を区別する。
  def test_absence_distinguished_from_explicit_defer_reject
    m = model
    ids = m.decision_units.map { |u| u.fetch("decision_unit_id") }
    m.record_human_decision(decision_unit_id: ids[0], decision: "rejected")
    m.record_human_decision(decision_unit_id: ids[1], decision: "deferred")

    u0 = m.decision_units.find { |x| x.fetch("decision_unit_id") == ids[0] }
    u1 = m.decision_units.find { |x| x.fetch("decision_unit_id") == ids[1] }
    assert_equal "rejected", u0.fetch("human_decision")
    assert_equal "deferred", u1.fetch("human_decision")

    # 不在 = pending 相当。明示 reject/defer とは別物。
    assert_equal "rejected", m.decision_state(ids[0])
    assert_equal "deferred", m.decision_state(ids[1])
  end

  def test_absence_state_is_pending_not_rejected
    m = model
    id = m.decision_units.first.fetch("decision_unit_id")
    assert_equal "pending", m.decision_state(id)
    refute_equal "rejected", m.decision_state(id)
    refute_equal "deferred", m.decision_state(id)
  end

  def test_invalid_decision_value_rejected
    m = model
    id = m.decision_units.first.fetch("decision_unit_id")
    assert_raises(ArgumentError) do
      m.record_human_decision(decision_unit_id: id, decision: "maybe")
    end
    assert_raises(ArgumentError) do
      m.record_human_decision(decision_unit_id: "nope", decision: "approved")
    end
    # pending を明示記録値にはしない（不在表現であり decision outcome ではない）。
    assert_raises(ArgumentError) do
      m.record_human_decision(decision_unit_id: id, decision: "pending")
    end
  end

  # aggregate sign-off status は foundation enum に従う。
  def test_aggregate_signoff_status_follows_foundation_enum
    m = model
    ids = m.decision_units.map { |u| u.fetch("decision_unit_id") }
    assert_equal "pending", m.aggregate_signoff_status

    m.decision_units.each_with_index do |_, i|
      m.record_human_decision(decision_unit_id: ids[i], decision: "approved")
    end
    assert_equal "approved", m.aggregate_signoff_status
    assert m.fully_signed_off?
    assert_includes SIGNOFF_STATUSES, m.aggregate_signoff_status
  end

  def test_aggregate_rejected_when_any_rejected
    m = model
    ids = m.decision_units.map { |u| u.fetch("decision_unit_id") }
    m.record_human_decision(decision_unit_id: ids[0], decision: "approved")
    m.record_human_decision(decision_unit_id: ids[1], decision: "rejected")
    assert_equal "rejected", m.aggregate_signoff_status
  end

  def test_aggregate_deferred_when_any_deferred_no_reject
    m = model
    ids = m.decision_units.map { |u| u.fetch("decision_unit_id") }
    m.record_human_decision(decision_unit_id: ids[0], decision: "approved")
    m.record_human_decision(decision_unit_id: ids[1], decision: "deferred")
    assert_equal "deferred", m.aggregate_signoff_status
  end

  def test_aggregate_pending_when_any_absent
    m = model
    ids = m.decision_units.map { |u| u.fetch("decision_unit_id") }
    m.record_human_decision(decision_unit_id: ids[0], decision: "approved")
    # ids[1] は不在のまま → 全体は未完 = pending。
    assert_equal "pending", m.aggregate_signoff_status
    refute m.fully_signed_off?
  end

  # decision_units.json を decisions/ 配下に書く（7 フィールド保持）。
  def test_writes_decision_units_artifact
    m = model
    m.record_human_decision(
      decision_unit_id: m.decision_units.first.fetch("decision_unit_id"),
      decision: "approved"
    )
    path = m.write_decision_units(run_root: @dir)
    assert_equal "decision_units.json", path.basename.to_s
    assert_equal "decisions", path.dirname.basename.to_s
    payload = JSON.parse(path.read)
    assert_equal "run-test-0001", payload.fetch("run_id")
    units = payload.fetch("decision_units")
    units.each { |u| DECISION_UNIT_FIELDS.each { |k| assert u.key?(k) } }
  end

  # human_signoff.json: 6 フィールド・foundation enum。
  def test_writes_human_signoff_artifact
    m = model
    ids = m.decision_units.map { |u| u.fetch("decision_unit_id") }
    ids.each { |id| m.record_human_decision(decision_unit_id: id, decision: "approved") }
    payload = m.build_human_signoff(signed_off_by: "op-1", note: "ok")

    SIGNOFF_FIELDS.each { |k| assert payload.key?(k), "missing #{k}" }
    assert_equal "run-test-0001", payload.fetch("run_id")
    assert_includes SIGNOFF_STATUSES, payload.fetch("human_signoff_status")
    assert_equal "approved", payload.fetch("human_signoff_status")
    assert_equal "op-1", payload.fetch("signed_off_by")
    assert_equal ids.sort, payload.fetch("covered_decision_unit_ids").sort
    refute_nil payload.fetch("signed_off_at")
    assert_equal "ok", payload.fetch("signoff_note")
  end

  def test_signoff_status_reflects_absence_as_pending
    m = model
    payload = m.build_human_signoff(signed_off_by: "op-1")
    assert_equal "pending", payload.fetch("human_signoff_status")
    assert_nil payload.fetch("signoff_note")
  end

  # finding linkage: foundation finding schema の decision_unit_id /
  # human_decision_ref がこの artifact を指す整合を出せる。
  def test_finding_linkage_map
    m = model
    ids = m.decision_units.map { |u| u.fetch("decision_unit_id") }
    m.record_human_decision(decision_unit_id: ids[0], decision: "approved")
    linkage = m.finding_linkage
    # f1 は最初の unit に属す。
    f1 = linkage.fetch("f1")
    assert_equal ids.first, f1.fetch("decision_unit_id")
    # human_decision_ref は sign-off artifact（run レベル）を指す参照。
    assert_equal "decisions/human_signoff.json", f1.fetch("human_decision_ref")
  end

  # 第1波 controller との接続: sign-off 未書込で close 不可（Run Close Boundary）。
  def test_close_blocked_without_signoff_written
    ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: @dir)
    run = ctrl.start_run(**controller_inputs)
    run.mark_step_d_complete
    run.freeze_raw_evidence
    # human_signoff 未書込のまま validator を起動 → fail-closed。
    err = assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) do
      run.invoke_validator { { "validator_status" => "passed" } }
    end
    assert_match(/sign-?off/i, err.message)
    assert_equal "orchestration_failed", run.run_status
    refute (run.run_root + "review_case.json").exist?
  end

  # 接続成立: model → controller.write_human_signoff → observable フラグ → 順序通り close。
  def test_signoff_then_validator_then_close_ordering
    ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: @dir)
    run = ctrl.start_run(**controller_inputs)
    m = DualReviewer::Runtime::DecisionUnitModel.new(
      run_id: run.run_id, decision_units: step_d_units
    )
    m.decision_units.each do |u|
      m.record_human_decision(
        decision_unit_id: u.fetch("decision_unit_id"), decision: "approved"
      )
    end

    run.mark_step_d_complete
    so = m.build_human_signoff(signed_off_by: "op-1")
    # decision_units.json も sign-off 書込より前に出す。
    m.write_decision_units(run_root: run.run_root)
    run.write_human_signoff(
      status: so.fetch("human_signoff_status"),
      signed_off_by: so.fetch("signed_off_by"),
      covered_decision_unit_ids: so.fetch("covered_decision_unit_ids"),
      note: so.fetch("signoff_note")
    )
    run.freeze_raw_evidence
    run.invoke_validator { { "validator_status" => "passed" } }
    meta = run.close

    assert_equal "closed", meta.fetch("run_status")
    assert_equal "approved", meta.fetch("human_signoff_status")
    signoff_path = run.run_root + "decisions/human_signoff.json"
    assert signoff_path.exist?
    written = JSON.parse(signoff_path.read)
    assert_equal "approved", written.fetch("human_signoff_status")
    assert_equal run.run_id, written.fetch("run_id")
    assert (run.run_root + "decisions/decision_units.json").exist?
  end

  def controller_inputs
    {
      target_id: "spec/dual-reviewer-runtime/tasks.md",
      target_artifact_hash: "deadbeef",
      source_repository_id: "rwiki-v2",
      source_revision: "abc123",
      phase_profile: "tasks",
      treatment: "dual",
      review_mode: "runtime_mediated",
      protocol_version: "1.0.0",
      runtime_version: "1.0.0",
      prompt_set_version: "1.0.0",
      schema_set_version: "1.0.0",
      config_version: "1.0.0",
      config_hash: "cfg-hash",
      operator_id: "op-1",
      track: "spec",
      source_refs: ["spec/dual-reviewer-runtime/tasks.md"]
    }
  end
end
