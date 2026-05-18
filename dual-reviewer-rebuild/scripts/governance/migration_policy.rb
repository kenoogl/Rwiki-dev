# frozen_string_literal: true

require "date"

# Task 16: uniform application・reopen 経路・移行戦略
# 根拠: Requirement 9 受入 7・9、design 小節 5／10
module Governance
  class FailClosed < StandardError; end unless defined?(FailClosed)

  class MigrationPolicy
    MigrationDirective = Struct.new(:migration_required, :bulk_rewrite, :directive,
                                    keyword_init: true)

    def initialize(governance_design_approved_at:)
      @approved_at = Date.parse(governance_design_approved_at)
    end

    # 全 prescribed workflow process に例外なく適用する。reopen 経路も含め、
    # 特定 process／spec phase に特化した適用除外を持たない（design 小節 5）。
    def applies_to?(_process_id)
      true
    end

    # 適用除外の試み自体を拒否する（抜け穴化禁止）。
    def exempt!(process_id)
      raise FailClosed,
            "enforcement は全 prescribed workflow process に例外なく適用される。" \
            "適用除外は許されない（fail-closed）: #{process_id}"
    end

    # grandfathering（design 小節 10）：
    # design 承認以降に開始した新規 process は適用。
    # 承認前に開始し既に completed の process のみ遡及せず除外。
    # 承認前開始でも未完了なら遡及対象＝適用（抜け穴化しない）。
    def grandfathered?(process_started_at:, completed:)
      started = Date.parse(process_started_at)
      started < @approved_at && completed
    end

    # 自己ブートストラップ（design 小節 10）：
    # 導入期（移行期）は手作業台帳を許容。証跡は workflow-gate-status.md に残す。
    # 定常期は手作業台帳を許容しない。
    def bootstrap_allowed?(phase:)
      phase == :introduction
    end

    # ledger_format_version による形式移行（design 小節 10）：
    # 破壊的一括書換を行わず、移行指示のみ返す。
    def format_migration(ledger_version:, current_version:)
      if ledger_version == current_version
        return MigrationDirective.new(migration_required: false, bulk_rewrite: false,
                                      directive: "移行不要（形式版一致）")
      end

      MigrationDirective.new(
        migration_required: true,
        bulk_rewrite: false,
        directive: "ledger_format_version #{ledger_version} → #{current_version}: " \
                   "破壊的一括書換は禁止。新規 process から新形式を適用し、" \
                   "既存台帳は読み取り互換のまま据え置く（非破壊移行）。"
      )
    end
  end
end
