# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "open3"

# Finding 2（P1）解消: Requirement 9 の強制関数が「実 docs/coordination/ artifact」
# （実 authority-map・実 workflow-repair-procedure・実 validator 環境）に対して
# 実効的に機能することを決定的に検証する。tmpdir 仮装 fixture ではなく、
# 実 repo の正本 artifact を入力にする（読み取り検証のみ・実 artifact は書き換えない）。
#
# 本ファイルは Encoding.default_external を固定しない。Finding 3 の既定ロケール
# 起動の堅牢性も対象に含めるため、テストプロセス側でエンコーディングを偽装しない。
#
# 根拠: design 小節 7／9、Requirement 9 受入 1・5・10・11、レビュー証跡 Finding 1/2/3/5
require_relative "../../scripts/governance/ledger_generator"
require_relative "../../scripts/governance/independent_rederivation"
require_relative "../../scripts/governance/enforcement_point"

class TestReq9RealArtifacts < Minitest::Test
  REPO_ROOT = Pathname(__dir__).join("../..").expand_path
  VALIDATOR = REPO_ROOT.join("scripts/validate_implementation_governance_artifacts.rb").to_s
  # `reopen-procedure` は authority-map §6 が「確定書式適合」と宣言する唯一の
  # process。実 workflow-repair-procedure.md §2 は Step 1〜10 の単一リスト。
  REAL_REOPEN_STAGES = (1..10).map { |i| "Step #{i}" }.freeze

  def setup
    @tmp = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  # 実 authority-map × 実 workflow-repair-procedure に対する独立再導出が
  # 実 artifact 上で曖昧 fail-closed にならず Step 1〜10 を一意抽出する。
  def test_independent_rederivation_resolves_real_reopen_procedure
    rd = Governance::IndependentRederivation.new(repo_root: REPO_ROOT)
    stages = rd.rederive("reopen-procedure")
    assert_equal REAL_REOPEN_STAGES, stages,
                 "実 authority-map × 実権威文書で Step 1〜10 を一意抽出できること（Finding 1/5）"
  end

  # 台帳生成器（非共有経路）も実 authority-map から実 reopen-procedure の
  # 段集合を導出でき、独立再導出と一致する（実 artifact 上で pass 到達可能）。
  def test_ledger_generator_derives_real_reopen_procedure_stage_set
    gen = Governance::LedgerGenerator.new(repo_root: real_clone)
    result = gen.generate(
      process_id: "reopen-procedure", date: "2026-05-19",
      independent_rederivation: ->(_row) { REAL_REOPEN_STAGES }
    )
    assert_equal :created, result.status
    body = Pathname(result.ledger_path).read(encoding: "UTF-8")
    REAL_REOPEN_STAGES.each { |st| assert_includes body, st }
    refute_includes body, "| 2.1 |", "§2 内の `### 2.1` を段として拾わない（Finding 5）"
  end

  # 実 authority-map × 実権威文書 × 実生成台帳に対して validator サブモードが
  # exit 0（pass）を返す＝強制関数が実 artifact 上で pass 到達可能（Finding 1/2）。
  def test_validator_submode_passes_on_real_artifacts
    repo = real_clone
    Governance::LedgerGenerator.new(repo_root: repo).generate(
      process_id: "reopen-procedure", date: "2026-05-19",
      independent_rederivation: ->(_row) { REAL_REOPEN_STAGES }
    )
    out, status = Open3.capture2e(
      "ruby", VALIDATOR, "--rederive", "reopen-procedure",
      "--repo-root", repo.to_s, "--date", "2026-05-19"
    )
    assert_equal 0, status.exitstatus, out
    assert_includes out, "result=pass"
  end

  # Finding 3: 既定ロケール（LANG/LC_ALL/RUBYOPT 未設定）で legacy validator が
  # 例外停止せず pass する（実 docs/coordination/ artifact を実検査）。
  def test_legacy_validator_passes_under_default_locale
    env = { "LANG" => nil, "LC_ALL" => nil, "LC_CTYPE" => nil, "RUBYOPT" => nil }
    out, status = Open3.capture2e(env, "ruby", VALIDATOR, chdir: REPO_ROOT.to_s)
    assert_equal 0, status.exitstatus, out
    assert_includes out, "implementation governance artifact validation passed"
  end

  # Finding 3: rederive サブモードも既定ロケールで実 artifact を pass する。
  def test_rederive_submode_passes_under_default_locale
    repo = real_clone
    Governance::LedgerGenerator.new(repo_root: repo).generate(
      process_id: "reopen-procedure", date: "2026-05-19",
      independent_rederivation: ->(_row) { REAL_REOPEN_STAGES }
    )
    env = { "LANG" => nil, "LC_ALL" => nil, "LC_CTYPE" => nil, "RUBYOPT" => nil }
    out, status = Open3.capture2e(
      env, "ruby", VALIDATOR, "--rederive", "reopen-procedure",
      "--repo-root", repo.to_s, "--date", "2026-05-19"
    )
    assert_equal 0, status.exitstatus, out
    assert_includes out, "result=pass"
  end

  private

  # 実 authority-map・実権威文書を読み取り専用でコピーした作業 repo を作る。
  # 台帳生成（書き込み）は tmpdir 側に閉じ、実 docs/coordination/ は汚さない。
  def real_clone
    %w[
      docs/coordination/workflow-process-authority-map.md
      docs/coordination/workflow-repair-procedure.md
      operations/REVIEW_PROTOCOL.md
      operations/HUMAN_WORKFLOW.md
    ].each do |rel|
      src = REPO_ROOT + rel
      next unless src.exist?

      dst = @tmp + rel
      dst.dirname.mkpath
      dst.write(src.read(encoding: "UTF-8"))
    end
    (@tmp + "docs/coordination/ledgers").mkpath
    @tmp
  end
end
