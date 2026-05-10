# Generic Execution Layer v2 Spec

_作成: 2026-05-10_  
_status: draft v0.1_  
_purpose: case-specific heuristic pilot を置換する generic execution layer v2 の上位仕様を固定する_

---

## 1. この文書の役割

この文書は、`dual-reviewer` 論文化用 pilot 実装で露呈した
case-specific execution rule を除去し、
**track 共通で運用できる generic execution layer v2**
の上位仕様を固定するための文書である。

ここでいう v2 は、単なる runtime patch ではない。

- `ECL` で除去対象を固定し
- その上位概念を仕様として再設計し
- その仕様駆動で `requirements/design/tasks` を回し
- 実装として generic layer を作り直す

という intent-governed spec-driven development の対象である。

---

## 2. Background

現状の pilot acquisition は成立している。
しかし execution layer は次の問題を持つ。

1. review rule が `phase-field` と `dual-reviewer-rebuild` に埋め込まれている
2. writer が実質 analyzer を兼ね、case 固有 finding を直接生成している
3. case を増やすたびに branch と script が増殖する
4. 同じ case でも rule 実装変更で evidence が揺れる

この状態では、

- main evidence
- reusable pilot method
- v2 system architecture

のいずれとしても不十分である。

---

## 3. Goal

v2 の目標は次である。

1. `Intent / Spec / Implementation` の 3 track を同じ execution contract で扱う
2. finding を case 名ではなく taxonomy で first-class に扱う
3. case 固有性を input artifact と extracted evidence に閉じ込める
4. analyzer と writer を分離し、artifact 生成を deterministic にする
5. case onboarding を code edit ではなく manifest 更新で済む形にする

---

## 4. Non-Goals

この v2 仕様で直ちに目指さないもの:

1. 全ドメイン自動一般化
2. finding quality の最終最適化
3. 人間 gate の除去
4. main evidence への即昇格

まず必要なのは、execution rule の generic 化と再実行可能性の確立である。

---

## 5. Layer Model

v2 では少なくとも次の 4 層を分離する。

### 5.1 Case Manifest Layer

責務:

- case identity
- track
- phase
- input refs
- batch grouping
- pilot scope

を固定する。

この層は case 固有情報を持ってよい。
ただし finding rule は持たない。

### 5.2 Analysis Layer

責務:

- input artifact を読む
- evidence excerpt を抽出する
- gap / inconsistency / caveat / handback 候補を taxonomy に写像する

この層は track-aware でよいが case-aware ではない。

### 5.3 Decision Layer

責務:

- primary / adversarial / judgment の役割分担
- severity / necessity / reopen depth / handback class の決定

この層は extracted evidence と taxonomy を入力にし、
case 名で分岐しない。

### 5.4 Writer Layer

責務:

- review artifact
- metric snapshot
- trace note
- signal linkage
- comparison summary

を schema に従って出力する。

writer は finding を発明しない。

---

## 6. Common Execution Contract

全 track は少なくとも次の共通 contract を持つ。

### 6.1 Common Inputs

- `track`
- `phase_profile`
- `review_mode`
- `source_refs`
- `governance_refs`
- `case_manifest_ref`

### 6.2 Common Intermediate Objects

- `evidence_observation`
- `review_issue_candidate`
- `caveat_candidate`
- `reopen_candidate`
- `signal_candidate`

### 6.3 Common Outputs

- `review_artifact`
- `metric_snapshot`
- `trace_note`
- `signal_linkage_note`
- `run_manifest`

---

## 7. Track-Specific Input Contracts

### 7.1 Intent Track

最小入力:

- `intent_ref`
- `supporting_refs`
- `traceability_refs`

主に観測するもの:

- phase contract gap
- scope drift risk
- human gate ambiguity
- downstream propagation target

### 7.2 Spec Track

最小入力:

- `reviewed_phase`
- `reviewed_phase_ref`
- `adjacent_phase_refs`
- `alignment_refs`

主に観測するもの:

- phase-local gap
- cross-phase inconsistency
- intent-attributed issue
- reopen / recheck depth

### 7.3 Implementation Track

最小入力:

- `implementation_snapshot_ref`
- `upstream_spec_refs`
- `governance_refs`
- `target_artifact_hash`

主に観測するもの:

- implementation/spec mismatch
- parameter interpretation drift
- ordered-state-transition risk
- caveat retention
- downstream rework traceability

---

## 8. Finding Taxonomy v2

finding は case 名ではなく次の taxonomy で first-class 化する。

### 8.1 Gap Type

- `phase_contract_gap`
- `constraint_mismatch`
- `missing_explicit_boundary`
- `validation_ownership_gap`
- `downstream_readiness_gap`

### 8.2 Inconsistency Type

- `cross_phase_inconsistency`
- `input_to_artifact_mapping_ambiguity`
- `ordered_state_transition_risk`
- `parameter_interpretation_drift`

### 8.3 Caveat Type

- `scope_boundary_caveat`
- `evidence_density_caveat`
- `external_side_effect_caveat`
- `bootstrap_case_caveat`

### 8.4 Propagation Type

- `recheck_required`
- `reopen_required`
- `intent_handback`
- `requirements_handback`
- `design_handback`
- `task_local_adjustment`

---

## 9. Separation Rules

v2 では次を禁止する。

1. `case_id` を見て analyzer を切り替える
2. `target_id` を見て finding 生成可否を切り替える
3. writer が case 固有 finding summary を直接生成する
4. batch script が review rule を内包する

代わりに次を許可する。

1. manifest が case 固有 refs を持つ
2. analyzer が track ごとに異なる input contract を持つ
3. final finding text が extracted excerpt を含む

---

## 10. Relation To ECL

`ECL` は v2 の仕様入力台帳である。

- `remove` 対象は execution layer から除去する
- `migrate to case manifest` 対象は manifest 層へ移送する
- `sample/default only` 対象は canonical protocol から降格する

したがって、v2 実装は `ECL` を満たさない限り完了とみなさない。

---

## 11. Spec-Driven Development Path

この上位仕様の次に進む順は固定する。

1. v2 `requirements` を起こす
2. v2 `design` で layer boundary と contracts を固定する
3. v2 `tasks` で置換順を固定する
4. 実装で runtime / analyzer / writer / manifest を分離する
5. `phase-field` で pilot を再取得する

---

## 12. Completion Rule

この文書が役割を果たしたとみなす条件は次である。

1. `ACTIVE_WORKLIST` の `Current Next Step` を次の spec phase に進められる
2. `ECL` の P0 / P1 が v2 仕様上どこへ吸収されるか説明できる
3. 後続の `requirements/design/tasks` が code patch ではなく spec から起こせる
