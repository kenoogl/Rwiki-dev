#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "fileutils"

# Task 6: exclusion report writer（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 6、design「Analysis Artifact Layout」
#       （classifications/exclusion_report.json）。
#       適合レビュー 2026-05-19 の writer 系不具合（出力先ディレクトリ未作成
#       での ENOENT）を再発させないため書き出し前に mkpath を保証する。
module DualReviewer
  module Evaluation
    class ExclusionReportWriter
      REL_PATH = "classifications/exclusion_report.json"

      attr_reader :analysis_root

      def initialize(analysis_root:)
        @analysis_root = Pathname(analysis_root).expand_path
      end

      def write(exclusion_report:)
        path = analysis_root + REL_PATH
        path.dirname.mkpath
        path.write(JSON.pretty_generate(exclusion_report))
        path.to_s
      end
    end
  end
end
