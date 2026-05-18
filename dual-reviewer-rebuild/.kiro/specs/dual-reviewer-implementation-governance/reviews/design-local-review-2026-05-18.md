# Design Local Review — dual-reviewer-implementation-governance（Requirement 9 設計節）

- 実施日: 2026-05-18
- 方式: 独立設計レビュアー（起草者とは別視点、REVIEW_PROTOCOL 節 3 の設計 10 観点）
- 対象: design.md「## Workflow Execution Ledger and Enforcement Model」節全体（Owned Artifacts 追加分、小節 1 / 1.1 / 2 / 3 / 4 / 5 / 6 / 7 / 8）
- 照合対象: 既存 design.md 他節（Owned Artifacts、Validation Model、Workflow Model、Workflow Status Model、Reopen Propagation Model、Cross-Spec Alignment Model、Finding Model）、requirements.md Requirement 9 受入 1〜11（既存 Requirement 1〜8、特に 5/6/7）、INTENT.md、WORKFLOW_OVERVIEW.md、HUMAN_WORKFLOW.md、REVIEW_PROTOCOL.md、workflow-repair-procedure.md、workflow-gate-status.md、CONVENTIONS.md、phase-and-feature-dependency-map.md
- 参考（鵜呑みにせず独立判断）: requirements-local-review-2026-05-18.md、requirements-alignment-gate-2026-05-18-governance.md
- 生証跡として不変扱い。design.md / requirements.md / spec.json は変更しない（点検と所見のみ）。
- 設計レビューは HOW（どう実現するか）の具体化を検査する（要件レビューの WHAT 検査とは別）。

---

## 観点 1: 要件全件の網羅（Req9 受入 1〜11 を設計節が漏れなく具体化したか）

要点提示 → 詳細抽出 → 深掘り。AC ごとに設計節の対応箇所と具体化レベルを点検した。

- AC1（着手前に正本から台帳を新規生成）: 小節 1 が「起草または実質作業の前に authority-map から段集合を導出し台帳インスタンスを新規生成」と具体化。Owned Artifacts に `docs/coordination/ledgers/<process_id>-<date>.md` を定義。対応あり。
- AC2（段ごとに stage name / SoT citation / completion predicate / independence requirement）: 小節 1 とテンプレート `workflow-execution-ledger-template.md` 必須欄で具体化。対応あり。
- AC3（完了述語＝証跡 artifact の存在＋構造適合、主張で満たせない）: 小節 2 で具体化、Requirement 5 必須セクション／metric キー検査と同型と明記。対応あり。
- AC4（横断・横段 alignment 段は起草者独立プロセスで生成、independent-production marker を台帳記録）: 小節 3 で具体化、CONVENTIONS 節 8.4 と整合明記。対応あり。
- AC5（独立再導出 entrypoint、Requirement 5 の上位集合、台帳生成ロジック/出力非共有の独立一次パース）: 小節 3 後段＋Owned Artifacts の validator 拡張モードで具体化。対応あり。
- AC6（不可逆操作 enforcement point。spec.json approval / phase-transition write / 任意不可逆状態変更 / 人間承認依頼の生成・提示）: 小節 4 で具体化、判定 pass の論理積を明示。対応あり。
- AC7（全 process 例外なし、特定 process/spec phase に特化しない）: 小節 5 で具体化。対応あり。
- AC8（承認依頼に各段→証跡パスの台帳突合表を埋め込み、その生成自体を enforcement 対象）: 小節 4 末尾で具体化。対応あり。
- AC9（reopen-propagation/cross-spec-alignment 義務保存、workflow-repair-procedure 含む手続き正本を本契約内包へ同期し reopen 経路も enforcement 対象）: 小節 5＋小節 6 C-3 で具体化。対応あり。
- AC10（process ごと段集合の権威ソース文書が単一・明示指定）: 小節 1＋Owned Artifacts `workflow-process-authority-map.md` で具体化。対応あり。
- AC11（validator/独立再導出/台帳が確定的 pass を出せない場合は fail-closed）: 小節 1.1＋小節 4 で具体化。対応あり。
- 1.1 既存台帳の冪等/陳腐化/改竄: 小節 1.1 で provenance 一致・構造検査・独立再導出一致の AND 条件、不一致時 fail-closed、supersedes リンク・破壊的上書き禁止を具体化。対応あり。

11 受入すべてに設計節の対応箇所がある。ただし「対応がある」ことと「実装可能なレベルまで HOW が具体化されているか」は別であり、観点 3〜6 で具体化の深さを精査する。観点 1 単体での致命級（受入未カバー＝設計不在）はなし。

### D1-1: 軽微 — AC6「任意の不可逆ワークフロー状態変更」の捕捉対象集合が列挙どまりで未閉

- 所在: design.md 小節 4「不可逆ワークフロー操作（spec.json approval／phase-transition write／任意の不可逆ワークフロー状態変更／人間承認依頼の生成・提示）」
- 問題: AC6 は「at minimum」で 3 類型＋承認依頼を挙げるが、設計小節 4 も要件文をほぼ転記し「任意の不可逆ワークフロー状態変更」を未定義集合のまま残す。enforcement point が「どの操作を捕捉するか」（観点 4 の接合面境界）が設計レベルで列挙されないと、実装者は spec.json 書き込みと承認依頼生成だけを捕捉し「任意の不可逆状態変更」（例：workflow-gate-status.md の completed 書き込み、reopen イベント追記、alignment memo 確定）を取りこぼし得る。
- 根拠: 小節 4 自身が「検査スクリプトの具体配線・フック実装は tasks／implementation の責務」（小節 8）とするが、捕捉対象の境界（どの artifact への write を不可逆とみなすか）は実装詳細ではなく設計責務。要件 AC6 は「a design decision」を AC10 で明示している一方、不可逆操作集合の確定は設計に委ねられている。
- 推奨対応: 小節 4 に「本 spec が不可逆ワークフロー操作とみなす write 対象の最小集合」を列挙（spec.json の approvals/phase 書き込み、workflow-gate-status.md の status 遷移書き込み、reopen イベント追記、phase evidence summary / gate package の生成・提示）。具体フック配線は実装段でよいが、捕捉対象の集合定義は設計段で閉じる。
- 必要性判定: 設計に書くべき（捕捉対象集合が未閉だと enforcement が穴を持ち、要件の趣旨＝抜け穴封鎖が成立しない）。劣後案＝実装段で列挙は、設計レビューでの検証可能性を失い AC6 の網羅判定ができないため明らかに劣る。致命的デメリットなし → **自動採択可**。

---

## 観点 2: アーキテクチャ整合性（モジュール分割・依存が既存 governance アーキテクチャと整合するか）

要点 → 深掘り。既存 Architecture 節は「feature logic graph に新しい data producer を追加しない／implementation checkpoint に post-stage gate を追加する」と宣言。

- 小節 8 Boundary が「completion gate と evidence contract の owner、feature artifact ownership を変えない（既存 Boundary Clarification 不変）」と明記し、既存 Architecture の post-stage gate 方針と整合。feature logic graph への producer 追加なし。整合（該当なし方向）。
- 台帳生成器・独立再導出器・enforcement point・validator 拡張の 4 モジュールが登場するが、依存方向は「権威ソース文書 → 台帳生成器 → 台帳」「権威ソース文書 → 独立再導出器（台帳生成器の出力に非依存）」「台帳＋独立再導出 → enforcement point」と小節 1/3/4 から読め、循環なし。独立再導出器が台帳生成器に依存しない非共有が小節 3 で明示され、アーキテクチャ上の独立性が担保されている。整合。
- 既存 Validation Model（validator は artifact completeness と structure のみ、finding 妥当性は判定しない）を小節 7 が「finding 妥当性を判定しない方針は不変」と踏襲。整合。

### D2-1: 重要 — 台帳生成器が「feature logic graph に producer を追加しない」既存アーキテクチャ宣言と緊張する点が未解消

- 所在: design.md 既存 Architecture 節（「governance feature は feature logic graph に新しい data producer を追加しない」）↔ 小節 1（台帳インスタンス `docs/coordination/ledgers/<process_id>-<date>.md` を「新規生成」する生成器の導入）
- 問題: 既存 Architecture 節は governance を「post-stage gate のみ、data producer は追加しない」と性格づける。しかし小節 1 の台帳生成器は repo 内に新規 artifact（ledger instance）を毎 process 着手前に生成する producer であり、文面上は「data producer を追加しない」という既存宣言と緊張する。設計節はこの緊張に言及せず、既存 Architecture 節（producer 追加なし）と新節（producer 的な台帳生成器追加）の関係が設計内で未調停。
- 根拠: 設計の内部整合性として、上位の Architecture 宣言と下位の新節が文面矛盾を残すと、実装者・後続レビュアーが「台帳生成器は feature logic graph 上の producer か否か」を解釈で判断することになる。AC1 は台帳生成を要求しており台帳生成器の存在自体は必須なので、矛盾の解消方向は「Architecture 節の宣言は feature business data（schema/evidence）の producer を指し、workflow control artifact である台帳はこれに当たらない」という限定の明示。
- 推奨対応: 小節 1 または小節 8 に「台帳・authority-map は feature logic graph 上の business data producer ではなく workflow control/gate artifact であり、既存 Architecture 節『data producer を追加しない』宣言の対象外」である旨を 1 文補足。あるいは既存 Architecture 節側にその限定を補う。
- 必要性判定: 設計に書くべき（設計内部の文面矛盾は実装段・後続レビューで解釈ぶれを生む。要件 AC1 で台帳生成は不可避なので、矛盾は「限定の明示」で解くしかない）。劣後案なし（生成器を置かない選択は AC1 違反）。致命的デメリットなし → **自動採択可**。

---

## 観点 3: データモデル・スキーマ詳細（台帳の必須欄、authority-map 構造、provenance、marker、supersedes が具体化されているか）

要点 → 深掘り。設計が宣言したデータ構造の値域・必須欄の確定度を精査。

- 台帳必須欄: 小節 1＋Owned Artifacts テンプレートで「stage name / SoT citation（文書+節）/ completion predicate / independence requirement」＋「導出元 provenance（権威ソースの識別子・版・ハッシュ）」を列挙。欄名は確定。
- supersedes リンク: 小節 1.1 で「`supersedes`（置換元参照）」と命名・意味を確定。
- independent-production marker: 小節 3 で名称言及。

### D3-1: 重要 — provenance の「版・ハッシュ」の値域と算出対象が未定義

- 所在: design.md 小節 1（「導出元 provenance（権威ソースの識別子・版・ハッシュ）」）、小節 1.1（「台帳記録の導出元 provenance が現在の権威ソースと一致」）、小節 7(f)
- 問題: 小節 1.1 は「provenance が現在の権威ソースと一致するか」を冪等再開／陳腐化判定の AND 条件の (a) に据える。判定関数の中核入力であるにもかかわらず、(1) 「版」が git commit か文書内 version 行か mtime か未定義、(2) 「ハッシュ」の対象（権威ソース文書全文か AC10 が指す当該 process の段集合該当節か）と算出方式（正規化前後）が未定義、(3) 「識別子」がパスか論理名か未定義。値域未定義のまま小節 7(f)「provenance 一致」検査を validator に課すと、実装者ごとに一致判定が分岐し、陳腐化検知（要件の核心機序）が再現しない。
- 根拠: 観点 3 はデータモデルの値域確定を設計責務とする。小節 1.1 の判定は本要件の改竄／陳腐化耐性の中核で、provenance の比較粒度が「文書全文ハッシュ」か「段集合該当節ハッシュ」かで挙動が大きく変わる（前者は無関係な節編集でも全 process の台帳が陳腐化扱いになり形骸化＝観点 5 とも連動、後者は段集合抽出ロジックの正規化定義が別途必要）。これは複数の合理的選択肢が残り、かつ選択が形骸化リスク／改竄耐性に致命的に影響する。
- 推奨対応: 小節 1 または 1.1 に provenance の (a) 識別子＝権威ソース文書の repo 相対パス、(b) 版＝採用する版基準（例：git blob hash か文書 version 行か）、(c) ハッシュ対象＝全文か AC10 該当節か、を確定して明記する。
- 必要性判定: 設計に書くべき（判定関数の中核入力の値域未定は実装不能に近い曖昧さで、観点 5 の判定関数とも連動）。ハッシュ対象（全文 vs 段集合該当節）は形骸化と改竄耐性のトレードオフがあり複数合理案かつ致命影響 → **利用者判断**。

### D3-2: 重要 — authority-map の構造（行スキーマ・process_id 命名規約・段集合抽出規約）が未定義

- 所在: design.md Owned Artifacts `workflow-process-authority-map.md`、小節 1（「`workflow-process-authority-map.md` が一意指定する権威ソース文書から段集合を導出」）、小節 7(c)
- 問題: authority-map は AC10 の単一権威性を実装に落とす中核 artifact だが、設計はファイル名と「process → 権威ソース文書の対応表」という役割しか定めない。(1) process_id の値域（WORKFLOW_OVERVIEW が規定する phase execution / review wave / alignment gate / reopen procedure / cross-spec alignment の 5 類型をどう識別子化するか、wave は phase 別か単一か）、(2) 各行が「文書」だけか「文書＋節番号」まで指すか（小節 1 は「文書」、小節 2 の SoT citation は「文書+節」で粒度不一致）、(3) 権威ソースから段集合をどう機械抽出するか（節見出し列挙か、特定書式か）が未定義。authority-map 構造が未定だと小節 7(c)「authority-map からの独立再導出と台帳段集合の一致」検査が実装できない。
- 根拠: F2-1（要件レビュー）／C-2（横断ゲート）が「権威ソース一意化」を要件レベルで閉じたが、その実装スキーマは設計責務として明示的に降りてきている（横断ゲート C-2「process→権威文書 対応（AC10 の設計判断）を確定する」）。設計節はこの設計判断を「authority-map.md を置く」までで止め、行スキーマと段集合抽出規約を未確定のまま残す。
- 推奨対応: 小節 1 または小節 7 に authority-map の最小行スキーマ（process_id 値域＝5 類型＋粒度（wave は phase 別か）、authority document path、authoritative section、stage-extraction rule＝どの書式から段集合を読むか）を定義する。
- 必要性判定: 設計に書くべき（AC10 の設計判断＝横断ゲート C-2 が明示的に設計フェーズへ降ろした責務であり、未確定だと独立再導出が実装不能）。process_id の粒度（wave を phase 別に分けるか）は複数合理案かつ独立再導出の段集合一致判定に致命影響 → **利用者判断**。

### D3-3: 軽微 — independent-production marker の構造が未定義（記録）

- 所在: design.md 小節 3（「台帳に independent-production marker を残す」）、小節 7(d)
- 確認: marker の名称は確定するが、何を記録すれば「独立生成された」と機械判定できるか（生成プロセス識別子、別セッション ID、生成者ロール等）が未定義。ただし観点 7（セキュリティ）で marker 偽装面と統合して扱うのが妥当（D7-1 に集約）。観点 3 単体では構造未定として記録にとどめ、推奨は D7-1 に統合。

---

## 観点 4: API/接合面の具体化（validator 拡張モード入出力、enforcement 捕捉境界、生成器⇄再導出器接合、冪等性）

要点 → 深掘り。

- validator 拡張モードの入出力: 小節 7 が確認項目 (a)〜(f) を列挙し、Validation Model 拡張として既存 validator の上位集合と明記。確認項目は具体化されている。
- 生成器⇄再導出器の接合（非共有）: 小節 3 が「台帳生成ロジック・解析結果を共有せず、権威ソースを一次資料として独立に再パース」と接合面の独立性を明示。F3-2（要件）の独立性対象を設計が引き継いでいる。
- 冪等性: 小節 1.1 が「すべて満たすときのみ正当な再開として継続記録（作り直さず冪等に追記）」と冪等条件を 3 条件 AND で具体化。

### D4-1: 重要 — validator 拡張モードの入出力契約（起動形態・終了コード・出力スキーマ）が未定義で、Requirement 5 設計の既存欠落を継承

- 所在: design.md 小節 7（Validation Model 拡張）、既存 Validation Model 節、Owned Artifacts `scripts/validate_implementation_governance_artifacts.rb` の拡張モード
- 問題: AC5 は「Requirement 5 entrypoint の上位集合」とし設計小節 7 も確認項目を列挙するが、(1) 拡張モードの起動形態（同一スクリプトのサブコマンドか引数か、process_id をどう渡すか）、(2) 結果の表現（終了コード、pass/fail/blocked の出力スキーマ）、(3) enforcement point がこの結果をどう機械消費するか（小節 4 の判定 pass の入力）が未定義。要件個別レビュー F1-1 は「Requirement 5 の入出力契約未規定が前回 should-fix」と既に指摘しており、設計でも未補完のまま Requirement 9 が同じ接合面に依存する。
- 根拠: 小節 4 enforcement の判定は「entrypoint／独立再導出が確定的 pass を出せるか」を入力にする（AC11 連動）。その入出力契約（特に「確定的 pass を出せない」をどの終了コード／出力で表すか）が未定義だと、fail-closed 判定（AC11）の実装が分岐し、検査不能を pass と誤読する余地が残る。これは接合面の境界（観点 4）かつ失敗モード（観点 6）に跨る。
- 推奨対応: 小節 7 または小節 4 に拡張モードの最小入出力契約（process_id 引数、終了コード規約＝0 pass / 非0 fail / 検査不能も非0、出力に各段→証跡パスの突合結果を構造化）を定義する。CONVENTIONS 既存の validator_status 語彙（foundation 所有の pass/fail/blocked）との整合方針も 1 文示す。
- 必要性判定: 設計に書くべき（AC11 fail-closed の実装可否がこの接合契約に依存し、未定義だと検査不能を pass と誤読する穴が残る＝要件趣旨に直結）。劣後案＝実装段確定は AC11 の設計検証可能性を失うため明らかに劣る。致命的デメリットなし → **自動採択可**。ただし CONVENTIONS の validator_status 語彙（foundation 所有）への準拠は他 spec 所有語彙との接合判断を含むため、語彙整合の方針は **利用者判断**（pass/fail/blocked を流用するか governance 独自にするか複数合理案）。

---

## 観点 5: アルゴリズム＋性能（段集合の独立再導出ロジック、台帳突合判定関数、権威ソース曖昧判定、全 process 着手前生成のコスト/形骸化）

要点 → 深掘り。

- 段集合の独立再導出ロジック: 小節 3 が「権威ソースを一次資料として独立に再パースして段集合を再導出し台帳と突合、欠落段を validation failure」と方針を示すが、再パースの具体（節見出し抽出か特定書式か）は D3-2 と同根で未定義。
- 台帳突合判定関数: 小節 4 が「pass ⇔ 台帳存在 ∧ 全段 completion predicate 充足 ∧ 独立再導出突合一致」と論理積を明示。判定式は具体化されている。
- 権威ソース曖昧判定: 小節 4 が「権威ソース曖昧で段集合を一意導出不能」を fail-closed トリガに含めるが、「曖昧」を機械判定する基準が未定義。

### D5-1: 致命 — 「権威ソースが段集合を一意導出不能なほど曖昧」の機械判定基準が未定義で、AC11 fail-closed の発火条件が実装不能

- 所在: design.md 小節 4（「権威ソース曖昧で段集合を一意導出不能」を fail-closed トリガに含む）、小節 1.1、requirements AC11（「a canonical source too ambiguous to derive the stage set uniquely」を fail-closed）
- 問題: AC11／小節 4 は「権威ソースが曖昧で段集合を一意導出できない」場合を fail-closed の発火条件に据える。これは本要件の核心機序（検査不能を pass にしない）の一翼。しかし設計は「曖昧」を機械判定する基準を全く与えていない。独立再導出器は権威ソースをパースして段集合を出すが、「一意に出せた／出せなかった（曖昧）」をどう機械判定するかが未定義だと、(1) パーサが何らかの段集合を必ず返す実装になり「曖昧」が永遠に発火しない（fail-closed 機序が空振り＝要件趣旨の無効化）、または (2) 判定が実装者裁量になり再現しない。横断ゲート C-2 が指摘した通り WORKFLOW_OVERVIEW 自身「概観であり正本優先」で wave 段構成・reopen は複数文書に重複記載されており、「曖昧」が現実に起こり得る構造が残っている（authority-map で権威を一意化しても、その権威文書内で段集合が一意に書式化されている保証は別問題）。
- 根拠: 本要件は「失敗した注意喚起型対策の再現を避ける」ことが存在理由（INTENT 2.1／workflow-gate-status 3.4 の reopen 起点＝ワークフロー不遵守）。AC11 の「曖昧なら fail-closed」は機序の最後の砦であり、その発火条件が設計で機械化されないと「曖昧でも何か段集合を返して pass」になり、要件が防ごうとした無言圧縮が「曖昧スルー」という形で復活する。これは受入の目的を設計が満たさない＝致命。実装段では「曖昧をどう判定するか」の設計指針なしには着手できない。
- 推奨対応: 小節 4 または小節 1.1 に「段集合一意導出可能性」の機械判定基準を設計で確定する。例：権威ソース文書は AC10 該当節に段集合を機械抽出可能な確定書式（番号付き stage 見出しの単一リスト等）で記すことを要求し、独立再導出器が (a) 該当節を一意特定できない、(b) 抽出した段リストが空または重複定義、のいずれかなら「曖昧」として fail-closed と定義する。書式要求は小節 6 の上位文書同期（C-2/C-3）の追記内容と一体で確定する。
- 必要性判定: 設計に書くべき（AC11 の核心発火条件が機械化されないと fail-closed が空振りし、要件目的を設計が満たさない＝致命。設計指針なしに実装着手不能）。判定基準の具体（書式要求の形）に複数合理案があり、かつ機序の砦に致命影響 → **利用者判断**。

### D5-2: 軽微 — 全 process 着手前台帳生成のコスト/形骸化への設計上の立場が未言及（記録）

- 所在: design.md 小節 1（全 process 着手前に台帳新規生成）、小節 5（例外なし全 process 適用）
- 確認: 要件レビュー F4-3 が「微小 reopen にも全段台帳を課すと形骸化を誘発し得るが、段集合が正本で小さければ自然」と整理し要件変更不要・自動採択（記録のみ）と判定済み。設計小節 1.1 の冪等再開（正当な再開は作り直さず追記）が再生成コストを一部緩和する設計になっている。設計として形骸化対策は AC3（証拠構造判定）・小節 3（独立再導出）が担う。観点 5 として致命/重要の追加所見なし。設計上の立場（小さい process は段集合が正本で小さくなるため台帳も小さい、冪等再開で再生成しない）を小節 1.1 が実質カバーしており、明示の追記は過剰修正側 → 記録のみ、追加対応不要。

---

## 観点 6: 失敗モード処理＋観測性（fail-closed の網羅性、検査器自身の不在/破損/例外、台帳改竄検知、enforcement 迂回検知、ログ・証跡の所在）

要点 → 深掘り。

- fail-closed 網羅性: 小節 4 が「entrypoint／独立再導出／台帳が確定的 pass を出せない場合（不在・実行失敗・権威ソース曖昧）は pass とみなさず遮断」と 3 失敗類型を列挙。検査器不在・実行失敗を明示的に fail-closed に編入しており要件 F4-1 の致命を設計が引き継いでいる。
- 台帳改竄検知: 小節 1.1 が provenance 一致＋構造検査＋独立再導出一致の AND で陳腐化／改竄を検知し fail-closed、旧台帳保全・supersedes リンクと具体化。
- enforcement 迂回検知（非 spec.json 経路）: 小節 4 が承認依頼生成自体を enforcement 対象に編入し、要件 F3-1 の致命を設計が引き継いでいる。

### D6-1: 致命 — enforcement point 自体の不在/破損/未配線を検知する機序が設計に存在しない（自己参照穴）

- 所在: design.md 小節 4（enforcement point）、小節 8（「検査スクリプトの具体配線・フック実装は tasks／implementation の責務」）
- 問題: 小節 4 は「entrypoint／独立再導出／台帳が確定的 pass を出せない場合は遮断」と検査器側の不在・破損を fail-closed に編入する。しかし enforcement point 自体（不可逆操作の直前で検査を呼ぶ配線・フック）が不在・未配線・無効化された場合を検知する機序が設計に無い。小節 8 は配線を実装責務に委ねるが、「配線が存在し有効であること」を機械保証する設計が無いと、enforcement point を通さずに spec.json approval や承認依頼生成を行う経路（＝今回の reopen 起点そのもの＝ワークフロー不遵守の無言圧縮）が残る。validator の fail-closed は「validator が呼ばれた後」にしか効かず、「そもそも呼ばれない」攻撃面（無言圧縮の本体）を設計が塞いでいない。
- 根拠: 本要件の reopen 起点（workflow-gate-status 3.4 最終行）は「タスクフェーズ wave のフェーズ内レビュー段を無言圧縮、整合ゲートを独立実施せず」＝検査を呼ばずに前進したこと。要件 F4-1 が指摘した「検査スクリプトを壊す／消す」の派生として「検査を呼ぶ配線を置かない／通さない」がある。小節 4 の fail-closed は検査器の内部失敗は塞ぐが、enforcement point の不在・バイパスという最も本質的な穴（要件が生まれた原因そのもの）に対する設計上の保証（例：不可逆操作対象 artifact への write が enforcement を経由したことを台帳/証跡で事後検知できる、または phase 遷移時に enforcement 通過証跡の存在を後続 gate が必須確認する）が無い。これは要件 9 の存在理由に直結する致命的設計欠落。
- 推奨対応: 小節 4 に「enforcement 通過の証跡化」設計を追加する。例：enforcement point が pass した事実を台帳または gate-status に通過マーカー（process_id・対象不可逆操作・タイムスタンプ・突合結果ハッシュ）として記録し、後続の人間承認依頼・次 phase 着手時にこの通過マーカーの存在と整合を必須確認する（マーカー無き状態遷移＝バイパスとして fail-closed）。配線実装は tasks/implementation でよいが、「バイパス不能性をどの証跡で事後保証するか」の設計は本節の責務。
- 必要性判定: 設計に書くべき（enforcement point 不在/バイパスは要件 9 が生まれた原因そのものを再現する致命穴。validator 内部 fail-closed だけでは「呼ばれない」攻撃面を塞げない）。通過マーカーの所在（台帳内か gate-status か別証跡か）に複数合理案があり、かつ要件存在理由に致命影響 → **利用者判断**。

### D6-2: 重要 — 観測性（enforcement 判定・fail-closed 遮断・台帳陳腐化検知のログ/証跡の所在）が設計に未規定

- 所在: design.md 小節 4、小節 1.1、小節 7、既存 Finding Model / Validation Model
- 問題: 小節 4/1.1/7 は判定・遮断・陳腐化検知の挙動を定めるが、それらの結果（いつ・どの process で・なぜ遮断したか、どの段が欠落したか、provenance 不一致の詳細）をどこに記録するかが設計に無い。要件が防ぐ「無言の機序省略」の対偶として、遮断・検知イベントが証跡に残らないと、enforcement が働いたのか／そもそも呼ばれなかったのか（D6-1）を事後監査できない。既存設計は finding を docs/reviews、signal を signal-register、gate 状態を workflow-gate-status に残す証跡所在を持つが、Requirement 9 の enforcement イベントの追記先が小節群に未指定。
- 根拠: 観点 6 は観測性（ログ形式・証跡所在）を設計責務とする。REVIEW_PROTOCOL 節 3 観点 6 は「失敗観測＝復旧設計の前提」とし、移行/監査（観点 10）にも enforcement イベント証跡が要る。workflow-repair-procedure 節 6 の同期（小節 6 C-3）と一体で、enforcement/fail-closed イベントの記録先（workflow-gate-status か coordination log か台帳内か）を確定する必要がある。
- 推奨対応: 小節 4 または小節 7 に enforcement 判定結果・fail-closed 遮断・台帳陳腐化検知イベントの記録先と最小記録項目（process_id、対象操作、判定＝pass/blocked、欠落段または不一致理由、タイムスタンプ）を 1 段落で確定する（既存証跡所在規約＝workflow-gate-status / coordination log のどちらに寄せるか）。
- 必要性判定: 設計に書くべき（証跡所在未定だと遮断/検知が事後監査不能で D6-1 の検知機序とも連動。既存設計は他証跡の所在を定めており Requirement 9 だけ未定なのは整合欠落）。記録先（gate-status か coordination log か台帳内か）に複数合理案、ただし「どこかに残す」自体は不可欠で致命影響は限定的 → 記録先選択は **利用者判断**、記録すること自体は自動採択側。

---

## 観点 7: セキュリティ・改竄（台帳/provenance 改竄耐性、independent marker 偽装、enforcement バイパス面）

要点 → 深掘り。

- 台帳/provenance 改竄耐性: 小節 1.1 が provenance 不一致・構造不適合・独立再導出不一致を改竄とみなし fail-closed、旧台帳保全・supersedes リンク・破壊的上書き禁止と具体化。設計として改竄検知の骨格はある（ただし D3-1 の provenance 値域未定が検知の実効を弱める）。
- enforcement バイパス面: D6-1（致命、enforcement point 自体の不在/バイパス）で扱う。

### D7-1: 重要 — independent-production marker の偽装耐性（誰がどう記録すれば独立と機械判定するか）が未設計

- 所在: design.md 小節 3（「台帳に independent-production marker を残す」）、小節 7(d)（marker を validator が確認）、CONVENTIONS 節 8.4（3 役は独立呼び出し・履歴非共有）
- 問題: 小節 3 は alignment 段の証跡を起草者独立プロセスで生成し marker を台帳に残すとするが、marker は「台帳に書かれた文字列」であり、起草者本人が独立生成を装って marker を自己記入できる。小節 7(d) で validator が marker の存在を確認しても、存在確認は偽装を排除しない。AC4 の独立性（self-review しない）の核心は marker の真正性だが、設計は marker の構造も真正性検証手段も与えない。CONVENTIONS 節 8.4 は 3 役を「独立した呼び出し（会話履歴非共有セッション）」と定義しており、marker が「どの独立プロセス／別セッションが生成したか」を機械的に紐付けられる構造でないと AC4 が形骸化する。
- 根拠: 本要件は「体裁で満たす回帰」を防ぐのが趣旨。marker が自己申告可能なら AC4 は「marker という体裁を起草者が書く」だけになり、要件 F3-1 と同型の「フォーマット遵守を起草者の善意に委ねる」失敗の再現。観点 7（marker 偽装面）の核心。
- 推奨対応: 小節 3 に independent-production marker の真正性設計を追加。例：marker は alignment 段証跡 artifact 自体（独立プロセスが生成した docs/reviews 等の実体）への参照＋その artifact の構造適合（小節 2 の completion predicate と同型）で裏付け、「marker 文字列の存在」ではなく「独立生成された証跡 artifact が存在し構造適合する」ことを independence requirement の completion predicate とする（marker は証跡 artifact への必須リンク欄として定義し、リンク先 artifact 不在/不適合なら独立性未充足＝fail-closed）。
- 必要性判定: 設計に書くべき（marker 自己申告可能性は AC4 を形骸化させ要件趣旨に直結。存在確認だけでは偽装を排除できない）。裏付け方式（証跡 artifact リンク方式）は要件 AC3（証拠 artifact 存在＋構造で完了判定）と同型で劣後案なし → **自動採択可**。D3-3（marker 構造未定）の推奨を本所見に統合。

---

## 観点 8: 依存選定（既存 validator スクリプト/フック基盤との整合、版制約）

要点 → 深掘り。

- 既存 validator との整合: Owned Artifacts は Requirement 5 と同一の `scripts/validate_implementation_governance_artifacts.rb` を拡張モードとして使い、別スクリプトを新設しない（AC5 superset 方針と整合）。Ruby ランタイム前提は既存 Owned Artifacts（`.rb` validator、`bootstrap_reference_free_case.rb`）と一貫し、新規ライブラリ依存の宣言はない。版制約の新規導入なし。
- フック基盤: 小節 8 が「フック実装は tasks／implementation の責務」と委譲。enforcement の配線基盤（フック）の選定は実装段で妥当だが、D6-1（enforcement 不在検知）はフック基盤選定以前の「バイパス不能性をどう設計で保証するか」の問題であり観点 8 ではなく観点 6 で扱い済み。

### D8-0: 該当なし（記録）

- 確認: 新規ライブラリ・外部依存・版制約の導入なし。既存 Ruby validator 基盤の拡張に閉じ、依存選定上の設計所見は致命/重要/軽微いずれも検出なし。フック基盤の具体選定は実装段の責務（小節 8）として妥当で、設計段で確定すべき依存選定事項はない。観点 8 は該当なしを明示記録する。

---

## 観点 9: テスト戦略（台帳生成・独立再導出・enforcement・fail-closed・1.1 各分岐の検証可能性、単体/統合境界）

要点 → 深掘り。REVIEW_PROTOCOL 節 3 は観点 9 を「規模の小さいフィーチャーでも該当なし扱いせず必ず実施、最小でも単体・統合の境界を明示」と規定。

### D9-1: 重要 — Requirement 9 設計節にテスト戦略（検証可能性・単体/統合境界）の記述が皆無

- 所在: design.md「Workflow Execution Ledger and Enforcement Model」節全体（小節 1〜8）
- 問題: 設計節は台帳生成・独立再導出・enforcement・fail-closed・小節 1.1（冪等再開／陳腐化／改竄／supersedes）という分岐の多い機序を定義するが、これらをどう検証するか（単体テストの対象＝段集合抽出関数・突合判定関数・provenance 比較、統合テストの境界＝enforcement point が不可逆操作を実際に遮断するか、fixture＝曖昧な権威ソース・改竄台帳・provenance 不一致の異常系）の記述が一切ない。既存 design.md 他節も明示的なテスト戦略節を持たないが、REVIEW_PROTOCOL 節 3 は観点 9 を「省略せず最小でも単体・統合境界を明示」と必須化しており、enforcement/fail-closed のような誤実装が要件目的を直接無効化する機序ではテスト戦略の設計段明示が特に要る。
- 根拠: REVIEW_PROTOCOL 節 3「観点 9（テスト戦略）と観点 10（移行戦略）は実装フェーズに直結するため規模の小さいフィーチャーでも該当なし扱いせず必ずラウンドを実施（テスト戦略は最小でも単体・統合の境界を明示）」。本機序は分岐が多く（小節 1.1 だけで 3 条件 AND × 不一致時挙動 × supersedes）、異常系（曖昧権威ソース＝D5-1、改竄台帳、enforcement 不在＝D6-1）の検証可能性を設計段で示さないと、tasks フェーズで検証単位に分解できず、AC11/AC4 の「体裁で満たせない」保証がテストで裏付かない。
- 推奨対応: 小節 7 または新小節に最小テスト戦略を追加（単体＝段集合再導出関数・台帳突合判定関数・provenance 一致判定・小節 1.1 の 3 条件分岐、統合＝enforcement point が spec.json approval/承認依頼生成を実際に遮断、異常系 fixture＝曖昧権威ソース/改竄台帳/provenance 不一致/enforcement 未配線で fail-closed すること）。単体/統合の境界を 1 段落で明示すれば足りる（詳細ケース分解は tasks 段）。
- 必要性判定: 設計に書くべき（REVIEW_PROTOCOL 節 3 が観点 9 を設計段必須・該当なし不可と明文化。fail-closed/enforcement は誤実装が要件目的を直接無効化するためテスト境界の設計段明示が特に要る）。劣後案＝tasks 段まで無記述は REVIEW_PROTOCOL 規約違反かつ検証単位分解不能 → **自動採択可**（単体/統合境界の明示は最小追記で劣後案なし）。

---

## 観点 10: 移行戦略（既存 workflow-gate-status/workflow-repair-procedure からの移行、台帳形式変更時の移行、C 群 3 件の同期段取り）

要点 → 深掘り。REVIEW_PROTOCOL 節 3 は観点 10 を「規模の小さいフィーチャーでも該当なし扱いせず、旧版から継承の有無を明示」と規定。

- C 群 3 件の同期段取り: 小節 6 が C-1（依存マップ）／C-2（CONVENTIONS 節 6・WORKFLOW_OVERVIEW 節 7・HUMAN_WORKFLOW 節 5.2.7）／C-3（workflow-repair-procedure 節 2/3）の取り込み先を明示し「具体追記は設計横断整合ゲートで一括、設計確定後の文書同期作業で実施」と段取りを定義。横断ゲート C-1〜C-3 と対応が取れている。移行段取りの骨格はある。

### D10-1: 重要 — 既存 workflow-gate-status の status 語彙・既存運用からの移行、および台帳形式変更時の移行が未設計

- 所在: design.md 小節 1.1（台帳の supersedes リンクは「台帳改竄/陳腐化時」の置換のみ規定）、小節 6（C 群同期）、既存 Workflow Status Model 節、workflow-gate-status.md
- 問題: (1) Requirement 9 導入時点で既に workflow-gate-status.md には多数の completed/reopen イベントが記録され、ledger ディレクトリは存在しない。「既存の進行中ワークフロー（governance spec design 自体が reopen_required で進行中）に台帳機序を後付けする際、過去 process に遡及して台帳を要求するのか／導入時点以降の新規 process からか」の移行方針が設計に無い。AC7「例外なし全 process 適用」を遡及適用すると既存 completed が全て台帳欠落で fail-closed になり得る（自己ブートストラップ問題＝本設計を承認する design フェーズ自体が台帳を要求されるか）。(2) 台帳テンプレート/形式が将来変わったとき既存 ledger インスタンスをどう移行するか（supersedes は改竄/陳腐化用で形式バージョン移行とは別概念）が未設計。REVIEW_PROTOCOL 節 3 観点 10 は「台帳形式変更時の移行スクリプト」を例示として明記しており、本機序はまさに台帳を持つため該当する。
- 根拠: REVIEW_PROTOCOL 節 3「観点 10（移行戦略）は実装フェーズに直結するため規模の小さいフィーチャーでも該当なし扱いせず必ず実施、旧版から継承の有無を明示」。さらに観点 10 の正規例示が「台帳形式変更時の移行スクリプト」。本設計は台帳という新 artifact を全 process に課す移行であり、(a) 適用開始点（遡及 vs 導入後）、(b) 自己ブートストラップ（本契約を導入する design/tasks フェーズ自体への適用可否）、(c) 台帳形式 versioning と移行、の 3 点が移行戦略として要る。workflow-gate-status 3.4 最終行は「設計フェーズ丸ごと再実施＋AC9 同期作業」を必須後続とするため、本設計の適用開始点は実務上避けて通れない。
- 推奨対応: 小節 1 または新小節に移行戦略を追加。最小限：(a) 適用開始点＝本契約の design 承認以降に新規着手する prescribed workflow process から適用（既存 completed は遡及して台帳欠落 fail-closed にしない＝grandfathering の明示）、(b) 自己ブートストラップ＝本契約を導入する設計/タスクフェーズ自体の扱い（移行期は台帳手動生成可など）、(c) 台帳形式 version 欄を必須欄に追加し、形式変更時は supersedes と別の format-migration 経路で移行、を 1 段落で確定。
- 必要性判定: 設計に書くべき（REVIEW_PROTOCOL 節 3 が観点 10 を設計段必須・該当なし不可・台帳形式移行を正規例示と明文化。適用開始点未定は自己ブートストラップ矛盾＝本設計の design 承認手続き自体が台帳を要求されるかが不定で実務をデッドロックさせ得る）。適用開始点（遡及 vs grandfathering）と自己ブートストラップ扱いは複数合理案かつ実務デッドロックに致命影響 → **利用者判断**。台帳 version 欄追加は劣後案なし → 自動採択側。

---

## 集計

- 致命: 2 件（D5-1 権威ソース曖昧判定の機械化未設計、D6-1 enforcement point 不在/バイパス検知の設計不在）
- 重要: 7 件（D2-1 producer 宣言との緊張未調停、D3-1 provenance 値域未定、D3-2 authority-map 構造未定、D4-1 validator 拡張入出力契約未定、D6-2 観測性証跡所在未定、D7-1 marker 偽装耐性未設計、D9-1 テスト戦略皆無、D10-1 移行戦略未設計）※D9-1/D10-1 を含むと重要 8 件
- 軽微: 3 件（D1-1 AC6 捕捉対象集合未閉、D3-3 marker 構造未定〔D7-1 に統合〕、D5-2 形骸化立場〔記録のみ〕）
- 該当なし明示記録: 観点 8（D8-0、依存選定上の設計所見なし）。観点 5 は D5-2 を記録のみ。観点 1 は受入未カバー（設計不在）なし。

注: 重要件数は D9-1（テスト戦略）・D10-1（移行戦略）を含め 8 件。冒頭サマリ整合のため「重要 7+テスト/移行 1 系」と数えず、重要 8 件として総合所見に集計する。

### must-fix 候補一覧（番号・1 行・自動採択/利用者判断の別）

1. D5-1（致命）: 「権威ソース曖昧で段集合一意導出不能」の機械判定基準を設計確定し AC11 fail-closed の発火条件を実装可能化 — 利用者判断（書式要求の形に複数合理案、機序の砦に致命影響）
2. D6-1（致命）: enforcement point 自体の不在/バイパスを事後検知する通過マーカー証跡設計を追加（validator 内部 fail-closed だけでは「呼ばれない」穴を塞げない） — 利用者判断（マーカー所在に複数合理案、要件存在理由に致命影響）
3. D2-1（重要）: 台帳/authority-map は workflow control artifact で既存 Architecture「producer 追加なし」宣言の対象外、と限定を明示 — 自動採択可
4. D3-1（重要）: provenance の識別子/版/ハッシュの値域・算出対象を確定 — 利用者判断（ハッシュ対象＝全文 vs 段集合節に形骸化/改竄耐性トレードオフ）
5. D3-2（重要）: authority-map の行スキーマ・process_id 値域/粒度・段集合抽出規約を確定 — 利用者判断（wave を phase 別に分けるか独立再導出一致判定に致命影響）
6. D4-1（重要）: validator 拡張モードの最小入出力契約（process_id 引数・終了コード・突合出力）を確定 — 自動採択可（CONVENTIONS validator_status 語彙整合方針のみ利用者判断）
7. D6-2（重要）: enforcement 判定/fail-closed 遮断/陳腐化検知イベントの記録先と最小項目を確定 — 記録すること自体は自動採択、記録先選択は利用者判断
8. D7-1（重要）: independent-production marker を「独立生成証跡 artifact への必須リンク＋構造適合」で裏付け（自己申告偽装を排除、AC3 と同型） — 自動採択可
9. D9-1（重要）: 単体/統合/異常系の最小テスト戦略を設計段で明示（REVIEW_PROTOCOL 節 3 観点 9 必須） — 自動採択可
10. D10-1（重要）: 適用開始点（grandfathering）・自己ブートストラップ扱い・台帳形式 version 移行を設計段で確定（REVIEW_PROTOCOL 節 3 観点 10 必須） — 適用開始点/自己ブートストラップは利用者判断、version 欄追加は自動採択側
11. D1-1（軽微）: 小節 4 に「不可逆ワークフロー操作とみなす write 対象の最小集合」を列挙 — 自動採択可

### 観点ごとの該当なし件数概況

- 観点 1（要件網羅）: 受入未カバー（設計不在）0 件。11 受入すべてに設計対応箇所あり。具体化深さの不足は観点 3〜6/9/10 で所見化。
- 観点 8（依存選定）: 該当なし 1 件（D8-0）。新規依存・版制約なし。
- 観点 5: 致命 1（D5-1）＋記録のみ 1（D5-2）。
- その他観点（2/3/4/6/7/9/10）: いずれも所見あり（致命または重要）。該当なし観点は観点 8 のみ。

### 総合所見

- Requirement 9 設計節は 11 受入すべてに対応箇所を持ち、要件レビュー/横断ゲートで閉じた致命級論点（F3-1 非 spec.json 経路→小節 4 で承認依頼生成を enforcement 編入、F4-1 fail-closed→小節 4/1.1、F3-2 独立再導出非共有→小節 3、F2-1 権威ソース一意→authority-map）を設計が引き継いでいる。骨格は要件意図と整合している。
- ただし HOW（どう実現するか）の具体化に **致命 2 件**が残る。D5-1（「権威ソース曖昧」の機械判定基準が皆無で AC11 fail-closed の核心発火条件が空振りし得る）と D6-1（enforcement point 自体の不在/バイパス＝要件 9 が生まれた原因そのものを事後検知する機序が設計に無く、validator 内部 fail-closed では「そもそも検査が呼ばれない」穴を塞げない）。この 2 件は要件の存在理由（無言の機序省略の封鎖）に直結し、設計のまま実装すると「失敗した注意喚起型対策の再現」になる構造的リスクが残る。
- 重要 8 件（D2-1/D3-1/D3-2/D4-1/D6-2/D7-1/D9-1/D10-1）は、データモデル値域・接合面契約・観測性・marker 真正性・テスト/移行戦略の設計段欠落で、いずれも tasks フェーズで検証単位に分解する前に閉じるべき must-fix 級。特に D9-1/D10-1 は REVIEW_PROTOCOL 節 3 が観点 9/10 を設計段必須・該当なし不可と明文化している規約事項。
- **設計人間承認に進める前に must-fix 適用が必要**（致命 2 件は承認前必須、重要 8 件も設計段で閉じるのが REVIEW_PROTOCOL 規約・検証可能性の観点から相当）。軽微 D1-1 も自動採択で同時適用が妥当。致命 2 件・重要のうち D3-1/D3-2/D10-1（適用開始点）は複数合理選択肢かつ致命影響があり利用者判断、D2-1/D4-1/D7-1/D9-1/D6-2（記録すること）/D1-1/D10-1（version 欄）は劣後案なしで自動採択可。
- 他 spec 波及: Requirement 9 設計節は小節 8 で feature artifact ownership 不変を明示し、要件レビュー/横断ゲートが波及 0 を独立確認済み。本設計レビューでも他 6 spec の business contract への新義務付与は検出せず（D4-1 の CONVENTIONS validator_status 語彙整合は foundation 所有語彙の参照可否＝接合方針の確認であって他 spec の AC 変更ではない）。設計段の上位文書同期 C-1〜C-3 は小節 6 が取り込み先を明示済み（横断ゲート C 群と対応）。

---

## 証跡パス

`/Users/Daily/Development/Rwiki-v2-code-mod/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-implementation-governance/reviews/design-local-review-2026-05-18.md`（本文書、生証跡・不変）
