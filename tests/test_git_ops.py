import subprocess
import pytest
import rw_light


class TestGitCommit:
  def test_normal_commit(self, monkeypatch):
    # Req 3.1: git add → git diff (returncode=1, 変更あり) → git commit の順で呼ばれる
    calls = []

    def mock_run(args, **kwargs):
      calls.append(list(args))
      if "diff" in args:
        return subprocess.CompletedProcess(args, returncode=1)
      return subprocess.CompletedProcess(args, returncode=0)

    monkeypatch.setattr(subprocess, "run", mock_run)
    rw_light.git_commit(["file.md"], "test commit")

    assert any("add" in str(c) for c in calls), "git add が呼ばれていない"
    assert any("diff" in str(c) for c in calls), "git diff が呼ばれていない"
    assert any("commit" in str(c) for c in calls), "git commit が呼ばれていない"

  def test_skip_commit_when_no_changes(self, monkeypatch):
    # Req 3.2: git diff returncode=0 (変更なし) → git commit が呼ばれない
    calls = []

    def mock_run(args, **kwargs):
      calls.append(list(args))
      # diff は returncode=0 (変更なし)
      return subprocess.CompletedProcess(args, returncode=0)

    monkeypatch.setattr(subprocess, "run", mock_run)
    rw_light.git_commit(["file.md"], "test commit")

    assert all("commit" not in str(c) for c in calls), "変更なしなのに git commit が呼ばれた"

  def test_git_add_failure_raises(self, monkeypatch):
    # Req 3.3a: git add 失敗 → CalledProcessError 送出
    def mock_run_add_fails(args, **kwargs):
      if "add" in args:
        raise subprocess.CalledProcessError(1, args)
      return subprocess.CompletedProcess(args, returncode=0)

    monkeypatch.setattr(subprocess, "run", mock_run_add_fails)

    with pytest.raises(subprocess.CalledProcessError):
      rw_light.git_commit(["file.md"], "test commit")

  def test_git_commit_failure_raises(self, monkeypatch):
    # Req 3.3b: git commit 失敗 → CalledProcessError 送出
    def mock_run_commit_fails(args, **kwargs):
      if "diff" in args:
        return subprocess.CompletedProcess(args, returncode=1)
      if "commit" in args:
        raise subprocess.CalledProcessError(1, args)
      return subprocess.CompletedProcess(args, returncode=0)

    monkeypatch.setattr(subprocess, "run", mock_run_commit_fails)

    with pytest.raises(subprocess.CalledProcessError):
      rw_light.git_commit(["file.md"], "test commit")


class TestGitStatusPorcelain:
  def test_returns_stdout(self, monkeypatch):
    # Req 3.4: subprocess.run モックで stdout を返すことを検証
    expected_output = " M scripts/rw_light.py\n?? new_file.txt\n"

    def mock_run(args, **kwargs):
      return subprocess.CompletedProcess(args, returncode=0, stdout=expected_output)

    monkeypatch.setattr(subprocess, "run", mock_run)
    result = rw_light.git_status_porcelain()

    assert result == expected_output


class TestGitPathIsDirty:
  def test_dirty_when_path_matches(self, monkeypatch):
    # Req 3.5a: 指定パスに dirty ファイルがある → True
    def mock_run(args, **kwargs):
      return subprocess.CompletedProcess(
        args, returncode=0, stdout=" M path/to/file.md\n"
      )

    monkeypatch.setattr(subprocess, "run", mock_run)
    result = rw_light.git_path_is_dirty("path/to")

    assert result is True

  def test_clean_when_no_path_matches(self, monkeypatch):
    # Req 3.5b: 指定パスに dirty ファイルがない → False
    def mock_run(args, **kwargs):
      return subprocess.CompletedProcess(
        args, returncode=0, stdout=" M other/path/file.md\n"
      )

    monkeypatch.setattr(subprocess, "run", mock_run)
    result = rw_light.git_path_is_dirty("path/to")

    assert result is False
