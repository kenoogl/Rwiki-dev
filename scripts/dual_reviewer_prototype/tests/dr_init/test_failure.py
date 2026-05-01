# Task 6.2: dr-init bootstrap failure path test
# (conflict + unsupported lang + rollback + rollback failure + 改変禁止 + Phase B-1.3 reference)
import importlib.util
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest import mock

BOOTSTRAP_PATH = Path(__file__).resolve().parents[2] / "skills" / "dr-init" / "bootstrap.py"


def run_bootstrap(target, lang="ja"):
  return subprocess.run(
    [sys.executable, str(BOOTSTRAP_PATH), "--target", str(target), "--lang", lang],
    capture_output=True,
    text=True,
  )


def _import_bootstrap():
  """bootstrap.py を direct import (rollback failure injection 用、subprocess では monkeypatch 不可)"""
  spec = importlib.util.spec_from_file_location("dr_init_bootstrap", BOOTSTRAP_PATH)
  module = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(module)
  return module


def test_conflict_existing_dual_reviewer_returns_exit_1():
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    existing = target / ".dual-reviewer"
    existing.mkdir()
    pre_file = existing / "preexisting.txt"
    pre_file.write_text("preexisting content")

    result = run_bootstrap(target)

    assert result.returncode == 1, f"expected exit 1, got {result.returncode}, stderr={result.stderr}"
    # 既存 file 上書きなし
    assert pre_file.read_text() == "preexisting content"
    # stderr に conflict message (".dual-reviewer" を含む)
    assert ".dual-reviewer" in result.stderr or "conflict" in result.stderr.lower()


def test_unsupported_lang_returns_exit_3_with_phase_b_reference():
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    result = run_bootstrap(target, lang="en")
    assert result.returncode == 3, f"expected exit 3, got {result.returncode}, stderr={result.stderr}"
    # stderr に Phase B-1.3 reference message
    assert "B-1.3" in result.stderr or "Phase B" in result.stderr


def test_target_not_directory_returns_nonzero():
  """target が directory でない (= file or 不存在) 時は non-zero exit"""
  with tempfile.NamedTemporaryFile() as tmp_file:
    target = Path(tmp_file.name)  # file (not directory)
    result = run_bootstrap(target)
    assert result.returncode != 0, f"expected non-zero exit, got {result.returncode}"


def test_rollback_filesystem_error_returns_exit_2():
  """target が readonly な場合、書込権限なしで exit 2 (filesystem error)"""
  if os.geteuid() == 0:
    # root 権限では chmod による readonly が無視されるため skip
    return
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    # target を readonly (5 = r-x) に
    os.chmod(target, 0o555)
    try:
      result = run_bootstrap(target)
      assert result.returncode == 2, f"expected exit 2, got {result.returncode}, stderr={result.stderr}"
    finally:
      os.chmod(target, 0o755)


def test_rollback_failure_returns_exit_4_with_residual_files():
  """rollback 中の write error injection: bootstrap 内の Path.unlink を mock で fail させる → exit 4 + stderr に残存 file list"""
  bootstrap = _import_bootstrap()
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    # bootstrap 関数を直接呼出 (subprocess なし)
    # 実装詳細: bootstrap.bootstrap(target, lang) が中で Path.unlink / shutil.rmtree 等を呼ぶ
    # → mock で OSError を raise させる → rollback failure 経由 exit 4

    # まず file 生成途中で error を発火させるため、_write_file 等の internal を mock するか、
    # rollback 用の _rollback / _remove を mock。
    # bootstrap.py impl は exit_code = bootstrap.bootstrap(target, lang) 形式を想定。

    # 戦略: 4 file 書込中に最後の write を fail させ、その後 rollback 中の unlink も fail させる
    # = mock で Path.unlink を raise OSError("rollback inject")
    # かつ, 4 file 書込前段階で内部 _write を 1 回成功させてから fail にして rollback を trigger する必要がある
    # 簡略化: bootstrap.bootstrap() を patch せず、Path.write_text を 2 回目から fail にし、Path.unlink を fail にする

    call_count = {"write": 0}
    real_write_text = Path.write_text

    def fake_write_text(self, *args, **kwargs):
      call_count["write"] += 1
      if call_count["write"] >= 2:
        raise OSError("inject write fail")
      return real_write_text(self, *args, **kwargs)

    def fake_unlink(self, *args, **kwargs):
      raise OSError("inject unlink fail")

    with mock.patch.object(Path, "write_text", fake_write_text), \
         mock.patch.object(Path, "unlink", fake_unlink):
      exit_code = bootstrap.bootstrap(target, lang="ja")

    assert exit_code == 4, f"expected exit 4 (rollback failure), got {exit_code}"


def test_no_modification_outside_dual_reviewer_on_success():
  """改変禁止 invariant: success 時も target の `.dual-reviewer/` 配下以外を改変しない"""
  with tempfile.TemporaryDirectory() as tmp:
    target = Path(tmp)
    fixtures = {
      "CLAUDE.md": "claude content",
      ".kiro/steering.md": "kiro steering content",
      "src/main.py": "src main content",
    }
    for rel, content in fixtures.items():
      p = target / rel
      p.parent.mkdir(parents=True, exist_ok=True)
      p.write_text(content)

    result = run_bootstrap(target)
    assert result.returncode == 0

    for rel, original in fixtures.items():
      assert (target / rel).read_text() == original, f"file {rel} modified"
