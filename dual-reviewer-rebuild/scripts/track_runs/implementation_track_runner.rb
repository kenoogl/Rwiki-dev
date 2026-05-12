# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "pathname"
require "time"
require "yaml"
require_relative "../../runtime/controller/session_controller"
require_relative "../../runtime/execution_v2/manifests/case_manifest_loader"
require_relative "spec_phase_guard"
require_relative "runtime_validation_summary_builder"
require_relative "default_heuristic_profile_ref"

module DualReviewer
  module TrackRuns
    class ImplementationTrackRunner
      attr_reader :repo_root, :run_label, :case_id, :review_mode, :implementation_snapshot_ref,
                  :upstream_spec_refs, :governance_refs, :operator, :phase_profile, :target_id,
                  :target_artifact_hash, :protocol_output_root, :runtime_run_root_base, :export_root_base,
                  :case_manifest_ref, :loaded_case_manifest, :heuristic_profile_ref, :runtime_validation_summary_builder,
                  :spec_phase_guard

      def initialize(repo_root:, run_label:, case_id:, review_mode:, implementation_snapshot_ref:,
                     upstream_spec_refs:, governance_refs:, operator:, phase_profile:, target_id:,
                     target_artifact_hash: nil, protocol_output_root: nil, runtime_run_root_base: nil,
                     export_root_base: nil, case_manifest_ref: nil)
        @repo_root = Pathname(repo_root).expand_path
        @run_label = run_label
        @review_mode = review_mode
        @operator = operator
        @protocol_output_root = protocol_output_root ? Pathname(protocol_output_root).expand_path : default_protocol_output_root
        @runtime_run_root_base = runtime_run_root_base ? Pathname(runtime_run_root_base).expand_path : repo_root.join("experiments/runs")
        @export_root_base = export_root_base ? Pathname(export_root_base).expand_path : repo_root.join("exports")
        @case_manifest_ref = case_manifest_ref
        @loaded_case_manifest = load_case_manifest(case_manifest_ref)
        @runtime_validation_summary_builder = RuntimeValidationSummaryBuilder.new(repo_root: @repo_root)
        @spec_phase_guard = SpecPhaseGuard.new(repo_root: @repo_root)
        @case_id = loaded_case_manifest ? loaded_case_manifest.fetch("case_id") : case_id
        @implementation_snapshot_ref = loaded_case_manifest ? loaded_case_manifest.fetch("implementation_snapshot_ref") : implementation_snapshot_ref
        @upstream_spec_refs = loaded_case_manifest ? loaded_case_manifest.fetch("upstream_spec_refs") : upstream_spec_refs
        @governance_refs = loaded_case_manifest ? loaded_case_manifest.fetch("governance_refs") : governance_refs
        @phase_profile = loaded_case_manifest ? loaded_case_manifest.fetch("phase_profile") : phase_profile
        @target_id = loaded_case_manifest ? loaded_case_manifest.fetch("target_id") : target_id
        @heuristic_profile_ref = if loaded_case_manifest && loaded_case_manifest["heuristic_profile_ref"]
                                   loaded_case_manifest["heuristic_profile_ref"]
                                 else
                                   DefaultHeuristicProfileRef.for_track("implementation")
                                 end
        @target_artifact_hash = target_artifact_hash || derive_target_artifact_hash
      end

      def run_all
        spec_phase_guard.assert_phase_entry_allowed!(phase: "implementation", refs: upstream_spec_refs)

        FileUtils.mkdir_p(run_root)

        controller = DualReviewer::Runtime::SessionController.new(
          repo_root: repo_root,
          run_root_base: runtime_run_root_base,
          export_root_base: export_root_base
        )

        initialized_run = controller.initialize_run(
          target_id: target_id,
          target_artifact_hash: target_artifact_hash,
          phase_profile: phase_profile,
          treatment: mapped_treatment,
          review_mode: "runtime_mediated",
          operator_id: operator
        )

        step_payloads = controller.emit_step_artifacts(
          run_id: initialized_run.fetch("run_id"),
          target_id: initialized_run.fetch("metadata").fetch("target_id"),
          phase_profile: initialized_run.fetch("metadata").fetch("phase_profile"),
          treatment: initialized_run.fetch("metadata").fetch("treatment"),
          analysis_inputs: {
            "implementation_snapshot_ref" => implementation_snapshot_ref,
            "upstream_spec_refs" => upstream_spec_refs,
            "governance_refs" => governance_refs,
            "heuristic_profile_ref" => heuristic_profile_ref
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

        case_manifest = controller.build_case_manifest(
          manifest_payload
        )
        execution_v2_artifacts = controller.emit_execution_v2_artifacts(
          run_id: initialized_run.fetch("run_id"),
          track: "implementation",
          common_inputs: {
            "target_id" => target_id,
            "target_artifact_hash" => target_artifact_hash,
            "source_repository_id" => initialized_run.fetch("metadata").fetch("source_repository_id"),
            "source_revision" => initialized_run.fetch("metadata").fetch("source_revision"),
            "phase_profile" => phase_profile,
            "treatment" => initialized_run.fetch("metadata").fetch("treatment"),
            "review_mode" => initialized_run.fetch("metadata").fetch("review_mode"),
            "source_refs" => [implementation_snapshot_ref, *upstream_spec_refs].uniq,
            "governance_refs" => governance_refs
          },
          track_inputs: {
            "implementation_snapshot_ref" => implementation_snapshot_ref,
            "upstream_spec_refs" => upstream_spec_refs,
            "governance_refs" => governance_refs
          },
          case_manifest: case_manifest,
          review_case: review_case.fetch("review_case"),
          decision_artifacts: decision_artifacts,
          validation_close: validation_close
        )

        bundle_export = controller.export_run_bundle(
          run_id: initialized_run.fetch("run_id"),
          metadata: initialized_run.fetch("metadata").merge(
            "validator_status" => validation_close.fetch("validator_result").fetch("overall_status") == "passed" ? "passed" : "failed",
            "human_signoff_status" => decision_artifacts.fetch("human_signoff").fetch("human_signoff_status")
          )
        )

        runtime_paths = {
          "review_artifact" => Pathname(review_case.fetch("review_case_path")),
          "v2_review_artifact" => Pathname(execution_v2_artifacts.fetch("review_artifact_path")),
          "v2_metric_snapshot" => Pathname(execution_v2_artifacts.fetch("metric_snapshot_path")),
          "v2_trace_note" => Pathname(execution_v2_artifacts.fetch("trace_note_path")),
          "v2_signal_linkage_note" => Pathname(execution_v2_artifacts.fetch("signal_linkage_note_path")),
          "decision_units" => Pathname(decision_artifacts.fetch("decision_units_path")),
          "conformance_review_result" => Pathname(validation_close.fetch("validator_result_path")),
          "caveat_artifact" => Pathname(validation_close.fetch("invalidation_markers_path")),
          "comparison_eligibility_note" => Pathname(validation_close.fetch("comparison_eligibility_note_path")),
          "invalid_run_triage_note" => Pathname(validation_close.fetch("invalid_run_triage_note_path")),
          "bundle_manifest" => Pathname(bundle_export.fetch("bundle_manifest_path"))
        }

        protocol_paths = {
          "implementation_review_note" => write_implementation_review_note(
            initialized_run: initialized_run,
            runtime_paths: runtime_paths
          ),
          "signal_linkage_note" => write_signal_linkage_note(initialized_run: initialized_run),
          "downstream_rework_log" => write_downstream_rework_log(initialized_run: initialized_run),
          "conformance_review_result_note" => write_conformance_review_result_note(
            initialized_run: initialized_run,
            validation_close: validation_close
          ),
          "execution_packet" => write_execution_packet(
            initialized_run: initialized_run,
            runtime_paths: runtime_paths
          )
        }
        protocol_paths["run_manifest"] = write_protocol_run_manifest(
          initialized_run: initialized_run,
          runtime_paths: runtime_paths,
          protocol_paths: protocol_paths,
          bundle_export: bundle_export
        )

        {
          "protocol_paths" => stringify_paths(protocol_paths),
          "runtime_paths" => stringify_paths(runtime_paths),
          "run_id" => initialized_run.fetch("run_id"),
          "bundle_id" => bundle_export.fetch("bundle_id")
        }
      end

      private

      def default_protocol_output_root
        repo_root.join("experiments/protocols/implementation-track-runs")
      end

      def load_case_manifest(ref)
        return nil unless ref

        DualReviewer::Runtime::ExecutionV2::CaseManifestLoader.new(repo_root: repo_root).load(ref)
      end

      def run_root
        protocol_output_root.join(sanitize(run_label))
      end

      def sanitize(value)
        value.gsub(/[^a-zA-Z0-9._-]+/, "-")
      end

      def mapped_treatment
        case review_mode
        when "single_review"
          "single"
        when "dual_review"
          "dual"
        when "dual_reviewer_workflow"
          "dual+judgment"
        else
          raise ArgumentError, "unsupported review_mode for implementation track: #{review_mode}"
        end
      end

      def derive_target_artifact_hash
        snapshot_path = Pathname(implementation_snapshot_ref)
        if snapshot_path.file?
          "sha256:#{Digest::SHA256.file(snapshot_path).hexdigest}"
        else
          "sha256:#{Digest::SHA256.hexdigest(implementation_snapshot_ref)}"
        end
      end

      def write_protocol_run_manifest(initialized_run:, runtime_paths:, protocol_paths:, bundle_export:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "implementation",
          "review_mode" => review_mode,
          "operator" => operator,
          "phase_profile" => phase_profile,
          "generated_at" => Time.now.utc.iso8601,
          "case_manifest_ref" => case_manifest_reference,
          "inputs" => {
            "implementation_snapshot_ref" => implementation_snapshot_ref,
            "upstream_spec_refs" => upstream_spec_refs,
            "governance_refs" => governance_refs
          },
          "runtime" => {
            "run_id" => initialized_run.fetch("run_id"),
            "runtime_review_mode" => initialized_run.fetch("metadata").fetch("review_mode"),
            "treatment" => initialized_run.fetch("metadata").fetch("treatment"),
            "bundle_id" => bundle_export.fetch("bundle_id")
          },
          "outputs" => runtime_paths.merge(protocol_paths).transform_values { |path| relative_to_repo(path) }
        }

        path = run_root.join("run_manifest.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_implementation_review_note(initialized_run:, runtime_paths:)
        content = <<~MARKDOWN
          # implementation review note

          ## 1. run scope

          - run label: `#{run_label}`
          - case id: `#{case_id}`
          - track: `implementation`
          - review mode: `#{review_mode}`
          - runtime review mode: `#{initialized_run.fetch("metadata").fetch("review_mode")}`
          - treatment: `#{initialized_run.fetch("metadata").fetch("treatment")}`
          - operator: `#{operator}`
          - implementation snapshot ref:
            - `#{implementation_snapshot_ref}`
          - case manifest ref:
            - `#{case_manifest_reference}`
          - upstream spec refs:
        #{upstream_spec_refs.map { |ref| "  - `#{ref}`" }.join("\n")}

          ## 2. runtime artifact refs

          - review artifact:
            - `#{relative_to_repo(runtime_paths.fetch("review_artifact"))}`
          - decision units:
            - `#{relative_to_repo(runtime_paths.fetch("decision_units"))}`

          ## 3. findings

          <!-- Populate implementation-local issues, upstream inconsistencies, disagreements, and caveats after the run. -->

          ## 4. reopen assessment

          - reopen required:
          - target reopen phases:
          - caveats:
        MARKDOWN

        path = run_root.join("implementation_review_note.md")
        path.write(content)
        path
      end

      def write_signal_linkage_note(initialized_run:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "implementation",
          "run_id" => initialized_run.fetch("run_id"),
          "linked_signal_ids" => [],
          "status" => "pending_manual_population",
          "note" => "Populate when implementation-track findings are linked into evaluation or self-improvement signal inventories."
        }

        path = run_root.join("signal_linkage_note.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_downstream_rework_log(initialized_run:)
        payload = {
          "run_label" => run_label,
          "case_id" => case_id,
          "track" => "implementation",
          "run_id" => initialized_run.fetch("run_id"),
          "rework_events" => [],
          "status" => "pending_manual_population",
          "note" => "Populate when implementation review findings trigger downstream rework or reopen actions."
        }

        path = run_root.join("downstream_rework_log.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_conformance_review_result_note(initialized_run:, validation_close:)
        payload = runtime_validation_summary_builder.build(
          run_label: run_label,
          case_id: case_id,
          track: "implementation",
          run_id: initialized_run.fetch("run_id"),
          runtime_paths: {
            "validator_result" => validation_close.fetch("validator_result_path"),
            "invalidation_markers" => validation_close.fetch("invalidation_markers_path"),
            "comparison_eligibility_note" => validation_close.fetch("comparison_eligibility_note_path"),
            "invalid_run_triage_note" => validation_close.fetch("invalid_run_triage_note_path")
          }
        )

        path = run_root.join("conformance_review_result.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_execution_packet(initialized_run:, runtime_paths:)
        steps =
          case review_mode
          when "single_review"
            [
              "implementation snapshot と upstream spec refs を読む",
              "implementation-local issue と upstream spec inconsistency を分離して列挙する",
              "runtime 生成済み artifact を参照し、`implementation_review_note.md` を更新する",
              "`signal_linkage_note.yaml`, `downstream_rework_log.yaml`, `conformance_review_result.yaml` を埋める"
            ]
          when "dual_review"
            [
              "primary reading を作る",
              "adversarial pass で counter-hypothesis と caveat を出す",
              "judgment なしで reopen target を決め、runtime artifact と protocol note を更新する",
              "`implementation_review_note.md`, `signal_linkage_note.yaml`, `downstream_rework_log.yaml`, `conformance_review_result.yaml` を埋める"
            ]
          else
            [
              "primary reading を作る",
              "adversarial pass で counter-hypothesis と caveat を出す",
              "judgment で must-fix / should-fix / leave-as-is を分ける",
              "reopen target を決め、runtime artifact と protocol note を更新する",
              "`implementation_review_note.md`, `signal_linkage_note.yaml`, `downstream_rework_log.yaml`, `conformance_review_result.yaml` を埋める"
            ]
          end

        content = <<~MARKDOWN
          # execution packet

          ## 1. run header

          - run label: `#{run_label}`
          - case id: `#{case_id}`
          - track: `implementation`
          - review mode: `#{review_mode}`
          - runtime review mode: `#{initialized_run.fetch("metadata").fetch("review_mode")}`
          - treatment: `#{initialized_run.fetch("metadata").fetch("treatment")}`
          - operator: `#{operator}`

          ## 2. inputs to read

          - implementation snapshot ref:
            - `#{implementation_snapshot_ref}`
          - upstream spec refs:
        #{upstream_spec_refs.map { |ref| "  - `#{ref}`" }.join("\n")}
          - governance refs:
        #{governance_refs.map { |ref| "  - `#{ref}`" }.join("\n")}

          ## 3. execution steps

        #{steps.each_with_index.map { |step, index| "#{index + 1}. #{step}" }.join("\n")}

          ## 4. runtime artifacts to inspect

          - `#{relative_to_repo(runtime_paths.fetch("review_artifact"))}`
          - `#{relative_to_repo(runtime_paths.fetch("decision_units"))}`
          - `#{relative_to_repo(runtime_paths.fetch("conformance_review_result"))}`
          - `#{relative_to_repo(runtime_paths.fetch("caveat_artifact"))}`
          - `#{relative_to_repo(runtime_paths.fetch("comparison_eligibility_note"))}`
          - `#{relative_to_repo(runtime_paths.fetch("invalid_run_triage_note"))}`

          ## 5. protocol artifacts to update

          - `#{relative_to_repo(run_root.join("implementation_review_note.md"))}`
          - `#{relative_to_repo(run_root.join("signal_linkage_note.yaml"))}`
          - `#{relative_to_repo(run_root.join("downstream_rework_log.yaml"))}`
          - `#{relative_to_repo(run_root.join("conformance_review_result.yaml"))}`

          ## 6. success check

          1. implementation-local issue と upstream inconsistency が分離されている
          2. disagreement / caveat が保存されている
          3. reopen target が必要時に埋まっている
        MARKDOWN

        path = run_root.join("execution_packet.md")
        path.write(content)
        path
      end

      def relative_to_repo(path)
        Pathname(path).relative_path_from(repo_root).to_s
      end

      def manifest_payload
        if loaded_case_manifest
          loaded_case_manifest
        else
          {
            "case_id" => case_id,
            "target_id" => target_id,
            "source_refs" => [implementation_snapshot_ref, *upstream_spec_refs].uniq,
            "case_manifest_ref" => case_manifest_reference
          }
        end
      end

      def case_manifest_reference
        case_manifest_ref || "implementation-track/#{case_id}"
      end

      def stringify_paths(hash)
        hash.transform_values(&:to_s)
      end
    end
  end
end
