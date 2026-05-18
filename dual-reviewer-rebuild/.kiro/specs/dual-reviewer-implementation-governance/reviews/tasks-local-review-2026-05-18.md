# タスク個別レビュー（Requirement 9 タスク差分・独立レビュー）

- レビュー日：2026-05-18
- 対象 feature：`dual-reviewer-implementation-governance`
- レビュー種別：タスク個別レビュー（REVIEW_PROTOCOL 節 5 の 7 観点）
- レビュー対象：tasks.md の Task 11〜18 ＋「## 6. Completion Criteria」末尾に追加された Requirement 9 完了条件 1 行（既存 Task 1〜10・§4・§5 との整合も検査）
- 設計正本：同 spec design.md「Workflow Execution Ledger and Enforcement Model」節（導入文・Owned Artifacts 追加分・小節 1／1.1／1.2／1.3／2〜10）
- 要件参照：同 spec requirements.md Requirement 9 受入 1〜11
- レビュー人：独立タスクレビュー人（起草者と独立、批判的視点）
- 生証跡（不変）。tasks.md / design.md / spec.json は変更しない（所見のみ）。

---

## 0. 依存マップ確認結果（横断・順序判断の前提＝節 5／節 4 規律）

正本 `docs/alignment/phase-and-feature-dependency-map.md` を確認した。

- §4.7：implementation-governance は runtime/evaluation/self-improvement/paper-interface に対し `review dependency`。data contract を生成せず completion gate を追加する位置。
- §5.3：tasks wave 生成順は foundation → runtime → evaluation → self-improvement → paper-interface → tasks alignment gate → implementation-governance。governance tasks は「prototype 実装後の review gate と validator を定義する位置」。
- §7 Tasks Alignment Checklist：foundation provenance/validator 語彙が固まってから下流という順序規律。Task 13／§5 が参照する foundation 所有正準 validator 状態語彙（`not_run`/`passed`/`failed`/`blocked`）は依存マップの順序規律と整合（foundation 先行）。

結論：Task 11〜18 を governance spec 内に閉じ、§5 Blocking Dependencies で foundation 語彙・他 5 feature implementation 後の concrete artifact 取得を前提化する構成は依存マップと整合。正本に明示なき構造的決定（横断タスクの置き場所等）は本レビューで新規導入せず、設計小節 6（C-1〜C-3）が確定した置き場所を踏襲しているか検査する立場を取る。

---

## 観点 1：設計全件の網羅

要点：design「Workflow Execution Ledger and Enforcement Model」の Owned Artifacts 追加分・小節 1／1.1／1.2／1.3／2〜10 を Task 11〜18 が漏れなく実装単位へ分解しているか。

詳細抽出（設計小節 → 担当 Task の対応）：

- Owned Artifacts 追加分（台帳テンプレ／ledgers/／authority-map／validator 拡張）→ Task 11（テンプレ・ledgers/・authority-map）、Task 13（validator 拡張）。網羅。
- 小節 1（process と台帳生成）→ Task 12。網羅。
- 小節 1.1（冪等性・陳腐化・改竄、supersedes）→ Task 12。網羅。
- 小節 1.2（authority-map 構造・2 階層 process 階層・行スキーマ）→ Task 11。網羅。
- 小節 1.3（provenance 値域＝`authority_path`／`authoritative_section_id`／`section_content_hash`／git 併記）→ Task 11（provenance 欄定義）＋ Task 12（hash 記録・一致判定）。網羅。
- 小節 2（completion predicate＝存在＋構造適合、Requirement 5 同型上位集合）→ Task 13。網羅。
- 小節 3（independence model／independent-production marker＝リンク欄、自己申告偽装排除）→ Task 15。網羅。
- 小節 4（enforcement point 最小集合・曖昧判定・通過マーカー・blocked/fail-closed 記録・承認依頼突合表）→ Task 14。網羅。
- 小節 5（uniform application／reopen 経路を enforcement 対象）→ Task 16。網羅。
- 小節 6（上位文書同期 C-1／C-2／C-3）→ Task 17。網羅。
- 小節 7（Validation Model 拡張・入出力契約・終了コード・foundation 正準語彙参照）→ Task 13。網羅。
- 小節 8（Boundary＝workflow control artifact は data producer 対象外）→ §4 Downstream Handoff／Task 11〜16 の前提に内包。後述 F-1 参照。
- 小節 9（テスト戦略：単体／統合／異常系 fixture）→ Task 18。網羅。
- 小節 10（移行戦略：grandfathering／自己ブートストラップ／`ledger_format_version`／既存運用移行）→ Task 16（grandfathering・自己ブートストラップ・format version）＋ Task 17 C-3（既存運用移行）。網羅。

深掘り・必要性判定：

- 設計小節の機能要素はすべていずれかの Task に分解されている。**致命的な未分解（実装不能になる漏れ）はなし。**
- F-1（軽微）：小節 8「Boundary」（台帳・authority-map・通過マーカーは feature business data producer ではなく workflow control artifact、既存 Architecture 宣言の対象外）が独立 Task の作業項目・完了条件として明示されていない。設計逆方向監査（design-reverse-trace-audit-2026-05-18.md 単位 26）が「小節 8 は traceable」と判定済みで、内容は §4 Downstream Handoff の既存記述（governance は data producer を追加しない）と整合する境界宣言であり、新規実装作業を生まない設計上の限定明示である。実装単位として切り出す必要は薄いが、Task 11 の完了条件「feature ownership を侵さない」が小節 8 の境界宣言と同義であることを Task 11 根拠行に小節 8 を併記すると、レビュー時に「Architecture 宣言との非矛盾」が追跡しやすい。**修正は任意（利用者判断）**。重大度：軽微。実装欠落ではなくトレース可読性の問題。

該当の致命・重要：なし。観点 1 該当所見：F-1（軽微・任意）1 件。

---

## 観点 2：タスクの粒度と完了基準

要点：各 Task が半日〜数日の実装可能単位か、完了条件が検証可能形か。Task 14 等の過大分解要否。

詳細抽出：

- Task 11（テンプレ・ledgers/ skeleton・authority-map）：静的 artifact 3 種の作成。粒度適切。完了条件「段集合の権威ソースが process ごとに一意」は authority-map 行検査で検証可能。
- Task 12（生成器＋既存台帳 3 条件 AND＋supersedes）：ロジック実装 1 本。粒度適切。完了条件「黙った再利用・上書きが起きず／fail-closed／系譜追跡可能」はテスト（Task 18 単体・異常系）で検証可能。
- Task 13（独立再導出 validator 拡張モード）：既存スクリプトのサブモード追加。粒度適切。完了条件「Requirement 5 entrypoint の上位集合として機械検証」は終了コード規約で検証可能。
- Task 14（enforcement 一式：曖昧判定・通過マーカー・観測性・fail-closed）：作業項目が 4 ブロック（不可逆操作最小集合フック判定／曖昧の機械判定／通過マーカー記録と後続必須確認／承認依頼突合表生成も enforcement 対象）あり、本タスク差分中で最大。
- Task 15（independent-production marker）：リンク欄＋completion predicate。小粒度。適切。
- Task 16（uniform application・reopen 経路・移行戦略）：適用範囲規律＋移行 3 方式。粒度適切。
- Task 17（C-1／C-2／C-3 承認後文書同期）：作業項目に「1 件ずつ実施（spec.json alignment 反映を伴う）」と明記。粒度・進め方は適切（承認関門遵守と整合）。
- Task 18（テスト：単体／統合／異常系）：design 小節 9 を分解。TDD 明記。粒度適切。

深掘り・必要性判定：

- F-2（軽微）：Task 14 は enforcement の 4 ブロック（フック判定／曖昧の機械判定／通過マーカー＋後続確認／承認依頼突合表）を 1 Task に集約しており、本差分中で最も重い。ただし 4 ブロックはいずれも同一の enforcement point ロジックに密結合（通過マーカーは判定結果の派生、曖昧判定は判定 pass 条件の一部、承認依頼突合表は enforcement 対象操作の 1 つ）であり、分割すると enforcement point の判定一貫性（pass ⇔ 台帳存在 ∧ 全段 predicate ∧ 突合一致 ∧ 非曖昧）が複数 Task に分散して整合検証が困難になる。「数日」目安の上限付近だが、密結合のため一体実装が合理的で、サブタスク分解は dominated。完了条件「バイパス・検査不能・曖昧がいずれも fail-closed、遮断・通過が事後監査可能」は Task 18 統合・異常系で検証可能。**サブタスク強制分解は不要（現状維持が妥当）**。重大度：軽微。記録のみ。

該当の致命・重要：なし。観点 2 該当所見：F-2（軽微・記録のみ、現状維持妥当）1 件。

---

## 観点 3：依存関係と順序

要点：Task 11→12→13→14… の前提・依存が明示され前提先行か、循環なし。承認後作業（Task 17）の順序整合。

詳細抽出：

- Task 11（テンプレ・authority-map）は Task 12（生成器が authority-map から段集合導出）・Task 13（独立再導出が authority-map を再パース）・Task 14（enforcement が台帳参照）の前提物を作る → 11 が先行。tasks.md §2「実装順序」9（validator と concrete artifact）・理由「procedure と template がないと concrete review artifact が書けない／validator は後段」と整合。
- Task 12（台帳生成・provenance 記録）は Task 13（既存台帳 provenance 一致を独立再導出と突合）・Task 14（enforcement が台帳存在・通過マーカーを台帳へ記録）の前提 → 12 が 13／14 に先行。
- Task 13（独立再導出）は Task 14（enforcement pass 条件＝独立再導出突合一致）の前提 → 13 が 14 に先行。
- Task 15（independent-production marker）は Task 13 の completion predicate 検査対象（小節 7(d)）。13 と 15 は marker 欄定義（15）→検査（13）の関係だが、Task 13 作業は「Requirement 5 検査と同型・上位集合」、Task 15 は marker をリンク欄として実装。15 の marker 欄を 13 が検査するため 15 が 13 に対し interface 先行が望ましいが、両 Task とも設計小節を引いており欄スキーマは設計（小節 3）で固定済み。tasks.md に 13↔15 の明示依存記載はないが、欄スキーマが設計確定済みのため実装順は前後可（並行可）。後述 F-3 参照。
- Task 16（uniform application・移行）は Task 14（enforcement）が存在して初めて「全 process に例外なく適用」が意味を持つ → 14 が 16 に先行する関係だが、tasks.md に明示なし。後述 F-3 参照。
- Task 17（C-1〜C-3）は「本タスク文書承認後の文書同期作業」と明記され、Task 11〜16・18 とは承認関門で分離。設計小節 4／6 が「確定書式を権威ソース文書へ課す追記は小節 6（C-2／C-3）で一体確定」とするため、Task 17 C-2／C-3 完了前は権威ソース文書が確定書式を備えない可能性があるが、これは設計の「自己ブートストラップ／移行期は手作業台帳可」（小節 10、Task 16）で吸収される設計判断であり、順序矛盾ではない。
- Task 18（テスト）は TDD 方針上 Task 12〜16 の実装前にテスト先行（tasks.md §開発方針）。tasks.md §2 順序 10「テスト」末尾配置だが TDD 注記で先行を担保。
- 循環依存：検出なし（11→12→13→14、15・16 は 13/14 の後段、17 は承認後、18 は TDD 先行）。

深掘り・必要性判定：

- F-3（軽微）：Task 13↔15、Task 14→16 の前提順序が各 Task 根拠/作業行に明示依存として書かれていない（設計小節番号は引いているが Task 間先行関係は文章から読み取る形）。tasks.md §2「実装順序」は Task 1〜10 中心の記述で、Task 11〜18 の内部順序（11→12→13→14→{15,16}→18、17 は承認後）が §2 に追記されていない。本差分は 8 Task で「依存グラフ別表」基準（節 5 タスク特有方針：10 件超で別表）には届かず、設計小節番号トレースで前提物の先後は導出可能なため致命/重要ではないが、§2「実装順序」または各 Task に Task 11〜18 の順序 1〜2 行を追記すると実装者が前提物の先行を取り違えにくい。**修正は任意（自動採択可・致命的デメリットなし）**。重大度：軽微。循環なし・前提先行は導出可能なため実装阻害はしない。

該当の致命・重要：なし。観点 3 該当所見：F-3（軽微・任意、自動採択可）1 件。

---

## 観点 4：要件／設計とのトレース

要点：各 Task が Requirement 9 受入番号・design 小節番号を引いているか。

詳細抽出（Task → 引用）：

- Task 11：根拠「Requirement 9 受入 1・2・10、design 小節 1／1.2／1.3／Owned Artifacts」。AC1（着手前新規導出）・AC2（台帳各段欄）・AC10（単一権威ソース）に対応。トレース可。
- Task 12：根拠「受入 1・10・11、design 小節 1／1.1／1.3」。AC1・AC10・AC11（fail-closed）。トレース可。
- Task 13：根拠「受入 5・3、design 小節 2／3／7」。AC5（独立再導出・上位集合）・AC3（completion predicate）。トレース可。
- Task 14：根拠「受入 6・8・11、design 小節 4」。AC6（enforcement point）・AC8（承認依頼突合表）・AC11（fail-closed）。トレース可。
- Task 15：根拠「受入 4、design 小節 3」。AC4（独立生成・independent-production marker）。トレース可。
- Task 16：根拠「受入 7・9、design 小節 5／10」。AC7（一様適用）・AC9（reopen 経路同期）。トレース可。
- Task 17：根拠「受入 9、design 小節 6、要件／設計横断整合ゲート C 群」。AC9。トレース可。
- Task 18：根拠「design 小節 9、プロジェクト開発方針（TDD）」。テスト戦略は design 小節 9 由来。トレース可。
- Completion Criteria 追加行：「Requirement 9 の実行台帳・独立再導出・enforcement・fail-closed・通過マーカー・移行戦略が設計小節 1〜10 どおり実装され、検査不能・バイパス・曖昧がいずれも fail-closed」。要件 AC1〜11 と設計小節 1〜10 を包括参照。トレース可。

受入カバレッジ照合（AC1〜11 → Task）：AC1=Task11/12、AC2=Task11、AC3=Task13、AC4=Task15、AC5=Task13、AC6=Task14、AC7=Task16、AC8=Task14、AC9=Task16/17、AC10=Task11、AC11=Task12/14。**全 11 受入が Task に対応。漏れなし。**

深掘り・必要性判定：

- F-4（軽微）：Task 17 C-3 の作業行は「`workflow-repair-procedure.md` 節 2／3／6 に台帳・enforcement を内包同期」とするが、設計小節 6 は C-3 を「`workflow-repair-procedure.md` 節 2／節 3 に台帳・enforcement を内包同期（AC9 と一体）」とし、設計は節 2／節 3 のみ指定で「節 6」を含まない（workflow-repair-procedure.md の実構成では §6 は「update rule」）。Task が設計より同期対象節を 1 つ（節 6）拡張している。§6「update rule」は本契約導入で更新が必要になりうる節（本文書の更新規律）であり Task の節 6 追加は実務上は妥当な拡張だが、設計小節 6 が同期対象節を「節 2／節 3」と明示確定している以上、Task が設計を越えて節 6 を加えるのは task が design HOW を上書きする形になる。トレース整合上は (a) 設計小節 6 を「節 2／3／6」に追従させる（設計差し戻し＝重め）か、(b) Task 17 C-3 を設計どおり「節 2／3」に揃え、節 6 同期が必要なら設計小節 6 改版を経る、のいずれか。**複数の合理的選択肢が残り、設計小節との不一致を含むため利用者判断**。重大度：軽微（実装不能ではなく文書同期対象の範囲差。C-3 は承認後作業で実害が出る前に是正可能）。なお CONVENTIONS.md §6 参照（Task 17 C-2「節 6」）は設計小節 6 も「節 6」と一致しており不整合なし（現 CONVENTIONS.md §6 は「運用メモ」だが、新概念定義の追記先として §6 を指定する点は task と design で一致）。

該当の致命：なし。観点 4 該当所見：F-4（軽微・利用者判断）1 件。

---

## 観点 5：横断タスクの抽出

要点：上位文書同期（C-1／C-2／C-3）・foundation 所有 validator 状態語彙参照など横断作業が独立 Task として切り出され、中心フィーチャー（governance）側に置かれているか。他 6 spec tasks への波及有無。

詳細抽出：

- 上位文書同期 C-1（`phase-and-feature-dependency-map.md`）／C-2（`CONVENTIONS.md`・`WORKFLOW_OVERVIEW.md`・`HUMAN_WORKFLOW.md`）／C-3（`workflow-repair-procedure.md`）は **Task 17 として独立 Task に切り出され、governance spec の tasks.md に置かれている**。設計レビューの中心フィーチャー判定（節 3）と同じく、本契約の発生源・所有者である governance 側に集約されており、節 5 タスク特有方針「横断タスクは中心フィーチャー側に置く」と整合。
- foundation 所有正準 validator 状態語彙（`not_run`/`passed`/`failed`/`blocked`）参照：Task 13 作業「状態語彙は foundation 所有正準語彙を参照、再定義しない」と完了条件で参照のみと明示。foundation 側 tasks.md に新規追加 Task を要求しない（foundation は当該語彙を既に所有＝foundation tasks.md 行 94-95・187 で `validator_status: not_run/passed/failed/blocked` を canonical owner として定義済み）。横断作業は「参照」であり foundation tasks への波及を生まない。設計小節 7 の方針と整合。
- heuristic 既定挙動・minimal-template 語彙：Task 3（既存）・§5 Blocking Dependencies で「canonical owner は v2-acquisition、governance は参照のみ・語彙確定まで必須検査しない」と既に切り出し済み。Task 11〜18 は heuristic 語彙に新規依存を追加しない（Requirement 9 は台帳・enforcement で heuristic template を必須検査対象に含めない）。v2-acquisition tasks への新規波及なし。

他 6 spec tasks 波及精査（明示記録）：

- foundation/runtime/evaluation/self-improvement/paper-interface/v2-acquisition の各 tasks.md を grep（`workflow-execution-ledger`／`workflow-process-authority-map`／`prescribed workflow process`／`implementation-governance`）→ **いずれも該当 0 件。Task 11〜18 は他 6 spec tasks.md に新規 Task 追加・改版を要求しない。**
- 設計の「全 prescribed workflow process に例外なく適用」（小節 5／Task 16）は workflow control 層（gate/ledger）への適用であり、各 feature の business data tasks を変えない（設計小節 8 Boundary・§4 Downstream Handoff と整合）。governance の completion gate に従う義務は既存 §4 Downstream Handoff で表現済みで Requirement 9 追加で新規 task 波及は発生しない。
- **他 6 spec tasks への波及：0 件。**

深掘り・必要性判定：横断タスク（C-1〜C-3）は独立 Task 17 に集約され中心フィーチャー側配置。foundation 語彙は参照のみで foundation tasks 不変。他 6 spec への波及 0 件。該当所見：なし（横断抽出は適切に実施済み）。

該当の致命・重要・軽微：なし。観点 5 該当所見：なし（適切）。

---

## 観点 6：失敗時の巻き戻し単位

要点：各 Task 失敗時の影響範囲・巻き戻し単位が読めるか（特に enforcement 配線・台帳形式・承認後文書同期）。

詳細抽出：

- Task 11（静的 artifact）：失敗＝artifact 未配置。巻き戻し＝当該ファイル削除のみ。下流（Task 12/13/14）が前提物欠如で動かないが破壊は局所。読める。
- Task 12（台帳生成・supersedes）：設計小節 1.1 が「旧台帳は削除せず証跡保全＋`supersedes` リンク（破壊的上書き禁止）」と巻き戻し単位を設計確定。Task 12 完了条件「置換系譜が追跡可能」がこれを反映。失敗時も旧台帳保全のため巻き戻し単位＝新台帳破棄で旧台帳に復帰。明示的に読める。
- Task 13（validator 拡張）：既存スクリプトのサブモード追加。失敗＝サブモード不適合だが既存 Requirement 1〜8 検査モードは別経路（設計小節 2「別建てにしない」が上位集合関係を保証）。巻き戻し＝サブモード分の差し戻し。読める。
- Task 14（enforcement 配線）：設計小節 4 が fail-closed 既定（pass を出せない＝遮断）。配線失敗時は「検査不能＝fail-closed」で不可逆操作が進まない＝安全側に倒れる。巻き戻し不要（前進が止まるだけ）で影響範囲が読める。設計小節 10 grandfathering（既存 completed は遡及しない）で過去 process への破壊波及なし。最も重要な巻き戻し性が設計＋Task 16 で担保。
- Task 15（marker）：失敗＝リンク欠落で independence 未充足 fail-closed。前進停止のみ。読める。
- Task 16（移行戦略）：grandfathering／`ledger_format_version`／自己ブートストラップが巻き戻し境界を設計確定。format 変更は「supersedes とは別経路の format-migration、旧 version 台帳は読める形を保つ（破壊的一括書換なし）」と巻き戻し非破壊性を明示。読める。
- Task 17（承認後文書同期 C-1〜C-3）：「1 件ずつ実施（spec.json alignment 反映を伴う）」。失敗時の巻き戻し単位＝当該 C 項目 1 件の文書 revert ＋ spec.json alignment 戻し。1 件ずつ＝巻き戻し粒度が C-1／C-2／C-3 単位で明示。reopen 10 ステップ（WORKFLOW_OVERVIEW §5・workflow-repair-procedure）と整合し、文書同期失敗は手戻り種別判定→正本 revert で吸収。読める。
- Task 18（テスト）：失敗＝テスト不成立。実装側を修正（TDD 方針、テスト不変）。巻き戻し単位＝実装差し戻し。読める。

深掘り・必要性判定：enforcement 配線（Task 14）は fail-closed 既定で「失敗＝前進停止」に倒れ巻き戻し不要、台帳形式（Task 12/16）は supersedes／format-migration で非破壊巻き戻しが設計確定、承認後文書同期（Task 17）は 1 件ずつで巻き戻し粒度が明示。**3 つの重点いずれも巻き戻し単位が Task または引用設計小節から読める。** 追加で書くべき巻き戻し記述はなし。

該当の致命・重要・軽微：なし。観点 6 該当所見：なし（巻き戻し単位は設計＋Task で読める）。

---

## 観点 7：波及精査（最終ガード）

要点：観点 1〜6 の所見が他 Task・他 spec・上位文書に与える連鎖を最終確認。波及あり／なしを全件明示記録。

各所見の波及：

- F-1（小節 8 Boundary トレース併記・軽微・任意）：Task 11 根拠行に小節 8 併記するのみ。tasks.md 内 1 行追記で他 Task・他 spec・上位文書への波及 **なし**。
- F-2（Task 14 集約・軽微・記録のみ）：現状維持妥当の判定。変更を加えないため波及 **なし**。
- F-3（Task 11〜18 内部順序の §2 追記・軽微・任意）：tasks.md §2 または各 Task に順序行追記のみ。他 spec・上位文書への波及 **なし**（governance tasks.md 内に閉じる）。
- F-4（Task 17 C-3 の節 6 が設計小節 6 と不一致・軽微・利用者判断）：**波及あり（限定）**。選択肢 (a) 設計小節 6 を「節 2／3／6」に追従＝design.md 改版＝設計差し戻し（重い）。選択肢 (b) Task 17 C-3 を設計どおり「節 2／3」に揃える＝tasks.md 内 1 箇所修正、波及は governance tasks.md に閉じる（軽い）。いずれも他 6 spec tasks への波及はなし（観点 5 で他 spec 波及 0 件を確認済み）。C-3 は承認後作業のため、tasks 承認前に (b) で揃えれば実害なく、節 6 同期が真に必要なら別途設計小節 6 改版を経る運用が保守的（より上流へ倒す＝WORKFLOW_OVERVIEW §4 handback class 規律と整合）。波及範囲は「governance design.md 1 行 or governance tasks.md 1 行」に限定、他 spec・他上位文書 0 件。

他 6 spec tasks への連鎖（再確認）：F-1〜F-4 いずれも他 6 spec tasks.md に変更を要求しない。**他 spec 波及：全所見で 0 件。**

上位文書への連鎖：F-4 選択肢 (a) を採る場合のみ governance design.md（spec 内）に波及。上位運用文書（CONVENTIONS.md／WORKFLOW_OVERVIEW.md／workflow-repair-procedure.md）への実体変更は Task 17（承認後作業）まで発生せず、本タスクレビュー段では上位文書への波及 **なし**（Task 17 の同期作業自体は承認後の別工程）。

観点 7 該当：F-4 のみ限定波及あり（governance spec 内に閉じる）。F-1／F-2／F-3 波及なし。他 6 spec 波及 0 件。

---

## 集計

- 致命：**0 件**
- 重要：**0 件**
- 軽微：**4 件**（F-1／F-2／F-3／F-4）
- 観点別該当：観点 1＝F-1、観点 2＝F-2、観点 3＝F-3、観点 4＝F-4、観点 5＝該当なし、観点 6＝該当なし、観点 7＝F-4 限定波及（他は波及なし）
- 該当なし観点：観点 5（横断タスク抽出は適切に実施済み・他 6 spec 波及 0 件）、観点 6（巻き戻し単位は設計＋Task で読める）
- 他 6 spec tasks 波及：**0 件**（foundation/runtime/evaluation/self-improvement/paper-interface/v2-acquisition いずれも該当 grep 0 件、business data tasks 不変）

## must-fix 候補一覧

- F-1：小節 8 Boundary を Task 11 根拠行に併記してトレース可読性向上 — 軽微・**任意（利用者判断不要、現状維持も正当）**
- F-2：Task 14 の 4 ブロック集約 — 軽微・記録のみ・**現状維持妥当（サブタスク分解は dominated）**
- F-3：Task 11〜18 の内部実装順序を §2 または各 Task に 1〜2 行追記 — 軽微・**自動採択可（致命的デメリットなし）**
- F-4：Task 17 C-3 の同期対象「節 2／3／6」が設計小節 6 の「節 2／3」と不一致 — 軽微・**利用者判断**（選択肢 (a) 設計追従改版／(b) Task を設計どおり節 2／3 に是正の二択、設計小節との不一致を含むため）

must-fix（重要以上）：**0 件**。F-1〜F-3 は任意／自動採択／記録のみで tasks 承認の阻害要因にならない。F-4 のみ設計小節との軽微不一致だが C-3 は承認後作業のため tasks 承認後・C-3 着手前に是正可能で、進行を止める性質ではない。

## 総合所見

- Task 11〜18 ＋ Completion Criteria 追加行は、design「Workflow Execution Ledger and Enforcement Model」の Owned Artifacts 追加分・小節 1〜10 を漏れなく実装単位へ分解しており、**致命的な設計未分解・実装不能は 0 件**。Requirement 9 受入 1〜11 は全件いずれかの Task に対応。
- 既存 Task 1〜10・§4 Downstream Handoff・§5 Blocking Dependencies は不変で、追加差分との整合がとれている。横断タスク（C-1〜C-3）は独立 Task 17 として中心フィーチャー（governance）側に集約され、foundation 正準語彙は参照のみで foundation tasks を変えず、他 6 spec tasks への波及は 0 件。
- 検出は軽微 4 件のみ。F-3 は自動採択可、F-1／F-2 は任意・記録のみ、F-4 は設計小節との軽微不一致で利用者判断だが承認後 C-3 着手前に是正可能。
- 結論：**must-fix（重要以上）0 件のため、本タスク差分はタスク横断整合ゲート → 人間承認へ進めてよい。** must-fix 適用は不要。F-3 は承認前後いずれでも自動採択で取り込んでよく、F-4 は人間承認時に「設計どおり節 2／3 へ是正（推奨・軽い）／設計小節 6 を節 6 追加で追従改版（重い）」のいずれかを利用者へ提示し、tasks 承認後・Task 17 C-3 着手前に確定すれば足りる。F-1／F-2 は任意。

## 証跡パス

- 本レビュー証跡：`.kiro/specs/dual-reviewer-implementation-governance/reviews/tasks-local-review-2026-05-18.md`（本ファイル、不変）
- 依存正本：`docs/alignment/phase-and-feature-dependency-map.md`（§4.7／§5.3／§7 確認）
- 参照（鵜呑みにせず独立判断）：`reviews/design-local-review-2026-05-18.md`、`reviews/design-reverse-trace-audit-2026-05-18.md`、`docs/coordination/design-alignment-gate-2026-05-18-governance.md`
