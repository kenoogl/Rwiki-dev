# phase evidence summary template

> derived artifact only. source of truth remains the referenced review artifacts, alignment memo, and workflow gate status.

## 1. gate package scope

- phase:
- reviewed feature set:
- local review artifact refs:
- phase review wave artifact ref:
- phase alignment memo ref:
- workflow gate status ref:

## 2. evidence rollup

- local review findings by feature:
- phase review wave findings:
- total findings observed in this phase:
- total blocking findings:
- total fixed findings:
- total deferred findings:
- total reopen-triggering findings:

## 3. metric snapshot

- `phase_blocking_issue_count`:
- `phase_nonblocking_open_point_count`:
- `phase_recheck_count`:
- `phase_minor_adjustment_count`:
- `phase_major_correction_count`:
- `phase_intent_attributed_issue_count`:
- `phase_reopen_required_count`:

## 4. carried open points

- open point 1:

## 5. human decision guide

- decide now:
  - `<各判断点を plain language で 1 点ずつ説明する。何を比べて、何に違和感があれば止めるべきかまで書く>`
- current proposal:
  - `<system 側の current proposal を plain language で書く>`
- do not decide yet:
  - `<この gate ではまだ決めない detail を明示する>`
- approve means:
  - `<approve が次 phase で何を許可するかを plain language で書く>`
- reject or defer means:
  - `<reject/defer でどこまで戻るか、何が未確定のまま止まるかを書く>`

## 6. gate readiness statement

- readiness:
- remaining risk:
- requested human decision:
