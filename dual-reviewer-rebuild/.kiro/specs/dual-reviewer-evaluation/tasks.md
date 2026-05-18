# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-evaluation` を implementation 可能な作業単位へ落とした task plan である。承認済み requirements.md（Requirement 1〜10）と design.md から全面再導出した。

`evaluation` は runtime artifact を読み、valid / invalid / exploratory / analysis_blocked の区分、比較可能な metrics、caveat 付き分析 artifact に変換する analysis layer である。raw run evidence を編集せず `experiments/analysis/` に derived artifact を生成する。本 task は次の順で作る。

- analysis artifact directory skeleton
- intake（local run + portable bundle）
- classification（4 状態 + admission state）
- metric extraction（3 tier + phase overlay）
- comparison（treatment / phase-aware）
- exclusion / caveat reporting
- imported evidence intake artifacts（ingestion / admission register）
- versioning と staleness 伝播
- テスト

## 2. 実装順序

1. `experiments/analysis/` directory skeleton を確定する
2. intake model（local + portable bundle）
3. classification model（valid / invalid / exploratory / analysis_blocked、admission state、設計スキップ弁別）
4. metric extraction（3 tier、core + phase overlay、derivation rule）
5. comparison model（treatment、phase-aware、valid population rule、比較可能性条件）
6. exclusion / caveat reporting
7. imported evidence intake artifacts（ingestion / admission register）
8. versioning と staleness 伝播
9. テスト

理由（design「Architecture」「Interfaces to Downstream Features」より）:

- intake → classification がないと metric / comparison が成立しない
- comparison 可能性条件と caveat がないと paper-interface / self-improvement が再利用できない
- staleness 伝播は foundation 無効化伝播義務を入力起点とするため classification 確定後に置く

## 3. Tasks

### Task 1: `experiments/analysis/` directory skeleton を確定する

根拠: Requirement 5（受入 1・3）、design「Analysis Artifact Layout」「Placement Rationale」「Key Decision 1」。

作業:

- 正本出力先を固定する（design「Analysis Artifact Layout」）。
  - `imports/{ingestion_register.json,admission_register.json}`
  - `manifests/analysis_run_manifest.yaml`
  - `classifications/{run_classification_index.json,exclusion_report.json}`
  - `metrics/{run_metrics.json,finding_metrics.json,treatment_metrics.json}`
  - `comparisons/{treatment_comparisons.json,phase_comparisons.json}`
  - `caveats/caveat_register.json`
- analysis artifact を raw run evidence storage から分離する（Requirement 5 受入 3、Decision 1：evaluation は run artifact を mutate しない）。

完了条件:

- raw run と analysis artifact の境界を説明できる（design Completion Criteria 第 1 項）
- derived output が `experiments/analysis/` に分離されている

### Task 2: intake model を作る

根拠: Requirement 6（受入 1〜5）、Requirement 10（受入 1〜3）、design「Intake Model」「Portable Bundle Intake」「Analysis Population Selection」。

作業:

- local run の最小 intake artifact を読む: `run_manifest.yaml` / `review_case.json` / `decisions/decision_units.json` / `validation/validator_result.json` / `validation/invalidation_markers.json` / `derived/comparison_eligibility_note.json`（design Intake Model）。standard aggregate の一次入力は `review_case.json` と validation artifact とし、`steps/*.json` は必要時のみ読む。
- v2-compatible optional intake（`v2/review_artifact.json` / `v2/metric_snapshot.json` / `v2/trace_note.json`）を読めなくても standard analysis が成立する設計にする（design）。
- portable bundle intake の最小入力（`bundle_manifest.yaml` + exported run_manifest/review_case/decision_units/validator_result/invalidation_markers/comparison_eligibility_note）を受ける（Requirement 10 受入 1）。required provenance 欠落時は intake 継続しても standard admission を与えない（design Portable Bundle Intake）。
- standard aggregation 前に必須 metadata を check し、欠落時は standard aggregation を拒否、insufficiency diagnostics を明示する（Requirement 6 受入 1〜3）。narrative から欠落 metadata を捏造しない（受入 5）。
- analysis population を再現可能な selection policy で選ぶ（`run_status=closed` / standard intake complete / protocol-facing validation summary available / 同一 case_id・phase_profile 内で比較 treatment が揃う）。selection manifest と refresh workflow に落とせる形にする（design Analysis Population Selection）。

完了条件:

- 必須 metadata 不足時に standard aggregation が fail fast し insufficiency diagnostics を出す
- portable bundle が required provenance 不足では standard admission を得ない

### Task 3: classification model を作る

根拠: Requirement 1（受入 1〜6）、Requirement 9（受入 1〜6）、Requirement 10（受入 4・5）、Requirement 2 受入 3、design「Classification Model §1〜§4」「Admission States for Imported Bundles」。

作業:

- run を 4 状態 `valid` / `invalid` / `exploratory` / `analysis_blocked` で分類する（design §1）。`analysis_blocked` は foundation evidence_class ではなく evaluation local state（design §1、Decision 2）。
- classification rules を実装する（design §2）。`valid`=validator_status passed かつ human_signoff 終端かつ evidence_class valid、`invalid`=invalidation marker あり or validator_status failed、`exploratory`=evidence_class exploratory、`analysis_blocked`=required input 不足 or run_status≠closed or validator_status blocked。`analysis_blocked` は exclusion report に出すが比較集団に入れない（Requirement 1 受入 1・2）。
- missing と invalid を区別する（Requirement 1 受入 4、design §3）。
- `comparison_eligibility_note.json` を classification 前の補助判断材料として読んでよいが final 判定は metadata / validator / invalidation を基礎にする。スキーマは runtime 所有、evaluation は最小項目に依存し再定義しない（評価 A-7 決定、design §2 末尾）。
- 有効性分類（valid/invalid/exploratory）と review-mode（manual_dogfooding/runtime_mediated）を直交独立軸として扱う。manual_dogfooding の内容的 valid run を review-mode 理由で invalid 誤分類しない（Requirement 1 受入 6、Requirement 9 受入 1）。review-mode による標準集団切り分けは別の slice 操作とする（Requirement 9 受入 2・4・5）。
- review-mode の standard comparison-population rule を evaluation が所有する: manual dogfooding は Phase 1 evidence で、明示的 separate slice として含めない限り standard runtime-mediated comparison set から除外する（Requirement 9 受入 6）。通常編集活動を manual review record contract 経由でなければ valid review evidence にしない（受入 3）。
- imported bundle の admission state（`admitted_standard` / `admitted_exploratory` / `rejected`）は Task 7 が単一所有者として判定・`imports/admission_register.json` に記録する。本 Task はその admission status を classification 前段の入力として参照し、再判定しない（Requirement 10 受入 4、design Admission States）。admission state を run validity と別に保持する（受入 5）。
- 設計スキップ vs 障害欠損を runtime の step 実行印（`execution_state` / `reason` / `treatment`）で弁別する（Requirement 2 受入 3、design §4）。設計上の意図的省略を障害扱いで母集団から誤排除しない（runtime 要件 2 受入 5 と整合）。

完了条件:

- valid / invalid / exploratory / analysis_blocked の違いを説明できる（design Completion Criteria 第 2 項）
- review-mode と run-validity が直交軸として扱われる
- classification / admission / 設計スキップ弁別が Task 9 の決定的検証ケースで pass する

### Task 4: metric extraction を作る

根拠: Requirement 3（受入 1〜5）、Requirement 8（受入 1〜5）、Requirement 7（受入 1・4）、design「Metric Model §1〜§3」「Phase-Specific Metric Overlays」。

作業:

- metric を 3 tier（run-level / finding-level / treatment-level）に分離する（Requirement 3 受入 5、design §1）。
- 初版 minimum metric set を実装する（design §2）。run-level=total/accepted/rejected/deferred findings + validation outcome、finding-level=severity/source-role/judgment label distribution、treatment-level=findings per run/acceptance ratio/judgment invocation coverage。foundation / runtime に追加 field を要求しない範囲で始める。
- phase 共通 core metric layer と phase ごとの overlay metric layer の 2 層構造にする（Requirement 8 受入 1〜5、design §2・§2.5）。overlay は intent/requirements/design/tasks（+ future implementation-oriented）ごとに別観点。design 中心 baseline を全 phase 主指標と見なさない。phase-specific metric selection を derived artifact に明示する（Requirement 8 受入 4、Requirement 7 受入 4）。entire evaluation contract の再設計なしに implementation-oriented review へ拡張可能にする（受入 5）。
- derivation rule: free-form summary からでなく metadata → structured findings → decision units → validation/invalidation の順で計算する（Requirement 3 受入 2、design §3）。`derived/runtime_summary.json` を metric の正本入力にしない。
- raw evidence → derived metric の derivation path を保持し、schema 互換 raw evidence 不変なら再計算可能にする（Requirement 3 受入 3・4）。

完了条件:

- metrics がどこに出るか説明できる（design Completion Criteria 第 3 項）
- core / phase overlay の 2 層が derived artifact から追跡できる
- metric 導出（core / phase overlay）が Task 9 の決定的検証ケースで pass する

### Task 5: comparison model を作る

根拠: Requirement 2（受入 1〜6）、Requirement 7（受入 2・3・5）、design「Comparison Model §1〜§3」。

作業:

- treatment comparison（`single` / `dual` / `dual+judgment`）を実装する（Requirement 2 受入 1・2、design §1）。比較前に target condition 一致 / phase-profile 比較可能 / protocol・runtime・prompt・schema version 比較可能 / `comparison_eligibility_note` の不可理由を先に尊重、を確認する。
- protocol-version と prompt-version の uniformity を比較可能性条件として要求し、per-run metadata が揃っていても version 混在 comparison set を検出・報告する（Requirement 2 受入 6）。不一致は `comparison_invalid_reason` を出し aggregate しない（受入 5）。treatment-driven step omission と runtime failure を区別する（受入 3）。treatment identity を comparison-relevant derived output 全てに見せる（受入 4）。
- phase-aware comparison の標準 slice（intent/requirements/design/tasks）を実装する（Requirement 7 受入 3、design §2）。phase identity を消さず保持し phase-specific overlay 選択を明示する。phase-distinct run を default で 1 集約に潰さない（Requirement 7 受入 5）。
- valid population rule: 標準 comparative metrics は `valid` population のみで計算し、`exploratory` は separate appendix-style aggregate として保持、主比較に混ぜない（design §3、Decision 3）。

完了条件:

- 比較可能性条件（target / phase / version / eligibility）を満たさない set が aggregate されない
- valid population のみで標準比較が計算される
- 比較可能性条件と valid population rule が Task 9 の決定的検証ケースで pass する

### Task 6: exclusion / caveat reporting を作る

根拠: Requirement 4（受入 1〜5）、Requirement 1 受入 3、design「Exclusion and Caveat Model」「Key Decision 4」。

作業:

- `classifications/exclusion_report.json` を作る（`run_id` / `classification` / `reason_codes` / `reason_details` / `phase_profile` / `treatment`）。どの run がなぜ除外されたか記述する（Requirement 4 受入 1、design §1）。除外 run の counts と reasons を保持する（Requirement 1 受入 3、Requirement 4 受入 4：raw run log 手読みなしに exclusion counts を報告可能）。
- `caveats/caveat_register.json` を作る（mixed maturity evidence / exploratory only slice / low sample size / protocol drift across comparison set など）。paper-interface が raw archive 再読なしに caveat 継承できる形にする（Requirement 4 受入 2、design §2）。
- data-quality caveat と runtime-quality caveat を区別する（Requirement 4 受入 3）。invalid と valid population を silent に 1 集約へ潰さない（Requirement 4 受入 5、Decision 4）。

完了条件:

- exclusion counts を raw log 手読みなしに報告できる
- caveat が machine-readable first-class artifact として残る

### Task 7: imported evidence intake artifacts を作る

根拠: Requirement 10（受入 2〜5）、design「Imported Evidence Intake Artifacts」。

作業:

- `imports/ingestion_register.json` を作る（`bundle_id` / `run_id` / `source_repository_id` / `source_revision` / `review_mode` / `ingested_at` / `ingestion_status` / `missing_fields`）。
- `imports/admission_register.json` を作る（`bundle_id` / `run_id` / `admission_status` / `admission_reason_codes` / `eligible_for_standard_comparison` / `eligible_for_exploratory_analysis`）。
- admission 前に required provenance を validate する（Requirement 10 受入 2）。imported runtime-mediated bundle と manual dogfooding session を区別する（受入 3）。reject / downgrade-to-exploratory / admit を明示 admission rule で判定する（受入 4）。本 Task が admission 判定の単一所有者であり、判定結果を `imports/admission_register.json` に記録する。Task 3 は本 Task の admission status を参照のみ（再判定しない）。どの derived artifact が imported evidence をどの admission status で含むか保持する（受入 5）。

完了条件:

- imported evidence が raw local run と区別されたまま扱える
- admission status と reason codes が register に残る

### Task 8: versioning と staleness 伝播を作る

根拠: Requirement 5（受入 5・6）、Requirement 5 受入 2、design「Versioning Model」。

作業:

- analysis artifact を versioned output とする。`manifests/analysis_run_manifest.yaml` に `analysis_logic_version` / `input_run_set` / `generated_at` / `metric_set_version` / `phase_metric_profile_version` / `comparison_contract_version` を記録する（Requirement 5 受入 5、design Versioning Model）。同一 raw run set でも analysis logic が変われば別 output 扱い。
- derived output から run identifier / target identifier への linkage を保持する（Requirement 5 受入 2）。
- 参照していた run が事後に invalidate された場合、その run を入力に含む derived artifact を stale フラグ付け、または再導出する（Requirement 5 受入 6、design）。invalidation を含む run の上に古い derived output を据え置かない。foundation 無効化伝播義務（foundation 要件 6 受入 9）を入力起点とする。

完了条件:

- analysis logic 変更時に artifact versioning が見える
- 事後 invalidate された run を含む derived artifact が stale 化または再導出される
- staleness 伝播（事後 invalidate → derived stale 化）が Task 9 の決定的検証ケースで pass する

### Task 9: テストを用意する

根拠: design「Completion Criteria」、プロジェクト開発方針（TDD）。

作業:

- classification rules / admission rules / 設計スキップ弁別を固定入力で決定的に検証する。
- metric derivation を固定 structured evidence で入出力対応検証する（free-form 非依存）。
- comparison 可能性条件（version 混在検出含む）と valid population rule を検証する。
- staleness 伝播（事後 invalidate → derived stale 化）を検証する。
- TDD: 期待入出力に基づき先にテストを用意し失敗を確認してから実装する。

完了条件:

- design Completion Criteria 4 点（境界説明・4 状態説明・metrics/caveat 所在説明・downstream 追跡）を満たす
- 列挙 4 検証対象（classification・admission／metric 導出／比較可能性・valid population／staleness 伝播）それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass する（着手前に客観基準を確定、TDD 先行）

## 4. Downstream Handoff

evaluation tasks 完了後に downstream が読んでよい artifact（design「Interfaces to Downstream Features」）。本節は Requirement 5 受入 4（self-improvement・paper-interface の双方が消費可能）を満たす。

- self-improvement: `run_classification_index.json` / `exclusion_report.json` / `run_metrics.json` / `finding_metrics.json` / `caveat_register.json`（特に invalid / exploratory 分布）
- paper-interface: `treatment_comparisons.json` / `phase_comparisons.json` / `exclusion_report.json` / `caveat_register.json`（raw run directory を一次入力にしない）

## 5. Blocking Dependencies

phase-and-feature-dependency-map §5.3 に従い、次は先行成果物が固まるまで blocked。

- Task 2/3 は runtime export manifest shape と `comparison_eligibility_note.json`（runtime 所有スキーマ）確定が前提
- Task 2 の foundation metadata contract / evidence_class 確定が前提
- Task 8 の foundation 無効化伝播義務確定が前提
- evaluation comparison artifact field naming 確定が paper-interface bundle task の前提（後段 alignment で詰める）
- `treatment_comparisons.json` / `phase_comparisons.json` の field naming 確定は tasks alignment gate の横断議題（design open issue。確定値は alignment gate で詰める）
- Task 4 の phase-specific overlay 初版集合は design alignment open issue 解決後に確定（tasks alignment gate で詰める）

### 5.1 Task 間依存グラフ（§2 から導出。並列可を明示）

- Task 1（analysis skeleton）が起点。
- Task 2（intake）→ Task 3（classification）→ Task 4（metric）→ Task 5（comparison）→ Task 6（exclusion/caveat）。
- Task 7（imported intake artifacts。admission 判定の単一所有）は Task 2 後に着手可。Task 3 は Task 7 の admission status を参照（Task 7 → Task 3 の一方向）。
- Task 8（versioning/staleness）は Task 3（classification 確定）後。
- Task 9（テスト）は全 Task と並走（TDD 先行）。
- 外部前提：Task 2/3 は runtime export shape・`comparison_eligibility_note.json`（runtime 所有）確定、Task 2 は foundation metadata/evidence_class 確定、Task 8 は foundation 無効化伝播義務確定が blocking（上記）。

### 5.2 失敗時の巻き戻し単位

- Task 1/6/7 は task-local 吸収（handback A）。
- Task 2/3 で実行側 export shape または `comparison_eligibility_note.json` 最小項目不足が判明したら handback C で実行側へ。
- Task 2 で foundation metadata contract / evidence_class 不足なら handback C で foundation へ。
- Task 4 の phase-specific overlay 初版集合が固められず詰まった場合：要件 8（phase-specific effectiveness metrics）が十分で設計の初版確定だけが未了なら handback B（design へ）、要件 8 自体が overlay を導けるほど取り決めていないなら handback C（requirements へ）、判定に迷う場合は保守規律により C（上流）へ寄せる。
- Task 8 で foundation 無効化伝播義務不足なら handback C で foundation へ。
- raw 不変原則（design Decision 1）により実行時の巻き戻しは derived artifact 再生成に閉じ raw を編集しない。

## 6. Completion Criteria

design「Completion Criteria」に従い、少なくとも次を満たすとき本 task plan は有効とみなす。

- raw run と analysis artifact の境界を説明できる
- valid / invalid / exploratory / analysis_blocked の違いを説明できる
- metrics と caveat がどこに出るか説明できる
- self-improvement と paper-interface がどの analysis artifact を読むか追跡できる
- review-mode と run-validity が直交軸として扱われ、`comparison_eligibility_note.json` を runtime 所有スキーマとして参照する（評価 A-7）
