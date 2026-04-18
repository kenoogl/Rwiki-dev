"""Unit tests for rw_light.py — Task 1.1: parse_agent_mapping / load_task_prompts"""
import json
import os
import sys
import textwrap
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")

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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_EXTRACT_RESPONSE)

        result = rw_light.cmd_query_extract(["test question", "--type", "fact"])
        assert result in (0, 2)

    def test_large_wiki_triggers_2stage(self, tmp_path, monkeypatch):
        """ファイル数>20 かつ scope=None の場合: 2段階方式が呼び出されること"""
        _, review_query_dir = _setup_mock_vault_for_query(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "today", lambda: "2026-04-17")
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")

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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        result = rw_light.cmd_query_answer(["test question"])
        assert result == 0

    def test_success_no_file_created_in_query_review(self, tmp_path, monkeypatch):
        """成功パス: review/query/ にファイルが生成されないこと（Req 2.3）"""
        _, review_query_dir = _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        rw_light.cmd_query_answer(["test question"])

        # review/query/ 配下にファイルやディレクトリが生成されていないこと
        entries = list(review_query_dir.iterdir())
        assert entries == [], f"Unexpected files in review/query/: {entries}"

    def test_success_stdout_contains_answer_text(self, tmp_path, monkeypatch, capsys):
        """成功パス: stdout に回答テキストが含まれること"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        rw_light.cmd_query_answer(["test question"])

        captured = capsys.readouterr()
        assert "This is the answer." in captured.out
        assert "Answer content here." in captured.out

    def test_success_stdout_contains_referenced_pages(self, tmp_path, monkeypatch, capsys):
        """成功パス: stdout に参照ページ（Referenced: セクション）が含まれること"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
        monkeypatch.setattr(rw_light, "call_claude", lambda p: MOCK_ANSWER_RESPONSE)

        rw_light.cmd_query_answer(["test question"])

        captured = capsys.readouterr()
        assert "wiki/concepts/test.md" in captured.out
        assert "wiki/methods/method.md" in captured.out

    def test_response_without_referenced_section_still_returns_0(self, tmp_path, monkeypatch, capsys):
        """---\\nReferenced: セパレータなし → 全体を回答として出力し return 0"""
        _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
        no_ref_response = "This is an answer without referenced section."
        monkeypatch.setattr(rw_light, "call_claude", lambda p: no_ref_response)

        result = rw_light.cmd_query_answer(["test question"])

        assert result == 0
        captured = capsys.readouterr()
        assert "This is an answer without referenced section." in captured.out

    def test_scope_option_passes_to_read_wiki_content(self, tmp_path, monkeypatch):
        """--scope オプションが read_wiki_content に渡されること"""
        _, _ = _setup_mock_vault_for_answer(tmp_path, monkeypatch)
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")

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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        monkeypatch.setattr(rw_light, "load_task_prompts", lambda task: "mock prompts")
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
        assert any("QL006" in e for e in lint_result["errors"]), (
            f"QL006 error expected, got: {lint_result['errors']}"
        )

        # Step 4: fix（call_claude を fix レスポンスにすり替え）
        monkeypatch.setattr(rw_light, "call_claude", lambda p: _make_fix_response(query_id))
        fix_result = rw_light.cmd_query_fix([query_id])
        assert fix_result in (0, 2), f"fix command returned unexpected code: {fix_result}"

        # Step 5: lint 再検証 → PASS
        post_lint = rw_light.lint_single_query_dir(str(qdir))
        assert post_lint["status"] in ("PASS", "PASS_WITH_WARNINGS"), (
            f"lint should PASS after fix, got: {post_lint['status']}, errors: {post_lint['errors']}"
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

    def test_finding_has_six_fields(self):
        """Finding NamedTuple は 6 フィールドを持つこと"""
        f = rw_light.Finding(
            severity="ERROR",
            category="broken_link",
            page="concepts/my-page.md",
            message="リンク先が存在しない",
            sub_severity="CRITICAL",
            marker="CONFLICT",
        )
        assert f.severity == "ERROR"
        assert f.category == "broken_link"
        assert f.page == "concepts/my-page.md"
        assert f.message == "リンク先が存在しない"
        assert f.sub_severity == "CRITICAL"
        assert f.marker == "CONFLICT"

    def test_finding_fields_all_str(self):
        """Finding の全フィールドが str 型であること"""
        f = rw_light.Finding(
            severity="WARN",
            category="orphan_page",
            page="methods/orphan.md",
            message="孤立ページ",
            sub_severity="",
            marker="",
        )
        for field in (f.severity, f.category, f.page, f.message, f.sub_severity, f.marker):
            assert isinstance(field, str), f"Expected str, got {type(field)}"

    def test_finding_is_named_tuple(self):
        """Finding が NamedTuple であること"""
        import typing
        assert issubclass(rw_light.Finding, tuple)
        assert hasattr(rw_light.Finding, "_fields")
        assert set(rw_light.Finding._fields) == {
            "severity", "category", "page", "message", "sub_severity", "marker"
        }


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
