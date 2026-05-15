# CONVENTIONS

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` 全体で共有する運用・用語・命名の共通規約を定義する。

目的:

- status の正本を一元化する
- `phase` という語の使い分けを固定する
- artifact 命名規則を先に固定して、implementation 時の drift を防ぐ

## 2. Canonical Status Source

進行状態の正本は各 feature の `spec.json` とする。

意味:

- phase の現在地
- approvals の状態
- reopen 状態
- alignment 状態
- traceability 更新要否

は `spec.json` を基準に判断する。

他文書の扱い:

- `DOCUMENT_INDEX.md`
  - 説明用の overview として status を書いてよい
  - ただし正本ではない
- `docs/alignment/cross-spec-*.md`
  - alignment 実施ログとして status を書いてよい
  - ただし feature の現在状態を確定する正本ではない
- `README.md`
  - 入口レベルの概況のみを書く

ルール:

- status が変わった場合、まず `spec.json` を更新する
- 他文書への反映は `spec.json` に従属する
- 他文書と `spec.json` が矛盾した場合は `spec.json` を優先する

## 3. Phase Terminology

本 repo では `phase` という語を次の 3 種に分けて使う。

### 3.1 spec phase

意図駆動ワークフローの開発段階を指す。

対象:

- `requirements`
- `design`
- `tasks`
- `implementation`

### 3.2 review phase/profile

`dual-reviewer` が review 対象として扱う開発内容の位相を指す。

対象:

- `intent`
- `requirements`
- `design`
- `tasks`
- `implementation-oriented review` (future)

### 3.3 run status

個々の review session の lifecycle 状態を指す。

対象例:

- `created`
- `in_progress`
- `closed`
- `orchestration_failed`

ルール:

- `phase` とだけ書くのを避け、必要に応じて `spec phase` / `review phase` / `run status` と明記する
- `evidence_class` は phase ではなく downstream consumption 区分として扱う

## 4. Artifact Naming Conventions

artifact 名は役割ごとに suffix を固定する。

### 4.1 manifest

`*_manifest`

用途:

- ある処理単位の実行条件やバージョン情報の記録

例:

- `run_manifest.yaml`
- `analysis_run_manifest.yaml`

### 4.2 index

`*_index`

用途:

- 同種 artifact 群の一覧や lookup

例:

- `run_classification_index.json`
- `proposal_index.json`
- `backtest_index.json`

### 4.3 register

`*_register`

用途:

- caveat、evidence、adoption、rollback など累積管理台帳

例:

- `caveat_register.json`
- `evidence_register.json`
- `adoption_register.json`
- `rollback_register.json`
- `finding_register.json`

### 4.4 result

`*_result`

用途:

- 単一処理または単一 validator 実行の結果

例:

- `validator_result.json`

### 4.5 summary

`*_summary`

用途:

- raw evidence ではない convenience 要約

例:

- `runtime_summary.json`

ルール:

- `summary` を正本入力にしない
- `result` と `summary` を混同しない
- `register` は履歴・台帳、`index` は参照一覧として使い分ける

## 5. Deferred and Gap Terminology

traceability や planning では次を区別する。

- `deferred`
  - 意図的に今回のスコープ外へ送ったもの
- `gap`
  - 本来必要だが現時点で未対応のもの

## 6. 運用メモ

- 新しい artifact 種別を導入する場合は、本書に naming rule を追記する
- `spec phase` / `review phase` / `run status` のどれにも当てはまらない新しい phase-like 概念を導入する場合は、本書で先に定義する
- status 表現を他文書に追加する場合は、`spec.json` を正本とする旨を崩さない
- implementation handback は `task-local adjustment` / `design handback` / `requirements handback` の 3 区分で扱う

## 7. 日本語用語の整理

日本語文書では「仕様」という語が「フィーチャー全体」と「要件フェーズの文書」の両方に使われがちで、混乱を招く。本書では次のように整理する。

### 7.1 フィーチャーとフェーズ

- **フィーチャー（feature）**：開発対象として独立した一つの機能単位。`spec.json` を持つ各単位
- **フェーズ**：フィーチャーが通過する開発段階（要件 → 設計 → タスク → 実装）
- **要件書（requirements.md）/ 設計書（design.md）/ タスク表（tasks.md）**：各フェーズの文書

例：「複数のフィーチャーが要件フェーズを完走したあと、横断レビューを行う」

### 7.2 「仕様」の単独使用を避ける

「仕様」という語は曖昧になりやすいため、文書では単独使用を避ける。代わりに次のいずれかを使う。

- フィーチャー全体を指すとき → 「フィーチャー」
- 要件フェーズの文書を指すとき → 「要件書」
- 要件フェーズのレビューを指すとき → 「要件レビュー」
- 要件フェーズの規律を指すとき → 「要件」

例の置き換え：

- 「上流仕様」→「上流フィーチャー」
- 「下位仕様」→「下位フィーチャー」
- 「仕様レビュー」→「要件レビュー」
- 「仕様改版」→「要件書の改版」

### 7.3 英語の固有用語

`spec.json` と `spec phase` は英語の固有用語としてそのまま用いる。日本語文書中で参照する際は文脈で明確にする（例：「フィーチャーのメタデータファイル `spec.json`」「フィーチャーのフェーズ（spec phase）」）。

## 8. レビュー 3 役の用語定義

`dual-reviewer` 手法のレビューは、レビュー作業を 3 つの役に分業して実行する。本書では各役の名称と責務をここで定義し、用語の正本とする。各役の手続きの詳細（判定の観点と条件、波及精査の手順、5 ラウンド構成など）は `operations/REVIEW_PROTOCOL.md` を正本とする。

### 8.1 主役（primary）

- レビュー対象の一次検出を担う役
- 検査軸に従って所見（finding）を網羅的に列挙する
- 「不備を見落とさない」方向に最適化されており、検出を採用する側に偏る傾向を持つ

### 8.2 敵対役（adversarial）

- 主役の出力を入力として独立に検証する役
- 主役が見落とした所見を「独立発見」として補う
- 主役所見の修正動機に対して「反論」を試問する
- 出力は「反論」と「独立発見」の 2 パートで構成する

### 8.3 判定役（judgment）

- 主役と敵対役の両方の出力を入力として、各所見の必要性を独立に判定する役
- 「修正必須 / 必要に応じて / 修正不要」の三段ラベルに分類する
- 主役の過剰修正偏りを抑える独立判定の装置として位置づける

### 8.4 通信構造

3 役は β 逐次方式で結合する。主役 → 敵対役 → 判定役の順に直列で実行し、各役は前段の出力を明示的に入力として受け取る。各役は独立した呼び出し（会話履歴を共有しないセッション）で動作させる。メインの応答主体は 3 役のいずれにもならない。

### 8.5 用語の統一

- 「判定役」を正本とする。文書中で「判断役」と書かれている箇所は、見つけ次第「判定役」に統一する。
- 用語の揺れが発生した場合、本書節 8 を根拠として修正する。
