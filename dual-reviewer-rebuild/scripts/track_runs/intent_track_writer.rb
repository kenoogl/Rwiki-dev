#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "digest"
require "json"
require "pathname"
require "time"
require "yaml"
require_relative "../../runtime/support/foundation_asset_loader"
require_relative "../../runtime/controller/session_controller"
require_relative "../../runtime/execution_v2/manifests/case_manifest_loader"
require_relative "../../runtime/execution_v2/protocol_track_session"

module DualReviewer
  module TrackRuns
    class IntentTrackWriter
      attr_reader :repo_root, :run_label, :case_id, :review_mode, :intent_ref, :supporting_refs,
                  :traceability_refs, :operator, :objective, :output_root, :case_manifest_ref, :loaded_case_manifest,
                  :asset_loader, :protocol_track_session, :runtime_run_root_base

      def initialize(repo_root:, run_label:, case_id:, review_mode:, intent_ref:, supporting_refs:,
                     operator:, objective:, output_root: nil, case_manifest_ref: nil, traceability_refs: [],
                     runtime_run_root_base: nil)
        @repo_root = Pathname(repo_root).expand_path
        @run_label = run_label
        @review_mode = review_mode
        @operator = operator
        @output_root = output_root ? Pathname(output_root).expand_path : default_output_root
        @runtime_run_root_base = runtime_run_root_base ? Pathname(runtime_run_root_base).expand_path : repo_root.join("experiments/runs")
        @case_manifest_ref = case_manifest_ref
        @loaded_case_manifest = load_case_manifest(case_manifest_ref)
        @case_id = loaded_case_manifest ? loaded_case_manifest.fetch("case_id") : case_id
        @intent_ref = loaded_case_manifest ? loaded_case_manifest.fetch("intent_ref") : intent_ref
        @supporting_refs = loaded_case_manifest ? loaded_case_manifest.fetch("supporting_refs") : supporting_refs
        @traceability_refs = loaded_case_manifest ? loaded_case_manifest.fetch("traceability_refs") : traceability_refs
        @objective = loaded_case_manifest ? loaded_case_manifest.fetch("objective") : objective
        @asset_loader = DualReviewer::Runtime::FoundationAssetLoader.new(repo_root: @repo_root)
        @protocol_track_session = DualReviewer::Runtime::ExecutionV2::ProtocolTrackSession.new(repo_root: @repo_root)
      end

      def write_all
        FileUtils.mkdir_p(run_root)
        FileUtils.mkdir_p(run_root.join("v2"))
        analysis = analyze_case

        paths = {
          "intent_review_artifact" => write_intent_review_artifact(analysis: analysis),
          "intent_trace_note" => write_intent_trace_note(analysis: analysis),
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
        repo_root.join("experiments/protocols/intent-track-runs")
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
          "case_manifest_ref" => case_manifest_reference,
          "inputs" => {
            "intent_ref" => intent_ref,
            "supporting_refs" => supporting_refs,
            "traceability_refs" => traceability_refs
          },
          "references" => {
            "workflow_gate_status_ref" => workflow_gate_status_ref,
            "phase_metric_register_ref" => phase_metric_register_ref,
            "intent_review_template_ref" => intent_review_template_ref
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
          - case manifest ref:
            - `#{case_manifest_reference}`
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
          "case_manifest_ref" => case_manifest_reference,
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
          - case manifest ref:
            - `#{case_manifest_reference}`
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

      def case_manifest_reference
        case_manifest_ref || "intent-track/#{case_id}"
      end

      def execution_contract
        @execution_contract ||= runtime_session_result.fetch("execution_contract")
      end

      def mapped_treatment
        execution_contract.fetch("common_inputs").fetch("treatment")
      end

      def intent_evidence_observations(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("evidence_observations")
      end

      def intent_issue_candidates(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("review_issue_candidates")
      end

      def intent_caveat_candidates(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("caveat_candidates")
      end

      def intent_reopen_candidates(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("reopen_candidates")
      end

      def intent_signal_candidates(analysis:)
        protocol_runtime_case.fetch("analysis_result").fetch("signal_candidates")
      end

      def analyze_case
        protocol_runtime_case.fetch("analysis")
      end

      def protocol_runtime_case
        @protocol_runtime_case ||= protocol_track_session.build_intent_case(
          case_id: case_id,
          review_mode: review_mode,
          analysis_profile_ref: loaded_case_manifest && loaded_case_manifest["analysis_profile_ref"],
          intent_ref: intent_ref,
          supporting_refs: supporting_refs,
          traceability_refs: traceability_refs,
          workflow_gate_status_ref: workflow_gate_status_ref,
          case_manifest_ref: case_manifest_reference,
          compatibility_projection: {
            "protocol_artifact_refs" => [
              relative_to_repo(run_root.join("intent_review.md")),
              relative_to_repo(run_root.join("intent_trace_note.yaml")),
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

          target_id = "intent:#{case_id}"
          target_artifact_hash = "sha256:#{Digest::SHA256.hexdigest(intent_ref)}"
          source_refs = ([intent_ref] + supporting_refs + traceability_refs).uniq

          initialized_run = controller.initialize_run(
            target_id: target_id,
            target_artifact_hash: target_artifact_hash,
            phase_profile: "intent",
            treatment: review_mode == "dual_reviewer_workflow" ? "dual+judgment" : "single",
            review_mode: "runtime_mediated",
            operator_id: operator
          )

          step_payloads = controller.emit_step_artifacts(
            run_id: initialized_run.fetch("run_id"),
            target_id: target_id,
            phase_profile: "intent",
            treatment: initialized_run.fetch("metadata").fetch("treatment"),
            analysis_inputs: {
              "source_refs" => source_refs,
              "intent_ref" => intent_ref,
              "supporting_refs" => supporting_refs,
              "traceability_refs" => traceability_refs,
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
            track: "intent",
            common_inputs: {
              "target_id" => target_id,
              "target_artifact_hash" => target_artifact_hash,
              "source_repository_id" => initialized_run.fetch("metadata").fetch("source_repository_id"),
              "source_revision" => initialized_run.fetch("metadata").fetch("source_revision"),
              "phase_profile" => "intent",
              "treatment" => initialized_run.fetch("metadata").fetch("treatment"),
              "review_mode" => "runtime_mediated",
              "source_refs" => source_refs,
              "governance_refs" => [workflow_gate_status_ref]
            },
            track_inputs: {
              "intent_ref" => intent_ref,
              "supporting_refs" => supporting_refs,
              "traceability_refs" => traceability_refs
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
