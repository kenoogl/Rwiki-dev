# phase-field pruning trace reconstruction note

## 1. 目的

この文書は、`phase-field-cpp` implementation pilot における
rule pruning 過程の raw rerun artifact の一部を誤って削除した後、

- 何が失われた可能性があるか
- 何がまだ再構成できるか
- 今後どのように保存方針を変えるか

を固定するための incident note である。

## 2. 何が起きたか

- `runtime-runs/` と `exports/` の未追跡 rerun artifact を整理する過程で、
  pruning trace として価値を持ちうる raw artifact を物理削除した
- 追跡済み artifact は `git checkout -- ...` により復元した
- しかし、未追跡だった raw rerun / bundle は Git から復元できない

## 3. 失われた可能性があるもの

失われた可能性があるのは、主に次の raw trace である。

1. pruning の途中段階ごとの `runtime-runs/`
2. pruning の途中段階ごとの `exports/`
3. role 削除前後の raw step payload 差分
4. rollback 前の一時 run に付随する bundle

これらは、後から

- どの pruning 段階で結果が維持されたか
- どの段階で結果が崩れたか
- どの evidence role が本当に不要だったか

を raw artifact ベースで再確認する材料になりえた。

## 4. まだ再構成できるもの

完全復元ではないが、次は再構成できる。

### 4.1 文書と summary から再構成できるもの

- pruning の順序
- 各 pruning step の意図
- 維持 / 崩壊の判定結果
- representative 3-treatment の最終結果

根拠:

- [implementation-coordination-log.md](implementation-coordination-log.md:1)
- [generic-execution-layer-v2-replacement-outcome.md](generic-execution-layer-v2-replacement-outcome.md:1)
- [comparison_summary.json](../../experiments/protocols/implementation-track-runs/F1-phase-field-cpp/comparison_summary.json:1)
- [phase-field-dual-treatment-observation.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/phase-field-dual-treatment-observation.md:1)

### 4.2 現在も残っている representative artifact

- `comparison_summary.json`
- `batch_manifest.yaml`
- `protocol-runs/F1-phase-field-cpp-single/`
- `protocol-runs/F1-phase-field-cpp-dual-only/`
- `protocol-runs/F1-phase-field-cpp-dual/`

これらにより、最終採用版の 3 treatment 比較は保持されている。

### 4.3 再実行で取り直せる可能性があるもの

- pruning step を coordination log に沿って再適用した rerun
- representative 3-treatment の raw runtime artifact

ただし、これは

- 当時の未追跡 raw artifact そのもの

ではなく、

- 同じルール状態を再現するための新規再取得

である。

## 5. まだ再構成できないもの

現時点で、そのままでは再構成できないものは次である。

1. 削除時点の未追跡 raw artifact そのもの
2. 途中段階の bundle checksum を含む完全な時系列 raw set
3. 当時のファイルタイムスタンプや生成順を含む物理痕跡

## 6. 運用変更

今後は次をルールとする。

1. pruning / ablation / rollback の raw run は、未追跡でも evidence 候補として扱う
2. 削除前に `must keep / hold for decision / safe to discard` を一覧化する
3. 物理削除は、対象一覧を出した上で承認後にのみ行う

## 7. 現時点の結論

- 今回の削除は重大な運用ミスである
- ただし representative 3-treatment 結果と、pruning の論理順序そのものは文書と tracked artifact から再構成できる
- 今後の論文化では、失われた raw trace があることを念頭に置き、
  summary・coordination log・representative artifact を中心に evidence を組み立てる
