# frozen_string_literal: true

require "json"
require "pathname"
require_relative "runtime_session_driver"

# Task 11 / B: spec track writer（新 controller API 整合・スクラッチ）
# 根拠: tasks.md Task 2「Generic Protocol Entrypoint Rule」、design「File
#       Placement for v2 Runtime Core」。旧 v1（dangling controller API +
#       撤廃済み heuristic profile）はスクラッチ方針で置換。流用しない。
#
# Generic Protocol Entrypoint Rule:
#   - case_manifest_ref あり → controller が manifest を読む
#   - なし → track 別必須入力（case_id / reviewed_phase /
#            reviewed_phase_ref）を明示必須
#   - どちらも無し → controller が fail fast
#
# reviewed_phase は runtime phase_profile 軸（intent/requirements/design/
# tasks）にそのまま対応する。treatment 軸とは独立（Requirement 8 受入 5）。
module DualReviewer
  module TrackRuns
    class SpecTrackWriter
      def initialize(repo_root:, run_label:, review_mode:, operator:,
                     case_id: nil, reviewed_phase: nil,
                     reviewed_phase_ref: nil, adjacent_phase_refs: [],
                     alignment_refs: [], case_manifest_ref: nil,
                     runtime_run_root_base: nil, **_ignored)
        @repo_root = Pathname(repo_root).expand_path
        @run_label = run_label
        @review_mode = review_mode
        @operator = operator
        @case_id = case_id
        @reviewed_phase = reviewed_phase
        @reviewed_phase_ref = reviewed_phase_ref
        @adjacent_phase_refs = Array(adjacent_phase_refs)
        @alignment_refs = Array(alignment_refs)
        @case_manifest_ref = case_manifest_ref
        @run_root_base =
          if runtime_run_root_base
            Pathname(runtime_run_root_base).expand_path
          else
            @repo_root + "experiments/runs"
          end
      end

      def write_all
        driver = RuntimeSessionDriver.new(
          repo_root: @repo_root, run_root_base: @run_root_base
        )
        source_refs =
          ([@reviewed_phase_ref] + @adjacent_phase_refs +
           @alignment_refs).compact
        result = driver.run_session(
          target_id: @case_id || @reviewed_phase_ref,
          phase_profile: @reviewed_phase || "design",
          review_mode: @review_mode,
          operator: @operator,
          source_refs: source_refs.empty? ? nil : source_refs,
          track: @case_manifest_ref ? nil : "spec",
          case_manifest_ref: @case_manifest_ref
        )
        paths = result.fetch("runtime_paths").transform_values do |p|
          Pathname(p)
        end
        paths.merge(
          "run_id" => result.fetch("run_id"),
          "run_status" => result.fetch("run_status")
        )
      end
    end
  end
end
