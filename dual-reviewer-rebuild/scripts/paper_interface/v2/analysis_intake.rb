#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"

# 論文インターフェース共通: evaluation 分析出力の intake（スクラッチ）。
# 根拠: tasks.md Task 3、Requirement 1 受入 4、design「Claim Mapping
#       Model §2 Supporting Artifact Sources」「Interfaces / Evaluation」。
#       適合レビュー 2026-05-19 Finding 1/2/8（新 evaluation 実体スキーマ
#       不一致）解消の基盤。
#
# スクラッチ方針: 旧 v1 evaluation_intake_loader.rb（caveat_register に
# fetch("entries") を期待する旧 v1 形依存）は流用せず破棄して作り直す。
# 新 evaluation 実体スキーマ（caveats / caveats_by_class、
# treatments_present / treatment_aggregates、phase_slices /
# selected_overlay、exclusion entries=除外のみ + total_excluded +
# population_separation）をそのキー名で読む。
#
# evaluation output が存在しない場合は生ログにフォールバックせず評価
# プロセス実行を要求する（Requirement 1 受入 4、design Design Drivers）。
module DualReviewer
  module PaperInterfaceV2
    class AnalysisIntake
      # design §2: experiments/analysis/ 相対の標準 source。
      STANDARD_SOURCES = {
        treatment_comparisons:
          "comparisons/treatment_comparisons.json",
        phase_comparisons:
          "comparisons/phase_comparisons.json",
        exclusion_report:
          "classifications/exclusion_report.json",
        run_classification_index:
          "classifications/run_classification_index.json",
        caveat_register:
          "caveats/caveat_register.json",
        manifest:
          "manifests/analysis_run_manifest.yaml"
      }.freeze

      # analysis_root: 評価分析出力 root（experiments/analysis/ 相当の
      # 実ディレクトリ。fixture も同形）。
      def initialize(analysis_root:)
        @root = Pathname(analysis_root)
      end

      def treatment_comparisons
        load_json(:treatment_comparisons)
      end

      def phase_comparisons
        load_json(:phase_comparisons)
      end

      def exclusion_report
        load_json(:exclusion_report)
      end

      def run_classification_index
        load_json(:run_classification_index)
      end

      def caveat_register
        load_json(:caveat_register)
      end

      def manifest
        path = @root + STANDARD_SOURCES[:manifest]
        require_evaluation_output!(path)
        YAML.safe_load(path.read)
      end

      # design §2 / Requirement 1 受入 4: relative path（基準起点）のみで
      # 所在特定できる標準 source の repo 相対表現。Reference の
      # target_path に使う（experiments/analysis/ prefix を付与）。
      def relative_target_path(key)
        "experiments/analysis/#{STANDARD_SOURCES.fetch(key)}"
      end

      private

      def load_json(key)
        path = @root + STANDARD_SOURCES.fetch(key)
        require_evaluation_output!(path)
        JSON.parse(path.read)
      end

      # evaluation output 不在で生ログにフォールバックせず評価プロセス
      # 実行を要求する（Requirement 1 受入 4）。raw log / experiments/runs
      # への言及をエラーに含めない（生ログ直読を示唆しない）。
      def require_evaluation_output!(path)
        return if path.file?

        raise "evaluation output missing at #{path}; " \
              "the evaluation process must be run to produce " \
              "analysis artifacts (no fallback)."
      end
    end
  end
end
