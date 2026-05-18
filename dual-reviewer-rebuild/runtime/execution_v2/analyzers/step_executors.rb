# frozen_string_literal: true

require_relative "../contracts/treatment_matrix"
require_relative "../profiles/phase_profile_config"

# Task 3: Step A/B/C executors（LLM seam 経由）
# 根拠: tasks.md Task 3、Requirement 1（受入 1〜4）、Requirement 2（受入 3・4）、
#       design「Step Execution Model」（Step A/B/C 入出力）、
#       設計再確定 finding 5（LLM 呼び出しを差し替え可能 seam 1 点に集約）。
#
# finding 5（再確定境界・本波の実装拘束）:
#   step 実行は固定文の簡易解析ではなく実 LLM 呼び出しとする設計だが、
#   テスト可能性のため LLM 呼び出しを差し替え可能な seam（境界）1 点に集約。
#   runtime は「step を実行し evidence を emit する」ことのみ所有。取得方式
#   （モデル/温度/別セッション起動方式）は v2-acquisition 所有で再定義しない。
#   v2-acquisition 未承認の現段では default をモック seam とし、テストは
#   固定応答 seam を注入（依存性注入）して決定的に検証する。確定後に実方式を
#   この seam へ差し込む（前方依存を seam で吸収）。
#
# 配置: track-aware analyzer / evidence extraction（design File Placement）。
module DualReviewer
  module Runtime
    class StepExecutors
      class StepExecutionError < StandardError; end

      ADVERSARIAL_OUTCOMES = %w[
        counter_evidence_raised
        no_counter_evidence_after_challenge
        not_assessed
      ].freeze

      # default seam: v2-acquisition 未承認段の決定的モック。実 LLM を呼ばず
      # 空の構造化出力を返す。実方式は v2-acquisition 確定後に差し込む。
      class MockSeam
        def call(role:, step:, prompt_body:, target:, context:)
          case step
          when "primary_detection" then { "findings" => [] }
          when "adversarial_review" then { "assessments" => [] }
          when "judgment" then { "judgments" => [] }
          else
            raise StepExecutionError, "mock seam: unknown step #{step.inspect}"
          end
        end
      end

      def initialize(llm_seam: MockSeam.new)
        @llm_seam = llm_seam
      end

      # treatment 由来の意図的 skip marker（要件 2 受入 4・5）。
      # 設計上の意図的 skip と事故的欠落を run record だけで区別可能にする。
      def self.skip_marker(step_id:, step_name:, treatment:, state: "skipped")
        unless TreatmentMatrix::EXECUTION_STATES.include?(state)
          raise ArgumentError, "invalid execution_state #{state.inspect}"
        end
        {
          "step_id" => step_id,
          "step_name" => step_name,
          "execution_state" => state,
          "reason" => "intentional #{state} by treatment selection " \
                      "(treatment=#{treatment})",
          "treatment" => treatment
        }
      end

      # Step A: Primary Detection。
      # 入力: target / phase_profile / primary prompt(identity) / config。
      # 出力: primary findings / step metadata / prompt identity。
      def run_step_a(target:, phase_profile:, prompt_identity:, treatment:,
                     config: {})
        body = require_prompt_body(prompt_identity)
        resp = @llm_seam.call(
          role: prompt_identity.fetch("role"), step: "primary_detection",
          prompt_body: body, target: target,
          context: profile_context(phase_profile, config: config)
        )
        findings = Array(resp["findings"])
        base_record("step_a", "primary_detection", treatment, prompt_identity,
                    phase_profile).merge("findings" => findings)
      end

      # Step B: Adversarial Review（forced-divergence）。
      # 各 finding の adversarial_outcome を必ず設定（要件 1 受入 4）。
      # 空 counter_evidence で「未試行」と「試行結果なし」を曖昧化しない。
      def run_step_b(target:, step_a_findings:, phase_profile:,
                     prompt_identity:, treatment:, config: {})
        body = require_prompt_body(prompt_identity)
        resp = @llm_seam.call(
          role: prompt_identity.fetch("role"), step: "adversarial_review",
          prompt_body: body, target: target,
          context: profile_context(phase_profile, config: config,
                                    step_a_findings: step_a_findings)
        )
        assessments = Array(resp["assessments"])
        assessments.each do |a|
          outcome = a["adversarial_outcome"]
          unless ADVERSARIAL_OUTCOMES.include?(outcome)
            raise StepExecutionError,
                  "Step B forced-divergence: each finding must set " \
                  "adversarial_outcome to one of " \
                  "#{ADVERSARIAL_OUTCOMES.join('/')} " \
                  "(finding=#{a['finding_id'].inspect}, got #{outcome.inspect})"
          end
        end
        base_record("step_b", "adversarial_review", treatment,
                    prompt_identity, phase_profile)
          .merge("assessments" => assessments)
      end

      # Step C: Judgment。
      # 入力: Step A/B findings / counter-evidence / judgment prompt / profile。
      # 出力: necessity judgments / final labels / recommended actions。
      def run_step_c(step_a_findings:, step_b_assessments:, phase_profile:,
                     prompt_identity:, treatment:, config: {})
        body = require_prompt_body(prompt_identity)
        resp = @llm_seam.call(
          role: prompt_identity.fetch("role"), step: "judgment",
          prompt_body: body, target: nil,
          context: profile_context(phase_profile, config: config,
                                    step_a_findings: step_a_findings,
                                    step_b_assessments: step_b_assessments)
        )
        base_record("step_c", "judgment", treatment, prompt_identity,
                    phase_profile)
          .merge("judgments" => Array(resp["judgments"]))
      end

      private

      # phase/profile 軸: runtime 所有 profile config から emphasis を解決し
      # seam context へ供給する（Task 10、受入 2）。step id/順序/state は
      # 触れない（state machine 不変）。emphasis は config 化されており本
      # メソッドは値を読むだけ。未知 profile は config が明示エラーにする。
      def profile_context(phase_profile, **extra)
        {
          phase_profile: phase_profile,
          profile_emphasis: PhaseProfileConfig.emphasis_for(phase_profile)
        }.merge(extra)
      end

      def base_record(step_id, step_name, treatment, prompt_identity,
                      phase_profile)
        {
          "step_id" => step_id,
          "step_name" => step_name,
          "execution_state" => "executed",
          "treatment" => treatment,
          "phase_profile" => phase_profile,
          "prompt_identity" => prompt_identity
        }
      end

      # prompt body は code 内に持たず resolver 解決物を必須入力とする
      # （Task 4 / Requirement 3 受入 1・5）。識別子だけでなく本文を要求。
      def require_prompt_body(prompt_identity)
        body = prompt_identity["body"]
        if body.nil? || body.to_s.strip.empty?
          # identity record（4 項目）のみで body 未注入の場合も実行可能に
          # するが、prompt 一意解決の証跡として identity 4 項目を必須とする。
          %w[prompt_artifact_path prompt_id prompt_version role].each do |k|
            if prompt_identity[k].nil?
              raise StepExecutionError,
                    "prompt identity incomplete: missing #{k}"
            end
          end
          return ""
        end
        body
      end
    end
  end
end
