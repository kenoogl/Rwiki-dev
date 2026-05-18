# タスク個別レビュー（Task 1〜10・前半全面再導出分の正規補完・独立レビュー）

- レビュー日：2026-05-18
- 対象 feature：`dual-reviewer-implementation-governance`
- レビュー種別：タスク個別レビュー（REVIEW_PROTOCOL 節 5 の 7 観点）
- レビュー対象：tasks.md の Task 1〜10、§1〜§2、§4 Downstream Handoff、§5 Blocking Dependencies、§6 Completion Criteria のうち Requirement 1〜8 該当部
- 整合確認の参照対象（再レビューはしない）：Task 11〜18、§6 末尾 Requirement 9 行（Task 1〜10 との重複・矛盾・順序・§5/§6 不整合のみ所見化）
- 設計正本：同 spec design.md の Requirement 1〜8 設計部（Owned Artifacts／Boundary Clarification／Workflow Model Stage -1〜4／Workflow Status Model／Cross-Spec Alignment Model／Reopen Propagation Model／Finding Model／Finding→Signal Mapping／Handback Model／Metric Model／Validation Model）。「Workflow Execution Ledger and Enforcement Model」節は Req9 ぶんで参照のみ
- 要件参照：同 spec requirements.md Requirement 1〜8（Requirement 9 は対象外＝Task 11〜18 が担当済）
- レビュー人：独立タスクレビュー人（起草者と独立、批判的視点）
- 生証跡（不変）。tasks.md / design.md / requirements.md / spec.json は変更しない（所見のみ）

---

## 0. 依存マップ確認結果（横断・順序判断の前提＝節 5／節 4 規律）

横断・順序判断の前に正本 `docs/alignment/phase-and-feature-dependency-map.md` を確認した。

- §4.7：implementation-governance は runtime/evaluation/self-improvement/paper-interface に対し `review dependency`。feature data contract を生成せず completion gate を追加する位置。governance は feature data producer ではなく governance（review procedure／evidence contract）owner であり、依存マップ上 review dependency のみ。本性質差を全観点の判定前提に置く。
- §5.3：tasks wave 生成順は foundation → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance。governance tasks は「prototype 実装後の review gate と validator を定義する位置」。
- §7 Tasks Alignment Checklist：foundation provenance／validator 語彙が固まってから下流という順序規律。Task 9／§6 が参照する foundation 所有正準 validator 状態語彙は順序規律と整合（foundation 先行）。
- §8.1：Workflow Execution Ledger 前提（Req9）。本書 §5 は wave 段構成の権威ソースの一つ、各 process 段集合の権威ソースは `workflow-process-authority-map.md` が一意指定（Req9 ぶん、本レビュー範囲外）。

結論：Task 1〜10 を governance spec 内に閉じ、§5 Blocking Dependencies で foundation 語彙・他 5 feature implementation 後の concrete artifact 取得を前提化する構成は依存マップと整合。正本に明示なき構造的決定（sibling 同型小節の要否等）は本レビューで新規導入せず、sibling 4 spec の tasks-local-review で確定済みの非対称補修パターンとの整合のみを検査する立場を取る。

---

## sibling 非対称の前提整理（本レビューの重点）

sibling 4 spec（runtime/evaluation/self-improvement/paper-interface）の tasks.md は §5 に次の 2 小節を持つ（いずれも tasks-local-review で補修確定済み）。

- `### 5.1 Task 間依存グラフ（§2 から導出。並列可を明示）`
- `### 5.2 失敗時の巻き戻し単位`

確認した sibling 先例：

- runtime tasks-local-review T3-B（**重要・自動採択**）：Task 11 件（10 件超）に対し §5 が外部 blocking のみで Task 間依存グラフ別表が無い＝節 5 タスク特有方針「10 件超は依存グラフ別表が要件」の明示違反。T6-A（軽微・自動採択）：失敗時巻き戻し単位節欠落。
- evaluation tasks-local-review F-4（**重要・自動採択候補**）：9 件（閾値未満）でも §5.1 を runtime 同形で付与、§5.2 欠落も補修。
- self-improvement tasks-local-review T3-A（**重要・自動採択**）：9 件でも sibling 非対称解消のため §5.1 付与。
- foundation tasks.md：§5 Blocking Dependencies のみで §5.1／§5.2 を持たない。ただし foundation は producer-root（全 downstream が foundation に blocked される起点）で §5 は「downstream を blocked する側」の列挙であり、consumer 4 spec とは構造が異なる正当な例外（foundation tasks-local-review は §5.1／§5.2 を要求していない）。

governance の性質差：governance は feature data producer でなく governance owner で依存マップ上 review dependency のみ。foundation 型の producer-root でもない。本レビューはこの性質差を踏まえ、§5.1／§5.2 の要否を「節 5 タスク特有方針の閾値（10 件超）」と「sibling consumer 先例の重大度判定」の両面で判定する。

---

## 観点 1：設計全件の網羅

要点：design Requirement 1〜8 設計部を Task 1〜10 が漏れなく実装単位へ分解しているか。

詳細抽出（設計章 → 担当 Task）：

- Owned Artifacts（Req1〜8 分の artifact 一覧）→ Task 1（配置先 skeleton 固定。Req9 追加 Owned Artifacts は Task 11 で範囲外）。網羅。
- Boundary Clarification（review 対象 vs owner）→ Task 1 完了条件「feature ownership を侵さない」＋ §4 Downstream Handoff。網羅。
- Workflow Model Stage -1（reference-free bootstrap）→ Task 3。網羅。
- Workflow Model Stage 0（intent review）→ Task 3。網羅。
- Minimal Heuristic Default Rule → Task 3（v2-acquisition owner・参照のみ・必須検査しない明示）。網羅。
- Workflow Model Stage 1〜4（implementation／smoke／conformance review／checkpoint close）→ Task 2。網羅。
- Workflow Status Model（5 status 区別）→ Task 7。網羅。
- Cross-Spec Alignment Model → Task 8。網羅。
- Reopen Propagation Model → Task 3（intent reopen）＋ Task 7（gate status 反映）。網羅。
- Finding Model（severity／必須項目）→ Task 5。網羅。
- Finding → Signal Register Mapping → Task 5。網羅。
- Handback Model（A/B/C/D）→ Task 5。網羅。
- Metric Model（conformance／phase-review metric register・段階語彙区別）→ Task 6。網羅。
- Review Template Required Sections（intent／conformance 必須セクション・type 判別）→ Task 4。網羅。
- Validation Model（Req1〜8 分の validator 確認項目・concrete artifact）→ Task 9。網羅。
- テスト戦略（Validation Model 由来＋TDD）→ Task 10。網羅。

深掘り・必要性判定：

- design Requirement 1〜8 設計部の機能要素はすべていずれかの Task に分解されている。**致命的な未分解（実装不能になる漏れ）はなし。**
- Reopen Propagation Model は Task 3（intent→requirements/design/tasks 連鎖）と Task 7（gate status 反映）に分割されているが、Task 7 作業行が「Task 3 と整合して workflow-gate-status に反映する」と相互参照を明示しており分割は追跡可能。所見化不要。

該当の致命・重要・軽微：なし。観点 1 該当所見：なし（設計全件分解済み、致命未分解 0）。

---

## 観点 2：タスクの粒度と完了基準

要点：各 Task が半日〜数日の実装可能単位か、完了条件が検証可能形か。sibling 同型のテスト Task（Task 10）が存在しテスト二重化の非対称が無いか。

詳細抽出：

- Task 1（配置先 skeleton 固定）：静的配置の固定。粒度小・適切。完了条件「repo 内配置・ownership 不侵」「owner 明確」は artifact 存在と Task 9 validator で検証可能。
- Task 2（conformance review procedure）：procedure doc 1 本の定義。粒度適切。完了条件「必須性・focus・タイミング・close 条件が procedure doc に定義」「smoke pass のみで閉じない」は doc 構造で検証可能。
- Task 3（intent review stage＋reference-free bootstrap＋minimal heuristic＋reopen propagation）：作業項目が 4 ブロック（Stage 0／Stage -1＋bootstrap script／minimal heuristic policy／reopen propagation）あり、本前半中で最も重い。後述 F-2 参照。
- Task 4（review template＋type 判別）：テンプレ 2 種＋front-matter type。粒度適切。完了条件検証可能。
- Task 5（finding model＋signal/handback 接続）：severity／必須項目／写像規則／handback。密結合 1 本。粒度適切。
- Task 6（conformance／phase-review metric register）：register 2 種定義。粒度適切。完了条件「canonical 定義・manual snapshot 許容」「段階語彙区別」検証可能。
- Task 7（workflow status model＋reopen propagation 反映）：status 5 値＋reopen 反映。粒度適切。
- Task 8（cross-spec alignment model）：alignment memo＋spec.json 反映要求。粒度小・適切。
- Task 9（validator＋concrete artifact）：スクリプト 1 本＋concrete artifact 1。粒度適切。完了条件「機械確認」「pass する concrete 最低 1」検証可能。
- Task 10（テスト）：Validation Model 由来のテスト Task として独立に存在。TDD 明記。

深掘り・必要性判定：

- テスト二重化の非対称：sibling 4 spec はいずれも末尾に独立テスト Task（runtime Task 11／evaluation Task 9／self-improvement Task 9／paper-interface 末尾）を持ち TDD 先行を明記。governance も Task 10（Req1〜8 分）＋ Task 18（Req9 分）の二系統でテスト Task を独立化しており、**sibling 同型のテスト Task 欠落・非対称は無い。** Task 10 完了条件「適合/不適合判定が決定的に検証できる」も sibling と同水準。
- F-2（軽微・記録のみ）：所在＝tasks.md Task 3。問題＝Task 3 は 4 ブロック（Stage 0 intent review／Stage -1＋bootstrap script／minimal heuristic policy／intent reopen propagation）を 1 Task に集約し前半中で最重。根拠＝節 5 タスク特有方針「1 タスクは半日〜数日、超えるならサブタスク分解」。深掘り：4 ブロックは「workflow 最上流の入口定義」という単一の設計クラスタ（design Stage -1／Stage 0／Minimal Heuristic Default Rule／Reopen Propagation Model が連続節）であり、Stage 0 の reviewer 作業と Stage -1 の bootstrap は intent gate 入口で密結合、minimal heuristic も bootstrap が作る control artifact の一部、reopen propagation も intent 変更の起点定義で intent review と不可分。分割すると「intent 起点の入口契約」の一貫性が複数 Task に分散し整合検証が困難になる。Task 12（Req9・enforcement 集約）に対する Req9 レビュー F-2 と同型の判断（密結合のため一体実装が合理的、サブタスク分解は dominated）。完了条件も検証可能形。推奨対応＝サブタスク強制分解は不要、現状維持が妥当。重大度＝軽微（記録のみ）。必要性判定＝現状維持（分解は dominated）。

該当の致命・重要：なし。観点 2 該当所見：F-2（軽微・記録のみ、現状維持妥当）1 件。

---

## 観点 3：依存関係と順序

要点：Task 1〜10 の前提・依存が明示され前提先行か、循環なし。§5 に Task 間依存グラフ／失敗時巻き戻し単位の小節が sibling 同型で存在するか（本レビュー重点）。

詳細抽出：

- §2「実装順序」は 1〜10 の線形順序を散文で記述：1（skeleton）→2（conformance procedure）→3（intent review／bootstrap）→4（template）→5（finding／signal／handback）→6（metric register）→7（status／reopen）→8（cross-spec alignment）→9（validator／concrete）→10（テスト）。理由として「procedure と template がないと concrete review artifact が書けない／validator は template と concrete の存在・必須セクションを確認するため後段／cross-spec alignment は completion rule 横断のため metric/status 確定後」を明示。前提先行は散文で読める。
- Task 4（template）は Task 9（validator が template／concrete の必須セクション確認）の前提 → 4 が 9 に先行。散文の理由行と整合。
- Task 2（procedure）・Task 5（finding model）・Task 6（metric register）は Task 9（validator が procedure doc／metric register 存在確認）の前提 → 9 が後段。整合。
- Task 3（reopen propagation）と Task 7（gate status へ reopen 反映）：Task 7 作業行が「Task 3 と整合して」と明示依存を記載。一方向（3→7 の概念先行、ただし Task 7 は status model 本体で独立着手可）。循環なし。
- Task 8（cross-spec alignment）は Task 6（metric）・Task 7（status）確定後＝§2 理由行で明示。前提先行。
- Task 10（テスト）は TDD 方針上 Task 1〜9 実装前にテスト先行（Task 10 作業行「先にテストを用意し失敗を確認してから実装」）。§2 順序 10 末尾配置だが TDD 注記で先行担保（sibling 同型）。
- 循環依存：検出なし（1→2→3→4→5→6→7→8→9、10 は TDD 先行）。
- Task 1〜10 と Task 11〜18 の順序整合：§2 に「Requirement 9 ぶんの内部実装順序：Task 11→12→13→14→15→16→18、Task 17 は承認後」が追記済み。Task 1〜10 と Task 11〜18 の順序矛盾なし（11〜18 は 1〜10 の Owned Artifacts／validator を前提とし後段、§2 で分離記述）。

深掘り・必要性判定（**本レビュー重点＝sibling 非対称**）：

- **T3-GOV（重要）：所在＝tasks.md §5 Blocking Dependencies／全 Task。** 問題＝§5 は foundation 語彙・他 5 feature implementation 後の concrete artifact 取得という外部 blocking のみ列挙し、**Task 間依存グラフ（どの Task がどの Task の出力を入力にするか、並列実行可能ペア）の独立小節（sibling §5.1 相当）が無い。** 根拠＝(1) REVIEW_PROTOCOL 節 5「タスク特有の追加方針：タスクが多い場合（10 件超）は依存グラフを別表で示し、並列実行可能なタスクを明示する」。本 tasks.md は Task 1〜18 で **18 件＝10 件超**であり依存グラフ別表は**必須要件**（任意ではない）。(2) sibling 4 consumer spec はいずれも §5.1「Task 間依存グラフ（§2 から導出。並列可を明示）」を持ち、runtime tasks-local-review T3-B はこの欠落を**重要・自動採択**、self-improvement T3-A・evaluation F-4 は 9 件（閾値未満）でも sibling 非対称解消のため**重要・自動採択**で補修済み。governance は 18 件で閾値を大きく超え、かつ consumer sibling 全件が備える要素を欠く非対称。Req9 タスクレビュー（tasks-local-review-2026-05-18.md）F-3 は「Task 11〜18 の内部順序が §2 に未追記」を軽微・任意としたが、これは Req9 範囲（Task 11〜18）に限った判断であり、Task 1〜10 を含む tasks.md 全体（18 件）に対する節 5「10 件超は依存グラフ別表が必須要件」の明示違反・sibling consumer 非対称は本レビュー（Task 1〜10 正規補完）で初めて正面評価する論点。推奨対応＝§5 に sibling §5.1 同形の「### 5.1 Task 間依存グラフ（§2 から導出。並列可を明示）」小節を追加。内容は §2 から機械導出可能（例：Task1（skeleton）が起点 → Task2／Task3 は Task1 後に並列着手可 → Task4（template）→ Task5（finding/signal/handback）／Task6（metric）は並列可 → Task7（status/reopen、Task3 の reopen propagation と整合）→ Task8（cross-spec alignment、Task6/7 後）→ Task9（validator、Task2/4/5/6 の artifact 存在が前提で後段）→ Task10（テスト、全 Task と並走 TDD 先行）。Req9 分は §2 既述の Task11→12→13→14→{15,16}→18、Task17 承認後を併記。外部前提＝Task9 は他 5 feature implementation 後 concrete artifact 取得・foundation 正準語彙確定が blocking）。重大度＝**重要**（節 5 必須要件の明示違反＋sibling consumer 4 spec 全件が備える要素の非対称欠落。ただし §2 散文順序で実装自体は可能なため致命ではない）。必要性判定＝**自動採択**（節 5 必須要件の最小補修、内容は §2 から機械導出可能、sibling 4 spec で同型確定済み・先例はいずれも自動採択、致命的デメリットなし）。

該当の致命：なし。観点 3 該当所見：T3-GOV（**重要・自動採択**）1 件。

---

## 観点 4：要件／設計とのトレース

要点：各 Task が Requirement 1〜8 受入番号・design 章を引いているか。Requirement 1〜8 全受入被覆。Task 1〜10 と Task 11〜18 の根拠重複・矛盾なし。

詳細抽出（Task → 引用）：

- Task 1：Req2 受入1／Req5 受入2／Req7 受入2／design Owned Artifacts・Boundary Clarification。トレース可。
- Task 2：Req1 受入1〜4／design Workflow Model Stage 1〜4・Architecture。トレース可。
- Task 3：Req7 受入1・4／Req8 受入1〜6／Req6 受入5／design Stage -1・Stage 0・Minimal Heuristic Default Rule・Reopen Propagation Model。トレース可。
- Task 4：Req2 受入2・5／Req7 受入2・6／design Review Template Required Sections。トレース可。
- Task 5：Req2 受入3・4／Req4 受入1〜4／design Finding Model・Finding→Signal Mapping・Handback Model。トレース可。
- Task 6：Req3 受入1〜4／Req7 受入3・5・7／design Metric Model。トレース可。
- Task 7：Req6 受入2・3・5／design Workflow Status Model・Reopen Propagation Model。トレース可。
- Task 8：Req6 受入1・4／design Cross-Spec Alignment Model。トレース可。
- Task 9：Req5 受入1〜4／Req7 受入6／Req2 受入2／design Validation Model。トレース可。
- Task 10：design Validation Model／プロジェクト開発方針（TDD）。テスト戦略は Validation Model 由来。トレース可。

受入カバレッジ照合（Requirement 1〜8 → Task）：

- Req1（受入1〜4）＝Task2。全 4 受入。
- Req2（受入1〜5）＝受入1/2＝Task1/4/9、受入2＝Task4、受入3/4＝Task5、受入5＝Task4。全 5 受入。
- Req3（受入1〜4）＝Task6。全 4 受入。
- Req4（受入1〜4）＝Task5。全 4 受入。
- Req5（受入1〜4）＝Task9。全 4 受入。
- Req6（受入1〜5）＝受入1/4＝Task8、受入2/3/5＝Task7、受入5＝Task3/7。全 5 受入。
- Req7（受入1〜7）＝受入1/4＝Task3、受入2/6＝Task4/9、受入3/5/7＝Task6、受入6＝Task9。全 7 受入。
- Req8（受入1〜6）＝Task3。全 6 受入。

**Requirement 1〜8 の全受入が Task 1〜10 に対応。漏れなし。**

深掘り・必要性判定：

- Task 1〜10 と Task 11〜18 の根拠重複・矛盾：Task 11〜18 は Requirement 9・design「Workflow Execution Ledger and Enforcement Model」のみを引き、Task 1〜10（Req1〜8・対応設計章）と引用域が排他。重複・矛盾なし。Task 11 が Task 1 と同じ `scripts/validate_implementation_governance_artifacts.rb` を扱うが、Task 1 は配置先固定（Req1〜8 分）、Task 13 は同スクリプトの「サブモード追加（Req9 拡張、上位集合）」で design 小節 2「別建てにしない」が上位集合関係を保証 → 同一ファイルへの段階的拡張で矛盾でなく整合（Req9 レビューでも確認済み）。
- §6 Completion Criteria：Req1〜8 由来行（conformance review 必須／finding severity／metric register／status 区別／validator＋concrete／phase-review 語彙区別）と Req9 由来行（実行台帳・独立再導出・enforcement・fail-closed）が分離記述され矛盾なし。Task 1〜10 完了条件と §6 Req1〜8 行は整合（例：Task2 完了条件「smoke pass のみで閉じない」＝§6 1 行目）。
- 軽微所見も該当なし：Task 根拠の要件番号・設計章引用は全 Task で具体的かつ正確。Req9 レビュー F-4（Task 17 C-3 の節 6 が設計小節 6 と不一致）相当の「Task が設計 HOW を越える」事例は Task 1〜10 には検出されない（Task 1〜10 の作業項目は design 章の記述範囲内）。

該当の致命・重要・軽微：なし。観点 4 該当所見：なし（全受入被覆・根拠重複矛盾なし・引用正確）。

---

## 観点 5：横断タスクの抽出

要点：governance が他 5 spec に課す completion rule／conformance review／reopen propagation が独立タスク化され、他 spec tasks との命名衝突・暗黙義務の非対称がないか。他 5 spec 波及を明示記録。

詳細抽出：

- governance が他 5 feature に課す義務（completion rule／conformance review／reopen propagation）は **§4 Downstream Handoff で「foundation/runtime/evaluation/self-improvement/paper-interface は本 spec の completion rule・conformance review・reopen propagation に従う」と一括宣言**。これは governance が completion gate owner（依存マップ §4.7 review dependency）であることの帰結で、他 5 spec の business data tasks に新規 Task を生まない（governance は data producer でなく gate を足す側）。横断作業の所有は中心フィーチャー＝governance 側（tasks.md §4）に集約されており、節 5 タスク特有方針「横断タスクは中心フィーチャー側に置く」と整合。
- foundation 所有正準 validator 状態語彙：Task 1〜10 範囲では §6 Completion Criteria・Task 9 が間接参照するが、Req1〜8 分の Task 9 validator 確認項目（design Validation Model）に状態語彙再定義は含まれず参照のみ。foundation tasks への新規 Task を生まない（foundation tasks.md が canonical owner、§7 順序規律と整合）。
- heuristic 既定挙動・minimal-template 語彙：Task 3 が「canonical owner は v2-acquisition spec、governance は参照のみ・語彙確定まで必須検査しない」と明示切り出し済み（Req8 受入6・design Minimal Heuristic Default Rule）。v2-acquisition tasks への新規波及なし。

他 5 spec tasks 波及精査（明示記録）：

- foundation/runtime/evaluation/self-improvement/paper-interface の各 tasks.md を grep（`implementation-governance`／`conformance review`／`completion rule`／`reopen propagation`／`governance`）。

確認結果：

- runtime/evaluation/self-improvement/paper-interface tasks.md の §4 Downstream Handoff 相当・§5／§6 は foundation 依存と相互の data 依存を記述するが、governance への上り依存（governance completion gate に従う義務）は各 spec tasks.md に新規 Task としては存在せず、§4.7 review dependency の性質上 governance 側 §4 で一括表現される設計。**他 5 spec tasks.md に governance 由来の新規 Task 追加・改版・命名衝突は要求されない（波及 0 件）。**
- governance Task 1〜10 が定義する artifact 配置先（`docs/coordination/`・`docs/reviews/`・`scripts/`・`.kiro/methodology/`）は他 5 spec の artifact placement と命名衝突しない（governance 専用 path＝`implementation-conformance-review.md`／`*-metric-register.md`／`validate_implementation_governance_artifacts.rb` 等、feature 固有名で前置）。命名衝突 0 件。
- **他 5 spec tasks への波及：0 件。**

深掘り・必要性判定：横断義務（completion rule／conformance review／reopen propagation）は §4 Downstream Handoff に中心フィーチャー側集約で表現済み、他 5 spec への新規 Task・命名衝突・暗黙義務の非対称なし。波及 0 件。該当所見：なし。

該当の致命・重要・軽微：なし。観点 5 該当所見：なし（横断義務は中心フィーチャー側に適切集約・他 5 spec 波及 0 件）。

---

## 観点 6：失敗時の巻き戻し単位

要点：Task 1〜10 失敗時の影響範囲・巻き戻し単位（handback class 紐付け小節）の有無。sibling §5.2 同型の独立小節が存在するか。Task 1〜10 と Req9 §5.2（Task 11〜18 ぶん）との整合。

詳細抽出：

- sibling 4 consumer spec はいずれも §5.2「失敗時の巻き戻し単位」を持ち、handback class（A/B/C/D）への紐付けを明示（evaluation §5.2 が最も詳細：Task 別に handback A/B/C と判定迷い時の保守規律を明示）。
- governance tasks.md §5 は Blocking Dependencies のみで、**Task 1〜10 の失敗時巻き戻し単位・handback class 紐付けの独立小節（sibling §5.2 相当）が無い。**
- Task 1〜10 の各 Task 失敗時の巻き戻し性：Task 1（静的配置）＝当該 artifact 削除で局所巻き戻し（handback A 相当）。Task 2〜8（procedure/template/finding/metric/status/alignment doc 定義）＝doc 単位の差し戻し（handback A〜B：Req1〜8 が定義不足なら C 上流戻し）。Task 9（validator）＝スクリプト差し戻し。Task 10（テスト）＝TDD で実装側修正。いずれも巻き戻し境界は推測可能だが tasks.md に明示記述が無い。
- Req9 §5.2 との整合：Req9 タスクレビュー（tasks-local-review-2026-05-18.md）観点 6 は「Task 11〜18 の巻き戻し単位は設計小節（1.1 supersedes／小節 10 grandfathering・format-migration／小節 4 fail-closed）＋各 Task から読める」とし §5.2 独立小節の新設を求めていない（Req9 分は設計小節が巻き戻し境界を確定）。一方 Task 1〜10 は Req1〜8 設計部に supersedes/grandfathering 相当の巻き戻し境界明示が無く、sibling §5.2 のような handback class 紐付け節が無いため、Task 1〜10 ぶんは Req9 ぶんと異なり「設計から巻き戻し単位が読める」とは言い難い。tasks.md 内に §5.2 が無いため、Task 1〜10 と Req9 §5.2 相当記述の整合は「§5.2 節そのものが不在」という形で非対称（Req9 は設計小節で代替、Task 1〜10 は代替も無し）。

深掘り・必要性判定：

- **T6-GOV（軽微）：所在＝tasks.md §5（巻き戻し単位の独立小節欠落）／Task 1〜10。** 問題＝WORKFLOW_OVERVIEW.md 節 4 handback class（A/B/C/D）に照らした Task 1〜10 失敗時の巻き戻し単位（task-local 吸収か design/requirements handback か）の独立小節（sibling §5.2 相当）が tasks.md に無い。特に Task 1（artifact ownership 境界）／Task 9（validator が他 5 feature concrete artifact に依存）／Task 6（foundation 正準語彙・runtime 語彙区別）で実装中に Req1〜8 契約不足が判明した場合の上流戻し単位が未明示。根拠＝REVIEW_PROTOCOL 節 5 観点 6（タスク失敗時の影響範囲・巻き戻し単位の明示）＋ sibling 4 consumer spec 全件が §5.2 を備える非対称（runtime tasks-local-review T6-A は同型欠落を軽微・自動採択で補修済み）。推奨対応＝§5 に sibling §5.2 同形の「### 5.2 失敗時の巻き戻し単位」小節を追加（例：Task1〜2/4〜8/10 は task-local 吸収（handback A）。Task1 で feature ownership 境界が Req2/5/7 で不足なら handback C（requirements へ）。Task3 で Stage -1/0・heuristic policy が Req7/8 で導けないなら handback C（v2-acquisition 語彙確定待ちは §5 Blocking の既述に従い必須検査しない）。Task6 で foundation 正準語彙との区別が contract 化されていないなら handback C（foundation/requirements へ）。Task9 は他 5 feature implementation 後 concrete artifact 取得待ちが blocking で前進停止に倒れる（巻き戻し不要）。判定に迷う場合は保守規律により上流へ寄せる）。重大度＝軽微（design Boundary/Validation で gate 性質上「検査不能＝前進停止」に倒れる面はあるが、Task 1〜10 ぶんは Req9 と違い設計小節に巻き戻し境界の明示が無く、開発時 handback 単位の明示が sibling 比で薄い）。必要性判定＝**自動採択**（観点 6 の明示要件の最小補修、内容は WORKFLOW_OVERVIEW 節 4＋§5 Blocking＋各 Task 根拠から導出可能、sibling 4 spec で同型確定済み・先例は自動採択、致命的デメリットなし）。

該当の致命・重要：なし。観点 6 該当所見：T6-GOV（**軽微・自動採択**）1 件。

---

## 観点 7：波及精査（最終ガード）

要点：観点 1〜6 の所見が他 Task・他 spec・上位文書・Task 11〜18 に与える連鎖を最終確認。波及あり／なしを全件明示記録。

各所見の波及：

- F-2（Task 3 集約・軽微・記録のみ）：現状維持妥当の判定。変更を加えないため波及 **なし**。
- T3-GOV（§5.1 Task 間依存グラフ小節追加・重要・自動採択）：tasks.md §5 に小節 1 つ追加。内容は §2（Task 1〜10 順序）＋ §2 既述 Req9 順序行から機械導出。**波及範囲＝governance tasks.md §5 内に閉じる。** 他 5 spec tasks.md は各々 §5.1 を既に保有（sibling 補修済み）のため新規波及なし。Task 11〜18 への波及：§5.1 に Req9 分順序（§2 既述）を併記するのみで Task 11〜18 本体は不変。上位文書（依存マップ／CONVENTIONS／WORKFLOW_OVERVIEW）への波及なし（tasks.md 内構造補修）。**他 5 spec 波及 0 件。**
- T6-GOV（§5.2 巻き戻し単位小節追加・軽微・自動採択）：tasks.md §5 に小節 1 つ追加。内容は WORKFLOW_OVERVIEW 節 4＋§5 Blocking＋各 Task 根拠から導出。**波及範囲＝governance tasks.md §5 内に閉じる。** 他 5 spec tasks.md は各々 §5.2 を既に保有。Task 11〜18 への波及：Req9 タスクレビューは Req9 分巻き戻しを「設計小節で代替」と判定済みのため §5.2 は Task 1〜10 ぶんを記述し Req9 分は設計小節参照を 1 行併記すれば足る（Task 11〜18 本体不変）。上位文書波及なし。**他 5 spec 波及 0 件。**

Task 1〜10 と Task 11〜18 の整合（再確認）：

- §2「実装順序」に Req9 内部順序（Task11→12→13→14→{15,16}→18、Task17 承認後）が分離追記済み。Task 1〜10 線形順序と矛盾なし。
- §5 Blocking Dependencies は Task 3（heuristic 語彙 v2-acquisition 確定待ち）・Task 9（他 5 feature implementation 後 concrete artifact）を記述。Req9 §8.1（依存マップ）前提と矛盾なし。
- §6 Completion Criteria は Req1〜8 行（Task 1〜10 由来）と Req9 行（Task 11〜18 由来）が分離記述・矛盾なし。
- T3-GOV／T6-GOV の §5.1／§5.2 追加は Task 11〜18 の Req9 順序・設計小節巻き戻し記述と併記整合可能（重複・矛盾を生まない）。
- **Task 1〜10 と Task 11〜18 の重複・矛盾・順序不整合・§5/§6 不整合：検出 0 件（整合）。**

他 5 spec tasks への連鎖（最終確認）：F-2／T3-GOV／T6-GOV いずれも他 5 spec tasks.md に変更を要求しない。**他 5 spec 波及：全所見で 0 件。**

上位文書への連鎖：全所見が governance tasks.md §5 内（または無変更）に閉じる。上位運用文書（CONVENTIONS.md／WORKFLOW_OVERVIEW.md／phase-and-feature-dependency-map.md／workflow-repair-procedure.md）への実体変更は本所見群では発生しない。上位文書波及 **なし**。

観点 7 該当：T3-GOV／T6-GOV は限定波及あり（いずれも governance tasks.md §5 内に閉じる）。F-2 波及なし。他 5 spec 波及 0 件。Task 1〜10／Task 11〜18 整合確認 0 件不整合。

---

## 集計

- 致命：**0 件**
- 重要：**1 件**（T3-GOV：§5.1 Task 間依存グラフ小節欠落＝節 5「10 件超は依存グラフ別表が必須」明示違反＋sibling consumer 4 spec 非対称）
- 軽微：**2 件**（F-2：Task 3 の 4 ブロック集約・記録のみ／T6-GOV：§5.2 失敗時巻き戻し単位小節欠落・sibling 非対称）
- 観点別該当：観点 1＝なし、観点 2＝F-2、観点 3＝T3-GOV、観点 4＝なし、観点 5＝なし、観点 6＝T6-GOV、観点 7＝T3-GOV／T6-GOV 限定波及（F-2 波及なし）
- 該当なし観点：観点 1（設計全件分解済・致命未分解 0）、観点 4（Requirement 1〜8 全受入被覆・根拠重複矛盾なし・引用正確）、観点 5（横断義務は中心フィーチャー側集約・他 5 spec 波及 0 件）
- 他 5 spec tasks 波及：**0 件**（foundation/runtime/evaluation/self-improvement/paper-interface いずれも該当 grep 0 件・命名衝突 0 件・business data tasks 不変）
- Task 1〜10 と Task 11〜18 整合：**不整合 0 件**（§2 順序分離・§5 Blocking・§6 Completion 分離記述で重複/矛盾/順序不整合なし）

## must-fix 候補一覧

- T3-GOV（番号 1）：§5 に sibling §5.1 同形「### 5.1 Task 間依存グラフ（§2 から導出。並列可を明示）」を追加 — **重要・自動採択**（節 5「10 件超（本 spec 18 件）は依存グラフ別表が必須要件」の明示違反補修＋sibling consumer 4 spec 全件が備える要素の非対称解消。内容は §2 から機械導出可能、sibling 先例はいずれも自動採択、致命的デメリットなし）
- T6-GOV（番号 2）：§5 に sibling §5.2 同形「### 5.2 失敗時の巻き戻し単位」を追加（Task 1〜10 ぶんの handback class 紐付け。Req9 分は設計小節参照 1 行併記） — **軽微・自動採択**（観点 6 明示要件の最小補修＋sibling 非対称解消。WORKFLOW_OVERVIEW 節 4＋§5 Blocking＋各 Task 根拠から導出可能、sibling 先例は自動採択、致命的デメリットなし）
- F-2（番号 3）：Task 3 の 4 ブロック集約 — **軽微・記録のみ・現状維持妥当**（密結合のためサブタスク分解は dominated、Req9 レビュー F-2 と同型判断）

must-fix（重要以上）：**1 件（T3-GOV）**。ただし T3-GOV は自動採択（節 5 必須要件の機械導出可能な構造補修、sibling 4 spec で同型確定済み・先例も自動採択、複数合理選択肢なし・致命影響なし）であり、利用者判断を要しない。T6-GOV も自動採択（軽微）。F-2 は現状維持。

## 総合所見

- Task 1〜10 ＋ §1〜§2／§4 Downstream Handoff／§6 Req1〜8 行は、design Requirement 1〜8 設計部（Owned Artifacts／Boundary／Stage -1〜4／Status／Cross-Spec Alignment／Reopen Propagation／Finding／Handback／Metric／Validation）を漏れなく実装単位へ分解しており、**致命的な設計未分解・実装不能は 0 件**。Requirement 1〜8 受入は全件 Task 1〜10 に対応。Task 1〜10 と Task 11〜18 は §2 順序・§5 Blocking・§6 Completion が分離記述され**整合（不整合 0 件）**。横断義務（completion rule／conformance review／reopen propagation）は中心フィーチャー（governance）側 §4 に集約され他 5 spec tasks 波及 0 件。テスト Task（Task 10）は sibling 同型で独立化されテスト二重化の非対称なし。
- 最重要の検出は sibling 非対称：sibling 4 consumer spec（runtime/evaluation/self-improvement/paper-interface）はいずれも §5.1（Task 間依存グラフ）・§5.2（失敗時巻き戻し単位）を tasks-local-review 補修で備えるのに対し、governance tasks.md §5 は Blocking Dependencies のみで両小節を欠く。本 tasks.md は 18 件で節 5「10 件超は依存グラフ別表が必須要件」を大きく超過しており、§5.1 欠落（T3-GOV）は sibling 先例（runtime T3-B・self-improvement T3-A・evaluation F-4）と同じく**重要・自動採択**、§5.2 欠落（T6-GOV）は runtime T6-A と同じく**軽微・自動採択**。Req9 タスクレビュー（Task 11〜18 範囲）はこの Task 1〜10 を含む全体構造の節 5 必須要件違反を正面評価していなかったため、本レビュー（Task 1〜10 正規補完）が初出論点として所見化した。
- 結論：**must-fix（重要以上）は T3-GOV 1 件のみだが自動採択（機械導出可能・sibling 先例確定・複数選択肢なし・致命影響なし）であり利用者判断を要しない。** T3-GOV／T6-GOV を自動採択で適用（§5 に sibling §5.1／§5.2 同形小節を追加、内容は §2＋WORKFLOW_OVERVIEW 節 4＋§5 Blocking から機械導出）してから**タスク横断整合ゲートへ進めるのが妥当**。F-2 は現状維持（記録のみ）。must-fix 適用後は致命・重要・利用者判断ともに 0 件で横断整合ゲート完走可能と判断する。

## 証跡パス

- 本レビュー証跡：`.kiro/specs/dual-reviewer-implementation-governance/reviews/tasks-local-review-task1-10-2026-05-18.md`（本ファイル、不変）
- 主対象：`.kiro/specs/dual-reviewer-implementation-governance/tasks.md`（Task 1〜10・§1〜§2・§4・§5・§6 Req1〜8 部）
- 設計正本：`.kiro/specs/dual-reviewer-implementation-governance/design.md`（Requirement 1〜8 設計部）
- 要件参照：`.kiro/specs/dual-reviewer-implementation-governance/requirements.md`（Requirement 1〜8）
- 依存正本：`docs/alignment/phase-and-feature-dependency-map.md`（§4.7／§5.3／§7／§8.1 確認）
- 上位正本：`operations/REVIEW_PROTOCOL.md`（節 5）
- 整合参照（再レビューせず）：`.kiro/specs/dual-reviewer-implementation-governance/reviews/tasks-local-review-2026-05-18.md`（Req9・Task 11〜18 既往レビュー）
- sibling 非対称先例（独立判断、鵜呑みにせず）：`dual-reviewer-runtime/reviews/tasks-local-review-2026-05-18.md`（T3-B/T6-A）、`dual-reviewer-evaluation/reviews/tasks-local-review-2026-05-18.md`（F-4）、`dual-reviewer-self-improvement/reviews/tasks-local-review-2026-05-18.md`（T3-A）、各 spec tasks.md §5.1／§5.2
