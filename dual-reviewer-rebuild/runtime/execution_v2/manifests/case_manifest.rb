# frozen_string_literal: true

# Task 2: case manifest base 必須項目
# 根拠: tasks.md Task 2、design「Case Manifest and Heuristic Resolution Model」
#       「Generic Protocol Entrypoint Rule」
#
# v2 runtime は case manifest を track-aware object として扱う。本クラスは
# base required fields の固定と検証を所有する。track-required fields は
# track ごとの固有 set を持つ（後続波で specializer が拡張する余地を残す）。
# 旧 v1 namespace（ExecutionV2 配下・instance build）はスクラッチ再構築で撤廃。
module DualReviewer
  module Runtime
    class CaseManifest
      # design「Case Manifest and Heuristic Resolution Model」base required fields
      BASE_REQUIRED_FIELDS = %w[case_id track source_refs case_manifest_ref].freeze

      # track-required fields。track 固有 required set（design 同節）。
      # 値語彙・項目は runtime 所有（foundation は列挙しない）。
      TRACK_REQUIRED_FIELDS = {
        "implementation" => %w[],
        "spec" => %w[],
        "intent" => %w[]
      }.freeze

      def self.build(payload)
        normalized = payload.transform_keys(&:to_s)
        missing = BASE_REQUIRED_FIELDS.reject do |field|
          value = normalized[field]
          !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
        end
        unless missing.empty?
          raise ArgumentError,
                "case manifest base required fields missing: #{missing.join(', ')}"
        end

        track = normalized.fetch("track")
        unless TRACK_REQUIRED_FIELDS.key?(track)
          raise ArgumentError, "unsupported case manifest track: #{track.inspect}"
        end

        source_refs = normalized.fetch("source_refs")
        unless source_refs.is_a?(Array) && source_refs.all? { |e| e.is_a?(String) && !e.empty? }
          raise ArgumentError, "source_refs must be a non-empty-string array"
        end

        normalized
      end
    end
  end
end
