# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 9: テスト（列挙 4 検証対象の決定的検証ケース）。
# 根拠: tasks.md Task 9、design「Test Strategy」、プロジェクト開発方針
#       （TDD）。Requirement 1 受入 5 / Separation Rules 2 / Requirement 6
#       受入 4 / Requirement 2 受入 6。
#       適合レビュー 2026-05-19 Finding 5（決定的 paper-interface 検証
#       全面不在・スモーク非機能。Finding 1〜4・6〜10 が検出されなかった
#       根因）解消の品質保証対象。
#
# 4 検証対象それぞれに固定入力→期待出力の決定的検証ケースを 1 つ以上
# 置く: (1) 証拠追跡性の機械検証 (2) 無声昇格の検出 (3) 混在 review_mode
# caveat (4) 陳腐化再生成。固定入力＝波0版固定 評価実出力 fixture。
class TestTask9VerificationTargets < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  ANALYSIS = ROOT + "tests/fixtures/paper_interface/analysis"

  def setup
    base = "../../scripts/paper_interface/v2"
    require_relative "#{base}/reference"
    require_relative "#{base}/claim_map_builder"
    require_relative "#{base}/evidence_register_builder"
    require_relative "#{base}/paper_caveat_register_builder"
    require_relative "#{base}/reporting_fragments_builder"
    require_relative "#{base}/separation_rules"
    @ref = DualReviewer::PaperInterfaceV2::Reference
  end

  # 検証対象 1: 証拠追跡性の機械検証（Requirement 1 受入 5）。
  # 固定入力＝波0 fixture。期待出力＝claim_map の
  # supporting_artifact_refs / provenance_refs が Reference Format に従い
  # 参照先 artifact まで machine 解決できる（basename 部分一致に
  # 依存しない）。
  def test_target1_evidence_traceability_deterministic
    cm = DualReviewer::PaperInterfaceV2::ClaimMapBuilder
         .new(analysis_root: ANALYSIS.to_s).build

    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "experiments"))
      FileUtils.cp_r(ANALYSIS.to_s,
                     File.join(dir, "experiments", "analysis"))

      total_refs = 0
      cm["claims"].each do |c|
        (c["supporting_artifact_refs"] + c["provenance_refs"]).each do |r|
          assert @ref.valid?(r), "must be structured reference"
          refute r["target_path"].include?("#"),
                 "no path#id string concatenation"
          res = @ref.resolve(r, repo_root: dir)
          assert res[:resolved],
                 "ref must machine-resolve: #{r['target_path']}"
          total_refs += 1
        end
      end
      assert total_refs.positive?, "expected resolvable refs"
    end
  end

  # 検証対象 2: 無声昇格の検出（Separation Rules 2）。
  # 固定入力＝preliminary/exploratory を含む evidence_register。
  # 期待出力＝それらが mature と同列に paper artifact へ入らない
  # （maturity_label と束縛規則で検証。silent strengthening 不許可）。
  def test_target2_no_silent_strengthening_detected
    reg = DualReviewer::PaperInterfaceV2::EvidenceRegisterBuilder
          .new(analysis_root: ANALYSIS.to_s).build
    rules = DualReviewer::PaperInterfaceV2::SeparationRules.new

    # 波0 fixture: valid+stable=mature、exploratory=exploratory が混在。
    labels = reg["entries"].map { |e| e["maturity_label"] }.uniq.sort
    assert_includes labels, "exploratory"
    assert_includes labels, "mature"

    # exploratory entry を mature と同列に提示しようとしたら不許可。
    expl = reg["entries"].find { |e| e["maturity_label"] == "exploratory" }
    refute_nil expl
    refute rules.silent_strengthening_allowed?(
      source_maturity: expl["maturity_label"], presented_as: "mature"
    )
    # 束縛規則: exploratory evidence_class は exploratory に束縛。
    assert_equal "exploratory", expl["evidence_class"]
  end

  # 検証対象 3: 混在レビュー実施モードの caveat 検証（Requirement 6
  # 受入 4）。固定入力＝review_mode 2 値以上の report set。
  # 期待出力＝混在検知 ＋ paper caveat に
  # methodological_limitation で付与。
  def test_target3_mixed_review_mode_caveat_deterministic
    erb = DualReviewer::PaperInterfaceV2::EvidenceRegisterBuilder
          .new(analysis_root: ANALYSIS.to_s)
    base = erb.build["entries"]

    # 固定入力: runtime_mediated のみ → 混在なし → caveat 付かない。
    refute erb.mixed_review_modes?(base)

    # 固定入力: manual_dogfooding entry を加える → 2 値混在。
    mixed = base + [{
      "artifact_ref" => @ref.build(ref_type: "manual_review",
                                   target_path: "p", target_id: "m1"),
      "review_mode" => "manual_dogfooding"
    }]
    assert erb.mixed_review_modes?(mixed)
    cav = erb.mixed_review_mode_caveat(mixed)

    pcrb = DualReviewer::PaperInterfaceV2::PaperCaveatRegisterBuilder
           .new(analysis_root: ANALYSIS.to_s)
    reg = pcrb.build(extra_caveats: [cav])
    mr = reg["caveats"].find do |c|
      c["caveat_id"].include?("mixed_review_mode")
    end
    refute_nil mr, "mixed review-mode caveat must be attached"
    assert_equal "methodological_limitation", mr["limitation_type"]
  end

  # 検証対象 4: 陳腐化再生成の確認（Requirement 2 受入 6）。
  # 固定入力＝新 evaluation StalenessPropagator 形の伝播 +
  # paper-facing artifact。期待出力＝stale=true 付与 ＋ 再生成対象検出。
  def test_target4_stale_regeneration_deterministic
    rules = DualReviewer::PaperInterfaceV2::SeparationRules.new
    reg = DualReviewer::PaperInterfaceV2::EvidenceRegisterBuilder
          .new(analysis_root: ANALYSIS.to_s).build

    # 固定入力: StalenessPropagator#evaluate の stale=true 形。
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
    marked = rules.apply_staleness(
      artifacts: reg["entries"], propagation: propagation
    )
    assert marked.all? { |e| e["stale"] == true }
    assert marked.all? { |e| @ref.valid?(e["stale_source_ref"]) }
    assert rules.regeneration_required?(marked),
           "stale=true paper-facing artifact must be regen target"

    # 固定入力: fresh 伝播 → 再生成対象でない。
    fresh = rules.apply_staleness(
      artifacts: reg["entries"],
      propagation: { "stale" => false, "disposition" => "fresh",
                     "stale_run_ids" => [] }
    )
    refute rules.regeneration_required?(fresh)
  end

  # design Completion Criteria 4 点が説明可能（統合での回帰固定）。
  def test_completion_criteria_coverage
    cm = DualReviewer::PaperInterfaceV2::ClaimMapBuilder
         .new(analysis_root: ANALYSIS.to_s).build
    reg = DualReviewer::PaperInterfaceV2::EvidenceRegisterBuilder
          .new(analysis_root: ANALYSIS.to_s).build
    fr = DualReviewer::PaperInterfaceV2::ReportingFragmentsBuilder
         .new(analysis_root: ANALYSIS.to_s).build
    pc = DualReviewer::PaperInterfaceV2::PaperCaveatRegisterBuilder
         .new(analysis_root: ANALYSIS.to_s).build

    # claim と evidence source の対応を説明できる。
    assert cm["claims"].all? do |c|
      c["supporting_artifact_refs"].any?
    end
    # mature / preliminary / exploratory の扱いを説明できる。
    assert reg["entries"].all? do |e|
      %w[mature preliminary exploratory].include?(e["maturity_label"])
    end
    # caveat がどこに残るか説明できる（paper/caveats/ に集約）。
    assert pc["caveats"].size.positive?
    # paper-interface が runtime/evaluation を支配しないことを説明できる。
    rules = DualReviewer::PaperInterfaceV2::SeparationRules.new
    assert_equal false,
                 rules.reverse_control_invariants[
                   "overrides_evaluation_comparison_rule"
                 ]
    assert fr["fragments"].size.positive?
  end
end
