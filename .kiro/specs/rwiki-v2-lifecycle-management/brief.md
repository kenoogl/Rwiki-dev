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

## Design phase 持ち越し項目

第 1 ラウンドのレビューで requirements レベルでは保留／持ち越しと判断した項目。design phase 起票時に確定する。

### Requirements レビューで発生した持ち越し

- **R6.9 由来**: Skill lifecycle 拡張 2 種（`skill deprecate` / `skill archive`）の危険度・対話ガイド要否・`--auto` 可否を design phase で確定（Spec 4 Requirement 13.7 と整合、drafts D-8 Adjacent Sync 後に drafts §7.2 Spec 7 の Dangerous op の分類表へ反映可）
- **R13.7 由来**: `cmd_promote_to_synthesis(candidate_path, target_path, merge_strategy, target_field)` の signature と `merge_strategy` × `target_field` から「新規 wiki page 生成 / `extend` / `merge` / `deprecate`」を自動判定する判定アルゴリズム詳細を design phase で確定
- **R15.3 由来**: L3 診断 API の名前 / signature / 返り値スキーマの確定（Spec 5 Requirement 20.8 = L2 診断 API と並列構造で定義）

### 軽微指摘（design phase で扱う）

- **F-1（軽微）**: コンポーネント命名のばらつき。R4.1-4.6 のみ subject = `the Dangerous Operation Guide`、他全 AC は `the Lifecycle Manager`。意図的な component 分離（ガイドが Markdown ドキュメントとして実体化される設計）か統一すべきかを design phase で判断
- **F-2（中重要度）**: R7.2 の task_type enum 拡張余地。現状 4 種固定（`edge_followup` / `backlink_update` / `manual_review` / `reactivation_check`）。design phase で「初期セット 4 種、新 task_type 追加可」の方針を検討
- **F-3（軽微）**: R9.3 と R11.6 の Backlink 走査範囲統一表現。Page 用 = `wiki/**/*.md` + `raw/**/*.md`、Skill 用 = 上記 + `AGENTS/**/*.md`。design phase で走査範囲を表す共通表現（例: `BACKLINK_SCAN_PATHS` 定数）を整理

### 第 3 ラウンドで発生した持ち越し（本質的観点の中重要度 / 軽微）

- **第 3-7（中重要度）**: `update_history` / `status_changed_at` の精度が YYYY-MM-DD のため、同日内に複数 dangerous op が実行された場合の順序が frontmatter から判別不能。design phase で順序保証メカニズム（ISO 8601 timestamp `YYYY-MM-DDTHH:MM:SS+09:00` への精度引き上げ、または `update_history` 配列に `sequence_number` field 追加）を検討
- **第 3-8（中重要度）**: Follow-up タスクの長期 GC 機構未規定。`status: resolved` / `status: dismissed` のタスクが `wiki/.follow-ups/` に蓄積し続けると長期運用で肥大化。design phase で archive メカニズム（例: `wiki/.follow-ups/.archived/<year>/<id>.md` への移動、または retention policy `> 90 日 resolved → archive` 等）を検討
- **第 3-9（中重要度）**: `promote-to-synthesis` = 最高危険度（drafts §7.2 Spec 7 の Dangerous op の分類表）に対する追加ゲートの要否。現状は 8 段階対話 + `--auto` 不可（Requirement 6.4）で十分か、それとも追加ゲート（2 名 approve / audit 実行済必須 / 一定期間後 cool-down 等）が必要かを design phase で判断
- **第 3-10（中重要度）**: Follow-up `id` の unique 保証メカニズム未規定。Requirement 7.2 で `id`（unique 文字列）が必須だが、採番方式（UUID v4 / `<YYYY-MM-DD>-<seq>` / `<origin_operation>-<short-hash>` 等）と衝突時の挙動（再採番 / エラー）が design phase 持ち越し
- **第 3-11（軽微）**: Requirement 6.5 の `--auto` 不可指定操作に `--auto` フラグが渡された場合の severity = INFO は控えめ、WARN が妥当か（`--auto` 不可指定への違反は警告すべき注意事項）。design phase で再評価可

### 第 4 ラウンドで発生した持ち越し（B 観点の中重要度 / 軽微）

- **第 4-5（中重要度）**: dangerous op 実行時の出力に「N 件の follow-up が生成されました」を明示する規定が薄い。Requirement 13.2 の JSON / human-readable 出力規定に follow-up 件数表示を含める仕様を design phase で確定（ユーザーが事後対応すべき task の認知性向上）
- **第 4-6（中重要度）**: 全 dangerous op の reversibility 一覧が requirements 内に分散（Requirement 10.5 の retracted / merged 不可逆、Requirement 1.2 の archived 終端等）。design phase で reversibility 表を生成（drafts §7.2 Spec 7 の Dangerous op の分類表に列追加 or 別表として整理）
- **第 4-7（中重要度）**: 大規模 Vault（>1,000 ページ）での Backlink 走査性能。Requirement 9.3 の `wiki/**/*.md` + `raw/**/*.md` 全走査が deprecate 1 回で長時間化する可能性。design phase で並列化 / cache 戦略（前回走査結果の差分 incremental 走査等）を検討
- **第 4-8（中重要度）**: `rw follow-up list` の pagination 規定なし。Requirement 7.7 の handler ロジックで N=10,000 件返るケースに備え、design phase で max_results / pagination / filter（task_type / status / date range）を確定
- **第 4-9（軽微）**: status_reason / update_history.summary / Follow-up description / blockquote 文言の encoding 規定なし（UTF-8 前提が暗黙）。design phase で明示
- **第 4-10（軽微）**: handler 引数（target path / reason / merge_strategy 等）の sanitization 規定なし。design phase で path traversal 防止 / argument injection 防止等を明示
