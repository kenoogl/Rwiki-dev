# heat3d gate-only workflow trial

_作成: 2026-05-11_  
_status: active trial plan v0.1_  
_purpose: `heat3d` を intent-governed development で進める際、workflow rule と gate が実際に機能するかを検証する_

---

## 1. この文書の役割

この文書は、`C-3 heat3d` を
**「user が gate だけを承認する」**
という簡約運用で試すための trial protocol である。

ここで確認したいのは、

1. workflow の順序が崩れないか
2. gate を飛ばさずに進められるか
3. 人間判断が必要な局面で Codex が停止できるか
4. 事後に workflow path を可視化できるか

である。

この trial は main evidence 取得そのものではない。
主目的は **workflow operation validation** である。

この文書は実施手順の補助であり、正本順位は次に従う。

1. [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
2. [CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md:1)
3. [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)
4. この trial protocol
5. [heat3d-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-workflow-path.md:1)
6. [ACTIVE_WORKLIST.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/ACTIVE_WORKLIST.md:1)

## 2. Scope

対象 case:

- `C-3 heat3d`
- intent ref:
  - [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- canonical source:
  - `/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md`

対象 phase:

1. `intent`
2. `requirements`
3. `design`
4. `tasks`
5. `review acquisition`

feature mode:

- current restart scenario では `heat3d` を multi-feature case として扱う
- active feature 第一案は
  `heat3d-foundation`
  `heat3d-linear-solver`
  `heat3d-case-model`
  `heat3d-main`
  である
- したがって `HUMAN_WORKFLOW.md` にある review wave と alignment gate を active step に含める

pre-requirements discovery:

- `requirements` phase に入る前に、feature decomposition を確認する discovery checkpoint を置いてよい
- この checkpoint は `spec phase` ではなく、human approval gate も持たない
- ただしここで single-feature 前提が不適切と判明した場合、`requirements` draft は無効化して discovery に戻す

## 3. Approval Model

### 3.1 人間が承認するもの

人間は次の 5 gate だけを明示的に承認する。

1. `intent gate`
2. `requirements gate`
3. `design gate`
4. `tasks gate`
5. `review acquisition gate`

補足:

- この trial では `intent gate` はすでに充足済みの fixed input として扱う
- 実運用でこれから回す gate は `requirements / design / tasks / implementation` の 4 つである

### 3.2 Codex が停止すべき条件

次の場合、Codex は作業を停止し、人間へ問い合わせる。

1. 複数の合理的選択肢が残り、片方を勝手に採ると scope が変わる
2. canonical source の解釈が分かれ、downstream artifact が分岐しうる
3. gate を閉じる前提が不足している
4. reopen の要否判断が人間責務に属する
5. review acquisition で runtime-affecting choice が複数あり、spec で決め切れない

## 4. Trial Sequence

順序は固定する。

1. `intent` を fixed input として確認する
2. pre-requirements discovery で feature decomposition を確認する
3. active feature ごとに `requirements.md` を起草する
4. active feature ごとに local requirements review を実施する
5. active feature 群に対して `requirements review wave` を実施する
6. `requirements alignment gate` を実施する
7. `requirements evidence summary` を作成する
8. 人間が `requirements gate` を承認する
9. active feature ごとに `design.md` を起草する
10. active feature ごとに local design review を実施する
11. active feature 群に対して `design review wave` を実施する
12. `design alignment gate` を実施する
13. `design evidence summary` を作成する
14. 人間が `design gate` を承認する
15. active feature ごとに `tasks.md` を起草する
16. active feature ごとに local tasks review を実施する
17. active feature 群に対して `tasks review wave` を実施する
18. `tasks alignment gate` を実施する
19. `tasks evidence summary` を作成する
20. 人間が `tasks gate` を承認する
21. review acquisition 準備と review boundary を固定する
22. implementation review boundary の self-check / conformance review 準備を行う
23. 人間が `review acquisition gate` を承認する

## 4.5 Artifact Contract

この trial で実施者が直接更新する artifact は次に固定する。

- umbrella control:
  - [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
  - [brief.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/brief.md:1)
  - [research.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/research.md:1)
  - [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)
- active feature specs:
  - [heat3d-foundation/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/spec.json:1)
  - [heat3d-foundation/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/requirements.md:1)
  - [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:1)
  - [heat3d-linear-solver/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/spec.json:1)
  - [heat3d-linear-solver/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/requirements.md:1)
  - [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:1)
  - [heat3d-case-model/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/spec.json:1)
  - [heat3d-case-model/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/requirements.md:1)
  - [heat3d-case-model/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:1)
  - [heat3d-main/spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/spec.json:1)
  - [heat3d-main/requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/requirements.md:1)
  - [heat3d-main/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:1)
- workflow trace:
  - [heat3d-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-workflow-path.md:1)
- gate package derived artifacts:
  - [requirements-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/requirements-evidence-summary.md:1)
  - `design-evidence-summary.md`
  - `tasks-evidence-summary.md`

`review acquisition` phase では、少なくとも次を review acquisition gate input として固定する。

- approved `requirements.md`
- approved `design.md`
- approved `tasks.md`
- implementation target statement または review acquisition boundary の短い memo
- 既取得の implementation pilot を使う場合は、その ref

推奨 template:

- [review-acquisition-preparation-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/review-acquisition-preparation-template.md:1)
- [review-acquisition-gate-summary-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/review-acquisition-gate-summary-template.md:1)

## 4.6 phase-field 由来の教訓をどう使うか

この trial は `phase-field` pilot をそのまま複製するものではない。
ただし、少なくとも次の教訓は current rule として継承する。

1. review は phase ごとに上流から下流へ流し、multi-feature なら同 phase の feature 群を水平展開して扱う
2. feature ごとの draft 完了を、そのまま human gate 入力と見なしてはならない
3. review wave で phase 文書が変わった場合、対応する alignment gate を再実施する
4. 上流 phase の reopen は下流 phase の確定性を失わせるため、局所修正のまま前進してはならない

この 4 点の正本は [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:181) に置き、この trial protocol はその `heat3d` への写像としてのみ振る舞う。

## 5. Gate Conditions

### 5.1 Intent Gate

- `intent.md` が current canonical source を参照している
- case scope が `C-3 heat3d` と整合している
- `spec.json` が `intent-fixed` 相当状態になっている

### 5.2 Requirements Gate

- active feature ごとの `requirements.md` が intent と canonical source から self-contained に読める
- active feature ごとの `requirements.md` が人間にとって平易で、意味を追える文章になっている
- downstream で判定不能な曖昧性が主要部に残っていない
- active feature の `spec.json.approvals.requirements.generated = true`
- active feature ごとの local requirements review が完了している
- `requirements review wave` が完了し、未処理 finding が gate request 前に解消または defer されている
- `requirements alignment gate` が完了している
- `requirements evidence summary` が review artifact / alignment / trace への ref を持っている

### 5.3 Design Gate

- active feature ごとの `design.md` が requirements を具体化し、boundary を明示する
- implementation に必要な構成と依存が明示されている
- active feature の `spec.json.approvals.design.generated = true`
- active feature ごとの local design review が完了している
- `design review wave` が完了し、未処理 finding が gate request 前に解消または defer されている
- `design alignment gate` が完了している
- `design evidence summary` が review artifact / alignment / trace への ref を持っている

### 5.4 Tasks Gate

- active feature ごとの `tasks.md` が design を implementation 単位へ落としている
- 実装順序と blocking dependency が明示されている
- active feature の `spec.json.approvals.tasks.generated = true`
- active feature ごとの local tasks review が完了している
- `tasks review wave` が完了し、未処理 finding が gate request 前に解消または defer されている
- `tasks alignment gate` が完了している
- `tasks evidence summary` が review artifact / alignment / trace への ref を持っている

### 5.5 Review Acquisition Gate

- review acquisition の boundary が固定されている
- upstream spec refs と snapshot refs が固定されている
- review acquisition の入力境界が明確である
- review acquisition preparation と review acquisition gate summary が作成されている
- `spec.json.ready_for_review_acquisition = true`

## 5.6 `spec.json` State Transition Rule

`spec.json` は status の正本なので、gate request や path 更新より先に更新する。

| timing | required `spec.json` state |
|---|---|
| trial start | `phase = intent-fixed` |
| requirements draft completed, gate request前 | `phase = requirements-generated`, `approvals.requirements.generated = true` |
| requirements gate approved後 | `phase = requirements-approved`, `approvals.requirements.approved = true` |
| design draft completed, gate request前 | `phase = design-generated`, `approvals.design.generated = true` |
| design gate approved後 | `phase = design-approved`, `approvals.design.approved = true` |
| tasks draft completed, gate request前 | `phase = tasks-generated`, `approvals.tasks.generated = true` |
| tasks gate approved後 | `phase = tasks-approved`, `approvals.tasks.approved = true`, `ready_for_implementation = true`, `ready_for_review_acquisition = false` |
| review acquisition preparation completed, gate request前 | `phase = tasks-approved`, `approvals.review_acquisition.generated = true`, `ready_for_review_acquisition = true` |
| review acquisition gate approved後 | `approvals.review_acquisition.generated = true`, `approvals.review_acquisition.approved = true`, `ready_for_review_acquisition = true` |

reject / reopen の場合は、下流 `approved` を維持したまま前進してはならない。必要な phase を reopen し、`phase` を reopen 元の generated 相当状態へ戻してから作業を再開する。

defer の場合は、`generated = true` を維持したまま `approved = false` とし、`phase` はその phase の `*-generated` に留める。

## 5.7 Review-Before-Gate Rule

この trial では、次を mandatory rule とする。

1. `draft completed` の直後に gate request を出してはならない
2. 各 phase は必ず `review wave` を 1 回以上通す
3. `review completed` event が trace にない phaseは gate request 不可
4. review で finding が出た場合、`fix / defer / reopen` のいずれかが記録されるまで gate request 不可
5. multi-feature case では、すべての active feature の draft と local review が揃う前に phase-level review wave へ進んではならない
6. multi-feature case では、review wave 完了後に alignment gate を通さずに human gate へ進んではならない
7. `requirements / design / tasks` gate は、対応する phase evidence summary がない状態で人間へ回してはならない

## 6. Workflow Path Trace

記録先:

- [heat3d-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-workflow-path.md:1)
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)

責務分担:

- `spec.json`: 現在状態の正本
- `heat3d-workflow-path.md`: 時系列 trace の正本

最低限記録するもの:

- current phase
- gate status
- gate open / close timestamp
- reopen 発生有無
- blocker
- stop reason
- human query 発生有無

更新順序:

1. `spec.json` を更新する
2. `heat3d-workflow-path.md` に event を追記する
3. その後に user へ gate request または pause query を出す

## 6.5 Gate Request Template

各 gate request は少なくとも次の情報を含める。

1. 現在の `spec phase`
2. 対象 artifact ref
3. `spec.json` 更新済みであること
4. 対応する review wave 完了済みであること
5. 対応する evidence summary ref
6. gate を閉じる根拠
7. 残る open issue の有無
8. 人間に求める判断

最小テンプレート:

```text
[Gate Request]
phase: requirements|design|tasks|implementation
artifact: <primary artifact ref>
spec.json: updated
review: completed
evidence summary: <summary ref>
ready state: <why gate can be reviewed now>
open issue: none | <short description>
requested decision: approve | reject | defer
```

## 6.6 Pause Query Template

停止問い合わせは少なくとも次を含める。

1. どの phase で止まったか
2. stop reason は何か
3. どの選択肢が残っているか
4. 推奨案はどれか
5. 進めるには何を決める必要があるか

最小テンプレート:

```text
[Pause Query]
phase: <current phase>
stop reason: <why work must stop>
choice A: <short consequence>
choice B: <short consequence>
recommended: A|B
needed from human: <decision needed to resume>
```

## 7. Success Criteria

1. `intent -> requirements -> design -> tasks -> implementation` の順序が保たれる
2. phase 承認を人間が担い、Codex が代行しない
3. 必要時に停止して問い合わせる
4. reopen が起きたら path trace に残る
5. 事後にどの gate を何回通したかが可視化できる

## 8. Immediate Next Step

1. pre-requirements discovery の結果として active feature set と dependency order を固定する
2. active feature ごとに `requirements.md` を起草する
3. active feature ごとに `spec.json` を `requirements-generated` に更新する
4. workflow path に active feature ごとの requirements draft event を追記する
5. active feature ごとに local requirements review を実施する
6. その後に `requirements review wave` と `requirements alignment gate` を実施する
7. `requirements evidence summary` を作成する
8. review/alignment/summary 完了後にのみ `requirements gate` の human approval を要請する
