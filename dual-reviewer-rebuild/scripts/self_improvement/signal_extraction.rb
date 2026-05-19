#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "set"
require "pathname"
require_relative "learning_layout"
require_relative "input_model"

# Task 3: signal extraction model（自己改善所有・スクラッチ）
#
# 根拠: tasks.md Task 3、Requirement 1 受入 5（出所連鎖）、
#       design「Signal Extraction Model §1〜§4」「Proposal Normalization
#       Rules」「Project-Specific Pattern Extraction」「Findings Artifact
#       Required Fields」「v2 Supporting Inputs」。
#       適合レビュー 2026-05-19 finding 1/2/3 解消。
#
# スクラッチ方針: 旧 v1 signal extraction（2026-05-13・旧 fixture corpus
# 前提）は流用せず破棄。本モジュールは第1波 InputModel（runtime/evaluation
# signal の正本抽出器）と LearningLayout（findings/templates 正本パス・
# schema_version・mkpath 保証）を consumer として使い、次を行う:
#   - runtime 由来 signal を design §1 taxonomy へ分類
#   - evaluation 由来 signal を design §2 taxonomy へ分類
#   - findings/recurring_failure_signals.json /
#     findings/workflow_failure_signals.json を proposal 前 inventory として
#     required field 付きで作る（design §4）
#   - project-specific / meta-pattern candidate を区別して
#     findings/pattern_candidates.json に整理（design §3）
#   - 安定 invalid-run triage recurring failure mode を
#     templates/workflow_remediation_templates.json に派生（design §3）
#   - proposal normalization（同一 run の closely-coupled workflow failure
#     を 1 group、aggregate caveat は caveat code ごとに分離・design §2.5）
#   - proposal source_evidence_refs → findings → runtime/evaluation evidence
#     を機械的に辿れる（Requirement 1 受入 5）
#
# runtime_validation_summary.schema.json は runtime 所有・consumer 依存のみ
# で再定義しない。v2 supporting input は InputModel 側で補助扱いされ、本
# モジュールは読めなくても基本 flow を維持する（design §1.5）。
module DualReviewer
  module SelfImprovement
    class SignalExtraction
      # design §1 runtime-derived signal taxonomy。
      RUNTIME_SIGNAL_TYPES = %w[
        repeated_defer_clusters
        high_reject_concentration
        frequent_skip_marker_misuse
        repeated_invalidation_categories
        repeated_signal_linkage
      ].freeze

      # design §2 evaluation-derived signal taxonomy。
      EVALUATION_SIGNAL_TYPES = %w[
        treatment_specific_quality_drop
        phase_specific_caveat_concentration
        low_acceptance_ratio
        repeated_analysis_blocked
        repeated_comparison_ineligible
      ].freeze

      # InputModel signal_code → design §1/§2 signal_type。
      # 旧 v1 語彙でなく現行確定 InputModel が産出する signal_code に対応する。
      RUNTIME_TYPE_MAP = {
        # reviewer dissent（rejected/deferred）= review-quality 信号。
        # rejected は high_reject_concentration、deferred は
        # repeated_defer_clusters に寄せる（signal_value で再分類）。
        "human_decision_dissent" => "high_reject_concentration",
        # invalidation marker / validator failed = invalidation 系。
        "validator_failed" => "repeated_invalidation_categories",
        "invalidation_marker_issued" => "repeated_invalidation_categories",
        "failure_observation_recorded" => "repeated_invalidation_categories",
        # signal linkage to unresolved gap（analysis precondition gap）。
        "analysis_precondition_gap" => "repeated_signal_linkage"
      }.freeze

      EVALUATION_TYPE_MAP = {
        "rejected_finding_cluster" => "low_acceptance_ratio",
        "deferred_finding_cluster" => "low_acceptance_ratio",
        "unresolved_judgment_labels" => "low_acceptance_ratio",
        "caveat_observed" => "phase_specific_caveat_concentration",
        "analysis_blocked_population_member" => "repeated_analysis_blocked",
        "exploratory_population_member" => "repeated_comparison_ineligible"
      }.freeze

      # closely-coupled workflow failure signal（design §2.5）。同一 invalid
      # run で同時発生時 1 workflow proposal にまとめてよい signal_code。
      COUPLED_WORKFLOW_CODES = %w[
        validator_failed
        invalidation_marker_issued
        failure_observation_recorded
      ].freeze

      COUPLED_REMEDIATION_SURFACE =
        "invalid-run prevention / invalidation handling"

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @input = InputModel.new(repo_root: @repo_root)
        @layout = LearningLayout
      end

      def runtime_signal_types
        RUNTIME_SIGNAL_TYPES
      end

      def evaluation_signal_types
        EVALUATION_SIGNAL_TYPES
      end

      # runtime + evaluation signal を抽出し signal_type を付与、inventory
      # entry へ集約、proposal normalization を適用した結果を返す。
      def extract(run_roots:, analysis_root:)
        signals = collect_signals(run_roots: run_roots,
                                  analysis_root: analysis_root)
        inventory = build_inventory_entries(signals)
        groups = normalize_proposal_groups(signals)
        {
          signals: signals,
          inventory_entries: inventory,
          proposal_groups: groups
        }
      end

      # 第1波 LearningLayout の findings/・templates/ 正本パスへ書き出す
      # （mkpath 保証・schema_version 自動付与・冪等）。
      def write_inventory(learning_root:, run_roots:, analysis_root:)
        res = extract(run_roots: run_roots, analysis_root: analysis_root)
        recurring = res[:inventory_entries]
        workflow = recurring.select do |e|
          e["signal_class"] == "workflow_failure_signal"
        end
        candidates = build_pattern_candidates(res[:inventory_entries])
        templates = build_remediation_templates(res[:signals], candidates)

        @layout.write_artifact(
          learning_root: learning_root,
          relative_path: "findings/recurring_failure_signals.json",
          payload: { "entries" => recurring }
        )
        @layout.write_artifact(
          learning_root: learning_root,
          relative_path: "findings/workflow_failure_signals.json",
          payload: { "entries" => workflow }
        )
        @layout.write_artifact(
          learning_root: learning_root,
          relative_path: "findings/pattern_candidates.json",
          payload: { "entries" => candidates }
        )
        @layout.write_artifact(
          learning_root: learning_root,
          relative_path: "templates/workflow_remediation_templates.json",
          payload: { "entries" => templates }
        )
        res.merge(pattern_candidates: candidates, templates: templates)
      end

      # source_evidence_refs（findings signal_id 参照）→ findings entry →
      # runtime/evaluation evidence ref まで機械的に辿る（Req1 受入 5）。
      def trace_provenance(learning_root:, source_evidence_refs:)
        recurring = read_entries(
          Pathname(learning_root) +
            "findings/recurring_failure_signals.json"
        )
        index = recurring.each_with_object({}) do |e, acc|
          acc[e["signal_id"]] = e
        end
        findings_entries = []
        evidence_refs = []
        all_found = !Array(source_evidence_refs).empty?
        Array(source_evidence_refs).each do |ref|
          signal_id = ref.to_s.split("#", 2).last
          entry = index[signal_id]
          if entry.nil?
            all_found = false
            next
          end
          findings_entries << entry
          evidence_refs.concat(Array(entry["source_evidence_refs"]))
        end
        {
          findings_entries: findings_entries,
          evidence_refs: evidence_refs.uniq,
          fully_traceable: all_found && !evidence_refs.empty?
        }
      end

      private

      def collect_signals(run_roots:, analysis_root:)
        out = []
        Array(run_roots).each do |root|
          res = @input.load_runtime_signals(run_root: root)
          res["signals"].each do |s|
            out << annotate(s, classify_runtime(s))
          end
        end
        if analysis_root
          ev = @input.load_evaluation_signals(analysis_root: analysis_root)
          ev["signals"].each do |s|
            out << annotate(s, classify_evaluation(s))
          end
        end
        out
      end

      # signal_type を付与する。runtime baseline（dissent なし valid run の
      # run_review_quality_observed）は recurring failure 兆候でないため
      # signal_type を付けず inventory/normalization の対象外にする。
      def annotate(signal, signal_type)
        s = signal.dup
        s["signal_type"] = signal_type
        s
      end

      def classify_runtime(signal)
        code = signal["signal_code"]
        if code == "human_decision_dissent"
          v = signal["signal_value"] || {}
          if v["deferred_count"].to_i.positive? &&
             v["rejected_count"].to_i.zero?
            return "repeated_defer_clusters"
          end

          return "high_reject_concentration"
        end
        RUNTIME_TYPE_MAP[code]
      end

      def classify_evaluation(signal)
        EVALUATION_TYPE_MAP[signal["signal_code"]]
      end

      # design §4 required field: signal_id / signal_type /
      # source_evidence_refs / occurrence_count / first_seen_run_ref /
      # last_seen_run_ref / summary。signal_type 単位で複数 run を集約する。
      def build_inventory_entries(signals)
        typed = signals.reject { |s| s["signal_type"].nil? }
        grouped = typed.group_by { |s| s["signal_type"] }
        grouped.map do |signal_type, members|
          run_refs = members.map { |m| m["run_id"] }.compact
          evidence = members.flat_map { |m| Array(m["source_refs"]) }.uniq
          classes = members.map { |m| m["signal_class"] }.uniq
          {
            "signal_id" => "sig-#{signal_type}",
            "signal_type" => signal_type,
            "signal_class" => classes.size == 1 ? classes.first : "mixed",
            "signal_source" => members.first["signal_source"],
            "source_evidence_refs" => evidence,
            "occurrence_count" => members.size,
            "first_seen_run_ref" => run_refs.min,
            "last_seen_run_ref" => run_refs.max,
            "member_signal_ids" => members.map { |m| m["signal_id"] },
            "summary" =>
              "Recurring #{signal_type} observed across " \
              "#{run_refs.uniq.size} run(s)."
          }
        end
      end

      # design §2.5 proposal normalization。
      # - 同一 run の closely-coupled workflow failure signal は 1 group。
      # - aggregate caveat signal は caveat code ごとに別 group（過併合禁止）。
      # - それ以外は signal ごとに独立 group。
      def normalize_proposal_groups(signals)
        groups = []
        typed = signals.reject { |s| s["signal_type"].nil? }

        coupled = typed.select do |s|
          COUPLED_WORKFLOW_CODES.include?(s["signal_code"])
        end
        coupled.group_by { |s| s["run_id"] }.each do |run_id, members|
          groups << {
            "normalization_kind" => "coupled_workflow",
            "run_id" => run_id,
            "remediation_surface" => COUPLED_REMEDIATION_SURFACE,
            "member_signal_codes" =>
              members.map { |m| m["signal_code"] }.uniq,
            "member_signal_ids" => members.map { |m| m["signal_id"] },
            "source_evidence_refs" =>
              members.map { |m| inventory_ref(m) }.uniq
          }
        end

        caveats = typed.select { |s| s["signal_code"] == "caveat_observed" }
        caveats.group_by { |s| (s["signal_value"] || {})["caveat_code"] }
               .each do |caveat_code, members|
          groups << {
            "normalization_kind" => "aggregate_caveat",
            "caveat_code" => caveat_code,
            "member_signal_codes" =>
              members.map { |m| m["signal_code"] }.uniq,
            "member_signal_ids" => members.map { |m| m["signal_id"] },
            "source_evidence_refs" =>
              members.map { |m| inventory_ref(m) }.uniq
          }
        end

        handled = (coupled + caveats).map { |s| s["signal_id"] }.to_set
        typed.reject { |s| handled.include?(s["signal_id"]) }.each do |s|
          groups << {
            "normalization_kind" => "single_signal",
            "run_id" => s["run_id"],
            "member_signal_codes" => [s["signal_code"]],
            "member_signal_ids" => [s["signal_id"]],
            "source_evidence_refs" => [inventory_ref(s)]
          }
        end
        groups
      end

      # proposal source_evidence_refs は findings inventory の signal_id を
      # 指す（Req1 受入 5: proposal → findings → evidence の連鎖 anchor）。
      def inventory_ref(signal)
        st = signal["signal_type"]
        "findings/recurring_failure_signals.json#sig-#{st}"
      end

      # design §3: project-specific concrete と meta-pattern candidate を
      # 区別する。複数 run/source で再現する signal_type は meta-pattern
      # candidate、単一 run 局所のものは project-specific。
      def build_pattern_candidates(inventory_entries)
        inventory_entries.map do |e|
          run_span = [e["first_seen_run_ref"],
                      e["last_seen_run_ref"]].uniq.compact
          recurring = e["occurrence_count"].to_i > 1 || run_span.size > 1
          level = recurring ? "meta-pattern candidate" : "project-specific"
          {
            "candidate_id" => "pat-#{e['signal_type']}",
            "abstraction_level" => level,
            "source_signal_refs" => [e["signal_id"]],
            "summary" =>
              "#{level} derived from #{e['signal_type']} " \
              "(#{e['occurrence_count']} occurrence)."
          }
        end
      end

      # design §3 初版: invalid-run triage の recurring failure mode を
      # operator-facing checklist + recommended action 化する。
      # runtime_validation_summary.schema.json は runtime 所有のため
      # 再定義しない（payload を読むだけ）。
      def build_remediation_templates(signals, candidates)
        cand_by_type = candidates.each_with_object({}) do |c, acc|
          type = c["candidate_id"].sub(/\Apat-/, "")
          acc[type] = c
        end
        invalid_failures = signals.select do |s|
          s["signal_class"] == "workflow_failure_signal" &&
            s["evidence_maturity"] == "invalid"
        end
        invalid_failures.group_by { |s| s["signal_code"] }
                        .map do |failure_mode, members|
          sample = members.first
          v = sample["signal_value"] || {}
          type = sample["signal_type"]
          pat = cand_by_type[type]
          {
            "template_id" => "tmpl-#{failure_mode}",
            "failure_mode" => failure_mode,
            "checklist" => triage_checklist(failure_mode, v),
            "recommended_action" =>
              "Resolve #{failure_mode} before run close; re-run validator " \
              "and confirm invalidation handling.",
            "source_pattern_refs" =>
              [pat ? pat["candidate_id"] : "pat-#{type}"]
          }
        end
      end

      def triage_checklist(failure_mode, signal_value)
        base = [
          "Confirm primary_failure_code and failed check ids from " \
          "derived/invalid_run_triage_note.json.",
          "Verify invalidation marker linkage is complete.",
          "Re-run runtime validator after remediation."
        ]
        if failure_mode == "validator_failed"
          checks = Array(signal_value["failed_validator_check_ids"])
          unless checks.empty?
            base.unshift(
              "Address failed validator checks: #{checks.join(', ')}."
            )
          end
        end
        base
      end

      def read_entries(path)
        return [] unless path.file?

        JSON.parse(path.read).fetch("entries", [])
      rescue JSON::ParserError
        []
      end
    end
  end
end
