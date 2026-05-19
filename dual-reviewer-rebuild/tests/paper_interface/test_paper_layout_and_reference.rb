# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 1 / Task 2: paper/ directory skeleton ＋ reference format 共通基盤
# （論文インターフェース所有・スクラッチ再実装）。
# 根拠: tasks.md Task 1・Task 2、Requirement 2 受入 3、Requirement 1 受入 5、
#       design「Paper Artifact Layout」「Placement Rationale」
#       「Claim Mapping Model §3 Reference Format」。
#       適合レビュー 2026-05-19 Finding 9（paper/ skeleton 不在）・
#       Finding 3（構造化参照未実装）解消の品質保証対象。
#
# 決定的固定入力→期待出力。出力先は tmpdir（実 paper/ を汚さない）。
class TestPaperLayoutAndReference < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path

  def setup
    require_relative "../../scripts/paper_interface/v2/paper_layout"
    require_relative "../../scripts/paper_interface/v2/reference"
    @layout = DualReviewer::PaperInterfaceV2::PaperLayout
    @ref = DualReviewer::PaperInterfaceV2::Reference
  end

  # Task 1: 正本出力先を固定する（design「Paper Artifact Layout」）。
  def test_paper_layout_canonical_paths
    assert_equal "paper/reports/claim_map.json",
                 @layout::CLAIM_MAP
    assert_equal "paper/reports/evidence_register.json",
                 @layout::EVIDENCE_REGISTER
    assert_equal "paper/reports/reporting_fragments.json",
                 @layout::REPORTING_FRAGMENTS
    assert_equal "paper/tables/table_source_bundle.json",
                 @layout::TABLE_SOURCE_BUNDLE
    assert_equal "paper/figures/figure_source_bundle.json",
                 @layout::FIGURE_SOURCE_BUNDLE
    assert_equal "paper/caveats/paper_caveat_register.json",
                 @layout::PAPER_CAVEAT_REGISTER
  end

  # Task 1 完了条件: paper-facing artifact が paper/ 配下に分離されている
  # （raw evidence・core evaluation output と分離。基準ディレクトリが
  #  experiments/analysis/ と異なり衝突しない＝design Caveat Model）。
  def test_paper_artifacts_separated_under_paper_root
    @layout.all_artifacts.each do |rel|
      assert rel.start_with?("paper/"),
             "paper-facing artifact must live under paper/: #{rel}"
    end
    refute @layout.all_artifacts.any? { |r| r.start_with?("experiments/") }
    refute @layout.all_artifacts.any? { |r| r.start_with?("learning/") }
  end

  # Task 1: skeleton を tmpdir に物理生成できる（.gitkeep）。
  def test_skeleton_materialization
    Dir.mktmpdir do |dir|
      @layout.materialize_skeleton(paper_root: dir)
      %w[reports tables figures caveats].each do |sub|
        assert File.directory?(File.join(dir, sub)),
               "paper/#{sub}/ must exist"
        assert File.file?(File.join(dir, sub, ".gitkeep")),
               "paper/#{sub}/.gitkeep must exist"
      end
    end
  end

  # Task 2: *_ref は {ref_type, target_path, target_id} 構造化参照。
  def test_single_reference_shape
    r = @ref.build(
      ref_type: "evaluation_comparison",
      target_path: "experiments/analysis/comparisons/" \
                   "treatment_comparisons.json",
      target_id: "dual+judgment"
    )
    assert_equal(
      {
        "ref_type" => "evaluation_comparison",
        "target_path" =>
          "experiments/analysis/comparisons/treatment_comparisons.json",
        "target_id" => "dual+judgment"
      }, r
    )
  end

  # Task 2: target_id は任意（entry 単位でないとき省略）。
  def test_reference_without_target_id
    r = @ref.build(
      ref_type: "evaluation_caveat_register",
      target_path: "experiments/analysis/caveats/caveat_register.json"
    )
    assert_equal "evaluation_caveat_register", r["ref_type"]
    assert_nil r["target_id"]
    refute r.key?("dangling")
  end

  # Task 2: 裸パス文字列・裸識別子・basename 部分一致を正本判定に使わない
  # （Requirement 1 受入 5、design §1・§3）。bare string は reference でない。
  def test_bare_string_is_not_a_valid_reference
    refute @ref.valid?("experiments/analysis/comparisons/" \
                       "treatment_comparisons.json")
    refute @ref.valid?("treatment_comparisons.json#dual+judgment")
    refute @ref.valid?({ "path" => "x" })
    assert @ref.valid?(
      @ref.build(ref_type: "t", target_path: "p")
    )
  end

  # Task 2 完了条件: 構造化参照が参照先 artifact まで機械解決できる
  # （basename 部分一致に依存しない）。
  def test_reference_machine_resolution_against_analysis_root
    Dir.mktmpdir do |dir|
      analysis_root = File.join(dir, "experiments", "analysis")
      FileUtils.mkdir_p(File.join(analysis_root, "comparisons"))
      target = File.join(analysis_root, "comparisons",
                         "treatment_comparisons.json")
      File.write(target, JSON.dump({ "comparison_status" => "valid" }))

      r = @ref.build(
        ref_type: "evaluation_comparison",
        target_path:
          "experiments/analysis/comparisons/treatment_comparisons.json"
      )
      resolved = @ref.resolve(r, repo_root: dir)
      assert resolved[:resolved]
      assert_equal target, resolved[:absolute_path]
      assert_equal({ "comparison_status" => "valid" }, resolved[:payload])

      missing = @ref.build(
        ref_type: "evaluation_comparison",
        target_path: "experiments/analysis/comparisons/does_not_exist.json"
      )
      refute @ref.resolve(missing, repo_root: dir)[:resolved]
    end
  end
end
