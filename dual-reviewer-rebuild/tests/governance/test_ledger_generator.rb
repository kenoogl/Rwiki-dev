# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative "../../scripts/governance/ledger_generator"

# Task 12: 台帳生成器と既存台帳の扱い（冪等／陳腐化／改竄）
# 根拠: Requirement 9 受入 1・10・11、design 小節 1／1.1／1.3
class TestLedgerGenerator < Minitest::Test
  def setup
    @dir = Pathname(Dir.mktmpdir)
    (@dir + "docs/coordination/ledgers").mkpath
    (@dir + "operations").mkpath
    write_authority_doc(stage_count: 3)
    write_authority_map(
      "reopen-procedure" => {
        path: "operations/sample-procedure.md",
        section: "## 2. 手続き一覧"
      }
    )
    @gen = Governance::LedgerGenerator.new(repo_root: @dir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 着手前に権威ソースから段集合を導出し台帳を新規生成（Req9 受入 1）
  def test_new_generation_creates_ledger_with_provenance_and_stages
    result = @gen.generate(
      process_id: "reopen-procedure",
      date: "2026-05-18",
      independent_rederivation: matching_rederivation
    )
    assert_equal :created, result.status
    body = (@dir + "docs/coordination/ledgers/reopen-procedure-2026-05-18.md").read
    assert_includes body, "process_id"
    assert_includes body, "section_content_hash"
    assert_includes body, "Step 1"
    assert_includes body, "Step 3"
  end

  # 権威ソース曖昧（未確立行）は黙って段集合を返さず fail-closed（design 小節 4）
  def test_unresolved_authority_is_fail_closed
    write_authority_map(
      "intent-review-wave" => { path: "未確立", section: "未確立" }
    )
    gen = Governance::LedgerGenerator.new(repo_root: @dir)
    assert_raises(Governance::FailClosed) do
      gen.generate(
        process_id: "intent-review-wave",
        date: "2026-05-18",
        independent_rederivation: matching_rederivation
      )
    end
  end

  # 独立再導出が与えられない＝検査不能は pass としない（Req9 受入 11）
  def test_missing_independent_rederivation_is_fail_closed_on_existing
    @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                   independent_rederivation: matching_rederivation)
    assert_raises(Governance::FailClosed) do
      @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                     independent_rederivation: nil)
    end
  end

  # (a)(b)(c) すべて一致のときのみ冪等に再利用（作り直さない）
  def test_idempotent_when_all_three_conditions_match
    first = @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                          independent_rederivation: matching_rederivation)
    path = @dir + "docs/coordination/ledgers/reopen-procedure-2026-05-18.md"
    before = path.read
    second = @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                           independent_rederivation: matching_rederivation)
    assert_equal :created, first.status
    assert_equal :idempotent, second.status
    assert_equal before, path.read, "冪等再利用は台帳を作り直さない"
  end

  # 陳腐化／改竄（provenance 不一致）は fail-closed。理由未指定なら黙って作り直さない
  def test_stale_provenance_without_reason_is_fail_closed
    @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                  independent_rederivation: matching_rederivation)
    write_authority_doc(stage_count: 4) # 権威節の本文が変化＝hash 不一致
    assert_raises(Governance::FailClosed) do
      @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                    independent_rederivation: matching_rederivation)
    end
  end

  # 陳腐化検知時、理由付きなら旧台帳保全＋supersedes リンクで新台帳（破壊的上書き禁止）
  def test_stale_with_reason_preserves_old_and_links_supersedes
    @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                  independent_rederivation: matching_rederivation)
    old_path = @dir + "docs/coordination/ledgers/reopen-procedure-2026-05-18.md"
    old_body = old_path.read
    write_authority_doc(stage_count: 4)
    result = @gen.generate(
      process_id: "reopen-procedure",
      date: "2026-05-18",
      independent_rederivation: matching_rederivation,
      supersede_reason: "権威節改版に伴う再生成（テスト）"
    )
    assert_equal :superseded, result.status
    assert Pathname(result.superseded_path).exist?, "旧台帳は削除せず保全する"
    assert_equal old_body, Pathname(result.superseded_path).read, "旧台帳を破壊的上書きしない"
    new_body = Pathname(result.ledger_path).read
    assert_includes new_body, "supersedes"
    assert_includes new_body, "権威節改版に伴う再生成（テスト）"
  end

  # 独立再導出の段集合が生成器側と不一致なら fail-closed（理由なし）
  def test_independent_rederivation_mismatch_is_fail_closed
    @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                  independent_rederivation: matching_rederivation)
    mismatching = ->(_row) { ["Step 1", "Step 2"] } # 段欠落
    assert_raises(Governance::FailClosed) do
      @gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                    independent_rederivation: mismatching)
    end
  end

  private

  def matching_rederivation
    ->(_row) { (1..stage_count_now).map { |i| "Step #{i}" } }
  end

  def stage_count_now
    body = (@dir + "operations/sample-procedure.md").read
    body.scan(/^### Step \d+:/).size
  end

  def write_authority_doc(stage_count:)
    steps = (1..stage_count).map { |i| "### Step #{i}: 段 #{i}\n\n段 #{i} の本文。\n" }.join("\n")
    content = +"# sample-procedure\n\n## 1. 役割\n\n説明。\n\n## 2. 手続き一覧\n\n#{steps}\n## 3. 後続\n\n後続。\n"
    (@dir + "operations/sample-procedure.md").write(content)
  end

  def write_authority_map(rows)
    lines = []
    lines << "# workflow-process-authority-map"
    lines << ""
    lines << "| process_id | authority_document_path | authoritative_section |"
    lines << "|------------|-------------------------|-----------------------|"
    rows.each do |pid, r|
      lines << "| `#{pid}` | `#{r[:path]}` | `#{r[:section]}` |"
    end
    lines << ""
    (@dir + "docs/coordination/workflow-process-authority-map.md").write(lines.join("\n") + "\n")
  end
end
