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

- `requirements review wave` 中は `requirements.md` を見る
- `requirements alignment gate` 中は各 feature の `requirements.md` を依存順で見る
- `requirements approval gate` 中は `requirements.md` と alignment artifact を見る
- `design review wave` 中は `design.md` を見る
- `design alignment gate` 中は各 feature の `design.md` を依存順で見る
- `design approval gate` 中は `design.md` と alignment artifact を見る
- `tasks review wave` 中は `tasks.md` を見る
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

- 今は **main evidence 取得段階ではない**
- 今は **acquisition tooling と pilot acquisition を全 phase に通す段階** である
- fixed core case は現状 `phase-field`
- `heat3d` と `iot-arduino` は provisional のまま
- `phase-field pilot only` の範囲で tooling を揃えている
- ただし、現在の `phase-field` pilot は **case-specific heuristic 実装** を含む
- この case-specific 実装は
  - 新しい case へ一般化できない
  - 実装を書き換えると同じ case でも結果が変わりうる
  - main evidence だけでなく reusable pilot method としても不適切
- したがって、**case profile ごとに review rule を増やす方向では進めない**

追加前提:

- 本開発は、狭義の「仕様駆動開発」ではなく
  **intent-governed spec-driven development**
  として扱う
- `requirements/design/tasks` は中間媒体であり、
  `intent` に照らして reopen / handback / 再解釈されうる
- よって、phase 完了だけでなく
  `Current Next Step` と `Stop Rules` による実行制御が必要

---

## 4. Phase Coverage Status

| phase | current status | evidence type | note |
|---|---|---|---|
| `intent` | pilot acquired | source-driven heuristic | `dual-reviewer-rebuild` case |
| `requirements` | pilot acquired | source-driven heuristic | `phase-field-reverse-spec` case |
| `design` | pilot acquired | source-driven heuristic | `phase-field-reverse-spec` case |
| `tasks` | pilot acquired | source-driven heuristic | `phase-field-reverse-spec` case |
| `implementation` | pilot acquired | source-driven heuristic | `phase-field-cpp` case |

---

## 5. Done

### 5.1 Implementation Track

- `phase-field` implementation pilot runner
- `single_review` / `dual_reviewer_workflow` batch execution
- non-empty findings
- comparison summary

refs:
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json:1)

### 5.2 Spec Track (`tasks`)

- `phase-field-reverse-spec` tasks case runner
- reopen / recheck / intent-attributed issue / metrics
- comparison summary

refs:
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/comparison_summary.json:1)

### 5.3 Intent Track

- `dual-reviewer-rebuild` bootstrap case runner
- major gap / scope drift / counter-hypothesis / handback / propagation
- comparison summary

refs:
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/comparison_summary.json:1)

### 5.4 Spec Track (`requirements` / `design`)

- `phase-field-reverse-spec` requirements case runner
- `phase-field-reverse-spec` design case runner
- reopen / recheck / intent-attributed issue / metrics
- comparison summaries

refs:
- [requirements comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/comparison_summary.json:1)
- [design comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/comparison_summary.json:1)

---

## 6. Not Done

### 6.1 Requirements Phase

- `phase-field-reverse-spec` requirements execution layer
- `single_review` / `dual_reviewer_workflow` pilot batch
- requirements-specific metrics snapshot
- comparison summary

status:
- completed as pilot acquisition

refs:
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-requirements-phase-field-reverse-spec/comparison_summary.json:1)

### 6.2 Design Phase

- `phase-field-reverse-spec` design execution layer
- `single_review` / `dual_reviewer_workflow` pilot batch
- design-specific metrics snapshot
- comparison summary

status:
- completed as pilot acquisition

refs:
- [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-design-phase-field-reverse-spec/comparison_summary.json:1)

### 6.3 Main-Evidence Readiness

pilot acquisition 条件は満たした。  
ただし main evidence へはまだ昇格しない。

次に必要なのは:

1. case-specific heuristic 実装を除去する方針を固める
2. case 非依存の generic review execution layer を定義する
3. pilot artifact schema を保ったまま generic layer に差し替える
4. その後に main-evidence 昇格条件を議論する

### 6.4 Generic Execution Layer Redesign

ここが現在の最優先 blocker。

解くべき問題:

1. `phase-field` 固有の finding 文面や cue に依存している
2. `Spec Track` の analysis が case id / file ref で直分岐している
3. 同じ case でも実装変更で結果が変わり、比較基盤として不安定

必要な方向:

1. 入力 artifact から generic に review prompt / review observation を作る
2. finding は case 名ではなく
   - gap type
   - inconsistency type
   - caveat type
   - handback / reopen class
   の taxonomy で表現する
3. case 固有性は
   - input artifact
   - extracted evidence
   - final finding text
   にのみ残し、execution rule 自体には埋め込まない

status:
- `case-specific hardcode inventory`: completed
- `generic execution layer v2` 上位仕様: completed
- `dual-reviewer-generic-execution-layer-v2` requirements: approved
- `dual-reviewer-generic-execution-layer-v2` design: approved
- `dual-reviewer-generic-execution-layer-v2` design alignment: completed

refs:
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
- [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1)
- [generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md:1)
- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-generic-execution-layer-v2/requirements.md:1)

---

## 7. Current Workflow Step

`tasks generation`

authoritative workflow ref:
- [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:215)

why this is the current step:
- `dual-reviewer-generic-execution-layer-v2` requirements review では blocking finding が消えた
- requirements-phase の feature 間調整結果を [cross-spec-generic-execution-layer-v2-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-generic-execution-layer-v2-requirements-alignment.md:1) に記録した
- requirements は approve 済みになった
- `design.md` 初版を生成した
- design review を 6 feature 順で実施した
- design alignment 結果を [cross-spec-generic-execution-layer-v2-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-generic-execution-layer-v2-design-alignment.md:1) に記録した
- design は approve 済みになった
- したがって、次は tasks 初版を作成する段階である

---

## 8. Current Blocker

- approved design を実装単位へ落とした `tasks.md` がまだ存在しない
- implementation order と shared migration timing を task 単位で具体化していない

---

## 9. Current Action

`dual-reviewer-generic-execution-layer-v2` の `tasks.md` 初版を作成する。

この action では、次を確認対象にする。

- implementation order を切れること
- shared artifact migration timing を task に落とせること
- validator / rerun / comparison 再取得まで task 化できること

この文書はここで tasks 手順自体を再定義しない。phase の進め方と gate の成立条件は [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:215) を正本とする。

---

## 10. Exit Condition

この step は、次が満たされたら完了とみなす。

1. design approval の記録が feature 状態に反映されている
2. `tasks.md` 初版が生成される
3. tasks review に進める前提となる implementation order と shared migration timing が明示される

---

## 11. Working Artifact

- [requirements.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-generic-execution-layer-v2/requirements.md:1)
- [design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/dual-reviewer-generic-execution-layer-v2/design.md:1)
- [cross-spec-generic-execution-layer-v2-requirements-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-generic-execution-layer-v2-requirements-alignment.md:1)
- [cross-spec-generic-execution-layer-v2-design-alignment.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/cross-spec-generic-execution-layer-v2-design-alignment.md:1)
- [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1)
- [generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md:1)

---

## 12. Next Handoff

tasks 初版を起こした後に、workflow に従って tasks review と必要な tasks alignment へ進む。この文書では手順自体を再定義しない。

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
