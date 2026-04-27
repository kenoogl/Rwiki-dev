# Requirements Document

## Project Description (Input)

Rwiki v2 はすべてのタスクを `rw <task>` で統一起動する CLI を持つ。v1 では `rw_light.py` が散発的にコマンドを追加した結果、起動方式が CLI 直接 / Hybrid / Prompt-only に混在し、対話型エントリも統一されていなかった。L2 Graph Ledger 操作（graph / edge / reject / extract-relations / audit graph）を追加するにあたり、既存の散発構造のままでは UX が破綻する。Maintenance UX（曖昧指示への候補提示、複合診断 orchestration、Autonomous maintenance）も未整備のため、ユーザーがコマンド名を覚えていなくても LLM が自然言語でガイドできる対話型 default の入口（`rw chat`）が必要となる。

本 spec（Spec 4、Phase 2）は、`rwiki-v2-foundation`（Spec 0）が固定したコマンド 4 Level 階層・実行モード 3 種・13 中核原則と、`rwiki-v2-classification`（Spec 1）が固定した frontmatter スキーマ・vocabulary・lint 統合規約を前提として、(a) 対話型エントリ `rw chat`（LLM CLI 起動 / AGENTS 自動ロード / Maintenance UX）、(b) 各タスクの CLI 統一（distill / approve / lint / audit / query / perspective / hypothesize / discover 等）、(c) 対話型 default と `--auto` フラグの可否ポリシー、(d) `rw check <file>` 診断コマンド、(e) `rw follow-up *` コマンド群、(f) Maintenance UX（曖昧指示の候補提示、複合診断 orchestration、Autonomous maintenance 提案）、(g) L2 Graph Ledger 管理コマンド群（`rw graph` / `rw edge` / `rw reject` / `rw extract-relations` / `rw audit graph`）の CLI dispatch、(h) `rw doctor` 複合診断コマンド、を実装する。

L2 Graph Ledger 管理コマンドの内部ロジック（`edges.jsonl` 操作、Hygiene 進化則、Reject queue の data model）は Spec 5 が所管し、本 spec は CLI dispatch（引数 parse、対話 confirm、Spec 5 API 呼出、結果出力、exit code 制御）のみを所管する。Page lifecycle の状態遷移ルールは Spec 7 が所管し、本 spec は dangerous op コマンドの対話 confirm UI と `--auto` フラグハンドリングのみを所管する。Skill 選択 dispatch は Spec 3 が所管する。

出典 SSoT: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.11 ユーザー primary interface / Maintenance LLM guide / §3.4 実行モード / §3.5 コマンド 4 Level 階層 / §6 Task & Command モデル / §7.2 Spec 4 cli-mode-unification / `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 33 メンテナンス UX 全般原則。Upstream: `rwiki-v2-foundation` requirements.md（13 中核原則・コマンド 4 Level 階層・実行モード 3 種）/ `rwiki-v2-classification` requirements.md（frontmatter スキーマ・lint vocabulary 統合 / `rw tag *` コマンド群）。

## Introduction

本 requirements は、Rwiki v2 の Spec 4 として **CLI モード統一と対話型エントリ・Maintenance UX** を定義する。読者は Spec 4 の実装者と、本 spec が定める CLI dispatch 規約を引用する Spec 5（knowledge-graph、L2 管理コマンドの内部 API 実装）/ Spec 6（perspective-generation、`rw perspective` / `rw hypothesize` の Hybrid 実行）/ Spec 7（lifecycle-management、dangerous op の状態遷移実装）の起票者である。

本 spec は **CLI を直接実装する spec** であり、規範文書（Foundation）と異なり実装される機能を含む。したがって本 requirements の各 acceptance criterion は、(a) `rw <task>` ディスパッチが満たすべき動作要件、(b) `rw chat` が満たすべき対話 UX 要件、(c) Maintenance UX が満たすべき候補提示・診断・Autonomous 提案要件、(d) L2 Graph Ledger 管理コマンドが満たすべき CLI dispatch 要件、(e) `--auto` ポリシーが満たすべき安全要件、(f) 周辺 spec との境界・coordination 要件、として記述される。Subject は概ね `the rw CLI` または個別コンポーネント（`the rw chat command` / `the rw doctor command` / `the rw graph command` / `the rw reject command` / `the Maintenance UX` 等）を用いる。

本 spec の成果物は次の 6 種類に分類される。

- 対話型エントリ `rw chat`（LLM CLI 起動 / AGENTS 自動ロード / 内部 `rw <task>` 呼出 / Maintenance UX 込み）
- 各タスクの CLI 統一（`rw lint` / `rw ingest` / `rw distill` / `rw extend` / `rw merge` / `rw split` / `rw approve` / `rw unapprove` / `rw query` / `rw perspective` / `rw hypothesize` / `rw discover` / `rw audit` / `rw retag`）
- L2 Graph Ledger 管理コマンドの CLI dispatch（`rw graph` 9 サブコマンド / `rw edge` 4 サブコマンド / `rw reject` / `rw extract-relations` / `rw audit graph`、内部は Spec 5 API 呼出）
- 診断・補助コマンド（`rw check <file>` / `rw doctor` / `rw follow-up` 4 サブコマンド / `rw init` 2 形式）
- 対話型 default と `--auto` フラグの可否ポリシー（許可リスト / 禁止リスト）
- Maintenance UX（曖昧指示の候補提示 / 複合診断 orchestration / Autonomous maintenance 提案）

Spec 5-7 が本 spec を引用することで、CLI 入口とコマンド名・実行モード・dangerous op の対話ポリシーが複数 spec で分岐することを防ぐ。

## Boundary Context

- **In scope**:
  - 対話型エントリ `rw chat`（LLM CLI 起動、AGENTS 自動ロード、内部 `rw <task>` 呼出、Maintenance UX 込み、対話ログ自動保存 = Requirement 1.8、`--mode autonomous` 起動 flag dispatch = Requirement 1.9）
  - 各タスクの CLI dispatch（`rw lint` / `rw ingest` / `rw retag` / `rw distill` / `rw extend` / `rw merge` / `rw split` / `rw approve`（Requirement 16 で review 層 dispatch を所管）/ `rw unapprove` / `rw query {answer, extract, fix, promote}` / `rw perspective` / `rw hypothesize` / `rw discover` / `rw audit {links, structure, semantic, strategic, deprecated, tags, evidence, followups, graph}`）
  - **Decision Log 管理コマンドの CLI dispatch（`rw decision {history, recent, stats, search, contradictions, render}`、Requirement 15、内部は Spec 5 API 呼出）**
  - 実行モード 3 種（Interactive `rw chat` / CLI 直接 `rw <task>` / CLI Hybrid 内部 LLM CLI 呼出）の同一エンジン規約
  - 対話型 default と `--auto` フラグの可否ポリシー（許可リスト / 禁止リスト）
  - dangerous op コマンド（deprecate / retract / archive / reactivate / unapprove / merge / split / query promote / tag merge / tag split / tag rename / skill install / skill retract）の対話 confirm UI と `--auto` ハンドリング
  - L2 Graph Ledger 管理コマンドの CLI dispatch（`rw graph {rebuild, status, hygiene, neighbors, path, orphans, hubs, bridges, export}` / `rw edge {show, promote, demote, history}` / `rw reject` / `rw extract-relations` / `rw audit graph`、内部は Spec 5 API 呼出）
  - 診断コマンド `rw check <file>`（ファイルに対する適用可能タスク列挙）
  - 複合診断コマンド `rw doctor`（全層並行スキャン、診断のみ）
  - `rw follow-up {list, show, resolve, remind}` コマンド群
  - `rw init <path> [--reinstall-symlink]` Vault 初期化コマンド
  - Maintenance UX：曖昧指示への候補提示、複合診断 orchestration、Autonomous maintenance 提案、`/dismiss` / `/mute` 等のユーザー制御
  - `.rwiki/.hygiene.lock` 概念上の取得・解放を CLI 側で行う規約（実装は Spec 5 と整合）
  - exit code 0/1/2 分離、Severity 4 水準の出力統一、subprocess timeout 必須を全コマンドに適用
  - L4 Power user / CI 向けに全コマンド直接実行可能（環境変数や非対話 flag 経由）

- **Out of scope**:
  - Skill ライブラリの実装（Spec 2 / `.rwiki/skills/` のスキーマ・選択ヒント）
  - Skill 選択 dispatch ロジック（Spec 3 / 明示 → `type:` → category default → LLM 判断の優先順位）
  - L2 Graph Ledger の data model と内部ロジック（Spec 5 / `edges.jsonl` 操作、Hygiene 進化則、reject queue の append-only 規約、`relations.yml`、`normalize_frontmatter` API、initial confidence 計算 6 係数）
  - Page lifecycle の状態遷移ルール（Spec 7 / `active` ↔ `deprecated` ↔ `retracted` ↔ `archived` ↔ `merged` の 5 状態、`successor` / `merged_from` / `merged_into` のセマンティクス）
  - Perspective / Hypothesis / Discovery 生成ロジック（Spec 6 / `perspective` / `hypothesize` / `discover` の prompt 設計、`autonomous` モードの内部）
  - Frontmatter スキーマ・vocabulary 自体（Spec 1 / `tags.yml` / `categories.yml` / `entity_types.yml`）
  - `rw tag *` コマンドの実装（Spec 1 が所管、ただし本 spec は dangerous op の `rw tag merge` / `rw tag split` / `rw tag rename` の対話 confirm 規約を Spec 1 と整合させる）

- **Adjacent expectations**:
  - 本 spec は Foundation（Spec 0、`rwiki-v2-foundation`）が固定する 13 中核原則 / 用語集 / 3 層アーキテクチャ / コマンド 4 Level 階層 / 実行モード 3 種 / Edge status 6 種と Page status 5 種の区別 を **唯一の引用元** として参照し、独自定義による再解釈・再命名を行わない。Foundation の用語と矛盾する記述が必要になった場合は先に Foundation を改版し、その後本 spec を更新する（roadmap.md「Adjacent Spec Synchronization」運用ルールに従う）。
  - Spec 1 は frontmatter スキーマと vocabulary を所管し、本 spec の `rw lint` / `rw ingest` / `rw audit tags` 等は Spec 1 の vocabulary 統合規約と severity 体系（CRITICAL / ERROR / WARN / INFO）に従う。
  - Spec 5 は L2 Graph Ledger の Query / Mutation API（neighbor / path / orphans / hubs / bridges / export / reject / extract-relations / Hygiene 等）を所管し、本 spec の `rw graph *` / `rw edge *` / `rw reject` / `rw extract-relations` / `rw audit graph` は Spec 5 API の薄い CLI dispatch wrapper として動作する。
  - Spec 5 と本 spec は `.rwiki/.hygiene.lock` の concurrency strategy（取得タイミング / 取得失敗時のメッセージ / dry-run 時の lock 取得可否）を整合させる。本 spec は CLI 側の lock 取得・解放契約を所管し、lock の物理実装は Spec 5 が所管する。本 spec は `rw tag *` 系 vocabulary 変動操作の lock 取得契約も所管する（Spec 1 Requirement 8.14 由来 coordination 要求、Requirement 10.1 と整合）。**さらに本 spec は write 系 `rw skill *` 操作（`rw skill draft` / `rw skill test` / `rw skill install`）の lock 取得契約も所管する**（Spec 2 Requirement 13.8 由来 coordination 要求、Requirement 10.1 と整合）。
  - Spec 5 は **Decision Log の記録・検索・集計・矛盾検出 API（`record_decision()` / `get_decisions_for()` / `search_decisions()` / `find_contradictory_decisions()` の 4 種、Spec 5 Requirement 14 で確定済 Query API 15 種の一部）** を所管し、本 spec の `rw decision *` 6 サブコマンド（Requirement 15）は Spec 5 API の薄い CLI dispatch wrapper として動作する。Tier 2 markdown timeline（`review/decision-views/<id>-timeline.md`）の生成機構は Spec 5 Requirement 11.11 が規定し、**内部 API 名は Spec 5 design phase で確定**する。`record_decision()` の自動呼出責務は本 spec が CLI 側で行うが、`decision_log.jsonl` の schema・privacy mode・selective recording ルール本体は Spec 5 の所管とする。
  - Spec 2（skill-library）は `rw chat` の **対話ログ frontmatter スキーマ（`type: dialogue_log` / `session_id` 等）と markdown フォーマット**を所管し（drafts Scenario 15 / 25 と整合）、本 spec の Requirement 1.8 が定める対話ログ保存実装はこのスキーマに従う。Spec 6 は対話ログの保存タイミング（perspective / hypothesis 生成時の trigger）を規定し、本 spec はそれら trigger からの保存実装を提供する。
  - Spec 7 は dangerous op コマンド（deprecate / retract / archive / reactivate / unapprove / merge / split）の状態遷移ルール本体を所管し、本 spec はこれらコマンドの CLI dispatch、対話 confirm UI、`--auto` ポリシー、確認段階数（8 段階対話 / 1-stage confirm）を所管する。
  - Spec 6 は `rw perspective` / `rw hypothesize` / `rw discover` の prompt と内部生成ロジックを所管し、本 spec はこれらコマンドの引数 parse と Hybrid 実行（内部 LLM CLI 呼出 / subprocess timeout / 結果整形）を所管する。
  - Maintenance UX の autonomous trigger 判定値（reject queue 件数閾値、decay edges 件数閾値、未 approve 件数閾値、audit 未実行期間閾値）の **計算実装** は Spec 5（L2 診断項目）と Spec 7（L3 診断項目）に委ね、本 spec はそれら値を取得・surface する CLI 側 UX のみを所管する。

## Requirements

### Requirement 1: 対話型エントリ `rw chat` の動作

**Objective:** As a Rwiki v2 ユーザー, I want `rw chat` を default 入口として LLM CLI が起動し AGENTS が自動ロードされ Maintenance UX が利用できる, so that コマンド名・オプションを覚えなくても自然言語で意図を伝えるだけで Rwiki の全タスクを操作できる。

#### Acceptance Criteria

1. When ユーザーが `rw chat` を引数なしで実行した, the rw chat command shall LLM CLI を subprocess として起動し、`AGENTS/` 配下のファイル群（運用ルール）を自動的にコンテキストへロードする。
2. The rw chat command shall 対話セッション中に LLM が Bash tool 等で `rw <task>` を内部呼出することを前提とした起動環境を提供する。
3. While `rw chat` セッションが進行中, the rw chat command shall ユーザー発話に対して LLM が `rw <task>` を内部呼出して結果を整形・要約して返す UX を成立させる。
4. The rw chat command shall エディタ内蔵ターミナル（VSCode / Obsidian）および別プロセスから起動可能な subprocess 起動契約を持つ（特定エディタのプラグインに依存しない）。
5. If LLM CLI subprocess の起動に失敗した, then the rw chat command shall 失敗理由を stderr に出力し exit code 1（runtime error）で終了する。
6. The rw chat command shall LLM CLI subprocess に対して subprocess timeout を必須設定として渡す（roadmap.md「v1 から継承する技術決定」に従う）。`rw chat` の subprocess timeout は **チャットセッション全体の timeout ではなく、対話中に LLM が内部で呼び出す各 `rw <task>` 呼出ごとに渡す timeout** として解釈する（チャットセッション自体は対話継続のため長時間動作することを許容する）。
7. While `rw chat` セッションが進行中, the rw chat command shall Maintenance UX（Requirement 6 / Requirement 7 / Requirement 8）を利用可能にする。
8. While `rw chat` セッションが進行中, the rw chat command shall 対話ログを `raw/llm_logs/chat-sessions/<timestamp>-<session-id>.md` に **append-only で自動保存** する（drafts §2.11 / Scenario 15 / Scenario 25 / Scenario 33 と整合）。複数の `rw chat` セッションが同時起動された場合, the rw chat command shall 各セッションに一意の `<session-id>` を付与して対話ログファイルを物理的に分離し、別セッションの append による衝突・上書きを発生させない。対話ログの **frontmatter スキーマ（`type: dialogue_log` / `session_id` / `started_at` / `ended_at` / `turns` 等）と markdown フォーマットの規定**は Spec 2（skill-library）の所管とし（Scenario 15 / 25 と整合）、保存タイミング（append 単位 / flush 単位）と format 反映の trigger は Spec 6（perspective-generation）の規定に従う。本 spec は **保存実装と保存先 path 規約のみ**を所管する。
9. The rw chat command shall `rw chat --mode autonomous` の起動 flag および対話セッション中の `/mode` トグルコマンドを dispatch し、autonomous mode 切替の **CLI 引数 parse とフラグ伝達**を所管する（drafts §2.14 / Scenario 14）。autonomous mode の **内部生成ロジック（perspective / hypothesis 自動 surface のアルゴリズム、prompt 設計、surface 頻度・閾値の判定）**は Spec 6 の所管とし、本 spec は flag dispatch と Maintenance UX 提案 surface（Requirement 8 と整合）のみを所管する。

### Requirement 2: 各タスクの CLI 統一と実行モード 3 種

**Objective:** As a Rwiki v2 ユーザーおよび CI/CD 自動化担当者, I want すべてのタスクが `rw <task>` の単一コマンドファミリで起動でき、Interactive / CLI 直接 / CLI Hybrid の 3 モードがいずれも同じエンジン関数を呼ぶ, so that 起動方式の混在による UX の崩れと結果の差異を防げる。

#### Acceptance Criteria

1. The rw CLI shall §6.1 Task 一覧 の全タスク（`lint` / `ingest` / `distill` / `approve` / `query {answer, extract, fix}` / `audit {links, structure, semantic, strategic, deprecated, tags, evidence, followups, graph}` / `perspective` / `hypothesize` / `discover`）を `rw <task>` 形式の単一エントリとして提供する。
2. The rw CLI shall §6.2 Command 一覧 の全コマンド（コア / Input Pipeline / Knowledge Generation / Approval / Query / Audit / L2 Graph Ledger 管理 / Edge 個別操作 / Entity-Relation 抽出 / Reject workflow / Page Lifecycle / Tag Vocabulary / Skill Library / Follow-up / Vault 管理）を Foundation Requirement 9 が固定したコマンド名のまま実装する（独自に再命名しない）。
3. The rw CLI shall 実行モードを Interactive（`rw chat`）/ CLI 直接（`rw <task> [args]`）/ CLI Hybrid（内部で LLM CLI を呼ぶ `rw <task>`）の 3 種として提供し、いずれも同じ `cmd_*` エンジン関数を呼ぶ規約を持つ。
4. While いずれかのモードでタスクが実行されている場合, the rw CLI shall 同一入力に対して同一の副作用と出力を生成する（モード差で結果が変わらない）。
5. The rw CLI shall 全コマンドが exit code 0/1/2 分離規約（exit 0 = PASS / exit 1 = runtime error / exit 2 = FAIL 検出）に従い、`rw ingest` のように検出概念を持たないコマンドは exit 0/1 のみを使う（roadmap.md「v1 から継承する技術決定」と整合）。
6. The rw CLI shall LLM CLI を呼び出す全 CLI Hybrid コマンドが subprocess timeout を必須設定として渡す（roadmap.md「v1 から継承する技術決定」と整合）。
7. The rw CLI shall Severity 出力を 4 水準（CRITICAL / ERROR / WARN / INFO）として統一し、Spec 1 の lint vocabulary 統合と Foundation の severity 体系に揃える。

### Requirement 3: 対話型 default と `--auto` フラグの可否ポリシー

**Objective:** As a Rwiki v2 ユーザーおよび dangerous op を扱う実装者, I want dangerous op コマンドの default を対話型とし、`--auto` フラグの可否を許可リスト・禁止リストで明確化する, so that 不可逆操作や trust chain を破壊し得る操作が誤って非対話で実行されることを防ぐ。

#### Acceptance Criteria

1. The rw CLI shall dangerous op コマンドの default 実行モードを「対話型 confirm を伴う実行」とし、ユーザーが `--auto` を明示しない限り対話 confirm を省略しない。
2. While `--auto` 許可リストに該当するコマンドが `--auto` 付きで実行された場合, the rw CLI shall 対話 confirm を省略して実行する。許可リストは `rw deprecate` / `rw archive` / `rw reactivate` / `rw merge`（wiki page、慎重判定。drafts §11.3 「`merge (wiki)` ✓（慎重）」と整合、merge_strategy 確定済の場合のみ許可）/ `rw unapprove`（drafts §7.2 Spec 7 表 L2192「✓（`--yes`）」に従い、`--yes` フラグの明示を要求、Spec 7 Requirement 6.7 と整合）/ `rw tag merge` / `rw tag rename` / `rw skill install` / `rw extract-relations` / `rw reject <edge-id>`（特定 edge-id 指定時のみ）とする。
3. If `--auto` 禁止リストに該当するコマンドが `--auto` 付きで実行された, then the rw CLI shall 即座に exit code 1 で失敗し stderr に「このコマンドは --auto を許可しません」と理由を出力する。禁止リストは `rw retract` / `rw query promote` / `rw split`（wiki page 分割は不可逆の構造変更のため禁止）/ `rw tag split` / `rw skill retract` の **5 種**とする（drafts §7.2 Spec 7 表 L2183-2197 と整合、Spec 7 Requirement 6.4 と一致）。The rw CLI shall 環境変数（例: `RWIKI_FORCE_AUTO=1`）や非標準起動オプションを介して **禁止リストの `--auto` を強制 on にするバイパス経路を提供しない**（バイパスを試みた場合も同様に exit code 1 で拒否する）。Maintenance UX（Requirement 7 / 8 の包括承認）も禁止リストに対する `--auto` バイパスとして機能してはならない（Requirement 7.5 と整合）。
4. While 対話 confirm が必要な dangerous op コマンドが Interactive モード外（CLI 直接 / CLI Hybrid）で `--auto` なしに実行された場合, the rw CLI shall 標準入出力で対話 confirm を行うか、対話不能な環境（非 TTY 等）では exit code 1 で「対話必須コマンドです、`rw chat` 経由か `--auto`（許可されている場合）で実行してください」と通知する。
5. The rw CLI shall `rw retract` / `rw query promote` / `rw split` / `rw tag split` / `rw skill retract` の **5 種**を「Foundation §2.4 Dangerous ops 8 段階」相当の対話を伴う commands として扱い、確認段階の最終ゲートを必須とする（drafts §7.2 Spec 7 表 L2183-2197 / Spec 7 Requirement 6.4 の 5 操作と整合、Requirement 3.3 禁止リスト 5 種と一致）。`rw unapprove` は drafts §7.2 Spec 7 表 L2192 に従い「Simple dangerous op（1 段階確認）」として `--yes` フラグ確認のみで実行可能とする（Foundation §2.5 Simple dangerous ops 適用）。
6. The rw CLI shall `rw reject`（引数なし、対話 reject queue 処理）を Simple dangerous op として 1-stage confirm のみ要求する一方、`rw reject <edge-id>`（特定 edge-id 指定時）は `--auto` 許可とする（Foundation §2.5 / §2.12 に準拠）。
7. The rw CLI shall L4 Power user / CI 用途として、許可リストのコマンドが `--auto` 付きで実行された場合に exit code 0/2 のみで結果を判定可能な非対話出力を提供する（CI から下流 consumer が parse できる構造）。

### Requirement 4: 診断コマンド `rw check <file>` と `rw doctor`

**Objective:** As a Rwiki v2 ユーザー, I want 任意のファイルに適用可能なタスクを列挙する `rw check <file>` と全層並行スキャンを行う `rw doctor` を持つ, so that 状態確認のためにメンテナンスコマンドを実行する前段の診断を一意の入口で行える。

#### Acceptance Criteria

1. When ユーザーが `rw check <file>` を実行した, the rw check command shall 指定 file の path / frontmatter / 配置層（L1 raw / L2 候補 / L3 wiki / review）を識別し、適用可能なタスク（lint / ingest / distill / approve / merge / split / extract-relations / deprecate 等）を一覧として stdout に出力する。
2. The rw check command shall 各候補タスクについて「実行に必要な前提（commit 状態、前段タスク、対話必須か）」を併記する。
3. If 指定 file が Rwiki Vault 配下に存在しない, then the rw check command shall ERROR を出力し exit code 1 で終了する。
4. When ユーザーが `rw doctor` を実行した, the rw doctor command shall 全層（L1 raw / L2 Graph Ledger / L3 wiki）の診断項目を並行スキャンして結果を要約出力する。
5. The rw doctor command shall 診断対象として L1 incoming 状態（未 ingest / FAIL 滞留）/ L2 状態（reject queue 件数 / decay 進行中 edges 件数 / typed-edge 整備率 / dangling evidence 件数）/ L3 状態（未 approve 件数 / audit 未実行期間 / tag vocabulary 重複候補 / 未解決 follow-up 件数）/ **Decision Log 健全性**（`decision_log.jsonl` の append-only 整合性、過去 decision 間の矛盾候補件数、`decision_log` schema 違反件数。Foundation Requirement 12 / §2.13 Curation Provenance と整合）を含む。
6. The rw doctor command shall 診断のみを行い副作用を一切持たない（修正・削除・ledger 更新を行わない）。
7. The rw doctor command shall 診断項目の **計算ロジック本体** を Spec 5（L2 診断 / Decision Log 健全性）/ Spec 7（L3 診断）/ 本 spec（L1 診断）の所管 API 呼出として実装し、独自に診断ロジックを再実装しない。
8. The rw doctor command shall 結果出力を JSON / human-readable 両形式で提供し、JSON 出力には **`schema_version` field を必須**として含めることで CI 下流 consumer の parse 安定性を保証する（schema 進化時の破壊的変更検知のため）。
9. The rw doctor command および本 spec の全 graph 系・診断系コマンド（`rw graph status` / `rw graph hubs` / `rw graph neighbors` / `rw doctor` 等の長時間実行可能なコマンド）shall **コマンド全体の実行 timeout を CLI 側で設定可能**とし、Edges > 10,000 / Pages > 1,000 規模で hang した場合に CI 環境から abort 可能な exit code 1（runtime error）として終了する規約を持つ（Spec 5 / Spec 7 が提供する内部 API の timeout は各 spec 所管、本 spec は CLI 側 timeout 設定を所管）。

### Requirement 5: `rw follow-up *` コマンド群と `rw init` / `rw retag`

**Objective:** As a Rwiki v2 ユーザー, I want follow-up（未解決の確認事項）の一覧・表示・解決マーク・優先度順表示と Vault 初期化・タグ再抽出のコマンドが提供されている, so that 対話セッション外でも基本的なメンテナンスを CLI で完結できる。

#### Acceptance Criteria

1. The rw follow-up command shall サブコマンド `list` / `show <file>` / `resolve <file>` / `remind` を提供する。
2. When `rw follow-up list` が実行された, the rw follow-up command shall `wiki/.follow-ups/` 配下の未解決 follow-up を一覧として stdout に出力する。
3. When `rw follow-up show <file>` が実行された, the rw follow-up command shall 指定 follow-up file の本文と関連 metadata を出力する。
4. When `rw follow-up resolve <file>` が実行された, the rw follow-up command shall 指定 follow-up を解決済みとしてマークする（具体的な状態変更表現は Spec 7 の lifecycle 規約と整合させる）。
5. When `rw follow-up remind` が実行された, the rw follow-up command shall 未解決 follow-up を優先度順に並べて出力する。
6. When `rw init <path>` が実行された, the rw init command shall 指定 path に新規 Vault 構造（`raw/` / `wiki/` / `review/` / `.rwiki/` 等の最小集合）を初期化する。
7. When `rw init <path> --reinstall-symlink` が実行された, the rw init command shall 既存 Vault に対して `rw` symlink のみを再作成する（Vault 内データを変更しない）。
8. When `rw retag <path-or-glob>` が実行された, the rw retag command shall 指定対象に対してタグを LLM で再抽出する CLI Hybrid タスクを実行し、subprocess timeout 必須を満たす。

### Requirement 6: Maintenance UX — 曖昧指示への候補提示

**Objective:** As a Rwiki v2 ユーザー, I want `rw chat` セッションで曖昧な発話（例:「整理しておいて」「チェックして」）に対して LLM が拒絶せず候補タスクを提示する, so that メンテナンスコマンドの正式名・オプションを知らなくてもタスクに到達できる。

#### Acceptance Criteria

1. While `rw chat` セッション中に曖昧なメンテナンス意図の発話が入力された, the Maintenance UX shall 即座に拒絶（"タスクが不明瞭です、STOP"）せず、候補タスクのリストを提示する（Scenario 33 Bad UX 禁止）。
2. The Maintenance UX shall 候補リストに各候補タスクの一行説明を併記する（例: `lint — raw/incoming/ の検証のみ`）。
3. While 候補提示を行う場合, the Maintenance UX shall 直近の作業（例: 直前に追加された raw ファイル、最後に approve されたページ）から最も可能性の高い候補に推測の根拠を併記する。
4. The Maintenance UX shall 各候補タスクの前提条件（commit 状態、前段タスクの完了要否、対話必須かどうか）を可視化する。
5. While ユーザーが候補から選択した場合, the Maintenance UX shall 該当する `rw <task>` を内部呼出して実行し、結果を要約してユーザーに返す。
6. While 候補提示後にユーザーが別意図を述べた場合, the Maintenance UX shall 候補リストを再生成して提示し直す（同じ候補に固執しない）。
7. The Maintenance UX shall タスク名やパターンを学習させる説明（例: 「この操作は distill と言います」）を必要に応じて添えて、ユーザーが将来直接呼出できるよう支援する。

### Requirement 7: Maintenance UX — 複合診断 orchestration

**Objective:** As a Rwiki v2 ユーザー, I want 「Rwiki を綺麗にしたい」のような包括的な発話に対して LLM が全層並行診断を実行し、複数メンテナンスタスクを優先順位で順次提案・実行する, so that ユーザー発話 1 つで複数メンテナンスシナリオをオーケストレーションできる。

#### Acceptance Criteria

1. While `rw chat` セッション中にユーザーが包括的なメンテナンス意図（例:「綺麗にしたい」「最近放っといた」）を発話した, the Maintenance UX shall 内部で `rw doctor` 相当の全層並行診断を実行し結果を集約してユーザーに提示する。
2. The Maintenance UX shall 集約結果を L1 raw / L2 Graph Ledger / L3 wiki の 3 層別に分けて提示する。
3. The Maintenance UX shall 集約結果に対して優先順位の提案（例:「L1 incoming FAIL 滞留 → 作業継続のため最優先」「L2 reject queue → 10 分でレビュー可能」）を付与する。
4. While ユーザーが「全部お任せ」等の包括的承認を返した場合, the Maintenance UX shall 優先順位に従って順次タスクを実行し、各タスクの結果を要約してから次へ進む。順次実行中に **タスクが非ゼロ exit code（exit 1 = runtime error または exit 2 = FAIL 検出）で終了した場合, the Maintenance UX shall halt-on-error をデフォルト挙動として残タスクの実行を中止し**、失敗内容と中断理由をユーザーに提示する（後続タスクが先行タスクの副作用に依存する可能性があるため、自動 skip / 自動 retry はデフォルトで行わない。ユーザーが対話で明示的に「skip」「retry」「continue」を指示した場合のみ後続タスクへ進む）。
5. While 各タスクが dangerous op に該当する場合, the Maintenance UX shall Requirement 3 の対話 confirm ポリシーを遵守し、`--auto` 許可リスト外のタスクで包括的承認を「dangerous op の確認スキップ」として扱わない。
6. The Maintenance UX shall 並行診断の対象項目（L1 incoming 状態 / L2 reject queue / L2 decay edges / L2 typed-edge 整備率 / L2 dangling evidence / L3 未 approve 件数 / L3 audit 未実行期間 / L3 tag vocabulary 重複候補 / L3 未解決 follow-up）を Requirement 4 の `rw doctor` と同じ項目集合とする。
7. The Maintenance UX shall 各診断項目の **計算実装** を Spec 5（L2 診断）/ Spec 7（L3 診断）の API 呼出として行い、独自に診断ロジックを再実装しない。

### Requirement 8: Maintenance UX — Autonomous maintenance 提案

**Objective:** As a Rwiki v2 ユーザー, I want `rw chat` セッション開始時または対話進行中に LLM が能動的に蓄積タスクや状態変化を surface する Autonomous maintenance 提案を持つ, so that ユーザーが尋ねなくても重要なメンテナンス機会を見逃さない。

#### Acceptance Criteria

1. While `rw chat` セッションが開始された場合またはセッション中に状態変化の閾値超過が検知された場合, the Maintenance UX shall 蓄積されたメンテナンス候補を能動的に surface する（ユーザー発話を待たずに提示する）。
2. The Maintenance UX shall surface 対象として L3 系（未 approve 件数 / audit 未実行期間 / deprecated chain の循環）/ L2 系（reject queue 件数 / decay 進行中 edges 件数 / typed-edge 整備率の低下）/ **Decision Log 系（過去 decision 間の矛盾候補検出 = `rw decision contradictions` 相当の閾値超過、Foundation Requirement 12 / §2.13 と整合）**を含む。
3. The Maintenance UX shall surface 時に各提案の根拠（件数 / 期間 / 閾値）を併記する。
4. While ユーザーが Autonomous 提案に対して `/dismiss` を入力した場合, the Maintenance UX shall 当該セッション中は同じ提案を再 surface しない。
5. While ユーザーが `/mute maintenance` を入力した場合, the Maintenance UX shall それ以降のセッション（永続的）で Autonomous 提案を抑止する（永続化媒体は本 spec の所管とする）。
6. The Maintenance UX shall surface する閾値（reject queue 件数閾値 / decay edges 件数閾値 / 未 approve 件数閾値 / audit 未実行期間閾値）を設定可能な config として持ち、デフォルト値を含む。
7. The Maintenance UX shall surface 判定の **計算実装** を Spec 5 / Spec 7 の API 呼出として行い、本 spec は閾値設定と surface UX のみを所管する。

### Requirement 9: L2 Graph Ledger 管理コマンドの CLI dispatch

**Objective:** As a Rwiki v2 ユーザーおよび L4 Power user / CI 担当者, I want L2 Graph Ledger 操作（graph 全体管理 / edge 個別操作 / reject workflow / extract-relations / audit graph）の CLI を提供し、内部は Spec 5 API を呼ぶ薄い dispatch wrapper として動作する, so that L2 操作が CLI から一意のコマンド名で起動でき、Spec 5 の内部実装変更が CLI 側に波及しない。

#### Acceptance Criteria

1. The rw graph command shall サブコマンド `rebuild [--verify]` / `status` / `hygiene [--dry-run] [--apply decay|competition|merge]` / `neighbors <page> [--depth N] [--relation <type>]` / `path <from> <to>` / `orphans` / `hubs [--top N]` / `bridges <cluster-a> <cluster-b>` / `export --format {dot|mermaid|json} [--scope <path>]` を提供する。
2. The rw edge command shall サブコマンド `show <edge-id>` / `promote <edge-id>` / `demote <edge-id>` / `history <edge-id>` を提供する。
3. The rw reject command shall 引数なし呼出（対話 reject queue 処理）/ `<edge-id>` 指定呼出（特定 edge を reject）/ `--auto-batch`（confidence < 0.2 を一括 reject 候補に）の 3 形式を提供する。
4. The rw extract-relations command shall 引数として `<page>` / `--all` / `--since "<duration>"` / `--new-only` の 4 形式を提供する。本コマンドは LLM CLI を内部呼出する **CLI Hybrid 実行**であり、subprocess timeout 必須（Requirement 11.3 と整合）として実装する。
5. When `rw audit graph [--communities] [--find-bridges] [--repair-symmetry] [--propose-relations]` が実行された, the rw audit graph command shall 各 flag に応じた L2 Graph Ledger 整合性監査を Spec 5 API 呼出として実行する。
6. The L2 Graph Ledger 管理コマンド群 shall 内部ロジック（`edges.jsonl` 操作、Hygiene 進化則、reject queue の append-only 規約、initial confidence 計算、`relations.yml` 参照、`normalize_frontmatter` API）を **Spec 5 が所管する API への呼出** として実装し、本 spec の所管は CLI 引数 parse、対話 confirm、Spec 5 API への引数転送、結果整形、exit code 制御に限定する。
7. The L2 Graph Ledger 管理コマンド群 shall 全コマンドで exit code 0/1/2 分離規約および Severity 4 水準の出力統一を満たす。
8. The rw reject command shall `<edge-id>` 指定時の `--auto` を許可（Requirement 3.2 と整合）し、引数なし呼出時は 1-stage confirm を必須とする。
9. The rw reject command shall **`reject_reason_text` を空文字で受領した場合 exit code 1 で失敗**し、reject 操作を ledger に書き込まない（roadmap.md「Reject 理由必須」/ Foundation Requirement 13.5 / §2.6 / `reject_learner` skill の学習素材として必須）。`--auto-batch` 形式（confidence < 0.2 の一括 reject 候補化）でも、実際の reject コミット時は **1 件ずつユーザーに `reject_reason_text` の入力を求める**（drafts §2.5 / Scenario 35 と整合）。

### Requirement 10: `.rwiki/.hygiene.lock` Concurrency Strategy の整合（Spec 4 ↔ Spec 5）

**Objective:** As a Spec 5 起票者および本 spec 実装者, I want `.rwiki/.hygiene.lock` の取得・解放契約を CLI 側（本 spec）と API 側（Spec 5）で一意に固定する, so that Hygiene バッチと CLI 操作の同時実行による ledger 破損を防げる。

#### Acceptance Criteria

1. While L2 Graph Ledger を変更し得るコマンド（`rw graph hygiene` / `rw reject` / `rw extract-relations` / `rw edge promote` / `rw edge demote`）**または vocabulary を変動させる `rw tag *` 操作（`rw tag merge` / `rw tag split` / `rw tag rename` / `rw tag deprecate` / `rw tag register`、Spec 1 Requirement 8.14 由来 coordination 要求）または write 系 `rw skill *` 操作（`rw skill draft` / `rw skill test` / `rw skill install`、Spec 2 Requirement 13.8 由来 coordination 要求）**が実行されている場合, the rw CLI shall 実行開始時に `.rwiki/.hygiene.lock` を取得し、終了時（成功・失敗いずれも）に解放する規約を持つ。vocabulary 変動操作の lock 取得は `tags.yml` / `categories.yml` / `entity_types.yml` および影響を受ける markdown ファイル群の整合性保証のために行い、**skill 変動操作の lock 取得は `AGENTS/skills/` ディレクトリの整合性および `applicable_categories` 値域の参照整合性（Spec 2 Requirement 3.2 / Spec 1 Requirement 7.1 と整合）保証のために行い**、Hygiene batch との競合・複数 `rw tag *` / `rw skill *` 同時実行・複数端末同時編集を排他制御する（Spec 1 Requirement 8.14 / Spec 2 Requirement 13.8 / Foundation Requirement 11.5 と整合）。`rw skill list` / `rw skill show` は read-only 操作のため lock 取得対象外とする（Spec 2 Requirement 13.8 と整合）。
2. If `.rwiki/.hygiene.lock` が他プロセスにより取得済の場合, then the rw CLI shall stderr に「Hygiene lock が他プロセスで保持されています」と出力し exit code 1 で終了する（待機しない）。
3. While L2 Graph Ledger を読み取りのみ行うコマンド（`rw graph status` / `rw graph neighbors` / `rw graph path` / `rw graph orphans` / `rw graph hubs` / `rw graph bridges` / `rw graph export` / `rw edge show` / `rw edge history`）が実行されている場合, the rw CLI shall lock 取得を要求しない。
4. While `rw graph hygiene --dry-run` が実行されている場合, the rw CLI shall lock 取得を要求しない（読取相当）。
5. The rw CLI shall lock の物理実装（ファイル形式、stale lock 検出、PID 記録）を Spec 5 が所管する `.rwiki/.hygiene.lock` 規約に委譲し、本 spec 側は取得・解放 API を呼び出す責務のみを持つ。
6. If lock 取得・解放 API が runtime error を返した, then the rw CLI shall stderr にエラー内容を出力し exit code 1 で終了する（lock の状態を不定にしない）。
7. The rw CLI shall lock 関連のメッセージとエラーを Severity 4 水準の体系で出力する。

### Requirement 11: v1 から継承する技術決定の遵守

**Objective:** As a 本 spec 実装者および将来の保守者, I want v1 で確定済の技術決定（Severity 4 水準 / exit code 0/1/2 分離 / call_claude timeout 必須 / モジュール責務分割）を本 spec 実装の制約として明示する, so that 本 spec が Foundation Requirement 11 と roadmap.md「v1 から継承する技術決定」と矛盾しない実装を成立させられる。

#### Acceptance Criteria

1. The rw CLI shall Severity 出力を CRITICAL / ERROR / WARN / INFO の 4 水準で統一し、`map_severity()` identity マッピング（4→3 マッピングコスト解消済）を継承する。
2. The rw CLI shall exit code を `exit 0 = PASS / exit 1 = runtime error / exit 2 = FAIL 検出` の 3 値で分離し、検出概念を持たないコマンド（`rw ingest` 等）は exit 0/1 のみを使う。
3. The rw CLI shall LLM CLI を呼び出す全 subprocess 起動箇所（`rw chat` / `rw distill` / `rw query *` / `rw audit semantic` / `rw audit strategic` / `rw retag` / `rw perspective` / `rw hypothesize` / `rw discover` / `rw extract-relations` / `rw audit graph --propose-relations` 等）で subprocess timeout を必須設定として渡す。`rw chat` の場合は **チャットセッション全体ではなく、対話中に LLM が内部で呼び出す各 `rw <task>` 呼出ごとに timeout を渡す**（Requirement 1.6 と整合）。
4. The rw CLI shall モジュール構成を `rw_<責務>.py` パターンとし、各モジュールを 1,500 行以内に保ち、DAG 依存（循環なし）と モジュール修飾参照（`rw_<module>.<symbol>`）を維持し、後方互換 re-export を行わない。
5. The rw CLI shall エントリポイントを `rw` symlink により提供し、`rw init <path> --reinstall-symlink` を symlink 再作成 helper として実装する。
6. If 本 spec 実装中に v1 から継承する技術決定と矛盾する設計が必要になった, then the rw CLI 実装者 shall 先に Foundation または roadmap.md の改版手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を経由し、独自に逸脱しない。

### Requirement 12: Foundation 規範への準拠

**Objective:** As a 本 spec の品質保証および将来の更新者, I want 本 spec が Foundation（Spec 0、`rwiki-v2-foundation`）の 13 中核原則・コマンド 4 Level 階層・実行モード 3 種・用語集を SSoT として参照し、独自定義による再解釈・再命名を行わない, so that CLI 入口とコマンド名・実行モードの解釈が複数 spec で分岐することを防ぐ。

#### Acceptance Criteria

1. The rw CLI shall Foundation の 13 中核原則のうち §2.1 Paradigm C / §2.2 Review layer first（L3 限定）/ §2.4 Dangerous ops 8 段階（L3 限定）/ §2.5 Simple dangerous ops / **§2.6 Git + 層別履歴媒体**（reject 理由必須 / `decision_log.jsonl` の append-only 等）/ §2.7 エディタ責務分離 / §2.11 Discovery primary / Maintenance LLM guide / §2.12 Evidence-backed Candidate Graph（L2 限定、reject に適用）/ **§2.13 Curation Provenance**（`rw decision *` コマンド群 + `rw approve` / `rw reject` 時の `record_decision()` 呼出と整合、Requirement 15 と紐付き）を本 spec の設計前提として参照することを明示する。
2. The rw CLI shall Foundation Requirement 6（コマンド 4 Level 階層）の L1 発見 / L2 判断 / L3 メンテナンス / L4 Power user 区分と、Foundation Requirement 9（Task & Command モデル）のコマンド名一覧を本 spec の実装対象として継承する（独自に再分類・再命名しない）。
3. The rw CLI shall Foundation Requirement 5 の Edge status 6 種（`weak` / `candidate` / `stable` / `core` / `deprecated` / `rejected`）と Page status 5 種（`active` / `deprecated` / `retracted` / `archived` / `merged`）を CLI 出力で区別し、共通の状態セットとして混同しない。
4. The rw CLI shall §2.11 Discovery primary / Maintenance LLM guide 原則を Maintenance UX（Requirement 6 / 7 / 8）の設計前提として明示し、ユーザーの認知をメンテナンス手順ではなく知識発見に集中させる UX を取る。
5. The rw CLI shall §2.7 エディタ責務分離原則（編集体験はエディタ、パイプラインは Rwiki、Obsidian は参照実装）を `rw chat` 起動契約（特定エディタに依存しない）の前提として遵守する。
6. If Foundation の用語・原則・マトリクスと矛盾する記述が本 spec に必要となった, then the rw CLI 実装者 shall 先に Foundation を改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残し、本 spec を独自に逸脱させない。
7. The rw CLI shall 本 spec 自身が `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.11 / §3.4 / §3.5 / §6 / §7.2 Spec 4 と `.kiro/drafts/rwiki-v2-scenarios.md` Scenario 33 を SSoT 出典とすることを明示する。

### Requirement 13: 周辺 spec との責務分離

**Objective:** As a Spec 5 / Spec 6 / Spec 7 起票者, I want 本 spec の所管（CLI dispatch、対話 UX、引数 parse、`--auto` ポリシー、Maintenance UX、`.hygiene.lock` 取得契約）と周辺 spec の所管（内部ロジック、状態遷移ルール、prompt 設計、診断項目計算）の境界が明文で固定されている, so that 周辺 spec 起票時に本 spec を再変更する coordination リスクが消える。

#### Acceptance Criteria

1. The rw CLI shall L2 Graph Ledger 管理コマンド（`rw graph *` / `rw edge *` / `rw reject` / `rw extract-relations` / `rw audit graph`）の **CLI dispatch のみ** を所管し、内部ロジック（edges.jsonl 操作、Hygiene 進化則、reject queue の append-only 規約、initial confidence 計算、`relations.yml` 参照、`normalize_frontmatter` API、L2 診断項目の計算）を Spec 5 の所管として明示する。
2. The rw CLI shall Page lifecycle コマンド（`rw deprecate` / `rw retract` / `rw archive` / `rw reactivate` / `rw unapprove` / `rw merge` / `rw split`）の **CLI dispatch・対話 confirm UI・`--auto` ポリシー** のみを所管し、状態遷移ルール（5 状態間遷移、`successor` / `merged_from` / `merged_into` のセマンティクス、操作可逆性）と L3 診断項目の計算を Spec 7 の所管として明示する。
3. The rw CLI shall `rw perspective` / `rw hypothesize` / `rw discover` の **引数 parse・Hybrid 実行・subprocess timeout・結果整形** のみを所管し、prompt 設計・autonomous モードの内部生成ロジック・mode 切替の判定を Spec 6 の所管として明示する。
4. The rw CLI shall `rw distill` / `rw query *` / `rw audit semantic` / `rw audit strategic` / `rw retag` の **CLI dispatch と Hybrid 実行契約** のみを所管し、Skill 選択 dispatch（明示 → `type:` → category default → LLM 判断の優先順位）を Spec 3 の所管として、Skill ファイルのスキーマと `.rwiki/skills/` 構造を Spec 2 の所管として明示する。
5. The rw CLI shall `rw lint` / `rw audit tags` / `rw audit links` / `rw audit structure` / `rw audit deprecated` / `rw audit evidence` / `rw audit followups` の **CLI dispatch と severity 統一出力** を所管し、frontmatter スキーマと vocabulary 統合検査ロジックを Spec 1 の所管として明示する。**`rw audit evidence` は本 spec が CLI dispatch を所管しつつ、`source:` field の重複検出・canonical 化提案（同一 paper / DOI / URL / arXiv ID の表記揺れ検出と統合提案）を本 spec の audit task として実装する**（Spec 1 Requirement 5 Adjacent expectations 由来 coordination 要求、Spec 1 が dedup ロジックを規定しないため本 spec が所管する）。
6. The rw CLI shall `rw tag merge` / `rw tag split` / `rw tag rename` の **dangerous op 対話 confirm 規約**（Requirement 3 と整合）を Spec 1 の `rw tag *` コマンド実装と整合させ、`--auto` 許可リスト・禁止リストの両 spec 間の食い違いを発生させない。
7. The rw CLI shall **`rw skill install` / `rw skill deprecate` / `rw skill retract` の CLI dispatch・対話 confirm UI・`--auto` ポリシー** のみを所管し、Skill ファイルのスキーマ・validation rule・dry-run 実装は Spec 2（skill-library）の所管、`rw skill deprecate` / `rw skill retract` の **lifecycle と retract 時の使用禁止メカニズム**は Spec 7（lifecycle-management）の所管として明示する（Spec 2 Requirement 10.6 / Spec 7 Requirement 10 / 11 と整合、`rw skill install` は `--auto` 許可リスト、`rw skill retract` は `--auto` 禁止リスト、Requirement 3 と整合、`rw skill deprecate` の `--auto` 可否は Spec 7 design phase で確定）。なお `rw skill deprecate` は drafts §7.2 Spec 7 表 L2183-2197 の dangerous op 13 種に未列挙のため、Boundary Context in_scope の dangerous op リスト + Requirement 3.2 / 3.3 への反映は **drafts §7.2 Spec 7 表の整理（TODO_NEXT_SESSION.md D-8）後に Adjacent Sync で実施**する保留中 coordination として扱う（同様の状況: `rw tag deprecate` / `rw tag rename` / `rw tag register` も drafts §7.2 Spec 7 表に未列挙だが Spec 1 R8.13 / R8.14 では vocabulary 変動 5 操作として扱う）。
8. The rw CLI shall **Decision Log 管理コマンド（`rw decision history` / `recent` / `stats` / `search` / `contradictions` / `render`、Requirement 15 が定義）の CLI dispatch のみ**を所管し、内部の Decision Log 検索・集計・矛盾検出ロジックを Spec 5 の所管 API（`record_decision()` / `get_decisions_for()` / `search_decisions()` / `find_contradictory_decisions()` の 4 種、Spec 5 Requirement 14 で確定済 Query API 15 種と整合）への薄い wrapper として実装し、`rw decision render` は Spec 5 Requirement 11.11 が規定する Tier 2 markdown timeline 生成機構を呼び出す（**内部 API 名は Spec 5 design phase で確定**）。`record_decision()` の自動呼出責務（`rw approve` / `rw reject` / `rw tag *` approve 時等）は本 spec が CLI 側で行うが、decision schema・privacy mode・selective recording ルール本体は Spec 5 の所管とする（Foundation Requirement 12 / §2.13 Curation Provenance 整合）。
9. If 周辺 spec 起票時に本 spec の CLI dispatch 規約・`--auto` ポリシー・Maintenance UX 設計に変更が必要になった, then the rw CLI 実装者 shall 本 spec を先に改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残す。

### Requirement 14: 文書品質と運用前提

**Objective:** As a 本 spec の品質保証および将来の更新者, I want 本 spec の出力が CLAUDE.md の出力ルール（日本語・表は最小限・長文は表外箇条書き）に準拠し、運用前提（Python 3.10+ / git 必須 / LLM CLI subprocess timeout 必須 / Severity 4 水準 / exit code 0/1/2 分離）を Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」経由で継承する, so that 本 spec の可読性と運用整合性が保たれる。

#### Acceptance Criteria

1. The rw CLI shall 本 spec の requirements / design / tasks 文書を日本語で記述し、`spec.json.language=ja` および CLAUDE.md「All Markdown content written to project files MUST be written in the target language」要件に準拠する。
2. While 本 spec 文書中で表形式を用いる場合, the rw CLI shall 表は最小限に留め、長文・解説は表外の箇条書きまたは段落で記述する。
3. The rw CLI shall 運用前提（Python 3.10+ / git 必須 / LLM CLI subprocess timeout 必須 / Severity 4 水準 / exit code 0/1/2 分離 / モジュール責務分割 / `rw_<責務>.py` パターン / `rw` symlink）を Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」経由で継承し、独自に再定義しない。
4. The rw CLI shall **本 spec が他 spec に発行する全 coordination 要求を、roadmap.md「Coordination 合意の記録」運用ルールに従い両方の spec の design.md に同期記載する**ことを規定する。対象 coordination は最低限以下を含む: (a) `.rwiki/.hygiene.lock` の取得・解放契約（Requirement 10、Spec 5）、(b) `record_decision()` / `get_decisions_for()` / `search_decisions()` / `find_contradictory_decisions()` API 契約および `rw decision render` の Tier 2 markdown timeline 生成機構（内部 API 名は Spec 5 design phase で確定、Spec 5 Requirement 11.11 と整合）（Requirement 15、Spec 5 Requirement 14 で確定済 Query API 15 種と整合）、(c) `rw approve` の review 層 dispatch 契約（Requirement 16、Spec 1 / Spec 5 / Spec 7）、(d) 対話ログ frontmatter スキーマと markdown フォーマット（Requirement 1.8、Spec 2 / Spec 6）、(e) `rw doctor` の L2 / L3 / Decision Log 健全性診断項目計算 API（Requirement 4、Spec 5 / Spec 7）、(f) Page lifecycle dangerous op の状態遷移ルール（Requirement 13.2、Spec 7）、(g) Skill 選択 dispatch（Requirement 13.4、Spec 3 / Spec 2）。
5. The rw CLI shall 本 requirements が定める **16 個の Requirement** の各々について、design 段階で「Boundary Commitments」として境界が再確認されることを前提とし、本 requirements の境界（in scope / out of scope / adjacent expectations）を design phase に渡せる形で固定する。

### Requirement 15: Decision Log 管理コマンドの CLI dispatch

**Objective:** As a Rwiki v2 ユーザーおよび L4 Power user / CI 担当者, I want Curation Provenance（§2.13）の Decision Log を CLI から検索・集計・矛盾検出・timeline render 可能とする `rw decision *` コマンド群を提供し、内部は Spec 5 API を呼ぶ薄い dispatch wrapper として動作する, so that Decision Log が `decision_log.jsonl` として蓄積されても、CLI から一意のコマンド名で参照・分析でき、Spec 5 の内部実装変更が CLI 側に波及しない。

#### Acceptance Criteria

1. The rw decision command shall サブコマンド `history` / `recent` / `stats` / `search` / `contradictions` / `render` の 6 種を提供する（Foundation Requirement 9.2 / drafts L1779-1786 / `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §6 と整合）。
2. The rw decision history command shall `<decision-id>` 引数で特定 decision の詳細表示、`--edge <edge-id>` で edge を生んだ decisions の時系列表示、`--page <path>` で page の curation timeline 表示の 3 形式を提供する。
3. The rw decision recent command shall `[--since "<duration>"]`（例: `7 days`）で直近 decisions を時系列順に表示する。
4. The rw decision stats command shall `decision_type` / `actor` 別の集計を表示する。
5. The rw decision search command shall `"<keyword>"` を引数として `decision_log.jsonl` の `reasoning` / `outcome` / `subject_refs` を全文検索する。
6. The rw decision contradictions command shall 過去の decision 間の矛盾候補（同一 subject に対して相反する decision_type が記録されているケース等）を検出して一覧表示する。
7. When `rw decision render --edge <edge-id>` または `rw decision render --decision <decision-id>` が実行された, the rw decision render command shall Tier 2 markdown timeline（`review/decision-views/<id>-timeline.md`）を生成し、Foundation Requirement 8.4 が定める `review/decision-views/` 配下のスキーマ（`type: decision_view` 等）に従って書き込む。
8. The rw decision command shall 内部の Decision Log 検索・集計・矛盾検出の **計算ロジック本体**を Spec 5 が所管する API（`record_decision(decision)` / `get_decisions_for(subject_ref)` / `search_decisions(query, filter)` / `find_contradictory_decisions()` の 4 種、Spec 5 Requirement 14 で確定済 Query API 15 種の一部）への呼出として実装する。Tier 2 markdown timeline 生成（`rw decision render --edge <id>` で `review/decision-views/<id>-timeline.md` を生成）は Spec 5 Requirement 11.11 が規定する自動生成機構を呼び出すこととし、**内部 API 名は Spec 5 design phase で確定**する（Spec 5 Requirement 14 の Query API 15 種にも内部 API 名は未列挙）。本 spec の所管は CLI 引数 parse、Spec 5 API および timeline 生成機構への引数転送、結果整形（JSON / human-readable）、exit code 制御に限定する。
9. The rw decision command shall 全サブコマンドで exit code 0/1/2 分離規約（exit 0 = PASS / exit 1 = runtime error / exit 2 = FAIL 検出 = `contradictions` で矛盾検出時等）および Severity 4 水準の出力統一を満たす。
10. The rw CLI shall `rw approve` / `rw reject` / `rw tag merge` / `rw tag split` / `rw tag rename` / `rw tag deprecate` / `rw tag register` / `rw deprecate` / `rw retract` / `rw archive` / `rw merge` / `rw split` / `rw query promote` 等の **decision_log 自動記録対象操作**（Foundation Requirement 12.4 / §2.13 selective recording）の approve / 実行完了時に Spec 5 の `record_decision()` API を呼び出す責務を持つ（Spec 1 Requirement 8.13 由来 coordination 要求と整合）。`decision_type` の値（`vocabulary_merge` / `vocabulary_split` / `vocabulary_rename` / `vocabulary_deprecate` / `vocabulary_register` / `synthesis_approve` / `edge_reject` / `page_deprecate` 等）は Spec 5 が初期セットを定義し、Spec 7 / Spec 1 が拡張可とする。
11. The rw decision command shall `decision_log.jsonl` の **privacy mode**（`config.decision_log.gitignore: true` 時）に対応し、privacy mode 下でも本コマンド群がローカルに対しては機能することを保証する（git 共有時のみ抑止する Spec 5 設計と整合）。
12. The rw decision command 一覧の drafts / steering 同期に関しては、本 requirements 確定時点で drafts §6.2 に Decision Log カテゴリが未記載であるため、roadmap.md「Adjacent Spec Synchronization」運用ルールに従って drafts §6.2 の更新を別 issue / 別セッションで実施する旨を本 spec design phase の Boundary Commitments に持ち越す（本 requirements の確定は drafts 更新を待たない）。

### Requirement 16: `rw approve` の review 層 dispatch

**Objective:** As a Rwiki v2 ユーザーおよび Spec 1 / Spec 5 / Spec 7 起票者, I want `rw approve [<path>]` が review 層を path から判別し各層の所管 spec API へ dispatch する規約を本 spec で固定する, so that 周辺 spec が新 review 層を追加するたびに `rw approve` の dispatch ロジックを再交渉する coordination リスクが消え、Spec 1 Requirement 4.9 由来の `vocabulary_candidates/` approve 拡張も他 review 層と同じ規約で扱える。

#### Acceptance Criteria

1. When ユーザーが `rw approve [<path>]` を実行した, the rw approve command shall `<path>` から該当 review 層を判別し（または `<path>` 省略時は全 review 層を順次 scan し）、以下の 6 review 層に対応する dispatch 先を決定する: (a) `review/synthesis_candidates/*` / (b) `review/vocabulary_candidates/*` / (c) `review/audit_candidates/*` / (d) `review/relation_candidates/*` / (e) `review/decision-views/*` / (f) `wiki/.follow-ups/*`（Follow-up）。
2. The rw approve command shall `review/synthesis_candidates/*` を Spec 7 (lifecycle-management) の page lifecycle API（新規 wiki page 生成 / `extend` / `merge` / `deprecate` 等を `merge_strategy` field と `target` field から自動判定、Spec 1 Requirement 3 と整合）への dispatch として処理する。
3. The rw approve command shall `review/vocabulary_candidates/*` を Spec 1 の vocabulary 反映 API（`tags.yml` / `categories.yml` / `entity_types.yml` 更新と影響 markdown 一括更新、Spec 1 Requirement 4.9 由来 coordination 要求）への dispatch として処理し、approve 完了時に Spec 5 の `record_decision()` API（`decision_type: vocabulary_merge` / `vocabulary_split` / `vocabulary_rename` / `vocabulary_deprecate` / `vocabulary_register`、Requirement 15.10 と整合）を呼び出す。
4. The rw approve command shall `review/audit_candidates/*` を本 spec の audit task 反映 API への dispatch として処理する（Foundation Requirement 8.4 で本 spec 所管と再委譲済）。
5. The rw approve command shall `review/relation_candidates/*` を Spec 5 の edge 反映 API（candidate edge → stable / core への昇格、`edges.jsonl` 更新）への dispatch として処理する（Foundation Requirement 8.4 / Spec 5 所管と整合）。
6. The rw approve command shall `review/decision-views/*` を **approve 対象外**として扱う（`review/decision-views/` は Tier 2 markdown timeline の出力先であり、approve 概念を持たない。`rw decision render` で生成される派生成果物。Foundation Requirement 8.4 と整合）。`<path>` が `review/decision-views/*` を指している場合, the rw approve command shall stderr に「decision-views は approve 対象外です（`rw decision render` の出力先）」と通知し exit code 1 で終了する。
7. The rw approve command shall `wiki/.follow-ups/*` を **approve 概念外**として扱い、ユーザーには `rw follow-up resolve <file>`（Requirement 5.4）の使用を案内する（exit code 1）。
8. While `<path>` が複数 review 層にまたがる場合（例: `review/` directory 全体指定）, the rw approve command shall 各層の dispatch を **依存順序**（vocabulary_candidates → synthesis_candidates → relation_candidates → audit_candidates の順、vocabulary 確定が synthesis approve の前提となるため）で実行する。途中で失敗した場合は halt-on-error をデフォルトとし、残層の処理を中止する（Requirement 7.4 と同方針）。
9. The rw approve command shall 各 review 層の approve 操作完了時に Requirement 15.10 の `record_decision()` 呼出を行い、Curation Provenance（§2.13）を保全する。
10. The rw approve command shall 各 review 層の dispatch 先 API の存在前提を Boundary Commitments として design phase に持ち越し、対応 review 層が未実装の spec（Spec 1 / Spec 5 / Spec 7 起票完了前）には dispatch しないことを許容する（暫定動作: 未対応層を skip + WARN）。

---

_change log_

- 2026-04-26: 初版生成 + 6 ラウンドレビュー反映 + approve（致命級 8 件 + 重要級 12 件、`rw decision *` / `rw approve` review 層 dispatch / `.hygiene.lock` 拡張 / 対話ログ自動保存 / 大規模 timeout / `--auto` バイパス防止 等を反映、AC 数 100 → 130）
- 2026-04-27: Spec 5 第 1 ラウンドレビュー由来 Adjacent Sync — Spec 5 Requirement 14 の Query API が 14 種 → 15 種に拡張（`resolve_entity` 追加）されたため、本 spec line 63 / 258 / 270 / 286（2 箇所）の「Query API 14 種」を「Query API 15 種」に文言同期（roadmap.md「Adjacent Spec Synchronization」運用ルールに従い再 approval 不要、参照内容は「Spec 5 が確定する API 群への薄い CLI dispatch wrapper」という構造に変化なし、種数のみの同期）
- 2026-04-27 (Adjacent Sync): Spec 2 第 4 ラウンド 重-2 由来 — R10.1 の `.rwiki/.hygiene.lock` 取得対象に write 系 `rw skill *` 操作（`rw skill draft` / `rw skill test` / `rw skill install`）を追加（Spec 2 R13.8 由来 coordination 要求）。skill 変動操作の lock 取得は `AGENTS/skills/` ディレクトリ整合性および `applicable_categories` 値域の参照整合性保証のために行う旨も追記。Boundary Context Spec 4 ↔ Spec 5 の lock 取得契約説明にも skill 操作を追加。`rw skill list` / `rw skill show` は read-only のため lock 取得対象外（Spec 2 R13.8 と整合）。Adjacent Spec Synchronization 運用ルールに従い再 approval は不要、`spec.json.updated_at` 更新のみ。
