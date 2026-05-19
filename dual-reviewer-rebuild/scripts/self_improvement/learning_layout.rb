#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "fileutils"

# Task 1: learning/ skeleton と schema versioning（自己改善所有・スクラッチ）
#
# 根拠: tasks.md Task 1、design「Learning Artifact Layout」「Placement
#       Rationale」「Schema Versioning」、Requirement 2 受入 5・Requirement 5
#       受入 5、foundation 要件 3 受入 3 versioning 規約。
#       適合レビュー 2026-05-19 finding 3（決定的検証不在）の品質保証対象。
#
# スクラッチ方針: 旧 v1 self_improvement（2026-05-13 付・現行承認仕様再承認
# および evaluation/runtime スクラッチ再実装より前）は流用せず破棄して作り
# 直す。本モジュールは self-improvement が所有する learning derived artifact
# の正本配置を機械列挙・冪等生成し、全 artifact に schema_version を持たせ、
# version 差があっても読めることを保証する。foundation 規約には接続宣言の
# みで foundation 側は修正しない（スキーマ所有は self-improvement 側）。
module DualReviewer
  module SelfImprovement
    module LearningLayout
      # learning/ 配下 artifact の現行 schema version。非互換変更時はこの値を
      # 上げ、旧 version artifact は read_versioned で旧 version のまま解釈
      # 可能に保つ（破壊的一括書換をしない・design Schema Versioning）。
      SCHEMA_VERSION = "1.0.0"

      # 既知の解釈可能 version 集合（旧 version も読めることを保証する）。
      KNOWN_SCHEMA_VERSIONS = %w[0.9.0 1.0.0].freeze

      # design「Learning Artifact Layout」ツリーを正本とする。
      # key = learning_root 相対パス、value = Placement Rationale の役割説明。
      ARTIFACT_CATALOG = {
        "findings/recurring_failure_signals.json" =>
          "改善前 signal inventory（runtime/evaluation 由来 recurring signal）",
        "findings/workflow_failure_signals.json" =>
          "workflow failure signal の inventory",
        "findings/pattern_candidates.json" =>
          "project-specific / meta-pattern candidate の整理",
        "proposals/proposal_index.json" =>
          "proposal 正本の索引（<proposal_id>.yaml は別 artifact）",
        "backtests/backtest_index.json" =>
          "検証 artifact の索引（<proposal_id>.json は別 artifact）",
        "templates/workflow_remediation_templates.json" =>
          "recurring workflow failure mode への remediation template",
        "approved-updates/adoption_register.json" =>
          "採用履歴（proposal と repo change/version update の連結）",
        "rejected-updates/rejection_register.json" =>
          "却下履歴（invisible discard でなく preserved outcome）",
        "rollback/rollback_register.json" =>
          "rollback 履歴（supersession と区別・学習入力に再接続）"
      }.freeze

      # <proposal_id> ごとの可変 artifact（catalog の固定 index/register と別）。
      VARIABLE_ARTIFACT_DIRS = {
        "proposal" => "proposals/",
        "backtest" => "backtests/"
      }.freeze

      module_function

      def canonical_artifact_paths
        ARTIFACT_CATALOG.keys
      end

      def subdirectories
        (ARTIFACT_CATALOG.keys.map { |rel| rel.split("/").first } +
         VARIABLE_ARTIFACT_DIRS.values.map { |d| d.delete_suffix("/") })
          .uniq
      end

      def proposal_artifact_path(proposal_id:)
        "proposals/#{proposal_id}.yaml"
      end

      def backtest_artifact_path(proposal_id:)
        "backtests/#{proposal_id}.json"
      end

      # proposal / backtest / adoption / rollback artifact の所在を説明できる
      # （design Completion Criteria 第 2 項）。
      def artifact_locations
        {
          "proposal" => VARIABLE_ARTIFACT_DIRS.fetch("proposal"),
          "backtest" => VARIABLE_ARTIFACT_DIRS.fetch("backtest"),
          "proposal_index" => "proposals/proposal_index.json",
          "backtest_index" => "backtests/backtest_index.json",
          "adoption" => "approved-updates/adoption_register.json",
          "rejection" => "rejected-updates/rejection_register.json",
          "rollback" => "rollback/rollback_register.json",
          "findings" => "findings/",
          "templates" => "templates/"
        }
      end

      # learning_root 配下に正本 skeleton を冪等生成する。
      # 既存 artifact は破壊しない（再生成可能）。全 index/register に
      # schema_version を持たせる。書き出しは mkpath 保証で ENOENT を出さない
      # （評価で起きた writer 系不具合を再発させない）。
      def create_skeleton(learning_root:)
        root = Pathname(learning_root)
        subdirectories.each do |sub|
          dir = root + sub
          dir.mkpath
        end
        ARTIFACT_CATALOG.each_key do |rel|
          path = root + rel
          next if path.file?

          path.dirname.mkpath
          path.write(JSON.pretty_generate(empty_artifact))
        end
        root
      end

      # mkpath 保証付き artifact 書き出し（schema_version 自動付与）。
      def write_artifact(learning_root:, relative_path:, payload:)
        path = Pathname(learning_root) + relative_path
        path.dirname.mkpath
        body = { "schema_version" => SCHEMA_VERSION }.merge(payload)
        path.write(JSON.pretty_generate(body))
        path
      end

      # 長期保存 artifact を version 差があっても読む。schema_version 欠落は
      # silent に既定値で読まず diagnostic にする（versioning 規約: silent な
      # 非互換編集の禁止）。既知 version は readable、未知 version は
      # incompatible として明示する（旧 version は解釈可能に保つ）。
      def read_versioned(path:)
        payload = JSON.parse(Pathname(path).read)
        sv = payload["schema_version"]
        if sv.nil? || sv.to_s.strip.empty?
          return {
            "readable" => false,
            "diagnostic" => "schema_version_missing",
            "payload" => payload
          }
        end

        known = KNOWN_SCHEMA_VERSIONS.include?(sv)
        {
          "schema_version" => sv,
          "readable" => known,
          "incompatible" => !known,
          "diagnostic" => known ? nil : "schema_version_unknown",
          "payload" => payload
        }
      end

      def empty_artifact
        { "schema_version" => SCHEMA_VERSION, "entries" => [] }
      end
    end
  end
end
