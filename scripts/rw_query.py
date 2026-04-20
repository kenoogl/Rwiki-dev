#!/usr/bin/env python3
"""rw_query モジュール: query コマンド群と query lint 検査。

Phase 4b (module-split spec) で rw_light.py から物理移動。

DAG: rw_config, rw_utils, rw_prompt_engine のみ import。
rw_audit / rw_light は import しない（循環防止、Req 2.2）。

Note:
  `_strip_code_block` は rw_audit にも複製が存在する（Phase 4.1 決定）。
  この重複は仕様上許容され、本モジュールのコピーが query 系の正。
"""
import json
import os
import re
import sys
from datetime import datetime
from typing import Any

import rw_config
import rw_prompt_engine
import rw_query
import rw_utils


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
    # 自モジュール修飾で呼び出し（Req 4.3 の monkeypatch を有効化するため）
    pre_lint = rw_query.lint_single_query_dir(query_dir)
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
    # 自モジュール修飾で呼び出し（Req 4.3 の monkeypatch を有効化するため）
    post_lint = rw_query.lint_single_query_dir(query_dir)

    # 13. post-fix lint 結果を表示
    print(f"\n[POST-FIX LINT] status: {post_lint['status']}")
    for chk in post_lint.get("checks", []):
        if chk["severity"] in rw_config._FAIL_SEVERITIES:
            print(f"  [{chk['severity']}] {chk['id']} {chk['message']}")

    # 14. 終了コード決定
    if post_lint["status"] == "FAIL":
        return 2
    return 0
