# Design Reopen Review — dual-reviewer-runtime（実装適合差し戻し対応：設計境界の再確定 finding 2/5/6/9）

- 実施日: 2026-05-18
- 方式: 独立設計レビュアー（起草者とは別視点、REVIEW_PROTOCOL 節 3 の設計 10 観点）。差分レビュー＝finding 2/5/6/9 設計差し戻し対象節のみを検査する差分設計レビューであり、全面再導出ではない。
- 対象: `.kiro/specs/dual-reviewer-runtime/design.md`「## 実装適合差し戻し対応：設計境界の再確定（finding 2/5/6/9、2026-05-18）」節全体（commit 5100a6da 追加分、4 箇条 + 結語）
- 照合対象:
  - runtime design.md 他節（Boundary Clarification／Prompt Resolution Model／Step Execution Model／Treatment × Step Execution Matrix／Evidence Writing Model／Case Manifest and Heuristic Resolution Model／Generic Fragment Cue Rule（削除済み）／Validator Integration（Run Close Boundary / Validation Outcomes）／Decision 3／Testability Seams／Requirements Traceability）
  - runtime requirements.md（Requirement 1〜9、特に要件 3／4 受入 6／6 受入 9、Requirement 10 削除）
  - 基盤確定資産: `runtime/foundation/layer1_framework.yaml`、`runtime/foundation/metadata_contract.yaml`、`runtime/prompts/`（実 frontmatter）、`runtime/schemas/*.schema.json`、`runtime/validators/contracts/*.schema.json`
  - v2-acquisition: `.kiro/specs/dual-reviewer-v2-acquisition/requirements.md`（FR-1〜FR-9）
- 参考（鵜呑みにせず独立判断）: `reviews/implementation-conformance-review-2026-05-18.md` finding 2/5/6/9 原文
- 生証跡として不変扱い。design.md / spec.json / requirements.md は変更しない（点検と所見の記録のみ）。
- 設計レビューは HOW（どう実現するか）の具体化を検査する（要件レビューの WHAT 検査とは別）。手戻り A 群 7 件（finding 1/3/4/7/8/10/11）は runtime スクラッチ再実装で別途解消予定のため本レビュー対象外。再確定境界が A 群解消を阻害しないかは観点 9・総括で一言確認する。

---

## 観点 1: 要件全件の網羅（再確定境界が対応 finding の設計境界欠落を要件レベルで漏れなくカバーするか）

要点提示 → 詳細抽出 → 深掘り。差分節は 4 finding に 1 箇条ずつ対応し、各箇条が引く要件を点検した。

- finding 2 → 要件 3（Prompt Resolution and Version Traceability）受入 1（repo-contained のみ）/受入 3（role×step 区別）/受入 5（repo 外メモリ非依存）、要件 8 受入 6（override resolution policy runtime 所有）。差分箇条は frontmatter 規約＋`asset_locations` 唯一入力＋role×step 引き当て＋selection/override runtime 所有を述べ、これら受入の HOW を指す。対応あり。
- finding 5 → 要件 1 受入 1〜4（4-step pipeline 実行と state machine）、要件 4 受入 2（finding-level 出力）、Requirement 10 削除（規則ファイル参照・パターン照合撤廃）。差分箇条は実 LLM 呼び出し化＋差し替え可能 seam＋責務分界を述べる。対応あり。
- finding 6 → 要件 4 受入 6（review-mode provenance を foundation metadata contract 準拠で emit）、要件 6 受入 2（validator status 正準語彙の丸めなし伝播）。差分箇条は `metadata_contract.yaml` `fields:` 正本入力＋`required: true` 機械抽出＋`canonical_ownership.validator_status`＋`review_mode` enum 参照を述べる。対応あり。
- finding 9 → 要件 6 受入 9（human sign-off → validator → run close 順序、validator が human decision に先行しない）。差分箇条は単一起動点集約＋前提 3 条件＋多重起動禁止＋順序厳守を述べ「要件 6 受入 9 と一体」と明記。対応あり。

4 finding すべてに差分節の対応箇条があり、引く要件番号も妥当である。ただし「対応がある」ことと「実装可能なレベルまで HOW が具体化されているか／既存他節と矛盾しないか」は別であり、観点 2〜10 で精査する。観点 1 単体での致命級（受入未カバー＝差分節不在）はなし。

---

## 観点 2: アーキテクチャ整合性（再確定境界がモジュール分割・レイヤ・依存グラフ・責務境界と整合するか）

要点提示 → 詳細抽出 → 深掘り。4 finding を 1 件ずつ責務境界の観点で点検した。

**finding 2**: 「selection/override の適用順序は runtime 所有（foundation は拡張点の所在のみ固定）」は、design「Boundary Clarification」（runtime 所有＝prompt override resolution order）および基盤 `layer1_framework.yaml` `override_extension_point`（「選択順序・優先規則・適用条件は一切定義しない（runtime 責務）」）と一致。所有境界は曖昧でない。

**finding 5**: 「runtime は step を実行し evidence を emit することを所有、取得方式は v2-acquisition 所有、runtime は確定物を入力として参照するのみで再定義しない」は責務分界として明確。ただし下記 DR-1 のとおり「確定物」の参照接合面が差分節内に固定されておらず、v2-acquisition requirements との責務の穴が残る。

**finding 6**: validation 層が foundation `metadata_contract.yaml` を正本入力とし runtime 側で再定義しない方針は、design「Boundary Clarification」（foundation 所有＝metadata field definitions / validation artifact shapes）と整合。レイヤ依存方向（runtime → foundation consumer）は保たれる。

**finding 9**: 「validator 呼び出しは Run Close Boundary の単一起動点に集約」「controller が禁止する」は、design Architecture の `session controller`／`validation bridge` 4 役分割と整合。controller を順序ガードの保持者と位置づける点はアーキテクチャ的に妥当。

### DR-1: 重要 — finding 5 の「v2-acquisition 確定物」の参照接合面が差分節で未固定（責務の穴）

- 所在: 差分節 finding 5 箇条「取得方式（v2 取得の語彙・プロファイル等）は `dual-reviewer-v2-acquisition` 所有。runtime は v2-acquisition の確定物を入力として参照するのみで再定義しない」
- 現状: 「確定物を入力として参照する」とのみ述べ、(a) 何を確定物とみなすか（v2-acquisition requirements FR-1 役割設計／FR-2 モデル選定／FR-3 prompt 方針／FR-4 入力設計のどれが runtime 入力か）、(b) その参照接合面（runtime のどの層が、どの artifact/契約を、どの形で受けるか）が差分節にも他節にも書かれていない。
- 問題: 接合面が未固定だと、実装者が runtime 側に取得方式（モデル選定・別セッション起動・入力範囲計算）を再実装しても差分節と矛盾しない＝finding 5 が指摘した「責務の二重定義」を構造的に防げない。さらに v2-acquisition spec は research/design 段（spec.json 未承認、`v2-acquisition-design.md` は別リポジトリ参照）であり、「確定物」が現時点で確定していない。runtime design が「確定物を参照する」とだけ書くと、未確定物への前方依存が設計に残る。
- 推奨対応: 差分節 finding 5 箇条に最小限 (1) runtime が v2-acquisition から受ける入力の種別（role×step の LLM 呼び出し方式＝モデル/温度/別セッション起動方式は v2-acquisition 所有、runtime は role×step→prompt 解決と evidence emit のみ）、(2) 参照接合面＝testability seam（LLM 呼び出し境界）が v2-acquisition 確定方式の差し替え点である旨、(3) v2-acquisition 未承認段では runtime はモック seam で決定的検証可能で、確定後に実方式を差し込む（前方依存を seam で吸収）旨を明記する。
- 必要性判定: 設計に書くべき（接合面の未固定は finding 5 が解消すべき責務の穴そのもの。劣後案＝tasks/implementation 段で接合面を決めるは、設計レビューで責務二重定義の不在を検証できず finding 5 の解消判定ができないため明らかに劣る）。複数の合理的選択肢（接合面を runtime 所有 seam とするか、v2-acquisition 側 entrypoint とするか）が残り、かつ未承認 spec への前方依存の扱いは構造的決定のため → **利用者判断を仰ぐ**（自動採択不可）。

### DR-2: 軽微 — finding 9 の「freeze（raw evidence 凍結）」の実行主体・凍結点が差分節で未明示

- 所在: 差分節 finding 9 箇条「前提条件＝(1) Step D 統合完了、(2) human sign-off artifact 書込済み、(3) raw evidence 凍結済み」「順序＝Step D → human sign-off → freeze → validator → close」
- 現状: 「raw evidence 凍結済み」を前提条件かつ順序段に置くが、凍結を誰が（controller か evidence writer か）どの操作で（書込禁止フラグか、ハッシュ封緘か）行うかが差分節にも既存「Run Close Boundary」「Evidence Writing Model」（raw step outputs は immutable とのみ記載）にも具体化されていない。
- 問題: 凍結が「immutable と定める」だけの宣言に留まると、controller が「凍結済み」を機械判定する条件（前提条件 3）が実装不能になり、不変条件（多重起動・順序違反禁止）の前提が空文化する。
- 推奨対応: 差分節 finding 9 箇条または既存「Run Close Boundary」に、freeze の実行主体（controller が evidence writer に freeze を指示）と「凍結済み」を controller が機械判定できる observable（例：raw step file 集合の確定 + freeze marker artifact の存在）を 1 文で固定する。
- 必要性判定: 設計に書くべき（前提条件 3 の機械判定可能性が不変条件成立の前提。劣後案＝実装段で凍結方式決定は、不変条件が設計レベルで実装可能と言えず観点 6 失敗モード設計が検証できないため劣る）。凍結 observable の具体形に致命的デメリットを持つ劣後案はなく単一の合理案に収束 → **自動採択可**（推奨対応どおりの 1 文追記で足りる）。

---

## 観点 3: データモデル・スキーマ詳細（要件で宣言されたフィールド・値域が再確定境界で実スキーマと一致するか）

要点提示 → 詳細抽出 → 深掘り。基盤実ファイルと突き合わせた。

**finding 2 の frontmatter 規約突合**: 差分節は frontmatter が `prompt_id` / `version` / `role` / `step` / `language` / `source_ref` を持つと記す。実ファイル `runtime/prompts/{primary_detection,adversarial_review,judgment}/*.prompt.md` の frontmatter は `prompt_id` / `version` / `role` / `step` / `language` / `source_ref` の 6 キーで完全一致。撤廃済み旧資産（`prompts/shared/frontmatter_contract.yaml`）の参照排除も明記され、conformance review finding 2 の MISSING 指摘と整合。`asset_locations` 突合: `layer1_framework.yaml` `asset_locations.prompts` は `primary_detection` / `adversarial_review` / `judgment` の 3 キーに repo 相対パスを持つ（Step D は無し＝design「Role and Step Mapping」の Step D role なしと整合）。差分節「role×step から `asset_locations` の repo 相対パスを引き当て」は実構造と一致。データモデル整合は良好。

**finding 6 の metadata_contract 突合**: 差分節は `fields:` 構造を正本入力とし `required: true` から必須項目を機械抽出すると記す。実ファイル `runtime/foundation/metadata_contract.yaml` は `fields:` マップを持ち、各 field に `required: true/false` を持つ（実構造一致）。`validator_status` は `canonical_ownership.validator_status: [not_run, passed, failed, blocked]` を所有（差分節記載の 4 値と完全一致）。`review_mode` は `fields.review_mode.enum: [manual_dogfooding, runtime_mediated]`（差分節「同契約 enum を参照」と整合）。conformance review finding 6 の旧キー（`contract_id`/`required_fields`）不在指摘とも整合。データモデル整合は良好。

### DR-3: 重要 — design「Validation Outcomes」節が旧語彙 `pass`/`fail`/`blocked` のまま、再確定 finding 6 の `passed`/`failed` と内部矛盾

- 所在: design.md「## Validator Integration → Validation Outcomes」（`- pass` / `- fail` / `- blocked`、および本文「foundation が正準 validator 状態語彙として `pass` / `fail` / `blocked` を所有する」）対 差分節 finding 6（`canonical_ownership.validator_status`（`not_run`/`passed`/`failed`/`blocked`）参照）
- 現状: 差分節 finding 6 は基盤実 enum `not_run`/`passed`/`failed`/`blocked` を正本と再確定したが、既存「Validation Outcomes」節は `pass`/`fail`/`blocked`（過去形でない 3 値）のまま残置。基盤実ファイル `canonical_ownership.validator_status` は `[not_run, passed, failed, blocked]`。「Validation Outcomes」節の `pass`/`fail` は実 enum と不一致、かつ `not_run` を欠く。
- 問題: finding 6 の中心問い（runtime 側の再定義・別トークン化が排除されているか）に対し、差分節は正しいが design 他節（Validation Outcomes）が旧トークンを残すため design 内部で語彙が二重化。実装者が「Validation Outcomes」節を実装根拠にすると finding 7（`passed`/`failed` 2 値丸め、conformance review）と同型の不適合が再発する。差分節は「本節の確定により finding 6 の設計境界欠落は解消する」と結語するが、Validation Outcomes 節の旧語彙未修正により解消は不完全。
- 根拠: 差分節は design.md への追記のみで既存節を改訂しない方針（差し戻し節構成）だが、finding 6 の解消は「validation 層が再定義しない」ことの保証であり、design 内に正準語彙と矛盾する別語彙列挙が残るのは再定義の温存に等しい。
- 推奨対応: 差分節 finding 6 箇条に「既存『Validation Outcomes』節の `pass`/`fail`/`blocked` 表記は本再確定により `not_run`/`passed`/`failed`/`blocked`（基盤 `canonical_ownership.validator_status`）に読み替える。runtime は 4 値を丸めず伝播し `not_run` も保持する」旨の読み替え規定を 1 文追加する（既存節本文の改訂は差し戻し節構成上不要だが、読み替えの明示が無いと内部矛盾が残る）。
- 必要性判定: 設計に書くべき（design 内部の語彙二重化は finding 6 解消の不完全性であり、conformance finding 7 の再発経路を残す）。劣後案＝既存節を後で個別修正は、本差し戻しレビューの整合判定時点で内部矛盾が顕在しており差し戻し節の結語「解消する」が成立しないため劣る。読み替え 1 文に致命的デメリットなく単一合理案に収束 → **自動採択可**。

---

## 観点 4: API 接合面の具体化（再確定境界の解決方式・参照接合面がシグネチャ／エラーモデル／曖昧解決として実装可能か）

要点提示 → 詳細抽出 → 深掘り。

**finding 2**: 「role×step から `asset_locations` の repo 相対パスを引き当て、frontmatter を parse して本文を LLM に渡す」は解決アルゴリズムとして実装可能なレベル。エラーモデルは既存「Prompt Resolution Model」の resolution order 3「explicit failure if ambiguous」および要件 3 受入 4（解決不能時 fail/invalid）に接続。ただし下記 DR-4 のとおり差分節の「selection/override の適用順序は runtime 所有」と既存「Prompt Resolution Model」の resolution order（foundation canonical path → runtime override → ambiguous fail）の関係が再確定後に未整理。

**finding 5**: 差し替え可能 seam（LLM 呼び出し境界）を 1 点設けるとの記載は既存「Testability Seams」の「言語モデル差し替え点」と一致。接合面の具体化は DR-1 に集約。

**finding 6**: `required: true` 機械抽出は既存 design「Run Manifest Field Set」（開始時固定／実行中更新 2 群）と整合し、controller の `validate_required_metadata!` 相当が `fields:` 走査で必須集合を導く接合が明確。

**finding 9**: 単一起動点・前提条件 3・多重起動禁止は controller のライフサイクル API（close_run の事前条件契約）として実装可能なレベル。順序段も列挙済み。

### DR-4: 軽微 — finding 2 の「selection/override 適用順序 runtime 所有」と既存「Prompt Resolution Model」resolution order の関係が再確定後に未架橋

- 所在: 差分節 finding 2「selection/override の適用順序は runtime 所有」対 既存「Prompt Resolution Model」resolution order（1 foundation canonical prompt path → 2 runtime-owned role/phase override path → 3 explicit failure if ambiguous）
- 現状: 既存節の resolution order 1 は「foundation canonical prompt path」と記すが、差分節は解決入力を「`layer1_framework.yaml` `asset_locations` を唯一の入力」と再確定。両者の関係（asset_locations 引き当てが resolution order 1 を具体化したものか、置換か）が差分節で明示されない。
- 問題: 実装者が既存節の「foundation canonical prompt path」を asset_locations 以外（撤廃済み frontmatter_contract 等）と解釈する余地が残ると、finding 2 の「唯一入力」確定が骨抜きになる。
- 推奨対応: 差分節 finding 2 箇条に「既存『Prompt Resolution Model』resolution order 1 の foundation canonical prompt path は `layer1_framework.yaml` `asset_locations.prompts` を指す（他の foundation 資産を canonical path 源にしない）」旨を 1 文補う。
- 必要性判定: 設計に書くべき（唯一入力の確定を既存節と架橋しないと解釈余地が残る）。1 文補足に劣後案なし、致命的デメリットなし → **自動採択可**。

---

## 観点 5: アルゴリズム + 性能達成手段（計算量・端境界・性能手段）

要点提示 → 詳細抽出 → 深掘り。

- finding 2 の解決アルゴリズム（map 引き当て + frontmatter parse）は定数〜線形で性能論点なし。端境界（asset_locations に該当 role×step キーが無い＝Step D）は design「Role and Step Mapping」で Step D が role/prompt 非依存と既定済みのため差分節と矛盾しない。
- finding 5/6/9 はアルゴリズム・性能の新規論点を持たない（LLM 呼び出しレイテンシは v2-acquisition 所有、性能は試作測定方針）。
- 該当なし（差分範囲内に性能達成手段の設計欠落なし）。新規所見なし。

---

## 観点 6: 失敗モード処理 + 観測性（巻き戻し・再実行・タイムアウトの具体化 + 観測点）

要点提示 → 詳細抽出 → 深掘り。

- finding 9 が本観点の中心。多重起動禁止・3 条件未充足での起動禁止は失敗モード（順序違反・二重 close）の予防として具体化されている。ただし「禁止する」結果の挙動（fail-closed か no-op か、invalidation marker `run close without sign-off`／`treatment/step mismatch` との連動）が差分節で未記載。既存「Invalidation Handling」に `run close without sign-off` の自動 marker 型はあるが、controller が前提条件違反を検知したときに当該 marker を必ず付与する連結が差分節にない。
- finding 2 の解決失敗（asset_locations 不整合）は要件 3 受入 4 と既存「Invalidation Handling」`unresolved prompt identity` に接続済み（差分節は新規失敗モードを増やさない）。
- finding 6 の必須項目欠落は基盤 `rules.missing_required_metadata_is_validator_failure: true` と接続し validator failure 化が既定。差分節と矛盾しない。

### DR-5: 軽微 — finding 9 の「禁止」の失敗時挙動と invalidation marker 連結が差分節で未記載

- 所在: 差分節 finding 9「3 条件未充足での validator 起動および多重起動を controller が禁止する」
- 現状: 「禁止する」とのみ記し、禁止検知時に (a) fail-closed（run を `orchestration_failed` へ）するのか、(b) 既存「Invalidation Handling」の `run close without sign-off` marker を付与するのかが差分節にも既存節にも明示されない。
- 問題: 失敗モードの結果挙動が未定だと、不変条件違反が観測可能な artifact（invalidation marker / run_status）に落ちず、conformance review finding 9 が問題視した「実装が防げない」状態と機械的に区別がつかない（防いだ証跡が残らない）。
- 推奨対応: 差分節 finding 9 箇条に「前提条件違反・多重起動を検知した場合、controller は validator を起動せず当該 run を fail-closed（`orchestration_failed`）とし、`run close without sign-off`／`treatment/step mismatch` 相当の invalidation marker を付与する」旨を 1 文追加。
- 必要性判定: 設計に書くべき（失敗モードの観測可能化は不変条件が「実装上担保される」ことの証跡前提）。fail-closed + marker 付与に明白に劣る劣後案なし、致命的デメリットなし → **自動採択可**。

---

## 観点 7: セキュリティ・プライバシーの具体化（入力清浄化・ログ伏字・版管理除外）

要点提示 → 詳細抽出 → 深掘り。

- 差分節 4 finding はいずれも repo 内 artifact 解決・契約参照・順序保証に閉じ、外部入力清浄化・秘匿情報ログ・版管理除外の新規論点を持たない。finding 2 は「repo 外 prompt source を禁止」を既存「Prompt Resolution Model」が既定済みで差分節と整合（repo 外メモリ非依存＝要件 3 受入 5）。
- 該当なし／差分範囲外（差分範囲内にセキュリティ・プライバシーの設計欠落なし）。新規所見なし。

---

## 観点 8: 依存選定（ライブラリ・版制約・旧版継承との整合）

要点提示 → 詳細抽出 → 深掘り。

- finding 2/5/6 は旧版資産（`frontmatter_contract.yaml`／`review_mode_vocab.yaml`／`seed_patterns.yaml`／`heuristic_profile_ref`／`RuleMatchAnalyzer`）からの脱却を再確定する内容で、旧版継承の撤廃整合が中心。差分節は旧資産非参照・Requirement 10 削除整合・基盤新契約付け替えを明記し、conformance review finding 2/5/6 の旧依存指摘および design「Generic Fragment Cue Rule（削除済み）」「Case Manifest and Heuristic Resolution Model」備考（heuristic_profile_ref 撤廃）と一貫。
- ライブラリ・版固定の新規論点なし。旧版継承との整合は良好。新規所見なし（該当：旧版撤廃整合は確認済み）。

---

## 観点 9: テスト戦略（単体・統合・フィーチャー横断、および A 群解消阻害有無）

要点提示 → 詳細抽出 → 深掘り。

- finding 5 の「差し替え可能な seam（LLM 呼び出し境界）を 1 点設ける」は既存「Testability Seams」4 seam の第 1（言語モデル差し替え点：固定応答に置換して決定的検証）と一致し、conformance review finding 11（決定的検証ケース不在＝A 群）の解消基盤と整合。差分節は seam を 1 点に固定する点で finding 11 解消（4 seam の決定的検証ケース整備）を阻害しない。
- finding 9 の単一起動点集約は「検証ブリッジ起動点」seam（既存 Testability Seams 第 2）と一致し、A 群（finding 7 validator_status 丸め、finding 8 human_signoff フィールド）解消の前提を崩さない。
- A 群解消阻害の確認（一言）: 再確定境界は finding 1（config キー）/3（executor 引数契約）/4（prompt path/frontmatter キー）/7（blocked 丸め）/8（human_signoff フィールド）/10（adversarial_outcome）/11（決定的検証ケース）の task-local 修正方向と矛盾しない。むしろ finding 2 の frontmatter キー確定（`version`）は finding 4 の「frontmatter キー参照を `version` に統一」を、finding 6 の `canonical_ownership.validator_status` 確定は finding 7 の丸め撤廃を、それぞれ設計根拠として後押しする。A 群解消を阻害しない。
- テスト戦略単体の差分節固有の致命級なし。新規所見なし（DR-1 が seam を介した v2-acquisition 前方依存吸収に言及するため、テスト戦略観点はそこに包含）。

---

## 観点 10: 移行戦略（旧版から新版への移行・台帳形式変更時の移行スクリプト）

要点提示 → 詳細抽出 → 深掘り。

- 差分節は「実装（runtime スクラッチ再実装）は本節を前提に行う」と結語し、conformance review disposition（スクラッチ再実装相当の是正）と整合。移行＝旧 v1 ベース実装の置換であり、漸進移行ではなくスクラッチ再実装方針が明示されている点で移行戦略は単純（旧 run artifact の互換は design「v2 Compatibility Rule」が別途既定、差分節はそれを変更しない）。
- 旧資産（撤廃済み）への移行スクリプトは不要（基盤再実装で削除済み、差分節は非参照を再確定）。
- 移行戦略単体の差分節固有の致命級なし。新規所見なし（該当：スクラッチ再実装方針が明示済み、旧版継承は撤廃側で確定）。

---

## must-fix サマリ

- 致命: 0 件
- 重要: 2 件
  - DR-1（観点 2、対応 finding 5）: v2-acquisition 確定物の参照接合面が差分節で未固定。責務の穴。**利用者判断を仰ぐ**（未承認 spec への前方依存の扱い＝構造的決定）
  - DR-3（観点 3、対応 finding 6）: design「Validation Outcomes」節が旧語彙 `pass`/`fail` のまま、再確定 finding 6 の `passed`/`failed`/`not_run` と内部矛盾。読み替え規定の追加で自動採択可
- 軽微: 3 件
  - DR-2（観点 2、対応 finding 9）: freeze の実行主体・凍結点（controller 機械判定 observable）が未明示。自動採択可
  - DR-4（観点 4、対応 finding 2）: 「selection/override 順序 runtime 所有」と既存 resolution order 1 の架橋未記載。自動採択可
  - DR-5（観点 6、対応 finding 9）: 「禁止」の失敗時挙動（fail-closed + invalidation marker 連結）が未記載。自動採択可

A 群 7 件（finding 1/3/4/7/8/10/11）は本レビュー対象外。再確定境界が A 群解消を阻害しないことは観点 9 で確認済み（むしろ finding 4/7 の修正根拠を後押し）。

---

## 総括

- **finding 2（Prompt Resolution Model 構造的付け替え）**: 解消（条件付き）。frontmatter 6 キー・`asset_locations` 突合は実ファイルと完全一致、旧資産非参照・所有境界明確で HOW レベルの設計境界欠落は実質解消。残課題は DR-4（既存 resolution order との架橋、軽微・自動採択可）のみ。
- **finding 5（Step Execution と v2-acquisition 責務境界）**: 部分解消。実 LLM 化・seam・責務分界の方向は妥当だが、DR-1（参照接合面未固定＝責務の穴、重要、利用者判断）が未解消。接合面の明示なしでは finding 5 が指摘した責務二重定義の不在を設計レベルで保証できない。
- **finding 6（validation 層の基盤新契約付け替え）**: 部分解消。`fields:`／`required: true`／`canonical_ownership.validator_status`／`review_mode` enum はすべて実ファイルと一致し正本入力化の HOW は確定。ただし DR-3（design「Validation Outcomes」節の旧語彙 `pass`/`fail` 残置による内部矛盾、重要・自動採択可）の読み替え規定を欠くため、design 内部での再定義温存が残り解消は不完全。
- **finding 9（run close 順序保証＝controller 不変条件）**: 部分解消。単一起動点・前提 3 条件・多重起動禁止・順序段は不変条件として実装可能なレベルに具体化。ただし DR-2（freeze の機械判定 observable 未明示、軽微）・DR-5（禁止の失敗時挙動と marker 連結未記載、軽微）が残り、不変条件の「観測可能性」が未閉。いずれも自動採択可の 1 文追記で閉じる。
- **内部整合**: 再確定節は Prompt Resolution Model／Step Execution Model／Run Close Boundary／Testability Seams／Decision 3／Requirements Traceability と概ね整合するが、DR-3（Validation Outcomes 旧語彙）と DR-4（resolution order 架橋）で既存節との語彙・参照の架橋不足が残る。requirements.md 要件 6 受入 9・要件 3・要件 4 受入 6・Requirement 10 削除との整合は確認。
- **設計健全性の判定**: 致命級ゼロ。重要 2 件（DR-1 利用者判断要・DR-3 自動採択可）の解消を条件に設計健全。DR-1 は未承認 spec（v2-acquisition）への前方依存の扱いを含む構造的決定のため、本差し戻し節の人間再承認前に利用者判断が必要。DR-3 を含む自動採択可 4 件は差し戻し節への 1 文追記で閉じる。現状の差分節のみでは finding 5/6 の解消が不完全であり、**DR-1 の利用者判断 + DR-3 の読み替え追記を経たうえで設計横断整合ゲートへ進むことを推奨**する。
