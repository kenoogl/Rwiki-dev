# 設計横断整合ゲート — 基盤 finding 8・実行系 finding 2/5/6/9 設計差し戻しの横断波及（2026-05-18）

- 実施日: 2026-05-18
- 方式: 独立横断整合ゲート（起草者・設計個別レビュアーとは別プロセス、`operations/REVIEW_PROTOCOL.md` 節 1 基本規律・節 4 フィーチャー横断レビューパターンに準拠）
- 対象: 基盤フィーチャー finding 8（手戻り B）と実行系フィーチャー finding 2/5/6/9（手戻り B 群）の設計差し戻し（design reopen）による横断波及。独立設計レビュー（節 3、別プロセス）の must-fix 反映後の design.md 状態を横断視点で独立点検する（個別レビュー結論は鵜呑みにしない）
- 横断対象 6 機能: dual-reviewer-foundation / -runtime / -evaluation / -self-improvement / -paper-interface / -implementation-governance の design.md・requirements.md
- 接合面相手方: dual-reviewer-v2-acquisition（requirements.md / research.md / spec.json）
- 正本確認: 横断・順序判断の前提として正本 `docs/alignment/phase-and-feature-dependency-map.md` を最初に通読・確認した（節 0 に結果を記載）
- 不変条項: 本ファイルは生証跡として不変扱い。design.md / spec.json / requirements.md は一切変更しない（点検と所見の記録のみ）。C 群が出た場合も適用要否は呼び出し元が利用者判断する（本ゲートでは追記しない）

---

## 0. 正本確認結果（REVIEW_PROTOCOL 節 4「横断・順序判断の前提」に従い最初に実施）

正本 `docs/alignment/phase-and-feature-dependency-map.md` を最初に通読し、依存・順序を確認した。

- 節 3.1: 下流 phase は上流 phase の approved 状態に依存。**同 phase に修正が入ったら、その phase の alignment gate を再実施する。上流 phase に修正が入ったら、完了済みの下流 phase も reopen 対象になる。**
- 節 4.2 Foundation: runtime / evaluation / self-improvement / paper-interface に対し `hard dependency`。理由＝metadata field・schema shape・review-mode vocabulary・provenance field naming が foundation owner。
- 節 4.3 Runtime: foundation に `hard dependency`、evaluation / self-improvement に `interface dependency`。
- 節 4.7 Implementation-Governance: runtime / evaluation / self-improvement / paper-interface に対し `review dependency`。「feature data contract を生成するのではなく completion gate を追加する」と明記。
- 節 5.2 Design Wave 順序: foundation → runtime → evaluation → self-improvement → paper-interface →（6）design alignment gate →（7）implementation-governance。
- 節 8: shared owner の変更／design で依存方向が変わる修正は依存マップ本体の更新対象。

本ゲートは WORKFLOW_OVERVIEW.md §3 是正ルール（review wave で同じ phase の文書が修正された場合、次 phase に進む前にその phase の alignment gate を再実施する）に基づき、基盤・実行系の design reopen に伴う設計横断整合ゲートの**再実施**に該当する。正本に明示がある事項（依存方向、reopen 連鎖規律、design wave 順序）はそれに従った。正本に明示がない構造的決定（連鎖 reopen を要するか、依存マップ本体改訂の要否）は本ゲート単独で採択せず、所見で「利用者確認要」を明記する（REVIEW_PROTOCOL 節 4 / discipline_ssot_structural_decision_check）。

### 0.1 差し戻し起点の差分（横断影響の起点）と must-fix 反映状況の確認

- 基盤 `dual-reviewer-foundation/design.md` §4「mandatory/deferred の JSON Schema 符号化規約」小節：working tree 突合の結果、独立設計レビュー（`reviews/design-reopen-review-2026-05-18.md`）の must-fix 5 件（D1 入れ子 required／D2 第 3 類型箇条／D3 x-deferred 機械検査委譲／D4 Test Strategy 1 行／D5 validator-facing 専用注記キー特例）はすべて design.md に反映済み（行 298・299・301・302・569）。
- 実行系 `dual-reviewer-runtime/design.md`「実装適合差し戻し対応：設計境界の再確定（finding 2/5/6/9）」節：working tree 突合の結果、独立設計レビューの must-fix 5 件（DR-1 v2-acquisition 接合面＝実行系所有 seam で吸収＝**利用者判断確定済み**／DR-2 freeze observable／DR-3 Validation Outcomes 読み替え／DR-4 resolution order 架橋／DR-5 fail-closed marker 連結）はすべて節内に反映済み。
- 本ゲートはこの must-fix 反映後の状態を横断点検対象とする。個別レビューが「条件付き解消」とした DR-1（利用者判断要の構造的決定）は、task 指示文に「実行系所有 seam で吸収＝利用者判断確定」と明記されており、利用者判断が下りた前提で横断整合を点検する。

---

## 1. 観点別横断点検（REVIEW_PROTOCOL 節 4 の整合性チェック観点）

差し戻し起点は 2 つ：(A) 基盤 §4 符号化規約（mandatory=`required`／deferred=`x-deferred`+`description`／意味論先送りは形状 mandatory＋値域 `x-deferred` 委譲／初版語彙固定の第 3 類型／入れ子 required／validator-facing 専用注記キー特例／x-deferred 機械検査は validator design 委譲）、(B) 実行系の再確定（finding 2 resolution order 架橋／finding 5 v2-acquisition 接合面＝実行系所有 seam 吸収／finding 6 Validation Outcomes 旧語彙読み替え／finding 9 freeze observable・fail-closed marker）。観点別に 6 機能＋v2-acquisition を横断点検する。

### 1.1 観点：共通契約・唯一の正本の同期メカニズム（中心問い 1）

基盤 §4 符号化規約が、これを import 前提にする runtime / evaluation / self-improvement の既存記述と矛盾しないか、下流が旧前提（符号化規約が未具体だった頃の記述）に依存していないかを点検。

- **依存方向**：符号化規約は「runtime / evaluation / self-improvement はこの符号化を前提に import してよい」と宣言。依存方向（下流→foundation 一方向）は依存マップ節 4.2（foundation hard dependency）および基盤設計 5 schema 関係図・Impact on Downstream Specs と整合。新規依存方向の追加・反転はない（依存マップ節 8 の更新トリガに非該当）。
- **下流の旧前提依存の有無**：
  - evaluation `design.md`：foundation 成果物を `validation/invalidation_markers.json`・`run_manifest.yaml`・`review_case.json`・`validator_result.json` 等の **artifact shape（成果物形状）単位**で参照（行 123/151/212）。必須項目数や enum 値リストを foundation からハードコピーした記述は検出されない。符号化規約は「mandatory をどう機械可読に表現するか（`required` 列挙 vs `x-deferred`）」を確定するもので、各 field の意味論・値域・形状そのものを変更しない。よって evaluation の artifact 参照は符号化規約適用前後で不変＝旧前提依存なし。
  - self-improvement `design.md`：foundation schema を `validator_failed`／`invalidation_marker_issued` 等のイベント／marker 単位で参照（行 205）。同様に値域・必須数のハードコピーなし。符号化規約は schema 注記規約であり self-improvement の signal intake / proposal provenance 記述に波及しない＝旧前提依存なし。
  - runtime：差し戻し起点（B）側で finding 6 が `metadata_contract.yaml` `fields:` 構造＋`required: true` 機械抽出を正本入力に再確定。符号化規約（基盤側 §4）は schema 注記、metadata_contract は YAML field 定義で別資産だが、いずれも「mandatory を機械抽出可能にする」方向で一貫しており矛盾しない（後述 1.3 で finding 8↔6 相互矛盾を個別点検）。
- **第 3 類型・専用注記キー特例の下流影響**：第 3 類型（初版 enum 固定＋拡張 deferred、`finding.adversarial_outcome` 他）と validator-facing 2 contract の専用注記キー特例（`x-staleness-propagation`）は、いずれも foundation 実装の現状を規約が追認する精緻化で、schema の形状・値域を変えない。下流は schema 形状を消費するため波及なし。

判定：A 群（確認済整合）。下流 3 機能は符号化規約の対象 schema を形状単位で消費し、旧前提（符号化未具体時の記述）への依存は検出されない。

### 1.2 観点：責務境界の二重定義・穴／接続契約の 3 要素（中心問い 2）

実行系の再確定（v2-acquisition 接合面＝実行系所有 seam で吸収、Validation Outcomes 読み替え、freeze observable、fail-closed marker）が v2-acquisition・evaluation・implementation-governance の既存 design/requirements と整合するか、v2-acquisition との責務境界に二重定義や穴がないかを点検。

- **finding 5 × v2-acquisition 責務境界**：再確定節は接合面を 3 点で固定—(1) runtime が受ける入力種別＝role×step の LLM 呼び出し方式（モデル／温度／別セッション起動方式）は v2-acquisition 所有、runtime は role×step→prompt 解決と evidence emit のみ所有、(2) 参照接合面＝testability seam（LLM 呼び出し境界）を v2-acquisition 確定方式の差し替え点とし接合面の正本は runtime 所有 seam に置く、(3) v2-acquisition 未承認段は runtime がモック seam で決定的検証、確定後に実方式を差し込む。
  - v2-acquisition `requirements.md` 突合：FR-1（3 役別セッション起動）・FR-2（役別モデル版・温度 0）・FR-3（prompt 方針）・FR-4（入力範囲設計）が「取得方式」を所有。runtime 再確定は取得方式を v2-acquisition 所有と明記し、runtime 側はモデル選定・別セッション起動・入力範囲計算を**再実装しない**ことを seam で構造的に担保。責務の二重定義は検出されない。責務の穴（どちらも所有しない領域）も、role×step→prompt 解決＋evidence emit を runtime、LLM 呼び出し方式を v2-acquisition と排他配分しており検出されない。
  - 未承認 spec への前方依存：v2-acquisition `spec.json` は phase=`tasks-generated`、requirements/design/tasks すべて approved=false（未承認）。再確定節は前方依存を runtime 所有 testability seam（既存「Testability Seams」第 1：言語モデル差し替え点）で吸収し、設計に未承認 spec への直接前方依存を残さない方式。これは依存マップに明示のない構造的決定（未承認 spec への前方依存の扱い）だが、**task 指示文で「実行系所有 seam で吸収＝利用者判断確定」と明示**されており利用者判断が下りている。本ゲートは追認のみ（新規構造決定なし）。
- **finding 6 × evaluation（validator_status 分類）**：再確定節は `validator_status` を基盤 `canonical_ownership.validator_status`（`not_run`/`passed`/`failed`/`blocked`）参照、runtime 側で再定義・別トークン化しないと確定。evaluation `design.md` Classification Rules（行 178/182/188）は `validator_status=passed`（valid）／`=failed`（invalid）／`=blocked`（analysis_blocked）を分類トリガに使用—基盤正準語彙と完全一致、旧 `pass`/`fail` トークンは不在。`not_run` は evaluation の分類トリガに明示列挙されないが、`not_run`（validator 未実行）の run は evaluation の `run_status != closed`／required input 不足経路で `analysis_blocked` に落ちる設計（行 188 直後の運用補足「created や途中中断 run は analysis_blocked」）であり、`not_run` が分類で取りこぼされる穴ではない。整合。
- **finding 6 × implementation-governance（gate/台帳）**：governance `design.md` 行 444 は validator 拡張モードの状態語彙を「foundation 所有の正準 validator 状態語彙（`not_run`/`passed`/`failed`/`blocked`）を参照元とし、統治では再定義・別トークン化しない」と明記。runtime finding 6 の再確定と同一正準語彙・同一非再定義方針で一貫。governance は completion gate 追加のみで feature data contract を生成しない（依存マップ節 4.7）ため、runtime 再確定が governance gate 定義に波及しない。整合。
- **finding 9 × implementation-governance（fail-closed/台帳）**：再確定節は前提条件違反・多重起動検知時に validator を起動せず run を fail-closed（`orchestration_failed`）とし invalidation marker を付与。`orchestration_failed` は基盤 `metadata_contract.yaml` `run_status` enum（`created`/`in_progress`/`closed`/`orchestration_failed`）に存在する既定値で、新トークン導入なし。governance `design.md` 行 430 は「pass だけでなく blocked・fail-closed・陳腐化/改竄検知イベントも台帳に記録」と既定—runtime の fail-closed 化と整合（governance は fail-closed を台帳記録対象として既に想定）。整合。

判定：A 群（確認済整合）。v2-acquisition との責務境界は排他配分で二重定義・穴ともなし。evaluation・governance とも正準語彙・既定 enum 値で一貫し、新トークン導入・責務越境なし。

### 1.3 観点：再検証の双方向反映／契約参照の依存連鎖（中心問い 3）

基盤 finding 8 と実行系 finding 6 はいずれも validator 状態語彙（not_run/passed/failed/blocked）と metadata_contract に触れる。両差し戻しの相互矛盾を点検。

- 基盤 finding 8（符号化規約）：mandatory を `required` 列挙で機械可読化、初版語彙固定 field は `enum` を schema に記載（第 3 類型）。基盤 `metadata_contract.yaml` 突合—`validator_status` は `required: true`（mandatory＝`required` 表現と整合）かつ `enum: [not_run, passed, failed, blocked]`（初版語彙固定＝第 3 類型と整合）。`purpose` 散文に「pass / fail / blocked」表記があるが、これは人間可読 description（符号化規約 D2 系で description は人間可読、機械値は `required`/`enum` が正本という建付け）であり、機械語彙の正本は `enum` の 4 値。
- 実行系 finding 6（読み替え）：runtime `design.md`「Validation Outcomes」節の旧 `pass`/`fail`/`blocked` 表記を `not_run`/`passed`/`failed`/`blocked`（基盤 `canonical_ownership.validator_status`）に読み替え、4 値を丸めず伝播・`not_run` 保持と明記。
- 相互矛盾の有無：両差し戻しとも「機械語彙の正本は基盤 `enum`/`canonical_ownership` の 4 値（`not_run`/`passed`/`failed`/`blocked`）、散文の旧表記（pass/fail）は人間可読 description であって機械トークンではない」という同一の建付けに収束。基盤 finding 8 は「散文 description と機械 `required`/`enum` の役割分離」を符号化規約として確立し、実行系 finding 6 は「散文の旧 pass/fail を機械 4 値に読み替える」ことを runtime 側で確定—両者は同方向（散文と機械語彙の分離・機械語彙を 4 値正準化）であり相互矛盾しない。むしろ基盤 finding 8 の符号化規約が、実行系 finding 6 の「散文表記に引きずられず機械 enum を正本とする」読み替えの設計根拠を補強する関係。

判定：B 群（既存対応済・記録のみ）。基盤 finding 8 と実行系 finding 6 は同一の語彙正本（基盤 4 値 enum）に収束し相互矛盾なし。両差し戻しの独立設計レビューが各々この点を解消済み（基盤 D2／実行系 DR-3）であり、横断点でも追加対応不要。記録のみ。

### 1.4 観点：フェーズの対象範囲制約／連鎖 reopen 要否（中心問い 4）

依存マップ正本に照らし、今回の差し戻しが下流フィーチャーの design/tasks 承認状態に波及（連鎖 reopen 要否）するかを点検。

- spec.json 突合（6 機能）：
  - foundation：phase=`tasks-approved`、`reopened.design=true`、`recheck.impacted_downstream_phases=["design","tasks"]`。差し戻しは自フィーチャーの design/tasks を impacted とし、design reopened 中。
  - runtime：同上（phase=`tasks-approved`、`reopened.design=true`、`impacted_downstream_phases=["design","tasks"]`）。
  - evaluation / self-improvement / paper-interface / implementation-governance：いずれも phase=`tasks-approved`、`reopened.design=false`、`upstream_change_pending=false`、`impacted_downstream_phases=[]`（reopen マークなし）。
- 連鎖 reopen 要否判定：依存マップ節 3.1「上流 phase に修正が入ったら完了済みの下流 phase も reopen 対象になる」に照らす。foundation は evaluation/self-improvement/paper-interface に hard dependency、runtime は evaluation/self-improvement に interface dependency。今回の差し戻しの実質変更は：
  - 基盤 §4 符号化規約＝既存実装（commit c4928ff3 スクラッチ再実装）の符号化を design に**追認・明文化**するもの。schema の形状・値域・必須集合を変更せず、下流が消費する artifact shape は不変（1.1 で確認）。よって下流 design/tasks の前提（artifact shape）は変わらず、連鎖 reopen の実体的トリガ（下流が依存する契約の変更）は発生しない。
  - 実行系再確定＝runtime 内部の責務境界・読み替え・observable の明文化。evaluation が消費する `validator_status` 値域は基盤正準 4 値で不変（1.2 で確認）、self-improvement の replay 依存も artifact shape 不変。下流が依存する interface（artifact shape・provenance field）は変わらない。
- 構造的決定の扱い：連鎖 reopen を要するか否かは依存マップに自動判定ルールがある（節 3.1「上流修正→下流 reopen 対象」）が、「上流修正」が**契約変更を伴わない明文化・追認**の場合に下流 reopen を要するかは正本に明示がない構造的決定。本ゲートの点検結果は「下流が依存する契約（artifact shape・値域・必須集合・provenance）に実体変更なし＝連鎖 reopen の実体的必要性なし」だが、依存マップ節 3.1 の文言は形式上「上流 phase に修正が入ったら」を reopen トリガとしており、形式適用と実体判断が分岐しうる。**この最終判定（4 下流を連鎖 reopen 対象に形式マークするか、実体変更なしとして据え置くか）は依存マップに明示のない構造的決定のため、本ゲート単独で採択せず利用者確認を要する**（discipline_ssot_structural_decision_check）。

判定：不整合ではない（C 群でもない）。点検事実＝下流が依存する契約に実体変更なし。ただし連鎖 reopen の形式適用要否は**利用者確認要**の構造的決定として節 3・節 4 に明記する。

### 1.5 その他観点（命名・参照・上書き階層・利用者向け契約メタ情報・テスト戦略横断）

- 命名・参照整合：`x-deferred`／`x-staleness-propagation` の命名は基盤既存の `x-` 接頭辞拡張キー（`x-versioning-note` 等）と一貫（個別レビュー観点 8 で確認済、横断点でも新規衝突なし）。`orchestration_failed`／`validator_status` 4 値は基盤 metadata_contract 既定値で下流参照と一致。A 群。
- 上書き階層：符号化規約「validator-facing 2 contract で専用注記キーを `x-deferred` の代替に用いてよい（特例）」は基盤内の特例規定で下流の上書き階層に影響しない。A 群。
- テスト戦略横断：基盤 Test Strategy に追記された「各 schema が §4 符号化規約に準拠することを schema 単体検査で確認」は foundation 内の機械検証境界で、下流の統合・横断テスト設計に新規依存を生まない（governance の validator 拡張モードは終了コード契約で疎結合、行 444）。A 群。
- 利用者向け契約メタ情報：本差し戻しは時刻・コミットハッシュ等のメタ情報契約を変更しない。該当なし。

判定：A 群（確認済整合）。

---

## 2. 3 群分類の集計

REVIEW_PROTOCOL 節 4 の 3 群分類に整理する。

- **A 群（確認済整合・対応不要）：4 件**
  - A-1（1.1）：下流 3 機能（evaluation/self-improvement/runtime）は符号化規約対象 schema を artifact shape 単位で消費、旧前提依存なし。
  - A-2（1.2）：v2-acquisition との責務境界は排他配分で二重定義・穴ともなし。evaluation/governance とも正準語彙・既定 enum で一貫。
  - A-3（1.5 命名・参照）：`x-deferred`/`x-staleness-propagation`/`orchestration_failed`/4 値語彙は基盤既定と命名・値とも一貫、新規衝突なし。
  - A-4（1.5 上書き階層・テスト戦略横断・メタ情報）：符号化規約特例は基盤内規定、Test Strategy 追記は foundation 内検証境界で下流に新規依存を生まない。
- **B 群（既存対応済・記録のみ）：1 件**
  - B-1（1.3）：基盤 finding 8 と実行系 finding 6 は同一語彙正本（基盤 4 値 enum）に収束し相互矛盾なし。両差し戻しの独立設計レビュー（基盤 D2／実行系 DR-3）が各々解消済み、横断点で追加対応不要。
- **C 群（新規含意・各機能に軽微追記で対応）：0 件**
  - 横断点検で初めて顕在化した、各機能への軽微追記を要する新規含意は検出されなかった。
- **不整合（進行を止める）：0 件**
  - 受け入れ基準違反・実装不可能性・契約の二重定義/穴は検出されなかった。

通常パターン（A 群・B 群が大部分、C 群少数、不整合 0）と整合し、本ゲートは C 群 0・不整合 0 で完走。

---

## 3. C 群含意の 4 要素＋必要性判定

C 群 0 件のため、4 要素記述・必要性判定の対象なし。

---

## 4. 連鎖 reopen 要否の判定

- **点検事実**：今回の差し戻し（基盤 §4 符号化規約の明文化／実行系再確定）は、いずれも下流が依存する契約（schema artifact shape・値域・必須集合・provenance field・review-mode/validator-status 語彙）に**実体変更を伴わない**。基盤側は既存スクラッチ再実装の符号化を design に追認、実行系側は runtime 内部の責務境界・読み替え・observable の明文化。よって evaluation/self-improvement/paper-interface/implementation-governance が依存する interface は不変であり、連鎖 reopen の**実体的必要性は検出されない**。
- **spec.json 現状**：下流 4 機能とも `reopened.design=false`／`upstream_change_pending=false`／`impacted_downstream_phases=[]`（reopen マークなし）。foundation/runtime のみ自フィーチャー design reopened 中で impacted=["design","tasks"]。
- **構造的決定（利用者確認要）**：依存マップ節 3.1 の reopen 連鎖規律は文言上「上流 phase に修正が入ったら完了済みの下流 phase も reopen 対象」と形式トリガを定めるが、「修正」が**契約変更を伴わない明文化・追認**の場合に下流を形式的に reopen マークするか実体変更なしとして据え置くかは正本に明示がない。本ゲートは点検事実（実体変更なし＝実体的連鎖 reopen 不要）を提示するに留め、4 下流の連鎖 reopen 形式マーク要否の**最終判定は利用者確認を要する**（REVIEW_PROTOCOL 節 4 / discipline_ssot_structural_decision_check）。本ゲート単独では下流の spec.json を変更せず（不変条項どおり点検のみ）、現状の reopen マークなし状態を据え置く判断材料を提示する。

---

## 5. 総括

- **不整合 0 件で完走**：6 機能＋v2-acquisition の横断点検で、受け入れ基準違反・実装不可能性・契約の二重定義/穴は検出されなかった。3 群分類＝A 群 4／B 群 1／C 群 0／不整合 0。
- **中心問い 1（基盤符号化規約 vs 下流）**：下流 3 機能は対象 schema を artifact shape 単位で消費し、旧前提（符号化未具体時の記述）への依存は検出されない。符号化規約は schema 注記の機械可読化であり形状・値域を変えないため波及なし（A 群）。
- **中心問い 2（実行系再確定 vs v2-acquisition/evaluation/governance）**：v2-acquisition との責務境界は role×step→prompt 解決+evidence emit（runtime）と LLM 呼び出し方式（v2-acquisition）の排他配分で二重定義・穴ともなし。未承認 spec への前方依存は利用者判断確定済みの runtime 所有 testability seam で吸収。evaluation の validator_status 分類・governance の台帳/gate とも基盤正準 4 値・既定 enum で一貫（A 群）。
- **中心問い 3（基盤 finding 8 vs 実行系 finding 6）**：両差し戻しは同一語彙正本（基盤 `canonical_ownership.validator_status` の 4 値 enum）に収束し相互矛盾なし。散文 description と機械語彙の分離という同一建付けで一貫（B 群・記録のみ）。
- **中心問い 4（連鎖 reopen 要否）**：下流が依存する契約に実体変更なし＝実体的連鎖 reopen 不要。ただし依存マップ節 3.1 の形式トリガ適用要否（契約不変の明文化で下流を形式 reopen マークするか）は正本に明示なき構造的決定のため**利用者確認要**として節 4 に明記。本ゲートは下流 spec.json を変更しない。
- **設計人間再承認への進行可否**：横断整合の観点では不整合 0・C 群 0 で完走しており、基盤 finding 8・実行系 finding 2/5/6/9 設計差し戻しの横断波及は閉じている。**設計人間再承認に進める**（横断整合ゲート再実施の必須後続を充足）。ただし進行前に、節 4 の構造的決定（下流 4 機能の連鎖 reopen 形式マーク要否）について利用者確認を 1 点要する。これは横断整合の不整合ではなく、reopen 連鎖規律の形式適用範囲に関する手続き上の利用者判断事項であり、設計人間再承認の判断材料として併せて提示する。
