# frozen_string_literal: true

require "digest"
require "pathname"

# Task 12: 台帳生成器と既存台帳の扱い（冪等／陳腐化／改竄）
# 根拠: Requirement 9 受入 1・10・11、design 小節 1／1.1／1.3
module Governance
  # 検査不能・陳腐化・改竄・曖昧をすべて fail-closed として表す
  class FailClosed < StandardError; end

  LEDGER_FORMAT_VERSION = "1.0.0"

  Result = Struct.new(:status, :ledger_path, :superseded_path, keyword_init: true)

  AuthorityRow = Struct.new(:process_id, :authority_document_path, :authoritative_section,
                            :stage_extraction_rule, keyword_init: true) do
    # stage_extraction_rule から段見出し接頭辞を取り出す（`stage_prefix=<接頭辞>`）。
    # 明示が無い行は接頭辞限定なし（従来どおり全番号付き見出しを段候補とする）。
    def stage_prefix
      stage_extraction_rule.to_s[/stage_prefix=(\S+)/, 1]
    end
  end

  class LedgerGenerator
    def initialize(repo_root:)
      @repo_root = Pathname(repo_root)
    end

    def read_utf8(path)
      Pathname(path).read(encoding: "UTF-8")
    end

    # process に着手する前に権威ソースから段集合を導出し台帳を新規生成する。
    # 既存台帳がある場合は (a) provenance 一致 ∧ (b) 構造検査合格 ∧
    # (c) 独立再導出一致 の AND を満たすときのみ冪等再利用、いずれか
    # 不満なら fail-closed（理由付きのみ supersede 再生成）。
    def generate(process_id:, date:, independent_rederivation: nil, supersede_reason: nil)
      row = authority_row(process_id)
      stages = derive_stage_set(row)
      hash = section_content_hash(row)
      ledger_path = @repo_root + "docs/coordination/ledgers/#{process_id}-#{date}.md"

      unless ledger_path.exist?
        ledger_path.dirname.mkpath
        ledger_path.write(render_ledger(process_id: process_id, row: row, stages: stages,
                                        section_hash: hash))
        return Result.new(status: :created, ledger_path: ledger_path.to_s)
      end

      existing = read_utf8(ledger_path)
      provenance_ok = existing.include?("section_content_hash: #{hash}")
      structure_ok = structurally_valid?(existing)
      independence_ok = independent_match?(independent_rederivation, row, stages)

      return Result.new(status: :idempotent, ledger_path: ledger_path.to_s) if provenance_ok && structure_ok && independence_ok

      unless supersede_reason
        raise FailClosed,
              "ledger reconciliation failed (provenance=#{provenance_ok} structure=#{structure_ok} " \
              "independence=#{independence_ok}); supersede_reason 未指定のため黙った作り直しを禁ずる"
      end

      superseded_path = preserve_old(ledger_path)
      ledger_path.write(render_ledger(process_id: process_id, row: row, stages: stages,
                                      section_hash: hash, supersedes: superseded_path.to_s,
                                      supersede_reason: supersede_reason))
      Result.new(status: :superseded, ledger_path: ledger_path.to_s,
                 superseded_path: superseded_path.to_s)
    end

    private

    def authority_row(process_id)
      map_path = @repo_root + "docs/coordination/workflow-process-authority-map.md"
      raise FailClosed, "authority-map 不在: #{map_path}" unless map_path.exist?

      read_utf8(map_path).each_line do |line|
        cells = parse_table_row(line)
        next unless cells && cells.length == 4
        next if cells[0] == "process_id" || cells[0].start_with?("-")
        next unless cells[0] == process_id

        if cells[1] == "未確立" || cells[2] == "未確立"
          raise FailClosed, "権威ソース未確立（fail-closed）: #{process_id}"
        end

        return AuthorityRow.new(process_id: cells[0], authority_document_path: cells[1],
                                authoritative_section: cells[2],
                                stage_extraction_rule: cells[3])
      end
      raise FailClosed, "authority-map に process_id 不在（fail-closed）: #{process_id}"
    end

    def parse_table_row(line)
      stripped = line.strip
      return nil unless stripped.start_with?("|") && stripped.end_with?("|")

      stripped[1..-2].split("|").map { |c| c.strip.delete("`").strip }
    end

    def section_body(row)
      doc = @repo_root + row.authority_document_path
      raise FailClosed, "権威文書不在（fail-closed）: #{doc}" unless doc.exist?

      target = row.authoritative_section
      level = target[/\A#+/]&.length
      raise FailClosed, "authoritative_section が見出し形式でない（曖昧＝fail-closed）" unless level

      lines = read_utf8(doc).lines
      starts = lines.each_index.select { |i| lines[i].rstrip == target }
      raise FailClosed, "authoritative_section を一意特定できない（曖昧＝fail-closed）" unless starts.length == 1

      body = []
      lines[(starts[0] + 1)..].each do |l|
        m = l[/\A(#+)\s/, 1]
        break if m && m.length <= level

        body << l
      end
      body
    end

    def derive_stage_set(row)
      body = section_body(row)
      prefix = row.stage_prefix
      stages = []
      body.each do |l|
        heading = l[/\A(#+)\s+(.*)/, 2]
        next unless heading

        if prefix
          # stage_prefix 明示時：当該接頭辞で始まる番号付き見出しのみを段とし、
          # 接頭辞に合致しない文書小節（補足注記 `2.1` 等）は段集合に含めない
          # （authority-map §6・正本の段集合定義に合致。Finding 5）。
          token = heading[/\A(#{Regexp.escape(prefix)}\s+\d+)/, 1]
          next unless token
        else
          token = heading[/\A(Step\s+\d+|\d+(?:\.\d+)*)/, 1]
          # prefix 非明示の process は番号付き stage 見出しの単一リストを要求。
          # 番号付きでない下位見出しが混在＝確定書式でない＝曖昧 fail-closed。
          raise FailClosed, "確定書式でない下位見出しを検出（曖昧＝fail-closed）: #{heading}" unless token
        end

        stages << token.gsub(/\s+/, " ")
      end
      raise FailClosed, "段集合の抽出が空（曖昧＝fail-closed）" if stages.empty?
      raise FailClosed, "段識別子が重複（曖昧＝fail-closed）" if stages.uniq.length != stages.length

      stages
    end

    def section_content_hash(row)
      normalized = section_body(row)
                   .map { |l| l.rstrip.gsub(/[ \t]+/, " ") }
                   .join("\n")
                   .strip
      Digest::SHA256.hexdigest(normalized)
    end

    def independent_match?(rederivation, row, stages)
      return false unless rederivation.respond_to?(:call)

      Array(rederivation.call(row)) == stages
    end

    def structurally_valid?(existing)
      %w[process_id ledger_format_version section_content_hash authority_path].all? do |key|
        existing.include?("#{key}:")
      end && existing.include?("| stage |")
    end

    def preserve_old(ledger_path)
      stamp = Time.now.strftime("%Y%m%dT%H%M%S%6N")
      superseded = Pathname("#{ledger_path}.superseded-#{stamp}.md")
      superseded.write(read_utf8(ledger_path))
      superseded
    end

    def render_ledger(process_id:, row:, stages:, section_hash:, supersedes: "", supersede_reason: "")
      rows = stages.map do |s|
        "| #{s} | #{row.authority_document_path}##{row.authoritative_section} | " \
          "証跡 artifact 存在＋構造適合 | 独立証跡リンク（要件段のみ） |  |  | not_run |"
      end.join("\n")

      <<~LEDGER
        # workflow-execution-ledger: #{process_id}

        - process_id: #{process_id}
        - ledger_format_version: #{LEDGER_FORMAT_VERSION}
        - generated_at: #{Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')}
        - authority_path: #{row.authority_document_path}
        - authoritative_section_id: #{row.authoritative_section}
        - section_content_hash: #{section_hash}
        - supersedes: #{supersedes}
        - supersede_reason: #{supersede_reason}

        ## 段集合表

        | stage | sot_citation | completion_predicate | independence_requirement | evidence_artifact_path | independent_evidence_ref | stage_status |
        |-------|--------------|----------------------|--------------------------|------------------------|--------------------------|--------------|
        #{rows}

        ## 通過マーカー記録欄

        （enforcement pass 時に追記）

        ## 遮断・検知記録欄

        （blocked / fail-closed / 陳腐化・改竄を追記）
      LEDGER
    end
  end
end
