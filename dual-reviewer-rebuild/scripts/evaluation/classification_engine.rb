#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../runtime/execution_v2/contracts/treatment_matrix"

# Task 3: classification model（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 3、Requirement 1 受入 1〜6、Requirement 9 受入 1〜6、
#       Requirement 10 受入 4・5、Requirement 2 受入 3、design「Classification
#       Model §1〜§4」「Admission States」。runtime 所有 TreatmentMatrix
#       （Treatment×Step 実行印の正本。評価は参照のみ・再定義しない）。
#       適合レビュー 2026-05-19 finding 4/5/7/8。
#
# スクラッチ方針: 旧 v1 classification_engine（review_mode 直交未所有・
# 設計スキップ弁別なし・analysis_blocked 一律化）は流用せず破棄して
# 作り直す。後続波 self-improvement signal_intake.rb が参照する公開
# エントリ classify_local_run(run_intake:) / classify_imported_bundle と
# result の {run_id,classification,reason_codes,reason_details,
# phase_profile,treatment} 形は維持する（無用な破壊をしない）。
#
# 設計原則:
# - 有効性分類（valid/invalid/exploratory/analysis_blocked）と review-mode
#   （manual_dogfooding/runtime_mediated）は直交独立軸（design §2 末尾）。
# - imported bundle の admission state は Task 7（AdmissionEvaluator）が
#   単一所有。本 Task は admission_status を前段入力として参照のみし
#   再判定しない（Req10 受入 4・5）。
module DualReviewer
  module Evaluation
    class ClassificationEngine
      TERMINAL_HUMAN_SIGNOFF = %w[approved rejected deferred].freeze
      # foundation canonical review_mode のみ（finding 4: 撤廃語彙非依存）。
      STANDARD_REVIEW_MODE = "runtime_mediated"
      MANUAL_DOGFOODING_REVIEW_MODE = "manual_dogfooding"

      TM = DualReviewer::Runtime::TreatmentMatrix

      # local run の分類（design §1〜§4）。
      def classify_local_run(run_intake:)
        metadata = run_intake.fetch("metadata", {}) || {}
        missing = Array(run_intake["missing_artifacts"])
        artifacts = run_intake.fetch("artifacts", {}) || {}

        invalidation = invalidation_markers(artifacts)
        base = base_classification(
          metadata: metadata,
          missing_artifacts: missing,
          invalidation_markers: invalidation
        )

        decorate(
          base: base,
          metadata: metadata,
          review_case: artifacts["review_case"],
          admission_status: nil
        )
      end

      # imported bundle の分類。admission_result は Task 7 が単一所有で判定
      # 済み。本メソッドは admission_status を参照のみし再判定しない。
      def classify_imported_bundle(bundle_intake:, admission_result:)
        admission_status = admission_result.fetch("admission_status")
        run_artifacts = bundle_intake.fetch("run_artifacts", {}) || {}
        review_case = run_artifacts["review_case"]
        metadata =
          (review_case.is_a?(Hash) && review_case["metadata"].is_a?(Hash) ?
             review_case["metadata"] : {}) || {}

        base =
          case admission_status
          when "rejected"
            result(
              run_id: admission_result["run_id"] || metadata["run_id"],
              classification: "analysis_blocked",
              phase_profile: metadata["phase_profile"],
              treatment: metadata["treatment"],
              reason_codes: ["imported_bundle_rejected_before_classification"],
              reason_details:
                ["Imported bundle rejected during admission " \
                 "(Task 7 single owner). Not eligible for classification."],
              insufficiency_kind: "rejected_admission"
            )
          when "admitted_exploratory"
            result(
              run_id: admission_result["run_id"] || metadata["run_id"],
              classification: "exploratory",
              phase_profile: metadata["phase_profile"],
              treatment: metadata["treatment"],
              reason_codes:
                ["imported_bundle_admitted_exploratory"] +
                Array(admission_result["admission_reason_codes"]),
              reason_details:
                ["Imported bundle retained for exploratory analysis only."],
              insufficiency_kind: nil
            )
          else # admitted_standard
            invalidation = invalidation_markers(run_artifacts)
            base_classification(
              metadata: metadata,
              missing_artifacts: [],
              invalidation_markers: invalidation
            )
          end

        decorated = decorate(
          base: base,
          metadata: metadata,
          review_case: review_case,
          admission_status: admission_status
        )
        # admission state は run validity と別に保持（Req10 受入 5）。
        decorated["admission_status"] = admission_status
        decorated["admission_reason_codes"] =
          Array(admission_result["admission_reason_codes"])
        decorated
      end

      private

      # --- 4 状態判定（design §2・§3） -----------------------------------------

      def base_classification(metadata:, missing_artifacts:, invalidation_markers:)
        run_id = metadata["run_id"]
        phase = metadata["phase_profile"]
        treatment = metadata["treatment"]

        # analysis_blocked: required input 不足 / run_status!=closed /
        # validator_status=blocked（design §2）。created・中断 run は invalid
        # でなく analysis_blocked（design §2 補足）。
        if !missing_artifacts.empty?
          return result(
            run_id: run_id, classification: "analysis_blocked",
            phase_profile: phase, treatment: treatment,
            reason_codes: ["required_input_missing"],
            reason_details:
              ["Missing evaluation input: #{missing_artifacts.join(', ')}"],
            insufficiency_kind: "missing_input"
          )
        end

        if metadata["run_status"] != "closed"
          return result(
            run_id: run_id, classification: "analysis_blocked",
            phase_profile: phase, treatment: treatment,
            reason_codes: ["run_status_not_closed"],
            reason_details:
              ["run_status is " \
               "#{metadata['run_status'] || 'unknown'} (not closed)."],
            insufficiency_kind: "missing_input"
          )
        end

        if metadata["validator_status"] == "blocked"
          return result(
            run_id: run_id, classification: "analysis_blocked",
            phase_profile: phase, treatment: treatment,
            reason_codes: ["validator_status_blocked"],
            reason_details:
              ["validator_status is blocked; validity undetermined."],
            insufficiency_kind: "missing_input"
          )
        end

        # invalid: invalidation marker あり or validator_status=failed。
        # 入力はあるが contract 違反（design §3 invalid）。
        if !invalidation_markers.empty? ||
           metadata["validator_status"] == "failed"
          return result(
            run_id: run_id, classification: "invalid",
            phase_profile: phase, treatment: treatment,
            reason_codes: invalid_reason_codes(metadata, invalidation_markers),
            reason_details:
              invalid_reason_details(metadata, invalidation_markers),
            insufficiency_kind: "invalid_input"
          )
        end

        # exploratory: evidence_class=exploratory。
        if metadata["evidence_class"] == "exploratory"
          return result(
            run_id: run_id, classification: "exploratory",
            phase_profile: phase, treatment: treatment,
            reason_codes: ["evidence_class_exploratory"],
            reason_details:
              ["evidence_class marks this run as exploratory."],
            insufficiency_kind: nil
          )
        end

        # valid: validator_status=passed かつ human_signoff 終端 かつ
        # evidence_class=valid（design §2）。
        if metadata["validator_status"] == "passed" &&
           TERMINAL_HUMAN_SIGNOFF.include?(metadata["human_signoff_status"]) &&
           metadata["evidence_class"] == "valid"
          return result(
            run_id: run_id, classification: "valid",
            phase_profile: phase, treatment: treatment,
            reason_codes: ["valid_population_member"],
            reason_details:
              ["validator passed, human sign-off terminal, " \
               "evidence_class valid."],
            insufficiency_kind: nil
          )
        end

        # どの規則にも該当しない -> analysis_blocked（valid/invalid 判定と
        # 混同しない。design §2 主目的）。
        result(
          run_id: run_id, classification: "analysis_blocked",
          phase_profile: phase, treatment: treatment,
          reason_codes: ["classification_precondition_not_met"],
          reason_details:
            ["Metadata does not satisfy valid/invalid/exploratory rules."],
          insufficiency_kind: "missing_input"
        )
      end

      # --- review-mode 直交軸 + 設計スキップ弁別の付与 -------------------------

      def decorate(base:, metadata:, review_case:, admission_status:)
        classification = base["classification"]
        in_population = classification == "valid"

        review_mode = metadata["review_mode"]
        slice_codes = []
        in_standard_set = false

        if review_mode == STANDARD_REVIEW_MODE
          # runtime_mediated valid のみ標準 runtime-mediated 比較集団。
          in_standard_set = (classification == "valid")
        elsif review_mode == MANUAL_DOGFOODING_REVIEW_MODE
          # manual dogfooding は Phase 1 evidence。明示 separate slice 以外は
          # standard runtime-mediated comparison set から除外（Req9 受入 6）。
          slice_codes << "manual_dogfooding_phase1_separate_slice"
          in_standard_set = false
        end

        step_disposition = step_omission_disposition(
          metadata: metadata, review_case: review_case
        )
        failure_gap = step_disposition.values.any? do |d|
          d["kind"] == "failure_gap"
        end

        decorated = base.dup
        decorated["review_mode"] = review_mode
        # 有効性分類と review-mode は直交（review_mode を分類理由にしない）。
        decorated["in_comparison_population"] = in_population
        decorated["excluded"] = !in_population
        decorated["in_standard_runtime_comparison_set"] = in_standard_set
        decorated["review_mode_slice_codes"] = slice_codes
        decorated["step_omission_disposition"] = step_disposition

        if failure_gap
          decorated["reason_codes"] =
            (Array(decorated["reason_codes"]) + ["step_failure_gap"]).uniq
          decorated["reason_details"] =
            Array(decorated["reason_details"]) +
            ["One or more step omissions are inconsistent with the " \
             "declared treatment (failure gap, not design skip)."]
        end
        decorated
      end

      # 設計スキップ vs 障害欠損（Req2 受入 3・design §4）。runtime 所有
      # TreatmentMatrix を正本に弁別する（評価は再定義しない）。
      def step_omission_disposition(metadata:, review_case:)
        treatment = metadata["treatment"]
        disposition = {}
        return disposition unless TM.supported_treatments.include?(treatment)

        observed = observed_step_states(review_case)
        TM::STEP_IDS.each do |sid|
          expected = TM.execution_state_for(treatment: treatment).fetch(sid)
          actual = observed[sid]

          kind =
            if expected == "executed"
              if actual == "executed" || actual.nil?
                "executed"
              else
                # 実行されるべき step が欠落/skip -> 障害欠損。
                "failure_gap"
              end
            else # expected skipped/reduced
              if actual.nil? || actual == expected ||
                 (expected == "skipped" && %w[skipped reduced].include?(actual))
                # treatment 由来の意図的省略 -> 設計スキップ。
                "design_skip"
              else
                # 印が宣言 treatment と矛盾 -> 障害欠損。
                "failure_gap"
              end
            end

          disposition[sid] = {
            "kind" => kind,
            "expected_execution_state" => expected,
            "observed_execution_state" => actual
          }
        end
        disposition
      end

      # review_case.step_records の step_status を runtime 実行印として読む
      # （runtime ReviewCaseProjector 投影規約。step_status = executed/
      # skipped/reduced）。
      def observed_step_states(review_case)
        return {} unless review_case.is_a?(Hash)

        records = review_case["step_records"]
        return {} unless records.is_a?(Array)

        records.each_with_object({}) do |rec, h|
          next unless rec.is_a?(Hash)

          h[rec["step_id"]] = rec["step_status"]
        end
      end

      def invalidation_markers(artifacts)
        im = artifacts["invalidation_markers"]
        im.is_a?(Hash) ? Array(im["invalidation_markers"]) : []
      end

      def invalid_reason_codes(metadata, markers)
        codes = []
        codes << "validator_failed" if metadata["validator_status"] == "failed"
        markers.each { |m| codes << "invalidation:#{m['reason_code']}" }
        codes.empty? ? ["invalid_without_marker_detail"] : codes
      end

      def invalid_reason_details(metadata, markers)
        details = []
        if metadata["validator_status"] == "failed"
          details << "validator_status is failed"
        end
        markers.each { |m| details << m["reason_detail"] }
        details.empty? ? ["Invalid classification without marker detail."] :
          details
      end

      def result(run_id:, classification:, phase_profile:, treatment:,
                 reason_codes:, reason_details:, insufficiency_kind:)
        {
          "run_id" => run_id,
          "classification" => classification,
          "reason_codes" => reason_codes,
          "reason_details" => reason_details,
          "phase_profile" => phase_profile,
          "treatment" => treatment,
          "insufficiency_kind" => insufficiency_kind
        }
      end
    end
  end
end
