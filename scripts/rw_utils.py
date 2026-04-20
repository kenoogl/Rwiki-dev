"""rw_utils — 汎用ユーティリティ関数（日付 / パス / ファイル I/O / frontmatter / git / severity）。

他のサブモジュール（rw_prompt_engine, rw_audit, rw_query, rw_light）から
`import rw_utils` + `rw_utils.<name>` 形式で参照する。`from rw_utils import <name>` は
禁止（Req 1.3: re-export 禁止、Req 3.2: テスト monkeypatch が効かなくなるため）。

このモジュールは stdlib と rw_config のみを import し、他のサブモジュールは import しない
（DAG 最下層から 2 番目、Req 2.2）。
"""
import json
import os
import re
import subprocess
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import Any

import rw_config


# -------------------------
# Utility
# -------------------------
def is_existing_vault(path: str) -> bool:
    """CLAUDE.md または index.md が存在する場合、既存の Vault と判定する。"""
    p = Path(path)
    return (p / "CLAUDE.md").exists() or (p / "index.md").exists()


def ensure_dirs() -> None:
    for d in [rw_config.LOGDIR, rw_config.SYNTH_CANDIDATES, rw_config.WIKI_SYNTH, rw_config.QUERY_REVIEW]:
        os.makedirs(d, exist_ok=True)


def read_text(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def write_text(path: str, text: str) -> None:
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def append_text(path: str, text: str) -> None:
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(text)


def relpath(path: str) -> str:
    return os.path.relpath(path, rw_config.ROOT)


def today() -> str:
    return datetime.today().date().isoformat()


def is_valid_iso_date(value: str) -> bool:
    if not isinstance(value, str):
        return False
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value.strip()):
        return False
    try:
        datetime.strptime(value.strip(), "%Y-%m-%d")
        return True
    except ValueError:
        return False


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s-]", "", text)
    text = re.sub(r"\s+", "-", text)
    text = re.sub(r"-+", "-", text)
    text = text.strip("-")
    return text[:80] if text else "untitled"


def list_md_files(root_dir: str) -> list[str]:
    if not os.path.isdir(root_dir):
        return []
    files: list[str] = []
    for root, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(".md"):
                files.append(os.path.join(root, filename))
    return sorted(files)


def list_query_dirs(root_dir: str) -> list[str]:
    if not os.path.isdir(root_dir):
        return []
    result: list[str] = []
    for entry in sorted(os.listdir(root_dir)):
        path = os.path.join(root_dir, entry)
        if os.path.isdir(path):
            result.append(path)
    return result


def has_frontmatter(text: str) -> bool:
    return text.startswith("---\n") or text == "---" or text.startswith("---\r\n")


def parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not has_frontmatter(text):
        return {}, text

    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text

    raw_meta = parts[1].strip()
    body = parts[2].lstrip("\n")
    meta: dict[str, str] = {}

    for line in raw_meta.splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        meta[key.strip()] = value.strip().strip('"').strip("'")

    return meta, body


def build_frontmatter(meta: dict[str, Any]) -> str:
    lines = ["---"]
    for key, value in meta.items():
        if isinstance(value, list):
            rendered = "[" + ", ".join(str(v) for v in value) + "]"
            lines.append(f"{key}: {rendered}")
        elif isinstance(value, bool):
            lines.append(f"{key}: {'true' if value else 'false'}")
        else:
            lines.append(f'{key}: "{value}"')
    lines.append("---\n")
    return "\n".join(lines)


def first_h1(text: str) -> str | None:
    for line in text.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return None


def infer_source_from_path(path: str) -> str:
    norm = path.replace("\\", "/")
    if "/articles/" in norm:
        return "web"
    if "/papers/zotero/" in norm:
        return "zotero"
    if "/papers/local/" in norm:
        return "local"
    if "/meeting-notes/" in norm:
        return "meeting"
    if "/code-snippets/" in norm:
        return "code"
    return "unknown"


def ensure_basic_frontmatter(path: str, default_source: str) -> tuple[bool, list[str], str]:
    text = read_text(path)
    fixes: list[str] = []

    meta, body = parse_frontmatter(text)

    if not meta:
        meta = {}
        fixes.append("added frontmatter")

    if not meta.get("title"):
        meta["title"] = first_h1(body) or os.path.basename(path)
        fixes.append("filled title")

    if not meta.get("source"):
        meta["source"] = default_source
        fixes.append("filled source")

    if not meta.get("added"):
        meta["added"] = today()
        fixes.append("filled added")

    new_text = build_frontmatter(meta) + "\n" + body.strip() + "\n"
    modified = new_text != text
    if modified:
        write_text(path, new_text)

    return modified, fixes, new_text


def read_json(path: str) -> dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def safe_read_json(path: str) -> tuple[dict[str, Any] | None, str | None]:
    try:
        return read_json(path), None
    except Exception as e:
        return None, str(e)


def git_status_porcelain() -> str:
    result = subprocess.run(
        ["git", "status", "--porcelain"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=False,
    )
    return result.stdout


def git_path_is_dirty(path_prefix: str) -> bool:
    prefix = path_prefix.rstrip("/") + "/"
    for line in git_status_porcelain().splitlines():
        if len(line) < 4:
            continue
        path = line[3:].strip()
        if path == path_prefix.rstrip("/") or path.startswith(prefix):
            return True
    return False


def warn_if_dirty_paths(paths: list[str], action_name: str) -> None:
    dirty = [p for p in paths if git_path_is_dirty(p)]
    if dirty:
        joined = ", ".join(dirty)
        print(f"[WARN] {action_name} is using uncommitted paths: {joined}")


def git_commit(paths: list[str], message: str) -> None:
    subprocess.run(["git", "add", *paths], check=True)
    diff = subprocess.run(["git", "diff", "--cached", "--quiet"], check=False)
    if diff.returncode == 0:
        return
    subprocess.run(["git", "commit", "-m", message], check=True)


def _git_list_files(args: list[str]) -> list[str]:
    """git コマンドを実行しファイルリストを返す。失敗時は空リスト。

    テスト時にモンキーパッチ可能な薄いラッパー。
    get_recent_wiki_changes() が内部で使用する。
    call_claude() とは独立してモック可能にするために分離。

    Args:
        args: git サブコマンドと引数のリスト（例: ["diff", "--name-only", "--", "wiki/"]）
    Returns:
        コマンド出力を改行で分割したファイルパスリスト。空行は除外。
    """
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
        )
    except Exception:
        return []
    if result.returncode != 0:
        return []
    return [line for line in result.stdout.splitlines() if line.strip()]


# severity / status / exit code helpers


def _compute_run_status(findings: list) -> str:
  """CRITICAL または ERROR が 1 件以上あれば FAIL, それ以外は PASS。"""
  for f in findings:
    if f.severity in rw_config._FAIL_SEVERITIES:
      return "FAIL"
  return "PASS"


def _compute_exit_code(status: str | None, had_runtime_error: bool) -> int:
  """had_runtime_error → 1, FAIL → 2, PASS/None → 0。"""
  if had_runtime_error:
    return 1
  if status == "FAIL":
    return 2
  return 0
