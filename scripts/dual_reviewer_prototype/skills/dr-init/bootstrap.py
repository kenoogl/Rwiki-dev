#!/usr/bin/env python3
"""dr-init bootstrap (Req 2.1-2.7)

target project root に `.dual-reviewer/` directory + 4 file (config.yaml +
extracted_patterns.yaml + terminology.yaml + dev_log.jsonl) を all-or-nothing
で配置する。Phase A scope では --lang ja のみ対応 (他 lang は exit 3 + Phase
B-1.3 reference message)。
"""
import argparse
import os
import shutil
import sys
from pathlib import Path

PROTOTYPE_ROOT = Path(__file__).resolve().parents[2]
CONFIG_TEMPLATE = PROTOTYPE_ROOT / "config" / "config.yaml.template"
TERMINOLOGY_TEMPLATE = PROTOTYPE_ROOT / "terminology" / "terminology.yaml.template"

EXIT_SUCCESS = 0
EXIT_CONFLICT = 1
EXIT_FILESYSTEM_ERROR = 2
EXIT_UNSUPPORTED_LANG = 3
EXIT_ROLLBACK_FAILURE = 4

EXTRACTED_PATTERNS_INITIAL = (
  "# Layer 3 抽出 patterns (Layer 3 Extracted Patterns Placeholder)\n"
  "# 本 file は dr-init bootstrap で生成された Layer 3 placeholder。\n"
  "# 実体的蓄積は dogfeeding 以降に蓄積する。\n"
  'version: "1.0"\n'
  "patterns: []\n"
)


def bootstrap(target: Path, lang: str = "ja") -> int:
  # 4 重 mechanical pre-check
  if not target.is_dir():
    print(f"target is not a directory: {target}", file=sys.stderr)
    return EXIT_FILESYSTEM_ERROR

  dr = target / ".dual-reviewer"
  if dr.exists():
    print(f"conflict: .dual-reviewer/ already exists at {dr}", file=sys.stderr)
    return EXIT_CONFLICT

  if lang != "ja":
    print(
      f"unsupported lang: {lang!r}. Only 'ja' is supported in Phase A scope. "
      "Other languages are reserved for Phase B-1.3 release.",
      file=sys.stderr,
    )
    return EXIT_UNSUPPORTED_LANG

  if not os.access(target, os.W_OK):
    print(f"target is not writable: {target}", file=sys.stderr)
    return EXIT_FILESYSTEM_ERROR

  created: list[Path] = []
  try:
    dr.mkdir()
    created.append(dr)

    config_dst = dr / "config.yaml"
    config_dst.write_text(CONFIG_TEMPLATE.read_text())
    created.append(config_dst)

    extracted = dr / "extracted_patterns.yaml"
    extracted.write_text(EXTRACTED_PATTERNS_INITIAL)
    created.append(extracted)

    term_dst = dr / "terminology.yaml"
    term_dst.write_text(TERMINOLOGY_TEMPLATE.read_text())
    created.append(term_dst)

    dev_log = dr / "dev_log.jsonl"
    dev_log.touch()
    created.append(dev_log)

  except Exception as e:
    return _rollback(created, dr, original_error=e)

  print(str(dr.resolve()))
  return EXIT_SUCCESS


def _rollback(created: list[Path], dr_dir: Path, original_error: Exception) -> int:
  failed: list[str] = []
  for p in reversed(created):
    if p == dr_dir:
      continue
    try:
      p.unlink()
    except Exception:
      failed.append(str(p.resolve()))

  if dr_dir.exists():
    try:
      dr_dir.rmdir()
    except OSError:
      try:
        shutil.rmtree(dr_dir)
      except Exception:
        failed.append(str(dr_dir.resolve()))

  if failed:
    print("rollback failure: residual files (please delete manually):", file=sys.stderr)
    for path in failed:
      print(path, file=sys.stderr)
    print(f"original error during bootstrap: {original_error}", file=sys.stderr)
    return EXIT_ROLLBACK_FAILURE

  print(f"filesystem error during bootstrap, rolled back: {original_error}", file=sys.stderr)
  return EXIT_FILESYSTEM_ERROR


def main(argv=None) -> int:
  parser = argparse.ArgumentParser(
    description="dr-init: bootstrap .dual-reviewer/ in target project root"
  )
  parser.add_argument("--target", required=True, type=Path, help="target project root path")
  parser.add_argument("--lang", default="ja", help="language (default: ja)")
  args = parser.parse_args(argv)
  return bootstrap(args.target, args.lang)


if __name__ == "__main__":
  sys.exit(main())
