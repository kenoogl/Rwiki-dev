# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-generic-execution-layer-v2` を implementation 可能な作業単位へ落とした task plan である。

この feature は、既存 pilot に残っている case-specific hardcode を除去し、

- `Case Manifest Layer`
- `Analysis Layer`
- `Decision Layer`
- `Writer Layer`

の 4 層で generic execution layer を実装し直すための主 task plan である。

この文書では、

- どの順で v2 を組み立てるか
- どの時点で既存 runtime 互換 artifact を維持するか
- downstream への受け渡しをいつ整えるか
- validator と pilot rerun をどこで入れるか

を implementation order として固定する。

## 2. 実装順序

1. v2 module skeleton と common contract を揃える
2. case manifest wiring を batch / runner hardcode から切り離す
3. analysis / decision / writer の 3 層を実装する
4. runtime 互換 artifact と v2 internal artifact の両方を出せるようにする
5. protocol runner と track runner を v2 path へ差し替える
6. evaluation / self-improvement が読む補助 artifact を揃える
7. validator / comparison eligibility / smoke checks を揃える
8. `phase-field` pilot rerun と comparison 再取得を行う

理由:

- writer より先に contract と manifest を固めないと case-specific wiring が残る
- runtime 互換 artifact を維持しないと downstream 影響を切り分けにくい
- runner 差し替え前に 4 層の内部を作らないと pilot を再取得できない
- rerun は implementation 後の最後に置くべきである

## 3. Tasks

### Task 1: Create v2 module skeleton and contract files

目的:

- generic execution layer v2 の ownership 境界を file / module レベルで固定する

作業:

- `runtime/execution_v2/contracts/`
- `runtime/execution_v2/manifests/`
- `runtime/execution_v2/analyzers/`
- `runtime/execution_v2/decisions/`
- `runtime/execution_v2/writers/`
- `runtime/execution_v2/support/`

の skeleton を作る。

含めること:

- common execution contract loader
- track-specific contract specializer
- shared object naming

完了条件:

- v2 実装の責務分離が directory / module レベルで見える
- 後続 task が `runtime/execution_v2/` を正本実装先として参照できる

### Task 2: Implement common execution contract loading

目的:

- 3 track が同じ run-level contract で起動できるようにする

作業:

- `track`
- `target_id`
- `target_artifact_hash`
- `source_repository_id`
- `source_revision`
- `phase_profile`
- `treatment`
- `review_mode`
- `source_refs`
- `governance_refs`
- `case_manifest_ref`

を含む common contract loader を実装する。

含めること:

- required field check
- provenance field preservation
- `target_id` を traceability field として扱い、rule branch には使わせない guard

完了条件:

- 3 track が contract shape の差ではなく contract specialization だけで分かれる
- missing contract field のまま runner が進まない

### Task 3: Implement Case Manifest Layer and migrate case wiring

目的:

- batch script / runner 側に残る case-specific binding を manifest layer へ移す

作業:

- case manifest resolver
- source ref binder
- batch grouping metadata loader
- pilot scope metadata loader

を実装する。

移行対象:

- `ECL` の `migrate to case manifest` entries
- case id と spec path の固定 binding
- reviewed phase / implementation snapshot / intent ref の case registration

完了条件:

- batch / runner 側に case-specific review rule が残らない
- case 固有性が manifest input と ref binding に閉じる

### Task 4: Implement track-aware Analysis Layer

目的:

- input artifact を読み、taxonomy-first candidate を作る層を実装する

作業:

- intent analyzer
- spec analyzer
- implementation analyzer
- shared candidate builder

を実装する。

含めること:

- `evidence_observation`
- `review_issue_candidate`
- `caveat_candidate`
- `reopen_candidate`
- `signal_candidate`

の生成。

禁止事項:

- `case_id` string match による analyzer 切替
- hardcoded finding summary の生成

完了条件:

- track-aware だが case-aware ではない candidate generation path が存在する
- candidate が case 名ではなく taxonomy と evidence refs で表現される

### Task 5: Implement Decision Layer

目的:

- candidate を accepted / rejected / deferred な決定結果へ変換する

作業:

- severity resolver
- necessity / reopen resolver
- handback / propagation classifier
- signal linkage resolver

を実装する。

含めること:

- treatment / review_mode aware decision context
- invalidation-relevant note generation
- deferred decision handling

完了条件:

- decision が case 名ではなく taxonomy と evidence に基づいて行われる
- reopen / handback class が writer 内の埋め込み rule でなく decision object として残る

### Task 6: Implement Writer Layer with compatibility outputs

目的:

- v2 internal artifact と既存 downstream 互換 artifact の両方を書き出せるようにする

作業:

- `v2/review_artifact.json`
- `v2/metric_snapshot.json`
- `v2/trace_note.json`
- `v2/signal_linkage_note.json`
- `run_manifest.yaml`
- `review_case.json`
- `decisions/decision_units.json`
- `decisions/human_signoff.json`

の writer を実装する。

含めること:

- compatibility projection from v2 decision objects to existing runtime envelope
- writer が analyzer / decision を兼ねない guard
- taxonomy-first internal representation と rendered text の分離

完了条件:

- evaluation の標準 intake を壊さずに v2 internal artifact が追加される
- existing compatible artifact と v2 internal artifact の責務が混線しない

### Task 7: Implement validation and comparison-eligibility artifact emission

目的:

- validator 結果と comparison eligibility を v2 path でも失わないようにする

作業:

- `validation/validator_result.json`
- `validation/invalidation_markers.json`
- `derived/comparison_eligibility_note.json`

の emission / update path を実装する。

含めること:

- validator invocation bridge
- invalidation marker preservation
- comparison-ineligible note emission

完了条件:

- `valid / invalid / comparison-ineligible` の区別が artifact に残る
- runtime / evaluation / self-improvement が同じ補助情報を読める

### Task 8: Implement portable bundle export compatibility

目的:

- v2 replacement 後も local run を imported bundle として外へ渡せるようにする

作業:

- `exports/<bundle_id>/bundle_manifest.yaml`
- `exports/<bundle_id>/run/` subtree
- `exports/<bundle_id>/checksums/bundle_checksums.json`

の export path が v2 artifact layout と両立するようにする。

含めること:

- `review_case.json` / `decision_units.json` / validation artifacts の export inclusion
- `v2/review_artifact.json` など internal artifact の optional inclusion 方針
- raw run semantics を変えない export bridge

完了条件:

- evaluation の imported bundle intake 前提を壊さない
- v2 replacement 後も portable bundle export が実行できる

### Task 9: Adapt protocol runners and track runners to v2

目的:

- pilot acquisition 実行経路を v2 layer 経由に差し替える

作業:

- `scripts/protocol_runners/` の v2 entrypoint 実装
- `scripts/track_runs/` adapter 更新
- first-batch runner の manifest-based wiring への差し替え

対象例:

- `run_*_track_protocol.rb`
- `run_phase_field_*_first_batch.rb`
- `run_dual_reviewer_rebuild_intent_first_batch.rb`

完了条件:

- first-batch runner が case-specific branch ではなく manifest / contract 経由で動く
- `phase-field` pilot を v2 path から再実行できる

### Task 10: Update downstream-supporting intake surfaces

目的:

- evaluation / self-improvement が必要とする補助 artifact を実際に供給できるようにする

作業:

- evaluation 向け optional intake artifact の placement 最終確認
- self-improvement 向け `trace_note` / `signal_linkage_note` / `comparison_eligibility_note` 供給確認
- paper-interface が evaluation 経由を維持することの smoke check

含めること:

- artifact ref integrity check
- optional vs standard intake distinction

完了条件:

- downstream design で前提にした artifact が実際に出力される
- paper convenience のために runtime rule を逆流的に変えない

### Task 11: Add fixtures and mechanical tests for v2

目的:

- v2 実装の最低限の機械的健全性を確認できるようにする

作業:

- minimal manifest fixture
- intent / spec / implementation track fixture
- invalidation fixture
- comparison-ineligible fixture
- writer compatibility fixture

を追加する。

テスト対象:

- contract completeness
- manifest resolution
- candidate generation shape
- compatibility artifact emission
- validator / comparison note emission

完了条件:

- v2 path の最小 smoke check が repo 内で回せる
- downstream feature が fixture を再利用できる

### Task 12: Execute phase-field pilot rerun through v2

目的:

- 置換後の v2 が最初の固定 case で再取得できることを確認する

作業:

- `phase-field` implementation / spec / intent 関連 pilot rerun
- `single_review` / `dual_reviewer_workflow` rerun
- generated artifact shape と previous pilot shape の比較

含めること:

- rerun register
- failure capture
- artifact diff summary

完了条件:

- `phase-field` pilot が v2 path で再取得できる
- major artifact omission がない

### Task 13: Reacquire comparison outputs and record replacement outcome

目的:

- v2 replacement 後に比較出力と置換結果を再固定する

作業:

- comparison summary 再取得
- metrics snapshot 再取得
- replacement outcome note 作成
- `ECL` mandatory removal completion check

含めること:

- old heuristic path との差分要約
- remaining reopen item register
- main evidence 未昇格の確認

完了条件:

- v2 replacement の first validation result が artifact として残る
- `main evidence` へ飛ばず、pilot reacquisition 完了までを閉じられる
