# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 6: evidence writing model
# 根拠: tasks.md Task 6、Requirement 4 受入 1〜7、Requirement 7 受入 1〜5、
#       design「Evidence Writing Model」「Raw vs Derived Separation」
#       「`review_case.json`」「Runtime Artifact Layout」「v2 Compatibility Rule」
#       「Interfaces to Downstream Features」、設計横断整合ゲート 2026-05-18
#       実行側 A-5（review_case 唯一横断正本・review_artifact 投影規約 runtime 所有）、
#       評価 A-7（comparison_eligibility_note スキーマ runtime 所有・最小 6 項目）、
#       自己改善 T5-A 案 A（runtime_validation_summary.schema.json runtime 所有 contract）。
# 外部依存なし（gem 不使用）・repo 内で完結。
class TestEvidenceWriter < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/writers/evidence_writer"
    require_relative "../../runtime/execution_v2/writers/review_case_projector"
    @dir = Pathname(Dir.mktmpdir)
    @run_id = "run-20260519T000000Z-abcd1234"
    @run_root = @dir + "experiments/runs/#{@run_id}"
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 18 項目（closed_at は run 中更新で review_case metadata required は 19 項目）。
  def base_metadata
    {
      "run_id" => @run_id,
      "target_id" => "spec/dual-reviewer-runtime/tasks.md",
      "target_artifact_hash" => "sha256:deadbeef",
      "source_repository_id" => "Rwiki-v2-code-mod",
      "source_revision" => "abc1234",
      "phase_profile" => "design",
      "treatment" => "dual+judgment",
      "review_mode" => "runtime_mediated",
      "protocol_version" => "1.0.0",
      "runtime_version" => "0.1.0",
      "schema_set_version" => "1.0.0",
      "prompt_set_version" => "1.0.0",
      "config_version" => "1.0.0",
      "config_hash" => "sha256:cfg",
      "run_status" => "in_progress",
      "validator_status" => "not_run",
      "human_signoff_status" => "pending",
      "evidence_class" => "candidate",
      "started_at" => "2026-05-19T00:00:00Z"
    }
  end

  def prompt_identity(role)
    {
      "prompt_artifact_path" => "runtime/prompts/#{role}.md",
      "prompt_id" => "prompt-#{role}",
      "prompt_version" => "1.0.0",
      "role" => role
    }
  end

  def step_a_record
    {
      "step_id" => "step_a",
      "step_name" => "primary_detection",
      "execution_state" => "executed",
      "treatment" => "dual+judgment",
      "phase_profile" => "design",
      "prompt_identity" => prompt_identity("primary_reviewer"),
      "findings" => [
        {
          "finding_id" => "f-001",
          "source_role" => "primary_reviewer",
          "severity" => "high",
          "summary" => "責務境界が曖昧",
          "requirement_link" => "REQ-4",
          "source_refs" => ["spec:design.md#L10"]
        }
      ]
    }
  end

  def step_b_record
    {
      "step_id" => "step_b",
      "step_name" => "adversarial_review",
      "execution_state" => "executed",
      "treatment" => "dual+judgment",
      "phase_profile" => "design",
      "prompt_identity" => prompt_identity("adversarial_reviewer"),
      "assessments" => [
        {
          "finding_id" => "f-001",
          "adversarial_outcome" => "counter_evidence_raised",
          "counter_evidence" => ["代替設計で責務分離可能"]
        }
      ]
    }
  end

  def step_c_record
    {
      "step_id" => "step_c",
      "step_name" => "judgment",
      "execution_state" => "executed",
      "treatment" => "dual+judgment",
      "phase_profile" => "design",
      "prompt_identity" => prompt_identity("judgment_reviewer"),
      "judgments" => [
        {
          "finding_id" => "f-001",
          "final_label" => "necessary",
          "recommended_action" => "address_finding",
          "override_reason" => "敵対役の反証を踏まえ必要性確定"
        }
      ]
    }
  end

  def step_d_record
    {
      "step_id" => "step_d",
      "step_name" => "integration",
      "execution_state" => "executed",
      "treatment" => "dual+judgment",
      "integrated_finding_count" => 1,
      "decision_unit_count" => 1,
      "run_close_readiness" => { "ready" => true, "missing_required_steps" => [] }
    }
  end

  def decision_units
    [
      {
        "decision_unit_id" => "du-001",
        "decision_key" => "REQ-4",
        "finding_refs" => ["f-001"],
        "judgment_refs" => ["f-001"],
        "proposed_action" => "address_finding",
        "human_decision" => "approved",
        "human_decision_timestamp" => "2026-05-19T00:05:00Z",
        "human_decision_note" => nil
      }
    ]
  end

  def build_writer(metadata: base_metadata)
    DualReviewer::Runtime::ExecutionV2::EvidenceWriter.new(
      run_root: @run_root, run_id: @run_id
    ).tap do |w|
      w.metadata = metadata
    end
  end

  def write_all_steps(writer)
    writer.write_raw_step(step_a_record)
    writer.write_raw_step(step_b_record)
    writer.write_raw_step(step_c_record)
    writer.write_raw_step(step_d_record)
  end

  # --- 3 層分離（raw / decision / v2） --------------------------------------

  def test_three_layer_separation_paths
    w = build_writer
    write_all_steps(w)
    w.write_decision_units(decision_units)
    w.write_v2_internal(
      review_artifact: { "schema_version" => "1.0.0" },
      trace_note: { "trace" => [] },
      signal_linkage_note: { "links" => [] }
    )
    assert (@run_root + "steps/step_a_primary_detection.json").exist?
    assert (@run_root + "steps/step_d_integration.json").exist?
    assert (@run_root + "decisions/decision_units.json").exist?
    assert (@run_root + "v2/review_artifact.json").exist?
    assert (@run_root + "v2/trace_note.json").exist?
    assert (@run_root + "v2/signal_linkage_note.json").exist?
  end

  # raw step outputs は immutable。summary 更新後も raw を書き換えない（受入 4）。
  def test_raw_step_outputs_are_immutable_after_summary_update
    w = build_writer
    w.write_raw_step(step_a_record)
    raw_path = @run_root + "steps/step_a_primary_detection.json"
    original = raw_path.read

    # derived summary / review_case を後から生成・更新しても raw は不変
    w.write_runtime_summary("note" => "after the fact")
    w.write_v2_internal(metric_snapshot: { "metrics" => {} })
    w.write_metric_snapshot
    # 同一 step を別内容で再投入しても immutability で拒否し raw を書き換えない
    assert_raises(RuntimeError) do
      w.write_raw_step(step_a_record.merge("findings" => []))
    end
    assert_equal original, raw_path.read, "raw step output が summary 更新で変化した"
  end

  # 同一 step の二重書込は immutability 違反として拒否する
  def test_duplicate_raw_step_write_rejected
    w = build_writer
    w.write_raw_step(step_a_record)
    err = assert_raises(RuntimeError) do
      w.write_raw_step(step_a_record.merge("findings" => []))
    end
    assert_match(/immutable|already|raw/i, err.message)
  end

  # skip/reduced marker も raw step 層へ書く（事故的欠落と区別、受入 5）
  def test_skip_marker_written_to_raw_step_layer
    w = build_writer(metadata: base_metadata.merge("treatment" => "single"))
    w.write_raw_step(step_a_record)
    w.write_raw_step(
      "step_id" => "step_b", "step_name" => "adversarial_review",
      "execution_state" => "skipped",
      "reason" => "intentional skipped by treatment selection (treatment=single)",
      "treatment" => "single"
    )
    doc = JSON.parse((@run_root + "steps/step_b_adversarial_review.json").read)
    assert_equal "skipped", doc.fetch("execution_state")
    assert_match(/treatment/, doc.fetch("reason"))
  end

  # --- review_case.json が foundation schema へ常時準拠 ----------------------

  def schema
    @schema ||= JSON.parse((ROOT + "runtime/schemas/review_case.schema.json").read)
  end

  def assert_required(obj, required, label)
    missing = required.reject { |k| obj.is_a?(Hash) && obj.key?(k) }
    assert missing.empty?, "#{label} required 欠落: #{missing.join(', ')}"
  end

  def build_review_case(w)
    write_all_steps(w)
    w.write_decision_units(decision_units)
    w.write_v2_internal(review_artifact: { "schema_version" => "1.0.0" })
    w.write_review_case(
      validator_result_ref: "validation/validator_result.json#vr-1",
      invalidation_marker_refs: []
    )
  end

  def test_review_case_conforms_to_foundation_required_top_level
    w = build_writer
    build_review_case(w)
    doc = JSON.parse((@run_root + "review_case.json").read)
    assert_required(doc, schema.fetch("required"), "review_case top-level")
  end

  def test_review_case_metadata_satisfies_19_required
    w = build_writer
    build_review_case(w)
    doc = JSON.parse((@run_root + "review_case.json").read)
    md_required = schema.dig("properties", "metadata", "required")
    assert_equal 19, md_required.length
    assert_required(doc.fetch("metadata"), md_required, "review_case metadata")
  end

  def test_review_case_step_records_items_satisfy_6_required
    w = build_writer
    build_review_case(w)
    doc = JSON.parse((@run_root + "review_case.json").read)
    item_required = schema.dig("properties", "step_records", "items", "required")
    refute_empty doc.fetch("step_records")
    doc.fetch("step_records").each do |sr|
      assert_required(sr, item_required, "step_record item")
    end
  end

  def test_review_case_findings_satisfy_finding_schema_required
    w = build_writer
    build_review_case(w)
    doc = JSON.parse((@run_root + "review_case.json").read)
    finding_schema = JSON.parse((ROOT + "runtime/schemas/finding.schema.json").read)
    fr = finding_schema.fetch("required")
    refute_empty doc.fetch("findings")
    doc.fetch("findings").each do |f|
      assert_required(f, fr, "finding")
      assert finding_schema.dig("properties", "adversarial_outcome", "enum")
        .include?(f.fetch("adversarial_outcome")),
             "adversarial_outcome が foundation enum 外: #{f['adversarial_outcome']}"
    end
  end

  def test_review_case_validation_refs_shape
    w = build_writer
    build_review_case(w)
    doc = JSON.parse((@run_root + "review_case.json").read)
    vr = doc.fetch("validation_refs")
    assert vr.key?("validator_result_ref")
    assert vr.key?("invalidation_marker_refs")
    assert_kind_of Array, vr.fetch("invalidation_marker_refs")
  end

  # 実行中更新群は foundation enum 初期値で schema 準拠（確定遷移は Task 7 波）
  def test_runtime_updated_fields_use_foundation_initial_values
    w = build_writer
    build_review_case(w)
    md = JSON.parse((@run_root + "review_case.json").read).fetch("metadata")
    assert_equal "not_run", md.fetch("validator_status")
    assert_equal "pending", md.fetch("human_signoff_status")
    assert_equal "candidate", md.fetch("evidence_class")
  end

  # --- review_artifact → review_case 投影規約（runtime 所有・A-5） -----------

  def test_projection_rule_is_runtime_owned_and_deterministic
    proj = DualReviewer::Runtime::ExecutionV2::ReviewCaseProjector.new
    review_artifact = {
      "schema_version" => "1.0.0",
      "review_issue_candidates" => [
        { "finding_id" => "f-001", "taxonomy_path" => "design/responsibility" }
      ]
    }
    rc = proj.project(
      run_id: @run_id,
      metadata: base_metadata,
      step_records: [step_a_record, step_b_record, step_c_record, step_d_record],
      decision_units: decision_units,
      review_artifact: review_artifact,
      validator_result_ref: nil,
      invalidation_marker_refs: []
    )
    # 投影は taxonomy-first review_artifact を foundation review_case へ写像する
    assert_required(rc, schema.fetch("required"), "projected review_case")
    assert_equal @run_id, rc.fetch("metadata").fetch("run_id")
    f = rc.fetch("findings").find { |x| x.fetch("finding_id") == "f-001" }
    refute_nil f
    # source attribution（受入 2）
    assert_equal "primary_reviewer", f.fetch("source_role")
    # judgment linkage（受入 2）
    refute_nil f.fetch("judgment_ref")
    # decision unit linkage（finding schema）
    assert_equal "du-001", f.fetch("decision_unit_id")
  end

  # counter-evidence / override field を該当時に出す（受入 3）
  def test_counter_evidence_and_override_fields_emitted_when_applicable
    w = build_writer
    build_review_case(w)
    f = JSON.parse((@run_root + "review_case.json").read)
      .fetch("findings").find { |x| x.fetch("finding_id") == "f-001" }
    refute_empty f.fetch("counter_evidence_refs"),
                 "counter_evidence 該当時に counter_evidence_refs が空"
    assert_equal "counter_evidence_raised", f.fetch("adversarial_outcome")
  end

  # review-mode provenance を foundation metadata contract enum で出す（受入 6）
  def test_review_mode_provenance_conforms_to_foundation_enum
    w = build_writer
    build_review_case(w)
    md = JSON.parse((@run_root + "review_case.json").read).fetch("metadata")
    assert_includes %w[manual_dogfooding runtime_mediated], md.fetch("review_mode")
    assert_equal "runtime_mediated", md.fetch("review_mode")
  end

  # --- failure_observation（受入 7） -----------------------------------------

  def test_failure_observation_conforms_to_foundation_schema
    w = build_writer
    w.write_failure_observation(
      failure_type: "review_miss",
      related_finding_ref: "f-001",
      missed_by_role: "primary_reviewer",
      detected_at_step: "step_b"
    )
    path = @run_root + "failures/failure_observation.json"
    assert path.exist?, "failure mode で failure_observation.json 未生成"
    doc = JSON.parse(path.read)
    fo_schema = JSON.parse((ROOT + "runtime/schemas/failure_observation.schema.json").read)
    assert_required(doc, fo_schema.fetch("required"), "failure_observation")
    assert_equal @run_id, doc.fetch("run_ref")
    assert_equal "review_miss", doc.fetch("failure_type")
  end

  # --- comparison_eligibility_note（評価 A-7・runtime 所有 6 項目） ----------

  # 配置は runtime 所有 contract（runtime/schemas/ は foundation 所有・読取専用
  # のため runtime 所有スキーマは runtime/execution_v2/contracts/ に置く）。
  COMPARISON_ELIGIBILITY_SCHEMA =
    "runtime/execution_v2/contracts/comparison_eligibility_note.schema.json"

  def test_comparison_eligibility_note_runtime_owned_schema_exists
    sp = ROOT + COMPARISON_ELIGIBILITY_SCHEMA
    assert sp.exist?, "comparison_eligibility_note runtime 所有スキーマ不在"
    sc = JSON.parse(sp.read)
    %w[run_id eligible_for_standard_comparison ineligibility_reason_codes
       treatment phase_profile generated_at].each do |k|
      assert sc.fetch("required").include?(k), "A-7 必須項目欠落: #{k}"
    end
  end

  def test_comparison_eligibility_note_emitted_with_six_fields
    w = build_writer
    w.write_comparison_eligibility_note(
      eligible_for_standard_comparison: true,
      ineligibility_reason_codes: []
    )
    path = @run_root + "derived/comparison_eligibility_note.json"
    assert path.exist?
    doc = JSON.parse(path.read)
    sc = JSON.parse((ROOT + COMPARISON_ELIGIBILITY_SCHEMA).read)
    assert_required(doc, sc.fetch("required"), "comparison_eligibility_note")
    assert_equal @run_id, doc.fetch("run_id")
    assert_equal true, doc.fetch("eligible_for_standard_comparison")
    assert_equal "dual+judgment", doc.fetch("treatment")
    assert_equal "design", doc.fetch("phase_profile")
    assert_kind_of Array, doc.fetch("ineligibility_reason_codes")
    refute_nil doc.fetch("generated_at")
  end

  # ineligible 時は reason code を保持する
  def test_comparison_eligibility_note_ineligible_carries_reason_codes
    w = build_writer
    w.write_comparison_eligibility_note(
      eligible_for_standard_comparison: false,
      ineligibility_reason_codes: %w[validator_failed]
    )
    doc = JSON.parse((@run_root + "derived/comparison_eligibility_note.json").read)
    assert_equal false, doc.fetch("eligible_for_standard_comparison")
    assert_equal %w[validator_failed], doc.fetch("ineligibility_reason_codes")
  end

  # --- metric_snapshot（生成責務 runtime writer 側、空 artifact を残さない） --

  def test_metric_snapshot_generated_by_runtime_writer
    w = build_writer
    write_all_steps(w)
    w.write_metric_snapshot
    path = @run_root + "v2/metric_snapshot.json"
    assert path.exist?, "metric_snapshot.json が runtime writer で未生成"
    doc = JSON.parse(path.read)
    # 未生成の空 artifact を残さない: run identity と step 数を最低限保持
    assert_equal @run_id, doc.fetch("run_id")
    refute_nil doc.fetch("generated_at")
    assert doc.key?("step_execution_counts"), "metric_snapshot が空 artifact"
  end

  # --- runtime_validation_summary contract（自己改善 T5-A 案 A） -------------

  def test_runtime_validation_summary_is_runtime_owned_contract
    sp = ROOT + "scripts/track_runs/contracts/runtime_validation_summary.schema.json"
    assert sp.exist?, "runtime_validation_summary contract 不在"
    sc = JSON.parse(sp.read)
    # runtime 所有 contract として固定された payload shape（再定義禁止）
    assert_equal "urn:dual-reviewer:track-runs:runtime-validation-summary:1.0.0",
                 sc.fetch("$id")
    %w[schema_version run_label case_id track run_id validator_result_ref
       invalidation_markers_ref comparison_eligibility_note_ref
       invalid_run_triage_note_ref overall_status primary_failure_code
       operator_action_hint remediation_templates].each do |k|
      assert sc.fetch("required").include?(k),
             "runtime_validation_summary contract 必須項目欠落: #{k}"
    end
  end

  # --- downstream artifact 追跡（design Interfaces / Downstream Handoff） ----

  def test_downstream_artifact_trace_is_enumerable
    map = DualReviewer::Runtime::ExecutionV2::EvidenceWriter.downstream_artifact_trace
    assert map.key?("evaluation")
    assert map.key?("self_improvement")
    assert map.key?("paper_interface")
    assert_includes map.fetch("evaluation"), "review_case.json"
    assert_includes map.fetch("evaluation"),
                    "derived/comparison_eligibility_note.json"
    refute_includes map.fetch("evaluation"), "derived/runtime_summary.json"
    assert_includes map.fetch("self_improvement"),
                    "failures/failure_observation.json"
    assert_includes map.fetch("self_improvement"),
                    "derived/invalid_run_triage_note.json"
  end

  # 配置規約: writer 系は runtime/execution_v2/writers/ 配下
  def test_writer_placement_under_writers_dir
    assert (ROOT + "runtime/execution_v2/writers/evidence_writer.rb").exist?
    assert (ROOT + "runtime/execution_v2/writers/review_case_projector.rb").exist?
  end
end
