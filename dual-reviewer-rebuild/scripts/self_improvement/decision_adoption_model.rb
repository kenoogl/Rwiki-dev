#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "learning_layout"
require_relative "proposal_model"

# Task 6: decision / adoption model（自己改善所有・スクラッチ）
#
# 根拠: tasks.md Task 6、Requirement 4（受入 1〜5）、design「Decision and
#       Adoption Model §1〜§3」「Decision 3」「Proposal States」。
#       適合レビュー 2026-05-19 finding（Task 9 決定的検証皆無のうち
#       adoption gate 3 条件部分）解消の品質保証対象。
#
# スクラッチ方針: 旧 v1 record_self_improvement_decision/history_registry
# （2026-05-13・旧 fixture corpus 前提）は流用せず破棄して作り直す。本
# モジュールは:
#   - approval gate（design §1）: prompt / policy / schema / runtime-affecting
#     workflow change に human approval を必須とする。`approved` は採否判断
#     であり repo change が入ったことをまだ意味しない。
#   - adoption gate（design §2 / Decision 3）: `adopted` 条件 = (1) proposal
#     が approved (2) required test artifact が存在し未検証(untested)でない
#     (3) repo change が version update と結びつく。3 条件いずれか欠落で
#     adopted にしない。
#   - adoption_register（Req4 受入 3・4）: proposal_id / adopted_change_ref /
#     version_update_ref / approval_ref / test_artifact_ref / adopted_at を
#     第1波 LearningLayout 正本パスに連結保存（proposal と repo change を結ぶ）。
#   - rejection model（design §3 / Req4 受入 5）: rejection を invisible
#     discard でなく preserved outcome として rejection_register に残す。
#
# proposal state machine（draft/awaiting_test/tested/approved/rejected/
# adopted/rolled_back、許可遷移と終端不可逆）は第4波 ProposalModel が正本
# であり本モジュールは再定義しない（ProposalModel#transition を尊重する）。
# runtime/foundation/evaluation の schema・語彙は再定義しない。raw evidence
# は mutate しない（register への追記のみ）。
module DualReviewer
  module SelfImprovement
    class DecisionAdoptionModel
      LearningLayout = DualReviewer::SelfImprovement::LearningLayout

      # design §1: human approval が必要な対象（runtime-affecting layer）。
      # report / paper / export は runtime-affecting でないため対象外
      # （Task 8 / design Separation from Paper Narrative と整合）。
      APPROVAL_REQUIRED_LAYERS = %w[prompt policy schema runtime workflow].freeze

      # adoption の根拠にできない test result label（Req3 受入 4 / Decision 3：
      # 未検証 artifact を採用根拠にしない）。
      NON_ADOPTABLE_RESULT_LABELS = %w[untested].freeze

      ADOPTION_REGISTER_PATH = "approved-updates/adoption_register.json"
      REJECTION_REGISTER_PATH = "rejected-updates/rejection_register.json"

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @layout = LearningLayout
        # proposal state machine の正本（許可遷移・終端不可逆）を尊重する。
        @proposals = ProposalModel.new(repo_root: @repo_root)
      end

      # design §1 / Req4 受入 2: approval gate。runtime-affecting layer は
      # human approval 必須。対象外 layer は approval gate を通さない
      # （runtime-affecting でないため採用フローに乗らない＝境界明示）。
      def approval_gate(target_layer:)
        layer = target_layer.to_s
        required = APPROVAL_REQUIRED_LAYERS.include?(layer)
        {
          "target_layer" => layer,
          "human_approval_required" => required,
          "allowed" => required,
          "reason" => required ? nil : "not_runtime_affecting"
        }
      end

      # tested → approved を記録する。state machine（ProposalModel）を尊重し
      # 許可遷移元（tested）以外からは記録しない。`approved` は採否判断で
      # あり repo change 反映を意味しないことを結果に明示する（design §1）。
      def record_approval(learning_root:, proposal:, approver:,
                          approval_note: nil)
        layer = proposal["target_layer"].to_s
        gate = approval_gate(target_layer: layer)
        unless gate["human_approval_required"]
          return { "recorded" => false, "reason" => "not_runtime_affecting",
                   "status" => proposal["status"] }
        end

        t = @proposals.transition(from: proposal["status"].to_s,
                                  to: "approved")
        unless t["allowed"]
          return { "recorded" => false, "reason" => t["reason"],
                   "status" => proposal["status"] }
        end

        @proposals.record_decision(
          learning_root: learning_root, proposal: proposal,
          decision: "approved", note: approval_note
        )
        {
          "recorded" => true,
          "reason" => nil,
          "status" => "approved",
          "approver" => approver,
          # design §1: approved は repo change が入ったことを意味しない。
          "repo_change_applied" => false,
          "adopted" => false
        }
      end

      # design §2 / Decision 3 / Req4 受入 3・4: adoption gate。
      # 3 条件 = (1) proposal が approved (2) required test artifact が存在し
      # 未検証でない (3) repo change が version update と結びつく。
      # state machine（approved→adopted）も尊重する。3 条件いずれか欠落で
      # adopted にせず理由を返す。
      def adopt(learning_root:, proposal:, adopted_change_ref:,
                version_update_ref:, approval_ref:, test_artifact_ref:)
        # 条件 1: proposal が approved。
        # `tested` は adopted への合法経路（tested→approved→adopted）の
        # 途上であり「未だ approved でない」を意味する条件 1 欠落として
        # `proposal_not_approved` を返す。それ以外（draft 等、approved を
        # 経て adopted に到達できない）は state machine 正本どおり
        # `illegal_transition` を返す（state machine を再定義しない）。
        unless proposal["status"].to_s == "approved"
          status = proposal["status"].to_s
          reason =
            if status == "tested"
              "proposal_not_approved"
            else
              @proposals.transition(from: status, to: "adopted")["reason"]
            end
          return { "adopted" => false, "reason" => reason,
                   "status" => proposal["status"] }
        end

        # 条件 2: required test artifact が存在し untested でない。
        ta = resolve_test_artifact(
          learning_root: learning_root, proposal: proposal,
          test_artifact_ref: test_artifact_ref
        )
        if ta.nil?
          return { "adopted" => false, "reason" => "test_artifact_missing",
                   "status" => proposal["status"] }
        end
        if NON_ADOPTABLE_RESULT_LABELS.include?(ta["result_label"].to_s)
          return { "adopted" => false, "reason" => "test_artifact_untested",
                   "status" => proposal["status"] }
        end

        # 条件 3: repo change が version update と結びつく。
        if blank?(adopted_change_ref)
          return { "adopted" => false, "reason" => "repo_change_missing",
                   "status" => proposal["status"] }
        end
        if blank?(version_update_ref)
          return { "adopted" => false, "reason" => "version_update_missing",
                   "status" => proposal["status"] }
        end

        # state machine 正本で approved→adopted を確認（防御的）。
        t = @proposals.transition(from: "approved", to: "adopted")
        unless t["allowed"]
          return { "adopted" => false, "reason" => t["reason"],
                   "status" => proposal["status"] }
        end

        # 波間結合（Task 7 / Req5 受入 6）: RollbackModel#reassess_on_
        # invalidation は adoption_register の motivating_run_refs（起点 run
        # を runtime invalidation marker に連結する anchor）を期待する。
        # proposal の source_signal_ids / source_evidence_refs から起点
        # run_id 群を機械導出して追加出力する（既存 6 field は不変・後方
        # 互換、追加のみ。冪等な register upsert で重複増殖しない）。
        append_adoption_entry(
          learning_root: learning_root,
          entry: {
            "proposal_id" => proposal["proposal_id"],
            "adopted_change_ref" => adopted_change_ref,
            "version_update_ref" => version_update_ref,
            "approval_ref" => approval_ref,
            "test_artifact_ref" => test_artifact_ref.to_s,
            "adopted_at" => adopted_at(proposal),
            "motivating_run_refs" => motivating_run_refs(proposal)
          }
        )
        { "adopted" => true, "reason" => nil, "status" => "adopted" }
      end

      # design §3 / Req4 受入 5: rejection を invisible discard でなく
      # preserved outcome として残す。state machine（→rejected の許可遷移元
      # = draft / tested / approved、終端不可逆）を尊重する。
      def reject(learning_root:, proposal:, rejection_reason:,
                 reviewer_note: nil)
        t = @proposals.transition(from: proposal["status"].to_s,
                                  to: "rejected")
        unless t["allowed"]
          return { "recorded" => false, "reason" => t["reason"],
                   "status" => proposal["status"] }
        end

        append_rejection_entry(
          learning_root: learning_root,
          entry: {
            "proposal_id" => proposal["proposal_id"],
            "rejection_reason" => rejection_reason,
            "rejected_at" => rejected_at(proposal),
            "reviewer_note" => reviewer_note
          }
        )
        { "recorded" => true, "reason" => nil, "status" => "rejected" }
      end

      # 完了条件（design Completion Criteria 第 3 項）: approval と adoption
      # の違いを説明できる。
      def approval_vs_adoption_distinction
        "Approval is a human accept/reject decision on a proposal (the " \
        "`tested` → `approved` transition); it records intent but does NOT " \
        "mean any repository change has landed. Adoption is the later " \
        "`approved` → `adopted` transition, allowed only when all three " \
        "conditions hold: (1) the proposal is approved, (2) a required test " \
        "artifact exists and is not untested, and (3) the repository change " \
        "is linked to a version update. Adoption is recorded in " \
        "approved-updates/adoption_register.json, which ties the proposal " \
        "to the concrete repo change, the version update, the approval, " \
        "and the test artifact (Decision 3: approval and adoption are " \
        "separate states)."
      end

      private

      # 波間結合 anchor。proposal から起点 run_id 群を機械導出する。
      # 優先 1: source_signal_ids（SignalExtraction の signal_id 形
      #   `runtime:<run_id>:<code>:<ref>` / `evaluation:<run_id>:<code>:<ref>`。
      #   aggregate は `<source>:aggregate:...` で run なし）。
      # 優先 2: source_evidence_refs に runtime run path
      #   （`experiments/runs/<run_id>/...`）が直接含まれる場合。
      # どちらからも導出できなければ空配列（rollback 側は marker なしと
      # 同じく steady state を保つ）。重複は除去し決定的順序にする。
      def motivating_run_refs(proposal)
        refs = []
        Array(proposal["source_signal_ids"]).each do |sid|
          parts = sid.to_s.split(":")
          next if parts.size < 2

          run_id = parts[1]
          next if run_id.nil? || run_id.empty? || run_id == "aggregate"

          refs << run_id
        end
        Array(proposal["source_evidence_refs"]).each do |ref|
          m = ref.to_s.match(%r{experiments/runs/([^/#]+)/})
          refs << m[1] if m
        end
        refs.uniq.sort
      end

      # required test artifact を解決する。明示 ref（learning_root 相対）を
      # 優先し、無ければ LearningLayout 正本パス backtests/<id>.json を見る。
      # 第5波 ReplayBacktestModel が書く artifact shape を前提とする。
      def resolve_test_artifact(learning_root:, proposal:, test_artifact_ref:)
        root = Pathname(learning_root)
        candidates = []
        candidates << (root + test_artifact_ref.to_s) unless
          blank?(test_artifact_ref)
        candidates << (root + @layout.backtest_artifact_path(
          proposal_id: proposal["proposal_id"]
        ))
        path = candidates.find(&:file?)
        return nil if path.nil?

        JSON.parse(path.read)
      rescue JSON::ParserError
        nil
      end

      def append_adoption_entry(learning_root:, entry:)
        upsert_register(
          learning_root: learning_root,
          relative_path: ADOPTION_REGISTER_PATH,
          entry: entry
        )
      end

      def append_rejection_entry(learning_root:, entry:)
        upsert_register(
          learning_root: learning_root,
          relative_path: REJECTION_REGISTER_PATH,
          entry: entry
        )
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

      def adopted_at(proposal)
        proposal["adopted_at"] || proposal["decided_at"] ||
          "1970-01-01T00:00:00Z"
      end

      def rejected_at(proposal)
        proposal["rejected_at"] || proposal["decided_at"] ||
          "1970-01-01T00:00:00Z"
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
