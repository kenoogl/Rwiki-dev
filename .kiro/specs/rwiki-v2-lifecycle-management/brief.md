# Brief: rwiki-v2-lifecycle-management

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §7.2 Spec 7

## Problem

L3 wiki ページの状態（active / deprecated / retracted / archived / merged）は frontmatter `status:` で管理する方針だが、状態遷移時の dangerous op（8 段階対話、警告 blockquote 自動挿入、backlink 更新、follow-up タスク化）が定義されていなければ、ユーザーが手動で全てを処理することになり、誤操作で trust chain が壊れる。さらに L2 edge lifecycle（Spec 5）との相互作用（Page deprecation → 関連 edges demotion 等）も整合させる必要がある。

## Current State

- consolidated-spec §2.4 で 8 段階チェックリストが確定
- §7.2 Spec 7 で Page status 5 種、Page と Edge lifecycle の相互作用、dangerous op 13 種の分類（必須 / 推奨 / 簡易、--auto 可否）が整理済
- Skill lifecycle（deprecate / retract / archive）も本 spec の責務
- v1 の v1-archive には deprecate / retract / archive コマンドの実装はなく、新規実装

## Desired Outcome

- Page status の状態遷移が CLI コマンドとして提供され、各状態の挙動（参照元扱い / Query 対象 / Wiki 位置）が定義される
- Page deprecation → 関連 L2 edges の demotion、Page retracted → edges を rejected に準ずる扱い、Page merged → edges を merged target に付け替えが動作
- Dangerous op の 8 段階対話ガイドが `AGENTS/guides/` に揃い、対話的に安全な状態変更が行える
- 警告 blockquote の自動挿入、backlink 更新、follow-up タスク化が機能
- Simple dangerous ops（unapprove / reactivate）が 1 段階確認で動作

## Approach

L3 Page lifecycle の状態遷移ルール（Page status 5 種）と CLI ハンドラを本 spec で定義。8 段階チェックリストは `AGENTS/guides/dangerous-operations.md` に集約、固有ガイド（deprecate-guide / merge-guide 等）は別ファイル。Page と Edge lifecycle の相互作用は本 spec が orchestrate（Spec 5 の edge API を呼出）。Skill lifecycle も同様に本 spec で管理。

## Scope

- **In**:
  - Page status 状態遷移（active / deprecated / retracted / archived / merged / active 復帰）
  - Page lifecycle と Edge lifecycle の相互作用（page deprecation → edges demotion 等）
  - Dangerous op 8 段階共通チェックリスト（`AGENTS/guides/dangerous-operations.md`）
  - 固有ガイド（`deprecate-guide.md` / `merge-guide.md` 等）
  - Follow-up タスク仕組み（`wiki/.follow-ups/`）
  - 警告 blockquote の自動挿入（deprecate / retract / archive）
  - Backlink 更新（wiki merge / deprecate 時）
  - Simple dangerous ops（unapprove / reactivate、1 段階確認）
  - Skill lifecycle（deprecate / retract / archive）
- **Out**:
  - 個別タスクの出力（他 spec）
  - Edge lifecycle の進化則（Spec 5 Graph Hygiene）
  - Edge status の定義と遷移（Spec 5）

## Boundary Candidates

- Page lifecycle ルール（本 spec）と Edge lifecycle ルール（Spec 5）
- Dangerous op の対話 UX（本 spec）と CLI dispatch（Spec 4）
- Page → Edge interaction の orchestration（本 spec）と edge API の実装（Spec 5）
- Skill lifecycle（本 spec）と skill 定義（Spec 2）

## Out of Boundary

- Edge status 定義と進化則（Spec 5）
- L2 ledger の data model（Spec 5）
- Skill 内容（Spec 2）
- 個別 CLI コマンドのフレーム（Spec 4）

## Upstream / Downstream

- **Upstream**: rwiki-v2-foundation（Spec 0）/ rwiki-v2-classification（Spec 1 — frontmatter `status:`）。実装段階では rwiki-v2-cli-mode-unification（Spec 4 — dangerous op CLI ハンドラ呼出）も必要だが、requirements は Spec 4 と並列可（consolidated-spec §9.5）
- **Downstream**: rwiki-v2-knowledge-graph（Spec 5 — Page→Edge interaction で edge API 呼出）/ rwiki-v2-perspective-generation（Spec 6 — Confirmed hypothesis の wiki 昇格は本 spec の dangerous op を経由）

## Existing Spec Touchpoints

- **Extends**: なし（v2 新規、v1 には deprecate / retract / archive コマンドなし）
- **Adjacent**: v1 `cli-audit`（v1-archive、参照のみ）

## Constraints

- v2 には 2 種類の lifecycle が並立（L3 Page = Spec 7、L2 Edge = Spec 5）
- Page status 5 種: active / deprecated / retracted / archived / merged
- Dangerous op 13 種の分類（--auto 可否、対話ガイド必須/推奨）は §7.2 Spec 7 表で確定
- `--auto` 不可: retract / split / tag split / skill retract / promote-to-synthesis
- 8 段階チェックリスト共通: 意図確認 → 現状把握 → 依存グラフ解析 → 代替案提示 → 参照元の個別判断 → Pre-flight warning → 差分プレビュー → 人間レビュー → approve
- ディレクトリ移動なし（status frontmatter で管理、§2.3）
- Backlink 更新は wiki merge / deprecate 時に必須
- Skill lifecycle も同じ pattern（deprecate / retract / archive）

## Coordination 必要事項

- **Spec 7 ↔ Spec 5**: Page deprecation → Edge demotion の interaction flow（API contract と orchestration の境界）
- **Spec 7 ↔ Spec 4**: dangerous op CLI ハンドラの呼出規約
