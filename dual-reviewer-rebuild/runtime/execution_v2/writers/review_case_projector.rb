# frozen_string_literal: true

# Task 6: review_artifact.json → review_case.json 投影規約（runtime 所有）
# 根拠: tasks.md Task 6、Requirement 4 受入 1・2・3・6、design「Evidence Writing
#       Model」「`review_case.json`」、設計横断整合ゲート 2026-05-18 実行側 A-5。
#
# A-5 決定（runtime 所有・本クラスが正本）:
#   - `review_case.json` を唯一の横断正本とする（スキーマは foundation 所有＝
#     runtime/schemas/review_case.schema.json に常時準拠）。
#   - `review_artifact.json` は runtime 内部限定の taxonomy-first 表現にとどめ、
#     横断正本にはしない。
#   - runtime が review_artifact → review_case のフィールド対応（投影規約）を
#     所有・定義し、review_case が常に foundation スキーマ準拠であることを保証。
#
# 投影規約（フィールド対応。新たな推論をしない機械写像）:
#   review_case.review_case_id   <- "review-case-#{run_id}"
#   review_case.metadata         <- run-level metadata（foundation metadata
#                                   contract の必須 field 集合をそのまま継承。
#                                   runtime 側で語彙再定義・別トークン化しない）
#   review_case.step_records[*]  <- 各 step raw record を replay identity 6 項目
#                                   （step_id / step_name / step_status /
#                                   step_prompt_artifact_id / step_started_at /
#                                   step_closed_at）へ写像
#   review_case.findings[*]      <- Step A/B/C raw finding を foundation finding
#                                   schema 11 必須項目へ写像。source attribution
#                                   （source_role）・judgment linkage（judgment_ref）・
#                                   counter-evidence / override（counter_evidence_refs
#                                   / adversarial_outcome）を該当時に付与。
#                                   decision unit linkage（decision_unit_id /
#                                   human_decision_ref）を decision_units から付与。
#   review_case.validation_refs  <- validator_result / invalidation marker 参照
#
# 配置: design File Placement「runtime/execution_v2/writers/」（compatibility /
# v2 internal artifact write 層）。manifest / analyzer / decision を混ぜない。
module DualReviewer
  module Runtime
    module ExecutionV2
      class ReviewCaseProjector
        # foundation finding schema が許す adversarial_outcome enum（再定義しない）。
        ADVERSARIAL_OUTCOMES = %w[
          counter_evidence_raised
          no_counter_evidence_after_challenge
          not_assessed
        ].freeze

        # finding 何にも紐づかないときの adversarial_outcome 既定（foundation enum 内）。
        DEFAULT_ADVERSARIAL_OUTCOME = "not_assessed"

        # human_decision_ref が指す run レベル正本（design Human Sign-off Record）。
        HUMAN_SIGNOFF_REF = "decisions/human_signoff.json"

        # foundation 横断正本へ写像する。常に foundation review_case schema の
        # required（top-level / metadata 19 / step_records items 6 / finding 11）を
        # 満たす envelope を返す。review_artifact は taxonomy-first 補助入力。
        def project(run_id:, metadata:, step_records:, decision_units:,
                    review_artifact: nil, validator_result_ref: nil,
                    invalidation_marker_refs: [])
          {
            "schema_version" => "1.0.0",
            "review_case_id" => "review-case-#{run_id}",
            "metadata" => project_metadata(metadata),
            "step_records" => step_records.map { |sr| project_step_record(sr) },
            "findings" => project_findings(
              step_records: step_records,
              decision_units: decision_units || [],
              review_artifact: review_artifact
            ),
            "validation_refs" => {
              "validator_result_ref" => validator_result_ref,
              "invalidation_marker_refs" => Array(invalidation_marker_refs)
            }
          }
        end

        private

        # metadata は foundation metadata contract の必須 field 集合をそのまま
        # 継承する（runtime 側で再定義・丸め・別トークン化しない＝finding 6 整合）。
        def project_metadata(metadata)
          # 破壊的変更を避けるため複製して返す。
          JSON.parse(JSON.generate(metadata))
        end

        # foundation review_case step_records items の必須 6 項目へ写像。
        def project_step_record(raw)
          step_id = raw.fetch("step_id")
          {
            "step_id" => step_id,
            "step_name" => raw.fetch("step_name"),
            "step_status" => raw["execution_state"] || "executed",
            "step_prompt_artifact_id" => prompt_artifact_id(raw),
            "step_started_at" => raw["step_started_at"] || raw["started_at"],
            "step_closed_at" => raw["step_closed_at"] || raw["closed_at"] || nil
          }
        end

        # Step D は LLM 非依存のため prompt identity を持たない。machine 統合を
        # 表す安定識別子を入れ、required（string）を満たす。
        def prompt_artifact_id(raw)
          pi = raw["prompt_identity"]
          return pi.fetch("prompt_id") if pi.is_a?(Hash) && pi["prompt_id"]

          raw["step_id"] == "step_d" ? "mechanical_integration" : "unresolved"
        end

        # Step A/B/C raw finding を foundation finding schema 11 必須項目へ写像。
        def project_findings(step_records:, decision_units:, review_artifact:)
          by_id = step_records.each_with_object({}) do |sr, h|
            h[sr.fetch("step_id")] = sr
          end

          assessments = index_by_finding(by_id["step_b"], "assessments")
          judgments = index_by_finding(by_id["step_c"], "judgments")
          du_link = decision_unit_linkage(decision_units)

          raw_findings = Array(by_id["step_a"] && by_id["step_a"]["findings"])
          raw_findings.map do |f|
            fid = f.fetch("finding_id")
            assessment = assessments[fid] || {}
            judgment = judgments[fid]
            link = du_link[fid] || {}

            {
              "finding_id" => fid,
              "step_id" => f["step_id"] || "step_a",
              "source_role" => f["source_role"] || "primary_reviewer",
              "severity" => f["severity"] || "unspecified",
              "summary" => f["summary"] || "",
              "source_refs" => Array(f["source_refs"]),
              # counter-evidence を該当時に出す（受入 3）。
              "counter_evidence_refs" => Array(assessment["counter_evidence"]),
              # judgment linkage（受入 2）。
              "judgment_ref" => judgment ? "step_c##{fid}" : nil,
              # decision unit linkage（finding schema）。
              "decision_unit_id" => link["decision_unit_id"],
              "human_decision_ref" => link["human_decision_ref"],
              "adversarial_outcome" =>
                normalize_outcome(assessment["adversarial_outcome"])
            }.merge(override_fields(judgment))
          end
        end

        # override 関連 field を該当時のみ出す（受入 3。無いときは付けない）。
        def override_fields(judgment)
          return {} if judgment.nil?

          fields = {}
          fields["final_label"] = judgment["final_label"] if judgment["final_label"]
          if judgment["recommended_action"]
            fields["recommended_action"] = judgment["recommended_action"]
          end
          if judgment["override_reason"]
            fields["override_reason"] = judgment["override_reason"]
          end
          fields
        end

        def index_by_finding(step_record, key)
          return {} if step_record.nil?

          Array(step_record[key]).each_with_object({}) do |entry, h|
            h[entry["finding_id"]] = entry if entry["finding_id"]
          end
        end

        def decision_unit_linkage(decision_units)
          map = {}
          decision_units.each do |u|
            duid = u["decision_unit_id"]
            Array(u["finding_refs"]).each do |fid|
              map[fid] = {
                "decision_unit_id" => duid,
                "human_decision_ref" => HUMAN_SIGNOFF_REF
              }
            end
          end
          map
        end

        def normalize_outcome(value)
          ADVERSARIAL_OUTCOMES.include?(value) ? value : DEFAULT_ADVERSARIAL_OUTCOME
        end
      end
    end
  end
end
