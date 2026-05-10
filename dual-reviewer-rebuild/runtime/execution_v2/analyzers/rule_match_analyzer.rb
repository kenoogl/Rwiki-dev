# frozen_string_literal: true

require "pathname"

module DualReviewer
  module Runtime
    module ExecutionV2
      class RuleMatchAnalyzer
        attr_reader :repo_root, :asset_loader

        def initialize(repo_root:, asset_loader:)
          @repo_root = Pathname(repo_root).expand_path
          @asset_loader = asset_loader
        end

        def build_findings(step_name:, step_id:, source_document_refs:, rule_set:)
          Array(rule_set).each_with_object([]) do |rule, findings|
            refs_payload = matched_refs(rule: rule, source_document_refs: source_document_refs)
            source_refs = refs_payload.fetch("source_refs")
            next if source_refs.empty?

            findings << {
              "finding_id" => "#{step_id}-#{rule.fetch('finding_suffix')}",
              "severity" => rule.fetch("severity"),
              "summary" => summarized_rule(rule: rule, refs: source_refs),
              "source_role" => rule.fetch("source_role"),
              "source_refs" => source_refs,
              "counter_evidence_refs" => refs_payload.fetch("counter_evidence_refs"),
              "failure_observation_refs" => Array(rule["failure_observation_refs"]),
              "analysis_origin" => {
                "analysis_kind" => "rule_match",
                "step_name" => step_name
              }
            }
          end
        end

        private

        def matched_refs(rule:, source_document_refs:)
          primary_refs = refs_matching(
            source_document_refs,
            compile_patterns(expanded_patterns(rule: rule, pattern_key: "source_patterns", pattern_id_key: "source_pattern_ids"))
          )
          counter_refs = refs_matching(
            source_document_refs,
            compile_patterns(expanded_patterns(rule: rule, pattern_key: "counter_evidence_patterns", pattern_id_key: "counter_evidence_pattern_ids"))
          )
          {
            "source_refs" => (primary_refs + counter_refs).uniq,
            "counter_evidence_refs" => counter_refs
          }
        end

        def refs_matching(source_document_refs, patterns)
          Array(source_document_refs).select do |ref|
            text = load_ref_text(ref)
            next false if text.nil? || text.empty?

            patterns.any? { |pattern| text.match?(pattern) }
          end
        end

        def summarized_rule(rule:, refs:)
          patterns = compile_patterns(
            expanded_patterns(rule: rule, pattern_key: "source_patterns", pattern_id_key: "source_pattern_ids") +
            expanded_patterns(rule: rule, pattern_key: "counter_evidence_patterns", pattern_id_key: "counter_evidence_pattern_ids")
          )
          excerpt = first_matching_excerpt(refs, patterns)
          prefix = rule.fetch("summary_prefix")
          excerpt ? "#{prefix} Evidence excerpt: #{excerpt}" : prefix
        end

        def expanded_patterns(rule:, pattern_key:, pattern_id_key:)
          direct_patterns = Array(rule[pattern_key])
          referenced_patterns = Array(rule[pattern_id_key]).flat_map do |pattern_id|
            lookup_pattern_terms(pattern_id)
          end
          (direct_patterns + referenced_patterns).uniq
        end

        def lookup_pattern_terms(pattern_id)
          entry = pattern_catalog.fetch(pattern_id) do
            raise ArgumentError, "seed pattern not found: #{pattern_id}"
          end
          Array(entry["match_terms"])
        end

        def pattern_catalog
          @pattern_catalog ||= begin
            catalog = asset_loader.seed_pattern_catalog
            entries = Array(catalog["reusable_seed_patterns"]) + Array(catalog["project_accumulated_patterns"])
            entries.each_with_object({}) { |entry, acc| acc[entry.fetch("pattern_id")] = entry }
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

        def compile_patterns(patterns)
          Array(patterns).map { |entry| Regexp.new(entry, Regexp::IGNORECASE) }
        end

        def load_ref_text(ref)
          ref_path = Pathname(ref.to_s.split("#").first)
          absolute_path = if ref_path.absolute?
                            ref_path
                          else
                            primary = repo_root.join(ref_path)
                            primary.exist? ? primary : repo_root.parent.join(ref_path)
                          end
          return nil unless absolute_path.exist?

          absolute_path.read
        end
      end
    end
  end
end
