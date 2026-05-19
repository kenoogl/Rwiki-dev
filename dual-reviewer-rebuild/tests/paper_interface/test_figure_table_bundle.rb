# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 5: figure / table bundle model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 5、Requirement 2（受入 1・2・4・5）、
#       design「Figure and Table Bundle Model §1〜§2」。
#       適合レビュー 2026-05-19 Finding 2（comparison キー不一致）・
#       Finding 8（exclusion 実体意味不整合）解消の品質保証対象。
#
# 決定的固定入力＝波0版固定 評価実出力 fixture。
class TestFigureTableBundle < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  ANALYSIS = ROOT + "tests/fixtures/paper_interface/analysis"

  def setup
    require_relative "../../scripts/paper_interface/v2/bundle_builder"
    require_relative "../../scripts/paper_interface/v2/reference"
    @ref = DualReviewer::PaperInterfaceV2::Reference
    @builder = DualReviewer::PaperInterfaceV2::BundleBuilder.new(
      analysis_root: ANALYSIS.to_s
    )
  end

  # design §1: table bundle entry は table_id / source_artifact_refs /
  # field_projection / maturity_label / caveat_refs を持つ。
  def test_table_bundle_entry_shape
    tb = @builder.build_table_bundle
    assert tb["tables"].size.positive?
    tb["tables"].each do |t|
      %w[table_id source_artifact_refs field_projection
         maturity_label caveat_refs].each do |k|
        assert t.key?(k), "table entry must have #{k}"
      end
      assert @ref.all_valid?(t["source_artifact_refs"])
      assert @ref.all_valid?(t["caveat_refs"])
    end
  end

  # design §2: figure bundle entry は figure_id / source_artifact_refs /
  # plot_contract / maturity_label / caveat_refs を持つ。
  def test_figure_bundle_entry_shape
    fb = @builder.build_figure_bundle
    assert fb["figures"].size.positive?
    fb["figures"].each do |f|
      %w[figure_id source_artifact_refs plot_contract
         maturity_label caveat_refs].each do |k|
        assert f.key?(k), "figure entry must have #{k}"
      end
      assert @ref.all_valid?(f["source_artifact_refs"])
    end
  end

  # design §2: plot_contract は描画でなく slice/metric/grouping の
  # reporting-side definition。
  def test_plot_contract_is_reporting_side_definition
    @builder.build_figure_bundle["figures"].each do |f|
      pc = f["plot_contract"]
      assert pc.is_a?(Hash)
      %w[slice metric grouping].each { |k| assert pc.key?(k) }
      refute pc.key?("renderer")
      refute pc.key?("image_path")
    end
  end

  # Finding 2 解消: comparison source は新 evaluation 実体キー
  # （treatments_present / treatment_aggregates / selected_overlay）を
  # field_projection に持つ（旧 available_treatments/overlay_metric_profile
  # を死参照しない）。
  def test_field_projection_uses_new_comparison_keys
    proj = @builder.build_table_bundle["tables"]
           .flat_map { |t| t["field_projection"] }
    refute_includes proj, "available_treatments"
    refute_includes proj, "available_phases"
    refute_includes proj, "overlay_metric_profile"
    assert(proj.any? { |p| p.include?("treatments_present") } ||
           proj.any? { |p| p.include?("treatment_aggregates") })
  end

  # Finding 8 解消: exclusion source は新実体（total_excluded /
  # population_separation、entries=除外のみ）の構造化集計を消費する。
  def test_exclusion_projection_uses_new_exclusion_keys
    t = @builder.build_table_bundle["tables"].find do |x|
      x["table_id"].include?("exclusion")
    end
    refute_nil t
    assert(t["field_projection"].any? { |p| p.include?("total_excluded") })
    assert(t["field_projection"].any? do |p|
      p.include?("population_separation")
    end)
  end

  # Requirement 2 受入 1・2: source artifact required field 定義 ＋
  # evaluation output への provenance linkage を要求。
  def test_provenance_linkage_back_to_evaluation
    [@builder.build_table_bundle["tables"],
     @builder.build_figure_bundle["figures"]].each do |coll|
      coll.each do |e|
        e["source_artifact_refs"].each do |r|
          assert r["target_path"].start_with?("experiments/analysis/"),
                 "source must link to evaluation output"
        end
      end
    end
  end

  # Requirement 2 受入 4: upstream evaluation output 不変なら再生成可能
  # （決定的＝同一入力で同一出力）。
  def test_regeneration_is_deterministic
    a = @builder.build_table_bundle
    b = DualReviewer::PaperInterfaceV2::BundleBuilder.new(
      analysis_root: ANALYSIS.to_s
    ).build_table_bundle
    assert_equal a, b
  end

  # Requirement 2 受入 5 / Requirement 4 受入 2: formatting 都合のみで
  # runtime/foundation schema 変更を強制しない（bundle は projection 名の
  # 宣言に留まり source 実体スキーマを書き換える指示を出さない）。
  def test_no_schema_mutation_directive
    json = JSON.dump(@builder.build_table_bundle) +
           JSON.dump(@builder.build_figure_bundle)
    refute_match(/schema_change|mutate_schema|add_runtime_field/i, json)
  end
end
