# メモリ一般化と統廃合計画

最終更新：2026-05-14
対象：`dual-reviewer-rebuild/.kiro/memory/` 配下の 21 件
目的：配布物として持ち出せる形に書き直す。利用者像は spec 駆動開発を採用する別チーム・個人。言語は日本語。

## 前提（本セッションで合意済）

- 利用者像：spec 駆動開発を採る別チーム・個人。英語版は将来別途用意。
- 他文書との重複：メモリ側を削除、または該当文書へのリンクだけ残す。
- ファイル名：主題が分かる中立名へ改名し、索引と他参照を同時更新。
- サブツリー `CLAUDE.md` との連携：配布時に再検討。
- 重複配置 3 件（`finding_4elements`、`review_log_template`、`commit_log_sequencing`）：dual-reviewer 側は一般化、Rwiki-dev 側は現状維持。
- 配布物 `frontmatter` は `name` / `description` / `type` の 3 項目のみ。`originSessionId` は全件削除。`type` は当面 `feedback` 一本。
- テンプレートは案 C（複雑さに応じて簡素版／節分け詳細版を使い分け）。

## テンプレート規約

### 案 A（簡素な三部構成）

短い規律向き。

```
---
name: <主題>
description: <一行説明>
type: feedback
---

<規律本体：1〜2 文>

**Why:** <根拠 1 段落>

**How to apply:** <適用方法、数行〜箇条書き>
```

### 案 B（節分け詳細版）

手順や規則が複雑な規律向き。節見出しの候補は次のとおり。各ファイルの主題に応じて取捨選択。

- 「全体の流れ」
- 「個別の規則」
- 「適用する場面」
- 「例外的な扱い」

## 21 件の仕分け

凡例：
- 改名案は中立名。先頭の `feedback_` は維持（フィードバック由来の規律であることを示すため、敢えて残す）。配布時に `feedback_` を取り除く判断は、命名規則の見直し時に再検討する。
- 「書き直し量」は、削るべき内部固有表現の多寡で見積もり。

### 案 A 向き（簡素な三部構成、9 件）

1. `feedback_adjacent_sync_direction.md`
   - 改名案：`feedback_adjacent_sync_direction.md`（変更なし）
   - 書き直し量：軽微（「Negative 視点」を「敵対役視点」に置き換え程度）
   - 統合先：独立維持

2. `feedback_commit_log_sequencing.md`（重複配置：Rwiki-dev 側は現状維持）
   - 改名案：`feedback_commit_log_sequencing.md`（変更なし）
   - 書き直し量：中（`rework_log` / `dev_log` を「開発ログ」「変更履歴」に一般化、`TBD placeholder` の社内経緯を削除）
   - 統合先：独立維持

3. `feedback_design_decisions_record.md`
   - 改名案：`feedback_design_decisions_record.md`（変更なし）
   - 書き直し量：軽微
   - 統合先：独立維持。ただし `feedback_design_review.md`（10 観点）と関連が深いので、目次から相互参照する旨を一行入れる。

4. `feedback_design_spec_roundtrip.md`
   - 改名案：`feedback_design_spec_roundtrip.md`（変更なし）
   - 書き直し量：軽微
   - 統合先：独立維持

5. `feedback_finding_4elements.md`（重複配置）
   - 改名案：`feedback_finding_4elements.md`（変更なし）
   - 書き直し量：軽微（具体例の表現を一般化）
   - 統合先：独立維持

6. `feedback_no_round_batching.md`
   - 改名案：`feedback_no_round_batching.md`（変更なし）
   - 書き直し量：中（「40 回目末例外」など通番由来の例外記述を一般化）
   - 統合先：`feedback_review_rounds.md` と密接、独立維持か統合検討（後述）

7. `feedback_review_log_template.md`（重複配置）
   - 改名案：`feedback_review_log_template.md`（変更なし）
   - 書き直し量：軽微
   - 統合先：独立維持

8. `feedback_review_save_immediately.md`
   - 改名案：`feedback_review_save_immediately.md`（変更なし）
   - 書き直し量：軽微（主役/敵対役/判断役の役名は日本語化済みなので大きな書き直しは不要）
   - 統合先：独立維持。`feedback_review_log_template.md` と表裏一体（保存時点 vs 表記式）なので相互参照を入れる。

9. `feedback_wave_procedure_compliance.md`
   - 改名案：`feedback_wave_procedure_compliance.md`（変更なし）
   - 書き直し量：軽微
   - 統合先：独立維持

### 案 B 向き（節分け詳細版、11 件）

1. `feedback_cross_spec_review_pattern.md`
   - 改名案：`feedback_cross_spec_review_pattern.md`（変更なし）
   - 書き直し量：大（「12 回目末 design phase + 14 回目末 tasks phase 累計適用」通番、20 観点整合性検査、Group A/B/C を一般化）
   - 統合先：独立維持

2. `feedback_design_review.md`（10 観点 SSoT）
   - 改名案：`feedback_design_review.md`（変更なし）
   - 書き直し量：中（V3 / V4 への参照を「現行方法論」と読み替え、敵対役エージェント派遣などの内部表現を一般化）
   - 統合先：独立維持。`feedback_design_review_v3_consolidated.md` との関係を整理（次項参照）。

3. `feedback_design_review_v3_consolidated.md`
   - 改名案：`feedback_adversarial_review_overview.md`（V3 という内部世代名を外し、敵対役レビュー全体の概観に位置づける）
   - 書き直し量：大（V3、Phase A/B/C、Layer 1/2/3、外部レビューア固有名などをすべて一般化）
   - 統合先：要検討。`feedback_design_review.md`（10 観点）と内容が一部重なる。10 観点を「検出の観点」、本ファイルを「主役・敵対役・判定役の全体構造」と役割分担すれば独立維持で整理可能。

4. `feedback_dual_reviewer_3_concept_separation.md`
   - 改名案：`feedback_three_concepts_separation.md`（dual-reviewer 用語は配布物では「敵対役レビュー」または「dual-reviewer 手法」に統一）
   - 書き直し量：大（dr-\* skill / V4 protocol / Level 6 はすべて内部固有名）
   - 統合先：独立維持。配布物導入時の概念整理として最初に読まれる位置。

5. `feedback_dual_reviewer_monitor_only.md`
   - 削除候補（要判断）。理由：「Phase A は観測のみで改善は Phase B-1.x へ繰り延べ」という規律は、Rwiki 論文のための社内 phase 区分に依存しており、配布先利用者には文脈が伝わらない。一般化すると「方法論を実証する期間中は手を加えず観測に徹する」という極めて抽象的な助言になり、わざわざ独立ファイルにする価値が薄い。
   - 改名案（残す場合）：`feedback_methodology_stable_period.md`
   - 統合先（残す場合）：`feedback_dual_reviewer_3_concept_separation.md` の節として吸収

6. `feedback_main_merge_3req_audit.md`
   - 改名案：`feedback_main_merge_audit_process.md`
   - 書き直し量：大（「11 回目末 main 統合（case A 即 merge）+ V3 design phase artifact cleanup + 3 req 整合性 audit」のうち通番と V3 名を外し、3 仕様を「複数仕様」に一般化）
   - 統合先：独立維持

7. `feedback_review_judgment_patterns.md`
   - 改名案：`feedback_review_judgment_patterns.md`（変更なし）
   - 書き直し量：中（過去開発ログのパス、Step 1b-iii などの内部節番号を一般化。23 種パターン自体は中身を残す。）
   - 統合先：独立維持

8. `feedback_review_necessity_judgment.md`（書き直し済）
   - 既に一般化済み。再点検のみ。

9. `feedback_review_rounds.md`
   - 改名案：`feedback_review_rounds_5_stages.md`
   - 書き直し量：中（「Foundation 改版時は傘下全 spec への精査必須」を「上位仕様の改版時は依存する下位仕様すべてを再精査」に一般化）
   - 統合先：`feedback_no_round_batching.md` を本ファイルの一節として吸収する案あり（「各ラウンドを独立 turn で処理」を「適用ルール」の一節に組み込む）。統合すれば 22 件から 21 件、さらに統合できれば 20 件。

10. `feedback_review_step_redesign.md`
    - 改名案：`feedback_review_step_1_design.md`
    - 書き直し量：大（Step 1a/1b/4 重検査、production deploy 逆算、Phase 1 パターンマッチング、dev-log 23 パターン、Spec 4 design 試行など、内部固有用語が多い）
    - 統合先：独立維持

11. `feedback_self_review_skill_skip.md`
    - 改名案：`feedback_self_review_skip.md`
    - 書き直し量：中（`validate-design` / `validate-gap` / `validate-impl` などスキル名は配布版での実装名次第、`19 回目末 A-2 phase 採取軸違反由来` は社内経緯）
    - 統合先：独立維持。ただし内容が短いので、検討余地あり。

### 削除候補

- `feedback_dual_reviewer_monitor_only.md`（上記理由）

### 統合候補

- `feedback_no_round_batching.md` → `feedback_review_rounds.md` の節として吸収
  - 効果：レビュー手順のラウンド設計が 1 ファイルに集約され、利用者が読みやすい。
  - 影響：ファイル数 -1、索引 -1 行。

## 改名一覧（採用した場合）

- `feedback_design_review_v3_consolidated.md` → `feedback_adversarial_review_overview.md`
- `feedback_dual_reviewer_3_concept_separation.md` → `feedback_three_concepts_separation.md`
- `feedback_main_merge_3req_audit.md` → `feedback_main_merge_audit_process.md`
- `feedback_review_rounds.md` → `feedback_review_rounds_5_stages.md`
- `feedback_review_step_redesign.md` → `feedback_review_step_1_design.md`
- `feedback_self_review_skill_skip.md` → `feedback_self_review_skip.md`

その他は名前変更なし。

## 件数の見通し

- 現状：21 件
- 削除候補採用：-1（`dual_reviewer_monitor_only`）
- 統合候補採用：-1（`no_round_batching` を `review_rounds` に吸収）
- 改名 6 件：件数は変わらず
- 最終：19 件（推定）

## 実作業時の手順（次セッション以降）

1. 削除候補 1 件の最終判断
2. 統合候補 1 件の最終判断
3. 各ファイルの内部固有表現を機械的に検索：通番（〇 回目）、内部世代名（V3 / V4）、phase 名（Phase A / Phase B-1.x）、固有仕様名（foundation / design-review / dogfeeding 等）、内部文書パス、日付
4. 案 A / 案 B のテンプレートに沿って書き直し
5. 改名を実施し、索引 `MEMORY.md` と他文書（特に `dual-reviewer-rebuild/CLAUDE.md`）の参照を同時更新
6. 配布物として通読して規律が利用者に届く形になっているかを確認

## B 群（Rwiki-dev 側）への参考

- B 群（16 件）は本体プロジェクト文脈で書かれており、配布物化は別タイミング。
- 配布物化する場合、本計画の手順をそのまま適用可能。
- 重複配置 3 件のうち Rwiki-dev 側は本体プロジェクトの文脈を維持し、一般化はしない方針（本セッションで合意済）。
- B 群側で特に削除候補となるのは、解消済み技術負債の 3 件（`call_claude_timeout`、`exit_code_ambiguity`、`severity_system`）。これらは Rwiki 本体側でも履歴記録としての価値が低いため、本体側でも整理対象となる可能性が高い。

## 軽い照合の所見（2026-05-14 実施）

21 件を主題で 6 グループに分け、グループ内の重なりを確認した。本セッションで実施した「軽い照合」の所見を以下に記録する。深い照合は一般化作業の完了後に別途実施する。

### 所見 1：`feedback_design_review_v3_consolidated.md`（6）の位置づけ

このファイルは敵対役レビューの全体構造を概観しているが、`feedback_design_review.md`（5）／`feedback_dual_reviewer_3_concept_separation.md`（8）／`feedback_review_necessity_judgment.md`（15）／`feedback_review_step_redesign.md`（18）と内容が重なる。最終判断として次の二案がある。

- 案 X：6 を削除し、5・8・15・18 を直接参照させる。
- 案 Y：6 を「全体概観の道標」として最小限に再構成し、入口ファイルとして残す。

### 所見 2：「設計レビュー」と「仕様レビュー」の用語整理

`feedback_design_review.md`（5、10 観点 = 10 ラウンド）と `feedback_review_rounds.md`（16、5 ラウンド構成）は適用範囲が異なる（前者は設計レビュー、後者は仕様レビュー）。配布物では利用者の混乱を避けるため、各ファイル冒頭で対象範囲を明示し、相互参照を入れる。

### 所見 3：参照パターンと Step 1 改修の関係

`feedback_review_judgment_patterns.md`（13、23 種パターン）は、`feedback_review_step_redesign.md`（18、Step 1 改修）の Step 1b で引用される関係にある。統合はせず、18 から 13 への参照を明示する。

### 所見 4：レビュー出力の表現式と保存タイミング

`feedback_review_log_template.md`（14、表現式）と `feedback_review_save_immediately.md`（17、保存タイミング）は同じ「レビュー出力の取扱い」を二つの観点で扱う。統合はせず、相互参照を入れる。

### 軽い照合では重なりが見つからなかった項目

- グループ C（仕様横断・統合、3 件）：相互に独立。
- グループ D（設計レビュー特有、2 件）：観点が異なり重なりなし。
- グループ F（周辺手順、4 件）：相互に独立。

### 次の作業への影響

実作業時の手順（前述）の「2. 統合候補 1 件の最終判断」に加え、「所見 1 の二案（案 X／案 Y）の最終判断」を承認対象に追加する。所見 2／3／4 は相互参照を入れるだけなので、各ファイルの一般化作業の中で実施できる。
