# Rwiki ユーザーガイド

> **Inspired by Andrej Karpathy's LLM Wiki approach**
>
> Rwiki は、Andrej Karpathy 氏が公開した [LLM Wiki のアイデア](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) に着想を得て構築されています。「LLM による知識のキュレーションを、人間の判断で品質を担保しながら継続的に行う」という Karpathy 氏の洞察に深い敬意を表します。

## Rwiki とは

Rwiki は、**生データから知識をキュレーションして蓄積し、それを活用するための基盤**です。

日々の情報収集（論文・記事・会議メモ・LLM との対話ログなど）は膨大ですが、それをそのまま溜め込んでも「後で参照できる知識」にはなりません。Rwiki は、生データを **人間の判断を経てキュレーションされた Wiki** へ変換するパイプラインを提供します。

### どんな問題を解決するか

| 課題 | Rwiki の解決策 |
|------|---------------|
| 読んだ論文・記事が後から参照できない | 構造化された Wiki ページとして蓄積 |
| LLM に生成させた文章の品質が不安 | 人間の承認を必須とする review 層でフィルタリング |
| 蓄積した知識の整合性が崩れていく | audit コマンドで定期的に検証 |
| 「あの情報どこにあったっけ」が解消しない | query コマンドで Wiki から回答を抽出 |

### Rwiki を使うメリット

1. **LLM の暴走を構造で防ぐ** — LLM は `raw/` も `wiki/` も直接書き換えられない設計。AI が生成した「それっぽい嘘」が信頼できる知識層に混入するリスクを仕組みとして排除します。
2. **人間判断のコストを最小化** — LLM が候補を作成し、人間は承認・却下・修正だけを行います。すべてを自力で書かず、品質ゲートだけを守る形で効率化できます。
3. **完全なトレーサビリティ** — Wiki ページから元の生データまで逆追跡可能。git 履歴と JSON ログで「いつ誰がどの判断をしたか」が常に残ります。
4. **知識ベースの腐敗を防ぐ audit** — 蓄積するほど整合性が崩れる（リンク切れ・定義の矛盾・孤立ページ）問題を、定期的な audit で早期発見できます。
5. **外部依存ゼロのポータビリティ** — Python 標準ライブラリのみで動作。特殊なサーバー・データベース・SaaS は不要で、ローカルの Obsidian Vault として完結します。
6. **Git でバージョン管理** — すべての知識変更が git 履歴に残り、過去の状態への復元や差分確認が常に可能です。

### 他の方法との違い

| 手段 | Rwiki との違い |
|------|---------------|
| 単なる Markdown メモ（Obsidian 等） | LLM 連携・整合性 audit・承認ワークフローがない。情報を溜められるが、**キュレーションと品質保証**の仕組みが欠落 |
| LLM に直接 Wiki を書かせる | 誤情報が混入しても検出しにくい。Rwiki は **人間承認を必須化** して信頼性を担保 |
| ノートアプリ（Notion 等） | ベンダーロックイン・構造化の曖昧さ・Git 追跡不可。Rwiki は**プレーンテキスト + Git で完全可搬** |
| 検索のみ（grep / RAG） | 「後で探せる」だけで「整理された知識」にはならない。Rwiki は **蓄積と整理を同時に回す**仕組み |

---

### 3 層パイプラインの概念

```
raw/          生データ層    — 変更禁止。信頼できるソースのアーカイブ
  ↓
review/       検証・待機層  — LLM が生成した候補を人間がレビューする場所
  ↓
wiki/         知識層        — 人間が承認した信頼できる知識だけが存在する
```

**核心ルール**: LLM は `wiki/` を直接書き換えられない。すべての知識は `review/` での人間承認を経て昇格する。これにより、蓄積した知識の信頼性を担保します。

### 典型的なユースケース

**ケース 1: 論文・記事を知識として蓄積する**
1. 論文 PDF や記事を `raw/incoming/` に置く
2. `rw lint` → `rw ingest` で raw 層に取り込む
3. Claude で `synthesize` タスクを実行 → `review/` に Wiki ページ候補が生成される
4. 候補を人間がレビューして承認 → `rw approve` で `wiki/` に昇格

**ケース 2: LLM との対話ログを知識に変換する**
1. Claude との対話ログを `raw/llm_logs/` に保存
2. `rw synthesize-logs` で synthesis 候補を生成
3. レビュー・承認 → `wiki/` に昇格

**ケース 3: 蓄積した知識に質問する**
```bash
rw query answer "SINDy と疎回帰の関係を説明してほしい"
```

**ケース 4: 定期的に知識の整合性を確認する**
```bash
rw audit weekly    # リンク切れ・孤立ページ等の構造チェック
rw audit monthly   # LLM による意味的矛盾の検出
```

---

## 実際の使い方: 週次ワークフロー例

Rwiki は「毎日全部やる」ではなく、**投入 → キュレーション → 承認 → 監査**のリズムを週次サイクルで回す設計です。典型的な 1 週間の流れ:

```
月曜（投入）
├── 週末に読んだ論文 2 本を raw/incoming/papers/local/ に配置
├── 会議メモを raw/incoming/meeting-notes/ に配置
├── rw lint            → 全入力ファイルの検証
└── rw ingest          → raw/ へ取り込み（自動コミット）

火〜水曜（候補生成）
├── Claude CLI で synthesize タスクを実行
│   └── raw/ の新規ファイルから review/synthesis_candidates/ に Wiki ページ候補を生成
└── rw synthesize-logs → 直近の LLM 対話ログから synthesis 候補を追加生成

木〜金曜（レビューと承認）
├── review/synthesis_candidates/ の候補を隙間時間で確認
│   └── 良い候補には frontmatter で status: approved, reviewed_by, approved: <日付> をマーク
├── rw approve         → wiki/synthesis/ に昇格（手動で git commit）
└── rw audit micro     → 今週更新したページのリンク切れ等を即時チェック

週末（定期監査）
└── rw audit weekly    → 全 wiki ページの構造監査
```

**月次・四半期での追加運用**:

```
月初
└── rw audit monthly    → LLM による意味的矛盾・定義の不一致を検出

四半期末
└── rw audit quarterly  → wiki グラフの俯瞰とカバレッジギャップ分析
```

**日常的なクエリ（いつでも）**:

```bash
# 蓄積した知識に自然言語で質問する
rw query answer "SINDy と疎回帰の関係を簡単に説明して"

# 構造化されたアーティファクトとして抽出する（レビューレポートの下書き等）
rw query extract "SINDy と Koopman 演算子の違い" --type comparison
```

この週次リズムにより、情報を入れっぱなしにせず「読んだ → キュレート → 使える知識」のサイクルが回り続けます。

---

## 初めて使う場合: セットアップ

### 1. Vault（知識ベースのディレクトリ）を作成する

```bash
python /path/to/Rwiki-dev/scripts/rw_cli.py init ~/my-vault
```

これにより、以下の構造が作成され、`rw` コマンドのシンボリックリンクが設定されます:

```
~/my-vault/
├── raw/
│   ├── incoming/       ← ここに生データを置く
│   └── llm_logs/       ← LLM との対話ログ
├── review/
│   ├── synthesis_candidates/
│   └── query/
├── wiki/
│   ├── concepts/
│   ├── methods/
│   └── synthesis/
├── CLAUDE.md           ← Claude CLI 用のルール定義
├── AGENTS/             ← Claude CLI が読み込むタスク別プロンプト
└── scripts/
    └── rw -> rw_cli.py ← CLIコマンドへのリンク
```

### 2. Vault のディレクトリで作業する

```bash
cd ~/my-vault
```

以降のコマンドは Vault のルートで実行します。シンボリックリンク経由で `rw` コマンドが使えます:

```bash
python scripts/rw <command>
# または絶対パスで
python ~/my-vault/scripts/rw <command>
```

### 3. 生データを投入する

論文・記事・メモを `raw/incoming/` 配下の適切なサブディレクトリに置きます:

```
raw/incoming/
├── articles/           ← ウェブ記事
├── papers/
│   ├── local/          ← ローカルの論文
│   └── zotero/         ← Zotero 管理の論文
├── meeting-notes/      ← 会議メモ
└── code-snippets/      ← コードメモ
```

各ファイルには YAML フロントマターが必要です:

```yaml
---
title: "SINDy: 非線形力学系の疎同定"
date: 2026-04-21
source: "https://example.com/sindy-paper"
type: paper
tags: [sparse-regression, dynamical-systems]
---

# 本文...
```

---

## 基本的な運用サイクル

```
[1] lint        raw/incoming/ のバリデーション
[2] ingest      raw/incoming/ を raw/ へ移動・コミット
[3] synthesize  raw/ から review/ への知識候補生成（Prompt）
[4] approve     review/ の承認済み候補を wiki/ へ昇格（CLI）
[5] audit       wiki/ の整合性・一貫性を検証（CLI Hybrid）
```

### ステップ詳細

**ステップ1: lint**

```bash
rw lint
```

`raw/incoming/` 配下のファイルを検証し `logs/lint_latest.json` を生成する。
FAIL が存在する場合は ingest を実行しない。

**ステップ2: ingest**

```bash
rw ingest
```

lint が FAIL == 0 の場合のみ実行可能。
`raw/incoming/` のファイルを `raw/` へ移動し、`ingest: batch import` でコミットする。

**ステップ3: synthesize（Prompt）**

Claude CLIで synthesize エージェントをロードして実行する:

```bash
claude
```

実行時の宣言:
```
Task Type: synthesize
Loaded Agents: synthesize.md, page_policy.md, naming.md
Execution Plan: raw/papers/sindy-tutorial.md を review/synthesis_candidates/ に変換する
```

出力先は `review/synthesis_candidates/` のみ。`wiki/` には直接書かない。

**ステップ4: approve**

`review/synthesis_candidates/` の候補ファイルを人間がレビューし、frontmatterを更新する:

```yaml
status: approved
reviewed_by: alice
approved: 2026-04-17
```

承認後に実行:

```bash
rw approve
```

`wiki/synthesis/` に昇格される。完了後、コミットを手動で実行:

```bash
git add review/synthesis_candidates/
git commit -m "approve: update promoted flag"

git add wiki/synthesis/ wiki/index.md wiki/log.md
git commit -m "approve: promote synthesis"
```

**ステップ5: audit（CLI Hybrid）**

CLIコマンドで wiki/ の整合性を監査する。4段階のティアを用途に応じて使い分ける:

```bash
rw audit micro      # 直近の更新ページを対象とした高速チェック（更新後に実行）
rw audit weekly     # 全ページの構造チェック（週次）
rw audit monthly    # LLM支援による意味的監査（月次）
rw audit quarterly  # LLM支援による戦略的監査（四半期）
```

audit はレポートのみ（`logs/` に出力）。`wiki/`・`raw/`・`review/` を変更しない。

---

## CLIコマンドリファレンス

### `rw init`

新しいVaultを初期化する。`templates/` の構成を新しいVaultディレクトリにコピーする。

```bash
rw init <vault-path>
```

**引数**: `vault-path` — 初期化先のディレクトリパス

**出力**: ディレクトリ構造・CLAUDE.md・AGENTS/ディレクトリが配置される

---

### `rw lint`

`raw/incoming/` のファイルを検証する。

```bash
rw lint
```

**引数**: なし

**出力**:
- `logs/lint_latest.json`（全ファイルの検証結果）
- 標準出力に各ファイルの判定（PASS / WARN / FAIL）
- 終了コード: 0（FAIL なし）/ 1（FAIL あり）

**例**:
```
[PASS] raw/incoming/articles/sindy-intro.md
[WARN] raw/incoming/papers/local/draft.md too short
[FAIL] raw/incoming/code-snippets/empty.md empty file

Summary: {'pass': 1, 'warn': 1, 'fail': 1}
Log: logs/lint_latest.json
```

---

### `rw lint query`

`review/query/` 配下のクエリアーティファクトを検証する。

```bash
rw lint query [query_id]
```

**引数**: `query_id`（省略時は全クエリを対象）

**出力**: 各クエリの検証結果（QLコードと詳細）

---

### `rw ingest`

lint済みファイルを `raw/incoming/` から `raw/` へ移動する。

```bash
rw ingest
```

**前提条件**: `rw lint` が実行済みで FAIL == 0 であること

**出力**:
- 各ファイルの移動状況
- 完了後に自動コミット（`ingest: batch import`）

---

### `rw synthesize-logs`

`raw/llm_logs/` のLLMインタラクションログからsynthesis候補を生成する。

```bash
rw synthesize-logs
```

**前提条件**: `raw/llm_logs/` にコミット済みのログファイルが存在すること

**出力**: `review/synthesis_candidates/` にsynthesis候補ファイルを生成

**注**: CLIは自動コミットしない。完了後に手動でコミットすること:
```bash
git add review/synthesis_candidates/
git commit -m "synthesize-logs: generate candidates"
```

---

### `rw approve`

承認済みの synthesis 候補を `wiki/synthesis/` へ昇格させる。

```bash
rw approve
```

**前提条件**: `review/synthesis_candidates/` に以下の全フィールドを持つファイルが存在すること:
- `status: approved`
- `reviewed_by: <非空の文字列>`
- `approved: YYYY-MM-DD`
- `promoted` が `"true"` でない

**出力**:
- `wiki/synthesis/` への昇格（新規作成またはマージ）
- 候補ファイルの `promoted: true` フラグ更新

**注**: CLIは自動コミットしない。完了後に以下の順序でコミットすること:
```bash
git add review/synthesis_candidates/
git commit -m "approve: update promoted flag"

git add wiki/synthesis/ wiki/index.md wiki/log.md
git commit -m "approve: promote synthesis"
```

---

### `rw query`

wiki 知識に対するクエリ操作を行う。

#### `rw query extract`

```
rw query extract "<質問文>" [--scope <wikiページパス>] [--type <クエリタイプ>]
```

wiki 知識から構造化されたクエリアーティファクトを抽出し `review/query/<query_id>/` に4ファイルを生成する。実行後に自動で lint 検証が行われる。

**引数**:
- `<質問文>` (必須): 抽出したい知識に関する質問
- `--scope <パス>` (省略可): 参照する wiki ページを限定する
- `--type <タイプ>` (省略可): クエリタイプ (`fact` / `structure` / `comparison` / `why` / `hypothesis`)

**出力例**:
```
review/query/20260417-example-question/question.md
review/query/20260417-example-question/answer.md
review/query/20260417-example-question/evidence.md
review/query/20260417-example-question/metadata.json
Lint Result: PASS
```

**終了コード**: 0（成功・lint PASS）/ 1（入力エラー）/ 2（生成成功・lint FAIL）

---

##### 4 ファイル契約 — それぞれの役割

`rw query extract` は**必ず 4 ファイルをセットで生成**します。4 つは独立した役割を持ち、組み合わせることで「エビデンスに裏付けられた再利用可能な知識アーティファクト」を構成します。

**① `question.md` — 問いの記録**

何をクエリしたかを記録する。フィールド:
- `query`: クエリ本文
- `query_type`: `fact` / `structure` / `comparison` / `why` / `hypothesis`
- `scope`: 対象スコープ（wiki のどこを参照したか）
- `date`: YYYY-MM-DD

👉 **後から「何を問うたか」を再現できる**。同じクエリの再実行・検索条件としての再利用が可能。

**② `answer.md` — 構造化された回答**

エビデンスに基づく回答本体。見出し・箇条書きで構造化される。

- 推論・解釈・クロスページ横断を含む場合は `[INFERENCE]` マーカーで明示
- 「前述」「これ」等の文脈依存表現は禁止（単独で読める自己完結性）

👉 **論文の「結論・考察」に相当**。レビュー論文のドラフトや説明資料の素材として直接使える。

**③ `evidence.md` — 根拠となる wiki 抜粋**

回答を支える wiki からの引用集。各ブロックに以下を含む:
- `source:` フィールド（どの wiki ページから引用したか）
- 最小十分な抜粋（関連箇所のみ、バルクダンプ禁止）

👉 **論文の「引用・参考文献」に相当**。**ハルシネーション防止の要**。`answer.md` の各主張が本当に wiki に書かれていたかを検証できる。

**④ `metadata.json` — プログラム処理用インデックス**

機械処理のための構造化メタデータ:
- `query_id`: 識別子（`YYYYMMDD-slug` 形式）
- `query_type`, `scope`: 上記と同じ
- `sources`: 参照した wiki ページのリスト
- `created_at`: ISO 8601 タイムスタンプ
- `synthesis_candidate`（任意）: `true` なら synthesis への昇格候補

👉 **`rw lint query` の検証、synthesis 候補の自動抽出、audit での参照元追跡**に使われる。

##### 設計思想：なぜ 4 ファイル分離なのか

```
question.md    ← "何を問うたか"
    ↓
evidence.md    ← wiki からの生引用（source 付き）
    ↓
answer.md      ← evidence を構造化、推論は [INFERENCE] 明示
    ↓
metadata.json  ← 全体のインデックスと分類
```

3 つの原則：

1. **Fact-Evidence 分離**: 「回答」と「根拠」を別ファイルにすることで、`rw lint query` が「answer の各主張は本当に evidence に裏付けられているか？」を機械検証できる。
2. **Reusability First**: 4 ファイルだけで自己完結。チャット履歴や文脈を知らなくても、後から読んで理解・再利用できる。
3. **Trust Chain**: `wiki → evidence → answer` の信頼の連鎖。すべての主張の根拠を wiki まで辿れ、推論部分は `[INFERENCE]` で区別される。

##### 具体例：SINDy と Koopman 演算子の比較

```bash
rw query extract "SINDy と Koopman 演算子の違い" --type comparison
```

生成される 4 ファイル:

```
review/query/20260421-sindy-koopman-difference/
├── question.md      # "SINDy と Koopman..." / comparison / wiki/methods/ / 2026-04-21
├── answer.md        # 比較表、各セルに [INFERENCE] or エビデンス参照
├── evidence.md      # wiki/methods/sindy.md L23-30、wiki/methods/koopman.md L45-52
└── metadata.json    # query_id, sources: [sindy.md, koopman.md], synthesis_candidate: true
```

後日「レビュー論文の Related Work を書く」といった場面で：
- `answer.md` をそのまま下書きに使う
- `evidence.md` の `source:` を辿って元の wiki ページに戻る
- `metadata.json` の `sources` を citation リストの元にする

といった再利用が自然に行える。

---

#### `rw query answer`

```
rw query answer "<質問文>" [--scope <wikiページパス>]
```

wiki 知識に基づく直接回答を標準出力に表示する。アーティファクトファイルは生成しない。

**引数**:
- `<質問文>` (必須): 回答を得たい質問
- `--scope <パス>` (省略可): 参照する wiki ページを限定する

**stdout 出力例**:
```
SINDy（Sparse Identification of Nonlinear Dynamics）は非線形力学系の方程式を
スパース回帰によって同定する手法です。

## 詳細

計測データから支配方程式を自動抽出し、解釈可能な数式モデルを得ることができます。

---
Referenced: wiki/methods/sindy.md, wiki/concepts/sparse-regression.md
```

**終了コード**: 0（成功）/ 1（入力エラー）

---

#### `rw query fix`

```
rw query fix <query_id>
```

lint 結果に基づき、既存クエリアーティファクトの lint エラーを自動修復する。修復後に再 lint 検証を行う。

**引数**:
- `<query_id>` (必須): 修復対象のクエリID（`YYYYMMDD-slug` 形式）

**出力例**:
```
[FIX] answer.md: QL006 → expanded content
Skipped: QL009 (Cannot auto-fix source references)
Post-fix Lint Result: PASS
```

**終了コード**: 0（成功・post-fix lint PASS）/ 1（クエリ不在・入力エラー）/ 2（fix 実行・post-fix lint FAIL）

---

### `rw audit`

wiki/ の整合性・構造・完全性を4段階の監査サイクルで検証する。すべての audit は読み取り専用であり、`wiki/`・`raw/`・`review/` へのファイル書き込みを行わない。監査結果は `logs/` に Markdown レポートとして出力される。

サブコマンドなしで実行すると使用方法を表示する:

```bash
rw audit
```

**終了コード**: 0（ERROR なし）/ 1（ERROR あり）

---

#### `rw audit micro`

直近の更新ページを対象とした高速な静的チェック（Tier 0: Micro-check）。wiki 更新後に実行することを想定している。Claude CLI を使用せず Python のみで完結する。

```bash
rw audit micro
```

**引数**: なし

**スコープ**: git diff で検出された直近の更新ページのみ（全ページスキャンなし）

**チェック項目**:
- リンク切れ（`[[link]]` の参照先ページ不在）→ ERROR
- `index.md` への未登録ページ → WARN
- frontmatter の YAML パースエラー（パース不能な YAML）→ ERROR

**出力**:
- 標準出力: 各 Finding の severity 付き一覧とサマリー
- `logs/audit-micro-<YYYYMMDD-HHMMSS>.md`（Markdown レポート）

**出力例**:
```
[ERROR] concepts/my-page.md: [[nonexistent]] のリンク先が存在しない
[WARN] methods/sindy.md: index.md に未登録
---
audit micro: ERROR 1, WARN 1, INFO 0 — FAIL
レポート: logs/audit-micro-20260418-153000.md
```

**対象ページが 0 件の場合**（直近の wiki 更新なし）:
```
[INFO] チェック対象なし（直近の wiki 更新が検出されませんでした）
レポート: logs/audit-micro-20260418-153000.md
```

---

#### `rw audit weekly`

全ページを対象とした構造チェック（Tier 1: Structural Audit）。micro のスーパーセットであり、micro の全チェック項目に加えて構造的な問題も検出する。Claude CLI を使用せず Python のみで完結する。

```bash
rw audit weekly
```

**引数**: なし

**スコープ**: wiki/ 内の全ページ

**チェック項目**（micro のチェック項目を全ページに拡張して含む）:
- リンク切れ → ERROR
- `index.md` への未登録ページ → WARN
- frontmatter の YAML パースエラー → ERROR
- 孤立ページ（他ページからリンクされていない、index.md リンクを除く）→ WARN
- 双方向リンクの欠落 → WARN
- 命名規則違反（小文字・ハイフン区切り・ASCII のみ）→ WARN
- `source:` フィールドの空・欠落 → INFO

**出力**:
- 標準出力: 各 Finding の severity 付き一覧とサマリー
- `logs/audit-weekly-<YYYYMMDD-HHMMSS>.md`（Markdown レポート）

**出力例**:
```
[ERROR] concepts/broken-link.md: [[nonexistent-page]] のリンク先が存在しない
[WARN] methods/orphan-page.md: 他のページからリンクされていない
[WARN] methods/sindy.md: title フィールドが欠落
[INFO] entities/some-tool.md: source フィールドが空
---
audit weekly: ERROR 1, WARN 2, INFO 1 — FAIL
レポート: logs/audit-weekly-20260418-090000.md
```

---

#### `rw audit monthly`

LLM 支援による意味的監査（Tier 2: Semantic Audit）。Claude CLI を呼び出して wiki 内ページ間の矛盾・曖昧さを検出する。`AGENTS/audit.md` をプロンプトの正規ソースとして使用する。

```bash
rw audit monthly [--timeout <秒>]
```

**引数**:
- `--timeout <秒>`（省略可）: Claude CLI のタイムアウト秒数（デフォルト: 300）

**スコープ**: wiki/ 内の全ページ（LLM が分析）

**検出対象**:
- ページ間の定義の矛盾 → `[CONFLICT]` マーカー
- 緊張関係・不整合 → `[TENSION]` マーカー
- 曖昧な定義・解釈の揺れ → `[AMBIGUOUS]` マーカー

**severity（4 水準）**（詳細: [developer-guide.md §Severity Vocabulary](developer-guide.md#6-severity-vocabulary)）:

| Severity | 終了コードへの影響 |
|----------|-----------------|
| `CRITICAL` | FAIL（exit 2） |
| `ERROR` | FAIL（exit 2） |
| `WARN` | PASS に影響しない |
| `INFO` | PASS に影響しない |

**出力**:
- 標準出力: 処理中メッセージ・各 Finding の severity 付き一覧・サマリー
- `logs/audit-monthly-<YYYYMMDD-HHMMSS>.md`（Markdown レポート）
- `logs/audit-monthly-<YYYYMMDD-HHMMSS>-raw.txt`（Claude 生レスポンス、デバッグ用）

**出力例**:
```
[INFO] monthly 監査を実行中...
[ERROR] concepts/page-a.md: page-b.md と定義が矛盾している
[ERROR] projects/proj-x.md: status フィールドと Current Status セクションが不一致
[WARN] entities/person-y.md: 所属の記述が methods/method-z.md と異なる
---
audit monthly: ERROR 2, WARN 1, INFO 0 — FAIL
レポート: logs/audit-monthly-20260418-020000.md
```

---

#### `rw audit quarterly`

LLM 支援による戦略的監査（Tier 3: Strategic Audit）。Claude CLI を呼び出して wiki のグラフ構造の俯瞰・カバレッジギャップ・スキーマ改訂提案を行う。`AGENTS/audit.md` をプロンプトの正規ソースとして使用する。

```bash
rw audit quarterly [--timeout <秒>]
```

**引数**:
- `--timeout <秒>`（省略可）: Claude CLI のタイムアウト秒数（デフォルト: 300）

**スコープ**: wiki/ 内の全ページ（LLM が分析）

**検出・提案対象**:
- wiki グラフの孤立クラスター
- カバレッジギャップ（トピック・種別の偏り）
- スキーマ・構造の改訂提案

**出力**:
- 標準出力: 処理中メッセージ・各 Finding の severity 付き一覧・サマリー
- `logs/audit-quarterly-<YYYYMMDD-HHMMSS>.md`（Markdown レポート）
- `logs/audit-quarterly-<YYYYMMDD-HHMMSS>-raw.txt`（Claude 生レスポンス、デバッグ用）

**出力例**:
```
[INFO] quarterly 監査を実行中...
[WARN] methods/ 配下のページが concepts/ とほぼクロスリンクされていない
[INFO] synthesis ページが concepts に対して不足している（カバレッジ不足）
---
audit quarterly: ERROR 0, WARN 1, INFO 1 — PASS
レポート: logs/audit-quarterly-20260418-000000.md
```

---

## プロンプトレベルタスクの実行

### Claude CLIでのエージェントロード手順

1. Claude CLIを起動する
2. 実行宣言を行う（Task Type / Loaded Agents / Execution Plan）
3. 必要なエージェントファイルをReadツールでロードする
4. エージェントルールに従って実行する

### synthesize タスク

```
Task Type: synthesize
Loaded Agents: synthesize.md, page_policy.md, naming.md
Execution Plan: [対象ファイル] を review/synthesis_candidates/ に変換する
```

ロード:
```
Read("AGENTS/synthesize.md")
Read("AGENTS/page_policy.md")
Read("AGENTS/naming.md")
```

### query_extract タスク

```
Task Type: query_extract
Loaded Agents: query_extract.md, naming.md, page_policy.md
Execution Plan: query_id: 20260417-sindy-dimensionality でクエリアーティファクトを生成する
```

出力先: `review/query/<query_id>/` 配下の4ファイル（question.md / answer.md / evidence.md / metadata.json）

### query_answer タスク

```
Task Type: query_answer
Loaded Agents: query_answer.md, page_policy.md
Execution Plan: [質問内容]
```

wiki知識に基づいた直接回答を返す。アーティファクトは生成しない。

### query_fix タスク

```
Task Type: query_fix
Loaded Agents: query_fix.md, naming.md
Execution Plan: query_id: 20260417-sindy-dimensionality の lint エラーを修復する
```

lint結果（QLコード）を提供した上で実行する。

### audit タスク

audit コマンドは CLI で実行する（「CLIコマンドリファレンス」の `rw audit` セクションを参照）。

```bash
rw audit micro      # Tier 0: 直近の更新ページを対象とした高速チェック
rw audit weekly     # Tier 1: 全ページの構造チェック
rw audit monthly    # Tier 2: LLM支援による意味的監査
rw audit quarterly  # Tier 3: LLM支援による戦略的監査
```

---

## システム更新時の運用

Rwiki のシステム（dev リポジトリ）が更新されても、**Vault の知識データ（`raw/` / `review/` / `wiki/` / `index.md` / `log.md`）は一切影響を受けません**。更新の種類に応じて、必要な操作は異なります。

### Vault とシステムの依存関係

| Vault 側の要素 | 更新方式 |
|---------------|---------|
| `raw/` / `review/` / `wiki/` / `index.md` / `log.md` | ユーザー所有。システム更新で一切触らない |
| `scripts/rw` シンボリックリンク | dev リポジトリのコードへの参照。`git pull` で自動追従 |
| `CLAUDE.md` / `AGENTS/` | init 時のスナップショット。明示的な re-sync が必要 |

### シナリオ別の手順

**① CLI の機能追加・バグ修正（コードのみ変更）**

```bash
cd ~/Rwiki-dev
git pull
```

これだけで完了。symlink 経由で新しいコードが即反映される。Vault 側の操作は不要。

**② `templates/CLAUDE.md` や `templates/AGENTS/` の更新**

```bash
cd ~/Rwiki-dev
git pull
python scripts/rw_cli.py init ~/my-vault
```

既存 Vault に対して `rw init` を再実行すると:

- 上書き確認のプロンプトが表示される（`y` で承認）
- 旧 `CLAUDE.md` を `CLAUDE.md.bak` にバックアップ
- 旧 `AGENTS/` を `AGENTS.bak/` にバックアップ
- 新しい template をコピー
- **`raw/` / `review/` / `wiki/` には一切触らない**

確認をスキップする場合（タイムスタンプ付きバックアップ）:

```bash
python scripts/rw_cli.py init ~/my-vault --force
# 旧 AGENTS/ は <vault>/.backup/<timestamp>/ に退避される
```

**③ エントリポイントのファイル名変更（例: rw-light-rename）**

```bash
python scripts/rw_cli.py init ~/my-vault --reinstall-symlink
```

symlink のみを張り替え、他のファイル・ディレクトリには一切触らない。通常初期化処理（ディレクトリ生成・template コピー・git init）はスキップされる。

**④ スキーマ・フォーマットの破壊的変更**（今後の検討課題）

frontmatter のフィールド変更・JSON ログの schema バージョンアップ・severity 体系の変更など、既存データに影響する変更については、**現時点では共通のマイグレーションフレームワークは未整備**です。これまでは個別のスペックで対応してきました:

- `severity-unification`（2026-04-20 完了）: AGENTS ファイルの severity 語彙 rename（HIGH→ERROR 等）と CLI の exit code 契約統一。既存 JSON ログとの互換性を考慮した設計を実施。
- `rw-light-rename`（2026-04-21 完了）: エントリポイントのファイル名変更に伴う Vault symlink 張り替え手段として `--reinstall-symlink` を追加。

将来的に必要になりうる共通基盤:

- `rw migrate <from-version> <to-version>` のような専用コマンド
- Vault 側の state version（`.rw-version` ファイル等）による自動マイグレーション検出
- 破壊的変更を伴うスペックでの「マイグレーションガイド」標準フォーマット

該当する変更が発生した場合は、**`CHANGELOG.md` と該当スペックの `requirements.md` に移行手順を明記する**運用とします。

### 共通原則

どのシナリオでも **ユーザーの知識データ（`raw/` / `review/` / `wiki/` / `index.md` / `log.md`）は触らない**。これは Rwiki の Safety Guardrails（LLM が `raw/` と `wiki/` を直接変更できない設計）と同じ思想で、システム更新もユーザーデータを守る設計になっています。

---

## 知識フロー図

```
raw/incoming/          (未検証入力)
    ↓ rw lint
    ↓ rw ingest
raw/                   (検証済みソース・READ ONLY)
    ↓ synthesize (Prompt)
    ↓ synthesize-logs (CLI)
review/                (レビュー・ステージング層)
    ↓ [human review & approval]
    ↓ rw approve (CLI)
wiki/                  (キュレーション済み知識層)
```
