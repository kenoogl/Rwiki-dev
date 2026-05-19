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

# Task 14: enforcement point（曖昧判定・通過マーカー・観測性・fail-closed）
# 根拠: Requirement 9 受入 6・8・11、design 小節 4
class TestEnforcementPoint < Minitest::Test
  OP = "spec.json:approvals/phase write"

  def setup
    @dir = Pathname(Dir.mktmpdir)
    (@dir + "docs/coordination/ledgers").mkpath
    (@dir + "operations").mkpath
    (@dir + "docs/reviews").mkpath
    write_authority_doc(stage_count: 3)
    write_authority_map(
      "reopen-procedure" => { path: "operations/sample-procedure.md", section: "## 2. 手続き一覧",
                              rule: "番号付き stage 見出しの単一リスト stage_prefix=Step" }
    )
    @ledger = @dir + "docs/coordination/ledgers/reopen-procedure-2026-05-18.md"
    @ep = Governance::EnforcementPoint.new(repo_root: @dir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 全段 completion predicate 充足＋段集合一致＝pass。通過マーカーを台帳に記録
  def test_pass_records_passage_marker
    generate_ledger
    mark_all_stages_complete
    decision = @ep.enforce(process_id: "reopen-procedure", operation: OP, date: "2026-05-18")
    assert_equal :pass, decision
    body = @ledger.read(encoding: "UTF-8")
    assert_includes body, "passage_marker"
    assert_includes body, OP
    assert_includes body, "reconciliation_hash="
  end

  # 段未完了＝fail-closed（blocked）。遮断記録を台帳に残す（事後監査可能）
  def test_incomplete_stage_is_fail_closed_and_recorded
    generate_ledger # 全段 not_run
    err = assert_raises(Governance::FailClosed) do
      @ep.enforce(process_id: "reopen-procedure", operation: OP, date: "2026-05-18")
    end
    assert_match(/blocked|完了/, err.message)
    body = @ledger.read(encoding: "UTF-8")
    assert_includes body, "decision=blocked"
    assert_includes body, OP
  end

  # 台帳不在＝検査不能は pass としない（fail-closed）
  def test_absent_ledger_is_fail_closed
    err = assert_raises(Governance::FailClosed) do
      @ep.enforce(process_id: "reopen-procedure", operation: OP, date: "2026-05-18")
    end
    assert_match(/台帳不在|検査不能/, err.message)
  end

  # 権威ソース曖昧（未確立）＝fail-closed
  def test_ambiguous_authority_is_fail_closed
    write_authority_map("intent-review-wave" => { path: "未確立", section: "未確立", rule: "未確立" })
    ep = Governance::EnforcementPoint.new(repo_root: @dir)
    assert_raises(Governance::FailClosed) do
      ep.enforce(process_id: "intent-review-wave", operation: OP, date: "2026-05-18")
    end
  end

  # 不可逆操作の最小集合外＝保守的に fail-closed（曖昧扱い）
  def test_unknown_operation_is_fail_closed
    generate_ledger
    mark_all_stages_complete
    assert_raises(Governance::FailClosed) do
      @ep.enforce(process_id: "reopen-procedure", operation: "rename a local variable",
                  date: "2026-05-18")
    end
  end

  # マーカー無き後続遷移＝バイパス＝fail-closed
  def test_missing_marker_is_bypass_fail_closed
    generate_ledger
    mark_all_stages_complete
    assert_raises(Governance::FailClosed) do
      @ep.verify_marker(process_id: "reopen-procedure", operation: OP, date: "2026-05-18")
    end
    @ep.enforce(process_id: "reopen-procedure", operation: OP, date: "2026-05-18")
    assert_equal true,
                 @ep.verify_marker(process_id: "reopen-procedure", operation: OP, date: "2026-05-18")
  end

  # 承認依頼の段→証跡突合表生成自体が enforcement 対象（未 pass なら遮断）
  def test_approval_request_table_is_enforcement_targeted
    generate_ledger
    assert_raises(Governance::FailClosed) do
      @ep.approval_request_table(process_id: "reopen-procedure", date: "2026-05-18")
    end
    mark_all_stages_complete
    table = @ep.approval_request_table(process_id: "reopen-procedure", date: "2026-05-18")
    assert_includes table, "Step 1"
    assert_includes table, "evidence"
  end

  private

  def generate_ledger
    Governance::LedgerGenerator.new(repo_root: @dir).generate(
      process_id: "reopen-procedure", date: "2026-05-18",
      independent_rederivation: ->(_r) { %w[Step\ 1 Step\ 2 Step\ 3] }
    )
  end

  def mark_all_stages_complete
    ev = @dir + "docs/reviews/evidence.md"
    ev.write("# 証跡\n")
    body = @ledger.read(encoding: "UTF-8").lines.map do |l|
      if l.strip.start_with?("| Step ")
        c = l.strip[1..-2].split("|").map(&:strip)
        c[4] = "docs/reviews/evidence.md"
        c[6] = "passed"
        "| #{c.join(' | ')} |\n"
      else
        l
      end
    end.join
    @ledger.write(body)
  end

  def write_authority_doc(stage_count:)
    steps = (1..stage_count).map { |i| "### Step #{i}: 段 #{i}\n\n本文 #{i}。\n" }.join("\n")
    (@dir + "operations/sample-procedure.md").write(
      +"# s\n\n## 1. 役割\n\n説明。\n\n## 2. 手続き一覧\n\n#{steps}\n## 3. 後続\n\n後続。\n"
    )
  end

  def write_authority_map(rows)
    lines = ["# m", "",
             "| process_id | authority_document_path | authoritative_section | stage_extraction_rule |",
             "|---|---|---|---|"]
    rows.each { |pid, r| lines << "| `#{pid}` | `#{r[:path]}` | `#{r[:section]}` | `#{r[:rule]}` |" }
    (@dir + "docs/coordination/workflow-process-authority-map.md").write(lines.join("\n") + "\n")
  end
end
