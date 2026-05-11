# Active Worklist Template

_status: template_  
_purpose: case 初期化時に current control board を生成するための最小ひな形_

---

## 1. Role

この文書は workflow 正本ではない。  
この文書の役割は、**今この case で何を実行中か**を固定することに限る。

- procedure 正本:
  - `dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md`
- case 配置の正本:
  - case manifest
  - core case note
  - case `spec.json`

この文書は、各 case 実行開始時に生成する instance control board である。

## 2. Authoritative Refs

- workflow:
  - `[HUMAN_WORKFLOW.md](...)`
- case manifest:
  - `[case-manifest.md](...)`
- core case:
  - `[core-case-<case>.md](...)`
- state:
  - `[spec.json](...)`

## 3. Current Workflow Step

- current phase:
  - `<intent | requirements | design | tasks | implementation | review acquisition>`
- current artifact type:
  - `<intent.md | requirements.md | design.md | tasks.md | gate package | code>`
- current target set:
  - `<umbrella spec | active feature list | implementation case>`

## 4. Current Blocker

- blocker:
  - `<none | human gate pending | review wave pending | alignment pending | reopen pending | runtime ambiguity>`

## 5. Current Action

- action:
  - `<one concrete next action>`

## 6. Exit Condition

- exit:
  - `<what must become true before moving to the next step>`

## 7. Working Artifacts

- primary:
  - `<file refs>`
- supporting:
  - `<file refs>`

## 8. Stop Rules

- stop if:
  - canonical source interpretation forks
  - multiple reasonable choices change scope
  - gate closure basis is missing
  - reopen responsibility belongs to human
  - review acquisition boundary is not fixed

## 9. Instance Notes

- special case caveat:
  - `<optional>`
- dependency order:
  - `<optional>`
- active feature set:
  - `<optional>`
