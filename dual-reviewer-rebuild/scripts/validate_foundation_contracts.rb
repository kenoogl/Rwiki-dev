#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"

ROOT = Pathname(__dir__).join("..").expand_path

def load_json(relative_path)
  JSON.parse(ROOT.join(relative_path).read)
end

def load_yaml(relative_path)
  YAML.load_file(ROOT.join(relative_path))
end

def assert(condition, message)
  raise message unless condition
end

def assert_required_fields!(object, required_fields, label)
  missing = required_fields.reject { |field| object.key?(field) }
  assert(missing.empty?, "#{label} missing required fields: #{missing.join(', ')}")
end

def parse_frontmatter(relative_path)
  text = ROOT.join(relative_path).read
  match = text.match(/\A---\n(.*?)\n---\n/m)
  raise "frontmatter not found in #{relative_path}" unless match

  YAML.safe_load(match[1], permitted_classes: [], aliases: false)
end

def schema_parse_check!
  schema_paths = Dir[ROOT.join("runtime/schemas/*.json").to_s] +
                 Dir[ROOT.join("runtime/validators/contracts/*.json").to_s]
  assert(!schema_paths.empty?, "schema paths not found")

  schema_paths.each do |path|
    JSON.parse(File.read(path))
  end
end

def metadata_required_fields_smoke_test!
  metadata_contract = load_yaml("runtime/foundation/metadata_contract.yaml")
  review_case = load_json("tests/fixtures/foundation/review_case.minimal.json")
  required_fields = metadata_contract.fetch("required_fields")

  assert_required_fields!(review_case.fetch("metadata"), required_fields, "review_case.metadata")
end

def fixture_required_fields_smoke_test!
  review_case_schema = load_json("runtime/schemas/review_case.schema.json")
  finding_schema = load_json("runtime/schemas/finding.schema.json")
  validator_result_schema = load_json("runtime/validators/contracts/validator_result.schema.json")
  invalidation_marker_schema = load_json("runtime/validators/contracts/invalidation_marker.schema.json")

  review_case = load_json("tests/fixtures/foundation/review_case.minimal.json")
  finding = load_json("tests/fixtures/foundation/finding.minimal.json")
  validator_result = load_json("tests/fixtures/foundation/validator_result.minimal.json")
  invalidation_marker = load_json("tests/fixtures/foundation/invalidation_marker.minimal.json")

  assert_required_fields!(review_case, review_case_schema.fetch("required"), "review_case fixture")
  assert_required_fields!(finding, finding_schema.fetch("required"), "finding fixture")
  assert_required_fields!(validator_result, validator_result_schema.fetch("required"), "validator_result fixture")
  assert_required_fields!(invalidation_marker, invalidation_marker_schema.fetch("required"), "invalidation_marker fixture")
end

def prompt_frontmatter_smoke_test!
  frontmatter_contract = load_yaml("runtime/prompts/shared/frontmatter_contract.yaml")
  prompt_frontmatter = parse_frontmatter("runtime/prompts/judgment/judgment_reviewer.prompt.md")

  assert_required_fields!(prompt_frontmatter, frontmatter_contract.fetch("required_fields"), "judgment prompt frontmatter")
  assert(prompt_frontmatter["role"] == "judgment_reviewer", "judgment prompt role must be judgment_reviewer")
  assert(prompt_frontmatter["step"] == "judgment", "judgment prompt step must be judgment")
end

def review_mode_consistency_smoke_test!
  metadata_contract = load_yaml("runtime/foundation/metadata_contract.yaml")
  review_mode_vocab = load_yaml("runtime/validators/contracts/review_mode_vocab.yaml")
  validator_result = load_json("tests/fixtures/foundation/validator_result.minimal.json")
  review_case = load_json("tests/fixtures/foundation/review_case.minimal.json")

  metadata_modes = metadata_contract.fetch("enum_definitions").fetch("review_mode")
  vocab_modes = review_mode_vocab.fetch("review_modes").map { |entry| entry.fetch("mode") }

  assert(metadata_modes.sort == vocab_modes.sort, "review_mode vocabulary must match metadata contract enum")
  assert(vocab_modes.include?(validator_result.fetch("review_mode")), "validator_result fixture review_mode must be in vocabulary")
  assert(vocab_modes.include?(review_case.fetch("metadata").fetch("review_mode")), "review_case fixture review_mode must be in vocabulary")
end

schema_parse_check!
metadata_required_fields_smoke_test!
fixture_required_fields_smoke_test!
prompt_frontmatter_smoke_test!
review_mode_consistency_smoke_test!

puts "foundation contract validation passed"
