# Task 7.1: Foundation install location relative path locate test
# foundation install location (`scripts/dual_reviewer_prototype/`) からの相対 path で 8 file 全 locate
import json
from pathlib import Path

import yaml

PROTOTYPE_ROOT = Path(__file__).resolve().parents[3]


def test_locate_5_schemas_via_relative_path():
  schema_dir = PROTOTYPE_ROOT / "schemas"
  for n in ["review_case", "finding", "impact_score", "failure_observation", "necessity_judgment"]:
    p = schema_dir / f"{n}.schema.json"
    assert p.exists(), f"missing schema: {p}"
    schema = json.load(open(p))
    assert "$schema" in schema, f"{n}: $schema missing"
    assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"


def test_locate_2_patterns_via_relative_path():
  patterns_dir = PROTOTYPE_ROOT / "patterns"
  fatal = yaml.safe_load(open(patterns_dir / "fatal_patterns.yaml"))
  assert len(fatal["patterns"]) == 8
  seed = yaml.safe_load(open(patterns_dir / "seed_patterns.yaml"))
  assert len(seed["patterns"]) == 23


def test_locate_judgment_subagent_prompt_via_relative_path():
  prompt_path = PROTOTYPE_ROOT / "prompts" / "judgment_subagent_prompt.txt"
  assert prompt_path.exists()
  content = prompt_path.read_text()
  lines = content.splitlines()
  # header 3 行 presence
  assert lines[0].startswith("# canonical-source:")
  assert lines[1].startswith("# v4-protocol-version:")
  assert lines[2].startswith("# sync-policy:")
  # 本文 presence (4 行目以降に non-empty content)
  body = "\n".join(lines[3:])
  assert "judgment-only subagent" in body
  assert "5 fields" in body or "5 judgment rules" in body


def test_total_8_files_locate():
  paths = [
    PROTOTYPE_ROOT / "schemas" / "review_case.schema.json",
    PROTOTYPE_ROOT / "schemas" / "finding.schema.json",
    PROTOTYPE_ROOT / "schemas" / "impact_score.schema.json",
    PROTOTYPE_ROOT / "schemas" / "failure_observation.schema.json",
    PROTOTYPE_ROOT / "schemas" / "necessity_judgment.schema.json",
    PROTOTYPE_ROOT / "patterns" / "seed_patterns.yaml",
    PROTOTYPE_ROOT / "patterns" / "fatal_patterns.yaml",
    PROTOTYPE_ROOT / "prompts" / "judgment_subagent_prompt.txt",
  ]
  for p in paths:
    assert p.exists(), f"missing: {p}"
