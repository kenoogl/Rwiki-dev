# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 8: versioning と staleness 伝播（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 8、Requirement 5 受入 5・6・2、design「Versioning
#       Model」。analysis artifact を versioned output とし
#       analysis_run_manifest.yaml に 6 version フィールドを記録、derived
#       output から run/target identifier への linkage を保持、参照 run が
#       事後 invalidate された場合に derived artifact を stale 化／再導出。
#       foundation 無効化伝播義務（foundation 要件 6 受入 9）を入力起点と
#       する。raw 不変原則（design Decision 1）により巻き戻しは derived
#       再生成に閉じ raw を編集しない。
#       適合レビュー 2026-05-19 finding 7（staleness 伝播）/ finding 8。
#
# TDD 先行: 実装前に期待入出力を固定し赤を確認する。事後 invalidate ケースは
# invalidation_markers 追加など実 runtime 準拠の形で tmp に作り
# experiments/runs/ を汚染しない。
class TestVersioningStalenessModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  LOCAL = ROOT + "tests/fixtures/evaluation/local_runs"

  def setup
    require_relative "../../scripts/evaluation/local_run_loader"
    require_relative "../../scripts/evaluation/classification_engine"
    require_relative "../../scripts/evaluation/analysis_manifest_writer"
    require_relative "../../scripts/evaluation/staleness_propagator"
    @loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: ROOT)
    @engine = DualReviewer::Evaluation::ClassificationEngine.new
    @manifest = DualReviewer::Evaluation::AnalysisManifestWriter.new
    @stale = DualReviewer::Evaluation::StalenessPropagator.new
    @dir = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def record(dir, run_root: nil)
    intake = @loader.load_run(run_root: run_root || (LOCAL + dir))
    cls = @engine.classify_local_run(run_intake: intake)
    {
      "run_id" => cls["run_id"],
      "target_id" => intake.fetch("metadata", {})["target_id"],
      "classification" => cls
    }
  end

  # --- Versioning Model ------------------------------------------------------

  # Requirement 5 受入 5 / design Versioning Model: manifest に 6 version
  # フィールドを記録する。
  def test_manifest_has_six_versioning_fields
    m = @manifest.build_manifest(
      input_run_records: [record("valid_runtime_run")]
    )
    %w[analysis_logic_version input_run_set generated_at
       metric_set_version phase_metric_profile_version
       comparison_contract_version].each do |k|
      assert m.key?(k), "manifest に #{k} が無い"
      refute_nil m[k], "#{k} が nil"
    end
  end

  # Requirement 5 受入 2: derived output から run identifier / target
  # identifier への linkage を保持する。
  def test_manifest_preserves_run_and_target_linkage
    m = @manifest.build_manifest(
      input_run_records: [record("valid_runtime_run"),
                          record("invalid_runtime_run")]
    )
    link = m["run_target_linkage"]
    refute_nil link
    valid_id = record("valid_runtime_run")["run_id"]
    entry = link.find { |l| l["run_id"] == valid_id }
    refute_nil entry, "run_target_linkage に valid run が無い"
    assert_equal "spec/dual-reviewer-evaluation/tasks.md", entry["target_id"]
    assert_includes m["input_run_set"], valid_id
  end

  # design Versioning Model: 同一 raw run set でも analysis logic が変われば
  # 別 output 扱い（analysis_logic_version が manifest identity に効く）。
  def test_analysis_logic_version_change_yields_distinct_output_identity
    runs = [record("valid_runtime_run")]
    m1 = @manifest.build_manifest(input_run_records: runs)
    m2 = @manifest.build_manifest(
      input_run_records: runs, analysis_logic_version: "9.9.9-experimental"
    )
    assert_equal m1["input_run_set"], m2["input_run_set"],
                 "raw run set は同一のはず"
    refute_equal m1["analysis_logic_version"], m2["analysis_logic_version"]
    refute_equal @manifest.output_identity(manifest: m1),
                 @manifest.output_identity(manifest: m2),
                 "analysis logic 変更が別 output 扱いにならない"
  end

  # writer は出力先ディレクトリ未作成でも ENOENT を起こさない（mkpath 保証）。
  def test_manifest_writer_creates_missing_directories
    m = @manifest.build_manifest(input_run_records: [record("valid_runtime_run")])
    path = @manifest.write_manifest(
      manifest: m, analysis_root: @dir + "experiments" + "analysis"
    )
    assert Pathname(path).file?
    loaded = YAML.safe_load(Pathname(path).read)
    assert_equal m["analysis_logic_version"], loaded["analysis_logic_version"]
    assert_equal m["input_run_set"], loaded["input_run_set"]
  end

  # --- Staleness 伝播 --------------------------------------------------------

  # Requirement 5 受入 6 / design: 参照 run が事後 invalidate された場合、
  # その run を入力に含む derived artifact を stale フラグ付けする。
  # foundation 無効化伝播義務を入力起点（= raw invalidation_markers）とする。
  def test_post_hoc_invalidated_run_flags_derived_artifact_stale
    runs = [record("valid_runtime_run"), record("invalid_runtime_run")]
    m = @manifest.build_manifest(input_run_records: runs)

    # 事後 invalidate: valid だった run に raw invalidation marker が
    # 追加された状態を foundation 無効化伝播義務の入力起点として与える。
    valid_id = record("valid_runtime_run")["run_id"]
    current_state = {
      valid_id => {
        "invalidated" => true,
        "invalidation_marker_ids" => ["im-post-hoc-001"],
        "source" => "foundation_invalidation_propagation"
      }
    }

    result = @stale.evaluate(
      manifest: m, current_invalidation_state: current_state
    )
    assert_equal true, result["stale"]
    assert_includes result["stale_run_ids"], valid_id
    assert_equal "foundation_invalidation_propagation",
                 result["propagation_source"]
    affected = result["affected_derived_artifacts"]
    refute_empty affected
  end

  # 事後 invalidate された run を含まない manifest は stale にならない。
  def test_no_post_hoc_invalidation_keeps_artifact_fresh
    m = @manifest.build_manifest(input_run_records: [record("valid_runtime_run")])
    result = @stale.evaluate(manifest: m, current_invalidation_state: {})
    assert_equal false, result["stale"]
    assert_empty result["stale_run_ids"]
    assert_equal "fresh", result["disposition"]
  end

  # design / Requirement 5 受入 6: stale 化または再導出。再導出要求を
  # 立てられる（古い derived output を invalidate run の上に据え置かない）。
  def test_stale_artifact_requests_rederivation_not_left_unchanged
    runs = [record("valid_runtime_run")]
    m = @manifest.build_manifest(input_run_records: runs)
    valid_id = record("valid_runtime_run")["run_id"]
    result = @stale.evaluate(
      manifest: m,
      current_invalidation_state: {
        valid_id => { "invalidated" => true,
                      "invalidation_marker_ids" => ["im-x"] }
      }
    )
    assert_equal "rederive_required", result["disposition"]
    assert_equal true, result["leave_unchanged"] == false ||
                       result["rederivation_required"] == true
    assert result["rederivation_required"], "再導出要求が立たない"
  end

  # raw 不変原則（design Decision 1）: staleness 伝播は derived 再生成に
  # 閉じ raw を一切編集しない。事後 invalidate ケースの raw fixture 不変。
  def test_staleness_propagation_never_edits_raw
    before = JSON.parse((LOCAL + "valid_runtime_run" + "review_case.json").read)
    before_markers = JSON.parse(
      (LOCAL + "valid_runtime_run" + "validation" + "invalidation_markers.json").read
    )
    runs = [record("valid_runtime_run")]
    m = @manifest.build_manifest(input_run_records: runs)
    valid_id = record("valid_runtime_run")["run_id"]
    @stale.evaluate(
      manifest: m,
      current_invalidation_state: {
        valid_id => { "invalidated" => true,
                      "invalidation_marker_ids" => ["im-y"] }
      }
    )
    after = JSON.parse((LOCAL + "valid_runtime_run" + "review_case.json").read)
    after_markers = JSON.parse(
      (LOCAL + "valid_runtime_run" + "validation" + "invalidation_markers.json").read
    )
    assert_equal before, after, "staleness 伝播が raw review_case を編集した"
    assert_equal before_markers, after_markers,
                 "staleness 伝播が raw invalidation_markers を編集した"
  end

  # foundation 無効化伝播義務を入力起点とする決定的検証（finding 7）。
  # 同一固定入力 → 期待 stale 出力が決定的に再現する。
  def test_staleness_propagation_is_deterministic
    runs = [record("valid_runtime_run"), record("exploratory_runtime_run")]
    m = @manifest.build_manifest(input_run_records: runs)
    exp_id = record("exploratory_runtime_run")["run_id"]
    state = {
      exp_id => { "invalidated" => true,
                  "invalidation_marker_ids" => ["im-det-1"],
                  "source" => "foundation_invalidation_propagation" }
    }
    r1 = @stale.evaluate(manifest: m, current_invalidation_state: state)
    r2 = @stale.evaluate(manifest: m, current_invalidation_state: state)
    assert_equal r1, r2, "staleness 伝播が非決定的"
    assert_equal [exp_id], r1["stale_run_ids"]
  end
end
