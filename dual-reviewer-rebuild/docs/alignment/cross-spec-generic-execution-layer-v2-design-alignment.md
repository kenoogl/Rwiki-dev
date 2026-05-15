# Cross-Spec Design Alignment: Generic Execution Layer v2

_作成日: 2026-05-10_  
_対象: `dual-reviewer-generic-execution-layer-v2` design alignment_

## 1. 目的

この文書は、`dual-reviewer-generic-execution-layer-v2` の design と、

- `foundation`
- `runtime`
- `evaluation`
- `self-improvement`
- `paper-interface`

の design を横断し、

- interface
- file / directory placement
- validator integration point
- replay / paper / improvement への受け渡し

が噛み合っているかを確認するための alignment artifact である。

## 2. 参照正本

- [dual-reviewer-generic-execution-layer-v2 design](/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-generic-execution-layer-v2/design.md:1)
- [dual-reviewer-foundation design](../../.kiro/specs/dual-reviewer-foundation/design.md:1)
- [dual-reviewer-runtime design](../../.kiro/specs/dual-reviewer-runtime/design.md:1)
- [dual-reviewer-evaluation design](../../.kiro/specs/dual-reviewer-evaluation/design.md:1)
- [dual-reviewer-self-improvement design](../../.kiro/specs/dual-reviewer-self-improvement/design.md:1)
- [dual-reviewer-paper-interface design](../../.kiro/specs/dual-reviewer-paper-interface/design.md:1)
- [ACTIVE_WORKLIST.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md:1)
- [phase-and-feature-dependency-map.md](phase-and-feature-dependency-map.md:1)

## 3. Alignment Result Summary

| target | result | note |
|---|---|---|
| `foundation` | aligned | shared contract owner の位置づけは維持。taxonomy を shared contract に上げる場合のみ handback |
| `runtime` | aligned after update | v2 4-layer core を runtime 内部構造として取り込み、既存 runtime artifact 互換も維持 |
| `evaluation` | aligned after update | `comparison_eligibility_note` と `v2/review_artifact.json` の optional intake を追加 |
| `self-improvement` | aligned after update | `signal_linkage_note`, `trace_note`, `comparison_eligibility_note` を supporting input として追加 |
| `paper-interface` | aligned | evaluation 経由の reporting input を維持し、runtime raw artifact を claim-supporting source にしない |

design-phase の blocking 級矛盾は見つからなかった。

## 4. Confirmed Design Boundaries

### 4.1 Shared Contract vs Runtime Internal Structure

確認結果:

- `foundation` は shared metadata、shared schema、validator-facing contract の owner のまま据え置く
- `v2` は `Case Manifest / Analysis / Decision / Writer` の 4 層を runtime の internal execution core として持つ
- `runtime` は step 順序、treatment、prompt resolution、run close の owner として残る

意味:

- `foundation` は共通契約
- `runtime` は実行順序
- `v2` は runtime 内部の責務分離

という役割分担で衝突しない。

### 4.2 Artifact Placement

確認結果:

- raw run directory の正本は引き続き `experiments/runs/<run_id>/`
- downstream compatibility artifact は
  - `review_case.json`
  - `decisions/decision_units.json`
  - `validation/validator_result.json`
  - `validation/invalidation_markers.json`
  を維持する
- v2 internal canonical artifact は `v2/` 配下に置く
- `comparison_eligibility_note.json` は `derived/` 配下に置く

意味:

- 既存 consumer の入口は維持
- v2 の内部正本は追加

という形で両立している。

### 4.3 Evaluation Intake

確認結果:

- evaluation の standard intake は引き続き `review_case.json` と `decision_units.json`
- `derived/comparison_eligibility_note.json` を新しく intake する
- `v2/review_artifact.json`、`v2/metric_snapshot.json`、`v2/trace_note.json` は optional intake とする

意味:

- v2 への移行を始めても、既存 comparison path を壊さずに済む

### 4.4 Self-Improvement Intake

確認結果:

- self-improvement の primary signal owner は引き続き evaluation / self-improvement 側
- v2 は proposal-ready signal inventory を直接正本化しない
- 代わりに
  - `v2/signal_linkage_note.json`
  - `v2/trace_note.json`
  - `run_manifest.yaml`
  - `derived/comparison_eligibility_note.json`
  を supporting input として渡す

意味:

- signal 抽出の主権は self-improvement 側
- v2 は補助情報を渡す

という境界が保たれている。

### 4.5 Paper-Facing Boundary

確認結果:

- paper-interface は evaluation output を一次入力とする
- runtime raw artifact を claim-supporting source にしない
- `paper convenience` による lower layer 逆流を認めない

意味:

- reporting 都合で runtime や evaluation のルールが歪まない

## 5. Validator and Invalidation Boundary

確認結果:

- validator / invalidation policy owner は downstream 判定側に残る
- runtime / v2 は
  - `validator_result.json`
  - `invalidation_markers.json`
  - `comparison_eligibility_note.json`
  を書き出す
- evaluation はそれらを読んで valid / invalid / exploratory / comparison exclusion を扱う
- self-improvement は invalidation と comparison exclusion を workflow / evidence quality signal に使える

意味:

- policy と artifact emission の責務が分離されている

## 6. Design-Phase Open Follow-Ups

blocking ではないが、tasks 前に具体化が必要な論点は残る。

- taxonomy object を shared contract に昇格させるかどうか
- evaluation が taxonomy-first comparison へどう移行するか
- self-improvement proposal input の最小 object shape
- paper claim ID taxonomy の粒度
- v2 internal class / module 名の最終決定

これらは design approval を止める級ではなく、tasks で具体化する detail と整理する。

## 7. Gate Result

- status: `completed`
- blocker level: `none at design alignment phase`
- next gate: `design approval gate`

補足:

- これは実装 ready を意味しない
- design 横断整合が取れ、approval / reopen を判定できる状態になったことを意味する
