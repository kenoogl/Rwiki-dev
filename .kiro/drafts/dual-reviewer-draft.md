# dual-reviewer 仕様検討ドラフト

_v0.3 / 2026-04-29 / dual-reviewer-foundation requirements 5 ラウンドレビュー (V3 adversarial subagent 統合) 反映 = 固有名詞ゼロ削除 + trigger_state 表記精度 + 3 spec 分割反映_

dual-reviewer (設計レビュー方法論 v3 一般化 package) の仕様検討ドラフト。spec 策定 (A-0、`/kiro-spec-init` 〜 `tasks.md` approve) における参照点として、これまでの議論で確定した内容を集約。

参照優先度: 本ドラフト > memory §1-13 > 試験運用報告書 §8 > dev-log。本ドラフトは memory §1-13 + Chappy review 反映 + Phase A 細分化判断を統合した自己完結ドキュメント。

---

## §1 概要

### 1.1 Purpose

設計レビューの方法論 v3 (旧 10 ラウンド + adversarial subagent 統合) を Rwiki 開発から独立した汎用 npm package に一般化。LLM 主体 + adversarial subagent の dual-reviewer 構成で、bias 共有疑念に対する反証 evidence を蓄積しつつ、致命級発見率 / disagreement 率 / impact_score 分布で品質評価可能なレビューシステムを提供する。

### 1.2 Target user

- cc-sdd を運用する spec-driven development practitioner
- Claude Code user (subagent 機能を活用する開発者)
- 将来的には multi-vendor (GPT/Gemini/etc.) 対応で広範な agentic SDLC user

### 1.3 Target output

- npm package `dual-reviewer` (`npx dual-reviewer@latest`)
- GitHub repo (cc-sdd と同方式で公開)
- skills (`dr-*` 接頭辞、design / tasks / requirements / impl + framework 補助 init/log/extract/validate/update/translate)
- 同梱 seed: `seed_patterns.yaml` (Rwiki 由来 23 事例 + Phase A dogfeeding 蓄積) / `fatal_patterns.yaml` (致命級 8 種)

### 1.4 試験運用 evidence (確立済)

Rwiki Spec 3 design Round 5-10 で adversarial subagent 試験運用 6 回。subagent 追加発見 23 件 (致命級 1 + 重要級 13 + 軽微 9)、disagreement 2/24、Phase 1 同型 3 種全該当 2 度達成 = bias 共有疑念に対する決定的反証。詳細 = `.kiro/methodology/dogfeeding/spec-3/round_5-10_subagent_adversarial.md` §1-7。

---

## §2 設計判断 (memory §2-12 + Chappy review 反映)

### 2.1 Layer 構造 (memory §2)

- **Layer 1 (phase 横断 framework、portable)**:
  - Step A/B/C 構造 (primary detection → adversarial review → integration)
  - bias 抑制 quota (formal challenge + 検出漏れ + Phase 1 同型探索)
  - pattern schema (中程度 granularity + primary_group + secondary_groups 二層)
  - 介入 framework (Quota event-triggered のみ、Tier 比率は post-run measurement only)
  - dr-* script 群 (init / log / extract / validate / update / translate)
  - **Chappy P0 採用**: `fatal_patterns.yaml` 強制照合 (8 種固定) / forced divergence prompt (1 行追加)
- **Layer 2 (phase 別 extension)**:
  - `requirements_extension.md` (5 ラウンド + R-1〜R-4 quota)
  - `design_extension.md` (10 ラウンド、現行 v3、Phase 1 escalate 3 メタパターン)
  - `tasks_extension.md` (10 ラウンド task 視点、boundary / dependency quota)
  - `implementation_extension.md` (PR-based、test cover / regression quota)
- **Layer 3 (project 固有)**:
  - `extracted_patterns.yaml` (project の cycle 蓄積)
  - terminology entries (project 固有用語)
  - dev-log JSONL (project の log archive)
  - tier 実測値 (project の measurement)

### 2.2 Run-Log-Analyze-Update cycle (memory §4)

```
[Run] dual-reviewer 運用 (Layer 1 + Layer 2 + Layer 3)
   ↓
[Log] review session log を JSONL 記録 (dr-log)
   ↓
[Analyze] 事後分析で pattern 抽出 (dr-extract subagent task) + schema validate (dr-validate)
   ↓
[Update] 抽出データを feedback (dr-update が PR 生成、人間 PR review style apply)
   ↓ (loop back to Run)
```

cycle 周期 = user 依存 (config 化なし、自動化が必要になった時点で再検討)。

### 2.3 並列処理 + 整合性 Round (memory §6)

- **並列**: Round 1-10 完全並列 (read-only snapshot、各 ~150s × 並列 = wall-clock ~5-10 分)
- **整合性 Round** (primary reviewer = Opus 逐次、6 task):
  1. Deduplicate
  2. Detect dependencies
  3. Detect conflicts
  4. Topologically sort
  5. Predict derived issues
  6. Severity re-evaluation
- **派生 Round 再実行**: 上限 3 回、件数上限なし、Spec 3 evidence で 95%+ 収束
- **完全逐次 fall back** (現行 v3 方式): 並列成果保持 + 既適用 Edit 維持
- **wall-clock**: 典型 50-100 分 (現状 v3 = 3-4 時間 → 2-4x 短縮)
- **token cost**: 典型 +10-15%、worst case (fall back) +100-150%
- **fall back trigger 5 条件**: 派生上限 / 循環依存 / 判定不能多数 / user 手動 / LLM 失敗

### 2.4 multi-project bias 対策 (memory §7)

- 同モデル偏向 (training 由来) → 完全 mitigation 不可、bias 抑制 quota + subagent 再帰多重化
- project 知識混入 (用語) → `terminology.yaml` で抽象化、contribution review で固有用語 regex 検出
- collective contribution noise → maintainer review (quality gate)、Phase B-2 以降詳細化
- multi-project user memory 混入 → core/seed 共有 + project 完全分離 + subagent prompt で strict context 分離明示

### 2.5 subagent 再帰多重化 (memory §8)

subagent 構成段階 (release lifecycle と同期):

- **B-1** (release 直後 = release lifecycle B-1.0/B-1.x):
  - 現行 v3 (単純 dual = Opus + Sonnet) + 案 C1 (Claude family rotation: Sonnet/Opus/Haiku) opt-in
  - API コール不要 (Claude Code Agent tool の `model` parameter 切替)
- **B-2** (~6-12 ヶ月):
  - 案 A (並列 multi-subagent) + 案 C2 (multi-vendor: GPT/Gemini/etc.) opt-in 試験
  - C2 = 必要 (Bash + Python SDK で外部 API、API key 管理 + `.env` + git-secrets)
- **B-3** (~1-2 年):
  - 統計に基づき default 化
  - 案 A + C2 組合せで bias diversity 最大化、案 B (階層的) は experimental

dispute resolution = `majority_vote` default、必要に応じて `escalate_to_user` (Tier 1 介入)。

**用語衝突注記**: subagent 構成段階の B-1/B-2/B-3 と release lifecycle の B-1.x は同期 (B-1.x 内で subagent 構成 B-1 完成、release B-2 で subagent 構成 B-2 移行)。混同を避けるため文脈で明示。

### 2.6 Chappy review (2026-04-29) 反映 (memory §12)

Chappy 11 課題 + 優先度 P0-P3 を再検討、以下を確定:

#### 採用 (Phase A MVP 組込) — 3 件

1. **致命パターン構造化** (Chappy 課題 6, P0):
   - Layer 1 framework に `fatal_patterns.yaml` 追加 (initial 8 種固定: sandbox escape / data loss / privilege escalation / infinite retry / deadlock / path traversal / secret leakage / destructive migration)
   - 各 Round で強制照合 quota 化、bias 抑制 quota と同列扱い
   - 採用根拠: 23 事例 (`seed_patterns.yaml`) は中程度 granularity で致命級だけのレイヤ未提供、価値高 + コスト低
2. **impact_score** (Chappy 課題 7, P0):
   - 既存 severity (CRITICAL/ERROR/WARN/INFO) を 3 軸 (severity / fix_cost / downstream_effect) に拡張
   - post-run JSONL schema (dr-log) に追加、analysis 用 metric
   - 採用根拠: 件数 metric では「事故防止価値」が見えず ROI 説明力が弱い
3. **forced divergence** (Chappy 課題 5、P1 → P0 格上げ):
   - adversarial subagent prompt template に 1 行追加
   - 文言案 (微調整版): 「primary reviewer の暗黙前提を 1 つ identify し、別の妥当な代替前提に置換した場合に同じ結論が成立するか評価せよ」
   - 採用根拠: Spec 3 disagreement 2/24 は bias 共有疑念への反証と総括したが「収束しすぎ警告」という別解釈も妥当 = 直接対策。コスト極低 (prompt 1 行)

#### 保留 (Phase B-2 以降検討) — 3 件

1. **hypothesis generator role 3 体構成** (Chappy 課題 4):
   - 配置: Phase B-2 並列 multi-subagent (§2.5) と統合検討
   - 役割: 「設計が満たしていない隠れ要件を推定」「failure シナリオ生成」
   - 保留根拠: MVP には不要、Phase B-2 multi-vendor 試験と同時導入が効率的
2. **意味レビュー層** (Chappy 課題 11):
   - 配置: Phase C 以降 (Chappy P3 と一致)
   - 関連: requirements_extension R-1 (user 意図確認) が部分カバー
   - 保留根拠: 規模大 (intent → requirement → design 関手チェック)、研究テーマ性
3. **Layer 境界明確化** (Chappy 課題 9):
   - 圏論的整理 (モルフィズム / ファンクタ / オブジェクト) は overengineering、却下
   - 代替: 実装用語 (transformer / specialization / instance) で境界明示、Phase A 文書化作業に含める
   - 保留根拠: 概念整理は価値あるが実装直結性が低い

#### 却下 (恒久的除外、再提案抑止) — 3 件

将来 conversation で再提案された際の re-derive を抑止するため、根拠を明記。

1. **リスク駆動 Adaptive Rounds** (Chappy 課題 1):
   - 却下根拠: Tier 比率 pre-run target setting を **Goodhart's Law 回避** で意図的削除済 = 同根拠で「リスクスコア事前重み付け」も LLM の pre-run target 化 = 自己充足的 bias を生む。confirmation loop に陥る
   - 代替実装: post-run severity_re_evaluation (整合性 Round 6 task の 6 番目) が事後に重み付け = 同等効果を bias なしで実現
2. **escalate 確率モデル化 (P(escalate|context) > θ)** (Chappy 課題 3):
   - 却下根拠: cycle (Run-Log-Analyze-Update) で経験則更新は組込済。確率モデル化は LLM が「閾値以下なら escalate しない」という新たな bias 源 = 修正されにくい指摘 (controversial だが致命的) を escalate しない方向に学習が偏る
   - 代替実装: 5 条件は静的だが human escalate 必須 = bias 学習を排除しつつ知見蓄積は cycle で対応
3. **並列レビュー収束関数 (Δ monotonic decrease)** (Chappy 課題 10):
   - 却下根拠: 派生 Round 再実行上限 3 回 + fall back trigger 5 条件 + Spec 3 evidence 95%+ 収束 = 経験的に対応済。数学的保証 (monotonic decrease) は理想だが「unresolved_issues + conflicts」を関数化する際の定義 (どれが unresolved か) 自体が判定不能多数を含む = 自己参照ループ
   - 将来余地: Phase C 以降に formal verification 候補

### 2.7 Quota 設計 (memory §9)

- **Tier 比率**: pre-run target setting 削除 (Goodhart's Law 回避)、post-run measurement only (実測 JSONL 記録、analysis 用)
- **Quota** (event-triggered 介入の核、phase 別 extension で拡張):
  - design phase: formal challenge / 検出漏れ / Phase 1 同型探索 / 厳しく検証 5 種 / escalate 必須条件 5 種 / **`fatal_patterns.yaml` 強制照合 (Chappy P0)** / **forced divergence (Chappy P0)**
  - requirements phase: R-1 (user 意図確認) / R-2 (domain 不在 escalate) / R-3 (stakeholder mapping) / R-4 (scope creep 検出)
  - tasks phase: boundary 違反 / dependency cycle / granularity quota
  - implementation phase: test coverage gap / regression risk quota

### 2.8 用語抽象化 + 多言語 policy (memory §10)

- **role 用語**: primary reviewer / adversarial reviewer (Opus / Sonnet 名は config `primary_model` / `adversarial_model` で抽象化、将来 model 切替対応)
- **section 見出し**: bilingual 併記 (project 言語 + 英語ラベル)
- **schema field**: 構造ラベル英語固定 (transferable)、自由記述は project 言語 (user readability)
- **pattern 翻訳**: transfer 時 LLM 翻訳、`terminology.yaml` で用語 mapping 統一

### 2.9 23 事例 + collective learning network (memory §5)

- **23 事例** (Rwiki dev-log 由来) = `seed_patterns.yaml` (Rwiki 固有名詞付きで OK、`origin: rwiki-v2-dev-log`) として package 同梱、immutable initial knowledge (generalization は Phase B-1.0 release prep の責務)
- **具体例**: 別 markdown (`seed_patterns_examples.md`、人間可読、同梱)
- **transfer 戦略**: 16 representative を subagent prompt embed + 全 archive は別 grep
- **`terminology.yaml`**: Phase A 蓄積開始 (review_methodology 用語 30-50 entries)、Phase B 以降で seed 化
- **collective learning network** (Phase B-2 以降): GitHub PR で contribution、maintainer review で quality gate、`seed_patterns.yaml` が育つ → 全 user に配布
- **domain tag**: 削除 (8 メタ群 + 中程度 granularity で domain 横断、固有性は concrete レベルのみ)

### 2.10 論文化軸 + 拡張ログ schema (2026-04-29 後段議論、`docs/ログサンプル.md` 反映)

#### 2.10.1 dual-reviewer の二重位置付け

dual-reviewer は **二重の位置付け** で進める:

- **位置付け 1 (主軸、プロダクト価値)**: 設計レビュー方法論パッケージ = 開発品質向上のための実用ツール
- **位置付け 2 (副産物、研究価値)**: **LLM レビューバイアスの観測装置** = 内省困難な LLM の構造的 failure を可視化する実験装置

論文化方針: **プロダクトが主、論文は副産物** (user 軸)。論文化のため別実験を組まず、日々の開発をそのまま実験化 (二重ループ構造):

- 開発ループ (主目的): 設計 → dual-review → 修正 → 実装
- 研究ループ (裏で回す): ログ収集 → パターン抽出 → バイアス分析 → 論文化

→ 同じ JSONL log を両方で使う = 開発と論文の同時前進。論文 timing = 8 月ドラフト提出。

#### 2.10.2 主張のアップグレード版

- 旧主張: dual-reviewer 方法論が単一 LLM レビューより優れる
- 新主張: **「LLM は批判的推論フレームワークを知識として保持していても、それを自己推論に適用する機構を持たないため、構造的な見落としが発生する」** → 「外部化された adversarial 構造が必要」
- 言い換え: LLM の問題は知識不足や推論能力不足ではなく、**制御フローの欠如**。dual-reviewer = 制御フローを外付けする装置
- LLM を「賢くする」研究ではなく「**壊れにくくする**」研究

#### 2.10.3 拡張ログ schema (B-1.0 採用 3 要素 + B-1.x 採用 3 要素)

これまでの dr-log JSONL = `impact_score` 3 軸 (severity / fix_cost / downstream_effect、Chappy P0) = 「結果の質」軸。論文化のため **「失敗構造の観測」軸** を追加。impact_score とは直交。

##### B-1.0 採用 3 要素 (軽量 enum / boolean、B-1.0 minimum 同梱)

**要素 1: `miss_type`** (finding ごとのラベル、6 種 enum):

- `implicit_assumption` — 暗黙前提依存
- `boundary_leakage` — 責務境界漏れ (Rwiki で頻出、例: Spec 3 が Spec 4 の責務決定)
- `spec_implementation_gap` — 仕様と実装の乖離
- `failure_mode_missing` — 失敗モード欠落 (retry / rollback / timeout 未定義)
- `security_oversight` — セキュリティ見落とし (symlink / prompt injection / PATH hijack、Spec 3 致命例)
- `consistency_overconfidence` — 一貫性過信 (局所整合に満足、グローバル矛盾を見逃す) **← 論文核心**

論文 figure 1 候補: miss_type 分布 = 「LLM はこの 6 タイプを見落とす」一般化。

**要素 2: `difference_type`** (adversarial 拾い分のラベル、6 種 enum):

- `assumption_shift` — 前提変更 (失敗ケース仮定) **← adversarial 本質**
- `perspective_divergence` — 視点の違い (primary 整合性 vs adversarial 攻撃者視点)
- `constraint_activation` — 制約の顕在化 (メモリ / 実行環境制約の明示)
- `scope_expansion` — スコープ拡張 (cross-spec 検証)
- `adversarial_trigger` — 攻撃的発想 (injection, misuse)
- `reasoning_depth` — 推論深度 (failure シナリオ多段展開)

論文 figure 2 候補: difference_type 分布 + forced divergence (Chappy P0) 効果評価 = 「どの difference_type が forced divergence で増えたか」。

**要素 3: `trigger_state`** (review_case ごとのフラグ、3 軸 enum object 各 applied | skipped の 2 値 enum) **← 論文核心**:

- `negative_check: applied | skipped` — Step 1b-v Negative 視点 5 切り口が発動したか
- `escalate_check: applied | skipped` — escalate 必須条件 5 種を確認したか
- `alternative_considered: applied | skipped` — 代替案を検討したか

論文 figure 3 候補: trigger 発動率 (skipped 頻出 = 「ルールはあるが発動しない構造的問題」の定量化、論文核心 evidence)。

リスク: LLM 自己診断の信頼性 (skipped を skipped と認識できるか)。aggregate 統計として意味あり、個別精度は完全信頼不可。

**要素 4: `phase1_meta_pattern`** (Phase 1 escalate 同型識別、3 値 enum + null、cross-spec contract 補強 field):

- `norm_range_preemption` (Spec 0 R4 同型 = 規範範囲先取り)
- `doc_impl_inconsistency` (Spec 1 R5 同型 = 文書 vs 実装不整合)
- `norm_premise_ambiguity` (Spec 1 R7 同型 = 規範前提曖昧化)
- `null` (escalate 非該当)

escalate 検出 finding にのみ付与、`dual-reviewer-dogfeeding` Req 4 AC 3 の Phase 1 同型 hit rate 抽出 + Req 4 AC 8 (c) bias 共有反証 evidence 構成要素として再利用。要素 1-3 (B-1.0 採用 3 要素 = 失敗構造観測軸) とは別軸 (Phase 1 escalate 同型識別による cross-spec 学習継承軸) として位置付け、4 要素目として B-1.0 minimum 同梱 (foundation Req 3 AC 10 / design-review Req 6 AC 8 / dogfeeding Req 4 AC 3 連鎖)。

##### B-1.x 採用 3 要素 (自由記述 + 内省、B-1.x で段階追加)

**要素 4: `decision_path`** (B-1.x 追加、思考分岐軌跡):

- 形式: 自由記述 list (例: `["Spec 4 inconsistency detected", "Assumed typo", "Proposed fix immediately"]`)
- 論文用途: figure 4 候補「failure pipeline」(Spec 3 self-diagnosis ログを 1 図化)
- B-1.x 回し理由: B-1.0 trigger_state で trigger failure 検出は十分、decision_path は深掘り段階で必要

**要素 5: `skipped_alternatives`** (B-1.x 追加、考えなかった代替案):

- 形式: 自由記述 list (例: `["Spec 3 design not generated yet", "Should defer to later phase"]`)
- 論文用途: 直接 evidence (qualitative)
- B-1.x 回し理由: 「skipped を skipped と気づくこと自体が認識能力」 = LLM 自己ラベリング最難関、後段 adversarial subagent に「primary が考えなかった代替案を列挙せよ」と問い直す形式が現実的 = subagent 側のタスク化必要

**要素 6: `bias_signal`** (B-1.x 追加、bias パターンタグ):

- 形式: 事前定義 enum (例: `premature_fix` / `assumption_lock` / `no_negative_pass`、5-10 種)
- 論文用途: figure 5 候補 (bias パターン aggregate 頻度図)
- B-1.x 回し理由: bias タグの初期セットを Phase A dogfeeding データから経験的抽出する方が合理的、最初から固定すると Rwiki 文脈の bias を取り逃がす

##### B-1.0 vs B-1.x 切り分け根拠 (3 点)

1. LLM 自己ラベリング難易度: B-1.0 (enum / boolean = 認知負荷低) vs B-1.x (自由記述 + 内省 = 認知負荷高)
2. 論文 evidence 階層: B-1.0 で quantitative evidence 揃う (figure 1-3) → B-1.x は qualitative evidence 強化 (figure 4-5)
3. 8 月 timeline: Phase 2 (6-7月、A-2) で B-1.0 + 対照実験で quantitative 揃う → Phase 3 (7-8月) で B-1.x 追加 + case study 強化

---

## §3 開発計画 (memory §1 + §13)

### 3.1 Phase A 細分化 (A-0/A-1/A-2)

#### A-0 (spec 策定、3 spec 分割)

- 配置: `.kiro/specs/dual-reviewer-foundation/` + `.kiro/specs/dual-reviewer-design-review/` + `.kiro/specs/dual-reviewer-dogfeeding/` (TODO_NEXT_SESSION.md 確定事項 1 で 3 spec 分割確定、依存階層: foundation → design-review → dogfeeding)
- 内容 (3 spec 並走):
  1. 各 spec で `/kiro-spec-init {feature}` で `brief.md` + `spec.json` 生成 (T 案 = kiro-discovery skip + 手動 brief.md、roadmap 汚染回避)
  2. 各 spec の `requirements.md` 策定 (memory §1-14 + Chappy P0 3 件を AC 化)
  3. 各 spec の `design.md` 策定 (memory §1-14 確定事項を design 詳細化)
  4. 各 spec の `tasks.md` 策定:
     - foundation = Layer 1 framework + dr-init skill + 共通 JSON schema + seed/fatal patterns yaml
     - design-review = dr-design + dr-log skill (Layer 2 design extension + Chappy P0 全機能 + B-1.0 拡張 schema)
     - dogfeeding = Spec 6 適用 + 対照実験 (single vs dual)
- 終端条件: 3 spec すべての `tasks.md` approve
- 期間目安: 数日 〜 1 週間
- Spec 6 = A-0 中は触らない (A-2 dogfeeding で再開、ペンディング維持)

#### A-1 (prototype 実装)

- 配置: `scripts/dual_reviewer_prototype/` または `.kiro/specs/dual-reviewer/prototype/`
- 範囲: B-1.0 minimum 相当 = 3 skills (`dr-init` + `dr-design` + `dr-log`)
- 必須同梱: Chappy P0 3 件 (`fatal_patterns.yaml` 8 種 / impact_score 3 軸 / forced divergence prompt)
- 23 事例 retrofit (`seed_patterns.yaml`、Rwiki 固有名詞付きで OK、generalization は B-1.0 release prep)
- `terminology.yaml` seed 開始 (entries 蓄積は A-2 で、目標 30-50 は B-1.2 まで延伸)
- 終端条件: prototype が Spec 6 design に適用可能なレベルで動作確認 (sample 1 round 通過)
- 期間目安: 1-2 週間
- Spec 6 = 触らない (ペンディング維持)

#### A-2 (Spec 6 dogfeeding)

- prototype を Spec 6 (rwiki-v2-perspective-generation) design に適用、Round 1-10 完走 + **全 Round で single (Opus のみ) + dual の対照実験 (cost 倍、論文用比較データ、§2.10.3 + §3.5 参照)**
- 試験運用 metrics 取得:
  - 致命級発見再現性 (Spec 3 = 1 件、Spec 6 で 1 件以上で go)
  - disagreement 率 (Spec 3 = 2/24、forced divergence で増加するか)
  - Phase 1 同型 hit rate (Spec 3 = 3 種全該当 2 度)
  - impact_score 分布 (件数中心 metric から脱却できているか)
  - `fatal_patterns.yaml` 強制照合効果 (致命級漏れ防止)
- Phase B fork go/hold 判断基準:
  - 致命級発見 ≥ 2 件 (Spec 3 = 1 件 + Spec 6 で 1 件以上)
  - disagreement ≥ 3 件 (Spec 3 = 2 件 + Spec 6 で 1 件以上、forced divergence 効果含む)
  - bias 共有反証 evidence 確実
  - impact_score 分布が minor のみではない
- 終端条件: dual-reviewer 適用 review evidence 提供 + Phase B fork go/hold 判断 + Spec 6 design approve = A-2 期間終端時期一致で並走後同時宣言 (session 内 simultaneous approve ではなく、approve 操作は Spec 6 spec の責務として post-本 spec、本 spec の deliverable は review evidence 提供で終端)
- 期間目安: 2-3 週間
- Spec 6 = この phase で完走 (= ペンディング解除 = Rwiki v2 design phase 全 8 spec approve 完了)

### 3.2 Phase B (release lifecycle)

#### B-1.0 (initial release prep + initial release)

- 元 A-3 (固有名詞除去 / npm package 化準備 / multi-language seed) を統合 (#3 採用)
- GitHub repo `dual-reviewer` fork
- npm package 化 (`package.json` / README / LICENSE)
- `--lang ja` initial、英 / 多言語は B-1.3 で追加
- Initial release: 3 skills (`dr-init` + `dr-design` + `dr-log`) + Chappy P0 3 件 + `seed_patterns.yaml` + `fatal_patterns.yaml`

#### B-1.x (incremental release)

- B-1.1: tasks phase 追加 (`dr-tasks` skill + Layer 2 tasks extension) + Claude family rotation opt-in flag (案 C1)
- B-1.2: cycle automation (`dr-extract` / `dr-update` skills) + `terminology.yaml` seed 配布
- B-1.3: multi-lingual + cc-sdd integration 強化 (`dr-translate` skill + `--lang en` 追加 + `--integrate-cc-sdd` flag 本格化)
- B-1.4: requirements + impl phase 追加 (`dr-requirements` / `dr-impl` skills + Layer 2 extension 2 種)

#### B-2 (multi-vendor + 並列 multi-subagent)

- timing: ~6-12 ヶ月
- 案 A (並列 multi-subagent) + 案 C2 (multi-vendor: GPT/Gemini/etc.) opt-in 試験
- C2 = 必要 (Bash + Python SDK で外部 API、API key 管理 + `.env` + git-secrets)
- **Chappy 保留 1 (hypothesis generator role 3 体構成)** をここで統合検討

#### B-3 (default 化)

- timing: ~1-2 年
- 統計に基づき default 化、案 A + C2 組合せで bias diversity 最大化
- 案 B (階層的) は experimental

### 3.3 Phase C (Rwiki dogfooding)

- timing: Rwiki implementation phase 中
- 内容: Rwiki が `npx dual-reviewer@latest --integrate-cc-sdd` で install して dogfooding
- real-world feedback を独立 repo にループバック (collective learning network 起動)
- **Chappy 保留 2 (意味レビュー層)** をここで導入検討

### 3.4 用語衝突注記

memory 内で「B-1」は二つの意味を持つ。混同回避:

- subagent 構成段階の B-1/B-2/B-3 (memory §8): 単純 dual / multi-subagent + multi-vendor / default 化
- release lifecycle の B-1.x: B-1.0 / B-1.1 / B-1.2 / B-1.3 / B-1.4

両者は同期 (release B-1.x 内で subagent 構成 B-1 完成、release B-2 で subagent 構成 B-2 移行)。本ドラフトでは subagent 構成段階を B-1/B-2/B-3、release lifecycle を B-1.x と表記。

### 3.5 8 月までの論文化ロードマップ

dual-reviewer は二重位置付け (プロダクト主 + 研究副産物、§2.10 参照)。論文 8 月ドラフト提出を前提に、Phase A timing と論文ロードマップを同期:

- **Phase 1 仕込み (今〜6月)**:
  - A-0 (spec 策定): `.kiro/specs/dual-reviewer/` で req → design → tasks
  - A-1 (prototype 実装): B-1.0 minimum 3 skills + Chappy P0 3 件 + **B-1.0 拡張 schema (`miss_type` / `difference_type` / `trigger_state`)**
- **Phase 2 溜め (6-7月)**:
  - A-2 (Spec 6 dogfeeding + 対照実験): Round 1-10 を **single (Opus のみ) + dual の両方で完走** (全 Round 2 倍)
  - quantitative evidence 取得 (figure 1-3): miss_type 分布 / difference_type 分布 / trigger 発動率
- **Phase 3 書き (7-8月)**:
  - A-2 後半に B-1.x 拡張 schema 追加 (`decision_path` / `skipped_alternatives` / `bias_signal`)
  - qualitative evidence + case study 強化 (figure 4-5): failure pipeline / bias パターン頻度
  - 論文ドラフト

二重ループ構造: 開発ループ (設計 → dual-review → 修正 → 実装) と研究ループ (ログ収集 → パターン抽出 → バイアス分析 → 論文化) が **同じ JSONL log を参照**。論文化のために別実験を組まない = 開発と論文の同時前進。

---

## §4 MVP scope (B-1.0 minimum)

### 4.1 Skills (3 個のみ)

- `dr-init` (project bootstrap)
- `dr-design` (Layer 1 framework + design extension + bias 抑制 quota + `fatal_patterns.yaml` 強制照合 + forced divergence prompt)
- `dr-log` (JSONL 構造化記録、impact_score 3 軸 schema)

残り 7 skills (`dr-tasks` / `dr-requirements` / `dr-impl` / `dr-extract` / `dr-validate` / `dr-update` / `dr-translate`) は B-1.x 段階追加。

### 4.2 同梱コンテンツ

- `seed_patterns.yaml` (23 事例 retrofit、Rwiki 由来 + `origin: rwiki-v2-dev-log`)
- `fatal_patterns.yaml` (致命級 8 種固定: sandbox escape / data loss / privilege escalation / infinite retry / deadlock / path traversal / secret leakage / destructive migration)
- design phase only (req/tasks/impl extension は B-1.x で段階追加)

### 4.3 Chappy P0 3 件 (B-1.0 必須)

- `fatal_patterns.yaml` 強制照合 (Layer 1 quota)
- impact_score 3 軸 (post-run JSONL schema)
- forced divergence prompt (adversarial subagent prompt template に 1 行)

### 4.4 言語

- `--lang ja` 単一 (initial、user 中心が日本語話者 = Rwiki seed の言語)
- `--lang en` は B-1.3 で追加
- prompt 言語 = 英語固定 1 本 (subagent 出力は document auto-detect)

### 4.5 cc-sdd integration

- `--integrate-cc-sdd` flag は B-1.0 で minimum (skill placeholder のみ)
- 本格化は B-1.3

### 4.6 B-1.0 拡張ログ schema (論文化軸、§2.10.3 参照)

`dr-log` JSONL に以下 4 要素を schema 追加 (B-1.0 minimum 同梱):

- `miss_type` (finding ラベル、6 種 enum)
- `difference_type` (adversarial 拾い分のラベル、6 種 enum)
- `trigger_state` (review_case フラグ、3 軸 enum object 各 applied | skipped の 2 値 enum: `negative_check` / `escalate_check` / `alternative_considered`)
- `phase1_meta_pattern` (escalate 検出 finding ラベル、3 値 enum + null: `norm_range_preemption` / `doc_impl_inconsistency` / `norm_premise_ambiguity` / null、cross-spec contract 補強 field、`dual-reviewer-dogfeeding` Req 4 AC 3 の Phase 1 同型 hit rate 抽出と integration)

実装コスト = 極低 (enum 定義 + LLM prompt 1 行)。impact_score 3 軸 (Chappy P0、結果の質軸) と直交 (要素 1-3 = 失敗構造観測軸 / 要素 4 = Phase 1 escalate 同型識別による cross-spec 学習継承軸)。

B-1.x 段階追加: `decision_path` / `skipped_alternatives` / `bias_signal` (詳細 §2.10.3、自由記述 + 内省、A-2 後半 〜 Phase 3 で実装)。

---

## §5 関連リソース + 参照点

### 5.1 memory (`~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/`)

- `feedback_design_review_v3_generalization_design.md` (本ドラフトの primary 参照点、§1-13 確定事項)
- `feedback_design_review_v3_adversarial_subagent.md` (試験運用 evidence)
- `feedback_design_review.md` (10 ラウンド構成、Layer 2 design extension の base)
- `feedback_review_step_redesign.md` (Step 1a/1b + 4 重検査 + Step 1b-v 自動深掘り)
- `feedback_no_round_batching.md` (一括処理禁止)
- `feedback_dominant_dominated_options.md` (dominated 除外 + 厳密化規律)
- `feedback_review_judgment_patterns.md` (dev-log 23 パターン、Phase A retrofit で yaml 化)

### 5.2 試験運用報告書

- `.kiro/methodology/dogfeeding/spec-3/round_5-10_subagent_adversarial.md`
  - §1-7: 試験運用 evidence (致命級 1 件 + disagreement 2 件 + Phase 1 同型 3 種全該当 2 度)
  - §8: 一般化 design 議論集約 (5 観点全クローズ)

### 5.3 dev-log (User 管理)

- `docs/レビューシステム検討.md` (5 観点議論の対話ログ)
- `docs/review_by_chappy.md` (Chappy review)

### 5.4 Rwiki spec (関連)

- `.kiro/specs/rwiki-v2-prompt-dispatch/` (Spec 3、試験運用基盤)
- `.kiro/specs/rwiki-v2-perspective-generation/` (Spec 6、A-2 dogfeeding 対象)

### 5.5 Phase A 後の発展先

- `.kiro/specs/dual-reviewer/` (A-0 で生成、本ドラフトを参照)
- `scripts/dual_reviewer_prototype/` または `.kiro/specs/dual-reviewer/prototype/` (A-1 で配置)
- 独立 repo `dual-reviewer` (Phase B-1.0 fork)

---

_本ドラフト v0.2 = A-0 開始時点の参照点。A-0 進行中に `design.md` / `tasks.md` と整合させ、必要に応じて v0.3, v0.4 に更新。_

## 変更履歴

- **v0.1** (2026-04-29 初版): 5 観点議論完了 + Chappy review 受領後の初版集約。memory §1-13 + Phase A 細分化判断を反映。
- **v0.2** (2026-04-29 改訂): `docs/ログサンプル.md` (Chappy との論文化議論) を反映。
  - §2.10 新規: 論文化軸 (dual-reviewer の二重位置付け) + 主張アップグレード版 + 拡張ログ schema (B-1.0 enum 3 = `miss_type` / `difference_type` / `trigger_state`、B-1.x 自由記述 3 = `decision_path` / `skipped_alternatives` / `bias_signal`)
  - §3.1 A-2 修正: 対照実験 (single vs dual 全 Round 2 倍) 追記
  - §3.5 新規: 8 月までの論文化ロードマップ (Phase 1 仕込み / Phase 2 溜め / Phase 3 書き)
  - §4.6 新規: B-1.0 拡張ログ schema 同梱 (3 要素)
- **v0.3** (2026-04-29 改訂): dual-reviewer-foundation requirements 5 ラウンドレビュー (V3 adversarial subagent 統合) で発見した cross-document 矛盾を解消。
  - §2.9 修正 (致命級解消、subagent 独立発見): 「固有名詞ゼロ」削除 = §3.1 / §4.2 / brief.md / req AC 4.3「Rwiki 固有名詞付きで OK」と整合 (generalization は Phase B-1.0 release prep の責務であることを明示)
  - §2.10.3 / §4.6 修正: trigger_state「3 軸 boolean」→「3 軸 enum object 各 applied | skipped の 2 値 enum」 = JSON Schema 表現精度向上
  - §3.1 A-0 修正: 単一 `.kiro/specs/dual-reviewer/` 想定を 3 spec 分割 (foundation / design-review / dogfeeding) に更新 (TODO_NEXT_SESSION.md 確定事項 1 反映、依存階層 / 並走方針も明示)
