# frozen_string_literal: true

require "minitest/autorun"
require "json"
require "yaml"
require "pathname"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# dual-reviewer-foundation 機械検証（design「Test Strategy」準拠）
# foundation は実行コードを持たず、成果物の静的検証に限定する。
# 外部依存なし（gem 不使用）・repo 内で完結。
class TestFoundationContracts < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  SCHEMA_FILES = %w[
    runtime/schemas/review_case.schema.json
    runtime/schemas/finding.schema.json
    runtime/schemas/impact_score.schema.json
    runtime/schemas/failure_observation.schema.json
    runtime/schemas/necessity_judgment.schema.json
    runtime/validators/contracts/validator_result.schema.json
    runtime/validators/contracts/invalidation_marker.schema.json
  ].freeze

  # スキーマ整合：7 schema が JSON として解析でき、JSON Schema の最小構造
  # （$schema 宣言＋type/properties）を満たす
  def test_schema_files_are_valid_json_schema
    SCHEMA_FILES.each do |rel|
      path = ROOT + rel
      assert path.exist?, "schema 欠落: #{rel}"
      doc = JSON.parse(path.read)
      assert doc.key?("$schema"), "#{rel}: $schema 宣言なし"
      assert(doc.key?("type") || doc.key?("properties") || doc.key?("definitions"),
             "#{rel}: JSON Schema 構造（type/properties/definitions）なし")
    end
  end

  # 旧 Requirement 5 資産・旧命名が存在しないこと（スクラッチ適合）
  def test_deleted_legacy_assets_absent
    %w[
      runtime/patterns
      runtime/validators/contracts/review_mode_vocab.yaml
      runtime/prompts/primary runtime/prompts/adversarial
      runtime/prompts/integration runtime/prompts/shared
    ].each { |rel| refute (ROOT + rel).exist?, "旧資産が残存: #{rel}" }
  end

  # framework 整合：layer1_framework.yaml の必須 top-level section
  def test_layer1_framework_required_sections
    path = ROOT + "runtime/foundation/layer1_framework.yaml"
    assert path.exist?, "layer1_framework.yaml 欠落"
    doc = YAML.safe_load(path.read)
    %w[version roles step_pipeline step_intents required_metadata_refs asset_locations].each do |k|
      assert doc.key?(k), "layer1_framework.yaml: 必須 section 欠落: #{k}"
    end
    flat = doc.to_s
    refute_match(/intent|requirements|design|tasks/i, doc["step_pipeline"].to_s,
                 "phase/profile 値語彙を列挙してはならない")
    refute_match(/single|dual\+judgment/, flat.gsub("judgment_reviewer", ""),
                 "treatment 値語彙を列挙してはならない")
  end

  # metadata 整合：必須 field と各 enum（blocked / exploratory を含む）
  def test_metadata_contract_fields_and_enums
    path = ROOT + "runtime/foundation/metadata_contract.yaml"
    assert path.exist?, "metadata_contract.yaml 欠落"
    doc = YAML.safe_load(path.read)
    fields = doc.fetch("fields")
    required = %w[
      run_id target_id target_artifact_hash source_repository_id source_revision
      phase_profile treatment review_mode protocol_version runtime_version
      schema_set_version prompt_set_version config_version config_hash run_status
      validator_status human_signoff_status evidence_class started_at closed_at
    ]
    required.each { |f| assert fields.key?(f), "metadata 必須 field 欠落: #{f}" }
    assert_equal %w[created in_progress closed orchestration_failed],
                 fields["run_status"]["enum"]
    assert_equal %w[not_run passed failed blocked], fields["validator_status"]["enum"]
    assert_equal %w[pending approved rejected deferred],
                 fields["human_signoff_status"]["enum"]
    assert_equal %w[candidate valid invalid exploratory], fields["evidence_class"]["enum"]
    rm = fields["review_mode"]["enum"]
    assert_includes rm, "manual_dogfooding"
    assert_includes rm, "runtime_mediated"
  end

  # prompt 整合：Step A/B/C 正本が存在し frontmatter 必須 field を持つ
  def test_prompt_artifacts_frontmatter
    {
      "runtime/prompts/primary_detection/primary_reviewer.prompt.md" => "primary_reviewer",
      "runtime/prompts/adversarial_review/adversarial_reviewer.prompt.md" => "adversarial_reviewer",
      "runtime/prompts/judgment/judgment_reviewer.prompt.md" => "judgment_reviewer"
    }.each do |rel, role|
      path = ROOT + rel
      assert path.exist?, "prompt 欠落: #{rel}"
      text = path.read
      assert_match(/\A---\n/, text, "#{rel}: frontmatter 開始なし")
      fm = YAML.safe_load(text.split(/^---\s*$/)[1])
      %w[prompt_id version role step language source_ref].each do |k|
        assert fm.key?(k), "#{rel}: frontmatter 必須 field 欠落: #{k}"
      end
      assert_equal role, fm["role"]
    end
  end

  # Step D（integration）は prompt artifact を持たない
  def test_step_d_has_no_prompt
    refute (ROOT + "runtime/prompts/integration").exist?
  end

  # template 整合：config / terminology テンプレートが YAML 解析できる
  def test_templates_parse_as_yaml
    %w[runtime/config/config.yaml.template runtime/config/terminology.yaml.template].each do |rel|
      path = ROOT + rel
      assert path.exist?, "template 欠落: #{rel}"
      assert YAML.safe_load(path.read), "#{rel}: YAML 解析不可"
    end
  end

  # fixture 整合：最小 fixture が JSON として解析できる
  def test_fixtures_parse
    %w[
      review_case.minimal.json finding.minimal.json necessity_judgment.minimal.json
      validator_result.minimal.json invalidation_marker.minimal.json
    ].each do |f|
      path = ROOT + "tests/fixtures/foundation/#{f}"
      assert path.exist?, "fixture 欠落: #{f}"
      JSON.parse(path.read)
    end
  end
end
