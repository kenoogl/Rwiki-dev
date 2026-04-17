#!/usr/bin/env python3
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
from datetime import datetime
from pathlib import Path
from typing import Any

ROOT = os.getcwd()

RAW = os.path.join(ROOT, "raw")
INCOMING = os.path.join(RAW, "incoming")
LLM_LOGS = os.path.join(RAW, "llm_logs")

REVIEW = os.path.join(ROOT, "review")
SYNTH_CANDIDATES = os.path.join(REVIEW, "synthesis_candidates")
QUERY_REVIEW = os.path.join(REVIEW, "query")

WIKI = os.path.join(ROOT, "wiki")
WIKI_SYNTH = os.path.join(WIKI, "synthesis")

LOGDIR = os.path.join(ROOT, "logs")
LINT_LOG = os.path.join(LOGDIR, "lint_latest.json")
QUERY_LINT_LOG = os.path.join(LOGDIR, "query_lint_latest.json")

INDEX_MD = os.path.join(ROOT, "index.md")
CHANGE_LOG_MD = os.path.join(ROOT, "log.md")

ALLOWED_QUERY_TYPES = {"fact", "structure", "comparison", "why", "hypothesis"}

INFERENCE_PATTERNS = [
    r"考えられる",
    r"示唆される",
    r"推測される",
    r"おそらく",
    r"可能性がある",
    r"と思われる",
    r"\blikely\b",
    r"\bsuggests?\b",
    r"\bmay\b",
    r"\bcould\b",
]

EVIDENCE_SOURCE_PATTERNS = [
    r"^source\s*:",
    r"^file\s*:",
    r"^page\s*:",
    r"^path\s*:",
    r"\[\[.+\]\]",
]

VAULT_DIRS = [
    "raw/incoming/articles",
    "raw/incoming/papers/zotero",
    "raw/incoming/papers/local",
    "raw/incoming/meeting-notes",
    "raw/incoming/code-snippets",
    "raw/articles",
    "raw/papers/zotero",
    "raw/papers/local",
    "raw/meeting-notes",
    "raw/code-snippets",
    "raw/llm_logs",
    "review/synthesis_candidates",
    "review/query",
    "wiki/concepts",
    "wiki/methods",
    "wiki/projects",
    "wiki/entities/people",
    "wiki/entities/tools",
    "wiki/synthesis",
    "logs",
    "scripts",
    "AGENTS",
]

DEV_ROOT = str(Path(__file__).resolve().parent.parent)


# -------------------------
# Utility
# -------------------------
def is_existing_vault(path: str) -> bool:
    """CLAUDE.md または index.md が存在する場合、既存の Vault と判定する。"""
    p = Path(path)
    return (p / "CLAUDE.md").exists() or (p / "index.md").exists()


def ensure_dirs() -> None:
    for d in [LOGDIR, SYNTH_CANDIDATES, WIKI_SYNTH, QUERY_REVIEW]:
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
    return os.path.relpath(path, ROOT)


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


# -------------------------
# lint
# -------------------------
def cmd_lint() -> int:
    ensure_dirs()
    files = list_md_files(INCOMING)

    results = []
    summary = {"pass": 0, "warn": 0, "fail": 0}

    for path in files:
        entry = {
            "path": relpath(path),
            "status": "PASS",
            "warnings": [],
            "errors": [],
            "fixes": [],
        }

        raw = read_text(path)
        if len(raw.strip()) == 0:
            entry["status"] = "FAIL"
            entry["errors"].append("empty file")
            summary["fail"] += 1
            results.append(entry)
            print(f"[FAIL] {entry['path']} empty file")
            continue

        _, fixes, new_text = ensure_basic_frontmatter(path, infer_source_from_path(path))
        entry["fixes"].extend(fixes)

        if len(new_text.strip()) < 80:
            entry["status"] = "WARN"
            entry["warnings"].append("too short")
            summary["warn"] += 1
            print(f"[WARN] {entry['path']} too short")
        else:
            summary["pass"] += 1
            print(f"[PASS] {entry['path']}")

        results.append(entry)

    payload = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "files": results,
        "summary": summary,
    }

    write_text(LINT_LOG, json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    print(f"\nSummary: {summary}")
    print(f"Log: {relpath(LINT_LOG)}")

    return 1 if summary["fail"] > 0 else 0


# -------------------------
# ingest
# -------------------------
def load_lint_summary() -> dict[str, Any]:
    if not os.path.exists(LINT_LOG):
        raise FileNotFoundError("lint log not found. run `rw lint` first.")
    return json.loads(read_text(LINT_LOG))


def plan_ingest_moves(files: list[str]) -> list[tuple[str, str]]:
    moves: list[tuple[str, str]] = []
    for path in files:
        relative = os.path.relpath(path, INCOMING)
        target = os.path.join(RAW, relative)
        if os.path.exists(target):
            raise RuntimeError(f"conflict: {target} already exists")
        moves.append((path, target))
    return moves


def execute_ingest_moves(moves: list[tuple[str, str]]) -> None:
    completed: list[tuple[str, str]] = []
    try:
        for src, dst in moves:
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.move(src, dst)
            completed.append((src, dst))
    except Exception:
        for src, dst in reversed(completed):
            if os.path.exists(dst):
                os.makedirs(os.path.dirname(src), exist_ok=True)
                shutil.move(dst, src)
        raise


def cmd_ingest() -> int:
    ensure_dirs()
    lint_result = load_lint_summary()
    if lint_result["summary"]["fail"] > 0:
        print("FAIL exists in lint_latest.json. abort ingest.")
        return 1

    files = list_md_files(INCOMING)
    if not files:
        print("No files found in raw/incoming/")
        return 0

    moves = plan_ingest_moves(files)

    for src, _ in moves:
        print(f"[MOVE] {relpath(src)}")

    execute_ingest_moves(moves)

    try:
        git_commit(["raw/"], "ingest: batch import")
    except subprocess.CalledProcessError as e:
        print(f"[FAIL] git commit failed: {e}")
        return 1

    print("[DONE] ingest completed")
    return 0


# -------------------------
# synthesize-logs
# -------------------------
def call_claude_for_log_synthesis(log_path: str) -> str:
    prompt = f"""
次の llm log から、再利用可能な知識だけを抽出してください。

要件:
- 会話形式は残さない
- 試行錯誤・冗長・文脈依存表現は除外
- トピックごとに分割
- 出力はJSONのみ
- 保存先は review/synthesis_candidates/ を想定
- wiki/synthesis に直行しない

JSON schema:
{{
  "topics": [
    {{
      "title": "string",
      "summary": "string",
      "decision": "string",
      "reason": "string",
      "alternatives": "string",
      "reusable_pattern": "string",
      "tags": ["string", "..."]
    }}
  ]
}}

対象ファイル:
{relpath(log_path)}

対象テキスト:
\"\"\"
{read_text(log_path)}
\"\"\"
""".strip()

    result = subprocess.run(
        ["claude", "-p", prompt],
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=False,
    )

    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "claude synthesis failed")

    return result.stdout.strip()


def parse_topics(output: str) -> list[dict[str, Any]]:
    data = json.loads(output)
    topics = data.get("topics", [])
    if not isinstance(topics, list):
        raise ValueError("topics must be a list")
    return topics


def render_candidate_note(topic: dict[str, Any], source_rel: str) -> str:
    title = str(topic.get("title", "Untitled")).strip()
    summary = str(topic.get("summary", "")).strip()
    decision = str(topic.get("decision", "")).strip()
    reason = str(topic.get("reason", "")).strip()
    alternatives = str(topic.get("alternatives", "")).strip()
    reusable_pattern = str(topic.get("reusable_pattern", "")).strip()
    tags = topic.get("tags", [])
    if not isinstance(tags, list):
        tags = []

    return build_frontmatter({
        "title": title,
        "source": source_rel,
        "type": "synthesis_candidate",
        "status": "pending",
        "reviewed_by": "",
        "created": today(),
        "updated": today(),
        "tags": tags,
    }) + f"""
## Summary
{summary}

## Decision
{decision}

## Reason
{reason}

## Alternatives
{alternatives}

## Reusable Pattern
{reusable_pattern}
"""


def candidate_note_path(title: str) -> str:
    return os.path.join(SYNTH_CANDIDATES, f"{slugify(title)}.md")


def cmd_synthesize_logs() -> int:
    ensure_dirs()
    warn_if_dirty_paths(["raw/llm_logs"], "synthesize-logs")

    log_files = list_md_files(LLM_LOGS)
    if not log_files:
        print("No llm logs found in raw/llm_logs/")
        return 0

    generated: list[str] = []

    for log_path in log_files:
        print(f"[READ] {relpath(log_path)}")
        try:
            output = call_claude_for_log_synthesis(log_path)
            topics = parse_topics(output)
        except Exception as e:
            print(f"[FAIL] {relpath(log_path)}: {e}")
            continue

        for topic in topics:
            path = candidate_note_path(str(topic.get("title", "Untitled")))
            if os.path.exists(path):
                print(f"[SKIP] existing candidate: {relpath(path)}")
                continue
            note = render_candidate_note(topic, relpath(log_path))
            write_text(path, note)
            generated.append(relpath(path))
            print(f"[CANDIDATE] {relpath(path)}")

    if generated:
        if not os.path.exists(CHANGE_LOG_MD):
            write_text(CHANGE_LOG_MD, "# Log\n")
        body = f"\n## {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        for g in generated:
            body += f"- synthesis candidate generated: {g}\n"
        append_text(CHANGE_LOG_MD, body)

    print(f"[DONE] generated {len(generated)} candidate notes")
    return 0


# -------------------------
# approve
# -------------------------
def candidate_files() -> list[str]:
    return list_md_files(SYNTH_CANDIDATES)


def approved_candidate_files() -> list[str]:
    approved_paths: list[str] = []
    for path in candidate_files():
        text = read_text(path)
        meta, _ = parse_frontmatter(text)

        if (
            meta.get("status") == "approved"
            and bool(str(meta.get("reviewed_by", "")).strip())
            and is_valid_iso_date(str(meta.get("approved", "")).strip())
            and str(meta.get("promoted", "")).lower() != "true"
        ):
            approved_paths.append(path)

    return approved_paths


def synthesis_target_path(title: str) -> str:
    return os.path.join(WIKI_SYNTH, f"{slugify(title)}.md")


def merge_synthesis(existing_path: str, new_meta: dict[str, str], new_body: str) -> None:
    old_text = read_text(existing_path)
    old_meta, old_body = parse_frontmatter(old_text)

    old_meta["updated"] = today()
    if new_meta.get("reviewed_by"):
        old_meta["reviewed_by"] = new_meta["reviewed_by"]
    if new_meta.get("approved"):
        old_meta["approved"] = new_meta["approved"]

    existing_sources = set()
    candidate_source = old_meta.get("candidate_source", "").strip()
    if candidate_source:
        existing_sources.add(candidate_source)
    new_candidate_source = new_meta.get("candidate_source", "").strip()

    if new_candidate_source and new_candidate_source not in existing_sources:
        if candidate_source:
            old_meta["candidate_source"] = f"{candidate_source}; {new_candidate_source}"
        else:
            old_meta["candidate_source"] = new_candidate_source

    merged = (
        build_frontmatter(old_meta)
        + "\n"
        + old_body.rstrip()
        + f"\n\n---\n\n## Update {today()}\n"
        + new_body.strip()
        + "\n"
    )
    write_text(existing_path, merged)


def promote_candidate(path: str) -> tuple[str, str]:
    text = read_text(path)
    meta, body = parse_frontmatter(text)

    title = meta.get("title", Path(path).stem)
    target = synthesis_target_path(title)

    promoted_meta = dict(meta)
    promoted_meta["type"] = "synthesis"
    promoted_meta["updated"] = today()
    promoted_meta["candidate_source"] = relpath(path)

    promoted_text = build_frontmatter(promoted_meta) + "\n" + body.strip() + "\n"

    if os.path.exists(target):
        merge_synthesis(target, promoted_meta, body)
        return "merged", relpath(target)

    write_text(target, promoted_text)
    return "created", relpath(target)


def mark_candidate_promoted(path: str, target: str) -> None:
    text = read_text(path)
    meta, body = parse_frontmatter(text)

    meta["promoted"] = "true"
    meta["promoted_at"] = today()
    meta["promoted_to"] = target
    meta["updated"] = today()

    write_text(path, build_frontmatter(meta) + "\n" + body.strip() + "\n")


def update_index_synthesis() -> None:
    parent = os.path.dirname(INDEX_MD)
    if parent:
        os.makedirs(parent, exist_ok=True)
    if not os.path.exists(INDEX_MD):
        write_text(INDEX_MD, "# Index\n")

    files = list_md_files(WIKI_SYNTH)
    lines = ["## synthesis\n"]
    for path in sorted(files):
        name = Path(path).stem
        lines.append(f"- [[{name}]]\n")
    new_section = "".join(lines)

    current = read_text(INDEX_MD)
    if "## synthesis" in current:
        current = re.sub(r"## synthesis[\s\S]*?(?=\n## |\Z)", new_section.rstrip() + "\n", current)
    else:
        if not current.endswith("\n"):
            current += "\n"
        current += "\n" + new_section

    write_text(INDEX_MD, current)


def append_approval_log(entries: list[str]) -> None:
    if not os.path.exists(CHANGE_LOG_MD):
        write_text(CHANGE_LOG_MD, "# Log\n")

    stamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    body = f"\n## {stamp}\n"
    for entry in entries:
        body += f"- {entry}\n"
    append_text(CHANGE_LOG_MD, body)


def cmd_approve() -> int:
    ensure_dirs()
    warn_if_dirty_paths(["review/synthesis_candidates"], "approve")

    files = approved_candidate_files()
    if not files:
        print("No approved synthesis candidates found.")
        return 0

    entries: list[str] = []

    for path in files:
        print(f"[APPROVE] {relpath(path)}")
        action, target_rel = promote_candidate(path)
        mark_candidate_promoted(path, target_rel)
        entries.append(f"{action} synthesis: {target_rel} from {relpath(path)}")

    update_index_synthesis()
    append_approval_log(entries)

    print(f"[DONE] approved {len(files)} candidate(s)")
    return 0


# -------------------------
# Prompt Engine
# -------------------------

def parse_agent_mapping(claude_md_path: str) -> dict[str, dict[str, Any]]:
    """CLAUDE.md のマッピング表をパースし、タスク→エージェント+ポリシーの辞書を返す。

    パース手順:
    1. CLAUDE.md を read_text() で読み込む
    2. ヘッダー列名（Task, Agent, Policy, Execution Mode）でテーブル位置と列順を特定
    3. 各データ行を解析し、Policy 列はカンマ区切りでリスト化

    バリデーション:
    - 必須列（Task, Agent, Policy）が存在すること
    - 各行の Agent パスが空でないこと

    Returns:
        {"query_extract": {"agent": "AGENTS/query_extract.md",
                           "policies": ["AGENTS/naming.md", "AGENTS/page_policy.md"],
                           "mode": "Prompt"}, ...}

    Raises:
        ValueError: マッピング表が見つからない、必須列が欠落、またはパース不能な場合
    """
    content = read_text(claude_md_path)

    # マッピングテーブルのヘッダー行を探す
    header_line: str | None = None
    header_line_idx: int = -1
    lines = content.splitlines()

    for i, line in enumerate(lines):
        stripped = line.strip()
        if not stripped.startswith("|"):
            continue
        # ヘッダー候補: Task, Agent, Policy の3列が全て含まれているか
        cells = [c.strip() for c in stripped.strip("|").split("|")]
        lower_cells = [c.lower() for c in cells]
        if "task" in lower_cells and "agent" in lower_cells and "policy" in lower_cells:
            header_line = stripped
            header_line_idx = i
            break

    if header_line is None:
        raise ValueError(
            f"CLAUDE.md のマッピング表が見つかりません: {claude_md_path}"
        )

    # 列インデックスを特定
    header_cells = [c.strip() for c in header_line.strip("|").split("|")]
    lower_header = [c.lower() for c in header_cells]

    required_cols = ["task", "agent", "policy"]
    for col in required_cols:
        if col not in lower_header:
            raise ValueError(
                f"CLAUDE.md のマッピング表に必須列 '{col}' が見つかりません"
            )

    idx_task = lower_header.index("task")
    idx_agent = lower_header.index("agent")
    idx_policy = lower_header.index("policy")
    # Execution Mode 列はオプション
    idx_mode = lower_header.index("execution mode") if "execution mode" in lower_header else None

    mapping: dict[str, dict[str, Any]] = {}

    # ヘッダー行の次の行からデータ行を処理
    for line in lines[header_line_idx + 1:]:
        stripped = line.strip()
        if not stripped.startswith("|"):
            # テーブル終端
            break
        # 区切り行（|---|---|...）をスキップ
        if re.match(r"^\|[-|\s:]+\|$", stripped):
            continue

        cells = [c.strip() for c in stripped.strip("|").split("|")]
        # 列数が不足している場合はスキップ
        max_required = max(idx_task, idx_agent, idx_policy)
        if len(cells) <= max_required:
            continue

        task_name = cells[idx_task].strip()
        agent_path = cells[idx_agent].strip()
        policy_raw = cells[idx_policy].strip()
        mode = cells[idx_mode].strip() if idx_mode is not None and idx_mode < len(cells) else ""

        if not task_name:
            continue

        if not agent_path:
            raise ValueError(
                f"CLAUDE.md マッピング表の行 '{task_name}' に Agent パスが空です"
            )

        # Policy はカンマ区切りでリスト化
        policies = [p.strip() for p in policy_raw.split(",") if p.strip()]

        mapping[task_name] = {
            "agent": agent_path,
            "policies": policies,
            "mode": mode,
        }

    if not mapping:
        raise ValueError(
            f"CLAUDE.md のマッピング表にデータ行が見つかりません: {claude_md_path}"
        )

    return mapping


def load_task_prompts(task_name: str) -> str:
    """タスクに必要なエージェント+ポリシーを CLAUDE.md マッピングに基づいて読み込み、結合して返す。

    手順:
    1. parse_agent_mapping() でマッピングを取得
    2. task_name に対応するエージェントファイルを読み込む
    3. 対応するポリシーを全て読み込む
    4. エージェント + ポリシーを結合して返す

    Raises:
        ValueError: task_name がマッピング表に存在しない場合
        FileNotFoundError: エージェントまたはポリシーファイルが存在しない場合
    """
    claude_md_path = os.path.join(ROOT, "CLAUDE.md")
    mapping = parse_agent_mapping(claude_md_path)

    if task_name not in mapping:
        raise ValueError(
            f"タスク '{task_name}' は CLAUDE.md のマッピング表に存在しません"
        )

    entry = mapping[task_name]
    agent_path = os.path.join(ROOT, entry["agent"])
    policy_paths = [os.path.join(ROOT, p) for p in entry["policies"]]

    if not os.path.isfile(agent_path):
        raise FileNotFoundError(
            f"エージェントファイルが見つかりません: {agent_path}"
        )

    for pol_path in policy_paths:
        if not os.path.isfile(pol_path):
            raise FileNotFoundError(
                f"ポリシーファイルが見つかりません: {pol_path}"
            )

    parts: list[str] = [read_text(agent_path)]
    for pol_path in policy_paths:
        parts.append(read_text(pol_path))

    return "\n\n".join(parts)


def build_query_prompt(
    task_prompts: str,
    question: str,
    wiki_content: str,
    *,
    output_format: str = "json",
    query_type: str | None = None,
    lint_results: dict[str, Any] | None = None,
    existing_artifacts: dict[str, str] | None = None,
) -> str:
    """エージェント+ポリシーの内容とコンテキストからプロンプトを構築する。

    プロンプト構造:
    1. エージェント+ポリシーの内容（ルール定義）
    2. wikiコンテンツ（知識ソース）
    3. 質問文またはタスク指示
    4. 出力形式指定（output_format に基づく）
    """
    parts: list[str] = []

    # 1. エージェント+ポリシー（ルール定義）
    parts.append(task_prompts)

    # 2. wiki コンテンツ（知識ソース）
    parts.append("## Wiki コンテンツ\n\n" + wiki_content)

    # 3. 質問文またはタスク指示
    if query_type is not None:
        parts.append(f"## 質問（query_type: {query_type}）\n\n{question}")
    else:
        # query_type=None → Claude に自動判定させる
        parts.append(f"## 質問\n\n{question}")

    # fix モード: lint_results と existing_artifacts を含める
    if lint_results is not None:
        lint_json = json.dumps(lint_results, ensure_ascii=False, indent=2)
        parts.append(f"## Lint 結果\n\n```json\n{lint_json}\n```")

    if existing_artifacts is not None:
        artifact_parts: list[str] = ["## 既存アーティファクト"]
        for filename, content in existing_artifacts.items():
            artifact_parts.append(f"### {filename}\n\n{content}")
        parts.append("\n\n".join(artifact_parts))

    # 4. 出力形式指定
    if output_format == "plaintext":
        output_instruction = (
            "## 出力形式\n\n"
            "回答をプレーンテキスト（Markdown）で出力してください。\n"
            "回答の末尾に必ず以下の形式で参照ページリストを付与してください:\n\n"
            "---\n"
            "Referenced: page1.md, page2.md"
        )
    elif lint_results is not None:
        # fix モード: fix スキーマ
        fix_schema = {
            "fixes": [{"file": "...", "ql_code": "...", "action": "..."}],
            "files": {
                "question.md": "...",
                "answer.md": "...",
                "evidence.md": None,
                "metadata.json": None,
            },
            "skipped": [{"ql_code": "...", "reason": "..."}],
        }
        fix_schema_json = json.dumps(fix_schema, ensure_ascii=False, indent=2)
        output_instruction = (
            "## 出力形式\n\n"
            "以下の JSON スキーマに従って、修正内容を JSON 形式で出力してください。\n"
            "コードブロック（```json ... ```）で囲まずに、JSONのみを出力してください。\n\n"
            f"```json\n{fix_schema_json}\n```"
        )
    else:
        # extract モード: 4ファイル抽出スキーマ
        extract_schema = {
            "query": {
                "text": "...",
                "query_type": "fact|structure|comparison|why|hypothesis",
                "scope": "...",
                "date": "YYYY-MM-DD",
            },
            "answer": {"content": "Markdown"},
            "evidence": {
                "blocks": [{"source": "wiki/path.md", "excerpt": "..."}]
            },
            "metadata": {
                "query_id": "...",
                "query_type": "...",
                "scope": "...",
                "sources": ["..."],
                "created_at": "...",
            },
            "referenced_pages": ["wiki/path.md"],
        }
        extract_schema_json = json.dumps(extract_schema, ensure_ascii=False, indent=2)
        output_instruction = (
            "## 出力形式\n\n"
            "以下の JSON スキーマに従って、回答を JSON 形式で出力してください。\n"
            "コードブロック（```json ... ```）で囲まずに、JSONのみを出力してください。\n"
            "推測・推定を含む場合は [INFERENCE] マーカーを付与してください。\n\n"
            f"```json\n{extract_schema_json}\n```"
        )

    parts.append(output_instruction)

    return "\n\n".join(parts)


def call_claude(prompt: str) -> str:
    """Claude CLI を呼び出してレスポンスを返す。

    Raises:
        RuntimeError: Claude CLI がエラーを返した場合（stderrを含む）
    """
    result = subprocess.run(
        ["claude", "-p", prompt],
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=False,
    )
    if result.returncode != 0:
        print(result.stdout[:500], file=sys.stderr)
        raise RuntimeError(result.stderr.strip() or "claude call failed")
    return result.stdout.strip()


def read_wiki_content(scope: str | None) -> str:
    """wiki/ のコンテンツを収集して返す。

    Args:
        scope: 指定時はそのページのみ読み込む。None 時は全ファイル読み込み（小規模 wiki）
               またはindex.md のみ（大規模 wiki、ファイル数 > 20）。

    Returns:
        wiki コンテンツ文字列。

    Raises:
        FileNotFoundError: wiki/ が存在しない場合、または scope で指定されたページが存在しない場合
        ValueError: wiki/ に .md ファイルが存在しない場合
    """
    if scope is not None:
        # scope 指定: そのファイルのみ読み込む
        if not os.path.isfile(scope):
            raise FileNotFoundError(f"指定されたwikiページが見つかりません: {scope}")
        return read_text(scope)

    # scope=None: wiki/ ディレクトリを対象とする
    if not os.path.isdir(WIKI):
        raise FileNotFoundError(f"wiki/ ディレクトリが見つかりません: {WIKI}")

    md_files = list_md_files(WIKI)
    if not md_files:
        raise ValueError(f"wiki/ に .md ファイルが存在しません: {WIKI}")

    # 小規模 wiki (≤20): 全ファイルを結合して返す
    if len(md_files) <= 20:
        parts: list[str] = []
        for path in md_files:
            parts.append(f"<!-- file: {relpath(path)} -->\n{read_text(path)}")
        return "\n\n".join(parts)

    # 大規模 wiki (>20): index.md のみを返す（cmd_* が2段階方式でオーケストレーションする）
    return read_text(INDEX_MD)


# -------------------------
# Output utilities
# -------------------------

def generate_query_id(question: str) -> str:
    """YYYYMMDD-<slugify(question)> 形式の query_id を生成する。

    slugify は既存関数を使用（ASCII, lowercase, hyphen, max 80 chars）。

    Raises:
        ValueError: question が空または空白のみの場合
    """
    if not question or not question.strip():
        raise ValueError("question must not be empty")
    date_prefix = today().replace("-", "")
    slug = slugify(question)
    return f"{date_prefix}-{slug}"


def write_query_artifacts(
    query_id: str,
    data: dict[str, Any],
) -> list[str]:
    """review/query/<query_id>/ に4ファイルを書き出す。

    CLI が generate_query_id() で生成した query_id を正とする。
    Claude CLI レスポンス内の query_id は無視し、CLI 生成の query_id で
    metadata.json の query_id フィールドおよびディレクトリ名を上書きする。

    Returns:
        生成したファイルパスのリスト
    """
    base_dir = os.path.join(QUERY_REVIEW, query_id)
    os.makedirs(base_dir, exist_ok=True)

    # question.md: キーバリュー形式
    query = data["query"]
    question_content = (
        f"query: {query['text']}\n"
        f"query_type: {query['query_type']}\n"
        f"scope: {query['scope']}\n"
        f"date: {query['date']}\n"
    )
    question_path = os.path.join(base_dir, "question.md")
    write_text(question_path, question_content)

    # answer.md: Markdown コンテンツそのまま
    answer_path = os.path.join(base_dir, "answer.md")
    write_text(answer_path, data["answer"]["content"])

    # evidence.md: evidence blocks から source: 行を含む形式で書き出す
    blocks = data["evidence"]["blocks"]
    evidence_lines: list[str] = []
    for block in blocks:
        evidence_lines.append(f"source: {block['source']}")
        if block.get("excerpt"):
            evidence_lines.append(block["excerpt"])
        evidence_lines.append("")
    evidence_content = "\n".join(evidence_lines).rstrip() + "\n"
    evidence_path = os.path.join(base_dir, "evidence.md")
    write_text(evidence_path, evidence_content)

    # metadata.json: CLI 生成の query_id で上書き
    metadata = dict(data["metadata"])
    metadata["query_id"] = query_id
    metadata_path = os.path.join(base_dir, "metadata.json")
    write_text(metadata_path, json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")

    return [question_path, answer_path, evidence_path, metadata_path]


def _strip_code_block(response: str) -> str:
    """マークダウンコードブロック（```json ... ``` や ``` ... ```）を除去する。"""
    stripped = response.strip()
    # ```json\n...\n``` または ```\n...\n``` 形式を除去
    match = re.match(r"^```(?:json)?\s*\n([\s\S]*?)\n```\s*$", stripped)
    if match:
        return match.group(1)
    return stripped


def parse_extract_response(response: str) -> dict[str, Any]:
    """Claude CLI の extract レスポンス（JSON）をパースする。

    Args:
        response: Claude CLI のレスポンス文字列（JSON または ```json...``` 形式）

    Returns:
        パースした dict（query/answer/evidence/metadata の各キーを含む）

    Raises:
        ValueError: 不正な JSON、または必須フィールド（query/answer/evidence/metadata）が欠落した場合
    """
    required_keys = ("query", "answer", "evidence", "metadata")
    try:
        cleaned = _strip_code_block(response)
        data = json.loads(cleaned)
    except json.JSONDecodeError as e:
        print(response[:500], file=sys.stderr)
        raise ValueError(f"extract レスポンスの JSON パースに失敗しました: {e}") from e

    missing = [k for k in required_keys if k not in data]
    if missing:
        print(response[:500], file=sys.stderr)
        raise ValueError(
            f"extract レスポンスに必須フィールドが欠落しています: {', '.join(missing)}"
        )

    return data


def parse_fix_response(response: str) -> dict[str, Any]:
    """Claude CLI の fix レスポンス（JSON）をパースする。

    Args:
        response: Claude CLI のレスポンス文字列（JSON または ```json...``` 形式）

    Returns:
        パースした dict（fixes/files/skipped の各キーを含む）

    Raises:
        ValueError: 不正な JSON、または必須フィールド（fixes/files）が欠落した場合
    """
    required_keys = ("fixes", "files")
    try:
        cleaned = _strip_code_block(response)
        data = json.loads(cleaned)
    except json.JSONDecodeError as e:
        print(response[:500], file=sys.stderr)
        raise ValueError(f"fix レスポンスの JSON パースに失敗しました: {e}") from e

    missing = [k for k in required_keys if k not in data]
    if missing:
        print(response[:500], file=sys.stderr)
        raise ValueError(
            f"fix レスポンスに必須フィールドが欠落しています: {', '.join(missing)}"
        )

    return data


# -------------------------
# query commands
# -------------------------

def cmd_query_extract(args: list[str]) -> int:
    """rw query extract サブコマンド。終了コードを返す。"""
    # 1. 引数パース（question, --scope, --type）
    question: str = ""
    scope: str | None = None
    query_type: str | None = None

    i = 0
    while i < len(args):
        a = args[i]
        if a == "--scope":
            i += 1
            if i < len(args):
                scope = args[i]
        elif a == "--type":
            i += 1
            if i < len(args):
                query_type = args[i]
        elif not a.startswith("--") and not question:
            question = a
        i += 1

    # 質問文が空の場合はエラー終了
    if not question or not question.strip():
        print("[ERROR] question is required")
        return 1

    # 2. 前提条件チェック
    # wiki/ 存在チェック
    if not os.path.isdir(WIKI):
        print(f"[ERROR] wiki/ ディレクトリが見つかりません: {WIKI}")
        return 1

    # CLAUDE.md 存在チェック
    if not os.path.exists(os.path.join(ROOT, "CLAUDE.md")):
        print(f"[ERROR] CLAUDE.md が見つかりません: {os.path.join(ROOT, 'CLAUDE.md')}")
        return 1

    # AGENTS/ 存在チェック
    if not os.path.isdir(os.path.join(ROOT, "AGENTS")):
        print(f"[ERROR] AGENTS/ ディレクトリが見つかりません: {os.path.join(ROOT, 'AGENTS')}")
        return 1

    warn_if_dirty_paths(["wiki"], "query extract")

    # 3. query_id 生成
    try:
        query_id = generate_query_id(question)
    except ValueError as e:
        print(f"[ERROR] {e}")
        return 1

    query_dir = os.path.join(QUERY_REVIEW, query_id)
    if os.path.isdir(query_dir):
        print(
            f"[ERROR] query_id '{query_id}' のディレクトリが既に存在します: {query_dir}\n"
            f"手動で削除することで再生成できます: rm -rf {query_dir}"
        )
        return 1

    # 4. load_task_prompts
    try:
        task_prompts = load_task_prompts("query_extract")
    except (ValueError, FileNotFoundError) as e:
        print(f"[ERROR] load_task_prompts 失敗: {e}")
        return 1

    # 5. wiki サイズチェックと wiki_content 取得
    try:
        num_files = len(list_md_files(WIKI))
        if num_files > 20 and scope is None:
            # 2段階方式: ステージ1で関連ページ特定
            try:
                index_content = read_text(INDEX_MD)
            except FileNotFoundError:
                index_content = ""

            stage1_prompt = (
                f"{task_prompts}\n\n"
                f"## Wiki Index\n\n{index_content}\n\n"
                f"## 質問\n\n{question}\n\n"
                "## タスク\n\n"
                "上記の wiki インデックスと質問から、回答に関連するwikiページのパスを特定してください。\n"
                '{"identified_pages": ["wiki/path1.md", "wiki/path2.md"]} の形式でJSONのみを出力してください。'
            )
            stage1_response = call_claude(stage1_prompt)

            # ステージ1のレスポンスから関連ページを特定
            identified_pages: list[str] = []
            try:
                stage1_data = json.loads(_strip_code_block(stage1_response))
                identified_pages = stage1_data.get("identified_pages", [])
            except (json.JSONDecodeError, AttributeError):
                identified_pages = []

            if identified_pages:
                # 特定されたページを読み込む
                parts: list[str] = []
                for page_path in identified_pages:
                    full_path = os.path.join(ROOT, page_path) if not os.path.isabs(page_path) else page_path
                    if os.path.isfile(full_path):
                        parts.append(f"<!-- file: {page_path} -->\n{read_text(full_path)}")
                    elif os.path.isfile(page_path):
                        parts.append(f"<!-- file: {page_path} -->\n{read_text(page_path)}")
                wiki_content = "\n\n".join(parts) if parts else index_content
            else:
                # フォールバック: index.md を使用
                wiki_content = index_content
        else:
            wiki_content = read_wiki_content(scope)
    except FileNotFoundError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1
    except ValueError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1

    # 6. プロンプト構築
    prompt = build_query_prompt(
        task_prompts,
        question,
        wiki_content,
        output_format="json",
        query_type=query_type,
    )

    # 7. Claude 呼び出し
    try:
        response = call_claude(prompt)
    except RuntimeError as e:
        print(f"[ERROR] Claude 呼び出し失敗: {e}")
        return 1

    # 8. レスポンスパース
    try:
        data = parse_extract_response(response)
    except ValueError as e:
        print(f"[ERROR] レスポンスパース失敗: {e}")
        return 1

    # 9. アーティファクト書き出し
    try:
        file_paths = write_query_artifacts(query_id, data)
    except Exception as e:
        print(f"[ERROR] アーティファクト書き出し失敗: {e}")
        return 1

    # 10. lint 検証
    lint_result = lint_single_query_dir(query_dir)

    # 11. 結果に基づいて終了コードを返す
    if lint_result["status"] == "FAIL":
        print(f"[WARN] lint 検証失敗: {lint_result['target']}")
        for err in lint_result["errors"]:
            print(f"  [ERROR] {err}")
        print("[INFO] アーティファクトは生成されましたが lint に失敗しました。")
        for p in file_paths:
            print(f"  {relpath(p)}")
        return 2
    else:
        print(f"[DONE] query extract 完了: {query_id}")
        for p in file_paths:
            print(f"  {relpath(p)}")
        return 0


def cmd_query_answer(args: list[str]) -> int:
    """rw query answer サブコマンド。終了コードを返す。"""
    # 1. 引数パース（question, --scope）
    question: str = ""
    scope: str | None = None

    i = 0
    while i < len(args):
        a = args[i]
        if a == "--scope":
            i += 1
            if i < len(args):
                scope = args[i]
        elif not a.startswith("--") and not question:
            question = a
        i += 1

    # 質問文が空の場合はエラー終了
    if not question or not question.strip():
        print("[ERROR] question is required")
        return 1

    # 2. 前提条件チェック
    # wiki/ 存在チェック
    if not os.path.isdir(WIKI):
        print(f"[ERROR] wiki/ ディレクトリが見つかりません: {WIKI}")
        return 1

    # CLAUDE.md 存在チェック
    if not os.path.exists(os.path.join(ROOT, "CLAUDE.md")):
        print(f"[ERROR] CLAUDE.md が見つかりません: {os.path.join(ROOT, 'CLAUDE.md')}")
        return 1

    # AGENTS/ 存在チェック
    if not os.path.isdir(os.path.join(ROOT, "AGENTS")):
        print(f"[ERROR] AGENTS/ ディレクトリが見つかりません: {os.path.join(ROOT, 'AGENTS')}")
        return 1

    warn_if_dirty_paths(["wiki"], "query answer")

    # 3. load_task_prompts
    try:
        task_prompts = load_task_prompts("query_answer")
    except (ValueError, FileNotFoundError) as e:
        print(f"[ERROR] load_task_prompts 失敗: {e}")
        return 1

    # 4. wiki コンテンツ取得
    try:
        wiki_content = read_wiki_content(scope)
    except FileNotFoundError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1
    except ValueError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1

    # 5. プロンプト構築
    prompt = build_query_prompt(
        task_prompts,
        question,
        wiki_content,
        output_format="plaintext",
    )

    # 6. Claude 呼び出し
    try:
        response = call_claude(prompt)
    except RuntimeError as e:
        print(f"[ERROR] Claude 呼び出し失敗: {e}")
        return 1

    # 7. レスポンスパース: "---\nReferenced:" で分割
    separator = "\n---\nReferenced:"
    if separator in response:
        parts = response.split(separator, 1)
        answer_text = parts[0]
        referenced_raw = parts[1].strip()
        referenced_pages = [p.strip() for p in referenced_raw.split(",") if p.strip()]
    else:
        answer_text = response
        referenced_pages = []

    # 8. 回答テキストを stdout に表示
    print(answer_text)

    # 9. 参照ページセクションを stdout に表示
    if referenced_pages:
        print("\n---")
        print("Referenced:")
        for page in referenced_pages:
            print(f"  {page}")

    return 0


# -------------------------
# query lint
# -------------------------
def count_evidence_blocks(text: str) -> int:
    count = 0
    for line in text.splitlines():
        s = line.strip()
        if (
            s == "---"
            or s.startswith("###")
            or s.lower().startswith("source:")
            or s.lower().startswith("file:")
            or s.lower().startswith("page:")
            or s.lower().startswith("path:")
        ):
            count += 1
    return max(count, 1 if text.strip() else 0)


def contains_markdown_structure(text: str) -> bool:
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("#") or s.startswith("- ") or s.startswith("* "):
            return True
        if re.match(r"^\d+\.\s+", s):
            return True
    return False


def has_query_text(text: str) -> bool:
    if not text.strip():
        return False

    lines = text.splitlines()
    for i, line in enumerate(lines):
        s = line.strip()
        if re.match(r"^query\s*:", s, re.IGNORECASE):
            return True
        if re.match(r"^#{1,3}\s*query\b", s, re.IGNORECASE):
            for j in range(i + 1, min(i + 6, len(lines))):
                if lines[j].strip():
                    return True

    return len(text.strip()) >= 20


def extract_query_type(query_text: str, metadata: dict[str, Any]) -> str | None:
    qt = metadata.get("query_type")
    if isinstance(qt, str) and qt.strip():
        return qt.strip().lower()

    for line in query_text.splitlines():
        s = line.strip()
        m = re.match(r"^query_type\s*:\s*(.+)$", s, re.IGNORECASE)
        if m:
            return m.group(1).strip().lower()
        m = re.match(r"^type\s*:\s*(.+)$", s, re.IGNORECASE)
        if m:
            return m.group(1).strip().lower()

    return None


def extract_scope(query_text: str, metadata: dict[str, Any]) -> str | list[Any] | None:
    scope = metadata.get("scope")
    if scope:
        return scope

    for line in query_text.splitlines():
        s = line.strip()
        m = re.match(r"^scope\s*:\s*(.+)$", s, re.IGNORECASE)
        if m:
            return m.group(1).strip()

    return None


def has_evidence_source(text: str) -> bool:
    for line in text.splitlines():
        s = line.strip()
        for pat in EVIDENCE_SOURCE_PATTERNS:
            if re.search(pat, s, re.IGNORECASE):
                return True
    return False


def contains_inference_language(text: str) -> bool:
    for pat in INFERENCE_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            return True
    return False


def lint_single_query_dir(query_dir: str, strict: bool = False) -> dict[str, Any]:
    result: dict[str, Any] = {
        "target": relpath(query_dir),
        "status": "PASS",
        "errors": [],
        "warnings": [],
        "infos": [],
        "checks": [],
    }

    def add(level: str, code: str, message: str) -> None:
        result["checks"].append({
            "id": code,
            "severity": level,
            "message": message,
        })
        if level == "ERROR":
            result["errors"].append(f"{code} {message}")
        elif level == "WARN":
            result["warnings"].append(f"{code} {message}")
        else:
            result["infos"].append(f"{code} {message}")

    required_files = {
        "question.md": os.path.join(query_dir, "question.md"),
        "answer.md": os.path.join(query_dir, "answer.md"),
        "evidence.md": os.path.join(query_dir, "evidence.md"),
        "metadata.json": os.path.join(query_dir, "metadata.json"),
    }

    missing = []
    for name, path in required_files.items():
        if not os.path.exists(path):
            missing.append(name)
            add("ERROR", "QL001", f"missing file: {name}")

    if missing:
        result["status"] = "FAIL"
        return result

    query_text = read_text(required_files["question.md"])
    answer_text = read_text(required_files["answer.md"])
    evidence_text = read_text(required_files["evidence.md"])

    metadata, metadata_err = safe_read_json(required_files["metadata.json"])
    if metadata_err:
        add("ERROR", "QL017", f"metadata.json is invalid JSON: {metadata_err}")
        result["status"] = "FAIL"
        return result

    metadata = metadata or {}

    if not has_query_text(query_text):
        add("ERROR", "QL002", "query text not found")

    scope = extract_scope(query_text, metadata)
    if not scope:
        add("ERROR", "QL004", "scope not found")

    if not answer_text.strip() or len(answer_text.strip()) < 30:
        add("ERROR", "QL006", "answer.md is empty or too short")

    if not evidence_text.strip() or len(evidence_text.strip()) < 30:
        add("ERROR", "QL008", "evidence.md is empty or too short")

    if evidence_text.strip() and not has_evidence_source(evidence_text):
        add("ERROR", "QL009", "evidence source information not found")

    query_type = extract_query_type(query_text, metadata)
    if query_type == "hypothesis":
        if "[INFERENCE]" not in answer_text:
            add("ERROR", "QL011", "hypothesis query requires [INFERENCE] marker")
    else:
        if contains_inference_language(answer_text) and "[INFERENCE]" not in answer_text:
            if strict:
                add("ERROR", "QL011", "inference-like language found without [INFERENCE]")
            else:
                add("WARN", "QL011", "inference-like language found without [INFERENCE]")

    if "query_id" not in metadata or not metadata.get("query_id"):
        add("ERROR", "QL017", "metadata.query_id is missing")
    if "sources" not in metadata or not metadata.get("sources"):
        add("ERROR", "QL017", "metadata.sources is missing")

    if not query_type:
        add("WARN", "QL003", "query_type not found")
    elif query_type not in ALLOWED_QUERY_TYPES:
        add("ERROR", "QL003", f"invalid query_type: {query_type}")

    if "created_at" not in metadata or not metadata.get("created_at"):
        add("WARN", "QL005", "metadata.created_at is missing")

    if not contains_markdown_structure(answer_text):
        add("WARN", "QL007", "answer.md is weakly structured")

    if answer_text.strip() and evidence_text.strip():
        answer_len = len(answer_text.strip())
        evidence_blocks = count_evidence_blocks(evidence_text)
        if answer_len > 1500 and evidence_blocks < 2:
            add("WARN", "QL010", "long answer with too few evidence blocks")

    if result["errors"]:
        result["status"] = "FAIL"
    elif result["warnings"]:
        result["status"] = "PASS_WITH_WARNINGS"
    else:
        result["status"] = "PASS"

    return result


def print_query_lint_text(results: list[dict[str, Any]]) -> None:
    total_errors = 0
    total_warnings = 0

    for res in results:
        print(f"Lint Result: {res['status']}")
        print(f"Target: {res['target']}")
        print()

        for chk in res["checks"]:
            print(f"{chk['severity']:5} {chk['id']:6} {chk['message']}")

        if not res["checks"]:
            print("No issues found.")

        print()
        total_errors += len(res["errors"])
        total_warnings += len(res["warnings"])

    print(f"Summary: {len(results)} target(s), {total_errors} error(s), {total_warnings} warning(s)")


def cmd_lint_query(args: list[str]) -> int:
    ensure_dirs()

    target_path = None
    strict = False
    output_format = "text"

    i = 0
    while i < len(args):
        a = args[i]
        if a == "--path":
            i += 1
            if i >= len(args):
                print("missing value for --path")
                return 3
            target_path = args[i]
        elif a == "--strict":
            strict = True
        elif a == "--format":
            i += 1
            if i >= len(args):
                print("missing value for --format")
                return 3
            output_format = args[i]
        else:
            if not a.startswith("--") and target_path is None:
                target_path = a
            else:
                print(f"unknown option: {a}")
                return 3
        i += 1

    if target_path:
        query_dirs = [target_path]
    else:
        query_dirs = list_query_dirs(QUERY_REVIEW)

    if not query_dirs:
        print("No query directories found.")
        return 0

    missing_paths = [p for p in query_dirs if not os.path.isdir(p)]
    if missing_paths:
        print(f"target path not found: {missing_paths[0]}")
        return 4

    results = [lint_single_query_dir(p, strict=strict) for p in query_dirs]

    payload = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "results": results,
        "summary": {
            "targets": len(results),
            "errors": sum(len(r["errors"]) for r in results),
            "warnings": sum(len(r["warnings"]) for r in results),
        },
    }
    write_text(QUERY_LINT_LOG, json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

    if output_format == "json":
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print_query_lint_text(results)
        print(f"Log: {relpath(QUERY_LINT_LOG)}")

    has_error = any(r["status"] == "FAIL" for r in results)
    has_warn = any(r["status"] == "PASS_WITH_WARNINGS" for r in results)

    if has_error:
        return 2
    if has_warn:
        return 1
    return 0


def cmd_query_fix(args: list[str]) -> int:
    """rw query fix サブコマンド。終了コードを返す。"""
    # 1. 引数パース（query_id）
    if not args:
        print("[ERROR] query_id is required")
        return 1

    query_id = args[0]

    # 2. 前提条件チェック
    query_dir = os.path.join(QUERY_REVIEW, query_id)
    if not os.path.isdir(query_dir):
        print(f"[ERROR] query_id ディレクトリが見つかりません: {query_dir}")
        return 1

    if not os.path.exists(os.path.join(ROOT, "CLAUDE.md")):
        print(f"[ERROR] CLAUDE.md が見つかりません: {os.path.join(ROOT, 'CLAUDE.md')}")
        return 1

    if not os.path.isdir(os.path.join(ROOT, "AGENTS")):
        print(f"[ERROR] AGENTS/ ディレクトリが見つかりません: {os.path.join(ROOT, 'AGENTS')}")
        return 1

    warn_if_dirty_paths(["wiki"], "query fix")

    # 3. 事前 lint
    pre_lint = lint_single_query_dir(query_dir)
    if not pre_lint["errors"]:
        print(f"[INFO] 修復不要: {query_id} は lint 検証をパスしています")
        return 0

    # 4. load_task_prompts
    try:
        task_prompts = load_task_prompts("query_fix")
    except (ValueError, FileNotFoundError) as e:
        print(f"[ERROR] load_task_prompts 失敗: {e}")
        return 1

    # 5. wiki コンテンツ取得
    try:
        wiki_content = read_wiki_content(scope=None)
    except FileNotFoundError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1
    except ValueError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1

    # 6. 既存アーティファクト読み込み
    artifact_paths = {
        "question.md": os.path.join(query_dir, "question.md"),
        "answer.md": os.path.join(query_dir, "answer.md"),
        "evidence.md": os.path.join(query_dir, "evidence.md"),
        "metadata.json": os.path.join(query_dir, "metadata.json"),
    }
    existing_artifacts: dict[str, str] = {}
    for filename, path in artifact_paths.items():
        if os.path.exists(path):
            existing_artifacts[filename] = read_text(path)

    # 7. プロンプト構築
    prompt = build_query_prompt(
        task_prompts,
        question="",
        wiki_content=wiki_content,
        output_format="json",
        lint_results=pre_lint,
        existing_artifacts=existing_artifacts,
    )

    # 8. Claude 呼び出し
    try:
        response = call_claude(prompt)
    except RuntimeError as e:
        print(f"[ERROR] Claude 呼び出し失敗: {e}")
        return 1

    # 9. レスポンスパース
    try:
        fix_data = parse_fix_response(response)
    except ValueError as e:
        print(f"[ERROR] レスポンスパース失敗: {e}")
        return 1

    # 10. 変更が必要なファイルのみ書き出し（None はスキップ）
    written_files: list[str] = []
    for filename, content in fix_data["files"].items():
        if content is not None:
            file_path = os.path.join(query_dir, filename)
            write_text(file_path, content)
            written_files.append(filename)

    # 11. 修復結果と skipped 項目を報告
    print(f"[FIX] {query_id}: {len(written_files)} ファイルを修復")
    for fix in fix_data.get("fixes", []):
        print(f"  [{fix.get('ql_code', '?')}] {fix.get('file', '?')}: {fix.get('action', '')}")

    skipped = fix_data.get("skipped", [])
    if skipped:
        print(f"[SKIP] 修復不可能な項目: {len(skipped)} 件")
        for skip in skipped:
            print(f"  [{skip.get('ql_code', '?')}] {skip.get('reason', '')}")

    # 12. post-fix lint 再検証
    post_lint = lint_single_query_dir(query_dir)

    # 13. post-fix lint 結果を表示
    print(f"\n[POST-FIX LINT] status: {post_lint['status']}")
    for err in post_lint.get("errors", []):
        print(f"  [ERROR] {err}")
    for warn in post_lint.get("warnings", []):
        print(f"  [WARN] {warn}")

    # 14. 終了コード決定
    if post_lint["errors"]:
        return 2
    return 0


# -------------------------
# cmd_init
# -------------------------
def cmd_init(args: list[str]) -> int:
  """
  Vaultセットアップを実行する。

  args: コマンドライン引数（target_path を含む場合あり）
  returns: 終了コード（0: 成功, 1: エラー）
  """
  # --- 引数解析 ---
  target_path = args[0] if args else os.getcwd()

  # --- report dict 初期化 ---
  report: dict[str, Any] = {
    "target": target_path,
    "dirs_created": 0,
    "templates_copied": [],
    "skipped": [],
  }

  # --- テンプレートチェック ---
  tmpl_claude = os.path.join(DEV_ROOT, "templates", "CLAUDE.md")
  tmpl_gitignore = os.path.join(DEV_ROOT, "templates", ".gitignore")
  if not os.path.exists(tmpl_claude):
    print(f"[ERROR] templates/CLAUDE.md not found: {tmpl_claude}")
    return 1
  if not os.path.exists(tmpl_gitignore):
    print(f"[ERROR] templates/.gitignore not found: {tmpl_gitignore}")
    return 1

  # --- ターゲットパス作成 ---
  if not os.path.exists(target_path):
    try:
      os.makedirs(target_path)
    except OSError as e:
      print(f"[ERROR] failed to create target path '{target_path}': {e}")
      return 1

  # --- Vault検出 ---
  if is_existing_vault(target_path):
    ans = input(
      f"[WARN] '{target_path}' は既存のVaultです。上書きしますか？ [y/N]: "
    ).strip().lower()
    if ans != "y":
      print("[INFO] セットアップを中断しました。")
      return 0

  # --- ディレクトリ生成 ---
  dirs_created = 0
  for d in VAULT_DIRS:
    dir_path = os.path.join(target_path, d)
    try:
      os.makedirs(dir_path, exist_ok=True)
      dirs_created += 1
    except OSError as e:
      print(f"[WARN] ディレクトリ作成失敗 '{dir_path}': {e}")
  report["dirs_created"] = dirs_created

  # --- CLAUDE.md コピー（re-init 時はバックアップ後上書き） ---
  dest_claude = os.path.join(target_path, "CLAUDE.md")
  try:
    if os.path.exists(dest_claude):
      os.rename(dest_claude, dest_claude + ".bak")
    shutil.copy2(tmpl_claude, dest_claude)
    report["templates_copied"].append("CLAUDE.md")
  except Exception as e:
    print(f"[WARN] CLAUDE.md コピー失敗: {e}")
    report["skipped"].append({"item": "CLAUDE.md", "reason": str(e)})

  # --- AGENTS/ コピー（re-init 時はバックアップ後上書き） ---
  tmpl_agents = os.path.join(DEV_ROOT, "templates", "AGENTS")
  dest_agents = os.path.join(target_path, "AGENTS")
  if os.path.isdir(tmpl_agents):
    try:
      if os.path.isdir(dest_agents):
        bak_agents = dest_agents + ".bak"
        if os.path.isdir(bak_agents):
          shutil.rmtree(bak_agents)
        os.rename(dest_agents, bak_agents)
      shutil.copytree(tmpl_agents, dest_agents, dirs_exist_ok=True)
      report["templates_copied"].append("AGENTS/")
    except Exception as e:
      print(f"[WARN] AGENTS/ コピー失敗: {e}")
      report["skipped"].append({"item": "AGENTS/", "reason": str(e)})
  else:
    report["skipped"].append({"item": "AGENTS/", "reason": "templates/AGENTS/ が存在しない"})

  # --- 初期ファイル生成 ---
  index_md = os.path.join(target_path, "index.md")
  if not os.path.exists(index_md):
    try:
      write_text(index_md, "# Index\n")
      report["templates_copied"].append("index.md")
    except Exception as e:
      print(f"[WARN] index.md 生成失敗: {e}")
      report["skipped"].append({"item": "index.md", "reason": str(e)})
  else:
    report["skipped"].append({"item": "index.md", "reason": "既存ファイルを保護"})

  log_md = os.path.join(target_path, "log.md")
  if not os.path.exists(log_md):
    try:
      write_text(log_md, "# Log\n")
      report["templates_copied"].append("log.md")
    except Exception as e:
      print(f"[WARN] log.md 生成失敗: {e}")
      report["skipped"].append({"item": "log.md", "reason": str(e)})
  else:
    report["skipped"].append({"item": "log.md", "reason": "既存ファイルを保護"})

  # --- Git 初期化 ---
  git_dir = os.path.join(target_path, ".git")
  if not os.path.exists(git_dir):
    try:
      result = subprocess.run(
        ["git", "init"], cwd=target_path, capture_output=True, text=True
      )
      if result.returncode == 0:
        report["git_init"] = "initialized"
      else:
        print(f"[WARN] git init 失敗: {result.stderr.strip()}")
        report["git_init"] = f"failed: {result.stderr.strip()}"
    except Exception as e:
      print(f"[WARN] git init 実行失敗: {e}")
      report["git_init"] = f"failed: {e}"
  else:
    report["git_init"] = "skipped (existing .git/)"

  # --- .gitignore コピー ---
  dest_gitignore = os.path.join(target_path, ".gitignore")
  if not os.path.exists(dest_gitignore):
    try:
      shutil.copy2(tmpl_gitignore, dest_gitignore)
      report["gitignore"] = "copied"
    except Exception as e:
      print(f"[WARN] .gitignore コピー失敗: {e}")
      report["gitignore"] = f"failed: {e}"
  else:
    report["gitignore"] = "skipped (existing .gitignore)"
    report["skipped"].append({"item": ".gitignore", "reason": "既存ファイルを保護"})

  # --- シンボリックリンク作成 ---
  rw_src = os.path.join(DEV_ROOT, "scripts", "rw_light.py")
  rw_link = os.path.join(target_path, "scripts", "rw")

  # rw_light.py に実行権限を付与
  try:
    current_mode = os.stat(rw_src).st_mode
    if not (current_mode & 0o111):
      os.chmod(rw_src, current_mode | 0o755)
  except Exception as e:
    print(f"[WARN] rw_light.py の実行権限付与失敗: {e}")

  # 既存リンクは削除して再作成
  if os.path.islink(rw_link):
    try:
      os.remove(rw_link)
    except Exception as e:
      print(f"[WARN] 既存シンボリックリンク削除失敗: {e}")

  try:
    os.symlink(rw_src, rw_link)
    report["symlink"] = f"created: {rw_link} -> {rw_src}"
  except Exception as e:
    print(f"[WARN] シンボリックリンク作成失敗: {e}")
    print(f"[INFO] 手動で作成するには: ln -s {rw_src} {rw_link}")
    report["symlink"] = f"failed: {e}"

  # --- 完了レポート出力 ---
  print("\n=== rw init 完了レポート ===")
  print(f"対象: {report['target']}")
  print(f"ディレクトリ生成: {report['dirs_created']} 個")
  print(f"テンプレートコピー: {', '.join(report['templates_copied']) or 'なし'}")
  print(f"Git初期化: {report.get('git_init', 'N/A')}")
  print(f".gitignore: {report.get('gitignore', 'N/A')}")
  print(f"シンボリックリンク: {report.get('symlink', 'N/A')}")
  if report["skipped"]:
    print("スキップ項目:")
    for s in report["skipped"]:
      print(f"  - {s['item']}: {s['reason']}")
  print("===========================")

  return 0


# -------------------------
# main
# -------------------------
def print_usage() -> None:
    print("Usage: rw [lint|ingest|synthesize-logs|approve|init|query]")
    print("       rw lint")
    print("       rw lint query [--path review/query/<query_id>] [--strict] [--format text|json]")
    print("       rw init [<path>]")
    print("       rw query <subcommand>")
    print('           extract "<question>" [--scope <page>] [--type <query_type>]')
    print('           answer  "<question>" [--scope <page>]')
    print("           fix     <query_id>")


def main() -> None:
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    cmd = sys.argv[1]

    try:
        if cmd == "lint":
            if len(sys.argv) >= 3 and sys.argv[2] == "query":
                sys.exit(cmd_lint_query(sys.argv[3:]))
            sys.exit(cmd_lint())
        if cmd == "ingest":
            sys.exit(cmd_ingest())
        if cmd == "synthesize-logs":
            sys.exit(cmd_synthesize_logs())
        if cmd == "approve":
            sys.exit(cmd_approve())
        if cmd == "init":
            sys.exit(cmd_init(sys.argv[2:]))

        if cmd == "query":
            if len(sys.argv) < 3:
                print_usage()
                sys.exit(1)
            subcmd = sys.argv[2]
            if subcmd == "extract":
                sys.exit(cmd_query_extract(sys.argv[3:]))
            elif subcmd == "answer":
                sys.exit(cmd_query_answer(sys.argv[3:]))
            elif subcmd == "fix":
                sys.exit(cmd_query_fix(sys.argv[3:]))
            else:
                print(f"Unknown query subcommand: {subcmd}")
                print_usage()
                sys.exit(1)

        print_usage()
        sys.exit(1)
    except FileNotFoundError as e:
        print(f"[FAIL] {e}")
        sys.exit(1)
    except RuntimeError as e:
        print(f"[FAIL] {e}")
        sys.exit(1)
    except ValueError as e:
        print(f"[FAIL] {e}")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"[FAIL] command failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
