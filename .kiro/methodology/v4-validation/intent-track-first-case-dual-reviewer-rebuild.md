# Intent Track first case: dual-reviewer-rebuild

_作成: 2026-05-09_  
_status: fixed for first-run v0.1_  
_role: `F1-intent-track` の concrete case 固定_

---

## 1. この文書の役割

この文書は、`Intent Track` の最初の取得バッチで使う
concrete case を固定する。

ここでの目的は、`intent` しかない、または `intent` が最上位入力である状態から、
`requirements / design / tasks` へ下る review/governance loop を
`dual-reviewer` が成立させられるかを見ることである。

---

## 2. Fixed Case ID

- case id: `F1-intent-dual-reviewer-rebuild`
- batch label: `F1-intent-track`
- track: `Intent Track`
- target label: `dual-reviewer-rebuild`
- role in paper:
  - intent-origin workflow validity
  - intent-only bootstrap representative

---

## 3. Case Definition

この case は、`dual-reviewer-rebuild` の初期 bootstrap 区間を対象にする。

固定する対象は次の 2 層である。

1. intent-side anchor
2. downstream bootstrap reference

### 3.1 Intent-Side Anchor

- canonical intent ref:
  - [dual-reviewer-spec-driven-paper-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/dual-reviewer-spec-driven-paper-plan.md:1)
- supporting intent/governance refs:
  - [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
  - [workflow-repair-procedure.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md:1)
  - [implementation-conformance-review.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/implementation-conformance-review.md:1)

この case では、「`intent` しかない状態から複数 phase をどう起こし、
途中で見つかった問題をどう handback / reopen / recheck するか」を
観測対象にする。

### 3.2 Downstream Bootstrap Reference

- bootstrap spec root:
  - [dual-reviewer-rebuild/.kiro/specs](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs)
- workflow evidence root:
  - [docs/coordination](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination)
  - [docs/reviews](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews)

first-run では、既存 artifact の最終状態を main evidence として使うのではなく、
bootstrap の開始条件と、そこからどの phase に伝播したかを
Intent Track の run artifact として切り出す。

---

## 4. Why This Case

この case を `Intent Track` first-run に選ぶ理由は次である。

1. `intent` 起点の最小入力を扱える  
   `dual-reviewer` の目的自体が、intent-origin の仕様駆動開発支援にある。

2. downstream 全 phase への伝播を説明できる  
   `requirements / design / tasks / implementation / conformance review` まで
   既に接続経験があり、reopen / recheck rule を観測しやすい。

3. workflow evidence の所在が明確  
   governance、review artifact、signal register、gate status が揃っている。

4. internal dogfooding を external main evaluation と混同しにくい  
   本 case は workflow bootstrap 妥当性の確認に限定し、
   downstream implementation quality の主評価には使わない。

---

## 5. Review Boundary for First Run

first-run で主対象に含めるもの:

- `intent` の明示内容
- そこから起こされる `requirements` 候補
- `intent-attributed issue`
- `D` handback 要否
- downstream propagation target (`requirements/design/tasks`)

first-run で主対象にしないもの:

- implementation code quality の詳細比較
- paper-facing artifact quality
- self-improvement adoption loop の性能比較

つまりこの case で見るのは、
「上流 bootstrap の review/governance loop が成立するか」である。

---

## 6. Required First-Run Outputs Bound to This Case

`F1-intent-dual-reviewer-rebuild` で最低限残す出力:

- `run_manifest.yaml`
- `intent_review.md`
- `intent_trace_note.yaml`
- `phase_metric_snapshot.json`
- `signal_linkage_note.yaml`
- protocol mismatch note（必要時）

加えて、run memo では少なくとも次を持つ。

- major gap candidate
- scope drift candidate
- counter-hypothesis
- `intent_handback_required`
- downstream propagation target
- caveat

---

## 7. Comparison Modes Bound to This Case

`F1-intent-dual-reviewer-rebuild` に対して固定する比較軸:

1. `single review`
2. `dual-reviewer workflow`

`manual reference` は optional とする。

---

## 8. Caveats

この case の caveat は次である。

1. internal rebuild case であり、external case ではない
2. downstream 実装・review evidence が豊富なので、純粋な blank-slate intent-only より context が厚い
3. したがって first-run では「最小 bootstrap の厳密比較」よりも
   「workflow artifact の欠落がないか」の確認に重心を置く

この caveat は preliminary report では limitation として保持する。

---

## 9. Immediate Operational Rule

`Intent Track` first-run を開始する前に、少なくとも次を行う。

1. input intent ref を 1 つに固定する
2. supporting governance refs を run manifest に列挙する
3. `single review` と `dual-reviewer workflow` の両方で
   同じ intent input を使う
4. downstream propagation target を `requirements/design/tasks` から明示的に選ぶ

これを満たした時点で、
`F1-intent-dual-reviewer-rebuild` を fixed case とみなす。
