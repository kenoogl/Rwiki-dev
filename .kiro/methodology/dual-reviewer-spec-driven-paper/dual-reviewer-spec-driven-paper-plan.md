# dual-reviewer 論文化計画 — intent-origin spec-driven development edition

_作成: 2026-05-09_  
_status: draft v0.2_  
_focus: code review 単体ではなく、intent 起点の仕様駆動開発支援_

---

## 1. この計画の位置付け

本計画は、`dual-reviewer` の次段論文化対象を
**「intent から始まる仕様駆動開発の下流工程支援」**
として整理し直す paper roadmap である。

前段で既に得られているもの:

- `dual-reviewer-rebuild` 上で v1 prototype を構築した
- implementation governance を formalize した
- manual `implementation conformance review` を 1 サイクル通した
- review finding の修正と rerun を evidence として残した

これらは主に `system construction validity` の証拠である。
次の論文では、これを土台にして、

- `intent`
- `requirements`
- `design`
- `tasks`
- `implementation`
- `review`

へ下る仕様駆動開発プロセス全体を、
`dual-reviewer` がどう支えるかを主対象に置く。

---

## 2. 研究目的

この論文で示したい中心命題は次である。

> `dual-reviewer` は、単なる multi-agent review prompt ではなく、  
> **intent 起点の仕様駆動開発において、下流工程ほど高まる認知負荷と手戻り管理を支える workflow, evidence, governance system**  
> として機能する。

特に強調したいのは、単に「良い指摘を出すか」ではない。
中心問題は次である。

- `intent` しかない段階で論点漏れや premature closure が起きやすい
- `design` や `tasks` で detail が増えると人間の認知負荷が高まる
- implementation / review phase では disagreement や caveat が落ちやすい
- 手戻りが起きても、どこまで戻るべきかを管理できないと workflow が壊れる

この問題に対して `dual-reviewer` は、

- adversarial review
- judgment
- `A/B/C/D` handback
- conformance review
- signal register
- workflow gate status
- evidence-preserving reporting

を組み合わせた system として位置づける。

---

## 3. 評価の主線

今回の論文化では、評価を 3 つの track に分ける。

### Intent Track

開始点が `intent` のみで、
そこから `requirements / design / tasks` を起こすケース。

ここで見たいこと:

- intent から requirement への落とし込みで論点漏れを減らせるか
- design/tasks の detail 増加に対して premature closure を抑えられるか
- handback が適切に `D -> C -> B -> A` と管理されるか

### Spec Track

既に `requirements / design / tasks` があるケース。

ここで見たいこと:

- downstream refinement での認知負荷軽減
- alignment gate の運用
- recheck / reopen の深さ管理

### Implementation Track

仕様駆動開発の downstream artifact として
implementation code が存在するケース。

ここで見たいこと:

- implementation / conformance review を dual-reviewer がどう支えるか
- disagreement, caveat, reopen depth を evidence として残せるか
- code review を workflow 全体の末尾 phase として扱えるか

**重要**: code review は主線そのものではなく、Implementation Track に属する downstream phase である。

---

## 4. 論文の新規性

### 5.1 intent 起点の workflow-governed review system

本研究の新規性は、LLM review を
「複数 agent を組み合わせた prompt trick」ではなく、
**intent 起点の仕様駆動開発を支える workflow system**
として提示する点にある。

含まれる要素:

- cognitive-load-aware review design
- phase-aware workflow
- `A/B/C/D` handback
- conformance review
- signal register
- workflow gate status
- evidence-preserving paper interface

### 5.2 finding quality と process quality の同時評価

既存の LLM review 評価は finding precision/recall に寄りやすい。
本研究では、それに加えて次を測る。

- finding が traceable か
- caveat が脱落していないか
- reopen depth が管理されているか
- downstream rework signal を残せるか
- `intent` 起因問題がどの phase で観測されたか

### 5.3 implementation phase を含む end-to-end support

`dual-reviewer` は spec review だけでも code review だけでもない。
`intent -> requirements -> design -> tasks -> implementation -> review`
の end-to-end を同じ workflow contract で扱える点を訴求する。

### 5.4 adversarial review の位置づけ

`adversarial review` は novelty の中心ではない。

位置づけ:

- 高認知負荷レビューで見落とし候補を並列化する mechanism
- 単独 reviewer の premature closure を崩す mechanism

`judgment` は、その結果として増えた候補を整理し、
過剰修正を抑制する mechanism である。

---

## 5. 論文の主訴求点

1. `dual-reviewer` は code review assistant ではなく、仕様駆動開発支援 system である
2. 人間の認知負荷が高い下流工程を、adversarial/judgment と artifact/gate の両方で支える
3. finding を返すだけでなく、手戻り深さと証跡まで扱う
4. intent-only / spec-present / implementation-present の複数開始条件を同じ workflow contract で扱える
5. manual dogfooding によって workflow 自体の成立を先に確認している

避けるべき過剰主張:

- 「完全自動 review が人間を置き換える」
- 「code correctness を絶対 oracle として証明した」
- 「全ドメインで一般化する」

---

## 6. 評価仮説

### Claim 1

`dual-reviewer` は、仕様駆動開発の下流工程における cognitive brittleness を減らす。

### Claim 2

`dual-reviewer` は、finding だけでなく disagreement, caveat, disposition, handback depth を traceable に残す。

### Claim 3

`dual-reviewer` は、`intent-only`, `spec-present`, `implementation-present` の異なる開始条件でも workflow を維持できる。

### Claim 4

`dual-reviewer` は、review 後の evidence を self-improvement / reporting に再利用可能な形で残す。

---

## 8. 評価対象

### Intent Track case

- `dual-reviewer-rebuild` 自体の再構築過程
- intent-only または spec-bootstrap case として使う

### Spec Track cases

- `phase-field-reverse-spec`
- `heat3d` 系の spec-present case
- 必要なら他の spec-present sample

### Implementation Track cases

- `phase-field-cpp`
- `heat3d-julia`
- `iot-arduino-c`

ただし Implementation Track の code artifact は、
対応する `intent/spec/design/tasks` を伴う downstream sample としてのみ扱う。

---

## 9. データ取得方針

### 9.1 target-side prior evidence を主評価に混ぜない

過去バージョンの reviewer や別実装系で得た観測値は、
main evaluation evidence として使わない。

使ってよい用途:

- target boundary の説明
- historical context
- internal memo

### 9.2 main evaluation evidence

論文で主に使うのは、
Ruby 版 `dual-reviewer v1` で新たに取得する evidence のみである。

### 9.3 implementation artifact の扱い

implementation code は review object ではあるが、
論文の主対象はコードそのものではなく、
そのコードに至る workflow と review process である。

### 9.4 treatment decomposition

`dual-reviewer` の効果は、少なくとも次の 3 treatment を区別して観測する。

1. `single`
   - primary review のみ
2. `dual`
   - primary + adversarial
   - judgment なし
3. `dual+judgment`
   - primary + adversarial + judgment

この分解を入れる理由は次の 2 つである。

1. `adversarial` の寄与と `judgment` の寄与を分けて示すため
2. 「2 reviewer で十分ではないか」という反論に答えられるようにするため

ただし、全 case で 3 treatment を必須にするわけではない。

- 少なくとも 1 つの代表 case では `single / dual / dual+judgment` を取る
- 他の case では `single / dual+judgment` を主比較としてよい

現時点では、代表 case は `phase-field-cpp` とする。

---

## 10. Immediate Next Work

1. case manifest を `intent/spec/implementation` の 3 track で再整理する
2. target-specific protocol を「code review protocol」から「implementation-phase protocol」に修正する
3. `phase-field-cpp` snapshot 文書から prior observed metrics を外す
4. first-run plan を Implementation Track pilot として書き換える
5. `phase-field-cpp` を代表 case として `single / dual / dual+judgment` を取得する
6. その後に `heat3d-julia` を第 2 implementation case として起こす
