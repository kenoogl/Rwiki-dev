# frozen_string_literal: true

require "securerandom"
require "time"
require "yaml"
require "json"
require "fileutils"
require "pathname"
require_relative "../execution_v2/contracts/run_layout"
require_relative "../execution_v2/manifests/case_manifest"
require_relative "../execution_v2/validation/invalidation_handler"

# Task 2: session controller
# 根拠: tasks.md Task 2、Requirement 1（受入 1〜6）、Requirement 8（受入 1・3・5）、
#       design「Session Model §1〜§3」「Run Manifest Field Set」
#       「Reference-Free Runtime Entry Principle」「Generic Protocol Entrypoint Rule」、
#       設計再確定 finding 9（run close 順序＝controller ライフサイクル不変条件）
#
# 本波の範囲: run lifecycle 状態機械・session input 固定・軸分離・reference-free
# entry・Run Close Boundary の順序ガード骨格。validator 実体呼び出しは後続 Task 7 で
# 接続する（invoke_validator は前提条件ガードと yield ブロック差し込み点のみ提供）。
module DualReviewer
  module Runtime
    class SessionController
      # foundation metadata_contract.yaml の enum を継承（再定義しない）。
      RUN_STATUSES = %w[created in_progress closed orchestration_failed].freeze
      VALIDATOR_STATUSES = %w[not_run passed failed blocked].freeze
      HUMAN_SIGNOFF_STATUSES = %w[pending approved rejected deferred].freeze
      EVIDENCE_CLASSES = %w[candidate valid invalid exploratory].freeze

      # phase_profile / treatment は独立軸。値語彙は runtime 所有（design §3）。
      PHASE_PROFILES = %w[intent requirements design tasks].freeze
      TREATMENTS = %w[single dual dual+judgment].freeze

      # run_manifest.yaml 開始時固定群（design「Run Manifest Field Set」）。
      STARTED_FIXED_FIELDS = %w[
        run_id target_id target_artifact_hash source_repository_id source_revision
        phase_profile treatment review_mode protocol_version runtime_version
        prompt_set_version schema_set_version config_version config_hash
        operator_id started_at
      ].freeze

      # 実行中更新群（実行進行・検証・承認の結果で更新）。
      RUNTIME_UPDATED_FIELDS = %w[
        run_status validator_status human_signoff_status evidence_class closed_at
      ].freeze

      # finding 9: Run Close Boundary 前提条件違反・多重起動を表す fail-closed エラー。
      class CloseBoundaryViolation < StandardError; end

      def initialize(run_root_base:)
        @run_root_base = Pathname(run_root_base)
      end

      # reference-free entry（design「Generic Protocol Entrypoint Rule」）。
      # case_manifest_ref があれば manifest を読む。無ければ track 別必須入力を要求。
      # どちらも無ければ fail fast。generic runtime code は特定 case を hidden default
      # にしない（pilot case basename / case id を既定値に持たない）。
      def start_run(
        target_id:, target_artifact_hash:, source_repository_id:, source_revision:,
        phase_profile:, treatment:, review_mode:, protocol_version:, runtime_version:,
        prompt_set_version:, schema_set_version:, config_version:, config_hash:,
        operator_id:, case_manifest_ref: nil, track: nil, source_refs: nil
      )
        validate_axis!(PHASE_PROFILES, phase_profile, "phase_profile")
        validate_axis!(TREATMENTS, treatment, "treatment")

        case_manifest = resolve_case_manifest(
          case_manifest_ref: case_manifest_ref, track: track,
          source_refs: source_refs, target_id: target_id
        )

        run_id = generate_run_id
        started_at = Time.now.utc.iso8601
        metadata = {
          "run_id" => run_id,
          "target_id" => target_id,
          "target_artifact_hash" => target_artifact_hash,
          "source_repository_id" => source_repository_id,
          "source_revision" => source_revision,
          "phase_profile" => phase_profile,
          "treatment" => treatment,
          "review_mode" => review_mode,
          "protocol_version" => protocol_version,
          "runtime_version" => runtime_version,
          "prompt_set_version" => prompt_set_version,
          "schema_set_version" => schema_set_version,
          "config_version" => config_version,
          "config_hash" => config_hash,
          "operator_id" => operator_id,
          "started_at" => started_at,
          # 実行中更新群の初期値
          "run_status" => "in_progress",
          "validator_status" => "not_run",
          "human_signoff_status" => "pending",
          "evidence_class" => "candidate",
          "closed_at" => nil
        }

        run = RunSession.new(
          run_id: run_id, run_root: @run_root_base + RunLayout.run_root_relative(run_id),
          metadata: metadata, case_manifest: case_manifest
        )
        run.persist_initial_manifest
        run
      end

      private

      def validate_axis!(vocab, value, label)
        return if vocab.include?(value)

        raise ArgumentError,
              "invalid #{label}: #{value.inspect} (allowed: #{vocab.join('/')})"
      end

      def resolve_case_manifest(case_manifest_ref:, track:, source_refs:, target_id:)
        if case_manifest_ref && !case_manifest_ref.to_s.strip.empty?
          payload = JSON.parse(Pathname(case_manifest_ref).read)
          return CaseManifest.build(payload)
        end

        if track.nil? || track.to_s.strip.empty? ||
           source_refs.nil? || (source_refs.respond_to?(:empty?) && source_refs.empty?)
          raise ArgumentError,
                "reference-free entry requires either case_manifest_ref or " \
                "explicit track inputs (track + source_refs); none provided"
        end

        CaseManifest.build(
          "case_id" => target_id,
          "track" => track,
          "source_refs" => source_refs,
          "case_manifest_ref" => "inline:explicit-track-inputs"
        )
      end

      def generate_run_id
        "run-#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}-#{SecureRandom.hex(4)}"
      end

      # 1 run の lifecycle 状態機械と Run Close Boundary 順序ガードの保持者。
      # 状態遷移 API は後続波（Task 7）が validator 実体と前提条件ガードを
      # 差し込めるよう、観測可能なフラグとして分離する。
      class RunSession
        attr_reader :run_id, :run_root, :initial_status

        def initialize(run_id:, run_root:, metadata:, case_manifest:)
          @run_id = run_id
          @run_root = run_root
          @metadata = metadata
          @case_manifest = case_manifest
          # Task 8: invalidation marker / triage note 本体は runtime 所有の
          # 独立 InvalidationHandler が生成する（controller は接続点のみ）。
          @invalidation_handler = ExecutionV2::InvalidationHandler.new
          @initial_status = "created"
          # finding 9 前提条件 observable
          @step_d_complete = false
          @human_signoff_written = false
          @raw_evidence_frozen = false
          @validator_invoked = false
          @validator_status = "not_run"
          @human_signoff_status = "pending"
          @invalidation_markers = []
          @validator_result = nil
          @closed = false
        end

        def run_status
          @metadata.fetch("run_status")
        end

        def manifest_metadata
          @metadata
        end

        def case_manifest
          @case_manifest
        end

        def invalidation_markers
          @invalidation_markers
        end

        def persist_initial_manifest
          @run_root.mkpath
          write_manifest
        end

        # Step D 統合完了（finding 9 前提条件 1）。
        def mark_step_d_complete
          @step_d_complete = true
        end

        # human sign-off artifact 書込（finding 9 前提条件 2）。
        # validator より前に decisions/human_signoff.json を書く（要件 6 受入 9）。
        def write_human_signoff(status:, signed_off_by:, covered_decision_unit_ids: [], note: nil)
          unless HUMAN_SIGNOFF_STATUSES.include?(status)
            raise ArgumentError, "invalid human_signoff_status: #{status.inspect}"
          end

          payload = {
            "run_id" => @run_id,
            "human_signoff_status" => status,
            "signed_off_by" => signed_off_by,
            "signed_off_at" => Time.now.utc.iso8601,
            "covered_decision_unit_ids" => covered_decision_unit_ids,
            "signoff_note" => note
          }
          path = @run_root + "decisions/human_signoff.json"
          path.dirname.mkpath
          path.write(JSON.pretty_generate(payload))
          @human_signoff_status = status
          @human_signoff_written = true
          payload
        end

        # raw evidence 凍結（finding 9 前提条件 3）。controller が evidence writer に
        # 指示する凍結を骨格として表現。freeze marker artifact を observable にする。
        def freeze_raw_evidence
          marker = @run_root + "validation/.raw_evidence_frozen"
          marker.dirname.mkpath
          marker.write(Time.now.utc.iso8601)
          @raw_evidence_frozen = true
        end

        # finding 9: validator 単一起動点。前提 3 条件未充足／多重起動は
        # fail-closed（orchestration_failed）＋invalidation marker。
        # validator 実体は後続 Task 7 が yield ブロックとして差し込む。
        def invoke_validator
          enforce_close_boundary_preconditions!

          @validator_invoked = true
          result = block_given? ? yield : { "validator_status" => "not_run" }
          status = result.fetch("validator_status")
          # foundation canonical 4 値を丸めず伝播。enum 外は再定義せず拒否。
          unless VALIDATOR_STATUSES.include?(status)
            raise ArgumentError, "invalid validator_status: #{status.inspect}"
          end

          @validator_status = status
          @validator_result = result
          # validator_result.json を Run Close Boundary 単一起動点で保存
          # （要件 6 受入 9、design Run Close Boundary）。raw evidence は
          # 凍結済みで非編集、結果は別 artifact として重ねる（design Decision 3）。
          path = @run_root + "validation/validator_result.json"
          path.dirname.mkpath
          path.write(JSON.pretty_generate(result))
          result
        end

        # close は validator 後にのみ成立（順序: Step D → sign-off → freeze →
        # validator → close）。closed は raw evidence 凍結のみを意味し validity を
        # 意味しない（design §1）。evidence_class は close 時 candidate のまま記録。
        def close
          unless @validator_invoked
            fail_closed!("close attempted before validator invocation",
                         "close_boundary_order_violation")
          end

          @metadata["run_status"] = "closed"
          @metadata["validator_status"] = @validator_status
          @metadata["human_signoff_status"] = @human_signoff_status
          @metadata["evidence_class"] = "candidate"
          @metadata["closed_at"] = Time.now.utc.iso8601
          write_manifest
          write_review_case
          @closed = true
          @metadata
        end

        # run close 成立後の確定順（design Run Close Boundary）:
        #   1. invalidation marker 付与
        #   2. invalid_run_triage_note.json 生成（本体生成は Task 8 波。本波は
        #      Run Close Boundary 後の triage 呼び出し位置・順序のみ確定）
        #   3. run_manifest.yaml / review_case.json metadata 更新
        # close 成立前の呼び出しは順序違反として fail-closed（順序を崩さない）。
        def finalize_post_close(validation_bridge:)
          unless @closed
            fail_closed!(
              "finalize_post_close attempted before run close " \
              "(required order: ... -> validator -> close -> post-close)",
              "close_boundary_order_violation"
            )
          end

          order = []

          # 1. invalidation marker 付与（既に検知済みの marker を確定保存）。
          persist_invalidation_markers
          order << "invalidation_markers_applied"

          # 2. triage note 生成（Task 8 本体）。order 第2段の接続点で、
          #    bridge の triage_linkage（failed checks / invalidation marker /
          #    remediation hint linkage）を入力に InvalidationHandler が
          #    derived/invalid_run_triage_note.json を生成する。Run Close
          #    Boundary 後の生成位置・順序を崩さない（design Run Close Boundary）。
          validator_result = @validator_result ||
            { "validator_status" => @validator_status, "error_list" => [] }
          linkage = validation_bridge.triage_linkage(
            run_id: @run_id,
            validator_result: validator_result,
            invalidation_markers: @invalidation_markers
          )
          triage = @invalidation_handler.write_triage_note(
            run_root: @run_root,
            run_id: @run_id,
            validator_result: validator_result,
            invalidation_markers: @invalidation_markers,
            operator_action_hint: linkage["operator_remediation_hint"]
          )
          order << "triage_hook_invoked"

          # 3. run_manifest.yaml / review_case.json metadata 更新。
          @metadata["validator_status"] = @validator_status
          @metadata["human_signoff_status"] = @human_signoff_status
          write_manifest
          write_review_case
          order << "metadata_refreshed"

          {
            "invalidation_markers_applied" => @invalidation_markers,
            "triage_hook_invoked" => triage,
            "metadata_refreshed" => true,
            "post_close_order" => order
          }
        end

        private

        def enforce_close_boundary_preconditions!
          if @validator_invoked
            fail_closed!("validator double invocation is forbidden",
                         "close_boundary_double_invocation")
          end

          missing = []
          missing << "step_d_complete" unless @step_d_complete
          missing << "human_signoff_written" unless @human_signoff_written
          missing << "raw_evidence_frozen" unless @raw_evidence_frozen
          return if missing.empty?

          fail_closed!(
            "Run Close Boundary preconditions unmet before validator: " \
            "missing #{missing.join(', ')} (required order: Step D -> human " \
            "sign-off -> freeze -> validator -> close)",
            missing.include?("human_signoff_written") ? :run_close_without_signoff : :treatment_step_mismatch
          )
        end

        # fail-closed: validator を起動せず orchestration_failed にし、
        # invalidation marker を raw evidence 非編集で追加（design Decision 3）。
        # marker は Task 8 InvalidationHandler 経由で構築し、基盤
        # invalidation_marker.schema.json の必須形・reason_code 語彙を
        # handler が出す自動 marker と一貫させる（finding 9・型一貫）。
        # reason が 4 自動 kind の場合は kind を渡し、controller 固有の
        # orchestration reason（close 順序違反等）は同 schema 必須形で構築する。
        def fail_closed!(message, reason)
          @metadata["run_status"] = "orchestration_failed"
          marker =
            if reason.is_a?(Symbol)
              @invalidation_handler.automatic_marker(
                run_id: @run_id, kind: reason, detail: message, scope: "run"
              )
            else
              @invalidation_handler.human_issued_marker(
                run_id: @run_id, reason_code: reason.to_s,
                reason_detail: message, issued_by: "runtime", scope: "run"
              )
            end
          @invalidation_markers << marker
          persist_invalidation_markers
          write_manifest
          raise CloseBoundaryViolation, message
        end

        def persist_invalidation_markers
          path = @run_root + "validation/invalidation_markers.json"
          path.dirname.mkpath
          path.write(JSON.pretty_generate("invalidation_markers" => @invalidation_markers))
        end

        def write_manifest
          path = @run_root + "run_manifest.yaml"
          path.dirname.mkpath
          payload = {
            "manifest_version" => "1.0.0",
            "runtime_feature" => "dual-reviewer-runtime",
            "metadata" => @metadata
          }
          path.write(YAML.dump(payload))
        end

        # review_case.json は唯一の横断正本（常に foundation review_case schema
        # 準拠＝A-5、design Completion Criteria）。投影規約は runtime 所有の
        # ReviewCaseProjector が持つ（writer 層）。controller は run lifecycle の
        # 更新群を反映する責務のみを持ち、projector 生成済みの schema-compliant
        # envelope（step_records / findings / validation_refs 等）を clobber せず
        # 保全し、metadata の実行中更新群（run_status / validator_status /
        # human_signoff_status / evidence_class / closed_at）のみを上書きする。
        # projector 出力が未生成の場合は最小 envelope を書く（metadata 正本性は
        # 保つ。横断正本の完全形は EvidenceWriter 経由で投影される）。
        def write_review_case
          path = @run_root + "review_case.json"
          path.dirname.mkpath
          existing =
            if path.file?
              begin
                JSON.parse(path.read)
              rescue JSON::ParserError
                nil
              end
            end

          payload =
            if existing.is_a?(Hash) && existing.key?("metadata")
              # projector 生成済み envelope を保全し metadata のみ refresh する
              # （raw step_records / findings / validation_refs を消さない）。
              merged_metadata = (existing["metadata"] || {}).merge(@metadata)
              existing.merge("metadata" => merged_metadata)
            else
              {
                "schema_version" => "1.0.0",
                "review_case_id" => "review-case-#{@run_id}",
                "metadata" => @metadata
              }
            end
          path.write(JSON.pretty_generate(payload))
        end
      end
    end
  end
end
