# frozen_string_literal: true

module DualReviewer
  module Runtime
    class BaseStepExecutor
      attr_reader :asset_loader, :evidence_writer

      def initialize(asset_loader:, evidence_writer:)
        @asset_loader = asset_loader
        @evidence_writer = evidence_writer
      end

      def step_name
        raise NotImplementedError, "#{self.class} must implement #step_name"
      end

      def execute(_context)
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      private

      def foundation_prompt_path(relative_path)
        asset_loader.foundation_asset_path(relative_path)
      end

      def placeholder_prompt_identity(role:, step:)
        {
          "prompt_artifact_path" => nil,
          "prompt_id" => "runtime.#{role}.#{step}.deferred",
          "prompt_version" => nil,
          "resolution_status" => "deferred"
        }
      end
    end
  end
end
