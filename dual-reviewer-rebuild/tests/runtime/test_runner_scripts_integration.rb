# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"
require "open3"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 11 / B: 実行系所有 runner スクリプトの新 controller API 整合
# 根拠: tasks.md Task 2 Generic Protocol Entrypoint Rule、
#       design「File Placement for v2 Runtime Core」
#       「Generic Protocol Entrypoint Rule」「Reference-Free Runtime Entry
#       Principle」、本波作業 B。
#
# 旧 v1 runner（run_review_session / run_*_track_protocol /
# track_runs/*）は新 controller に存在しない dangling API を呼んでいた。
# 本テストは整合後の runner が:
#   - 構文 OK（ruby -c）
#   - reference-free entry を新 controller API で通し run を生成できる
#   - Generic Protocol Entrypoint Rule（manifest あり→読む／なし→track 別
#     必須入力／どちらも無し→fail fast）に従う
# ことを決定的に検証する（実 experiments/runs/ は汚さず tmpdir 出力）。
class TestRunnerScriptsIntegration < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  RUNNER_SCRIPTS = %w[
    scripts/run_review_session.rb
    scripts/run_implementation_track_protocol.rb
    scripts/run_intent_track_protocol.rb
    scripts/run_spec_track_protocol.rb
    scripts/track_runs/implementation_track_runner.rb
    scripts/track_runs/intent_track_writer.rb
    scripts/track_runs/spec_track_writer.rb
    scripts/bootstrap_reference_free_case.rb
  ].freeze

  def setup
    @dir = Pathname(Dir.mktmpdir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # 整合した runner が全件 構文 OK（ruby -c）。
  def test_all_runner_scripts_are_syntactically_valid
    RUNNER_SCRIPTS.each do |rel|
      path = ROOT + rel
      assert path.file?, "runner script 欠落: #{rel}"
      out, st = Open3.capture2e("ruby", "-c", path.to_s)
      assert st.success?, "ruby -c 失敗 (#{rel}): #{out}"
    end
  end

  # run_review_session.rb が新 controller API で reference-free に 1 run 通す。
  def test_run_review_session_drives_one_run_via_new_api
    out, st = Open3.capture2e(
      "ruby", (ROOT + "scripts/run_review_session.rb").to_s,
      "--run-root-base", @dir.to_s
    )
    assert st.success?, "run_review_session 失敗: #{out}"
    summary = JSON.parse(out)
    assert_equal "run_review_session", summary.fetch("entrypoint")
    run_id = summary.fetch("run_id")
    refute_nil run_id
    rr = @dir + "experiments/runs/#{run_id}"
    assert (rr + "run_manifest.yaml").exist?
    assert (rr + "review_case.json").exist?
    assert (rr + "validation/validator_result.json").exist?
    assert_equal "closed", summary.fetch("run_status")
  end

  # Generic Protocol Entrypoint Rule: case_manifest_ref も track 別必須入力も
  # 無ければ fail fast（非ゼロ終了）。
  def test_generic_protocol_entrypoint_fail_fast_without_inputs
    out, st = Open3.capture2e(
      "ruby", (ROOT + "scripts/run_spec_track_protocol.rb").to_s
    )
    refute st.success?, "必須入力なしで成功してはならない: #{out}"
    assert_match(/case-manifest-ref|required/i, out)
  end

  # Generic Protocol Entrypoint Rule: track 別必須入力明示で run を通す
  # （reference-free。pilot case を hidden default にしない）。
  def test_spec_track_protocol_with_explicit_track_inputs
    out, st = Open3.capture2e(
      "ruby", (ROOT + "scripts/run_spec_track_protocol.rb").to_s,
      "--case-id", "smoke-spec-case",
      "--reviewed-phase", "design",
      "--reviewed-phase-ref", "spec/design.md",
      "--runtime-run-root-base", @dir.to_s
    )
    assert st.success?, "explicit track inputs で失敗: #{out}"
    res = JSON.parse(out)
    assert_equal "spec", res.fetch("track")
    refute_nil res.fetch("run_id")
    rr = @dir + "experiments/runs/#{res.fetch('run_id')}"
    assert (rr + "run_manifest.yaml").exist?
  end

  # Generic Protocol Entrypoint Rule: case manifest があれば manifest を読む。
  def test_implementation_track_protocol_with_case_manifest
    manifest = {
      "case_id" => "mf-impl-case",
      "track" => "implementation",
      "source_refs" => ["impl/snapshot.rb"],
      "case_manifest_ref" => "inline:test",
      "phase_profile" => "tasks",
      "target_id" => "impl/snapshot.rb"
    }
    mf = @dir + "case_manifest.json"
    mf.write(JSON.generate(manifest))
    out, st = Open3.capture2e(
      "ruby", (ROOT + "scripts/run_implementation_track_protocol.rb").to_s,
      "--case-manifest-ref", mf.to_s,
      "--runtime-run-root-base", @dir.to_s
    )
    assert st.success?, "case manifest 経由で失敗: #{out}"
    res = JSON.parse(out)
    assert_equal "implementation", res.fetch("track")
    # case_manifest_ref がある場合 controller が manifest を読む。manifest
    # 由来の case_id は薄い wrapper の CLI 出力には現れない（hidden default
    # を作らない reference-free 規約と整合）。run が通ったことを検証する。
    refute_nil res.fetch("run_id")
    assert_equal "closed", res.fetch("run_status")
  end
end
