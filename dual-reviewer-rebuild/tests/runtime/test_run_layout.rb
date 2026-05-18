# frozen_string_literal: true

require "minitest/autorun"
require "pathname"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 1: code / run directory skeleton
# 根拠: tasks.md Task 1、design「Runtime Artifact Layout」「File Placement for v2 Runtime Core」
# 外部依存なし（gem 不使用）・repo 内で完結。
class TestRunLayout < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/contracts/run_layout"
    @layout = DualReviewer::Runtime::RunLayout
  end

  # 1 run の正本ディレクトリ構造（design「Runtime Artifact Layout」のツリー）を
  # 機械的に列挙できる。run_id 相対の正準 artifact パスを返す。
  def test_canonical_run_artifacts_enumerable
    rels = @layout.run_relative_artifacts("run-x")
    expected = %w[
      experiments/runs/run-x/run_manifest.yaml
      experiments/runs/run-x/review_case.json
      experiments/runs/run-x/steps/step_a_primary_detection.json
      experiments/runs/run-x/steps/step_b_adversarial_review.json
      experiments/runs/run-x/steps/step_c_judgment.json
      experiments/runs/run-x/steps/step_d_integration.json
      experiments/runs/run-x/decisions/decision_units.json
      experiments/runs/run-x/decisions/human_signoff.json
      experiments/runs/run-x/failures/failure_observation.json
      experiments/runs/run-x/v2/review_artifact.json
      experiments/runs/run-x/v2/metric_snapshot.json
      experiments/runs/run-x/v2/trace_note.json
      experiments/runs/run-x/v2/signal_linkage_note.json
      experiments/runs/run-x/validation/validator_result.json
      experiments/runs/run-x/validation/invalidation_markers.json
      experiments/runs/run-x/derived/runtime_summary.json
      experiments/runs/run-x/derived/comparison_eligibility_note.json
      experiments/runs/run-x/derived/invalid_run_triage_note.json
    ]
    assert_equal expected.sort, rels.sort
  end

  # run の正準サブディレクトリ集合（design Placement Rationale 準拠）
  def test_canonical_subdirectories
    assert_equal %w[decisions derived failures steps v2 validation],
                 @layout.run_subdirectories.sort
  end

  # 各 artifact に説明（Placement Rationale 準拠の役割）が付く＝
  # 「artifact layout を機械的に列挙・説明できる」完了条件
  def test_artifact_descriptions_present
    desc = @layout.artifact_catalog
    %w[run_manifest.yaml review_case.json steps/step_a_primary_detection.json
       decisions/decision_units.json failures/failure_observation.json
       v2/review_artifact.json validation/validator_result.json
       derived/comparison_eligibility_note.json].each do |key|
      assert desc.key?(key), "catalog 欠落: #{key}"
      refute desc.fetch(key).to_s.strip.empty?, "説明が空: #{key}"
    end
  end

  def test_run_root_is_run_id_relative
    assert_equal "experiments/runs/run-abc",
                 @layout.run_root_relative("run-abc")
  end

  # runtime code 配置規約（design「File Placement for v2 Runtime Core」）が
  # ディレクトリとして存在し、責務分離されている
  def test_code_placement_directories_exist
    %w[
      runtime/execution_v2/manifests
      runtime/execution_v2/analyzers
      runtime/execution_v2/decisions
      runtime/execution_v2/writers
      runtime/execution_v2/contracts
      scripts/protocol_runners
      scripts/track_runs
    ].each do |rel|
      assert (ROOT + rel).directory?, "code 配置ディレクトリ欠落: #{rel}"
    end
  end

  # 配置規約をテストで表現できる（completion 条件）：
  # analyzer / downstream 変換 / manifest logic を混在させない役割を機械可読に持つ
  def test_code_placement_role_map
    roles = @layout.code_placement_roles
    assert_equal "case manifest 読込・track specialization 解決",
                 roles.fetch("runtime/execution_v2/manifests/")
    assert roles.key?("runtime/execution_v2/analyzers/")
    assert roles.key?("runtime/execution_v2/decisions/")
    assert roles.key?("runtime/execution_v2/writers/")
    assert roles.key?("runtime/execution_v2/contracts/")
    assert roles.key?("scripts/protocol_runners/")
    assert roles.key?("scripts/track_runs/")
    # 混在禁止ルール（design「File Placement」ルール）
    assert_includes @layout.placement_separation_rules,
                    "analyzer logic を batch script に入れない"
    assert_includes @layout.placement_separation_rules,
                    "downstream 変換 logic を execution core に混ぜない"
    assert_includes @layout.placement_separation_rules,
                    "manifest logic を writer に混ぜない"
  end
end
