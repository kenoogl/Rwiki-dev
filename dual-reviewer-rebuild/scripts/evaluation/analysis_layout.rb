#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "fileutils"

# Task 1: experiments/analysis/ directory skeleton（評価所有モジュール）
# 根拠: tasks.md Task 1、Requirement 5 受入 1・3、design「Analysis Artifact
#       Layout」「Placement Rationale」「Key Decisions / Decision 1」。
#       適合レビュー 2026-05-19 finding 9（skeleton 現存性・可説明性）。
#
# スクラッチ方針: 旧 v1 評価実装は流用せず作り直す。本モジュールは evaluation
# が所有する derived analysis artifact の正本配置を機械的に列挙・生成し、raw run
# evidence（experiments/runs/<run_id>/、runtime 所有）との境界を明示する。
# evaluation は raw run artifact を一切 mutate しない（Decision 1）。
module DualReviewer
  module Evaluation
    module AnalysisLayout
      # design「Analysis Artifact Layout」のツリーを正本とする。
      # key = analysis_root 相対パス、value = Placement Rationale の役割説明。
      ARTIFACT_CATALOG = {
        "imports/ingestion_register.json" =>
          "imported bundle の intake 履歴（どの bundle をいつ取り込んだか）",
        "imports/admission_register.json" =>
          "imported bundle の admission 判定結果（standard/exploratory/rejected）",
        "manifests/analysis_run_manifest.yaml" =>
          "どの evaluation logic version で analysis を作ったかと input_run_set の記録",
        "classifications/run_classification_index.json" =>
          "valid/invalid/exploratory/analysis_blocked の判定結果索引",
        "classifications/exclusion_report.json" =>
          "どの run がなぜ標準集団から除外されたかの counts と reasons",
        "metrics/run_metrics.json" =>
          "run-level metric 出力（findings 数・validation outcome 等）",
        "metrics/finding_metrics.json" =>
          "finding-level metric 出力（severity/source-role/judgment 分布）",
        "metrics/treatment_metrics.json" =>
          "treatment-level metric 出力（findings per run・acceptance ratio 等）",
        "comparisons/treatment_comparisons.json" =>
          "treatment（single/dual/dual+judgment）ごとの比較 aggregate",
        "comparisons/phase_comparisons.json" =>
          "phase（intent/requirements/design/tasks）ごとの比較 aggregate",
        "caveats/caveat_register.json" =>
          "paper-interface / self-improvement が継承する machine-readable caveat"
      }.freeze

      module_function

      def artifact_catalog
        ARTIFACT_CATALOG
      end

      # 正本サブディレクトリ集合（design Placement Rationale）。
      def subdirectories
        ARTIFACT_CATALOG.keys.map { |rel| rel.split("/").first }.uniq
      end

      # analysis_root 配下に正本 skeleton を冪等に生成する。
      # 既存 derived artifact は破壊しない（再生成可能・finding 9）。
      # raw run storage（experiments/runs/）は一切作らない／触らない
      # （Decision 1：evaluation は run artifact を mutate しない）。
      # 返り値: 生成（既存含む）サブディレクトリの絶対パス配列。
      def create_skeleton(analysis_root:)
        root = Pathname(analysis_root)
        subdirectories.map do |sub|
          dir = root + sub
          dir.mkpath
          gitkeep = dir + ".gitkeep"
          gitkeep.write("") unless gitkeep.exist?
          dir.to_s
        end
      end

      # raw run と analysis artifact の境界を説明できる（design Completion
      # Criteria 第 1 項・Decision 1）。
      def raw_derived_boundary
        {
          "raw_evidence_root" => "experiments/runs/<run_id>/",
          "derived_artifact_root" => "experiments/analysis/",
          "evaluation_mutates_raw" => false,
          "rationale" =>
            "raw run evidence は immutable で runtime 所有。evaluation は " \
            "それを読み取り、derived artifact を experiments/analysis/ に " \
            "分離出力する。raw run artifact を編集・移動・上書きしない " \
            "（design Key Decision 1）。"
        }
      end
    end
  end
end
