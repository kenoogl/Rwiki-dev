# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"
require "open3"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# self-improvement fixture 生成（実 runtime 出力 → 実 evaluation 出力）。
#
# 適合レビュー 2026-05-19 finding 1/2/3 の再発防止方針:
#   - ハンドメイドで仮装しない。再実装済み runtime modules を実際に駆動して
#     experiments/runs/<run_id>/ 相当の run tree を生成し、再実装済み
#     evaluation rebuild に通して experiments/analysis/ 相当を生成する。
#   - valid（異議 decision 含む）/ invalid（workflow failure + triage +
#     failure_observation）/ exploratory / valid-clean の差を作る。
#   - 実 experiments/ は汚さない（tmpdir で生成し版固定先へ複写）。
#   - runtime/evaluation のコードは読むだけ・変更しない。
#
# 版固定先:
#   tests/fixtures/self_improvement/runtime_runs/<variant>/...
#   tests/fixtures/self_improvement/analysis/...
#
# 決定性: 生成後に timestamp / run_id を決定的値へ正規化する（version 固定
# fixture が wall-clock で変動しないようにする）。
module SelfImprovementFixtureGenerator
  ROOT = Pathname(__dir__).join("..", "..", "..").expand_path # rebuild root
  FIXTURE_ROOT = ROOT + "tests/fixtures/self_improvement"
  RUNTIME_RUNS_DIR = FIXTURE_ROOT + "runtime_runs"
  ANALYSIS_DIR = FIXTURE_ROOT + "analysis"

  # 決定的 run_id（variant → 固定 id）。実 runtime は時刻ベース run_id を出す
  # ため、生成後にこの固定 id へ rewrite して fixture を安定させる。
  CANONICAL_RUN_IDS = {
    "valid_dissent_run" => "run-si-valid-dissent-0001",
    "invalid_workflow_failure_run" => "run-si-invalid-workflow-0001",
    "exploratory_run" => "run-si-exploratory-0001",
    "valid_clean_run" => "run-si-valid-clean-0001"
  }.freeze

  FIXED_TS = "2026-05-19T00:00:00Z"

  module_function

  # 固定応答 seam。variant ごとに findings / 役間 disagreement を変える。
  class Seam
    def initialize(variant)
      @variant = variant
    end

    def call(role:, step:, prompt_body:, target:, context:)
      case step
      when "primary_detection"
        { "findings" => primary_findings }
      when "adversarial_review"
        { "assessments" => assessments }
      when "judgment"
        { "judgments" => judgments }
      end
    end

    def primary_findings
      base = [
        { "finding_id" => "f1", "source_role" => "primary_reviewer",
          "requirement_link" => "R1", "severity" => "major",
          "summary" => "scope drift detected" }
      ]
      if %w[valid_dissent_run invalid_workflow_failure_run].include?(@variant)
        base << { "finding_id" => "f2", "source_role" => "primary_reviewer",
                  "requirement_link" => "R2", "severity" => "minor",
                  "summary" => "missing acceptance condition" }
      end
      base
    end

    def assessments
      a = [{ "finding_id" => "f1",
             "adversarial_outcome" => "no_counter_evidence_after_challenge" }]
      if %w[valid_dissent_run invalid_workflow_failure_run].include?(@variant)
        a << { "finding_id" => "f2",
                "adversarial_outcome" => "counter_evidence_raised" }
      end
      a
    end

    def judgments
      j = [{ "finding_id" => "f1", "final_label" => "necessary",
             "recommended_action" => "fix" }]
      if %w[valid_dissent_run invalid_workflow_failure_run].include?(@variant)
        j << { "finding_id" => "f2", "final_label" => "unnecessary",
                "recommended_action" => "drop" }
      end
      j
    end
  end

  # 1 variant を実 runtime modules で駆動して run tree を tmp に作る。
  # 戻り値: 生成 run_root（Pathname）。
  def drive_runtime_run(variant:, tmp_root:)
    require_relative "../../../runtime/controller/session_controller"
    require_relative "../../../runtime/execution_v2/analyzers/step_executors"
    require_relative "../../../runtime/execution_v2/decisions/step_d_integration"
    require_relative "../../../runtime/execution_v2/contracts/treatment_matrix"
    require_relative "../../../runtime/execution_v2/decisions/decision_units"
    require_relative "../../../runtime/execution_v2/writers/evidence_writer"
    require_relative "../../../runtime/execution_v2/validation/validation_bridge"

    ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: tmp_root)
    bridge = DualReviewer::Runtime::ExecutionV2::ValidationBridge.new(
      foundation_root: ROOT + "runtime/foundation"
    )

    treatment = variant == "exploratory_run" ? "single" : "dual+judgment"
    phase_profile = variant == "exploratory_run" ? "requirements" : "design"
    # invalid run: foundation metadata_contract.yaml review_mode.enum
    # （manual_dogfooding/runtime_mediated）外の値を渡し、実 validation_bridge
    # に contract violation（check_id=review_mode_not_in_contract_enum）を
    # 出させる。validator_status=failed・invalidation marker・triage note は
    # 実 runtime が生成する（仮装しない）。
    review_mode = if variant == "invalid_workflow_failure_run"
                    "legacy_single_review"
                  else
                    "runtime_mediated"
                  end

    inputs = {
      target_id: "spec/dual-reviewer-self-improvement/tasks.md",
      target_artifact_hash: "sha256:fixturegen",
      source_repository_id: "dual-reviewer-rebuild",
      source_revision: "rev-si-#{variant}",
      phase_profile: phase_profile,
      treatment: treatment,
      review_mode: review_mode,
      protocol_version: "1.0.0",
      runtime_version: "0.1.0",
      prompt_set_version: "1.0.0",
      schema_set_version: "1.0.0",
      config_version: "1.0.0",
      config_hash: "sha256:cfg",
      operator_id: "fixture-gen",
      track: "spec",
      source_refs: ["spec/dual-reviewer-self-improvement"]
    }

    run = ctrl.start_run(**inputs)
    run_root = tmp_root + "experiments/runs/#{run.run_id}"
    ex = DualReviewer::Runtime::StepExecutors.new(llm_seam: Seam.new(variant))
    writer = DualReviewer::Runtime::ExecutionV2::EvidenceWriter.new(
      run_root: run_root, run_id: run.run_id
    )
    writer.metadata = run.manifest_metadata

    matrix = DualReviewer::Runtime::TreatmentMatrix.execution_state_for(
      treatment: treatment
    )
    identity = lambda do |role|
      { "prompt_artifact_path" => "runtime/prompts/#{role}.md",
        "prompt_id" => "foundation.#{role}", "prompt_version" => "1.0.0",
        "role" => role }
    end

    step_a = step_b = step_c = nil
    if matrix["step_a"] == "executed"
      step_a = ex.run_step_a(target: { "artifact" => "x" },
                             phase_profile: phase_profile,
                             prompt_identity: identity.call("primary_reviewer"),
                             treatment: treatment)
      writer.write_raw_step(step_a)
    end
    if matrix["step_b"] == "executed"
      step_b = ex.run_step_b(target: {}, step_a_findings: step_a["findings"],
                             phase_profile: phase_profile,
                             prompt_identity:
                               identity.call("adversarial_reviewer"),
                             treatment: treatment)
      writer.write_raw_step(step_b)
    else
      writer.write_raw_step(
        DualReviewer::Runtime::StepExecutors.skip_marker(
          step_id: "step_b", step_name: "adversarial_review",
          treatment: treatment
        )
      )
    end
    if matrix["step_c"] == "executed"
      step_c = ex.run_step_c(step_a_findings: step_a["findings"],
                             step_b_assessments: step_b["assessments"],
                             phase_profile: phase_profile,
                             prompt_identity:
                               identity.call("judgment_reviewer"),
                             treatment: treatment)
      writer.write_raw_step(step_c)
    else
      writer.write_raw_step(
        DualReviewer::Runtime::StepExecutors.skip_marker(
          step_id: "step_c", step_name: "judgment", treatment: treatment
        )
      )
    end

    integ = DualReviewer::Runtime::StepDIntegration.new
    d = integ.integrate(step_a: step_a, step_b: step_b, step_c: step_c,
                        treatment: treatment)
    writer.write_raw_step(d[:step_d_record])

    dm = DualReviewer::Runtime::DecisionUnitModel.new(
      run_id: run.run_id, decision_units: d[:decision_units]
    )
    # valid_dissent_run: 1 件 approved + 1 件 rejected（review-quality 異議
    # 信号を実 decision_units から出させる）。他は全 approved。
    d[:decision_units].each_with_index do |u, idx|
      decision =
        if variant == "valid_dissent_run" && idx.odd?
          "rejected"
        elsif variant == "valid_dissent_run" && idx == 0
          "approved"
        else
          "approved"
        end
      dm.record_human_decision(decision_unit_id: u["decision_unit_id"],
                               decision: decision,
                               note: decision == "rejected" ? "reviewer dissent" : nil)
    end
    dm.write_decision_units(run_root: run_root)
    writer.write_decision_units(dm.decision_units)
    writer.write_metric_snapshot
    eligible = variant == "valid_clean_run"
    writer.write_comparison_eligibility_note(
      eligible_for_standard_comparison: eligible,
      ineligibility_reason_codes:
        eligible ? [] : ["non_standard_population_member"]
    )

    # invalid_workflow_failure_run: review 実行が failure mode に陥った
    # ことを runtime failure_observation 正本配置へ書く（foundation schema
    # 必須 6 項目を実 writer で満たす）。
    if variant == "invalid_workflow_failure_run"
      writer.write_failure_observation(
        failure_type: "validator_contract_violation",
        missed_by_role: "adversarial_reviewer",
        detected_at_step: "step_b",
        related_finding_ref: "f2"
      )
    end

    run.mark_step_d_complete
    signoff = dm.build_human_signoff(signed_off_by: "fixture-gen")
    run.write_human_signoff(
      status: signoff["human_signoff_status"], signed_off_by: "fixture-gen",
      covered_decision_unit_ids: signoff["covered_decision_unit_ids"]
    )
    run.freeze_raw_evidence
    run.invoke_validator do
      bridge.validate(run_id: run.run_id, metadata: run.manifest_metadata,
                      frozen_evidence: { "raw" => "frozen" })
    end
    run.close
    writer.write_review_case(
      validator_result_ref: "validation/validator_result.json",
      invalidation_marker_refs: []
    )
    run.finalize_post_close(validation_bridge: bridge)
    # finalize_post_close が review_case/manifest を再投影するため再書込で
    # writer 側の findings 投影を確定させる。
    writer.write_review_case(
      validator_result_ref: "validation/validator_result.json",
      invalidation_marker_refs:
        run.invalidation_markers.map { |m| m["marker_id"] }
    )

    # evidence_class の downstream 確定遷移を適用する。
    # foundation metadata_contract.yaml の candidate_note 正本どおり:
    #   candidate は runtime close 直後の未確定。validator_status と
    #   human_signoff_status が揃った後に valid / invalid / exploratory へ
    #   遷移する。これは捏造でなく契約が規定する post-close downstream 区分。
    final_class =
      if variant == "invalid_workflow_failure_run"
        "invalid"
      elsif variant == "exploratory_run"
        "exploratory"
      else
        "valid"
      end
    apply_evidence_class!(run_root: run_root, evidence_class: final_class)
    run_root
  end

  # review_case.json / run_manifest.yaml metadata の evidence_class を
  # contract 規定の post-close 区分へ確定する（raw step evidence は不変）。
  def apply_evidence_class!(run_root:, evidence_class:)
    rc_path = run_root + "review_case.json"
    rc = JSON.parse(rc_path.read)
    rc["metadata"]["evidence_class"] = evidence_class
    rc_path.write(JSON.pretty_generate(rc))

    rm_path = run_root + "run_manifest.yaml"
    rm = YAML.safe_load(rm_path.read)
    rm["metadata"]["evidence_class"] = evidence_class
    rm_path.write(rm.to_yaml)
  end

  # 生成 run tree の timestamp / run_id を決定的値へ正規化する。
  def normalize_run_tree!(run_root:, variant:)
    canonical = CANONICAL_RUN_IDS.fetch(variant)
    actual_run_id = run_root.basename.to_s
    dest = RUNTIME_RUNS_DIR + variant
    FileUtils.rm_rf(dest)
    FileUtils.mkdir_p(dest.dirname)
    FileUtils.cp_r(run_root, dest)

    ts_re = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z/
    Dir.glob(dest.join("**", "*"), File::FNM_DOTMATCH).each do |f|
      next unless File.file?(f)

      # .raw_evidence_frozen は freeze 時刻 marker。存在のみが意味を持つ。
      # version 固定 fixture を git で安定させるため固定値へ正規化する。
      if File.basename(f) == ".raw_evidence_frozen"
        File.write(f, FIXED_TS)
        next
      end

      txt = File.read(f, encoding: "UTF-8")
      txt = txt.gsub(actual_run_id, canonical)
      txt = txt.gsub(ts_re, FIXED_TS)
      File.write(f, txt)
    end
    dest
  end

  # 全 variant を実 runtime で生成し runtime_runs/ へ版固定。
  # 続けて実 evaluation rebuild に通し analysis/ を版固定。
  def regenerate!
    FileUtils.rm_rf(RUNTIME_RUNS_DIR)
    FileUtils.rm_rf(ANALYSIS_DIR)
    FileUtils.mkdir_p(RUNTIME_RUNS_DIR)
    FileUtils.mkdir_p(ANALYSIS_DIR)

    Dir.mktmpdir do |tmp|
      tmp_root = Pathname(tmp)
      CANONICAL_RUN_IDS.each_key do |variant|
        rr = drive_runtime_run(variant: variant, tmp_root: tmp_root)
        normalize_run_tree!(run_root: rr, variant: variant)
      end
    end

    run_dirs = CANONICAL_RUN_IDS.keys.map { |v| (RUNTIME_RUNS_DIR + v).to_s }
    Dir.mktmpdir do |etmp|
      etmp_root = Pathname(etmp)
      # rebuild script は repo_root から experiments/analysis を解決する。
      # repo を汚さないため tmp repo へ scripts/ を複写して走らせる。
      FileUtils.cp_r(ROOT + "scripts", etmp_root + "scripts")
      FileUtils.cp_r(ROOT + "runtime", etmp_root + "runtime")
      FileUtils.cp_r(ROOT + "tests", etmp_root + "tests")
      cmd = ["ruby",
             (etmp_root + "scripts/rebuild_evaluation_analysis_from_runs.rb").to_s,
             *CANONICAL_RUN_IDS.keys.map do |v|
               (etmp_root + "tests/fixtures/self_improvement/runtime_runs/#{v}").to_s
             end]
      out, err, st = Open3.capture3(*cmd)
      unless st.success?
        raise "evaluation rebuild failed: #{err}\n#{out}"
      end

      src_analysis = etmp_root + "experiments/analysis"
      FileUtils.cp_r(Dir.glob(src_analysis.join("*").to_s), ANALYSIS_DIR)
    end

    # analysis fixture の timestamp 正規化（決定性）。
    ts_re = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z/
    Dir.glob(ANALYSIS_DIR.join("**", "*")).each do |f|
      next unless File.file?(f)

      txt = File.read(f, encoding: "UTF-8")
      File.write(f, txt.gsub(ts_re, FIXED_TS))
    end
    true
  end
end

if $PROGRAM_NAME == __FILE__
  SelfImprovementFixtureGenerator.regenerate!
  puts "self-improvement fixtures regenerated"
end
