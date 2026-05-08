# Feature Disposition Judgment

_作成日: 2026-05-08_
_目的: 旧 `dual-reviewer` の主要機能を `keep / reshape / drop-defer` で棚卸しし、再構築時の判断基準を固定する_

## 1. この文書の役割

この文書は、旧 `dual-reviewer` に存在した主要機能を再構築の観点から分類するための判断表である。

本書でいう分類は次の 3 つである。

- `keep`
  - 基本機能として残す
- `reshape`
  - 機能自体は残すが、責務、境界、interface、配置を変える
- `drop/defer`
  - 初期再構築からは外し、後段で再検討する

この分類は「旧 system が良かったか悪かったか」を判定するものではない。再構築の初期スコープに対して、どの機能をどう扱うべきかを決めるための文書である。

## 2. 判断基準

### 2.1 `keep`

次を満たす機能は `keep` とする。

- 再構築の中核価値に直結する
- `repo-contained runtime` と矛盾しない
- `protocol first` と矛盾しない
- 他 feature の土台として必要

### 2.2 `reshape`

次を満たす機能は `reshape` とする。

- 価値は高いが、旧 repo では責務が混線していた
- runtime / evaluation / paper / self-improvement のどこに属するかを引き直す必要がある
- 旧実装のまま移植すると trust boundary を壊す

### 2.3 `drop/defer`

次を満たす機能は `drop/defer` とする。

- 初期再構築に必須ではない
- スコープを不必要に広げる
- foundation 安定前に入れると複雑度が上がりすぎる
- Phase 2 以降の拡張として扱う方がよい

## 3. 主要機能の判断

### 3.1 Step A/B/C/D の review pipeline

- 判定: `keep`
- 理由:
  - dual-reviewer の中核構造そのもの
  - foundation と runtime の最重要 contract
  - evaluation と self-improvement の前提になる
- 再構築での扱い:
  - foundation で canonical state machine を定義
  - runtime で実行責務を持つ

### 3.2 3 role 構成 (`primary` / `adversarial` / `judgment`)

- 判定: `keep`
- 理由:
  - review behavior の根幹であり、ablation の軸でもある
  - 将来 multi-vendor に拡張しても role abstraction は必要
- 再構築での扱い:
  - foundation で abstract role 名として固定
  - runtime で role ごとの実行境界を持つ

### 3.3 `dr-init` 的 bootstrap

- 判定: `reshape`
- 理由:
  - 初期化は必要だが、旧 system の skill 前提をそのまま持ち込む必要はない
  - repo 内構造が固定化されたため、責務を縮められる
- 再構築での扱い:
  - runtime または foundation 補助機能として再設計
  - 「project に `.dual-reviewer/` を置く」発想自体も再検討対象

### 3.4 `dr-design` / `dr-log` / `dr-judgment` の skill 分割

- 判定: `reshape`
- 理由:
  - 機能境界としては有用だが、旧 skill 単位をそのまま module 境界にする必要はない
  - runtime module と skill presentation を分離した方がよい可能性がある
- 再構築での扱い:
  - runtime requirements / design で再分割
  - user-facing command 単位と内部 module 単位を分けて考える

### 3.5 共通 schema 5 file

- 判定: `keep`
- 理由:
  - foundation contract の核心
  - validator、evaluation、self-improvement の共通基盤
- 再構築での扱い:
  - foundation に repo-contained asset として移植
  - field の不足は design で補う

### 3.6 judgment subagent prompt template

- 判定: `keep`
- 理由:
  - Step C の再現性に直結する
  - prompt version traceability の基準点になる
- 再構築での扱い:
  - foundation の canonical prompt asset として保持

### 3.7 forced divergence prompt

- 判定: `keep`
- 理由:
  - adversarial role の中核機能
  - single / dual / dual+judgment の比較軸にも関わる
- 再構築での扱い:
  - runtime 側の prompt asset として保持
  - foundation ではなく runtime 配置に整理

### 3.8 `seed_patterns.yaml`

- 判定: `reshape`
- 理由:
  - 再利用価値は高い
  - ただし旧 Rwiki 固有性を持つため、「一般機能」と「旧 evidence 由来初期知識」を分けて扱う必要がある
- 再構築での扱い:
  - foundation で canonical placement を持つ
  - reusable seed と project-accumulated pattern を区別する

### 3.9 `fatal_patterns.yaml`

- 判定: `keep`
- 理由:
  - 見落とし不可カテゴリとして明確
  - runtime / evaluation の両方で意味がある
- 再構築での扱い:
  - foundation に残す
  - matching logic は runtime 側へ分離

### 3.10 treatment 比較 (`single` / `dual` / `dual+judgment`)

- 判定: `keep`
- 理由:
  - evaluation contract の中核
  - review behavior の比較と改善のために必要
- 再構築での扱い:
  - runtime が treatment を run metadata に出す
  - evaluation が比較を担う

### 3.11 dogfeeding scripts

- 判定: `reshape`
- 理由:
  - 分析スクリプト自体は有用
  - ただし旧 paper / experiment 前提が混ざっているため、そのまま正本にできない
- 再構築での扱い:
  - evaluation feature の source reference として使う
  - 再設計後の metric pipeline へ分解する

### 3.12 comparison report / evidence catalog / preliminary report

- 判定: `reshape`
- 理由:
  - 研究 narrative と evidence inventory の素材として有用
  - しかし runtime や evaluation の正本ではない
- 再構築での扱い:
  - paper-interface と self-improvement の reference source
  - 必要箇所のみ再定義

### 3.13 review logs (`docs/dual-reviewer-log-*`)

- 判定: `reshape`
- 理由:
  - 失敗・改善・判断の一次資料として価値が高い
  - しかし新 repo の structured runtime evidence ではない
- 再構築での扱い:
  - self-improvement 用 reference
  - failure pattern 抽出の source

### 3.14 repo 外 memory による補正

- 判定: `drop/defer`
- 理由:
  - 初期再構築の原則に反する
  - 再現性と deploy 境界を壊す
- 再構築での扱い:
  - steady-state behavior から排除
  - 必要知見は repo 内 artifact に還元する

### 3.15 transcript JSONL 依存の運用知識

- 判定: `drop/defer`
- 理由:
  - forensic source としては有用だが runtime contract ではない
  - operator の暗黙知を system に混ぜる危険がある
- 再構築での扱い:
  - archive 参照のみ

### 3.16 paper-first な field / process 拡張

- 判定: `drop/defer`
- 理由:
  - paper convenience は runtime rule より下位
  - 初期再構築で優先すべきではない
- 再構築での扱い:
  - paper-interface で吸収
  - foundation / runtime へ逆流させない

### 3.17 external contribution intake

- 判定: `drop/defer`
- 理由:
  - 将来価値は高いが、foundation 安定前に入れるべきではない
  - trust tier、compatibility、privacy の問題が未確定
- 再構築での扱い:
  - Phase 2 の候補

### 3.18 multi-vendor collective learning

- 判定: `drop/defer`
- 理由:
  - 初期再構築には不要
  - abstraction は残すが実装は後段
- 再構築での扱い:
  - role abstraction のみ foundation で保持

### 3.19 packaged CLI / hosted service

- 判定: `drop/defer`
- 理由:
  - local-only deploy を安定させる前に扱うべきでない
- 再構築での扱い:
  - Phase 2 以降

### 3.20 self-improvement loop

- 判定: `keep`
- 理由:
  - 今回の再構築の中心目的の一つ
  - review system を static tool ではなく evolving system にする
- 再構築での扱い:
  - 独立 feature として spec 化
  - proposal / backtest / approval / rollback の formal loop にする

## 4. まとめ

### 4.1 `keep`

- Step A/B/C/D pipeline
- 3 role 構成
- 共通 schema 5 file
- judgment prompt template
- forced divergence prompt
- `fatal_patterns.yaml`
- treatment 比較
- self-improvement loop

### 4.2 `reshape`

- `dr-init`
- `dr-design` / `dr-log` / `dr-judgment` 分割
- `seed_patterns.yaml`
- dogfeeding scripts
- comparison report / evidence catalog / preliminary report
- review logs

### 4.3 `drop/defer`

- repo 外 memory による補正
- transcript JSONL 依存の運用知識
- paper-first な runtime 拡張
- external contribution intake
- multi-vendor collective learning
- packaged CLI / hosted service

## 5. この文書の使い方

以後、旧機能を新 repo に移すときは、各機能について本書の分類を必ず確認する。

- `keep` のものは foundation / runtime / evaluation / self-improvement のどこに置くかを決める
- `reshape` のものは、どの責務へ再配置するかを design で確定する
- `drop/defer` のものは、requirements に混ぜず backlog または future work として扱う
