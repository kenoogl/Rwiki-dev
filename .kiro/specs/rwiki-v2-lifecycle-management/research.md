# Research & Design Decisions

## Summary

- **Feature**: `rwiki-v2-lifecycle-management` (Spec 7)
- **Discovery Scope**: Complex Integration (Page lifecycle 5 状態遷移 + Page→Edge orchestration + dangerous op 13 種 + Follow-up registry + L3 診断 API + Skill lifecycle + 11 種 AGENTS guide)
- **Key Findings**:
  - Spec 4 design.md (commit `4bc89f7`) が Spec 7 への coordination 申し送り 7 項目を確定済 (line 2019-2029)。本 spec design は申し送り 7 項目 + Spec 4 design 内 Spec 7 引用 30+ 箇所と整合させる必要がある。
  - Spec 1 design.md (commit `7543536`) が L3 frontmatter `status:` 関連 9 field schema を確定済。本 spec は schema を継承し、`update_history.type` lifecycle 起源値域 (deprecation / retract / archive / merge / split / reactivate / promote_to_synthesis) のみ本 spec 所管として確定。
  - Spec 5 requirements.md が edge API 3 種 (`edge_demote` / `edge_reject` / `edge_reassign`) と `record_decision()` API + decision_type 22 種を規定。本 spec は呼出側として 10 種 (Page 6 + Skill 4) を所管。
  - Foundation §2.4 (8 段階対話) は L3 専用、§2.5 (Simple) と §2.12 (L2 専用優先関係) との 3 分類で dangerous op 13 種を整理可能。
  - 8 段階対話 / read-only walkthrough / user input wait signal の 3 用途を **Python generator yield pattern** で統合する設計が最もシンプル (Spec 4 決定 4-7 案 B + R5 重-5-1 X1 + lock 取得タイミング race window 解消の 3 申し送りを 1 つの API パターンで吸収)。
  - **Round 2 review 由来追加**: Layer 4 (handler 17 種集約 1 module) は ≤ 1500 行制約超過リスク (~2000 行 estimate)、機能別 3 sub-module 分割 (Page handler 8 種 / Skill handler 4 種 / Follow-up CRUD 5 種) で解消、4 module → **6 module DAG** に変更 (Decision 7-21 新規追加).

## Research Log

### Spec 4 design からの coordination 申し送り 7 項目

- **Context**: Spec 4 (cli-mode-unification) design.md (line 2019-2029) で Spec 7 着手時に Adjacent Sync で受領すべき 7 項目を確定済。本 spec design はこれらを設計前提として継承する責務がある。
- **Sources Consulted**:
  - `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-cli-mode-unification/design.md` (commit `4bc89f7`、2047 行)
  - `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-cli-mode-unification/research.md` (決定 4-1〜4-21、378 行)
- **Findings**:
  1. **dangerous op 8 段階対話 handler 規約**: Spec 7 は 5 種禁止リスト (`cmd_retract` / `cmd_query_promote` / `cmd_split` / `cmd_tag_split` / `cmd_skill_retract`) + `cmd_promote_to_synthesis` の 8 段階対話 handler を `cmd_*(args: argparse.Namespace) -> int` signature で提供。Spec 4 G3 AutoPolicy `confirm_dangerous_op()` が dispatch、`ConfirmResult` enum 5 値 (CONFIRMED_LIVE / CONFIRMED_DRY_RUN / ABORTED_USER / ABORTED_PREFLIGHT_FAIL / ABORTED_NON_TTY) を返却。
  2. **Page lifecycle 5 状態遷移ルール**: 5 状態 (active / deprecated / retracted / archived / merged) + 5 frontmatter field semantics (`successor` / `merged_from` / `merged_into` / `merge_strategy` / `merge_conflicts_resolved`) は Spec 7 所管。Spec 4 G2 が CLI dispatch wrapper、Spec 7 が内部 logic。
  3. **L3 診断 API thread-safe 保証**: `get_l3_diagnostics(vault) -> dict` + `check_l3_thresholds(vault) -> list[dict]` の 2 API を提供、`concurrent.futures.ThreadPoolExecutor(max_workers=4)` 経由で並行呼出可能 (read-only 保証)。`DiagnosticReadError` 例外を raise、Spec 4 G4 側が `as_completed(timeout=cli_timeout)` で fail-isolation。
  4. **HTML 差分マーカー attribute 詳細**: Spec 4 決定 4-8 で「Phase 3 = 本 spec design 委譲」確定。本 spec で attribute schema を Document Contract として確定。
  5. **8 段階対話の各段階 read-only/write 区別**: 段階 0-7 read-only、段階 8 のみ write (Spec 4 決定 4-7 案 B 採択)。`--dry-run` は段階 0-7 walkthrough 完走 + 段階 8 skip。提供対象は重い dangerous op 5 種 (deprecate/merge/split/archive/retract)。
  6. **8 段階対話の lock 取得タイミング**: 段階 8 開始時に lock 取得 → state hash pre-flight 再確認 → 差異なし時のみ commit、差異あれば user に再確認を促す logic。Spec 4 G5 LockHelper の scope に `'page_lifecycle'` 追加が必要 (Adjacent Sync)。
  7. **8 段階対話 user input 待ち中の CLI-level timeout suspend**: CLI-level timeout は subprocess 呼出 wall-clock のみ対象、user input 待ち時間は除外 (Spec 4 R5 重-5-1 X1 採択)。Spec 7 handler が user input wait state を明示的に signal、Spec 4 G3 wrapper 側で timeout suspend 判定。signal pattern は本 spec design phase で確定。
- **Implications**: 申し送り 5/6/7 の 3 項目は別々のメカニズムを要求しているように見えるが、Python generator yield pattern で統合可能 (Synthesis Lens 1 で確認、Decision 7-5 で詳述)。

### Spec 1 design からの frontmatter schema 継承

- **Context**: Spec 1 (classification) design.md (commit `7543536`) が L3 wiki frontmatter の lifecycle 関連 9 field schema を確定済。本 spec は schema を入力として継承し、状態遷移セマンティクスを本 spec で確定する責務分離。
- **Sources Consulted**:
  - `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-classification/design.md` (1413 行、特に line 407-410 / 886-918)
  - `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-classification/research.md` (決定 1-1〜1-17)
- **Findings**:
  - **継承する 9 field**: `status` (5 値 enum) / `status_changed_at` (YYYY-MM-DD) / `status_reason` (string) / `successor` (path 配列、0 個以上) / `merged_from` (path 配列、index 0=a / index 1=b 規約) / `merged_into` (path 単数) / `merge_strategy` (5 値 enum: complementary / dedup / canonical-a / canonical-b / restructure) / `merge_conflicts_resolved` (`{issue, resolution}` オブジェクト配列) / `update_history` (要素配列、`{date, type, summary, evidence?}`).
  - **責務分離**: Spec 1 が field 存在・型・許可値を所管 (R3.1-R3.6)、Spec 7 が状態遷移セマンティクス・操作可逆性・dangerous op 階段・自動追記トリガ・必須/空文字規約を所管 (R3.7 委譲)。
  - **`update_history.type` 値域委譲**: Spec 1 design line 408 / line 893 の type 値は example 列挙、正規許可値リストの正本は所管 spec に委譲。本 spec は lifecycle 起源 7 値 (deprecation / retract / archive / merge / split / reactivate / promote_to_synthesis) を確定する責務 (R1.8 と整合)。
  - **連鎖 migration 4 改版経路の現状**: R6.1 (`successor_tag` rename) / R4.7 (period 必須化) / R9.1 (lint 拡張) は Spec 1 で完了済。R5.2 (`directory_name` 追加) のみ未確定だが本 spec とは無関係 (entity 命名規約)。
  - **`merged_from` 配列順序規約 (Spec 1 決定 1-10)**: index 0 = a、index 1 = b。本 spec merge handler は user 入力順を保持して書き出す。
- **Implications**: schema 継承は機械的、本 spec の追加責務は (a) 状態遷移グラフ確定 (Decision 7-1 で 5 状態 → 5 状態の許容遷移表)、(b) `update_history.type` lifecycle 起源 7 値の確定 (Decision 7-3 で値域固定)、(c) `status_reason` 必須/空文字規約 (Spec 1 では未確定、本 spec で確定)。

### Spec 5 edge API および decision_log への依存

- **Context**: 本 spec R3 (Page→Edge 相互作用 orchestration) は Spec 5 edge API を呼出側として利用、本 spec R12.7 は Spec 5 `record_decision()` API を呼出して decision_log.jsonl に記録。
- **Sources Consulted**:
  - `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-knowledge-graph/requirements.md` (R11 / R17 / R18 / R19.6)
- **Findings**:
  - **edge API 3 種** (Spec 5 R18.1): `edge_demote(edge_id, reason, timeout)` / `edge_reject(edge_id, reason_category, reason_text, timeout)` / `edge_reassign(edge_id, new_endpoint, timeout)`. timeout は必須パラメータ、値の確定は本 spec design phase。同期 API、内部状態遷移完結 (confidence 更新 / events.jsonl append / decision_log 記録)。
  - **timeout 失敗時** (Spec 5 R18.7 / R18.8): partial failure として呼出側に伝搬、内部状態は timeout 発生時点の整合状態を保つ。本 spec orchestration は失敗を集計し follow-up タスク化 (R3.4 / R3.7 / R3.8)。
  - **`record_decision(decision) → decision_id`** (Spec 5 R11.8): 必須 10 field (decision_id / ts / decision_type / actor / subject_refs / reasoning / alternatives_considered / outcome / context_ref / evidence_ids). selective recording trigger 5 条件、reasoning 必須 4 条件 (`hypothesis_verify_confirmed` / `hypothesis_verify_refuted` / `synthesis_approve` / `retract`). Spec 5 R11.16 で partial failure 記録形式が確定 (outcome 内に partial_failure / successful_edge_ops / failed_edge_ops / followup_ids 4 field).
  - **decision_type 22 種** (Spec 5 R11.2): 本 spec が 10 種を所管 (Page lifecycle 6 種: page_deprecate / page_retract / page_archive / page_merge / page_split / page_promote_to_synthesis、Skill 起源 4 種: skill_install / skill_deprecate / skill_retract / skill_archive).
  - **`.rwiki/.hygiene.lock`** (Spec 5 R17): 物理実装 (fcntl/flock + PID 記録 + stale lock 検出) は Spec 5 所管、CLI 側取得・解放規約は Spec 4 所管。本 spec handler 内で lock を直接取得しない (Spec 5 API 経由の write は Spec 5 内部で取得、Spec 7 自身の wiki write は Spec 4 が handler 起動時に取得して解放)。
- **Implications**: edge API timeout 値 (deprecate / retract / merge で workload 別) は本 spec design で table 化 (Decision 7-9)。`record_decision()` の reasoning 必須条件 (page_retract が該当) を handler 内で gate 化。

### Spec 6 hypothesis approve flow との coordination

- **Context**: 本 spec R5.1 / R6.4 / R13.7 が確定する `cmd_promote_to_synthesis` は Spec 6 R9 (`rw approve <hypothesis-id>`) と Spec 4 (`rw query promote`) の 2 entry point から共有 handler として呼出。
- **Sources Consulted**:
  - `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-perspective-generation/requirements.md` (R7.6 / R9 / Boundary line 86)
- **Findings**:
  - **Spec 6 R9.3**: `rw approve <hypothesis-id>` handler が Spec 7 `cmd_promote_to_synthesis(hypothesis_id, target_path)` を呼出、`wiki/synthesis/<slug>.md` 昇格。8 段階対話完走後 Spec 6 が hypothesis status を `confirmed → promoted` に遷移、`successor_wiki:` field に target_path を記録。
  - **Spec 6 R9.5**: 昇格完了後 Spec 5 `record_decision(decision_type='synthesis_approve')` を呼出 (reasoning 必須、default skip 不可、Spec 5 R11.6).
  - **Spec 6 R9.5 (rollback)**: `record_decision()` 失敗時は approve 全体を ERROR severity で abort、status 遷移と `successor_wiki:` 記録を atomic 更新で rollback.
  - **Spec 6 R9.8**: `rw approve <hypothesis-id>` は `--auto` 不可、`--auto` flag が渡されても 8 段階対話を必ず経由 (本 spec R6.4 と整合).
  - **target_path 自動推定**: Spec 6 R9.3 は `cmd_promote_to_synthesis(hypothesis_id, target_path)` の signature のみ規定、target_path 自動推定アルゴリズムは本 spec design phase で確定 (Decision 7-14).
- **Implications**: `cmd_promote_to_synthesis` は呼出元 (Spec 6 R9 / Spec 4 query promote) から見て 8 段階対話完走 + target_path 確定の 2 責務を持つ。Spec 6 が status 遷移 + successor_wiki 記録 + record_decision を後段で実行する責務分離 (本 spec は wiki/synthesis/ 書込みまで).

### Spec 2 skill lifecycle handler との coordination

- **Context**: 本 spec R11 (Skill lifecycle) と R12.7 (Skill 起源 4 種 decision_type) が Spec 2 と coordinate. Spec 2 R3.5 / R7.5 / R13.6 は skill lifecycle 操作を本 spec に委譲.
- **Sources Consulted**:
  - `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-skill-library/requirements.md` (R1 / R3.5 / R3.6 / R7.5 / R9.4 / R13.6 / R13.8)
- **Findings**:
  - **Skill ファイル配置 (Spec 2 R1)**: `AGENTS/skills/<skill_name>.md` の **単一 .md ファイル** (サブディレクトリなし). `.claude/skills/<name>/SKILL.md` パターンとは異なる.
  - **Skill 初期 install (Spec 2 R7.5)**: candidate を `AGENTS/skills/<name>.md` に移動、frontmatter `origin=custom` / `status=active` / `version=1` を確定. `rw skill install` は dangerous_op 中 (推奨対話、Spec 2 R9.4) → 本 spec design phase で 8 段階 vs 簡易対話を確定 (Decision 7-15).
  - **Skill lifecycle 委譲 (Spec 2 R3.5 / R13.6)**: `deprecated` / `retracted` / `archived` への遷移は Spec 7 lifecycle 操作のみが行える. Spec 2 では subcommand 名の存在のみ認知.
  - **Skill update_history なし方針 (Spec 2 R3.6)**: Skill ファイルには `update_history` field を v2 MVP では適用しない. 履歴は `decision_log.jsonl` の Skill 起源 4 種で網羅. 本 spec R3.8 末尾「Skill ファイルには本 AC を v2 MVP では適用せず」と整合.
  - **hygiene.lock 取得 (Spec 2 R13.8)**: write 系の `rw skill` 操作 (`rw skill draft` / `rw skill test` / `rw skill install`) 実行時に `.rwiki/.hygiene.lock` を取得 (Spec 4 が CLI 側で取得).
- **Implications**: Skill handler 4 種は Page handler とほぼ同パターンだが (a) `update_history:` 追記なし、(b) Backlink 走査範囲に `AGENTS/**/*.md` を含む、(c) `cmd_skill_install` の対話階段は本 spec design で確定する 3 点が異なる. handler 内で `if target_type == 'skill': skip update_history` 等の分岐で実装 (共通 class hierarchy は不要).

### Foundation 規範との整合

- **Context**: Foundation §2.3 / §2.4 / §2.5 / §2.10 / §2.12 / §2.13 と Foundation Requirement 5 / R11 / R11.5 / R12 を本 spec の設計前提として参照する責務 (R16.1).
- **Sources Consulted**:
  - `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-foundation/requirements.md` (R5 / R11 / R12)
  - `/Users/Daily/Development/Rwiki-dev/.kiro/drafts/rwiki-v2-consolidated-spec.md` (§2.3 L253-264 / §2.4 L266-283 / §2.5 L285-315 / §2.10 L453-467 / §2.12 L535-647 / §2.13 L648-705 / §7.2 Spec 7 L2156-2202)
- **Findings**:
  - **§2.3**: 退避ディレクトリを作らず frontmatter `status:` で管理. 本 spec 全 handler は frontmatter 編集のみ (R1.6 / R2.6).
  - **§2.4**: L3 専用、L2 edge 操作には適用しない. `AGENTS/guides/dangerous-operations.md` Document Contract で 8 段階を完全一致記述 (R4.2).
  - **§2.5**: 1 コマンド・最小フラグ・Preview + y/N confirm のみ・可逆. 本 spec R10 (unapprove / reactivate) が継承.
  - **§2.10**: trust chain の縦軸 (L1 → L2 → L3、source の WHAT). merge / promote-to-synthesis handler が `merged_from:` / `successor:` / `merge_strategy:` を frontmatter に必須記録.
  - **§2.12**: L2 edge lifecycle (Hygiene 進化則 / decay / reinforcement / Competition) は Spec 5 所管、本 spec は呼出側. Boundary Commitments で明文化 (R3.6 / R12.5).
  - **§2.13**: trust chain の横軸 (decision_log → context_ref → chat-session、curator の WHY). 本 spec R12.7 で page 6 種 + skill 4 種 = 計 10 種 decision_type を所管確定.
  - **R5**: Page status 5 種を本 spec の唯一所管 status set として継承、独自追加禁止 (R1.1 / R16.2).
  - **R11**: Severity 4 水準 + exit code 0/1/2 + LLM CLI subprocess timeout 必須を継承 (R3.8 / R3.9 / R10.5 / R16.6).
  - **R11.5**: `.rwiki/.hygiene.lock` 排他制御を Spec 5 物理実装 + Spec 4 CLI 取得で履行. 本 spec handler 内で直接取得しない.
  - **R12**: decision_log 規範を Spec 5 schema 上で履行 (R12.7 で 10 種所管確定).
- **Implications**: 規範遵守は機械的、本 spec の設計責務は規範を「実装される機能」に翻訳することにある. design.md 冒頭の Boundary Commitments で §2.4 = L3 のみ / §2.12 = L2 edge は Spec 5 委譲を明示.

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| **State machine class** (LifecycleStateMachine) | Page / Skill 共通の class で状態遷移を管理 | 拡張性高、type safety | Page と Skill で update_history 適用差 / Backlink 走査範囲差 / install 対話差を class 内に分岐ロジック内包 → over-engineering | **不採用** (Synthesis Lens 3) |
| **Layer 4 単一 module 集約 (4 module DAG)** | handler 17 種を `rw_page_lifecycle.py` (≤ 1500 行) に集約 | 単純構造、1 module で検索容易 | handler 17 種 × ~100 行 + helper = ~2000 行 estimate で ≤ 1500 行制約 ~33% 超過、後方互換 re-export 禁止規律違反リスク | **不採用 (Round 2 review 由来)**、初版 Decision 7-4 案 |
| **Layer 4 機能別 3 sub-module 分割 (6 module DAG)** (採用) | Layer 4a (Page handler 8 種、≤ 1000 行) + Layer 4b (Skill handler 4 種、≤ 400 行) + Layer 4c (Follow-up CRUD 5 種、≤ 200 行) | 機能別 boundary 明確、各 module ≤ 1500 行制約に余裕、Spec 4 G1-G6 5 module 分割 pattern と整合 (Phase 1 整合) | Layer 4b → Layer 4a の StageEvent / generator base sibling import 例外的に許容、cyclic dependency 注意 | **採用 (Decision 7-21、Round 2 review)** |
| **Layer 4 base class 抽象化 (1 module 維持 + handler 短縮)** | 8 段階対話 generator pattern を base class で抽象化、各 handler を < 80 行に短縮 | DRY 強化、1 module 維持 | 短縮効果限定的 (依然 1500 行近接)、base class over-abstraction で読解負荷増 | **不採用 (Round 2 review)** |
| **Transition map dict + helper** (採用) | `PAGE_TRANSITIONS: dict[Status, set[Status]]` 定数 + `check_transition(curr, next, kind)` helper 関数 | シンプル、5×5 表で全網羅可、Page と Skill で別 dict | 拡張時に dict 修正のみ、helper も小さい | **採用 (Decision 7-1)** |
| **8 段階対話 generator yield pattern** (採用) | Python generator が `yield Stage(...)` / `yield WaitForInput(...)` event を発火、Spec 4 G3 wrapper が受領 | 段階 0-7 walkthrough mode + user input wait signal の 3 用途を 1 API で統合可、`--dry-run` 時 step N で break 可、callback より直線的 | generator は Python coroutine と異なり send() で双方向通信必要、慎重な設計要 | **採用 (Decision 7-5)**、Spec 4 申し送り 5/6/7 を統合 |
| **8 段階対話 callback pattern** | handler.set_input_wait_callback(on_wait, on_resume) 形式 | callback 階層柔軟 | callback 多層化で flow 追跡困難、yield pattern より複雑 | **不採用** |
| **8 段階対話 state machine class** | StageMachine.advance() / .pause() / .resume() | 状態管理明確 | クラス階層が generator より冗長、Python idiom から外れる | **不採用** |
| **Page→Edge orchestrator: 共通関数** (採用) | `orchestrate_edge_ops(target_path, edge_op_func, reason_kwargs, timeout)` の 1 関数 | 3 種 (deprecate/retract/merge) で共通パターン抽象化、partial failure 集計を 1 箇所に集約 | edge_op_func の引数 schema 統一が必要 | **採用 (Decision 7-8)** |
| **Page→Edge orchestrator: class** | PageEdgeOrchestrator class | 状態保持可、test 容易 | 1 関数で十分、class は over-engineering | **不採用** |
| **Page→Edge orchestrator: inline** | 各 handler 内で edge API 呼出を直接記述 | 単純 | 3 handler で重複、partial failure 集計 logic も重複 | **不採用** |
| **Follow-up registry: file-based markdown** (採用) | `wiki/.follow-ups/<id>.md` per task | git 管理対象、人間可読、編集可能、外部依存なし | 大量タスク時の list 操作が naive | **採用** (R7.1 と整合) |
| **Follow-up registry: sqlite** | `.rwiki/cache/followups.sqlite` | 高速 query / pagination 容易 | git 管理外 (Spec 0 §3 と整合性に齟齬)、人間可読性低 | **不採用** |
| **diff 表示: difflib (標準ライブラリ)** (採用) | `difflib.unified_diff()` (terminal) + `difflib.HtmlDiff` (HTML) | 外部依存ゼロ、Spec 0 tech stack 整合 | 大規模 diff の性能は naive | **採用 (Decision 7-10)** |
| **diff 表示: 自作 / 外部 lib** | Python 外部 (e.g. mistune, markdown-it-py) | 高度な MD-aware diff 可 | 依存追加、Spec 0 tech stack `networkx ≥ 3.0` のみ規範違反 | **不採用** |
| **state hash: page 全体 sha256** | page 本文全体含む | 完全な変更検出 | 性能影響大 (大規模 page で hashing 遅延) | **不採用** |
| **state hash: lifecycle field + edges 概要 sha256** (採用) | frontmatter lifecycle field + 関連 edges 数 + 関連 edges 最新 status の sha256 | 性能影響小、race window 解消に十分 | page 本文変更を検出しないが本 spec scope 外 | **採用 (Decision 7-7)** |
| **HTML diff attribute: class only** (採用) | `class="rwiki-diff-add"` / `"rwiki-diff-del"` / `"rwiki-diff-context"` | シンプル、CSS で styling 可 | data-attribute による段階紐付け不可 (MVP では不要) | **採用 (Decision 7-10)** |
| **HTML diff attribute: class + data-attribute** | `data-stage="7"` / `data-operation="retract"` 等 | renderer で段階・操作別 styling 可 | over-engineering、MVP に不要 | **不採用** (Phase 2 拡張保留) |
| **Follow-up id: UUID v4** | uuid.uuid4().hex | 衝突確率実質ゼロ | 人間可読性低、git diff で見にくい | **不採用** |
| **Follow-up id: `<YYYY-MM-DD>-<3 桁 seq>`** (採用) | 例: `2026-04-28-001` | 人間可読、git diff 可読、同日内 seq で衝突解決 | 同日 1000 件超で 3 桁不足 (現実的にあり得ない) | **採用 (Decision 7-11)** |
| **Follow-up id: `<origin>-<short-hash>`** | 例: `deprecate-a3f9e1` | origin trace 容易 | origin が長い場合 id 冗長、hash 衝突可能性 | **不採用** |

## Design Decisions

### Decision 7-1: Transition map dict + helper による状態遷移検査

- **Context**: 本 spec R1.2 が定める Page status 5 状態 + 5 状態間遷移ルールを実装する際の構造選択. Spec 7 R11.2 で Skill lifecycle も同遷移表で扱う.
- **Alternatives Considered**:
  1. State machine class (LifecycleStateMachine): 共通 class で状態管理、Page/Skill 差を class 内分岐
  2. Transition map dict + helper 関数: `PAGE_TRANSITIONS: dict[Status, set[Status]]` 定数 + `check_transition(curr, next, kind='page'|'skill')` helper
  3. Inline check: 各 handler 内で if-else で直接判定
- **Selected Approach**: 採択 = (2). `PAGE_TRANSITIONS` dict + `check_transition()` helper. handler は最初に `check_transition()` を呼び、不正遷移時は CRITICAL severity + exit 1 で reject.
- **Rationale**: state machine class は over-engineering (Synthesis Lens 3). Page と Skill の差は (a) update_history 適用、(b) Backlink 走査範囲のみで、状態遷移表は完全一致 (R11.2). dict + helper でサイズ最小、人間可読、追加 status 時の修正容易.
- **Trade-offs**: 状態数増加 (例: 10 状態) なら class 化が望ましいが、5 状態固定 (Foundation R5) で当面拡張なし. 拡張時は Spec 0 改版経由 → 本 spec dict 拡張の Adjacent Sync で対応.
- **Follow-up**: 実装時 `PAGE_TRANSITIONS` の type alias 定義 (`Status = Literal[...]`).

### Decision 7-2: 設計決定の二重記録方式 (本文 + change log)

- **Context**: Spec 0 / Spec 1 / Spec 4 と整合する設計決定の記録方式. ADR 独立ファイルは不採用 (memory `feedback_design_decisions_record.md`).
- **Alternatives Considered**:
  1. ADR 独立ファイル (`adr/0001-*.md`): 過去に機能せず
  2. design.md 本文「設計決定事項」セクション + change log の二重記録
  3. design.md 本文のみ
- **Selected Approach**: 採択 = (2). design.md 本文の「設計決定事項」セクションに 7-1〜7-N を numbered subsection で列挙、change log で commit/Adjacent Sync 履歴.
- **Rationale**: Spec 0/1/4 で実証済の方式、reviewer が design.md 単体で全決定を確認可能、ADR 独立ファイルの維持コストなし.
- **Trade-offs**: design.md の line 数増加 (≈ 1500-2000 行 想定). template.md「approaching 1000 lines indicates excessive complexity」警告に該当するが、Spec 7 は dangerous op 13 種 + 11 guide + 17 cmd_* handler + 5 種 decision_type 等の必然的複雑度 (Spec 4 design 2047 行 / Spec 1 design 1413 行と同水準).

### Decision 7-3: `update_history.type` lifecycle 起源 7 値の確定

- **Context**: Spec 1 R3.6 が `update_history.type` を example 列挙のみで宣言、正規許可値リストの正本を所管 spec に委譲. 本 spec R1.8 が lifecycle 起源 type 値域を確定する責務.
- **Alternatives Considered**:
  1. lifecycle 起源 4 値 (deprecation / merge / split / archive、Spec 1 design line 408 既出) のみ採用
  2. 4 値 + retract / reactivate / promote_to_synthesis 追加 = 7 値
  3. さらに細分 (例: page_deprecate / page_merge / skill_install などで 11+ 値)
- **Selected Approach**: 採択 = (2). lifecycle 起源 7 値 = `deprecation` / `retract` / `archive` / `merge` / `split` / `reactivate` / `promote_to_synthesis`.
- **Rationale**: Spec 7 が所管する dangerous op 13 種のうち、status 遷移を伴う 7 種に対応. Skill lifecycle 起源 4 種は decision_log 側で網羅 (Spec 2 R3.6 / 本 spec R3.8 末尾)、`update_history` には適用しない. tag merge / split / unapprove は wiki page status 遷移を伴わないため update_history 起源 type に含めない (tag 操作は別 spec、unapprove は git revert で update_history が自動 reverse).
- **Trade-offs**: Spec 1 design line 893 の active example コメントは 6 値のみ列挙、本 spec 確定後に Spec 1 へ Adjacent Sync で追記する選択肢あり (実質コメント整合のみ、Spec 1 schema 変更ではない).
- **Follow-up**: 本 spec design approve 後 Spec 1 design line 893 example コメントを Adjacent Sync で 7 値追記検討 (本 spec の change log で記録).

### Decision 7-4: Spec 7 module 分割パターン (`rw_page_lifecycle.py` 中心)

- **Context**: Spec 4 決定 4-3 (v1 5 層 DAG パターン踏襲、各 ≤ 1500 行、修飾参照、後方互換 re-export 禁止). 本 spec も同パターン継承.
- **Alternatives Considered**:
  1. 単一 module `rw_page_lifecycle.py` (≤ 1500 行) に全 handler + helper 集約
  2. 機能別分割: `rw_page_lifecycle.py` (handler) + `rw_lifecycle_orchestrator.py` (Page→Edge) + `rw_followup_registry.py` (Follow-up) + `rw_lifecycle_diagnostics.py` (L3 診断)
  3. 全 handler 個別 module (例: `rw_page_deprecate.py` / `rw_page_retract.py` / ...)
- **Selected Approach**: 採択 = (2). 4 module 分割.
- **Rationale**: 単一 module は ≤ 1500 行制約を超過するリスク (handler 17 種 + helper 多数). 個別 module は過分割で import 関係複雑. 4 module 分割は責務明確 (handler / orchestration / follow-up / 診断) + Spec 4 module DAG 同層 import 回避規律 (Spec 4 design line 206) と整合.
- **Trade-offs**: 4 module 間の dependency direction を明示する必要あり (Decision 7-19 参照).
- **Follow-up**: File Structure Plan で 4 module の依存方向 + line 数推定を明示.

### Decision 7-5: 8 段階対話 = generator yield pattern + read-only walkthrough + user input wait signal の 3 用途統合

- **Context**: Spec 4 申し送り 5/6/7 の 3 項目 (read-only walkthrough mode / state hash pre-flight 再確認 / user input wait timeout suspend) は別々のメカニズムを要求しているように見えるが、共通基盤で統合可能か検討.
- **Alternatives Considered**:
  1. State machine class: `StageMachine.advance() / .pause() / .resume()`
  2. Callback pattern: `handler.set_input_wait_callback(on_wait, on_resume)`
  3. Generator yield pattern: handler が generator function、`yield StageEvent(...)` / `yield WaitForUserInput(...)` event を発火、Spec 4 G3 wrapper が `.send(response)` で応答
- **Selected Approach**: 採択 = (3). Generator yield pattern.
  - handler signature: `def stage_handler(args: argparse.Namespace) -> Generator[StageEvent, UserResponse, FinalResult]`
  - 段階 0-7 で各々 `yield StageReadOnly(stage_id, content)` を発火 (Spec 4 wrapper が表示)
  - user 入力待ち時 `yield WaitForUserInput(prompt)` を発火 (Spec 4 G3 が CLI-level timeout suspend、`input()` で受領後 `.send(user_input)` で再開)
  - 段階 8 開始時 `yield AcquireLock(scope='page_lifecycle')` を発火 (Spec 4 が lock 取得)
  - 段階 8 内で `yield PreFlightStateHash(curr_hash)` を発火 (Spec 4 が再計算 + 比較、差異あれば `.send(False)` で abort、なければ `.send(True)` で commit)
  - `--dry-run` 時 Spec 4 G3 が generator を段階 7 で `.close()` して abort (案 B 採択、Spec 4 決定 4-7).
- **Rationale**: 1 つの API パターンで 3 用途を吸収 = simplification. Python 標準 idiom (PEP 342 + PEP 380) でシンプル. Callback より直線的、state machine class より軽量.
- **Trade-offs**: generator の `.send()` 双方向通信は学習コストあり. test 時は generator を mock しやすい (event 列を直接 next() で iterate).
- **Follow-up**: handler 実装時 generator base class または ABC を定義するか検討. 8 種 StageEvent (StageReadOnly / WaitForUserInput / AcquireLock / PreFlightStateHash / DiffPreview / WriteCommit / FollowupCreate / DecisionRecord) の dataclass 定義.

### Decision 7-6: 8 段階対話 lock 取得タイミング (段階 8 開始時 + state hash pre-flight 再確認)

- **Context**: Spec 4 申し送り 6 で「段階 1-7 中の race window 解消」が design phase 確定事項として残された.
- **Alternatives Considered**:
  1. 段階 1 開始時に lock 取得 → 段階 8 完了で解放: 人間判断時間 (数分〜数時間) lock 保持 → 他プロセスブロック、UX 悪化
  2. 段階 8 開始時に lock 取得 + state hash pre-flight 再確認 → 差異なければ commit、差異あれば user 再確認: race window 最小化 + UX 維持
  3. lock なし: race condition 受容、整合性放棄 → 不採用
- **Selected Approach**: 採択 = (2). 段階 8 開始時に lock 取得、state hash 比較で race window 解消.
  - state hash 対象 = page lifecycle frontmatter (status / status_changed_at / status_reason / successor / merged_from / merged_into / merge_strategy) + 関連 edges 数 + 関連 edges 最新 status (Decision 7-7 で詳述)
  - 段階 7 終了時に hash_t7 を記録、段階 8 開始時 (lock 取得直後) に hash_t8 を再計算、`hash_t7 != hash_t8` なら ERROR severity で abort + user に「8 段階対話を再実行してください」を提示 (R3.9 の規約と整合).
- **Rationale**: lock を段階 1-7 で保持すると long lock hold で UX 悪化 (人間が dangerous op を熟考する数分〜数時間). 段階 8 開始時 lock 取得 + state hash 再確認で「lock hold 時間最小化 + race window 解消」を両立.
- **Trade-offs**: state hash 再計算で false negative (実際の状態変化を検出できない) 可能性ゼロではないが、lifecycle field + 関連 edges を hash 対象とする限り、lifecycle 関連の変化は捕捉可能. page 本文変更は本 spec scope 外 (本 spec は status 遷移のみ責務).
- **Follow-up**: `acquire_lock` scope に `'page_lifecycle'` 追加を Spec 4 G5 LockHelper line 1046 に Adjacent Sync.

### Decision 7-7: state hash の対象範囲

- **Context**: Decision 7-6 で「state hash 比較で race window 解消」を採択. hash 対象範囲を確定する必要あり.
- **Alternatives Considered**:
  1. page 本文全体 sha256: 完全な変更検出だが性能影響大 (大規模 page で hashing 遅延、本文変更は本 spec scope 外)
  2. lifecycle frontmatter field + 関連 edges 数 + 関連 edges 最新 status の sha256: race window 解消に十分 + 性能影響小
  3. lifecycle frontmatter field のみ sha256: 関連 edges 状態変化を検出できない (Page→Edge orchestration 整合性失う)
- **Selected Approach**: 採択 = (2). `hashlib.sha256(canonical_repr).hexdigest()` 形式.
  - canonical_repr の構成: `{status, status_changed_at, status_reason, successor, merged_from, merged_into, merge_strategy, related_edges_count, related_edges_status_summary}` を JSON canonical form (sort_keys=True) で serialize して hash.
  - related_edges_status_summary: 関連 edges を edge_id 順 sort、各 edge の `(edge_id, status)` tuple を list 化.
- **Rationale**: hash 対象を本 spec scope (lifecycle 関連) に絞ることで性能影響を最小化、かつ lifecycle 整合性の race condition を完全捕捉.
- **Trade-offs**: page 本文の同時編集 (例: 別プロセスが本文 typo 修正中) は検出されないが、これは本 spec scope 外で問題なし. 関連 edges の confidence 微変化 (status 遷移なし) は検出されないが、status 遷移なしなら lifecycle integrity に影響なし.
- **Follow-up**: 実装時 `compute_state_hash(page_path) -> str` helper を `rw_page_lifecycle.py` に提供.

### Decision 7-8: Page→Edge orchestrator = `orchestrate_edge_ops()` 共通関数

- **Context**: 本 spec R3 (Page→Edge 相互作用 orchestration) の 3 種 (deprecate/retract/merge) でパターン類似. 共通化価値あり.
- **Alternatives Considered**:
  1. PageEdgeOrchestrator class
  2. 共通関数 `orchestrate_edge_ops(target_path, edge_op_func, reason_kwargs, timeout) -> OrchestrationResult`
  3. inline (各 handler 内で edge API 呼出を直接記述)
- **Selected Approach**: 採択 = (2). `orchestrate_edge_ops()` 関数.
  - signature: `def orchestrate_edge_ops(target_path: Path, edge_op_func: Callable, reason_kwargs: dict, timeout: float) -> OrchestrationResult`
  - OrchestrationResult dataclass: `successful_edge_ops: int / failed_edge_ops: int / followup_ids: list[str] / partial_failure: bool`
  - 内部処理: (a) 関連 edges 取得 (Spec 5 query API 経由、target_path が source/target である全 stable/core edges) → (b) edges loop で edge_op_func(edge_id, **reason_kwargs, timeout=timeout) 呼出 → (c) 失敗を集計、follow-up タスク生成 → (d) OrchestrationResult 返却.
- **Rationale**: 3 handler で共通する pattern を 1 関数に集約 = simplification. partial failure 集計 logic も 1 箇所. class 化は state 保持不要なので over-engineering.
- **Trade-offs**: edge_op_func の引数 schema を統一する必要あり (`edge_op_func(edge_id, **kwargs)` 形式).
- **Follow-up**: `rw_lifecycle_orchestrator.py` module で実装.

### Decision 7-9: edge API timeout 値の workload 別設定

- **Context**: Spec 5 R18.7 が edge API 3 種に timeout 必須化、値の確定は本 spec design phase 委譲 (本 spec R12.8).
- **Alternatives Considered**:
  1. 全 edge API で 1 つの default timeout (例: 10 秒)
  2. workload 別 default (deprecate=5s / retract=10s / merge=30s)
  3. config.yml で全 timeout を上書き可能
- **Selected Approach**: 採択 = (2) + (3) ハイブリッド. workload 別 default + config.yml で上書き可.
  - `EDGE_API_TIMEOUT_DEFAULTS = {'deprecate': 5.0, 'retract': 10.0, 'merge': 30.0, 'reassign': 30.0}` (秒).
  - config.yml `[lifecycle.edge_api_timeouts]` で上書き可能.
- **Rationale**: edge_demote は単純な status 更新で 5 秒で十分. edge_reject は decision_log 記録 + rejected_edges.jsonl 移動で 10 秒. edge_reassign は merge orchestration で複数 edges 一括 reassign の可能性ありで 30 秒.
- **Trade-offs**: 大規模 vault で merge orchestration の edges 数 ≥ 100 等で timeout 不足の可能性、config.yml で実環境調整可.
- **Follow-up**: 実装後 production usage で timeout 値妥当性検証、necessary なら default 値改訂.

### Decision 7-10: HTML 差分マーカー attribute schema

- **Context**: Spec 4 決定 4-8 で「Phase 3 = 本 spec design 委譲」確定. 本 spec で attribute schema を Document Contract として確定.
- **Alternatives Considered**:
  1. class only: `class="rwiki-diff-add"` / `"rwiki-diff-del"` / `"rwiki-diff-context"`
  2. class + data-attribute: `data-stage="7"` / `data-operation="retract"`
  3. inline style: `<span style="color: green">...</span>`
- **Selected Approach**: 採択 = (1). class only.
  - HTML diff: `difflib.HtmlDiff().make_file(from_lines, to_lines)` を使用、生成 HTML 内の `<span>` element を post-process して `class="rwiki-diff-add"` / `"rwiki-diff-del"` / `"rwiki-diff-context"` に統一.
  - terminal text diff: `difflib.unified_diff()` を使用、ANSI escape で色付け (Spec 4 G6 colorize と整合).
- **Rationale**: data-attribute は MVP 不要 (over-engineering). class only で CSS による styling 可、Phase 2 で data-attribute 追加余地残す.
- **Trade-offs**: data-attribute による段階別 styling 不可だが MVP に不要. Phase 2 拡張時に attribute 追加で後方互換維持.
- **Follow-up**: 実装後 user feedback で data-attribute 必要性再評価.

### Decision 7-11: Follow-up id 採番方式

- **Context**: brief 第 3-10 持ち越し. Follow-up タスクの id (R7.2 で必須) の採番方式.
- **Alternatives Considered**:
  1. UUID v4: `uuid.uuid4().hex`
  2. `<YYYY-MM-DD>-<3 桁 seq>`: 例 `2026-04-28-001`
  3. `<origin_operation>-<short-hash>`: 例 `deprecate-a3f9e1`
- **Selected Approach**: 採択 = (2). `<YYYY-MM-DD>-<3 桁 seq>` 形式.
  - seq は同日内のグローバル連番、`wiki/.follow-ups/<YYYY-MM-DD>-*.md` を glob して最大 seq + 1 を採番.
  - 同日内衝突回避: 採番直前に `wiki/.follow-ups/` を再 glob (file lock 不要、同日 1000 件超は現実的にあり得ない).
- **Rationale**: 人間可読 + git diff 可読 + 同日内 seq で衝突解決. UUID v4 は人間可読性低い、`<origin>-<short-hash>` は origin 文字列が長くなる.
- **Trade-offs**: 同日 1000 件超で 3 桁不足だが、Rwiki 単一ユーザー想定で現実的にあり得ない. 衝突時は ERROR severity で abort + user に手動 id 指定要求.
- **Follow-up**: 実装時 `generate_followup_id(origin_operation, target_path, vault) -> str` helper.

### Decision 7-12: Follow-up 長期 GC 機構 (resolved/dismissed > 90 日 → archive ディレクトリ移動)

- **Context**: brief 第 3-8 持ち越し. `status: resolved` / `status: dismissed` のタスクが `wiki/.follow-ups/` に蓄積し続けると長期運用で肥大化.
- **Alternatives Considered**:
  1. GC なし: 永続蓄積、運用 1-2 年で数千件
  2. 物理削除: git 履歴は残るが現状 archive 不可、誤削除リスク
  3. archive ディレクトリ移動: `wiki/.follow-ups/.archived/<year>/<id>.md` へ移動、retention policy = 解消後 90 日経過で auto-archive
- **Selected Approach**: 採択 = (3). archive ディレクトリ移動 + 90 日 retention.
  - `rw follow-up archive` コマンド (auto/manual 両対応): `status: resolved` / `dismissed` かつ最終更新が 90 日以上前のタスクを `wiki/.follow-ups/.archived/<year>/<id>.md` に移動.
  - 自動実行 trigger は本 spec scope 外 (Spec 4 maintenance UX 経由で trigger 可能). MVP は manual `rw follow-up archive` のみ.
- **Rationale**: 物理削除はトレース不能、永続蓄積は性能影響. archive ディレクトリで折衷.
- **Trade-offs**: archive 後の検索は `.archived/` 配下を別途 glob 必要、UX 複雑化軽微.
- **Follow-up**: 実装後 6 ヶ月で archive 件数評価、necessary なら retention period 調整.

### Decision 7-13: status_changed_at / update_history.date の精度 = YYYY-MM-DD 維持

- **Context**: brief 第 3-7 持ち越し. 同日内に複数 dangerous op が実行された場合の順序が frontmatter から判別不能.
- **Alternatives Considered**:
  1. ISO 8601 timestamp `YYYY-MM-DDTHH:MM:SS+09:00` への精度引き上げ
  2. `update_history` 配列に `sequence_number` field 追加
  3. YYYY-MM-DD 維持 (Spec 1 整合) + 同日内順序は git commit hash で時系列特定可
- **Selected Approach**: 採択 = (3). YYYY-MM-DD 維持.
- **Rationale**: Spec 1 R3.1 が YYYY-MM-DD 規定 (例 line 902 / 912 すべて YYYY-MM-DD). 精度引き上げは Spec 1 改版要 (Adjacent Sync). 同日内順序は (a) git commit hash で時系列特定可、(b) `update_history` 配列の挿入順 (last-append) で論理順保証、(c) Rwiki は単一 user 想定で同日内多重 dangerous op は稀.
- **Trade-offs**: 同日内多重 dangerous op の precise timing は git log で確認、frontmatter 単体では判別不能だが運用上問題なし.
- **Follow-up**: 将来同日内多重操作が頻発する運用要請が出れば Spec 1 R3.1 改版経路で精度引き上げ検討 (本 spec とは独立).

### Decision 7-14: `cmd_promote_to_synthesis` の自動判定アルゴリズム

- **Context**: brief R13.7 持ち越し. `cmd_promote_to_synthesis(candidate_path, target_path, merge_strategy, target_field)` の signature と判定アルゴリズム詳細.
- **Alternatives Considered**:
  1. 全引数を user に明示要求 (autonomous なし): UX 悪、Spec 6 R9.3 の `cmd_promote_to_synthesis(hypothesis_id, target_path)` signature と不整合
  2. 4 通りの自動判定: target_path 有無 + target_field 有無 + 既存 page 衝突
  3. machine learning ベースの判定: over-engineering
- **Selected Approach**: 採択 = (2). 4 通り自動判定.
  - **case A: 新規 wiki page 生成** (`merge_strategy=complementary`): target_path 未指定 OR 指定された slug が `wiki/synthesis/` 内未存在.
  - **case B: 既存 page の section 拡張** (`merge_strategy=complementary` + 内部 mode=`extend`): target_path 指定 + 既存 page 存在 + target_field 未指定.
  - **case C: 既存 page の specific field 置換** (`merge_strategy=dedup` 相当 + 内部 mode=`merge`): target_path 指定 + 既存 page 存在 + target_field 指定.
  - **case D: 既存 page を deprecated にして新規生成** (`merge_strategy=canonical-a` 相当 + 内部 mode=`replace`): target_path 指定 + 既存 page 存在 + 完全置換 user 指示 (`--replace` flag).
  - 8 段階対話の段階 1 (意図確認) で「自動判定結果: case X (target_path=Y, mode=Z)」を user に提示、段階 4 (代替案提示) で他 case を選択肢として表示、user は段階 8 で最終承認.
- **Rationale**: 4 通り判定で typical use cases を網羅. 8 段階対話の中で透明化することで誤判定リスクを user 承認で吸収.
- **Trade-offs**: case 分岐 logic の test coverage が複雑だが、unit test で 4 case + edge cases (target_path = 自分自身、循環依存等) を網羅.
- **Follow-up**: 実装後 user feedback で判定アルゴリズム精緻化、case 5 (例: multi-target merge) 必要性評価.

### Decision 7-15: Skill lifecycle handler の対話階段

- **Context**: brief R6.9 持ち越し. Skill lifecycle 拡張 2 種 (`skill deprecate` / `skill archive`) の危険度・対話ガイド要否・`--auto` 可否.
- **Alternatives Considered**:
  1. 全 skill 操作 (install / deprecate / retract / archive) = 8 段階対話 (重い)
  2. install = 簡易 1 段階 / deprecate / retract / archive = 8 段階対話
  3. install / deprecate / archive = 簡易 1 段階 / retract = 8 段階対話 (最軽量)
- **Selected Approach**: 採択 = (2).
  - `skill install`: 簡易 1 段階 (Spec 2 R9.4 の dangerous_op 中 + 推奨対話と整合、--auto 可)
  - `skill deprecate`: 8 段階対話 (中、--auto 可)
  - `skill retract`: 8 段階対話 (高、--auto 不可、Spec 7 R6.4 既定)
  - `skill archive`: 8 段階対話 (低、推奨、--auto 可)
- **Rationale**: skill install は validation 通過後の実行で誤動作影響小、簡易 1 段階で十分. deprecate / archive は status 遷移で誤動作影響中、8 段階対話で慎重. retract は不可逆で最重要、`--auto` 不可で必ず 8 段階.
- **Trade-offs**: deprecate / archive を 8 段階対話とすることで UX 重くなるが、skill 撤回・履歴化は誤動作影響大なので妥当.
- **Follow-up**: drafts §7.2 Spec 7 表に Skill 拡張 2 種を追加 (Adjacent Sync、本 spec change log で記録).

### Decision 7-16: Skill update_history なし方針の実装パターン

- **Context**: Spec 2 R3.6 / 本 spec R3.8 末尾で「Skill ファイルには `update_history:` 適用しない」確定. 実装パターン.
- **Alternatives Considered**:
  1. handler 内 `if target_type == 'skill': skip` 分岐
  2. Page と Skill で別 handler 関数 (`cmd_page_*` / `cmd_skill_*`) で完全分離
  3. 共通 base class + override
- **Selected Approach**: 採択 = (2). Page と Skill で別 handler 関数.
  - `cmd_deprecate(args)` (page) と `cmd_skill_deprecate(args)` (skill) を別関数として実装.
  - 共通 helper (state machine check / blockquote 自動挿入 / Backlink 走査) は kwargs で `kind='page'|'skill'` を受領して内部分岐.
- **Rationale**: Spec 4 G2 CommandDispatch (line 605-617) の cmd_* 列挙パターンと整合 (Page / Skill 別関数). handler 内 if 分岐は signature が紛らわしい (1 関数で 2 種の操作). 共通 base class は over-engineering.
- **Trade-offs**: Page と Skill で 17 種 cmd_* function を別々に定義する line 数増、helper kwargs で実態は重複しない.
- **Follow-up**: handler 関数の DRY 原則を helper kwargs で履行.

### Decision 7-17: `BACKLINK_SCAN_PATHS` 定数

- **Context**: brief F-3 持ち越し. R9.3 と R11.6 の Backlink 走査範囲統一表現. Page 用 = `wiki/**/*.md` + `raw/**/*.md`、Skill 用 = 上記 + `AGENTS/**/*.md`.
- **Alternatives Considered**:
  1. 各 handler 内で hard-coded glob pattern
  2. 定数 `BACKLINK_SCAN_PATHS = {'page': [...], 'skill': [...]}` で統一
  3. config.yml で上書き可能
- **Selected Approach**: 採択 = (2) + (3) ハイブリッド. 定数 default + config.yml 上書き可.
  - `BACKLINK_SCAN_PATHS = {'page': ['wiki/**/*.md', 'raw/**/*.md'], 'skill': ['wiki/**/*.md', 'raw/**/*.md', 'AGENTS/**/*.md']}` (相対パス).
  - 除外: `v1-archive/**` / `.rwiki/**` / `.git/**` (R9.3 と整合).
  - config.yml `[lifecycle.backlink_scan_paths]` で上書き可能.
- **Rationale**: 定数化で重複回避、config 上書きで vault 構造拡張に対応.
- **Trade-offs**: なし.
- **Follow-up**: 大規模 vault (Pages > 1K) の性能対策は Decision 7-18 で扱う.

### Decision 7-18: Backlink 走査 partial vs 全失敗判定

- **Context**: 本 spec R9.5 で「Backlink 走査対象が全数失敗した場合 (disk full / permission denied 等) は ERROR severity で operation 自体を rollback」と「一部 / 全失敗の判定基準は design phase で確定」が残存.
- **Alternatives Considered**:
  1. 失敗率 0% のみ成功扱い (1 件失敗で全体 rollback): 過剰反応
  2. 失敗率 ≥ 95% を全失敗扱い (= rollback)、< 95% は partial failure (follow-up タスク化)
  3. 全失敗判定なし、常に partial failure として follow-up タスク化: disk full 等の根本障害見逃し
- **Selected Approach**: 採択 = (2). 失敗率 ≥ 95% を全失敗扱い.
  - 失敗率計算: `failed_count / total_count`. total_count は走査対象 markdown 全数 (BACKLINK_SCAN_PATHS で glob した数).
  - ≥ 95% 失敗 = ERROR severity で operation 自体を rollback (frontmatter status 遷移と Edge orchestration 取り消し). `lock` 範囲内のため atomicity 保証可能 (R3.9 と整合).
  - < 95% 失敗 = partial failure として follow-up タスク化 (R9.5 と整合).
- **Rationale**: 95% 閾値で disk full / permission denied 等の根本障害を捕捉、軽微な個別 page の失敗は follow-up タスクで人間判断に委ねる.
- **Trade-offs**: 95% 閾値は経験的、production usage で調整余地. 5% 失敗が許容される運用なら閾値下げる.
- **Follow-up**: 実装後 production usage で閾値妥当性検証.

### Decision 7-19: 4 module 分割の dependency direction

- **Context**: Decision 7-4 で 4 module 分割採択. Spec 4 design module DAG (5 層、修飾参照、後方互換 re-export 禁止) と整合する dependency direction.
- **Alternatives Considered**:
  1. flat (全 module 同層、相互 import 可): cyclic dependency リスク
  2. 階層化 (handler → orchestrator → follow-up + diagnostics): 1 方向 import
  3. 別の階層化 (orchestrator → handler): 不自然
- **Selected Approach**: 採択 = (2).
  ```
  Layer 4 (top):    rw_page_lifecycle.py (handler)
                       ↓ import
  Layer 3:          rw_lifecycle_orchestrator.py (Page→Edge orchestration)
                       ↓ import
  Layer 2:          rw_followup_registry.py (Follow-up registry)
                       ↓ import
  Layer 1 (bottom): rw_lifecycle_diagnostics.py (L3 診断 API、read-only)
  ```
  - Layer 4 (handler) が Layer 1-3 を import. Layer 3 が Layer 1-2 を import. Layer 2 が Layer 1 を import.
  - 上位層 → 下位層の 1 方向 import、cyclic dependency 禁止.
  - Spec 4 module (`rw_dispatch.py` 等) は本 spec Layer 4 (handler) のみ import.
  - Spec 5 module (`rw_graph.py` 等) は本 spec Layer 3 (orchestrator) から呼出.
- **Rationale**: 4 module の責務階層が自然 (handler が最上位、診断 read-only API が最下位). 1 方向 import で cyclic dependency 回避.
- **Trade-offs**: handler 増加時に Layer 4 line 数膨張リスク、necessary なら handler 内部分割 (Page / Skill) 検討.
- **Follow-up**: 実装時 module DAG を test で検証 (cyclic import detection).

### Decision 7-20: `--auto` 不可違反時の severity

- **Context**: brief 第 3-11 持ち越し. R6.5 の `--auto` 不可指定操作に `--auto` フラグが渡された場合の severity = INFO は控えめ、WARN が妥当か.
- **Alternatives Considered**:
  1. INFO (現状規定): 軽微な情報通知
  2. WARN: 明示的な注意喚起 (`--auto` 不可指定への違反)
  3. ERROR: 操作拒否 (現状は対話強制で実行はする)
- **Selected Approach**: 採択 = (2). WARN.
  - 出力例: `WARN: --auto flag is not allowed for 'retract' operation. Falling back to interactive 8-stage dialogue.`
  - 8 段階対話を強制実行 (現状規定維持、操作拒否はしない、R6.5 と整合).
- **Rationale**: `--auto` 不可指定への違反は user の意図 (CI 等での自動化) と designer の意図 (誤動作防止) の不一致を示す重要な情報、INFO ではなく WARN で目立たせる. ERROR で拒否すると CI script が壊れる、対話強制で実行継続.
- **Trade-offs**: WARN 多発で log noise 増加リスクあるが、`--auto` 不可指定への違反は本来稀.
- **Follow-up**: requirements R6.5 の severity を INFO → WARN に修正 (本 spec change log で記録、Adjacent Sync 経路は本 spec 内のみ).

### Decision 7-21: Layer 4 を機能別 3 sub-module に分割 (Round 2 review 由来)

- **Context**: Round 2 アーキテクチャ整合性レビューで重-2-1 検出. Decision 7-4 初版 (4 module 分割) では handler 17 種を `rw_page_lifecycle.py` (≤ 1500 行) に集約する想定だったが、handler 平均 ~100 行 typical で 17 × 100 = ~1700 行 + helper 200-300 行 = **~2000 行 estimate**、Spec 4 決定 4-3 の ≤ 1500 行制約を ~33% 超過する.
- **Alternatives Considered**:
  1. 現状維持 (Layer 4 ≤ 1500 行制約遵守、17 handler 集約): handler 各々 < 90 行で実装可能、しかし generator pattern handler は 100-200 行が typical で達成困難
  2. Layer 4 を 3 sub-module に分割 (Page handler 8 種 / Skill handler 4 種 / Follow-up CRUD 5 種)
  3. handler 17 種を完全均一化 (各 handler 短縮 < 80 行) で 1 module に集約 (base class refactoring)
- **Selected Approach**: 採択 = (2). Layer 4 を機能別 3 sub-module に分割.
  - Layer 4a `rw_page_lifecycle.py`: Page handler 8 種 (cmd_deprecate / cmd_retract / cmd_archive / cmd_reactivate / cmd_merge / cmd_split / cmd_unapprove / cmd_promote_to_synthesis) + 共有基盤 (8 段階対話 generator base + StageEvent dataclass + PAGE_TRANSITIONS dict + check_transition + compute_state_hash) ≤ 1000 行
  - Layer 4b `rw_skill_lifecycle.py`: Skill handler 4 種 + Skill 専用 helper ≤ 400 行. Layer 4a から StageEvent + generator base を import (sibling import、共通 base 共有のため例外的に許容)
  - Layer 4c `rw_followup_handlers.py`: Follow-up CRUD handler 5 種 + pagination + filter logic ≤ 200 行 (Layer 2 thin wrapper)
- **Rationale**: 1500 行制約超過確実 (X1) では implementation phase で module 分割を強いられる → 後方互換 re-export 禁止規律 (Spec 4 決定 4-3) と矛盾. Layer 4 を機能別 3 sub-module に分割することで (a) Page lifecycle / Skill lifecycle / Follow-up CRUD の責務境界明確化 (dev-log パターン 7), (b) reviewer が module 単位で確認可能 (運用整合性), (c) Spec 4 design 5 module 分割 (G1-G6) パターンと整合 (Phase 1 整合), (d) Layer 4a ≤ 1000 行 / 4b ≤ 400 行 / 4c ≤ 200 行で各々 1500 行制約に余裕.
- **Trade-offs**: Layer 4b → Layer 4a の sibling import (StageEvent / generator base) を例外的に許容、cyclic dependency 注意. Layer 4c は Layer 2 thin wrapper としてのみ機能、handler ロジック集中度低い (Follow-up CRUD は単純な CRUD).
- **Follow-up**: Decision 7-4 (4 module → 6 module) と Decision 7-19 (dependency direction、6 module 反映) を本 Decision 7-21 と同期更新済. Spec 4 design 連動 Adjacent Sync (Module DAG line 206 / Directory Structure line 250 で 3 sub-module 名追記) を本 spec design approve 直後に実施.

## Risks & Mitigations

- **Risk 1: Spec 5 design 未完による edge API signature 未確定**
  - Spec 5 design.md (knowledge-graph) は本 spec design 完了後に着手予定 (Phase 3). 本 spec design phase で Spec 5 R18.1 の signature 案を採用、Spec 5 design phase で確定後に Adjacent Sync で本 spec を更新する手順を残す (本 spec R12.6 と整合).
- **Risk 2: Spec 4 G5 LockHelper への `'page_lifecycle'` scope 追加忘れ**
  - Decision 7-6 で確定した lock scope 追加を Spec 4 design line 1046 に Adjacent Sync で反映する義務. 本 spec design approve 後に Spec 4 design 改版 commit を必ず実施.
- **Risk 3: Generator yield pattern の test 困難性**
  - Decision 7-5 で採択した generator pattern は test 時に generator state 操作が必要. mitigation = test では generator を mock せず、event 列を直接 next() / send() で iterate する pattern を確立、unit test template を `tests/test_lifecycle_generator.py` で例示.
- **Risk 4: 大規模 vault (Pages > 1K) での Backlink 走査性能**
  - Decision 7-17 の BACKLINK_SCAN_PATHS naive 全走査は大規模 vault で長時間化リスク. MVP は naive 全走査、Phase 2 拡張で incremental 走査 cache (前回走査結果との diff のみ) を検討. `rw doctor` の CLI-level timeout 300 秒以内完走を verify.
- **Risk 5: 8 段階対話の途中 abort 時 lock 解放漏れ**
  - Decision 7-6 で段階 8 開始時に lock 取得、generator pattern (Decision 7-5) で `.close()` 時に lock 解放を保証. mitigation = generator base class の `__del__` または try/finally で lock 解放を保証、unit test で abort scenarios を網羅.
- **Risk 6: HTML 差分 attribute schema (Decision 7-10) の renderer 互換性**
  - Spec 4 G6 colorize は terminal text diff 用、HTML diff は別途 renderer (chat 統合等) 必要. MVP は class-based HTML 出力のみ、renderer は Phase 2.

## References

- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-foundation/design.md` (commit `ba7b11b`) — §2.3 / §2.4 / §2.5 / §2.10 / §2.12 / §2.13 規範本文
- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-classification/design.md` (commit `7543536`) — frontmatter schema 9 field 継承元
- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-cli-mode-unification/design.md` (commit `4bc89f7`) — Spec 7 申し送り 7 項目 + cmd_* signature 規約
- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-knowledge-graph/requirements.md` — edge API 3 種 + decision_log + record_decision API
- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-perspective-generation/requirements.md` — hypothesis approve flow + cmd_promote_to_synthesis 呼出元
- `/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-skill-library/requirements.md` — Skill ファイル配置 + skill lifecycle 委譲
- `/Users/Daily/Development/Rwiki-dev/.kiro/drafts/rwiki-v2-consolidated-spec.md` (v0.7.12) — §7.2 Spec 7 表 (Dangerous op 13 種 + Page 状態挙動 + Page→Edge 相互作用)
- `/Users/Daily/Development/Rwiki-dev/.kiro/steering/{product,tech,structure,roadmap}.md` — プロジェクト全体の steering context
- Python 標準ライブラリ: `difflib` (HTML/text diff) / `hashlib` (state hash) / `pathlib` (path 操作) / `subprocess` (LLM CLI 呼出 timeout)
- PEP 342 / PEP 380: Python generator yield pattern (Decision 7-5 の根拠)

---

_change log_

- 2026-04-28: 初版生成 (Spec 7 design draft 起票時、20 設計決定 + 6 リスク + 9 references). Discovery scope = Complex Integration. Spec 4 申し送り 7 項目 + Spec 1 schema 継承 + Spec 5 edge API + Spec 6 hypothesis flow + Spec 2 skill lifecycle + Foundation 規範 6 項目を統合.
- 2026-04-28 (Round 1-10 review 完了): 全 10 ラウンド (R1 requirements 全 AC 網羅 / R2 アーキテクチャ整合性 / R3 データモデル / R4 API interface / R5 アルゴリズム+性能 / R6 失敗 handler+観測性 / R7 セキュリティ / R8 依存選定 / R9 テスト戦略 / R10 マイグレーション戦略) を memory 改訂版方式 (4 重検査 + Step 1b-v 5 切り口 + 厳しく検証 5 種強制発動 + 自動承認モード廃止 + Step 2 user 判断必須) で網羅実施. design.md 1425 → 1754 行 (+329 行) に拡充, 合計 30 件適用 (軽微自動採択 19 件 + escalate 確証 11 件) + 設計決定 1 件追加 (**Decision 7-21 = Layer 4 機能別 3 sub-module 分割**、Round 2 review 由来) + Adjacent Sync 経路 4 項目追加 (Spec 5 R11.6 改版 / Spec 6 args construct coordination / R12.7 6→7 種拡張 + Spec 5 R11.2 22→23 種拡張). research.md は本 commit で Decision 7-21 + Architecture Pattern Evaluation 2 行追加 + Summary > Key Findings に Round 2 由来項目追加で design.md と整合.
