# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "pathname"
require "json"
require "yaml"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 1: learning/ skeleton と schema versioning（自己改善所有）
# 根拠: tasks.md Task 1、design「Learning Artifact Layout」「Placement
#       Rationale」「Schema Versioning」、Requirement 2 受入 5・Requirement 5
#       受入 5、foundation 要件 3 受入 3 versioning 規約。
#       適合レビュー 2026-05-19 finding 3（決定的検証不在）の品質保証。
#
# 先にテストを置き赤を確認してから実装で緑にする（TDD）。実 fixture は読み
# 取りのみ。出力は tmpdir。実 learning/・experiments/ を汚さない。
class TestLearningLayout < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path

  def setup
    require_relative "../../scripts/self_improvement/learning_layout"
    @mod = DualReviewer::SelfImprovement::LearningLayout
  end

  # design「Learning Artifact Layout」ツリーの正本パスを機械列挙できる。
  def test_canonical_artifact_paths_match_design_layout
    expected = %w[
      findings/recurring_failure_signals.json
      findings/workflow_failure_signals.json
      findings/pattern_candidates.json
      proposals/proposal_index.json
      backtests/backtest_index.json
      templates/workflow_remediation_templates.json
      approved-updates/adoption_register.json
      rejected-updates/rejection_register.json
      rollback/rollback_register.json
    ].sort
    assert_equal expected, @mod.canonical_artifact_paths.sort
  end

  # proposal / backtest は <proposal_id> ごとの可変 artifact。所在を説明できる。
  def test_proposal_and_backtest_artifact_locations
    assert_equal "proposals/p-001.yaml",
                 @mod.proposal_artifact_path(proposal_id: "p-001")
    assert_equal "backtests/p-001.json",
                 @mod.backtest_artifact_path(proposal_id: "p-001")
    desc = @mod.artifact_locations
    assert_equal "proposals/", desc.fetch("proposal")
    assert_equal "backtests/", desc.fetch("backtest")
    assert_equal "approved-updates/adoption_register.json",
                 desc.fetch("adoption")
    assert_equal "rollback/rollback_register.json", desc.fetch("rollback")
  end

  # skeleton を冪等生成し全 index/register に schema_version を持たせる。
  # writer は mkpath 保証で ENOENT を出さない（評価 writer 不具合 非再発）。
  def test_create_skeleton_is_idempotent_and_versioned
    Dir.mktmpdir do |tmp|
      learning_root = Pathname(tmp) + "learning"
      2.times { @mod.create_skeleton(learning_root: learning_root) }

      @mod.canonical_artifact_paths.each do |rel|
        path = learning_root + rel
        assert path.file?, "skeleton artifact 未生成: #{rel}"
        payload = JSON.parse(path.read)
        assert_equal @mod::SCHEMA_VERSION, payload["schema_version"],
                     "#{rel} に schema_version が無い/不一致"
      end
    end
  end

  # 非互換変更時は schema_version を上げ、旧 version artifact も解釈可能に
  # 保つ（foundation 要件 3 受入 3 / design Schema Versioning）。
  def test_reads_older_schema_version_artifact
    Dir.mktmpdir do |tmp|
      learning_root = Pathname(tmp) + "learning"
      @mod.create_skeleton(learning_root: learning_root)
      old = learning_root + "proposals/proposal_index.json"
      old.write(JSON.pretty_generate(
                  { "schema_version" => "0.9.0", "entries" => [] }
                ))

      view = @mod.read_versioned(path: old)
      assert_equal "0.9.0", view["schema_version"]
      assert view["readable"], "旧 version artifact が解釈不能"
      refute view["incompatible"],
             "既知の旧 version を非互換扱いにしている"
    end
  end

  # schema_version 欠落 artifact は silent に既定値で読まない（versioning
  # 規約: silent な非互換編集の禁止）。
  def test_missing_schema_version_is_flagged
    Dir.mktmpdir do |tmp|
      p = Pathname(tmp) + "x.json"
      p.write(JSON.pretty_generate({ "entries" => [] }))
      view = @mod.read_versioned(path: p)
      refute view["readable"]
      assert_equal "schema_version_missing", view["diagnostic"]
    end
  end

  # mkpath 保証: 親ディレクトリが無くても書き出しで ENOENT を出さない。
  def test_write_artifact_creates_missing_parent_dirs
    Dir.mktmpdir do |tmp|
      learning_root = Pathname(tmp) + "learning"
      @mod.write_artifact(
        learning_root: learning_root,
        relative_path: "rollback/rollback_register.json",
        payload: { "entries" => [] }
      )
      written = learning_root + "rollback/rollback_register.json"
      assert written.file?
      assert_equal @mod::SCHEMA_VERSION,
                   JSON.parse(written.read)["schema_version"]
    end
  end
end
