#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

# Task 1: paper/ directory skeleton を確定する
# （論文インターフェース所有・スクラッチ再実装）。
# 根拠: tasks.md Task 1、Requirement 2 受入 3、
#       design「Paper Artifact Layout」「Placement Rationale」。
#       適合レビュー 2026-05-19 Finding 9（paper/ skeleton 不在）解消。
#
# スクラッチ方針: 旧 v1（scripts/paper_interface/*_writer.rb 群）の出力先
# 規約は流用せず、design「Paper Artifact Layout」から正本パスを再導出して
# 単一の正本として固定する。raw evidence・core evaluation output と分離
# （基準ディレクトリが experiments/analysis/ と異なり衝突しない）。
module DualReviewer
  module PaperInterfaceV2
    module PaperLayout
      PAPER_ROOT = "paper"

      CLAIM_MAP = "paper/reports/claim_map.json"
      EVIDENCE_REGISTER = "paper/reports/evidence_register.json"
      REPORTING_FRAGMENTS = "paper/reports/reporting_fragments.json"
      TABLE_SOURCE_BUNDLE = "paper/tables/table_source_bundle.json"
      FIGURE_SOURCE_BUNDLE = "paper/figures/figure_source_bundle.json"
      PAPER_CAVEAT_REGISTER = "paper/caveats/paper_caveat_register.json"

      SUBDIRS = %w[reports tables figures caveats].freeze

      module_function

      def all_artifacts
        [
          CLAIM_MAP, EVIDENCE_REGISTER, REPORTING_FRAGMENTS,
          TABLE_SOURCE_BUNDLE, FIGURE_SOURCE_BUNDLE, PAPER_CAVEAT_REGISTER
        ]
      end

      # paper-facing artifact の正本基準ディレクトリ。上流 evaluation の
      # experiments/analysis/ とは別基準であり caveat register が衝突しない。
      def paper_caveat_basedir
        "paper/caveats"
      end

      # skeleton を物理生成する。paper_root 配下に reports/tables/figures/
      # caveats/ と各 .gitkeep を冪等に作る。
      def materialize_skeleton(paper_root:)
        SUBDIRS.each do |sub|
          dir = File.join(paper_root, sub)
          FileUtils.mkdir_p(dir)
          gitkeep = File.join(dir, ".gitkeep")
          File.write(gitkeep, "") unless File.file?(gitkeep)
        end
        paper_root
      end
    end
  end
end
