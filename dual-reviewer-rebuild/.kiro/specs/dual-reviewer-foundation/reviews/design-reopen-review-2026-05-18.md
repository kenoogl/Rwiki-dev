# dual-reviewer-foundation 設計差し戻し 差分設計レビュー証跡

- 実施日：2026-05-18
- 方式：独立設計レビュアー（起草者と別視点）。`operations/REVIEW_PROTOCOL.md` 節 1（基本規律）・節 3（設計レビューの 10 観点）に準拠。差分レビュー（finding 8 設計差し戻しで再確定した設計境界の差分のみを対象とし、全面再導出はしない）。
- レビュー対象：`.kiro/specs/dual-reviewer-foundation/design.md` §4「Shared Schema Relationships」に追記された小節「mandatory/deferred の JSON Schema 符号化規約」（commit a3b2d9ec、design.md 行 294〜301）。
- 照合対象：
  - 正本 `.kiro/specs/dual-reviewer-foundation/design.md`（§3 Run Metadata Contract、§4 schema 定義群・provenance・5 schema 関係図、§5 step-level replay、§8 validator-facing 2 contract）
  - 正本 `.kiro/specs/dual-reviewer-foundation/requirements.md`（要件 3 受入 3・9）
  - finding 原文 `.kiro/specs/dual-reviewer-foundation/reviews/implementation-conformance-review-2026-05-18.md` Finding 8（鵜呑みにせず独立判断）
  - 実装資産 `runtime/schemas/*.schema.json`（5 件）、`runtime/validators/contracts/*.schema.json`（2 件）、`runtime/foundation/metadata_contract.yaml`
- 不変条項：本ファイルは生証跡として不変扱い。本レビューは点検と所見の記録のみで、design.md / spec.json / requirements.md は一切変更しない。

---

## 観点 1：要件全件の網羅

- 所在：design.md §4 符号化規約 4 箇条、要件 3 受入 9。
- 現状：受入 9（mandatory / deferred の明示）に対し、規約は (a) mandatory=required 列挙、(b) deferred=required 非列挙＋`description`＋`x-deferred`、(c) 形状 mandatory／意味論 deferred の混在項目の扱い、(d) 適用範囲、の 4 箇条で HOW を与える。受入 3（versioned かつ silent 非互換編集の禁止）との関係では、`required` を正本表現に固定したことで「必須/任意の境界が機械可読」になり受入 3 の機械検出が補強される。
- 問題：受入 9 が求める「項目ごと」の粒度に対し、規約本文は schema 単位と field 単位を併記しているが、`required` は object 直下の field にしか効かないため、`review_case` のような入れ子（`step_records` 配列 items 内の step-level replay 6 項目、§5）における mandatory 表現が「各入れ子オブジェクトの `required` を再帰適用する」と規約本文で明示されていない。差分レビュー範囲内の軽微な明確性不足。
- 推奨対応：規約箇条 1 に「入れ子 object / 配列 items についても各階層の `required` で mandatory を表現する」を 1 文追記。
- 必要性判定：設計に書くべき＝はい（受入 9 の「項目ごと」は入れ子項目も含むため）。劣後案＝実装の慣習任せ（機械検証の正本性が崩れるため劣後）。致命的デメリット＝なし。自動採択可否＝可（追記は規約の自然な精緻化で選択肢が割れない）。重要度＝軽微。所見 ID＝D1。

## 観点 2：アーキテクチャ整合性

- 所在：design.md §4 規約箇条 4「runtime / evaluation / self-improvement はこの符号化を前提に import してよい」。
- 現状：規約は foundation を符号化の単一正本とし、下流 3 フィーチャーが import 前提にできることを宣言。依存方向（下流→foundation の一方向）は §4 5 schema 関係図および Impact on Downstream Specs と整合。
- 問題：なし。依存グラフ・レイヤ境界に矛盾は検出されない。
- 推奨対応：なし。
- 必要性判定：該当なし（差分はアーキ依存方向を変更せず、既存方向を明文化するに留まる）。重要度＝該当なし。

## 観点 3：データモデル・スキーマ詳細

- 所在：design.md §4 規約箇条 1〜3、実装資産 7 schema。
- 現状：実ファイル突き合わせ結果。
  - `impact_score.schema.json`：`required` に 4 軸、`x-deferred` に値語彙/採点尺度/重み付けの evaluation 委譲、各軸 `description` に「値語彙は deferred」。規約箇条 3（形状 mandatory／enum 不記載／`x-deferred` 委譲）に完全一致。
  - `failure_observation.schema.json`：`required` に 6 項目、`x-deferred` に `failure_type` 詳細分類の self-improvement/evaluation 委譲、`failure_type` `description` に deferred 明記。規約一致。
  - `necessity_judgment.schema.json`：`required` に 5-field＋label＋action、`override_reason` を非列挙＋`description`「optional」。`override_reason` は design §4 で「optional」だが規約上 deferred ではない（任意 field であって先送り拡張点ではない）。規約は optional と deferred を別概念として扱う前提だが、規約本文に「optional（B-1.0 で任意だが先送りでない）と deferred の区別」が明示されていない。
  - `review_case.schema.json`：`step_records.items.required` に §5 の 6 項目を展開（finding 8 のもう一方の指摘＝step-level replay identity が schema から機械確認不能だった点を解消）。`x-deferred` 不在は規約箇条 2（deferred 拡張点が存在する場合のみ付す）と整合（review_case は deferred 拡張点なしと description で宣言）。
  - `finding.schema.json`：`adversarial_outcome` に `enum`（3 値）を schema 内に記載しつつ `description` に「語彙拡張は deferred」。規約箇条 3 は「値域 enum を schema に書かず `x-deferred` に委譲」と規定するが、本 field は初版語彙を mandatory として固定し拡張のみ deferred する「部分先送り」型で、規約箇条 3 の文面と表面上競合する。design §4 finding 本文は「最小語彙を固定し拡張は deferred」と明記しており設計意図は一貫しているが、規約箇条 3 はこの「初版 enum 固定＋拡張 deferred」型を対象外としていて、規約が現行実装の符号化を網羅できていない。
- 問題：規約箇条 3 が二分（完全 deferred の enum 不記載 / mandatory 形状）しかカバーせず、`finding.adversarial_outcome`・`invalidation_marker.scope`・`validator_result.validator_status` のような「初版 enum を mandatory 固定し将来拡張のみ deferred」型の符号化規約が欠落している。Finding 8 の設計境界欠落（mandatory/defer を機械可読に区別する規約の未具体）は主要部分は解消しているが、この第 3 類型が未規定なため部分的に残存。
- 推奨対応：規約に第 3 類型を 1 箇条追加。「初版語彙を固定する field は `enum` を schema に記載（形状・初版語彙とも mandatory）し、語彙の将来拡張が deferred である旨を `description` に記し `x-deferred` に拡張委譲先を併記する」。
- 必要性判定：設計に書くべき＝はい（現行 3 schema が該当し、規約が実装の符号化を説明できないと finding 8 の解消が不完全）。劣後案＝enum 記載 field をすべて完全 deferred 化し enum を抜く（design §4 finding/§8 が初版語彙固定を要件として明記しており設計意図に反するため劣後・採用不可）。致命的デメリット＝なし。自動採択可否＝可（設計意図と実装が既に一致しており、規約文面を実態に合わせる精緻化で選択肢が割れない）。重要度＝重要（finding 8 の中心問い 1・3 に直接かかる）。所見 ID＝D2。

## 観点 4：API 接合面の具体化

- 所在：design.md §4 規約箇条 4（下流 import 前提）。
- 現状：規約は schema を接合契約として下流へ引き渡す際の符号化規約を固定。シグネチャ／冪等性／ページ送りといった呼び出し API はこの差分の範囲外。
- 問題：なし（差分範囲外）。
- 推奨対応：なし。
- 必要性判定：該当なし／差分範囲外。重要度＝該当なし。

## 観点 5：アルゴリズム + 性能達成手段

- 所在：該当箇所なし。
- 現状：符号化規約は静的 schema 注記規約であり、計算量・性能達成手段を伴わない。
- 問題：なし。
- 推奨対応：なし。
- 必要性判定：該当なし／差分範囲外。重要度＝該当なし。

## 観点 6：失敗モード処理 + 観測性

- 所在：design.md §4 規約箇条 2（`x-deferred` 注記）、要件 3 受入 3。
- 現状：規約は `x-deferred` を「先送り対象と委譲先を文章で示す」とのみ規定。`x-deferred` は JSON Schema 標準語彙でない拡張キー（`x-` 接頭辞）で、validator がこれを未知キーとして無視するか検査対象にするかは規約に書かれていない。silent 非互換編集の検出（受入 3）の観点では、deferred 拡張点が後に mandatory 化された際に `x-deferred` の更新漏れを機械検出する手段が規約上未定義。観測性としては `description` と `x-deferred` の二重記載で人間可読性は確保。
- 問題：`x-deferred` の機械的取り扱い（validator が読むのか単なる注記か）が規約で未定義。ただし design §8 で具体的検証手段は evaluation/validator design へ委譲する方針が確立済みで、foundation 段で機械契約まで固める要求は要件にない。差分範囲内では軽微。
- 推奨対応：規約箇条 2 に「`x-deferred` は人間可読注記であり、機械的 deferred 検査の要否は validator design に委ねる」と委譲先を 1 文明示（責務境界の明確化のみ。検査機構の設計は不要）。
- 必要性判定：設計に書くべき＝はい（委譲先未明示は責務境界の空白）。劣後案＝foundation で `x-deferred` 検査機構まで設計（要件外・スコープ拡大で劣後）。致命的デメリット＝なし。自動採択可否＝可（委譲先明示のみで選択肢が割れない、design §8 の既定方針と一貫）。重要度＝軽微。所見 ID＝D3。

## 観点 7：セキュリティ・プライバシーの具体化

- 所在：該当箇所なし。
- 現状：符号化規約は入力清浄化・暗号化・伏字を伴わない静的 schema 規約。
- 問題：なし。
- 推奨対応：なし。
- 必要性判定：該当なし／差分範囲外。重要度＝該当なし。

## 観点 8：依存選定

- 所在：design.md §4 規約箇条 2（`x-deferred` 拡張キー）、各 schema の `$schema` 宣言。
- 現状：実装資産は JSON Schema draft 2020-12 を採用。`x-deferred` は draft 2020-12 で許容される未知 keyword（`x-versioning-note` 等と同系統）であり版制約と矛盾しない。規約は `x-deferred` を新規導入するが既存の `x-versioning-note` / `x-raw-evidence-rule` / `x-staleness-propagation` と命名規約（`x-` 接頭辞）が一貫。
- 問題：なし。
- 推奨対応：なし。
- 必要性判定：該当なし（差分は新ライブラリ・新版制約を導入しない）。重要度＝該当なし。

## 観点 9：テスト戦略

- 所在：design.md §4 規約箇条 1〜4、design.md Test Strategy 節。
- 現状：規約により「mandatory field が `required` に列挙されているか」「deferred 拡張点に `x-deferred`＋`description` があるか」が schema 単体検査の判定基準になり得る。Test Strategy 節は framework 整合の YAML 検査を記載するが、7 schema が本符号化規約に準拠しているかを検証する単体検査の境界が Test Strategy 節に追記されていない（差分は §4 のみ変更で Test Strategy 未更新）。
- 問題：本符号化規約の準拠検査をどのテスト層（schema 単体検査）で担保するかが設計上未明示。規約が下流 import の前提となるため、規約準拠の検査境界の明示は実装フェーズ直結。
- 推奨対応：Test Strategy 節に「各 schema が §4 符号化規約に準拠（mandatory=required 列挙、deferred=`x-deferred`＋`description`）することを schema 単体検査で確認する」境界を 1 文追記。
- 必要性判定：設計に書くべき＝はい（REVIEW_PROTOCOL 節 3 は観点 9 を規模小でも該当なし扱いせず最小でも単体/統合境界明示を要求）。劣後案＝検査を実装裁量に委ねる（規約準拠が検証されないと finding 8 の機械検証性確保が形骸化、劣後）。致命的デメリット＝なし。自動採択可否＝可（単体検査境界の明示のみで選択肢が割れない）。重要度＝軽微。所見 ID＝D4。

## 観点 10：移行戦略

- 所在：design.md §4 規約箇条、commit c4928ff3（実装はスクラッチ再実装で本符号化前提に構築済み）。
- 現状：finding 8 設計差し戻しは実装手戻りなし（commit メッセージ a3b2d9ec／conformance review の handback 整理と一致）。実ファイル突き合わせの結果、`impact_score`・`failure_observation` は規約箇条 3 に完全一致、`review_case`・`finding`・`necessity_judgment` も箇条 1・2 に整合しており、本規約は現行実装の符号化を追認する形（旧版からの移行スクリプトは不要）。ただし観点 3 D2（第 3 類型の規約欠落）と後述 D5（validator-facing 2 contract の `x-deferred` 不使用）により、規約と実装の一部に文面上の不整合が残るため、規約を実装の現状に整合させる差分は移行ではなく規約精緻化として扱うべき。
- 問題：`invalidation_marker.schema.json` は「具体的な陳腐化フラグ付け／再導出手段は evaluation / paper-interface に委ねる」という deferred を `x-staleness-propagation` キーで表現し `x-deferred` を用いていない。規約箇条 4 は「5 schema および validator-facing contract 2 schema に一律適用」と明記するため、2 contract も deferred 拡張点には `x-deferred` を用いる（または `x-staleness-propagation` のような専用キーを `x-deferred` の特例として許容する）規約が必要だが、規約本文がこの特例を許容するのか一律 `x-deferred` 強制なのかが曖昧。`validator_result` は deferred 拡張点を持たず `x-deferred` 不在で整合。
- 推奨対応：規約箇条 4 に「validator-facing 2 contract で deferred を表現する際、専用注記キー（例 `x-staleness-propagation`）を `x-deferred` の代替として用いてよいが、その場合も deferred 対象と委譲先を文章で示す」と特例可否を 1 文明示。
- 必要性判定：設計に書くべき＝はい（規約箇条 4 が一律適用を宣言する一方で実装が専用キーを使っており、規約と実装の整合判定基準が空白）。劣後案＝`invalidation_marker` を `x-deferred` へ書き換える前提を規約に課す（実装手戻り発生・finding 8 の「実装手戻りなし」前提に反するため劣後）。致命的デメリット＝なし。自動採択可否＝可（実装の現状を追認する特例明示で選択肢が割れない）。重要度＝重要（規約箇条 4 の適用範囲宣言と実装の不整合で中心問い 4 に直接かかる）。所見 ID＝D5。

---

## must-fix サマリ

- 致命：0 件。
- 重要：2 件。
  - D2（観点 3）：規約箇条 3 が「初版 enum 固定＋拡張のみ deferred」型（`finding.adversarial_outcome` 他）を対象外とし、規約が現行実装の符号化を網羅できていない。第 3 類型の箇条追加が必要。
  - D5（観点 10）：規約箇条 4 が 2 validator-facing contract への一律適用を宣言するが、`invalidation_marker` は `x-staleness-propagation` で deferred 表現しており `x-deferred` 不使用。専用注記キー特例の可否明示が必要。
- 軽微：3 件。
  - D1（観点 1）：入れ子 object / 配列 items の mandatory 表現（再帰 `required`）が規約に未明示。
  - D3（観点 6）：`x-deferred` の機械的取り扱い（validator 検査の要否）の委譲先未明示。
  - D4（観点 9）：規約準拠を確認する schema 単体検査の境界が Test Strategy 節に未追記。

## 総括

- finding 8 の設計境界欠落（mandatory/deferred を機械可読に区別する規約が design 未具体だった点）は、規約箇条 1（mandatory=`required` 正本表現）・箇条 2（deferred=非列挙＋`description`＋`x-deferred`）・箇条 3（形状 mandatory／意味論 deferred 分離）・箇条 4（7 schema 一律適用＋下流 import 前提）により主要部分が HOW レベルで解消された。実ファイル突き合わせでも `impact_score`・`failure_observation` は規約箇条 3 に完全一致し、`review_case` は finding 8 のもう一方の指摘（step-level replay identity の schema 機械確認不能）も併せて解消している。
- ただし規約は「初版 enum 固定＋拡張 deferred」型（実装で 3 schema が該当、D2）と validator-facing 2 contract の専用注記キー特例（D5）を規定しておらず、規約箇条 3・4 が現行実装の符号化を一部説明できない。この 2 件は規約と既存実装の文面整合の空白であり、いずれも実装手戻りを伴わない規約精緻化で閉じる（劣後案はすべて実装手戻りを誘発し finding 8 の「実装手戻りなし」前提に反するため不採用）。
- 設計健全性判定：**要修正**（致命 0／重要 2／軽微 3）。重要 2 件は設計境界の本質的欠落というより「規約が実装の現状を完全には記述しきれていない網羅不足」であり、規約への箇条追加・特例明示で解消可能。致命的破綻はなく、finding 8 の設計差し戻しの主旨は概ね達成されているが、D2・D5 を解消しない限り「規約が実装の符号化を過不足なく説明する」状態には至っていないため、設計横断整合ゲート前に重要 2 件の反映を要する。
