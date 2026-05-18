# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 7: validator integration と Run Close Boundary
# 根拠: tasks.md Task 7、Requirement 6 受入 1〜9、design「Validator Integration」
#       「Run Close Boundary」「Validation Outcomes」、設計再確定 finding 6・finding 9
#
# 本テストは ValidationBridge（runtime 所有・独立モジュール）の
#   - finding 6: metadata_contract.yaml `fields:` から required: true 機械抽出照合、
#                4 値（not_run/passed/failed/blocked）丸めなし伝播、
#                review_mode を同契約 enum から参照、
#                missing_required_metadata_is_validator_failure に従う failure
#   - validator failure と orchestration failure の区別
#   - review_mode=runtime_mediated mark（受入 6）
#   - triage 接続点（failed checks / invalidation marker / remediation hint linkage）
# を決定的に検証する。固定 validator スタブを注入し外部依存なし。
class TestValidationBridge < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/validation/validation_bridge"
    @dir = Pathname(Dir.mktmpdir)
    @bridge = DualReviewer::Runtime::ExecutionV2::ValidationBridge.new(
      foundation_root: ROOT + "runtime/foundation"
    )
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def full_metadata(overrides = {})
    {
      "run_id" => "run-x",
      "target_id" => "spec/x",
      "target_artifact_hash" => "sha256:a",
      "source_repository_id" => "repo",
      "source_revision" => "rev1",
      "phase_profile" => "design",
      "treatment" => "dual+judgment",
      "review_mode" => "runtime_mediated",
      "protocol_version" => "1.0.0",
      "runtime_version" => "0.1.0",
      "schema_set_version" => "1.0.0",
      "prompt_set_version" => "1.0.0",
      "config_version" => "1.0.0",
      "config_hash" => "sha256:c",
      "run_status" => "closed",
      "validator_status" => "not_run",
      "human_signoff_status" => "approved",
      "evidence_class" => "candidate",
      "started_at" => "2026-05-19T00:00:00Z"
    }.merge(overrides)
  end

  # --- finding 6: required を metadata_contract fields から機械抽出 -----------

  def test_required_fields_extracted_from_metadata_contract_not_hardcoded
    req = @bridge.required_metadata_fields
    # metadata_contract.yaml の fields: で required: true のものだけ
    doc = YAML.safe_load((ROOT + "runtime/foundation/metadata_contract.yaml").read)
    expected = doc.fetch("fields").select { |_, v| v["required"] == true }.keys.sort
    assert_equal expected, req.sort
    refute_includes req, "closed_at" # required: false は含めない
  end

  def test_review_mode_enum_referenced_from_contract
    doc = YAML.safe_load((ROOT + "runtime/foundation/metadata_contract.yaml").read)
    assert_equal doc.fetch("fields").fetch("review_mode").fetch("enum"),
                 @bridge.review_mode_enum
  end

  def test_validator_status_canonical_enum_from_contract
    assert_equal %w[not_run passed failed blocked],
                 @bridge.validator_status_enum
  end

  # --- validate: 必須メタデータ欠落は validator failure（finding 6） ----------

  def test_missing_required_metadata_is_validator_failure
    md = full_metadata
    md.delete("target_artifact_hash")
    result = @bridge.validate(run_id: "run-x", metadata: md, frozen_evidence: {})
    assert_equal "failed", result.fetch("validator_status")
    assert(result.fetch("error_list").any? do |e|
      e["check_id"] == "missing_required_metadata" &&
        Array(e["fields"]).include?("target_artifact_hash")
    end)
  end

  def test_all_required_present_passes
    result = @bridge.validate(
      run_id: "run-x", metadata: full_metadata, frozen_evidence: {}
    )
    assert_equal "passed", result.fetch("validator_status")
    assert_empty result.fetch("error_list")
  end

  def test_invalid_review_mode_token_is_failure
    md = full_metadata("review_mode" => "made_up_mode")
    result = @bridge.validate(run_id: "run-x", metadata: md, frozen_evidence: {})
    assert_equal "failed", result.fetch("validator_status")
    assert(result.fetch("error_list").any? { |e| e["check_id"] == "review_mode_not_in_contract_enum" })
  end

  # --- 4 値丸めなし伝播（finding 6） ----------------------------------------

  def test_blocked_propagated_not_collapsed_with_insufficiency_detail
    result = @bridge.validate(
      run_id: "run-x", metadata: full_metadata, frozen_evidence: {},
      validator: ->(_) { { "validator_status" => "blocked",
                           "insufficiency_detail" => "required artifact absent",
                           "error_list" => [] } }
    )
    assert_equal "blocked", result.fetch("validator_status")
    refute_equal "failed", result.fetch("validator_status")
    assert_equal "required artifact absent", result.fetch("insufficiency_detail")
  end

  def test_not_run_preserved_not_rounded
    result = @bridge.validate(
      run_id: "run-x", metadata: full_metadata, frozen_evidence: {},
      validator: ->(_) { { "validator_status" => "not_run", "error_list" => [] } }
    )
    assert_equal "not_run", result.fetch("validator_status")
  end

  def test_failed_from_injected_validator_preserved
    result = @bridge.validate(
      run_id: "run-x", metadata: full_metadata, frozen_evidence: {},
      validator: ->(_) { { "validator_status" => "failed",
                           "error_list" => [{ "check_id" => "schema_violation" }] } }
    )
    assert_equal "failed", result.fetch("validator_status")
    assert(result.fetch("error_list").any? { |e| e["check_id"] == "schema_violation" })
  end

  def test_unknown_validator_status_token_rejected_not_rounded
    assert_raises(ArgumentError) do
      @bridge.validate(
        run_id: "run-x", metadata: full_metadata, frozen_evidence: {},
        validator: ->(_) { { "validator_status" => "pass" } } # 旧トークン丸め禁止
      )
    end
  end

  # --- validator_result.json schema 準拠 ------------------------------------

  def test_validator_result_satisfies_foundation_schema_required
    result = @bridge.validate(
      run_id: "run-x", metadata: full_metadata, frozen_evidence: {}
    )
    schema = JSON.parse(
      (ROOT + "runtime/validators/contracts/validator_result.schema.json").read
    )
    schema.fetch("required").each do |k|
      assert result.key?(k), "validator_result schema 必須欠落: #{k}"
    end
    assert_includes @bridge.validator_status_enum, result.fetch("validator_status")
  end

  # --- review_mode=runtime_mediated mark（受入 6） --------------------------

  def test_marks_runtime_mediated_review_mode
    marked = @bridge.mark_runtime_mediated(full_metadata("review_mode" => nil))
    assert_equal "runtime_mediated", marked.fetch("review_mode")
    assert_includes @bridge.review_mode_enum, marked.fetch("review_mode")
  end

  # --- validator failure と orchestration failure の区別（受入 4・5） --------

  def test_validator_failure_distinct_from_orchestration_failure
    failed = @bridge.validate(
      run_id: "run-x", metadata: full_metadata, frozen_evidence: {},
      validator: ->(_) { { "validator_status" => "failed", "error_list" => [] } }
    )
    # validator failure は validator_status=failed であり run lifecycle の
    # orchestration_failed とは別概念（bridge は run_status を触らない）。
    refute failed.key?("run_status")
    assert_equal "failed", failed.fetch("validator_status")
  end

  def test_required_validation_failure_blocks_valid_run_handling
    failed = @bridge.validate(
      run_id: "run-x", metadata: full_metadata("target_id" => nil),
      frozen_evidence: {}
    )
    assert_equal "failed", failed.fetch("validator_status")
    refute @bridge.downstream_valid_run_admissible?(failed),
           "required validation 失敗時に valid run 扱いを許してはならない"
    passed = @bridge.validate(
      run_id: "run-x", metadata: full_metadata, frozen_evidence: {}
    )
    assert @bridge.downstream_valid_run_admissible?(passed)
  end

  # --- triage 接続点（受入 7・8、本体生成は Task 8） ------------------------

  def test_triage_linkage_payload_preserves_failed_checks_and_markers
    result = @bridge.validate(
      run_id: "run-x", metadata: full_metadata("source_revision" => nil),
      frozen_evidence: {}
    )
    markers = [{ "reason_code" => "missing_required_artifact",
                 "reason_detail" => "x" }]
    linkage = @bridge.triage_linkage(
      run_id: "run-x", validator_result: result,
      invalidation_markers: markers,
      remediation_hint: "populate source_revision in run_manifest"
    )
    assert_equal "run-x", linkage.fetch("run_id")
    assert_equal result.fetch("validator_status"),
                 linkage.fetch("validator_status")
    assert(Array(linkage.fetch("failed_validator_check_ids"))
             .include?("missing_required_metadata"))
    assert_equal markers, linkage.fetch("invalidation_marker_linkage")
    assert_equal "populate source_revision in run_manifest",
                 linkage.fetch("operator_remediation_hint")
  end

  def test_triage_linkage_indicates_no_workflow_failure_when_passed
    result = @bridge.validate(
      run_id: "run-x", metadata: full_metadata, frozen_evidence: {}
    )
    linkage = @bridge.triage_linkage(
      run_id: "run-x", validator_result: result, invalidation_markers: []
    )
    refute linkage.fetch("workflow_failure_indicated")
  end
end
