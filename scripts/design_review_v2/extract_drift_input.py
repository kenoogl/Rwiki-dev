"""Phase 2-E 意味的ドリフト検出の入力サブセットを抽出する。

design_metadata.yaml から:
- requirements_index のうち constraint_kind != normal の項目
- 上記 requirement を parent_specs に持つ design_units の振る舞い情報

をペア化して drift_input.yaml に出力する。LLM がこれを入力に drift_findings.yaml を生成する。

Usage:
    python extract_drift_input.py <metadata_yaml_path>
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml


def extract(metadata: dict) -> dict:
  req_by_id = {r["id"]: r for r in metadata.get("requirements_index", [])}

  constraints = []
  for r in metadata.get("requirements_index", []):
    if r.get("constraint_kind") == "normal":
      continue
    constraints.append({
      "requirement_id": r["id"],
      "constraint_kind": r["constraint_kind"],
      "constraint_text": r.get("constraint_text", ""),
    })

  pairs = []
  for unit in metadata.get("design_units", []):
    for ps in unit.get("parent_specs") or []:
      req = req_by_id.get(ps)
      if not req or req.get("constraint_kind") == "normal":
        continue
      pairs.append({
        "pair_id": f"{ps}::{unit['id']}",
        "requirement_id": ps,
        "design_unit_id": unit["id"],
        "constraint_kind": req["constraint_kind"],
        "constraint_text": req.get("constraint_text", ""),
        "design_responsibilities": unit.get("responsibilities") or [],
        "design_bools": {
          "auto_approval": unit.get("auto_approval", False),
          "human_gate": unit.get("human_gate", False),
          "llm_judgment": unit.get("llm_judgment", False),
          "llm_confidence_or_escalation": unit.get("llm_confidence_or_escalation", False),
          "state_change": unit.get("state_change", False),
          "rollback_defined": unit.get("rollback_defined", False),
        },
      })

  return {
    "feature_name": metadata.get("feature_name"),
    "constraints_count": len(constraints),
    "pairs_count": len(pairs),
    "constraints": constraints,
    "pairs": pairs,
  }


def main(metadata_path: str) -> None:
  with open(metadata_path) as f:
    metadata = yaml.safe_load(f)
  result = extract(metadata)
  out_path = Path(metadata_path).parent / "drift_input.yaml"
  with open(out_path, "w") as f:
    yaml.safe_dump(result, f, allow_unicode=True, sort_keys=False)
  print(f"constraints (non-normal): {result['constraints_count']}")
  print(f"pairs (design × constraint): {result['pairs_count']}")
  print(f"written to: {out_path}")


if __name__ == "__main__":
  if len(sys.argv) != 2:
    print("Usage: python extract_drift_input.py <metadata_yaml_path>", file=sys.stderr)
    sys.exit(2)
  main(sys.argv[1])
