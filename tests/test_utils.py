"""
tests/test_utils.py — ユーティリティ関数の単体テスト

対象: parse_frontmatter, build_frontmatter, slugify, list_md_files,
      first_h1, ensure_basic_frontmatter, read_text/write_text/append_text,
      read_json
"""

import json
import os

import pytest

import rw_light


class TestParseFrontmatter:
  """parse_frontmatter の正常系・異常系テスト"""

  def test_normal_yaml(self):
    """正常な YAML フロントマターをパースできる"""
    text = "---\ntitle: Hello\nauthor: Alice\n---\nBody text"
    meta, body = rw_light.parse_frontmatter(text)
    assert meta["title"] == "Hello"
    assert meta["author"] == "Alice"
    assert body == "Body text"

  def test_no_frontmatter(self):
    """フロントマターなしのテキストは空の dict とテキスト全体を返す"""
    text = "Just a plain body"
    meta, body = rw_light.parse_frontmatter(text)
    assert meta == {}
    assert body == text

  def test_opening_dashes_only(self):
    """開始 --- のみで終了 --- がない場合は空の dict と元テキストを返す"""
    text = "---\ncontent without closing dashes"
    meta, body = rw_light.parse_frontmatter(text)
    assert meta == {}
    assert body == text


class TestBuildFrontmatter:
  """build_frontmatter のテスト"""

  def test_dict_to_yaml(self):
    """辞書から YAML フロントマットブロックを生成する"""
    meta = {"title": "My Note", "source": "web"}
    result = rw_light.build_frontmatter(meta)
    assert result.startswith("---")
    assert 'title: "My Note"' in result
    assert 'source: "web"' in result
    assert result.endswith("---\n")

  def test_roundtrip_with_special_chars(self):
    """YAML 特殊文字（コロン含む title）を含む値で build → parse 往復しても元データが復元される"""
    original = {"title": "Python: A Guide", "source": "local", "added": "2025-01-01"}
    built = rw_light.build_frontmatter(original)
    parsed, body = rw_light.parse_frontmatter(built + "body")
    assert parsed["title"] == "Python: A Guide"
    assert parsed["source"] == "local"
    assert parsed["added"] == "2025-01-01"


class TestSlugify:
  """slugify のテスト"""

  def test_japanese_to_ascii(self):
    """日本語文字列は ASCII スラッグに変換される（非 ASCII は除去）"""
    result = rw_light.slugify("テスト")
    # 日本語は ASCII に変換できないため除去 → 空 → "untitled"
    assert result == "untitled"

  def test_symbols_and_spaces(self):
    """記号・スペース混在の文字列はハイフン区切りに正規化される"""
    result = rw_light.slugify("Hello, World! Test")
    assert result == "hello-world-test"
    assert len(result) <= 80

  def test_empty_string(self):
    """空文字列は 'untitled' を返す"""
    result = rw_light.slugify("")
    assert result == "untitled"


class TestListMdFiles:
  """list_md_files のテスト"""

  def test_returns_only_md_files(self, tmp_path):
    """.md と非 .md が混在するディレクトリは .md ファイルのみ返す"""
    (tmp_path / "note.md").write_text("# Note", encoding="utf-8")
    (tmp_path / "readme.txt").write_text("text file", encoding="utf-8")
    (tmp_path / "data.json").write_text("{}", encoding="utf-8")
    subdir = tmp_path / "sub"
    subdir.mkdir()
    (subdir / "nested.md").write_text("# Nested", encoding="utf-8")

    result = rw_light.list_md_files(str(tmp_path))
    basenames = [os.path.basename(p) for p in result]
    assert "note.md" in basenames
    assert "nested.md" in basenames
    assert "readme.txt" not in basenames
    assert "data.json" not in basenames

  def test_nonexistent_dir_returns_empty(self, tmp_path):
    """存在しないディレクトリに対しては空リストを返す"""
    result = rw_light.list_md_files(str(tmp_path / "does_not_exist"))
    assert result == []


class TestFirstH1:
  """first_h1 のテスト"""

  def test_h1_found(self):
    """H1 見出しがある場合はそのテキストを返す"""
    text = "## Section\n\n# My Title\n\nBody"
    assert rw_light.first_h1(text) == "My Title"

  def test_no_h1(self):
    """H1 見出しがない場合は None を返す"""
    text = "## Section\nJust body text without H1"
    assert rw_light.first_h1(text) is None


class TestEnsureBasicFrontmatter:
  """ensure_basic_frontmatter のテスト"""

  def test_missing_fields_are_filled(self, tmp_path, fixed_today):
    """フィールド欠落時は title（H1 優先）, source, added が自動補完される"""
    path = tmp_path / "note.md"
    path.write_text("# My H1 Title\nBody content", encoding="utf-8")

    modified, fixes, new_text = rw_light.ensure_basic_frontmatter(str(path), "web")

    assert modified is True
    assert "filled title" in fixes
    assert "filled source" in fixes
    assert "filled added" in fixes

    meta, body = rw_light.parse_frontmatter(new_text)
    # H1 が title として使われることを確認
    assert meta["title"] == "My H1 Title"
    assert meta["source"] == "web"
    assert meta["added"] == fixed_today

  def test_missing_title_uses_basename_when_no_h1(self, tmp_path, fixed_today):
    """H1 がない場合は os.path.basename(path) が title として使われる"""
    path = tmp_path / "my_note.md"
    path.write_text("Body without H1 heading", encoding="utf-8")

    modified, fixes, new_text = rw_light.ensure_basic_frontmatter(str(path), "local")

    meta, body = rw_light.parse_frontmatter(new_text)
    assert meta["title"] == "my_note.md"

  def test_all_fields_present_no_change(self, tmp_path, fixed_today):
    """全フィールドが既に存在する場合は変更なし（modified=False, fixes=[]）"""
    # ensure_basic_frontmatter が生成する形式（build_frontmatter + "\n" + body.strip() + "\n"）
    # と完全一致するようにファイルを作成する
    meta = {
      "title": "Existing Title",
      "source": "web",
      "added": "2025-01-01",
    }
    body = "Body text"
    content = rw_light.build_frontmatter(meta) + "\n" + body + "\n"
    path = tmp_path / "existing.md"
    path.write_text(content, encoding="utf-8")

    modified, fixes, new_text = rw_light.ensure_basic_frontmatter(str(path), "unknown")

    assert modified is False
    assert fixes == []


class TestFileIO:
  """read_text, write_text, append_text のテスト"""

  def test_write_and_read_japanese_utf8(self, tmp_path):
    """write_text で書いた日本語テキストを read_text で正しく読み返せる"""
    path = tmp_path / "test.md"
    content = "日本語テキスト: テスト用コンテンツ\n"
    rw_light.write_text(str(path), content)
    result = rw_light.read_text(str(path))
    assert result == content

  def test_append_text_japanese(self, tmp_path):
    """append_text で日本語テキストを追記でき、既存内容が保持される"""
    path = tmp_path / "append_test.md"
    rw_light.write_text(str(path), "最初の行\n")
    rw_light.append_text(str(path), "追記した行\n")
    result = rw_light.read_text(str(path))
    assert "最初の行" in result
    assert "追記した行" in result

  def test_write_creates_parent_dirs(self, tmp_path):
    """write_text は親ディレクトリが存在しなくても自動作成してファイルを書き込む"""
    path = tmp_path / "nested" / "dir" / "file.txt"
    rw_light.write_text(str(path), "content")
    assert path.exists()
    assert rw_light.read_text(str(path)) == "content"


class TestReadJson:
  """read_json のテスト"""

  def test_valid_json_returns_dict(self, tmp_path):
    """有効な JSON ファイルを辞書として読み込める"""
    data = {"key": "value", "number": 42, "list": [1, 2, 3]}
    path = tmp_path / "data.json"
    path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")

    result = rw_light.read_json(str(path))
    assert result["key"] == "value"
    assert result["number"] == 42
    assert result["list"] == [1, 2, 3]

  def test_invalid_json_raises_exception(self, tmp_path):
    """不正な JSON ファイルは例外（JSONDecodeError）を送出する"""
    path = tmp_path / "broken.json"
    path.write_text("{ invalid json content }", encoding="utf-8")

    with pytest.raises(json.JSONDecodeError):
      rw_light.read_json(str(path))
