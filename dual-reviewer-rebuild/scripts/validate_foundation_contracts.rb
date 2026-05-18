#!/usr/bin/env ruby
# frozen_string_literal: true

# dual-reviewer-foundation 機械検証（design「Test Strategy」準拠）
# foundation は実行コードを持たず、成果物の静的検証に限定する。
# 外部依存なし（gem 不使用）。CI でも手動でも同一基準（exit 0=pass / 非0=fail）。
# テスト本体は tests/foundation/test_foundation_contracts.rb と同一基準。

require "json"
require "yaml"
require "pathname"

ROOT = Pathname(__dir__).join("..").expand_path # dual-reviewer-rebuild/
errors = []

schema_files = %w[
  runtime/schemas/review_case.schema.json
  runtime/schemas/finding.schema.json
  runtime/schemas/impact_score.schema.json
  runtime/schemas/failure_observation.schema.json
  runtime/schemas/necessity_judgment.schema.json
  runtime/validators/contracts/validator_result.schema.json
  runtime/validators/contracts/invalidation_marker.schema.json
]
schema_files.each do |rel|
  path = ROOT + rel
  unless path.exist?
    errors << "schema 欠落: #{rel}"
    next
  end
  begin
    doc = JSON.parse(path.read(encoding: "UTF-8"))
    errors << "#{rel}: $schema 宣言なし" unless doc.key?("$schema")
    unless doc.key?("type") || doc.key?("properties") || doc.key?("definitions")
      errors << "#{rel}: JSON Schema 構造なし"
    end
  rescue JSON::ParserError => e
    errors << "#{rel}: JSON 解析不可: #{e.message}"
  end
end

%w[
  runtime/patterns
  runtime/validators/contracts/review_mode_vocab.yaml
  runtime/prompts/primary runtime/prompts/adversarial
  runtime/prompts/integration runtime/prompts/shared
].each { |rel| errors << "旧資産が残存: #{rel}" if (ROOT + rel).exist? }

fw = ROOT + "runtime/foundation/layer1_framework.yaml"
if fw.exist?
  doc = YAML.safe_load(fw.read(encoding: "UTF-8"))
  %w[version roles step_pipeline step_intents required_metadata_refs asset_locations].each do |k|
    errors << "layer1_framework.yaml: 必須 section 欠落: #{k}" unless doc.key?(k)
  end
else
  errors << "layer1_framework.yaml 欠落"
end

mc = ROOT + "runtime/foundation/metadata_contract.yaml"
if mc.exist?
  doc = YAML.safe_load(mc.read(encoding: "UTF-8"))
  fields = doc["fields"] || {}
  %w[
    run_id target_id target_artifact_hash source_repository_id source_revision
    phase_profile treatment review_mode protocol_version runtime_version
    schema_set_version prompt_set_version config_version config_hash run_status
    validator_status human_signoff_status evidence_class started_at closed_at
  ].each { |f| errors << "metadata 必須 field 欠落: #{f}" unless fields.key?(f) }
  expect = {
    "run_status" => %w[created in_progress closed orchestration_failed],
    "validator_status" => %w[not_run passed failed blocked],
    "human_signoff_status" => %w[pending approved rejected deferred],
    "evidence_class" => %w[candidate valid invalid exploratory]
  }
  expect.each do |f, en|
    errors << "metadata enum 不一致: #{f}" unless fields.dig(f, "enum") == en
  end
else
  errors << "metadata_contract.yaml 欠落"
end

{
  "runtime/prompts/primary_detection/primary_reviewer.prompt.md" => "primary_reviewer",
  "runtime/prompts/adversarial_review/adversarial_reviewer.prompt.md" => "adversarial_reviewer",
  "runtime/prompts/judgment/judgment_reviewer.prompt.md" => "judgment_reviewer"
}.each do |rel, role|
  path = ROOT + rel
  unless path.exist?
    errors << "prompt 欠落: #{rel}"
    next
  end
  text = path.read(encoding: "UTF-8")
  fm = YAML.safe_load(text.split(/^---\s*$/)[1].to_s)
  unless fm.is_a?(Hash)
    errors << "#{rel}: frontmatter 解析不可"
    next
  end
  %w[prompt_id version role step language source_ref].each do |k|
    errors << "#{rel}: frontmatter 必須 field 欠落: #{k}" unless fm.key?(k)
  end
  errors << "#{rel}: role 不一致" unless fm["role"] == role
end

%w[runtime/config/config.yaml.template runtime/config/terminology.yaml.template].each do |rel|
  path = ROOT + rel
  if path.exist?
    begin
      YAML.safe_load(path.read(encoding: "UTF-8"))
    rescue StandardError => e
      errors << "#{rel}: YAML 解析不可: #{e.message}"
    end
  else
    errors << "template 欠落: #{rel}"
  end
end

if errors.empty?
  puts "foundation contract validation passed"
  exit 0
else
  warn "foundation contract validation FAILED:"
  errors.each { |e| warn "  - #{e}" }
  exit 1
end
