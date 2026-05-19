#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

# Requirement 9 受入 5・3: 独立再導出 validator 拡張モード（design 小節 7）。
# `--rederive <process_id> [--repo-root P] [--date D] [--ledger PATH]`。
# 終了コード 0=pass、非0=不適合/検査不能（fail-closed と一致）。
# 引数なしの既存検査は不変（後方互換）。
if ARGV.include?("--rederive")
  require_relative "governance/independent_rederivation"

  def opt(flag)
    i = ARGV.index(flag)
    i && ARGV[i + 1]
  end

  process_id = opt("--rederive")
  repo = Pathname(opt("--repo-root") || Pathname(__dir__).join("..").expand_path)
  begin
    validator = Governance::RederivationValidator.new(repo_root: repo)
    outcome = validator.validate(process_id: process_id, date: opt("--date"),
                                 ledger_path: opt("--ledger"))
    outcome.lines.each { |l| puts l }
    if outcome.ok
      puts "result=pass reason=#{outcome.reason}"
      exit 0
    else
      puts "result=fail reason=#{outcome.reason}"
      exit 1
    end
  rescue Governance::FailClosed => e
    puts "result=fail reason=#{e.message}"
    exit 1
  end
end

repo_root = Pathname(__dir__).join("..").expand_path

required_files = [
  "docs/coordination/implementation-conformance-review.md",
  "docs/coordination/implementation-conformance-metric-register.md",
  "docs/coordination/phase-review-metric-register.md",
  "docs/coordination/workflow-gate-status.md",
  "docs/alignment/cross-spec-implementation-governance-alignment.md",
  "docs/reviews/templates/intent-review-template.md",
  "docs/reviews/templates/implementation-conformance-review-template.md",
  "docs/reviews/2026-05-09-intent-baseline-review.md",
  "docs/reviews/2026-05-09-prototype-shelf-review.md"
]

missing_files = required_files.reject { |relative| repo_root.join(relative).exist? }
raise "missing governance artifacts: #{missing_files.join(', ')}" unless missing_files.empty?

review_artifact = repo_root.join("docs/reviews/2026-05-09-prototype-shelf-review.md").read(encoding: "UTF-8")
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

intent_review_artifact = repo_root.join("docs/reviews/2026-05-09-intent-baseline-review.md").read(encoding: "UTF-8")
required_intent_sections = [
  "## 1. review scope",
  "## 2. findings",
  "## 3. metric snapshot",
  "## 4. disposition summary"
]
missing_intent_sections = required_intent_sections.reject { |section| intent_review_artifact.include?(section) }
raise "intent review artifact missing sections: #{missing_intent_sections.join(', ')}" unless missing_intent_sections.empty?

required_intent_metric_keys = [
  "`intent_revision_count`",
  "`intent_handback_count`",
  "`intent_review_findings_count`",
  "`review_artifact_presence_rate`"
]
missing_intent_metric_keys = required_intent_metric_keys.reject { |key| intent_review_artifact.include?(key) }
raise "intent review artifact missing metric keys: #{missing_intent_metric_keys.join(', ')}" unless missing_intent_metric_keys.empty?

template = repo_root.join("docs/reviews/templates/implementation-conformance-review-template.md").read(encoding: "UTF-8")
missing_template_keys = required_metric_keys.reject { |key| template.include?(key) }
raise "review template missing metric keys: #{missing_template_keys.join(', ')}" unless missing_template_keys.empty?

intent_template = repo_root.join("docs/reviews/templates/intent-review-template.md").read(encoding: "UTF-8")
missing_intent_template_keys = required_intent_metric_keys.reject { |key| intent_template.include?(key) }
raise "intent review template missing metric keys: #{missing_intent_template_keys.join(', ')}" unless missing_intent_template_keys.empty?

procedure = repo_root.join("docs/coordination/implementation-conformance-review.md").read(encoding: "UTF-8")
raise "procedure doc missing completion rule" unless procedure.include?("## 10. completion rule")

metric_register = repo_root.join("docs/coordination/implementation-conformance-metric-register.md").read(encoding: "UTF-8")
raise "metric register missing baseline snapshot section" unless metric_register.include?("## 4. current baseline snapshot")

phase_metric_register = repo_root.join("docs/coordination/phase-review-metric-register.md").read(encoding: "UTF-8")
required_phase_metric_terms = [
  "`intent_revision_count`",
  "`intent_handback_count`",
  "`phase_intent_attributed_issue_count`"
]
missing_phase_metric_terms = required_phase_metric_terms.reject { |term| phase_metric_register.include?(term) }
raise "phase-review metric register missing required terms: #{missing_phase_metric_terms.join(', ')}" unless missing_phase_metric_terms.empty?

workflow_gate_status = repo_root.join("docs/coordination/workflow-gate-status.md").read(encoding: "UTF-8")
required_status_terms = [
  "`completed_with_open_findings`",
  "implementation conformance review",
  "Open finding backlog status"
]
missing_status_terms = required_status_terms.reject { |term| workflow_gate_status.include?(term) }
raise "workflow gate status missing required terms: #{missing_status_terms.join(', ')}" unless missing_status_terms.empty?

alignment_memo = repo_root.join("docs/alignment/cross-spec-implementation-governance-alignment.md").read(encoding: "UTF-8")
required_alignment_sections = [
  "## 1. 目的",
  "## 2. 確認した論点",
  "## 6. gate result",
  "## 7. 次の正しい作業"
]
missing_alignment_sections = required_alignment_sections.reject { |section| alignment_memo.include?(section) }
raise "alignment memo missing sections: #{missing_alignment_sections.join(', ')}" unless missing_alignment_sections.empty?

puts "implementation governance artifact validation passed"
