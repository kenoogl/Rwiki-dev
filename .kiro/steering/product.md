# Product Overview

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §1

## 一行定義

Rwiki は **Curated Knowledge Graph に対する探索・発見システム**である。LLM は graph を育て、人間は graph を方向づけ、Hygiene が graph を進化させる。

## ビジョンの起源

Andrej Karpathy の LLM Wiki アイデアと Vannevar Bush の Memex を継承。

- **知識は一度コンパイルし、継続的に保守する**（毎クエリで再検索しない）
- **人間は戦略・判断、LLM は統合・構造化の実務**
- **Git で管理される markdown リポジトリ**

## 中核価値: Trust + Graph + Perspective + Hypothesis の四位一体

| 軸 | 内容 |
|----|------|
| **Trust** | 人間承認と evidence chain で裏付け |
| **Graph** | typed edges を持つ知識グラフ |
| **Perspective** | LLM が graph traverse で視点提示 |
| **Hypothesis** | LLM が未検証の仮説を生成、検証ワークフロー供給 |

LLM 単体でも wiki 単体でもなく、**両者の統合**でのみ実現できる知的生産形態。

## Curated GraphRAG としての位置付け

通常の GraphRAG（Microsoft Research 2024 系列）と Rwiki v2 の対比：

| 軸 | 通常 GraphRAG | Rwiki v2 |
|----|---|---|
| 起点 | 未整理テキスト → graph 化 | wiki + 候補 graph 二層併走 |
| 主体 | LLM 中心 | 人間承認中心（L3）+ LLM 抽出（L2） |
| 品質 | 自動抽出ノイズを含む | Reject-only + Hygiene + Evidence |
| 用途 | RAG 検索粒度の強化 | 検索 + Perspective/Hypothesis 生成 |
| 知識の時間変化 | 基本静的 | evolving（使用で育つ、不活性で痩せる） |

## GraphRAG から採り入れる 4 技法

| 技法 | 用途 |
|------|------|
| Community detection | Perspective で類似手法 surface |
| Global query | 大局視点生成 |
| Missing bridge detection | Hypothesis の主要源泉 |
| Hierarchical summary（on-demand） | 大規模 graph 俯瞰 |

**事前構築しない原則**: graph は evolving。community summary は on-demand 生成（事前 index 化しない）。理由 — (a) 事前構築は陳腐化しやすい、(b) 必要時のみ LLM コスト発生、(c) Hygiene 後の最新状態を反映できる。

## 設計信念（哲学）

1. Graph は static ではなく **evolving**
2. Evidence が graph を裏付ける（evidence.jsonl は first-class）
3. 人間の役割は **戦略判断と reject、方向付け**
4. 知識の正誤は時間の関数（古い知識は deprecate 可能、失敗も記録）
5. LLM は抽出・統合・surface の実務者、人間は編集者・方向性決定者
6. 「recall を上げる」ではなく **「使われる知識を残す」**

## Target Use Cases

- **研究者・知識ワーカー**: 複雑で進化し続ける情報を体系化、Perspective で異分野横断の関係発見
- **論文・レビュー執筆**: wiki ＋ Perspective を素材に、新規論点を Hypothesis から発掘
- **Obsidian Vault ユーザー**: 既存 Vault に LLM 自動抽出と Hygiene を追加、graph view を意味的に強化
- **個人 Memex 構築**: 一生涯の読書・調査ログを徐々に graph 化、後年 traverse 可能に

## 運用上の Design Principles

- **Safety Guardrails**: LLM は L3 wiki を直接書き換え不可。L1 raw も人間入力のみ。L2 ledger は append-only
- **Traceability**: 全変更は Git + 層別補助履歴（edge_events.jsonl / frontmatter update_history）で追跡
- **Reversibility**: reject / unapprove / unreject / reactivate で全ての軽量操作は可逆
- **LLM 非依存**: Claude Code は参照実装、Spec 3 が抽象層を提供

## 他手段との差別化

| 手段 | Rwiki との違い |
|------|--------------|
| 素の LLM チャット | 学習データのみ、hallucination、検証不可 |
| RAG（通常） | 未キュレート、graph 構造なし、視点創発なし |
| GraphRAG（通常） | 自動抽出のみ、Hygiene なし、人間層なし |
| Obsidian / Notion | 品質保証・LLM 連携・graph 自動進化なし |
| **Rwiki v2** | 候補 graph + 人間承認 + Hygiene + Evidence + Perspective/Hypothesis |

## Perspective vs Hypothesis

| 軸 | Perspective | Hypothesis |
|----|---|---|
| 性質 | 既存知識の再解釈 | 未検証の新命題 |
| Trust chain | 維持（wiki 引用） | 検証前、`[INFERENCE]` 必須 |
| 後続 | 再利用（論文素材等） | raw/ で裏付け→検証→昇格 |
| 位置付け | 知識の深化・整理 | 知識の前進・拡張 |

両者は LLM × Graph の同じメカニズムから生まれるが、**出力形態と後続ワークフローが異なる**。Spec 6（perspective-generation）で統合的に扱う。
