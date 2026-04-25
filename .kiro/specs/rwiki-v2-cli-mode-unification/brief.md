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
- v1 から継承: モジュール責務分割（rw_<責務>.py、各 ≤ 1,500 行、DAG 依存、モジュール修飾参照）
