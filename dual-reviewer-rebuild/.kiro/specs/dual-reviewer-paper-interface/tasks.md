# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-paper-interface` を implementation 可能な作業単位へ落とした task plan である。承認済み requirements.md（Requirement 1〜6）と design.md から全面再導出した。

`paper-interface` は evaluation が生成した analysis artifact を paper-facing artifact に変換する reporting interface layer である。manuscript authoring そのものではなく、論文化に必要な structured reporting input を整える。paper convenience は reproducibility と validity に従属し、runtime/evaluation を支配しない。本 task は次の順で作る。

- `paper/` directory skeleton
- reference format（構造化参照）共通基盤
- claim mapping model
- evidence register model（maturity・provenance・review-mode）
- figure / table bundle model
- caveat and limitation model
- reporting fragment model
- separation rules（逆流禁止・無声昇格禁止・stale 再生成）
- テスト

## 2. 実装順序

1. `paper/` directory skeleton を確定する
2. reference format（`*_ref`/`*_refs` 構造化参照）共通基盤
3. claim mapping model（claim unit、supporting source 限定）
4. evidence register model（maturity 束縛規則、provenance、review-mode、supersession）
5. figure / table bundle model
6. caveat and limitation model
7. reporting fragment model（保守的成熟度集約）
8. separation rules（no reverse control / no silent strengthening / stale upstream regeneration）
9. テスト

理由（design「Architecture」より）:

- claim mapping → reporting bundle → caveat attachment → export の 4 段
- reference format は全モデル共通のため先に固定する
- stale 再生成は evaluation の staleness 伝播を入力起点とするため後段に置く

## 3. Tasks

### Task 1: `paper/` directory skeleton を確定する

根拠: Requirement 2 受入 3、design「Paper Artifact Layout」「Placement Rationale」。

作業:

- 正本出力先を固定する（design「Paper Artifact Layout」）。
  - `reports/{claim_map.json,evidence_register.json,reporting_fragments.json}`
  - `tables/table_source_bundle.json`
  - `figures/figure_source_bundle.json`
  - `caveats/paper_caveat_register.json`
- paper-facing artifact を raw evidence と core evaluation output から分離する（Requirement 2 受入 3）。

完了条件:

- caveat がどこに残るか説明できる（design Completion Criteria 第 3 項）
- paper-facing artifact が `paper/` 配下に分離されている

### Task 2: reference format 共通基盤を作る

根拠: Requirement 1 受入 5、design「Claim Mapping Model §3 Reference Format」。

作業:

- `*_ref`（単数）/ `*_refs`（複数）系フィールド（`supporting_artifact_refs` / `caveat_refs` / `provenance_refs` / `source_analysis_manifest_ref` / `input_run_set_ref` 等）を構造化参照とする（design §3）。
  - `ref_type`: 参照先 artifact 種別
  - `target_path`: repo 相対パス（基準ディレクトリ起点。基準は claim mapping の supporting source 解決規約と整合）
  - `target_id`: artifact 内安定識別子（任意）
- 裸のパス文字列・裸の識別子・basename / filename 部分一致を正本判定に使わない（Requirement 1 受入 5、design §1・§3）。クロスドキュメント追跡を機械的に検証可能にする。

完了条件:

- claim-to-evidence と caveat linkage が構造化参照で機械検証できる
- basename 部分一致に依存しない

### Task 3: claim mapping model を作る

根拠: Requirement 1（受入 1〜6）、Requirement 4 受入 1、design「Claim Mapping Model §1〜§2」。

作業:

- claim を 1 artifact 単位で扱う。claim は claim-to-evidence 対応付けの単位となる paper-facing 言明で、最低限 identifier と明示的 evidence source 結合を持つ（Requirement 1 受入 6、design §1）。
- `reports/claim_map.json` の各 entry に `claim_id` / `claim_text` / `supporting_artifact_refs` / `maturity_label` / `caveat_refs` / `provenance_refs` を持たせる（Requirement 1 受入 1・2、design §1）。
- supporting artifact source を `experiments/analysis/` 相対で解決し標準 source に限定する（design §2、foundation 要件 4 受入 4）。`comparisons/treatment_comparisons.json` / `comparisons/phase_comparisons.json` / `classifications/exclusion_report.json` / `caveats/caveat_register.json` / 必要に応じ `metrics/*.json`。runtime raw artifact を一次入力にしない（Requirement 1 受入 4、Requirement 4 受入 1）。
- evaluation output が存在しない場合は生ログにフォールバックせず evaluation プロセス実行を要求する（Requirement 1 受入 4、design Design Drivers）。
- direct evidence と caveated / preliminary evidence を区別する（Requirement 1 受入 3）。versioned evidence に辿れない claim-supporting artifact を許さない（受入 5）。

完了条件:

- claim と evidence source の対応を説明できる（design Completion Criteria 第 1 項）
- 全 claim が versioned evidence に辿れる
- 証拠追跡性の機械検証が Task 9 の決定的検証ケースで pass する

### Task 4: evidence register model を作る

根拠: Requirement 5（受入 1〜6）、Requirement 6（受入 1〜5）、Requirement 1 受入 2、design「Evidence Register Model §1〜§3」。

作業:

- evidence maturity label を `mature` / `preliminary` / `exploratory` で実装する（design §1）。`caveated` は maturity label でなく `caveat_refs` で表現し、mature かつ caveat 保持を表せるようにする。
- `maturity_label` を foundation `evidence_class`（valid/invalid/exploratory、foundation 要件 6 受入 8 所有）に束縛された派生分類とし、Requirement 1・3・5 で同一語彙を用いる（Requirement 5 受入 6、design §1）。束縛規則: `evidence_class=invalid` は paper-facing 対象外、`evidence_class=exploratory`→`maturity_label=exploratory`、`evidence_class=valid` は安定比較集合なら `mature` そうでなければ `preliminary`。foundation 由来フィールドを再定義しない。
- `reports/evidence_register.json` の各 entry に `artifact_ref` / `source_analysis_manifest_ref` / `input_run_set_ref` / `evidence_class` / `review_mode` / `maturity_label` / `caveat_refs` / `supersedes` / `superseded_by` / `generated_at` を持たせる（Requirement 1 受入 2、Requirement 5 受入 5、design §2）。
- review-mode provenance を保持する（Requirement 6 受入 1、design §3）。手動由来と runtime 由来を分離報告でき混在を強制しない（受入 2）。手動レビュー記録を明示ラベルなしに runtime 産出証拠として提示しない（受入 3）。早期手動証拠→後 runtime 証拠の置換系譜を `supersedes` / `superseded_by` で保存する（Requirement 5 受入 5、Requirement 6 受入 5）。
- stable comparison set 由来か exploratory analysis 由来かを保持する（Requirement 5 受入 2）。mixed-maturity 報告は区別が見える場合のみ許可し、mature と preliminary を未分化 artifact に潰さない（受入 3・4）。後の refinement/replacement に必要な traceability を保持する（受入 5）。

完了条件:

- mature / preliminary / exploratory の扱いを説明できる（design Completion Criteria 第 2 項）
- `maturity_label` が foundation `evidence_class` に束縛され Requirement 1・3・5 で同一語彙
- 無声昇格検出・review_mode 混在 caveat 検証が Task 9 の決定的検証ケースで pass する
- Task 4 作業項目は Requirement 5 受入 1〜6・Requirement 6 受入 1〜5・Requirement 1 受入 2 に対応（maturity label＝Req5 受入 1・2／evidence_class 束縛＝Req5 受入 6／provenance fields＝Req1 受入 2・Req5 受入 5／review-mode＝Req6 受入 1〜5／supersession＝Req5 受入 5・Req6 受入 5）

### Task 5: figure / table bundle model を作る

根拠: Requirement 2（受入 1・2・4・5）、design「Figure and Table Bundle Model §1〜§2」。

作業:

- `tables/table_source_bundle.json` に `table_id` / `source_artifact_refs` / `field_projection` / `maturity_label` / `caveat_refs` を持たせる（design §1）。
- `figures/figure_source_bundle.json` に `figure_id` / `source_artifact_refs` / `plot_contract` / `maturity_label` / `caveat_refs` を持たせる（design §2）。`plot_contract` は描画でなく、どの slice / metric / grouping を使うかの reporting-side definition とする。
- figure/table source artifact の required field を定義し evaluation output への provenance linkage を要求する（Requirement 2 受入 1・2）。upstream evaluation output 不変なら再生成可能にする（受入 4）。formatting 都合のみで runtime/foundation schema 変更を強制しない（受入 5、Requirement 4 受入 2）。

完了条件:

- figure/table bundle が evaluation output への provenance linkage を持つ
- formatting 都合で下層 schema 変更を強制しない

### Task 6: caveat and limitation model を作る

根拠: Requirement 3（受入 1〜5）、design「Caveat and Limitation Model」。

作業:

- evaluation の `caveat_register.json` を継承しつつ paper-facing 説明単位へ再配置する（design）。`paper/caveats/paper_caveat_register.json` に `caveat_id` / `source_caveat_ref` / `applies_to_claim_refs` / `applies_to_artifact_refs` / `limitation_type` / `narrative_note` を持たせる。`narrative_note` は manuscript 本文でなく structured note とする。
- `limitation_type` enum を Requirement 3 受入 2 の 3 分類を正準値として実装する: `invalid_data_exclusion` / `partial_evidence` / `methodological_limitation`。
- evidence source に紐づく caveat metadata を保持する（Requirement 3 受入 1）。paper-facing summary が raw archive 手読みなしに caveat 参照できる（受入 3）。意図的不完全 evidence に preliminary labeling を支援する（受入 4）。caveated evidence を silent に strong evidence へ格上げしない（受入 5、Requirement 3 受入 2 の区別保持）。

完了条件:

- invalid-data exclusion / partial evidence / methodological limitation が区別される
- caveated evidence が silent に格上げされない

### Task 7: reporting fragment model を作る

根拠: Requirement 5 受入 3・4、design「Reporting Fragment Model」「Key Decision 3」。

作業:

- `reports/reporting_fragments.json` の各 fragment に `fragment_id` / `fragment_type` / `source_artifact_refs` / `maturity_label` / `caveat_refs` / `text_stub` を持たせる（design）。`fragment_type` 例: `claim_summary` / `method_note` / `limitation_note` / `comparison_summary`。manuscript そのものにしない（Decision 3）。
- 複数出典 fragment の成熟度集約規則を実装する（design）。`maturity_label` は出典の最も保守的な値（`exploratory` < `preliminary` < `mature`、1 つでも低ければ全体をその値に）。出典ごとの成熟度区分を fragment 内に保持し束ねても見えなくしない（Requirement 5 受入 3）。成熟度の異なる出典を単一未分化値に圧縮しない（受入 4）。集約値は保守表示であり出典別 maturity の保持を代替しない。

完了条件:

- fragment が保守的成熟度集約をしつつ出典別 maturity を保持する

### Task 8: separation rules を強制する

根拠: Requirement 4（受入 1〜5）、Requirement 2 受入 6、design「Separation Rules §1〜§4」。

作業:

- no reverse control: runtime field 追加要求を独自に出さない、invalid run を valid evidence に格上げしない、evaluation comparison rule を独自上書きしない（Requirement 4 受入 1・2・3、design §1）。invalidation policy を override しない（受入 3）。paper convenience を reproducibility/validity に従属させる（受入 4）。
- no silent strengthening: preliminary / exploratory evidence を paper artifact 生成時に mature と同列に扱わない（design §2）。
- self-improvement independence: self-improvement proposal を claim support artifact にしない。adopted change 履歴は methodology note 参照に留め performance claim の一次根拠にしない（design §3）。
- stale upstream regeneration: 上流 evaluation output が run 無効化により stale 扱いされた場合、出力変化時だけでなく上流陳腐化時にも paper-facing artifact を再生成対象とする（Requirement 2 受入 6、design §4）。paper-facing artifact（evidence_register entry / reporting fragment / bundle manifest）に陳腐化標識 `stale` / `stale_reason` / `stale_source_ref`（foundation 要件 6 受入 9 の伝播を受ける）を持たせる。`stale=true` は paper-facing 用途前に再生成対象。標識付与は上流 evaluation 由来の陳腐化伝播を受けて行い、再生成の自動起動主体・タイミングは実装委譲（本タスクは信号表現契約のみ固定）。
- downstream narrative transformation を explicit かつ versionable にする（Requirement 4 受入 5）。

完了条件:

- paper-interface が runtime/evaluation を支配しないことを説明できる（design Completion Criteria 第 4 項）
- stale 上流時に paper-facing artifact が再生成対象になる
- stale 再生成検出が Task 9 の決定的検証ケースで pass する

### Task 9: テストを用意する

根拠: design「Test Strategy」、プロジェクト開発方針（TDD）。

作業:

- 証拠追跡性の機械検証: claim_map の `supporting_artifact_refs` / `provenance_refs` が Reference Format に従い参照先 artifact まで machine 解決できる（Requirement 1 受入 5）。
- 無声昇格の検出: preliminary / exploratory evidence が mature と同列に paper artifact へ入っていないことを `maturity_label` と束縛規則で検証（Separation Rules 2）。
- 混在レビュー実施モードの caveat 検証: report set 参照 evidence_register の `review_mode` が 2 値以上のとき caveat 付与を検証（Requirement 6 受入 4）。
- 陳腐化再生成の確認: `stale=true` の paper-facing artifact が再生成対象として検出される（Requirement 2 受入 6）。
- TDD: 期待入出力に基づき先にテストを用意し失敗を確認してから実装する。

完了条件:

- design Test Strategy 4 点が検証できる
- design Completion Criteria 4 点を満たす
- 列挙 4 検証対象（証拠追跡性／無声昇格／混在 review_mode caveat／陳腐化再生成）それぞれに固定入力→期待出力の決定的検証ケースが 1 つ以上存在し pass する（着手前に客観基準を確定、TDD 先行）

## 4. Downstream Handoff

paper-interface は evaluation の主要 consumer であり下流に成果物を渡さない（design Interfaces）。読む対象: `analysis_run_manifest.yaml` / `treatment_comparisons.json` / `phase_comparisons.json` / `exclusion_report.json` / `caveat_register.json`（必要なら `input_run_set` 対応の protocol-facing validation summary を provenance convenience として追加 intake 可）。self-improvement adopted history は system revision history 参照に留め runtime quality claim の一次根拠にしない。runtime とは直接結合しない。

## 5. Blocking Dependencies

phase-and-feature-dependency-map §5.3 に従い、paper-interface bundle 実装は evaluation comparison artifact の field naming 確定後に作る。

- Task 3〜7 は evaluation の comparison / exclusion / caveat artifact 確定が前提
- Task 4 の foundation `evidence_class`・`review_mode` 語彙確定が前提
- Task 8 の evaluation staleness 伝播（foundation 要件 6 受入 9 起点）確定が前提
- Task 3 の claim ID taxonomy 形式化範囲、Task 8 の adopted change history methodology note 参照範囲は design alignment open issue 解決後に確定（tasks alignment gate で詰める）
- evaluation comparison artifact field naming は design alignment open issue 未解決のため tasks alignment gate の横断議題であり、確定値は alignment gate で詰める（evaluation tasks.md §5 と双方向整合）

### 5.1 Task 間依存グラフ（§2 から導出。並列可を明示）

- Task 1（paper skeleton）が起点 → Task 2（reference format、全モデル共通 hub）。
- Task 2 → {Task 3（claim mapping）, Task 4（evidence register）}（Task 3 と Task 4 は Task 2 後に並行着手可）。
- Task 4 → Task 5（figure/table bundle、maturity 参照）→ Task 6（caveat、claim_refs 参照）→ Task 7（reporting fragment、Task 3/4/6 出典参照）→ Task 8（separation rules、全モデルに stale 標識付与）。
- Task 9（テスト）は全 Task と並走（TDD 先行）。
- 外部前提：Task 3〜7＝evaluation comparison/exclusion/caveat 確定、Task 4＝foundation `evidence_class`/`review_mode` 確定、Task 8＝evaluation staleness 伝播確定が blocking（上記）。

### 5.2 失敗時の巻き戻し単位

- Task 1/2/5/6/7 は task-local 吸収（handback A）。
- Task 3〜7 で evaluation comparison/exclusion/caveat artifact contract 不足が判明したら handback C で evaluation へ。
- Task 4 で foundation `evidence_class`/`review_mode` 語彙不足なら handback C で foundation へ。
- Task 8 で evaluation staleness 伝播（foundation 要件 6 受入 9 起点）不足なら handback C で foundation/evaluation へ。
- claim ID taxonomy（Task 3）/ adopted change history 範囲（Task 8）が design open issue 未確定で詰まれば handback B で design へ。判定に迷う場合は保守規律により上流 C へ寄せる。
- raw evidence・core evaluation output 不変、paper convenience 従属（design Separation Rules）により実行時の巻き戻しは paper-facing artifact 再生成に閉じ raw/core evaluation output を編集しない。

## 6. Completion Criteria

design「Completion Criteria」に従い、少なくとも次を満たすとき本 task plan は有効とみなす。

- claim と evidence source の対応を説明できる
- mature / preliminary / exploratory の扱いを説明できる
- caveat がどこに残るか説明できる
- paper-interface が runtime/evaluation を支配しないことを説明できる
