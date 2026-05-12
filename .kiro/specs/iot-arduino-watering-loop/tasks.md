# Implementation Plan

> `iot-arduino-watering-loop` は、灌水 loop の execution owner である。ここでは、relay、ISR pulse count、flow / irrigation accumulation、threshold / timeout stop、loop outcome を実装順と test sequencing が読める形に落とす。

## 1. Watering loop execution path を実装する

- [ ] 1.1 public contract と file skeleton を実装する
  - `src/watering_loop/watering_loop.h/.cpp`、`relay_driver.h/.cpp`、`pulse_counter.h/.cpp`、`flow_accumulator.h/.cpp`、`stop_condition_judge.h/.cpp` の skeleton を追加する。
  - `LoopInput`, `LoopSample`, `StopConditionState`, `LoopOutcome` を public contract として header に固定する。
  - 観測条件: loop public contract owner が `watering-loop` に固定され、caller が必要 field を再定義しない。
  - _Requirements: 1, 2, 3, 4_
  - _Boundary: src/watering_loop/*_

- [ ] 1.2 relay adapter と pulse counter を実装する
  - `RelayDriver` で relay on/off をラップし、`PulseCounter` で ISR increment、reset、snapshot を実装する。
  - ISR は volatile counter increment だけに留め、runner は snapshot 経由でしか count を読まない。
  - 観測条件: relay control owner と pulse snapshot owner が code 上で 1 か所に閉じる。
  - _Requirements: 1, 2_
  - _Boundary: RelayDriver, PulseCounter_
  - _Depends: 1.1_

- [ ] 1.3 flow / irrigation accumulation step を実装する
  - `FlowAccumulator` で canonical flow formula と cumulative irrigation update を実装する。
  - `elapsed` 正規化を入れ、period 遅延の誤差を抑える。
  - 観測条件: loop 内の flow / irrigation calculation owner が code 上で一意になる。
  - _Requirements: 2, 3_
  - _Boundary: FlowAccumulator_
  - _Depends: 1.1, 1.2_

- [ ] 1.4 stop condition judge を実装する
  - `StopConditionJudge` で `thresholdReached` と `timeoutReached` の評価を実装する。
  - threshold と timeout の両 path を同じ stop evaluator に通す。
  - 観測条件: stop rule owner が 1 か所に固定され、runner 本体へ式を重複させない。
  - _Requirements: 3_
  - _Boundary: StopConditionJudge_
  - _Depends: 1.1, 1.3_

- [ ] 1.5 `WateringLoopRunner` を実装する
  - `runLoop(input)` で relay ON、pulse reset、period loop、sample update、stop evaluation、relay OFF、`LoopOutcome` assembly を実装する。
  - exit path では必ず relay を OFF にし、`relayOffConfirmed` を outcome に入れる。
  - 観測条件: timeout と threshold の両方が `LoopOutcome` へ統一的に流れ、caller が post-run commit に使える。
  - _Requirements: 1, 2, 3, 4_
  - _Boundary: WateringLoopRunner_
  - _Depends: 1.2, 1.3, 1.4_

- [ ] 1.6 watering loop smoke test を整備する
  - `threshold stop`、`timeout stop`、`relayOffConfirmed`、`flow / irrigation formula` の最小 smoke を追加する。
  - pulse input を deterministic に与え、`LoopOutcome` shape と final values を確認する。
  - 観測条件: loop feature 単体で stop path と outcome contract drift を検出できる。
  - _Requirements: 1, 2, 3, 4_
  - _Boundary: watering loop smoke tests_
  - _Depends: 1.3, 1.4, 1.5_
