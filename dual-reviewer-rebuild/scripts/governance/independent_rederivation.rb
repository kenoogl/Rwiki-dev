# frozen_string_literal: true

require "pathname"

# Task 13: 独立再導出 validator 拡張モード
# 根拠: Requirement 9 受入 5・3、design 小節 2／3／7
#
# 本モジュールは台帳生成器（ledger_generator.rb）のロジック・解析結果を
# 一切共有しない。authority-map の権威ソースを一次解釈で独立に再パースし、
# 段集合を再導出する。共有すると独立性が崩れるため require もしない。
module Governance
  class FailClosed < StandardError; end unless defined?(FailClosed)

  # foundation 所有の正準 validator 状態語彙（再定義しない・参照のみ）
  CANONICAL_STATUS = %w[not_run passed failed blocked].freeze

  class IndependentRederivation
    def initialize(repo_root:)
      @repo_root = Pathname(repo_root)
    end

    # 権威ソースから段集合を独立に再導出する。曖昧・未確立は fail-closed。
    def rederive(process_id)
      doc_path, section = resolve_authority(process_id)
      body = slice_section(doc_path, section)
      extract_stages(body)
    end

    private

    def slurp(path)
      Pathname(path).read(encoding: "UTF-8")
    end

    def resolve_authority(process_id)
      map = @repo_root + "docs/coordination/workflow-process-authority-map.md"
      raise FailClosed, "authority-map 不在（fail-closed）: #{map}" unless map.exist?

      hit = nil
      slurp(map).each_line do |line|
        next unless line =~ /\A\s*\|(.+)\|\s*\z/

        cols = Regexp.last_match(1).split("|").map { |c| c.strip.tr("`", "").strip }
        next unless cols.length == 3
        next if cols[0] == "process_id" || cols[0].start_with?("-")
        next unless cols[0] == process_id

        hit = cols
        break
      end
      raise FailClosed, "authority-map に process_id 不在（fail-closed）: #{process_id}" unless hit
      if hit[1] == "未確立" || hit[2] == "未確立"
        raise FailClosed, "権威ソース未確立（fail-closed）: #{process_id}"
      end

      [@repo_root + hit[1], hit[2]]
    end

    def slice_section(doc_path, section)
      raise FailClosed, "権威文書不在（fail-closed）: #{doc_path}" unless doc_path.exist?

      level = section[/\A#+/]&.length
      raise FailClosed, "authoritative_section が見出し形式でない（曖昧＝fail-closed）" unless level

      lines = slurp(doc_path).lines
      idxs = (0...lines.length).select { |i| lines[i].rstrip == section }
      raise FailClosed, "authoritative_section を一意特定できない（曖昧＝fail-closed）" unless idxs.length == 1

      out = []
      i = idxs[0] + 1
      while i < lines.length
        h = lines[i][/\A(#+)\s/, 1]
        break if h && h.length <= level

        out << lines[i]
        i += 1
      end
      out
    end

    # 独立した一次解釈：段見出しのみを走査し番号付き token を抽出する。
    def extract_stages(body)
      tokens = []
      body.each do |l|
        next unless (text = l[/\A#+\s+(.+?)\s*\z/, 1])

        tok = text[/\A(?:Step\s+\d+|\d+(?:\.\d+)*)/]
        raise FailClosed, "確定書式でない下位見出し（曖昧＝fail-closed）: #{text}" unless tok

        tokens << tok.gsub(/\s+/, " ")
      end
      raise FailClosed, "段集合抽出が空（曖昧＝fail-closed）" if tokens.empty?
      raise FailClosed, "段識別子重複（曖昧＝fail-closed）" if tokens.uniq.length != tokens.length

      tokens
    end
  end

  # 台帳と独立再導出段集合の突合。design 小節 7 (a)〜(c)。
  class RederivationValidator
    def initialize(repo_root:)
      @repo_root = Pathname(repo_root)
      @rederiver = IndependentRederivation.new(repo_root: repo_root)
    end

    Outcome = Struct.new(:ok, :lines, :reason, keyword_init: true)

    def validate(process_id:, date: nil, ledger_path: nil)
      independent = @rederiver.rederive(process_id) # 曖昧時はここで FailClosed

      path = ledger_path ? Pathname(ledger_path) : locate_ledger(process_id, date)
      unless path&.exist?
        return Outcome.new(ok: false, lines: [], reason: "台帳不在（検査不能＝fail-closed）")
      end

      text = path.read(encoding: "UTF-8")
      missing_fields = %w[process_id ledger_format_version section_content_hash authority_path]
                       .reject { |k| text.include?("#{k}:") }
      unless missing_fields.empty? && text.include?("| stage |")
        return Outcome.new(ok: false, lines: [], reason: "台帳必須欄不足（fail-closed）: #{missing_fields.join(',')}")
      end

      ledger_rows = parse_stage_rows(text)
      ledger_stages = ledger_rows.map { |r| r[:stage] }

      lines = []
      independent.each do |st|
        row = ledger_rows.find { |r| r[:stage] == st }
        if row.nil?
          lines << "stage=#{st} evidence=- status=- complete=false"
        else
          complete = !row[:evidence].empty? &&
                     (@repo_root + row[:evidence]).exist? &&
                     row[:status] == "passed"
          lines << "stage=#{st} evidence=#{row[:evidence].empty? ? '-' : row[:evidence]} " \
                   "status=#{row[:status]} complete=#{complete}"
        end
      end

      missing = independent - ledger_stages
      extra = ledger_stages - independent
      if !missing.empty?
        return Outcome.new(ok: false, lines: lines, reason: "欠落段: #{missing.join(',')}")
      elsif !extra.empty?
        return Outcome.new(ok: false, lines: lines, reason: "台帳に余剰段: #{extra.join(',')}")
      end

      Outcome.new(ok: true, lines: lines, reason: "独立再導出と台帳段集合が一致")
    end

    private

    def locate_ledger(process_id, date)
      dir = @repo_root + "docs/coordination/ledgers"
      return nil unless dir.exist?

      if date
        cand = dir + "#{process_id}-#{date}.md"
        return cand.exist? ? cand : nil
      end
      dir.children
         .select { |c| c.basename.to_s =~ /\A#{Regexp.escape(process_id)}-\d{4}-\d{2}-\d{2}\.md\z/ }
         .max_by(&:to_s)
    end

    def parse_stage_rows(text)
      rows = []
      text.each_line do |l|
        next unless l.strip.start_with?("|")

        cells = l.strip[1..-2].to_s.split("|").map(&:strip)
        next unless cells.length == 7
        next if cells[0] == "stage" || cells[0].start_with?("-")

        rows << { stage: cells[0], evidence: cells[4], status: cells[6] }
      end
      rows
    end
  end
end
