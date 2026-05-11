# heat3d-julia first snapshot

_作成: 2026-05-11_  
_status: fixed for first-run v0.1_  
_role: `F2-heat3d-julia` の concrete snapshot 固定_

---

## 1. この文書の役割

この文書は、`heat3d` case の implementation/review phase における
最初の `heat3d-julia` run が参照すべき snapshot を固定する。

first-run の目的は統計比較ではなく、

- target boundary の固定
- acquisition protocol の崩れ検出
- `single review` と `dual-reviewer workflow` の artifact 差の確認

であるため、snapshot も「clean-room boundary が明確で、upstream spec との接続を説明できる 1 点」
として固定する。

## 2. Fixed Snapshot ID

- snapshot id: `F2-heat3d-julia-s1`
- batch label: `F2-heat3d-julia`
- target label: `heat3d-julia`
- language: `Julia`
- role in paper:
  - Implementation Track second-run pilot
  - scientific simulation implementation-phase representative

## 3. Snapshot Definition

この snapshot は、次の 2 つを組にして定義する。

1. spec-side anchor
2. code-side anchor

### 3.1 Spec-Side Anchor

- canonical spec path:
  - `/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md`
- intent path:
  - [heat3d-spec/intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- source control note:
  - `DR-heat3d` workspace は local-only seed directory として扱う
  - first-run では git hash ではなく fixed path reference を anchor とする

spec-side anchor にする理由:

- self-contained な original specification を 1 file で保持している
- heat3d case の intent が明示的にこの spec を canonical source として参照する
- implementation-phase review でも upstream semantics をこの file に遡及できる

### 3.2 Code-Side Anchor

- implementation root:
  - `/Users/Daily/Development/DR-heat3d`
- implementation type:
  - clean-room reconstruction workspace
- current reviewable package:
  - `spec_seed/thermal_simulator_spec.md`
- source control note:
  - local-only workspace であり git commit hash は存在しない
  - first-run では reviewable file-set digest で固定する

code-side snapshot canonical digest:

- reviewable file-set digest:
  - `sha256:d5bbe2a8274057be6b0c1c27dc712364e36545f4eeefff5e9d86098e107b3c4a`
- reviewable file count:
  - `1`

digest の対象:

- `spec_seed/thermal_simulator_spec.md`

code-side shape:

- implementation source は first-run 時点では未固定
- clean-room boundary の primary target は `spec_seed/` 配下の canonical spec seed である

## 4. Why This Snapshot

この snapshot を Implementation Track first-run に選ぶ理由は次である。

1. upstream boundary が明確
   original spec seed と intent reference の対応が固定され、実装側がどの仕様に拘束されるかを曖昧にしない。

2. simulation stress が十分にある
   non-uniform Z grid、boundary condition semantics、implicit time integration、PBiCGSTAB、geometry/material assignment を同時に含む。

3. parameter and caveat surface が review-critical
   MVP fixed case、boundary sign convention、z-range rule、solver tolerance の解釈を silent にずらすと downstream behavior が変わるため、default と caveat を finding に残せるかを見たい。

4. clean-room constraint を保持できる
   元の Julia 実装ではなく、spec_seed だけを canonical input に固定した状態で review acquisition を開始できる。

## 5. Evidence Anchors

snapshot boundary の説明責任を支える補助 anchor は次である。

- case intent:
  - [intent.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/heat3d-spec/intent.md:1)
- implementation protocol:
  - [heat3d-implementation-phase-protocol.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-implementation-phase-protocol.md:1)

これらの資料は snapshot provenance の補助に使う。
main evaluation metric としては使わない。

## 6. Review Boundary for First Run

first-run review では、次を対象に含める。

- `spec_seed/thermal_simulator_spec.md` に書かれた discretization / boundary / solver / software structure rules
- `heat3d-spec/intent.md` に書かれた case-level goals / constraints
- clean-room implementation workspace の boundary definition

first-run review では、次を主対象にしない。

- `Heat3ds_rework` 配下の既存 Julia code
- plotting / notebook / output rendering
- CLI / batch execution の将来拡張

## 7. Comparison Modes Bound to This Snapshot

`F2-heat3d-julia-s1` に対して Implementation Track first-run で固定する比較軸:

1. `single review`
2. `dual review`
3. `dual-reviewer workflow`

## 8. Caveats

この snapshot の caveat は次である。

1. current code-side anchor は implementation source tree ではなく seed-only workspace である
2. first-run 再現性は file-set digest と fixed path reference に依存する
3. clean-room 制約のため、既存 Julia implementation を review evidence に含めない
4. 本 run は protocol acquisition 用であり、main-evidence-grade review quality をまだ主張しない

## 9. Immediate Operational Rule

`heat3d-julia` first-run を開始する前に、少なくとも次を行う。

1. `/Users/Daily/Development/DR-heat3d/spec_seed/thermal_simulator_spec.md` を common upstream input に固定する
2. `Heat3ds_rework` 配下の code file を review evidence に入れない
3. `single review`、`dual review`、`dual-reviewer workflow` の共通入力に同一 snapshot ref を使う

これを満たした時点で、`heat3d-julia` の first-run snapshot は fixed とみなす。
