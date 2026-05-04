# test_metric_extractor.py — TDD step 1 (test first → fail)
# Task 2.1 (Req 4.1-4.7 整合)

import json
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[3]
DOGFEEDING_DIR = REPO_ROOT / "scripts" / "dual_reviewer_dogfeeding"
EXTRACTOR_PATH = DOGFEEDING_DIR / "metric_extractor.py"
PROTOTYPE_ROOT = REPO_ROOT / "scripts" / "dual_reviewer_prototype"


@pytest.fixture
def extractor_module():
  sys.path.insert(0, str(DOGFEEDING_DIR))
  import metric_extractor
  yield metric_extractor
  sys.path.remove(str(DOGFEEDING_DIR))


def _make_review_case(treatment, round_index, design_md_commit_hash, findings, ts_start="2026-05-01T10:00:00Z", ts_end="2026-05-01T10:07:00Z"):
  return {
    "session_id": f"s-{treatment}-r{round_index}",
    "phase": "design",
    "target_spec_id": "rwiki-v2-perspective-generation",
    "timestamp_start": ts_start,
    "timestamp_end": ts_end,
    "treatment": treatment,
    "round_index": round_index,
    "design_md_commit_hash": design_md_commit_hash,
    "findings": findings,
  }


def _make_finding(issue_id, source, label, source_necessity="judgment_subagent",
                   uncertainty="low", recommended_action="fix_now",
                   severity="ERROR", state="judged"):
  finding = {
    "issue_id": issue_id,
    "source": source,
    "finding_text": f"finding {issue_id}",
    "severity": severity,
    "state": state,
    "impact_score": {"severity": severity, "fix_cost": "low", "downstream_effect": "isolated"},
  }
  if state == "judged":
    finding["necessity_judgment"] = {
      "source": source_necessity,
      "requirement_link": "yes", "ignored_impact": "high", "fix_cost": "low",
      "scope_expansion": "no", "uncertainty": uncertainty,
      "fix_decision": {"label": label}, "recommended_action": recommended_action,
    }
  return finding


@pytest.fixture
def mock_30_line_jsonl(tmp_path):
  """3 treatment × 10 Round = 30 line mock JSONL."""
  jsonl_path = tmp_path / "dev_log.jsonl"
  lines = []
  for treatment in ["single", "dual", "dual+judgment"]:
    for round_index in range(1, 11):
      findings = [
        _make_finding(f"P-{treatment}-r{round_index}-1", "primary", "must_fix"),
        _make_finding(f"A-{treatment}-r{round_index}-1", "adversarial", "do_not_fix"),
      ]
      rc = _make_review_case(treatment, round_index, "commit-hash-1", findings)
      lines.append(json.dumps(rc))
  jsonl_path.write_text("\n".join(lines) + "\n")
  return jsonl_path


def test_metric_extractor_module_exists(extractor_module):
  assert hasattr(extractor_module, "extract_metrics")


def test_extract_metrics_returns_6_top_level_fields(extractor_module, mock_30_line_jsonl):
  result = extractor_module.extract_metrics(mock_30_line_jsonl)
  for key in ["version", "session_count", "treatments", "rounds", "commit_hash_variance", "metrics"]:
    assert key in result, f"missing top-level field: {key}"


def test_extract_metrics_session_count_30(extractor_module, mock_30_line_jsonl):
  result = extractor_module.extract_metrics(mock_30_line_jsonl)
  assert result["session_count"] == 30


def test_extract_metrics_3_treatments(extractor_module, mock_30_line_jsonl):
  result = extractor_module.extract_metrics(mock_30_line_jsonl)
  assert sorted(result["treatments"]) == ["dual", "dual+judgment", "single"]


def test_extract_metrics_per_treatment_metric_keys(extractor_module, mock_30_line_jsonl):
  result = extractor_module.extract_metrics(mock_30_line_jsonl)
  for t in ["single", "dual", "dual+judgment"]:
    m = result["metrics"][t]
    for key in ["detection_count", "must_fix_count", "should_fix_count", "do_not_fix_count",
                "must_fix_ratio", "should_fix_ratio", "do_not_fix_ratio",
                "adoption_rate", "over_correction_ratio", "wall_clock_seconds"]:
      assert key in m, f"missing metric key {key} for treatment {t}"


def test_extract_metrics_per_treatment_must_fix_count_10(extractor_module, mock_30_line_jsonl):
  """3 treatment × 10 Round で各 treatment 10 件 must_fix."""
  result = extractor_module.extract_metrics(mock_30_line_jsonl)
  for t in ["single", "dual", "dual+judgment"]:
    assert result["metrics"][t]["must_fix_count"] == 10


def test_wall_clock_calculation_from_iso8601(extractor_module, mock_30_line_jsonl):
  """timestamp_start - timestamp_end の差分秒で wall_clock 算出 (= 7 minutes = 420 seconds)."""
  result = extractor_module.extract_metrics(mock_30_line_jsonl)
  for t in ["single", "dual", "dual+judgment"]:
    # 10 Round × 7 minutes = 70 minutes = 4200 seconds
    assert 4150 <= result["metrics"][t]["wall_clock_seconds"] <= 4250


def test_wall_clock_handles_jst_utc_normalization(extractor_module, tmp_path):
  """A3 fix: UTC/JST 混在 fixture でも UTC normalize 後同一基準で wall_clock 算出."""
  jsonl_path = tmp_path / "dev_log.jsonl"
  rc_jst = _make_review_case(
    "dual+judgment", 1, "h", [_make_finding("P1", "primary", "must_fix")],
    ts_start="2026-05-01T19:00:00+09:00", ts_end="2026-05-01T19:07:00+09:00",  # JST = 10:00-10:07 UTC
  )
  jsonl_path.write_text(json.dumps(rc_jst) + "\n")
  result = extractor_module.extract_metrics(jsonl_path)
  # 7 minutes = 420 seconds (JST/UTC 混在でも同一基準)
  assert 415 <= result["metrics"]["dual+judgment"]["wall_clock_seconds"] <= 425


def test_commit_hash_variance_detected(extractor_module, tmp_path):
  jsonl_path = tmp_path / "dev_log.jsonl"
  lines = [
    json.dumps(_make_review_case("dual+judgment", 1, "hash-A", [_make_finding("P1", "primary", "must_fix")])),
    json.dumps(_make_review_case("dual+judgment", 2, "hash-B", [_make_finding("P2", "primary", "must_fix")])),
  ]
  jsonl_path.write_text("\n".join(lines) + "\n")
  result = extractor_module.extract_metrics(jsonl_path)
  assert result["commit_hash_variance"]["detected"] is True
  assert "hash-A" in result["commit_hash_variance"]["hashes"]
  assert "hash-B" in result["commit_hash_variance"]["hashes"]


def test_commit_hash_variance_not_detected_when_uniform(extractor_module, mock_30_line_jsonl):
  result = extractor_module.extract_metrics(mock_30_line_jsonl)
  assert result["commit_hash_variance"]["detected"] is False


def test_escalate_finding_counted_in_disagreement(extractor_module, tmp_path):
  """Req 2.5 整合: escalate-mapped findings (uncertainty=high → should_fix + user_decision) を override 件数に正しく count up."""
  jsonl_path = tmp_path / "dev_log.jsonl"
  finding = _make_finding(
    "P-1", "primary", "should_fix",
    source_necessity="judgment_subagent",
    uncertainty="high", recommended_action="user_decision",
  )
  rc = _make_review_case("dual+judgment", 1, "hash", [finding])
  jsonl_path.write_text(json.dumps(rc) + "\n")
  result = extractor_module.extract_metrics(jsonl_path)
  # escalate finding は should_fix に count up (V4 §2.5 三ラベル)
  assert result["metrics"]["dual+judgment"]["should_fix_count"] == 1


def test_cli_main_produces_dogfeeding_metrics_json(tmp_path, mock_30_line_jsonl):
  output = tmp_path / "metrics.json"
  result = subprocess.run(
    [sys.executable, str(EXTRACTOR_PATH),
     "--input", str(mock_30_line_jsonl), "--output", str(output),
     "--dual-reviewer-root", str(PROTOTYPE_ROOT)],
    capture_output=True, text=True,
  )
  assert result.returncode == 0, result.stderr
  data = json.loads(output.read_text())
  assert data["session_count"] == 30


def test_cli_main_exit_1_on_input_read_fail(tmp_path):
  output = tmp_path / "metrics.json"
  result = subprocess.run(
    [sys.executable, str(EXTRACTOR_PATH),
     "--input", "/nonexistent/path.jsonl", "--output", str(output),
     "--dual-reviewer-root", str(PROTOTYPE_ROOT)],
    capture_output=True, text=True,
  )
  assert result.returncode == 1


# ---------- 改修 1: treatment=single + treatment=dual の summary array 集計 ----------
# 47th 末 §12 確定数値: 過剰修正比率 = skip 件数 / total detect (P+A)
#   single 63.0% (29/46) / dual 21.7% (13/60) / dual+judgment 33.3% (23/69)
# 実 data schema (= treatment-single / treatment-dual branch dev_log):
#   findings[] 不在、代わりに primary_findings_summary[] / adversarial_findings_summary[]
#   / forced_divergence_summary[] / adversarial_counter_evidence_summary[] が配置
#   各 summary item は user_decision field を持ち "fix_now" / "skip" / "approved" 等を取る


def _make_primary_summary_item(issue_id, user_decision="fix_now", severity="WARN",
                                phase1_metapattern="a", state_initial="escalate"):
  return {
    "issue_id": issue_id,
    "severity": severity,
    "state_initial": state_initial,
    "phase1_metapattern": phase1_metapattern,
    "escalate_condition": "normative_scope",
    "user_decision": user_decision,
    "fix_target": None if user_decision == "skip" else f"design.md L{abs(hash(issue_id)) % 1000}",
  }


def _make_adversarial_summary_item(issue_id, user_decision="fix_now", severity="WARN",
                                     phase1_metapattern="c"):
  return {
    "issue_id": issue_id,
    "severity": severity,
    "state_initial": "escalate",
    "phase1_metapattern": phase1_metapattern,
    "escalate_condition": "normative_scope",
    "user_decision": user_decision,
    "fix_target": None if user_decision == "skip" else f"design.md L{abs(hash(issue_id)) % 1000}",
  }


def _make_forced_divergence_summary_item(target_issue_id, primary_conclusion_robustness="partially_robust"):
  return {
    "target_issue_id": target_issue_id,
    "tacit_premise_identified": "tacit premise text",
    "alternative_premise": "alternative text",
    "primary_conclusion_robustness": primary_conclusion_robustness,
    "note": "note text",
  }


def _make_summary_review_case_single(round_index, design_md_commit_hash, primary_summary,
                                       ts_start="2026-05-03T09:00:00+00:00",
                                       ts_end="2026-05-03T09:07:00+00:00"):
  return {
    "session_id": f"s-single-r{round_index}",
    "phase": "design",
    "target_spec_id": "rwiki-v2-perspective-generation",
    "timestamp_start": ts_start,
    "timestamp_end": ts_end,
    "treatment": "single",
    "round_index": round_index,
    "design_md_commit_hash": design_md_commit_hash,
    "branch": "treatment-single",
    "primary_findings_count": len(primary_summary),
    "adversarial_findings_count": 0,
    "forced_divergence_findings_count": 0,
    "judgment_label_distribution": {},
    "judgment_rule_distribution": {},
    "judgment_override_count": 0,
    "judgment_escalate_count": 0,
    "primary_findings_summary": primary_summary,
    "step_1a_minor_findings_count": 0,
    "fatal_pattern_hits": 0,
    "seed_pattern_hits": [],
    "seed_pattern_hits_count": 0,
  }


def _make_summary_review_case_dual(round_index, design_md_commit_hash,
                                     primary_summary, adversarial_summary, forced_divergence_summary,
                                     ts_start="2026-05-04T09:00:00+00:00",
                                     ts_end="2026-05-04T09:07:00+00:00"):
  return {
    "session_id": f"s-dual-r{round_index}",
    "phase": "design",
    "target_spec_id": "rwiki-v2-perspective-generation",
    "timestamp_start": ts_start,
    "timestamp_end": ts_end,
    "treatment": "dual",
    "round_index": round_index,
    "design_md_commit_hash": design_md_commit_hash,
    "branch": "treatment-dual",
    "primary_findings_count": len(primary_summary),
    "adversarial_findings_count": len(adversarial_summary),
    "forced_divergence_findings_count": len(forced_divergence_summary),
    "judgment_label_distribution": {},
    "judgment_rule_distribution": {},
    "judgment_override_count": 0,
    "judgment_escalate_count": 0,
    "primary_findings_summary": primary_summary,
    "adversarial_findings_summary": adversarial_summary,
    "forced_divergence_summary": forced_divergence_summary,
    "step_1a_minor_findings_count": 0,
    "fatal_pattern_hits": 0,
    "seed_pattern_hits": [],
    "seed_pattern_hits_count": 0,
  }


@pytest.fixture
def mock_treatment_single_jsonl(tmp_path):
  """treatment=single 系統 fixture: 5 round × 4 detect = 20 total, skip 12 → 過剰修正比率 60%.

  実 data 47th 末 = 46 detect / 29 skip = 63.0%。本 fixture は schema 検証 + 集計 logic 検証用 simplified.
  """
  jsonl_path = tmp_path / "single_dev_log.jsonl"
  lines = []
  for round_index in range(1, 6):
    summary = [
      _make_primary_summary_item(f"S-P-r{round_index}-1", user_decision="fix_now"),
      _make_primary_summary_item(f"S-P-r{round_index}-2",
                                  user_decision="fix_now" if round_index <= 2 else "skip"),
      _make_primary_summary_item(f"S-P-r{round_index}-3", user_decision="skip"),
      _make_primary_summary_item(f"S-P-r{round_index}-4", user_decision="skip"),
    ]
    rc = _make_summary_review_case_single(round_index, "h-single", summary)
    lines.append(json.dumps(rc))
  jsonl_path.write_text("\n".join(lines) + "\n")
  return jsonl_path


@pytest.fixture
def mock_treatment_dual_jsonl(tmp_path):
  """treatment=dual 系統 fixture: 5 round, P 1 + A 1 + FD 1 / round = 10 detect (P+A), skip 3 → 30%."""
  jsonl_path = tmp_path / "dual_dev_log.jsonl"
  lines = []
  for round_index in range(1, 6):
    primary_summary = [_make_primary_summary_item(f"D-P-r{round_index}-1", user_decision="fix_now")]
    # adversarial: round 4-5 で skip = 計 2 件、round 1 primary skip 0、so total skip = 2 (A) + 1 (P-r1 below)
    adversarial_summary = [_make_adversarial_summary_item(
      f"D-A-r{round_index}-1",
      user_decision="fix_now" if round_index <= 3 else "skip",
    )]
    forced_divergence_summary = [_make_forced_divergence_summary_item(f"D-P-r{round_index}-1")]
    rc = _make_summary_review_case_dual(round_index, "h-dual",
                                          primary_summary, adversarial_summary, forced_divergence_summary)
    lines.append(json.dumps(rc))
  # round 1 primary を 1 件 skip に
  rc1 = json.loads(lines[0])
  rc1["primary_findings_summary"][0]["user_decision"] = "skip"
  rc1["primary_findings_summary"][0]["fix_target"] = None
  lines[0] = json.dumps(rc1)
  jsonl_path.write_text("\n".join(lines) + "\n")
  return jsonl_path


def test_extract_metrics_treatment_single_uses_summary_arrays(extractor_module, mock_treatment_single_jsonl):
  """改修 1: treatment=single で primary_findings_summary 集計、findings array 不在でも detection_count > 0."""
  result = extractor_module.extract_metrics(mock_treatment_single_jsonl)
  assert "single" in result["metrics"]
  m = result["metrics"]["single"]
  # 5 round × 4 detect = 20
  assert m["detection_count"] == 20, f"got {m['detection_count']}"


def test_extract_metrics_treatment_single_over_correction_ratio_from_skip(extractor_module, mock_treatment_single_jsonl):
  """改修 1: 過剰修正比率 = skip 件数 / total detect (= judgment 系の do_not_fix 比と意味的統一)."""
  result = extractor_module.extract_metrics(mock_treatment_single_jsonl)
  m = result["metrics"]["single"]
  # skip 計 = round 1-2 で 2 件 (P-3,4) × 2 + round 3-5 で 3 件 (P-2,3,4) × 3 = 4+9 = 13
  # detect 計 = 20、ratio = 13/20 = 0.65
  assert abs(m["over_correction_ratio"] - 13/20) < 0.01, f"got {m['over_correction_ratio']}"


def test_extract_metrics_treatment_dual_includes_p_and_a_in_detection_count(extractor_module, mock_treatment_dual_jsonl):
  """改修 1: treatment=dual で P + A summary が detection_count に集計 (forced_divergence は count up しない、§12 整合)."""
  result = extractor_module.extract_metrics(mock_treatment_dual_jsonl)
  assert "dual" in result["metrics"]
  m = result["metrics"]["dual"]
  # P 5 + A 5 = 10 detect
  assert m["detection_count"] == 10, f"got {m['detection_count']}"


def test_extract_metrics_treatment_dual_over_correction_ratio_unified(extractor_module, mock_treatment_dual_jsonl):
  """改修 1: treatment=dual の over_correction_ratio = (P skip + A skip) / total detect."""
  result = extractor_module.extract_metrics(mock_treatment_dual_jsonl)
  m = result["metrics"]["dual"]
  # round 1 P skip 1 件 + round 4-5 A skip 2 件 = 3 件、detect 10 → 30%
  assert abs(m["over_correction_ratio"] - 0.30) < 0.01, f"got {m['over_correction_ratio']}"


def test_extract_metrics_top_level_count_fields_aggregated(extractor_module, mock_treatment_dual_jsonl):
  """改修 1: dev_log top-level の primary_findings_count / adversarial_findings_count / forced_divergence_findings_count が
  per-treatment metric として保持される."""
  result = extractor_module.extract_metrics(mock_treatment_dual_jsonl)
  m = result["metrics"]["dual"]
  assert m.get("primary_findings_count") == 5
  assert m.get("adversarial_findings_count") == 5
  assert m.get("forced_divergence_findings_count") == 5


def test_extract_metrics_three_branch_concatenated_three_treatments(extractor_module, tmp_path):
  """改修 1+2: 3 系統 concatenate jsonl で全 treatment が独立 metric 持つ + 過剰修正比率横断統一定義."""
  jsonl_path = tmp_path / "merged_dev_log.jsonl"
  lines = []
  # single 5 round × 2 detect = 10、skip 6 → 60%
  for r in range(1, 6):
    summary = [
      _make_primary_summary_item(f"S-P-{r}-1", user_decision="fix_now" if r <= 2 else "skip"),
      _make_primary_summary_item(f"S-P-{r}-2", user_decision="skip"),
    ]
    lines.append(json.dumps(_make_summary_review_case_single(r, "h", summary)))
  # dual 5 round × 2 detect (P 1 + A 1) = 10、skip 3 → 30%
  for r in range(1, 6):
    p = [_make_primary_summary_item(f"D-P-{r}-1", user_decision="fix_now")]
    a = [_make_adversarial_summary_item(f"D-A-{r}-1",
                                          user_decision="fix_now" if r <= 2 else "skip")]
    lines.append(json.dumps(_make_summary_review_case_dual(r, "h", p, a, [])))
  # dual+judgment 5 round × 2 detect = 10、do_not_fix 3 → 30%
  for r in range(1, 6):
    findings = [
      _make_finding(f"DJ-P-{r}-1", "primary", "must_fix"),
      _make_finding(f"DJ-A-{r}-1", "adversarial", "do_not_fix" if r <= 3 else "must_fix"),
    ]
    lines.append(json.dumps(_make_review_case("dual+judgment", r, "h", findings)))
  jsonl_path.write_text("\n".join(lines) + "\n")
  result = extractor_module.extract_metrics(jsonl_path)
  assert sorted(result["treatments"]) == ["dual", "dual+judgment", "single"]
  assert abs(result["metrics"]["single"]["over_correction_ratio"] - 0.60) < 0.01
  assert abs(result["metrics"]["dual"]["over_correction_ratio"] - 0.30) < 0.01
  assert abs(result["metrics"]["dual+judgment"]["over_correction_ratio"] - 0.30) < 0.01


def test_extract_metrics_treatment_single_no_findings_array_no_zero_division(extractor_module, mock_treatment_single_jsonl):
  """改修 1: findings array 不在でも除算 / 0 を回避 + detection_count > 0."""
  result = extractor_module.extract_metrics(mock_treatment_single_jsonl)
  m = result["metrics"]["single"]
  assert m["detection_count"] > 0
  assert 0 <= m["over_correction_ratio"] <= 1
