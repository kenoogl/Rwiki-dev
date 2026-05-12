# design evidence summary

> derived artifact only. source of truth remains the referenced local review artifacts, design review wave artifact, alignment memo, and workflow gate status.

## 1. gate package scope

- phase: `design`
- reviewed feature set:
  - [iot-arduino-loop-outside-control/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/design.md:1)
  - [iot-arduino-watering-loop/design.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/design.md:1)
- local review artifact refs:
  - [loop-outside-control local review](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-loop-outside-control/reviews/design-local-review-2026-05-12.md:1)
  - [watering-loop local review](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-watering-loop/reviews/design-local-review-2026-05-12.md:1)
- phase review wave artifact ref:
  - [design review wave](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/design-review-wave-2026-05-12.md:1)
- phase alignment memo ref:
  - [design alignment gate](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/design-alignment-2026-05-12.md:1)
- workflow gate status ref:
  - [iot-arduino workflow path](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-workflow-path.md:1)
  - [iot-arduino umbrella spec.json](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/spec.json:1)

## 2. evidence rollup

- local review findings by feature:
  - `iot-arduino-loop-outside-control`: `2` blocking findings, all fixed
  - `iot-arduino-watering-loop`: `2` blocking findings, all fixed
- phase review wave findings:
  - `2` blocking findings, all fixed
- total findings observed in this phase:
  - `6`
- total blocking findings:
  - `6`
- total fixed findings:
  - `6`
- total deferred findings:
  - `0`
- total reopen-triggering findings:
  - `0`

## 3. metric snapshot

- `phase_blocking_issue_count`: `6`
- `phase_nonblocking_open_point_count`: `3`
- `phase_recheck_count`: `0`
- `phase_minor_adjustment_count`: `0`
- `phase_major_correction_count`: `4`
- `phase_intent_attributed_issue_count`: `0`
- `phase_reopen_required_count`: `0`

## 4. carried open points

- EEPROM byte layout と RTC memory field placement は tasks phase で固定する
- ISR atomic snapshot と `millis()` wraparound-safe helper は tasks phase で固定する
- OLED page layout と Blynk send cadence は tasks phase で固定する

## 5. human decision guide

- decide now:
  - `2 feature split` が設計の粒度として自然かを見てください。
    ここでの問いは、「loop 外の policy と loop 内の execution を分けるだけで、設計を十分に議論できるか」です。
    もし `loop-outside-control` が広すぎて設計できない、または逆に `watering-loop` 側へ寄せるべき責務があるなら、この gate で止めます。
  - `loop entry -> loop outcome -> final status` の流れが自然かを見てください。
    ここでの問いは、「loop に入る前の判断、loop の実行結果、最終状態のまとめ方が別解釈なしでつながっているか」です。
    もし handoff が飛んで見える、または情報不足で tasks に落とせないなら、この gate で止めます。
  - `irrigation_controller.ino` を薄い入口にしてよいかを見てください。
    ここでの問いは、「top-level entry は起動と sleep entry だけを持ち、policy は `LoopOutsideController` に集約する方が自然か」です。
    もし `.ino` にもっと運用判断を書くべきなら、この gate で止めます。
  - file / module placement が tasks へ渡せるかを見てください。
    ここでの問いは、「次の tasks wave で、そのまま実装順と担当単位に落とせる配置になっているか」です。
    もしファイル分けが粗すぎる、または細かすぎるなら、この gate で止めます。
- current proposal:
  - loop 外制御は 1 feature のまま保ち、その内部を `ConfigStore / StateStore / TimeSyncGateway / EligibilityGate / StatusReporter / PostRunCommitter / SleepPlanner / LoopOutsideController` に分けます。
  - watering-loop は 1 feature のまま保ち、その内部を `RelayDriver / PulseCounter / FlowAccumulator / StopConditionJudge / WateringLoopRunner` に分けます。
  - post-run commit、telemetry warning、sleep planning は loop 外制御の owner に保ちます。
- do not decide yet:
  - EEPROM byte offset の具体値はまだ決めません。
  - exact OLED 文言はまだ決めません。
  - Blynk の送信実装 detail はまだ決めません。
  - interrupt guard の exact code pattern はまだ決めません。
- approve means:
  - この architecture、file placement、interface 契約で tasks wave に進んでよい、という意味です。
  - まだ決めていない detail は tasks で詰めます。
- reject or defer means:
  - architecture か handoff contract にまだ修正が必要であり、tasks には進まない、という意味です。
  - 必要なら design wave を reopen して、分割や interface を直します。

## 6. gate readiness statement

- readiness:
  - active feature 2 本の design draft は生成済みである
  - active feature 2 本の local design review は完了している
  - design review wave は完了し、wave-level blocking issue は修正済みである
  - design alignment gate は完了し、blocking 級の owner conflict は残っていない
- remaining risk:
  - open point は tasks-level detail 3 件に限られ、design gate を止める blocking issue ではない
- requested human decision:
  - `approve | reject | defer`
