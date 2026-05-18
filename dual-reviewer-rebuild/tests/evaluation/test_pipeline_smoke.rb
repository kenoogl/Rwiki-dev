# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 9: end-to-end パイプラインスモーク（評価所有・スクラッチ再実装の最終波）
# 根拠: tasks.md Task 9、§4 Downstream Handoff、design「Architecture」
#       （intake → classification → metric → comparison → reporting）
#       「Analysis Artifact Layout」「Interfaces to Downstream Features」。
#       適合レビュー 2026-05-19 finding 3（決定的テスト不在）/ finding 9
#       （正本 skeleton・実行時生成）/ 中心問題（旧 fixture が runtime 出力
#       を仮装していた）の再発防止。
#
# 第1波が版固定した実 runtime 出力形 fixture（experiments/runs/ 由来でなく
# tests/fixtures/evaluation/local_runs/*）を入力に、評価 5 段の主経路が通り
# AnalysisLayout 正本出力先に artifact が生成され、downstream（self-
# improvement / paper-interface）が読む artifact が揃うことを決定的に通す。
# 出力は tmpdir。experiments/analysis/・experiments/runs/ を一切汚染しない。
# 少なくとも valid/invalid/exploratory/analysis_blocked が混在する population
# で 1 パス通す。
class TestPipelineSmoke < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  LOCAL = ROOT + "tests/fixtures/evaluation/local_runs"
  MIXED_POPULATION = %w[
    valid_runtime_run invalid_runtime_run
    exploratory_runtime_run analysis_blocked_run
  ].freeze

  def setup
    require_relative "../../scripts/evaluation/analysis_layout"
    require_relative "../../scripts/evaluation/local_run_loader"
    require_relative "../../scripts/evaluation/classification_engine"
    require_relative "../../scripts/evaluation/metric_extractor"
    require_relative "../../scripts/evaluation/comparison_builder"
    require_relative "../../scripts/evaluation/exclusion_report_builder"
    require_relative "../../scripts/evaluation/caveat_builder"
    require_relative "../../scripts/evaluation/analysis_manifest_writer"
    require_relative "../../scripts/evaluation/classification_writer"
    require_relative "../../scripts/evaluation/metric_writer"
    require_relative "../../scripts/evaluation/comparison_writer"
    require_relative "../../scripts/evaluation/exclusion_report_writer"
    require_relative "../../scripts/evaluation/caveat_writer"
    @loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: ROOT)
    @engine = DualReviewer::Evaluation::ClassificationEngine.new
    @extractor = DualReviewer::Evaluation::MetricExtractor.new
    @comparison = DualReviewer::Evaluation::ComparisonBuilder.new
    @exclusion = DualReviewer::Evaluation::ExclusionReportBuilder.new
    @caveat = DualReviewer::Evaluation::CaveatBuilder.new
    @manifest = DualReviewer::Evaluation::AnalysisManifestWriter.new
  end

  # tmpdir に AnalysisLayout 正本 skeleton を作り、混在 population を
  # 主経路へ通す。raw fixture は読み取りのみ（編集しない）。
  def run_pipeline(analysis_root:)
    DualReviewer::Evaluation::AnalysisLayout.create_skeleton(
      analysis_root: analysis_root
    )

    records = MIXED_POPULATION.map do |dir|
      intake = @loader.load_run(run_root: LOCAL + dir)
      cls = @engine.classify_local_run(run_intake: intake)
      metrics = @extractor.extract_from_run_intake(run_intake: intake)
      {
        "run_id" => cls["run_id"],
        "intake" => intake,
        "classification" => cls,
        "metrics" => metrics,
        "metadata" => intake.fetch("metadata", {}),
        "comparison_eligibility" => intake["comparison_eligibility"]
      }
    end

    classification_results = records.map { |r| r["classification"] }

    comparison_result = @comparison.build(
      run_records: records.map do |r|
        {
          "run_id" => r["run_id"],
          "classification" => r["classification"],
          "metrics" => r["metrics"],
          "metadata" => r["metadata"],
          "comparison_eligibility" => r["comparison_eligibility"]
        }
      end
    )

    exclusion_report = @exclusion.build(
      classification_results: classification_results
    )
    caveat_register = @caveat.build(
      classification_results: classification_results,
      comparison_result: comparison_result
    )

    # writers（mkpath 保証・ENOENT 非再発）。
    cls_writer = DualReviewer::Evaluation::ClassificationWriter.new(
      repo_root: analysis_root_repo(analysis_root)
    )
    met_writer = DualReviewer::Evaluation::MetricWriter.new(
      repo_root: analysis_root_repo(analysis_root)
    )
    cmp_writer = DualReviewer::Evaluation::ComparisonWriter.new(
      repo_root: analysis_root_repo(analysis_root)
    )
    exc_writer = DualReviewer::Evaluation::ExclusionReportWriter.new(
      analysis_root: analysis_root
    )
    cav_writer = DualReviewer::Evaluation::CaveatWriter.new(
      analysis_root: analysis_root
    )

    records.each do |r|
      cls_writer.write_classification(classification_result: r["classification"])
      met_writer.write_run_metrics(run_metrics: r["metrics"]["run_metrics"])
      met_writer.write_finding_metrics(
        finding_metrics: r["metrics"]["finding_metrics"]
      )
    end
    cmp_writer.write_treatment_comparisons(
      payload: comparison_result["treatment_comparisons"]
    )
    cmp_writer.write_phase_comparisons(
      payload: comparison_result["phase_comparisons"]
    )
    cmp_writer.write_treatment_metrics(
      payload: {
        "entries" =>
          comparison_result["treatment_comparisons"]["treatment_aggregates"]
      }
    )
    exc_writer.write(exclusion_report: exclusion_report)
    cav_writer.write(caveat_register: caveat_register)

    manifest = @manifest.build_manifest(
      input_run_records: records.map do |r|
        {
          "run_id" => r["run_id"],
          "target_id" => r["metadata"]["target_id"],
          "classification" => r["classification"]
        }
      end
    )
    @manifest.write_manifest(manifest: manifest, analysis_root: analysis_root)

    {
      "records" => records,
      "comparison_result" => comparison_result,
      "exclusion_report" => exclusion_report,
      "caveat_register" => caveat_register,
      "manifest" => manifest
    }
  end

  # ClassificationWriter / MetricWriter / ComparisonWriter は repo_root から
  # experiments/analysis/... を解決する。tmpdir を repo_root 見立てにする。
  def analysis_root_repo(analysis_root)
    Pathname(analysis_root).parent.parent
  end

  # downstream（design「Interfaces to Downstream Features」）が読む
  # artifact 群が正本配置に揃うことを確認する。
  SELF_IMPROVEMENT_INPUTS = %w[
    classifications/run_classification_index.json
    classifications/exclusion_report.json
    metrics/run_metrics.json
    metrics/finding_metrics.json
    caveats/caveat_register.json
  ].freeze
  PAPER_INTERFACE_INPUTS = %w[
    comparisons/treatment_comparisons.json
    comparisons/phase_comparisons.json
    classifications/exclusion_report.json
    caveats/caveat_register.json
  ].freeze

  def test_mixed_population_pipeline_produces_downstream_artifacts
    Dir.mktmpdir do |tmp|
      analysis_root = Pathname(tmp) + "experiments" + "analysis"
      result = run_pipeline(analysis_root: analysis_root)

      (SELF_IMPROVEMENT_INPUTS | PAPER_INTERFACE_INPUTS).each do |rel|
        path = analysis_root + rel
        assert path.file?, "downstream artifact 未生成: #{rel}"
        # JSON として読めること（machine-readable first-class）。
        JSON.parse(path.read)
      end

      # 混在 population: 4 状態すべてが classification index に出る。
      idx = JSON.parse(
        (analysis_root + "classifications/run_classification_index.json").read
      )
      states = idx["entries"].map { |e| e["classification"] }.sort.uniq
      assert_equal %w[analysis_blocked exploratory invalid valid], states

      # exclusion report に valid 以外が除外計上される。
      exc = JSON.parse(
        (analysis_root + "classifications/exclusion_report.json").read
      )
      excluded_runs = exc["entries"].map { |e| e["run_id"] }
      assert_includes excluded_runs, "run-eval-invalid-0001"
      assert_includes excluded_runs, "run-eval-blocked-0001"
      refute_includes excluded_runs, "run-eval-valid-0001"

      # treatment_comparisons は valid population のみで成立する。
      tc = JSON.parse(
        (analysis_root + "comparisons/treatment_comparisons.json").read
      )
      assert_equal "valid", tc["comparison_status"]

      # manifest は 6 version フィールド + run/target linkage を持つ。
      man = YAML.safe_load((analysis_root + "manifests/analysis_run_manifest.yaml").read)
      %w[analysis_logic_version input_run_set generated_at
         metric_set_version phase_metric_profile_version
         comparison_contract_version].each do |k|
        refute_nil man[k], "manifest に #{k} が無い"
      end
    end
  end

  # 旧 fixture が runtime 出力を仮装していた再発防止: 入力 fixture が runtime
  # 実体投影規約（review_case.validation_refs / human_decision_ref=
  # "decisions/human_signoff.json"・# 無し）であることを確認し、評価が
  # その実体形を消費して metric が成立することを通す。
  def test_input_fixture_is_runtime_shaped_not_disguised
    rc = JSON.parse((LOCAL + "valid_runtime_run" + "review_case.json").read)
    # runtime 新契約: validation_refs（旧 v1 の validation_artifacts ではない）。
    assert rc.key?("validation_refs"),
           "fixture が runtime 投影規約 validation_refs を持たない"
    refute rc.key?("validation_artifacts"),
           "fixture が旧 v1 命名 validation_artifacts を仮装している"
    rc["findings"].each do |f|
      # human_decision_ref は run レベル sign-off pointer（# フラグメント無し）。
      assert_equal "decisions/human_signoff.json", f["human_decision_ref"],
                   "fixture が runtime が出さない # 付き ref を仮装している"
    end
    # その実体形で metric の label 解決が機能する（unresolved にならない）。
    m = @extractor.extract_from_run_intake(
      run_intake: @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    )
    assert_equal 2, m["run_metrics"]["accepted_findings"]
    fm = m["finding_metrics"]["judgment_label_distribution"]
    assert_equal 0, fm["unresolved_judgment_labels"]
  end

  # 決定的: 同一固定入力 population から 2 回パスして同一 derived 結果。
  def test_pipeline_is_deterministic
    Dir.mktmpdir do |a|
      Dir.mktmpdir do |b|
        ra = run_pipeline(analysis_root: Pathname(a) + "experiments" + "analysis")
        rb = run_pipeline(analysis_root: Pathname(b) + "experiments" + "analysis")
        assert_equal ra["comparison_result"], rb["comparison_result"]
        assert_equal ra["exclusion_report"], rb["exclusion_report"]
        assert_equal ra["caveat_register"], rb["caveat_register"]
        assert_equal ra["manifest"]["input_run_set"],
                     rb["manifest"]["input_run_set"]
      end
    end
  end

  # raw fixture 不変（評価は raw を一切編集しない・design Decision 1）。
  def test_pipeline_never_mutates_raw_fixture
    before = MIXED_POPULATION.to_h do |d|
      [d, JSON.parse((LOCAL + d + "review_case.json").read)]
    end
    Dir.mktmpdir do |tmp|
      run_pipeline(analysis_root: Pathname(tmp) + "experiments" + "analysis")
    end
    MIXED_POPULATION.each do |d|
      after = JSON.parse((LOCAL + d + "review_case.json").read)
      assert_equal before[d], after,
                   "パイプラインが raw fixture #{d} を編集した"
    end
  end
end
