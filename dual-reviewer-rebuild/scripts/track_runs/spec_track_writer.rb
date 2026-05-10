#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "digest"
require "json"
require "pathname"
require "time"
require "yaml"
require "erb"
require_relative "../../runtime/support/foundation_asset_loader"
require_relative "../../runtime/controller/session_controller"
require_relative "../../runtime/execution_v2/manifests/case_manifest_loader"
require_relative "../../runtime/execution_v2/protocol_track_session"

module DualReviewer
  module TrackRuns
    class SpecTrackWriter
      attr_reader :repo_root, :run_label, :case_id, :review_mode, :reviewed_phase,
                  :reviewed_phase_ref, :adjacent_phase_refs, :alignment_refs, :operator,
                  :output_root, :runtime_run_root_base, :case_manifest_ref, :loaded_case_manifest,
                  :asset_loader, :protocol_track_session

      def initialize(repo_root:, run_label:, case_id:, review_mode:, reviewed_phase:, reviewed_phase_ref:,
                     adjacent_phase_refs:, alignment_refs:, operator:, output_root: nil, runtime_run_root_base: nil, case_manifest_ref: nil)
        @repo_root = Pathname(repo_root).expand_path
        @run_label = run_label
        @review_mode = review_mode
        @operator = operator
        @output_root = output_root ? Pathname(output_root).expand_path : default_output_root
        @runtime_run_root_base = runtime_run_root_base ? Pathname(runtime_run_root_base).expand_path : repo_root.join("experiments/runs")
        @case_manifest_ref = case_manifest_ref
        @loaded_case_manifest = load_case_manifest(case_manifest_ref)
        @case_id = loaded_case_manifest ? loaded_case_manifest.fetch("case_id") : case_id
        @reviewed_phase = loaded_case_manifest ? loaded_case_manifest.fetch("reviewed_phase") : reviewed_phase
        @reviewed_phase_ref = loaded_case_manifest ? loaded_case_manifest.fetch("reviewed_phase_ref") : reviewed_phase_ref
        @adjacent_phase_refs = loaded_case_manifest ? loaded_case_manifest.fetch("adjacent_phase_refs") : adjacent_phase_refs
        @alignment_refs = loaded_case_manifest ? loaded_case_manifest.fetch("alignment_refs") : alignment_refs
        @asset_loader = DualReviewer::Runtime::FoundationAssetLoader.new(repo_root: @repo_root)
        @protocol_track_session = DualReviewer::Runtime::ExecutionV2::ProtocolTrackSession.new(repo_root: @repo_root)
      end

      def write_all
        FileUtils.mkdir_p(run_root)
        FileUtils.mkdir_p(run_root.join("v2"))
        analysis = analyze_case

        paths = {
          "reviewed_phase_note" => write_reviewed_phase_note(analysis: analysis),
          "alignment_artifact" => write_alignment_artifact(analysis: analysis),
          "phase_metric_snapshot" => write_phase_metric_snapshot(analysis: analysis),
          "signal_linkage_note" => write_signal_linkage_note(analysis: analysis),
          "v2_review_artifact" => write_v2_review_artifact(analysis: analysis),
          "v2_metric_snapshot" => write_v2_metric_snapshot(analysis: analysis),
          "v2_trace_note" => write_v2_trace_note(analysis: analysis),
          "v2_signal_linkage_note" => write_v2_signal_linkage_note(analysis: analysis),
          "execution_packet" => write_execution_packet
        }
        paths["run_manifest"] = write_run_manifest(paths: paths)
        paths
      end

      private

      def default_output_root
        repo_root.join("experiments/protocols/spec-track-runs")
      end

      def load_case_manifest(ref)
        return nil unless ref

        DualReviewer::Runtime::ExecutionV2::CaseManifestLoader.new(repo_root: repo_root).load(ref)
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
          "case_manifest_ref" => case_manifest_reference,
          "inputs" => {
            "reviewed_phase_ref" => reviewed_phase_ref,
            "adjacent_phase_refs" => adjacent_phase_refs,
            "alignment_refs" => alignment_refs
          },
          "references" => {
            "workflow_gate_status_ref" => workflow_gate_status_ref,
            "phase_metric_register_ref" => phase_metric_register_ref
          },
          "runtime" => {
            "run_id" => runtime_session_result.fetch("run_id"),
            "runtime_review_mode" => "runtime_mediated",
            "treatment" => runtime_session_result.fetch("metadata").fetch("treatment")
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
          - case manifest ref:
            - `#{case_manifest_reference}`
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

      def write_v2_review_artifact(analysis:)
        payload = JSON.parse(Pathname(runtime_session_result.fetch("runtime_paths").fetch("v2_review_artifact")).read)

        path = run_root.join("v2/review_artifact.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_v2_metric_snapshot(analysis:)
        payload = JSON.parse(Pathname(runtime_session_result.fetch("runtime_paths").fetch("v2_metric_snapshot")).read)

        path = run_root.join("v2/metric_snapshot.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_v2_trace_note(analysis:)
        payload = JSON.parse(Pathname(runtime_session_result.fetch("runtime_paths").fetch("v2_trace_note")).read)

        path = run_root.join("v2/trace_note.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_v2_signal_linkage_note(analysis:)
        payload = JSON.parse(Pathname(runtime_session_result.fetch("runtime_paths").fetch("v2_signal_linkage_note")).read)

        path = run_root.join("v2/signal_linkage_note.json")
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

      def case_manifest_reference
        case_manifest_ref || "spec-track/#{case_id}"
      end

      def execution_contract
        @execution_contract ||= runtime_session_result.fetch("execution_contract")
      end

      def mapped_treatment
        execution_contract.fetch("common_inputs").fetch("treatment")
      end

      def spec_evidence_observations(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("evidence_observations")
      end

      def spec_issue_candidates(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("review_issue_candidates")
      end

      def spec_caveat_candidates(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("caveat_candidates")
      end

      def spec_reopen_candidates(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("reopen_candidates")
      end

      def spec_signal_candidates(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("signal_candidates")
      end

      def analyze_case
        protocol_runtime_case.fetch("analysis")
      end

      def protocol_v2_bundle(analysis:)
        protocol_runtime_case.fetch("bundle")
      end

      def protocol_runtime_case
        @protocol_runtime_case ||= protocol_track_session.build_spec_case(
          case_id: case_id,
          review_mode: review_mode,
          analysis_profile_ref: loaded_case_manifest && loaded_case_manifest["analysis_profile_ref"],
          reviewed_phase: reviewed_phase,
          reviewed_phase_ref: reviewed_phase_ref,
          adjacent_phase_refs: adjacent_phase_refs,
          alignment_refs: alignment_refs,
          workflow_gate_status_ref: workflow_gate_status_ref,
          case_manifest_ref: case_manifest_reference,
          compatibility_projection: {
            "protocol_artifact_refs" => [
              relative_to_repo(run_root.join("reviewed_phase_note.md")),
              relative_to_repo(run_root.join("alignment_artifact.yaml")),
              relative_to_repo(run_root.join("phase_metric_snapshot.json")),
              relative_to_repo(run_root.join("signal_linkage_note.yaml"))
            ]
          }
        )
      end

      def runtime_session_result
        @runtime_session_result ||= begin
          controller = DualReviewer::Runtime::SessionController.new(
            repo_root: repo_root,
            run_root_base: runtime_run_root_base
          )

          target_id = "spec:#{case_id}"
          target_artifact_hash = "sha256:#{Digest::SHA256.hexdigest(reviewed_phase_ref)}"

          initialized_run = controller.initialize_run(
            target_id: target_id,
            target_artifact_hash: target_artifact_hash,
            phase_profile: reviewed_phase,
            treatment: review_mode == "dual_reviewer_workflow" ? "dual+judgment" : "single",
            review_mode: "runtime_mediated",
            operator_id: operator
          )

          step_payloads = controller.emit_step_artifacts(
            run_id: initialized_run.fetch("run_id"),
            target_id: target_id,
            phase_profile: reviewed_phase,
            treatment: initialized_run.fetch("metadata").fetch("treatment"),
            analysis_inputs: {
              "source_refs" => ([reviewed_phase_ref] + adjacent_phase_refs + alignment_refs).uniq,
              "reviewed_phase_ref" => reviewed_phase_ref,
              "adjacent_phase_refs" => adjacent_phase_refs,
              "alignment_refs" => alignment_refs,
              "heuristic_profile_ref" => loaded_case_manifest.fetch("heuristic_profile_ref")
            }
          )

          review_case = controller.aggregate_review_case(
            run_id: initialized_run.fetch("run_id"),
            metadata: initialized_run.fetch("metadata"),
            step_payloads: step_payloads
          )

          decision_artifacts = controller.emit_decision_artifacts(
            run_id: initialized_run.fetch("run_id"),
            step_payloads: step_payloads,
            human_decision: "approved",
            operator_id: operator,
            review_case: review_case.fetch("review_case")
          )

          validation_close = controller.close_run(
            run_id: initialized_run.fetch("run_id"),
            metadata: initialized_run.fetch("metadata"),
            human_signoff: decision_artifacts.fetch("human_signoff")
          )

          case_manifest = controller.build_case_manifest(loaded_case_manifest)
          execution_v2_artifacts = controller.emit_execution_v2_artifacts(
            run_id: initialized_run.fetch("run_id"),
            track: "spec",
            common_inputs: {
              "target_id" => target_id,
              "target_artifact_hash" => target_artifact_hash,
              "source_repository_id" => initialized_run.fetch("metadata").fetch("source_repository_id"),
              "source_revision" => initialized_run.fetch("metadata").fetch("source_revision"),
              "phase_profile" => reviewed_phase,
              "treatment" => initialized_run.fetch("metadata").fetch("treatment"),
              "review_mode" => "runtime_mediated",
              "source_refs" => ([reviewed_phase_ref] + adjacent_phase_refs + alignment_refs).uniq,
              "governance_refs" => [workflow_gate_status_ref]
            },
            track_inputs: {
              "reviewed_phase" => reviewed_phase,
              "reviewed_phase_ref" => reviewed_phase_ref,
              "adjacent_phase_refs" => adjacent_phase_refs,
              "alignment_refs" => alignment_refs
            },
            case_manifest: case_manifest,
            review_case: review_case.fetch("review_case"),
            decision_artifacts: decision_artifacts,
            validation_close: validation_close
          )

          {
            "run_id" => initialized_run.fetch("run_id"),
            "metadata" => initialized_run.fetch("metadata"),
            "execution_contract" => execution_v2_artifacts.fetch("execution_contract"),
            "runtime_paths" => {
              "v2_review_artifact" => execution_v2_artifacts.fetch("review_artifact_path"),
              "v2_metric_snapshot" => execution_v2_artifacts.fetch("metric_snapshot_path"),
              "v2_trace_note" => execution_v2_artifacts.fetch("trace_note_path"),
              "v2_signal_linkage_note" => execution_v2_artifacts.fetch("signal_linkage_note_path")
            }
          }
        end
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
