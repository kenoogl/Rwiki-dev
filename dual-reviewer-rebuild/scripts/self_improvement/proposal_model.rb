#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "set"
require "pathname"
require_relative "learning_layout"
require_relative "input_model"
require_relative "signal_extraction"

# Task 4: proposal model（unit / target layer / state machine / normalization）
# Task 8: paper narrative 分離の強制（自己改善所有・スクラッチ）
#
# 根拠: tasks.md Task 4・Task 8、Requirement 2（受入 1〜5）/ Requirement 4
#       受入 1 / Requirement 6（受入 1〜5）/ Requirement 8（受入 1〜3）、
#       design「Proposal Model §1〜§4」「Separation from Paper Narrative」
#       「Interfaces to Other Features」「Decision 1」。
#       適合レビュー 2026-05-19 finding 1/2/3 解消の品質保証対象。
#
# スクラッチ方針: 旧 v1 proposal_builder/proposal_writer/proposal_status_updater
# /proposal_provenance_resolver/history_registry（2026-05-13・旧 fixture
# corpus 前提・撤廃語彙 human_decision_mix 等）は流用せず破棄して作り直す。
# 本モジュールは第2波 SignalExtraction の proposal_groups を anchor に
# 「1 改善仮説 = 1 artifact」（Decision 1）を生成し、第1波 LearningLayout の
# proposals/ 正本パス・schema_version・mkpath 保証で出力、第1波 InputModel
# の provenance gate（必須欠落時 proposal 生成阻止）を再利用する。
#
# runtime/foundation/evaluation の schema・語彙は再定義しない（consumer 依存
# のみ）。paper-interface は self-improvement proposal を narrative source と
# しない（design Interfaces）。本モジュールは paper-facing motivation を
# proposal の主理由として単独採用しない（design Separation from Paper
# Narrative）。
module DualReviewer
  module SelfImprovement
    class ProposalModel
      # design §2 target_layer 初版 enum。
      TARGET_LAYERS = %w[prompt policy schema runtime workflow].freeze

      # design §2 source_origin 初版 enum。
      SOURCE_ORIGINS = %w[
        central_local_run imported_external_bundle manual_review_record
      ].freeze

      # design §3 proposal state。
      PROPOSAL_STATES = %w[
        draft awaiting_test tested approved rejected adopted rolled_back
      ].freeze

      # design §3 許可遷移（正本どおり）。それ以外は禁止。
      ALLOWED_TRANSITIONS = {
        "draft" => %w[awaiting_test rejected],
        "awaiting_test" => %w[tested],
        "tested" => %w[approved rejected],
        "approved" => %w[adopted rejected],
        "adopted" => %w[rolled_back]
      }.freeze

      # 終端状態（不可逆）。design §3。
      TERMINAL_STATES = %w[rejected rolled_back].freeze

      # design Drivers / Req6 受入 3: 改善 motivation の layer 区別 enum。
      # paper-facing motivation はこの enum に含めない（Task 8 / 受入 1）。
      MOTIVATION_CLASSES = %w[
        runtime_quality workflow_quality evidence_quality
      ].freeze

      # signal_class → target_layer（design §2/§4: 品質改善 vs workflow 改善
      # を曖昧にしない）。review-quality は reviewer/judge prompt 規準で直し、
      # evidence-quality は downstream 解像度に効く schema、workflow-failure は
      # workflow。runtime layer は signal_code が runtime 構造を直接示す場合。
      SIGNAL_CLASS_TARGET_LAYER = {
        "review_quality_signal" => "prompt",
        "workflow_failure_signal" => "workflow",
        "evidence_quality_signal" => "schema"
      }.freeze

      # signal_class → motivation_class（layer 区別保持・Req6 受入 3）。
      SIGNAL_CLASS_MOTIVATION = {
        "review_quality_signal" => "runtime_quality",
        "workflow_failure_signal" => "workflow_quality",
        "evidence_quality_signal" => "evidence_quality"
      }.freeze

      # paper-facing motivation 語彙（design Separation from Paper Narrative）。
      # これらは runtime-affecting proposal の主理由として単独採用しない。
      PAPER_MOTIVATION_CLASSES = %w[
        paper_convenience paper_narrative report_layer
      ].freeze

      # report-layer caveat handling は runtime-layer improvement と区別する
      # （Req6 受入 2）。runtime-affecting でない target は proposal 対象外。
      NON_RUNTIME_AFFECTING_LAYERS = %w[report paper export].freeze

      # design §4 review prioritization: workflow > schema/evidence >
      # prompt/policy。小さいほど先に review。
      LAYER_PRIORITY = {
        "workflow" => 0,
        "schema" => 1,
        "runtime" => 1,
        "policy" => 2,
        "prompt" => 2
      }.freeze

      # design §4: comparison impossibility 系 caveat を cautionary caveat
      # より先に review してよい。
      COMPARISON_IMPOSSIBILITY_CAVEATS = %w[
        single_treatment_only comparison_ineligible
        non_standard_population_member
      ].freeze

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @input = InputModel.new(repo_root: @repo_root)
        @extraction = SignalExtraction.new(repo_root: @repo_root)
        @layout = LearningLayout
      end

      def target_layers
        TARGET_LAYERS
      end

      def source_origins
        SOURCE_ORIGINS
      end

      def proposal_states
        PROPOSAL_STATES
      end

      def terminal_states
        TERMINAL_STATES
      end

      def motivation_classes
        MOTIVATION_CLASSES
      end

      # SignalExtraction の proposal_groups を返す（proposal unit anchor）。
      def signal_proposal_groups(run_roots:, analysis_root:)
        @extraction.extract(run_roots: run_roots,
                            analysis_root: analysis_root)[:proposal_groups]
      end

      # 1 proposal group = 1 proposal artifact（Decision 1）。
      # 全 proposal を learning/proposals/<id>.yaml と proposal_index.json
      # （schema_version 付き）に冪等出力する。
      def build_proposals(learning_root:, run_roots:, analysis_root:)
        res = @extraction.extract(run_roots: run_roots,
                                  analysis_root: analysis_root)
        signals = res[:signals]
        by_id = signals.each_with_object({}) do |s, acc|
          acc[s["signal_id"]] = s
        end

        proposals = []
        res[:proposal_groups].each do |group|
          members = Array(group["member_signal_ids"]).map { |id| by_id[id] }
                                                      .compact
          proposal = build_proposal_from_group(group: group, signals: members)
          proposals << proposal if proposal
        end

        write_proposals(learning_root: learning_root, proposals: proposals)
        res.merge(proposals: proposals)
      end

      # 1 group + その member signals から構造化 proposal を作る。
      # provenance 欠落・paper narrative 由来・motivation layer 外は nil を
      # 返し proposal を生成しない（Req1 受入 6 / Task 8 / Req6 受入 1・4）。
      def build_proposal_from_group(group:, signals:)
        return nil if Array(signals).empty?

        primary = signals.first
        signal_class = primary["signal_class"]

        # paper narrative 由来 signal は steady-state に入れない（Req6 受入
        # 1・4、design Separation from Paper Narrative / Interfaces）。
        return nil unless SIGNAL_CLASS_TARGET_LAYER.key?(signal_class)

        target_layer = SIGNAL_CLASS_TARGET_LAYER.fetch(signal_class)
        motivation_class = SIGNAL_CLASS_MOTIVATION.fetch(signal_class)

        # provenance 欠落/断絶時は proposal 生成を阻止する（Req1 受入 6・
        # foundation 要件 6 整合）。InputModel の gate を再利用する。
        # ただし aggregate evaluation signal（design §2.5 aggregate caveat /
        # Signal Extraction §2：caveat register 由来で単一 run に紐付かない）
        # は provenance を run_id でなく source_evidence_refs 連鎖で保持する。
        # この種は design §2.5/§4 が proposal identity を持つことを明示的に
        # 要求するため、run-centric gate で一律阻止しない（aggregate でない
        # signal は従来どおり run provenance 欠落で阻止する）。
        unless aggregate_provenance_ok?(group, primary)
          gate = @input.proposal_provenance_gate(
            signal: provenance_view(group, primary)
          )
          return nil unless gate["allowed"]
        end

        # paper-facing motivation は単独で runtime-affecting を通さない。
        sep = paper_separation_gate(
          target_layer: target_layer,
          motivation_class: motivation_class,
          motivation_evidence_refs: Array(group["source_evidence_refs"])
        )
        return nil unless sep["allowed"]

        proposal_id = build_proposal_id(group)
        repo_refs = build_repository_refs(signals)
        admission_refs = build_admission_refs(signals)

        {
          "proposal_id" => proposal_id,
          "status" => "draft",
          "target_layer" => target_layer,
          "motivation_class" => motivation_class,
          "source_evidence_refs" => Array(group["source_evidence_refs"]).uniq,
          "source_origin" => resolve_source_origin(signals),
          "source_repository_refs" => repo_refs,
          "source_admission_refs" => admission_refs,
          "problem_statement" => problem_statement(group, signals),
          "proposed_change_summary" =>
            proposed_change_summary(target_layer, group),
          "expected_benefit" => expected_benefit(motivation_class),
          "possible_risks" => possible_risks(primary),
          "required_test_mode" => required_test_mode(target_layer, primary),
          "created_at" => primary["created_at"] || "1970-01-01T00:00:00Z",
          # 補助 metadata（first-class record / review prioritization 用）。
          "normalization_kind" => group["normalization_kind"],
          "source_signal_codes" =>
            Array(group["member_signal_codes"]).uniq,
          "source_signal_ids" => Array(group["member_signal_ids"]).uniq,
          "evidence_maturity_context" => primary["evidence_maturity"],
          "caveat_code" => group["caveat_code"]
        }
      end

      # design §3 proposal state machine。許可遷移のみ通し、終端からは一切
      # 遷移させない。不正遷移は理由付きで禁止する。
      def transition(from:, to:)
        unless PROPOSAL_STATES.include?(from) &&
               PROPOSAL_STATES.include?(to)
          return { "allowed" => false, "reason" => "unknown_state",
                   "status" => from }
        end
        if TERMINAL_STATES.include?(from)
          return { "allowed" => false, "reason" => "terminal_state",
                   "status" => from }
        end

        allowed = ALLOWED_TRANSITIONS.fetch(from, [])
        if allowed.include?(to)
          { "allowed" => true, "reason" => nil, "status" => to }
        else
          { "allowed" => false, "reason" => "illegal_transition",
            "status" => from }
        end
      end

      # accepted / rejected proposal を first-class record として保持する
      # （Req2 受入 5、Req4 受入 5：invisible discard でなく preserved
      # outcome）。state machine を尊重し不正遷移は記録しない。
      def record_decision(learning_root:, proposal:, decision:, note: nil)
        from = proposal["status"]
        to = case decision
             when "accepted", "approved" then "approved"
             when "rejected" then "rejected"
             else
               return { "recorded" => false, "reason" => "unknown_decision",
                        "status" => from }
             end

        t = transition(from: from, to: to)
        unless t["allowed"]
          return { "recorded" => false, "reason" => t["reason"],
                   "status" => from }
        end

        updated = proposal.dup
        updated["status"] = to
        updated["decision_note"] = note
        write_proposal_artifact(learning_root: learning_root,
                                proposal: updated)
        update_index_status(learning_root: learning_root,
                            proposal_id: updated["proposal_id"],
                            status: to)
        { "recorded" => true, "reason" => nil, "status" => to }
      end

      # design §4 review prioritization notes（補助規約）。
      # workflow > schema/evidence > prompt/policy。aggregate caveat では
      # comparison impossibility 系を cautionary より先に review してよい。
      def prioritize_review(proposals:)
        proposals.each_with_index.sort_by do |p, idx|
          [LAYER_PRIORITY.fetch(p["target_layer"], 9),
           caveat_priority(p["caveat_code"]),
           idx]
        end.map(&:first)
      end

      # exploratory-only 由来の prompt/policy proposal は hold 候補（design
      # §4）。それ以外は通常 review。
      def review_disposition(proposal:)
        layer = proposal["target_layer"]
        maturity = proposal["evidence_maturity_context"]
        if %w[prompt policy].include?(layer) && maturity == "exploratory"
          return { "disposition" => "hold_candidate",
                   "reason" => "exploratory_only_evidence" }
        end

        { "disposition" => "review", "reason" => nil }
      end

      # Task 8 / Req6 受入 1・2: paper-facing motivation を runtime-affecting
      # proposal の主理由として単独採用しない。report-layer caveat handling
      # は runtime-layer improvement と区別する。
      def paper_separation_gate(target_layer:, motivation_class:,
                                motivation_evidence_refs:)
        if NON_RUNTIME_AFFECTING_LAYERS.include?(target_layer)
          return { "allowed" => false,
                   "reason" => "report_layer_not_runtime_affecting" }
        end
        if PAPER_MOTIVATION_CLASSES.include?(motivation_class)
          return { "allowed" => false,
                   "reason" => "paper_convenience_not_sufficient" }
        end
        unless MOTIVATION_CLASSES.include?(motivation_class)
          return { "allowed" => false,
                   "reason" => "motivation_class_not_runtime_workflow_evidence" }
        end

        { "allowed" => true, "reason" => nil }
      end

      private

      # aggregate evaluation signal は単一 run に紐付かないが provenance を
      # source_evidence_refs 連鎖（caveat register → analysis artifact）で
      # 保持する。design §2.5（aggregate caveat は proposal identity を持つ）
      # と §4（aggregate caveat proposal の review 優先順）が proposal の
      # 生成を前提とするため、run_id 不在のみを理由に阻止しない。
      # 判定: evaluation source かつ aggregate_analysis maturity かつ
      # source 連鎖（group の source_evidence_refs と signal の source_refs）
      # が非空であること。連鎖が空なら依然 provenance 不足として扱う。
      def aggregate_provenance_ok?(group, signal)
        return false unless signal["signal_source"] == "evaluation"
        return false unless signal["evidence_maturity"] == "aggregate_analysis"

        evidence = Array(group["source_evidence_refs"]) +
                   Array(signal["source_refs"])
        !evidence.empty?
      end

      # InputModel#proposal_provenance_gate へ渡す view。group の
      # source_evidence_refs と signal の source_refs / imported_provenance
      # を束ねる（どちらの key でも provenance 連鎖が辿れることを確認する）。
      def provenance_view(group, signal)
        {
          "run_id" => signal["run_id"],
          "source_evidence_refs" =>
            Array(group["source_evidence_refs"]) +
            Array(signal["source_refs"]),
          "source_refs" => Array(signal["source_refs"]),
          "imported_provenance" => signal["imported_provenance"]
        }
      end

      def build_proposal_id(group)
        kind = group["normalization_kind"]
        case kind
        when "coupled_workflow"
          "proposal-workflow-#{slug(group['run_id'])}"
        when "aggregate_caveat"
          "proposal-caveat-#{slug(group['caveat_code'])}"
        else
          code = Array(group["member_signal_codes"]).first
          "proposal-#{slug(code)}-#{slug(group['run_id'])}"
        end
      end

      def slug(value)
        value.to_s.gsub(/[^a-zA-Z0-9]+/, "-").gsub(/\A-|-\z/, "")
      end

      def resolve_source_origin(signals)
        origins = signals.map { |s| s["source_origin"] }.compact.uniq
        return origins.first if origins.size == 1 &&
                                SOURCE_ORIGINS.include?(origins.first)

        # imported が混在すれば imported を優先保持（provenance を消さない）。
        return "imported_external_bundle" if origins.include?(
          "imported_external_bundle"
        )

        "central_local_run"
      end

      # Req8 受入 2: imported 時 source repository identity / revision を保持。
      def build_repository_refs(signals)
        refs = signals.map do |s|
          md = s["_metadata"] || {}
          next nil if md["source_repository_id"].to_s.empty?

          { "source_repository_id" => md["source_repository_id"],
            "source_revision" => md["source_revision"],
            "run_id" => s["run_id"] }
        end.compact.uniq
        refs
      end

      # Req8 受入 3: imported evidence の evaluation 側 admission status を保持。
      def build_admission_refs(signals)
        signals.map do |s|
          ip = s["imported_provenance"]
          next nil unless ip

          { "source_repository_id" => ip["source_repository_id"],
            "source_revision" => ip["source_revision"],
            "admission_status" => ip["admission_status"],
            "run_id" => s["run_id"] }
        end.compact.uniq
      end

      def problem_statement(group, signals)
        case group["normalization_kind"]
        when "coupled_workflow"
          "Closely-coupled workflow failure signals recurred on the same " \
          "invalid run (#{group['remediation_surface']})."
        when "aggregate_caveat"
          "Aggregate caveat #{group['caveat_code']} recurred and warrants " \
          "an independent improvement hypothesis."
        else
          signals.first["summary"] ||
            "Recurring signal warrants an improvement hypothesis."
        end
      end

      def proposed_change_summary(target_layer, _group)
        case target_layer
        when "workflow"
          "Harden workflow checks and closure conditions so invalid or " \
          "incomplete runs are prevented earlier."
        when "prompt"
          "Tighten reviewer or judgment prompt criteria so review " \
          "outcomes become more consistent."
        when "schema"
          "Extend schema or metric extraction so downstream analysis " \
          "resolution improves."
        else
          "Adjust the targeted #{target_layer} layer per the motivating " \
          "evidence."
        end
      end

      def expected_benefit(motivation_class)
        case motivation_class
        when "workflow_quality"
          "Reduce invalid or contaminated runs before they reach evaluation."
        when "runtime_quality"
          "Improve review consistency and reduce repeated ambiguous " \
          "decisions."
        else
          "Improve evidence usability for downstream evaluation and " \
          "adoption decisions."
        end
      end

      def possible_risks(primary)
        if primary["evidence_maturity"] == "exploratory"
          ["Exploratory-only evidence is a weak adoption basis; treat as " \
           "hypothesis seed."]
        else
          ["No special risk flagged at proposal generation time."]
        end
      end

      # required_test_mode（design Replay/Backtest §1 の枠を先取り。Task 5 で
      # 詳細化）。本波は target_layer に基づく保守的既定のみ与える。
      def required_test_mode(target_layer, _primary)
        case target_layer
        when "workflow" then "manual_review"
        when "schema" then "backtest"
        else "replay"
        end
      end

      def caveat_priority(caveat_code)
        return 2 if caveat_code.to_s.empty?

        COMPARISON_IMPOSSIBILITY_CAVEATS.include?(caveat_code) ? 0 : 1
      end

      def write_proposals(learning_root:, proposals:)
        proposals.each do |p|
          write_proposal_artifact(learning_root: learning_root, proposal: p)
        end
        @layout.write_artifact(
          learning_root: learning_root,
          relative_path: "proposals/proposal_index.json",
          payload: { "entries" => proposals.map { |p| index_entry(p) } }
        )
      end

      def write_proposal_artifact(learning_root:, proposal:)
        path = Pathname(learning_root) +
               @layout.proposal_artifact_path(
                 proposal_id: proposal["proposal_id"]
               )
        path.dirname.mkpath
        body = { "schema_version" => LearningLayout::SCHEMA_VERSION }
               .merge(proposal)
        path.write(body.to_yaml)
        path
      end

      def index_entry(proposal)
        {
          "proposal_id" => proposal["proposal_id"],
          "status" => proposal["status"],
          "target_layer" => proposal["target_layer"],
          "motivation_class" => proposal["motivation_class"],
          "source_origin" => proposal["source_origin"],
          "created_at" => proposal["created_at"]
        }
      end

      def update_index_status(learning_root:, proposal_id:, status:)
        idx_path = Pathname(learning_root) + "proposals/proposal_index.json"
        return unless idx_path.file?

        idx = JSON.parse(idx_path.read)
        Array(idx["entries"]).each do |e|
          e["status"] = status if e["proposal_id"] == proposal_id
        end
        @layout.write_artifact(
          learning_root: learning_root,
          relative_path: "proposals/proposal_index.json",
          payload: { "entries" => idx["entries"] }
        )
      end
    end
  end
end
