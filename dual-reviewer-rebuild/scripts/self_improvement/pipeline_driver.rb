#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "learning_layout"
require_relative "input_model"
require_relative "signal_extraction"
require_relative "proposal_model"
require_relative "replay_backtest_model"
require_relative "decision_adoption_model"
require_relative "rollback_model"

# 自己改善エントリ用 共有ドライバ（スクラッチ）。
#
# 根拠: tasks.md §C（自己改善エントリ script スクラッチ整合）、design
#       「Architecture」5 段（signal intake → proposal → test gate →
#       decision gate → history registry）。
#
# スクラッチ方針: 旧 v1 エントリ 10 件は第1波で git rm 済（評価外参照ゼロを
# grep -rl で確認済）。本ドライバは新モジュール公開 API のみを使い design
# 5 段を駆動する薄い結節点であり、runtime/evaluation 波で用いた共有 driver
# パターンを踏襲する。スキーマ・語彙は再定義せず（consumer 依存のみ）、
# raw run evidence / analysis は一切 mutate しない。出力は learning/ 正本
# 配置（LearningLayout）に限定する。
module DualReviewer
  module SelfImprovement
    class PipelineDriver
      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @layout = LearningLayout
        @extraction = SignalExtraction.new(repo_root: @repo_root)
        @proposals = ProposalModel.new(repo_root: @repo_root)
        @rbt = ReplayBacktestModel.new(repo_root: @repo_root)
        @decision = DecisionAdoptionModel.new(repo_root: @repo_root)
        @rollback = RollbackModel.new(repo_root: @repo_root)
      end

      # 段 0: learning/ 正本 skeleton（mkpath 保証・schema_version）。
      def ensure_layout(learning_root:)
        @layout.create_skeleton(learning_root: learning_root)
      end

      # 段 1: signal intake → signal extraction。findings/ ・templates/ を
      # 正本配置へ冪等書き出しする。
      def stage_signal_intake(learning_root:, run_roots:, analysis_root:)
        ensure_layout(learning_root: learning_root)
        @extraction.write_inventory(
          learning_root: learning_root,
          run_roots: run_roots, analysis_root: analysis_root
        )
      end

      # 段 2: proposal builder（1 group = 1 artifact、provenance gate /
      # paper narrative 分離を内包）。
      def stage_proposals(learning_root:, run_roots:, analysis_root:)
        @proposals.build_proposals(
          learning_root: learning_root,
          run_roots: run_roots, analysis_root: analysis_root
        )
      end

      # 段 3: replay / backtest gate（proposal ごとに 3 要素で mode 判定し
      # 結果 artifact を別 artifact として残す）。
      def stage_test_gate(learning_root:, proposals:, run_roots:,
                          analysis_root:)
        proposals.map do |p|
          mode = @rbt.decide_test_mode(proposal: p)["required_test_mode"]
          if mode == "backtest"
            @rbt.run_backtest(learning_root: learning_root, proposal: p,
                              analysis_root: analysis_root)
          else
            @rbt.run_replay(learning_root: learning_root, proposal: p,
                            search_roots: Array(run_roots))
          end
        end
      end

      # 段 4: decision gate。明示指示（adopt / reject）に従い register へ
      # 連結保存する。承認の代行はせず引数で渡された判断のみ記録する。
      def stage_decision(learning_root:, proposal:, action:,
                         adopted_change_ref: nil, version_update_ref: nil,
                         approval_ref: nil, test_artifact_ref: nil,
                         rejection_reason: nil, reviewer_note: nil)
        case action
        when "adopt"
          @decision.adopt(
            learning_root: learning_root,
            proposal: proposal.merge("status" => "approved"),
            adopted_change_ref: adopted_change_ref,
            version_update_ref: version_update_ref,
            approval_ref: approval_ref,
            test_artifact_ref: test_artifact_ref
          )
        when "reject"
          @decision.reject(
            learning_root: learning_root,
            proposal: proposal, rejection_reason: rejection_reason,
            reviewer_note: reviewer_note
          )
        else
          { "recorded" => false, "reason" => "unknown_action" }
        end
      end

      # 段 5: history registry の rollback / 事後 invalidate 起点 reassess。
      def stage_rollback_reassess(learning_root:, proposals:)
        @rollback.reassess_on_invalidation(
          learning_root: learning_root, proposals: proposals
        )
      end

      # design Architecture 5 段を通し pipeline 健全性を検証する（決定的
      # スモーク。fixture 仮装でなく実 runtime→evaluation 出力 fixture or
      # 与えられた入力で主経路が通り learning/ 正本配置が生成されること）。
      def validate_pipeline(learning_root:, run_roots:, analysis_root:)
        diagnostics = []
        intake = stage_signal_intake(
          learning_root: learning_root,
          run_roots: run_roots, analysis_root: analysis_root
        )
        signals = intake[:signals]
        if signals.empty?
          diagnostics << "no_signals_extracted"
        end
        classes = signals.map { |s| s["signal_class"] }.uniq
        unless classes.include?("review_quality_signal")
          diagnostics << "missing_review_quality_signal"
        end

        pres = stage_proposals(
          learning_root: learning_root,
          run_roots: run_roots, analysis_root: analysis_root
        )
        proposals = pres[:proposals]
        diagnostics << "no_proposals_generated" if proposals.empty?

        stage_test_gate(
          learning_root: learning_root, proposals: proposals,
          run_roots: run_roots, analysis_root: analysis_root
        )

        required = %w[
          findings/recurring_failure_signals.json
          findings/workflow_failure_signals.json
          findings/pattern_candidates.json
          proposals/proposal_index.json
          backtests/backtest_index.json
          templates/workflow_remediation_templates.json
          approved-updates/adoption_register.json
          rejected-updates/rejection_register.json
          rollback/rollback_register.json
        ]
        missing = required.reject do |rel|
          (Pathname(learning_root) + rel).file?
        end
        diagnostics << "missing_learning_artifacts:#{missing.join(',')}" unless
          missing.empty?

        {
          "ok" => diagnostics.empty?,
          "diagnostics" => diagnostics,
          "signal_classes" => classes,
          "proposal_count" => proposals.size
        }
      end
    end
  end
end
