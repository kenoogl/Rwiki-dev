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
