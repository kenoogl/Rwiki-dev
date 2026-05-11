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
        source_document_entries(context, extra_refs).map { |entry| entry.fetch("ref") }
      end

      def source_document_entries(context, extra_refs = [])
        inputs = analysis_inputs(context)
        entries = []
        entries.concat(Array(inputs["source_refs"]).map { |ref| build_source_entry(ref, "case_source") })
        entries << build_source_entry(inputs["implementation_snapshot_ref"], "implementation_snapshot")
        entries.concat(Array(inputs["upstream_spec_refs"]).map { |ref| build_source_entry(ref, "upstream_spec") })
        entries << build_source_entry(inputs["reviewed_phase_ref"], "reviewed_phase")
        entries << build_source_entry(inputs["intent_ref"], "intent")
        entries.concat(Array(inputs["adjacent_phase_refs"]).map { |ref| build_source_entry(ref, "adjacent_phase") })
        entries.concat(Array(inputs["alignment_refs"]).map { |ref| build_source_entry(ref, "alignment") })
        entries.concat(Array(inputs["supporting_refs"]).map { |ref| build_source_entry(ref, "supporting") })
        entries.concat(Array(inputs["traceability_refs"]).map { |ref| build_source_entry(ref, "traceability") })
        entries.concat(Array(extra_refs).map { |ref| build_source_entry(ref, "extra") })
        dedupe_source_entries(entries)
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

      def build_rule_matched_analysis(context)
        rules = heuristic_rules_for(context)
        evidence_records = rule_match_analyzer.build_evidence_records(
          step_id: context.fetch(:step_id),
          source_document_refs: source_document_refs(context),
          source_document_entries: source_document_entries(context),
          rule_set: rules
        )
        observations = rule_match_analyzer.build_observations(
          step_name: step_name,
          step_id: context.fetch(:step_id),
          source_document_refs: source_document_refs(context),
          source_document_entries: source_document_entries(context),
          rule_set: rules
        )
        raw_findings = rule_match_analyzer.build_findings(
          step_name: step_name,
          step_id: context.fetch(:step_id),
          observations: observations,
          rule_set: rules
        )

        findings = raw_findings.map do |finding|
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

        {
          "evidence_records" => evidence_records,
          "observations" => observations,
          "findings" => findings
        }
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

      def build_source_entry(ref, source_kind)
        return nil if ref.nil?

        {
          "ref" => ref,
          "source_kind" => source_kind
        }
      end

      def dedupe_source_entries(entries)
        Array(entries).compact.each_with_object([]) do |entry, acc|
          next if acc.any? { |existing| existing.fetch("ref") == entry.fetch("ref") }

          acc << entry
        end
      end
    end
  end
end
