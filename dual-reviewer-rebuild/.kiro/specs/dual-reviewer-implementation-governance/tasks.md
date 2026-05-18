# Tasks

## 1. この文書の役割

この文書は `dual-reviewer-implementation-governance` を implementation 可能な作業単位へ落とした task plan である。承認済み requirements.md（Requirement 1〜8）と design.md から全面再導出した。

`implementation-governance` は implementation completion を「task 完了 + smoke pass」だけで閉じないための governance layer である。所有するのは review logic ではなく review procedure と evidence contract であり、feature logic graph に新しい data producer を追加せず implementation checkpoint に post-stage gate を足す。本 task は次の順で作る。

- 所有 artifact（procedure / metric register / template / validator / gate status / alignment memo / bootstrap）の repo-contained 配置
- workflow 段階（reference-free bootstrap → intent review → smoke → conformance review → checkpoint close）
- finding / handback / signal 接続
- conformance metric register と phase-review metric register
- governance artifact validator と concrete artifact
- cross-spec alignment と reopen propagation

## 2. 実装順序

1. 所有 artifact の配置先 skeleton を確定する
2. conformance review procedure（Stage 1〜4）を定義する
3. intent review stage（Stage 0）と reference-free bootstrap（Stage -1）を定義する
4. review template（intent / conformance）と必須セクション・type 判別を定義する
5. finding model と signal / handback 接続を定義する
6. conformance metric register と phase-review metric register を定義する
7. workflow status model と reopen propagation を定義する
8. cross-spec alignment model を定義する
9. governance artifact validator と concrete artifact を作る
10. テスト

Requirement 9 ぶんの内部実装順序：Task 11（台帳テンプレ・authority-map）→ 12（台帳生成器・既存台帳の扱い）→ 13（独立再導出 validator 拡張）→ 14（enforcement・通過マーカー・fail-closed）→ 15（marker 真正性）→ 16（uniform・reopen・移行）→ 18（テスト）。Task 17（C-1/C-2/C-3 上位文書同期）はタスク人間承認後の文書同期作業として最後に実施。

理由（design「Architecture」「Validation Model」より）:

- procedure と template がないと concrete review artifact が書けない
- validator は template と concrete artifact の存在・必須セクションを確認するため後段
- cross-spec alignment は completion rule を横断変更するため metric/status 確定後に置く

## 3. Tasks

### Task 1: 所有 artifact の配置先 skeleton を確定する

根拠: Requirement 2 受入 1、Requirement 5 受入 2、Requirement 7 受入 2、design「Owned Artifacts」「Boundary Clarification」。

作業:

- governance 所有 artifact の配置を固定する（design「Owned Artifacts」）。
  - `docs/coordination/implementation-conformance-review.md`（procedure）
  - `docs/coordination/implementation-conformance-metric-register.md`（conformance metric）
  - `docs/coordination/phase-review-metric-register.md`（phase-level metric）
  - `docs/reviews/templates/intent-review-template.md`
  - `docs/reviews/templates/implementation-conformance-review-template.md`
  - `docs/reviews/*.md`（concrete intent / conformance review evidence）
  - `scripts/validate_implementation_governance_artifacts.rb`
  - `docs/coordination/workflow-gate-status.md`
  - `docs/alignment/cross-spec-implementation-governance-alignment.md`
  - `scripts/bootstrap_reference_free_case.rb`
  - `.kiro/methodology/dual-reviewer-spec-driven-paper/{reference-free-case-bootstrap-guide.md,implementation-phase-protocol-template.md,implementation-phase-snapshot-template.md}`
- feature spec の artifact ownership を変更しない（review 対象であり owner ではない＝design Boundary Clarification、Non-Goals）。

完了条件:

- governance 所有 artifact が repo 内に配置され feature ownership を侵さない
- review procedure と evidence contract の owner が明確

### Task 2: conformance review procedure を定義する

根拠: Requirement 1（受入 1〜4）、design「Workflow Model Stage 1〜4」「Architecture」。

作業:

- `implementation conformance review` を implementation と smoke validation の後の必須 stage として定義する（Requirement 1 受入 1）。review focus に最低限 specification conformance / boundary conditions / evidence traceability を含める（受入 2）。
- 実行タイミングを定義する（Requirement 1 受入 3、design Stage 3）: プロトタイプ完了時 / pre-push または pre-PR チェックポイント時 / trust boundary・invalidation・provenance・承認採用ロジックのいずれか変更後。変更起因トリガーと事前チェックポイントを含み線形フロー 1 回限りにしない。
- Stage 1（implementation）→ Stage 2（relevant smoke validation）→ Stage 3（conformance review：scope 固定 / rerun summary / spec・design・dependency map 照合 / finding 起票 / severity・disposition / signal・coordination 接続 / metric snapshot）→ Stage 4（checkpoint close）を定義する（design Stage 1〜4）。
- checkpoint は conformance review が finding 0 件、または review artifact と明示 disposition を伴う finding を持つまで fully closed としない（Requirement 1 受入 4、design Stage 4）。`P1` open は次 feature 開始前修正対象とする。

完了条件:

- conformance review の必須性・focus・タイミング・close 条件が procedure doc に定義されている
- smoke pass のみで checkpoint が閉じない

### Task 3: intent review stage と reference-free bootstrap を定義する

根拠: Requirement 7（受入 1・4）、Requirement 8（受入 1〜6）、Requirement 6 受入 5、design「Stage -1」「Stage 0」「Minimal Heuristic Default Rule」「Reopen Propagation Model」。

作業:

- Stage 0（intent review）を first-class review stage として定義する（Requirement 7 受入 1、design Stage 0）。reviewer 作業: reviewed intent documents 固定 / traceability document 確認 / `D` handback 要否判定 / `intent_revision_count`・`intent_handback_count` snapshot 記録。下流 phase issue の総件数を吸い上げず、原因が intent 起因のものだけを `intent-attributed issue` として downstream artifact 側に残す（Requirement 7 受入 4）。
- Stage -1（reference-free case bootstrap）を first-class workflow entry として定義する（Requirement 8 受入 1）。`scripts/bootstrap_reference_free_case.rb` と bootstrap guide で、`intent` gate に入る最小 control artifact（upstream intent source / canonical source / umbrella intent.md / umbrella spec.json / case workflow overlay / active worklist / workflow path）を repo 内に作る（受入 2、design Stage -1）。template と gate structure のみ再利用可、case 固有 stress/scope/risk は supplied source document から書き起こす（受入 3）。
- minimal heuristic policy を定義する（Requirement 8 受入 4、design Minimal Heuristic Default Rule）。`heuristic_profile_ref` 省略時に runtime が track-specific repo-contained minimal template を既定使用してよい。bootstrap guide / bootstrap script / implementation protocol・snapshot template / heuristic policy note / track-level minimal heuristic template の canonical reference を定義する（受入 5）。ただし heuristic-default 挙動と minimal-template 語彙の canonical owner は v2-acquisition spec とし、governance は参照のみで所有しない。v2-acquisition spec が語彙確定するまで governance validator はこれら heuristic template 実体を必須検査しない（Requirement 8 受入 6、design）。
- reopen propagation を定義する（Requirement 6 受入 5、design Reopen Propagation Model）: design 修正→tasks reopen、requirements 修正→design・tasks reopen、intent 修正→影響 feature の requirements・design・tasks（必要なら implementation）reopen。intent 変更は local patch でなく workflow 再進入の起点とする。

完了条件:

- intent review と reference-free bootstrap が first-class stage として定義されている
- heuristic 語彙の所有が v2-acquisition spec にあり governance は必須検査しない

### Task 4: review template と必須セクション・type 判別を定義する

根拠: Requirement 2（受入 2・5）、Requirement 7 受入 2・6、design「Review Template Required Sections」。

作業:

- `docs/reviews/templates/intent-review-template.md` の必須セクションを定義する（design）: Reviewed Intent Documents / Traceability Check / Handback Decision（`D` handback 要否）/ Intent Metric Snapshot（`intent_revision_count`・`intent_handback_count`）。
- `docs/reviews/templates/implementation-conformance-review-template.md` の必須セクションを定義する（Requirement 2 受入 2、design）: Reviewed Scope / Reviewed Commit or Branch / Validation Rerun Summary / Findings / Severity / Recommended Action / Disposition Summary。
- reusable template として後続 review が構造的に drift しないようにする（Requirement 2 受入 5）。
- artifact 種別判別: 各 `docs/reviews/*.md` の front-matter に `type` フィールド（`intent_review` または `conformance_review`）を持たせ、validator がこの値で適用必須セクション集合を選択する。`type` 欠如・未知値は不適合扱い（design）。
- concrete review artifact は対応テンプレートの必須セクションをすべて備える（Requirement 7 受入 2）。

完了条件:

- intent / conformance template の必須セクションと type 判別が確定している
- concrete artifact が必須セクションを満たす

### Task 5: finding model と signal / handback 接続を定義する

根拠: Requirement 2（受入 3・4）、Requirement 4（受入 1〜4）、design「Finding Model」「Finding → Signal Register Mapping」「Handback Model」。

作業:

- severity を `P1` / `P2` / `P3` で定義する（Requirement 2 受入 3、design Finding Model）。`P1`=approval/adoption・trust boundary・invalidation・provenance の破綻、`P2`=fixture-bound・hard-coded・heuristic linkage などの brittle point、`P3`=traceability/maintainability を弱めるが即時破綻でないもの。critical implementation nonconformance を lower-severity boundary/traceability risk と区別する。
- 各 finding は scope / file reference / description / impact / recommended action / handback assessment / status を持つ（design）。
- finding → `implementation-signal-register` 写像規則を定義する（Requirement 4 受入 1、design）: `source_finding_ref`←finding 識別子、signal 対象領域←scope と file reference、signal 要約←description と impact、signal 優先度←severity、signal status←finding status。severity 別接続: `P1`=signal register 記録 + Stage 4 の P1 ブロック経路接続、`P2`/`P3`=軽微 signal として記録。
- open finding は implementation signal register または coordination log（あるいは両方）にリンクする（Requirement 2 受入 4）。
- handback model を定義する（Requirement 4 受入 2、design Handback Model）: `A`=task-local adjustment、`B`=design handback、`C`=requirements handback、`D`=intent handback。`D` は intent→requirements→design→tasks の連鎖 reopen を引き起こす。handback assessment を持つ finding は signal 写像に加え handback クラスにも接続する。
- trust boundary / invalidation / provenance / 承認採用ロジックに影響する未解決 finding を silent に無視しない（Requirement 4 受入 3）。implementation-only fix と design/requirements/intent reopen を要する finding の区別を保持する（受入 4）。

完了条件:

- finding が severity 区分・必須項目を持ち signal register と handback に接続される
- 上位 reopen を要する finding が implementation-only fix と区別される

### Task 6: conformance metric register と phase-review metric register を定義する

根拠: Requirement 3（受入 1〜4）、Requirement 7（受入 3・5・7）、design「Metric Model」。

作業:

- `docs/coordination/implementation-conformance-metric-register.md` を canonical metric register として定義する（Requirement 3 受入 1）。baseline metric: `conformance_findings_count` / `severity_weighted_finding_score` / `post_smoke_nonconformance_count` / `fixture_bound_resolution_count` / `heuristic_linkage_count` / `placeholder_or_deferred_count` / `review_artifact_presence_rate` / `finding_to_signal_link_rate`（Requirement 3 受入 2、design Metric Model）。各 metric の意味・収集タイミング・解釈を定義する（受入 3）。自動抽出未実装時は manual snapshot を許容する（受入 4、design）。
- `docs/coordination/phase-review-metric-register.md` を定義する（Requirement 7 受入 5）。`intent`=`intent_revision_count`・`intent_handback_count`（Requirement 7 受入 3）、`requirements/design/tasks/implementation`=phase-local issue count・recheck count・handback count・`intent-attributed issue` count。`intent` phase 自体の変更回数と下流観測の intent 起因問題を分離する。
- phase-review metric register の段階語彙（`implementation` を含む）が governance 所有であり runtime 所有の phase/profile 審査語彙と別物であることを明示する。下流 evaluation / paper-interface は runtime phase/profile slice に `implementation` を期待しない（Requirement 7 受入 7、design Metric Model 末尾）。

完了条件:

- conformance / phase-review metric register が canonical に定義され manual snapshot を許容する
- phase-review 段階語彙が governance 所有として runtime 語彙と区別される

### Task 7: workflow status model と reopen propagation を定義する

根拠: Requirement 6（受入 2・3・5）、design「Workflow Status Model」「Reopen Propagation Model」。

作業:

- `docs/coordination/workflow-gate-status.md` を repo-contained artifact として定義する（Requirement 6 受入 2）。checkpoint status を `pending` / `in_progress` / `completed` / `completed_with_open_findings` / `reopen_required` で区別する（受入 3、design Workflow Status Model）。conformance review まで進んだが open finding が残る場合は `completed_with_open_findings`。
- reopen propagation を Task 3 と整合して workflow-gate-status に反映する（Requirement 6 受入 5）。intent-triggered reopen propagation（intent 変更が下流 requirements / design / tasks checkpoint を無効化）を支援する。

完了条件:

- checkpoint status が `completed` と `completed_with_open_findings` を区別する
- intent-triggered reopen propagation が gate status に反映される

### Task 8: cross-spec alignment model を定義する

根拠: Requirement 6（受入 1・4）、design「Cross-Spec Alignment Model」。

作業:

- governance rule が複数 feature の completion criteria を変える場合に cross-spec alignment review を要求する（Requirement 6 受入 1）。
- `docs/alignment/cross-spec-implementation-governance-alignment.md` を governance-specific alignment memo として定義する。workflow gate status artifact 更新と `spec.json` 上の alignment status 更新を要求する（design Cross-Spec Alignment Model）。
- governance spec metadata が cross-spec alignment の要否と完了を反映することを要求する（Requirement 6 受入 4）。

完了条件:

- completion rule 横断変更時に cross-spec alignment memo と gate status 更新が要求される
- spec metadata に alignment 要否・完了が反映される

### Task 9: governance artifact validator と concrete artifact を作る

根拠: Requirement 5（受入 1〜4）、Requirement 7 受入 6、Requirement 2 受入 2、design「Validation Model」。

作業:

- `scripts/validate_implementation_governance_artifacts.rb` を repo-contained validation entrypoint として作る（Requirement 5 受入 1）。確認対象（design Validation Model）: procedure doc 存在 / metric register 存在 / phase-review metric register 存在 / intent review template 存在 / review template 存在 / concrete intent review artifact の required section / review artifact の required section / metric snapshot の required keys。
- validator は required governance documents と review template artifact の存在を確認する（Requirement 5 受入 2）。conformance review artifact が最小必須セクションと metric key を含むか確認する（受入 3）。validator は finding の妥当性自体を判定せず artifact completeness と structure のみを担う（design）。
- validator がチェックする対象として intent review template・concrete intent review artifact・phase-review metric register の存在を含める（Requirement 7 受入 6）。
- validation entrypoint を pass する concrete review artifact を最低 1 つ用意する（Requirement 5 受入 4）。

完了条件:

- validator が governance artifact の存在・必須セクション・metric key を機械確認する
- validator を pass する concrete artifact が最低 1 つ存在する

### Task 10: テストを用意する

根拠: design「Validation Model」、プロジェクト開発方針（TDD）。

作業:

- validator を、必須 artifact 欠如・必須セクション欠落・`type` 欠如/未知値・metric key 欠落の各ケースで不適合検出することを検証する。
- concrete artifact が必須セクションを満たすとき pass することを検証する。
- TDD: 期待入出力に基づき先にテストを用意し失敗を確認してから実装する。

完了条件:

- validator の適合/不適合判定が決定的に検証できる
- pass する concrete artifact が検証される

### Task 11: 実行台帳テンプレートと authority-map を作る

根拠: Requirement 9 受入 1・2・10、design 小節 1／1.2／1.3／Owned Artifacts。

作業:

- `docs/coordination/workflow-execution-ledger-template.md` を作る。必須欄＝stage name／SoT citation（文書+節）／completion predicate／independence requirement／導出元 provenance（`authority_path`／`authoritative_section_id`／`section_content_hash`）／`ledger_format_version`。
- `docs/coordination/ledgers/` を台帳インスタンス配置先 skeleton として用意（`<process_id>-<date>.md`）。
- `docs/coordination/workflow-process-authority-map.md` を作る。2 階層 process taxonomy（workflow-level＝`reopen-procedure`／`cross-spec-alignment`、phase-level＝spec phase × {`phase-execution`／`review-wave`／`alignment-gate`}）。行スキーマ＝`process_id`／`authority_document_path`／`authoritative_section`／`stage_extraction_rule`（番号付き stage 見出しの単一リスト）。

完了条件:

- テンプレート・配置先・authority-map が repo 内に存在し、段集合の権威ソースが process ごとに一意

### Task 12: 台帳生成器と既存台帳の扱い（冪等／陳腐化／改竄）を実装する

根拠: Requirement 9 受入 1・10・11、design 小節 1／1.1／1.3。

作業:

- prescribed workflow process 着手前に authority-map から段集合を導出し台帳インスタンスを新規生成。provenance（`section_content_hash`＝`authoritative_section` 本文を正規化した content hash、文書全文でない）を記録。
- 既存台帳がある場合、provenance 一致 ∧ 構造検査合格 ∧ 独立再導出一致の AND を満たすときのみ冪等に追記、いずれか不満なら fail-closed で遮断、旧台帳保全＋`supersedes` リンク（破壊的上書き禁止）。

完了条件:

- 黙った再利用・上書きが起きず、陳腐化／改竄が fail-closed、置換系譜が追跡可能

### Task 13: 独立再導出 validator 拡張モードを実装する

根拠: Requirement 9 受入 5・3、design 小節 2／3／7。

作業:

- 既存 `scripts/validate_implementation_governance_artifacts.rb` のサブモードとして実装（`process_id` 引数、終了コード 0=pass・非 0=不適合/検査不能、出力＝各段→証跡パス突合と blocked／不一致理由）。
- 台帳生成ロジック・解析結果を共有せず、authority-map の権威ソースを一次解釈で再パースし段集合を再導出、台帳と突合、欠落段＝validation failure。
- 完了述語＝証跡 artifact の存在＋構造適合（Requirement 5 検査と同型・上位集合）。状態語彙は foundation 所有正準語彙（not_run／passed／failed／blocked）を参照、再定義しない。

完了条件:

- 独立再導出が台帳と非共有で動き、Requirement 5 entrypoint の上位集合として機械検証できる

### Task 14: enforcement point（曖昧判定・通過マーカー・観測性・fail-closed）を実装する

根拠: Requirement 9 受入 6・8・11、design 小節 4。

作業:

- 不可逆ワークフロー操作の最小集合（spec.json の `approvals`／`phase` 書込、`workflow-gate-status.md` の status 遷移・reopen 追記、cross-spec alignment memo 確定、phase evidence summary／gate package 生成・提示）の直前で判定。pass ⇔ 台帳存在 ∧ 全段 completion predicate ∧ 独立再導出突合一致。
- 「権威ソース曖昧で段集合一意導出不能」を機械判定（`authoritative_section` 不特定／抽出空・重複／非確定書式 → 曖昧＝fail-closed）。検査不能（不在・実行失敗・曖昧・台帳不在）は pass とみなさず fail-closed。
- enforcement pass を台帳に通過マーカー（process_id／対象操作／timestamp／突合ハッシュ）として記録、後続承認依頼・次 process 着手時にマーカー存在と整合を必須確認、マーカー無き遷移＝バイパス＝fail-closed。blocked／fail-closed／陳腐化検知も台帳に記録（process_id／対象操作／判定／欠落段・不一致理由／timestamp）。
- 人間承認依頼に各段→証跡パスの台帳突合表を埋め込み、その生成自体を enforcement 対象にする。

完了条件:

- バイパス・検査不能・曖昧がいずれも fail-closed、遮断・通過が事後監査可能

### Task 15: independent-production marker（真正性）を実装する

根拠: Requirement 9 受入 4、design 小節 3。

作業:

- 横断・横段の alignment 段の証跡は起草者と独立プロセスで生成。independent-production marker は自己申告文字列でなく、独立証跡 artifact（`docs/reviews/` または `docs/coordination/` 配下の実体）への必須リンク欄として実装。completion predicate＝リンク先存在＋構造適合。リンク欠落・不在・不適合は独立性未充足＝fail-closed。

完了条件:

- marker の自己申告偽装が排除され、独立性が証拠 artifact で裏付く

### Task 16: uniform application・reopen 経路・移行戦略を実装する

根拠: Requirement 9 受入 7・9、design 小節 5／10。

作業:

- 全 prescribed workflow process に例外なく適用（特定 process／spec phase に特化しない）。reopen 経路も enforcement 対象とし、reopen-procedure を本契約内包へ同期する作業の受け皿を用意（具体追記は承認後の文書同期＝C-3）。
- 移行戦略：grandfathering（design 承認以降の新規 process から適用、既存 completed は遡及しない）、自己ブートストラップ（導入フェーズは移行期に手作業台帳可・`workflow-gate-status.md` に証跡記録）、`ledger_format_version` による形式移行（破壊的一括書換なし）。

完了条件:

- 例外なし適用と grandfathering が両立、reopen 経路が抜け穴化しない

### Task 17: 上位文書同期（C-1／C-2／C-3）を承認後作業として段取りする

根拠: Requirement 9 受入 9、design 小節 6、要件／設計横断整合ゲート C 群。

作業:

- C-1：`phase-and-feature-dependency-map.md` に台帳着手前提を追記。
- C-2：`CONVENTIONS.md`（新概念定義・節 6）／`WORKFLOW_OVERVIEW.md` 節 7（権威ソース・正本一覧）／`HUMAN_WORKFLOW.md` 節 5.2.7（承認依頼への台帳突合埋込前提）を同期。
- C-3：`workflow-repair-procedure.md` 節 2／3 に台帳・enforcement を内包同期（設計小節 6 に追従。権威ソースの確定書式要求も一体）。
- いずれも本タスク文書承認後の文書同期作業として 1 件ずつ実施（spec.json alignment 反映を伴う）。

完了条件:

- C-1〜C-3 が同期され、独立再導出の権威ソースが確定書式で一意

### Task 18: テストを用意する（Requirement 9 分）

根拠: design 小節 9、プロジェクト開発方針（TDD）。

作業:

- 単体：段集合再導出／突合判定／provenance 一致／小節 1.1 の 3 条件／authority-map 行解釈。
- 統合：enforcement が不可逆操作を実遮断／通過マーカー記録と後続確認／独立再導出が台帳生成と非共有。
- 異常系 fixture：曖昧権威ソース／改竄・陳腐化台帳／検査スクリプト不在・失敗／enforcement 未配線 → いずれも fail-closed。
- TDD：期待入出力に基づき先にテストを用意し失敗確認後に実装。

完了条件:

- design 小節 9 のテスト境界が検証可能

## 4. Downstream Handoff

governance は feature logic graph に data producer を追加しない。foundation/runtime/evaluation/self-improvement/paper-interface は本 spec の completion rule・conformance review・reopen propagation に従う（design Boundary Clarification）。`docs/coordination/` と `docs/reviews/` は本 spec の artifact placement rule に従う。

## 5. Blocking Dependencies

phase-and-feature-dependency-map §5.3 に従い、implementation-governance tasks は tasks alignment gate 完走後・prototype 実装後の review gate と validator を定義する位置にある。

- Task 3 の heuristic 語彙関連 validator 検査は v2-acquisition spec の語彙確定まで必須化しない（Requirement 8 受入 6）
- Task 9 の validator は他 5 feature の implementation 着手後に concrete review artifact を得て pass 確認する

### 5.1 Task 間依存グラフ（§2 から導出。並列可を明示）

- Task 1（所有 artifact skeleton）が起点。
- Task 2（conformance review procedure）と Task 3（intent review／reference-free bootstrap）は Task 1 後に並行着手可。
- Task 4（review template／必須セクション／type 判別）→ Task 5（finding model／signal・handback 接続）→ Task 6（conformance／phase-review metric register）→ Task 7（workflow status／reopen propagation）→ Task 8（cross-spec alignment model）。
- Task 9（governance artifact validator／concrete artifact）は Task 2/4/6 の成果（procedure・template・metric register）が揃って着手可。
- Task 10（テスト）は Task 1〜9 と並走（TDD 先行）。
- Requirement 9 ぶん：Task 11→12→13→14→15→16→18（§2 の Req9 内部順序）。Task 17（C-1/C-2/C-3 上位文書同期）はタスク人間承認後の文書同期作業として最後。Req9 ぶんは Task 1 skeleton と Task 9 validator 拡張を前提とする。
- 外部前提：Task 3 の heuristic 語彙関連 validator 検査は v2-acquisition 語彙確定まで必須化しない、Task 9 は他 5 feature の implementation 着手後に concrete artifact で pass 確認（上記 Blocking）。

### 5.2 失敗時の巻き戻し単位

- Task 1〜10 は governance 文書・スクリプト作成で概ね task-local 吸収（handback A）。
- Task 7（reopen propagation）／Task 8（cross-spec alignment model）でワークフロー正本や他 feature 完了規則との不整合が判明したら handback B（design）または C（requirements）で上流へ。
- Task 3 の heuristic 語彙は v2-acquisition spec 所有のため不足時は v2-acquisition 側 alignment 議題（Requirement 8 受入 6 により governance validator は必須化しない）。
- Task 9 validator が他 feature の concrete artifact 不在で pass 確認できない場合は blocked（巻き戻しでなく前提待ち）。
- Requirement 9 ぶん（Task 11〜18）の巻き戻しは design 小節 5／10（grandfathering・reopen 経路）に従う。
- governance は feature data を生成しないため raw evidence は対象外。判定に迷う場合は WORKFLOW_OVERVIEW §4 に従い上流（C）へ寄せる。

## 6. Completion Criteria

design「Validation Model」と Requirement に従い、少なくとも次を満たすとき本 task plan は有効とみなす。

- conformance review が必須 stage として定義され smoke pass のみで checkpoint が閉じない
- finding が severity 区分・必須項目を持ち signal register と handback に接続される
- conformance / phase-review metric register が canonical に定義されている
- checkpoint status が `completed` と `completed_with_open_findings` を区別する
- governance artifact validator が存在・必須セクション・metric key を機械確認し pass する concrete artifact が最低 1 つ存在する
- phase-review 段階語彙（`implementation` 含む）が governance 所有として runtime phase/profile 語彙と区別される
- Requirement 9 の実行台帳・独立再導出・enforcement・fail-closed・通過マーカー・移行戦略が設計小節 1〜10 どおり実装され、検査不能・バイパス・曖昧がいずれも fail-closed となる
