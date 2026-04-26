

# Rwiki V2の開発-2

[Rwiki V2の開発-1](Rwiki-V2-dev-log-1.md)



[Spec 7 rwiki-v2-lifecycle-management](##Spec 7 rwiki-v2-lifecycle-management)



## Spec 7 rwiki-v2-lifecycle-management



##### ❯ Spec 7 (lifecycle-management) のレビュー開始 — Spec 1 由来 + Spec 4 由来の coordination 要求と過去セッション由来の波及項目 (W-4 / W-5、Important I-5、design 持ち越し I-3) をチェック対象に含める

```
⏺ Requirements を読み終えた。次に関連する過去のレビューセッション履歴と波及項目（W-4 / W-5、Important I-5、design 持ち越し I-3）を確認する。

  Searched for 2 patterns (ctrl+o to expand)

⏺ dev-log の波及項目関連箇所を抽出して読み込む。

  Read 1 file (ctrl+o to expand)

⏺ Spec 1 と Spec 4 のレビューセッションで Spec 7 へ波及した項目を確認する。

  Searched for 2 patterns, read 1 file, listed 1 directory (ctrl+o to expand)

⏺ dev-log と TODO_NEXT_SESSION.md の確認が完了。Spec 7 レビューの要点を整理する。

⏺ Spec 7 (rwiki-v2-lifecycle-management) レビュー — Step 1: 要点提示

  Requirement 一覧（14 Req / 96 AC）

  - R1: Page status 5 種の状態遷移ルール（7 AC）
  - R2: 各 status における参照元扱い・Query/Distill 対象の挙動（7 AC）
  - R3: Page lifecycle と Edge lifecycle の相互作用 orchestration（7 AC）
  - R4: 8 段階共通チェックリストガイド（6 AC）
  - R5: 操作固有ガイドの作成と維持（5 AC）
  - R6: Dangerous op 13 種の分類と handler 動作要件（8 AC）
  - R7: Follow-up タスク仕組み（8 AC）
  - R8: 警告 blockquote の自動挿入（7 AC）
  - R9: Backlink 更新（7 AC）
  - R10: Simple dangerous op の 1 段階確認動作（6 AC）
  - R11: Skill lifecycle（6 AC）
  - R12: Spec 7 ↔ Spec 5 coordination の責務分離（6 AC）
  - R13: Spec 7 ↔ Spec 4 coordination の責務分離（6 AC）
  - R14: Foundation 規範への準拠と文書品質（9 AC）

  Spec 1 由来 coordination 要求の対応状況

  - R3.4 (merge_strategy 5 値、Spec 7 拡張可): R1.7 で 5 値固定。「拡張可」の言及なし → 要追記候補
  - R3.6 (update_history lifecycle 自動追記): R8.5 / R8.7 / R10.3 に部分言及あり。全 dangerous op で update_history: 追記する一般 AC が不在 →
  要追加候補
  - R4.8 (Follow-up frontmatter は Spec 7 所管): R7.2 で完全網羅 → ✅ 対応済

  Spec 4 由来 coordination 要求の対応状況

  - R3.2 / R3.3 (merge 許可・split 禁止): R6.4 で --auto 不可 5 種に split を含み、R6.6 で merge (wiki) --auto の 2 段階指定を
  「設計時の検討事項として残す」と保留にしている。Spec 4 R3.2 / R3.3 では確定済みなので矛盾発生 → 要修正候補
  - R4.7 (L3 診断 API): 本 spec 内に L3 診断 API の提供責務 AC が不在 → 要追加候補（Spec 4 R4.7 が依存）
  - R5.4 (rw follow-up resolve): R7.7 で rw follow-up resolve <id> 言及あり → ✅ 対応済（design 持ち越し可）
  - R16.2 (synthesis_candidates dispatch): R5.1 / R6.1 で promote-to-synthesis / hypothesis approve 言及はあるが、Spec 4 R16.2 が dispatch する Page
  lifecycle API の signature 規定が見当たらない → 要追加候補
  - R13.2 (dangerous op 8 操作の状態遷移ルール): R1 / R6 / R10 でカバー → ✅ 対応済
  - R14.4 (全 coordination の design.md 同期記載): R12.4 / R12.6 / R13.6 / R14.8 で言及 → ✅ 対応済

  過去セッション由来の波及項目

  - W-4 (§2.12 優先性の遵守): Boundary Adjacent expectations に §2.12 言及は R12.5 のみで「§2.12 / Edge status 6 種は Spec 5 所管」の参照に留まる。本
   spec の Boundary 等で §2.12 優先性の遵守を明示する記述が薄い → 要追記候補
  - W-5 (page merge/split の decision_log 自動記録): R3.7 で部分言及（rollback 不能な失敗時のみ）。通常の merge / split / deprecate / retract 等の
  dangerous op approve 完了時に record_decision() を呼ぶ責務 AC が不在 → 要追加候補
  - I-5 (Skill lifecycle Backlink 走査範囲): R11.6 で AGENTS/**/*.md を走査対象に含める明記 → ✅ 対応済
  - I-4 (merge --auto 許可・split 禁止): R6.4 で split 禁止、R6.6 で merge 許可（ただし 2 段階指定保留）→ Spec 4 と一部矛盾、上記 R6.6
  修正と統合して対応
  - I-3 (HTML 差分マーカー attribute): design 持ち越しなので brief 追記の確認のみ → 後段でチェック

  Spec 4 D-8 由来（保留中 Adjacent Sync）

  - skill deprecate / tag deprecate / tag rename / tag register の dangerous op 分類は drafts §7.2 Spec 7 表 13 種に未列挙
  - 本 spec R6.1 では 13 種固定（skill install / skill retract のみ含む、skill deprecate 不在）
  - R5.1 では skill install / skill retract の 2 種のみ操作固有ガイド対象（skill deprecate / tag deprecate / tag rename / tag register 不在）
  - R11.1 では rw skill deprecate / retract / archive の handler ロジック提供 → ✅ 部分的に整合
  - tag deprecate / tag rename / tag register の所管が本 spec に不在 → drafts レベル設計漏れ確認要、もしくは「Spec 1 rw tag *
  委譲」の既存方針で吸収できるか整理要

  第 1 ラウンドの所感サマリ（要確認 / 要追加 / 要修正候補）

  - 致命級候補（要修正）: R6.6 の merge (wiki) --auto 保留を Spec 4 と整合する形で確定（Spec 4 R3.2 で許可リスト＋「慎重判定」確定済み）
  - 致命級候補（要追加）: L3 診断 API（W-5 関連、Spec 4 R4.7 依存）/ record_decision() 呼出責務（W-5）/ Spec 4 R16.2 依存の Page lifecycle API
  signature
  - 重要級候補（要追加）: update_history: 自動追記の一般 AC（Spec 1 R3.6 への対応強化）/ §2.12 優先性遵守の Boundary 明文（W-4）/ merge_strategy 5
  値の「拡張可」明示（Spec 1 R3.4）
  - 重要級候補（要整理）: D-8 由来の tag deprecate / rename / register の所管確認、skill deprecate の操作固有ガイド扱い

  進め方の選択肢

  - A: 全 14 Req を Read で詳細確認してから 6 ラウンド構成（基本整合 / brief・roadmap 照合 / 本質的観点 / failure mode / 他 spec 波及 / drafts
  整合）でフルレビュー（Spec 4 と同じ手順、最も厚い）
  - B: 上記サマリの致命級・重要級候補のみ詳細確認 → 確認不要な R は skip して approve 判断（中程度）
  - C: 「全部読む」で Claude がもう一段深掘り（中程度）

  どの方針で進めますか？

✻ Cooked for 2m 37s

※ recap: Spec 7 (lifecycle-management) の requirements レビューを開始し、Step 1 として 14 Req の要点と Spec 1/4 由来の coordination 要求、波及項目
  (W-4/W-5/I-3/I-5) の対応状況を提示済みです。次は進め方 A/B/C のどれで進めるかユーザーの判断を待ちます。

  3 tasks (1 done, 1 in progress, 1 open)
  ◼ Spec 7 requirements レビュー
  ✔ 過去セッション波及項目を抽出
  ◻ 指摘事項の分類とレポート作成
```

##### ❯ Claude が全 14 Req を順次読み、基本整合 / brief・roadmap 照合 / 本質的観点 / failure mode / 他 spec 波及 / drafts整合を順番に実行。各レビュー後人による承認を得て進む。

```
⏺ 第 1 ラウンド（基本整合性チェック）を実行する。Requirement 内部の論理整合、AC 間の矛盾、用語統一、コンポーネント命名、EARS 形式の妥当性を全 14 Reqで確認した。

  第 1 ラウンド: 基本整合性チェック — 結果

  A. Requirement 間の数の不整合（致命級候補）

  A-1: 操作リストの 13 種 / 11 種 / 17 種 / 3 種の数が R5 / R6 / R11 / R13 で食い違う

  - R6.1: 13 種固定 = deprecate / retract / archive / reactivate / merge (review) / merge (wiki) / split / unapprove / tag merge / tag split / skill install / skill retract / promote-to-synthesis
  - R5.1: 操作固有ガイド対象 11 種 = R6.1 の 13 種から reactivate / unapprove を除外
  - R11.1: handler 提供 3 種 = skill deprecate / skill retract / skill archive
  - R13.1: 17 関数列挙 = R6.1 の 13 種 + R11.1 の skill deprecate / skill archive + R7.7 の followup 4 種

  問題: R6.1 の 13 種に skill deprecate / skill archive が含まれない一方、R11.1 と R13.1 では含まれる。skill deprecate / skill archive の dangerous
  op 分類（危険度 / 対話ガイド要否 / --auto 可否）が R6.2-6.4 に存在しないため、handler 実装時に判断基準が無い → D-8 の Adjacent Sync 結論を待つ前に、本 spec 内で「13 種 + Skill 系拡張 2 種」または「15 種」と整理する必要あり

  問題: R5.1 の 11 種に skill deprecate / skill archive が含まれず、操作固有ガイドが作成対象外。R11.1 の handler は何のガイドを参照すべきか不明 → R5.1 / R5.2 の対象を整理要

  B. Spec 4 との直接的な不整合（致命級）

  B-1: R6.6 が merge (wiki) --auto の 2 段階指定を「設計時の検討事項として残す」

  - 本 spec R6.6: 「merge (wiki) の --auto は SSoT §7.2 表「✓（慎重）」に従い、明示的な --yes-merge-wiki フラグまたは --auto-with-confirmation の 2 段階指定を要求することを 設計時の検討事項として残す」
  - Spec 4 R3.2: rw merge（wiki、慎重判定）は許可リストに追加済み（致-6 で確定）

  → Spec 4 では既に確定済みの事項を本 spec で「検討事項」と書くと矛盾発生。requirements レベルで方針確定が必要。Spec 4 R3.2 の「慎重判定」をそのまま継承する形に修正要

  C. Coordination 要求の対応漏れ（致命級）

  C-1: Spec 4 R16.2 (synthesis_candidates/* dispatch) への対応 AC が不在

  - Spec 4 R16.2 は rw approve 経由で synthesis_candidates/* を Spec 7 page lifecycle API に dispatch する契約を要求
  - 本 spec R6.1 で promote-to-synthesis を 13 種に含むが、Spec 4 R16.2 が呼び出す API signature の規定が R13 にない（R13.1 の 17 関数に cmd_promote_to_synthesis はあるが、synthesis_candidates/* を入力とする dispatch contract が未明示）
  - → R13 に新 AC として「Spec 4 R16.2 が dispatch する cmd_promote_to_synthesis(candidate_path, target_path, ...) の signature を design phase
  で確定」を追加要

  C-2: Spec 4 R4.7 (L3 診断 API) への対応 AC が不在

  - Spec 4 R4.7 は rw doctor の L3 診断項目（未 approve / audit 未実行期間 / deprecated chain 循環 / tag vocabulary 重複候補 / 未解決 follow-up）をSpec 7 所管の L3 診断 API として要求
  - 本 spec に L3 診断 API（例: check_l3_health() など）の提供責務 AC が不在
  - → 新 Req または既存 Req への AC 追加要（Spec 5 R20.8 と並列の構造）

  C-3: W-5 (page merge/split の record_decision() 自動記録) への対応 AC が不在

  - W-5: page merge/split 時の decision_log 自動記録（API 呼出ポイント）の明示
  - 本 spec R3.7 は rollback 不能な失敗時のみ decision_log 記録を Spec 5 へ依頼
  - 正常な merge / split / deprecate / retract の approve 完了時に record_decision() を呼ぶ責務 AC が存在しない
  - → 新 AC 追加要（Foundation R12.4 / Spec 1 本-17 の vocabulary 操作 decision_log と並列構造）

  D. Spec 1 由来 coordination 要求の対応不足（重要級）

  D-1: Spec 1 R3.4 (merge_strategy 5 値の Spec 7 拡張可) への明示が不在

  - 本 spec R1.7 は merge_strategy 5 値を必須記録項目として規定するのみ
  - Spec 1 R3.4 は「初期セット + Spec 7 拡張可（追加時は Adjacent Sync）」を規定
  - → 「6 番目以降の strategy が必要になった場合、Spec 1 を改版する手順を参照点として残す」の AC を追加要

  D-2: Spec 1 R3.6 (update_history: lifecycle 自動追記) の一般 AC が不在

  - 本 spec R8.5 (reactivate) / R8.7 (blockquote updated) / R10.3 (reactivate) で部分的言及
  - 「全 dangerous op の approve 完了時に update_history: へイベント追記する」一般 AC が R1 / R6 にない
  - → R1 または R8 に「全 status 遷移時に update_history: 追記」の一般 AC 追加要

  E. W-4 (§2.12 優先性遵守) の明文不足（重要級）

  - 本 spec の Boundary Adjacent expectations / R12 / R14 で §2.12 への参照が R12.5 のみで「Spec 5 所管」の参照に留まる
  - R14.1 の参照する Foundation 原則に §2.12 が含まれていない（§2.3 / §2.4 / §2.5 / §2.6 / §2.10 / §2.13 のみ）
  - → R14.1 / R12 に「§2.12 L2 専用優先関係の遵守（Page→Edge orchestration が L2 自律進化に立ち入らない）」を Boundary 等で明示する AC 追加要

  F. その他の発見事項

  F-1: コンポーネント命名のばらつき（軽微）

  - ほぼ全 AC で subject = the Lifecycle Manager
  - R4 (4.1-4.6) のみ subject = the Dangerous Operation Guide
  - R5 / R8 / R9 では subject が再び the Lifecycle Manager
  - → R4 のサブコンポーネント分離は意図的か？意図ならば R5 にも応用可、不要ならば統一可。問い合わせ事項

  F-2: R7.2 の task_type enum が固定（中重要度）

  - AC 7.2 で edge_followup / backlink_update / manual_review / reactivation_check の 4 種固定
  - design phase での拡張余地が AC 内で示されていない
  - → 「初期セット 4 種、design phase で拡張可」の追記検討

  F-3: R9.3 と R11.6 の Backlink 走査範囲統合（軽微）

  - R9.3: wiki/**/*.md + raw/**/*.md (Page 用)
  - R11.6: 上記 + AGENTS/**/*.md (Skill 用)
  - 走査対象 enum を R9.3 で初期 2 種、R11.6 で「Skill lifecycle 操作時は AGENTS/** を追加」と明示する形は OK（既に整合）。整理可能だが致命的ではない

  第 1 ラウンド総括

  - 致命級: A-1（操作リスト数の不整合 4 箇所）/ B-1（Spec 4 との merge --auto 矛盾）/ C-1（R16.2 対応）/ C-2（R4.7 L3 診断 API）/ C-3（W-5 record_decision 一般 AC）= 5 件
  - 重要級: D-1（merge_strategy 拡張可）/ D-2（update_history 一般 AC）/ E（§2.12 明文）= 3 件
  - 軽微: F-1（命名ばらつき）/ F-2（task_type enum 拡張余地）/ F-3（Backlink 走査範囲整理）= 3 件

  致命級 5 件は requirements レベルでの修正が必須、重要級 3 件は requirements 推奨、軽微 3 件は brief.md 持ち越しでも可。

  第 1 ラウンドの結果として上記 11 件を提示しました。第 2 ラウンド（roadmap.md / brief.md 厳格照合）に進んでよいか、または第 1 ラウンドで指摘した個別項目を先に詳細確認しますか？
```

##### ❯ 第 1 ラウンドで指摘した個別項目を先に詳細確認

```
⏺ 各指摘の根拠を Spec 4 / Spec 1 / Foundation から抽出して提示する。
⏺ 各指摘の根拠を Spec 4 / Spec 1 から抽出した。順次詳細を提示する。
⏺ 各指摘の根拠を Spec 4 / Spec 1 / Foundation から抽出して提示する。

  Searched for 4 patterns (ctrl+o to expand)

⏺ 各指摘の根拠を Spec 4 / Spec 1 から抽出した。順次詳細を提示する。

  ---
  A-1: 操作リストの数が R5 / R6 / R11 / R13 で食い違う（致命級）

  該当 AC

  Spec 7 R5.1（line 129）: 操作固有ガイド対象 11 種

  ▎ deprecate / retract / archive / merge（wiki page 統合）/ split / tag merge / tag split / skill install / skill retract / hypothesis approve /
  ▎ query promote

  Spec 7 R6.1（line 142）: dangerous op 13 種（drafts §7.2 Spec 7 表 SSoT）

  ▎ deprecate / retract / archive / reactivate / merge (review) / merge (wiki) / split / unapprove / tag merge / tag split / skill install / skill
  ▎ retract / promote-to-synthesis

  Spec 7 R11.1（line 213）: Skill lifecycle handler 3 種

  ▎ rw skill deprecate / rw skill retract / rw skill archive

  Spec 7 R13.1（line 239）: handler 関数 17 種

  ▎ cmd_deprecate / cmd_retract / cmd_archive / cmd_reactivate / cmd_merge_review / cmd_merge_wiki / cmd_split / cmd_unapprove / cmd_skill_install /
  ▎ cmd_skill_deprecate / cmd_skill_retract / cmd_skill_archive / cmd_promote_to_synthesis / cmd_followup_list / cmd_followup_show /
  ▎ cmd_followup_resolve / cmd_followup_dismiss

  整理

  - R6.1 (13 種) には skill install / skill retract のみで skill deprecate / skill archive 不在
  - R11.1 (3 種) は skill deprecate / skill retract / skill archive の Skill lifecycle 拡張
  - R13.1 (17 種) = R6.1 13 種 + skill 拡張 2 種 (cmd_skill_deprecate / cmd_skill_archive) + followup 4 種
  - R5.1 (11 種) は merge (review) / reactivate / unapprove を除外（1 段階確認 ops は除外する設計）、skill deprecate / skill archive も不在

  不整合と Spec 4 D-8 への接続

  - skill deprecate / skill archive の dangerous op 分類（危険度 / 対話ガイド要否 / --auto 可否）が R6.2-6.4 で規定されないと、R11 / R13 の handler
  が判断基準を持たない
  - Spec 4 R13.7（line 257）でも保留中: 「rw skill deprecate の --auto 可否は Spec 7 design phase で確定」「drafts §7.2 Spec 7 表 13
  種に未列挙のため保留中」

  修正案候補

  - (α) R6.1 を 13 種から 15 種に拡張: skill deprecate / skill archive を追加、危険度 / 対話ガイド / --auto 可否を本 spec で確定（Spec 4 R13.7
  の保留を解消、drafts D-8 への波及前提）
  - (β) 現状維持で「13 種 + skill 拡張 2 種は本 spec が dangerous op 分類を独自規定」と注記: drafts §7.2 Spec 7 表 13 種を SSoT とし、本 spec は別途
  skill 拡張用の表を内部に持つ
  - (γ) R5.1 / R13.1 を R6.1 13 種に揃える: skill deprecate / archive の独立 handler は廃止、rw skill deprecate を内部で cmd_deprecate の skill
  モードに集約

  → (α) が drafts SSoT を更新する起点となり最も整合的。ただし drafts §7.2 Spec 7 表に追加する 4 行（skill deprecate / skill archive / tag deprecate / tag rename / tag register）の値判断が必要 → ユーザーへ判断委ね事項

  ---
  B-1: R6.6 の merge (wiki) --auto 保留が Spec 4 R3.2 と矛盾（致命級）

  該当 AC

  Spec 7 R6.6（line 147）:

The Lifecycle Manager shall --auto 可指定の操作（deprecate / archive / reactivate / merge (review) / merge (wiki) / unapprove / tag merge / skill install の 8 種）について、--auto 受領時に 8 段階対話を skip し pre-flight check / 差分プレビュー / 自動 approve を一連で実行することを規定する。ただし merge (wiki) の --auto は SSoT §7.2 表「✓（慎重）」に従い、明示的な --yes-merge-wiki フラグまたは--auto-with-confirmation の 2 段階指定を要求することを設計時の検討事項として残す。

  Spec 4 R3.2（line 108）:

許可リストは rw deprecate / rw archive / rw reactivate / rw merge（wiki page、慎重判定。drafts §11.3 「merge (wiki) ✓（慎重）」と整合、merge_strategy 確定済の場合のみ許可）/ rw unapprove（…--yes フラグの明示を要求…）/ rw tag merge / rw tag rename / rw skill install / rw extract-relations / rw reject <edge-id> …とする。

  不整合の核心

  - Spec 4 R3.2 では「merge_strategy 確定済の場合のみ許可」を確定済みの条件として明示
  - Spec 7 R6.6 では「2 段階指定」を 設計時の検討事項として残す（保留）
  - 両者で「条件は何か」が一致せず（Spec 4 = merge_strategy 確定 / Spec 7 = 2 段階フラグ）、しかも Spec 7 が保留

  修正案

  - 本 spec R6.6 を Spec 4 R3.2 と整合させる: 「merge (wiki) の --auto は merge_strategy field 確定済みの場合のみ許可 とし、--yes 同等の明示フラグをSpec 4 R3.2 と揃える形で要求する」
  - Spec 4 R3.2 が CLI フラグ名の確定権を持つので、本 spec は「条件 = merge_strategy 確定済」のみ規定し、フラグ名は Spec 4 へ委譲

  ---
  C-1: Spec 4 R16.2 への対応 AC が不在（致命級）

  該当 AC

  Spec 4 R16.2（line 299）:

The rw approve command shall review/synthesis_candidates/* を Spec 7 (lifecycle-management) の page lifecycle API（新規 wiki page 生成 / extend / merge / deprecate 等を merge_strategy field と target field から自動判定、Spec 1 Requirement 3 と整合）への dispatch として処理する。

  本 spec での対応状況

  - R5.1 / R6.1 で promote-to-synthesis / hypothesis approve を扱うが、これは Spec 6 hypothesis 経由の wiki 昇格
  - Spec 4 R16.2 は synthesis_candidates/* review 層 → Spec 7 への dispatch であり、page lifecycle API 側の規定が必要
  - R13.1 に cmd_promote_to_synthesis はあるが、synthesis_candidates/* を入力とする dispatch contract（candidate path / target path / merge_strategy/ target field の解釈）が R13 に不在

  修正案

  - R13 に新 AC 追加: 「Spec 4 R16.2 が dispatch する synthesis_candidates/* 入力に対し、本 spec は cmd_promote_to_synthesis(candidate_path,
  target_path, merge_strategy, ...) を提供し、merge_strategy と target field から extend / merge / deprecate / 新規生成のいずれかを自動判定する。signature の確定は design phase の coordination 項目とする」

  ---
  C-2: Spec 4 R4.7 (L3 診断 API) への対応 AC が不在（致命級）

  該当 AC

  Spec 4 R4.7（line 171、Requirement 4 内）:

The Maintenance UX shall 並行診断の対象項目（L1 incoming 状態 / L2 reject queue / L2 decay edges / L2 typed-edge 整備率 / L2 dangling evidence /L3 未 approve 件数 / L3 audit 未実行期間 / L3 tag vocabulary 重複候補 / L3 未解決 follow-up）を Requirement 4 の rw doctor と同じ項目集合とする。

  本 spec での対応状況

  - L3 診断項目（未 approve 件数 / audit 未実行期間 / deprecated chain 循環 / tag vocabulary 重複候補 / 未解決 follow-up）は Spec 7 所管だが、計算
  API の提供責務 AC が不在
  - Boundary Out of scope (line 57) で「Severity 4 水準と exit code 0/1/2 分離… 本 spec は継承」とのみ記述、診断 API は触れず
  - TODO_NEXT_SESSION.md L68 の Spec 7 起票時チェック項目にも明記されている

  修正案

  - 新 Requirement 追加（仮称: Requirement 15 「L3 診断 API の提供」）または既存 Requirement の AC 追加:
    - L3 診断対象 5 項目（未 approve 件数 / audit 未実行期間 / deprecated chain 循環 / tag vocabulary 重複候補 / 未解決 follow-up）の計算 API を提供
    - API 名・signature・返り値構造は design phase で確定（Spec 5 R20.8 と並列構造）
    - rw doctor への CLI dispatch は Spec 4、計算 API 本体は本 spec が所管

  ---
  C-3: W-5 (record_decision() 自動記録) の対応 AC が不在（致命級）

  該当 AC

  Spec 4 R15.10（line 288）:

The rw CLI shall rw approve / rw reject / rw tag merge / rw tag split / rw tag rename / rw tag deprecate / rw tag register / rw deprecate / rw retract / rw archive / rw merge / rw split / rw query promote 等の decision_log 自動記録対象操作（Foundation Requirement 12.4 / §2.13 selective recording）の approve / 実行完了時に Spec 5 の record_decision() API を呼び出す責務を持つ。decision_type の値（…page_deprecate 等）は Spec 5 が初期セットを定義し、Spec 7 / Spec 1 が拡張可とする。

  本 spec での対応状況

  - Spec 4 R15.10 で「呼出主体は rw CLI」と明示 → CLI 層が呼ぶ前提で確定済み
  - 本 spec R3.7（rollback 不能な失敗時のみ decision_log 記録を Spec 5 へ依頼）は 失敗ケースのみ
  - 正常な merge / split / deprecate / retract / archive 完了時の decision_type 拡張責務（page_deprecate 等の値追加）が本 spec に不在

  修正案

  - 新 AC 追加: 「Spec 4 R15.10 が record_decision() を呼び出す際の decision_type 値（page_deprecate / page_retract / page_archive / page_merge /
  page_split / page_promote_to_synthesis 等）を本 spec が初期セットとして規定し、追加時は Spec 5 への Adjacent Sync を経由する」
  - W-5 の本来の趣旨「page merge/split の decision_log 自動記録ポイント」は Spec 4 R15.10 で吸収済みであり、本 spec は decision_type
  拡張側に責務がシフト

  ---
  D-1: Spec 1 R3.4 (merge_strategy 5 値の Spec 7 拡張可) の対応不足（重要級）

  該当 AC

  Spec 1 R3.4（line 103）:

  ▎ merge_strategy:（文字列、初期許可値 として complementary / dedup / canonical-a / canonical-b / restructure の 5 値を宣言。Spec 7 は本 spec
  ▎ を全面改版することなく merge_strategy: 値を追加可能とし、追加時は Spec 7 の requirements で新値を宣言した上で Adjacent Spec Synchronization
  ▎ 運用ルール（roadmap.md）に従い本 spec の許可値リストを同期更新する。許可値リストの正本は本 spec、拡張要請は Spec 7 が起点）

  本 spec での対応状況

  Spec 7 R1.7（line 80）:

  ▎ the Lifecycle Manager shall merged_from（path 配列）/ merged_into（path）/ merge_strategy（complementary / dedup / canonical-a / canonical-b /
  ▎ restructure の 5 値）の 3 field を必須記録項目として要求する。

  → 5 値固定の表現で「拡張可」「Spec 7 起点で Adjacent Sync」の言及なし

  修正案

  - R1.7 の AC を修正、または新 AC 追加: 「本 spec は merge_strategy 5 値を初期セットとして継承する（Spec 1 R3.4）。6 番目以降の strategy
  が必要となった場合、本 spec の requirements で新値を宣言した上で Spec 1 を Adjacent Sync で更新する手順を採る（roadmap.md「Adjacent Spec
  Synchronization」運用ルール）」

  ---
  D-2: Spec 1 R3.6 (update_history: 自動追記責務) の一般 AC 不在（重要級）

  該当 AC

  Spec 1 R3.6（line 105）:

  ▎ update_history の 生成責務（誰が・いつ追記するか）は各操作所管 spec が担う: lifecycle 起源（type: deprecation / merge / split / archive 等）は
  ▎ Spec 7 が自動追記、synthesis 起源は Spec 6 / Spec 4 distill が自動追記、ユーザー手動編集は許可。本 spec は schema（field
  ▎ 存在・型・要素構造）のみを規定し、各 type 値の正規許可値リストおよび追記トリガは所管 spec が確定する。

  本 spec での対応状況

  - R8.5 (reactivate) / R8.7 (blockquote updated) / R10.3 (reactivate) で個別言及
  - 「全 dangerous op の approve 完了時に update_history: 追記」の一般 AC が不在
  - type の許可値（deprecation / merge / split / archive / retract / extension 等）の本 spec 所管分の正規許可値リストが規定されていない

  修正案

  - 新 AC 追加（R1 または R8 内）: 「全 status 遷移 dangerous op の approve 完了時、本 spec は対象ページの update_history: に {date, type, summary}
  要素を自動追記する。type の lifecycle 起源許可値は deprecation / retract / archive / merge / split / reactivate / promote_to_synthesis 等として本
  spec が確定する（Spec 1 R3.6 / Foundation 規範と整合）」

  ---
  E: W-4 (§2.12 優先性遵守) の Boundary 明文不足（重要級）

  該当箇所

  Spec 7 R12.5（line 230）:

  ▎ While Spec 5 が L2 edge の独自 lifecycle（Hygiene による decay / reinforcement / Competition / Contradiction tracking 等）を実装する場合, the
  ▎ Lifecycle Manager shall それらが本 spec から呼び出されないことを明示し、Spec 5 内の自律進化として完結する旨を確認する（Foundation §2.12 / Edge
  ▎ status 6 種は Spec 5 所管）。

  Spec 7 R14.1（line 252）:

  ▎ Foundation の 13 中核原則のうち §2.3 status frontmatter over directory movement / §2.4 Dangerous operations 8 段階 / §2.5 Simple dangerous
  ▎ operations / §2.6 Git + 層別履歴媒体 / §2.10 Evidence chain / §2.13 Curation Provenance を本 spec の設計前提として参照することを明示する。

  → R14.1 の参照対象に §2.12 が不在。R12.5 で参照はあるが Boundary 全体としての遵守宣言が薄い

  W-4 の元趣旨（TODO_NEXT_SESSION.md L277）

  ▎ 層別 binding 不変項目（§2.12 優先性）の明文化不足
  ▎ 修正方針: Spec 5 / Spec 7 requirements に「§2.12 優先性の遵守」を Boundary 等で明示

  修正案

  - R14.1 に §2.12 を追加: 「§2.3 / §2.4 / §2.5 / §2.6 / §2.10 / §2.12 L2 専用優先関係（Page→Edge orchestration が L2 自律進化に立ち入らない） /
  §2.13 を本 spec の設計前提として参照」
  - Boundary Adjacent expectations にも明示追加（line 59 周辺）

  ---
  F-1〜F-3 軽微指摘の根拠

  F-1: コンポーネント命名のばらつき（軽微）

  - R4.1-4.6 の subject = the Dangerous Operation Guide
  - R5 / R8 / R9 / その他全 AC = the Lifecycle Manager
  - 意図確認: R4 のガイド自身を独立 component として subject 化しているのは「ガイドが Markdown ドキュメントとして実体化される」設計か → ユーザー確認

  F-2: R7.2 の task_type enum 拡張余地（中重要度）

  - AC 7.2: edge_followup / backlink_update / manual_review / reactivation_check の 4 種固定
  - design phase での新 task_type 追加余地が不在

  F-3: R9.3 と R11.6 の Backlink 走査範囲（軽微）

  - R9.3: wiki/**/*.md + raw/**/*.md
  - R11.6: 上記 + AGENTS/**/*.md（Skill lifecycle 操作時）
  - 既に整合済、整理は brief 持ち越しで可

  ---
  第 1 ラウンド指摘 11 件の根拠引用と修正案候補の提示が完了しました。

  次のステップ候補:

  - (a) 致命級 5 件 + 重要級 3 件 = 8 件すべてを Edit で適用してから第 2 ラウンドへ
  - (b) 致命級 5 件のみ先に適用、重要級 3 件と軽微 3 件は第 2-6 ラウンド完了後に一括適用
  - (c) 第 1 ラウンドの指摘事項は「指摘記録」として留め、まず第 2 ラウンドへ進み全体観点を出してから一括判断
  - (d) 個別案件（A-1 / B-1 等）について、修正案候補の選択をユーザーが個別に判断してから Edit 適用

  どれで進めますか？
```

#####   ❯ (a)

```
⏺ 致命級 5 件 + 重要級 3 件の修正方針を確定する。A-1 のみ判断分岐があるので、最終 Edit に入る前に修正方針一覧を提示する。

  修正方針一覧（8 件）

  A-1: 操作リスト数の不整合 — 推奨案 (β')

  - R6.1: drafts §7.2 表 13 種を SSoT として維持（変更なし）
  - 新 AC R6.9: 「skill deprecate と skill archive の dangerous op 分類は drafts §7.2 表 13 種未列挙の Skill lifecycle 拡張 2 種として本 spec
  が所管。危険度・対話ガイド要否・--auto 可否は本 spec の design phase で確定（Spec 4 R13.7 の保留事項と整合、drafts D-8 Adjacent Sync 後に drafts
  §7.2 表へ反映可）」を追加
  - R5.1: 11 種 → 13 種に拡張（skill deprecate / skill archive を追加。操作固有ガイド対象として skill deprecate / skill retract / skill archive
  を含む形に整理）
  - R13.1: 変更なし（既に 17 関数で skill 拡張 2 種を含む）

  → 値判断（危険度・対話ガイド・--auto）は design phase に保留、要件レベルの数の不整合のみ解消

  B-1: R6.6 を Spec 4 R3.2 と整合

  - R6.6 末尾の「設計時の検討事項として残す」を削除
  - 「merge (wiki) の --auto は merge_strategy field 確定済みの場合のみ許可 とし、明示フラグ要求の具体名は Spec 4 R3.2 の CLI
  フラグ規定に従う」に置換

  C-1: R13 に新 AC 追加（R13.7）

  - 「Spec 4 R16.2 が review/synthesis_candidates/* を本 spec へ dispatch する際、本 spec は cmd_promote_to_synthesis(candidate_path, target_path,
  merge_strategy, target_field) を提供し、merge_strategy と target field から新規生成 / extend / merge / deprecate
  のいずれかを自動判定する。signature 詳細は design phase で確定」

  C-2: 新 Requirement 15 を追加（L3 診断 API）

  - 「L3 診断 API の提供」5 AC：未 approve 件数 / audit 未実行期間 / deprecated chain 循環 / tag vocabulary 重複候補 / 未解決 follow-up の計算 API 5
  種、rw doctor への CLI dispatch は Spec 4 / 計算 API 本体は本 spec、API 名・signature は design phase で確定（Spec 5 R20.8 と並列構造）
  - Requirement 14 を Requirement 16 に rename

  C-3: W-5 の record_decision() 拡張責務 — 新 AC (R12.7 として追加)

  - 「Spec 4 R15.10 が dangerous op 完了時に呼び出す record_decision() の decision_type 値（page_deprecate / page_retract / page_archive / page_merge
   / page_split / page_promote_to_synthesis 等）を本 spec が初期セットとして規定する。新 decision_type 値の追加時は Spec 5 への Adjacent Sync
  を経由する」

  D-1: R1.7 を Spec 1 R3.4 と整合

  - R1.7 末尾に追記:「本 spec は merge_strategy 5 値を初期セットとして継承する（Spec 1 R3.4）。6 番目以降の strategy が必要となった場合、本 spec の
  requirements で新値を宣言した上で Spec 1 を Adjacent Sync で更新する手順を採る（roadmap.md「Adjacent Spec Synchronization」運用ルール）」

  D-2: update_history: 自動追記の一般 AC — 新 AC (R1.8 として追加)

  - 「全 status 遷移 dangerous op の approve 完了時、本 spec は対象ページの update_history: に {date, type, summary} 要素を自動追記する。type の
  lifecycle 起源許可値は deprecation / retract / archive / merge / split / reactivate / promote_to_synthesis 等として本 spec が確定する（Spec 1 R3.6
  と整合）」

  E: §2.12 を R14.1 に追加 + Boundary に明示

  - R14.1 の参照対象に §2.12 を追加: §2.3 / §2.4 / §2.5 / §2.6 / §2.10 / §2.12 / §2.13
  - Adjacent expectations（line 59 周辺）に「§2.12 L2 専用優先関係（Page→Edge orchestration が L2 自律進化に立ち入らない）の遵守」を追加

  ---
  Requirement 番号の変動

  - 現状: 14 Req
  - 修正後: 16 Req（C-2 で新 Req 15 = L3 診断 API、現 Req 14 = Foundation 規範を Req 16 へ）
  - AC 数: 約 96 → 約 105（C-1 + C-3 + D-2 で +3、C-2 で +5、A-1 で +1、B-1 / D-1 / E は既存 AC 修正で増減なし）

  ---
  この修正方針で 8 件を Edit 適用してよいか確認してください。

  - 進める: 並列 Edit で 8 件を一括適用 → 修正後に第 2 ラウンドへ
  - A-1 を見直し: (β')以外の選択肢（α / γ）を再検討
  - 個別案件を見直し: B-1 / C-1 / C-2 / C-3 / D-1 / D-2 / E のいずれかを再考
```

##### ❯ 8件をまとめて判断しない。ステップバイステップで、修正案のメリット・デメリットを明確に示す。

```
⏺ 了解。1 件ずつ修正案のメリット・デメリットを示し、判断を仰ぎながら進める。

  ---
  A-1: 操作リスト数の不整合（致命級）

  現状の不整合

  - R5.1 = 11 種（操作固有ガイド対象、skill deprecate / skill archive 不在）
  - R6.1 = 13 種（drafts §7.2 表 SSoT、skill deprecate / skill archive 不在）
  - R11.1 = 3 種（Skill 用 handler、skill deprecate / skill retract / skill archive）
  - R13.1 = 17 種（CLI handler 関数、cmd_skill_deprecate / cmd_skill_archive を含む）

  修正案候補と比較

  (α) drafts §7.2 表を 13 種 → 15 種に拡張

  - 内容: drafts §7.2 表自体を改訂、skill deprecate / skill archive を追加し危険度・対話ガイド・--auto 可否を確定。本 spec R6.1 を 15 種に同期、R5.1
  を 13 種に揃える
  - メリット:
    - drafts SSoT が完全網羅、Spec 4 D-8 の保留が部分解消（4 種未列挙のうち 2 種が解消）
    - 全 spec で SSoT 一意、後続 spec のレビューがシンプル
  - デメリット:
    - drafts §7.2 表改訂を本 spec の前提にすると、Adjacent Sync 別セッション処理が本 spec approve をブロックする可能性
    - 危険度・対話ガイド・--auto 可否の値を本 spec レビュー段階で確定要（推測値で書くと Spec 4 D-8 と同じ反復）
    - tag deprecate / tag rename / tag register も同様の状況で「同時に拡張すべき」議論を誘発

  (β) drafts 13 種維持、本 spec 内で skill 拡張 2 種の値を確定

  - 内容: R6.1 を 13 種維持、新 AC で「skill deprecate / archive は本 spec 所管の Skill lifecycle
  拡張、危険度=中/低、対話ガイド=必須/推奨、--auto=可/可」と確定
  - メリット:
    - drafts 改訂を伴わず本 spec 内で完結、approve がブロックされない
    - Spec 4 D-8 の保留を本 spec レビューで解消（design phase 待ちでない）
  - デメリット:
    - SSoT が drafts §7.2 表 13 種と本 spec の skill 拡張 2 種で 2 箇所に分散 → 後の drafts 同期で齟齬リスク
    - 危険度等の値を本 spec で確定する根拠が薄い（drafts §7.2 表の確定プロセスを経ない）
    - tag deprecate 等の類似問題は別途扱う必要

  (β') drafts 13 種維持、本 spec で拡張 2 種を「design phase 確定」として保留

  - 内容: R6.1 を 13 種維持、新 AC で「skill deprecate / archive の dangerous op 分類は本 spec の design phase で確定（Spec 4 R13.7 と整合、drafts
  D-8 Adjacent Sync 後に drafts §7.2 表へ反映可）」と保留明示
  - メリット:
    - drafts 改訂を伴わない
    - 値判断を design phase に持ち越し、要件レベルでは数の不整合のみ解消
    - Spec 4 R13.7 の保留と同じ運用パターン、追加コストなし
  - デメリット:
    - design phase で skill deprecate / archive の値判断が再発 → Spec 4 R13.7 の保留が二重化
    - 本 spec approve 後も drafts D-8 Adjacent Sync が必要
    - R6.1 13 種 + 「拡張 2 種は別途」 の構造になり、handler 実装時の判断基準が薄い

  (γ) skill 系 handler を統合

  - 内容: cmd_skill_deprecate / cmd_skill_archive を廃止、cmd_deprecate / cmd_archive が target 種別（page / skill）を引数で判定する単一 handler
  に統合
  - メリット:
    - 設計の重複が消える
    - R5.1 / R6.1 / R11 / R13.1 の数が一致
  - デメリット:
    - Spec 4 R13.7 が rw skill deprecate を独立 CLI コマンドとして規定済み → handler 統合でも CLI 層は別 dispatch、設計の整合確認が必要
    - skill deprecate と page deprecate は target / Backlink 走査範囲（R9.3 vs R11.6）/ 警告 blockquote 配置先が異なる → 統合 handler
  の内部分岐が複雑化
    - 設計変更が大きく、本 spec のレビュー段階で扱う規模を超える

  (δ) drafts SSoT 13 種に厳密準拠、独立 handler を廃止

  - 内容: R11.1 / R13.1 から skill deprecate / skill archive を削除、Skill lifecycle は drafts §7.2 表 13 種にある skill install / skill retract
  のみ扱う
  - メリット:
    - drafts SSoT 完全準拠
    - 本 spec 内の数が一致
  - デメリット:
    - Skill ファイルに deprecate / archive の lifecycle 機能が無くなる → R11 の責務が空洞化、Page status 5 種と同じ集合で扱う前提（R11.2）と矛盾
    - 「Skill にも Page と同じ lifecycle」という brief.md / R11.2 の前提を崩す（実質設計後退）

  推奨

  (β') を推奨。理由:

  - drafts §7.2 表改訂は別セッション処理のため、本 spec approve がブロックされない
  - 値判断を design phase に保留しても、Spec 4 R13.7 の保留パターンと同じで運用整合
  - 要件レベルでは「数の不整合」が最大の問題で、これは design phase 確定の保留明示で解消できる
  - 値の確定は drafts §7.2 表改訂時に skill deprecate / archive / tag deprecate / rename / register の 5
  種を一括判断する方が効率的（個別判断を分散させない）

  ただし (α) の長所「SSoT 一意」も重大なので、ユーザーが drafts §7.2 表改訂を本 spec approve の前提にしてもよいと判断するなら (α) も合理的選択肢。

  A-1 の修正方針はどれにしますか？

  - (α) drafts 拡張、本 spec で値確定
  - (β) 本 spec 内で値確定（drafts は別途）
  - (β') 本 spec で保留明示、design phase で値確定（推奨）
  - (γ) handler 統合
  - (δ) drafts 13 種に厳密準拠
```

##### ❯ 論点が細かすぎて判断できない

```
⏺ シンプルにします。本質は1つだけ。

  A-1 の核心: drafts §7.2 表（13 種）を本 spec で改訂するか

  選択肢 2 つに絞る

  (1) drafts は変えない、本 spec で「保留」と明示（推奨）

  - skill deprecate / archive を「本 spec で扱う Skill lifecycle 拡張、値は design phase で確定」と注記
  - メリット: drafts 改訂は別セッション処理なので本 spec approve をブロックしない。Spec 4 R13.7 と同じ運用で新たな複雑性なし
  - デメリット: design phase で値判断が再発する

  (2) drafts 改訂を本 spec の前提にする

  - drafts §7.2 表を 13 種 → 15 種に拡張、危険度・対話ガイド・--auto の値も本 spec で確定
  - メリット: SSoT が一意に揃う、後続 spec が読みやすい
  - デメリット: drafts 改訂が完了するまで本 spec を approve できない、値判断を今やる必要

  推奨は (1)

  理由は単純: Spec 4 がすでに同じ問題を「design phase で確定」と保留しており、本 spec も同じ運用にすれば一貫する。drafts 改訂は後でまとめて 5種（skill deprecate / archive / tag deprecate / rename / register）を一括処理する方が効率的。

  (1) でよいか、それとも (2) を選ぶか、これだけ判断してください。
```

```
❯ 多くの表があるので、正確にDangerous op の分類というべき

⏺ ご指摘の通り。今後は 「drafts §7.2 Spec 7 の Dangerous op の分類表」（または短く「Dangerous op の分類表」）と明示します。

  §7.2 Spec 7 セクションには他にも「Page 状態と挙動」表（line 2174-2180）と「コマンド対応」注記（line 2199-2202）があるので、単に「§7.2
  表」では曖昧でした。

  ---
  A-1 再提示（用語修正版）

  問題: drafts §7.2 Spec 7 の Dangerous op の分類表（13 行）に skill deprecate と skill archive が無いのに、本 spec R11.1 / R13.1 ではこの 2 操作の
  handler を提供すると書いている → 矛盾。

  選択肢:

  - (1) 表を変えない（推奨）: 本 spec で「skill deprecate / archive は表に未列挙の Skill lifecycle 拡張、値は design phase で確定」と注記。本 spec
  approve をブロックせず Spec 4 R13.7 と同じ運用
  - (2) 表に 2 行追加する: drafts §7.2 Dangerous op の分類表に skill deprecate / archive を追加して値を本 spec レビューで確定。SSoT が一意になるが
  drafts 改訂と即時の値判断が必要

  どちらで進めますか?
```

##### ❯ 1を採択

```
⏺ A-1 修正完了。

  - R5.1: 操作固有ガイド対象 11 種 → 13 種（skill deprecate / skill archive 追加）
  - R6.9（新 AC）: 「Skill lifecycle 拡張 2 種は drafts 表未列挙、値は design phase で確定」と明示　R6 が 8 AC → 9 AC、R5 が 5 AC → 5 AC（変更なし、対象数のみ拡張）。R11.1 / R13.1 は変更不要（既に skill deprecate / archive を含む）。

  ---
  B-1: R6.6 の merge (wiki) --auto 保留が Spec 4 R3.2 と矛盾（致命級）

  修正案

  R6.6 末尾の「設計時の検討事項として残す」を削除し、Spec 4 R3.2 の確定済み条件（merge_strategy 確定済の場合のみ許可）を引用する形に置換。

  現状（line 147）:

 merge (wiki) の --auto は SSoT §7.2 表「✓（慎重）」に従い、明示的な --yes-merge-wiki フラグまたは --auto-with-confirmation の 2段階指定を要求することを 設計時の検討事項として残す。

  修正後:

merge (wiki) の --auto は drafts §7.2 Spec 7 の Dangerous op の分類表「✓（慎重）」と Spec 4 Requirement 3.2の許可リスト規定に従い、merge_strategy field が確定済みの場合のみ許可する。明示フラグ名（例: --yes 同等）の確定は Spec 4 Requirement 3.2 の CLIフラグ規定に委ね、本 spec は条件（merge_strategy 確定済）のみ規定する。

  メリット

  - Spec 4 R3.2 の確定済み事項を尊重、本 spec が再保留しない
  - フラグ名の規定権を Spec 4 に明確に委譲（CLI フラグは Spec 4 の所管）

  デメリット

  - 「2 段階指定」（--yes-merge-wiki / --auto-with-confirmation）の独自設計案を放棄する →
  ただし元々これは「検討事項」で確定していなかったので、放棄コストはゼロ

  修正案で Edit してよいか?
```

##### ❯ OK

```
⏺ B-1 修正完了。R6.6 で Spec 4 R3.2 の許可リスト規定を引用、保留を解消。

  ---
  C-1: Spec 4 R16.2 への対応 AC が不在（致命級）

  状況

  Spec 4 R16.2 が review/synthesis_candidates/* を Spec 7 へ dispatch する規定だが、本 spec R13 にこの dispatch contract への対応 ACが存在しない。merge_strategy と target field から自動判定するロジックの所管確認が必要。

  修正案

  R13 の末尾（現 R13.6 の後）に新 AC R13.7 を追加。

  追加 AC R13.7（案）:

  ▎ The Lifecycle Manager shall Spec 4 Requirement 16.2 が review/synthesis_candidates/* を本 spec へ dispatch
  ▎ する際、cmd_promote_to_synthesis(candidate_path, target_path, merge_strategy, target_field) を提供し、merge_strategy field と target field から
  ▎ 新規 wiki page 生成 / extend / merge / deprecate のいずれかを自動判定する handler を所管する（Spec 1 Requirement 3 の frontmatter
  ▎ スキーマと整合、判定ロジックは drafts §7.2 Spec 7 の Dangerous op の分類表「promote-to-synthesis」=「最高 / 必須 / --auto 不可」に従い 8
  ▎ 段階対話を必ず経由する）。signature と判定アルゴリズム詳細は本 spec の design phase で確定すべき coordination 項目として明示する。

  メリット

  - Spec 4 R16.2 が依存する API の存在を本 spec で明示、coordination 漏れ解消
  - 自動判定ロジック（4 分岐）の所管を本 spec に固定し、Spec 4 が dispatch のみに専念できる
  - --auto 不可（drafts 表「promote-to-synthesis」= ✗）と整合、安全側に倒れる

  デメリット

  - 自動判定アルゴリズムの詳細は design phase 持ち越しのため、要件レベルでは抽象的な記述に留まる（ただしこれは Spec 4 R13.8 等の他 coordinationと同じパターン）

⏺ 修正案で Edit してよいか?
```

##### ❯ OK

```
⏺ C-1 修正完了。R13 が 6 AC → 7 AC。

  ---
  C-2: Spec 4 R4.7 (L3 診断 API) への対応 AC が不在（致命級）

  状況

  Spec 4 R4.7 が rw doctor の L3 診断項目（未 approve 件数 / audit 未実行期間 / deprecated chain 循環 / tag vocabulary 重複候補 / 未解決 follow-up）を Spec 7 所管の API として要求しているが、本 spec に L3 診断 API の提供責務 AC が不在。

  修正案

  新 Requirement 15「L3 診断 API の提供」を追加（現 R14 = Foundation 規範を R16 に rename）。

  新 R15 案（5 AC）:

  ### Requirement 15: L3 診断 API の提供

  **Objective:** As a Spec 4 起票者, I want Spec 4 Requirement 4.7 が要求する L3 診断項目（未 approve 件数 / audit 未実行期間 / deprecated chain 循環 / tag vocabulary 重複候補 / 未解決 follow-up）の計算 API が本 spec で提供責務として固定されている, so that Spec 4 の `rw doctor` / Maintenance UX / autonomous mode が L3 診断を一意の API 経由で実行でき、診断ロジックが Spec 4 と本 spec で重複しない。

  #### Acceptance Criteria

  1. The Lifecycle Manager shall L3 診断項目として (a) 未 approve 件数（`review/synthesis_candidates/*` / `review/vocabulary_candidates/*` /
  `wiki/.follow-ups/*` 等の未 approve エントリ件数）/ (b) audit 未実行期間（最終 audit 実行からの経過時間）/ (c) deprecated chain 循環（`successor:`
  field の循環参照検出）/ (d) tag vocabulary 重複候補（同一意味の tag 候補検出）/ (e) 未解決 follow-up（`status: open` の Follow-up タスク件数）の 5
  項目を計算する API を提供する。
  2. The Lifecycle Manager shall 各 L3 診断 API の返り値構造（件数 / 該当 path 配列 / severity / 最終実行日時等）を Spec 4 Requirement 4 の `rw
  doctor` および Requirement 8 の Autonomous Maintenance UX が利用可能な形で提供することを規定する。
  3. The Lifecycle Manager shall L3 診断 API の名前 / signature / 返り値スキーマの確定を本 spec の design phase で行う coordination
  項目として明示し、Spec 5 Requirement 20.8（L2 診断 API）と並列構造で定義する。
  4. While `rw doctor` の CLI dispatch / 出力整形 / exit code 制御 / 並列診断 orchestration を扱う場合, the Lifecycle Manager shall それらが Spec 4
  の所管であることを明示し、本 spec は計算 API 本体のみを提供する。
  5. The Lifecycle Manager shall L3 診断 API が deprecated chain 循環検出時に `status: deprecated` ページの `successor:` field
  を辿り、循環が検出された場合に CRITICAL severity で報告する規約を本 spec の所管とする（Foundation Requirement 11 / Severity 4 水準と整合）。

  メリット

  - Spec 4 R4.7 が依存する L3 診断 API の所管が明示
  - Spec 5 R20.8（L2 診断 API）と並列構造で、診断 API の責務分離（L1 = Spec 4 / L2 = Spec 5 / L3 = Spec 7）が一貫
  - deprecated chain 循環検出（Spec 4 R4.7 の項目には無いが、本 spec のシナリオから自然な追加項目）を CRITICAL で報告する規約を明文化

  デメリット

  - Requirement 数が 14 → 16 に増える（C-2 で +1、現 R14 を R16 に rename）
  - design phase でAPI signature を再設計する必要があるが、これは Spec 4 R14.4 の coordination 同期記載と整合する標準パターン

  修正案で Edit してよいか?
```

##### ❯ OK

```
⏺ C-2 修正完了。Requirement 数 14 → 16（新 R15 = L3 診断 API、現 R14 = R16 に rename）。R16.9 の「14 個」も「16 個」に同期更新。

  ---
  C-3: W-5 (record_decision() 拡張責務) の対応 AC が不在（致命級）

  状況

  Spec 4 R15.10 が dangerous op 完了時に record_decision() を呼び出す責務を CLI 側（Spec 4）に固定し、decision_type 値は「Spec 5 が初期セット定義、Spec 7 / Spec 1 が拡張可」と規定。本 spec に decision_type の Page lifecycle 起源値の規定 AC が不在。

  修正案

  R12（Spec 7 ↔ Spec 5 coordination）に新 AC R12.7 を追加。

  追加 AC R12.7（案）:

  ▎ The Lifecycle Manager shall Spec 4 Requirement 15.10 が dangerous op 完了時に呼び出す record_decision() API の decision_type 値として、Page
  ▎ lifecycle 起源の初期セット 6 種（page_deprecate / page_retract / page_archive / page_merge / page_split / page_promote_to_synthesis）を本 spec
  ▎ が規定する。Skill lifecycle 起源（skill_deprecate / skill_retract / skill_archive 等）も同じ pattern で本 spec が規定する。新 decision_type
  ▎ 値の追加時は Spec 5 への Adjacent Sync を経由する（roadmap.md「Adjacent Spec Synchronization」運用ルール、Spec 4 Requirement 15.10 の「Spec 7 /
  ▎ Spec 1 が拡張可」と整合）。record_decision() の自動呼出責務自体は Spec 4 が CLI 側で行い、decision_log.jsonl schema・privacy mode・selective
  ▎ recording ルール本体は Spec 5 の所管とする（Requirement 12.2 と整合）。

  メリット

  - W-5（page merge/split の decision_log 自動記録ポイント）が要件レベルで明示
  - decision_type 値の Page lifecycle 起源所管を本 spec に固定、Spec 4 R15.10 と Spec 5 design の coordination が明確化
  - Skill lifecycle 起源の decision_type も同じ pattern で扱う方針を明示し、Skill 拡張（A-1 / R6.9）との整合保持

  デメリット

  - R12 が「Spec 7 ↔ Spec 5 coordination」だが、Spec 4 R15.10 への直接対応も含む形になる → R12 が Spec 4 / Spec 5 両方への coordination を扱う構造になる（ただし decision_type 値の決定自体は Spec 5 / 呼出は Spec 4 という多者間 coordination なので R12 配置は妥当）

  修正案で Edit してよいか?
```

##### ❯ OK

```
⏺ C-3 修正完了。R12 が 6 AC → 7 AC。

  致命級 5 件 (A-1 / B-1 / C-1 / C-2 / C-3) すべて完了。次は重要級 3 件 (D-1 / D-2 / E)。

  ---
  D-1: Spec 1 R3.4 (merge_strategy 5 値の Spec 7 拡張可) の対応不足（重要級）

  状況

  Spec 1 R3.4 が「許可値リストの正本は本 spec、拡張要請は Spec 7 が起点。追加時は Adjacent Sync」と明記しているが、本 spec R1.7 では 5
  値固定の表現で「拡張可」言及なし。

  修正案

  R1.7 末尾に追記する短い修正。

  現状（line 80）:

  ▎ The Lifecycle Manager shall merged への遷移を扱う場合, the Lifecycle Manager shall merged_from（path 配列）/ merged_into（path）/
  ▎ merge_strategy（complementary / dedup / canonical-a / canonical-b / restructure の 5 値）の 3 field を必須記録項目として要求する。

  修正後:

  ▎ While merged への遷移を扱う場合, the Lifecycle Manager shall merged_from（path 配列）/ merged_into（path）/ merge_strategy（初期セットとして
  ▎ complementary / dedup / canonical-a / canonical-b / restructure の 5 値、Spec 1 Requirement 3.4 と整合）の 3 field
  ▎ を必須記録項目として要求する。本 spec は merge_strategy 5 値を初期セットとして継承し、6 番目以降の strategy が必要となった場合は本 spec の
  ▎ requirements で新値を宣言した上で Spec 1 を Adjacent Sync で更新する手順を採る（roadmap.md「Adjacent Spec
  ▎ Synchronization」運用ルール、許可値リストの正本は Spec 1）。

  メリット

  - Spec 1 R3.4 の「拡張可、Spec 7 起点」運用を本 spec で明示的に継承
  - 将来 6 番目の strategy が必要になったとき、Adjacent Sync 手順が明文化済みで運用ブレを防ぐ

  デメリット

  - R1.7 が長くなる（既存の長文 AC スタイルと一貫しているので大きな問題ではない）

  修正案で Edit してよいか?
```

##### ❯ OK

```
⏺ D-1 修正完了。

  ---
  D-2: update_history: 自動追記の一般 AC が不在（重要級）

  状況

  Spec 1 R3.6 が「lifecycle 起源の update_history: 追記は Spec 7 が自動追記」と明記。本 spec では R8.5 (reactivate) / R8.7 (blockquote updated) / R10.3 (reactivate) の個別 AC のみで、全 dangerous op の approve 完了時に追記する一般 AC が不在。

  修正案

  R1（Page status 5 種の状態遷移ルール）の末尾に新 AC R1.8 を追加。R1 が 7 AC → 8 AC。

  追加 AC R1.8（案）:

  ▎ The Lifecycle Manager shall 全 status 遷移 dangerous op の approve 完了時に対象ページの update_history: field へ要素 {date, type, summary,
  ▎ evidence?} を自動追記する。type の lifecycle 起源許可値として deprecation / retract / archive / merge / split / reactivate / promote_to_synthesis
  ▎  を本 spec が初期セットとして規定し、Skill lifecycle 起源（skill_deprecation / skill_retract / skill_archive）も同じ pattern で本 spec
  ▎ が規定する（Spec 1 Requirement 3.6 が宣言した update_history schema と整合、type の正規許可値リストの所管は本 spec）。新 type 値の追加時は Spec 1
  ▎  への Adjacent Sync を経由する（roadmap.md「Adjacent Spec Synchronization」運用ルール）。

  メリット

  - Spec 1 R3.6 が要請する「lifecycle 起源は Spec 7 が自動追記」が要件レベルで一般 AC として明示される
  - type の許可値リストの正本所管が本 spec に固定、Spec 1 が schema のみ規定する原則と整合
  - Skill lifecycle 起源も同じ pattern で扱い、A-1 / R6.9 / C-3 / R12.7 と一貫

  デメリット

  - R1 のスコープが「状態遷移ルール」から「+ update_history 自動追記」へ若干拡張する（ただし状態遷移そのものの記録なので自然な配置）
  - 既存の R8.5 / R8.7 / R10.3 と内容的に重複する余地がある（ただしそれらは blockquote / reactivate 固有の記述なので、R1.8 は一般則 / R8.5 等は固有則として階層化される）

  修正案で Edit してよいか?
```

##### ❯ OK

```
⏺ D-2 修正完了。R1 が 7 AC → 8 AC。

  ---
  E: W-4 (§2.12 優先性遵守) の Boundary 明文不足（重要級）

  状況

  R14（現 R16）.1 の参照する Foundation 原則に §2.12 が含まれていない（§2.3 / §2.4 / §2.5 / §2.6 / §2.10 / §2.13 のみ）。R12.5 で §2.12
  への部分参照はあるが Boundary 全体としての遵守宣言が薄い。

  修正案（2 箇所修正）

  (1) R16.1 に §2.12 を追加

  現状（line 252）:

The Lifecycle Manager shall Foundation の 13 中核原則のうち §2.3 status frontmatter over directory movement / §2.4 Dangerous operations 8 段階 / §2.5 Simple dangerous operations / §2.6 Git + 層別履歴媒体 / §2.10 Evidence chain / §2.13 Curation Provenance を本 spec の設計前提として参照することを明示する。

  修正後:

The Lifecycle Manager shall Foundation の 13 中核原則のうち §2.3 status frontmatter over directory movement / §2.4 Dangerous operations 8 段階 / §2.5 Simple dangerous operations / §2.6 Git + 層別履歴媒体 / §2.10 Evidence chain / §2.12 L2 専用優先関係（Page→Edge orchestration が L2 自律進化に立ち入らない原則） / §2.13 Curation Provenance を本 spec の設計前提として参照することを明示する。

  (2) Boundary Adjacent expectations に §2.12 遵守を明示追加

  現状（line 59 周辺、Adjacent expectations の末尾）:

本 spec は Severity 4 水準（CRITICAL / ERROR / WARN / INFO）と exit code 0/1/2 分離（PASS / runtime error / FAIL 検出）を Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 経由で継承し、独自に再定義しない。

  修正後（末尾に 1 行追加）:

本 spec は Foundation §2.12「L2 専用優先関係」を遵守し、Page→Edge 相互作用 orchestration（Requirement 3）において Edge 内部状態遷移 / Hygiene による decay / reinforcement / Competition / Contradiction tracking 等の L2 自律進化ロジックに立ち入らない（Requirement 12.5 と整合、Edge status 6 種は Spec 5 所管）。

  メリット

  - W-4 が要請する「層別 binding 不変項目（§2.12 優先性）の明文化」が要件レベルで明示
  - R16.1 の参照リストが 6 → 7 原則に拡張、Foundation 原則継承の網羅性が向上
  - Adjacent expectations に §2.12 遵守が追加され、Boundary の設計前提として強化

  デメリット

  - なし（既存の R12.5 と整合する追加であり、矛盾要素なし）

  修正案で Edit してよいか?
```

##### ❯ OK

```
⏺ E 修正完了。

  ---
  第 1 ラウンド致命級 + 重要級の修正完了サマリ

  - A-1: R5.1 を 11 → 13 種に拡張、新 R6.9 で Skill 拡張 2 種を design phase 保留として明示 → R5 は 5 AC、R6 は 8 → 9 AC
  - B-1: R6.6 の merge (wiki) --auto 保留を Spec 4 R3.2 規定に同期 → R6.6 のみ修正
  - C-1: R13 に新 R13.7 で Spec 4 R16.2 dispatch 対応 AC 追加 → R13 は 6 → 7 AC
  - C-2: 新 R15「L3 診断 API」追加、現 R14 を R16 に rename → Requirement 数 14 → 16、AC +5
  - C-3: R12 に新 R12.7 で decision_type 値の Page lifecycle 起源初期セット規定 → R12 は 6 → 7 AC
  - D-1: R1.7 末尾に Spec 1 R3.4 の Adjacent Sync 手順を継承する記述追加 → R1.7 修正のみ
  - D-2: R1 に新 R1.8 で update_history: 自動追記の一般 AC 追加 → R1 は 7 → 8 AC
  - E: R16.1 に §2.12 追加、Boundary Adjacent expectations に §2.12 遵守を明示 → R16.1 と Boundary 修正

  合計: Requirement 数 14 → 16、AC 数 約 96 → 約 105

  ---
  軽微 3 件（F-1 / F-2 / F-3）が残っています。

  - F-1: コンポーネント命名のばらつき（R4 のみ subject = the Dangerous Operation Guide）
  - F-2: R7.2 の task_type enum 拡張余地
  - F-3: R9.3 と R11.6 の Backlink 走査範囲整理

  進め方の選択肢:

  - (a) 軽微 3 件をステップバイステップで処理してから第 2 ラウンドへ
  - (b) 軽微 3 件は brief.md 持ち越しに記録、第 2 ラウンドへ進む
  - (c) 軽微 3 件をスキップして第 2 ラウンドへ（後続ラウンドで再浮上したら再検討）
```

##### ❯ （ｂ）

```
⏺ brief.md に「Design phase 持ち越し項目」セクションを新設して軽微 3 件を記録する。追加内容は以下:

  - F-1（軽微）: コンポーネント命名のばらつき。R4.1-4.6 のみ subject = the Dangerous Operation Guide、他全 AC は the Lifecycle Manager。意図的な component 分離か統一すべきか design phase で判断。
  - F-2（中重要度）: R7.2 の task_type enum 拡張余地。現状 4 種固定（edge_followup / backlink_update / manual_review / reactivation_check）。design phase で「初期セット 4 種、追加可」の方針を検討。
  - F-3（軽微）: R9.3 と R11.6 の Backlink 走査範囲統一表現。Page 用 = wiki/**/*.md + raw/**/*.md、Skill 用 = 上記 + AGENTS/**/*.md。design phase で走査範囲の統一表現を検討。

  加えて、第 1 ラウンドで本文修正に伴って発生した「design phase 持ち越し項目」も同じセクションに記録する:

  - R6.9 由来: Skill lifecycle 拡張 2 種（skill deprecate / skill archive）の危険度・対話ガイド要否・--auto 可否を design phase で確定（Spec 4 R13.7と整合、drafts D-8 Adjacent Sync 後に drafts §7.2 Spec 7 の Dangerous op の分類表へ反映可）
  - R13.7 由来: cmd_promote_to_synthesis(candidate_path, target_path, merge_strategy, target_field) の signature と判定アルゴリズム詳細を design phase で確定
  - R15.3 由来: L3 診断 API の名前 / signature / 返り値スキーマの確定（Spec 5 R20.8 と並列構造）

  Edit してよいか?
```

##### ❯ OK

```
⏺ brief.md に「Design phase 持ち越し項目」セクションを追加完了。軽微 3 件 + 第 1 ラウンドで発生した持ち越し 3 件 = 計 6 件を記録した。

  第 1 ラウンドが完了したので、第 2 ラウンドに進む。

  ---
  第 2 ラウンド: roadmap.md / brief.md 厳格照合

  このラウンドの目的:

  - brief.md の Scope.In 全項目が requirements でカバーされているか（網羅性）
  - brief.md の Scope.Out が requirements の Out of scope と一致しているか
  - roadmap.md の Spec 7 dependency / coordination が requirements に反映されているか
  - brief.md の Constraints / Boundary Candidates が requirements で具体化されているか

  ラウンド開始してよいか?
```

##### ❯ OK

```
⏺ 第 2 ラウンド結果: roadmap.md / brief.md 厳格照合

  A. brief.md Scope.In の網羅性 → ✅ 全項目カバー済

  - Page status 状態遷移（5 種 + active 復帰）→ R1 / R10
  - Page lifecycle と Edge lifecycle の相互作用 → R3 / R12
  - Dangerous op 8 段階共通チェックリスト → R4
  - 操作固有ガイド → R5
  - Follow-up タスク仕組み → R7
  - 警告 blockquote 自動挿入 → R8
  - Backlink 更新 → R9
  - Simple dangerous ops（unapprove / reactivate）→ R10
  - Skill lifecycle → R11

  B. brief.md Scope.Out / Out of Boundary の整合性 → ✅ 整合

  - 個別タスクの出力（他 spec）→ Boundary Out of scope に「個別 CLI コマンドの dispatch」「Skill 内容」「Hypothesis 生成」等で対応
  - Edge lifecycle の進化則（Spec 5）→ Boundary Out of scope L49 で対応
  - Edge status の定義と遷移（Spec 5）→ Boundary Out of scope L49 で対応

  requirements.md の Boundary Out of scope は brief.md より詳細に 10 項目を列挙、隙間なく分割済み

  C. brief.md Coordination 必要事項 → ✅ 整合

  - Spec 7 ↔ Spec 5（Page deprecation → Edge demotion）→ R3 / R12 で具体化（C-3 で R12.7 追加済）
  - Spec 7 ↔ Spec 4（dangerous op CLI ハンドラの呼出規約）→ R13（C-1 で R13.7 追加済）

  D. roadmap.md L37 dependency / L54 phase / L87 coordination → ✅ 整合

  - dependency = foundation, classification（Spec 4 並列可）→ requirements.md Adjacent expectations で明示
  - Phase 2 = Spec 4 → Spec 7 の順 → TODO_NEXT_SESSION の進行順と一致
  - Spec 5 ↔ Spec 7 coordination = Page deprecation → Edge demotion → R3 / R12 で対応

  E. roadmap.md「v1 から継承する技術決定」の整合性

  - Severity 4 水準（CRITICAL / ERROR / WARN / INFO）→ R16.6 / R1.3 / R1.5 / R10.5 / R15.5 で参照 ✅
  - Exit code 0/1/2 分離 → R16.6 / R13.2 で参照 ✅
  - LLM CLI subprocess timeout 必須 → R16.6 で参照 ✅
  - モジュール責務分割 → 本 spec では言及なし、design / implementation phase で適用 → 言及不要（既存 spec のパターンと整合）
  - CLI 命名統一（rw symlink）→ R13.3 で「Spec 4 所管」として明示 ✅

  F. brief.md Constraints の具体化 → ✅ 整合

  - v2 には 2 種類の lifecycle が並立 → R12 / Boundary で明示
  - Page status 5 種 → R1 / R14.2（旧 R14.2 = R16.2）で固定
  - Dangerous op 13 種の分類 → R6.1（drafts §7.2 表 SSoT 引用）
  - --auto 不可 5 種 → R6.4 で固定（retract / split / tag split / skill retract / promote-to-synthesis）
  - 8 段階チェックリスト共通 → R4.2 で 8 項目固定
  - ディレクトリ移動なし → R1.6 で固定
  - Backlink 更新は wiki merge / deprecate 時に必須 → R9.1 / R9.2 / R9.7 で固定
  - Skill lifecycle も同じ pattern → R11.2 で固定

  G. 第 2 ラウンド観察事項（指摘ではない）

  - G-1: brief.md L67 の「Existing Spec Touchpoints: Extends なし、Adjacent v1 cli-audit（参照のみ）」が requirements.md に言及なし → v2
  新規実装の既知事実なので requirements で言及不要、観察のみ
  - G-2: roadmap.md L130-152 の v1 継承事項のうち「モジュール責務分割」「CLI 命名統一」は design / implementation phase で適用される事項のため
  requirements で直接言及不要 → 観察のみ

  第 2 ラウンド総括

  - 指摘なし。brief.md / roadmap.md と requirements.md の網羅性・境界・Coordination・継承事項はすべて整合
  - 第 1 ラウンドで適用した致命級 5 件 + 重要級 3 件の修正により、Coordination 関連の対応漏れも解消済
  - 観察事項 G-1 / G-2 は requirements 修正不要、design phase で自然に扱われる範囲

  ---
  第 2 ラウンドはクリーン。第 3 ラウンド（本質的観点 = 致命的 / 重要 / 中重要度 / 軽微の見直し）に進んでよいか?
```

##### ❯ OK

```
⏺ 第 3 ラウンドは「設計の本質的問題」「将来 trap になる構造」を探す視点で読み直した。致命級 3 件・重要級 3 件・中重要度/軽微 5 件を抽出した。

  ---
  第 3 ラウンド: 本質的観点の指摘事項

  致命級候補

  第 3-1 (致命級): partial failure 時の exit code が未定義

  - R3.4: Page→Edge orchestration 部分失敗時は「frontmatter 維持、edge 操作 rollback せず、follow-up 化」と規定
  - R13.2: 「exit code を Spec 4 の CLI dispatch が利用可能な形で提供」と書くが、partial failure 時の exit code 値が未定義
  - 問題: ユーザーには「Page deprecated 完了」と見えるが Edge は半分だけ demote / 残りは follow-up → exit 0（PASS）か exit 1（runtime error）か exit
  2（FAIL 検出）か曖昧
  - 修正案: R3.4 または R13.2 に「partial failure 時は exit 1（runtime error）を返し、follow-up 生成件数を JSON 出力に含める」と AC 追加

  第 3-2 (致命級): 8 段階対話の途中キャンセル時の状態確定タイミングが未明示

  - R6.4 / R4.2 で 8 段階対話の必須経由を規定するが、各段階の状態確定タイミングが AC で未規定
  - 問題: ユーザーが step 5（参照元の個別判断）で Ctrl+C キャンセルした場合、frontmatter は変更されているか? 暗黙の前提は「approve(step 8) 完了まで
  frontmatter 変更なし」だが明示されていない
  - リスク: 実装者が「step 4 までで pre-flight 結果を frontmatter に保存」のような中間状態を作ると、キャンセル時に破損状態が残る
  - 修正案: R4 または R6 に「8 段階対話の step 8 (approve) 完了までは frontmatter / Edge 状態は変更しない（pre-flight check / 差分プレビューは
  read-only 操作）。途中キャンセル時は状態整合性が保たれる」と AC 追加

  第 3-3 (致命級): Backlink 更新時の .hygiene.lock 取得規定が不在

  - R9.1 / R9.2 で Backlink 更新（wiki / raw markdown 走査と追記）
  - Foundation R11.5 / Spec 4 R10.1 で .hygiene.lock 取得が規定済（vocabulary 編集、L2 edge 操作等）
  - 問題: Backlink 更新中に他プロセスが該当ページを編集すると衝突。lock 取得の規定が本 spec にない
  - 修正案: R9 または R3 に「Page→Edge orchestration / Backlink 更新の実行中は .rwiki/.hygiene.lock を取得し、Spec 4 R10.1 / Spec 5 R17 と整合する
  concurrency 制御を行う」と AC 追加

  重要級候補

  第 3-4 (重要級): R8.4 の [!INFO] blockquote が GFM 標準外

  - R8.4: merge 時に > [!INFO] Merged\n> このページは... を挿入
  - 問題: GitHub Flavored Markdown の callout は [!NOTE] / [!TIP] / [!IMPORTANT] / [!WARNING] / [!CAUTION] の 5 種固定。[!INFO] は GitHub で通常の
  blockquote として render される（警告として目立たない）
  - 修正案: R8.4 の [!INFO] Merged を [!NOTE] Merged に変更（または [!IMPORTANT] Merged）

  第 3-5 (重要級): successor: 循環の事前チェックなし

  - R15.1 / R15.5 で deprecated chain 循環検出を診断 API として提供
  - 問題: 循環は検出するが、deprecate 時の事前チェック（successor 設定時に循環を作らないか確認）が未規定
  - リスク: ユーザーが手動で frontmatter を編集して循環を作ると、診断で検出されるまで気づかない
  - 修正案: R8 または R5 の deprecate-guide.md 操作固有ガイドに「successor の事前 cycle check（pre-flight 段階）」を AC として追加

  第 3-6 (重要級): archived → deprecated 遷移の意図確認

  - R1.2: archived → {active（reactivate）, retracted} のみ → archived → deprecated は不可
  - 問題: ユーザーが archived のページを deprecated にしたい場合、archived → active (reactivate) → deprecated の 2 段階遷移が必要 → 運用上の煩雑さ
  - 意図確認: 「archived は完全な履歴扱いで変更しない」という設計判断は妥当（drafts §7.2 表とも整合）。ただし brief.md / requirements で「archived
  は意図的に終端状態」と明示されていない
  - 修正案 (a): R1.2 のコメントに「archived は終端的 lifecycle 状態（変更時は reactivate を経由）」を補足
  - 修正案 (b): 現状維持、設計意図は brief 持ち越し

  中重要度・軽微（簡潔列挙、brief 持ち越し候補）

  - 第 3-7 (中): update_history / status_changed_at の精度が YYYY-MM-DD（同日複数 op の順序が不明）→ design phase で順序保証メカニズムを検討
  - 第 3-8 (中): Follow-up タスクの長期 GC 機構未規定 → resolved / dismissed の archive メカニズムを design phase で検討
  - 第 3-9 (中): promote-to-synthesis = 最高危険度に対する追加ゲート（2 名 approve / audit 実行ゲート等）の要否 → design phase で判断
  - 第 3-10 (中): Follow-up id の unique 保証メカニズム未規定 → design phase
  - 第 3-11 (軽微): R6.5 の --auto 不可指定操作に --auto 渡された場合の severity = INFO は控えめ、WARN が妥当か → 軽微

  第 3 ラウンド総括

  - 致命級 3 件: requirements レベルで AC 追加が必要
  - 重要級 3 件: 2 件は requirements 修正、1 件は意図確認
  - 中重要度・軽微 5 件: design phase 持ち越し / brief 追記候補

  ---
  致命級 3 件から順次ステップバイステップで進めますか?

  - (a) 致命級 3 件 → 重要級 3 件 → 中重要度・軽微の brief 持ち越しの順で個別判断
  - (b) 致命級 3 件のみ判断、重要級以下は brief 持ち越しでまとめて記録
  - (c) 第 3 ラウンド全体を再検討（指摘の優先度を見直し）
```

```
⏺ 第 3-1 (致命級): partial failure 時の exit code が未定義

  状況

  - R3.4: Page→Edge orchestration 部分失敗時は「frontmatter 維持、edge 操作 rollback せず、follow-up 化」と規定済
  - R13.2: 「exit code を Spec 4 の CLI dispatch が利用可能な形で提供」と規定済
  - 不在: partial failure 時の exit code 値（0 / 1 / 2 のどれを返すか）の規定

  修正案候補

  案 1: R3 に新 AC 追加（推奨）

  R3.4 の隣接位置に新 R3.5 を追加（既存 R3.5-3.7 を 1 つずつ shift）、または R3.4 に文言を追記。

  追記文言案:

When Page→Edge orchestration が rollback 不能な部分的失敗を起こした, the Lifecycle Manager shall handler の exit code を 1（runtime error、roadmap.md「v1 から継承する技術決定」/ Spec 4 Requirement 4 と整合）として返し、JSON 出力に partial_failure: true / successful_edge_ops:
<count> / failed_edge_ops: <count> / followup_ids: [<id>...] を含めることを規定する。

  案 2: R13 に新 AC 追加

  R13.2 の exit code 規定を強化、または新 AC で partial failure 時の挙動を規定。

  メリット (案 1)

  - 失敗 / partial failure / 成功 の 3 状態を exit code で区別できる
  - Spec 4 R4 / Spec 6 等が dispatch 結果を判定する際に明確
  - followup_ids を JSON に含めることで、ユーザーが事後対応すべき task が即座にわかる

  デメリット (案 1)

  - exit 1 を「partial failure」に流用すると、本来の「runtime error（コマンド実行不能 / 例外）」と混同する余地がある
  - exit 2（FAIL 検出）との区別が必要なら独自の exit code を定義する案もあるが、roadmap.md の「v1 から継承する技術決定」に逸脱する

  案 3: exit 2 を返す

  - partial failure を「FAIL 検出」と解釈し exit 2 を返す
  - メリット: runtime error（exit 1 = subprocess timeout / I/O error 等）と区別される
  - デメリット: 「FAIL 検出」は audit / lint 等の検出系コマンドに使う規約で、partial failure に使うと意味が拡張される

  推奨

  案 1（exit 1 + JSON 出力強化） を推奨。理由:

  - partial failure は実質「dangerous op の一部が runtime error で失敗」の状態であり、exit 1 が意味的に妥当
  - exit 2 を partial failure に使うと audit / lint の「FAIL 検出」と意味が混在する
  - JSON 出力で詳細を返すパターンは Spec 4 R15.10 / Spec 5 design と整合

  修正案 1 で Edit してよいか?
```

##### ❯ OK

```
 第 3-1 修正完了。R3 が 7 AC → 8 AC。

  ---
  第 3-2 (致命級): 8 段階対話の途中キャンセル時の状態確定タイミングが未明示

  状況

  - R6.4 / R4.2 で 8 段階対話の必須経由を規定済
  - 不在: 各段階での状態確定タイミング（frontmatter / Edge 状態の変更がどの段階で起きるか）の AC 規定
  - 暗黙の前提: 「step 8 (approve) 完了まで状態変更なし」だが明示されていない

  修正案候補

  案 1: R4 に新 AC 追加（推奨）

  R4 の末尾（R4.6 の後）に新 R4.7 を追加。

  追記文言案:

  ▎ The Dangerous Operation Guide shall 8 段階対話の step 1〜7（意図確認 → 現状把握 → 依存グラフ解析 → 代替案提示 → 各参照元の個別判断 → Pre-flight
  ▎ warning → 差分プレビュー生成）を read-only 操作として実装 することを規定し、frontmatter 編集 / Edge 状態変更 / Backlink 追記 / update_history
  ▎ 追記 / decision_log 記録 / Follow-up 生成等の永続的副作用は step 8 (approve) 完了後に一括実行する。途中キャンセル（Ctrl+C / プロセス終了 / chat
  ▎ セッション中断等）時は永続化前のため状態整合性が保たれることを保証する。

  メリット (案 1)

  - 8 段階対話の途中キャンセル時の安全性が要件レベルで保証される
  - 実装者が「中間状態を保存」する設計を排除できる（明示的禁止）
  - R6.4 の対話強制と整合

  デメリット (案 1)

  - 「pre-flight warning」「差分プレビュー生成」が完全に read-only かは設計判断（例: 差分プレビューを .rwiki/cache/ に書き出す実装は許容するか）→「永続的副作用」の解釈に幅
  - 一括実行の atomicity（fsync / トランザクション境界）は別途 design phase で詳細化が必要

  案 2: R6 に新 AC 追加

  R6（Dangerous op 13 種の分類）に「途中キャンセル時の整合性」AC を追加。R4 ではなく R6 にすることで、handler 動作要件の文脈で扱う。

  メリット (案 2)

  - handler の動作要件としての文脈に置かれる（R6 が handler 動作要件のため）

  デメリット (案 2)

  - R4 が 8 段階対話の文脈、R6 が分類の文脈なので、整合性規定は R4 の方が自然

  案 3: 両方に分散

  - R4: ガイド側の規定（step 1〜7 = read-only）
  - R6: handler 側の規定（step 8 完了まで永続的副作用なし）

  推奨

  案 1（R4 に新 R4.7 追加） を推奨。理由:

  - 8 段階対話のセマンティクスは R4（共通チェックリストガイド）の所管
  - handler 実装側からの視点も同一規定で網羅できる（read-only step 1〜7 → step 8 で永続化）
  - 修正範囲が最小（R4 のみ +1 AC）

  修正案 1 で Edit してよいか?
```

##### ❯ OK

```
 第 3-2 修正完了。R4 が 6 AC → 7 AC。

  ---
  第 3-3 (致命級): Backlink 更新時の .hygiene.lock 取得規定が不在

  状況

  - R9.1 / R9.2 で Backlink 更新（wiki / raw markdown 走査と追記）を規定
  - Foundation R11.5 / Spec 4 R10.1 で .hygiene.lock 取得が確立済（vocabulary 編集、L2 edge 操作等）
  - 不在: Backlink 更新 / Page→Edge orchestration 中の .hygiene.lock 取得 AC
  - 第 3-2 で「step 8 完了後に一括実行」を規定したため、この一括実行中に concurrent edit が起きるリスク

  修正案候補

  案 1: R3 / R9 / R8 に lock 取得 AC を分散追加

  各 Requirement に個別の lock 取得 AC を追加。

  デメリット

  - 同じ規定が 3 箇所に重複、メンテ負荷増

  案 2: 新 Requirement を追加（concurrency 制御）

  新 Requirement 17（Foundation 規範を R16 に rename したのでさらに rename 要）として「concurrency 制御と .hygiene.lock 取得規約」を追加。

  デメリット

  - Requirement 数が 16 → 17 に増える、現 R16 を R17 に rename
  - C-2 の追加に続いて 2 度目の rename 発生

  案 3: R3 に集約 AC 追加（推奨）

  R3（Page→Edge 相互作用 orchestration）に新 AC として「8 段階対話の step 8 一括実行中は .rwiki/.hygiene.lock を取得し、Backlink 更新 / Edge
  orchestration / blockquote 挿入を一連の lock 範囲内で実行」を追加。

  R3 が Page→Edge orchestration の中核 Req のため、ここで lock 取得を集約規定する。

  追記文言案:

  ▎ The Lifecycle Manager shall 8 段階対話の step 8 (approve) 完了後の一括実行（frontmatter 編集 / Edge 状態変更 / Backlink 追記 / update_history
  ▎ 追記 / 警告 blockquote 挿入 / Follow-up 生成等）の前に .rwiki/.hygiene.lock を取得し、一括実行完了後に解放することを規定する（Foundation
  ▎ Requirement 11.5 / Spec 4 Requirement 10.1 / Spec 5 Requirement 17 と整合）。lock 取得失敗時は handler の exit code を 1（runtime
  ▎ error）として返し、JSON 出力に lock_acquisition_failed: true / lock_holder_pid: <pid> を含めることを規定する（Requirement 3.8 と整合）。Simple
  ▎ dangerous op（rw unapprove / rw reactivate、Requirement 10）も同様に lock 取得を経由する。

  メリット (案 3)

  - lock 取得の規定が R3 に集約され、関連 AC（R3.7 = decision_log 記録、R3.8 = exit code）と論理的に隣接配置
  - Foundation R11.5 / Spec 4 R10.1 / Spec 5 R17 との coordination が明示
  - Simple dangerous op も同じ lock 規約に取り込み、一貫性確保

  デメリット (案 3)

  - R3 のスコープが「Page→Edge orchestration」から「+ concurrency 制御」へ拡張する → ただし両者は密接（lock なしで orchestration できない）

  推奨

  案 3（R3 に集約 AC 追加） を推奨。理由:

  - 修正範囲が最小（R3 のみ +1 AC）
  - lock 取得の規定が一箇所に集約され、メンテしやすい
  - 第 3-1 (R3.8 exit code) と論理的に隣接、R3.7 (decision_log) / R3.8 (exit code) / R3.9 (lock) の 3 つで partial failure ハンドリングを完結

  修正案 3 で Edit してよいか?
```

##### ❯ OK

```
 承知しました。再提示します。

  第 3-4 (重要級): R8.4 の [!INFO] blockquote が GFM 標準外

  状況

  - R8.4: merge 時に > [!INFO] Merged\n> このページは {status_changed_at} に {merged_into} へ merge されました。strategy: {merge_strategy} を merged_from 側ページに自動挿入する
  - R8.1 / R8.2 / R8.3 はそれぞれ [!WARNING] / [!CAUTION] / [!NOTE] を使用、これらは GitHub Flavored Markdown (GFM) の callout 標準仕様で renderされる
  - R8.4 のみ [!INFO] を使用、GFM 標準の callout type には含まれない（GFM 公式 5 種は [!NOTE] / [!TIP] / [!IMPORTANT] / [!WARNING] / [!CAUTION]）

  何が問題なのか

  - GitHub Web で render したとき、[!INFO] は callout として解釈されず、通常の blockquote として表示される
    - GFM の callout が render されると、左端のカラーバー / アイコン / type ラベル（強調太字）が表示される視覚効果が得られる
    - [!INFO] は GitHub に認識されないため、> [!INFO] Merged は単に「[!INFO] Merged」というテキスト付きの blockquote として表示され、視認性が低下する
  - merged ページは過去のリンクから訪問される導線が主（R2.5 で Query / Distill 対象から除外、能動的な検索で到達することはない）
    - merged blockquote の役割は「古いリンクで訪問したユーザーに merged_into への誘導を視覚的に伝える」こと
    - callout として render されないと「merge された旨と誘導」が単なる blockquote に埋もれ、誘導の意図が弱まる
  - R8.1-3 が GFM 標準準拠なのに R8.4 のみ非標準
    - 同じ R8 内で render 挙動が分散する
    - 将来 GitHub UI が [!INFO] を独自対応する可能性は低く、放置すると永続的に「merged blockquote だけ視覚的に弱い」状態になる
  - エディタ依存の互換性問題
    - Obsidian などは独自に [!info] をサポートするが、Rwiki の wiki/ は drafts §8 で「Obsidian は参照実装、wiki/ の閲覧は GitHub Web も含む」前提
    - 特定エディタ依存の callout を採用すると、責務分離原則に反する

  修正案候補

  案 1: [!NOTE] Merged に変更（推奨）

  merge 後の誘導は archived と同じ「履歴扱い + 情報提供」のセマンティクスなので [!NOTE] が妥当。

  - メリット: archived（R8.3 = [!NOTE] Archived）と同レベルの控えめな notice、merged の本来意味（後継へ移った情報提供）と一致
  - デメリット: archived と同じ render になるので「視覚的に区別が付きにくい」点はある（ただしテキスト本文で type
  名「Merged」を明示するため誤読は起きない）

  案 2: [!IMPORTANT] Merged に変更

  merge は強い lifecycle 変更で利用者に必ず気づかせたい場合。

  - メリット: deprecated（R8.1 = [!WARNING] 中位）と retracted（R8.2 = [!CAUTION] 上位）の中間レベルとして強調できる
  - デメリット: 「重要」の感覚的強度が高く、merged 自体は悪い変更ではない（後継に統合されただけ）ので過剰な強調

  案 3: [!WARNING] Merged に変更

  deprecated と同レベルの注意喚起にする。

  - メリット: 「使うべきでない」レベルとしては deprecated と類似
  - デメリット: deprecated は「将来削除されうる」意味、merged は「後継に統合済み（不可逆、R1.2）」意味で本質が異なる → 混乱の余地

  推奨

  案 1（[!NOTE] Merged）。理由:

  - archived と同じ「履歴扱い」のセマンティクスで一貫し、GFM 標準準拠
  - merged は Query 対象外（R2.5）で能動的な検索で到達されないため、強い警告は不要
  - 修正規模は最小（1 文字列置換）

  修正案 1 で Edit してよいか?
```

##### ❯ OK

```
⏺ 第 3-4 修正完了。

  ---
  第 3-5 (重要級): successor: 循環の事前チェックなし

  状況

  - R15.1 / R15.5 で deprecated chain 循環検出を診断 API として提供（実装済 = rw doctor の L3 診断項目の (c) deprecated chain 循環）
  - R5.1: deprecate-guide.md 操作固有ガイドの作成・維持を規定
  - R5.2: 操作固有ガイドの 4 項目（Pre-flight チェック項目 / 警告 blockquote 文言テンプレート / 代替案候補 / 典型的な拒否理由）に「Pre-flight チェック項目」が含まれる
  - 不在: deprecate handler の Pre-flight 段階で「successor 設定が循環を作らないかの事前チェック」AC

  何が問題なのか

  - 循環は事後検出のみ → 検出されるまで気づかない
    - 例: page A deprecated, successor = B → B deprecated, successor = C → C deprecated, successor = A という循環を作っても、deprecate
  コマンド自体は成功して止まらない
    - rw doctor 実行時または事故発生後に初めて検出される
    - 利用者が successor を辿った場合、永遠にループする UX 障害が起きる
  - 8 段階対話の Pre-flight warning (step 6) が機能不足
    - R4.2 で 8 段階対話の step 6 = Pre-flight warning と規定済
    - step 6 で循環チェックを行う規定があれば、approve 前に拒否できる（第 3-2 の R4.7 で「step 1〜7 は read-only」と規定したため、循環チェックは read-only として step 6 に組み込み可能）
    - しかし R5 / R8 / R15 のいずれも「deprecate handler の Pre-flight 段階で循環チェック」を AC として規定していない
  - R10.2 の rw reactivate でも同様の問題
    - reactivate 時に successor を持つページの状態が active に戻ると、successor field の整合性確認が必要
    - 同様の Pre-flight チェックが reactivate にも必要

  修正案候補

  案 1: R5 (操作固有ガイド) に新 AC 追加（推奨）

  R5.2 の操作固有ガイド 4 項目に「Pre-flight チェック項目」が含まれているため、deprecate-guide.md の Pre-flight チェック項目に「successor 設定が循環を作らないかの事前チェック」を必須項目として明示する AC を追加。

  追記文言案（新 R5.6）:

  ▎ The Lifecycle Manager shall deprecate-guide.md の Pre-flight チェック項目に「successor 設定が deprecated chain
  ▎ 循環を作らないかの事前チェック（既存 deprecated ページの successor field を辿り、循環検出時は ERROR severity で operation
  ▎ を拒否）」を必須項目として規定し、Requirement 15.5 の事後検出 API（rw doctor 経由）と独立した事前防止メカニズムとして機能させる。merge-guide.md
  ▎ でも同様に「merged_from / merged_into の循環チェック」を必須 Pre-flight 項目として規定する。

  メリット (案 1)

  - Pre-flight 段階（step 6）で循環を事前防止、rw doctor の事後検出と二重防御
  - merge-guide.md にも同パターンを適用、merge 系の循環も予防
  - R5.2 の既存「Pre-flight チェック項目」枠内での規定で、操作固有ガイドの責務分離と整合
  - R15 の事後検出 API は維持（手動 frontmatter 編集による循環は事後検出が必要）

  デメリット (案 1)

  - R5 が 5 AC → 6 AC に増える（軽微）
  - 循環チェックアルゴリズム詳細は design phase 持ち越し（ただし計算 API は R15 が所管なので呼び出すだけで実装はシンプル）

  案 2: R15 に新 AC 追加（事前チェック API も提供）

  R15 に「事前チェック API（cycle pre-check）も提供」と AC 追加。

  デメリット (案 2)

  - R15 のスコープが「診断 API」から「+ 事前チェック API」へ拡張
  - handler 側でこの API を呼び出す責務を別 AC で規定する必要 → 規定が分散

  案 3: 両方追加

  R5.6（ガイド側）+ R15.6（API 側）。最も網羅的だが過剰。

  推奨

  案 1（R5.6 追加）。理由:

  - 操作固有ガイドは Pre-flight チェック項目を含む既存設計（R5.2）と整合
  - R15 の事後検出 API を呼び出す形で実装可能（API 重複なし）
  - merge-guide.md にも同パターンを適用してカバレッジ拡大
  - 修正範囲が最小（R5 のみ +1 AC）

  修正案 1 で Edit してよいか?
```

##### ❯ OK

```
⏺ 第 3-5 修正完了。R5 が 6 AC → 7 AC。

  ---
  第 3-6 (重要級): archived → deprecated 遷移不可の意図確認

  状況

  - R1.2: archived → {active（reactivate）, retracted} のみ
  - 不可: archived → deprecated / archived → merged
  - archived のページを deprecated にしたい場合、archived → active (reactivate) → deprecated の 2 段階遷移が必要

  何が問題なのか

  - 意図の不明示: archived は終端状態（変更時は reactivate を経由）という設計判断が requirements に明文なし
  - 運用上の煩雑さ: archived のページを「やっぱり deprecated として明示したい」場合、reactivate して active に戻してから deprecateする必要があり、update_history に2 イベント分が記録される（R1.8 / R8 の自動追記対象）
  - ただし設計判断としては妥当: archived は「履歴扱い、Query 履歴として検索可（R2.4）」のセマンティクスで、警告 blockquote は [!NOTE] Archived の控えめな表記。直接 deprecated に遷移可能にすると「archived の履歴扱い」と「deprecated の警告扱い」のセマンティクスが混乱する

  修正案候補

  案 1: R1.2 にコメント補足を追加（推奨）

  R1.2 の遷移表に「archived は終端的 lifecycle 状態」の補足を追加。

  追記文言案:

  ▎ The Lifecycle Manager shall 各 status の遷移先を以下のとおり規定する: active → {deprecated, retracted, archived, merged} / deprecated →
  ▎ {active（reactivate）, retracted, archived, merged} / archived → {active（reactivate）, retracted} / retracted → {}（不可逆、git revert
  ▎ のみで戻る）/ merged → {}（不可逆、git revert のみで戻る）。archived は意図的に終端的 lifecycle 状態として設計され、deprecated / merged
  ▎ への直接遷移は不可とする（変更時は rw reactivate で active に戻してから別の lifecycle 操作を実行する 2 段階運用を採る）。これにより archived
  ▎ の「履歴扱い、Query 履歴として検索可」（Requirement 2.4）セマンティクスと deprecated / merged の警告セマンティクスが意味的に分離される。

  メリット (案 1)

  - 設計判断が requirements レベルで明文化、将来の改版者・実装者が意図を誤解しない
  - 運用上の 2 段階遷移要求が明示され、ユーザーガイドに反映できる
  - archived の「履歴扱い」と deprecated / merged の「警告扱い」の分離が強化

  デメリット (案 1)

  - R1.2 が長くなる（既存の長文 AC スタイルなので大きな問題ではない）

  案 2: 現状維持、brief.md に意図記録

  requirements は現状のまま、brief.md の Constraints に「archived は終端的 lifecycle 状態」を追記。

  メリット (案 2)

  - requirements の変更なし
  - 設計意図が brief.md に残る

  デメリット (案 2)

  - requirements から brief.md を辿らないと意図がわからない
  - 将来の design phase / implementation phase で意図が見落とされるリスク

  案 3: archived → deprecated を許可

  設計を変更して archived → deprecated を許可。

  デメリット (案 3)

  - 「archived は履歴扱い」のセマンティクスが崩壊
  - 警告 blockquote が混在する状態が発生（archived の [!NOTE] から deprecated の [!WARNING] への置換）
  - drafts §7.2 表 / Foundation R5 の Page status 5 種の意味が曖昧化
  - 大きな設計変更で他 spec への波及リスク

  推奨

  案 1（R1.2 に補足追加）。理由:

  - 設計判断を requirements で明文化、意図を後世に伝える
  - 運用上の 2 段階遷移を要件レベルで明示
  - archived のセマンティクス（履歴扱い）を強化

  修正案 1 で Edit してよいか?
```

##### ❯ OK

```
 第 3-6 修正完了。致命級 3 件 + 重要級 3 件すべて完了。

  ---
  第 3 ラウンド 中重要度・軽微 5 件の brief 持ち越し

  残り 5 件は brief.md の「Design phase 持ち越し項目」セクションに追加する。

  追加内容（5 件）

  - 第 3-7 (中重要度): update_history / status_changed_at の精度が YYYY-MM-DD（同日複数 op の順序が不明）→ design phase
  で順序保証メカニズム（timestamp / sequence number 等）を検討
  - 第 3-8 (中重要度): Follow-up タスクの長期 GC 機構未規定 → design phase で resolved / dismissed の archive メカニズム（wiki/.follow-ups/.archived/
   等）を検討
  - 第 3-9 (中重要度): promote-to-synthesis = 最高危険度に対する追加ゲート（2 名 approve / audit 実行ゲート等）の要否 → design phase で判断、現状は 8
   段階対話 + --auto 不可で十分か再評価
  - 第 3-10 (中重要度): Follow-up id の unique 保証メカニズム未規定（現状 R7.2 で「unique 文字列」とのみ規定）→ design phase で採番方式（UUID /
  <date>-<seq> 等）と衝突時の挙動を確定
  - 第 3-11 (軽微): R6.5 の --auto 不可指定操作に --auto 渡された場合の severity = INFO は控えめ、WARN が妥当か → 軽微、design phase で再評価可

  Edit 内容

  brief.md の既存「Design phase 持ち越し項目」セクション末尾に「### 第 3 ラウンドで発生した持ち越し」サブセクションを追加して 5 件を記録。

  Edit してよいか?
```

##### ❯ OK

```
⏺ brief.md に第 3 ラウンドで発生した持ち越し 5 件を追加完了。

  ---
  第 3 ラウンド完了サマリ

  修正適用 6 件:

  - 第 3-1（致命級）: R3.8 新設 — partial failure 時の exit code = 1 + JSON 出力強化
  - 第 3-2（致命級）: R4.7 新設 — 8 段階対話の step 1〜7 を read-only、step 8 で一括実行
  - 第 3-3（致命級）: R3.9 新設 — .hygiene.lock 取得規定
  - 第 3-4（重要級）: R8.4 修正 — [!INFO] → [!NOTE] (GFM 標準準拠)
  - 第 3-5（重要級）: R5.7 新設 — successor: 循環の事前 Pre-flight チェック
  - 第 3-6（重要級）: R1.2 補足 — archived 終端状態の意図明文化

  brief 持ち越し 5 件:

  - 第 3-7 / 3-8 / 3-9 / 3-10 / 3-11（中重要度・軽微）

  現状の AC 数:

  - R1: 8 AC（D-2 で +1）
  - R3: 9 AC（C-3 で +1、3-1 で +1、3-3 で +1）
  - R4: 7 AC（3-2 で +1）
  - R5: 7 AC（3-5 で +1）
  - R6: 9 AC（A-1 で +1）
  - R12: 7 AC（C-3 で +1）
  - R13: 7 AC（C-1 で +1）
  - R15（新）: 5 AC
  - R16（旧 R14）: 9 AC

  第 4 ラウンド（B 観点 = failure mode / 並行 / セキュリティ / 国際化 / 観測可能性 / 可逆性 / 規模 / 暗黙前提崩壊）に進んでよいか?
```

##### ❯ OK

```
⏺ 第 4 ラウンド: B 観点 — failure mode / 並行 / セキュリティ / 観測 / 可逆性 / 規模 / 暗黙前提

  第 1-3 ラウンドで触れなかった観点を中心に確認した。致命級 1 件・重要級 3 件・中重要度/軽微 6 件を抽出。

  致命級候補

  第 4-1 (致命級): edge API 呼出の timeout 規定が不在

  - 状況: R12.4 で edge API は「同期 API として提供される前提」と規定済、R3.1-3.3 で edge demote / reject / reassign の呼出を規定
  - 不在: edge API 呼出自体の timeout 規定（応答しない場合の handling）
  - 問題:
    - Spec 5 が L2 ledger 操作を同期 API として提供する前提だが、edges.jsonl が大規模化（>10,000 entries）すると I/O が遅延する可能性
    - 第 3-3 (R3.9) で .hygiene.lock 取得失敗時の handling は規定したが、lock 取得後の edge API 呼出が応答しないケースは未対応
    - timeout がないと dangerous op が無限 hang する → ユーザーが Ctrl+C → R4.7「step 1〜7 は read-only」前提が崩壊（lock 取得済 → 解放されない）
  - 修正案: R3 または R12 に「edge API 呼出に timeout（design phase で値確定、roadmap.md「v1 から継承する技術決定」LLM CLI subprocess timeout
  必須と並列）を必須として規定し、timeout 発生時は partial failure として扱う（Requirement 3.4 / 3.8 と整合）」を追加

  重要級候補

  第 4-2 (重要級): step 8 で lock 取得後の pre-flight 再確認規定が不在

  - 状況: R4.7 で「step 1〜7 は read-only」、R3.9 で「step 8 完了後の一括実行前に lock 取得」と規定済
  - 不在: step 8 で lock 取得した時点で「step 1〜7 で行った pre-flight check が依然有効か」を再確認する規定
  - 問題:
    - step 1〜7 中（lock 未取得）に他プロセスが該当ページを編集した場合、step 7 で生成した差分プレビューが古い状態に基づく可能性
    - 古い差分プレビューに基づいて approve すると、想定外の状態に遷移する
  - 修正案: R3.9 または R4.7 に「step 8 で lock 取得直後に pre-flight check (step 6) を再実行し、step 7
  で生成した差分プレビューが依然有効であることを確認。状態が変わっていた場合は ERROR severity で abort し、ユーザーに再実行を促す」を追加

  第 4-3 (重要級): Backlink 更新の全失敗 vs 一部失敗の区別なし

  - 状況: R9.5 で「Backlink 走査中に一部ページの更新が失敗した場合、操作全体を rollback せず follow-up 化、操作自体は完了として扱う」と規定
  - 不在: 全失敗（disk full / permission denied で全 markdown 更新失敗）の挙動
  - 問題:
    - 「一部失敗」と「全失敗」を同じ扱い（操作完了 + follow-up 化）にすると、disk full のような根本的問題が表面化しない
    - 全失敗時も「操作完了」と返すと、ユーザーは「Backlink 更新が成功した」と誤認
  - 修正案: R9.5 に「Backlink 走査対象が全数失敗した場合は ERROR severity で operation 自体を rollback し、frontmatter status 遷移と Edge
  orchestration を取り消す（lock 範囲内なので atomicity 保証可能、Requirement 3.9 と整合）」を追加

  第 4-4 (重要級): successor: 未指定時の blockquote / 動作が不明示

  - 状況: R8.1 で deprecate 時の blockquote に 後継: {successor のリスト、リンク形式} を含める規定
  - 不在: successor: field が未指定の deprecate 操作の挙動と blockquote 文言
  - 問題:
    - Spec 1 R3 で successor は schema 上 optional（任意指定）の可能性
    - successor 未指定で deprecate すると、blockquote の 後継: {successor のリスト} がどう render されるか不明（空配列 / null / 文言省略 / エラー）
    - ユーザー視点では「後継不明な deprecate」も実用シナリオ（API 廃止 → 後継未定 等）
  - 修正案: R8.1 に「successor 未指定時は blockquote に 後継: 未指定（後日設定可） を表示、または successor 行を省略する仕様を operation guide
  で明示。successor は optional であり deprecate 操作の必須要件ではない（status_reason のみ必須、Requirement 1.5 と整合）」を追加。または R1
  に「successor は optional」と明示

  中重要度・軽微（brief 持ち越し候補、6 件）

  - 第 4-5 (中): dangerous op 実行時の出力に「N 件の follow-up が生成されました」を明示する規定が薄い → design phase で出力フォーマット統一を検討
  - 第 4-6 (中): 全 dangerous op の reversibility 一覧が requirements 内に分散（R10.5 / R1.2 等）→ design phase で reversibility 表を生成（drafts
  §7.2 表に列追加 or 別表）
  - 第 4-7 (中): 大規模 Vault（>1,000 ページ）での Backlink 走査性能 → design phase で並列化 / cache 戦略を検討
  - 第 4-8 (中): rw follow-up list の pagination 規定なし → design phase で max_results / pagination を確定
  - 第 4-9 (軽微): status_reason / update_history.summary / Follow-up description の encoding 規定なし（UTF-8 前提が暗黙）→ design phase で明示
  - 第 4-10 (軽微): handler 引数の sanitization 規定なし → design phase で明示

  第 4 ラウンド総括

  - 致命級 1 件 + 重要級 3 件: requirements レベルで AC 追加が必要
  - 中重要度・軽微 6 件: brief 持ち越し

  ---
  致命級 1 件から順次ステップバイステップで進めますか?

  - (a) 致命級 1 件 → 重要級 3 件 → 中重要度・軽微の brief 持ち越しの順で個別判断
  - (b) 致命級 1 件のみ判断、重要級以下は brief 持ち越しでまとめて記録
  - (c) 第 4 ラウンド全体を再検討
```

##### ❯ a

```
⏺ 第 4-1 (致命級): edge API 呼出の timeout 規定が不在

  状況

  - R12.4 で edge API は「同期 API として提供される前提、orchestration が逐次呼出可能」と規定
  - R3.1-3.3 で edge demote / reject / reassign の呼出を規定
  - R3.9 で .hygiene.lock 取得失敗時の handling 規定済
  - R16.6 で「LLM CLI subprocess timeout 必須」を継承
  - 不在: edge API 呼出自体の timeout 規定（Spec 5 が同期 API として実装するが、応答しない場合の handling）

  何が問題なのか

  - edge API は LLM CLI ではなく Spec 5 の内部関数呼出 → R16.6 の「LLM CLI subprocess timeout」の対象外
  - edges.jsonl が大規模化（>10,000 entries）すると edge API の I/O が遅延する可能性
  - 第 3-3 (R3.9) で lock 取得後の edge API 呼出が応答しないケース未対応 → dangerous op が無限 hang
  - ユーザーが Ctrl+C → R4.7 の「step 1〜7 read-only、step 8 で一括実行」前提が崩壊（lock 取得済 → 解放されない、edge API
  呼出が中途半端な状態で中断）
  - partial failure として扱える timeout があれば R3.4 / R3.8 の handling パターンに自然に乗せられる

  修正案候補

  案 1: R12 に新 AC 追加（推奨）

  R12.4 の「同期 API 前提」規定の隣に、edge API 呼出 timeout を必須として規定する新 AC を追加。

  追記文言案（新 R12.8）:

  ▎ The Lifecycle Manager shall edge API（edge demote / edge reject / edge reassign 等）の各呼出に timeout を必須として規定し、timeout 値の確定は本
  ▎ spec の design phase の coordination 項目とする（roadmap.md「v1 から継承する技術決定」の LLM CLI subprocess timeout 必須と並列概念、ただし edge
  ▎ API は内部関数呼出のため値・実装機構は別系統）。timeout 発生時は当該 edge 操作を partial failure として扱い（Requirement 3.4 / 3.8
  ▎ と整合）、failed_edge_ops に計上して follow-up タスク化する。timeout 後は orchestration 全体を継続し、残りの edge 操作を順次実行する。

  メリット (案 1)

  - timeout が R3.4 / R3.8 の partial failure handling パターンに自然に統合される
  - edge API 呼出単位での timeout のため、1 つの edge が hang しても全体 orchestration は継続可能
  - timeout 値は design phase 持ち越し（実装複雑度の判断は後回し）
  - R12 の Spec 5 coordination の文脈に置かれる

  デメリット (案 1)

  - R12 が 7 AC → 8 AC に増える
  - timeout 値の確定が design phase 持ち越しのため、要件レベルでは抽象的

  案 2: R3 に新 AC 追加

  R3 (Page→Edge orchestration) に timeout AC を追加。

  メリット (案 2)

  - orchestration 文脈で timeout を扱う

  デメリット (案 2)

  - R3 が 9 AC → 10 AC で長くなる
  - API 仕様規定は R12 (Spec 5 coordination) の方が自然

  案 3: 別 Requirement で concurrency / timeout / 性能 をまとめる

  新 Requirement を追加（17 番）して edge API timeout / Backlink 走査 timeout / 大規模 Vault 性能 をまとめて扱う。

  デメリット (案 3)

  - Requirement 数が 16 → 17 に増える
  - 過剰な抽象化、現状の指摘 1 件には過剰設計

  推奨

  案 1（R12 に新 R12.8 追加）。理由:

  - edge API 仕様は R12 (Spec 5 coordination) の所管が自然
  - partial failure handling (R3.4 / R3.8) と統合され、設計が一貫
  - 修正範囲が最小（R12 のみ +1 AC）

  修正案 1 で Edit してよいか?
```

##### ❯ OK

```
⏺ 第 4-1 修正完了。R12 が 7 AC → 8 AC。

  ---
  第 4-2 (重要級): step 8 で lock 取得後の pre-flight 再確認規定が不在

  状況

  - R4.7 で「step 1〜7 は read-only、step 8 で一括実行」を規定済
  - R3.9 で「step 8 完了後の一括実行前に lock 取得」を規定済
  - 不在: step 8 で lock 取得した時点で「step 6 で行った pre-flight check と step 7 で生成した差分プレビューが依然有効か」を再確認する規定

  何が問題なのか

  - step 1〜7 中（lock 未取得）に他プロセスが該当ページを編集すると、step 7 で生成した差分プレビューが古い状態に基づく可能性
  - 古い差分プレビューに基づいて approve すると、想定外の状態に遷移する（例: ユーザーが step 7 で「A → deprecated」を確認したが、その間に他プロセスが
   A を archived に変更 → step 8 で「archived → deprecated」遷移を試行 → R1.2 違反で abort、ただしユーザーには「成功した」と表示される可能性）
  - lock 範囲が「step 8 完了後の一括実行」のみのため、step 1〜7 と step 8 の境界に race window がある

  修正案候補

  案 1: R3.9 に再確認規定を追加（推奨）

  R3.9 の lock 取得規定に「pre-flight 再確認」の文言を追記。

  追記文言案（R3.9 に追加、または新 R3.10 として独立）:

  R3.9 の末尾に追加:

  ▎ ...Simple dangerous op（rw unapprove / rw reactivate、Requirement 10）も同様に lock 取得を経由する。lock 取得直後に Requirement 4.2 の step 6
  ▎ (Pre-flight warning) を再実行し、step 1〜7 期間中に状態が変化した場合（status / successor / merged_from / merged_into 等）は ERROR severity で
  ▎ operation を abort し、ユーザーに 8 段階対話の再実行を促す。再確認は read-only 操作で lock 範囲内に含める。

  メリット (案 1)

  - lock 取得と再確認を同じ AC で扱い、概念的にまとまる
  - race window が消失、step 1〜7 と step 8 の整合性保証
  - ユーザーには「状態変化のため再実行が必要」と明示的に伝わる
  - 追加の Requirement / AC を作らずに修正可能

  デメリット (案 1)

  - R3.9 がさらに長くなる（既に長い AC）

  案 2: 新 R3.10 として独立 AC

  メリット (案 2)

  - R3.9 がコンパクトに保たれる
  - 再確認の責務が独立 AC で明示

  デメリット (案 2)

  - R3 が 9 AC → 10 AC でやや増える
  - lock 取得と再確認は密接で、同じ AC でまとめる方が自然

  案 3: R4.7 に追加

  R4.7（step 1〜7 read-only、step 8 一括実行）の規定に「step 8 で lock 取得後 pre-flight 再確認」を追加。

  メリット (案 3)

  - 8 段階対話の文脈で扱う

  デメリット (案 3)

  - R4 (Dangerous Operation Guide) と R3 (orchestration) でガイド側 / handler 側の責務分離があり、再確認は handler 側 (R3) の方が自然

  推奨

  案 1（R3.9 への追記）。理由:

  - lock 取得と再確認は密接、同じ AC で扱う方が概念的にまとまる
  - 修正範囲最小（既存 AC への追記）
  - handler 側責務として R3 配置が自然

  修正案 1 で Edit してよいか?
```

##### ❯ OK

```
⏺ 第 4-2 修正完了。R3.9 拡張のみ（AC 数変動なし）。

  ---
  第 4-3 (重要級): Backlink 更新の全失敗 vs 一部失敗の区別なし

  状況

  - R9.5: 「Backlink 走査中に一部ページの更新が失敗した場合、操作全体を rollback せず follow-up 化、操作自体は完了として扱う」と規定
  - 不在: 全失敗（disk full / permission denied / 全 markdown 更新失敗）の挙動

  何が問題なのか

  - 「一部失敗」と「全失敗」を同じ扱い（操作完了 + follow-up 化）にすると、disk full のような根本的問題が表面化しない
  - 全失敗時も「操作完了」として返すと、ユーザーは「Backlink 更新が成功した」と誤認
  - 例: 100 個の wiki/raw markdown を走査して全て disk full で書き込み失敗 → 全 100 件が follow-up 化される、ただし frontmatter status と Edge
  orchestration は完了扱い → 後続の operation が disk full の状態で続行 → さらに状態崩壊
  - 第 3-3 (R3.9) の lock 範囲内に Backlink 更新が含まれているため、全失敗時の rollback は可能（atomicity 保証）

  修正案候補

  案 1: R9.5 に全失敗時 rollback 規定を追加（推奨）

  R9.5 を拡張し、「一部失敗」と「全失敗」を区別する。

  修正文言案:

  ▎ If Backlink 走査中に一部ページの更新が失敗した, then the Lifecycle Manager shall 操作全体を rollback せず、未更新ページを Follow-up
  ▎ タスク（Requirement 7、task_type: backlink_update）として記録し、操作自体は完了として扱う。ただし Backlink 走査対象が全数失敗した場合（disk full
  ▎ / permission denied 等の根本的 I/O 障害）は ERROR severity で operation 自体を rollback し、frontmatter status 遷移と Edge orchestration
  ▎ を取り消す（lock 範囲内のため atomicity 保証可能、Requirement 3.9 と整合）。一部 / 全失敗の判定基準（例: 失敗率 ≥ 95% を全失敗とみなす等）は
  ▎ design phase で確定する。

  メリット (案 1)

  - 全失敗 = 根本的問題 を ERROR で表面化、ユーザーに対応を促す
  - lock 範囲内の rollback で atomicity 保証
  - 一部失敗の従来挙動は維持、後方互換性あり
  - 判定基準は design phase 持ち越しで実装柔軟性確保

  デメリット (案 1)

  - R9.5 が長くなる（既存スタイルと一貫）
  - 「一部 / 全失敗」の閾値判定が必要 → design phase で確定

  案 2: R9.5 を分割、新 R9.8 で全失敗を扱う

  メリット (案 2)

  - AC が分割され読みやすい

  デメリット (案 2)

  - R9 が 7 AC → 8 AC に増える
  - 一部 / 全失敗の判定が AC 分割で見通しが悪い

  案 3: 現状維持、design phase 持ち越し

  デメリット (案 3)

  - 致命的な障害（disk full）が表面化しない要件のまま
  - 重要級として扱う以上、要件レベルでの規定が望ましい

  推奨

  案 1（R9.5 拡張）。理由:

  - 一部 / 全失敗のセマンティクスを 1 AC で一貫した形で規定
  - lock 範囲内 rollback で atomicity 保証、設計が一貫
  - 判定基準は design phase 持ち越し（実装柔軟性）
  - 修正範囲最小（既存 AC 拡張）

  修正案 1 で Edit してよいか?
```

##### ❯ OK

```
⏺ 第 4-3 修正完了。R9.5 拡張のみ（AC 数変動なし）。

  ---
  第 4-4 (重要級): successor: 未指定時の blockquote / 動作が不明示

  状況

  - R8.1: deprecate 時の blockquote に > 後継: {successor のリスト、リンク形式} を含める
  - 不在: successor: field が未指定の deprecate 操作の挙動と blockquote 文言
  - Spec 1 の確認が必要: successor: は schema 上 optional か必須か

  確認事項

  Spec 1 R3 の successor: 規定を確認しておく必要があります。

  Searched for 1 pattern (ctrl+o to expand)

⏺ 確認結果: Spec 1 R3.3 で successor: は「0 個以上の wiki ページ path の配列」と規定 = optional が確認できた。「後継未定のdeprecate」は意図的に許容されている設計。

  修正案候補

  案 1: R8.1 に未指定時の挙動を明示（推奨）

  R8.1 を拡張し、successor 空配列時の blockquote 文言を規定。

  修正文言案:

  ▎ When rw deprecate <page> の 8 段階対話が approve まで完了した, the Lifecycle Manager shall 該当ページの本文先頭（frontmatter 直後）に警告
  ▎ blockquote > [!WARNING] Deprecated\n> このページは {status_changed_at} に deprecated されました。理由: {status_reason}\n> 後継: {successor
  ▎ のリスト、リンク形式} を自動挿入する。successor: field が未指定または空配列の場合（Spec 1 Requirement 3.3 で successor: は 0
  ▎ 個以上を許可）、blockquote の 後継: 行を 後継: 未指定（後日 successor 設定可、rw reactivate で active 化後に再 deprecate も可）
  ▎ と表示するか、または 後継: 行自体を省略する仕様を deprecate-guide.md（Requirement 5.2 のテンプレート）で確定する。

  メリット (案 1)

  - Spec 1 R3.3 の optional 仕様と整合
  - ユーザーには「後継未定でも deprecate 可能」と明示
  - テンプレート確定は operation guide (Requirement 5) に委譲、design phase で表現確定

  デメリット (案 1)

  - R8.1 が長くなる（既存スタイルと一貫）
  - 「未指定（後日設定可）」と「省略」の二択を残しているため、design phase で確定が必要

  案 2: R1 に successor の optional 性を明示し、R8.1 は変更なし

  R1 に「successor は optional（Spec 1 R3.3 と整合）」を補足、R8.1 は現状維持。

  メリット (案 2)

  - successor の optional 性が R1（状態遷移ルール）に集約
  - R8.1 は短いまま

  デメリット (案 2)

  - blockquote の挙動は依然不明示、design phase / 実装段階で再議論必須
  - R8 (警告 blockquote) で fallback 文言を規定しないと実装ばらつく

  案 3: R5 (操作固有ガイド) で確定、R1 / R8 は現状維持

  operation guide で fallback 文言を確定する責務を明示する AC を R5 に追加。

  メリット (案 3)

  - テンプレート責務を R5 に集約

  デメリット (案 3)

  - R8.1 と R5 の relations が薄い、実装者が R8 だけを見ると未指定時の挙動が分からない

  推奨

  案 1（R8.1 拡張）。理由:

  - blockquote の挙動規定は R8 の所管が自然
  - Spec 1 R3.3 の optional 仕様への明示的参照で coordination 強化
  - design phase で表現確定の余地を残す

  修正案 1 で Edit してよいか?
```

##### ❯ OK. あきらかにデメリットが大きな場合には候補を提案しなくて良い。

```
⏺ 第 4-4 修正完了。R8.1 拡張のみ。重要級 3 件すべて完了。

  ---
  第 4 ラウンド 中重要度・軽微 6 件の brief 持ち越し

  残り 6 件を brief.md に追加する:

  - 第 4-5（中）: dangerous op 実行時の出力に「N 件の follow-up が生成されました」を明示する規定
  - 第 4-6（中）: 全 dangerous op の reversibility 一覧（drafts §7.2 表に列追加 or 別表）
  - 第 4-7（中）: 大規模 Vault（>1,000 ページ）での Backlink 走査性能 / 並列化 / cache 戦略
  - 第 4-8（中）: rw follow-up list の pagination 規定
  - 第 4-9（軽微）: encoding 規定（UTF-8 前提の明示）
  - 第 4-10（軽微）: handler 引数の sanitization 規定

  Edit してよいか?
```

##### ❯ OK

```
⏺ brief.md に第 4 ラウンドの持ち越し 6 件を追加完了。

  ---
  第 4 ラウンド完了サマリ

  修正適用 4 件:

  - 第 4-1（致命級）: R12.8 新設 — edge API 呼出 timeout 必須
  - 第 4-2（重要級）: R3.9 拡張 — step 8 lock 取得後の pre-flight 再確認
  - 第 4-3（重要級）: R9.5 拡張 — Backlink 全失敗時の rollback
  - 第 4-4（重要級）: R8.1 拡張 — successor 未指定時の blockquote 仕様

  brief 持ち越し 6 件: 第 4-5 / 4-6 / 4-7 / 4-8 / 4-9 / 4-10

  現状の AC 数:

  - R3: 9 AC（第 3 ラウンド時点から変動なし、3-1 / 3-3 で AC 追加済、4-2 は AC 拡張）
  - R4: 7 AC
  - R5: 7 AC
  - R6: 9 AC
  - R8: 7 AC（4-4 は AC 拡張）
  - R9: 7 AC（4-3 は AC 拡張）
  - R12: 8 AC（4-1 で +1）
  - R15: 5 AC
  - R16: 9 AC

  第 5 ラウンド（C 観点 = 他 spec への波及影響）に進んでよいか?
```

##### ❯ OK

```
⏺ 第 5 ラウンド: C 観点 — 他 spec への波及影響

  第 1-4 ラウンドで適用した修正（致命級 9 件 + 重要級 6 件 + brief 持ち越し 14 件）が他 spec へ何を要求するかを整理した。

  ---
  A. Spec 5 (knowledge-graph) review 時の新規チェック項目（4 件）

  未 approve、これから review するため TODO_NEXT_SESSION.md に追記要

  - 第 4-1 由来 (R12.8): edge API（edge demote / edge reject / edge reassign）の各呼出に timeout を必須として規定する責務 → Spec 5 review 時に edge
  API spec の AC として組み込み確認
  - C-3 由来 (R12.7): record_decision() の decision_type 値として、本 spec が規定する Page lifecycle 起源 6 種（page_deprecate / page_retract /
  page_archive / page_merge / page_split / page_promote_to_synthesis）+ Skill lifecycle 起源 3 種（skill_deprecate / skill_retract /
  skill_archive）を Spec 5 の decision_log.jsonl schema が受け入れる責務 → Spec 5 review 時に decision_type enum の拡張可規約と整合確認
  - 第 3-3 由来 (R3.9): .rwiki/.hygiene.lock の物理実装（既存 Spec 5 R17 と整合）+ Page→Edge orchestration からの取得経路 → Spec 5 R17
  が既存規定済、追加修正は不要だが coordination 確認
  - 第 3-1 由来 (R3.8): partial failure JSON 出力（partial_failure / successful_edge_ops / failed_edge_ops / followup_ids）を Spec 5 の decision_log
  記録 (R3.7) で利用 → Spec 5 design phase で decision_log.jsonl schema に partial failure の記録形式を統合

  B. Spec 2 (skill-library) review 時の新規チェック項目（3 件）

  未 approve、TODO_NEXT_SESSION.md に追記要

  - A-1 由来 (R6.9): Skill lifecycle 拡張 2 種（skill deprecate / skill archive）の dangerous op 分類（危険度・対話ガイド要否・--auto
  可否）の値確定を本 spec design phase で行う際、Spec 2 が Skill 内容 schema を所管する観点から想定値の妥当性確認
  - R11.6 由来: Backlink 走査範囲 AGENTS/**/*.md の対象 = AGENTS/skills/<name>/SKILL.md 配置（Spec 2 所管）と整合確認
  - R12.7 由来 (Skill 起源 decision_type): skill_deprecate / skill_retract / skill_archive の decision_type 値追加は本 spec が起点、Spec 2 review
  時に Skill ファイル lifecycle の責務分離（schema = Spec 2 / lifecycle = 本 spec）と整合確認

  C. Spec 6 (perspective-generation) review 時の新規チェック項目（1 件）

  未 approve、TODO_NEXT_SESSION.md に追記要

  - C-1 由来 (R13.7): cmd_promote_to_synthesis(candidate_path, target_path, merge_strategy, target_field) の dispatch contract → Spec 6 が hypothesis
   status confirmed → promoted 遷移時に Spec 4 R16.2 経由で本 handler を呼び出す規約 → Spec 6 review 時に呼出側 spec として整合確認

  D. Spec 4 (cli-mode-unification) への遡及確認（既に approve 済 → Adjacent Sync 候補）

  approve 済 spec、再 approval 不要だが Adjacent Sync 対象の可能性

  - 第 3-1 由来 (R3.8): partial failure 時の exit code = 1 と JSON field（partial_failure 等）を Spec 4 dispatch が解釈する規約 → Spec 4 R13.2 /
  R15.10 / R16.2 等の dispatch ロジックで必要 → Adjacent Sync 候補
  - C-1 由来 (R13.7): cmd_promote_to_synthesis の signature が Spec 4 R16.2 と双方向一致 → Spec 4 R16.2 は既に approve 済、本 spec で signature
  詳細を design phase 持ち越しに固定 → 整合 ✅

  E. Spec 1 (classification) / Spec 0 (foundation) への遡及確認

  両者 approve 済、本 spec の修正は既存規定への参照強化のみ

  - D-1 / D-2 / 第 4-4: Spec 1 R3.3 / R3.4 / R3.6 への参照 → 既存規定の活用、Spec 1 修正不要 ✅
  - E (§2.12 参照追加): Foundation §2.12 への参照強化 → 既存規定の活用、Foundation 修正不要 ✅

  F. 本 spec requirements の内部修正の要否

  第 5 ラウンドでの requirements 内部修正は 不要 と判断:

  - 各 coordination は個別 Requirement (R3 / R12 / R13) 内で言及済み
  - Boundary Adjacent expectations は「設計前提」レベルなので個別 Req の coordination 詳細は本文に書かれていればよい
  - 既存の Adjacent expectations が 8 項目（Foundation / Spec 1 / Spec 4 / Spec 5 / Spec 6 / Severity / exit code / §2.12）で網羅的

  ---
  第 5 ラウンド総括

  - requirements 内部修正: 不要
  - 必要アクション: TODO_NEXT_SESSION.md に Spec 5 / Spec 2 / Spec 6 review 時の新規チェック項目を追加
  - Adjacent Sync 候補: Spec 4 R13.2 / R15.10 / R16.2 への partial failure JSON 解釈規約反映（別セッションで処理）

  ---
  進め方:

  - (a) TODO_NEXT_SESSION.md を更新して Spec 5 / Spec 2 / Spec 6 review チェック項目に追記、その後第 6 ラウンドへ
  - (b) TODO_NEXT_SESSION.md 更新は最終ステップにまとめ、即第 6 ラウンドへ進む
  - (c) Adjacent Sync 候補（Spec 4 への波及）も brief 等に記録してから次へ

  どれで進めますか?
```

##### ❯ a

```
⏺ TODO_NEXT_SESSION.md に Spec 7 由来の coordination 要求を追加する。3 spec のチェック項目セクションに新規追記 + Adjacent Sync 候補 1 件追加。
⏺ TODO_NEXT_SESSION.md 更新完了。

  - Spec 5 セクションに Spec 7 由来 4 件追加
  - Spec 2 セクションに Spec 7 由来 3 件追加
  - Spec 6 セクションに Spec 7 由来 1 件追加
  - Adjacent Sync TODO に D-9 (Spec 4 への partial failure JSON field 解釈) 追加

  第 5 ラウンド完了。第 6 ラウンド（D 観点 = drafts との整合）に進んでよいか?
```

##### ❯ OK

```
⏺ 第 6 ラウンドは drafts との整合性チェック。本 spec 修正で drafts に新たな不整合が発生していないかを確認する。draftsの関連セクションを順次確認する。
⏺ drafts §2.13 / §7.2 Spec 5 / §2.4 / §2.5 / §2.6 を確認した。

  第 6 ラウンド: D 観点 — drafts との整合

  A. drafts §7.2 Spec 7 と本 spec の整合性

  - drafts §7.2 Spec 7 の Dangerous op の分類表 13 種 = 本 spec R6.1 SSoT 引用 ✅
  - drafts §7.2 Spec 7 の Page 状態と挙動表 5 種 = 本 spec R1 / R2 ✅
  - drafts §7.2 Spec 7 の 8 段階チェックリスト = 本 spec R4.2 ✅
  - drafts §7.2 Spec 7 の コマンド対応注（13 操作 → CLI 名） = 本 spec R6 / R13.1 整合 ✅

  B. drafts §2.4 / §2.5 / §2.6 / §2.13 と本 spec の整合性

  - drafts §2.4 8 段階対話 L3 限定 = 本 spec R4.4 整合 ✅
  - drafts §2.5 L3 対象 Simple ops（unapprove / reactivate） = 本 spec R10 整合 ✅
  - drafts §2.5 L2 対象は Spec 5 所管 = 本 spec R10.6 整合 ✅
  - drafts §2.6 L3 frontmatter update_history: = 本 spec R1.8（D-2 で追加）整合 ✅
  - drafts §2.13 Selective recording トリガー（人間 approve / status 遷移 / Synthesis 昇格） = 本 spec R12.7（C-3 で追加）整合 ✅

  C. 新規発見の drafts 不整合

  第 6-A (重要級): drafts §7.2 Spec 5 line 1670 の decision_type 値リストと本 spec R12.7 で表記揺れ

  drafts §7.2 Spec 5 line 1670 (Decision types 10 種):

  ▎ edge_extraction / edge_reject / edge_promote / edge_unreject / hypothesis_verify / synthesis_approve / page_deprecate / tag_merge / split /
  ▎ hygiene_apply

  本 spec R12.7 (Page lifecycle 起源 6 種):

  ▎ page_deprecate / page_retract / page_archive / page_merge / page_split / page_promote_to_synthesis

  問題点:

  - drafts では split 単独（prefix なし）、本 spec では page_split → 表記揺れ
  - drafts では synthesis_approve のみ、本 spec では別概念として page_promote_to_synthesis
  - drafts には page_retract / page_archive / page_merge が未列挙

  設計判断: drafts §7.2 Spec 5 の Decision types 10 種は例示と解釈する（... 表記なしだが、Spec 1 R8.13 / Spec 4 R15.10 / 本 spec R12.7 で「Spec 5
  が初期セット定義、Spec 7 / Spec 1 拡張可」が確定済）。本 spec R12.7 で 正しい Page lifecycle 起源値リストを規定したので、drafts §7.2 Spec 5 line
  1670 への反映は Adjacent Sync で行う。

  修正案: 本 spec の修正は 不要。drafts Adjacent Sync TODO に新規追加（D-10）。

  D. drafts に未規定で本 spec が新規追加した内容（drafts Adjacent Sync 候補）

  - 本 spec R3.8 (partial failure exit code = 1 + JSON 出力)
  - 本 spec R3.9 (.hygiene.lock 取得規定)
  - 本 spec R4.7 (8 段階対話の step 1〜7 read-only / step 8 一括実行)
  - 本 spec R12.8 (edge API 呼出 timeout 必須)
  - 本 spec R15 (L3 診断 API)

  これらは drafts 未規定領域の本 spec 規定で、drafts への反映は別セッション処理 (Adjacent Sync) で対応。本 spec の修正は不要。

  E. 既知の drafts Adjacent Sync TODO との関係

  - D-8 (drafts §7.2 Spec 7 の Dangerous op の分類表に skill deprecate / skill archive / tag deprecate / tag rename / tag register 未列挙) →
  既知、TODO_NEXT_SESSION.md に記録済み

  第 6 ラウンド総括

  - 本 spec requirements の内部修正は 不要
  - 必要アクション: TODO_NEXT_SESSION.md の Adjacent Sync TODO に新規 D-10 を追加（drafts §7.2 Spec 5 line 1670 の Decision types 10 種への Page
  lifecycle 起源値の反映）

  ---
  進め方:

  - (a) TODO_NEXT_SESSION.md に D-10 を追加してから第 6 ラウンドを完了
  - (b) D-10 追加は最終ステップにまとめ、即第 6 ラウンド完了とする

  どれで進めますか?
```

##### ❯ a

```
⏺ D-10 追加完了。第 6 ラウンドの結果を反映。

  ---
  Spec 7 review 6 ラウンド完了 — 最終サマリ

  各ラウンドで適用した修正

  第 1 ラウンド（基本整合性）— 致命級 5 + 重要級 3 = 8 件:

  - A-1 / B-1 / C-1 / C-2 / C-3 / D-1 / D-2 / E

  第 2 ラウンド（roadmap / brief 厳格照合）— 0 件:

  - 整合性確認のみ、修正不要

  第 3 ラウンド（本質的観点）— 致命級 3 + 重要級 3 = 6 件:

  - 3-1 / 3-2 / 3-3 / 3-4 / 3-5 / 3-6

  第 4 ラウンド（B 観点）— 致命級 1 + 重要級 3 = 4 件:

  - 4-1 / 4-2 / 4-3 / 4-4

  第 5 ラウンド（他 spec 波及）— 0 件:

  - TODO_NEXT_SESSION.md に Spec 5 / Spec 2 / Spec 6 への coordination 要求追加（8 件）+ Spec 4 への Adjacent Sync 候補 D-9 追加

  第 6 ラウンド（drafts 整合）— 0 件:

  - TODO_NEXT_SESSION.md に Adjacent Sync 候補 D-10 追加

  Requirement / AC 数の変動

  - Requirement 数: 14 → 16（C-2 で R15 = L3 診断 API を新設、現 R14 を R16 に rename）
  - AC 数: 約 96 → 約 112（合計 +16 AC）

  各 Requirement の AC 数:

  - R1: 7 → 8 AC（D-2 で +1）
  - R2: 7 AC（変更なし）
  - R3: 7 → 9 AC（C-3 / 3-1 / 3-3 で +1 each、4-2 は AC 拡張）
  - R4: 6 → 7 AC（3-2 で +1）
  - R5: 6 → 7 AC（3-5 で +1）
  - R6: 8 → 9 AC（A-1 で +1）
  - R7: 8 AC（変更なし）
  - R8: 7 AC（3-4 / 4-4 は AC 拡張）
  - R9: 7 AC（4-3 は AC 拡張）
  - R10: 6 AC（変更なし）
  - R11: 6 AC（変更なし）
  - R12: 6 → 8 AC（C-3 / 4-1 で +1 each）
  - R13: 6 → 7 AC（C-1 で +1）
  - R15（新）: 5 AC
  - R16（旧 R14）: 9 AC（E は AC 拡張）

  brief.md に持ち越した design phase 項目

  - 第 1 ラウンド由来: F-1 / F-2 / F-3 + R6.9 / R13.7 / R15.3 由来 = 6 件
  - 第 3 ラウンド由来: 3-7 / 3-8 / 3-9 / 3-10 / 3-11 = 5 件
  - 第 4 ラウンド由来: 4-5 / 4-6 / 4-7 / 4-8 / 4-9 / 4-10 = 6 件

  合計 17 件

  TODO_NEXT_SESSION.md 更新内容

  - Spec 5 review 時のチェック項目: Spec 7 由来 4 件追加
  - Spec 2 review 時のチェック項目: Spec 7 由来 3 件追加
  - Spec 6 review 時のチェック項目: Spec 7 由来 1 件追加
  - Adjacent Sync TODO: D-9（Spec 4 R13.2 等への partial failure JSON 解釈反映）+ D-10（drafts §7.2 Spec 5 line 1670 の decision_type 整合）追加

  ---
  次のアクション

  ユーザーの判断待ち:

  - (a) spec.json を approve = true に更新（approvals.requirements.approved = true、phase = requirements-approved、updated_at 更新）
  - (b) approve 前に最終確認したい Requirement / 修正箇所を再確認
  - (c) 修正内容を git commit してから approve（修正適用 → コミット → 別途 approve）
  - (d) 本セッションを区切り、新セッションで approve（コンテキスト確認後に approve）

  どれで進めますか?
```

##### ❯ a

```

```





仕様間の整合性をチェック

仕様間の依存関係をチェック