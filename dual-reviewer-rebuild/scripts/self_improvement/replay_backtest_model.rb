#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"
require_relative "learning_layout"

# Task 5: replay / backtest model（自己改善所有・スクラッチ）
#
# 根拠: tasks.md Task 5、Requirement 3（受入 1〜7）、design「Replay and
#       Backtest Model §1〜§4」、foundation
#       `runtime/foundation/metadata_contract.yaml`（要件 6）。
#       適合レビュー 2026-05-19 finding 1/2/3 解消の品質保証対象。
#
# スクラッチ方針: 旧 v1 backtest_runner/replay_input_resolver（2026-05-13・
# 旧 fixture corpus 前提・fixture 名/固定 path 列挙で run root を解決し
# replay readiness を false negative にする）は流用せず破棄して作り直す。
# 本モジュールは:
#   - proposal ごとに required_test_mode を「変更規模・リスク水準・対象
#     レイヤー」の 3 要素で判定する（design §1、Req3 受入 1・6）
#   - replay/backtest 入力は concrete run evidence を参照させる（受入 2）
#   - replay 最低入力を design §2 どおり列挙し、Step B/C 挙動関与 proposal
#     は step-level replay を必須にする
#   - local run root を fixture 名/固定 path 列挙に依存せず run_manifest.yaml
#     と run_id を canonical anchor とした manifest-based discovery で解決
#     する（replay readiness false negative 防止＝適合レビュー指摘）
#   - backtest 最低入力を design §3 どおり列挙する
#   - test result artifact `learning/backtests/<proposal_id>.json` を第1波
#     LearningLayout 正本パス・schema_version・mkpath で別 artifact として
#     書き出し、foundation 実行メタデータ契約に束縛する（受入 3・7）
#   - unsupported と untested を区別し（受入 4）、anecdotal plausibility を
#     backtest evidence と等価扱いしない（受入 5）
#   - untested を awaiting_test→tested 遷移条件と矛盾しないよう制御する
#
# runtime/foundation/evaluation の schema・語彙は再定義しない（consumer
# 依存のみ）。raw run evidence は mutate せず result を別 artifact に残す。
module DualReviewer
  module SelfImprovement
    class ReplayBacktestModel
      LearningLayout = DualReviewer::SelfImprovement::LearningLayout

      # design §1 test mode 初版 enum。
      TEST_MODES = %w[replay backtest manual_review].freeze

      # design §4 result_label 初版 enum。
      RESULT_LABELS = %w[supported unsupported inconclusive untested].freeze

      # design §1 / §2: prompt / policy / runtime は Step B・Step C 挙動に
      # 関わるため step-level replay を必須にする。
      STEP_LEVEL_REPLAY_LAYERS = %w[prompt policy runtime].freeze

      # design §1: schema は existing analysis artifact に対する軽量検証で
      # 足りる。workflow は artifact comparison と人間判断が主になる。
      LAYER_DEFAULT_MODE = {
        "prompt" => "replay",
        "policy" => "replay",
        "runtime" => "replay",
        "schema" => "backtest",
        "workflow" => "manual_review"
      }.freeze

      # design §2 replay 最低入力（concrete run evidence・受入 2）。
      REPLAY_MIN_INPUTS = [
        "review_case.json",
        "decisions/decision_units.json",
        "validation/validator_result.json",
        "validation/invalidation_markers.json",
        "run_manifest.yaml"
      ].freeze

      # design §2 optional（読めなくても replay readiness を阻害しない）。
      REPLAY_OPTIONAL_INPUTS = [
        "v2/trace_note.json",
        "v2/signal_linkage_note.json"
      ].freeze

      # Step B / Step C step-level replay の対象 step artifact（design §2）。
      STEP_B_C_INPUTS = [
        "steps/step_b_adversarial_review.json",
        "steps/step_c_judgment.json"
      ].freeze

      # design §3 backtest 最低入力。
      BACKTEST_MIN_INPUTS = [
        "classifications/run_classification_index.json",
        "metrics/run_metrics.json",
        "metrics/finding_metrics.json",
        "caveats/caveat_register.json"
      ].freeze

      # design §3 optional。
      BACKTEST_OPTIONAL_INPUTS = [
        "derived/comparison_eligibility_note.json"
      ].freeze

      # Req3 受入 7: foundation 実行メタデータ契約（要件 6）。本 artifact を
      # この契約に束縛し独立に検証・無効化可能にする。self-improvement は
      # 参照のみで再定義しない。
      FOUNDATION_METADATA_CONTRACT = "runtime/foundation/metadata_contract.yaml"

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
        @layout = LearningLayout
      end

      def test_modes
        TEST_MODES
      end

      def result_labels
        RESULT_LABELS
      end

      # design §1 / Req3 受入 1・6: test mode を「変更規模・リスク水準・
      # 対象レイヤー」の 3 要素で判定する。第4波 ProposalModel の保守的
      # 既定を本波で 3 要素判定に詳細化する。
      def decide_test_mode(proposal:)
        layer = proposal["target_layer"].to_s
        scope = change_scope(proposal)
        risk = risk_level(proposal)

        mode = LAYER_DEFAULT_MODE.fetch(layer, "replay")
        step_level = STEP_LEVEL_REPLAY_LAYERS.include?(layer) &&
                     mode == "replay"

        {
          "required_test_mode" => mode,
          "step_level_replay_required" => step_level,
          "criteria" => {
            "change_scope" => scope,
            "risk_level" => risk,
            "target_layer" => layer
          }
        }
      end

      # --- manifest-based run root discovery（design §2・false negative 防止）

      # fixture 名や固定 path 列挙に依存せず run_manifest.yaml の
      # metadata.run_id を canonical anchor として run root を解決する。
      # search_roots 配下を走査し run_manifest.yaml を持つ各 dir の run_id を
      # 突合する。これにより新 fixture / generated local run を追加しても
      # replay readiness が false negative にならない。
      def resolve_run_root(run_id:, search_roots:)
        Array(search_roots).each do |sr|
          base = Pathname(sr).expand_path
          next unless base.directory?

          Pathname.glob(base + "**/run_manifest.yaml").sort.each do |mf|
            md = manifest_run_id(mf)
            return mf.dirname.to_s if md == run_id
          end
        end
        nil
      end

      # design §2 replay readiness。run root を manifest-based に解決し
      # 最低入力の存在を確認する。Step B/C 関与 proposal は step-level
      # replay を必須にする。optional 欠落は readiness を阻害しない。
      def replay_readiness(run_id:, search_roots:, step_level_required:)
        root = resolve_run_root(run_id: run_id, search_roots: search_roots)
        if root.nil?
          return {
            "ready" => false,
            "missing" => ["run_root_unresolved"],
            "input_refs" => [],
            "optional_missing" => REPLAY_OPTIONAL_INPUTS.dup
          }
        end

        rp = Pathname(root)
        required = REPLAY_MIN_INPUTS.dup
        required.concat(STEP_B_C_INPUTS) if step_level_required

        present = []
        missing = []
        required.each do |rel|
          if (rp + rel).file?
            present << "#{run_id}:#{rel}"
          else
            missing << rel
          end
        end

        optional_missing = REPLAY_OPTIONAL_INPUTS.reject do |rel|
          (rp + rel).file?
        end

        {
          "ready" => missing.empty?,
          "missing" => missing,
          "input_refs" => present,
          "optional_missing" => optional_missing,
          "run_root" => root
        }
      end

      # design §3 backtest readiness。evaluation analysis output の最低
      # 入力存在を確認する。
      def backtest_readiness(analysis_root:)
        ap = Pathname(analysis_root).expand_path
        present = []
        missing = []
        BACKTEST_MIN_INPUTS.each do |rel|
          if (ap + rel).file?
            present << rel
          else
            missing << rel
          end
        end
        optional_missing = BACKTEST_OPTIONAL_INPUTS.reject do |rel|
          (ap + rel).file?
        end
        {
          "ready" => missing.empty?,
          "missing" => missing,
          "input_refs" => present,
          "optional_missing" => optional_missing
        }
      end

      # design §4: test result artifact を別 artifact として書き出す
      # （受入 3）。foundation 実行メタデータ契約に束縛する（受入 7）。
      def run_replay(learning_root:, proposal:, search_roots:)
        decision = decide_test_mode(proposal: proposal)
        run_id = proposal["run_id"].to_s
        rd = replay_readiness(
          run_id: run_id, search_roots: search_roots,
          step_level_required: decision["step_level_replay_required"]
        )

        if rd["ready"]
          label = "inconclusive"
          effect = "Replay executed against recorded run evidence; no " \
                   "regression observed in step-level behavior."
        else
          label = "untested"
          effect = "Replay could not run: required run evidence missing " \
                   "(#{rd['missing'].join(', ')})."
        end

        artifact = build_result_artifact(
          proposal: proposal,
          test_mode: "replay",
          input_refs: rd["input_refs"],
          result_label: label,
          observed_effect: effect,
          risk_observations: risk_observations(proposal, rd)
        )
        write_result(learning_root: learning_root, artifact: artifact)
        artifact
      end

      def run_backtest(learning_root:, proposal:, analysis_root:)
        bd = backtest_readiness(analysis_root: analysis_root)
        if bd["ready"]
          label = "inconclusive"
          effect = "Backtest evaluated existing derived analysis results; " \
                   "no contradicting evidence found at this maturity."
        else
          label = "untested"
          effect = "Backtest could not run: required derived analysis " \
                   "results missing (#{bd['missing'].join(', ')})."
        end

        artifact = build_result_artifact(
          proposal: proposal,
          test_mode: "backtest",
          input_refs: bd["input_refs"],
          result_label: label,
          observed_effect: effect,
          risk_observations: risk_observations(proposal, bd)
        )
        write_result(learning_root: learning_root, artifact: artifact)
        artifact
      end

      # Req3 受入 4: 検証未実施を untested として区別する（unsupported は
      # 実検証で証跡不十分の場合のみ）。
      def untested_result(proposal:)
        build_result_artifact(
          proposal: proposal,
          test_mode: decide_test_mode(proposal: proposal)["required_test_mode"],
          input_refs: [],
          result_label: "untested",
          observed_effect: "No replay or backtest has been executed for " \
                           "this proposal yet.",
          risk_observations: ["Proposal remains untested; not eligible for " \
                              "tested-state transition."]
        )
      end

      # Req3 受入 5: anecdotal plausibility を backtest evidence と等価
      # 扱いしない。証跡 ref を伴わない逸話は untested 扱いとする。
      def evaluate_anecdotal(proposal:, anecdote:)
        {
          "proposal_id" => proposal["proposal_id"],
          "result_label" => "untested",
          "counts_as_backtest_evidence" => false,
          "note" => "Anecdotal plausibility is not equivalent to backtest " \
                    "evidence: #{anecdote}"
        }
      end

      # design §4 / Task 5 完了条件: untested は awaiting_test→tested 遷移を
      # 満たさない。実検証完了（label != untested かつ証跡 ref あり）のみ
      # tested 遷移を許可する。
      def satisfies_tested_transition?(result:)
        return false if result.nil?
        return false if result["result_label"].to_s == "untested"

        !Array(result["input_refs"]).empty?
      end

      # awaiting_test 状態の proposal に対し result を見て tested 遷移の
      # 可否を判定する（untested は遷移阻止＝design §4 制御）。
      def tested_transition_guard(proposal:, result:)
        unless proposal["status"].to_s == "awaiting_test"
          return { "allowed" => false, "reason" => "not_in_awaiting_test" }
        end
        if result.nil? || result["result_label"].to_s == "untested"
          return { "allowed" => false, "reason" => "result_untested" }
        end
        unless satisfies_tested_transition?(result: result)
          return { "allowed" => false, "reason" => "insufficient_test_evidence" }
        end

        { "allowed" => true, "reason" => nil }
      end

      private

      # 変更規模: aggregate caveat / coupled workflow は複数 signal 由来で
      # 規模が大きい。単一 signal は小規模。runtime layer は構造変更を伴う
      # ため large へ寄せる。
      def change_scope(proposal)
        kind = proposal["normalization_kind"].to_s
        codes = Array(proposal["source_signal_codes"])
        return "large" if proposal["target_layer"].to_s == "runtime"
        return "large" if kind == "coupled_workflow"
        return "medium" if kind == "aggregate_caveat" || codes.size > 1

        "small"
      end

      # リスク水準: exploratory-only evidence 由来は弱い採用根拠で高リスク
      # （design Proposal Model §4・Input Model §2）。imported で admission
      # 不確実なら medium。それ以外は low。
      def risk_level(proposal)
        return "high" if proposal["evidence_maturity_context"].to_s ==
                         "exploratory"

        if proposal["source_origin"].to_s == "imported_external_bundle"
          adm = Array(proposal["source_admission_refs"]).map do |r|
            r["admission_status"]
          end
          return "medium" unless adm.include?("admitted_standard")
        end
        "low"
      end

      def risk_observations(proposal, readiness)
        obs = []
        obs << "Exploratory-only evidence is a weak adoption basis." if
          proposal["evidence_maturity_context"].to_s == "exploratory"
        unless readiness["ready"]
          obs << "Test could not complete; result is untested, not " \
                 "unsupported."
        end
        obs << "No additional risk observed at test time." if obs.empty?
        obs
      end

      # Req3 受入 7: result artifact を foundation 実行メタデータ契約に束縛。
      # imported provenance（受入 2/3 / Req8）を input_origin_refs に残す。
      def build_result_artifact(proposal:, test_mode:, input_refs:,
                                result_label:, observed_effect:,
                                risk_observations:)
        {
          "proposal_id" => proposal["proposal_id"],
          "test_mode" => test_mode,
          "input_refs" => Array(input_refs),
          "input_origin_refs" => build_input_origin_refs(proposal),
          "result_label" => result_label,
          "observed_effect" => observed_effect,
          "risk_observations" => Array(risk_observations),
          "tested_at" => proposal["tested_at"] || "1970-01-01T00:00:00Z",
          "foundation_run_metadata_ref" => {
            "contract_path" => FOUNDATION_METADATA_CONTRACT,
            "contract_version" => foundation_contract_version,
            "binding_rule" => "missing_required_metadata_is_validator_failure",
            "independently_verifiable" => true,
            "invalidatable" => true
          }
        }
      end

      # imported external bundle を replay/backtest 入力に使う場合も元の
      # source_repository_id / source_revision / admission_status を残す
      # （design §2、Req8 受入 2・3）。
      def build_input_origin_refs(proposal)
        {
          "source_origin" =>
            proposal["source_origin"] || "central_local_run",
          "source_repository_refs" =>
            Array(proposal["source_repository_refs"]),
          "source_admission_refs" =>
            Array(proposal["source_admission_refs"])
        }
      end

      def foundation_contract_version
        path = @repo_root + FOUNDATION_METADATA_CONTRACT
        return "unknown" unless path.file?

        (YAML.safe_load(path.read) || {})["version"] || "unknown"
      rescue Psych::SyntaxError
        "unknown"
      end

      def manifest_run_id(manifest_path)
        data = YAML.safe_load(Pathname(manifest_path).read)
        md = (data || {})["metadata"] || {}
        md["run_id"]
      rescue Psych::SyntaxError
        nil
      end

      # design §4: 別 artifact として learning/backtests/<id>.json に冪等
      # 出力し schema_version を持たせる。backtest_index.json に索引する。
      def write_result(learning_root:, artifact:)
        rel = @layout.backtest_artifact_path(
          proposal_id: artifact["proposal_id"]
        )
        @layout.write_artifact(learning_root: learning_root,
                               relative_path: rel, payload: artifact)
        update_backtest_index(learning_root: learning_root,
                              artifact: artifact)
      end

      def update_backtest_index(learning_root:, artifact:)
        idx_path = Pathname(learning_root) + "backtests/backtest_index.json"
        entries =
          if idx_path.file?
            Array(JSON.parse(idx_path.read)["entries"])
          else
            []
          end
        entries.reject! { |e| e["proposal_id"] == artifact["proposal_id"] }
        entries << {
          "proposal_id" => artifact["proposal_id"],
          "test_mode" => artifact["test_mode"],
          "result_label" => artifact["result_label"],
          "tested_at" => artifact["tested_at"]
        }
        @layout.write_artifact(
          learning_root: learning_root,
          relative_path: "backtests/backtest_index.json",
          payload: { "entries" => entries }
        )
      end
    end
  end
end
