# frozen_string_literal: true

require "json"
require "pathname"
require_relative "runtime_session_driver"

# Task 11 / B: implementation track runner（新 controller API 整合・スクラッチ）
# 根拠: tasks.md Task 2「Generic Protocol Entrypoint Rule」、design「File
#       Placement for v2 Runtime Core」（scripts/track_runs/ は runtime 所有
#       adapter）。旧 v1 実装（dangling controller API + 撤廃済み heuristic
#       profile 参照）はスクラッチ方針で置換。旧ロジックは流用しない。
#
# Generic Protocol Entrypoint Rule:
#   - case_manifest_ref あり → controller が manifest を読む
#   - なし → track 別必須入力（case_id / implementation_snapshot_ref /
#            phase_profile / target_id / upstream_spec_refs）を明示必須
#   - どちらも無し → controller が fail fast
module DualReviewer
  module TrackRuns
    class ImplementationTrackRunner
      def initialize(repo_root:, run_label:, review_mode:, operator:,
                     case_id: nil, implementation_snapshot_ref: nil,
                     upstream_spec_refs: [], governance_refs: [],
                     phase_profile: nil, target_id: nil,
                     case_manifest_ref: nil, runtime_run_root_base: nil,
                     **_ignored)
        @repo_root = Pathname(repo_root).expand_path
        @run_label = run_label
        @review_mode = review_mode
        @operator = operator
        @case_id = case_id
        @implementation_snapshot_ref = implementation_snapshot_ref
        @upstream_spec_refs = Array(upstream_spec_refs)
        @governance_refs = Array(governance_refs)
        @phase_profile = phase_profile
        @target_id = target_id
        @case_manifest_ref = case_manifest_ref
        @run_root_base =
          if runtime_run_root_base
            Pathname(runtime_run_root_base).expand_path
          else
            @repo_root + "experiments/runs"
          end
      end

      def run_all
        driver = RuntimeSessionDriver.new(
          repo_root: @repo_root, run_root_base: @run_root_base
        )
        source_refs =
          ([@implementation_snapshot_ref] + @upstream_spec_refs).compact
        result = driver.run_session(
          target_id: @target_id || @case_id,
          phase_profile: @phase_profile || "tasks",
          review_mode: @review_mode,
          operator: @operator,
          source_refs: source_refs.empty? ? nil : source_refs,
          track: @case_manifest_ref ? nil : "implementation",
          case_manifest_ref: @case_manifest_ref
        )
        {
          "run_id" => result.fetch("run_id"),
          "run_status" => result.fetch("run_status"),
          "treatment" => result.fetch("treatment"),
          "runtime_paths" => result.fetch("runtime_paths")
        }
      end
    end
  end
end
