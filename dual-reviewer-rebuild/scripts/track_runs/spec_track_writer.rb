#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "time"
require "yaml"

module DualReviewer
  module TrackRuns
    class SpecTrackWriter
      attr_reader :repo_root, :run_label, :case_id, :review_mode, :reviewed_phase,
                  :reviewed_phase_ref, :adjacent_phase_refs, :alignment_refs, :operator,
                  :output_root

      def initialize(repo_root:, run_label:, case_id:, review_mode:, reviewed_phase:, reviewed_phase_ref:,
                     adjacent_phase_refs:, alignment_refs:, operator:, output_root: nil)
        @repo_root = Pathname(repo_root).expand_path
        @run_label = run_label
        @case_id = case_id
        @review_mode = review_mode
        @reviewed_phase = reviewed_phase
        @reviewed_phase_ref = reviewed_phase_ref
        @adjacent_phase_refs = adjacent_phase_refs
        @alignment_refs = alignment_refs
        @operator = operator
        @output_root = output_root ? Pathname(output_root).expand_path : default_output_root
      end

      def write_all
        FileUtils.mkdir_p(run_root)

        paths = {
          "reviewed_phase_note" => write_reviewed_phase_note,
          "alignment_artifact" => write_alignment_artifact,
          "phase_metric_snapshot" => write_phase_metric_snapshot,
          "signal_linkage_note" => write_signal_linkage_note
        }
        paths["run_manifest"] = write_run_manifest(paths: paths)
        paths
      end

      private

      def default_output_root
        repo_root.join("experiments/protocols/spec-track-runs")
      end

      def run_root
        output_root.join(sanitize(run_label))
      end

      def sanitize(value)
        value.gsub(/[^a-zA-Z0-9._-]+/, "-")
      end

      def workflow_gate_status_ref
        "docs/coordination/workflow-gate-status.md"
      end

      def signal_register_ref
        "docs/coordination/implementation-signal-register.md"
      end

      def phase_metric_register_ref
        "docs/coordination/phase-review-metric-register.md"
      end

      def write_run_manifest(paths:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "spec",
          "review_mode" => review_mode,
          "reviewed_phase" => reviewed_phase,
          "operator" => operator,
          "generated_at" => Time.now.utc.iso8601,
          "inputs" => {
            "reviewed_phase_ref" => reviewed_phase_ref,
            "adjacent_phase_refs" => adjacent_phase_refs,
            "alignment_refs" => alignment_refs
          },
          "references" => {
            "workflow_gate_status_ref" => workflow_gate_status_ref,
            "phase_metric_register_ref" => phase_metric_register_ref
          },
          "outputs" => paths.transform_values { |path| relative_to_repo(path) }
        }

        path = run_root.join("run_manifest.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_reviewed_phase_note
        content = <<~MARKDOWN
          # reviewed phase note

          ## 1. run scope

          - run label: `#{run_label}`
          - case id: `#{case_id}`
          - track: `spec`
          - review mode: `#{review_mode}`
          - reviewed phase: `#{reviewed_phase}`
          - operator: `#{operator}`
          - reviewed phase ref:
            - `#{reviewed_phase_ref}`
          - adjacent phase refs:
        #{adjacent_phase_refs.map { |ref| "  - `#{ref}`" }.join("\n")}

          ## 2. phase findings

          <!-- Populate phase-local findings, cross-phase inconsistencies, and caveats after the run. -->

          ## 3. reopen assessment

          - reopen required:
          - target reopen phases:
          - intent-attributed issues:

          ## 4. next action

          - next action:
        MARKDOWN

        path = run_root.join("reviewed_phase_note.md")
        path.write(content)
        path
      end

      def write_alignment_artifact
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "spec",
          "reviewed_phase" => reviewed_phase,
          "alignment_refs" => alignment_refs,
          "propagation_targets" => [],
          "reopen_required" => nil,
          "status" => "pending_manual_population",
          "note" => "Populate with alignment findings, reopen targets, and propagation decisions after the run."
        }

        path = run_root.join("alignment_artifact.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_phase_metric_snapshot
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "spec",
          "review_mode" => review_mode,
          "reviewed_phase" => reviewed_phase,
          "collection_status" => "pending_manual_population",
          "source_register_ref" => phase_metric_register_ref,
          "metrics" => {
            "phase_blocking_issue_count" => nil,
            "phase_nonblocking_open_point_count" => nil,
            "phase_recheck_count" => nil,
            "phase_handback_count_by_class" => { "A" => 0, "B" => 0, "C" => 0, "D" => 0 },
            "phase_reopen_required_count" => nil,
            "phase_minor_adjustment_count" => nil,
            "phase_major_correction_count" => nil,
            "phase_intent_attributed_issue_count" => nil
          }
        }

        path = run_root.join("phase_metric_snapshot.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_signal_linkage_note
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "spec",
          "reviewed_phase" => reviewed_phase,
          "signal_register_ref" => signal_register_ref,
          "linked_signal_ids" => [],
          "status" => "pending_manual_population",
          "note" => "Populate when spec-track findings are linked into the implementation signal register or equivalent downstream signal record."
        }

        path = run_root.join("signal_linkage_note.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def relative_to_repo(path)
        path.relative_path_from(repo_root).to_s
      end
    end
  end
end
