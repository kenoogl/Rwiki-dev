# Task 7.2: dr-init → consumer mock config 読込 test
# dr-init bootstrap で生成された config.yaml を consumer mock が yaml parse → 5 field 全 populate 確認
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

BOOTSTRAP_PATH = Path(__file__).resolve().parents[3] / "skills" / "dr-init" / "bootstrap.py"


def consumer_mock_read_config(config_path):
  """consumer (Layer 2 / Layer 3) が config.yaml を読み込む際の mock = yaml parse"""
  return yaml.safe_load(config_path.read_text())


def test_dr_init_to_consumer_config_pipeline():
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    result = subprocess.run(
      [sys.executable, str(BOOTSTRAP_PATH), "--target", str(target), "--lang", "ja"],
      capture_output=True,
      text=True,
    )
    assert result.returncode == 0, f"dr-init failed: {result.stderr}"

    config_path = target / ".dual-reviewer" / "config.yaml"
    assert config_path.exists()

    cfg = consumer_mock_read_config(config_path)
    expected = {"primary_model", "adversarial_model", "judgment_model", "lang", "dev_log_path"}
    assert set(cfg.keys()) == expected, f"config field mismatch: {set(cfg.keys()) ^ expected}"

    # placeholder 文字列 (`<...>` 形式) presence 確認
    for f in ("primary_model", "adversarial_model", "judgment_model"):
      v = cfg[f]
      assert isinstance(v, str) and v.startswith("<") and v.endswith(">"), f"{f}={v!r}"

    # lang + dev_log_path 確認
    assert cfg["lang"] == "ja"
    assert cfg["dev_log_path"] == ".dual-reviewer/dev_log.jsonl"
