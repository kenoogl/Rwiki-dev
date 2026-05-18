# 設計横断整合ゲート — implementation-governance Requirement 9 設計節（2026-05-18）

- 実施日: 2026-05-18
- 方式: 独立設計横断整合レビュアー（起草者・設計個別レビュアーとは別視点、REVIEW_PROTOCOL 節 4 のフィーチャー横断レビューパターン）
- 対象: implementation-governance design.md「## Workflow Execution Ledger and Enforcement Model」節全体（Owned Artifacts 追加分、小節 1 / 1.1 / 1.2 / 1.3 / 2 / 3 / 4 / 5 / 6 / 7 / 8 / 9 / 10）の、設計個別レビュー must-fix 11 件適用後の状態
- 横断対象 6 spec: dual-reviewer-foundation / -runtime / -evaluation / -self-improvement / -paper-interface / -v2-acquisition の requirements.md・design.md
- 上位・正本文書: INTENT.md、WORKFLOW_OVERVIEW.md、HUMAN_WORKFLOW.md、REVIEW_PROTOCOL.md、workflow-repair-procedure.md、workflow-gate-status.md、CONVENTIONS.md、phase-and-feature-dependency-map.md
- 併せて: 要件横断ゲート C 群 3 件（C-1/C-2/C-3）の設計段取り込み妥当性、統治 Requirement 6 受入 1 の設計段充足判定
- 生証跡として不変扱い。design.md / requirements.md / spec.json は変更しない（点検と所見のみ）。

---

## 0. 正本確認結果（REVIEW_PROTOCOL 節 4「横断・順序判断の前提」に従い最初に実施）

正本 `docs/alignment/phase-and-feature-dependency-map.md` を最初に通読し、依存・順序を確認した。

- 節 3.1: 下流 phase は上流 phase の approved 状態に依存。同 phase に修正が入ったら当該 phase の alignment gate を再実施。implementation completion rule が変更された場合は本書（依存マップ）の更新対象（節 8）。
- 節 4.7: implementation-governance は runtime/evaluation/self-improvement/paper-interface に対し `review dependency`。「feature data contract を生成するのではなく completion gate を追加する」と明記。統治が他 6 feature の business contract（schema / 挙動）を変えるのは構造上想定外であり、変えるのは completion gate のみ。
- 節 5.2 Design Wave 順序: foundation → runtime → evaluation → self-improvement → paper-interface →（6）design alignment gate →（7）implementation-governance。「implementation-governance は feature design 完了後に post-implementation gate を定義する」と明示。**本ゲートはこの正本が定める design wave の (6) design alignment gate（統治設計確定前の設計横断整合）に該当する。** 統治を最後に置く正本の構造と矛盾しない。
- 節 8: 「implementation completion rule が変更された場合」が依存マップ自身の更新対象。Requirement 9 設計節は completion 基準（不可逆操作の機械遮断・台帳必須・通過マーカー）を全プロセス横断で具体化するため、依存マップ本体の更新要否が論点として継続（要件ゲート C-1 を設計段へ引き継ぎ、後述）。

正本に明示がある事項（統治の役割・順序・依存種別、本ゲートが design alignment gate に該当する点）はそれに従った。正本に明示がない構造的決定（C-1〜C-3 の本セッション同期か別送りか、依存マップ本体改訂の要否）は本レビュアーは決定せず「利用者判断が必要」と所見に明記する（REVIEW_PROTOCOL 節 4 / discipline_ssot_structural_decision_check）。

---

## 1. 観点別横断点検（REVIEW_PROTOCOL 節 4 の整合性チェック観点）

設計個別レビュー（reviews/design-local-review-2026-05-18.md）の must-fix 11 件（致命 D5-1/D6-1、重要 D2-1/D3-1/D3-2/D4-1/D6-2/D7-1/D9-1/D10-1、軽微 D1-1）は design.md に反映済み（小節 1.1/1.2/1.3、小節 4 の不可逆操作最小集合・通過マーカー・blocked イベント記録、小節 7 の入出力契約・foundation 語彙参照、小節 9 テスト戦略、小節 10 移行戦略として確認）。本ゲートはこの適用後状態を横断視点で独立点検する（個別レビュー結論は鵜呑みにしない）。

### 1.1 新 Owned Artifacts の配置・命名衝突（観点 a：インストール場所規約・命名重複）

- 追加 Owned Artifacts は 4 件：(1) `docs/coordination/workflow-execution-ledger-template.md`、(2) `docs/coordination/ledgers/<process_id>-<date>.md`、(3) `docs/coordination/workflow-process-authority-map.md`、(4) `scripts/validate_implementation_governance_artifacts.rb` の拡張モード。
- `.kiro/specs/` 全 spec の design.md / requirements.md を grep（`workflow-execution-ledger` / `workflow-process-authority-map` / `docs/coordination/ledgers`）した結果、他 6 spec での同名 artifact 所有・参照ヒット 0 件。命名衝突なし（A 群）。
- 実ファイル系確認：`docs/coordination/` 直下に既存ファイル（`*-rollout-status-*.md`、`analysis-run-set-selection-policy.md`、`implementation-conformance-metric-register.md` 等）があるが、`docs/coordination/ledgers/` サブディレクトリは未作成で、新規サブディレクトリ採用により既存 `docs/coordination/` 直下ファイルと配置衝突しない（A 群）。
- CONVENTIONS 節 4 命名規約との整合：`*_register` / `*_index` / `*_manifest` / `*_result` / `*_summary` の suffix 規約に対し、台帳テンプレートは `-template`、台帳インスタンスは `<process_id>-<date>` 形式、authority-map は `-map`。これらは CONVENTIONS 節 4 の suffix 規約が対象とする「ある処理単位の累積管理台帳（register）」等とは別系統の workflow control 文書であり、既存 `*-status-*.md` 等の coordination 文書と同じ非 suffix 命名系。命名規約違反ではないが、CONVENTIONS 節 6「新しい artifact 種別を導入する場合は本書に naming rule を追記する」に照らすと workflow ledger/authority-map の命名規約が CONVENTIONS 未追記（要件ゲート C-2 と同系統、後述 C-2 に集約。設計文面内の整合は閉じている）。
- 統治既存 Owned Artifacts（`scripts/validate_implementation_governance_artifacts.rb`、`docs/coordination/workflow-gate-status.md`、`docs/coordination/implementation-conformance-*.md` 等）との関係：validator は同一スクリプトの拡張モード（別スクリプト新設なし、AC5 superset 方針）。台帳・authority-map は新規で既存統治 artifact と非重複。Owned Artifacts 節内の整合（A 群）。

### 1.2 foundation 所有 validator 状態語彙参照の横断整合（観点 b：唯一正本の同期メカニズム・接続契約）

- 設計小節 7 末尾：「検査結果の状態語彙は foundation 所有の正準 validator 状態語彙（`not_run` / `passed` / `failed` / `blocked`）を参照元とし、統治では再定義・別トークン化しない」。
- foundation 正本確認：`foundation/requirements.md` 受入 10「canonical validator-status vocabulary（ran-and-passed / ran-and-failed / blocked）を foundation が所有し downstream runtime/evaluation が参照、再定義しない」。`foundation/design.md` 行 260-263・行 449 で `validator_status` 語彙を `not_run` / `passed` / `failed` / `blocked` と確定。設計小節 7 の参照トークンは foundation design.md 正本と**完全一致**（A 群）。
- 横断 spec の同語彙参照との整合：runtime/requirements.md 受入 2「foundation canonical validator-status vocabulary（pass/fail/blocked）を再定義・collapse せず伝播」、runtime/design.md 行 619「foundation が正準 validator 状態語彙 pass/fail/blocked を所有」、evaluation/design.md 行 178-188 が `validator_status=passed/failed/blocked` を参照（評価独自 local state は `analysis_blocked` で別概念と明示）。統治の参照は runtime/evaluation の foundation 参照と同一正本・同一トークン系で、並行語彙の二重化なし。三者（統治・runtime・evaluation）が foundation 単一正本を参照する構造で整合（A 群）。
- 二重化リスク評価：統治小節 7 が「他フィーチャーが foundation 正準語彙を参照する既存規律と一貫、並行語彙の二重化を避ける」と明記。これは workflow-gate-status 節 3.4（2026-05-17 foundation 要件 6 受入 10 追加・runtime 要件 6 受入 2 修正）の A-4 再開で確立した「foundation 正準語彙単一化」決定の正しい継承（B 群＝A-4 サイクルで確立済みの語彙正本に新規参照を整合させたもの。記録のみ）。

### 1.3 authority-map 2 階層 process taxonomy と WORKFLOW_OVERVIEW/HUMAN_WORKFLOW 段構成の整合（観点 c）

- 設計小節 1.2：workflow-level process（`reopen-procedure`、`cross-spec-alignment`）と phase-level process（spec phase ∈ {intent/requirements/design/tasks/implementation} の各 `<phase>-phase-execution` / `<phase>-review-wave` / `<phase>-alignment-gate`）の 2 階層。
- WORKFLOW_OVERVIEW 整合：節 2「requirements wave / design wave / tasks wave も同様の構造（feature 起草 → feature-local review → review wave → alignment gate → gate package）」、節 3「requirements/design/tasks alignment gate」、節 5「reopen 10 ステップ」。小節 1.2 の phase-level taxonomy（phase-execution/review-wave/alignment-gate）は WORKFLOW_OVERVIEW 節 2 の wave 内部構造と対応し、workflow-level（reopen/cross-spec-alignment）は節 5・節 3 と対応。段構成の写像に齟齬なし（A 群）。
- CONVENTIONS 節 3 spec phase 語彙との整合：小節 1.2 の spec phase 値域 {intent/requirements/design/tasks/implementation} は CONVENTIONS 節 3.1 spec phase（requirements/design/tasks/implementation）＋節 3.2 review phase の intent を包含。Requirement 9 文面が「prescribed workflow process は CONVENTIONS 節 3 の spec-phase 語彙と用語上区別される」と定義済み（要件ゲート A-1 で確認済み）であり、設計小節 1.2 が phase-level process を `<phase>-<process-type>` と複合識別子化することで spec phase 語と process 識別子を構文上分離。CONVENTIONS 節 3 との二重定義なし（A 群）。
- HUMAN_WORKFLOW 整合：節 5.2.5 multi-feature alignment gate、節 5.2.7 phase evidence summary、節 5.2.5.5 wave 既定解釈と小節 1.2 の process 値域は対応。ただし HUMAN_WORKFLOW 本体に「prescribed workflow process の 2 階層 taxonomy」「各 process の権威ソース」が未記載（要件ゲート C-2 と同系統、C-2 に集約。設計文面内の整合は閉じている）。

### 1.4 AC9 の workflow-repair-procedure 同期要求と既存 reopen 10 ステップ・状態遷移表の整合（観点 d）

- 設計小節 5：「既存 reopen-propagation／cross-spec-alignment 義務を保存しつつ、手続き正本（特に workflow-repair-procedure.md の reopen 10 ステップ・状態遷移表）を本契約内包へ同期し、reopen 経路も enforcement 対象とする（AC9）」。小節 6 で C-3 として取り込み先を明示。
- workflow-repair-procedure 正本確認：節 2 Step 1〜10（台帳生成・独立再導出ステップは現状なし）、節 3 状態遷移表（最終行「governance spec introduced / completion rule 変更 / cross-spec review 必須 / alignment memo・gate status・spec.json alignment 更新」は存在するが台帳・enforcement の必須アクション列はなし）、節 6 update rule（「reopen propagation rule が変わったとき」を更新トリガーに保持＝同期の受け皿あり）。
- 矛盾の有無：設計小節 5 は「既存 reopen 義務を**保存しつつ**内包同期」と明記し、reopen 10 ステップ・状態遷移表の既存遷移を**置換せず台帳・enforcement を上乗せ**する方向。Reopen Propagation Model 節（design.md 既存節、design 修正→tasks reopen 等）とも矛盾しない。AC9 が「保存」を明示するため、reopen 10 ステップの既存ステップ意味と設計小節 5 の間に矛盾は生じない（A 群）。
- ただし AC9 が「同期を要求」した結果、workflow-repair-procedure 節 2/節 3 の文書実体が未同期である点が確定的に顕在化（要件ゲート C-3 が要件段で特定済み・設計段送り。設計小節 6 が取り込み先を引き継ぎ確定。後述 C-3 で取り込み妥当性判定）。

### 1.5 小節 6 の C-1〜C-3 取り込み先と要件横断ゲート C 群の対応（観点 e）

- 要件横断ゲート（requirements-alignment-gate-2026-05-18-governance.md）C 群：C-1＝依存マップ更新、C-2＝CONVENTIONS 節 6 / WORKFLOW_OVERVIEW 節 7 / HUMAN_WORKFLOW 節 5.2.7 同期、C-3＝workflow-repair-procedure 節 2/節 3 同期。
- 設計小節 6 の取り込み先指定：C-1＝`phase-and-feature-dependency-map.md` に台帳前提を追記、C-2＝`CONVENTIONS.md`（新概念定義・節 6）／`WORKFLOW_OVERVIEW.md` 節 7（権威ソース・正本一覧）／`HUMAN_WORKFLOW.md` 節 5.2.7（承認依頼への台帳突合埋め込み前提）へ同期、C-3＝`workflow-repair-procedure.md` 節 2／節 3 に台帳・enforcement を内包同期（AC9 と一体）。
- 対応点検：設計小節 6 の C-1/C-2/C-3 の文書名・節番号・取り込み趣旨は要件ゲート C-1/C-2/C-3 と**1 対 1 で完全対応**。漏れ・齟齬・新規 C 群なし（A 群＝対応整合）。「具体追記は設計横断整合ゲートで一括し、設計確定後の文書同期作業で実施」と段取りも明示。後述 §4 で取り込み妥当性を判定。

### 1.6 通過マーカー／観測性記録と既存証跡所在規約の二重正本化（観点 f）

- 設計小節 4：enforcement pass 事実を「台帳に通過マーカーとして記録」、「記録先は台帳内とし、別証跡に分散させない」。blocked／fail-closed／陳腐化検知イベントも「通過マーカーと同一の台帳内」。
- 既存証跡所在規約：workflow-repair-procedure 節 6（intent review→docs/reviews、実装判断→coordination log、軽微 signal→signal-register、review finding→docs/reviews、gate 状態→workflow-gate-status）、design.md 既存 Finding Model（finding→signal-register 写像）、HUMAN_WORKFLOW 節 5.2.7（phase evidence summary は derived artifact、source は review artifact/alignment memo/workflow gate status）。
- 二重正本化評価：通過マーカー・enforcement イベントは**新概念（enforcement 通過の事実証跡）**であり、既存証跡所在規約が定める種別（finding / signal / gate status / coordination 判断）のいずれにも該当しない新カテゴリ。設計小節 4 が「台帳内に集約・別証跡へ分散しない」と単一所在を明示することで、既存証跡（workflow-gate-status の gate status 記録、signal-register の signal）と**機能的に重複しない別正本**として配置。gate status（どの gate まで通過したか）と通過マーカー（不可逆操作の直前検査が pass したか）は粒度・目的が異なり、二重正本化ではない（A 群）。
- ただし「enforcement 通過証跡を台帳に置く」新方針が workflow-repair-procedure 節 6 の証跡所在一覧（gate 状態→workflow-gate-status 等）に未追記。これは C-3（workflow-repair-procedure 同期）の取り込み内容に含めるべき派生点（後述 C-3 妥当性判定で言及。設計文面内＝小節 4 は閉じている）。

### 1.7 接続契約 3 要素・versioning 戦略・後段引き渡し（観点：接続契約 3 要素、versioning、後段引き渡し）

- 接続契約 3 要素：場所規約＝Owned Artifacts のパス確定（ledgers/、authority-map、template）、識別子＝小節 1.2/1.3 の process_id 値域・provenance 値域（authority_path/authoritative_section_id/section_content_hash）、失敗信号＝小節 4 の fail-closed・blocked イベント記録。3 要素が設計レベルで揃う（A 群）。要件ゲート §1.3 が要件レベルで 3 要素充足を確認済みで、設計が値域まで具体化（B 群方向の深化＝既存要件整合の設計具体化、記録のみ）。
- versioning 戦略：小節 10「台帳必須欄に `ledger_format_version` を追加。形式変更は小節 1.1 の supersedes（陳腐化／改竄置換）とは別経路の format-migration とし旧 version 台帳は読める形を保つ」。supersedes（改竄/陳腐化置換）と format-migration（形式版移行）を別経路と明示分離。versioning 戦略の設計段確定あり（A 群＝設計個別レビュー D10-1 反映確認）。
- 後段引き渡し：小節 8「検査スクリプトの具体配線・フック実装は tasks／implementation の責務」、小節 9「詳細ケース分解は tasks 段」と tasks 段への引き渡し境界を明示。設計が閉じる範囲（捕捉対象集合・判定論理・値域・テスト境界・移行方針）と tasks に委ねる範囲（フック配線・ケース分解）の境界が明確（A 群）。

---

## 2. 4 分類結果

### A 群：確認済整合（対応不要）

- A-1: 新 Owned Artifacts（ledger-template / ledgers/ / authority-map / validator 拡張）の他 6 spec との命名・配置衝突 0 件。`docs/coordination/ledgers/` 新規サブディレクトリは既存 `docs/coordination/` 直下ファイルと非衝突。
- A-2: 設計小節 7 の validator 状態語彙参照（`not_run`/`passed`/`failed`/`blocked`）が foundation design.md 正本（行 260-263/449）と完全一致。
- A-3: 統治・runtime・evaluation が foundation 単一正準語彙を参照する三者整合（並行語彙二重化なし）。
- A-4: 小節 1.2 の 2 階層 process taxonomy が WORKFLOW_OVERVIEW 節 2/3/5・HUMAN_WORKFLOW 節 5.2.5/5.2.7 の段構成と写像整合。
- A-5: 小節 1.2 の process 識別子が CONVENTIONS 節 3 spec phase 語と構文分離（`<phase>-<process-type>` 複合化）、二重定義なし。
- A-6: 設計小節 5 の AC9 同期が既存 reopen 10 ステップ・状態遷移表・Reopen Propagation Model を「保存しつつ内包」で矛盾なし。
- A-7: 設計小節 6 の C-1/C-2/C-3 取り込み先指定が要件横断ゲート C-1/C-2/C-3 と 1 対 1 完全対応（漏れ・齟齬・新規 C 群なし）。
- A-8: 通過マーカー／enforcement イベントは新カテゴリ証跡で既存証跡所在規約（gate status / signal / finding）と機能非重複、台帳内単一所在で二重正本化なし。
- A-9: 接続契約 3 要素・versioning（supersedes と format-migration の分離）・後段引き渡し境界（tasks/implementation への委譲明示）が設計段で整合確定。

### B 群：既存対応済（記録のみ）

- B-1: foundation 正準 validator 語彙の単一化は workflow-gate-status 節 3.4（2026-05-17 A-4 再開サイクル）で確立済み。設計小節 7 はその確立済み正本に新規参照を整合させたもので、新たな対応不要（記録のみ）。
- B-2: 接続契約 3 要素の充足は要件横断ゲート §1.3 で要件段確認済み。設計はその値域具体化であり既存整合の設計深化（記録のみ）。
- B-3: 設計個別レビュー must-fix 11 件（致命 2/重要 8/軽微 1）は design.md に適用済み（小節 1.1/1.2/1.3、小節 4 不可逆操作最小集合・通過マーカー・blocked 記録、小節 7 入出力契約・foundation 語彙、小節 9/10）。本横断ゲートでも適用後状態に新たな横断不整合が発生していないことを独立確認（記録のみ、追加対応不要）。
- B-4: 他 6 spec への暗黙契約変更・新義務付与＝0 件。要件横断ゲート §3 で要件段 0 件を独立確認済み。設計段でも独立再確認（次節）し同一結論。重複対応不要、記録のみ。

### C 群：今回横断レビューで顕在化した新規含意（設計文面内の整合は閉じている。提示のみ・適用しない）

C-1〜C-3 はいずれも要件横断ゲートで設計段送りとされた上位運用文書同期であり、設計小節 6 が取り込み先を確定し設計文面内の整合は閉じている（不整合ではない）。Requirement 9 設計の意図駆動ワークフローへの実体反映として、設計人間承認後の文書同期作業に属する。本設計横断整合ゲートは「設計小節 6 の取り込み先指定が正しく、追加同期漏れがないか」を点検する役割であり、§4 で取り込み妥当性を判定する。新規 C 群（要件ゲート C 群に対応しない設計段固有の新規含意）は本点検で検出しなかった。C 群として再掲する 3 件は要件ゲート C-1〜C-3 を設計段の取り込み対象として確定したものであり、所見の 4 要素は §4 に記す。

#### C-1: 依存マップ（phase-and-feature-dependency-map.md）への台帳前提追記

- 所在: phase-and-feature-dependency-map.md 節 4.7（implementation-governance の役割）／節 5.x（wave 順序）、節 8（update rule「implementation completion rule が変更された場合」）
- 問題: Requirement 9 設計節は completion 基準（全 prescribed workflow process に台帳・enforcement・通過マーカー必須）を確定。依存マップ節 8 はこれを自身の更新トリガーに明示列挙するが、依存マップ本体には「各 wave / alignment gate / reopen は execution ledger を着手前提とする」旨が未反映。
- 根拠: 依存マップは planning memo ではなく phase progression の補助正本（節 8 冒頭）。設計小節 1/5 が requirements/design/tasks の各 wave・alignment gate・reopen に台帳を要求する以上、補助正本にも台帳ステップの位置づけ反映が筋。設計小節 6 が C-1 として取り込み先を依存マップと明示。
- 推奨対応: 依存マップ節 4.7 または節 5.x に「各 wave / alignment gate / reopen は Requirement 9 の execution ledger を着手前提とする」旨を 1〜2 文追記（設計小節 6 の C-1 指定どおり）。
- 必要性判定: 設計確定後の文書同期作業で足りる（design.md 文面は小節 6 で取り込み先確定済み、依存マップは設計書ではない）。設計人間承認の阻害要因ではない。**利用者判断**（補助正本改訂・本セッション同期か別送りか）。

#### C-2: CONVENTIONS.md 節 6 / WORKFLOW_OVERVIEW 節 7 / HUMAN_WORKFLOW 節 5.2.7 への概念・権威ソース・summary 前提同期

- 所在: CONVENTIONS.md 節 6（新 phase-like 概念は CONVENTIONS で先に定義／新 artifact 種別は naming rule 追記）、WORKFLOW_OVERVIEW 節 7（正本文書一覧）、HUMAN_WORKFLOW 節 5.2.7（phase evidence summary 生成手順）
- 問題: 設計節は (a) 新概念「prescribed workflow process」2 階層 taxonomy（小節 1.2）、(b) process ごと段集合権威ソース一意性と authority-map（小節 1/1.2/AC10）、(c) 台帳・authority-map の新 artifact 種別命名（§1.1）、(d) gate package / phase evidence summary 生成を enforcement point 化（小節 4・AC8）を導入。設計文面内では閉じているが、CONVENTIONS 節 6（新 phase-like 概念・新 artifact 種別の先行定義）・WORKFLOW_OVERVIEW 節 7（権威ソース一覧）・HUMAN_WORKFLOW 節 5.2.7（summary 生成が台帳照合 pass を前提とする旨）の上位文書側に未反映。
- 根拠: CONVENTIONS 節 6 は新 phase-like 概念・新 artifact 種別の CONVENTIONS 先行定義を運用ルールとして要求。設計が概念・新 artifact を確定した以上、上位規約への反映が節 6 ルール上必要。AC10 権威ソース一意性は WORKFLOW_OVERVIEW 節 7「概観であり正本優先」現状記述と緊張するため、権威ソース対応の上位文書反映が独立再導出（AC5）実効性に必要。HUMAN_WORKFLOW 節 5.2.7 本体に「gate package / summary 生成は台帳照合 pass を前提」が未記載で AC6/AC8 の enforcement 化が上位文書未反映。設計小節 6 が C-2 として 3 文書を取り込み先に明示。
- 推奨対応: 設計確定後の文書同期作業で、設計小節 6 指定どおり CONVENTIONS 節 6（prescribed workflow process 定義・ledger/authority-map の naming rule 追記）・WORKFLOW_OVERVIEW 節 7（権威ソース対応の参照追加）・HUMAN_WORKFLOW 節 5.2.7（summary 生成が台帳照合 pass を前提とする旨）を同期。AC10 の「process→権威文書」具体対応（authority-map 内容）の確定と同一作業内で行う。
- 必要性判定: 設計確定後の文書同期作業で足りる（design.md 文面は AC10/AC6/AC8/小節 1.2 で閉じている）。設計人間承認の阻害要因ではない。**利用者判断**（3 文書実質変更含み・本セッション同期か別送りか）。要件ゲート C-2 と同一系統、本ゲートで独立再特定し対象に「ledger/authority-map の CONVENTIONS 節 6 naming rule 追記」を追加して拡張。

#### C-3: workflow-repair-procedure.md（reopen 10 ステップ・状態遷移表）への台帳・enforcement 内包同期

- 所在: workflow-repair-procedure.md 節 2 Step 1〜10、節 3 状態遷移表、節 6 update rule、加えて節 6 証跡所在一覧（gate 状態→workflow-gate-status 等）
- 問題: 設計小節 5＝AC9 が「reopen 経路自体が台帳・独立再導出・enforcement の対象になるよう既存手続き文書を同期」を確定。workflow-repair-procedure 節 2 の 10 ステップに台帳生成・独立再導出ステップが現状なく、節 3 状態遷移表の必須アクション列に enforcement がなく、節 6 証跡所在一覧に「enforcement 通過証跡＝台帳内」（設計小節 4 の新方針）が未追記。設計文面内では小節 5/6 で閉じているが文書実体が未同期。
- 根拠: 設計小節 1 は reopen procedure を prescribed workflow process（workflow-level process `reopen-procedure`、小節 1.2）に含め台帳を要求、小節 5＝AC9 が同期を明示。文書実体（reopen 10 ステップ）未同期では独立再導出器が reopen 経路の段集合を再導出する権威根拠が上位文書に存在しない。workflow-repair-procedure 節 6 update rule は「reopen propagation rule が変わったとき」を更新トリガーに保持＝同期の受け皿あり。設計小節 6 が C-3 として取り込み先を明示。
- 推奨対応: 設計確定後の文書同期作業で、設計小節 6 指定どおり workflow-repair-procedure 節 2 に台帳着手ステップ・節 3 状態遷移表に enforcement 必須アクションを追記。加えて節 6 証跡所在一覧に「enforcement 通過マーカー／blocked・fail-closed イベント＝台帳内」（設計小節 4 の単一所在方針）を追記すると §1.6 の派生点も同時に閉じる。C-2 の権威ソース対応確定と同一作業内で行うと reopen 経路の権威文書（reopen-procedure process の authority_document_path）も一意化できる。
- 必要性判定: 設計確定後の文書同期作業で足りる（AC9＝設計小節 5/6 で design.md 文面は閉じている）。設計人間承認の阻害要因ではない。**利用者判断**（reopen 手続き実質改訂・本セッション同期か別送りか）。要件ゲート C-3 と同一系統、本ゲートで独立再特定し「節 6 証跡所在一覧への enforcement 証跡追記」を派生点として追加（§1.6 と連動）。

### 不整合（受入基準違反・実装不可能・進行停止要否）

- **不整合 0 件。** Requirement 9 設計節は受入 1〜11 すべてに対応箇所を持ち（設計個別レビュー観点 1 で受入未カバー 0 を独立確認、本ゲートでも横断視点で再確認）、設計個別レビューの致命 2 件（D5-1 権威ソース曖昧の機械判定基準、D6-1 enforcement バイパス通過マーカー）・重要 8 件は design.md（小節 1.1/1.2/1.3/4/7/9/10）に適用済み。横断点検でも (a) 新 Owned Artifacts の他 6 spec 命名・配置衝突、(b) foundation validator 語彙参照不整合、(c) WORKFLOW_OVERVIEW/HUMAN_WORKFLOW 段構成との矛盾、(d) reopen 10 ステップ・状態遷移表との矛盾、(e) 小節 6 C 群対応漏れ、(f) 証跡二重正本化、いずれも検出されなかった。他 6 spec の business contract への新義務付与・矛盾なし。進行を止める所見はなし。

---

## 3. 波及明示記録（他 6 spec、波及なしも全件明示）

REVIEW_PROTOCOL 節 4 の「修正の双方向反映・波及あり/なしを全件明示記録」に従い、設計段で独立に再確認した。

- 検索: `.kiro/specs/` 全 spec の design.md / requirements.md に対し `workflow-execution-ledger` / `workflow-process-authority-map` / `docs/coordination/ledgers` / `validator.status` / `not_run|passed|failed|blocked` / `ledger|enforcement|prescribed|irreversible|re-deriv` を実行。
- 新 Owned Artifacts（ledger-template / ledgers/ / authority-map / validator 拡張）: 他 6 spec での同名 artifact 所有・参照ヒット 0 件。命名・配置の暗黙衝突なし。
- foundation: 受入 10／design.md 行 260-263/449 が validator 状態語彙正本。統治設計小節 7 はこれを**参照**するのみで foundation の AC・フィールドを変更しない。foundation への新義務付与なし。
- runtime: requirements 受入 2／design.md 行 619 が foundation 語彙参照。統治設計は runtime と同一正本を独立参照するのみで runtime の参照規律・AC を変えない。波及なし。
- evaluation: design.md 行 178-188 が `validator_status` 参照・`analysis_blocked` で local state を別概念化済み。統治設計は evaluation の分類・local state に触れない。波及なし。
- self-improvement / paper-interface: Requirement 9 設計関連語のヒットなし。stat/proposal/backtest/claim mapping 等の business contract に新義務なし。波及なし。
- v2-acquisition: 既存 Requirement 8 AC6 が v2-acquisition を heuristic-default 正本所有者とする従属関係を持つが、Requirement 9 設計節（小節 1〜10）はこの所有関係に触れず（設計 Workflow Model の Minimal Heuristic Default Rule は既存節で不変）。波及なし。
- 構造的根拠: 依存マップ節 4.7「implementation-governance は feature data contract を生成するのではなく completion gate を追加する」。Requirement 9 設計は workflow を実行するエージェント／検査器に台帳・機械強制を課す workflow control 契約であり、6 spec の business data contract（schema / orchestration / metrics / improvement loop / paper export / heuristic-default 語彙）の AC・フィールド・挙動を変更しない。設計小節 8 が「feature artifact ownership を変えない（既存 Boundary Clarification 不変）」「台帳・authority-map・通過マーカーは feature logic graph の business data producer ではなく workflow control/gate artifact」と明示し、既存 Architecture「feature logic graph に新しい data producer を追加しない」宣言と矛盾しない限定を設計内で確定（D2-1 反映確認）。
- **結論: 他 6 spec（foundation / runtime / evaluation / self-improvement / paper-interface / v2-acquisition）への暗黙契約変更・新義務付与は 0 件（波及あり 0 件）。** 設計個別レビュー総合所見の波及 0 を鵜呑みにせず設計段で独立再確認した結果も同一。

---

## 4. 要件横断ゲート C 群 3 件（C-1/C-2/C-3）の設計段取り込み妥当性判定

- **C-1（依存マップ）**: 設計小節 6 が取り込み先を `phase-and-feature-dependency-map.md` と正しく指定。要件ゲート C-1 と文書・趣旨が一致。取り込み先指定**妥当**。追加で必要な上位文書同期なし。設計確定後の文書同期作業として段取り妥当（設計人間承認の阻害要因ではない）。
- **C-2（CONVENTIONS 節 6 / WORKFLOW_OVERVIEW 節 7 / HUMAN_WORKFLOW 節 5.2.7）**: 設計小節 6 が 3 文書すべてを取り込み先に明示。要件ゲート C-2 と一致。**取り込み先指定妥当**。本ゲートで追加同期点 1 件を特定＝CONVENTIONS 節 6 への「ledger / authority-map の新 artifact 種別 naming rule 追記」（§1.1）。これは設計小節 6 の「CONVENTIONS（新概念定義・節 6）」に内包可能で、文書同期作業の同一スコープで吸収できる（新規 C 群ではなく C-2 の同期内容の明確化）。段取り妥当。
- **C-3（workflow-repair-procedure 節 2/節 3）**: 設計小節 6 が取り込み先を正しく指定し AC9（設計小節 5）と一体。要件ゲート C-3 と一致。**取り込み先指定妥当**。本ゲートで派生点 1 件を特定＝workflow-repair-procedure 節 6 証跡所在一覧への「enforcement 通過マーカー／blocked・fail-closed イベント＝台帳内」追記（§1.6・設計小節 4 の単一所在方針と連動）。これは C-3 の「節 2／節 3 に台帳・enforcement を内包同期」と同一作業スコープで吸収でき、新規 C 群ではなく C-3 同期内容の明確化。段取り妥当。
- **対応漏れ・新規 C 群の有無**: 要件ゲート C 群 3 件はすべて設計小節 6 に取り込み先指定があり対応漏れ 0。設計段固有の新規 C 群（要件ゲート C 群に対応しない別含意）は検出されず。C-2 の naming rule 追記・C-3 の証跡所在追記は既存 C-2/C-3 の同期スコープ内で吸収できる派生明確化であり、独立した新規 C 群を構成しない。
- **段取り総括**: 設計小節 6 は「具体追記は設計横断整合ゲートで一括し、設計確定後の文書同期作業で実施」と定義。本ゲート（本文書）が「設計横断整合ゲート」に該当し、ここで C-1〜C-3 の取り込み妥当性を判定（すべて妥当・取り込み先正確）。具体追記実体は設計人間承認後の文書同期作業で行う段取りが上位文書側の各 update rule（依存マップ節 8 / CONVENTIONS 節 6 / WORKFLOW_OVERVIEW 節 8 同期ルール / HUMAN_WORKFLOW / workflow-repair-procedure 節 6）に受け皿として存在し、欠落なし。C 群 3 件はいずれも設計人間承認の阻害要因ではなく、本セッション同期か別送りかは利用者判断。

---

## 5. 統治 Requirement 6 受入 1 の設計段充足判定

統治 Requirement 6 AC1:「governance rule が複数 feature の完了基準を変えるとき cross-spec alignment review を必須化する」。workflow-repair-procedure 節 3 状態遷移表最終行（governance spec introduced / completion rule 変更 / cross-spec review 必須 / alignment memo・gate status・spec.json alignment 更新 / → governance alignment completed）。

- **発火確認（設計段）**: Requirement 9 設計節は不可逆操作の機械遮断・台帳必須・通過マーカーという completion 基準を全 prescribed workflow process（＝全 feature の requirements/design/tasks フェーズ遂行手続き）横断で具体化する。Requirement 6 AC1 の「複数 feature の完了基準を変える governance rule」に該当し、設計段でも cross-spec alignment review が必須。
- **設計段 cross-spec alignment の充足**: 本設計横断整合ゲート（本文書）が、依存マップ正本確認のうえ Requirement 9 設計節を 6 spec 横断・上位文書横断で点検し不整合 0・波及 0・C 群 3 件（取り込み妥当性判定）を構造化した。これは workflow-repair-procedure 節 3 最終行が要求する「cross-spec review」の**設計段実施そのもの**に当たる。依存マップ節 5.2 が定める design wave (6) design alignment gate にも該当（§0 正本確認）。**Requirement 6 AC1 は設計段で「必要」と判定されるべきであり、本ゲートの実施でその義務は設計段として充足している。**
- **alignment memo の要否（設計段）**: 必要。本文書が設計段の cross-spec alignment 実施証跡（生証跡・不変）であり、節 3 最終行の「alignment memo」の設計段相当。要件段の alignment memo（requirements-alignment-gate-2026-05-18-governance.md）とは別フェーズの独立証跡で、設計段で改めて必要・本ゲートで充足（要件段 memo の再利用ではなく設計段で新規作成が正しい＝依存マップ節 3.1「同 phase に修正が入ったら当該 phase の alignment gate を再実施」と整合）。
- **workflow-gate-status 更新・spec.json alignment 反映の要否**: 必要だが本レビュアーは適用しない（点検と所見のみ）。spec.json は現在 `phase=requirements-approved` / `custom.alignment.design.status=pending` / note に「設計フェーズ丸ごと再実施＋要件横断ゲート C 群 3 件を本段で取り込む」と記録済み。本ゲート完了（不整合 0・C 群 3 件取り込み妥当性判定済み）と設計人間承認の結果を受けて `alignment.design=completed`・workflow-gate-status 節 3.2「governance spec design: reopen_required」更新・spec.json `phase=design-approved` 反映を行う段取りが上位文書（workflow-repair-procedure 節 3 / workflow-gate-status 節 5 update rule「reopen が発生したとき」「新しい cross-cutting governance rule を追加したとき」）に受け皿として存在し、欠落なし。更新自体は設計人間承認と同一手続き内（本セッションのスコープ外）。
- **判定**: 統治 Requirement 6 AC1 の cross-spec alignment review は設計段で「必要」と判定されるべきであり、本ゲートの実施でその義務は設計段として充足している。設計段 cross-spec alignment memo（＝本文書）は設計段で必要であり既に作成済み。要件段 memo を流用せず設計段で独立に再実施した点が依存マップ節 3.1・節 5.2 と整合。workflow-gate-status / spec.json alignment 反映は設計人間承認と同一手続き内で行う段取りが上位文書に存在し欠落なし（本レビュアーは適用しない）。

---

## 6. 集計と総合所見

### 集計

- A 群（確認済整合）: 9 件（A-1〜A-9）
- B 群（既存対応済・記録のみ）: 4 件（B-1 foundation 語彙単一化済み、B-2 接続契約 3 要素要件段確認済み、B-3 設計 must-fix 11 件適用後の横断不整合 0 独立確認、B-4 他 6 spec 波及 0 既記録の設計段独立再確認）
- C 群（要件ゲート由来・設計小節 6 で取り込み先確定・提示のみ）: 3 件（C-1 依存マップ／C-2 CONVENTIONS 節 6・WORKFLOW_OVERVIEW 節 7・HUMAN_WORKFLOW 節 5.2.7／C-3 workflow-repair-procedure 節 2/3）
- 不整合: 0 件（進行を止める所見なし）

### C 群一覧（番号・1 行・自動採択/利用者判断の別）

- C-1（依存マップ phase-and-feature-dependency-map.md 節 4.7/5.x に台帳着手前提を 1〜2 文追記）— 利用者判断（補助正本改訂・本セッション同期か別送りか）
- C-2（CONVENTIONS.md 節 6〔prescribed workflow process 定義＋ledger/authority-map naming rule〕／WORKFLOW_OVERVIEW 節 7〔権威ソース参照〕／HUMAN_WORKFLOW 節 5.2.7〔summary 生成が台帳照合 pass 前提〕同期）— 利用者判断（3 文書実質変更含み）
- C-3（workflow-repair-procedure.md 節 2〔台帳着手ステップ〕／節 3〔enforcement 必須アクション〕／節 6〔enforcement 証跡＝台帳内〕同期）— 利用者判断（reopen 手続き実質改訂）

3 件とも他 feature spec ではなく上位運用文書側で、設計小節 6 が取り込み先を確定し設計文面内の整合は閉じている（不整合ではない）。いずれも設計人間承認の阻害要因ではなく、設計承認後の文書同期作業。C 群対応の利用者 3 択（全採用 / 個別レビュー / A 群 B 群のみ確認し C 群は次回送り）は利用者が選ぶ。本レビュアーは適用しない。

### 他 6 spec 波及あり件数

- 0 件（foundation / runtime / evaluation / self-improvement / paper-interface / v2-acquisition すべて暗黙契約変更・新義務なし。設計段で独立再確認・明示記録済み）。

### C-1〜C-3 設計段取り込み妥当性判定

- C-1/C-2/C-3 とも設計小節 6 の取り込み先指定が要件横断ゲート C 群と 1 対 1 完全対応で**妥当**。対応漏れ 0・設計段固有の新規 C 群なし。C-2 の naming rule 追記・C-3 の証跡所在追記は既存 C-2/C-3 同期スコープ内で吸収できる派生明確化（独立新規 C 群を構成しない）。設計確定後の文書同期作業として段取り妥当（各上位文書 update rule に受け皿あり、欠落なし）。

### 統治 Requirement 6 受入 1 設計段充足判定

- cross-spec alignment review は設計段で「必要」。本ゲートでその義務を設計段として充足。設計段 cross-spec alignment memo（＝本文書）は設計段で必要であり作成済み（要件段 memo の流用ではなく設計段で独立再実施＝依存マップ節 3.1/5.2 と整合）。workflow-gate-status / spec.json alignment 反映は設計人間承認と同一手続きで行う段取りが上位文書に存在し欠落なし（本レビュアーは適用しない）。

### 総合所見

- **設計人間承認に進めてよい。** 不整合 0 件、他 6 spec 波及 0 件。設計個別レビューの致命 2 件（D5-1 権威ソース曖昧の機械判定基準、D6-1 enforcement バイパス通過マーカー）・重要 8 件・軽微 1 件（計 must-fix 11 件）は design.md（小節 1.1/1.2/1.3、小節 4 不可逆操作最小集合・通過マーカー・blocked 記録、小節 7 入出力契約・foundation 語彙参照、小節 9 テスト戦略、小節 10 移行戦略）に適用済みで、本横断ゲートでも適用後状態に (a) 新 Owned Artifacts 命名・配置衝突、(b) foundation validator 語彙参照不整合、(c) 段構成矛盾、(d) reopen 10 ステップ・状態遷移表矛盾、(e) C 群対応漏れ、(f) 証跡二重正本化、いずれも検出されず受入基準違反・実装不可能性・他 spec 矛盾なし。
- 本ゲート起因の追加 must-fix は不要（致命・重要級の横断不整合 0）。設計個別レビュー must-fix 11 件は既に適用済みであり、本横断ゲートはその適用後状態の横断整合を独立確認した（追加適用要求なし）。
- C 群 3 件はいずれも要件横断ゲート由来・設計小節 6 で取り込み先確定済みの上位運用文書同期であり、設計文面内の整合は閉じている（設計承認の前提条件ではない）。3 件とも設計人間承認後の文書同期作業で扱う性質で、上位文書側に同期の受け皿（各 update rule・WORKFLOW_OVERVIEW 節 8 同期ルール・workflow-repair-procedure 節 6・CONVENTIONS 節 6）が存在。C 群適用や不整合是正を設計承認前に強制する必要はない。
- 構造的決定（C-1〜C-3 の本セッション同期か別送りか、依存マップ本体改訂の要否）は本レビュアーは決定せず、利用者判断事項として提示する（REVIEW_PROTOCOL 節 4 / discipline_ssot_structural_decision_check）。

---

## 証跡パス

`/Users/Daily/Development/Rwiki-v2-code-mod/dual-reviewer-rebuild/docs/coordination/design-alignment-gate-2026-05-18-governance.md`（本文書、生証跡・不変）
