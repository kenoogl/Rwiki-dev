# Task 6.1: dr-init bootstrap success path test
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

BOOTSTRAP_PATH = Path(__file__).resolve().parents[2] / "skills" / "dr-init" / "bootstrap.py"


def run_bootstrap(target, lang="ja"):
  return subprocess.run(
    [sys.executable, str(BOOTSTRAP_PATH), "--target", str(target), "--lang", lang],
    capture_output=True,
    text=True,
  )


def test_dr_init_success_creates_directory_and_4_files():
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    # 改変禁止 invariant 検証用 dummy file を target 配下に予め配置
    (target / "CLAUDE.md").write_text("dummy CLAUDE content")
    (target / ".kiro").mkdir()
    (target / ".kiro" / "dummy.md").write_text("dummy kiro content")

    result = run_bootstrap(target)

    # exit 0 + stdout absolute path 1 行
    assert result.returncode == 0, f"expected exit 0, got {result.returncode}, stderr={result.stderr}"
    expected_path = str((target / ".dual-reviewer").resolve())
    assert result.stdout.strip() == expected_path, f"stdout={result.stdout!r}"

    # `.dual-reviewer/` directory 存在
    dr = target / ".dual-reviewer"
    assert dr.is_dir(), f".dual-reviewer/ should exist"

    # 4 file 全 presence
    for fname in ["config.yaml", "extracted_patterns.yaml", "terminology.yaml", "dev_log.jsonl"]:
      assert (dr / fname).exists(), f"missing file: {fname}"

    # config.yaml 5 field populated
    cfg = yaml.safe_load((dr / "config.yaml").read_text())
    expected_fields = {"primary_model", "adversarial_model", "judgment_model", "lang", "dev_log_path"}
    assert set(cfg.keys()) == expected_fields, f"config field mismatch: {set(cfg.keys()) ^ expected_fields}"
    assert cfg["lang"] == "ja"
    assert cfg["dev_log_path"] == ".dual-reviewer/dev_log.jsonl"
    # 3 model field は placeholder 文字列 (`<...>` 形式)
    for f in ("primary_model", "adversarial_model", "judgment_model"):
      assert isinstance(cfg[f], str) and cfg[f].startswith("<") and cfg[f].endswith(">"), f"{f}={cfg[f]!r}"

    # extracted_patterns.yaml content (Layer 3 placeholder = version + 空 patterns list)
    ep = yaml.safe_load((dr / "extracted_patterns.yaml").read_text())
    assert "version" in ep, "extracted_patterns missing version"
    assert ep.get("patterns") == [], f"extracted_patterns.patterns should be [], got {ep.get('patterns')!r}"

    # 改変禁止 invariant: target の `.dual-reviewer/` 配下以外が改変なし
    assert (target / "CLAUDE.md").read_text() == "dummy CLAUDE content"
    assert (target / ".kiro" / "dummy.md").read_text() == "dummy kiro content"


def test_dev_log_jsonl_initial_is_empty_file():
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    result = run_bootstrap(target)
    assert result.returncode == 0
    dev_log = target / ".dual-reviewer" / "dev_log.jsonl"
    # 空 file (= append target、initial bytes 0)
    assert dev_log.exists()
    assert dev_log.read_bytes() == b"", "dev_log.jsonl should be empty initially"


def test_terminology_yaml_copied_from_template():
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    result = run_bootstrap(target)
    assert result.returncode == 0
    term = yaml.safe_load((target / ".dual-reviewer" / "terminology.yaml").read_text())
    assert "version" in term
    assert term["entries"] == []
