# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"
require "digest"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 9: portable evidence bundle export
# 根拠: tasks.md Task 9、Requirement 9 受入 1〜5、
#       design「Portable Evidence Bundle Export」「Export Boundary」
#       「Bundle Shape」「Runtime Artifact Layout」、
#       基盤 metadata_contract.yaml（provenance_roles / review_mode enum）。
# 外部依存なし（gem 不使用）・repo 内で完結。実 experiments/runs は汚さず
# tmpdir に擬似 run directory を組んで export を検証する。
class TestBundleExport < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/contracts/bundle_exporter"
    @exporter = DualReviewer::Runtime::ExecutionV2::BundleExporter
    @dir = Pathname(Dir.mktmpdir)
    @run_id = "run-20260519T000000Z-abcd1234"
    @run_root = @dir + "experiments/runs/#{@run_id}"
    @exports_base = @dir + "exports"
    build_fake_run(run_status: "closed")
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && @dir.exist?
  end

  # ---- 擬似 run directory ----
  # design「Runtime Artifact Layout」相当の最小構造を tmpdir に組む。
  def build_fake_run(run_status:, with_provenance: true)
    FileUtils.rm_rf(@run_root)
    %w[steps decisions validation derived].each do |sub|
      FileUtils.mkdir_p(@run_root + sub)
    end
    manifest = {
      "run_id" => @run_id,
      "target_id" => "spec/dual-reviewer-runtime/tasks.md",
      "run_status" => run_status,
      "validator_status" => "passed",
      "human_signoff_status" => "approved",
      "evidence_class" => "candidate"
    }
    if with_provenance
      manifest["source_repository_id"] = "Rwiki-v2-code-mod"
      manifest["source_revision"] = "rev-deadbeef"
      manifest["review_mode"] = "runtime_mediated"
    end
    (@run_root + "run_manifest.yaml").write(YAML.dump(manifest))
    (@run_root + "review_case.json").write(JSON.pretty_generate("run_id" => @run_id))
    (@run_root + "steps/step_a_primary_detection.json")
      .write(JSON.pretty_generate("step" => "a"))
    (@run_root + "validation/validator_result.json")
      .write(JSON.pretty_generate("validator_status" => "passed"))
  end

  def do_export(**overrides)
    args = {
      run_root: @run_root,
      exports_base: @exports_base,
      export_runtime_version: "0.1.0",
      now: Time.utc(2026, 5, 19, 1, 2, 3)
    }.merge(overrides)
    @exporter.export(**args)
  end

  # 受入 1: raw run directory を書き換えず bundle copy を作る。
  def test_raw_run_directory_unchanged_and_bundle_copy_created
    raw_before = snapshot(@run_root)
    result = do_export
    raw_after = snapshot(@run_root)
    assert_equal raw_before, raw_after, "raw run directory が export で変化した"

    bundle_root = Pathname(result.fetch("bundle_root"))
    copied = bundle_root + "run" + @run_id + "run_manifest.yaml"
    assert copied.file?, "bundle に run copy が無い"
    assert_equal (@run_root + "run_manifest.yaml").read, copied.read,
                 "copy が raw と byte 一致しない（意味を書き換えた）"
    assert_equal (@run_root + "steps/step_a_primary_detection.json").read,
                 (bundle_root + "run" + @run_id +
                  "steps/step_a_primary_detection.json").read
  end

  # 受入 2・3 / Bundle Shape: exports/<bundle_id>/{bundle_manifest.yaml,
  # run/<run_id>/...,checksums/bundle_checksums.json} を作り、
  # bundle_manifest.yaml は規定 8 フィールドを持つ。
  def test_bundle_shape_and_manifest_eight_fields
    result = do_export
    bundle_root = Pathname(result.fetch("bundle_root"))
    bundle_id = result.fetch("bundle_id")

    assert_equal @exports_base + bundle_id, bundle_root
    assert (bundle_root + "bundle_manifest.yaml").file?
    assert (bundle_root + "run" + @run_id).directory?
    assert (bundle_root + "checksums/bundle_checksums.json").file?

    manifest = YAML.safe_load((bundle_root + "bundle_manifest.yaml").read)
    expected_keys = %w[
      bundle_id run_id source_repository_id source_revision review_mode
      exported_at export_runtime_version included_artifact_refs
    ]
    assert_equal expected_keys.sort, manifest.keys.sort,
                 "bundle_manifest は規定 8 フィールド厳密"
    assert_equal bundle_id, manifest.fetch("bundle_id")
    assert_equal @run_id, manifest.fetch("run_id")
    assert_equal "Rwiki-v2-code-mod", manifest.fetch("source_repository_id")
    assert_equal "rev-deadbeef", manifest.fetch("source_revision")
    assert_equal "runtime_mediated", manifest.fetch("review_mode")
    assert_equal "2026-05-19T01:02:03Z", manifest.fetch("exported_at")
    assert_equal "0.1.0", manifest.fetch("export_runtime_version")
    refs = manifest.fetch("included_artifact_refs")
    assert_includes refs, "run/#{@run_id}/run_manifest.yaml"
    assert_includes refs, "run/#{@run_id}/steps/step_a_primary_detection.json"
    assert_equal refs, refs.sort, "included_artifact_refs は決定的に sort"
  end

  # checksums/bundle_checksums.json が copy 済 run file の sha256 を持つ。
  def test_checksums_generated_over_copied_run_files
    result = do_export
    bundle_root = Pathname(result.fetch("bundle_root"))
    payload = JSON.parse((bundle_root + "checksums/bundle_checksums.json").read)
    entries = payload.fetch("checksums")
    rel = "run/#{@run_id}/run_manifest.yaml"
    entry = entries.find { |e| e.fetch("path") == rel }
    refute_nil entry, "checksums に #{rel} が無い"
    expected = Digest::SHA256.file(bundle_root + rel).hexdigest
    assert_equal expected, entry.fetch("sha256")
    # checksums 自身は対象に含めない（自己参照しない）
    refute(entries.any? { |e| e.fetch("path").end_with?("bundle_checksums.json") })
  end

  # してはいけないこと: missing provenance を暗黙補完しない。
  # manifest に provenance が無く explicit 入力も無ければ fail（既定値を作らない）。
  def test_missing_provenance_not_silently_filled
    build_fake_run(run_status: "closed", with_provenance: false)
    err = assert_raises(ArgumentError) { do_export }
    assert_match(/provenance/i, err.message)
    refute @exports_base.exist?, "失敗時に bundle を作ってはならない"
  end

  # explicit 入力は manifest provenance と矛盾してはならない（意味の書換禁止）。
  def test_explicit_provenance_conflict_is_rejected
    err = assert_raises(ArgumentError) do
      do_export(source_revision: "rev-OTHER")
    end
    assert_match(/conflict|矛盾/i, err.message)
  end

  # explicit 入力が manifest と一致するか、manifest 欠落時の明示供給は許容。
  def test_explicit_provenance_consistent_is_accepted
    result = do_export(source_repository_id: "Rwiki-v2-code-mod")
    manifest = YAML.safe_load(
      (Pathname(result.fetch("bundle_root")) + "bundle_manifest.yaml").read
    )
    assert_equal "Rwiki-v2-code-mod", manifest.fetch("source_repository_id")
  end

  # 受入 4 / Export Boundary: export は close/validation 後の別工程。
  # closed でない run は export しない（admission を済ませたことにもしない）。
  def test_export_refuses_run_not_closed
    build_fake_run(run_status: "in_progress")
    err = assert_raises(RuntimeError) { do_export }
    assert_match(/close|closed/i, err.message)
    refute @exports_base.exist?
  end

  # 受入 4: bundle は central-side admission/ingestion 判定と区別される。
  # manifest は provenance envelope であり admission verdict を持たない。
  def test_bundle_distinct_from_admission_decision
    result = do_export
    bundle_root = Pathname(result.fetch("bundle_root"))
    manifest = YAML.safe_load((bundle_root + "bundle_manifest.yaml").read)
    %w[admission_status admitted ingested ingestion_decision
       admission_decision central_accepted].each do |forbidden|
      refute manifest.key?(forbidden),
             "bundle_manifest が admission 判定 #{forbidden} を内包してはならない"
    end
    # API も admission を済ませた旨を返さない
    refute result.key?("admission_status")
    refute result.key?("admitted")
  end

  # 受入 5: bundle の意味再構成に repo 外 hidden memory を要さない。
  # bundle 内に provenance + run copy + checksums が自己完結している。
  def test_bundle_self_contained_no_external_memory
    result = do_export
    bundle_root = Pathname(result.fetch("bundle_root"))
    manifest = YAML.safe_load((bundle_root + "bundle_manifest.yaml").read)
    # provenance は bundle 内 manifest だけで読める
    %w[source_repository_id source_revision review_mode run_id].each do |k|
      refute_nil manifest.fetch(k)
    end
    # included_artifact_refs が指す path はすべて bundle 内に実在
    manifest.fetch("included_artifact_refs").each do |rel|
      assert (bundle_root + rel).file?, "ref が bundle 内に無い: #{rel}"
    end
  end

  # 正本不変: runtime 正本は experiments/runs/<run_id>/ のまま。
  # export は別 artifact（exports/ 配下）で、raw を移動/置換しない。
  def test_canonical_run_remains_in_experiments_runs
    do_export
    assert @run_root.directory?, "raw run が消えた（置換された）"
    assert (@run_root + "run_manifest.yaml").file?
    assert_match(%r{experiments/runs/#{Regexp.escape(@run_id)}\z},
                 @run_root.to_s)
  end

  private

  # ディレクトリ配下の相対 path → 内容 のスナップショット（raw 不変検証用）。
  def snapshot(root)
    root = Pathname(root)
    Dir[root.join("**/*").to_s].select { |p| File.file?(p) }.sort.to_h do |p|
      [Pathname(p).relative_path_from(root).to_s, File.read(p)]
    end
  end
end
