# frozen_string_literal: true

require "json"
require "time"
require "pathname"

# Task 5: decision unit model と human sign-off record
# 根拠: tasks.md Task 5、Requirement 5 受入 1〜5、Requirement 6 受入 9、
#       design「Decision Unit Model」「Human Sign-off Record」、
#       設計再確定 finding 9（Run Close Boundary 順序＝human sign-off → validator
#       → close。human sign-off artifact 書込は validator 起動より前）。
#
# 責務（design Decision Unit Model）:
#   - raw finding をそのまま human に渡さず Step D 生成の decision unit に束ねる
#     （受入 1。本 model は束ね済み構造を受け取り human decision の記録機構を足す）
#   - 各 decision unit の human decision outcome を記録する（受入 2）
#   - human decision 不在（= pending 相当の不在）と明示 defer / reject を区別する
#     （受入 3。不在は記録値ではなく「未記録」として表す。pending を outcome 値に
#     しない＝不在の sentinel として nil を保持）
#   - LLM finding を silent に auto-adopt しない（受入 5。初期 human_decision は
#     nil のまま、明示記録がない限り approved にならない）
#   - run レベル human_signoff.json を作る（design Human Sign-off Record 正本）。
#     Run Close Boundary の起点で validator 起動より前に書く（受入 4、要件 6 受入 9）。
#     実 artifact 書込（controller への接続）と decision_units.json 書出までを担い、
#     最終 review_case.json 投影は Task 6 波。
#
# 配置: design File Placement「runtime/execution_v2/decisions/」（necessity /
# reopen / handback / signal linkage 判定層。writer 層と混在させない）。
module DualReviewer
  module Runtime
    class DecisionUnitModel
      # foundation human_signoff_status enum を継承（runtime で再定義しない）。
      # pending = 承認なし（不在）/ approved / rejected = 明示否決 / deferred = 明示保留。
      SIGNOFF_STATUSES = %w[pending approved rejected deferred].freeze

      # 明示的に記録できる human decision outcome。pending は「不在」の表現で
      # あり outcome ではないため記録値から除外する（受入 3・5）。
      RECORDABLE_DECISIONS = %w[approved rejected deferred].freeze

      # human decision が不在のときの decision state（pending 相当）。
      ABSENT_STATE = "pending"

      # finding schema linkage: human_decision_ref が指す run レベル正本の相対パス。
      HUMAN_DECISION_REF = "decisions/human_signoff.json"
      DECISION_UNITS_RELPATH = "decisions/decision_units.json"

      attr_reader :run_id

      # decision_units: Step D 統合が生成した unit 配列（7 フィールド構造）。
      # 本 model は破壊的変更を避けるため deep copy を保持する。
      def initialize(run_id:, decision_units:)
        @run_id = run_id
        @decision_units = decision_units.map { |u| deep_dup(u) }
        normalize_units!
      end

      def decision_units
        @decision_units
      end

      # 受入 2: 各 decision unit の human decision outcome を記録する。
      # 受入 3・5: 明示値のみ受理。不在表現 pending や未知値は拒否（silent 採用回避）。
      def record_human_decision(decision_unit_id:, decision:, note: nil, at: nil)
        unless RECORDABLE_DECISIONS.include?(decision)
          raise ArgumentError,
                "invalid human decision: #{decision.inspect} " \
                "(recordable: #{RECORDABLE_DECISIONS.join('/')}; " \
                "absence is represented by no record, not by 'pending')"
        end

        unit = @decision_units.find do |u|
          u.fetch("decision_unit_id") == decision_unit_id
        end
        if unit.nil?
          raise ArgumentError,
                "unknown decision_unit_id: #{decision_unit_id.inspect}"
        end

        unit["human_decision"] = decision
        unit["human_decision_timestamp"] = at || Time.now.utc.iso8601
        unit["human_decision_note"] = note
        unit
      end

      # 受入 3: 個別 unit の decision state。不在は明示 reject/defer と区別して
      # pending を返す（不在を rejected/deferred に丸めない）。
      def decision_state(decision_unit_id)
        unit = @decision_units.find do |u|
          u.fetch("decision_unit_id") == decision_unit_id
        end
        raise ArgumentError, "unknown decision_unit_id" if unit.nil?

        d = unit.fetch("human_decision")
        d.nil? ? ABSENT_STATE : d
      end

      # run 全体の sign-off 集約状態（foundation enum）。
      #   - 不在が 1 件でもあれば pending（未完。silent auto-adopt しない＝受入 5）
      #   - 明示 reject が 1 件でもあれば rejected
      #   - reject 無しで defer があれば deferred
      #   - 全件 approved なら approved
      def aggregate_signoff_status
        states = @decision_units.map do |u|
          decision_state(u.fetch("decision_unit_id"))
        end
        return "pending" if states.empty?
        return "pending" if states.include?(ABSENT_STATE)
        return "rejected" if states.include?("rejected")
        return "deferred" if states.include?("deferred")

        "approved"
      end

      # 全 decision unit が明示 approved（承認なしに closed 扱いにしないための判定）。
      def fully_signed_off?
        aggregate_signoff_status == "approved"
      end

      # design Human Sign-off Record 正本 6 フィールド（run レベル）。
      # 値は controller.write_human_signoff へ渡す前提のため artifact 書込はしない
      # （Run Close Boundary の起点書込は第1波 controller 単一経路に集約）。
      def build_human_signoff(signed_off_by:, note: nil, signed_off_at: nil)
        {
          "run_id" => @run_id,
          "human_signoff_status" => aggregate_signoff_status,
          "signed_off_by" => signed_off_by,
          "signed_off_at" => signed_off_at || Time.now.utc.iso8601,
          "covered_decision_unit_ids" =>
            @decision_units.map { |u| u.fetch("decision_unit_id") },
          "signoff_note" => note
        }
      end

      # decisions/decision_units.json 書出（7 フィールド保持）。
      # decision/sign-off ロジック層の責務範囲。raw step evidence は触らない。
      def write_decision_units(run_root:)
        path = Pathname(run_root) + DECISION_UNITS_RELPATH
        path.dirname.mkpath
        payload = {
          "run_id" => @run_id,
          "decision_units" => @decision_units
        }
        path.write(JSON.pretty_generate(payload))
        path
      end

      # finding linkage: foundation finding schema の decision_unit_id /
      # human_decision_ref がこの artifact を指す整合を出す。
      # human_decision_ref は run レベル正本 decisions/human_signoff.json を指す。
      def finding_linkage
        map = {}
        @decision_units.each do |u|
          duid = u.fetch("decision_unit_id")
          Array(u.fetch("finding_refs")).each do |fid|
            map[fid] = {
              "decision_unit_id" => duid,
              "human_decision_ref" => HUMAN_DECISION_REF
            }
          end
        end
        map
      end

      private

      # Step D 生成 unit が 7 フィールドを持つことを保証（未確定値は nil 維持）。
      def normalize_units!
        @decision_units.each do |u|
          u["decision_unit_id"] ||= nil
          u["finding_refs"] ||= []
          u["judgment_refs"] ||= []
          u["proposed_action"] ||= nil
          u["human_decision"] = nil unless u.key?("human_decision")
          unless u.key?("human_decision_timestamp")
            u["human_decision_timestamp"] = nil
          end
          u["human_decision_note"] = nil unless u.key?("human_decision_note")
        end
      end

      def deep_dup(obj)
        JSON.parse(JSON.generate(obj))
      end
    end
  end
end
