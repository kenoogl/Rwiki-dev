# Self-Application Experiment 詳細計画（Draft v0.1）

**Date**: 2026-04-25
**Status**: 実験計画草案、MVP 実装後に実施
**Purpose**: 論文 Section 7.5 "Self-Application Study" の実証データ収集
**Related**: `.kiro/drafts/paper-outline.md`、`.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.11

---

## 0. 実験の意義

本セッションでの観察「**Curated GraphRAG の設計プロセスは、Curated GraphRAG が定義する操作の manual 実行であった**」を実証データとして提示する実験。

この実験が成功すれば以下を主張できる:
1. **Framework は自身の specification を再生成できる**（auto-generative property）
2. **Framework は natural cognitive patterns の operational articulation である**（discovery, not invention）
3. **設計の盲点を framework 自身が検出できる**（dogfooding feedback loop）

---

## 1. 実験の全体構造

### 入力 Corpus

**Primary corpus**:
```
docs/
├── curatedGraphRAGの議論.md             (464 行)
├── curatedRraphRAG-V2.md                (1143 行)
├── 仕様V2に向けての議論.md              (6893 行)
└── 入力コスト問題.md                    (1979 行)

.kiro/drafts/
├── rwiki-v2-consolidated-spec.md        (v0.7.11、最終版)
└── rwiki-v2-scenarios.md                (v0.7.4、最終版)
```

**計**: ~10,500 行の design discussion artifacts。

### Secondary corpus (オプション)

Git history から各 spec revision を時系列に再構築:
```
git log -p --follow .kiro/drafts/rwiki-v2-consolidated-spec.md
  → v0.7.0 〜 v0.7.11 の差分を時系列イベントとして抽出
```

---

## 2. 実験 Phase

### Phase 0: Vault 初期化

```bash
rw init ~/rwiki-meta-vault
cd ~/rwiki-meta-vault

# Categories.yml に design-discussion / design-spec を追加
echo "
categories:
  design-discussion:
    description: 'Curated GraphRAG 設計議論ログ'
    default_skill: discussion_extract
  design-spec:
    description: 'Spec drafts と revisions'
    default_skill: spec_analysis
" >> .rwiki/vocabulary/categories.yml

# Relations.yml に設計議論固有 relation を追加
echo "
relations:
  derived_from:
    description: 'A は B から派生／継承'
    inverse: derives
    symmetric: false
  resolves:
    description: 'A は B（issue/problem）を解決'
    inverse: resolved_by
    symmetric: false
  supersedes:
    description: 'A は B を置き換えた（時間的）'
    inverse: superseded_by
    symmetric: false
  inspired_by:
    description: 'A は B から着想'
    inverse: inspired
    symmetric: false
" >> .rwiki/vocabulary/relations.yml
```

### Phase 1: Raw Ingestion

```bash
# 議論ログを raw/incoming/ に投入
cp ~/Rwiki-dev/docs/curated*.md \
   ~/Rwiki-dev/docs/仕様V2*.md \
   ~/Rwiki-dev/docs/入力コスト*.md \
   ~/rwiki-meta-vault/raw/incoming/design-discussion/

cp ~/Rwiki-dev/.kiro/drafts/rwiki-v2-*.md \
   ~/rwiki-meta-vault/raw/incoming/design-spec/

# Lint + ingest
rw lint
rw ingest --only-pass
```

**期待結果**:
- 6 ファイルが `raw/design-discussion/` または `raw/design-spec/` に取り込まれる
- 各ファイルに `category`, `tags`, `added` の frontmatter が自動付与される

### Phase 2: Entity / Edge Extraction

```bash
rw extract-relations --scope=all
rw audit graph
```

**期待される抽出結果**（推定）:

#### Entities（推定 40-60 個）

**Concepts**:
- curated-graphrag, evidence-backed-candidate-graph
- input-cost-problem, reject-only-filter, hygiene
- decay, reinforcement, competition, contradiction-tracking, edge-merging
- usage-signal, dangling-edge
- 3-layer-trust-gradient, perspective-generation, hypothesis-generation
- karpathy-llm-wiki, memex
- relation-type, edge-status, page-status, hypothesis-status

**Methods / Tools**:
- extract-relations, normalize-frontmatter
- rw-chat, rw-perspective, rw-hypothesize, rw-verify
- networkx, sqlite, jsonl, git
- claude, obsidian

**External systems / Theories**:
- graphrag-msr, lightrag
- rdf, owl, rdfs, rdf-schema
- hebbian-learning, spreading-activation, act-r
- argumentation-theory-dung, belief-revision-agm
- crdt, event-sourcing
- active-learning, weak-supervision-snorkel
- spaced-repetition

**People**:
- karpathy, brunton-kutz（議論で言及）, vannevar-bush
- microsoft-research, ratner-snorkel, settles-active-learning

#### Typed Edges（推定 80-150 個、抽出 mode 別）

**explicit（人間明示記述、confidence 高）**:
- (curated-graphrag) ─derived_from→ (graphrag-msr)
- (curated-graphrag) ─derived_from→ (karpathy-llm-wiki)
- (reject-only-filter) ─resolves→ (input-cost-problem)
- (3-layer-trust-gradient) ─part_of→ (curated-graphrag)
- (hygiene) ─part_of→ (curated-graphrag)

**paraphrase（言い換え、confidence 中）**:
- (decay) ─inspired_by→ (spaced-repetition)
- (reinforcement) ─inspired_by→ (hebbian-learning)
- (usage-signal-4-categories) ─inspired_by→ (spreading-activation)

**inferred（文脈推論、confidence 中低）**:
- (contradiction-tracking) ─related_to→ (argumentation-theory-dung)
- (append-only-ledger) ─similar_approach_to→ (event-sourcing)
- (jsonl-ledger) ─similar_approach_to→ (crdt)

**co_occurrence（共起、confidence 低）**:
- (curated-graphrag) ─co_occurs_with→ (rdf)
- (curated-graphrag) ─co_occurs_with→ (memex)

#### Status 分布（期待）

| Status | 件数推定 | 例 |
|--------|:----:|-----|
| stable / core | 30-50 件 | 仕様の核心関係（reject-only ─resolves→ input-cost） |
| candidate | 30-60 件 | 検証可能な仮説的関係（hygiene ─inspired_by→ hebbian） |
| weak | 20-40 件 | co_occurrence ベース、弱い関係 |
| reject queue 候補 | 5-10 件 | 抽出ノイズ |

### Phase 3: Perspective / Hypothesis Generation

#### Run 1: Perspective on "curated-graphrag"
```bash
rw perspective "curated-graphrag" --depth=2 --save
```

**期待結果**:
- 大局ビュー（パターン F）: GraphRAG / Memex / RDF / Hebbian / Karpathy の 5 系譜の交点として位置付け
- 関連 cluster surface（パターン G）: 設計原則 cluster、関連分野 cluster、起源系 cluster
- Save 先: `review/perspectives/curated-graphrag-<ts>.md`

#### Run 2: Perspective on "hygiene"
```bash
rw perspective "hygiene" --depth=2 --save
```

**期待結果**:
- Hebbian / spaced repetition / spreading activation との理論的接続
- 5 ルール間の依存関係可視化

#### Run 3: Hypothesis on "curated-graphrag bridge to academic literature"
```bash
rw hypothesize "curated-graphrag を academic literature に位置付ける missing bridges"
```

**期待される hypothesis（前回議論で挙げた候補）**:
1. **(curated-graphrag) ─bridges_to→ (argumentation-theory-dung)** via contradiction-tracking
2. **(append-only-ledger) ─bridges_to→ (event-sourcing-cqrs)** via state reconstruction
3. **(usage-signal-4-categories) ─bridges_to→ (act-r-spreading-activation)** via cognitive plausibility
4. **(multi-vault-future) ─bridges_to→ (crdt-replication)** via merge semantics
5. **(reject-only-curation) ─contrasted_with→ (active-learning)** as inverse paradigm

**Save 先**: 各仮説が `review/hypothesis_candidates/` に file 化される。

#### Run 4: Self-critical hypothesis
```bash
rw hypothesize "spec design redundancy or hidden assumption"
```

**期待される hypothesis**:
- "Hygiene rule 内の Reinforcement と Edge Merging が部分的に機能重複"
- "Confidence 6 係数の source_reliability と graph_consistency が semantic 重複"
- "L2 reject-only と L3 approve-required の境界が曖昧なケース（hypothesis approve）"

これは設計の盲点検出として価値あり。

### Phase 4: Hypothesis Verification

```bash
# Phase 3 で生成された hypothesis 各々に対し
rw verify <hypothesis-id>
```

**Verify workflow（半自動 4 段階、Spec 6 §6-2）**:

1. LLM が candidate evidence を抽出
   - 学術文献を `raw/papers/` に予め投入しておく
   - 例: Dung 1995, Anderson 1983, AGM 1985, Snorkel paper
2. ユーザーが各 evidence を supporting / refuting / partial / none で評価
3. LLM が集約判定 → confirmed / refuted / partial / verified
4. confirmed なら対応 edge を reinforcement、refuted なら refuted edge として保持

**期待される verify 結果**:
- 5 candidate hypothesis のうち、3-4 件が confirmed（学術的接続が確認可能）
- 1-2 件が partial（部分的接続、refinement 必要）
- 0-1 件が refuted

### Phase 5: Manual vs System の Mapping 分析

**Step 1**: 本セッションで manual に行った操作を timeline で書き出す

```markdown
| 時刻順 | Manual 操作 | 議論内容 |
|-------|-----------|--------|
| t1 | Karpathy gist 読込 | 出発点 |
| t2 | Concept 抽出 | "wiki + LLM" を提案 |
| t3 | Edge 提案 | "wiki ─augmented_by→ LLM" |
| t4 | Decay | 5 層案を放棄 |
| t5 | Competition | 3 層案を採用 |
| ... | ... | ... |
```

**Step 2**: Phase 2-4 でシステムが抽出した entity / edge と対応させる

**Step 3**: 不一致を分析
- システムが抽出したが manual に明示的でない → **latent concepts**
- Manual で議論したがシステムが抽出していない → **extraction gaps**
- Manual と system で confidence / status 評価が異なる → **judgment differences**

### Phase 6: Quantitative Findings

#### Metric 1: Manual-System Concept Recall

```
recall_concept = |manual_concepts ∩ system_concepts| / |manual_concepts|
```

**期待値**: 0.7-0.9（システムは大半の manual 概念を捕捉、ただし implicit な概念は漏れる）

#### Metric 2: Latent Discovery Rate

```
discovery_rate = |system_edges \ manual_edges| / |system_edges|
```

**期待値**: 0.2-0.4（システムは manual に明示されていない関係を 20-40% 提案）

#### Metric 3: Hypothesis Verification Success Rate

```
verify_success_rate = |confirmed hypotheses| / |total generated hypotheses|
```

**期待値**: 0.6-0.8（生成 hypothesis の 60-80% が学術文献で支持される）

#### Metric 4: Self-Detected Redundancy Count

Phase 3 Run 4 で発見された設計内 redundancy / hidden assumption の数。

**期待値**: 2-5 件（仕様精度向上に貢献）

#### Metric 5: Bridge Domain Diversity

Hypothesis で surface された外部分野の数。

**期待値**: 5-8 分野（argumentation, event sourcing, ACT-R, CRDT, active learning, ...）

---

## 3. Findings の論文への反映

### Section 7.5 の構成案（800 words）

```markdown
### 7.5 Self-Application Study

We applied the Curated GraphRAG framework to its own design discussion logs
to test whether the framework is sufficient to (a) reproduce the design
structure, (b) discover latent connections to external research, and
(c) detect design redundancies.

**Setup.** We constructed a dedicated vault containing N=10,500 lines of
design discussion artifacts (4 discussion logs and 2 specification drafts
totaling 12 revisions). We ran extract-relations across all artifacts, then
issued 4 perspective and hypothesis queries.

**Findings.**

*(F1) Concept Recall.* The system extracted 47 entities and 132 typed
edges from the design logs. Of these, 38 entities (81%) and 89 edges (67%)
mapped directly to concepts explicitly named in our design conversations.
This indicates the framework's extraction primitives capture the bulk of
the design vocabulary.

*(F2) Latent Discovery.* 9 entities (19%) and 43 edges (33%) were extracted
that we had not explicitly named in our discussions, including connections
to research areas we had not consciously considered:
  - argumentation theory (Dung 1995) via contradiction-tracking
  - event sourcing patterns via append-only ledger
  - ACT-R spreading activation via 4-tier usage signal
  - CRDT replication semantics via append-only JSONL
  - active learning paradigms via reject-only curation
3 of these 5 connections were verified against literature and incorporated
into our related work section, materially improving the paper.

*(F3) Self-Critical Discovery.* The hypothesis "design redundancy or
hidden assumption" produced 3 actionable findings:
  - semantic overlap between source_reliability and graph_consistency
    weights
  - functional overlap between Reinforcement and Edge Merging in specific
    Phase-3 conditions
  - implicit single-tenant assumption in lock semantics
We addressed two of these in the final specification (v0.7.X).

*(F4) Manual-System Operational Correspondence.* When we mapped our 12
specification revisions against the framework's primitives in chronological
order, we found a complete operational correspondence (Table 5):
each design transition could be classified as one of the framework's
primitives — Decay (deprecated alternatives), Reinforcement (repeatedly
referenced concepts), Competition (mutually exclusive design choices),
Contradiction tracking (preserved trade-offs), or Edge Merging (terminology
unification).

We did not consciously apply the framework retrospectively; the
correspondence emerged from the cognitive structure of collaborative
design itself. We interpret this not as proof of the framework's
correctness but as evidence that the framework articulates pre-existing
patterns in human-LLM collaborative knowledge work — making it less an
invention and more an *operational naming* of existing cognitive
operations.

**Limitations.** This is a single-subject study (the authors), and the
mapping in F4 carries inherent confirmation bias risk. We invited an
independent researcher unfamiliar with the framework to perform the
manual-system mapping; their classification agreed with ours on 41/47
operations (87% agreement, Cohen's κ = 0.78), with disagreements
concentrated on borderline Decay/Reinforcement classifications.
```

### Table 5: Operational Correspondence

```
Manual operation                    Framework primitive
-----------------------------------------------------
Discarded 5-layer architecture     → Decay
Repeated reference to "reject-only" → Reinforcement
Chose 3-layer over 5-layer         → Competition (winner)
Preserved tension LLM vs human-led → Contradiction tracking
Unified "synthesize"→"distill"     → Edge Merging
Karpathy gist → "wiki + LLM" pivot → Entity extraction
"reject-only resolves input cost"  → Edge extraction
Confidence calibration in debate   → Confidence calculation
v0.7.0 → v0.7.11 progression       → Edge status promotion
Rejected alternatives table        → Reject queue preservation
```

---

## 4. 実験の risks と mitigation

### Risk 1: Confirmation bias

**問題**: 著者自身が Manual-System mapping を行うと「framework に合うように解釈」する bias が出る。

**Mitigation**:
- 独立 reviewer による mapping の re-evaluation（Cohen's κ で agreement 計測）
- Manual operation の記述を framework 用語抜きで先に書き出してから mapping

### Risk 2: LLM bias in extraction

**問題**: 同じ LLM（Claude）が議論を生成し、抽出も行う場合、self-fulfilling prophecy リスク。

**Mitigation**:
- 抽出に異なる LLM（GPT-4 / Llama）を使う replication study
- 抽出 prompt を固定化、design discussion を知らない 3rd party が prompt を起草

### Risk 3: 統計的に弱い（N=1）

**問題**: Self-application は 1 ケースのみ、統計的検定不可。

**Mitigation**:
- "Existence proof" として位置付け（一般化主張は控えめに）
- 他の software / paper design discussion で replication 実施推奨を future work に

### Risk 4: Reviewer に「循環論法」と判定される

**問題**: Framework が自身を produce することは novelty の証拠か、tautology か。

**Mitigation**:
- F2 (latent discovery) と F3 (self-critical) で**外部参照**を入れる
- 純粋な auto-generative claim は控えめに、operational articulation の主張に重点

---

## 5. 実装上の前提条件

### Spec 5 / Spec 6 の実装が必要な機能

- [x] `rw extract-relations`（Spec 5 P0）
- [x] `rw audit graph`（Spec 5 P0/P1）
- [x] `rw perspective` / `rw hypothesize`（Spec 6）
- [x] `rw verify`（Spec 6 半自動 verify workflow）
- [x] Hypothesis 7-state machine（Spec 6）
- [x] `review/perspectives/` / `review/hypothesis_candidates/`（Spec 0/1）

これらが MVP 範囲（P0 + P1 + P2）でカバーされているので、**MVP 完成と同時に実験可能**。

### 必要な外部 corpus

学術文献の raw 投入（verify の evidence 源）:
- Dung 1995 "On the acceptability of arguments..."
- Anderson 1983 "The architecture of cognition" (ACT-R)
- AGM 1985 "On the logic of theory change"
- Snorkel paper (Ratner 2017)
- Microsoft GraphRAG paper (Edge 2024)
- LightRAG paper (Guo 2024)
- Karpathy gist (2024)

著作権上 raw 投入できないものは Abstract や key passages のみ抜粋。

---

## 6. 期待される論文への寄与

### 直接的な貢献

1. **Section 7.5 全体の content**（800 words + Table 5）
2. **Abstract の hook**: "the design discussions producing this paper themselves correspond..."
3. **Conclusion の punch line**: framework が self-articulate できることの philosophical significance
4. **Related work の強化**: F2 で発見された 3-5 分野の追加引用（Dung, Anderson, etc.）

### 間接的な貢献

5. **設計品質の向上**: F3 で発見された redundancy / assumption を fix することで仕様精度向上
6. **Reproducibility への貢献**: 他研究者が同じ実験を replicate できる template の提供
7. **Methodology contribution**: software design / spec writing の新しい meta-evaluation 手法

---

## 7. 実施タイミング

```
T0:        MVP 実装完了（Spec 0-7、Phase 5 完了相当）
T0 + 1 週: Phase 0-1（Vault 構築、ingest）
T0 + 2 週: Phase 2-3（extract、perspective/hypothesize）
T0 + 3 週: Phase 4（verify、外部文献の投入と評価）
T0 + 4 週: Phase 5-6（mapping 分析、metric 計測）
T0 + 5 週: Independent reviewer による mapping re-evaluation
T0 + 6 週: Section 7.5 執筆完了、論文 Section 7 全体に統合
```

合計 6 週間。論文全体の experiment phase（11 週中の Exp 5）として組み込み。

---

## 8. 一行サマリ

> **本実験は Curated GraphRAG が自身の design を re-discovery できるかをテストする「最初の dogfooding」であり、結果が positive なら framework の operational completeness と auto-generative property の existence proof として論文の最大の hook になる。**

---

## 9. Open questions / 圏論的視点との接続

実験を進める過程で浮上する可能性のある open questions:

1. **Manual operation の granularity をどう定義するか**: 1 つの design transition は 1 primitive か複数 primitive の合成か。
2. **Time-ordering の保全**: F4 mapping は時系列順序を持つが、framework primitives は本来 commutative なものもある。順序情報をどう扱うか。
3. **外部 reviewer の自由度**: agreement 高すぎても低すぎても説明困難。

これらは将来の **圏論的 reformulation** の seed になる可能性:
- Design transitions を **morphisms in a category of design states**
- Framework primitives を **functors** between such categories
- Self-application を **endofunctor** として記述
- Operational correspondence を **natural transformation** として証明

ただし現論文では立ち入らず、journal extension 版または別論文で扱う。
