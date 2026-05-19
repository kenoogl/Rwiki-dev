#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "analysis_intake"
require_relative "reference"

# Task 6: caveat and limitation model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 6、Requirement 3（受入 1〜5）、
#       design「Caveat and Limitation Model」。
#       適合レビュー 2026-05-19 Finding 1（旧 caveat_register entries[] /
#       caveat_code/affected_scope/details 旧 v1 形依存）解消。
#
# スクラッチ方針: 旧 v1 paper_caveat_register_builder.rb
# （evaluation_caveats.fetch("entries") の旧 v1 形依存）は流用せず破棄
# して作り直す。新 evaluation caveat 実体（caveats[] / caveat_class 軸）
# を構造化参照で継承し paper-facing 説明単位へ再配置する。
# limitation_type は Requirement 3 受入 2 の 3 分類を正準値とする。
# caveated evidence を silent に strong evidence へ格上げしない
# （limitation_type を必ず保持する）。
module DualReviewer
  module PaperInterfaceV2
    class PaperCaveatRegisterBuilder
      Ref = DualReviewer::PaperInterfaceV2::Reference

      LIMITATION_TYPES = %w[
        invalid_data_exclusion partial_evidence methodological_limitation
      ].freeze

      # 上流 evaluation caveat_code → 正準 limitation_type の対応。
      # 未知 code は保守的に methodological_limitation（silent な格上げを
      # 避ける＝Requirement 3 受入 5）。
      CODE_TO_LIMITATION = {
        "invalid_data_exclusion" => "invalid_data_exclusion",
        "population_collapsed" => "invalid_data_exclusion",
        "low_sample_size" => "partial_evidence",
        "partial_evidence" => "partial_evidence",
        "mixed_maturity_evidence" => "methodological_limitation",
        "mixed_review_mode_evidence" => "methodological_limitation"
      }.freeze

      def initialize(analysis_root:)
        @intake = AnalysisIntake.new(analysis_root: analysis_root)
      end

      # extra_caveats: evidence_register 側で機械検知した混在 review-mode
      # caveat 等（limitation_type_hint を持つ）を追加取込する。
      def build(extra_caveats: [])
        cr = @intake.caveat_register
        entries = Array(cr["caveats"]).map do |c|
          paper_entry(c)
        end

        Array(extra_caveats).each do |x|
          entries << extra_entry(x)
        end

        { "caveats" => entries }
      end

      private

      def paper_entry(c)
        code = c["caveat_code"].to_s
        {
          "caveat_id" => "paper-caveat-#{code}",
          "source_caveat_ref" => Ref.build(
            ref_type: "evaluation_caveat",
            target_path:
              @intake.relative_target_path(:caveat_register),
            target_id: code
          ),
          # claim/artifact への適用は claim_map 側 caveat_refs が正本。
          # ここでは上流 caveat の affected_scope を構造化参照化する。
          "applies_to_claim_refs" => [],
          "applies_to_artifact_refs" =>
            applies_to_artifact_refs(c),
          "limitation_type" => limitation_type_for(code),
          "narrative_note" => narrative_note(c)
        }
      end

      def extra_entry(x)
        code = x["caveat_code"].to_s
        hint = x["limitation_type_hint"].to_s
        lt =
          if hint == "mixed_review_mode"
            "methodological_limitation"
          else
            limitation_type_for(code)
          end
        {
          "caveat_id" => "paper-caveat-#{code}",
          "source_caveat_ref" => Ref.build(
            ref_type: "paper_derived_caveat",
            target_path:
              @intake.relative_target_path(:caveat_register),
            target_id: code
          ),
          "applies_to_claim_refs" => [],
          "applies_to_artifact_refs" => [],
          "limitation_type" => lt,
          "narrative_note" => x["details"].to_s
        }
      end

      def limitation_type_for(code)
        CODE_TO_LIMITATION.fetch(code, "methodological_limitation")
      end

      def applies_to_artifact_refs(c)
        scope = c["affected_scope"].to_s
        return [] if scope.empty? || scope == "global"

        # treatment_comparison / phase_comparison 等の上流 scope を
        # 対応 analysis artifact への構造化参照にする。
        key =
          case scope
          when "treatment_comparison" then :treatment_comparisons
          when "phase_comparison" then :phase_comparisons
          end
        return [] if key.nil?

        [Ref.build(
          ref_type: "evaluation_#{key}",
          target_path: @intake.relative_target_path(key)
        )]
      end

      def narrative_note(c)
        detail = c["details"].to_s
        cls = c["caveat_class"].to_s
        sev = c["severity"].to_s
        "[#{cls}/#{sev}] #{detail}".strip
      end
    end
  end
end
