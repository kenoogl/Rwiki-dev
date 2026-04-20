"""rw_prompt_engine — Claude CLI 呼び出しとプロンプト構築、タスクプロンプトロードの集約層。

`rw_audit`, `rw_query`, `rw_light` から
`import rw_prompt_engine` + `rw_prompt_engine.<name>` 形式で参照する。
`from rw_prompt_engine import <name>` は禁止（Req 1.3: re-export 禁止、
Req 3.2: テスト monkeypatch が効かなくなるため）。

このモジュールは `rw_config` と `rw_utils` のみを import し、
他のサブモジュール（rw_audit, rw_query, rw_light）は import しない（DAG 維持、Req 2.2）。
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

import rw_config
import rw_utils


# -------------------------
# synthesize-logs: Claude 呼び出し
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
{rw_utils.relpath(log_path)}

対象テキスト:
\"\"\"
{rw_utils.read_text(log_path)}
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


# -------------------------
# CLAUDE.md エージェント・ポリシー マッピング
# -------------------------
def parse_agent_mapping(claude_md_path: str) -> dict[str, dict[str, Any]]:
    """CLAUDE.md のマッピング表をパースし、タスク→エージェント+ポリシーの辞書を返す。

    パース手順:
    1. CLAUDE.md を rw_utils.read_text() で読み込む
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
    content = rw_utils.read_text(claude_md_path)

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


def load_task_prompts(task_name: str, *, skip_vault_validation: bool = False) -> str:
    """タスクに必要なエージェント+ポリシーを CLAUDE.md マッピングに基づいて読み込み、結合して返す。

    手順:
    1. parse_agent_mapping() でマッピングを取得
    2. task_name に対応するエージェントファイルを読み込む
    3. 対応するポリシーを全て読み込む
    4. エージェント + ポリシーを結合して返す

    audit タスクの場合は _validate_agents_severity_vocabulary() を呼び出して
    AGENTS/audit.md の severity 語彙を検証する。
    skip_vault_validation=True の場合はこの検証をスキップし、
    "[vault-validation] SKIPPED ..." 警告を stderr に出力する。

    Args:
        task_name: タスク名（"audit", "query_extract" 等）
        skip_vault_validation: True の場合、audit の vault 語彙検証をスキップする。
            RW_SKIP_VAULT_VALIDATION=1 環境変数でも同等の効果。

    Raises:
        ValueError: task_name がマッピング表に存在しない場合
        FileNotFoundError: エージェントまたはポリシーファイルが存在しない場合
    """
    claude_md_path = os.path.join(rw_config.ROOT, "CLAUDE.md")
    mapping = parse_agent_mapping(claude_md_path)

    if task_name not in mapping:
        raise ValueError(
            f"タスク '{task_name}' は CLAUDE.md のマッピング表に存在しません"
        )

    entry = mapping[task_name]
    agent_path = os.path.join(rw_config.ROOT, entry["agent"])
    policy_paths = [os.path.join(rw_config.ROOT, p) for p in entry["policies"]]

    if not os.path.isfile(agent_path):
        raise FileNotFoundError(
            f"エージェントファイルが見つかりません: {agent_path}"
        )

    for pol_path in policy_paths:
        if not os.path.isfile(pol_path):
            raise FileNotFoundError(
                f"ポリシーファイルが見つかりません: {pol_path}"
            )

    # audit タスクの場合は severity 語彙を検証する（Req 6.5, 7.9）
    if task_name == "audit":
        _env_skip = os.environ.get("RW_SKIP_VAULT_VALIDATION") == "1"
        if skip_vault_validation or _env_skip:
            sys.stderr.write(
                "[vault-validation] SKIPPED (--skip-vault-validation or"
                " RW_SKIP_VAULT_VALIDATION=1 set)."
                " Drift 3-layer defense weakened.\n"
            )
        else:
            _validate_agents_severity_vocabulary(Path(rw_config.AGENTS_DIR) / "audit.md")

    parts: list[str] = [rw_utils.read_text(agent_path)]
    for pol_path in policy_paths:
        parts.append(rw_utils.read_text(pol_path))

    return "\n\n".join(parts)


# -------------------------
# query プロンプト構築
# -------------------------
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


# -------------------------
# Claude CLI 呼び出し
# -------------------------
def call_claude(prompt: str, timeout: int | None = None) -> str:
    """Claude CLI を呼び出してレスポンスを返す。

    Args:
        prompt: Claude に送信するプロンプト
        timeout: タイムアウト秒数。None の場合はタイムアウトなし（既存動作と同一）
    Returns:
        Claude の応答文字列
    Raises:
        RuntimeError: Claude CLI が非ゼロ終了、またはタイムアウト
    """
    try:
        result = subprocess.run(
            ["claude", "-p", prompt],
            capture_output=True,
            text=True,
            encoding="utf-8",
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"Claude CLI がタイムアウトしました ({timeout}秒)")
    if result.returncode != 0:
        print(result.stdout[:500], file=sys.stderr)
        raise RuntimeError(result.stderr.strip() or "claude call failed")
    return result.stdout.strip()


# -------------------------
# wiki コンテンツ読み込み
# -------------------------
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
        return rw_utils.read_text(scope)

    # scope=None: wiki/ ディレクトリを対象とする
    if not os.path.isdir(rw_config.WIKI):
        raise FileNotFoundError(f"wiki/ ディレクトリが見つかりません: {rw_config.WIKI}")

    md_files = rw_utils.list_md_files(rw_config.WIKI)
    if not md_files:
        raise ValueError(f"wiki/ に .md ファイルが存在しません: {rw_config.WIKI}")

    # 小規模 wiki (≤20): 全ファイルを結合して返す
    if len(md_files) <= 20:
        parts: list[str] = []
        for path in md_files:
            parts.append(f"<!-- file: {rw_utils.relpath(path)} -->\n{rw_utils.read_text(path)}")
        return "\n\n".join(parts)

    # 大規模 wiki (>20): index.md のみを返す（cmd_* が2段階方式でオーケストレーションする）
    return rw_utils.read_text(rw_config.INDEX_MD)


# audit: data loading


def read_all_wiki_content() -> str:
    """wiki/ 内の全 .md ファイル + rw_config.ROOT/index.md + rw_config.ROOT/log.md を結合して返す。
    グローバル定数 rw_config.WIKI, rw_config.INDEX_MD, rw_config.CHANGE_LOG_MD を使用。

    各ファイルは `<!-- file: wiki/page-name.md -->` ヘッダー付きで結合する。
    rw_config.ROOT 直下のファイルは `<!-- file: index.md -->`, `<!-- file: log.md -->` として結合する。

    ページ数が rw_config.LARGE_WIKI_THRESHOLD（150）を超える場合は、標準出力に警告を表示する。
    ただし処理は続行する。

    index.md / log.md が存在しない場合はスキップする（エラーにしない）。

    Raises:
        FileNotFoundError: wiki/ が存在しない場合
        ValueError: wiki/ に .md ファイルが存在しない場合
    """
    if not os.path.isdir(rw_config.WIKI):
        raise FileNotFoundError(f"wiki/ が存在しません: {rw_config.WIKI}")

    md_files = rw_utils.list_md_files(rw_config.WIKI)
    if not md_files:
        raise ValueError(f"wiki/ に .md ファイルが存在しません: {rw_config.WIKI}")

    if len(md_files) > rw_config.LARGE_WIKI_THRESHOLD:
        print(
            f"[WARN] wiki ページ数が {len(md_files)} 件（閾値 {rw_config.LARGE_WIKI_THRESHOLD} 超）です。"
            " Claude のコンテキストウィンドウ上限に近づいている可能性があります。"
        )

    parts: list[str] = []

    # wiki/ 配下の全 .md ファイル
    for path in md_files:
        header = f"<!-- file: {rw_utils.relpath(path)} -->"
        parts.append(f"{header}\n{rw_utils.read_text(path)}")

    # rw_config.ROOT/index.md（存在する場合のみ）
    if os.path.isfile(rw_config.INDEX_MD):
        parts.append(f"<!-- file: index.md -->\n{rw_utils.read_text(rw_config.INDEX_MD)}")

    # rw_config.ROOT/log.md（存在する場合のみ）
    if os.path.isfile(rw_config.CHANGE_LOG_MD):
        parts.append(f"<!-- file: log.md -->\n{rw_utils.read_text(rw_config.CHANGE_LOG_MD)}")

    return "\n\n".join(parts)


# -------------------------
# AGENTS/audit.md severity 語彙検証（load_task_prompts の内部ヘルパー）
# -------------------------
def _validate_agents_severity_vocabulary(agents_file: Path) -> None:
  """AGENTS/audit.md の severity 語彙を検証する。

  旧語彙（HIGH/MEDIUM/LOW）が severity トークンとして出現した場合は
  stderr に error message を出力して SystemExit(1) を送出する。
  新語彙のみの場合は None を返す（正常終了）。

  Pattern 定義:
    Pattern A: テーブルセル・散文・大文字 `\\b(HIGH|MEDIUM|LOW)\\b`
    Pattern B: サマリーフィールドキー（行頭限定） `^\\s*-\\s+(high|medium|low)\\s*:`
    Pattern C: ファインディングブラケット `\\[(HIGH|MEDIUM|LOW)\\]`

  Migration Notes 除外: `<!-- severity-vocab: legacy-reference -->` ～
    `<!-- /severity-vocab -->` 内の旧語彙は検出対象外。

  Args:
      agents_file: AGENTS/audit.md への Path（通常 vault_root/AGENTS/audit.md）

  Raises:
      SystemExit(1): 旧語彙検出・ファイルサイズ超過・symlink パスエスケープ時
  """
  import re as _re

  # ---- symlink パスエスケープ防御 ----
  # vault root = agents_file.parent.parent (AGENTS/ → vault root)
  vault_dir = agents_file.parent.parent.resolve()
  try:
    real_path = agents_file.resolve()
    real_path.relative_to(vault_dir)
  except ValueError:
    sys.stderr.write("[vault-validation] path escape detected\n")
    raise SystemExit(1)

  # ---- ファイルサイズ上限（1 MB） ----
  _MAX_FILE_SIZE = 1024 * 1024  # 1 MB
  file_size = agents_file.stat().st_size
  if file_size > _MAX_FILE_SIZE:
    sys.stderr.write(
      f"[agents-vocab-error] file too large: {agents_file} ({file_size} bytes > 1 MB limit)\n"
    )
    raise SystemExit(1)

  # ---- ファイル読み込み ----
  content = agents_file.read_text(encoding="utf-8")

  # ---- Migration Notes ブロック除外 ----
  # <!-- severity-vocab: legacy-reference --> ～ <!-- /severity-vocab --> を空行に置換
  # re.DOTALL で複数行ブロックを一括除外
  _MIGRATION_BLOCK_RE = _re.compile(
    r"<!--\s*severity-vocab:\s*legacy-reference\s*-->.*?<!--\s*/severity-vocab\s*-->",
    _re.DOTALL,
  )
  # 行数がずれないよう改行を保持して空白に置換
  def _blank_preserving_lines(m: _re.Match) -> str:
    matched = m.group(0)
    newline_count = matched.count("\n")
    return "\n" * newline_count

  sanitized_content = _MIGRATION_BLOCK_RE.sub(_blank_preserving_lines, content)

  # ---- 3 Pattern 定義 ----
  # Pattern A: \b(HIGH|MEDIUM|LOW)\b  (テーブルセル・散文・大文字)
  _PAT_A = _re.compile(r"\b(HIGH|MEDIUM|LOW)\b")
  # Pattern B: ^\s*-\s+(high|medium|low)\s*:  (サマリーキー、行頭限定、小文字)
  _PAT_B = _re.compile(r"^\s*-\s+(high|medium|low)\s*:", _re.MULTILINE)
  # Pattern C: \[(HIGH|MEDIUM|LOW)\]  (ファインディングブラケット)
  _PAT_C = _re.compile(r"\[(HIGH|MEDIUM|LOW)\]")

  # ---- 違反を収集 ----
  # 各違反: (line_num: int, col: int, pattern_id: str, snippet: str)
  violations: list[tuple[int, int, str, str]] = []

  lines = sanitized_content.splitlines()
  for line_idx, line in enumerate(lines):
    line_num = line_idx + 1  # 1-origin

    for m in _PAT_A.finditer(line):
      # Pattern C と重複しないようにする（同一 match は Pattern C が優先）
      # ブラケット付き `[HIGH]` は Pattern C が検出するが、Pattern A も同一行でマッチしうる。
      # ここでは両方を記録し、sort stability で (line, col, pattern_id) 順に整列する。
      col = m.start()
      snippet = line.strip()[:60]
      violations.append((line_num, col, "pattern_A", snippet))

    for m in _PAT_B.finditer(line):
      col = m.start()
      snippet = line.strip()[:60]
      violations.append((line_num, col, "pattern_B", snippet))

    for m in _PAT_C.finditer(line):
      col = m.start()
      snippet = line.strip()[:60]
      violations.append((line_num, col, "pattern_C", snippet))

  if not violations:
    return None

  # ---- Sort: (line_num, col, pattern_id) の 3 段キーで deterministic ----
  violations.sort(key=lambda v: (v[0], v[1], v[2]))

  # ---- error message 出力 ----
  # 形式:
  #   [agents-vocab-error] deprecated severity vocabulary detected in <path>:
  #     line <N>: <pattern_id> → <snippet>
  #     ...
  #     (detected <count> violation(s))
  #     Run 'rw init --force <vault>' to redeploy.
  count = len(violations)
  lines_out = [
    f"[agents-vocab-error] deprecated severity vocabulary detected in {agents_file}:",
  ]
  for line_num, _col, pattern_id, snippet in violations:
    lines_out.append(f"  line {line_num}: {pattern_id} → {snippet}")
  lines_out.append(f"  (detected {count} violation(s))")
  lines_out.append(f"  Run 'rw init --force {agents_file.parent.parent}' to redeploy.")

  sys.stderr.write("\n".join(lines_out) + "\n")
  raise SystemExit(1)
