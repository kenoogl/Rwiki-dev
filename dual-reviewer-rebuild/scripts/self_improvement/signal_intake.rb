#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require_relative "../evaluation/local_run_loader"
require_relative "../evaluation/classification_engine"
require_relative "signal_class_classifier"

module DualReviewer
  module SelfImprovement
    class SignalIntake
      attr_reader :repo_root, :local_run_loader, :classification_engine, :signal_class_classifier

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @local_run_loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: @repo_root)
        @classification_engine = DualReviewer::Evaluation::ClassificationEngine.new
        @signal_class_classifier = SignalClassClassifier.new
      end

      def load_runtime_signals(run_root:)
        run_intake = local_run_loader.load_run(run_root: run_root)
        classification = classification_engine.classify_local_run(run_intake: run_intake)

        {
          "runtime_source_type" => "local_run",
          "run_root" => Pathname(run_root).expand_path.to_s,
          "classification" => classification,
          "signals" => extract_runtime_signals(run_intake: run_intake, classification: classification)
        }
      end

      def load_evaluation_signals(analysis_root:)
        root = Pathname(analysis_root).expand_path
        classification_entries = load_entries(root.join("classifications/run_classification_index.json"))
        run_metric_entries = index_by_run_id(load_entries(root.join("metrics/run_metrics.json")))
        finding_metric_entries = index_by_run_id(load_entries(root.join("metrics/finding_metrics.json")))
        caveat_entries = load_entries(root.join("caveats/caveat_register.json"))

        {
          "analysis_root" => root.to_s,
          "signals" => dedupe_signals(extract_evaluation_signals(
            classification_entries: classification_entries,
            run_metric_entries: run_metric_entries,
            finding_metric_entries: finding_metric_entries,
            caveat_entries: caveat_entries
          ))
        }
      end

      private

      def extract_runtime_signals(run_intake:, classification:)
        metadata = run_intake.fetch("metadata")
        artifacts = run_intake.fetch("artifacts")
        signals = []

        decision_units = artifacts.fetch("decision_units", {}).fetch("decision_units", [])
        if decision_units.any?
          decisions = decision_units.map { |unit| unit["human_decision"] }
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "human_decision_mix",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: classification["classification"],
            source_refs: ["decisions/decision_units.json"],
            summary: "Runtime decision distribution captured for self-improvement intake.",
            signal_value: {
              "approved_count" => decisions.count("approved"),
              "rejected_count" => decisions.count("rejected"),
              "deferred_count" => decisions.count("deferred")
            }
          )
        end

        if metadata["validator_status"] == "failed"
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "validator_failed",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: classification["classification"],
            source_refs: ["validation/validator_result.json"],
            summary: "Runtime validator failed for this run.",
            signal_value: {
              "validator_status" => metadata["validator_status"],
              "human_signoff_status" => metadata["human_signoff_status"]
            }
          )
        end

        artifacts.fetch("invalidation_markers", {}).fetch("invalidation_markers", []).each do |marker|
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "invalidation_marker_issued",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: classification["classification"],
            source_refs: ["validation/invalidation_markers.json##{marker['invalidation_marker_id']}"],
            summary: "Runtime invalidation marker issued for this run.",
            signal_value: {
              "reason_code" => marker["reason_code"],
              "scope" => marker["scope"],
              "issued_by" => marker["issued_by"]
            }
          )
        end

        comparison_note = artifacts["comparison_eligibility_note"]
        if comparison_note
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "comparison_eligibility_observed",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: classification["classification"],
            source_refs: ["derived/comparison_eligibility_note.json##{comparison_note['comparison_eligibility_note_id']}"],
            summary: "Runtime recorded comparison eligibility state for this run.",
            signal_value: {
              "eligibility_status" => comparison_note["eligibility_status"],
              "reason_codes" => comparison_note["reason_codes"]
            }
          )
        end

        trace_note = artifacts["v2_trace_note"]
        if trace_note
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "v2_trace_note_available",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: classification["classification"],
            source_refs: ["v2/trace_note.json"],
            summary: "V2 trace note is available for downstream replay or provenance tracing.",
            signal_value: {
              "track" => trace_note["track"],
              "case_id" => trace_note["case_id"]
            }
          )
        end

        signal_linkage_note = artifacts["v2_signal_linkage_note"]
        if signal_linkage_note
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "v2_signal_linkage_available",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: classification["classification"],
            source_refs: ["v2/signal_linkage_note.json"],
            summary: "V2 signal linkage note is available for downstream signal extraction.",
            signal_value: {
              "linked_signal_ids" => signal_linkage_note["linked_signal_ids"],
              "comparison_eligibility_status" => signal_linkage_note["comparison_eligibility_status"]
            }
          )
        end

        if metadata["evidence_class"] == "exploratory"
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "exploratory_evidence_mode",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: classification["classification"],
            source_refs: ["run_manifest.yaml", "review_case.json"],
            summary: "Runtime metadata marks this run as exploratory evidence.",
            signal_value: {
              "evidence_class" => metadata["evidence_class"],
              "review_mode" => metadata["review_mode"]
            }
          )
        end

        if classification["classification"] == "analysis_blocked"
          signals << build_signal(
            signal_source: "runtime",
            signal_code: "analysis_precondition_gap",
            run_id: metadata["run_id"],
            phase_profile: metadata["phase_profile"],
            treatment: metadata["treatment"],
            evidence_maturity: classification["classification"],
            source_refs: classification.fetch("reason_codes"),
            summary: "Runtime run did not satisfy analysis intake preconditions.",
            signal_value: {
              "reason_codes" => classification.fetch("reason_codes"),
              "reason_details" => classification.fetch("reason_details")
            }
          )
        end

        signals
      end

      def extract_evaluation_signals(classification_entries:, run_metric_entries:, finding_metric_entries:, caveat_entries:)
        signals = []

        classification_entries.each do |entry|
          run_id = entry["run_id"]
          maturity = entry["classification"]

          case maturity
          when "exploratory"
            signals << build_signal(
              signal_source: "evaluation",
              signal_code: "exploratory_population_member",
              run_id: run_id,
              phase_profile: entry["phase_profile"],
              treatment: entry["treatment"],
              evidence_maturity: maturity,
              source_refs: ["classifications/run_classification_index.json##{run_id}"],
              summary: "Evaluation retained this run as exploratory-only evidence.",
              signal_value: {
                "reason_codes" => entry["reason_codes"],
                "reason_details" => entry["reason_details"]
              }
            )
          when "analysis_blocked"
            signals << build_signal(
              signal_source: "evaluation",
              signal_code: "analysis_blocked_population_member",
              run_id: run_id,
              phase_profile: entry["phase_profile"],
              treatment: entry["treatment"],
              evidence_maturity: maturity,
              source_refs: ["classifications/run_classification_index.json##{run_id}"],
              summary: "Evaluation could not admit this run into analysis population.",
              signal_value: {
                "reason_codes" => entry["reason_codes"],
                "reason_details" => entry["reason_details"]
              }
            )
          end

          run_metrics = run_metric_entries[run_id]
          if run_metrics && run_metrics["rejected_findings"].to_i.positive?
            signals << build_signal(
              signal_source: "evaluation",
              signal_code: "rejected_finding_cluster",
              run_id: run_id,
              phase_profile: entry["phase_profile"],
              treatment: entry["treatment"],
              evidence_maturity: maturity,
              source_refs: ["metrics/run_metrics.json##{run_id}"],
              summary: "Evaluation observed rejected findings in this run.",
              signal_value: {
                "rejected_findings" => run_metrics["rejected_findings"],
                "total_findings" => run_metrics["total_findings"]
              }
            )
          end

          if run_metrics && run_metrics["deferred_findings"].to_i.positive?
            signals << build_signal(
              signal_source: "evaluation",
              signal_code: "deferred_finding_cluster",
              run_id: run_id,
              phase_profile: entry["phase_profile"],
              treatment: entry["treatment"],
              evidence_maturity: maturity,
              source_refs: ["metrics/run_metrics.json##{run_id}"],
              summary: "Evaluation observed deferred findings in this run.",
              signal_value: {
                "deferred_findings" => run_metrics["deferred_findings"],
                "total_findings" => run_metrics["total_findings"]
              }
            )
          end

          finding_metrics = finding_metric_entries[run_id]
          unresolved_judgments = finding_metrics.dig("judgment_label_distribution", "unresolved_judgment_labels").to_i
          if finding_metrics && unresolved_judgments.positive?
            signals << build_signal(
              signal_source: "evaluation",
              signal_code: "unresolved_judgment_labels",
              run_id: run_id,
              phase_profile: entry["phase_profile"],
              treatment: entry["treatment"],
              evidence_maturity: maturity,
              source_refs: ["metrics/finding_metrics.json##{run_id}"],
              summary: "Evaluation metric extraction could not resolve judgment labels directly.",
              signal_value: {
                "judgment_ref_present" => finding_metrics.dig("judgment_label_distribution", "judgment_ref_present"),
                "unresolved_judgment_labels" => unresolved_judgments
              }
            )
          end
        end

        caveat_entries.each do |entry|
          signals << build_signal(
            signal_source: "evaluation",
            signal_code: "caveat_observed",
            run_id: nil,
            phase_profile: nil,
            treatment: nil,
            evidence_maturity: "aggregate_analysis",
            source_refs: ["caveats/caveat_register.json##{entry['caveat_code']}"],
            summary: "Evaluation emitted a caveat relevant to self-improvement intake.",
            signal_value: {
              "caveat_code" => entry["caveat_code"],
              "severity" => entry["severity"],
              "affected_scope" => entry["affected_scope"]
            }
          )
        end

        signals
      end

      def load_entries(path)
        return [] unless path.exist?

        JSON.parse(path.read).fetch("entries", [])
      end

      def index_by_run_id(entries)
        entries.each_with_object({}) do |entry, acc|
          acc[entry["run_id"]] = entry
        end
      end

      def build_signal(signal_source:, signal_code:, run_id:, phase_profile:, treatment:, evidence_maturity:, source_refs:, summary:, signal_value:)
        {
          "signal_id" => [
            signal_source,
            run_id || "aggregate",
            signal_code,
            source_refs.first.to_s.gsub(%r{[^a-zA-Z0-9]+}, "-").gsub(/^-|-$/, "")
          ].join(":"),
          "signal_source" => signal_source,
          "signal_class" => signal_class_classifier.classify(signal_code: signal_code),
          "signal_code" => signal_code,
          "run_id" => run_id,
          "phase_profile" => phase_profile,
          "treatment" => treatment,
          "evidence_maturity" => evidence_maturity,
          "source_refs" => source_refs,
          "summary" => summary,
          "signal_value" => signal_value
        }
      end

      def dedupe_signals(signals)
        signals.uniq { |signal| signal["signal_id"] }
      end
    end
  end
end
