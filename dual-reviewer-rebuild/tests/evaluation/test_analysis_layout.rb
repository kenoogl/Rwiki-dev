# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 1: experiments/analysis/ directory skeleton（評価所有）
# 根拠: tasks.md Task 1、Requirement 5 受入 1・3、design「Analysis Artifact
#       Layout」「Placement Rationale」「Key Decision 1」（evaluation は run
#       artifact を mutate しない）。適合レビュー finding 9（skeleton 現存性）。
#
# TDD 先行: 実装前に期待入出力を固定する。実 runtime 出力 fixture は
# tests/fixtures/evaluation/local_runs/ 配下（実 runtime をスクラッチ再実装後の
# 実体出力をコピーして版固定したもの）。raw（experiments/runs 相当）は不変。
class TestAnalysisLayout < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../scripts/evaluation/analysis_layout"
    @dir = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # design「Analysis Artifact Layout」の正本出力先を列挙できる。
  def test_canonical_artifact_catalog_matches_design_layout
    expected = %w[
      imports/ingestion_register.json
      imports/admission_register.json
      manifests/analysis_run_manifest.yaml
      classifications/run_classification_index.json
      classifications/exclusion_report.json
      metrics/run_metrics.json
      metrics/finding_metrics.json
      metrics/treatment_metrics.json
      comparisons/treatment_comparisons.json
      comparisons/phase_comparisons.json
      caveats/caveat_register.json
    ].sort
    assert_equal expected,
                 DualReviewer::Evaluation::AnalysisLayout.artifact_catalog.keys.sort
  end

  # 正本サブディレクトリ集合（design Placement Rationale）。
  def test_canonical_subdirectories
    assert_equal %w[caveats classifications comparisons imports manifests metrics],
                 DualReviewer::Evaluation::AnalysisLayout.subdirectories.sort
  end

  # 各 artifact に Placement Rationale の役割説明が付く（可説明性）。
  def test_every_artifact_has_placement_rationale
    DualReviewer::Evaluation::AnalysisLayout.artifact_catalog.each do |rel, role|
      refute_nil role, "#{rel} に役割説明が無い"
      refute_empty role.to_s.strip, "#{rel} の役割説明が空"
    end
  end

  # create_skeleton は正本配置を analysis_root 配下に生成する。
  def test_create_skeleton_creates_canonical_layout
    analysis_root = @dir + "experiments" + "analysis"
    created = DualReviewer::Evaluation::AnalysisLayout.create_skeleton(
      analysis_root: analysis_root
    )
    DualReviewer::Evaluation::AnalysisLayout.subdirectories.each do |sub|
      assert (analysis_root + sub).directory?,
             "サブディレクトリ未生成: #{sub}"
      assert (analysis_root + sub + ".gitkeep").file?,
             ".gitkeep 未生成: #{sub}"
    end
    assert_kind_of Array, created
    assert_includes created, (analysis_root + "metrics").to_s
  end

  # 冪等性: 既存 skeleton 上で再実行しても破壊しない（再生成可能）。
  def test_create_skeleton_is_idempotent
    analysis_root = @dir + "experiments" + "analysis"
    DualReviewer::Evaluation::AnalysisLayout.create_skeleton(
      analysis_root: analysis_root
    )
    sentinel = analysis_root + "metrics" + "run_metrics.json"
    sentinel.write(JSON.generate("preexisting" => true))
    DualReviewer::Evaluation::AnalysisLayout.create_skeleton(
      analysis_root: analysis_root
    )
    assert_equal({ "preexisting" => true }, JSON.parse(sentinel.read),
                 "再実行が既存 derived artifact を破壊した")
  end

  # Decision 1: raw run と analysis artifact の境界を説明できる。
  # evaluation は run artifact を mutate しない（raw は別 storage）。
  def test_raw_derived_boundary_is_explained
    boundary = DualReviewer::Evaluation::AnalysisLayout.raw_derived_boundary
    assert_match(/experiments\/runs/, boundary["raw_evidence_root"])
    assert_match(/experiments\/analysis/, boundary["derived_artifact_root"])
    assert_equal false, boundary["evaluation_mutates_raw"]
    refute_empty boundary["rationale"].to_s.strip
  end

  # create_skeleton は raw run evidence（experiments/runs 相当）を一切作らない
  # / 触らない（Decision 1・Requirement 5 受入 3）。
  def test_create_skeleton_never_touches_raw_runs
    analysis_root = @dir + "experiments" + "analysis"
    DualReviewer::Evaluation::AnalysisLayout.create_skeleton(
      analysis_root: analysis_root
    )
    refute (@dir + "experiments" + "runs").exist?,
           "skeleton 生成が raw run storage を作成した（Decision 1 違反）"
  end
end
