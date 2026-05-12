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
