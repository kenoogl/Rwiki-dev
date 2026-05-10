# dual-reviewer first-run plan

_作成: 2026-05-09_  
_status: draft v0.2_  
_purpose: first evaluation batch の取得条件固定_

---

## 1. この文書の役割

この文書は、`dual-reviewer` の次段評価における
最初の取得バッチを固定するための plan である。

ここでの first-run は、
code review 単独の pilot ではなく、
**仕様駆動開発支援評価のうち `phase-field` Implementation Track を先に小さく回す batch**
として扱う。

---

## 2. first-run の目的

first-run batch の目的は、大規模な統計比較ではない。

目的は次の 4 つである。

1. implementation/review phase でも `dual-reviewer` workflow が崩れず動くことを確認する
2. upstream spec と implementation review が切れずにつながることを確認する
3. disagreement / caveat / reopen depth が artifact に残ることを確認する
4. main batch 前に logging / caveat / traceability の欠落を潰す

したがって、この batch は pilot であり、
paper 本番の main evidence ではなく Implementation Track acquisition の入口である。

---

## 3. 取得順序

first-run の順序は次とする。

1. `phase-field` implementation phase

この pilot で protocol / artifact / workflow の成立を確認した後に、
scope を順次 `heat3d` と `iot-arduino` へ拡大する。

理由:

- `phase-field` が最も高認知負荷で、implementation/review phase の stress test になる
- provisional case を混ぜずに fixed core case だけで pilot を閉じられる

---

## 4. Per-Case First Batch

### 4.1 `phase-field` implementation phase

- batch label: `F1-phase-field-cpp`
- fixed snapshot:
  - [phase-field-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-implementation-phase-first-snapshot.md:1)
- initial comparison modes:
  - `single review`
  - `dual-reviewer workflow`
- optional:
  - `manual reference`
- minimum batch:
  - `1 implementation snapshot x 2 review modes`

system/protocol success condition:

1. upstream spec ref が artifact に残る
2. disagreement evidence が artifact に残る
3. caveat が silent に消えない
4. conformance rerun が可能

review-output success condition:

1. algorithmic / boundary / parameter / mutation ordering のいずれかで meaningful finding が出る
2. implementation issue と specification issue を混同せず扱える

### 4.2 Scope expansion after the pilot

pilot 結果を確認した後に、次の順で scope を拡大する。

1. `heat3d` implementation phase
2. `iot-arduino` implementation phase

どちらも provisional case が fixed に上がった後に first batch 対象へ入れる。

---

## 5. Snapshot Selection Rule

各 implementation-phase first snapshot は次の条件を満たすものを使う。

1. review boundary が明確である
2. upstream spec と接続できる
3. trivial toy ではない
4. phase-specific stress point が最低 2 種以上含まれる

避けるもの:

- formatting-only snapshot
- 上流 spec と切れている孤立 code snapshot
- 問題が既知すぎて答え合わせだけになるもの

---

## 6. Required Artifacts for First Run

各 first run で最低限必要な出力:

- case descriptor
- upstream spec ref
- review artifact
- decision units
- signal linkage
- caveat / exclusion artifact
- conformance review result
- downstream rework placeholder or log

first-run 特有で残すもの:

- batch note
- acquisition issue memo
- protocol mismatch note

---

## 7. First-Run Readiness Checklist

run 開始前に確認すること:

1. target snapshot が固定されている
2. upstream spec ref が書けている
3. comparison mode が固定されている
4. artifact placement が決まっている
5. conformance rerun path がある

---

## 8. Interpretation Rule

first-run の結果は、優劣を強く主張するために使わない。

first-run では次を確認する。

- `phase-field` implementation/review phase で workflow が成立するか
- `single` と `dual-reviewer` で process/evidence 差が見えるか
- target-specific caveat が properly retained されるか
- upstream spec と review artifact が切れないか

ここで問題が出た場合は、
まず protocol / artifact / workflow を修正し、
main batch の前に潰す。

---

## 9. Immediate Next Step

この plan の直後に必要なのは次である。

1. `phase-field` implementation phase の snapshot を 1 つ固定する
   - status:
     - fixed as `F1-phase-field-cpp-s1`
2. `single review` と `dual-reviewer workflow` の run template を作る
3. `phase-field` pilot の review logic と acquisition runner を整える
4. Intent Track / Spec Track 用の first-run も別文書で定義する
   - status:
     - [intent-track-first-run-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-first-run-plan.md:1)
     - [spec-track-first-run-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-first-run-plan.md:1)
5. 3 track の run template を作る
   - status:
     - [intent-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/intent-track-run-template.md:1)
     - [spec-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/spec-track-run-template.md:1)
     - [implementation-track-run-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-track-run-template.md:1)
