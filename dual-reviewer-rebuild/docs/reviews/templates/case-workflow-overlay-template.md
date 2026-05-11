# Case Workflow Overlay Template

_status: template_  
_purpose: generic workflow に対する case 固有差分だけを短く固定する overlay_

---

## 1. Role

この文書は generic workflow の代替ではない。  
この文書は、**その case で追加指定が必要な最小情報だけ**を持つ。

手順の正本は `dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md` とする。

## 2. Case Identity

- case id:
  - `<case-id>`
- core note:
  - `[core-case-<case>.md](...)`
- canonical source:
  - `<path or ref>`
- umbrella state:
  - `[spec.json](...)`

## 3. Active Feature Set

- active features:
  - `<feature-a>`
  - `<feature-b>`

## 4. Dependency Order

- order:
  1. `<feature-a>`
  2. `<feature-b>`

## 5. Approval Model

- human gates:
  - `<requirements | design | tasks | implementation | review acquisition>`
- fixed inputs:
  - `<optional>`

## 6. Special Stop Conditions

- stop when:
  - `<case-specific ambiguity>`
  - `<case-specific reopen condition>`

## 7. Optional Extensions

- uses review acquisition:
  - `<yes | no>`
- uses behavioral appendix boundary:
  - `<yes | no>`

## 8. Primary Working Artifacts

- workflow trace:
  - `<file ref>`
- current control board:
  - `<file ref>`
- main evidence bundle:
  - `<file ref>`
