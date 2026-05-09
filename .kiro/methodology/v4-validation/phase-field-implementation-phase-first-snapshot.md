# phase-field-cpp first snapshot

_作成: 2026-05-09_  
_status: fixed for first-run v0.1_  
_role: `F1-phase-field-cpp` の concrete snapshot 固定_

---

## 1. この文書の役割

この文書は、`phase-field` case の implementation/review phase における
最初の `phase-field-cpp` run が参照すべき snapshot を固定する。

first-run の目的は統計比較ではなく、

- target boundary の固定
- acquisition protocol の崩れ検出
- `single review` と `dual-reviewer workflow` の artifact 差の確認

であるため、snapshot も「最も代表的で、review stress が高く、説明可能な 1 点」
として固定する。

---

## 2. Fixed Snapshot ID

- snapshot id: `F1-phase-field-cpp-s1`
- batch label: `F1-phase-field-cpp`
- target label: `phase-field-cpp`
- language: `C++`
- role in paper:
  - Implementation Track first-run pilot
  - high-cognitive-load scientific implementation-phase representative

---

## 3. Snapshot Definition

この snapshot は、次の 2 つを組にして定義する。

1. spec-side anchor
2. code-side anchor

### 3.1 Spec-Side Anchor

- spec path:
  - [phase-field-reverse-spec](/Users/Daily/Development/Rwiki-dev/.kiro/specs/phase-field-reverse-spec)
- canonical spec anchor commit:
  - `08f25c0`
- commit message:
  - `docs(phase-field-reverse-spec): tasks phase Round 5 失敗モード+観測 fixes (= 16 件 + design.md cascade 2 件) [最終 Round]`

この commit を spec-side anchor にする理由:

- V4 review を 5 rounds 通した tasks 最終修正点である
- review boundary と stress point が最も明確である
- `deb7dfd` は evidence batch を締める commit であり、review target そのものより「周辺 evidence closure」の意味が強い

補助参照:

- evidence closure commit:
  - `deb7dfd`
- commit message:
  - `docs(phase-field-reverse-spec): §3.7.6.1 evidence batch + tasks 22 全完走 final commit`

### 3.2 Code-Side Anchor

- implementation root:
  - `/Users/Daily/Development/DR-pfm`
- implementation type:
  - clean-room C++ reconstruction
- source control note:
  - local-only git は存在するが commit は未作成
  - したがって first-run では git hash ではなく file-set digest で固定する

code-side snapshot canonical digest:

- reviewable source tree digest:
  - `7a35611db41b17b500c241579618ba351bf8ed212207a57fa9dffbd41068c243`
- implementation package digest
  - `485c0d33881a0c6b0170f0d36bdda83db7a6f659f767dd79570b1b97e6c1b8f0`

digest の対象:

- source / header / test files (`include/`, `src/`, `tests/` の `.h/.cpp/.sh/.py`)
- package digest では上記に加えて `Makefile` と `spec_seed/` を含む

code-side shape:

- reviewable source/header/test file count:
  - `48`
- main executable artifacts present:
  - `pfm_sim`
  - `pfm_render`
  - `pfm_bmp`

---

## 4. Why This Snapshot

この snapshot を Implementation Track first-run に選ぶ理由は次である。

1. review boundary が明確
   spec-side では tasks 最終 round を通過し、code-side では clean-room 実装と test 群が揃っている。

2. trivial toy ではない
   numerical update, boundary handling, visualization, I/O, error handling を含む implementation package である。

3. stress point が十分に含まれる
   algorithmic correctness, boundary semantics, parameter interpretation, update ordering, numerical caveat, implementation brittleness が同時に存在する。

4. upstream/downstream の接続を説明できる
   reverse-spec 側 anchor と implementation package 側 anchor の両方を持つ。

---

## 5. Evidence Anchors

snapshot boundary の説明責任を支える補助 anchor は次である。

- characteristic summary:
  - [spec_characteristic.json](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/samples/a3/3_7_6_1_phase_field_cpp/spec_characteristic.json:1)
- implementation dev log:
  - [dev_log.jsonl](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/samples/a3/3_7_6_1_phase_field_cpp/dev_log.jsonl:1)
- implementation rework log:
  - [rework_log.jsonl](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/v4-validation/samples/a3/3_7_6_1_phase_field_cpp/rework_log.jsonl:1)

これらの資料は snapshot provenance の補助に使う。
main evaluation metric としては使わない。

---

## 6. Review Boundary for First Run

first-run review では、次を対象に含める。

- `DR-pfm/include/`
- `DR-pfm/src/`
- numerical / I/O / visualization / main-loop / error-handling の実装

first-run review では、次を主対象にしない。

- compiled binaries
- `.o`, `.a`, `.dSYM`
- `output/` の生成物

運用上は、run 実施前にこの snapshot を immutable copy として export する。

推奨 export 単位:

- `include/`
- `src/`
- `tests/`
- `Makefile`
- `spec_seed/`

---

## 7. Comparison Modes Bound to This Snapshot

`F1-phase-field-cpp-s1` に対して Implementation Track first-run で固定する比較軸:

1. `single review`
2. `dual-reviewer workflow`

`manual reference` は optional とする。

---

## 8. Caveats

この snapshot の caveat は次である。

1. code-side root は local-only で、git commit hash がない
2. first-run 再現性は file-set digest に依存する
3. reverse-engineered spec を経由しているため、original code review そのものではなく clean-room reconstruction review である
4. 過去バージョンの reviewer で得た観測値は、この snapshot の main evaluation evidence に含めない

この caveat は paper では limitation として保持する。

---

## 9. Immediate Operational Rule

`phase-field-cpp` first-run を開始する前に、少なくとも次を行う。

1. `/Users/Daily/Development/DR-pfm` から reviewable package を export する
2. export 後の file-set digest が本書の digest と一致することを確認する
3. その package を `single review` と `dual-reviewer workflow` の共通入力に使う

これを満たした時点で、`phase-field-cpp` の first-run snapshot は fixed とみなす。
