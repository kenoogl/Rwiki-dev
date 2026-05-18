# frozen_string_literal: true

require "json"
require "time"
require "pathname"
require_relative "review_case_projector"

# Task 6: evidence writing model
# 根拠: tasks.md Task 6、Requirement 4 受入 1〜7、Requirement 7 受入 1〜5、
#       design「Evidence Writing Model」「Raw vs Derived Separation」
#       「`review_case.json`」「Runtime Artifact Layout」「v2 Compatibility Rule」
#       「Interfaces to Downstream Features」、設計横断整合ゲート 2026-05-18
#       実行側 A-5 / 評価 A-7 / 自己改善 T5-A 案 A。
#
# 責務（design Raw vs Derived Separation）: evidence を 3 層で書き分ける。
#   - raw step evidence            steps/*.json（immutable。summary 更新で不変）
#   - human / decision integration decisions/decision_units.json
#   - v2 internal canonical        v2/{review_artifact,metric_snapshot,
#                                  trace_note,signal_linkage_note}.json
# review_case.json は唯一の横断正本（foundation schema 常時準拠）。投影規約は
# ReviewCaseProjector（runtime 所有）。failure mode 時は failure_observation を
# foundation schema 準拠で必ず出す。comparison_eligibility_note は runtime 所有
# スキーマ（A-7 最小 6 項目）。metric_snapshot 生成責務は writer 側（空にしない）。
#
# 実行中更新群（validator_status / human_signoff_status / evidence_class）は
# foundation enum の初期値（not_run / pending / candidate）で schema 準拠に保ち、
# 確定遷移は Task 7 波（validator / Run Close Boundary）に委ねる。runtime 側で
# 語彙を再定義・別トークン化しない。
#
# 配置: design File Placement「runtime/execution_v2/writers/」。manifest /
# analyzer / decision logic を writer に混ぜない。
module DualReviewer
  module Runtime
    module ExecutionV2
      class EvidenceWriter
        RawImmutabilityError = Class.new(RuntimeError)

        # design「Runtime Artifact Layout」: step_id → raw step file 相対パス。
        STEP_RELPATH = {
          "step_a" => "steps/step_a_primary_detection.json",
          "step_b" => "steps/step_b_adversarial_review.json",
          "step_c" => "steps/step_c_judgment.json",
          "step_d" => "steps/step_d_integration.json"
        }.freeze

        # comparison_eligibility_note runtime 所有スキーマ（評価 A-7。配置は
        # runtime 所有 contract。foundation runtime/schemas/ には置かない）。
        COMPARISON_ELIGIBILITY_SCHEMA_RELPATH =
          "runtime/execution_v2/contracts/comparison_eligibility_note.schema.json"

        attr_accessor :metadata
        attr_reader :run_root, :run_id

        def initialize(run_root:, run_id:)
          @run_root = Pathname(run_root)
          @run_id = run_id
          @metadata = {}
          @raw_steps = {}
          @decision_units = []
        end

        # downstream 3 feature が読んでよい artifact（design「Interfaces to
        # Downstream Features」「Downstream Handoff」§4）。runtime のどの artifact
        # を誰が読むか追跡できる（完了条件）。
        def self.downstream_artifact_trace
          {
            "evaluation" => %w[
              run_manifest.yaml
              review_case.json
              decisions/decision_units.json
              validation/validator_result.json
              validation/invalidation_markers.json
              derived/comparison_eligibility_note.json
            ].freeze,
            "self_improvement" => %w[
              steps/step_a_primary_detection.json
              steps/step_b_adversarial_review.json
              steps/step_c_judgment.json
              steps/step_d_integration.json
              decisions/decision_units.json
              validation/validator_result.json
              validation/invalidation_markers.json
              derived/invalid_run_triage_note.json
              failures/failure_observation.json
              v2/signal_linkage_note.json
              v2/trace_note.json
            ].freeze,
            "paper_interface" => [
              "(runtime から直接 raw step file を読まず原則 evaluation 出力経由)"
            ].freeze
          }
        end

        # --- layer 1: raw step evidence（immutable） ---------------------------

        # raw step output を steps/*.json に 1 度だけ書く。二重書込は immutability
        # 違反として拒否する（受入 4。summary 更新で raw を書き換えない）。
        # skip/reduced marker record も同層へ書く（事故的欠落と区別、受入 5）。
        def write_raw_step(record)
          step_id = record.fetch("step_id")
          rel = STEP_RELPATH.fetch(step_id) do
            raise ArgumentError, "unknown step_id: #{step_id.inspect}"
          end
          path = @run_root + rel
          if @raw_steps.key?(step_id) || path.exist?
            raise RawImmutabilityError,
                  "raw step output is immutable and already written: " \
                  "#{step_id} (#{rel})"
          end

          write_json(path, record)
          @raw_steps[step_id] = record
          path
        end

        # --- layer 2: human / decision integration evidence -------------------

        def write_decision_units(decision_units)
          @decision_units = decision_units
          write_json(
            @run_root + "decisions/decision_units.json",
            "run_id" => @run_id, "decision_units" => decision_units
          )
        end

        # --- layer 3: v2 internal canonical evidence --------------------------

        # v2 internal artifact を書く。review_artifact は runtime 内部限定の
        # taxonomy-first 表現（横断正本にしない＝A-5）。指定された artifact のみ書く。
        def write_v2_internal(review_artifact: nil, metric_snapshot: nil,
                              trace_note: nil, signal_linkage_note: nil)
          out = {}
          if review_artifact
            out["review_artifact"] =
              write_json(@run_root + "v2/review_artifact.json", review_artifact)
          end
          if metric_snapshot
            out["metric_snapshot"] =
              write_json(@run_root + "v2/metric_snapshot.json", metric_snapshot)
          end
          if trace_note
            out["trace_note"] =
              write_json(@run_root + "v2/trace_note.json", trace_note)
          end
          if signal_linkage_note
            out["signal_linkage_note"] = write_json(
              @run_root + "v2/signal_linkage_note.json", signal_linkage_note
            )
          end
          out
        end

        # v2/metric_snapshot.json の生成責務は runtime writer 側（design layout に
        # 存在。未生成の空 artifact を残さない）。run identity と step 実行数を
        # 最低限保持する（metrics 集計自体は Non-Goal のため数え上げのみ）。
        def write_metric_snapshot
          counts = Hash.new(0)
          @raw_steps.each_value do |rec|
            counts[rec["execution_state"] || "executed"] += 1
          end
          payload = {
            "schema_version" => "1.0.0",
            "run_id" => @run_id,
            "generated_at" => now,
            "treatment" => @metadata["treatment"],
            "phase_profile" => @metadata["phase_profile"],
            "step_execution_counts" => counts,
            "recorded_step_ids" => @raw_steps.keys
          }
          write_json(@run_root + "v2/metric_snapshot.json", payload)
        end

        # --- review_case.json（唯一の横断正本・foundation schema 常時準拠） ----

        # review_artifact → review_case 投影規約（runtime 所有 = projector）で
        # foundation schema 準拠の横断正本を書く（A-5）。実行中更新群は metadata
        # の初期値（not_run / pending / candidate）をそのまま保持し schema 準拠に
        # する（確定遷移は Task 7 波）。
        def write_review_case(validator_result_ref: nil,
                              invalidation_marker_refs: [],
                              review_artifact: nil)
          rc = ReviewCaseProjector.new.project(
            run_id: @run_id,
            metadata: @metadata,
            step_records: ordered_step_records,
            decision_units: @decision_units,
            review_artifact: review_artifact,
            validator_result_ref: validator_result_ref,
            invalidation_marker_refs: invalidation_marker_refs
          )
          write_json(@run_root + "review_case.json", rc)
        end

        # --- failure_observation（受入 7・foundation schema 準拠） -------------

        # review 実行が failure mode（review miss / disagreement 等）に陥った
        # ときに必ず出す。foundation failure_observation schema の必須 6 項目
        # （observation_id / run_ref / related_finding_ref / failure_type /
        # missed_by_role / detected_at_step）を満たす。未使用 schema にしない。
        def write_failure_observation(failure_type:, missed_by_role:,
                                      detected_at_step:,
                                      related_finding_ref: nil,
                                      observation_id: nil)
          payload = {
            "observation_id" =>
              observation_id || "fo-#{@run_id}-#{detected_at_step}",
            "run_ref" => @run_id,
            "related_finding_ref" => related_finding_ref,
            "failure_type" => failure_type,
            "missed_by_role" => missed_by_role,
            "detected_at_step" => detected_at_step
          }
          write_json(@run_root + "failures/failure_observation.json", payload)
        end

        # --- comparison_eligibility_note（評価 A-7・runtime 所有 6 項目） -------

        def write_comparison_eligibility_note(eligible_for_standard_comparison:,
                                              ineligibility_reason_codes: [])
          payload = {
            "schema_version" => "1.0.0",
            "run_id" => @run_id,
            "eligible_for_standard_comparison" =>
              eligible_for_standard_comparison,
            "ineligibility_reason_codes" => Array(ineligibility_reason_codes),
            "treatment" => @metadata["treatment"],
            "phase_profile" => @metadata["phase_profile"],
            "generated_at" => now
          }
          write_json(
            @run_root + "derived/comparison_eligibility_note.json", payload
          )
        end

        # --- derived convenience（evaluation の正本ではない） ------------------

        def write_runtime_summary(payload)
          write_json(
            @run_root + "derived/runtime_summary.json",
            { "run_id" => @run_id, "generated_at" => now }.merge(payload)
          )
        end

        private

        # review_case step_records は design layout の step 順を正本順序にする。
        def ordered_step_records
          %w[step_a step_b step_c step_d]
            .map { |sid| @raw_steps[sid] }
            .compact
        end

        def now
          Time.now.utc.iso8601
        end

        def write_json(path, payload)
          path.dirname.mkpath
          path.write(JSON.pretty_generate(payload))
          path
        end
      end
    end
  end
end
