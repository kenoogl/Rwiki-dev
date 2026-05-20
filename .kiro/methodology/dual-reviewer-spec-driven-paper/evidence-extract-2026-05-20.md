# 有効レビュー記録 出典付き構造化抽出（D-C）

_作成日: 2026-05-20_
_位置付け: 論文1（SES2026 実践論文）の証拠土台。論文化方針（正本）§2「証拠基盤」と今後の計画（正本）§1「D-C」に基づく素材。本文書は素材であり主張ではない_
_対の正本: 同ディレクトリ `paperization-policy-2026-05-20.md` / `overall-plan-2026-05-20.md`_

---

## 0. この文書の規律と読み方

- 各定量値には出典を併記する。出典は「ファイル相対パス:行番号」（レビュー記録）または「コミットの短縮ハッシュ」（git）。出典に辿れない値は載せない。
- 事実（記録に書かれていること）と、解釈（記録から読み取れる傾向の説明）を節で明示的に分ける。§1〜§6 は事実。§7 は観察と解釈で、人間承認前の素材である。
- 用語の意味（初出時併記）:
  - 指摘件数 = レビューで挙げられた所見の数。
  - 重大度 = 所見の深刻さの段階。フェーズにより記録語が異なる（要件・設計の個別レビューは CRITICAL/ERROR/WARN/INFO、タスクと適合レビューは 致命/重要/軽微 または P1/P2/P3）。
  - 差し戻し区分（手戻り種別）= 所見をどこまで戻して直すかの分類。A＝その作業内で吸収（task-local）、B＝設計まで戻す、C＝要件まで戻す、D＝上位意図まで戻す。出典＝`dual-reviewer-rebuild/operations/WORKFLOW_OVERVIEW.md` 第4節。
  - やり直し（reopen）= 承認済みフェーズを問題検出により再開すること。
  - 判定 = レビューの結論語（GO 可／要手戻り（GO 不可）／設計整合ゲート不通過 など、記録された語のまま）。
  - 見落とし事例 = 指示違反・仕様逸脱が前段の関門を素通りし、後段の点検や独立レビューで初めて捕捉された旨が記録された箇所。
- 対象範囲（有効・git 追跡）: 6機能の `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-{foundation,runtime,evaluation,self-improvement,paper-interface,implementation-governance}/reviews/*.md`（計36ファイル、2026-05-20 に foundation の postrebuild レビューを補完追加）＋ git コミット名。
- 除外: `experiments/protocols/_archived-2026-05-13/`（汚染・退避、論文化方針§2「除外」）。レビュー記録の無い `dual-reviewer-v2-acquisition` は本抽出の対象外。
- パス略記: 以下、各機能節のレビュー記録は `…/.kiro/specs/dual-reviewer-<機能>/reviews/<ファイル名>` を `<ファイル名>` と略記する。

### 0.1 記録様式に関する事実（全機能共通）

- 差し戻し区分（A/B/C/D）の件数内訳が記録されているのは実装適合レビュー（implementation-conformance）のファイルのみ。要件・設計・タスクの各個別レビューは must-fix／should-fix／leave-as-is の区分で集計し、A/B/C/D は使わない（各機能の該当項に「該当記述なし」と明記）。
- 「§4 metric snapshot」という構造化定量節（conformance_findings_count・severity_weighted_finding_score・post_smoke_nonconformance_count 等）を持つのも実装適合レビューのファイルのみ。
- 重み付けスコア（severity_weighted_finding_score）の重みは P1=3／P2=2／P3=1。foundation の適合レビューは「重み付け尺度は foundation で未確定（design §4 で deferred）のため暫定」と注記している（`implementation-conformance-review-2026-05-18.md:133`）。

---

## 1. dual-reviewer-foundation（基盤）

### 1.1 要件 個別レビュー — `requirements-local-review-2026-05-13.md`

- 指摘件数: 主役発見11件（`:208`）、敵対役独立発見9件（`:300`）。
- 最終集計（記録語）: must-fix 6件（うち P-1 と A-2 が同根で実質5件）／should-fix 8件／leave-as-is 6件（`:369`–`:372`）。
- 重大度: 主役所見は CRITICAL/ERROR/WARN/INFO で各所見行に個別記録（例 `:18` CRITICAL、`:32` ERROR）。集約節に重大度別合計の数値表記は無し。
- 差し戻し区分（A/B/C/D）: 該当記述なし（must-fix/should-fix/leave-as-is のみ）。
- やり直し（reopen）: 該当記述なし。
- 判定: 「must-fix が6件（実質5件）あるため、要件フェーズをこのまま先に進めるべきではない」（`:374`）。
- 見落とし事例: 該当記述なし。

### 1.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- 指摘件数: 主役 P-1〜P-21（21件）、敵対役独立 A-1〜A-6（6件）（`:176`）。
- 最終集計（記録語）: must-fix 9件／should-fix 11件／leave-as-is 7件（`:400`–`:402`）。主役 ERROR 以上は6件（`:168`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。要件への差し戻し「なし」（`:420`–`:422`）、他spec設計への波及「なし」（`:424`–`:426`）。
- やり直し（reopen）: 該当記述なし（初回設計レビュー）。
- 判定: 総合GO/手戻りの単一語は該当記述なし。敵対役総括「主役の ERROR 6件はいずれも実在」（`:273`）。
- 見落とし事例: 主役が10ラウンドで未検出の独立発見 A-1/A-2/A-5 を敵対役が指摘（`:264`、`:276`）。関門すり抜けではなく敵対役関門内の検出。

### 1.3 設計差し戻し 差分レビュー — `design-reopen-review-2026-05-18.md`

- 位置付け: 適合レビュー Finding 8（手戻りB候補）の設計差し戻しに対する差分設計レビュー（`:1`、`:4`–`:5`、`:9`）。コミット `a3b2d9ec`（基盤 finding 8 設計差し戻し）。
- 指摘件数: 所見5件（D1〜D5）。致命0／重要2／軽微3（`:104`–`:111`）。
- やり直し（reopen）: 本ファイル自体が reopen 対応の差分レビュー。Finding 8（mandatory/deferred の JSON Schema 表現境界が design 未具体、disposition=reopen-design）を受けたもの（`:117`）。
- 判定: 設計健全性判定「要修正（致命0／重要2／軽微3）。D2・D5 を解消しない限り規約が実装の符号化を過不足なく説明する状態に至っていない」（`:117`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。

### 1.4 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- 指摘件数: 致命0／重要0／軽微2件（T-1, T-2）。must-fix 候補なし（`:155`–`:157`、`:179`）。
- 他5spec への波及: 0件（`:169`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。
- やり直し（reopen）: 該当記述なし。
- 判定: 「タスク横断整合ゲートへ進めてよい。must-fix 適用は不要」（`:182`）。
- 見落とし事例: 直接の事例記述なし。位置付けに「tasks wave 再生成時に省略した機能個別タスクレビューの正規実施」（`:7`）＝前段で省略された関門の事後補完である旨。

### 1.5 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-18.md`

- 出典コミット: `1c3af809`（基盤 実装適合レビュー証跡：finding 9件 致命5/重要3/軽微1、手戻りA8/B1）。
- 指摘件数: finding 9件。`conformance_findings_count`: 9（`:131`）。
- 重大度内訳: P1=5（Finding 1–5）／P2=3（Finding 6–8）／P3=1（Finding 9）（各 Finding 見出し `:30`–`:118`）。severity_weighted_finding_score 22（`:132`、暫定重みの注記 `:133`）。
- 差し戻し区分（A/B/C/D）: A=8／B=1／C=0／D=0（各 Finding の handback assessment 行 `:38` `:49` `:60` `:71` `:82` `:93` `:104` `:126`＝A、`:115`＝Finding 8 B、総括 `:148`「handback はすべて A（Finding 8 のみ保守的に B）であり要件・intent の再開は不要」）。git コミット名 `1c3af809`「A8/B1」と一致。
- やり直し（reopen）: Finding 8 を design に差し戻し（`:116`、`:144`、`:148`）。実施結果が §1.3。
- 判定: 総括「既存コードの現行仕様適合度: 低い」（`:146`）。
- 見落とし事例: 削除済み Requirement 5 資産と検証スクリプトが旧仕様を前提化＝実装が旧仕様ベースである直接証拠（Finding 4 `:68`）。既存 smoke が完走せず非適合を検出できず（`:134`、`:58`）＝smoke 関門のすり抜け。要件再開（2026-05-17）に実装未追従（`:147`）。
- その他定量: post_smoke_nonconformance_count 9、fixture_bound_resolution_count 1、heuristic_linkage_count 0（`:134`–`:138`）。
- 再実装: コミット `c4928ff3`（基盤スクラッチ再実装：適合 finding A 8件解消）。

### 1.6 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-20-postrebuild.md`

- 追補日: 2026-05-20。本論文骨子レビューを受けて欠損を補完（補完前は本機能のみ postrebuild レビュー記録が無く、図1・図2 の収束データに穴があった）。
- reviewed commit: `cea191b8` 時点の作業ツリー（基盤の再実装は `c4928ff3` で完了済み）。
- 指摘件数: 新規 finding 1件。`conformance_findings_count`: 1（P1=0／P2=0／P3=1）。
- 重大度内訳: 新規 P3 1件（`finding.schema.json` トップレベル `x-deferred` 注記欠落、軽微）。severity_weighted_finding_score 1。
- 差し戻し区分（A/B/C/D）: A=1／B=0／C=0／D=0。
- やり直し（reopen）: 不要。前回 finding 9件すべて解消を独立確認（B群1件＝Finding 8 は design §4 符号化規約追記により構造的に解消、A群8件は task-local 解消）。
- 判定: 「GO 可。基盤再実装は承認仕様に構造適合、残1 finding は本ブランチ内 task-local cleanup で吸収、reopen 不要」。
- 検証結果: `scripts/validate_foundation_contracts.rb` 完走 exit 0、`tests/foundation/test_foundation_contracts.rb` 8 runs / 107 assertions / 0 failures（無回帰）。
- 見落とし事例: 該当記述なし（新規 finding は schema 注記の軽微欠落のみで関門すり抜け事例ではない）。

---

## 2. dual-reviewer-runtime（実行系）

### 2.1 要件 個別レビュー — `requirements-local-review-2026-05-13.md`

- 指摘件数: 主役発見10件（`:9`）、敵対役 反論3件＋独立発見12件（`:120`）。
- 最終集計（記録語）: must-fix 9件／should-fix 12件／leave-as-is 4件（`:277`–`:279`）。must-fix 帰属＝foundation 修正7件・runtime 修正2件（`:283`、`:291`）。
- 重大度: CRITICAL/ERROR/WARN/INFO で各所見行に記録（例 `:11` P-1 CRITICAL、`:110` P-10 INFO）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。
- やり直し・見落とし・§4 metric snapshot: 該当記述なし。

### 2.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- 指摘件数: 主役発見15件（`:184`）、敵対役独立発見8件（`:277`）。
- 重大度（主役視点）: ERROR 3件／WARN 9件／INFO 2件（`:176`–`:178`）。
- 最終集計（判断役）: must-fix 13件／should-fix 9件／leave-as-is 1件（`:447`–`:456`）。must-fix 帰属＝runtime 設計固有10件・要件差し戻し1件（A-4）・他spec設計波及2件（A-5,A-6）（`:471`、`:485`、`:489`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。
- やり直し（reopen）: 該当記述なし。A-6 で要件削除済み領域への設計スコープ漏洩を must-fix 指摘（`:427`–`:428`）。
- 見落とし事例: A-1・A-6 は主役10観点で未検出、A-6 は「要件＝契約原則そのものへの違反」（`:278`、`:260`）。

### 2.3 設計差し戻し 差分レビュー — `design-reopen-review-2026-05-18.md`

- 位置付け: 適合レビュー（再実装前）の reopen-design（Finding 2/5/6/9）を受けた差分設計レビュー（`:1`、`:4`–`:5`）。コミット `5100a6da`（実行系 B群4件 設計差し戻し）、`1085b3f1`（差し戻し関門消化）。
- 指摘件数: 新規所見5件（DR-1〜DR-5）。致命0／重要2（DR-1,DR-3）／軽微3（`:170`–`:177`）。
- やり直し（reopen）: 本ファイルが reopen 対応の差分レビュー。手戻りA群7件（finding 1/3/4/7/8/10/11）は本レビュー対象外＝runtime スクラッチ再実装で別途解消予定と明記（`:13`、`:179`）。結語にスクラッチ再実装方針が明示（`:162`）。
- 判定: 設計健全性「致命級ゼロ。重要2件（DR-1 利用者判断要・DR-3 自動採択可）の解消を条件に設計健全」（`:190`）。finding 2/5/6/9 は「解消（条件付き）／部分解消」（`:185`–`:188`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし（参照元 finding を「A群7件／B群＝finding 2/5/6/9」と区別する記述は `:13`、`:179`）。

### 2.4 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- 指摘件数: 合計9件。致命0／重要4（T2-A,T3-A,T3-B,T5-A）／軽微5（`:243`–`:246`）。
- 必要性判定: 自動採択7件／利用者判断2件（`:250`–`:251`）。他spec波及＝修正0件・記録のみ1件（`:275`）。
- 差し戻し区分（A/B/C/D）: 件数内訳は該当記述なし。所見T6-A内で handback class の語に言及（`:195`）。
- やり直し（reopen）: 該当記述なし。タスク全面再導出の独立批判視点である旨（`:5`）。
- 判定: 「致命0件。重要4・軽微5はいずれも runtime tasks.md 内で閉じ、要件書・設計書・spec.json・他spec改版を要さない」（`:281`）。横断ゲート前に must-fix 適用を推奨（`:283`）。

### 2.5 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-18.md`

- 出典コミット: `bea2dbeb`（実行系 実装適合レビュー証跡：finding 11件 致命6/重要3/軽微2、手戻りA7/B4）。reviewed commit `a3b2d9ec…`（`:12`）。
- 指摘件数: finding 11件。`conformance_findings_count`: 11（P1=6／P2=3／P3=2）（`:174`）。severity_weighted 26（`:175`、`:182`）。
- 差し戻し区分（A/B/C/D）: A=7／B=4／C=0／D=0。
  - 【原文内部の不整合・要注記】総括行 `:194` は本文に「A=5件」と記すが、同行括弧内に Finding 1・3・4・7・8・10・11（7件）を列挙し本文数値と一致しない。
  - 確定根拠（複数の独立出典が A7/B4 を支持）: ① disposition summary（`:187`–`:190`）で reopen-design＝Finding 2・5・6・9（B群4件）、残り7件（1・3・4・7・8・10・11）が非reopen、② §2.3 設計差し戻しが finding 2/5/6/9 を B群4件と明示、③ git コミット名 `bea2dbeb`「手戻りA7/B4」、④ 後続 §2.6 適合レビュー（再実装後）が「前回 finding 11件（A7/B4）」と参照（`implementation-conformance-review-2026-05-19.md:133`）。
  - 解釈は加えず事実として: 正は A7/B4。`:194` 本文の「A=5件」は原文の内部記載不整合。
- 判定: 「既存 runtime 実装は現行承認仕様に未適合。`initialize_run` 段階で実行不能。スクラッチ再実装相当の是正が必要」（`:193`）。
- やり直し（reopen）: B群4件（Finding 2/5/6/9）について reopen 10ステップ起動・スクラッチ再実装方針を人間承認に諮ると推奨（`:188`、`:195`）。
- 見落とし事例: 承認仕様の中核方針（パターン照合撤廃、Requirement 10 削除）に実装が旧 v1 のまま＝致命的仕様逸脱（Finding 5 `:102`）。Finding 11＝回帰基盤が無く Finding 1〜10 の破綻が静的検出されないまま tasks-approved に至った（`:167`）。
- その他定量: post_smoke_nonconformance_count 11（smoke 段階で全件露見）、fixture_bound_resolution_count 3、heuristic_linkage_count 1（`:176`–`:178`）。
- 再実装: コミット `ef5b6b69`（実行系スクラッチ再実装：全11タスクをTDDで再構築）。

### 2.6 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-19.md`

- reviewed commit `1085b3f1…`（`:6`）。
- 指摘件数: 新規 finding 3件。`conformance_findings_count`: 3（P1=0／P2=0／P3=3）（`:89`）。severity_weighted 3（`:90`）。
- 差し戻し区分（A/B/C/D）: A=3／B=0／C=0／D=0（`:107`、各 Finding `:60` `:72` `:84`）。
- やり直し（reopen）: 新規 reopen なし（`:103`）。前回 finding 11件（致命6/重要3/軽微2、A7/B4）を「全11件解消」と独立確認（B群4件は再確定設計どおり、A群7件は task-local）（`:133`、`:114`–`:129`）。
- 判定: 「現行承認仕様（再確定設計を含む）へ構造適合。GO 可。残3 finding（P3/A）は本ブランチ内 cleanup（reopen 不要）」（`:106`、`:108`、`:135`）。
- 見落とし事例: 旧 v1 実装ファイル群が物理削除されず git-tracked のまま残存（Finding 1 `:53`、`:57`）＝require 閉包の点検で検出。
- その他定量: テスト 15ファイル 170 runs / 1226 assertions / 0 failures（`:42`）。post_smoke_nonconformance_count 0（`:91`）。

---

## 3. dual-reviewer-evaluation（評価）

### 3.1 要件 個別レビュー — `requirements-local-review-2026-05-16.md`

- 指摘件数: 主役所見9件（ERROR4/WARN4/INFO1）（`:158`–`:161`）、敵対役独立5件、計14件（`:261`）。
- 最終集計（判断役）: must-fix 3件／should-fix 7件／leave-as-is 5件（`:357`–`:359`）。帰属＝evaluation固有（A-2,A-3）／foundation 修正（P-4）／他spec なし（`:365`–`:373`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。
- やり直し: 該当記述なし。
- 判定: 「設計着手前に must-fix 3件の解消を推奨」（`:379`）。GO/fail の総括語は該当記述なし。
- 見落とし事例: 主役の判定基準の一貫性欠落を敵対役が指摘（`:183`）。A-2/A-3 は主役の列挙系指摘より研究結論の妥当性に直結（`:253`）。

### 3.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- 指摘件数: 主役28件（ERROR6/WARN16/INFO6）、敵対役独立7件（`:226`–`:253`、`:323`、`:329`–`:369`）。
- 最終集計（判断役）: must-fix 3件／should-fix 21件／leave-as-is 11件（`:602`–`:604`）。敵対役反論の採否＝全面採用（撤回）4件ほか（`:608`–`:611`）。must-fix 帰属＝evaluation固有2件・他spec波及1件（A-7）・要件差し戻し0件（`:615`–`:624`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。
- やり直し: 該当記述なし。
- 判定: 「must-fix 3件は設計ゲート通過の阻害要因。いずれも設計文書の追記で対応可能、要件の書き直しや構造変更は不要」（`:630`）。
- 見落とし事例: 主役の事実誤認・過剰解釈（P-2/P-10/P-11 撤回相当）を敵対役・判断役が実物確認で否定（`:373`、`:453`）。主役が AC 単位の網羅（A-1〜A-7）を取りこぼし（`:373`）。

### 3.3 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- 指摘件数: 合計9件（F-1〜F-9）。致命0／重要3（F-2,F-4,F-9）／軽微6（`:265`–`:268`）。
- 差し戻し区分（A/B/C/D）: 件数内訳は該当記述なし。handback 定義参照（`:224`）と F-9 推奨対応内に割当例（`:233`）。他spec波及＝B群相当の記述（`:250`）。
- やり直し（reopen）: 該当記述なし。reopen 種別判定の起点が tasks.md に無い旨を指摘（`:231`）。
- 判定: 「致命0件、tasks.md の骨格は妥当」「横断ゲート前に重要3件の must-fix 適用が望ましい」（`:296`、`:297`、`:299`）。
- 見落とし事例: 前段で省略した正規レビューの正規実施（`:6`）。重要3件は sibling（runtime）が備える要素の欠落＝非対称（`:297`）。

### 3.4 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-19.md`

- 位置付け: 旧 v1 対象（実装作業日2026-05-13が仕様再承認・runtime 再実装より前、`:177`）。
- 指摘件数: finding 10件。`conformance_findings_count`: 10（P1=4／P2=5／P3=1）（`:161`）。severity_weighted 23（`:162`）。
- 差し戻し区分（A/B/C/D）: A=10／B=0／C=0／D=0（`:178`、各 Finding `:56`–`:155`、`:174`）。
- やり直し（reopen）: 連携不要（`:174`、`:175`）。スクラッチ再実装が妥当と推奨（`:179`）。
- 判定: 「現行承認仕様および runtime 新契約へ未適合（GO 不可・要手戻り）。設計差し戻し不要、スクラッチ再実装＋runtime 実体出力形 fixture での TDD 先行を推奨」（`:177`、`:179`、`:191`）。
- 見落とし事例: fixture が非 runtime 形に手作りされ smoke は緑だが実 runtime 連携で破綻する隠れ非適合（Finding 1 `:54`、Finding 2 `:65`）。決定的検証の不在が根因（Finding 3 `:76`）。silent 空集合化（Finding 4 `:86`）。post_smoke_nonconformance_count 4（`:163`）、fixture_bound_resolution_count 2（`:164`）。
- 再実装: コミット `9b586932`（評価スクラッチ再実装：全9タスクをTDDで再構築）。

### 3.5 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-19-postrebuild.md`

- 指摘件数: 新規 finding 1件。`conformance_findings_count`: 1（P1=0／P2=1／P3=0）（`:73`）。severity_weighted 2（`:74`）。
- 差し戻し区分（A/B/C/D）: A=1／B=0／C=0／D=0（`:90`、`:67`、`:86`）。
- やり直し（reopen）: reopen 不要。前回 finding 10件（致命4/重要5/軽微1、全件A）について、§6 個別判定では9件「解消」・前回 Finding 9 は「部分解消（残置 finding 1 として再起票）」（`:97`–`:106`）。【原文内部の表現差・要注記】結論部 `:89` は「全10件解消を独立確認」と記し、総括 `:110` は「9件は完全解消、1件（前回 Finding 9）は orchestrator 経路で解消・standalone 経路に系統的残置」と記す。前回 Finding 9 が新規 Finding 1 に再起票（`:105`、`:112`）。解釈を加えず事実として両表現を併記。
- 判定: 「現行承認仕様および runtime 新契約へ構造適合（GO 可・条件付き）。残1 finding は本ブランチ内 task-local 修正で吸収。設計差し戻し不要・reopen 不要」（`:89`、`:91`、`:112`）。
- 見落とし事例: スクラッチ方針が writer 3件で徹底されず旧 v1 残置（orchestrator/テストでは緑だが standalone で破綻、点検で捕捉）（`:65`、`:75`）。前回 finding 1/2 の fixture 仮装は解消（`:76`）。
- その他定量: tests/evaluation 10ファイル 123 runs / 622 assertions / 0 failures（`:47`）。

---

## 4. dual-reviewer-self-improvement（自己改善）

### 4.1 要件 個別レビュー — `requirements-local-review-2026-05-16.md`

- 指摘件数: 主役合計18件（CRITICAL0／ERROR7／WARN11）（`:159`–`:162`）、敵対役独立7件（A-1〜A-7）。
- 最終集計（判断役）: must-fix 4件／should-fix 11件／leave-as-is 9件（`:371`–`:373`）。帰属＝4件すべて self-improvement 固有（`:386`）。
- 差し戻し区分（A/B/C/D）・やり直し・見落とし・§4 metric snapshot: 該当記述なし。
- 判定: GO/NG の総括語なし。敵対役総括「主役は ERROR を過大報告している」（`:311`）。

### 4.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- 指摘件数: 主役13件（P-1〜P-13）、敵対役独立13件（A-1〜A-13）（`:177`–`:189`、`:246`–`:306`）。
- 最終集計（判断役）: must-fix 6件／should-fix 7件／leave-as-is 13件（`:501`–`:503`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。要件への差し戻し「なし」、他spec設計波及「なし」（`:518`–`:523`）。
- やり直し: 該当記述なし。
- 判定: GO/NG 総括語なし。判定基準は `:327`–`:329`。敵対役の最重要は A-1（traceability 表から要件7・8 が丸ごと欠落）（`:317`）。
- 見落とし事例: 主役の見落とし箇所を敵対役が複数独立検出（`:249` ほか `:254`/`:259`/`:264`/`:269`/`:274`/`:284`/`:289`/`:309`）。レビュー工程内の検出で関門すり抜けではない。

### 4.3 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- 指摘件数: 合計9件。致命0／重要4（T2-A,T3-A,T5-A,T6-A）／軽微5（`:260`–`:263`）。自動採択7件／利用者判断2件（`:267`–`:268`）。
- 差し戻し区分（A/B/C/D）: 件数内訳は該当記述なし。観点6で handback class に言及し推奨対応内に割当例（`:212`）。他spec修正波及＝runtime 2件・他4spec波及なし（`:292`–`:293`）。
- やり直し: 該当記述なし。
- 判定: GO/NG 総括語なし。横断ゲート進行可否の推奨（`:301`）。
- 見落とし事例: 前半で機能個別タスクレビューを省略した工程不遵守の正規補完（`:5`、`:299`）。暗黙の越境義務付与（T5-A `:183`）。

### 4.4 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-19.md`

- 位置付け: 旧 v1 対象。
- 指摘件数: finding 3件。`conformance_findings_count`: 3（P1=3／P2=0／P3=0）（`:94`）。severity_weighted 9（`:95`）。
- 差し戻し区分（A/B/C/D）: A=3／B=0／C=0／D=0（`:111`、各 Finding `:64` `:76` `:88`）。
- やり直し（reopen）: 不要（`:107`、`:112`）。スクラッチ再実装を推奨（`:112`、`:127`）。
- 判定: 「GO 不可。要手戻り（スクラッチ再実装推奨）。設計差し戻し不要（B/C/D ゼロ）」（`:112`、`:127`）。smoke は FAIL（`:43`）。
- 見落とし事例: invalid-run 学習の中核 enrichment が現行契約下で silent に消える隠れ非適合（`:74`、`:96`）。旧コミット済み proposal が削除・置換＝consume-contract drift の機能的傍証（`:50`）。
- 再実装: コミット `3b71fb3c`（自己改善スクラッチ再実装：全9タスクをTDDで再構築）。

### 4.5 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-19-postrebuild.md`

- 指摘件数: 新規 finding 0件（致命0／重要0／軽微0）。`conformance_findings_count`: 0（`:64`、`:70`）。severity_weighted 0（`:71`）。
- 差し戻し区分（A/B/C/D）: A=0／B=0／C=0／D=0（finding ゼロ）（`:86`）。
- やり直し（reopen）: 不要（`:82`、`:83`）。前回 finding 3件（致命3、全件A）を「全3件解消を独立確認」、新規ゼロ（`:85`、§6 `:93`–`:95`）。
- 判定: 「現行承認仕様および runtime／evaluation 新契約へ構造適合（GO 可）。前回 finding 3件は全件解消。新規 finding ゼロ。設計差し戻し不要・reopen 不要。前回 GO 不可・スクラッチ再実装推奨は妥当な判断であった」（`:87`、`:101`）。smoke は PASS（`:50`）。
- 見落とし事例: 前回の「fixture 仮装による smoke 緑」「smoke 構造的 FAIL」構造は解消（`:72`、`:85`）。本ファイル時点の新規すり抜け記述なし。
- その他定量: tests/self_improvement 10ファイル 131 runs / 996 assertions / 0 failures（`:49`）。旧 v1（15モジュール＋10エントリ）を git rm し 8モジュール＋6エントリ＋10テストへ全面置換（`:99`）。

---

## 5. dual-reviewer-paper-interface（論文インターフェース）

### 5.1 要件 個別レビュー — `requirements-local-review-2026-05-16.md`

- 指摘件数: 主役11件（CRITICAL1／ERROR4／WARN6／INFO0）（`:110`–`:113`）、敵対役独立5件（A-1〜A-5）。実効件数は重複除去で must-fix3＋should-fix6＝9件（`:375`）。
- 最終集計（判断役）: must-fix 3件／should-fix 6件／leave-as-is 6件（`:356`–`:358`）。
- 差し戻し区分（A/B/C/D）・やり直し・§4 metric snapshot: 該当記述なし。
- 判定: GO/fail 総括語なし（must-fix3＋should-fix6 の対処必要9件で締め `:375`）。
- 見落とし事例: 主役が内部矛盾（A-1）と語彙断片化（A-3）の ERROR 級構造欠陥を見落とし、検出の網羅性に穴（`:200`）。主役の二重計上（`:155`）。

### 5.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- 指摘件数: 主役13件（P-1〜P-13）、敵対役独立6件（A-1〜A-6）（`:41`–`:171`、`:269`–`:299`）。
- 最終集計（判断役）: must-fix 9件／should-fix 7件／leave-as-is 2件（`:472`–`:479`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。要件への差し戻し「なし」（`:500`–`:502`）。
- やり直し（reopen）: 「must-fix 全件の解消後に再レビューを要する」（`:510`）＝reopen に相当する再レビュー要求。
- 判定: 総合ゲート判定「設計整合ゲート：不通過。must-fix 9件のうち P-1+A-1（要件1件分の全面欠落）と P-5（自称準拠と実体の矛盾）は構造的問題で局所修正では吸収しきれない」（`:506`–`:510`）。
- 見落とし事例: Requirement 6 が設計から全面欠落、traceability 表に行なし（`:43`）。設計が準拠を自称しつつ実体が違反（`:235`、`:356`）。主役がラウンド8を「該当なし」とし依存先スキーマ版固定欠落を未計上（`:301`）。

### 5.3 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- 指摘件数: 合計7件。致命0／重要3（P2-A,P3-A,P6-A）／軽微4（`:264`–`:267`）。自動採択7件／利用者判断0件（`:271`–`:272`）。他5spec修正波及0件（`:294`）。
- 差し戻し区分（A/B/C/D）: paper-interface 自体は §5.2 巻き戻し単位小節を欠き件数集計なし（`:216`）。sibling 3spec の §5.2 handback 紐付けを参照（`:215`）、推奨割当例（`:220`）。
- やり直し: 該当記述なし。reopen 種別判定の起点が tasks.md に無い旨（`:220`）。
- 判定: 「致命所見0件、骨格は妥当」「横断ゲート前に重要3件（sibling 非対称の3点）の must-fix 適用を推奨」（`:301`、`:304`）。
- 見落とし事例: 前半で省略した正規タスク個別レビューの正規実施（`:6`）。重要3件は sibling 3spec が備える要素を単独で欠く同型非対称＝横断ゲートで再検出される片肺（`:302`）。

### 5.4 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-19.md`

- 位置付け: 旧 v1 対象（実装作業日2026-05-13、`:181`）。reviewed commit `8f524f45…`。
- 指摘件数: finding 10件。`conformance_findings_count`: 10（P1=6／P2=3／P3=1）（`:165`）。severity_weighted 25（`:166`）。
- 差し戻し区分（A/B/C/D）: A=10／B=0／C=0／D=0（`:182`、各 Finding `:60`–`:159`、`:178`）。
- やり直し（reopen）: reopen-design/requirements/intent 該当なし（`:178`）。スクラッチ再実装が妥当と推奨（`:183`、`:196`）。
- 判定: 「現行承認仕様および evaluation/self-improvement/foundation 新契約へ未適合（GO 不可・要手戻り）。設計差し戻し不要、スクラッチ再実装＋新実体出力形 fixture での TDD 先行を推奨」（`:181`、`:183`、`:196`）。
- 見落とし事例: smoke が起動例外で非機能のため不適合が隠れた（`:44`、`:58`、`:167`）。決定的検証の不在が他 finding 未検出の根因（Finding 5 `:102`）。post_smoke_nonconformance_count 10、fixture_bound_resolution_count 0、heuristic_linkage_count 1（`:167`–`:169`）。
- 再実装: コミット `d7eddf7c`（論文インターフェース スクラッチ再実装：全Task1〜9をTDDで再構築、旧v1破棄）、`9766febb`（適合レビュー証跡＋波0評価実出力 fixture 版固定）。

### 5.5 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-19-postrebuild.md`

- reviewed commit `9766febb`（`:6`）。
- 指摘件数: 新規 finding 0件（`:61`）。`conformance_findings_count`: 0（P1=0／P2=0／P3=0）（`:70`）。severity_weighted 0（`:71`）。非 finding の観察2件（`:65`–`:66`）。
- 差し戻し区分（A/B/C/D）: 新規 A/B/C/D いずれもゼロ（`:86`、`:82`）。前回分は handback A=10（`:83`、`:106`）。
- やり直し（reopen）: 不要。前回 finding 10件（P1=6/P2=3/P3=1、全件A）を「全10件解消を独立確認」、前回各 F1〜F10 個別に「解消」（`:85`、`:104`–`:106`、§6 `:93`–`:102`）。新規ゼロ。
- 判定: 「現行承認仕様および evaluation 新契約・foundation 語彙へ構造適合（GO 可）。前回 finding 10件は全10件解消。新規 finding ゼロ。設計差し戻し不要・reopen 不要。前回の要手戻り判断は妥当」（`:85`、`:87`、`:121`）。
- 見落とし事例: 前回の「旧 fixture が新契約を仮装し決定的検証不在で不適合が露呈しない」構造の解消を記述（`:85`、`:106`）。本レビュー時点の新規すり抜けなし（`:63`、`:72`）。
- その他定量: tests/paper_interface 8ファイル 59 runs / 401 assertions / 0 failures（`:49`）。実装者申告と完全一致を独立確認（`:49`）。

---

## 6. dual-reviewer-implementation-governance（統治）

### 6.1 要件 個別レビュー（初版）— `requirements-local-review-2026-05-13.md`

- 指摘件数: 主役発見13件（`:9`）、敵対役 反論3件＋独立発見8件（`:148`）。重大度＝CRITICAL（P-1/P-2/P-3/A-1の4件）ほか ERROR/WARN/INFO（`:11`–`:247`）。
- 最終集計（記録語）: must-fix 2件（P-2,P-4）／should-fix 10件／leave-as-is 12件（`:259`–`:261`）。governance 固有 must-fix 0件、foundation 修正必要 must-fix 2件（`:265`–`:269`）。
- 差し戻し区分（A/B/C/D）・やり直し・見落とし・§4 metric snapshot: 該当記述なし。

### 6.2 要件 個別レビュー（Requirement 9 版）— `requirements-local-review-2026-05-18.md`

- 対象: requirements.md の Requirement 9「Workflow Execution Ledger and Compliance Enforcement」受入1〜9（`:5`）＝強制関数の要件。
- 指摘件数: 致命2（F3-1,F4-1）／重要4（F1-1,F2-1,F2-2,F3-2）／軽微4（`:168`–`:170`）。must-fix 候補一覧7項目（`:172`–`:180`）。
- やり直し（reopen）: 統治 spec requirements は spec.json 上 `approved: false`（reopened）、本レビューは承認前精査（`:153`）。Requirement 9 自体が新規導入（`:1`、`:50`）。
- 判定: 「enforcement の機序が成立するための核心条件に致命級の欠落が2件ある（F3-1, F4-1）」（`:160`）。他6spec への暗黙契約変更0件（`:184`）。
- 見落とし事例: 「注意喚起型対策（1行出すだけ）では機序が止まらなかった」のが Requirement 9 の存在理由（`:68`）。背景の不遵守は「機序を無言で省略」したもの（`:92`）。
- 差し戻し区分（A/B/C/D）・§4 metric snapshot: 該当記述なし。

### 6.3 設計 個別レビュー（初版）— `design-local-review-2026-05-16.md`

- 指摘件数（主役）: ERROR 5件／WARN 8件／INFO 0件（`:141`–`:145`）。敵対役独立5件（A-1〜A-5）。
- 最終集計（判断役）: must-fix 4件（P-1,P-8,A-1,A-3）／should-fix 11件／leave-as-is 3件（`:340`–`:342`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。要件差し戻し0件、他spec設計波及0件（`:355`–`:359`）。
- やり直し: 該当記述なし（Req9 未登場、Req1〜8 対象）。
- 判定: GO/fail 単語なし。4件すべて governance 設計固有（`:348`）。

### 6.4 設計 個別レビュー（Requirement 9 設計節版）— `design-local-review-2026-05-18.md`

- 対象: design.md「Workflow Execution Ledger and Enforcement Model」節全体（`:5`）。
- 指摘件数: 致命2（D5-1,D6-1）／重要8（D9-1・D10-1 含む、`:225` 注で確定）／軽微3（`:220`–`:225`）。must-fix 候補一覧11項目（`:227`–`:239`）。
- やり直し（reopen）: 自己ブートストラップ（本契約を導入する design/tasks フェーズ自体への適用可否）の論点（`:212`–`:213`）。
- 判定: 「設計人間承認に進める前に must-fix 適用が必要（致命2件は承認前必須、重要8件も設計段で閉じるのが相当）」（`:253`）。他spec波及検出せず（`:254`）。
- 見落とし事例: 本要件の reopen 起点＝「タスクフェーズ wave のフェーズ内レビュー段を無言圧縮、整合ゲートを独立実施せず＝検査を呼ばずに前進」（`:144`、`:121`）。
- 差し戻し区分（A/B/C/D）・§4 metric snapshot: 該当記述なし。

### 6.5 設計 逆方向トレース監査 — `design-reverse-trace-audit-2026-05-18.md`

- 監査種別: 設計→要件の逆方向トレース（孤児・陳腐・矛盾の検出）（`:4`）。
- 結果: 総数26単位。traceable 26/26、orphan（孤児）0件、stale/conflict 1件（軽微 S-1）（`:33`、`:78`–`:80`）。削除済み要件なし（`:17`）。
- 判定: 「本逆方向監査の観点では design.md は健全。S-1 は任意改善、設計差し戻しは不要」（`:101`–`:102`）。
- 見落とし事例（記録の性質上重要）: 「孤児なし」を明示記録（後で見落とし誤認されないため）（`:82`、`:100`）。
- 差し戻し区分（A/B/C/D）: 該当記述なし。

### 6.6 タスク 個別レビュー（Requirement 9 タスク差分版）— `tasks-local-review-2026-05-18.md`

- 対象: tasks.md Task 11〜18 ＋ Requirement 9 完了条件1行（`:6`）。
- 指摘件数: 致命0／重要0／軽微4（F-1〜F-4）。must-fix（重要以上）0件（`:192`–`:194`、`:206`）。他6spec波及0件（`:197`）。
- 判定: 「must-fix（重要以上）0件のため、タスク横断整合ゲート→人間承認へ進めてよい」（`:213`）。
- 差し戻し区分（A/B/C/D）・やり直し・§4 metric snapshot: 該当記述なし（WORKFLOW_OVERVIEW handback class への言及 `:180`）。

### 6.7 タスク 個別レビュー（Task 1〜10 正規補完版）— `tasks-local-review-task1-10-2026-05-18.md`

- 対象: tasks.md Task 1〜10 ほか Requirement 1〜8 該当部（`:6`）。
- 指摘件数: 致命0／重要1（T3-GOV）／軽微2（F-2,T6-GOV）（`:240`–`:242`）。must-fix（重要以上）1件（T3-GOV、自動採択）（`:254`）。他5spec波及0件（`:238`–`:246`）。
- 判定: 「must-fix は T3-GOV 1件のみだが自動採択。タスク横断整合ゲートへ進めるのが妥当」（`:260`）。
- 見落とし事例（関門すり抜けの明示）: Req9 タスクレビュー（Task 11〜18 範囲）は Task 1〜10 を含む全体18件に対する「節5＝10件超は依存グラフ別表が必須」の明示違反・sibling 非対称を正面評価しておらず、本レビュー（Task 1〜10 正規補完）で初めて正面評価する論点（`:121`、`:259`）。
- 差し戻し区分（A/B/C/D）: T6-GOV 推奨対応に handback A/C 紐付けの記述（`:206`）。件数内訳なし。

### 6.8 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-19.md`

- reviewed commit `81dfee1c…`（`:6`）。出典コミット `0edcfb31`（統治中核 部分修正：finding6件をTDD解消）。
- 指摘件数: finding 6件。`conformance_findings_count`: 6（P1=2／P2=2／P3=2）（`:123`）。severity_weighted 12（`:124`）。
- 差し戻し区分（A/B/C/D）: A=5／B候補=1（Finding 4、利用者判断で A 吸収可）／C=0／D=0（`:139`、`:142`、各 Finding `:62`–`:117`）。
- やり直し（reopen）: Finding 4 の disposition が `reopen-design` 候補（利用者判断で A 吸収なら fix-in-current-branch）（`:97`、`:136`）。
- 判定: 「Requirement 9 強制関数は実 artifact 上で実効的に未稼働。要手戻り（GO 不可）。スクラッチ全面再実装は不要、部分修正で足りる」（`:141`、`:143`、`:162`）。
  - 注: 統治は他5機能と異なりスクラッチ再実装でなく部分修正の方針（コミット名 `0edcfb31`「部分修正」と一致）。論文化方針§2 の「統治のフルスクラッチ再実装は廃案、監査で意図適合判定」とも整合。
- 見落とし事例（重要）: Requirement 9 の全テストが tmpdir に手製の権威文書を仮装し実 artifact を一度も検証しない＝実 artifact 上の P1級不適合3件（Finding 1/3/5）が緑のテストの裏で全て見逃された（Finding 2 `:68`、`:71`、`:74`）。post_smoke_nonconformance_count 6、fixture_bound_resolution_count 6（`:125`–`:126`）。
- その他定量: tests/governance 6ファイル 40 runs / 104 assertions / 0 failures（`:45`、全緑だが全て tmpdir 仮装 fixture 上 `:125`）。

### 6.9 実装適合レビュー（再実装後／部分修正後）— `implementation-conformance-review-2026-05-19-postrebuild.md`

- 位置付け: 「6機能の実装適合フェーズの最後の機能の最終ゲート」（`:7`）。reviewed commit `81dfee1c…`（部分修正は本コミット基底の作業ツリーに未コミットで存在、`:6`）。
- 指摘件数: 新規 finding 0件（`:59`）。`conformance_findings_count`: 0（P1=0／P2=0／P3=0）（`:69`）。severity_weighted 0（`:70`）。非 finding の観察3件（`:63`–`:65`）。
- 差し戻し区分（A/B/C/D）: 新規 A/B/C/D いずれもゼロ。前回 A=5＋B候補1 を本部分修正で全件解消（B候補は A 吸収で design 不変）（`:87`、`:82`、`:83`）。
- やり直し（reopen）: 不要。前回 Finding 4 の reopen-design 候補は利用者判断で A 吸収（authority-map 4列化＋パーサ追従）が選択され design 小節1.2 不変のまま解消＝reopen 不発（`:82`、`:83`）。前回6件全件解消を独立確認（`:90`–`:103`）。
- 判定: 「現行承認仕様へ適合（GO 可）。前回 finding 6件（P1=2/P2=2/P3=2、handback A=5＋B候補1）は全6件解消を独立確認。新規 finding ゼロ。設計差し戻し不要・reopen 不要。これにて6機能の実装適合フェーズの最後の機能が GO 可」（`:88`、`:121`）。
- 見落とし事例: 前回「緑テストの裏で P1級不適合3件を見逃す仮装世界検証」の構造が解消（`:95`）。実 artifact 上で強制関数が pass 到達可能であることを自分で再実行し実証（`:52`）。
- その他定量: tests/governance 7ファイル 45 runs / 137 assertions / 0 failures（新設 real-artifacts 5/33 を加算）（`:49`）。

---

## 7. 観察と解釈（人間承認前の素材・事実ではない）

本節は §1〜§6 の事実から読み取れる傾向の説明であり、論文1の主張ではない。骨子・主張は人間承認後に確定する（論文化方針§4「信頼の作法」）。

- 観察A（差し戻しの深さの分布）: 6機能の実装適合レビューで記録された差し戻し区分は、A（その作業内で吸収）と B（設計まで戻す）に集中し、C（要件）・D（意図）は全機能でゼロ。設計まで戻った（B）のは基盤（B=1、Finding 8）と実行系（B=4、Finding 2/5/6/9）と統治（B候補=1、A 吸収で消化）に限られる。これは「要件・意図は概ね妥当で、乖離の多くは実装側の旧仕様残存」とレビュー記録が繰り返し述べる構造と対応する（各機能の総括行を参照）。
- 観察B（再実装前→後の解消）: 評価・自己改善・論文インターフェースは再実装前レビューで「GO 不可・要手戻り」となり、スクラッチ再実装後の独立レビューで前回 finding が全件（または1件部分残置）解消・新規ほぼゼロに収束。実行系も同型（前回11件→再実装後 新規3件 P3/A）。統治のみ部分修正で前回6件解消・新規ゼロ。基盤は再実装後の独立適合レビュー（§1.6、2026-05-20補完）で前回9件すべて解消・新規1件（P3/A）。
- 観察C（見落としの捕捉点）: 「指示違反・仕様逸脱が前段の関門を素通りし後段で初めて捕まった」型の記録が複数機能にある。代表は (1) fixture を手製で仮装し smoke が緑になる構造が実連携・点検で破綻（評価・論文・統治の再実装前）、(2) tasks-approved まで回帰基盤が無く破綻が静的検出されなかった（実行系 Finding 11）、(3) Req9 タスクレビューが Task 1〜10 を含む全体の節5違反を正面評価せず後続の正規補完で初出論点化（統治）。これらは論文化方針§2 末尾「フルスクラッチ指示違反が全関門をすり抜け対話・点検で初めて捕まった見落とし」に相当する素材。
- 観察D（記録の様式上の限界）: 差し戻し区分（A/B/C/D）の件数と §4 metric snapshot は実装適合レビューにのみ存在し、要件・設計・タスクの個別レビューは must-fix/should-fix/leave-as-is で集計される。フェーズ横断で同一指標による定量比較はできない（フェーズで記録語が異なる）。これは限界として論文に明記すべき素材（論文化方針§4「限界・脅威を明記」）。
- 原文内部の不整合（事実として記録、解釈なし）:
  - 実行系 再実装前 `implementation-conformance-review-2026-05-18.md:194` 本文「A=5件」は同行括弧内列挙7件・disposition summary・git `bea2dbeb`・後続レビューと不一致。正は A7/B4。
  - 評価 再実装後 `…-postrebuild.md` の結論部 `:89`「全10件解消」と総括 `:110`「9件完全解消・1件部分解消（前回 Finding 9 を新規 Finding 1 に再起票）」は表現が一致しない。両表現を併記済み（§3.5）。

---

## 8. 次工程

- 本文書を論文1の証拠土台とし、論文1 証拠地図・骨子（章節と各主張→証拠の対応）を作成 → 人間承認 → 本文（8ページ日本語）→ 5/29 初回投稿（今後の計画§3）。
- 骨子・主張の確定、コミット／プッシュ、spec.json 書込、フェーズ移行は明示承認を維持する。
