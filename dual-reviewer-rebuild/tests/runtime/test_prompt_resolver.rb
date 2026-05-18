# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 4: prompt resolution model
# 根拠: tasks.md Task 4、Requirement 3（受入 1〜5）、Requirement 8 受入 6、
#       design「Prompt Resolution Model」「Role and Step Mapping」
#       「Prompt Identity Recording」、設計再確定 finding 2。
# 外部依存なし（gem 不使用）・repo 内で完結。
class TestPromptResolver < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  def setup
    require_relative "../../runtime/execution_v2/prompts/prompt_resolver"
    @resolver = DualReviewer::Runtime::PromptResolver.new(repo_root: ROOT)
  end

  # finding 2: 解決の唯一入力 = layer1_framework.yaml asset_locations.prompts。
  # role×step から repo 相対パスを引き当て frontmatter を parse する。
  def test_resolves_primary_detection_from_canonical_asset_locations
    r = @resolver.resolve(step: "primary_detection")
    assert_equal "primary_reviewer", r[:role]
    assert_equal "foundation.primary_detection.primary_reviewer", r[:prompt_id]
    assert_equal "1.0.0", r[:prompt_version]
    assert_equal "runtime/prompts/primary_detection/primary_reviewer.prompt.md",
                 r[:prompt_artifact_path]
    # 本文は frontmatter を除いた prompt body（LLM seam に渡す対象）。
    assert_includes r[:body], "あなたは主役レビュアーです"
    refute_includes r[:body], "prompt_id:"
  end

  def test_resolves_adversarial_and_judgment_roles
    b = @resolver.resolve(step: "adversarial_review")
    assert_equal "adversarial_reviewer", b[:role]
    assert_equal "foundation.adversarial_review.adversarial_reviewer", b[:prompt_id]

    c = @resolver.resolve(step: "judgment")
    assert_equal "judgment_reviewer", c[:role]
    assert_equal "foundation.judgment.judgment_reviewer", c[:prompt_id]
  end

  # Step D は role なし（言語モデル非依存の機械統合）。prompt 不要。
  def test_step_d_has_no_prompt_role
    assert_nil @resolver.role_for_step("integration")
    err = assert_raises(DualReviewer::Runtime::PromptResolver::PromptResolutionError) do
      @resolver.resolve(step: "integration")
    end
    assert_match(/no prompt|role なし|integration/i, err.message)
  end

  # prompt identity record（design Prompt Identity Recording の最小 4 項目）。
  def test_prompt_identity_record_minimum_fields
    rec = @resolver.identity_record(step: "primary_detection")
    %w[prompt_artifact_path prompt_id prompt_version role].each do |k|
      assert rec.key?(k), "identity record must include #{k}"
      refute_nil rec[k]
    end
    # repo-contained path（repo 外への steady-state 依存なし）。
    refute rec["prompt_artifact_path"].start_with?("/")
    assert (ROOT + rec["prompt_artifact_path"]).file?
  end

  # 未知 step は曖昧でなく explicit failure（Requirement 3 受入 4）。
  def test_unknown_step_fails_explicitly
    assert_raises(DualReviewer::Runtime::PromptResolver::PromptResolutionError) do
      @resolver.resolve(step: "no_such_step")
    end
  end

  # resolution order: (1) foundation canonical (asset_locations.prompts)
  # → (2) runtime-owned override path → (3) ambiguous なら explicit failure。
  # override は runtime 所有 policy。frontmatter は parse できる前提。
  def test_runtime_owned_override_takes_precedence_when_present
    Dir.mktmpdir do |tmp|
      tmp_root = Pathname(tmp)
      # canonical asset を最小再現
      fw = tmp_root + "runtime/foundation/layer1_framework.yaml"
      fw.dirname.mkpath
      fw.write(<<~YAML)
        version: "1.0.0"
        asset_locations:
          prompts:
            primary_detection: "runtime/prompts/primary_detection/primary_reviewer.prompt.md"
        override_extension_point:
          location: "runtime owns override policy"
      YAML
      base = tmp_root + "runtime/prompts/primary_detection/primary_reviewer.prompt.md"
      base.dirname.mkpath
      base.write(<<~MD)
        ---
        prompt_id: base.primary
        version: "1.0.0"
        role: primary_reviewer
        step: primary_detection
        language: ja
        source_ref: x
        ---
        BASE BODY
      MD
      ovr = tmp_root + "runtime/prompts/overrides/design/primary_detection/primary_reviewer.prompt.md"
      ovr.dirname.mkpath
      ovr.write(<<~MD)
        ---
        prompt_id: override.primary.design
        version: "2.0.0"
        role: primary_reviewer
        step: primary_detection
        language: ja
        source_ref: y
        ---
        OVERRIDE BODY
      MD

      res = DualReviewer::Runtime::PromptResolver.new(repo_root: tmp_root)
      base_r = res.resolve(step: "primary_detection")
      assert_equal "base.primary", base_r[:prompt_id]
      assert_includes base_r[:body], "BASE BODY"

      ovr_r = res.resolve(step: "primary_detection", phase_profile: "design")
      assert_equal "override.primary.design", ovr_r[:prompt_id]
      assert_equal "2.0.0", ovr_r[:prompt_version]
      assert_includes ovr_r[:body], "OVERRIDE BODY"
      # replay: 同 step だが prompt 違いを identity で判別できる。
      refute_equal base_r[:prompt_id], ovr_r[:prompt_id]
    end
  end

  # 必須 prompt の artifact が解決できない（path 不在）は explicit failure。
  def test_missing_artifact_fails
    Dir.mktmpdir do |tmp|
      tmp_root = Pathname(tmp)
      fw = tmp_root + "runtime/foundation/layer1_framework.yaml"
      fw.dirname.mkpath
      fw.write(<<~YAML)
        version: "1.0.0"
        asset_locations:
          prompts:
            primary_detection: "runtime/prompts/primary_detection/missing.prompt.md"
      YAML
      res = DualReviewer::Runtime::PromptResolver.new(repo_root: tmp_root)
      assert_raises(DualReviewer::Runtime::PromptResolver::PromptResolutionError) do
        res.resolve(step: "primary_detection")
      end
    end
  end
end
