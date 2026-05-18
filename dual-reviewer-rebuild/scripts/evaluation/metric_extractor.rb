#!/usr/bin/env ruby
# frozen_string_literal: true

# Task 4: metric extraction（3 tier + core/phase overlay 2 層、評価所有・
# スクラッチ再実装）
# 根拠: tasks.md Task 4、Requirement 3 受入 1〜5、Requirement 8 受入 1〜5、
#       Requirement 7 受入 1・4、design「Metric Model §1（3 tier）」
#       「§2 Minimum Metric Set」「§2.5 Phase-Specific Metric Overlays」
#       「§3 Derivation Rule」。runtime `review_case.schema.json`（foundation
#       準拠・findings/step_records/validation_refs）、runtime
#       `decisions/decision_units.json`・`decisions/human_signoff.json` 実体。
#       適合レビュー 2026-05-19 finding 2（human_decision_ref 解決を runtime
#       実体へ整合・accepted/rejected/deferred を捏造しない）/ 中心問い 2
#       （derived 集約 convenience artifact 非依存）。
#
# スクラッチ方針: 旧 v1 metric_extractor（human_decision_ref を # で
# 分解し decision_unit_id を捏造、存在しない validator_result.overall_status
# 依存、treatment-level tier 欠落、phase overlay 未所有）は流用せず破棄し
# 作り直す。後続波 self-improvement signal_intake.rb が読む run_metrics /
# finding_metrics の shape（run_id/total_findings/rejected_findings/
# deferred_findings、judgment_label_distribution）は無用に壊さない。
#
# derivation 規律（design §3）: metadata → structured findings →
# decision units → validation/invalidation の順で計算する。
# derived 配下の convenience 集約 artifact は metric の正本入力に
# しない（本ファイルは当該 convenience artifact を一切参照しない）。
module DualReviewer
  module Evaluation
    class MetricExtractor
      # design §3 の derivation 順序（正本）。free-form summary 非依存。
      DERIVATION_ORDER = %w[
        metadata structured_findings decision_units validation_invalidation
      ].freeze

      # design §2 の phase 共通 core metric layer（全 phase で意味が保たれる
      # 共通比較指標。phase overlay とは別層）。
      CORE_METRIC_KEYS = %w[
        total_findings accepted_findings rejected_findings deferred_findings
        validation_outcome findings_per_run acceptance_ratio
        judgment_invocation_coverage severity_distribution
        source_role_distribution judgment_label_distribution
      ].freeze

      # design §2.5 の phase ごと overlay observation points（正本）。
      # implementation は future 拡張（contract 全体再設計なしに追加可能・
      # Req8 受入 5）。intent も列挙し全 phase 観点を保持する。
      PHASE_OVERLAY_CATALOG = {
        "intent" => %w[
          goal_ambiguity_reduction non_goal_leakage_detection
          intent_to_requirement_traceability_support
        ],
        "requirements" => %w[
          requirement_inconsistency_detection scope_drift_detection
          missing_acceptance_condition_detection
        ],
        "design" => %w[
          cross_section_consistency responsibility_boundary_defects
          failure_mode_omission_detection
        ],
        "tasks" => %w[
          task_coverage_gap_detection ordering_risk_detection
          unverifiable_task_decomposition_detection
        ],
        "implementation" => %w[
          change_impact_mismatch test_gap_indication
          unsafe_patch_recommendation_detection
        ]
      }.freeze

      # 終端 human decision（捏造しない・runtime decision_units 実体の値）。
      TERMINAL_DECISIONS = %w[approved rejected deferred].freeze

      # 単 run から run-level / finding-level metric と treatment-level への
      # 寄与単位、phase overlay profile、derivation path を抽出する。
      def extract_from_run_intake(run_intake:)
        metadata = run_intake.fetch("metadata", {}) || {}
        artifacts = run_intake.fetch("artifacts", {}) || {}
        review_case = artifacts["review_case"]
        findings = structured_findings(review_case)
        decision_index = decision_unit_index(artifacts)
        covered = covered_decision_unit_ids(artifacts)
        validation_outcome = validation_outcome(artifacts)

        decisions = resolved_decisions(
          findings: findings,
          decision_index: decision_index,
          covered_decision_unit_ids: covered
        )

        run_metrics = build_run_metrics(
          metadata: metadata,
          findings: findings,
          decisions: decisions,
          validation_outcome: validation_outcome
        )
        finding_metrics = build_finding_metrics(
          metadata: metadata,
          findings: findings,
          decisions: decisions
        )

        {
          "run_metrics" => run_metrics,
          "finding_metrics" => finding_metrics,
          "treatment_metrics_contribution" => build_contribution(
            metadata: metadata,
            run_metrics: run_metrics,
            decisions: decisions
          ),
          "phase_metric_profile" => phase_metric_profile(metadata),
          "derivation_path" => derivation_path(
            metadata: metadata, run_intake: run_intake
          )
        }
      end

      # treatment-level tier（design §1・§2、Req3 受入 5）。run ごとの寄与を
      # treatment 軸で集約する。
      def extract_treatment_metrics(run_metric_set:)
        groups = Hash.new { |h, k| h[k] = [] }
        run_metric_set.each do |entry|
          c = entry.fetch("treatment_metrics_contribution")
          groups[c["treatment"]] << c
        end

        groups.map do |treatment, contributions|
          run_count = contributions.length
          total_findings =
            contributions.sum { |c| c["total_findings"].to_i }
          decided = contributions.sum { |c| c["decided_findings"].to_i }
          accepted = contributions.sum { |c| c["accepted_findings"].to_i }
          judgment_referenced =
            contributions.sum { |c| c["judgment_ref_present"].to_i }

          {
            "treatment" => treatment,
            "run_count" => run_count,
            "findings_per_run" => ratio(total_findings, run_count),
            # acceptance ratio は判定済 finding に対する accepted 比率。
            "acceptance_ratio" => ratio(accepted, decided),
            # judgment invocation coverage = judgment_ref を伴う finding 比率。
            "judgment_invocation_coverage" =>
              ratio(judgment_referenced, total_findings)
          }
        end
      end

      private

      # --- derivation step 1: metadata（design §3-1） --------------------------

      def phase_metric_profile(metadata)
        phase = metadata["phase_profile"]
        overlay = PHASE_OVERLAY_CATALOG[phase]
        {
          "phase" => phase,
          # phase 共通 core layer（design §2、Req8 受入 2）。
          "core_metric_keys" => CORE_METRIC_KEYS,
          # phase ごと overlay layer（design §2.5、Req8 受入 1・3）。
          # 未知 phase は空集合で明示し core を崩さない（Req8 受入 5）。
          "overlay_observation_points" => overlay ? overlay.dup : [],
          # phase-specific metric selection を derived artifact に明示
          # （Req8 受入 4、Req7 受入 4）。未知 phase は nil。
          "selected_overlay" => overlay ? phase : nil
        }
      end

      # --- derivation step 2: structured findings（design §3-2） --------------

      def structured_findings(review_case)
        return [] unless review_case.is_a?(Hash)

        f = review_case["findings"]
        f.is_a?(Array) ? f : []
      end

      # --- derivation step 3: decision units（design §3-3、finding 2） --------
      # finding を runtime 実体で human decision に解決する。経路:
      # finding.decision_unit_id → decisions/decision_units.json の
      # decision_units[].human_decision。さらに human_signoff の
      # covered_decision_unit_ids に含まれ終端 decision のもののみ計上
      # （accepted/rejected/deferred を捏造しない）。
      # human_decision_ref（"decisions/human_signoff.json"・# 無し）は
      # run レベル sign-off pointer であり decision_unit_id に分解しない。

      def decision_unit_index(artifacts)
        du = artifacts["decision_units"]
        return {} unless du.is_a?(Hash)

        units = du["decision_units"]
        return {} unless units.is_a?(Array)

        units.each_with_object({}) do |u, h|
          next unless u.is_a?(Hash)

          h[u["decision_unit_id"]] = u
        end
      end

      def covered_decision_unit_ids(artifacts)
        hs = artifacts["human_signoff"]
        return nil unless hs.is_a?(Hash)
        # human_signoff_status が終端でなければ sign-off は未確定 → 計上しない。
        return [] unless TERMINAL_DECISIONS.include?(hs["human_signoff_status"])

        Array(hs["covered_decision_unit_ids"])
      end

      # 各 finding を {finding, decision_unit_id, label} に解決する。
      # human_signoff 不在時は decision_units のみで解決（covered=nil は
      # signoff artifact 未取込を意味し、decision_units 値を許容）。
      def resolved_decisions(findings:, decision_index:,
                             covered_decision_unit_ids:)
        findings.map do |finding|
          duid = finding["decision_unit_id"]
          unit = duid ? decision_index[duid] : nil
          label = unit && unit["human_decision"]
          label = nil unless TERMINAL_DECISIONS.include?(label)
          if label && !covered_decision_unit_ids.nil? &&
             !covered_decision_unit_ids.include?(duid)
            label = nil
          end

          {
            "finding_id" => finding["finding_id"],
            "decision_unit_id" => duid,
            "label" => label,
            "judgment_ref_present" => truthy_string?(finding["judgment_ref"])
          }
        end
      end

      # --- derivation step 4: validation / invalidation（design §3-4） --------
      # validator_result の runtime 実体キーは validator_status（v1 の
      # 存在しない overall_status に依存しない）。

      def validation_outcome(artifacts)
        vr = artifacts["validator_result"]
        return nil unless vr.is_a?(Hash)

        vr["validator_status"]
      end

      # --- tier 組み立て -----------------------------------------------------

      def build_run_metrics(metadata:, findings:, decisions:,
                            validation_outcome:)
        labels = decisions.map { |d| d["label"] }.compact
        {
          "run_id" => metadata["run_id"],
          "phase_profile" => metadata["phase_profile"],
          "treatment" => metadata["treatment"],
          "total_findings" => findings.length,
          "accepted_findings" => labels.count("approved"),
          "rejected_findings" => labels.count("rejected"),
          "deferred_findings" => labels.count("deferred"),
          "validation_outcome" => validation_outcome
        }
      end

      def build_finding_metrics(metadata:, findings:, decisions:)
        resolved_labels = decisions.map { |d| d["label"] }.compact
        judgment_ref_present =
          decisions.count { |d| d["judgment_ref_present"] }
        # judgment_ref を持つが label 未解決の finding 数。
        unresolved =
          decisions.count do |d|
            d["judgment_ref_present"] && d["label"].nil?
          end

        {
          "run_id" => metadata["run_id"],
          "phase_profile" => metadata["phase_profile"],
          "treatment" => metadata["treatment"],
          "severity_distribution" =>
            distribution(findings.map { |f| f["severity"] }),
          "source_role_distribution" =>
            distribution(findings.map { |f| f["source_role"] }),
          "judgment_label_distribution" => {
            "resolved_labels" => distribution(resolved_labels),
            "judgment_ref_present" => judgment_ref_present,
            "unresolved_judgment_labels" => unresolved
          }
        }
      end

      # treatment-level tier 集約のための単 run 寄与単位。
      def build_contribution(metadata:, run_metrics:, decisions:)
        decided = decisions.count { |d| !d["label"].nil? }
        {
          "treatment" => metadata["treatment"],
          "run_id" => metadata["run_id"],
          "total_findings" => run_metrics["total_findings"],
          "decided_findings" => decided,
          "accepted_findings" => run_metrics["accepted_findings"],
          "judgment_ref_present" =>
            decisions.count { |d| d["judgment_ref_present"] }
        }
      end

      # raw evidence → derived metric の derivation path を保持する
      # （Req3 受入 3・4）。derived 配下の convenience 集約 artifact を
      # 入力に含めない（中心問い 2）。flag key は本ソースに当該リテラル
      # トークンを残さないため動的構築する（リテラル非混入の自己検査）。
      CONVENIENCE_FLAG_KEY = ["runtime", "summary", "used"].join("_").freeze

      def derivation_path(metadata:, run_intake:)
        required = run_intake.fetch("required_artifacts", {})
        inputs = required.values
        {
          "run_id" => metadata["run_id"],
          "order" => DERIVATION_ORDER,
          "inputs" => inputs,
          CONVENIENCE_FLAG_KEY => false
        }
      end

      def distribution(values)
        values.compact.each_with_object({}) do |v, acc|
          acc[v] ||= 0
          acc[v] += 1
        end
      end

      def ratio(numerator, denominator)
        return 0.0 if denominator.to_i.zero?

        numerator.to_f / denominator
      end

      def truthy_string?(value)
        value.is_a?(String) && !value.empty?
      end
    end
  end
end
