#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"

# Task 2: local run intake model（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 2、Requirement 6 受入 1〜5、Requirement 1 受入 4、
#       design「Intake Model」「Classification Model §2 末尾／§3」、
#       runtime `runtime/schemas/review_case.schema.json`（foundation 準拠）、
#       runtime 所有 `comparison_eligibility_note.schema.json`（最小 6 項目）、
#       foundation `runtime/foundation/metadata_contract.yaml`。
#       適合レビュー 2026-05-19 finding 1（validation_refs）/ finding 10
#       （eligibility note consume）/ 中心問い 2（runtime_summary 非依存）。
#
# スクラッチ方針: 旧 v1 local_run_loader（validation_artifacts 旧命名・
# runtime_summary 経路前提）は流用せず破棄して作り直す。公開エントリ名
# DualReviewer::Evaluation::LocalRunLoader#load_run(run_root:) は維持し、
# 自己改善 signal_intake.rb の require_relative を無用に破壊しない。
module DualReviewer
  module Evaluation
    class LocalRunLoader
      # design「Intake Model」の最小 intake artifact。standard aggregate の
      # 一次入力は review_case.json + validation artifact。steps/*.json は
      # 必要時のみ。derived/runtime_summary.json は正本入力にしない。
      REQUIRED_ARTIFACTS = {
        "run_manifest" => "run_manifest.yaml",
        "review_case" => "review_case.json",
        "decision_units" => "decisions/decision_units.json",
        "validator_result" => "validation/validator_result.json",
        "invalidation_markers" => "validation/invalidation_markers.json",
        "comparison_eligibility_note" =>
          "derived/comparison_eligibility_note.json"
      }.freeze

      # v2-compatible optional intake（読めなくても standard analysis 成立）。
      # runtime_summary は含めない（convenience artifact・正本入力にしない）。
      OPTIONAL_ARTIFACTS = {
        "v2_review_artifact" => "v2/review_artifact.json",
        "v2_metric_snapshot" => "v2/metric_snapshot.json",
        "v2_trace_note" => "v2/trace_note.json"
      }.freeze

      # foundation metadata_contract.yaml が必須とする run-level metadata 群
      # （runtime/foundation/metadata_contract.yaml fields.required）。評価は
      # これを正本として読むだけで再定義しない。
      REQUIRED_METADATA_KEYS = %w[
        run_id target_id target_artifact_hash source_repository_id
        source_revision phase_profile treatment review_mode protocol_version
        runtime_version schema_set_version prompt_set_version config_version
        config_hash run_status validator_status human_signoff_status
        evidence_class started_at
      ].freeze

      # comparison_eligibility_note runtime 所有スキーマ最小 6 項目（評価 A-7）。
      ELIGIBILITY_MIN_FIELDS = %w[
        run_id eligible_for_standard_comparison ineligibility_reason_codes
        treatment phase_profile generated_at
      ].freeze

      PRIMARY_AGGREGATE_INPUT = "review_case.json+validation_artifacts"

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def load_run(run_root:)
        root = Pathname(run_root).expand_path
        artifacts = {}
        missing = []

        REQUIRED_ARTIFACTS.each do |name, rel|
          path = root + rel
          if path.file?
            artifacts[name] = load_artifact(path)
          else
            missing << rel
          end
        end
        OPTIONAL_ARTIFACTS.each do |name, rel|
          path = root + rel
          artifacts[name] = load_artifact(path) if path.file?
        end

        {
          "run_root" => root.to_s,
          "required_artifacts" => REQUIRED_ARTIFACTS,
          "optional_artifacts" => OPTIONAL_ARTIFACTS,
          "missing_artifacts" => missing,
          "intake_status" => missing.empty? ? "complete" : "incomplete",
          "primary_aggregate_input" => PRIMARY_AGGREGATE_INPUT,
          "artifacts" => artifacts,
          "validation_refs" => validation_refs(artifacts),
          "comparison_eligibility" => eligibility_view(artifacts),
          "metadata" => extract_metadata(artifacts)
        }
      end

      # Requirement 6 受入 1〜3・5: standard aggregation 前に必須 metadata /
      # 必須 intake 入力を check し、欠落時は fail fast + insufficiency
      # diagnostics を明示する。narrative から欠落 metadata を捏造しない
      # （observed のみ。inferred_value を作らない）。
      def standard_aggregation_readiness(run_intake:)
        diagnostics = []

        Array(run_intake["missing_artifacts"]).each do |rel|
          diagnostics << {
            "code" => "required_intake_input_missing",
            "observed" => rel
          }
        end

        md = run_intake.fetch("metadata", {})
        REQUIRED_METADATA_KEYS.each do |k|
          v = md[k]
          next unless v.nil? || v.to_s.strip.empty?

          diagnostics << {
            "code" => "required_metadata_missing",
            "observed" => k
          }
        end

        run_status = md["run_status"]
        if run_status != "closed"
          diagnostics << {
            "code" => "run_status_not_closed",
            "observed" => run_status
          }
        end

        vstatus = md["validator_status"]
        if vstatus == "blocked"
          diagnostics << {
            "code" => "validator_status_blocked",
            "observed" => vstatus
          }
        end

        {
          "ready_for_standard_aggregation" => diagnostics.empty?,
          "insufficiency_diagnostics" => diagnostics
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

      # runtime 新契約: review_case は foundation review_case.schema.json 準拠
      # で validation_refs（validator_result_ref / invalidation_marker_refs）を
      # 持つ。旧 v1 の validation_artifacts 命名には依存しない（finding 1）。
      def validation_refs(artifacts)
        rc = artifacts["review_case"]
        return {} unless rc.is_a?(Hash)

        refs = rc["validation_refs"]
        return {} unless refs.is_a?(Hash)

        {
          "validator_result_ref" => refs["validator_result_ref"],
          "invalidation_marker_refs" =>
            Array(refs["invalidation_marker_refs"])
        }
      end

      # comparison_eligibility_note を runtime 所有スキーマ最小 6 項目だけに
      # 依存して読む（再定義しない・finding 10 入口）。
      def eligibility_view(artifacts)
        note = artifacts["comparison_eligibility_note"]
        return nil unless note.is_a?(Hash)

        ELIGIBILITY_MIN_FIELDS.each_with_object({}) do |k, h|
          h[k] = note[k]
        end
      end

      # metadata の正本は review_case.metadata（foundation 準拠投影）。
      # 無ければ run_manifest.metadata を補助に見る（どちらも nest 構造）。
      def extract_metadata(artifacts)
        rc_md = dig_metadata(artifacts["review_case"])
        rm_md = dig_metadata(artifacts["run_manifest"])
        REQUIRED_METADATA_KEYS.each_with_object({}) do |k, h|
          h[k] = rc_md.fetch(k, nil) || rm_md.fetch(k, nil)
        end
      end

      def dig_metadata(artifact)
        return {} unless artifact.is_a?(Hash)

        md = artifact["metadata"]
        md.is_a?(Hash) ? md : {}
      end
    end
  end
end
