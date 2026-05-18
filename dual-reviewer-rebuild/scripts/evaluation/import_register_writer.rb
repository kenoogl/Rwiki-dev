#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "time"
require "fileutils"

# Task 7: imported evidence intake artifacts writer（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 7、Requirement 10 受入 5、design「Imported Evidence
#       Intake Artifacts」（Ingestion Register / Admission Register）。
#
# スクラッチ方針: 旧 v1 import_register_writer（ingestion_status / provenance_
# missing_fields など旧 loader 戻り値前提）は流用せず破棄して作り直す。
# 第1波で確定した ImportedBundleLoader#load_bundle の戻り値形に追随する。
# raw run storage（experiments/runs/）は一切触らない（Decision 1）。
module DualReviewer
  module Evaluation
    class ImportRegisterWriter
      INGESTION_REGISTER_REL =
        "experiments/analysis/imports/ingestion_register.json"
      ADMISSION_REGISTER_REL =
        "experiments/analysis/imports/admission_register.json"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      # design「Ingestion Register」必須 8 項目を記録する。
      def write_ingestion_entry(bundle_intake:)
        manifest = bundle_intake.fetch("bundle_manifest", {}) || {}
        entry = {
          "bundle_id" => manifest["bundle_id"],
          "run_id" => manifest["run_id"] ||
            bundle_intake["run_id"],
          "source_repository_id" => manifest["source_repository_id"],
          "source_revision" => manifest["source_revision"],
          "review_mode" => manifest["review_mode"],
          "ingested_at" => Time.now.utc.iso8601,
          "ingestion_status" => bundle_intake.fetch("intake_status"),
          "missing_fields" => combined_missing_fields(bundle_intake)
        }
        write_register(
          register_path: repo_root + INGESTION_REGISTER_REL,
          entry: entry,
          dedup_key: "bundle_id"
        )
      end

      # design「Admission Register」必須 6 項目を記録する。判定は
      # AdmissionEvaluator が単一所有（本 writer は記録のみ・再判定しない）。
      def write_admission_entry(admission_result:)
        entry = {
          "bundle_id" => admission_result["bundle_id"],
          "run_id" => admission_result["run_id"],
          "admission_status" => admission_result.fetch("admission_status"),
          "admission_reason_codes" =>
            admission_result.fetch("admission_reason_codes"),
          "eligible_for_standard_comparison" =>
            admission_result.fetch("eligible_for_standard_comparison"),
          "eligible_for_exploratory_analysis" =>
            admission_result.fetch("eligible_for_exploratory_analysis")
        }
        write_register(
          register_path: repo_root + ADMISSION_REGISTER_REL,
          entry: entry,
          dedup_key: "bundle_id"
        )
      end

      private

      def combined_missing_fields(bundle_intake)
        [
          *Array(bundle_intake["missing_artifacts"]),
          *Array(bundle_intake["missing_provenance"])
        ].uniq
      end

      def write_register(register_path:, entry:, dedup_key:)
        register_path.dirname.mkpath
        payload =
          if register_path.exist?
            JSON.parse(register_path.read)
          else
            { "entries" => [] }
          end
        if entry[dedup_key]
          payload["entries"].reject! do |e|
            e[dedup_key] == entry[dedup_key]
          end
        end
        payload["entries"] << entry
        register_path.write(JSON.pretty_generate(payload))
        register_path
      end
    end
  end
end
