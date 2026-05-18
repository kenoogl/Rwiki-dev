# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 6: exclusion / caveat reporting（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 6、Requirement 4 受入 1〜5、Requirement 1 受入 3、
#       design「Exclusion and Caveat Model §1 Exclusion Report・§2 Caveat
#       Register」「Key Decision 4」。
#       入力は ClassificationEngine（分類・除外理由の正本）＋
#       ComparisonBuilder（version 混在・exploratory appendix・eligibility
#       note 除外・review-mode 除外の正本）。出力先は第1波 AnalysisLayout。
#       適合レビュー 2026-05-19 finding（writer 系 mkpath 不具合の再発防止）。
#
# TDD 先行: 実装前に期待入出力を固定し赤を確認する。fixture は第1波が
# 版固定した実 runtime 出力 fixture（tests/fixtures/evaluation/local_runs/）。
# raw（experiments/runs 相当）は不変。
class TestExclusionCaveatModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  LOCAL = ROOT + "tests/fixtures/evaluation/local_runs"

  def setup
    require_relative "../../scripts/evaluation/local_run_loader"
    require_relative "../../scripts/evaluation/classification_engine"
    require_relative "../../scripts/evaluation/metric_extractor"
    require_relative "../../scripts/evaluation/comparison_builder"
    require_relative "../../scripts/evaluation/exclusion_report_builder"
    require_relative "../../scripts/evaluation/exclusion_report_writer"
    require_relative "../../scripts/evaluation/caveat_builder"
    require_relative "../../scripts/evaluation/caveat_writer"
    @loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: ROOT)
    @engine = DualReviewer::Evaluation::ClassificationEngine.new
    @extractor = DualReviewer::Evaluation::MetricExtractor.new
    @comparison = DualReviewer::Evaluation::ComparisonBuilder.new
    @exclusion = DualReviewer::Evaluation::ExclusionReportBuilder.new
    @caveat = DualReviewer::Evaluation::CaveatBuilder.new
    @dir = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def classify(dir)
    intake = @loader.load_run(run_root: LOCAL + dir)
    @engine.classify_local_run(run_intake: intake)
  end

  def record(dir)
    intake = @loader.load_run(run_root: LOCAL + dir)
    cls = @engine.classify_local_run(run_intake: intake)
    {
      "run_id" => cls["run_id"],
      "classification" => cls,
      "metrics" => @extractor.extract_from_run_intake(run_intake: intake),
      "metadata" => intake.fetch("metadata", {}),
      "comparison_eligibility" => intake["comparison_eligibility"]
    }
  end

  # --- Task 6 §1 Exclusion Report --------------------------------------------

  # design §1: exclusion_report は run ごとに 6 フィールドを持つ
  # （run_id / classification / reason_codes / reason_details /
  #  phase_profile / treatment）。Requirement 4 受入 1。
  def test_exclusion_report_entry_has_six_design_fields
    results = %w[valid_runtime_run invalid_runtime_run
                 exploratory_runtime_run analysis_blocked_run].map { |d| classify(d) }
    report = @exclusion.build(classification_results: results)

    refute_empty report["entries"]
    report["entries"].each do |e|
      %w[run_id classification reason_codes reason_details
         phase_profile treatment].each do |k|
        assert e.key?(k), "exclusion entry に #{k} が無い"
      end
    end
  end

  # Requirement 4 受入 1: どの run がなぜ除外されたか記述する。
  # valid は除外されない（in_comparison_population=true）。
  def test_exclusion_report_lists_only_excluded_runs_with_reasons
    results = %w[valid_runtime_run invalid_runtime_run
                 exploratory_runtime_run analysis_blocked_run].map { |d| classify(d) }
    report = @exclusion.build(classification_results: results)

    excluded_ids = report["entries"].map { |e| e["run_id"] }
    valid_id = classify("valid_runtime_run")["run_id"]
    refute_includes excluded_ids, valid_id,
                    "valid run が exclusion_report に混入した"
    report["entries"].each do |e|
      refute_empty Array(e["reason_codes"]), "除外理由 code が空: #{e['run_id']}"
      refute_empty Array(e["reason_details"]), "除外理由 detail が空"
    end
  end

  # Requirement 1 受入 3 / Requirement 4 受入 4: 除外 run の counts と
  # reasons を保持し raw run log 手読みなしに exclusion counts を報告可能。
  def test_exclusion_counts_reportable_without_raw_log
    results = %w[valid_runtime_run invalid_runtime_run
                 exploratory_runtime_run analysis_blocked_run].map { |d| classify(d) }
    report = @exclusion.build(classification_results: results)

    counts = report["exclusion_counts"]
    assert_equal 3, report["total_excluded"]
    assert_equal 1, counts["invalid"]
    assert_equal 1, counts["exploratory"]
    assert_equal 1, counts["analysis_blocked"]
    refute counts.key?("valid"), "valid を除外集計に含めてはならない"
    # reason code ごとの集計も raw log なしに引ける。
    assert_kind_of Hash, report["exclusion_counts_by_reason_code"]
    refute_empty report["exclusion_counts_by_reason_code"]
  end

  # Requirement 4 受入 5 / Decision 4: invalid と valid を silent に
  # 1 集約へ潰さない（population_separation で明示分離）。
  def test_invalid_and_valid_population_not_collapsed
    results = %w[valid_runtime_run invalid_runtime_run].map { |d| classify(d) }
    report = @exclusion.build(classification_results: results)

    sep = report["population_separation"]
    assert_equal 1, sep["valid_population_count"]
    assert_equal 1, sep["excluded_population_count"]
    assert_equal false, sep["collapsed_into_single_aggregate"]
  end

  # writer は出力先ディレクトリ未作成でも ENOENT を起こさない（mkpath 保証）。
  # 適合レビュー finding の writer 系不具合を再発させない。
  def test_exclusion_report_writer_creates_missing_directories
    results = [classify("invalid_runtime_run")]
    report = @exclusion.build(classification_results: results)
    writer = DualReviewer::Evaluation::ExclusionReportWriter.new(
      analysis_root: @dir + "experiments" + "analysis"
    )
    path = writer.write(exclusion_report: report)
    assert Pathname(path).file?
    written = JSON.parse(Pathname(path).read)
    assert_equal report["entries"].length, written["entries"].length
    assert_equal report["total_excluded"], written["total_excluded"]
  end

  # --- Task 6 §2 Caveat Register ---------------------------------------------

  # design §2 / Requirement 4 受入 2: caveat は machine-readable first-class
  # artifact。paper-interface が raw archive 再読なしに継承できる構造。
  def test_caveat_register_is_machine_readable_first_class
    results = %w[valid_runtime_run exploratory_runtime_run].map { |d| classify(d) }
    cmp = @comparison.build(
      run_records: %w[valid_runtime_run exploratory_runtime_run].map { |d| record(d) }
    )
    register = @caveat.build(classification_results: results, comparison_result: cmp)

    assert_kind_of Array, register["caveats"]
    register["caveats"].each do |c|
      %w[caveat_code caveat_class severity details affected_scope].each do |k|
        assert c.key?(k), "caveat に #{k} が無い"
      end
    end
  end

  # Requirement 4 受入 3: data-quality caveat と runtime-quality caveat を
  # 区別する（caveat_class で機械的に弁別可能）。
  def test_data_quality_and_runtime_quality_caveats_distinguished
    results = %w[valid_runtime_run exploratory_runtime_run].map { |d| classify(d) }
    cmp = @comparison.build(
      run_records: %w[valid_runtime_run exploratory_runtime_run].map { |d| record(d) }
    )
    register = @caveat.build(classification_results: results, comparison_result: cmp)

    classes = register["caveats"].map { |c| c["caveat_class"] }.uniq
    classes.each do |cl|
      assert_includes %w[data_quality runtime_quality], cl,
                      "未知の caveat_class: #{cl}"
    end
    # 区別が後段で機械的に引けること（class 別索引）。
    assert register.key?("caveats_by_class")
    assert register["caveats_by_class"].keys.all? do |k|
      %w[data_quality runtime_quality].include?(k)
    end
  end

  # design §2: exploratory only slice の caveat（valid 無し・exploratory 有り）。
  def test_exploratory_only_slice_caveat_emitted
    results = [classify("exploratory_runtime_run")]
    cmp = @comparison.build(run_records: [record("exploratory_runtime_run")])
    register = @caveat.build(classification_results: results, comparison_result: cmp)

    codes = register["caveats"].map { |c| c["caveat_code"] }
    assert_includes codes, "exploratory_only_slice"
  end

  # design §2: low sample size の caveat（valid 母集団が閾値未満）。
  def test_low_sample_size_caveat_emitted
    results = [classify("valid_runtime_run")]
    cmp = @comparison.build(run_records: [record("valid_runtime_run")])
    register = @caveat.build(classification_results: results, comparison_result: cmp)

    codes = register["caveats"].map { |c| c["caveat_code"] }
    assert_includes codes, "low_sample_size"
  end

  # design §2: protocol drift across comparison set。version 混在を
  # ComparisonBuilder が comparison_invalid_reason に出した場合に
  # protocol drift caveat を runtime-quality として継承する。
  def test_protocol_drift_caveat_from_version_mixed_comparison
    base_a = @dir + "drift_a"
    base_b = @dir + "drift_b"
    FileUtils.cp_r((LOCAL + "valid_runtime_run").to_s + "/.", base_a.to_s)
    FileUtils.cp_r((LOCAL + "valid_runtime_run").to_s + "/.", base_b.to_s)
    rb = base_b + "review_case.json"
    data = JSON.parse(rb.read)
    data["metadata"]["run_id"] = "run-eval-valid-driftB"
    data["metadata"]["protocol_version"] = "2.0.0"
    rb.write(JSON.pretty_generate(data))

    rec_a = build_record_from_root(base_a)
    rec_b = build_record_from_root(base_b)
    cmp = @comparison.build(run_records: [rec_a, rec_b])
    results = [rec_a["classification"], rec_b["classification"]]
    register = @caveat.build(classification_results: results, comparison_result: cmp)

    drift = register["caveats"].find { |c| c["caveat_code"] == "protocol_drift" }
    refute_nil drift, "version 混在で protocol_drift caveat が出ない"
    assert_equal "runtime_quality", drift["caveat_class"]
  end

  # Requirement 4 受入 5 / Decision 4: caveat register も invalid/valid を
  # silent に潰さない。mixed maturity（valid と exploratory 混在）を残す。
  def test_mixed_maturity_caveat_not_silently_collapsed
    results = %w[valid_runtime_run exploratory_runtime_run].map { |d| classify(d) }
    cmp = @comparison.build(
      run_records: %w[valid_runtime_run exploratory_runtime_run].map { |d| record(d) }
    )
    register = @caveat.build(classification_results: results, comparison_result: cmp)

    codes = register["caveats"].map { |c| c["caveat_code"] }
    assert_includes codes, "mixed_maturity_evidence"
    assert_equal false, register["population_collapsed"]
  end

  def test_caveat_writer_creates_missing_directories
    results = [classify("valid_runtime_run")]
    cmp = @comparison.build(run_records: [record("valid_runtime_run")])
    register = @caveat.build(classification_results: results, comparison_result: cmp)
    writer = DualReviewer::Evaluation::CaveatWriter.new(
      analysis_root: @dir + "experiments" + "analysis"
    )
    path = writer.write(caveat_register: register)
    assert Pathname(path).file?
    written = JSON.parse(Pathname(path).read)
    assert_equal register["caveats"].length, written["caveats"].length
  end

  # raw run evidence（experiments/runs 相当・fixture）は一切編集しない
  # （Decision 1）。Task 6 は derived のみを生成する。
  def test_task6_never_mutates_raw_fixture
    before = JSON.parse((LOCAL + "valid_runtime_run" + "review_case.json").read)
    results = [classify("valid_runtime_run")]
    cmp = @comparison.build(run_records: [record("valid_runtime_run")])
    @exclusion.build(classification_results: results)
    @caveat.build(classification_results: results, comparison_result: cmp)
    after = JSON.parse((LOCAL + "valid_runtime_run" + "review_case.json").read)
    assert_equal before, after, "Task 6 が raw fixture を編集した（Decision 1 違反）"
  end

  private

  def build_record_from_root(root)
    intake = @loader.load_run(run_root: root)
    cls = @engine.classify_local_run(run_intake: intake)
    {
      "run_id" => cls["run_id"],
      "classification" => cls,
      "metrics" => @extractor.extract_from_run_intake(run_intake: intake),
      "metadata" => intake.fetch("metadata", {}),
      "comparison_eligibility" => intake["comparison_eligibility"]
    }
  end
end
