# reference-free-case-bootstrap-guide

_purpose: 新しい case を既存 pilot case のコピーから始めず、intent gate に入るための最小 control artifact を repo 内に作る手順を固定する_
_正本参照: `.kiro/specs/dual-reviewer-implementation-governance` design「Owned Artifacts」「Workflow Model / Stage -1: Reference-Free Case Bootstrap」、requirements Requirement 8（受入 1〜6）、tasks Task 1／Task 3_

---

## 1. この文書の役割

この文書は governance 所有の methodology artifact であり、`scripts/bootstrap_reference_free_case.rb` が固定する Stage -1（reference-free case bootstrap）の人手手順を記述する。case content を完成させることではなく、`intent gate` に入るための最小 control artifact を repo 内に作ることを役割とする。

## 2. 再利用してよいもの／書き起こすもの

- 再利用してよい:
  - template（本ディレクトリの `implementation-phase-protocol-template.md`／`implementation-phase-snapshot-template.md`）
  - gate structure（`operations/HUMAN_WORKFLOW.md` の workflow 段）
- case 固有として supplied source document から書き起こす:
  - case 固有の stress
  - case 固有の scope
  - case 固有の risk

pilot case の copied heuristic は持ち込まない。新規 case の最初の run は repo-contained minimal default（track-level minimal heuristic template）から始める。

## 3. 固定する最小 control artifact

bootstrap stage では次を固定する（design Stage -1）。

- upstream intent source
- canonical source
- umbrella `intent.md`
- umbrella `spec.json`
- case workflow overlay
- active worklist
- workflow path

これらは `scripts/bootstrap_reference_free_case.rb` が `.kiro/methodology/dual-reviewer-spec-driven-paper/` 配下と case ディレクトリへ生成する。

## 4. minimal heuristic default

- case manifest に `heuristic_profile_ref` が無い場合、runtime は track-specific repo-contained minimal template を既定使用してよい。
- case 固有 heuristic は approved source に anchored した review-critical contract が明確なときだけ追加する。
- heuristic default 挙動と minimal template 語彙の canonical owner は v2-acquisition spec とする（Requirement 8 受入 6）。governance はこれを参照するが所有せず、v2-acquisition spec が語彙を確定するまで governance validator はこれら heuristic template 実体を必須検査しない。

## 5. 退出条件

- 人間 `intent gate` に出せる初回 gate input が揃っていること（active feature set と dependency order の提案を含む）。
