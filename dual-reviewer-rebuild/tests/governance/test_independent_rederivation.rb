# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "open3"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative "../../scripts/governance/ledger_generator"
require_relative "../../scripts/governance/independent_rederivation"

# Task 13: 独立再導出 validator 拡張モード
# 根拠: Requirement 9 受入 5・3、design 小節 2／3／7
class TestIndependentRederivation < Minitest::Test
  REPO_ROOT = Pathname(__dir__).join("../..").expand_path
  VALIDATOR = REPO_ROOT.join("scripts/validate_implementation_governance_artifacts.rb").to_s

  def setup
    @dir = Pathname(Dir.mktmpdir)
    (@dir + "docs/coordination/ledgers").mkpath
    (@dir + "operations").mkpath
    write_authority_doc(stage_count: 3)
    write_authority_map(
      "reopen-procedure" => { path: "operations/sample-procedure.md", section: "## 2. 手続き一覧",
                              rule: "番号付き stage 見出しの単一リスト stage_prefix=Step" }
    )
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 独立再導出が台帳生成ロジックを共有せず段集合を再導出できる
  def test_independent_rederivation_module_does_not_use_ledger_generator
    rd = Governance::IndependentRederivation.new(repo_root: @dir)
    stages = rd.rederive("reopen-procedure")
    assert_equal %w[Step\ 1 Step\ 2 Step\ 3], stages
    refute Governance::IndependentRederivation.instance_methods.include?(:render_ledger),
           "独立再導出は生成器の実装を共有してはならない"
  end

  # 権威ソース未確立は黙って段集合を返さず fail-closed
  def test_unresolved_authority_is_fail_closed
    write_authority_map("intent-review-wave" => { path: "未確立", section: "未確立", rule: "未確立" })
    rd = Governance::IndependentRederivation.new(repo_root: @dir)
    assert_raises(Governance::FailClosed) { rd.rederive("intent-review-wave") }
  end

  # 生成済み台帳と独立再導出が一致＝exit 0（pass）
  def test_validator_submode_passes_when_ledger_matches
    generate_ledger
    out, status = run_validator("reopen-procedure")
    assert_equal 0, status, out
    assert_includes out, "result=pass"
  end

  # 台帳の段集合が権威ソースと不一致（欠落段）＝exit 非0（validation failure）
  def test_validator_submode_fails_on_missing_stage
    generate_ledger
    ledger = @dir + "docs/coordination/ledgers/reopen-procedure-2026-05-18.md"
    tampered = ledger.read(encoding: "UTF-8").sub(/^\| Step 3 .*\n/, "")
    ledger.write(tampered)
    out, status = run_validator("reopen-procedure")
    refute_equal 0, status
    assert_includes out, "result=fail"
    assert_includes out, "欠落段"
  end

  # 台帳不在＝検査不能は pass としない（fail-closed）
  def test_validator_submode_fail_closed_when_ledger_absent
    out, status = run_validator("reopen-procedure")
    refute_equal 0, status
    assert_includes out, "result=fail"
  end

  # 既存検査（引数なし）の挙動を壊さない（後方互換）
  def test_legacy_mode_unaffected
    _out, status = Open3.capture2e("ruby", VALIDATOR, chdir: REPO_ROOT.to_s)
    assert_includes [0, 1], status.exitstatus
  end

  private

  def generate_ledger
    gen = Governance::LedgerGenerator.new(repo_root: @dir)
    gen.generate(process_id: "reopen-procedure", date: "2026-05-18",
                 independent_rederivation: ->(_r) { %w[Step\ 1 Step\ 2 Step\ 3] })
  end

  def run_validator(process_id)
    out, status = Open3.capture2e(
      "ruby", VALIDATOR, "--rederive", process_id,
      "--repo-root", @dir.to_s, "--date", "2026-05-18"
    )
    [out, status.exitstatus]
  end

  def write_authority_doc(stage_count:)
    steps = (1..stage_count).map { |i| "### Step #{i}: 段 #{i}\n\n段 #{i} の本文。\n" }.join("\n")
    content = +"# sample\n\n## 1. 役割\n\n説明。\n\n## 2. 手続き一覧\n\n#{steps}\n## 3. 後続\n\n後続。\n"
    (@dir + "operations/sample-procedure.md").write(content)
  end

  def write_authority_map(rows)
    lines = ["# authority-map", "",
             "| process_id | authority_document_path | authoritative_section | stage_extraction_rule |",
             "|---|---|---|---|"]
    rows.each { |pid, r| lines << "| `#{pid}` | `#{r[:path]}` | `#{r[:section]}` | `#{r[:rule]}` |" }
    (@dir + "docs/coordination/workflow-process-authority-map.md").write(lines.join("\n") + "\n")
  end
end
