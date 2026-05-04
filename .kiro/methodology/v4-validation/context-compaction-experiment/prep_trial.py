#!/usr/bin/env python3
"""
Context Compaction Experiment - Prep Script

ホスト directory `~/Development/context-compaction-trial/` 配下に
5 段階別 sub-directory を作成し、各 sub-directory に必要 file を配置する。

Usage:
  python3 prep_trial.py --stage all      # 5 stage 全部 prep
  python3 prep_trial.py --stage 0        # 段階 0 (baseline) のみ
  python3 prep_trial.py --stage 1        # 段階 1 (TODO 縮約) のみ
  python3 prep_trial.py --stage 2        # 段階 2 (TODO + memory 縮約) のみ
  python3 prep_trial.py --stage 3        # 段階 3 (= MEMORY.md 2 階層化)
  python3 prep_trial.py --stage 4        # 段階 4 (= subagent pattern 拡張)
  python3 prep_trial.py --check          # template 配置状況 check のみ (= dry run)

prerequisite: templates/stage_{N}_* directory に縮約版 file 配置済
- stage_0 = 現状 file copy (= 自動生成 logic 実装)
- stage_1 = + TODO_TRIAL.md 縮約版 (= 手動起草、本 session で起草)
- stage_2 = + memory/ 縮約版 (= 46th 開始時に手動起草)
- stage_3 = + MEMORY.md 2 階層化 (= 46th 開始時に手動起草)
- stage_4 = + subagent pattern 説明 (= 46th 開始時に手動起草)
"""

import argparse
import shutil
import sys
from pathlib import Path

# ============================================================
# 定数
# ============================================================

REPO = Path('/Users/Daily/Development/Rwiki-dev')
HOST = Path.home() / 'Development' / 'context-compaction-trial'
TEMPLATES = REPO / '.kiro/methodology/v4-validation/context-compaction-experiment/templates'

# target sample = Spec 4 (rwiki-v2-knowledge-graph)
TARGET_SPEC = REPO / '.kiro/specs/rwiki-v2-knowledge-graph'

# dr-design infrastructure
DR_DESIGN_SRC = REPO / 'scripts/dual_reviewer_prototype'

# 段階定義
STAGES = {
  0: 'stage_0_baseline',
  1: 'stage_1_todo',
  2: 'stage_2_todo_memory',
  3: 'stage_3_index',
  4: 'stage_4_subagent',
}

# stage 0 = baseline で copy する source file (= 縮約なし、現状 全量)
BASELINE_FILES = {
  # CLAUDE.md (= user global + project 統合)
  'CLAUDE.md.user': Path.home() / '.claude/CLAUDE.md',
  'CLAUDE.md.project': REPO / 'CLAUDE.md',
  # MEMORY.md
  'MEMORY.md': Path.home() / '.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/MEMORY.md',
  # 必読 memory 7 件
  'memory/feedback_explanation_with_context.md': Path.home() / '.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_explanation_with_context.md',
  'memory/feedback_commit_log_sequencing.md': Path.home() / '.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_commit_log_sequencing.md',
  'memory/project_treatment_design_md_state_policy.md': Path.home() / '.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/project_treatment_design_md_state_policy.md',
  'memory/feedback_review_log_template.md': Path.home() / '.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_review_log_template.md',
  'memory/feedback_response_quality_rules.md': Path.home() / '.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_response_quality_rules.md',
  'memory/feedback_dual_reviewer_monitor_only.md': Path.home() / '.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_dual_reviewer_monitor_only.md',
  'memory/feedback_approval_required.md': Path.home() / '.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_approval_required.md',
}

# 共通 file (= 全 stage で配置)
COMMON_FILES = {
  'target_design.md': TARGET_SPEC / 'design.md',
  'target_requirements.md': TARGET_SPEC / 'requirements.md',
  'dr-design/skill/SKILL.md': DR_DESIGN_SRC / 'skills/dr-design/SKILL.md',
  'dr-design/extensions/design_extension.yaml': DR_DESIGN_SRC / 'extensions/design_extension.yaml',
  'dr-design/prompts/forced_divergence_prompt.txt': DR_DESIGN_SRC / 'prompts/forced_divergence_prompt.txt',
  'dr-design/prompts/judgment_subagent_prompt.txt': DR_DESIGN_SRC / 'prompts/judgment_subagent_prompt.txt',
  'dr-design/patterns/seed_patterns.yaml': DR_DESIGN_SRC / 'patterns/seed_patterns.yaml',
  'dr-design/patterns/fatal_patterns.yaml': DR_DESIGN_SRC / 'patterns/fatal_patterns.yaml',
}

# ============================================================
# helper functions
# ============================================================

def ensure_dir(path: Path):
  path.mkdir(parents=True, exist_ok=True)


def copy_file(src: Path, dst: Path) -> bool:
  if not src.exists():
    return False
  ensure_dir(dst.parent)
  shutil.copy2(src, dst)
  return True


def stage_dir(stage: int) -> Path:
  return HOST / STAGES[stage]


def template_dir(stage: int) -> Path:
  return TEMPLATES / STAGES[stage]


# ============================================================
# stage prep functions
# ============================================================

def prep_stage_0(dry_run=False):
  """stage 0 = baseline = 現状 file の自動 copy (= 縮約なし)"""
  target = stage_dir(0)
  if dry_run:
    print(f'[dry-run] stage 0 -> {target}')
    return
  ensure_dir(target)
  print(f'[stage 0] prep: {target}')

  # baseline file copy
  for relpath, src in BASELINE_FILES.items():
    dst = target / relpath
    if copy_file(src, dst):
      print(f'  copied: {relpath}')
    else:
      print(f'  MISSING: {src} (skip)')

  # TODO_TRIAL.md = TODO_NEXT_SESSION.md from main branch (= 現状 baseline)
  todo_src = REPO / 'TODO_NEXT_SESSION.md'
  if todo_src.exists():
    copy_file(todo_src, target / 'TODO_TRIAL.md')
    print(f'  copied: TODO_TRIAL.md (= TODO_NEXT_SESSION.md baseline)')
  else:
    print(f'  WARN: {todo_src} not found, baseline TODO not configured')

  # 共通 file
  copy_common_files(target)
  write_trial_start(target)
  ensure_dir(target / 'output')
  print(f'  done: {target}')


def prep_stage_n(stage: int, dry_run=False):
  """stage 1-4 = stage_(n-1) baseline + template overlay (= cumulative chain、各 stage 増分のみ template に置く)"""
  target = stage_dir(stage)
  tmpl = template_dir(stage)
  baseline = stage_dir(stage - 1)

  if dry_run:
    print(f'[dry-run] stage {stage} -> {target} (baseline = stage_{stage - 1} + overlay from {tmpl})')
    return

  if not baseline.exists():
    print(f'[stage {stage}] ERROR: stage_{stage - 1} baseline not prepared, run prior stages first')
    return

  if not tmpl.exists():
    print(f'[stage {stage}] SKIP: template not found at {tmpl}')
    print(f'  (= 段階 {stage} の縮約版 file 手動起草が必要)')
    return

  print(f'[stage {stage}] prep: {target}')

  # 1. stage_0 baseline を全 copy (= 既存 target あれば clear)
  if target.exists():
    shutil.rmtree(target)
  shutil.copytree(baseline, target)
  print(f'  baseline copied from {baseline}')

  # 2. template directory 配下で overlay (= 縮約版 file で上書き)
  for src_file in tmpl.rglob('*'):
    if src_file.is_file():
      rel = src_file.relative_to(tmpl)
      dst = target / rel
      ensure_dir(dst.parent)
      shutil.copy2(src_file, dst)
      print(f'  overlay: {rel}')

  ensure_dir(target / 'output')
  print(f'  done: {target}')


def copy_common_files(target: Path):
  """target_design / target_requirements / dr-design 一式 を target に配置"""
  for relpath, src in COMMON_FILES.items():
    dst = target / relpath
    if copy_file(src, dst):
      print(f'  copied common: {relpath}')
    else:
      print(f'  MISSING common: {src} (skip)')


TRIAL_START_CONTENT = '''# TRIAL_START.md (= context compaction experiment 着手指示)

このディレクトリは context compaction experiment の trial directory です。stage 別に context 量を縮約してあり、本 trial の目的は規律発動 quality を 5 trial 比較で測ることです。

## 着手指示

1. `TODO_TRIAL.md` を Read して trial 状態を把握
2. 必要に応じて `memory/` 配下を Read で参照
3. `dr-design/skill/SKILL.md` で V4 protocol 確認
4. `dr-design/extensions/design_extension.yaml` で Round 1 (= 規範範囲確認) 観点確認
5. `target_design.md` (= Spec 4 rwiki-v2-knowledge-graph design.md) と `target_requirements.md` を Read
6. Round 1 review 実施 = treatment=dual pattern (= primary は私が直接、adversarial subagent dispatch、judgment skip)
7. 結果を `output/` に保存:
   - `output/round1_message.md` = Round 提示 user 向け message (= 検出整合 + 判断要請)
   - `output/round1_dev_log.json` = dev_log entry
   - `output/metrics.json` = 6 metric の自動測定値

## 観点

- Round 1 = 規範範囲確認 = spec scope vs design 範囲の整合性、規範範囲先取り検出
- 関連 seed_pattern = phase1_metapattern (a) 規範範囲先取り を中心に照合

## metric

各 trial で以下を取得 (= self-count + 自動測定 + user verify):

1. 規律違反 raw 件数 (= 等号畳み込み + dense academic 文体 + jargon 初出 paraphrase なし)
2. output 文字数 / 検出件数 比
3. user 指摘回数
4. 書き直し回数
5. jargon density (= jargon word / total word)
6. self-evaluation (= 1-10 scale 規律遵守 self-rating)

## stage 識別

trial directory 名で識別 = stage_0_baseline / stage_1_todo / stage_2_todo_memory / stage_3_index / stage_4_subagent。

trial 結果はホスト directory `~/Development/context-compaction-trial/results.md` に集約します (= 5 trial 完了後に user が作成)。
'''


def write_trial_start(target: Path):
  """TRIAL_START.md を target directory 直下に書き出し"""
  dst = target / 'TRIAL_START.md'
  dst.write_text(TRIAL_START_CONTENT, encoding='utf-8')
  print(f'  wrote: TRIAL_START.md')


# ============================================================
# main
# ============================================================

def main():
  parser = argparse.ArgumentParser(description='Context Compaction Experiment Prep')
  parser.add_argument('--stage', default='all', help='stage to prep: all | 0 | 1 | 2 | 3 | 4')
  parser.add_argument('--check', action='store_true', help='dry-run check only')
  args = parser.parse_args()

  print(f'Host directory: {HOST}')
  print(f'Templates dir: {TEMPLATES}')
  print(f'Target spec: {TARGET_SPEC}')
  print()

  if args.stage == 'all':
    stages = [0, 1, 2, 3, 4]
  else:
    try:
      stages = [int(args.stage)]
    except ValueError:
      print(f'ERROR: invalid stage: {args.stage}')
      sys.exit(1)

  ensure_dir(HOST)

  for s in stages:
    if s == 0:
      prep_stage_0(dry_run=args.check)
    else:
      prep_stage_n(s, dry_run=args.check)
    print()

  print('done.')


if __name__ == '__main__':
  main()
