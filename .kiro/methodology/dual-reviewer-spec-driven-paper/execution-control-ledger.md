# Execution Control Ledger

_作成: 2026-05-10_  
_status: draft v0.1_  
_purpose: generic execution layer v2 仕様再設計の入力として、case-specific hardcode を正本化して固定する_

_scope note: 起点は `phase-field` pilot で露出した hardcode inventory だが、現在の役割は case 一般化後の execution/control constraint ledger である。current workflow control board ではない。_

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

補足:

- `heat3d` gate-only trial では、この文書は workflow current step の正本にはならない
- 同 trial では gate 運用確認が主目的であり、`ECL` は一般化済み execution/control rule の制約台帳として参照する
- trial の前進条件や承認条件は `ACTIVE_WORKLIST` と trial protocol 側で保持する

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

### 2.4 現在フェーズでの使い方

この文書の成立起点は `phase-field` pilot だが、
現在フェーズで確認したいのは
**一般化された execution/control scheme が別 case でも運用できるか**
である。

したがって、この文書は今は次の意味で使う。

- `phase-field` で抽出した constraint の記録
- 他 case へ持ち越してよい一般則の明示
- 新 case で workflow を回す際に逸脱検知へ使う constraint source

逆に、今のフェーズでは次の意味では使わない。

- `phase-field` 専用問題の棚卸しを続けるための current task board
- current workflow step を決める control board

---

## 3. Inventory Summary

| id | layer | artifact | current hardcode shape | disposition |
|---|---|---|---|---|
| `ECL-R1` | runtime | `RuleMatchAnalyzer` | `phase-field-implementation-phase-first-snapshot.md` basename を特判して section class を決める | remove |
| `ECL-R2` | runtime | `runtime/patterns/seed_patterns.yaml` | `phase-field-cpp first snapshot` を parent heading に持つ fragment cue 群 | remove |
| `ECL-R3` | runtime | `runtime/patterns/seed_patterns.yaml` | `Requirement 1/2/6` など `phase-field` acceptance structure 前提の upstream cue 群 | remove |
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
  [rule_match_analyzer.rb](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/execution_v2/analyzers/rule_match_analyzer.rb:518)
- current behavior:
  `classify_section` が basename `phase-field-implementation-phase-first-snapshot.md` を特判し、
  `implementation_snapshot_note` を返す
- why this is a hardcode:
  section class の決定が generic rule ではなく特定 snapshot filename に依存している
- blocker:
  新しい snapshot を追加するたびに analyzer 側へ filename 例外を足す誘惑が残る
- replacement direction:
  basename 特判ではなく、heading / source kind / manifest-provided schema から section class を決める

### `ECL-R2` Snapshot fragment cue hardcode

- artifact:
  [seed_patterns.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/patterns/seed_patterns.yaml:1)
- current behavior:
  `clean-room-caveat-note`、`digest-fixity-caveat-note`、
  `operational-digest-check-note`、`evidence-exclusion-note` などの cue が
  parent heading `^phase-field-cpp first snapshot$` を前提にしている
- why this is a hardcode:
  fragment class 判定が特定 snapshot 文書の heading 構造に依存している
- blocker:
  `heat3d` のように別 snapshot title / heading を持つ case で cue 再利用性が落ちる
- replacement direction:
  heading title 固定ではなく、manifest または profile から supplied される structural role で cue を解決する

### `ECL-R3` Upstream contract cue hardcode

- artifact:
  [seed_patterns.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/runtime/patterns/seed_patterns.yaml:1)
- current behavior:
  `parameter_contract`、`boundary_contract`、`update_order_contract` の cue が
  `Requirement 1:`、`Requirement 2:`、`Requirement 6:` など
  `phase-field` acceptance structure を前提にしている
- why this is a hardcode:
  upstream contract 判定が generic acceptance model ではなく特定 case の requirement numbering に依存している
- blocker:
  upstream spec の節構成が異なる case では rule をそのまま適用できない
- replacement direction:
  contract cue は fixed requirement numbers ではなく、
  profile-provided structural requirements または normalized spec schema で判定する

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

意味:

- generic execution/control scheme の一般性を直接壊す項目である
- 残したままでは case を替えた瞬間に analyzer / writer の挙動が変質しうる
- main evidence 以前に、cross-case operational validity を壊す

現在フェーズでの扱い:

- `heat3d` trial 中は「即時全面改修」よりも「逸脱検知の最優先監視対象」として扱う
- これらに触れる修正や、これらを増やす方向の判断が必要になった場合は stop reason として記録する
- trial 後に generic layer 正本化へ戻る際、最優先で除去・置換する

exit criterion:

- case identity や特定 case の文書構造に依存しなくても同等の runtime / review output contract を維持できること

### P1: case manifest への移送

- `ECL-B1`
- `ECL-B2`
- `ECL-B3`

意味:

- execution rule そのものではなく、sample invocation や case wiring の残骸である
- generic 化の blocker ではあるが、P0 ほど直接的に review logic を汚染しない

現在フェーズでの扱い:

- `heat3d` trial では immediate blocker ではない
- ただし新 case 追加のたびに script 増殖が起きるなら、manifest への移送を前倒しする

exit criterion:

- protocol runner が sample default なしでも成立し、
- case binding が script 本体ではなく manifest / batch definition で完結すること

### Operational Reading Rule

この priority は「今この瞬間の実装順」をそのまま命じるものではない。

- `ACTIVE_WORKLIST` が current step を決める
- `ECL` の priority は、その step の中で何を最も危険な逸脱として監視するかを決める

したがって `heat3d` gate-only trial では、

1. current action は workflow gate の運用確認
2. その最中に最優先で監視するのは `P0`
3. trial を通した後に構造整理へ戻すときの次順位が `P1`

という読み方を取る。

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

補足:

- `heat3d` gate-only trial では、`ACTIVE_WORKLIST` が current control を持つ
- この文書は `phase-field` を起点に抽出した constraint を、他 case に対しても適用可能か検証するための履歴・制約台帳である
- したがって、この文書に `phase-field` が残るのは origin 記録として自然だが、current scope は `phase-field` 固有 inventory に閉じない

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

現在フェーズでは、これに加えて次も含意する。

6. 一般化された execution/control scheme を `heat3d` のような次ケースで運用し、gate と control artifact が実際に回るかを確認する

---

## 10. Relation To heat3d Gate-Only Trial

`heat3d` trial では、次を明示する。

1. trial の主目的は `ECL` 除去作業そのものではなく、一般化済み execution/control scheme の運用確認である
2. `ECL` は「generic layer へ進む際に何を除去対象と見るか」だけでなく、「一般化済み rule から逸脱していないか」を見る参照台帳として使う
3. trial 中に case-specific rule を増やしたくなった場合は、workflow 上の stop reason として扱い、この ledger の constraint に反する兆候として記録する

つまり `ECL` は trial の steering artifact ではなく、
**trial 中に逸脱を検知するための constraint artifact**
として使う。
