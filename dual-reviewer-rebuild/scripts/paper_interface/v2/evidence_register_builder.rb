#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "analysis_intake"
require_relative "reference"

# Task 4: evidence register model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 4、Requirement 5（受入 1〜6）、Requirement 6
#       （受入 1〜5）、Requirement 1 受入 2、
#       design「Evidence Register Model §1〜§3」。
#       適合レビュー 2026-05-19 Finding 3（10 フィールド欠落・evidence_class
#       束縛未実装・構造化参照未実装・stale 標識皆無）・Finding 4
#       （review-mode 混在検知/置換系譜全面欠落）解消。
#
# スクラッチ方針: 旧 v1 evidence_register_builder.rb（独自
# runtime_validation_summary_refs・comparison_status==valid?mature:
# preliminary の独自規則・evidence_class/review_mode/supersedes 不在）は
# 流用せず破棄して作り直す。maturity_label は foundation evidence_class
# （valid/invalid/exploratory）に束縛された派生分類とし独立語彙にしない
# （Requirement 5 受入 6）。review_mode は foundation 由来で保持し再定義
# しない。
module DualReviewer
  module PaperInterfaceV2
    class EvidenceRegisterBuilder
      Ref = DualReviewer::PaperInterfaceV2::Reference

      REVIEW_MODE_VOCAB = %w[manual_dogfooding runtime_mediated].freeze

      def initialize(analysis_root:)
        @intake = AnalysisIntake.new(analysis_root: analysis_root)
      end

      # evidence_register.json を組み立てる。run_classification_index を
      # run 単位 evidence の正本入力とし、invalid run は paper-facing
      # 対象外として除外する（design §1 束縛規則）。
      def build
        index = @intake.run_classification_index
        manifest_ref = manifest_ref()
        run_set_ref = input_run_set_ref()

        entries = Array(index["entries"]).map do |row|
          ec = evidence_class_of(row)
          next nil if ec == "invalid" # paper-facing 対象外

          {
            "artifact_ref" => artifact_ref(row),
            "source_analysis_manifest_ref" => manifest_ref,
            "input_run_set_ref" => run_set_ref,
            "evidence_class" => ec,
            "review_mode" => review_mode_of(row),
            "maturity_label" => maturity_label(ec, row),
            "caveat_refs" => caveat_refs_for(row),
            "supersedes" => [],
            "superseded_by" => [],
            "generated_at" => generated_at(),
            # design §4: 既定 stale=false。上流陳腐化伝播で付与される。
            "stale" => false,
            "stale_reason" => nil,
            "stale_source_ref" => nil
          }
        end.compact

        { "entries" => entries }
      end

      # design「Review-Mode in Reporting」受入 4: report set 参照の
      # evidence_register entry の review_mode が 2 値以上で混在。
      def mixed_review_modes?(entries)
        modes = Array(entries).map { |e| e["review_mode"] }.compact.uniq
        modes.size >= 2
      end

      # 混在検知 caveat（自動付与の素材）。Task 6 paper caveat register が
      # limitation_type を最終確定する（hint を渡す）。
      def mixed_review_mode_caveat(entries)
        modes = Array(entries).map { |e| e["review_mode"] }.compact.uniq
        {
          "caveat_code" => "mixed_review_mode_evidence",
          "limitation_type_hint" => "mixed_review_mode",
          "review_modes" => modes,
          "details" =>
            "Report set mixes review modes (#{modes.sort.join(', ')}); " \
            "manual dogfooding evidence must not be presented as " \
            "runtime-produced evidence without explicit labeling."
        }
      end

      # Requirement 5 受入 5 / Requirement 6 受入 5 / design §2・§3:
      # 早期手動証拠→後 runtime 証拠の置換系譜を supersedes /
      # superseded_by で双方向に保存する（破壊的更新でなく複製を返す）。
      def link_supersession(superseded:, superseding:)
        sd = deep_dup(superseded)
        sg = deep_dup(superseding)

        sd["superseded_by"] = Array(sd["superseded_by"]) +
                              [ref_to(sg)]
        sg["supersedes"] = Array(sg["supersedes"]) + [ref_to(sd)]
        { superseded: sd, superseding: sg }
      end

      private

      def ref_to(entry)
        a = entry["artifact_ref"]
        Ref.build(
          ref_type: a["ref_type"],
          target_path: a["target_path"],
          target_id: a["target_id"]
        )
      end

      def artifact_ref(row)
        Ref.build(
          ref_type: "evaluation_run_classification",
          target_path:
            @intake.relative_target_path(:run_classification_index),
          target_id: row["run_id"]
        )
      end

      def manifest_ref
        Ref.build(
          ref_type: "analysis_run_manifest",
          target_path: @intake.relative_target_path(:manifest)
        )
      end

      def input_run_set_ref
        Ref.build(
          ref_type: "analysis_run_manifest_input_run_set",
          target_path: @intake.relative_target_path(:manifest),
          target_id: "input_run_set"
        )
      end

      # foundation evidence_class（valid/invalid/exploratory）。
      # run_classification_index の classification を foundation 語彙へ
      # 対応付ける（analysis_blocked は paper-facing 対象外＝invalid 同様）。
      # foundation 由来語彙を再定義しない（対応のみ）。
      def evidence_class_of(row)
        case row["classification"].to_s
        when "valid" then "valid"
        when "exploratory" then "exploratory"
        else "invalid" # invalid / analysis_blocked: paper-facing 対象外
        end
      end

      def review_mode_of(row)
        rm = row["review_mode"].to_s
        REVIEW_MODE_VOCAB.include?(rm) ? rm : "runtime_mediated"
      end

      # design §1 束縛規則: invalid は対象外（呼出前に除外済み）、
      # exploratory→exploratory、valid は安定比較集合なら mature 否なら
      # preliminary。in_standard_runtime_comparison_set を安定比較集合の
      # 正本指標とする（評価が確定済み＝正）。
      def maturity_label(evidence_class, row)
        return "exploratory" if evidence_class == "exploratory"

        if row["in_standard_runtime_comparison_set"] == true
          "mature"
        else
          "preliminary"
        end
      end

      # design §1: caveated は maturity でなく caveat_refs で表現。
      # 本 builder は run 単位の caveat 紐付けを行わない（paper caveat
      # register が claim/artifact 単位で再配置する）。空で初期化し、
      # Task 6 が applies_to で結ぶ。
      def caveat_refs_for(_row)
        []
      end

      def generated_at
        @intake.manifest["generated_at"].to_s
      end

      def deep_dup(obj)
        Marshal.load(Marshal.dump(obj))
      end
    end
  end
end
