# タスク横断整合ゲート（Requirement 9 タスク差分・統治）

- 実施日：2026-05-18
- 対象 feature：`dual-reviewer-implementation-governance`
- ゲート種別：タスク横断整合ゲート（REVIEW_PROTOCOL.md 節 4 フェーズ完走後フィーチャー横断レビューパターン）
- 対象差分：tasks.md の Task 11〜18、§2「実装順序」の Requirement 9 内部実装順序行（F-3 適用済）、§6 Completion Criteria の Requirement 9 完了条件行。既存 Task 1〜10・§4 Downstream Handoff・§5 Blocking Dependencies との整合も検査。
- 設計／要件正本：同 spec design.md「Workflow Execution Ledger and Enforcement Model」小節 1〜10、requirements.md Requirement 9 受入 1〜11。
- 横断対象：他 6 spec（foundation/runtime/evaluation/self-improvement/paper-interface/v2-acquisition）の tasks.md。
- レビュー人：独立タスク横断整合レビュー人（起草者と独立、批判的視点）。生証跡（不変）。tasks.md / design.md / spec.json は変更しない（点検と所見のみ）。

---

## 0. 正本（依存マップ）確認結果（横断・順序判断の前提＝REVIEW_PROTOCOL 節 4 規律）

正本 `docs/alignment/phase-and-feature-dependency-map.md` を本横断レビュー実施前に確認した。該当節：

- **§3.1 / §3.2**：phase 正方向依存 `intent→requirements→design→tasks→implementation→conformance review`。同 phase 修正時はその phase の alignment gate を再実施するルール。本ゲートは tasks phase 差分（Task 11〜18 追加）に対する tasks alignment gate の位置づけと整合。
- **§4.7**：implementation-governance は runtime/evaluation/self-improvement/paper-interface に対し `review dependency`。data contract を生成せず completion gate を追加する位置。Requirement 9 追加（台帳・enforcement）も workflow control 層であり data producer ではない（設計小節 8 Boundary と整合）。
- **§5.3**：tasks wave 生成順は foundation → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance。governance tasks は「prototype 実装後の review gate と validator を定義する位置」。Task 11〜18 を governance spec 内に閉じ §5 Blocking Dependencies で foundation 語彙・他 5 feature implementation 後 concrete artifact を前提化する構成と整合。
- **§7 Tasks Alignment Checklist**：foundation provenance/validator 語彙が固まってから下流という順序規律。Task 13／§5 が参照する foundation 所有正準 validator 状態語彙（`not_run`/`passed`/`failed`/`blocked`）は依存マップの順序規律と整合（foundation 先行）。
- **§8 Process Rule**：本マップは「implementation completion rule が変更された場合」更新対象。Requirement 9 は completion rule（台帳・enforcement）を追加するため依存マップ自体への前提追記が必要となるが、その取り込み先は設計小節 6 C-1 として確定済み（後述）。

**構造的決定の正本明示確認**：横断タスクの置き場所（C-1/C-2/C-3 の集約先）・Task 11〜18 の内部実装順序・foundation 語彙の所有は、設計小節 6（C 群取り込み先）・設計小節 7（foundation 正準語彙参照）・依存マップ §4.7/§5.3/§7・既設計横断整合ゲート（design-alignment-gate-2026-05-18-governance.md）で既に確定済み。本ゲートで新規の構造的決定は導入せず、確定済み決定への tasks 段の追従整合のみを検査する立場を取る。正本に明示なき新規構造的決定は本ゲートでは発生しなかった（利用者確認要事項なし）。

---

## 1. 観点別点検（REVIEW_PROTOCOL 節 4 整合性チェック観点）

### (a) 新 Owned Artifacts の配置・命名衝突（インストール場所規約整合・命名重複・曖昧性）

設計小節 Owned Artifacts 追加分が Task 11／Task 13 に分解する新 artifact：

- `docs/coordination/workflow-execution-ledger-template.md`（Task 11）
- `docs/coordination/ledgers/<process_id>-<date>.md`（Task 11、配置先 skeleton）
- `docs/coordination/workflow-process-authority-map.md`（Task 11）
- `scripts/validate_implementation_governance_artifacts.rb` のサブモード拡張（Task 13。新規スクリプトでなく既存 entrypoint の上位集合＝設計小節 2／7 と整合、別建て禁止を遵守）

検査：

- 既存 Task 1〜10 の配置（Task 1 の `docs/coordination/`／`docs/reviews/`／`scripts/` 列挙）と新 artifact 名の重複なし。`workflow-execution-ledger-template.md`／`workflow-process-authority-map.md`／`ledgers/` は Task 1 の既存列挙（implementation-conformance-review.md／metric-register 群／workflow-gate-status.md／cross-spec-...-alignment.md 等）と非重複。
- 他 6 spec tasks.md を `workflow-execution-ledger`／`workflow-process-authority-map`／`ledgers/`／`validate_implementation_governance` で grep → **全 6 spec で該当 0 件**。同名 artifact 所有・参照ヒットなし。命名・配置の暗黙衝突なし。
- 既設計横断整合ゲート §3（line 140）が同一検査を設計段で実施済み（他 6 spec 同名 artifact 所有・参照 0 件）。本タスク段で tasks.md レイヤを独立再確認した結果も同一。
- `docs/coordination/` 配下集約は §4 Downstream Handoff「`docs/coordination/` と `docs/reviews/` は本 spec の artifact placement rule に従う」と整合。配置規約の上書き階層違反なし。

判定：**A 群（配置・命名衝突なし）**。波及：なし。

### (b) Task 13 の foundation 所有 validator 状態語彙参照と runtime/evaluation の同語彙参照タスクの整合

- Task 13 作業：「状態語彙は foundation 所有正準語彙（not_run／passed／failed／blocked）を参照、再定義しない」。§5 Blocking Dependencies／設計小節 7 と一貫。
- foundation tasks.md：行 94-95／106／187／252 で `validator_status: not_run/passed/failed/blocked` を canonical owner として所有定義済み（foundation Requirement 6 受入 10）。
- runtime tasks.md 行 164：「validator status を foundation 所有の正準 enum をそのまま伝播し、実行側で再定義・丸め・別トークン化をしない」。
- evaluation tasks.md 行 82-83：`validator_status blocked → analysis_blocked` は evaluation local state（foundation evidence_class ではない）と弁別済み。
- 三者（foundation 所有・runtime 伝播・evaluation 参照・governance 参照）はいずれも foundation を単一正本とし再定義しない一貫構造。**並行語彙の二重化なし**。Task 13 は foundation tasks に新規 Task 追加を要求せず（参照のみ）、runtime/evaluation tasks へも波及しない。

判定：**A 群（foundation 単一正本参照で横断整合、語彙二重化なし）**。波及：なし（foundation/runtime/evaluation tasks 不変）。

### (c) Task 17（C-1/C-2/C-3 上位文書同期）の対象節と設計小節 6・要件/設計横断ゲート C 群の一致（F-4 是正後）

tasks.md Task 17 現行：

- C-1：`phase-and-feature-dependency-map.md` に台帳着手前提を追記。
- C-2：`CONVENTIONS.md`（新概念定義・節 6）／`WORKFLOW_OVERVIEW.md` 節 7／`HUMAN_WORKFLOW.md` 節 5.2.7 を同期。
- C-3：`workflow-repair-procedure.md` 節 2／3 に台帳・enforcement を内包同期。

照合：

- 設計小節 6：「C-1＝依存マップ。C-2＝CONVENTIONS（節 6）／WORKFLOW_OVERVIEW 節 7／HUMAN_WORKFLOW 節 5.2.7。C-3＝workflow-repair-procedure 節 2／節 3」。**Task 17 C-3 は「節 2／3」で設計小節 6 と完全一致**。タスク個別レビュー F-4 案 X（C-3 を設計どおり「節 2／3」に是正、旧記載の「節 6」拡張を除去）が適用済みであることを本ゲートで確認。設計小節を tasks が越えて上書きする不整合は解消済み。
- 要件横断ゲート（requirements-alignment-gate-2026-05-18-governance.md）C 群 3 件・設計横断ゲート（design-alignment-gate-2026-05-18-governance.md line 184-186）C 群 3 件と Task 17 の C-1/C-2/C-3 は 1 対 1 完全対応。対象文書・趣旨が一致。対応漏れ 0。
- 各上位文書側の同期受け皿（依存マップ §8／CONVENTIONS 節 6／WORKFLOW_OVERVIEW 節 8 同期ルール／HUMAN_WORKFLOW／workflow-repair-procedure 節 6 update rule）が存在し欠落なし（設計横断ゲート line 157／206 で確認済み、本ゲートで再確認）。
- 検査時点で CONVENTIONS.md 節 6 は「運用メモ」、workflow-repair-procedure.md 節 6 は「update rule」だが、新概念定義／enforcement 内包同期の追記先として節番号指定は task と design で一致しており、追記実体は Task 17（承認後文書同期作業、1 件ずつ spec.json alignment 反映を伴う）で行う段取りが上位文書 update rule に存在。

判定：**B 群（F-4 是正で設計小節 6 と完全一致、C 群対応漏れ 0。記録のみ）**。波及：F-4 是正は既適用済で本ゲート起点の追加波及なし。

### (d) Task 11〜18 の依存・順序（§2 Req9 行）と §5 Blocking・依存マップの非矛盾

- §2「実装順序」に F-3 適用の Requirement 9 内部実装順序行を確認：「Task 11（台帳テンプレ・authority-map）→ 12（台帳生成器・既存台帳の扱い）→ 13（独立再導出 validator 拡張）→ 14（enforcement・通過マーカー・fail-closed）→ 15（marker 真正性）→ 16（uniform・reopen・移行）→ 18（テスト）。Task 17（C-1/C-2/C-3 上位文書同期）はタスク人間承認後の文書同期作業として最後に実施」。前提物先行（11 が 12/13/14 の前提、12 が 13/14 の前提、13 が 14 の前提、17 は承認後）が明示され、タスク個別レビュー F-3（§2 に Req9 内部順序追記）適用済を確認。
- §5 Blocking Dependencies：「phase-and-feature-dependency-map §5.3 に従い tasks alignment gate 完走後・prototype 実装後の review gate と validator を定義する位置」「Task 3 heuristic 語彙 validator 検査は v2-acquisition 語彙確定まで必須化しない」「Task 9 validator は他 5 feature implementation 着手後 concrete artifact 取得後 pass 確認」。§2 順序行と §5 に矛盾なし。Task 11〜18 内部順序は §5 の Blocking（foundation 語彙先行・他 feature implementation 後 concrete）と非競合（台帳・enforcement は workflow control 層で他 feature business data 完了に依存しない）。
- 循環依存：11→12→13→14→{15,16}→18、17 は承認後、18 は TDD 先行。循環なし。
- 依存マップ §5.3／§7 の foundation 先行規律と §2 Req9 行・§5 は整合（(b) 参照）。

判定：**A 群（順序・Blocking・依存マップ非矛盾、循環なし。F-3 適用で §2 に内部順序明示済）**。波及：なし。

### (e) 横断タスク（C-1/C-2/C-3）の中心フィーチャー（統治）側独立タスク集約

- C-1/C-2/C-3 は **Task 17 として独立 Task に切り出され、governance spec の tasks.md に配置**。本契約（Requirement 9 台帳・enforcement）の発生源・所有者である governance が中心フィーチャー。REVIEW_PROTOCOL 節 5 タスク特有方針「横断タスクは中心フィーチャー側に置く」（節 3 中心フィーチャー判定と同一基準）と整合。
- 他 6 spec tasks.md に C-1/C-2/C-3 相当の横断タスクは存在しない（grep 0 件）。横断作業が周辺 feature に分散せず統治側に集約されている。
- foundation 正準語彙参照（Task 13）も「参照」であり foundation tasks への新規 Task 追加を生まない（(b) 参照）。
- heuristic 既定挙動・minimal-template 語彙：Task 3（既存）・§5 Blocking で「canonical owner は v2-acquisition、governance は参照のみ・語彙確定まで必須検査しない」（Requirement 8 受入 6）と既に切り出し済み。v2-acquisition tasks.md（T1〜T17）に heuristic-default／minimal-template 語彙所有タスクは未記載だが、これは Requirement 8 受入 6 が認める既知の段送り（governance は語彙確定まで heuristic template 実体を必須検査しない設計）であり、Task 11〜18 は heuristic 語彙に新規依存を追加しない（Requirement 9 台帳・enforcement は heuristic template を必須検査対象に含めない）。v2-acquisition tasks への新規波及なし。

判定：**A 群（横断タスクは独立 Task 17 に集約・中心フィーチャー側配置、周辺 feature 分散なし）**。波及：なし。

### その他観点（接続契約 3 要素・再検証双方向反映・期限完了基準整合・移行スクリプト・用語正本整合）

- **接続契約 3 要素（場所規約・識別子・失敗信号）**：台帳の場所規約（`docs/coordination/ledgers/<process_id>-<date>.md`）・識別子（`process_id`／provenance `authority_path`/`authoritative_section_id`/`section_content_hash`）・失敗信号（fail-closed／blocked／陳腐化検知の台帳内記録）が Task 11/12/14 で 3 要素を備える。設計小節 1/1.3/4 と整合。**A 群**。波及なし。
- **再検証の双方向反映**：reopen 経路（Task 16・C-3）が enforcement 対象に内包され、下流から上流への要請（reopen-procedure 同期）が設計小節 5／Task 16・17 に反映。**A 群**。波及なし。
- **期限と完了基準整合**：§6 Completion Criteria の Requirement 9 完了条件行「実行台帳・独立再導出・enforcement・fail-closed・通過マーカー・移行戦略が設計小節 1〜10 どおり実装され、検査不能・バイパス・曖昧がいずれも fail-closed」は要件 AC1〜11／設計小節 1〜10 を包括参照し各 Task 完了条件と整合。**A 群**。波及なし。
- **移行スクリプト／移行戦略**：Task 16 が grandfathering（design 承認以降の新規 process から適用）・自己ブートストラップ（移行期は手作業台帳可・workflow-gate-status に証跡）・`ledger_format_version` による format-migration（破壊的一括書換なし）を設計小節 10 どおり分解。既存 completed process への遡及破壊なし。**A 群**。波及なし。
- **用語の正本整合（CONVENTIONS 節 3）**：「prescribed workflow process」は requirements Requirement 9 で WORKFLOW_OVERVIEW 規定 process と定義され CONVENTIONS 節 3 の `phase` 語と区別済み（要件個別レビュー F1-2 反映、要件横断ゲート line 30 で命名重複 0 確認済）。tasks.md は本語を踏襲し再定義しない。**B 群（要件段確認済・記録のみ）**。波及なし。

---

## 2. 4 分類結果

- **A 群（確認済整合）：8 件**
  - A-1：新 Owned Artifacts 配置・命名衝突なし（他 6 spec grep 0 件）
  - A-2：foundation 正準 validator 語彙 単一正本参照で横断整合（語彙二重化なし、foundation/runtime/evaluation tasks 不変）
  - A-3：Task 11〜18 順序・§5 Blocking・依存マップ非矛盾（循環なし、F-3 で §2 内部順序明示）
  - A-4：横断タスク C-1/C-2/C-3 が独立 Task 17 に集約・中心フィーチャー側配置
  - A-5：接続契約 3 要素（場所規約・識別子・失敗信号）整合
  - A-6：再検証双方向反映（reopen 経路 enforcement 内包）整合
  - A-7：期限・完了基準整合（§6 Completion Criteria 行が AC1〜11／小節 1〜10 包括）
  - A-8：移行戦略（grandfathering／自己ブートストラップ／format-migration）整合・遡及破壊なし
- **B 群（既存対応済・記録のみ）：3 件**
  - B-1：Task 17 C-3 が F-4 是正で設計小節 6「節 2／3」と完全一致（要件/設計横断ゲート C 群と 1 対 1 対応・対応漏れ 0）
  - B-2：用語「prescribed workflow process」CONVENTIONS 節 3 整合（要件段確認済）
  - B-3：他 6 spec 波及 0 件が設計横断ゲート §3 で確認済、本タスク段で tasks.md レイヤ独立再確認も同一
- **C 群（今回顕在化の新規含意）：0 件**
- **不整合（受入違反・実装不可能）：0 件**

通常パターン（A 群大部分・C 群少数・不整合 0）と一致。REVIEW_PROTOCOL 節 4「タスクフェーズの横断レビューでは A 群が大幅に増え C 群はさらに少数」の経験パターンに一致。

---

## 3. 波及明示記録（全件、なしも明記）

- A-1〜A-8：いずれも tasks.md 内整合の確認のみ。**他 Task・他 spec・上位文書への波及なし**。
- B-1（F-4 是正）：既適用済（タスク個別レビュー F-4 案 X）。本ゲート起点の追加波及なし。波及範囲は過去に governance tasks.md 1 箇所に閉じており完了済。**他 6 spec・上位文書波及なし**。
- B-2／B-3：記録のみ。変更を加えないため**波及なし**。
- C 群 0 件：**追加波及なし**。
- **他 6 spec tasks への波及：0 件**（foundation/runtime/evaluation/self-improvement/paper-interface/v2-acquisition いずれも `workflow-execution-ledger`／`workflow-process-authority-map`／`ledgers/`／`validate_implementation_governance`／`prescribed workflow process` grep 該当 0 件。business data tasks 不変）。
- **上位運用文書への波及**：Task 17（C-1/C-2/C-3）の同期実体は **タスク人間承認後の文書同期作業**であり、本タスク横断整合ゲート段では上位文書（依存マップ／CONVENTIONS／WORKFLOW_OVERVIEW／HUMAN_WORKFLOW／workflow-repair-procedure）への実体変更は発生しない。各上位文書 update rule に同期受け皿が存在し欠落なし。本段での上位文書波及は**なし**（同期は承認後の別工程）。

---

## 4. 統治 Requirement 6 受入 1 のタスク段充足判定

統治 Requirement 6 AC1：「governance rule が複数 feature の completion criteria を変えるとき cross-spec alignment review を必須化する」。

- **発火確認**：Requirement 9（実行台帳・独立再導出・enforcement・fail-closed）は不可逆操作の機械遮断・台帳必須という completion 基準を全 prescribed workflow process（＝全 feature の requirements/design/tasks フェーズ遂行手続き）横断で変える。Requirement 6 AC1 の「複数 feature の完了基準を変える governance rule」に該当し、tasks 段でも cross-spec alignment review が必須。
- **本ゲートによる充足**：本タスク横断整合ゲート（本文書）が、依存マップ正本確認のうえ Requirement 9 タスク差分（Task 11〜18／§2 Req9 行／§6 完了条件行）を 6 spec 横断・上位文書横断で点検し不整合 0・他 6 spec 波及 0・A 群 8／B 群 3／C 群 0 を構造化した。これは workflow-repair-procedure 節 3 状態遷移表最終行が要求する「cross-spec review」の **tasks 段実施そのもの**に当たる。依存マップ §5.3 が定める tasks wave (6) tasks alignment gate にも該当（§0 正本確認）。
- **要件段・設計段との連続性**：cross-spec alignment review は要件段（requirements-alignment-gate-2026-05-18-governance.md）で要件段充足、設計段（design-alignment-gate-2026-05-18-governance.md）で設計段充足が判定済。本ゲートはその tasks 段の cross-spec alignment 実施として一連の充足を完結させる。
- **spec.json alignment 反映の要否**：Requirement 6 AC4「governance spec metadata に cross-spec alignment の要否・完了を反映」。spec.json `custom.alignment.tasks` への completed 反映・workflow-gate-status 更新は **タスク人間承認と同一手続き内**で行う段取りが上位文書（workflow-repair-procedure 節 3／workflow-gate-status 節 5 update rule）に存在し欠落なし。本レビュアーは spec.json／workflow-gate-status を変更しない（点検と所見のみ）。

**判定：統治 Requirement 6 AC1 の cross-spec alignment review は tasks 段で「必要」と判定されるべきであり、本ゲートの実施でその義務は tasks 段として充足している。** cross-spec alignment memo（＝本文書）は tasks 段で必要であり作成済み。

---

## 5. C 群所見

**C 群：0 件。** 4 要素所見・必要性判定・本セッション同期/別送り判断材料の対象なし。

要件横断ゲート由来の C-1/C-2/C-3（上位文書同期）は本タスク段で新規顕在化した含意ではなく、設計小節 6 で取り込み先確定済・Task 17 として承認後文書同期作業に段取り済の既知事項であり、本ゲートでは B 群（B-1。既存対応済・記録のみ）として扱う。新規 C 群を構成しない（設計横断ゲート line 156/196 の「C-2 naming rule 追記・C-3 証跡所在追記は既存 C-2/C-3 同期スコープ内吸収、独立新規 C 群を構成しない」判定と整合）。本タスク段固有の新規含意は検出されなかった。

---

## 6. 総合所見

- Task 11〜18 ＋ §2 Requirement 9 内部実装順序行（F-3 適用済）＋ §6 Completion Criteria Requirement 9 完了条件行は、design「Workflow Execution Ledger and Enforcement Model」小節 1〜10・Owned Artifacts 追加分を漏れなく実装単位へ分解し、フィーチャー横断（新 Owned Artifacts 命名・配置、foundation 語彙参照、横断タスク集約、依存・順序、接続契約、移行戦略）でいずれも整合。**不整合 0 件・受入違反/実装不可能なし・進行を止める所見なし**。
- 他 6 spec tasks への波及 0 件（business data tasks 不変、workflow control 層は他 feature 完了に依存しない）。foundation 正準 validator 語彙は単一正本参照で語彙二重化なし。横断タスク C-1/C-2/C-3 は独立 Task 17 として中心フィーチャー（governance）側に集約。
- タスク個別レビューの F-3（§2 に Req9 内部順序追記・自動採択）／F-4 案 X（Task 17 C-3 を設計小節 6 どおり「節 2／3」に是正）はいずれも tasks.md に適用済であることを本ゲートで確認。F-4 是正後、Task 17 C-3 と設計小節 6 は完全一致し設計越境上書きは解消（B-1）。F-1（小節 8 Boundary トレース併記・任意）／F-2（Task 14 集約・現状維持妥当・記録のみ）は本横断ゲートでも横断不整合を生まないことを再確認（C 群・不整合に該当せず）。
- 統治 Requirement 6 AC1 の cross-spec alignment review は tasks 段で「必要」と判定され、本ゲートの実施でその義務は tasks 段として充足。要件段・設計段・タスク段の cross-spec alignment が一連で完結。
- **結論：本タスク差分（Task 11〜18／§2 Req9 行／§6 完了条件行）はタスク人間承認へ進めてよい。C 群是正・不整合是正の必要なし（C 群 0 件・不整合 0 件）。** spec.json `custom.alignment.tasks=completed`・workflow-gate-status 更新はタスク人間承認と同一手続き内で行う段取りが上位文書に存在し欠落なし（本レビュアーは適用しない）。要件横断ゲート由来 C-1/C-2/C-3 の上位文書同期（Task 17）は承認後文書同期作業として実施し、本セッション同期か別送りかは利用者判断事項（REVIEW_PROTOCOL 節 4 / discipline_ssot_structural_decision_check。本レビュアーは決定せず提示のみ）。

---

## 7. 証跡パス

- 本ゲート証跡：`dual-reviewer-rebuild/docs/coordination/tasks-alignment-gate-2026-05-18-governance.md`（本ファイル、不変）
- 依存正本：`dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md`（§3.1/§3.2/§4.7/§5.3/§7/§8 確認）
- レビュー手続き正本：`dual-reviewer-rebuild/operations/REVIEW_PROTOCOL.md` 節 4（フェーズ完走後フィーチャー横断レビューパターン）
- 主対象：`dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/tasks.md`（Task 11〜18／§2 Req9 行／§4／§5／§6）
- 設計／要件正本：同 spec `design.md`（小節 1〜10）／`requirements.md`（Requirement 9 受入 1〜11）
- 参照（鵜呑みにせず独立判断）：同 spec `reviews/tasks-local-review-2026-05-18.md`、`reviews/design-local-review-2026-05-18.md`、`reviews/design-reverse-trace-audit-2026-05-18.md`、`docs/coordination/design-alignment-gate-2026-05-18-governance.md`、`docs/coordination/requirements-alignment-gate-2026-05-18-governance.md`、`docs/coordination/workflow-gate-status.md`
