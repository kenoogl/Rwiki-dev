#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "fileutils"
require "time"
require "yaml"
require "digest"

# Task 8: versioning（analysis artifact を versioned output とする。
# 評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 8、Requirement 5 受入 5・2、design「Versioning Model」。
#       manifests/analysis_run_manifest.yaml に 6 version フィールドを記録し、
#       derived output から run identifier / target identifier への linkage を
#       保持する。同一 raw run set でも analysis logic が変われば別 output 扱い。
#
# スクラッチ方針: 旧 v1 analysis_manifest_writer（既存 derived JSON を読んで
# input_run_set を逆算・mkpath なし・run/target linkage なし・staleness
# 非接続）は流用せず破棄して作り直す。入力は評価が確定した input_run_records
# （run_id / target_id / classification）を一次入力にし、derived 逆読みに
# 依存しない（derivation path の正本性を保つ）。
module DualReviewer
  module Evaluation
    class AnalysisManifestWriter
      ANALYSIS_LOGIC_VERSION = "0.1.0"
      METRIC_SET_VERSION = "0.1.0"
      PHASE_METRIC_PROFILE_VERSION = "overlay-v1"
      COMPARISON_CONTRACT_VERSION = "0.1.0"

      REL_PATH = "manifests/analysis_run_manifest.yaml"

      # design Versioning Model が要求する 6 version フィールド
      # ＋ run/target linkage（Requirement 5 受入 2）。
      def build_manifest(input_run_records:,
                         analysis_logic_version: ANALYSIS_LOGIC_VERSION,
                         metric_set_version: METRIC_SET_VERSION,
                         phase_metric_profile_version:
                           PHASE_METRIC_PROFILE_VERSION,
                         comparison_contract_version:
                           COMPARISON_CONTRACT_VERSION,
                         generated_at: nil)
        records = Array(input_run_records)
        run_set = records.map { |r| r["run_id"] }.compact.uniq.sort

        {
          "analysis_logic_version" => analysis_logic_version,
          "input_run_set" => run_set,
          "generated_at" => generated_at || Time.now.utc.iso8601,
          "metric_set_version" => metric_set_version,
          "phase_metric_profile_version" => phase_metric_profile_version,
          "comparison_contract_version" => comparison_contract_version,
          # derived output から run/target identifier への linkage を保持
          # （Requirement 5 受入 2）。
          "run_target_linkage" => records.map do |r|
            {
              "run_id" => r["run_id"],
              "target_id" => r["target_id"],
              "classification" =>
                (r["classification"] || {})["classification"]
            }
          end
        }
      end

      # 同一 raw run set でも analysis logic が変われば別 output 扱い
      # （design Versioning Model）。version 群 ＋ input_run_set から
      # 決定的な output identity を導く。
      def output_identity(manifest:)
        material = [
          manifest["analysis_logic_version"],
          manifest["metric_set_version"],
          manifest["phase_metric_profile_version"],
          manifest["comparison_contract_version"],
          Array(manifest["input_run_set"]).sort.join(",")
        ].join("|")
        Digest::SHA256.hexdigest(material)
      end

      # 適合レビュー 2026-05-19 の writer 系不具合（出力先未作成での ENOENT）を
      # 再発させないため書き出し前に mkpath を保証する。
      def write_manifest(manifest:, analysis_root:)
        path = Pathname(analysis_root).expand_path + REL_PATH
        path.dirname.mkpath
        path.write(YAML.dump(manifest))
        path.to_s
      end
    end
  end
end
