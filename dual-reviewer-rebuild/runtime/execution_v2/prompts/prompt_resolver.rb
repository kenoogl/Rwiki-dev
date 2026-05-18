# frozen_string_literal: true

require "yaml"
require "pathname"

# Task 4: prompt resolution model
# 根拠: tasks.md Task 4、Requirement 3（受入 1〜5）、Requirement 8 受入 6、
#       design「Prompt Resolution Model」「Role and Step Mapping」
#       「Prompt Identity Recording」、設計再確定 finding 2。
#
# finding 2（再確定境界・本波の実装拘束）:
#   prompt 解決の唯一の入力は
#     (a) foundation の現行 prompt frontmatter 規約
#         （prompt_id / version / role / step / language / source_ref）
#     (b) runtime/foundation/layer1_framework.yaml の asset_locations
#         （特に asset_locations.prompts の role/step→repo 相対パス）
#   とする。旧 prompts/shared/frontmatter_contract.yaml 等の撤廃済み資産は参照しない。
#   resolution order:
#     1 = foundation canonical prompt path（= layer1_framework.yaml の
#         asset_locations.prompts。他 foundation 資産を canonical path 源にしない）
#     2 = runtime 所有の role/phase override path
#     3 = 曖昧なら explicit failure
#   selection/override の適用順序は runtime 所有
#   （foundation は override_extension_point の所在のみ固定）。
#
# 配置: prompt 解決は analyzer / manifest / writer のいずれにも混ぜない独立モジュール
#       （design「File Placement」: execution core に変換ロジックを混ぜない）。
module DualReviewer
  module Runtime
    class PromptResolver
      class PromptResolutionError < StandardError; end

      # design「Role and Step Mapping」の正本。Step D は role なし
      # （言語モデル非依存の機械統合のため prompt 不要）。
      ROLE_BY_STEP = {
        "primary_detection" => "primary_reviewer",
        "adversarial_review" => "adversarial_reviewer",
        "judgment" => "judgment_reviewer",
        "integration" => nil
      }.freeze

      # foundation prompt frontmatter 規約（finding 2 (a)）。
      FRONTMATTER_KEYS = %w[prompt_id version role step language source_ref].freeze

      # runtime 所有 override path 規約（finding 2、Requirement 8 受入 6）。
      # foundation placement/identity は保持し、選択順序のみ runtime が所有。
      OVERRIDE_BASE = "runtime/prompts/overrides"

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root)
        @framework_path =
          @repo_root + "runtime/foundation/layer1_framework.yaml"
      end

      # design「Role and Step Mapping」: step → foundation 抽象 role 名。
      def role_for_step(step)
        unless ROLE_BY_STEP.key?(step)
          raise PromptResolutionError,
                "unknown step #{step.inspect} (no role/step mapping)"
        end
        ROLE_BY_STEP.fetch(step)
      end

      # role×step から prompt を解決し body と identity を返す。
      # 戻り値: { role:, prompt_id:, prompt_version:, prompt_artifact_path:, body: }
      def resolve(step:, phase_profile: nil)
        role = role_for_step(step)
        if role.nil?
          raise PromptResolutionError,
                "step #{step.inspect} has no prompt (role なし: " \
                "言語モデル非依存の機械統合)"
        end

        rel = canonical_relative_path(step)
        rel = apply_runtime_override(step, role, rel, phase_profile)

        artifact = @repo_root + rel
        unless artifact.file?
          raise PromptResolutionError,
                "required prompt artifact not resolvable: #{rel} " \
                "(step=#{step}, role=#{role})"
        end

        fm, body = parse_prompt(artifact, rel)
        validate_frontmatter!(fm, rel, step, role)

        {
          role: role,
          prompt_id: fm.fetch("prompt_id"),
          prompt_version: fm.fetch("version"),
          prompt_artifact_path: rel,
          body: body
        }
      end

      # design「Prompt Identity Recording」の最小 4 項目（要件 3 受入 2・3）。
      # 各 step record に埋め込むための string-key record。
      def identity_record(step:, phase_profile: nil)
        r = resolve(step: step, phase_profile: phase_profile)
        {
          "prompt_artifact_path" => r[:prompt_artifact_path],
          "prompt_id" => r[:prompt_id],
          "prompt_version" => r[:prompt_version],
          "role" => r[:role]
        }
      end

      private

      # resolution order 1: foundation canonical prompt path。
      # 唯一引き当て元 = layer1_framework.yaml asset_locations.prompts。
      def canonical_relative_path(step)
        framework = load_framework
        prompts = framework.dig("asset_locations", "prompts")
        if prompts.nil? || !prompts.is_a?(Hash)
          raise PromptResolutionError,
                "asset_locations.prompts not found in #{@framework_path}"
        end
        rel = prompts[step]
        if rel.nil? || rel.to_s.strip.empty?
          raise PromptResolutionError,
                "no canonical prompt path for step #{step.inspect} " \
                "in asset_locations.prompts"
        end
        rel
      end

      # resolution order 2: runtime 所有 role/phase override path。
      # 規約: runtime/prompts/overrides/<phase_profile>/<step>/<role>.prompt.md。
      # 存在すれば canonical を上書き（runtime 所有 selection policy）。
      # 適用条件は runtime 責務（foundation は所在のみ固定）。
      def apply_runtime_override(step, role, canonical_rel, phase_profile)
        return canonical_rel if phase_profile.nil? ||
                                phase_profile.to_s.strip.empty?

        override_rel = "#{OVERRIDE_BASE}/#{phase_profile}/#{step}/" \
                       "#{role}.prompt.md"
        override_path = @repo_root + override_rel
        override_path.file? ? override_rel : canonical_rel
      end

      def load_framework
        unless @framework_path.file?
          raise PromptResolutionError,
                "foundation framework not found: #{@framework_path}"
        end
        YAML.safe_load(@framework_path.read)
      rescue Psych::Exception => e
        raise PromptResolutionError,
              "failed to parse #{@framework_path}: #{e.message}"
      end

      # frontmatter（YAML between leading `---` fences）と body を分離する。
      # body は LLM seam に渡す対象（frontmatter は含めない）。
      def parse_prompt(artifact, rel)
        text = artifact.read
        unless text.start_with?("---\n") || text.start_with?("---\r\n")
          raise PromptResolutionError,
                "prompt #{rel} missing YAML frontmatter fence"
        end
        rest = text.sub(/\A---\r?\n/, "")
        parts = rest.split(/^---\r?\n/, 2)
        if parts.length < 2
          raise PromptResolutionError,
                "prompt #{rel} has unterminated frontmatter"
        end
        fm =
          begin
            YAML.safe_load(parts[0])
          rescue Psych::Exception => e
            raise PromptResolutionError,
                  "prompt #{rel} frontmatter parse error: #{e.message}"
          end
        unless fm.is_a?(Hash)
          raise PromptResolutionError,
                "prompt #{rel} frontmatter is not a mapping"
        end
        [fm, parts[1].strip]
      end

      def validate_frontmatter!(fm, rel, step, role)
        missing = FRONTMATTER_KEYS.reject { |k| fm.key?(k) && !fm[k].nil? }
        unless missing.empty?
          raise PromptResolutionError,
                "prompt #{rel} frontmatter missing: #{missing.join(', ')}"
        end
        if fm["step"] != step
          raise PromptResolutionError,
                "prompt #{rel} frontmatter step #{fm['step'].inspect} " \
                "!= resolved step #{step.inspect}"
        end
        return if fm["role"] == role

        raise PromptResolutionError,
              "prompt #{rel} frontmatter role #{fm['role'].inspect} " \
              "!= mapped role #{role.inspect}"
      end
    end
  end
end
