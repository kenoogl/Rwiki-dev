# Cross-Spec Requirements Alignment: Generic Execution Layer v2

_作成日: 2026-05-10_  
_対象: `dual-reviewer-generic-execution-layer-v2` requirements alignment_

## 1. 目的

この文書は、`dual-reviewer-generic-execution-layer-v2` の requirements について、
workflow が要求する feature 間調整を記録するための alignment artifact である。

この文書では次を固定する。

- `foundation`
- `runtime`
- `evaluation`
- `self-improvement`
- `paper-interface`

に対して、

- shared metadata contract
- invalidation rule
- prompt / schema / artifact dependency
- responsibility boundary

の 4 観点で requirements-phase の整合を確認し、
この feature 内で吸収する事項と handback / follow-on を分離する。

## 2. 参照正本

- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-generic-execution-layer-v2/requirements.md:1)
- [ACTIVE_WORKLIST.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md:1)
- [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1)
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:215)
- [metadata_contract.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/foundation/metadata_contract.yaml:1)
- [dual-reviewer-foundation requirements](/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-foundation/requirements.md:1)
- [dual-reviewer-runtime requirements](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-runtime/requirements.md:1)
- [dual-reviewer-evaluation requirements](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-evaluation/requirements.md:1)
- [dual-reviewer-self-improvement requirements](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-self-improvement/requirements.md:1)
- [dual-reviewer-paper-interface requirements](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-paper-interface/requirements.md:1)

## 3. Alignment Result Summary

| target | result | disposition | note |
|---|---|---|---|
| `foundation` | aligned with conditions | follow-on / possible handback | shared metadata は現状維持。新しい shared schema / vocabulary を design で定義する場合は foundation handback 必須 |
| `runtime` | aligned | absorbed in this feature | v2 redesign の主 ownership はこの feature に置く。legacy runtime spec は requirements-phase 正本にしない |
| `evaluation` | aligned with design follow-on | follow-on | intake / admission / comparison へ渡す derived artifact shape は design で具体化する |
| `self-improvement` | aligned with design follow-on | follow-on | signal/proposal intake に必要な provenance と admission status は維持。signal object mapping は design で具体化する |
| `paper-interface` | aligned with boundary constraint | follow-on | paper-facing input は evaluation 経由を維持。paper convenience による runtime 逆流は禁止 |

requirements-phase の blocking 級矛盾は見つからなかった。

## 4. Category Check

### 4.1 Shared Metadata Contract

確認結果:

- v2 requirements は `target_id`, `target_artifact_hash`, `source_repository_id`, `source_revision`, `treatment`, `review_mode` を共通 execution contract に保持する
- したがって、現行 `foundation` metadata contract と requirements-phase で衝突しない
- `evaluation`, `self-improvement`, `paper-interface` が依存する provenance も requirements 上は維持される

判定:

- requirements-phase では `absorbed`
- ただし taxonomy-first redesign に伴い shared metadata field, shared schema shape, shared controlled vocabulary を変更する場合は `foundation handback required`

### 4.2 Invalidation Rule

確認結果:

- v2 requirements は `valid / invalid / comparison-ineligible` 条件への影響確認を gate 項目に含めた
- ただし requirements 自体は invalidation policy を変更していない
- `evaluation` が admission / exclusion の downstream owner、`paper-interface` はその結果 consumer、`self-improvement` は admission status を保持する consumer である

判定:

- requirements-phase では `aligned`
- invalidation semantics の変更は今回の requirements には含めず、もし design で変更が必要になれば reopen 対象とする

### 4.3 Prompt / Schema / Artifact Dependency

確認結果:

- `runtime` は foundation-owned schema / metadata contract を引き続き import する
- `evaluation` は runtime-produced evidence と derived artifact を intake する
- `self-improvement` は evaluation output と runtime provenance を proposal input として使う
- `paper-interface` は evaluation output を paper-facing source として扱い、runtime raw artifact を標準入力にしない

判定:

- requirements-phase では `aligned with design follow-on`
- exact artifact shape は design で固定する

design で固定すべき論点:

- `review_artifact`, `metric_snapshot`, `run_manifest`, `trace_note`, `signal_linkage_note` の placement
- taxonomy-first object をどの schema owner が持つか
- `signal_candidate` から self-improvement proposal intake へ渡す mapping
- evaluation output から paper-facing fragment へ渡す field contract

### 4.4 Responsibility Boundary

確認結果:

- `dual-reviewer-generic-execution-layer-v2` は runtime-centered redesign の primary owner とする
- `foundation` は shared contract owner のまま据え置く
- `evaluation` は admission / validity / metrics / comparisons の owner とする
- `self-improvement` は signal intake / proposal governance の owner とする
- `paper-interface` は evaluation output consumer であり、runtime rule owner にはしない

判定:

- requirements-phase では `aligned`
- v2 feature は runtime requirements の単純再開ではなく、新規 primary feature として扱う

## 5. Handback / Follow-On Decision

### 5.1 Absorbed Inside This Feature

- case-specific branch 除去
- Case Manifest / Analysis / Decision / Writer の layer separation
- track 共通 execution contract の requirements-level 定義
- `ECL` mandatory removal の redesign target 化

### 5.2 Foundation Handback Trigger

次が design で必要になった場合は foundation handback を起こす。

- new shared metadata field
- new shared schema object
- shared taxonomy vocabulary の追加または変更
- downstream 共通 consumer が読む canonical contract の変更

### 5.3 Design-Phase Follow-On

- `evaluation`
  - taxonomy-first review artifact をどう standard intake / comparison artifact に落とすか
- `self-improvement`
  - `signal_candidate` / `signal_linkage_note` を proposal input contract にどう接続するか
- `paper-interface`
  - evaluation output から paper-facing claim fragment へ必要 field をどう切り出すか
- `runtime`
  - manifest / analyzer / decision / writer の concrete placement と protocol runner migration

## 6. Gate Result

- status: `completed`
- blocker level: `none at requirements alignment phase`
- next gate: `requirements approval gate`

補足:

- これは implementation-ready を意味しない
- requirements-phase の feature 間調整が完了し、approval gate に進める状態になったことだけを意味する
