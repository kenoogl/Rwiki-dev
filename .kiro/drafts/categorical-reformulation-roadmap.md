# Categorical Reformulation Roadmap（Draft v0.1）

**Date**: 2026-04-25
**Status**: 将来構想、MVP 完成後に Rwiki v2 自身を用いて実施
**Position**: 論文 1（operational spec）の後続研究、journal extension または独立論文として
**Related**: `.kiro/drafts/paper-outline.md`、`.kiro/drafts/self-application-experiment-plan.md`

---

## 0. なぜ圏論的再構築か

### 現状の Curated GraphRAG（v0.7.11）の性質

- **Operational semantics で記述**: 各 primitive（extraction, Hygiene, reject, etc.）が手続き的に定義されている
- **数式は局所的**: confidence 計算 / usage signal / decay 等は個別に式化されているが、**全体構造の代数性**は明示されていない
- **Spec 間の関係は narrative**: 「Spec 5 が Spec 2 に API 提供」のような依存関係は文章で記述、形式的構造はない

### 圏論的再構築で得られる可能性

| 期待される効果 | 内容 |
|-----------|------|
| **Spec 間関係の代数化** | Spec 0-7 を category として、Spec 間関係を functor として記述。依存関係が形式的に検証可能 |
| **Hygiene の合成則の発見** | 5 ルールの順序実行を natural transformation の合成として記述、可換性 / 結合性が明示 |
| **Trust chain の形式化** | L1 → L2 → L3 を functor chain として記述、trust の伝播を categorical lens で正確に扱う |
| **Multi-vault federation の理論基盤** | 複数 vault の統合を colimit / pushout として定義 |
| **Verify ロジックの厳密化** | Hypothesis verify の「supporting / refuting / partial」判定を partial order or lattice として形式化 |
| **Reject-only filter の双対性** | Active learning との形式的対照を adjoint functor で表現 |

### 但し、operational spec を**置き換える**のではない

- Operational spec は実装者向け、categorical 再構築は理論研究者向け
- 両者は **同一の framework の異なる abstraction layer**
- Operational が ground truth、categorical はその formal lifting

---

## 1. 既存研究（categorical knowledge representation）

### 1.1 Spivak's Olog (Ontology log)

- **Spivak (2012)**: "Category theory for the sciences"
- Olog = labeled directed graph + commutative diagrams + classification
- 各 object が「概念のクラス」、各 morphism が「関係」
- **Rwiki との対応**: Entity ≈ Olog object、Typed edge ≈ Olog morphism、relations.yml ≈ Olog の commutative law

### 1.2 Functorial Data Migration

- **Spivak (2012-2014)**: 異なる schema 間の data 移行を functor として記述
- データベース schema を category として、schema migration を functor として
- **Rwiki との対応**: Vault 間の relation type translation、Phase 進行（P0 → P1）の data shape 変化

### 1.3 Categorical Databases

- **Schultz, Spivak, et al.**: Algebraic data integration
- SQL を Cat 内の operation として再記述
- **Rwiki との対応**: edges.jsonl ↔ sqlite の関係、append-only ledger の formal モデル

### 1.4 Algebraic Theory of Knowledge Graphs

- Knowledge graph completion を category-theoretic に扱う最近の研究
- TransE / RotatE 系を group action として再記述
- **Rwiki との対応**: 6 係数加重 confidence を tensor product として？

### 1.5 Argumentation in Categorical Setting

- Dung argumentation の categorical formalization 研究
- Acceptable extensions を fixed point として記述
- **Rwiki との対応**: Contradiction tracking の preserve principle

---

## 2. Rwiki v2 の categorical lifting 仮説（要検証）

以下は **作業仮説**。MVP 後に Rwiki v2 自身を用いて検証・refine する。

### Hypothesis 1: 各層は category

```
L1_t  : objects = raw files at time t
        morphisms = revisions / lint passes / category transitions

L2_t  : objects = entities (identified)
        morphisms = typed edges (with confidence as enrichment)

L3_t  : objects = wiki pages
        morphisms = links (typed via L2 cache)
```

**含意**: 各層は **time-indexed category**（presheaf over time）

### Hypothesis 2: 層間遷移は functor

```
F_extract : L1_t → L2_t       (LLM 抽出)
F_approve : L2_t → L3_t       (人間承認)
F_sync    : L2_t → L3_t       (related: cache sync)
F_evidence : L3 → L1           (sources: 逆参照)
```

**含意**: 3 層は **adjoint pair / triple** を成す可能性

### Hypothesis 3: Hygiene は endofunctor + natural transformation

```
H_decay         : L2_t → L2_{t+δ}    (時間進行)
H_reinforce    : L2_t → L2_t        (usage signal 反映)
H_competition  : L2 → L2             (winner 選定)
H_contradict   : L2 → L2_with_marks  (矛盾保持)
H_merge        : L2 → L2_simplified  (統合)
```

5 ルールの **固定実行順** は natural transformation の合成順序として記述可能。

**含意**: 「実行順序が固定なのは、ある合成則を満たさないから」を形式的に証明できる

### Hypothesis 4: Reject-only filter は adjoint

```
Approve : 候補 → 承認         (left adjoint? 自由構築)
Reject  : 候補 → 拒絶          (right adjoint? 必要最小限)
```

Active learning との **双対性**を形式化:
```
Active learning  ⊣ Reject-only?
（前者は質問、後者は拒絶のみ）
```

**含意**: Reject-only paradigm の formal characterization

### Hypothesis 5: Confidence は enriched category の hom-set

各 edge の confidence ∈ [0, 1] を **enriched morphism** として:
```
Hom(A, B) ∈ [0, 1]   (V-enriched category over [0,1])
```

Hygiene による confidence 進化 = enrichment の time evolution。

**含意**: Probabilistic / fuzzy KG との接続

### Hypothesis 6: Multi-vault federation は colimit

```
Vault_alice ──┐
               ├─→ Vault_merged   (colimit / pushout)
Vault_bob   ──┘
```

CRDT の formal semantics と接続。

**含意**: Phase 2 multi-user 拡張の理論基盤

### Hypothesis 7: Self-application は endofunctor

```
S : Curated_GraphRAG → Curated_GraphRAG
    (system が自身を ingest して再生成)
```

Section 7.5 self-application study が **存在を示す** S が一意か、fixed point を持つか、等の問い。

**含意**: Auto-generative property の形式的定式化

### Hypothesis 8: Curation provenance は profunctor / decoration

§2.13 で導入された decision_log は、edges.jsonl と evidence.jsonl の **両方を indexing する**追加層:

```
P : (Decision)^op × (Edge | Page | Hypothesis) → Set
    decision_log entry が「対象（edge / page / hypothesis）に対する判断」を記述
```

または **decorated category** として、category Edges / Pages の各 morphism / object に decision_log の記録を decoration として付加。

**圏論的問い**:
- Curation provenance は trust chain（vertical functor chain）に対する **horizontal categorical structure** か
- Decision_log の context_ref は **lax functor** として記述可能か
- Self-application（H7）と curation provenance（H8）の合成が monad を成すか

**含意**: 「what」と「why」の二層構造を categorical lens で正確に記述、§2.10 と §2.13 の orthogonality を formal に証明

---

## 3. Rwiki v2 を用いた reformulation の手順

これが本提案の核心: **categorical reformulation を Rwiki v2 自身で実施する**。

### Phase A: Categorical literature の vault 投入

```bash
rw init ~/rwiki-categorical-vault

# Categorical literature を raw に投入
cp papers/spivak-2012-olog.pdf ~/rwiki-categorical-vault/raw/papers/
cp papers/spivak-2014-functorial-data-migration.pdf ~/rwiki-categorical-vault/raw/papers/
cp papers/schultz-spivak-algebraic-data.pdf ~/rwiki-categorical-vault/raw/papers/
cp books/maclane-categories-for-working-mathematician/ ~/rwiki-categorical-vault/raw/books/
cp papers/awodey-category-theory.pdf ~/rwiki-categorical-vault/raw/books/
# argumentation, fuzzy KG, CRDT 関連も投入
```

### Phase B: Rwiki v2 自身の spec を vault に投入

```bash
cp .kiro/drafts/rwiki-v2-consolidated-spec.md \
   ~/rwiki-categorical-vault/raw/specs/

# 既存 categorical 文献と spec が同じ vault に同居
```

### Phase C: 抽出と graph 構築

```bash
rw extract-relations --scope=all
rw audit graph
```

**期待される自動抽出**:
- categorical primitive entities: object, morphism, functor, natural-transformation, monad, adjoint, ...
- Rwiki primitive entities: layer, edge, hygiene-rule, confidence, ...
- **両者を結ぶ candidate edges** が抽出される（co_occurrence ベース、initial confidence 低）

### Phase D: Perspective / Hypothesis で connections を探索

```bash
# 大局視点
rw perspective "Rwiki v2 と圏論の対応関係" --scope=global --save

# 仮説生成
rw hypothesize "Hygiene 5 ルールの categorical formalization"
rw hypothesize "L1/L2/L3 trust chain の functor representation"
rw hypothesize "Reject-only filter の adjoint pair"
rw hypothesize "Self-application を endofunctor として定式化"
```

これにより **§2 で挙げた 7 hypothesis に対応する候補 edges** が surface される。

### Phase E: Verify と refinement

```bash
# 各 hypothesis を学術文献で verify
rw verify hyp-hygiene-categorical
rw verify hyp-trust-chain-functor
rw verify hyp-reject-adjoint
rw verify hyp-self-app-endofunctor
```

検証フロー（Spec 6 の半自動 4 段階）:
1. LLM が Spivak / Awodey 等の文献から evidence 候補を抽出
2. 人間（圏論の知識を持つ研究者）が supporting / refuting / partial / none 評価
3. LLM が集約判定
4. confirmed hypothesis は categorical formulation の seed として採用

### Phase F: 形式的 reformulation の起草

Verified hypothesis をもとに paper を起草:
- Hygiene を natural transformation として記述
- 3-layer trust gradient を functor chain として記述
- Reject-only を adjoint として証明（または反証）

### Phase G: Reformulation を spec に back-port（optional）

形式化が安定したら、operational spec の各 section に **categorical 注釈**を追加:
```markdown
### 2.12 Evidence-backed Candidate Graph

**Operational definition**: ...

**Categorical interpretation** (§ Categorical Reformulation 参照):
L2 は V-enriched category over [0,1]、confidence は hom-set の enrichment。
Hygiene rules R = {Decay, Reinforcement, ...} は endofunctor の合成
H = R_merge ∘ R_contradict ∘ R_compete ∘ R_reinforce ∘ R_decay として
記述される。
```

これは MVP 完了後の **v2.1 / v2.2** に向けた spec refinement。

---

## 4. 期待される論文構成（圏論的再構築 paper）

**Title 仮**: "A Categorical Foundation for Curated GraphRAG: Functor-Based Trust Gradients and Hygiene as Natural Transformations"

**Sections**:
1. Introduction
   - Curated GraphRAG operational spec (paper 1) からの follow-up であることを明示
2. Related Work
   - Spivak Olog, Functorial data migration, Categorical databases
3. Preliminaries
   - Category, functor, natural transformation, enriched category, adjoint
4. **Categorical Lifting of Curated GraphRAG**
   - 4.1: Three-layer trust gradient as functor chain
   - 4.2: Hygiene as natural transformation
   - 4.3: Reject-only as adjoint to active learning
   - 4.4: Confidence as enrichment over [0,1]
   - 4.5: Self-application as endofunctor
5. **Implementation via Rwiki v2 Self-Discovery**（独自貢献）
   - Phase A-G の手順
   - 5 hypothesis のうち何件が verified か
   - Latent connections の発見（Spivak 文献から想定外の接続）
6. Discussion
   - Operational spec と categorical lifting の異形性 / 同形性
   - Federation の colimit / pushout 定義
7. Future Work
   - Higher-order categorical structures（2-categories for Hygiene rule changes）
   - Topos-theoretic foundation（intuitionistic logic for partial verification）

**Venue**:
- **Primary**: TAC (Theory and Applications of Categories) or LiPIcs CALCO
- **Secondary**: AKBC, ISWC（よりapplied 寄りに書き換えて）
- **Tertiary**: TIIS journal（前 paper の continuation として）

---

## 5. なぜ Rwiki 自身で実施するのが意義深いか

### (a) Auto-generative property の higher-order 実証

論文 1 の Section 7.5 では framework が自身の **operational spec** を rediscover した。
論文 2 では framework が自身の **theoretical formalization** を discover する。

これは **second-order self-application** であり、framework の generative reach の検証。

### (b) Categorical literature を「外部 corpus」として扱える

圏論文献を raw に投入 → Rwiki が抽出 → 既存 spec 内の概念と connection を提案。
これは **「LLM が圏論文献から自分自身の構造を発見する」** 実験。

仮に system が "Hygiene ─is_natural_transformation_of→ ..." のような edge を提案できれば、
それは operational primitive と categorical structure の橋を **system が自動発見した** ことになる。

### (c) Operational と categorical の bridge を natural な形で構築

人間が手動で「Hygiene は natural transformation だ」と主張するのではなく、
**system が両者の relation を candidate edge として提案** → 人間が verify → 採用。

これは Curated GraphRAG の本来の使い方であり、framework の正当な application。

### (d) 知的誠実さの担保

人間が categorical mapping を作ると confirmation bias が入りやすい（前回議論で指摘）。
Rwiki に発見させることで、**bias の混入を技術的に減らせる**。

System が抽出できなかった対応は「無理筋」、抽出できた対応は「natural」と判定可能。

---

## 6. 想定 timeline

論文 1（operational spec、Section 7.5 含む）を T0 に投稿として:

```
T0:        論文 1 投稿（K-CAP / ISWC）
T0 + 2 ヶ月: 論文 1 review 待ちの間に Rwiki v2 implementation 安定化
T0 + 3 ヶ月: Categorical literature の vault 構築開始（Phase A-B）
T0 + 4-6 ヶ月: Phase C-E（extract / perspective / verify）
T0 + 7-9 ヶ月: 論文 2 起草（Phase F、形式化作業）
T0 + 10 ヶ月: 論文 2 投稿（TAC / CALCO / extension）
```

論文 1 の acceptance / rejection 結果と並行して論文 2 の準備が進む。

---

## 7. リスクと留意点

### Risk 1: 圏論的 lifting が trivial に終わる

**問題**: 「単に Hygiene を functor と書き換えただけ、insight なし」と reviewer に言われる。

**Mitigation**:
- Adjoint の発見、colimit 構造の活用、enrichment の応用など、**categorical 構造から得られる operational insight**を必ず示す
- 例: 「H_decay と H_reinforce が adjoint pair なら、両者の合成が monad を成し、Hygiene 全体が **monad on L2** として記述可能。これは Phase 3 の Edge Merging 設計を予測する」

### Risk 2: Rwiki が categorical edges を抽出できない

**問題**: 「Hygiene ─is─ natural transformation」のような meta-level edge を LLM extraction が捕捉できない可能性。

**Mitigation**:
- relations.yml に圏論固有 relation type を予め定義（is_functor_of, is_natural_transformation_of, is_adjoint_to 等）
- extraction prompt を圏論用に specialized
- 抽出結果が薄い場合は人間補完して **system support の effectiveness** を限界として正直に報告

### Risk 3: 圏論の knowledge を持つ user が必要

**問題**: Verify phase で評価できる人間が limited（圏論専門家）。

**Mitigation**:
- 共著者として圏論研究者を招く
- または categorical analyst LLM agent を併用（GPT-4 with category theory prompts）

### Risk 4: 論文 1 と 論文 2 の独立性

**問題**: 論文 1 が rejection されると論文 2 も reformulation 対象がない（論文 1 が前提）。

**Mitigation**:
- 論文 2 は論文 1 の operational spec を **既知前提** として扱い、formal foundation を独立に提示
- 仮に論文 1 が venue を変えて re-submit になっても、論文 2 は self-contained に書ける構成にする

---

## 8. Open questions

実施前から認識している不確定要素:

1. **Hygiene 5 ルールの実行順序が固定なのは、ある合成則を満たさないからか、それとも単に operational 理由か** — categorical 解析で明らかにしたい
2. **Reject-only filter は本当に active learning と adjoint pair を成すか、それとも別の categorical 関係（duality、coalgebra など）か**
3. **Self-application S : RG → RG が fixed point を持つとして、それは何を意味するか**（spec の "完成" の categorical 定義？）
4. **Trust gradient L1 → L2 → L3 が functor chain だとして、forgetful 方向（L3 → L1）は left/right adjoint か** — evidence chain の categorical 性質
5. **Multi-vault federation の正しい categorical 構造は colimit か pushout か pullback か** — vault 間の独立性 / 共有関係に依存

これらは MVP 後の実験で順次明らかにする問い。

---

## 9. 圏論的アプローチが**現 spec を否定しない**ことの確認

重要な点: categorical reformulation は operational spec を**置き換えない**。

```
operational spec  ←→  categorical lifting
   (実装者向け)        (理論研究者向け)
   ground truth        formal abstraction
```

両者は同じ framework の異なる layer。Operational spec は不変、categorical lifting はその上に構築される。

この階層を明示することで:
- 実装者は operational spec のみ参照すれば OK
- 理論家は categorical lifting で正確な性質を議論
- 両者の翻訳は spec 末尾の「categorical interpretation」注釈で連結

---

## 10. 一行サマリ

> **MVP 完成後、Rwiki v2 自身に圏論文献を ingest して categorical reformulation を発見させる。これは second-order self-application であり、framework が自身の theoretical foundation を生成できるかをテストする。論文 1（operational spec）の continuation として論文 2（categorical foundation）を起こし、Curated GraphRAG が "discovery, not invention" であることを更に強化する。**

---

## 11. 関連 doc 内で本 doc を参照する場所

- `paper-outline.md` §9.2 Future Work: 圏論的再構築への future direction として briefly 言及（既存）
- `self-application-experiment-plan.md` §9 Open questions: granularity / time-ordering / endofunctor 視点として briefly 言及（既存）
- 本 doc: detailed roadmap

論文 1 では本 doc の内容を **future work で 1 段落のみ言及**するに留める。論文 2 を書く時に本 doc を起点にする。
