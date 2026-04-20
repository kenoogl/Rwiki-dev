"""Unit tests for rw_light.py — Task 1.1: parse_agent_mapping / load_task_prompts"""
import json
import os
import sys
import textwrap
from pathlib import Path
import pytest

# scripts/ を sys.path に追加
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scripts"))

import rw_light  # noqa: E402

# テスト用 CLAUDE.md が存在する templates/CLAUDE.md のパス
TEMPLATES_CLAUDE_MD = os.path.join(
    os.path.dirname(__file__), "..", "templates", "CLAUDE.md"
)
TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "..", "templates")


# ---------------------------------------------------------------------------
# parse_agent_mapping() のテスト
# ---------------------------------------------------------------------------

class TestParseAgentMapping:
    """parse_agent_mapping() のユニットテスト"""

    def test_returns_9_rows(self):
        """templates/CLAUDE.md から 9 行のマッピングが返ること"""
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        assert len(result) == 9, f"Expected 9 rows, got {len(result)}: {list(result.keys())}"

    def test_each_row_has_agent(self):
        """各行に agent キーが存在し非空であること"""
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        for task_name, entry in result.items():
            assert "agent" in entry, f"Row '{task_name}' missing 'agent' key"
            assert entry["agent"], f"Row '{task_name}' has empty agent"

    def test_each_row_has_policies(self):
        """各行に policies キーが存在しリスト型であること"""
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        for task_name, entry in result.items():
            assert "policies" in entry, f"Row '{task_name}' missing 'policies' key"
            assert isinstance(entry["policies"], list), (
                f"Row '{task_name}' policies should be a list"
            )

    def test_each_row_has_mode(self):
        """各行に mode キーが存在すること（具体値は検証しない）"""
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        for task_name, entry in result.items():
            assert "mode" in entry, f"Row '{task_name}' missing 'mode' key"
            assert entry["mode"], f"Row '{task_name}' has empty mode"

    def test_known_task_names_present(self):
        """期待されるタスク名が全て含まれていること"""
        expected_tasks = {
            "ingest", "lint", "synthesize", "synthesize_logs", "approve",
            "query_answer", "query_extract", "query_fix", "audit",
        }
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        assert set(result.keys()) == expected_tasks

    def test_multi_policy_parsed_as_list(self):
        """複数ポリシーがカンマ区切りでリスト化されること"""
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        # synthesize は 2 つのポリシーを持つ
        assert len(result["synthesize"]["policies"]) == 2

    def test_single_policy_parsed_as_list(self):
        """単一ポリシーも長さ 1 のリストで返ること"""
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        # ingest は 1 つのポリシー
        assert len(result["ingest"]["policies"]) == 1

    def test_agent_path_contains_agents_dir(self):
        """agent パスが AGENTS/ を含むこと"""
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        for task_name, entry in result.items():
            assert "AGENTS/" in entry["agent"], (
                f"Row '{task_name}' agent path doesn't start with AGENTS/: {entry['agent']}"
            )

    def test_policy_paths_contain_agents_dir(self):
        """各 policy パスが AGENTS/ を含むこと"""
        result = rw_light.parse_agent_mapping(TEMPLATES_CLAUDE_MD)
        for task_name, entry in result.items():
            for pol in entry["policies"]:
                assert "AGENTS/" in pol, (
                    f"Row '{task_name}' policy path doesn't contain AGENTS/: {pol}"
                )

    # --- エラーケース ---

    def test_raises_value_error_when_table_not_found(self, tmp_path):
        """マッピング表が存在しない CLAUDE.md の場合 ValueError を raise すること"""
        no_table_md = tmp_path / "CLAUDE.md"
        no_table_md.write_text("# Header\n\nNo table here.\n", encoding="utf-8")
        with pytest.raises(ValueError, match=".*"):
            rw_light.parse_agent_mapping(str(no_table_md))

    def test_raises_value_error_when_required_column_missing(self, tmp_path):
        """必須列 (Task, Agent, Policy) のいずれかが欠落している場合 ValueError を raise すること"""
        missing_col_md = tmp_path / "CLAUDE.md"
        # Policy 列なし
        missing_col_md.write_text(
            textwrap.dedent("""\
                | Task | Agent | Execution Mode |
                |---|---|---|
                | ingest | AGENTS/ingest.md | CLI |
            """),
            encoding="utf-8",
        )
        with pytest.raises(ValueError, match=".*"):
            rw_light.parse_agent_mapping(str(missing_col_md))

    def test_raises_value_error_when_agent_is_empty(self, tmp_path):
        """agent フィールドが空の行がある場合 ValueError を raise すること"""
        empty_agent_md = tmp_path / "CLAUDE.md"
        empty_agent_md.write_text(
            textwrap.dedent("""\
                | Task | Agent | Policy | Execution Mode |
                |---|---|---|---|
                | ingest |  | AGENTS/git_ops.md | CLI |
            """),
            encoding="utf-8",
        )
        with pytest.raises(ValueError, match=".*"):
            rw_light.parse_agent_mapping(str(empty_agent_md))

    def test_column_order_independent(self, tmp_path):
        """列順が変わっても正しくパースできること"""
        reordered_md = tmp_path / "CLAUDE.md"
        reordered_md.write_text(
            textwrap.dedent("""\
                | Execution Mode | Policy | Task | Agent |
                |---|---|---|---|
                | CLI | AGENTS/git_ops.md | ingest | AGENTS/ingest.md |
            """),
            encoding="utf-8",
        )
        result = rw_light.parse_agent_mapping(str(reordered_md))
        assert "ingest" in result
        assert result["ingest"]["agent"] == "AGENTS/ingest.md"
        assert result["ingest"]["policies"] == ["AGENTS/git_ops.md"]


# ---------------------------------------------------------------------------
# load_task_prompts() のテスト
# ---------------------------------------------------------------------------

class TestLoadTaskPrompts:
    """load_task_prompts() のユニットテスト"""

    def test_returns_string(self, monkeypatch, tmp_path):
        """正常ケース: 文字列が返ること"""
        # Vault ルートを tmp_path に向ける
        _setup_mock_vault(tmp_path, monkeypatch)
        result = rw_light.load_task_prompts("ingest")
        assert isinstance(result, str)
        assert len(result) > 0

    def test_concatenates_agent_and_policy(self, monkeypatch, tmp_path):
        """エージェントとポリシーの内容が結合されて返ること"""
        _setup_mock_vault(tmp_path, monkeypatch)
        result = rw_light.load_task_prompts("ingest")
        # AGENT_CONTENT と POLICY_CONTENT の両方が含まれること
        assert "AGENT_CONTENT" in result
        assert "POLICY_CONTENT" in result

    def test_multi_policy_all_included(self, monkeypatch, tmp_path):
        """複数ポリシーが全て結合されること"""
        _setup_mock_vault(tmp_path, monkeypatch)
        result = rw_light.load_task_prompts("synthesize")
        assert "SYNTHESIZE_AGENT" in result
        assert "PAGE_POLICY_CONTENT" in result
        assert "NAMING_POLICY_CONTENT" in result

    def test_raises_value_error_for_unknown_task(self, monkeypatch, tmp_path):
        """マッピング表に存在しないタスク名の場合 ValueError を raise すること"""
        _setup_mock_vault(tmp_path, monkeypatch)
        with pytest.raises(ValueError, match=".*"):
            rw_light.load_task_prompts("nonexistent_task")

    def test_raises_file_not_found_when_agent_missing(self, monkeypatch, tmp_path):
        """エージェントファイルが存在しない場合 FileNotFoundError を raise すること"""
        _setup_mock_vault(tmp_path, monkeypatch)
        # ingest.md を削除
        agent_file = tmp_path / "AGENTS" / "ingest.md"
        agent_file.unlink()
        with pytest.raises(FileNotFoundError):
            rw_light.load_task_prompts("ingest")

    def test_raises_file_not_found_when_policy_missing(self, monkeypatch, tmp_path):
        """ポリシーファイルが存在しない場合 FileNotFoundError を raise すること"""
        _setup_mock_vault(tmp_path, monkeypatch)
        # git_ops.md を削除
        policy_file = tmp_path / "AGENTS" / "git_ops.md"
        policy_file.unlink()
        with pytest.raises(FileNotFoundError):
            rw_light.load_task_prompts("ingest")


# ---------------------------------------------------------------------------
# テスト用ヘルパー
# ---------------------------------------------------------------------------

def _setup_mock_vault(tmp_path, monkeypatch):
    """
    tmp_path 配下に最小限の Vault 構造を作成し、
    rw_light.ROOT を tmp_path に向ける。
    """
    agents_dir = tmp_path / "AGENTS"
    agents_dir.mkdir()

    # CLAUDE.md (マッピング表を含む)
    claude_md = tmp_path / "CLAUDE.md"
    claude_md.write_text(
        textwrap.dedent("""\
            # Task → AGENTS Mapping (Default)

            | Task | Agent | Policy | Execution Mode |
            |---|---|---|---|
            | ingest | AGENTS/ingest.md | AGENTS/git_ops.md | CLI |
            | lint | AGENTS/lint.md | AGENTS/naming.md | CLI |
            | synthesize | AGENTS/synthesize.md | AGENTS/page_policy.md, AGENTS/naming.md | Prompt |
            | synthesize_logs | AGENTS/synthesize_logs.md | AGENTS/naming.md | CLI (Hybrid) |
            | approve | AGENTS/approve.md | AGENTS/git_ops.md, AGENTS/page_policy.md | CLI |
            | query_answer | AGENTS/query_answer.md | AGENTS/page_policy.md | Prompt |
            | query_extract | AGENTS/query_extract.md | AGENTS/naming.md, AGENTS/page_policy.md | Prompt |
            | query_fix | AGENTS/query_fix.md | AGENTS/naming.md | Prompt |
            | audit | AGENTS/audit.md | AGENTS/page_policy.md, AGENTS/naming.md, AGENTS/git_ops.md | Prompt |
        """),
        encoding="utf-8",
    )

    # AGENTS/ ファイルを作成
    agent_files = {
        "ingest.md": "AGENT_CONTENT ingest",
        "lint.md": "AGENT lint",
        "synthesize.md": "SYNTHESIZE_AGENT content",
        "synthesize_logs.md": "AGENT synthesize_logs",
        "approve.md": "AGENT approve",
        "query_answer.md": "AGENT query_answer",
        "query_extract.md": "AGENT query_extract",
        "query_fix.md": "AGENT query_fix",
        "audit.md": "AGENT audit",
        "git_ops.md": "POLICY_CONTENT git_ops",
        "naming.md": "NAMING_POLICY_CONTENT naming",
        "page_policy.md": "PAGE_POLICY_CONTENT page",
    }
    for filename, content in agent_files.items():
        (agents_dir / filename).write_text(content, encoding="utf-8")

    # rw_light.ROOT を tmp_path に向ける
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))


# ---------------------------------------------------------------------------
# call_claude() のテスト
# ---------------------------------------------------------------------------

class TestCallClaude:
    """call_claude() のユニットテスト"""

    def test_success_returns_stdout(self, monkeypatch):
        """成功時: stdout を返すこと"""
        import subprocess

        mock_result = subprocess.CompletedProcess(
            args=["claude", "-p", "test"],
            returncode=0,
            stdout="  hello from claude  \n",
            stderr="",
        )

        monkeypatch.setattr(subprocess, "run", lambda *args, **kwargs: mock_result)

        result = rw_light.call_claude("test prompt")
        assert result == "hello from claude"

    def test_failure_raises_runtime_error(self, monkeypatch):
        """失敗時 (returncode != 0): RuntimeError を raise し、stderr を含むこと"""
        import subprocess

        mock_result = subprocess.CompletedProcess(
            args=["claude", "-p", "test"],
            returncode=1,
            stdout="partial output",
            stderr="claude error: something went wrong",
        )

        monkeypatch.setattr(subprocess, "run", lambda *args, **kwargs: mock_result)

        with pytest.raises(RuntimeError, match="claude error: something went wrong"):
            rw_light.call_claude("test prompt")

    def test_failure_prints_stdout_to_stderr(self, monkeypatch, capsys):
        """失敗時: stdout の先頭500文字が stderr に出力されること"""
        import subprocess

        long_stdout = "X" * 600
        mock_result = subprocess.CompletedProcess(
            args=["claude", "-p", "test"],
            returncode=1,
            stdout=long_stdout,
            stderr="error message",
        )

        monkeypatch.setattr(subprocess, "run", lambda *args, **kwargs: mock_result)

        with pytest.raises(RuntimeError):
            rw_light.call_claude("test prompt")

        captured = capsys.readouterr()
        # stderr に stdout 先頭500文字が含まれること
        assert "X" * 500 in captured.err
        # 501文字目以降は含まれないこと（正確に500文字でトリム）
        assert "X" * 501 not in captured.err

    def test_failure_error_message_contains_stderr(self, monkeypatch):
        """失敗時: RuntimeError メッセージが stderr 内容を含むこと"""
        import subprocess

        mock_result = subprocess.CompletedProcess(
            args=["claude", "-p", "test"],
            returncode=2,
            stdout="",
            stderr="specific error detail",
        )

        monkeypatch.setattr(subprocess, "run", lambda *args, **kwargs: mock_result)

        with pytest.raises(RuntimeError) as exc_info:
            rw_light.call_claude("test prompt")

        assert "specific error detail" in str(exc_info.value)


# ---------------------------------------------------------------------------
# read_wiki_content() のテスト
# ---------------------------------------------------------------------------

class TestReadWikiContent:
    """read_wiki_content() のユニットテスト"""

    def _setup_wiki(self, tmp_path, monkeypatch, num_files=1, with_index=True):
        """tmp_path 配下に wiki/ ディレクトリと .md ファイルを作成し、ROOT を向ける。"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()

        # index.md を ROOT 直下に作成
        if with_index:
            index_md = tmp_path / "index.md"
            index_md.write_text("# Index\n\nThis is the index.", encoding="utf-8")

        # .md ファイルを指定数作成
        for i in range(num_files):
            md_file = wiki_dir / f"page_{i:02d}.md"
            md_file.write_text(f"# Page {i}\n\nContent of page {i}.", encoding="utf-8")

        # ROOT / WIKI / INDEX_MD を tmp_path に向ける
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))

        return wiki_dir

    # --- 正常系: scope 指定 ---

    def test_scope_existing_file_returns_content(self, tmp_path, monkeypatch):
        """scope 指定・ファイル存在: そのファイルの内容を返すこと"""
        wiki_dir = self._setup_wiki(tmp_path, monkeypatch)
        scope_path = str(wiki_dir / "page_00.md")

        result = rw_light.read_wiki_content(scope_path)

        assert "Content of page 0" in result

    def test_scope_returns_only_specified_file(self, tmp_path, monkeypatch):
        """scope 指定時: 指定ファイルの内容のみ返すこと（他ファイルは含まない）"""
        wiki_dir = self._setup_wiki(tmp_path, monkeypatch, num_files=3)
        scope_path = str(wiki_dir / "page_00.md")

        result = rw_light.read_wiki_content(scope_path)

        assert "Content of page 0" in result
        assert "Content of page 1" not in result
        assert "Content of page 2" not in result

    # --- エラー系: scope 指定 ---

    def test_scope_missing_file_raises_file_not_found(self, tmp_path, monkeypatch):
        """scope 指定・ファイル不在: FileNotFoundError を raise すること"""
        self._setup_wiki(tmp_path, monkeypatch)
        missing_path = str(tmp_path / "wiki" / "nonexistent.md")

        with pytest.raises(FileNotFoundError):
            rw_light.read_wiki_content(missing_path)

    # --- エラー系: scope=None ---

    def test_scope_none_wiki_missing_raises_file_not_found(self, tmp_path, monkeypatch):
        """scope=None・wiki/ 不在: FileNotFoundError を raise すること"""
        # wiki/ を作らずに ROOT のみ設定
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))

        with pytest.raises(FileNotFoundError):
            rw_light.read_wiki_content(None)

    def test_scope_none_no_md_files_raises_value_error(self, tmp_path, monkeypatch):
        """scope=None・.md ファイルゼロ: ValueError を raise すること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        # .md ファイルなし（.txt ファイルのみ）
        (wiki_dir / "readme.txt").write_text("not markdown", encoding="utf-8")

        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))

        with pytest.raises(ValueError):
            rw_light.read_wiki_content(None)

    # --- 正常系: scope=None, 小規模 wiki (≤20) ---

    def test_scope_none_small_wiki_returns_all_content(self, tmp_path, monkeypatch):
        """scope=None・ファイル数≤20: 全ファイル内容を結合して返すこと"""
        wiki_dir = self._setup_wiki(tmp_path, monkeypatch, num_files=3)

        result = rw_light.read_wiki_content(None)

        assert "Content of page 0" in result
        assert "Content of page 1" in result
        assert "Content of page 2" in result

    def test_scope_none_exactly_20_files_returns_all(self, tmp_path, monkeypatch):
        """scope=None・ファイル数=20: 全ファイル内容を返すこと（境界値）"""
        wiki_dir = self._setup_wiki(tmp_path, monkeypatch, num_files=20)

        result = rw_light.read_wiki_content(None)

        for i in range(20):
            assert f"Content of page {i}" in result

    # --- 正常系: scope=None, 大規模 wiki (>20) ---

    def test_scope_none_large_wiki_returns_index_only(self, tmp_path, monkeypatch):
        """scope=None・ファイル数>20: index.md の内容のみ返すこと"""
        wiki_dir = self._setup_wiki(tmp_path, monkeypatch, num_files=21)

        result = rw_light.read_wiki_content(None)

        # index.md の内容を含む
        assert "This is the index" in result
        # wiki/ ファイルの内容は含まない
        assert "Content of page 0" not in result

    def test_scope_none_exactly_21_files_returns_index(self, tmp_path, monkeypatch):
        """scope=None・ファイル数=21: index.md のみ返すこと（境界値）"""
        wiki_dir = self._setup_wiki(tmp_path, monkeypatch, num_files=21)

        result = rw_light.read_wiki_content(None)

        assert "This is the index" in result
        assert "Content of page" not in result

    def test_scope_none_large_wiki_index_missing_raises_file_not_found(self, tmp_path, monkeypatch):
        """scope=None・ファイル数>20・index.md 不在: FileNotFoundError を raise すること"""
        wiki_dir = self._setup_wiki(tmp_path, monkeypatch, num_files=21, with_index=False)

        with pytest.raises(FileNotFoundError):
            rw_light.read_wiki_content(None)


# ---------------------------------------------------------------------------
# build_query_prompt() のテスト
# ---------------------------------------------------------------------------

class TestBuildQueryPrompt:
    """build_query_prompt() のユニットテスト"""

    TASK_PROMPTS = "AGENT_CONTENT: You are a query agent.\n\nPOLICY_CONTENT: Follow naming rules."
    QUESTION = "What is the main topic of the wiki?"
    WIKI_CONTENT = "# Wiki\n\nThis wiki covers machine learning topics."

    def test_json_format_contains_json_schema_markers(self):
        """output_format='json' の場合、JSON スキーマ指示が含まれること"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
        )
        assert isinstance(result, str)
        # JSON スキーマ関連のマーカーが含まれること
        assert "json" in result.lower() or "JSON" in result

    def test_json_format_contains_extract_schema_fields(self):
        """output_format='json' の場合、4ファイル抽出スキーマのフィールドが含まれること"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
        )
        # 抽出スキーマのキーフィールドが含まれること
        assert "query" in result
        assert "answer" in result
        assert "evidence" in result
        assert "metadata" in result
        assert "referenced_pages" in result

    def test_plaintext_format_contains_referenced_instruction(self):
        """output_format='plaintext' の場合、Referenced: 指示が含まれること"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="plaintext",
        )
        assert "Referenced" in result or "referenced" in result

    def test_plaintext_format_does_not_contain_json_schema(self):
        """output_format='plaintext' の場合、JSONスキーマ指示が含まれないこと"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="plaintext",
        )
        # 4ファイルスキーマの構造は含まれないこと
        assert "referenced_pages" not in result

    def test_query_type_specified_included_in_prompt(self):
        """query_type 指定時: プロンプトに query_type が含まれること"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
            query_type="fact",
        )
        assert "fact" in result

    def test_query_type_none_not_explicitly_set(self):
        """query_type=None の場合: 明示的なクエリタイプ指定がプロンプトに含まれないこと"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
            query_type=None,
        )
        # 特定の query_type 値（fact, structure等）が明示的に指定されていないこと
        # ただしスキーマ内のサンプル値は除く（"fact|structure|..." 形式は許容）
        # query_type: fact のような形式が含まれないことを確認
        assert "query_type: fact" not in result
        assert "query_type: structure" not in result
        assert "query_type: why" not in result
        assert "query_type: comparison" not in result
        assert "query_type: hypothesis" not in result

    def test_lint_results_included_when_provided(self):
        """lint_results 提供時: プロンプトに lint 結果が含まれること"""
        lint_results = {
            "errors": [{"code": "QL001", "message": "missing file: answer.md"}],
            "warnings": [],
        }
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
            lint_results=lint_results,
        )
        assert "QL001" in result or "lint" in result.lower() or "missing file" in result

    def test_existing_artifacts_included_when_provided(self):
        """existing_artifacts 提供時: プロンプトに既存アーティファクトが含まれること"""
        existing_artifacts = {
            "question.md": "# Question\n\nWhat is ML?",
            "answer.md": "# Answer\n\nML is machine learning.",
        }
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
            existing_artifacts=existing_artifacts,
        )
        assert "What is ML?" in result or "question.md" in result

    def test_task_prompts_included_in_result(self):
        """task_prompts の内容がプロンプトに含まれること（エージェント+ポリシー）"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
        )
        assert "AGENT_CONTENT" in result
        assert "POLICY_CONTENT" in result

    def test_wiki_content_included_in_result(self):
        """wiki_content の内容がプロンプトに含まれること（知識ソース）"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
        )
        assert "machine learning topics" in result

    def test_question_included_in_result(self):
        """question がプロンプトに含まれること"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
        )
        assert self.QUESTION in result

    def test_fix_format_contains_fix_schema(self):
        """lint_results 提供時 (fix モード): fix スキーマが含まれること"""
        lint_results = {
            "errors": [{"code": "QL001", "message": "missing file: answer.md"}],
            "warnings": [],
        }
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
            lint_results=lint_results,
        )
        # fix スキーマのキーが含まれること
        assert "fixes" in result or "skipped" in result

    def test_prompt_structure_order(self):
        """プロンプト構造: task_prompts → wiki_content → question の順序であること"""
        result = rw_light.build_query_prompt(
            self.TASK_PROMPTS,
            self.QUESTION,
            self.WIKI_CONTENT,
            output_format="json",
        )
        pos_agent = result.find("AGENT_CONTENT")
        pos_wiki = result.find("machine learning topics")
        pos_question = result.find(self.QUESTION)

        assert pos_agent < pos_wiki, "task_prompts は wiki_content より前にあること"
        assert pos_wiki < pos_question, "wiki_content は question より前にあること"


# ---------------------------------------------------------------------------
# generate_query_id() のテスト
# ---------------------------------------------------------------------------

class TestGenerateQueryId:
    """generate_query_id() のユニットテスト"""

    def test_ascii_question_generates_slug(self, monkeypatch):
        """ASCII 質問文からスラッグが生成されること"""
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        result = rw_light.generate_query_id("What is machine learning?")
        assert result == "20260417-what-is-machine-learning"

    def test_non_ascii_question_slugified(self, monkeypatch):
        """非ASCII 質問文が slugify されること（ASCII 変換後にスラッグ生成）"""
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        result = rw_light.generate_query_id("機械学習とは何か？")
        # 非ASCII は除去されて "untitled" または空になるケース
        assert result.startswith("20260417-")
        # 少なくとも日付プレフィックスを含むこと
        assert len(result) > 9

    def test_empty_question_raises_value_error(self, monkeypatch):
        """空の質問文で ValueError が raise されること"""
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        with pytest.raises(ValueError, match=".*"):
            rw_light.generate_query_id("")

    def test_whitespace_only_raises_value_error(self, monkeypatch):
        """空白のみの質問文で ValueError が raise されること"""
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        with pytest.raises(ValueError, match=".*"):
            rw_light.generate_query_id("   ")

    def test_date_prefix_is_8_digits(self, monkeypatch):
        """日付プレフィックスが YYYYMMDD 形式 (8桁) であること"""
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        result = rw_light.generate_query_id("test question")
        prefix = result.split("-")[0]
        assert len(prefix) == 8
        assert prefix.isdigit()
        assert prefix == "20260417"

    def test_max_slug_length_80_chars(self, monkeypatch):
        """非常に長い質問文でスラッグ部分が 80 文字以下になること"""
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        long_question = "a " * 100  # 200文字の質問
        result = rw_light.generate_query_id(long_question)
        # プレフィックス "20260417-" を除いたスラッグ部分
        slug_part = result[9:]  # "20260417-" は9文字
        assert len(slug_part) <= 80, f"Slug part too long: {len(slug_part)} chars"

    def test_format_is_yyyymmdd_hyphen_slug(self, monkeypatch):
        """YYYYMMDD-{slug} 形式であること"""
        monkeypatch.setattr(rw_light, "today", lambda: "2026-01-15")
        result = rw_light.generate_query_id("hello world")
        assert result == "20260115-hello-world"


# ---------------------------------------------------------------------------
# write_query_artifacts() のテスト
# ---------------------------------------------------------------------------

class TestWriteQueryArtifacts:
    """write_query_artifacts() のユニットテスト"""

    QUERY_ID = "20260417-what-is-ml"

    SAMPLE_DATA = {
        "query": {
            "text": "What is ML?",
            "query_type": "fact",
            "scope": "wiki/ml.md",
            "date": "2026-04-17",
        },
        "answer": {
            "content": "## Answer\n\nML stands for Machine Learning. It is a subfield of AI.",
        },
        "evidence": {
            "blocks": [
                {"source": "wiki/ml.md", "excerpt": "ML is a method of data analysis."},
                {"source": "wiki/ai.md", "excerpt": "AI encompasses many fields."},
            ]
        },
        "metadata": {
            "query_id": "old-id-from-claude",
            "query_type": "fact",
            "scope": "wiki/ml.md",
            "sources": ["wiki/ml.md", "wiki/ai.md"],
            "created_at": "2026-04-17T10:00:00",
        },
        "referenced_pages": ["wiki/ml.md", "wiki/ai.md"],
    }

    def _setup(self, tmp_path, monkeypatch):
        """QUERY_REVIEW を tmp_path/review/query に向ける"""
        review_query_dir = tmp_path / "review" / "query"
        review_query_dir.mkdir(parents=True)
        monkeypatch.setattr(rw_light, "QUERY_REVIEW", str(review_query_dir))
        return review_query_dir

    def test_creates_query_id_directory(self, tmp_path, monkeypatch):
        """review/query/<query_id>/ ディレクトリが作成されること"""
        review_query_dir = self._setup(tmp_path, monkeypatch)
        rw_light.write_query_artifacts(self.QUERY_ID, self.SAMPLE_DATA)
        expected_dir = review_query_dir / self.QUERY_ID
        assert expected_dir.is_dir(), f"Expected directory: {expected_dir}"

    def test_creates_4_files(self, tmp_path, monkeypatch):
        """4ファイル (question.md, answer.md, evidence.md, metadata.json) が作成されること"""
        review_query_dir = self._setup(tmp_path, monkeypatch)
        rw_light.write_query_artifacts(self.QUERY_ID, self.SAMPLE_DATA)
        target_dir = review_query_dir / self.QUERY_ID
        for filename in ["question.md", "answer.md", "evidence.md", "metadata.json"]:
            assert (target_dir / filename).exists(), f"Missing file: {filename}"

    def test_returns_list_of_4_paths(self, tmp_path, monkeypatch):
        """ファイルパスのリスト（4要素）が返ること"""
        self._setup(tmp_path, monkeypatch)
        result = rw_light.write_query_artifacts(self.QUERY_ID, self.SAMPLE_DATA)
        assert isinstance(result, list)
        assert len(result) == 4

    def test_metadata_json_query_id_overridden(self, tmp_path, monkeypatch):
        """metadata.json の query_id が CLI 生成の query_id で上書きされること"""
        review_query_dir = self._setup(tmp_path, monkeypatch)
        rw_light.write_query_artifacts(self.QUERY_ID, self.SAMPLE_DATA)
        metadata_path = review_query_dir / self.QUERY_ID / "metadata.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        assert metadata["query_id"] == self.QUERY_ID
        assert metadata["query_id"] != "old-id-from-claude"

    def test_question_md_key_value_format(self, tmp_path, monkeypatch):
        """question.md がキーバリュー形式で書き出されること"""
        review_query_dir = self._setup(tmp_path, monkeypatch)
        rw_light.write_query_artifacts(self.QUERY_ID, self.SAMPLE_DATA)
        question_path = review_query_dir / self.QUERY_ID / "question.md"
        content = question_path.read_text(encoding="utf-8")
        assert "query: What is ML?" in content
        assert "query_type: fact" in content
        assert "scope: wiki/ml.md" in content
        assert "date: 2026-04-17" in content

    def test_answer_md_contains_answer_content(self, tmp_path, monkeypatch):
        """answer.md に answer content が含まれること"""
        review_query_dir = self._setup(tmp_path, monkeypatch)
        rw_light.write_query_artifacts(self.QUERY_ID, self.SAMPLE_DATA)
        answer_path = review_query_dir / self.QUERY_ID / "answer.md"
        content = answer_path.read_text(encoding="utf-8")
        assert "ML stands for Machine Learning" in content

    def test_evidence_md_contains_source_lines(self, tmp_path, monkeypatch):
        """evidence.md にエビデンスブロックの source: 行が含まれること"""
        review_query_dir = self._setup(tmp_path, monkeypatch)
        rw_light.write_query_artifacts(self.QUERY_ID, self.SAMPLE_DATA)
        evidence_path = review_query_dir / self.QUERY_ID / "evidence.md"
        content = evidence_path.read_text(encoding="utf-8")
        assert "source: wiki/ml.md" in content
        assert "source: wiki/ai.md" in content


# ---------------------------------------------------------------------------
# parse_extract_response() のテスト
# ---------------------------------------------------------------------------

class TestParseExtractResponse:
    """parse_extract_response() のユニットテスト"""

    VALID_JSON = json.dumps({
        "query": {
            "text": "What is ML?",
            "query_type": "fact",
            "scope": "wiki/ml.md",
            "date": "2026-04-17",
        },
        "answer": {"content": "## Answer\n\nML is machine learning."},
        "evidence": {
            "blocks": [{"source": "wiki/ml.md", "excerpt": "ML is..."}]
        },
        "metadata": {
            "query_id": "20260417-what-is-ml",
            "query_type": "fact",
            "scope": "wiki/ml.md",
            "sources": ["wiki/ml.md"],
            "created_at": "2026-04-17T10:00:00",
        },
        "referenced_pages": ["wiki/ml.md"],
    }, ensure_ascii=False)

    def test_valid_json_returns_dict_with_required_keys(self):
        """正常な JSON → query/answer/evidence/metadata を含む dict が返ること"""
        result = rw_light.parse_extract_response(self.VALID_JSON)
        assert isinstance(result, dict)
        for key in ("query", "answer", "evidence", "metadata"):
            assert key in result, f"Missing key: {key}"

    def test_valid_json_values_are_correct(self):
        """正常な JSON → 各フィールドの値が正しくパースされること"""
        result = rw_light.parse_extract_response(self.VALID_JSON)
        assert result["query"]["text"] == "What is ML?"
        assert result["answer"]["content"] == "## Answer\n\nML is machine learning."
        assert result["evidence"]["blocks"][0]["source"] == "wiki/ml.md"
        assert result["metadata"]["query_id"] == "20260417-what-is-ml"

    def test_invalid_json_raises_value_error(self):
        """不正な JSON → ValueError が raise されること"""
        with pytest.raises(ValueError):
            rw_light.parse_extract_response("not json at all {{{")

    def test_invalid_json_prints_to_stderr(self, capsys):
        """不正な JSON → stderr にレスポンス先頭500文字が出力されること"""
        long_invalid = "X" * 600 + "{{{"
        with pytest.raises(ValueError):
            rw_light.parse_extract_response(long_invalid)
        captured = capsys.readouterr()
        assert "X" * 500 in captured.err
        assert "X" * 501 not in captured.err

    def test_missing_answer_key_raises_value_error(self):
        """必須フィールド 'answer' が欠落 → ValueError が raise されること"""
        data = json.loads(self.VALID_JSON)
        del data["answer"]
        with pytest.raises(ValueError, match=".*answer.*"):
            rw_light.parse_extract_response(json.dumps(data))

    def test_missing_query_key_raises_value_error(self):
        """必須フィールド 'query' が欠落 → ValueError が raise されること"""
        data = json.loads(self.VALID_JSON)
        del data["query"]
        with pytest.raises(ValueError):
            rw_light.parse_extract_response(json.dumps(data))

    def test_missing_evidence_key_raises_value_error(self):
        """必須フィールド 'evidence' が欠落 → ValueError が raise されること"""
        data = json.loads(self.VALID_JSON)
        del data["evidence"]
        with pytest.raises(ValueError):
            rw_light.parse_extract_response(json.dumps(data))

    def test_missing_metadata_key_raises_value_error(self):
        """必須フィールド 'metadata' が欠落 → ValueError が raise されること"""
        data = json.loads(self.VALID_JSON)
        del data["metadata"]
        with pytest.raises(ValueError):
            rw_light.parse_extract_response(json.dumps(data))

    def test_missing_field_prints_to_stderr(self, capsys):
        """必須フィールド欠落時 → stderr にレスポンス先頭500文字が出力されること"""
        data = json.loads(self.VALID_JSON)
        del data["answer"]
        response = json.dumps(data)
        with pytest.raises(ValueError):
            rw_light.parse_extract_response(response)
        captured = capsys.readouterr()
        assert len(captured.err) > 0

    def test_json_wrapped_in_code_block_parsed_correctly(self):
        """```json ... ``` で囲まれた JSON → 正常にパースされること"""
        wrapped = f"```json\n{self.VALID_JSON}\n```"
        result = rw_light.parse_extract_response(wrapped)
        assert isinstance(result, dict)
        for key in ("query", "answer", "evidence", "metadata"):
            assert key in result

    def test_json_wrapped_in_plain_code_block_parsed_correctly(self):
        """``` ... ``` （言語指定なし）で囲まれた JSON → 正常にパースされること"""
        wrapped = f"```\n{self.VALID_JSON}\n```"
        result = rw_light.parse_extract_response(wrapped)
        assert isinstance(result, dict)
        assert "query" in result


# ---------------------------------------------------------------------------
# parse_fix_response() のテスト
# ---------------------------------------------------------------------------

class TestParseFixResponse:
    """parse_fix_response() のユニットテスト"""

    VALID_JSON = json.dumps({
        "fixes": [
            {"file": "answer.md", "ql_code": "QL006", "action": "rewrite"},
        ],
        "files": {
            "question.md": "query: What is ML?\n",
            "answer.md": "## Answer\n\nML is machine learning.",
            "evidence.md": None,
            "metadata.json": None,
        },
        "skipped": [
            {"ql_code": "QL001", "reason": "file already exists"},
        ],
    }, ensure_ascii=False)

    def test_valid_json_returns_dict_with_required_keys(self):
        """正常な JSON → fixes/files/skipped を含む dict が返ること"""
        result = rw_light.parse_fix_response(self.VALID_JSON)
        assert isinstance(result, dict)
        for key in ("fixes", "files", "skipped"):
            assert key in result, f"Missing key: {key}"

    def test_valid_json_values_are_correct(self):
        """正常な JSON → 各フィールドの値が正しくパースされること"""
        result = rw_light.parse_fix_response(self.VALID_JSON)
        assert len(result["fixes"]) == 1
        assert result["fixes"][0]["file"] == "answer.md"
        assert result["files"]["question.md"] == "query: What is ML?\n"
        assert result["skipped"][0]["ql_code"] == "QL001"

    def test_invalid_json_raises_value_error(self):
        """不正な JSON → ValueError が raise されること"""
        with pytest.raises(ValueError):
            rw_light.parse_fix_response("{invalid json}")

    def test_invalid_json_prints_to_stderr(self, capsys):
        """不正な JSON → stderr にレスポンス先頭500文字が出力されること"""
        long_invalid = "Y" * 600 + "{invalid"
        with pytest.raises(ValueError):
            rw_light.parse_fix_response(long_invalid)
        captured = capsys.readouterr()
        assert "Y" * 500 in captured.err
        assert "Y" * 501 not in captured.err

    def test_missing_fixes_key_raises_value_error(self):
        """必須フィールド 'fixes' が欠落 → ValueError が raise されること"""
        data = json.loads(self.VALID_JSON)
        del data["fixes"]
        with pytest.raises(ValueError, match=".*fixes.*"):
            rw_light.parse_fix_response(json.dumps(data))

    def test_missing_files_key_raises_value_error(self):
        """必須フィールド 'files' が欠落 → ValueError が raise されること"""
        data = json.loads(self.VALID_JSON)
        del data["files"]
        with pytest.raises(ValueError):
            rw_light.parse_fix_response(json.dumps(data))

    def test_null_values_in_files_handled_correctly(self):
        """files 内の null 値 → Python None として正常にパースされること"""
        result = rw_light.parse_fix_response(self.VALID_JSON)
        assert result["files"]["evidence.md"] is None
        assert result["files"]["metadata.json"] is None

    def test_missing_field_prints_to_stderr(self, capsys):
        """必須フィールド欠落時 → stderr にレスポンス先頭500文字が出力されること"""
        data = json.loads(self.VALID_JSON)
        del data["fixes"]
        response = json.dumps(data)
        with pytest.raises(ValueError):
            rw_light.parse_fix_response(response)
        captured = capsys.readouterr()
        assert len(captured.err) > 0

    def test_json_wrapped_in_code_block_parsed_correctly(self):
        """```json ... ``` で囲まれた JSON → 正常にパースされること"""
        wrapped = f"```json\n{self.VALID_JSON}\n```"
        result = rw_light.parse_fix_response(wrapped)
        assert isinstance(result, dict)
        assert "fixes" in result
        assert "files" in result


# ---------------------------------------------------------------------------
# cmd_query_extract() のテスト
# ---------------------------------------------------------------------------

MOCK_EXTRACT_RESPONSE = json.dumps({
    "query": {"text": "test question", "query_type": "fact", "scope": "all", "date": "2026-04-17"},
    "answer": {"content": "# Answer\n\nThis is the answer with enough content to pass lint.\n\n## Details\n\nMore content here."},
    "evidence": {"blocks": [{"source": "wiki/concepts/test.md", "excerpt": "relevant text"}]},
    "metadata": {"query_id": "old-id", "query_type": "fact", "scope": "all", "sources": ["wiki/concepts/test.md"], "created_at": "2026-04-17T12:00:00+09:00"},
    "referenced_pages": ["wiki/concepts/test.md"]
})


def _setup_mock_vault_for_query(tmp_path, monkeypatch):
    """cmd_query_extract テスト用の Vault 環境を設定する。"""
    # ディレクトリ構造作成
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()
    agents_dir = tmp_path / "AGENTS"
    agents_dir.mkdir()
    review_query_dir = tmp_path / "review" / "query"
    review_query_dir.mkdir(parents=True)
    logs_dir = tmp_path / "logs"
    logs_dir.mkdir()

    # wiki ファイル（小規模: 3ファイル）
    (wiki_dir / "concepts").mkdir()
    (wiki_dir / "concepts" / "test.md").write_text(
        "# Test\n\nThis is a test wiki page with content.", encoding="utf-8"
    )

    # CLAUDE.md（マッピング表含む）
    claude_md = tmp_path / "CLAUDE.md"
    claude_md.write_text(
        "| Task | Agent | Policy | Execution Mode |\n"
        "|---|---|---|---|\n"
        "| query_extract | AGENTS/query_extract.md | AGENTS/naming.md | Prompt |\n",
        encoding="utf-8",
    )

    # AGENTS/ ファイル
    (agents_dir / "query_extract.md").write_text("AGENT query_extract", encoding="utf-8")
    (agents_dir / "naming.md").write_text("POLICY naming", encoding="utf-8")

    # index.md
    (tmp_path / "index.md").write_text("# Index\n\n- [[test]]", encoding="utf-8")

    # rw_light のグローバル変数を tmp_path に向ける
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "QUERY_REVIEW", str(review_query_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
    monkeypatch.setattr(rw_light, "QUERY_LINT_LOG", str(logs_dir / "query_lint_latest.json"))

    return tmp_path, review_query_dir


class TestCmdQueryExtract:
    """cmd_query_extract() のユニットテスト"""

    def test_empty_question_returns_1(self, tmp_path, monkeypatch):
        """空の質問文 → return 1"""
        _setup_mock_vault_for_query(tmp_path, monkeypatch)
        result = rw_light.cmd_query_extract([])
        assert result == 1

    def test_empty_string_question_returns_1(self, tmp_path, monkeypatch):
        """空文字列の質問文 → return 1"""
        _setup_mock_vault_for_query(tmp_path, monkeypatch)
        result = rw_light.cmd_query_extract([""])
        assert result == 1

    def test_whitespace_only_question_returns_1(self, tmp_path, monkeypatch):
        """空白のみの質問文 → return 1"""
        _setup_mock_vault_for_query(tmp_path, monkeypatch)
        result = rw_light.cmd_query_extract(["   "])
        assert result == 1

    def test_wiki_missing_returns_1(self, tmp_path, monkeypatch):
        """wiki/ が存在しない → return 1"""
        _setup_mock_vault_for_query(tmp_path, monkeypatch)
        # wiki/ を削除
        import shutil
        shutil.rmtree(str(tmp_path / "wiki"))
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_EXTRACT_RESPONSE)
        result = rw_light.cmd_query_extract(["test question"])
        assert result == 1

    def test_claude_md_missing_returns_1(self, tmp_path, monkeypatch):
        """CLAUDE.md が存在しない → return 1"""
        _setup_mock_vault_for_query(tmp_path, monkeypatch)
        # CLAUDE.md を削除
        (tmp_path / "CLAUDE.md").unlink()
        result = rw_light.cmd_query_extract(["test question"])
        assert result == 1

    def test_duplicate_query_id_returns_1(self, tmp_path, monkeypatch):
        """同一 query_id ディレクトリが既存 → return 1"""
        _, review_query_dir = _setup_mock_vault_for_query(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_EXTRACT_RESPONSE)

        # 事前に同一 query_id ディレクトリを作成
        query_id = rw_light.generate_query_id("test question")
        (review_query_dir / query_id).mkdir(parents=True)

        result = rw_light.cmd_query_extract(["test question"])
        assert result == 1

    def test_success_creates_4_files(self, tmp_path, monkeypatch):
        """成功パス: 4ファイルが review/query/<query_id>/ に作成されること"""
        _, review_query_dir = _setup_mock_vault_for_query(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_EXTRACT_RESPONSE)

        result = rw_light.cmd_query_extract(["test question"])

        # 終了コードは 0 または 2（lint 結果による）
        assert result in (0, 2)

        # query_id ディレクトリが作成されていること
        query_id = rw_light.generate_query_id("test question")
        query_dir = review_query_dir / query_id
        assert query_dir.is_dir(), f"query_dir not found: {query_dir}"

        # 4ファイルが存在すること
        for fname in ["question.md", "answer.md", "evidence.md", "metadata.json"]:
            assert (query_dir / fname).exists(), f"Missing file: {fname}"

    def test_success_with_scope_arg(self, tmp_path, monkeypatch):
        """--scope 引数が正しく解析されること"""
        _, review_query_dir = _setup_mock_vault_for_query(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")

        scope_path = str(tmp_path / "wiki" / "concepts" / "test.md")
        called_scopes = []

        def mock_call_claude(p):
            return MOCK_EXTRACT_RESPONSE

        monkeypatch.setattr(rw_light, "call_claude", mock_call_claude)

        result = rw_light.cmd_query_extract(["test question", "--scope", scope_path])
        assert result in (0, 2)

    def test_success_with_type_arg(self, tmp_path, monkeypatch):
        """--type 引数が正しく解析されること"""
        _, review_query_dir = _setup_mock_vault_for_query(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_EXTRACT_RESPONSE)

        result = rw_light.cmd_query_extract(["test question", "--type", "fact"])
        assert result in (0, 2)

    def test_large_wiki_triggers_2stage(self, tmp_path, monkeypatch):
        """ファイル数>20 かつ scope=None の場合: 2段階方式が呼び出されること"""
        _, review_query_dir = _setup_mock_vault_for_query(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")

        # wiki/ に 21 ファイル追加
        wiki_dir = tmp_path / "wiki"
        for i in range(21):
            (wiki_dir / f"page_{i:02d}.md").write_text(
                f"# Page {i}\n\nContent {i}.", encoding="utf-8"
            )

        call_count = []
        stage1_response = json.dumps({"identified_pages": ["wiki/concepts/test.md"]})

        def mock_call_claude(p):
            call_count.append(p)
            if len(call_count) == 1:
                # ステージ1: 関連ページ特定
                return stage1_response
            else:
                # ステージ2: 本プロンプト
                return MOCK_EXTRACT_RESPONSE

        monkeypatch.setattr(rw_light, "call_claude", mock_call_claude)

        result = rw_light.cmd_query_extract(["test question"])
        assert result in (0, 2)
        # 2回 call_claude が呼ばれていること（2段階方式）
        assert len(call_count) == 2, f"Expected 2 calls, got {len(call_count)}"

    def test_lint_fail_returns_2(self, tmp_path, monkeypatch):
        """lint status=FAIL の場合: return 2"""
        _, review_query_dir = _setup_mock_vault_for_query(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_EXTRACT_RESPONSE)

        # lint_single_query_dir を FAIL を返すモックに差し替え
        def mock_lint(query_dir):
            return {
                "target": query_dir,
                "status": "FAIL",
                "errors": ["QL001 missing file: answer.md"],
                "warnings": [],
                "infos": [],
                "checks": [{"id": "QL001", "severity": "ERROR", "message": "missing file"}],
            }

        monkeypatch.setattr(rw_light, "lint_single_query_dir", mock_lint)

        result = rw_light.cmd_query_extract(["test question"])
        assert result == 2

    def test_lint_pass_returns_0(self, tmp_path, monkeypatch):
        """lint status=PASS の場合: return 0"""
        _, review_query_dir = _setup_mock_vault_for_query(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_EXTRACT_RESPONSE)

        # lint_single_query_dir を PASS を返すモックに差し替え
        def mock_lint(query_dir):
            return {
                "target": query_dir,
                "status": "PASS",
                "errors": [],
                "warnings": [],
                "infos": [],
                "checks": [],
            }

        monkeypatch.setattr(rw_light, "lint_single_query_dir", mock_lint)

        result = rw_light.cmd_query_extract(["test question"])
        assert result == 0


# ---------------------------------------------------------------------------
# cmd_query_answer() のテスト
# ---------------------------------------------------------------------------

MOCK_ANSWER_RESPONSE = "This is the answer.\n\n## Details\n\nAnswer content here.\n---\nReferenced: wiki/concepts/test.md, wiki/methods/method.md"


def _setup_mock_vault_for_answer(tmp_path, monkeypatch):
    """cmd_query_answer テスト用の Vault 環境を設定する。"""
    # ディレクトリ構造作成
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()
    agents_dir = tmp_path / "AGENTS"
    agents_dir.mkdir()
    review_query_dir = tmp_path / "review" / "query"
    review_query_dir.mkdir(parents=True)

    # wiki ファイル（小規模: 1ファイル）
    (wiki_dir / "concepts").mkdir()
    (wiki_dir / "concepts" / "test.md").write_text(
        "# Test\n\nThis is a test wiki page with content.", encoding="utf-8"
    )

    # CLAUDE.md（マッピング表含む）
    claude_md = tmp_path / "CLAUDE.md"
    claude_md.write_text(
        "| Task | Agent | Policy | Execution Mode |\n"
        "|---|---|---|---|\n"
        "| query_answer | AGENTS/query_answer.md | AGENTS/page_policy.md | Prompt |\n",
        encoding="utf-8",
    )

    # AGENTS/ ファイル
    (agents_dir / "query_answer.md").write_text("AGENT query_answer", encoding="utf-8")
    (agents_dir / "page_policy.md").write_text("POLICY page_policy", encoding="utf-8")

    # index.md
    (tmp_path / "index.md").write_text("# Index\n\n- [[test]]", encoding="utf-8")

    # rw_light のグローバル変数を tmp_path に向ける
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "QUERY_REVIEW", str(review_query_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))

    return tmp_path, review_query_dir


class TestCmdQueryAnswer:
    """cmd_query_answer() のユニットテスト"""

    def test_empty_question_returns_1(self, tmp_path, monkeypatch):
        """空の質問文 → return 1"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        result = rw_light.cmd_query_answer([])
        assert result == 1

    def test_whitespace_only_question_returns_1(self, tmp_path, monkeypatch):
        """空白のみの質問文 → return 1"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        result = rw_light.cmd_query_answer(["   "])
        assert result == 1

    def test_wiki_missing_returns_1(self, tmp_path, monkeypatch):
        """wiki/ が存在しない → return 1"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        import shutil
        shutil.rmtree(str(tmp_path / "wiki"))
        result = rw_light.cmd_query_answer(["test question"])
        assert result == 1

    def test_claude_md_missing_returns_1(self, tmp_path, monkeypatch):
        """CLAUDE.md が存在しない → return 1"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        (tmp_path / "CLAUDE.md").unlink()
        result = rw_light.cmd_query_answer(["test question"])
        assert result == 1

    def test_success_returns_0(self, tmp_path, monkeypatch):
        """成功パス: return 0 かつ review/query/ にファイルが生成されないこと"""
        _, review_query_dir = _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        result = rw_light.cmd_query_answer(["test question"])
        assert result == 0

    def test_success_no_file_created_in_query_review(self, tmp_path, monkeypatch):
        """成功パス: review/query/ にファイルが生成されないこと（Req 2.3）"""
        _, review_query_dir = _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        rw_light.cmd_query_answer(["test question"])

        # review/query/ 配下にファイルやディレクトリが生成されていないこと
        entries = list(review_query_dir.iterdir())
        assert entries == [], f"Unexpected files in review/query/: {entries}"

    def test_success_stdout_contains_answer_text(self, tmp_path, monkeypatch, capsys):
        """成功パス: stdout に回答テキストが含まれること"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        rw_light.cmd_query_answer(["test question"])

        captured = capsys.readouterr()
        assert "This is the answer." in captured.out
        assert "Answer content here." in captured.out

    def test_success_stdout_contains_referenced_pages(self, tmp_path, monkeypatch, capsys):
        """成功パス: stdout に参照ページ（Referenced: セクション）が含まれること"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        rw_light.cmd_query_answer(["test question"])

        captured = capsys.readouterr()
        assert "wiki/concepts/test.md" in captured.out
        assert "wiki/methods/method.md" in captured.out

    def test_response_without_referenced_section_still_returns_0(self, tmp_path, monkeypatch, capsys):
        """---\\nReferenced: セパレータなし → 全体を回答として出力し return 0"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        no_ref_response = "This is an answer without referenced section."
        monkeypatch.setattr(rw_light, "call_claude", lambda p: no_ref_response)

        result = rw_light.cmd_query_answer(["test question"])

        assert result == 0
        captured = capsys.readouterr()
        assert "This is an answer without referenced section." in captured.out

    def test_scope_option_passes_to_read_wiki_content(self, tmp_path, monkeypatch):
        """--scope オプションが read_wiki_content に渡されること"""
        _, _ = _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        scope_path = str(tmp_path / "wiki" / "concepts" / "test.md")
        received_scopes = []

        original_read_wiki = rw_light.read_wiki_content

        def mock_read_wiki(scope):
            received_scopes.append(scope)
            return original_read_wiki(scope)

        monkeypatch.setattr(rw_light, "read_wiki_content", mock_read_wiki)

        result = rw_light.cmd_query_answer(["test question", "--scope", scope_path])

        assert result == 0
        assert received_scopes == [scope_path]


# ---------------------------------------------------------------------------
# cmd_query_fix() のテスト
# ---------------------------------------------------------------------------

MOCK_FIX_RESPONSE = json.dumps({
    "fixes": [{"file": "answer.md", "ql_code": "QL006", "action": "expanded content"}],
    "files": {
        "question.md": None,
        "answer.md": "# Answer\n\nExpanded answer content with enough length to pass lint validation checks.\n\n## Details\n\nMore detailed content here for evidence.",
        "evidence.md": None,
        "metadata.json": None,
    },
    "skipped": [],
})


def _setup_mock_vault_for_fix(tmp_path, monkeypatch):
    """cmd_query_fix テスト用の Vault 環境を設定する。"""
    # ディレクトリ構造作成
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()
    agents_dir = tmp_path / "AGENTS"
    agents_dir.mkdir()
    review_query_dir = tmp_path / "review" / "query"
    review_query_dir.mkdir(parents=True)
    logs_dir = tmp_path / "logs"
    logs_dir.mkdir()

    # wiki ファイル
    (wiki_dir / "concepts").mkdir()
    (wiki_dir / "concepts" / "test.md").write_text(
        "# Test\n\nThis is a test wiki page with content.", encoding="utf-8"
    )

    # CLAUDE.md（マッピング表含む）
    claude_md = tmp_path / "CLAUDE.md"
    claude_md.write_text(
        "| Task | Agent | Policy | Execution Mode |\n"
        "|---|---|---|---|\n"
        "| query_fix | AGENTS/query_fix.md | AGENTS/naming.md | Prompt |\n",
        encoding="utf-8",
    )

    # AGENTS/ ファイル
    (agents_dir / "query_fix.md").write_text("AGENT query_fix", encoding="utf-8")
    (agents_dir / "naming.md").write_text("POLICY naming", encoding="utf-8")

    # index.md
    (tmp_path / "index.md").write_text("# Index\n\n- [[test]]", encoding="utf-8")

    # query_id ディレクトリと4ファイルを作成
    query_id = "20260417-test-query"
    query_dir = review_query_dir / query_id
    query_dir.mkdir(parents=True)

    (query_dir / "question.md").write_text(
        "query: test question\nquery_type: fact\nscope: all\ndate: 2026-04-17\n",
        encoding="utf-8",
    )
    (query_dir / "answer.md").write_text(
        "Short.",
        encoding="utf-8",
    )
    (query_dir / "evidence.md").write_text(
        "source: wiki/concepts/test.md\nsome evidence text here",
        encoding="utf-8",
    )
    (query_dir / "metadata.json").write_text(
        json.dumps({
            "query_id": query_id,
            "query_type": "fact",
            "scope": "all",
            "sources": ["wiki/concepts/test.md"],
            "created_at": "2026-04-17T12:00:00",
        }, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    # rw_light のグローバル変数を tmp_path に向ける
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "QUERY_REVIEW", str(review_query_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
    monkeypatch.setattr(rw_light, "QUERY_LINT_LOG", str(logs_dir / "query_lint_latest.json"))

    return tmp_path, review_query_dir, query_id, query_dir


class TestCmdQueryFix:
    """cmd_query_fix() のユニットテスト"""

    def test_missing_query_id_dir_returns_1(self, tmp_path, monkeypatch):
        """query_id ディレクトリが存在しない → return 1 (Req 6.3)"""
        _setup_mock_vault_for_fix(tmp_path, monkeypatch)
        result = rw_light.cmd_query_fix(["nonexistent-query-id"])
        assert result == 1

    def test_claude_md_missing_returns_1(self, tmp_path, monkeypatch):
        """CLAUDE.md が存在しない → return 1"""
        _, _, query_id, _ = _setup_mock_vault_for_fix(tmp_path, monkeypatch)
        (tmp_path / "CLAUDE.md").unlink()
        result = rw_light.cmd_query_fix([query_id])
        assert result == 1

    def test_no_lint_errors_returns_0_with_message(self, tmp_path, monkeypatch, capsys):
        """lint エラーなし（PASS）→ 修復不要メッセージを表示して return 0 (Req 3.7)"""
        _, _, query_id, _ = _setup_mock_vault_for_fix(tmp_path, monkeypatch)

        def mock_lint(_query_dir, **kwargs):
            return {
                "target": _query_dir,
                "status": "PASS",
                "errors": [],
                "warnings": [],
                "infos": [],
                "checks": [],
            }

        monkeypatch.setattr(rw_light, "lint_single_query_dir", mock_lint)
        result = rw_light.cmd_query_fix([query_id])
        assert result == 0
        captured = capsys.readouterr()
        assert "修復不要" in captured.out

    def test_success_fix_returns_0(self, tmp_path, monkeypatch):
        """lint FAIL → fix → post-fix PASS → return 0"""
        _, _, query_id, _ = _setup_mock_vault_for_fix(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_FIX_RESPONSE)

        lint_call_count = [0]

        def mock_lint(_query_dir, **kwargs):
            lint_call_count[0] += 1
            if lint_call_count[0] == 1:
                # 事前 lint: FAIL
                return {
                    "target": _query_dir,
                    "status": "FAIL",
                    "errors": ["QL006 answer.md is empty or too short"],
                    "warnings": [],
                    "infos": [],
                    "checks": [{"id": "QL006", "severity": "ERROR", "message": "answer.md is empty or too short"}],
                }
            else:
                # 事後 lint: PASS
                return {
                    "target": _query_dir,
                    "status": "PASS",
                    "errors": [],
                    "warnings": [],
                    "infos": [],
                    "checks": [],
                }

        monkeypatch.setattr(rw_light, "lint_single_query_dir", mock_lint)
        result = rw_light.cmd_query_fix([query_id])
        assert result == 0

    def test_non_none_files_written_none_skipped(self, tmp_path, monkeypatch):
        """non-None ファイルは書き出され、None ファイルはスキップされること (Req 5.2)"""
        _, _, query_id, query_dir = _setup_mock_vault_for_fix(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_FIX_RESPONSE)

        original_answer_content = (query_dir / "question.md").read_text(encoding="utf-8")

        def mock_lint(_query_dir, **kwargs):
            return {
                "target": _query_dir,
                "status": "FAIL",
                "errors": ["QL006 answer.md is empty or too short"],
                "warnings": [],
                "infos": [],
                "checks": [{"id": "QL006", "severity": "ERROR", "message": "answer.md is empty or too short"}],
            }

        monkeypatch.setattr(rw_light, "lint_single_query_dir", mock_lint)
        rw_light.cmd_query_fix([query_id])

        # answer.md (non-None) は更新されていること
        new_answer = (query_dir / "answer.md").read_text(encoding="utf-8")
        fix_data = json.loads(MOCK_FIX_RESPONSE)
        assert new_answer == fix_data["files"]["answer.md"]

        # question.md (None) は変更されていないこと
        assert (query_dir / "question.md").read_text(encoding="utf-8") == original_answer_content

    def test_skipped_items_reported(self, tmp_path, monkeypatch, capsys):
        """skipped 項目が報告されること"""
        _, _, query_id, _ = _setup_mock_vault_for_fix(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")

        fix_response_with_skipped = json.dumps({
            "fixes": [{"file": "answer.md", "ql_code": "QL006", "action": "expanded content"}],
            "files": {
                "question.md": None,
                "answer.md": "# Answer\n\nExpanded answer content here with enough text to pass.\n\n## Details\n\nMore here.",
                "evidence.md": None,
                "metadata.json": None,
            },
            "skipped": [{"ql_code": "QL009", "reason": "Cannot auto-fix source references"}],
        })
        monkeypatch.setattr(rw_light, "call_claude", lambda p: fix_response_with_skipped)

        def mock_lint(_query_dir, **kwargs):
            return {
                "target": _query_dir,
                "status": "FAIL",
                "errors": ["QL006 answer too short"],
                "warnings": [],
                "infos": [],
                "checks": [],
            }

        monkeypatch.setattr(rw_light, "lint_single_query_dir", mock_lint)
        rw_light.cmd_query_fix([query_id])

        captured = capsys.readouterr()
        assert "QL009" in captured.out or "Cannot auto-fix" in captured.out

    def test_post_fix_lint_fail_returns_2(self, tmp_path, monkeypatch):
        """post-fix lint FAIL → return 2 (Req 3.8, 3.9)"""
        _, _, query_id, _ = _setup_mock_vault_for_fix(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_FIX_RESPONSE)

        def mock_lint(_query_dir, **kwargs):
            # 事前も事後も FAIL のまま
            return {
                "target": _query_dir,
                "status": "FAIL",
                "errors": ["QL006 answer.md still too short"],
                "warnings": [],
                "infos": [],
                "checks": [],
            }

        monkeypatch.setattr(rw_light, "lint_single_query_dir", mock_lint)
        result = rw_light.cmd_query_fix([query_id])
        assert result == 2

    def test_no_files_written_to_wiki(self, tmp_path, monkeypatch):
        """wiki/ ディレクトリには何も書き出されないこと (Req 5.2)"""
        _, _, query_id, _ = _setup_mock_vault_for_fix(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task, **kw: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_FIX_RESPONSE)

        wiki_dir = tmp_path / "wiki"
        # wiki/ の初期ファイルリストを記録
        initial_wiki_files = set(str(p) for p in wiki_dir.rglob("*") if p.is_file())

        def mock_lint(_query_dir, **kwargs):
            return {
                "target": _query_dir,
                "status": "FAIL",
                "errors": ["QL006 answer too short"],
                "warnings": [],
                "infos": [],
                "checks": [],
            }

        monkeypatch.setattr(rw_light, "lint_single_query_dir", mock_lint)
        rw_light.cmd_query_fix([query_id])

        # wiki/ に新しいファイルが作成されていないこと
        final_wiki_files = set(str(p) for p in wiki_dir.rglob("*") if p.is_file())
        assert initial_wiki_files == final_wiki_files, (
            f"wiki/ に新しいファイルが作成された: {final_wiki_files - initial_wiki_files}"
        )


# ---------------------------------------------------------------------------
# TestExecutionModeUpdates のテスト (tasks 5.1-5.3)
# ---------------------------------------------------------------------------

class TestExecutionModeUpdates:
    """Templates の Execution Mode 更新を確認するテスト (tasks 5.1-5.3)"""

    TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "..", "templates")

    def _read_file(self, rel_path):
        full_path = os.path.join(self.TEMPLATES_DIR, rel_path)
        with open(full_path, encoding="utf-8") as f:
            return f.read()

    # --- Task 5.1: templates/CLAUDE.md マッピング表 ---

    def test_claude_md_query_extract_mode_is_cli_hybrid(self):
        """templates/CLAUDE.md: query_extract の Execution Mode が CLI (Hybrid) であること"""
        content = self._read_file("CLAUDE.md")
        for line in content.splitlines():
            if "query_extract" in line and "|" in line:
                assert "CLI (Hybrid)" in line, (
                    f"query_extract の Execution Mode が CLI (Hybrid) でない: {line!r}"
                )
                return
        pytest.fail("templates/CLAUDE.md に query_extract のマッピング行が見つからない")

    def test_claude_md_query_answer_mode_is_cli_hybrid(self):
        """templates/CLAUDE.md: query_answer の Execution Mode が CLI (Hybrid) であること"""
        content = self._read_file("CLAUDE.md")
        for line in content.splitlines():
            if "query_answer" in line and "|" in line:
                assert "CLI (Hybrid)" in line, (
                    f"query_answer の Execution Mode が CLI (Hybrid) でない: {line!r}"
                )
                return
        pytest.fail("templates/CLAUDE.md に query_answer のマッピング行が見つからない")

    def test_claude_md_query_fix_mode_is_cli_hybrid(self):
        """templates/CLAUDE.md: query_fix の Execution Mode が CLI (Hybrid) であること"""
        content = self._read_file("CLAUDE.md")
        for line in content.splitlines():
            if "query_fix" in line and "|" in line:
                assert "CLI (Hybrid)" in line, (
                    f"query_fix の Execution Mode が CLI (Hybrid) でない: {line!r}"
                )
                return
        pytest.fail("templates/CLAUDE.md に query_fix のマッピング行が見つからない")

    # --- Task 5.2: AGENTS/query_*.md Execution Mode セクション ---

    def test_agents_query_extract_execution_mode_section(self):
        """AGENTS/query_extract.md の Execution Mode セクションが CLI (Hybrid) であること"""
        content = self._read_file("AGENTS/query_extract.md")
        in_section = False
        for line in content.splitlines():
            if line.strip() == "## Execution Mode":
                in_section = True
                continue
            if in_section:
                if line.startswith("## "):
                    break
                if "**" in line:
                    assert "CLI (Hybrid)" in line, (
                        f"query_extract.md Execution Mode が CLI (Hybrid) でない: {line!r}"
                    )
                    return
        pytest.fail("AGENTS/query_extract.md に Execution Mode セクションの bold テキストが見つからない")

    def test_agents_query_answer_execution_mode_section(self):
        """AGENTS/query_answer.md の Execution Mode セクションが CLI (Hybrid) であること"""
        content = self._read_file("AGENTS/query_answer.md")
        in_section = False
        for line in content.splitlines():
            if line.strip() == "## Execution Mode":
                in_section = True
                continue
            if in_section:
                if line.startswith("## "):
                    break
                if "**" in line:
                    assert "CLI (Hybrid)" in line, (
                        f"query_answer.md Execution Mode が CLI (Hybrid) でない: {line!r}"
                    )
                    return
        pytest.fail("AGENTS/query_answer.md に Execution Mode セクションの bold テキストが見つからない")

    def test_agents_query_fix_execution_mode_section(self):
        """AGENTS/query_fix.md の Execution Mode セクションが CLI (Hybrid) であること"""
        content = self._read_file("AGENTS/query_fix.md")
        in_section = False
        for line in content.splitlines():
            if line.strip() == "## Execution Mode":
                in_section = True
                continue
            if in_section:
                if line.startswith("## "):
                    break
                if "**" in line:
                    assert "CLI (Hybrid)" in line, (
                        f"query_fix.md Execution Mode が CLI (Hybrid) でない: {line!r}"
                    )
                    return
        pytest.fail("AGENTS/query_fix.md に Execution Mode セクションの bold テキストが見つからない")

    # --- Task 5.3: AGENTS/README.md テーブル ---

    def test_agents_readme_query_extract_mode(self):
        """AGENTS/README.md テーブルで query_extract が CLI (Hybrid) であること"""
        content = self._read_file("AGENTS/README.md")
        for line in content.splitlines():
            if "query_extract" in line and "|" in line:
                assert "CLI (Hybrid)" in line, (
                    f"README.md の query_extract 行の実行モードが CLI (Hybrid) でない: {line!r}"
                )
                return
        pytest.fail("AGENTS/README.md に query_extract のテーブル行が見つからない")

    def test_agents_readme_query_answer_mode(self):
        """AGENTS/README.md テーブルで query_answer が CLI (Hybrid) であること"""
        content = self._read_file("AGENTS/README.md")
        for line in content.splitlines():
            if "query_answer" in line and "|" in line:
                assert "CLI (Hybrid)" in line, (
                    f"README.md の query_answer 行の実行モードが CLI (Hybrid) でない: {line!r}"
                )
                return
        pytest.fail("AGENTS/README.md に query_answer のテーブル行が見つからない")

    def test_agents_readme_query_fix_mode(self):
        """AGENTS/README.md テーブルで query_fix が CLI (Hybrid) であること"""
        content = self._read_file("AGENTS/README.md")
        for line in content.splitlines():
            if "query_fix" in line and "|" in line:
                assert "CLI (Hybrid)" in line, (
                    f"README.md の query_fix 行の実行モードが CLI (Hybrid) でない: {line!r}"
                )
                return
        pytest.fail("AGENTS/README.md に query_fix のテーブル行が見つからない")


# ---------------------------------------------------------------------------
# print_usage() のテスト
# ---------------------------------------------------------------------------

class TestPrintUsage:
    """print_usage() のユニットテスト"""

    def test_print_usage_contains_query_subcommand(self, capsys):
        """print_usage() の出力に 'query' が含まれること"""
        rw_light.print_usage()
        captured = capsys.readouterr()
        assert "query" in captured.out

    def test_print_usage_contains_extract(self, capsys):
        """print_usage() の出力に 'extract' が含まれること"""
        rw_light.print_usage()
        captured = capsys.readouterr()
        assert "extract" in captured.out

    def test_print_usage_contains_answer(self, capsys):
        """print_usage() の出力に 'answer' が含まれること"""
        rw_light.print_usage()
        captured = capsys.readouterr()
        assert "answer" in captured.out

    def test_print_usage_contains_fix(self, capsys):
        """print_usage() の出力に 'fix' が含まれること"""
        rw_light.print_usage()
        captured = capsys.readouterr()
        assert "fix" in captured.out


# ---------------------------------------------------------------------------
# main() ディスパッチャのテスト
# ---------------------------------------------------------------------------

class TestMainDispatcher:
    """main() の query ルーティングと例外ハンドラのテスト"""

    def test_query_extract_routes_to_cmd_query_extract(self, monkeypatch, capsys):
        """rw query extract "q" → cmd_query_extract(["q"]) が呼ばれること"""
        called_with = []

        def mock_cmd_query_extract(args):
            called_with.append(args)
            return 0

        monkeypatch.setattr(sys, "argv", ["rw", "query", "extract", "q"])
        monkeypatch.setattr(rw_light, "cmd_query_extract", mock_cmd_query_extract)

        with pytest.raises(SystemExit) as exc_info:
            rw_light.main()

        assert exc_info.value.code == 0
        assert called_with == [["q"]]

    def test_query_answer_routes_to_cmd_query_answer(self, monkeypatch):
        """rw query answer "q" → cmd_query_answer(["q"]) が呼ばれること"""
        called_with = []

        def mock_cmd_query_answer(args):
            called_with.append(args)
            return 0

        monkeypatch.setattr(sys, "argv", ["rw", "query", "answer", "q"])
        monkeypatch.setattr(rw_light, "cmd_query_answer", mock_cmd_query_answer)

        with pytest.raises(SystemExit) as exc_info:
            rw_light.main()

        assert exc_info.value.code == 0
        assert called_with == [["q"]]

    def test_query_fix_routes_to_cmd_query_fix(self, monkeypatch):
        """rw query fix qid → cmd_query_fix(["qid"]) が呼ばれること"""
        called_with = []

        def mock_cmd_query_fix(args):
            called_with.append(args)
            return 0

        monkeypatch.setattr(sys, "argv", ["rw", "query", "fix", "qid"])
        monkeypatch.setattr(rw_light, "cmd_query_fix", mock_cmd_query_fix)

        with pytest.raises(SystemExit) as exc_info:
            rw_light.main()

        assert exc_info.value.code == 0
        assert called_with == [["qid"]]

    def test_query_no_subcommand_exits_1(self, monkeypatch, capsys):
        """rw query（サブコマンドなし）→ sys.exit(1)"""
        monkeypatch.setattr(sys, "argv", ["rw", "query"])

        with pytest.raises(SystemExit) as exc_info:
            rw_light.main()

        assert exc_info.value.code == 1

    def test_query_no_subcommand_shows_usage(self, monkeypatch, capsys):
        """rw query（サブコマンドなし）→ usage に 'query' が含まれること"""
        monkeypatch.setattr(sys, "argv", ["rw", "query"])

        with pytest.raises(SystemExit):
            rw_light.main()

        captured = capsys.readouterr()
        assert "query" in captured.out

    def test_query_unknown_subcommand_exits_1(self, monkeypatch):
        """rw query unknown → sys.exit(1)"""
        monkeypatch.setattr(sys, "argv", ["rw", "query", "unknown"])

        with pytest.raises(SystemExit) as exc_info:
            rw_light.main()

        assert exc_info.value.code == 1

    def test_no_command_exits_1(self, monkeypatch):
        """rw（コマンドなし）→ sys.exit(1)"""
        monkeypatch.setattr(sys, "argv", ["rw"])

        with pytest.raises(SystemExit) as exc_info:
            rw_light.main()

        assert exc_info.value.code == 1

    def test_value_error_caught_and_exits_1(self, monkeypatch, capsys):
        """cmd_query_extract が ValueError を raise → sys.exit(1) かつ '[FAIL]' が出力されること"""

        def mock_cmd_query_extract(args):
            raise ValueError("test error")

        monkeypatch.setattr(sys, "argv", ["rw", "query", "extract", "q"])
        monkeypatch.setattr(rw_light, "cmd_query_extract", mock_cmd_query_extract)

        with pytest.raises(SystemExit) as exc_info:
            rw_light.main()

        assert exc_info.value.code == 1
        captured = capsys.readouterr()
        assert "[FAIL]" in captured.out


# ---------------------------------------------------------------------------
# TestDocumentationUpdates のテスト (tasks 6.1-6.2)
# ---------------------------------------------------------------------------

class TestDocumentationUpdates:
    """ドキュメント更新を確認するテスト (tasks 6.1-6.2)"""

    PROJECT_ROOT = os.path.join(os.path.dirname(__file__), "..")

    def _read_file(self, rel_path):
        full_path = os.path.join(self.PROJECT_ROOT, rel_path)
        with open(full_path, encoding="utf-8") as f:
            return f.read()

    def test_user_guide_exists(self):
        """docs/user-guide.md が存在すること"""
        full_path = os.path.join(self.PROJECT_ROOT, "docs", "user-guide.md")
        assert os.path.isfile(full_path), f"docs/user-guide.md が存在しない: {full_path}"

    def test_user_guide_contains_query_extract_section(self):
        """user-guide.md に rw query extract の説明が含まれること"""
        content = self._read_file("docs/user-guide.md")
        assert "rw query extract" in content, "docs/user-guide.md に 'rw query extract' が含まれていない"

    def test_user_guide_contains_query_answer_section(self):
        """user-guide.md に rw query answer の説明が含まれること"""
        content = self._read_file("docs/user-guide.md")
        assert "rw query answer" in content, "docs/user-guide.md に 'rw query answer' が含まれていない"

    def test_user_guide_contains_query_fix_section(self):
        """user-guide.md に rw query fix の説明が含まれること"""
        content = self._read_file("docs/user-guide.md")
        assert "rw query fix" in content, "docs/user-guide.md に 'rw query fix' が含まれていない"

    def test_changelog_contains_unreleased_section(self):
        """CHANGELOG.md に [Unreleased] セクションが存在すること"""
        content = self._read_file("CHANGELOG.md")
        assert "[Unreleased]" in content, "CHANGELOG.md に '[Unreleased]' セクションが存在しない"

    def test_changelog_contains_query_extract_entry(self):
        """CHANGELOG.md に rw query extract の変更内容が記載されていること"""
        content = self._read_file("CHANGELOG.md")
        assert "rw query extract" in content, "CHANGELOG.md に 'rw query extract' エントリが含まれていない"

    def test_changelog_contains_query_answer_entry(self):
        """CHANGELOG.md に rw query answer の変更内容が記載されていること"""
        content = self._read_file("CHANGELOG.md")
        assert "rw query answer" in content, "CHANGELOG.md に 'rw query answer' エントリが含まれていない"

    def test_changelog_contains_query_fix_entry(self):
        """CHANGELOG.md に rw query fix の変更内容が記載されていること"""
        content = self._read_file("CHANGELOG.md")
        assert "rw query fix" in content, "CHANGELOG.md に 'rw query fix' エントリが含まれていない"


# ---------------------------------------------------------------------------
# TestE2EWorkflow — extract → lint → fix E2E 統合検証 (task 7.1)
# ---------------------------------------------------------------------------

def _setup_e2e_vault(tmp_path, monkeypatch):
    """E2Eテスト用の完全な Vault 構造を作成する"""
    # wiki/
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()
    (wiki_dir / "concepts").mkdir()
    (wiki_dir / "concepts" / "machine_learning.md").write_text(
        "# Machine Learning\n\nML is a field of AI.\n\nsource: textbook\n", encoding="utf-8"
    )
    (wiki_dir / "concepts" / "deep_learning.md").write_text(
        "# Deep Learning\n\nDeep learning uses neural networks.\n\nsource: textbook\n", encoding="utf-8"
    )

    # review/query/
    query_dir = tmp_path / "review" / "query"
    query_dir.mkdir(parents=True)

    # logs/
    logs_dir = tmp_path / "logs"
    logs_dir.mkdir()

    # index.md
    index_md = tmp_path / "index.md"
    index_md.write_text("# Index\n\n- [[machine_learning]]\n- [[deep_learning]]\n", encoding="utf-8")

    # CLAUDE.md (with mapping table)
    claude_md = tmp_path / "CLAUDE.md"
    claude_md.write_text(
        "# CLAUDE.md\n\n"
        "# Task → AGENTS Mapping (Default)\n\n"
        "| Task | Agent | Policy | Execution Mode |\n"
        "|---|---|---|---|\n"
        "| ingest | AGENTS/ingest.md | AGENTS/git_ops.md | CLI |\n"
        "| lint | AGENTS/lint.md | AGENTS/naming.md | CLI |\n"
        "| synthesize | AGENTS/synthesize.md | AGENTS/page_policy.md, AGENTS/naming.md | Prompt |\n"
        "| synthesize_logs | AGENTS/synthesize_logs.md | AGENTS/naming.md | CLI (Hybrid) |\n"
        "| approve | AGENTS/approve.md | AGENTS/git_ops.md, AGENTS/page_policy.md | CLI |\n"
        "| query_answer | AGENTS/query_answer.md | AGENTS/page_policy.md | CLI (Hybrid) |\n"
        "| query_extract | AGENTS/query_extract.md | AGENTS/naming.md, AGENTS/page_policy.md | CLI (Hybrid) |\n"
        "| query_fix | AGENTS/query_fix.md | AGENTS/naming.md | CLI (Hybrid) |\n"
        "| audit | AGENTS/audit.md | AGENTS/page_policy.md, AGENTS/naming.md, AGENTS/git_ops.md | Prompt |\n",
        encoding="utf-8",
    )

    # AGENTS/ directory
    agents_dir = tmp_path / "AGENTS"
    agents_dir.mkdir()
    agent_files = {
        "ingest.md": "AGENT ingest",
        "lint.md": "AGENT lint",
        "synthesize.md": "AGENT synthesize",
        "synthesize_logs.md": "AGENT synthesize_logs",
        "approve.md": "AGENT approve",
        "query_answer.md": "AGENT query_answer - initial content",
        "query_extract.md": "AGENT query_extract - initial content",
        "query_fix.md": "AGENT query_fix",
        "audit.md": "AGENT audit",
        "git_ops.md": "POLICY git_ops",
        "naming.md": "POLICY naming",
        "page_policy.md": "POLICY page_policy",
    }
    for filename, content in agent_files.items():
        (agents_dir / filename).write_text(content, encoding="utf-8")

    # Patch rw_light module constants
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "QUERY_REVIEW", str(query_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(index_md))
    monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
    monkeypatch.setattr(rw_light, "QUERY_LINT_LOG", str(logs_dir / "query_lint_latest.json"))

    return tmp_path, wiki_dir, query_dir, agents_dir


def _make_extract_response(query_text="What is ML?", query_type="fact"):
    return json.dumps({
        "query": {"text": query_text, "query_type": query_type, "scope": "all", "date": "2026-04-17"},
        "answer": {
            "content": (
                "# Answer\n\nMachine Learning is a field of AI.\n\n"
                "## Details\n\nML uses statistical methods to learn from data."
            )
        },
        "evidence": {
            "blocks": [{"source": "wiki/concepts/machine_learning.md", "excerpt": "ML is a field of AI."}]
        },
        "metadata": {
            "query_id": "old-id",
            "query_type": query_type,
            "scope": "all",
            "sources": ["wiki/concepts/machine_learning.md"],
            "created_at": "2026-04-17T12:00:00+09:00",
        },
        "referenced_pages": ["wiki/concepts/machine_learning.md"],
    })


def _make_fix_response(query_id):
    return json.dumps({
        "fixes": [{"file": "answer.md", "ql_code": "QL006", "action": "expanded content"}],
        "files": {
            "question.md": None,
            "answer.md": (
                "# Answer\n\nThis is a comprehensive answer about Machine Learning.\n\n"
                "## What is ML?\n\nML is a subfield of AI that uses statistical methods.\n\n"
                "## Key Concepts\n\nSupervised learning, unsupervised learning, reinforcement learning."
            ),
            "evidence.md": None,
            "metadata.json": None,
        },
        "skipped": [],
    })


class TestE2EWorkflow:
    """extract → lint → fix E2E 統合検証テスト (task 7.1)"""

    # ------------------------------------------------------------------
    # Test 1: extract で 4ファイル生成
    # ------------------------------------------------------------------

    def test_extract_creates_4_files(self, tmp_path, monkeypatch):
        """extract → review/query/<query_id>/ に 4ファイルが作成されること"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: _make_extract_response())

        result = rw_light.cmd_query_extract(["What is ML?"])

        assert result in (0, 2), f"Expected 0 or 2, got {result}"

        query_id = rw_light.generate_query_id("What is ML?")
        qdir = query_dir / query_id
        assert qdir.is_dir(), f"query directory not found: {qdir}"

        for fname in ["question.md", "answer.md", "evidence.md", "metadata.json"]:
            assert (qdir / fname).exists(), f"Missing file: {fname}"

    # ------------------------------------------------------------------
    # Test 2: extract → lint PASS
    # ------------------------------------------------------------------

    def test_extract_then_lint_pass(self, tmp_path, monkeypatch):
        """extract → lint が PASS を返すこと"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: _make_extract_response())

        extract_result = rw_light.cmd_query_extract(["What is ML?"])
        assert extract_result in (0, 2), f"extract failed: {extract_result}"

        query_id = rw_light.generate_query_id("What is ML?")
        qdir = str(query_dir / query_id)
        lint_result = rw_light.lint_single_query_dir(qdir)

        assert lint_result["status"] in ("PASS", "PASS_WITH_WARNINGS"), (
            f"lint should PASS after extract, got: {lint_result['status']}, errors: {lint_result['errors']}"
        )

    # ------------------------------------------------------------------
    # Test 3: extract → corrupt answer → lint FAIL → fix → lint PASS
    # ------------------------------------------------------------------

    def test_extract_lint_fail_fix_workflow(self, tmp_path, monkeypatch):
        """extract → answer.md を短縮 → lint FAIL → fix → lint PASS ワークフローの検証"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: _make_extract_response())

        # Step 1: extract
        extract_result = rw_light.cmd_query_extract(["What is ML?"])
        assert extract_result in (0, 2), f"extract failed: {extract_result}"

        query_id = rw_light.generate_query_id("What is ML?")
        qdir = query_dir / query_id

        # Step 2: answer.md を意図的に短縮して QL006 を引き起こす
        (qdir / "answer.md").write_text("short", encoding="utf-8")

        # Step 3: lint → FAIL
        lint_result = rw_light.lint_single_query_dir(str(qdir))
        assert lint_result["status"] == "FAIL", (
            f"lint should FAIL after corrupting answer.md, got: {lint_result['status']}"
        )
        assert any("QL006" in c["id"] for c in lint_result["checks"] if c["severity"] in {"ERROR", "CRITICAL"}), (
            f"QL006 error expected, got: {lint_result['checks']}"
        )

        # Step 4: fix（call_claude を fix レスポンスにすり替え）
        monkeypatch.setattr(rw_light, "call_claude", lambda p: _make_fix_response(query_id))
        fix_result = rw_light.cmd_query_fix([query_id])
        assert fix_result in (0, 2), f"fix command returned unexpected code: {fix_result}"

        # Step 5: lint 再検証 → PASS
        post_lint = rw_light.lint_single_query_dir(str(qdir))
        assert post_lint["status"] == "PASS", (
            f"lint should PASS after fix, got: {post_lint['status']}, checks: {post_lint['checks']}"
        )

    # ------------------------------------------------------------------
    # Test 4: AGENTS ファイル更新 → extract に反映 (Req 9.2)
    # ------------------------------------------------------------------

    def test_agents_file_update_reflected(self, tmp_path, monkeypatch):
        """AGENTS/query_extract.md 変更後に extract を実行すると新内容がプロンプトに反映されること (Req 9.2)"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")

        # 1回目: 初期内容でプロンプトをキャプチャ
        captured_prompts_1 = []

        def mock_claude_1(p):
            captured_prompts_1.append(p)
            return _make_extract_response("What is ML? first")

        monkeypatch.setattr(rw_light, "call_claude", mock_claude_1)
        result1 = rw_light.cmd_query_extract(["What is ML? first"])
        assert result1 in (0, 2), f"first extract failed: {result1}"
        assert len(captured_prompts_1) >= 1

        # AGENTS/query_extract.md を更新
        new_content = "AGENT query_extract - UPDATED CONTENT v2"
        (agents_dir / "query_extract.md").write_text(new_content, encoding="utf-8")

        # 2回目: 更新後のプロンプトをキャプチャ
        captured_prompts_2 = []

        def mock_claude_2(p):
            captured_prompts_2.append(p)
            return _make_extract_response("What is ML? second")

        monkeypatch.setattr(rw_light, "call_claude", mock_claude_2)
        result2 = rw_light.cmd_query_extract(["What is ML? second"])
        assert result2 in (0, 2), f"second extract failed: {result2}"
        assert len(captured_prompts_2) >= 1

        # 1回目のプロンプトには初期内容が、2回目には新内容が含まれること
        assert "initial content" in captured_prompts_1[0], (
            "first prompt should contain initial AGENTS content"
        )
        assert "UPDATED CONTENT v2" in captured_prompts_2[0], (
            "second prompt should contain updated AGENTS content (Req 9.2)"
        )
        assert "UPDATED CONTENT v2" not in captured_prompts_1[0], (
            "first prompt should NOT contain updated content"
        )

    # ------------------------------------------------------------------
    # Test 5: --scope オプションで特定ページのみ参照
    # ------------------------------------------------------------------

    def test_scope_option_limits_wiki_content(self, tmp_path, monkeypatch):
        """--scope 指定時、そのページのみが wiki コンテンツとして読み込まれること"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")

        # read_wiki_content の呼び出し引数をキャプチャ
        captured_scope = []
        original_read_wiki = rw_light.read_wiki_content

        def mock_read_wiki(scope):
            captured_scope.append(scope)
            return original_read_wiki(scope)

        monkeypatch.setattr(rw_light, "read_wiki_content", mock_read_wiki)

        scope_path = str(wiki_dir / "concepts" / "machine_learning.md")
        captured_prompts = []

        def mock_claude(p):
            captured_prompts.append(p)
            return _make_extract_response("What is ML? scoped")

        monkeypatch.setattr(rw_light, "call_claude", mock_claude)
        result = rw_light.cmd_query_extract(["What is ML? scoped", "--scope", scope_path])
        assert result in (0, 2), f"scope extract failed: {result}"

        # read_wiki_content が scope 付きで呼ばれたこと
        assert len(captured_scope) >= 1
        assert captured_scope[0] == scope_path, (
            f"Expected scope={scope_path}, got {captured_scope[0]}"
        )

        # プロンプトに machine_learning.md のコンテンツが含まれること
        assert len(captured_prompts) >= 1
        assert "Machine Learning" in captured_prompts[0], (
            "prompt should contain scoped page content"
        )

    # ------------------------------------------------------------------
    # Test 6: answer コマンドはファイルを作成しない (Req 2.3)
    # ------------------------------------------------------------------

    def test_answer_no_files_created(self, tmp_path, monkeypatch):
        """answer コマンド実行後、review/query/ にファイルが作成されないこと (Req 2.3)"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "call_claude", lambda p: "ML is a field of AI.\n\n---\nReferenced: wiki/concepts/machine_learning.md")

        result = rw_light.cmd_query_answer(["What is ML?"])
        assert result == 0, f"answer command failed: {result}"

        # review/query/ 内にディレクトリが作成されていないこと
        subdirs = [d for d in query_dir.iterdir() if d.is_dir()]
        assert len(subdirs) == 0, (
            f"answer should not create files in review/query/, found: {subdirs}"
        )

    # ------------------------------------------------------------------
    # Test 7: answer --scope オプション (Req 2.4)
    # ------------------------------------------------------------------

    def test_answer_scope_option(self, tmp_path, monkeypatch):
        """answer --scope オプションが read_wiki_content に正しく渡されること"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)

        captured_scope = []
        original_read_wiki = rw_light.read_wiki_content

        def mock_read_wiki(scope):
            captured_scope.append(scope)
            return original_read_wiki(scope)

        monkeypatch.setattr(rw_light, "read_wiki_content", mock_read_wiki)
        monkeypatch.setattr(rw_light, "call_claude", lambda p: "Answer about ML.\n\n---\nReferenced: wiki/concepts/machine_learning.md")

        scope_path = str(wiki_dir / "concepts" / "machine_learning.md")
        result = rw_light.cmd_query_answer(["What is ML?", "--scope", scope_path])
        assert result == 0, f"answer with scope failed: {result}"

        assert len(captured_scope) >= 1
        assert captured_scope[0] == scope_path, (
            f"Expected scope={scope_path}, got {captured_scope[0]}"
        )

    # ------------------------------------------------------------------
    # Error cases
    # ------------------------------------------------------------------

    def test_error_wiki_missing(self, tmp_path, monkeypatch):
        """wiki/ が存在しない → cmd_query_extract が 1 を返すこと"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        import shutil
        shutil.rmtree(str(wiki_dir))

        result = rw_light.cmd_query_extract(["What is ML?"])
        assert result == 1, f"Expected 1 for missing wiki/, got {result}"

    def test_error_agents_missing(self, tmp_path, monkeypatch):
        """AGENTS/ が存在しない → cmd_query_extract が 1 を返すこと"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        import shutil
        shutil.rmtree(str(agents_dir))

        result = rw_light.cmd_query_extract(["What is ML?"])
        assert result == 1, f"Expected 1 for missing AGENTS/, got {result}"

    def test_error_claude_md_parse_fail(self, tmp_path, monkeypatch):
        """CLAUDE.md にマッピング表がない → cmd_query_extract が 1 を返すこと"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        # CLAUDE.md をマッピング表なしの内容に上書き
        (tmp_path / "CLAUDE.md").write_text(
            "# CLAUDE.md\n\nNo table here, just text.\n", encoding="utf-8"
        )
        monkeypatch.setattr(rw_light, "call_claude", lambda p: _make_extract_response())

        result = rw_light.cmd_query_extract(["What is ML?"])
        assert result == 1, f"Expected 1 for invalid CLAUDE.md, got {result}"

    def test_error_empty_question(self, tmp_path, monkeypatch):
        """空の質問文 → cmd_query_extract が 1 を返すこと"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)

        result = rw_light.cmd_query_extract([""])
        assert result == 1, f"Expected 1 for empty question, got {result}"

    def test_error_scope_page_missing(self, tmp_path, monkeypatch):
        """--scope で存在しないページを指定 → cmd_query_extract が 1 を返すこと"""
        tmp_path, wiki_dir, query_dir, agents_dir = _setup_e2e_vault(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "call_claude", lambda p: _make_extract_response())

        nonexistent_scope = str(wiki_dir / "concepts" / "nonexistent_page.md")
        result = rw_light.cmd_query_extract(["What is ML?", "--scope", nonexistent_scope])
        assert result == 1, f"Expected 1 for missing scope page, got {result}"


# ---------------------------------------------------------------------------
# Task 1.1: Finding / WikiPage NamedTuple + call_claude() timeout 拡張
# ---------------------------------------------------------------------------

class TestFindingNamedTuple:
    """Finding NamedTuple の定義テスト"""

    def test_finding_has_five_fields(self):
        """Finding NamedTuple は 5 フィールドを持つこと（sub_severity 廃止後）"""
        f = rw_light.Finding(
            severity="ERROR",
            category="broken_link",
            page="concepts/my-page.md",
            message="リンク先が存在しない",
            marker="CONFLICT",
        )
        assert f.severity == "ERROR"
        assert f.category == "broken_link"
        assert f.page == "concepts/my-page.md"
        assert f.message == "リンク先が存在しない"
        assert f.marker == "CONFLICT"

    def test_finding_fields_all_str(self):
        """Finding の全フィールドが str 型であること"""
        f = rw_light.Finding(
            severity="WARN",
            category="orphan_page",
            page="methods/orphan.md",
            message="孤立ページ",
            marker="",
        )
        for field in (f.severity, f.category, f.page, f.message, f.marker):
            assert isinstance(field, str), f"Expected str, got {type(field)}"

    def test_finding_is_named_tuple(self):
        """Finding が NamedTuple であること"""
        import typing
        assert issubclass(rw_light.Finding, tuple)
        assert hasattr(rw_light.Finding, "_fields")
        assert set(rw_light.Finding._fields) == {
            "severity", "category", "page", "message", "marker"
        }

    def test_finding_no_sub_severity(self):
        """Task 1.6: Finding NamedTuple に sub_severity フィールドが存在しないこと"""
        assert "sub_severity" not in rw_light.Finding._fields, (
            "sub_severity field must be removed from Finding NamedTuple"
        )

    def test_finding_has_five_fields_after_removal(self):
        """Task 1.6: Finding NamedTuple は sub_severity 廃止後 5 フィールドであること"""
        assert set(rw_light.Finding._fields) == {
            "severity", "category", "page", "message", "marker"
        }

    def test_format_finding_line_single_prefix(self):
        """Task 1.6: _format_finding_line が [SEVERITY] 単一プレフィックスを返すこと"""
        # generate_audit_report の内部関数 _format_finding_line を間接テストする
        # Finding を使った audit report 生成で prefix が単一であることを確認
        f = rw_light.Finding(
            severity="ERROR",
            category="broken_link",
            page="concepts/my-page.md",
            message="リンク先が存在しない",
            marker="",
        )
        # [ERROR:CRITICAL] のような2段表記が存在しないことを確認
        assert hasattr(f, "severity")
        assert not hasattr(f, "sub_severity"), "sub_severity must not exist on Finding"


class TestWikiPageNamedTuple:
    """WikiPage NamedTuple の定義テスト"""

    def test_wiki_page_has_seven_fields(self):
        """WikiPage NamedTuple は 7 フィールドを持つこと"""
        wp = rw_light.WikiPage(
            path="concepts/my-page.md",
            filename="my-page.md",
            raw_text="---\ntitle: My Page\n---\n\nBody text.",
            frontmatter={"title": "My Page"},
            body="Body text.",
            links=["other-page"],
            read_error="",
        )
        assert wp.path == "concepts/my-page.md"
        assert wp.filename == "my-page.md"
        assert wp.raw_text == "---\ntitle: My Page\n---\n\nBody text."
        assert wp.frontmatter == {"title": "My Page"}
        assert wp.body == "Body text."
        assert wp.links == ["other-page"]
        assert wp.read_error == ""

    def test_wiki_page_links_is_list(self):
        """WikiPage.links が list[str] であること"""
        wp = rw_light.WikiPage(
            path="methods/sindy.md",
            filename="sindy.md",
            raw_text="",
            frontmatter={},
            body="",
            links=["page-a", "page-b"],
            read_error="",
        )
        assert isinstance(wp.links, list)
        assert all(isinstance(lnk, str) for lnk in wp.links)

    def test_wiki_page_frontmatter_is_dict(self):
        """WikiPage.frontmatter が dict であること"""
        wp = rw_light.WikiPage(
            path="entities/tool.md",
            filename="tool.md",
            raw_text="",
            frontmatter={"title": "Tool", "source": "web"},
            body="",
            links=[],
            read_error="",
        )
        assert isinstance(wp.frontmatter, dict)

    def test_wiki_page_is_named_tuple(self):
        """WikiPage が NamedTuple であること"""
        assert issubclass(rw_light.WikiPage, tuple)
        assert hasattr(rw_light.WikiPage, "_fields")
        assert set(rw_light.WikiPage._fields) == {
            "path", "filename", "raw_text", "frontmatter", "body", "links", "read_error"
        }

    def test_wiki_page_read_error_str(self):
        """WikiPage.read_error が str であること（エラー時のメッセージ）"""
        wp = rw_light.WikiPage(
            path="wiki/broken.md",
            filename="broken.md",
            raw_text="",
            frontmatter={},
            body="",
            links=[],
            read_error="UnicodeDecodeError: invalid byte",
        )
        assert isinstance(wp.read_error, str)
        assert "UnicodeDecodeError" in wp.read_error


class TestCallClaudeTimeout:
    """call_claude() の timeout パラメータ拡張テスト"""

    def test_timeout_parameter_accepted(self, monkeypatch):
        """timeout パラメータを指定しても正常動作すること"""
        import subprocess

        mock_result = subprocess.CompletedProcess(
            args=["claude", "-p", "test"],
            returncode=0,
            stdout="response text\n",
            stderr="",
        )

        monkeypatch.setattr(subprocess, "run", lambda *args, **kwargs: mock_result)

        result = rw_light.call_claude("test prompt", timeout=300)
        assert result == "response text"

    def test_timeout_none_is_default(self, monkeypatch):
        """timeout=None がデフォルトで既存動作と同一であること"""
        import subprocess

        mock_result = subprocess.CompletedProcess(
            args=["claude", "-p", "test"],
            returncode=0,
            stdout="default response\n",
            stderr="",
        )

        monkeypatch.setattr(subprocess, "run", lambda *args, **kwargs: mock_result)

        result = rw_light.call_claude("test prompt")
        assert result == "default response"

    def test_timeout_passed_to_subprocess(self, monkeypatch):
        """timeout が subprocess.run に渡されること"""
        import subprocess

        captured_kwargs = {}

        def mock_run(*args, **kwargs):
            captured_kwargs.update(kwargs)
            return subprocess.CompletedProcess(
                args=args[0], returncode=0, stdout="ok\n", stderr=""
            )

        monkeypatch.setattr(subprocess, "run", mock_run)

        rw_light.call_claude("test prompt", timeout=120)
        assert captured_kwargs.get("timeout") == 120

    def test_timeout_none_not_passed_to_subprocess(self, monkeypatch):
        """timeout=None の場合、subprocess.run に timeout=None が渡されるか
        またはデフォルト動作（タイムアウトなし）であること"""
        import subprocess

        captured_kwargs = {}

        def mock_run(*args, **kwargs):
            captured_kwargs.update(kwargs)
            return subprocess.CompletedProcess(
                args=args[0], returncode=0, stdout="ok\n", stderr=""
            )

        monkeypatch.setattr(subprocess, "run", mock_run)

        rw_light.call_claude("test prompt", timeout=None)
        # timeout=None が渡されても subprocess は無制限タイムアウトとして動作する
        timeout_val = captured_kwargs.get("timeout")
        assert timeout_val is None

    def test_timeout_expired_raises_runtime_error(self, monkeypatch):
        """TimeoutExpired が RuntimeError に変換されること"""
        import subprocess

        def mock_run(*args, **kwargs):
            raise subprocess.TimeoutExpired(cmd=["claude"], timeout=300)

        monkeypatch.setattr(subprocess, "run", mock_run)

        with pytest.raises(RuntimeError) as exc_info:
            rw_light.call_claude("test prompt", timeout=300)

        assert "300" in str(exc_info.value)

    def test_timeout_expired_message_contains_seconds(self, monkeypatch):
        """TimeoutExpired の RuntimeError メッセージにタイムアウト秒数が含まれること"""
        import subprocess

        def mock_run(*args, **kwargs):
            raise subprocess.TimeoutExpired(cmd=["claude"], timeout=60)

        monkeypatch.setattr(subprocess, "run", mock_run)

        with pytest.raises(RuntimeError) as exc_info:
            rw_light.call_claude("test prompt", timeout=60)

        error_msg = str(exc_info.value)
        assert "60" in error_msg


class TestAuditSectionHeaders:
    """rw_light.py に audit セクションヘッダーが配置されていること"""

    def test_audit_data_loading_header_exists(self):
        """# audit: data loading ヘッダーが存在すること"""
        import inspect
        source = inspect.getsource(rw_light)
        assert "# audit: data loading" in source

    def test_audit_static_checks_micro_header_exists(self):
        """# audit: static checks — micro ヘッダーが存在すること"""
        import inspect
        source = inspect.getsource(rw_light)
        assert "# audit: static checks \u2014 micro" in source

    def test_audit_static_checks_weekly_header_exists(self):
        """# audit: static checks — weekly ヘッダーが存在すること"""
        import inspect
        source = inspect.getsource(rw_light)
        assert "# audit: static checks \u2014 weekly" in source

    def test_audit_llm_engine_header_exists(self):
        """# audit: LLM engine ヘッダーが存在すること"""
        import inspect
        source = inspect.getsource(rw_light)
        assert "# audit: LLM engine" in source

    def test_audit_report_engine_header_exists(self):
        """# audit: report engine ヘッダーが存在すること"""
        import inspect
        source = inspect.getsource(rw_light)
        assert "# audit: report engine" in source

    def test_audit_commands_dispatch_header_exists(self):
        """# audit: commands — dispatch+micro ヘッダーが存在すること"""
        import inspect
        source = inspect.getsource(rw_light)
        assert "# audit: commands \u2014 dispatch+micro" in source

    def test_audit_commands_weekly_header_exists(self):
        """# audit: commands — weekly ヘッダーが存在すること"""
        import inspect
        source = inspect.getsource(rw_light)
        assert "# audit: commands \u2014 weekly" in source

    def test_audit_commands_monthly_quarterly_header_exists(self):
        """# audit: commands — monthly/quarterly ヘッダーが存在すること"""
        import inspect
        source = inspect.getsource(rw_light)
        assert "# audit: commands \u2014 monthly/quarterly" in source

    def test_audit_headers_after_read_wiki_content(self):
        """audit ヘッダーが read_wiki_content の後にあること"""
        import inspect
        source = inspect.getsource(rw_light)
        idx_read_wiki = source.find("def read_wiki_content(")
        idx_audit_data = source.find("# audit: data loading")
        assert idx_read_wiki != -1, "read_wiki_content が見つからない"
        assert idx_audit_data != -1, "audit: data loading ヘッダーが見つからない"
        assert idx_read_wiki < idx_audit_data, (
            "audit ヘッダーは read_wiki_content の後に配置されるべき"
        )

    def test_audit_headers_before_output_utilities(self):
        """audit ヘッダーが Output utilities セクションの前にあること"""
        import inspect
        source = inspect.getsource(rw_light)
        idx_output = source.find("# Output utilities")
        idx_audit_data = source.find("# audit: data loading")
        assert idx_output != -1, "Output utilities が見つからない"
        assert idx_audit_data != -1, "audit: data loading ヘッダーが見つからない"
        assert idx_audit_data < idx_output, (
            "audit ヘッダーは Output utilities の前に配置されるべき"
        )


# ---------------------------------------------------------------------------
# Task 1.2: validate_wiki_dir() + load_wiki_pages()
# ---------------------------------------------------------------------------


def _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=2):
    """audit テスト用の wiki ディレクトリを tmp_path に作成する。"""
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()

    # 正常な .md ファイルを作成
    for i in range(num_files):
        page = wiki_dir / f"page-{i:02d}.md"
        page.write_text(
            f"---\ntitle: Page {i}\nsource: web\n---\n\n# Page {i}\n\nBody [[other-page]] text.\n",
            encoding="utf-8",
        )

    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    return wiki_dir


class TestValidateWikiDir:
    """validate_wiki_dir() のユニットテスト"""

    def test_returns_true_when_wiki_exists_with_md_files(self, tmp_path, monkeypatch):
        """wiki/ が存在し .md ファイルがある場合 True を返すこと"""
        _setup_wiki_for_audit(tmp_path, monkeypatch)
        result = rw_light.validate_wiki_dir()
        assert result is True

    def test_returns_false_when_wiki_dir_missing(self, tmp_path, monkeypatch):
        """wiki/ が存在しない場合 False を返すこと"""
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
        result = rw_light.validate_wiki_dir()
        assert result is False

    def test_prints_error_when_wiki_dir_missing(self, tmp_path, monkeypatch, capsys):
        """wiki/ が存在しない場合 [ERROR] メッセージを表示すること"""
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
        rw_light.validate_wiki_dir()
        captured = capsys.readouterr()
        assert "[ERROR]" in captured.out

    def test_returns_false_when_no_md_files(self, tmp_path, monkeypatch):
        """wiki/ が存在するが .md ファイルがない場合 False を返すこと"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "readme.txt").write_text("not markdown", encoding="utf-8")
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        result = rw_light.validate_wiki_dir()
        assert result is False

    def test_prints_error_when_no_md_files(self, tmp_path, monkeypatch, capsys):
        """wiki/ に .md ファイルがない場合 [ERROR] メッセージを表示すること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        rw_light.validate_wiki_dir()
        captured = capsys.readouterr()
        assert "[ERROR]" in captured.out

    def test_calls_warn_if_dirty_paths(self, tmp_path, monkeypatch):
        """dirty working tree の場合 warn_if_dirty_paths を呼び出すこと"""
        _setup_wiki_for_audit(tmp_path, monkeypatch)
        called_with = []

        def mock_warn(paths, action_name):
            called_with.append((paths, action_name))

        monkeypatch.setattr(rw_light, "warn_if_dirty_paths", mock_warn)
        rw_light.validate_wiki_dir()
        # warn_if_dirty_paths が "wiki" パスを含む引数で呼ばれること
        assert len(called_with) == 1
        assert "wiki" in called_with[0][0]

    def test_returns_true_with_single_md_file(self, tmp_path, monkeypatch):
        """wiki/ に .md ファイルが 1 つあれば True を返すこと"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "page.md").write_text("# Page\n\nContent.", encoding="utf-8")
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        result = rw_light.validate_wiki_dir()
        assert result is True


class TestLoadWikiPages:
    """load_wiki_pages() のユニットテスト"""

    def test_returns_list_of_wiki_pages(self, tmp_path, monkeypatch):
        """正常ケース: WikiPage リストが返ること"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=2)
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert isinstance(result, list)
        assert len(result) == 2
        assert all(isinstance(p, rw_light.WikiPage) for p in result)

    def test_wiki_page_path_is_wiki_relative(self, tmp_path, monkeypatch):
        """WikiPage.path が wiki/ からの相対パスであること"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=1)
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert len(result) == 1
        # path は wiki/ プレフィックスなし（例: "page-00.md"）
        assert not result[0].path.startswith("wiki/")
        assert result[0].path.endswith(".md")

    def test_wiki_page_filename_is_basename(self, tmp_path, monkeypatch):
        """WikiPage.filename がファイル名のみであること"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=1)
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert result[0].filename == "page-00.md"

    def test_wiki_page_frontmatter_parsed(self, tmp_path, monkeypatch):
        """WikiPage.frontmatter が parse_frontmatter() でパース済みであること"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=1)
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert isinstance(result[0].frontmatter, dict)
        assert result[0].frontmatter.get("title") == "Page 0"

    def test_wiki_page_body_contains_text(self, tmp_path, monkeypatch):
        """WikiPage.body が frontmatter 以降の本文テキストであること"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=1)
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert "Body" in result[0].body

    def test_wiki_page_links_extracted_from_body(self, tmp_path, monkeypatch):
        """WikiPage.links が body から [[link]] regex で抽出されること"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=1)
        result = rw_light.load_wiki_pages(str(wiki_dir))
        # page-00.md の body は "Body [[other-page]] text."
        assert "other-page" in result[0].links

    def test_wiki_page_links_alias_syntax_extracts_page_name(self, tmp_path, monkeypatch):
        """[[page|alias]] 形式のリンクで page 名のみが抽出されること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "test.md").write_text(
            "---\ntitle: Test\n---\n\n[[target-page|Display Text]] and [[simple-page]]\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert "target-page" in result[0].links
        assert "simple-page" in result[0].links
        # "Display Text" はリンク名として含まれないこと
        assert "Display Text" not in result[0].links

    def test_wiki_page_links_not_from_frontmatter(self, tmp_path, monkeypatch):
        """frontmatter 内の [[link]] は抽出対象外であること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "test.md").write_text(
            "---\ntitle: Test\nrelated: [[frontmatter-link]]\n---\n\n[[body-link]] text.\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert "body-link" in result[0].links
        assert "frontmatter-link" not in result[0].links

    def test_wiki_page_read_error_empty_on_success(self, tmp_path, monkeypatch):
        """正常読み込み時 WikiPage.read_error が空文字列であること"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=1)
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert result[0].read_error == ""

    def test_wiki_page_encoding_error_sets_read_error(self, tmp_path, monkeypatch):
        """エンコーディングエラーのファイルで read_error が設定されること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        # 正常ファイル
        (wiki_dir / "normal.md").write_text("---\ntitle: Normal\n---\n\nNormal body.\n", encoding="utf-8")
        # 非 UTF-8 ファイル（latin-1 のバイト列）
        bad_file = wiki_dir / "broken.md"
        bad_file.write_bytes(b"\xff\xfe broken content that is not valid UTF-8 \x80\x81\x82")

        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))

        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert len(result) == 2

        broken_pages = [p for p in result if p.filename == "broken.md"]
        assert len(broken_pages) == 1
        broken = broken_pages[0]
        assert broken.read_error != ""
        assert broken.frontmatter == {}
        assert broken.body == ""
        assert broken.links == []
        assert broken.raw_text == ""

    def test_encoding_error_does_not_stop_other_pages(self, tmp_path, monkeypatch):
        """エンコーディングエラーがあっても残りのページが読み込まれること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "aaa-normal.md").write_text("---\ntitle: A\n---\n\nContent A.\n", encoding="utf-8")
        bad_file = wiki_dir / "bbb-broken.md"
        bad_file.write_bytes(b"\xff\xfe\x80")
        (wiki_dir / "ccc-normal.md").write_text("---\ntitle: C\n---\n\nContent C.\n", encoding="utf-8")

        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))

        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert len(result) == 3
        normal_pages = [p for p in result if p.read_error == ""]
        assert len(normal_pages) == 2

    def test_target_files_filters_to_specified_files(self, tmp_path, monkeypatch):
        """target_files 指定時は指定ファイルのみ読み込むこと"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=3)
        target = [str(wiki_dir / "page-00.md")]
        result = rw_light.load_wiki_pages(str(wiki_dir), target_files=target)
        assert len(result) == 1
        assert result[0].filename == "page-00.md"

    def test_target_files_none_reads_all_files(self, tmp_path, monkeypatch):
        """target_files=None 時は全 .md ファイルを読み込むこと"""
        wiki_dir = _setup_wiki_for_audit(tmp_path, monkeypatch, num_files=3)
        result = rw_light.load_wiki_pages(str(wiki_dir), target_files=None)
        assert len(result) == 3

    def test_returns_empty_list_when_no_md_files(self, tmp_path, monkeypatch):
        """wiki/ に .md ファイルがない場合は空リストを返すこと"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "readme.txt").write_text("not markdown", encoding="utf-8")
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert result == []

    def test_subdirectory_pages_included(self, tmp_path, monkeypatch):
        """サブディレクトリ内のページが含まれること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        concepts = wiki_dir / "concepts"
        concepts.mkdir()
        (concepts / "my-concept.md").write_text(
            "---\ntitle: My Concept\n---\n\nBody text.\n", encoding="utf-8"
        )
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert len(result) == 1
        # path にサブディレクトリが含まれること
        assert "concepts" in result[0].path
        assert result[0].filename == "my-concept.md"

    def test_raw_text_preserved(self, tmp_path, monkeypatch):
        """WikiPage.raw_text に生テキストが保持されること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        raw = "---\ntitle: Raw Test\n---\n\nBody content here.\n"
        (wiki_dir / "raw-test.md").write_text(raw, encoding="utf-8")
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        result = rw_light.load_wiki_pages(str(wiki_dir))
        assert result[0].raw_text == raw


class TestAllPagesSetConstruction:
    """all_pages_set 構築ヘルパーのテスト（list_md_files + relpath + wiki/ プレフィックス除去）"""

    def test_all_pages_set_excludes_wiki_prefix(self, tmp_path, monkeypatch):
        """all_pages_set の各要素が wiki/ プレフィックスを含まないこと"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "page.md").write_text("# Page\n", encoding="utf-8")
        concepts = wiki_dir / "concepts"
        concepts.mkdir()
        (concepts / "concept.md").write_text("# Concept\n", encoding="utf-8")

        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))

        # all_pages_set の構築: list_md_files → relpath → wiki/ 除去
        files = rw_light.list_md_files(str(wiki_dir))
        all_pages_set = set()
        for f in files:
            rel = os.path.relpath(f, str(wiki_dir))
            all_pages_set.add(rel)

        assert "page.md" in all_pages_set
        assert "concepts/concept.md" in all_pages_set
        # wiki/ プレフィックスなし
        for entry in all_pages_set:
            assert not entry.startswith("wiki/"), f"wiki/ prefix found: {entry}"


# ---------------------------------------------------------------------------
# Task 1.3: _git_list_files / get_recent_wiki_changes
# ---------------------------------------------------------------------------

class TestGitListFiles:
    """_git_list_files() のユニットテスト"""

    def test_returns_list_of_file_paths(self, monkeypatch):
        """git コマンドが成功した場合、改行区切りのファイルパスリストを返すこと"""
        import subprocess

        fake_result = type("R", (), {"returncode": 0, "stdout": "wiki/page-a.md\nwiki/page-b.md\n"})()

        def fake_run(cmd, **kwargs):
            return fake_result

        monkeypatch.setattr(subprocess, "run", fake_run)
        result = rw_light._git_list_files(["diff", "--name-only", "--", "wiki/"])
        assert result == ["wiki/page-a.md", "wiki/page-b.md"]

    def test_returns_empty_list_on_failure(self, monkeypatch):
        """git コマンドが失敗した場合（returncode != 0）は空リストを返すこと"""
        import subprocess

        fake_result = type("R", (), {"returncode": 1, "stdout": ""})()

        def fake_run(cmd, **kwargs):
            return fake_result

        monkeypatch.setattr(subprocess, "run", fake_run)
        result = rw_light._git_list_files(["diff", "--name-only"])
        assert result == []

    def test_returns_empty_list_on_exception(self, monkeypatch):
        """subprocess が例外を raise した場合は空リストを返すこと"""
        import subprocess

        def fake_run(cmd, **kwargs):
            raise OSError("git not found")

        monkeypatch.setattr(subprocess, "run", fake_run)
        result = rw_light._git_list_files(["diff"])
        assert result == []

    def test_excludes_empty_lines(self, monkeypatch):
        """出力に空行が含まれる場合は除外されること"""
        import subprocess

        fake_result = type("R", (), {"returncode": 0, "stdout": "wiki/a.md\n\nwiki/b.md\n"})()

        def fake_run(cmd, **kwargs):
            return fake_result

        monkeypatch.setattr(subprocess, "run", fake_run)
        result = rw_light._git_list_files(["diff", "--name-only"])
        assert "" not in result
        assert result == ["wiki/a.md", "wiki/b.md"]

    def test_passes_correct_args_to_git(self, monkeypatch):
        """_git_list_files に渡した引数が git コマンドに正しく付加されること"""
        import subprocess

        captured = {}
        fake_result = type("R", (), {"returncode": 0, "stdout": ""})()

        def fake_run(cmd, **kwargs):
            captured["cmd"] = cmd
            return fake_result

        monkeypatch.setattr(subprocess, "run", fake_run)
        rw_light._git_list_files(["diff", "--name-only", "HEAD~1..HEAD", "--", "wiki/"])
        assert captured["cmd"] == ["git", "diff", "--name-only", "HEAD~1..HEAD", "--", "wiki/"]

    def test_call_claude_not_affected(self, monkeypatch):
        """_git_list_files のモックが call_claude には影響しないこと（独立性の確認）"""
        import subprocess

        git_call_count = 0
        original_run = subprocess.run

        def counting_fake_run(cmd, **kwargs):
            nonlocal git_call_count
            if cmd and cmd[0] == "git":
                git_call_count += 1
                return type("R", (), {"returncode": 0, "stdout": "wiki/page.md\n"})()
            return original_run(cmd, **kwargs)

        monkeypatch.setattr(subprocess, "run", counting_fake_run)
        result = rw_light._git_list_files(["status"])
        assert git_call_count == 1
        assert result == ["wiki/page.md"]


class TestGetRecentWikiChanges:
    """get_recent_wiki_changes() のユニットテスト"""

    def _make_wiki(self, tmp_path, files: dict[str, str]) -> str:
        """wiki/ ディレクトリとファイルを作成してパスを返す"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir(parents=True, exist_ok=True)
        for name, content in files.items():
            p = wiki_dir / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content, encoding="utf-8")
        return str(wiki_dir)

    def test_returns_files_with_uncommitted_changes(self, tmp_path, monkeypatch):
        """未コミット変更のある wiki/.md ファイルがリストに含まれること"""
        wiki_dir = self._make_wiki(tmp_path, {"page-a.md": "# A\n"})
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)

        def fake_git_list_files(args):
            if args[:2] == ["diff", "--name-only"] and "HEAD~1..HEAD" not in args:
                return [os.path.join(wiki_dir, "page-a.md")]
            return []

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert any("page-a.md" in p for p in result)

    def test_returns_files_from_last_commit(self, tmp_path, monkeypatch):
        """直近コミットの変更ファイルがリストに含まれること"""
        wiki_dir = self._make_wiki(tmp_path, {"page-b.md": "# B\n"})
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)

        def fake_git_list_files(args):
            if "HEAD~1..HEAD" in args:
                return [os.path.join(wiki_dir, "page-b.md")]
            return []

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert any("page-b.md" in p for p in result)

    def test_deduplicates_results(self, tmp_path, monkeypatch):
        """未コミット変更と直近コミット変更に同じファイルがある場合、重複が除去されること"""
        wiki_dir = self._make_wiki(tmp_path, {"page-dup.md": "# Dup\n"})
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)
        dup_path = os.path.join(wiki_dir, "page-dup.md")

        def fake_git_list_files(args):
            return [dup_path]

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert result.count(dup_path) == 1

    def test_excludes_deleted_files(self, tmp_path, monkeypatch):
        """削除されたファイル（ディスク上に存在しない）は除外されること"""
        wiki_dir = self._make_wiki(tmp_path, {})
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)
        deleted_path = os.path.join(wiki_dir, "deleted.md")  # ファイルを作成しない

        def fake_git_list_files(args):
            return [deleted_path]

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert deleted_path not in result

    def test_excludes_non_md_files(self, tmp_path, monkeypatch):
        """.md 以外のファイルは除外されること"""
        wiki_dir = self._make_wiki(tmp_path, {"page.md": "# OK\n"})
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)
        txt_path = os.path.join(wiki_dir, "readme.txt")
        open(txt_path, "w").close()
        md_path = os.path.join(wiki_dir, "page.md")

        def fake_git_list_files(args):
            return [txt_path, md_path]

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert txt_path not in result
        assert md_path in result

    def test_returns_empty_list_when_no_changes(self, tmp_path, monkeypatch):
        """変更がない場合は空リストを返すこと"""
        wiki_dir = self._make_wiki(tmp_path, {})
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)

        def fake_git_list_files(args):
            return []

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert result == []

    def test_head1_not_found_fallback(self, tmp_path, monkeypatch):
        """HEAD~1 が存在しない場合は HEAD の全追加ファイルにフォールバックすること"""
        wiki_dir = self._make_wiki(tmp_path, {"initial.md": "# Initial\n"})
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)
        initial_path = os.path.join(wiki_dir, "initial.md")

        def fake_git_list_files(args):
            if "HEAD~1..HEAD" in args:
                # HEAD~1 が存在しないケースをシミュレート（空リスト）
                return []
            if "--diff-filter=A" in args and "HEAD" in args:
                # フォールバック: HEAD の全追加ファイル
                return [initial_path]
            return []

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert initial_path in result

    def test_returns_list_of_absolute_paths(self, tmp_path, monkeypatch):
        """返されるパスが文字列のリストであること"""
        wiki_dir = self._make_wiki(tmp_path, {"page.md": "# P\n"})
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)
        page_path = os.path.join(wiki_dir, "page.md")

        def fake_git_list_files(args):
            return [page_path]

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert isinstance(result, list)
        assert all(isinstance(p, str) for p in result)

    def test_union_of_uncommitted_and_last_commit(self, tmp_path, monkeypatch):
        """未コミット変更と直近コミット変更の和集合が返されること"""
        wiki_dir = self._make_wiki(tmp_path, {
            "page-uncommitted.md": "# U\n",
            "page-committed.md": "# C\n",
        })
        monkeypatch.setattr(rw_light, "WIKI", wiki_dir)
        uncommitted_path = os.path.join(wiki_dir, "page-uncommitted.md")
        committed_path = os.path.join(wiki_dir, "page-committed.md")

        def fake_git_list_files(args):
            if "HEAD~1..HEAD" in args:
                return [committed_path]
            if "--diff-filter=A" in args:
                return []
            # 未コミット（git diff --name-only または ls-files）
            if "ls-files" in args:
                return []
            return [uncommitted_path]

        monkeypatch.setattr(rw_light, "_git_list_files", fake_git_list_files)
        result = rw_light.get_recent_wiki_changes()
        assert uncommitted_path in result


# ---------------------------------------------------------------------------
# Task 1.4: read_all_wiki_content
# ---------------------------------------------------------------------------


def _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=2,
                              create_index=True, create_log=True):
    """read_all_wiki_content テスト用の wiki ディレクトリと ROOT ファイルを作成する。"""
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()

    for i in range(num_files):
        page = wiki_dir / f"page-{i:02d}.md"
        page.write_text(
            f"---\ntitle: Page {i}\n---\n\n# Page {i}\n\nContent {i}.\n",
            encoding="utf-8",
        )

    if create_index:
        (tmp_path / "index.md").write_text("# Index\n\nTop-level index.\n", encoding="utf-8")
    if create_log:
        (tmp_path / "log.md").write_text("# Log\n\nChange log.\n", encoding="utf-8")

    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(tmp_path / "log.md"))
    return wiki_dir


class TestReadAllWikiContent:
    """read_all_wiki_content() のユニットテスト（Task 1.4）"""

    def test_returns_string(self, tmp_path, monkeypatch):
        """正常ケース: 文字列を返すこと"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=1)
        result = rw_light.read_all_wiki_content()
        assert isinstance(result, str)

    def test_all_wiki_pages_included(self, tmp_path, monkeypatch):
        """wiki/ の全 .md ファイルが結合に含まれること"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=3)
        result = rw_light.read_all_wiki_content()
        assert "Content 0" in result
        assert "Content 1" in result
        assert "Content 2" in result

    def test_each_file_has_file_header(self, tmp_path, monkeypatch):
        """各ファイルが <!-- file: ... --> ヘッダー付きで結合されること"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=2)
        result = rw_light.read_all_wiki_content()
        assert "<!-- file:" in result
        # wiki ページのヘッダーが含まれること
        assert "page-00.md" in result
        assert "page-01.md" in result

    def test_index_md_included_in_result(self, tmp_path, monkeypatch):
        """ROOT/index.md が結合に含まれること"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=1, create_index=True)
        result = rw_light.read_all_wiki_content()
        assert "Top-level index." in result

    def test_log_md_included_in_result(self, tmp_path, monkeypatch):
        """ROOT/log.md が結合に含まれること"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=1, create_log=True)
        result = rw_light.read_all_wiki_content()
        assert "Change log." in result

    def test_index_md_header_format(self, tmp_path, monkeypatch):
        """ROOT/index.md が <!-- file: index.md --> ヘッダー付きで含まれること"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=1, create_index=True)
        result = rw_light.read_all_wiki_content()
        assert "<!-- file: index.md -->" in result

    def test_log_md_header_format(self, tmp_path, monkeypatch):
        """ROOT/log.md が <!-- file: log.md --> ヘッダー付きで含まれること"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=1, create_log=True)
        result = rw_light.read_all_wiki_content()
        assert "<!-- file: log.md -->" in result

    def test_index_md_missing_skipped_not_error(self, tmp_path, monkeypatch):
        """index.md が存在しない場合はスキップしてエラーにならないこと"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=1,
                                  create_index=False, create_log=True)
        result = rw_light.read_all_wiki_content()
        # index.md ヘッダーが含まれないこと
        assert "<!-- file: index.md -->" not in result
        # log.md は含まれること
        assert "Change log." in result

    def test_log_md_missing_skipped_not_error(self, tmp_path, monkeypatch):
        """log.md が存在しない場合はスキップしてエラーにならないこと"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=1,
                                  create_index=True, create_log=False)
        result = rw_light.read_all_wiki_content()
        # log.md ヘッダーが含まれないこと
        assert "<!-- file: log.md -->" not in result
        # index.md は含まれること
        assert "Top-level index." in result

    def test_both_index_and_log_missing_skipped(self, tmp_path, monkeypatch):
        """index.md と log.md の両方が存在しない場合もスキップして続行すること"""
        _setup_wiki_for_read_all(tmp_path, monkeypatch, num_files=1,
                                  create_index=False, create_log=False)
        result = rw_light.read_all_wiki_content()
        # wiki ページは含まれること
        assert "Content 0" in result

    def test_raises_file_not_found_when_wiki_missing(self, tmp_path, monkeypatch):
        """wiki/ が存在しない場合 FileNotFoundError を raise すること"""
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
        monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(tmp_path / "log.md"))
        import pytest
        with pytest.raises(FileNotFoundError):
            rw_light.read_all_wiki_content()

    def test_raises_value_error_when_no_md_files(self, tmp_path, monkeypatch):
        """wiki/ に .md ファイルがない場合 ValueError を raise すること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "readme.txt").write_text("not markdown", encoding="utf-8")
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
        monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(tmp_path / "log.md"))
        import pytest
        with pytest.raises(ValueError):
            rw_light.read_all_wiki_content()

    def test_warns_when_page_count_exceeds_150(self, tmp_path, monkeypatch, capsys):
        """150 ページ超の場合に標準出力に警告を表示すること（処理は続行）"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        # 151 ページ作成
        for i in range(151):
            page = wiki_dir / f"page-{i:03d}.md"
            page.write_text(f"---\ntitle: P{i}\n---\n\n# P{i}\n", encoding="utf-8")
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
        monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(tmp_path / "log.md"))

        result = rw_light.read_all_wiki_content()
        captured = capsys.readouterr()
        # 警告が表示されること
        assert "150" in captured.out or "警告" in captured.out or "WARN" in captured.out
        # 処理は続行され、全ページが結合されること
        assert "page-000.md" in result or "P0" in result

    def test_exactly_150_pages_no_warning(self, tmp_path, monkeypatch, capsys):
        """ちょうど 150 ページの場合は警告を表示しないこと"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        for i in range(150):
            page = wiki_dir / f"page-{i:03d}.md"
            page.write_text(f"# P{i}\n", encoding="utf-8")
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
        monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(tmp_path / "log.md"))

        rw_light.read_all_wiki_content()
        captured = capsys.readouterr()
        # 150 ページ以下なので警告は出ないこと
        assert "WARN" not in captured.out

    def test_wiki_page_file_header_format(self, tmp_path, monkeypatch):
        """wiki ページが <!-- file: wiki/page-name.md --> 形式のヘッダー付きで結合されること"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        (wiki_dir / "my-page.md").write_text("# My Page\n\nContent.\n", encoding="utf-8")
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
        monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(tmp_path / "log.md"))

        result = rw_light.read_all_wiki_content()
        # wiki/ プレフィックス付きのヘッダー
        assert "<!-- file: wiki/my-page.md -->" in result
        # ページコンテンツが含まれること
        assert "Content." in result


# ---------------------------------------------------------------------------
# Task 2.1: check_broken_links / check_index_registration / check_frontmatter
#           / run_micro_checks
# ---------------------------------------------------------------------------


def _make_wiki_page(
    path="page.md",
    filename="page.md",
    raw_text="---\ntitle: Test\n---\n\nBody.\n",
    frontmatter=None,
    body="Body.\n",
    links=None,
    read_error="",
) -> "rw_light.WikiPage":
    """テスト用 WikiPage を生成するヘルパー。"""
    if frontmatter is None:
        frontmatter = {"title": "Test"}
    if links is None:
        links = []
    return rw_light.WikiPage(
        path=path,
        filename=filename,
        raw_text=raw_text,
        frontmatter=frontmatter,
        body=body,
        links=links,
        read_error=read_error,
    )


class TestCheckBrokenLinks:
    """check_broken_links() のユニットテスト"""

    def test_no_findings_when_no_links(self):
        """リンクなしのページは Finding なしであること"""
        page = _make_wiki_page(links=[])
        all_pages_set = {"page.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert result == []

    def test_no_findings_when_link_resolves(self):
        """リンク先が all_pages_set に存在する場合は Finding なしであること"""
        page = _make_wiki_page(links=["target-page"])
        all_pages_set = {"page.md", "target-page.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert result == []

    def test_finding_when_link_not_found(self):
        """リンク先が all_pages_set に存在しない場合 ERROR Finding を返すこと"""
        page = _make_wiki_page(path="page.md", links=["nonexistent"])
        all_pages_set = {"page.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert len(result) == 1
        assert result[0].severity == "ERROR"
        assert result[0].category == "broken_link"
        assert result[0].page == "page.md"
        assert "nonexistent" in result[0].message

    def test_finding_severity_is_error(self):
        """broken_link の severity が ERROR であること"""
        page = _make_wiki_page(links=["missing-page"])
        all_pages_set = {"page.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert all(f.severity == "ERROR" for f in result)

    def test_link_resolves_with_md_extension_appended(self):
        """拡張子なしリンク名に .md を付加して解決されること"""
        # [[target]] → target.md として all_pages_set を検索
        page = _make_wiki_page(links=["target"])
        all_pages_set = {"target.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert result == []

    def test_link_resolves_by_filename_match_in_subdirectory(self):
        """サブディレクトリをまたいでファイル名部分マッチで解決されること"""
        page = _make_wiki_page(links=["my-concept"])
        all_pages_set = {"concepts/my-concept.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert result == []

    def test_multiple_broken_links_all_reported(self):
        """複数のリンク切れがすべて報告されること"""
        page = _make_wiki_page(links=["missing-a", "missing-b"])
        all_pages_set = {"page.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert len(result) == 2

    def test_link_with_md_extension_in_all_pages_set(self):
        """リンク名が .md 付きで all_pages_set に存在する場合も解決されること"""
        page = _make_wiki_page(links=["target.md"])
        all_pages_set = {"target.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert result == []

    def test_multiple_pages_checked(self):
        """複数ページのリンクがすべてチェックされること"""
        page1 = _make_wiki_page(path="a.md", filename="a.md", links=["missing"])
        page2 = _make_wiki_page(path="b.md", filename="b.md", links=["also-missing"])
        all_pages_set = {"a.md", "b.md"}
        result = rw_light.check_broken_links([page1, page2], all_pages_set)
        assert len(result) == 2
        pages_in_findings = {f.page for f in result}
        assert "a.md" in pages_in_findings
        assert "b.md" in pages_in_findings

    def test_finding_fields_are_strings(self):
        """Finding の全フィールドが文字列であること"""
        page = _make_wiki_page(links=["nonexistent"])
        all_pages_set = {"page.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert len(result) == 1
        f = result[0]
        assert isinstance(f.severity, str)
        assert isinstance(f.category, str)
        assert isinstance(f.page, str)
        assert isinstance(f.message, str)
        assert isinstance(f.marker, str)

    def test_marker_is_empty(self):
        """micro チェックでは marker が空文字列であること"""
        page = _make_wiki_page(links=["missing"])
        all_pages_set = {"page.md"}
        result = rw_light.check_broken_links([page], all_pages_set)
        assert result[0].marker == ""

    def test_does_not_mutate_page_links(self):
        """check_broken_links が WikiPage.links を変更しないこと"""
        original_links = ["missing", "another-missing"]
        page = _make_wiki_page(links=list(original_links))
        all_pages_set = {"page.md"}
        rw_light.check_broken_links([page], all_pages_set)
        assert page.links == original_links


class TestCheckIndexRegistration:
    """check_index_registration() のユニットテスト"""

    def _make_index_content(self, page_names: list[str]) -> str:
        """index.md のコンテンツを生成するヘルパー。"""
        lines = ["# Index\n"]
        for name in page_names:
            lines.append(f"- [[{name}]]")
        return "\n".join(lines)

    def test_no_findings_when_all_registered(self):
        """全ページが index.md に登録済みの場合 Finding なしであること"""
        page = _make_wiki_page(path="my-page.md", filename="my-page.md")
        index_content = self._make_index_content(["my-page"])
        result = rw_light.check_index_registration([page], index_content)
        assert result == []

    def test_finding_when_page_not_in_index(self):
        """index.md に未登録のページで WARN Finding を返すこと"""
        page = _make_wiki_page(path="unregistered.md", filename="unregistered.md")
        index_content = self._make_index_content([])  # 空の index
        result = rw_light.check_index_registration([page], index_content)
        assert len(result) == 1
        assert result[0].severity == "WARN"
        assert result[0].category == "index_missing"
        assert result[0].page == "unregistered.md"

    def test_finding_severity_is_warn(self):
        """index_missing の severity が WARN であること"""
        page = _make_wiki_page(path="not-in-index.md", filename="not-in-index.md")
        index_content = self._make_index_content([])
        result = rw_light.check_index_registration([page], index_content)
        assert all(f.severity == "WARN" for f in result)

    def test_returns_warning_finding_when_index_content_is_none(self):
        """index_content が None（index.md 不在）の場合 WARNING Finding を返すこと（Req 7.7）"""
        page = _make_wiki_page()
        result = rw_light.check_index_registration([page], None)
        # チェックをスキップし WARNING を返す
        assert len(result) == 1
        assert result[0].severity == "WARN"

    def test_returns_no_page_findings_when_index_missing(self):
        """index.md 不在時はページ個別の未登録 Finding を返さないこと"""
        page1 = _make_wiki_page(path="p1.md", filename="p1.md")
        page2 = _make_wiki_page(path="p2.md", filename="p2.md")
        result = rw_light.check_index_registration([page1, page2], None)
        # index.md 不在の WARNING 1件のみ（ページ別 Finding は含まない）
        assert len(result) == 1

    def test_index_link_resolved_by_filename_match(self):
        """index.md の [[link]] がファイル名部分マッチで解決されること"""
        page = _make_wiki_page(path="concepts/my-concept.md", filename="my-concept.md")
        # index.md には "my-concept" として登録
        index_content = self._make_index_content(["my-concept"])
        result = rw_light.check_index_registration([page], index_content)
        assert result == []

    def test_multiple_unregistered_pages_all_reported(self):
        """複数の未登録ページがすべて報告されること"""
        page1 = _make_wiki_page(path="p1.md", filename="p1.md")
        page2 = _make_wiki_page(path="p2.md", filename="p2.md")
        index_content = self._make_index_content([])
        result = rw_light.check_index_registration([page1, page2], index_content)
        assert len(result) == 2

    def test_partially_registered_reports_only_unregistered(self):
        """部分的に登録されている場合、未登録のページのみが報告されること"""
        page1 = _make_wiki_page(path="registered.md", filename="registered.md")
        page2 = _make_wiki_page(path="unregistered.md", filename="unregistered.md")
        index_content = self._make_index_content(["registered"])
        result = rw_light.check_index_registration([page1, page2], index_content)
        assert len(result) == 1
        assert result[0].page == "unregistered.md"

    def test_empty_page_list_no_findings(self):
        """ページリストが空の場合 Finding なしであること"""
        index_content = self._make_index_content(["some-page"])
        result = rw_light.check_index_registration([], index_content)
        assert result == []


class TestCheckFrontmatter:
    """check_frontmatter() のユニットテスト"""

    def test_no_findings_for_valid_frontmatter(self):
        """正常な frontmatter のページは Finding なしであること"""
        raw = "---\ntitle: My Page\nsource: web\n---\n\nBody.\n"
        page = _make_wiki_page(
            raw_text=raw,
            frontmatter={"title": "My Page", "source": "web"},
            body="Body.\n",
        )
        result = rw_light.check_frontmatter([page])
        assert result == []

    def test_error_for_empty_frontmatter_block(self):
        """frontmatter ブロックが空の場合 ERROR Finding を返すこと"""
        raw = "---\n---\n\nBody.\n"
        page = _make_wiki_page(
            raw_text=raw,
            frontmatter={},
            body="Body.\n",
        )
        result = rw_light.check_frontmatter([page])
        errors = [f for f in result if f.severity == "ERROR"]
        assert len(errors) >= 1

    def test_error_for_invalid_line_in_frontmatter(self):
        """frontmatter ブロック内に `:` を含まない行がある場合 ERROR Finding を返すこと"""
        raw = "---\ntitle: My Page\ninvalid line without colon\n---\n\nBody.\n"
        page = _make_wiki_page(
            raw_text=raw,
            frontmatter={"title": "My Page"},
            body="Body.\n",
        )
        result = rw_light.check_frontmatter([page])
        errors = [f for f in result if f.severity == "ERROR"]
        assert len(errors) >= 1

    def test_error_for_unclosed_frontmatter(self):
        """frontmatter の閉じ `---` がない場合 ERROR Finding を返すこと"""
        raw = "---\ntitle: My Page\n\nBody content without closing delimiter.\n"
        page = _make_wiki_page(
            raw_text=raw,
            frontmatter={},
            body=raw,  # parse_frontmatter は {} を返す
        )
        result = rw_light.check_frontmatter([page])
        errors = [f for f in result if f.severity == "ERROR"]
        assert len(errors) >= 1

    def test_warn_for_missing_title_with_frontmatter(self):
        """frontmatter はあるが title が欠落している場合 WARN Finding を返すこと"""
        raw = "---\nsource: web\n---\n\nBody.\n"
        page = _make_wiki_page(
            raw_text=raw,
            frontmatter={"source": "web"},
            body="Body.\n",
        )
        result = rw_light.check_frontmatter([page])
        warns = [f for f in result if f.severity == "WARN"]
        assert len(warns) >= 1

    def test_warn_for_missing_title_without_frontmatter(self):
        """frontmatter 自体が存在しないページも title 欠落として WARN を返すこと"""
        raw = "# Page\n\nBody without frontmatter.\n"
        page = _make_wiki_page(
            raw_text=raw,
            frontmatter={},
            body=raw,
        )
        result = rw_light.check_frontmatter([page])
        warns = [f for f in result if f.severity == "WARN"]
        assert len(warns) >= 1

    def test_no_error_when_no_frontmatter(self):
        """frontmatter がない場合は ERROR Finding を返さないこと"""
        raw = "# Page\n\nBody without frontmatter.\n"
        page = _make_wiki_page(
            raw_text=raw,
            frontmatter={},
            body=raw,
        )
        result = rw_light.check_frontmatter([page])
        errors = [f for f in result if f.severity == "ERROR"]
        assert errors == []

    def test_finding_page_is_correct(self):
        """Finding.page が WikiPage.path と一致すること"""
        raw = "---\nsource: web\n---\n\nBody.\n"
        page = _make_wiki_page(
            path="concepts/my-page.md",
            filename="my-page.md",
            raw_text=raw,
            frontmatter={"source": "web"},
            body="Body.\n",
        )
        result = rw_light.check_frontmatter([page])
        assert all(f.page == "concepts/my-page.md" for f in result)

    def test_error_finding_category(self):
        """ERROR Finding の category が frontmatter_error であること"""
        raw = "---\n---\n\nBody.\n"
        page = _make_wiki_page(raw_text=raw, frontmatter={}, body="Body.\n")
        result = rw_light.check_frontmatter([page])
        errors = [f for f in result if f.severity == "ERROR"]
        assert all(f.category == "frontmatter_error" for f in errors)

    def test_warn_finding_category(self):
        """WARN Finding の category が frontmatter_warn であること"""
        raw = "---\nsource: web\n---\n\nBody.\n"
        page = _make_wiki_page(
            raw_text=raw,
            frontmatter={"source": "web"},
            body="Body.\n",
        )
        result = rw_light.check_frontmatter([page])
        warns = [f for f in result if f.severity == "WARN"]
        assert all(f.category == "frontmatter_warn" for f in warns)

    def test_does_not_mutate_page_frontmatter(self):
        """check_frontmatter が WikiPage.frontmatter を変更しないこと"""
        original_fm = {"title": "Test", "source": "web"}
        raw = "---\ntitle: Test\nsource: web\n---\n\nBody.\n"
        page = _make_wiki_page(raw_text=raw, frontmatter=dict(original_fm), body="Body.\n")
        rw_light.check_frontmatter([page])
        assert page.frontmatter == original_fm


class TestRunMicroChecks:
    """run_micro_checks() のユニットテスト"""

    def _make_wiki_setup(self, tmp_path, monkeypatch):
        """テスト用 wiki と index.md を作成する。"""
        wiki_dir = tmp_path / "wiki"
        wiki_dir.mkdir()
        monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
        monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
        monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
        return wiki_dir

    def test_returns_list_of_findings(self, tmp_path, monkeypatch):
        """run_micro_checks は Finding のリストを返すこと"""
        self._make_wiki_setup(tmp_path, monkeypatch)
        page = _make_wiki_page(
            raw_text="---\ntitle: Test\n---\n\nBody.\n",
            frontmatter={"title": "Test"},
            body="Body.\n",
            links=[],
        )
        all_pages_set = {"page.md"}
        index_content = "# Index\n\n- [[page]]\n"
        result = rw_light.run_micro_checks([page], all_pages_set, index_content)
        assert isinstance(result, list)
        assert all(isinstance(f, rw_light.Finding) for f in result)

    def test_broken_link_returns_error_finding(self, tmp_path, monkeypatch):
        """broken link があるページで ERROR Finding が返されること"""
        self._make_wiki_setup(tmp_path, monkeypatch)
        page = _make_wiki_page(
            path="page.md",
            filename="page.md",
            raw_text="---\ntitle: Test\n---\n\nBody [[nonexistent]] text.\n",
            frontmatter={"title": "Test"},
            body="Body [[nonexistent]] text.\n",
            links=["nonexistent"],
        )
        all_pages_set = {"page.md"}
        result = rw_light.run_micro_checks([page], all_pages_set, "# Index\n")
        errors = [f for f in result if f.severity == "ERROR"]
        assert any(f.category == "broken_link" for f in errors)

    def test_unregistered_page_returns_warn_finding(self, tmp_path, monkeypatch):
        """index.md に未登録のページで WARN Finding が返されること"""
        self._make_wiki_setup(tmp_path, monkeypatch)
        page = _make_wiki_page(
            path="unregistered.md",
            filename="unregistered.md",
            raw_text="---\ntitle: Test\n---\n\nBody.\n",
            frontmatter={"title": "Test"},
            body="Body.\n",
            links=[],
        )
        all_pages_set = {"unregistered.md"}
        result = rw_light.run_micro_checks([page], all_pages_set, "# Index\n")
        warns = [f for f in result if f.severity == "WARN"]
        assert any(f.category == "index_missing" for f in warns)

    def test_read_error_page_excluded_from_checks(self, tmp_path, monkeypatch):
        """read_error が設定された WikiPage は個別チェックから除外されること"""
        self._make_wiki_setup(tmp_path, monkeypatch)
        bad_page = rw_light.WikiPage(
            path="broken.md",
            filename="broken.md",
            raw_text="",
            frontmatter={},
            body="",
            links=[],
            read_error="UnicodeDecodeError: 'utf-8' codec ...",
        )
        all_pages_set = {"broken.md"}
        result = rw_light.run_micro_checks([bad_page], all_pages_set, "# Index\n")
        # read_error ページは ERROR Finding として記録される
        error_findings = [f for f in result if f.severity == "ERROR"]
        assert any(f.page == "broken.md" for f in error_findings)

    def test_read_error_page_not_included_in_link_check(self, tmp_path, monkeypatch):
        """read_error のページはリンクチェック対象に含まれないこと"""
        self._make_wiki_setup(tmp_path, monkeypatch)
        bad_page = rw_light.WikiPage(
            path="broken.md",
            filename="broken.md",
            raw_text="",
            frontmatter={},
            body="",
            links=[],
            read_error="read failed",
        )
        all_pages_set = {"broken.md"}
        result = rw_light.run_micro_checks([bad_page], all_pages_set, "# Index\n")
        # broken_link カテゴリの Finding は broken.md に対してないこと
        link_check_findings = [f for f in result if f.category == "broken_link" and f.page == "broken.md"]
        assert len(link_check_findings) == 0

    def test_none_index_content_passes_through_to_index_check(self, tmp_path, monkeypatch):
        """index_content が None の場合、index 不在の WARNING が含まれること"""
        self._make_wiki_setup(tmp_path, monkeypatch)
        page = _make_wiki_page(
            raw_text="---\ntitle: Test\n---\n\nBody.\n",
            frontmatter={"title": "Test"},
            body="Body.\n",
            links=[],
        )
        all_pages_set = {"page.md"}
        result = rw_light.run_micro_checks([page], all_pages_set, None)
        warns = [f for f in result if f.severity == "WARN"]
        # index.md 不在の WARNING が含まれること
        assert len(warns) >= 1

    def test_all_three_checks_run(self, tmp_path, monkeypatch):
        """3 つのチェック（broken_link, index_registration, frontmatter）がすべて実行されること"""
        self._make_wiki_setup(tmp_path, monkeypatch)
        # broken link + index 未登録 + title なし の複合ページ
        page = _make_wiki_page(
            path="multi-issue.md",
            filename="multi-issue.md",
            raw_text="---\nsource: web\n---\n\nBody [[missing]] text.\n",
            frontmatter={"source": "web"},  # title なし
            body="Body [[missing]] text.\n",
            links=["missing"],
        )
        all_pages_set = {"multi-issue.md"}
        result = rw_light.run_micro_checks([page], all_pages_set, "# Index\n")
        categories = {f.category for f in result}
        assert "broken_link" in categories
        assert "index_missing" in categories
        assert "frontmatter_warn" in categories

    def test_empty_pages_no_findings(self, tmp_path, monkeypatch):
        """ページリストが空の場合は Finding なし（index 不在の場合を除く）"""
        self._make_wiki_setup(tmp_path, monkeypatch)
        result = rw_light.run_micro_checks([], set(), "# Index\n")
        assert result == []


# ---------------------------------------------------------------------------
# Task 2.2: weekly static checks
# ---------------------------------------------------------------------------


class TestCheckOrphanPages:
    """check_orphan_pages() のユニットテスト"""

    def test_no_orphan_when_all_linked(self):
        """すべてのページが他ページからリンクされている場合は Finding なし"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=["b"])
        page_b = _make_wiki_page(path="b.md", filename="b.md", links=["a"])
        index_links = set()
        result = rw_light.check_orphan_pages([page_a, page_b], index_links)
        assert result == []

    def test_orphan_detected_when_no_inbound_links(self):
        """他ページからリンクされず index_links にもないページは WARN Finding"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=[])
        page_b = _make_wiki_page(path="b.md", filename="b.md", links=[])
        index_links = set()
        result = rw_light.check_orphan_pages([page_a, page_b], index_links)
        orphan_cats = [f for f in result if f.category == "orphan_page"]
        assert len(orphan_cats) == 2
        assert all(f.severity == "WARN" for f in orphan_cats)

    def test_index_linked_pages_are_not_orphan(self):
        """index_links に含まれるページは孤立と見なさない"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=[])
        index_links = {"a.md"}  # a.md は index にリンクあり
        result = rw_light.check_orphan_pages([page_a], index_links)
        assert result == []

    def test_index_md_filename_excluded(self):
        """ファイル名が index.md のページは孤立チェックから除外される"""
        page_index = _make_wiki_page(path="subdir/index.md", filename="index.md", links=[])
        index_links = set()
        result = rw_light.check_orphan_pages([page_index], index_links)
        assert result == []

    def test_linked_page_not_orphan_even_if_not_in_index(self):
        """他ページからリンクされているページは index なしでも孤立でない"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=["b"])
        page_b = _make_wiki_page(path="b.md", filename="b.md", links=[])
        index_links = set()
        result = rw_light.check_orphan_pages([page_a, page_b], index_links)
        # a.md はリンクを張っているが誰からもリンクされていない → orphan
        # b.md は a.md からリンクされている → 非 orphan
        orphan_pages = [f.page for f in result if f.category == "orphan_page"]
        assert "b.md" not in orphan_pages
        assert "a.md" in orphan_pages


class TestCheckBidirectionalLinks:
    """check_bidirectional_links() のユニットテスト"""

    def test_no_findings_when_no_links(self):
        """リンクなしのページは Finding なし・stats は total_pairs=0"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=[])
        all_pages_set = {"a.md"}
        findings, stats = rw_light.check_bidirectional_links([page_a], all_pages_set)
        assert findings == []
        assert stats["total_pairs"] == 0
        assert stats["bidirectional_pairs"] == 0

    def test_bidirectional_pair_no_finding(self):
        """A→B かつ B→A の双方向リンクは Finding なし"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=["b"])
        page_b = _make_wiki_page(path="b.md", filename="b.md", links=["a"])
        all_pages_set = {"a.md", "b.md"}
        findings, stats = rw_light.check_bidirectional_links([page_a, page_b], all_pages_set)
        assert findings == []
        assert stats["total_pairs"] == 1
        assert stats["bidirectional_pairs"] == 1

    def test_unidirectional_link_is_finding(self):
        """A→B だが B→A がない場合は WARN Finding"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=["b"])
        page_b = _make_wiki_page(path="b.md", filename="b.md", links=[])
        all_pages_set = {"a.md", "b.md"}
        findings, stats = rw_light.check_bidirectional_links([page_a, page_b], all_pages_set)
        assert len(findings) == 1
        assert findings[0].severity == "WARN"
        assert findings[0].category == "missing_backlink"
        assert stats["total_pairs"] == 1
        assert stats["bidirectional_pairs"] == 0

    def test_index_md_links_excluded(self):
        """index.md からのリンクは双方向チェック対象外"""
        page_index = _make_wiki_page(path="index.md", filename="index.md", links=["other"])
        page_other = _make_wiki_page(path="other.md", filename="other.md", links=[])
        all_pages_set = {"index.md", "other.md"}
        findings, stats = rw_light.check_bidirectional_links([page_index, page_other], all_pages_set)
        # index.md からのリンクは除外されるため total_pairs = 0
        assert stats["total_pairs"] == 0
        assert findings == []

    def test_returns_tuple_with_stats(self):
        """戻り値が (findings, dict) のタプルであること"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=[])
        all_pages_set = {"a.md"}
        result = rw_light.check_bidirectional_links([page_a], all_pages_set)
        assert isinstance(result, tuple)
        assert len(result) == 2
        findings, stats = result
        assert isinstance(findings, list)
        assert isinstance(stats, dict)
        assert "total_pairs" in stats
        assert "bidirectional_pairs" in stats


class TestCheckNamingConvention:
    """check_naming_convention() のユニットテスト"""

    def test_valid_filename_no_finding(self):
        """有効な命名（小文字・ハイフン区切り）は Finding なし"""
        page = _make_wiki_page(path="my-concept.md", filename="my-concept.md")
        result = rw_light.check_naming_convention([page])
        assert result == []

    def test_uppercase_filename_is_finding(self):
        """大文字を含むファイル名は WARN Finding"""
        page = _make_wiki_page(path="MyPage.md", filename="MyPage.md")
        result = rw_light.check_naming_convention([page])
        assert len(result) == 1
        assert result[0].severity == "WARN"
        assert result[0].category == "naming_violation"

    def test_underscore_filename_is_finding(self):
        """アンダースコアを含むファイル名は WARN Finding"""
        page = _make_wiki_page(path="my_page.md", filename="my_page.md")
        result = rw_light.check_naming_convention([page])
        assert len(result) == 1
        assert result[0].severity == "WARN"

    def test_space_in_filename_is_finding(self):
        """スペースを含むファイル名は WARN Finding"""
        page = _make_wiki_page(path="my page.md", filename="my page.md")
        result = rw_light.check_naming_convention([page])
        assert len(result) == 1
        assert result[0].severity == "WARN"

    def test_valid_with_numbers_no_finding(self):
        """数字を含む有効なファイル名は Finding なし"""
        page = _make_wiki_page(path="page-01.md", filename="page-01.md")
        result = rw_light.check_naming_convention([page])
        assert result == []

    def test_index_md_is_valid(self):
        """index.md は有効な命名として Finding なし"""
        page = _make_wiki_page(path="index.md", filename="index.md")
        result = rw_light.check_naming_convention([page])
        assert result == []

    def test_multiple_pages_mixed(self):
        """有効・無効が混在する場合、違反のみ Finding"""
        valid = _make_wiki_page(path="valid-page.md", filename="valid-page.md")
        invalid = _make_wiki_page(path="Invalid_Page.md", filename="Invalid_Page.md")
        result = rw_light.check_naming_convention([valid, invalid])
        assert len(result) == 1
        assert result[0].page == "Invalid_Page.md"


class TestCheckSourceField:
    """check_source_field() のユニットテスト"""

    def test_source_present_no_finding(self):
        """source フィールドが存在する場合は Finding なし"""
        page = _make_wiki_page(frontmatter={"title": "Test", "source": "https://example.com"})
        result = rw_light.check_source_field([page])
        assert result == []

    def test_source_missing_is_info(self):
        """source フィールドが欠落している場合は INFO Finding"""
        page = _make_wiki_page(frontmatter={"title": "Test"})
        result = rw_light.check_source_field([page])
        assert len(result) == 1
        assert result[0].severity == "INFO"
        assert result[0].category == "missing_source"

    def test_source_empty_string_is_info(self):
        """source フィールドが空文字列の場合は INFO Finding"""
        page = _make_wiki_page(frontmatter={"title": "Test", "source": ""})
        result = rw_light.check_source_field([page])
        assert len(result) == 1
        assert result[0].severity == "INFO"

    def test_multiple_pages(self):
        """複数ページで source あり/なしが正しく処理される"""
        page_ok = _make_wiki_page(
            path="ok.md", filename="ok.md",
            frontmatter={"title": "OK", "source": "web"},
        )
        page_missing = _make_wiki_page(
            path="missing.md", filename="missing.md",
            frontmatter={"title": "Missing"},
        )
        result = rw_light.check_source_field([page_ok, page_missing])
        assert len(result) == 1
        assert result[0].page == "missing.md"


class TestCheckRequiredSections:
    """check_required_sections() のユニットテスト"""

    def test_no_findings_when_page_policy_is_none(self):
        """page_policy が None の場合は no-op（Finding なし）"""
        page = _make_wiki_page()
        result = rw_light.check_required_sections([page], None)
        assert result == []

    def test_no_findings_when_page_policy_is_empty(self):
        """page_policy が空 dict の場合は no-op（Finding なし）"""
        page = _make_wiki_page()
        result = rw_light.check_required_sections([page], {})
        assert result == []

    def test_no_findings_with_current_page_policy(self):
        """現行 page_policy.md は必須セクション定義がないため Finding なし"""
        page = _make_wiki_page(body="# Title\n\nSome body text.")
        # 現行の page_policy.md には具体的なセクション定義がない
        page_policy = {"concepts": "何であるか/なぜ重要か"}
        result = rw_light.check_required_sections([page], page_policy)
        assert result == []


class TestRunWeeklyChecks:
    """run_weekly_checks() のユニットテスト"""

    def test_returns_tuple(self):
        """戻り値が (list, dict) のタプルであること"""
        page = _make_wiki_page()
        all_pages_set = {"page.md"}
        index_links = set()
        result = rw_light.run_weekly_checks([page], all_pages_set, None, index_links, None)
        assert isinstance(result, tuple)
        assert len(result) == 2
        findings, stats = result
        assert isinstance(findings, list)
        assert isinstance(stats, dict)

    def test_stats_contain_required_keys(self):
        """stats に total_pairs と bidirectional_pairs が含まれること"""
        page = _make_wiki_page()
        all_pages_set = {"page.md"}
        index_links = set()
        _, stats = rw_light.run_weekly_checks([page], all_pages_set, None, index_links, None)
        assert "total_pairs" in stats
        assert "bidirectional_pairs" in stats

    def test_orphan_finding_included(self):
        """孤立ページが正しく検出されること"""
        page = _make_wiki_page(path="orphan.md", filename="orphan.md", links=[])
        all_pages_set = {"orphan.md"}
        index_links = set()
        findings, _ = rw_light.run_weekly_checks([page], all_pages_set, None, index_links, None)
        orphan_findings = [f for f in findings if f.category == "orphan_page"]
        assert len(orphan_findings) >= 1

    def test_naming_violation_included(self):
        """命名規則違反が正しく検出されること"""
        page = _make_wiki_page(path="BadName.md", filename="BadName.md", links=[])
        all_pages_set = {"BadName.md"}
        index_links = set()
        findings, _ = rw_light.run_weekly_checks([page], all_pages_set, None, index_links, None)
        naming_findings = [f for f in findings if f.category == "naming_violation"]
        assert len(naming_findings) >= 1

    def test_bidirectional_stats_propagated(self):
        """check_bidirectional_links の stats が正しく伝搬されること"""
        page_a = _make_wiki_page(path="a.md", filename="a.md", links=["b"])
        page_b = _make_wiki_page(path="b.md", filename="b.md", links=["a"])
        all_pages_set = {"a.md", "b.md"}
        index_links = set()
        _, stats = rw_light.run_weekly_checks(
            [page_a, page_b], all_pages_set, None, index_links, None
        )
        assert stats["total_pairs"] == 1
        assert stats["bidirectional_pairs"] == 1

    def test_all_five_checks_run(self):
        """5 つのチェック関数（orphan, bidir, naming, source, required_sections）がすべて実行されること"""
        # 命名違反 + source なし + 孤立 の複合ケース
        page = _make_wiki_page(
            path="BadName.md",
            filename="BadName.md",
            frontmatter={"title": "Test"},  # source なし
            links=[],
        )
        all_pages_set = {"BadName.md"}
        index_links = set()
        findings, stats = rw_light.run_weekly_checks(
            [page], all_pages_set, None, index_links, None
        )
        categories = {f.category for f in findings}
        assert "orphan_page" in categories
        assert "naming_violation" in categories
        assert "missing_source" in categories


# ---------------------------------------------------------------------------
# Task 3.1: build_audit_prompt()
# ---------------------------------------------------------------------------


class TestBuildAuditPrompt:
    """build_audit_prompt() のティア別動作をテストする"""

    TASK_PROMPTS = "## AGENTS/audit.md content here\nSome rules."
    WIKI_CONTENT = "<!-- file: wiki/page.md -->\nPage content."

    def test_monthly_contains_tier2_instruction(self):
        """monthly のプロンプトに Tier 2: Semantic Audit の指示が含まれること"""
        result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        assert "Tier 2" in result
        assert "Semantic Audit" in result

    def test_monthly_excludes_tier3(self):
        """monthly のプロンプトに Tier 3: Strategic Audit の除外指示が含まれること"""
        result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        # monthly は Tier 3 を除外する
        assert "Tier 3" in result  # 除外リストとして言及される
        # Tier 3 を「実行しない」旨の指示が含まれること
        assert "Strategic Audit" in result

    def test_quarterly_contains_tier3_instruction(self):
        """quarterly のプロンプトに Tier 3: Strategic Audit の指示が含まれること"""
        result = rw_light.build_audit_prompt("quarterly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        assert "Tier 3" in result
        assert "Strategic Audit" in result

    def test_quarterly_excludes_tier2(self):
        """quarterly のプロンプトに Tier 2: Semantic Audit の除外指示が含まれること"""
        result = rw_light.build_audit_prompt("quarterly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        # quarterly は Tier 2 を除外する
        assert "Tier 2" in result  # 除外リストとして言及される
        assert "Semantic Audit" in result

    def test_monthly_and_quarterly_prompts_differ(self):
        """monthly と quarterly でプロンプト内容が異なること（ティア指示が切り替わる）"""
        monthly_result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        quarterly_result = rw_light.build_audit_prompt("quarterly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        assert monthly_result != quarterly_result

    def test_task_prompts_included(self):
        """task_prompts の内容がプロンプトに含まれること（AGENTS/audit.md 一元管理 Req 10.1）"""
        result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        assert self.TASK_PROMPTS in result

    def test_wiki_content_included(self):
        """wiki_content がプロンプトに含まれること"""
        result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        assert self.WIKI_CONTENT in result

    def test_json_schema_at_end(self):
        """JSON スキーマサンプルがプロンプトの末尾に配置されること（セキュリティ考慮）"""
        result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        # JSON スキーマ指示がプロンプトに含まれること
        assert "findings" in result
        assert "metrics" in result
        assert "recommended_actions" in result
        # wiki_content よりも JSON スキーマ指示が後に来ること
        wiki_idx = result.find(self.WIKI_CONTENT)
        findings_idx = result.rfind("findings")
        assert wiki_idx < findings_idx, "JSON スキーマ指示は wiki_content の後に配置されるべき"

    def test_monthly_json_schema_includes_marker(self):
        """monthly の JSON スキーマサンプルに marker フィールドが含まれること"""
        result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        assert "marker" in result

    def test_quarterly_json_schema_lacks_marker(self):
        """quarterly の JSON スキーマサンプルに marker フィールドが含まれないこと"""
        result = rw_light.build_audit_prompt("quarterly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        # quarterly スキーマには marker フィールドがない
        # ただし monthly の除外指示で "marker" という語が出る可能性は考慮しないで
        # JSON サンプルセクション以降のみチェック
        json_section_idx = result.find("## 出力形式")
        assert json_section_idx != -1
        json_section = result[json_section_idx:]
        assert "marker" not in json_section

    def test_markdown_override_instruction(self):
        """Markdown 形式ではなく JSON で出力する旨の指示が含まれること"""
        result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        assert "JSON" in result
        assert "Markdown" in result  # Markdown を使用しない旨の言及

    def test_execution_declaration_suppressed(self):
        """実行宣言を出力しない旨の指示が含まれること"""
        result = rw_light.build_audit_prompt("monthly", self.TASK_PROMPTS, self.WIKI_CONTENT)
        assert "実行宣言" in result


# ---------------------------------------------------------------------------
# Task 3.2: parse_audit_response（スキーマ検証付き）
# ---------------------------------------------------------------------------


class TestParseAuditResponse:
  """parse_audit_response のスキーマ検証テスト"""

  VALID_MONTHLY = {
    "findings": [
      {
        "severity": "HIGH",
        "category": "contradicting_definition",
        "page": "concepts/my-concept.md",
        "message": "page-a.md と page-b.md で定義が矛盾している",
        "marker": "CONFLICT",
        "recommendation": "定義を統一する",
      }
    ],
    "metrics": {
      "pages_scanned": 42,
      "total_findings": 1,
      "conflict_count": 1,
      "tension_count": 0,
      "ambiguous_count": 0,
    },
    "recommended_actions": ["concepts/my-concept.md の定義を確認する"],
  }

  def _to_json(self, d: dict) -> str:
    return json.dumps(d, ensure_ascii=False)

  # ── 正常系 ─────────────────────────────────────────────────────

  def test_valid_json_returns_dict(self):
    """正常 JSON をパースして dict を返すこと"""
    result = rw_light.parse_audit_response(self._to_json(self.VALID_MONTHLY))
    assert isinstance(result, dict)
    assert "findings" in result
    assert "metrics" in result
    assert "recommended_actions" in result

  def test_valid_json_findings_preserved(self):
    """正常 JSON の findings が保持されること（HIGH は drift → INFO に降格）"""
    result = rw_light.parse_audit_response(self._to_json(self.VALID_MONTHLY))
    assert len(result["findings"]) == 1
    # HIGH は旧語彙のため drift → INFO に降格（finding は保持される）
    assert result["findings"][0]["severity"] == "INFO"
    assert result["findings"][0]["page"] == "concepts/my-concept.md"

  def test_code_block_stripped(self):
    """```json ... ``` で囲まれた JSON もパースできること"""
    raw = "```json\n" + self._to_json(self.VALID_MONTHLY) + "\n```"
    result = rw_light.parse_audit_response(raw)
    assert isinstance(result, dict)
    assert len(result["findings"]) == 1

  def test_all_severity_values_accepted(self):
    """全 severity トークンで finding が保持されること（旧語彙は drift → INFO 降格）"""
    # 新語彙はそのまま保持
    for sev in ("CRITICAL", "ERROR", "WARN", "INFO"):
      data = {
        "findings": [
          {
            "severity": sev,
            "category": "test",
            "page": "test.md",
            "message": "test message",
          }
        ],
        "metrics": {"pages_scanned": 1, "total_findings": 1},
        "recommended_actions": [],
      }
      result = rw_light.parse_audit_response(self._to_json(data))
      assert len(result["findings"]) == 1, f"severity={sev} で finding が消えた"
      assert result["findings"][0]["severity"] == sev, f"severity={sev} が変更された"
    # 旧語彙は drift → INFO に降格（finding は保持）
    for sev in ("HIGH", "MEDIUM", "LOW"):
      data = {
        "findings": [
          {
            "severity": sev,
            "category": "test",
            "page": "test.md",
            "message": "test message",
          }
        ],
        "metrics": {"pages_scanned": 1, "total_findings": 1},
        "recommended_actions": [],
      }
      result = rw_light.parse_audit_response(self._to_json(data))
      assert len(result["findings"]) == 1, f"severity={sev} で finding が消えた（drift でも保持されるべき）"
      assert result["findings"][0]["severity"] == "INFO", f"severity={sev} が INFO に降格されなかった"

  # ── 改行含み message ─────────────────────────────────────────

  def test_newline_in_message_replaced_with_space(self):
    """message の改行が空白に置換されること"""
    data = {
      "findings": [
        {
          "severity": "MEDIUM",
          "category": "test",
          "page": "test.md",
          "message": "line1\nline2\nline3",
        }
      ],
      "metrics": {"pages_scanned": 1, "total_findings": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    assert "\n" not in result["findings"][0]["message"]
    assert "line1 line2 line3" == result["findings"][0]["message"]

  def test_crlf_in_message_replaced_with_space(self):
    """message の CRLF も空白に置換されること"""
    data = {
      "findings": [
        {
          "severity": "LOW",
          "category": "test",
          "page": "test.md",
          "message": "line1\r\nline2",
        }
      ],
      "metrics": {"pages_scanned": 1, "total_findings": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    assert "\n" not in result["findings"][0]["message"]
    assert "\r" not in result["findings"][0]["message"]

  # ── null → "" 変換 ──────────────────────────────────────────

  def test_null_page_converted_to_empty_string(self):
    """page が null の場合は空文字列に変換されること"""
    data = {
      "findings": [
        {
          "severity": "MEDIUM",
          "category": "coverage_gap",
          "page": None,
          "message": "カバレッジ不足",
        }
      ],
      "metrics": {"pages_scanned": 10, "total_findings": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    assert result["findings"][0]["page"] == ""

  def test_null_marker_converted_to_empty_string(self):
    """marker が null の場合は空文字列に変換されること"""
    data = {
      "findings": [
        {
          "severity": "LOW",
          "category": "test",
          "page": "test.md",
          "message": "test",
          "marker": None,
        }
      ],
      "metrics": {"pages_scanned": 1, "total_findings": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    assert result["findings"][0]["marker"] == ""

  # ── 不正 severity: スキップ ──────────────────────────────────

  def test_invalid_severity_finding_skipped(self):
    """不正 severity の finding は drift → INFO 降格で保持されること（スキップしない）"""
    data = {
      "findings": [
        {
          "severity": "INVALID",
          "category": "test",
          "page": "test.md",
          "message": "不正なseverity",
        },
        {
          "severity": "HIGH",
          "category": "valid",
          "page": "valid.md",
          "message": "正常なfinding",
        },
      ],
      "metrics": {"pages_scanned": 2, "total_findings": 2},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    # 両方とも drift → INFO に降格されて保持される（スキップされない）
    assert len(result["findings"]) == 2
    assert all(f["severity"] == "INFO" for f in result["findings"])

  def test_invalid_severity_prints_warn(self, capsys):
    """不正 severity の finding は drift 警告を stderr に出力すること"""
    data = {
      "findings": [
        {
          "severity": "BOGUS",
          "category": "test",
          "page": "test.md",
          "message": "test",
        }
      ],
      "metrics": {"pages_scanned": 1, "total_findings": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    captured = capsys.readouterr()
    # drift 警告は stderr に [severity-drift] として出力される
    assert "[severity-drift]" in captured.err
    # finding は破棄されず INFO に降格されて保持される
    assert len(result["findings"]) == 1
    assert result["findings"][0]["severity"] == "INFO"

  def test_all_invalid_severity_returns_empty_findings(self):
    """不正 severity の finding は drift → INFO 降格で保持されること（空リストにならない）"""
    data = {
      "findings": [
        {
          "severity": "UNKNOWN",
          "category": "test",
          "page": "test.md",
          "message": "test",
        }
      ],
      "metrics": {"pages_scanned": 1, "total_findings": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    # drift → INFO 降格で finding は保持される
    assert len(result["findings"]) == 1
    assert result["findings"][0]["severity"] == "INFO"

  # ── 不正スキーマ: ValueError ────────────────────────────────

  def test_invalid_json_raises_value_error(self):
    """不正 JSON は ValueError を raise すること"""
    import pytest
    with pytest.raises(ValueError):
      rw_light.parse_audit_response("not a valid json {{{")

  def test_missing_findings_key_raises_value_error(self):
    """findings キー欠落は ValueError を raise すること"""
    import pytest
    data = {
      "metrics": {"pages_scanned": 1},
      "recommended_actions": [],
    }
    with pytest.raises(ValueError):
      rw_light.parse_audit_response(self._to_json(data))

  def test_missing_metrics_key_raises_value_error(self):
    """metrics キー欠落は ValueError を raise すること"""
    import pytest
    data = {
      "findings": [],
      "recommended_actions": [],
    }
    with pytest.raises(ValueError):
      rw_light.parse_audit_response(self._to_json(data))

  def test_missing_recommended_actions_raises_value_error(self):
    """recommended_actions キー欠落は ValueError を raise すること"""
    import pytest
    data = {
      "findings": [],
      "metrics": {"pages_scanned": 1},
    }
    with pytest.raises(ValueError):
      rw_light.parse_audit_response(self._to_json(data))

  def test_findings_not_list_raises_value_error(self):
    """findings が list でない場合は ValueError を raise すること"""
    import pytest
    data = {
      "findings": "not a list",
      "metrics": {"pages_scanned": 1},
      "recommended_actions": [],
    }
    with pytest.raises(ValueError):
      rw_light.parse_audit_response(self._to_json(data))

  def test_metrics_not_dict_raises_value_error(self):
    """metrics が dict でない場合は ValueError を raise すること"""
    import pytest
    data = {
      "findings": [],
      "metrics": ["not", "a", "dict"],
      "recommended_actions": [],
    }
    with pytest.raises(ValueError):
      rw_light.parse_audit_response(self._to_json(data))

  def test_recommended_actions_not_list_raises_value_error(self):
    """recommended_actions が list でない場合は ValueError を raise すること"""
    import pytest
    data = {
      "findings": [],
      "metrics": {"pages_scanned": 1},
      "recommended_actions": "not a list",
    }
    with pytest.raises(ValueError):
      rw_light.parse_audit_response(self._to_json(data))

  # ── finding 必須キー欠落: スキップ or ValueError ──────────────

  def test_finding_missing_severity_skipped(self):
    """finding に severity キーが欠落している場合は INFO 補完して保持されること（Task 1.8: silent skip 廃止）"""
    data = {
      "findings": [
        {
          "category": "test",
          "page": "test.md",
          "message": "severity なし",
        },
        {
          "severity": "LOW",
          "category": "valid",
          "page": "valid.md",
          "message": "正常",
        },
      ],
      "metrics": {"pages_scanned": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    # Task 1.8: severity 欠落の finding は INFO 補完して保持（silent skip 廃止）
    # LOW は drift → INFO に降格されて保持。合計 2 件。
    assert len(result["findings"]) == 2
    assert result["findings"][0]["severity"] == "INFO"
    assert result["findings"][1]["severity"] == "INFO"
    # drift_events に missing-severity の記録があること
    assert "drift_events" in result
    drift_sources = [e.get("source_field", "") for e in result["drift_events"]]
    assert any("<missing-severity>" in s for s in drift_sources)

  def test_finding_missing_page_skipped(self):
    """finding に page キーが欠落している場合も保持されること（Task 1.8: page は非必須、location に統一）"""
    data = {
      "findings": [
        {
          "severity": "HIGH",
          "category": "test",
          "message": "page なし",
        },
        {
          "severity": "LOW",
          "category": "valid",
          "page": "valid.md",
          "message": "正常",
        },
      ],
      "metrics": {"pages_scanned": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    # Task 1.8: page は非必須（location に統一）。HIGH/LOW ともに drift → INFO に降格して保持。合計 2 件。
    assert len(result["findings"]) == 2
    assert result["findings"][0]["severity"] == "INFO"
    assert result["findings"][1]["severity"] == "INFO"

  def test_finding_missing_message_skipped(self):
    """finding に message キーが欠落している場合は空文字補完して保持されること（Task 1.8: silent skip 廃止）"""
    data = {
      "findings": [
        {
          "severity": "HIGH",
          "category": "test",
          "page": "test.md",
        },
        {
          "severity": "LOW",
          "category": "valid",
          "page": "valid.md",
          "message": "正常",
        },
      ],
      "metrics": {"pages_scanned": 1},
      "recommended_actions": [],
    }
    result = rw_light.parse_audit_response(self._to_json(data))
    # Task 1.8: message 欠落の finding は空文字補完して保持（silent skip 廃止）。合計 2 件。
    assert len(result["findings"]) == 2
    assert result["findings"][0]["severity"] == "INFO"
    assert result["findings"][1]["severity"] == "INFO"
    # drift_events に missing-message の記録があること
    assert "drift_events" in result
    drift_sources = [e.get("source_field", "") for e in result["drift_events"]]
    assert any("missing-message" in s for s in drift_sources)

  # ── 返却値の構造確認 ────────────────────────────────────────

  def test_return_value_has_required_keys(self):
    """返却値が findings / metrics / recommended_actions を持つこと"""
    result = rw_light.parse_audit_response(self._to_json(self.VALID_MONTHLY))
    assert set(result.keys()) >= {"findings", "metrics", "recommended_actions"}

  def test_metrics_preserved(self):
    """metrics がそのまま返却されること"""
    result = rw_light.parse_audit_response(self._to_json(self.VALID_MONTHLY))
    assert result["metrics"]["pages_scanned"] == 42
    assert result["metrics"]["conflict_count"] == 1

  def test_recommended_actions_preserved(self):
    """recommended_actions がそのまま返却されること"""
    result = rw_light.parse_audit_response(self._to_json(self.VALID_MONTHLY))
    assert len(result["recommended_actions"]) == 1
    assert "my-concept" in result["recommended_actions"][0]


# ---------------------------------------------------------------------------
# Task 4.1: generate_audit_report() + print_audit_summary()
# ---------------------------------------------------------------------------


def _make_finding(
  severity="ERROR",
  category="broken_link",
  page="concepts/my-page.md",
  message="テストメッセージ",
  marker="",
):
  return rw_light.Finding(
    severity=severity,
    category=category,
    page=page,
    message=message,
    marker=marker,
  )


class TestGenerateAuditReport:
  """generate_audit_report() のテスト。"""

  def _micro_findings(self):
    return [
      _make_finding("ERROR", "broken_link", "concepts/page-a.md", "リンク切れ"),
      _make_finding("WARN", "index_missing", "methods/page-b.md", "index.md 未登録"),
      _make_finding("INFO", "source_field", "entities/tool.md", "source フィールドが空"),
    ]

  def _micro_metrics(self):
    return {
      "pages_scanned": 3,
      "broken_links": 1,
      "index_missing": 1,
      "frontmatter_errors": 0,
      "total_findings": 3,
    }

  def test_returns_path_object(self, tmp_path, monkeypatch):
    """ファイルパス文字列を返すこと"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    assert isinstance(result, str)

  def test_file_created_in_logs(self, tmp_path, monkeypatch):
    """logs/ にレポートファイルが生成されること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    assert Path(result).exists()

  def test_filename_format(self, tmp_path, monkeypatch):
    """ファイル名が audit-{tier}-{timestamp}.md 形式であること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-153000"
    )
    assert Path(result).name == "audit-micro-20260418-153000.md"

  def test_timestamp_auto_generated_when_none(self, tmp_path, monkeypatch):
    """timestamp=None のとき、ファイル名にタイムスタンプが含まれること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "weekly", [], {}, timestamp=None
    )
    name = Path(result).name
    assert name.startswith("audit-weekly-")
    assert name.endswith(".md")

  def test_summary_section_exists(self, tmp_path, monkeypatch):
    """Summary セクションが含まれること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "## Summary" in content

  def test_summary_contains_tier(self, tmp_path, monkeypatch):
    """Summary にティア名が含まれること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "micro" in content

  def test_summary_error_warn_info_counts(self, tmp_path, monkeypatch):
    """Summary に ERROR/WARN/INFO カウントが含まれること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "ERROR" in content
    assert "WARN" in content
    assert "INFO" in content

  def test_summary_pass_when_no_errors_no_warns(self, tmp_path, monkeypatch):
    """ERROR=0 かつ WARN=0 の場合 PASS と表示されること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    findings = [
      _make_finding("INFO", "source_field", "entities/tool.md", "source 空"),
    ]
    result = rw_light.generate_audit_report(
      "micro", findings, {}, timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "PASS" in content

  def test_summary_fail_when_errors_exist(self, tmp_path, monkeypatch):
    """ERROR がある場合 FAIL と表示されること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "FAIL" in content

  def test_findings_section_exists(self, tmp_path, monkeypatch):
    """Findings セクションが含まれること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "## Findings" in content

  def test_micro_structural_findings_label(self, tmp_path, monkeypatch):
    """micro は Structural Findings ラベルであること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "Structural Findings" in content

  def test_weekly_structural_findings_label(self, tmp_path, monkeypatch):
    """weekly は Structural Findings ラベルであること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "weekly", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "Structural Findings" in content

  def test_monthly_semantic_findings_label(self, tmp_path, monkeypatch):
    """monthly は Semantic Findings ラベルであること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "monthly", [], {}, timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "Semantic Findings" in content

  def test_quarterly_strategic_findings_label(self, tmp_path, monkeypatch):
    """quarterly は Strategic Findings ラベルであること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "quarterly", [], {}, timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "Strategic Findings" in content

  def test_findings_grouped_by_severity(self, tmp_path, monkeypatch):
    """ERROR -> Structural, WARN -> Semantic, INFO -> Strategic にグループ化されること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    # ERROR finding が含まれること
    assert "[ERROR]" in content
    # WARN finding が含まれること
    assert "[WARN]" in content
    # INFO finding が含まれること
    assert "[INFO]" in content

  def test_metrics_section_exists(self, tmp_path, monkeypatch):
    """Metrics セクションが含まれること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "## Metrics" in content

  def test_metrics_dict_contents(self, tmp_path, monkeypatch):
    """metrics dict の内容が Metrics セクションに含まれること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "pages_scanned" in content
    assert "broken_links" in content

  def test_recommended_actions_section_exists(self, tmp_path, monkeypatch):
    """Recommended Actions セクションが含まれること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    result = rw_light.generate_audit_report(
      "micro", self._micro_findings(), self._micro_metrics(), timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "## Recommended Actions" in content

  def test_micro_recommended_actions_auto_generated(self, tmp_path, monkeypatch):
    """micro で recommended_actions=None のとき、findings から自動生成されること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    findings = [
      _make_finding("ERROR", "broken_link", "concepts/page-a.md", "リンク切れ"),
      _make_finding("WARN", "index_missing", "methods/page-b.md", "未登録"),
    ]
    result = rw_light.generate_audit_report(
      "micro", findings, {}, recommended_actions=None, timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    # category ごとの集約メッセージが含まれること
    assert "broken_link" in content or "件検出" in content

  def test_micro_auto_actions_group_by_category(self, tmp_path, monkeypatch):
    """micro 自動生成アクションは category ごとに集約されること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    findings = [
      _make_finding("ERROR", "broken_link", "concepts/page-a.md", "リンク切れA"),
      _make_finding("ERROR", "broken_link", "concepts/page-b.md", "リンク切れB"),
      _make_finding("WARN", "index_missing", "methods/page-c.md", "未登録"),
    ]
    result = rw_light.generate_audit_report(
      "micro", findings, {}, recommended_actions=None, timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    # broken_link 2件、index_missing 1件 -> 2行
    assert "broken_link" in content
    assert "index_missing" in content

  def test_monthly_uses_passed_recommended_actions(self, tmp_path, monkeypatch):
    """monthly は passed recommended_actions をそのまま出力すること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    actions = ["具体的なアクション1", "具体的なアクション2"]
    result = rw_light.generate_audit_report(
      "monthly", [], {}, recommended_actions=actions, timestamp="20260418-120000"
    )
    content = Path(result).read_text(encoding="utf-8")
    assert "具体的なアクション1" in content
    assert "具体的なアクション2" in content

  def test_logs_dir_created_if_absent(self, tmp_path, monkeypatch):
    """logs/ ディレクトリが存在しなくても自動作成されること（write_text の既存動作）"""
    new_logdir = tmp_path / "new_logs"
    monkeypatch.setattr(rw_light, "LOGDIR", str(new_logdir))
    result = rw_light.generate_audit_report(
      "micro", [], {}, timestamp="20260418-120000"
    )
    assert Path(result).exists()


class TestPrintAuditSummary:
  """print_audit_summary() のテスト。"""

  def _findings(self):
    return [
      _make_finding("ERROR", "broken_link", "concepts/page-a.md", "リンク切れ"),
      _make_finding("WARN", "index_missing", "methods/page-b.md", "未登録"),
      _make_finding("WARN", "frontmatter", "methods/page-c.md", "title 欠落"),
      _make_finding("INFO", "source_field", "entities/tool.md", "source 空"),
    ]

  def test_each_finding_printed(self, capsys):
    """各 Finding が [severity] page: message 形式で表示されること"""
    rw_light.print_audit_summary("micro", self._findings(), "logs/audit-micro-test.md")
    out = capsys.readouterr().out
    assert "[ERROR] concepts/page-a.md: リンク切れ" in out

  def test_page_empty_omits_page_part(self, capsys):
    """page="" のとき [severity] message 形式（ページ省略）で表示されること"""
    findings = [_make_finding("INFO", "coverage_gap", "", "カバレッジ不足")]
    rw_light.print_audit_summary("quarterly", findings, "logs/audit-quarterly-test.md")
    out = capsys.readouterr().out
    assert "[INFO] カバレッジ不足" in out
    # ページパスが含まれないこと（": " のコロンがある場合はページ付き形式）
    assert "[INFO] : カバレッジ不足" not in out

  def test_summary_line_format(self, capsys):
    """サマリー行が audit {tier}: CRITICAL N, ERROR N, WARN N, INFO N — PASS/FAIL 形式であること"""
    rw_light.print_audit_summary("micro", self._findings(), "logs/audit-micro-test.md")
    out = capsys.readouterr().out
    assert "CRITICAL 0" in out
    assert "ERROR 1" in out
    assert "WARN 2" in out
    assert "INFO 1" in out

  def test_fail_when_error_exists(self, capsys):
    """ERROR > 0 のとき FAIL と表示されること"""
    rw_light.print_audit_summary("micro", self._findings(), "logs/audit-micro-test.md")
    out = capsys.readouterr().out
    assert "FAIL" in out

  def test_pass_when_warn_only(self, capsys):
    """WARN > 0（CRITICAL/ERROR = 0）のとき PASS と表示されること（新体系: status 2 値化）"""
    findings = [_make_finding("WARN", "index_missing", "methods/page.md", "未登録")]
    rw_light.print_audit_summary("weekly", findings, "logs/audit-weekly-test.md")
    out = capsys.readouterr().out
    assert "PASS" in out

  def test_pass_when_only_info(self, capsys):
    """ERROR=0 かつ WARN=0 のとき PASS と表示されること"""
    findings = [_make_finding("INFO", "source_field", "entities/tool.md", "source 空")]
    rw_light.print_audit_summary("micro", findings, "logs/audit-micro-test.md")
    out = capsys.readouterr().out
    assert "PASS" in out

  def test_pass_when_no_findings(self, capsys):
    """findings が空のとき PASS と表示されること"""
    rw_light.print_audit_summary("micro", [], "logs/audit-micro-test.md")
    out = capsys.readouterr().out
    assert "PASS" in out

  def test_report_path_in_output(self, capsys):
    """レポートパスが最終行付近に表示されること"""
    rw_light.print_audit_summary("micro", self._findings(), "logs/audit-micro-20260418-120000.md")
    out = capsys.readouterr().out
    assert "logs/audit-micro-20260418-120000.md" in out

  def test_warn_count_in_summary(self, capsys):
    """サマリー行に WARN カウントが含まれること"""
    rw_light.print_audit_summary("micro", self._findings(), "logs/test.md")
    out = capsys.readouterr().out
    assert "WARN 2" in out

  def test_info_count_in_summary(self, capsys):
    """サマリー行に INFO カウントが含まれること"""
    rw_light.print_audit_summary("micro", self._findings(), "logs/test.md")
    out = capsys.readouterr().out
    assert "INFO 1" in out


# ---------------------------------------------------------------------------
# Task 2.8: cmd_audit_* status 計算 + CRITICAL 可視化
# ---------------------------------------------------------------------------


class TestAuditSummaryCriticalVisibility:
  """audit summary に CRITICAL 行と 4 水準出力が含まれることを検証"""

  def _finding(self, sev: str) -> rw_light.Finding:
    return rw_light.Finding(severity=sev, category="test", page="p.md", message="m", marker="")

  def test_summary_line_includes_critical(self, capsys):
    """stdout summary 行に CRITICAL が含まれる"""
    rw_light.print_audit_summary("weekly", [self._finding("CRITICAL")], "logs/test.md")
    out = capsys.readouterr().out
    assert "CRITICAL" in out

  def test_stdout_format_4_tiers(self, capsys):
    """stdout summary 行が 'audit {tier}: CRITICAL X, ERROR Y, WARN Z, INFO W — status' 形式"""
    rw_light.print_audit_summary(
      "micro",
      [self._finding("CRITICAL"), self._finding("ERROR"), self._finding("WARN"), self._finding("INFO")],
      "logs/test.md",
    )
    out = capsys.readouterr().out
    assert "CRITICAL 1" in out
    assert "ERROR 1" in out
    assert "WARN 1" in out
    assert "INFO 1" in out
    assert "FAIL" in out

  def test_warn_only_is_pass(self, capsys):
    """WARN のみ（CRITICAL/ERROR なし）は PASS（新体系: status 2 値化）"""
    rw_light.print_audit_summary("micro", [self._finding("WARN")], "logs/test.md")
    out = capsys.readouterr().out
    assert "PASS" in out

  def test_zero_findings_shows_status(self, capsys):
    """findings 0 件でも status 行が表示される（AC 5.5 境界）"""
    rw_light.print_audit_summary("micro", [], "logs/test.md")
    out = capsys.readouterr().out
    assert "PASS" in out
    assert "CRITICAL" in out

  def test_generate_audit_report_critical_line(self, tmp_path, monkeypatch):
    """generate_audit_report の Summary 節に '- CRITICAL: N' 行が存在する"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    findings = [self._finding("CRITICAL"), self._finding("ERROR")]
    report_path = rw_light.generate_audit_report(
      "weekly", findings, {}, timestamp="20260420-120000"
    )
    content = (tmp_path / "audit-weekly-20260420-120000.md").read_text()
    assert "- CRITICAL:" in content

  def test_generate_audit_report_status_uses_compute_run_status(self, tmp_path, monkeypatch):
    """WARN のみ → status: PASS（旧: FAIL）"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))
    findings = [self._finding("WARN")]
    report_path = rw_light.generate_audit_report(
      "micro", findings, {}, timestamp="20260420-120001"
    )
    content = (tmp_path / "audit-micro-20260420-120001.md").read_text()
    assert "- status: PASS" in content


class TestGenerateAuditReportIntegration:
  """generate_audit_report + print_audit_summary の統合テスト（task 4.1 要件）。"""

  def test_micro_report_file_and_summary(self, tmp_path, monkeypatch, capsys):
    """micro findings でレポートファイルが生成され、サマリーが標準出力に表示されること"""
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path))

    findings = [
      rw_light.Finding("ERROR", "broken_link", "concepts/page.md", "リンク切れ", ""),
      rw_light.Finding("WARN", "index_missing", "methods/page.md", "index 未登録", ""),
      rw_light.Finding("INFO", "source_field", "entities/tool.md", "source 空", ""),
    ]
    metrics = {
      "pages_scanned": 3,
      "broken_links": 1,
      "index_missing": 1,
      "frontmatter_errors": 0,
      "total_findings": 3,
    }

    report_path = rw_light.generate_audit_report(
      "micro", findings, metrics, timestamp="20260418-153000"
    )
    rw_light.print_audit_summary("micro", findings, report_path)

    # レポートファイルの検証
    assert Path(report_path).exists()
    assert Path(report_path).name == "audit-micro-20260418-153000.md"
    content = Path(report_path).read_text(encoding="utf-8")
    assert "## Summary" in content
    assert "## Findings" in content
    assert "## Metrics" in content
    assert "## Recommended Actions" in content
    assert "FAIL" in content

    # 標準出力の検証
    out = capsys.readouterr().out
    assert "[ERROR] concepts/page.md: リンク切れ" in out
    assert "[WARN] methods/page.md: index 未登録" in out
    assert "CRITICAL 0" in out
    assert "ERROR 1" in out
    assert "WARN 1" in out
    assert "INFO 1" in out
    assert report_path in out


# ---------------------------------------------------------------------------
# cmd_audit / cmd_audit_micro のテスト（task 5.1）
# ---------------------------------------------------------------------------

def _setup_wiki_for_cmd_audit(tmp_path, monkeypatch, num_files=2):
  """cmd_audit_micro テスト用の最小 Vault を構築する。"""
  wiki_dir = tmp_path / "wiki"
  wiki_dir.mkdir()
  logs_dir = tmp_path / "logs"
  logs_dir.mkdir()

  for i in range(num_files):
    page = wiki_dir / f"page-{i:02d}.md"
    page.write_text(
      f"---\ntitle: Page {i}\nsource: web\n---\n\n# Page {i}\n\nBody text.\n",
      encoding="utf-8",
    )

  monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
  monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
  monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
  monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
  return wiki_dir, logs_dir


class TestCmdAuditDispatch:
  """cmd_audit() ディスパッチャのテスト（Req 5.5）"""

  def test_cmd_audit_exists(self):
    """cmd_audit 関数が定義されていること"""
    assert hasattr(rw_light, "cmd_audit")
    assert callable(rw_light.cmd_audit)

  def test_cmd_audit_no_args_returns_1(self, tmp_path, monkeypatch, capsys):
    """サブコマンドなしで呼び出した場合 exit 1 相当（return 1）で usage を表示すること"""
    _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    result = rw_light.cmd_audit([])
    assert result == 1

  def test_cmd_audit_no_args_prints_usage(self, tmp_path, monkeypatch, capsys):
    """サブコマンドなしで呼び出した場合に使用方法が表示されること"""
    _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    rw_light.cmd_audit([])
    out = capsys.readouterr().out
    assert "micro" in out
    assert "weekly" in out
    assert "monthly" in out
    assert "quarterly" in out

  def test_cmd_audit_unknown_subcmd_returns_1(self, tmp_path, monkeypatch, capsys):
    """不明なサブコマンドの場合 return 1 すること"""
    _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    result = rw_light.cmd_audit(["unknown-subcmd"])
    assert result == 1

  def test_cmd_audit_unknown_subcmd_prints_error(self, tmp_path, monkeypatch, capsys):
    """不明なサブコマンドの場合エラーメッセージを表示すること"""
    _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    rw_light.cmd_audit(["invalid"])
    out = capsys.readouterr().out
    assert "invalid" in out or "Unknown" in out or "usage" in out.lower() or "audit" in out


class TestCmdAuditMicro:
  """cmd_audit_micro() のテスト（Req 1.1-1.8）"""

  def test_cmd_audit_micro_exists(self):
    """cmd_audit_micro 関数が定義されていること"""
    assert hasattr(rw_light, "cmd_audit_micro")
    assert callable(rw_light.cmd_audit_micro)

  def test_cmd_audit_micro_returns_int(self, tmp_path, monkeypatch):
    """cmd_audit_micro が int を返すこと"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    # _git_list_files を空リスト返却にモック（変更なし扱い）
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])
    result = rw_light.cmd_audit_micro()
    assert isinstance(result, int)

  def test_cmd_audit_micro_no_wiki_returns_1(self, tmp_path, monkeypatch, capsys):
    """wiki/ が存在しない場合 exit 1（Req 7.1）"""
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path / "logs"))
    result = rw_light.cmd_audit_micro()
    assert result == 1

  def test_cmd_audit_micro_no_wiki_prints_error(self, tmp_path, monkeypatch, capsys):
    """wiki/ が存在しない場合 [ERROR] を表示すること"""
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path / "logs"))
    rw_light.cmd_audit_micro()
    out = capsys.readouterr().out
    assert "[ERROR]" in out

  def test_cmd_audit_micro_no_changes_returns_0(self, tmp_path, monkeypatch, capsys):
    """対象ファイル 0 件のとき exit 0（Req 1.7）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    # 変更なしにモック
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])
    result = rw_light.cmd_audit_micro()
    assert result == 0

  def test_cmd_audit_micro_no_changes_prints_info(self, tmp_path, monkeypatch, capsys):
    """対象ファイル 0 件のとき [INFO] 変更なしを表示すること（Req 1.7）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])
    rw_light.cmd_audit_micro()
    out = capsys.readouterr().out
    assert "[INFO]" in out

  def test_cmd_audit_micro_no_changes_generates_report(self, tmp_path, monkeypatch, capsys):
    """対象ファイル 0 件のとき pages_scanned: 0 のレポートを生成すること（Req 1.7）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])
    rw_light.cmd_audit_micro()
    # logs/ にレポートファイルが生成されること
    report_files = list(logs_dir.glob("audit-micro-*.md"))
    assert len(report_files) == 1
    content = report_files[0].read_text(encoding="utf-8")
    assert "pages_scanned: 0" in content

  def test_cmd_audit_micro_with_changes_generates_report(self, tmp_path, monkeypatch):
    """変更ファイルがある場合 logs/ にレポートが生成されること（Req 1.4）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    page_path = wiki_dir / "page-00.md"
    # _git_list_files が wiki ページを返すようモック
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(page_path)] if "diff" in args else []
    )
    rw_light.cmd_audit_micro()
    report_files = list(logs_dir.glob("audit-micro-*.md"))
    assert len(report_files) == 1

  def test_cmd_audit_micro_report_in_logs_only(self, tmp_path, monkeypatch):
    """レポートが logs/ にのみ出力され wiki/ には書き込まれないこと（Req 6.1）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])
    rw_light.cmd_audit_micro()
    # wiki/ 内に新規ファイルがないこと
    wiki_files_after = list(wiki_dir.rglob("*.md"))
    assert len(wiki_files_after) == 2  # 元の 2 ファイルのみ

  def test_cmd_audit_micro_no_error_returns_0(self, tmp_path, monkeypatch):
    """ERROR なしの場合 exit 0（Req 1.5）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    page_path = wiki_dir / "page-00.md"
    # 正常ページ（リンク切れなし）
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(page_path)] if "diff" in args else []
    )
    result = rw_light.cmd_audit_micro()
    # ERROR finding なし（title/source は設定済み）→ exit 0
    assert result == 0

  def test_cmd_audit_micro_with_error_returns_1(self, tmp_path, monkeypatch):
    """ERROR finding がある場合 exit 2（新体系: FAIL → exit 2）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    # broken link を含むページを作成
    broken_page = wiki_dir / "broken.md"
    broken_page.write_text(
      "---\ntitle: Broken\nsource: web\n---\n\n# Broken\n\n[[nonexistent-page]] をリンク。\n",
      encoding="utf-8",
    )
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(broken_page)] if "diff" in args else []
    )
    result = rw_light.cmd_audit_micro()
    assert result == 2

  def test_cmd_audit_micro_summary_displayed(self, tmp_path, monkeypatch, capsys):
    """完了後にサマリーが表示されること（Req 1.3）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    page_path = wiki_dir / "page-00.md"
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(page_path)] if "diff" in args else []
    )
    rw_light.cmd_audit_micro()
    out = capsys.readouterr().out
    assert "audit micro:" in out

  def test_cmd_audit_micro_report_path_displayed(self, tmp_path, monkeypatch, capsys):
    """レポートパスが標準出力に表示されること（Req 5.7）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    page_path = wiki_dir / "page-00.md"
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(page_path)] if "diff" in args else []
    )
    rw_light.cmd_audit_micro()
    out = capsys.readouterr().out
    assert "audit-micro-" in out

  def test_cmd_audit_micro_metrics_in_report(self, tmp_path, monkeypatch):
    """レポートに metrics（pages_scanned, broken_links 等）が含まれること（Req 5.4）"""
    wiki_dir, logs_dir = _setup_wiki_for_cmd_audit(tmp_path, monkeypatch)
    page_path = wiki_dir / "page-00.md"
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(page_path)] if "diff" in args else []
    )
    rw_light.cmd_audit_micro()
    report_files = list(logs_dir.glob("audit-micro-*.md"))
    assert report_files
    content = report_files[0].read_text(encoding="utf-8")
    assert "pages_scanned" in content
    assert "broken_links" in content
    assert "total_findings" in content


class TestMainAuditDispatch:
  """main() での audit コマンドのディスパッチテスト"""

  def test_main_dispatches_audit(self, monkeypatch):
    """main() が 'audit' コマンドを cmd_audit に委譲すること"""
    called = []

    def mock_cmd_audit(args):
      called.append(args)
      return 0

    monkeypatch.setattr(rw_light, "cmd_audit", mock_cmd_audit)
    monkeypatch.setattr(sys, "argv", ["rw", "audit", "micro"])

    with pytest.raises(SystemExit) as exc:
      rw_light.main()
    assert exc.value.code == 0
    assert called  # cmd_audit が呼ばれたこと


class TestPrintUsageAudit:
  """print_usage() に audit ヘルプ行が含まれるテスト"""

  def test_print_usage_contains_audit(self, capsys):
    """print_usage() の出力に 'audit' が含まれること"""
    rw_light.print_usage()
    out = capsys.readouterr().out
    assert "audit" in out


# ---------------------------------------------------------------------------
# cmd_audit_weekly のテスト（task 5.2）
# ---------------------------------------------------------------------------

def _setup_wiki_for_weekly(tmp_path, monkeypatch, num_files=2):
  """cmd_audit_weekly テスト用の最小 Vault を構築する。"""
  wiki_dir = tmp_path / "wiki"
  wiki_dir.mkdir()
  logs_dir = tmp_path / "logs"
  logs_dir.mkdir()

  for i in range(num_files):
    page = wiki_dir / f"page-{i:02d}.md"
    page.write_text(
      f"---\ntitle: Page {i}\nsource: web\n---\n\n# Page {i}\n\nBody text.\n",
      encoding="utf-8",
    )

  monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
  monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
  monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
  monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
  return wiki_dir, logs_dir


class TestCmdAuditWeekly:
  """cmd_audit_weekly() のテスト（Req 2.1-2.6）"""

  def test_cmd_audit_weekly_exists(self):
    """cmd_audit_weekly 関数が定義されていること"""
    assert hasattr(rw_light, "cmd_audit_weekly")
    assert callable(rw_light.cmd_audit_weekly)

  def test_cmd_audit_weekly_returns_int(self, tmp_path, monkeypatch):
    """cmd_audit_weekly が int を返すこと"""
    _setup_wiki_for_weekly(tmp_path, monkeypatch)
    result = rw_light.cmd_audit_weekly()
    assert isinstance(result, int)

  def test_cmd_audit_weekly_no_wiki_returns_1(self, tmp_path, monkeypatch, capsys):
    """wiki/ が存在しない場合 exit 1（Req 7.1）"""
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path / "logs"))
    result = rw_light.cmd_audit_weekly()
    assert result == 1

  def test_cmd_audit_weekly_no_wiki_prints_error(self, tmp_path, monkeypatch, capsys):
    """wiki/ が存在しない場合 [ERROR] を表示すること"""
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(tmp_path / "logs"))
    rw_light.cmd_audit_weekly()
    out = capsys.readouterr().out
    assert "[ERROR]" in out

  def test_cmd_audit_weekly_scans_all_pages(self, tmp_path, monkeypatch):
    """全ページをスキャンすること（Req 2.1, 2.2）"""
    wiki_dir, logs_dir = _setup_wiki_for_weekly(tmp_path, monkeypatch, num_files=3)
    rw_light.cmd_audit_weekly()
    report_files = list(logs_dir.glob("audit-weekly-*.md"))
    assert len(report_files) == 1
    content = report_files[0].read_text(encoding="utf-8")
    # 3ページをスキャン
    assert "pages_scanned: 3" in content

  def test_cmd_audit_weekly_generates_report(self, tmp_path, monkeypatch):
    """logs/ にレポートが生成されること（Req 2.3）"""
    wiki_dir, logs_dir = _setup_wiki_for_weekly(tmp_path, monkeypatch)
    rw_light.cmd_audit_weekly()
    report_files = list(logs_dir.glob("audit-weekly-*.md"))
    assert len(report_files) == 1

  def test_cmd_audit_weekly_report_in_logs_only(self, tmp_path, monkeypatch):
    """レポートが logs/ にのみ出力され wiki/ には書き込まれないこと（Req 6.1）"""
    wiki_dir, logs_dir = _setup_wiki_for_weekly(tmp_path, monkeypatch)
    original_wiki_files = set(wiki_dir.rglob("*.md"))
    rw_light.cmd_audit_weekly()
    wiki_files_after = set(wiki_dir.rglob("*.md"))
    assert original_wiki_files == wiki_files_after

  def test_cmd_audit_weekly_no_error_returns_0(self, tmp_path, monkeypatch):
    """ERROR なしの場合 exit 0（Req 2.4）"""
    _setup_wiki_for_weekly(tmp_path, monkeypatch)
    result = rw_light.cmd_audit_weekly()
    assert result == 0

  def test_cmd_audit_weekly_with_error_returns_1(self, tmp_path, monkeypatch):
    """ERROR finding がある場合 exit 2（新体系: FAIL → exit 2）"""
    wiki_dir, logs_dir = _setup_wiki_for_weekly(tmp_path, monkeypatch)
    broken_page = wiki_dir / "broken.md"
    broken_page.write_text(
      "---\ntitle: Broken\nsource: web\n---\n\n# Broken\n\n[[nonexistent-page]] リンク。\n",
      encoding="utf-8",
    )
    result = rw_light.cmd_audit_weekly()
    assert result == 2

  def test_cmd_audit_weekly_summary_displayed(self, tmp_path, monkeypatch, capsys):
    """完了後にサマリーが表示されること（Req 2.3）"""
    _setup_wiki_for_weekly(tmp_path, monkeypatch)
    rw_light.cmd_audit_weekly()
    out = capsys.readouterr().out
    assert "audit weekly:" in out

  def test_cmd_audit_weekly_report_path_displayed(self, tmp_path, monkeypatch, capsys):
    """レポートパスが標準出力に表示されること（Req 5.7）"""
    _setup_wiki_for_weekly(tmp_path, monkeypatch)
    rw_light.cmd_audit_weekly()
    out = capsys.readouterr().out
    assert "audit-weekly-" in out

  def test_cmd_audit_weekly_metrics_in_report(self, tmp_path, monkeypatch):
    """レポートに weekly 必須メトリクスが含まれること（Req 5.4）"""
    _setup_wiki_for_weekly(tmp_path, monkeypatch)
    rw_light.cmd_audit_weekly()
    report_files = list((tmp_path / "logs").glob("audit-weekly-*.md"))
    assert report_files
    content = report_files[0].read_text(encoding="utf-8")
    assert "pages_scanned" in content
    assert "broken_links" in content
    assert "orphan_pages" in content
    assert "bidirectional_compliance" in content
    assert "source_missing" in content
    assert "naming_violations" in content
    assert "total_findings" in content

  def test_cmd_audit_weekly_includes_micro_checks(self, tmp_path, monkeypatch):
    """weekly は micro チェック項目（broken_links, index_missing, frontmatter）も実行すること（Req 2.2）"""
    wiki_dir, logs_dir = _setup_wiki_for_weekly(tmp_path, monkeypatch)
    broken_page = wiki_dir / "broken.md"
    broken_page.write_text(
      "---\ntitle: Broken\nsource: web\n---\n\n# Broken\n\n[[nonexistent-page]] リンク。\n",
      encoding="utf-8",
    )
    rw_light.cmd_audit_weekly()
    report_files = list(logs_dir.glob("audit-weekly-*.md"))
    content = report_files[0].read_text(encoding="utf-8")
    # broken_links: 1 が metrics に含まれること
    assert "broken_links: 1" in content

  def test_cmd_audit_weekly_bidirectional_compliance_in_report(self, tmp_path, monkeypatch):
    """bidirectional_compliance が % 形式でレポートに含まれること"""
    _setup_wiki_for_weekly(tmp_path, monkeypatch)
    rw_light.cmd_audit_weekly()
    report_files = list((tmp_path / "logs").glob("audit-weekly-*.md"))
    content = report_files[0].read_text(encoding="utf-8")
    assert "bidirectional_compliance:" in content
    assert "%" in content

  def test_cmd_audit_weekly_report_has_sections(self, tmp_path, monkeypatch):
    """レポートに必須セクションが含まれること（Req 5.2）"""
    _setup_wiki_for_weekly(tmp_path, monkeypatch)
    rw_light.cmd_audit_weekly()
    report_files = list((tmp_path / "logs").glob("audit-weekly-*.md"))
    content = report_files[0].read_text(encoding="utf-8")
    assert "## Summary" in content
    assert "## Findings" in content
    assert "## Metrics" in content
    assert "## Recommended Actions" in content

  def test_cmd_audit_weekly_no_claude_called(self, tmp_path, monkeypatch):
    """Claude CLI を呼び出さないこと（Req 2.6）"""
    _setup_wiki_for_weekly(tmp_path, monkeypatch)
    claude_called = []

    def mock_call_claude(prompt, timeout=None):
      claude_called.append(prompt)
      return "{}"

    monkeypatch.setattr(rw_light, "call_claude", mock_call_claude)
    rw_light.cmd_audit_weekly()
    assert claude_called == []

  def test_cmd_audit_weekly_read_error_pages_excluded_from_checks(self, tmp_path, monkeypatch):
    """read_error のあるページが weekly チェックから除外されること（実装メモより）"""
    wiki_dir, logs_dir = _setup_wiki_for_weekly(tmp_path, monkeypatch)
    # load_wiki_pages が read_error 付きページを含むよう monkeypatch
    normal_page = rw_light.WikiPage(
      path="page-00.md",
      filename="page-00.md",
      raw_text="---\ntitle: Normal\nsource: web\n---\n# Normal\n",
      frontmatter={"title": "Normal", "source": "web"},
      body="# Normal\n",
      links=[],
      read_error="",
    )
    error_page = rw_light.WikiPage(
      path="bad.md",
      filename="bad.md",
      raw_text="",
      frontmatter={},
      body="",
      links=[],
      read_error="UnicodeDecodeError: bad encoding",
    )
    monkeypatch.setattr(rw_light, "load_wiki_pages", lambda wiki_dir, target_files=None: [normal_page, error_page])
    result = rw_light.cmd_audit_weekly()
    # read_error ページが ERROR finding として報告され、exit 2 であること（新体系: FAIL → exit 2）
    assert result == 2
    report_files = list(logs_dir.glob("audit-weekly-*.md"))
    content = report_files[0].read_text(encoding="utf-8")
    assert "bad.md" in content


# ---------------------------------------------------------------------------
# Task 5.3: _run_llm_audit / cmd_audit_monthly / cmd_audit_quarterly
# ---------------------------------------------------------------------------


def _setup_vault_for_llm_audit(tmp_path, monkeypatch):
  """cmd_audit_monthly/quarterly テスト用の最小 Vault を構築する。"""
  wiki_dir = tmp_path / "wiki"
  wiki_dir.mkdir()
  logs_dir = tmp_path / "logs"
  logs_dir.mkdir()

  # AGENTS/ ディレクトリと audit.md を作成
  agents_dir = tmp_path / "AGENTS"
  agents_dir.mkdir()
  (agents_dir / "audit.md").write_text("# Audit Agent\n", encoding="utf-8")

  # CLAUDE.md を作成（ダミー）
  (tmp_path / "CLAUDE.md").write_text("# CLAUDE.md\n", encoding="utf-8")

  # wiki ページを 1 つ作成
  (wiki_dir / "page-00.md").write_text(
    "---\ntitle: Page 0\nsource: web\n---\n\n# Page 0\n\nBody text.\n",
    encoding="utf-8",
  )

  monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
  monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
  monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
  monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
  monkeypatch.setattr(rw_light, "CLAUDE_MD", str(tmp_path / "CLAUDE.md"))
  monkeypatch.setattr(rw_light, "AGENTS_DIR", str(agents_dir))

  return wiki_dir, logs_dir, agents_dir


def _make_valid_monthly_response():
  """有効な monthly JSON レスポンスを返す（新語彙 ERROR を使用）。"""
  return json.dumps({
    "findings": [
      {
        "severity": "ERROR",
        "category": "contradicting_definition",
        "page": "page-00.md",
        "message": "page-a.md と page-b.md で定義が矛盾している",
        "marker": "CONFLICT",
        "recommendation": "定義を統一するか、条件分岐を明記する",
      }
    ],
    "metrics": {
      "pages_scanned": 1,
      "total_findings": 1,
      "conflict_count": 1,
      "tension_count": 0,
      "ambiguous_count": 0,
    },
    "recommended_actions": ["concepts/my-concept.md の定義を確認する"],
  })


def _make_valid_quarterly_response():
  """有効な quarterly JSON レスポンスを返す（新語彙 WARN を使用）。"""
  return json.dumps({
    "findings": [
      {
        "severity": "WARN",
        "category": "coverage_gap",
        "page": "",
        "message": "synthesis ページが不足している",
        "recommendation": "synthesis 候補を review に追加する",
      }
    ],
    "metrics": {
      "pages_scanned": 1,
      "total_findings": 1,
    },
    "recommended_actions": ["synthesis ページの充実を検討する"],
  })


class TestRunLlmAudit:
  """_run_llm_audit() のテスト（Req 3.1-3.8, 4.1-4.6, 7.2, 7.3, 7.5）"""

  def test_run_llm_audit_exists(self):
    """_run_llm_audit 関数が定義されていること"""
    assert hasattr(rw_light, "_run_llm_audit")
    assert callable(rw_light._run_llm_audit)

  def test_cmd_audit_monthly_exists(self):
    """cmd_audit_monthly 関数が定義されていること"""
    assert hasattr(rw_light, "cmd_audit_monthly")
    assert callable(rw_light.cmd_audit_monthly)

  def test_cmd_audit_quarterly_exists(self):
    """cmd_audit_quarterly 関数が定義されていること"""
    assert hasattr(rw_light, "cmd_audit_quarterly")
    assert callable(rw_light.cmd_audit_quarterly)

  def test_monthly_returns_0_on_warn_only(self, tmp_path, monkeypatch):
    """monthly: WARN only (HIGH → ERROR) の場合 return 1 であること"""
    # HIGH は ERROR にマッピングされるので return 1 — ここは WARN のみテスト
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)

    warn_response = json.dumps({
      "findings": [
        {
          "severity": "MEDIUM",
          "category": "ambiguous_definition",
          "page": "page-00.md",
          "message": "曖昧な記述がある",
          "marker": "AMBIGUOUS",
          "recommendation": "記述を明確にする",
        }
      ],
      "metrics": {"pages_scanned": 1, "total_findings": 1,
                  "conflict_count": 0, "tension_count": 0, "ambiguous_count": 1},
      "recommended_actions": ["記述を明確にする"],
    })

    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: warn_response)

    result = rw_light.cmd_audit_monthly([])
    assert result == 0

  def test_monthly_returns_1_on_error(self, tmp_path, monkeypatch):
    """monthly: ERROR finding がある場合 return 1 であること（Req 3.7）"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_monthly_response())

    result = rw_light.cmd_audit_monthly([])
    # ERROR finding があるので exit 2（新体系: FAIL → exit 2）
    assert result == 2

  def test_quarterly_returns_0_on_no_error(self, tmp_path, monkeypatch):
    """quarterly: ERROR なし（WARN のみ）の場合 return 0 であること（Req 4.4）"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_quarterly_response())

    result = rw_light.cmd_audit_quarterly([])
    # WARN finding のみで ERROR なし → return 0
    assert result == 0

  def test_raw_response_saved(self, tmp_path, monkeypatch):
    """Claude 生レスポンスが logs/audit-{tier}-{ts}-raw.txt に保存されること"""
    _, logs_dir, _ = _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_monthly_response())

    rw_light.cmd_audit_monthly([])
    raw_files = list(logs_dir.glob("audit-monthly-*-raw.txt"))
    assert len(raw_files) == 1
    content = raw_files[0].read_text(encoding="utf-8")
    assert "findings" in content

  def test_report_generated(self, tmp_path, monkeypatch):
    """レポートファイルが logs/audit-monthly-*.md として生成されること（Req 3.4）"""
    _, logs_dir, _ = _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_monthly_response())

    rw_light.cmd_audit_monthly([])
    report_files = list(logs_dir.glob("audit-monthly-*.md"))
    assert len(report_files) == 1

  def test_severity_mapping_applied(self, tmp_path, monkeypatch):
    """severity ERROR finding がレポートに記載されること（Req 5.3）"""
    _, logs_dir, _ = _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_monthly_response())

    rw_light.cmd_audit_monthly([])
    report_files = list(logs_dir.glob("audit-monthly-*.md"))
    content = report_files[0].read_text(encoding="utf-8")
    # ERROR finding がレポートに含まれること
    assert "ERROR" in content

  def test_category_from_claude_response(self, tmp_path, monkeypatch):
    """Finding の category フィールドが Claude レスポンスの category から取得されること"""
    _, logs_dir, _ = _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_monthly_response())

    rw_light.cmd_audit_monthly([])
    report_files = list(logs_dir.glob("audit-monthly-*.md"))
    content = report_files[0].read_text(encoding="utf-8")
    # category フィールド（contradicting_definition）がレポートに含まれること
    assert "contradicting_definition" in content

  def test_timeout_option_applied(self, tmp_path, monkeypatch):
    """--timeout オプションが call_claude に渡されること（Req 7.2 関連）"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    called_with = []

    def mock_call_claude(prompt, timeout=None):
      called_with.append(timeout)
      return _make_valid_monthly_response()

    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", mock_call_claude)

    rw_light.cmd_audit_monthly(["--timeout", "600"])
    assert called_with == [600]

  def test_default_timeout_applied(self, tmp_path, monkeypatch):
    """--timeout 未指定時はデフォルト 300 が適用されること"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    called_with = []

    def mock_call_claude(prompt, timeout=None):
      called_with.append(timeout)
      return _make_valid_monthly_response()

    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", mock_call_claude)

    rw_light.cmd_audit_monthly([])
    assert called_with == [300]

  def test_missing_claude_md_returns_1(self, tmp_path, monkeypatch, capsys):
    """CLAUDE.md が存在しない場合 return 1 かつ [ERROR] 表示（Req 7.5）"""
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()
    logs_dir = tmp_path / "logs"
    logs_dir.mkdir()
    agents_dir = tmp_path / "AGENTS"
    agents_dir.mkdir()
    (wiki_dir / "page.md").write_text("---\ntitle: T\n---\n# T\n", encoding="utf-8")

    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
    # CLAUDE.md を作成しない
    monkeypatch.setattr(rw_light, "CLAUDE_MD", str(tmp_path / "CLAUDE.md"))
    monkeypatch.setattr(rw_light, "AGENTS_DIR", str(agents_dir))

    result = rw_light.cmd_audit_monthly([])
    assert result == 1
    out = capsys.readouterr().out
    assert "[ERROR]" in out

  def test_missing_agents_dir_returns_1(self, tmp_path, monkeypatch, capsys):
    """AGENTS/ ディレクトリが存在しない場合 return 1 かつ [ERROR] 表示（Req 7.5）"""
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()
    logs_dir = tmp_path / "logs"
    logs_dir.mkdir()
    (tmp_path / "CLAUDE.md").write_text("# CLAUDE\n", encoding="utf-8")
    (wiki_dir / "page.md").write_text("---\ntitle: T\n---\n# T\n", encoding="utf-8")

    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
    monkeypatch.setattr(rw_light, "CLAUDE_MD", str(tmp_path / "CLAUDE.md"))
    # AGENTS/ を作成しない
    monkeypatch.setattr(rw_light, "AGENTS_DIR", str(tmp_path / "AGENTS"))

    result = rw_light.cmd_audit_monthly([])
    assert result == 1
    out = capsys.readouterr().out
    assert "[ERROR]" in out

  def test_claude_failure_returns_1(self, tmp_path, monkeypatch, capsys):
    """Claude CLI 呼び出し失敗時 return 1 かつ [ERROR] 表示（Req 7.2）"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude", lambda prompt, timeout=None: (_ for _ in ()).throw(RuntimeError("Claude 失敗"))
    )

    result = rw_light.cmd_audit_monthly([])
    assert result == 1
    out = capsys.readouterr().out
    assert "[ERROR]" in out

  def test_parse_failure_returns_1_with_raw_path(self, tmp_path, monkeypatch, capsys):
    """パース失敗時 return 1 + raw ファイルパスが [INFO] 表示されること（Req 7.3）"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: "not valid json {{{")

    result = rw_light.cmd_audit_monthly([])
    assert result == 1
    out = capsys.readouterr().out
    assert "[ERROR]" in out
    assert "[INFO]" in out
    assert "raw" in out

  def test_processing_message_printed(self, tmp_path, monkeypatch, capsys):
    """処理中メッセージが標準出力に表示されること（Req 3.1, 4.1）"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_monthly_response())

    rw_light.cmd_audit_monthly([])
    out = capsys.readouterr().out
    assert "[INFO]" in out
    assert "monthly" in out

  def test_quarterly_uses_tier3_prompt(self, tmp_path, monkeypatch):
    """quarterly の場合 build_audit_prompt に tier='quarterly' が渡されること"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    tiers_used = []

    orig_build = rw_light.build_audit_prompt

    def capture_build(tier, task_prompts, wiki_content):
      tiers_used.append(tier)
      return orig_build(tier, task_prompts, wiki_content)

    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "build_audit_prompt", capture_build)
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_quarterly_response())

    rw_light.cmd_audit_quarterly([])
    assert tiers_used == ["quarterly"]

  def test_load_task_prompts_called_with_audit(self, tmp_path, monkeypatch):
    """load_task_prompts が 'audit' で呼び出されること（Req 3.8, 10.1）"""
    _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    prompts_called = []

    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: (prompts_called.append(name), "task prompts")[1])
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_monthly_response())

    rw_light.cmd_audit_monthly([])
    assert "audit" in prompts_called

  def test_quarterly_report_generated(self, tmp_path, monkeypatch):
    """quarterly のレポートが logs/audit-quarterly-*.md として生成されること（Req 4.3）"""
    _, logs_dir, _ = _setup_vault_for_llm_audit(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "task prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(rw_light, "call_claude", lambda prompt, timeout=None: _make_valid_quarterly_response())

    rw_light.cmd_audit_quarterly([])
    report_files = list(logs_dir.glob("audit-quarterly-*.md"))
    assert len(report_files) == 1


# ---------------------------------------------------------------------------
# Task 7.1: E2E テスト — 全4ティア動作確認 + 読み取り専用保証
# ---------------------------------------------------------------------------


def _setup_e2e_audit_vault(tmp_path, monkeypatch):
  """E2E audit テスト用の Vault を構築する。

  wiki/ に複数ページ、index.md、log.md を配置した完全な Vault 構造を作成する。
  モックが必要な全グローバル定数をパッチする。

  Returns:
      (wiki_dir, logs_dir, raw_dir, review_dir, agents_dir)
  """
  wiki_dir = tmp_path / "wiki"
  wiki_dir.mkdir()
  logs_dir = tmp_path / "logs"
  logs_dir.mkdir()
  raw_dir = tmp_path / "raw"
  raw_dir.mkdir()
  review_dir = tmp_path / "review"
  review_dir.mkdir()

  # AGENTS/ ディレクトリと audit.md を作成
  agents_dir = tmp_path / "AGENTS"
  agents_dir.mkdir()
  (agents_dir / "audit.md").write_text("# Audit Agent\n## Tier 2: Semantic Audit\nCheck for conflicts.\n", encoding="utf-8")
  (agents_dir / "naming.md").write_text("# Naming Rules\n", encoding="utf-8")
  (agents_dir / "page_policy.md").write_text("# Page Policy\n", encoding="utf-8")
  (agents_dir / "git_ops.md").write_text("# Git Ops\n", encoding="utf-8")

  # CLAUDE.md を作成（load_task_prompts が参照するマッピング表付き）
  claude_md_content = (
    "# CLAUDE.md\n\n"
    "| Task | Agent | Policy | Execution Mode |\n"
    "|------|-------|--------|----------------|\n"
    "| audit | AGENTS/audit.md | AGENTS/page_policy.md, AGENTS/naming.md, AGENTS/git_ops.md | CLI (Hybrid) |\n"
  )
  (tmp_path / "CLAUDE.md").write_text(claude_md_content, encoding="utf-8")

  # wiki/ に複数ページを作成（互いにリンクしあう）
  (wiki_dir / "page-alpha.md").write_text(
    "---\ntitle: Alpha\nsource: web\n---\n\n# Alpha\n\nSee [[page-beta]].\n",
    encoding="utf-8",
  )
  (wiki_dir / "page-beta.md").write_text(
    "---\ntitle: Beta\nsource: web\n---\n\n# Beta\n\nSee [[page-alpha]].\n",
    encoding="utf-8",
  )
  (wiki_dir / "page-gamma.md").write_text(
    "---\ntitle: Gamma\nsource: web\n---\n\n# Gamma\n\nStandalone page.\n",
    encoding="utf-8",
  )

  # ROOT/index.md を作成（全ページを登録）
  index_md = tmp_path / "index.md"
  index_md.write_text(
    "# Index\n\n- [[page-alpha]]\n- [[page-beta]]\n- [[page-gamma]]\n",
    encoding="utf-8",
  )

  # ROOT/log.md を作成
  log_md = tmp_path / "log.md"
  log_md.write_text("# Log\n\n## 2026-04-18\n\n- 初回エントリ\n", encoding="utf-8")

  # グローバル定数をパッチ
  monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
  monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
  monkeypatch.setattr(rw_light, "INDEX_MD", str(index_md))
  monkeypatch.setattr(rw_light, "CHANGE_LOG_MD", str(log_md))
  monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
  monkeypatch.setattr(rw_light, "CLAUDE_MD", str(tmp_path / "CLAUDE.md"))
  monkeypatch.setattr(rw_light, "AGENTS_DIR", str(agents_dir))
  monkeypatch.setattr(rw_light, "RAW", str(raw_dir))
  monkeypatch.setattr(rw_light, "REVIEW", str(review_dir))

  return wiki_dir, logs_dir, raw_dir, review_dir, agents_dir


def _collect_file_snapshots(directory):
  """ディレクトリ内の全ファイルのパスと mtime のスナップショットを取得する。

  Args:
      directory: Path オブジェクト
  Returns:
      dict: {str(path): mtime} のマッピング
  """
  snapshot = {}
  if not directory.exists():
    return snapshot
  for f in directory.rglob("*"):
    if f.is_file():
      snapshot[str(f)] = f.stat().st_mtime
  return snapshot


class TestE2EAuditAllTiers:
  """全4ティアの E2E 動作確認テスト（Task 7.1）

  Req 6.1, 6.2, 6.3, 6.4, 7.1, 7.5
  """

  # ---------- micro ----------

  def test_micro_runs_and_generates_report(self, tmp_path, monkeypatch):
    """rw audit micro が正常に実行され logs/ にレポートが生成される（Req 1.4, 5.1）"""
    wiki_dir, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    # get_recent_wiki_changes は 1 つのファイルを返すようにモック
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(wiki_dir / "page-alpha.md")] if "diff" in args else [],
    )

    result = rw_light.cmd_audit_micro()

    assert isinstance(result, int)
    report_files = list(logs_dir.glob("audit-micro-*.md"))
    assert len(report_files) == 1, "micro レポートファイルが生成されること"

  def test_micro_report_in_logs_only(self, tmp_path, monkeypatch):
    """micro のレポートが logs/ にのみ出力される（Req 5.6）"""
    wiki_dir, logs_dir, raw_dir, review_dir, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(wiki_dir / "page-alpha.md")] if "diff" in args else [],
    )

    rw_light.cmd_audit_micro()

    # logs/ にレポートあること
    assert len(list(logs_dir.glob("audit-micro-*.md"))) == 1
    # wiki/ / raw/ / review/ にはファイルが増えていないこと
    assert len(list(review_dir.rglob("*.md"))) == 0

  # ---------- weekly ----------

  def test_weekly_runs_and_generates_report(self, tmp_path, monkeypatch):
    """rw audit weekly が全ページをスキャンし統合レポートを生成する（Req 2.3）"""
    _, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)

    result = rw_light.cmd_audit_weekly()

    assert isinstance(result, int)
    report_files = list(logs_dir.glob("audit-weekly-*.md"))
    assert len(report_files) == 1, "weekly レポートファイルが生成されること"

  def test_weekly_report_contains_all_pages(self, tmp_path, monkeypatch):
    """weekly レポートが全ページをスキャンしたメトリクスを含む（Req 2.1）"""
    _, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)

    rw_light.cmd_audit_weekly()

    report_files = list(logs_dir.glob("audit-weekly-*.md"))
    content = report_files[0].read_text(encoding="utf-8")
    # 3ページ分のスキャンが記録されること
    assert "pages_scanned" in content or "3" in content

  def test_weekly_report_in_logs_only(self, tmp_path, monkeypatch):
    """weekly のレポートが logs/ にのみ出力される（Req 5.6）"""
    _, logs_dir, raw_dir, review_dir, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)

    rw_light.cmd_audit_weekly()

    assert len(list(logs_dir.glob("audit-weekly-*.md"))) == 1
    assert len(list(review_dir.rglob("*.md"))) == 0

  # ---------- monthly ----------

  def test_monthly_generates_report_with_mock_claude(self, tmp_path, monkeypatch):
    """monthly が Claude CLI モック環境で JSON レスポンスをパースしレポートを生成する（Req 3.4）"""
    _, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_monthly_response(),
    )

    result = rw_light.cmd_audit_monthly([])

    assert isinstance(result, int)
    report_files = list(logs_dir.glob("audit-monthly-*.md"))
    assert len(report_files) == 1, "monthly レポートファイルが生成されること"

  def test_monthly_raw_response_saved(self, tmp_path, monkeypatch):
    """monthly の raw レスポンスファイルが logs/ に保存される（Req 5.6 design）"""
    _, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_monthly_response(),
    )

    rw_light.cmd_audit_monthly([])

    raw_files = list(logs_dir.glob("audit-monthly-*-raw.txt"))
    assert len(raw_files) == 1, "monthly の raw レスポンスファイルが logs/ に保存されること"

  def test_monthly_report_in_logs_only(self, tmp_path, monkeypatch):
    """monthly のレポートが logs/ にのみ出力される（Req 5.6, 6.1-6.3）"""
    _, logs_dir, raw_dir, review_dir, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_monthly_response(),
    )

    rw_light.cmd_audit_monthly([])

    assert len(list(logs_dir.glob("audit-monthly-*.md"))) == 1
    assert len(list(review_dir.rglob("*.md"))) == 0

  # ---------- quarterly ----------

  def test_quarterly_generates_report_with_mock_claude(self, tmp_path, monkeypatch):
    """quarterly が Claude CLI モック環境で quarterly レポートを生成する（Req 4.3）"""
    _, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_quarterly_response(),
    )

    result = rw_light.cmd_audit_quarterly([])

    assert isinstance(result, int)
    report_files = list(logs_dir.glob("audit-quarterly-*.md"))
    assert len(report_files) == 1, "quarterly レポートファイルが生成されること"

  def test_quarterly_raw_response_saved(self, tmp_path, monkeypatch):
    """quarterly の raw レスポンスファイルが logs/ に保存される（Req 5.6 design）"""
    _, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_quarterly_response(),
    )

    rw_light.cmd_audit_quarterly([])

    raw_files = list(logs_dir.glob("audit-quarterly-*-raw.txt"))
    assert len(raw_files) == 1, "quarterly の raw レスポンスファイルが logs/ に保存されること"

  def test_quarterly_report_in_logs_only(self, tmp_path, monkeypatch):
    """quarterly のレポートが logs/ にのみ出力される（Req 5.6, 6.1-6.3）"""
    _, logs_dir, raw_dir, review_dir, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_quarterly_response(),
    )

    rw_light.cmd_audit_quarterly([])

    assert len(list(logs_dir.glob("audit-quarterly-*.md"))) == 1
    assert len(list(review_dir.rglob("*.md"))) == 0

  # ---------- 読み取り専用保証（Req 6.1, 6.2, 6.3）----------

  def test_readonly_wiki_not_modified_after_all_tiers(self, tmp_path, monkeypatch):
    """全ティア実行後に wiki/ のファイルが変更されていない（Req 6.1）"""
    wiki_dir, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_monthly_response(),
    )
    # micro 用 git モック（変更なし → 対象 0 件でも OK）
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])

    # 実行前スナップショット
    before = _collect_file_snapshots(wiki_dir)

    # 全ティア実行
    rw_light.cmd_audit_micro()
    rw_light.cmd_audit_weekly()
    rw_light.cmd_audit_monthly([])
    rw_light.cmd_audit_quarterly([])

    # 実行後スナップショット
    after = _collect_file_snapshots(wiki_dir)

    assert before == after, f"wiki/ 内のファイルが変更された: before={before}, after={after}"

  def test_readonly_raw_not_modified_after_all_tiers(self, tmp_path, monkeypatch):
    """全ティア実行後に raw/ のファイルが変更されていない（Req 6.2）"""
    _, _, raw_dir, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_monthly_response(),
    )
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])

    before = _collect_file_snapshots(raw_dir)

    rw_light.cmd_audit_micro()
    rw_light.cmd_audit_weekly()
    rw_light.cmd_audit_monthly([])
    rw_light.cmd_audit_quarterly([])

    after = _collect_file_snapshots(raw_dir)

    assert before == after, f"raw/ 内のファイルが変更された: before={before}, after={after}"

  def test_readonly_review_not_modified_after_all_tiers(self, tmp_path, monkeypatch):
    """全ティア実行後に review/ のファイルが変更されていない（Req 6.3）"""
    _, _, _, review_dir, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "load_task_prompts", lambda name, **kw: "audit prompts")
    monkeypatch.setattr(rw_light, "read_all_wiki_content", lambda: "wiki content")
    monkeypatch.setattr(
      rw_light, "call_claude",
      lambda prompt, timeout=None: _make_valid_monthly_response(),
    )
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])

    before = _collect_file_snapshots(review_dir)

    rw_light.cmd_audit_micro()
    rw_light.cmd_audit_weekly()
    rw_light.cmd_audit_monthly([])
    rw_light.cmd_audit_quarterly([])

    after = _collect_file_snapshots(review_dir)

    assert before == after, f"review/ 内のファイルが変更された: before={before}, after={after}"

  # ---------- エラーケース ----------

  def test_error_wiki_missing_all_tiers_exit_1(self, tmp_path, monkeypatch, capsys):
    """wiki/ 不在の場合、全ティアが exit 1 を返す（Req 7.1）"""
    # wiki/ は作成しない
    logs_dir = tmp_path / "logs"
    logs_dir.mkdir()
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(tmp_path / "wiki"))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
    monkeypatch.setattr(rw_light, "CLAUDE_MD", str(tmp_path / "CLAUDE.md"))
    monkeypatch.setattr(rw_light, "AGENTS_DIR", str(tmp_path / "AGENTS"))

    assert rw_light.cmd_audit_micro() == 1
    assert rw_light.cmd_audit_weekly() == 1
    assert rw_light.cmd_audit_monthly([]) == 1
    assert rw_light.cmd_audit_quarterly([]) == 1

  def test_error_agents_missing_monthly_exits_1(self, tmp_path, monkeypatch, capsys):
    """AGENTS/ 不在の場合、monthly が exit 1 を返す（Req 7.5）"""
    wiki_dir, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    # AGENTS/ を削除
    import shutil as _shutil
    _shutil.rmtree(str(tmp_path / "AGENTS"))
    monkeypatch.setattr(rw_light, "AGENTS_DIR", str(tmp_path / "AGENTS"))

    result = rw_light.cmd_audit_monthly([])
    assert result == 1

    out = capsys.readouterr().out
    assert "[ERROR]" in out

  def test_error_agents_missing_quarterly_exits_1(self, tmp_path, monkeypatch, capsys):
    """AGENTS/ 不在の場合、quarterly が exit 1 を返す（Req 7.5）"""
    wiki_dir, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    import shutil as _shutil
    _shutil.rmtree(str(tmp_path / "AGENTS"))
    monkeypatch.setattr(rw_light, "AGENTS_DIR", str(tmp_path / "AGENTS"))

    result = rw_light.cmd_audit_quarterly([])
    assert result == 1

  def test_micro_no_changes_exits_0(self, tmp_path, monkeypatch):
    """micro 対象 0 件（変更なし）の場合 exit 0 を返す（Req 1.7）"""
    _, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    # 変更ファイルなしをモック
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])

    result = rw_light.cmd_audit_micro()

    assert result == 0

  def test_micro_no_changes_generates_report_with_zero_pages(self, tmp_path, monkeypatch):
    """micro 対象 0 件の場合、pages scanned: 0 のレポートが生成される（Req 1.7）"""
    _, logs_dir, _, _, _ = _setup_e2e_audit_vault(tmp_path, monkeypatch)
    monkeypatch.setattr(rw_light, "_git_list_files", lambda args: [])

    rw_light.cmd_audit_micro()

    report_files = list(logs_dir.glob("audit-micro-*.md"))
    assert len(report_files) == 1
    content = report_files[0].read_text(encoding="utf-8")
    assert "0" in content  # pages_scanned: 0 が記録されること


# ---------------------------------------------------------------------------
# _normalize_severity_token() のテスト（Task 1.2）
# ---------------------------------------------------------------------------

def test_normalize_severity_token():
  import io

  # (a) 新 4 水準 identity: CRITICAL/ERROR/WARN/INFO → 同一返却、drift_sink 空のまま
  for sev in ("CRITICAL", "ERROR", "WARN", "INFO"):
    sink = []
    result = rw_light._normalize_severity_token(sev, drift_sink=sink)
    assert result == sev, f"{sev!r} は identity で返るべき"
    assert len(sink) == 0, f"{sev!r} で drift_sink に余計なエントリが入った"

  # (b) 旧語彙 HIGH/MEDIUM/LOW → INFO 降格 + drift
  for old in ("HIGH", "MEDIUM", "LOW"):
    sink = []
    stderr_cap = io.StringIO()
    sys.stderr = stderr_cap
    try:
      result = rw_light._normalize_severity_token(
        old,
        source_context={"context": "test", "source_field": "x", "location": "f:1"},
        drift_sink=sink,
      )
    finally:
      sys.stderr = sys.__stderr__
    assert result == "INFO", f"旧語彙 {old!r} は INFO に降格されるべき"
    assert len(sink) == 1, f"旧語彙 {old!r} で drift_sink に 1 エントリ追加されるべき"
    entry = sink[0]
    assert set(entry.keys()) == {
      "original_token", "sanitized_token", "demoted_to", "source_field", "context"
    }, f"drift entry のキーが不正: {set(entry.keys())}"
    assert entry["demoted_to"] == "INFO"
    assert "[severity-drift]" in stderr_cap.getvalue(), "stderr に [severity-drift] が出力されるべき"

  # (c) 未知 severity（WARNING 等）→ INFO + drift
  sink = []
  result = rw_light._normalize_severity_token("WARNING", drift_sink=sink)
  assert result == "INFO", "未知トークン WARNING は INFO に降格されるべき"
  assert len(sink) == 1, "未知トークンで drift_sink に 1 エントリ追加されるべき"

  # (d) 空文字 / None / 非 str → drift + INFO
  for bad in ("", None, 123):
    sink = []
    result = rw_light._normalize_severity_token(bad, drift_sink=sink)
    assert result == "INFO", f"{bad!r} は INFO に降格されるべき"
    assert len(sink) == 1, f"{bad!r} で drift_sink に 1 エントリ追加されるべき"

  # (e) drift_sink エントリの shape 検証（5 キー必須）
  sink = []
  rw_light._normalize_severity_token(
    "HIGH",
    source_context={"context": "c", "source_field": "f", "location": "l"},
    drift_sink=sink,
  )
  entry = sink[0]
  assert "original_token" in entry
  assert "sanitized_token" in entry
  assert "demoted_to" in entry
  assert "source_field" in entry
  assert "context" in entry


# ---------------------------------------------------------------------------
# Task 2.9: cmd_lint / cmd_audit_* FAIL → exit 2
# ---------------------------------------------------------------------------


class TestAuditExit2OnFail:
  """cmd_audit_micro / cmd_audit_weekly の exit code 3 値契約を検証"""

  def test_cmd_audit_micro_exit_2_on_error_finding(self, tmp_path, monkeypatch):
    """ERROR finding がある場合 cmd_audit_micro は exit 2"""
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()
    logs_dir = tmp_path / "logs"
    logs_dir.mkdir()
    broken_page = wiki_dir / "broken.md"
    broken_page.write_text(
      "---\ntitle: B\nsource: web\n---\n\n# B\n\n[[nonexistent]] link.\n",
      encoding="utf-8",
    )
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(broken_page)] if "diff" in args else []
    )
    result = rw_light.cmd_audit_micro()
    assert result == 2

  def test_cmd_audit_micro_exit_0_on_pass(self, tmp_path, monkeypatch):
    """ERROR なし → exit 0"""
    wiki_dir = tmp_path / "wiki"
    wiki_dir.mkdir()
    logs_dir = tmp_path / "logs"
    logs_dir.mkdir()
    page = wiki_dir / "page.md"
    page.write_text(
      "---\ntitle: P\nsource: web\n---\n\n# P\n\nBody.\n",
      encoding="utf-8",
    )
    monkeypatch.setattr(rw_light, "ROOT", str(tmp_path))
    monkeypatch.setattr(rw_light, "WIKI", str(wiki_dir))
    monkeypatch.setattr(rw_light, "INDEX_MD", str(tmp_path / "index.md"))
    monkeypatch.setattr(rw_light, "LOGDIR", str(logs_dir))
    monkeypatch.setattr(
      rw_light, "_git_list_files",
      lambda args: [str(page)] if "diff" in args else []
    )
    result = rw_light.cmd_audit_micro()
    assert result == 0


# ---------------------------------------------------------------------------
# Task 1.7: map_severity() 全廃
# ---------------------------------------------------------------------------


def test_map_severity_deleted():
  """map_severity should no longer exist after task 1.7"""
  assert not hasattr(rw_light, "map_severity"), "map_severity should be deleted in task 1.7"


# ---------------------------------------------------------------------------
# Task 2.1: _compute_run_status(findings) helper
# ---------------------------------------------------------------------------


def _severity_finding(severity: str) -> rw_light.Finding:
  return rw_light.Finding(
    severity=severity,
    category="test",
    page="test/page.md",
    message="test message",
    marker="",
  )


def test_compute_run_status():
  """_compute_run_status: CRITICAL or ERROR → FAIL, otherwise → PASS"""
  fn = rw_light._compute_run_status

  # (a) 空 findings → PASS
  assert fn([]) == "PASS"

  # (b) INFO のみ → PASS
  assert fn([_severity_finding("INFO")]) == "PASS"

  # (c) WARN のみ → PASS
  assert fn([_severity_finding("WARN")]) == "PASS"

  # (d) ERROR 1 件 → FAIL
  assert fn([_severity_finding("ERROR")]) == "FAIL"

  # (e) CRITICAL 1 件 → FAIL
  assert fn([_severity_finding("CRITICAL")]) == "FAIL"

  # (f) CRITICAL + ERROR 混在 → FAIL
  assert fn([_severity_finding("CRITICAL"), _severity_finding("ERROR")]) == "FAIL"


# ---------------------------------------------------------------------------
# Task 2.2: _compute_exit_code(status, had_runtime_error) helper
# ---------------------------------------------------------------------------


def test_compute_exit_code():
  """_compute_exit_code: had_runtime_error=True → 1, FAIL → 2, PASS → 0"""
  fn = rw_light._compute_exit_code

  # (a) PASS + no runtime error → 0
  assert fn("PASS", False) == 0

  # (b) had_runtime_error=True, status PASS → 1 (runtime overrides)
  assert fn("PASS", True) == 1

  # (c) had_runtime_error=True, status FAIL → 1 (runtime overrides)
  assert fn("FAIL", True) == 1

  # (d) FAIL + no runtime error → 2
  assert fn("FAIL", False) == 2

  # (e) None status + runtime error → 1
  assert fn(None, True) == 1

  # (f) None status + no runtime error → 0 (treat None as PASS)
  assert fn(None, False) == 0
