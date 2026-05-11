# phase-review-metric register

## 1. 目的

この文書は、`intent / requirements / design / tasks / implementation` の各 phase で
どの問題が観測されたか、どの程度の手戻りが起きたかを同じ形式で集計するための
metric 定義台帳である。

`implementation-conformance-metric-register.md` が post-implementation review を測るのに対し、
本書は phase progression 全体の friction と reopen を測る。

## 2. 集計原則

- phase ごとに `finding`, `recheck`, `handback`, `open point` を分けて数える
- `blocking` と `non-blocking` を分離する
- 同一 issue を複数 phase に重複計上しない
- report 用の baseline 値は、必ず artifact に残っている evidence から引く
- `intent` phase 自体の指標と、下流 phase で観測された `intent-attributed` 問題を分ける
- `intent` は専用 review artifact がない場合のみ `未計測` を許容する
- `phase evidence summary` は derived artifact として使ってよいが、source of truth の代替にはしない

## 3. metric 定義

| metric | phase | 定義 | primary source |
|-------|-------|------|----------------|
| `intent_revision_count` | `intent` | `INTENT.md` または intent 正本群の意味変更を伴う改訂回数 | intent review artifact / traceability note |
| `intent_handback_count` | `intent` | `D` handback の件数 | coordination log / review artifact |
| `phase_blocking_issue_count` | `requirements/design/tasks` | 次段 gate 通過前に修正が必要だった blocking issue の件数 | phase alignment memo / review artifact |
| `phase_nonblocking_open_point_count` | `requirements/design/tasks` | 次段へ持ち越した detail-level open point の件数 | phase alignment memo |
| `phase_recheck_count` | `intent/requirements/design/tasks/implementation` | 上流変更や review 反映で同一 phase gate を再実施した回数 | alignment memo / workflow gate status / review artifact |
| `phase_handback_count_by_class` | `all` | `A/B/C/D` handback の件数 | coordination log / review artifact |
| `phase_reopen_required_count` | `all` | downstream reopen が必要になった件数 | `spec.json`, coordination log, workflow gate status |
| `phase_minor_adjustment_count` | `requirements/design/tasks/implementation` | gate を戻さず phase 内で吸収した軽微修正の件数 | alignment memo / coordination log |
| `phase_major_correction_count` | `requirements/design/tasks/implementation` | blocking issue 修正、または reopen を伴う major correction の件数 | alignment memo / review artifact |
| `phase_intent_attributed_issue_count` | `requirements/design/tasks/implementation` | 当該 phase で観測された issue のうち、原因が intent の再解釈や intent 不整合にあると判定された件数 | phase review artifact / alignment memo |
| `phase_signal_count` | `implementation` | signal register に起票した signal 件数 | signal register |
| `phase_signal_status_distribution` | `implementation` | `open/watch/absorbed/escalated` の分布 | signal register |
| `phase_signal_risk_distribution` | `implementation` | `low/medium/high` の分布 | signal register |
| `phase_conformance_finding_count` | `implementation` | conformance review で出た finding 件数 | review artifact |
| `phase_conformance_severity_weighted_score` | `implementation` | conformance finding に severity weight を掛けた合計 | review artifact |

## 4. phase ごとの期待出力

### 4.1 `intent`

- intent review artifact
- traceability impact note
- `intent_revision_count`
- `intent_handback_count`

### 4.2 `requirements`

- cross-spec requirements alignment memo
- recheck artifact
- requirements evidence summary
- blocking issue count
- intent-attributed issue count
- downstream design reopen の有無

### 4.3 `design`

- cross-spec design alignment memo
- design evidence summary
- blocking issue count
- open alignment point count
- intent-attributed issue count
- downstream tasks reopen の有無

### 4.4 `tasks`

- cross-spec tasks alignment memo
- tasks evidence summary
- ordering conflict count
- shared artifact timing correction count
- intent-attributed issue count

### 4.5 `implementation`

- implementation coordination log
- implementation signal register
- implementation conformance review artifact
- short rerun artifact
- intent-attributed issue count

## 5. v1 baseline extraction rule

v1 completion report では次の簡略ルールで集計した。

- `intent`
  - `docs/reviews/2026-05-09-intent-baseline-review.md` を baseline とし、以後は intent review artifact を正本とする
- `requirements`
  - `cross-spec-requirements-alignment.md` の「今回修正した点」を blocking issue とみなす
  - `Recheck` 節の存在を `phase_recheck_count=1` とみなす
  - intent 起因と明示された issue は v1 では `0` ではなく `未計測` とする
- `design`
  - `cross-spec-design-alignment.md` の「今回修正した点」を blocking issue とみなす
  - `残る open alignment points` の列挙数を non-blocking open point とみなす
  - intent 起因と明示された issue は v1 では `未計測` とする
- `tasks`
  - `cross-spec-tasks-alignment.md` の「今回修正した点」を minor adjustment とみなす
  - `blocking 級の task ordering conflict は見つからなかった` を `0` とみなす
  - intent 起因と明示された issue は v1 では `未計測` とする
- `implementation`
  - coordination log の entry 数と `handback class` 分布を集計する
  - signal register の status / risk を集計する
  - conformance review artifact の metric snapshot を正本とする
  - intent 起因と明示された finding は v1 では `未計測` とする

## 6. 今後の補強

- intent 変更ごとに review artifact を更新し、`intent_revision_count` と `intent_handback_count` を継続記録する
- `requirements / design / tasks` について、alignment memo と review artifact から phase evidence summary へ機械抽出できる最小 field を固定する
- issue の原因分類として `intent-attributed` を各 phase artifact に埋め込めるようにする
- `workflow-gate-status.md` と phase metrics を接続し、`completed_with_open_findings` を phase 別に追跡できるようにする
