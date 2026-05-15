# Cross-Spec Requirements Alignment

_作成日: 2026-05-08_
_対象: `dual-reviewer-foundation` / `runtime` / `evaluation` / `paper-interface` / `self-improvement` requirements_

## 1. 目的

5 feature の requirements wave を横断し、shared contract の齟齬を早期に潰す。

加えて、`INTENT.md` にある主要命題が各 feature requirement に落ちているかを確認し、必要なら trace matrix 更新を発火させる。

## 1.5 Trace Matrix 連動

requirements alignment の結果、次のいずれかが起きた場合は [intent-to-requirements-trace-matrix.md](../traceability/intent-to-requirements-trace-matrix.md) を更新対象とする。

- requirement の追加、削除、統合、分割
- requirement の責務移管
- wording 修正だが意味変更を含む場合
- 既存 requirement が新しい intent 命題を受けるようになった場合
- intent に対応しない requirement または requirement に対応しない intent が見つかった場合

## 2. 確認した主要論点

- foundation metadata contract と runtime / evaluation / invalidation policy の整合
- finding 単位の human decision linkage の有無
- valid / invalid / exploratory の責務境界
- runtime と paper-interface の依存方向
- self-improvement の入力が runtime / evaluation の出力で満たせるか

## 3. 整合している点

### 3.1 state machine

- foundation が Step A/B/C/D を canonical contract として定義
- runtime がそれを実行系として受ける
- evaluation と self-improvement はその evidence を消費する

### 3.2 invalidation

- `operations/DATA_INVALIDATION_POLICY.md` が valid / invalid を上位定義
- foundation が required metadata と invalidation marker の contract を持つ
- runtime が run close validation を呼び出す
- evaluation が invalid run を default 除外する
- self-improvement は invalid run を workflow failure evidence として別用途利用する

### 3.3 paper separation

- paper-interface は runtime rule を持たない
- evaluation output を入力に取る consumer として定義されている
- self-improvement も paper narrative と proposal rationale を混同しない

## 4. 今回修正した点

### 4.1 finding と human decision の接続

問題:

- runtime は decision unit ごとの human outcome を記録する要求を持つ
- しかし foundation の finding contract には human decision linkage が明記されていなかった

修正:

- foundation Requirement 3 AC5 に `human decision linkage` を追加

### 4.2 run metadata の不足

問題:

- invalidation policy と human workflow では validator status と human sign-off status が必要
- foundation Requirement 6 AC2 ではそこが明示不足だった

修正:

- foundation Requirement 6 AC2 に `validator status` と `human sign-off status` を追加

### 4.3 runtime と paper-interface の依存方向

問題:

- runtime requirements の adjacent expectations に paper-interface が直接 minimal export field を要求するような読め方があった
- これは runtime -> paper の従属方向を曖昧にする

修正:

- runtime adjacent expectations を、paper-interface へは原則 evaluation 経由で artifact を渡す形に修正

### 4.4 manual dogfooding evidence の位置づけ不足

問題:

- `INTENT.md` に manual dogfooding を本 repo 自身へ適用する方針を入れた
- しかし requirements wave では、manual review evidence と runtime-mediated evidence の区別が十分に明示されていなかった

修正:

- foundation Requirement 6 に `review mode` と canonical vocabulary を追加
- runtime Requirement 4 / Requirement 6 に runtime-mediated evidence の review-mode provenance を追加
- evaluation に `Requirement 9: Review-Mode Distinction` を追加
- self-improvement に `Requirement 7: Manual-vs-Runtime Evidence Provenance` を追加
- paper-interface に `Requirement 6: Review-Mode Provenance in Reporting` を追加
- standard comparison population の owner を evaluation とし、運用上の扱いを `DATA_INVALIDATION_POLICY.md` に追記

## 5. 残る open alignment points

### 5.1 exploratory category の formal placement

解消:

- foundation design で `run_status` と別に `evidence_class` を導入
- `exploratory` は lifecycle ではなく downstream consumption 区分として扱う
- これにより `run_status=closed` かつ `validator_status=passed` でも `evidence_class=exploratory` を表現できる

### 5.2 minimum metric set の定義

現状:

- evaluation が minimum metric set を要求
- foundation / runtime 側ではその metric 計算に必要な field 群の最終確定がまだない

設計で決める必要があること:

- 必須 field と派生 field の境界
- run-level / finding-level / treatment-level の field 所在

### 5.3 replay granularity

解消:

- foundation design で replay 最小単位を `step-level within run` に決定
- `review_case` から `step_id`、`step_name`、`step_status`、`step_prompt_artifact_id` を参照可能にする
- run 全体 replay は step 群の集合として扱う

### 5.4 manual-to-runtime handoff boundary

解消:

- `INTENT.md` に manual dogfooding の最低有効条件を追加
- manual review record contract を前提に、ordinary editing と manual review evidence を分離
- downstream specs では review-mode provenance を保持する方針にした

## 6. design フェーズへ渡すべき共通課題

- run metadata field list の最終確定
- evaluation derived artifact schema
- replay/backtest artifact schema
- manual review record と runtime evidence を接続するときの shared field mapping

## 7. 結論

requirements wave の時点で blocking 級の矛盾は大きく 3 点あり、今回修正した。さらに foundation design で `exploratory` と replay granularity の placement を解消した。残りは evaluation / self-improvement 側 design で解くべき interface detail に整理できている。

したがって次段は、いきなり実装ではなく、まず cross-spec design alignment を意識しつつ `foundation` から design に入るのが妥当である。

## 8. Traceability Status

- `intent-to-requirements-trace-matrix.md`: required
- 現在状態: created
- 今回の alignment で matrix 更新が必要になる将来トリガー:
  - requirement responsibility transfer
  - requirement meaning change
  - new intent-bearing requirement addition

## 9. Recheck 2026-05-08

manual `requirements review wave` の finding 反映後に、`requirements alignment recheck` を実施した。

### 9.1 Recheck scope

- `dual-reviewer-foundation`
- `dual-reviewer-runtime`
- `dual-reviewer-evaluation`
- `dual-reviewer-self-improvement`
- `dual-reviewer-paper-interface`

再確認対象:

- `review_mode` shared contract の owner
- manual dogfooding evidence と runtime-mediated evidence の区別
- standard runtime comparison population の owner
- handoff boundary の責務配置

### 9.2 Recheck result

blocking 級の追加矛盾は見つからなかった。

整合した点:

- foundation が `review_mode` と canonical vocabulary の上流 owner になる
- runtime が runtime-mediated evidence 側の provenance emitter になる
- evaluation が standard comparison population の owner になる
- self-improvement と paper-interface は downstream consumer として provenance を保持する
- `DATA_INVALIDATION_POLICY.md` が mixed review mode の default exclusion を運用面で支える

残る design-level 課題:

- manual review record と runtime-produced evidence の shared field mapping
- review-mode provenance を各 derived artifact にどう埋め込むか
- mixed review mode を reporting artifact でどう表示するか

### 9.3 Process correction

この recheck は、`requirements review wave` 後に requirements が修正されたため、`design review wave` の前に必須の再調整として実施した。

以後は、review wave による phase 修正が入った場合も、同じ phase の alignment gate を次段に進む前に再実施する。

## 10. Recheck Addendum: Distributed Local Collection and Central Ingestion

他 project で local に取得した evidence を central repository 側へ持ち寄って分析・改善する flow を requirements に反映した。

### 10.1 Added ownership

- foundation
  - cross-project provenance field naming の owner
- runtime
  - portable evidence bundle export の owner
- evaluation
  - central-side ingestion / validation / admission の owner
- self-improvement
  - imported evidence を proposal provenance に結び付ける owner
- paper-interface
  - provenance-preserving reporting consumer のまま据え置き

### 10.2 Alignment result

blocking 級の追加矛盾は見つからなかった。

整合した点:

- deploy model は initial target を local-only のまま保つ
- その次の第一拡張は shared hosted runtime ではなく `distributed local collection + central ingestion` とする
- runtime は export するが intake owner にはならない
- evaluation は intake / admission owner になる
- self-improvement は imported evidence の provenance を proposal まで保持する

### 10.3 Design-phase implications

- portable evidence bundle の concrete shape
- imported bundle と in-repo run directory の field mapping
- admission result を analysis artifact にどう残すか
- imported evidence を learning artifact へどう渡すか
