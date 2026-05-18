# タスク個別レビュー（dual-reviewer-evaluation）

_実施日: 2026-05-18_
_対象: `.kiro/specs/dual-reviewer-evaluation/tasks.md` 全体_
_手順: `operations/REVIEW_PROTOCOL.md` 節 5（タスクレビュー 7 観点）_
_位置づけ: 起草者と独立した批判的タスク個別レビュー。本セッション前半で省略した正規レビューの正規実施。生証跡として不変。本レビューは所見のみで tasks.md / design.md / requirements.md / spec.json を変更しない_

---

## 0. 依存マップ確認結果（横断・順序判断の前提）

`docs/alignment/phase-and-feature-dependency-map.md` を確認した。確認結果:

- §4.4 evaluation は foundation / runtime に対し `hard dependency`、self-improvement / paper-interface に対し（下流が evaluation 出力を一次入力とする向きで）`hard dependency`。
- §5.3 Tasks Wave 推奨順序は `foundation → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance`。evaluation tasks は foundation tasks / runtime tasks の後段。
- §7 Tasks Alignment Checklist:「evaluation intake 実装より前に runtime export manifest shape が固まっているか」「paper-interface bundle 実装より前に evaluation comparison artifact field naming が固まっているか」が明記。
- §6 Current Blocking Points:「evaluation admission は runtime export と別責務」が明記。
- 設計横断整合ゲート 2026-05-18 決定（評価 A-7）：`comparison_eligibility_note.json` のスキーマは生成元 runtime 所有に確定。evaluation は最小項目に依存し再定義しない。design.md「Open Issues for Design Alignment Gate」末尾および「Classification Model」末尾に反映済み。runtime tasks.md Task 6 が producer 側責務として最小 6 項目（`run_id` / `eligible_for_standard_comparison` / `ineligibility_reason_codes` / `treatment` / `phase_profile` / `generated_at`）を所有・生成と明記している。

本レビューの横断・順序判断は上記正本に従う。正本に明示のない構造的決定はエージェント単独で採択せず、利用者判断対象として所見化する。

---

## 観点 1: 設計全件の網羅

**要点**: design.md の全構成要素が tasks に分解されているか。

**詳細抽出（design 構成要素 → 対応 Task）**:

- Analysis Artifact Layout / Placement Rationale → Task 1（網羅）
- Analysis Population Selection → Task 2 末尾（selection policy / selection manifest / refresh workflow に言及。網羅）
- Intake Model / v2-compatible optional intake / Portable Bundle Intake → Task 2（網羅）
- Classification Model §1〜§4（4 状態 / rules / missing vs invalid / 設計スキップ弁別） → Task 3（網羅）
- Admission States for Imported Bundles → Task 3 + Task 7（判定は Task 3、register 出力は Task 7。網羅）
- Metric Model §1〜§3 + §2.5 Phase-Specific Metric Overlays → Task 4（網羅）
- Comparison Model §1〜§3 → Task 5（網羅）
- Exclusion and Caveat Model §1〜§2 → Task 6（網羅）
- Imported Evidence Intake Artifacts §1〜§2 → Task 7（網羅）
- Versioning Model → Task 8（網羅）
- Interfaces to Downstream Features → tasks.md §4 Downstream Handoff（網羅）
- Key Decisions 1〜4 → Task 1（D1）/ Task 3（D2）/ Task 5（D3）/ Task 6（D4）。全件 Task 根拠に明記（網羅）
- Completion Criteria → tasks.md §6 + Task 9（網羅）
- Test 戦略：design.md に独立した「Test Strategy」節は存在せず、Completion Criteria 4 点が検証基準。Task 9 はこれを根拠に決定的検証を列挙（後述 観点 2 / F-2 参照）

**深掘り**:

所見 F-1（軽微）

- 所在: Task 4 / design.md「Metric Model §2.5」
- 問題: design §2.5 は `intent` overlay（goal ambiguity / non-goal leakage / intent-to-requirement traceability）と `implementation-oriented review`(future) overlay を明記する。Task 4 作業は「overlay は intent/requirements/design/tasks（+ future implementation-oriented）ごとに別観点」と総称で書き、初版 overlay 集合の具体定義をタスク本文に展開していない。design.md 自体が「Open Issues for Design Alignment Gate: phase-specific overlay metric set の初版確定」を未解決事項として残しているため、タスク側で確定値を固定すると design 未確定と矛盾する。
- 根拠: design.md「Open Issues for Design Alignment Gate」3 行目（phase-specific overlay metric set の初版確定が design alignment gate 送り）。Task 4 は要件 8 受入 5（実装指向拡張時に contract 再設計不要）を引いており拡張余地保持は意図的。
- 推奨対応: 現状維持で可。ただし Task 4 完了条件に「overlay 初版集合は tasks alignment gate / design alignment open issue 解決を待って確定する依存がある」旨を 1 行追記すると blocking 依存が明確になる（観点 3 / F-5 と関連）。

**該当なし確認**: design 構成要素で Task に落ちていない欠落は検出されなかった（網羅性は満たす）。F-1 は欠落ではなく粒度・確定タイミングの問題。

**必要性判定**: F-1 は軽微。致命的デメリットなし。ただし overlay 確定タイミングが Task 3（依存マップ §5 / open issue）と絡むため、追記は利用者判断（自動採択でも害はないが design open issue との連動を明示する価値判断を含む）。

---

## 観点 2: タスクの粒度と完了基準

**要点**: 1 タスクが実装可能単位か、完了基準が検証可能か。

**詳細抽出**:

- 全 9 Task。1〜8 が成果物生成、9 がテスト。粒度は「半日〜数日」目安（節 5 タスク特有方針）に概ね収まる。runtime tasks.md Task 3 のような明示サブタスク分解注記は evaluation には無いが、各 Task の作業項目数（3〜6 項目）は単一 artifact 群に閉じており過大ではない。
- 完了条件は全 Task に明示。多くが「〜を説明できる」形式。

**深掘り**:

所見 F-2（重要）

- 所在: Task 1〜8 の完了条件（特に Task 1「raw run と analysis artifact の境界を説明できる」、Task 3「valid / invalid / exploratory / analysis_blocked の違いを説明できる」、Task 4「metrics がどこに出るか説明できる」）
- 問題: 完了条件の多くが「説明できる」という人間の説明可能性に依存し、機械的・客観的な合否判定基準になっていない。節 5 タスク特有方針「検証手段の事前確定：各タスクの完了判定基準は実装着手前に確定する。実装後に基準を後付けすると検証の中立性が失われる」に照らすと、「説明できる」は実装後に解釈で合否を動かせる弱い基準。比較対象として runtime tasks.md は Task 3/6/7 完了条件に「Task 11 の決定的検証ケースで pass する」を併記し、説明可能性と機械検証を二重化している。evaluation tasks.md にはこの二重化が無く、Task 9（テスト）と Task 1〜8 完了条件の結合が宣言されていない。
- 根拠: design.md Completion Criteria は 4 点とも「説明できる」表現だが、Task 9 作業は「classification rules / admission rules / 設計スキップ弁別を固定入力で決定的に検証」「metric derivation を固定 structured evidence で入出力対応検証」等の決定的検証を列挙しており、機械検証可能な対象は実在する。完了条件と Task 9 の結合が明示されていないだけ。
- 推奨対応: Task 3 / 4 / 5 / 8 の完了条件に「Task 9 の決定的検証ケースで pass する」を併記し、説明可能性と機械検証を二重化する（runtime tasks.md と同形）。Task 1（directory skeleton）/ Task 6 / Task 7 は artifact 存在・分離の静的検証で代替可。

**必要性判定**: F-2 は重要。検証中立性は節 5 が明示要求する規律であり、現状は実装後に完了基準を解釈で動かせる。runtime tasks.md に先例があり修正案が一意（決定的検証ケース併記）で致命的デメリットがないため**自動採択候補**。ただし「どの完了条件にどの検証を結ぶか」の対応付けは複数の合理的割当があるため、対応付けの粒度は利用者確認が望ましい（must-fix・対応付け細部は利用者判断）。

所見 F-3（軽微）

- 所在: Task 9
- 問題: Task 9 完了条件は「design Completion Criteria 4 点を満たす」のみ。runtime tasks.md Task 11 は「4 つの testability seam それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass する（着手前にこの客観基準を確定）」と検証ケースの最小本数と着手前確定を明記している。evaluation Task 9 は検証対象を 4 項目列挙するが「各項目に最低 1 ケース」「着手前に客観基準確定」の客観閾値が無い。
- 根拠: 節 5「検証手段の事前確定」、runtime tasks.md Task 11 の先例。
- 推奨対応: Task 9 完了条件に「列挙 4 検証対象（classification/admission・metric derivation・comparison 可能性/valid population・staleness 伝播）それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass する。着手前に客観基準を確定（TDD 先行）」を追記。

**必要性判定**: F-3 は軽微。F-2 と同系統で先例があり修正案一意。致命的デメリットなし → **自動採択候補**（F-2 採択時に同時適用が自然）。

---

## 観点 3: 依存関係と順序

**要点**: タスク間前提・依存が明示され、前提タスクが先行し、循環が無いか。10 件超なら依存グラフ別表要。

**詳細抽出**:

- Task 総数 9 件（10 件以下）。節 5 タスク特有方針の「10 件超なら依存グラフ別表」閾値には達しないため別表必須ではない。
- tasks.md §2 実装順序が 1→9 の線形順序を提示。理由 3 点（intake→classification 前提、comparison 可能性/caveat が下流再利用前提、staleness は classification 確定後）を design 章参照付きで明示。
- tasks.md §5 Blocking Dependencies が外部前提（runtime export manifest / comparison_eligibility_note、foundation metadata contract / evidence_class、foundation 無効化伝播義務）を列挙。

**深掘り**:

所見 F-4（重要）

- 所在: tasks.md §5 Blocking Dependencies / §2 実装順序
- 問題: runtime tasks.md は §5.1 に「Task 間依存グラフ（§2 から導出。並列可を明示）」、§5.2 に「失敗時の巻き戻し単位」を独立小節として持つ。evaluation tasks.md は §2 に線形順序の散文はあるが、(a) Task 間内部依存グラフ（どの Task がどの Task の出力を入力にするか、並列可能ペア）が明示されていない、(b) 失敗時の巻き戻し単位の独立記述が無い（観点 6 で詳述）。9 件で別表必須閾値未満だが、Task 3（classification）と Task 4（metric）の関係、Task 7（imported intake artifacts）と Task 3（admission state 判定）の分担境界（admission 判定は Task 3、register 出力は Task 7）が散文からは追いにくい。特に Task 3 作業に「imported bundle の admission state を classification 前段で判定」とあり Task 7 作業に「admission 前に required provenance を validate」とあるため、admission ロジックが Task 3 と Task 7 に跨る。順序上 Task 3 が Task 7 より先だが、Task 7 が Task 3 の admission 判定結果を前提とするのか、Task 7 が判定し Task 3 が消費するのか、依存方向が散文では一意でない。
- 根拠: design.md「Admission States for Imported Bundles」は classification の前段で admission state を持つと規定（判定は intake/admission 側）。tasks.md Task 3 作業 7 行目「imported bundle の admission state ... を classification 前段で判定する」と Task 7 作業「reject / downgrade-to-exploratory / admit を明示 admission rule で判定する」が両方「判定」と書いており所有が二重。
- 推奨対応: (1) §5 に「Task 間依存グラフ（並列可明示）」小節を追加（runtime tasks.md §5.1 と同形）。(2) admission state 判定の所有を一意化：admission rule の判定ロジックは Task 7（imported evidence intake artifacts）が所有し register に記録、Task 3 は Task 7 の admission status を「分類前段の入力として参照する（再判定しない）」と作業文を是正。これにより Task 3↔Task 7 の依存方向が一意化。

**必要性判定**: F-4 は重要。admission 判定の二重所有は実装時に Task 3 と Task 7 双方で判定ロジックを書く risk があり、design「Admission States」の単一所有意図に反する。依存方向の一意化は致命的デメリットなく修正案が一意 → 所有一意化は**自動採択候補**。依存グラフ小節追加も runtime 先例ありで自動採択候補。ただし「判定を Task 7 所有」とする割当は design 文面（「classification の前段」）と整合する一方、Task 3 を所有とする読みも論理上ありうるため、所有先の最終確定は**利用者判断**（評価 A-7 と同じく所有境界は構造的決定）。

所見 F-5（軽微）

- 所在: tasks.md §5 / Task 4
- 問題: F-1 で指摘の通り Task 4 の overlay 初版集合は design.md「Open Issues for Design Alignment Gate」で未解決。tasks.md §5 Blocking Dependencies は runtime / foundation 外部前提を列挙するが「phase-specific overlay metric set 初版確定（design alignment open issue）」を Task 4 の前提として列挙していない。tasks.md §5 末尾は「evaluation comparison artifact field naming 確定が paper-interface bundle task の前提（後段 alignment で詰める）」と paper-interface 向け前提は書くが、evaluation 自身の Task 4 が抱える design open issue 依存は未記載。
- 根拠: design.md「Open Issues for Design Alignment Gate」、phase-and-feature-dependency-map §7（tasks alignment checklist）。
- 推奨対応: §5 に「Task 4 の phase-specific overlay metric 初版集合は design alignment open issue 解決後に確定（tasks alignment gate で詰める）」を 1 行追加。

**必要性判定**: F-5 は軽微。F-1 と一体。致命的デメリットなし → 自動採択候補（F-1/F-5 同時適用）。

**循環依存**: §2 の 1→9 線形順序および F-4 是正後の Task 3↔7 一方向化により循環は生じない。Task 8（staleness）が Task 3（classification 確定）後という順序も design 根拠と整合。**循環依存なし**。

---

## 観点 4: 要件 / 設計とのトレース

**要点**: 各 Task が対応要件番号・設計章番号を引いているか。

**詳細抽出（Task → 引用）**:

- Task 1: Requirement 5（受入 1・3）、design「Analysis Artifact Layout」「Placement Rationale」「Key Decision 1」
- Task 2: Requirement 6（受入 1〜5）、Requirement 10（受入 1〜3）、design「Intake Model」「Portable Bundle Intake」「Analysis Population Selection」
- Task 3: Requirement 1（受入 1〜6）、Requirement 9（受入 1〜6）、Requirement 10（受入 4・5）、Requirement 2 受入 3、design「Classification Model §1〜§4」「Admission States」
- Task 4: Requirement 3（受入 1〜5）、Requirement 8（受入 1〜5）、Requirement 7（受入 1・4）、design「Metric Model §1〜§3」「Phase-Specific Metric Overlays」
- Task 5: Requirement 2（受入 1〜6）、Requirement 7（受入 2・3・5）、design「Comparison Model §1〜§3」
- Task 6: Requirement 4（受入 1〜5）、Requirement 1 受入 3、design「Exclusion and Caveat Model」「Key Decision 4」
- Task 7: Requirement 10（受入 2〜5）、design「Imported Evidence Intake Artifacts」
- Task 8: Requirement 5（受入 5・6）、Requirement 5 受入 2、design「Versioning Model」
- Task 9: design「Completion Criteria」、開発方針 TDD

**深掘り（要件 1〜10 の被覆確認）**:

- Req1: Task 3（受入 1〜6）+ Task 6（受入 3）。被覆。
- Req2: Task 5（受入 1〜6）+ Task 3（受入 3）。被覆。
- Req3: Task 4（受入 1〜5）。被覆。
- Req4: Task 6（受入 1〜5）。被覆。
- Req5: Task 1（受入 1・3）+ Task 8（受入 2・5・6）。**受入 4 の所在を確認**：Req5 受入 4「support downstream consumption by both self-improvement and paper-interface」は Task 個別根拠に明示引用が無いが、tasks.md §4 Downstream Handoff が self-improvement / paper-interface の読む artifact を design「Interfaces to Downstream Features」根拠で列挙し実質被覆。F-6 参照。
- Req6: Task 2（受入 1〜5）。被覆。
- Req7: Task 4（受入 1・4）+ Task 5（受入 2・3・5）。**受入 1「preserve reviewed phase/profile identity」**は Task 5 作業「phase identity を消さず保持」で被覆。被覆。
- Req8: Task 4（受入 1〜5）。被覆。
- Req9: Task 3（受入 1〜6）。被覆。
- Req10: Task 2（受入 1〜3）+ Task 3（受入 4・5）+ Task 7（受入 2〜5）。被覆。

所見 F-6（軽微）

- 所在: tasks.md §4 Downstream Handoff / Task 根拠群
- 問題: Requirement 5 受入 4（downstream consumption by both self-improvement and paper-interface）がどの Task 完了条件にも直接トレースされず、§4 Downstream Handoff という非 Task 節に実質被覆が落ちている。トレース観点では「全受入が Task に紐付く」状態が望ましい。
- 根拠: requirements.md Req5 受入 4。tasks.md §4 は Task でなくハンドオフ記述節。
- 推奨対応: Task 1 または Task 8 のいずれか（derived artifact 構造を確定する Task）の根拠に「Requirement 5 受入 4」を追記、もしくは §4 冒頭に「Requirement 5 受入 4 を満たす」旨を明記してトレースを可視化。

**必要性判定**: F-6 は軽微。実質被覆済みでトレース可視化のみの問題。致命的デメリットなし → **自動採択候補**。

**該当なし確認**: 要件 1〜10 の全受入に重大な被覆欠落は無い。設計章引用も全 Task に存在。トレース観点は概ね良好（F-6 の可視化軽微指摘のみ）。

---

## 観点 5: 横断タスクの抽出

**要点**: 複数 feature にまたがる作業（共通契約固定・命名統一・移行スクリプト）が独立タスクとして切り出され、consumer 側で「依存・再定義しない」になっているか。foundation 語彙参照整合。他 5 spec 波及。

**詳細抽出と深掘り**:

(A) `comparison_eligibility_note.json`（runtime 所有、評価 A-7）

- evaluation tasks.md Task 2 作業: intake 入力に `derived/comparison_eligibility_note.json` を列挙。
- Task 3 作業: 「`comparison_eligibility_note.json` を classification 前の補助判断材料として読んでよいが final 判定は metadata / validator / invalidation を基礎にする。スキーマは runtime 所有、evaluation は最小項目に依存し再定義しない（評価 A-7 決定、design §2 末尾）」と明記。
- Task 5 作業: 「`comparison_eligibility_note` の不可理由を先に尊重」と consumer 利用のみ。
- §6 Completion Criteria: 「`comparison_eligibility_note.json` を runtime 所有スキーマとして参照する（評価 A-7）」と明記。
- runtime tasks.md Task 6 作業: producer 側として最小 6 項目を runtime 所有で定義・生成、「評価は本スキーマに依存し再定義しない＝producer 側責務」と明記。
- **整合判定**: producer（runtime Task 6）/ consumer（evaluation Task 2/3/5）双方で所有・非再定義が一貫。**横断契約整合（A-7）は正しく consumer 側で「依存・再定義しない」になっている。不整合なし**。

(B) foundation 語彙参照整合（`evidence_class` / `validator_status`）

- evaluation tasks.md Task 3 作業: `analysis_blocked` は「foundation evidence_class ではなく evaluation local state（design §1、Decision 2）」と明示。classification rules で `evidence_class valid/exploratory`、`validator_status passed/failed/blocked` を参照。
- foundation tasks.md Task 3: `evidence_class`=`candidate`/`valid`/`invalid`/`exploratory`、`validator_status`=`not_run`/`passed`/`failed`/`blocked` を foundation canonical 所有、「downstream evaluation / paper-interface は再定義せず参照」と明記。
- **整合判定**: evaluation は foundation 語彙を参照のみ、`analysis_blocked` は foundation 語彙でない local state と明示弁別。**foundation 語彙参照整合。不整合なし**。

(C) runtime 出力参照整合（`review_case.json` / validator / invalidation / decision_units）

- evaluation Task 2 intake 入力（`run_manifest.yaml` / `review_case.json` / `decisions/decision_units.json` / `validation/validator_result.json` / `validation/invalidation_markers.json` / `derived/comparison_eligibility_note.json`）は runtime tasks.md §4 Downstream Handoff の evaluation 向け提供 artifact（`run_manifest.yaml` / `review_case.json` / `validation/*` / `derived/comparison_eligibility_note.json`）とほぼ一致。
- evaluation Task 4 作業:「`derived/runtime_summary.json` を metric の正本入力にしない」は runtime tasks.md §4「`derived/runtime_summary.json` には依存させない」と双方向一致。
- **軽微所見 F-7（軽微）**: evaluation Task 2 は `decisions/decision_units.json` を intake 入力に列挙するが、runtime tasks.md §4 Downstream Handoff の evaluation 向け列挙は `run_manifest.yaml` / `review_case.json` / `validation/validator_result.json` / `validation/invalidation_markers.json` / `derived/comparison_eligibility_note.json` で、`decisions/decision_units.json` を evaluation 向けに明示列挙していない（self-improvement 向けには decision units を列挙）。evaluation Task 4 は metric derivation 順序に「decision units」を含むため decision_units への依存は実在。runtime 側 Downstream Handoff の evaluation 行に `decisions/decision_units.json` が欠落しているか、evaluation 側が runtime 非公開 artifact を読もうとしているかの不整合候補。
  - 根拠: evaluation tasks.md Task 2 作業 1 行目・Task 4 derivation rule。runtime tasks.md §4 evaluation 行。
  - 推奨対応: tasks alignment gate で双方向同期。evaluation 側を正とし runtime §4 Downstream Handoff の evaluation 行に `decisions/decision_units.json` を追記する方向が design「Intake Model」（decision_units を最小 intake に含む）と整合。本所見は runtime tasks.md への波及（後述 観点 7）。

(D) paper-interface / self-improvement への横断（consumer 側非再定義）

- evaluation §4 Downstream Handoff: self-improvement に `run_classification_index.json` 等、paper-interface に `treatment_comparisons.json` 等を提供、「paper-interface は raw run directory を一次入力にしない」と明記。
- paper-interface tasks.md Task 3/4 は `experiments/analysis/` 相対で evaluation 出力を読み「runtime raw artifact を一次入力にしない」、Task 4 は `evidence_class` を foundation 所有として「foundation 由来フィールドを再定義しない」と明記。
- self-improvement tasks.md Task 2 は evaluation analysis output（classification index / metrics / caveat register）を入力とし §5 で「evaluation の analysis output 確定が前提」と blocking 明記。
- **整合判定**: 下流 consumer は evaluation 出力を再定義せず参照、raw 迂回禁止が双方向一致。**横断整合。不整合なし**（F-8 の field naming 確定タイミングを除く）。

所見 F-8（軽微）

- 所在: evaluation tasks.md §5 末尾 / paper-interface tasks.md §5
- 問題: evaluation §5「evaluation comparison artifact field naming 確定が paper-interface bundle task の前提（後段 alignment で詰める）」、paper-interface §5「Task 3〜7 は evaluation の comparison / exclusion / caveat artifact 確定が前提」。両者は整合するが、evaluation tasks.md は comparison artifact（`treatment_comparisons.json` / `phase_comparisons.json`）の field naming を Task 5 完了条件で確定する旨を明示していない（Task 5 完了条件は「比較可能性条件を満たさない set が aggregate されない」「valid population のみで計算」の 2 点のみ）。横断タスク（field naming 固定）の独立性が evaluation 側 Task に内在化されておらず「後段 alignment で詰める」に委ねられている。
- 根拠: phase-and-feature-dependency-map §7「paper-interface bundle 実装より前に evaluation comparison artifact field naming が固まっているか」。
- 推奨対応: Task 5 完了条件に「`treatment_comparisons.json` / `phase_comparisons.json` の field naming を確定し downstream（paper-interface）が参照可能にする」を追記、または §5 で「field naming 確定は tasks alignment gate の横断議題」と横断タスク化を明示。

**必要性判定**: F-8 は軽微。design「Open Issues for Design Alignment Gate: paper-interface 向け comparison artifact の field naming」が未解決のため、現時点でタスクに確定値を書けない（design 未確定）。alignment gate 送りが妥当。タスクには「横断議題である」明示のみ追記が望ましい → **自動採択候補**（議題明示の追記、確定値は alignment gate）。

**横断タスク独立切り出し総括**: evaluation は analysis layer であり「移行スクリプト」相当の横断タスクは無い（raw 不変・derived 生成のみ、design Decision 1）。共通契約（A-7）は consumer 依存宣言として各 Task に内在化され独立タスク不要。命名統一は F-8 の field naming が唯一の横断議題で alignment gate 送りが正本方針と整合。**横断タスクの独立切り出し漏れによる致命的欠落なし**。

---

## 観点 6: 失敗時の巻き戻し単位

**要点**: タスク失敗時の影響範囲・巻き戻し単位が明示されているか。

**詳細抽出**:

- runtime tasks.md は §5.2「失敗時の巻き戻し単位」独立小節で「Task 1〜5・10 は task-local 吸収。Task 6/7/9 で foundation 契約不足が判明したら handback class C で foundation へ戻す」と handback class（WORKFLOW_OVERVIEW §4 / workflow-repair-procedure）に紐付け明示。
- self-improvement / paper-interface tasks.md も §5 Blocking Dependencies に巻き戻し前提（foundation 契約起点）を記述。
- **evaluation tasks.md には失敗時巻き戻し単位の独立記述が無い**。§5 Blocking Dependencies は外部前提列挙のみで、各 Task 失敗時にどこへ handback（A: task-local / B: design / C: requirements / D: intent）するかの分類が無い。

**深掘り**:

所見 F-9（重要）

- 所在: tasks.md §5（Blocking Dependencies のみで巻き戻し単位節が欠落）
- 問題: 節 5 観点 6 が要求する「タスク失敗時の影響範囲・巻き戻し単位の明示」が evaluation tasks.md に存在しない。runtime tasks.md §5.2 が先例として handback class（A/B/C/D、WORKFLOW_OVERVIEW §4）に紐付けた巻き戻し単位を明示しているのと非対称。evaluation 固有のリスク：(a) Task 2/3 が runtime export manifest shape / `comparison_eligibility_note` 確定前に着手すると handback C（runtime/foundation contract 不足）、(b) Task 8 が foundation 無効化伝播義務確定前なら handback C、(c) Task 4 の overlay は design open issue 未解決のため handback B（design 境界）。これらが未分類のため、実装中に問題検出した際の reopen 種別判定（WORKFLOW_OVERVIEW §5 ステップ 2）の起点が tasks.md に無い。
- 根拠: REVIEW_PROTOCOL 節 5 観点 6、WORKFLOW_OVERVIEW §4 handback class、runtime tasks.md §5.2 先例。
- 推奨対応: §5 に「5.x 失敗時の巻き戻し単位」小節を追加。最低限：Task 1/6/7（artifact skeleton/reporting/imports）= task-local 吸収（handback A）。Task 2/3 で runtime export shape または `comparison_eligibility_note` 最小項目不足が判明したら handback C で runtime へ。Task 2 で foundation metadata contract / evidence_class 不足なら handback C で foundation へ。Task 4 で overlay 初版集合が design 未確定で詰まれば handback B で design へ。Task 8 で foundation 無効化伝播義務不足なら handback C で foundation へ。raw 不変原則（design Decision 1）により実行時巻き戻しは derived artifact 再生成に閉じ raw を編集しない旨も明記。

**必要性判定**: F-9 は重要。観点 6 が明示要求する記述の欠落であり、runtime tasks.md に一意な先例がある。修正案（handback class 紐付け巻き戻し小節追加）は致命的デメリットなく内容が design/dependency-map から一意導出可能 → **自動採択候補**。ただし各 Task の handback class 割当（特に Task 4 を B か C か）に複数解釈余地があるため、割当の最終確定は**利用者判断**寄り（must-fix、割当細部は利用者確認）。

---

## 観点 7: 波及精査（最終ガード）

**要点**: 観点 1〜6 の所見が他 feature・他 Task に波及するか全件明示。

**詳細抽出（所見ごとの波及）**:

- F-1 / F-5（Task 4 overlay 初版・design open issue 連動）: 波及先 = design.md「Open Issues」（既存・修正不要、連動明示のみ）。他 spec 波及**なし**。
- F-2 / F-3（完了条件への決定的検証ケース二重化）: evaluation tasks.md 内に閉じる。他 spec 波及**なし**。
- F-4（Task 3↔7 admission 判定所有一意化 + 依存グラフ小節）: evaluation tasks.md 内に閉じる。design「Admission States」は既に「classification の前段」と所有意図を持つため design 修正不要。他 spec 波及**なし**。
- F-6（Req5 受入 4 トレース可視化）: evaluation tasks.md 内に閉じる。他 spec 波及**なし**。
- F-7（`decisions/decision_units.json` の runtime §4 Downstream Handoff 欠落）: **runtime tasks.md へ波及あり（1 件）**。runtime tasks.md §4 Downstream Handoff の evaluation 行に `decisions/decision_units.json` が欠落しており、evaluation Task 2/4 の decision_units 依存と非対称。tasks alignment gate で双方向同期が必要。evaluation 側は design「Intake Model」（decision_units を最小 intake に含む）と整合しているため evaluation 側 tasks.md の修正は不要。runtime tasks.md §4 への追記提案として alignment gate へ申し送る。
- F-8（comparison artifact field naming 横断議題明示）: paper-interface tasks.md §5 と論理的に関連するが paper-interface 側は既に「evaluation の comparison artifact 確定が前提」と blocking 明記済みで対応済。design「Open Issues」が未解決事項として保持。**新規の他 spec 波及なし**（既存 blocking 記述で吸収済、B 群相当）。
- F-9（巻き戻し単位小節追加）: 内容は dependency-map / foundation / runtime 契約から導出するが、参照のみで他 spec 文書の修正は不要。他 spec 波及**なし**。

**波及精査総括**:

- **他 5 spec への波及: 1 件（F-7 → runtime tasks.md §4 Downstream Handoff の evaluation 行に `decisions/decision_units.json` 追記）**。
- 他は全て evaluation tasks.md 内に閉じるか、既存 blocking 記述で吸収済（波及なしを明示記録）。
- foundation / self-improvement / paper-interface / implementation-governance tasks.md への新規波及は**なし**（明示記録）。

---

## 集計

### 重大度別件数

- 致命: 0 件
- 重要: 3 件（F-2、F-4、F-9）
- 軽微: 6 件（F-1、F-3、F-5、F-6、F-7、F-8）
- 合計: 9 件

### 観点別「該当なし」概況

- 観点 1（設計網羅）: 重大欠落なし。F-1（軽微・overlay 確定タイミング）のみ。
- 観点 2（粒度・完了基準）: 粒度は適正。完了基準の機械検証二重化欠落（F-2 重要、F-3 軽微）。
- 観点 3（依存・順序）: 循環なし。admission 所有二重 + 依存グラフ小節欠落（F-4 重要）、overlay 依存未記載（F-5 軽微）。
- 観点 4（トレース）: 要件 1〜10 全受入に重大被覆欠落なし。Req5 受入 4 のトレース可視化軽微（F-6）。
- 観点 5（横断タスク）: A-7 / foundation 語彙 / 下流 consumer 整合は良好（不整合なし）。decision_units 双方向欠落（F-7 軽微・runtime 波及）、field naming 横断議題明示（F-8 軽微）。
- 観点 6（巻き戻し単位）: 独立記述が欠落（F-9 重要）。
- 観点 7（波及）: 他 5 spec 波及 1 件（F-7）、他は波及なしを全件明示。

### must-fix 候補一覧

- F-2（重要・粒度/完了基準）: Task 3/4/5/8 完了条件に Task 9 決定的検証ケース pass を併記し検証中立性を担保。— 修正案一意で自動採択候補。検証対応付けの細部は利用者判断。
- F-4（重要・依存/順序）: admission state 判定の所有を Task 7 に一意化（Task 3 は参照のみ）+ §5 に Task 間依存グラフ小節追加。— 依存グラフ追加は自動採択候補。所有先確定（Task 7 か Task 3 か）は構造的決定のため利用者判断。
- F-9（重要・巻き戻し単位）: §5 に handback class 紐付け「失敗時の巻き戻し単位」小節を追加。— 小節追加は自動採択候補。各 Task の handback class 割当（特に Task 4=B/C）は利用者判断。

### 軽微（自動採択候補、致命的デメリットなし）

- F-1/F-5: Task 4 overlay 初版集合の design open issue 依存を §5 / Task 4 完了条件に 1 行明示。
- F-3: Task 9 完了条件に検証ケース最小本数・着手前客観基準確定を追記。
- F-6: Req5 受入 4 のトレースを Task 根拠または §4 で可視化。
- F-7: runtime tasks.md §4 Downstream Handoff の evaluation 行に `decisions/decision_units.json` を追記（**他 spec 波及・tasks alignment gate 申し送り**）。
- F-8: comparison artifact field naming を tasks alignment gate 横断議題と明示（確定値は alignment gate）。

### 総合所見

- **致命所見 0 件**。設計全件網羅・要件トレース・横断契約整合（評価 A-7 / foundation 語彙 / 下流 consumer 非再定義）は良好で、tasks.md の骨格は妥当。
- ただし**重要 3 件（F-2 完了基準の機械検証中立性、F-4 admission 所有二重 + 依存グラフ欠落、F-9 巻き戻し単位欠落）は、いずれも sibling の runtime tasks.md が備える要素の欠落**であり、tasks 文書としての検証可能性・依存明示・失敗時手続きの観点で sibling spec と非対称。横断整合ゲートへ進める前に重要 3 件の must-fix 適用が望ましい（特に F-4 の admission 所有一意化は実装時の二重実装リスクを除去する）。
- **他 5 spec 波及は F-7 の 1 件**（runtime tasks.md §4 への decision_units 追記）。これは tasks alignment gate の双方向同期議題として申し送る。evaluation tasks.md 側の修正は不要（design Intake Model と整合済）。
- 推奨進行: 重要 3 件（F-2/F-4/F-9）を 1 件ずつ利用者承認で適用 → 軽微 6 件は自動採択候補として一括または個別適用 → その後 tasks 横断整合ゲート（F-7 / F-8 を横断議題に持ち込む）へ進む。must-fix 未適用のまま横断ゲートへ進むのは非推奨。

---

_証跡パス: `.kiro/specs/dual-reviewer-evaluation/reviews/tasks-local-review-2026-05-18.md`（本ファイル、不変）_
