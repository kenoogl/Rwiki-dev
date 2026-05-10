# frozen_string_literal: true

require "json"
require "yaml"
require "pathname"

module DualReviewer
  module Runtime
    class FoundationAssetLoader
      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def metadata_contract
        @metadata_contract ||= load_yaml("runtime/foundation/metadata_contract.yaml")
      end

      def prompt_frontmatter_contract
        @prompt_frontmatter_contract ||= load_yaml("runtime/prompts/shared/frontmatter_contract.yaml")
      end

      def review_mode_vocabulary
        @review_mode_vocabulary ||= load_yaml("runtime/validators/contracts/review_mode_vocab.yaml")
      end

      def review_case_schema
        @review_case_schema ||= load_json("runtime/schemas/review_case.schema.json")
      end

      def seed_pattern_catalog
        @seed_pattern_catalog ||= load_yaml("runtime/patterns/seed_patterns.yaml")
      end

      def prompt_frontmatter(relative_path)
        text = foundation_asset_path(relative_path).read
        match = text.match(/\A---\n(.*?)\n---\n/m)
        raise "frontmatter not found for #{relative_path}" unless match

        YAML.safe_load(match[1], permitted_classes: [], aliases: false)
      end

      def foundation_asset_path(relative_path)
        repo_root.join(relative_path)
      end

      private

      def load_yaml(relative_path)
        YAML.load_file(foundation_asset_path(relative_path))
      end

      def load_json(relative_path)
        JSON.parse(foundation_asset_path(relative_path).read)
      end
    end
  end
end
