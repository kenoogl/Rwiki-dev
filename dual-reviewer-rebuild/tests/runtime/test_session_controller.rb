# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "yaml"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 2: session controller（run lifecycle・session inputs・軸分離・reference-free entry）
# 根拠: tasks.md Task 2、design「Session Model §1〜§3」「Run Manifest Field Set」
#       「Reference-Free Runtime Entry Principle」「Generic Protocol Entrypoint Rule」
#       「Case Manifest and Heuristic Resolution Model」
#       設計再確定 finding 9（run close 順序＝controller ライフサイクル不変条件）
# 外部依存なし（gem 不使用）・repo 内で完結。
class TestSessionController < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path # dual-reviewer-rebuild/

  STARTED_FIXED = %w[
    run_id target_id target_artifact_hash source_repository_id source_revision
    phase_profile treatment review_mode protocol_version runtime_version
    prompt_set_version schema_set_version config_version config_hash
    operator_id started_at
  ].freeze

  RUNTIME_UPDATED = %w[
    run_status validator_status human_signoff_status evidence_class closed_at
  ].freeze

  def setup
    require_relative "../../runtime/controller/session_controller"
    @dir = Pathname(Dir.mktmpdir)
    @ctrl = DualReviewer::Runtime::SessionController.new(run_root_base: @dir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def base_inputs
    {
      target_id: "spec/dual-reviewer-runtime/tasks.md",
      target_artifact_hash: "sha256:deadbeef",
      source_repository_id: "Rwiki-v2-code-mod",
      source_revision: "abc1234",
      phase_profile: "design",
      treatment: "dual+judgment",
      review_mode: "runtime_mediated",
      protocol_version: "1.0.0",
      runtime_version: "0.1.0",
      prompt_set_version: "1.0.0",
      schema_set_version: "1.0.0",
      config_version: "1.0.0",
      config_hash: "sha256:cfg",
      operator_id: "kenji"
    }
  end

  def explicit_inputs(extra = {})
    base_inputs.merge(track: "spec", source_refs: ["spec/x"]).merge(extra)
  end

  # --- run lifecycle ---------------------------------------------------------

  def test_run_starts_in_created_then_in_progress
    run = @ctrl.start_run(**explicit_inputs)
    assert_equal "created", run.initial_status
    assert_equal "in_progress", run.run_status
  end

  def test_lifecycle_states_vocabulary
    assert_equal %w[created in_progress closed orchestration_failed],
                 DualReviewer::Runtime::SessionController::RUN_STATUSES
  end

  # closed は raw evidence 凍結のみを意味し validity を意味しない（design §1）
  def test_closed_does_not_imply_validity
    run = @ctrl.start_run(**explicit_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    run.invoke_validator { { "validator_status" => "passed" } }
    run.close
    assert_equal "closed", run.run_status
    # close 時点の evidence_class は candidate（確定遷移は foundation 契約に委ねる）
    assert_equal "candidate", run.manifest_metadata.fetch("evidence_class")
  end

  # --- session inputs / run_manifest field set ------------------------------

  def test_started_fixed_inputs_recorded_in_manifest
    run = @ctrl.start_run(**explicit_inputs)
    md = run.manifest_metadata
    STARTED_FIXED.each do |f|
      assert md.key?(f), "開始時固定項目欠落: #{f}"
      refute md.fetch(f).to_s.strip.empty?, "開始時固定項目が空: #{f}"
    end
  end

  def test_runtime_updated_fields_have_initial_values
    run = @ctrl.start_run(**explicit_inputs)
    md = run.manifest_metadata
    assert_equal "in_progress", md.fetch("run_status")
    assert_equal "not_run", md.fetch("validator_status")
    assert_equal "pending", md.fetch("human_signoff_status")
    assert_equal "candidate", md.fetch("evidence_class")
    assert_nil md.fetch("closed_at")
  end

  # 開始固定群は run 中に上書きしない（design §2）
  def test_started_fixed_inputs_immutable_during_run
    run = @ctrl.start_run(**explicit_inputs)
    snapshot = STARTED_FIXED.map { |f| [f, run.manifest_metadata.fetch(f)] }.to_h
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    run.invoke_validator { { "validator_status" => "passed" } }
    run.close
    written = YAML.safe_load((@dir + "experiments/runs/#{run.run_id}/run_manifest.yaml").read)
    md = written.fetch("metadata")
    snapshot.each { |f, v| assert_equal v, md.fetch(f), "run 中に固定項目が変化: #{f}" }
  end

  def test_manifest_written_to_canonical_path
    run = @ctrl.start_run(**explicit_inputs)
    path = @dir + "experiments/runs/#{run.run_id}/run_manifest.yaml"
    assert path.exist?, "run_manifest.yaml が正準パスに無い"
    assert YAML.safe_load(path.read).fetch("metadata").key?("run_id")
  end

  # evidence_class は close 時に candidate を manifest と review_case 双方へ記録
  def test_evidence_class_candidate_in_manifest_and_review_case_on_close
    run = @ctrl.start_run(**explicit_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    run.invoke_validator { { "validator_status" => "passed" } }
    run.close
    mp = @dir + "experiments/runs/#{run.run_id}/run_manifest.yaml"
    rc = @dir + "experiments/runs/#{run.run_id}/review_case.json"
    assert_equal "candidate",
                 YAML.safe_load(mp.read).fetch("metadata").fetch("evidence_class")
    assert_equal "candidate",
                 JSON.parse(rc.read).fetch("metadata").fetch("evidence_class")
  end

  # --- metadata vocabulary inherited from foundation -------------------------

  def test_metadata_enums_inherited_from_foundation_contract
    assert_equal %w[not_run passed failed blocked],
                 DualReviewer::Runtime::SessionController::VALIDATOR_STATUSES
    assert_equal %w[pending approved rejected deferred],
                 DualReviewer::Runtime::SessionController::HUMAN_SIGNOFF_STATUSES
    assert_equal %w[candidate valid invalid exploratory],
                 DualReviewer::Runtime::SessionController::EVIDENCE_CLASSES
  end

  # --- phase_profile / treatment independent axes ---------------------------

  def test_phase_profile_and_treatment_are_independent_axes
    assert_equal %w[intent requirements design tasks],
                 DualReviewer::Runtime::SessionController::PHASE_PROFILES
    assert_equal %w[single dual dual+judgment],
                 DualReviewer::Runtime::SessionController::TREATMENTS
    run = @ctrl.start_run(**explicit_inputs(phase_profile: "tasks", treatment: "single"))
    md = run.manifest_metadata
    assert_equal "tasks", md.fetch("phase_profile")
    assert_equal "single", md.fetch("treatment")
  end

  def test_invalid_phase_profile_rejected
    assert_raises(ArgumentError) { @ctrl.start_run(**explicit_inputs(phase_profile: "bogus")) }
  end

  def test_invalid_treatment_rejected
    assert_raises(ArgumentError) { @ctrl.start_run(**explicit_inputs(treatment: "triple")) }
  end

  # --- reference-free entry --------------------------------------------------

  # case_manifest_ref があれば manifest を読む
  def test_entry_reads_case_manifest_when_ref_present
    cm = @dir + "case_manifest.json"
    cm.write(JSON.dump(
      "case_id" => "case-1",
      "track" => "spec",
      "source_refs" => ["spec/a"],
      "case_manifest_ref" => "case_manifest.json"
    ))
    run = @ctrl.start_run(**base_inputs.merge(case_manifest_ref: cm.to_s))
    assert_equal "case-1", run.case_manifest.fetch("case_id")
    assert_equal "spec", run.case_manifest.fetch("track")
  end

  # case_manifest_ref が無ければ track 別必須入力を明示要求
  def test_entry_requires_explicit_track_inputs_without_manifest
    run = @ctrl.start_run(**explicit_inputs)
    assert_equal "spec", run.case_manifest.fetch("track")
    assert_equal ["spec/x"], run.case_manifest.fetch("source_refs")
  end

  # case_manifest_ref も明示 track 入力も無ければ fail fast
  def test_entry_fail_fast_without_manifest_or_explicit_inputs
    err = assert_raises(ArgumentError) { @ctrl.start_run(**base_inputs) }
    assert_match(/case_manifest_ref|track/, err.message)
  end

  # generic runtime code は特定 case の basename / case id を hidden default にしない
  def test_no_hidden_case_default
    src = (ROOT + "runtime/controller/session_controller.rb").read
    refute_match(/heat3d|phase-field|phase_field/i, src,
                 "generic runtime code に pilot case の hidden default が混入")
  end

  # case manifest base 必須項目（design「Case Manifest and Heuristic Resolution Model」）
  def test_case_manifest_base_required_fields
    require_relative "../../runtime/execution_v2/manifests/case_manifest"
    assert_equal %w[case_id track source_refs case_manifest_ref],
                 DualReviewer::Runtime::CaseManifest::BASE_REQUIRED_FIELDS
    err = assert_raises(ArgumentError) do
      DualReviewer::Runtime::CaseManifest.build("case_id" => "x")
    end
    assert_match(/track|source_refs|case_manifest_ref/, err.message)
  end

  # --- finding 9: run close boundary lifecycle invariant skeleton -----------

  # 前提 3 条件未充足での validator 起動を禁止し orchestration_failed にする
  def test_validator_blocked_before_step_d_complete
    run = @ctrl.start_run(**explicit_inputs)
    err = assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) do
      run.invoke_validator { { "validator_status" => "passed" } }
    end
    assert_match(/step.?d|sign-?off|freeze/i, err.message)
    assert_equal "orchestration_failed", run.run_status
  end

  def test_validator_blocked_before_human_signoff
    run = @ctrl.start_run(**explicit_inputs)
    run.mark_step_d_complete
    assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) do
      run.invoke_validator { { "validator_status" => "passed" } }
    end
    assert_equal "orchestration_failed", run.run_status
  end

  def test_validator_blocked_before_freeze
    run = @ctrl.start_run(**explicit_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) do
      run.invoke_validator { { "validator_status" => "passed" } }
    end
    assert_equal "orchestration_failed", run.run_status
  end

  # 多重起動禁止
  def test_validator_double_invocation_rejected
    run = @ctrl.start_run(**explicit_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    run.invoke_validator { { "validator_status" => "passed" } }
    assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) do
      run.invoke_validator { { "validator_status" => "passed" } }
    end
    assert_equal "orchestration_failed", run.run_status
  end

  # close は validator 後にのみ成立。順序を崩すと close できない
  def test_close_requires_validator_first
    run = @ctrl.start_run(**explicit_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    assert_raises(DualReviewer::Runtime::SessionController::CloseBoundaryViolation) { run.close }
  end

  # 違反検知時に invalidation marker を付与する（finding 9 再確定）
  def test_close_boundary_violation_emits_invalidation_marker
    run = @ctrl.start_run(**explicit_inputs)
    begin
      run.invoke_validator { { "validator_status" => "passed" } }
    rescue DualReviewer::Runtime::SessionController::CloseBoundaryViolation
      # expected
    end
    markers = run.invalidation_markers
    assert(markers.any? { |m| m.fetch("reason_code") =~ /sign-?off|mismatch|close.?boundary/i },
           "close boundary 違反時に invalidation marker が無い")
  end

  # 正常順序: Step D → human sign-off → freeze → validator → close
  def test_happy_path_close_order
    run = @ctrl.start_run(**explicit_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    run.freeze_raw_evidence
    result = run.invoke_validator { { "validator_status" => "passed" } }
    assert_equal "passed", result.fetch("validator_status")
    run.close
    assert_equal "closed", run.run_status
    md = run.manifest_metadata
    assert_equal "passed", md.fetch("validator_status")
    assert_equal "approved", md.fetch("human_signoff_status")
    refute_nil md.fetch("closed_at")
  end

  # human sign-off artifact は validator より前に書かれる（順序証跡）
  def test_human_signoff_artifact_written_before_validator
    run = @ctrl.start_run(**explicit_inputs)
    run.mark_step_d_complete
    run.write_human_signoff(status: "approved", signed_off_by: "kenji")
    so = @dir + "experiments/runs/#{run.run_id}/decisions/human_signoff.json"
    assert so.exist?, "human_signoff.json が validator 前に未生成"
    doc = JSON.parse(so.read)
    assert_equal run.run_id, doc.fetch("run_id")
    assert_equal "approved", doc.fetch("human_signoff_status")
  end
end
