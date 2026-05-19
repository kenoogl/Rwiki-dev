#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "reference"

# Task 8: separation rules（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 8、Requirement 4（受入 1〜5）、Requirement 2 受入 6、
#       design「Separation Rules §1〜§4」。
#       適合レビュー 2026-05-19 Finding 6（stale 再生成全面欠落・新
#       evaluation StalenessPropagator と非接続）解消。
#
# スクラッチ方針: 旧 v1 に separation rule / stale 受信は不在。本モジュール
# はスクラッチ新設。No Reverse Control / No Silent Strengthening /
# Self-Improvement Independence / Stale Upstream Regeneration を強制。
# stale 標識付与は新 evaluation StalenessPropagator#evaluate の出力契約
# （stale / stale_run_ids / propagation_source / stale_marker_refs /
# affected_derived_artifacts）を入力起点とする。再生成の自動起動主体・
# タイミングは実装委譲（本モジュールは信号表現契約と検出のみ）。
module DualReviewer
  module PaperInterfaceV2
    class SeparationRules
      Ref = DualReviewer::PaperInterfaceV2::Reference

      TRANSFORMATION_VERSION = "paper-narrative-transformation-0.1.0"

      # design §1 No Reverse Control。
      def reverse_control_invariants
        {
          "requests_runtime_field_additions" => false,
          "upgrades_invalid_to_valid" => false,
          "overrides_evaluation_comparison_rule" => false,
          "overrides_invalidation_policy" => false,
          "paper_convenience_subordinate" => true
        }
      end

      # design §1 / Requirement 4 受入 1: invalid run を valid evidence に
      # 格上げしない。invalid evidence_class は paper-facing 対象外。
      def allow_evidence?(evidence_class:, requested_maturity:)
        return false if evidence_class.to_s == "invalid"

        %w[mature preliminary exploratory]
          .include?(requested_maturity.to_s)
      end

      # design §2 No Silent Strengthening: preliminary/exploratory を
      # mature と同列にしない。出典 maturity より強い提示を不許可。
      def silent_strengthening_allowed?(source_maturity:, presented_as:)
        order = { "exploratory" => 0, "preliminary" => 1, "mature" => 2 }
        s = order.fetch(source_maturity.to_s, 0)
        p = order.fetch(presented_as.to_s, 0)
        p <= s
      end

      # design §3 Self-Improvement Independence。
      def classify_self_improvement_reference(adopted_change_ref:)
        {
          "input_ref" => adopted_change_ref,
          "allowed_role" => "methodology_note",
          "usable_as_primary_performance_claim" => false,
          "usable_as_claim_support_artifact" => false
        }
      end

      # design §4 / Requirement 2 受入 6: 新 evaluation StalenessPropagator
      # の伝播出力を入力起点に paper-facing artifact へ
      # stale/stale_reason/stale_source_ref を付与する（破壊的更新でなく
      # 複製を返す）。stale=false 伝播では付与しない。
      def apply_staleness(artifacts:, propagation:)
        prop = propagation || {}
        stale = prop["stale"] == true

        Array(artifacts).map do |a|
          e = deep_dup(a)
          if stale
            e["stale"] = true
            e["stale_reason"] =
              "upstream evaluation marked stale " \
              "(disposition=#{prop['disposition']}, runs=" \
              "#{Array(prop['stale_run_ids']).join(',')})"
            e["stale_source_ref"] = stale_source_ref(prop)
          else
            e["stale"] = false
            e["stale_reason"] = nil
            e["stale_source_ref"] = nil
          end
          e
        end
      end

      # design §4: stale=true の paper-facing artifact が再生成対象。
      def regeneration_required?(artifacts)
        Array(artifacts).any? { |a| a["stale"] == true }
      end

      # Requirement 4 受入 5: downstream narrative transformation を
      # explicit かつ versionable にする。
      def narrative_transformation_descriptor
        {
          "explicit" => true,
          "transformation_version" => TRANSFORMATION_VERSION,
          "description" =>
            "Evaluation analysis artifacts are transformed into " \
            "paper-facing fragments without altering upstream " \
            "runtime/evaluation semantics."
        }
      end

      # raw evidence・core evaluation output 不変（design Separation
      # Rules / tasks §5.2）。巻き戻しは paper-facing 再生成に閉じる。
      def rollback_scope
        {
          "scope" => "paper_facing_artifact_regeneration",
          "edits_raw_evidence" => false,
          "edits_core_evaluation_output" => false
        }
      end

      private

      def stale_source_ref(prop)
        # propagation_source（foundation_invalidation_propagation 等）と
        # stale_run_ids/stale_marker_refs を構造化参照に束ねる。
        first_run = Array(prop["stale_run_ids"]).first
        Ref.build(
          ref_type: "evaluation_staleness_propagation",
          target_path: "experiments/analysis/manifests/" \
                        "analysis_run_manifest.yaml",
          target_id: [prop["propagation_source"], first_run]
                     .compact.join(":")
        )
      end

      def deep_dup(obj)
        Marshal.load(Marshal.dump(obj))
      end
    end
  end
end
