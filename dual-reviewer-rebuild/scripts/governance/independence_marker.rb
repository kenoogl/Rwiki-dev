# frozen_string_literal: true

require "pathname"

# Task 15: independent-production marker（真正性）
# 根拠: Requirement 9 受入 4、design 小節 3
#
# independent-production marker は台帳内の自己申告文字列ではなく、独立プロセスが
# 生成した証跡 artifact（docs/reviews/ または docs/coordination/ 配下の実体）への
# 必須リンクとして検証する。リンク欠落・リンク先不在・経路詐称・構造不適合は
# いずれも独立性未充足＝fail-closed。
module Governance
  class FailClosed < StandardError; end unless defined?(FailClosed)

  class IndependenceMarker
    EVIDENCE_DIRS = ["docs/reviews/", "docs/coordination/"].freeze

    def initialize(repo_root:)
      @repo_root = Pathname(repo_root)
    end

    # 全 stage 行を検査。required な段が独立証跡を正しく持つことを担保する。
    # 違反は最初の 1 件で fail-closed。全て満たせば true。
    def verify(ledger_path:)
      rows = parse_stage_rows(Pathname(ledger_path).read(encoding: "UTF-8"))
      rows.each do |row|
        next unless required?(row[:independence_requirement])

        ref = row[:independent_evidence_ref].to_s.strip
        stage = row[:stage]
        if ref.empty?
          raise FailClosed, "独立性未充足: 独立証跡リンク欠落（fail-closed）: #{stage}"
        end
        unless EVIDENCE_DIRS.any? { |d| ref.start_with?(d) }
          raise FailClosed,
                "独立性未充足: 自己申告偽装＝不正経路（docs/reviews|docs/coordination 配下でない・fail-closed）: #{stage} -> #{ref}"
        end

        target = @repo_root + ref
        raise FailClosed, "独立性未充足: リンク先不在（fail-closed）: #{stage} -> #{ref}" unless target.exist?

        unless structurally_conformant?(target)
          raise FailClosed, "独立性未充足: リンク先構造不適合（fail-closed）: #{stage} -> #{ref}"
        end
      end
      true
    end

    private

    # 独立性が要求される段は independence_requirement 欄に「必須」印を持つ。
    # 生成テンプレートの記述的プレースホルダ（必須印なし）は不要扱い。
    def required?(cell)
      cell.to_s.include?("必須")
    end

    # 小節 2 と同型の構造適合：実体が存在し、最低限の markdown 構造
    # （見出し行を 1 つ以上持ち、本文が空でない）を満たす。
    def structurally_conformant?(path)
      text = path.read(encoding: "UTF-8")
      return false if text.strip.empty?

      text.lines.any? { |l| l =~ /\A#+\s+\S/ }
    end

    def parse_stage_rows(text)
      rows = []
      text.each_line do |l|
        next unless l.strip.start_with?("|")

        cells = l.strip[1..-2].to_s.split("|").map(&:strip)
        next unless cells.length == 7
        next if cells[0] == "stage" || cells[0].start_with?("-")

        rows << {
          stage: cells[0],
          independence_requirement: cells[3],
          independent_evidence_ref: cells[5]
        }
      end
      rows
    end
  end
end
