"""rw_audit — audit コマンド（micro/weekly/monthly/quarterly）とチェック関数群の集約層。

`rw_light` から `import rw_audit` + `rw_audit.<name>` 形式で参照する。
`from rw_audit import <name>` は禁止（Req 1.3: re-export 禁止、
Req 3.2: テスト monkeypatch が効かなくなるため）。

このモジュールは `rw_config`, `rw_utils`, `rw_prompt_engine` のみを import し、
他のサブモジュール（rw_query, rw_light）は import しない（DAG 維持、Req 2.2）。
"""
import json
import os
import re
import sys
from datetime import datetime
from typing import NamedTuple

import rw_config
import rw_prompt_engine
import rw_utils


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


def _strip_code_block(response: str) -> str:
  """マークダウンコードブロック（```json ... ``` や ``` ... ```）を除去する。

  audit の `parse_audit_response` 用ローカルヘルパ。rw_query にも同名の関数が
  存在するが、Req 2.2（DAG 維持）のため rw_query を import せずに重複定義している。
  """
  stripped = response.strip()
  # ```json\n...\n``` または ```\n...\n``` 形式を除去
  match = re.match(r"^```(?:json)?\s*\n([\s\S]*?)\n```\s*$", stripped)
  if match:
    return match.group(1)
  return stripped


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
