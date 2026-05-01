"""dr-judgment skill: judgment subagent dispatch helper script.

Responsibilities (P4 fix integrated, design.md L565-568 + L570 整合):
- prompt load: foundation ./prompts/judgment_subagent_prompt.txt 動的 read
- payload assemble: primary_findings + adversarial_findings + adversarial_counter_evidence + requirements_text + design_text? + semi_mechanical_mapping_defaults
- yaml output validate: foundation ./schemas/necessity_judgment.schema.json で V4 §1.6 yaml format 整合性確認
- escalate mapping: uncertainty=high → fix_decision.label=should_fix + recommended_action=user_decision

Out of scope (= SKILL.md responsibility = Claude assistant が Agent tool 経由実行):
- judgment subagent dispatch
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import jsonschema
import yaml


# V4 §1.4.2 semi-mechanical mapping defaults (7 種、foundation prompt L22-29 整合)
SEMI_MECHANICAL_MAPPING_DEFAULTS = [
  {"condition": "AC linkage direct", "requirement_link": "yes", "ignored_impact": "high"},
  {"condition": "AC linkage indirect", "requirement_link": "indirect", "ignored_impact": "medium"},
  {"condition": "No AC linkage + security/data_loss/sandbox_escape", "ignored_impact": "critical"},
  {"condition": "No AC linkage + no security", "requirement_link": "no", "ignored_impact": "low"},
  {"condition": "Fix scope: 1 file <=5 lines", "fix_cost": "low"},
  {"condition": "Fix scope: cross-spec or schema change", "fix_cost": "high"},
  {"condition": "Otherwise", "fix_cost": "medium"},
]


def load_judgment_prompt(dual_reviewer_root: Path) -> str:
  """foundation ./prompts/judgment_subagent_prompt.txt を読み返す (hardcode 禁止、Req 5.5)."""
  prompt_path = Path(dual_reviewer_root) / "prompts" / "judgment_subagent_prompt.txt"
  if not prompt_path.is_file():
    print(f"prompt file not found: {prompt_path}", file=sys.stderr)
    raise FileNotFoundError(prompt_path)
  return prompt_path.read_text(encoding="utf-8")


def assemble_payload(
  primary_findings: list[dict],
  adversarial_findings: list[dict],
  adversarial_counter_evidence: list[dict],
  requirements_text: str,
  design_text: str | None = None,
) -> dict[str, Any]:
  """dispatch payload (6 field) 構造化 (Req 3.2)."""
  payload: dict[str, Any] = {
    "primary_findings": primary_findings,
    "adversarial_findings": adversarial_findings,
    "adversarial_counter_evidence": adversarial_counter_evidence,
    "requirements_text": requirements_text,
    "semi_mechanical_mapping_defaults": SEMI_MECHANICAL_MAPPING_DEFAULTS,
  }
  if design_text is not None:
    payload["design_text"] = design_text
  return payload


def validate_judgment_output(yaml_str: str, schemas_dir: Path) -> list[dict]:
  """parse yaml + each entry validate against necessity_judgment.schema.json.

  Returns: list of validated judgment entries.
  Raises: FileNotFoundError if schema missing / yaml.YAMLError on parse fail / jsonschema.ValidationError on schema fail.
  """
  schema_path = Path(schemas_dir) / "necessity_judgment.schema.json"
  if not schema_path.is_file():
    raise FileNotFoundError(schema_path)
  schema = json.loads(schema_path.read_text(encoding="utf-8"))
  entries = yaml.safe_load(yaml_str)
  if entries is None:
    return []
  if not isinstance(entries, list):
    entries = [entries]
  validator = jsonschema.Draft202012Validator(schema)
  for idx, entry in enumerate(entries):
    necessity = entry.get("necessity", entry) if isinstance(entry, dict) else entry
    errors = list(validator.iter_errors(necessity))
    if errors:
      raise jsonschema.ValidationError(
        f"entry {idx} validation failed: {[e.message for e in errors]}"
      )
  return entries


def apply_escalate_mapping(entry: dict) -> dict:
  """uncertainty=high → fix_decision.label=should_fix + recommended_action=user_decision (Req 3.5)."""
  necessity = entry.get("necessity", entry) if isinstance(entry, dict) else entry
  if necessity.get("uncertainty") == "high":
    necessity.setdefault("fix_decision", {})["label"] = "should_fix"
    necessity["recommended_action"] = "user_decision"
  return entry


def main() -> int:
  parser = argparse.ArgumentParser(description="dr-judgment payload assembler + validator helper")
  parser.add_argument("--payload-json", required=False, default=None, help="JSON file path or '-' for stdin")
  parser.add_argument("--dual-reviewer-root", required=True, type=Path)
  parser.add_argument("--config-yaml-path", required=True, type=Path)
  args = parser.parse_args()

  try:
    prompt = load_judgment_prompt(args.dual_reviewer_root)
  except FileNotFoundError:
    return 1

  # smoke test mode (Observable for Task 6.6 CLI test): prompt load 成功 + ready stdout 出力
  output = {"prompt_loaded_bytes": len(prompt), "ready": True}
  print(json.dumps(output))
  return 0


if __name__ == "__main__":
  sys.exit(main())
