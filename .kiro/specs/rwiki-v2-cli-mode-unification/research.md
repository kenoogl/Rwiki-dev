# Research & Design Decisions: rwiki-v2-cli-mode-unification

## Summary

- **Feature**: `rwiki-v2-cli-mode-unification` (Spec 4、Phase 2)
- **Discovery Scope**: Extension + Complex Integration — Phase 1 (Spec 0 + Spec 1) approve 済 + Phase 0 (Spec 2 / 3 / 5 / 6 / 7) requirements approve 済からの coordination 受け取りを集約する CLI dispatch hub spec
- **Key Findings**:
  - **CLI dispatch wrapper の同型構造**: R9 (L2 Graph) / R15 (Decision Log) / R16 (review 層 dispatch) すべて「引数 parse → 他 spec API 呼出 → 結果整形 → exit code」の同型 → 共通 helper に抽象化可能
  - **v1 6 module DAG 構造の踏襲が最適**: v1-archive で確立済の `rw_config → rw_utils → rw_prompt_engine → {rw_audit, rw_query} → rw_cli` 5 層 DAG (合計 4007 行) を v2 でも踏襲、各モジュール ≤ 1500 行 / 修飾参照 / 後方互換 re-export 禁止 / DAG 循環禁止 を継承
  - **Maintenance UX を二層分離**: 「LLM CLI 側 system prompt (UX engine 本体) + Spec 4 側 data surfacer (構造化 JSON event)」の二層に分離、Python 側で UX engine 全実装しない (Scenario 33 の自然言語対話 + Spec 4 の閾値判定 + 計算 API 呼出の責務分離)

## Research Log

### Topic: SSoT 出典 (consolidated-spec) の精査

- **Context**: Spec 4 requirements は consolidated-spec v0.7.12 §2.11 / §3.4 / §3.5 / §6 / §7.2 Spec 4 を SSoT 出典として明示。design phase で各 section の実装含意を抽出する必要
- **Sources Consulted**:
  - `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.11 (ユーザー primary interface / Maintenance LLM guide)
  - 同 §3.4 (実行モード 3 種)
  - 同 §3.5 (コマンド 4 Level 階層)
  - 同 §6.1 (Task 一覧) / §6.2 (Command 一覧、約 60 種)
  - 同 §7.2 Spec 4 (in_scope / out_of_scope / Adjacent / `--auto` 表)
  - 同 §11.3 (v1 → v2 命名マッピング)
- **Findings**:
  - §2.11 = ユーザー primary interface = `rw chat` (default 入口) + L1 発見系 + LLM guide 経由の自然言語対話
  - §3.4 = 3 モード (Interactive / CLI 直接 / CLI Hybrid) は **同じ `cmd_*` エンジン関数を呼ぶ** 契約、出力統一・対話有無の差のみ
  - §3.5 = 4 Level 階層 (L1 発見 / L2 判断 / L3 メンテナンス / L4 Power user)、L1 発見はユーザー直接、L3 メンテは LLM guide 経由、L4 は CI 向け直接
  - §6 = Task 約 14 種 + Command 約 60 種 (`rw chat` / `rw lint` / `rw ingest` / `rw distill` / `rw approve` / `rw query *` / `rw audit *` / `rw graph *` / `rw edge *` / `rw reject` / `rw extract-relations` / `rw deprecate` / `rw retract` / `rw archive` / `rw reactivate` / `rw merge` / `rw split` / `rw tag *` / `rw skill *` / `rw follow-up *` / `rw decision *` / `rw doctor` / `rw check` / `rw init` / `rw retag` / `rw perspective` / `rw hypothesize` / `rw discover`)
  - §7.2 Spec 4 = `--auto` 許可 (deprecate / archive / reactivate / merge wiki 慎重 / unapprove `--yes` / tag merge / tag rename / skill install / extract-relations / reject `<edge-id>`) / 禁止 (retract / unapprove no-flag / promote-to-synthesis / tag split / skill retract)
  - §11.3 = v1 → v2 命名マッピング (例: `synthesize` → `distill`、`audit micro/weekly/monthly/quarterly` → `audit links/structure/semantic/strategic`)、互換エイリアスなし (フルスクラッチ)
- **Implications**:
  - design.md の Components 構成は §6.2 Command 一覧を網羅する `cmd_*` 関数群を sub-system 単位で整理する必要 (約 60 コマンドを 5-7 module に責務分割)
  - `rw chat` は単独 component として独立 (LLM CLI subprocess 起動 + Maintenance UX surfacer + 対話ログ自動保存 = 3 責務集約)
  - v1 → v2 命名マッピングは Migration Strategy section で明示、互換エイリアスは設置しない (フルスクラッチ規律)

### Topic: Maintenance UX 設計原則 (Scenario 33 / 14 / 15 / 25 / 18 / 35)

- **Context**: requirements R6 (候補提示) / R7 (複合診断) / R8 (autonomous) は scenarios.md Scenario 33 を SSoT 出典として明示、design phase で UX 実装規約を抽出
- **Sources Consulted**:
  - `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 33 (Maintenance UX 全般原則)
  - 同 Scenario 14 (Autonomous mode 関連、`rw chat --mode autonomous` / `/mode` トグル)
  - 同 Scenario 15 / 25 (対話ログ自動保存 / frontmatter スキーマ / markdown フォーマット)
  - 同 Scenario 18 (Pre-flight check、dangerous op 前の `--dry-run`)
  - 同 Scenario 35 (Reject queue UX、理由必須 + `--auto-batch` 1 件ずつ理由入力)
- **Findings**:
  - **Bad UX 禁止**: 曖昧指示 → 即拒絶 (「タスクが不明瞭です」) / 沈黙 / 不明確な選択肢 → S33 で明示禁止
  - **Good UX**: 候補リスト + 一行説明 + 直近作業からの推測根拠 + 前提条件併記 + 学習機会 (例「この操作は distill と言います」)
  - **複合診断 orchestration**: 「綺麗にしたい」発話 → L1/L2/L3 全層並行診断 → 優先順位提案 → 包括的承認時 halt-on-error で順次実行 (auto skip / retry なし)
  - **Autonomous trigger 6 種**: reject queue ≥10 / Decay ≥20 / typed-edge 整備率 <2.0 / Dangling ≥5 / Audit 未実行 ≥14 日 / 未 approve ≥5 (S33 §4.4)
  - **対話ログ frontmatter** (Spec 2 所管): `type: dialogue_log` / `session_id` (`YYYYMMDD-HHMMSS` ベース) / `started_at` / `ended_at` / `turns` / `skill` / `content_type`
  - **対話ログ保存 path**: `raw/llm_logs/chat-sessions/<timestamp>-<session-id>.md` (S15 命名規約) / append-only / 並行起動時の物理分離
  - **Pre-flight `--dry-run`** (S18): dangerous op の事前診断、対象ファイル検査 + L2 状態サマリ表示、8 段階対話の第 0 ステップとして機能可能
  - **Reject 理由必須** (S35): `rw reject <edge-id>` 実行時 `reject_reason_text` 空文字禁止、`--auto-batch` でも 1 件ずつ理由入力
- **Implications**:
  - Maintenance UX の **engine 本体は LLM CLI 側 system prompt** に集約 (Scenario 33 の自然言語対話は LLM の責務)、Spec 4 は **data surfacer** (閾値判定 + 計算 API 呼出 + 構造化 JSON event 提供) のみ実装
  - Autonomous trigger 6 種の閾値値は config 化 (R8.6)、計算実装は Spec 5 (L2) / Spec 7 (L3) API 呼出として委譲 (R8.7)
  - 対話ログ session_id は timestamp 単独では並行起動衝突リスク → timestamp + 短縮 uuid 形式が必要 (設計決定 4-13)
  - Pre-flight `--dry-run` を全 dangerous op に一律提供するか、対話 confirm 内 (8 段階対話) の第 0 ステップとして組み込むか → 設計決定 4-5 で確定 (escalate 案件)

### Topic: v1 module-split パターン (v1-archive/scripts/)

- **Context**: roadmap.md「v1 から継承する技術決定」で「モジュール責務分割 (v1 module-split)」が継承対象 (各 ≤ 1500 行 / DAG 依存 / モジュール修飾参照 / 後方互換 re-export 禁止)。v2 ではどのような module 構成で踏襲すべきか
- **Sources Consulted**:
  - `v1-archive/scripts/rw_config.py` (87 行)
  - `v1-archive/scripts/rw_utils.py` (294 行)
  - `v1-archive/scripts/rw_prompt_engine.py` (607 行)
  - `v1-archive/scripts/rw_audit.py` (1419 行 = 限度ギリギリ)
  - `v1-archive/scripts/rw_query.py` (842 行)
  - `v1-archive/scripts/rw_cli.py` (758 行)
  - 合計 4007 行、5 層 DAG: `rw_config → rw_utils → rw_prompt_engine → {rw_audit, rw_query} → rw_cli`
- **Findings**:
  - v1 6 module 構成: `rw_config` (定数のみ) / `rw_utils` (I/O / frontmatter / git / 日付 / exit code) / `rw_prompt_engine` (Claude CLI 呼出 / プロンプト構築) / `rw_audit` (audit 4 種) / `rw_query` (query extract/answer/fix) / `rw_cli` (エントリ + cmd_* dispatch)
  - 共通 helper の location: `_compute_run_status()` / `_compute_exit_code()` = `rw_utils` / `call_claude(prompt, timeout)` = `rw_prompt_engine` / argparse = `rw_cli` 内 cmd_* 関数で個別 parse (一部 `rw_query` で手製パーサ混在)
  - exit code 規約: 0 = PASS / 1 = runtime error or 入力エラー / 2 = FAIL (severity ERROR/CRITICAL ≥1 件)
  - subprocess timeout: v1 で `call_claude(timeout=None)` がデフォルト = 未設定 (audit 顕在化リスク)
  - Vault path 解決: `rw_config.ROOT = os.getcwd()` (Vault root) と `DEV_ROOT = Path(__file__).resolve().parent.parent` (Repo root) の二本立て
  - `rw_audit.py` 1419 行は限度ギリギリ → v2 で audit 内部分割 (`rw_audit.py` 本体 + `rw_audit_checks.py` 等) を計画的に行うのが妥当
- **Implications**:
  - v2 module 構成は v1 5 層 DAG パターンを踏襲しつつ、Spec 4 が新規所管する責務 (chat / dispatch / doctor / lock / lifecycle CLI / decision CLI / graph CLI / approve / maintenance UX) を 7-8 module に分割する必要
  - argparse 統一 (v1 一部手製 → v2 統一) を設計決定として明示 (4-3)
  - subprocess timeout 必須化を設計レベルで明示、CLI-level + per-call の 2 階層で運用 (4-4)
  - `rw_audit.py` 1500 行リスクは Spec 4 design では mitigation (audit 内部分割計画を File Structure Plan に記載)

### Topic: Phase 1 / Phase 0 spec からの coordination 受け取り

- **Context**: Spec 4 requirements の Boundary Context Adjacent expectations と change log で、Phase 1 (Spec 0 + Spec 1) approve 済 + Phase 0 (Spec 2 / 3 / 5 / 6 / 7) requirements approve 済からの coordination 要求が記録されている。design phase で全件を Components に組み込む必要
- **Sources Consulted**:
  - Spec 0 design.md (rwiki-v2-foundation) — 検証 4 種 / Foundation 引用形式 / `rw doctor foundation` 委譲
  - Spec 1 design.md (rwiki-v2-classification) — `rw doctor classification` / `rw approve` 拡張 / `.hygiene.lock` vocabulary 編集 / lint 統合 / `rw tag *` help text / Severity 4
  - Spec 2 requirements.md — 対話ログ frontmatter / skill 操作の lock / `applicable_input_paths`
  - Spec 3 requirements.md — Skill 選択 dispatch 5 段階優先順位 (3.5 = `applicable_input_paths` glob match)
  - Spec 5 requirements.md — Decision Log API 4 種 (`record_decision()` / `get_decisions_for()` / `search_decisions()` / `find_contradictory_decisions()`) + Tier 2 markdown timeline 生成機構 / Query API 15 種
  - Spec 6 requirements.md — `rw approve <hypothesis-id>` (id 指定 CLI、本 spec の path 指定とは別 operation) / autonomous mode 内部生成ロジック
  - Spec 7 requirements.md — Page lifecycle 状態遷移 / dangerous op 8 段階対話 handler / `cmd_promote_to_synthesis`
- **Findings**:
  - **Spec 0 由来 coordination**: `rw doctor foundation` サブコマンド実装 (検証 4 種 schema 規範を CLI に展開、Spec 0 決定 0-2)
  - **Spec 1 由来 coordination**: `rw doctor classification` (vocabulary 整合性検査) / `rw approve` 拡張 (`vocabulary_candidates/` 対応、R4.9) / `.hygiene.lock` vocabulary 編集 lock (R8.14、決定 1-14) / lint 統合 (Severity 4 / JSON output 統一、R9.2) / `rw tag *` help text 標準化 (本-22) / `successor_tag` rename CLI 対応 (決定 1-4)
  - **Spec 2 由来 coordination** (Adjacent Sync 反映済): `.hygiene.lock` 取得対象に write 系 `rw skill *` 操作追加 (R10.1) / 対話ログ frontmatter スキーマと markdown フォーマット (R1.8) / `applicable_input_paths` glob match (R13.4)
  - **Spec 3 由来 coordination** (Adjacent Sync 反映済): Skill 選択 dispatch 5 段階優先順位 (3.5 = `applicable_input_paths` glob match)
  - **Spec 5 由来 coordination**: Decision Log API 4 種 = `record_decision()` / `get_decisions_for()` / `search_decisions()` / `find_contradictory_decisions()` (Spec 5 R14 確定済 Query API 15 種の一部)、`rw decision render` の Tier 2 markdown timeline 生成機構は Spec 5 R11.11 規定、内部 API 名は Spec 5 design phase で確定 / `.hygiene.lock` の物理実装は Spec 5 所管 / L2 Graph Ledger 内部ロジック全部 Spec 5 委譲
  - **Spec 6 由来 coordination** (Adjacent Sync 反映済): `rw approve <hypothesis-id>` (id 指定、本 spec の `rw approve [<path>]` review 層 dispatch とは別 operation、三者命名関係) / `--mode autonomous` flag dispatch のみ Spec 4、内部生成ロジックは Spec 6
  - **Spec 7 由来 coordination**: Page lifecycle 状態遷移ルール (5 状態間遷移、`successor` / `merged_from` / `merged_into` セマンティクス、操作可逆性) / dangerous op 8 段階対話 handler (`cmd_promote_to_synthesis` 等) / L3 診断項目計算
- **Implications**:
  - design.md の Components 構成では各 coordination 要求を所管 component に明確に紐付け、cross-spec ↔ Spec 4 の boundary を再確認
  - 設計決定 4-1 (Foundation 引用形式) と 4-2 (検証 4 種実装責務) は Spec 0 / Spec 1 の決定をそのまま継承
  - `rw approve` の path 指定 (本 spec R16) と id 指定 (Spec 6 R9) の三者命名関係は設計決定 4-X で明示

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| **CLI Dispatch Hub (採択)** | Spec 4 = CLI 引数 parse + 他 spec API 呼出 wrapper、UX engine は LLM CLI 側 | 責務分離明確 / 他 spec 内部実装変更が CLI に波及しない / v1 module-split 踏襲可 | 多数 spec の coordination 受け取り | requirements の structure と一致、§7.2 Spec 4 in_scope と完全対応 |
| Monolithic CLI | 全 spec の内部ロジックを Spec 4 で集約実装 | 内部単純 / dispatch overhead なし | 他 spec の責務領域に侵入 / boundary 違反 / 巨大化 | requirements R12 (Foundation 規範準拠) / R13 (周辺 spec 責務分離) と矛盾、不採択 |
| Plugin Architecture | 各 spec が plugin として動的読込、Spec 4 は plugin loader | 高拡張性 / spec 追加時の修正最小化 | Python plugin 機構の overhead / monkeypatch テスト困難 / v1 modular split パターンと不一致 | v2 MVP 範囲外、過度な汎用化 (synthesis lens 3 で除外) |
| Microservice (subprocess IPC) | 各 spec を独立 subprocess、Spec 4 は IPC client | spec 間完全分離 / 言語非依存 | overhead 大 / atomicity 困難 / debug 困難 | v1 module-split が単一 process module 修飾参照を確立済、不採択 |

採択理由: **CLI Dispatch Hub** が requirements 構造 + v1 継承方針 + synthesis 3 lens (Generalization / Build vs Adopt / Simplification) すべてに整合。

## Design Decisions

### Decision 4-1: Foundation 文書本体への引用形式 = Spec 0 決定 0-1 / Spec 1 決定 1-1 継承

- **Context**: Spec 4 design / requirements / 将来 implementation での Foundation 引用形式統一
- **Alternatives Considered**:
  1. 独自引用形式 (例: `Foundation §2.4`) — 短縮されるが anchor 検証不能
  2. `.kiro/specs/rwiki-v2-foundation/foundation.md#<github-auto-id>` 形式 — Spec 0 / Spec 1 採用形式
- **Selected Approach**: 案 2 採択。Spec 0 決定 0-1 / Spec 1 決定 1-1 を Spec 4 でも踏襲
- **Rationale**: 検証 3 (用語集引用 link 切れ、Spec 0 design) の検査対象範囲に Spec 4 が組み込まれる、規範一貫性
- **Trade-offs**: 引用が冗長になる / link 検査対象が増える ↔ 規範 anchor 検証可能性
- **Follow-up**: Spec 4 implementation phase で全 Foundation 引用を `.kiro/specs/rwiki-v2-foundation/foundation.md#<anchor>` に統一

### Decision 4-2: 検証 4 種実装責務 = Spec 0 決定 0-2 継承

- **Context**: Foundation 検証 4 種 (章節アンカー存在 / SSoT 章番号整合 / 用語集引用 link 切れ / frontmatter schema 妥当性) の実装責務
- **Alternatives Considered**:
  1. Spec 0 が実装も所管 — Spec 0 brief 設計上限と矛盾
  2. Spec 4 が `rw doctor foundation` / `rw doctor classification` 等として実装 — Spec 0 決定 0-2
- **Selected Approach**: 案 2 採択。Spec 4 が `rw doctor foundation` (Foundation 規範整合性) / `rw doctor classification` (vocabulary 整合性) を `rw doctor` サブコマンド体系で実装
- **Rationale**: 検証 4 種の規範 = Spec 0、実装 = Spec 4 の責務分離、CLI 統一
- **Trade-offs**: Spec 4 design.md / implementation の coordination 要求が増える ↔ Spec 0 が実装責務を持たない (規範文書 spec の純粋性)
- **Follow-up**: Spec 4 implementation phase で `rw doctor` サブコマンド体系を構築、Foundation 規範 schema を input、JSON / human-readable 両 output

### Decision 4-3: モジュール分割 = v1 5 層 DAG パターン踏襲 (各 ≤ 1500 行)

- **Context**: roadmap.md「v1 から継承する技術決定」のモジュール責務分割を v2 でどう踏襲するか
- **Alternatives Considered**:
  1. v1 5 層 DAG パターン踏襲 (`rw_config → rw_utils → rw_prompt_engine → {rw_audit, rw_query} → rw_cli`) — v1 確立済
  2. 新 architecture pattern 導入 (hexagonal / clean arch 等) — v2 で initial 学習コスト
  3. 単一 module 集約 — v1 の `rw_light.py` 3490 行リスク再現
- **Selected Approach**: 案 1 採択。v1 5 層 DAG を踏襲し、Spec 4 新責務 (chat / dispatch / doctor / lock / lifecycle CLI / decision CLI / graph CLI / approve / maintenance UX) を 7-8 module に分割
- **Rationale**: v1 で運用実績あり / 各 module ≤ 1500 行制約で巨大化防止 / モジュール修飾参照規約で monkeypatch test patch が全呼出経路で作用 / DAG 循環禁止で依存方向明確
- **Trade-offs**: module 数増加 (v1 6 → v2 8-10) で import 文増加 ↔ 責務分離・テスト容易性
- **Follow-up**: File Structure Plan で具体 module 一覧 + 依存方向を明示

### Decision 4-4: argparse 採用 (v1 一部手製パーサ → v2 統一)

- **Context**: v1 では `rw_query.cmd_query_extract` で手製パーサが混在、v2 で引数 parse を統一すべきか
- **Alternatives Considered**:
  1. argparse 全コマンド統一 (Python 標準) — v1 の混在を解消
  2. click ライブラリ (第三者) — 機能豊富だが新規依存
  3. typer (第三者) — 型ヒント連携だが新規依存
  4. 手製パーサ継続 — v1 と同じ debt
- **Selected Approach**: 案 1 採択。argparse を全 cmd_* 関数で統一
- **Rationale**: Python 標準 / build vs adopt の adopt / 新規依存ゼロ / v1 の手製パーサ debt 解消 / `--auto` / `--dry-run` / `--yes` / `--scope` 等の共通 flag を共有可能
- **Trade-offs**: argparse の冗長性 (subparser ネスト) ↔ 標準依存 / 学習コスト不要
- **Follow-up**: 共通 `argparse.ArgumentParser` factory 関数を `rw_utils.py` に配置、各 cmd_* で `add_subparsers()` 経由で呼出

### Decision 4-5: subprocess timeout 2 階層 (CLI-level + per-call)

- **Context**: roadmap.md「v1 から継承する技術決定」で「subprocess timeout 必須」、v1 ではデフォルト未設定。v2 でどう運用するか
- **Alternatives Considered**:
  1. CLI-level timeout のみ (環境変数 `RWIKI_CLI_TIMEOUT`) — 簡単だが LLM CLI 個別呼出制御不可
  2. per-call timeout のみ (config file) — 個別制御可能だが CLI 全体 hang 防止不可
  3. 2 階層 (CLI-level + per-call) — 両方制御
- **Selected Approach**: 案 3 採択。CLI-level (env var, default 600 秒) + per-call (config / 引数, default 120 秒) の 2 階層
- **Rationale**: 大規模 vault (Edges > 10K, Pages > 1K) での hang 防止に CLI-level、個別 LLM CLI 呼出での timeout 制御に per-call、両方必要
- **Trade-offs**: 設定階層の複雑さ ↔ CI 環境 abort 対応 + 個別呼出制御の両立 / R4.9 (rw doctor 等の長時間 timeout) と整合
- **Follow-up**: Implementation で `rw_utils.get_cli_timeout()` / `rw_prompt_engine.call_claude(timeout=...)` を実装

### Decision 4-6: I-1 `/mute maintenance` 永続化媒体 = `<vault>/.rwiki/config.toml` の `[maintenance]` セクション (escalate 案件)

- **Context**: requirements R8.5 で「永続化媒体は本 spec の所管」と固定済、具体先は design 持ち越し (brief.md 持ち越し I-1)。候補は (a) `~/.rwiki/global.toml` (ユーザー global) / (b) `<vault>/.rwiki/config.toml` (vault 別)
- **Alternatives Considered**:
  1. `~/.rwiki/global.toml` の `[maintenance]` セクション — ユーザー個人空間、vault を跨ぐ
  2. `<vault>/.rwiki/config.toml` の `[maintenance]` セクション — vault ごとに独立
  3. 両方併用 (vault 設定が global を override) — 柔軟だが UX 複雑
- **Selected Approach**: 案 2 採択 (escalate 結果)。`<vault>/.rwiki/config.toml` の `[maintenance]` セクションに `mute = true` / `mute_until = <ISO 8601>` を保存
- **Rationale**: vault 別 maintenance 制御は Curated GraphRAG の vault-scoped 性質と整合 / `~/.rwiki/global.toml` 案は v2 では未導入の global config 概念を新規導入する追加コスト / 案 3 (両方併用) は dominated
- **Trade-offs**: ユーザーが複数 vault を持つ場合 vault ごとに `/mute` 必要 ↔ vault 別の運用ポリシー独立性
- **Follow-up**: `rw chat` 起動時に `<vault>/.rwiki/config.toml` を読み込み、`[maintenance].mute` フラグで Maintenance UX surface 抑止判定

### Decision 4-7: B-7 dangerous op pre-flight `--dry-run` 一律提供 (escalate 案件)

- **Context**: requirements brief.md 持ち越し B-7、dangerous op 13 種に `--dry-run` 一律提供すべきか、対話 confirm 内 (8 段階対話) の第 0 ステップとして組み込むか
- **Alternatives Considered**:
  1. `--dry-run` 全 dangerous op に一律提供 — CLI 直接実行モードでの事前診断容易
  2. 対話 confirm 内 第 0 ステップとして組み込み (Foundation §2.4 8 段階対話の Pre-flight warning ステップ) — 対話 UX 統一
  3. 両方提供 — 冗長
- **Selected Approach**: 案 2 採択 (escalate 結果)。8 段階対話の第 0 ステップ (Pre-flight warning) として組み込み、CLI 直接実行モードでも `rw <op> --dry-run` を **重い dangerous op (`rw deprecate` / `rw merge` / `rw split` / `rw archive` / `rw retract`) に限定して提供**
- **Rationale**: 対話 UX 統一 (8 段階対話で完結) / 軽量 op (例: `rw reactivate`) では `--dry-run` 過剰 / 案 1 全 op 一律は API 表面積の肥大化 / 案 3 両方は dominated (8 段階対話の Pre-flight が CLI mode でも機能)
- **Trade-offs**: 軽量 op に `--dry-run` がない不一致 ↔ API 表面積最小化 / 対話 UX 一貫性
- **Follow-up**: Spec 7 design phase で 8 段階対話の各段階を確定、本 spec は CLI dispatch 側 (引数 parse + 第 0 ステップ trigger) のみ実装

### Decision 4-8: I-3 HTML 差分マーカー attribute = Phase 2/3 Spec 2 / Spec 7 design 委譲

- **Context**: requirements brief.md 持ち越し I-3、HTML 差分 marker (例: `<ins>` / `<del>` / class 等) の attribute 詳細は本 spec で確定すべきか
- **Alternatives Considered**:
  1. 本 spec で確定 — Spec 2 / Spec 7 への影響を予測する必要
  2. Phase 2/3 (Spec 2 / Spec 7 design) で確定 — 各 spec の dangerous op 文脈で確定
- **Selected Approach**: 案 2 採択。本 spec は CLI 側の差分プレビュー dispatch のみ所管、HTML attribute 詳細は Spec 2 (Skill ファイル diff) / Spec 7 (Page lifecycle diff) の design phase で確定
- **Rationale**: HTML 差分は dangerous op の対話 UI で使われるが、attribute 詳細は各 spec の差分意味論に依存 / 本 spec で先行確定すると Phase 2/3 で再交渉リスク
- **Trade-offs**: 本 spec design 段階で詳細未確定 ↔ Spec 2 / Spec 7 design の自由度確保
- **Follow-up**: Spec 7 design phase でまず attribute schema 提案、必要なら Spec 4 への Adjacent Sync

### Decision 4-9: 本-Q / 整-5 status 表記の出力 contract = `rw doctor` / `rw graph status` / `rw edge show` で 6+5 状態区別表示

- **Context**: requirements brief.md 持ち越し 本-Q / 整-5、Edge status 6 種 (`weak` / `candidate` / `stable` / `core` / `deprecated` / `rejected`) と Page status 5 種 (`active` / `deprecated` / `retracted` / `archived` / `merged`) を CLI 出力で区別する具体コマンド (R12.3)
- **Alternatives Considered**:
  1. 共通 status table を全コマンドで共有 — 簡潔だが Edge と Page の混同リスク
  2. コマンド別に専用 table を持つ — 冗長だが明示的
  3. 出力 contract を section header で区別 (`## Page Status` / `## Edge Status`) — Markdown 出力で明示
- **Selected Approach**: 案 3 採択。`rw doctor` (両方表示) / `rw graph status` (Edge 6 種) / `rw edge show` (Edge 6 種) / `rw deprecate --dry-run` (Page 5 種) で section header 区別 + colorize (CRITICAL=赤 / ERROR=橙 / WARN=黄 / INFO=青)
- **Rationale**: Foundation R5 (Edge / Page status 区別必須) と整合 / Markdown header 区別は CommonMark 準拠で自動的にツール解釈可能 / colorize は terminal output で視認性向上
- **Trade-offs**: colorize は ANSI escape sequence 依存 (CI 環境では `--no-color` flag) ↔ 視認性
- **Follow-up**: `rw_utils.format_status_table(statuses, kind: 'edge' | 'page')` helper 関数を実装

### Decision 4-10: B-4 AGENTS 自動ロード時の改ざん検知 = MVP 範囲外、Phase 2 以降 Spec 2 design で再検討

- **Context**: requirements brief.md 持ち越し B-4、`rw chat` 起動時に AGENTS/ 配下を自動ロードする際の改ざん検知 (hash / signing) を本 spec で実装すべきか
- **Alternatives Considered**:
  1. 本 spec MVP で hash 検知実装 — sha256 計算 + 期待 hash 比較
  2. Phase 2 以降 Spec 2 (skill-library) design で再検討 — Skill ファイル全般の整合性検査と統合
  3. 検知不要 (利用者責任) — セキュリティリスク残存
- **Selected Approach**: 案 2 採択。本 spec MVP は AGENTS 自動ロード機構のみ提供、改ざん検知は Spec 2 design で `rw skill verify` 等の専用 CLI として実装
- **Rationale**: AGENTS 配下は Skill ファイル群と Skill 文書群が混在、改ざん検知は Skill 全体の整合性 (signature / hash / digital sign) として Spec 2 で統合的に設計するのが適切 / MVP では信頼境界を「Vault 内ファイル = 利用者責任」とする
- **Trade-offs**: MVP セキュリティリスク残存 ↔ Spec 2 design での統合的設計余地
- **Follow-up**: Phase 2 以降 Spec 2 design で `rw skill verify` / hash schema を確定、本 spec への Adjacent Sync

### Decision 4-11: 設計決定二重記録 = Spec 0 決定 0-4 / Spec 1 決定 1-2 継承

- **Context**: 設計決定記録方式 (ADR 独立ファイル vs design.md 本文 + change log)
- **Alternatives Considered**:
  1. ADR 独立ファイル (`docs/adr/`) — 過去 LLM が忘却し機能せず (memory feedback_design_decisions_record.md)
  2. design.md 本文「設計決定事項」セクション + change log の二重記録 — Spec 0 / Spec 1 採用
- **Selected Approach**: 案 2 採択。Spec 0 決定 0-4 / Spec 1 決定 1-2 を Spec 4 でも踏襲
- **Rationale**: 二重記録で LLM 忘却リスク mitigation / change log 1 行サマリで履歴可視性
- **Trade-offs**: design.md 肥大化 (Spec 1 = 1295 行) ↔ 設計決定 traceability
- **Follow-up**: 本 design.md の「設計決定事項」セクションに 4-1〜4-N を記録、change log に 1 行サマリ

### Decision 4-12: `rw doctor` JSON output `schema_version` 管理体系 = semantic versioning (`major.minor.patch`)

- **Context**: requirements R4.8 で「JSON 出力には `schema_version` field を必須として含める」と明示、具体管理体系は design 持ち越し
- **Alternatives Considered**:
  1. semantic versioning (`major.minor.patch`、例: `1.0.0`) — 業界標準、breaking change は major bump
  2. 連番 (`1` / `2` / `3`) — 簡単だが breaking / non-breaking 区別不能
  3. 日付ベース (`20260427`) — 確定日明示だが互換性判定不可
- **Selected Approach**: 案 1 採択。`schema_version: "1.0.0"` 形式、major bump = breaking change / minor bump = additive change / patch bump = bug fix
- **Rationale**: 業界標準 / CI 下流 consumer が major bump で破壊的変更検知可能 / 案 2 / 3 は dominated (互換性判定機能不足)
- **Trade-offs**: version 番号 3 階層の管理コスト ↔ 互換性判定機能性
- **Follow-up**: `rw doctor` 初版 schema は `1.0.0` (Spec 4 implementation phase 確定)、change log で schema 変更履歴を別途維持

### Decision 4-13: 対話ログ session_id 規約 = `YYYYMMDD-HHMMSS-<uuid4-4hex>` 形式

- **Context**: requirements R1.8 で「複数の `rw chat` セッションが同時起動された場合、各セッションに一意の session_id を付与」と明示、Scenario 15 では timestamp 単独形式 (`YYYYMMDD-HHMMSS`)。並行起動衝突リスクの対策が必要
- **Alternatives Considered**:
  1. timestamp 単独 (`YYYYMMDD-HHMMSS`) — Scenario 15 形式、秒単位精度では衝突リスク残存
  2. timestamp + 短縮 uuid (`YYYYMMDD-HHMMSS-<uuid4-4hex>`) — 衝突リスク 1/65536 = 実質ゼロ
  3. timestamp + プロセス PID (`YYYYMMDD-HHMMSS-<pid>`) — 同 PID 再起動衝突リスク
  4. UUID 単独 (`<uuid4>`) — timestamp 順序情報喪失
- **Selected Approach**: 案 2 採択。`<timestamp>-<uuid4-4hex>` 形式 (例: `20260427-153000-a3f9`)、対話ログ path は `raw/llm_logs/chat-sessions/<session_id>.md`
- **Rationale**: 衝突リスク 1/65536 で実質ゼロ / timestamp 順序情報保持 / Scenario 15 timestamp 形式と前方互換 (timestamp prefix 維持) / 案 3 / 4 は dominated
- **Trade-offs**: session_id 文字列長増加 (15 → 20 chars) ↔ 衝突リスク回避
- **Follow-up**: Spec 2 design phase で対話ログ frontmatter `session_id` field 形式と整合確認

### Decision 4-14: Maintenance UX engine 二層分離 = LLM CLI system prompt + Spec 4 data surfacer

- **Context**: requirements R6 / R7 / R8 で Maintenance UX を Spec 4 が所管。UX engine 全部を Python 側で実装するか、LLM CLI と分担するか
- **Alternatives Considered**:
  1. UX engine 全部 Python 側で実装 — 自然言語対話を Python で処理する難しさ
  2. UX engine 全部 LLM CLI 側 system prompt — 計算実装 (閾値判定 / API 呼出) を LLM に委ねるリスク
  3. 二層分離 (LLM CLI system prompt = UX engine 本体 / Spec 4 = data surfacer) — 責務分離
- **Selected Approach**: 案 3 採択。Maintenance UX engine 本体は LLM CLI 側 system prompt (Scenario 33 の自然言語対話)、Spec 4 は data surfacer (閾値判定 + 計算 API 呼出 + 構造化 JSON event 提供) のみ実装
- **Rationale**: 自然言語対話は LLM の責務、計算 / API 呼出は Python の責務 / synthesis lens 3 (Simplification) と整合 / Python 側で UX engine 全実装するのは過度な汎用化
- **Trade-offs**: LLM CLI system prompt と Python data surfacer の境界面定義が必要 ↔ 責務分離 / Python 側コード量削減
- **Follow-up**: Spec 4 implementation phase で LLM CLI に渡す system prompt template を `AGENTS/maintenance_ux.md` 等に配置、Python data surfacer は構造化 JSON event (`type: maintenance_event` / `triggers: [...]` / `priorities: [...]`) を出力

### Decision 4-15: `rw doctor` CLI-level timeout default = 300 秒、`--timeout <sec>` で override

- **Context**: requirements R4.9 で「rw doctor / rw graph status / rw graph hubs / rw graph neighbors 等の長時間実行可能なコマンドは CLI 側で timeout 設定可能、Edges > 10K / Pages > 1K 規模で hang 時 abort 可能」と明示。default 値が design 持ち越し
- **Alternatives Considered**:
  1. CLI-level default 60 秒 — CI 短時間向け、本格運用 hang リスク
  2. CLI-level default 300 秒 (5 分) — 中庸、`--timeout` で override
  3. CLI-level default 1800 秒 (30 分) — 大規模 vault 余裕、CI 環境 hang リスク
  4. timeout 無し (None) — v1 と同じ debt 再現
- **Selected Approach**: 案 2 採択。CLI-level default 300 秒、`--timeout <sec>` 引数または `RWIKI_CLI_TIMEOUT` 環境変数で override
- **Rationale**: 5 分は中規模 vault (Edges 5K-10K) の `rw doctor` 完走に十分 / `--timeout` override で大規模 vault 対応 / 案 1 短すぎ / 案 3 長すぎ / 案 4 は v1 debt 継承 (不採択)
- **Trade-offs**: 大規模 vault でのデフォルト hang リスク ↔ CI 環境応答性
- **Follow-up**: Spec 4 implementation phase で `rw_utils.get_cli_timeout()` 実装、決定 4-5 (subprocess timeout 2 階層) と統合

### Decision 4-16: review 層 dispatch routing = `<path>` から正規表現で 6 review 層判別 + spec 別 handler 委譲

- **Context**: requirements R16.1 で `rw approve [<path>]` が 6 review 層 (synthesis_candidates / vocabulary_candidates / audit_candidates / relation_candidates / decision-views / .follow-ups) を判別する規約を明示、具体 routing logic は design 持ち越し
- **Alternatives Considered**:
  1. ファイル frontmatter から判別 — frontmatter parse 必要、I/O コスト
  2. `<path>` 正規表現 (`review/synthesis_candidates/.*` 等) — 軽量 / 確定的
  3. ディレクトリ存在確認 — Vault 構造依存
- **Selected Approach**: 案 2 採択。正規表現 dispatch table:
  - `review/synthesis_candidates/.*` → Spec 7 page lifecycle API
  - `review/vocabulary_candidates/.*` → Spec 1 vocabulary 反映 API
  - `review/audit_candidates/.*` → 本 spec audit task 反映
  - `review/relation_candidates/.*` → Spec 5 edge 反映 API
  - `review/decision-views/.*` → approve 対象外 (R16.6、stderr 通知 + exit 1)
  - `wiki/.follow-ups/.*` → approve 対象外 (R16.7、stderr 通知 + exit 1)
  - `review/hypothesis_candidates/.*` → path 指定 dispatch 対象外 (Spec 6 R9 `rw approve <hypothesis-id>` 経由を案内、stderr 通知 + exit 1)
- **Rationale**: 正規表現は確定的 / I/O 不要 / Vault 構造変更時は dispatch table 更新のみ / 案 1 / 3 は dominated
- **Trade-offs**: dispatch table の hard-code ↔ 軽量性 / Vault 構造規約の明示
- **Follow-up**: `rw_dispatch.dispatch_approve_path(path)` 関数を実装、各 spec API は内部 import

### Decision 4-17: `rw approve` 三者命名関係 = path 指定 (本 spec R16) と id 指定 (Spec 6 R9) を別 operation として明示

- **Context**: Spec 6 R9 が `rw approve <hypothesis-id>` (Hypothesis 専用昇格 CLI、id 指定、内部で Spec 7 `cmd_promote_to_synthesis` 8 段階対話 handler 呼出) を確定、本 spec R16 の `rw approve [<path>]` (review 層 dispatch、path 指定) との関係明示が必要
- **Alternatives Considered**:
  1. id 指定を本 spec の review 層 dispatch に統合 — Spec 6 R9.9 の三者命名関係と矛盾
  2. id 指定と path 指定を別 operation として明示 (現行 Spec 6 R9.9 と整合) — 命名衝突回避
  3. id 指定を `rw promote-to-synthesis` 等の別 CLI に分離 — Spec 6 R9 と矛盾
- **Selected Approach**: 案 2 採択。`rw approve <ARG>` の `<ARG>` が id 形式 (例: `hyp_a3f9`) なら id 指定 = Hypothesis 昇格 (Spec 6 R9 経由)、path 形式 (例: `review/synthesis_candidates/foo.md`) なら path 指定 = review 層 dispatch (本 spec R16)
- **Rationale**: Spec 6 R9.9 / 本 spec R3.3 注記 / 本 spec R16.1 注記すべて整合 / 引数形式 (id vs path) で operation 分岐は確定的判定 (id 形式は `[a-z]+_[a-f0-9]{4,}` 等の正規表現で判別可能)
- **Trade-offs**: 引数形式判定の hard-code ↔ Spec 6 / 本 spec / Spec 7 の三者命名関係維持
- **Follow-up**: `rw_dispatch.parse_approve_argument(arg)` 関数で id / path 判別、id なら Spec 6 R9 経由、path なら R16 経由

### Decision 4-18: `--auto` 強制バイパス禁止実装 = 環境変数 / 引数 / config いずれも禁止、bypass 試行は exit 1 + INFO log

- **Context**: requirements R3.3 で「環境変数や非標準起動オプションを介して禁止リストの `--auto` を強制 on にするバイパス経路を提供しない」と明示、具体実装規律は design 持ち越し
- **Alternatives Considered**:
  1. 環境変数バイパス無効化のみ (引数 / config からは可能) — 不完全
  2. 環境変数 + 引数 + config 全面禁止 (実装で `RWIKI_FORCE_AUTO=1` 等を検出して exit 1) — 完全
  3. Maintenance UX 包括承認も bypass として機能しない — R7.5 と整合
- **Selected Approach**: 案 2 + 3 採択。`RWIKI_FORCE_AUTO` 等の環境変数 / `--force-auto` 等の引数 / config の `force_auto: true` いずれも検出して exit 1 + INFO log 出力 (「禁止リスト 5 種は `--auto` バイパス不可、対話 confirm 必須」)、Maintenance UX 包括承認も bypass として機能しない
- **Rationale**: 「禁止」の意味は実装で守られて初めて成立 / R3.3 の規範を実装で機械的に強制 / Maintenance UX bypass 禁止は R7.5 と整合
- **Trade-offs**: bypass 検出 logic 追加 ↔ 規範強制
- **Follow-up**: `rw_policy.check_auto_bypass_attempt(args, env)` 関数を実装、全 dangerous op cmd_* で必ず呼出 (gate)

### Decision 4-19: Spec 1 R6.1 `successor_tag` rename への CLI 対応 (Adjacent Sync 反映済)

- **Context**: Spec 1 決定 1-4 で `tags.yml` field `successor` → `successor_tag` rename が確定、Spec 4 の `rw tag *` CLI / `rw lint` / `rw approve` 拡張も `successor_tag` 形式で動作する必要
- **Alternatives Considered**:
  1. CLI で `successor` field を継続サポート (後方互換) — Spec 1 R6.1 (実質変更経路) と矛盾
  2. CLI で `successor_tag` のみサポート (Spec 1 改版と整合) — 実質変更経路の徹底
- **Selected Approach**: 案 2 採択。Spec 4 implementation で `successor_tag` のみ実装、`successor` (旧 field) は migration 用の WARN として lint 検出
- **Rationale**: Spec 1 R6.1 改版と整合 / フルスクラッチ方針で後方互換不要 / migration 用 WARN は移行支援
- **Trade-offs**: 既存 `tags.yml` (もしあれば) の手動 migration 必要 ↔ Spec 1 R6.1 整合 / 命名衝突回避 (`wiki frontmatter.successor` との)
- **Follow-up**: Spec 4 implementation phase で `rw_lint_vocabulary.py` (Spec 1 R9.2 拡張) に「`successor` field 検出 → `successor_tag` 移行 WARN」検査項目を追加

## Risks & Mitigations

- **Risk 1 — Spec 5 / Spec 6 / Spec 7 design phase 未完による API signature 未確定** (Spec 5 Decision Log API 4 種 / Spec 6 autonomous mode 内部生成 / Spec 7 page lifecycle handler) — Mitigation: Phase 3-5 design phase 着手時の Adjacent Sync で内部 API 名を確定、本 spec implementation phase は Phase 5 完了後に開始
- **Risk 2 — `rw audit` モジュール (`rw_audit.py`) 1500 行制約超過** — Mitigation: File Structure Plan で `rw_audit.py` (audit 4 種 + audit graph dispatch) と `rw_audit_checks.py` (各 check 関数) の分割計画を明示、初期実装で分割粒度を計画
- **Risk 3 — Maintenance UX 二層分離の責務境界曖昧化** — Mitigation: 構造化 JSON event schema (`type` / `triggers` / `priorities` / `subjects`) を本 spec design で確定、LLM CLI system prompt template も本 spec implementation で固定
- **Risk 4 — `--auto` バイパス試行の網羅検出漏れ** — Mitigation: `rw_policy.check_auto_bypass_attempt()` を 全 dangerous op cmd_* の入口で gate 化、unit test で全環境変数 / 引数 / config 経路を網羅
- **Risk 5 — 大規模 vault (Edges > 10K) での `rw doctor` hang** — Mitigation: 決定 4-15 で CLI-level default 300 秒 + `--timeout` override、決定 4-5 (subprocess timeout 2 階層) と統合
- **Risk 6 — review 層 dispatch routing table の hard-code 規律** — Mitigation: 決定 4-16 で正規表現 dispatch table、Vault 構造変更時は本 spec design 改版経路 (Adjacent Sync) で更新

## References

- [`.kiro/drafts/rwiki-v2-consolidated-spec.md`](../../drafts/rwiki-v2-consolidated-spec.md) v0.7.12 §2.11 / §3.4 / §3.5 / §6 / §7.2 Spec 4 / §11.3 — Spec 4 SSoT 出典
- [`.kiro/drafts/rwiki-v2-scenarios.md`](../../drafts/rwiki-v2-scenarios.md) Scenario 33 / 14 / 15 / 25 / 18 / 35 — Maintenance UX 設計原則
- [`.kiro/specs/rwiki-v2-foundation/design.md`](../rwiki-v2-foundation/design.md) — Spec 0 design (Phase 1 完了、設計決定 0-1〜0-5、検証 4 種規範)
- [`.kiro/specs/rwiki-v2-classification/design.md`](../rwiki-v2-classification/design.md) — Spec 1 design (Phase 1 完了、設計決定 1-1〜1-16、Coordination 受け取り)
- [`v1-archive/scripts/`](../../../v1-archive/scripts/) — v1 5 層 DAG パターン (合計 4007 行、参考)
- [`.kiro/steering/roadmap.md`](../../steering/roadmap.md) — v1 から継承する技術決定 / Adjacent Spec Synchronization
- [`.kiro/steering/structure.md`](../../steering/structure.md) — Vault 構造 / コマンド 4 Level 階層 / Code Organization Principles
- [`.kiro/steering/tech.md`](../../steering/tech.md) — 実行モード 3 種 / Severity 4 / Exit code 0/1/2 / subprocess timeout 必須

---

_change log_

- 2026-04-27: 初版生成 — Spec 4 (cli-mode-unification) design phase 着手用、Light Discovery + Synthesis 3 lens 完了。設計決定 4-1〜4-19 (うち 4-1 / 4-2 / 4-11 は Spec 0 / Spec 1 継承) を確定。Risks & Mitigations 6 件記録。Phase 1 (Spec 0 + Spec 1) approve 済 + Phase 0 (Spec 2 / 3 / 5 / 6 / 7) requirements approve 済からの coordination 受け取りを Components 構成に反映予定。
