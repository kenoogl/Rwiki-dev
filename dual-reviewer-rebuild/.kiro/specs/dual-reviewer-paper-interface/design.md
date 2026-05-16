# Design Document

## Overview

`dual-reviewer-paper-interface` は、evaluation が生成した analysis artifact を paper-facing artifact に変換する reporting interface layer である。

本 design の役割は、次を concrete に定義することにある。

- claim と evidence source の対応付け
- figure / table / report fragment の入力 contract
- caveat と maturity label の継承方法
- paper convenience が lower layer に逆流しない境界

この feature は manuscript authoring そのものではなく、論文化や研究報告に必要な structured reporting input を整えるための層である。

## Goals

- claim-supporting artifact を traceable にする
- mature / preliminary / exploratory を見分けられる reporting input を作る
- exclusion と caveat を narrative から脱落させない
- evaluation output から再生成可能な paper-facing artifact を作る

## Non-Goals

- runtime field の再定義
- evaluation metric rule の変更
- full manuscript drafting pipeline の実装
- submission packaging

## Design Drivers

- paper convenience は reproducibility と validity に従属する
- raw run artifact を直接読まない。evaluation output を読む。evaluation output が存在しない場合は生ログにフォールバックせず、評価プロセスの実行を要求する（要件 1 受入 4）
- claim は evidence source と provenance を失わない
- preliminary evidence は明示的に label する

## Architecture

paper-interface は `claim mapping -> reporting bundle generation -> caveat attachment -> export fragments` の 4 段に分ける。

```mermaid
graph TD
    Eval["experiments/analysis/"] --> ClaimMap["claim mapper"]
    ClaimMap --> Bundle["reporting bundle builder"]
    Bundle --> Caveat["caveat / maturity annotator"]
    Caveat --> Export["paper-facing fragments"]
    Export --> Paper["paper/"]
```

### Components

- `claim mapper`
  - claim ごとに supporting artifact を結びつける
- `reporting bundle builder`
  - figure / table / summary 用の bundle を作る
- `caveat / maturity annotator`
  - preliminary / mature / caveated を明示する
- `export fragments`
  - reporting に使う JSON / Markdown / table input を出す

## Paper Artifact Layout

paper-interface の正本出力先は `paper/` 配下とする。

```text
paper/
├── reports/
│   ├── claim_map.json
│   ├── evidence_register.json
│   └── reporting_fragments.json
├── tables/
│   └── table_source_bundle.json
├── figures/
│   └── figure_source_bundle.json
└── caveats/
    └── paper_caveat_register.json
```

### Placement Rationale

- `reports/claim_map.json`
  - claim と evidence の対応正本
- `reports/evidence_register.json`
  - evidence maturity と provenance の registry
- `reports/reporting_fragments.json`
  - text-ready だが manuscript 非依存の summary fragment
- `tables/` と `figures/`
  - table / figure の source bundle を分ける
- `caveats/`
  - paper-facing caveat の集約場所

## Claim Mapping Model

### 1. Claim Unit

paper-interface は claim を 1 artifact 単位で扱う。

claim とは、claim-to-evidence 対応付けの単位となる paper-facing な言明であり、最低限 identifier と明示的な evidence source への結合を持つ（要件 1 受入 6）。

`claim_map.json` の各 entry は少なくとも次を持つ。

- `claim_id`
- `claim_text`
- `supporting_artifact_refs`
- `maturity_label`
- `caveat_refs`
- `provenance_refs`

claim-to-evidence と caveat linkage は文字列 heuristic ではなく構造化参照で扱う。
artifact-specific caveat の canonical source は claim entry が持つ `supporting_artifact_refs` と `caveat_refs` とし、
basename や filename の部分一致を正本判定に使ってはならない。

### 2. Supporting Artifact Sources

標準的な source は次に限定する。

- `comparisons/treatment_comparisons.json`
- `comparisons/phase_comparisons.json`
- `classifications/exclusion_report.json`
- `caveats/caveat_register.json`
- 必要に応じて `metrics/*.json`

runtime raw artifact は claim-supporting source の一次入力にしない。

## Evidence Register Model

### 1. Evidence Maturity

evidence maturity の初版 label は次とする。

- `mature`
- `preliminary`
- `exploratory`

`caveated` は maturity label ではなく、`caveat_refs` によって表現する。これにより、1 artifact が `mature` でありつつ caveat を持つ状態を表現できる。

この maturity 語彙は paper-interface 独自に再定義せず、foundation の正準 evidence-class（要件 6 受入 8）に結合する。要件 1・3・5 をまたいで単一の統一語彙を用いる（要件 5 受入 6）。

### 2. Provenance Fields

`evidence_register.json` の各 entry は少なくとも次を持つ。

- `artifact_ref`
- `source_analysis_manifest_ref`
- `input_run_set_ref`
- `maturity_label`
- `caveat_refs`
- `generated_at`

これにより、どの analysis logic version と run set から報告断片ができたか追跡できる。

## Figure and Table Bundle Model

### 1. Table Source Bundle

`tables/table_source_bundle.json` は少なくとも次を持つ。

- `table_id`
- `source_artifact_refs`
- `field_projection`
- `maturity_label`
- `caveat_refs`

### 2. Figure Source Bundle

`figures/figure_source_bundle.json` は少なくとも次を持つ。

- `figure_id`
- `source_artifact_refs`
- `plot_contract`
- `maturity_label`
- `caveat_refs`

ここで `plot_contract` は描画そのものではなく、どの slice / metric / grouping を使うかの reporting-side definition とする。

## Caveat and Limitation Model

paper-interface は evaluation の `caveat_register.json` を継承しつつ、paper-facing な説明単位へ再配置する。

`paper/caveats/paper_caveat_register.json` は少なくとも次を持つ。

- `caveat_id`
- `source_caveat_ref`
- `applies_to_claim_refs`
- `applies_to_artifact_refs`
- `limitation_type`
- `narrative_note`

`narrative_note` は manuscript 本文ではなく、author が limitations を落とさないための structured note とする。

## Reporting Fragment Model

`reporting_fragments.json` は論文本文そのものではないが、再利用しやすい報告断片を保持する。

各 fragment は少なくとも次を持つ。

- `fragment_id`
- `fragment_type`
- `source_artifact_refs`
- `maturity_label`
- `caveat_refs`
- `text_stub`

`fragment_type` の例:

- `claim_summary`
- `method_note`
- `limitation_note`
- `comparison_summary`

## Separation Rules

### 1. No Reverse Control

paper-interface は次をしてはいけない。

- runtime field の追加要求を独自に出す
- invalid run を valid evidence に格上げする
- evaluation comparison rule を独自に上書きする

### 2. No Silent Strengthening

preliminary または exploratory な evidence を、paper artifact 生成時に mature evidence と同列に扱ってはいけない。

### 3. Self-Improvement Independence

self-improvement proposal は paper claim の support artifact ではない。採用済み改善履歴を methodology note として参照することはできるが、performance claim の一次根拠にはしない。

### 4. Stale Upstream Regeneration

上流 evaluation output が run 無効化により stale 扱いされた場合、paper-facing artifact は再生成の対象とする。出力が変化したときだけでなく、上流の陳腐化時にも再生成する（要件 2 受入 6）。

## Interfaces to Other Features

### Evaluation

paper-interface は evaluation の主要 consumer である。少なくとも次を読む。

- `analysis_run_manifest.yaml`
- `treatment_comparisons.json`
- `phase_comparisons.json`
- `exclusion_report.json`
- `caveat_register.json`

必要なら、`analysis_run_manifest.yaml` の `input_run_set` に対応する protocol-facing validation summary を provenance convenience として追加 intake してよい。対象は `runtime_validation_summary.yaml` または `conformance_review_result.yaml` のような upstream が既に生成した summary artifact に限る。

### Self-Improvement

paper-interface は self-improvement の adopted history を、必要なら「system revision history」として参照できる。ただし runtime quality claim の一次根拠にしない。

### Runtime

runtime とは直接結合しない。runtime は paper-interface の field convenience のために artifact shape を変えない。

paper-interface が参照できる runtime 由来情報は、evaluation や protocol layer が既に versioned artifact として固定した summary に限る。これらは methodology/provenance context であり、claim-supporting primary evidence にはしない。

## Key Decisions

### Decision 1: Claim map is the paper-facing center

どの claim がどの evidence で支えられるかを central artifact にする。

### Decision 2: Maturity is explicit

preliminary / exploratory / caveated を artifact に埋め込む。

### Decision 3: Reporting fragments are not manuscripts

再利用可能な断片までに留め、執筆工程そのものは別にする。

### Decision 4: Evaluation remains the upstream authority

paper-interface は consumer であり、comparison rule の owner ではない。

## Requirements Traceability

| Requirement | Design Response |
|------------|-----------------|
| Claim-to-evidence mapping | `claim_map.json` と evidence register を定義 |
| Paper-facing data contract | figure/table/report bundle を定義 |
| Caveat and limitation tracking | paper-facing caveat register を定義 |
| Separation from runtime and evaluation logic | no reverse control rules を定義 |
| Preliminary vs mature evidence distinction | maturity labels と no silent strengthening rule を定義 |

## Open Issues for Design Alignment Gate

- claim ID taxonomy をどこまで formalize するか
- figure/table bundle の field naming を evaluation とどこまで揃えるか
- adopted change history を methodology note に含める範囲

## Completion Criteria

- claim と evidence source の対応を説明できる
- mature / preliminary / exploratory の扱いを説明できる
- caveat がどこに残るか説明できる
- paper-interface が runtime/evaluation を支配しないことを説明できる
