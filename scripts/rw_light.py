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
from typing import Any, NamedTuple

import rw_config
import rw_prompt_engine
import rw_utils


# -------------------------
# lint
# -------------------------
def cmd_lint() -> int:
    rw_utils.ensure_dirs()
    files = rw_utils.list_md_files(rw_config.INCOMING)

    results = []
    severity_counts: dict[str, int] = {"critical": 0, "error": 0, "warn": 0, "info": 0}
    pass_count = 0
    fail_count = 0

    for path in files:
        entry: dict = {
            "path": rw_utils.relpath(path),
            "status": "PASS",
            "checks": [],
            "fixes": [],
        }

        raw = rw_utils.read_text(path)
        if len(raw.strip()) == 0:
            entry["checks"].append({"severity": "ERROR", "message": "empty file"})
            entry["status"] = "FAIL"
            severity_counts["error"] += 1
            fail_count += 1
            results.append(entry)
            print(f"[FAIL] {entry['path']} empty file")
            continue

        _, fixes, new_text = rw_utils.ensure_basic_frontmatter(path, rw_utils.infer_source_from_path(path))
        entry["fixes"].extend(fixes)

        if len(new_text.strip()) < 80:
            entry["checks"].append({"severity": "WARN", "message": "too short"})
            severity_counts["warn"] += 1
            print(f"[WARN] {entry['path']} too short")
        else:
            print(f"[PASS] {entry['path']}")

        pass_count += 1
        results.append(entry)

    summary = {
        "pass": pass_count,
        "fail": fail_count,
        "severity_counts": severity_counts,
    }
    run_status = "FAIL" if fail_count > 0 else "PASS"

    payload = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "status": run_status,
        "files": results,
        "summary": summary,
        "drift_events": [],
    }

    rw_utils.write_text(rw_config.LINT_LOG, json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
    sc = severity_counts
    print(
      f"\nlint: CRITICAL {sc['critical']}, ERROR {sc['error']},"
      f" WARN {sc['warn']}, INFO {sc['info']} — {run_status}"
    )
    print(f"Log: {rw_utils.relpath(rw_config.LINT_LOG)}")

    return rw_utils._compute_exit_code(run_status, had_runtime_error=False)


# -------------------------
# ingest
# -------------------------
def load_lint_summary() -> dict[str, Any]:
    if not os.path.exists(rw_config.LINT_LOG):
        raise FileNotFoundError("lint log not found. run `rw lint` first.")
    return json.loads(rw_utils.read_text(rw_config.LINT_LOG))


def plan_ingest_moves(files: list[str]) -> list[tuple[str, str]]:
    moves: list[tuple[str, str]] = []
    for path in files:
        relative = os.path.relpath(path, rw_config.INCOMING)
        target = os.path.join(rw_config.RAW, relative)
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
    rw_utils.ensure_dirs()
    lint_result = load_lint_summary()
    top_status = lint_result.get("status")
    has_fail = lint_result["summary"]["fail"] > 0 or top_status not in {None, "PASS"}
    if has_fail:
        print("FAIL exists in lint_latest.json. abort ingest.", file=sys.stderr)
        return 1

    files = rw_utils.list_md_files(rw_config.INCOMING)
    if not files:
        print("No files found in raw/incoming/")
        return 0

    moves = plan_ingest_moves(files)

    for src, _ in moves:
        print(f"[MOVE] {rw_utils.relpath(src)}")

    execute_ingest_moves(moves)

    try:
        rw_utils.git_commit(["raw/"], "ingest: batch import")
    except subprocess.CalledProcessError as e:
        print(f"[FAIL] git commit failed: {e}")
        return 1

    print("[DONE] ingest completed")
    return 0


# -------------------------
# synthesize-logs
# -------------------------
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

    return rw_utils.build_frontmatter({
        "title": title,
        "source": source_rel,
        "type": "synthesis_candidate",
        "status": "pending",
        "reviewed_by": "",
        "created": rw_utils.today(),
        "updated": rw_utils.today(),
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
    return os.path.join(rw_config.SYNTH_CANDIDATES, f"{rw_utils.slugify(title)}.md")


def cmd_synthesize_logs() -> int:
    rw_utils.ensure_dirs()
    rw_utils.warn_if_dirty_paths(["raw/llm_logs"], "synthesize-logs")

    log_files = rw_utils.list_md_files(rw_config.LLM_LOGS)
    if not log_files:
        print("No llm logs found in raw/llm_logs/")
        return 0

    generated: list[str] = []

    for log_path in log_files:
        print(f"[READ] {rw_utils.relpath(log_path)}")
        try:
            output = rw_prompt_engine.call_claude_for_log_synthesis(log_path)
            topics = parse_topics(output)
        except Exception as e:
            print(f"[FAIL] {rw_utils.relpath(log_path)}: {e}")
            continue

        for topic in topics:
            path = candidate_note_path(str(topic.get("title", "Untitled")))
            if os.path.exists(path):
                print(f"[SKIP] existing candidate: {rw_utils.relpath(path)}")
                continue
            note = render_candidate_note(topic, rw_utils.relpath(log_path))
            rw_utils.write_text(path, note)
            generated.append(rw_utils.relpath(path))
            print(f"[CANDIDATE] {rw_utils.relpath(path)}")

    if generated:
        if not os.path.exists(rw_config.CHANGE_LOG_MD):
            rw_utils.write_text(rw_config.CHANGE_LOG_MD, "# Log\n")
        body = f"\n## {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        for g in generated:
            body += f"- synthesis candidate generated: {g}\n"
        rw_utils.append_text(rw_config.CHANGE_LOG_MD, body)

    print(f"[DONE] generated {len(generated)} candidate notes")
    return 0


# -------------------------
# approve
# -------------------------
def candidate_files() -> list[str]:
    return rw_utils.list_md_files(rw_config.SYNTH_CANDIDATES)


def approved_candidate_files() -> list[str]:
    approved_paths: list[str] = []
    for path in candidate_files():
        text = rw_utils.read_text(path)
        meta, _ = rw_utils.parse_frontmatter(text)

        if (
            meta.get("status") == "approved"
            and bool(str(meta.get("reviewed_by", "")).strip())
            and rw_utils.is_valid_iso_date(str(meta.get("approved", "")).strip())
            and str(meta.get("promoted", "")).lower() != "true"
        ):
            approved_paths.append(path)

    return approved_paths


def synthesis_target_path(title: str) -> str:
    return os.path.join(rw_config.WIKI_SYNTH, f"{rw_utils.slugify(title)}.md")


def merge_synthesis(existing_path: str, new_meta: dict[str, str], new_body: str) -> None:
    old_text = rw_utils.read_text(existing_path)
    old_meta, old_body = rw_utils.parse_frontmatter(old_text)

    old_meta["updated"] = rw_utils.today()
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
        rw_utils.build_frontmatter(old_meta)
        + "\n"
        + old_body.rstrip()
        + f"\n\n---\n\n## Update {rw_utils.today()}\n"
        + new_body.strip()
        + "\n"
    )
    rw_utils.write_text(existing_path, merged)


def promote_candidate(path: str) -> tuple[str, str]:
    text = rw_utils.read_text(path)
    meta, body = rw_utils.parse_frontmatter(text)

    title = meta.get("title", Path(path).stem)
    target = synthesis_target_path(title)

    promoted_meta = dict(meta)
    promoted_meta["type"] = "synthesis"
    promoted_meta["updated"] = rw_utils.today()
    promoted_meta["candidate_source"] = rw_utils.relpath(path)

    promoted_text = rw_utils.build_frontmatter(promoted_meta) + "\n" + body.strip() + "\n"

    if os.path.exists(target):
        merge_synthesis(target, promoted_meta, body)
        return "merged", rw_utils.relpath(target)

    rw_utils.write_text(target, promoted_text)
    return "created", rw_utils.relpath(target)


def mark_candidate_promoted(path: str, target: str) -> None:
    text = rw_utils.read_text(path)
    meta, body = rw_utils.parse_frontmatter(text)

    meta["promoted"] = "true"
    meta["promoted_at"] = rw_utils.today()
    meta["promoted_to"] = target
    meta["updated"] = rw_utils.today()

    rw_utils.write_text(path, rw_utils.build_frontmatter(meta) + "\n" + body.strip() + "\n")


def update_index_synthesis() -> None:
    parent = os.path.dirname(rw_config.INDEX_MD)
    if parent:
        os.makedirs(parent, exist_ok=True)
    if not os.path.exists(rw_config.INDEX_MD):
        rw_utils.write_text(rw_config.INDEX_MD, "# Index\n")

    files = rw_utils.list_md_files(rw_config.WIKI_SYNTH)
    lines = ["## synthesis\n"]
    for path in sorted(files):
        name = Path(path).stem
        lines.append(f"- [[{name}]]\n")
    new_section = "".join(lines)

    current = rw_utils.read_text(rw_config.INDEX_MD)
    if "## synthesis" in current:
        current = re.sub(r"## synthesis[\s\S]*?(?=\n## |\Z)", new_section.rstrip() + "\n", current)
    else:
        if not current.endswith("\n"):
            current += "\n"
        current += "\n" + new_section

    rw_utils.write_text(rw_config.INDEX_MD, current)


def append_approval_log(entries: list[str]) -> None:
    if not os.path.exists(rw_config.CHANGE_LOG_MD):
        rw_utils.write_text(rw_config.CHANGE_LOG_MD, "# Log\n")

    stamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    body = f"\n## {stamp}\n"
    for entry in entries:
        body += f"- {entry}\n"
    rw_utils.append_text(rw_config.CHANGE_LOG_MD, body)


def cmd_approve() -> int:
    rw_utils.ensure_dirs()
    rw_utils.warn_if_dirty_paths(["review/synthesis_candidates"], "approve")

    files = approved_candidate_files()
    if not files:
        print("No approved synthesis candidates found.")
        return 0

    entries: list[str] = []

    for path in files:
        print(f"[APPROVE] {rw_utils.relpath(path)}")
        action, target_rel = promote_candidate(path)
        mark_candidate_promoted(path, target_rel)
        entries.append(f"{action} synthesis: {target_rel} from {rw_utils.relpath(path)}")

    update_index_synthesis()
    append_approval_log(entries)

    print(f"[DONE] approved {len(files)} candidate(s)")
    return 0


def get_recent_wiki_changes() -> list[str]:
    """git diff で最近更新された wiki ページのファイルパスリストを返す。
    グローバル定数 rw_config.WIKI を使用。内部で rw_utils._git_list_files() を呼び出す。

    検出方法:
    1. 未コミット変更: git diff --name-only -- wiki/
       + git ls-files --others -- wiki/
    2. 直近コミットの変更: git diff --name-only HEAD~1..HEAD -- wiki/
       - HEAD~1 が存在しない場合（初回コミット）: git diff --name-only --diff-filter=A HEAD -- wiki/
         で HEAD の全追加ファイルを対象とする
    3. 1 と 2 の和集合から重複を除去
    4. 削除されたファイルを除外（os.path.isfile() で存在確認）
    5. .md ファイルのみにフィルタリング

    Returns:
        wiki/ 配下の .md ファイルパスリスト。
        git リポジトリでない場合は空リストを返す。
    """
    wiki_rel = os.path.relpath(rw_config.WIKI, os.getcwd()) if os.path.isabs(rw_config.WIKI) else rw_config.WIKI

    # 1. 未コミット変更（ステージ済み・未ステージ・untracked）
    uncommitted: list[str] = []
    uncommitted += rw_utils._git_list_files(["diff", "--name-only", "--", wiki_rel + "/"])
    uncommitted += rw_utils._git_list_files(["diff", "--cached", "--name-only", "--", wiki_rel + "/"])
    uncommitted += rw_utils._git_list_files(["ls-files", "--others", "--exclude-standard", "--", wiki_rel + "/"])

    # 2. 直近コミットの変更（HEAD~1..HEAD）
    last_commit = rw_utils._git_list_files(["diff", "--name-only", "HEAD~1..HEAD", "--", wiki_rel + "/"])
    if not last_commit:
        # HEAD~1 が存在しない場合（初回コミット）はフォールバック
        last_commit = rw_utils._git_list_files(["diff", "--name-only", "--diff-filter=A", "HEAD", "--", wiki_rel + "/"])

    # 3. 和集合（重複除去）
    all_files_set: set[str] = set()
    for path in uncommitted + last_commit:
        # パスが絶対パスでない場合はプロジェクトルート基準で解決
        if not os.path.isabs(path):
            abs_path = os.path.join(os.getcwd(), path)
        else:
            abs_path = path
        all_files_set.add(abs_path)

    # 4. 削除ファイル除外 + 5. .md フィルタ
    result: list[str] = [
        p for p in sorted(all_files_set)
        if os.path.isfile(p) and p.endswith(".md")
    ]
    return result


def validate_wiki_dir() -> bool:
    """wiki/ ディレクトリの事前検証を行う。グローバル定数 rw_config.WIKI を使用。

    検証項目:
    - wiki/ ディレクトリの存在（Req 7.1）— 不在時はエラーメッセージ表示
    - wiki/ 内の .md ファイルの存在（Req 7.1）— 不在時はエラーメッセージ表示
    - Git working tree の dirty チェック（Req 7.6）— dirty 時は警告表示

    Returns:
        True: 検証パス（続行可能）, False: 検証失敗（呼び出し元が exit 1）
    """
    if not os.path.isdir(rw_config.WIKI):
        print(f"[ERROR] wiki/ ディレクトリが見つかりません: {rw_config.WIKI}")
        return False

    md_files = rw_utils.list_md_files(rw_config.WIKI)
    if not md_files:
        print(f"[ERROR] wiki/ に .md ファイルが存在しません: {rw_config.WIKI}")
        return False

    rw_utils.warn_if_dirty_paths(["wiki"], "audit")
    return True


def load_wiki_pages(wiki_dir: str, target_files: list[str] | None = None) -> list["WikiPage"]:
    """wiki/ 内の .md ファイルを読み込んで WikiPage リストを返す。

    Args:
        wiki_dir: wiki ディレクトリパス（グローバル定数 rw_config.WIKI）
        target_files: 指定時はそのファイルのみ読み込む（micro 用）。
                      None の場合は全 .md ファイルを読み込む（weekly 用）。
    Returns:
        WikiPage のリスト。読み込みエラーのファイルも read_error 付きで含む。
    """
    LINK_RE = re.compile(r"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]")

    if target_files is not None:
        files = [f for f in target_files if f.endswith(".md")]
    else:
        files = rw_utils.list_md_files(wiki_dir)

    pages: list[WikiPage] = []
    for file_path in files:
        # wiki/ からの相対パス（wiki/ プレフィックスなし）
        rel = os.path.relpath(file_path, wiki_dir)
        filename = os.path.basename(file_path)

        try:
            raw_text = rw_utils.read_text(file_path)
            frontmatter, body = rw_utils.parse_frontmatter(raw_text)
            links = LINK_RE.findall(body)
            pages.append(WikiPage(
                path=rel,
                filename=filename,
                raw_text=raw_text,
                frontmatter=frontmatter,
                body=body,
                links=links,
                read_error="",
            ))
        except (OSError, UnicodeDecodeError) as e:
            pages.append(WikiPage(
                path=rel,
                filename=filename,
                raw_text="",
                frontmatter={},
                body="",
                links=[],
                read_error=str(e),
            ))

    return pages


class Finding(NamedTuple):
    """監査で検出された個別の問題。"""
    severity: str      # "CRITICAL" | "ERROR" | "WARN" | "INFO"
    category: str      # チェックカテゴリ（例: "broken_link", "orphan_page"）
    page: str          # 対象ページパス（wiki/ からの相対パス）
    message: str       # 問題の説明
    marker: str        # monthly のマーカー（"CONFLICT" | "TENSION" | "AMBIGUOUS" | ""）


class WikiPage(NamedTuple):
    """wiki ページの読み込み済みデータ。"""
    path: str                  # wiki/ からの相対パス（例: "concepts/my-page.md"）
    filename: str              # ファイル名（例: "my-page.md"）
    raw_text: str              # 読み込んだ生テキスト（frontmatter 検査用）
    frontmatter: dict          # rw_utils.parse_frontmatter() でパース済み frontmatter
    body: str                  # rw_utils.parse_frontmatter() が返す本文
    links: list                # body から [[link]] regex で抽出したページ名リスト
    read_error: str            # 読み込みエラーがあった場合のメッセージ（正常時は ""）


# audit: static checks — micro


def _resolve_link(link_name: str, all_pages_set: set[str]) -> bool:
    """リンク名を all_pages_set と照合して解決可能かを返す。

    リンク解決ルール:
    1. link_name に .md がなければ付加する
    2. all_pages_set 内でファイル名部分が一致するエントリを検索
    3. 1件以上一致 → 解決成功（True）、0件 → False
    """
    # 拡張子がなければ付加
    if not link_name.endswith(".md"):
        target = link_name + ".md"
    else:
        target = link_name

    # ファイル名部分（basename）で一致検索
    target_basename = os.path.basename(target)
    for entry in all_pages_set:
        if os.path.basename(entry) == target_basename:
            return True
    return False


def check_broken_links(pages: list["WikiPage"], all_pages_set: set[str]) -> list["Finding"]:
    """wiki 内 [[link]] の参照先ページ不在を検出する。Severity: ERROR

    pages 内の各ページの links を all_pages_set と照合する。
    リンク解決はリンク解決ルールに従う。
    """
    findings: list[Finding] = []
    for page in pages:
        for link_name in page.links:
            if not _resolve_link(link_name, all_pages_set):
                findings.append(Finding(
                    severity="ERROR",
                    category="broken_link",
                    page=page.path,
                    message=f"[[{link_name}]] のリンク先が存在しない",
                    marker="",
                ))
    return findings


def check_index_registration(pages: list["WikiPage"], index_content: "str | None") -> list["Finding"]:
    """Vault ルート直下の index.md に未登録のページを検出する。
    index.md 不在時はチェックをスキップし WARNING を Finding として返す（Req 7.7）。

    Severity: WARN
    """
    if index_content is None:
        return [Finding(
            severity="WARN",
            category="index_missing",
            page="",
            message="index.md が存在しないため index 登録チェックをスキップします",
            marker="",
        )]

    # index.md から [[link]] を抽出
    LINK_RE = re.compile(r"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]")
    raw_index_links = LINK_RE.findall(index_content)

    # index_links を解決可能なファイル名セットに変換（basename）
    index_basenames: set[str] = set()
    for link_name in raw_index_links:
        if not link_name.endswith(".md"):
            link_name = link_name + ".md"
        index_basenames.add(os.path.basename(link_name))

    findings: list[Finding] = []
    for page in pages:
        page_basename = os.path.basename(page.path)
        if page_basename not in index_basenames:
            findings.append(Finding(
                severity="WARN",
                category="index_missing",
                page=page.path,
                message=f"index.md に未登録",
                marker="",
            ))
    return findings


def check_frontmatter(pages: list["WikiPage"]) -> list["Finding"]:
    """frontmatter の構造的問題を検出する。

    検出対象:
    1. `---` ブロックが存在するが中身が完全に空 → ERROR
    2. `---` ブロック内に `:` を含まない行が存在する → ERROR
    3. `---` の開始はあるが閉じがない → ERROR
    4. title フィールドの欠落 → WARN

    frontmatter なし時: 1-3 はスキップ、4 のみ適用。
    """
    findings: list[Finding] = []

    for page in pages:
        raw = page.raw_text

        if rw_utils.has_frontmatter(raw):
            # frontmatter ブロックの構造解析
            parts = raw.split("---", 2)
            if len(parts) < 3:
                # 閉じ --- がない（未閉じ frontmatter）
                findings.append(Finding(
                    severity="ERROR",
                    category="frontmatter_error",
                    page=page.path,
                    message="frontmatter の閉じ `---` がない（未閉じ frontmatter）",
                    marker="",
                ))
            else:
                raw_meta = parts[1].strip()
                if not raw_meta:
                    # 空ブロック
                    findings.append(Finding(
                        severity="ERROR",
                        category="frontmatter_error",
                        page=page.path,
                        message="frontmatter ブロックが空",
                        marker="",
                    ))
                else:
                    # 各行を検査: `:` を含まない行は不正
                    for line in raw_meta.splitlines():
                        line = line.strip()
                        if line and ":" not in line:
                            findings.append(Finding(
                                severity="ERROR",
                                category="frontmatter_error",
                                page=page.path,
                                message=f"frontmatter に不正な行がある: `{line}`",
                                marker="",
                            ))
                            break

        # title 欠落チェック（frontmatter の有無に関わらず適用）
        if not page.frontmatter.get("title"):
            findings.append(Finding(
                severity="WARN",
                category="frontmatter_warn",
                page=page.path,
                message="title フィールドが欠落",
                marker="",
            ))

    return findings


def run_micro_checks(
    pages: list["WikiPage"],
    all_pages_set: set[str],
    index_content: "str | None",
) -> list["Finding"]:
    """micro チェック項目（broken_links, index_registration, frontmatter）を実行する。

    read_error が設定された WikiPage は ERROR Finding として記録し、
    個別チェックからは除外する。
    """
    findings: list[Finding] = []

    # read_error のあるページを分離
    ok_pages: list[WikiPage] = []
    for page in pages:
        if page.read_error:
            findings.append(Finding(
                severity="ERROR",
                category="read_error",
                page=page.path,
                message=f"ファイル読み込みエラー: {page.read_error}",
                marker="",
            ))
        else:
            ok_pages.append(page)

    if not ok_pages:
        # ok_pages が空の場合、index チェックのみ（None なら WARNING）
        if index_content is None:
            findings.extend(check_index_registration([], index_content))
        return findings

    findings.extend(check_broken_links(ok_pages, all_pages_set))
    findings.extend(check_index_registration(ok_pages, index_content))
    findings.extend(check_frontmatter(ok_pages))

    return findings


# audit: static checks — weekly


def check_orphan_pages(
    pages: list["WikiPage"],
    index_links: set[str],
) -> list["Finding"]:
    """孤立ページ（他ページからリンクされていない。index.md リンクは除外）を検出する。

    判定: pages 内の全ページから被リンク集合を構築し、
    どのページの links にも含まれず、かつ index_links にも含まれないページを孤立と判定。

    除外: ファイル名が "index.md" のページは孤立チェックから除外する。
    Severity: WARN
    """
    # 被リンク集合を構築（basename で正規化）
    inbound_basenames: set[str] = set()
    for page in pages:
        for link_name in page.links:
            if not link_name.endswith(".md"):
                link_name = link_name + ".md"
            inbound_basenames.add(os.path.basename(link_name))

    # index_links も basename で正規化
    index_basenames: set[str] = set()
    for link_name in index_links:
        if not link_name.endswith(".md"):
            link_name = link_name + ".md"
        index_basenames.add(os.path.basename(link_name))

    findings: list[Finding] = []
    for page in pages:
        # ファイル名が "index.md" のページは除外
        if page.filename == "index.md":
            continue
        page_basename = os.path.basename(page.path)
        if page_basename not in inbound_basenames and page_basename not in index_basenames:
            findings.append(Finding(
                severity="WARN",
                category="orphan_page",
                page=page.path,
                message="他のページからリンクされていない",
                marker="",
            ))
    return findings


def check_bidirectional_links(
    pages: list["WikiPage"],
    all_pages_set: set[str],
) -> "tuple[list[Finding], dict[str, int]]":
    """双方向リンクの欠落を検出する。Severity: WARN

    定義: ページ A が [[B]] でリンクしているとき、ページ B にも [[A]] へのリンクが
    存在するかを検査する。全リンクペアに対してチェックし、片方向のみのペアを報告する。

    注意: index.md からのリンクは双方向チェックの対象外とする。

    Returns:
        (findings, stats) のタプル。
        stats: {"total_pairs": int, "bidirectional_pairs": int}
    """
    # basename → path のマッピング（リンク解決用）
    basename_to_path: dict[str, str] = {}
    for entry in all_pages_set:
        basename_to_path[os.path.basename(entry)] = entry

    # ページ path → links の basename セット（高速参照用）
    page_links_map: dict[str, set[str]] = {}
    for page in pages:
        link_basenames: set[str] = set()
        for link_name in page.links:
            if not link_name.endswith(".md"):
                link_name = link_name + ".md"
            link_basenames.add(os.path.basename(link_name))
        page_links_map[os.path.basename(page.path)] = link_basenames

    # 有向リンクペアを収集（index.md 発信リンクは除外）
    # 処理済みペアを追跡（{frozenset(a, b)} で重複防止）
    checked_pairs: set[frozenset] = set()
    findings: list[Finding] = []
    total_pairs = 0
    bidirectional_pairs = 0

    for page in pages:
        # index.md からのリンクは除外
        if page.filename == "index.md":
            continue
        page_basename = os.path.basename(page.path)
        for link_name in page.links:
            if not link_name.endswith(".md"):
                link_name = link_name + ".md"
            target_basename = os.path.basename(link_name)

            # 自己参照はスキップ
            if target_basename == page_basename:
                continue
            # all_pages_set に存在しないリンクはスキップ（broken link は別チェック）
            if target_basename not in basename_to_path:
                continue
            # index.md へのリンクはスキップ（index.md 発信を除外しているので対称）
            if target_basename == "index.md":
                continue

            pair = frozenset([page_basename, target_basename])
            if pair in checked_pairs:
                continue
            checked_pairs.add(pair)

            total_pairs += 1
            # 逆方向リンクを確認
            target_links = page_links_map.get(target_basename, set())
            if page_basename in target_links:
                bidirectional_pairs += 1
            else:
                findings.append(Finding(
                    severity="WARN",
                    category="missing_backlink",
                    page=page.path,
                    message=f"[[{link_name.replace('.md', '')}]] への逆リンクが欠落",
                    marker="",
                ))

    stats = {"total_pairs": total_pairs, "bidirectional_pairs": bidirectional_pairs}
    return findings, stats


def check_naming_convention(pages: list["WikiPage"]) -> list["Finding"]:
    """命名規則違反（小文字・ハイフン区切り・ASCII のみ）を検出する。Severity: WARN

    regex: ^[a-z0-9]+(-[a-z0-9]+)*\\.md$ にマッチしないファイルを違反として報告。
    """
    NAMING_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*\.md$")
    findings: list[Finding] = []
    for page in pages:
        if not NAMING_RE.match(page.filename):
            findings.append(Finding(
                severity="WARN",
                category="naming_violation",
                page=page.path,
                message=f"命名規則違反: `{page.filename}` は小文字・ハイフン区切り・ASCII のみを使用してください",
                marker="",
            ))
    return findings


def check_source_field(pages: list["WikiPage"]) -> list["Finding"]:
    """source: フィールドの空・欠落を検出する。Severity: INFO"""
    findings: list[Finding] = []
    for page in pages:
        source_val = page.frontmatter.get("source", None)
        if source_val is None or source_val == "":
            findings.append(Finding(
                severity="INFO",
                category="missing_source",
                page=page.path,
                message="source フィールドが空または欠落",
                marker="",
            ))
    return findings


def check_required_sections(
    pages: list["WikiPage"],
    page_policy: "dict | None",
) -> list["Finding"]:
    """page_policy.md の必須セクション定義に基づく欠落を検出する。

    現行の page_policy.md には具体的な必須セクション名の定義がないため no-op。
    将来の拡張構造のみ用意する。
    """
    # 現行 page_policy.md は必須セクション定義なし → no-op
    return []


def run_weekly_checks(
    pages: list["WikiPage"],
    all_pages_set: set[str],
    index_content: "str | None",
    index_links: set[str],
    page_policy: "dict | None",
) -> "tuple[list[Finding], dict]":
    """weekly 固有チェック項目（orphan, bidirectional, naming, source, required_sections）を実行する。

    Returns:
        (findings, metrics_stats) のタプル。
        findings: 全 weekly チェックの Finding リスト
        metrics_stats: {"total_pairs": int, "bidirectional_pairs": int}
    """
    findings: list[Finding] = []

    findings.extend(check_orphan_pages(pages, index_links))

    bidir_findings, bidir_stats = check_bidirectional_links(pages, all_pages_set)
    findings.extend(bidir_findings)

    findings.extend(check_naming_convention(pages))
    findings.extend(check_source_field(pages))
    findings.extend(check_required_sections(pages, page_policy))

    return findings, bidir_stats


# audit: LLM engine


def _normalize_severity_token(
  token,
  *,
  source_context: dict | None = None,
  drift_sink: list | None = None,
) -> str:
  """severity トークンを正規化する。

  新 4 水準（CRITICAL/ERROR/WARN/INFO）はそのまま返す。
  それ以外は INFO に降格し、drift_sink に記録、stderr に警告を出力する。

  Args:
      token: 正規化対象のトークン（str 以外も受け付け、drift 扱い）
      source_context: {"context": str, "source_field": str, "location": str}
          欠落キーは空文字列で補完される
      drift_sink: drift エントリを追記するリスト（None の場合は追記しない）

  Returns:
      正規化後の severity 文字列（"CRITICAL" | "ERROR" | "WARN" | "INFO"）
  """
  # source_context からのキー取得（欠落は空文字補完）
  ctx: dict = source_context or {}
  ctx_str = ctx.get("context", "") or ""
  source_field = ctx.get("source_field", "") or ""
  location = ctx.get("location", "") or ""

  # 非 str の場合は文字列化し drift 扱い
  if not isinstance(token, str):
    raw_str = str(token) if token is not None else ""
    sanitized = "".join(c for c in raw_str[:40] if c.isprintable() and ord(c) < 128)
    _record_drift(raw_str, sanitized, ctx_str, source_field, location, drift_sink)
    return "INFO"

  # 前処理: strip + upper
  normalized = token.strip().upper()

  # 有効な 4 水準ならそのまま返す
  if normalized in rw_config._VALID_SEVERITIES:
    return normalized

  # drift 処理: sanitize して記録・降格
  sanitized = "".join(c for c in token[:40] if c.isprintable() and ord(c) < 128)
  _record_drift(token, sanitized, ctx_str, source_field, location, drift_sink)
  return "INFO"


def _record_drift(
  original_token: str,
  sanitized_token: str,
  context: str,
  source_field: str,
  location: str,
  drift_sink: list | None,
) -> None:
  """drift イベントを stderr に出力し drift_sink に追記する。"""
  import sys

  # 4 行形式の stderr 出力（AC 1.9）
  ctx_display = context or "(unknown)"
  print(
    f"[severity-drift] unknown token in {ctx_display}: {sanitized_token}\n"
    f"  - source: {source_field}\n"
    f"  - related location: {location}\n"
    f"  - demoted to: INFO",
    file=sys.stderr,
  )

  if drift_sink is not None:
    drift_sink.append({
      "original_token": original_token,
      "sanitized_token": sanitized_token,
      "demoted_to": "INFO",
      "source_field": source_field,
      "context": context,
    })


def build_audit_prompt(tier: str, task_prompts: str, wiki_content: str) -> str:
  """audit 用プロンプトを構築する。

  Args:
      tier: "monthly" | "quarterly"
      task_prompts: rw_prompt_engine.load_task_prompts("audit") で読み込んだプロンプト文字列
      wiki_content: rw_prompt_engine.read_all_wiki_content() で取得した wiki 全文
  Returns:
      Claude CLI に渡すプロンプト文字列

  プロンプト構成（既存 rw_prompt_engine.build_query_prompt() パターンに準拠）:
  1. タスクプロンプト（AGENTS/audit.md + ポリシー）
  2. ティア指示 + フォーマットオーバーライド + Execution Declaration 抑制
  3. wiki コンテンツ（ユーザー提供データ）
  4. 出力形式指示（具体的 JSON サンプル付き）— 必ず最後に配置
  """
  parts: list[str] = []

  # 0. Severity Vocabulary (STRICT) prefix — Req 8.5, 8.6
  severity_vocab_prefix = (
    "## Severity Vocabulary (STRICT)\n\n"
    "Use ONLY these severity tokens: CRITICAL, ERROR, WARN, INFO.\n"
    "Do NOT use deprecated tokens: HIGH, MEDIUM, LOW.\n"
    "Any deviation will be flagged as drift in post-processing.\n\n"
  )
  parts.append(severity_vocab_prefix)

  # 1. タスクプロンプト（AGENTS/audit.md + ポリシー）— Req 10.1
  parts.append(task_prompts)

  # 2. ティア指示 + フォーマットオーバーライド + Execution Declaration 抑制
  if tier == "monthly":
    tier_label = "Tier 2: Semantic Audit"
    exclude_tiers = "Tier 0 (Micro-check), Tier 1 (Structural Audit), Tier 3 (Strategic Audit)"
  else:
    # quarterly
    tier_label = "Tier 3: Strategic Audit"
    exclude_tiers = "Tier 0 (Micro-check), Tier 1 (Structural Audit), Tier 2 (Semantic Audit)"

  tier_instruction = (
    "## 実行指示\n\n"
    f"以下の4ティアのうち、{tier_label} のみを実行してください。\n"
    f"{exclude_tiers} の\n"
    "チェック項目は実行しないでください。Tier 0/1 の構造チェックは CLI が Python で\n"
    "実行済みであり、重複を避ける必要があります。\n\n"
    "注意: AGENTS/audit.md の「出力フォーマット」セクションに定義された Markdown 形式は\n"
    "対話型プロンプト実行用のフォーマットです。CLI モードでは末尾の「出力形式」セクションの\n"
    "JSON スキーマに従って出力してください。Markdown 形式では出力しないでください。\n\n"
    "実行宣言は不要です。JSON のみを出力してください。"
  )
  parts.append(tier_instruction)

  # 3. wiki コンテンツ（ユーザー提供データ）
  parts.append("## Wiki コンテンツ\n\n" + wiki_content)

  # 4. 出力形式指示（JSON サンプル付き）— 必ず末尾に配置（セキュリティ考慮）
  if tier == "monthly":
    schema_sample = {
      "findings": [
        {
          "severity": "HIGH",
          "category": "contradicting_definition",
          "page": "concepts/my-concept.md",
          "message": "page-a.md と page-b.md で定義が矛盾している",
          "marker": "CONFLICT",
          "recommendation": "定義を統一するか、条件分岐を明記する",
        },
        {
          "severity": "MEDIUM",
          "category": "ambiguous_definition",
          "page": "entities/some-tool.md",
          "message": "機能の説明が不十分で解釈が分かれる",
          "marker": "AMBIGUOUS",
          "recommendation": "具体的な使用例を追記する",
        },
      ],
      "metrics": {
        "pages_scanned": 42,
        "total_findings": 2,
        "conflict_count": 1,
        "tension_count": 0,
        "ambiguous_count": 1,
      },
      "recommended_actions": [
        "concepts/my-concept.md の定義を確認する",
        "entities/some-tool.md に使用例を追記する",
      ],
    }
  else:
    # quarterly
    schema_sample = {
      "findings": [
        {
          "severity": "MEDIUM",
          "category": "isolated_cluster",
          "page": None,
          "message": "methods/ 配下のページが concepts/ とほぼクロスリンクされていない",
          "recommendation": "methods の各ページに関連 concept へのリンクを追加する",
        },
        {
          "severity": "LOW",
          "category": "coverage_gap",
          "page": None,
          "message": "concepts に対して synthesis ページが不足している（synthesis/ 全体のカバレッジ不足）",
          "recommendation": "synthesis 候補を review に追加する",
        },
      ],
      "metrics": {
        "pages_scanned": 42,
        "total_findings": 2,
      },
      "recommended_actions": [
        "methods と concepts のクロスリンクを強化する",
        "synthesis ページの充実を検討する",
      ],
    }

  schema_json = json.dumps(schema_sample, ensure_ascii=False, indent=2)
  output_instruction = (
    "## 出力形式\n\n"
    "以下の JSON スキーマに従って、監査結果を JSON 形式で出力してください。\n"
    "コードブロック（```json ... ```）で囲まずに、JSONのみを出力してください。\n\n"
    f"```json\n{schema_json}\n```"
  )
  parts.append(output_instruction)

  return "\n\n".join(parts)


def parse_audit_response(response: str, cmd_context: str = "audit") -> dict:
  """Claude CLI のレスポンスから JSON をパースし、スキーマ検証を行う。

  既存の _strip_code_block() ヘルパーでコードブロックを除去してから
  json.loads() でパース。

  スキーマ検証（プロンプトインジェクション・モデル幻覚への防御）4 段構造:
  1. トップレベル型検証: dict でない場合は RuntimeError（exit 1 相当）
  2. findings key 型検証: list でない場合は ValueError
  3. 各 finding 要素の型検証: dict でない場合は placeholder + drift_events 記録（silent skip 廃止）
  4. 必須 key 欠落検証: severity / message / location 欠落は補完 + drift_events 記録

  severity の値が CRITICAL / ERROR / WARN / INFO（新 4 水準）のいずれかであること。
  旧語彙（HIGH/MEDIUM/LOW 等）は _normalize_severity_token() で drift として記録し、
  INFO に降格して finding を保持する（破棄しない）。

  Args:
      response: Claude CLI のレスポンス文字列（JSON または ```json...``` 形式）
      cmd_context: drift_events の context フィールドに使う呼び出し文脈文字列

  Returns:
      {"findings": [...], "metrics": {...}, "recommended_actions": [...],
       "drift_events": [...]} の dict
      drift_events は severity drift または構造的不正があった場合のみ含まれる（Req 1.9, 7.10）

  Raises:
      RuntimeError: トップレベルが dict でない場合（exit 1 相当）
      ValueError: 不正な JSON またはトップレベルスキーマ違反の場合（findings が list でない等）
  """
  # コードブロック除去 + JSON パース
  try:
    cleaned = _strip_code_block(response)
    data = json.loads(cleaned)
  except json.JSONDecodeError as e:
    raise ValueError(f"audit レスポンスの JSON パースに失敗しました: {e}") from e

  # ステップ 1: トップレベル型検証（非 dict は RuntimeError、Req 1.9 AC (a)）
  if not isinstance(data, dict):
    raise RuntimeError(
      f"audit レスポンスのトップレベルが dict でありません（got {type(data).__name__}）"
    )

  # ステップ 2: findings key 型検証
  if not isinstance(data.get("findings"), list):
    raise ValueError(
      "audit レスポンスに必須フィールドが欠落または型不一致です: findings（list が必要）"
    )
  if not isinstance(data.get("metrics"), dict):
    raise ValueError(
      "audit レスポンスに必須フィールドが欠落または型不一致です: metrics（dict が必要）"
    )
  if not isinstance(data.get("recommended_actions"), list):
    raise ValueError(
      "audit レスポンスに必須フィールドが欠落または型不一致です: recommended_actions（list が必要）"
    )

  # drift イベント収集バッファ（Req 1.9, 7.10）
  drift_events: list[dict] = []

  # ステップ 3-4: finding ごとの検証と変換（silent skip 廃止、配列長保持）
  validated_findings: list[dict] = []
  for i, finding in enumerate(data["findings"]):
    # ステップ 3: finding 要素の型検証（非 dict → placeholder + drift_events 記録）
    if not isinstance(finding, dict):
      drift_events.append({
        "original_token": "<non-dict-finding>",
        "sanitized_token": "<structurally-invalid>",
        "demoted_to": "INFO",
        "source_field": f"findings[{i}]",
        "context": f"expected dict, got {type(finding).__name__}",
      })
      validated_findings.append({
        "severity": "INFO",
        "message": f"[structurally invalid finding at index {i}, see drift_events]",
        "location": "-",
      })
      continue

    # コピーして変換処理（元の dict を破壊しない）
    f = dict(finding)

    # ステップ 4: location 欠落検証 → "-" 補完 + drift_events 記録
    if "location" not in f:
      drift_events.append({
        "original_token": "<missing>",
        "sanitized_token": "<missing>",
        "demoted_to": "-",
        "source_field": f"findings[{i}].<missing-location>",
        "context": cmd_context,
      })
      f["location"] = "-"

    location_val = f.get("location") or "-"

    # ステップ 4: severity 正規化（raw_sev → str coerce → _normalize_severity_token）
    raw_sev = f.get("severity") if "severity" in f else None
    coerced_sev = str(raw_sev) if raw_sev is not None else None
    source_field_sev = (
      f"findings[{i}].severity" if raw_sev is not None else f"findings[{i}].<missing-severity>"
    )
    if raw_sev is None:
      # severity 欠落: drift_events に missing-severity を記録して INFO に補完
      drift_events.append({
        "original_token": "<missing>",
        "sanitized_token": "<missing>",
        "demoted_to": "INFO",
        "source_field": source_field_sev,
        "context": cmd_context,
      })
      f["severity"] = "INFO"
    else:
      severity = _normalize_severity_token(
        coerced_sev,
        source_context={
          "context": cmd_context,
          "source_field": source_field_sev,
          "location": location_val,
        },
        drift_sink=drift_events,
      )
      f["severity"] = severity

    # ステップ 4: message 欠落検証 → 空文字補完 + drift_events 記録
    if "message" not in f:
      drift_events.append({
        "original_token": "<missing>",
        "sanitized_token": "<missing>",
        "demoted_to": "-",
        "source_field": f"findings[{i}].<missing-message>",
        "context": cmd_context,
      })
      f["message"] = ""

    # message の改行→空白置換
    if f.get("message"):
      f["message"] = f["message"].replace("\r\n", " ").replace("\n", " ").replace("\r", " ")

    # null → "" 変換（page, marker）
    if f.get("page") is None:
      f["page"] = ""
    if f.get("marker") is None:
      f["marker"] = ""

    validated_findings.append(f)

  result: dict = {
    "findings": validated_findings,
    "metrics": data["metrics"],
    "recommended_actions": data["recommended_actions"],
  }
  if drift_events:
    result["drift_events"] = drift_events
  return result


# audit: report engine


def generate_audit_report(
  tier: str,
  findings: list,
  metrics: dict,
  recommended_actions=None,
  timestamp=None,
) -> str:
  """Markdown 形式の監査レポートを生成して logs/ に出力する。

  Args:
    tier: "micro" | "weekly" | "monthly" | "quarterly"
    findings: 検出された問題のリスト（Finding NamedTuple）
    metrics: ティア固有のメトリクス dict
    recommended_actions: 推奨アクション（monthly/quarterly は Claude が返す。
                         None の場合（micro/weekly）は findings から自動生成）
    timestamp: ファイル名とレポートヘッダーに使用するタイムスタンプ文字列
               （YYYYMMDD-HHMMSS 形式）。None の場合は datetime.now() から生成。
  Returns:
    生成されたレポートファイルのパス文字列
  """
  if timestamp is None:
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")

  # カウント集計
  critical_count = sum(1 for f in findings if f.severity == "CRITICAL")
  error_count = sum(1 for f in findings if f.severity == "ERROR")
  warn_count = sum(1 for f in findings if f.severity == "WARN")
  info_count = sum(1 for f in findings if f.severity == "INFO")
  status = rw_utils._compute_run_status(findings)

  # Findings セクションのラベル決定
  if tier in ("micro", "weekly"):
    findings_label = "Structural Findings"
  elif tier == "monthly":
    findings_label = "Semantic Findings"
  else:
    findings_label = "Strategic Findings"

  # Recommended Actions の自動生成（micro/weekly: recommended_actions=None の場合）
  if recommended_actions is None:
    # ERROR/WARN の category ごとに集約
    from collections import Counter
    cat_counter: Counter = Counter()
    for f in findings:
      if f.severity in ("ERROR", "WARN"):
        cat_counter[f.category] += 1
    auto_actions = []
    for cat, count in sorted(cat_counter.items()):
      auto_actions.append(
        f"{cat} が {count} 件検出されました。対象ページを確認してください"
      )
    recommended_actions = auto_actions

  # Finding の行フォーマット
  def _format_finding_line(f) -> str:
    sev_tag = f"[{f.severity}]"
    marker_suffix = f" [{f.marker}]" if f.marker else ""
    category_suffix = f" ({f.category})" if f.category else ""
    if f.page:
      return f"- {sev_tag} {f.page}{category_suffix}: {f.message}{marker_suffix}"
    else:
      return f"- {sev_tag}{category_suffix} {f.message}{marker_suffix}"

  # レポート本文を構築
  lines = []
  lines.append(f"# Audit Report: {tier}")
  lines.append("")

  # Summary セクション
  lines.append("## Summary")
  lines.append("")
  lines.append(f"- tier: {tier}")
  lines.append(f"- timestamp: {timestamp}")
  lines.append(f"- CRITICAL: {critical_count}")
  lines.append(f"- ERROR: {error_count}")
  lines.append(f"- WARN: {warn_count}")
  lines.append(f"- INFO: {info_count}")
  lines.append(f"- status: {status}")
  lines.append("")

  # Findings セクション
  lines.append("## Findings")
  lines.append("")
  lines.append(f"### {findings_label}")
  lines.append("")
  if findings:
    for f in findings:
      lines.append(_format_finding_line(f))
  else:
    lines.append("- 問題は検出されませんでした")
  lines.append("")

  # Metrics セクション
  lines.append("## Metrics")
  lines.append("")
  if metrics:
    for key, value in metrics.items():
      lines.append(f"- {key}: {value}")
  else:
    lines.append("- N/A")
  lines.append("")

  # Recommended Actions セクション
  lines.append("## Recommended Actions")
  lines.append("")
  if recommended_actions:
    for action in recommended_actions:
      lines.append(f"- {action}")
  else:
    lines.append("- なし")
  lines.append("")

  content = "\n".join(lines)
  report_path = os.path.join(rw_config.LOGDIR, f"audit-{tier}-{timestamp}.md")
  rw_utils.write_text(report_path, content)
  return report_path


def print_audit_summary(tier: str, findings: list, report_path: str) -> None:
  """標準出力に監査サマリーを表示する。

  表示内容:
  - 各 Finding を [severity] page: message 形式（page="" 時はページ省略）
  - サマリー行: audit {tier}: ERROR N, WARN N, INFO N — PASS/FAIL
  - 最終行にレポートファイルパス
  """
  # 個別 Finding を表示
  for f in findings:
    if f.page:
      print(f"[{f.severity}] {f.page}: {f.message}")
    else:
      print(f"[{f.severity}] {f.message}")

  # カウント集計
  critical_count = sum(1 for f in findings if f.severity == "CRITICAL")
  error_count = sum(1 for f in findings if f.severity == "ERROR")
  warn_count = sum(1 for f in findings if f.severity == "WARN")
  info_count = sum(1 for f in findings if f.severity == "INFO")
  status = rw_utils._compute_run_status(findings)

  print("---")
  print(
    f"audit {tier}: CRITICAL {critical_count}, ERROR {error_count},"
    f" WARN {warn_count}, INFO {info_count} \u2014 {status}"
  )
  print(f"レポート: {report_path}")


# audit: commands — dispatch+micro


def cmd_audit(args: list[str]) -> int:
    """audit サブコマンドのディスパッチ。

    Args:
        args: sys.argv[2:] 以降の引数リスト
    Returns:
        終了コード（0: PASS, 1: FAIL）
    """
    if not args:
        print("Usage: rw audit <subcommand>")
        print("  subcommands: micro, weekly, monthly, quarterly")
        return 1

    subcmd = args[0]
    if subcmd == "micro":
        return cmd_audit_micro()
    elif subcmd == "weekly":
        return cmd_audit_weekly()
    elif subcmd == "monthly":
        return cmd_audit_monthly(args[1:])
    elif subcmd == "quarterly":
        return cmd_audit_quarterly(args[1:])
    else:
        print(f"[ERROR] Unknown audit subcommand: {subcmd}")
        print("Usage: rw audit <subcommand>")
        print("  subcommands: micro, weekly, monthly, quarterly")
        return 1


def cmd_audit_micro() -> int:
    """micro 監査を実行する。グローバル定数 rw_config.ROOT, rw_config.WIKI, rw_config.INDEX_MD を使用。

    Returns:
        終了コード（0: ERROR なし, 1: ERROR あり）
    """
    # 1. wiki/ の事前検証
    if not validate_wiki_dir():
        return 1

    # 2. 対象ファイル取得
    target_files = get_recent_wiki_changes()

    # 3. 対象 0 件の場合
    if not target_files:
        print("[INFO] 変更なし: チェック対象の wiki ページがありません")
        metrics = {
            "pages_scanned": 0,
            "broken_links": 0,
            "index_missing": 0,
            "frontmatter_errors": 0,
            "total_findings": 0,
        }
        report_path = generate_audit_report("micro", [], metrics)
        print_audit_summary("micro", [], report_path)
        return 0

    # 4. WikiPage リスト生成
    pages = load_wiki_pages(rw_config.WIKI, target_files)

    # 5. all_pages_set 構築（全 wiki ページのファイル名セット）
    all_md_files = rw_utils.list_md_files(rw_config.WIKI)
    all_pages_set: set[str] = set()
    for f in all_md_files:
        rel = os.path.relpath(f, rw_config.WIKI)
        all_pages_set.add(rel)

    # 6. index_content 読み込み（不在時は None）
    index_content: str | None = None
    if os.path.isfile(rw_config.INDEX_MD):
        index_content = rw_utils.read_text(rw_config.INDEX_MD)

    # 7. micro チェック実行
    findings = run_micro_checks(pages, all_pages_set, index_content)

    # 8. metrics 算出
    broken_links_count = sum(1 for f in findings if f.category == "broken_link")
    index_missing_count = sum(
        1 for f in findings if f.category == "index_missing" and f.page != ""
    )
    frontmatter_errors_count = sum(1 for f in findings if f.category == "frontmatter_error")
    metrics = {
        "pages_scanned": len(pages),
        "broken_links": broken_links_count,
        "index_missing": index_missing_count,
        "frontmatter_errors": frontmatter_errors_count,
        "total_findings": len(findings),
    }

    # 9. レポート生成
    report_path = generate_audit_report("micro", findings, metrics)

    # 10. サマリー表示
    print_audit_summary("micro", findings, report_path)

    # 11. CRITICAL/ERROR あれば exit 2、なければ exit 0
    return rw_utils._compute_exit_code(rw_utils._compute_run_status(findings), had_runtime_error=False)


# audit: commands — weekly


def cmd_audit_weekly() -> int:
    """weekly 監査を実行する。グローバル定数 rw_config.ROOT, rw_config.WIKI, rw_config.INDEX_MD を使用。

    Returns:
        終了コード（0: ERROR なし, 1: ERROR あり）
    """
    # 1. wiki/ の事前検証
    if not validate_wiki_dir():
        return 1

    # 2. 全ページ読み込み
    pages = load_wiki_pages(rw_config.WIKI, None)

    # 3. all_pages_set 構築
    all_md_files = rw_utils.list_md_files(rw_config.WIKI)
    all_pages_set: set[str] = set()
    for f in all_md_files:
        rel = os.path.relpath(f, rw_config.WIKI)
        all_pages_set.add(rel)

    # 4. index_content 読み込み（rw_config.INDEX_MD 不在時は None）
    index_content: str | None = None
    if os.path.isfile(rw_config.INDEX_MD):
        index_content = rw_utils.read_text(rw_config.INDEX_MD)

    # 5. index_links 構築（index_content から [[link]] regex で抽出、basename のみ）
    index_links: set[str] = set()
    if index_content:
        raw_links = re.findall(r"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]", index_content)
        for link in raw_links:
            basename = os.path.basename(link)
            if not basename.endswith(".md"):
                basename = basename + ".md"
            index_links.add(basename)

    # 6. page_policy=None を渡す（現行 page_policy.md に必須セクション定義なし → no-op）
    page_policy = None

    # 7. micro チェック実行（全ページ対象）
    micro_findings = run_micro_checks(pages, all_pages_set, index_content)

    # 8. ok_pages 構築（read_error のあるページを weekly checks から除外）
    ok_pages = [p for p in pages if not p.read_error]

    # 9. weekly チェック実行
    weekly_findings, bidir_stats = run_weekly_checks(
        ok_pages, all_pages_set, index_content, index_links, page_policy
    )

    # 10. findings 統合（micro + weekly）
    findings = micro_findings + weekly_findings

    # 11. bidirectional_compliance 算出
    total_pairs = bidir_stats.get("total_pairs", 0)
    bidir_pairs = bidir_stats.get("bidirectional_pairs", 0)
    if total_pairs == 0:
        bidirectional_compliance = 100.0
    else:
        bidirectional_compliance = bidir_pairs / total_pairs * 100

    # 12. metrics dict 構築
    broken_links_count = sum(1 for f in findings if f.category == "broken_link")
    index_missing_count = sum(
        1 for f in findings if f.category == "index_missing" and f.page != ""
    )
    frontmatter_errors_count = sum(1 for f in findings if f.category == "frontmatter_error")
    orphan_pages_count = sum(1 for f in findings if f.category == "orphan_page")
    source_missing_count = sum(1 for f in findings if f.category == "missing_source")
    naming_violations_count = sum(1 for f in findings if f.category == "naming_violation")

    metrics = {
        "pages_scanned": len(pages),
        "broken_links": broken_links_count,
        "index_missing": index_missing_count,
        "frontmatter_errors": frontmatter_errors_count,
        "orphan_pages": orphan_pages_count,
        "bidirectional_compliance": f"{bidirectional_compliance:.1f}%",
        "source_missing": source_missing_count,
        "naming_violations": naming_violations_count,
        "total_findings": len(findings),
    }

    # 13. レポート生成
    report_path = generate_audit_report("weekly", findings, metrics)

    # 14. サマリー表示
    print_audit_summary("weekly", findings, report_path)

    # 15. CRITICAL/ERROR あれば exit 2、なければ exit 0
    return rw_utils._compute_exit_code(rw_utils._compute_run_status(findings), had_runtime_error=False)


# audit: commands — monthly/quarterly


def _run_llm_audit(tier: str, args: list[str]) -> int:
  """monthly/quarterly 共通の LLM 監査フローを実行する。
  グローバル定数 rw_config.ROOT, rw_config.WIKI, rw_config.INDEX_MD, rw_config.CLAUDE_MD, rw_config.AGENTS_DIR, rw_config.LOGDIR を使用。

  Args:
      tier: "monthly" | "quarterly"
      args: オプション引数。
          `--timeout <秒>` でタイムアウトをオーバーライド（デフォルト 300）
          `--skip-vault-validation` で vault 語彙検証をスキップする。
          RW_SKIP_VAULT_VALIDATION=1 環境変数でも同等の効果。
  Returns:
      終了コード（0: PASS, 1: FAIL, 2: PASS with drift）
  """
  # 1. args から --timeout と --skip-vault-validation をパース
  drift_events: list[dict] = []
  timeout = 300
  skip_vault_validation = os.environ.get("RW_SKIP_VAULT_VALIDATION") == "1"
  i = 0
  while i < len(args):
    if args[i] == "--timeout" and i + 1 < len(args):
      try:
        timeout = int(args[i + 1])
      except ValueError:
        print(f"[ERROR] --timeout の値が不正です: {args[i + 1]}")
        return 1
      i += 2
    elif args[i] == "--skip-vault-validation":
      skip_vault_validation = True
      i += 1
    else:
      i += 1

  # 2. validate_wiki_dir() → False なら return 1
  if not validate_wiki_dir():
    return 1

  # 3. CLAUDE.md と AGENTS/ の存在確認（Req 7.5）
  if not os.path.isfile(rw_config.CLAUDE_MD):
    print(f"[ERROR] CLAUDE.md が見つかりません: {rw_config.CLAUDE_MD}")
    return 1
  if not os.path.isdir(rw_config.AGENTS_DIR):
    print(f"[ERROR] AGENTS/ ディレクトリが見つかりません: {rw_config.AGENTS_DIR}")
    return 1

  # 4. rw_prompt_engine.load_task_prompts("audit") で AGENTS/audit.md + ポリシーファイルを読み込む
  # skip_vault_validation を渡す（Req 6.5, 7.9）
  try:
    task_prompts = rw_prompt_engine.load_task_prompts("audit", skip_vault_validation=skip_vault_validation)
  except (ValueError, FileNotFoundError) as e:
    print(f"[ERROR] load_task_prompts 失敗: {e}")
    return 1

  # 5. rw_prompt_engine.read_all_wiki_content() で wiki コンテンツ取得
  try:
    wiki_content = rw_prompt_engine.read_all_wiki_content()
  except (FileNotFoundError, ValueError) as e:
    print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
    return 1

  # 6. build_audit_prompt(tier, task_prompts, wiki_content) でプロンプト生成
  prompt = build_audit_prompt(tier, task_prompts, wiki_content)

  # 7. [INFO] {tier} 監査を実行中... を標準出力に表示
  print(f"[INFO] {tier} 監査を実行中...")

  # タイムスタンプ生成（raw ファイル名とレポートで共用）
  ts = datetime.now().strftime("%Y%m%d-%H%M%S")

  # 8. rw_prompt_engine.call_claude(prompt, timeout=timeout) で Claude 呼び出し
  try:
    raw_response = rw_prompt_engine.call_claude(prompt, timeout=timeout)
  except RuntimeError as e:
    print(f"[ERROR] Claude 呼び出し失敗: {e}")
    return 1

  # 9. raw レスポンスを logs/audit-{tier}-{ts}-raw.txt に保存
  raw_path = os.path.join(rw_config.LOGDIR, f"audit-{tier}-{ts}-raw.txt")
  rw_utils.write_text(raw_path, raw_response)

  # 10. parse_audit_response(raw_response) でパース
  try:
    data = parse_audit_response(raw_response)
  except ValueError as e:
    # 11. パース失敗時: [ERROR] 表示 + raw ファイルパスを [INFO] 表示 + return 1
    print(f"[ERROR] レスポンスパース失敗: {e}")
    print(f"[INFO] Claude の生レスポンスは {raw_path} に保存されています")
    return 1

  # 12. _normalize_severity_token で Finding に変換
  raw_findings = data.get("findings", [])
  findings: list[Finding] = []
  for i, f in enumerate(raw_findings):
    cli_severity = _normalize_severity_token(
      f["severity"],
      source_context={
        "context": f"audit {tier}",
        "source_field": f"findings[{i}].severity",
        "location": f.get("location", "-"),
      },
      drift_sink=drift_events,
    )
    category = f.get("category", "")
    page = f.get("page") or ""
    message = f.get("message", "")
    marker = f.get("marker") or ""
    findings.append(Finding(
      severity=cli_severity,
      category=category,
      page=page,
      message=message,
      marker=marker,
    ))

  # 13. generate_audit_report でレポート生成
  metrics = data.get("metrics", {})
  recommended_actions = data.get("recommended_actions", [])
  report_path = generate_audit_report(tier, findings, metrics, recommended_actions, timestamp=ts)

  # 14. print_audit_summary
  print_audit_summary(tier, findings, report_path)

  # 15. CRITICAL/ERROR あれば exit 2、なければ exit 0
  return rw_utils._compute_exit_code(rw_utils._compute_run_status(findings), had_runtime_error=False)


def cmd_audit_monthly(args: list[str]) -> int:
  """monthly 監査を実行する。_run_llm_audit("monthly", args) に委譲。"""
  return _run_llm_audit("monthly", args)


def cmd_audit_quarterly(args: list[str]) -> int:
  """quarterly 監査を実行する。_run_llm_audit("quarterly", args) に委譲。"""
  return _run_llm_audit("quarterly", args)


# -------------------------
# Output utilities
# -------------------------

def generate_query_id(question: str) -> str:
    """YYYYMMDD-<rw_utils.slugify(question)> 形式の query_id を生成する。

    slugify は既存関数を使用（ASCII, lowercase, hyphen, max 80 chars）。

    Raises:
        ValueError: question が空または空白のみの場合
    """
    if not question or not question.strip():
        raise ValueError("question must not be empty")
    date_prefix = rw_utils.today().replace("-", "")
    slug = rw_utils.slugify(question)
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
    base_dir = os.path.join(rw_config.QUERY_REVIEW, query_id)
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
    rw_utils.write_text(question_path, question_content)

    # answer.md: Markdown コンテンツそのまま
    answer_path = os.path.join(base_dir, "answer.md")
    rw_utils.write_text(answer_path, data["answer"]["content"])

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
    rw_utils.write_text(evidence_path, evidence_content)

    # metadata.json: CLI 生成の query_id で上書き
    metadata = dict(data["metadata"])
    metadata["query_id"] = query_id
    metadata_path = os.path.join(base_dir, "metadata.json")
    rw_utils.write_text(metadata_path, json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")

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
    if not os.path.isdir(rw_config.WIKI):
        print(f"[ERROR] wiki/ ディレクトリが見つかりません: {rw_config.WIKI}")
        return 1

    # CLAUDE.md 存在チェック
    if not os.path.exists(os.path.join(rw_config.ROOT, "CLAUDE.md")):
        print(f"[ERROR] CLAUDE.md が見つかりません: {os.path.join(rw_config.ROOT, 'CLAUDE.md')}")
        return 1

    # AGENTS/ 存在チェック
    if not os.path.isdir(os.path.join(rw_config.ROOT, "AGENTS")):
        print(f"[ERROR] AGENTS/ ディレクトリが見つかりません: {os.path.join(rw_config.ROOT, 'AGENTS')}")
        return 1

    rw_utils.warn_if_dirty_paths(["wiki"], "query extract")

    # 3. query_id 生成
    try:
        query_id = generate_query_id(question)
    except ValueError as e:
        print(f"[ERROR] {e}")
        return 1

    query_dir = os.path.join(rw_config.QUERY_REVIEW, query_id)
    if os.path.isdir(query_dir):
        print(
            f"[ERROR] query_id '{query_id}' のディレクトリが既に存在します: {query_dir}\n"
            f"手動で削除することで再生成できます: rm -rf {query_dir}"
        )
        return 1

    # 4. load_task_prompts
    try:
        task_prompts = rw_prompt_engine.load_task_prompts("query_extract")
    except (ValueError, FileNotFoundError) as e:
        print(f"[ERROR] load_task_prompts 失敗: {e}")
        return 1

    # 5. wiki サイズチェックと wiki_content 取得
    try:
        num_files = len(rw_utils.list_md_files(rw_config.WIKI))
        if num_files > 20 and scope is None:
            # 2段階方式: ステージ1で関連ページ特定
            try:
                index_content = rw_utils.read_text(rw_config.INDEX_MD)
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
            stage1_response = rw_prompt_engine.call_claude(stage1_prompt, timeout=120)

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
                    full_path = os.path.join(rw_config.ROOT, page_path) if not os.path.isabs(page_path) else page_path
                    if os.path.isfile(full_path):
                        parts.append(f"<!-- file: {page_path} -->\n{rw_utils.read_text(full_path)}")
                    elif os.path.isfile(page_path):
                        parts.append(f"<!-- file: {page_path} -->\n{rw_utils.read_text(page_path)}")
                wiki_content = "\n\n".join(parts) if parts else index_content
            else:
                # フォールバック: index.md を使用
                wiki_content = index_content
        else:
            wiki_content = rw_prompt_engine.read_wiki_content(scope)
    except FileNotFoundError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1
    except ValueError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1

    # 6. プロンプト構築
    prompt = rw_prompt_engine.build_query_prompt(
        task_prompts,
        question,
        wiki_content,
        output_format="json",
        query_type=query_type,
    )

    # 7. Claude 呼び出し
    try:
        response = rw_prompt_engine.call_claude(prompt, timeout=120)
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
        for chk in lint_result["checks"]:
            if chk["severity"] in rw_config._FAIL_SEVERITIES:
                print(f"  [{chk['severity']}] {chk['id']} {chk['message']}")
        print("[INFO] アーティファクトは生成されましたが lint に失敗しました。")
        for p in file_paths:
            print(f"  {rw_utils.relpath(p)}")
        return 2
    else:
        print(f"[DONE] query extract 完了: {query_id}")
        for p in file_paths:
            print(f"  {rw_utils.relpath(p)}")
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
    if not os.path.isdir(rw_config.WIKI):
        print(f"[ERROR] wiki/ ディレクトリが見つかりません: {rw_config.WIKI}")
        return 1

    # CLAUDE.md 存在チェック
    if not os.path.exists(os.path.join(rw_config.ROOT, "CLAUDE.md")):
        print(f"[ERROR] CLAUDE.md が見つかりません: {os.path.join(rw_config.ROOT, 'CLAUDE.md')}")
        return 1

    # AGENTS/ 存在チェック
    if not os.path.isdir(os.path.join(rw_config.ROOT, "AGENTS")):
        print(f"[ERROR] AGENTS/ ディレクトリが見つかりません: {os.path.join(rw_config.ROOT, 'AGENTS')}")
        return 1

    rw_utils.warn_if_dirty_paths(["wiki"], "query answer")

    # 3. load_task_prompts
    try:
        task_prompts = rw_prompt_engine.load_task_prompts("query_answer")
    except (ValueError, FileNotFoundError) as e:
        print(f"[ERROR] load_task_prompts 失敗: {e}")
        return 1

    # 4. wiki コンテンツ取得
    try:
        wiki_content = rw_prompt_engine.read_wiki_content(scope)
    except FileNotFoundError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1
    except ValueError as e:
        print(f"[ERROR] wiki コンテンツ読み込み失敗: {e}")
        return 1

    # 5. プロンプト構築
    prompt = rw_prompt_engine.build_query_prompt(
        task_prompts,
        question,
        wiki_content,
        output_format="plaintext",
    )

    # 6. Claude 呼び出し
    try:
        response = rw_prompt_engine.call_claude(prompt, timeout=120)
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
        for pat in rw_config.EVIDENCE_SOURCE_PATTERNS:
            if re.search(pat, s, re.IGNORECASE):
                return True
    return False


def contains_inference_language(text: str) -> bool:
    for pat in rw_config.INFERENCE_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            return True
    return False


def lint_single_query_dir(query_dir: str, strict: bool = False) -> dict[str, Any]:
    result: dict[str, Any] = {
        "target": rw_utils.relpath(query_dir),
        "status": "PASS",
        "checks": [],
    }

    def add(level: str, code: str, message: str) -> None:
        result["checks"].append({
            "id": code,
            "severity": level,
            "message": message,
        })

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

    query_text = rw_utils.read_text(required_files["question.md"])
    answer_text = rw_utils.read_text(required_files["answer.md"])
    evidence_text = rw_utils.read_text(required_files["evidence.md"])

    metadata, metadata_err = rw_utils.safe_read_json(required_files["metadata.json"])
    if metadata_err:
        add("CRITICAL", "QL017", f"metadata.json is invalid JSON: {metadata_err}")
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
    elif query_type not in rw_config.ALLOWED_QUERY_TYPES:
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

    has_fail = any(c["severity"] in rw_config._FAIL_SEVERITIES for c in result["checks"])
    result["status"] = "FAIL" if has_fail else "PASS"

    return result


def print_query_lint_text(results: list[dict[str, Any]]) -> None:
    agg: dict[str, int] = {"critical": 0, "error": 0, "warn": 0, "info": 0}
    for res in results:
        print(f"Lint Result: {res['status']}")
        print(f"Target: {res['target']}")
        print()

        for chk in res["checks"]:
            print(f"{chk['severity']:5} {chk['id']:6} {chk['message']}")
            key = chk["severity"].lower()
            if key in agg:
                agg[key] += 1

        if not res["checks"]:
            print("No issues found.")

        print()

    run_status = "FAIL" if any(r["status"] == "FAIL" for r in results) else "PASS"
    print(
        f"query lint: CRITICAL {agg['critical']}, ERROR {agg['error']},"
        f" WARN {agg['warn']}, INFO {agg['info']} — {run_status}"
    )


def cmd_lint_query(args: list[str]) -> int:
    rw_utils.ensure_dirs()

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
                return rw_utils._compute_exit_code(None, had_runtime_error=True)
            target_path = args[i]
        elif a == "--strict":
            strict = True
        elif a == "--format":
            i += 1
            if i >= len(args):
                print("missing value for --format")
                return rw_utils._compute_exit_code(None, had_runtime_error=True)
            output_format = args[i]
        else:
            if not a.startswith("--") and target_path is None:
                target_path = a
            else:
                print(f"unknown option: {a}")
                return rw_utils._compute_exit_code(None, had_runtime_error=True)
        i += 1

    if target_path:
        query_dirs = [target_path]
    else:
        query_dirs = rw_utils.list_query_dirs(rw_config.QUERY_REVIEW)

    if not query_dirs:
        print("No query directories found.")
        return 0

    missing_paths = [p for p in query_dirs if not os.path.isdir(p)]
    if missing_paths:
        print(f"target path not found: {missing_paths[0]}")
        return rw_utils._compute_exit_code(None, had_runtime_error=True)

    results = [lint_single_query_dir(p, strict=strict) for p in query_dirs]

    sc: dict[str, int] = {"critical": 0, "error": 0, "warn": 0, "info": 0}
    for r in results:
        for chk in r["checks"]:
            key = chk["severity"].lower()
            if key in sc:
                sc[key] += 1
    run_status = "FAIL" if any(r["status"] == "FAIL" for r in results) else "PASS"

    payload = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "status": run_status,
        "results": results,
        "summary": {
            "targets": len(results),
            "severity_counts": sc,
        },
        "drift_events": [],
    }
    rw_utils.write_text(rw_config.QUERY_LINT_LOG, json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

    if output_format == "json":
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print_query_lint_text(results)
        print(f"Log: {rw_utils.relpath(rw_config.QUERY_LINT_LOG)}")

    if run_status == "FAIL":
        return 2
    return 0


def cmd_query_fix(args: list[str]) -> int:
    """rw query fix サブコマンド。終了コードを返す。"""
    # 1. 引数パース（query_id）
    if not args:
        print("[ERROR] query_id is required")
        return 1

    query_id = args[0]

    # 2. 前提条件チェック
    query_dir = os.path.join(rw_config.QUERY_REVIEW, query_id)
    if not os.path.isdir(query_dir):
        print(f"[ERROR] query_id ディレクトリが見つかりません: {query_dir}")
        return 1

    if not os.path.exists(os.path.join(rw_config.ROOT, "CLAUDE.md")):
        print(f"[ERROR] CLAUDE.md が見つかりません: {os.path.join(rw_config.ROOT, 'CLAUDE.md')}")
        return 1

    if not os.path.isdir(os.path.join(rw_config.ROOT, "AGENTS")):
        print(f"[ERROR] AGENTS/ ディレクトリが見つかりません: {os.path.join(rw_config.ROOT, 'AGENTS')}")
        return 1

    rw_utils.warn_if_dirty_paths(["wiki"], "query fix")

    # 3. 事前 lint
    pre_lint = lint_single_query_dir(query_dir)
    if pre_lint["status"] != "FAIL":
        print(f"[INFO] 修復不要: {query_id} は lint 検証をパスしています")
        return 0

    # 4. load_task_prompts
    try:
        task_prompts = rw_prompt_engine.load_task_prompts("query_fix")
    except (ValueError, FileNotFoundError) as e:
        print(f"[ERROR] load_task_prompts 失敗: {e}")
        return 1

    # 5. wiki コンテンツ取得
    try:
        wiki_content = rw_prompt_engine.read_wiki_content(scope=None)
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
            existing_artifacts[filename] = rw_utils.read_text(path)

    # 7. プロンプト構築
    prompt = rw_prompt_engine.build_query_prompt(
        task_prompts,
        question="",
        wiki_content=wiki_content,
        output_format="json",
        lint_results=pre_lint,
        existing_artifacts=existing_artifacts,
    )

    # 8. Claude 呼び出し
    try:
        response = rw_prompt_engine.call_claude(prompt, timeout=120)
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
            rw_utils.write_text(file_path, content)
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
    for chk in post_lint.get("checks", []):
        if chk["severity"] in rw_config._FAIL_SEVERITIES:
            print(f"  [{chk['severity']}] {chk['id']} {chk['message']}")

    # 14. 終了コード決定
    if post_lint["status"] == "FAIL":
        return 2
    return 0


# -------------------------
# cmd_init
# -------------------------
def _backup_timestamp() -> str:
  """バックアップディレクトリ名に使用するタイムスタンプ文字列を返す（YYYYMMDD-HHMMSS 形式）。
  テスト時に monkeypatch で差し替え可能にするためモジュールレベル関数として分離。"""
  import datetime
  return datetime.datetime.now().strftime("%Y%m%d-%H%M%S")


def cmd_init(args: list[str]) -> int:
  """
  Vaultセットアップを実行する。

  args: コマンドライン引数（target_path を含む場合あり）
  returns: 終了コード（0: 成功, 1: エラー）
  """
  # --- 引数解析 ---
  import argparse as _argparse
  parser = _argparse.ArgumentParser(prog="rw init", add_help=False)
  parser.add_argument("--force", action="store_true", default=False,
                      help="既存 AGENTS/ を .backup/<timestamp>/ に退避して新テンプレートで上書きする")
  parser.add_argument("target", nargs="?", default=None)
  parsed, _unknown = parser.parse_known_args(args)
  force = parsed.force
  target_path = parsed.target if parsed.target else os.getcwd()

  # --- report dict 初期化 ---
  report: dict[str, Any] = {
    "target": target_path,
    "dirs_created": 0,
    "templates_copied": [],
    "skipped": [],
  }

  # --- テンプレートチェック ---
  tmpl_claude = os.path.join(rw_config.DEV_ROOT, "templates", "CLAUDE.md")
  tmpl_gitignore = os.path.join(rw_config.DEV_ROOT, "templates", ".gitignore")
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
  if rw_utils.is_existing_vault(target_path) and not force:
    ans = input(
      f"[WARN] '{target_path}' は既存のVaultです。上書きしますか？ [y/N]: "
    ).strip().lower()
    if ans != "y":
      print("[INFO] セットアップを中断しました。")
      return 0

  # --- ディレクトリ生成 ---
  dirs_created = 0
  for d in rw_config.VAULT_DIRS:
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

  # --- AGENTS/ コピー ---
  tmpl_agents = os.path.join(rw_config.DEV_ROOT, "templates", "AGENTS")
  dest_agents = os.path.join(target_path, "AGENTS")
  if os.path.isdir(tmpl_agents):
    try:
      if os.path.isdir(dest_agents):
        if force:
          # --force: .backup/<timestamp>/ に退避（symlink 防御 + timestamp collision fallback）
          backup_root = os.path.join(target_path, ".backup")
          # .backup/ が symlink なら abort
          if os.path.islink(backup_root):
            print("[rw-init] .backup/ must be a regular directory", file=sys.stderr)
            sys.exit(1)
          ts = _backup_timestamp()
          backup_agents_dir = os.path.join(backup_root, ts)
          if os.path.exists(backup_agents_dir):
            # timestamp collision: <timestamp>-<pid> fallback
            backup_agents_dir = os.path.join(backup_root, f"{ts}-{os.getpid()}")
          os.makedirs(backup_agents_dir, exist_ok=True)
          shutil.move(dest_agents, os.path.join(backup_agents_dir, "AGENTS"))
          print(f"[rw-init] 上書き: 旧 AGENTS/ を {backup_agents_dir}/AGENTS に退避しました。", file=sys.stderr)
        else:
          # 通常 re-init: AGENTS.bak に退避
          bak_agents = dest_agents + ".bak"
          if os.path.isdir(bak_agents):
            shutil.rmtree(bak_agents)
          os.rename(dest_agents, bak_agents)
      shutil.copytree(tmpl_agents, dest_agents, dirs_exist_ok=True)
      report["templates_copied"].append("AGENTS/")
    except SystemExit:
      raise
    except Exception as e:
      print(f"[WARN] AGENTS/ コピー失敗: {e}")
      report["skipped"].append({"item": "AGENTS/", "reason": str(e)})
  else:
    report["skipped"].append({"item": "AGENTS/", "reason": "templates/AGENTS/ が存在しない"})

  # --- 初期ファイル生成 ---
  index_md = os.path.join(target_path, "index.md")
  if not os.path.exists(index_md):
    try:
      rw_utils.write_text(index_md, "# Index\n")
      report["templates_copied"].append("index.md")
    except Exception as e:
      print(f"[WARN] index.md 生成失敗: {e}")
      report["skipped"].append({"item": "index.md", "reason": str(e)})
  else:
    report["skipped"].append({"item": "index.md", "reason": "既存ファイルを保護"})

  log_md = os.path.join(target_path, "log.md")
  if not os.path.exists(log_md):
    try:
      rw_utils.write_text(log_md, "# Log\n")
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
  rw_src = os.path.join(rw_config.DEV_ROOT, "scripts", "rw_light.py")
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
    print("Usage: rw [lint|ingest|synthesize-logs|approve|init|query|audit]")
    print("       rw lint")
    print("       rw lint query [--path review/query/<query_id>] [--strict] [--format text|json]")
    print("       rw init [<path>]")
    print("       rw query <subcommand>")
    print('           extract "<question>" [--scope <page>] [--type <query_type>]')
    print('           answer  "<question>" [--scope <page>]')
    print("           fix     <query_id>")
    print("       rw audit <subcommand>")
    print("           micro      最近更新されたページを対象とした静的チェック")
    print("           weekly     全ページを対象とした構造チェック")
    print("           monthly    Claude CLI を使用した意味的監査")
    print("           quarterly  Claude CLI を使用した戦略的監査")


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

        if cmd == "audit":
            sys.exit(cmd_audit(sys.argv[2:]))

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
