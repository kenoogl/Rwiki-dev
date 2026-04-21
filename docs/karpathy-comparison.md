---
title: Rwiki と Karpathy の LLM Wiki の比較
created: 2026-04-21
updated: 2026-04-21
status: living-document
reference: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
---

# Rwiki と Karpathy の LLM Wiki の比較

## このドキュメントの目的

Rwiki は [Andrej Karpathy 氏が公開した LLM Wiki のアイデア](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) に着想を得て構築されたシステムです。本ドキュメントは、Karpathy 氏の原案と Rwiki の実装の**差異を継続的に記録する生きたドキュメント**です。

Rwiki は今後も進化するため、差分は時間とともに変化します。各改訂の履歴は末尾の「更新履歴」で追跡します。

---

## 継承した核心コンセプト

Karpathy のアイデアから引き継いだ中核思想：

- **知識の一度限りのコンパイル**: 毎クエリ時に生データを再検索するのではなく、LLM が知識を蓄積された wiki に統合し続ける
- **人間は戦略、LLM は実務**: 人間は「何を知りたいか」を決め、LLM が要約・相互参照・ファイリングを行う
- **Git で管理される markdown リポジトリ**: バージョン履歴・分岐・協働を無料で得る
- **Memex の現代的実装**: Vannevar Bush（1945）の個人知識ストア構想を、LLM で実用化

---

## Karpathy 原案と Rwiki の差分

### 1. 層構造と安全装置

| 項目 | Karpathy | Rwiki |
|------|----------|-------|
| **層構造** | 2 層（`raw/` + `wiki/`）+ `schema/` | **3 層（`raw/` + `review/` + `wiki/`）** — 明示的な検証・承認ゲート層を追加 |
| **LLM の書込権限** | `wiki/` を直接編集 | **`raw/` と `wiki/` は LLM 書込禁止**。必ず `review/` を経由 |
| **承認プロセス** | 会話ベース（Obsidian で「見る」） | **frontmatter 必須（`status: approved`, `reviewed_by`, `approved:`）** + CLI による機械検証 |

→ Rwiki は「LLM がそれっぽい嘘を wiki に混入させるリスク」を構造で排除。Karpathy のアプローチは個人の自己規律に依存。

### 2. 実行方式

| 項目 | Karpathy | Rwiki |
|------|----------|-------|
| **主な操作** | 対話型（LLM エージェント + Obsidian 並行表示） | **CLI コマンド主体**（`rw lint / ingest / approve / query / audit`） |
| **対話型タスク** | ほぼ全て | **`synthesize` のみ**（wiki ページ候補生成） |

→ Rwiki は「毎回 LLM と会話する必要なく、コマンドで運用サイクルを回せる」形に自動化。

### 3. Lint / Audit の体系化

| 項目 | Karpathy | Rwiki |
|------|----------|-------|
| **Lint の実行主体** | LLM に wiki を読ませて会話で問題発見 | **Python で自動実行**（`rw lint`、決定的・高速） |
| **Audit の階層** | 明示的な階層化なし | **4 Tier**: micro（更新ページ高速）/ weekly（全頁構造）/ monthly（LLM 意味的）/ quarterly（LLM 戦略的） |
| **重大度分類** | なし | **4 水準（CRITICAL / ERROR / WARN / INFO）** + exit code 契約（0 / 1 / 2） |
| **ログ形式** | `log.md`（時系列 markdown） | `log.md` + **JSON 構造化ログ**（`logs/*_latest.json`、プログラム消費可能） |

### 4. Query（質問応答）の扱い

| 項目 | Karpathy | Rwiki |
|------|----------|-------|
| **成果物** | なし（qmd で検索 + LLM リランク） | **4 ファイル契約**（`question.md` / `answer.md` / `evidence.md` / `metadata.json`）で構造化アーティファクトを生成 |
| **ハルシネーション防止** | 人間レビューに依存 | **Fact-Evidence 分離** + `[INFERENCE]` マーカー + `source:` 必須で trust chain を機械検証 |
| **再利用性** | 会話コンテキスト依存 | **Reusability First**（自己完結、後日レビュー論文の素材として使える） |

### 5. 依存関係とツール

| 項目 | Karpathy | Rwiki |
|------|----------|-------|
| **必須ツール** | Obsidian（IDE 役）、Web Clipper、LLM エージェント（Claude Code / Codex） | **Python 標準ライブラリのみ**（Claude CLI は synthesize/query/audit でのみ使用） |
| **スケール対応** | `~100 pages` 超は qmd（BM25 / ベクトル検索）に依存 | 外部検索なし。代わりに `audit quarterly` がグラフ俯瞰・スキーマ改訂提案 |

### 6. Rwiki で追加した概念

Karpathy 原案にはない、Rwiki 独自の要素：

- **`review/synthesis_candidates/`**: wiki 昇格前の待機場所
- **`wiki/synthesis/`**: クロスページ統合知識の専用層（entity / concept と区別）
- **`raw/llm_logs/`**: LLM との対話ログを生データとして保存し、`rw synthesize-logs` で再利用
- **`templates/AGENTS/`**: タスク別プロンプトの一元管理（Prompt Engine が動的ロード）
- **Kiro-style spec-driven development**: `.kiro/specs/` で requirements → design → tasks → impl の段階承認

### 7. 開発思想の違い

**Karpathy: 個人的な実装パターンの提示**

> "a way I personally use it" — 自分用ツールのレシピ共有。各自のカスタマイズ前提。

**Rwiki: 共有可能な知識基盤の構築**

- 構造的なガバナンス（LLM 書込禁止層、承認ゲート）
- CLI で自動化された運用サイクル
- 自動テスト（`pytest tests/` で 644+ passed）・spec-driven 開発プロセス
- 複数人運用を見据えた明示的な approval metadata

---

## 要約

Karpathy のアイデアは「**LLM が知識をインクリメンタルにコンパイルし続ける**」という中核コンセプトを提供しました。Rwiki はこの思想を継承しつつ、以下の方向に具体化しました：

1. **信頼性の構造化** — LLM を信用しきらず、人間承認を必須化
2. **運用の自動化** — 会話型から CLI 型へ、機械検証可能な契約へ
3. **監査可能性** — severity / exit code / JSON ログで audit を体系化
4. **再利用可能アーティファクト** — query を「会話」ではなく「構造化された成果物」として残す

Karpathy の個人運用レシピに対し、Rwiki は「研究グループ・長期運用に耐える知識基盤」へと発展させた、と整理できます。

---

## 更新履歴

| 日付 | 変更内容 | 反映元スペック・コミット |
|------|---------|----------------------|
| 2026-04-21 | 初版作成 — Karpathy 原案との差分を 7 観点で整理 | `rw-light-rename` 完了時点（全計画スペック実装済み状態） |

### 更新ガイドライン

このドキュメントは以下のタイミングで更新する：

- Rwiki に**新しい概念・層・ワークフロー**が追加されたとき（例: 新スペック実装完了）
- Karpathy 氏が gist を更新して **LLM Wiki の設計思想を変更した**とき
- **外部コミュニティの類似プロジェクト**との比較が有益と判断されたとき（将来的な拡張）

更新時は「更新履歴」に日付・変更内容・反映元（commit ハッシュまたはスペック名）を追記する。
