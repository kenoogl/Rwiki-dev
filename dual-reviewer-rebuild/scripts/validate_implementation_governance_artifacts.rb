#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

repo_root = Pathname(__dir__).join("..").expand_path

required_files = [
  "docs/coordination/implementation-conformance-review.md",
  "docs/coordination/implementation-conformance-metric-register.md",
  "docs/coordination/workflow-gate-status.md",
  "docs/alignment/cross-spec-implementation-governance-alignment.md",
  "docs/reviews/templates/implementation-conformance-review-template.md",
  "docs/reviews/2026-05-09-prototype-shelf-review.md"
]

missing_files = required_files.reject { |relative| repo_root.join(relative).exist? }
raise "missing governance artifacts: #{missing_files.join(', ')}" unless missing_files.empty?

review_artifact = repo_root.join("docs/reviews/2026-05-09-prototype-shelf-review.md").read
required_sections = [
  "## 1. review scope",
  "## 2. validation rerun",
  "## 3. findings",
  "## 4. metric snapshot",
  "## 5. disposition summary"
]
missing_sections = required_sections.reject { |section| review_artifact.include?(section) }
raise "review artifact missing sections: #{missing_sections.join(', ')}" unless missing_sections.empty?

required_metric_keys = [
  "`conformance_findings_count`",
  "`severity_weighted_finding_score`",
  "`post_smoke_nonconformance_count`",
  "`fixture_bound_resolution_count`",
  "`heuristic_linkage_count`",
  "`review_artifact_presence_rate`",
  "`finding_to_signal_link_rate`"
]
missing_metric_keys = required_metric_keys.reject { |key| review_artifact.include?(key) }
raise "review artifact missing metric keys: #{missing_metric_keys.join(', ')}" unless missing_metric_keys.empty?

template = repo_root.join("docs/reviews/templates/implementation-conformance-review-template.md").read
missing_template_keys = required_metric_keys.reject { |key| template.include?(key) }
raise "review template missing metric keys: #{missing_template_keys.join(', ')}" unless missing_template_keys.empty?

procedure = repo_root.join("docs/coordination/implementation-conformance-review.md").read
raise "procedure doc missing completion rule" unless procedure.include?("## 10. completion rule")

metric_register = repo_root.join("docs/coordination/implementation-conformance-metric-register.md").read
raise "metric register missing baseline snapshot section" unless metric_register.include?("## 4. current baseline snapshot")

workflow_gate_status = repo_root.join("docs/coordination/workflow-gate-status.md").read
required_status_terms = [
  "`completed_with_open_findings`",
  "implementation conformance review",
  "Open finding backlog status"
]
missing_status_terms = required_status_terms.reject { |term| workflow_gate_status.include?(term) }
raise "workflow gate status missing required terms: #{missing_status_terms.join(', ')}" unless missing_status_terms.empty?

alignment_memo = repo_root.join("docs/alignment/cross-spec-implementation-governance-alignment.md").read
required_alignment_sections = [
  "## 1. 目的",
  "## 2. 確認した論点",
  "## 6. gate result",
  "## 7. 次の正しい作業"
]
missing_alignment_sections = required_alignment_sections.reject { |section| alignment_memo.include?(section) }
raise "alignment memo missing sections: #{missing_alignment_sections.join(', ')}" unless missing_alignment_sections.empty?

puts "implementation governance artifact validation passed"
