#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "pathname"

# Task 2: reference format 共通基盤（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 2、Requirement 1 受入 5、
#       design「Claim Mapping Model §3 Reference Format」。
#       適合レビュー 2026-05-19 Finding 3（構造化参照未実装。
#       "path#code" 文字列結合・basename 部分一致依存）解消。
#
# スクラッチ方針: 旧 v1 の裸パス文字列・"#{REF}##{code}" 文字列結合は
# 流用せず破棄して作り直す。全 *_ref / *_refs 系フィールドは次の構造化
# 参照のみを正本判定に使う。
#
#   ref_type:    参照先 artifact の種別
#   target_path: repo 相対パス（基準ディレクトリ起点）
#   target_id:   artifact 内の安定識別子（任意）
#
# basename / filename 部分一致を正本判定に使わない（design §1・§3）。
module DualReviewer
  module PaperInterfaceV2
    module Reference
      module_function

      # 単数 *_ref 1 個を構造化参照として組み立てる。
      def build(ref_type:, target_path:, target_id: nil)
        {
          "ref_type" => ref_type.to_s,
          "target_path" => target_path.to_s,
          "target_id" => target_id.nil? ? nil : target_id.to_s
        }
      end

      # 複数 *_refs 配列を組み立てる。
      def build_many(specs)
        Array(specs).map do |s|
          build(
            ref_type: s[:ref_type] || s["ref_type"],
            target_path: s[:target_path] || s["target_path"],
            target_id: s[:target_id] || s["target_id"]
          )
        end
      end

      # 構造化参照として妥当か。裸パス文字列・裸識別子・部分一致用文字列・
      # 不足 Hash は不可（false）。クロスドキュメント追跡を機械検証可能に
      # するための型ゲート。
      def valid?(value)
        return false unless value.is_a?(Hash)

        ref_type = value["ref_type"]
        target_path = value["target_path"]
        ref_type.is_a?(String) && !ref_type.empty? &&
          target_path.is_a?(String) && !target_path.empty?
      end

      # *_refs（配列）全件が構造化参照か。
      def all_valid?(refs)
        Array(refs).all? { |r| valid?(r) }
      end

      # 参照を repo_root（基準ディレクトリ起点の target_path）で機械解決
      # する。basename 部分一致に依存せず target_path 完全一致で解決。
      # JSON は payload を返す。
      def resolve(ref, repo_root:)
        unless valid?(ref)
          return { resolved: false, reason: "invalid_reference",
                   absolute_path: nil, payload: nil }
        end

        abs = Pathname(repo_root).join(ref["target_path"]).expand_path
        unless abs.file?
          return { resolved: false, reason: "target_missing",
                   absolute_path: abs.to_s, payload: nil }
        end

        payload =
          if abs.to_s.end_with?(".json")
            begin
              JSON.parse(abs.read)
            rescue JSON::ParserError
              nil
            end
          end
        { resolved: true, reason: nil, absolute_path: abs.to_s,
          payload: payload }
      end
    end
  end
end
