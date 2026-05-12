# Active Worklist

_作成: 2026-05-10_  
_status: active control sheet_  
_purpose: 目先の実装で主線を見失わないための固定 worklist_

---

## 1. この文書の役割

この文書は、`dual-reviewer` 論文化準備とデータ取得について、
**今なにが完了し、なにが未完了で、次に何をすべきか**を固定するための作業台帳である。

この文書は単なる TODO ではない。

- static spec を置き換えるものではない
- しかし LLM 協調下で spec を正しい順序で運用するための
  **execution-control artifact** である
- `intent` を最上位に置く開発を、実行時に破綻させないための
  **dynamic control board** である

今回の試行錯誤で得た重要な finding:

1. `LLM + spec-driven development` では、static spec だけでは進行制御が足りない
2. LLM は局所的未完に引っ張られ、上位拘束と順序を見失いやすい
3. そのため、`ACTIVE_WORKLIST` のように
   - workflow 上の現在地
   - 現在の blocker
   - exit condition
   - stop rule
   - reopen 状態
   を固定する artifact が必要
4. また、実際に駆動源になっているのは `requirements/design/tasks` 単体ではなく
   **`intent` を最上位に置いた intent-governed development** である

したがって、この文書は
**「仕様駆動開発の作業メモ」ではなく、「意図駆動開発を LLM で運用するための制御板」**
として扱う。

また、この文書は reusable protocol ではなく **case instance** である。  
新しい case では、この全文をコピーするのではなく、
[active-worklist-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/active-worklist-template.md:1)
から最小 control board を生成して使う。

ただし、この文書は workflow 手順そのものの正本ではない。

- phase の順序
- review wave の順序
- feature 間調整
- 承認 gate

の正本は [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1) とする。

この文書の責務は、

- workflow 上の現在地点
- 現在の実行単位
- 現在の blocker
- その step の exit condition
- 現在参照している作業 artifact
- stop rule

を固定することに限る。

以後の作業では、次を必ず守る。

1. 新しい作業に入る前にこの文書を確認する
2. `claim-case-matrix.md` に反する作業は進めない
3. 未完了 phase を飛ばして `main evidence` 議論へ進まない
4. 次の行動は、この文書の `Current Workflow Step` と `Exit Condition` に従う

---

## 1.5 運用境界

この試行で確認された重要点:

- `HUMAN_WORKFLOW.md` は procedure の正本である
- `ACTIVE_WORKLIST.md` は procedure を再記述せず、現在地と現在の実行単位を指す control board である
- `execution-control-ledger.md` は redesign input ledger であり、進行順序や gate 判定の正本ではない

したがって運用は次の分担で行う。

- workflow が順序と gate を決める
- `ACTIVE_WORKLIST` が current step, current action, blocker, exit condition を指す
- `ECL` が generic execution layer v2 再設計の入力制約を供給する

この 3 者の責務を混ぜてはならない。

- `ACTIVE_WORKLIST` が workflow 手順を再定義しない
- `ECL` が current next step を持たない
- workflow の gate 判定を `ACTIVE_WORKLIST` や `ECL` に移さない

---

## 1.6 次手判断ルール

次の手順を提案したり review 対象を挙げたりする前に、必ず次の 3 点を先に固定する。

1. `Current Workflow Step` は何か
2. 今 review / 修正すべき文書種別は何か
3. どの feature 順で見るか

この 3 点を飛ばして、会話だけで「次は何か」を決めてはならない。

文書種別の判定規則:

- `requirements draft` 後はまず feature ごとの local review を行う
- `requirements review wave` 中は揃った active feature の `requirements.md` を横断して見る
- `requirements gate` 前には対応する `requirements review wave` 完了を確認する
- `requirements alignment gate` 中は各 feature の `requirements.md` を依存順で見る
- `requirements approval gate` 中は `requirements.md` と alignment artifact を見る
- `design draft` 後はまず feature ごとの local review を行う
- `design review wave` 中は揃った active feature の `design.md` を横断して見る
- `design gate` 前には対応する `design review wave` 完了を確認する
- `design alignment gate` 中は各 feature の `design.md` を依存順で見る
- `design approval gate` 中は `design.md` と alignment artifact を見る
- `tasks draft` 後はまず feature ごとの local review を行う
- `tasks review wave` 中は揃った active feature の `tasks.md` を横断して見る
- `tasks gate` 前には対応する `tasks review wave` 完了を確認する
- `tasks alignment gate` 中は各 feature の `tasks.md` を依存順で見る

依存順の判定規則:

- 共通契約 owner を先に見る
- 実行本体を次に見る
- 下流 consumer は後で見る

generic execution layer v2 の design phase では、次の順を固定する。

1. `dual-reviewer-generic-execution-layer-v2/design.md`
2. `dual-reviewer-foundation/design.md`
3. `dual-reviewer-runtime/design.md`
4. `dual-reviewer-evaluation/design.md`
5. `dual-reviewer-self-improvement/design.md`
6. `dual-reviewer-paper-interface/design.md`

generic execution layer v2 の tasks phase では、次の順を固定する。

1. `dual-reviewer-generic-execution-layer-v2/tasks.md`
2. `dual-reviewer-foundation/tasks.md`
3. `dual-reviewer-runtime/tasks.md`
4. `dual-reviewer-evaluation/tasks.md`
5. `dual-reviewer-self-improvement/tasks.md`
6. `dual-reviewer-paper-interface/tasks.md`

以後、次の手順説明では必ず

- 現在の phase
- 現在見る文書種別
- feature 順

を明示してから、具体的な action を述べる。

---

## 2. 正本の優先順位

この順序で拘束される。

1. [dual-reviewer-spec-driven-paper-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-paper-plan.md:1)
2. [claim-case-matrix.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md:1)
3. [dual-reviewer-spec-driven-case-manifest.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-case-manifest.md:1)
4. core case 文書
5. first-run case 文書
6. この worklist

補足:

- ここでの `spec-driven` は、実態としては `intent` に統治された spec 運用である
- spec は正本だが最上位ではない
- 最上位拘束は `intent` と、それに整合する claim / case / workflow である
- workflow の phase 順序と承認 gate は [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1) を正本とする

---

## 3. 現在の前提

### 3.1 Current Control Assumptions

- 今は **main evidence 取得段階ではない**
- 今は **workflow operation validation と case expansion の段階** である
- current control target は `C-3 heat3d` の gate-only trial である
- この trial では `intent -> discovery checkpoint -> requirements -> design -> tasks -> implementation` の順序を保てるかを first-class に確認する
- 人間は gate の承認者であり、Codex は gate の代行者ではない
- `requirements/design/tasks` は中間媒体であり、`intent` に照らして reopen / handback / 再解釈されうる
- よって、phase 完了だけでなく `Current Next Step` と `Stop Rules` による実行制御が必要である
- restart 後の current step では、single-feature 前提を固定せず、discovery checkpoint で active feature set を確認する
- multi-feature alignment gate は feature set 確定後に適用有無を判定する

### 3.2 Historical Baseline

- `phase-field` 系で intent / spec / implementation の pilot acquisition は取得済みである
- `phase-field-cpp` は representative implementation baseline として `single / dual / dual+judgment` の 3 treatment を取得済みである
- ただし、`phase-field` pilot は **case-specific heuristic 実装** を含む
- この baseline は比較用・履歴用には有効だが、そのまま main evidence や generic method の正本には昇格させない

### 3.3 Operational Constraint

- case-specific heuristic を積み増して新 case を通す方向では進めない
- `heat3d` trial で workflow を通す際も、case 固有 rule 追加ではなく gate operation の成立を優先して見る

---

## 4. Phase Coverage Status

### 4.1 Current Trial Coverage (`heat3d`)

| phase | current status | approval status | note |
|---|---|---|---|
| `intent` | fixed input | approved | [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1) と canonical source を固定済み |
| `requirements` | approved | approved | active feature の requirements draft、local review、requirements review wave、alignment gate、evidence summary を経て human requirements gate を通過 |
| `design` | approved | approved | active feature 4 本の `design.md` 初稿、local design review、design review wave、alignment gate、evidence summary を経て human design gate を通過 |
| `tasks` | approved | approved | active feature 4 本の tasks draft、local review、tasks review wave、alignment gate、evidence summary を経て human tasks gate を通過 |
| `review acquisition` | acquired | approved | gate-approved boundary で `single / dual / dual+judgment` を再取得し comparison summary を更新 |
| `implementation` | completed | approved | `/Users/Daily/Development/DR-heat3d` に source tree を起こし、unit/smoke validation を通過 |

### 4.2 Historical Pilot Coverage (`phase-field` baseline)

| phase | current status | evidence type | note |
|---|---|---|---|
| `intent` | pilot acquired | source-driven heuristic | `dual-reviewer-rebuild` case |
| `requirements` | pilot acquired | source-driven heuristic | `phase-field-reverse-spec` case |
| `design` | pilot acquired | source-driven heuristic | `phase-field-reverse-spec` case |
| `tasks` | pilot acquired | source-driven heuristic | `phase-field-reverse-spec` case |
| `implementation` | pilot acquired | source-driven heuristic | `phase-field-cpp` case |

---

## 5. Done

### 5.1 Current Trial Setup (`heat3d`)

- `heat3d-spec` intent を canonical source 付きで固定
- gate-only trial protocol を追加
- workflow path trace artifact を追加
- `heat3d-spec/spec.json` を初期化
- `heat3d-julia` implementation pilot を別取得済み baseline として保持
- discovery artifact として `brief.md` / `research.md` を追加
- active feature spec として `heat3d-foundation`, `heat3d-linear-solver`, `heat3d-case-model`, `heat3d-main` を起票
- active feature requirements draft / local review / requirements review wave / alignment artifact を取得
- `requirements-evidence-summary.md` を gate package derived artifact として取得
- human gate で指摘された readability issue を requirements recheck と alignment recheck で吸収
- human `requirements gate` を通過し、requirements phase を approved に固定
- active feature 4 本の `design.md` 初稿を作成し、design phase を generated に進めた
- active feature 4 本の local design review artifact を作成し、feature-local blocking issue を解消した
- design review wave / alignment gate / design-evidence-summary を取得し、design gate package を固定した
- human `design gate` を通過し、design phase を approved に固定した
- active feature 4 本の `tasks.md` 初稿を作成し、tasks phase を generated に進めた
- active feature 4 本の local tasks review artifact を作成し、feature-local blocking issue を解消した
- tasks review wave / alignment gate / tasks-evidence-summary を取得し、tasks gate package を固定した
- human `tasks gate` を通過し、tasks phase を approved に固定した
- review acquisition preparation memo と review acquisition gate summary を作成し、review acquisition gate package を固定した
- `ready_for_review_acquisition` を true に更新し、review acquisition 入力境界を current state に反映した
- gate-approved upstream bundle で review acquisition batch を再実行し、`single / dual / dual+judgment` の comparison summary を更新した
- `/Users/Daily/Development/DR-heat3d` に actual implementation を追加し、`Project.toml`, `src/`, `test/` を新規作成した
- implementation 中の blocking issue 3 件を coding layer 内で解消し、upstream phase への reopen なしで閉じた
- `julia --project=. test/runtests.jl` を実行し、`grid and boundary contract`, `case-model contract`, `solver invariants`, `main integration` を pass させた

refs:
- [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)
- [heat3d-gate-only-trial.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-gate-only-trial.md:1)
- [heat3d-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-workflow-path.md:1)
- [review-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/review-acquisition-summary.md:1)
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/implementation-evidence-summary.md:1)

### 5.2 Historical Pilot Baseline (`phase-field`)

- `phase-field` implementation pilot runner
- `single_review` / `dual_review` / `dual_reviewer_workflow` batch execution
- `phase-field-reverse-spec` requirements / design / tasks pilot acquisition
- `dual-reviewer-rebuild` bootstrap intent pilot acquisition

refs:
- [implementation comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json:1)
- [tasks comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/comparison_summary.json:1)
- [requirements comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/comparison_summary.json:1)
- [design comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/comparison_summary.json:1)
- [intent comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/comparison_summary.json:1)

---

## 6. Not Done

### 6.1 Current Trial Gap (`heat3d`)

- `heat3d` を v3 code-conformance evaluation case として保存する判断は記録済みである
- canonical full-case acceptance `13.4` は main evidence 必須条件にはせず、supplementary behavioral evidence として扱う

### 6.2 Trial Success Still Unproven

まだ未証明なのは次である。

1. gate-only 承認モデルで workflow が破綻しないか
2. 人間判断が必要な局面で Codex が適切に停止できるか
3. reopen / query / gate trace を artifact として残せるか
4. `heat3d` が `C-3` の `Spec-origin / Implementation-origin` を一つの流れで満たせるか

### 6.3 Historical Baseline Limit

`phase-field` baseline は参考にはなるが、
current control target の正本ではない。

理由:

1. `phase-field` は case-specific heuristic を含む
2. `heat3d` trial で見たいのは finding 数よりも gate operation の成立である
3. current step の意思決定を historical baseline に引っ張られてはならない

### 6.4 Generic Execution Layer Redesign

generic execution layer v2 は未完了であり、trial 中も open constraint として保持する。

status:
- `case-specific hardcode inventory`: completed
- `generic execution layer v2` 上位仕様: completed
- `dual-reviewer-generic-execution-layer-v2` requirements: approved
- `dual-reviewer-generic-execution-layer-v2` design: approved
- `dual-reviewer-generic-execution-layer-v2` design alignment: completed
- `dual-reviewer-generic-execution-layer-v2` tasks: approved
- `dual-reviewer-generic-execution-layer-v2` tasks alignment: completed

refs:
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
- [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1)
- [generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md:1)

---

## 7. Current Workflow Step

`post-report comparison planning`

authoritative workflow ref:
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:215)

why this is the current step:
- `F2-heat3d-julia` の implementation pilot は取得済みである
- gate-approved boundary での review acquisition も再取得済みである
- `phase-field` baseline との比較 note は取得済みである
- `C-3 heat3d` evidence bundle も取得済みである
- `heat3d` の fixed core case judgment は文書化済みである
- `/Users/Daily/Development/DR-heat3d` で actual implementation も完了し、implementation-local rework data も取得済みである
- main paper 用の observation note は作成済みである
- preliminary report と paper plan への一次統合も完了した
- `core-case-heat3d` と `heat3d-c3-evidence-bundle` への claim-supporting text 追加も完了した
- `phase-field` と `heat3d` を並べた cross-case synthesis note も作成済みである
- `dual-reviewer-spec-driven-paper-plan.md` の `Claim 2 / 3 / 4` に paragraph candidate も追加済みである
- `dual-reviewer-spec-driven-preliminary-report.md` の `Claim 2 / 3 / 4` も cross-case prose に更新済みである
- preliminary report を本文正本、paper plan を planning source とする役割分担は固定済みである
- cross-track narrative note も作成済みである
- preliminary report の Main Evaluation Tracks に cross-track continuity paragraph も追加済みである
- preliminary report の Threats to Validity に `heat3d` の interpretation boundary も追加済みである
- `Intent Track / Spec Track` の未取得分を narrative gap として整理した bridge note も作成済みである
- `Intent Track / Spec Track / first-run` 計画文書にも narrative role を反映済みである
- execution preparation note も作成済みである
- `Intent Track / Spec Track` の fresh narrative batch 実行も完了した
- first-batch acquisition summary により、旧 pilot と current narrative batch の provenance 分離もできた
- したがって次に必要なのは、同期済み prose を固定したうえで、追加比較と集計の planning に戻ることである
- 今回の試行では、gate operation、review acquisition、actual implementation、spec underconstraint reading を分けて記録する必要がある

---

## 8. Current Blocker

- current blocker はない
- remaining track の first batch も取得済みで、caveat の置き場所と editorial redundancy の圧縮も完了した
- additional comparison / metric aggregation の planning note と `heat3d` supplementary behavioral note を追加した
- first aggregation package も作成した
- compressed reading も claim prose へ反映したので、次は residual redundancy を落としつつ supporting note との役割を固定する段階に進める

---

## 9. Current Action

直近の action は、固定済み prose と caveat 配置を保ったまま
**claim prose に入れた compressed reading と supporting note の役割分担を固定すること**
である。

直近の action は次の 4 点である。

- `brief.md` / `research.md` を discovery artifact として維持する
- active feature set を spec artifact として維持する
- approved upstream bundle と review acquisition gate package を acquisition boundary の正本として維持する
- evidence bundle と comparison note を claim drafting の入口として使う
- implementation evidence summary を coding-layer rework の正本として維持する
- `tasks` phase の finding 数と carry-over risk を review acquisition result の読み筋に接続する
- implementation-local rework 3 件が upstream reopen を起こしていないことを judgment に反映する
- `heat3d-v3-evaluation-note.md` を v3 保存記録として維持する
- `heat3d-case-fixation-decision.md` を fixed-case judgment の正本として維持する
- `heat3d-main-paper-observation-note.md` を paper-facing summary として維持する
- preliminary report と paper plan の heat3d 記述を claim-supporting sentence の候補として扱う
- `core-case-heat3d.md` と `heat3d-c3-evidence-bundle.md` の claim-supporting text を claim 本文の source paragraph として扱う
- `claim-2-3-4-cross-case-synthesis.md` を final phrasing の source note として扱う
- `dual-reviewer-spec-driven-paper-plan.md` の `current paragraph candidate` を正式 claim prose の叩き台として扱う
- `dual-reviewer-spec-driven-preliminary-report.md` の `Claim 2 / 3 / 4` を現時点の canonical prose として扱う
- `dual-reviewer-spec-driven-paper-plan.md` は planning source / fallback source として扱う
- `heat3d-validation-boundary-decision.md` を validation boundary の正本判断として扱う
- `cross-track-narrative-note.md` を track 横断 story の source note として扱う
- `dual-reviewer-spec-driven-preliminary-report.md` の Threats 節を `heat3d` interpretation boundary の canonical placement として扱う
- `remaining-track-acquisition-bridge-note.md` を残り acquisition の narrative role 定義として扱う
- `intent-track-first-run-plan.md` と `spec-track-first-run-plan.md` を narrative-connected execution plan として扱う
- `remaining-track-acquisition-execution-preparation.md` を concrete execution prep の正本として扱う
- `remaining-track-first-batch-acquisition-summary.md` を fresh provenance summary として扱う
- `heat3d-main-paper-observation-note.md` を `heat3d` caveat placement の source note として扱う
- `cross-track-metric-aggregation-plan.md` を追加比較と集計設計の正本として扱う
- `cross-track-metric-aggregation-first-package.md` を最小比較 package の正本として扱う
- `heat3d-supplementary-behavioral-evidence-note.md` を supplementary behavioral boundary の正本として扱う

この action では、次を確認対象にする。

- gate-approved acquisition 結果を claim narrative に十分写せているか
- implementation issue と upstream spec issue の切り分けを artifact に残せているか
- `single / dual / dual+judgment` の差分を中身で説明できるか
- clean-room exclusion が acquisition 中に破られていないか
- implementation validation の current boundary を main evidence でどう扱うかを明示できるか
- fresh `Intent Track / Spec Track` batch の読みを preliminary report, paper plan, synthesis note に無理なく接続できるか
- `first-batch level` の限定と `v3` 委譲文が本文と補助文書で矛盾していないか
- additional case / additional metric をどこに足すと main paper の弱点を最も減らせるか
- `Claim 2 / 3 / 4` に入れる最小集計 package を 1 表または 1 段落まで圧縮できるか
- その compressed reading を existing claim prose に重複なく統合できるか
- integrated prose と supporting table の重複をどこまで残すか

---

## 10. Exit Condition

この step は、次が満たされたら完了とみなす。

1. fresh `Intent Track / Spec Track` batch が provenance 分離された形で残る
2. `remaining-track-first-batch-acquisition-summary.md` で 2 track の result を 1 枚で読める
3. preliminary report 側で `Intent / Spec / Implementation` の 3-track story が acquisition-backed と書ける
4. implementation issue と upstream spec issue の切り分けを claim 文面へ残せる
5. validation 留保を supplementary behavioral evidence として main paper の書き方へ落とせる
6. `first-batch level` と `v3` delegation の caveat placement が report / note 間で揃う
7. 次の step を additional comparison planning に移せる
8. minimal aggregation package の source metric と supplementary note の置き場所を固定できる
9. first aggregation package の compressed reading を本文へ再利用できる
10. report 本文と supporting note の役割分担を固定できる

---

## 11. Working Artifact

- [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/spec.json:1)
- [heat3d-foundation/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/design.md:1)
- [heat3d-linear-solver/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/design.md:1)
- [heat3d-case-model/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/design.md:1)
- [heat3d-main/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/design.md:1)
- [heat3d-foundation/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-foundation/tasks.md:1)
- [heat3d-linear-solver/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-linear-solver/tasks.md:1)
- [heat3d-case-model/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-case-model/tasks.md:1)
- [heat3d-main/tasks.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-main/tasks.md:1)
- [tasks-review-wave-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/tasks-review-wave-2026-05-11.md:1)
- [tasks-alignment-2026-05-11.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/tasks-alignment-2026-05-11.md:1)
- [tasks-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/tasks-evidence-summary.md:1)
- [heat3d-review-acquisition-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-review-acquisition-preparation.md:1)
- [review-acquisition-gate-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/review-acquisition-gate-summary.md:1)
- [review-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/reviews/review-acquisition-summary.md:1)
- [heat3d-implementation-execution-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-execution-note.md:1)
- [heat3d-phase-field-implementation-comparison-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-phase-field-implementation-comparison-note.md:1)
- [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)
- [heat3d-v3-evaluation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-v3-evaluation-note.md:1)
- [heat3d-case-fixation-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-case-fixation-decision.md:1)
- [heat3d-main-paper-observation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-main-paper-observation-note.md:1)
- [cross-track-metric-aggregation-plan.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-metric-aggregation-plan.md:1)
- [cross-track-metric-aggregation-first-package.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-metric-aggregation-first-package.md:1)
- [heat3d-supplementary-behavioral-evidence-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-supplementary-behavioral-evidence-note.md:1)
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F2-heat3d-julia/comparison_summary.json:1)
- [heat3d-gate-only-trial.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-gate-only-trial.md:1)
- [heat3d-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-workflow-path.md:1)
- [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1)
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)

---

## 12. Next Handoff

この trial 整備の次は、claim prose の正本と residual caveat の書き方を固定する。

その際は、

1. `intent` を最上位拘束として使う
2. canonical source を `/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md` に固定する
3. discovery checkpoint で固定した active feature set と dependency order を保つ
4. gate-approved upstream bundle と review acquisition gate package を acquisition boundary の正本として使う
5. ambiguity が残ったら停止して問い合わせる

を守る。

補足:

- 実装完了後に「生成物が `intent / requirements / design / tasks` と一致しているか」を検査する conformance 評価は、有益な後続テーマとして認識された
- ただしこれは `generic execution layer v2` の完了条件には含めず、今の開発が終わった後に `v3` の主評価テーマとして扱う
- したがって現段階では、`v2` の残課題と混ぜず、future handoff item としてのみ保持する

---

## 13. Stop Rules

次の場合は作業を止めて確認する。

1. case 固有の rule を足せばよい、と考えた
2. main-evidence 昇格を言いたくなったが、generic execution layer が未定義
3. provisional case を fixed 扱いしたくなった
4. `claim-case-matrix.md` にない case を main evidence 側へ入れたくなった
5. 直前の作業が `Current Workflow Step`、`Current Action`、または `Exit Condition` と一致しない
6. `requirements/design/tasks` だけを見て、`intent` との整合確認を飛ばしたくなった
7. static spec があるので worklist は不要だ、と考えた
8. 人間承認がまだないのに次 phase へ進みたくなった
9. runtime-affecting な選択肢を問い合わせなしで決めたくなった
