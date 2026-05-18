# Tasks Local Review — dual-reviewer-self-improvement

- 実施日: 2026-05-18
- 方式: 独立タスク個別レビュー（REVIEW_PROTOCOL 節 5、7 観点を網羅実施）
- 起草との独立性: 本セッション前半でタスクを全面再導出した工程の独立批判視点。起草者と分離した検査として実施（前半で機能個別タスクレビューを省略した工程不遵守の正規補完）
- 入力（すべて絶対パス）:
  - 主対象: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/tasks.md`
  - 設計正本: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/design.md`
  - 要件参照: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/requirements.md`（Requirement 1〜8）
  - 横断参照: foundation / runtime / evaluation / paper-interface / implementation-governance の tasks.md
  - 上位正本: `operations/REVIEW_PROTOCOL.md` 節 5、`docs/alignment/phase-and-feature-dependency-map.md`、`CONVENTIONS.md`
  - 参考: runtime / evaluation の `reviews/tasks-local-review-2026-05-18.md`（所見型の参考。独立判断）
- 不変条件: 本ファイルは生証跡。tasks.md / design.md / requirements.md / spec.json は本レビューで変更しない（所見のみ）

---

## 0. 依存マップ確認結果（横断・順序判断の前提）

`docs/alignment/phase-and-feature-dependency-map.md` を確認した。判断に効く点は次。

- §4.5: self-improvement は foundation に `hard dependency`、runtime に `interface dependency`、evaluation に `hard dependency`。replay は runtime artifact 依存、proposal quality / exclusion / imported evidence admission は evaluation output 依存。
- §5.3 tasks wave 推奨順序: foundation → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance。self-improvement tasks は evaluation tasks の後段。
- §6 / §7 tasks alignment checklist: 「self-improvement proposal template 実装より前に evaluation admission artifact が固まっているか」が最低限の確認対象。
- §8.1: prescribed workflow process は workflow execution ledger を前提とするが、本タスク文書は self-improvement feature の実装単位分解であり、process 段集合の権威ソースではない（authority-map 対象外）。
- 結論: self-improvement tasks の blocking dependency（tasks.md §5）が runtime step-level replay artifact / evaluation analysis output / foundation 実行メタデータ・無効化契約を先行条件として明示しているのは依存マップ §4.5 / §5.3 / §6 / §7 と整合。横断順序の即興導出はせず本正本に従って観点 3 / 5 を判定した。

横断構造決定（feature 間依存・順序）について本正本に明示のない新規事項は本レビューで検出せず（規律 `discipline_ssot_structural_decision_check.md` 該当なし）。

---

## 観点 1: 設計全件の網羅

### 要点

design.md の構成要素を列挙し、tasks.md の Task 1〜9 への割当を全件突合した。

### 詳細突合（design 構成要素 → 担当 Task）

- Architecture 5 段（signal intake / proposal builder / test gate / decision gate / history registry）→ Task 2/3 / 4 / 5 / 6 / 6・7。網羅。
- Learning Artifact Layout（findings/proposals/backtests/templates/approved-updates/rejected-updates/rollback 全 7 ディレクトリ）→ Task 1 が全ツリーを列挙。網羅。
- Schema Versioning（全 artifact に `schema_version`、foundation 要件 3 受入 3 規約接続、非互換時版上げ、長期保存読取保証、スキーマ所有 self-improvement 側）→ Task 1。網羅。
- Input Model §1 Input Classes（`review_quality_signal` / `workflow_failure_signal` / `evidence_quality_signal`）→ Task 2。網羅。
- Input Model §1.5 v2 Supporting Inputs（`run_manifest.yaml` / `v2/signal_linkage_note.json` / `v2/trace_note.json` / `derived/comparison_eligibility_note.json`、読めなくても基本 flow 維持）→ Task 2。網羅。
- Input Model §2 Valid vs Invalid（valid=review quality 一次、invalid=workflow/validation/contamination 一次、exploratory=hypothesis seed のみ、provenance 欠落時 proposal 阻止）→ Task 2。網羅。
- Input Model §2.5 Manual→Runtime Handoff Boundary（非破壊上書き、`superseded_by`/`supersession_reason`/`supersession_at`、対称 `supersedes`、`source_origin=manual_review_record` 保持）→ Task 2。網羅。
- Signal Extraction Model §1 Runtime-Derived Signals（repeated defer clusters ほか 5 種）→ Task 3。網羅。
- Signal Extraction Model §2 Evaluation-Derived Signals（treatment-specific quality drop ほか 5 種）→ Task 3。網羅。
- Signal Extraction Model §2.5 Proposal Normalization Rules（同一 run closely-coupled 統合可、aggregate caveat は caveat code ごとに分離）→ Task 3。網羅。
- Signal Extraction Model §3 Project-Specific Pattern Extraction（recurring → pattern candidate → meta-pattern → proposal/pattern asset 接続、operator-facing remediation template 派生、`runtime_validation_summary.schema.json` を canonical contract）→ Task 3。網羅。
- Signal Extraction Model §4 Findings Artifact Required Fields（findings/templates 各 artifact の必須 field）→ Task 3。網羅。
- Proposal Model §1 Proposal Unit（`<proposal_id>.yaml` の 13 必須 field）→ Task 4。網羅。
- Proposal Model §2 Target Layers / `source_origin` enum → Task 4。網羅。
- Proposal Model §3 Proposal States（7 状態・許可遷移正本・終端 2 種・不正遷移禁止）→ Task 4。網羅。
- Proposal Model §4 Review Prioritization Notes（workflow > schema/evidence > prompt/policy、exploratory-only hold、comparison impossibility 系優先）→ Task 4。網羅。
- Replay and Backtest Model §1 Test Mode Selection（`replay`/`backtest`/`manual_review`、3 要素分岐）→ Task 5。網羅。
- Replay and Backtest Model §2 Replay Inputs（最低入力 + Step B/C step-level replay 必須 + manifest-based discovery）→ Task 5。網羅。
- Replay and Backtest Model §3 Backtest Inputs（最低入力 4 + optional 1）→ Task 5。網羅。
- Replay and Backtest Model §4 Test Result Artifact（`<proposal_id>.json` の 9 必須 field、`result_label` enum、`untested` と遷移条件整合）→ Task 5。網羅。
- Decision and Adoption Model §1 Approval Gate（4 対象 human approval、`approved` は repo change 未含意）→ Task 6。網羅。
- Decision and Adoption Model §2 Adoption Gate（3 条件、`adoption_register.json` 6 必須 field）→ Task 6。網羅。
- Decision and Adoption Model §3 Rejection Model（`rejection_register.json` 4 必須 field、preserved outcome）→ Task 6。網羅。
- Rollback Model（supersession 区別、`rollback_register.json` 5 必須 field、failed improvement 履歴非削除、motivating evidence 事後 invalidate 起点再評価/rollback）→ Task 7。網羅。
- Separation from Paper Narrative（paper-facing motivation 単独不可、許容されない 2 例）→ Task 8。網羅。
- Interfaces to Other Features（Runtime/Evaluation/Paper-Interface）→ Task 8 + tasks.md §4 Downstream Handoff。網羅。
- Key Decisions 1〜4 → 各 Task 根拠記述に分散反映（Decision 2→Task 2、Decision 3→Task 6、Decision 4→Task 7）。網羅。
- Completion Criteria 4 点 → tasks.md §6 + Task 9 完了条件。網羅。
- Open Issues for Design Alignment Gate（4 件：repo version update 参照法、schema change proposal の最小 replay、workflow-only proposal replay 境界、paper-interface adopted change 履歴粒度）→ tasks.md に未反映（下記 T1-A）。

### 深掘り — 設計に存在するが Task に明示反映が弱い要素

- 所見 T1-A（軽微）: 所在 = tasks.md 全体 / design「Open Issues for Design Alignment Gate」。問題 = design に未解決の design alignment open issue が 4 件明記される（proposal→repo version update 参照法、schema change proposal の最小 replay 要件、workflow-only proposal に replay を要求する境界、paper-interface 提示 adopted change 履歴粒度）が、tasks.md §5 Blocking Dependencies / §1〜§2 のいずれにも「これらは tasks alignment gate で詰める未確定事項」として明示されない。評価 tasks.md §5 は同種の design open issue を「後段 alignment で詰める」と明示しており非対称。根拠 = Task 5（replay/backtest）と Task 6（adoption の version_update_ref）は未解決の open issue に実装が依存するが、tasks.md がその未確定性を blocking として持ち上げていない。推奨対応 = §5 に「design open issue 4 件（version update 参照法・schema change 最小 replay・workflow-only replay 境界・paper-interface 履歴粒度）は tasks alignment gate で確定」を 1 行追加。重大度 = 軽微（design 既存節の blocking 持ち上げ漏れ。実装は可能だが未確定性が不可視）。必要性判定 = 自動採択（評価 tasks との非対称補修、致命的デメリットなし）。

### 該当なし

design の主要構造要素（5 段 architecture、artifact layout、schema versioning、input model 全節、signal extraction 全節、proposal model 全節、replay/backtest 全節、decision/adoption、rollback、paper 分離、interfaces）は Task に漏れなく割当済み。観点 1 の致命・重要級の網羅漏れは検出せず。

---

## 観点 2: タスクの粒度と完了基準

### 要点

Task 1〜9 各々の作業量と完了条件の明示性を検査。タスク特有方針「1 タスクは半日〜数日」「完了判定基準は着手前確定（実装後の後付けは検証中立性を失う）」を適用。sibling（runtime/evaluation）が採用した「Task テスト の決定的検証ケースで pass」二重化の有無を照合。

### 詳細抽出

- 全 9 Task が「作業」「完了条件」を持つ。完了条件は説明可能性 + design Completion Criteria 対応で記述。
- sibling 比較: runtime tasks.md は重い実装 Task（Task 3/6/7）完了条件に「Task 11 の決定的検証ケースで pass する」を付与。evaluation tasks.md も Task 3/4/5/8 完了条件に「Task 9 の決定的検証ケースで pass する」を付与。self-improvement tasks.md は Task 1〜8 のどの完了条件にも「Task 9 の決定的検証ケースで pass」型の機械検証二重化が無く、定性基準（「説明できる」「阻止される」）に留まる。
- Task 9（テスト）完了条件は「design Completion Criteria 4 点を満たす」のみで、sibling が持つ「列挙 N 検証対象それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass する（着手前に客観基準を確定、TDD 先行）」型の客観基準が無い。

### 深掘り

- 所見 T2-A（重要）: 所在 = Task 9「テストを用意する」完了条件 / Task 1〜8 完了条件。問題 = Task 9 完了条件が「design Completion Criteria 4 点（signal 使い分け・artifact 所在・approval/adoption 区別・境界説明）を満たす」のみで、Task 9 作業項目に列挙される 4 検証対象（state machine 許可/不許可遷移、provenance 欠落時 proposal 阻止、test mode 3 要素分岐 + result_label 整合、adoption gate 3 条件 + rollback invalidation 起点起動）の各々に「固定入力→期待出力の決定的検証ケースが存在し pass する」という機械検証可能な客観基準が事前明示されない。かつ Task 4/5/6/7（state machine・replay 分岐・adoption gate・rollback）完了条件は「曖昧にせず構造化される」「禁止される」等の定性表現で、sibling が採った「Task 9 の決定的検証ケースで pass する」二重化が欠落。タスク特有方針「検証手段の事前確定」と CLAUDE.md TDD 原則に照らし、各 Task 完了判定が Task 9 テスト設計に依存しつつ Task 9 自身の判定基準が後送りで定義循環。根拠 = REVIEW_PROTOCOL 節 5「検証手段の事前確定（実装後の後付けは検証中立性を失う）」の明示要件。sibling 2 spec が同型補修を採択済みで本 spec のみ非対称。推奨対応 = Task 9 完了条件に sibling 同型の客観基準（4 検証対象それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass、着手前に客観基準確定・TDD 先行）を追加し、Task 4/5/6/7 完了条件に「Task 9 の決定的検証ケースで pass する」を 1 行追加。重大度 = 重要（検証中立性に直結、TDD 方針との不整合、sibling 非対称）。必要性判定 = 自動採択（タスク特有方針の明示違反の補修、sibling 2 spec で同型確定済み、複数選択肢なし、致命的デメリットなし）。
- 所見 T2-B（軽微）: 所在 = Task 2「input model を作る」。問題 = Task 2 は input 3 class + valid/invalid/exploratory distinction + provenance 保持/欠落阻止 + review-mode provenance（manual/runtime 区別）+ manual→runtime handoff boundary（非破壊上書き 4 field）+ imported external bundle provenance（source repo/revision/admission status）+ v2 supporting input の 7 サブ論点を 1 Task に内包。Requirement 1（受入 1〜6）+ Requirement 7（受入 1〜5）+ Requirement 8（受入 1〜5）の 3 要件 16 受入を 1 Task が担う最大規模 Task。粒度の目安「半日〜数日」を超える可能性。根拠 = 実装の重い論点が 1 Task に集中。ただし全て「input provenance の保持構造」という単一 remediation surface で、過剰分割の逆リスクもある。推奨対応 = サブタスク分解（3 class + valid/invalid 弁別 / manual↔runtime handoff / imported bundle provenance）を実装着手時に検討する旨を Task 2 に注記。重大度 = 軽微。必要性判定 = 利用者判断（分解の是非に複数の合理的選択肢、過剰分割の逆リスクあり、致命的影響なし）。

### 該当なし

Task 1/3/4/5/6/7/8 の粒度は半日〜数日相当で完了条件も列挙的。粒度過大による必須分解は Task 2 の注記候補（軽微）以外に検出せず。完了条件の存在自体（全 Task に「完了条件」節がある）は満たす。問題は機械検証性の二重化欠落（T2-A）に集約。

---

## 観点 3: 依存関係と順序

### 要点

tasks.md §2 実装順序（1→9）と §5 Blocking Dependencies、依存マップ §4.5 / §5.3 / §6 / §7 を突合。前提先行・循環・依存グラフ別表（10 件超ルール）を検査。

### 詳細抽出

- §2 順序: skeleton/versioning → input model → signal extraction → proposal model → replay/backtest → decision/adoption → rollback → paper 分離 → test。理由として「signal intake→proposal がないと test/decision が成立しない」「adoption は test gate と version update を前提」「rollback は invalidation 契約起点で decision/adoption 後」を明示。前提先行は妥当。
- §5 Blocking Dependencies: Task 2/3 が runtime step-level replay artifact + evaluation analysis output（classification index/metrics/caveat register）確定前提、Task 5 が foundation 実行メタデータ契約（要件 6）確定前提、Task 7 が foundation 無効化契約確定前提と明示。依存マップ §4.5 / §6 / §7 と整合。
- 循環依存: Task 間に明示的循環は無い。ただし T2-A の「各 Task 完了条件 ⇄ Task 9 テスト」は実質的な定義循環（テスト客観基準未確定なのに完了判定を要求）。
- Task 件数 = 9 件。タスク特有方針の「依存グラフ別表」要件は「10 件超」が閾値で本 spec は 9 件のため別表は必須要件には抵触しない（runtime 11 件・evaluation 9 件で evaluation も §5.1 を任意付与している点に留意）。

### 深掘り

- 所見 T3-A（重要）: 所在 = tasks.md §5 / §2 / 全 Task。問題 = Task 9 件で「10 件超」別表必須要件には抵触しないが、sibling の runtime（§5.1 Task 間依存グラフ・並列可明示）と evaluation（§5.1 Task 間依存グラフ。9 件でも付与）は Task 間依存グラフ小節を持つのに self-improvement tasks.md は §5 に外部 blocking のみ列挙し Task 間依存グラフ・並列実行可能タスクの小節が無い。特に Task 2 と Task 3 は §5 で同じ外部前提（runtime replay artifact + evaluation analysis output）に blocked だが、Task 2→Task 3 の内部一方向依存（input model 確定後に signal extraction）や Task 8（paper 分離）が Task 4 以降のどこに並列可かが §2 散文からしか読めない。根拠 = REVIEW_PROTOCOL 節 5「タスク特有の追加方針：依存グラフを別表で示し並列実行可能なタスクを明示」（10 件超は必須だが 9 件 sibling も整合のため付与）+ sibling 2 spec の同型小節との非対称。推奨対応 = §5 に sibling 同型の「§5.1 Task 間依存グラフ（§2 から導出。並列可を明示）」小節を追加（例: Task1→Task2→Task3→Task4→Task5→Task6→Task7、Task8 は Task4 以降と並列可、Task9 は全 Task と並走 TDD、外部前提 Task2/3=runtime/evaluation 確定・Task5=foundation 実行メタデータ・Task7=foundation 無効化が blocking）。重大度 = 重要（必須閾値未満だが sibling 非対称で横断整合ゲートで再検出される蓋然性が高い、内容は §2 から機械導出可能）。必要性判定 = 自動採択（sibling 2 spec で同型確定済み、§2 から機械導出可能、致命的デメリットなし）。
- 所見 T3-B（軽微）: 所在 = tasks.md §2 理由節 / Task 6・Task 7 順序。問題 = §2 は Task 6（decision/adoption）→ Task 7（rollback）順で「rollback は invalidation 契約を起点とするため decision/adoption 確定後に置く」と理由明示。これは妥当だが、Task 7 完了条件「motivating evidence の事後 invalidate が再評価/rollback を起動する」は foundation 無効化契約（§5 で Task 7 の blocking と明示）に加え、rollback 対象となる adopted change が Task 6 の adoption_register に連結保存されている前提に依存する。§2 理由は invalidation 起点のみ述べ adoption_register 依存に触れない。根拠 = Task 7 の rollback_register `adopted_change_ref` は Task 6 の adoption_register `adopted_change_ref` と参照整合する必要があるが、Task 6→Task 7 の内部 artifact 依存が §2 理由で部分的にしか説明されない。推奨対応 = §2 理由節に「rollback は adoption_register の adopted_change 連結を前提とするため Task 6 後」を 1 句追加（T3-A の依存グラフ小節追加で実質吸収可）。重大度 = 軽微。必要性判定 = 自動採択（順序理由の明示補強、T3-A と同時吸収可、致命的デメリットなし）。

### 該当なし

循環依存は実装順序上は無し（T2-A の定義循環は観点 2 で計上）。外部 blocking（runtime/evaluation/foundation 先行）は §5 が明示し依存マップ §4.5 / §5.3 / §6 / §7 と整合。前提先行の致命的違反（後続が前提より先）は検出せず。

---

## 観点 4: 要件 / 設計とのトレース

### 要点

各 Task の「根拠」行が要件番号・設計章を引いているか全件確認。Requirement 1〜8 の全受入が Task に被覆されるか突合。

### 詳細抽出（Task → 根拠）

- Task 1: design「Learning Artifact Layout」「Schema Versioning」、Requirement 2 受入 5、Requirement 5 受入 5。可。
- Task 2: Requirement 1（受入 1〜6）、Requirement 7（受入 1〜5）、Requirement 8（受入 1〜5）、design「Input Model §1〜§2.5」「v2 Supporting Inputs」。可。
- Task 3: Requirement 1 受入 5、design「Signal Extraction Model §1〜§4」「Proposal Normalization Rules」。可。
- Task 4: Requirement 2（受入 1〜5）、Requirement 4 受入 1、design「Proposal Model §1〜§4」。可。
- Task 5: Requirement 3（受入 1〜7）、design「Replay and Backtest Model §1〜§4」。可。
- Task 6: Requirement 4（受入 1〜5）、design「Decision and Adoption Model §1〜§3」。可。
- Task 7: Requirement 5（受入 1〜6）、design「Rollback Model」。可。
- Task 8: Requirement 6（受入 1〜5）、design「Separation from Paper Narrative」「Interfaces to Other Features」。可。
- Task 9: design「Completion Criteria」+ プロジェクト TDD 方針。可（要件番号は無いがテスト Task の性質上 design 章引用で妥当、sibling 同様）。

### 受入被覆突合（Requirement 1〜8 全受入）

- Requirement 1（受入 1〜6）: Task 2 が 1〜6 を引く（受入 5 は Task 3 も明示）。被覆。
- Requirement 2（受入 1〜5）: Task 4 が 1〜5 を引く（受入 5 first-class record も Task 4 作業項目に明示）。受入 5「accepted と rejected を first-class record」は Task 4（保持）+ Task 6（rejection_register 実体）に分散被覆。被覆。
- Requirement 3（受入 1〜7）: Task 5 が 1〜7 を引く（受入 7 foundation 実行メタデータ束縛は Task 5 完了条件にも明示）。被覆。
- Requirement 4（受入 1〜5）: Task 6 が 1〜5、受入 1（状態定義）は Task 4 state machine が担う旨も Task 4 根拠に明示。被覆。
- Requirement 5（受入 1〜6）: Task 7 が 1〜6 を引く。受入 5「失敗改善からの学習」は Task 1（長期保存）+ Task 7（履歴非削除）に分散被覆。被覆。
- Requirement 6（受入 1〜5）: Task 8 が 1〜5 を引く。被覆。
- Requirement 7（受入 1〜5）: Task 2 が 1〜5 を引く。被覆。
- Requirement 8（受入 1〜5）: Task 2 が 1〜5 を引く。被覆。

### 深掘り

- 所見 T4-A（軽微）: 所在 = Task 4 根拠行 / Requirement 4 受入 1 と Task 6。問題 = Requirement 4 受入 1（proposal review/approval/rejection/adoption の明示状態定義）は Task 4（state machine 実装）と Task 6（decision/adoption model）の双方が引く。Task 4 根拠は「Requirement 4 受入 1」を引き Task 6 根拠は「Requirement 4（受入 1〜5）」を引くため、受入 1 が Task 4 と Task 6 に分割される対応が tasks.md 本文で相互参照されず読者が突合を要する（runtime tasks の T4-A 所見と同型：Requirement 8 が Task 4/Task 10 に分割される際の相互参照欠落）。根拠 = トレース可読性の問題（抜けではなく分割明示の弱さ）。推奨対応 = Task 6 根拠行に「Requirement 4 受入 1 の state 定義実体は Task 4 が担当」と相互参照を 1 行付す（runtime T4-A と同型補修）。重大度 = 軽微。必要性判定 = 自動採択（トレース可読性補修、sibling 同型、致命的デメリットなし）。

### 該当なし

全 Task が要件番号 + 設計章（テスト Task は design 章）を引いており、トレース欠落（要件を引かない実装 Task）は検出せず。Requirement 1〜8 の全受入は Task 1〜8 に分散して引かれ、どの Task にも現れない受入基準は観点 1 突合と併せて検出せず。要件未カバーの致命・重要級は無し。

---

## 観点 5: 横断タスクの抽出

### 要点

複数 feature にまたがる作業（foundation 所有契約への参照、runtime/evaluation 所有 artifact への consumer 依存、命名統一）が独立タスク or 明示参照になっているか。consumer 側が「依存・再定義しない」になっているか。proposal が他 spec に暗黙の新義務を課さないか。他 5 spec 波及を検査。

### 詳細抽出（他 spec 所有 contract の参照整合）

- foundation 所有 schema versioning 規約（要件 3 受入 3、foundation tasks.md Task 5 が「versioned artifact とし silent な非互換編集を禁ずる旨を schema directory 規約に記す」と所有）: self-improvement Task 1 が「foundation 要件 3 受入 3 の versioning 規約に接続。スキーマ所有は self-improvement 側、foundation 規約には接続宣言のみ（foundation 修正不要）」と明示。consumer 側「接続宣言のみ・foundation 修正不要」になっている。整合。
- foundation 所有 実行メタデータ契約（要件 6、foundation tasks.md Task 3 `metadata_contract.yaml`）: self-improvement Task 5 が「test result artifact を foundation 要件 6 実行メタデータ契約に束縛し独立検証・無効化可能」「foundation_run_metadata_ref」と consumer 参照を明示。再定義しない。整合。
- foundation 所有 無効化伝播義務（要件 6 受入 9、foundation tasks.md が「無効化標識付与が下流派生成果物への陳腐化伝播義務を伴うことを contract 化、具体的フラグ付け/再導出は evaluation/paper-interface に委ねる」）: self-improvement Task 7 が「foundation 無効化契約（foundation 要件 6）を起点に再評価または rollback を起動」と consumer 参照を明示。再定義しない。整合。
- runtime 所有 replay 入力 artifact（`review_case.json` / `steps/*.json` / decision units / validator・invalidation artifacts / `run_manifest.yaml` / `v2/trace_note.json` / `v2/signal_linkage_note.json`）: self-improvement Task 2/5 が runtime 所有 artifact を入力として参照。runtime tasks.md §4 Downstream Handoff の self-improvement 列挙（step files / decision units / validator・invalidation artifacts / `derived/invalid_run_triage_note.json` / `failures/failure_observation.json`、特に Step B・Step C を replay 入力に）と命名一致。runtime Task 5/6/7/8 が producer 側を所有。consumer 側は依存のみで再定義せず。整合。
- runtime 所有 `comparison_eligibility_note.json`（評価 A-7 で runtime 所有スキーマと確定、runtime tasks.md Task 1/6 が producer 側を所有・最小 6 項目）: self-improvement Task 2/5 が `derived/comparison_eligibility_note.json` を optional supporting input として参照。再定義せず。整合。
- evaluation 所有 analysis output（`run_classification_index.json` / `run_metrics.json` / `finding_metrics.json` / `caveat_register.json`、evaluation tasks.md §4 Downstream Handoff の self-improvement 列挙）: self-improvement Task 5 が backtest 最低入力として参照、Task 3 が evaluation 由来 signal を抽出。命名一致（evaluation tasks.md は `run_classification_index.json` を self-improvement 向けに列挙、self-improvement Task 5 も同名参照）。consumer 側は依存のみで再定義せず。整合。
- runtime `runtime_validation_summary.schema.json`（`scripts/track_runs/contracts/runtime_validation_summary.schema.json` を canonical contract）: self-improvement Task 3 が「runtime validation summary は同 schema を canonical contract とし track 間で payload shape を揃える」と参照。

### 深掘り

- 所見 T5-A（重要）: 所在 = self-improvement Task 3 作業項目 / runtime tasks.md。問題 = self-improvement Task 3 は「runtime validation summary は `scripts/track_runs/contracts/runtime_validation_summary.schema.json` を canonical contract とし track 間で payload shape を揃える」と記し、`scripts/track_runs/contracts/` 配下の schema を canonical として参照する。これは runtime / foundation 側が所有・固定すべき contract artifact だが、(a) self-improvement tasks.md は「どの spec が `runtime_validation_summary.schema.json` を所有・生成するか」を consumer 注記なしに canonical 前提として引用しており、(b) runtime tasks.md §4 / 全 Task に `runtime_validation_summary.schema.json` を runtime owner として固定する作業項目が見当たらず（runtime tasks は `scripts/{protocol_runners,track_runs}/` 配置のみ Task 1 で言及、validation summary schema の owner タスクは未分解）。これは self-improvement proposal が runtime 側に「track 間で payload shape を揃える共通 contract を固定せよ」という暗黙の新義務を課す形になっており、producer 側 owner タスクが横断で未確定なまま consumer が canonical 依存している。runtime tasks-local-review T5-A（`comparison_eligibility_note.json` の producer 側欠落）と同型の片肺だが、本件は self-improvement → runtime への越境義務付与の方向。根拠 = REVIEW_PROTOCOL 節 5 観点 5「proposal が他 spec に暗黙の新義務を課さないか」「consumer 側で依存・再定義しない形か」。self-improvement 側で canonical 宣言しているが所有 spec が横断で未明示。推奨対応 = self-improvement Task 3 作業項目に「`runtime_validation_summary.schema.json` の所有 spec を明示参照し、self-improvement は consumer として依存・再定義しない（owner 側未固定なら tasks alignment gate 議題に上げる）」旨へ書き換え、§5 に当該 schema owner 確定を blocking/alignment 議題として持ち上げる。重大度 = 重要（致命ではないが横断越境の owner 未確定 + 暗黙義務付与、横断整合ゲートで再検出される蓋然性が高い）。必要性判定 = 利用者判断（owner を runtime/foundation のどちらに置くか、または self-improvement local contract に降格するかに複数の合理的選択肢があり、横断構造決定として規律 `discipline_ssot_structural_decision_check.md` 上も依存マップに明示がないため利用者確認が要る）。
- 所見 T5-B（軽微）: 所在 = self-improvement Task 2 / runtime tasks.md §4。問題 = Task 2 は runtime/evaluation 所有の v2 supporting input（`run_manifest.yaml` / `v2/signal_linkage_note.json` / `v2/trace_note.json` / `derived/comparison_eligibility_note.json`）を「読めなくても基本 flow が維持される」と consumer 依存で正しく扱うが、`v2/signal_linkage_note.json` / `v2/trace_note.json` は runtime tasks.md §4 Downstream Handoff の self-improvement 列挙（step files / decision units / validator・invalidation artifacts / `derived/invalid_run_triage_note.json` / `failures/failure_observation.json`）に明示列挙されていない（runtime §4 は self-improvement 向けに trace_note/signal_linkage_note を挙げず、evaluation 向けにのみ v2 optional を挙げる）。self-improvement Task 2/3 はこれらを補助入力として参照するため、runtime §4 の self-improvement 行と self-improvement Task 2 参照集合に非対称がある。根拠 = 横断 artifact の producer 側公開列挙と consumer 側参照集合の片側非対称（命名衝突ではなく公開漏れ）。推奨対応 = 記録のみ（self-improvement 側は「読めなくても基本 flow 維持」で耐性設計済みのため self-improvement tasks 変更不要。runtime §4 の self-improvement 行に v2 optional supporting input を追記すべきかは tasks alignment gate の横断議題として持ち上げる）。重大度 = 軽微。必要性判定 = 自動採択（self-improvement 側は記録のみで修正不要、横断議題への持ち上げのみ、致命的デメリットなし）。

### 他 5 spec 波及（明示記録）

- foundation tasks.md: 波及なし（self-improvement は consumer。schema versioning 規約・metadata contract・無効化伝播義務への参照は「接続宣言のみ・foundation 修正不要」と Task 1/5/7 が明示。foundation tasks への修正要求は本観点から発生せず）。
- runtime tasks.md: 波及あり（T5-A 関連で `runtime_validation_summary.schema.json` の owner 確定が runtime 側に要る可能性、T5-B 関連で runtime §4 self-improvement 行への v2 optional 追記候補。いずれも tasks alignment gate 横断議題として持ち上げ、self-improvement tasks 単独修正では閉じない）。
- evaluation tasks.md: 波及なし（self-improvement Task 3/5 は evaluation analysis output を consumer 参照し命名一致。evaluation tasks.md §4 の self-improvement 列挙と整合。修正波及なし）。
- paper-interface tasks.md: 波及なし。self-improvement Task 8 / §4 は「paper-interface は self-improvement proposal を narrative source としない、adopted changes 履歴は methodology note 参照に留める」と consumer 境界を明示。design「Interfaces」と整合。命名衝突なし。
- implementation-governance tasks.md: 波及なし。governance は self-improvement に review dependency のみ（依存マップ §4.7）、feature data contract を生成しない。命名衝突検出せず。

命名衝突の全 spec 横断検査: `review_case.json` / `run_manifest.yaml` / `comparison_eligibility_note.json` / `run_classification_index.json` / `run_metrics.json` / `finding_metrics.json` / `caveat_register.json` / `invalidation_markers.json` / `failure_observation.json` は producer（runtime/evaluation/foundation）と consumer（self-improvement）で同一綴り・同一意味で参照され、衝突・別義使用は検出せず。self-improvement 固有 artifact（`proposals/<id>.yaml` / `backtests/<id>.json` / `adoption_register.json` / `rejection_register.json` / `rollback_register.json` / `recurring_failure_signals.json` / `pattern_candidates.json` / `workflow_remediation_templates.json`）は他 spec と命名衝突なし。

---

## 観点 6: 失敗時の巻き戻し単位

### 要点

Task 失敗時の影響範囲・巻き戻し単位（handback class A/B/C/D 紐付け小節）が明示されているか。sibling（runtime §5.2 / evaluation §5.2）の同型小節有無を照合。

### 詳細抽出

- tasks.md §5 Blocking Dependencies は前提未充足時の blocked を示すが、各 Task の「失敗時にどこまで巻き戻すか」（task-local 吸収 / handback B design / handback C requirements）の明示が無い。
- sibling 比較: runtime tasks.md §5.2「失敗時の巻き戻し単位」（Task 1〜5/10 task-local、Task 6/7/9 で foundation 契約不足判明なら handback C）、evaluation tasks.md §5.2「失敗時の巻き戻し単位」（handback A/B/C を Task 別に明示、判定迷い時は保守規律で C 上流寄せ）が存在。self-improvement tasks.md には §5.2 相当の「失敗時の巻き戻し単位」小節が無い。
- design Decision 4「Rollback remains part of learning history」+ Task 7（failed improvement 履歴非削除、非破壊上書き）が self-improvement の「実行時（learning loop 動作時）」の巻き戻しは履歴非削除・supersession 区別で単位を内包するが、これは feature 動作時 rollback であって「Task 実装中の失敗 handback 単位」とは別物。

### 深掘り

- 所見 T6-A（重要）: 所在 = tasks.md §5（巻き戻し単位小節の欠落）。問題 = WORKFLOW_OVERVIEW.md 節 4 の handback class（A/B/C/D）に照らし、Task 実装中の失敗が task-local 吸収か design handback（B）か requirements handback（C）かを判定する単位が tasks.md に無い。特に Task 1（schema versioning、foundation 要件 3 受入 3 接続）・Task 5（backtest artifact の foundation 実行メタデータ契約束縛）・Task 7（foundation 無効化契約起点 rollback）は foundation 契約への接続が前提のため、実装中に foundation 契約不足が判明した場合 handback C 相当に上流戻しが要るが、その巻き戻し単位が未明示。sibling 2 spec（runtime/evaluation）が §5.2 で同型小節を確定済みで本 spec のみ非対称。根拠 = REVIEW_PROTOCOL 節 5 観点 6「タスク失敗時の影響範囲・巻き戻し単位の明示」+ 本観点が「handback class 紐付け小節の有無」を要件化。sibling 2 spec の §5.2 と非対称。推奨対応 = §5 に sibling 同型の「§5.2 失敗時の巻き戻し単位」小節を追加（例: Task 1〜4/6/8 は task-local 吸収（handback A）、Task 1/5/7 で foundation 契約（schema versioning 規約/実行メタデータ契約/無効化契約）不足が判明したら handback C で foundation へ、Task 2/3 で runtime replay artifact または evaluation analysis output shape 不足が判明したら handback C で当該 producer へ、判定に迷う場合は保守規律により C 上流へ寄せる、learning loop 動作時の rollback は履歴非削除・supersession 区別で raw 不変）。重大度 = 重要（design の履歴非削除で feature 動作時巻き戻しは担保されるが、開発時 handback 単位が未明示で sibling 非対称、横断整合ゲートで再検出される蓋然性）。必要性判定 = 自動採択（観点 6 の明示要件 + sibling 2 spec で同型確定済み、内容は WORKFLOW_OVERVIEW 節 4 と §5 から導出可能、致命的デメリットなし）。

### 該当なし

learning loop 動作時の巻き戻し（feature runtime 動作時）は Task 7（failed improvement 履歴非削除、rollback と supersession 区別、非破壊上書き）が単位を内包しており、致命級の動作時巻き戻し単位欠落は検出せず。所見は開発時 handback 単位小節の欠落（重要、sibling 非対称）に集約。

---

## 観点 7: 波及精査（最終ガード）

### 要点

観点 1〜6 の推奨対応が他 Task・他 feature へ生む連鎖を最終確認。波及あり/なしを全件明示。

### 変更候補リスト化（観点 1〜6 の推奨対応）

- T1-A: §5 に design open issue 4 件を alignment 議題として明示 → 波及精査
- T2-A: Task 9 完了条件に sibling 同型客観基準、Task 4/5/6/7 にテスト参照 → 波及精査
- T2-B: Task 2 にサブタスク分解注記 → 波及精査
- T3-A: §5 に §5.1 Task 間依存グラフ小節追加 → 波及精査
- T3-B: §2 理由節に adoption_register 依存を 1 句追加 → 波及精査
- T4-A: Task 6 根拠行に Requirement 4 受入 1 の Task 4 相互参照 → 波及精査
- T5-A: Task 3 の `runtime_validation_summary.schema.json` owner 明示 + §5 alignment 議題持ち上げ → 波及精査
- T5-B: 記録のみ（runtime §4 への追記候補は alignment 議題） → 波及精査
- T6-A: §5 に §5.2 失敗時の巻き戻し単位小節追加 → 波及精査

### 波及判定（全件明示）

- T1-A 波及: なし（§5 内の blocking/alignment 議題明示。design 既存節の持ち上げで要件・設計不変。他 spec 不変）。
- T2-A 波及: self-improvement 内 Task 4/5/6/7/9 に閉じる。他 spec 波及なし（テスト客観基準は self-improvement ローカル、foundation/runtime/evaluation の契約に触れない。sibling 同型化のため横断整合性はむしろ向上）。
- T2-B 波及: なし（Task 2 注記のみ、分解は実装判断）。
- T3-A 波及: self-improvement 内 §5/§2 に閉じる。内容は §2 散文から機械導出、新依存を生まない。他 spec 波及なし。
- T3-B 波及: なし（§2 理由の明示補強、T3-A 依存グラフ小節で実質吸収可、要件・設計不変）。
- T4-A 波及: なし（トレース可読性補修、要件・設計不変、self-improvement 内 Task 6 根拠行のみ）。
- T5-A 波及: runtime tasks.md に波及（`runtime_validation_summary.schema.json` owner 確定が runtime 側に要る可能性、tasks alignment gate 横断議題）。self-improvement tasks 単独修正では閉じず、横断ゲートでの owner 決定 + 利用者判断を要する。foundation/evaluation/paper-interface/governance への修正波及なし。
- T5-B 波及: runtime tasks.md §4 self-improvement 行への v2 optional 追記候補（記録のみ、tasks alignment gate 横断議題）。self-improvement tasks 変更不要。
- T6-A 波及: なし（§5 内小節追加、WORKFLOW_OVERVIEW 節 4 既存概念の参照、sibling 同型化で横断整合性向上。上位文書改版不要）。

### 連鎖更新漏れ精査

観点 1〜6 の推奨対応のうち T1-A/T2-A/T2-B/T3-A/T3-B/T4-A/T6-A は self-improvement tasks.md 内の作業項目・完了条件・節追加に閉じ、要件書・設計書・spec.json の改版を要さない。T5-A / T5-B のみ runtime tasks.md への横断波及（owner 確定 / §4 追記候補）があり、これは self-improvement tasks 単独では閉じず tasks alignment gate の横断議題として持ち上げる必要がある（T5-A は利用者判断要）。他 4 spec（foundation/evaluation/paper-interface/governance）tasks への修正波及は 0 件。連鎖更新漏れ（self-improvement 内で観点間矛盾を生む推奨対応）は検出せず。

---

## 集計

### 重大度別件数

- 致命: 0 件
- 重要: 4 件（T2-A / T3-A / T5-A / T6-A）
- 軽微: 5 件（T1-A / T2-B / T3-B / T4-A / T5-B）
- 合計: 9 件

### 必要性判定別

- 自動採択（致命的デメリットなし、複数合理選択肢なし）: 7 件 — T1-A / T2-A / T3-A / T3-B / T4-A / T5-B / T6-A
- 利用者判断（複数の合理的選択肢が残る / 横断構造決定）: 2 件 — T2-B（Task 2 サブタスク分解の是非）/ T5-A（`runtime_validation_summary.schema.json` の owner をどこに置くか＝横断構造決定、依存マップ未明示で `discipline_ssot_structural_decision_check.md` 該当）

### must-fix 候補一覧

- T2-A（重要・自動採択）: Task 9 完了基準が後送りで各 Task 完了判定と定義循環。Task 9 に sibling 同型の客観基準（4 検証対象ごと固定入力→期待出力の決定的検証ケース存在・pass）を事前明示、Task 4/5/6/7 に「Task 9 の決定的検証ケースで pass」を付加。
- T3-A（重要・自動採択）: sibling 2 spec が持つ §5.1 Task 間依存グラフ小節が self-improvement のみ欠落。§5 に §5.1 を追加（§2 から機械導出、並列可明示）。
- T5-A（重要・利用者判断）: `runtime_validation_summary.schema.json` の owner spec が横断未確定なまま self-improvement が canonical 依存（暗黙の越境義務付与）。Task 3 を consumer 注記へ書き換え + §5 に owner 確定を alignment 議題として持ち上げ。owner 配置は利用者判断。
- T6-A（重要・自動採択）: sibling 2 spec が持つ §5.2 失敗時の巻き戻し単位小節が self-improvement のみ欠落。§5 に §5.2 を追加（handback A/B/C を Task 別に紐付け）。
- T1-A（軽微・自動採択）: §5 に design open issue 4 件を alignment 議題として明示（評価 tasks との非対称補修）。
- T2-B（軽微・利用者判断）: Task 2 にサブタスク分解検討の注記。
- T3-B（軽微・自動採択）: §2 理由節に rollback の adoption_register 依存を 1 句追加（T3-A で実質吸収可）。
- T4-A（軽微・自動採択）: Task 6 根拠行に Requirement 4 受入 1 の Task 4 相互参照（runtime T4-A 同型）。
- T5-B（軽微・自動採択）: 記録のみ（self-improvement 修正不要、runtime §4 追記候補を alignment 議題に）。

### 観点ごと該当なし概況

- 観点 1: 主要構造の網羅漏れ該当なし（軽微 1 件 T1-A は design open issue の blocking 持ち上げ漏れ、致命・重要の構造網羅漏れなし）。
- 観点 2: 必須分解を要する過大タスク該当なし（Task 2 は軽微注記候補）。問題は機械検証性二重化欠落（T2-A）に集約。
- 観点 3: 循環依存・致命的順序違反は該当なし（重要 1 件 T3-A は sibling 非対称の依存グラフ小節欠落、軽微 1 件 T3-B は順序理由の明示補強）。
- 観点 4: トレース欠落（要件を引かない Task・どの Task にも無い受入）該当なし（軽微 1 件 T4-A は分割明示の弱さ）。
- 観点 5: foundation/runtime/evaluation 所有契約の参照不整合・命名衝突は該当なし（重要 1 件 T5-A は横断 owner 未確定 + 暗黙義務付与、軽微 1 件 T5-B は producer 側公開列挙の片側非対称で記録のみ）。
- 観点 6: feature 動作時巻き戻し単位の欠落該当なし（重要 1 件 T6-A は開発時 handback 単位小節の sibling 非対称欠落）。
- 観点 7: self-improvement 内連鎖更新漏れ該当なし。他 spec 修正波及は T5-A/T5-B の runtime 横断のみ（残 4 spec 0 件）。

### 他 5 spec tasks 波及件数

- 修正波及（横断議題持ち上げ要）: runtime tasks.md 2 件（T5-A owner 確定 = 利用者判断、T5-B §4 追記候補 = 記録のみ）。いずれも self-improvement tasks 単独では閉じず tasks alignment gate の横断議題。
- foundation / evaluation / paper-interface / implementation-governance: 波及なし（命名整合・参照整合・consumer 境界確認済み、修正波及 0 件）。

### 総合所見

致命 0 件。重要 4 件・軽微 5 件。重要 4 件のうち T2-A / T3-A / T6-A は sibling 2 spec（runtime/evaluation）の tasks-local-review で同型補修が確定済みの非対称欠落であり、self-improvement tasks.md が前半の全面再導出時に sibling と同等の構造小節（§5.1 Task 間依存グラフ / §5.2 失敗時巻き戻し単位 / Task 完了条件のテスト二重化）を欠いたまま生成された工程不遵守の帰結。これら 3 件は self-improvement tasks.md 内に閉じ自動採択で補修すれば横断整合性が向上する。T5-A（`runtime_validation_summary.schema.json` の横断 owner 未確定 + 暗黙の越境義務付与）は唯一の横断構造決定で、owner 配置に複数の合理的選択肢があり依存マップにも明示がないため利用者判断を要する（規律 `discipline_ssot_structural_decision_check.md` 該当）。

横断整合ゲートへの進行可否: must-fix 候補（特に sibling 非対称の T2-A / T3-A / T6-A、横断 owner の T5-A）を 1 件ずつ承認で適用してから tasks alignment gate（依存マップ §5.3 の 6 番目）へ進むことを推奨する。未適用のまま横断ゲートへ進むと、sibling 3 spec（runtime/evaluation/self-improvement）間の tasks 構造の非対称（依存グラフ小節・巻き戻し単位小節・テスト二重化の有無）と T5-A の片肺越境が横断検査で確実に再検出される。軽微 5 件のうち T1-A/T3-B/T4-A/T5-B は自動採択で同時適用してよい。T2-B（Task 2 分解の是非）と T5-A（owner 配置）は利用者判断後に確定。修正適用後は本観点 7 の波及精査どおり他 4 spec への連鎖が 0 件、runtime 横断 2 件は alignment 議題に持ち上げ済みであることを再確認すれば横断ゲート進行の前提が整う。

### 証跡パス

`/Users/Daily/Development/Rwiki-v2-code-mod/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/reviews/tasks-local-review-2026-05-18.md`
