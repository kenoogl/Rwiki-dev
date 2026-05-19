# frozen_string_literal: true

require "minitest/autorun"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 6: caveat and limitation model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 6、Requirement 3（受入 1〜5）、
#       design「Caveat and Limitation Model」。
#       適合レビュー 2026-05-19 Finding 1（旧 caveat_register entries 形
#       依存）解消の品質保証対象。
#
# 決定的固定入力＝波0版固定 評価実出力 fixture（新 caveat 実体：
# caveats / caveats_by_class / caveat_class 軸）。
class TestPaperCaveatRegister < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  ANALYSIS = ROOT + "tests/fixtures/paper_interface/analysis"

  def setup
    require_relative "../../scripts/paper_interface/v2/" \
                     "paper_caveat_register_builder"
    require_relative "../../scripts/paper_interface/v2/reference"
    @ref = DualReviewer::PaperInterfaceV2::Reference
    @builder = DualReviewer::PaperInterfaceV2::PaperCaveatRegisterBuilder
              .new(analysis_root: ANALYSIS.to_s)
  end

  def build
    @builder.build
  end

  # design: paper_caveat_register entry は caveat_id /
  # source_caveat_ref / applies_to_claim_refs / applies_to_artifact_refs
  # / limitation_type / narrative_note を持つ。
  def test_entry_shape
    reg = build
    assert reg["caveats"].size.positive?
    reg["caveats"].each do |c|
      %w[caveat_id source_caveat_ref applies_to_claim_refs
         applies_to_artifact_refs limitation_type
         narrative_note].each do |k|
        assert c.key?(k), "paper caveat entry must have #{k}"
      end
    end
  end

  # design / Finding 1 解消: 新 evaluation caveat 実体（caveats[].
  # caveat_code）を構造化参照で継承（旧 entries[] 形に依存しない）。
  def test_source_caveat_ref_is_structured_and_targets_new_schema
    build["caveats"].each do |c|
      assert @ref.valid?(c["source_caveat_ref"])
      assert c["source_caveat_ref"]["target_path"]
             .end_with?("caveats/caveat_register.json")
      refute_nil c["source_caveat_ref"]["target_id"]
    end
  end

  # Requirement 3 受入 2 / design: limitation_type 正準 3 値。
  def test_limitation_type_canonical_enum
    allowed = %w[invalid_data_exclusion partial_evidence
                 methodological_limitation]
    build["caveats"].each do |c|
      assert_includes allowed, c["limitation_type"]
    end
  end

  # Requirement 3 受入 1: evidence source に紐づく caveat metadata を
  # 保持（applies_to_artifact_refs が構造化参照）。
  def test_applies_to_refs_structured
    build["caveats"].each do |c|
      assert @ref.all_valid?(c["applies_to_claim_refs"])
      assert @ref.all_valid?(c["applies_to_artifact_refs"])
    end
  end

  # Requirement 3 受入 3: paper-facing summary が raw archive 手読み
  # なしに caveat 参照できる（narrative_note は structured note・
  # manuscript 本文でない）。
  def test_narrative_note_is_structured_not_manuscript
    build["caveats"].each do |c|
      assert c["narrative_note"].is_a?(String)
      refute c["narrative_note"].empty?
    end
  end

  # Requirement 3 受入 5 / design「No Silent Strengthening」と整合:
  # caveated evidence を silent に strong evidence へ格上げしない
  # （caveat は maturity を強めない＝limitation_type が保持される）。
  def test_caveat_does_not_silently_upgrade
    build["caveats"].each do |c|
      refute_nil c["limitation_type"]
      refute_equal "", c["limitation_type"]
    end
  end

  # Requirement 6 受入 4 連携: mixed review-mode caveat を取り込めると
  # limitation_type=methodological_limitation で再配置できる。
  def test_mixed_review_mode_caveat_intake
    src = {
      "caveat_code" => "mixed_review_mode_evidence",
      "limitation_type_hint" => "mixed_review_mode",
      "review_modes" => %w[manual_dogfooding runtime_mediated],
      "details" => "mixed"
    }
    reg = @builder.build(extra_caveats: [src])
    e = reg["caveats"].find do |c|
      c["caveat_id"].include?("mixed_review_mode")
    end
    refute_nil e
    assert_equal "methodological_limitation", e["limitation_type"]
  end
end
