# heat3d Validation Boundary Decision

_作成: 2026-05-11_  
_status: fixed decision v0.1_  
_role: `heat3d` の canonical full-case acceptance `13.4` を main evidence でどう扱うかを固定する_

---

## 1. decision

`heat3d` における canonical full-case acceptance `13.4` は、**main paper の admission gate にはしない**。

位置づけは次の通りとする。

1. main paper の primary evidence
   - workflow validity
   - review acquisition result
   - implementation traceability
   - evidence reusability
2. `13.4` full-case run
   - behavioral adequacy の補助観測
   - spec/design underconstraint を露出する supplementary evidence

したがって、`13.4` を未達または未確立だからという理由だけで `heat3d` を main paper core case から外さない。

---

## 2. why

この判断の理由は 3 つある。

1. main paper の中心主張は code correctness ではなく workflow / evidence system である
2. `heat3d` では approved upstream artifact から clean-room implementation まで到達し、review acquisition と implementation-local rework trace を取得できている
3. canonical-scale condition を走らせると、形式条件は通っても reference behavior mismatch が残り、`13.4` 自体が behavior oracle として十分強くないことが分かった

したがって `13.4` は、

- main claim の admission criterion
  ではなく
- behavioral adequacy probe

として扱う方が、今回の観測事実と整合する。

---

## 3. recorded reading

`heat3d` の validation boundary は次の 2 層に分けて読む。

### 3.1 implementation-completion side

- code exists
- unit/smoke validation passes
- implementation-local rework is traceable

### 3.2 behavioral-adequacy side

- canonical-scale condition was executed
- formal thresholds can pass
- reference behavior may still mismatch

この split を崩して、

- `13.4` を通ったから implementation correctness が確定した
  または
- `13.4` が behavior mismatch を出したから implementation defect だ

とは言わない。

---

## 4. consequence for the paper

main paper では次の書き方を採る。

1. `heat3d` は fixed core case のまま使う
2. `13.4` は supplementary behavioral evidence として記述する
3. behavior mismatch は first-order で `spec/design underconstraint exposure` と読む
4. responsibility split は `v3` の code-conformance evaluation に委ねる

---

## 5. linked artifacts

- [heat3d-main-paper-observation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-main-paper-observation-note.md:1)
- [heat3d-case-fixation-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-fixation-decision.md:1)
- [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)
- [heat3d-v3-evaluation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-v3-evaluation-note.md:1)
