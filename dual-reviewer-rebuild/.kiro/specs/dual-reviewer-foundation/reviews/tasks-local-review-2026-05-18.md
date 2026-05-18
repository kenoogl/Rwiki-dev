# dual-reviewer-foundation タスク個別レビュー（独立パス）

_実施日: 2026-05-18_
_対象: `.kiro/specs/dual-reviewer-foundation/tasks.md` 全体_
_正本: design.md / requirements.md（Requirement 1〜7、Requirement 5 削除済み）_
_手続き正本: `operations/REVIEW_PROTOCOL.md` 節 5（タスクレビュー 7 観点）_
_位置づけ: tasks wave 再生成時に省略した機能個別タスクレビューの正規実施。起草者と独立した批判的視点。生証跡として不変。本レビューは所見のみ。tasks.md / design.md / requirements.md / spec.json は変更しない。_

---

## 0. 依存マップ確認結果（横断・順序判断の前提）

正本 `docs/alignment/phase-and-feature-dependency-map.md` を確認した。

- foundation は shared contract owner であり、runtime / evaluation / self-improvement / paper-interface に対して `hard dependency`（§4.2）。foundation artifact が固まるまで下流 4 spec の関連 task は blocked（§5.3、§7 Tasks Alignment Checklist）。
- tasks wave 推奨順序（§5.3）は `foundation tasks → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance tasks`。foundation は先頭であり、本レビューはその先頭 spec の個別タスクレビュー。
- §7 が要求する foundation 起点の順序依存（runtime export 前に provenance field 固定、evaluation intake 前に runtime export manifest 固定 等）は、foundation tasks.md の Downstream Handoff（§4）と Blocking Dependencies（§5）が正しく反映している。
- 構造的決定（feature 間依存・進行順）は正本に明示済みで、即興導出はしていない。

結論：横断・順序の判断はすべて上記正本に準拠する。foundation tasks.md の順序記述は依存マップと矛盾しない。

---

## 1. 観点 1：設計全件の網羅

要点：tasks が design.md の全構成要素（モジュール／データモデル／schema／prompt／config／validator contract／テスト戦略／移行）を漏れなく実装単位に分解しているか。

詳細抽出（design 構成要素 → 対応 Task）:

- Shared Artifact Layout / Placement Decisions → Task 1（directory skeleton）
- Domain Model §1 Layer 1 Review Contract / §2 Role Abstraction → Task 2（`layer1_framework.yaml`）
- §3 Run Metadata Contract / §9 Exploratory Handling → Task 3（`metadata_contract.yaml`）
- §4 Shared Schema Relationships / §5 Step-Level Replay Model → Task 4（schema 5 file）
- §6 Prompt Artifact Model → Task 6（Step A/B/C prompt artifacts）
- §10 Config and Template Model → Task 7（config / terminology template）
- §8 Validation and Invalidation Model → Task 8（validator-facing contract 2 file）
- Test Strategy / Completion Criteria → Task 9（fixtures と機械検証）
- §7（削除済み）→ Task 5 を欠番として明示維持。tasks.md §4 / §5 で「`runtime/patterns/*`・`review_mode_vocab.yaml` は提供しない」と非生成を明記
- Interface Decisions 1〜5 → Decision 1 は Task 6、Decision 2 は Task 3、Decision 3 は Task 4（finding）、Decision 4 は Task 8、Decision 5 は Task 4（§5 replay identity）に分解されている

深掘り：design の全 Domain Model 節（§1〜§10、§7 は意図的削除で欠番処理）、全 Interface Decision、Test Strategy 全 5 項目、Completion Criteria 全項目が Task に写像されている。未分解の design 構成要素は検出されない。`override_extension_point`（design §1）は Task 2 作業に「拡張点の所在のみ。選択順序・優先規則・適用条件は定義しない」と明記され design Boundary Clarification と一致。step-level replay identity（design §5 の 6 項目）も Task 4 review_case 作業に列挙済み。

必要性判定：**該当なし（致命・重要なし）**。設計全件は漏れなく分解されている。タスクへの追記不要。

---

## 2. 観点 2：タスクの粒度と完了基準

要点：各 Task が実装可能単位（半日〜数日目安）か、完了条件が検証可能か。

詳細抽出：Task 数は実質 8 件（Task 5 欠番）。foundation は実行コードを持たず artifact 固定が中心のため、各 Task は 1 artifact 群（または 1 directory skeleton）の作成に対応し、半日〜数日に収まる。各 Task に「完了条件」節があり、Task 9 の機械検証（design Test Strategy 準拠）で機械判定できる形に揃っている。完了条件はすべて Test Strategy の静的検証項目に還元されており、実装着手前に検証手段が確定している（タスク特有方針「検証手段の事前確定」に適合）。

深掘り（軽微所見 T-1）：Task 4 は schema 5 file をまとめて 1 Task としている。5 file それぞれが独立 JSON Schema で field 定義量があるが、design §4 が 5 schema を 1 関係図として相互参照付きで規定しているため、分割すると `review_case`↔`finding`↔派生 3 schema の参照整合を Task 横断で担保する負担が生じる。粒度目安（数日）の上限付近だが、相互参照の一貫性を 1 Task 内で閉じる利得が分割コストを上回る。分割は明らかに劣後するため提示しない（タスク特有方針「明らかに劣る選択肢は提示しない」）。

必要性判定：**該当なし（致命・重要なし）／T-1 は軽微・対応不要**。粒度は foundation の性質（規範中心）に照らし適切。完了基準は検証可能形で明示済み。

---

## 3. 観点 3：依存関係と順序

要点：Task 間の前提・依存が明示され、前提が先行し、循環がないか。

詳細抽出：tasks.md §2「実装順序」が 1〜9 の線形順序を明示。理由節が design「Impact on Downstream Specs」「Architecture」を引いて順序根拠を述べる。

深掘り（順序の妥当性検証）:

- Task 8（validator_result.schema.json）の `validator_status` は Task 3（metadata_contract.yaml）の語彙と整合させる必要がある。tasks.md は Task 3 → Task 8 の順で、Task 8 作業に「`metadata_contract.yaml` の語彙と整合させる（design §8）」と前提を明示。前提が先行している。
- Task 9（機械検証）は Task 1〜8 の全 artifact 存在を前提とし最後尾。正しい。
- Task 4（schema）と Task 6（prompt）は相互依存なし。Task 2/3/4/6/7/8 間に循環はない。directory skeleton（Task 1）が全 artifact 配置の前提として先頭。

循環依存：なし。前提先行：成立。依存グラフは線形で 10 件未満のため別表不要（タスク特有方針「10 件超で依存グラフ別表」に未該当）。

必要性判定：**該当なし（致命・重要なし）**。順序は依存マップ §7 とも整合。タスクへの追記不要。

---

## 4. 観点 4：要件／設計とのトレース

要点：各 Task が対応要件番号・設計章番号を引いているか。

詳細抽出（全 Task の「根拠」記載を照合）:

- Task 1：design「Shared Artifact Layout」「Placement Decisions」
- Task 2：Requirement 1（受入 1〜9）、Requirement 2 受入 1、design §1・§2
- Task 3：Requirement 1 受入 5、Requirement 6（受入 1〜10）、Requirement 7 受入 3、Requirement 2 受入 4、design §3・§9
- Task 4：Requirement 3（受入 1〜10）、Requirement 1 受入 4、design §4・§5
- Task 5：欠番。Requirement 5 削除・design §7 を引いて欠番理由を明示
- Task 6：Requirement 4（受入 1〜5）、design §6・Placement Decisions 項目 3・Interface Decision 1
- Task 7：Requirement 2（受入 3〜5）、Requirement 7（受入 1〜4）、design §10
- Task 8：Requirement 6（受入 3・9）、design §8・Interface Decision 4
- Task 9：design「Test Strategy」「Completion Criteria」

深掘り（要件カバレッジの逆引き）：Requirement 1〜4・6・7 はすべていずれかの Task が引いている。Requirement 5 は削除済みで Task 5 欠番が対応。Requirement 2 受入 2（vendor 名禁止）は Task 2 作業の `roles` 記述に「vendor / model 名を入れない＝Requirement 2 受入 1・2」として写像。Requirement 4 受入 5（diff 履歴で検出可能）は Task 6 完了条件「prompt version traceability」が Requirement 4 受入 2・3・5 を一括参照。トレース欠落の要件・設計章は検出されない。

必要性判定：**該当なし（致命・重要なし）**。全 Task が要件番号・設計章を引いており、要件側の被参照も漏れがない。タスクへの追記不要。

---

## 5. 観点 5：横断タスクの抽出（最重点：foundation は shared contract owner）

要点：複数 feature にまたがる作業（shared contract 固定・命名統一・移行）が独立タスクとして切り出され、中心 feature 側（＝foundation）に置かれているか。foundation 所有 artifact を下流が参照する順序が壊れないか。他 5 spec tasks への波及有無。

詳細抽出：foundation の Task 全体が本質的に横断タスク（下流 4 spec が import する shared contract の固定）であり、これは依存マップ §4.2 のとおり中心 feature たる foundation に正しく置かれている。tasks.md §4「Downstream Handoff」が下流が依存してよい artifact を列挙し、§5「Blocking Dependencies」が foundation 完了まで blocked となる下流 task を明示している。

横断整合の実地照合（下流 5 spec tasks.md を grep で確認）:

- runtime tasks.md：foundation `review_case` schema 準拠を「唯一の横断正本」とし、metadata 語彙・責務分離を「foundation §Run Metadata Contract を継承し再定義しない」と明記。validator-status 語彙を「foundation 所有の正準 enum をそのまま伝播し再定義・丸め・別トークン化をしない」と明記。Step B `adversarial_outcome` 3 語彙が foundation Task 4 の語彙と一致。
- evaluation tasks.md：`evidence_class` を foundation 由来とし `analysis_blocked` は「foundation evidence_class ではなく evaluation local state」と責務境界を明示。foundation 無効化伝播義務を入力起点とすると記載。
- self-improvement tasks.md：`schema_version` を「スキーマ所有は self-improvement 側、foundation 規約には接続宣言のみ（foundation 修正不要）」、backtest artifact を「foundation 実行メタデータ契約に束縛」と記載。
- paper-interface tasks.md：`maturity_label` を「foundation `evidence_class` に束縛された派生分類」「foundation 由来フィールドを再定義しない」、staleness 標識を「foundation 要件 6 受入 9 の伝播を受ける」と記載。
- implementation-governance tasks.md：状態語彙を「foundation 所有正準語彙を参照、再定義しない」、「feature logic graph に data producer を追加しない」と記載。

深掘り（命名衝突・暗黙の新義務）：下流 5 spec はいずれも foundation 語彙を「再定義しない／接続宣言のみ／foundation 修正不要」と一貫して書いており、foundation tasks.md に下流へ暗黙の新義務を課す記述はない。命名衝突（同名 artifact の別定義）は検出されない。foundation 所有 artifact 名（`review_case` / `evidence_class` / `validator_status` / `failure_observation` / `invalidation_marker` 等）は下流で参照のみで上書きされていない。参照順序（foundation 先行 → 下流 import）は §4・§5 と依存マップ §7 で一致。

他 5 spec tasks への波及：**0 件**（foundation tasks.md は所見のみで未変更。仮に後続で must-fix を適用しても、本レビューでは契約変更を要する所見が出ていないため波及見込みなし。下記観点 7 で再確認）。

必要性判定：**該当なし（致命・重要なし）**。横断タスクは foundation に正しく集約され、下流参照順序・命名は健全。タスクへの追記不要。

---

## 6. 観点 6：失敗時の巻き戻し単位

要点：各 Task 失敗時の影響範囲・巻き戻し単位が読めるか。

詳細抽出：foundation は実行コードを持たず、各 Task の成果物は独立 artifact（または directory skeleton）。Task 失敗時の巻き戻しは当該 artifact 単位で、他 artifact を破壊しない構造になっている（Task 間に生成物の相互改変がない）。Task 9 の機械検証が全 artifact を横断検証するため、個別 Task の不備は Task 9 で検出され、当該 artifact のみ再作成すれば回復する。

深掘り（軽微所見 T-2）：tasks.md は各 Task の「完了条件」は明記するが、「Task 失敗時の影響範囲・巻き戻し単位」を明示する独立記述は持たない。ただし foundation の性質（artifact が相互に副作用を持たない宣言的 contract 群、実行状態を持たない）から、巻き戻し単位＝当該 artifact 単位であることは構造上自明に読める。REVIEW_PROTOCOL 節 5 観点 6 は「明示されているか」を問うが、規範中心 feature では「観点 2〜6 で該当なし／軽微が多くなる」と節 5「ラウンド構成」が明記しており、本 feature はこれに該当。明示の欠如が実装不能や手戻り拡大を招く致命的デメリットは生じない（artifact 単位巻き戻しが構造的に保証されるため）。

必要性判定：**T-2 は軽微。利用者判断は不要だが任意採択候補として記録**。foundation のような規範中心 feature では巻き戻し単位が artifact 単位で構造的に自明なため、明示追記は任意。致命的デメリットがないため自動採択対象だが、tasks.md への追記内容は「§6 Completion Criteria 付近に『各 artifact は独立で、Task 失敗時の巻き戻し単位は当該 artifact 単位』の 1 文を補足」程度の軽微改善であり、必須ではない。タスク承認の阻害要因にはならない。

---

## 7. 観点 7：波及精査（最終ガード）

要点：観点 1〜6 の所見が他 Task・他 spec・上位文書に与える連鎖を最終確認。

詳細抽出：

- 観点 1・3・4・5：該当なし（致命・重要なし）。波及なし。
- 観点 2（T-1 軽微）：Task 4 の粒度は分割しない判断。tasks.md 改変なし。他 Task・他 spec・上位文書への波及なし。
- 観点 6（T-2 軽微）：仮に巻き戻し単位の 1 文を補足しても、contract（artifact 名・field・enum・配置）は不変であり、下流 5 spec の参照前提・依存マップ・REVIEW_PROTOCOL に変更を生じない。波及なし。

深掘り（連鎖の有無を全件明示）:

- 他 Task への波及：なし（T-2 は補足文のみで Task 間依存・順序を変えない）。
- 他 5 spec tasks への波及：**0 件**（runtime / evaluation / self-improvement / paper-interface / implementation-governance のいずれにも contract 変更が及ばない。語彙・field・配置すべて不変）。
- 上位文書への波及：なし（依存マップ §7、REVIEW_PROTOCOL 節 5、CONVENTIONS 命名規約のいずれも変更不要）。

必要性判定：**該当なし（致命・重要なし）**。本レビューの所見は軽微 2 件（T-1 / T-2）のみで、いずれも contract 不変・波及 0 件。タスク横断整合ゲートを止める要素はない。

---

## 8. 集計

- 致命：**0 件**
- 重要（must-fix 級）：**0 件**
- 軽微：**2 件**（T-1：Task 4 粒度＝分割せず据え置き判断・対応不要／T-2：巻き戻し単位の明示補足＝任意採択候補・必須でない）

観点別該当なし概況：

- 観点 1（設計全件網羅）：該当なし
- 観点 2（粒度・完了基準）：軽微 T-1（対応不要）
- 観点 3（依存・順序）：該当なし
- 観点 4（要件／設計トレース）：該当なし
- 観点 5（横断タスク抽出）：該当なし
- 観点 6（巻き戻し単位）：軽微 T-2（任意採択候補）
- 観点 7（波及精査）：該当なし／波及 0 件全件明示

他 5 spec tasks への波及：**0 件**（対象 spec：runtime / evaluation / self-improvement / paper-interface / implementation-governance、いずれも波及なし）。

---

## 9. 総合所見

foundation tasks.md は承認済み requirements（Requirement 1〜7、Requirement 5 削除）と design.md から全面再導出されており、設計全構成要素を漏れなく実装単位へ分解し、要件番号・設計章番号のトレースも完備、依存順序は依存マップ §7 と整合、横断タスクは shared contract owner たる foundation に正しく集約されている。下流 5 spec tasks.md はすべて foundation 語彙を「再定義しない／接続宣言のみ」と一貫しており、命名衝突・暗黙の新義務・参照順序破壊は検出されない。

検出所見は軽微 2 件のみで、いずれも contract 不変・波及 0 件・タスク承認の阻害要因にならない。

- must-fix 候補：**なし**
- 任意採択候補：T-2（巻き戻し単位の 1 文補足、必須でない）

結論：**タスク横断整合ゲートへ進めてよい**。must-fix 適用は不要。T-2 は必須でなく、横断整合ゲート後の人間承認パッケージで「軽微・任意」として併記すれば足りる（本レビュー単独での tasks.md 変更は行わない）。

---

## 10. 証跡

- 本証跡パス：`.kiro/specs/dual-reviewer-foundation/reviews/tasks-local-review-2026-05-18.md`
- 参照正本：`.kiro/specs/dual-reviewer-foundation/{tasks.md,design.md,requirements.md,spec.json}`、`operations/REVIEW_PROTOCOL.md` 節 5、`docs/alignment/phase-and-feature-dependency-map.md`、`CONVENTIONS.md`
- 横断照合対象：`.kiro/specs/dual-reviewer-{runtime,evaluation,self-improvement,paper-interface,implementation-governance}/tasks.md`
- 生証跡として不変。tasks.md / design.md / requirements.md / spec.json は本レビューで変更していない。
