# Manual Review Records

## 1. この文書の役割

この directory は、`dual-reviewer` 方法論を本 repo 自身へ手動適用した review 記録の正本置き場である。

初期段階では自動記録の仕組みがないため、manual review の session 条件、findings、summary をここに保存する。

ここに保存される evidence は、現段階では `manual single-review dogfooding baseline` として扱う。

理由:

- reviewer と handback 実行主体が実質的に同一である
- 独立した 2 reviewer の分離出力を持たない
- runtime が生成する `single / dual / dual+judgment` evidence とは topology が異なる

したがって、この directory の evidence は method-validation と初期 baseline のための記録であり、将来の runtime-mediated comparison population と同列に扱わない。

## 2. Directory Layout

```text
reviews/manual/
├── README.md
├── manual_review_metrics_summary.json
├── manual_review_metrics_summary.md
├── templates/
│   ├── review_session_manifest.yaml
│   ├── finding_register.json
│   └── review_summary.yaml
└── sessions/
    └── <review_session_id>/
        ├── review_session_manifest.yaml
        ├── finding_register.json
        └── review_summary.yaml
```

## 3. Canonical Files

### `review_session_manifest.yaml`

session 単位の条件と対象を記録する正本。

最低限含めるもの:

- `review_session_id`
- `review_mode`
- `reviewed_feature`
- `reviewed_spec_phase`
- `reviewed_phase_profile`
- `review_basis`
- `review_question_set`
- `target_paths`
- `target_version_refs`
- `reviewer`
- `review_started_at`
- `review_closed_at`

### `finding_register.json`

finding 単位の structured record を保持する正本。

最低限含めるもの:

- `finding_id`
- `severity`
- `category`
- `summary`
- `rationale`
- `affected_refs`
- `suggested_action`
- `decision_status`
- `fix_linkage`
- `reopen_linkage`
- `alignment_impact`

### `review_summary.yaml`

session 終了時点の sign-off と未解決事項を保持する正本。

最低限含めるもの:

- `review_session_id`
- `signoff_status`
- `reopen_required`
- `downstream_recheck_required`
- `unresolved_concerns`
- `finding_counts`

## 4. Recording Rules

- 1 review session につき 1 directory を作る
- session directory 名は `review_session_id` と一致させる
- finding は free-form memo だけにしない
- sign-off 前でも manifest と finding register は先に作成してよい
- summary は session close 時に確定する
- `category` はできるだけ固定語彙を使う
- repo 内 artifact への参照は原則として repo root 基準の相対パスで記録する
- 絶対パスは chat 上の案内には使ってよいが、record の正本には使わない
- section 名、field 名、spec phase などはその時点の正本表記に合わせる

### 4.2 Review Flow Rule

manual review record は、review が `intent -> requirements -> design -> tasks` と段階的に流れることを前提に作成する。

原則:

- review session は上流 stage から下流 stage へ進める
- 同じ stage 内では feature を水平展開して review する
- 上流 stage に修正が入った場合、下流 stage の review record は必要に応じて再確認対象とする
- review wave の finding を反映して同じ stage の文書が変わった場合、次 stage の review に進む前に当該 stage の alignment recheck を行う

記録時の注意:

- `reviewed_spec_phase` は現在どの review stage かを表す
- `reviewed_feature` は stage 内での対象 feature を表す
- repo-wide な review wave では `reviewed_feature: repo-wide` を使ってよい
- downstream recheck が必要な場合は `review_summary.yaml` に明示する

### 4.1 Path Recording Rule

manual review record に含める path は、原則として `dual-reviewer-rebuild` repo root からの相対パスとする。

例:

- `intent/INTENT.md`
- `operations/HUMAN_WORKFLOW.md`
- `.kiro/specs/dual-reviewer-foundation/requirements.md`
- `docs/alignment/cross-spec-requirements-alignment.md`

避けるもの:

- `/Users/...` のような絶対パス
- `../` を多用した session directory 基準の相対パス

理由:

- repo 移動や複製後も壊れにくい
- 他環境でも再利用しやすい
- 後の metric 抽出や script 処理で扱いやすい

## 4.5 Recommended Category Taxonomy

初期の manual review では、少なくとも次の category 語彙を推奨する。

- `ambiguity`
- `contradiction`
- `missing_requirement`
- `missing_design_detail`
- `boundary_error`
- `traceability_gap`
- `metric_gap`
- `alignment_gap`
- `workflow_gap`
- `naming_inconsistency`

新しい category を使う場合は、必要に応じて本 README に追加する。

## 5. Metric Extraction Readiness

この format から後で少なくとも次を抽出できる。

- phase 別 finding 数
- severity 分布
- category 分布
- accepted / rejected / deferred 比率
- reopen 発生率
- unresolved concern 数

本 directory は manual review 記録の正本であり、後続の evaluation や self-improvement の入力候補となる。

ただし、ここから抽出される metric は baseline / process evidence として読むべきであり、runtime-mediated review quality の直接指標とはみなさない。

## 6. Aggregated Summary Artifacts

manual review session から抽出した集計結果は次に置く。

- `manual_review_metrics_summary.json`
  - machine-readable aggregate
- `manual_review_metrics_summary.md`
  - human-readable summary

これらは `sessions/` 配下の session record から導かれる派生 artifact であり、manual review 記録そのものの正本ではない。
