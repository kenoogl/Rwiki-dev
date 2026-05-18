#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"
require "fileutils"

# Task 6: caveat register writer（評価所有・スクラッチ再実装）
# 根拠: tasks.md Task 6、design「Analysis Artifact Layout」
#       （caveats/caveat_register.json）「Key Decision 4」（caveat は
#       machine-readable first-class artifact）。
#       適合レビュー 2026-05-19 の writer 系不具合（出力先ディレクトリ未作成
#       での ENOENT）を再発させないため書き出し前に mkpath を保証する。
#
# スクラッチ方針: 旧 v1 caveat_writer（{"entries" => caveats} 形・mkpath
# なし）は流用せず破棄して作り直す。CaveatBuilder#build の戻り全体を
# first-class artifact としてそのまま保存する（paper-interface が raw archive
# を再読せず継承できる）。
module DualReviewer
  module Evaluation
    class CaveatWriter
      REL_PATH = "caveats/caveat_register.json"

      attr_reader :analysis_root

      def initialize(analysis_root:)
        @analysis_root = Pathname(analysis_root).expand_path
      end

      def write(caveat_register:)
        path = analysis_root + REL_PATH
        path.dirname.mkpath
        path.write(JSON.pretty_generate(caveat_register))
        path.to_s
      end
    end
  end
end
