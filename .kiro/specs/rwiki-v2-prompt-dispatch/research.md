# Research & Design Decisions Log

## Summary

- **Feature**: rwiki-v2-prompt-dispatch (Spec 3、Phase 4)
- **Discovery Scope**: Extension (新規 spec、ただし隣接 7 spec との coordination が密)
- **Key Findings**:
  - Spec 1 / Spec 2 / Spec 4 / Spec 0 / Spec 5 / Spec 7 の design.md 全件で本 spec 入力 contract が確定済 (Skill カタログ 15 種 / `applicable_*` 2 系統 / `categories.yml.default_skill` inline 方式 / `type:` 推奨 frontmatter / Severity 4 水準 / exit code 0/1/2 分離 / LLM CLI 抽象層を Spec 3 が提供)
  - 新規 dependency 不要 (PyYAML / Python 標準 `subprocess` / `fnmatch` / `pathlib` のみ、Spec 1 / Spec 2 / Spec 5 と共通)
  - 5 段階 dispatch を Pipeline + Strategy で構築する設計が最小複雑度 (各 stage は単一責務、interface 統一で短絡評価が自然に表現可能)

## Research Log

### Spec 1 (rwiki-v2-classification) との coordination 契約

- **Context**: 本 spec 段階 2 (`type:`) と段階 3 (`categories.yml.default_skill`) は Spec 1 の SSoT に依存
- **Sources Consulted**: `.kiro/specs/rwiki-v2-classification/design.md` G1 / G2 / G3、requirements R2.2 / R7 / R9 / R11
- **Findings**:
  - frontmatter `type:` 推奨 field、許可値 = `categories.yml.recommended_type` ∪ Spec 2 `applicable_categories` 整合表
  - category 判定はディレクトリベース (`wiki/<category>/<file>.md`)、frontmatter `type:` からの推論ではない (R1.4 明記)
  - `categories.yml` の `default_skill` field は inline 方式 (R7.2 / R11.2 確定)、別ファイル分離は採用しない
  - Spec 1 lint task が `type:` 値域 / `default_skill` 値の存在整合 / `applicable_categories` 整合を WARN で検出 (R9.1 / R11.3)
  - frontmatter parse 失敗 / `categories.yml` parse 失敗時の root 検知は Spec 1 lint 委譲、本 spec dispatch は段階スキップで継続 (R4.7 / R5.8 二重防御)
- **Implications**:
  - 本 spec は frontmatter `type:` / `categories.yml` を **読み取り側** として扱い、再定義しない
  - category 解決ロジックは Spec 1 G1 `resolve_category` 準拠、本 spec で再実装しない
  - `type:` 値 → skill 名マッピング表は dispatch 起動時に `categories.yml.recommended_type` × `applicable_categories` の cross-product で導出

### Spec 2 (rwiki-v2-skill-library) との coordination 契約

- **Context**: 本 spec の candidate pool / 段階 3.5 / 段階 4 LLM ヒント / R6 fallback で Spec 2 の skill カタログを参照
- **Sources Consulted**: `.kiro/specs/rwiki-v2-skill-library/design.md` Layer 1 / Layer 2 / §5.6 (skill frontmatter)、requirements R3.2 / R4 / R11
- **Findings**:
  - Standard 15 種 (12 distill + 2 graph + 1 lint) で `generic_summary` は `origin: standard` 配布対象 (R4.4 / R11.6)
  - `applicable_categories` (L3 wiki content category dispatch hint) と `applicable_input_paths` (L1 raw 入力 path 系統 dispatch hint、extended glob 互換) の 2 系統 frontmatter optional field
  - Skill Validator (Spec 2) は path 形式の構文妥当性のみ check、実 path 存在検証は本 spec 所管 (R3.2 明記)
  - status 4 値 (`active` / `deprecated` / `retracted` / `archived`)、初期値 `active`、状態遷移所管は Spec 7
  - 8 section schema (Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions) は本 spec dispatch 範囲では参照しない (Spec 4 distill 実行時に消費)
  - skill ファイル配置 = `AGENTS/skills/<name>.md` 単一ディレクトリ
- **Implications**:
  - 本 spec の `SkillCatalogLoader` は frontmatter 主要 5 field (name / origin / status / `applicable_categories` / `applicable_input_paths`) のみ parse
  - `applicable_input_paths` の glob match 計算は本 spec の責務 (PathGlobResolver)
  - Graph 抽出 / lint 支援 skill は `load_distill_skills()` で除外 (R9.8)
  - `generic_summary` の存在前提で R6 fallback を組む

### Spec 4 (rwiki-v2-cli-mode-unification) との coordination 契約

- **Context**: 本 spec dispatch を呼び出す caller、UI 詳細・exit code 変換を所管
- **Sources Consulted**: `.kiro/specs/rwiki-v2-cli-mode-unification/design.md` R13.4 / R2.5 / R2.7、requirements
- **Findings**:
  - Spec 4 design R13.4: 「`rw distill` の Skill 選択 dispatch (5 段階優先順位) を Spec 3 の所管として明示」と記載済
  - exit code 0/1/2 変換は Spec 4 所管 (R2.5)
  - Severity 4 水準を CLI 出力で統一 (R2.7)
  - 対話モード ↔ `--auto` モード切替判定は Spec 4 所管、本 spec は `interactive_mode: bool` flag を受け取る
  - コンセンサス確認 UI (3 択キー入力) は Spec 4 所管 (R3.6 / R4 系列)
  - subprocess timeout は階層構造: CLI level (Spec 4、例: 600s) > dispatch 内 LLM 1 回呼び出し (本 spec、60s)
- **Implications**:
  - 本 spec は `DispatchResult` (固定 5 フィールド) を返す boundary、Spec 4 が exit code / CLI 出力整形に責任分離
  - `ConfirmUICallback` 関数型 interface を本 spec が type 定義、Spec 4 が実装提供
  - 本 spec の severity 付与表 (R11.2) を Spec 4 の exit code 変換規律に直結

### Spec 0 (Foundation) 規範

- **Context**: 用語集 / Severity 4 水準 / exit code 0/1/2 / LLM CLI 抽象層 (§1.2) の根本規範
- **Sources Consulted**: `.kiro/specs/rwiki-v2-foundation/design.md` §1.2 / §4.4 / §6 / Requirement 11、consolidated-spec L171
- **Findings**:
  - 「LLM 切替のための抽象層は Spec 3 (prompt-dispatch) で定義する」と consolidated-spec L171 で明記、Foundation Requirement で本 spec の責務として固定
  - Severity 4 水準 (CRITICAL / ERROR / WARN / INFO) と exit code 0/1/2 分離は v1 severity-unification spec 由来、roadmap.md「v1 から継承する技術決定」で全 spec 共通
  - 本 spec の dispatch 範囲では CRITICAL 不発火 (Foundation Requirement 11 整合、L2 ledger 破損等の不可逆事象に予約)
  - 用語集 5 分類のうち本 spec は「Skill」「Distill」「Perspective」「Hypothesis」「LLM CLI インターフェイス」「Severity」を整合参照
- **Implications**:
  - `LLMCLIInvoker` を本 spec で定義し、Foundation §1.2 規範を具体化
  - Severity / exit code / subprocess timeout の規律は再定義せず継承
  - 用語の独自再定義 / 再命名を禁止

### Spec 5 (knowledge-graph) / Spec 7 (lifecycle-management) との境界

- **Context**: extraction skill output schema / skill status 遷移所管が本 spec dispatch 経路に影響しないことを確認
- **Sources Consulted**: Spec 5 design L7 / L65 / L893、Spec 7 design L46 / L720 / L1705
- **Findings**:
  - extraction skill (`entity_extraction` / `relation_extraction`) の出力 schema validation は Spec 5 所管、`rw extract-relations` (Spec 4) が直接呼ぶ、本 spec dispatch を経由しない
  - skill status 遷移 (`active` → `deprecated` / `retracted` / `archived`) は Spec 7 lifecycle 操作のみが行う、Spec 2 / Spec 3 は実行しない
  - 本 spec は dispatch 実行直前 (R6.1) に skill status を **read-only** で参照
- **Implications**:
  - `SkillCatalogLoader.load_distill_skills()` で extraction / lint skill を除外する (R9.8)
  - 本 spec dispatch は skill status を一方向に観測のみ、遷移は引き起こさない
  - skill status 遷移経路追加 (新規 status 値導入) は Revalidation Trigger に該当

### SSoT 整合 audit (4 点監査) - design phase 内で実施

- **Context**: design phase の review gate 通過後、ユーザー指示で隣接 spec / drafts SSoT 4 箇所の整合 audit を実施
- **Sources Consulted**:
  - `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.13 §7.2 Spec 3 line 1563 (Purpose: distill 専用)
  - `.kiro/specs/rwiki-v2-prompt-dispatch/requirements.md` line 39 (本 spec が `rw chat` 自然言語経由でも同一 dispatch ロジック共有)
  - `.kiro/specs/rwiki-v2-cli-mode-unification/design.md` line 172 (`Spec3Dispatch` 呼出範囲を 5 種コマンドに拡張記述)
  - `.kiro/specs/rwiki-v2-classification/design.md` line 330 / 731-737 (G6 §「Coordination 1: Spec 1 ↔ Spec 3 (R11)」R11.1-R11.5)
  - `.kiro/specs/rwiki-v2-skill-library/design.md` line 949-954 (Adjacent Sync 経路 § downstream Spec 3 提供契約)
- **Findings**:
  - **(必須 1) drafts §7.2 vs requirements line 39**: drafts は distill 専用、requirements は distill + chat 自然言語経由の同一 dispatch を追加。**実質は distill 範囲の自然言語 entry point 拡張で SSoT を逸脱しない**。design.md This Spec Owns 末尾項で記載済、ただし SSoT 整合 note を追記して明示化
  - **(必須 2) Spec 4 design line 172 不整合**: `Spec3Dispatch` の呼出範囲が `rw distill` / `rw query *` / `rw audit semantic` / `rw audit strategic` / `rw retag` の 5 種に拡張記述、drafts SSoT (§7.2 line 1563 distill 専用) / 本 spec requirements R9.8 (Graph 抽出 / lint 支援は対象外) / R10.1 (distill 専用) / R10.5 (Graph / lint skill 非対象再確認) と不整合。**Spec 4 design 側の誤記**と判定
  - **(推奨 3) Spec 1 R11 章**: G6 §「Coordination 1: Spec 1 ↔ Spec 3 (R11)」(line 731-737) で coordination 5 件 (R11.1 type field / R11.2 inline default_skill / R11.3 値域整合 / R11.4 5 段階優先順位 / R11.5 改版経路) が確定済。design.md は内在化済、明示引用が薄い
  - **(推奨 4) Spec 2 design line 949-954**: Adjacent Sync 経路 § で「downstream Spec 3 (prompt-dispatch): 本 spec が `applicable_categories` / `applicable_input_paths` field を提供、Spec 3 が 5 段階優先順位 dispatch 構築」と提供契約確定済。design.md は内在化済、明示引用が薄い
- **Implications**:
  - (必須 1): design.md Allowed Dependencies 直後に「dispatch 対象範囲の SSoT 整合 note」セクションを追加し、両者整合 (distill 専用 + chat 自然言語意図解釈経由のみ) を明示
  - (必須 2): design.md Revalidation Triggers に Spec 4 design line 172 訂正必要事項を追加、Decision D-11 (dispatch 対象範囲は distill 専用) を新設、Migration Strategy 新節「本 spec design phase で発見した Adjacent Sync 必要事項」で approve 後の訂正工程を明記
  - (推奨 3): design.md Allowed Dependencies の Spec 1 項に R11.1-R11.5 を明示引用
  - (推奨 4): design.md Allowed Dependencies の Spec 2 項に line 949-954 を明示引用
  - 本 spec approve 後の Adjacent Sync 工程で Spec 4 design line 172 を「`rw distill` (CLI 直接 + chat 自然言語意図解釈経由) のみが Spec 3 dispatch を呼び出す」に訂正、Spec 4 approve は再要求しない (Adjacent Spec Synchronization 運用ルール準拠)

### Glob match 実装方法 (Build vs Adopt)

- **Context**: R1.6 で extended glob 互換 (`*` / `?` / `[...]` + `**` recursive) が要請、Python 3.10 標準 `pathlib.PurePath.match` は `**` を 1 segment にしか展開しない
- **Sources Consulted**: Python 3.10 公式 docs / `fnmatch` module / `wcmatch` (third-party)
- **Findings**:
  - `pathlib.PurePath.match`: `**` 非対応 (Python 3.13+ で `full_match` が登場)
  - `fnmatch.translate`: glob → 正規表現変換、`**` は明示変換が必要
  - `wcmatch`: extended glob 完全対応の third-party、ただし新規 dependency 追加が必要
  - Spec 2 design でも同種の glob 検査で `fnmatch` + 自前正規化を採用済
- **Implications**:
  - `fnmatch.translate` で正規表現化し `**` を `.*` に置換する自前正規化を採用
  - 新規 dependency 不要 (steering tech.md「追加依存は networkx ≥ 3.0 のみ」整合)
  - Python 3.13+ への移行時は `pathlib.PurePath.full_match` に置換可能

### LLM CLI subprocess timeout 設計

- **Context**: R2.5 / R11.5 で subprocess timeout 必須、デフォルト値を本 spec で確定
- **Sources Consulted**: roadmap.md「v1 から継承する技術決定」/ Spec 5 design / Spec 4 design
- **Findings**:
  - v1 cli-audit で `call_claude()` ハングリスクが顕在化、v2 では timeout 必須
  - 典型的 LLM 推論時間: 5-30 秒 (短い prompt + 短い response)、長尺コンテンツで 30-60 秒
  - Spec 4 CLI level timeout は 600 秒目安 (`rw distill` 全体)
  - Spec 5 / Spec 4 の subprocess 呼び出しと階層構造を整合
- **Implications**:
  - dispatch 内 LLM 1 回呼び出し timeout = 60 秒をデフォルト採用
  - `.rwiki/config.yml` の `dispatch.llm_timeout_seconds` で上書き可能
  - `LLMCLIInvoker.invoke(prompt, *, timeout: int)` で必須 keyword 引数 (型 level 強制)

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Pipeline + Strategy (採用) | 5 段階を Pipeline で逐次評価、各 stage を Strategy interface に分離 | stage 単位の test 容易性 / 短絡評価の自然な表現 / 将来 stage 追加の影響局所化 | 5 モジュール分割で初期実装行数増加 | 各 stage が `Optional[ResolvedCandidate]` を返す統一 interface |
| 単一巨大関数 (rejected) | 5 段階を 1 つの dispatch() に直書き | 実装が簡素 | test 単位肥大化 / stage 追加時の影響範囲不明 / 短絡評価の可視性低 | Spec 5 / Spec 4 の dispatch も Pipeline 化済、整合性低下 |
| Chain of Responsibility (rejected) | 各 stage が次 stage を直接呼ぶ | 連鎖が暗黙的に表現 | stage 順序変更が複数箇所修正 / 短絡評価の test が困難 / コンセンサス併走の組込みが複雑 | 段階 1 / 2 のコンセンサス併走を別経路にするとパターンが破綻 |
| State Machine (rejected) | dispatch 状態を有限 state で表現 | 状態遷移が明示的 | 5 段階 + コンセンサス併走 + fallback で state 数が膨張 | 過剰設計 |

## Design Decisions

### Decision: 5 段階を Pipeline + Strategy で構築

- **Context**: D-1 (design.md §設計決定事項)
- **Alternatives**: 単一巨大関数 / Chain of Responsibility / State Machine
- **Selected**: Pipeline + Strategy
- **Rationale**: stage 単位 test + 短絡評価の自然表現 + 将来拡張の影響局所化
- **Trade-offs**: 5 モジュール分割の boilerplate、ただし test / メンテナンスが優位
- **Follow-up**: stage 追加時 (Phase 2 で context-based matching 等) は本 pattern を拡張

### Decision: LLM CLI 抽象層を本 spec で定義

- **Context**: D-2、Foundation §1.2 規範具体化
- **Alternatives**: 各 spec が個別 subprocess 呼び出し / 共通 utility 化を別 spec に分離
- **Selected**: 本 spec が `LLMCLIInvoker` interface を定義
- **Rationale**: consolidated-spec L171 で本 spec 所管と明記 / timeout 必須化規律を集中 / Foundation 規範を最小 boilerplate で実現
- **Trade-offs**: LLM CLI ごとに adapter 実装が必要 (将来コスト)、Spec 5 / Spec 4 と共通化の余地
- **Follow-up**: Codex / 他 LLM CLI 対応時は adapter pattern で拡張、本 spec interface は不変

### Decision: cache せず毎回読込 (整合性優先)

- **Context**: D-3、R5.5 / R9.9
- **Alternatives**: メモリ cache + invalidation / disk cache + TTL / cache なし (採用)
- **Selected**: cache なし
- **Rationale**: skill 15 種 / category ≤ 10 種で disk read オーバーヘッド < 50ms (target)、cache 不整合リスク回避、skill lifecycle 即時反映保証
- **Trade-offs**: 大規模化 (skill > 100 / dispatch > 10/s) で再評価が必要、v2 MVP 範囲では non-issue
- **Follow-up**: 性能 cache 導入は別 spec で扱う (現時点では yagni)

### Decision: コンセンサス確認 UI を Spec 4 callback に委譲

- **Context**: D-4、R3.6
- **Alternatives**: 本 spec が UI 実装 / Spec 4 が UI を提供 (採用) / UI なしで `--auto` のみ
- **Selected**: Spec 4 callback
- **Rationale**: `rw chat` 自然言語対話と `rw distill` TUI で UI 形式が異なる、本 spec での UI 抱え込みは Spec 4 と二重実装
- **Trade-offs**: 本 spec test では mock callback 必須、実 UI test は Spec 4 e2e
- **Follow-up**: Spec 4 design 最終版確定後、本 spec の `ConfirmUICallback` 仕様を Adjacent Sync で文言同期

### Decision: glob match を `fnmatch` + 自前 `**` 正規化で実装

- **Context**: D-5、R1.6
- **Alternatives**: `pathlib.PurePath.match` / `fnmatch` + 自前正規化 (採用) / `wcmatch` 採用
- **Selected**: `fnmatch` + 自前正規化
- **Rationale**: 新規 dependency 不要 (steering 整合) / Spec 2 と同方針 / Python 3.13+ 移行容易
- **Trade-offs**: 自前正規化の edge case test が必要、test cost 増加
- **Follow-up**: Python 3.13 移行時に `pathlib.PurePath.full_match` に置換 (1 関数差替えで完了)

### Decision: timeout デフォルト値 = 60 秒

- **Context**: D-6、R2.5
- **Alternatives**: 30 秒 / 60 秒 (採用) / 120 秒 / config 必須
- **Selected**: 60 秒、`.rwiki/config.yml` で上書き可能
- **Rationale**: LLM 推論典型値 5-30 秒、長尺コンテンツで 30-60 秒、95% カバー想定。Spec 4 CLI level (600 秒) との階層構造維持
- **Trade-offs**: 大規模 content (>50KB) で timeout 発生時は WARN + fallback、ユーザー上書き可
- **Follow-up**: 実運用で timeout 発生率 > 5% 観測時は再評価

### Decision: 段階 3.5 で `status: active` 事前フィルタ

- **Context**: D-7、R1.6
- **Alternatives**: candidate pool 全件で match 後に status check / `active` のみ pre-filter (採用)
- **Selected**: pre-filter
- **Rationale**: 非 active skill が複数 match に含まれると R1.7 escalate 誤発火、無駄な計算回避、R6.1 直前 check と整合
- **Trade-offs**: status 取得の disk read は SkillCatalogLoader 毎回読込前提なのでオーバーヘッド差分なし
- **Follow-up**: status 値域追加時 (Spec 7 改版) は Revalidation Trigger 該当

### Decision: dispatch 結果 5 フィールド固定

- **Context**: D-8、R7.1 / R11.4
- **Alternatives**: 3 フィールド (skill_name / input_file / dispatch_reason) + 別途 logger / 5 フィールド固定 (採用) / 拡張可能 dict
- **Selected**: 5 フィールド固定
- **Rationale**: severity / notes をフィールド化することで Spec 4 の exit code 変換 + CLI 出力整形が一括処理可能、`dispatch_reason` enumeration で機械可読性確保
- **Trade-offs**: 構造変更時 Adjacent Sync 必須 (R7.5)
- **Follow-up**: Spec 4 design 最終版での要望で他フィールド追加要請があれば Adjacent Sync 実施

### Decision: timeout 未設定を type 強制で静的防止

- **Context**: D-9、R11.5
- **Alternatives**: runtime check / type 強制 (採用) / lint rule
- **Selected**: type 強制 (`timeout: int` 必須 keyword 引数)
- **Rationale**: 実装時点で発見、CI / mypy / IDE で容易に検出
- **Trade-offs**: type hint だけでは runtime 強制ではないが、`mypy --strict` で実用上保証可能
- **Follow-up**: pyflakes / mypy CI で必須化 (Spec 4 / Spec 5 と同方針)

### Decision: CRITICAL 不発火を invariant として固定

- **Context**: D-10、R11.2
- **Alternatives**: enum に CRITICAL 含めず / 含める + 不発火 invariant (採用)
- **Selected**: 含める + 不発火 invariant
- **Rationale**: Severity enum を本 spec / 他 spec で共通化するため CRITICAL 値は保持、本 spec で発火しない invariant を test で保証
- **Trade-offs**: 将来 dispatch 範囲拡大 (vault 破損検知等) で CRITICAL 発火が必要になれば別 spec で扱う
- **Follow-up**: Severity enum を `rw_dispatch_types.py` に置くか、Spec 0 / Spec 4 の severity utility に集約するかは実装 task で決定

## Risks & Mitigations

- **R-1**: 5 段階の resolver / coordination で test ケースが膨大化 (5 stage × 各 stage 4-7 ケース ≒ 25-35 ケース) → Mitigation: stage 単位の test ファイル分割 + integration test での 5 段階短絡評価検証
- **R-2**: LLM CLI 抽象層の type 強制が runtime では保証できない (mypy なしで誤実装) → Mitigation: pyflakes / mypy CI 必須化 (Spec 4 / Spec 5 と同方針)、`call_claude()` 同等関数の代替実装が出現する都度 review
- **R-3**: glob match の自前 `**` 正規化に edge case 漏れ → Mitigation: 段階 3.5 test で `a/**/b` / `**/c` / `a/**` / `**` 単独の各パターンを網羅、Python 3.13 移行時に `full_match` 置換でリスク解消
- **R-4**: `applicable_categories` / `applicable_input_paths` の Spec 2 SSoT 変更で本 spec 段階 3.5 / 段階 4 が破綻 → Mitigation: Revalidation Trigger 該当を design.md で明示、Spec 2 改版時に Adjacent Sync 実施
- **R-5**: コンセンサス確認 UI を Spec 4 が提供する前に本 spec 実装が進むと test mock のみで実 UI 検証が遅延 → Mitigation: Spec 4 design 最終版で `ConfirmUICallback` 仕様を先行確定、本 spec test では mock 完備
- **R-6**: timeout デフォルト 60 秒が現場で短すぎる / 長すぎる事例が出る → Mitigation: `.rwiki/config.yml` 上書き機能を実装 task で確定、運用 6 ヶ月後に observation で再評価
- **R-7**: Spec 4 design line 172 dispatch 対象範囲の Adjacent Sync 訂正漏れ (本 spec design phase で発見、approve 後の工程で実施予定) → Mitigation: design.md Migration Strategy 新節 + Decision D-11 で訂正経路を明示記録、本 spec approve 工程の next action として明確化、Spec 4 design / spec.json / change log の更新を Adjacent Sync commit にまとめて実施

## References

- [consolidated-spec v0.7.13 §7.2 Spec 3](../../drafts/rwiki-v2-consolidated-spec.md#spec-3-prompt-dispatch) — line 1561-1578、本 spec の Boundary / Key Requirements
- [consolidated-spec L171 §1.2 LLM 非依存](../../drafts/rwiki-v2-consolidated-spec.md) — 「LLM 切替のための抽象層は Spec 3 で定義」明記
- [consolidated-spec §5.6 Skill ファイル frontmatter](../../drafts/rwiki-v2-consolidated-spec.md) — line 1138-1156、`applicable_categories` / `applicable_input_paths` 定義
- [Spec 1 design](../rwiki-v2-classification/design.md) — G1 (resolve_category) / G2 (`type:` field) / G3 (`categories.yml`)
- [Spec 2 design](../rwiki-v2-skill-library/design.md) — Layer 1 (SkillLibrary) / Layer 2 (SkillValidator) / §5.6 frontmatter 11 field
- [Spec 4 design](../rwiki-v2-cli-mode-unification/design.md) — R13.4 (Spec 3 dispatch 所管明示) / R2.5 (exit code) / R2.7 (Severity 統一)
- [Spec 0 Foundation design](../rwiki-v2-foundation/design.md) — §1.2 (LLM 非依存) / §6 Severity / Requirement 11
- [steering tech.md](../../steering/tech.md) — subprocess timeout / モジュール DAG 分割 / Severity 4 水準
- [steering structure.md](../../steering/structure.md) — Vault 構造 + AGENTS/skills/ 配置
- [roadmap.md「v1 から継承する技術決定」](../../steering/roadmap.md) — Severity / exit code / subprocess timeout
- [roadmap.md「Adjacent Spec Synchronization」](../../steering/roadmap.md) — 文言同期運用ルール
