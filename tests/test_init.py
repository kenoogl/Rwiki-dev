import os
import subprocess

import pytest

import rw_light


class TestCmdInit:
  """cmd_init の新規初期化シナリオをテストする。"""

  @pytest.fixture(autouse=True)
  def mock_subprocess(self, monkeypatch):
    """全テストで subprocess.run を no-op モックに差し替える。"""
    calls = []

    def fake_run(cmd, **kwargs):
      calls.append(cmd)
      return subprocess.CompletedProcess(args=cmd, returncode=0)

    monkeypatch.setattr(subprocess, "run", fake_run)
    self._subprocess_calls = calls

  def test_creates_all_vault_dirs(self, tmp_path, mock_templates):
    """Req 9.1: 空ディレクトリへの init → VAULT_DIRS の全エントリが存在する。"""
    vault = tmp_path / "vault"
    rw_light.cmd_init([str(vault)])
    for d in rw_light.VAULT_DIRS:
      assert os.path.isdir(os.path.join(str(vault), d)), f"Missing dir: {d}"

  def test_creates_target_dir_if_missing(self, tmp_path, mock_templates):
    """Req 9.2: 存在しないパスを指定 → 自動作成して続行、exit 0。"""
    vault = tmp_path / "nonexistent" / "vault"
    assert not vault.exists()
    result = rw_light.cmd_init([str(vault)])
    assert vault.exists()
    assert result == 0

  def test_claude_md_copied(self, tmp_path, mock_templates):
    """Req 9.3: mock_templates の CLAUDE.md が Vault ルートにコピーされ内容が一致。"""
    vault = tmp_path / "vault"
    rw_light.cmd_init([str(vault)])
    dest = vault / "CLAUDE.md"
    assert dest.exists(), "CLAUDE.md が Vault ルートに存在しない"
    src = mock_templates / "CLAUDE.md"
    assert dest.read_text(encoding="utf-8") == src.read_text(encoding="utf-8")

  def test_agents_dir_copied(self, tmp_path, mock_templates):
    """Req 9.4: AGENTS/ ディレクトリのファイル数と名前が一致。"""
    vault = tmp_path / "vault"
    rw_light.cmd_init([str(vault)])
    dest_agents = vault / "AGENTS"
    assert dest_agents.is_dir(), "AGENTS/ が Vault に存在しない"
    src_files = set(f.name for f in (mock_templates / "AGENTS").iterdir())
    dst_files = set(f.name for f in dest_agents.iterdir())
    assert src_files == dst_files, f"AGENTS/ ファイル不一致: src={src_files} dst={dst_files}"

  def test_initial_files_created(self, tmp_path, mock_templates):
    """Req 9.5: index.md に '# Index'、log.md に '# Log' の見出しが存在。"""
    vault = tmp_path / "vault"
    rw_light.cmd_init([str(vault)])
    index_md = vault / "index.md"
    log_md = vault / "log.md"
    assert index_md.exists(), "index.md が存在しない"
    assert log_md.exists(), "log.md が存在しない"
    assert "# Index" in index_md.read_text(encoding="utf-8")
    assert "# Log" in log_md.read_text(encoding="utf-8")

  def test_git_init_called(self, tmp_path, mock_templates):
    """Req 9.7: .git/ 不在 → subprocess.run の呼び出しに ['git', 'init'] が含まれる。"""
    vault = tmp_path / "vault"
    rw_light.cmd_init([str(vault)])
    assert any(
      list(cmd)[:2] == ["git", "init"]
      for cmd in self._subprocess_calls
    ), f"git init が呼ばれなかった。calls={self._subprocess_calls}"

  def test_git_init_skipped_when_git_exists(self, tmp_path, mock_templates):
    """Req 9.8: .git/ ディレクトリを事前作成 → git init が呼ばれない。"""
    vault = tmp_path / "vault"
    vault.mkdir(parents=True)
    (vault / ".git").mkdir()
    rw_light.cmd_init([str(vault)])
    git_init_calls = [
      cmd for cmd in self._subprocess_calls
      if list(cmd)[:2] == ["git", "init"]
    ]
    assert git_init_calls == [], f"git init が呼ばれた: {git_init_calls}"

  def test_gitignore_copied(self, tmp_path, mock_templates):
    """Req 9.9: .gitignore の内容が templates/.gitignore と一致。"""
    vault = tmp_path / "vault"
    rw_light.cmd_init([str(vault)])
    dest_gitignore = vault / ".gitignore"
    assert dest_gitignore.exists(), ".gitignore が Vault に存在しない"
    src_gitignore = mock_templates / ".gitignore"
    assert dest_gitignore.read_text(encoding="utf-8") == src_gitignore.read_text(encoding="utf-8")

  def test_symlink_created(self, tmp_path, mock_templates):
    """Req 9.11: vault/scripts/rw が scripts/rw_light.py へのシンボリックリンク。"""
    vault = tmp_path / "vault"
    rw_light.cmd_init([str(vault)])
    rw_link = vault / "scripts" / "rw"
    assert os.path.islink(str(rw_link)), "vault/scripts/rw がシンボリックリンクでない"
    link_target = os.readlink(str(rw_link))
    assert link_target.endswith("rw_light.py"), (
      f"リンク先が rw_light.py でない: {link_target}"
    )

  def test_completion_report(self, tmp_path, mock_templates, capsys):
    """Req 9.12: capsys で主要項目（ディレクトリ数、テンプレート名）の部分一致検証。"""
    vault = tmp_path / "vault"
    rw_light.cmd_init([str(vault)])
    captured = capsys.readouterr()
    out = captured.out
    assert "ディレクトリ生成" in out, "ディレクトリ生成の報告がない"
    assert str(len(rw_light.VAULT_DIRS)) in out, "生成ディレクトリ数が出力に含まれない"
    assert "CLAUDE.md" in out, "CLAUDE.md の報告がない"
    assert "AGENTS/" in out, "AGENTS/ の報告がない"
