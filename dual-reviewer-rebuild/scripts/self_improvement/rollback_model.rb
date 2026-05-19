#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "learning_layout"
require_relative "proposal_model"

# Task 7: rollback model（自己改善所有・スクラッチ）
#
# 根拠: tasks.md Task 7、Requirement 5（受入 1〜6）、design「Rollback
#       Model」「Decision 4」「Proposal States」（adopted→rolled_back）。
#       適合レビュー 2026-05-19 finding（Task 9 決定的検証皆無のうち
#       invalidation 起点 rollback 部分）解消の品質保証対象。
#
# スクラッチ方針: 旧 v1 record_self_improvement_rollback（2026-05-13・旧
# fixture corpus 前提）は流用せず破棄して作り直す。本モジュールは:
#   - rollback-triggering 条件を定義（Req5 受入 1）。
#   - rollback と supersession を区別する（Req5 受入 4、design：
#     supersession=より新しい改善で置換、rollback=有害な採用 change を戻す）。
#   - `rollback/rollback_register.json` に proposal_id / adopted_change_ref
#     / rollback_reason / rollback_trigger_signal_refs / rolled_back_at を
#     第1波 LearningLayout 正本パスに連結保存。reverted behavior を導入した
#     accepted proposal と rollback reason を evidence として保持（受入 2・3）。
#   - failed improvement の history を削除せず次の proposal input につなげる
#     （Req5 受入 5、Decision 4）。supersession は破壊削除せず先行を保持し
#     上書き関係を別 register に明示記録（rollback と別概念）。
#   - 採用済み改善の motivating evidence が事後に invalidate された場合、
#     foundation 無効化契約（foundation 要件 6）を起点に再評価または
#     rollback を機械起動（Req5 受入 6、design）。adoption_register の
#     adopted_change_ref（と起点 run）と runtime 正本配置
#     validation/invalidation_markers.json を連結する。
#
# proposal state machine（adopted→rolled_back のみ rollback 遷移許可、
# 終端 rolled_back/rejected 不可逆）は第4波 ProposalModel が正本であり
# 本モジュールは再定義しない（ProposalModel#transition を尊重する）。
# runtime/foundation/evaluation の schema・語彙は再定義しない（consumer
# 依存のみ）。raw evidence は mutate しない（register への追記のみ）。
module DualReviewer
  module SelfImprovement
    class RollbackModel
      LearningLayout = DualReviewer::SelfImprovement::LearningLayout

      ROLLBACK_REGISTER_PATH = "rollback/rollback_register.json"
      SUPERSESSION_REGISTER_PATH = "rollback/supersession_register.json"
      ADOPTION_REGISTER_PATH = "approved-updates/adoption_register.json"

      # Req5 受入 1 / design Rollback Model: rollback-triggering 条件。
      # 採用 change が有害だった／観測 regression／motivating evidence の
      # 事後 invalidate（foundation 要件 6 起点）。
      ROLLBACK_TRIGGERING_CONDITIONS = [
        "adopted_change_is_harmful",
        "post_adoption_regression_observed",
        "motivating_evidence_later_invalidated"
      ].freeze

      # reason_code → 事象種別（rollback vs supersession の機械区別）。
      # rollback=有害な採用 change を戻す。supersession=より新しい改善で
      # 置換（design Rollback Model / Input Model §2.5）。
      ROLLBACK_REASON_CODES = %w[
        harmful_change_detected regression_observed
        motivating_evidence_invalidated adopted_change_is_harmful
        post_adoption_regression_observed
        motivating_evidence_later_invalidated
      ].freeze
      SUPERSESSION_REASON_CODES = %w[
        later_runtime_evidence replaced_by_newer_improvement
      ].freeze

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @layout = LearningLayout
        # proposal state machine の正本（許可遷移・終端不可逆）を尊重する。
        @proposals = ProposalModel.new(repo_root: @repo_root)
      end

      # Req5 受入 1: rollback-triggering 条件を定義する。
      def rollback_triggering_conditions
        ROLLBACK_TRIGGERING_CONDITIONS
      end

      # Req5 受入 4 / design: rollback と supersession を区別する。
      def rollback_vs_supersession_distinction
        "Supersession means an adopted improvement is replaced by a newer " \
        "improvement; the prior proposal is NOT deleted and the override " \
        "relationship is recorded non-destructively (Input Model 2.5). " \
        "Rollback means an adopted change was harmful and must be reverted, " \
        "or its motivating evidence was later invalidated under the " \
        "foundation invalidation contract (foundation Requirement 6), so " \
        "that no adopted change remains in steady state on evidence that no " \
        "longer holds (Decision 4). They are recorded in separate registers."
      end

      # reason_code を rollback / supersession に機械分類する。
      def classify_event(reason_code:)
        code = reason_code.to_s
        return "supersession" if SUPERSESSION_REASON_CODES.include?(code)

        "rollback"
      end

      # adopted → rolled_back を記録する（Req5 受入 2・3）。
      # state machine（ProposalModel）を尊重し adopted 以外からは記録しない。
      # 終端 rolled_back/rejected からの再 rollback は不可逆として弾く。
      def rollback(learning_root:, proposal:, rollback_reason:,
                   rollback_trigger_signal_refs:)
        from = proposal["status"].to_s
        t = @proposals.transition(from: from, to: "rolled_back")
        unless t["allowed"]
          return { "rolled_back" => false, "reason" => t["reason"],
                   "status" => proposal["status"] }
        end

        adopted_change_ref = adopted_change_ref_for(
          learning_root: learning_root,
          proposal_id: proposal["proposal_id"]
        )
        upsert_register(
          learning_root: learning_root,
          relative_path: ROLLBACK_REGISTER_PATH,
          entry: {
            "proposal_id" => proposal["proposal_id"],
            "adopted_change_ref" => adopted_change_ref,
            "rollback_reason" => rollback_reason,
            "rollback_trigger_signal_refs" =>
              Array(rollback_trigger_signal_refs),
            "rolled_back_at" => rolled_back_at(proposal)
          }
        )
        { "rolled_back" => true, "reason" => nil, "status" => "rolled_back" }
      end

      # Req5 受入 4・5: supersession を破壊削除せず先行を保持し上書き関係を
      # 別 register に明示記録する（rollback と別概念）。
      def record_supersession(learning_root:, superseded_proposal:,
                              superseded_by:, supersession_reason:)
        if blank?(superseded_by)
          return { "recorded" => false, "reason" => "superseded_by_missing" }
        end

        upsert_register(
          learning_root: learning_root,
          relative_path: SUPERSESSION_REGISTER_PATH,
          entry: {
            "proposal_id" => superseded_proposal["proposal_id"],
            "superseded_by" => superseded_by,
            "supersession_reason" => supersession_reason,
            "superseded_at" => superseded_at(superseded_proposal),
            # 先行が手動由来であった事実を上書き後も保持（Input Model 2.5）。
            "source_origin" => superseded_proposal["source_origin"]
          }
        )
        { "recorded" => true, "reason" => nil }
      end

      # Req5 受入 5 / Decision 4: failed improvement の history を削除せず
      # 次の proposal input につなげる。rollback_register をそのまま読み、
      # 次 proposal 生成が消費できる input shape に射影する（raw 不削除）。
      def failed_improvement_inputs(learning_root:)
        path = Pathname(learning_root) + ROLLBACK_REGISTER_PATH
        return [] unless path.file?

        entries = Array(JSON.parse(path.read)["entries"])
        entries.map do |e|
          {
            "proposal_id" => e["proposal_id"],
            "outcome" => "rollback",
            "rollback_reason" => e["rollback_reason"],
            "rollback_trigger_signal_refs" =>
              Array(e["rollback_trigger_signal_refs"]),
            "adopted_change_ref" => e["adopted_change_ref"],
            "rolled_back_at" => e["rolled_back_at"]
          }
        end
      end

      # Req5 受入 6 / design: 採用済み改善の motivating evidence が事後に
      # invalidate された場合、foundation 無効化契約（foundation 要件 6）を
      # 起点に再評価または rollback を機械起動する。adoption_register の
      # 起点 run と runtime 正本配置 validation/invalidation_markers.json を
      # 連結し、marker が立った proposal だけ action を返す。
      def reassess_on_invalidation(learning_root:, proposals:)
        register = load_adoption_register(learning_root: learning_root)
        results = []
        Array(proposals).each do |proposal|
          entry = register[proposal["proposal_id"]]
          next if entry.nil?

          marker_refs = invalidation_marker_refs_for(
            motivating_run_refs: Array(entry["motivating_run_refs"])
          )
          next if marker_refs.empty?

          # 成り立たない根拠の上に採用済み change を steady state で残さない。
          # adopted は機械 rollback、それ以外（既に rolled_back 等）は
          # 再評価に倒す（state machine を破らない保守判定）。
          action =
            if proposal["status"].to_s == "adopted"
              "rollback"
            else
              "re_evaluation"
            end

          if action == "rollback"
            rollback(
              learning_root: learning_root, proposal: proposal,
              rollback_reason:
                "motivating evidence later invalidated " \
                "(foundation invalidation contract)",
              rollback_trigger_signal_refs: marker_refs
            )
          end

          results << {
            "proposal_id" => proposal["proposal_id"],
            "action" => action,
            "invalidation_marker_refs" => marker_refs,
            "adopted_change_ref" => entry["adopted_change_ref"]
          }
        end
        results
      end

      private

      # adoption_register から proposal_id → entry を引く。
      def load_adoption_register(learning_root:)
        path = Pathname(learning_root) + ADOPTION_REGISTER_PATH
        return {} unless path.file?

        Array(JSON.parse(path.read)["entries"]).each_with_object({}) do |e, h|
          h[e["proposal_id"]] = e
        end
      rescue JSON::ParserError
        {}
      end

      def adopted_change_ref_for(learning_root:, proposal_id:)
        load_adoption_register(learning_root: learning_root)
          .dig(proposal_id, "adopted_change_ref")
      end

      # 起点 run の runtime 正本配置 validation/invalidation_markers.json を
      # manifest-based に解決し、立っている marker への参照を返す。
      # 固定 path 列挙でなく run_id を canonical anchor とする
      # （適合レビュー 2026-05-19 の false-negative 防止方針に整合）。
      def invalidation_marker_refs_for(motivating_run_refs:)
        refs = []
        motivating_run_refs.each do |run_id|
          path = @repo_root +
                 "experiments/runs/#{run_id}/validation/" \
                 "invalidation_markers.json"
          next unless path.file?

          markers = Array(JSON.parse(path.read)["invalidation_markers"])
          markers.each do |m|
            next if m.nil? || m.empty?

            mid = m["marker_id"] || "marker"
            refs << "experiments/runs/#{run_id}/validation/" \
                    "invalidation_markers.json##{mid}"
          end
        end
        refs
      rescue JSON::ParserError
        []
      end

      # proposal_id ごとに冪等な register 追記（既存 entry は置換）。
      # 第1波 LearningLayout の mkpath 保証・schema_version 付与を使う。
      def upsert_register(learning_root:, relative_path:, entry:)
        path = Pathname(learning_root) + relative_path
        entries =
          if path.file?
            Array(JSON.parse(path.read)["entries"])
          else
            []
          end
        entries.reject! { |e| e["proposal_id"] == entry["proposal_id"] }
        entries << entry
        @layout.write_artifact(
          learning_root: learning_root,
          relative_path: relative_path,
          payload: { "entries" => entries }
        )
      end

      def rolled_back_at(proposal)
        proposal["rolled_back_at"] || proposal["decided_at"] ||
          "1970-01-01T00:00:00Z"
      end

      def superseded_at(proposal)
        proposal["superseded_at"] || proposal["decided_at"] ||
          "1970-01-01T00:00:00Z"
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
