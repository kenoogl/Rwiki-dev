# Legacy Discussion Carryover

_作成日: 2026-05-08_  
_参照元: [docs/レビューシステム検討.md](/Users/Daily/Development/Rwiki-dev/docs/レビューシステム検討.md)_

## 1. 目的

この文書は、旧 repo にある初期検討 [レビューシステム検討.md](/Users/Daily/Development/Rwiki-dev/docs/レビューシステム検討.md) から、再構築に再利用価値のある論点だけを切り出して残すための memo である。

これは正本ではない。正本は `intent/`, `operations/`, `.kiro/specs/` にある。ここでは、

- 再利用すべき発想
- 将来拡張に回すべき発想
- 今回は採用しない前提

を分離する。

## 2. 継承価値の高い論点

この節のうち、次の 4 項目は現行案に即採用する。

- 3 層分離
- project 固有知識の evidence からの抽出
- 具体パターンとメタパターンの分離
- human-in-the-loop の維持

### 2.1 一般層 / メタ層 / project 固有層の 3 層分離

旧議論で最も有用なのは、review system を次の 3 層に分けて考える整理である。

- Layer 1
  - 完全に一般化可能な review 構造
- Layer 2
  - project 横断で再利用可能なメタパターン
- Layer 3
  - project 固有の事例、用語、履歴

これは再構築後の構成に次のように対応づけられる。

- Layer 1
  - `dual-reviewer-foundation`
- Layer 2
  - `runtime/patterns/` と将来の pattern schema
- Layer 3
  - `learning/findings/` と project 固有 evidence

この整理は今後も維持すべきである。

### 2.2 project 固有知識はログから抽出して schema 化する

旧議論では、project 固有部分は review log から抽出し、構造化して蓄積するという方向が明示されていた。

これは今回の再構築方針と強く整合する。具体的には、

- runtime が raw evidence を `experiments/runs/` に保存する
- evaluation が `experiments/analysis/` に派生分析を出す
- self-improvement が recurring signal を抽出する
- そこから project 固有 pattern を構造化する

という流れに落とせる。

したがって、「repo 外 memory に知識を貯める」のではなく、「repo 内 evidence から抽出して artifact 化する」という発想は継承対象である。

### 2.3 23 パターンのメタ群化

旧議論では、Rwiki 由来の 23 パターンを複数のメタ群へ抽象化する発想が出ていた。

これ自体の群分類をそのまま正本化する必要はないが、次の原則は有用である。

- 具体パターンは project 固有
- メタパターンは project 横断で再利用可能
- 抽象化の粒度は粗すぎず細かすぎない中程度がよい

この原則は、今後 `seed_patterns.yaml` や pattern schema を作るときの判断基準になる。

### 2.4 human-in-the-loop を残すという結論

旧議論は、LLM の easy wins 偏向や adversarial な検出限界を踏まえ、人間 gate を残すべきという結論を置いていた。

これは現在の

- [TRUST_BOUNDARY.md](../../operations/TRUST_BOUNDARY.md)
- [HUMAN_WORKFLOW.md](../../operations/HUMAN_WORKFLOW.md)

と整合しているため、方針確認として継承価値がある。

## 3. 将来拡張として有用な論点

### 3.1 10 ラウンド並列化 + 整合性ラウンド

旧議論には、round を並列実行し、最後に整合性ラウンドを走らせることで wall-clock を短縮する案がある。

これは有望だが、初期再構築の必須要件ではない。理由は、

- まず正しい raw evidence と metadata contract が必要
- round 間 dependency 検出は runtime が安定してからの最適化
- いまは速度より reproducibility と observability を優先する

ためである。

位置づけ:

- Phase 1
  - 不採用
- Phase 2 以降
  - performance / throughput 改善案として再検討

### 3.2 portable starter kit 的な構想

旧議論では Layer 1/2 を切り出して starter kit にする構想がある。

これも長期的には有用だが、現時点ではまだ早い。まずは `dual-reviewer-rebuild` 自体を安定化させることが先である。

## 4. 今回は採用しない前提

### 4.1 repo 外 memory 中心の実装

旧議論には `memory` ファイル群を中心とした運用前提が強く残っている。

しかし再構築では、

- prompt
- policy
- schema
- pattern
- validator contract

を repo 内正本として持つため、この前提は採用しない。

### 4.2 Rwiki 固有の round 内容や spec 番号への依存

旧議論の具体例は Rwiki 固有であり、そのまま generic runtime の contract にするべきではない。

これらは次の用途に限定する。

- migration 参考
- pattern 抽象化の素材
- failure archive

### 4.3 design 中心の固定的な有効性指標

旧議論は design review 中心で進んだ経緯があり、その前提で「効果」を語っている部分がある。

再構築では、

- `intent`
- `requirements`
- `design`
- `tasks`
- 将来の implementation-oriented review

で主指標が変わりうるため、design 固定の評価観をそのまま継承しない。

## 5. 現行 repo への反映先

旧議論から継承した発想は、現時点では次に反映されている。

- 3 層分離
  - [dual-reviewer-foundation/design.md](../../.kiro/specs/dual-reviewer-foundation/design.md)
  - [dual-reviewer-self-improvement/design.md](../../.kiro/specs/dual-reviewer-self-improvement/design.md)
- evidence からの継続改善
  - [SELF_IMPROVEMENT_LOOP.md](../../SELF_IMPROVEMENT_LOOP.md)
  - [dual-reviewer-self-improvement/requirements.md](../../.kiro/specs/dual-reviewer-self-improvement/requirements.md)
- human-in-the-loop
  - [TRUST_BOUNDARY.md](../../operations/TRUST_BOUNDARY.md)
  - [HUMAN_WORKFLOW.md](../../operations/HUMAN_WORKFLOW.md)
- phase ごとに異なる有効性指標
  - [INTENT.md](../../intent/INTENT.md)
  - [dual-reviewer-evaluation/design.md](../../.kiro/specs/dual-reviewer-evaluation/design.md)

## 6. 今後の使い方

この文書は次のタイミングで参照する。

- pattern schema を設計するとき
- self-improvement の tasks を具体化するとき
- Phase 2 の高速化や並列化を検討するとき
- legacy 議論を正本へ誤って持ち込まないよう確認するとき

## 7. 結論

旧 [レビューシステム検討.md](/Users/Daily/Development/Rwiki-dev/docs/レビューシステム検討.md) は、そのまま新 repo の正本にはならないが、

- 一般層 / メタ層 / project 固有層の分離
- ログから知識を抽出して schema 化する発想
- human gate を残す判断
- 将来の並列化構想

の 4 点は再構築に有用である。
