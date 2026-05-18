# frozen_string_literal: true

# Task 1: code / run directory skeleton
# 根拠: tasks.md Task 1、design「Runtime Artifact Layout」「File Placement for v2 Runtime Core」
#
# 1 run の正本ディレクトリ構造を機械的に列挙・説明する runtime 所有 contract。
# runtime はこの layout を所有する（design Boundary Clarification: run directory layout）。
# foundation contract は変更しない（consumer として参照するのみ）。
module DualReviewer
  module Runtime
    module RunLayout
      RUNS_BASE = "experiments/runs"

      # design「Runtime Artifact Layout」のツリーを正本とする。
      # key = run_id 相対の artifact パス、value = Placement Rationale の役割説明。
      ARTIFACT_CATALOG = {
        "run_manifest.yaml" =>
          "run metadata の operator-readable 正本（開始時固定群＋実行中更新群）",
        "review_case.json" =>
          "foundation schema に従う machine-readable 横断正本",
        "steps/step_a_primary_detection.json" =>
          "Step A（primary_detection）raw step output。step-level replay の最小単位",
        "steps/step_b_adversarial_review.json" =>
          "Step B（adversarial_review）raw step output",
        "steps/step_c_judgment.json" =>
          "Step C（judgment）raw step output",
        "steps/step_d_integration.json" =>
          "Step D（integration）統合 raw step output",
        "decisions/decision_units.json" =>
          "human decision 単位の正本（finding と human judgment の接続）",
        "decisions/human_signoff.json" =>
          "run 全体の人間 close judgment を表す run レベル正本",
        "failures/failure_observation.json" =>
          "review 実行が失敗状態に陥った場合の foundation failure_observation 準拠記録",
        "v2/review_artifact.json" =>
          "generic execution layer v2 の taxonomy-first internal canonical object（runtime 内部限定）",
        "v2/metric_snapshot.json" =>
          "v2 internal canonical artifact（metric snapshot）",
        "v2/trace_note.json" =>
          "v2 internal canonical artifact（trace note）",
        "v2/signal_linkage_note.json" =>
          "v2 internal canonical artifact（signal linkage note）",
        "validation/validator_result.json" =>
          "mechanical validation の正本",
        "validation/invalidation_markers.json" =>
          "invalidation 事実の正本（raw evidence を編集せず marker 追加で表現）",
        "derived/runtime_summary.json" =>
          "runtime convenience artifact（evaluation の正本ではない）",
        "derived/comparison_eligibility_note.json" =>
          "standard comparison 直接投入可否の判断補助 note（スキーマは runtime 所有）",
        "derived/invalid_run_triage_note.json" =>
          "invalid run の primary failure・linked checks・operator action hint の補助 note"
      }.freeze

      # runtime code 配置規約（design「File Placement for v2 Runtime Core」）。
      # analyzer / downstream 変換 / manifest logic を混在させない配置。
      CODE_PLACEMENT_ROLES = {
        "runtime/execution_v2/manifests/" =>
          "case manifest 読込・track specialization 解決",
        "runtime/execution_v2/analyzers/" =>
          "track-aware analyzer・evidence extraction",
        "runtime/execution_v2/decisions/" =>
          "necessity / reopen / handback / signal linkage 判定",
        "runtime/execution_v2/writers/" =>
          "compatibility artifact と v2 internal artifact の write",
        "runtime/execution_v2/contracts/" =>
          "layer 間 object shape（run layout 等の contract）",
        "scripts/protocol_runners/" =>
          "run entrypoint",
        "scripts/track_runs/" =>
          "comparison input や protocol artifact への adapter"
      }.freeze

      PLACEMENT_SEPARATION_RULES = [
        "analyzer logic を batch script に入れない",
        "downstream 変換 logic を execution core に混ぜない",
        "manifest logic を writer に混ぜない"
      ].freeze

      module_function

      # run_id 相対の正準 artifact パスを repo ルート相対で列挙する。
      def run_relative_artifacts(run_id)
        ARTIFACT_CATALOG.keys.map { |rel| "#{run_root_relative(run_id)}/#{rel}" }
      end

      def run_root_relative(run_id)
        "#{RUNS_BASE}/#{run_id}"
      end

      # run 直下の正準サブディレクトリ集合（design Placement Rationale）。
      def run_subdirectories
        ARTIFACT_CATALOG.keys
          .map { |rel| rel.include?("/") ? rel.split("/").first : nil }
          .compact
          .uniq
      end

      def artifact_catalog
        ARTIFACT_CATALOG
      end

      def code_placement_roles
        CODE_PLACEMENT_ROLES
      end

      def placement_separation_rules
        PLACEMENT_SEPARATION_RULES
      end
    end
  end
end
