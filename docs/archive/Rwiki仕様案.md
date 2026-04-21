### 仕様素案

karpathyのLLM wiki(https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)を元に、知識ベースを構築するしくみを作り出す。

- 知識ソースの取捨選択は人
- 知識の要約や、概念、比較や分析はLLM
- ソース・システムの管理、定期的な健康診断はLLM
- 増加する複雑性との戦いをLLMに任せる方針

### 利用するツール

- Obsidian（メモアプリ）+ Smart Composer + Web Clipper + Dataview 
- LLM（ClaudeCode、OpenAI Codex、OpenCodeなどでも可）
- Git (Wikiのバージョン管理をする)
- Markdownファイルの集合（これがWikiになる）
- Zotero　(pdf管理)
- Script
- qmd (オプション)
  - Markdownドキュメントを対象に、BM25による全文検索、ベクトル検索、そしてLLMによる再ランキングを組み合わせた、いわば“ローカルで動く検索エンジン＋RAG用リトリーバ”のような構成を持つツール, MCP対応


### 方針

- 生データを不変な情報源として保持する
- 検証済みワークフローを通じて知識を変換する
- 再利用可能で一貫性のある知識層を構築する
- トレーサビリティ・再現性・信頼性を確保する

### 層管理

 ~~~
 raw/incoming/          : 未検証ソースの一時置き場
 raw/                   : 確定した一次ソース
 raw/llm_logs/          : llmとの対話生ログ
 review/                : LLM生成候補の人手レビュー待ち
 wiki/                  : キュレーション済み（承認済み）知識
 logs/                  : lintや変換処理のログ
 scripts/               : CLI実装
 CLAUDE.md              : Claudeへの実行ルール
 index.md               : Wikiインデックス
 log.md                 : 作業ログ
 ~~~

## レイヤーの意味

### raw/

- 不変のソース層
- ingest によってのみ書き込み可能
- LLMによる変更は禁止

------

### review/

- 検証・安定化層
- 含まれるもの：
  - synthesis候補
  - クエリアーティファクト
  - 中間構造化知識
- 役割：
  - 再利用性の確保
  - 構造化
  - ノイズ削減
- 複数種類の構造化データを含んでもよい

------

### wiki/

- キュレーション済み知識層
- 以下のみを含む：
  - 承認済み
  - 検証済み
  - 再利用可能な知識

### ルール

- `raw/` から `wiki/` へ直接移動してはならない
- `raw/llm_logs/` から `wiki/synthesis/` へ直接移動してはならない
- `wiki/` に入るすべての知識は `review/` を通過しなければならない

## 知識フロー（必須）

すべての知識は以下の流れに従う：

```
raw → review → （人間による承認）→ wiki
```

### LLMインターフェイス

- RwikiディレクトリでCluade CLiを起動してターミナルから**直接指示を与える**

  - カレントディレクトリでclaudeを起動すると、自動的にコンテキストになり`CLAUDE.md`を読み込んだ上でファイル操作を行う
  - ただし、一次ソース（`raw/`）へのClaudeの書き込みは禁止

- Obsidianの**Smart Composer プラグイン**を利用する

  - ノートを選択してAIに編集指示

  - Claudeのファイル編集に近い操作感




# グローバルルール

## rawの完全性

```text
LLMはいかなる場合もrawを変更してはならない
```

- `raw/` は読み取り専用
- `raw/incoming/` は未検証であり、コミットしてはならない

------

## reviewの強制

```
すべての知識はwikiに入る前にreviewを通過しなければならない
wikiへのすべての変更は review → 承認プロセスに従う
```

- reviewは任意ではない
- reviewは単なるバッファではなく品質ゲート

------

## 承認要件

```
reviewからwikiへ昇格するすべての知識には承認が必要
人間による承認は必須
```

- 自動承認は禁止
- 推測による承認は禁止
- 承認メタデータの捏造は禁止

------

## 書き込み権限

| レイヤー | 書き込み             |
| -------- | -------------------- |
| raw      | ❌ 禁止               |
| review   | ⭕ 許可               |
| wiki     | ⭕ 許可（承認後のみ） |

------

## インデックスとログ整合性

- すべてのwikiページは `index.md` に登録する必要がある
- wiki更新は必ず `log.md` に追記する
- `log.md` は追記専用

------

## コミット分離

raw、review、wikiの更新は**別々にコミットすること**

------

# タスクの意味

## Synthesizeの役割

- synthesizeタスクは review に構造化知識を生成する
- wikiへ直接公開してはならない

# タスクモデル

## タスク分類（必須）

すべての操作は以下のいずれかに分類する：

```
ingest
lint
synthesize
synthesize_logs
approve
query_answer
query_extract
query_fix
audit
```

------

## タスク選択ルール

優先順位：

1. 明示的コマンド
2. 自然言語からの分類
3. それ以外 → 停止

------

## 曖昧性ルール

```
タスクが不明確な場合 → 停止
```

- 暗黙の推測は禁止

------

# 実行モデル

## エージェントロードルール

- すべてのAGENTSを読み込んではならない
- 必要なもののみロードする

------

## 実行宣言（必須）

実行前に必ず以下を宣言：

- タスク種別
- 読み込んだエージェント
- 実行計画

------

## マルチステップルール

```
複数ステップの処理は分解すること
```

禁止例：

- ingest → wiki を1ステップで行う
- query → wiki昇格 を1ステップで行う

------

# 監査モデル

## 定義

```
auditはwikiの整合性・構造・完全性を評価する読み取り専用タスク
```

### ルール

- ファイル変更は禁止
- 問題を報告してから修正
- 修正にはユーザの明示指示が必要

------

# 失敗条件

以下の場合、システムは停止する：

- タスクが特定できない
- 必要入力が不足
- 承認なしでwikiに書き込もうとした
- コミット境界が不明
- 必要なAGENTSが特定できない

------

## 設計原則

```
このシステムは単なる文書生成器ではない

以下を備えた統制された知識パイプラインである：

- 不変のソース
- 強制された検証
- 明示的なタスク分岐
- 必須のレビュー
- 人間による承認
- トレーサブルな実行
```

------

## プロンプト設計

`CLAUDE.md` の肥大化によるコンテキスト圧迫を避けるため、
**常時必要な最小原則だけを `CLAUDE.md` に残し、詳細な手順・ルールは `AGENTS/` 配下のサブプロンプトへ分離する**。

この分割により、以下を実現する。

- Claude実行時の常時コンテキストを最小化する
- 作業ごとに必要なルールだけをオンデマンドで読む
- 仕様変更時の保守性を高める
- ingest, synthesis, audit などの運用ルールを独立管理する

## 基本方針

### CLAUDE.md はカーネル

`CLAUDE.md` は **全作業に共通する絶対原則のみ**を保持する。

含める内容は最小限とし、詳細手順は書かない。

------

### AGENTS/ はサブプロンプト群

`AGENTS/` 配下には、**作業単位・運用単位の詳細ルール**を配置する。

Claude は、現在のタスクに必要なファイルのみを読む。

------

### 読み込みは必要時のみ

原則として、Claude は `AGENTS/` の全ファイルを最初から読まない。

現在のタスクに応じて、必要なサブプロンプトのみを選択的に読む。

## まとめ

このconstitutionは以下を保証する：

- レイヤーの厳格な分離
- 知識昇格前の必須レビュー
- 明示的かつ統制された実行
- ワークフローにおける曖昧さの排除



### 運用サイクル

~~~
新規ソース投入 > raw/incoming
↓
rw lint
↓
rw ingest
↓
Claudeで wiki 更新（5〜10ページ）
 index.md 更新
 log.md 追記
↓
会話ログが価値あるなら raw/llm_logs に保存
↓
rw synthesize-logs
↓
review/synthesis_candidates を人が確認
↓
承認したものだけ wiki/synthesis に移動
↓
Obsidianで確認・修正
（グラフビュー、Dataviewテーブル）
↓
Claude query（質問・分析依頼）
 良い回答 → review/synthesis_candidates/ に保存 → 承認 → rw approve → wiki/synthesis/
↓
定期 audit（AGENTS/audit.mdをロードして実行）
 【毎ingest後】マイクロチェック
   リンク切れ・index更新漏れ・frontmatter崩れ
 【週次】Structural Audit
   孤立ページ・双方向リンク・命名違反
 【月次】Semantic Audit
   矛盾候補抽出 → [CONFLICT] / [TENSION] / [AMBIGUOUS]
   孤立ページ → ユーザーに報告、確認後に統合
 【四半期】Strategic Audit
   グラフ構造俯瞰・スキーマ改訂提案
     │
     └──────────────► 繰り返し
~~~



## 推奨ディレクトリ構成

```text
Rwiki/
├── CLAUDE.md
├── index.md
├── log.md
├── raw/                   # ソース層（不変・Claudeは読み取りのみ）
│   ├── llm_logs/          # LLMとの対話生ログ（git保存、ingest適用外）
│   ├── incoming/          # ソースの仮置き場所
│   │   ├── articles/      # Web clipper取得Markdown
│   │   ├── papers/        # 論文
│   │   │   ├── zotero/    # zoteroメタデータ
│   │   │   └── local/     # ローカルpdf,メタデータ
│   │   ├── meeting-notes/ # 研究会・会議メモ（生テキスト）
│   │   └── code-snippets/ # 参考コード（Julia/C++/Fortran）
│   ├── papers/            # 以降は確定データを配置
│   │   ├── zotero/
│   │   └── local/
│   ├── articles/
│   ├── meeting-notes/
│   └── code-snippets/
│   
├── review/
│   └── synthesis_candidates/
├── wiki/                  # Wiki層（Claude管理）
│   ├── concepts/          # 概念ページ
│   ├── methods/           # 手法比較・技術詳細
│   ├── projects/          # プロジェクト別ページ
│   ├── entities/          # 人物・ツール・データベース
│   │   ├── people/
│   │   └── tools/
│   └── synthesis/         # 横断的考察・比較分析（資産化済み回答）
├── logs/
└── scripts/
│   └── rw.py
│
├── AGENTS/                # モード別ポリシー（オンデマンドロード）
│   └── audit.md           # 監査エンジン
├── .obsidian/
└── .git/
```

## 
