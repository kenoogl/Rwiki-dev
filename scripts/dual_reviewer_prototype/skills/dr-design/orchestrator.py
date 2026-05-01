"""dr-design skill: design phase orchestrator helper script.

Service Interface (design.md §dr-design Skill):
- Layer 1/2 yaml load (foundation framework + 本 spec extension)
- Round 1-10 sequential iteration helper
- 5 重検査 (Step 1b) checklist generator
- foundation patterns yaml load (seed + fatal)
- 本 spec forced_divergence prompt load
- target design.md git commit hash 取得 (subprocess `git rev-parse`)
- adversarial counter_evidence decompose (issue_id 単位)
- treatment 3 系統 切替 helper

Responsibilities (P4 + A3 fix 整合):
- 担う: yaml load + helpers (path resolution / 5 重検査 / commit hash / counter_evidence decompose / treatment switch)
- 担わない: adversarial subagent dispatch 本体 (= Claude assistant が SKILL.md instructions に従って Agent tool 経由実行)
- 担わない: V4 §1.5 fix-negation prompt の Python 側 file read / regex extract (= SKILL.md inline 配置のみ)

Out of scope:
- judgment subagent dispatch (dr-judgment skill 責務、本 helper は invoke 結果を merge するのみ)
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Iterator

import yaml

# Step 1b 5 重検査 layer 名 (固定 list、Layer 2 から動的化は B-1.x)
STEP_1B_5_LAYER_CHECKLIST = [
  "二重逆算 (双方向 trace = 仕様 → 設計 + 設計 → 仕様)",
  "Phase 1 パターンマッチング (foundation seed_patterns + Layer 3 extracted_patterns + Layer 2 phase1_metapatterns 3 件)",
  "dev-log patterns 照合 (foundation seed_patterns 23 件 + Layer 3 extracted_patterns 二層)",
  "自己診断 (primary 自己 evaluation)",
  "内部論理整合 (design 内 cross-reference + dependency)",
]


def resolve_foundation_path(base_root: Path | str, relative: str) -> Path:
  """Resolve `./` prefix relative path against foundation install location."""
  base = Path(base_root)
  rel = relative.lstrip("./")
  return base / rel


def load_frameworks(dual_reviewer_root: Path) -> tuple[dict, dict]:
  """foundation Layer 1 + 本 spec Layer 2 yaml を起動時動的 read (Req 5.1)."""
  base = Path(dual_reviewer_root)
  layer1_path = base / "framework" / "layer1_framework.yaml"
  layer2_path = base / "extensions" / "design_extension.yaml"
  if not layer1_path.is_file():
    raise FileNotFoundError(layer1_path)
  if not layer2_path.is_file():
    raise FileNotFoundError(layer2_path)
  layer1 = yaml.safe_load(layer1_path.read_text(encoding="utf-8"))
  layer2 = yaml.safe_load(layer2_path.read_text(encoding="utf-8"))
  return layer1, layer2


def iterate_rounds(layer2: dict) -> Iterator[dict]:
  """Layer 2 extension yaml の rounds list (10 件) を round_index 1-10 順に yield."""
  rounds = layer2.get("rounds", [])
  rounds_sorted = sorted(rounds, key=lambda r: r["round_index"])
  yield from rounds_sorted


def step_1b_5_layer_checklist(layer2: dict) -> list[str]:
  """Step 1b 5 重検査 layer 名 list を返す (5 件 = 二重逆算 / Phase 1 / dev-log / 自己診断 / 内部論理整合)."""
  return list(STEP_1B_5_LAYER_CHECKLIST)


def load_forced_divergence_prompt(dual_reviewer_root: Path) -> str:
  """本 spec ./prompts/forced_divergence_prompt.txt 動的 read (Req 6.4)."""
  path = Path(dual_reviewer_root) / "prompts" / "forced_divergence_prompt.txt"
  if not path.is_file():
    raise FileNotFoundError(path)
  return path.read_text(encoding="utf-8")


def load_fatal_patterns(dual_reviewer_root: Path) -> list[dict]:
  """foundation ./patterns/fatal_patterns.yaml 8 種 enum 動的読込 (Req 5.4)."""
  path = Path(dual_reviewer_root) / "patterns" / "fatal_patterns.yaml"
  if not path.is_file():
    raise FileNotFoundError(path)
  data = yaml.safe_load(path.read_text(encoding="utf-8"))
  return data.get("patterns", [])


def load_seed_patterns(dual_reviewer_root: Path) -> dict:
  """foundation ./patterns/seed_patterns.yaml の version + patterns 動的読込 (Req 5.3)."""
  path = Path(dual_reviewer_root) / "patterns" / "seed_patterns.yaml"
  if not path.is_file():
    raise FileNotFoundError(path)
  return yaml.safe_load(path.read_text(encoding="utf-8"))


def get_design_md_commit_hash(target_design_md_path: Path, target_project_root: Path) -> str:
  """target design.md の git commit hash を取得 (A2 fix、reproducibility)."""
  result = subprocess.run(
    ["git", "rev-parse", "HEAD", "--", str(target_design_md_path)],
    cwd=target_project_root, capture_output=True, text=True,
  )
  if result.returncode != 0:
    return ""
  return result.stdout.strip()


def decompose_counter_evidence(adversarial_yaml_str: str) -> dict[str, str]:
  """adversarial 出力 yaml の counter_evidence section を issue_id 単位 dict に decompose (A6 fix)."""
  data = yaml.safe_load(adversarial_yaml_str)
  if not isinstance(data, dict):
    return {}
  counter_list = data.get("counter_evidence", [])
  result: dict[str, str] = {}
  for entry in counter_list:
    issue_id = entry.get("issue_id")
    argument = entry.get("argument", "")
    if issue_id:
      result[issue_id] = argument
  return result


def treatment_step_skip_logic(treatment: str) -> dict[str, bool]:
  """3 系統 treatment 切替 helper. Return: {step_b: skip?, step_c: skip?}.

  - single: skip Step B + Step C
  - dual: exec Step B, skip Step C
  - dual+judgment: exec Step B + Step C
  """
  if treatment == "single":
    return {"step_b": True, "step_c": True}
  if treatment == "dual":
    return {"step_b": False, "step_c": True}
  if treatment == "dual+judgment":
    return {"step_b": False, "step_c": False}
  raise ValueError(f"invalid treatment: {treatment}")


def main() -> int:
  parser = argparse.ArgumentParser(description="dr-design orchestrator (smoke test)")
  parser.add_argument("--target-design-md", required=False, type=Path)
  parser.add_argument("--dual-reviewer-root", required=True, type=Path)
  parser.add_argument("--config-yaml-path", required=False, type=Path)
  parser.add_argument("--treatment", required=False, default="dual+judgment",
                      choices=["single", "dual", "dual+judgment"])
  args = parser.parse_args()

  # smoke test mode: layer 1/2 load + ready stdout
  try:
    layer1, layer2 = load_frameworks(args.dual_reviewer_root)
  except FileNotFoundError as e:
    print(f"framework yaml not found: {e}", file=sys.stderr)
    return 1

  rounds_count = len(list(iterate_rounds(layer2)))
  output = {
    "ready": True,
    "treatment": args.treatment,
    "rounds": rounds_count,
    "layer1_version": layer1.get("version"),
    "layer2_version": layer2.get("version"),
  }
  print(json.dumps(output))
  return 0


if __name__ == "__main__":
  sys.exit(main())
