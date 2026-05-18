# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 5: comparison model（treatment / phase-aware / valid population /
# 比較可能性条件、評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 5、Requirement 2 受入 1〜6、Requirement 7 受入 2・3・5、
#       design「Comparison Model §1〜§3」「Key Decision 3」。
#       runtime treatment_matrix（Treatment×Step 正本・runtime 所有）、
#       runtime 所有 comparison_eligibility_note（最小 6 項目）。
#       適合レビュー 2026-05-19 finding 6（protocol/prompt version
#       uniformity 比較可能性条件）/ finding 4（撤廃 review_mode 語彙非依存）。
#
# 入力は第1波が版固定した実 runtime 出力形 fixture
# （tests/fixtures/evaluation/local_runs/*）。version 混在・phase 別など
# 新ケースは metadata 差し替えで実 runtime artifact 形状を保ったまま作る
# （experiments/runs/ 非汚染・raw 不変）。
class TestComparisonModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  LOCAL = ROOT + "tests/fixtures/evaluation/local_runs"

  def setup
    require_relative "../../scripts/evaluation/local_run_loader"
    require_relative "../../scripts/evaluation/classification_engine"
    require_relative "../../scripts/evaluation/metric_extractor"
    require_relative "../../scripts/evaluation/comparison_builder"
    require_relative "../../runtime/execution_v2/contracts/treatment_matrix"
    @loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: ROOT)
    @engine = DualReviewer::Evaluation::ClassificationEngine.new
    @extractor = DualReviewer::Evaluation::MetricExtractor.new
    @builder = DualReviewer::Evaluation::ComparisonBuilder.new
  end

  # fixture dir からの単 run record（classification + metric + metadata を
  # comparison builder 入力単位に束ねる）。
  def record(dir, run_root: nil)
    root = run_root || (LOCAL + dir)
    intake = @loader.load_run(run_root: root)
    cls = @engine.classify_local_run(run_intake: intake)
    metrics = @extractor.extract_from_run_intake(run_intake: intake)
    {
      "run_id" => cls["run_id"],
      "classification" => cls,
      "metrics" => metrics,
      "metadata" => intake.fetch("metadata", {}),
      "comparison_eligibility" => intake["comparison_eligibility"]
    }
  end

  def build(*records)
    @builder.build(run_records: records)
  end

  # 同一 case_id / phase 内で treatment を分けた compose 用 helper。
  # raw fixture を tmp に複製し metadata（treatment/run_id 等）を差し替える
  # （artifact 形状は実 runtime 準拠を維持）。
  def synthesized(dir, base:, overrides:)
    root = Pathname(base)
    FileUtils.cp_r((LOCAL + dir).to_s + "/.", root.to_s)
    rc = root + "review_case.json"
    data = JSON.parse(rc.read)
    overrides.each { |k, v| data["metadata"][k] = v }
    # treatment 上書き時は step_records.step_status を runtime Treatment×Step
    # 正本へ整合させる（実 runtime はこの matrix どおりに投影する。
    # artifact 形状を実 runtime 準拠に保つための整合であり、評価ロジックに
    # 合わせた捏造ではない）。
    tm = DualReviewer::Runtime::TreatmentMatrix
    treatment = data["metadata"]["treatment"]
    if tm.supported_treatments.include?(treatment) &&
       data["step_records"].is_a?(Array)
      states = tm.execution_state_for(treatment: treatment)
      data["step_records"].each do |sr|
        st = states[sr["step_id"]]
        sr["step_status"] = st if st
      end
    end
    rc.write(JSON.pretty_generate(data))
    rm = root + "run_manifest.yaml"
    if rm.file?
      text = rm.read
      overrides.each do |k, v|
        text = text.gsub(/^(\s*#{k}:).*$/, "\\1 #{v}")
      end
      rm.write(text)
    end
    note = root + "derived/comparison_eligibility_note.json"
    if note.file?
      nd = JSON.parse(note.read)
      nd["run_id"] = overrides["run_id"] if overrides.key?("run_id")
      nd["treatment"] = overrides["treatment"] if overrides.key?("treatment")
      nd["phase_profile"] = overrides["phase_profile"] if
        overrides.key?("phase_profile")
      note.write(JSON.pretty_generate(nd))
    end
    root
  end

  # --- treatment comparison（Req2 受入 1・2、design §1） ---------------------

  # single / dual / dual+judgment の treatment-aware aggregation。
  def test_treatment_comparison_three_variants
    Dir.mktmpdir do |dir|
      s = synthesized("exploratory_runtime_run",
                      base: File.join(dir, "single"),
                      overrides: { "run_id" => "r-single", "treatment" => "single",
                                   "phase_profile" => "design",
                                   "evidence_class" => "valid" })
      d = synthesized("valid_runtime_run",
                      base: File.join(dir, "dual"),
                      overrides: { "run_id" => "r-dual", "treatment" => "dual",
                                   "phase_profile" => "design" })
      dj = synthesized("valid_runtime_run",
                       base: File.join(dir, "dj"),
                       overrides: { "run_id" => "r-dj",
                                    "treatment" => "dual+judgment",
                                    "phase_profile" => "design" })
      out = build(record(nil, run_root: s), record(nil, run_root: d),
                  record(nil, run_root: dj))
      tc = out["treatment_comparisons"]
      assert_equal "valid", tc["comparison_status"]
      assert_equal %w[dual dual+judgment single],
                   tc["treatments_present"].sort
      # treatment identity を全 aggregate に見せる（受入 4）。
      tc["treatment_aggregates"].each do |agg|
        assert agg.key?("treatment")
        assert_kind_of Integer, agg["run_count"]
      end
    end
  end

  # treatment identity が comparison-relevant derived output 全てに出る
  # （Req2 受入 4）。
  def test_treatment_identity_visible_everywhere
    out = build(record("valid_runtime_run"))
    tc = out["treatment_comparisons"]
    assert(tc["treatment_aggregates"].all? { |a| a["treatment"] })
    out["phase_comparisons"]["phase_slices"].each do |ps|
      ps["treatments_present"].each { |t| refute_nil t }
    end
  end

  # --- 比較可能性条件（target / phase / version / eligibility） --------------

  # target condition 不一致は aggregate しない（Req2 受入 5）。
  def test_mismatched_target_condition_not_aggregated
    Dir.mktmpdir do |dir|
      a = synthesized("valid_runtime_run",
                       base: File.join(dir, "a"),
                       overrides: { "run_id" => "r-a", "treatment" => "dual",
                                    "target_id" => "spec/x/tasks.md" })
      b = synthesized("valid_runtime_run",
                       base: File.join(dir, "b"),
                       overrides: { "run_id" => "r-b",
                                    "treatment" => "dual+judgment",
                                    "target_id" => "spec/y/tasks.md" })
      out = build(record(nil, run_root: a), record(nil, run_root: b))
      tc = out["treatment_comparisons"]
      assert_equal "invalid", tc["comparison_status"]
      assert_includes tc["comparison_invalid_reason"],
                      "mismatched_target_condition"
      assert_empty tc["treatment_aggregates"]
    end
  end

  # protocol-version 混在は per-run metadata が揃っていても検出・報告し
  # aggregate しない（Req2 受入 6・5、finding 6）。
  def test_protocol_version_mix_detected_and_not_aggregated
    Dir.mktmpdir do |dir|
      a = synthesized("valid_runtime_run",
                       base: File.join(dir, "a"),
                       overrides: { "run_id" => "r-a", "treatment" => "dual",
                                    "protocol_version" => "1.0.0" })
      b = synthesized("valid_runtime_run",
                       base: File.join(dir, "b"),
                       overrides: { "run_id" => "r-b",
                                    "treatment" => "dual+judgment",
                                    "protocol_version" => "2.0.0" })
      out = build(record(nil, run_root: a), record(nil, run_root: b))
      tc = out["treatment_comparisons"]
      assert_equal "invalid", tc["comparison_status"]
      assert_includes tc["comparison_invalid_reason"],
                      "mixed_protocol_version"
      assert_empty tc["treatment_aggregates"]
    end
  end

  # prompt-version 混在も同様（finding 6: per-run metadata 完備でも検出）。
  def test_prompt_version_mix_detected
    Dir.mktmpdir do |dir|
      a = synthesized("valid_runtime_run",
                       base: File.join(dir, "a"),
                       overrides: { "run_id" => "r-a", "treatment" => "dual",
                                    "prompt_set_version" => "1.0.0" })
      b = synthesized("valid_runtime_run",
                       base: File.join(dir, "b"),
                       overrides: { "run_id" => "r-b",
                                    "treatment" => "dual+judgment",
                                    "prompt_set_version" => "1.1.0" })
      out = build(record(nil, run_root: a), record(nil, run_root: b))
      tc = out["treatment_comparisons"]
      assert_includes tc["comparison_invalid_reason"],
                      "mixed_prompt_version"
      assert_equal "invalid", tc["comparison_status"]
    end
  end

  # runtime-version / schema-version 混在も比較可能性条件として検出。
  def test_runtime_and_schema_version_mix_detected
    Dir.mktmpdir do |dir|
      a = synthesized("valid_runtime_run",
                       base: File.join(dir, "a"),
                       overrides: { "run_id" => "r-a", "treatment" => "dual",
                                    "runtime_version" => "0.1.0",
                                    "schema_set_version" => "1.0.0" })
      b = synthesized("valid_runtime_run",
                       base: File.join(dir, "b"),
                       overrides: { "run_id" => "r-b",
                                    "treatment" => "dual+judgment",
                                    "runtime_version" => "0.2.0",
                                    "schema_set_version" => "1.1.0" })
      out = build(record(nil, run_root: a), record(nil, run_root: b))
      tc = out["treatment_comparisons"]
      assert_includes tc["comparison_invalid_reason"],
                      "mixed_runtime_version"
      assert_includes tc["comparison_invalid_reason"],
                      "mixed_schema_set_version"
    end
  end

  # uniform version の comparison set は valid（混在検出が誤検知しない）。
  def test_uniform_version_set_is_valid
    Dir.mktmpdir do |dir|
      a = synthesized("valid_runtime_run",
                       base: File.join(dir, "a"),
                       overrides: { "run_id" => "r-a", "treatment" => "dual" })
      b = synthesized("valid_runtime_run",
                       base: File.join(dir, "b"),
                       overrides: { "run_id" => "r-b",
                                    "treatment" => "dual+judgment" })
      out = build(record(nil, run_root: a), record(nil, run_root: b))
      assert_equal "valid", out["treatment_comparisons"]["comparison_status"]
      assert_empty out["treatment_comparisons"]["comparison_invalid_reason"]
    end
  end

  # comparison_eligibility_note の不可理由を先に尊重する（design §1）。
  # note が ineligible を示す run は標準比較から外し理由を保持する。
  def test_eligibility_note_ineligibility_respected_first
    Dir.mktmpdir do |dir|
      a = synthesized("valid_runtime_run",
                       base: File.join(dir, "a"),
                       overrides: { "run_id" => "r-a", "treatment" => "dual" })
      note = Pathname(a) + "derived/comparison_eligibility_note.json"
      nd = JSON.parse(note.read)
      nd["eligible_for_standard_comparison"] = false
      nd["ineligibility_reason_codes"] = ["runtime_owned_ineligible"]
      note.write(JSON.pretty_generate(nd))
      b = synthesized("valid_runtime_run",
                       base: File.join(dir, "b"),
                       overrides: { "run_id" => "r-b",
                                    "treatment" => "dual+judgment" })
      out = build(record(nil, run_root: a), record(nil, run_root: b))
      tc = out["treatment_comparisons"]
      ids = tc["treatment_aggregates"].flat_map { |g| g["run_ids"] }
      refute_includes ids, "r-a"
      assert_includes out["respected_eligibility_note_exclusions"]
        .map { |e| e["run_id"] }, "r-a"
      assert_includes out["respected_eligibility_note_exclusions"]
        .first["ineligibility_reason_codes"], "runtime_owned_ineligible"
    end
  end

  # --- valid population rule（design §3、Decision 3） ------------------------

  # 標準 comparative metrics は valid population のみ。invalid/blocked は
  # 比較集団に入れない（ClassificationEngine の in_comparison_population 尊重）。
  def test_valid_population_only_in_standard_comparison
    out = build(record("valid_runtime_run"),
                record("invalid_runtime_run"),
                record("analysis_blocked_run"))
    tc = out["treatment_comparisons"]
    ids = tc["treatment_aggregates"].flat_map { |g| g["run_ids"] }
    assert_includes ids, "run-eval-valid-0001"
    refute_includes ids, "run-eval-invalid-0001"
    refute_includes ids, "run-eval-blocked-0001"
  end

  # exploratory は separate appendix-style aggregate に保持し主比較に混ぜない。
  def test_exploratory_separate_appendix_not_in_main
    out = build(record("valid_runtime_run"),
                record("exploratory_runtime_run"))
    main_ids = out["treatment_comparisons"]["treatment_aggregates"]
               .flat_map { |g| g["run_ids"] }
    refute_includes main_ids, "run-eval-exploratory-0001"
    appendix = out["exploratory_appendix"]
    refute_nil appendix
    app_ids = appendix["treatment_aggregates"].flat_map { |g| g["run_ids"] }
    assert_includes app_ids, "run-eval-exploratory-0001"
    # appendix は主比較と分離されたラベルを持つ。
    assert_equal "appendix", appendix["aggregate_role"]
  end

  # --- phase-aware comparison（Req7 受入 2・3・5、design §2） ----------------

  # 標準 slice intent/requirements/design/tasks。phase identity を保持。
  def test_phase_aware_slices_preserve_identity
    Dir.mktmpdir do |dir|
      d = synthesized("valid_runtime_run",
                       base: File.join(dir, "d"),
                       overrides: { "run_id" => "r-d", "treatment" => "dual",
                                    "phase_profile" => "design" })
      t = synthesized("valid_runtime_run",
                       base: File.join(dir, "t"),
                       overrides: { "run_id" => "r-t",
                                    "treatment" => "dual+judgment",
                                    "phase_profile" => "tasks" })
      out = build(record(nil, run_root: d), record(nil, run_root: t))
      pc = out["phase_comparisons"]
      phases = pc["phase_slices"].map { |s| s["phase_profile"] }.sort
      assert_equal %w[design tasks], phases
      pc["phase_slices"].each do |s|
        # phase identity を消さず保持し overlay 選択を明示（Req7 受入 3）。
        refute_nil s["phase_profile"]
        assert s.key?("selected_overlay")
      end
    end
  end

  # phase-distinct run を default で 1 集約に潰さない（Req7 受入 5）。
  def test_phase_distinct_runs_not_collapsed
    Dir.mktmpdir do |dir|
      d = synthesized("valid_runtime_run",
                       base: File.join(dir, "d"),
                       overrides: { "run_id" => "r-d", "treatment" => "dual",
                                    "phase_profile" => "design" })
      t = synthesized("valid_runtime_run",
                       base: File.join(dir, "t"),
                       overrides: { "run_id" => "r-t", "treatment" => "dual",
                                    "phase_profile" => "tasks" })
      out = build(record(nil, run_root: d), record(nil, run_root: t))
      assert_equal 2, out["phase_comparisons"]["phase_slices"].length
    end
  end

  # phase-specific overlay 選択を明示（design §2、Req7 受入 3）。
  def test_phase_overlay_selection_explicit
    out = build(record("valid_runtime_run")) # design phase
    slice = out["phase_comparisons"]["phase_slices"]
            .find { |s| s["phase_profile"] == "design" }
    assert_equal(
      %w[cross_section_consistency responsibility_boundary_defects
         failure_mode_omission_detection],
      slice["selected_overlay"]
    )
  end

  # --- treatment step omission vs runtime failure（Req2 受入 3） -------------

  # treatment-driven step omission（design_skip）は runtime failure と
  # 区別し、設計上 step を持たない run を比較から障害排除しない。
  def test_treatment_driven_skip_not_excluded_as_failure
    Dir.mktmpdir do |dir|
      single = synthesized("exploratory_runtime_run",
                            base: File.join(dir, "s"),
                            overrides: { "run_id" => "r-s",
                                         "treatment" => "single",
                                         "phase_profile" => "design",
                                         "evidence_class" => "valid" })
      dj = synthesized("valid_runtime_run",
                        base: File.join(dir, "dj"),
                        overrides: { "run_id" => "r-dj",
                                     "treatment" => "dual+judgment",
                                     "phase_profile" => "design" })
      out = build(record(nil, run_root: single), record(nil, run_root: dj))
      tc = out["treatment_comparisons"]
      ids = tc["treatment_aggregates"].flat_map { |g| g["run_ids"] }
      # single は step_b/step_c が treatment 由来 skip。障害排除しない。
      assert_includes ids, "r-s"
      assert_empty out["runtime_failure_excluded"]
    end
  end

  # runtime failure（印が宣言 treatment と矛盾）の run は比較から除外し
  # treatment-driven skip と区別する（Req2 受入 3）。
  def test_runtime_failure_excluded_and_distinguished
    Dir.mktmpdir do |dir|
      bad = synthesized("valid_runtime_run",
                         base: File.join(dir, "bad"),
                         overrides: { "run_id" => "r-bad",
                                      "treatment" => "dual+judgment" })
      # treatment=dual+judgment は step_c executed のはずだが skipped 印 ->
      # 宣言 treatment と矛盾 -> failure_gap（障害欠損）。
      rc = Pathname(bad) + "review_case.json"
      rcd = JSON.parse(rc.read)
      rcd["step_records"].each do |s|
        s["step_status"] = "skipped" if s["step_id"] == "step_c"
      end
      rc.write(JSON.pretty_generate(rcd))
      good = synthesized("valid_runtime_run",
                          base: File.join(dir, "good"),
                          overrides: { "run_id" => "r-good",
                                       "treatment" => "dual" })
      out = build(record(nil, run_root: bad), record(nil, run_root: good))
      tc = out["treatment_comparisons"]
      ids = tc["treatment_aggregates"].flat_map { |g| g["run_ids"] }
      refute_includes ids, "r-bad"
      assert_includes out["runtime_failure_excluded"]
        .map { |e| e["run_id"] }, "r-bad"
    end
  end

  # --- 撤廃 review_mode 語彙非依存（finding 4） -----------------------------

  def test_no_retired_review_mode_vocabulary_in_comparison
    src = File.read(ROOT + "scripts/evaluation/comparison_builder.rb")
    %w[single_review dual_review dual_reviewer_workflow].each do |retired|
      refute_includes src, retired
    end
  end

  # manual_dogfooding valid は明示 separate slice 以外、標準 runtime-mediated
  # 比較集団に silent 混入しない（Req9 連動・classification の
  # in_standard_runtime_comparison_set 尊重）。
  def test_manual_dogfooding_excluded_from_standard_comparison
    Dir.mktmpdir do |dir|
      md = synthesized("valid_runtime_run",
                        base: File.join(dir, "md"),
                        overrides: { "run_id" => "r-md", "treatment" => "dual",
                                     "review_mode" => "manual_dogfooding" })
      rm = synthesized("valid_runtime_run",
                        base: File.join(dir, "rm"),
                        overrides: { "run_id" => "r-rm",
                                     "treatment" => "dual+judgment" })
      out = build(record(nil, run_root: md), record(nil, run_root: rm))
      ids = out["treatment_comparisons"]["treatment_aggregates"]
            .flat_map { |g| g["run_ids"] }
      refute_includes ids, "r-md"
      assert_includes out["review_mode_excluded"].map { |e| e["run_id"] },
                      "r-md"
    end
  end

  # --- 決定性（Task 9 完了条件: 固定入力 -> 期待出力） -----------------------

  def test_comparison_is_deterministic
    a = build(record("valid_runtime_run"))
    b = build(record("valid_runtime_run"))
    assert_equal a, b
  end

  # paper-interface が読む shape（treatment_comparisons/phase_comparisons）を
  # 機械可読 first-class で出す（design Interfaces to Downstream Features）。
  def test_downstream_consumable_shape
    out = build(record("valid_runtime_run"))
    assert out.key?("treatment_comparisons")
    assert out.key?("phase_comparisons")
    tc = out["treatment_comparisons"]
    %w[comparison_status comparison_invalid_reason treatments_present
       treatment_aggregates].each { |k| assert tc.key?(k) }
    pc = out["phase_comparisons"]
    %w[comparison_status phase_slices].each { |k| assert pc.key?(k) }
  end
end
