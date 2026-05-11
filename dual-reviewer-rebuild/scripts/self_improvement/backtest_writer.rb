#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module SelfImprovement
    class BacktestWriter
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def write_backtests(backtests:)
        expected_paths = backtests.map { |backtest| repo_root.join("learning/backtests/#{backtest.fetch('proposal_id')}.json") }
        payload = {
          "generated_at" => backtests.first && backtests.first["tested_at"],
          "entries" => backtests.map { |backtest| index_entry(backtest) }
        }
        repo_root.join("learning/backtests/backtest_index.json").write(JSON.pretty_generate(payload))
        Dir[repo_root.join("learning/backtests/proposal-*.json")].each do |path|
          backtest_path = Pathname(path)
          backtest_path.delete unless expected_paths.include?(backtest_path)
        end
        backtests.each do |backtest|
          repo_root.join("learning/backtests/#{backtest.fetch('proposal_id')}.json").write(JSON.pretty_generate(backtest))
        end
      end

      private

      def index_entry(backtest)
        {
          "proposal_id" => backtest.fetch("proposal_id"),
          "test_mode" => backtest.fetch("test_mode"),
          "result_label" => backtest.fetch("result_label"),
          "tested_at" => backtest.fetch("tested_at")
        }
      end
    end
  end
end
