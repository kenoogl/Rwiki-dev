# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 7: imported evidence intake artifacts（ingestion / admission register）
# 根拠: tasks.md Task 7、Requirement 10 受入 2〜5、design「Imported Evidence
#       Intake Artifacts」「Admission States for Imported Bundles」。
#       適合レビュー 2026-05-19 finding 4（撤廃 review_mode 語彙非依存）。
#
# 本 Task は admission 判定の単一所有者。判定ルールは design 優先順
#   rejected -> admitted_exploratory -> admitted_standard（最初に該当）。
# 入力は第1波が版固定した実 runtime 出力形 fixture。raw は不変。
class TestImportedEvidenceIntake < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/
  BUNDLES = ROOT + "tests/fixtures/evaluation/imported_bundles"

  def setup
    require_relative "../../scripts/evaluation/imported_bundle_loader"
    require_relative "../../scripts/evaluation/admission_evaluator"
    require_relative "../../scripts/evaluation/import_register_writer"
    @loader = DualReviewer::Evaluation::ImportedBundleLoader.new(repo_root: ROOT)
    @admission = DualReviewer::Evaluation::AdmissionEvaluator.new
  end

  # --- admission 優先順 3 状態（design Admission States、Req10 受入 4） --------

  # 必須 intake 入力完備・required provenance 完備・version 整合・invalidation
  # marker 無し -> admitted_standard。
  def test_standard_bundle_admitted_standard
    bundle = @loader.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
    result = @admission.evaluate(bundle_intake: bundle)
    assert_equal "admitted_standard", result["admission_status"]
    assert_equal true, result["eligible_for_standard_comparison"]
    assert_equal true, result["eligible_for_exploratory_analysis"]
    assert_equal "bundle-standard-0001", result["bundle_id"]
    assert_equal "run-eval-valid-0001", result["run_id"]
  end

  # required provenance（source_repository_id / source_revision）欠落 ->
  # 優先順最上位 rejected（Req10 受入 2: standard admission には完備が前提）。
  def test_missing_provenance_bundle_rejected
    bundle = @loader.load_bundle(bundle_root: BUNDLES + "missing_provenance_bundle")
    result = @admission.evaluate(bundle_intake: bundle)
    assert_equal "rejected", result["admission_status"]
    assert_includes result["admission_reason_codes"], "required_provenance_missing"
    assert_equal false, result["eligible_for_standard_comparison"]
    assert_equal false, result["eligible_for_exploratory_analysis"]
  end

  # bundle_manifest.yaml 不在 -> rejected（design: 不在または不正）。
  def test_absent_bundle_manifest_rejected
    Dir.mktmpdir do |dir|
      bundle = @loader.load_bundle(bundle_root: dir)
      result = @admission.evaluate(bundle_intake: bundle)
      assert_equal "rejected", result["admission_status"]
      assert_includes result["admission_reason_codes"],
                      "bundle_manifest_absent_or_invalid"
    end
  end

  # 必須 intake 入力が schema 不適合で読めない -> rejected。
  def test_unreadable_required_intake_input_rejected
    Dir.mktmpdir do |dir|
      root = Pathname(dir)
      (root + "bundle_manifest.yaml").write(<<~YAML)
        ---
        bundle_id: bundle-broken-0001
        run_id: run-broken-0001
        source_repository_id: ext-repo-B
        source_revision: ext-rev-broken
        review_mode: runtime_mediated
      YAML
      run_dir = root + "run" + "run-broken-0001"
      run_dir.mkpath
      # 必須 intake 入力を欠落させる（run_manifest 等が無い）。
      bundle = @loader.load_bundle(bundle_root: dir)
      result = @admission.evaluate(bundle_intake: bundle)
      assert_equal "rejected", result["admission_status"]
      assert_includes result["admission_reason_codes"],
                      "required_intake_input_unreadable"
    end
  end

  # 必須 intake 入力は読めるが invalidation marker あり -> standard には
  # しない（admitted_exploratory へ降格、優先順 2 番目）。
  def test_invalidation_marker_downgrades_to_exploratory
    Dir.mktmpdir do |dir|
      build_exploratory_bundle(dir, with_invalidation: true)
      bundle = @loader.load_bundle(bundle_root: dir)
      result = @admission.evaluate(bundle_intake: bundle)
      assert_equal "admitted_exploratory", result["admission_status"]
      assert_includes result["admission_reason_codes"], "invalidation_marker_present"
      assert_equal false, result["eligible_for_standard_comparison"]
      assert_equal true, result["eligible_for_exploratory_analysis"]
    end
  end

  # imported runtime-mediated bundle と manual dogfooding session を区別する
  # （Req10 受入 3）。canonical 語彙のみ（finding 4: 撤廃語彙非依存）。
  def test_distinguishes_runtime_mediated_from_manual_dogfooding
    std = @loader.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
    std_result = @admission.evaluate(bundle_intake: std)
    assert_equal "runtime_mediated", std_result["review_mode"]

    Dir.mktmpdir do |dir|
      build_exploratory_bundle(dir, review_mode: "manual_dogfooding")
      bundle = @loader.load_bundle(bundle_root: dir)
      result = @admission.evaluate(bundle_intake: bundle)
      assert_equal "manual_dogfooding", result["review_mode"]
      # manual dogfooding は標準集団に直接入れない（Phase 1 evidence）。
      assert_equal "admitted_exploratory", result["admission_status"]
      assert_includes result["admission_reason_codes"],
                      "manual_dogfooding_not_standard"
    end
  end

  # 撤廃済み review_mode 語彙（single_review 等）を一切使わない（finding 4）。
  def test_no_retired_review_mode_vocabulary
    src = File.read(ROOT + "scripts/evaluation/admission_evaluator.rb")
    %w[single_review dual_review dual_reviewer_workflow].each do |retired|
      refute_includes src, retired,
                       "撤廃 review_mode 語彙 #{retired} を使ってはならない"
    end
  end

  # --- ingestion / admission register（design Imported Evidence Intake） ------

  def test_ingestion_register_written_with_required_fields
    Dir.mktmpdir do |out|
      writer = DualReviewer::Evaluation::ImportRegisterWriter.new(repo_root: out)
      bundle = @loader.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
      path = writer.write_ingestion_entry(bundle_intake: bundle)
      entry = JSON.parse(File.read(path)).fetch("entries").last
      %w[bundle_id run_id source_repository_id source_revision review_mode
         ingested_at ingestion_status missing_fields].each do |k|
        assert entry.key?(k), "ingestion_register 必須項目欠落: #{k}"
      end
      assert_equal "bundle-standard-0001", entry["bundle_id"]
      assert_equal "runtime_mediated", entry["review_mode"]
    end
  end

  def test_admission_register_written_with_required_fields
    Dir.mktmpdir do |out|
      writer = DualReviewer::Evaluation::ImportRegisterWriter.new(repo_root: out)
      bundle = @loader.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
      result = @admission.evaluate(bundle_intake: bundle)
      path = writer.write_admission_entry(admission_result: result)
      entry = JSON.parse(File.read(path)).fetch("entries").last
      %w[bundle_id run_id admission_status admission_reason_codes
         eligible_for_standard_comparison
         eligible_for_exploratory_analysis].each do |k|
        assert entry.key?(k), "admission_register 必須項目欠落: #{k}"
      end
      assert_equal "admitted_standard", entry["admission_status"]
    end
  end

  # どの derived artifact が imported evidence をどの admission status で
  # 含むか保持する（Req10 受入 5）。register に bundle->status linkage が残る。
  def test_admission_register_preserves_bundle_to_status_linkage
    Dir.mktmpdir do |out|
      writer = DualReviewer::Evaluation::ImportRegisterWriter.new(repo_root: out)
      std = @loader.load_bundle(bundle_root: BUNDLES + "standard_runtime_bundle")
      miss = @loader.load_bundle(bundle_root: BUNDLES + "missing_provenance_bundle")
      writer.write_admission_entry(admission_result: @admission.evaluate(bundle_intake: std))
      path = writer.write_admission_entry(admission_result: @admission.evaluate(bundle_intake: miss))
      entries = JSON.parse(File.read(path)).fetch("entries")
      by_bundle = entries.each_with_object({}) { |e, h| h[e["bundle_id"]] = e }
      assert_equal "admitted_standard",
                   by_bundle["bundle-standard-0001"]["admission_status"]
      assert_equal "rejected",
                   by_bundle["bundle-missing-prov-0001"]["admission_status"]
    end
  end

  private

  # standard_runtime_bundle を雛形に exploratory 系 bundle を組み立てる。
  def build_exploratory_bundle(dir, with_invalidation: false,
                               review_mode: "runtime_mediated")
    root = Pathname(dir)
    src = BUNDLES + "standard_runtime_bundle"
    FileUtils.cp_r(src.to_s + "/.", root.to_s)
    manifest_path = root + "bundle_manifest.yaml"
    manifest = manifest_path.read
    manifest = manifest.sub(/review_mode: .*/, "review_mode: #{review_mode}")
    manifest = manifest.sub(/bundle_id: .*/, "bundle_id: bundle-exploratory-0001")
    manifest_path.write(manifest)
    if with_invalidation
      im = root + "run" + "run-eval-valid-0001" + "validation" +
           "invalidation_markers.json"
      im.write(JSON.pretty_generate(
                 "invalidation_markers" => [
                   {
                     "marker_id" => "im-imported-001",
                     "run_id" => "run-eval-valid-0001",
                     "reason_code" => "imported_provenance_drift",
                     "reason_detail" => "imported run flagged post hoc",
                     "issued_by" => "central-eval",
                     "scope" => "run"
                   }
                 ]
               ))
    end
  end
end
