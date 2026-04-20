#!/usr/bin/env python3
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

import rw_audit
import rw_config
import rw_prompt_engine
import rw_query
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
                sys.exit(rw_query.cmd_lint_query(sys.argv[3:]))
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
                sys.exit(rw_query.cmd_query_extract(sys.argv[3:]))
            elif subcmd == "answer":
                sys.exit(rw_query.cmd_query_answer(sys.argv[3:]))
            elif subcmd == "fix":
                sys.exit(rw_query.cmd_query_fix(sys.argv[3:]))
            else:
                print(f"Unknown query subcommand: {subcmd}")
                print_usage()
                sys.exit(1)

        if cmd == "audit":
            sys.exit(rw_audit.cmd_audit(sys.argv[2:]))

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
