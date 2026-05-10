# Execution Control Ledger

_作成: 2026-05-10_  
_status: draft v0.1_  
_purpose: generic execution layer v2 仕様再設計の入力として、case-specific hardcode を正本化して固定する_

---

## 1. この文書の役割

この文書は、`dual-reviewer` 論文化用 pilot 実装に残っている
`case-specific hardcode` を棚卸しし、
**generic execution layer へ置換すべき箇所**
と
**単なる case binding として許容される箇所**
を分離するための台帳である。

この文書は inventory そのものが目的ではない。
目的は、ここで固定した除去対象と境界条件を入力にして、

- 上位概念の仕様を再設計する
- その仕様駆動で `generic execution layer v2` を定義する
- `requirements/design/tasks` を回して v2 を実装する

という spec-driven development を進めることである。

ここで問題にしているのは、単に文字列が固定されていることではない。
問題は、execution rule 自体が

- 特定 case 名
- 特定 file path
- 特定 finding 文面
- 特定 reopen / handback 判定

に埋め込まれていることである。

したがって、この ledger は
`hardcode inventory`
であると同時に、
`v2 redesign input ledger`
として扱う。

この文書単体では進行制御を担わない。
進行制御は `ACTIVE_WORKLIST` が担い、
この文書はその `Current Next Step` に対する
**redesign input artifact**
として従属する。

---

## 2. 判定基準

### 2.1 許容される固定

次は直ちに違反とはみなさない。

- batch runner が特定 case の `intent/spec/snapshot` を入力として渡すこと
- pilot 用 output root や `run_label` を固定すること
- 比較 summary が pilot scope を説明すること

これらは **execution rule** ではなく **case manifest / batch wiring** だからである。

### 2.2 除去対象

次は generic execution layer 設計で除去対象とする。

- `case_id` や `target_id` を見て review 内容を分岐する
- 特定 case だけで finding を生成する
- 特定 case 専用の issue summary / caveat / handback / metric を埋め込む
- 特定 spec path を前提に reopen target や signal id を決める

### 2.3 この文書の非目標

この文書は次を直接は行わない。

- v2 の layer boundary 定義
- v2 の taxonomy 定義
- v2 の input / output contract 定義
- v2 の `requirements/design/tasks` 起票

それらは後続の v2 仕様正本で扱う。
この文書は、その前提となる除去対象と移送対象を固定する。

---

## 3. Inventory Summary

| id | layer | artifact | current hardcode shape | disposition |
|---|---|---|---|---|
| `ECL-R1` | runtime | `BaseStepExecutor` | `target_id` に `phase-field-cpp` を含むかで case 判定 | remove |
| `ECL-R2` | runtime | `StepAPrimaryDetection` | `phase-field` 向け pattern / summary / failure observation | remove |
| `ECL-R3` | runtime | `StepBAdversarialReview` | `phase-field` 向け pattern / summary / failure observation | remove |
| `ECL-S1` | spec track | `SpecTrackWriter` | `phase-field` 3 case 向け分析 payload をコード埋め込み | remove |
| `ECL-S2` | spec track | `SpecTrackWriter` | `case_id` と `reviewed_phase_ref` で branch 判定 | remove |
| `ECL-I1` | intent track | `IntentTrackWriter` | `dual-reviewer-rebuild` bootstrap case 専用分析 payload | remove |
| `ECL-I2` | intent track | `IntentTrackWriter` | `case_id` と `intent_ref` で branch 判定 | remove |
| `ECL-B1` | batch wiring | `run_phase_field_*` scripts | `phase-field` case の ref/path を shared option に固定 | migrate to case manifest |
| `ECL-B2` | batch wiring | `run_dual_reviewer_rebuild_intent_first_batch.rb` | `dual-reviewer-rebuild` intent case を shared option に固定 | migrate to case manifest |
| `ECL-B3` | protocol defaults | `run_*_track_protocol.rb` | default option が pilot case 前提 | demote to sample/default only |

---

## 4. Detailed Inventory

### `ECL-R1` Runtime target predicate

- artifact:
  [base_step_executor.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/executors/base_step_executor.rb:54)
- current behavior:
  `phase_field_target?` が `target_id.include?("phase-field-cpp")` で真偽を返す
- why this is a hardcode:
  runtime の finding 生成可否が target 名に直接依存している
- blocker:
  新しい implementation case を追加しても、execution rule が増殖しない限り何も起きない
- replacement direction:
  `target_id` 判定ではなく、input artifact から抽出した reviewable evidence profile を使う

### `ECL-R2` Primary detection heuristic

- artifact:
  [step_a_primary_detection.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/executors/step_a_primary_detection.rb:8)
- current behavior:
  `BOUNDARY_PATTERNS` / `UPDATE_ORDER_PATTERNS` と summary 文面が
  `phase-field` の periodic boundary と update ordering に寄っている
- why this is a hardcode:
  gap type ではなく domain content が executor に埋まっている
- blocker:
  finding taxonomy が `boundary` / `update order` の case-specific wording に固定される
- replacement direction:
  executor は
  `constraint mismatch`
  `ordered-state-transition risk`
  のような generic gap type だけを出し、case 固有性は excerpt と evidence に残す

### `ECL-R3` Adversarial review heuristic

- artifact:
  [step_b_adversarial_review.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/executors/step_b_adversarial_review.rb:8)
- current behavior:
  parameter / clean-room caveat を `phase-field` 向け cue と summary で生成する
- why this is a hardcode:
  adversarial pass の論点候補が case content で固定されている
- blocker:
  adversarial role が generic disagreement surface ではなく
  `phase-field` 用の second opinion に縮退している
- replacement direction:
  adversarial executor は
  `parameter interpretation drift`
  `scope-boundary caveat`
  `input-to-implementation mapping ambiguity`
  のような generic contradiction class を扱う

### `ECL-S1` Spec-track analysis payload embedding

- artifact:
  [spec_track_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/track_runs/spec_track_writer.rb:285)
- current behavior:
  tasks / design / requirements それぞれについて、
  issue summary、reopen target、signal id、metric 値、handback class をコード内で直接構築する
- why this is a hardcode:
  review output が source artifact 解析結果ではなく、
  既知 case の期待 finding を writer が生成している
- blocker:
  spec track の pilot artifact が execution layer の一般性を示さず、
  `phase-field` 専用 scripted evidence になる
- replacement direction:
  writer は review result schema の serializing に専念し、
  analysis payload 自体は generic analyzer に分離する

### `ECL-S2` Spec-track branch by case identity

- artifact:
  [spec_track_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/track_runs/spec_track_writer.rb:593)
- current behavior:
  `phase_field_tasks_case?`,
  `phase_field_requirements_case?`,
  `phase_field_design_case?`
  が `case_id` と path 文字列で分岐する
- why this is a hardcode:
  phase 名だけではなく case identity によって analyzer を切り替えている
- blocker:
  case が増えるたびに writer 内 branch が増殖する
- replacement direction:
  `reviewed_phase`, input refs, extracted evidence profile から
  phase-generic analyzer を選ぶ

### `ECL-I1` Intent-track bootstrap analysis embedding

- artifact:
  [intent_track_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/track_runs/intent_track_writer.rb:274)
- current behavior:
  `dual-reviewer-rebuild` bootstrap case 向けに
  phase contract gap, code-review collapse, human gate collapse を固定生成する
- why this is a hardcode:
  intent review の finding が input intent の読解結果ではなく、
  bootstrap case の既知論点を writer が埋めている
- blocker:
  intent track が generic intent review ではなく
  bootstrap memo generator になる
- replacement direction:
  intent analyzer は
  `phase contract gap`
  `scope drift risk`
  `human gate ambiguity`
  などの generic intent taxonomy を source 文書から抽出する

### `ECL-I2` Intent-track branch by case identity

- artifact:
  [intent_track_writer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/track_runs/intent_track_writer.rb:380)
- current behavior:
  `dual_reviewer_rebuild_case?` が `case_id` と `intent_ref` の文字列で bootstrap case を特判する
- why this is a hardcode:
  intent track writer が case registry を内包している
- blocker:
  `intent-origin` case を増やすたびに writer 修正が必要になる
- replacement direction:
  case 判定は writer から除去し、case manifest と generic intent analyzer の入力 contract に移す

### `ECL-B1` Phase-field batch wiring

- artifacts:
  [run_phase_field_spec_first_batch.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_phase_field_spec_first_batch.rb:12)
  [run_phase_field_requirements_first_batch.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_phase_field_requirements_first_batch.rb:12)
  [run_phase_field_design_first_batch.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_phase_field_design_first_batch.rb:12)
  [run_phase_field_implementation_first_batch.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_phase_field_implementation_first_batch.rb:14)
- current behavior:
  `phase-field` の batch root、refs、operator、run label を script ごとに固定している
- assessment:
  これは現時点では execution-layer 汚染そのものではない
  が、case manifest 化されていないため batch 定義が script に分散している
- blocker:
  generic layer へ置換後も case 追加のたびに new script を増やす構造が残る
- replacement direction:
  `claim-case-matrix` と整合する case manifest / track manifest に移す

### `ECL-B2` Bootstrap intent batch wiring

- artifact:
  [run_dual_reviewer_rebuild_intent_first_batch.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_dual_reviewer_rebuild_intent_first_batch.rb:12)
- current behavior:
  `dual-reviewer-rebuild` bootstrap case を batch script で固定する
- assessment:
  これも immediate な execution hardcode ではなく case binding である
- blocker:
  intent case 追加時に batch registration が code edit 前提になる
- replacement direction:
  intent-track case manifest に切り出す

### `ECL-B3` Pilot-biased protocol defaults

- artifacts:
  [run_intent_track_protocol.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_intent_track_protocol.rb:11)
  [run_spec_track_protocol.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_spec_track_protocol.rb:11)
  [run_implementation_track_protocol.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/scripts/run_implementation_track_protocol.rb:10)
- current behavior:
  CLI default option が pilot case 前提になっている
- assessment:
  これは execution heuristic ではないが、
  protocol entrypoint の canonical shape が sample case と混ざっている
- blocker:
  generic runner と sample invocation の境界が曖昧になる
- replacement direction:
  protocol runner 自体は必須 option 寄りにし、
  sample defaults は example script か manifest 側へ移す

---

## 5. Priority

### P0: execution layer 汚染

- `ECL-R1`
- `ECL-R2`
- `ECL-R3`
- `ECL-S1`
- `ECL-S2`
- `ECL-I1`
- `ECL-I2`

これらは generic execution layer の正本化前に必ず除去対象とする。

### P1: case manifest への移送

- `ECL-B1`
- `ECL-B2`
- `ECL-B3`

これらは runtime / analyzer の generic 化と並行して整理する。

---

## 6. Relation To ACTIVE_WORKLIST

この文書は `ACTIVE_WORKLIST` を置き換えない。

- `ACTIVE_WORKLIST`:
  execution-control artifact
- `ECL`:
  generic execution layer v2 再設計入力台帳

運用上は次の関係にある。

1. `ACTIVE_WORKLIST` が次の 1 手を固定する
2. その次の 1 手が `hardcode inventory` である間、この文書が正本になる
3. inventory 完了後は、この文書を入力にして v2 上位仕様へ handoff する

したがって、この文書を作成しただけでは作業完了ではない。
`ACTIVE_WORKLIST` 上で次段へ進み、v2 仕様と後続 spec を起こす必要がある。

---

## 7. Design Constraints For The Next Step

generic execution layer 設計では、少なくとも次を満たす必要がある。

1. case identity は analyzer の branch 条件に使わない
2. finding は case 名ではなく taxonomy で first-class 化する
3. case 固有性は input refs, extracted excerpts, final rendered finding text にのみ残す
4. track ごとの差は `intent/spec/implementation` の input contract 差に閉じる
5. batch wiring は execution rule ではなく case manifest 層へ落とす

---

## 8. Handoff To v2 Spec

この文書から後続の v2 上位仕様へ handoff されるべき論点は次である。

1. `remove` 項目をどの layer から追い出すか
2. `migrate to case manifest` 項目をどの manifest contract に移すか
3. analyzer / writer / decision の責務をどこで切るか
4. finding をどの taxonomy で表現するか
5. v2 実装完了を何で判定するか

この handoff 先は
`generic-execution-layer-v2-spec`
である。

---

## 9. Immediate Consequence

この inventory から次にやるべきことは固定される。

1. `Intent / Spec / Implementation` 共通の finding taxonomy を定義する
2. track ごとの input contract を定義する
3. analyzer と writer を分離する
4. case manifest 層を定義する
5. その後に `phase-field` pilot を generic layer で再取得する
