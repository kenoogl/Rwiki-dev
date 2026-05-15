# DOCUMENT_INDEX

## 1. 目的

この文書は、`dual-reviewer-rebuild` 内で生成・管理される文書と主要 artifact の index である。

目的は次の 3 つ。

- どの文書が何のために存在するかを一目で分かるようにする
- どの文書が正本で、どの文書が補助資料かを区別する
- multi-feature 開発で文書追加が進んでも、所在と更新責務を見失わないようにする

この repo では文書が多層に増えるため、新しい文書を追加した場合は原則として本 index も更新する。

## 2. 文書階層

この repo の文書階層は次の順で読む。

1. `intent/`
2. `operations/`
3. top-level contract documents
4. `.kiro/steering/`
5. `.kiro/specs/`
6. `docs/`
7. 実装・実験・学習・論文化 artifact

意味:

- 上にあるほど「なぜ」「どう使うか」に近い
- 下にあるほど「どう作るか」「どう測るか」「何が起きたか」に近い

## 3. ルート文書

| Path | Role | Status |
|------|------|--------|
| [README.md](README.md) | repo 全体の入口 | overview |
| [DOCUMENT_INDEX.md](DOCUMENT_INDEX.md) | 文書・artifact の所在管理 index | authoritative index |
| [CLAUDE.md](CLAUDE.md) | 開発作業時の運用メモ | working guidance |
| [CONVENTIONS.md](CONVENTIONS.md) | status / 用語 / naming / レビュー 3 役の共通規約 | top-level contract |
| [SYSTEM_BOUNDARY.md](SYSTEM_BOUNDARY.md) | system の in/out scope | top-level contract |
| [REPRODUCIBILITY_CONTRACT.md](REPRODUCIBILITY_CONTRACT.md) | 再現性条件 | top-level contract |
| [EVIDENCE_PROTOCOL.md](EVIDENCE_PROTOCOL.md) | evidence の扱い規約 | top-level contract |
| [SELF_IMPROVEMENT_LOOP.md](SELF_IMPROVEMENT_LOOP.md) | 改善 loop の上位定義 | top-level contract |
| [PAPER_WORK_BREAKDOWN.md](PAPER_WORK_BREAKDOWN.md) | 論文化作業の分解 | planning reference |
| [MIGRATION_MANIFEST.md](MIGRATION_MANIFEST.md) | 旧 repo からの移植対象一覧 | migration authority |

## 4. `intent/`

`intent/` は「なぜこの system を作るか」の層であり、spec より上位の正本である。

| Path | Role | Status |
|------|------|--------|
| [intent/INTENT.md](intent/INTENT.md) | 再構築の目的と価値命題 | authoritative |
| [intent/NON_GOALS.md](intent/NON_GOALS.md) | 今回やらないことの明示 | authoritative |
| [intent/DESIGN_PRINCIPLES.md](intent/DESIGN_PRINCIPLES.md) | 設計原則 | authoritative |
| [intent/TRACEABILITY.md](intent/TRACEABILITY.md) | intent から spec / artifact への接続 | authoritative |

補足:

- phase-specific effectiveness metrics の価値命題は `intent/INTENT.md`
- 具体定義は `dual-reviewer-evaluation` spec
を正本とする
- `dual-reviewer` 方法論を本 repo 自身へ手動適用する方針も `intent/INTENT.md` と `operations/HUMAN_WORKFLOW.md` を正本とする

## 5. `operations/`

`operations/` は「どう使い、何を信頼し、どう無効化するか」の層である。

| Path | Role | Status |
|------|------|--------|
| [operations/DEPLOYMENT_MODEL.md](operations/DEPLOYMENT_MODEL.md) | deploy 形態の固定 | authoritative |
| [operations/TRUST_BOUNDARY.md](operations/TRUST_BOUNDARY.md) | LLM / validator / human の責務境界 | authoritative |
| [operations/HUMAN_WORKFLOW.md](operations/HUMAN_WORKFLOW.md) | 開発・運用 workflow | authoritative |
| [operations/DATA_INVALIDATION_POLICY.md](operations/DATA_INVALIDATION_POLICY.md) | valid / invalid / exploratory の扱い | authoritative |

補足:

- review の進め方も `operations/HUMAN_WORKFLOW.md` が正本であり、`intent -> requirements -> design -> tasks` の段階的かつ水平的な wave を採る

## 6. `.kiro/steering/`

意図駆動ワークフロー全体にかかる共通 steering。

| Path | Role | Status |
|------|------|--------|
| [product.md](.kiro/steering/product.md) | product steering | steering |
| [tech.md](.kiro/steering/tech.md) | technical steering | steering |
| [structure.md](.kiro/steering/structure.md) | repo structure steering | steering |

## 7. `.kiro/specs/`

ここが意図駆動ワークフローの feature 正本である。各 spec は `brief -> requirements -> design -> tasks` の順に整備する。

### 7.1 feature 一覧

| Feature | Purpose | Current note |
|---------|---------|--------------|
| `dual-reviewer-foundation` | 共通 contract と shared asset layer | tasks approved |
| `dual-reviewer-runtime` | review orchestration | tasks approved |
| `dual-reviewer-evaluation` | valid/invalid 分離と metrics | tasks approved |
| `dual-reviewer-paper-interface` | paper-facing export | tasks approved |
| `dual-reviewer-self-improvement` | evidence-driven improvement loop | tasks approved |
| `dual-reviewer-implementation-governance` | implementation completion rule と conformance review governance | tasks approved |

### 7.2 spec 内ファイルの意味

各 feature directory には次の文書がある。

| File | Role |
|------|------|
| `brief.md` | feature の短い導入 |
| `research.md` | 調査メモや参考知見 |
| `requirements.md` | feature contract の正本 |
| `design.md` | feature 設計の正本 |
| `tasks.md` | 実装・移植タスクの正本 |
| `spec.json` | 意図駆動ワークフロー管理用メタデータ |

### 7.3 spec 主要ファイルリンク

| Feature | Requirements | Design | Tasks |
|---------|--------------|--------|-------|
| foundation | [requirements.md](.kiro/specs/dual-reviewer-foundation/requirements.md) | [design.md](.kiro/specs/dual-reviewer-foundation/design.md) | [tasks.md](.kiro/specs/dual-reviewer-foundation/tasks.md) |
| runtime | [requirements.md](.kiro/specs/dual-reviewer-runtime/requirements.md) | [design.md](.kiro/specs/dual-reviewer-runtime/design.md) | [tasks.md](.kiro/specs/dual-reviewer-runtime/tasks.md) |
| evaluation | [requirements.md](.kiro/specs/dual-reviewer-evaluation/requirements.md) | [design.md](.kiro/specs/dual-reviewer-evaluation/design.md) | [tasks.md](.kiro/specs/dual-reviewer-evaluation/tasks.md) |
| paper-interface | [requirements.md](.kiro/specs/dual-reviewer-paper-interface/requirements.md) | [design.md](.kiro/specs/dual-reviewer-paper-interface/design.md) | [tasks.md](.kiro/specs/dual-reviewer-paper-interface/tasks.md) |
| self-improvement | [requirements.md](.kiro/specs/dual-reviewer-self-improvement/requirements.md) | [design.md](.kiro/specs/dual-reviewer-self-improvement/design.md) | [tasks.md](.kiro/specs/dual-reviewer-self-improvement/tasks.md) |
| implementation-governance | [requirements.md](.kiro/specs/dual-reviewer-implementation-governance/requirements.md) | [design.md](.kiro/specs/dual-reviewer-implementation-governance/design.md) | [tasks.md](.kiro/specs/dual-reviewer-implementation-governance/tasks.md) |

## 8. `docs/`

`docs/` は spec 正本ではなく、横断判断や棚卸しの補助資料を置く。

### 8.1 `docs/alignment/`

| Path | Role | Status |
|------|------|--------|
| [cross-spec-requirements-alignment.md](docs/alignment/cross-spec-requirements-alignment.md) | requirements wave の横断整合メモ | alignment memo |
| [cross-spec-design-alignment.md](docs/alignment/cross-spec-design-alignment.md) | design wave の横断整合メモ | alignment memo |
| [cross-spec-tasks-alignment.md](docs/alignment/cross-spec-tasks-alignment.md) | tasks wave の横断整合メモ | alignment memo |
| [cross-spec-implementation-governance-alignment.md](docs/alignment/cross-spec-implementation-governance-alignment.md) | implementation-governance 導入時の横断整合メモ | alignment memo |
| [phase-and-feature-dependency-map.md](docs/alignment/phase-and-feature-dependency-map.md) | phase 間・feature 間依存と進行順の正本補助 | alignment memo |

`cross-spec-design-alignment.md` には design 修正時の reopen procedure を含める。

### 8.2 `docs/coordination/`

| Path | Role | Status |
|------|------|--------|
| [implementation-coordination-log.md](docs/coordination/implementation-coordination-log.md) | implementation 中の横断調整ログ | coordination log |
| [implementation-signal-register.md](docs/coordination/implementation-signal-register.md) | implementation 中の軽微な兆候・未確定リスクの台帳 | signal register |
| [implementation-conformance-review.md](docs/coordination/implementation-conformance-review.md) | prototype 実装後の仕様準拠性・境界条件・証跡性 review 工程定義 | review procedure |
| [implementation-conformance-metric-register.md](docs/coordination/implementation-conformance-metric-register.md) | conformance review を測る metric 定義台帳 | metric register |
| [phase-review-metric-register.md](docs/coordination/phase-review-metric-register.md) | `intent` から `implementation` までの phase friction / handback / recheck を測る metric 定義台帳 | metric register |
| [workflow-gate-status.md](docs/coordination/workflow-gate-status.md) | 現在どの workflow gate まで通過したかの状態台帳 | gate status register |
| [workflow-repair-procedure.md](docs/coordination/workflow-repair-procedure.md) | `A/B/C/D` handback と gate 再実施の修正手続き一覧と状態遷移表 | workflow repair procedure |

### 8.3 `docs/reviews/`

| Path | Role | Status |
|------|------|--------|
| [2026-05-09-intent-baseline-review.md](docs/reviews/2026-05-09-intent-baseline-review.md) | v1 baseline 時点の intent review artifact | review artifact |
| [2026-05-09-prototype-shelf-review.md](docs/reviews/2026-05-09-prototype-shelf-review.md) | prototype 一巡後の implementation conformance review artifact | review artifact |
| [2026-05-09-prototype-shelf-review-rerun.md](docs/reviews/2026-05-09-prototype-shelf-review-rerun.md) | open finding 修正後の conformance review short rerun artifact | review artifact |
| [templates/implementation-conformance-review-template.md](docs/reviews/templates/implementation-conformance-review-template.md) | conformance review artifact の再利用 template | review template |
| [templates/intent-review-template.md](docs/reviews/templates/intent-review-template.md) | intent review artifact の再利用 template | review template |

### 8.4 `docs/reports/`

| Path | Role | Status |
|------|------|--------|
| [dual-reviewer-v1-completion-report.md](docs/reports/dual-reviewer-v1-completion-report.md) | dual-reviewer v1 の完成報告と review/evidence の要約 | completion report |

### 8.5 `docs/guides/`

| Path | Role | Status |
|------|------|--------|
| [dual-reviewer-v2-user-guide.md](docs/guides/dual-reviewer-v2-user-guide.md) | dual-reviewer v2 の全体像、使い方、判断ポイントをまとめた利用者向けガイド | current user guide |
| [dual-reviewer-v1-user-guide.md](docs/guides/dual-reviewer-v1-user-guide.md) | dual-reviewer v1 の目的と使い方をまとめた参照用ガイド | legacy reference |

### 8.6 `docs/traceability/`

| Path | Role | Status |
|------|------|--------|
| [intent-to-requirements-trace-matrix.md](docs/traceability/intent-to-requirements-trace-matrix.md) | intent 命題と feature requirements の対応表 | traceability matrix |

### 8.7 `docs/migration/`

| Path | Role | Status |
|------|------|--------|
| [feature-disposition-judgment.md](docs/migration/feature-disposition-judgment.md) | 旧機能の keep/reshape/drop 判定表 | migration memo |

### 8.8 `docs/legacy/`

| Path | Role | Status |
|------|------|--------|
| [legacy-discussion-carryover.md](docs/legacy/legacy-discussion-carryover.md) | 初期議論から継承する論点の整理 | legacy reference |

## 9. Artifact Directory Index

以下は現時点では mostly skeleton だが、今後の実装・実験・学習で主要な置き場になる。

| Path | Expected contents | Status |
|------|-------------------|--------|
| [runtime/](runtime) | prompts / schemas / validators / config / runtime assets | shared asset layer |
| [experiments/](experiments) | protocols / runs / analysis / fixtures | experiment workspace |
| [learning/](learning) | findings / proposals / backtests / approved-updates / rejected-updates / rollback | self-improvement workspace |
| [paper/](paper) | reports / tables / figures / caveats | paper-facing workspace |
| [scripts/](scripts) | utility scripts | implementation workspace |
| [tests/](tests) | repo-level tests | validation workspace |
| [reviews/manual/](reviews/manual) | manual dogfooding review records, templates, and aggregate summaries | manual review workspace |

## 10. 正本と参考資料の区別

### 正本

- `intent/`
- `operations/`
- top-level contract documents
- `.kiro/steering/`
- `.kiro/specs/*/requirements.md`
- `.kiro/specs/*/design.md`
- `.kiro/specs/*/tasks.md`
- `.kiro/specs/*/spec.json` for status and phase state

### 補助資料

- `docs/`
- `brief.md`
- `research.md`
- 将来の analysis notes

判断に迷った場合は、補助資料ではなく正本を優先する。

## 11. 更新ルール

1. 新しい上位文書を追加したら本 index に追加する
2. 新しい feature spec を追加したら `7.1` と `7.3` を更新する
3. `docs/` に alignment memo や棚卸し資料を追加したら `8` を更新する
4. 主要 artifact directory の役割が変わったら `9` を更新する
5. `status` 列は説明用 overview として追随させてよいが、正本は `spec.json` とする
6. `intent -> requirements` の trace matrix を追加した場合は `4` または `8` の関連項目に追記し、更新トリガーの所在も明示する

## 12. 次に読むべき順序

新規参加者向けの推奨順序は次だ。

1. [README.md](README.md)
2. [DOCUMENT_INDEX.md](DOCUMENT_INDEX.md)
3. [intent/INTENT.md](intent/INTENT.md)
4. [operations/TRUST_BOUNDARY.md](operations/TRUST_BOUNDARY.md)
5. [SYSTEM_BOUNDARY.md](SYSTEM_BOUNDARY.md)
6. [CONVENTIONS.md](CONVENTIONS.md)
7. [MIGRATION_MANIFEST.md](MIGRATION_MANIFEST.md)
8. [dual-reviewer-foundation/requirements.md](.kiro/specs/dual-reviewer-foundation/requirements.md)
9. [dual-reviewer-foundation/design.md](.kiro/specs/dual-reviewer-foundation/design.md)
10. [cross-spec-requirements-alignment.md](docs/alignment/cross-spec-requirements-alignment.md)
11. [cross-spec-design-alignment.md](docs/alignment/cross-spec-design-alignment.md)
12. [cross-spec-tasks-alignment.md](docs/alignment/cross-spec-tasks-alignment.md)
13. [intent-to-requirements-trace-matrix.md](docs/traceability/intent-to-requirements-trace-matrix.md)
14. [dual-reviewer-implementation-governance/requirements.md](.kiro/specs/dual-reviewer-implementation-governance/requirements.md)
15. [dual-reviewer-implementation-governance/design.md](.kiro/specs/dual-reviewer-implementation-governance/design.md)

この順序で、意図、運用境界、system boundary、移行方針、feature contract に到達できる。
