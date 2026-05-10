# frozen_string_literal: true

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

      def phase_field_target?(context)
        context.fetch(:target_id).include?("phase-field-cpp")
      end

      def source_ref_list(context, extra_refs = [])
        refs = []
        refs << analysis_inputs(context)["implementation_snapshot_ref"]
        refs.concat(Array(analysis_inputs(context)["upstream_spec_refs"]))
        refs.concat(extra_refs)
        refs.compact.uniq
      end

      def source_document_refs(context)
        source_ref_list(context)
      end

      def load_ref_text(ref)
        ref_path = Pathname(ref.to_s.split("#").first)
        absolute_path = if ref_path.absolute?
                          ref_path
                        else
                          primary = asset_loader.repo_root.join(ref_path)
                          primary.exist? ? primary : asset_loader.repo_root.parent.join(ref_path)
                        end
        return nil unless absolute_path.exist?

        absolute_path.read
      end

      def refs_matching(context, patterns)
        source_document_refs(context).select do |ref|
          text = load_ref_text(ref)
          next false if text.nil? || text.empty?

          patterns.any? { |pattern| text.match?(pattern) }
        end
      end

      def first_matching_excerpt(refs, patterns)
        refs.each do |ref|
          text = load_ref_text(ref)
          next if text.nil? || text.empty?

          line = text.lines.find { |entry| patterns.any? { |pattern| entry.match?(pattern) } }
          return line.strip unless line.nil?
        end

        nil
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
