# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 2: intake model（local run + portable bundle、評価所有）
# 根拠: tasks.md Task 2、Requirement 6 受入 1〜5、Requirement 10 受入 1〜3、
#       design「Intake Model」「Portable Bundle Intake」「Analysis Population
#       Selection」。runtime 新契約（review_case foundation 準拠 = validation_refs／
#       comparison_eligibility_note runtime 所有 6 項目／runtime_summary 非依存／
#       必須 metadata fail fast）。適合レビュー finding 1/4/9/10。
#
# 入力は実 runtime をスクラッチ再実装後の実体出力を版固定した fixture
# （tests/fixtures/evaluation/）。ハンドメイド仮装はしない。raw は不変。
class TestIntakeModel < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  LOCAL = ROOT + "tests/fixtures/evaluation/local_runs"
  BUNDLES = ROOT + "tests/fixtures/evaluation/imported_bundles"

  def setup
    require_relative "../../scripts/evaluation/local_run_loader"
    require_relative "../../scripts/evaluation/imported_bundle_loader"
    require_relative "../../scripts/evaluation/population_selector"
    @loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: ROOT)
  end

  # --- local run minimal intake (design Intake Model) -------------------------

  # 公開エントリ名（LocalRunLoader#load_run(run_root:)）を維持する。
  def test_local_run_loader_public_entry_preserved
    assert_respond_to @loader, :load_run
    out = @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    assert_kind_of Hash, out
    assert_equal "complete", out["intake_status"]
  end

  # 最小 intake artifact を読む（design Intake Model 列挙）。
  def test_minimal_intake_artifacts_loaded
    out = @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    a = out.fetch("artifacts")
    assert a.key?("run_manifest")
    assert a.key?("review_case")
    assert a.key?("decision_units")
    assert a.key?("validator_result")
    assert a.key?("invalidation_markers")
    assert a.key?("comparison_eligibility_note")
  end

  # runtime 新契約: review_case は foundation スキーマ準拠 = validation_refs
  # （旧 validation_artifacts 命名に依存しない）。finding 1 解消。
  def test_review_case_validation_refs_resolved_from_foundation_schema
    out = @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    rc = out.fetch("artifacts").fetch("review_case")
    assert rc.key?("validation_refs"),
           "runtime 実体は validation_refs を出す（foundation review_case schema）"
    refute rc.key?("validation_artifacts"),
           "旧 v1 命名 validation_artifacts に依存してはならない"
    vr = out.fetch("validation_refs")
    assert_equal "validation/validator_result.json", vr["validator_result_ref"]
    assert_kind_of Array, vr["invalidation_marker_refs"]
  end

  # standard aggregate の一次入力は review_case + validation artifact であり
  # derived/runtime_summary.json に依存しない（design Derivation Rule・中心問い2）。
  def test_intake_does_not_depend_on_runtime_summary
    out = @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    refute out.fetch("artifacts").key?("runtime_summary")
    refute out.fetch("required_artifacts").value?("derived/runtime_summary.json")
    assert_equal "review_case.json+validation_artifacts",
                 out.fetch("primary_aggregate_input")
  end

  # comparison_eligibility_note は runtime 所有スキーマ最小 6 項目で読む
  # （再定義しない。finding 10 解消の入口）。
  def test_comparison_eligibility_note_read_with_runtime_owned_min_fields
    out = @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    note = out.fetch("artifacts").fetch("comparison_eligibility_note")
    %w[run_id eligible_for_standard_comparison ineligibility_reason_codes
       treatment phase_profile generated_at].each do |k|
      assert note.key?(k), "comparison_eligibility_note 最小項目欠落: #{k}"
    end
  end

  # v2-compatible optional intake が読めなくても standard intake は成立する。
  def test_optional_v2_intake_absence_does_not_block_standard_intake
    out = @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    assert_equal "complete", out["intake_status"]
    refute out.fetch("artifacts").key?("v2_review_artifact")
  end

  # --- required metadata fail fast (Requirement 6 受入 1〜3・5) ---------------

  # 必須 metadata が揃う valid run は standard aggregation 可。
  def test_metadata_completeness_passes_for_valid_run
    out = @loader.load_run(run_root: LOCAL + "valid_runtime_run")
    check = @loader.standard_aggregation_readiness(run_intake: out)
    assert_equal true, check["ready_for_standard_aggregation"]
    assert_empty check["insufficiency_diagnostics"]
  end

  # 必須 intake 入力欠落（decision_units 除去）+ run_status!=closed の
  # analysis_blocked 相当 run は standard aggregation を fail fast し
  # insufficiency diagnostics を出す（捏造しない）。
  def test_metadata_insufficiency_fails_fast_with_diagnostics
    out = @loader.load_run(run_root: LOCAL + "analysis_blocked_run")
    assert_equal "incomplete", out["intake_status"]
    assert_includes out["missing_artifacts"], "decisions/decision_units.json"

    check = @loader.standard_aggregation_readiness(run_intake: out)
    assert_equal false, check["ready_for_standard_aggregation"]
    refute_empty check["insufficiency_diagnostics"]
    codes = check["insufficiency_diagnostics"].map { |d| d["code"] }
    assert_includes codes, "required_intake_input_missing"
    assert_includes codes, "run_status_not_closed"
    # narrative から欠落 metadata を捏造しない（受入 5）。
    check["insufficiency_diagnostics"].each do |d|
      refute_nil d["observed"]
      refute d.key?("inferred_value"),
             "欠落 metadata を narrative から捏造してはならない"
    end
  end

  # missing（入力なし）と invalid（入力はあるが contract 違反）を区別する
  # （Requirement 1 受入 4、design §3）。intake 段では missing を検出。
  def test_missing_distinguished_from_invalid_at_intake
    blocked = @loader.load_run(run_root: LOCAL + "analysis_blocked_run")
    invalid = @loader.load_run(run_root: LOCAL + "invalid_runtime_run")
    assert_equal "incomplete", blocked["intake_status"]   # missing 入力
    assert_equal "complete", invalid["intake_status"]     # 入力は揃う
  end

  # --- portable bundle intake (Requirement 10 受入 1〜3) ----------------------

  def test_portable_bundle_minimal_intake
    bl = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: ROOT)
    out = bl.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
    assert_equal "complete", out["intake_status"]
    m = out.fetch("bundle_manifest")
    assert_equal "external-repo-A", m["source_repository_id"]
    assert_equal "ext-rev-001", m["source_revision"]
    a = out.fetch("run_artifacts")
    %w[run_manifest review_case decision_units validator_result
       invalidation_markers comparison_eligibility_note].each do |k|
      assert a.key?(k), "bundle exported 最小入力欠落: #{k}"
    end
    assert a.fetch("review_case").key?("validation_refs"),
           "bundle 内 review_case も foundation 準拠 validation_refs"
  end

  # required provenance 欠落時は intake 継続しても standard admission を
  # 与えない（design Portable Bundle Intake、Requirement 10 受入 2）。
  def test_missing_provenance_bundle_intake_continues_without_standard_admission
    bl = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: ROOT)
    out = bl.load_bundle(bundle_root: BUNDLES + "missing_provenance_bundle")
    # intake 自体は継続（run artifact は読める）。
    refute_empty out.fetch("run_artifacts")
    assert_equal false, out["eligible_for_standard_admission"]
    assert_includes out["missing_provenance"], "source_repository_id"
    assert_includes out["missing_provenance"], "source_revision"
  end

  # imported runtime-mediated bundle と manual dogfooding を区別できる
  # provenance（review_mode）を保持する（Requirement 10 受入 3）。
  def test_bundle_preserves_review_mode_provenance
    bl = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: ROOT)
    out = bl.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
    assert_equal "runtime_mediated", out.fetch("bundle_manifest")["review_mode"]
  end

  # --- analysis population selection (design Analysis Population Selection) ----

  # 再現可能な selection policy: run_status=closed / standard intake complete /
  # protocol-facing validation summary available / 同一 case_id・phase_profile
  # 内で比較 treatment が揃う。selection manifest に落とせる。
  def test_population_selection_is_reproducible_policy
    sel = DualReviewer::Evaluation::PopulationSelector.new(repo_root: ROOT)
    intakes = %w[valid_runtime_run invalid_runtime_run exploratory_runtime_run
                 analysis_blocked_run].map do |d|
      @loader.load_run(run_root: LOCAL + d)
    end
    manifest = sel.select(run_intakes: intakes)

    selected_ids = manifest.fetch("selected_run_ids")
    # closed + intake complete のみ標準母集団入口（valid/invalid/exploratory）。
    assert_includes selected_ids, "run-eval-valid-0001"
    # analysis_blocked（run_status!=closed / intake incomplete）は除外。
    refute_includes selected_ids, "run-eval-blocked-0001"

    policy = manifest.fetch("selection_policy")
    assert_equal true, policy["run_status_closed"]
    assert_equal true, policy["standard_intake_complete"]
    assert_equal true, policy["protocol_facing_validation_summary_available"]
    assert policy.key?("comparison_treatment_grouping")
    # refresh workflow に落とせる形（manifest に track/case/phase filter 固定）。
    assert manifest.key?("refresh_inputs")
    assert manifest.fetch("refresh_inputs").key?("local_runs_root")
  end

  # 同一 fixture から 2 回選定して結果が一致する（決定的・再現可能）。
  def test_population_selection_deterministic
    sel = DualReviewer::Evaluation::PopulationSelector.new(repo_root: ROOT)
    intakes = %w[valid_runtime_run exploratory_runtime_run].map do |d|
      @loader.load_run(run_root: LOCAL + d)
    end
    a = sel.select(run_intakes: intakes).fetch("selected_run_ids").sort
    b = sel.select(run_intakes: intakes).fetch("selected_run_ids").sort
    assert_equal a, b
  end
end
