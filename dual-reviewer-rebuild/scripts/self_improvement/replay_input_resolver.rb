#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

module DualReviewer
  module SelfImprovement
    class ReplayInputResolver
      STEP_PRIORITY_BY_LAYER = {
        "prompt" => %w[step_b_adversarial_review step_c_judgment],
        "schema" => %w[step_c_judgment],
        "runtime" => %w[step_a_primary_detection step_b_adversarial_review step_c_judgment step_d_integration],
        "workflow" => [],
        "policy" => []
      }.freeze

      REQUIRED_RUNTIME_ARTIFACTS = %w[
        review_case.json
        decisions/decision_units.json
        validation/validator_result.json
        validation/invalidation_markers.json
      ].freeze

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def resolve_for_proposal(proposal_id:)
        proposal = load_proposal(proposal_id)
        run_id = proposal["source_repository_refs"]&.first&.fetch("run_id", nil)
        run_root = resolve_run_root(proposal: proposal, run_id: run_id)

        {
          "proposal_id" => proposal_id,
          "required_test_mode" => proposal["required_test_mode"],
          "replay_readiness" => replay_readiness(proposal: proposal, run_root: run_root),
          "source_origin" => proposal["source_origin"],
          "input_origin_refs" => proposal.fetch("source_repository_refs", []),
          "source_admission_refs" => proposal.fetch("source_admission_refs", []),
          "run_root" => run_root&.to_s,
          "replay_inputs" => run_root ? resolve_inputs(proposal: proposal, run_root: run_root) : default_inputs
        }
      end

      private

      def load_proposal(proposal_id)
        path = repo_root.join("learning/proposals/#{proposal_id}.yaml")
        YAML.load_file(path)
      end

      def resolve_run_root(proposal:, run_id:)
        return nil unless run_id

        case proposal["source_origin"]
        when "imported_external_bundle"
          bundle_id = proposal["source_admission_refs"]&.first&.fetch("bundle_id", nil)
          return repo_root.join("tests/fixtures/evaluation/imported_bundles", bundle_id, "run", run_id) if bundle_id && repo_root.join("tests/fixtures/evaluation/imported_bundles", bundle_id, "run", run_id).exist?
          return repo_root.join("exports", bundle_id, "run", run_id) if bundle_id && repo_root.join("exports", bundle_id, "run", run_id).exist?
        when "central_local_run"
          return local_run_candidates.find { |path| manifest_run_id(path) == run_id }
        end

        nil
      end

      def replay_readiness(proposal:, run_root:)
        return "not_required" unless proposal["required_test_mode"] == "replay"
        return "unresolved_run_root" unless run_root

        missing = missing_artifacts_for(proposal: proposal, run_root: run_root)
        missing.empty? ? "ready" : "incomplete"
      end

      def resolve_inputs(proposal:, run_root:)
        {
          "review_case_ref" => relative_if_exists(run_root.join("review_case.json")),
          "step_refs" => relevant_step_refs(proposal: proposal, run_root: run_root),
          "decision_unit_ref" => relative_if_exists(run_root.join("decisions/decision_units.json")),
          "validator_result_ref" => relative_if_exists(run_root.join("validation/validator_result.json")),
          "invalidation_markers_ref" => relative_if_exists(run_root.join("validation/invalidation_markers.json")),
          "missing_refs" => missing_artifacts_for(proposal: proposal, run_root: run_root)
        }
      end

      def default_inputs
        {
          "review_case_ref" => nil,
          "step_refs" => [],
          "decision_unit_ref" => nil,
          "validator_result_ref" => nil,
          "invalidation_markers_ref" => nil,
          "missing_refs" => []
        }
      end

      def relevant_step_refs(proposal:, run_root:)
        prioritized = STEP_PRIORITY_BY_LAYER.fetch(proposal["target_layer"], [])
        existing = prioritized.map { |basename| run_root.join("steps/#{basename}.json") }.select(&:exist?)
        existing.map { |path| relative_path(path) }
      end

      def missing_artifacts_for(proposal:, run_root:)
        missing = REQUIRED_RUNTIME_ARTIFACTS.reject { |relative| run_root.join(relative).exist? }

        if proposal["required_test_mode"] == "replay"
          replay_steps = STEP_PRIORITY_BY_LAYER.fetch(proposal["target_layer"], [])
          missing.concat(
            replay_steps
              .map { |basename| "steps/#{basename}.json" }
              .reject { |relative| run_root.join(relative).exist? }
          )
        end

        missing
      end

      def relative_if_exists(path)
        path.exist? ? relative_path(path) : nil
      end

      def relative_path(path)
        path.relative_path_from(run_root_base(path)).to_s
      end

      def run_root_base(path)
        current = path
        current = current.parent until current.join("run_manifest.yaml").exist? || current == current.parent
        current
      end

      def manifest_run_id(run_root)
        manifest_path = run_root.join("run_manifest.yaml")
        return nil unless manifest_path.exist?

        YAML.load_file(manifest_path).dig("metadata", "run_id")
      end

      def local_run_candidates
        candidates = []

        experiments_root = repo_root.join("experiments/runs")
        candidates.concat(experiments_root.children.select(&:directory?)) if experiments_root.exist?

        fixture_root = repo_root.join("tests/fixtures/evaluation/local_runs")
        candidates.concat(fixture_root.children.select(&:directory?)) if fixture_root.exist?

        candidates.select { |path| path.join("run_manifest.yaml").exist? }
      end
    end
  end
end
