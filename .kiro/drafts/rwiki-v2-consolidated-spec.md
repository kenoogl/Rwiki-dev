# Rwiki v2 統合仕様書（Draft v0.7.12）

**Status**: 議論統合、各 Spec 起票前のドラフト（3 層 + Curated GraphRAG + 入力コスト問題.md 完全取込 + §2 中核原則の層別適用整理 + §2.6 履歴媒体の層別整理 + Edge management / Hygiene 運用ポリシー追記 + 用語集完全版 + Spec 5/6 起票前 preparatory 議論の 6 決定を反映 + §9 実装戦略再構築 + §2.13 Curation Provenance 新設）
**Date**: 2026-04-25
**Scope**: 3 層アーキテクチャ（L1 Raw / L2 Graph Ledger / L3 Curated Wiki）の確定、Curated GraphRAG としての哲学明示（§1.3）、GraphRAG から採り入れる 4 技法の明示（§1.3.3）、12 中核原則（§2.12 Evidence-backed Candidate Graph 含む、confidence 6 係数加重式・閾値 3 段階・却下代替案も明記）、Scenario 7-8, 11-12, 14-17, 19-20, 25 の合意内容、Spec 0-7 の要件骨子（Usage 4 種別・Competition 3 レベル・実装 4 Phase 含む）
**Out of Scope**（詳細化は次セッション以降）:
- Scenario 9（ページ分割）、10（audit fix loop）、13（evidence 検証）、18（pre-flight）、26（lint-fail recovery）
- Scenario 34-38（Entity/Relation 抽出、Edge reject、Graph Hygiene 実行、Edge lifecycle 管理、Edge events 監査）
- Scenario 33（Maintenance UX 全般原則、骨子のみ確定、詳細シーン要議論）

参考情報：[シナリオ](rwiki-v2-scenarios.md)

---

## 1. ビジョンと価値提案

### 1.1 Karpathy の LLM Wiki から継承するもの

Rwiki は [Andrej Karpathy 氏の LLM Wiki アイデア](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) に着想を得ている。中核コンセプト：

- **知識は一度コンパイルし、継続的に保守する**（毎クエリで再検索しない）
- **人間は戦略・判断、LLM は統合・構造化の実務**
- **Git で管理される markdown リポジトリ**
- **Vannevar Bush の Memex を LLM で現代化**

### 1.2 Rwiki 独自の中核価値

**Rwiki = Trust + Graph + Perspective + Hypothesis の四位一体**

```
Trust:       人間承認と evidence chain で裏付けられた wiki 知識
Graph:       typed edges を持つ知識グラフ構造
Perspective: LLM がグラフを traverse してユーザー単独では気づかない視点を提示
Hypothesis:  LLM が既存 wiki から未検証の仮説・新しい洞察を生成、検証ワークフローに供給
```

LLM 単体でも wiki 単体でもなく、**両者の統合**によってのみ実現できる知的生産形態。

**Perspective と Hypothesis の違い**:

| 軸 | Perspective（視点創発） | Hypothesis（仮説生成） |
|----|---------------------|---------------------|
| 性質 | 既存 wiki 知識の**再解釈・関係性発見** | 既存 wiki から導かれる**未検証の新命題** |
| Trust chain | 維持される（wiki を引用） | 仮説は検証前、`[INFERENCE]` マーカー必須 |
| 出力例 | 「A と B は同じ原理の別表現」「支持 evidence 3 件、反論 evidence 2 件」 | 「A と C を組み合わせると D が予測できる」「まだ wiki にないが検証価値あり」 |
| 後続アクション | そのままレビュー論文素材等に再利用 | raw/ に戻って裏付け・反証、検証後に wiki 昇格候補 |
| 位置付け | 知識の**深化・整理** | 知識の**前進・拡張** |

両者は LLM × Graph の同じメカニズムから生まれるが、**出力形態と後続ワークフローが異なる**。Spec 6（perspective-generation）で両者を統合的に扱う。

### 1.3 Curated GraphRAG としての位置付け

#### 1.3.1 GraphRAG の系譜と Rwiki のスタンス

近年の **GraphRAG**（Microsoft Research 2024 を起点に LightRAG 等の派生）は、テキストから entity と relation を自動抽出して graph を構築し、それを RAG の検索粒度として活用する手法群である。Rwiki は **特定の GraphRAG 実装／ライブラリを採用しない**。ただし「グラフ構造を知識表現の一等市民として扱う」という設計思想には深く共鳴する。

Rwiki が採るのは **Curated GraphRAG** — 自動抽出 graph を認めつつ、そこに**人間キュレーション層**と**継続進化機構**を組み込んだ変種である。

**ワンライン定義**:

> Rwiki は **「Curated Knowledge Graph に対する探索・発見システム」** である。LLM は graph を育て、人間は graph を方向づけ、Hygiene が graph を進化させる。

**通常 GraphRAG との対比（ポジショニングジャンプ）**:

| 軸 | 通常の GraphRAG | **Rwiki v2 (Curated GraphRAG)** |
|----|---------------|------------------------------|
| 起点 | 未整理テキスト → LLM が graph 化 | **既に整理済 wiki** と **候補 graph** の二層を併走 |
| 主体 | LLM 中心 | **人間承認中心**（L3）+ LLM 抽出補助（L2） |
| 品質 | 自動抽出ノイズを含む | **Reject-only + Hygiene + Evidence 裏付け**で高信頼 |
| 用途 | RAG 検索粒度の強化 | 検索 + **Perspective/Hypothesis 生成**（探索・発見） |
| 知識の時間変化 | 基本静的 | **evolving**（使用で育ち、不活性で痩せる） |

#### 1.3.2 意図: 従来型 GraphRAG の限界と処方

**従来型 GraphRAG の構造的な弱点**:

| 弱点 | 問題の本質 |
|------|----------|
| 自動抽出ノイズ | LLM は誤った entity/relation を必ず生成する。検索時に混入して精度劣化を招く |
| 文脈ズレ | 抽出された relation の「意味の強さ」が一様に扱われる（仮説レベルと確定事実を区別できない） |
| 静的な graph | 一度構築された graph は古い情報・誤り情報を抱えたまま放置される |
| 裏付け不足 | edge の根拠となる evidence が graph に紐付かず、信頼性を検証できない |

**Rwiki の処方**:

- **L2 Graph Ledger（候補 graph）**: 自動抽出を否定せず、全てを「候補 edge」として一旦受け入れる。拒絶は後で行う
- **Reject-only 人間フィルタ**: 全件 approve は要求しない。ユーザーは**不適切な edge だけを reject** する軽量作業
- **Hygiene による継続進化**: perspective / hypothesize で使われた edge は reinforcement、使われない edge は decay、矛盾する edges は競合解決
- **Evidence-backed**: 全 edge は evidence.jsonl への参照を持ち、confidence は evidence の数・質・再現性から算出
- **L3 Curated Wiki（trust 層）**: 人間承認済み markdown ページが最終的な trust 源。L3 frontmatter の `related:` は L2 ledger からの derived cache
- **3 層 trust chain**: L1 raw → L2 ledger → L3 wiki を edge_id / evidence_id で任意段階まで逆追跡可能

#### 1.3.3 GraphRAG から採り入れる 4 技法

通常の GraphRAG が発明したグラフ上の発見・要約アルゴリズムのうち、**Rwiki が採り入れる**のは以下 4 技法。実装所管は Spec 5（L2 query API）および Spec 6（Perspective / Hypothesis）に分かれる。

| 技法 | 役割 | Rwiki での用途 | 所管 |
|------|-----|--------------|------|
| **Community detection** | 関連 entity を cluster 化（louvain 等） | Perspective で同一 community 内の類似手法を surface、Hypothesis で cluster 間の missing bridge 探索 | Spec 5 |
| **Global query** | 特定 node 起点ではなく、graph 全体・大局 scope の集約 query | 「この分野全体の主要手法を俯瞰したい」のような大局視点生成 | Spec 5 + Spec 6 |
| **Missing bridge detection** | 関連性が疑われるが edge が無い組合せを検出 | Hypothesis の主要源泉（「A と C を結ぶ edge がまだない → 仮説候補」）、Scenario 14 パターン C | Spec 5 + Spec 6 |
| **Hierarchical summary（on-demand）** | community 単位で要約を動的生成（事前構築しない） | 大規模 graph 俯瞰時の認知負荷低減、perspective での上位ビュー | Spec 5 + Spec 6 |

**事前構築しない原則**: 従来 GraphRAG は index 時に community summary を事前構築する場合が多いが、Rwiki は **on-demand** で生成する。理由は (a) graph が evolving なので事前構築が陳腐化しやすい、(b) 必要な時だけ LLM を呼べばコストを抑えられる、(c) Hygiene 後の最新状態を反映できる。

#### 1.3.4 メリット

| メリット | 具体内容 |
|---------|---------|
| **入力コストの劇的低減** | 旧来の「全件 approve 必須」を reject-only に緩和。知識蓄積のボトルネックを排除 |
| **Recall と Precision の両立** | L2 は recall 重視（広く拾う）、L3 は precision 重視（人間承認）の二層制で役割分担 |
| **知識の自己進化** | Hygiene により不活性 edge は自然に deprecate、活性 edge は core 化。human intervention なしで graph の品質が時間で向上 |
| **Perspective / Hypothesis の源泉** | L2 の weak/candidate edges が「まだ人間が気づいていない関係性」の発掘地。従来の wiki には書かれない前景候補を LLM が surface |
| **透明な trust chain** | 任意の wiki 記述・perspective・hypothesis から evidence・raw ソースまで一貫して辿れる。hallucination との差別化 |
| **LLM 非依存の知識資産** | graph は Rwiki Vault に閉じた JSONL / markdown の集合。LLM を乗り換えても知識資産は残る |

#### 1.3.5 哲学（設計信念）

1. **Graph は static ではなく evolving** — 知識グラフは「作って終わり」ではなく、使用で育ち、不活性で痩せる生きた構造
2. **Evidence が graph を裏付ける** — edge は単独では成立しない。必ず evidence に紐付く。evidence.jsonl は first-class concept
3. **人間の役割は戦略判断と reject、方向付け** — 単純承認作業は Hygiene が代行。人間は graph の方向性と拒絶の判断に集中
4. **知識の正誤は時間の関数** — 古い知識は deprecate 可能。失敗・反証も記録として残す（Karpathy 思想「失敗からも学ぶ」）
5. **LLM は抽出・統合・surface の実務者、人間は編集者・方向性決定者** — Karpathy 哲学の継承。LLM は graph を育て、人間は graph を方向づける
6. **「recall を上げる」ではなく「使われる知識を残す」** — 全ての knowledge が同価値ではない。使用 signal で価値を計測

### 1.4 他の手段との差別化

| 手段 | Rwiki との違い |
|------|-------------|
| 素の LLM チャット | 学習データのみ、hallucination、検証不可 |
| RAG（通常） | 未キュレートのチャンク引用、graph 構造なし、視点創発なし |
| GraphRAG（通常） | 自動抽出 graph のみ、人間キュレーション層なし、Hygiene なし、知識劣化対策なし |
| 汎用ノートツール（Obsidian / Notion 等） | パイプライン・品質保証・LLM 連携・graph 自動進化なし |
| **Rwiki（Curated GraphRAG）** | **候補 graph（L2）+ 人間承認 wiki（L3）+ Hygiene + Evidence chain + Perspective/Hypothesis 生成** |

### 1.5 想定ツール・前提環境

Rwiki はコマンドライン + 対応ツール群の組み合わせで動作する。以下は想定する環境（**参照実装**を括弧内に示す）。

**必須（Required）**:

| ツール | 役割 | 参照実装 |
|------|------|---------|
| **Git** | バージョン管理、trust chain の保全 | git 2.x |
| **Python ランタイム** | `rw` CLI の実行環境 | Python 3.10+ |
| **LLM CLI インターフェイス** | `distill` / `query` / `audit semantic` / `extract-relations` 等で使用 | Claude Code、OpenAI Codex、他 LLM CLI（MCP 経由含む） |
| **Markdown エディタ** | 候補ファイル・wiki の編集 | 任意の markdown エディタ（vim、VSCode、Obsidian 等） |

**Python 依存（標準 + 追加）**:

| パッケージ | 用途 | 備考 |
|-----------|-----|------|
| `sqlite3` | `.rwiki/cache/graph.sqlite` — L2 ledger の derived cache | Python 標準ライブラリ |
| `networkx` ≥ 3.0 | Graph 操作（community detection / traverse algorithms） | 追加依存（Spec 5） |

**推奨（Recommended）**:

| ツール | 役割 | 備考 |
|------|------|------|
| **Obsidian** | Vault 閲覧・編集、Daily Note、Graph view、Backlinks、Dataview によるfrontmatter 駆動クエリ | 責務分離については §2.7・§8 参照 |
| **シェル環境** | CLI 操作 | bash / zsh / fish 等 |

**任意（Optional、将来連携予定）**:

| ツール | 役割 |
|------|------|
| Zotero | 論文管理からの自動取り込み（`rw sync-from-zotero`、roadmap） |
| Web clipper | ウェブ記事の markdown 取り込み（Obsidian plugin 等） |
| Obsidian プラグイン | `rw` コマンドの Command Palette 統合（roadmap） |

**LLM 実装の独立性**: Rwiki は特定 LLM に依存しない。Claude Code は参照実装であり、同等の機能を持つ LLM CLI（ツール呼出・ファイル読み書き・対話型プロンプト）であれば差し替え可能。LLM 切替のための抽象層は Spec 3（prompt-dispatch）で定義する。

**エディタ実装の独立性**: Rwiki 自体はエディタ非依存。Obsidian は推奨だが必須ではない。生成される markdown ファイルは任意のエディタで編集可能。

---

## 2. 中核原則

v2 の設計は以下 **13 原則（§2.1-§2.13）** に基づく。ただし **全原則が全層に一律適用されるわけではない** — 3 層アーキテクチャ（L1 Raw / L2 Graph Ledger / L3 Curated Wiki、§3 参照）では層ごとに LLM の裁量範囲と人間関与の度合いが大きく異なるため、原則の適用範囲も層別になる。

### 2.0 原則の層別適用マトリクス

入力コスト問題解決（§1.3.2）と Curated GraphRAG 哲学（§1.3.5）の帰結として、**層が違えば人間と LLM の関与モデルが違う**。以下は各原則の層別適用度：

| # | 原則 | L1 Raw | L2 Graph Ledger | L3 Curated Wiki | 備考 |
|---|------|:------:|:---------------:|:---------------:|------|
| §2.1 | Paradigm C（対話+エディタ） | — | — | ✅ | L1/L2 はエディタ直編集または自動、対話編集は L3 候補対象 |
| §2.2 | Review layer first | △ lint のみ | ❌ 適用外 | ✅ 必須 | **L2 は §2.12 reject-only が優先**、L1 は raw に直接書く |
| §2.3 | Status frontmatter over directory | — | ❌ Edge status で管理 | ✅ Page status | Edge/Page は別次元（用語集 §4.3） |
| §2.4 | Dangerous ops 8 段階 | — | ❌ 適用外 | ✅ 対象 | L2 は §2.5 Simple か §2.12 reject-only |
| §2.5 | Simple dangerous ops | — | ✅ edge reject/unreject | ✅ unapprove/reactivate | L2 の edge 操作は全て Simple |
| §2.6 | Git + 層別履歴媒体 | ✅ Git log のみ | ✅ edge_events.jsonl | ✅ frontmatter update_history | 補助媒体が層ごとに異なる、sqlite cache は gitignore |
| §2.7 | エディタ責務分離 | ✅ | △ sqlite/JSONL は Rwiki 管理 | ✅ | L2 はエディタ対象外（人間が直接編集しない） |
| §2.8 | Skill library | — | ✅ extract-relations / reject_learner | ✅ distill 系 | 層境界を跨ぐ変換の出力形式 |
| §2.9 | Graph as first-class | — | ✅ **正本** | △ derived cache | L3 の `related:` は L2 から生成 |
| §2.10 | Evidence chain | ✅ 起点 | ✅ evidence.jsonl 集約 | ✅ `sources:` | 全層を貫く唯一の不変原則 |
| §2.11 | Discovery primary / Maintenance LLM guide | ✅ | ✅ | ✅ | 全層共通、ユーザー UX 原則 |
| §2.12 | Evidence-backed Candidate Graph | — | ✅ **独占適用** | — | L2 専用、§2.2 / §2.4 より優先 |
| §2.13 | Curation Provenance | △ lint pass のみ | ✅ decision_log.jsonl | ✅ approve 時に reasoning 必須 | 「なぜ」の記録、selective recording で volume 抑制 |

**凡例**: ✅ 完全適用 / △ 限定適用 / ❌ 適用外（他原則が優先） / — 該当しない

**最重要の帰結**:

- **L2 Graph Ledger では §2.2 / §2.4 より §2.12 が優先**。LLM 自動抽出 → append-only JSONL → reject-only filter、review layer を経由しない。Hygiene（Decay / Reinforcement / Competition / Contradiction tracking / Edge Merging）で自律進化
- **L3 Curated Wiki は従来型**。全変更は review/ 層経由、approve 必須、dangerous op は 8 段階対話
- **L1 Raw は人間領域**。lint のみ、パイプラインが自動変換しない
- **§2.10 Evidence chain のみ全層を貫く**（trust の基盤、層を超えても切れない）

この層別適用により、**Curated GraphRAG の中核思想**（LLM 中心 + reject-only + Hygiene = L2、人間承認中心 = L3）と v2 の運用原則が整合する。

### 2.1 対話 + 直接編集のハイブリッド方式（Paradigm C）

候補ファイルへの編集方式として 3 つの選択肢があり、Rwiki v2 は**統合型（C）**を採用する：

| 方式 | 内容 | 長所 | 短所 |
|------|------|------|------|
| **Paradigm A**（対話のみ） | LLM への自然言語指示だけで修正 | 迅速、対話ログが残る | 構造変更が伝えづらい、細部を指示しにくい |
| **Paradigm B**（ファイル編集のみ） | 候補ファイルを markdown エディタで直接編集 | 全体俯瞰可能、自由度高 | エディタへの行き来の手間 |
| **Paradigm C**（ハイブリッド、採用） | 両者を自由に切り替え・併用 | 場面に応じて最適な手段 | 選択の判断が必要 |

**Paradigm C の運用**:

- LLM が生成した候補は **常にファイルとして出力される**（`review/*_candidates/`）
- 小さな修正・言い回し調整 → LLM への自然言語指示で再生成
- 構造変更・複数セクション再編 → markdown エディタで直接編集
- 両者の混在（対話で部分修正 → 直接編集で残り → 再度対話）も自由
- 最終的な反映は `rw approve` 等で一括実行される（候補ファイルが `wiki/` に昇格）

この方式は、本 Draft で合意した全ての dangerous operations（シナリオ 7/8/11/12/19/20）に共通する編集モデルとなる。

### 2.2 Review layer first（L3 限定）

**適用範囲**: L3 Curated Wiki への変更に限定。L2 Graph Ledger は §2.12 の Reject-only + Hygiene に従う（review layer 経由**しない**）。L1 Raw は lint のみ。

**L3 に対する運用**: 全変更は一度 `review/` 層を経由する：

```
review/synthesis_candidates/  ← distill の出力
review/query/                 ← query の 4 ファイル契約
review/skill_candidates/      ← custom skill 草案
review/vocabulary_candidates/ ← tag vocabulary 変更計画
review/audit_candidates/      ← audit 修復提案
review/relation_candidates/   ← L2 抽出提案のうち typed 提案 → L3 frontmatter 反映対象
review/hypothesis_candidates/ ← Hypothesis 候補（Scenario 14）
review/perspectives/          ← Perspective 保存版（`--save` 時）
```

`review/` 層は **L3 への人間レビューの場**。approve で L3 に反映されるまで可逆。

**L2 には適用されない理由**: L2 edges.jsonl は LLM 自動抽出の append-only ledger。全件 review を要求すると入力コスト問題（§1.3.2）が再発するため、**reject-only filter + Hygiene 自己進化**に設計思想が転換されている（§2.12）。

### 2.3 Status frontmatter over directory movement

ページの状態変化は**ディレクトリ移動ではなく frontmatter で管理**：

```yaml
status: active | deprecated | retracted | archived | merged
```

理由：
- ディレクトリ移動はパスずれで既存リンクを破壊
- エディタ側の検索・グラフ機能（Obsidian 等）が二重管理になる
- evidence chain が切れやすい

### 2.4 Dangerous operations の対話ガイド（8 段階、L3 対象）

**適用範囲**: **L3 Curated Wiki** の不可逆操作に限定。L2 Graph Ledger の edge 操作（reject / unreject）は §2.5 Simple dangerous op または §2.12 reject-only workflow に従う（8 段階対話は不要）。

**L3 で 8 段階対話が必須となる操作**: `deprecate` / `retract` / `merge`（wiki page 統合）/ `split` / `tag merge` / `skill install` / `hypothesis approve`（wiki/synthesis/ への promote、Scenario 14）/ `query promote`（Scenario 16）等

**共通の 8 段階チェックリスト**:

1. 意図確認
2. 現状把握
3. 依存グラフ解析
4. 代替案の提示
5. 各参照元の個別判断
6. Pre-flight warning
7. 差分プレビュー生成（review 層）
8. 人間レビュー → approve

**L2 で 8 段階が不要な理由**: L2 edges は LLM 自動抽出された候補集合であり、1 件あたりの判断コストを低く保つ必要がある。reject は 1-stage confirm（Scenario 35）、unreject は軽微な状態変更、Hygiene は自動バッチ処理（Scenario 36）。これにより reject queue の消化が現実的に行える。

### 2.5 Simple dangerous operations（L3 の軽量操作 + L2 edge 操作）

**適用範囲**: L3 の可逆操作（`unapprove` / `reactivate`）および **L2 の edge 状態変更**（`edge reject` / `edge unreject` / `edge promote/demote` 手動）。

**共通の運用ルール**:
- 1 コマンド、最小フラグ
- Preview + y/N confirm のみ（対話 1 段階）
- 可逆（git revert or rejected_edges.jsonl からの復元）

**L3 対象**:
- `unapprove`（直前 approve の取消、Scenario 19）— git revert の薄いラッパー
- `reactivate`（deprecated/archived page の復帰、Scenario 11）

**L2 対象**（§2.12 の reject-only filter の実装）:
- `rw reject <edge-id>`（candidate edge の拒絶、Scenario 35）— 1-stage confirm
- `rw edge unreject <edge-id>`（reject の取消、rejected_edges.jsonl → edges.jsonl に戻す）
- `rw edge promote / demote`（Hygiene 自動昇格を人間が上書き、Scenario 37）— 理由記録必須、confirm 後実行

**複雑度のスペクトラム**:

```
複雑（L3 8 段階） ─────────────────────── 単純（1 段階）──────────── 自動
deprecate, retract,     unapprove, reactivate,     Hygiene バッチ,
merge, split,           edge reject/unreject,      auto-accept (≥0.75),
tag merge,              edge promote/demote        decay, reinforcement,
skill install,                                     usage event 記録
hypothesis approve,
query promote
```

**原則**: 人間の判断コストが操作の可逆性と比例する（8 段階は不可逆、1 段階は可逆、自動は純粋にシステム内完結）。

### 2.6 Git + 層別履歴媒体

**適用範囲**: 全層に適用、ただし履歴の記録媒体が層ごとに異なる。

**共通原則**:
1. **Git が第一の履歴ソース**（全層共通）。`git log` / `git blame` で誰がいつ何を変えたかが必ず辿れる
2. **補助履歴で細粒度トレース**: Git だけでは分からない「なぜ変えたか」「edge confidence がどう推移したか」等を層固有の媒体で記録
3. **derived cache は gitignore**: 再生成可能なキャッシュはバージョン管理しない
4. **退避ディレクトリを作らない**: `.archived/` 等に物理移動せず、Git + status / rejected ledger で論理管理（§2.3 と整合）

**層別履歴媒体**:

| 層 | Git 管理対象 | 補助履歴媒体 | gitignore |
|----|-----------|-----------|-----------|
| **L1 Raw** | `raw/**/*.md` | **Git log のみ**（専用履歴フィールドなし、人間直接記述） | `raw/incoming/`（Vault 初期化時に gitignore） |
| **L2 Graph Ledger** | `.rwiki/graph/*.jsonl` / `*.yaml`（edges / edge_events / evidence / rejected_edges / entities） | **`edge_events.jsonl`**（append-only event log、edge-level 細粒度） | `.rwiki/cache/graph.sqlite`（derived from JSONL、`rw graph rebuild` で再生成） |
| **L3 Curated Wiki** | `wiki/**/*.md` | **frontmatter `update_history:`**（page-level 意味的変更） | `wiki/.obsidian/workspace*`（Obsidian UI 状態） |

---

**L3 の補助履歴（frontmatter `update_history:`）**:

```yaml
update_history:
  - date: 2026-04-24
    type: extension
    summary: "SINDy-MPC 章を追加"
    evidence: raw/papers/local/sindy-mpc.md
```

`wiki/.archived/` のような退避ディレクトリは作らない（deprecated / retracted / archived は frontmatter `status:` で管理、§2.3）。

---

**L2 の補助履歴（`edge_events.jsonl`）**:

append-only JSONL で edge-level の confidence 変遷・状態遷移を細粒度記録。event type（Spec 5 参照）:

```
created / reinforced(Direct|Support|Retrieval|Co-activation) /
decayed / promoted / demoted / rejected / merged / contradiction_flagged
```

例（1 行 1 event）:
```json
{"ts": "2026-04-25T10:30:00Z", "edge_id": "e_042", "type": "reinforced", "signal": "Direct", "delta": 0.08, "source": "perspective:sindy-koopman"}
{"ts": "2026-04-25T11:00:00Z", "edge_id": "e_042", "type": "promoted", "from": "candidate", "to": "stable", "reason": "confidence_threshold"}
```

**JSONL を採用した理由**（§3 / Spec 5 と整合）:

1. **append-only で git diff 親和**: 行単位追加のみ、git log が「何が起きたか」を時系列で読みやすい形で保全
2. **人間可読**: 1 行 1 record の JSON、直接開いてデバッグ可能
3. **Graph DB 正本化を却下**（§2.12 / §1.3 却下代替案表）: Graph DB は diff 管理困難、trust chain の人間検証が困難
4. **rebuild 可能**: JSONL が正本、sqlite cache は `rw graph rebuild` でいつでも再生成できる

**rejected_edges.jsonl も履歴の一部**: reject 後も物理削除せず保持し、`rw edge unreject` で復元可能（Karpathy 思想「失敗からも学ぶ」、§1.3.5）。

**Reject 理由の記録義務**:

L2 edge を reject する際、**理由記録は必須**（L3 frontmatter の `update_history:` に意味的変更理由を書くのと同等の義務）。これは trust chain の逆方向（「なぜこれを graph から除外したか」）を辿れるようにするため、および skill（`reject_learner`、Scenario 35）が将来の抽出精度向上のために学習する素材を確保するため。

rejected_edges.jsonl の各 entry は以下のフィールドを必須とする:

| フィールド | 必須 | 内容 |
|----------|:----:|------|
| `edge_id` | ✅ | 対象 edge |
| `rejected_at` | ✅ | ISO 8601 timestamp |
| `reject_reason_category` | ✅ | 定型分類: `incorrect_relation` / `wrong_direction` / `low_evidence` / `context_mismatch` / `superseded` / `other` |
| `reject_reason_text` | ✅ | 自由記述（1 行以上、空文字禁止）|
| `rejected_by` | ✅ | `user` / `auto-batch`（`confidence < reject_queue_threshold` の自動候補化、最終 confirm は user）|
| `pre_reject_status` | ✅ | reject 直前の edge status（unreject 時の復元に使用）|
| `pre_reject_evidence_ids` | ✅ | reject 直前の evidence_ids |

**auto-batch の扱い**: `rw reject --auto-batch` は candidate 化のみ行い、**実際の reject は 1 件ずつ user が確認してコミット**する。この時も `reject_reason_text` は user 記述必須（1 件ずつ最小限の一言でよい）。

---

**層間 trust chain と履歴の関係**:

各層の履歴媒体は独立しているが、`evidence_id` / `edge_id` を介して相互参照できる:
- L3 wiki の `sources:` → L1 raw パス or L2 evidence_id
- L3 wiki の `related:` → L2 edge_id（derived cache）
- L2 edges の `evidence_ids` → L2 evidence.jsonl の entries → L1 raw の quote/span
- L2 evidence.jsonl の `source:` → L1 raw ファイル

これにより、L3 wiki のある記述から「どの evidence に裏付けられ、どの edge 経由で関連付けられ、どの raw source が元か」を全層履歴を横断して辿れる（§2.10 Evidence chain と連携）。

### 2.7 エディタとの責務分離

**「編集体験はエディタ、パイプラインは Rwiki」**

以下は Obsidian を参照エディタとした場合の責務分担例：

| 領域 | エディタ（例: Obsidian） | Rwiki |
|------|------------------------|-------|
| 書く・読む体験 | ◎ | △ |
| Daily note 生成・テンプレート展開 | ◎ | — |
| パイプライン処理（lint / ingest / distill / approve） | — | ◎ |
| LLM 連携 | △（プラグイン依存） | ◎（LLM CLI 統合） |
| 知識グラフ分析 | △（表示のみ） | ◎（計算・audit） |
| Trust chain 保証 | — | ◎ |

Rwiki は**エディタ非依存**に設計される。生成される markdown ファイルは任意のエディタ（vim、VSCode、Obsidian、Typora 等）で編集可能。Obsidian は Daily Note・Graph view・Backlinks 等の機能が充実しているため推奨エディタとして参照する。

### 2.8 Skill library による出力柔軟化

**現行の問題**: タスクごとに出力形式が固定（`synthesize_logs` が Summary/Decision/... を強制）。

**v2 の解**: タスク（distill）と出力スキルを分離。

```
rw distill <file> --skill <skill-name>
```

スキルはコンテンツの種類に応じて選べる：
- `paper_summary` / `narrative_extract` / `meeting_synthesis` / `llm_log_extract` / `cross_page_synthesis` / ...

### 2.9 Graph as first-class citizen

Wiki のリンクは **typed edges**（関係の型を持つ）：

```yaml
related:
  - target: wiki/methods/koopman.md
    relation: similar_approach_to
  - target: wiki/methods/e-sindy.md
    relation: extended_by
```

LLM は graph を traverse して：
- **Perspective generation**: 既存知識の再解釈・代替視点の提示
- **Hypothesis generation**: 未検証の新しい命題・洞察の生成

を行う（Spec 6 で統合的に詳細化、本ドキュメントでは言及のみ）。

### 2.10 Evidence chain の徹底

すべての wiki 知識は raw/ に trace できる：

```
raw/papers/local/brunton-2016.md
  ↓ (source)
review/synthesis_candidates/sindy-candidate.md
  ↓ (approve)
wiki/methods/sindy.md
  ↓ (cross_page_synthesis)
wiki/synthesis/data-driven-identification.md
```

各 wiki ページの `source:` / `sources:` / `merged_from:` / `evidence:` フィールドで trust chain を維持。LLM の推論部分は `[INFERENCE]` マーカーで明示。

### 2.11 ユーザー primary interface は発見、メンテナンスは LLM guide

**原則**: Rwiki の複雑なメンテナンス処理は、ユーザーが手順を知らなくても LLM が対話でガイドできるように設計する。ユーザーの時間・認知は**知識発見**に集中させる。

**設計の動機**:
- v2 の MVP 対象シナリオ 16 件のうち、**メンテナンス系が約 70%** を占める
- しかしユーザーの真の目的は「知識発見」であり、メンテナンスは副次的
- 全コマンドとフローを覚えるのは認知負荷が過大
- Karpathy の思想「人間は戦略・判断、LLM は実務」の具体化

**コマンド階層（4 Level）**:

| Level | 対象 | ユーザーの関与 | 例 |
|-------|-----|------------|------|
| **L1: 発見** | 日常的な入口 | **最優先で覚える**（3 コマンドのみ） | `rw chat`, `rw perspective`, `rw hypothesize` |
| **L2: 判断** | 主要な意思決定 | ユーザーが関与すべき判断点 | `rw approve`, `rw verify` |
| **L3: メンテナンス**（20+ コマンド） | 裏方の実務 | **LLM ガイドで自然言語発話のみ**（コマンド名を知らなくてよい） | `rw chat` 内で「整理したい」「チェックしたい」等 |
| **L4: Power user / CI** | 自動化・熟練者 | オプショナル、CLI 直接実行 | 全コマンドを script 等で呼出 |

**設計上の帰結**:

1. **全メンテナンスコマンドは `rw chat` 内で LLM ガイド可能**であること
2. **メンテナンス系の user-guide 記述**は「コマンド reference」より「自然言語意図の例」を優先
3. **ドキュメント量 ≠ ユーザー学習コスト**（LLM が取り持つため、詳細は reference で残す）
4. **Autonomous mode にメンテナンス提案も含める**（Scenario 14 の拡張、後述）
5. **Scenario 33（Ambiguity UX）は全メンテナンス UX 原則**として機能（「意図を伝えるだけ、判断は LLM と相談」）

**具体例（L3 の LLM ガイド）**:

```
You: 最近忙しくて放っといた、Rwiki を綺麗にしたい

Claude: [内部: 複数診断を並行実行]
  状態診断:
    - raw/incoming/ に未 ingest 3 件（うち 2 件 FAIL 滞留）
    - review/synthesis_candidates/ に未 approve 5 件
    - wiki/ の audit structure が 2 週間前（ERROR 2 件推定）
    - tag vocabulary に重複候補 4 件
    - wiki/.follow-ups/ に未解決 2 件

  優先順位で進めます。まず lint FAIL 滞留から？

You: 全部お任せ

Claude: (1) lint FAIL → 自動修復可能な 1 件を先に fix
       (2) 未 approve 5 件 → レビュー要求
       ...（必要に応じて個別に相談）
```

ユーザー発話 1 つで、**複数メンテナンスシナリオをオーケストレーション**する。

**Maintenance autonomous mode**:

Autonomous mode（Scenario 14）はメンテナンス側にも発火：

```
💡 **メンテナンス提案**
  - 未 approve の候補が 5 件あります、レビューしませんか？
  - audit を 2 週間実行していません、structure チェックを推奨
  - L2 Graph Ledger の reject queue に 12 件の候補が溜まっています
  - edge decay が続いている edge が 30 件（1 週間アクティビティなし）
  - deprecated chain の循環が発生しています、修正しますか？
```

定期的な状態確認を LLM が代行、ユーザーは意思決定だけ。

### 2.12 Graph Ledger による Evidence-backed Candidate Graph（L2 専用・他原則への優先）

**適用範囲**: **L2 Graph Ledger のみ**。L3 wiki / L1 raw には適用されない。

**他原則との優先関係**: L2 においては本原則が **§2.2 Review layer first** および **§2.4 Dangerous ops 8 段階**より優先される。具体的には:

- **§2.2 との関係**: L2 の edge 追加は review/ 層を経由せず、edges.jsonl に append-only で直接記録される（§2.2 は L3 限定）
- **§2.4 との関係**: L2 の edge 拒絶（reject）は 1-stage confirm で実行される（§2.5 Simple dangerous op、8 段階は不要）
- **§2.9 Graph as first-class との関係**: L2 が正本、L3 `related:` は derived cache という分担により両原則は補完関係

**原則**: L2 Graph Ledger は「未完成・進化する graph」を許容し、**人間の approve を必須としない**。ただし **evidence 必須**の原則は崩さない。

**設計の動機**:
- 「構造を人間が書く」前提では graph が育たない（入力コスト問題、§1.3.2 参照）
- しかし「LLM 自動抽出を盲信」では trust chain が破綻する
- 解: **evidence-backed candidate graph** として、根拠付きで自動生成、使用で強化、reject で削除

**3 つの核心ルール**:

1. **Evidence 必須**: evidence なし edge は confidence ≤ 0.3 に強制上限
2. **Reject-only filter**: 人間は拒絶のみ判断、承認は閾値で自動（confidence ≥ 0.75 → stable）
3. **使用で育つ**: query / perspective / hypothesize で使われた edge は reinforcement、使われない edge は decay

**L3 との関係**:
- L2 edges は auto-accept（reject されない限り）
- **L3 wiki/ への昇格には従来通り approve が必須**（承認ゲート維持）
- L3 frontmatter `related:` は L2 の stable/core edges から derived（sync）

**初期 confidence 計算（6 係数加重和）**:

```
confidence_initial =
    0.35 × evidence_score
  + 0.20 × explicitness_score
  + 0.15 × source_reliability
  + 0.15 × graph_consistency
  + 0.10 × recurrence_score
  + 0.05 × human_feedback
```

各係数の定義:
- **evidence_score**: evidence.jsonl に紐付く裏付けの数と質（0-1）
- **explicitness_score**: extraction_mode から決定（explicit=1.0 / paraphrase=0.75 / inferred=0.5 / co_occurrence=0.25）
- **source_reliability**: 抽出元の信頼度（論文 > 個人メモ等）
- **graph_consistency**: 既存 graph との矛盾度（矛盾無し=1.0、矛盾あり=低下）
- **recurrence_score**: 複数 source で再出現した頻度（0-1）
- **human_feedback**: 過去の reject / confirm 履歴（0-1）

**evidence-less upper bound**: `evidence_score == 0` の場合、最終 confidence は 0.3 を上限にクランプ（ルール 1 を強制）。

**進化則（Graph Hygiene、Spec 5 で詳細化）**:

```
confidence_next =
    confidence_current
  + α × usage_signal          # 強化
  + β × recurrence            # 複数 source 再出現
  - γ × decay                 # 時間減衰
  - δ × contradiction         # 矛盾ペナルティ
```

**人間 reject の爆発的効果**: `confidence -= 1.0` で edge は事実上抹消、rejected_edges.jsonl に移動。

**Reinforcement delta の暴走防止**: 1 つの edge が複数 perspective / hypothesis で同時に reinforced されるとき、各 event は独立加算するが以下の上限で暴走を防ぐ（詳細は Spec 5 config）:
- **per-event 上限**: 1 reinforcement event で加算できる delta は 0.1 まで
- **per-day 上限**: 1 edge の 1 日合計 delta は 0.2 まで
- **session 内重複**: `independence_factor` で頭打ち（§Spec 5 Usage signal 参照）

これにより「同じ edge が 1 日で 10 回 reinforced → confidence +1.0」のような暴走を防ぎ、時間をかけて段階的に育つ graph を保証する。

**閾値 3 段階（edge status の境界）**:

| confidence 範囲 | Edge status | 人間関与 |
|---------------|------------|---------|
| `≥ 0.75` | candidate → **stable**（auto-accept） | なし（reject 可能） |
| `0.45 – 0.75` | **candidate**（監視対象） | reject queue 任意 |
| `0.3 – 0.45` | **weak**（表示抑制、低優先） | reject 推奨 |
| `< 0.3` | reject_queue 候補 | reject 対象 |

（数値は Spec 5 config（`.rwiki/config.yml` の `graph.auto_accept_threshold` / `graph.candidate_weak_boundary` / `graph.reject_queue_threshold`）で tunable）

**Dangling edge policy（evidence 消失時の挙動）**:

Edge が参照する evidence（evidence.jsonl の entry）が消失した場合、edge を**即座に自動切断しない**。理由は (a) evidence 消失は多くが一時的（URL 404 が後に復活、raw file が rename で検出漏れ等）、(b) 他 evidence_ids が残っている場合は edge の妥当性を損なわない、(c) 自動削除は「矛盾 edge の即座削除」却下と同じ trust 破壊リスク。

処理方針は以下の段階的 degrade:

| 状態 | 処理 | 結果 |
|------|------|------|
| **1 件でも有効 evidence が残る** | dangling evidence_id は edge の `evidence_ids` から除外（append-only の補正 event として記録）、confidence は再計算 | 継続利用可能 |
| **全 evidence_ids が dangling** | edge を `weak` status に降格、confidence を evidence ceiling（0.3）以下にクランプ、`dangling_flagged` event を edge_events.jsonl に追記 | reject queue 候補化、Hygiene の次回サイクルで decay 加速 |
| **dangling 状態が 30 日以上継続** | Hygiene が `deprecated` に自動遷移 | perspective / hypothesize の traverse 対象外 |
| **人間が明示的に reject 判断** | 通常の reject workflow（Simple dangerous op） | rejected_edges.jsonl に移動 |

**検出タイミング**: Scenario 13 の `rw audit evidence` で第一次検出 → Scenario 10 の `rw audit graph` で graph 構造整合性の結果として追随 → Hygiene バッチが confidence 調整と status 遷移を実行（3 つのレイヤーで責務分担）。

**物理削除は行わない**: edge 自体も、消失した evidence 参照も、履歴保全のため edges.jsonl / evidence.jsonl から物理削除しない。補正は append-only event で表現（§2.6 整合）。

**明示的に却下された代替案**:

| 却下案 | 却下理由 |
|-------|---------|
| 全件 approve（旧 wiki モデル） | 入力コスト爆発、scale 不可能 |
| Graph DB（Neo4j 等）を正本化 | git diff 不能、人間レビュー不能、trust chain 追跡困難 |
| LLM 自信度を直接 confidence に | 根拠不在、「LLM の妄想ネットワーク」化リスク |
| 使用回数（単純 count）で reinforcement | 「人気 = 真実」への汚染、recall 偏重 |
| 矛盾 edge の即座削除 | トレードオフ／対立視点の喪失、Perspective の土壌破壊 |

**Scenario 14（perspective / hypothesize）との連携**:
- Perspective: L2 の stable + core edges を traverse
- Hypothesis: L2 の missing bridges / candidate edges を発見源に
- 検証された hypothesis は対応 edge が reinforcement される

### 2.13 Curation Provenance（決定プロセスの保全）

**適用範囲**: 全層、ただし主に L2 / L3 の curation 操作で機能。L1 は lint pass / fail 判定のみ記録。

**原則**: 知識は **what + why** の二層で構成される。
- **what**: edge / page / entity そのもの（既存 edges.jsonl / wiki/ / entities.yaml）
- **why**: なぜそう判断したか、何を選び何を却下したかの **decision rationale**

`evidence.jsonl` が **source の WHAT**（raw からの引用）を保全するのに対し、本原則の `decision_log.jsonl` は **curator の WHY**（判断プロセス）を保全する。両者は直交する provenance dimension。

**設計の動機**:
- 結果（edge）だけでは「なぜこの relation_type を選んだか」が後から分からない
- 同じ raw でも curator の判断で異なる graph に育つ → reproducibility のために judgment を残す
- Self-application（framework が自身を学習）の最良素材
- Karpathy 哲学「人間は判断、LLM は実務」の判断側を first-class concept として扱う

**3 つの核心ルール**:

1. **Selective recording**: 全 decision を記録せず、**境界決定 / 矛盾 / 人間介入 / status 遷移時のみ** auto-record（volume 爆発防止）
2. **Append-only**: decision_log.jsonl は immutable、誤判断の訂正は compensating decision で表現（MVP は基本ロジックのみ、Phase 2 で訂正機構）
3. **Selective privacy**: default git 管理だが、`.rwiki/config.yml` で privacy mode、または per-decision `private:` flag で sanitize 可能

**自動記録の閾値**（config tunable、§Spec 5 参照）:

| トリガー | 記録 | 理由 |
|---------|:---:|------|
| confidence ≥ 0.85 の routine extraction | ❌ | 明確、記録不要 |
| confidence が candidate-weak boundary（0.45）±0.05 | ✅ | 境界判断、後で参照価値 |
| Contradiction 検出 | ✅ | 必須、§2.12 contradiction tracking と連携 |
| 人間 approve / reject / merge / split | ✅ | judgment 必須記録 |
| Hypothesis verify（confirmed / refuted / partial） | ✅ | 評価プロセスを保全 |
| Hygiene routine decay / reinforcement | ❌ | edge_events.jsonl で十分 |
| Hygiene による status 遷移（candidate → stable 等） | ✅ | 重要な状態変化 |
| Synthesis / wiki/synthesis/ 昇格 | ✅ | 重要 curation event |

**Reasoning 入力方法（hybrid）**:

1. **Auto-generate from chat session**: `rw chat` 中の対話が context にある時、LLM が直近の議論を要約して reasoning 候補を生成（user 確認後採用）
2. **Manual `--reason` flag**: `rw approve --reason "理由..."` で明示記述
3. **Default skip**: 入力負担を避けたい時、`approved without specific reason` 等の default を採用（reasoning field は空ではなく "default" 印）

**可視化**: 記録と同時設計、Tier 1-3 を MVP に組込み:
- **Tier 1**: CLI views（`rw decision history / recent / stats / contradictions / search`、Spec 4）
- **Tier 2**: Markdown timeline（`rw decision render` で `review/decision-views/<id>-timeline.md` 自動生成）
- **Tier 3**: Mermaid diagrams（Tier 2 markdown に gantt / flowchart 埋め込み、Obsidian / GitHub で render）
- **Tier 4-5**（Phase 2 候補）: Graph view 拡張、Web dashboard

**Self-application との接続**: decision_log.jsonl は self-application study（Section 7.5）で **framework が自身の curation pattern を学習** する素材になる。本セッションで実証された「議論ログ → spec」の構造を formal に system 化したもの。

**§2.10 Evidence chain との関係**:

```
Trust chain（縦軸、§2.10）:        L1 raw → L2 evidence → L3 sources
Curation provenance（横軸、§2.13）: decision_log → context_ref → chat-session
```

両者は直交し、ある wiki 記述から **「どの raw が裏付けか（縦）」** と **「どの判断でこうなったか（横）」** の両方を辿れる。

---

## 3. アーキテクチャ概観

### 3.1 3 層アーキテクチャ

Rwiki v2 は **3 つの architectural layer** で構成される。各層は物理的格納位置・アクセスパターン・人間関与の度合いが異なる。

```
┌───────────────────────────────────────────────────────────┐
│ Layer 1: Raw                                              │
│   raw/**/*.md                                              │
│   - 人間入力、自由記述                                      │
│   - Immutable / append-only（ingest 後は編集しない）          │
│   - evidence の源、trust chain の起点                       │
└───────────────────────────────────────────────────────────┘
              ↓ LLM 自動抽出（Scenario 34）
┌───────────────────────────────────────────────────────────┐
│ Layer 2: Graph Ledger                                     │
│   .rwiki/graph/                                            │
│     entities.yaml          — normalized entities           │
│     edges.jsonl            — source of truth for edges     │
│     edge_events.jsonl      — confidence 変遷履歴            │
│     evidence.jsonl         — 根拠引用集（first-class）      │
│     rejected_edges.jsonl   — 人間 reject 済                │
│     reject_queue/          — 人間判断待ち                   │
│                                                            │
│   各 edge には status:                                      │
│     weak / candidate / stable / core /                     │
│     deprecated / rejected                                  │
│                                                            │
│   Graph Hygiene が進化則で confidence を管理                │
│   （decay / reinforcement / competition /                  │
│    contradiction / merging）                               │
│                                                            │
│   派生 cache: .rwiki/cache/graph.sqlite（高速 query 用）     │
└───────────────────────────────────────────────────────────┘
              ↓ 人間承認（review → approve、L3 昇格）
┌───────────────────────────────────────────────────────────┐
│ Layer 3: Curated Wiki                                     │
│   wiki/**/*.md                                             │
│   - 人間承認済み markdown ページ                            │
│   - frontmatter: title, source, tags, status               │
│   - `related:` は **derived cache**（Ledger からの同期）    │
│   - subdirectory:                                          │
│     concepts/ methods/ projects/ entities/{people,tools}/  │
│     synthesis/   ← 最高ランク承認（Scenario 16、8 段階必須）│
│     .follow-ups/                                           │
└───────────────────────────────────────────────────────────┘

横断的要素:
  review/*_candidates/     — L2 → L3 への承認 buffer
  AGENTS/                  — LLM 運用ルール（skills, guides）
  .rwiki/vocabulary/       — tags / relations / categories / entity_types
  logs/                    — CLI 実行ログ
```

**各層の特徴**:

| 層 | 物理格納 | 更新頻度 | 人間関与 | Git 管理 |
|----|---------|---------|---------|---------|
| **L1 Raw** | `raw/**/*.md` | append-only | 入力のみ | ✓ |
| **L2 Graph Ledger** | `.rwiki/graph/*.jsonl` + `*.yaml` | 頻繁（events、confidence） | reject only | ✓（ledger 本体）<br>✗（cache） |
| **L3 Curated Wiki** | `wiki/**/*.md` | 人間承認時 | approve 必須 | ✓ |

### 3.2 Vault 構造

```
<vault>/
├── raw/                                # L1: Raw
│   ├── incoming/                       # 未検証入力
│   │   ├── articles/
│   │   ├── papers/{zotero,local}/
│   │   ├── notes/
│   │   ├── narratives/
│   │   ├── essays/
│   │   └── code-snippets/
│   ├── llm_logs/                       # LLM 対話ログ
│   │   ├── interactive/                # interactive skill 自動保存
│   │   ├── chat-sessions/              # rw chat 自動保存
│   │   └── manual/                     # 手動 export
│   └── （ingest 後、各カテゴリが raw/ 直下に展開）
├── review/                             # L2 ↔ L3 buffer
│   ├── synthesis_candidates/
│   ├── query/
│   ├── hypothesis_candidates/          # Scenario 14
│   ├── perspectives/                   # Scenario 14
│   ├── skill_candidates/               # Scenario 20
│   ├── vocabulary_candidates/          # Scenario 12
│   ├── audit_candidates/               # Scenario 10
│   └── relation_candidates/            # Scenario 34
├── wiki/                               # L3: Curated
│   ├── concepts/
│   ├── methods/
│   ├── projects/
│   ├── entities/{people,tools}/
│   ├── synthesis/                      # 最高ランク subdirectory
│   └── .follow-ups/
├── AGENTS/                             # 横断
│   ├── lint.md
│   ├── ingest.md
│   ├── approve.md
│   ├── audit.md
│   ├── skills/                         # スキルライブラリ
│   │   ├── paper_summary.md
│   │   ├── narrative_extract.md
│   │   ├── relation_extraction.md      # Scenario 34
│   │   └── ...
│   └── guides/                         # dangerous op 対話ガイド
│       ├── dangerous-operations.md
│       ├── deprecate-guide.md
│       ├── merge-guide.md
│       └── ...
├── scripts/
│   └── rw → <dev>/scripts/rw_cli.py
├── logs/
├── CLAUDE.md
├── .rwiki/                             # 横断メタデータ
│   ├── config.yml                      # 閾値、decay rate、chat mode 等
│   ├── vocabulary/
│   │   ├── tags.yml
│   │   ├── relations.yml
│   │   ├── categories.yml
│   │   └── entity_types.yml
│   ├── graph/                          # L2: Graph Ledger（git 管理）
│   │   ├── entities.yaml
│   │   ├── edges.jsonl
│   │   ├── edge_events.jsonl
│   │   ├── evidence.jsonl
│   │   ├── rejected_edges.jsonl
│   │   └── reject_queue/
│   └── cache/                          # derived（gitignore）
│       ├── graph.sqlite
│       └── networkx.pkl
└── .git/
```

### 3.3 データフロー

```
┌──────────────────────────────────────────────────────────┐
│ L1 Raw                                                    │
│   raw/incoming/  ──lint──►  raw/ (ingest commit)          │
└────────────────────┬─────────────────────────────────────┘
                     │ LLM extract-relations
                     ▼
┌──────────────────────────────────────────────────────────┐
│ L2 Graph Ledger                                           │
│   新規 edge → status: candidate, confidence 初期値         │
│              ↓ Hygiene 進化                                │
│     候補 → stable → core    （confidence 上昇、usage で強化）│
│     候補 → weak → deprecated （decay）                    │
│     人間 reject → rejected_edges.jsonl                    │
│                                                           │
│   Query 時（Scenario 14 perspective / hypothesize）:       │
│     L2 を traverse（status フィルタ適用）                   │
│     使われた edge に usage_signal 加算 → reinforcement     │
└────────────────────┬─────────────────────────────────────┘
                     │ 明示的に wiki 化したい時
                     ▼
┌──────────────────────────────────────────────────────────┐
│ review/*_candidates/  （L2 → L3 の承認 buffer）              │
│   人間が markdown エディタで確認・編集                        │
└────────────────────┬─────────────────────────────────────┘
                     │ rw approve（人間判断）
                     ▼
┌──────────────────────────────────────────────────────────┐
│ L3 Curated Wiki                                           │
│   wiki/ に markdown ページとして格納                         │
│   frontmatter `related:` ← L2 の stable/core から sync    │
│   wiki/synthesis/ 昇格は最高ランク（8 段階必須）             │
└──────────────────────────────────────────────────────────┘
```

### 3.4 実行モード

| モード | 起動 | 用途 |
|--------|------|------|
| **Interactive（対話型、推奨）** | `rw chat` | 探索的操作、複雑ワークフロー、L2 メンテナンス委任 |
| **CLI（直接実行）** | `rw <task> [args]` | 自動化、batch 処理、熟練ユーザーの速射 |
| **CLI Hybrid** | `rw <task>` が内部で LLM CLI を呼ぶ | LLM を使うタスクの非対話実行（distill, query, extract-relations, audit semantic/strategic 等） |

いずれも同じエンジン（同じ `cmd_*` 関数）を呼ぶ。

### 3.5 コマンド 4 Level 階層（§2.11 の再掲）

| Level | 対象層・機能 | コマンド例 |
|-------|---------|---------|
| **L1 発見** | 日常入口 | `rw chat`, `rw perspective`, `rw hypothesize` |
| **L2 判断** | L3 昇格・検証 | `rw approve`, `rw verify` |
| **L3 メンテナンス**（LLM ガイド） | L2 ledger 運用、wiki 保守 | `rw chat` 経由で自然言語発話 |
| **L4 Power user / CI** | 全コマンド直接 | `rw graph *`, `rw edge *`, `rw reject`, `rw hygiene` 等 |

---

## 4. 用語集

### 4.1 基本用語

| 用語 | 定義 |
|------|------|
| **Rwiki** | 本システム全体の総称。Karpathy LLM Wiki に着想を得た、Curated GraphRAG 型の知識発見・探索システム（§1）。 |
| **Vault** | Rwiki が管理する 1 つの knowledge base。`raw/` / `review/` / `wiki/` / `.rwiki/` を含む git リポジトリ 1 つ単位。 |
| **Curated GraphRAG** | Rwiki の位置付け（§1.3）。自動抽出 graph（L2）+ 人間キュレーション wiki（L3）+ Hygiene 自己進化の三要素を組み合わせた、通常の GraphRAG とは別の設計思想。 |
| **Distill（動詞・タスク名）** | raw → review/synthesis_candidates/ に知識候補を抽出する総称タスク。出力形式は skill で指定。 |
| **Synthesis（名詞）** | `wiki/synthesis/` レイヤー。複数 wiki ページから抽象化された創発的知識を置く専用層。L3 内の subdirectory（別層ではない）。 |
| **Skill（スキル）** | distill の具体的出力パターン。`AGENTS/skills/*.md` として定義。 |
| **Paradigm C** | 対話 + 直接編集のハイブリッド編集方式（§2.1）。 |
| **Follow-up** | 対話中に保留した後日判断タスク。`wiki/.follow-ups/` に記録。 |

### 4.2 アーキテクチャ用語

| 用語 | 定義 |
|------|------|
| **Layer 1 / L1 / Raw** | `raw/**/*.md`。人間入力、evidence の源。Immutable / append-only。 |
| **Layer 2 / L2 / Graph Ledger** | `.rwiki/graph/*.jsonl` + `*.yaml`。edge/entity/evidence/events の正本。自動生成 + Hygiene で進化。 |
| **Layer 3 / L3 / Curated Wiki** | `wiki/**/*.md`。人間承認済 markdown ページ。 |
| **Evidence-backed Candidate Graph** | L2 の設計原則（§2.12）。Evidence 必須 / Reject-only filter / Hygiene で進化の 3 核心ルールで駆動される候補 graph。 |
| **Trust chain** | L1 → L2 → L3 への evidence 連鎖。各 edge/page は evidence を持ち、L3 昇格には人間承認が必須。 |
| **Review layer** | L2 ↔ L3 の承認 buffer。`review/*_candidates/` として複数存在（§2.2、L3 変更に限定適用）。L2 は review を経由しない。 |
| **Derived cache** | 再生成可能な派生データ。`.rwiki/cache/graph.sqlite`（JSONL から rebuild）、L3 frontmatter `related:`（L2 edges から sync）等、gitignore または sync 対象。 |

### 4.3 Graph Ledger 用語（Spec 5 核心）

#### ノード・エッジ基本
| 用語 | 定義 |
|------|------|
| **Entity** | L2 の node。人物 / 概念 / 手法 / ツール等、一意な id と正規化名・aliases を持つ。`.rwiki/graph/entities.yaml` で管理。 |
| **Edge** | L2 の関係単位。source / type / target / confidence / status / evidence_ids / extraction_mode を持つ。 |
| **Edge status** | Edge のライフサイクル状態。`weak / candidate / stable / core / deprecated / rejected` の 6 種。 |
| **Page status** | L3 page のライフサイクル状態。`active / deprecated / retracted / archived / merged` の 5 種（Edge status とは別）。 |
| **Page merged**（状態） | 2 つ以上のページが 1 つに統合された後の旧ページの状態。`merged_into:` で統合先を指す。**L3 wiki ページ単位の概念**（Edge Merging とは別）。 |

#### Confidence と閾値
| 用語 | 定義 |
|------|------|
| **Confidence** | Evidence-backed trust score（0.0-1.0）。LLM の自信ではなく、**evidence の強さ × 複数要素**で決まる。初期値は 6 係数加重和（§2.12）。 |
| **Evidence-less upper bound** | evidence なし edge の confidence 上限（0.3）。§2.12 核心ルール 1、trust 破壊防止。 |
| **Auto-accept threshold** | Confidence ≥ 閾値（default 0.75）で candidate → stable に自動昇格。config `graph.auto_accept_threshold`。 |
| **Candidate-weak boundary** | candidate / weak を分ける閾値（default 0.45）。config `graph.candidate_weak_boundary`。 |
| **Reject queue threshold** | これ未満の confidence は reject 候補化（default 0.3）。config `graph.reject_queue_threshold`。 |

#### Evidence とイベント
| 用語 | 定義 |
|------|------|
| **Evidence ledger** | `evidence.jsonl`。edge の根拠引用集、first-class concept。各 evidence は file / quote / span を持つ。 |
| **Evidence_id** | evidence.jsonl の entry を一意識別する id。edge は `evidence_ids: [...]` で複数参照可能。 |
| **Edge event** | confidence / status 変更の時系列記録。`edge_events.jsonl` に append-only。event type 8 種: `created / reinforced(Direct\|Support\|Retrieval\|Co-activation) / decayed / promoted / demoted / rejected / merged / contradiction_flagged`（§2.6）。 |
| **Dangling edge** | 参照していた evidence_id が全て消失した edge（§2.12）。即座削除せず、weak + 0.3 クランプ + `dangling_flagged` event で段階的 degrade、30 日継続で deprecated。 |
| **Extraction mode** | Edge が抽出された方法。`explicit / paraphrase / inferred / co_occurrence` の 4 種、初期 confidence 係数（explicit=1.0 / paraphrase=0.75 / inferred=0.5 / co_occurrence=0.25）。 |

#### Graph Hygiene（進化則 5 ルール）
| 用語 | 定義 |
|------|------|
| **Graph Hygiene** | L2 edges の進化則 5 ルールの総称。定期バッチで実行（default 週次、`rw graph hygiene`）。 |
| **Decay**（Hygiene ルール 1） | 時間経過で未使用 edges の confidence を減衰。`decay_rate_per_day` で調整、Hygiene 固定実行順の 1 番目。 |
| **Reinforcement**（Hygiene ルール 2） | Usage signal が高い edges の confidence を強化。Hygiene 固定実行順の 2 番目（Decay 後）。 |
| **Competition**（Hygiene ルール 3） | 類似 edges 間で winner/runner-up/loser を決定。Level 1（同 node pair、MVP 必須）/ Level 2（類似 node pair、Phase 3）/ Level 3（semantic tradeoff、Phase 3）の 3 段階。 |
| **Contradiction tracking**（Hygiene ルール 4） | 矛盾 edges を**削除せず** `contradiction_with:` で相互参照。両立しない関係を知識として保持（Perspective 生成の土壌）。 |
| **Edge Merging**（Hygiene ルール 5） | 類似・重複 edges を 1 つに統合して ontology を自然形成。L2 edge 単位（Page merged status とは別）。 |

#### Usage signal
| 用語 | 定義 |
|------|------|
| **Usage signal** | edge が query 時にどれだけ推論に貢献したか。`base_score × contribution × sqrt(confidence) × independence × time_weight`（§2.12 / Spec 5）。 |
| **Contribution weight 4 種別** | Usage signal の contribution 係数。**Direct**（直接引用、1.0）/ **Support**（補助引用、0.6）/ **Retrieval**（検索ヒット、0.2）/ **Co-activation**（同時活性、0.1）。 |

#### Reject / Unreject
| 用語 | 定義 |
|------|------|
| **Reject queue** | 人間が reject を判断する candidate edges の待機所（`.rwiki/graph/reject_queue/`）。 |
| **Reject reason category** | reject 理由の定型分類 6 種: `incorrect_relation / wrong_direction / low_evidence / context_mismatch / superseded / other`（§2.6 必須記録）。 |
| **Unreject** | reject 済 edge の復元操作（`rw edge unreject`）。reject 直前 status に復帰（stable/core は candidate にリセット）、confidence は evidence ceiling クランプ、理由記録必須。 |
| **Entity shortcut field** | Frontmatter の entity 固有ショートカット（`authored:`, `collaborated_with:` 等）。内部的に typed edge に正規化（confidence 0.9 固定、extraction_mode=explicit）。 |

#### Concurrency / ストレージ
| 用語 | 定義 |
|------|------|
| **Hygiene lock** | `.rwiki/.hygiene.lock` file lock。MVP は single-user serialized、Hygiene 実行中は ingest/reject/approve/extract-relations が lock 待ちまたはエラー、read-only Query API は lock 不要（Spec 5）。 |
| **Transaction semantics** | Hygiene 実行は all-or-nothing。tmp 領域で書いて atomic rename、途中クラッシュは git commit に revert。 |

#### Curation Provenance（§2.13）
| 用語 | 定義 |
|------|------|
| **Curation provenance** | 「なぜそう curate したか」の判断プロセス保全（§2.13）。`evidence.jsonl` の WHAT に対する WHY、trust chain（縦軸）に対する直交次元（横軸）。 |
| **Decision log** | `.rwiki/graph/decision_log.jsonl`。重要 curation 決定を append-only 記録。schema: decision_id / ts / decision_type / actor / subject_refs / reasoning / alternatives_considered / outcome / context_ref / evidence_ids。 |
| **Decision type** | `edge_extraction / edge_reject / edge_promote / edge_unreject / hypothesis_verify / synthesis_approve / page_deprecate / tag_merge / split / hygiene_apply` の 10 種。 |
| **Selective recording** | volume 爆発防止のため auto-record は境界決定 / 矛盾 / 人間介入 / status 遷移 / synthesis 操作のみ（config tunable）。 |
| **Decision visualization Tier 1-5** | **Tier 1**（CLI views、P0）/ **Tier 2**（markdown timeline `rw decision render`、P1）/ **Tier 3**（mermaid 埋め込み、P1）/ Tier 4（graph view 拡張、Phase 2）/ Tier 5（web dashboard、Phase 2）。MVP は Tier 1-3。 |
| **Context ref** | decision の reasoning が依拠する議論ログへの link（例: `raw/llm_logs/chat-sessions/chat-<ts>.md#L42-67`）。重複保存を避け、議論本体は別 file で管理。 |

### 4.4 Perspective / Hypothesis 関連用語

#### 主機能
| 用語 | 定義 |
|------|------|
| **Perspective generation** | L2 graph を LLM が traverse して**既存知識の再解釈・代替視点・関係性**を創発する機能（Spec 6）。主に stable + core edges を活用。 |
| **Hypothesis generation** | L2 graph の missing bridges / candidate edges から**未検証の新命題・洞察・予測**を生成する機能（Spec 6）。Perspective と対をなす。 |
| **Hypothesis status** | Hypothesis のライフサイクル状態 7 種: `draft / verified / confirmed / refuted / promoted / evolved / archived`（Page status / Edge status とは独立）。 |
| **Discovery** | Perspective と Hypothesis が共通基盤とする**内部探索アルゴリズム**（L2 graph traverse）。MVP は単独 CLI なし、Phase 2 で `rw discover` 検討。 |
| **`[INFERENCE]` マーカー** | LLM の推論部分を明示するマーカー。wiki / evidence に直接書かれていない命題・推論・仮説に付与し、Trust chain を保つ。 |

#### GraphRAG 由来 4 技法（§1.3.3）
| 用語 | 定義 |
|------|------|
| **Community detection** | 関連 entity を cluster 化するアルゴリズム（Louvain / Leiden）。Perspective の近接手法 surface、Hypothesis の cluster 間 bridge 探索に使用。Spec 5 所管。 |
| **Global query** | 特定 node 起点ではなく graph 全体・大局 scope の集約 query。「この分野の主要手法を俯瞰」のような大局視点生成。Spec 5 + Spec 6 所管。 |
| **Missing bridge detection** | 関連性が疑われるが edge が無い node 組合せを検出。Hypothesis の主要源泉、Scenario 14 パターン C。Spec 5 所管（`rw graph bridges`）。 |
| **Hierarchical summary**（on-demand） | community 単位で動的に生成する要約。**事前構築しない**（graph が evolving なため）。大規模 graph 俯瞰時の認知負荷低減。Spec 5 + Spec 6 所管。 |

#### モード
| 用語 | 定義 |
|------|------|
| **Autonomous mode** | LLM が能動的に関連性・視点・メンテナンス提案を surface するモード（default OFF）。知識発見系と Maintenance 系の 2 系統。 |
| **User-requested mode** | LLM はユーザー要求時のみ応答する default モード。 |
| **Maintenance autonomous** | Autonomous mode の一部。未 approve / reject queue 蓄積 / Hygiene 推奨等を surface。6 種の具体 trigger 閾値は Spec 6 参照。 |
| **Maintenance autonomous trigger** | Maintenance autonomous の発火条件閾値（reject queue ≥10 / Decay 進行 ≥20 / typed-edge 整備率 <2.0 / Dangling ≥5 / Audit 未実行 ≥14 日 / 未 approve ≥5）。tunable。 |

### 4.5 Operations 用語

#### Dangerous op
| 用語 | 定義 |
|------|------|
| **Dangerous operation** | 不可逆または破壊的な操作。対話ガイド必須または推奨。**L3 対象**（§2.4）。 |
| **Simple dangerous operation** | 8 段階対話は不要、最小 confirm のみ。L3 の `unapprove` / `reactivate`、L2 の `edge reject` / `edge unreject` / `edge promote/demote`（§2.5）。 |
| **8 段階対話ガイド** | Dangerous operation 実行時の共通チェックリスト: 意図確認 → 現状把握 → 依存グラフ解析 → 代替案提示 → 個別判断 → Pre-flight warning → 差分プレビュー → 人間レビュー approve。`AGENTS/guides/dangerous-operations.md`。 |
| **Reject-only filter** | L2 edge に対する人間の関与方式。approve は不要、拒絶のみ判断（§2.12）。 |
| **Pre-flight check** | Dangerous op 実行前の俯瞰診断。approve / deprecate / merge 等の対象ファイル検査 + L2 edge state サマリ（reject queue / decay / dangling 件数）。読込のみ、非 dangerous（Scenario 18）。 |

#### コマンド階層（§2.11）
| 用語 | 定義 |
|------|------|
| **コマンド階層 4 Level** | §2.11 の分類。**L1 発見**（`rw chat` / `rw perspective` / `rw hypothesize`、優先習得 3 個）/ **L2 判断**（`rw approve` / `rw verify`）/ **L3 メンテナンス**（20+ コマンド、LLM ガイドで発話のみ）/ **L4 Power user / CI**（全コマンド直接実行）。|

#### 運用
| 用語 | 定義 |
|------|------|
| **Hygiene batch** | `rw graph hygiene` の定期実行（default 週次）。Decay → Reinforcement → Competition → Contradiction tracking → Edge Merging の固定直列順。 |
| **Dry-run** | Hygiene / repair / audit-fix 等の apply 前プレビュー実行。`--dry-run` フラグで共通。 |
| **Stale detection** | CLI 起動時に `.rwiki/cache/graph.sqlite` が JSONL に対して古くなっていないか確認、軽微なら増分 rebuild、大きければ `rw graph rebuild` 案内。 |
| **Rebuild** | `.rwiki/cache/graph.sqlite` の再生成（`rw graph rebuild`）。JSONL が正本、cache は derived（§2.6）。 |

**プロンプト中の自然言語表現**: 「抽出」「蒸留」「統合」など自然な日本語を使用可能。内部実装は `distill` などの英語コマンド。

---

## 5. Frontmatter スキーマ

### 5.1 共通必須フィールド（全 .md ファイル）

```yaml
title: string             # ページタイトル
source: string            # 出所（URL / DOI / meeting ID / book title 等、自由文字列）
added: YYYY-MM-DD         # Rwiki に取り込んだ日
```

### 5.2 推奨フィールド

```yaml
type: string              # content type 単一値（paper / article / narrative / meeting / log / code / book / essay 等）
                          # スキル選択のヒントに使われる
tags: [string, ...]       # 多次元分類
                          # 検索・audit 用
```

### 5.3 任意フィールド

```yaml
author: string | [string, ...]
date: YYYY-MM-DD          # 原典の発行日（added とは別）
# ドメイン固有: venue / journal / doi / arxiv_id / isbn 等
```

### 5.4 Wiki ページ固有

```yaml
status: active | deprecated | retracted | archived | merged   # default: active
status_changed_at: YYYY-MM-DD
status_reason: string

# deprecated の場合:
successor:
  - wiki/path/to/successor-1.md
  - wiki/path/to/successor-2.md

# merged の場合:
merged_from: [path, path, ...]
merged_into: path
merge_strategy: complementary | dedup | canonical-a | canonical-b | restructure
merge_conflicts_resolved:
  - issue: string
    resolution: string

# Typed edges（Spec 5）: L2 Graph Ledger から derived される cache
# 正本は .rwiki/graph/edges.jsonl、frontmatter は stable/core edges のみ表示
related:
  - target: wiki/path/target.md
    relation: similar_to | depends_on | contrasted_with | extended_by | unified_in | ...
    # edge_id: e_042   # optional: ledger への逆参照

# Entity 固有ショートカット（internal に typed edge へ正規化）
# 例（entity-person 用）:
authored: [wiki/methods/sindy.md]
collaborated_with: [wiki/entities/people/kutz.md]
mentored: []
# 例（entity-tool 用）:
implements: [wiki/methods/sindy.md]

# 更新履歴:
update_history:
  - date: YYYY-MM-DD
    type: extension | refactor | deprecation | merge
    summary: string
    evidence: raw/path/evidence.md
```

### 5.5 Review レイヤー固有（`review/synthesis_candidates/*`）

```yaml
# 新規 candidate（distill 出力）:
status: draft | approved
target: wiki/path/target-dir/    # 昇格予定ディレクトリ（optional）

# 拡張差分（rw extend の出力）:
update_type: extension | refactor | deprecation-reference | ...
target: wiki/path/target-page.md  # 更新対象

# 承認済みになったら:
reviewed_by: string
approved_at: YYYY-MM-DD
```

### 5.6 Skill ファイル（`AGENTS/skills/*.md`）

```yaml
name: string                          # snake_case
origin: standard | custom             # standard: Rwiki 配布、custom: ユーザー作成
version: integer                      # default: 1
status: active | deprecated | retracted | archived   # default: active
interactive: true | false             # 対話型スキルか
update_mode: create | extend | both   # 新規のみ / 既存拡張可 / 両対応
handles_deprecated: true | false      # deprecated ページを evidence に使うか
applicable_categories:                # 推奨カテゴリ（optional）
  - papers/local
  - papers/zotero
```

### 5.7 Skill candidate（`review/skill_candidates/*.md`）

```yaml
name: string
base: string | null     # --base で指定した既存スキル名
status: draft | approved | validated
dry_run_passed: true | false
```

### 5.8 Vocabulary candidate（`review/vocabulary_candidates/*.md`）

```yaml
operation: merge | split | rename | deprecate | register
target: string          # canonical tag or vocabulary key
aliases: [string, ...]  # merge の場合
affected_files: [path, ...]
status: draft | approved
```

### 5.9 Follow-up（`wiki/.follow-ups/*.md`）

```yaml
created_at: YYYY-MM-DD
context: string         # どの対話から発生したか
priority: low | medium | high
status: pending | resolved
related_pages: [path, ...]
next_action: string
```

### 5.9.1 Hypothesis candidate（`review/hypothesis_candidates/*.md`、Spec 6）

```yaml
title: string
hypothesis: string                # 仮説本文（1-2 文）
origin: [wiki/path, ...]          # 根拠とする wiki ページ
origin_edges: [edge_id, ...]      # L2 Graph Ledger への逆参照
generated_by: hypothesis_generation
generated_at: YYYY-MM-DD
# Hypothesis 固有 status（Page status / Edge status とは独立）
status: draft | verified | confirmed | refuted | promoted | evolved | archived
confidence: low | medium | high
verification_attempts:            # append-only 配列
  - date: YYYY-MM-DD
    evidence_searched: [path, ...]
    supporting_evidence:
      - evidence_id: ev_XXX       # L2 evidence.jsonl への参照
        quote: string
        source: path:L<start>-L<end>
    refuting_evidence: [...]
    outcome: pending | confirmed | refuted | evolved
    edge_reinforcements:          # この検証で強化された L2 edges
      - edge_id: e_XXX
        delta: +0.NN
successor_wiki: wiki/synthesis/<slug>.md   # promoted 時
next_action: string                        # pending 時のガイド
```

**3 種類の status の独立性**:

| Status 種別 | 対象 | 値域 |
|----------|------|------|
| Page status | L3 wiki ページ | active / deprecated / retracted / archived / merged |
| Edge status | L2 Graph Ledger edge | weak / candidate / stable / core / deprecated / rejected |
| Hypothesis status | review/hypothesis_candidates/ | draft / verified / confirmed / refuted / promoted / evolved / archived |

### 5.9.2 Perspective 保存版（`review/perspectives/*.md`、Spec 6）

```yaml
title: string
type: perspective
generated_by: perspective_generation
generated_at: YYYY-MM-DD
trigger: string                     # ユーザーの発話・文脈
sources: [wiki/path, ...]           # L3 wiki ページ参照
traversed_edges: [edge_id, ...]     # L2 Graph Ledger で活用した edges
                                    # 保存時に各 edge へ usage_signal が加算される
traversed_depth: integer            # N-hop（default 2）
confidence: low | medium | high
tags: [string, ...]
```

### 5.10 L2 Graph Ledger の記録形式

**`.rwiki/graph/entities.yaml`** — 正規化されたエンティティ:

```yaml
entities:
  sindy:
    canonical_path: wiki/methods/sindy.md
    type: method
    aliases: ["Sparse Identification of Nonlinear Dynamics", "SINDy"]
  brunton:
    canonical_path: wiki/entities/people/brunton.md
    type: entity-person
    aliases: ["Steven Brunton", "S. Brunton"]
```

**`.rwiki/graph/edges.jsonl`** — edge の正本（1 行 1 edge）:

```jsonl
{"edge_id":"e_001","source":"wiki/methods/sindy.md","type":"similar_approach_to","target":"wiki/methods/koopman.md","confidence":0.82,"status":"stable","evidence_ids":["ev_001","ev_007"],"extraction_mode":"explicit","created_at":"2026-04-24T15:30:00","updated_at":"2026-04-28T10:00:00","source_file":"raw/papers/local/brunton-2024.md","is_inverse":false}
{"edge_id":"e_002","source":"wiki/methods/koopman.md","type":"similar_approach_to","target":"wiki/methods/sindy.md","confidence":0.82,"status":"stable","evidence_ids":["ev_001","ev_007"],"extraction_mode":"explicit","created_at":"2026-04-24T15:30:00","updated_at":"2026-04-28T10:00:00","source_file":"raw/papers/local/brunton-2024.md","is_inverse":true}
```

**`.rwiki/graph/edge_events.jsonl`** — confidence 変遷の append-only log:

```jsonl
{"edge_id":"e_001","event":"used_in_query","delta":0.04,"query_id":"q_023","reason":"core_answer","timestamp":"2026-04-25T09:15:00"}
{"edge_id":"e_001","event":"decay","delta":-0.01,"timestamp":"2026-04-26T00:00:00"}
{"edge_id":"e_001","event":"reinforcement","delta":0.03,"query_id":"q_041","reason":"chain_support","timestamp":"2026-04-27T14:30:00"}
{"edge_id":"e_099","event":"human_reject","delta":-1.0,"reason":"incorrect_relation","reviewer":"user","timestamp":"2026-04-28T11:00:00"}
```

**`.rwiki/graph/evidence.jsonl`** — 根拠引用集（first-class concept）:

```jsonl
{"evidence_id":"ev_001","file":"raw/papers/local/brunton-2024.md","quote":"SINDy and Koopman operator theory share the same sparse representation paradigm","span":"L234-L238","added_at":"2026-04-24T15:30:00"}
{"evidence_id":"ev_007","file":"wiki/methods/sindy.md","quote":"数学的基盤を Koopman と共有する","span":"L45-L48","added_at":"2026-04-24T15:30:00"}
```

**`.rwiki/graph/rejected_edges.jsonl`** — 人間が reject した edge の記録（削除ではなく保存）:

```jsonl
{"edge_id":"e_099","original_confidence":0.45,"rejected_at":"2026-04-28T11:00:00","reason":"incorrect_relation","source":"wiki/methods/sindy.md","type":"alternative_to","target":"wiki/methods/nerf.md"}
```

**Git 管理方針**: 上記すべて **git 管理**（decay 履歴は reproducible でない、資産として保全）。`.rwiki/cache/graph.sqlite` のみ gitignore（derived、再生成可能）。

---

## 6. Task & Command モデル

### 6.1 Task 一覧

| Task | 実行モード | 対話ガイド | 用途 |
|------|----------|---------|------|
| `lint` | CLI | なし | raw/incoming/ の検証 |
| `ingest` | CLI | なし | raw/incoming/ → raw/ |
| `distill` | CLI Hybrid | Skill による | raw → review 知識候補生成 |
| `approve` | CLI | なし（簡易 confirm） | review → wiki 昇格 / extend/merge の反映 |
| `query answer` | CLI Hybrid | なし | wiki に基づく直接回答 |
| `query extract` | CLI Hybrid | なし | 4 ファイル契約の構造化抽出 |
| `query fix` | CLI Hybrid | なし | query lint エラー修復 |
| `audit links` | CLI | なし | リンク切れ等の高速チェック |
| `audit structure` | CLI | なし | 全頁構造チェック |
| `audit semantic` | CLI Hybrid | なし | LLM 意味的監査 |
| `audit strategic` | CLI Hybrid | なし | LLM 戦略的監査 |
| `audit deprecated` | CLI | なし | deprecated 整合性 |
| `audit tags` | CLI | なし | タグ vocabulary 問題検出 |
| `audit evidence` | CLI | なし | evidence chain 検証（URL 生存等） |
| `audit followups` | CLI | なし | follow-up 未解決警告 |
| `perspective` | CLI Hybrid | なし（mode 切替） | 視点創発（既存知識の再解釈、Spec 6） |
| `hypothesize` | CLI Hybrid | なし（mode 切替） | 仮説生成（未検証の新命題、Spec 6） |
| `discover` | CLI Hybrid | なし（mode 切替） | 関連性発見（Spec 6） |

### 6.2 Command 一覧

#### コア

| Command | 説明 |
|---------|------|
| `rw chat` | 対話型エントリ（LLM CLI 起動、AGENTS 自動ロード） |
| `rw check <file>` | 診断: ファイルに対する適用可能タスク |

#### Input Pipeline

| Command | 説明 |
|---------|------|
| `rw lint [<path>]` | raw/incoming/ のバリデーション |
| `rw ingest` | raw/incoming/ → raw/ 移動 + 自動 commit |
| `rw retag <path-or-glob>` | タグを LLM で再抽出 |

#### Knowledge Generation

| Command | 説明 |
|---------|------|
| `rw distill <file>... [--skill <name>] [--extend <wiki-page>]` | 知識抽出、review に候補生成 |
| `rw extend <source>... --target <wiki-page>` | 既存 wiki 更新の差分ファイル生成 |
| `rw merge <candidate>... [--strategy <s>] [--target <wiki>]` | 候補または wiki の統合（review / wiki 自動判定） |
| `rw split <wiki-page> [--skill concept_map]` | wiki ページ分割 |

#### Approval

| Command | 説明 |
|---------|------|
| `rw approve [<path>]` | review 候補を wiki に反映（新規 / extend / merge / deprecate 等を自動判定） |
| `rw unapprove [<target>] [--commit <sha>] [--dry-run] [--yes]` | 直近または指定 approve を revert |

#### Query / Knowledge Utilization

| Command | 説明 |
|---------|------|
| `rw query answer "<question>" [--scope <path>]` | wiki ベース回答（stdout） |
| `rw query extract "<question>" [--scope] [--type]` | 4 ファイル契約生成 |
| `rw query fix <query_id>` | query lint エラー修復 |
| `rw query promote <query_id>` | query → wiki/synthesis/ 昇格 |
| `rw perspective "<topic>" [--mode autonomous]` | 視点創発（既存知識の再解釈、Spec 6） |
| `rw hypothesize "<topic>" [--mode autonomous]` | 仮説生成（未検証の新命題、Spec 6） |
| `rw discover [--focus <topic>]` | 関連性発見（Spec 6） |

#### Audit

| Command | 説明 |
|---------|------|
| `rw audit {links, structure, semantic, strategic, deprecated, tags, evidence, followups}` | 各次元の監査 |
| `rw audit graph [--communities] [--find-bridges] [--repair-symmetry] [--propose-relations]` | L2 Graph Ledger の整合性監査（Scenario 10 拡張） |

#### L2 Graph Ledger 管理（Spec 5）

| Command | 説明 |
|---------|------|
| `rw graph rebuild [--verify]` | Ledger から SQLite cache を再生成 |
| `rw graph status` | 統計表示（edge 数、confidence 分布、status 別件数） |
| `rw graph hygiene [--dry-run] [--apply decay|competition|merge]` | 進化則の実行 |
| `rw graph neighbors <page> [--depth N] [--relation <type>]` | N-hop 近傍取得 |
| `rw graph path <from> <to>` | 最短経路探索 |
| `rw graph orphans` | 孤立ノード一覧 |
| `rw graph hubs [--top N]` | 次数の高いノード |
| `rw graph bridges <cluster-a> <cluster-b>` | cluster 間 missing bridge |
| `rw graph export --format {dot|mermaid|json} [--scope <path>]` | 可視化用 export |

#### Edge 個別操作（Spec 5）

| Command | 説明 |
|---------|------|
| `rw edge show <edge-id>` | Edge 詳細 + events 履歴 |
| `rw edge promote <edge-id>` | candidate → stable 手動昇格 |
| `rw edge demote <edge-id>` | ランクダウン |
| `rw edge history <edge-id>` | events 時系列 |

#### Entity / Relation 抽出（Spec 5）

| Command | 説明 |
|---------|------|
| `rw extract-relations <page>` | 特定ページから自動抽出 |
| `rw extract-relations --all` | wiki 全体を対象 |
| `rw extract-relations --since "7 days"` | 直近更新分 |
| `rw extract-relations --new-only` | typed edges がないページだけ |

#### Reject workflow（Spec 5、Scenario 35）

| Command | 説明 |
|---------|------|
| `rw reject` | reject_queue 対話処理 |
| `rw reject <edge-id>` | 特定 edge を reject |
| `rw reject --auto-batch` | confidence < 0.2 を一括 reject 候補に |

#### Page Lifecycle

| Command | 説明 |
|---------|------|
| `rw deprecate <wiki-page> [--reason] [--successor] [--auto]` | 非推奨化（対話ガイド必須） |
| `rw retract <wiki-page> [--reason]` | 撤回（対話ガイド必須、auto 不可） |
| `rw archive <wiki-page> [--reason]` | プロジェクト終了等のアーカイブ |
| `rw reactivate <wiki-page>` | deprecated / archived → active 復帰 |

#### Tag Vocabulary

| Command | 説明 |
|---------|------|
| `rw tag scan` | 問題候補一覧 |
| `rw tag stats [<tag>]` | 統計 |
| `rw tag diff <a> <b>` | 2 タグの類似度分析 |
| `rw tag merge <canonical> <aliases>...` | 統合（対話必須） |
| `rw tag split <tag> <new-tags>...` | 分割（対話必須） |
| `rw tag rename <old> <new>` | 単純改名 |
| `rw tag deprecate <tag>` | 非推奨マーク |
| `rw tag register <tag> [--desc]` | 未登録タグを登録 |
| `rw tag vocabulary {list, show, edit}` | vocabulary 管理 |
| `rw tag review` | 対話的 vocabulary 整理セッション |

#### Skill Library

| Command | 説明 |
|---------|------|
| `rw skill list` | スキル一覧 |
| `rw skill show <name>` | スキル詳細 |
| `rw skill draft <name> [--base <skill>]` | 新規スキル草案生成 |
| `rw skill test <candidate-or-name> [--sample <file>]` | dry-run |
| `rw skill install <candidate>` | validation + dry-run + 登録 |
| `rw skill deprecate <name> [--reason]` | スキル非推奨化 |
| `rw skill retract <name>` | スキル撤回（害ある使用禁止） |

#### Follow-up

| Command | 説明 |
|---------|------|
| `rw follow-up list` | 未解決 follow-up 一覧 |
| `rw follow-up show <file>` | 個別表示 |
| `rw follow-up resolve <file>` | 解決済みマーク |
| `rw follow-up remind` | 優先度順表示 |

#### Vault 管理

| Command | 説明 |
|---------|------|
| `rw init <path>` | 新規 Vault 初期化 |
| `rw init <path> --reinstall-symlink` | symlink のみ張り替え |

---

## 7. Spec 群

### 7.1 Spec 計画全体像

```
Spec 0: rwiki-v2-foundation           傘スペック、ビジョン・原則・用語集
├── Spec 1: classification-system     カテゴリ、frontmatter、vocabulary (基盤)
├── Spec 2: skill-library             スキル定義・dispatch・custom skill
├── Spec 3: prompt-dispatch           スキル選択メカニズム（明示/type/category/LLM）
├── Spec 4: cli-mode-unification      rw chat、全コマンド rw 統一、対話 default
├── Spec 5: knowledge-graph           typed edges、vocabulary/relations、graph query
├── Spec 6: perspective-generation    視点創発・仮説生成（本丸、シナリオ 14 議論待ち）
└── Spec 7: lifecycle-management      deprecate/retract/archive/merge/split/rollback
```

**Note**:
- v2 の全 Spec は**新名称のみを使用**して設計される（v1 を参照しない）
- v1 → v2 の命名対応表は §11.3（開発期の参照資料）に置く。これはスペック成果物ではなく、v2 実装時に v1 コード・テストを読む際の便宜マップ
- 当初案にあった Spec 5（command-naming）は独立スペック化せず、§11.3 の参照資料として扱う。以降のスペック番号を繰り上げた

### 7.2 各 Spec の詳細

#### Spec 0: rwiki-v2-foundation

**Purpose**: v2 全体のビジョン・原則・用語・アーキテクチャを定義し、他 Spec の上位規範とする。

**Boundary**:
- In scope: §1（ビジョン）、§2（中核原則、12 項目）、§3（3 層アーキテクチャ）、§4（用語集 5 分類）、§5（frontmatter schema）、§6（command model）を Spec 0 の内容とする
- Out of scope: 個別機能の実装（他 Spec）、Graph Ledger 詳細仕様（Spec 5）

**Key Requirements**:
- Rwiki の中核価値（Trust + Graph + Perspective + Hypothesis の四位一体）の明文化
- **3 層アーキテクチャ**（L1 Raw / L2 Graph Ledger / L3 Curated Wiki）の明示
- **12 中核原則**の明記（§2.1〜§2.12、Graph Ledger 原則 §2.12 含む）
- コマンド 4 Level 階層（L1 発見 / L2 判断 / L3 メンテ LLM ガイド / L4 Power user）
- エディタとの責務分離ポリシー（Obsidian を参照実装として）
- 用語集の 5 分類（基本 / アーキテクチャ / Graph Ledger / Perspective-Hypothesis / Operations）
- **Edge status（6 種）と Page status（4 種）を明確に区別**
- ユーザー primary interface は発見、メンテナンスは LLM guide（§2.11）
- Evidence-backed Candidate Graph の原則（§2.12、Evidence 必須 / Reject-only / 使用で育つ）

#### Spec 1: classification-system

**Purpose**: カテゴリ・frontmatter スキーマ・タグ vocabulary の基盤設計。L3 Curated Wiki の分類体系を確立する。

**Boundary**:
- In scope:
  - カテゴリディレクトリ構造（articles / papers / notes / narratives / essays / code-snippets / llm_logs）
  - 共通・L3 wiki 固有・review 固有の frontmatter スキーマ（§5）
  - `.rwiki/vocabulary/tags.yml` スキーマ（Scenario 12）
  - `.rwiki/vocabulary/categories.yml`（拡張）
  - Tag 操作コマンド（`rw tag *`）
  - lint の vocabulary 統合
  - **L3 frontmatter `related:` を derived cache として位置付け**（正本は Spec 5 の Graph Ledger）
  - **Entity 固有ショートカット field（`authored:`, `collaborated_with:` 等）の定義**（内部正規化は Spec 5）
- Out of scope:
  - Typed edges の正本管理（Spec 5 Graph Ledger）
  - Skill 内のタグ自動抽出（Spec 2）
  - Relation vocabulary 定義（Spec 5 の `.rwiki/vocabulary/relations.yml`）

**Key Requirements**:
- カテゴリは「強制されたディレクトリ」ではなく「推奨パターン」
- ユーザーが `.rwiki/vocabulary/categories.yml` で拡張可能
- source はカテゴリから自動推論しない（frontmatter 必須、自由文字列）
- タグ vocabulary は最小スキーマ（canonical + description + aliases）
- 未登録タグは INFO、エイリアスは WARN、非推奨は WARN
- **L3 frontmatter `related:` の扱い**: Graph Ledger (`edges.jsonl`) からの derived cache、`rw graph sync` で整合
- **Entity 固有ショートカット**: frontmatter の `authored:`, `collaborated_with:`, `mentored:`, `implements:` 等は entity type 別に定義し、内部で typed edge へ展開される（Spec 5）

**新規 review 層**: `review/vocabulary_candidates/`

#### Spec 2: skill-library

**Purpose**: タスクと出力形式を分離し、スキルライブラリ経由で多様な出力を実現。L1 raw から L2/L3 へのコンテンツ生成を担う。

**Boundary**:
- In scope:
  - `AGENTS/skills/` ディレクトリ構造
  - Skill ファイルの 8 section スキーマ
  - Skill frontmatter 属性（origin / interactive / update_mode / handles_deprecated / applicable_categories）
  - 初期スキル群:
    - **知識生成 skills**: paper_summary / multi_source_integration / cross_page_synthesis / personal_reflection / llm_log_extract / narrative_extract / concept_map / historical_analysis / code_explanation / entity_profile / generic_summary / interactive_synthesis
    - **Graph 抽出 skills**（新）: `relation_extraction` / `entity_extraction` — L2 Graph Ledger 向け
    - **Lint 支援 skills**（新）: `frontmatter_completion` — Scenario 26
  - Custom skill 作成フロー（`rw skill draft/test/install`、Scenario 20）
  - `review/skill_candidates/` 層
  - Dry-run 必須化
- Out of scope:
  - Skill 選択ロジック（Spec 3）
  - Skill lifecycle（Spec 7）
  - Graph 抽出結果の格納・進化（Spec 5）

**Key Requirements**:
- 必須 8 section: Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions
- `update_mode: extend` 対応（差分マーカー形式、Option 1 HTML コメント）
- Install 時の validation（8 section / YAML / 衝突 / 参照整合性）
- Install 前に dry-run 最低 1 回必須
- `origin: standard | custom` の区別、`rw init` は standard のみ配布
- Skill export/import は v2 MVP 外（将来拡張）
- **Graph 抽出 skill の出力先**: `review/relation_candidates/` → human reject で filter → `.rwiki/graph/edges.jsonl`（Spec 5 連携）

#### Spec 3: prompt-dispatch

**Purpose**: distill タスクでのスキル選択メカニズムを定義。

**Boundary**:
- In scope:
  - スキル選択の優先順位: 明示指定 → frontmatter `type:` → カテゴリ default → LLM 判断
  - LLM 毎回判定方式（設計判断 #2 = b）
  - スキル欠如時の `generic_summary` fallback（設計判断 #10 = b）
  - `.rwiki/vocabulary/categories.yml` のカテゴリ → default skill マッピング
- Out of scope: Skill 内容自体（Spec 2）、Perspective 選択（Spec 6）

**Key Requirements**:
- 明示 `--skill` は常に最優先
- `type:` frontmatter があれば LLM 判断とのコンセンサス確認
- LLM は毎回コンテンツを読んで最適スキルを推論（精度優先）
- 推論結果と明示指定が食い違う場合、ユーザーに確認

#### Spec 4: cli-mode-unification

**Purpose**: すべてのタスクを `rw <task>` で統一、対話型エントリ `rw chat` を追加、メンテナンス UX（L3 LLM ガイド主体）を実装。

**Boundary**:
- In scope:
  - `rw chat` コマンド（LLM CLI 起動、AGENTS 自動ロード、Maintenance UX を含む）
  - 各タスクの CLI 統一
  - 対話型 default / `--auto` フラグの可否
  - `rw check <file>` 診断コマンド
  - `rw follow-up *` コマンド群
  - **Maintenance UX（Scenario 33）**: 曖昧指示の候補提示、複合診断オーケストレーション、Autonomous maintenance 提案
  - **L2 Graph Ledger 管理コマンドの実装**（内部は Spec 5 の API を呼出）:
    - `rw graph {rebuild, status, hygiene, neighbors, path, orphans, hubs, bridges, export}`
    - `rw edge {show, promote, demote, history}`
    - `rw extract-relations [...]`
    - `rw reject [...]`
    - `rw audit graph [...]`
  - `rw doctor` コマンド（複合診断、Scenario 33）
- Out of scope:
  - Skill library 実装（Spec 2）
  - Graph Ledger の内部ロジック（Spec 5）
  - Page lifecycle（Spec 7）

**Key Requirements**:
- `rw chat` はエディタ内蔵ターミナル（VSCode / Obsidian 等）や別プロセスから起動可能
- 対話中に LLM が Bash tool 等で `rw <task>` を内部呼出
- Dangerous op コマンドの default は対話型
- `--auto` 許可: deprecate / archive / reactivate / tag merge / tag rename / skill install / extract-relations（非 dangerous）/ reject `<edge-id>`（指定時）
- `--auto` 不可: retract / unapprove / promote-to-synthesis / tag split / skill retract
- **Maintenance UX の候補提示**: ユーザーの曖昧発話に対して拒絶せず、候補タスク（L3 の 20+ コマンド）を提示する（Scenario 33）
- **Autonomous maintenance**: edge reject queue 蓄積、L2 ledger 状態異常（decay 進行・矛盾増加）、未 approve 残数等を surface
- L4 Power user 向けに全コマンド直接実行も提供（CI/CD 対応）

**注**: v2 のコマンド名は §6（Task & Command モデル）で既に定義されており、Spec 4 は**その名前で実装するだけ**。v1 からの命名マッピングは §11.3（開発期参照資料）を参照。v2 スペックは v1 を「知らない」前提で自己完結的に設計されている。

#### Spec 5: knowledge-graph（Evidence-backed Candidate Graph + Hygiene）

**Purpose**: L2 Graph Ledger を実装し、evidence-backed candidate graph を自動生成・進化させる基盤を提供。人間の approve を必須としない graph 運用を実現しつつ、evidence 必須で trust chain を保つ。

**Boundary**:

- In scope:
  - **Graph Ledger 基盤**
    - `.rwiki/graph/entities.yaml`, `edges.jsonl`, `edge_events.jsonl`, `evidence.jsonl`, `rejected_edges.jsonl`, `reject_queue/`, `decision_log.jsonl`（§2.13 Curation Provenance）
    - `.rwiki/cache/graph.sqlite`（derived index、gitignore）
    - `.rwiki/vocabulary/relations.yml` / `entity_types.yml` 定義
  - **Entity 抽出と正規化**
    - LLM ベースの entity 抽出（Scenario 34）
    - Alias / normalization（entities.yaml で管理）
  - **Relation（edge）抽出**
    - LLM ベースの 2-stage extraction（GraphRAG-inspired）
    - Evidence 必須（evidence.jsonl への参照）
    - extraction_mode: `explicit` / `paraphrase` / `inferred` / `co_occurrence`
  - **Confidence scoring**
    - 初期値計算式・evidence-less 上限・Status 境界は **§2.12 を SSoT** とする。Spec 5 は式の再掲を行わず、**§2.12 の値を実装** する役割に徹する
    - 実装のため必要な値は `.rwiki/config.yml` の `graph.confidence_weights` / `graph.auto_accept_threshold` / `graph.candidate_weak_boundary` / `graph.reject_queue_threshold` / `graph.evidence_required_ceiling` から注入
  - **Edge lifecycle**
    - Status: `weak / candidate / stable / core / deprecated / rejected`
    - 遷移条件（confidence 閾値、decay、reject 等、§2.12 の閾値表と整合）
  - **Graph Hygiene（進化則、5 ルール）**
    - **Decay**（時間減衰、`decay_rate_per_day` で調整）
    - **Reinforcement**（usage による強化、後述 usage_signal 4 種別）
    - **Competition**（類似 edge の優劣、後述 3 レベル）
    - **Contradiction tracking**（矛盾の明示化、削除せず構造化保持）
    - **Edge Merging**（類似 relation の統合、ontology を自然形成、Page merged status とは別概念）
  - **Usage signal（4 種別 + 式）**
    - 式: `base_score × contribution_weight × sqrt(confidence) × independence_factor × time_weight`
    - **4 種別の contribution_weight**:

      | 種別 | contribution_weight | 発生条件 |
      |------|---------------------|---------|
      | **Direct**（直接引用） | 1.0 | perspective/hypothesis answer の本文で edge を引用 |
      | **Support**（補助引用） | 0.6 | answer の補強として edge を参照（primary ではない） |
      | **Retrieval**（検索ヒット） | 0.2 | graph neighbor / path 探索で touch されたが answer に未採用 |
      | **Co-activation**（同時活性） | 0.1 | 同 session で他 edge と一緒に traverse された |

    - query / perspective / hypothesize 時に edge_events.jsonl に追記
    - `sqrt(confidence)`: 高 confidence edge の自己強化を緩和（フィードバックループ抑制）
    - `independence_factor`: 同一 session 内で既に強化済なら 0 に近づける（spam 防止）
    - `time_weight`: 古い event は減衰（`time_decay_half_life` で調整）
  - **Competition（3 レベル）**

    | Level | 対象 | 処理 | 実装優先度 |
    |-------|------|-----|----------|
    | **L1** | **同一 node pair** 内の複数 edge（A→B 関係が複数 relation_type で存在） | 最高 confidence が winner → stable、他は runner-up → candidate / loser → weak | MVP 必須 |
    | **L2** | **類似 node pair**（概念的に重複する edge、embedding 距離ベース） | winner を残し、他は merge 候補 / deprecated | Phase 3 |
    | **L3** | **semantic tradeoff / contradiction** | 両方残して `contradiction_with:` で相互参照（削除しない） | Phase 3 |

    **status transition（3 レベル共通）**: winner → stable / runner-up → candidate / loser → weak / obsolete → deprecated（削除ではなく状態変更）

  - **Event ledger（edge_events.jsonl）**
    - confidence 変遷の時系列 append-only 記録
    - Event type: `created / reinforced(Direct|Support|Retrieval|Co-activation) / decayed / promoted / demoted / rejected / merged / contradiction_flagged`
  - **Decision log（decision_log.jsonl、§2.13 Curation Provenance、P0 必須）**
    - Schema: `decision_id` / `ts` / `decision_type` / `actor` / `subject_refs[]` / `reasoning` / `alternatives_considered[]` / `outcome` / `context_ref` / `evidence_ids[]`
    - Decision types: `edge_extraction / edge_reject / edge_promote / edge_unreject / hypothesis_verify / synthesis_approve / page_deprecate / tag_merge / split / hygiene_apply`
    - Selective recording: confidence boundary（0.45±0.05）/ contradiction / 人間 action / status 遷移 / synthesis 操作のみ auto-record
    - Reasoning 入力 hybrid: chat session からの LLM auto-generate / `--reason` flag / default skip
    - Append-only、git 管理 default、`config.decision_log.gitignore: true` で privacy mode
  - **Reject workflow**
    - `reject_queue/` に人間判断待ち edge
    - `rw reject` で処理、rejected_edges.jsonl に移動、**decision_log にも記録**（reject_reason_text + 結果）
  - **Entity ショートカット field の正規化（Spec 1 と Spec 5 の境界を明示）**
    - **API**: Spec 5 が `normalize_frontmatter(page_path) → List[Edge]` を提供（Query API 表参照）
    - **Invoker**: Spec 4 CLI の `rw ingest` / `rw approve` / `rw graph rebuild` が呼び出す（直接実装は Spec 4 に置かない、Spec 5 API 経由で責務を集中）
    - **Spec 1 の責務**: frontmatter スキーマ（`authored:`, `collaborated_with:`, `implements:` 等）と `relations.yml` の mapping table を**定義**
    - **Spec 5 の責務（normalize_frontmatter 内部ロジック）**:
      1. Entity 固有 field → `relations.yml` の mapping table を参照
      2. source は当該ページ、target は field の値（`[[link]]` または entity id）
      3. extraction_mode は `explicit`（frontmatter 明示のため最高 explicitness）
      4. `inverse:` / `symmetric:` に従って双方向 edge を自動生成（`authored` ⇄ `authored_by` 等）
      5. evidence_ids は空（frontmatter 自体が evidence、`evidence.jsonl` に特殊 source `"frontmatter"` で登録）
      6. confidence は 0.9（人間が直接記述した root of trust として高値固定）
      7. Entity alias 衝突時は `relations.yml` の `canonical:` 値を優先、曖昧時は警告出力（normalize は skip、user に手動 resolve を要求）
    - **冪等性**: 同一 page を複数回 normalize しても duplicate edge を作らない（edge_id は source+type+target の hash で決定、既存は upsert）
  - **Graph query API（Spec 6 / audit / CLI から呼び出される内部 API、§Query API Design 参照）**
    - SQLite cache ベースの高速 traverse（P1）
    - Local query: N-hop neighbors、shortest path、orphans、hubs（P1）
    - Global query: community-level aggregation、hierarchical summary（P2 以降）
    - Missing bridge detection（P1、`rw graph bridges` 経由）
    - Edge status / confidence filter（呼出元が指定）
  - **Community detection（GraphRAG-inspired）**
    - networkx ベース（Leiden/Louvain）
    - Community id を nodes テーブルに格納
  - **Graph audit**
    - `rw audit graph` コマンド
    - 対称性、循環、孤立、参照整合性、confidence 分布
  - **Rebuild / sync**
    - 増分 rebuild（ingest / approve 後）
    - Full rebuild（`rw graph rebuild`）
    - Stale detection（CLI 起動時）
    - frontmatter `related:` との sync（L3 derived cache）
  - **外部依存**
    - `networkx >= 3.0` を必須に追加

- Out of scope:
  - Perspective / Hypothesis 生成（Spec 6）
  - Wiki page lifecycle（Spec 7）
  - Skill 設計（Spec 2）
  - Tag vocabulary（Spec 1）

**Key Requirements**（Phase マーカーは実装順序、§Spec 5 末尾「実装フェーズ」表と対応）:

1. **[P0]** **Ledger が source of truth**: L2 edges の正本は `edges.jsonl`。frontmatter `related:` は derived cache（sync 必須）
2. **[P0]** **Evidence 必須**: 全 edge は evidence_ids を持つ。evidence なしは confidence ≤ 0.3 に強制（§2.12 参照）
3. **[P0]** **Edge lifecycle の自動進化**: confidence ≥ 0.75 で candidate → stable auto-accept
4. **[P0]** **Reject-only human filter**: 人間は reject のみ判断、全 approve は求めない
5. **[P0]** **Relation type vocabulary**:
   - **初期 canonical 12 セット（P0 fixture として配布、汎用抽出向け）**: `uses / depends_on / causes / improves / degrades / compares_with / alternative_to / part_of / supports / contradicts / co_occurs_with / related_to`
   - **抽象関係（拡張、P0 提供 + 任意追加）**: `similar_approach_to / contrasted_with / extended_by / unified_in / superseded_by / prerequisite_of / application_of / derived_from`
   - **Entity 固有（P0 提供、frontmatter shortcut 経由）**: `authored / authored_by / collaborated_with / mentored / mentored_by / implements / implemented_by / critiqued / advocates / contemporary_of` 等
   - **拡張方針**: 最初から大きな ontology は作らない。使用実態から必要なものを順次追加
   - `relations.yml` で `inverse:` / `symmetric:` / `domain:` / `range:` 定義
6. **[P0]** **`[[link]]` syntax は untyped edge として並存**、後付け typing 可能
7. **[P0]** **JSONL フォーマット**: append-only、diff に優しい、人間可読
8. **[P1]** **Query cache (sqlite)**: graph.sqlite から neighbor / path / orphans / hubs / bridges が取得可能（§Query API 参照）
9. **[P2]** **Hygiene は定期バッチ**: `rw graph hygiene` で実行、CLI 起動時の軽量 stale check とは別。Decay + Reinforcement + Competition L1 が MVP
10. **[P2]** **Usage event 記録**: 4 種別（Direct/Support/Retrieval/Co-activation）を edge_events.jsonl に追記
11. **[P2]** **Community detection**: `rw audit graph --communities` で networkx 経由（MVP に含む、community id を node に付与）
12. **[P3]** **Competition L2/L3 + Edge Merging**: 類似 node pair / semantic tradeoff / contradiction tracking（v0.8 候補、MVP 外）
13. **[P1]** **Rebuild 自動化**: CLI が graph を使う前に stale 検出、軽微なら増分、大きければ警告 + `rw graph rebuild` 案内
14. **[P4 optional]** **外部 Graph DB export**: Neo4j / GraphML 等、要件発生時のみ

**MVP 範囲**: P0 + P1 + P2（要件 1-11, 13）。P3（12）は v0.8、P4（14）は要件発生時のみ。

**主要コマンド**:

```bash
# Graph 管理（L3 LLM ガイド主体）
rw graph rebuild [--verify]
rw graph status
rw graph hygiene [--dry-run] [--apply decay|competition|merge]

# Edge 個別操作
rw edge show <edge-id>
rw edge promote <edge-id>            # candidate → stable 手動
rw edge demote <edge-id>
rw edge history <edge-id>            # events 時系列

# Reject
rw reject                            # reject_queue 対話処理
rw reject <edge-id>
rw reject --auto-batch               # confidence < 0.2 を一括 reject 候補

# Entity/Relation 抽出
rw extract-relations <page>
rw extract-relations --all
rw extract-relations --since "7 days"
rw extract-relations --new-only      # typed edges がないページだけ

# Audit
rw audit graph [--communities] [--find-bridges] [--repair-symmetry] [--propose-relations]

# Query（内部 API、perspective/hypothesize が呼び出す）
rw graph neighbors <page> [--depth N] [--relation <type>]
rw graph path <from> <to>
rw graph orphans
rw graph hubs [--top N]
rw graph bridges <cluster-a> <cluster-b>

# Export（可視化用）
rw graph export --format {dot|mermaid|json} [--scope <path>]

# Decision log（§2.13 Curation Provenance、Spec 4 layer の CLI も参照）
rw decision history <decision-id>           # 特定 decision 詳細
rw decision history --edge <edge-id>        # edge を生んだ decisions の時系列
rw decision history --page <path>           # page の curation timeline
rw decision recent [--since "7 days"]       # 直近 decisions
rw decision stats                           # type / actor 別集計
rw decision search "<keyword>"              # reasoning 内検索
rw decision contradictions                  # 過去 decision 間の矛盾検出（P2）
rw decision render --edge <id>              # markdown timeline 生成（review/decision-views/）
```

**新規 review 層**: `review/relation_candidates/` （Entity/Relation 抽出提案の承認 buffer）、`review/audit_candidates/` （graph audit 修復提案）、**`review/decision-views/`（Tier 2 visualization、`rw decision render` の出力先）**

**Configuration**（`.rwiki/config.yml`）:

```yaml
graph:
  auto_accept_threshold: 0.75          # candidate → stable 昇格
  candidate_weak_boundary: 0.45        # candidate / weak 境界
  reject_queue_threshold: 0.3          # これ以下は reject 候補
  evidence_required_ceiling: 0.3       # evidence なし edge の上限
  confidence_weights:                  # 初期 confidence 計算（§2.12 と整合、合計 1.0）
    evidence: 0.35
    explicitness: 0.20
    source_reliability: 0.15
    graph_consistency: 0.15
    recurrence: 0.10
    human_feedback: 0.05
  hygiene:
    decay_rate_per_day: 0.01
    usage_reinforcement_alpha: 0.05
    recurrence_beta: 0.03
    contradiction_penalty: 0.1
    batch_schedule: weekly             # or 'on-demand'
    max_reinforcement_delta_per_event: 0.1   # 1 event で増やせる confidence 上限
    max_reinforcement_delta_per_day: 0.2     # 1 edge の 1 日合計 delta 上限（暴走防止）
  usage_signal:
    contribution_weights:              # 4 種別の重み
      direct: 1.0
      support: 0.6
      retrieval: 0.2
      co_activation: 0.1
    time_decay_half_life_days: 30
  competition:
    enable_level_2: false              # Phase 3 で有効化
    enable_level_3: false              # Phase 3 で有効化
    similarity_threshold: 0.85         # L2 の embedding 距離閾値
  community:
    algorithm: louvain                 # or 'leiden'
    resolution: 1.0

decision_log:                          # §2.13 Curation Provenance
  gitignore: false                     # default: git 管理（reproducibility）、true で privacy mode
  auto_record_triggers:
    confidence_boundary_window: 0.05   # candidate-weak 境界 ±0.05 で記録
    record_on_human_action: true       # approve / reject / merge / split は必須記録
    record_on_contradiction: true      # 矛盾検出時は必須記録
    record_on_status_transition: true  # candidate → stable 等の遷移
    record_on_synthesis_promotion: true # wiki/synthesis/ 昇格
    record_silent:                     # 以下は記録しない（routine、event log で十分）
      - hygiene_routine_decay
      - hygiene_routine_reinforce
      - extraction_with_confidence_above_0.85
  reasoning_input:
    auto_generate_from_chat: true      # rw chat の context があれば LLM が要約候補生成
    allow_default_skip: true           # 入力負担回避用、"default" 印で記録
    require_for:                       # これらは reason 必須（skip 不可）
      - hypothesis_verify_confirmed
      - hypothesis_verify_refuted
      - synthesis_approve
      - retract
```

**Query API Design（Spec 5 所管、Spec 6 / audit / CLI から呼出）**:

Spec 6（Perspective / Hypothesis）および `rw audit graph` / `rw graph *` コマンドは、L2 Graph Ledger を直接読まず、**以下の Query API 経由**でアクセスする。API の実装は Spec 5 に閉じる。呼出元 Spec は API の signature と返り値 schema のみに依存する。

| API | 用途 | Phase | 返り値 |
|-----|------|-------|-------|
| `get_neighbors(node, depth, filter)` | N-hop 近傍取得（depth / edge status / confidence filter 指定可） | P1 | List[Edge] |
| `get_shortest_path(from, to, filter)` | 2 node 間最短経路 | P1 | List[Edge] |
| `get_orphans()` | 孤立 node（in_degree = out_degree = 0） | P1 | List[Node] |
| `get_hubs(top_n)` | 中心性 top N（degree / pagerank） | P1 | List[Node] |
| `find_missing_bridges(cluster_a, cluster_b, top_n)` | 2 cluster 間の候補 edge（類似度ベース） | P1 | List[(Node, Node, score)] |
| `get_communities(algorithm)` | community detection の結果 | P2 | List[Community] |
| `get_global_summary(scope, method)` | 大局 scope の集約（node 数 / 主要 relation / 代表 entity） | P2 | Summary |
| `get_hierarchical_summary(community_id)` | community 単位の on-demand 要約 | P2 | Summary |
| `get_edge_history(edge_id)` | edge_events.jsonl からの時系列復元 | P0 | List[Event] |
| `normalize_frontmatter(page_path)` | L3 page frontmatter の Entity shortcut（`authored:` / `implements:` 等）を typed edge に展開、edges.jsonl に append。`rw ingest` / `rw approve` / `rw graph rebuild` が invoke | P0 | List[Edge] |
| `record_decision(decision)` | decision_log.jsonl に新しい decision を append（selective trigger を満たす場合のみ呼出側 invoke） | P0 | decision_id |
| `get_decisions_for(subject_ref)` | 特定 edge / page / hypothesis に関連する decisions を時系列取得 | P0 | List[Decision] |
| `search_decisions(query, filter)` | reasoning text の keyword / type / actor / 期間で検索 | P1 | List[Decision] |
| `find_contradictory_decisions()` | 過去 decisions 間で矛盾する判断を検出（同一 subject に対する反対方向の decision） | P2 | List[(Decision, Decision)] |

**共通フィルタ引数**（全 API 共通、呼出元が指定可能）:
- `status_in: List[EdgeStatus]` — edge status の集合（default `[stable, core]`）
- `min_confidence: float` — 絶対値フィルタ（edge status filter とは独立）
- `relation_types: List[str]` — relation_type の絞込（default 全て）

**返り値スキーマ**: `.rwiki/graph/edges.jsonl` と同形の dict（§5.10 参照）。呼出元は JSONL を直接読まず、API が返す dict に依存する。

**性能要件（Query API）**:
- P1 以降、`get_neighbors(depth=2)` は 100-500 edges で 100ms 以下
- Community / global summary はキャッシュ利用推奨、キャッシュ無効化は hygiene バッチのタイミング

**Hygiene 運用ポリシー**:

- **Concurrency モデル（MVP）**: **Single-user serialized execution**。複数 CLI プロセスが同時に `.rwiki/graph/*.jsonl` を書かないことを保証する。
  - 実装: `.rwiki/.hygiene.lock` file lock（fcntl/flock）を Hygiene 実行中に取得、ingest / reject / approve / extract-relations はロック取得待ち（short wait）/ 失敗時は明示エラー
  - Query API（read-only）はロック不要、Hygiene 実行中でも動作（append-only の事前状態を読む）
  - Phase 2（将来）で multi-user や distributed lock の検討余地あり（MVP 範囲外）
- **Transaction semantics**: 1 回の Hygiene 実行は **all-or-nothing**。
  - 途中クラッシュ時: 実行前の git commit に revert（`.rwiki/.hygiene.tx.tmp/` 等の一時領域で書いて commit 時に merge、失敗時は tmp を破棄）
  - edges.jsonl / edge_events.jsonl は atomic rename（`write-to-tmp → fsync → rename`）で更新
- **ルール実行順序**: 固定順で直列実行（並列不可）: `Decay → Reinforcement → Competition → Contradiction tracking → Edge Merging`
  - 理由: 後段ルールが前段の結果に依存（例: Decay 後の confidence で Competition 判定、Competition 後の winner を Merging 対象にする）
  - Phase 3（L2/L3 competition）以降で rule interaction graph を詳細化（MVP は単純 sequential）
- **Autonomous 発火 trigger 条件**（Scenario 14 autonomous mode と連携、Spec 6 も参照）:
  - **reject queue 蓄積**: 未処理 reject 候補 ≥ 10 件
  - **Decay 進行 edges**: `days_since_last_usage > decay_warn_days`（default 7）の edges ≥ 20 件
  - **typed-edge 整備率低下**: wiki ページあたり平均 typed-edge 数が閾値（default 2.0）未満
  - **Dangling edge 増加**: dangling_flagged 状態の edges ≥ 5 件
  - いずれかに該当時、Maintenance autonomous mode が `💡 Hygiene を走らせますか？` を surface（即座に apply ではなく提案のみ）

**パフォーマンス目標（MVP）**:

| 規模 | `rw graph hygiene` 実行時間 | `rw graph hygiene --dry-run` | Query API（neighbor depth=2） |
|------|---------------------------|------------------------------|-------------------------------|
| 1,000 edges | ≤ 30 秒 | ≤ 10 秒 | ≤ 100 ms |
| 10,000 edges | ≤ 5 分 | ≤ 1 分 | ≤ 300 ms |
| 100,000 edges（将来）| ≤ 30 分（部分 scope 推奨）| ≤ 5 分 | ≤ 1 秒 |

**Vault 規模の MVP 想定**: 個人用途で edges 500-5000、entities 100-500、evidences 1000-10000 程度。10000 edges を超える規模では `--scope` による部分 Hygiene（community 単位 / 直近 N 日更新分）を推奨（Phase 2 以降）。

**L3 `related:` cache invalidation 戦略（Hybrid stale-mark + Hygiene batch）**:

L2 edges.jsonl が正本、L3 wiki frontmatter `related:` は derived cache として sync する。sync 戦略は以下:

1. **Stale mark（edge 変更時）**: edges.jsonl の追加・更新・削除イベントが発生したとき、影響する L3 page path を `.rwiki/cache/stale_pages.txt` に追記（append-only、重複は後続で解消）
2. **Batch sync（Hygiene 時）**: Hygiene batch の最終段階で `stale_pages.txt` を読み、該当 page の `related:` を L2 ledger から再計算して frontmatter 更新、処理後 stale list をクリア
3. **Stale detection（CLI 起動時）**: `rw chat` / 他 CLI 起動時に `stale_pages.txt` が N 件（default 20）以上蓄積していたら「L3 sync 未反映 N 件、`rw graph hygiene` 推奨」と警告
4. **Manual sync**: `rw graph rebuild --sync-related` で即座実行可（緊急時）
5. **整合性レベル**: L3 `related:` は eventual consistency。正本は L2 ledger なので query / perspective / hypothesis は L2 を直接読み、cache 遅延の影響を受けない

**Stale 情報の記録フォーマット（`.rwiki/cache/stale_pages.txt`）**:
```
wiki/methods/sindy.md	2026-04-25T10:30:00Z	edge_added:e_042
wiki/methods/koopman.md	2026-04-25T10:30:00Z	edge_updated:e_042
wiki/methods/sindy.md	2026-04-25T11:00:00Z	edge_promoted:e_042
```
（page_path \t timestamp \t event_summary、batch sync で page_path 単位に集約）

**Edge Unreject 復元方針**:

`rw edge unreject <edge-id>` 実行時の復元ルール:
1. **Status**: reject 直前の status（`reject_history` に記録された `pre_reject_status`）に復帰。ただし `stable` / `core` からの reject だった場合は `candidate` にリセット（時間経過による再評価を強制）
2. **Confidence**: evidence ceiling（0.3）と reject 直前値の低い方にクランプ。reject 後の時間経過で decay が本来進行していたはずなので、復帰時点で一度リセットして Hygiene サイクルで再評価させる
3. **evidence_ids**: reject 時点の evidence_ids を復元（rejected_edges.jsonl に保全されている）。復元後 dangling チェックを走らせる
4. **Event**: `unreject` event を edge_events.jsonl に追記（`from: rejected`, `to: candidate`, `reason: <user_supplied>`）、理由記録は必須
5. **rejected_edges.jsonl からの移動**: 物理削除ではなく `status: unrejected` としてマーク、履歴保全

**実装フェーズ（機能単位、Spec 5 内部の段階化）**:

| Phase | 実装内容 | 成果物 | 検証条件 |
|-------|---------|-------|---------|
| **P0: Ledger 基盤** | `edges.jsonl` / `evidence.jsonl` / `entities.yaml` / `rejected_edges.jsonl` / **`decision_log.jsonl`（§2.13）** + 初期 confidence scorer（§2.12 の 6 係数式） + decision selective recorder | 手動 edge 追加で CRUD 可能、confidence 計算が動く、approve/reject 時に decision auto-record | Unit test: scorer 式、evidence ceiling、reject 移動、selective recording trigger |
| **P1: Query cache + Decision view** | `.rwiki/cache/graph.sqlite` + neighbor / path / orphans / hubs API、rebuild / stale detection、**Tier 2 markdown timeline（`rw decision render`）+ Tier 3 mermaid 埋め込み** | `rw graph neighbors / path / hubs` が動作、`rw decision render --edge` で markdown 生成 | 100+ edges での traverse、生成 markdown が Obsidian で正常 render |
| **P2: Usage event + Hygiene 基礎 + Decision search** | `edge_events.jsonl` への 4 種別 usage signal 記録、Decay + Reinforcement、Competition L1、`rw graph hygiene`、**`rw decision search` / `contradictions`** | query 後に event 追記、週次 hygiene で confidence 更新、decision 検索が動作 | Event schema、decay/reinforcement の符号、decision contradiction 検出精度 |
| **P3: Competition L2/L3 + Edge Merging** | 類似 node pair 競合、contradiction tracking、edge 統合、`rw graph hygiene --apply competition` | 矛盾 edge が `contradiction_with:` で構造化、類似 edge が merge 候補化 | Contradiction が削除されず保持されること |
| **P4（optional）: 外部 Graph DB export** | Neo4j / GraphML 等への export（必要性検証後） | `rw graph export --format neo4j` | Rwiki の JSONL が正本、外部は derived |

各 phase は前 phase の成果物を前提とする（P1 は P0 を、P2 は P1 を要求）。MVP 範囲は P0–P2。P3 は Phase 2（v0.8）候補、P4 は要件発生時のみ。

**関連シナリオ**:
- Scenario 34: Entity/Relation 自動抽出
- Scenario 35: Edge reject workflow
- Scenario 36: Graph Hygiene 実行
- Scenario 37: Edge lifecycle 管理
- Scenario 38: Edge events 監査
- Scenario 10: audit ERROR 修正（graph consistency 統合）
- Scenario 13: Evidence 検証（evidence.jsonl 活用）
- Scenario 14: Perspective / Hypothesis（L2 ledger 活用）

#### Spec 6: perspective-generation & hypothesis-generation

**Purpose**: LLM が **L2 Graph Ledger を traverse** して**視点創発（perspective）**と**仮説生成（hypothesis）**を行う機能（v2 の本丸）。

**Status**: **Scenario 14 の議論で要件確定済**（2026-04-24、scenarios.md 参照）。以下は確定内容：

**実装形態（Spec 2 / Spec 3 との関係）**:

Perspective / Hypothesis は **standalone CLI entry**（§2.11 Level 1 発見系）として提供し、**内部で Spec 2 skill を invoke** する hybrid 構造:

- `rw perspective` / `rw hypothesize` は独立 CLI コマンド（distill の flag ではない）
- 内部で `AGENTS/skills/perspective_gen.md` / `AGENTS/skills/hypothesis_gen.md` を load、Spec 2 の skill lifecycle（install / deprecate / retract）に参加
- **Spec 3 dispatch は distill 専用**。Perspective / Hypothesis は dispatch 対象外（固定 skill 呼び出し、`--skill <name>` 指定不要）
- 利点: L1 発見 CLI の UX 優先（ユーザーは `rw perspective` と覚えればよい）+ LLM prompt は skill 定義として一元管理（他 skill と同じ lifecycle）

**Perspective generation（視点創発）**:
- `rw perspective "<topic>"` — トピックに関連する複数視点（支持・反論・補完・代替）を提示
- **L2 の stable + core edges を中心に traverse**、depth default=2
- 既存知識の**再解釈・関係性発見**に特化
- Trust chain は wiki / evidence.jsonl 参照で維持
- Output: stdout（default）or `review/perspectives/`（`--save` 時）

**Hypothesis generation（仮説生成）**:
- `rw hypothesize "<topic>"` — **L2 の missing bridges や candidate edges** から仮説を生成
- **新命題の提案**（既存 wiki / stable edges にない洞察）
- `[INFERENCE]` マーカーで仮説部分を明示
- 出力は `review/hypothesis_candidates/`（必ずファイル化）
- 検証フロー: `rw verify <id>` で半自動 evidence 探索（下記「Verify workflow」参照）
- 承認: **confirmed のみ wiki 昇格可能**（Scenario 16 経由で wiki/synthesis/ へ）
- 検証で使われた edge は reinforcement（Spec 5 連携）

**Verify workflow（半自動 4 段階）**:

`rw verify <hypothesis-id>` は Scenario 14 の「半自動」原則に従い、以下の 4 段階で進行:

1. **LLM が candidate evidence 抽出**: `raw/**/*.md` を grep（hypothesis の key terms）+ semantic similarity で N 件（default 5）の候補 evidence を抽出、各候補の該当箇所（file / quote / span）を提示
2. **ユーザーが evidence を個別評価**: 各候補に対し `supporting / refuting / partial / none` を選択、必要に応じて手動で追加の evidence を `--add-evidence <path>:<span>` で指定可能
3. **LLM が collected evidence から最終 status を判定**:
   - supporting ≥ 2 件 かつ refuting = 0 → `confirmed`
   - refuting ≥ 2 件 → `refuted`
   - supporting + refuting が混在 → `partial`（user が追加調査するか、`--force-status` で強制 status 指定）
   - evidence 不足 → `verified`（status 据え置き、追加 verify 待ち）
4. **結果の記録**: frontmatter `verification_attempts` に entry 追加（collected evidence / verdict / timestamp）、confirmed / refuted の場合は対応 edge の reinforcement event を edge_events.jsonl に append

**設計原則**: 人間は「個別 evidence の採否判断」に集中（Karpathy 哲学 §1.3.5「人間は判断」と整合）、LLM は「候補抽出」と「集約判定」で support（大量の raw を読む cost を代行）。

**Discovery（内部機構）**:
- Community detection（`rw audit graph --communities`、Spec 5）
- Missing bridge detection（`rw audit graph --find-bridges`、Spec 5）
- Perspective / Hypothesis が内部で利用、単独 CLI は MVP 外（Phase 2 で検討）

**モード切替**:
- **Default**: user-requested mode（要求時のみ応答）
- **Autonomous mode**: `.rwiki/config.yml` + `rw chat --mode autonomous` + 対話中 `/mode` トグル
- 発火条件（知識発見系）: 信頼度 ≥ 7/10、3 発話に 1 回、novelty 判定、context sensing
- **Maintenance autonomous**: edge reject queue 蓄積や Hygiene 推奨も surface（§2.11 / §2.12）

**Maintenance autonomous の具体 trigger 条件**（Scenario 14 / Scenario 33 と整合、Spec 5 Hygiene 運用ポリシー参照）:

| trigger | 閾値（default） | surface する提案 |
|---------|---------------|---------------|
| reject queue 蓄積 | 未処理 ≥ 10 件 | 「reject queue をレビューしますか？（Scenario 35）」 |
| Decay 進行 edges | 未 usage > 7 日の edges ≥ 20 件 | 「Hygiene を走らせますか？（Scenario 36）」 |
| Typed-edge 整備率低下 | ページあたり平均 typed-edge < 2.0 | 「`rw extract-relations` を走らせますか？（Scenario 34）」 |
| Dangling edge | dangling_flagged 状態 ≥ 5 件 | 「`rw audit evidence` で原因確認しますか？（Scenario 13）」 |
| Audit 未実行 | 最終 `rw audit graph` から ≥ 14 日 | 「graph consistency check を走らせますか？（Scenario 10）」 |
| 未 approve synthesis 候補 | review/synthesis_candidates/ 未 approve ≥ 5 件 | 「候補をレビューしますか？」 |

**trigger の動作規則**:
1. **surface のみ、自動実行しない**: `💡 マーカー`で提案表示、user 同意があって初めて対応コマンド起動（判断を user に残す、§1.3.5 哲学）
2. **頻度制限**: 同じ trigger は同セッション 1 回まで、`/mute maintenance` で該当セッション無効化
3. **閾値は tunable**: `.rwiki/config.yml` の `chat.autonomous.maintenance_triggers.*` で上書き可能
4. **複合診断 orchestration**: 複数 trigger が同時発火した場合、Scenario 33 の「複合メンテナンス」で優先順位付けして提示

**Boundary**:
- In scope:
  - `rw perspective` / `rw hypothesize` / `rw verify` / `rw approve <hypothesis-id>` コマンド
  - L2 ledger からの graph traverse（Spec 5 の query API 活用）
  - Step 1-5 の処理フロー（seed 特定 → N-hop traverse → M 件絞込 → 本文読込 → 統合分析）
  - Dual-level retrieval（local / global scope）
  - Community-aware traversal（GraphRAG-inspired）
  - `--scope global` flag（global query）
  - `--method hierarchical-summary`（on-demand community summary）
  - Hypothesis の 7 状態管理（draft / verified / confirmed / refuted / promoted / evolved / archived）
- Out of scope:
  - Graph Ledger 実装（Spec 5）
  - Community detection アルゴリズム（Spec 5、networkx ベース）
  - Skill 設計（Spec 2）

**Key Requirements**:
- **L2 ledger を主 query 対象**（frontmatter `related:` は cache としても、正本は ledger）
- Typed edges 未整備時でも動作（graceful degradation、Spec 5 §B8-4）
- Hypothesis は **evidence 検証可能な命題に限定**（純粋な理論命題は Perspective 担当）
- **Confirmed hypothesis の wiki 昇格は Scenario 16（query → synthesis 昇格）と同じ 8 段階対話**
- Perspective の自動保存しない default（stdout のみ）、`--save` で review/perspectives/
- 対話ログの自動保存: `raw/llm_logs/chat-sessions/` / `interactive/`（Scenario 15/25 連携）

**5 段階処理フロー（Step 1-5、Perspective / Hypothesize 共通）**:

```
Step 1: seed 特定（Grep or ユーザー指定、entities.yaml から正規化）
Step 2: L2 Graph Ledger を SQLite 経由で N-hop traverse（depth default=2）
         フィルタ条件（edge status フィルタと confidence 絶対値フィルタの AND）:
           - Perspective: status IN (stable, core) AND confidence ≥ 0.4
             ・status で「承認済み edges」に絞り、さらに confidence 絶対値で低品質を除外
             ・0.4 は §2.12 の 閾値 3 段階とは**別の API-level フィルタ閾値**（§5.9.2 Perspective save）
           - Hypothesis: status IN (candidate, stable, core) AND confidence ≥ 0.3
             ・candidate も対象（未確定な edge から仮説種を拾う）
             ・0.3 は evidence-less 上限と同値、evidence のある weak edge は除外される
         → edges + nodes の metadata を取得（本文未読）
Step 3: LLM が候補から深掘り対象上位 M 件（default 20）を選定
         選定は scoring function で ranking（下記「候補選定 scoring」参照）
Step 4: 選ばれた M 件の wiki ページ本文を Read、evidence.jsonl も参照
Step 5: 統合分析 → 出力（Perspective stdout/save or Hypothesis review file）
         使われた edge 全てに usage_signal を加算 → edge_events.jsonl に append
         （Spec 5 Hygiene の reinforcement 入力）
```

**候補選定 scoring（Perspective / Hypothesis で使い分け）**:

Step 3 の top M 件選定は以下の scoring function で行う（config で tunable）:

- **Perspective**: 信頼性重視
  ```
  score = 0.6 × confidence + 0.3 × recency + 0.1 × novelty
  ```
  - 高 confidence の安定した関係を優先し、既存知識の再解釈に適した edges を surface

- **Hypothesis**: 未発見関係重視
  ```
  score = 0.5 × novelty + 0.3 × confidence + 0.2 × bridge_potential
  ```
  - novelty = 「wiki にまだ書かれていない度」（candidate edge で evidence が新しい順）
  - bridge_potential = missing bridge detection 由来（2 cluster 間を結ぶ候補度）
  - confidence は最低限の evidence 裏付けを保証する重み

**各 score 要素の計算**（Spec 5 Query API が提供）:
- `confidence`: edge.confidence（0.0-1.0）
- `recency`: `exp(-days_since_last_event / half_life)`、half_life default 30 日
- `novelty`: `1 - (edges_derived_from_same_raw_count / total_related_edges)`、高いほど独自
- `bridge_potential`: `find_missing_bridges` 由来の類似度スコア（Hypothesis のみ）

**Config** (`.rwiki/config.yml`):
```yaml
graph:
  perspective:
    scoring_weights:
      confidence: 0.6
      recency: 0.3
      novelty: 0.1
    top_m: 20
  hypothesis:
    scoring_weights:
      novelty: 0.5
      confidence: 0.3
      bridge_potential: 0.2
    top_m: 20
```

**L2 Ledger 成熟度別 fallback（graceful degradation）**:

| L2 Ledger 状態 | 判定指標 | 挙動 |
|-------------|-------|-----|
| 極貧 | stable+core edges < 10 件 | ⚠ 警告 + `rw extract-relations` 推奨 |
| 疎 | stable 比率 < 20% | INFO: ledger 成熟途上、candidate 多 |
| 通常 | stable+core が 50% 超 | full quality |

**Hypothesis 検証の edge reinforcement**:
- `rw verify <id>` 成功（confirmed）時、hypothesis の `origin_edges` で参照される L2 edges に confidence 上昇
- 具体的 delta は Spec 5 Hygiene の `supporting_evidence_reinforcement_delta`（default +0.28）
- `edge_events.jsonl` に `human_verification_support` event が記録される

**Perspective 保存時の L2 feedback**:
- `review/perspectives/*.md` に記録される `traversed_edges:` field に edge_id を列挙
- 保存時に各 edge へ `used_in_save_perspective` event を追加、usage_signal 加算

詳細な Trust chain・対話例・シナリオ間連携は scenarios.md の Scenario 14 参照。

#### Spec 7: lifecycle-management

**Purpose**: **L3 wiki ページ / skill の lifecycle** および **L2 edge lifecycle との連携**を管理。

**Boundary**:
- In scope:
  - **Page status 状態遷移**（active / deprecated / retracted / archived / merged / active 復帰）
  - **Page lifecycle と Edge lifecycle の相互作用**（例: page deprecation 時に関連 edges の demotion）
  - Dangerous op 8 段階共通チェックリスト（`AGENTS/guides/dangerous-operations.md`）
  - 固有ガイド（`AGENTS/guides/deprecate-guide.md` 等）
  - Follow-up タスク仕組み（`wiki/.follow-ups/`）
  - 警告 blockquote の自動挿入（deprecate / retract / archive）
  - Backlink 更新（wiki merge / deprecate 時）
  - Simple dangerous ops（unapprove / reactivate）
  - Skill lifecycle（deprecate / retract / archive）
- Out of scope:
  - 個別タスクの出力（他 Spec）
  - **Edge lifecycle の進化則**（Spec 5 Graph Hygiene が担当）
  - **Edge status の定義と遷移**（Spec 5）

**注**: v2 には **2 種類の lifecycle** が並立する：

| 対象 | Lifecycle | 主担当 Spec |
|------|---------|------------|
| **L3 Page** (wiki/*.md) | active / deprecated / retracted / archived / merged | Spec 7（本 Spec） |
| **L2 Edge** (edges.jsonl) | weak / candidate / stable / core / deprecated / rejected | Spec 5（Graph Hygiene） |

両者の**相互作用**は本 Spec の責務:
- Page deprecation → 関連 edges を demote 候補に
- Page retracted → 関連 edges を `rejected` に準ずる扱い
- Page merged → edges を merged target に付け替え

**Key Requirements**:

**Page 状態と挙動**:
| status | 参照元扱い | Query/Distill 対象 | Wiki 位置 |
|--------|----------|------------------|---------|
| active | 通常 | 対象 | 元の位置 |
| deprecated | 警告注記、successor 誘導 | 原則除外（明示フラグで含む） | 元の位置 |
| retracted | 強警告 | 完全除外 | 元の位置 |
| archived | そのまま | 履歴として検索可 | 元の位置 |
| merged | merged_into に誘導 | 除外 | 元の位置（candidate は） |

**Dangerous op の分類**:
| 操作 | 危険度 | 対話ガイド | --auto |
|------|-------|----------|------|
| deprecate | 中 | 必須 | ✓ |
| retract | 高 | 必須 | ✗ |
| archive | 低 | 推奨 | ✓ |
| reactivate | 低 | 簡易 | ✓ |
| merge (review) | 中 | 必須 | ✓ |
| merge (wiki) | 高 | 必須 | ✓（慎重） |
| split | 中〜高 | 必須 | ✗ |
| unapprove | 中 | 簡易（1 段階） | ✓（`--yes`） |
| tag merge | 中 | 必須 | ✓（typo 修正時） |
| tag split | 中〜高 | 必須 | ✗ |
| skill install | 中 | 推奨 | ✓ |
| skill deprecate | 中 | 必須 | ✓ |
| skill retract | 高 | 必須 | ✗ |
| skill archive | 低 | 推奨 | ✓ |
| promote-to-synthesis | 最高 | 必須 | ✗ |

**コマンド対応**: 13 操作の CLI 名は基本 `rw <操作名>` で機械的に対応する。例外は 2 ケース:

- `merge (review)` / `merge (wiki)`: いずれも `rw merge` を使用（review / wiki 層は CLI が path から自動判定）
- `promote-to-synthesis`: CLI 名は `rw query promote`（drafts §6.2 L1349 と整合）

**8 段階チェックリスト**（`AGENTS/guides/dangerous-operations.md`）:
1. 意図確認
2. 現状把握
3. 依存グラフ解析
4. 代替案提示
5. 参照元の個別判断
6. Pre-flight warning
7. 差分プレビュー生成
8. 人間レビュー → approve

---

## 8. エディタとの連携（Obsidian を参照実装として）

### 8.1 責務分離の原則

**Rwiki の責務**:
- パイプライン処理（lint/ingest/distill/approve/audit）
- LLM 連携（LLM CLI 統合、skill library）
- 知識グラフ分析（typed edges、perspective generation、audit）
- Trust chain 保証
- 構造化クエリ成果物の生成（4 ファイル契約）

**Rwiki の責務外**（エディタに委譲）:
- 日常的な編集体験（markdown エディタ、プレビュー、リアルタイム保存）
- Daily note の自動生成・テンプレート展開
- モバイルアクセス
- リアルタイムコラボ
- グラフの視覚化（関係計算は Rwiki、表示はエディタ側のグラフ view）

### 8.2 推奨エディタ: Obsidian

多数のプラグインエコシステムと機能が揃っているため、**参照エディタとして Obsidian を推奨**する：

- Vault を開いて markdown ファイルを編集
- Daily Note プラグイン、Templater
- Graph view（リンク関係の可視化）
- Backlinks パネル
- **Dataview プラグイン**: frontmatter 駆動の動的クエリ・集計・一覧生成（Rwiki の frontmatter スキーマと親和性が高い）
- モバイル対応

**Dataview の具体的な活用例**（Rwiki 運用上で有用）:

```dataview
TABLE status, successor, status_changed_at
FROM "wiki"
WHERE status != "active"
SORT status_changed_at DESC
```
→ deprecated / retracted / archived ページの一覧

```dataview
LIST
FROM "wiki/methods"
WHERE contains(tags, "ml") AND status = "active"
SORT file.mtime DESC
```
→ ml タグ付きの active method ページ一覧

```dataview
TABLE source, added
FROM "wiki"
WHERE contains(tags, "paper") AND added >= date(today) - dur(30 days)
```
→ 直近 30 日で取り込んだ論文

Rwiki の audit や query を補完する**エディタ側の軽量クエリ層**として機能する。

ただし必須ではない。以下は代替エディタの例：

| エディタ | 強み |
|---------|------|
| VSCode + Markdown Preview Enhanced | 開発者向け、Git 統合良好 |
| vim / neovim + markdown-preview.nvim | 軽量、端末内完結 |
| Typora | プレビューシームレス、初心者向け |
| Emacs + org-mode / markdown-mode | 強力なテキスト処理 |

`rw chat` は任意のエディタのターミナル機能、tmux、別ターミナルウィンドウ等から起動可能。

### 8.3 エディタ非依存の保証

Rwiki の出力は**標準的な markdown + YAML frontmatter + HTML コメント**で構成され、特定エディタの独自記法に依存しない。生成されたファイルは任意のエディタで開き・編集・保存できる。

### 8.4 将来拡張（roadmap）

- **エディタ連携コマンド**: `rw sync-from-editor`（将来の抽象化）
  - エディタ側で書かれた daily note / memo を Rwiki パイプラインに取り込む
  - 当初は Obsidian の daily note plugin が生成するファイルを想定
- **Obsidian プラグイン**: 薄い CLI wrapper（Command Palette から rw コマンド起動）
- **他エディタ連携**: VSCode 拡張、Emacs パッケージ等（需要に応じて）

---

## 9. 実装戦略

### 9.1 フルスクラッチ方針

- 新 spec 群に基づいて実装を **ゼロから再構築**
- v2 の各 Spec は **新名称のみで自己完結的に設計**される。v1 を知らない前提
- 既存 `scripts/` / `tests/` / `templates/AGENTS/` は **実装時の参考資料**
- 取り込むべき部分:
  - `rw_utils.py` の汎用関数（frontmatter parser、git helpers、path 正規化）
  - severity / exit code 契約
  - LLM CLI 呼出の timeout 処理
  - 既存 644 テストがカバーしている**暗黙仕様**（各 spec の requirements 策定時に参照）

**v1 との対応**: 旧名称と v2 名称のマッピングは §11.3（開発期参照資料）に記載。v2 実装者が v1 コードを読む際の便宜マップであり、v2 スペックの成果物ではない。つまり：

- Spec 0〜7 は「v2 世界に閉じた」設計・実装
- §11.3 は「v2 実装者が v1 を読む時」の架橋
- `.kiro/specs/v1-archive/` は「v1 時代の要件を知りたい時」の参照

この 3 層により、v2 開発中は新名称で一貫しつつ、v1 の知見を損なわない。

### 9.2 v1 archive

- `.kiro/specs/*` を `.kiro/specs/v1-archive/` に移動
- 新 spec 群は `.kiro/specs/` 直下に起票
- 既存コードは v2 実装完了後に置換（段階的）

### 9.3 テスト戦略

各新 spec の design フェーズで「**既存テストマッピング**」セクションを設け、v1 テストが扱う振る舞いを v2 requirements に組み込む：

```markdown
## Existing Test Coverage Mapping
- tests/test_lint.py::test_empty_file_fail → v2 lint でも空ファイルは FAIL
- tests/test_ingest.py::test_conflict_detection → v2 ingest でも衝突検出
- ...
```

### 9.4 実装順序（v0.7.10 時点、Spec 分割評価 + preparatory 議論反映版）

**起票準備度（v0.7.10 時点）**: Spec 0-7 全てが A 評価（即起票可能）。Spec 5/6 は v0.7.10 で 6 決定を確定済み（§1.3 Curated GraphRAG 位置付け、§2.12 Reinforcement delta cap、Spec 5 `normalize_frontmatter` API、Spec 5 cache invalidation、Spec 6 standalone CLI + skill、Spec 6 semi-auto verify、Spec 6 scoring function）。

**依存関係を反映した 5 Phase 実装順序**:

```
Phase 1: Foundation 層
  Spec 0 (foundation、3 層アーキテクチャ、12 中核原則、用語集)
    ↓
  Spec 1 (classification、L3 frontmatter、tag vocabulary、categories.yml)
    [coordination: Spec 3 との frontmatter `type:` field 合意]

Phase 2: L3 操作基盤
  Spec 4 (cli-mode-unification、全コマンド、chat mode、Maintenance UX)
    ↓
  Spec 7 (lifecycle-management、Page + Edge lifecycle 連携)

Phase 3: L2 Graph Ledger（最重要・最大規模）
  Spec 5 (knowledge-graph、内部 P0-P4 Phase で段階実装)
    P0: Ledger 基盤（edges.jsonl / evidence.jsonl / entities.yaml / scorer）
    P1: Query cache（sqlite + neighbor/path/orphans/hubs API、rebuild）
    P2: Usage event + Hygiene 基礎（Decay/Reinforcement/Competition L1）
    [MVP 範囲はここまで = P0+P1+P2]
    P3: Competition L2/L3 + Edge Merging（v0.8 候補、MVP 外）
    P4: 外部 Graph DB export（optional、要件発生時のみ）
    ↓
  Spec 2 (skill-library、extraction skills を含む、Spec 5 API 利用)
    [coordination: Spec 5 との extraction skill output validation interface]

Phase 4: Skill Dispatch
  Spec 3 (prompt-dispatch、skill 選択ロジック)
    [coordination: Spec 1 categories.yml の default_skill mapping 確定]

Phase 5: 本丸（Perspective + Hypothesis 生成、L2 ledger 活用）
  Spec 6 (perspective + hypothesis、standalone CLI + Spec 2 skill invoke)
```

**順序理由**:
1. **Spec 0 → 1**: Foundation と L3 frontmatter スキーマが全 Spec の基盤
2. **Spec 4 → 7 を Spec 5 より前**: CLI 統一と Page lifecycle が揃えば Spec 5 の CLI entry 点が決まる。Spec 7 の Page-Edge interaction は Spec 5 の edge API を前提にするが、Spec 7 requirements 段階では interface 定義だけで足りるため、Spec 5 実装完了を待たずに起票可能
3. **Spec 5 の先行実装**: Spec 2 の extraction skill は Spec 5 の `edges.jsonl` / Query API に書き込む。Ledger フォーマットと API が固まらないと skill がテストできない
4. **Spec 2 → 3**: Skill library が定義されてから dispatch ロジックを詰める（Spec 3 は Spec 2 の skill 群を前提にする）
5. **Spec 6 を最後**: 以下全てに依存（L3 frontmatter / L2 ledger & Query API / skill library & dispatch / CLI / lifecycle）

**必要な Spec 間 coordination**（起票中に決定）:
- **Spec 1 ↔ Spec 3**: frontmatter 推奨フィールドに `type:` を追加（distill dispatch の手掛かり）
- **Spec 1 ↔ Spec 3**: `.rwiki/vocabulary/categories.yml` の default_skill mapping 方式（inline / 別ファイル）
- **Spec 2 ↔ Spec 5**: extraction skill（`relation_extraction` / `entity_extraction`）の出力 validation interface
- **Spec 5 ↔ Spec 7**: Page deprecation → Edge demotion の interaction flow
- **Spec 4 ↔ Spec 5**: Concurrency lock strategy（`.rwiki/.hygiene.lock`）の整合

### 9.5 期間見積り（v0.7.10 時点、Spec 分割評価レポート反映）

**Phase 別見積り**:

| Phase | 作業内容 | 期間 | 並列化 |
|-------|--------|:----:|:----:|
| **1a** | Spec 0, 1 の requirements 起草 + 承認 | 2〜3 日 | — |
| **1b** | Spec 0, 1 の design + tasks | 2〜3 日 | — |
| **2a** | Spec 4, 7 の requirements 起草 + 承認 | 2〜3 日 | 並列可 |
| **2b** | Spec 4, 7 の design + tasks | 2〜3 日 | 並列可 |
| **3a** | Spec 5 の requirements 起草 + 承認（最大規模） | 2〜3 日 | — |
| **3b** | Spec 5 の design + tasks（P0-P4 を含む） | 3〜4 日 | — |
| **3c** | Spec 5 の autonomous 実装（P0+P1+P2 = MVP スコープ） | 4〜6 日 | — |
| **3d** | Spec 2 の requirements + design + tasks（Spec 5 と coordination） | 2〜3 日 | 3c と一部並列可 |
| **4** | Spec 3 の requirements + design + tasks | 1〜2 日 | — |
| **5a** | Spec 6 の requirements + design + tasks | 2〜3 日 | — |
| **5b** | Spec 2, 3, 4, 6, 7 の autonomous 実装（依存順） | 6〜9 日 | 部分並列可 |
| **6** | ドキュメント・steering 再構築 | 1〜2 日 | — |

**合計**: **11〜17 日**（2〜3.5 週間）。

**従来見積り（3〜4 週間）からの短縮要因**:
- Spec 5/6 の preparatory 議論が v0.7.10 で完了済み（起票時に再議論不要）
- Spec 分割評価で A 評価 4 件、B 評価 2 件で「軽微 coordination」のみ必要と判明
- Spec 4, 7 が Spec 5 より前に出せるため並列化可能

**拡大要因（見積り増えるケース）**:
- Spec 5 P0-P2 の実装で Hygiene / Competition のテストが複雑化
- extraction skill（Scenario 34）の LLM prompt tuning が試行錯誤
- `rw chat` の autonomous mode 実装（Scenario 33）で UX 調整が反復
- Obsidian との integration 確認（手動 E2E テスト）

### 9.6 MVP 範囲と Phase 2 以降への先送り

**MVP（v2.0）に含まれる**:
- Spec 0-7 の全 spec、Spec 5 は P0+P1+P2 まで
- Scenario 7, 8, 10, 11, 12, 14, 15, 16, 17, 19, 20, 25, 33（合意済 13 件）
- Scenario 13, 18, 26（v0.7.1 で L2 統合書き換え済、起票時に詳細化）
- Scenario 34-38（skeleton、Spec 5 P0+P1+P2 範囲で対応）

**Phase 2（v0.8）以降に先送り**:
- Spec 5 P3（Competition L2/L3 + Edge Merging）
- Spec 5 P4（外部 Graph DB export）
- Scenario 9（ページ分割、未議論）
- Scenario 21-24, 28, 29, 31（外部連携・マルチ Vault・migration）

**Phase 2 の起動条件**:
- MVP Vault 規模が拡大（edges > 10,000）し、Competition L1 だけでは整理しきれなくなった時点
- チーム利用で multi-user 同期が必要になった時点

### 9.7 起票開始の判定

以下が揃えば `/kiro-spec-init` で Spec 0 から順に起票開始可能:

- [x] consolidated-spec v0.7.10（本書）の合意
- [x] scenarios v0.7.4 の合意（ユースケース集として完成）
- [x] Spec 5/6 preparatory 議論の完了（v0.7.10 で 6 決定確定）
- [ ] Spec 1 ↔ Spec 3 coordination（frontmatter `type:` / categories.yml mapping、**起票中に決定可**）
- [ ] Spec 2 ↔ Spec 5 coordination（extraction skill validation interface、**Spec 5 起票中に決定可**）

残る 2 件の coordination は起票プロセスで自然に決まる軽微事項のため、**即起票開始可**。

---

## 10. 未議論・保留事項

本 Draft v0.1 に含まれていない項目。後続で詰める：

### 10.1 シナリオ 14（perspective + hypothesis generation）

**議論済み（2026-04-24 完了）**: Group A-D の 4 回議論で要件確定。詳細は scenarios.md 参照。

**確定事項**:
- 概念: Perspective / Hypothesis は独立コマンド、Discovery は共通基盤（MVP は内部機構のみ）
- 技術: depth=2 default、Graph-based + 段階的 loading、graceful degradation
- Hypothesis: `rw verify` 半自動 + ingest 時自動通知、7 状態 frontmatter、confirmed のみ wiki 昇格
- UX: autonomous mode 切替、stdout default + `--save`、新 review 層（perspectives/、hypothesis_candidates/）
- **Draft v0.7 での追加**: L2 Graph Ledger 統合、missing bridges、community detection 活用

### 10.2 シナリオ 10（audit ERROR 修正ループ）

- `rw audit-fix --auto-fixable-only` の対象範囲
- 自動修正可能 vs 人間判断要の境界
- query_fix の一般化として扱うか

### 10.3 シナリオ 6（query → synthesis 昇格）

- `rw query promote <query_id>` の挙動
- 4 ファイル契約から wiki/synthesis/ ページへの変換
- evidence の reference 変換
- Spec 7 lifecycle と連動

### 10.4 シナリオ 18（pre-flight check）

- 重要操作前の一括 dry-run
- `rw preflight` コマンド or 各 approve への `--preflight` フラグ
- Spec 7 に含めるか独立か

### 10.5 シナリオ 26（Incoming lint-fail 滞留リカバリ）

**概要**: `raw/incoming/` に複数文書を投入した際、一部が lint FAIL で滞留する状況のリカバリフロー。

**想定ユースケース**:
- 10 件の論文を一括投入 → 8 件 PASS、2 件 FAIL（frontmatter 不足・空ファイル等）
- PASS 分だけを先に ingest したい（FAIL は後で修復）
- 滞留中のファイルの可視化（`rw lint --show-pending` or 類似）
- 修復ループ: frontmatter 補完 → 再 lint → ingest

**Spec への影響**:
- Spec 0: lint の auto-fix 範囲ポリシー（`ensure_basic_frontmatter` をどこまで広げるか）
- Spec 4: `rw lint` の診断表示拡張、部分 ingest フロー
- 既存 Scenario 10（audit ERROR 修正）との違い: あちらは wiki 層、こちらは raw 層

### 10.6 シナリオ 33（Ambiguity 時の UX・rw chat の品質）

**概要**: ユーザー発話が曖昧なとき、LLM が**拒絶（STOP）ではなく候補提示で誘導**する UX 原則。

**想定例**:
```
You: このメモを整理しておいて
Claude: 「整理」の意図を確認させてください。候補:
  (a) ingest — raw/incoming/ の検証・取り込み
  (b) distill — 知識を review/ に抽出（どの skill？）
  (c) merge — 既存候補との統合
  (d) classify — カテゴリ/タグ整理のみ
  どれに近いですか？
```

**設計原則**:
- 「拒絶して止まる」→「候補提示で誘導する」に転換
- 前提条件の満たし方を自動チェック（`rw check` 相当）
- ユーザーの学習曲線を緩やかにする

**Spec への影響**:
- Spec 0: 対話時のコミュニケーション原則として明記
- Spec 4: `rw chat` の応答テンプレート、タスク分類ヒューリスティクスの定義
- Spec 2: Failure Conditions 発動時の「次のアクション」欄（シナリオ 11 で一度議論した原則の拡張）

- 重要操作前の一括 dry-run
- `rw preflight` コマンド or 各 approve への `--preflight` フラグ
- Spec 7 に含めるか独立か

### 10.7 対話型モードの詳細

- `rw chat` の起動プロンプト設計
- AGENTS/skills/guides のロード順
- 中断・再開（セッション継続）

### 10.8 Skill 自動選択の精度評価

- Spec 3 で LLM 毎回判定（精度優先）を採用したが、コストと精度のバランス
- キャッシング戦略

### 10.9 マルチユーザー・マルチ Vault（Scenario 29, 31 を含む）

- 将来拡張、v2 MVP 外
- roadmap.md に登録
- 含むシナリオ:
  - **Scenario 29**: Dirty tree と並行操作のガバナンス（single user 前提を超える段階で必要）
  - **Scenario 31**: Vault ポータビリティ・マルチデバイス・チーム共有

### 10.10 外部連携（Zotero / arXiv / エディタプラグイン）

- 将来拡張、v2 MVP 外
- roadmap.md に登録

### 10.11 Vault migration framework（Scenario 28 を含む）

- 既に roadmap の Technical Debt に `vault-migration-framework` として登録済
- v2 内での扱いは **先送り**（ユーザー判断、2026-04-24）
- **Scenario 28**（Vault スキーマ破壊的変更のマイグレーション）は v2 MVP に含めない
  - 理由: v2 自体が一度の大規模変更のため、多段階マイグレーション機構は過剰
  - 運用: v2 内でスキーマ変更が発生した場合は「各 spec で CHANGELOG + requirements に移行手順を明記」で対応
  - 将来、3 つ目以降の破壊的変更スペックが起草される時点で着手

---

## 11. 付録

### 11.0 シナリオ 25: LLM 対話ログからの継続的知識化（llm_log_extract）

**概要**: ユーザーは日常的に LLM（Claude / ChatGPT 等）との research discussion を行う。対話記録を `raw/llm_logs/` に蓄積し、後日 `rw distill <log> --skill llm_log_extract` で再利用可能な判断・パターンを抽出する。

**入力**:
- `raw/llm_logs/<date>-<topic>.md` のような対話ログファイル（手動 export / 自動保存）
- Scenario 15（interactive_synthesis）で自動保存された対話ログも同形式で対象

**スキル**: `llm_log_extract`
- 出力形式: Summary / Decision / Reason / Alternatives / Reusable Pattern
- `interactive: false`（静的解析、対話なし）
- `applicable_categories: [llm_logs]`（専用）

**処理フロー**:
1. LLM との対話を raw/llm_logs/ に保存（手動 export、Obsidian で直接記述、または Scenario 15 からの自動保存）
2. `rw distill raw/llm_logs/<log>.md --skill llm_log_extract`
3. `review/synthesis_candidates/<log>-extracted.md` に Decision/Reason 形式で生成
4. 人間レビュー → `rw approve` で wiki 昇格（通常 `wiki/synthesis/` or `wiki/entities/people/<user>.md`）

**Scenario 15 との連携（重要）**:

| 観点 | Scenario 15 | Scenario 25 |
|------|-------------|-------------|
| 対話のフェーズ | synthesis 実行**中** | synthesis 実行**前に完了済み** |
| 対話の主体 | LLM ↔ user（リアルタイム） | user ↔ 別の LLM（過去の記録） |
| 対話の位置 | synthesis の手段 | synthesis の一次ソース |
| 主な入力 | raw/ + user 対話 | raw/llm_logs/ |
| 出力の性質 | content（wiki 候補） | pattern（決定・理由） |

**連携ポイント（対話の二次利用）**:
- Scenario 15 の対話ログは `raw/llm_logs/interactive-<skill>-<timestamp>.md` に**自動保存**される
- そのログは後日 Scenario 25 の `llm_log_extract` で再処理可能
- **同じ対話を 2 つの観点から再利用**: 即時は content-centric、後日は process-centric

**想定テスト**: raw/llm_logs/ 配下のログ取込み、形式 variance（Claude export 形式、手動整形形式、interactive_synthesis 自動保存形式）への対応。

**Spec 2 への影響**:
- Skill 一覧に `llm_log_extract` を明記（既に記載済）
- Interactive skill の対話ログ自動保存規約を追加（命名: `raw/llm_logs/interactive-<skill>-<ts>.md`）

---

### 11.1 シナリオと Spec のマッピング

| シナリオ | 主要 Spec | 対応状況 |
|---------|---------|---------|
| 7. 既存 wiki 拡張 | Spec 2 (skill update_mode=extend), 4, 7 | 合意済 |
| 8. 複数候補 merge | Spec 4 (rw merge), 7 | 合意済 |
| 11. Archive / deprecation | Spec 7 | 合意済 |
| 12. タグ vocabulary 管理 | Spec 1 | 合意済 |
| 14. Perspective + Hypothesis generation | **Spec 6**（中心）、Spec 5 依存 | **合意済**（scenarios.md 参照） |
| 15. Interactive synthesis | Spec 2, Spec 6（autonomous 連携） | 合意済 |
| 16. Query → synthesis 昇格 | Spec 2, Spec 7 | 合意済 |
| 17. Daily note (エディタに委譲) | Spec 0（責務分離） | 合意済 |
| 19. Rollback / unapprove | Spec 4, 7 | 合意済 |
| 20. Custom skill 作成 | Spec 2 | 合意済 |
| 25. LLM 対話ログ抽出 | Spec 2（skill llm_log_extract） | 合意済 |
| 10. Audit ERROR 修正 | Spec 7 + Spec 5（graph consistency） | 未議論 |
| 9. Wiki ページ分割 | Spec 7 | 未議論 |
| 13. Evidence 検証 (+32) | Spec 7 + Spec 5（evidence.jsonl） | 未議論 |
| 18. Pre-flight check | Spec 7 + Spec 5（edge state） | 未議論 |
| 26. Incoming lint-fail 滞留リカバリ | Spec 0 (lint policy), Spec 4 (rw lint 拡張) | 未議論 |
| 33. Maintenance UX 全般原則 | Spec 0 (原則 §2.11), Spec 4 (rw chat 実装) | 原則確定、詳細未議論 |
| **34. Entity/Relation 自動抽出**（新） | **Spec 5** + Spec 2 | 未議論 |
| **35. Edge reject workflow**（新） | **Spec 5**, Spec 4 | 未議論 |
| **36. Graph Hygiene 実行**（新） | **Spec 5** | 未議論 |
| **37. Edge lifecycle 管理**（新） | **Spec 5** + Spec 7 | 未議論 |
| **38. Edge events 監査**（新） | **Spec 5** | 未議論 |
| 27. Incoming 混在ディレクトリ | Spec 1（classification 要件として統合） | Spec 1 要件 |
| 30. index.md / log.md 整合性 | Scenario 10 に統合 | Scenario 10 の一部 |
| 32. Raw data dead-link / source chain | Scenario 13 を拡張 | Scenario 13 の拡張 |
| 28. Vault スキーマ破壊的マイグレーション | （v2 MVP 外、roadmap） | 先送り（§10.11 参照） |
| 29. Dirty tree / 並行操作 | （v2 MVP 外） | 将来拡張（§10.9 参照） |
| 31. Vault ポータビリティ・複数デバイス | （v2 MVP 外） | 将来拡張（§10.9 参照） |

### 11.2 Skill 一覧（初期セット）

**知識生成 skills**（distill タスク向け）:

| Skill | 用途 | 出力 |
|-------|-----|------|
| `paper_summary` | 論文要約 | Abstract / Method / Findings / Critique |
| `multi_source_integration` | 複数論文統合 | 統合概念ページ |
| `cross_page_synthesis` | wiki 横断 synthesis | wiki/synthesis/ 候補（**最希少最価値**） |
| `personal_reflection` | 個人ノート・内省 | Observation / Interpretation / Action |
| `llm_log_extract` | LLM 対話ログ抽出 | Summary / Decision / Reason / Alternatives / Reusable Pattern |
| `narrative_extract` | 物語・事例から教訓 | 初期状態 / 選択 / 制約 / 試練 / 結果 / 本質 / 一般化 |
| `concept_map` | 概念説明 | Core Idea / Related Concepts / Examples / Applications |
| `historical_analysis` | 歴史的文書 | Context / Events / Causes / Consequences / Significance |
| `code_explanation` | コード | Purpose / Pattern / Caveats / Reusability |
| `entity_profile` | 人物・ツール紹介 | Who / What / Context / Relationships |
| `interactive_synthesis` | 対話型 synthesis（Scenario 15） | User 視点反映の wiki ページ候補 |
| `generic_summary` | 汎用 fallback | 自由形式 + WARN |

**Graph 抽出 skills**（L2 Graph Ledger 向け、Scenario 34）:

| Skill | 用途 | 出力先 |
|-------|-----|------|
| `entity_extraction` | 文書から entity 抽出 | `review/relation_candidates/` 経由で `entities.yaml` |
| `relation_extraction` | entity ペアから typed relation 抽出（GraphRAG-inspired 2-stage） | `review/relation_candidates/` 経由で `edges.jsonl` |

**Lint 支援 skills**（Scenario 26）:

| Skill | 用途 | 出力 |
|-------|-----|------|
| `frontmatter_completion` | 不足 frontmatter 補完提案 | review via `rw lint --fix` |

### 11.3 v1 → v2 命名対応表（開発期参照資料）

**位置付け**: 本表は v2 実装時に v1 コード・テストを参照する際の**便宜用マップ**であり、v2 のスペック成果物ではない。v2 の各 Spec は v1 を知らずに新名称で自己完結的に設計される。

**使用場面**:
- 旧 `scripts/` や `tests/` を読んで挙動を理解するとき
- v1 が扱っていた機能を v2 で実装する際の対応確認
- `.kiro/specs/v1-archive/` の要件文書を読むとき

**マッピング**:

| v1 コマンド / 概念 | v2 対応 | 備考 |
|------------------|-------|------|
| `rw synthesize`（Prompt） | `rw distill <file> [--skill <name>]` | タスク命名を抽象化、スキル指定追加 |
| `rw synthesize-logs`（CLI Hybrid） | `rw distill <file> --skill llm_log_extract` | 独立コマンド廃止、skill に統合 |
| `rw audit micro` | `rw audit links` | 意味ベース命名に変更 |
| `rw audit weekly` | `rw audit structure` | 同上 |
| `rw audit monthly` | `rw audit semantic` | 同上 |
| `rw audit quarterly` | `rw audit strategic` | 同上 |
| `rw lint` | `rw lint` | 維持 |
| `rw ingest` | `rw ingest` | 維持 |
| `rw approve` | `rw approve` | 機能拡張（extend/merge/deprecate 自動判定、v2 で強化） |
| `rw query extract/answer/fix` | `rw query extract/answer/fix` | 維持 |
| `rw init` | `rw init` | 維持（`--reinstall-symlink` 保持） |
| 旧 `AGENTS/synthesize.md` | `AGENTS/skills/{paper_summary, multi_source_integration, ...}` | スキル分離 |
| 旧 `AGENTS/synthesize_logs.md` | `AGENTS/skills/llm_log_extract.md` | |
| 旧カテゴリ固定（articles/papers/etc.） | カテゴリ + `.rwiki/vocabulary/categories.yml`（拡張可） | 一般化 |
| 旧 `source` の path 推論 | frontmatter `source` 必須（自由文字列） | Evidence chain 強化 |
| 旧 `rw approve` の promoted flag | `status: approved` + 自動判定 | Lifecycle への統合 |
| （v1 に不在） | `rw chat` / `rw distill --skill narrative_extract` / `rw perspective` / `rw hypothesize` / `rw discover` / `rw merge` / `rw extend` / `rw deprecate` / `rw retract` / `rw archive` / `rw reactivate` / `rw unapprove` / `rw retag` / `rw check` / `rw skill *` / `rw tag *` / `rw follow-up *` | v2 新規機能 |

**互換性方針**: v2 はフルスクラッチ実装のため、**互換エイリアスは提供しない**。v1 コードは `.kiro/specs/v1-archive/` で歴史記録として保持。

**更新タイミング**: v2 の各 Spec 実装時に、v1 コード・テストから拾うべき挙動を発見したら本表の備考欄に追記する運用（実装期の生きた資料）。実装完了後は `docs/migration/v1-to-v2.md` として docs に移動。

---

### 11.4 改訂履歴

| 日付 | 変更 | 備考 |
|------|------|------|
| 2026-04-24 | Draft v0.1 作成 | シナリオ 7, 8, 11, 12, 17, 19, 20 + 基盤原則まで統合 |
| 2026-04-24 | Draft v0.2 | 想定ツール明示、LLM CLI 抽象化、Obsidian 汎用化、Paradigm C 自己完結化、Hypothesis generation を中核価値に追加、Dataview plugin 追記 |
| 2026-04-24 | Draft v0.3 | Spec 5（command-naming）を Spec 4（cli-mode-unification）に統合、後続 Spec を繰り上げ（旧 6→5, 旧 7→6, 旧 8→7）。v1→v2 命名対応表を Spec 4 に取り込み |
| 2026-04-24 | Draft v0.4 | v1→v2 命名対応表を Spec 4 から §11.3（開発期参照資料）に移動。v2 の各 Spec は**新名称で自己完結**、v1 を参照しない設計に純化。§9.1 に v1 参照の 3 層構造（Spec / §11.3 / v1-archive）を明記 |
| 2026-04-24 | Draft v0.5 | Scenario 25 (llm_log_extract)・26 (lint-fail recovery)・33 (ambiguity UX) を追加。Scenario 27 → Spec 1 統合、30 → Scenario 10 統合、32 → Scenario 13 拡張。Scenario 28 (vault migration)・29 (dirty tree)・31 (portability) は v2 MVP 外として先送り |
| 2026-04-24 | Draft v0.6 | 中核原則 §2.11「ユーザー primary interface は発見、メンテナンスは LLM guide」を追加。コマンドを 4 Level（L1 発見 / L2 判断 / L3 メンテナンス LLM ガイド / L4 Power user）に階層化。MVP の 16 シナリオのうち 70% がメンテナンス系であることを認識し、ユーザーの認知負荷を発見に集中させる設計方針を明文化。Autonomous mode にメンテナンス提案を含める拡張を追加 |
| 2026-04-24 | Draft v0.7 | **3 層アーキテクチャ（Raw / Graph Ledger / Curated Wiki）への再構築**。変更内容:<br>• §3 全面書き直し（3 層データフロー、Vault 構造に `.rwiki/graph/` 詳細）<br>• §2.12「Graph Ledger による Evidence-backed Candidate Graph」を新設<br>• §2.11 にメンテナンス autonomous の範囲拡張（edge reject queue、Hygiene）<br>• **Spec 5 大改訂**（Graph Ledger、confidence model、edge lifecycle、Hygiene 5 ルール、usage signal、event ledger、extraction、reject workflow、community detection）<br>• Spec 0, 1, 2, 4, 6, 7 を 3 層整合で更新（Page status vs Edge status の区別、ledger 連携の明記）<br>• 用語集を 5 分類に再構成<br>• §5.10 L2 Graph Ledger JSONL フォーマット詳細を追加<br>• §6 Command モデルに L2 Graph 管理コマンド（graph/edge/extract-relations/reject）を追加<br>• §9.4 実装順序で Spec 5 を Spec 2 より先に変更<br>• §9.5 期間見積もりを 3-4 週間に拡大<br>• §11.1 シナリオ → Spec マッピングを全面更新、Scenario 34-38 追加<br>• §11.2 Skill 一覧に Graph 抽出・Lint 支援カテゴリ追加<br>• §1.5 必須ツールに `networkx` 追加 |
| 2026-04-25 | Draft v0.7.1 | Scenario 14 から仕様詳細を Spec 6 および §5.9.1/5.9.2 に移管: (a) Step 1-5 処理フローの詳細（confidence filter, M=20 等）、(b) L2 Ledger 成熟度別 fallback 閾値、(c) Hypothesis 検証時の edge reinforcement delta、(d) Perspective 保存時の L2 feedback 仕組み、(e) Hypothesis candidate frontmatter（origin_edges, verification_attempts with edge_reinforcements）、(f) Perspective 保存版 frontmatter（traversed_edges）。これにより scenarios.md は user flow に専念、仕様詳細は spec 側に集約 |
| 2026-04-25 | Draft v0.7.2 | §1 ビジョン章を 3 小節構成（1.1 継承 / 1.2 中核価値 / 1.3 差別化 / 1.4 想定ツール）から **5 小節構成**に拡張: §1.3 として **Curated GraphRAG としての位置付け**を新設（1.3.1 GraphRAG 系譜とスタンス、1.3.2 意図と処方、1.3.3 メリット、1.3.4 哲学 6 原則）。§1.4「他の手段との差別化」表に GraphRAG（通常）行を追加して通常 GraphRAG と Rwiki の差を明示。旧 §1.4 想定ツールを §1.5 に繰り下げ。これにより「なぜ Rwiki は通常の GraphRAG ではないのか」「なぜ人間キュレーション層を残すのか」「なぜ Hygiene が必要か」の設計根拠が §1 で明示的に語られる。 |
| 2026-04-25 | Draft v0.7.3 | ChatGPT 分析の取込: §1.3.1 に **ポジショニングジャンプ表**（通常 GraphRAG vs Rwiki の 5 軸対比）と **ワンライン定義**「Curated Knowledge Graph に対する探索・発見システム」を追加。§1.3.3 として **GraphRAG から採り入れる 4 技法**（community detection / global query / missing bridge detection / hierarchical summary on-demand）を明示列挙し、所管 Spec（5 / 6）と対応付け。「事前構築しない原則」を明記。メリット小節を §1.3.4、哲学を §1.3.5 に繰り下げ。Scenarios 側も Scenario 14 にパターン F（大局ビュー）・G（クラスタ surface）を追加し、4 技法がユーザーフロー上でどう surface されるかを可視化。 |
| 2026-04-25 | Draft v0.7.12 | **§2.13 Curation Provenance 新設**（13 番目の中核原則として、curation 決定プロセスの保全を first-class concept 化）。変更内容:<br>• **§2 冒頭**: 「12 原則」→「13 原則」、§2.0 マトリクスに §2.13 行追加（L1 lint pass のみ / L2 decision_log.jsonl / L3 approve 時 reasoning 必須）<br>• **§2.13 Curation Provenance 新設**: 知識は what + why の二層、`evidence.jsonl` の WHAT に対する WHY、trust chain（縦軸）に対する直交次元（横軸）。3 核心ルール（Selective recording / Append-only / Selective privacy）、自動記録 8 trigger、Reasoning hybrid 入力（chat auto-gen + manual --reason + default skip）、可視化 Tier 1-5（MVP は Tier 1-3）、self-application との接続、§2.10 との orthogonality を明記<br>• **Spec 5 in-scope に decision_log.jsonl 追加**: schema（9 fields）、10 decision types、selective recording trigger、append-only / git default、reasoning hybrid<br>• **Spec 5 Query API に 4 件追加**: `record_decision` / `get_decisions_for` / `search_decisions` / `find_contradictory_decisions`<br>• **Spec 5 主要コマンドに `rw decision *` 追加**: history（id/edge/page）、recent、stats、search、contradictions、render（Tier 2 markdown 生成）<br>• **Spec 5 config に `decision_log:` セクション追加**: gitignore default false、auto_record_triggers 8 項目、reasoning_input 3 mode<br>• **Spec 5 Phase 表更新**: P0 に decision_log.jsonl + selective recorder、P1 に Tier 2/3 markdown + mermaid、P2 に decision search/contradictions<br>• **新 review 層**: `review/decision-views/`（Tier 2 markdown timeline 出力先）<br>• **用語集 §4.3 に Curation Provenance 6 用語追加**: Curation provenance / Decision log / Decision type / Selective recording / Decision visualization Tier 1-5 / Context ref<br>• **paper-outline.md 更新**: Abstract を 3 contributions → 4 contributions、新 Section 5.5「Curation Provenance Layer」追加（Schema / Selective recording / Reasoning hybrid / Visualization tiers / Orthogonality to Evidence chain）<br>• **categorical-reformulation-roadmap.md に Hypothesis 8 追加**: Curation provenance を profunctor / decorated category として記述する圏論的 lifting 仮説 |
| 2026-04-25 | Draft v0.7.11 | **§9 実装戦略を v0.7.4 Spec 5 内部 Phase + v0.7.10 preparatory 議論完了 + Spec 分割評価レポート結果で全面再構築**。更新内容:<br>• **§9.4 実装順序**: 従来の 1 次元的な依存チェーン（Spec 0→1→5→2→3→4→7→6）を **5 Phase 並列実行対応版**に再編: Phase 1（Foundation: Spec 0, 1）→ Phase 2（L3 操作基盤: Spec 4, 7、並列可）→ Phase 3（L2 Ledger: Spec 5 内部 P0-P4 + Spec 2）→ Phase 4（Dispatch: Spec 3）→ Phase 5（本丸: Spec 6）。**Spec 4, 7 を Spec 5 より前に出す最適化**を追加（CLI と Page lifecycle は Spec 5 実装完了を待たずに起票可能）<br>• **Spec 5 内部 Phase の実装順序への統合**: MVP 範囲 = P0（Ledger 基盤）+ P1（Query cache）+ P2（Usage event + Hygiene 基礎）、P3（Competition L2/L3 + Edge Merging）は v0.8、P4（外部 Graph DB export）は要件発生時のみ optional<br>• **Spec 間 coordination tasks を明示**: Spec 1 ↔ Spec 3（frontmatter `type:` / categories.yml default_skill mapping）、Spec 2 ↔ Spec 5（extraction skill validation interface）、Spec 5 ↔ Spec 7（Page deprecation → Edge demotion flow）、Spec 4 ↔ Spec 5（Concurrency lock strategy）<br>• **§9.5 期間見積り**: 従来「3〜4 週間規模」を **11〜17 日（2〜3.5 週間）** に短縮。根拠: (a) preparatory 議論の完了で起票時再議論不要、(b) Spec 分割評価で 6/8 spec が A 評価、(c) Spec 4, 7 を Spec 5 より前に並列化可能。Phase 別の細かい見積り表を追加（1a/1b/2a/2b/3a/3b/3c/3d/4/5a/5b/6 の 12 Phase）<br>• **§9.6 MVP 範囲と先送り項目を明記（新設）**: MVP 含む 13+5 scenario と Phase 2 先送り項目（Spec 5 P3/P4、Scenario 9, 21-24, 28, 29, 31）、Phase 2 起動条件（edges > 10K、multi-user 同期）<br>• **§9.7 起票開始の判定基準を新設**: 満たすべき 5 条件のうち 3 条件達成（consolidated-spec / scenarios / Spec 5/6 preparatory）、残 2 条件（Spec 1↔3 / Spec 2↔5 coordination）は起票中に決定可のため **即起票開始可** と明言<br><br>これにより Spec 起票フェーズが迷いなく開始できる状態が完成。 |
| 2026-04-25 | Draft v0.7.10 | **Spec 5/6 起票前 preparatory 議論の 6 決定を仕様書に反映**（Spec 分割評価レポートで C 評価だった 2 Spec について、起票前に詰めるべき設計判断を確定）:<br>• **決定 5-1**（Entity shortcut 正規化）: Spec 5 が `normalize_frontmatter(page_path) → List[Edge]` API を新設、Spec 4 の `rw ingest` / `rw approve` / `rw graph rebuild` が invoke。展開ロジック 7 ステップ（mapping table 参照 → source/target 決定 → extraction_mode=explicit → 双方向 edge 自動生成 → frontmatter evidence 登録 → confidence 0.9 固定 → alias 衝突時の canonical 優先と警告）を明記、冪等性（edge_id = source+type+target の hash）も保証<br>• **決定 5-2**（L3 `related:` cache invalidation）: Hybrid 方式 = stale mark（edge 変更時に `.rwiki/cache/stale_pages.txt` に追記）+ Hygiene batch 一括 sync + CLI 起動時 stale detection（N 件蓄積で警告）+ 手動 `rw graph rebuild --sync-related`。整合性レベルは eventual（L2 正本、L3 cache 遅延は query / perspective に影響しない）<br>• **決定 5-3**（Edge reinforcement 複数合成）: 独立 event 加算を基本、per-event cap 0.1 / per-day cap 0.2 / session 内 independence_factor の 3 重制約で暴走防止。config に `max_reinforcement_delta_per_event` / `max_reinforcement_delta_per_day` 追加、§2.12 にも原則として明記<br>• **決定 6-1**（Perspective / Hypothesis 実装形態）: Standalone CLI entry（`rw perspective` / `rw hypothesize`、§2.11 Level 1）+ 内部で Spec 2 skill（`perspective_gen` / `hypothesis_gen`）を invoke。Spec 3 dispatch は distill 専用（Perspective / Hypothesize は dispatch 対象外、固定 skill 呼び出し）<br>• **決定 6-2**（Hypothesis verify workflow）: 半自動 4 段階 = LLM が candidate evidence 抽出 → user が supporting/refuting/partial/none で個別評価 → LLM が collected evidence から status 判定（supporting ≥2 かつ refuting=0 で confirmed、refuting ≥2 で refuted、混在で partial、不足で verified 据え置き）→ verification_attempts 記録 + edge reinforcement<br>• **決定 6-3**（候補 M 件 scoring function）: Perspective と Hypothesis で別式。Perspective は信頼性重視（`0.6 × confidence + 0.3 × recency + 0.1 × novelty`）、Hypothesis は未発見関係重視（`0.5 × novelty + 0.3 × confidence + 0.2 × bridge_potential`）、各要素の計算定義（recency は `exp(-days/half_life)`、novelty は raw 由来の独自性、bridge_potential は missing bridge 類似度）を明記、config で tunable<br><br>これにより Spec 5 / Spec 6 の起票評価が C → A に昇格、`/kiro-spec-init` で即起票可能な状態が完成。残る確認事項は Spec 2-3 の軽微な coordination（frontmatter `type:` / categories.yml mapping）のみ。 |
| 2026-04-25 | Draft v0.7.9 | **用語集 §4 の完全化**（v0.7.1-v0.7.8 で追加された概念が glossary 未記載だった問題を解消）。§4.1-4.5 に以下を追加:<br>• **§4.1 基本**: `Rwiki`（システム総称）/ `Vault`（管理単位）/ `Curated GraphRAG`（§1.3 位置付け）<br>• **§4.2 アーキテクチャ**: `Evidence-backed Candidate Graph` / `Derived cache`（sqlite + L3 related: の sync 関係）、Review layer に L3 限定適用の注記追加<br>• **§4.3 Graph Ledger を 6 分類にサブセクション化**: (a) ノード・エッジ基本（Entity を新設）、(b) Confidence と閾値（Evidence-less upper bound 0.3 / Candidate-weak boundary 0.45 / Reject queue threshold 0.3 を 3 閾値として明記）、(c) Evidence とイベント（Evidence_id / Dangling edge を新設、Edge event の 8 種 type 列挙）、(d) **Hygiene 5 ルール個別定義**（Decay / Reinforcement / Competition 3 Level / Contradiction tracking / Edge Merging）、(e) Usage signal の **Contribution weight 4 種別**（Direct 1.0 / Support 0.6 / Retrieval 0.2 / Co-activation 0.1）、(f) Reject / Unreject（Reject reason category 6 分類、Unreject 復元方針）、(g) Concurrency（Hygiene lock / Transaction semantics）<br>• **§4.4 Perspective/Hypothesis**: `Hypothesis status` 7 状態明記、`Discovery` 内部探索機構、GraphRAG 由来 4 技法（Community detection / Global query / Missing bridge detection / Hierarchical summary on-demand）、`Maintenance autonomous trigger` 6 閾値<br>• **§4.5 Operations**: `Pre-flight check` / `コマンド階層 4 Level`（§2.11 と整合）/ `Hygiene batch` / `Dry-run` / `Stale detection` / `Rebuild` の運用用語を追加、8 段階対話ガイドの 8 項目を glossary 内で展開<br><br>これにより「spec 本文で言及される用語が全て §4 で引ける」状態になり、Spec 起票時に参加者が同じ定義で議論できる基盤が完成。 |
| 2026-04-25 | Draft v0.7.8 | **Edge management / Hygiene 運用ポリシーの欠落 6 項目を追記**（Spec 5 起票前の実装ガイダンス確保）:<br>• **§2.12 Dangling edge policy 新設**: evidence 消失時の段階的 degrade（1 件でも有効 evidence あり → 除外再計算 / 全 dangling → weak + 0.3 クランプ + dangling_flagged event / 30 日継続 → deprecated / 人間 reject で通常 workflow）、物理削除禁止、Scenario 13 / 10 / Hygiene の 3 層責務分担を明記<br>• **§2.6 Reject 理由記録義務の追加**: rejected_edges.jsonl の必須フィールド（edge_id / rejected_at / reject_reason_category 6 分類 / reject_reason_text 自由記述 / rejected_by / pre_reject_status / pre_reject_evidence_ids）、auto-batch でも reason 記述は user 義務<br>• **Spec 5 Hygiene 運用ポリシー新設**: Concurrency モデル（MVP single-user serialized、`.rwiki/.hygiene.lock` file lock）、Transaction semantics（all-or-nothing、atomic rename）、Rule 実行順序固定直列（Decay → Reinforcement → Competition → Contradiction → Merging、依存理由明記）、Autonomous 発火 trigger 4 閾値（reject queue / Decay / Typed-edge / Dangling）<br>• **Spec 5 パフォーマンス目標表**: 1K edges で hygiene 30 秒 / 10K で 5 分 / 100K 30 分（部分 scope 推奨）、MVP 想定規模 500-5000 edges<br>• **Spec 5 Edge Unreject 復元方針新設**: reject 直前 status 復帰（stable/core は candidate にリセット）、confidence は evidence ceiling クランプ、evidence_ids 復元、unreject event 追記（理由必須）、rejected_edges.jsonl は status: unrejected マークで履歴保全<br>• **Spec 6 Maintenance autonomous trigger 表追加**: 6 個の具体 trigger と閾値、surface のみで自動実行しない原則、頻度制限（セッション 1 回）、tunable、Scenario 33 複合 orchestration との連携<br><br>これにより Spec 5 起票時に「dangling をどう扱うか」「hygiene はどう排他するか」「どの規模で動くべきか」「unreject はどこに戻すか」「autonomous trigger は何件で発火か」等の未定義事項が解消。 |
| 2026-04-25 | Draft v0.7.7 | **§2.6 を層別履歴媒体に書き直し**。従来 §2.6 は L3 wiki の frontmatter `update_history:` のみを対象としており、v0.7 で導入された L2 Graph Ledger の JSONL 履歴管理が原則レベルで未言及だった。修正内容:<br>• **§2.6 タイトル変更**: 「Git + frontmatter history」→「**Git + 層別履歴媒体**」<br>• **共通原則 4 点を明文化**: Git が第一の履歴ソース / 補助履歴で細粒度トレース / derived cache は gitignore / 退避ディレクトリを作らない<br>• **層別履歴媒体表を新設**: L1 は Git log のみ / L2 は edge_events.jsonl（append-only event log） / L3 は frontmatter update_history。各層の gitignore 対象（raw/incoming、.rwiki/cache/graph.sqlite、wiki/.obsidian/workspace*）も明示<br>• **L2 の edge_events.jsonl 詳細**: event type 8 種（created / reinforced(Direct\|Support\|Retrieval\|Co-activation) / decayed / promoted / demoted / rejected / merged / contradiction_flagged）と JSON サンプルを追加<br>• **JSONL を採用した設計理由 4 点**: append-only の git diff 親和性、人間可読性、Graph DB 正本化の却下理由（diff 管理困難、trust chain 人間検証困難）、rebuild 可能性（sqlite は derived）<br>• **rejected_edges.jsonl も履歴の一部** と明記（物理削除しない、`rw edge unreject` で復元可能、Karpathy 思想「失敗からも学ぶ」整合）<br>• **層間 trust chain の履歴横断**: evidence_id / edge_id を介して L1→L2→L3 を逆追跡可能と明記（§2.10 Evidence chain と連携）<br>• **§2.0 層別適用マトリクスの §2.6 行**も「L1=Git log のみ / L2=edge_events.jsonl / L3=frontmatter update_history」に更新して本文と整合 |
| 2026-04-25 | Draft v0.7.6 | **§2 中核原則の層別適用整理**。入力コスト問題.md 結論と §1.3.5 哲学の流れで「全原則一律適用」という v1 残骸を解消。変更内容:<br>• **§2 冒頭「10 原則」→「12 原則」誤記訂正**（実際 §2.1-§2.12）<br>• **§2.0 原則の層別適用マトリクス新設**: 12 原則 × 3 層（L1/L2/L3）で「完全適用 / 限定 / 適用外 / 該当なし」を一覧化。特に §2.2 / §2.4 が L3 中心、§2.12 が L2 独占であることを明示。「§2.10 Evidence chain のみ全層を貫く」「L2 では §2.12 が §2.2 / §2.4 より優先」を原則として明文化<br>• **§2.2 Review layer first を L3 限定化**: 「すべての変更は review/ 層を経由」を「L3 wiki/ への変更は review/ 層経由、L2 は §2.12 reject-only に従う（review 経由しない append-only ledger）」に修正。review layer の用途リストも拡張（audit_candidates / relation_candidates / hypothesis_candidates / perspectives を追加）、L2 に適用しない理由を明記<br>• **§2.4 Dangerous ops 8 段階を L3 限定化**: 「L3 Curated Wiki の不可逆操作」に限定、対象操作リストを更新（hypothesis approve / query promote 追加）、L2 で 8 段階が不要な理由を明記（1 件あたりの判断コストを低く保つ必要）<br>• **§2.5 Simple dangerous ops に L2 edge 操作を追加**: `edge reject / edge unreject / edge promote / edge demote` を Simple dangerous op として分類。複雑度スペクトラム表を拡張（「8 段階 / 1 段階 / 自動」の 3 階層）、可逆性と判断コストが比例する原則を明記<br>• **§2.12 に他原則との優先関係を追加**: 「L2 においては §2.2 / §2.4 より §2.12 が優先」を明文化、§2.9 Graph as first-class との補完関係も明示 |
| 2026-04-25 | Draft v0.7.5 | **整合性精査結果の patch**（7 次元レビューで検出した High 5 件 + Medium 3 件を修正）:<br>• **#1 改訂履歴の時系列順修正**: v0.7（04-24）を v0.7.1（04-25）より上に配置し直し<br>• **#2 Merging / merged 用語区別**: §2.12 / Spec 5 の Hygiene 5 ルールを「Edge Merging」に改名、用語集 §4.3 に「Edge Merging（Hygiene ルール、L2 edge 単位）」と「Page merged（L3 ページ status）」を別項で定義<br>• **#2 関連修正**: 用語集 §4.3 の Page status を「4 種」→「5 種（merged 含む）」に訂正<br>• **#3 Confidence model DRY 化**: Spec 5 in-scope から 6 係数式の重複記述を削除、「§2.12 を SSoT とし、Spec 5 は実装する役割」と明記、config への参照のみ残す<br>• **#4 Spec 5 MVP スコープ明確化**: Key Requirements 全 14 項目に Phase マーカー（[P0] - [P4]）を付与、「MVP 範囲 = P0+P1+P2 の要件 1-11, 13」を明記、P3 は v0.8、P4 は optional<br>• **#5 Query API Design サブセクション新設**: Spec 5 に 9 個の API（get_neighbors / get_shortest_path / get_orphans / get_hubs / find_missing_bridges / get_communities / get_global_summary / get_hierarchical_summary / get_edge_history）の signature、返り値 schema、共通フィルタ引数、性能要件を定義。Spec 6 からは JSONL 直読せず API 経由とすることを明示<br>• **#6 §5.4 参照の曖昧性解消**: `§5.4 Spec 5 config` → `Spec 5 config（.rwiki/config.yml の graph.*）` に明確化<br>• **#7 Entity ショートカット正規化詳細**: Spec 1 と Spec 5 の境界を明示、展開ロジック 6 ステップ（mapping table 参照、source/target 決定、extraction_mode=explicit、双方向生成、frontmatter evidence、confidence 0.9 固定）を追加<br>• **#8 Perspective/Hypothesis フィルタ意味論明確化**: Spec 6 Step 2 のフィルタ条件に「edge status フィルタと confidence 絶対値フィルタの AND」である旨明記、閾値 0.4 / 0.3 が §2.12 の 3 段階境界とは別の API-level フィルタ値であることを補足 |
| 2026-04-28 | Adjacent Sync (Spec 7 design approve commit `b45bdc3`) | §7.2 Spec 7 表「Dangerous op の分類」13 種に **Skill lifecycle 拡張 2 種**を追加（`skill deprecate` = 危険度中 / 必須対話 / `--auto` ✓、`skill archive` = 危険度低 / 推奨対話 / `--auto` ✓）。Spec 7 design Decision 7-15 で確定（`skill install` = 簡易 1 段階 + Skill 4 種で 8 段階対話 / 1 段階の対話階段確定）。表は 13 種 → 15 種に拡張、`skill retract` 行の前に `skill deprecate` を、`skill retract` 行の後に `skill archive` を挿入。再 approval 不要（roadmap.md「Adjacent Spec Synchronization」運用ルール準拠）。 |
| 2026-04-26 | Adjacent Sync (Spec 4 review F') | §7.2 Spec 7 表 L2197 直後に **コマンド対応注記**を追加（13 操作の CLI 名は基本 `rw <操作名>` で機械的に対応、例外は `merge (review)` / `merge (wiki)` → `rw merge` と `promote-to-synthesis` → `rw query promote` の 2 ケースのみ）。Spec 4 (rwiki-v2-cli-mode-unification) requirements review で軸分離設計（Spec 4 = CLI 名軸、Spec 7 = 操作名軸）を確立した際、CLI ↔ 操作名対応の SSoT として drafts §7.2 Spec 7 表に注記したもの。再 approval 不要（roadmap.md「Adjacent Spec Synchronization」運用ルール準拠）。 |
| 2026-04-25 | Draft v0.7.4 | **`docs/入力コスト問題.md` 最終結論の完全取込**。Gap analysis で検出した欠落 / 部分項目を patch:<br>• **§2.12** に **初期 confidence 6 係数加重式**を明記（evidence 0.35 / explicitness 0.20 / source 0.15 / graph_consistency 0.15 / recurrence 0.10 / human 0.05、合計 1.0）、係数ごとの定義（explicit=1.0 / paraphrase=0.75 / inferred=0.5 / co_occurrence=0.25 等）、**evidence-less upper bound** を強制クランプ式として定式化<br>• **§2.12 閾値 3 段階**（stable 0.75 / candidate 0.45 / weak 0.3 / reject_queue <0.3）を表として追加<br>• **§2.12 明示的却下代替案 5 件表**（全件 approve / Graph DB 正本 / LLM 自信度 confidence / 使用回数強化 / 矛盾削除）を追加<br>• **Spec 5 Usage signal** を **4 種別**（Direct 1.0 / Support 0.6 / Retrieval 0.2 / Co-activation 0.1）に分解、`sqrt(confidence)` と `independence_factor` と `time_weight` の意図説明追加<br>• **Spec 5 Competition 3 レベル表**（L1 同 node pair MVP / L2 類似 node pair Phase 3 / L3 semantic tradeoff Phase 3）追加、winner/runner-up/loser/obsolete の status transition 明記<br>• **Spec 5 Event ledger** の event type を細分化（`reinforced(Direct\|Support\|Retrieval\|Co-activation)` / `contradiction_flagged` 追加）<br>• **Spec 5 Relation type** に MVP canonical 12 セット（uses/depends_on/causes/improves/degrades/compares_with/alternative_to/part_of/supports/contradicts/co_occurs_with/related_to）を明記、拡張方針併記<br>• **Spec 5 config** に `candidate_weak_boundary: 0.45` / `confidence_weights` / `usage_signal.contribution_weights` / `competition.enable_level_2/3` / `similarity_threshold` 等を追加<br>• **Spec 5 実装 4 Phase**（P0 Ledger 基盤 / P1 Query cache / P2 Usage + Hygiene 基礎 / P3 Competition L2/L3 + Merging / P4 optional 外部 Graph DB export）を機能単位で表化、MVP 範囲は P0-P2、P3 は v0.8 候補を明示。これにより Spec 5 起票時に「何を実装し何を後送りするか」が明確化。 |

---

_本ドキュメントは `/kiro-spec-init` で Spec 0-8 を正式起票する前の統合下書きです。合意済み内容を一元化し、シナリオ 14 以降の議論の基点とします。_
