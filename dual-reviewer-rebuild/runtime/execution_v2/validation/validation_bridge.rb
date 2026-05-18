# frozen_string_literal: true

require "yaml"
require "time"
require "pathname"

# Task 7: validator integration（runtime 所有の独立 validation bridge）
# 根拠: tasks.md Task 7、Requirement 6 受入 1〜9、design「Validator Integration」
#       「Run Close Boundary」「Validation Outcomes」、
#       設計再確定 finding 6（validation 層の基盤新契約付け替え）。
#
# finding 6 拘束:
#   - validation 層は foundation runtime/foundation/metadata_contract.yaml の
#     `fields:` 構造を正本入力とし、必須項目は各 field の `required: true` から
#     機械抽出する（ハードコードした必須リストを持たない）。
#   - `validator_status` は同契約 `canonical_ownership.validator_status`
#     （not_run / passed / failed / blocked）を参照し runtime で再定義・別
#     トークン化・丸めをしない。4 値を丸めず伝播し not_run も保持する。
#   - `review_mode` は同契約 fields.review_mode.enum を参照する。
#   - `rules.missing_required_metadata_is_validator_failure: true` に従い
#     必須メタデータ欠落は validator failure とする。
#
# 責務境界:
#   - 本 bridge は validator failure（validator_status）のみを判定し、run
#     lifecycle の orchestration failure（run_status）には触れない（受入 4 の
#     区別を構造で担保。lifecycle 不変条件は controller 所有＝finding 9）。
#   - validation/invalidation が workflow failure を示すときの triage 接続点
#     （failed checks / invalidation marker / remediation hint linkage 保持）
#     を提供する。triage note 本体生成は Task 8 波。
#
# 配置: design「File Placement」。analyzer / writer / manifest / decision と
# 混在させない runtime 所有の独立モジュール（runtime/execution_v2/validation/）。
module DualReviewer
  module Runtime
    module ExecutionV2
      class ValidationBridge
        # foundation 契約ファイル名（runtime は consumer として参照のみ）。
        METADATA_CONTRACT_FILE = "metadata_contract.yaml"

        def initialize(foundation_root:)
          @foundation_root = Pathname(foundation_root)
          @contract = YAML.safe_load(
            (@foundation_root + METADATA_CONTRACT_FILE).read
          )
        end

        # finding 6: required: true の field 集合を機械抽出（ハードコードしない）。
        def required_metadata_fields
          @contract.fetch("fields").select do |_name, spec|
            spec.is_a?(Hash) && spec["required"] == true
          end.keys
        end

        # review_mode enum を契約から参照（runtime で再定義しない）。
        def review_mode_enum
          @contract.fetch("fields").fetch("review_mode").fetch("enum")
        end

        # canonical validator-status 語彙を契約 canonical_ownership から参照。
        def validator_status_enum
          @contract.fetch("canonical_ownership").fetch("validator_status")
        end

        # 必須メタデータ充足 + review_mode enum 整合を機械照合し、結果を
        # foundation validator_result schema 準拠 payload で返す。注入 validator
        # があれば追加 mechanical check を委譲し、その validator_status を
        # 丸めず伝播する（4 値検証込み）。
        #
        # frozen_evidence: 凍結後 raw evidence（決定的検証では固定入力）。
        # validator: optional callable。なければ metadata 検査結果のみで判定。
        def validate(run_id:, metadata:, frozen_evidence:, validator: nil)
          errors = []
          errors.concat(missing_required_metadata_errors(metadata))
          errors.concat(review_mode_enum_errors(metadata))

          status, extra =
            resolve_status(errors, frozen_evidence, validator)

          result = {
            "run_id" => run_id,
            "validator_status" => status,
            "checked_contract" =>
              "foundation:metadata_contract.yaml#fields(required)+review_mode.enum",
            "error_list" => errors,
            "validated_by" => "runtime:execution_v2:validation_bridge",
            "validated_at" => Time.now.utc.iso8601
          }
          # blocked の insufficiency detail は丸めず併記（Validation Outcomes）。
          if extra && extra["insufficiency_detail"]
            result["insufficiency_detail"] = extra["insufficiency_detail"]
          end
          result
        end

        # runtime-produced evidence を canonical runtime-mediated review mode で
        # mark する（受入 6）。enum は契約参照（runtime で別トークン化しない）。
        def mark_runtime_mediated(metadata)
          mode = "runtime_mediated"
          unless review_mode_enum.include?(mode)
            raise ArgumentError,
                  "runtime_mediated not in foundation review_mode enum"
          end

          metadata.merge("review_mode" => mode)
        end

        # required validation 失敗時に downstream「valid run」扱いを防ぐ（受入 5）。
        # passed のみ admissible。failed / blocked / not_run は不可。
        def downstream_valid_run_admissible?(validator_result)
          validator_result.fetch("validator_status") == "passed"
        end

        # validation/invalidation が workflow failure を示すときの triage 接続点
        # （受入 7・8）。failed validator check ids・invalidation marker・operator
        # remediation hint の linkage を保持する。triage note 本体生成は Task 8。
        def triage_linkage(run_id:, validator_result:, invalidation_markers: [],
                           remediation_hint: nil)
          status = validator_result.fetch("validator_status")
          failed_checks = Array(validator_result["error_list"])
                          .map { |e| e["check_id"] }.compact
          workflow_failure =
            status != "passed" || !Array(invalidation_markers).empty?

          {
            "run_id" => run_id,
            "validator_status" => status,
            "workflow_failure_indicated" => workflow_failure,
            "failed_validator_check_ids" => failed_checks,
            "invalidation_marker_linkage" => Array(invalidation_markers),
            "operator_remediation_hint" => remediation_hint
          }
        end

        private

        def missing_required_metadata_errors(metadata)
          # finding 6 + rules.missing_required_metadata_is_validator_failure。
          rule = @contract.fetch("rules")
                          .fetch("missing_required_metadata_is_validator_failure")
          return [] unless rule == true

          missing = required_metadata_fields.reject do |f|
            v = metadata[f]
            !v.nil? && !(v.respond_to?(:strip) && v.strip.empty?)
          end
          return [] if missing.empty?

          [{
            "check_id" => "missing_required_metadata",
            "detail" => "required metadata fields absent or empty",
            "fields" => missing
          }]
        end

        def review_mode_enum_errors(metadata)
          mode = metadata["review_mode"]
          return [] if mode.nil? # 欠落は missing_required_metadata 側で捕捉
          return [] if review_mode_enum.include?(mode)

          [{
            "check_id" => "review_mode_not_in_contract_enum",
            "detail" => "review_mode not in foundation metadata_contract enum",
            "fields" => ["review_mode"]
          }]
        end

        # metadata 検査結果と注入 validator を合成し canonical 4 値を丸めず返す。
        def resolve_status(errors, frozen_evidence, validator)
          if validator
            injected = validator.call(frozen_evidence) || {}
            status = injected.fetch("validator_status")
            assert_canonical_status!(status)
            errors.concat(Array(injected["error_list"]))
            return [status, injected]
          end

          [errors.empty? ? "passed" : "failed", nil]
        end

        # 4 値以外のトークン（旧 pass/fail 等）を丸めず明示拒否する（finding 6）。
        def assert_canonical_status!(status)
          return if validator_status_enum.include?(status)

          raise ArgumentError,
                "validator_status #{status.inspect} not in foundation " \
                "canonical_ownership.validator_status " \
                "#{validator_status_enum.inspect} (no rounding allowed)"
        end
      end
    end
  end
end
