# frozen_string_literal: true

require "digest"
require "pathname"

require_relative "independent_rederivation"
require_relative "independence_marker"

# Task 14: enforcement point（曖昧判定・通過マーカー・観測性・fail-closed）
# 根拠: Requirement 9 受入 6・8・11、design 小節 4
module Governance
  class FailClosed < StandardError; end unless defined?(FailClosed)

  class EnforcementPoint
    # 不可逆ワークフロー操作の最小集合（design 小節 4。捕捉対象集合は設計で閉じる）
    IRREVERSIBLE_OPERATIONS = [
      "spec.json:approvals/phase write",
      "workflow-gate-status.md:status transition",
      "workflow-gate-status.md:reopen append",
      "cross-spec alignment memo finalize",
      "phase evidence summary generate",
      "gate package generate",
      "approval request table generate"
    ].freeze

    def initialize(repo_root:)
      @repo_root = Pathname(repo_root)
      @validator = RederivationValidator.new(repo_root: repo_root)
      @rederiver = IndependentRederivation.new(repo_root: repo_root)
      @independence = IndependenceMarker.new(repo_root: repo_root)
    end

    # 不可逆操作の直前判定。
    # pass ⇔ 台帳存在 ∧ 全段 completion predicate 充足 ∧ 独立再導出突合一致。
    # いずれか不成立・検査不能・曖昧は pass とみなさず遮断（fail-closed）。
    def enforce(process_id:, operation:, date: nil, ledger_path: nil)
      ledger = resolve_ledger(process_id, date, ledger_path)

      unless IRREVERSIBLE_OPERATIONS.include?(operation)
        record(ledger, decision: "blocked", process_id: process_id, operation: operation,
                       reason: "不可逆操作最小集合外（曖昧＝fail-closed）")
        raise FailClosed, "blocked: 不可逆操作最小集合外（曖昧＝fail-closed）: #{operation}"
      end

      begin
        outcome = @validator.validate(process_id: process_id, date: date,
                                      ledger_path: ledger_path)
      rescue FailClosed => e
        record(ledger, decision: "blocked", process_id: process_id, operation: operation,
                       reason: "権威ソース曖昧/検査不能: #{e.message}")
        raise FailClosed, "blocked: #{e.message}"
      end

      unless outcome.ok
        record(ledger, decision: "blocked", process_id: process_id, operation: operation,
                       reason: outcome.reason)
        raise FailClosed, "blocked: #{outcome.reason}"
      end

      incomplete = outcome.lines.reject { |l| l.include?("complete=true") }
      unless incomplete.empty?
        record(ledger, decision: "blocked", process_id: process_id, operation: operation,
                       reason: "段未完了（completion predicate 未充足）")
        raise FailClosed, "blocked: 段未完了（completion predicate 未充足）"
      end

      begin
        @independence.verify(ledger_path: ledger)
      rescue FailClosed => e
        record(ledger, decision: "blocked", process_id: process_id, operation: operation,
                       reason: e.message)
        raise FailClosed, "blocked: #{e.message}"
      end

      write_passage_marker(ledger, process_id: process_id, operation: operation,
                                   stages: @rederiver.rederive(process_id))
      :pass
    end

    # 後続承認依頼・次 process 着手時のマーカー存在・整合確認。
    # マーカー無き遷移＝バイパス＝fail-closed。
    def verify_marker(process_id:, operation:, date: nil, ledger_path: nil)
      ledger = resolve_ledger(process_id, date, ledger_path)
      unless ledger&.exist?
        raise FailClosed, "blocked: 台帳不在のためマーカー確認不能（fail-closed）"
      end

      body = ledger.read(encoding: "UTF-8")
      present = body.lines.any? do |l|
        l.include?("passage_marker") && l.include?("process_id=#{process_id}") &&
          l.include?("operation=#{operation}")
      end
      raise FailClosed, "blocked: 通過マーカー不在＝バイパス（fail-closed）" unless present

      true
    end

    # 人間承認依頼の段→証跡突合表。生成自体を enforcement 対象にする（AC8）。
    def approval_request_table(process_id:, date: nil, ledger_path: nil)
      enforce(process_id: process_id, operation: "approval request table generate",
              date: date, ledger_path: ledger_path)

      ledger = resolve_ledger(process_id, date, ledger_path)
      rows = ledger.read(encoding: "UTF-8").lines.select { |l| l.strip.start_with?("| Step ") }
      header = "| stage | evidence_artifact_path | stage_status |"
      sep = "|---|---|---|"
      body = rows.map do |l|
        c = l.strip[1..-2].split("|").map(&:strip)
        "| #{c[0]} | #{c[4]} | #{c[6]} |"
      end
      ([header, sep] + body).join("\n")
    end

    private

    def resolve_ledger(process_id, date, ledger_path)
      return Pathname(ledger_path) if ledger_path

      dir = @repo_root + "docs/coordination/ledgers"
      return nil unless dir.exist?

      if date
        cand = dir + "#{process_id}-#{date}.md"
        return cand
      end
      dir.children
         .select { |c| c.basename.to_s =~ /\A#{Regexp.escape(process_id)}-\d{4}-\d{2}-\d{2}\.md\z/ }
         .max_by(&:to_s)
    end

    def ledger_section_hash(ledger)
      return "" unless ledger&.exist?

      m = ledger.read(encoding: "UTF-8")[/section_content_hash:\s*(\S+)/, 1]
      m.to_s
    end

    def write_passage_marker(ledger, process_id:, operation:, stages:)
      hash = Digest::SHA256.hexdigest("#{stages.join('|')}::#{ledger_section_hash(ledger)}")
      line = "- passage_marker process_id=#{process_id} operation=#{operation} " \
             "timestamp=#{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')} reconciliation_hash=#{hash}"
      insert_after_heading(ledger, "## 通過マーカー記録欄", line)
    end

    def record(ledger, decision:, process_id:, operation:, reason:)
      return unless ledger&.exist?

      line = "- decision=#{decision} process_id=#{process_id} operation=#{operation} " \
             "reason=#{reason} timestamp=#{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}"
      insert_after_heading(ledger, "## 遮断・検知記録欄", line)
    end

    def insert_after_heading(ledger, heading, line)
      lines = ledger.read(encoding: "UTF-8").lines
      idx = lines.index { |l| l.rstrip == heading }
      if idx
        lines.insert(idx + 1, "\n#{line}\n")
      else
        lines << "\n#{heading}\n\n#{line}\n"
      end
      ledger.write(lines.join)
    end
  end
end
