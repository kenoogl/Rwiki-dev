# frozen_string_literal: true

# Task 10: phase-aware review profiles（runtime-owned profile configuration）
# 根拠: tasks.md Task 10、Requirement 8（受入 1〜5）、
#       design「Phase-Aware Review Profiles」「Phase/Profile and Treatment Axes」
#       「Step Execution Model」「File Placement for v2 Runtime Core」。
#
# 本モジュールの責務（design 正本どおり）:
#   - intent/requirements/design/tasks の explicit phase/profile 選択を支援（受入 1）。
#   - profile ごとの emphasis を runtime 所有 config として保持（design、
#     foundation に戻さない）。canonical Step A/B/C/D state machine は変えない
#     （emphasis は step executor が seam context へ供給するだけで、step 列・
#     順序・state には触れない＝受入 2）。
#   - design/tasks は upstream(intent/requirements) より強い構造・依存指向
#     review にする（受入 4）。
#   - 使用 phase/profile を run metadata に保持できる descriptor を提供（受入 3）。
#   - treatment 選択と phase/profile 選択を区別。本 config は treatment 語彙を
#     持たず判定にも用いない（受入 5）。
#
# 配置: design「File Placement for v2 Runtime Core」の execution_v2 層に、
#       analyzer/writer/manifest と混在させない独立 profile モジュールとして
#       置く。emphasis は config 化（コード分岐に散らさない）。
module DualReviewer
  module Runtime
    module PhaseProfileConfig
      module_function

      # phase/profile 値語彙は runtime 所有（design §3）。treatment 軸とは別。
      PHASE_PROFILES = %w[intent requirements design tasks].freeze

      # 初版 emphasis（design「Phase-Aware Review Profiles」正本どおり）。
      # 識別子は安定 token（snake_case）で固定し、表示文ではなく config 値とする。
      EMPHASIS = {
        "intent" => %w[goal_ambiguity non_goal_leakage].freeze,
        "requirements" => %w[scope_drift requirement_inconsistency].freeze,
        "design" => %w[
          responsibility_boundary dependency_mismatch failure_mode_omission
        ].freeze,
        "tasks" => %w[
          coverage_gap ordering_risk unverifiable_task_decomposition
        ].freeze
      }.freeze

      # 受入 4: design/tasks は upstream より強い構造・依存指向。
      # rank は upstream(0,1) < downstream(2,3) を厳密に満たす単調序列とし、
      # state machine ではなく emphasis 強度の軸として扱う。
      STRUCTURAL_DEPENDENCY_RANK = {
        "intent" => 0,
        "requirements" => 1,
        "design" => 2,
        "tasks" => 3
      }.freeze

      # 構造・依存指向 review を強める profile（受入 4）。upstream は対象外。
      STRUCTURAL_DEPENDENCY_PROFILES = %w[design tasks].freeze

      def phase_profiles
        PHASE_PROFILES.dup
      end

      def supported?(phase_profile)
        PHASE_PROFILES.include?(phase_profile)
      end

      # 拡張解釈しない: 未知 profile は黙って既定にせず明示エラー。
      def emphasis_for(phase_profile)
        ensure_known!(phase_profile)
        EMPHASIS.fetch(phase_profile).dup
      end

      def structural_dependency_rank(phase_profile)
        ensure_known!(phase_profile)
        STRUCTURAL_DEPENDENCY_RANK.fetch(phase_profile)
      end

      def structural_dependency_oriented?(phase_profile)
        ensure_known!(phase_profile)
        STRUCTURAL_DEPENDENCY_PROFILES.include?(phase_profile)
      end

      # 受入 3: 使用 phase/profile を run metadata に保持するための descriptor。
      # treatment はここに含めない（軸分離・受入 5）。controller 側で
      # treatment と並べて別 field として持たせる前提。
      def run_metadata_descriptor(phase_profile)
        ensure_known!(phase_profile)
        {
          "phase_profile" => phase_profile,
          "profile_emphasis" => emphasis_for(phase_profile),
          "structural_dependency_oriented" =>
            structural_dependency_oriented?(phase_profile),
          "structural_dependency_rank" =>
            structural_dependency_rank(phase_profile)
        }
      end

      def ensure_known!(phase_profile)
        return if PHASE_PROFILES.include?(phase_profile)

        raise ArgumentError,
              "unknown phase_profile: #{phase_profile.inspect} " \
              "(allowed: #{PHASE_PROFILES.join('/')})"
      end
    end
  end
end
