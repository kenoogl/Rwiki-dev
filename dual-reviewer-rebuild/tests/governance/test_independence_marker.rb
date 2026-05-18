# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative "../../scripts/governance/independence_marker"

# Task 15: independent-production marker（真正性）
# 根拠: Requirement 9 受入 4、design 小節 3
class TestIndependenceMarker < Minitest::Test
  def setup
    @dir = Pathname(Dir.mktmpdir)
    (@dir + "docs/reviews").mkpath
    (@dir + "docs/coordination").mkpath
    @marker = Governance::IndependenceMarker.new(repo_root: @dir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 独立性不要の段（必須印なし）は素通り
  def test_non_required_stage_passes
    ledger = write_ledger([["Step 1", "独立証跡リンク（要件段のみ）", ""]])
    assert_equal true, @marker.verify(ledger_path: ledger)
  end

  # 必須段＋有効な独立証跡（docs/reviews 配下・存在・見出しあり）＝pass
  def test_required_stage_with_valid_independent_artifact_passes
    (@dir + "docs/reviews/cross-align-2026-05-18.md").write("# 横断整合\n\n内容。\n")
    ledger = write_ledger([["横断整合段", "必須:独立証跡", "docs/reviews/cross-align-2026-05-18.md"]])
    assert_equal true, @marker.verify(ledger_path: ledger)
  end

  # 必須段だがリンク欠落＝独立性未充足＝fail-closed
  def test_required_stage_missing_link_is_fail_closed
    ledger = write_ledger([["横断整合段", "必須:独立証跡", ""]])
    err = assert_raises(Governance::FailClosed) { @marker.verify(ledger_path: ledger) }
    assert_match(/リンク欠落/, err.message)
  end

  # リンク先不在＝fail-closed
  def test_required_stage_dangling_link_is_fail_closed
    ledger = write_ledger([["横断整合段", "必須:独立証跡", "docs/reviews/missing.md"]])
    err = assert_raises(Governance::FailClosed) { @marker.verify(ledger_path: ledger) }
    assert_match(/リンク先不在/, err.message)
  end

  # 自己申告偽装（docs/reviews|docs/coordination 配下でない経路）＝fail-closed
  def test_self_attested_path_outside_evidence_dirs_is_fail_closed
    (@dir + "scripts").mkpath
    (@dir + "scripts/fake.md").write("# x\n")
    ledger = write_ledger([["横断整合段", "必須:独立証跡", "scripts/fake.md"]])
    err = assert_raises(Governance::FailClosed) { @marker.verify(ledger_path: ledger) }
    assert_match(/自己申告|不正経路/, err.message)
  end

  # リンク先が構造不適合（見出しなし／空）＝fail-closed
  def test_structurally_nonconformant_target_is_fail_closed
    (@dir + "docs/reviews/empty.md").write("\n   \n")
    ledger = write_ledger([["横断整合段", "必須:独立証跡", "docs/reviews/empty.md"]])
    err = assert_raises(Governance::FailClosed) { @marker.verify(ledger_path: ledger) }
    assert_match(/構造不適合/, err.message)
  end

  private

  # rows: [[stage, independence_requirement, independent_evidence_ref], ...]
  def write_ledger(rows)
    header = "| stage | sot_citation | completion_predicate | independence_requirement | " \
             "evidence_artifact_path | independent_evidence_ref | stage_status |"
    sep = "|---|---|---|---|---|---|---|"
    body = rows.map do |stage, indep_req, indep_ref|
      "| #{stage} | doc#sec | 証跡存在＋構造適合 | #{indep_req} |  | #{indep_ref} | passed |"
    end
    path = @dir + "docs/coordination/ledgers-test.md"
    path.dirname.mkpath
    path.write(<<~L)
      # ledger

      - process_id: p
      - ledger_format_version: 1.0.0
      - section_content_hash: x
      - authority_path: y

      ## 段集合表

      #{header}
      #{sep}
      #{body.join("\n")}
    L
    path
  end
end
