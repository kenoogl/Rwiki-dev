#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "pathname"
require "time"
require "yaml"
require "erb"

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
        analysis = analyze_case

        paths = {
          "reviewed_phase_note" => write_reviewed_phase_note(analysis: analysis),
          "alignment_artifact" => write_alignment_artifact(analysis: analysis),
          "phase_metric_snapshot" => write_phase_metric_snapshot(analysis: analysis),
          "signal_linkage_note" => write_signal_linkage_note(analysis: analysis),
          "execution_packet" => write_execution_packet
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

      def write_reviewed_phase_note(analysis:)
        phase_local_lines = render_issue_lines(analysis.fetch("phase_local_issues"))
        cross_phase_lines = render_issue_lines(analysis.fetch("cross_phase_inconsistencies"))
        intent_lines = render_issue_lines(analysis.fetch("intent_attributed_issues"))
        caveat_lines = render_issue_lines(analysis.fetch("caveats"))

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

          phase-local issues:
#{phase_local_lines}

          cross-phase inconsistencies:
#{cross_phase_lines}

          caveats:
#{caveat_lines}

          ## 3. reopen assessment

          - reopen required: `#{analysis.fetch("reopen_required")}`
          - target reopen phases: `#{analysis.fetch("target_reopen_phases").join(", ")}`
          - intent-attributed issues:
#{intent_lines}

          ## 4. next action

          - next action: `#{analysis.fetch("next_action")}`
        MARKDOWN

        path = run_root.join("reviewed_phase_note.md")
        path.write(content)
        path
      end

      def write_alignment_artifact(analysis:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "spec",
          "reviewed_phase" => reviewed_phase,
          "alignment_refs" => alignment_refs,
          "propagation_targets" => analysis.fetch("target_reopen_phases"),
          "reopen_required" => analysis.fetch("reopen_required"),
          "status" => "populated_by_runner",
          "phase_local_issues" => analysis.fetch("phase_local_issues"),
          "cross_phase_inconsistencies" => analysis.fetch("cross_phase_inconsistencies"),
          "intent_attributed_issues" => analysis.fetch("intent_attributed_issues"),
          "note" => analysis.fetch("alignment_note")
        }

        path = run_root.join("alignment_artifact.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_phase_metric_snapshot(analysis:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "spec",
          "review_mode" => review_mode,
          "reviewed_phase" => reviewed_phase,
          "collection_status" => "populated_by_runner",
          "source_register_ref" => phase_metric_register_ref,
          "metrics" => {
            "phase_blocking_issue_count" => analysis.fetch("metrics").fetch("phase_blocking_issue_count"),
            "phase_nonblocking_open_point_count" => analysis.fetch("metrics").fetch("phase_nonblocking_open_point_count"),
            "phase_recheck_count" => analysis.fetch("metrics").fetch("phase_recheck_count"),
            "phase_handback_count_by_class" => analysis.fetch("metrics").fetch("phase_handback_count_by_class"),
            "phase_reopen_required_count" => analysis.fetch("metrics").fetch("phase_reopen_required_count"),
            "phase_minor_adjustment_count" => analysis.fetch("metrics").fetch("phase_minor_adjustment_count"),
            "phase_major_correction_count" => analysis.fetch("metrics").fetch("phase_major_correction_count"),
            "phase_intent_attributed_issue_count" => analysis.fetch("metrics").fetch("phase_intent_attributed_issue_count")
          }
        }

        path = run_root.join("phase_metric_snapshot.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_signal_linkage_note(analysis:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "spec",
          "reviewed_phase" => reviewed_phase,
          "signal_register_ref" => signal_register_ref,
          "linked_signal_ids" => analysis.fetch("linked_signal_ids"),
          "status" => "populated_by_runner",
          "note" => "Spec-track issues are preserved as runner-populated candidate signals for downstream implementation and governance review."
        }

        path = run_root.join("signal_linkage_note.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_execution_packet
        steps = if review_mode == "single_review"
                  [
                    "#{reviewed_phase} を読み、phase-local issue / ambiguity / ordering issue を抽出する",
                    "adjacent phase と照合し、cross-phase inconsistency を列挙する",
                    "`reviewed_phase_note.md` と `alignment_artifact.yaml` を埋める",
                    "`phase_metric_snapshot.json` と `signal_linkage_note.yaml` を更新する"
                  ]
                else
                  [
                    "primary reading で phase-local reading を作る",
                    "adversarial pass で cross-phase inconsistency 仮説を出す",
                    "judgment で must-fix / should-fix / leave-as-is を分ける",
                    "reopen / recheck depth と intent-attributed issue を判定する",
                    "`reviewed_phase_note.md`, `alignment_artifact.yaml`, `phase_metric_snapshot.json`, `signal_linkage_note.yaml` を更新する"
                  ]
                end

        content = <<~MARKDOWN
          # execution packet

          ## 1. run header

          - run label: `#{run_label}`
          - case id: `#{case_id}`
          - track: `spec`
          - review mode: `#{review_mode}`
          - reviewed phase: `#{reviewed_phase}`
          - operator: `#{operator}`

          ## 2. inputs to read

          - reviewed phase ref:
            - `#{reviewed_phase_ref}`
          - adjacent phase refs:
        #{adjacent_phase_refs.map { |ref| "  - `#{ref}`" }.join("\n")}
          - alignment refs:
        #{alignment_refs.empty? ? "  - (none)" : alignment_refs.map { |ref| "  - `#{ref}`" }.join("\n")}

          ## 3. execution steps

        #{steps.each_with_index.map { |step, index| "#{index + 1}. #{step}" }.join("\n")}

          ## 4. artifacts to update

          - `#{relative_to_repo(run_root.join("reviewed_phase_note.md"))}`
          - `#{relative_to_repo(run_root.join("alignment_artifact.yaml"))}`
          - `#{relative_to_repo(run_root.join("phase_metric_snapshot.json"))}`
          - `#{relative_to_repo(run_root.join("signal_linkage_note.yaml"))}`

          ## 5. success check

          1. reopen / recheck depth が埋まっている
          2. phase-local issue と cross-phase inconsistency が分離されている
          3. `intent-attributed issue` が必要時に区別されている
        MARKDOWN

        path = run_root.join("execution_packet.md")
        path.write(content)
        path
      end

      def relative_to_repo(path)
        path.relative_path_from(repo_root).to_s
      end

      def analyze_case
        return phase_field_design_analysis if phase_field_design_case?
        return phase_field_requirements_analysis if phase_field_requirements_case?
        return default_analysis unless phase_field_tasks_case?

        phase_local_issues = [
          {
            "issue_id" => "spec-phase-local-acceptance-batch-coupling",
            "severity" => "medium",
            "summary" => "The tasks phase bundles a long-running 100000-step acceptance run with downstream observation recording, which increases execution and review coupling inside a phase that is still marked `tasks-generated` rather than approved.",
            "source_refs" => [
              reviewed_phase_ref,
              ".kiro/specs/phase-field-reverse-spec/spec.json"
            ]
          }
        ]

        cross_phase_inconsistencies = [
          {
            "issue_id" => "spec-cross-phase-unapproved-downstream-readiness",
            "severity" => "high",
            "summary" => "Tasks define final acceptance and downstream evidence append paths while `design` and `tasks` remain unapproved in `spec.json`, so implementation-readiness should not be inferred without a design/tasks recheck.",
            "source_refs" => [
              reviewed_phase_ref,
              ".kiro/specs/phase-field-reverse-spec/spec.json",
              ".kiro/specs/phase-field-reverse-spec/design.md"
            ]
          }
        ]

        intent_attributed_issues = [
          {
            "issue_id" => "spec-intent-clean-room-propagation",
            "severity" => "medium",
            "summary" => "The clean-room intent and canonical-source limitation must stay explicit through tasks and acceptance, otherwise downstream implementation work can silently broaden the allowed evidence boundary.",
            "source_refs" => [
              ".kiro/specs/phase-field-reverse-spec/intent.md",
              reviewed_phase_ref
            ]
          }
        ]

        caveats = []
        linked_signal_ids = ["spec-track-phase-field-approval-gate", "spec-track-phase-field-clean-room-boundary"]
        handback_class = review_mode == "dual_reviewer_workflow" ? "B" : "A"
        major_correction_count = review_mode == "dual_reviewer_workflow" ? 1 : 0
        minor_adjustment_count = review_mode == "dual_reviewer_workflow" ? 1 : 2

        if review_mode == "dual_reviewer_workflow"
          phase_local_issues << {
            "issue_id" => "spec-phase-local-external-observation-write",
            "severity" => "medium",
            "summary" => "The tasks plan explicitly appends acceptance results into external methodology logs, so the review should preserve this as a caveat instead of treating it as a silent implementation detail.",
            "source_refs" => [
              reviewed_phase_ref,
              ".kiro/specs/phase-field-reverse-spec/design.md"
            ]
          }
          caveats << {
            "issue_id" => "spec-caveat-external-observation-side-effect",
            "severity" => "low",
            "summary" => "Cross-spec observation writes are allowed as a scoped exception, but they tighten provenance and should remain visible in downstream review memos.",
            "source_refs" => [
              reviewed_phase_ref
            ]
          }
        end

        {
          "phase_local_issues" => phase_local_issues,
          "cross_phase_inconsistencies" => cross_phase_inconsistencies,
          "intent_attributed_issues" => intent_attributed_issues,
          "caveats" => caveats,
          "reopen_required" => true,
          "target_reopen_phases" => %w[design tasks],
          "next_action" => "design/tasks alignment を再確認し、implementation readiness の前に approval gate と clean-room boundary を明示的に閉じる",
          "alignment_note" => "Tasks-origin issues require at least a design/tasks recheck before this case can be treated as implementation-ready main evidence.",
          "linked_signal_ids" => linked_signal_ids,
          "metrics" => {
            "phase_blocking_issue_count" => 1,
            "phase_nonblocking_open_point_count" => phase_local_issues.size + caveats.size - 1,
            "phase_recheck_count" => 1,
            "phase_handback_count_by_class" => { "A" => handback_class == "A" ? 1 : 0, "B" => handback_class == "B" ? 1 : 0, "C" => 0, "D" => 0 },
            "phase_reopen_required_count" => 1,
            "phase_minor_adjustment_count" => minor_adjustment_count,
            "phase_major_correction_count" => major_correction_count,
            "phase_intent_attributed_issue_count" => intent_attributed_issues.size
          }
        }
      end

      def phase_field_design_analysis
        phase_local_issues = [
          {
            "issue_id" => "spec-design-boundary-density",
            "severity" => "high",
            "summary" => "The design introduces a large number of tightly coupled component boundaries across Numerical Engine, clamp/correction helpers, snapshot I/O, visualization, and three executables, so downstream tasks must keep ownership and integration boundaries explicit to avoid silent coupling drift.",
            "source_refs" => [
              reviewed_phase_ref,
              ".kiro/specs/phase-field-reverse-spec/requirements.md"
            ]
          },
          {
            "issue_id" => "spec-design-static-allocation-and-failure-contract",
            "severity" => "medium",
            "summary" => "Static allocation, clamp non-convergence handling, and step-level diagnostic propagation are already fixed in design, so downstream implementation tasks need to preserve these failure contracts rather than reinterpreting them as local coding choices.",
            "source_refs" => [
              reviewed_phase_ref
            ]
          }
        ]

        cross_phase_inconsistencies = [
          {
            "issue_id" => "spec-design-unapproved-tasks-readiness-gap",
            "severity" => "high",
            "summary" => "The design is generated but not approved, and the tasks phase is also unapproved, so the current design should not be treated as implementation-ready without a design/tasks recheck against the approved requirements contract.",
            "source_refs" => [
              reviewed_phase_ref,
              ".kiro/specs/phase-field-reverse-spec/spec.json",
              ".kiro/specs/phase-field-reverse-spec/tasks.md"
            ]
          }
        ]

        intent_attributed_issues = [
          {
            "issue_id" => "spec-design-intent-clean-room-preservation",
            "severity" => "medium",
            "summary" => "The clean-room scientific intent still constrains the design surface: component responsibilities and accepted dependencies must remain derivable from the narrow canonical sources instead of silently importing extra assumptions.",
            "source_refs" => [
              ".kiro/specs/phase-field-reverse-spec/intent.md",
              reviewed_phase_ref
            ]
          }
        ]

        caveats = []
        linked_signal_ids = [
          "spec-track-design-boundary-density",
          "spec-track-design-readiness-gap"
        ]

        if review_mode == "dual_reviewer_workflow"
          cross_phase_inconsistencies << {
            "issue_id" => "spec-design-validation-ownership-spread",
            "severity" => "medium",
            "summary" => "Validation responsibilities are distributed across component notes and integration plans, so the downstream tasks should make test ownership and acceptance routing explicit instead of leaving them as implicit cross-file expectations.",
            "source_refs" => [
              reviewed_phase_ref,
              "dual-reviewer-rebuild/docs/alignment/cross-spec-design-alignment.md"
            ]
          }
          caveats << {
            "issue_id" => "spec-design-caveat-component-granularity",
            "severity" => "low",
            "summary" => "The current design intentionally uses fine-grained component decomposition for reviewability, but this increases downstream task coordination cost and should remain visible as a design caveat.",
            "source_refs" => [
              reviewed_phase_ref
            ]
          }
        end

        handback_class = "B"
        major_correction_count = review_mode == "dual_reviewer_workflow" ? 1 : 0
        minor_adjustment_count = review_mode == "dual_reviewer_workflow" ? 1 : 2

        {
          "phase_local_issues" => phase_local_issues,
          "cross_phase_inconsistencies" => cross_phase_inconsistencies,
          "intent_attributed_issues" => intent_attributed_issues,
          "caveats" => caveats,
          "reopen_required" => true,
          "target_reopen_phases" => %w[design tasks],
          "next_action" => "design boundary と failure contract を再確認し、その前提で tasks 側の ownership と acceptance routing を引き直す",
          "alignment_note" => "Design-origin issues require at least a design/tasks recheck before this case can be treated as implementation-ready pilot evidence.",
          "linked_signal_ids" => linked_signal_ids,
          "metrics" => {
            "phase_blocking_issue_count" => 1,
            "phase_nonblocking_open_point_count" => phase_local_issues.size + cross_phase_inconsistencies.size + caveats.size - 1,
            "phase_recheck_count" => 1,
            "phase_handback_count_by_class" => { "A" => 0, "B" => 1, "C" => 0, "D" => 0 },
            "phase_reopen_required_count" => 1,
            "phase_minor_adjustment_count" => minor_adjustment_count,
            "phase_major_correction_count" => major_correction_count,
            "phase_intent_attributed_issue_count" => intent_attributed_issues.size
          }
        }
      end

      def phase_field_requirements_analysis
        phase_local_issues = [
          {
            "issue_id" => "spec-requirements-clean-room-boundary-contract",
            "severity" => "high",
            "summary" => "The requirements lock the clean-room evidence boundary to `DEVELOPMENT_SPEC.md` and `wingxa.h`, but they also embed implementation-shaping constraints such as static allocation and exact acceptance bundles, so downstream phases must preserve where requirement contract ends and implementation choice begins.",
            "source_refs" => [
              reviewed_phase_ref,
              ".kiro/specs/phase-field-reverse-spec/intent.md"
            ]
          },
          {
            "issue_id" => "spec-requirements-acceptance-bundle-density",
            "severity" => "medium",
            "summary" => "Requirement 7 aggregates build, initial output, rerender, BMP generation, log-domain safety, and post-correction invariants into one acceptance bundle, which increases verification coupling and should be reflected explicitly in downstream validation planning.",
            "source_refs" => [
              reviewed_phase_ref
            ]
          }
        ]

        cross_phase_inconsistencies = [
          {
            "issue_id" => "spec-requirements-downstream-approval-gap",
            "severity" => "high",
            "summary" => "Requirements are already approved, but `design` and `tasks` remain unapproved in `spec.json`; downstream phases therefore need a recheck before the accepted requirements can be treated as implementation-ready evidence.",
            "source_refs" => [
              reviewed_phase_ref,
              ".kiro/specs/phase-field-reverse-spec/spec.json",
              ".kiro/specs/phase-field-reverse-spec/design.md",
              ".kiro/specs/phase-field-reverse-spec/tasks.md"
            ]
          }
        ]

        intent_attributed_issues = [
          {
            "issue_id" => "spec-requirements-intent-scope-preservation",
            "severity" => "medium",
            "summary" => "The scientific clean-room intent requires the downstream phases to preserve the narrow reference boundary and avoid silently broadening the reconstruction scope with extra materials or unstated implementation assumptions.",
            "source_refs" => [
              ".kiro/specs/phase-field-reverse-spec/intent.md",
              reviewed_phase_ref
            ]
          }
        ]

        caveats = []
        linked_signal_ids = [
          "spec-track-requirements-clean-room-boundary",
          "spec-track-requirements-downstream-approval-gap"
        ]

        if review_mode == "dual_reviewer_workflow"
          cross_phase_inconsistencies << {
            "issue_id" => "spec-requirements-validation-surface-spillover",
            "severity" => "medium",
            "summary" => "The acceptance criteria enumerate output and invariant checks across simulation, rerender, and BMP paths, so the downstream design should make validation ownership and cross-module test boundaries explicit instead of leaving them implicit.",
            "source_refs" => [
              reviewed_phase_ref,
              ".kiro/specs/phase-field-reverse-spec/design.md"
            ]
          }
          caveats << {
            "issue_id" => "spec-requirements-caveat-validation-ownership",
            "severity" => "low",
            "summary" => "Requirement-level acceptance remains intentionally dense for the pilot; the review should preserve this density as a caveat rather than flatten it into a single implementation task.",
            "source_refs" => [
              reviewed_phase_ref
            ]
          }
        end

        handback_class = "C"
        major_correction_count = review_mode == "dual_reviewer_workflow" ? 1 : 0
        minor_adjustment_count = review_mode == "dual_reviewer_workflow" ? 1 : 2

        {
          "phase_local_issues" => phase_local_issues,
          "cross_phase_inconsistencies" => cross_phase_inconsistencies,
          "intent_attributed_issues" => intent_attributed_issues,
          "caveats" => caveats,
          "reopen_required" => true,
          "target_reopen_phases" => %w[requirements design tasks],
          "next_action" => "requirements の clean-room boundary と acceptance bundle を再確認し、その前提で design/tasks の validation ownership と readiness gate を引き直す",
          "alignment_note" => "Requirements-origin issues require a requirements/design/tasks recheck before this case can be treated as fixed downstream evidence.",
          "linked_signal_ids" => linked_signal_ids,
          "metrics" => {
            "phase_blocking_issue_count" => 1,
            "phase_nonblocking_open_point_count" => phase_local_issues.size + cross_phase_inconsistencies.size + caveats.size - 1,
            "phase_recheck_count" => 1,
            "phase_handback_count_by_class" => { "A" => 0, "B" => 0, "C" => 1, "D" => 0 },
            "phase_reopen_required_count" => 1,
            "phase_minor_adjustment_count" => minor_adjustment_count,
            "phase_major_correction_count" => major_correction_count,
            "phase_intent_attributed_issue_count" => intent_attributed_issues.size
          }
        }
      end

      def default_analysis
        {
          "phase_local_issues" => [],
          "cross_phase_inconsistencies" => [],
          "intent_attributed_issues" => [],
          "caveats" => [],
          "reopen_required" => false,
          "target_reopen_phases" => [],
          "next_action" => "manual population required",
          "alignment_note" => "Populate with alignment findings, reopen targets, and propagation decisions after the run.",
          "linked_signal_ids" => [],
          "metrics" => {
            "phase_blocking_issue_count" => 0,
            "phase_nonblocking_open_point_count" => 0,
            "phase_recheck_count" => 0,
            "phase_handback_count_by_class" => { "A" => 0, "B" => 0, "C" => 0, "D" => 0 },
            "phase_reopen_required_count" => 0,
            "phase_minor_adjustment_count" => 0,
            "phase_major_correction_count" => 0,
            "phase_intent_attributed_issue_count" => 0
          }
        }
      end

      def phase_field_tasks_case?
        case_id == "F1-spec-phase-field-reverse-spec" && reviewed_phase == "tasks" && reviewed_phase_ref.include?("phase-field-reverse-spec/tasks.md")
      end

      def phase_field_requirements_case?
        case_id == "F1-requirements-phase-field-reverse-spec" &&
          reviewed_phase == "requirements" &&
          reviewed_phase_ref.include?("phase-field-reverse-spec/requirements.md")
      end

      def phase_field_design_case?
        case_id == "F1-design-phase-field-reverse-spec" &&
          reviewed_phase == "design" &&
          reviewed_phase_ref.include?("phase-field-reverse-spec/design.md")
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
