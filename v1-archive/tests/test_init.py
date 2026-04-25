import os
import subprocess
import sys

import pytest

import rw_config
import rw_cli


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
    rw_cli.cmd_init([str(vault)])
    for d in rw_config.VAULT_DIRS:
      assert os.path.isdir(os.path.join(str(vault), d)), f"Missing dir: {d}"

  def test_creates_target_dir_if_missing(self, tmp_path, mock_templates):
    """Req 9.2: 存在しないパスを指定 → 自動作成して続行、exit 0。"""
    vault = tmp_path / "nonexistent" / "vault"
    assert not vault.exists()
    result = rw_cli.cmd_init([str(vault)])
    assert vault.exists()
    assert result == 0

  def test_claude_md_copied(self, tmp_path, mock_templates):
    """Req 9.3: mock_templates の CLAUDE.md が Vault ルートにコピーされ内容が一致。"""
    vault = tmp_path / "vault"
    rw_cli.cmd_init([str(vault)])
    dest = vault / "CLAUDE.md"
    assert dest.exists(), "CLAUDE.md が Vault ルートに存在しない"
    src = mock_templates / "CLAUDE.md"
    assert dest.read_text(encoding="utf-8") == src.read_text(encoding="utf-8")

  def test_agents_dir_copied(self, tmp_path, mock_templates):
    """Req 9.4: AGENTS/ ディレクトリのファイル数と名前が一致。"""
    vault = tmp_path / "vault"
    rw_cli.cmd_init([str(vault)])
    dest_agents = vault / "AGENTS"
    assert dest_agents.is_dir(), "AGENTS/ が Vault に存在しない"
    src_files = set(f.name for f in (mock_templates / "AGENTS").iterdir())
    dst_files = set(f.name for f in dest_agents.iterdir())
    assert src_files == dst_files, f"AGENTS/ ファイル不一致: src={src_files} dst={dst_files}"

  def test_initial_files_created(self, tmp_path, mock_templates):
    """Req 9.5: index.md に '# Index'、log.md に '# Log' の見出しが存在。"""
    vault = tmp_path / "vault"
    rw_cli.cmd_init([str(vault)])
    index_md = vault / "index.md"
    log_md = vault / "log.md"
    assert index_md.exists(), "index.md が存在しない"
    assert log_md.exists(), "log.md が存在しない"
    assert "# Index" in index_md.read_text(encoding="utf-8")
    assert "# Log" in log_md.read_text(encoding="utf-8")

  def test_git_init_called(self, tmp_path, mock_templates):
    """Req 9.7: .git/ 不在 → subprocess.run の呼び出しに ['git', 'init'] が含まれる。"""
    vault = tmp_path / "vault"
    rw_cli.cmd_init([str(vault)])
    assert any(
      list(cmd)[:2] == ["git", "init"]
      for cmd in self._subprocess_calls
    ), f"git init が呼ばれなかった。calls={self._subprocess_calls}"

  def test_git_init_skipped_when_git_exists(self, tmp_path, mock_templates):
    """Req 9.8: .git/ ディレクトリを事前作成 → git init が呼ばれない。"""
    vault = tmp_path / "vault"
    vault.mkdir(parents=True)
    (vault / ".git").mkdir()
    rw_cli.cmd_init([str(vault)])
    git_init_calls = [
      cmd for cmd in self._subprocess_calls
      if list(cmd)[:2] == ["git", "init"]
    ]
    assert git_init_calls == [], f"git init が呼ばれた: {git_init_calls}"

  def test_gitignore_copied(self, tmp_path, mock_templates):
    """Req 9.9: .gitignore の内容が templates/.gitignore と一致。"""
    vault = tmp_path / "vault"
    rw_cli.cmd_init([str(vault)])
    dest_gitignore = vault / ".gitignore"
    assert dest_gitignore.exists(), ".gitignore が Vault に存在しない"
    src_gitignore = mock_templates / ".gitignore"
    assert dest_gitignore.read_text(encoding="utf-8") == src_gitignore.read_text(encoding="utf-8")

  def test_symlink_created(self, tmp_path, mock_templates):
    """Req 9.11: vault/scripts/rw が scripts/rw_light.py へのシンボリックリンク。"""
    vault = tmp_path / "vault"
    rw_cli.cmd_init([str(vault)])
    rw_link = vault / "scripts" / "rw"
    assert os.path.islink(str(rw_link)), "vault/scripts/rw がシンボリックリンクでない"
    link_target = os.readlink(str(rw_link))
    assert link_target.endswith("rw_cli.py"), (
      f"リンク先が rw_cli.py でない: {link_target}"
    )

  def test_completion_report(self, tmp_path, mock_templates, capsys):
    """Req 9.12: capsys で主要項目（ディレクトリ数、テンプレート名）の部分一致検証。"""
    vault = tmp_path / "vault"
    rw_cli.cmd_init([str(vault)])
    captured = capsys.readouterr()
    out = captured.out
    assert "ディレクトリ生成" in out, "ディレクトリ生成の報告がない"
    assert str(len(rw_config.VAULT_DIRS)) in out, "生成ディレクトリ数が出力に含まれない"
    assert "CLAUDE.md" in out, "CLAUDE.md の報告がない"
    assert "AGENTS/" in out, "AGENTS/ の報告がない"

  def test_no_overwrite_existing_index(self, tmp_path, mock_templates, monkeypatch):
    """Req 9.6: 再初期化時に index.md は上書きされない（テンプレートに含まれないため保護される）。"""
    vault = tmp_path / "vault"
    # 初回 init
    rw_cli.cmd_init([str(vault)])
    # index.md を独自内容で上書き
    index_md = vault / "index.md"
    custom_content = "# My Custom Index\nCustom content here.\n"
    index_md.write_text(custom_content, encoding="utf-8")
    # 再初期化: input を "y" でモック（既存Vault確認を承認）
    monkeypatch.setattr("builtins.input", lambda prompt="": "y")
    rw_cli.cmd_init([str(vault)])
    # index.md の内容が変わっていないことを確認
    assert index_md.read_text(encoding="utf-8") == custom_content, (
      "再初期化後に index.md が上書きされた（保護されるべき）"
    )

  def test_no_overwrite_existing_gitignore(self, tmp_path, mock_templates, monkeypatch):
    """Req 9.10: 再初期化を拒否した場合、.gitignore は変わらない。"""
    vault = tmp_path / "vault"
    # 初回 init
    rw_cli.cmd_init([str(vault)])
    # .gitignore を独自内容で上書き
    gitignore = vault / ".gitignore"
    custom_content = "# My custom gitignore\n*.log\n"
    gitignore.write_text(custom_content, encoding="utf-8")
    # 再初期化: input を "n" でモック（拒否）
    monkeypatch.setattr("builtins.input", lambda prompt="": "n")
    result = rw_cli.cmd_init([str(vault)])
    # exit 0 で中断
    assert result == 0, "再初期化拒否時は exit 0 であるべき"
    # .gitignore の内容が変わっていないことを確認
    assert gitignore.read_text(encoding="utf-8") == custom_content, (
      "再初期化拒否後に .gitignore が変更された"
    )

  def test_reinit_prompts_user(self, tmp_path, mock_templates, monkeypatch):
    """Req 9.13: 既存Vaultへの init 時に input() のプロンプトに '既存のVault' が含まれる。"""
    vault = tmp_path / "vault"
    # 初回 init で CLAUDE.md を生成（既存Vault状態にする）
    rw_cli.cmd_init([str(vault)])
    # input をキャプチャするモック
    prompts = []
    def mock_input(prompt=""):
      prompts.append(prompt)
      return "n"
    monkeypatch.setattr("builtins.input", mock_input)
    rw_cli.cmd_init([str(vault)])
    # input() が呼ばれ、プロンプトに '既存のVault' が含まれることを確認
    assert len(prompts) > 0, "input() が呼ばれなかった"
    assert any("既存のVault" in p for p in prompts), (
      f"プロンプトに '既存のVault' が含まれない: {prompts}"
    )

  def test_reinit_backup_and_overwrite(self, tmp_path, mock_templates, monkeypatch):
    """Req 9.14: 再初期化を承認すると CLAUDE.md.bak が作成され新 CLAUDE.md がコピーされる。"""
    vault = tmp_path / "vault"
    # 初回 init
    rw_cli.cmd_init([str(vault)])
    # CLAUDE.md を独自内容で上書き（既存内容を保存）
    claude_md = vault / "CLAUDE.md"
    original_content = "# Original CLAUDE\nOld content.\n"
    claude_md.write_text(original_content, encoding="utf-8")
    # 再初期化: input を "y" でモック（承認）
    monkeypatch.setattr("builtins.input", lambda prompt="": "y")
    result = rw_cli.cmd_init([str(vault)])
    assert result == 0, "再初期化承認時は exit 0 であるべき"
    # CLAUDE.md.bak が存在し、元の内容が保存されている
    bak = vault / "CLAUDE.md.bak"
    assert bak.exists(), "CLAUDE.md.bak が作成されていない"
    assert bak.read_text(encoding="utf-8") == original_content, (
      "CLAUDE.md.bak に元の内容が保存されていない"
    )
    # 新しい CLAUDE.md がテンプレートの内容
    src_content = (mock_templates / "CLAUDE.md").read_text(encoding="utf-8")
    assert claude_md.read_text(encoding="utf-8") == src_content, (
      "再初期化後の CLAUDE.md がテンプレートの内容でない"
    )

  def test_reinit_abort_on_no(self, tmp_path, mock_templates, monkeypatch):
    """Req 9.15: 再初期化を拒否（"n"）すると exit 0 で既存 CLAUDE.md の内容が変わらない。"""
    vault = tmp_path / "vault"
    # 初回 init
    rw_cli.cmd_init([str(vault)])
    # CLAUDE.md を独自内容で上書き
    claude_md = vault / "CLAUDE.md"
    custom_content = "# My Custom CLAUDE\nKeep this.\n"
    claude_md.write_text(custom_content, encoding="utf-8")
    # 再初期化: input を "n" でモック（拒否）
    monkeypatch.setattr("builtins.input", lambda prompt="": "n")
    result = rw_cli.cmd_init([str(vault)])
    assert result == 0, "再初期化拒否時は exit 0 であるべき"
    # CLAUDE.md の内容が変わっていないことを確認
    assert claude_md.read_text(encoding="utf-8") == custom_content, (
      "再初期化拒否後に CLAUDE.md が変更された"
    )

  def test_error_missing_claude_md(self, tmp_path, mock_templates, capsys):
    """Req 9.16: templates/CLAUDE.md が存在しない場合、exit 1 で stdout に '[ERROR]' が出力される。"""
    vault = tmp_path / "vault"
    # mock_templates の CLAUDE.md を削除
    (mock_templates / "CLAUDE.md").unlink()
    result = rw_cli.cmd_init([str(vault)])
    assert result == 1, "templates/CLAUDE.md 不在時は exit 1 であるべき"
    captured = capsys.readouterr()
    assert "[ERROR]" in captured.out, (
      f"stdout に '[ERROR]' が含まれない: {captured.out!r}"
    )

  def test_error_missing_gitignore(self, tmp_path, mock_templates, capsys):
    """Req 9.17: templates/.gitignore が存在しない場合、exit 1 で stdout に '[ERROR]' が出力される。"""
    vault = tmp_path / "vault"
    # mock_templates の .gitignore を削除
    (mock_templates / ".gitignore").unlink()
    result = rw_cli.cmd_init([str(vault)])
    assert result == 1, "templates/.gitignore 不在時は exit 1 であるべき"
    captured = capsys.readouterr()
    assert "[ERROR]" in captured.out, (
      f"stdout に '[ERROR]' が含まれない: {captured.out!r}"
    )


class TestRwInitForce:
  """rw init --force フラグのテスト (Req 6.5)。"""

  @pytest.fixture(autouse=True)
  def mock_subprocess(self, monkeypatch):
    """全テストで subprocess.run を no-op モックに差し替える。"""
    calls = []

    def fake_run(cmd, **kwargs):
      calls.append(cmd)
      return subprocess.CompletedProcess(args=cmd, returncode=0)

    monkeypatch.setattr(subprocess, "run", fake_run)
    self._subprocess_calls = calls

  def test_force_overwrites_agents(self, tmp_path, mock_templates, monkeypatch, capsys):
    """(a) 既存 AGENTS/ がある Vault で --force を指定すると、旧 AGENTS を新 template で上書きする。
    input() は呼ばれず（--force は非インタラクティブ）、旧ファイルは .backup/ に退避される。"""
    vault = tmp_path / "vault"
    # 初回 init で AGENTS/ を作成
    rw_cli.cmd_init([str(vault)])
    # 既存 AGENTS/ に古いファイルを追加して変更
    old_marker = vault / "AGENTS" / "old_marker.md"
    old_marker.write_text("# Old content\n", encoding="utf-8")
    assert old_marker.exists(), "前提: old_marker.md が存在するべき"

    # input() が呼ばれたら失敗させる（--force は非インタラクティブであるべき）
    def should_not_be_called(prompt=""):
      raise AssertionError(f"--force 時に input() が呼ばれた: {prompt!r}")
    monkeypatch.setattr("builtins.input", should_not_be_called)

    # --force で再実行 → 新テンプレートで上書き
    result = rw_cli.cmd_init(["--force", str(vault)])
    assert result == 0, f"--force で exit 0 であるべき: {result}"

    # 新テンプレートのファイルが存在することを確認
    dest_agents = vault / "AGENTS"
    src_files = set(f.name for f in (mock_templates / "AGENTS").iterdir())
    dst_files = set(f.name for f in dest_agents.iterdir())
    # テンプレートの全ファイルが存在する
    assert src_files <= dst_files, f"新テンプレートのファイルが存在しない: {src_files - dst_files}"

    # 旧ファイル (old_marker.md) は .backup/ 以下に退避されている
    backup_root = vault / ".backup"
    assert backup_root.is_dir(), ".backup/ が存在しない"
    all_backup_files = list(backup_root.rglob("old_marker.md"))
    assert len(all_backup_files) >= 1, "old_marker.md が .backup/ に退避されていない"

  def test_no_force_existing_agents_skips(self, tmp_path, mock_templates, monkeypatch):
    """(b) --force なしで既存 AGENTS/ がある場合は旧動作（input() 確認）を維持する。"""
    vault = tmp_path / "vault"
    # 初回 init
    rw_cli.cmd_init([str(vault)])
    # input を "n" でモック → 上書き拒否
    monkeypatch.setattr("builtins.input", lambda prompt="": "n")
    result = rw_cli.cmd_init([str(vault)])
    assert result == 0, "再初期化拒否時は exit 0 であるべき"

  def test_force_stderr_overwrite_notice(self, tmp_path, mock_templates, capsys):
    """(c) --force 指定時の stderr に上書き通知が出力される。"""
    vault = tmp_path / "vault"
    # 初回 init で AGENTS/ を作成
    rw_cli.cmd_init([str(vault)])

    # --force で再実行
    rw_cli.cmd_init(["--force", str(vault)])
    captured = capsys.readouterr()
    assert "overwrite" in captured.err.lower() or "上書き" in captured.err, (
      f"stderr に上書き通知が含まれない: {captured.err!r}"
    )

  def test_force_backup_symlink_abort(self, tmp_path, mock_templates, capsys):
    """(d) .backup/ が既存 symlink の場合 SystemExit(1) + stderr に '[rw-init] .backup/ must be a regular directory'。"""
    vault = tmp_path / "vault"
    # 初回 init で AGENTS/ を作成
    rw_cli.cmd_init([str(vault)])

    # .backup/ を symlink として作成
    backup_dir = vault / ".backup"
    fake_target = tmp_path / "fake_target"
    fake_target.mkdir()
    backup_dir.symlink_to(fake_target)
    assert backup_dir.is_symlink(), "前提: .backup/ が symlink であるべき"

    # --force で再実行 → SystemExit(1) かつ stderr にメッセージ
    with pytest.raises(SystemExit) as exc_info:
      rw_cli.cmd_init(["--force", str(vault)])
    assert exc_info.value.code == 1, f"SystemExit(1) であるべき: {exc_info.value.code}"
    captured = capsys.readouterr()
    assert "[rw-init] .backup/ must be a regular directory" in captured.err, (
      f"stderr に期待メッセージが含まれない: {captured.err!r}"
    )

  def test_force_timestamp_collision_fallback(self, tmp_path, mock_templates, monkeypatch):
    """(e) <timestamp> directory が既に存在する場合、<timestamp>-<pid> fallback 名で作成して成功する。"""
    vault = tmp_path / "vault"
    # 初回 init で AGENTS/ を作成
    rw_cli.cmd_init([str(vault)])

    # timestamp を固定してコリジョンを発生させる
    fixed_ts = "20260420-120000"
    monkeypatch.setattr(
      rw_cli, "_backup_timestamp", lambda: fixed_ts
    )
    # .backup/<timestamp>/ を事前作成（コリジョン）
    backup_dir = vault / ".backup" / fixed_ts
    backup_dir.mkdir(parents=True, exist_ok=True)

    # --force で実行 → <timestamp>-<pid> fallback で成功
    result = rw_cli.cmd_init(["--force", str(vault)])
    assert result == 0, f"timestamp collision fallback で exit 0 であるべき: {result}"

    # .backup/ 配下に <timestamp>-<pid> 形式のディレクトリが存在する
    backup_root = vault / ".backup"
    backups = list(backup_root.iterdir())
    fallback_dirs = [d for d in backups if d.name.startswith(fixed_ts + "-")]
    assert len(fallback_dirs) >= 1, (
      f"<timestamp>-<pid> fallback ディレクトリが存在しない: {[d.name for d in backups]}"
    )


class TestReinstallSymlink:
  """--reinstall-symlink フラグの専用テスト (Req 5.1, 5.2, 5.3, R6)。"""

  @pytest.fixture(autouse=True)
  def mock_subprocess(self, monkeypatch):
    """全テストで subprocess.run を no-op モックに差し替える。"""
    calls = []

    def fake_run(cmd, **kwargs):
      calls.append(cmd)
      return subprocess.CompletedProcess(args=cmd, returncode=0)

    monkeypatch.setattr(subprocess, "run", fake_run)
    self._subprocess_calls = calls

  def test_cmd_init_reinstall_symlink_on_existing_vault(self, tmp_path, mock_templates):
    """Req 5.1, 5.2: 既存 Vault に --reinstall-symlink を実行すると symlink のみ張り替えられ、
    通常初期化処理（dirs 作成・templates コピー・git init・.gitignore）が skip される。"""
    vault = tmp_path / "vault"
    vault.mkdir(parents=True)
    # 既存 Vault 判定のために CLAUDE.md を配置
    (vault / "CLAUDE.md").write_text("# CLAUDE\nexisting vault", encoding="utf-8")
    # symlink 作成のために scripts/ ディレクトリを用意
    (vault / "scripts").mkdir(parents=True)

    result = rw_cli.cmd_init([str(vault), "--reinstall-symlink"])

    assert result == 0, f"--reinstall-symlink で exit 0 であるべき: {result}"

    # 通常初期化処理が skip されていること（Req 5.2）
    # report は関数内部で使用されるが、テストでは stdout を capsys で確認できない
    # → VAULT_DIRS のいずれも作成されていないこと（scripts/ は手動作成済みなので除く）
    import rw_config as _rc
    for d in _rc.VAULT_DIRS:
      if d == "scripts":
        continue
      assert not (vault / d).exists(), f"通常 init で作成される {d} が存在してはいけない"

    # symlink が rw_cli.py を指していること（Req 5.1）
    rw_link = vault / "scripts" / "rw"
    assert os.path.islink(str(rw_link)), "vault/scripts/rw がシンボリックリンクでない"
    link_target = os.readlink(str(rw_link))
    assert link_target.endswith("rw_cli.py"), (
      f"リンク先が rw_cli.py でない: {link_target}"
    )

  def test_cmd_init_reinstall_symlink_rejects_non_vault(self, tmp_path, mock_templates, capsys):
    """Req 5.3: CLAUDE.md も index.md も存在しないディレクトリに --reinstall-symlink を実行すると
    exit 1 で stderr にエラーメッセージが出力される。"""
    non_vault = tmp_path / "non_vault"
    non_vault.mkdir(parents=True)
    # CLAUDE.md も index.md も置かない（非 Vault 状態）

    result = rw_cli.cmd_init([str(non_vault), "--reinstall-symlink"])

    assert result == 1, f"非 Vault + --reinstall-symlink は exit 1 であるべき: {result}"
    captured = capsys.readouterr()
    assert "既存の Vault ではありません" in captured.err, (
      f"stderr に '既存の Vault ではありません' が含まれない: {captured.err!r}"
    )

  def test_cmd_init_reinstall_symlink_with_force_warns(self, tmp_path, mock_templates, capsys):
    """R6: --reinstall-symlink + --force 併用時は stderr 警告を出力したうえで
    --reinstall-symlink を優先して処理が続行され exit 0 となる。"""
    vault = tmp_path / "vault"
    vault.mkdir(parents=True)
    # 既存 Vault 判定のために CLAUDE.md を配置
    (vault / "CLAUDE.md").write_text("# CLAUDE\nexisting vault", encoding="utf-8")
    # symlink 作成のために scripts/ ディレクトリを用意
    (vault / "scripts").mkdir(parents=True)

    result = rw_cli.cmd_init([str(vault), "--reinstall-symlink", "--force"])

    # stderr に警告が出力されること
    captured = capsys.readouterr()
    assert "--reinstall-symlink と --force が併用されました" in captured.err, (
      f"stderr に警告メッセージが含まれない: {captured.err!r}"
    )
    # --reinstall-symlink 挙動で処理が続行され exit 0
    assert result == 0, f"--reinstall-symlink + --force で exit 0 であるべき: {result}"
    # symlink が作成されていること（--reinstall-symlink 挙動）
    rw_link = vault / "scripts" / "rw"
    assert os.path.islink(str(rw_link)), "vault/scripts/rw がシンボリックリンクでない"
