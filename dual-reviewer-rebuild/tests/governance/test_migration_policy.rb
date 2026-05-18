# frozen_string_literal: true

require "minitest/autorun"
require "pathname"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require_relative "../../scripts/governance/migration_policy"

# Task 16: uniform application・reopen 経路・移行戦略
# 根拠: Requirement 9 受入 7・9、design 小節 5／10
class TestMigrationPolicy < Minitest::Test
  APPROVED = "2026-05-18"

  def setup
    @mp = Governance::MigrationPolicy.new(governance_design_approved_at: APPROVED)
  end

  # 全 prescribed workflow process に例外なく適用（reopen 経路を含む）
  def test_uniform_application_no_exemption
    %w[
      reopen-procedure cross-spec-alignment requirements-review-wave
      design-alignment-gate implementation-phase-execution
    ].each do |pid|
      assert_equal true, @mp.applies_to?(pid), "#{pid} は enforcement 対象でなければならない"
    end
  end

  # 特定 process を適用除外にしようとしても拒否（抜け穴化禁止）
  def test_exemption_attempt_is_rejected
    assert_raises(Governance::FailClosed) { @mp.exempt!("reopen-procedure") }
  end

  # grandfathering: design 承認以降の新規 process は適用
  def test_new_process_after_approval_is_enforced
    refute @mp.grandfathered?(process_started_at: "2026-05-19", completed: false)
  end

  # grandfathering: 承認前に既に completed の process は遡及しない
  def test_pre_approval_completed_process_is_grandfathered
    assert @mp.grandfathered?(process_started_at: "2026-05-10", completed: true)
  end

  # 承認前に開始したが未完了の process は遡及対象＝適用（抜け穴化しない）
  def test_pre_approval_incomplete_process_is_enforced
    refute @mp.grandfathered?(process_started_at: "2026-05-10", completed: false)
  end

  # 自己ブートストラップ: 導入期は手作業台帳可、定常期は不可
  def test_self_bootstrap_only_in_introduction_phase
    assert @mp.bootstrap_allowed?(phase: :introduction)
    refute @mp.bootstrap_allowed?(phase: :steady)
  end

  # ledger_format_version 移行は破壊的一括書換でなく移行指示を返す
  def test_format_migration_is_non_destructive_directive
    d = @mp.format_migration(ledger_version: "1.0.0", current_version: "1.1.0")
    assert d.migration_required
    assert_equal false, d.bulk_rewrite
    assert d.directive.is_a?(String)
  end

  def test_format_migration_not_required_when_same
    d = @mp.format_migration(ledger_version: "1.0.0", current_version: "1.0.0")
    refute d.migration_required
  end
end
