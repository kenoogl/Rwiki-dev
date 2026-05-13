# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-runtime` を implementation 可能な作業単位へ落とした task plan である。

`runtime` は foundation contract の consumer であり、

- review session orchestration
- run artifact emission
- validator invocation
- portable evidence bundle export

を concrete に実装する。

## 2. 実装順序

1. runtime skeleton と `execution_v2` entrypoint を揃える
2. track-aware case manifest / heuristic fallback / generic entrypoint rule を実装する
3. run metadata / review_case emission と `v2/` internal artifact path を実装する
4. Step A/B/C/D artifact emission を実装する
5. decision unit と human sign-off artifact を実装する
6. run close / validator integration / comparison eligibility emission を実装する
7. portable evidence bundle export を実装する
8. runtime fixtures と tests を追加する

理由:

- evaluation は runtime artifact shape が固まらないと intake task を起こしにくい
- self-improvement は step-level artifact と decision unit がないと replay task を起こせない
- exported bundle は run close 後の artifact に依存する

## 3. Tasks

### Task 1: Create runtime module skeleton and entrypoints

目的:

- review session 実行の骨格を repo 上に作る

作業:

- runtime controller module
- `runtime/execution_v2/` module skeleton
- step executor modules
- evidence writer module
- validation bridge module
- export entrypoint module

の file skeleton を作る。

完了条件:

- runtime implementation の ownership 境界が file レベルで分かれる
- foundation artifact を import する entrypoint が存在する

### Task 2: Implement run metadata loading and initialization

目的:

- foundation metadata contract に従って run 初期化を行う

作業:

- `metadata_contract.yaml` を読む loader を実装
- run 開始時に固定する field
  - `run_id`
  - `target_id`
  - `target_artifact_hash`
  - `source_repository_id`
  - `source_revision`
  - `phase_profile`
  - `treatment`
  - `review_mode`
  - version fields

を `run_manifest.yaml` に初期記録する処理を作る。

完了条件:

- run 開始時 metadata が incomplete なまま進まない
- `review_mode` と cross-project provenance が run 初期状態から保持される

### Task 3: Implement run directory creation and canonical layout

目的:

- `experiments/runs/<run_id>/` の canonical layout を concrete に生成する

作業:

- run directory create
- `steps/`
- `decisions/`
- `v2/`
- `validation/`
- `derived/`

の初期化処理を実装する。

完了条件:

- runtime 実行前に canonical directory shape が作成される
- evaluation / self-improvement が前提にする path が安定する

### Task 4: Implement Step A/B/C/D artifact emission

目的:

- step-level raw evidence を schema-conformant に出力する

作業:

- Step A output writer
- Step B output writer
- Step C output writer
- Step D output writer
- skip marker emission

を実装する。

含めること:

- prompt identity recording
- step status recording
- treatment-based skip distinction

完了条件:

- `steps/*.json` が treatment と phase/profile を保持して出力される
- `single` / `dual` / `dual+judgment` の skip behavior が区別可能

### Task 5: Implement `review_case.json` aggregation

目的:

- run 全体の canonical machine-readable envelope を生成する

作業:

- run metadata aggregation
- step refs aggregation
- finding refs aggregation
- validation / invalidation refs aggregation
- `v2/` internal artifact refs aggregation

を `review_case.json` にまとめる。

完了条件:

- evaluation が step raw body を再解釈せずに一次 intake できる envelope が存在する

### Task 6: Implement decision unit and human sign-off artifacts

目的:

- finding-level human decision と run-level sign-off を分離して保持する

作業:

- `decisions/decision_units.json`
- `decisions/human_signoff.json`

の writer を実装する。

含めること:

- `decision_unit_id`
- `finding_refs`
- `judgment_refs`
- `human_decision`
- `human_decision_timestamp`
- run-level close judgment

完了条件:

- foundation `finding` schema の human linkage と runtime artifact が接続する
- run-level sign-off と decision unit outcome が混線しない

### Task 7: Implement run close and validator integration

目的:

- freeze -> validate -> annotate の順序を concrete に実装する

作業:

- raw evidence freeze
- validator invocation
- `validation/validator_result.json` write
- `validation/invalidation_markers.json` write
- `derived/comparison_eligibility_note.json` write
- `derived/invalid_run_triage_note.json` write
- `run_manifest.yaml` / `review_case.json` metadata update

を実装する。

完了条件:

- validator failure と orchestration failure が区別される
- invalidation marker が raw artifact を書き換えずに追加される
- comparison eligibility が downstream 向け補助 artifact として残る
- invalid-run triage note が failed check / marker / operator hint を machine-readable に残す

### Task 8: Implement portable evidence bundle export

目的:

- local run を central analysis 向け portable bundle にできるようにする

作業:

- `exports/<bundle_id>/` create
- `bundle_manifest.yaml` writer
- exported `run/` subtree copy
- `checksums/bundle_checksums.json` writer

を実装する。

含めること:

- `bundle_id`
- `run_id`
- `source_repository_id`
- `source_revision`
- `review_mode`
- `export_runtime_version`
- `included_artifact_refs`

完了条件:

- export が raw run semantics を変えない
- evaluation 側が intake 可能な bundle shape が生成される

### Task 9: Add runtime fixtures

目的:

- downstream feature と tests が使える sample runtime outputs を用意する

作業:

- minimal local run fixture
- treatment-specific run fixture
- invalid run fixture
- exported bundle fixture

を配置する。

完了条件:

- evaluation intake task が fixture ベースで開始できる
- self-improvement replay task の最低入力が揃う

### Task 10: Add runtime tests and smoke checks

目的:

- runtime artifact emission と export path の最低限の mechanical validation を持つ

作業:

- run directory shape test
- metadata completeness test
- treatment skip marker test
- validator integration smoke test
- portable bundle export smoke test

を追加する。

完了条件:

- runtime から evaluation / self-improvement への handoff 条件が mechanical に確認できる

### Task 11: 削除済み（旧 Implement track-aware case manifest loading and heuristic fallback）

旧 v1 では `heuristic_profile_ref`（規則ファイル参照）の optional field 扱いと、未指定時の track-specific minimal fallback の実装タスクを持っていたが、v2 では規則ファイル参照を撤廃する方針のため、本タスクは削除した。track-aware case manifest validator の設計は v2 取得 spec（`dual-reviewer-rebuild/.kiro/specs/dual-reviewer-v2-acquisition/`）で再設計する。

### Task 12: Remove pilot-case assumptions from generic runtime entrypoints

目的:

- generic runtime path が historical pilot case の hidden default に依存しないようにする

作業:

- `run_*_track_protocol.rb` を explicit input or manifest-required にする
- case basename を generic runtime 条件から外す

完了条件:

- generic protocol wrapper が pilot case 固定値なしで動く

備考：旧 v1 のパターン照合関連の作業（seed pattern cue を structural cue ベースに寄せる、seed pattern matching の case-agnostic 化）は、v2 で取得処理を実 LLM 呼び出しに置き換える方針のため不要となった。詳細は v2 取得 spec（`dual-reviewer-rebuild/.kiro/specs/dual-reviewer-v2-acquisition/`）を参照。

## 4. Downstream Handoff

runtime tasks 完了後に、次の feature が依存してよい artifact は少なくとも次である。

- `experiments/runs/<run_id>/run_manifest.yaml`
- `experiments/runs/<run_id>/review_case.json`
- `experiments/runs/<run_id>/steps/*.json`
- `experiments/runs/<run_id>/decisions/decision_units.json`
- `experiments/runs/<run_id>/v2/*.json`
- `experiments/runs/<run_id>/validation/*.json`
- `experiments/runs/<run_id>/derived/comparison_eligibility_note.json`
- `exports/<bundle_id>/bundle_manifest.yaml`
- `exports/<bundle_id>/checksums/bundle_checksums.json`

## 5. Blocking Dependencies

runtime task 着手前の前提:

- foundation metadata contract が存在する
- foundation schema set が存在する
- foundation validator-facing contracts が存在する

runtime tasks 完了まで blocked とみなす downstream task:

- evaluation の imported bundle intake task
- evaluation の standard admission task
- self-improvement の replay artifact task
- self-improvement の imported provenance task
- paper-interface の imported/local provenance reporting task

## 6. Completion Criteria

- runtime controller と artifact writers の skeleton が存在する
- canonical run directory が生成できる
- `review_case.json` と decision artifacts が出力できる
- validator integration が run close 後に動く
- portable evidence bundle export が実行できる
- downstream feature が runtime output を参照する前提を持てる
