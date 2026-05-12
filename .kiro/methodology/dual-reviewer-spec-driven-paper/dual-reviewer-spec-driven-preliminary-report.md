# Preliminary Paper Report — dual-reviewer spec-driven development support

_作成: 2026-05-09_  
_status: draft v0.2_  
_position: intent-origin 仕様駆動開発支援論文の preliminary preview_

prose role:

- `Claim 2 / 3 / 4` の現時点 canonical prose
- paper-facing summary の一次正本

---

## 1. Executive Summary

本報告は、`dual-reviewer` の次段論文化に向けた preliminary report である。

今回の論文では、単独の code review evaluation を主結果に置かず、
**intent 起点の仕様駆動開発支援** を主結果に置く。

現時点で言えることは次である。

1. `dual-reviewer v2` は構築済みであり、governance と conformance review を含む最低限の workflow が成立している
2. manual dogfooding evidence は system construction validity の証拠として利用できる
3. 次の主評価は `Intent Track`, `Spec Track`, `Implementation Track` の 3 分類で整理する
   ここで `Spec Track` は `requirements / design / tasks` を含む中流 bundle を指す
4. code review は主線ではなく implementation/review phase の一部として扱う

本報告では、現行システム名を `dual-reviewer v2` とする。`v3` は future code-conformance evaluation line を指す。

この 3 track は独立 benchmark ではなく、`intent` から implementation まで下る 1 本の workflow story として読む。implementation 側では、`F1-phase-field-cpp-r2` を clean 3-treatment comparison case、`heat3d` をその後半を代表する bridge case として併置する。`heat3d` は workflow validity、implementation-origin evidence、evidence reusability、spec/design underconstraint exposure を同時に示す。

---

## 2. Research Framing

本研究の中心問題は、
LLM code review に複数 agent を入れること自体ではない。

中心問題は、

- `intent` しかない状態で論点漏れや premature closure が起きやすい
- `design/tasks` で detail が増えるほど人間の認知負荷が高まる
- implementation/review phase では disagreement や caveat が落ちやすい
- 手戻りが起きても、どこまで戻るべきかを管理できないと workflow が壊れる

という点である。

この問題に対し、`dual-reviewer` は

- adversarial review
- judgment
- handback / reopen
- governance
- evidence retention

を組み合わせた workflow system として設計されている。

現時点の paper-facing story は、3 track を次のように連結する。

- `Intent Track`
  - 上流 bootstrap と downstream propagation
- `Spec Track`
  - `requirements / design / tasks` の downstream refinement と reopen / alignment
- `Implementation Track`
  - approved upstream artifact に結びついた review acquisition と implementation trace

この連結の後半を代表する bridge case が `heat3d` であり、workflow validity、implementation-origin evidence、evidence reusability、spec/design underconstraint exposure を 1 case にまとめて示す。

---

## 3. Novelty and Intended Appeal

### 3.1 Core novelty

本研究の core novelty は次である。

- `intent` 起点の仕様駆動開発支援を review workflow system として扱う
- finding quality と process/evidence quality を同時に評価する
- implementation/review phase まで含めた end-to-end support を示す

### 3.2 adversarial review の位置づけ

`adversarial review` は novelty の中心ではない。

位置づけ:

- 高認知負荷レビューで見落とし候補を並列化する mechanism
- 単独 reviewer の premature closure を崩す mechanism

`judgment` は、
その結果として増えた候補を整理し、
過剰修正を抑制する mechanism である。

### 3.3 paper appeal

訴求点は次の 3 層で組み立てる。

1. governed intent-driven workflow
2. evidence-preserving downstream support
3. human cognitive load support as a secondary design aim

---

## 4. Current Evidence Status

### 4.1 Already available

- `dual-reviewer v2` system completion
- partial fresh acquisition through the current execution path
- implementation governance formalization
- manual implementation conformance review
- finding fix + rerun evidence
- phase metrics baseline
- intent review baseline
- `heat3d` fixed core case package
- `heat3d` actual implementation + reduced validation evidence
- `heat3d` implementation-origin second-case acquisition (`single / dual / dual+judgment = 2 / 3 / 3`)
- `F1-phase-field-cpp-r2` fresh reacquisition (`single / dual / dual+judgment = 2 / 3 / 3`)
- `heat3d` spec/design underconstraint exposure evidence
- `iot-arduino` generalized first-case pipeline from external intent/spec seed
- `iot-arduino` two-snapshot implementation acquisition with preserved `2 / 3 / 3`
- `Intent Track` fresh first batch (`dual-reviewer-rebuild`)
- `Spec Track` fresh first batch (`phase-field-reverse-spec`)

これらは main evaluation ではなく、
`system construction validity` と `evaluation readiness` を支える evidence として使う。

特に `heat3d` では、

- gate-based workflow が restart / reopen / recheck を含めて回った
- approved upstream artifact から clean-room implementation まで到達できた
- implementation-local rework は `3` 件で upstream reopen は `0` 件だった
- reduced validation は通る一方で reference behavior との差が残った

という 4 点が確認できている。

`F1-phase-field-cpp-r2` では、

- original first snapshot を fresh protocol root に再取得できた
- `single / dual / dual+judgment` の 3 treatment が runtime-backed に揃った
- `dual` は `single` より `+1` finding を持った
- `dual+judgment` は `dual` の finding count を増やさず、judgment-bearing trace を追加した

という 4 点が確認できている。

`iot-arduino` では、

- external `intent.md` と `仕様.md` から generalized case を起動できた
- first implementation snapshot と refined second snapshot の両方で `2 / 3 / 3` を取得できた
- `restart boundary` と `relay fail-safe` は stable safety finding として残った
- `telemetry caveat` は preserved caveat として残った

という 4 点が確認できている。

### 4.2 Remaining gaps

- downstream rework data across additional cases
- disagreement preservation metrics aggregated across tracks
- track 間の large-N comparison
- hardware-ready event-driven implementation evidence

`Intent Track` と `Spec Track` の first batch 自体は取得済みである。これにより、3-track story の前半も first-batch level では acquisition-backed になった。残っているのは、より広い比較と集計である。

---

## 5. Main Evaluation Tracks

### Intent Track

- `intent` から `requirements/design/tasks` を起こすケース
- 主観測:
  - requirement coverage
  - handback depth
  - alignment / reopen control

### Spec Track

- 既存 `requirements/design/tasks` を持つケース
- 主観測:
  - downstream refinement
  - recheck / reopen
  - process/evidence stability

### Implementation Track

- implementation artifact を持つケース
- 主観測:
  - conformance review
  - caveat retention
  - disagreement preservation
  - downstream rework traceability
  - implementation issue と spec/design underconstraint の切り分け

### 5.1 Track continuity

この 3 track は、別々の benchmark 群として置くのではなく、1 本の workflow story として連結して読む。

- `Intent Track`
  - 上流 bootstrap と downstream propagation
- `Spec Track`
  - `requirements / design / tasks` の downstream refinement と reopen / alignment
- `Implementation Track`
  - approved upstream artifact に結びついた review acquisition と implementation trace

implementation 側の読みは 2 層に分ける。`F1-phase-field-cpp-r2` は clean 3-treatment implementation comparison case であり、`single / dual / dual+judgment` の差を最も素直に見せる。一方 `heat3d` は `Spec-origin / Implementation-origin` の両方を持ち、restart, reopen, readability recheck, review acquisition, actual implementation, validation-boundary judgment まで含む長い trace を 1 case に束ねている。したがって本論文では、`F1-phase-field-cpp-r2` を treatment-comparison の main implementation case、`heat3d` を workflow validity、implementation-origin evidence、evidence reusability、spec/design underconstraint exposure を同時に示す bridge case として扱う。

---

## 6. Claims for the Next Paper

### Claim 1

`dual-reviewer` は、意図駆動開発の下流工程で review attention を構造化し、cognitive brittleness を緩和するよう設計されている。

### Claim 2

`dual-reviewer` は、finding だけでなく disagreement, caveat, disposition, handback depth を traceable に残す。

`phase-field` と `heat3d` の 2 case では、review artifact は finding の列挙に留まらず、caveat, disposition, reopen depth, phase evidence summary を同じ case lineage 上に保持した。したがって `dual-reviewer` は、指摘品質だけでなく traceability 自体を成果物として残す workflow system として読める。

`iot-arduino` では、implementation-local refinement を 1 回挟んだ second acquisition 後も `restart boundary`, `relay fail-safe`, `telemetry caveat` が artifact 上に保持された。したがって traceability は first-batch novelty に依存せず、refinement 後の signal persistence としても読める。

さらに fresh `Intent Track / Spec Track` batch でも、`intent handback`, `propagation obligation`, `reopen required`, `intent-attributed issue`, `major correction` が artifact に残った。したがってこの traceability は implementation-present case に限られない。ただし upstream 2 track については、現時点では first-batch level の成立確認として読む。

最小集計 package で見ると、この差分は finding 数の増分よりも preservation pattern の差として表れる。fresh `Intent Track` では dual only で handback depth が残り、fresh `Spec Track` では reopen を維持したまま dual only で major correction が残った。したがって `dual-reviewer` の寄与は、指摘数だけでなく handback, reopen, caveat, disposition を後続工程へ保持する点にもある。

### Claim 3

`dual-reviewer` は、`intent-only`, `spec-present`, `implementation-present` の複数開始条件でも workflow を維持できる。

fresh `Intent Track` の `dual-reviewer-rebuild`, fresh `Spec Track` の `phase-field-reverse-spec`, generalized implementation-first case `iot-arduino`, そして bridge case `heat3d` を合わせると、`dual-reviewer` は少なくとも first-batch level では `intent-only`, `spec-present`, `implementation-present` の 3 開始条件で artifact-preserving workflow を成立させた。`iot-arduino` は external intent/spec seed から start し、requirements defer/reopen, design/tasks gate, review acquisition, two-snapshot implementation acquisition まで 1 本の case lineage で通した。これは `dual-reviewer` が、開始条件や途中手戻りの差を吸収しながら workflow を維持できることの cross-track evidence である。

### Claim 4

`dual-reviewer` は、review 後の evidence を self-improvement / reporting に再利用可能な形で残す。

implementation track では、`F1-phase-field-cpp-r2` と `heat3d` の両方で `boundary`, `update-order`, `parameter-caveat` という finding pattern が再現した。`F1-phase-field-cpp-r2` は clean 3-treatment runtime-backed package として `adversarial` と `judgment` の差を分けて読める。一方 `heat3d` は、reduced validation pass と reference behavior mismatch の併存を通じて、review evidence を downstream reporting と future code-conformance evaluation の両方へ再利用できることを示した。behavior mismatch の責任分解そのものは本文で断定せず、`v3` の code-conformance evaluation に委ねる。

さらに `heat3d` では、actual coding 中の blocking issue `3` 件が upstream reopen `0` のまま implementation local に閉じた。このため implementation track の evidence は、review acquisition の finding pattern だけでなく、downstream rework trace を reporting / self-improvement に再利用できる形でも残ったと読める。

`iot-arduino` では、implementation-local refinement を入れた second snapshot 後も `2 / 3 / 3` が維持された。これは finding count が減らなかったという意味ではなく、`restart boundary` と `relay fail-safe` のような safety-sensitive contract と、`telemetry caveat` のような operational caveat が refinement 後も silent に失われなかった、という evidence として読むべきである。したがって implementation track の evidence は、fix 成功だけでなく signal stability と caveat retention の reporting 再利用にも使える。

---

## 7. Metrics Plan

### 7.1 phase-oriented

- blocking issue count
- nonblocking open point count
- minor adjustment count
- major correction count
- intent-attributed issue count

### 7.2 process-oriented

- handback class distribution
- reopen required count
- conformance finding count
- severity-weighted conformance score

### 7.3 evidence-oriented

- review artifact presence rate
- finding-to-signal link rate
- caveat retention rate
- evidence trace completeness
- disagreement preservation rate

### 7.4 downstream-oriented

- downstream rework event count
- review-to-fix traceability rate
- unresolved finding count

---

## 8. Threats to Validity

現時点で見えている主な threat は次である。

- Intent Track / Spec Track / Implementation Track の case 数がまだ少ない
- `Intent Track` と `Spec Track` の acquisition-backed support は、まだ first-batch level に留まる
- implementation-phase case が scientific / embedded 側に寄っている
- `iot-arduino` は still hardware-ready implementation ではなく snapshot-based evidence に留まる
- manual reference は補助比較に留まる
- ground truth を absolute oracle としない
- model drift の影響がある
- `heat3d` は reduced validation pass と reference behavior mismatch が同居しており、behavioral adequacy と spec conformance を分けて読む必要がある

### 8.1 Interpretation boundary for `heat3d`

`heat3d` の読みには、本文側で明示しておくべき解釈境界が 3 つある。

1. reference behavior mismatch は first-order で implementation defect を意味しない  
   approved upstream artifact だけでは所望挙動を十分拘束できていなかった可能性を残す。

2. canonical full-case acceptance `13.4` は main evidence の admission gate ではない  
   これは behavioral adequacy を見る supplementary evidence であり、workflow / evidence claim の成立条件ではない。

3. responsibility split は `v3` に委ねる  
   `code ↔ tasks/design/requirements` の conformance を別に調べることで、implementation deviation か spec/design underconstraint かを切り分ける。

したがって本報告では、`heat3d` を correctness proof case としてではなく、workflow validity, implementation-origin evidence, evidence reusability, spec underconstraint exposure を束ねた bridge case として扱う。

### 8.2 First-Batch Boundary For `Intent` / `Spec`

`Intent Track` と `Spec Track` は fresh first batch を取得済みだが、本文で強く言うのは次までに留める。

1. `intent-only` と `spec-present` の開始条件でも artifact-preserving workflow が成立した  
2. handback / propagation / reopen / major correction のような process evidence が残った  
3. ただし large-N comparison や domain-general regularity まではまだ主張しない

したがって、この 2 track の本文上の役割は first-batch level の workflow support evidence であり、成熟した benchmark 比較ではない。

---

## 9. Immediate Next Work

1. [cross-track-metric-aggregation-first-package.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-metric-aggregation-first-package.md:1) の compressed reading を claim prose に織り込む
2. [heat3d-supplementary-behavioral-evidence-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-supplementary-behavioral-evidence-note.md:1) を supplementary boundary の正本として維持する
3. large-N comparison を追加して first-batch boundary を越える

---

## 10. Readiness Summary

| area | status | note |
|------|--------|------|
| system construction validity | `ready` | `dual-reviewer v2` completion and governance evidence available |
| track framing | `ready` | intent-origin framing restored |
| implementation-phase setup | `ready` | `phase-field` baseline と `heat3d` second-case acquisition を取得済み |
| main paper evidence | `partially ready` | cross-track first-batch prose と最小集計 package は統合済み、large-N comparison が残る |

現時点では、
「論文の主張構成は整い、`heat3d` の core evidence と cross-track first-batch prose は main paper に統合済みだが、追加比較と集計はまだ残っている」
という状態である。
