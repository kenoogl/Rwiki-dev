# タスク個別レビュー（dual-reviewer-paper-interface）

_実施日: 2026-05-18_
_対象: `.kiro/specs/dual-reviewer-paper-interface/tasks.md` 全体_
_手順: `operations/REVIEW_PROTOCOL.md` 節 5（タスクレビュー 7 観点）_
_位置づけ: 起草者と独立した批判的タスク個別レビュー。本セッション前半で paper-interface tasks.md を承認済み requirements/design から全面再導出した際に省略した正規タスク個別レビューの正規実施。生証跡として不変。本レビューは所見のみで tasks.md / design.md / requirements.md / spec.json を変更しない_

入力（すべて絶対パス）:

- 主対象: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/tasks.md`
- 設計正本: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/design.md`
- 要件参照: `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/requirements.md`（Requirement 1〜6）
- 横断参照: foundation / evaluation / runtime / self-improvement / implementation-governance の tasks.md
- 上位正本: `operations/REVIEW_PROTOCOL.md` 節 5、`docs/alignment/phase-and-feature-dependency-map.md`、`CONVENTIONS.md`
- 参考（独立判断・鵜呑みにしない）: runtime / evaluation / self-improvement の `reviews/tasks-local-review-2026-05-18.md`

---

## 0. 依存マップ確認結果（横断・順序判断の前提）

`docs/alignment/phase-and-feature-dependency-map.md` を確認した。判断に効く点:

- §4.6 paper-interface は foundation に `hard dependency`、evaluation に `hard dependency`、runtime に `no primary dependency`。paper-interface は consumer であり producer に成果物を渡さない。paper-facing provenance は evaluation output 経由で継承する（runtime raw を standard source にしない）。
- §5.3 Tasks Wave 推奨順序: `foundation → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance`。paper-interface tasks は最後段（evaluation output contract 確定後）。
- §6 Current Blocking Points: 「paper-interface は evaluation consumer のまま据え置く」。
- §7 Tasks Alignment Checklist: 「paper-interface bundle 実装より前に evaluation comparison artifact field naming が固まっているか」が最低限の確認対象。
- §8.1: prescribed workflow process は workflow execution ledger を前提とするが、本タスク文書は paper-interface feature の実装単位分解であり process 段集合の権威ソースではない（authority-map 対象外）。

結論: paper-interface tasks.md §5 が evaluation comparison artifact field naming 確定・foundation `evidence_class`/`review_mode` 語彙確定・evaluation staleness 伝播（foundation 要件 6 受入 9 起点）確定を blocking として明示しているのは依存マップ §5.3 / §6 / §7 と整合。横断順序の即興導出はせず本正本に従って観点 3 / 5 を判定した。

横断構造決定（feature 間依存・順序）について本正本に明示のない新規事項は本レビューで検出せず（規律 `discipline_ssot_structural_decision_check.md` 該当なし）。evaluation comparison artifact field naming は design「Open Issues for Design Alignment Gate」で未確定のため tasks alignment gate の横断議題であり、本タスク文書側で確定値を書くべきでない（evaluation tasks.md §5 / §5.1 と双方向整合）。

---

## 観点 1: 設計全件の網羅

### 要点

design.md の全構成要素を列挙し tasks.md Task 1〜9 への割当を全件突合した。

### 詳細突合（design 構成要素 → 担当 Task）

- Overview / Goals / Non-Goals / Design Drivers → Task 1〜9 の根拠記述・§1 役割文に分散反映。網羅。
- Architecture（claim mapping → reporting bundle → caveat attachment → export fragments の 4 段）→ tasks.md §2 理由節が 4 段を明示。網羅。
- Components（claim mapper / reporting bundle builder / caveat-maturity annotator / export fragments）→ Task 3 / 5・7 / 6 / 7。網羅。
- Paper Artifact Layout（`reports/` `tables/` `figures/` `caveats/` 全 6 ファイル）→ Task 1 が全件列挙。網羅。
- Placement Rationale → Task 1 完了条件（caveat 残置説明・分離）。網羅。
- Claim Mapping Model §1 Claim Unit → Task 3。網羅。
- Claim Mapping Model §2 Supporting Artifact Sources（標準 source 限定・`experiments/analysis/` 相対・runtime raw 非一次入力）→ Task 3。網羅。
- Claim Mapping Model §3 Reference Format（全モデル共通）→ Task 2。網羅（先行固定の意図も §2 理由節に明示）。
- Evidence Register Model §1 Evidence Maturity（mature/preliminary/exploratory・caveated は label でなく caveat_refs・evidence_class 束縛規則）→ Task 4。網羅。
- Evidence Register Model §2 Provenance Fields（9 フィールド）→ Task 4。網羅。
- Evidence Register Model §3 Review-Mode in Reporting（受入 1〜5・混在検知条件＝review_mode 2 値以上）→ Task 4 + Task 9。網羅。
- Figure and Table Bundle Model §1/§2 → Task 5。網羅。
- Caveat and Limitation Model（6 フィールド・`limitation_type` 3 正準値）→ Task 6。網羅。
- Reporting Fragment Model（6 フィールド・`fragment_type` 例・成熟度集約規則）→ Task 7。網羅。
- Separation Rules §1〜§4（no reverse control / no silent strengthening / self-improvement independence / stale upstream regeneration）→ Task 8。網羅。
- Interfaces to Other Features（Evaluation / Self-Improvement / Runtime）→ tasks.md §4 Downstream Handoff。網羅。
- Key Decisions 1〜4 → Task 3（D1）/ Task 4（D2）/ Task 7（D3）/ Task 8（D4）に分散反映。網羅。
- Requirements Traceability 表 → tasks.md 各 Task 根拠行に対応。網羅。
- Test Strategy（4 つのテスト可能性の縫い目）→ Task 9 が 4 点を列挙。網羅。
- Open Issues for Design Alignment Gate（claim ID taxonomy / figure-table field naming / adopted change history 範囲）→ tasks.md §5 が field naming を blocking 明示。claim ID taxonomy と adopted change history 範囲は後述 所見 P1-A。
- Completion Criteria（4 点）→ tasks.md §6 + Task 9 完了条件。網羅。

### 深掘り — design に存在するが Task に明示反映が弱い要素

- 所見 P1-A（軽微）: 所在 = tasks.md 全体 / design「Open Issues for Design Alignment Gate」。問題 = design は未解決事項を 3 件挙げる（claim ID taxonomy をどこまで formalize するか / figure-table bundle field naming を evaluation とどこまで揃えるか / adopted change history を methodology note に含める範囲）。tasks.md §5 Blocking Dependencies は evaluation comparison artifact field naming 確定を前提に挙げるが、(a) claim ID taxonomy の確定タイミング（Task 3 の `claim_id` 体系）と (b) adopted change history 範囲（Task 8 の self-improvement independence、methodology note 参照範囲）が design open issue であることを §5 に列挙していない。evaluation tasks.md §5 が「Task 4 の phase-specific overlay 初版集合は design alignment open issue 解決後に確定」と自 feature の design open issue 依存を明示する先例があるのに対し、paper-interface は field naming（1 件）のみ明示し残り 2 件の design open issue 依存が tasks に内在化されていない。根拠 = design「Open Issues for Design Alignment Gate」3 行、phase-and-feature-dependency-map §7。推奨対応 = §5 に「Task 3 の claim ID taxonomy 形式化範囲、Task 8 の adopted change history methodology note 参照範囲は design alignment open issue 解決後に確定（tasks alignment gate で詰める）」を 1〜2 行追記。重大度 = 軽微（実装は最小契約で着手可能で確定値は alignment gate 送りが妥当。確定タイミングの可視化のみ）。必要性判定 = 自動採択（evaluation tasks.md 先例あり、修正案一意、致命的デメリットなし）。

### 該当なし

design の主要構造要素（Paper Artifact Layout 全 6 ファイル、Claim Mapping Model §1〜§3、Evidence Register Model §1〜§3、Figure/Table Bundle Model、Caveat and Limitation Model、Reporting Fragment Model、Separation Rules §1〜§4、Test Strategy 4 縫い目、Completion Criteria 4 点）は Task 1〜9 に漏れなく割当済み。観点 1 の致命・重要級の網羅漏れは検出せず（P1-A は欠落でなく確定タイミング可視化の軽微）。

---

## 観点 2: タスクの粒度と完了基準

### 要点

Task 1〜9 各々の作業量と完了条件の明示性を検査。タスク特有方針「1 タスクは半日〜数日」「検証手段の事前確定（実装後の後付けは検証中立性を失う）」を適用。sibling（runtime/evaluation/self-improvement）の「Task テストの決定的検証ケースで pass」二重化の有無を重点確認。

### 詳細抽出

- 全 9 Task が「作業」「完了条件」を持つ。Task 数 9 件（10 件以下）で粒度は単一 artifact 群に閉じ過大ではない。
- Task 1〜8 の完了条件は大半が「説明できる」「機械検証できる」「分離されている」型の定性／静的基準。
- Task 9（テスト）完了条件 = 「design Test Strategy 4 点が検証できる」「design Completion Criteria 4 点を満たす」のみ。

### 深掘り — sibling 非対称の重点確認

- 所見 P2-A（重要・sibling 非対称）: 所在 = Task 3 / 4 / 8 / 9 完了条件。問題 = sibling 3 spec はいずれも Task 完了条件に「Task 9（または Task 11）の決定的検証ケースで pass する」を併記し、説明可能性と機械検証を二重化している（runtime Task 3/6/7、evaluation Task 3/4/5/8、self-improvement Task 2/3/5/7/相当）。paper-interface tasks.md にはこの二重化が**全く無い**。Task 3（claim mapping＝証拠追跡性機械検証の主対象）、Task 4（evidence register＝無声昇格検出・review_mode 混在検知の主対象）、Task 8（separation rules＝stale 再生成検出の主対象）の完了条件はすべて「説明できる」「再生成対象になる」型の定性基準に留まり、Task 9 の決定的検証との結合が宣言されていない。根拠 = REVIEW_PROTOCOL 節 5 タスク特有方針「検証手段の事前確定：実装後に基準を後付けすると検証の中立性が失われる」、sibling 3 spec の一意な先例。design Test Strategy は 4 点とも machine 検証可能な対象（証拠追跡性の machine 解決・無声昇格検出・review_mode 混在 caveat・stale 再生成検出）として実在し、Task 9 作業項目もこれを列挙済み。完了条件と Task 9 の結合が明示されていないだけ。推奨対応 = Task 3 完了条件に「証拠追跡性の機械検証が Task 9 の決定的検証ケースで pass する」、Task 4 完了条件に「無声昇格検出・review_mode 混在 caveat 検証が Task 9 の決定的検証ケースで pass する」、Task 8 完了条件に「stale 再生成検出が Task 9 の決定的検証ケースで pass する」を併記し、sibling 3 spec と同形に二重化する。Task 1（skeleton）/ Task 5 / Task 6 / Task 7 は artifact 存在・分離の静的検証で代替可。重大度 = 重要（検証中立性は節 5 が明示要求する規律。sibling 全 3 spec が備える要素の paper-interface 単独欠落＝同型 sibling 非対称の中核所見）。必要性判定 = 自動採択（修正案が sibling 先例で一意、致命的デメリットなし）。ただし「どの完了条件にどの検証を結ぶか」の対応付け粒度は複数の合理的割当があり対応付け細部は利用者確認が望ましい（must-fix、細部は利用者判断）。

- 所見 P2-B（軽微・sibling 非対称）: 所在 = Task 9 完了条件。問題 = sibling（runtime Task 11 / evaluation Task 9 / self-improvement Task 9）はテスト Task 完了条件に「列挙 N 検証対象それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass する（着手前に客観基準を確定、TDD 先行）」と検証ケースの最小本数・着手前確定の客観閾値を明記している。paper-interface Task 9 は検証対象 4 項目（証拠追跡性／無声昇格／混在 review_mode caveat／陳腐化再生成）を列挙し「TDD: 先にテストを用意し失敗を確認してから実装」と書くが、「各検証対象に最低 1 ケース」「着手前に客観基準確定」の客観閾値表現が完了条件に無い。根拠 = 節 5「検証手段の事前確定」、sibling 3 spec の一意な先例。推奨対応 = Task 9 完了条件に「列挙 4 検証対象（証拠追跡性／無声昇格／混在 review_mode caveat／陳腐化再生成）それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass する（着手前に客観基準を確定、TDD 先行）」を追記。重大度 = 軽微（P2-A と同系統、先例で修正案一意）。必要性判定 = 自動採択（P2-A 採択時に同時適用が自然、致命的デメリットなし）。

### 該当なし

Task 1〜9 の粒度は半日〜数日相当で完了条件も列挙的。粒度過大による必須サブタスク分解は検出せず（横断的 feature だが各 Task は単一モデル/規則群に閉じる）。観点 2 の致命級なし。重要 1 件・軽微 1 件はいずれも sibling が備える完了基準の機械検証二重化の欠落。

---

## 観点 3: 依存関係と順序

### 要点

tasks.md §2 実装順序（1→9）と §5 Blocking Dependencies、依存マップ §5.3 / §6 / §7 を突合。前提先行・循環の有無を検査。Task 件数（9 件、10 件以下）で依存グラフ別表は方針上必須閾値未満だが、sibling 3 spec が §5.1（Task 間依存グラフ）・§5.2（失敗時巻き戻し単位）小節を備える非対称を重点確認。

### 詳細抽出

- §2 順序: skeleton → reference format → claim mapping → evidence register → figure/table bundle → caveat → reporting fragment → separation rules → テスト。前提先行は妥当（reference format が全モデル共通で先、stale 再生成が evaluation staleness 伝播入力起点で後段）。理由節が design「Architecture」根拠で記述。
- §5 Blocking Dependencies: Task 3〜7 が evaluation comparison/exclusion/caveat artifact 確定前提、Task 4 が foundation `evidence_class`/`review_mode` 語彙確定前提、Task 8 が evaluation staleness 伝播（foundation 要件 6 受入 9 起点）確定前提を外部 blocking として明示。依存マップ §5.3 / §6 / §7 と整合。
- 循環依存: Task 間に明示的循環は無い。ただし観点 2 所見 P2-A の「各 Task 完了条件 ⇄ Task 9 テスト」は sibling 同様の実質的定義循環（テスト結合未宣言で完了判定が定性に留まる）。

### 深掘り — sibling 非対称の重点確認

- 所見 P3-A（重要・sibling 非対称）: 所在 = tasks.md §5（Blocking Dependencies のみで §5.1 / §5.2 相当の小節が欠落）。問題 = sibling 3 spec はいずれも §5 配下に「5.1 Task 間依存グラフ（§2 から導出、並列可を明示）」「5.2 失敗時の巻き戻し単位（handback class A/B/C/D 紐付け）」の 2 小節を備える（runtime §5.1/§5.2、evaluation §5.1/§5.2、self-improvement §5.1/§5.2）。paper-interface tasks.md §5 は外部 blocking dependency の箇条書きのみで、(a) Task 間内部依存グラフ（どの Task がどの Task の出力を入力にするか、並列実行可能ペア）、(b) 失敗時巻き戻し単位（handback class 紐付け）の独立小節が**両方とも欠落**している。Task 9 件は別表必須閾値（10 件超）未満だが、sibling 3 spec が 9〜11 件規模でいずれも §5.1/§5.2 を備えており、paper-interface 単独でこの 2 小節を欠くのは横断整合上の明確な非対称。特に Task 2（reference format 共通基盤）は Task 3〜8 の全モデルが依存する hub であり、Task 9（テスト）が全 Task と並走 TDD する関係が散文の §2 順序からは一意に追えない。根拠 = REVIEW_PROTOCOL 節 5 観点 3 / 観点 6、sibling 3 spec の一意な先例。本所見は §5.1（依存グラフ）と §5.2（巻き戻し単位＝観点 6）の双方に跨るため、§5.1 を本観点で、§5.2 を観点 6（所見 P6-A）で計上する。推奨対応（§5.1 分）= §5 に「5.1 Task 間依存グラフ（§2 から導出、並列可を明示）」小節を追加。例: Task 1（paper skeleton）が起点 → Task 2（reference format、全モデル共通 hub）→ {Task 3（claim mapping）, Task 4（evidence register）}→ Task 5（figure/table bundle、Task 4 maturity 参照）→ Task 6（caveat、Task 3 claim_refs 参照）→ Task 7（reporting fragment、Task 3/4/6 出典参照）→ Task 8（separation rules、全モデルに stale 標識付与）→ Task 9（テスト、全 Task と並走 TDD）。並列可: Task 3 と Task 4 は reference format 確定後に並行着手可。外部前提（evaluation comparison field naming / foundation 語彙 / evaluation staleness 伝播）も明示。重大度 = 重要（sibling 全 3 spec が備える依存明示の paper-interface 単独欠落＝同型 sibling 非対称。§2 直列順序で実装は可能だが横断ゲートで再検出される片肺）。必要性判定 = 自動採択（内容は §2 から機械導出可能、sibling 先例で一意、致命的デメリットなし）。

### 該当なし

循環依存は実装順序上は無し（P2-A の定義循環は観点 2 で計上、P2-A 採択で解消）。foundation/evaluation 先行という外部依存は §5 が明示し依存マップと整合。前提先行違反（例: runtime の prompt resolution 順序問題のような順序入替を要する致命級）は paper-interface には該当なし（reference format → 各モデルの前提順は妥当）。重要 1 件は §5.1 相当小節の欠落（sibling 非対称）。

---

## 観点 4: 要件 / 設計とのトレース

### 要点

各 Task の「根拠」行が要件番号・設計章を引いているか全件確認。Requirement 1〜6 の全受入が Task に被覆されるか突合。

### 詳細抽出（Task → 引用）

- Task 1: Requirement 2 受入 3、design「Paper Artifact Layout」「Placement Rationale」。可。
- Task 2: Requirement 1 受入 5、design「Claim Mapping Model §3 Reference Format」。可。
- Task 3: Requirement 1（受入 1〜6）、Requirement 4 受入 1、design「Claim Mapping Model §1〜§2」。可。
- Task 4: Requirement 5（受入 1〜6）、Requirement 6（受入 1〜5）、Requirement 1 受入 2、design「Evidence Register Model §1〜§3」。可。
- Task 5: Requirement 2（受入 1・2・4・5）、design「Figure and Table Bundle Model §1〜§2」。可。
- Task 6: Requirement 3（受入 1〜5）、design「Caveat and Limitation Model」。可。
- Task 7: Requirement 5 受入 3・4、design「Reporting Fragment Model」「Key Decision 3」。可。
- Task 8: Requirement 4（受入 1〜5）、Requirement 2 受入 6、design「Separation Rules §1〜§4」。可。
- Task 9: design「Test Strategy」、プロジェクト TDD 方針。可（要件番号は無いがテスト Task の性質上 design 章引用で妥当）。

### 深掘り（要件 1〜6 全受入の被覆確認）

- Req1（受入 1〜6）: 受入 1（claim→evidence source 定義）=Task 3、受入 2（run/analysis provenance 保持）=Task 3+Task 4、受入 3（direct vs caveated/preliminary 区別）=Task 3、受入 4（evaluation output consume・raw 非再解釈・無ければ評価実行要求）=Task 3、受入 5（versioned evidence に辿れない artifact 不許可）=Task 2+Task 3、受入 6（claim 定義＝identifier+evidence-source linkage）=Task 3。被覆。
- Req2（受入 1〜6）: 受入 1（figure/table required fields）=Task 5、受入 2（evaluation output への provenance linkage）=Task 5、受入 3（raw/core evaluation output と分離）=Task 1、受入 4（upstream 不変時 regeneration）=Task 5、受入 5（formatting 都合で runtime/foundation schema 変更強制しない）=Task 5、受入 6（upstream stale 時 regeneration）=Task 8。被覆。
- Req3（受入 1〜5）: 受入 1（evidence source 紐づき caveat metadata 保持）=Task 6、受入 2（invalid-data exclusion/partial/methodological 区別）=Task 6、受入 3（raw archive 手読みなし caveat 参照）=Task 6、受入 4（preliminary labeling 支援）=Task 6、受入 5（caveated→strong silent 格上げ禁止）=Task 6。被覆。
- Req4（受入 1〜5）: 受入 1（evaluation output consume・rule 直接改変しない）=Task 3+Task 8、受入 2（runtime-critical metadata を foundation 独立に定義しない）=Task 5+Task 8、受入 3（invalidation policy override しない）=Task 8、受入 4（paper convenience を reproducibility/validity に従属）=Task 8、受入 5（downstream narrative transformation を explicit/versionable）=Task 8。被覆。
- Req5（受入 1〜6）: 受入 1（preliminary 明示 labeling）=Task 4、受入 2（stable comparison set vs exploratory 由来保持）=Task 4、受入 3（mixed-maturity は区別可視時のみ）=Task 4+Task 7、受入 4（mature/preliminary を未分化 artifact に潰さない）=Task 4+Task 7、受入 5（refinement/replacement traceability 保持）=Task 4、受入 6（単一統一 evidence 分類語彙、foundation evidence-class 束縛）=Task 4。被覆。
- Req6（受入 1〜5）: 受入 1（review-mode provenance 保持）=Task 4、受入 2（手動 dogfooding と runtime-mediated 分離報告）=Task 4、受入 3（手動記録を明示ラベルなし runtime 産出証拠として提示しない）=Task 4、受入 4（混在時 caveat 付与）=Task 4+Task 9、受入 5（早期手動→後 runtime 置換 traceability）=Task 4。被覆。

### 深掘り — トレース可読性

- 所見 P4-A（軽微）: 所在 = Task 4 根拠行。問題 = Task 4 は Requirement 5（受入 1〜6）と Requirement 6（受入 1〜5）と Requirement 1 受入 2 を一括で引くが、Task 4 が requirements 3 件・受入 12 件超を単一 Task に集約する最大トレース密度 Task でありながら、各受入と作業項目の対応が根拠行で粒度分解されていない（runtime tasks.md レビュー所見 T4-A と同系統のトレース可読性問題）。被覆自体は上記突合で確認済みで欠落ではないが、Task 4 の作業項目（maturity label / evidence_class 束縛 / provenance fields / review-mode / supersession）のどれが Req5 のどれ・Req6 のどれを満たすかが読者突合を要する。根拠 = トレース可読性（抜けではなく分割明示の弱さ）。推奨対応 = Task 4 作業項目の各箇条に対応受入を括弧付記（多くは既に付記済みのため、未付記の作業項目に Req5 受入 1・2 / Req6 受入 1〜5 の対応を補う程度の軽微補修）。重大度 = 軽微。必要性判定 = 自動採択（トレース可読性補修、致命的デメリットなし。なお現状 Task 4 作業項目は概ね受入番号付記済みで補修量は最小）。

### 該当なし

全 Task が要件番号 + 設計章を引いており、トレース欠落（要件を引かない Task・どの Task にも現れない受入基準）は検出せず。Requirement 1〜6 の全受入が Task 1〜9 に分散被覆。Requirement 1 受入 5（versioned evidence 追跡不能 artifact 不許可）も Task 2（reference format）+ Task 3 で機械検証可能形に被覆。観点 4 の致命・重要級なし（軽微 1 件はトレース可読性のみ）。

---

## 観点 5: 横断タスクの抽出

### 要点

複数 feature にまたがる作業（共通契約参照順序、foundation 語彙参照、evaluation analysis output 依存、命名統一）が独立タスク or 明示参照で consumer 側「依存・再定義しない／raw 迂回禁止」になっているか。foundation 語彙参照整合・evaluation comparison field naming 未確定の議題化・他 5 spec 波及を検査。

### 詳細抽出と深掘り

(A) evaluation 所有 analysis output への consumer 依存（treatment_comparisons / phase_comparisons / exclusion_report / caveat_register / analysis_run_manifest）

- paper-interface tasks.md Task 3 作業: supporting artifact source を `experiments/analysis/` 相対で解決し標準 source に限定（`comparisons/treatment_comparisons.json` / `comparisons/phase_comparisons.json` / `classifications/exclusion_report.json` / `caveats/caveat_register.json` / 必要に応じ `metrics/*.json`）。「runtime raw artifact を一次入力にしない」「evaluation output 不在時は生ログにフォールバックせず評価プロセス実行を要求」と明記。
- §4 Downstream Handoff: 読む対象を `analysis_run_manifest.yaml` / `treatment_comparisons.json` / `phase_comparisons.json` / `exclusion_report.json` / `caveat_register.json` と列挙。「runtime とは直接結合しない」。
- evaluation tasks.md §4 Downstream Handoff（paper-interface 行）= `treatment_comparisons.json` / `phase_comparisons.json` / `exclusion_report.json` / `caveat_register.json`（raw run directory を一次入力にしない）。evaluation Task 1 layout = `manifests/analysis_run_manifest.yaml` / `classifications/exclusion_report.json` / `comparisons/treatment_comparisons.json,phase_comparisons.json` / `caveats/caveat_register.json`。
- **整合判定**: paper-interface が読む 5 artifact 名（`analysis_run_manifest.yaml` / `treatment_comparisons.json` / `phase_comparisons.json` / `exclusion_report.json` / `caveat_register.json`）は evaluation 所有 layout・evaluation §4 paper-interface 提供行と**同一綴り・同一意味で一致**。consumer 側で再定義せず参照、raw 迂回禁止が双方向一致。**横断契約整合（evaluation analysis output 依存）は正しい。不整合なし**。

(B) foundation 語彙参照整合（`evidence_class` / `review_mode`）

- paper-interface tasks.md Task 4 作業: `maturity_label` を foundation `evidence_class`（valid/invalid/exploratory、foundation 要件 6 受入 8 所有）に束縛された派生分類とし「foundation 由来フィールドを再定義しない」と明記。`review_mode`（manual_dogfooding/runtime_mediated）を foundation 由来として保持・再定義しない。
- foundation tasks.md Task 3: `evidence_class`=`candidate`/`valid`/`invalid`/`exploratory`（Requirement 6 受入 8 所有、「downstream evaluation / paper-interface は再定義せず参照」）、`review_mode` canonical 語彙が最低限 `manual_dogfooding`/`runtime_mediated` を区別（Requirement 6 受入 6）と明記。
- **整合判定**: paper-interface は foundation `evidence_class`/`review_mode` を参照のみで再定義しない。束縛規則は paper-interface 側派生分類（`maturity_label`）の導出規約であり foundation 語彙の再定義ではない。foundation tasks.md の所有宣言と双方向一致。**foundation 語彙参照整合。不整合なし**。

(C) evaluation staleness 伝播（foundation 要件 6 受入 9 起点）への接続

- paper-interface tasks.md Task 8 作業: 上流 evaluation output が run 無効化で stale 扱いされた場合、出力変化時だけでなく上流陳腐化時にも paper-facing artifact を再生成対象とし、`stale`/`stale_reason`/`stale_source_ref`（foundation 要件 6 受入 9 の伝播を受ける）標識を持たせる。再生成自動起動主体・タイミングは実装委譲（信号表現契約のみ固定）。§5 で「Task 8 の evaluation staleness 伝播（foundation 要件 6 受入 9 起点）確定が前提」と blocking 明示。
- foundation tasks.md（grep 確認）: 無効化標識付与が下流派生成果物への陳腐化伝播義務を伴うことを contract 明記、具体的フラグ付け/再導出は evaluation / paper-interface に委ねる（Requirement 6 受入 9）。evaluation tasks.md Task 8: 事後 invalidate された run を含む derived artifact を stale 化、foundation 無効化伝播義務を入力起点。
- **整合判定**: foundation（義務 contract 所有）→ evaluation（derived stale 化）→ paper-interface（paper-facing stale 標識・再生成対象）の伝播鎖が 3 spec で一貫。paper-interface は伝播の受け手として「信号表現契約のみ固定、起動主体は実装委譲」と consumer 境界を明示。**staleness 伝播接続整合。不整合なし**。

(D) evaluation comparison artifact field naming 未確定（design open issue）の扱い

- paper-interface tasks.md §5: 「phase-and-feature-dependency-map §5.3 に従い paper-interface bundle 実装は evaluation comparison artifact の field naming 確定後に作る」「Task 3〜7 は evaluation の comparison/exclusion/caveat artifact 確定が前提」と blocking 明示。
- evaluation tasks.md §5: 「evaluation comparison artifact field naming 確定が paper-interface bundle task の前提（後段 alignment で詰める）」「`treatment_comparisons.json`/`phase_comparisons.json` の field naming 確定は tasks alignment gate の横断議題（design open issue。確定値は alignment gate で詰める）」。
- **整合判定**: paper-interface §5 と evaluation §5 は field naming 確定が paper-interface 着手前提という方向で双方向整合。確定値は design「Open Issues for Design Alignment Gate」が未解決のため両 spec とも tasks alignment gate 送りで一致。**横断議題化は正しく双方向に明示済み。不整合なし**（後述 P5-A の表現精緻化を除く）。

### 深掘り

- 所見 P5-A（軽微）: 所在 = paper-interface tasks.md §5。問題 = paper-interface §5 は「evaluation comparison artifact field naming 確定後に作る」「Task 3〜7 は evaluation artifact 確定が前提」と blocking として書くが、これが **tasks alignment gate の横断議題**（design open issue 未解決のため確定値は alignment gate で詰める）であることを paper-interface 側 §5 が明示していない。evaluation tasks.md §5 は「tasks alignment gate の横断議題」「確定値は alignment gate で詰める」と横断議題性を明示しているのに対し、paper-interface 側は単なる外部 blocking としてのみ記述し、確定主体（alignment gate）と確定タイミング（design open issue 解決後）が consumer 側 tasks に内在化されていない。横断議題は両 spec で対称に明示されるべき（evaluation 側のみ片側明示は横断整合の片肺）。根拠 = evaluation tasks.md §5「tasks alignment gate の横断議題」記述、phase-and-feature-dependency-map §7。推奨対応 = paper-interface §5 に「evaluation comparison artifact field naming は design alignment open issue 未解決のため tasks alignment gate の横断議題であり、確定値は alignment gate で詰める（evaluation tasks.md §5 と双方向整合）」を 1 行追記。重大度 = 軽微（blocking 自体は明示済みで実装着手判断は可能、横断議題性の対称明示のみ）。必要性判定 = 自動採択（evaluation 側に先例あり双方向対称化、確定値は alignment gate 送りで変わらず、致命的デメリットなし）。

### 他 5 spec 波及（明示記録）

- foundation tasks.md: 波及なし（paper-interface は consumer。foundation 所有 `evidence_class`/`review_mode` 語彙への参照整合は上記 (B) のとおり一致。foundation 要件 6 受入 9 の陳腐化伝播義務も foundation 側で「evaluation/paper-interface に委ねる」と既に明記済みで paper-interface 側追記は foundation 不変。foundation tasks への修正要求は本観点から発生せず）。
- evaluation tasks.md: 波及なし（記録のみ）。paper-interface が読む 5 artifact 名は evaluation 所有 layout・§4 paper-interface 提供行と一致。P5-A は paper-interface 側 §5 への横断議題性追記で解消し、evaluation tasks.md §5 は既に「tasks alignment gate の横断議題」を正しく明示済みで evaluation 側修正不要。
- runtime tasks.md: 波及なし。paper-interface は runtime と直接結合せず（依存マップ §4.6 no primary dependency）、自 tasks.md §4 で「runtime とは直接結合しない」と明示。runtime artifact 名への参照なし、命名衝突なし。
- self-improvement tasks.md: 波及なし。paper-interface tasks.md §4 / Task 8 が「self-improvement adopted history は system revision history 参照に留め runtime quality claim の一次根拠にしない」と consumer 境界を明示し、self-improvement 側の adopted history 所有と非競合。命名衝突なし。
- implementation-governance tasks.md: 波及なし。governance は paper-interface に review dependency のみ（依存マップ §4.7）、feature data contract を生成しない。paper-interface artifact 名（claim_map/evidence_register/reporting_fragments/table_source_bundle/figure_source_bundle/paper_caveat_register）は governance conformance metric 名と衝突しない。

命名衝突の全 spec 横断検査: `treatment_comparisons.json` / `phase_comparisons.json` / `exclusion_report.json` / `caveat_register.json` / `analysis_run_manifest.yaml` は producer（evaluation）と consumer（paper-interface）で同一綴り・同一意味で参照され、衝突・別義使用は検出せず。paper-interface 固有 artifact（`paper/caveats/paper_caveat_register.json` 対 evaluation `caveats/caveat_register.json`）は基準ディレクトリが異なり（design §2 明記）衝突しない。

---

## 観点 6: 失敗時の巻き戻し単位

### 要点

Task 失敗時の影響範囲・巻き戻し単位（handback class A/B/C/D 紐付け小節）が明示されているか。sibling 3 spec の §5.2 独立小節の有無を重点確認。

### 詳細抽出

- sibling 3 spec はいずれも §5.2「失敗時の巻き戻し単位」を独立小節で持ち handback class（WORKFLOW_OVERVIEW §4）に紐付け明示（runtime §5.2「Task 1〜5/10 task-local、Task 6/7/9 で foundation 契約不足なら handback C」、evaluation §5.2「Task 1/6/7 handback A、Task 2/3 で実行側 export shape 不足なら handback C、Task 4 overlay 未確定なら handback B/C」、self-improvement §5.2「Task 1〜4/6/8 handback A、Task 1/5/7 で foundation 契約不足なら handback C」）。
- **paper-interface tasks.md §5 には失敗時巻き戻し単位の独立小節が無い**。§5 Blocking Dependencies は外部前提（evaluation comparison field naming / foundation 語彙 / evaluation staleness 伝播）の箇条書きのみで、各 Task 失敗時にどこへ handback（A: task-local / B: design / C: requirements / D: intent）するかの分類が無い。

### 深掘り — sibling 非対称の重点確認

- 所見 P6-A（重要・sibling 非対称）: 所在 = tasks.md §5（Blocking Dependencies のみで §5.2 相当小節が欠落）。問題 = REVIEW_PROTOCOL 節 5 観点 6 が要求する「タスク失敗時の影響範囲・巻き戻し単位の明示」が paper-interface tasks.md に**存在しない**。sibling 全 3 spec が §5.2 で handback class 紐付け巻き戻し単位を明示しているのと非対称（observation 点 6 の同型 sibling 非対称の中核）。paper-interface 固有のリスク: (a) Task 3〜7 が evaluation comparison/exclusion/caveat artifact 確定前に着手すると handback C（evaluation analysis output contract 不足、evaluation は paper-interface に hard dependency 上流）、(b) Task 4 が foundation `evidence_class`/`review_mode` 語彙確定前なら handback C（foundation 契約不足）、(c) Task 8 が evaluation staleness 伝播（foundation 要件 6 受入 9 起点）確定前なら handback C（上流 foundation/evaluation 契約不足）、(d) claim ID taxonomy / adopted change history 範囲が design open issue 未解決で詰まれば handback B（design 境界、所見 P1-A 関連）。これらが未分類のため、実装中に問題検出した際の reopen 種別判定（WORKFLOW_OVERVIEW §5）の起点が tasks.md に無い。根拠 = REVIEW_PROTOCOL 節 5 観点 6、WORKFLOW_OVERVIEW §4 handback class、sibling 3 spec §5.2 の一意な先例。推奨対応 = §5 に「5.2 失敗時の巻き戻し単位」小節を追加。最低限: Task 1（paper skeleton）/ Task 2（reference format）/ Task 5/6/7（bundle/caveat/fragment モデル）= task-local 吸収（handback A）。Task 3〜7 で evaluation comparison/exclusion/caveat artifact contract 不足が判明したら handback C で evaluation へ。Task 4 で foundation `evidence_class`/`review_mode` 語彙不足なら handback C で foundation へ。Task 8 で evaluation staleness 伝播（foundation 要件 6 受入 9 起点）不足なら handback C で foundation/evaluation へ。claim ID taxonomy（Task 3）/ adopted change history 範囲（Task 8）が design open issue 未確定で詰まれば handback B で design へ（判定に迷う場合は保守規律により上流 C へ寄せる）。raw evidence 不変・paper convenience 従属原則（design Design Drivers, Separation Rules）により実行時の巻き戻しは paper-facing artifact 再生成に閉じ raw evidence・core evaluation output を編集しない旨も明記。重大度 = 重要（観点 6 が明示要求する記述の欠落、sibling 全 3 spec が備える要素の paper-interface 単独欠落＝同型 sibling 非対称）。必要性判定 = 自動採択（修正案が sibling 先例で一意、内容は依存マップ/foundation/evaluation 契約から導出可能、致命的デメリットなし）。ただし各 Task の handback class 割当（特に Task 4 / Task 8 を B か C か、claim ID taxonomy を B か C か）に複数解釈余地があるため割当の最終確定は利用者判断寄り（must-fix、割当細部は利用者確認）。

### 該当なし

実行時（paper-facing artifact 生成時）の巻き戻しは design Separation Rules（no reverse control・raw/core evaluation output 不変・paper convenience 従属）と Task 8（stale 標識・再生成対象）が単位を内包しており、致命級の実行時巻き戻し単位欠落は検出せず。所見 P6-A は開発時 handback 単位の独立小節欠落（sibling 非対称の重要 1 件）。

---

## 観点 7: 波及精査（最終ガード）

### 要点

観点 1〜6 の推奨対応が他 Task・他 feature へ生む連鎖を最終確認。波及あり/なしを全件明示。

### 変更候補リスト化（観点 1〜6 の推奨対応）

- P1-A: §5 に claim ID taxonomy / adopted change history 範囲の design open issue 依存を追記 → 波及精査
- P2-A: Task 3/4/8 完了条件に Task 9 決定的検証ケース pass を併記 → 波及精査
- P2-B: Task 9 完了条件に検証ケース最小本数・着手前客観基準確定を追記 → 波及精査
- P3-A: §5 に「5.1 Task 間依存グラフ」小節を追加 → 波及精査
- P4-A: Task 4 作業項目に Req5/Req6 受入対応を補付記 → 波及精査
- P5-A: §5 に evaluation comparison field naming の横断議題性を双方向対称で追記 → 波及精査
- P6-A: §5 に「5.2 失敗時の巻き戻し単位」小節を追加 → 波及精査

### 波及判定（全件明示）

- P1-A 波及: なし（paper-interface tasks.md §5 内追記。design「Open Issues」は既存・修正不要、依存可視化のみ。他 spec 不変）。
- P2-A 波及: paper-interface tasks.md 内 Task 3/4/8/9 に閉じる。他 spec 波及なし（テスト基準は paper-interface ローカル、evaluation/foundation 契約に触れない）。
- P2-B 波及: paper-interface tasks.md 内 Task 9 に閉じる。他 spec 波及なし。
- P3-A 波及: paper-interface tasks.md 内 §5/§2 に閉じる。依存グラフは §2 から機械導出で新依存を生まない。他 spec 波及なし。
- P4-A 波及: なし（トレース可読性補修、要件・設計不変、Task 4 内）。
- P5-A 波及: なし（paper-interface §5 への横断議題性追記。evaluation tasks.md §5 は既に「tasks alignment gate の横断議題」を正しく明示済みで evaluation 側修正不要＝双方向対称化の片側補修。他 spec 不変）。
- P6-A 波及: なし（paper-interface tasks.md §5 内小節追加、WORKFLOW_OVERVIEW §4 / 依存マップ / foundation・evaluation 契約の参照のみ、上位文書・他 spec 改版不要）。

### 連鎖更新漏れ精査

観点 1〜6 の全推奨対応は paper-interface tasks.md 内の作業項目・完了条件・§5 小節追加に閉じ、要件書・設計書・spec.json の改版を要しない（P1-A も design「Open Issues」記載済みで設計改版不要、P5-A も evaluation 側既存記述で対称化のみ）。他 5 spec tasks への修正波及は **0 件**（evaluation/foundation は記録のみ・既存記述で正しく修正不要、runtime/self-improvement/governance は命名・参照整合確認済みで波及なし）。連鎖更新漏れは検出せず。

---

## 集計

### 重大度別件数

- 致命: 0 件
- 重要: 3 件（P2-A / P3-A / P6-A）
- 軽微: 4 件（P1-A / P2-B / P4-A / P5-A）
- 合計: 7 件

### 必要性判定別

- 自動採択（致命的デメリットなし、修正案が sibling 先例で一意）: 7 件 — P1-A / P2-A / P2-B / P3-A / P4-A / P5-A / P6-A
- 利用者判断（複数の合理的選択肢が残る細部）: 0 件（ただし P2-A の完了条件↔検証対応付け粒度、P6-A の各 Task handback class 割当細部は採択後に利用者確認が望ましい＝must-fix 本体は自動採択、細部のみ利用者確認）

### must-fix 候補一覧（番号・1 行・採択別）

- P2-A（重要・自動採択）: sibling 3 spec が備える「Task 完了条件↔Task 9 決定的検証 pass」の二重化が paper-interface に皆無。Task 3/4/8 完了条件に併記（検証中立性・同型 sibling 非対称の中核）。対応付け粒度は利用者確認。
- P3-A（重要・自動採択）: sibling 3 spec が備える §5.1 Task 間依存グラフ小節が paper-interface に欠落。§5 に依存グラフ小節追加（§2 から機械導出）。
- P6-A（重要・自動採択）: sibling 3 spec が備える §5.2 失敗時巻き戻し単位（handback class 紐付け）小節が paper-interface に欠落。§5 に巻き戻し単位小節追加。各 Task handback class 割当細部は利用者確認。
- P1-A（軽微・自動採択）: §5 に claim ID taxonomy / adopted change history 範囲の design open issue 依存を 1〜2 行追記。
- P2-B（軽微・自動採択）: Task 9 完了条件に「列挙 4 検証対象に最低 1 決定的検証ケース・着手前客観基準確定（TDD 先行）」を追記（sibling Task 9/11 同形）。
- P4-A（軽微・自動採択）: Task 4 作業項目に Req5/Req6 受入対応をトレース可読性のため補付記（補修量最小）。
- P5-A（軽微・自動採択）: §5 に evaluation comparison field naming の tasks alignment gate 横断議題性を双方向対称で 1 行追記。

### 観点ごと該当なし概況

- 観点 1（設計網羅）: 主要構造の網羅漏れ該当なし（軽微 1 件 P1-A は確定タイミング可視化のみ、致命・重要なし）。
- 観点 2（粒度・完了基準）: 粒度過大による必須分解該当なし。重要 1 件（P2-A）・軽微 1 件（P2-B）はいずれも sibling が備える完了基準の機械検証二重化欠落（sibling 非対称）。
- 観点 3（依存・順序）: 循環依存・致命的順序違反は該当なし（reference format → 各モデル前提順は妥当）。重要 1 件（P3-A）は §5.1 相当小節欠落（sibling 非対称）。
- 観点 4（トレース）: トレース欠落（要件を引かない Task・どの Task にも無い受入）該当なし。Requirement 1〜6 全受入被覆確認済。軽微 1 件（P4-A）は可読性のみ。
- 観点 5（横断タスク）: evaluation analysis output 依存・foundation 語彙参照・staleness 伝播接続・命名衝突は整合良好（不整合なし）。軽微 1 件（P5-A）は横断議題性の双方向対称明示のみ。
- 観点 6（巻き戻し単位）: 実行時巻き戻し単位は design Separation Rules/Task 8 が内包（致命なし）。重要 1 件（P6-A）は開発時 handback 単位独立小節の欠落（sibling 非対称）。
- 観点 7（波及）: 連鎖更新漏れ・他 spec への修正波及該当なし（0 件、全件明示）。

### 他 5 spec tasks 波及件数

- 修正波及 **0 件**。記録のみ波及: evaluation / foundation（P5-A 関連で既に正しく修正不要、双方向対称化の片側補修）。
- runtime / self-improvement / implementation-governance: 波及なし（命名整合・参照整合確認済み）。

### 総合所見

- **致命所見 0 件**。設計全件網羅・要件トレース（Requirement 1〜6 全受入被覆）・横断契約整合（evaluation analysis output 5 artifact 名一致 / foundation `evidence_class`・`review_mode` 語彙参照非再定義 / staleness 伝播 3 spec 一貫 / 命名衝突なし）は良好で、paper-interface tasks.md の骨格は妥当。
- ただし **重要 3 件（P2-A 完了条件の機械検証二重化皆無、P3-A §5.1 依存グラフ小節欠落、P6-A §5.2 巻き戻し単位小節欠落）は、いずれも sibling 3 spec（runtime/evaluation/self-improvement）が備える要素を paper-interface 単独で欠く同型 sibling 非対称**であり、background で指摘された「sibling tasks-local-review で補修された §5.1/§5.2/テスト二重化の非対称欠落」が paper-interface でも**同一の 3 点すべてで再現**していることを確認した。これは observation 点として重大度が高い（横断ゲートで再検出される片肺）。
- **他 5 spec への修正波及は 0 件**。全推奨対応は paper-interface tasks.md 内に閉じ要件書・設計書・spec.json・他 5 spec tasks の改版を要さない。P5-A も evaluation tasks.md 側は既に正しく修正不要（双方向対称化の片側補修）。
- 横断整合ゲートへの進行可否: must-fix 候補（特に重要 3 件 P2-A / P3-A / P6-A、すなわち sibling 非対称の 3 点）を 1 件ずつ承認で適用してから tasks alignment gate（依存マップ §5.3 の 6 番目）へ進むことを推奨する。sibling 非対称が 3 点とも未補修のまま横断ゲートに進むと paper-interface 単独の片肺欠落が横断検査で確実に再検出される。軽微 4 件（P1-A/P2-B/P4-A/P5-A）は自動採択で同時適用してよい。利用者判断を要する独立所見は 0 件（P2-A 対応付け粒度・P6-A handback 割当細部のみ採択後に利用者確認）。must-fix 適用後は本観点 7 の波及精査どおり他 spec 連鎖 0 件を再確認すれば横断ゲート進行の前提が整う。

### 証跡パス

`/Users/Daily/Development/Rwiki-v2-code-mod/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/reviews/tasks-local-review-2026-05-18.md`（本ファイル、不変）
