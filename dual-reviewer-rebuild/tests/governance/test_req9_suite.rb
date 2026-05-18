# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative "../../scripts/governance/ledger_generator"
require_relative "../../scripts/governance/independent_rederivation"
require_relative "../../scripts/governance/enforcement_point"

# Task 18: Requirement 9 分のまとめテスト（単体は各 task テストで担保。
# 本ファイルは統合フローと異常系 fixture を集約する）
# 根拠: design 小節 9、プロジェクト開発方針（TDD）
class TestReq9Suite < Minitest::Test
  OP = "spec.json:approvals/phase write"

  def setup
    @dir = Pathname(Dir.mktmpdir)
    (@dir + "docs/coordination/ledgers").mkpath
    (@dir + "operations").mkpath
    (@dir + "docs/reviews").mkpath
    write_doc(3)
    write_map("reopen-procedure" => { p: "operations/p.md", s: "## 2. 手続き一覧" })
    @ledger = @dir + "docs/coordination/ledgers/reopen-procedure-2026-05-18.md"
    @ep = Governance::EnforcementPoint.new(repo_root: @dir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 統合: 生成 → 未完了で遮断 → 完了化 → pass → 通過マーカー後続確認 true
  def test_end_to_end_generate_block_complete_pass_verify
    gen
    assert_raises(Governance::FailClosed) { @ep.enforce(process_id: "reopen-procedure", operation: OP, date: "2026-05-18") }
    complete_all
    assert_equal :pass, @ep.enforce(process_id: "reopen-procedure", operation: OP, date: "2026-05-18")
    assert_equal true, @ep.verify_marker(process_id: "reopen-procedure", operation: OP, date: "2026-05-18")
  end

  # 統合: 独立再導出が台帳生成と非共有（生成器の改竄を独立に検出）
  def test_independent_rederivation_is_non_shared
    gen
    tampered = @ledger.read(encoding: "UTF-8").sub(/^\| Step 2 .*\n/, "")
    @ledger.write(tampered)
    out = `ruby #{REPO}/scripts/validate_implementation_governance_artifacts.rb --rederive reopen-procedure --repo-root #{@dir} --date 2026-05-18 2>&1`
    refute_equal 0, $?.exitstatus
    assert_includes out, "欠落段"
  end

  # 異常系: 曖昧権威ソース（未確立）→ fail-closed
  def test_abnormal_ambiguous_authority_fail_closed
    write_map("intent-review-wave" => { p: "未確立", s: "未確立" })
    ep = Governance::EnforcementPoint.new(repo_root: @dir)
    assert_raises(Governance::FailClosed) { ep.enforce(process_id: "intent-review-wave", operation: OP, date: "2026-05-18") }
  end

  # 異常系: 改竄/陳腐化台帳 → 生成器が fail-closed（理由なし再生成禁止）
  def test_abnormal_stale_ledger_fail_closed
    g = Governance::LedgerGenerator.new(repo_root: @dir)
    g.generate(process_id: "reopen-procedure", date: "2026-05-18", independent_rederivation: ->(_r) { %w[Step\ 1 Step\ 2 Step\ 3] })
    write_doc(4) # 権威節改版＝provenance 不一致
    assert_raises(Governance::FailClosed) do
      g.generate(process_id: "reopen-procedure", date: "2026-05-18", independent_rederivation: ->(_r) { %w[Step\ 1 Step\ 2 Step\ 3 Step\ 4] })
    end
  end

  # 異常系: 検査不能（台帳不在）→ pass としない（fail-closed）
  def test_abnormal_uninspectable_fail_closed
    assert_raises(Governance::FailClosed) { @ep.enforce(process_id: "reopen-procedure", operation: OP, date: "2026-05-18") }
  end

  # 異常系: enforcement 未配線＝マーカー無き後続遷移＝バイパス＝fail-closed
  def test_abnormal_bypass_without_marker_fail_closed
    gen
    complete_all
    assert_raises(Governance::FailClosed) { @ep.verify_marker(process_id: "reopen-procedure", operation: OP, date: "2026-05-18") }
  end

  private

  REPO = Pathname(__dir__).join("../..").expand_path.to_s

  def gen
    Governance::LedgerGenerator.new(repo_root: @dir).generate(
      process_id: "reopen-procedure", date: "2026-05-18",
      independent_rederivation: ->(_r) { %w[Step\ 1 Step\ 2 Step\ 3] }
    )
  end

  def complete_all
    ev = @dir + "docs/reviews/e.md"
    ev.write("# 証跡\n")
    body = @ledger.read(encoding: "UTF-8").lines.map do |l|
      if l.strip.start_with?("| Step ")
        c = l.strip[1..-2].split("|").map(&:strip)
        c[4] = "docs/reviews/e.md"
        c[6] = "passed"
        "| #{c.join(' | ')} |\n"
      else
        l
      end
    end.join
    @ledger.write(body)
  end

  def write_doc(n)
    steps = (1..n).map { |i| "### Step #{i}: 段 #{i}\n\n本文 #{i}。\n" }.join("\n")
    (@dir + "operations/p.md").write(+"# p\n\n## 1. 役割\n\n説明。\n\n## 2. 手続き一覧\n\n#{steps}\n## 3. 後\n\n後。\n")
  end

  def write_map(rows)
    lines = ["# m", "", "| process_id | authority_document_path | authoritative_section |", "|---|---|---|"]
    rows.each { |pid, r| lines << "| `#{pid}` | `#{r[:p]}` | `#{r[:s]}` |" }
    (@dir + "docs/coordination/workflow-process-authority-map.md").write(lines.join("\n") + "\n")
  end
end
