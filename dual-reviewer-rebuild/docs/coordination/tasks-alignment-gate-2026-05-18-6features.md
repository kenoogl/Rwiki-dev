# タスクフェーズ フィーチャー横断整合ゲート（6 機能）

_実施日: 2026-05-18_
_対象: dual-reviewer-rebuild 6 機能 tasks.md（foundation / runtime / evaluation / self-improvement / paper-interface / implementation-governance）_
_手続き正本: operations/REVIEW_PROTOCOL.md 節 4（フェーズ完走後のフィーチャー横断レビューパターン）_
_位置づけ: 生証跡（不変）。本ゲートは点検と所見のみ。tasks.md / design.md / requirements.md / spec.json は変更しない。_

---

## 0. 正本確認結果（横断・順序判断の前提）

REVIEW_PROTOCOL 節 4「横断・順序判断の前提（正本確認）」に従い、横断点検の前に正本 `docs/alignment/phase-and-feature-dependency-map.md` を確認した。

- フィーチャー依存トポロジ（§4.1）: foundation → {runtime, evaluation, self-improvement, paper-interface}、runtime → {evaluation, self-improvement}、evaluation → {self-improvement, paper-interface}、{runtime, evaluation, self-improvement, paper-interface} → implementation-governance（review dependency）。
- タスク生成順（§5.3）: foundation → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance。本ゲートはこの順序の第 6 段に位置する。
- タスク整合チェックリスト（§7）: foundation artifact の参照可能順序、runtime export より前の foundation provenance 固定、evaluation intake より前の runtime export manifest shape 固定、self-improvement proposal template より前の evaluation admission artifact 固定、paper-interface bundle より前の evaluation comparison artifact field naming 固定。
- §8.1: Requirement 9（実行台帳前提）は本 dependency map §5 を wave 段構成の権威ソースの一つとし、process→権威文書の一意指定は `workflow-process-authority-map.md` が担う。governance tasks Task 11〜18 と整合。

正本に明示なき構造的決定（特に T5-A の `runtime_validation_summary.schema.json` の owner 配置）は、依存マップに owner 指定がないため REVIEW_PROTOCOL 節 4・規律 `discipline_ssot_structural_decision_check.md` によりエージェント単独で採択せず、利用者確認を要する所見として後述する。

---

## 1. 観点別横断点検（REVIEW_PROTOCOL 節 4 整合性チェック観点）

### (a) producer/consumer artifact 名の双方向一致

- `review_case.json`: foundation が schema 所有（foundation Task 4）、runtime が正本生成（runtime Task 6）、evaluation が一次入力（evaluation Task 2）。三者で名称一致。**整合（A 群）**。
- `run_manifest.yaml`: runtime 生成（runtime Task 2）、evaluation intake（Task 2）、self-improvement replay 入力（Task 5）。一致。**整合（A 群）**。
- `comparison_eligibility_note.json`: runtime 所有スキーマ・生成（runtime Task 6 / 完了条件、最小 6 項目）、evaluation 消費・再定義しない（evaluation Task 3 line 85 / §5 / 完了条件、A-7 決定）。producer/consumer 対称。**整合（A 群、A-7 越境クラスタ）**。
- `validator_result.json` / `invalidation_markers.json`: foundation が schema 所有（foundation Task 8、単数形 `invalidation_marker.schema.json`）、runtime が run 配下に生成（runtime Task 1/7/8、複数形 `invalidation_markers.json`）、evaluation 消費（Task 2）。schema ファイル名（単数 `invalidation_marker.schema.json`）と run 配下インスタンス名（複数 `invalidation_markers.json`）の差は schema 名と instance ファイル名の規約差であり design 由来。命名衝突ではない。**整合（A 群）**。
- `decision_units.json`: runtime 生成（runtime Task 1 layout / Task 5）、evaluation 一次 intake（evaluation Task 2 line 65、portable bundle intake line 67）、self-improvement 入力（Task 5）。**runtime §4 Downstream Handoff の evaluation 行に未列挙＝F-7（後述、C 群）**。
- `failure_observation.json`: foundation schema 所有（Task 4）、runtime 生成（Task 6 line 151）、runtime §4 self-improvement 行に列挙（line 252）、self-improvement 入力。**整合（A 群）**。
- `runtime_validation_summary.schema.json`: self-improvement Task 3 が consumer として canonical 依存を宣言（line 90）、§5 で owner 未確定を alignment 議題に持ち上げ（line 210）。runtime tasks.md に owner 固定作業が不在＝**T5-A（後述、C 群／利用者判断）**。
- learning / paper artifact 群（`proposal_index.json` / `adoption_register.json` / `claim_map.json` / `evidence_register.json` 等）: self-improvement・paper-interface 各 tasks 内で完結し下流に producer artifact を渡さない（両者とも §4 Downstream Handoff で明言）。**整合（A 群）**。

### (b) foundation 所有語彙の参照非再定義

- `evidence_class`（`candidate`/`valid`/`invalid`/`exploratory`）: foundation Task 3 所有。runtime Task 2 が継承・再定義しない（line 76）、evaluation Task 3 が基礎判定に使用・`analysis_blocked` を local state と明示し foundation 語彙を侵さない（line 82）、paper-interface Task 4 が `maturity_label` を派生分類として束縛し再定義しない（line 99）。**整合（A 群）**。
- `validator_status`（`not_run`/`passed`/`failed`/`blocked`）: foundation Task 3 所有。runtime Task 7 がそのまま伝播・再定義/丸めしない（line 171）、governance Task 13 が foundation 正準語彙を参照し再定義しない（line 241）。**整合（A 群）**。
- `review_mode`（`manual_dogfooding`/`runtime_mediated`）: foundation Task 3 所有（`metadata_contract.yaml`、`review_mode_vocab.yaml` は作らない＝Task 8 line 191）。runtime/evaluation/self-improvement/paper-interface が参照のみ。**整合（A 群）**。
- governance phase-review 段階語彙（`implementation` 含む）: governance Task 6 が自所有と明示し runtime phase/profile 語彙と別物であることを宣言（line 139、Requirement 7 受入 7）。下流 evaluation/paper-interface は runtime phase/profile slice に `implementation` を期待しない。語彙衝突なし。**整合（A 群）**。

### (c) 越境クラスタの producer/consumer 対称

- A-5（`review_case.json` 唯一正本・`review_artifact.json` 投影規約 runtime 所有）: runtime Task 6（line 148）/ 完了条件（line 159・286）で投影規約 runtime 所有を固定。evaluation/self-improvement は `review_case.json` を読み `review_artifact.json` は runtime 内部限定。**対称（A 群）**。
- A-7（`comparison_eligibility_note.json` runtime 所有）: 上記 (a) のとおり producer（runtime Task 6）/consumer（evaluation Task 3/§5）対称。**対称（A 群）**。
- T5-A（`runtime_validation_summary.schema.json` owner=runtime、利用者決定済＝案 A）: consumer 側（self-improvement）は是正済だが producer 側（runtime）に owner 固定作業が未分解＝**片肺（C 群）**。

### (d) §5.1 依存グラフ・§5.2 失敗時巻き戻し単位・Task 完了条件のテスト二重化の構造対称

- foundation: §5.1/§5.2 を持たない。foundation は実行コードを持たない shared contract spec で Task 間が線形（§2 に実装順序、§5 Blocking Dependencies、§6 Completion Criteria）。テスト二重化は Task 9 機械検証に集約。コアレス spec の性質上、依存グラフ・巻き戻し単位を別小節化しないのは構造上妥当（不整合ではない）。
- runtime: §5.1 Task 間依存グラフ（line 264-272）、§5.2 失敗時巻き戻し単位（line 274-276）、各 Task 完了条件に Task 11 決定的検証ケース二重化（Task 3/6/7）。**対称**。
- evaluation: §5.1（line 213-220）、§5.2（line 222-229、handback A/B/C 明示）、各 Task 完了条件に Task 9 決定的検証ケース二重化（Task 3/4/5/8）。**対称**。
- self-improvement: §5.1（line 213-219）、§5.2（line 221-227）、各 Task 完了条件に Task 9 決定的検証ケース二重化（Task 4/5/6/7）。**対称**。
- paper-interface: §5.1（line 204-210）、§5.2（line 212-219）、各 Task 完了条件に Task 9 決定的検証ケース二重化（Task 3/4/8）。**対称**。
- implementation-governance: §5.1（line 328-336、Req9 ぶん Task 11→18 内部順序含む）、§5.2（line 338-345）、Task 10/18 にテスト工程。**対称**。

判定: 実装コードを持つ 5 spec（runtime/evaluation/self-improvement/paper-interface/governance）で §5.1／§5.2／テスト二重化が構造対称。foundation のみコアレス spec として §5.1/§5.2 非保持だが、これは spec 性質に起因する正当な非対称であり不整合ではない（B 群＝spec 個別レビューで確認済の構造であり横断でも整合）。

### (e) Downstream Handoff の双方向整合（F-7／T5-B を含む）

- runtime §4（line 247-253）の producer 公開列挙 と consumer 参照集合の双方向照合:
  - evaluation 行: 公開 = `run_manifest.yaml`/`review_case.json`/`validator_result.json`/`invalidation_markers.json`/`comparison_eligibility_note.json`。consumer（evaluation Task 2 line 65）参照集合 = 上記 + `decisions/decision_units.json`。**`decision_units.json` が producer 公開列挙に欠落＝F-7（C 群）**。
  - self-improvement 行: 公開 = step files/decision units/validator・invalidation artifacts/`invalid_run_triage_note.json`/`failure_observation.json`。consumer（self-improvement Task 2 line 73・Task 5 line 123）は追加で `v2/signal_linkage_note.json`/`v2/trace_note.json` を optional 補助入力として参照。**v2 補助 2 artifact が producer 公開列挙に未列挙＝T5-B（C 群、ただし self-improvement 側は耐性設計済）**。
  - paper-interface 行: runtime から直接 raw step を読ませず evaluation 経由＝paper-interface §4（line 192）と双方向一致。**整合（A 群）**。
- evaluation §4（line 195-200）⇔ self-improvement／paper-interface consumer 参照: self-improvement は `run_classification_index.json`/`exclusion_report.json`/`run_metrics.json`/`finding_metrics.json`/`caveat_register.json`、paper-interface は `treatment_comparisons.json`/`phase_comparisons.json`/`exclusion_report.json`/`caveat_register.json`。paper-interface Task 3（line 82）/§4（line 192）の参照集合と一致。**整合（A 群）**。ただし `treatment_comparisons.json`/`phase_comparisons.json` の field naming は evaluation §5（line 210）・paper-interface §5（line 202）の双方が design open issue 未解決として本 tasks alignment gate の横断議題に明示的に持ち上げ済（後述 §3）。

### (f) 命名衝突・上書き階層・期限/完了基準整合

- prompt resolution の上書き階層: foundation がプロンプト正本配置・identity を所有（foundation Task 6）、runtime が override resolution policy を所有（runtime Task 4 line 116、Requirement 8 受入 6）。上位（runtime override）→下位（foundation canonical）の解決順が一意（foundation placement/identity は保持）。**整合（A 群）**。
- heuristic 語彙の上書き階層: governance Task 3（line 88）が heuristic-default 挙動と minimal-template 語彙の canonical owner を v2-acquisition spec とし governance は参照のみ・必須検査しない（Requirement 8 受入 6）と明示。owner 未確定の越境を governance 側で consumer 注記化済。**整合（B 群、governance 個別レビュー T3-GOV 適用済）**。
- 完了基準整合: 各 spec の §6 Completion Criteria が design Completion Criteria に対応し、テスト二重化と整合。期限概念は本ワークフローに不在（フェーズ承認関門が完了基準）。**整合（A 群）**。
- 命名衝突: phase/profile 語彙（runtime 所有、`intent`/`requirements`/`design`/`tasks`）と governance phase-review 段階語彙（`implementation` 含む、governance 所有）は (b) のとおり所有分離が明示済で衝突なし。**整合（A 群）**。

---

## 2. ゲート送り 3 議題の解決方向（F-7／T5-A／T5-B）

### F-7（評価レビュー由来）— C 群

- 所在: runtime tasks.md §4 Downstream Handoff の evaluation 行（line 251）。
- 問題: evaluation Task 2（line 65）の最小 intake artifact と portable bundle intake（line 67）が `decisions/decision_units.json` を必須参照し、design Intake Model も decision_units を最小 intake に含むが、runtime §4 の evaluation 公開列挙に `decisions/decision_units.json` が欠落。producer 公開列挙と consumer 参照集合の双方向不一致。
- 根拠: REVIEW_PROTOCOL 節 4 観点 (e) Downstream Handoff の双方向整合。runtime Task 1（line 53）/ Task 5（line 131）で `decisions/decision_units.json` は生成 artifact として確定済であり、欠落は §4 列挙漏れのみ（実体は存在、契約破綻ではない）。
- 解決方向: **runtime tasks への C 群修正**。runtime §4 evaluation 行に `decisions/decision_units.json` を追記する（evaluation 側は修正不要）。具体追記提案: runtime tasks.md line 251 を `- evaluation: \`run_manifest.yaml\` / \`review_case.json\` / \`decisions/decision_units.json\` / \`validation/validator_result.json\` / \`validation/invalidation_markers.json\` / \`derived/comparison_eligibility_note.json\`（\`derived/runtime_summary.json\` には依存させない）` とする。
- 波及: runtime tasks.md のみ（1 行追記、軽微）。evaluation/foundation/self-improvement/paper-interface/governance への波及なし（明示記録）。

### T5-A（自己改善レビュー由来、利用者決定済＝案 A）— C 群（利用者判断）

- 所在: runtime tasks.md（owner 固定作業の不在）／self-improvement Task 3（line 90）・§5（line 210、是正済）。
- 問題: `scripts/track_runs/contracts/runtime_validation_summary.schema.json` の owner は runtime（A-7 と同型の生成元所有、利用者決定済＝案 A）。self-improvement は consumer 依存に是正済だが、runtime tasks.md に当該 schema を owner として定義・固定する作業項目が未分解。runtime Task 1（line 61）は `scripts/{protocol_runners,track_runs}/` ディレクトリ配置のみ言及し、validation summary schema の owner タスクが存在しない＝producer 側片肺。
- 根拠: REVIEW_PROTOCOL 節 4 観点 (c) 越境クラスタの producer/consumer 対称。consumer（self-improvement）是正済に対し producer（runtime）owner タスク欠落で対称が崩れている。依存マップに owner 明示がないため規律 `discipline_ssot_structural_decision_check.md` 該当（owner 配置は構造的決定で利用者確認領域。ただし利用者は案 A＝owner=runtime を既決定済のため、配置自体は確定。残るは「runtime tasks にどう作業分解するか」の追記方向）。
- 解決方向: **runtime tasks への C 群修正**。利用者既決定の案 A（owner=runtime）に従い、runtime tasks.md に `scripts/track_runs/contracts/runtime_validation_summary.schema.json` を runtime 所有 contract として定義・固定する作業を追記する。具体追記提案（2 案、利用者判断）:
  - 案 i: runtime Task 6（evidence writing model）作業項目に `comparison_eligibility_note.json` と同様の owner 宣言を 1 項追加 — 「`scripts/track_runs/contracts/runtime_validation_summary.schema.json` の payload 契約を runtime 所有として定義・固定する（self-improvement は consumer として依存・再定義しない＝producer 側責務、A-7 と同型）」。完了条件にも 1 行追加。
  - 案 ii: runtime Task 1 の skeleton 列挙に `scripts/track_runs/contracts/runtime_validation_summary.schema.json` を加え、定義実体を Task 6 か Task 7（validator integration）に振る。
  - 推奨: 案 i（A-7 `comparison_eligibility_note.json` と完全同型の owner 宣言パターンを Task 6 に集約でき構造対称が最も保たれる）。ただし owner タスクをどの runtime Task に置くか（Task 6 vs Task 1+別 Task）は作業分解の構造的選択であり**利用者判断**とする（案 A 自体は決定済だが追記の置き場所に複数の合理的選択肢が残る）。
- 波及: runtime tasks.md（1 作業項目＋完了条件 1 行）。self-improvement は是正済で追加修正不要（§5 line 210 の「tasks 横断整合ゲート議題に持ち上げる」は本ゲートで解決方向を確定したことで充足）。foundation/evaluation/paper-interface/governance への波及なし（明示記録）。

### T5-B（自己改善レビュー由来、記録のみ）— C 群（軽微・採否は利用者）

- 所在: runtime tasks.md §4 self-improvement 行（line 252）。
- 問題: self-improvement Task 2（line 73）が `v2/signal_linkage_note.json`/`v2/trace_note.json` を v2 supporting input、Task 5（line 123）が optional replay 入力として参照するが、runtime §4 self-improvement 公開列挙に未列挙。
- 根拠: REVIEW_PROTOCOL 節 4 観点 (e)。ただし self-improvement 側は「読めなくても基本 flow が維持される設計」（Task 2 line 73）「optional」（Task 5 line 123）と耐性設計済で、欠落しても契約破綻にならない（self-improvement 個別レビューで修正不要と確定済）。runtime Task 1（line 55）で `v2/{...,trace_note.json,signal_linkage_note.json}` は生成 artifact として確定済。
- 解決方向: **runtime tasks への C 群修正（軽微、採否は利用者判断）**。runtime §4 self-improvement 行に v2 補助 2 artifact を optional として追記すると producer 公開列挙と consumer 参照集合が双方向完全一致する。具体追記提案: runtime tasks.md line 252 末尾に `（optional 補助: \`v2/signal_linkage_note.json\` / \`v2/trace_note.json\`）` を付す。self-improvement 側は耐性設計済のため修正不要。本件は契約破綻でなく可読性・双方向対称性の向上にとどまるため、必要性判定上は「軽微・採否は利用者判断」（過剰修正抑制の観点で必須ではない）。
- 波及: runtime tasks.md のみ（1 行追記、軽微）。他 5 機能への波及なし（明示記録）。

---

## 3. その他の横断議題（既存 tasks 文書に明示済、本ゲートで確認）

- evaluation comparison artifact field naming（`treatment_comparisons.json`/`phase_comparisons.json`）: evaluation §5（line 210）・paper-interface §5（line 202）が双方向に design open issue 未解決として本 tasks alignment gate の横断議題と明示済。これは tasks 文書が自ら alignment gate へ正しく escalate しており双方向整合（B 群＝既存対応済、記録のみ）。確定値は design open issue 解決を要するため本ゲートでは確定しない（依存マップ §7 の「paper-interface bundle より前に evaluation comparison artifact field naming 固定」に従い、design 層 open issue として利用者・設計フェーズ判断領域。本ゲートは tasks 横断としては「双方向に議題化済で不整合なし」と判定）。
- evaluation Task 4 phase-specific overlay 初版集合（evaluation §5 line 211）: design alignment open issue 解決後確定と明示済。tasks 横断整合としては議題化済で不整合なし（B 群、記録のみ）。
- governance Req9 関連 C-1/C-2/C-3 上位文書同期（governance Task 17）: タスク人間承認後の文書同期作業として段取り済（governance §5.1 line 335）。本ゲート時点で未実施は工程設計どおり（B 群、記録のみ）。

---

## 4. 4 分類結果（波及あり/なし全件明示記録）

### A 群：確認済整合（何もしない）

1. `review_case.json` 三者命名一致（foundation/runtime/evaluation）— 波及なし
2. `run_manifest.yaml` producer/consumer 一致 — 波及なし
3. `comparison_eligibility_note.json` A-7 producer/consumer 対称 — 波及なし
4. `validator_result.json`/`invalidation_marker(s)` schema 名と instance 名の規約差（衝突でない）— 波及なし
5. `failure_observation.json` foundation schema→runtime 生成→self-improvement 入力の鎖一致 — 波及なし
6. foundation 所有 3 語彙（`evidence_class`/`validator_status`/`review_mode`）の参照非再定義 — 波及なし
7. A-5（`review_case.json` 唯一正本・投影規約 runtime 所有）producer/consumer 対称 — 波及なし
8. learning/paper artifact 群が下流に producer を渡さない（self-improvement/paper-interface §4）— 波及なし
9. prompt resolution の上書き階層一意（foundation placement ← runtime override policy）— 波及なし
10. phase/profile 語彙と governance phase-review 段階語彙の所有分離（衝突なし）— 波及なし
11. paper-interface が runtime 直接結合せず evaluation 経由（双方向一致）— 波及なし
12. 実装コード保持 5 spec の §5.1/§5.2/テスト二重化の構造対称 — 波及なし

### B 群：既存対応済（記録のみ）

1. foundation のコアレス spec ゆえの §5.1/§5.2 非保持（spec 性質に起因する正当な構造、個別レビューで確認済）— 波及なし
2. heuristic 語彙 owner=v2-acquisition、governance は consumer 注記化済（governance T3-GOV 適用済）— 波及なし
3. evaluation comparison field naming の双方向 alignment 議題化（evaluation §5・paper-interface §5）— 波及: design open issue として利用者/設計判断領域（tasks 横断としては不整合なし）
4. evaluation Task 4 phase overlay 初版集合の design open issue 議題化済 — 波及: design open issue
5. governance C-1/C-2/C-3 上位文書同期のタスク承認後段取り済 — 波及: 承認後 governance Task 17 で実施予定

### C 群：今回顕在化の新規含意（各機能既存文書に軽微追記、4 要素＋必要性判定）

| 番号 | 議題 | 所在 | 1 行要約 | 自動採択/利用者判断 |
| --- | --- | --- | --- | --- |
| C-α | F-7 | runtime §4 evaluation 行（line 251）| `decisions/decision_units.json` を evaluation 公開列挙に追記 | 自動採択（実体存在・列挙漏れのみ、致命的デメリットなし） |
| C-β | T5-A | runtime tasks（owner タスク不在）| `runtime_validation_summary.schema.json` を runtime 所有 contract として固定する作業を追記（案 A 既決定、追記置き場所は 2 案）| 利用者判断（作業分解の置き場所に複数合理的選択肢、`discipline_ssot_structural_decision_check.md` 該当）|
| C-γ | T5-B | runtime §4 self-improvement 行（line 252）| v2 補助 2 artifact を optional として追記（self-improvement は耐性設計済）| 利用者判断（契約破綻でなく双方向対称性向上のみ、必要性判定上は任意） |

注: 表形式は出力フォーマット規律で禁止のため、上記は構造化のための例外的最小表記。以下に箇条書きで再掲する。

- C-α（F-7）: 所在＝runtime §4 evaluation 行。問題＝consumer 必須の `decisions/decision_units.json` が producer 公開列挙に欠落（実体は runtime Task 1/5 で生成済、列挙漏れ）。根拠＝節 4 観点 (e) 双方向整合。推奨対応＝runtime line 251 に `decisions/decision_units.json` を追記。必要性判定＝必要（双方向不一致を放置すると下流が intake 契約を誤読しうる。修正コスト極小・致命的デメリットなし）。自動採択候補。
- C-β（T5-A）: 所在＝runtime tasks の owner タスク不在。問題＝owner=runtime（案 A 既決定）だが runtime tasks に owner 固定作業が未分解で producer 片肺。根拠＝節 4 観点 (c) 越境対称。推奨対応＝runtime Task 6 に A-7 同型の owner 宣言を追記（推奨案 i）または Task 1 skeleton＋別 Task 分解（案 ii）。必要性判定＝必要（owner 片肺は横断ゲートで再検出される蓋然性が高い）。ただし追記置き場所が構造的選択のため利用者判断。
- C-γ（T5-B）: 所在＝runtime §4 self-improvement 行。問題＝self-improvement が optional 参照する v2 補助 2 artifact が producer 公開列挙に未列挙。根拠＝節 4 観点 (e)。推奨対応＝runtime line 252 末尾に optional 補助として追記。必要性判定＝任意（self-improvement 耐性設計済で契約破綻せず、双方向対称性向上にとどまる）。利用者判断（過剰修正抑制の観点で必須でない）。

### 不整合（受入違反・実装不可能）

**0 件**。受け入れ基準違反・実装不可能性は検出されなかった。進行停止を要する事項なし。

---

## 5. §5.1/§5.2/テスト二重化の 6 機能構造対称性判定

- 実装コードを持つ 5 spec（runtime/evaluation/self-improvement/paper-interface/implementation-governance）: §5.1 Task 間依存グラフ・§5.2 失敗時巻き戻し単位（handback A/B/C 判定含む）・各 Task 完了条件のテスト二重化を全 spec が構造対称に保持。
- foundation: コアレス（実行コード非保持の shared contract）spec のため §5.1/§5.2 を別小節化せず §2 実装順序・§5 Blocking Dependencies・§6 Completion Criteria・Task 9 機械検証集約で代替。これは spec 性質に起因する正当な非対称であり不整合ではない。
- 判定: **6 機能で構造対称性は確保されている**（foundation の非保持は spec 性質由来の正当例外）。

---

## 6. 総合所見

- 正本（依存マップ）確認済。本ゲートは §5.3 タスク生成順の第 6 段に正しく位置する。
- 不整合 0 件。進行停止事項なし。
- A 群 12 件・B 群 5 件・C 群 3 件（C-α/C-β/C-γ）。REVIEW_PROTOCOL 節 4 の経験則「タスクフェーズ横断レビューでは A 群が大幅増、C 群はさらに少数（版固定の同期など軽微）、不整合 0 件で完走」のパターンに合致。C 群 3 件はいずれも runtime tasks.md への軽微追記（数行〜1 作業項目）に閉じ、新規フィーチャー作成不要。
- C 群はすべて producer 側（runtime）への片肺/列挙漏れの是正であり、consumer 側（evaluation/self-improvement）は個別レビューで既に是正済。runtime tasks.md のみへの C 群修正で双方向対称が完成する。
- 人間承認可否の所見: 不整合 0 件・C 群が runtime tasks への軽微追記 3 件に限定されるため、6 機能タスクは人間承認に進めてよい。ただし C-β（T5-A）は規律 `discipline_ssot_structural_decision_check.md` 該当の構造的選択（owner 追記の置き場所）を含むため、承認パッケージに C 群 3 件を提示し、利用者の 3 択（全採用 / 個別レビュー / A・B のみ確認し C 群次回送り）と C-β の追記置き場所（推奨案 i ＝ runtime Task 6 集約）の判断を仰ぐことを推奨する。本ゲートは所見提示のみで tasks.md/design.md/requirements.md/spec.json は変更していない。

---

## 7. 証跡パス

- 本ゲート証跡: `dual-reviewer-rebuild/docs/coordination/tasks-alignment-gate-2026-05-18-6features.md`（本ファイル、不変）
- 参照した個別レビュー証跡（独立判断、鵜呑みにせず取り込み確認）:
  - `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/reviews/tasks-local-review-2026-05-18.md`（T5-A／T5-B 起点）
  - 各 spec の `reviews/tasks-local-review-2026-05-18.md`（foundation/runtime/evaluation/paper-interface）
  - `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/reviews/tasks-local-review-task1-10-2026-05-18.md` および Req9 サイクル `reviews/tasks-local-review-2026-05-18.md`
- 正本: `dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md`、`operations/REVIEW_PROTOCOL.md` 節 4、`operations/WORKFLOW_OVERVIEW.md`、`CONVENTIONS.md`
