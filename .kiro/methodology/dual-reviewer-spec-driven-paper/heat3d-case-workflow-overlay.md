# heat3d case workflow overlay

_作成: 2026-05-11_  
_最終更新: 2026-05-13_  
_status: draft v0.2_  
_purpose: `heat3d` を generic workflow に載せるための case 固有差分だけを固定する_

---

## 1. Role

この文書は `heat3d` 専用の全文 workflow ではない。  
generic procedure の正本は [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1) とし、この overlay では case 固有差分だけを持つ。

## 2. Case Identity

- case id:
  - `C-3 heat3d`
- canonical source:
  - `/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md`
- umbrella state:
  - [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)

## 3. Active Feature Set

- active features:
  - `heat3d-foundation`
  - `heat3d-linear-solver`
  - `heat3d-case-model`
  - `heat3d-main`

## 4. Dependency Order

- order:
  1. `heat3d-foundation`
  2. `heat3d-linear-solver`
  3. `heat3d-case-model`
  4. `heat3d-main`

## 5. Approval Model

- human gates:
  - `requirements`
  - `design`
  - `tasks`
  - `review acquisition`
- fixed input:
  - `intent`

## 6. Special Stop Conditions

- stop when:
  - single-feature 前提のまま先へ進もうとしている
  - canonical source の解釈が feature decomposition を変える
  - reopen が upstream phase を変えるのに局所修正で閉じようとしている
  - behavioral mismatch を implementation defect と断定しようとしている

## 7. Optional Extensions

- uses review acquisition:
  - `yes`
- uses behavioral appendix boundary:
  - `yes`

