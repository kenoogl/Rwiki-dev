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

- `governance spec requirements`: `completed`（2026-05-18 Requirement 9 追加・独立レビュー/横断整合/人間承認 通過）
- `governance spec design`: `completed`（2026-05-18 Requirement 9 設計・独立レビュー/横断整合/人間承認 通過）
- `governance spec tasks`: `completed`（2026-05-18 Requirement 9 タスク・独立レビュー/横断整合/人間承認 通過）
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
- 2026-05-18 `design alignment gate（5 機能）完走`：対象＝foundation/runtime/evaluation/self-improvement/paper-interface。検出＝不整合 1（基盤設計 validator_status 列挙に blocked 欠落＝A-4 基盤側設計追従漏れ）→ 基盤設計修正で解消。C 群 1（評価分類に validator_status=blocked→analysis_blocked 追記）解消。越境クラスタ 2 件決定：実行側 A-5＝review_case を唯一横断正本（foundation 所有）・review_artifact 投影規約は runtime 所有、評価 A-7＝comparison_eligibility_note スキーマは生成元 runtime 所有。最終結果＝不整合 0。残＝implementation-governance 設計 must-fix（SSoT 設計波順で本ゲート後）
- 2026-05-18 `implementation-governance 設計 must-fix 適用`：4 件（P-1/P-8/A-1/A-3）すべて統治設計内で完結・他 spec 波及 0。横断波及なしのため 5 機能ゲート結果（不整合 0）維持
- 2026-05-18 `design 人間承認 通過`：6 機能とも設計 must-fix・横断整合・A-4 関連解消を経て設計人間承認を取得。spec.json 反映済み（phase=design-approved、approvals.design.approved=true、reopened.design=false、alignment.design=completed、recheck.impacted_downstream_phases から design 除去）。次段＝tasks フェーズ
- 2026-05-18 `implementation-governance requirements reopen`：起点＝当セッションのワークフロー不遵守（タスクフェーズ wave のフェーズ内レビュー段を無言圧縮、整合ゲートを独立実施せず）。手戻り種別＝`C`（統治の要件契約不足）。変更＝統治 requirements に Requirement 9（Workflow Execution Ledger and Compliance Enforcement。全ワークフロー適用、台帳の独立再導出による「穴 1」対処を含む）を追加。spec.json 反映済み（phase=requirements、reopened.requirements=true、reopened.design=true、approvals.requirements.approved=false、alignment.requirements/design=pending、recheck.impacted_downstream_phases=[requirements,design,tasks]）。必須後続＝要件個別レビュー（節 2）→ 要件横断整合ゲート（節 4）＋統治要件 6 受入 1 横断整合 → 要件人間承認 → 設計フェーズ丸ごと再実施 → タスクフェーズ丸ごと再実施。保留＝再生成済み 6 機能タスク文書のレビュー（利用者指示で本仕組み確立後）
- 2026-05-18 `implementation-governance requirements 個別レビュー＋横断整合ゲート 完走`：独立パスで実施。個別レビュー＝致命2/重要4/軽微1 の must-fix 7 件を 1 件ずつ承認で適用（Requirement 9 を受入 1〜11 に拡充）。横断整合ゲート＝不整合 0・他 6 spec 波及 0・A群8/B群2/C群3。C 群 3 件（依存マップ・CONVENTIONS/WORKFLOW_OVERVIEW/HUMAN_WORKFLOW・workflow-repair-procedure への上位文書同期）は利用者判断で設計段送り（設計フェーズ丸ごと再実施＋AC9 同期作業で処理）。統治要件 6 受入 1（cross-spec alignment review 必須）は本ゲートで要件段充足、証跡＝requirements-alignment-gate-2026-05-18-governance.md。次段＝要件人間承認
- 2026-05-18 `implementation-governance requirements 人間承認 通過`：spec.json 反映済み（phase=requirements-approved、approvals.requirements.approved=true、reopened.requirements=false、alignment.requirements=completed、recheck.impacted_downstream_phases から requirements 除去＝[design,tasks]）。要件横断整合ゲート C 群 3 件（上位文書同期）は alignment.design.note に引き継ぎ、設計フェーズ丸ごと再実施で取り込む。次段＝設計フェーズ再実施（節 3 個別レビュー＋節 4 設計横断整合＋人間承認、いずれも独立パス）
- 2026-05-18 `implementation-governance design 個別レビュー＋横断整合ゲート 完走`：独立パスで実施。個別レビュー＝致命2/重要8/軽微1 の must-fix 11 件を 1 件ずつ承認で適用（Requirement 9 設計節を小節 1〜10 に拡充、authority-map 構造・provenance 値域・曖昧判定機械化・通過マーカー・marker 真正性・テスト戦略・移行戦略を具体化）。横断整合ゲート＝不整合 0・他 6 spec 波及 0・A群9/B群4/C群3。C 群 3 件（C-1 依存マップ／C-2 CONVENTIONS・WORKFLOW_OVERVIEW・HUMAN_WORKFLOW／C-3 workflow-repair-procedure 同期）は利用者判断で承認後の文書同期作業送り（設計小節 6 と整合）。統治要件 6 受入 1 は設計段で充足、証跡＝design-alignment-gate-2026-05-18-governance.md。次段＝設計人間承認
- 2026-05-18 `implementation-governance design 人間承認 通過`：spec.json 反映済み（phase=design-approved、approvals.design.approved=true、reopened.design=false、alignment.design=completed、recheck.impacted_downstream_phases から design 除去＝[tasks]）。C 群 3 件（C-1/C-2/C-3 上位文書同期）は alignment.tasks.note に引き継ぎ、承認後の文書同期作業で実施。次段＝タスクフェーズ丸ごと再実施（節 5 個別レビュー＋節 4 タスク横断整合＋人間承認、いずれも独立パス）
- 2026-05-18 `implementation-governance design 逆方向トレース監査 完走＋S-1 微修正`：利用者懸念（差分追従の積み重ねで現行要件に紐づかない孤児・陳腐が混入していないか）を受け独立パスで design.md 全体（26 単位）を現行要件 1〜9 と逆方向突合。結果＝孤児 0・stale 1（S-1 軽微）・致命/重要 0、削除済み要件なし、設計健全。S-1（Validation Model 本体節と小節 7 の二層化＝可読性冗長）は案 A（本体節に小節 7 への前方参照 1 行、非意味的）を適用。設計人間承認後の編集だが契約・挙動不変かつ独立監査で健全性確認済みのため B 手戻り（設計整合再実施・tasks 連鎖 reopen）は回さず証跡記録のみ（利用者判断＝案ア）。証跡＝reviews/design-reverse-trace-audit-2026-05-18.md。次段＝タスク個別レビュー
- 2026-05-18 `implementation-governance tasks 個別レビュー＋横断整合ゲート 完走`：独立パスで実施。個別レビュー（節 5 7 観点）＝致命/重要 0・軽微 4、F-3（§2 に Req9 内部実装順序追記）・F-4 案 X（Task 17 C-3 を設計小節 6 どおり「節 2／3」に是正）を適用、F-1/F-2 任意・記録のみ。横断整合ゲート＝不整合 0・他 6 spec 波及 0・A群8/B群3/C群0。C-1〜C-3 は設計小節 6 確定済・Task 17 承認後文書同期に段取り済（B 群）。統治要件 6 受入 1 はタスク段で充足、証跡＝tasks-local-review-2026-05-18.md、tasks-alignment-gate-2026-05-18-governance.md。次段＝タスク人間承認
- 2026-05-18 `implementation-governance tasks 人間承認 通過／Requirement 9 再開サイクル完了`：spec.json 反映済み（phase=tasks-approved、approvals.tasks.approved=true、reopened すべて false、alignment.tasks=completed、recheck.upstream_change_pending=false・impacted_downstream_phases=[]）。要件→設計→タスクの再開 10 ステップ完走。残＝承認後の上位文書同期 C-1（依存マップ）／C-2（CONVENTIONS・WORKFLOW_OVERVIEW・HUMAN_WORKFLOW）／C-3（workflow-repair-procedure 節 2／3）＝Task 17、および強制関数の実装（実装フェーズ）。保留＝本セッション前半で全面再導出した 6 機能タスク文書のレビュー（利用者指示「その後」＝強制関数確立後）
- 2026-05-18 `implementation-governance 承認後 上位文書同期 C-1/C-2/C-3 完了`：Task 17 として実施。C-1＝phase-and-feature-dependency-map §8.1 に台帳着手前提を追記。C-2＝CONVENTIONS §6（新概念 prescribed workflow process／workflow execution ledger を Req9 正本定義として参照）・WORKFLOW_OVERVIEW §7（権威ソース＝workflow-process-authority-map を正本一覧に追加）・HUMAN_WORKFLOW §5.2.7（gate package に台帳突合表埋込を前提化、Req9 受入 8）。C-3＝workflow-repair-procedure §2.1（reopen 手続きへ台帳・enforcement・確定書式を内包）・§3 表直後に enforcement 対象注記。各文書とも追記のみ・既存不変。要件/設計/タスク横断整合ゲートで設計段送りとした C 群を全件解消。残＝強制関数の実装（実装フェーズ）と保留中の 6 機能タスク文書レビュー（利用者指示「その後」）

## 4. next gate transition

現在の次段は、必要があれば通常の feature 実装または新しい review checkpoint に進むこと。

## 5. update rule

この文書は少なくとも次のタイミングで更新する。

- 新しい cross-cutting governance rule を追加したとき
- conformance review を実施したとき
- open finding の status が変わったとき
- reopen が発生したとき
