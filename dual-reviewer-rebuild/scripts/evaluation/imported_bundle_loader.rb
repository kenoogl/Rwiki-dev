#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"
require_relative "local_run_loader"

# Task 2: portable bundle intake model（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 2、Requirement 10 受入 1〜3、design「Portable Bundle
#       Intake」「Intake Model」、runtime 所有 BundleExporter が出す bundle
#       shape（bundle_manifest.yaml + run/<run_id>/ 配下の exported run
#       artifact）。適合レビュー 2026-05-19 finding 1/10。
#
# スクラッチ方針: 旧 v1 imported_bundle_loader（旧 local_run_loader 経路前提・
# checksum/provenance 7 項目語彙）は流用せず破棄して作り直す。required
# provenance（source_repository_id / source_revision）欠落時は intake を
# 継続しても standard admission を与えない（最終 admission 判定の単一所有は
# Task 7。本 loader は intake と provenance 充足の観測までを担う）。
module DualReviewer
  module Evaluation
    class ImportedBundleLoader
      # design「Portable Bundle Intake」最小入力（exported run artifact）。
      EXPORTED_RUN_ARTIFACTS = {
        "run_manifest" => "run_manifest.yaml",
        "review_case" => "review_case.json",
        "decision_units" => "decisions/decision_units.json",
        "validator_result" => "validation/validator_result.json",
        "invalidation_markers" => "validation/invalidation_markers.json",
        "comparison_eligibility_note" =>
          "derived/comparison_eligibility_note.json"
      }.freeze

      # Requirement 10 受入 2: standard admission には required provenance
      # 完備が前提。欠落時は intake 継続しても standard admission を得ない。
      REQUIRED_PROVENANCE = %w[source_repository_id source_revision].freeze

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def load_bundle(bundle_root:)
        root = Pathname(bundle_root).expand_path
        manifest_path = root + "bundle_manifest.yaml"
        unless manifest_path.file?
          return {
            "bundle_root" => root.to_s,
            "intake_status" => "incomplete",
            "missing_artifacts" => ["bundle_manifest.yaml"],
            "bundle_manifest" => {},
            "run_artifacts" => {},
            "missing_provenance" => REQUIRED_PROVENANCE.dup,
            "eligible_for_standard_admission" => false
          }
        end

        manifest = YAML.safe_load(manifest_path.read) || {}
        run_id = manifest["run_id"]
        run_dir = run_id ? (root + "run" + run_id) : nil

        run_artifacts = {}
        missing = []
        EXPORTED_RUN_ARTIFACTS.each do |name, rel|
          path = run_dir && (run_dir + rel)
          if path&.file?
            run_artifacts[name] = load_artifact(path)
          else
            missing << "run/#{run_id}/#{rel}"
          end
        end

        missing_provenance = REQUIRED_PROVENANCE.reject do |k|
          v = manifest[k]
          v && !v.to_s.strip.empty?
        end

        {
          "bundle_root" => root.to_s,
          "bundle_manifest" => manifest,
          "run_id" => run_id,
          "run_artifacts" => run_artifacts,
          "missing_artifacts" => missing,
          "intake_status" => missing.empty? ? "complete" : "incomplete",
          "missing_provenance" => missing_provenance,
          # required provenance 完備 かつ run artifact 充足のときのみ
          # standard admission の前提を満たす（最終判定は Task 7 が所有）。
          "eligible_for_standard_admission" =>
            missing.empty? && missing_provenance.empty?
        }
      end

      private

      def load_artifact(path)
        case path.extname
        when ".yaml", ".yml" then YAML.safe_load(path.read)
        when ".json" then JSON.parse(path.read)
        else raise ArgumentError, "unsupported artifact format: #{path}"
        end
      end
    end
  end
end
