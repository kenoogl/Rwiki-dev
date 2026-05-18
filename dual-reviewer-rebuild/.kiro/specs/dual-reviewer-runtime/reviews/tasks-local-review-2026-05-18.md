# Tasks Local Review — dual-reviewer-runtime

- 実施日: 2026-05-18
- 方式: 独立タスク個別レビュー（REVIEW_PROTOCOL 節 5、7 観点を網羅実施）
- 起草との独立性: 本セッション前半でタスクを全面再導出した工程の独立批判視点。起草者と分離した検査として実施
- 入力（すべて絶対パス）:
  - 主対象: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/tasks.md`
  - 設計正本: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/design.md`
  - 要件参照: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md`（Requirement 1〜9、Requirement 10 削除済み）
  - 横断参照: foundation / evaluation / self-improvement / paper-interface / implementation-governance の tasks.md
  - 上位正本: `operations/REVIEW_PROTOCOL.md` 節 5、`docs/alignment/phase-and-feature-dependency-map.md`、`CONVENTIONS.md`
- 不変条件: 本ファイルは生証跡。tasks.md / design.md / requirements.md / spec.json は本レビューで変更しない（所見のみ）

---

## 0. 依存マップ確認結果（横断・順序判断の前提）

`docs/alignment/phase-and-feature-dependency-map.md` を確認した。判断に効く点は次。

- §4.3 / §4.4: runtime は foundation に `hard dependency`、evaluation / self-improvement に `interface dependency`。runtime は producer、foundation の consumer。
- §5.3 tasks wave 推奨順序: foundation → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance。runtime tasks は foundation tasks の後段。
- §6 / §7 tasks alignment checklist: 「runtime export 実装より前に foundation provenance field が固まっているか」「foundation artifacts を runtime/evaluation が参照可能になる順序」が最低限の確認対象。
- §8.1: prescribed workflow process は workflow execution ledger を前提とするが、本タスク文書は runtime feature の実装単位分解であり、process 段集合の権威ソースではない（authority-map 対象外）。
- 結論: runtime tasks の blocking dependency（tasks.md §5）が foundation を先行条件として明示しているのは依存マップ §5.3 / §6 / §7 と整合。横断順序の即興導出はせず、本正本に従って観点 3 / 5 を判定した。

横断構造決定（feature 間依存・順序）について本正本に明示のない新規事項は本レビューで検出せず（規律 `discipline_ssot_structural_decision_check.md` 該当なし）。

---

## 観点 1: 設計全件の網羅

### 要点

design.md の構成要素を列挙し、tasks.md の Task 1〜11 への割当を全件突合した。

### 詳細突合（design 構成要素 → 担当 Task）

- Architecture 4 役（session controller / step executors / evidence writer / validation bridge）→ Task 2 / 3 / 6 / 7。網羅。
- v2 Internal Structure（Case Manifest / Analysis / Decision / Writer 4 層）→ Task 1（code 配置 `runtime/execution_v2/{manifests,analyzers,decisions,writers,contracts}/`）+ Task 6（writer）。配置は網羅。
- Runtime Artifact Layout（run directory 全体）→ Task 1 が directory ツリー全件を列挙。網羅。
- v2 Compatibility Rule（互換 4 artifact 維持 + v2 追加）→ Task 1 + Task 6。網羅。
- Session Model §1 Run Lifecycle → Task 2。網羅。
- Session Model §2 Session Inputs / §Run Manifest Field Set（開始時固定群 / 実行中更新群）→ Task 2 が両群を列挙。網羅。
- `evidence_class` 初期値 `candidate` 記録と確定遷移委譲 → Task 2。網羅。
- Session Model §3 Phase/Profile and Treatment Axes → Task 2 + Task 10。網羅。
- Reference-Free Runtime Entry Principle / Generic Protocol Entrypoint Rule → Task 2。網羅。
- Step Execution Model A/B/C/D（入出力・保存先・Step B forced-divergence・Step D 6 手順）→ Task 3。網羅。
- Treatment × Step Execution Matrix（3 値 executed/skipped/reduced、marker record 4 項目）→ Task 3。網羅。
- Prompt Resolution Model / Role and Step Mapping / Prompt Identity Recording → Task 4。網羅。
- Decision Unit Model / Human Sign-off Record → Task 5。網羅。
- Evidence Writing Model（Raw vs Derived 3 層、`review_case.json` 正本、A-5 投影規約、failure_observation）→ Task 6。網羅。
- File Placement for v2 Runtime Core（配置規約・3 つの混在禁止ルール）→ Task 1。網羅。
- `review_case.json` 節（canonical envelope、ref 中心構成）→ Task 6。網羅。
- Validator Integration / Run Close Boundary / Validation Outcomes → Task 7。網羅。
- Invalidation Handling（自動 marker 4 種・human-issued marker・triage note）→ Task 8。網羅。
- Portable Evidence Bundle Export（Export Boundary / Bundle Shape）→ Task 9。網羅。
- Phase-Aware Review Profiles（emphasis 初版）→ Task 10。網羅。
- Testability Seams（4 縫い目）→ Task 11。網羅。
- Interfaces to Downstream Features（evaluation/self-improvement/paper-interface）→ tasks.md §4 Downstream Handoff。網羅。
- Key Decisions 1〜4 → 各 Task の根拠記述に分散反映。網羅。

### 深掘り — 設計に存在するが Task に明示反映が弱い要素

- 所見 T1-A（軽微）: 所在 = design「Case Manifest and Heuristic Resolution Model」（base required fields `case_id`/`track`/`source_refs`/`case_manifest_ref`、track-required fields）。問題 = Task 2 は reference-free entry で `case_manifest_ref` 無し時の track 必須入力 fail-fast に触れるが、case manifest の base required field 集合（`case_id`/`track`/`source_refs`/`case_manifest_ref`）と track-required field の実装単位が Task のどこにも明示分解されていない。根拠 = 実装者が case manifest schema をどの Task で固めるか曖昧。design に該当節があるのに Task に欠ける。推奨対応 = Task 2 作業項目に「case manifest の base required fields / track-required fields を `runtime/execution_v2/manifests/` で固定する」を 1 行追加。重大度 = 軽微（reference-free entry 記述で実質カバーされ実装は可能だが、明示が弱い）。必要性判定 = 自動採択（致命的デメリットなし、design 節の明示分解漏れの補修）。
- 所見 T1-B（軽微）: 所在 = design「v2 Internal Structure / Components」。問題 = `v2/metric_snapshot.json` が Runtime Artifact Layout に存在し Task 1 のツリーにも列挙されるが、その生成責務（誰がいつ何を書くか）がどの Task の作業項目にも明示されない（Task 6 evidence writing は `v2/review_artifact.json`/`trace_note.json`/`signal_linkage_note.json` を挙げるが `metric_snapshot.json` を挙げない）。根拠 = layout には在るが書き手が未分解 → 実装で空 artifact になる懸念。推奨対応 = Task 6 の v2 internal 層列挙に `v2/metric_snapshot.json` を追加するか、derived 扱いである旨を注記。重大度 = 軽微。必要性判定 = 自動採択（design layout と writer 分解の整合補修、致命的デメリットなし）。

### 該当なし

設計の主要構造要素（controller/step executors/evidence writer/validation bridge、run directory layout、v2 code 配置、prompt resolution、decision unit、portable bundle、phase profile、Testability Seams）は Task に漏れなく割当済み。観点 1 の致命・重要級の網羅漏れは検出せず。

---

## 観点 2: タスクの粒度と完了基準

### 要点

Task 1〜11 各々の作業量と完了条件の明示性を検査。タスク特有方針「1 タスクは半日〜数日」「完了判定基準は着手前確定」を適用。

### 詳細抽出

- 全 11 Task が「作業」「完了条件」を持ち、完了条件は説明可能性 + design Completion Criteria への対応で記述されている。
- Task 数 11 件（10 件超）→ タスク特有方針「依存グラフを別表で示す」が要件。tasks.md §5 Blocking Dependencies は記述されるが、並列実行可能タスクの明示や依存グラフ別表は無い（観点 3 で詳述）。

### 深掘り

- 所見 T2-A（重要）: 所在 = Task 11「テストと testability seams を用意する」。問題 = 完了条件が「design Testability Seams 4 点が検証できる」「Completion Criteria を満たす」で、検証手段（テストフレームワーク・固定応答の差替え機構の具体・成功判定値）は「詳細テスト計画は本タスク工程で策定する」と後送り。タスク特有方針「検証手段の事前確定（実装後の後付けは検証中立性を失う）」に照らすと、Task 1〜10 各々の完了判定が Task 11 のテスト設計に依存しつつ Task 11 自身の判定基準が未確定で循環的に曖昧。根拠 = 各 Task の「完了条件」が「説明できる」型の定性基準に留まり、テスト合格という客観基準が Task 11 へ集約されるが Task 11 が後送り。CLAUDE.md TDD 原則（先にテスト→失敗確認→実装）とも整合不足。推奨対応 = Task 11 完了条件に最低限の客観基準（4 seam ごとに「固定入力 X → 期待出力 Y の決定的検証ケースが存在し pass する」）を事前明示し、Task 3/6/7 完了条件に対応テストの参照を 1 行追加。重大度 = 重要（致命ではないが検証中立性に直結、TDD 方針との不整合）。必要性判定 = 自動採択（タスク特有方針「検証手段の事前確定」の明示違反の補修。複数選択肢なし、致命的デメリットなし）。
- 所見 T2-B（軽微）: 所在 = Task 3。問題 = Step A/B/C/D executor + treatment×step matrix + 3 値 execution state + Step B forced-divergence + Step D 6 手順を 1 Task に内包。粒度の目安「半日〜数日」を超える可能性（最大規模 Task）。根拠 = 実装の重い feature の観点 2 が厚くなる典型。ただし step executor は共通骨格の反復で、Task 11 の step 入出力分離 seam により分割検証可能なため過大とまでは断定しない。推奨対応 = サブタスク分解（Step A/B、Step C、Step D 統合）を実装着手時に検討する旨を Task 3 に注記。重大度 = 軽微。必要性判定 = 利用者判断（分解するかは複数の合理的選択肢があり、過剰分割の逆リスクもある。致命的影響なし）。

### 該当なし

Task 1/2/4/5/6/7/8/9/10 の粒度は半日〜数日相当で完了条件も列挙的。粒度過大による必須分解は Task 3 の注記候補（軽微）以外に検出せず。

---

## 観点 3: 依存関係と順序

### 要点

tasks.md §2 実装順序（1→11）と §5 Blocking Dependencies、依存マップ §5.3 / §6 / §7 を突合。前提先行・循環の有無を検査。

### 詳細抽出

- §2 順序: skeleton → controller → step executors → prompt → decision unit → evidence writing → validator/close → invalidation → export → phase profile → test。前提先行は概ね妥当（controller/step が先、export が close 後）。
- §5 Blocking Dependencies: Task 1 / 6 / 7 / 9 が foundation tasks 完了前提と明示。依存マップ §6 / §7 と整合。
- 循環依存: Task 間に明示的循環は無い。ただし観点 2 所見 T2-A の「各 Task 完了条件 ⇄ Task 11 テスト」は実質的な定義循環（テスト未確定なのに完了判定を要求）。

### 深掘り

- 所見 T3-A（重要）: 所在 = tasks.md §2 実装順序 / Task 4 prompt resolution と Task 3 step executors の順序。問題 = §2 は Task 3（step executors）→ Task 4（prompt resolution）の順だが、design Step Execution Model では各 step の入力に「primary/adversarial/judgment prompt set」が含まれ、Step executor は prompt resolution の結果を消費する。prompt 解決が後続だと Task 3 実装時に prompt identity recording（Requirement 3 受入 2・3）の前提が未確定。根拠 = design Step A 入力に「primary prompt set」、Step record に prompt identity 必須。prompt resolution model が後に来ると step executor の入力契約が宙に浮く。推奨対応 = §2 / §3 で Task 4（prompt resolution）を Task 3（step executors）より前に置く、または Task 3 の前提として Task 4 の prompt 解決契約を先行確定する旨を依存として明示。重大度 = 重要（順序の前提先行違反、ただし interface 定義の先行で吸収可能なため致命ではない）。必要性判定 = 利用者判断（順序入替か依存注記かに複数の合理的選択肢。step executor 骨格を prompt 抽象に対して先に書く実装戦略も成立しうるため、起草者意図の確認を要する）。
- 所見 T3-B（重要）: 所在 = tasks.md §5 Blocking Dependencies / 全 Task。問題 = Task 11 件（10 件超）に対しタスク特有方針は「依存グラフを別表で示し、並列実行可能なタスクを明示する」を要求するが、§5 は foundation への外部 blocking のみ列挙し、runtime 内 Task 間の依存グラフ・並列実行可能タスクの別表が無い。根拠 = REVIEW_PROTOCOL 節 5「タスク特有の追加方針」明示要件。推奨対応 = §5 または新節に Task 間依存グラフ（例: Task1→Task2→{Task3,Task4}→Task5→Task6→Task7→Task8、Task9 は Task7 後、Task10 は Task2 後で並列可、Task11 は全 Task と並走 TDD）を別表化。重大度 = 重要（方針の明示違反、ただし §2 直列順序で実装は可能）。必要性判定 = 自動採択（タスク特有方針の明示違反の補修、致命的デメリットなし、内容は §2 から機械的に導出可能）。

### 該当なし

循環依存は実装順序上は無し（T2-A の定義循環は観点 2 で計上）。foundation 先行という外部依存は §5 が明示し依存マップと整合。

---

## 観点 4: 要件 / 設計とのトレース

### 要点

各 Task の「根拠」行が要件番号・設計章を引いているか全件確認。

### 詳細抽出

- Task 1: Requirement 1 受入 6、design「Runtime Artifact Layout」「File Placement」。可。
- Task 2: Requirement 1（受入 1〜6）、Requirement 8（受入 1・3・5）、design §1〜§3 ほか。可。
- Task 3: Requirement 1（1〜4）、Requirement 2（1〜5）、design Step Execution / Matrix。可。
- Task 4: Requirement 3（1〜5）、Requirement 8 受入 6、design Prompt 系。可。
- Task 5: Requirement 5（1〜5）、design Decision Unit / Sign-off。可。
- Task 6: Requirement 4（1〜7）、Requirement 7（1〜5）、design Evidence Writing、A-5。可。
- Task 7: Requirement 6（1〜9）、design Validator / Close / Outcomes。可。
- Task 8: Requirement 6（3・7・8）、design Invalidation。可。
- Task 9: Requirement 9（1〜5）、design Portable Bundle。可。
- Task 10: Requirement 8（1〜5）、design Phase-Aware Profiles。可。
- Task 11: design「Testability Seams」「Completion Criteria」+ プロジェクト TDD 方針。可（要件番号は無いがテスト Task の性質上 design 章引用で妥当）。

### 深掘り

- 所見 T4-A（軽微）: 所在 = Task 4 根拠行 / Requirement 8 受入 2・4。問題 = Task 4 は Requirement 8 受入 6（prompt override 所有）を引くが、Task 10（phase profile）は Requirement 8 受入 1〜5 を引く。Requirement 8 受入 2「canonical Step A/B/C/D state machine を変えず emphasis 切替」と受入 4「design/tasks は強い構造・依存指向」は Task 10 が引くため重複漏れは無いが、Requirement 8 が Task 4 と Task 10 に分割される対応が tasks.md 本文で明示されず読者が突合を要する。根拠 = トレース可読性の問題（抜けではなく分割明示の弱さ）。推奨対応 = Task 10 根拠行に「Requirement 8 受入 6 は Task 4 が担当」と相互参照を 1 行付す。重大度 = 軽微。必要性判定 = 自動採択（トレース可読性補修、致命的デメリットなし）。

### 該当なし

全 Task が要件番号 + 設計章を引いており、トレース欠落（要件を引かない Task）は検出せず。Requirement 1〜9 の各受入は Task 1〜10 に分散して引かれ、Requirement 10 削除済みは tasks.md §1 で明示されている。要件未カバー（どの Task にも現れない受入基準）は観点 1 突合と併せて検出せず。

---

## 観点 5: 横断タスクの抽出

### 要点

複数 feature にまたがる作業（共通契約参照順序、A-5/A-7 越境規約、命名統一、移行）が独立タスク or 明示参照になっているか。foundation 所有語彙の参照整合と他 5 spec 波及を検査。

### 詳細抽出（foundation 所有 contract の参照整合）

- foundation 所有 `validator_status` enum（`not_run`/`passed`/`failed`/`blocked`）: runtime Task 7 が「foundation 所有の正準 enum をそのまま伝播、再定義・丸め・別トークン化しない」と明示。foundation tasks.md Task 3 / Task 8 の所有宣言と整合。横断参照規約は明示参照になっている。
- foundation 所有 metadata contract: runtime Task 2 が「foundation §Run Metadata Contract を継承し再定義しない」と明示。foundation tasks.md Task 3 と整合。
- foundation `failure_observation` schema: runtime Task 6 が foundation schema 準拠で emit、未使用 schema 放置禁止を明示。foundation tasks.md Task 4 と整合。
- foundation prompt placement/identity: runtime Task 4 が foundation canonical path 優先、runtime override は runtime 所有と明示。foundation tasks.md Task 6 と整合。

### 詳細抽出（A-5 / A-7 越境規約）

- 実行側 A-5（`review_case.json` を唯一の横断正本、`review_artifact.json` 投影規約は runtime 所有）: runtime Task 6 作業項目に明示。Task 6 完了条件・tasks.md §6 Completion Criteria にも明示。evaluation tasks.md Task 2/3 は `review_case.json` を一次入力として読む側で整合。越境規約は明示参照済み。
- 評価 A-7（`comparison_eligibility_note.json` スキーマは生成元 runtime 所有、最小項目 `run_id`/`eligible_for_standard_comparison`/`ineligibility_reason_codes`/`treatment`/`phase_profile`/`generated_at`）: runtime Task 1 が `derived/comparison_eligibility_note.json` を layout に置く。

### 深掘り

- 所見 T5-A（重要）: 所在 = runtime Task 1 / Task 6 と評価 A-7。問題 = 評価 A-7 決定で `comparison_eligibility_note.json` のスキーマ所有は生成元 runtime と確定し、design「v2 Compatibility Rule」に最小項目（`run_id`/`eligible_for_standard_comparison`/`ineligibility_reason_codes`/`treatment`/`phase_profile`/`generated_at`）が明記されている。しかし runtime tasks.md は Task 1 が layout に置くのみで、この artifact のスキーマ定義・最小項目・生成責務を持つ作業項目・完了条件がどの Task にも無い（Task 6 evidence writing は review_case/failure_observation/v2 を扱うが comparison_eligibility_note に触れない）。一方 evaluation tasks.md Task 3 は「スキーマは runtime 所有、evaluation は最小項目に依存し再定義しない」と consumer 側義務を明示しており、producer 側 runtime に対応タスクが欠ける非対称。根拠 = A-7 は runtime 所有と決定済みだが runtime tasks にスキーマ owner としての実装単位が無い → downstream evaluation が依存する契約が runtime 側で未分解。横断越境規約の片側欠落。推奨対応 = Task 6（または Task 1）作業項目に「`derived/comparison_eligibility_note.json` のスキーマと最小 6 項目（A-7 決定）を runtime 所有として定義・生成する」を追加し、完了条件に同 artifact が A-7 最小項目を満たす旨を明示。重大度 = 重要（致命ではないが downstream evaluation の依存契約の producer 側欠落、横断整合の片肺）。必要性判定 = 自動採択（A-7 決定の producer 側タスク化漏れの補修、決定は確定済みで複数選択肢なし、致命的デメリットなし）。

### 他 5 spec 波及（明示記録）

- foundation tasks.md: 波及なし（runtime は consumer。foundation 所有語彙への参照整合は上記のとおり一致。foundation tasks への修正要求は本観点から発生せず）。
- evaluation tasks.md: 波及あり（記録のみ、evaluation tasks 変更不要）。T5-A は runtime 側タスク追加で解消し、evaluation tasks Task 3 の「runtime 所有スキーマに依存」記述は既に正しい。evaluation 側に修正波及は発生しない。
- self-improvement tasks.md: 波及なし。self-improvement tasks は `review_case.json` / `steps/*.json` / `run_manifest.yaml` / `v2/trace_note.json` / `v2/signal_linkage_note.json` / `comparison_eligibility_note.json` を optional/必須入力として参照し、runtime tasks.md §4 Downstream Handoff の self-improvement 列挙と命名一致。命名衝突なし。
- paper-interface tasks.md: 波及なし。paper-interface は evaluation 出力のみ consume、runtime と直接結合しない旨を自 tasks に明示。runtime tasks.md §4 の paper-interface 方針（evaluation 経由原則）と整合。
- implementation-governance tasks.md: 波及なし。governance は review dependency のみで feature data contract を生成しない（依存マップ §4.7）。`review_artifact_presence_rate` 等の metric 名は governance 固有の conformance metric で runtime artifact 名と衝突しない。

命名衝突の全 spec 横断検査: `review_case.json` / `run_manifest.yaml` / `comparison_eligibility_note.json` / `invalidation_markers.json` / `failure_observation.json` は producer（runtime/foundation）と consumer（evaluation/self-improvement）で同一綴り・同一意味で参照され、衝突・別義使用は検出せず。

---

## 観点 6: 失敗時の巻き戻し単位

### 要点

Task 失敗時の影響範囲・巻き戻し単位が明示されているか。

### 詳細抽出

- tasks.md §5 Blocking Dependencies は前提未充足時の blocked を示すが、各 Task の「失敗時にどこまで巻き戻すか」（task-local / design handback / requirements handback）の明示は無い。
- ただし runtime feature の性質上、各 Task は artifact 生成 + 実装で、raw evidence immutability（design Decision 3、Task 6/7/8）が「巻き戻し時に raw evidence を汚さない」構造を内包しており、実行時の invalidation は raw 編集でなく marker 追加（Task 8）で表現される。これは run 単位の巻き戻しを raw 不変で実現する設計を Task が反映している。

### 深掘り

- 所見 T6-A（軽微）: 所在 = tasks.md 全体（巻き戻し単位の節欠落）。問題 = WORKFLOW_OVERVIEW.md 節 4 の handback class（A/B/C/D）に照らし、Task 実装中の失敗が task-local 吸収か design handback かを判定する単位が tasks.md に無い。特に Task 6/7（review_case 正本・Run Close Boundary）は foundation schema 準拠が前提のため、実装中に foundation 契約不足が判明した場合 C 群（requirements handback）相当に上流戻しが要るが、その巻き戻し単位が未明示。根拠 = REVIEW_PROTOCOL 節 5 観点 6 はタスク失敗時の影響範囲・巻き戻し単位の明示を求める。推奨対応 = tasks.md に短い「失敗時の巻き戻し単位」節を追加（例: Task 1〜5/10 は task-local、Task 6/7/9 で foundation 契約不足が判明したら handback class C で foundation へ戻す、raw evidence は marker 追加で巻き戻し raw 不変を維持）。重大度 = 軽微（design の raw immutability で実行時巻き戻しは担保されるが、開発時 handback 単位の明示が薄い）。必要性判定 = 自動採択（観点 6 の明示要件の最小補修、内容は WORKFLOW_OVERVIEW 節 4 と §5 から導出可能、致命的デメリットなし）。

### 該当なし

実行時（runtime 動作時）の巻き戻しは Task 7/8（Run Close Boundary 順序厳守、invalidation = marker 追加で raw 不変）が単位を明示しており、致命・重要級の巻き戻し単位欠落は検出せず。所見は開発時 handback 単位の軽微補修のみ。

---

## 観点 7: 波及精査（最終ガード）

### 要点

観点 1〜6 の推奨対応が他 Task・他 feature へ生む連鎖を最終確認。波及あり/なしを全件明示。

### 変更候補リスト化（観点 1〜6 の推奨対応）

- T1-A: Task 2 に case manifest required fields 追加 → 波及精査
- T1-B: Task 6 に `v2/metric_snapshot.json` writer 明示 → 波及精査
- T2-A: Task 11 完了条件に客観テスト基準、Task 3/6/7 にテスト参照 → 波及精査
- T2-B: Task 3 にサブタスク分解注記 → 波及精査
- T3-A: Task 4 を Task 3 より前 or 依存注記 → 波及精査
- T3-B: §5 に Task 間依存グラフ別表 → 波及精査
- T4-A: Task 10 根拠行に Req8 受入 6 相互参照 → 波及精査
- T5-A: Task 6/1 に comparison_eligibility_note スキーマ owner タスク追加 → 波及精査
- T6-A: tasks.md に巻き戻し単位節追加 → 波及精査

### 波及判定（全件明示）

- T1-A 波及: なし（Task 2 内作業項目追加のみ。design 既存節の分解で要件変更なし。他 Task・他 spec 不変）。
- T1-B 波及: なし（Task 6 内列挙追加。design layout 既存。downstream は metric_snapshot を optional 扱い＝evaluation tasks Task 2 が v2 optional intake 明示済みで整合済み）。
- T2-A 波及: runtime 内 Task 3/6/7/11 に閉じる。他 spec 波及なし（テスト基準は runtime ローカル、foundation/evaluation の契約に触れない）。
- T2-B 波及: なし（Task 3 注記のみ、分解は実装判断）。
- T3-A 波及: runtime 内 §2/§3/Task 3/4 に閉じる。他 spec 波及なし（prompt resolution は runtime 所有、foundation placement/identity は不変）。
- T3-B 波及: なし（§5 別表は §2 から機械導出、新依存を生まない）。
- T4-A 波及: なし（トレース可読性補修、要件・設計不変）。
- T5-A 波及: evaluation tasks.md に「記録のみ」波及（evaluation Task 3 は既に「runtime 所有スキーマに依存」を正しく記述済みのため修正不要、producer 側 runtime tasks の追加で整合が完成する片側補修）。foundation/self-improvement/paper-interface/governance への修正波及なし。
- T6-A 波及: なし（tasks.md 内節追加、WORKFLOW_OVERVIEW 節 4 既存概念の参照、上位文書改版不要）。

### 連鎖更新漏れ精査

観点 1〜6 の全推奨対応は runtime tasks.md 内の作業項目・完了条件・節追加に閉じ、要件書・設計書・spec.json の改版を要しない（T5-A も design「v2 Compatibility Rule」に最小項目記載済みで設計改版不要、A-7 決定済み事項のタスク化のみ）。他 5 spec tasks への修正波及は 0 件（evaluation は「記録のみ」で修正不要）。連鎖更新漏れは検出せず。

---

## 集計

### 重大度別件数

- 致命: 0 件
- 重要: 4 件（T2-A / T3-A / T3-B / T5-A）
- 軽微: 5 件（T1-A / T1-B / T2-B / T4-A / T6-A）
- 合計: 9 件

### 必要性判定別

- 自動採択（致命的デメリットなし、複数合理選択肢なし）: 7 件 — T1-A / T1-B / T3-B / T4-A / T5-A / T6-A / T2-A
- 利用者判断（複数の合理的選択肢が残る）: 2 件 — T2-B（サブタスク分解の是非）/ T3-A（順序入替 vs 依存注記）

### must-fix 候補一覧（重要級 + 自動採択軽微の主要分）

- T5-A（重要・自動採択）: `comparison_eligibility_note.json` のスキーマ owner タスクが runtime tasks に欠落（A-7 producer 側片肺）。Task 6/1 にスキーマ定義・最小 6 項目・生成責務を追加。
- T2-A（重要・自動採択）: Task 11 テスト完了基準が後送りで各 Task 完了判定と定義循環。Task 11 に最低限の客観基準（seam ごと固定入力→期待出力の決定的検証）を事前明示、Task 3/6/7 にテスト参照付加。
- T3-B（重要・自動採択）: Task 11 件超に対し Task 間依存グラフ別表が無い（タスク特有方針違反）。§5 に依存グラフ別表追加。
- T3-A（重要・利用者判断）: §2 で Task 3（step executors）が Task 4（prompt resolution）より先で前提先行違反の懸念。順序入替か依存注記かを利用者判断。
- T1-A（軽微・自動採択）: Task 2 に case manifest base/track required fields の固定作業を追加。
- T1-B（軽微・自動採択）: Task 6 に `v2/metric_snapshot.json` の writer 明示。
- T4-A（軽微・自動採択）: Task 10 根拠行に Requirement 8 受入 6 の Task 4 相互参照。
- T6-A（軽微・自動採択）: tasks.md に「失敗時の巻き戻し単位」節を追加。

### 観点ごと該当なし概況

- 観点 1: 主要構造の網羅漏れ該当なし（軽微 2 件のみ、致命・重要なし）。
- 観点 2: 必須分解を要する過大タスク該当なし（Task 3 は軽微注記候補）。
- 観点 3: 循環依存・致命的順序違反は該当なし（重要 2 件は前提先行の明示性問題）。
- 観点 4: トレース欠落（要件を引かない Task・どの Task にも無い受入）該当なし。
- 観点 5: foundation 所有語彙の参照不整合・命名衝突は該当なし（重要 1 件は A-7 producer 側欠落）。
- 観点 6: 実行時巻き戻し単位の欠落該当なし（軽微 1 件は開発時 handback 単位の薄さ）。
- 観点 7: 連鎖更新漏れ・他 spec への修正波及該当なし（0 件、T5-A は evaluation へ記録のみ）。

### 他 5 spec tasks 波及件数

- 修正波及 0 件。記録のみ波及 1 件（evaluation tasks、T5-A 関連で evaluation 側は既に正しく修正不要）。
- foundation / self-improvement / paper-interface / implementation-governance: 波及なし（命名整合・参照整合確認済み）。

### 総合所見

致命 0 件。重要 4 件・軽微 5 件はいずれも runtime tasks.md 内の作業項目・完了条件・節追加で閉じ、要件書・設計書・spec.json・他 5 spec tasks の改版を要さない。T5-A（A-7 の producer 側タスク化漏れ）と T2-A（テスト完了基準の定義循環）は実装着手前に補修する価値が高い must-fix 候補。T3-A のみ複数の合理的実装戦略があり利用者判断を要する。

横断整合ゲートへの進行可否: must-fix 候補（特に T5-A / T2-A / T3-B）を 1 件ずつ承認で適用してから tasks alignment gate（依存マップ §5.3 の 6 番目）へ進むことを推奨する。重要級が横断契約（A-7 越境）に 1 件触れるため、未適用のまま横断ゲートに進むと runtime 側の片肺欠落が横断検査で再検出される。軽微 5 件は自動採択で同時適用してよい。T3-A は利用者判断後に確定。修正適用後は本観点 7 の波及精査どおり他 spec への連鎖が 0 件であることを再確認すれば横断ゲート進行の前提が整う。

### 証跡パス

`/Users/Daily/Development/Rwiki-v2-code-mod/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/reviews/tasks-local-review-2026-05-18.md`
