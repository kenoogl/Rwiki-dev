# DATA_INVALIDATION_POLICY

## 1. この文書の役割

この文書は、どの run を valid とみなし、どの run を invalid とみなすかを定義する。

前回の失敗では、data acquisition plan の drift や repo 操作の混線によって、採取済み data の信頼性が損なわれた。問題は「何かがおかしかった」という感覚があっても、無効化条件が先に定義されていなかったため、どの data を残し、どの data を比較対象から外すかが曖昧になったことにある。

再構築では invalidation を一次概念として扱う。invalid run は失敗ではあるが、消すべきものではない。valid run と明確に分離して保存し、後続工程で混ざらないようにする。

## 2. 基本原則

- valid / invalid の判定基準は run 前または run close 前に定義されている必要がある
- invalidation 判定は可能な限り metadata と validator で機械化する
- invalid run は削除せず保存する
- invalid run は valid data の集計、paper input、self-improvement input から原則除外する
- 例外的に invalid run を参照する場合は、明示的に invalid data として扱う

## 3. valid run の最小条件

少なくとも以下を満たす run だけを valid candidate とみなす。

- protocol version が記録されている
- prompt version が記録されている
- runtime version が記録されている
- target artifact hash が記録されている
- treatment が記録されている
- required evidence files が揃っている
- validator が pass している
- human sign-off status が記録されている

## 4. invalid run の主な類型

### 4.1 metadata 欠落型

例:

- protocol version 不明
- prompt version 不明
- runtime version 不明
- target artifact hash 不明

扱い:

- 原則 invalid
- 後から推定して valid 化しない

### 4.2 mixed-version 型

例:

- 同一 run 内で prompt version が混在
- 実行中に runtime contract が変わった
- protocol version が途中で切り替わった

扱い:

- 原則 invalid
- 分割して再構成できるとしても、原 run 自体は invalid 記録を残す

### 4.3 target drift 型

例:

- target artifact が run 中または run 間で意図せず変化
- target hash と実際の review 対象が一致しない

扱い:

- 比較評価の対象としては invalid
- 必要なら exploratory reference としてのみ残す

### 4.4 validation failure 型

例:

- schema validation failure
- required field missing
- run close validation failure

扱い:

- invalid
- 原則として valid evidence pipeline に流さない

### 4.5 workflow violation 型

例:

- human approval が必要な点を飛ばしている
- review output unit と decision unit が一致していない
- sign-off 不在で採用処理が進んだ

扱い:

- invalid
- runtime / workflow の defect evidence としては残す

### 4.6 contamination 型

例:

- repo 外 memory が runtime-critical に作用していた
- hidden operator intervention が run condition を変えた
- paper 都合の後付け編集が raw evidence に混ざった

扱い:

- invalid
- contamination source を記録する

## 5. invalidation marker

invalid run には、少なくとも以下を記録する。

- run identifier
- invalidation category
- invalidation reason
- detection timing
- validator / human のどちらが検出したか
- raw evidence location

invalidity は raw log の削除ではなく、別 marker または metadata によって表現する。

## 6. invalid run の保存方針

- invalid run も `experiments/runs/` に保存する
- ただし valid run と区別可能でなければならない
- derived analysis では invalid run を default で除外する
- self-improvement で invalid run を使う場合は「runtime failure evidence」として別扱いにする

## 7. invalid run の利用可能性

invalid run は無価値ではない。用途を限定すれば有用である。

使ってよい用途:

- runtime defect analysis
- workflow defect analysis
- invalidation rule の妥当性検証
- self-improvement における failure pattern 抽出

使ってはいけない用途:

- comparative metrics の正規入力
- paper の performance claim の一次 evidence
- valid improvement gain の算定基礎

## 8. valid / invalid の判定主体

### 8.1 validator が判定するもの

- metadata completeness
- schema compliance
- version consistency
- required artifact presence

### 8.2 人間が最終判断するもの

- contamination の有無
- hidden intervention の扱い
- exploratory retention の可否

原則として、human は invalidity を解除するためではなく、invalidity の意味づけと保存方針を決めるために関与する。

## 9. 比較評価での扱い

比較評価では、invalid run は default で除外する。

加えて、manual dogfooding evidence と runtime-mediated evidence を混在させない。manual dogfooding は Phase 1 の方法論検証 evidence として保持できるが、standard runtime comparison population には default で入れない。

必要な保証:

- valid run 集合だけで metrics を再計算できる
- exclusion された run の数と理由を報告できる
- invalid run の存在自体を隠さない
- mixed review mode を使う場合、そのこと自体を明示できる

## 10. self-improvement での扱い

self-improvement では invalid run も入力になりうるが、用途を分ける。

### 10.1 valid run 由来

- review quality の改善
- prompt / policy / schema の調整

### 10.2 invalid run 由来

- workflow defect の改善
- validator coverage の改善
- contamination prevention の改善

invalid run を用いて「review quality が高かった」と主張してはいけない。

## 11. paper-interface での扱い

paper-facing artifact では、invalid run を原則集計から除外する。ただし、

- exclusion rule
- invalid run 件数
- invalidation categories

は limitations や methodology の一部として明示できる。

## 12. 旧 repo 由来 data の扱い

旧 repo 由来の data は、一律に invalid と決める必要はないが、初期段階では cautious に扱う。

原則:

- runtime contract が不明瞭なものは valid evidence として再利用しない
- reference / narrative / failure archive としては保持する
- 再利用する場合は、新 repo の invalidation policy に照らして再分類する

## 13. 逸脱防止ルール

以下が起きた場合、この policy 違反とみなす。

- invalid run を valid run に混ぜて集計する
- invalid marker を付けずに黙って除外する
- human intuition で invalidity をなかったことにする
- paper convenience のために invalidity を曖昧化する

## 14. この文書の完成条件

本書は、少なくとも以下を満たすときに有効とみなす。

- valid / invalid の判断条件を事前に説明できる
- invalid run を削除ではなく分離保存できる
- evaluation と self-improvement が invalid data をどう扱うか説明できる
