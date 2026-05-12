# iot-arduino C-4 evidence bundle

_作成: 2026-05-12_  
_status: bundle v0.2_  
_role: `C-4 iot-arduino` の workflow / spec / review acquisition / two-snapshot implementation evidence を 1 本に束ねる_

---

## 1. scope

- case id:
  - `C-4-iot-arduino`
- class:
  - `Intent-origin`
  - `Spec-origin`
  - `Implementation-origin`
- language:
  - Arduino / C++
- canonical source:
  - `/Users/Daily/Development/DR-IoT/intent.md`
  - `/Users/Daily/Development/DR-IoT/仕様.md`
- intent:
  - [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/intent.md:1)

この bundle は、`iot-arduino` で次の 2 点がどこまで確認できたかを束ねる。

1. 一般化後の意図駆動 workflow が event-driven IoT case でも gate ベースで回るか
2. first implementation snapshot と refined second snapshot に対して `single / dual / dual+judgment` がどう読めるか

---

## 2. upstream spec package

### 2.1 umbrella

- [spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/spec.json:1)
- [core-case-iot-arduino.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md:1)

### 2.2 active feature set

- [iot-arduino-loop-outside-control](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/spec.json:1)
- [iot-arduino-watering-loop](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/spec.json:1)

dependency order は
`loop-outside-control -> watering-loop`
で固定した。

---

## 3. phase evidence

### 3.1 requirements

- gate package:
  - [requirements-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/requirements-evidence-summary.md:1)
- totals:
  - `5 findings`
  - `5 blocking`
  - `5 fixed`
  - `1 recheck`

この phase では、最初の `6 feature` 分解が細かすぎると判明し、
最初の feature 分割提案は human に reject され、
対話的な修正議論を経て `2 feature` へ畳み直した。

### 3.2 design

- gate package:
  - [design-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/design-evidence-summary.md:1)
- totals:
  - `6 findings`
  - `6 blocking`
  - `6 fixed`

主に `loop entry -> loop outcome -> final status` の handoff chain と、
thin entrypoint rule を固定した。

### 3.3 tasks

- gate package:
  - [tasks-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/tasks-evidence-summary.md:1)
- totals:
  - `6 findings`
  - `6 blocking`
  - `6 fixed`

主に implementation order、shared file owner、feature-local smoke と controller smoke の順序を固定した。

---

## 4. workflow evidence

- workflow trace:
  - [iot-arduino-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-workflow-path.md:1)
- active worklist:
  - [iot-arduino-active-worklist.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-active-worklist.md:1)
- case overlay:
  - [iot-arduino-case-workflow-overlay.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-workflow-overlay.md:1)

この case で実際に観測された workflow 上の特徴は次である。

1. start は短い指示 `この intent と仕様から case を始めてください` から入れた
2. requirements gate で最初の `6 feature` 分割提案が reject され、修正案の議論を経て `2 feature` へ reopen した
3. その後は `requirements -> design -> tasks -> review acquisition` の順で gate を通した
4. implementation source tree を approved tasks 後に fresh spec-origin tree として作成した

つまり、`iot-arduino` は

- short-command start
- human reject and recomposition discussion
- reopen
- re-composition
- review acquisition approval

を含んだ generalized first-case trace になっている。

---

## 5. review acquisition evidence

### 5.1 boundary

- preparation:
  - [iot-arduino-review-acquisition-preparation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-review-acquisition-preparation.md:1)
- gate summary:
  - [review-acquisition-gate-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-gate-summary.md:1)
- summary:
  - [review-acquisition-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/review-acquisition-summary.md:1)
- snapshot:
  - [iot-arduino-implementation-phase-first-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-first-snapshot.md:1)

ここで固定したのは hardware-ready 実装ではなく、
owner boundary が読める `spec-origin` first snapshot に対する review acquisition boundary である。

### 5.2 first batch

- batch summary:
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/comparison_summary.json:1)
- run ids:
  - `single = run-20260512T013547Z-bc86d715`
  - `dual = run-20260512T013547Z-428bb710`
  - `dual+judgment = run-20260512T013548Z-4f530012`
- counts:
  - `2 / 3 / 3`
- validation:
  - all `passed`

この first batch では、

- primary で `restart boundary`
- primary で `relay fail-safe`
- adversarial で `telemetry non-blocking / stub boundary`

が出た。

### 5.3 second batch

- second snapshot:
  - [iot-arduino-implementation-phase-second-snapshot.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-second-snapshot.md:1)
- second batch summary:
  - [comparison_summary.json](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino-r2/comparison_summary.json:1)
- run ids:
  - `single = run-20260512T084649Z-a35f28aa`
  - `dual = run-20260512T084649Z-2da16e2d`
  - `dual+judgment = run-20260512T084649Z-7c843863`
- counts:
  - `2 / 3 / 3`
- validation:
  - all `passed`

この second batch では、first batch 後に

- restart boundary の stub persistence / time-sync seam
- relay fail-safe の single finalization path
- telemetry warning-return boundary

を明示した上で再取得したが、finding count は `2 / 3 / 3` のまま維持された。

---

## 6. implementation snapshot evidence

- source tree:
  - `/Users/Daily/Development/DR-IoT/src`
- protocol:
  - [iot-arduino-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-implementation-phase-protocol.md:1)
- protocol batch root:
  - [F3-iot-arduino batch_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino/batch_manifest.yaml:1)
  - [F3-iot-arduino-r2 batch_manifest.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F3-iot-arduino-r2/batch_manifest.yaml:1)
- implementation comparison summary:
  - [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/implementation-evidence-summary.md:1)
- case decision:
  - [iot-arduino-case-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-decision.md:1)

implementation-phase reading:

1. snapshot は fresh `Spec-origin` skeleton として作成された
2. `.ino` は thin entrypoint に抑えられている
3. loop 外 policy owner と loop 内 execution owner の分離は読める
4. second snapshot では restart boundary, relay finalization, telemetry warning-return の seam を explicit にした
5. ただし WiFi/NTP、EEPROM、OLED/Blynk、ISR-driven sampled loop はまだ stub を含む

したがって、今回の acquisition は

- completed implementation review
  ではなく
- snapshot-boundary review

として読むべきである。

---

## 7. current claim support

この bundle から、今の時点で比較的安全に言えることは次である。

### 7.1 Claim 2 / workflow operation

- event-driven IoT case でも gate-based workflow が回った
- human defer と reopen を trace artifact に残せた
- requirements/design/tasks と review acquisition を同じ case id で縦に接続できた
- `2 / 3 / 3` の first implementation batch を approved upstream bundle に接続できた
- implementation-local refinement 後にも `2 / 3 / 3` が維持され、review signal が silent に消えないことを確認できた

paper-facing reading:

`iot-arduino` は、timing-sensitive な operational case でも workflow trace, caveat, handback depth を保持でき、implementation-local hardening 後も safety-sensitive signal を保持することを示す。

### 7.2 Claim 3 / generalized first case

- external `intent.md` と `仕様.md` を起点に case を始められた
- short start command から first meaningful gate まで自然に進められた
- feature recomposition を含む上流 phase と implementation acquisition を 1 本の case として接続できた

paper-facing reading:

`iot-arduino` は、「intent と仕様のひな形から意図駆動ループを回せるか」の generalized first-case test として読める。

### 7.3 Claim 4 / domain transfer

- scientific code ではない event-driven case でも `2 / 3 / 3` を得た
- third finding は telemetry policy / snapshot stub boundary のような operational caveat として残った
- second acquisition 後も count が落ちず、`restart boundary / relay fail-safe` は stable safety finding、`telemetry caveat` は preserved caveat として残った
- したがって、`dual-reviewer` の artifact chain は simulation 系だけに閉じず、event-driven IoT case でも safety signal と caveat retention を維持しうる

paper-facing reading:

`iot-arduino` は、workflow と evidence contract が event-driven IoT domain にも移せること、そして refinement 後も signal が消えずに残ることを示す補助 case として使える。

---

## 8. current limits

この bundle だけでは、まだ次は言えない。

1. device-ready implementation quality が確立した
2. telemetry / persistence / ISR の具体実装が十分である
3. `2 / 3 / 3` が一般則である
4. paper main evidence にそのまま昇格させてよい

加えて、今回の review target は hardware integration 完了版ではなく skeleton snapshot なので、
finding の意味は `implementation-local defect` 断定より
`boundary and caveat review result`
として読む方が安全である。

second acquisition でも count が変わらなかったことは、

- refinement failure
  ではなく
- safety-sensitive contract と caveat retention が review signal として安定している

可能性として読むのが安全である。

---

## 9. next action

この bundle の次にやるべきことは 2 つである。

1. second batch の `2 / 3 / 3` を `stable safety finding / preserved caveat` として paper-facing prose に反映する
2. hardware-ready cycle に進むなら、real WiFi/NTP, EEPROM/RTC, OLED/Blynk, ISR wiring を含む次段 implementation を別 boundary として切る

補足:

- `iot-arduino` は fixed core case に上げず、snapshot-based supporting case として閉じる
- 現時点の paper-facing value は、hardware adequacy ではなく workflow continuity, signal stability, caveat retention にある
