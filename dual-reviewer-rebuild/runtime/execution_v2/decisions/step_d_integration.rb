# frozen_string_literal: true

require_relative "../contracts/treatment_matrix"

# Task 3: Step D Integration（追加 LLM 呼び出しなしの機械手順）
# 根拠: tasks.md Task 3、Requirement 1 受入 7、design「Step D: Integration」の
#       6 手順、設計再確定 finding 5（Step D は LLM 非依存・seam 不使用）。
#
# design Step D 統合 6 手順（機械的・新推論なし）:
#   1 Step A・Step B finding を収集し source_role を保持して統合集合化
#   2 Step C を含む treatment なら necessity judgment / final label を
#     機械的に紐づけ（非実行時はスキップ）
#   3 finding を decision unit 単位に集約（集約キー = requirement_link /
#     対象領域。新推論なし）
#   4 各 decision unit の proposed_action を Step C final label から写像。
#     ない場合は規定の既定規則で決める
#   5 run close readiness を必須 step 出力の充足のみで機械判定
#   6 結果を step_d_integration record と decision_units に書き出す
#     （human_decision は未確定のまま）
#
# accepted/rejected/deferred は Step D 出力ではなく後段 sign-off 結果
# （本波は decision unit 構造の生成までで human sign-off 接続は Task 5 波）。
# 配置: necessity / reopen / handback 判定（design File Placement: decisions/）。
module DualReviewer
  module Runtime
    class StepDIntegration
      # Step C final_label が無い場合の既定 proposed_action 規則。
      # 新たな推論をせず Step B の adversarial_outcome のみから機械決定する。
      DEFAULT_ACTION_BY_ADVERSARIAL = {
        "counter_evidence_raised" => "review_contested_finding",
        "no_counter_evidence_after_challenge" => "address_finding",
        "not_assessed" => "human_review_required"
      }.freeze
      FALLBACK_DEFAULT_ACTION = "human_review_required"

      # treatment ごとに Step D が close readiness 判定で要求する step 集合。
      # Step C は dual+judgment のみ必須（matrix 正本に追従）。
      def required_steps_for(treatment)
        state = TreatmentMatrix.execution_state_for(treatment: treatment)
        %w[step_a step_b step_c].select do |sid|
          state.fetch(sid) == "executed"
        end
      end

      # 入力: 固定の Step A/B/C 出力（前後 step なしで単体検証可能）。
      # 出力: decision_units / run_close_readiness / step_d_record。
      def integrate(step_a:, step_b:, step_c:, treatment:)
        required = required_steps_for(treatment)
        missing = []
        missing << "step_a" if required.include?("step_a") && step_a.nil?
        missing << "step_b" if required.include?("step_b") && step_b.nil?
        missing << "step_c" if required.include?("step_c") && step_c.nil?

        # 手順 1: Step A/B finding を source_role 保持で統合集合化。
        findings = collect_findings(step_a, step_b)

        # 手順 2: Step C を含む treatment なら judgment を機械的に紐づけ。
        judgments_by_finding = index_judgments(step_c)

        # 手順 3: requirement_link（無ければ対象領域 finding_id）で集約。
        grouped = group_by_decision_key(findings)

        # 手順 4: proposed_action を Step C final label から写像、無ければ既定規則。
        units = build_decision_units(grouped, judgments_by_finding)

        # 手順 5: run close readiness を必須 step 出力の充足のみで機械判定。
        readiness = {
          "ready" => missing.empty?,
          "missing_required_steps" => missing,
          "treatment" => treatment,
          "evaluated_required_steps" => required
        }

        # 手順 6: step_d record（LLM 非依存のため prompt_identity を持たない）。
        step_d_record = {
          "step_id" => "step_d",
          "step_name" => "integration",
          "execution_state" => "executed",
          "treatment" => treatment,
          "integrated_finding_count" => findings.length,
          "decision_unit_count" => units.length,
          "run_close_readiness" => readiness
        }

        {
          decision_units: units,
          run_close_readiness: readiness,
          step_d_record: step_d_record
        }
      end

      private

      def collect_findings(step_a, step_b)
        a = step_a ? Array(step_a["findings"]) : []
        b_assess = step_b ? Array(step_b["assessments"]) : []
        b_by_id = {}
        b_assess.each { |x| b_by_id[x["finding_id"]] = x }

        a.map do |f|
          fid = f["finding_id"]
          {
            "finding_id" => fid,
            "source_role" => f["source_role"] || "primary_reviewer",
            "requirement_link" => f["requirement_link"],
            "adversarial_outcome" =>
              (b_by_id[fid] || {})["adversarial_outcome"]
          }
        end
      end

      def index_judgments(step_c)
        return {} if step_c.nil?

        idx = {}
        Array(step_c["judgments"]).each do |j|
          idx[j["finding_id"]] = j
        end
        idx
      end

      def group_by_decision_key(findings)
        grouped = {}
        findings.each do |f|
          key = f["requirement_link"]
          key = "finding:#{f['finding_id']}" if key.nil? || key.to_s.empty?
          (grouped[key] ||= []) << f
        end
        grouped
      end

      def build_decision_units(grouped, judgments_by_finding)
        grouped.keys.sort.each_with_index.map do |key, i|
          members = grouped[key]
          finding_refs = members.map { |m| m["finding_id"] }
          judgment_refs = []
          mapped_label = nil
          members.each do |m|
            j = judgments_by_finding[m["finding_id"]]
            next unless j

            judgment_refs << m["finding_id"]
            mapped_label ||= j["recommended_action"] || j["final_label"]
          end

          proposed = mapped_label || default_action(members)

          {
            "decision_unit_id" => format("du-%03d", i + 1),
            "decision_key" => key,
            "finding_refs" => finding_refs,
            "judgment_refs" => judgment_refs,
            "proposed_action" => proposed,
            # human_decision は Step D では未確定（後段 sign-off で確定）。
            "human_decision" => nil,
            "human_decision_timestamp" => nil,
            "human_decision_note" => nil
          }
        end
      end

      # Step C final label が無い場合の既定規則（新推論なし・機械決定）。
      def default_action(members)
        outcomes = members.map { |m| m["adversarial_outcome"] }.compact
        outcomes.each do |o|
          mapped = DEFAULT_ACTION_BY_ADVERSARIAL[o]
          return mapped if mapped
        end
        FALLBACK_DEFAULT_ACTION
      end
    end
  end
end
