# frozen_string_literal: true

require "pathname"
require_relative "../execution_v2/analyzers/heuristic_profile_loader"
require_relative "../execution_v2/analyzers/rule_match_analyzer"

module DualReviewer
  module Runtime
    class BaseStepExecutor
      attr_reader :asset_loader, :evidence_writer

      def initialize(asset_loader:, evidence_writer:)
        @asset_loader = asset_loader
        @evidence_writer = evidence_writer
      end

      def step_name
        raise NotImplementedError, "#{self.class} must implement #step_name"
      end

      def execute(_context)
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      private

      def analysis_inputs(context)
        context.fetch(:analysis_inputs, {})
      end

      def prior_step_payloads(context)
        context.fetch(:prior_step_payloads, [])
      end

      def foundation_prompt_path(relative_path)
        asset_loader.foundation_asset_path(relative_path)
      end

      def resolved_prompt_identity(relative_path)
        frontmatter = asset_loader.prompt_frontmatter(relative_path)
        {
          "prompt_artifact_path" => foundation_prompt_path(relative_path).to_s,
          "prompt_id" => frontmatter.fetch("prompt_id"),
          "prompt_version" => frontmatter.fetch("prompt_version"),
          "resolution_status" => "resolved"
        }
      end

      def placeholder_prompt_identity(role:, step:)
        {
          "prompt_artifact_path" => nil,
          "prompt_id" => "runtime.#{role}.#{step}.deferred",
          "prompt_version" => nil,
          "resolution_status" => "deferred"
        }
      end

      def source_ref_list(context, extra_refs = [])
        inputs = analysis_inputs(context)
        refs = []
        refs.concat(Array(inputs["source_refs"]))
        refs << inputs["implementation_snapshot_ref"]
        refs.concat(Array(inputs["upstream_spec_refs"]))
        refs << inputs["reviewed_phase_ref"]
        refs << inputs["intent_ref"]
        refs.concat(Array(inputs["adjacent_phase_refs"]))
        refs.concat(Array(inputs["alignment_refs"]))
        refs.concat(Array(inputs["supporting_refs"]))
        refs.concat(Array(inputs["traceability_refs"]))
        refs.concat(extra_refs)
        refs.compact.uniq
      end

      def source_document_refs(context)
        source_ref_list(context)
      end

      def heuristic_profile(context)
        @heuristic_profiles ||= {}
        ref = analysis_inputs(context)["heuristic_profile_ref"]
        @heuristic_profiles[ref] ||= DualReviewer::Runtime::ExecutionV2::HeuristicProfileLoader.new(
          repo_root: asset_loader.repo_root
        ).load(ref: ref)
      end

      def heuristic_rules_for(context)
        heuristic_profile(context).fetch("steps", {}).fetch(step_name, {}).fetch("rules", [])
      end

      def rule_match_analyzer
        @rule_match_analyzer ||= DualReviewer::Runtime::ExecutionV2::RuleMatchAnalyzer.new(
          repo_root: asset_loader.repo_root,
          asset_loader: asset_loader
        )
      end

      def build_rule_matched_findings(context)
        raw_findings = rule_match_analyzer.build_findings(
          step_name: step_name,
          step_id: context.fetch(:step_id),
          source_document_refs: source_document_refs(context),
          rule_set: heuristic_rules_for(context)
        )

        raw_findings.map do |finding|
          build_step_finding(
            context: context,
            finding_id: finding.fetch("finding_id"),
            severity: finding.fetch("severity"),
            summary: finding.fetch("summary"),
            source_role: finding.fetch("source_role"),
            source_refs: finding.fetch("source_refs"),
            counter_evidence_refs: finding.fetch("counter_evidence_refs"),
            failure_observation_refs: finding.fetch("failure_observation_refs")
          ).merge(
            "analysis_origin" => finding.fetch("analysis_origin")
          )
        end
      end

      def summary_for_rule(_rule, _refs)
        raise NotImplementedError, "summary_for_rule is replaced by RuleMatchAnalyzer"
      end

      def refs_for_rule(_context, _rule)
        raise NotImplementedError, "refs_for_rule is replaced by RuleMatchAnalyzer"
      end

      def compile_patterns(_patterns)
        raise NotImplementedError, "compile_patterns is replaced by RuleMatchAnalyzer"
      end

      def load_ref_text(_ref)
        raise NotImplementedError, "load_ref_text is replaced by RuleMatchAnalyzer"
      end

      def build_step_finding(context:, finding_id:, severity:, summary:, source_role:, source_refs:, counter_evidence_refs: [], failure_observation_refs: [])
        {
          "finding_id" => finding_id,
          "severity" => severity,
          "summary" => summary,
          "source_role" => source_role,
          "source_refs" => source_refs,
          "counter_evidence_refs" => counter_evidence_refs,
          "failure_observation_refs" => failure_observation_refs
        }
      end
    end
  end
end
