# Cross-Spec Design Alignment

_作成日: 2026-05-08_  
_対象: `dual-reviewer-foundation` / `runtime` / `evaluation` / `self-improvement` / `paper-interface` design_

## 1. 目的

5 feature の design wave を横断し、artifact 配置、metadata contract、分類軸、受け渡し境界、versioning の齟齬を確認して、tasks フェーズに進む前に shared interface を揃える。

## 2. 確認した論点

- foundation metadata contract と runtime/evaluation の扱いが一致しているか
- raw evidence, derived analysis, learning artifacts, paper artifacts の配置境界が明確か
- valid / invalid / exploratory と local-only classification の責務が分離されているか
- finding-level human decision と run-level sign-off の意味が混線していないか
- paper convenience が runtime / evaluation へ逆流しない構造になっているか

## 3. 揃っている点

### 3.1 artifact 境界

- foundation は `runtime/` 配下の shared asset layer を所有
- runtime は `experiments/runs/` に raw evidence を保存
- evaluation は `experiments/analysis/` に derived artifact を保存
- self-improvement は `learning/` に proposal / backtest / adoption history を保存
- paper-interface は `paper/` に reporting artifact を保存

この 4 層の分離により、raw evidence を後段が上書きしない構造になっている。

### 3.2 metadata 軸

- foundation が `phase_profile`, `treatment`, `run_status`, `validator_status`, `human_signoff_status`, `evidence_class` を正本化
- runtime がそれを `run_manifest.yaml` と `review_case.json` に反映
- evaluation がその metadata を一次入力として分類と比較を行う

### 3.3 valid / invalid / exploratory の責務

- foundation で `evidence_class` を first-class field とした
- runtime は raw evidence freeze 後に validation と invalidation marker を付与する
- evaluation は `valid`, `invalid`, `exploratory` を standard population classification として扱う
- `analysis_blocked` は evaluation ローカルの分析不能状態として分離されている

### 3.4 replay 粒度

- foundation で step-level replay を最小単位とした
- runtime が `steps/*.json` を保存
- self-improvement がそれを replay input として受ける

### 3.5 paper consumer 化

- paper-interface は evaluation output を一次入力とする
- runtime raw artifact を claim-supporting source の標準入力にしない
- self-improvement proposal を performance claim の一次根拠にしない

## 4. 今回修正した点

### 4.1 run-level sign-off と finding-level decision の意味分離

問題:

- foundation には `human_signoff_status` と `human decision linkage` の両方がある
- runtime design でこの違いを明示しないと、run-level close judgment と finding-level accept/reject/defer が混線しうる

修正:

- runtime design に、run-level `human_signoff_status` は session close judgment を表し、個別 decision は `decisions/decision_units.json` 側で保持することを追記

### 4.2 paper maturity label と caveat の混線

問題:

- paper-interface で `caveated` を maturity label に含めると、`mature だが caveat を持つ artifact` を表しにくい

修正:

- paper-interface design で maturity label を `mature`, `preliminary`, `exploratory` の 3 つに限定
- caveat は `caveat_refs` による別軸表現へ変更

## 5. 残る open alignment points

### 5.1 runtime-owned profile configuration の置き場

現状:

- runtime design は profile emphasis を持つ
- concrete file placement は未確定

tasks 前に決める必要があること:

- `runtime/policies/phase_profiles/` のような配置にするか
- foundation asset と runtime-owned policy の境界をどう表現するか

### 5.2 evaluation minimum metric set の最終確定

現状:

- evaluation design は minimum metric set の初版を定義済み
- self-improvement / paper-interface が本当に必要とする field が確定しきっていない

tasks 前に決める必要があること:

- treatment-level metric の必須集合
- finding-level detail の最小保持範囲

### 5.3 proposal と repo version update の接続

現状:

- self-improvement は `adoption_register.json` で proposal と repo change を結ぶ方針
- concrete に何を ref として持つかは未確定

tasks 前に決める必要があること:

- spec version 参照か、git revision 参照か、artifact version 参照か

### 5.4 paper claim ID taxonomy

現状:

- paper-interface は `claim_id` を持つ
- claim の分類粒度は未確定

tasks 前に決める必要があること:

- claim type を runtime quality / workflow quality / methodology / limitation で分けるか

## 6. tasks フェーズへ渡す shared decisions

- raw evidence は `experiments/runs/` 以外へ置かない
- evaluation は `experiments/analysis/` を正本とし、raw run を編集しない
- self-improvement は `learning/` に proposal / test / adoption / rollback を保存する
- paper-interface は `paper/` に reporting artifact を保存し、evaluation output を一次入力とする
- `human_signoff_status` と `decision_units` は別 artifact で保持する
- `caveated` は maturity label ではなく caveat 軸で表現する

## 7. 結論

design wave の段階で blocking 級の齟齬は大きく 2 点あり、今回修正した。残りは tasks 設計時に具体 path や field を詰める detail に整理できている。

したがって、multi-feature 開発の `design alignment gate` は概ね通過可能であり、次段は tasks wave に入ってよい。

## 8. Design Reopen Procedure

後続作業の途中で `design.md` に修正が入った場合は、この alignment を「通過済みの記録」として放置しない。

必須手順:

1. 修正した feature の `design.md` を更新する
2. 対応する `spec.json` を更新する
   - `updated_at`
   - `custom.reopened.design = true`
   - 必要なら `custom.recheck.upstream_change_pending = true`
   - `custom.recheck.impacted_downstream_phases` に少なくとも `tasks` を入れる
3. この文書を再確認し、影響論点を追記する
4. 完了済みの `tasks` は reopen 扱いに戻し、再確認対象に含める
5. 再確認完了後にのみ `tasks alignment gate` へ進む

この手順を飛ばした場合、design 修正は局所変更ではなく workflow 逸脱として扱う。

## 9. Recheck Addendum: External Bundle Design Handback

requirements phase で追加した `distributed local collection + central ingestion` を受けて、design phase の handback を実施した。

### 9.1 Added design ownership

- foundation
  - cross-project provenance field の concrete metadata placement
- runtime
  - portable evidence bundle export boundary と bundle shape
- evaluation
  - portable bundle intake と admission artifact
- self-improvement
  - imported evidence provenance を proposal / backtest artifact に残す設計
- paper-interface
  - 既存 provenance-preserving consumer のまま据え置き

### 9.2 Recheck result

blocking 級の追加矛盾は見つからなかった。

整合した点:

- runtime export は raw run directory の正本性を壊さない
- evaluation admission は runtime export と別責務のまま保たれている
- imported evidence provenance は foundation metadata から evaluation、self-improvement へ流れる
- paper-interface は imported / local の違いを evaluation provenance 経由で継承できる

### 9.3 Remaining task-phase follow-ups

- bundle checksum verification をどの task 単位で実装するか
- imported bundle から in-repo analysis path への materialization 手順
- proposal artifact の provenance field を schema / template にどう落とすか
