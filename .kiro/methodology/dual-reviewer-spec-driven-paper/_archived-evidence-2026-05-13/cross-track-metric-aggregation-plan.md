# cross-track metric aggregation plan

_作成: 2026-05-11_  
_status: planning note v0.1_  
_role: additional comparison / metric aggregation の次段を固定する_

---

## 1. scope

この文書は、すでに取得済みの

- `Intent Track` fresh first batch
- `Spec Track` fresh first batch
- `Implementation Track` baseline (`phase-field`)
- `Implementation Track` bridge case (`heat3d`)

を使って、main paper の弱点を最も減らす最小集計単位を決める。

ここでやるのは **新規主張の追加** ではなく、

1. `Claim 2 / 3 / 4` を支える cross-track metric を定義する
2. どの artifact を source of truth にするかを固定する
3. large-N に行く前の最小 aggregation package を決める

ことである。

---

## 2. immediate objective

直近の objective は 3 つである。

1. disagreement / caveat / handback / reopen を、track ごとに比較可能な形へ揃える
2. `workflow/evidence claim` と `behavioral adequacy claim` を metric 上でも分離する
3. `heat3d` の implementation-local rework を、upstream reopen `0` と対にして読むための cross-track table を作る

---

## 3. input set

### 3.1 Intent Track

- [F1-intent-dual-reviewer-rebuild-narrative comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild-narrative/comparison_summary.json:1)
- [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1)

### 3.2 Spec Track

- [F1-spec-phase-field-reverse-spec-narrative comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec-narrative/comparison_summary.json:1)
- [remaining-track-first-batch-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/remaining-track-first-batch-acquisition-summary.md:1)

### 3.3 Implementation Track

- [phase-field comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json:1)
- [heat3d comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/comparison_summary.json:1)
- [heat3d-phase-field-implementation-comparison-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-phase-field-implementation-comparison-note.md:1)
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)

---

## 4. metric families

### 4.1 workflow preservation

- `handback_present`
- `reopen_required`
- `major_correction_present`
- `phase_evidence_summary_present`

この family は、単なる finding 数ではなく、**レビュー後にどれだけ構造化された差し戻しが残ったか**を見る。

### 4.2 disagreement preservation

- `caveat_retained`
- `disposition_recorded`
- `dual_only_signal_present`

この family は、`single` では落ちやすいが `dual` で残る signal を保持できたかを見る。

### 4.3 downstream rework

- `implementation_local_blocking_issue_count`
- `upstream_phase_reopen_required_count`
- `review_to_fix_trace_present`

この family は、implementation まで降りた後の手戻りがどこに閉じたかを見る。

### 4.4 boundary / interpretation

- `first_batch_only`
- `behavioral_adequacy_deferred`
- `v3_responsibility_split_deferred`

この family は成果指標ではなく、**本文に残す caveat** を管理するための flag として使う。

---

## 5. first aggregation package

main paper にまず足すべき最小 package は次の 3 表である。

1. `Track-level preservation table`
   - row: `Intent / Spec / Implementation`
   - col: `handback`, `reopen`, `major correction`, `caveat/disposition`, `evidence summary`

2. `Implementation downstream rework table`
   - row: `phase-field`, `heat3d`
   - col: `single findings`, `dual findings`, `dual+judgment findings`, `implementation-local blocking issue count`, `upstream reopen count`

3. `Interpretation boundary table`
   - row: `Intent`, `Spec`, `Implementation`
   - col: `first-batch only`, `behavioral adequacy outside main claim`, `v3 delegation needed`

---

## 6. non-goals

この planning では次をまだやらない。

- statistical significance
- domain-general regularity の断定
- `heat3d` の behavior mismatch の責任断定
- large-N comparison

---

## 7. execution order

次に実行する順はこれで固定する。

1. `Track-level preservation table` の source metric を手で抽出する
2. `Implementation downstream rework table` を `phase-field / heat3d` で作る
3. 本文に入れるのは table 全体ではなく、1 段落の compressed reading にする
4. full table は supporting note に残す

---

## 8. paper-facing reading

この集計で main paper に追加したい読みは次である。

`dual-reviewer` の差分は finding 数の増加だけではなく、track をまたいで handback, reopen, major correction, caveat retention, downstream rework trace を保持する点にある。ただし upstream 2 track の acquisition-backed support は first-batch level に留まるため、本文では workflow/evidence claim に限定して使い、large-N regularity や behavioral adequacy の主張には拡張しない。
