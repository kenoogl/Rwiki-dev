# 有効レビュー記録 出典付き構造化抽出 v2（D-C 再抽出）

_作成日: 2026-05-21_
_位置付け: 論文1（SES2026 実践論文）の証拠土台 v2。v1（evidence-extract-2026-05-20.md）の構造的問題を補正し、全レビュー段で「段内吸収（absorption）／上位 handback／他機能波及」の3次元で集計し直したもの_
_前版: `evidence-extract-2026-05-20.md`（v1）。v1 は実装適合段の A／B／C／D のみを集計しており、要件・設計・タスク段の同型構造を可視化していなかった_
_対の正本: 同ディレクトリ `paperization-policy-2026-05-20.md`／`overall-plan-2026-05-20.md`／`paper1-outline-2026-05-20.md`_

---

## 0. この文書の規律と読み方

- 各定量値には出典を併記する。出典は「ファイル相対パス:行番号」または「コミットの短縮ハッシュ」。出典に辿れない値は載せない。
- 事実（記録に書かれていること）と、解釈（記録から読み取れる傾向の説明）を節で明示的に分ける。§1〜§6 は事実、§7 は観察と解釈で人間承認前の素材である。
- 対象範囲：6機能の `dual-reviewer-rebuild/.kiro/specs/dual-reviewer-{foundation,runtime,evaluation,self-improvement,paper-interface,implementation-governance}/reviews/*.md`（計36ファイル）＋ git コミット。除外＝`experiments/protocols/_archived-2026-05-13/` 配下の汚染・退避データ。
- パス略記：以下、各機能節のレビュー記録は `…/.kiro/specs/dual-reviewer-<機能>/reviews/<ファイル名>` を `<ファイル名>` と略記する。

### 0.1 記録様式に関する事実（v1 から引き継ぎ）

- 差し戻し区分（A／B／C／D）の件数内訳が記録されているのは実装適合レビュー（implementation-conformance）のファイルのみ。要件・設計・タスクの各個別レビューは must-fix／should-fix／leave-as-is で集計し、A／B／C／D は使わない。
- 「§4 metric snapshot」という構造化定量節（conformance_findings_count、severity_weighted_finding_score、post_smoke_nonconformance_count 等）を持つのも実装適合レビューのみ。
- 重み付けスコア（severity_weighted_finding_score）の重みは P1=3／P2=2／P3=1。foundation 適合レビューは「重み付け尺度は foundation で未確定（design §4 で deferred）のため暫定」と注記している（`implementation-conformance-review-2026-05-18.md:133`）。

### 0.2 3次元の操作的定義（v2 の核心）

本抽出は、6機能×各レビュー段ごとに以下の3次元を集計する。原典の集計節と帰属別分類節に明示された数値を用いる。読み取り規約は次のとおり。

- **段内吸収（absorption）**：その段の成果物（要件書／設計書／タスク書／実装）に編集を加えることで解消する所見の件数。
  - 要件・設計・タスク段：must-fix と should-fix の合計を「修正適用による段内吸収」、leave-as-is を「記録のみの段内吸収」として併記。
  - 実装適合段：handback 区分 A（task-local／fix-in-current-branch）の件数。
- **上位 handback**：上位フェーズへ差し戻された所見の件数と差し戻し先。
  - 要件・設計・タスク段：原典の「帰属別分類」節に「要件への差し戻し」「他 spec 設計への波及」等として明示された件数。
  - 実装適合段：handback 区分 B（reopen-design）、C（reopen-requirements）、D（reopen-intent）の件数。
- **他機能波及**：他 spec（foundation／runtime／evaluation／self-improvement／paper-interface／implementation-governance のうち本機能以外）の成果物に修正を要求した所見の件数。
  - 「他5spec修正波及」「他6spec波及」「foundation 帰属」等の表現で原典に記録されたものを集計する。
  - 「記録のみ波及」（実体修正不要・横断議題への申し送り）は別途併記する。

なお、要件・設計・タスク段の must-fix／should-fix の帰属が他機能側にある場合（例：runtime 要件レビューの must-fix のうち foundation 修正必要分）、その件数を「他機能波及」に算入し、段内吸収には算入しない。これは原典の「帰属別分類」節の集計に沿う処理である。

### 0.3 implementation の「タスクへの handback」記号欠落（次々セッションの宿題）

実装適合レビューの原典は handback 区分を A（task-local／fix-in-current-branch）／B（reopen-design）／C（reopen-requirements）／D（reopen-intent）の4種で記録している。タスク段への差し戻し（仮に I-1 と呼ぶ区分）に相当する記号は元ログに存在しない。本論文§5（限界）に「タスク段への差し戻し記号が欠落し、実装で発生した所見をタスク差分でなく実装側で吸収するか設計に戻すかの二択に圧縮していた」と明記する素材とする。

実態としては、実装適合レビューが「タスク差分の追記で解決可能」と判断したものはすべて A（task-local）に分類されている。タスク書自体の改版を要した事例はあるが（例：実行系の前回 finding 11＝回帰基盤不在、自己改善の Task 9 決定的テスト不在）、それらも実装の小修正波の中で吸収されており、独立した「I」区分として記号化されていない。次々セッションでの宿題は、(a) 既存 A 群の事例から「タスク書の改版に伴う A」を切り出して再分類するか、(b) 新規 I 区分を追加して以後のレビューで記号化するか、を決定すること。本論文では「記号が欠落していた」事実を限界として記述する。

---

## 1. dual-reviewer-foundation（基盤）

### 1.1 要件 個別レビュー — `requirements-local-review-2026-05-13.md`

- **総件数**：主役発見11件（`:208`）、敵対役独立発見9件（`:300`）。集計（判断役）＝must-fix 6件（うち P-1/A-2 同根で実質5件）、should-fix 8件、leave-as-is 6件（`:369`–`:372`）。
- **段内吸収（absorption）**：
  - 修正適用：must-fix 6件（P-1, P-2, P-3, P-5, A-1, A-2）＋ should-fix 8件 ＝ 14件（すべて foundation 要件書への編集で吸収）。
  - 記録のみ：leave-as-is 6件（P-7, P-10, P-11, A-6, A-8, A-9）。
- **上位 handback**：0件（intent 差し戻し記述なし）。
- **他機能波及**：0件。must-fix・should-fix とも foundation 固有。ただし下流 runtime 要件レビュー（§2.1）で foundation 修正必要 must-fix が7件報告される逆方向の構造があり、これは本レビューの波及でなく下流からの要請として §2.1 に計上する。
- **判定**：「must-fix が6件（実質5件）あるため、要件フェーズをこのまま先に進めるべきではない」（`:374`）。

### 1.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- **総件数**：主役 P-1〜P-21（21件）、敵対役独立 A-1〜A-6（6件）（`:176`）。集計（判断役）＝must-fix 9件、should-fix 11件、leave-as-is 7件（`:398`–`:402`）。
- **段内吸収（absorption）**：
  - 修正適用：must-fix 9件（P-1, P-2, P-8, P-9, P-10, P-20, A-1, A-2, A-5）＋ should-fix 11件 ＝ 20件（すべて foundation 設計固有として設計書への追記で吸収）。
  - 記録のみ：leave-as-is 7件。
- **上位 handback**：要件への差し戻し 0件（`:420`–`:422`）。
- **他機能波及**：0件と明記（`:424`–`:426`）。「9件すべて foundation 設計文書内で完結する修正であり、他 spec の requirements／design を変更する必要はない」。

### 1.3 設計差し戻し 差分レビュー — `design-reopen-review-2026-05-18.md`

- **位置付け**：implementation-conformance Finding 8（手戻り B）に対応する差分設計レビュー（`:1`, `:4`–`:5`）。コミット `a3b2d9ec`。
- **総件数**：所見5件（D1〜D5）。致命0／重要2（D2, D5）／軽微3（`:104`–`:111`）。
- **段内吸収（absorption）**：
  - 修正適用：5件すべて（致命0＋重要2＋軽微3）が foundation 設計差分節への追記で吸収予定。実装手戻りは不要（`:95`）。
- **上位 handback**：0件。
- **他機能波及**：0件。
- **判定**：「要修正（致命0／重要2／軽微3）。D2・D5 を解消しない限り規約が実装の符号化を過不足なく説明する状態に至っていない」（`:117`）。
- **位置付けの特殊性**：本レビュー自体が「§1.5 実装適合レビューからの B 群1件 → reopen-design」の受け皿。すなわち上位段が下位段からの handback を受けて生成された差分レビューであり、3次元集計では「段内吸収のみ」として計上する（受け皿側は上位 handback を新たに発生させない）。

### 1.4 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- **総件数**：致命0／重要0／軽微2件（T-1, T-2）。must-fix 候補なし（`:155`–`:157`, `:179`）。
- **段内吸収（absorption）**：
  - 修正適用：0件（must-fix 候補なし）。
  - 記録のみ：軽微2件（T-1, T-2）。
- **上位 handback**：0件。
- **他機能波及**：0件（他5spec波及 0件と明記、`:169`）。
- **判定**：「タスク横断整合ゲートへ進めてよい。must-fix 適用は不要」（`:182`）。

### 1.5 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-18.md`

- 出典コミット：`1c3af809`（指摘9件・致命5／重要3／軽微1・A8/B1）。
- **総件数**：finding 9件。P1=5／P2=3／P3=1（`:131`、各 Finding 見出し `:30`–`:118`）。severity_weighted 22（`:132`、暫定重み注記 `:133`）。
- **段内吸収（absorption）**：A=8件（Finding 1〜7, 9。`:38` `:49` `:60` `:71` `:82` `:93` `:104` `:126`）。task-local／fix-in-current-branch／fix-before-next-feature で消化される所見群。
- **上位 handback**：
  - B=1件：Finding 8 → reopen-design（`:115`, `:144`, `:148`）。受け皿は §1.3。
  - C=0、D=0。
- **他機能波及**：0件。
- **判定**：「既存コードの現行仕様適合度: 低い」（`:146`）。後続の対応として基盤スクラッチ再実装（コミット `c4928ff3`）。

### 1.6 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-20-postrebuild.md`

- 追補日：2026-05-20（本論文骨子レビューを受けて欠損補完）。reviewed commit `cea191b8` 時点（基盤再実装は `c4928ff3` で完了済み）。
- **総件数**：新規 finding 1件。P1=0／P2=0／P3=1（`:78`）。severity_weighted 1（`:79`）。
- **段内吸収（absorption）**：A=1件（新規 P3、Finding 1＝`finding.schema.json` トップレベル `x-deferred` 注記欠落、`:66`）。
- **上位 handback**：B=0、C=0、D=0（`:88`–`:92`, `:94`）。
- **他機能波及**：0件。
- **判定**：「基盤再実装は承認仕様に構造適合（GO 可）。残1 finding は task-local cleanup で吸収（reopen 不要）」（`:97`）。前回9件すべて解消を独立確認（`:141`）。

---

## 2. dual-reviewer-runtime（実行系）

### 2.1 要件 個別レビュー — `requirements-local-review-2026-05-13.md`

- **総件数**：主役発見10件（`:9`）、敵対役 反論3件＋独立発見12件（`:120`）。集計（判断役）＝must-fix 9件、should-fix 12件、leave-as-is 4件（`:277`–`:279`）。
- **段内吸収（absorption）**：
  - 修正適用：runtime 固有 must-fix 2件（P-5, A-6）＋ runtime 固有 should-fix（原典に件数明示なし）＝最小2件。
  - 記録のみ：leave-as-is 4件。
- **上位 handback**：0件。
- **他機能波及**：foundation 修正必要 must-fix 7件（P-1, P-2, P-4, A-1, A-2, A-3, A-7＝P-5 と統合）（`:283`, `:291`）。すべて foundation 要件への波及。
  - 内訳：P-1＝foundation Req 7 AC1 から「pattern assets」削除、P-2＝foundation Req 1 に Step D contract、P-4＝foundation Req 1 AC5／Req 6 AC2 包含明示、A-1＝foundation Req 1 AC4 に Step B forced-divergence、A-2＝phase/profile 語彙、A-3＝treatment 語彙、A-7＝統合扱い。
- **判定**：内訳記述（`:282`–`:293`）。これら7件が foundation 要件再開（2026-05-17 受入 10 追加）の起点となった。

### 2.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- **総件数**：主役発見15件（`:184`）、敵対役独立発見8件（`:277`）。集計（判断役）＝must-fix 13件、should-fix 9件、leave-as-is 1件（`:447`–`:456`）。
- **段内吸収（absorption）**：
  - 修正適用：runtime 設計固有 must-fix 10件（P-1, P-3, P-6, P-7, P-10, P-13, P-14, A-1, A-2, A-8。`:471`–`:482`）＋ should-fix 9件 ＝ 19件。
  - 記録のみ：leave-as-is 1件。
- **上位 handback**：
  - 要件への差し戻し 1件（A-4＝foundation 検証状態列挙に `blocked` 欠落、`:484`–`:486`）。foundation 要件への reopen を起こした。
- **他機能波及**：2件（`:488`–`:491`）。
  - A-5：`review_case.json`（foundation 定義の正本）と `review_artifact.json`（v2 内部正本）のフィールド対応規約。foundation 設計および evaluation 設計との整合確認が必要。
  - A-6：ケースマニフェスト詳細の帰属について v2-acquisition spec との境界再画定が必要。

### 2.3 設計差し戻し 差分レビュー — `design-reopen-review-2026-05-18.md`

- **位置付け**：実装適合（再実装前）の reopen-design（Finding 2/5/6/9）を受けた差分設計レビュー（`:1`, `:4`–`:5`）。コミット `5100a6da`（B群4件差し戻し）、`1085b3f1`（差し戻し関門消化）。
- **総件数**：所見5件（DR-1〜DR-5）。致命0／重要2（DR-1, DR-3）／軽微3（`:170`–`:177`）。
- **段内吸収（absorption）**：
  - 修正適用：5件すべて runtime 差分節への追記で吸収（DR-1 は利用者判断要、DR-3 自動採択、軽微3件自動採択）。
- **上位 handback**：0件。
- **他機能波及**：DR-1 で v2-acquisition spec への前方依存問題が論点化（利用者判断、`:172`）。実体修正は v2-acquisition 側ではなく runtime 所有 seam で前方依存を吸収する判断で確定（v1 §2.3 注記と一致）。
- **判定**：「致命級ゼロ。重要2件（DR-1 利用者判断要・DR-3 自動採択可）の解消を条件に設計健全」（`:190`）。スクラッチ再実装方針が結語に明示（`:162`）。

### 2.4 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- **総件数**：合計9件。致命0／重要4（T2-A, T3-A, T3-B, T5-A）／軽微5（`:243`–`:246`）。自動採択7件／利用者判断2件（`:250`–`:251`）。
- **段内吸収（absorption）**：
  - 修正適用：9件すべて runtime tasks.md 内で閉じる（`:281`）。設計書・要件書・spec.json 改版不要。
- **上位 handback**：0件。
- **他機能波及**：修正0件、記録のみ1件（evaluation tasks で T5-A 関連、evaluation 側は既に正しく修正不要、`:275`–`:276`）。
- **判定**：「致命0件。重要4・軽微5はいずれも runtime tasks.md 内で閉じる」（`:281`）。

### 2.5 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-18.md`

- 出典コミット：`bea2dbeb`（指摘11件・致命6／重要3／軽微2・A7/B4）。reviewed commit `a3b2d9ec`（`:12`）。
- **総件数**：finding 11件。P1=6／P2=3／P3=2（`:174`）。severity_weighted 26（`:175`, `:182`）。
- **段内吸収（absorption）**：A=7件（Finding 1, 3, 4, 7, 8, 10, 11）。
  - 注：本文 `:194` は「A=5件」と記すが、同行括弧内に7件を列挙し本文数値と一致しない。確定根拠（複数の独立出典が A7/B4 を支持）：(1) disposition summary（`:187`–`:190`）で reopen-design＝Finding 2/5/6/9（B群4件）、残り7件が非 reopen、(2) §2.3 設計差し戻しが finding 2/5/6/9 を B群4件と明示、(3) git コミット名 `bea2dbeb`「手戻りA7/B4」、(4) 後続 §2.6 が「前回 finding 11件（A7/B4）」と参照（`implementation-conformance-review-2026-05-19.md:133`）。事実として、正は A7/B4、`:194` 本文の「A=5件」は原文の内部記載不整合。
- **上位 handback**：
  - B=4件：Finding 2/5/6/9 → reopen-design（`:188`）。受け皿は §2.3。
  - C=0、D=0。
- **他機能波及**：0件。
- **判定**：「既存 runtime 実装は現行承認仕様に未適合。`initialize_run` 段階で実行不能。スクラッチ再実装相当の是正が必要」（`:193`）。後続対応は実行系スクラッチ再実装（コミット `ef5b6b69`）。

### 2.6 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-19.md`

- reviewed commit `1085b3f1`（`:6`）。
- **総件数**：新規 finding 3件。P1=0／P2=0／P3=3（`:89`）。severity_weighted 3（`:90`）。
- **段内吸収（absorption）**：A=3件（Finding 1〜3、すべて P3、`:107`、各 Finding `:60` `:72` `:84`）。
- **上位 handback**：B=0、C=0、D=0（`:103`）。
- **他機能波及**：0件。
- **判定**：「現行承認仕様（再確定設計を含む）へ構造適合。GO 可」（`:106`, `:108`, `:135`）。前回11件（A7/B4）全件解消を独立確認（`:133`, `:114`–`:129`）。

---

## 3. dual-reviewer-evaluation（評価）

### 3.1 要件 個別レビュー — `requirements-local-review-2026-05-16.md`

- **総件数**：主役所見9件（ERROR4／WARN4／INFO1、`:158`–`:161`）、敵対役独立5件、計14件（`:261`）。集計（判断役）＝must-fix 3件、should-fix 7件、leave-as-is 5件（`:357`–`:359`）。
- **段内吸収（absorption）**：
  - 修正適用：evaluation 固有 must-fix 2件（A-2, A-3＝Req 1／Req 2 AC 追加、`:366`–`:367`）＋ should-fix 7件 ＝ 9件。
  - 記録のみ：leave-as-is 5件。
- **上位 handback**：0件。
- **他機能波及**：foundation 修正1件（P-4＝foundation Req 6 に証跡区分語彙の定義・所有受入基準追加、`:370`）。後の §6.x 段で foundation 要件 6 受入 8 追加に収束。
- **判定**：「設計着手前に must-fix 3件の解消を推奨」（`:379`）。

### 3.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- **総件数**：主役28件（ERROR6／WARN16／INFO6、`:226`–`:253`）、敵対役独立7件（`:323`, `:329`–`:369`）。集計（判断役）＝must-fix 3件、should-fix 21件、leave-as-is 11件（`:602`–`:604`）。
- **段内吸収（absorption）**：
  - 修正適用：evaluation 設計固有 must-fix 2件（P-1, A-2、`:617`–`:618`）＋ should-fix 21件 ＝ 23件。
  - 記録のみ：leave-as-is 11件（うち4件は敵対役反論採用で所見撤回、`:608`）。
- **上位 handback**：要件への差し戻し 0件（`:624`）。
- **他機能波及**：1件（A-7＝`comparison_eligibility_note.json` 等の runtime 副産物のスキーマ所有 spec 宣言。runtime 設計との整合確認、`:620`–`:622`）。後の越境クラスタ決定で「生成元 runtime 所有・評価は依存宣言のみ」と確定。
- **判定**：「must-fix 3件は設計ゲート通過の阻害要因。設計文書の追記で対応可能」（`:630`）。

### 3.3 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- **総件数**：合計9件（F-1〜F-9）。致命0／重要3（F-2, F-4, F-9）／軽微6（`:265`–`:268`）。
- **段内吸収（absorption）**：
  - 修正適用：重要3件＋軽微6件 ＝ 9件すべて evaluation tasks.md 内で閉じる（F-7 のみ後述）。
- **上位 handback**：0件。
- **他機能波及**：1件（F-7＝runtime tasks.md §4 Downstream Handoff の evaluation 行に `decisions/decision_units.json` を追記、`:291`）。tasks alignment gate の双方向同期議題として申し送り。evaluation tasks.md 側の修正は不要。
- **判定**：「致命0件、骨格は妥当」「横断ゲート前に重要3件の must-fix 適用が望ましい」（`:296`–`:297`, `:299`）。

### 3.4 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-19.md`

- 位置付け：旧 v1 対象（実装作業日2026-05-13、仕様再承認・runtime 再実装より前、`:177`）。
- **総件数**：finding 10件。P1=4／P2=5／P3=1（`:161`）。severity_weighted 23（`:162`）。
- **段内吸収（absorption）**：A=10件（`:178`、各 Finding `:56`–`:155`, `:174`）。
- **上位 handback**：B=0、C=0、D=0（`:174`–`:175`）。「reopen-design／requirements／intent 該当なし」。
- **他機能波及**：0件。乖離はすべて評価実装側に限局。
- **判定**：「GO 不可・要手戻り。設計差し戻し不要、スクラッチ再実装＋runtime 実体出力形 fixture での TDD 先行を推奨」（`:177`, `:179`, `:191`）。後続対応は評価スクラッチ再実装（コミット `9b586932`）。

### 3.5 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-19-postrebuild.md`

- **総件数**：新規 finding 1件。P1=0／P2=1／P3=0（`:73`）。severity_weighted 2（`:74`）。
- **段内吸収（absorption）**：A=1件（Finding 1＝旧 v1 残存 writer 3件の mkpath 欠落、`:90`, `:67`, `:86`）。
- **上位 handback**：B=0、C=0、D=0（`:86`）。
- **他機能波及**：0件。
- **判定**：「GO 可・条件付き。残1 finding は本ブランチ内 task-local 修正で吸収」（`:89`, `:91`, `:112`）。前回10件（全件 A）について§6 個別判定では9件「解消」、前回 Finding 9 は「部分解消（残置 finding 1 として再起票）」（`:97`–`:106`）。
- **原文内部の表現差**：結論部 `:89` は「全10件解消を独立確認」と記し、総括 `:110` は「9件は完全解消、1件（前回 Finding 9）は orchestrator 経路で解消・standalone 経路に系統的残置」と記す。前回 Finding 9 が新規 Finding 1 に再起票。事実として両表現を併記する。

---

## 4. dual-reviewer-self-improvement（自己改善）

### 4.1 要件 個別レビュー — `requirements-local-review-2026-05-16.md`

- **総件数**：主役合計18件（CRITICAL0／ERROR7／WARN11、`:159`–`:162`）、敵対役独立7件（A-1〜A-7）。集計（判断役）＝must-fix 4件、should-fix 11件、leave-as-is 9件（`:371`–`:373`）。
- **段内吸収（absorption）**：
  - 修正適用：must-fix 4件（P-2+P-10統合、P-13, A-3, A-7、すべて self-improvement 固有、`:386`）＋ should-fix 11件 ＝ 15件。
  - 記録のみ：leave-as-is 9件。
- **上位 handback**：0件。
- **他機能波及**：0件（`:386`「foundation 修正や他 spec 修正は不要」）。
- **判定**：GO/NG 総括語なし。敵対役総括「主役は ERROR を過大報告している」（v1 §4.1 と整合）。

### 4.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- **総件数**：主役13件（P-1〜P-13）、敵対役独立13件（A-1〜A-13）。集計（判断役）＝must-fix 6件、should-fix 7件、leave-as-is 13件（`:501`–`:503`）。
- **段内吸収（absorption）**：
  - 修正適用：self-improvement 設計固有 must-fix 6件（P-5, P-13, A-1, A-3, A-5, A-13、`:511`–`:516`）＋ should-fix 7件 ＝ 13件。
  - 記録のみ：leave-as-is 13件。
- **上位 handback**：要件への差し戻し 0件（`:520`「要件自体は十分に明確。問題は設計側の応答欠落」）。
- **他機能波及**：0件（v1 §4.2 と一致、`:522`–`:523`）。

### 4.3 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- **総件数**：合計9件。致命0／重要4（T2-A, T3-A, T5-A, T6-A）／軽微5（`:260`–`:263`）。
- **段内吸収（absorption）**：
  - 修正適用：T2-A, T3-A, T6-A の3件＋軽微5件 ＝ 8件（self-improvement tasks.md 内で閉じる）。
- **上位 handback**：0件。
- **他機能波及**：2件（runtime 横断、`:294`）。
  - T5-A：`runtime_validation_summary.schema.json` の横断 owner 未確定＋暗黙の越境義務付与（利用者判断）。alignment 議題として持ち上げ。
  - T5-B：軽微・記録のみ・runtime §4 追記候補（修正必要なし）。
- **判定**：「致命0件・重要4件・軽微5件」「sibling 非対称の3点（T2-A, T3-A, T6-A）と横断 owner（T5-A）の補修後、横断整合ゲートへ」（`:299`–`:301`）。

### 4.4 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-19.md`

- 位置付け：旧 v1 対象。
- **総件数**：finding 3件。P1=3／P2=0／P3=0（`:94`）。severity_weighted 9（`:95`）。
- **段内吸収（absorption）**：A=3件（`:111`、各 Finding `:64` `:76` `:88`）。
- **上位 handback**：B=0、C=0、D=0（`:107`）。
- **他機能波及**：0件。
- **判定**：「GO 不可・要手戻り（スクラッチ再実装推奨）。設計差し戻し不要」（`:112`, `:127`）。smoke は構造的 FAIL（`:43`）。後続対応は自己改善スクラッチ再実装（コミット `3b71fb3c`）。

### 4.5 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-19-postrebuild.md`

- **総件数**：新規 finding 0件（致命0／重要0／軽微0、`:64`, `:70`）。severity_weighted 0（`:71`）。
- **段内吸収（absorption）**：A=0（finding ゼロ、`:86`）。
- **上位 handback**：B=0、C=0、D=0（`:86`）。
- **他機能波及**：0件。
- **判定**：「現行承認仕様および runtime／evaluation 新契約へ構造適合。GO 可。前回 finding 3件は全件解消。新規 finding ゼロ」（`:87`, `:101`）。

---

## 5. dual-reviewer-paper-interface（論文インターフェース）

### 5.1 要件 個別レビュー — `requirements-local-review-2026-05-16.md`

- **総件数**：主役11件（CRITICAL1／ERROR4／WARN6／INFO0、`:110`–`:113`）、敵対役独立5件。集計（判断役）＝must-fix 3件、should-fix 6件、leave-as-is 6件（`:356`–`:358`）。
- **段内吸収（absorption）**：
  - 修正適用：paper-interface 固有 must-fix 2件（P-8, A-1、`:365`–`:366`）＋ should-fix 6件 ＝ 8件。
  - 記録のみ：leave-as-is 6件。
- **上位 handback**：0件。
- **他機能波及**：1件（A-3＝paper-interface 内の3系統の証拠分類語彙を foundation の evidence class フィールドに結合。foundation 側で語彙所有者の明示が必要、`:368`–`:369`）。後の C-2／C-3 上位文書同期に接続。
- **判定**：「must-fix3＋should-fix6＝対処必要9件」（`:375`）。

### 5.2 設計 個別レビュー — `design-local-review-2026-05-16.md`

- **総件数**：主役13件（P-1〜P-13）、敵対役独立6件（A-1〜A-6）。集計（判断役）＝must-fix 9件、should-fix 7件、leave-as-is 2件（`:472`–`:479`）。
- **段内吸収（absorption）**：
  - 修正適用：paper-interface 設計固有 must-fix 8件（P-1+A-1統合, P-3, P-4, P-8, P-12, A-2, A-4, A-5、`:485`–`:494`）＋ should-fix 7件 ＝ 15件。
  - 記録のみ：leave-as-is 2件。
- **上位 handback**：要件への差し戻し 0件（`:502`）。
- **他機能波及**：1件（P-5＝foundation の `valid／invalid／exploratory` と paper-interface の `mature／preliminary／exploratory` の関係明示。foundation 設計への波及か paper-interface 固有か、設計に明記、`:498`）。
- **判定**：「設計整合ゲート：不通過。must-fix 9件のうち P-1+A-1（要件1件分の全面欠落）と P-5（自称準拠と実体の矛盾）は構造的問題で局所修正では吸収しきれない」（`:508`）。

### 5.3 タスク 個別レビュー — `tasks-local-review-2026-05-18.md`

- **総件数**：合計7件。致命0／重要3（P2-A, P3-A, P6-A）／軽微4（`:264`–`:267`）。
- **段内吸収（absorption）**：
  - 修正適用：重要3件＋軽微4件 ＝ 7件すべて paper-interface tasks.md 内で閉じる。
- **上位 handback**：0件。
- **他機能波及**：修正0件（`:294`–`:295`）。記録のみ波及（双方向対称化）evaluation／foundation に1件ずつ言及（P5-A 関連）。
- **判定**：「致命0件、骨格は妥当」「sibling 3 spec が備える要素を paper-interface 単独で欠く同型 sibling 非対称」（`:301`–`:302`）。

### 5.4 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-19.md`

- 位置付け：旧 v1 対象（実装作業日2026-05-13、`:181`）。reviewed commit `8f524f45…`。
- **総件数**：finding 10件。P1=6／P2=3／P3=1（`:165`）。severity_weighted 25（`:166`）。
- **段内吸収（absorption）**：A=10件（`:182`、各 Finding `:60`–`:159`, `:178`）。
- **上位 handback**：B=0、C=0、D=0（`:178`）。
- **他機能波及**：0件。
- **判定**：「GO 不可・要手戻り。設計差し戻し不要、スクラッチ再実装＋新実体出力形 fixture での TDD 先行を推奨」（`:181`, `:183`, `:196`）。後続対応はスクラッチ再実装（コミット `d7eddf7c`）。

### 5.5 実装適合レビュー（再実装後）— `implementation-conformance-review-2026-05-19-postrebuild.md`

- reviewed commit `9766febb`（`:6`）。
- **総件数**：新規 finding 0件（`:61`）。P1=0／P2=0／P3=0（`:70`）。severity_weighted 0（`:71`）。
- **段内吸収（absorption）**：A=0（finding ゼロ、`:86`）。
- **上位 handback**：B=0、C=0、D=0（`:82`）。
- **他機能波及**：0件。
- **判定**：「現行承認仕様および evaluation 新契約・foundation 語彙へ構造適合。GO 可」（`:85`, `:87`, `:121`）。前回10件（全件 A）全件解消を独立確認。

---

## 6. dual-reviewer-implementation-governance（統治）

### 6.1 要件 個別レビュー（初版）— `requirements-local-review-2026-05-13.md`

- **総件数**：主役発見13件（`:9`）、敵対役 反論3件＋独立発見8件（`:148`）。集計（判断役）＝must-fix 2件、should-fix 10件、leave-as-is 12件（`:259`–`:261`）。
- **段内吸収（absorption）**：
  - 修正適用：governance 固有 must-fix 0件（`:265`）。should-fix 10件は governance／foundation の混在。
  - 記録のみ：leave-as-is 12件。
- **上位 handback**：0件。
- **他機能波及**：2件（must-fix）：P-2＝foundation Req 1 AC5／Req 6 AC2 の包含関係明示、P-4＝foundation Req 7 AC1 から「pattern assets」削除（`:267`–`:269`）。
- **判定**：GO/NG 総括語なし。

### 6.2 要件 個別レビュー（Requirement 9 版）— `requirements-local-review-2026-05-18.md`

- 対象：Requirement 9「Workflow Execution Ledger and Compliance Enforcement」受入1〜9（`:5`）＝強制関数の要件。
- **総件数**：致命2（F3-1, F4-1）／重要4（F1-1, F2-1, F2-2, F3-2）／軽微4（`:168`–`:170`）。must-fix 候補一覧7項目（`:172`–`:180`）。
- **段内吸収（absorption）**：
  - 修正適用：致命2＋重要4＋軽微4 ＝ 10件すべて governance requirements.md（Req 9 節）への追記で吸収。
- **上位 handback**：0件。
- **他機能波及**：0件（`:184`「他6spec への暗黙契約変更0件、明示記録済み」）。上位運用文書（workflow-repair-procedure／WORKFLOW_OVERVIEW／HUMAN_WORKFLOW）への設計フェーズ同期 TODO 2件（要件承認後の作業）。
- **判定**：「enforcement の機序が成立するための核心条件に致命級の欠落が2件ある」（`:160`）。

### 6.3 設計 個別レビュー（初版）— `design-local-review-2026-05-16.md`

- **総件数**：主役 ERROR 5件／WARN 8件／INFO 0件（`:141`–`:145`）、敵対役独立5件（A-1〜A-5）。集計（判断役）＝must-fix 4件、should-fix 11件、leave-as-is 3件（`:340`–`:342`）。
- **段内吸収（absorption）**：
  - 修正適用：governance 設計固有 must-fix 4件（P-1, P-8, A-1, A-3、`:350`–`:353`）＋ should-fix 11件 ＝ 15件。
  - 記録のみ：leave-as-is 3件。
- **上位 handback**：要件への差し戻し 0件（`:356`）。
- **他機能波及**：0件（`:358`–`:359`「4件すべて governance 設計の内部補完で完結」）。

### 6.4 設計 個別レビュー（Requirement 9 設計節版）— `design-local-review-2026-05-18.md`

- 対象：design.md「Workflow Execution Ledger and Enforcement Model」節（`:5`）。
- **総件数**：致命2（D5-1, D6-1）／重要8（D2-1, D3-1, D3-2, D4-1, D6-2, D7-1, D9-1, D10-1）／軽微3（`:220`–`:225`）。must-fix 候補一覧11項目（`:227`–`:239`）。
- **段内吸収（absorption）**：
  - 修正適用：致命2＋重要8＋軽微3 ＝ 13件すべて governance design.md（Req 9 設計節）への追記で吸収。
- **上位 handback**：0件。
- **他機能波及**：0件（`:254`「設計レビューでも他6 spec の business contract への新義務付与は検出せず」）。上位文書同期 C-1〜C-3 は小節6が取り込み先を明示済み（横断ゲート C 群と対応）。
- **判定**：「設計人間承認に進める前に must-fix 適用が必要（致命2件は承認前必須）」（`:253`）。

### 6.5 設計 逆方向トレース監査 — `design-reverse-trace-audit-2026-05-18.md`

- 監査種別：設計→要件の逆方向トレース（孤児・陳腐・矛盾の検出）（`:4`）。
- **総件数**：26単位。traceable 26/26、orphan 0件、stale/conflict 1件（軽微 S-1、`:78`–`:80`）。
- **段内吸収（absorption）**：
  - 修正適用：軽微1件（S-1＝Validation Model 二層化の可読性向上、`:89`）任意。
  - 記録のみ：「孤児なし」「stale/conflict 1件のみ」を明示記録（`:82`）。
- **上位 handback**：0件。
- **他機能波及**：0件。
- **判定**：「逆方向監査の観点では design.md は健全。S-1 は任意改善、設計差し戻しは不要」（`:101`–`:102`）。

### 6.6 タスク 個別レビュー（Requirement 9 タスク差分版）— `tasks-local-review-2026-05-18.md`

- 対象：tasks.md Task 11〜18 ＋ Requirement 9 完了条件1行（`:6`）。
- **総件数**：致命0／重要0／軽微4（F-1〜F-4）。must-fix（重要以上）0件（`:192`–`:194`, `:206`）。
- **段内吸収（absorption）**：
  - 修正適用：軽微4件（うち F-3 自動採択、F-4 利用者判断、F-1／F-2 任意）。
- **上位 handback**：0件。
- **他機能波及**：0件（`:197`「他6spec波及0件」）。
- **判定**：「must-fix（重要以上）0件のため、タスク横断整合ゲート→人間承認へ進めてよい」（`:213`）。

### 6.7 タスク 個別レビュー（Task 1〜10 正規補完版）— `tasks-local-review-task1-10-2026-05-18.md`

- 対象：tasks.md Task 1〜10 ほか Requirement 1〜8 該当部（`:6`）。
- **総件数**：致命0／重要1（T3-GOV）／軽微2（F-2, T6-GOV）（`:240`–`:242`）。must-fix（重要以上）1件（T3-GOV、自動採択、`:254`）。
- **段内吸収（absorption）**：
  - 修正適用：重要1件＋軽微2件 ＝ 3件すべて governance tasks.md §5 内で閉じる（`:260`）。
- **上位 handback**：0件。
- **他機能波及**：0件（`:230`「他5spec修正波及0件・上位文書波及なし」）。
- **判定**：「must-fix は T3-GOV 1件のみだが自動採択。タスク横断整合ゲートへ」（`:260`）。
- **見落とし事例の明示**：本レビューは「Req9 タスクレビュー（§6.6）が Task 1〜10 を含む全体18件に対する『節5＝10件超は依存グラフ別表が必須』の明示違反・sibling 非対称を正面評価しておらず、本レビュー（Task 1〜10 正規補完）で初めて正面評価する論点」を明示記録（`:259`）。前段で省略された関門の事後補完であり、§7（観察と解釈）の「漏れ点」素材となる。

### 6.8 実装適合レビュー（再実装前）— `implementation-conformance-review-2026-05-19.md`

- reviewed commit `81dfee1c`（`:6`）。出典コミット `0edcfb31`（部分修正：finding6件をTDD解消）。
- **総件数**：finding 6件。P1=2／P2=2／P3=2（`:123`）。severity_weighted 12（`:124`）。
- **段内吸収（absorption）**：A=5件（Finding 1, 2, 3, 5, 6、`:139`, `:142`、各 Finding `:62`–`:117`）。
- **上位 handback**：
  - B 候補=1件：Finding 4（design 小節 1.2 行スキーマと authority-map 実装の乖離、利用者判断で A 吸収可、`:97`, `:136`）。実際の処理は §6.9 で A 吸収＝design 不変。
  - C=0、D=0。
- **他機能波及**：0件（`:144`「統治と再実装済み他5機能の新契約の間に不整合は検出されず」）。
- **判定**：「Requirement 9 強制関数は実 artifact 上で実効的に未稼働。要手戻り（GO 不可）。スクラッチ全面再実装は不要、部分修正で足りる」（`:141`, `:143`, `:162`）。注：統治は他5機能と異なりスクラッチ再実装でなく部分修正の方針（論文化方針§2の「統治のフルスクラッチ再実装は廃案、監査で意図適合判定」とも整合）。
- **見落とし事例（重要）**：Requirement 9 の全テストが tmpdir に手製の権威文書を仮装し実 artifact を一度も検証しない＝実 artifact 上の P1 級不適合3件（Finding 1/3/5）が緑のテストの裏で全て見逃された（Finding 2、`:68`, `:71`, `:74`）。post_smoke_nonconformance_count 6、fixture_bound_resolution_count 6（`:125`–`:126`）。

### 6.9 実装適合レビュー（再実装後／部分修正後）— `implementation-conformance-review-2026-05-19-postrebuild.md`

- 位置付け：「6機能の実装適合フェーズの最後の機能の最終ゲート」（`:7`）。reviewed commit `81dfee1c`（部分修正は本コミット基底の作業ツリーに未コミットで存在、`:6`）。
- **総件数**：新規 finding 0件（`:59`）。P1=0／P2=0／P3=0（`:69`）。severity_weighted 0（`:70`）。
- **段内吸収（absorption）**：A=0（finding ゼロ、`:87`）。
- **上位 handback**：B=0、C=0、D=0（`:87`, `:82`–`:83`）。前回 Finding 4 の reopen-design 候補は利用者判断で A 吸収（authority-map 4列化＋パーサ追従）が選択され、design 小節 1.2 不変のまま解消＝reopen 不発。
- **他機能波及**：0件。
- **判定**：「現行承認仕様へ適合（GO 可）。前回 finding 6件（P1=2／P2=2／P3=2、handback A=5＋B 候補1）は全6件解消を独立確認。これにて6機能の実装適合フェーズの最後の機能が GO 可」（`:88`, `:121`）。

---

## 7. 観察と解釈（人間承認前の素材・事実ではない）

本節は §1〜§6 の事実から読み取れる傾向の説明であり、論文1の主張ではない。骨子・主張は人間承認後に確定する（論文化方針§4「信頼の作法」）。

### 7.1 absorption（段内吸収）と handback の構造的傾向

- 6機能の各段で「段内吸収のみ」で閉じる比率が高い。要件・設計・タスクの各個別レビューでは、must-fix の大半が当該段の成果物編集で吸収される構造になっており、上位段への差し戻しは少数。
  - 要件段で上位 handback（intent への差し戻し）：6機能とも 0件。
  - 設計段で上位 handback（要件への差し戻し）：runtime A-4（1件）のみ。foundation／evaluation／self-improvement／paper-interface／governance はゼロ。
  - タスク段で上位 handback（設計への差し戻し）：6機能とも 0件。
- 実装適合段の handback 構造（再実装前）：
  - foundation：A=8、B=1、C=0、D=0
  - runtime：A=7、B=4、C=0、D=0
  - evaluation：A=10、B=0、C=0、D=0
  - self-improvement：A=3、B=0、C=0、D=0
  - paper-interface：A=10、B=0、C=0、D=0
  - governance：A=5、B 候補=1（A 吸収で消化）、C=0、D=0
- C（要件への差し戻し）と D（intent への差し戻し）は実装適合段でも全機能ゼロ。これは「要件・意図は概ね妥当で、乖離の多くは実装側の旧仕様残存」という記録の趣旨（各機能の総括行）と対応する。

### 7.2 他機能波及の構造

- 要件段の他機能波及（must-fix 帰属が他機能側にある場合）：
  - runtime 要件レビュー：foundation 修正必要 7件（P-1, P-2, P-4, A-1, A-2, A-3, A-7）。
  - evaluation 要件レビュー：foundation 修正必要 1件（P-4）。
  - paper-interface 要件レビュー：foundation 確認要請 1件（A-3）。
  - governance 要件レビュー（初版）：foundation 修正必要 2件（P-2, P-4）。
  - 計：foundation へ11件波及（重複を含む同根 P-4 などあり、解消は foundation 要件 6 受入8追加・Req 7 AC1 修正等で集約）。
- 設計段の他機能波及：
  - runtime 設計レビュー：foundation／evaluation／v2-acquisition への波及 2件（A-5, A-6）。
  - evaluation 設計レビュー：runtime への波及 1件（A-7）。
  - paper-interface 設計レビュー：foundation への波及 1件（P-5）。
  - foundation／self-improvement／governance：他機能波及 0件。
- タスク段の他機能波及：
  - evaluation タスクレビュー：runtime への波及 1件（F-7、横断議題申し送り）。
  - self-improvement タスクレビュー：runtime への波及 2件（T5-A, T5-B、うち T5-A 利用者判断・T5-B 記録のみ）。
  - foundation／runtime／paper-interface／governance：他機能波及 0件。
- 実装適合段の他機能波及：6機能とも 0件。乖離はすべて当該機能の実装側に限局。

### 7.3 absorption 集中の意味

- 全段を通じて「absorption に集中、handback と他機能波及は少数」という構造が観察される。3区分の比率は段によって変化する：
  - 要件・設計段では他機能波及（特に foundation への帰属）が一定数発生（特に runtime 要件で7件）。これは下流機能のレビューが上流契約の不足を発見する正方向の波及である。
  - タスク段では波及が極端に減り（最大2件、ほぼゼロ）、ほぼすべて段内吸収。
  - 実装適合段では他機能波及がゼロ、handback は B（design）に限定。
- この傾向は「機能間の契約は上流段（要件・設計）で固まり、下流段（タスク・実装）は当該機能内に閉じる」という設計サイクルの正常動作と読める。一方で「タスク段への handback 記号が欠落（§0.3）」のため、実装で発生したタスク差分要件を A に圧縮している可能性は残る。

### 7.4 見落としの捕捉点（漏れ点の素材）

「指示違反・仕様逸脱が前段の関門を素通りし後段で初めて捕まった」型の記録が複数機能にある。代表は：

- **fixture 仮装による検証迂回**：4機能（evaluation §3.4 Finding 1/2、self-improvement §4.4 Finding 1/2、paper-interface §5.4 Finding 5、governance §6.8 Finding 2）。手製試験入力で smoke が緑になり、実連携・点検で破綻が露呈。
- **旧仕様残置**：2機能（foundation §1.5、runtime §2.5）。承認仕様の更新に実装が追従せず、旧仕様のもとで成立する形式合格が実体的に新仕様と乖離。
- **関門省略**：1機能（governance §6.7）。Req9 タスクレビュー（§6.6）が Task 1〜10 を含む全体の節 5 違反を正面評価せず、Task 1〜10 正規補完レビュー（§6.7）で初出論点化。

これら3型は論文化方針§2 末尾「フルスクラッチ指示違反が全関門をすり抜け対話・点検で初めて捕まった見落とし」に相当する素材。

### 7.5 記録の様式上の限界

- 差し戻し区分（A／B／C／D）の件数と §4 metric snapshot は実装適合レビューにのみ存在し、要件・設計・タスクの個別レビューは must-fix／should-fix／leave-as-is で集計される。フェーズ横断で同一指標による定量比較はできない（フェーズで記録語が異なる）。これは限界として論文に明記すべき素材（論文化方針§4「限界・脅威を明記」）。
- 「タスクへの handback」記号（仮称 I-1）が元ログに欠落していた（§0.3）。次々セッションでの宿題。
- 原文内部の記述上の不整合：
  - 実行系 再実装前 `implementation-conformance-review-2026-05-18.md:194` 本文「A=5件」は同行括弧内列挙7件・disposition summary・git `bea2dbeb`・後続レビューと不一致。正は A7/B4（§2.5）。
  - 評価 再実装後 `…-postrebuild.md` 結論部 `:89`「全10件解消」と総括 `:110`「9件完全解消・1件部分解消（前回 Finding 9 を新規 Finding 1 に再起票）」は表現一致せず（§3.5）。

### 7.6 absorption と handback の比率を踏まえた追記提案（論文§3.3／§4.3／§4.4 への素材）

- 論文§3.3「手戻り区分 A／B／C／D の定義」では、A／B／C／D は実装適合段の handback 記号であり、要件・設計・タスク段の must-fix／should-fix／leave-as-is とは別系統であることを明記する。両系統の対応関係は「must-fix（修正適用） → 段内吸収（absorption）」「他機能波及あり must-fix → 他機能 spec への記録のみ波及」「タスク段への handback 記号は元ログ欠落」と整理する。
- 論文§4.3 図1（フェーズ別 重大度分布）の集計は、要件・設計・タスク段の must-fix／should-fix／leave-as-is と、実装適合段の P1／P2／P3 を別系統で表示する必要がある。粗統一する場合は §0.1 の記録様式上の限界を脚注で明記する。
- 論文§4.4 図2（手戻りの有向グラフ）は、実装適合段からの B handback（基盤1本、実行系4本、統治1本＝A 吸収で消化）を実線で、漏れ点（fixture 仮装4機能、関門省略1機能）を破線で示すなどの分離が可能。要件・設計・タスク段の他機能波及（foundation への波及11件等）も別の線種で重ねれば、機能間の契約形成過程が可視化できる。
- 論文§4.6（収束）では、再実装前→再実装後の収束を「件数の減少」だけでなく「handback 区分の変化」で示せる。例：実行系は B=4 → B=0、評価は A=10 → A=1、自己改善は A=3 → A=0、論文インターフェースは A=10 → A=0、統治は A=5＋B 候補1 → A=0。
- 論文§5（限界）では、§0.3 の「タスクへの handback 記号欠落」「フェーズ間で記録様式が異なる」「原文内部の記述不整合 2件が保全されたまま」を限界として記述する。

---

## 8. 次工程

- 本文書を論文1の証拠土台 v2 とし、本文 `paper1-body-2026-05-20.md` の §3.3／§4.3／§4.4／§4.6／§5 を本抽出に基づいて補強・修正する（次セッション）。
- 本文補強後、本文と本文書を1コミットで commit／push（明示承認後）。
- 「タスクへの handback」記号（仮称 I-1）の導入要否は次々セッションの宿題。
- v1（evidence-extract-2026-05-20.md）は前版として残し、本書を正本とする。
