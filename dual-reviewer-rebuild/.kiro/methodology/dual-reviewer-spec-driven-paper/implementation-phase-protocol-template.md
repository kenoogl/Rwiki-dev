# implementation-phase-protocol-template

_purpose: reference-free case の implementation phase を、後段の conformance review と enforcement が突合できる形で記録するための protocol ひな型_
_正本参照: `.kiro/specs/dual-reviewer-implementation-governance` design「Owned Artifacts」「Workflow Model / Stage 1〜4」、requirements Requirement 8 受入 5、tasks Task 1／Task 3_

---

## 1. このひな型の役割

この文書は governance 所有の methodology artifact であり、reference-free case の implementation phase 実行 protocol の記入様式を固定する。値は主張や体裁では満たせない（完了は repo 内証跡 artifact の存在＋構造適合で判定する）。

## 2. ヘッダ欄（protocol インスタンス先頭に 1 つ）

- `case_slug` — 対象 case の slug
- `phase` — `implementation`
- `bootstrap_mode` — `reference-free`
- `canonical_source` — canonical source の repo 相対パス
- `started_at` — ISO 8601

## 3. 段集合（Stage 1〜4）

| stage | 役割 | completion 証跡 |
|-------|------|------------------|
| Stage 1: Implementation | task plan に従って artifact を実装 | 実装 artifact の repo 相対パス |
| Stage 2: Relevant Smoke Validation | feature ごとの validator/smoke を再実行し current branch 上の mechanical pass を確認 | smoke 実行結果 |
| Stage 3: Implementation Conformance Review | scope 固定／rerun summary／spec・design・dependency map 照合／finding 起票／severity・disposition／signal・coordination 接続／metric snapshot | `docs/reviews/*.md` |
| Stage 4: Checkpoint Close | finding 0 件、または review artifact と disposition を伴う finding を持つまで close しない（`P1` open は次 feature 開始前修正対象） | `docs/coordination/workflow-gate-status.md` |

## 4. 記入規律

- 各段の completion は repo 内証跡 artifact の存在＋構造適合で判定し、主張では満たせない。
- conformance review まで進んだが open finding が残る場合は checkpoint status を `completed_with_open_findings` とする。
- prescribed workflow process として着手する場合、`docs/coordination/workflow-process-authority-map.md`／`docs/coordination/workflow-execution-ledger-template.md` の台帳契約に従う（Requirement 9）。
