# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-implementation-governance` を implementation 可能な作業単位へ落とした task plan である。

governance feature は feature logic ではなく workflow contract を所有するため、

- procedure
- metric register
- review artifact
- template
- validation

の順で固める。

## 2. 実装順序

1. governance-owned artifact placement を固定する
2. conformance review procedure を実装する
3. conformance metric register を実装する
4. review template と concrete review artifact を実装する
5. signal / coordination linkage を実装する
6. governance artifact validator を実装する
7. workflow gate status と cross-spec alignment を実装する
8. intent review と phase-review metrics を正式化する
9. reference-free bootstrap と minimal heuristic default を正式化する

理由:

- procedure と metric が先にないと review artifact が drift する
- concrete review artifact がないと validator の対象がない
- signal / coordination linkage がないと finding が repo evidence として閉じない
- governance 自体が workflow を外れないよう、最後に status と cross-spec alignment を閉じる
- intent review と phase-review metrics は governance 所有範囲の拡張として最後に formalize する

## 3. Tasks

### Task 1: Create governance artifact placement

目的:

- governance-owned placement を repo 上に固定する

作業:

- `.kiro/specs/dual-reviewer-implementation-governance/`
- `docs/coordination/implementation-conformance-review.md`
- `docs/coordination/implementation-conformance-metric-register.md`
- `docs/reviews/templates/`

を正本配置として明示する。

完了条件:

- governance artifact の owner と placement が repo 上で一意になる

### Task 2: Implement conformance review procedure

目的:

- post-implementation review stage を concrete 文書にする

作業:

- review timing
- review scope
- required outputs
- severity / disposition
- completion rule

を `implementation-conformance-review.md` に実装する。

完了条件:

- implementation completion rule が smoke pass 単独ではないことが文書として固定される

### Task 3: Implement conformance metric register

目的:

- conformance review の effectiveness を測る metric 正本を作る

作業:

- required metric list
- definition
- collection timing
- interpretation

を `implementation-conformance-metric-register.md` に実装する。

完了条件:

- review artifact が metric snapshot を持てる

### Task 4: Implement review template and concrete review artifact

目的:

- review structure の drift を防ぎ、少なくとも 1 件の concrete evidence を残す

作業:

- `docs/reviews/templates/implementation-conformance-review-template.md`
- `docs/reviews/<date>-<scope>-review.md`

を作成する。

完了条件:

- reusable template と passing concrete review artifact の両方が存在する

### Task 5: Implement signal and coordination linkage

目的:

- conformance finding を repo 内の既存 tracking 文脈へ接続する

作業:

- `implementation-signal-register` に governance 起因の signal type と concrete entry を追加する
- `implementation-coordination-log` に review 実施記録を追加する

完了条件:

- finding が review artifact 単独で孤立しない

### Task 6: Implement governance artifact validator

目的:

- governance artifact の completeness を mechanical に確認できるようにする

作業:

- `scripts/validate_implementation_governance_artifacts.rb`

を実装する。

validator が確認すること:

- procedure doc の存在
- metric register の存在
- review template の存在
- concrete review artifact の required section
- metric snapshot の required keys

完了条件:

- governance artifact validation が repo 内 script で再現できる

### Task 7: Implement workflow gate status and governance alignment memo

目的:

- governance 追加自体を workflow に載せる

作業:

- `docs/coordination/workflow-gate-status.md`
- `docs/alignment/cross-spec-implementation-governance-alignment.md`

を追加し、governance spec の `spec.json` alignment status も更新する。

完了条件:

- governance spec 自体が cross-spec alignment を通過したことを repo artifact で説明できる

### Task 8: Formalize intent review and phase-review metrics

目的:

- governance spec の owning scope に `intent review` と phase-level measurement を含める

作業:

- `docs/reviews/templates/intent-review-template.md`
- `docs/reviews/<date>-intent-*.md`
- `docs/coordination/phase-review-metric-register.md`
- `operations/HUMAN_WORKFLOW.md`

を spec に対応する owner artifact として明示する。

あわせて validator を更新し、次を確認対象に含める。

- intent review template の存在
- concrete intent review artifact の存在
- phase-review metric register の存在

完了条件:

- intent review と phase-review metrics が governance spec の正式範囲として説明できる
- governance artifact validation が新しい owner artifact を検査する

### Task 9: Formalize reference-free case bootstrap and minimal heuristic defaults

目的:

- 新しい case が pilot-case copy に依存せず、minimal heuristic から始められることを workflow contract にする

作業:

- `operations/HUMAN_WORKFLOW.md` に reference-free bootstrap を正式手順として反映する
- `.kiro/methodology/dual-reviewer-spec-driven-paper/reference-free-case-bootstrap-guide.md` を owner artifact として固定する
- `scripts/bootstrap_reference_free_case.rb` を bootstrap entrypoint として明記する
- implementation protocol / snapshot template を reference-free template として明記する
- `experiments/protocols/heuristic_profiles/README.md` と track-level `_minimal_template.yaml` 群を minimal heuristic policy の正本として明記する

完了条件:

- 新規 case の開始手順が既存 case 参照なしで説明できる
- heuristic default policy が workflow owner artifact として明示される
- runtime の default heuristic fallback が governance rule と矛盾しない
