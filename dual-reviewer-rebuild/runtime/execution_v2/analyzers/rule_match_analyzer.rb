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

        def build_observations(step_name:, step_id:, source_document_refs:, source_document_entries: nil, rule_set:)
          Array(rule_set).each_with_object([]) do |rule, observations|
            refs_payload = matched_refs(
              step_id: step_id,
              rule: rule,
              source_document_refs: source_document_refs,
              source_document_entries: source_document_entries
            )
            source_refs = refs_payload.fetch("source_refs")
            next if source_refs.empty?
            next unless satisfies_evidence_requirements?(rule: rule, refs_payload: refs_payload)

            observation_id = "#{step_id}-observation-#{rule.fetch('finding_suffix')}"

            observations << {
              "observation_id" => observation_id,
              "observation_class" => rule.fetch("observation_class", "rule_matched_observation"),
              "taxonomy_path" => rule["taxonomy_path"],
              "severity" => rule.fetch("severity"),
              "summary" => summarized_rule(rule: rule, refs: source_refs),
              "source_role" => rule.fetch("source_role"),
              "source_refs" => source_refs,
              "counter_evidence_refs" => refs_payload.fetch("counter_evidence_refs"),
              "evidence_record_ids" => refs_payload.fetch("evidence_record_ids"),
              "counter_evidence_record_ids" => refs_payload.fetch("counter_evidence_record_ids"),
              "matched_pattern_ids" => refs_payload.fetch("matched_pattern_ids"),
              "counter_evidence_pattern_ids" => refs_payload.fetch("counter_evidence_pattern_ids"),
              "evidence_types" => refs_payload.fetch("evidence_types"),
              "counter_evidence_types" => refs_payload.fetch("counter_evidence_types"),
              "review_focuses" => refs_payload.fetch("review_focuses"),
              "source_kinds" => refs_payload.fetch("source_kinds"),
              "counter_evidence_source_kinds" => refs_payload.fetch("counter_evidence_source_kinds"),
              "section_classes" => refs_payload.fetch("section_classes"),
              "counter_evidence_section_classes" => refs_payload.fetch("counter_evidence_section_classes"),
              "fragment_classes" => refs_payload.fetch("fragment_classes"),
              "counter_evidence_fragment_classes" => refs_payload.fetch("counter_evidence_fragment_classes"),
              "supporting_pattern_ids" => Array(rule["source_pattern_ids"]),
              "analysis_origin" => {
                "analysis_kind" => "rule_match",
                "step_name" => step_name
              }
            }
          end
        end

        def build_evidence_records(step_id:, source_document_refs:, source_document_entries: nil, rule_set:)
          Array(rule_set).flat_map do |rule|
            refs_payload = matched_refs(
              step_id: step_id,
              rule: rule,
              source_document_refs: source_document_refs,
              source_document_entries: source_document_entries
            )
            refs_payload.fetch("evidence_records")
          end
        end

        def build_findings(step_name:, step_id:, observations:, rule_set:)
          rule_index = Array(rule_set).each_with_object({}) do |rule, acc|
            acc[rule.fetch("finding_suffix")] = rule
          end

          Array(observations).each_with_object([]) do |observation, findings|
            finding_suffix = observation.fetch("observation_id").split("-observation-").last
            rule = rule_index.fetch(finding_suffix)

            findings << {
              "finding_id" => "#{step_id}-#{finding_suffix}",
              "severity" => observation.fetch("severity"),
              "summary" => observation.fetch("summary"),
              "source_role" => observation.fetch("source_role"),
              "source_refs" => observation.fetch("source_refs"),
              "counter_evidence_refs" => observation.fetch("counter_evidence_refs"),
              "failure_observation_refs" => [observation.fetch("observation_id")] + Array(rule["failure_observation_refs"]),
              "analysis_origin" => observation.fetch("analysis_origin")
            }
          end
        end

        private

        def matched_refs(step_id:, rule:, source_document_refs:, source_document_entries: nil)
          primary_pattern_entries = expanded_pattern_entries(rule: rule, pattern_key: "source_patterns", pattern_id_key: "source_pattern_ids")
          counter_pattern_entries = expanded_pattern_entries(rule: rule, pattern_key: "counter_evidence_patterns", pattern_id_key: "counter_evidence_pattern_ids")
          entry_index = normalize_source_entries(source_document_refs, source_document_entries)

          primary_records = evidence_records_matching(
            source_document_refs: source_document_refs,
            source_entry_index: entry_index,
            pattern_entries: primary_pattern_entries
          )
          counter_records = evidence_records_matching(
            source_document_refs: source_document_refs,
            source_entry_index: entry_index,
            pattern_entries: counter_pattern_entries
          )
          structural_primary_records = structural_evidence_records_matching(
            source_document_refs: source_document_refs,
            source_entry_index: entry_index,
            structural_requirements: Array(rule["structural_source_requirements"])
          )
          structural_counter_records = structural_evidence_records_matching(
            source_document_refs: source_document_refs,
            source_entry_index: entry_index,
            structural_requirements: Array(rule["structural_counter_requirements"])
          )
          primary_records.each { |record| record["evidence_side"] = "primary" }
          counter_records.each { |record| record["evidence_side"] = "counter" }
          structural_primary_records.each { |record| record["evidence_side"] = "primary" }
          structural_counter_records.each { |record| record["evidence_side"] = "counter" }
          primary_records.concat(structural_primary_records)
          counter_records.concat(structural_counter_records)
          primary_records = filter_records_by_rule(records: primary_records, rule: rule, side: "primary")
          counter_records = filter_records_by_rule(records: counter_records, rule: rule, side: "counter")
          primary_records = compact_evidence_records(primary_records)
          counter_records = compact_evidence_records(counter_records)
          primary_refs = primary_records.map { |record| record.fetch("source_ref") }.uniq
          counter_refs = counter_records.map { |record| record.fetch("source_ref") }.uniq
          evidence_records = with_evidence_record_ids(
            step_id: step_id,
            finding_suffix: rule.fetch("finding_suffix"),
            records: (primary_records + counter_records).uniq
          )
          primary_evidence_records = evidence_records.select { |record| record["evidence_side"] == "primary" }
          counter_evidence_records = evidence_records.select { |record| record["evidence_side"] == "counter" }
          {
            "source_refs" => (primary_refs + counter_refs).uniq,
            "counter_evidence_refs" => counter_refs,
            "evidence_records" => evidence_records,
            "evidence_record_ids" => primary_evidence_records.map { |record| record["evidence_record_id"] }.uniq,
            "counter_evidence_record_ids" => counter_evidence_records.map { |record| record["evidence_record_id"] }.uniq,
            "matched_pattern_ids" => primary_evidence_records.map { |record| record["pattern_id"] }.compact.uniq,
            "counter_evidence_pattern_ids" => counter_evidence_records.map { |record| record["pattern_id"] }.compact.uniq,
            "evidence_types" => primary_evidence_records.map { |record| record["evidence_type"] }.compact.uniq,
            "counter_evidence_types" => counter_evidence_records.map { |record| record["evidence_type"] }.compact.uniq,
            "review_focuses" => evidence_records.map { |record| record["review_focus"] }.compact.uniq,
            "source_kinds" => primary_evidence_records.map { |record| record["source_kind"] }.compact.uniq,
            "counter_evidence_source_kinds" => counter_evidence_records.map { |record| record["source_kind"] }.compact.uniq,
            "section_classes" => primary_evidence_records.map { |record| record["section_class"] }.compact.uniq,
            "counter_evidence_section_classes" => counter_evidence_records.map { |record| record["section_class"] }.compact.uniq,
            "fragment_classes" => primary_evidence_records.map { |record| record["fragment_class"] }.compact.uniq,
            "counter_evidence_fragment_classes" => counter_evidence_records.map { |record| record["fragment_class"] }.compact.uniq
          }
        end

        def satisfies_evidence_requirements?(rule:, refs_payload:)
          required_evidence_types = Array(rule["required_evidence_types"])
          required_counter_evidence_types = Array(rule["required_counter_evidence_types"])
          required_source_kinds = Array(rule["required_source_kinds"])
          required_counter_source_kinds = Array(rule["required_counter_source_kinds"])
          required_section_classes = Array(rule["required_section_classes"])
          required_counter_section_classes = Array(rule["required_counter_section_classes"])

          return false unless (required_evidence_types - Array(refs_payload["evidence_types"])).empty?
          return false unless (required_counter_evidence_types - Array(refs_payload["counter_evidence_types"])).empty?
          return false unless (required_source_kinds - Array(refs_payload["source_kinds"])).empty?
          return false unless (required_counter_source_kinds - Array(refs_payload["counter_evidence_source_kinds"])).empty?
          return false unless (required_section_classes - Array(refs_payload["section_classes"])).empty?
          return false unless (required_counter_section_classes - Array(refs_payload["counter_evidence_section_classes"])).empty?

          true
        end

        def filter_records_by_rule(records:, rule:, side:)
          section_key = side == "primary" ? "allowed_fragment_classes" : "allowed_counter_fragment_classes"
          allowed_fragment_classes = Array(rule[section_key])
          return Array(records) if allowed_fragment_classes.empty?

          Array(records).select do |record|
            fragment_class = record["fragment_class"]
            fragment_class && allowed_fragment_classes.include?(fragment_class)
          end
        end

        def compact_evidence_records(records)
          Array(records).each_with_object({}) do |record, grouped|
            key = [
              record["source_ref"],
              record["source_kind"],
              record["evidence_side"],
              record["evidence_type"],
              record["review_focus"],
              record["section_heading"],
              record["parent_section_heading"],
              record["fragment_class"],
              record["line_marker"],
              record["bullet_ordinal"],
              Array(record["line_numbers"]).join(",")
            ]

            if grouped.key?(key)
              grouped[key] = merge_evidence_records(grouped[key], record)
            else
              grouped[key] = record
            end
          end.values
        end

        def merge_evidence_records(left, right)
          merged = left.merge(right) do |field, old_value, new_value|
            case field
            when "matched_terms", "line_numbers"
              (Array(old_value) + Array(new_value)).uniq
            when "pattern_id"
              old_value || new_value
            when "matched_excerpt"
              old_value.to_s.length >= new_value.to_s.length ? old_value : new_value
            when "structural_support"
              old_value || new_value
            else
              old_value
            end
          end

          merged["first_line_number"] = [left["first_line_number"], right["first_line_number"]].compact.min
          merged
        end

        def with_evidence_record_ids(step_id:, finding_suffix:, records:)
          Array(records).map.with_index do |record, index|
            record.merge("evidence_record_id" => "#{step_id}-evidence-#{finding_suffix}-#{index + 1}")
          end
        end

        def normalize_source_entries(source_document_refs, source_document_entries)
          return Array(source_document_entries).each_with_object({}) { |entry, acc| acc[entry.fetch("ref")] = entry } if source_document_entries

          Array(source_document_refs).each_with_object({}) do |ref, acc|
            acc[ref] = { "ref" => ref, "source_kind" => "unknown" }
          end
        end

        def refs_matching(source_document_refs, patterns)
          Array(source_document_refs).select do |ref|
            text = load_ref_text(ref)
            next false if text.nil? || text.empty?

            patterns.any? { |pattern| text.match?(pattern) }
          end
        end

        def evidence_records_matching(source_document_refs:, source_entry_index:, pattern_entries:)
          patterns = pattern_entries.map { |entry| [entry, Regexp.new(entry.fetch("term"), Regexp::IGNORECASE)] }

          Array(source_document_refs).flat_map do |ref|
            text = load_ref_text(ref)
            next [] if text.nil? || text.empty?

            source_kind = source_entry_index.fetch(ref, {})["source_kind"]
            structured_evidence_records(
              ref: ref,
              source_kind: source_kind,
              text: text,
              patterns: patterns
            )
          end
        end

        def structured_evidence_records(ref:, source_kind:, text:, patterns:)
          current_heading = nil
          current_parent_heading = nil
          heading_stack = []
          current_section_class = nil
          bullet_ordinal = 0
          grouped = {}

          text.lines.each_with_index do |line, index|
            heading = extract_heading(line)
            if heading
              heading_stack = heading_stack.take_while { |entry| entry.fetch("level") < heading.fetch("level") }
              current_parent_heading = heading_stack.last&.fetch("text")
              heading_stack << heading
              current_heading = heading.fetch("text")
              current_section_class = classify_section(ref: ref, source_kind: source_kind, section_heading: current_heading)
              bullet_ordinal = 0
              next
            end

            next if current_heading.nil?

            stripped = line.strip
            next if stripped.empty?

            line_marker = extract_line_marker(stripped)
            bullet_ordinal += 1 if line_marker == "-"
            current_bullet_ordinal = (line_marker == "-" ? bullet_ordinal : nil)
            fragment_class = classify_fragment_for_entry(
              source_kind: source_kind,
              section_heading: current_heading,
              section_class: current_section_class,
              parent_section_heading: current_parent_heading,
              line: stripped,
              line_marker: line_marker,
              bullet_ordinal: current_bullet_ordinal,
              review_focus: nil,
              evidence_type: nil
            )

            patterns.each do |entry, pattern|
              next unless line.match?(pattern)

              record_key = [
                ref,
                source_kind,
                entry["evidence_type"] || entry["pattern_id"] || entry.fetch("term"),
                current_heading || "line-#{index + 1}",
                fragment_class,
                line_marker,
                current_bullet_ordinal
              ]

              grouped[record_key] ||= {
                "evidence_record_id" => nil,
                "source_ref" => ref,
                "source_kind" => source_kind,
                "evidence_side" => nil,
                "pattern_id" => entry["pattern_id"],
                "evidence_type" => entry["evidence_type"],
                "review_focus" => entry["review_focus"],
                "section_heading" => current_heading,
                "parent_section_heading" => current_parent_heading,
                "section_class" => current_section_class,
                "fragment_class" => classify_fragment_for_entry(
                  source_kind: source_kind,
                  section_heading: current_heading,
                  section_class: current_section_class,
                  parent_section_heading: current_parent_heading,
                  line: stripped,
                  line_marker: line_marker,
                  bullet_ordinal: current_bullet_ordinal,
                  review_focus: entry["review_focus"],
                  evidence_type: entry["evidence_type"]
                ),
                "line_marker" => line_marker,
                "bullet_ordinal" => current_bullet_ordinal,
                "first_line_number" => index + 1,
                "line_numbers" => [],
                "matched_terms" => [],
                "matched_excerpt" => stripped
              }

              grouped_record = grouped[record_key]
              grouped_record["line_numbers"] << (index + 1)
              grouped_record["matched_terms"] << entry.fetch("term")
              grouped_record["line_numbers"].uniq!
              grouped_record["matched_terms"].uniq!
            end
          end

          grouped.values
        end

        def structural_evidence_records_matching(source_document_refs:, source_entry_index:, structural_requirements:)
          Array(source_document_refs).flat_map do |ref|
            text = load_ref_text(ref)
            next [] if text.nil? || text.empty?

            source_kind = source_entry_index.fetch(ref, {})["source_kind"]
            fragments = extract_structural_fragments(text: text, ref: ref, source_kind: source_kind)

            Array(structural_requirements).flat_map do |requirement|
              next [] unless requirement.fetch("source_kind", source_kind) == source_kind

              matching_fragments = fragments.select do |fragment|
                next false unless fragment.fetch("section_class") == requirement["section_class"]

                required_fragment_class = requirement["fragment_class"]
                next false unless required_fragment_class.nil? || fragment["fragment_class"] == required_fragment_class

                section_heading_patterns = Array(requirement["section_heading_patterns"])
                if !section_heading_patterns.empty?
                  current_heading = fragment["section_heading"].to_s
                  next false unless section_heading_patterns.any? { |pattern| current_heading.match?(Regexp.new(pattern, Regexp::IGNORECASE)) }
                end

                parent_heading_patterns = Array(requirement["parent_heading_patterns"])
                if !parent_heading_patterns.empty?
                  parent_heading = fragment["parent_section_heading"].to_s
                  next false unless parent_heading_patterns.any? { |pattern| parent_heading.match?(Regexp.new(pattern, Regexp::IGNORECASE)) }
                end

                line_prefix_patterns = Array(requirement["line_prefix_patterns"])
                if !line_prefix_patterns.empty?
                  marker = fragment["line_marker"].to_s
                  next false unless line_prefix_patterns.any? { |pattern| marker.match?(Regexp.new(pattern, Regexp::IGNORECASE)) }
                end

                bullet_ordinals = Array(requirement["bullet_ordinals"])
                if !bullet_ordinals.empty?
                  next false unless bullet_ordinals.map(&:to_i).include?(fragment["bullet_ordinal"].to_i)
                end

                true
              end

              matching_fragments.map do |fragment|
                {
                  "evidence_record_id" => nil,
                  "source_ref" => ref,
                  "source_kind" => source_kind,
                  "evidence_side" => nil,
                  "pattern_id" => requirement["pattern_id"],
                  "evidence_type" => requirement["evidence_type"],
                  "review_focus" => requirement["review_focus"],
                  "section_heading" => fragment["section_heading"],
                  "parent_section_heading" => fragment["parent_section_heading"],
                  "section_class" => fragment["section_class"],
                  "fragment_class" => fragment["fragment_class"],
                  "line_marker" => fragment["line_marker"],
                  "bullet_ordinal" => fragment["bullet_ordinal"],
                  "first_line_number" => fragment["first_line_number"],
                  "line_numbers" => fragment["line_numbers"],
                  "matched_terms" => [],
                  "matched_excerpt" => fragment["matched_excerpt"],
                  "structural_support" => true
                }
              end
            end
          end
        end

        def extract_structural_fragments(text:, ref:, source_kind:)
          current_heading = nil
          current_parent_heading = nil
          current_section_class = nil
          heading_stack = []
          fragments = []
          current_fragment = nil
          bullet_ordinal = 0

          text.lines.each_with_index do |line, index|
            heading = extract_heading(line)
            if heading
              heading_stack = heading_stack.take_while { |entry| entry.fetch("level") < heading.fetch("level") }
              current_parent_heading = heading_stack.last&.fetch("text")
              heading_stack << heading
              current_heading = heading.fetch("text")
              current_section_class = classify_section(ref: ref, source_kind: source_kind, section_heading: current_heading)
              current_fragment = nil
              bullet_ordinal = 0
              next
            end

            next if current_heading.nil?

            stripped = line.strip
            next if stripped.empty?

            line_marker = extract_line_marker(stripped)
            if line_marker.nil? && !current_fragment.nil?
              current_fragment["line_numbers"] << (index + 1)
              current_fragment["matched_excerpt"] = [current_fragment["matched_excerpt"], stripped].join(" ").strip
              next
            end

            bullet_ordinal += 1 if line_marker == "-"

            current_fragment = {
              "section_heading" => current_heading,
              "parent_section_heading" => current_parent_heading,
              "section_class" => current_section_class,
              "fragment_class" => classify_fragment(
                source_kind: source_kind,
                section_heading: current_heading,
                section_class: current_section_class,
                parent_section_heading: current_parent_heading,
                line: stripped,
                line_marker: line_marker,
                bullet_ordinal: (line_marker == "-" ? bullet_ordinal : nil)
              ),
              "line_marker" => line_marker,
              "bullet_ordinal" => (line_marker == "-" ? bullet_ordinal : nil),
              "first_line_number" => index + 1,
              "line_numbers" => [index + 1],
              "matched_excerpt" => stripped
            }
            fragments << current_fragment
          end

          fragments
        end

        def extract_heading(line)
          stripped = line.strip
          return nil unless stripped.start_with?("#")

          marker = stripped[/\A#+/]
          {
            "level" => marker.length,
            "text" => stripped.sub(/^#+\s*/, "")
          }
        end

        def extract_line_marker(line)
          match = line.match(/\A(\d+)\./)
          return match[1] unless match.nil?

          return "-" if line.match?(/\A-\s+/)

          nil
        end

        def classify_section(ref:, source_kind:, section_heading:)
          heading = section_heading.to_s
          basename = Pathname(ref).basename.to_s

          if heading.match?(/Acceptance Criteria/i)
            "acceptance_criteria"
          elsif heading.match?(/Boundary Context/i)
            "boundary_context"
          elsif heading.match?(/Directory Structure/i)
            "directory_structure"
          elsif heading.match?(/Numerical Engine/i)
            "numerical_engine_design"
          elsif heading.match?(/Why This Snapshot/i)
            "snapshot_rationale"
          elsif heading.match?(/Fixed Snapshot ID/i)
            "snapshot_identity"
          elsif basename == "phase-field-implementation-phase-first-snapshot.md"
            "implementation_snapshot_note"
          elsif source_kind == "implementation_snapshot"
            "implementation_snapshot_misc"
          elsif source_kind == "upstream_spec"
            "upstream_spec_misc"
          else
            nil
          end
        end

        def classify_fragment(source_kind:, section_heading:, section_class:, parent_section_heading:, line:, line_marker:, bullet_ordinal:)
          classify_fragment_for_entry(
            source_kind: source_kind,
            section_heading: section_heading,
            section_class: section_class,
            parent_section_heading: parent_section_heading,
            line: line,
            line_marker: line_marker,
            bullet_ordinal: bullet_ordinal,
            review_focus: nil,
            evidence_type: nil
          )
        end

        def classify_fragment_for_entry(source_kind:, section_heading:, section_class:, parent_section_heading:, line:, line_marker:, bullet_ordinal:, review_focus:, evidence_type:)
          fragment_cue_catalog.each do |cue|
            next unless cue.fetch("source_kind", source_kind) == source_kind
            next if cue["section_heading_patterns"] && !Array(cue["section_heading_patterns"]).any? { |pattern| section_heading.to_s.match?(Regexp.new(pattern, Regexp::IGNORECASE)) }
            next if cue["section_class"] && cue["section_class"] != section_class
            next if !review_focus.nil? && cue["review_focus"] && cue["review_focus"] != review_focus
            next if !evidence_type.nil? && cue["evidence_type"] && cue["evidence_type"] != evidence_type

            parent_heading_patterns = Array(cue["parent_heading_patterns"])
            if !parent_heading_patterns.empty?
              parent_heading = parent_section_heading.to_s
              next unless parent_heading_patterns.any? { |pattern| parent_heading.match?(Regexp.new(pattern, Regexp::IGNORECASE)) }
            end

            line_prefix_patterns = Array(cue["line_prefix_patterns"])
            if !line_prefix_patterns.empty?
              marker = line_marker.to_s
              next unless line_prefix_patterns.any? { |pattern| marker.match?(Regexp.new(pattern, Regexp::IGNORECASE)) }
            end

            cue_bullet_ordinals = Array(cue["bullet_ordinals"])
            if !cue_bullet_ordinals.empty?
              next unless cue_bullet_ordinals.map(&:to_i).include?(bullet_ordinal.to_i)
            end

            patterns = Array(cue["match_terms"]).map { |term| Regexp.new(term, Regexp::IGNORECASE) }
            next unless patterns.empty? || patterns.any? { |pattern| line.match?(pattern) }

            return cue["fragment_class"]
          end

          nil
        end

        def summarized_rule(rule:, refs:)
          patterns = compile_patterns(
            expanded_pattern_entries(rule: rule, pattern_key: "source_patterns", pattern_id_key: "source_pattern_ids").map { |entry| entry.fetch("term") } +
            expanded_pattern_entries(rule: rule, pattern_key: "counter_evidence_patterns", pattern_id_key: "counter_evidence_pattern_ids").map { |entry| entry.fetch("term") }
          )
          excerpt = first_matching_excerpt(refs, patterns)
          prefix = rule.fetch("summary_prefix")
          excerpt ? "#{prefix} Evidence excerpt: #{excerpt}" : prefix
        end

        def expanded_pattern_entries(rule:, pattern_key:, pattern_id_key:)
          direct_patterns = Array(rule[pattern_key]).map do |term|
            {
              "term" => term,
              "pattern_id" => nil,
              "evidence_type" => nil,
              "review_focus" => nil
            }
          end
          referenced_patterns = Array(rule[pattern_id_key]).flat_map do |pattern_id|
            lookup_pattern_entries(pattern_id)
          end
          (direct_patterns + referenced_patterns).uniq
        end

        def lookup_pattern_entries(pattern_id)
          entry = pattern_catalog.fetch(pattern_id) do
            raise ArgumentError, "seed pattern not found: #{pattern_id}"
          end
          Array(entry["match_terms"]).map do |term|
            {
              "term" => term,
              "pattern_id" => pattern_id,
              "evidence_type" => entry["evidence_type"],
              "review_focus" => entry["review_focus"]
            }
          end
        end

        def pattern_catalog
          @pattern_catalog ||= begin
            catalog = asset_loader.seed_pattern_catalog
            entries = Array(catalog["reusable_seed_patterns"]) + Array(catalog["project_accumulated_patterns"])
            entries.each_with_object({}) { |entry, acc| acc[entry.fetch("pattern_id")] = entry }
          end
        end

        def fragment_cue_catalog
          @fragment_cue_catalog ||= Array(asset_loader.seed_pattern_catalog["reusable_fragment_cues"])
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
