# MIGRATION_MANIFEST

## Purpose

旧 `Rwiki-dev` から `dual-reviewer-rebuild` へ何を移植するかを固定する。移植時に迷いを減らし、不要な artifact 混入を防ぐ。

## Carry Over

### foundation inputs

- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-foundation/`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/framework/layer1_framework.yaml`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/schemas/review_case.schema.json`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/schemas/finding.schema.json`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/schemas/impact_score.schema.json`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/schemas/failure_observation.schema.json`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/schemas/necessity_judgment.schema.json`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/patterns/seed_patterns.yaml`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/patterns/fatal_patterns.yaml`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/prompts/judgment_subagent_prompt.txt`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/config/config.yaml.template`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/terminology/terminology.yaml.template`

### runtime inputs

- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-design-review/`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/skills/dr-init/`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/skills/dr-design/`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/skills/dr-log/`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/skills/dr-judgment/`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/extensions/design_extension.yaml`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_prototype/prompts/forced_divergence_prompt.txt`

### evaluation inputs

- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-dogfeeding/`
- `/Users/Daily/Development/Rwiki-dev/scripts/dual_reviewer_dogfeeding/`
- `/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/data-acquisition-plan.md`

### paper-interface and self-improvement references

- `/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/paper-submission-plan.md`
- `/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/preliminary-paper-report.md`
- `/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/evidence-catalog.md`
- `/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/comparison-report.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-1.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-2.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-3.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-4.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-5.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-6.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-7.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-8.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-9.md`
- `/Users/Daily/Development/Rwiki-dev/docs/dual-reviewer-log-10.md`
- `/Users/Daily/Development/Rwiki-dev/docs/レビューシステム検討.md`
- `/Users/Daily/Development/Rwiki-dev/docs/過剰修正バイアス.md`

## Reference Only

- 既存 `Rwiki` 本体 spec 群
- 既存論文化 narrative の readiness 判定
- 既存 comparison の達成主張

扱い:

- 新 repo へ全文コピーしない
- 必要箇所だけ再定義する

## Do Not Carry Over

- repo 外 memory 依存
- transcript JSONL に依存した運用知識
- 旧 run の達成判定をそのまま正とすること
- invalidation 条件が曖昧な既存 data を runtime contract に直接混ぜること

## Migration Order

1. foundation assets
2. runtime assets
3. evaluation assets
4. self-improvement references
5. paper-interface references
