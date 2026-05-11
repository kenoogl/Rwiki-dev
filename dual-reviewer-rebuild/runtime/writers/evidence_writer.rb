# frozen_string_literal: true

require "json"
require "pathname"
require "fileutils"
require "yaml"

module DualReviewer
  module Runtime
    class EvidenceWriter
      attr_reader :repo_root, :run_root_base, :export_root_base

      def initialize(repo_root:, run_root_base: nil, export_root_base: nil)
        @repo_root = Pathname(repo_root).expand_path
        @run_root_base = run_root_base ? Pathname(run_root_base).expand_path : @repo_root.join("experiments/runs")
        @export_root_base = export_root_base ? Pathname(export_root_base).expand_path : @repo_root.join("exports")
      end

      def canonical_run_root(run_id)
        run_root_base.join(run_id)
      end

      def canonical_subdirectories
        %w[steps decisions v2 validation derived]
      end

      def create_run_layout(run_id)
        run_root = canonical_run_root(run_id)
        FileUtils.mkdir_p(run_root)
        canonical_subdirectories.each do |subdirectory|
          FileUtils.mkdir_p(run_root.join(subdirectory))
        end
        run_root
      end

      def write_run_manifest(run_id:, manifest:)
        run_root = create_run_layout(run_id)
        manifest_path = run_root.join("run_manifest.yaml")
        manifest_path.write(YAML.dump(manifest))
        manifest_path
      end

      def write_step_artifact(run_id:, step_name:, payload:)
        path = canonical_run_root(run_id).join("steps", "#{step_filename(step_name)}.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_review_case(run_id:, payload:)
        path = canonical_run_root(run_id).join("review_case.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_decision_units(run_id:, payload:)
        path = canonical_run_root(run_id).join("decisions/decision_units.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_human_signoff(run_id:, payload:)
        path = canonical_run_root(run_id).join("decisions/human_signoff.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_v2_review_artifact(run_id:, payload:)
        path = canonical_run_root(run_id).join("v2/review_artifact.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_v2_metric_snapshot(run_id:, payload:)
        path = canonical_run_root(run_id).join("v2/metric_snapshot.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_v2_trace_note(run_id:, payload:)
        path = canonical_run_root(run_id).join("v2/trace_note.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_v2_signal_linkage_note(run_id:, payload:)
        path = canonical_run_root(run_id).join("v2/signal_linkage_note.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_validator_result(run_id:, payload:)
        path = canonical_run_root(run_id).join("validation/validator_result.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_invalidation_markers(run_id:, payload:)
        path = canonical_run_root(run_id).join("validation/invalidation_markers.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_comparison_eligibility_note(run_id:, payload:)
        path = canonical_run_root(run_id).join("derived/comparison_eligibility_note.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def write_invalid_run_triage_note(run_id:, payload:)
        path = canonical_run_root(run_id).join("derived/invalid_run_triage_note.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def update_run_manifest(run_id:)
        path = canonical_run_root(run_id).join("run_manifest.yaml")
        manifest = YAML.load_file(path)
        yield manifest
        path.write(YAML.dump(manifest))
        path
      end

      def update_review_case(run_id:)
        path = canonical_run_root(run_id).join("review_case.json")
        review_case = JSON.parse(path.read)
        yield review_case
        path.write(JSON.pretty_generate(review_case))
        path
      end

      def export_root(bundle_id)
        export_root_base.join(bundle_id)
      end

      def prepare_export_layout(bundle_id)
        root = export_root(bundle_id)
        FileUtils.mkdir_p(root.join("run"))
        FileUtils.mkdir_p(root.join("checksums"))
        root
      end

      def write_bundle_manifest(bundle_id:, payload:)
        root = prepare_export_layout(bundle_id)
        path = root.join("bundle_manifest.yaml")
        path.write(YAML.dump(payload))
        path
      end

      def write_bundle_checksums(bundle_id:, payload:)
        root = prepare_export_layout(bundle_id)
        path = root.join("checksums/bundle_checksums.json")
        path.write(JSON.pretty_generate(payload))
        path
      end

      def copy_run_to_bundle(run_id:, bundle_id:)
        root = prepare_export_layout(bundle_id)
        destination = root.join("run", run_id)
        FileUtils.rm_rf(destination)
        FileUtils.cp_r(canonical_run_root(run_id), destination)
        destination
      end

      def step_filename(step_name)
        case step_name
        when "primary_detection"
          "step_a_primary_detection"
        when "adversarial_review"
          "step_b_adversarial_review"
        when "judgment"
          "step_c_judgment"
        when "integration"
          "step_d_integration"
        else
          raise ArgumentError, "unknown step name: #{step_name}"
        end
      end
    end
  end
end
