#!/usr/bin/env ruby
# frozen_string_literal: true

# 評価所有エントリ（スクラッチ再実装）。
# 旧 v1 は experiments/protocols/**/protocol-runs/*/run_manifest.yaml を
# 走査し、撤廃済み review_mode 語彙（single_review / dual_review /
# dual_reviewer_workflow）で完全一致フィルタしていた。実 runtime / 基盤
# canonical は manual_dogfooding / runtime_mediated であり、旧語彙は実
# runtime manifest を silent に 0 件化していた（適合レビュー 2026-05-19
# finding 4・基盤語彙再定義違反）。加えて v1 protocol artifact は
# experiments/protocols/_archived-2026-05-13/ へ退避済みで active state に
# 無い。
#
# 本実装は design「Analysis Population Selection」/ 評価所有
# PopulationSelector を正本に置き換える。selection policy（run_status=
# closed・standard intake complete・protocol-facing validation summary
# available・同一 case_id/phase_profile 内で比較 treatment が揃う）は
# PopulationSelector が一元所有し、本 script はその薄い CLI である。
# review_mode は foundation canonical（manual_dogfooding / runtime_mediated）
# のみを扱い再定義しない。
#
# CLI 契約: local run root を引数で受けるか --local-runs-root <dir> 配下を
# 走査する。stdout JSON に runtime_run_roots を含め、cross-feature の
# rebuild_evaluation_analysis_from_runs.rb --selection-json が消費できる
# 形を維持する。--track/--case-id/--phase-profile/--review-mode/--treatment/
# --selection-manifest/--allow-missing-summary は後方互換のため受理し
# canonical 語彙へ写像する（旧撤廃語彙は除外せず canonical に正規化）。
require "json"
require "pathname"
require "yaml"
require_relative "evaluation/local_run_loader"
require_relative "evaluation/population_selector"

repo_root = Pathname(__dir__).join("..").expand_path

# 旧撤廃語彙 → foundation canonical review_mode への正規化写像
# （評価は canonical を再定義しない・finding 4）。
LEGACY_REVIEW_MODE_NORMALIZATION = {
  "single_review" => "runtime_mediated",
  "dual_review" => "runtime_mediated",
  "dual_reviewer_workflow" => "runtime_mediated",
  "manual_dogfooding" => "manual_dogfooding",
  "runtime_mediated" => "runtime_mediated"
}.freeze

CANONICAL_REVIEW_MODES = %w[manual_dogfooding runtime_mediated].freeze

run_roots = []
local_runs_root = nil
case_id = nil
track = nil
phase_profile = nil
allowed_review_modes = nil
allowed_treatments = nil
selection_manifest_path = nil

argv = ARGV.dup
until argv.empty?
  flag = argv.shift
  case flag
  when "--local-runs-root"
    local_runs_root = argv.shift
  when "--case-id"
    case_id = argv.shift
  when "--track"
    track = argv.shift
  when "--phase-profile"
    phase_profile = argv.shift
  when "--review-mode"
    allowed_review_modes =
      argv.shift.to_s.split(",").map(&:strip).reject(&:empty?)
  when "--treatment"
    allowed_treatments =
      argv.shift.to_s.split(",").map(&:strip).reject(&:empty?)
  when "--selection-manifest"
    selection_manifest_path = argv.shift
  when "--allow-missing-summary"
    # 後方互換で受理（PopulationSelector は protocol-facing validation
    # summary を validation_refs.validator_result_ref で判定する）。
    nil
  else
    run_roots << flag
  end
end

if selection_manifest_path
  manifest_payload = YAML.safe_load(
    Pathname(File.expand_path(selection_manifest_path, Dir.pwd)).read
  ) || {}
  track ||= manifest_payload["track"]
  case_id ||= manifest_payload["case_id"]
  phase_profile ||= manifest_payload["phase_profile"]
  if manifest_payload["review_modes"]
    allowed_review_modes = Array(manifest_payload["review_modes"]).map(&:to_s)
  end
  if manifest_payload["treatments"]
    allowed_treatments = Array(manifest_payload["treatments"]).map(&:to_s)
  end
  local_runs_root ||= manifest_payload["local_runs_root"]
end

# review_mode フィルタを canonical へ正規化（旧撤廃語彙も canonical へ）。
normalized_review_modes =
  if allowed_review_modes
    allowed_review_modes
      .map { |m| LEGACY_REVIEW_MODE_NORMALIZATION.fetch(m, m) }
      .select { |m| CANONICAL_REVIEW_MODES.include?(m) }
      .uniq
  end

if local_runs_root
  base = Pathname(File.expand_path(local_runs_root, repo_root))
  run_roots = Dir.glob(base.join("*").to_s)
                 .select { |p| File.directory?(p) }
                 .sort
end

if run_roots.empty?
  abort "usage: ruby scripts/select_evaluation_run_set.rb " \
        "<run_root> [<run_root> ...] | --local-runs-root <dir> " \
        "[--phase-profile <phase>] [--review-mode <modes>] " \
        "[--treatment <treatments>] [--selection-manifest <path>]"
end

loader = DualReviewer::Evaluation::LocalRunLoader.new(repo_root: repo_root)
selector = DualReviewer::Evaluation::PopulationSelector.new(
  repo_root: repo_root
)

intake_by_root = {}
run_intakes = run_roots.map do |rr|
  expanded = Pathname(File.expand_path(rr, repo_root))
  intake = loader.load_run(run_root: expanded)
  intake_by_root[intake.fetch("metadata", {})["run_id"]] = expanded
  intake
end

# 後方互換フィルタ（canonical review_mode / treatment / case_id /
# phase_profile）を PopulationSelector 適用前段に適用する。
filtered = run_intakes.select do |intake|
  md = intake.fetch("metadata", {})
  next false if case_id && md["target_id"] != case_id &&
                 md["case_id"] != case_id
  next false if phase_profile && md["phase_profile"] != phase_profile
  if normalized_review_modes
    next false unless normalized_review_modes.include?(md["review_mode"])
  end
  if allowed_treatments
    next false unless allowed_treatments.include?(md["treatment"])
  end
  true
end

selection = selector.select(run_intakes: filtered)
selected_ids = selection.fetch("selected_run_ids")

runtime_run_roots = selected_ids.map do |rid|
  root = intake_by_root[rid]
  next nil unless root

  root.relative_path_from(repo_root).to_s
end.compact

puts JSON.pretty_generate(
  {
    "selection_policy_version" =>
      selection.dig("refresh_inputs", "selector_logic_version"),
    "track" => track,
    "case_id" => case_id,
    "phase_profile" => phase_profile,
    "review_modes" => normalized_review_modes,
    "treatments" => allowed_treatments,
    "selection_policy" => selection.fetch("selection_policy"),
    "selected_run_count" => selected_ids.length,
    "selected_run_ids" => selected_ids,
    "runtime_run_roots" => runtime_run_roots
  }
)
