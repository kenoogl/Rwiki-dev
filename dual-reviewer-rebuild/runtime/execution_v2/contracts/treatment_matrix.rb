# frozen_string_literal: true

# Task 3: Treatment × Step Execution Matrix
# 根拠: tasks.md Task 3、Requirement 2（受入 2〜5）、
#       design「Treatment × Step Execution Matrix」。
#
# treatment ごとの各 step 実行状態の正本。3 値:
#   executed — 通常実行
#   skipped  — treatment 選択により意図的に実行しない
#   reduced  — 対象・深さを限定して実行。現行 3 treatment では未使用。
#              将来 phase/profile 連動用の語彙として定義のみ。
# layer 間 object shape のため contracts/ に置く（design File Placement）。
module DualReviewer
  module Runtime
    module TreatmentMatrix
      EXECUTION_STATES = %w[executed skipped reduced].freeze

      STEP_IDS = %w[step_a step_b step_c step_d].freeze

      STEP_NAME_BY_ID = {
        "step_a" => "primary_detection",
        "step_b" => "adversarial_review",
        "step_c" => "judgment",
        "step_d" => "integration"
      }.freeze

      # design 表をそのまま正本化（再導出しない）。
      MATRIX = {
        "single" => {
          "step_a" => "executed", "step_b" => "skipped",
          "step_c" => "skipped",  "step_d" => "executed"
        },
        "dual" => {
          "step_a" => "executed", "step_b" => "executed",
          "step_c" => "skipped",  "step_d" => "executed"
        },
        "dual+judgment" => {
          "step_a" => "executed", "step_b" => "executed",
          "step_c" => "executed", "step_d" => "executed"
        }
      }.freeze

      module_function

      def supported_treatments
        MATRIX.keys
      end

      def execution_state_for(treatment:)
        state = MATRIX[treatment]
        unless state
          raise ArgumentError,
                "unsupported treatment #{treatment.inspect} " \
                "(allowed: #{MATRIX.keys.join('/')})"
        end
        state
      end

      # treatment 下で当該 step が実行されるべきか（executed か）。
      def executed?(treatment:, step_id:)
        execution_state_for(treatment: treatment).fetch(step_id) == "executed"
      end

      def step_name(step_id)
        STEP_NAME_BY_ID.fetch(step_id)
      end
    end
  end
end
