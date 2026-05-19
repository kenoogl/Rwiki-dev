#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"
require_relative "../evaluation/local_run_loader"
require_relative "../evaluation/classification_engine"

# Task 2: input model（自己改善所有・スクラッチ）
#
# 根拠: tasks.md Task 2、Requirement 1（受入 1〜6）/ Requirement 7（受入
#       1〜5）/ Requirement 8（受入 1〜5）、design「Input Model §1〜§2.5」
#       「v2 Supporting Inputs」「Signal Extraction Model §1〜§2」、
#       Decision 2、foundation `runtime/foundation/metadata_contract.yaml`。
#       適合レビュー 2026-05-19 finding 1/2/3 解消。
#
# スクラッチ方針: 旧 v1 signal_intake（2026-05-13・旧 fixture corpus 前提・
# evaluation LocalRunLoader 経由で invalid_run_triage_note を取得しようとし
# 恒常 nil・triage shape 旧 v1 drift・review_quality_signal が現行 fixture
# で不発）は流用せず破棄。本モジュールは:
#   - input を 3 class（review_quality / workflow_failure / evidence_quality）
#     に分ける（design §1）
#   - valid=review quality 改善一次入力 / invalid=workflow 防止一次入力 /
#     exploratory=hypothesis seed のみ（Decision 2）
#   - provenance 保持・必須欠落時 proposal 生成阻止（受入 6・foundation 要件
#     6 整合）
#   - review-mode provenance 保持・manual↔runtime handoff 非破壊保存
#   - imported provenance 保持・provenance 不足 imported を admitted 等価
#     扱いしない
#   - finding 2 解消: triage/failure を evaluation LocalRunLoader 経由で
#     なく runtime 正本配置（derived/・failures/）から直接解決し、現行
#     runtime triage shape（failed_validator_check_ids /
#     invalidation_marker_linkage）へ追随する
#
# evaluation モジュールは consumer として使う（LocalRunLoader#load_run で
# metadata/intake、ClassificationEngine で evidence maturity）。triage/failure
# は loader を介さず直接ファイル解決する（loader は convenience artifact を
# 載せない確定契約のため・finding 2）。
module DualReviewer
  module SelfImprovement
    class InputModel
      # design §1 の 3 input class（撤廃語彙不使用）。
      INPUT_CLASSES = %w[
        review_quality_signal
        workflow_failure_signal
        evidence_quality_signal
      ].freeze

      # signal_code → input class（design §1 / Signal Extraction §1〜§2）。
      SIGNAL_CLASS_MAP = {
        # review quality: false negative/positive・unstable judgment 系
        "human_decision_dissent" => "review_quality_signal",
        "run_review_quality_observed" => "review_quality_signal",
        "rejected_finding_cluster" => "review_quality_signal",
        "deferred_finding_cluster" => "review_quality_signal",
        # workflow failure: invalidation・validator・artifact missing 系
        "validator_failed" => "workflow_failure_signal",
        "invalidation_marker_issued" => "workflow_failure_signal",
        "failure_observation_recorded" => "workflow_failure_signal",
        # evidence quality: analysis_blocked・caveat 集中・metadata 系
        "exploratory_evidence_mode" => "evidence_quality_signal",
        "analysis_precondition_gap" => "evidence_quality_signal",
        "exploratory_population_member" => "evidence_quality_signal",
        "analysis_blocked_population_member" => "evidence_quality_signal",
        "unresolved_judgment_labels" => "evidence_quality_signal",
        "caveat_observed" => "evidence_quality_signal"
      }.freeze

      # foundation metadata_contract.yaml review_mode.enum（撤廃語彙不使用・
      # canonical のみ）。self-improvement は再定義せず参照のみ。
      CANONICAL_REVIEW_MODES = %w[manual_dogfooding runtime_mediated].freeze

      # source_origin enum（design Proposal Model §2）。
      SOURCE_ORIGINS = %w[
        central_local_run imported_external_bundle manual_review_record
      ].freeze

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @loader =
          DualReviewer::Evaluation::LocalRunLoader.new(repo_root: @repo_root)
        @engine = DualReviewer::Evaluation::ClassificationEngine.new
      end

      def input_classes
        INPUT_CLASSES
      end

      # design Completion Criteria 第 1 点: valid / invalid / exploratory の
      # signal をどう使い分けるか説明できる（Task 9 完了条件）。本文は
      # input_policy_for の実体（primary_use / adoption_supporting）と一致
      # させる（説明と挙動の乖離を作らない）。
      def signal_usage_explanation
        "valid runs are the primary input for review-quality improvement; " \
        "invalid runs are the primary input for workflow / validation / " \
        "contamination prevention; exploratory runs are usable only as a " \
        "hypothesis seed and are a weak basis for adoption (Decision 2). " \
        "Every proposal records which input class and evidence maturity it " \
        "depends on, and provenance must be intact or proposal generation " \
        "is blocked (Requirement 1 受入 6)."
      end

      # design Completion Criteria 第 4 点: runtime / evaluation /
      # paper-interface との境界を説明できる（Task 9 完了条件、design
      # Interfaces to Other Features）。
      def feature_boundary_explanation
        "self-improvement does not write back to runtime directly; adopted " \
        "proposals are converted into feature changes (runtime stays the " \
        "owner of its schemas and vocabulary). evaluation is the primary " \
        "signal source (invalid / exploratory distribution, phase-aware " \
        "metrics, caveat register) and self-improvement consumes its " \
        "AnalysisLayout output without redefining it. paper-interface does " \
        "not treat self-improvement proposals as a narrative source; it may " \
        "only reference adopted-change history as a methodology note."
      end

      # --- runtime 由来 signal -------------------------------------------------

      def load_runtime_signals(run_root:)
        root = Pathname(run_root).expand_path
        intake = @loader.load_run(run_root: root)
        classification = @engine.classify_local_run(run_intake: intake)
        metadata = intake.fetch("metadata", {})
        maturity = classification["classification"]

        signals = []
        signals.concat(decision_signals(root: root, metadata: metadata,
                                        maturity: maturity))
        signals.concat(workflow_signals(root: root, metadata: metadata,
                                        maturity: maturity,
                                        intake: intake))
        signals.concat(evidence_signals(root: root, metadata: metadata,
                                        maturity: maturity,
                                        classification: classification))

        {
          "runtime_source_type" => "local_run",
          "run_root" => root.to_s,
          "classification" => classification,
          "signals" => signals
        }
      end

      # --- evaluation 由来 signal ---------------------------------------------

      def load_evaluation_signals(analysis_root:)
        root = Pathname(analysis_root).expand_path
        cls = entries(root + "classifications/run_classification_index.json")
        rmx = by_run_id(entries(root + "metrics/run_metrics.json"))
        fmx = by_run_id(entries(root + "metrics/finding_metrics.json"))
        caveats = caveat_entries(root + "caveats/caveat_register.json")

        signals = []
        cls.each do |e|
          run_id = e["run_id"]
          maturity = e["classification"]
          signals.concat(
            eval_run_signals(entry: e, run_metrics: rmx[run_id],
                             finding_metrics: fmx[run_id],
                             maturity: maturity)
          )
        end
        caveats.each do |c|
          signals << build_signal(
            signal_source: "evaluation",
            signal_code: "caveat_observed",
            run_id: nil, phase_profile: nil, treatment: nil,
            evidence_maturity: "aggregate_analysis",
            source_refs: ["caveats/caveat_register.json##{c['caveat_code']}"],
            summary: "Evaluation emitted a caveat relevant to intake.",
            signal_value: { "caveat_code" => c["caveat_code"],
                            "severity" => c["severity"],
                            "affected_scope" => c["affected_scope"] }
          )
        end
        { "analysis_root" => root.to_s,
          "signals" => signals.uniq { |s| s["signal_id"] } }
      end

      # --- validity-aware input policy（Decision 2 / design §2） --------------

      def input_policy_for(evidence_maturity:)
        case evidence_maturity
        when "valid"
          { "primary_use" => "review_quality_primary",
            "adoption_supporting" => true }
        when "invalid"
          { "primary_use" => "workflow_prevention_primary",
            "adoption_supporting" => true }
        when "exploratory"
          { "primary_use" => "hypothesis_seed_only",
            "adoption_supporting" => false }
        else
          { "primary_use" => "non_admissible",
            "adoption_supporting" => false }
        end
      end

      # proposal-ready record はどの input class / evidence maturity に依拠
      # するか必ず記録する（design §2）。
      def proposal_input_binding(signal:)
        maturity = signal["evidence_maturity"]
        policy = input_policy_for(evidence_maturity: maturity)
        {
          "input_class" => signal["signal_class"],
          "evidence_maturity" => maturity,
          "source_evidence_refs" => signal["source_refs"],
          "primary_use" => policy["primary_use"],
          "adoption_supporting" => policy["adoption_supporting"]
        }
      end

      # --- 未記録 intuition / 通常編集 history を十分入力にしない（受入 4） ----

      def sufficient_input?(candidate:)
        src = candidate["source"]
        return false if src == "operator_intuition" &&
                        !candidate["recorded"]
        return false if src == "unstructured_editing_history"
        return false if src == "operator_intuition"

        refs = Array(candidate["source_evidence_refs"])
        !refs.empty? && !candidate["run_id"].to_s.empty?
      end

      # --- provenance 保持と欠落時 proposal 生成阻止（受入 5・6） -------------

      def resolve_provenance(signal:)
        run_id = signal["run_id"]
        md = signal["_metadata"] || {}
        complete = !run_id.to_s.empty? &&
                   !md["source_repository_id"].to_s.empty? &&
                   !md["source_revision"].to_s.empty?
        {
          "provenance_complete" => complete,
          "source_origin" => signal["source_origin"] || "central_local_run",
          "run_id" => run_id,
          "source_repository_id" => md["source_repository_id"],
          "source_revision" => md["source_revision"],
          "review_mode" => md["review_mode"]
        }
      end

      def resolve_imported_provenance(bundle:)
        rid = bundle["source_repository_id"]
        rev = bundle["source_revision"]
        adm = bundle["admission_status"]
        complete = !rid.to_s.empty? && !rev.to_s.empty? && !adm.to_s.empty?
        {
          "source_origin" => "imported_external_bundle",
          "source_repository_id" => rid,
          "source_revision" => rev,
          "admission_status" => adm,
          "provenance_complete" => complete,
          "equivalent_to_admitted_standard" =>
            complete && adm == "admitted_standard"
        }
      end

      # 必須 provenance 欠落/断絶時は proposal 生成を阻止する（受入 6・
      # foundation 要件 6 整合）。provenance 不足 imported を admitted standard
      # と等価扱いしない（Requirement 8 受入 5）。
      def proposal_provenance_gate(signal:)
        reasons = []
        reasons << "missing_run_provenance" if signal["run_id"].to_s.empty?
        # signal は source_refs を持つ。proposal-binding 側は
        # source_evidence_refs に写像される。どちらの key でも provenance
        # 連鎖が辿れることを確認する（Requirement 1 受入 5）。
        evidence = Array(signal["source_evidence_refs"]) +
                   Array(signal["source_refs"])
        if evidence.empty?
          reasons << "missing_source_evidence_refs"
        end
        imp = signal["imported_provenance"]
        if imp && !imp["provenance_complete"]
          reasons << "imported_provenance_insufficient"
        end
        { "allowed" => reasons.empty?, "block_reasons" => reasons }
      end

      # --- review-mode provenance / manual↔runtime handoff（Requirement 7） ---

      def motivation_eligibility(review_mode:)
        unless CANONICAL_REVIEW_MODES.include?(review_mode)
          return { "allowed_motivations" => [],
                   "implies_runtime_quality_equivalence" => false,
                   "diagnostic" => "review_mode_not_canonical" }
        end

        if review_mode == "manual_dogfooding"
          { "allowed_motivations" => %w[workflow_quality evidence_quality],
            "implies_runtime_quality_equivalence" => false }
        else
          { "allowed_motivations" =>
              %w[runtime_quality workflow_quality evidence_quality],
            "implies_runtime_quality_equivalence" => true }
        end
      end

      # manual→runtime handoff boundary を非破壊保存する（受入 5・design
      # §2.5）。先行は削除せず supersession 関係を明示し manual である事実を
      # 保持する。先行側に supersedes を対称記録する。
      def supersede(prior:, successor:, reason:, at: nil)
        ts = at || "1970-01-01T00:00:00Z"
        new_prior = prior.dup
        new_prior["superseded_by"] = successor["proposal_id"] ||
                                     successor["signal_id"]
        new_prior["supersession_reason"] = reason
        new_prior["supersession_at"] = ts
        new_prior["source_origin"] =
          prior["source_origin"] || "manual_review_record"

        new_succ = successor.dup
        new_succ["supersedes"] = prior["proposal_id"] || prior["signal_id"]
        { "prior" => new_prior, "successor" => new_succ }
      end

      private

      # 異議 decision（rejected/deferred）= review-quality 信号（finding 1
      # 解消: 実 dissent fixture から review_quality_signal を産出する）。
      def decision_signals(root:, metadata:, maturity:)
        du_path = root + "decisions/decision_units.json"
        return [] unless du_path.file?

        units = JSON.parse(du_path.read).fetch("decision_units", [])
        return [] if units.empty?

        decisions = units.map { |u| u["human_decision"] }
        counts = {
          "approved_count" => decisions.count("approved"),
          "rejected_count" => decisions.count("rejected"),
          "deferred_count" => decisions.count("deferred")
        }

        unless counts["rejected_count"].positive? ||
               counts["deferred_count"].positive?
          # 異議なし valid run も review-quality 改善の一次入力であり
          # provenance を input evidence→proposal で保持する必要がある
          # （Requirement 1 受入 5、design §2 valid runs=review quality
          # 改善一次入力）。baseline signal を 1 件出して provenance を
          # 失わない（adoption supporting は maturity 由来で決まる）。
          return [] unless maturity == "valid"

          return [build_signal(
            signal_source: "runtime",
            signal_code: "run_review_quality_observed",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: maturity,
            source_refs: ["decisions/decision_units.json"],
            summary: "Valid run review-quality baseline captured for " \
                     "self-improvement intake (no reviewer dissent).",
            signal_value: counts,
            metadata: metadata
          )]
        end

        [build_signal(
          signal_source: "runtime",
          signal_code: "human_decision_dissent",
          run_id: metadata["run_id"],
          phase_profile: metadata["phase_profile"],
          treatment: metadata["treatment"],
          evidence_maturity: maturity,
          source_refs: ["decisions/decision_units.json"],
          summary: "Runtime decision distribution shows reviewer dissent " \
                   "(rejected/deferred) relevant to review quality.",
          signal_value: counts,
          metadata: metadata
        )]
      end

      # workflow failure signal: validator_failed / invalidation_marker /
      # failure_observation。finding 2 解消: triage note と failure_observation
      # を evaluation LocalRunLoader を介さず runtime 正本配置から直接解決し、
      # 現行 runtime triage shape へ追随する。
      def workflow_signals(root:, metadata:, maturity:, intake:)
        signals = []
        triage = read_triage_note(root: root)

        if metadata["validator_status"] == "failed"
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "validator_failed",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: maturity,
            source_refs: workflow_refs("validation/validator_result.json",
                                       triage),
            summary: "Runtime validator failed for this run.",
            signal_value: {
              "validator_status" => metadata["validator_status"],
              "human_signoff_status" => metadata["human_signoff_status"],
              "primary_failure_code" => triage && triage["primary_failure_code"],
              # 現行 runtime triage shape へ追随（旧 v1 failed_checks[].
              # check_id ではなく failed_validator_check_ids）。
              "failed_validator_check_ids" =>
                triage ? Array(triage["failed_validator_check_ids"]) : [],
              "operator_action_hint" => triage && triage["operator_action_hint"]
            },
            metadata: metadata
          )
        end

        markers = read_invalidation_markers(root: root)
        markers.each do |m|
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "invalidation_marker_issued",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: maturity,
            source_refs: workflow_refs(
              "validation/invalidation_markers.json##{m['marker_id']}", triage
            ),
            summary: "Runtime invalidation marker issued for this run.",
            signal_value: {
              "reason_code" => m["reason_code"],
              "scope" => m["scope"],
              "issued_by" => m["issued_by"],
              "primary_failure_code" => triage && triage["primary_failure_code"],
              # 現行 triage shape: invalidation_marker_linkage（旧 v1
              # invalidation_marker_summary[].linked_check_ids ではない）。
              "invalidation_marker_linkage" =>
                triage ? Array(triage["invalidation_marker_linkage"]) : []
            },
            metadata: metadata
          )
        end

        fo = read_failure_observation(root: root)
        if fo
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "failure_observation_recorded",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: maturity,
            source_refs: ["failures/failure_observation.json"],
            summary: "Runtime recorded a failure_observation for this run.",
            signal_value: {
              "observation_id" => fo["observation_id"],
              "failure_type" => fo["failure_type"],
              "missed_by_role" => fo["missed_by_role"],
              "detected_at_step" => fo["detected_at_step"],
              "related_finding_ref" => fo["related_finding_ref"]
            },
            metadata: metadata
          )
        end
        signals
      end

      def evidence_signals(root:, metadata:, maturity:, classification:)
        signals = []
        if metadata["evidence_class"] == "exploratory" ||
           maturity == "exploratory"
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "exploratory_evidence_mode",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: maturity,
            source_refs: ["run_manifest.yaml", "review_case.json"],
            summary: "Runtime metadata marks this run as exploratory.",
            signal_value: { "evidence_class" => metadata["evidence_class"],
                            "review_mode" => metadata["review_mode"] },
            metadata: metadata
          )
        end
        if maturity == "analysis_blocked"
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "analysis_precondition_gap",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: maturity,
            source_refs: Array(classification["reason_codes"]),
            summary: "Runtime run did not satisfy analysis preconditions.",
            signal_value: {
              "reason_codes" => classification["reason_codes"],
              "reason_details" => classification["reason_details"]
            },
            metadata: metadata
          )
        end
        signals
      end

      def eval_run_signals(entry:, run_metrics:, finding_metrics:, maturity:)
        out = []
        run_id = entry["run_id"]
        ctx = { phase_profile: entry["phase_profile"],
                treatment: entry["treatment"], maturity: maturity }

        if maturity == "exploratory"
          out << eval_signal("exploratory_population_member", run_id,
                             "classifications/run_classification_index.json",
                             entry, ctx)
        elsif maturity == "analysis_blocked"
          out << eval_signal("analysis_blocked_population_member", run_id,
                             "classifications/run_classification_index.json",
                             entry, ctx)
        end

        if run_metrics && run_metrics["rejected_findings"].to_i.positive?
          out << eval_signal("rejected_finding_cluster", run_id,
                             "metrics/run_metrics.json",
                             { "rejected_findings" =>
                                 run_metrics["rejected_findings"],
                               "total_findings" =>
                                 run_metrics["total_findings"] }, ctx)
        end
        if run_metrics && run_metrics["deferred_findings"].to_i.positive?
          out << eval_signal("deferred_finding_cluster", run_id,
                             "metrics/run_metrics.json",
                             { "deferred_findings" =>
                                 run_metrics["deferred_findings"],
                               "total_findings" =>
                                 run_metrics["total_findings"] }, ctx)
        end
        unresolved = finding_metrics &&
                     finding_metrics.dig("judgment_label_distribution",
                                         "unresolved_judgment_labels").to_i
        if unresolved&.positive?
          out << eval_signal("unresolved_judgment_labels", run_id,
                             "metrics/finding_metrics.json",
                             { "unresolved_judgment_labels" => unresolved },
                             ctx)
        end
        out
      end

      def eval_signal(code, run_id, ref_base, value, ctx)
        build_signal(
          signal_source: "evaluation",
          signal_code: code,
          run_id: run_id,
          phase_profile: ctx[:phase_profile],
          treatment: ctx[:treatment],
          evidence_maturity: ctx[:maturity],
          source_refs: ["#{ref_base}##{run_id}"],
          summary: "Evaluation-derived signal: #{code}.",
          signal_value: value
        )
      end

      # finding 2 解消: triage note を runtime 正本配置から直接読む
      # （evaluation LocalRunLoader は convenience artifact を載せない確定
      # 契約のため loader 経由では恒常 nil になる）。
      def read_triage_note(root:)
        path = root + "derived/invalid_run_triage_note.json"
        return nil unless path.file?

        JSON.parse(path.read)
      rescue JSON::ParserError
        nil
      end

      def read_failure_observation(root:)
        path = root + "failures/failure_observation.json"
        return nil unless path.file?

        JSON.parse(path.read)
      rescue JSON::ParserError
        nil
      end

      def read_invalidation_markers(root:)
        path = root + "validation/invalidation_markers.json"
        return [] unless path.file?

        Array(JSON.parse(path.read)["invalidation_markers"])
      rescue JSON::ParserError
        []
      end

      def workflow_refs(primary, triage)
        refs = [primary]
        refs << "derived/invalid_run_triage_note.json" if triage
        refs
      end

      def build_signal(signal_source:, signal_code:, run_id:, phase_profile:,
                       treatment:, evidence_maturity:, source_refs:,
                       summary:, signal_value:, metadata: nil)
        sig = {
          "signal_id" => [
            signal_source, run_id || "aggregate", signal_code,
            source_refs.first.to_s.gsub(/[^a-zA-Z0-9]+/, "-")
                       .gsub(/^-|-$/, "")
          ].join(":"),
          "signal_source" => signal_source,
          "signal_class" => SIGNAL_CLASS_MAP.fetch(signal_code, "evidence_quality_signal"),
          "signal_code" => signal_code,
          "run_id" => run_id,
          "phase_profile" => phase_profile,
          "treatment" => treatment,
          "evidence_maturity" => evidence_maturity,
          "source_refs" => source_refs,
          "summary" => summary,
          "signal_value" => signal_value
        }
        if metadata
          sig["source_origin"] = "central_local_run"
          sig["_metadata"] = {
            "source_repository_id" => metadata["source_repository_id"],
            "source_revision" => metadata["source_revision"],
            "review_mode" => metadata["review_mode"]
          }
        end
        sig
      end

      def entries(path)
        return [] unless path.file?

        JSON.parse(path.read).fetch("entries", [])
      rescue JSON::ParserError
        []
      end

      def caveat_entries(path)
        return [] unless path.file?

        data = JSON.parse(path.read)
        Array(data["caveats"] || data["entries"])
      rescue JSON::ParserError
        []
      end

      def by_run_id(list)
        list.each_with_object({}) { |e, acc| acc[e["run_id"]] = e }
      end
    end
  end
end
