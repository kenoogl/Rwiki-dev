"""Phase 2-A〜D 機械検証 21 Check (Design Review v2)

design_metadata.yaml を入力に、Phase 2-A 構造 / 2-B トレーサビリティ / 2-C 型 / 2-D リスクパターンの
21 Check を実行して findings + scores を返す。LLM 呼出なし、決定論的検査のみ。

Usage:
    python -m design_review_v2.checks <metadata_yaml_path>
"""

from __future__ import annotations

import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal

import yaml


Severity = Literal["ERROR", "WARN", "INFO"]
Phase = Literal["A", "B", "C", "D"]


@dataclass
class Finding:
  phase: Phase
  check_id: str
  severity: Severity
  location: str
  detail: str


@dataclass
class PhaseScore:
  phase: Phase
  total_checks: int
  passed_checks: int
  findings: list[Finding] = field(default_factory=list)

  @property
  def score(self) -> float:
    if self.total_checks == 0:
      return 1.0
    return self.passed_checks / self.total_checks


# ---------- Phase 2-A: 構造チェック ----------

def check_a1_parent_specs(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """A-1: 各 design_unit が parent_specs 非空 (type=interface 以外、ERROR)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    if unit.get("type") == "interface":
      continue
    total += 1
    if unit.get("parent_specs"):
      passed += 1
    else:
      findings.append(Finding(
        phase="A", check_id="A-1", severity="ERROR",
        location=unit["id"],
        detail="parent_specs 空、上位仕様への traceability なし",
      ))
  return total, passed


def check_a2_inputs_outputs(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """A-2: type=component / interface の design_unit が inputs / outputs どちらかが非空 (ERROR)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    if unit.get("type") not in ("component", "interface"):
      continue
    total += 1
    if unit.get("inputs") or unit.get("outputs"):
      passed += 1
    else:
      findings.append(Finding(
        phase="A", check_id="A-2", severity="ERROR",
        location=unit["id"],
        detail="component / interface kind だが inputs / outputs 両方空、API contract 不明",
      ))
  return total, passed


def check_a3_components(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """A-3: 各 design_unit が components 列挙 (上位 type=module は空可、WARN)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    if unit.get("type") == "module":
      continue
    total += 1
    if unit.get("components"):
      passed += 1
    else:
      findings.append(Finding(
        phase="A", check_id="A-3", severity="WARN",
        location=unit["id"],
        detail="components 空、内部構造未列挙",
      ))
  return total, passed


def check_a4_dependencies_resolvable(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """A-4: 各 design_unit の dependencies[].target が他 design_unit / requirements / 標準 lib に解決可能 (ERROR)"""
  unit_ids = {u["id"] for u in metadata.get("design_units", [])}
  req_ids = {r["id"] for r in metadata.get("requirements_index", [])}
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    deps = unit.get("dependencies") or []
    for dep in deps:
      total += 1
      kind = dep.get("kind")
      target = dep.get("target", "")
      # internal: 他 design_unit に解決必要
      if kind == "internal":
        if target in unit_ids:
          passed += 1
        else:
          findings.append(Finding(
            phase="A", check_id="A-4", severity="ERROR",
            location=unit["id"],
            detail=f"internal dependency {target!r} が design_units に未定義",
          ))
      # spec: requirements_index に存在 or 外部 spec への参照は許容
      # external: 外部 lib / system 参照、解決チェック対象外で常に passed
      else:
        passed += 1
  return total, passed


def check_a5_tests(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """A-5: type=component の design_unit が tests 非空 (WARN)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    if unit.get("type") != "component":
      continue
    total += 1
    if unit.get("tests"):
      passed += 1
    else:
      findings.append(Finding(
        phase="A", check_id="A-5", severity="WARN",
        location=unit["id"],
        detail="component だが tests 紐付けなし",
      ))
  return total, passed


def check_a6_extraction_warnings(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """A-6: extraction_warnings 件数 0 (INFO、件数 > 0 で件数 report)"""
  warnings = metadata.get("extraction_warnings") or []
  total, passed = 1, 0
  if not warnings:
    passed = 1
  else:
    findings.append(Finding(
      phase="A", check_id="A-6", severity="INFO",
      location="metadata.extraction_warnings",
      detail=f"extraction_warnings {len(warnings)} 件 (内容: {warnings})",
    ))
  return total, passed


# ---------- Phase 2-B: トレーサビリティチェック ----------

def check_b1_orphan_designs(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """B-1: design_unit.parent_specs[i] が requirements_index に実在 (ERROR、orphan design 検出)"""
  req_ids = {r["id"] for r in metadata.get("requirements_index", [])}
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    for ps in unit.get("parent_specs") or []:
      total += 1
      if ps in req_ids:
        passed += 1
      else:
        findings.append(Finding(
          phase="B", check_id="B-1", severity="ERROR",
          location=unit["id"],
          detail=f"parent_specs {ps!r} が requirements_index に存在しない (orphan design)",
        ))
  return total, passed


def check_b2_uncovered_requirements(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """B-2: requirements_index.id が少なくとも 1 design_unit に implemented_by (ERROR、uncovered 検出)"""
  covered: set[str] = set()
  for unit in metadata.get("design_units", []):
    for ps in unit.get("parent_specs") or []:
      covered.add(ps)

  total, passed = 0, 0
  for req in metadata.get("requirements_index", []):
    rid = req["id"]
    total += 1
    if rid in covered:
      passed += 1
    else:
      findings.append(Finding(
        phase="B", check_id="B-2", severity="ERROR",
        location=f"requirement.{rid}",
        detail=f"requirement {rid} が design_unit からの implemented_by を持たない (uncovered)",
      ))
  return total, passed


def check_b3_uncovered_designs(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """B-3: design_unit が少なくとも 1 test に紐付け (WARN、uncovered design 検出)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    total += 1
    if unit.get("tests"):
      passed += 1
    else:
      findings.append(Finding(
        phase="B", check_id="B-3", severity="WARN",
        location=unit["id"],
        detail="design_unit に test 紐付けなし (uncovered design)",
      ))
  return total, passed


def check_b4_orphan_tasks(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """B-4: tasks_index がある場合、task.parent_design が design_unit に実在 (ERROR、orphan task)"""
  tasks = metadata.get("tasks_index") or []
  if not tasks:
    return 0, 0
  unit_ids = {u["id"] for u in metadata.get("design_units", [])}
  total, passed = 0, 0
  for task in tasks:
    total += 1
    pd = task.get("parent_design")
    if pd and pd in unit_ids:
      passed += 1
    else:
      findings.append(Finding(
        phase="B", check_id="B-4", severity="ERROR",
        location=task.get("id", "<unknown>"),
        detail=f"task parent_design {pd!r} が design_unit に未定義 (orphan task)",
      ))
  return total, passed


def check_b5_task_tests(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """B-5: tasks_index がある場合、task.tests 非空 (ERROR、verification 経路欠落)"""
  tasks = metadata.get("tasks_index") or []
  if not tasks:
    return 0, 0
  total, passed = 0, 0
  for task in tasks:
    total += 1
    if task.get("tests"):
      passed += 1
    else:
      findings.append(Finding(
        phase="B", check_id="B-5", severity="ERROR",
        location=task.get("id", "<unknown>"),
        detail="task tests 空、verification 経路なし",
      ))
  return total, passed


def check_b6_chain_connectivity(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """B-6: cross_references の連結性 (Spec → Design → Task → Test chain) (WARN)

  本 check は spec → design 連結 (cross_references implements 関係) のみを検査する。
  task → test 連結は B-5 でカバー済。
  """
  refs = metadata.get("cross_references") or []
  unit_ids = {u["id"] for u in metadata.get("design_units", [])}
  req_ids = {r["id"] for r in metadata.get("requirements_index", [])}

  # implements 関係のみ抽出
  implements_refs = [r for r in refs if r.get("relation") == "implements"]
  total, passed = 0, 0
  for ref in implements_refs:
    total += 1
    from_id = ref.get("from", "")
    to_id = ref.get("to", "")
    # design.* → requirement の implements 関係を期待
    if from_id in unit_ids and to_id in req_ids:
      passed += 1
    elif from_id.startswith("design.") and to_id in req_ids:
      passed += 1
    else:
      findings.append(Finding(
        phase="B", check_id="B-6", severity="WARN",
        location=f"{from_id} -> {to_id}",
        detail=f"cross_reference implements 関係の連結性が未確立 (from / to のいずれかが未解決)",
      ))
  return total, passed


# ---------- Phase 2-C: 型チェック ----------

ALLOWED_RELATIONS: set[tuple[str, str, str]] = {
  ("Design", "implements", "Spec"),
  ("Task", "implements", "Design"),
  ("Test", "verifies", "Spec"),
  ("Test", "verifies", "Task"),
  ("Design", "depends_on", "Design"),
  ("Design", "depends_on", "Spec"),
  ("Task", "depends_on", "Task"),
}


def _classify_kind(node_id: str, metadata: dict) -> str:
  """node_id から kind (Design / Task / Test / Spec) を分類する."""
  unit_ids = {u["id"] for u in metadata.get("design_units", [])}
  req_ids = {r["id"] for r in metadata.get("requirements_index", [])}
  task_ids = {t["id"] for t in metadata.get("tasks_index") or []}

  if node_id in unit_ids or node_id.startswith("design."):
    return "Design"
  if node_id in task_ids or node_id.startswith("task."):
    return "Task"
  if node_id.startswith("test."):
    return "Test"
  if node_id in req_ids:
    return "Spec"
  return "Unknown"


def check_c1_relation_types(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """C-1: cross_references 各 (from_kind, relation, to_kind) が ALLOWED_RELATIONS に含まれる (ERROR)"""
  refs = metadata.get("cross_references") or []
  total, passed = 0, 0
  for ref in refs:
    total += 1
    from_kind = _classify_kind(ref.get("from", ""), metadata)
    to_kind = _classify_kind(ref.get("to", ""), metadata)
    relation = ref.get("relation", "")
    triple = (from_kind, relation, to_kind)
    if triple in ALLOWED_RELATIONS:
      passed += 1
    else:
      findings.append(Finding(
        phase="C", check_id="C-1", severity="ERROR",
        location=f"{ref.get('from')} -> {ref.get('to')}",
        detail=f"不正関係 {triple} (許容: {sorted(ALLOWED_RELATIONS)})",
      ))
  return total, passed


def check_c2_spec_not_decomposed(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """C-2: Spec → Design / Task / Test の関係が implements / verifies であって、decomposed_into でない (ERROR)"""
  refs = metadata.get("cross_references") or []
  total, passed = 0, 0
  for ref in refs:
    relation = ref.get("relation", "")
    if relation != "decomposed_into":
      continue
    from_kind = _classify_kind(ref.get("from", ""), metadata)
    total += 1
    if from_kind == "Spec":
      findings.append(Finding(
        phase="C", check_id="C-2", severity="ERROR",
        location=f"{ref.get('from')} -> {ref.get('to')}",
        detail="Spec が decomposed_into 関係を持つ (Spec 自身は分解されない)",
      ))
    else:
      passed += 1
  return total, passed


def check_c3_test_not_to_design(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """C-3: Test → Design は不正 (Test は Spec / Task のみ verifies、ERROR)"""
  refs = metadata.get("cross_references") or []
  total, passed = 0, 0
  for ref in refs:
    relation = ref.get("relation", "")
    if relation != "verifies":
      continue
    from_kind = _classify_kind(ref.get("from", ""), metadata)
    to_kind = _classify_kind(ref.get("to", ""), metadata)
    if from_kind != "Test":
      continue
    total += 1
    if to_kind == "Design":
      findings.append(Finding(
        phase="C", check_id="C-3", severity="ERROR",
        location=f"{ref.get('from')} -> {ref.get('to')}",
        detail="Test が Design を verifies (Test は Spec / Task のみ verifies)",
      ))
    else:
      passed += 1
  return total, passed


# ---------- Phase 2-D: リスクパターンチェック ----------

def check_d1_responsibilities_overload(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """D-1: 単一 design_unit の responsibilities 配列長 >= 3 (WARN、責務過剰)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    total += 1
    resp = unit.get("responsibilities") or []
    if len(resp) >= 3:
      findings.append(Finding(
        phase="D", check_id="D-1", severity="WARN",
        location=unit["id"],
        detail=f"responsibilities 配列長 {len(resp)} (>= 3、責務過剰の可能性)",
      ))
    else:
      passed += 1
  return total, passed


def check_d2_inputs_without_outputs(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """D-2: inputs 非空かつ outputs 空 (WARN、出力なし)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    total += 1
    if (unit.get("inputs") or []) and not (unit.get("outputs") or []):
      findings.append(Finding(
        phase="D", check_id="D-2", severity="WARN",
        location=unit["id"],
        detail="inputs 非空だが outputs 空、副作用のみ?",
      ))
    else:
      passed += 1
  return total, passed


def check_d3_state_change_without_rollback(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """D-3: state_change == true かつ rollback_defined == false (ERROR)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    total += 1
    if unit.get("state_change") and not unit.get("rollback_defined"):
      findings.append(Finding(
        phase="D", check_id="D-3", severity="ERROR",
        location=unit["id"],
        detail="state_change=true だが rollback_defined=false (rollback 経路欠落)",
      ))
    else:
      passed += 1
  return total, passed


def check_d4_external_dep_without_failure_modes(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """D-4: dependencies[].kind == 'external' を持つが failure_modes 空 (ERROR)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    total += 1
    deps = unit.get("dependencies") or []
    has_external = any(d.get("kind") == "external" for d in deps)
    if has_external and not (unit.get("failure_modes") or []):
      findings.append(Finding(
        phase="D", check_id="D-4", severity="ERROR",
        location=unit["id"],
        detail="external dependency あり (kind=external) だが failure_modes 空",
      ))
    else:
      passed += 1
  return total, passed


def check_d5_llm_without_confidence(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """D-5: llm_judgment == true かつ llm_confidence_or_escalation == false (ERROR)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    total += 1
    if unit.get("llm_judgment") and not unit.get("llm_confidence_or_escalation"):
      findings.append(Finding(
        phase="D", check_id="D-5", severity="ERROR",
        location=unit["id"],
        detail="llm_judgment=true だが llm_confidence_or_escalation=false (confidence / escalation 設計欠落)",
      ))
    else:
      passed += 1
  return total, passed


def check_d6_auto_approval_without_human_gate(metadata: dict, findings: list[Finding]) -> tuple[int, int]:
  """D-6: auto_approval == true かつ human_gate == false (ERROR)"""
  total, passed = 0, 0
  for unit in metadata.get("design_units", []):
    total += 1
    if unit.get("auto_approval") and not unit.get("human_gate"):
      findings.append(Finding(
        phase="D", check_id="D-6", severity="ERROR",
        location=unit["id"],
        detail="auto_approval=true だが human_gate=false (人間判断 gate 欠落)",
      ))
    else:
      passed += 1
  return total, passed


# ---------- Phase 集約 ----------

PHASE_A_CHECKS = [
  check_a1_parent_specs, check_a2_inputs_outputs, check_a3_components,
  check_a4_dependencies_resolvable, check_a5_tests, check_a6_extraction_warnings,
]
PHASE_B_CHECKS = [
  check_b1_orphan_designs, check_b2_uncovered_requirements, check_b3_uncovered_designs,
  check_b4_orphan_tasks, check_b5_task_tests, check_b6_chain_connectivity,
]
PHASE_C_CHECKS = [
  check_c1_relation_types, check_c2_spec_not_decomposed, check_c3_test_not_to_design,
]
PHASE_D_CHECKS = [
  check_d1_responsibilities_overload, check_d2_inputs_without_outputs,
  check_d3_state_change_without_rollback, check_d4_external_dep_without_failure_modes,
  check_d5_llm_without_confidence, check_d6_auto_approval_without_human_gate,
]


def run_phase(phase: Phase, checks: list, metadata: dict) -> PhaseScore:
  findings: list[Finding] = []
  total, passed = 0, 0
  for check in checks:
    t, p = check(metadata, findings)
    total += t
    passed += p
  return PhaseScore(phase=phase, total_checks=total, passed_checks=passed, findings=findings)


def run_all_checks(metadata: dict) -> dict[Phase, PhaseScore]:
  return {
    "A": run_phase("A", PHASE_A_CHECKS, metadata),
    "B": run_phase("B", PHASE_B_CHECKS, metadata),
    "C": run_phase("C", PHASE_C_CHECKS, metadata),
    "D": run_phase("D", PHASE_D_CHECKS, metadata),
  }


def main(metadata_path: str) -> None:
  with open(metadata_path) as f:
    metadata = yaml.safe_load(f)

  scores = run_all_checks(metadata)

  # human-readable report
  print(f"=== Design Review v2 Phase 2-A〜D ({metadata.get('feature_name')}) ===\n")
  for phase, score in scores.items():
    print(f"[Phase 2-{phase}] {score.passed_checks}/{score.total_checks} = {score.score:.3f}")
    for f in score.findings:
      print(f"  {f.severity:5s} {f.check_id} {f.location}")
      print(f"        {f.detail}")
    print()

  # YAML output
  output = {
    "feature_name": metadata.get("feature_name"),
    "phase_results": {
      f"phase_{p.lower()}": {
        "total_checks": scores[p].total_checks,
        "passed_checks": scores[p].passed_checks,
        "score": round(scores[p].score, 4),
        "findings": [
          {
            "phase": f.phase, "check_id": f.check_id, "severity": f.severity,
            "location": f.location, "detail": f.detail,
          }
          for f in scores[p].findings
        ],
      }
      for p in ("A", "B", "C", "D")
    },
  }
  out_path = Path(metadata_path).parent / "phase2_findings.yaml"
  with open(out_path, "w") as f:
    yaml.safe_dump(output, f, allow_unicode=True, sort_keys=False)
  print(f"\nfindings written to: {out_path}")


if __name__ == "__main__":
  if len(sys.argv) != 2:
    print("Usage: python checks.py <metadata_yaml_path>", file=sys.stderr)
    sys.exit(2)
  main(sys.argv[1])
