# Requirements Document

## Project Description (Input)

dual-reviewer の主機能 = 設計 phase の 10 ラウンド review を adversarial subagent 構成で実行 + Chappy P0 機能 (`fatal_patterns.yaml` 強制照合 / forced divergence prompt / `impact_score`) 組込 + JSONL 構造化記録 (`impact_score` 3 軸 + B-1.0 拡張 schema 3 要素)。`dual-reviewer-foundation` の Layer 1 を活用しつつ Layer 2 design extension を実装し、Spec 6 dogfeeding で運用可能なレベルの prototype を構築する必要。

ドラフト v0.3 (`.kiro/drafts/dual-reviewer-draft.md`) §2.1 で Layer 2 design extension 仕様確定 (10 ラウンド + Phase 1 escalate 3 メタパターン)、§2.6 で Chappy P0 3 件採用確定、§2.7 で Quota 設計確定、§2.10.3 で B-1.0 拡張 schema 3 要素確定。`dual-reviewer-foundation` spec で共通 schema + Layer 1 framework + seed/fatal patterns yaml 整備予定、`dr-design` / `dr-log` skill は未実装。

本 spec は dual-reviewer の主 review 機能 = `dr-design` skill (10 ラウンド orchestration + adversarial subagent dispatch + Chappy P0 全機能) + `dr-log` skill (JSONL 構造化記録 + impact_score 3 軸 + B-1.0 拡張 schema) + Layer 2 design extension を実装し、Spec 6 dogfeeding (`dual-reviewer-dogfeeding` spec) に適用可能なレベル (sample 1 round 通過確認まで) で動作させる。Phase A scope = Rwiki repo 内 prototype 段階、subagent 構成 = 単純 dual のみ (Opus + Sonnet)。詳細は brief.md (`.kiro/specs/dual-reviewer-design-review/brief.md`) 参照。

## Introduction

dual-reviewer-design-review は dual-reviewer (LLM 設計レビュー方法論 v3 一般化 package) の Layer 2 design extension および主 review 機能を提供する。`dual-reviewer-foundation` が提供する Layer 1 framework + 共通 JSON schema + `seed_patterns.yaml` + `fatal_patterns.yaml` + `dr-init` skill を活用し、`dr-design` skill (10 ラウンド orchestration + adversarial subagent dispatch + Chappy P0 全機能 + B-1.0 拡張 schema 自己ラベリング) と `dr-log` skill (JSONL 構造化記録) を実装する。`dual-reviewer-dogfeeding` (Spec 6 適用 + 対照実験) が依存する全要素を contract として公開する。Phase A scope (Rwiki repo 内 prototype 段階) で動作し、Phase B 独立 fork は本 spec の対象外。subagent 構成 = 単純 dual のみ (primary = Opus + adversarial = Sonnet)、Claude family rotation / multi-vendor / 並列 multi-subagent / hypothesis generator role 3 体構成は別 spec 担当。

primary 参照点:

- ドラフト v0.3 = `.kiro/drafts/dual-reviewer-draft.md` §2.1 / §2.3 / §2.6 / §2.7 / §2.10 / §3 / §4
- memory = `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_review_v3_generalization_design.md` §1-14
- design phase 10 ラウンド本質 = memory `feedback_design_review.md` (中庸統合版)
- Step 1a/1b + 4 重検査 + Step 1b-v 自動深掘り = memory `feedback_review_step_redesign.md`
- 致命級 anti-pattern + Chappy P0 = ドラフト v0.3 §2.6
- 試験運用 evidence = `.kiro/methodology/dogfeeding/spec-3/round_5-10_subagent_adversarial.md` §1-8

## Boundary Context

- **In scope**:
  - `dr-design` skill (10 ラウンド orchestration + Layer 2 design extension)
  - `dr-log` skill (JSONL 構造化記録、`dual-reviewer-foundation` 共通 JSON schema 準拠)
  - Chappy P0 3 件全件実装:
    - `fatal_patterns.yaml` 強制照合 quota の発動 logic
    - forced divergence prompt template (adversarial subagent prompt の 1 行追加、文言は design phase で最終確定)
    - `impact_score` 3 軸生成・記録 logic (post-run JSONL)
  - B-1.0 拡張 schema 4 要素の LLM 自己ラベリング prompt + 記録 logic (`miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern`)
  - Layer 2 design phase 拡張 quota (Layer 1 5 種を継承 + 厳しく検証 5 種 + escalate 必須条件 5 種)
  - Step 1a/1b 分離 (軽微 / 構造的) + Step 1b-v 自動深掘り (1 回目 5 観点 + 2 回目 5 切り口、2 回目 5 番目 negative 視点強制発動)
  - Phase 1 escalate 3 メタパターン照合
  - single mode (primary reviewer のみ) / dual mode (primary + adversarial) 切替 = `dual-reviewer-dogfeeding` 対照実験用
- **Out of scope**:
  - `dual-reviewer-foundation` 担当: Layer 1 framework + 共通 JSON schema + `seed_patterns.yaml` + `seed_patterns_examples.md` + `fatal_patterns.yaml` + `dr-init` skill
  - `dual-reviewer-dogfeeding` 担当: Spec 6 (`rwiki-v2-perspective-generation`) への dual-reviewer 適用 + 対照実験 (single vs dual) + 比較 metric 抽出 + Phase B fork go/hold 判断
  - tasks / requirements / implementation phase の review 実行 (B-1.x で別 spec)
  - cycle automation (Run-Log-Analyze-Update、`dr-extract` / `dr-update`、B-1.2)
  - multi-vendor support (GPT/Gemini/etc.、B-2 以降)
  - 並列 multi-subagent + hypothesis generator role 3 体構成 (B-2 以降)
  - 並列処理 + 整合性 Round 6 task の本格実装 (現状は単純 dual の逐次運用、本格実装は B-1.x 以降)
  - B-1.x 拡張 schema 実装 (`decision_path` / `skipped_alternatives` / `bias_signal`)
  - generalization (固有名詞除去) / npm package 化 (Phase B-1.0 release prep)
  - 論文ドラフト執筆 (Phase 3 = 7-8月、別 effort)
  - dr-design / dr-log の cross-session 連携 (本 spec 範囲では同一 session 内 in-memory 渡し前提、cross-session resume は B-1.x 以降検討、ドラフト v0.3 §3.1 A-1 規範)
  - subagent prompt injection 対策 (design 文書内悪意 instruction による subagent hijack 防止) = Phase A scope では信頼できる input (Rwiki repo 内開発文書) 前提で defer、Phase B-2 multi-vendor 以降に厳密化
- **Adjacent expectations**:
  - `dual-reviewer-foundation` が以下の全要素を stable interface で公開していること: Layer 1 framework / 共通 JSON schema (`review_case` / `finding` / `impact_score` 3 軸 / `miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern`) / `seed_patterns.yaml` / `seed_patterns_examples.md` / `fatal_patterns.yaml` / `dr-init` skill (`.claude/skills/dr-init/SKILL.md` 形式)
  - `dual-reviewer-dogfeeding` が本 spec の `dr-design` / `dr-log` skill を Spec 6 design に適用し、両 skill が公開する artifact (skill SKILL.md + JSONL 出力 contract) のみを依存対象とする
  - Spec 6 (`rwiki-v2-perspective-generation`) は本 spec が直接適用しない (適用は dogfeeding spec の責務)。本 spec は Spec 6 design 内容に依存しない
  - Rwiki 既存 spec (Spec 0-7) と機能的に独立し cross-spec dependency を持たない。Phase A 期間中は Rwiki repo 内 prototype 配置のみで Rwiki spec を改変しない

## Requirements

### Requirement 1: dr-design skill による 10 ラウンド orchestration

**Objective:** dual-reviewer 利用者として、`dr-design` skill 1 つで設計 review の 10 ラウンドを完走したい。これにより、Layer 2 design extension の中核 = 10 ラウンドの全件適用 + 各ラウンドの Step A/B/C 構造駆動が単一 skill で実現され、利用者が手動でラウンド進行を制御する必要がなくなる。

#### Acceptance Criteria

1. When `dr-design` skill が起動される, the dr-design skill shall `dual-reviewer-foundation` が公開する Layer 1 framework + 共通 JSON schema + `seed_patterns.yaml` + `fatal_patterns.yaml` を起動時に全件 import / load する (各ラウンド前 lazy load は scope 外、Phase A 単純逐次運用)。If 起動時 load に失敗, then the dr-design skill shall actionable error message (どの artifact が missing / malformed か、foundation Req 6 AC 6.7 が提供する error message を利用 = foundation 側責務 = error 提供 / 本 spec 責務 = error 出力 + 起動中断) を出力し起動を fail-fast 中断する (Req 1.6 fatal error 経路と区別)
2. The dr-design skill shall 10 ラウンド (中庸統合版、ラウンド構成詳細は design phase で確定、memory `feedback_design_review.md` 規範) を全件実施する (適応的減少なし)
3. While 各ラウンド実行中, the dr-design skill shall foundation Layer 1 framework が定義する Step A → Step B → Step C の順 (primary detection → adversarial review → primary reviewer による integration) で実行する
4. When ラウンド完了時, the dr-design skill shall 当該ラウンドの finding 群を foundation 共通 JSON schema 準拠形式で `dr-log` skill に渡す
5. The dr-design skill shall ラウンド間で前ラウンドの finding を継承し累積結果を維持する (累積累計を default 形式とし、ラウンド別分離 / その他形式は design phase で確定)
6. If 10 ラウンドの途中で fatal error (subagent dispatch 失敗 / config 不正 / artifact load 失敗 等、具体 failure mode 列挙は design phase で確定) 発生, then the dr-design skill shall 部分結果を保持 (中断時点までの finding 群を dr-log 経由で JSONL に partial flush するか in-memory のみで保持するかの選択は design phase で確定、dogfeeding spec が partial 結果を観測可能であることは要件) しつつ actionable error message を出力し残ラウンドを中断する (中断後の resume は best-effort = Phase A scope では部分結果保持で OK、自動 resume は scope 外、design phase で具体方式確定。partial observability は best-effort = crash / OOM 等 severe failure 時は guarantees なし、Phase A scope 単純逐次運用前提)
7. The dr-design skill shall `.claude/skills/dr-design/SKILL.md` 形式 (foundation `dr-init` と同形式) で公開され downstream spec から `/dr-design` で起動可能である
8. If `.dual-reviewer/config.yaml` が missing / malformed (foundation `dr-init` skill 未実行 / config 破損等), then the dr-design skill shall 起動を中断し actionable error message (foundation `dr-init` 未実行 / config 修正の指示) を出力する (skill ordering precondition = `dr-init` → `dr-design` / `dr-log`)
9. The dr-design skill shall 同一 review session 内の 10 ラウンドで input 文書 (review 対象 design.md) snapshot を session 開始時点に固定する (session 中の対象文書改訂は次 session 適用時の input として反映、`dual-reviewer-dogfeeding` Req 1 AC 1 (c) の cross-mode 同一 snapshot 要請と integration、ラウンド間で同一 input を保証することで 10 ラウンドの累積結果が同 spec 同 version review 結果として valid)

### Requirement 2: adversarial subagent dispatch + single/dual mode 切替

**Objective:** dual-reviewer 利用者として、primary reviewer (Opus) と adversarial reviewer (Sonnet) を独立に起動して bias 共有を構造的に抑制したい。また、`dual-reviewer-dogfeeding` 対照実験のため single mode (primary のみ) と dual mode (primary + adversarial) の切替が可能である必要がある。

#### Acceptance Criteria

1. The dr-design skill shall primary reviewer (`primary_model`) と adversarial reviewer (`adversarial_model`) の 2 役を `.dual-reviewer/config.yaml` から決定する
2. When Step B (adversarial review) を実行する, the dr-design skill shall Claude Code 内蔵 subagent dispatch (Agent tool の `model` parameter 切替) を使用し外部 API call は実行しない (Phase A 制約 = 単純 dual のみ、Claude family rotation / multi-vendor は B-1.x / B-2 で別途)
3. While adversarial subagent 起動中, the dr-design skill shall primary reviewer の context (round 番号 / primary 検出 finding / 対象 design 文書) を strict context 分離形式で subagent prompt に渡す (multi-project 知識混入回避、ドラフト v0.3 §2.4 規範。strict context 分離の実装可能性 = Claude Code Agent tool の context isolation 挙動の technical 検証は design phase 必須、検証失敗時の代替 dispatch 機構 = 別 process spawn / 外部 API session isolation 等 = は design phase で確定。bias 共有抑制が本 spec の core objective であり、context 分離が技術的に保証されない場合は V3 試験運用 evidence の解釈再評価が必要)
4. If adversarial subagent dispatch が失敗 (rate limit / model 不在 / timeout 等、具体 failure mode 列挙と判定基準は design phase で確定), then the dr-design skill shall actionable error message を出力し当該ラウンドの fall back 挙動 (primary reviewer のみで継続 vs ラウンド中断、選択は design phase で確定) を実行する
5. Where 利用 context が single mode (adversarial subagent 無効) を要求する場合, the dr-design skill shall skill argument 経由 (具体 flag 名は design phase で確定、Phase A scope では foundation `config.yaml` schema は単純 dual 範囲で不変前提、最終 contract 確認は design phase で実施) で adversarial subagent dispatch を skip し primary reviewer 単独で 10 ラウンドを完走する (`dual-reviewer-dogfeeding` 対照実験用、ドラフト v0.3 §3.1 A-2 規範)
6. While single mode 実行中, the dr-design skill shall dual mode と同一の Layer 2 quota (Step 1a/1b + Step 1b-v + Phase 1 escalate 3 メタパターン照合 + 厳しく検証 5 種 + escalate 必須条件 5 種 + `fatal_patterns.yaml` 強制照合) を発動する (forced divergence prompt は adversarial subagent 不在のため発動 skip = `trigger_state.alternative_considered: skipped` で記録)

### Requirement 3: Layer 2 design phase 拡張 quota の発動

**Objective:** dual-reviewer 利用者として、foundation Layer 1 base quota に加え design phase 固有の拡張 quota (厳しく検証 5 種 / escalate 必須条件 5 種 / Step 1a/1b 分離 / Step 1b-v 自動深掘り / Phase 1 escalate 3 メタパターン) が各ラウンドで発動することで、設計レビューの bias 構造的抑制を Layer 1 base 以上に強化したい。

#### Acceptance Criteria

1. The dr-design skill shall foundation Layer 1 framework が定義する bias 抑制 quota 5 種 (formal challenge / 検出漏れ / Phase 1 同型探索 / `fatal_patterns.yaml` 強制照合 / forced divergence) を継承し各ラウンドで発動する
2. The dr-design skill shall 厳しく検証 5 種 (本質的観点 5 種 = a 規範範囲先取り / b 構造的不均一 / c 文書 vs 実装不整合 / d 規範前提曖昧化 / e 単純誤記 grep、memory `feedback_review_step_redesign.md` 規範) を各ラウンドで default 発動する
3. The dr-design skill shall escalate 必須条件 5 種 (具体的種別と発動 logic は design phase で確定、memory `feedback_review_step_redesign.md` 規範) を各ラウンドで照合する
4. While Step 1a (軽微指摘) 段階, the dr-design skill shall 軽微 fix のみを記録する (構造的指摘との混在禁止)
5. While Step 1b (構造的指摘) 段階, the dr-design skill shall 4 重検査 (二重逆算 + Phase 1 パターンマッチング + dev-log 23 パターン照合 (foundation `seed_patterns.yaml` 経由) + 自己診断義務、memory `feedback_review_step_redesign.md` 規範) を実行する
6. When Step 1b で深掘り判定基準 (具体基準は design phase で確定) を満たす, the dr-design skill shall Step 1b-v 自動深掘りを発動する (1 回目 = 5 観点深掘り、2 回目 = 5 切り口深掘り、2 回目の 5 番目 = negative 視点 = skim 禁止 + 強制発動義務化、memory `feedback_review_step_redesign.md` 規範)
7. If 各ラウンドで Phase 1 escalate 3 メタパターン (Spec 0 R4 / Spec 1 R5 / Spec 1 R7 の同型、ドラフト v0.3 §2.1 規範) を検出, then the dr-design skill shall escalate 必須として user 判断機会を確保する (人為的承認待機の具体形式 = blocking prompt / log 記録 + 後続 flag 等は design phase で確定)
8. When Layer 2 拡張 quota の各 quota が発動された, the dr-design skill shall 発動結果 (検出 finding / skip 理由) を `dr-log` 経由で JSONL に記録する (post-run measurement = 記録 timing は post-run、Layer 1 / Layer 2 双方とも同原則 = 発動は structural requirement で実行義務 / 記録は JSONL 書込成功時のみ反映 / 書込失敗時の発動事実は metrics 不可扱い、Goodhart's Law 回避のため pre-run target setting は実装しない、ドラフト v0.3 §2.7 規範)

### Requirement 4: Chappy P0 機能の組込発動

**Objective:** dual-reviewer 利用者として、Chappy review で P0 採用された 3 機能 (`fatal_patterns.yaml` 強制照合 / forced divergence prompt / `impact_score` 3 軸) が design review 中に発動・記録され、致命級漏れと bias 共有疑念に対する構造的抑制が確保される。

#### Acceptance Criteria

1. The dr-design skill shall foundation 同梱 `fatal_patterns.yaml` (致命級 8 種固定 = sandbox escape / data loss / privilege escalation / infinite retry / deadlock / path traversal / secret leakage / destructive migration) を各ラウンドで強制照合する (foundation Layer 1 base quota の 1 種 = `fatal_patterns.yaml` 強制照合、具体発動 logic は Layer 2 design extension の責務、Chappy P0 課題 6 採用、ドラフト v0.3 §2.6 規範)
2. While Step B (adversarial subagent prompt) 構成中, the dr-design skill shall forced divergence prompt template (1 行、文言は design phase で最終確定、素案 = "primary reviewer の暗黙前提を 1 つ identify し、別の妥当な代替前提に置換した場合に同じ結論が成立するか評価せよ"、Chappy P0 課題 5 採用) を含めて adversarial subagent に渡す
3. When 各 finding 生成時, the dr-design skill shall `impact_score` 3 軸 (severity / fix_cost / downstream_effect) を生成し finding に付与する (Chappy P0 課題 7 採用、ドラフト v0.3 §2.6 規範)
4. The impact_score shall foundation 共通 JSON schema (severity = CRITICAL / ERROR / WARN / INFO の 4 値 enum、fix_cost / downstream_effect は有限値 enum) に準拠する
5. If 強制照合で `fatal_patterns.yaml` 該当を検出, then the dr-design skill shall 当該 finding の severity を CRITICAL として `impact_score` に記録する
6. The dr-design skill shall Layer 1 base quota の `fatal_patterns.yaml` 強制照合 と forced divergence をいずれも post-run measurement only で metrics 記録する (pre-run target setting は Goodhart's Law 回避で禁止、各ラウンドの強制照合発動自体は structural requirement として実行義務、ドラフト v0.3 §2.6 / §2.7 規範)
7. The dr-design skill shall primary prompt + adversarial subagent prompt を英語固定 1 本で構成し、subagent 出力 (finding 説明) は対象 design 文書の言語 auto-detect で生成する (本 spec scope = ja document auto-detect、ドラフト v0.3 §4.4 規範)

### Requirement 5: dr-log skill による JSONL 構造化記録

**Objective:** dual-reviewer 利用者として、`dr-log` skill が review session の全 finding と review_case を JSONL 構造化形式で記録し、論文用 quantitative evidence (figure 1-3) と analyze cycle (Run-Log-Analyze-Update) の入力データを構築する。

#### Acceptance Criteria

1. The dr-log skill shall foundation 共通 JSON schema (`review_case` / `finding` / `impact_score` / `miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern`) に準拠した JSONL output を生成する
2. When `dr-design` 各ラウンド完了時, the dr-log skill shall ラウンド単位の `review_case` レコード (1 JSONL line) と配下の `finding` レコード群 (各 1 JSONL line / finding、フラット構造) を JSONL に append する (review_case の `primary_findings` / `adversarial_findings` field は finding ID 配列で紐付け、foundation Req 3 AC 3.1 の field 値型明確化は波及精査対象)
3. The dr-log skill shall JSONL 出力先 path を Layer 3 (project 固有) ディレクトリ配下 (foundation `dr-init` skill が生成した `dev_log/` 等) として `.dual-reviewer/config.yaml` から決定し、`dual-reviewer-dogfeeding` 対照実験用に single mode / dual mode の 2 系統 JSONL を出力先 path で分離する (具体 naming convention 例: `dev_log/single_${timestamp}.jsonl` / `dev_log/dual_${timestamp}.jsonl`、最終確定は design phase、skill argument 経由 single/dual mode flag に対応)
4. If JSONL 書込に失敗 (disk full / 権限不足 / 不正 path 等、具体 failure mode 列挙は design phase で確定), then the dr-log skill shall actionable error message を出力し partial 書込を残さない原則を best-effort で適用する (atomic 書込 = temp file + rename 等の方式は design phase で確定、SIGKILL / OOM 等 severe interrupt 時は guarantees なし、append-only JSONL との整合 = ラウンド境界 atomic batch flush で解決、SIGINT / SIGTERM 中断 signal 取扱は design phase で確定)
5. The dr-log skill shall foundation 共通 JSON schema を validator (jsonschema 等、具体実装は design phase で確定) で出力前検証する (検証失敗時の挙動 = abort / warn-and-continue の選択は design phase で確定)
6. The dr-log skill shall single mode と dual mode の両方で同一 schema の JSONL を生成する (`dual-reviewer-dogfeeding` 対照実験で両系統が比較可能、ドラフト v0.3 §3.1 A-2 規範)
7. The dr-log skill shall `.claude/skills/dr-log/SKILL.md` 形式 (foundation `dr-init` と同形式) で公開され downstream spec から起動可能である
8. When Step C (integration) で primary reviewer が integration 結果を生成する, the dr-log skill shall foundation Req 3 AC 3.1 の `review_case.integration_result` field に populate する (Step C output → dr-log への引渡 contract、foundation 共通 JSON schema 整合)
9. When `dr-design` 中断後 resume または同一 session 内で再起動時, the dr-log skill shall JSONL 重複 record 防止戦略 (review_case ID + round 番号 dedup / append-only で post-run analyze 時 dedup 等の選択は design phase で確定) を実装する (cross-session resume は Boundary Context Out 整合)
10. While Phase A scope 範囲内, the dr-log skill shall single mode JSONL と dual mode JSONL の concurrent write を前提しない (逐次実行のみ、`dual-reviewer-dogfeeding` 対照実験は逐次 cost 倍で運用、ドラフト v0.3 §3.1 A-2 規範)

### Requirement 6: B-1.0 拡張 schema の LLM 自己ラベリング

**Objective:** 論文化 evidence 取得目的で、各 finding と review_case に `miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern` を LLM が自己ラベリングし、JSONL に記録する。これにより論文 figure 1-3 (`miss_type` 分布 / `difference_type` 分布 / trigger 発動率) + Phase 1 同型 hit rate (`dual-reviewer-dogfeeding` Req 4 AC 3 経由) の quantitative data が蓄積される。

#### Acceptance Criteria

1. When primary reviewer が finding を生成する, the dr-design skill shall finding に `miss_type` (foundation 定義 6 値 enum: implicit_assumption / boundary_leakage / spec_implementation_gap / failure_mode_missing / security_oversight / consistency_overconfidence) を LLM 自己ラベリングで付与する
2. When adversarial subagent が独立追加した finding を生成する, the dr-design skill shall finding に `difference_type` (foundation 定義 6 値 enum: assumption_shift / perspective_divergence / constraint_activation / scope_expansion / adversarial_trigger / reasoning_depth) を LLM 自己ラベリングで付与する
3. When 各ラウンド (review_case) 完了時, the dr-design skill shall `trigger_state` (foundation 定義 3 軸 enum object: negative_check / escalate_check / alternative_considered、各 applied | skipped の 2 値 enum) を LLM 自己診断で生成する (foundation Req 3 AC 3.1 で trigger_state = review_case の実行制御状態として定義、本 spec では同 data を論文化 figure 3 = trigger 発動率の観測フラグとしても使用、両 semantic は同一 data の異なる用途、ドラフト v0.3 §2.10.3 規範。LLM 自己ラベリング信頼性 = aggregate 統計信頼性は確保、`trigger_state.skipped` の意図的 skip vs 記録漏れ識別不能を含み個別精度は完全信頼不可、論文 limitation 節で扱う)
4. The dr-design skill shall LLM 自己ラベリング prompt (各 enum 候補と判定基準) を primary prompt + adversarial subagent prompt の双方で同 schema で要請する
5. The dr-log skill shall 上記 self-labeled enum を JSONL の対応 field に書き込む (foundation 共通 JSON schema 準拠)
6. While single mode 実行中, the dr-design skill shall finding output JSONL から `difference_type` field を **absent** とする (foundation Req 3 AC 3.2 で `difference_type` を optional field 化することを前提、波及精査対象。`miss_type` + `trigger_state` は同 schema で自己ラベリングし、`trigger_state.alternative_considered: skipped` で adversarial 不在を記録、ドラフト v0.3 §3.1 A-2 + dogfeeding brief Approach 規範 = single でも自己ラベリング、dual との差を absent / present の binary 識別で可視化)
7. The dr-design skill shall 自己ラベリング失敗 (enum 範囲外 / parse 失敗等) 時の fallback ownership を保持し dr-log に渡す前段で fallback 値付与を完了させる (dr-log skill 側は受領値を schema validate に通すのみ、default value / re-prompt / log warning の選択は design phase で確定。LLM 自己ラベリングの aggregate 統計信頼性は確保するが個別精度は完全信頼不可、ドラフト v0.3 §2.10.3 規範)
8. When primary または adversarial reviewer が Phase 1 escalate 3 メタパターン (Spec 0 R4 / Spec 1 R5 / Spec 1 R7 同型) に該当する finding を生成する, the dr-design skill shall finding に `phase1_meta_pattern` (foundation Req 3 AC 3.10 定義 = norm_range_preemption / doc_impl_inconsistency / norm_premise_ambiguity の 3 値 enum) を LLM 自己ラベリングで付与する (escalate 検出 finding にのみ付与、その他 finding は absent / null、`dual-reviewer-dogfeeding` Req 4 AC 3 の Phase 1 同型 hit rate 抽出と連鎖、Req 3 AC 3.7 escalate 必須条件と integration)

### Requirement 7: Downstream spec 提供 contract

**Objective:** `dual-reviewer-dogfeeding` 開発者として、本 spec が提供する全要素 (`dr-design` skill / `dr-log` skill / Chappy P0 全機能 / B-1.0 拡張 schema 自己ラベリング機能 / single+dual mode 切替) を一貫した interface で利用したい。これにより dogfeeding spec が依存解決を機械的に行え、本 spec の internal 実装詳細を知らずに済む。

#### Acceptance Criteria

1. The dual-reviewer-design-review shall `dr-design` skill を `.claude/skills/dr-design/SKILL.md` 形式で公開する
2. The dual-reviewer-design-review shall `dr-log` skill を `.claude/skills/dr-log/SKILL.md` 形式で公開する
3. The dual-reviewer-design-review shall sample design 文書 1 件に対する 1 ラウンド通過確認 (sample 入力と通過判定基準は design phase で確定) を完了し、prototype 動作 evidence を残す
4. While sample 1 round 通過確認実行中, the dual-reviewer-design-review shall primary + adversarial の dual-reviewer 構成 + Chappy P0 3 件 (`fatal_patterns.yaml` 強制照合 / forced divergence prompt / `impact_score` 3 軸) + B-1.0 拡張 schema 自己ラベリング (`miss_type` / `difference_type` / `trigger_state` / `phase1_meta_pattern`) + JSONL 記録を全て発動する
5. When sample 1 round 完走時, the dual-reviewer-design-review shall sample 出力 JSONL が foundation 共通 JSON schema validator で検証 pass することを示す (Req 5 AC 5.5 で規定する dr-log skill の動作要件を sample 1 round 通過確認の evidence として実証)
6. Where dogfeeding spec が `dr-design` / `dr-log` を invoke する場合, the dual-reviewer-design-review shall internal 実装詳細を露出せず loadable artifact (skill SKILL.md + skill argument 経由 single/dual mode 切替 + JSONL 出力 contract + foundation 提供 `config.yaml` の `primary_model` / `adversarial_model` / `language` 利用) のみ提供する (foundation `config.yaml` schema 拡張は不要、encapsulation 検証基準は design phase で確定)
7. If dogfeeding spec が prototype 起動に失敗, then the dual-reviewer-design-review shall actionable error message (どの skill / config / foundation artifact が missing / malformed か) を提供する (具体 error 提供 agent = dr-design skill / dr-log skill / config validator のいずれか、は design phase で確定)
