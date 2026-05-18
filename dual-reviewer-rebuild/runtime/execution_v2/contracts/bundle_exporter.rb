# frozen_string_literal: true

# Task 9: portable evidence bundle export
# 根拠: tasks.md Task 9、Requirement 9 受入 1〜5、
#       design「Portable Evidence Bundle Export」「Export Boundary」
#       「Bundle Shape」「Runtime Artifact Layout」「v2 Compatibility Rule」、
#       基盤 metadata_contract.yaml（provenance_roles / review_mode enum）。
#
# 配置: design「File Placement for v2 Runtime Core」。export は close 後の
# adapter 的別工程であり、analyzer / writer / manifest と混在させない独立
# モジュールとして runtime/execution_v2/contracts/ に置く（layer 間 object
# shape を扱う層）。session_controller / evidence_writer には依存しない
# （raw run directory path のみを入力に取る close 後の独立工程）。
#
# 旧 v1（scripts/export_evidence_bundle.rb・runtime/export/bundle_exporter.rb）
# はスクラッチ方針により本実装で置換する（旧ロジックは流用しない）。
require "json"
require "yaml"
require "time"
require "digest"
require "fileutils"
require "pathname"

module DualReviewer
  module Runtime
    module ExecutionV2
      # portable evidence bundle exporter。
      #
      # 不変条件（design「Export Boundary」）:
      # - raw run directory の意味を書き換えない（read-only copy のみ）
      # - missing provenance を暗黙補完しない（既定値を作らない＝fail）
      # - central-side admission を済ませたことにしない（admission verdict を
      #   bundle / 返り値に持たせない）
      # - export は close / validation 後の別工程（run_status=closed 必須）
      # - runtime 正本は experiments/runs/<run_id>/ のまま（move/置換しない）
      module BundleExporter
        # bundle_manifest.yaml が持つフィールド（design「Bundle Shape」、厳密 8）。
        MANIFEST_FIELDS = %w[
          bundle_id
          run_id
          source_repository_id
          source_revision
          review_mode
          exported_at
          export_runtime_version
          included_artifact_refs
        ].freeze

        # raw run manifest から読む provenance 群（基盤 provenance_roles）。
        PROVENANCE_KEYS = %w[
          source_repository_id source_revision review_mode
        ].freeze

        module_function

        # 1 run を portable bundle として export する。
        #
        # run_root:                experiments/runs/<run_id>/ への path
        # exports_base:            exports/ への path（正本を置換しない別 artifact）
        # export_runtime_version:  この exporter の版（manifest に記録）
        # source_repository_id/source_revision/review_mode:
        #   明示供給する provenance（省略時は raw run_manifest.yaml から読む。
        #   両方欠落なら fail＝暗黙補完しない。明示値が manifest と矛盾しても
        #   fail＝raw の意味を書き換えない）
        # bundle_id:               省略時 "bundle-<run_id>"
        # now:                     exported_at に使う時刻（test 決定性のため注入可）
        def export(run_root:, exports_base:, export_runtime_version:,
                   source_repository_id: nil, source_revision: nil,
                   review_mode: nil, bundle_id: nil, now: nil)
          run_root = Pathname(run_root)
          exports_base = Pathname(exports_base)
          raise ArgumentError, "run_root does not exist: #{run_root}" unless run_root.directory?

          manifest = load_run_manifest(run_root)
          run_id = manifest.fetch("run_id") do
            raise ArgumentError, "run_manifest.yaml missing run_id"
          end

          # Export Boundary: export は close / validation 後の別工程。
          enforce_post_close_boundary(manifest)

          provenance = resolve_provenance(
            manifest,
            source_repository_id: source_repository_id,
            source_revision: source_revision,
            review_mode: review_mode
          )

          bundle_id ||= "bundle-#{run_id}"
          exported_at = (now || Time.now.utc).utc.iso8601

          bundle_root = exports_base + bundle_id
          run_copy_root = bundle_root + "run" + run_id

          # raw を read-only で copy（意味を書き換えない）。失敗時に半端な
          # bundle を残さないため、確定後にだけ書き出す。
          FileUtils.mkdir_p(run_copy_root.parent)
          FileUtils.cp_r("#{run_root}/.", run_copy_root.to_s)

          included_refs = collect_relative_files(run_copy_root)
            .map { |rel| "run/#{run_id}/#{rel}" }
            .sort

          bundle_manifest = {
            "bundle_id" => bundle_id,
            "run_id" => run_id,
            "source_repository_id" => provenance.fetch("source_repository_id"),
            "source_revision" => provenance.fetch("source_revision"),
            "review_mode" => provenance.fetch("review_mode"),
            "exported_at" => exported_at,
            "export_runtime_version" => export_runtime_version,
            "included_artifact_refs" => included_refs
          }
          assert_manifest_shape(bundle_manifest)
          (bundle_root + "bundle_manifest.yaml").write(YAML.dump(bundle_manifest))

          checksums = build_checksums(bundle_root)
          checksums_dir = bundle_root + "checksums"
          FileUtils.mkdir_p(checksums_dir)
          (checksums_dir + "bundle_checksums.json")
            .write(JSON.pretty_generate(checksums))

          # central-side admission を済ませたことにしない＝admission verdict を
          # 返さない。これは provenance envelope の生成完了のみを表す。
          {
            "bundle_id" => bundle_id,
            "run_id" => run_id,
            "bundle_root" => bundle_root.to_s,
            "bundle_manifest_path" => (bundle_root + "bundle_manifest.yaml").to_s,
            "checksums_path" => (checksums_dir + "bundle_checksums.json").to_s,
            "included_artifact_refs" => included_refs
          }
        end

        def load_run_manifest(run_root)
          path = Pathname(run_root) + "run_manifest.yaml"
          unless path.file?
            raise ArgumentError, "run_manifest.yaml not found under #{run_root}"
          end
          parsed = YAML.safe_load(path.read)
          unless parsed.is_a?(Hash)
            raise ArgumentError, "run_manifest.yaml is not a mapping"
          end
          parsed
        end

        # Export Boundary（design）: export は close / validation 後の別工程で
        # あり run 実行に含めない。closed でない run は export しない。
        def enforce_post_close_boundary(manifest)
          status = manifest["run_status"]
          return if status == "closed"

          raise "export refused: run_status=#{status.inspect} is not closed; " \
                "export is a separate post-close/validation step (Export Boundary)"
        end

        # provenance 解決。
        # - 明示供給があれば優先候補とする
        # - raw run_manifest にあれば突き合わせる
        # - 明示と raw が矛盾したら fail（raw の意味を書き換えない）
        # - どちらにも無ければ fail（missing provenance を暗黙補完しない）
        def resolve_provenance(manifest, source_repository_id:,
                               source_revision:, review_mode:)
          explicit = {
            "source_repository_id" => source_repository_id,
            "source_revision" => source_revision,
            "review_mode" => review_mode
          }
          resolved = {}
          missing = []
          PROVENANCE_KEYS.each do |key|
            given = blank?(explicit[key]) ? nil : explicit[key]
            from_manifest = blank?(manifest[key]) ? nil : manifest[key]

            if given && from_manifest && given != from_manifest
              raise ArgumentError,
                    "provenance conflict for #{key}: explicit=#{given.inspect} " \
                    "but run_manifest=#{from_manifest.inspect} " \
                    "(raw run の意味を書き換えない／矛盾は補完しない)"
            end

            value = given || from_manifest
            if value.nil?
              missing << key
            else
              resolved[key] = value
            end
          end

          unless missing.empty?
            raise ArgumentError,
                  "missing required provenance: #{missing.join(', ')}; " \
                  "exporter は missing provenance を暗黙補完しない（受入 2）"
          end
          resolved
        end

        def assert_manifest_shape(bundle_manifest)
          actual = bundle_manifest.keys.sort
          return if actual == MANIFEST_FIELDS.sort

          raise "bundle_manifest field set mismatch: " \
                "expected #{MANIFEST_FIELDS.sort.inspect}, got #{actual.inspect}"
        end

        def collect_relative_files(root)
          root = Pathname(root)
          Dir[root.join("**/*").to_s]
            .select { |p| File.file?(p) }
            .map { |p| Pathname(p).relative_path_from(root).to_s }
            .sort
        end

        # bundle 内の全 file の sha256（checksums file 自身は対象外）。
        def build_checksums(bundle_root)
          bundle_root = Pathname(bundle_root)
          files = Dir[bundle_root.join("**/*").to_s]
            .select { |p| File.file?(p) }
            .reject { |p| p.end_with?("bundle_checksums.json") }
            .sort
          {
            "bundle_id" => bundle_root.basename.to_s,
            "checksums" => files.map do |p|
              {
                "path" => Pathname(p).relative_path_from(bundle_root).to_s,
                "sha256" => Digest::SHA256.file(p).hexdigest
              }
            end
          }
        end

        def blank?(value)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end
    end
  end
end
