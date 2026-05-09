#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "time"
require "yaml"

module DualReviewer
  module TrackRuns
    class IntentTrackWriter
      attr_reader :repo_root, :run_label, :case_id, :review_mode, :intent_ref, :supporting_refs,
                  :operator, :objective, :output_root

      def initialize(repo_root:, run_label:, case_id:, review_mode:, intent_ref:, supporting_refs:,
                     operator:, objective:, output_root: nil)
        @repo_root = Pathname(repo_root).expand_path
        @run_label = run_label
        @case_id = case_id
        @review_mode = review_mode
        @intent_ref = intent_ref
        @supporting_refs = supporting_refs
        @operator = operator
        @objective = objective
        @output_root = output_root ? Pathname(output_root).expand_path : default_output_root
      end

      def write_all
        FileUtils.mkdir_p(run_root)

        paths = {
          "intent_review_artifact" => write_intent_review_artifact,
          "intent_trace_note" => write_intent_trace_note,
          "phase_metric_snapshot" => write_phase_metric_snapshot,
          "signal_linkage_note" => write_signal_linkage_note
        }
        paths["run_manifest"] = write_run_manifest(paths: paths)
        paths
      end

      private

      def default_output_root
        repo_root.join("experiments/protocols/intent-track-runs")
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

      def intent_review_template_ref
        "docs/reviews/templates/intent-review-template.md"
      end

      def write_run_manifest(paths:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "intent",
          "review_mode" => review_mode,
          "operator" => operator,
          "generated_at" => Time.now.utc.iso8601,
          "objective" => objective,
          "inputs" => {
            "intent_ref" => intent_ref,
            "supporting_refs" => supporting_refs
          },
          "references" => {
            "workflow_gate_status_ref" => workflow_gate_status_ref,
            "phase_metric_register_ref" => phase_metric_register_ref,
            "intent_review_template_ref" => intent_review_template_ref
          },
          "outputs" => paths.transform_values { |path| relative_to_repo(path) }
        }

        path = run_root.join("run_manifest.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_intent_review_artifact
        reviewed_documents = ([intent_ref] + supporting_refs).uniq
        content = <<~MARKDOWN
          # intent review

          ## 1. review scope

          - review type: `intent review`
          - run label: `#{run_label}`
          - case id: `#{case_id}`
          - review mode: `#{review_mode}`
          - operator: `#{operator}`
          - reviewed intent documents:
        #{reviewed_documents.map { |ref| "  - `#{ref}`" }.join("\n")}
          - reviewed traceability documents:
            - `docs/traceability/intent-to-requirements-trace-matrix.md`
          - review focus:
            - #{objective}

          ## 2. findings

          <!-- Populate findings after the run. Preserve disagreement and caveat instead of silently collapsing them. -->

          ## 3. metric snapshot

          - `intent_revision_count`:
          - `intent_handback_count`:
          - `intent_review_findings_count`:
          - `review_artifact_presence_rate`:

          ## 4. disposition summary

          - immediate disposition:
          - downstream implication:
          - next action:
        MARKDOWN

        path = run_root.join("intent_review.md")
        path.write(content)
        path
      end

      def write_intent_trace_note
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "intent",
          "intent_ref" => intent_ref,
          "supporting_refs" => supporting_refs,
          "downstream_propagation_targets" => [],
          "intent_attributed_issue_refs" => [],
          "status" => "pending_manual_population",
          "note" => "Populate after review with downstream propagation and intent-attributed issue refs."
        }

        path = run_root.join("intent_trace_note.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_phase_metric_snapshot
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "intent",
          "review_mode" => review_mode,
          "phase" => "intent",
          "collection_status" => "pending_manual_population",
          "source_register_ref" => phase_metric_register_ref,
          "metrics" => {
            "intent_revision_count" => nil,
            "intent_handback_count" => nil,
            "intent_review_findings_count" => nil,
            "review_artifact_presence_rate" => 1.0
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
          "track" => "intent",
          "signal_register_ref" => signal_register_ref,
          "linked_signal_ids" => [],
          "status" => "pending_manual_population",
          "note" => "Populate when intent-track findings are linked into the implementation signal register or equivalent downstream signal record."
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
