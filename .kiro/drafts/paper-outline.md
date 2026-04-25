# Curated GraphRAG 論文化 Roadmap（Draft v0.1）

**Date**: 2026-04-25
**Status**: 論文化を検討するための outline 草案、未投稿
**Source artifacts**: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.11、`.kiro/drafts/rwiki-v2-scenarios.md` v0.7.4、`docs/curatedGraphRAGの議論.md` 他 3 議論ログ

---

## 1. Title 候補

優先度順:

1. **"Curated GraphRAG: Reject-Only Curation and Hygiene-Driven Evolution for Personal Knowledge Construction"**
   - 主貢献を最も明示
   - "Curated GraphRAG" の名称を確立する効果
2. "Living Knowledge Graphs: Operational Semantics for Human-LLM Collaborative Knowledge Work"
   - "Living" abstraction を前面化
   - HCI 系 venue 向け
3. "From Approval to Rejection: Reducing Human Cost in LLM-Augmented Knowledge Graph Construction"
   - reject-only curation の paradigm shift を強調
   - Active learning コミュニティに刺さる
4. "Auto-Generative Knowledge Frameworks: A Self-Application Study of Curated GraphRAG"
   - Self-application の novelty を hook に
   - Demo / case study 系 venue 向け

**推奨**: Title 1 を主軸、subtitle として self-application を入れる版も検討。

---

## 2. Abstract 草案（300 words）

```
GraphRAG approaches augment retrieval with extracted entity-relation graphs,
but face two persistent obstacles: (1) the *input cost problem* — full human
approval of LLM-extracted relations does not scale, while no curation produces
a "hallucination network", and (2) the *static graph assumption* — once
constructed, knowledge graphs do not adapt to use patterns or accumulating
contradictions.

We propose **Curated GraphRAG**, a framework with four contributions.
First, a **three-layer trust gradient** (Raw / Graph Ledger / Curated Wiki)
with distinct human involvement at each layer: humans write at L1, *only
reject* at L2, and *approve* at L3. Second, **Hygiene** — five operational
evolution rules (Decay, Reinforcement, Competition, Contradiction tracking,
Edge Merging) that govern how a graph evolves through use, with explicit
mathematical semantics for confidence dynamics. Third, an **evidence-backed
candidate graph** model where every edge carries provenance, with a hard
upper bound (≤0.3) on confidence for evidence-less edges to prevent
hallucination drift. Fourth, **curation provenance** — a decision log
recording the *why* of each curation step, orthogonal to the *what* of
evidence chains, enabling reproducibility, self-reflection, and
self-application. We integrate visualization (CLI views, markdown
timelines, embedded mermaid diagrams) directly into the recording schema
to ensure provenance is immediately consumable.

A distinctive property of our framework is *contradiction preservation*:
unlike traditional knowledge bases that resolve conflicts, Curated GraphRAG
retains opposing edges with mutual references, providing the substrate for
later perspective generation and hypothesis discovery.

We present a self-application study showing that the design discussions
producing this paper themselves correspond, step-by-step, to manual
execution of the framework's primitives. This auto-generative property
constitutes both motivation and existence proof.

Curated GraphRAG positions itself not as a creativity engine but as an
*introspection amplifier* for human knowledge work — an honest claim
consistent with the framework's bounded scope and its philosophical
foundation in Karpathy's LLM Wiki vision.
```

---

## 3. Section 構造

### 1. Introduction（2 pages）

**Story arc**:
1. Personal knowledge management の現状 — Karpathy LLM Wiki vision、Memex、Obsidian 等の系譜
2. RAG / GraphRAG の台頭と限界 — schemaless extraction、hallucination drift、static graph
3. **Input cost problem の定式化** — 全件 approve は scale しない、no curation は trust 崩壊
4. **本論文の貢献**:
   - 3-layer trust gradient（reject-only at L2、approve at L3）
   - Hygiene という operational evolution semantics
   - Evidence-backed candidate graph model
5. Roadmap of paper

**Hook**: Section 7.5 self-application を冒頭で予告し reader を引き込む。

### 2. Background and Related Work（3 pages）

#### 2.1 Personal Knowledge Management
- Memex (Bush 1945)
- Vannevar Bush の trail concept
- Roam, Obsidian, Notion の系譜
- Karpathy LLM Wiki idea (gist 2024)
- 既存 PIM ツールの限界（パイプライン・LLM 連携・graph 自動進化なし）

#### 2.2 GraphRAG and Variants
- Microsoft GraphRAG (Edge et al., 2024)
- LightRAG (Guo et al., 2024)
- 通常 GraphRAG の弱点: 自動抽出ノイズ、文脈ズレ、静的 graph、裏付け不足

#### 2.3 Knowledge Graph Construction and Evolution
- Knowledge graph completion: TransE (Bordes 2013), RotatE (Sun 2019)
- Temporal KG: TKG embeddings
- Ontology learning (Cimiano 2006)
- Open IE (Etzioni 2008)
- 既存研究で扱われない: confidence の経時進化、competition operator

#### 2.4 Human-in-the-Loop Curation
- Active learning (Settles 2009)
- Crowdsourced annotation (Snow 2008)
- Weak supervision: Snorkel (Ratner 2017)
- 既存研究の前提: 人間が label 提供、または全自動。**reject-only 形式の formalization は新しい**

#### 2.5 Cognitive Plausibility
- Hebbian learning (Hebb 1949) — Reinforcement
- Spaced repetition (Ebbinghaus 1885) — Decay
- ACT-R spreading activation (Anderson 1983) — Usage signal 4 種別
- Argumentation theory (Dung 1995) — Contradiction tracking
- Belief revision AGM (Alchourrón et al. 1985)

#### 2.6 RDF and Semantic Web
- RDF triple structure
- RDFS / OWL ontologies
- Rwiki との対応: triple 同型だが推論なし、進化的 vocabulary

### 3. The Curated GraphRAG Framework（3 pages）

#### 3.1 Three-Layer Trust Gradient
- L1 Raw: 人間記述、evidence 源
- L2 Graph Ledger: LLM 抽出、reject-only
- L3 Curated Wiki: approve 必須、trust 層
- 各層での人間と LLM の役割（§2.0 layered applicability matrix）

#### 3.2 Evidence-Backed Candidate Graph
- 6 係数加重 confidence 式
- Evidence-less upper bound（≤0.3）
- 4 段 status（weak / candidate / stable / core）+ 終端 2 種（deprecated / rejected）
- 12 + 8 + 10 = 30 種の relation type 初期セット

#### 3.3 Reject-Only Curation Paradigm
- 全件 approve の cost 爆発と reject-only への転換
- Reject reason の 6 分類 + 自由記述
- Auto-batch（confidence 低位）と人間 confirm の hybrid

### 4. Hygiene as Evolution Semantics（4 pages、★ 中心章）

#### 4.1 Five Evolution Rules
固定実行順 Decay → Reinforcement → Competition → Contradiction tracking → Edge Merging
各 rule の operational semantics と数式

#### 4.2 Confidence Dynamics
```
confidence_{t+1} = c_t + α × usage_signal + β × recurrence
                       − γ × decay − δ × contradiction
```
Per-event / per-day delta cap で暴走防止

#### 4.3 Usage Signal with 4 Categories
Direct (1.0) / Support (0.6) / Retrieval (0.2) / Co-activation (0.1)
```
usage_signal = base × contribution × √confidence × independence × time_weight
```
Cognitive plausibility（spreading activation）への接続

#### 4.4 Competition: Three Levels
- L1: 同 node pair（MVP 必須）
- L2: 類似 node pair（Phase 3）
- L3: semantic tradeoff（Phase 3）
- Winner / runner-up / loser / obsolete の status transition

#### 4.5 Contradiction Preservation Principle
削除せず `contradiction_with:` で保持
Argumentation theory との接続
Perspective generation の土壌として機能

### 5. Implementation（2 pages）

- JSONL ledger as source of truth、SQLite cache as derived
- Append-only event log（edge_events.jsonl の 8 種 event type）
- File lock concurrency model（MVP single-user serialized）
- Atomic transaction semantics
- 5 Phase progression: P0 (Ledger) → P1 (Query cache) → P2 (Hygiene) → P3 (Competition L2/3) → P4 (export)
- MVP 範囲: P0 + P1 + P2

### 5.5 Curation Provenance Layer（★ 新貢献、2 pages）

#### 5.5.1 Decision Log Schema
- decision_log.jsonl の 9 fields（decision_id / ts / type / actor / subject_refs / reasoning / alternatives_considered / outcome / context_ref）
- 10 decision types
- Append-only、git 管理 default、privacy mode

#### 5.5.2 Selective Recording
- Volume 爆発防止のため auto-record 閾値を tuned に
- 6 trigger 条件（境界決定 / 矛盾 / 人間 action / status 遷移 / synthesis 操作）
- Routine events は edge_events.jsonl に集約、decision_log には記録しない

#### 5.5.3 Reasoning Input（Hybrid）
- Auto-generate from chat session（rw chat の context）
- Manual `--reason` flag
- Default skip with marker
- Required reasoning for high-stakes decisions

#### 5.5.4 Visualization Tiers
- Tier 1: CLI views (`rw decision history / recent / stats / search / contradictions`)
- Tier 2: Markdown timeline (`rw decision render` → `review/decision-views/`)
- Tier 3: Mermaid embeddings (gantt / flowchart) — Obsidian / GitHub render
- Tier 4 / 5: Phase 2 候補（graph view 拡張、web dashboard）

#### 5.5.5 Orthogonality to Evidence Chain
- Trust chain (vertical, §2.10): L1 raw → L2 evidence → L3 sources
- Curation provenance (horizontal, §2.13): decision_log → context_ref → chat-session
- 両方が交差する point から WHY と WHAT が同時に辿れる

### 6. Discovery: Perspective and Hypothesis Generation（2 pages）

#### 6.1 Two Distinct Epistemic Operations
- Perspective: 既存知識の再解釈（stable + core edges、confidence ≥ 0.4）
- Hypothesis: 未検証命題（candidate + missing bridges、confidence ≥ 0.3）
- 異なる scoring function での top-M 選定

#### 6.2 GraphRAG-Inspired 4 Techniques
- Community detection（Louvain/Leiden）
- Global query
- Missing bridge detection
- Hierarchical summary（on-demand、事前構築しない）

#### 6.3 Half-Automated Hypothesis Verification
- LLM が candidate evidence 抽出
- 人間が supporting/refuting/partial/none 評価
- LLM が集約判定
- Edge reinforcement への feedback loop

### 7. Evaluation（4 pages、★ 実証）

#### 7.1 Experiment 1: Input Cost Reduction
**Setup**: 同一 raw データで全件 approve vs reject-only filter の人間総作業時間を比較
**Metric**: 1000 edge 処理時の hours / clicks
**Hypothesis**: reject-only は 70-80% コスト削減
**Subjects**: 5-10 名の研究者（LLM tool 使用経験あり）

#### 7.2 Experiment 2: Hygiene-Driven Quality Evolution
**Setup**: 任意 vault で 1 ヶ月運用、weekly Hygiene
**Metric**: precision@k、stable+core edges 比率の経時推移
**Hypothesis**: 月単位で precision 向上、stable 比率増加
**Method**: Longitudinal study、graph snapshot 比較

#### 7.3 Experiment 3: Discovery Quality（User Study）
**Setup**: Perspective / Hypothesis vs baseline RAG
**Metric**:
- Likert: "自分が気づかなかった視点を提示できたか"
- 客観: 提示された関連性の precision @5
**Hypothesis**: Curated GraphRAG が baseline 比 +30% 以上
**Subjects**: 5-10 名（自分の知識領域を持つ）

#### 7.4 Experiment 4: Contradiction Preservation Impact
**Setup**: 矛盾削除条件 vs 保持条件で perspective generation 品質比較
**Metric**: surfaced 対立視点の数、user 評価
**Hypothesis**: 保持条件が有意に多くの tradeoff を surface

#### 7.5 Self-Application Study（★ 独自貢献）
**Setup**: 本論文の design discussion logs を vault に投入
**Method**: §7.5 Section に詳細（別 doc `self-application-experiment-plan.md` 参照）
**Findings**: 設計プロセスと framework primitives の対応マッピング、未明示の関連分野の発見、設計冗長性の検出

### 8. Discussion（2 pages）

#### 8.1 Curated GraphRAG vs Traditional GraphRAG
比較表で明確化:
| 軸 | 通常 GraphRAG | Rwiki Curated |
|----|--------------|--------------|
| 起点 | 未整理テキスト | 既整理 wiki + 候補 graph |
| 主体 | LLM | 人間承認 + LLM 抽出 |
| 品質 | ノイズあり | reject-only + Hygiene |
| 用途 | 検索強化 | 検索 + 探索・発見 |
| 進化 | 静的 | evolving |

#### 8.2 Theoretical Implications
- 「内省増幅装置」としての位置付け
- 創発の不可能性と弱い意味の novelty
- Karpathy 哲学の operational instantiation

#### 8.3 Practical Implications
- Personal knowledge management の future
- Multi-agent / federated 拡張の path
- Domain-specific vault（科学研究、医学、法律）の可能性

### 9. Limitations and Future Work（1 page）

#### 9.1 Fundamental Limitations
- LLM training distribution に bounded（真の創発は不可能）
- Embodiment / world interaction なし
- Single-user MVP（multi-user は Phase 2）
- No formal inference（OWL レベル厳密性なし）

#### 9.2 Future Work
- **Categorical reformulation（圏論的再構築）**: Spec の operational semantics を圏論的 framework（Olog 等、Spivak 系列）で再記述する研究方向。Functorial data migration による vault 間統合の可能性
- Multi-vault federation（CRDT による merge）
- Domain-specific Hygiene rules（科学領域 vs 法律領域）
- LLM-agnostic interface（Spec 3 prompt-dispatch の generalization）
- Quantitative ontology learning（relations.yml の自動拡張）

### 10. Conclusion（0.5 pages）

3 主貢献の再掲、self-application が示す framework の自己一貫性、PIM の future への含意。

---

## 4. Venue 選定

### Primary candidates

| Venue | 適合度 | 理由 | Acceptance rate |
|-------|:----:|------|---------------|
| **K-CAP** (Knowledge Capture) | ★★★ | KG construction + human-in-the-loop の core 領域 | ~30% |
| **ISWC** (Intl Semantic Web Conf) | ★★★ | RDF / KG / ontology の老舗、reject-only の novelty 評価できる | ~25% |
| **CHI** (Human Factors in Computing) | ★★ | PIM / dogfooding angle、self-application study が刺さる | ~25% |
| **UIST** | ★★ | tool-building 系、より technical | ~25% |
| **AKBC** (Automated KB Construction) | ★★★ | Hygiene / evolution semantics の理論的 contribution | open |

### Secondary candidates

| Venue | 適合度 | 理由 |
|-------|:----:|------|
| **EMNLP / ACL** | ★★ | LLM extraction の technical 部分 |
| **TIIS** (Trans Interactive Intelligent Sys, journal) | ★★ | longer form、self-application の深掘り可 |
| **TOIS** (Trans Information Sys, journal) | ★ | より formal IR 寄り |

### 推奨投稿戦略

**Plan A**: K-CAP または ISWC を primary target
- KG コミュニティに framework の novelty を認識させる
- Reject-only curation の paradigm shift を主張

**Plan B**: 落ちた場合 CHI / UIST に re-target
- Self-application study を中心に書き換え
- HCI / dogfooding angle を強化

**Plan C**: 並行して TIIS journal version を準備
- Conference 版を踏まえた長尺版
- Categorical reformulation 等の future work を含める

---

## 5. 主要 Claims と Threats to Validity

### 主要 Claims

1. **Reject-only curation は input cost を 70-80% 削減**（Exp 1 で実証）
2. **Hygiene は KG 品質を継続的に向上**（Exp 2 で実証）
3. **Curated GraphRAG は baseline RAG より発見的価値が高い**（Exp 3 で実証）
4. **Contradiction preservation は perspective generation を強化**（Exp 4 で実証）
5. **Framework は自身の specification を generate できる**（Exp 5 self-application）

### Threats to Validity

#### Internal validity
- User study の subject 選定 bias（研究者偏重 → general user との差異）
- LLM model choice（Claude vs GPT-4 vs Llama）が結果に影響
- Hygiene parameter（decay rate 等）の tuning が experiment 結果を左右

#### External validity
- Personal scale（500-5000 edges）の検証、enterprise scale で同じ結果が得られるか不明
- Single domain での検証、cross-domain での generalization 不明

#### Construct validity
- "Discovery quality" の subjective 評価が culture / domain 依存
- "Input cost" を時間で測ることが認知負荷を完全に捕捉していない可能性

#### Conclusion validity
- Self-application study の「manual = system」mapping が後付け解釈である可能性
- → 中立 reviewer による mapping の re-evaluation で対処

---

## 6. 圏論的再構築への future direction note

論文 Section 9.2 で言及する future work として、圏論的 framework での再構築を briefly 提案:

- **Olog (Spivak)**: Curated GraphRAG の relations.yml は形式的に Olog の object-morphism 構造に対応する可能性
- **Functorial data migration**: 異なる vault 間の relation type を Functor として翻訳する formalism
- **Profunctor 的 trust gradient**: L1/L2/L3 の trust 関係を categorical lens で記述
- **Hygiene as natural transformation**: 5 ルールを time t での functor 変換として再定義

これは別論文または extended journal 版での主題候補。現論文では:
- Operational semantics で先に framework を確立
- 後続の theoretical paper で圏論的 reformulation
- この順序が自然（先に「動くもの」、後に「形式」）

---

## 7. 執筆スケジュール（仮）

MVP 実装が前提なので、実装後の execution plan として:

| Phase | 期間 | 作業 |
|-------|-----|------|
| Implementation 完了 | T0 | Spec 0-7 implementation 完了（Phase 5 完了相当） |
| Experiment 1-2 | T0 + 1 週 | Input cost study、Hygiene longitudinal start |
| Experiment 3-4 | T0 + 2-4 週 | User study、contradiction comparison |
| Self-application | T0 + 5 週 | この session の artifacts を vault 投入、分析 |
| Hygiene longitudinal 完了 | T0 + 5 週 | 1 ヶ月の経過観察 |
| Draft 執筆 | T0 + 6-9 週 | Section 1-10、figure 作成 |
| Internal review | T0 + 10 週 | 共著者 review、修正 |
| 投稿 | T0 + 11 週 | K-CAP or ISWC deadline 合わせ |

**現実的な timeline**: T0 から 11 週（約 3 ヶ月）で投稿可能。

---

## 8. 必要な準備物

### 実装前に揃えておく
- [ ] Spec 0-7 完成（Phase 5 完了）
- [ ] Reference vault for experiments（科学研究 domain 推奨、edges 1000+）
- [ ] Baseline RAG implementation（比較用、LangChain 等）
- [ ] User study subject 募集（5-10 名、IRB approval 必要なら早めに）

### 論文関連
- [ ] LaTeX template（target venue に応じて）
- [ ] Figures: 3-layer architecture diagram、Hygiene rule flowchart、self-application mapping
- [ ] Open data / code policy（reproducibility のため repo 公開推奨）

---

## 9. リスク要因

| リスク | 影響 | 対処 |
|-------|-----|------|
| LLM の bias / hallucination が experiment 結果を歪める | 中 | Multiple LLM での replication、bias analysis 章追加 |
| User study の subject 数不足 | 中 | Online recruitment、Mturk 経由検討 |
| Hygiene parameter tuning に時間がかかる | 中 | MVP default values で固定、tuning は Future work に |
| Categorical reformulation 議論が時期尚早 | 低 | Section 9 で brief mention のみ、別論文に分離 |
| Reviewer が「self-application は循環論法」と判定 | 中 | Section 7.5 で正直に limitation 議論、外部 reviewer 評価を追加 |

---

## 10. 一行サマリ

> **Curated GraphRAG は personal knowledge management に向けた framework であり、reject-only curation + Hygiene 5-rule evolution + 3-layer trust gradient によって input cost と graph quality の trade-off を解決する。Self-application study が示す通り、framework は自身の specification を generate でき、これは framework が natural cognitive patterns の operational articulation であることを示唆する。**

この一文を Abstract と Conclusion で繰り返し、論文の thread として通す。
