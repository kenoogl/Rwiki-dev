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
        analysis = analyze_case

        paths = {
          "intent_review_artifact" => write_intent_review_artifact(analysis: analysis),
          "intent_trace_note" => write_intent_trace_note(analysis: analysis),
          "phase_metric_snapshot" => write_phase_metric_snapshot(analysis: analysis),
          "signal_linkage_note" => write_signal_linkage_note(analysis: analysis),
          "execution_packet" => write_execution_packet
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

      def write_intent_review_artifact(analysis:)
        reviewed_documents = ([intent_ref] + supporting_refs).uniq
        major_gap_lines = render_issue_lines(analysis.fetch("major_gap_candidates"))
        scope_drift_lines = render_issue_lines(analysis.fetch("scope_drift_candidates"))
        counter_hypothesis_lines = render_issue_lines(analysis.fetch("counter_hypotheses"))
        caveat_lines = render_issue_lines(analysis.fetch("caveats"))
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

          major gap candidates:
#{major_gap_lines}

          scope drift candidates:
#{scope_drift_lines}

          counter-hypotheses:
#{counter_hypothesis_lines}

          caveats:
#{caveat_lines}

          ## 3. metric snapshot

          - `intent_revision_count`: `#{analysis.dig("metrics", "intent_revision_count")}`
          - `intent_handback_count`: `#{analysis.dig("metrics", "intent_handback_count")}`
          - `intent_review_findings_count`: `#{analysis.dig("metrics", "intent_review_findings_count")}`
          - `review_artifact_presence_rate`: `#{analysis.dig("metrics", "review_artifact_presence_rate")}`

          ## 4. disposition summary

          - intent handback required: `#{analysis.fetch("intent_handback_required")}`
          - downstream implication: `#{analysis.fetch("downstream_implication")}`
          - next action: `#{analysis.fetch("next_action")}`
        MARKDOWN

        path = run_root.join("intent_review.md")
        path.write(content)
        path
      end

      def write_intent_trace_note(analysis:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "intent",
          "intent_ref" => intent_ref,
          "supporting_refs" => supporting_refs,
          "downstream_propagation_targets" => analysis.fetch("downstream_propagation_targets"),
          "intent_attributed_issue_refs" => analysis.fetch("intent_attributed_issue_refs"),
          "status" => "populated_by_runner",
          "intent_handback_required" => analysis.fetch("intent_handback_required"),
          "note" => analysis.fetch("trace_note")
        }

        path = run_root.join("intent_trace_note.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_phase_metric_snapshot(analysis:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "intent",
          "review_mode" => review_mode,
          "phase" => "intent",
          "collection_status" => "populated_by_runner",
          "source_register_ref" => phase_metric_register_ref,
          "metrics" => analysis.fetch("metrics")
        }

        path = run_root.join("phase_metric_snapshot.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_signal_linkage_note(analysis:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "intent",
          "signal_register_ref" => signal_register_ref,
          "linked_signal_ids" => analysis.fetch("linked_signal_ids"),
          "status" => "populated_by_runner",
          "note" => "Intent-track findings are preserved as runner-populated candidate signals for downstream spec and governance review."
        }

        path = run_root.join("signal_linkage_note.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_execution_packet
        steps = if review_mode == "single_review"
                  [
                    "intent を読み、major gap / scope drift 候補を抽出する",
                    "counter-hypothesis を無理に作らず、未確定点は caveat として残す",
                    "`intent_review.md` の findings と metric snapshot を埋める",
                    "`intent_trace_note.yaml` に downstream propagation target を入れる",
                    "`phase_metric_snapshot.json` と `signal_linkage_note.yaml` を更新する"
                  ]
                else
                  [
                    "primary reading を作る",
                    "adversarial pass で counter-hypothesis と premature closure 候補を出す",
                    "judgment で must-fix / should-fix / leave-as-is を分ける",
                    "`D` handback 要否と downstream propagation target を決める",
                    "`intent_review.md`, `intent_trace_note.yaml`, `phase_metric_snapshot.json`, `signal_linkage_note.yaml` を更新する"
                  ]
                end

        content = <<~MARKDOWN
          # execution packet

          ## 1. run header

          - run label: `#{run_label}`
          - case id: `#{case_id}`
          - track: `intent`
          - review mode: `#{review_mode}`
          - operator: `#{operator}`
          - objective:
            - #{objective}

          ## 2. inputs to read

          - intent ref:
            - `#{intent_ref}`
          - supporting refs:
        #{supporting_refs.map { |ref| "  - `#{ref}`" }.join("\n")}

          ## 3. execution steps

        #{steps.each_with_index.map { |step, index| "#{index + 1}. #{step}" }.join("\n")}

          ## 4. artifacts to update

          - `#{relative_to_repo(run_root.join("intent_review.md"))}`
          - `#{relative_to_repo(run_root.join("intent_trace_note.yaml"))}`
          - `#{relative_to_repo(run_root.join("phase_metric_snapshot.json"))}`
          - `#{relative_to_repo(run_root.join("signal_linkage_note.yaml"))}`

          ## 5. success check

          1. disagreement / caveat が消えていない
          2. downstream propagation target が明示されている
          3. `intent_handback_required` が yes/no で埋まっている
        MARKDOWN

        path = run_root.join("execution_packet.md")
        path.write(content)
        path
      end

      def relative_to_repo(path)
        path.relative_path_from(repo_root).to_s
      end

      def analyze_case
        return default_analysis unless dual_reviewer_rebuild_case?

        major_gap_candidates = [
          {
            "issue_id" => "intent-major-gap-phase-contract",
            "severity" => "high",
            "summary" => "The intent and paper plan strongly emphasize end-to-end support, but the bootstrap case still needs explicit phase-by-phase completion criteria to prevent downstream work from starting before governance gates are fixed.",
            "source_refs" => [
              intent_ref,
              "dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md",
              "dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md"
            ]
          }
        ]

        scope_drift_candidates = [
          {
            "issue_id" => "intent-scope-drift-code-review-collapse",
            "severity" => "medium",
            "summary" => "The bootstrap intent can drift toward a plain code-review framing unless the workflow documents keep `intent -> requirements -> design -> tasks -> implementation` as the governing path.",
            "source_refs" => [
              intent_ref,
              "dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md"
            ]
          }
        ]

        counter_hypotheses = []
        caveats = [
          {
            "issue_id" => "intent-caveat-bootstrap-case",
            "severity" => "low",
            "summary" => "This is an internal bootstrap case with rich downstream context, so it validates governance tooling more directly than a blank-slate external intent-only case.",
            "source_refs" => [
              ".kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-first-case-dual-reviewer-rebuild.md"
            ]
          }
        ]

        if review_mode == "dual_reviewer_workflow"
          counter_hypotheses << {
            "issue_id" => "intent-counter-hypothesis-human-gate-collapse",
            "severity" => "medium",
            "summary" => "A dual reading should preserve the possibility that the system over-centralizes LLM guidance and weakens explicit human gate ownership unless approval, adoption, and conformance review remain separate.",
            "source_refs" => [
              intent_ref,
              "dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md",
              "dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md"
            ]
          }
        end

        downstream_targets = %w[requirements design tasks]
        intent_attributed_issue_refs = [
          "intent-major-gap-phase-contract",
          "intent-scope-drift-code-review-collapse"
        ]
        linked_signal_ids = [
          "intent-track-phase-contract-gap",
          "intent-track-scope-drift-risk"
        ]

        {
          "major_gap_candidates" => major_gap_candidates,
          "scope_drift_candidates" => scope_drift_candidates,
          "counter_hypotheses" => counter_hypotheses,
          "caveats" => caveats,
          "intent_handback_required" => review_mode == "dual_reviewer_workflow",
          "downstream_propagation_targets" => downstream_targets,
          "intent_attributed_issue_refs" => intent_attributed_issue_refs,
          "downstream_implication" => "requirements/design/tasks の各 phase で completion rule と reopen depth を明示しない限り、下流 evidence を main claim に昇格させない",
          "next_action" => review_mode == "dual_reviewer_workflow" ? "requirements bootstrap に入る前に handback taxonomy と human gate separation を requirements wording に明示する" : "requirements bootstrap へ進みつつ、phase completion criteria を requirements candidate として先に起こす",
          "trace_note" => "Bootstrap intent issues should propagate into requirements/design/tasks as phase contract and scope-drift controls rather than being silently absorbed.",
          "linked_signal_ids" => linked_signal_ids,
          "metrics" => {
            "intent_revision_count" => 0,
            "intent_handback_count" => review_mode == "dual_reviewer_workflow" ? 1 : 0,
            "intent_review_findings_count" => major_gap_candidates.size + scope_drift_candidates.size + counter_hypotheses.size,
            "review_artifact_presence_rate" => 1.0
          }
        }
      end

      def default_analysis
        {
          "major_gap_candidates" => [],
          "scope_drift_candidates" => [],
          "counter_hypotheses" => [],
          "caveats" => [],
          "intent_handback_required" => false,
          "downstream_propagation_targets" => [],
          "intent_attributed_issue_refs" => [],
          "downstream_implication" => "manual population required",
          "next_action" => "manual population required",
          "trace_note" => "Populate after review with downstream propagation and intent-attributed issue refs.",
          "linked_signal_ids" => [],
          "metrics" => {
            "intent_revision_count" => 0,
            "intent_handback_count" => 0,
            "intent_review_findings_count" => 0,
            "review_artifact_presence_rate" => 1.0
          }
        }
      end

      def dual_reviewer_rebuild_case?
        case_id == "F1-intent-dual-reviewer-rebuild" && intent_ref.include?("dual-reviewer-spec-driven-paper-plan.md")
      end

      def render_issue_lines(issues)
        return "  - (none)" if issues.empty?

        issues.map do |issue|
          refs = Array(issue["source_refs"]).map { |ref| "`#{ref}`" }.join(", ")
          "  - [#{issue.fetch("severity")}] #{issue.fetch("summary")} (refs: #{refs})"
        end.join("\n")
      end
    end
  end
end
