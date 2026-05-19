#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "analysis_intake"
require_relative "reference"

# Task 3: claim mapping model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 3、Requirement 1（受入 1〜6）、Requirement 4 受入 1、
#       design「Claim Mapping Model §1〜§2」。
#       適合レビュー 2026-05-19 Finding 1/2/8（新 evaluation 実体スキーマ
#       不一致）・Finding 3（構造化参照未実装）・Finding 10（claim
#       taxonomy 3 固定ハードコード）解消。
#
# スクラッチ方針: 旧 v1 claim_map_builder.rb（build_phase_claim/
# build_treatment_claim/build_exclusion_claim の 3 固定 entry・裸パス
# 文字列・"#{REF}##{code}" 文字列結合・旧 evaluation スキーマ依存）は
# 流用せず破棄して作り直す。claim は claim_descriptor 駆動の一般 mapping
# 単位として再構成し（Finding 10）、新 evaluation 実体スキーマをそのキー
# 名で読む。supporting source は experiments/analysis/ 相対の標準 source
# に限定し runtime raw を一次入力にしない。
module DualReviewer
  module PaperInterfaceV2
    class ClaimMapBuilder
      Ref = DualReviewer::PaperInterfaceV2::Reference

      # claim を一般 mapping 単位として宣言的に列挙する claim descriptor。
      # claim_id は安定識別子、source_keys は標準 source 種別（intake が
      # experiments/analysis/ 相対 path へ解決）、text_proc は実体スキーマ
      # から claim_text を導く（埋め込み分岐をデータ化）。
      CLAIM_DESCRIPTORS = [
        {
          claim_id: "claim-treatment-comparison-summary",
          source_keys: %i[treatment_comparisons],
          text_proc: lambda do |intake|
            tc = intake.treatment_comparisons
            present = Array(tc["treatments_present"]).join(", ")
            "Treatment comparison (status=#{tc['comparison_status']}) " \
              "over treatments present: #{present}."
          end
        },
        {
          claim_id: "claim-phase-comparison-summary",
          source_keys: %i[phase_comparisons],
          text_proc: lambda do |intake|
            pc = intake.phase_comparisons
            profiles = Array(pc["phase_slices"])
                       .map { |s| s["phase_profile"] }.compact.join(", ")
            "Phase comparison (status=#{pc['comparison_status']}) " \
              "over phase profiles: #{profiles}."
          end
        },
        {
          claim_id: "claim-population-exclusion-summary",
          source_keys: %i[exclusion_report],
          text_proc: lambda do |intake|
            er = intake.exclusion_report
            "Analysis population excludes #{er['total_excluded']} run(s); " \
              "valid population is kept separate from excluded population."
          end
        }
      ].freeze

      def initialize(analysis_root:)
        @intake = AnalysisIntake.new(analysis_root: analysis_root)
      end

      def build
        # evaluation output 不在で生ログにフォールバックせず評価プロセス
        # 実行を要求する（Requirement 1 受入 4）。intake が raise する。
        ensure_evaluation_outputs!

        claims = CLAIM_DESCRIPTORS.map { |d| build_claim(d) }
        { "claims" => claims }
      end

      private

      def ensure_evaluation_outputs!
        # 標準 source の存在を intake 経由で確認（不在は intake が
        # 評価プロセス実行要求の RuntimeError を raise）。
        @intake.treatment_comparisons
        @intake.phase_comparisons
        @intake.exclusion_report
        @intake.caveat_register
        @intake.manifest
      end

      def build_claim(descriptor)
        supporting = descriptor[:source_keys].map do |k|
          Ref.build(
            ref_type: "evaluation_#{k}",
            target_path: @intake.relative_target_path(k)
          )
        end

        {
          "claim_id" => descriptor[:claim_id],
          "claim_text" => descriptor[:text_proc].call(@intake),
          "supporting_artifact_refs" => supporting,
          "maturity_label" => claim_maturity,
          "caveat_refs" => claim_caveat_refs,
          "provenance_refs" => provenance_refs
        }
      end

      # Requirement 1 受入 3 / design §1: direct と caveated/preliminary を
      # 区別する。claim の maturity は valid population が安定比較集合
      # （標準 runtime comparison set）か否かに束縛する（evidence_class
      # 束縛規則と整合）。valid run が安定比較集合にあれば mature、
      # exploratory のみなら exploratory、それ以外は preliminary。
      def claim_maturity
        index = @intake.run_classification_index
        rows = Array(index["entries"])
        valid_stable = rows.any? do |r|
          r["classification"] == "valid" &&
            r["in_standard_runtime_comparison_set"] == true
        end
        return "mature" if valid_stable

        any_valid = rows.any? { |r| r["classification"] == "valid" }
        any_valid ? "preliminary" : "exploratory"
      end

      # design §1: artifact-specific caveat の canonical source は
      # claim entry の caveat_refs。上流 evaluation caveat_register を
      # 構造化参照で指す（basename 部分一致を正本判定にしない）。
      def claim_caveat_refs
        cr = @intake.caveat_register
        Array(cr["caveats"]).map do |c|
          Ref.build(
            ref_type: "evaluation_caveat",
            target_path: @intake.relative_target_path(:caveat_register),
            target_id: c["caveat_code"]
          )
        end
      end

      # Requirement 1 受入 5: versioned evidence へ辿れる provenance。
      # analysis_run_manifest（analysis_logic_version / input_run_set 保持）
      # を構造化参照で持たせる。
      def provenance_refs
        [
          Ref.build(
            ref_type: "analysis_run_manifest",
            target_path: @intake.relative_target_path(:manifest)
          ),
          Ref.build(
            ref_type: "analysis_run_manifest_input_run_set",
            target_path: @intake.relative_target_path(:manifest),
            target_id: "input_run_set"
          )
        ]
      end
    end
  end
end
