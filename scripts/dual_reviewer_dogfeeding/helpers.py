"""Common helpers for dual-reviewer-dogfeeding 3 Python scripts.

Foundation install location resolve mechanism (P3 + C2 fix 整合):
- _resolve_foundation_path(base_root, relative): `./` prefix relative path を
  foundation install location absolute path に解決
- foundation install location は CLI flag `--dual-reviewer-root` default + `DUAL_REVIEWER_ROOT` 環境変数 fallback で受領
- 3 script (metric_extractor / figure_data_generator / phase_b_judgment) は本 module から import (DRY 規律 = inline 実装禁止)
"""

import os
from pathlib import Path


def resolve_foundation_root(cli_arg: Path | None = None) -> Path:
  """Resolve foundation install location from CLI flag → env var fallback.

  Args:
    cli_arg: --dual-reviewer-root CLI 引数値 (None の場合 env fallback)

  Returns:
    foundation install location の absolute Path

  Raises:
    ValueError: CLI flag + env var 両方未指定の場合
    FileNotFoundError: 解決された path が directory として存在しない場合
  """
  if cli_arg is not None:
    root = Path(cli_arg).resolve()
  else:
    env_value = os.environ.get("DUAL_REVIEWER_ROOT")
    if not env_value:
      raise ValueError(
        "foundation install location 未指定: --dual-reviewer-root CLI flag または DUAL_REVIEWER_ROOT 環境変数 必須"
      )
    root = Path(env_value).resolve()
  if not root.is_dir():
    raise FileNotFoundError(f"foundation install location not found: {root}")
  return root


def _resolve_foundation_path(base_root: Path | str, relative: str) -> Path:
  """Resolve `./` prefix relative path against foundation install location."""
  base = Path(base_root)
  rel = relative.lstrip("./")
  return base / rel
