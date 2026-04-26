# Brief: rwiki-v2-cli-mode-unification

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §6, §7.2 Spec 4

## Problem

v1 では `rw_light.py` が散発的にコマンドを追加してきた結果、起動方式が混在し（CLI 直接 / Hybrid / Prompt-only）、対話型エントリも統一されていない。L2 Graph Ledger 操作（graph / edge / reject / extract-relations / audit graph）を追加する際、既存の散発構造のままでは UX が壊れる。Maintenance UX（曖昧指示への候補提示、複合診断 orchestration、Autonomous maintenance）も未整備。

## Current State

- consolidated-spec §6（Task & Command モデル）に v2 のコマンド名と Task 一覧が定義済
- §3.4 実行モード（Interactive / CLI 直接 / CLI Hybrid）が確定
- v1 の `rw_cli.py` は `v1-archive/scripts/`、CLI 構造の参考資料
- Scenario 33 で Maintenance UX の方針（候補提示、複合診断、autonomous）が合意済

## Desired Outcome

- すべてのタスクが `rw <task>` で統一起動される
- 対話型エントリ `rw chat` が default 入口として機能
- L2 Graph Ledger 管理コマンド（`rw graph *` / `rw edge *` / `rw reject` / `rw extract-relations` / `rw audit graph`）が CLI として提供される（内部は Spec 5 の API 呼出）
- Maintenance UX が動作（曖昧指示の候補提示、複合診断 orchestration、Autonomous maintenance 提案）
- Dangerous op コマンドは default 対話型、`--auto` は明示時のみ

## Approach

CLI のエントリは `rw_cli.py`、各タスクを `cmd_*` 関数で実装。`rw chat` は LLM CLI を起動し AGENTS を自動ロード、対話中に `rw <task>` を内部呼出。L2 Graph 管理コマンドは Spec 5 の Query / Mutation API を呼ぶ薄いラッパー。Maintenance UX は autonomous trigger（reject queue 蓄積 / decay 進行 / audit 未実行等）を surface する。

## Scope

- **In**:
  - `rw chat` コマンド（LLM CLI 起動、AGENTS 自動ロード、Maintenance UX 含む）
  - 各タスクの CLI 統一（`rw distill` / `rw approve` / `rw lint` / `rw audit` / `rw query` 等）
  - 対話型 default / `--auto` フラグの可否
  - `rw check <file>` 診断コマンド
  - `rw follow-up *` コマンド群
  - Maintenance UX（候補提示、複合診断 orchestration、Autonomous maintenance）
  - L2 Graph Ledger 管理コマンド（`rw graph` / `rw edge` / `rw reject` / `rw extract-relations` / `rw audit graph`）
  - `rw doctor` 複合診断コマンド
- **Out**:
  - Skill library 実装（Spec 2）
  - Graph Ledger の内部ロジック（Spec 5）
  - Page lifecycle 状態遷移（Spec 7）

## Boundary Candidates

- CLI dispatch とコマンド実装（本 spec）と内部ロジック（各 spec）
- Maintenance UX 表示（本 spec）と autonomous trigger 計算（Spec 5 / Spec 6）
- 対話エントリ（本 spec）と LLM 推論（外部 LLM CLI）

## Out of Boundary

- Skill 選択ロジック（Spec 3）
- L2 Ledger の data model / 進化則（Spec 5）
- Page lifecycle の状態遷移ルール（Spec 7）

## Upstream / Downstream

- **Upstream**: rwiki-v2-foundation（Spec 0）/ rwiki-v2-classification（Spec 1）
- **Downstream**: rwiki-v2-lifecycle-management（Spec 7 — dangerous op CLI ハンドラ）/ rwiki-v2-knowledge-graph（Spec 5 — graph CLI のバックエンド）

## Existing Spec Touchpoints

- **Extends**: なし（新規）
- **Adjacent**: v1 `cli-query` / `cli-audit` / `module-split` / `rw-light-rename`（v1-archive、責務別モジュール分割と CLI 命名統一の参考）

## Constraints

- `rw chat` はエディタ内蔵ターミナル（VSCode / Obsidian）や別プロセスから起動可能
- 対話中に LLM が Bash tool 等で `rw <task>` を内部呼出
- Dangerous op コマンドの default は対話型
- `--auto` 許可: deprecate / archive / reactivate / tag merge / tag rename / skill install / extract-relations / reject `<edge-id>` 指定時
- `--auto` 不可: retract / unapprove / promote-to-synthesis / tag split / skill retract
- L4 Power user 向けに全コマンド直接実行も提供（CI/CD 対応）
- v2 のコマンド名は §6 で定義済、本 spec はその名前で実装するだけ（v1 命名マッピングは §11.3 参照）

## Coordination 必要事項

- **Spec 4 ↔ Spec 5**: `.rwiki/.hygiene.lock` Concurrency strategy の整合
- **Spec 4 ↔ Spec 5**: Decision Log API（`record_decision()` / `query_decisions()` / `find_contradictions()` / `render_decision_timeline()`）契約 — Requirement 15 / 16 由来
- **Spec 4 ↔ Spec 1**: `rw approve` の `vocabulary_candidates/` dispatch 拡張 — Spec 1 Requirement 4.9 / 本 spec Requirement 16 由来
- **Spec 4 ↔ Spec 1**: vocabulary 変動操作（`rw tag merge / split / rename / deprecate / register`）の `.hygiene.lock` 取得 — Spec 1 Requirement 8.14 / 本 spec Requirement 10.1 由来
- **Spec 4 ↔ Spec 1**: `source:` field の重複検出・canonical 化 audit — Spec 1 Requirement 5 Adjacent expectations / 本 spec Requirement 13.5 由来
- **Spec 4 ↔ Spec 2**: `rw chat` 対話ログ frontmatter スキーマと markdown フォーマット — drafts Scenario 15 / 25 / 本 spec Requirement 1.8 由来
- **Spec 4 ↔ Spec 6**: 対話ログ保存 trigger の規定（perspective / hypothesis 生成時等）
- **Spec 4 ↔ Spec 7**: `rw doctor` の L3 診断項目計算 API — 本 spec Requirement 4 由来
- **Spec 4 ↔ Spec 7**: `rw merge` (wiki) / `rw split` (wiki) の状態遷移ルール — 本 spec Requirement 3 / 13.2 由来
- v1 から継承: モジュール責務分割（rw_<責務>.py、各 ≤ 1,500 行、DAG 依存、モジュール修飾参照）

## Design phase 持ち越し項目（requirements レビューで合意、design phase で詰める）

### 要件レベルでは固定せず design phase で確定する項目

- **I-1**: `/mute maintenance` 永続化媒体の具体先（候補: `.rwiki/config.toml` の `[maintenance]` セクション or `~/.rwiki/global.toml`、Requirement 8.5 で「永続化媒体は本 spec の所管」と固定済、具体先は design）
- **整-3**: `rw follow-up resolve <file>` 実行時の状態変更表現（Spec 7 lifecycle 規約と整合、Requirement 5.4 で再委譲）
- **本-C**: Foundation §2.4 Dangerous ops 8 段階対話の各段の入力 / 出力 / abort 条件の AC 化レベル（Requirement 3.5 で Foundation 委譲済、design で詳細化）
- **本-G**: `rw init` で生成する Vault 構造の最小集合の引用先（Foundation §3 / drafts §5 を SSoT として参照、本 spec で繰り返さない、design で具体化）
- **本-N**: lock 待機なし規約の UX 影響（高頻度 batch 環境での再試行戦略、Requirement 10.2 で「待機なし即 exit 1」と固定済、再試行はクライアント側責務として design 持ち越し）
- **本-Q**: Edge status 6 種 / Page status 5 種の人間可読表記（短縮 vs full、colorize、status 区別を保証する出力 contract、Requirement 12.3 と整合）
- **整-5**: Requirement 12.3「Edge status 6 種と Page status 5 種を CLI 出力で区別」を保証する具体コマンド（`rw doctor` / `rw graph status` / `rw edge show` 等の出力 contract）
- **B-4**: AGENTS 自動ロード時の改ざん検知（hash / signing）— Spec 2 / Spec 3 所管寄り、本 spec での AC 化は design 持ち越し
- **B-7**: dangerous op の事前 dry-run 一律提供（drafts Scenario 18 pre-flight 連携）— `rw deprecate --dry-run` 等の必要性は design phase で判断

### 設計時に詳細化する API / Schema

- 対話ログ frontmatter スキーマ（Spec 2 所管、本 spec design 時点で Spec 2 が確定済か確認）
- Decision Log API の signature（`query_decisions(filter)` の filter スキーマ、`render_decision_timeline()` の出力 markdown スキーマ等、Spec 5 所管）
- `rw doctor` JSON 出力の `schema_version` 値の管理体系（semantic version 採用可否、design 持ち越し）
- `rw chat --mode autonomous` の `/mode` トグルコマンド構文（Requirement 1.9、Spec 6 の autonomous mode 内部生成ロジックと協調 design）
