# reference-free case bootstrap guide

_作成: 2026-05-12_  
_最終更新: 2026-05-13_  
_status: draft v0.2_  
_purpose: 既存の参照 case に依存せず、新しい case を intent 起点で立ち上げるための最小ガイド_

---

## 1. この文書の役割

この文書は、既存の completed case を参照しなくても、
新しい case を本番運用として立ち上げられるようにするための
**最小 bootstrap guide** である。

使い方の原則は単純である。

1. case 固有文書は template から起こす
2. `heuristic_profile` は minimal template から始める
3. target 固有の stress が明確なときだけ追加ルールを書く

---

## 2. Start Here

新しい case を起こすときは、まず次の template 群を使う。

- workflow overlay:
  - [case-workflow-overlay-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/case-workflow-overlay-template.md:1)
- active worklist:
  - [active-worklist-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/active-worklist-template.md:1)
- phase gate summary:
  - [phase-evidence-summary-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/phase-evidence-summary-template.md:1)
- implementation protocol:
  - [implementation-phase-protocol-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-phase-protocol-template.md:1)
- implementation snapshot:
  - [implementation-phase-snapshot-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-phase-snapshot-template.md:1)
- review acquisition preparation:
  - [review-acquisition-preparation-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/review-acquisition-preparation-template.md:1)
- review acquisition gate summary:
  - [review-acquisition-gate-summary-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/review-acquisition-gate-summary-template.md:1)
- heuristic profile policy：v2 以降のコード修正で再設計する。当面は参照しない。

---

## 3. Minimal Bootstrap Sequence

参照 case なしで始めるときの最小順序は次である。

1. external source を固定する  
   例: `intent.md`、仕様 seed、reverse-engineered source note。
2. umbrella spec の `intent.md` を起こす
3. umbrella `spec.json` を `intent-fixed` 相当の初期状態で起こす
4. case workflow overlay を作る
5. active worklist を作る
6. active feature set を提案し、human `intent gate` に出す
7. `requirements -> design -> tasks` の各 wave を gate まで進める
8. implementation/review acquisition に入る場合は:
   - implementation protocol template を埋める
   - implementation snapshot template を埋める
   - review acquisition preparation / gate summary を作る
   - minimal heuristic profile を必要最小限だけ拡張する

---

## 4. What Not To Copy From Existing Cases

既存 case からそのまま持ってきてはいけないもの:

- case 固有の stress point
- case 固有の failure observation refs
- case 固有の heading pattern
- case 固有の source pattern id
- case 固有の success interpretation

持ってきてよいもの:

- 文書の見出し構造
- gate package の役割
- `implementation snapshot` の固定の仕方
- `heuristic_profile` の最小 shape

要するに、**case 固有の中身ではなく、枠だけを再利用する**。

---

## 5. Minimal Heuristic Policy

`heuristic_profile` の方針は、取得処理を実 LLM 呼び出しに置き換える v2 以降のコード修正で再設計する。本ガイドの作成時点では、件数ガイダンスや具体的な追加方針を提示しない。

新規 case で `heuristic_profile` を必要とする場合は、再設計後の方針に従う。

---

## 6. Exit Condition

bootstrap が完了したとみなす条件は次である。

- case は既存参照 case を見なくても gate を進められる
- implementation protocol と snapshot を template から起こせる
- heuristic profile は minimal template から説明可能に作られている
- case 固有の追加は「なぜ必要か」を 1 文で言える

この条件を満たしたら、その case は reference-free に運用可能とみなす。
