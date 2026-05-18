# frozen_string_literal: true

require "json"
require "time"
require "pathname"

# Task 8: invalidation handling と invalid-run triage
# 根拠: tasks.md Task 8、Requirement 6 受入 3・7・8、design「Invalidation Handling」
#       「Run Close Boundary」、設計再確定 finding 9（fail-closed marker 型一貫）、
#       基盤契約 runtime/validators/contracts/invalidation_marker.schema.json。
#
# 責務境界:
#   - invalidation を raw evidence 編集ではなく
#     validation/invalidation_markers.json への追加で表現する（受入 3）。
#     raw step outputs は読まず・書かず、別 artifact にのみ追記する。
#   - runtime 自動 marker 4 型（missing required artifact /
#     unresolved prompt identity / run close without sign-off /
#     treatment-step mismatch）を発行する。人間判断要（contamination /
#     hidden intervention）は human-issued marker として同一 artifact 形式で
#     追加する。marker は基盤 invalidation_marker.schema.json に準拠し
#     runtime で再定義しない。
#   - invalid run の derived/invalid_run_triage_note.json を生成する（受入 7・8、
#     primary failure code / failed validator check ids / invalidation marker
#     linkage / operator action hint）。self-improvement / protocol review が
#     workflow failure 再発分析の正規補助入力として読める形にする。
#
# 配置: design「File Placement」。validation_bridge と協調する runtime 所有の
# 独立モジュール（runtime/execution_v2/validation/）。analyzer / writer /
# manifest / decision とは混在させない。
module DualReviewer
  module Runtime
    module ExecutionV2
      class InvalidationHandler
        # runtime 自動 marker の reason_code 語彙（design「Invalidation Handling」）。
        # 第1波 controller fail-closed が付与する reason_code と型・形式を一貫させる
        # ため、controller も本語彙を共有する（finding 9）。
        AUTOMATIC_REASON_CODES = {
          missing_required_artifact: "missing_required_artifact",
          unresolved_prompt_identity: "unresolved_prompt_identity",
          run_close_without_signoff: "run_close_without_signoff",
          treatment_step_mismatch: "treatment_step_mismatch"
        }.freeze

        # 基盤 invalidation_marker.schema.json の scope 初版語彙（再定義しない）。
        SCOPE_VOCAB = %w[run step finding].freeze

        # 自動 marker を 1 件構築する（基盤 schema 必須形に準拠）。
        # raw evidence は参照・編集しない。
        def automatic_marker(run_id:, kind:, detail:, scope: "run")
          code = AUTOMATIC_REASON_CODES[kind]
          unless code
            raise ArgumentError,
                  "unknown automatic invalidation kind: #{kind.inspect} " \
                  "(allowed: #{AUTOMATIC_REASON_CODES.keys.join('/')})"
          end

          build_marker(run_id: run_id, reason_code: code, reason_detail: detail,
                       scope: scope, issued_by: "runtime")
        end

        # 人間判断要 marker（contamination / hidden intervention 等）を構築する。
        # 自動 marker と同一 artifact 形式・同 schema 必須形。issued_by は人間。
        def human_issued_marker(run_id:, reason_code:, reason_detail:,
                                issued_by:, scope: "run")
          if issued_by.nil? || issued_by.to_s.strip.empty?
            raise ArgumentError, "human-issued marker requires issued_by"
          end

          build_marker(run_id: run_id, reason_code: reason_code,
                       reason_detail: reason_detail, scope: scope,
                       issued_by: issued_by)
        end

        # marker を validation/invalidation_markers.json に追加する（受入 3）。
        # 既存内容を上書きせず additive に追記し、raw evidence は一切編集しない。
        def append_markers(run_root:, markers:)
          path = Pathname(run_root) + "validation/invalidation_markers.json"
          path.dirname.mkpath
          existing =
            if path.exist?
              JSON.parse(path.read).fetch("invalidation_markers", [])
            else
              []
            end
          combined = existing + Array(markers)
          path.write(JSON.pretty_generate("invalidation_markers" => combined))
          combined
        end

        # invalid run の triage note を derived/ に生成する（受入 7・8）。
        # 最低 4 項目: primary failure code / failed validator check ids /
        # invalidation marker linkage / operator action hint。
        # runtime convenience artifact だが self-improvement / protocol review が
        # workflow failure 再発分析の正規補助入力として読める形にする。
        def write_triage_note(run_root:, run_id:, validator_result:,
                              invalidation_markers:, operator_action_hint:)
          markers = Array(invalidation_markers)
          status = validator_result.fetch("validator_status")
          failed_checks = Array(validator_result["error_list"])
                          .map { |e| e["check_id"] }.compact

          note = {
            "run_id" => run_id,
            "primary_failure_code" =>
              primary_failure_code(status, markers),
            "failed_validator_check_ids" => failed_checks,
            "invalidation_marker_linkage" => markers,
            "operator_action_hint" => operator_action_hint,
            "validator_status" => status,
            "generated_by" => "runtime:execution_v2:invalidation_handler",
            "generated_at" => Time.now.utc.iso8601
          }

          path = Pathname(run_root) + "derived/invalid_run_triage_note.json"
          path.dirname.mkpath
          path.write(JSON.pretty_generate(note))
          note
        end

        private

        def build_marker(run_id:, reason_code:, reason_detail:, scope:,
                         issued_by:)
          unless SCOPE_VOCAB.include?(scope)
            raise ArgumentError,
                  "invalid invalidation scope: #{scope.inspect} " \
                  "(schema enum: #{SCOPE_VOCAB.join('/')})"
          end

          # 基盤 invalidation_marker.schema.json の required を満たす。
          {
            "run_id" => run_id,
            "reason_code" => reason_code,
            "reason_detail" => reason_detail,
            "scope" => scope,
            "issued_by" => issued_by,
            "issued_at" => Time.now.utc.iso8601
          }
        end

        # primary failure code: validator failure を優先し、無ければ最初の
        # invalidation marker の reason_code に fall back する。
        def primary_failure_code(validator_status, markers)
          return "validator_#{validator_status}" if validator_status != "passed"
          return markers.first.fetch("reason_code") unless markers.empty?

          "unknown"
        end
      end
    end
  end
end
