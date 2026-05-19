# frozen_string_literal: true

require "minitest/autorun"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 4: evidence register model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 4、Requirement 5（受入 1〜6）、Requirement 6
#       （受入 1〜5）、Requirement 1 受入 2、
#       design「Evidence Register Model §1〜§3」。
#       適合レビュー 2026-05-19 Finding 3（10 フィールド欠落・evidence_class
#       束縛未実装・構造化参照未実装）・Finding 4（review-mode 混在/置換系譜
#       未実装）解消の品質保証対象。
#
# 決定的固定入力＝波0版固定 評価実出力 fixture（実パイプライン出力、
# generated_at 正規化済み）。手で値を作らない。
class TestEvidenceRegister < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  ANALYSIS = ROOT + "tests/fixtures/paper_interface/analysis"

  def setup
    require_relative "../../scripts/paper_interface/v2/evidence_register_builder"
    require_relative "../../scripts/paper_interface/v2/reference"
    @ref = DualReviewer::PaperInterfaceV2::Reference
    @builder = DualReviewer::PaperInterfaceV2::EvidenceRegisterBuilder.new(
      analysis_root: ANALYSIS.to_s
    )
  end

  def build
    @builder.build
  end

  # design §2: evidence_register 各 entry は 10 フィールドを持つ。
  def test_entry_has_all_ten_fields
    reg = build
    assert reg["entries"].size.positive?
    reg["entries"].each do |e|
      %w[artifact_ref source_analysis_manifest_ref input_run_set_ref
         evidence_class review_mode maturity_label caveat_refs
         supersedes superseded_by generated_at].each do |k|
        assert e.key?(k), "evidence_register entry must have #{k}"
      end
    end
  end

  # design §1 束縛規則: invalid は paper-facing 対象外。
  def test_invalid_evidence_class_excluded_from_register
    classes = build["entries"].map { |e| e["evidence_class"] }
    refute_includes classes, "invalid"
  end

  # design §1 束縛規則: exploratory → maturity_label=exploratory。
  def test_exploratory_binds_to_exploratory_maturity
    e = build["entries"].find { |x| x["evidence_class"] == "exploratory" }
    refute_nil e
    assert_equal "exploratory", e["maturity_label"]
  end

  # design §1 束縛規則: valid かつ安定比較集合なら mature。
  def test_valid_in_stable_comparison_set_binds_to_mature
    e = build["entries"].find do |x|
      x["evidence_class"] == "valid" &&
        x["artifact_ref"]["target_id"] == "run-eval-valid-0001"
    end
    refute_nil e
    assert_equal "mature", e["maturity_label"]
  end

  # Requirement 5 受入 6: maturity_label は foundation evidence_class
  # （valid/invalid/exploratory）に束縛された派生分類で独立語彙でない。
  def test_maturity_label_bound_to_evidence_class
    build["entries"].each do |e|
      case e["evidence_class"]
      when "exploratory"
        assert_equal "exploratory", e["maturity_label"]
      when "valid"
        assert_includes %w[mature preliminary], e["maturity_label"]
      else
        flunk "unexpected evidence_class #{e['evidence_class']}"
      end
    end
  end

  # design §3 / Requirement 6 受入 1: review_mode を foundation 由来で
  # 保持し再定義しない（manual_dogfooding / runtime_mediated）。
  def test_review_mode_preserved_from_foundation_vocab
    build["entries"].each do |e|
      assert_includes %w[manual_dogfooding runtime_mediated],
                       e["review_mode"]
    end
  end

  # Requirement 1 受入 5 / design §3: 全 *_ref(s) が構造化参照。
  def test_all_refs_are_structured
    build["entries"].each do |e|
      assert @ref.valid?(e["artifact_ref"])
      assert @ref.valid?(e["source_analysis_manifest_ref"])
      assert @ref.valid?(e["input_run_set_ref"])
      assert @ref.all_valid?(e["caveat_refs"])
      assert @ref.all_valid?(e["supersedes"])
      assert @ref.all_valid?(e["superseded_by"])
    end
  end

  # Requirement 6 受入 4 / design「Review-Mode in Reporting」: report set
  # が参照する evidence_register entry の review_mode が 2 値以上のとき
  # 混在を機械検知し caveat を自動付与する（検知のみ／register API）。
  def test_mixed_review_mode_detection
    runtime_only = build["entries"]
    refute @builder.mixed_review_modes?(runtime_only)

    mixed = runtime_only + [{
      "artifact_ref" => @ref.build(ref_type: "run", target_path: "x",
                                   target_id: "manual-1"),
      "review_mode" => "manual_dogfooding"
    }]
    assert @builder.mixed_review_modes?(mixed)
    cav = @builder.mixed_review_mode_caveat(mixed)
    assert_equal "mixed_review_mode", cav["limitation_type_hint"]
    assert_equal %w[manual_dogfooding runtime_mediated],
                 cav["review_modes"].sort
  end

  # Requirement 5 受入 5 / Requirement 6 受入 5 / design §2・§3:
  # 早期手動証拠→後 runtime 証拠の置換系譜を supersedes/superseded_by で
  # 保存する。決定的固定入力で系譜リンクを検証する。
  def test_supersession_lineage_linking
    manual = {
      "artifact_ref" => @ref.build(ref_type: "manual_review",
                                   target_path: "p", target_id: "m1"),
      "review_mode" => "manual_dogfooding",
      "evidence_class" => "valid"
    }
    runtime = {
      "artifact_ref" => @ref.build(ref_type: "runtime_review",
                                   target_path: "q", target_id: "r1"),
      "review_mode" => "runtime_mediated",
      "evidence_class" => "valid"
    }
    linked = @builder.link_supersession(
      superseded: manual, superseding: runtime
    )
    assert @ref.all_valid?(linked[:superseded]["superseded_by"])
    assert @ref.all_valid?(linked[:superseding]["supersedes"])
    assert_equal "r1",
                 linked[:superseded]["superseded_by"]
                 .first["target_id"]
    assert_equal "m1",
                 linked[:superseding]["supersedes"].first["target_id"]
  end

  # design §4: stale 標識（stale/stale_reason/stale_source_ref）を
  # evidence_register entry に持たせる（既定 stale=false）。
  def test_stale_marker_fields_present_default_false
    build["entries"].each do |e|
      assert_equal false, e["stale"]
      assert_nil e["stale_reason"]
      assert_nil e["stale_source_ref"]
    end
  end
end
