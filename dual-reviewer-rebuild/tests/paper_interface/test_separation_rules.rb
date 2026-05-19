# frozen_string_literal: true

require "minitest/autorun"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 8: separation rules（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 8、Requirement 4（受入 1〜5）、Requirement 2 受入 6、
#       design「Separation Rules §1〜§4」。
#       適合レビュー 2026-05-19 Finding 6（stale 再生成全面欠落・新
#       evaluation StalenessPropagator と非接続）解消の品質保証対象。
#
# 決定的固定入力。StalenessPropagator の出力契約に整合する。
class TestSeparationRules < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  ANALYSIS = ROOT + "tests/fixtures/paper_interface/analysis"

  def setup
    require_relative "../../scripts/paper_interface/v2/separation_rules"
    require_relative "../../scripts/paper_interface/v2/reference"
    @ref = DualReviewer::PaperInterfaceV2::Reference
    @rules = DualReviewer::PaperInterfaceV2::SeparationRules.new
  end

  # design §1 No Reverse Control: runtime field 追加要求を出さない・
  # invalid run を valid evidence に格上げしない・evaluation comparison
  # rule を上書きしない・invalidation policy を override しない。
  def test_no_reverse_control_invariants
    inv = @rules.reverse_control_invariants
    assert_equal false, inv["requests_runtime_field_additions"]
    assert_equal false, inv["upgrades_invalid_to_valid"]
    assert_equal false, inv["overrides_evaluation_comparison_rule"]
    assert_equal false, inv["overrides_invalidation_policy"]
    assert_equal true, inv["paper_convenience_subordinate"]
  end

  # design §1 / Requirement 4 受入 1: invalid run を valid evidence へ
  # 格上げしようとしたら拒否する。
  def test_reject_invalid_to_valid_upgrade
    refute @rules.allow_evidence?(
      evidence_class: "invalid", requested_maturity: "mature"
    )
    assert @rules.allow_evidence?(
      evidence_class: "valid", requested_maturity: "mature"
    )
  end

  # design §2 No Silent Strengthening: preliminary/exploratory を
  # mature と同列にしない。
  def test_no_silent_strengthening
    refute @rules.silent_strengthening_allowed?(
      source_maturity: "preliminary", presented_as: "mature"
    )
    refute @rules.silent_strengthening_allowed?(
      source_maturity: "exploratory", presented_as: "mature"
    )
    assert @rules.silent_strengthening_allowed?(
      source_maturity: "mature", presented_as: "mature"
    )
  end

  # design §3 Self-Improvement Independence: self-improvement proposal を
  # claim support artifact にしない。adopted history は methodology note
  # 参照に留め performance claim の一次根拠にしない。
  def test_self_improvement_independence
    res = @rules.classify_self_improvement_reference(
      adopted_change_ref: @ref.build(ref_type: "self_improvement_adoption",
                                     target_path: "learning/x.json")
    )
    assert_equal "methodology_note", res["allowed_role"]
    assert_equal false, res["usable_as_primary_performance_claim"]
    assert_equal false, res["usable_as_claim_support_artifact"]
  end

  # design §4 / Requirement 2 受入 6: 新 evaluation StalenessPropagator
  # の出力（stale / stale_run_ids / propagation_source /
  # stale_marker_refs）を入力起点に paper-facing artifact へ
  # stale/stale_reason/stale_source_ref を付与し再生成対象にする。
  def test_stale_propagation_marks_artifacts_for_regeneration
    propagation = {
      "stale" => true,
      "disposition" => "rederive_required",
      "stale_run_ids" => ["run-eval-valid-0001"],
      "rederivation_required" => true,
      "propagation_source" => "foundation_invalidation_propagation",
      "affected_derived_artifacts" => [
        "comparisons/treatment_comparisons.json"
      ],
      "stale_marker_refs" => {
        "run-eval-valid-0001" => ["invalidation-marker-1"]
      }
    }
    artifacts = [
      { "artifact_ref" => @ref.build(ref_type: "evidence_register_entry",
                                     target_path: "paper/reports/" \
                                     "evidence_register.json",
                                     target_id: "run-eval-valid-0001"),
        "stale" => false, "stale_reason" => nil,
        "stale_source_ref" => nil }
    ]
    marked = @rules.apply_staleness(
      artifacts: artifacts, propagation: propagation
    )
    e = marked.first
    assert_equal true, e["stale"]
    refute_nil e["stale_reason"]
    assert @ref.valid?(e["stale_source_ref"])
    assert @rules.regeneration_required?(marked)
  end

  # design §4: fresh（stale=false）伝播では再生成対象にしない。
  def test_fresh_propagation_no_regeneration
    propagation = {
      "stale" => false, "disposition" => "fresh",
      "stale_run_ids" => [], "rederivation_required" => false,
      "propagation_source" => nil,
      "affected_derived_artifacts" => []
    }
    artifacts = [{ "artifact_ref" => @ref.build(ref_type: "x",
                                                target_path: "y"),
                   "stale" => false, "stale_reason" => nil,
                   "stale_source_ref" => nil }]
    marked = @rules.apply_staleness(
      artifacts: artifacts, propagation: propagation
    )
    assert_equal false, marked.first["stale"]
    refute @rules.regeneration_required?(marked)
  end

  # Requirement 4 受入 5: downstream narrative transformation を
  # explicit かつ versionable にする（変換記述に version を持つ）。
  def test_narrative_transformation_explicit_and_versionable
    t = @rules.narrative_transformation_descriptor
    assert t.key?("transformation_version")
    assert_equal true, t["explicit"]
    refute t["transformation_version"].to_s.empty?
  end

  # raw evidence・core evaluation output 不変（design Separation Rules /
  # tasks §5.2）: 巻き戻しは paper-facing artifact 再生成に閉じる。
  def test_rollback_scoped_to_paper_facing
    s = @rules.rollback_scope
    assert_equal "paper_facing_artifact_regeneration", s["scope"]
    assert_equal false, s["edits_raw_evidence"]
    assert_equal false, s["edits_core_evaluation_output"]
  end
end
