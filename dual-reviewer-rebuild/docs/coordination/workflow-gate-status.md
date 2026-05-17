# workflow-gate-status

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` における
workflow gate の current status を記録するための台帳である。

目的は「実装済み」ではなく、
「どの gate まで通過したか」を明示することにある。

## 2. status vocabulary

- `pending`
- `in_progress`
- `completed`
- `completed_with_open_findings`
- `reopen_required`

## 3. current gate status

### 3.1 Core feature progression

- `intent review`: `completed`
- `requirements wave`: `completed`（2026-05-17 A-4 再開→差分横断整合 不整合 0→要件人間再承認 通過。経緯は下記 3.4）
- `design wave`: `completed`
- `tasks wave`: `completed`
- `implementation prototype pass`: `completed`
- `implementation conformance review`: `completed`

## 3.2 Implementation-governance introduction

- `governance spec requirements`: `completed`
- `governance spec design`: `completed`
- `governance spec tasks`: `completed`
- `governance artifact implementation`: `completed`
- `governance artifact validation`: `completed`
- `governance cross-spec alignment`: `completed`

## 3.3 Open finding backlog status

- `adoption gate nonconformance`: `fixed`
- `replay resolver fixture-bound resolution`: `fixed`
- `evidence-caveat heuristic linkage`: `fixed`

## 3.4 Reopen events

- 2026-05-17 `foundation requirements reopen`：起点＝runtime 設計レビュー A-4（must-fix、要件差し戻し）。変更＝foundation 要件 6 に受入 10（validator 状態語彙 pass/fail/blocked を foundation 所有）追加。spec.json 反映済み（reopened.requirements=true、approvals.requirements.approved=false、alignment.requirements=pending）。必須後続＝要件横断整合ゲートの再実施（6 機能）。解消期限＝設計人間承認の前
- 2026-05-17 `runtime requirements reopen`：起点＝上記 foundation 再開の横断整合差分チェックで顕在化した C 群 1 件。変更＝runtime 要件 6 受入 2 を foundation 正準 validator 状態語彙（pass/fail/blocked）参照に修正（A-4 上流原因の閉塞）。spec.json 反映済み（reopened.requirements=true、approvals.requirements.approved=false、alignment.requirements=pending）。横断整合差分チェック結果＝不整合 0、A 群整合・B 群既存対応・C 群本件を全採用で解消。解消期限＝設計人間承認の前
- 2026-05-17 `requirements re-approval 通過`：foundation・runtime とも要件人間再承認を取得。spec.json 反映済み（approvals.requirements.approved=true、reopened.requirements=false、recheck.impacted_downstream_phases から requirements 除去）。alignment.requirements=completed。A-4 再開サイクル（10 ステップ）完了。残課題なし
- 2026-05-17 `design alignment gate 決定保留 2 件`：(1) 実行側 A-5＝review_case と review_artifact の二重正本の対応規約所有、(2) 評価 A-7＝comparison_eligibility_note.json のスキーマ所有 spec。いずれも foundation/runtime/evaluation（および後続 self-improvement/paper-interface の消費）にまたがる所有決定。設計横断整合ゲートで一括決定。解消期限＝設計人間承認の前。それまで無契約依存が残る旨を明示

## 4. next gate transition

現在の次段は、必要があれば通常の feature 実装または新しい review checkpoint に進むこと。

## 5. update rule

この文書は少なくとも次のタイミングで更新する。

- 新しい cross-cutting governance rule を追加したとき
- conformance review を実施したとき
- open finding の status が変わったとき
- reopen が発生したとき
