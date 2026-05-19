# frozen_string_literal: true

require "minitest/autorun"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 7: reporting fragment model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 7、Requirement 5 受入 3・4、
#       design「Reporting Fragment Model」「Key Decision 3」。
#       適合レビュー 2026-05-19 Finding 群（決定的検証皆無）解消。
#
# 決定的固定入力＝波0版固定 評価実出力 fixture。
class TestReportingFragments < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  ANALYSIS = ROOT + "tests/fixtures/paper_interface/analysis"

  def setup
    require_relative "../../scripts/paper_interface/v2/" \
                     "reporting_fragments_builder"
    require_relative "../../scripts/paper_interface/v2/reference"
    @ref = DualReviewer::PaperInterfaceV2::Reference
    @builder = DualReviewer::PaperInterfaceV2::ReportingFragmentsBuilder
              .new(analysis_root: ANALYSIS.to_s)
  end

  def build
    @builder.build
  end

  # design: fragment は fragment_id / fragment_type /
  # source_artifact_refs / maturity_label / caveat_refs / text_stub。
  def test_fragment_shape
    fr = build
    assert fr["fragments"].size.positive?
    fr["fragments"].each do |f|
      %w[fragment_id fragment_type source_artifact_refs
         maturity_label caveat_refs text_stub].each do |k|
        assert f.key?(k), "fragment must have #{k}"
      end
      assert @ref.all_valid?(f["source_artifact_refs"])
    end
  end

  # design Decision 3: fragment は manuscript そのものでない（text_stub）。
  def test_fragment_is_not_manuscript
    build["fragments"].each do |f|
      assert f["text_stub"].is_a?(String)
      assert_includes %w[claim_summary method_note limitation_note
                         comparison_summary], f["fragment_type"]
    end
  end

  # design 集約規則: maturity_label は出典の最も保守的な値
  # （exploratory < preliminary < mature）。
  def test_conservative_maturity_aggregation
    agg = @builder.aggregate_maturity(%w[mature preliminary mature])
    assert_equal "preliminary", agg
    agg2 = @builder.aggregate_maturity(%w[mature exploratory preliminary])
    assert_equal "exploratory", agg2
    agg3 = @builder.aggregate_maturity(%w[mature mature])
    assert_equal "mature", agg3
  end

  # Requirement 5 受入 3: 出典ごとの成熟度区分を fragment 内に保持し
  # 束ねても見えなくしない。
  def test_per_source_maturity_preserved
    multi = build["fragments"].find do |f|
      f["fragment_type"] == "comparison_summary"
    end
    refute_nil multi
    assert multi.key?("per_source_maturity")
    assert multi["per_source_maturity"].is_a?(Array)
    multi["per_source_maturity"].each do |s|
      assert s.key?("source_artifact_ref")
      assert s.key?("maturity_label")
      assert @ref.valid?(s["source_artifact_ref"])
    end
  end

  # Requirement 5 受入 4: 成熟度の異なる出典を単一未分化値へ圧縮しない
  # （集約値は保守表示で per_source_maturity の保持を代替しない）。
  def test_aggregate_does_not_replace_per_source
    f = build["fragments"].find do |x|
      x["fragment_type"] == "comparison_summary"
    end
    sources = f["per_source_maturity"].map { |s| s["maturity_label"] }
    assert_equal @builder.aggregate_maturity(sources),
                 f["maturity_label"]
    # per_source は集約後も残る（圧縮しない）。
    assert f["per_source_maturity"].size >= 1
  end

  # 無声昇格の検出（Task 9 検証対象2）と整合: 1 つでも低い出典があれば
  # fragment 全体が低い値になり mature と同列にしない。
  def test_no_silent_strengthening_in_fragment
    sources = %w[preliminary mature]
    assert_equal "preliminary",
                 @builder.aggregate_maturity(sources)
  end
end
