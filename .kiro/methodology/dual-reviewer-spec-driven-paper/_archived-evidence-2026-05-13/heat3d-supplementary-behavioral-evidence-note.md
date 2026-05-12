# heat3d supplementary behavioral evidence note

_作成: 2026-05-11_  
_status: supplementary note v0.1_  
_role: `heat3d` の canonical-scale 実行結果と behavior mismatch を本文外の補助観測として固定する_

---

## 1. role

この文書は、`heat3d` の actual implementation について

- reduced validation は通った
- canonical-scale condition も実行した
- ただし reference behavior mismatch が残った

という 3 点を、main paper 本文の workflow/evidence claim と切り分けて保存する。

正本判断は [heat3d-validation-boundary-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-validation-boundary-decision.md:1) に従う。

---

## 2. compared artifacts

### 2.1 reference behavior

- [log.txt](/Users/Daily/Development/Heat3ds/log.txt:1)

この log は、

- physical grid `240 x 240 x 31`
- solver `pbicgstab`
- preconditioner `gauss-seidel`
- tolerance `1.0e-4`

の canonical-scale 実行記録として扱う。

### 2.2 clean-room implementation side

- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)
- [heat3d-implementation-execution-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-execution-note.md:1)
- [DR-rebuild-log-5.md](/Users/Daily/Development/Rwiki-dev/docs/DR-rebuild-log-5.md:2410)

---

## 3. observed split

### 3.1 reference log side

reference log では、少なくとも次が読める。

- converged around `iteration 200`
- `theta_min ≈ 301.8147 K`
- `theta_max ≈ 344.6925 K`

### 3.2 clean-room implementation side

clean-room implementation の canonical-scale run では、少なくとも次が記録されている。

- `iterations = 1313`
- `final_residual = 7.5188275219193246e-05`
- `theta_min = 273.64571257671713 K`
- `theta_max = 300.0 K`
- `elapsed_seconds = 87.90498900413513`

形式条件だけを見ると、

- `iterations <= 8000`
- `final_residual < 1.0e-4`
- `theta_min >= 250`
- `theta_max <= 2000`
- `theta_max > theta_min`

は満たしている。

---

## 4. reading boundary

この split から first-order に言うべきことは 2 つだけである。

1. current implementation は **動作し、reduced validation と formal threshold は通っている**
2. しかし **reference behavior の再現にはなっていない**

ここから直ちに

- implementation defect
  または
- implementation correctness confirmed

のどちらかを断定してはならない。

この note の役割は、むしろ

- main paper では workflow/evidence claim を維持する
- behavior mismatch は supplementary evidence として保持する
- responsibility split は `v3` の code-conformance evaluation へ委ねる

という境界を明示することにある。

---

## 5. paper-facing consequence

main paper では、この note の内容を 1 段落で圧縮して使う。

- `heat3d` は correctness proof case ではない
- `heat3d` は workflow validity, implementation-origin evidence, spec underconstraint exposure の bridge case である
- behavioral mismatch は supplementary evidence に退避し、本文で defect 断定をしない

---

## 6. next-use rule

この note を再利用する場面は次の 2 つである。

1. appendix / supplementary section で canonical-scale 実行結果を説明するとき
2. `v3` の code-conformance evaluation で、`code ↔ tasks/design/requirements` と behavior mismatch を切り分ける起点にするとき
