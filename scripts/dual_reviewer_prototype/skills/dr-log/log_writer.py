"""dr-log skill: review session-scoped JSONL log writer.

Service Interface (design.md L463-492 + A1 fix session lifecycle):
- open(session_id, treatment, round_index, design_md_commit_hash, target_spec_id, config_yaml_path)
- append(session_id, finding)  # per-finding invoke
- flush(session_id)             # Round 終端、1 JSONL line per session_id

Responsibilities:
- foundation ./schemas/ 動的読込 (referencing.Registry + Resource + DRAFT202012)
- target project .dual-reviewer/config.yaml の dev_log_path 動的読込
- in-memory accumulator: per session_id state (metadata + findings list + timestamp_start)
- per-finding schema validate fail-fast (state=detected で necessity_judgment optional / state=judged で必須)
- 3 系統対応 + 2 層 source field 明示分離 (A4 apply)
- 1 line per session_id JSONL append-only (A1 grain-correction)
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import jsonschema
import yaml
from jsonschema import Draft202012Validator
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

SCHEMA_NAMES = ["review_case", "finding", "impact_score", "failure_observation", "necessity_judgment"]


def _now_iso() -> str:
  return datetime.now(timezone.utc).isoformat()


def _load_all_schemas(schemas_dir: Path) -> dict[str, dict]:
  return {
    f"{n}.schema.json": json.loads((Path(schemas_dir) / f"{n}.schema.json").read_text(encoding="utf-8"))
    for n in SCHEMA_NAMES
  }


def _make_registry(schemas: dict[str, dict]) -> Registry:
  registry = Registry()
  for uri, schema in schemas.items():
    resource = Resource.from_contents(schema, default_specification=DRAFT202012)
    registry = registry.with_resource(uri=uri, resource=resource)
  return registry


class LogWriter:
  def __init__(self, schemas_dir: Path):
    self._schemas_dir = Path(schemas_dir)
    self._schemas = _load_all_schemas(self._schemas_dir)
    self._registry = _make_registry(self._schemas)
    self._finding_validator = Draft202012Validator(
      self._schemas["finding.schema.json"], registry=self._registry
    )
    self._sessions: dict[str, dict[str, Any]] = {}

  def open(
    self,
    session_id: str,
    treatment: str,
    round_index: int,
    design_md_commit_hash: str,
    target_spec_id: str,
    config_yaml_path: Path,
  ) -> str:
    if treatment not in {"single", "dual", "dual+judgment"}:
      raise ValueError(f"invalid treatment: {treatment}")
    config_yaml_path = Path(config_yaml_path)
    if not config_yaml_path.is_file():
      print(f"config.yaml not found: {config_yaml_path}", file=sys.stderr)
      raise FileNotFoundError(config_yaml_path)
    config = yaml.safe_load(config_yaml_path.read_text(encoding="utf-8"))
    dev_log_path_raw = config.get("dev_log_path", "./dev_log.jsonl")
    dev_log_path = (config_yaml_path.parent / dev_log_path_raw).resolve()
    self._sessions[session_id] = {
      "session_id": session_id,
      "treatment": treatment,
      "round_index": round_index,
      "design_md_commit_hash": design_md_commit_hash,
      "target_spec_id": target_spec_id,
      "phase": "design",
      "timestamp_start": _now_iso(),
      "findings": [],
      "_dev_log_path": dev_log_path,
    }
    return session_id

  def append(self, session_id: str, finding: dict) -> str:
    if session_id not in self._sessions:
      raise KeyError(f"session not opened: {session_id}")
    errors = list(self._finding_validator.iter_errors(finding))
    if errors:
      msg = f"finding {finding.get('issue_id', '?')} validation failed: {[e.message for e in errors]}"
      print(msg, file=sys.stderr)
      raise jsonschema.ValidationError(msg)
    self._sessions[session_id]["findings"].append(finding)
    return finding.get("issue_id", "?")

  def flush(self, session_id: str) -> str:
    if session_id not in self._sessions:
      raise KeyError(f"session not opened: {session_id}")
    state = self._sessions.pop(session_id)
    dev_log_path: Path = state.pop("_dev_log_path")
    review_case = {
      "session_id": state["session_id"],
      "phase": state["phase"],
      "target_spec_id": state["target_spec_id"],
      "timestamp_start": state["timestamp_start"],
      "timestamp_end": _now_iso(),
      "treatment": state["treatment"],
      "round_index": state["round_index"],
      "design_md_commit_hash": state["design_md_commit_hash"],
      "findings": state["findings"],
    }
    with open(dev_log_path, "a", encoding="utf-8") as f:
      f.write(json.dumps(review_case, ensure_ascii=False) + "\n")
    return f"{session_id}:flushed"


def main() -> int:
  parser = argparse.ArgumentParser(description="dr-log session-scoped JSONL log writer (smoke test)")
  parser.add_argument("--schemas-dir", required=True, type=Path)
  args = parser.parse_args()
  try:
    LogWriter(args.schemas_dir)
  except FileNotFoundError:
    return 1
  print(json.dumps({"ready": True, "schemas_loaded": len(SCHEMA_NAMES)}))
  return 0


if __name__ == "__main__":
  sys.exit(main())
