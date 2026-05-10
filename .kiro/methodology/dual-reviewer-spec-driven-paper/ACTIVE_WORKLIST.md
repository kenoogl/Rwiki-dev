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
   - 現在地
   - 次の 1 手
   - stop rule
   - reopen 状態
   を固定する artifact が必要
4. また、実際に駆動源になっているのは `requirements/design/tasks` 単体ではなく
   **`intent` を最上位に置いた intent-governed development** である

したがって、この文書は
**「仕様駆動開発の作業メモ」ではなく、「意図駆動開発を LLM で運用するための制御板」**
として扱う。

以後の作業では、次を必ず守る。

1. 新しい作業に入る前にこの文書を確認する
2. `claim-case-matrix.md` に反する作業は進めない
3. 未完了 phase を飛ばして `main evidence` 議論へ進まない
4. 次の 1 手は、この文書の `Current Next Step` に従う

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
- `generic execution layer v2` 上位仕様: in progress

refs:
- [execution-control-ledger.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/execution-control-ledger.md:1)
- [generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md:1)

---

## 7. Current Next Step

**`generic execution layer v2` の上位仕様を正本化し、spec-driven で v2 を起こす。**

具体的には次の順。

1. `ECL` を v2 再設計入力台帳として固定する
2. generic execution layer v2 の入力 / 出力 / taxonomy / layer boundary を定義する
3. その仕様を `requirements/design/tasks` に落とす
4. 置換順を固定する
5. その後に `phase-field` pilot を取り直す

---

## 8. After That

generic execution layer を定義した後に、pilot を取り直す。

順序は固定:

1. generic execution layer redesign
2. `phase-field` で pilot 再取得
3. 再取得結果の安定性確認
4. その後に main-evidence 昇格条件を固定
5. さらに scope を拡大

---

## 9. Stop Rules

次の場合は作業を止めて確認する。

1. case 固有の rule を足せばよい、と考えた
2. main-evidence 昇格を言いたくなったが、generic execution layer が未定義
3. provisional case を fixed 扱いしたくなった
4. `claim-case-matrix.md` にない case を main evidence 側へ入れたくなった
5. 直前の作業が `Current Next Step` と一致しない
6. `requirements/design/tasks` だけを見て、`intent` との整合確認を飛ばしたくなった
7. static spec があるので worklist は不要だ、と考えた
