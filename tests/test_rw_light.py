"""Unit tests for rw_light.py — Task 1.1: parse_agent_mapping / load_task_prompts"""
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
