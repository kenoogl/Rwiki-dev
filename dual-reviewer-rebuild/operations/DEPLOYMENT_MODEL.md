# DEPLOYMENT_MODEL

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` をどこでどう使う system として設計するかを定義する。

前回の失敗の一部は、deploy 形態を十分に固定しないまま runtime を作ったことにある。どこで使うのかが曖昧だと、

- repo 外 memory を置いてしまう
- local 環境依存を見落とす
- operator の手元状態を前提にしてしまう

という問題が再発する。したがって deploy 形態は foundation より前に明示する必要がある。

## 2. 初期 target

初期再構築の primary target は以下である。

- local repository execution
- single operator use
- repo-contained runtime

意味:

- 1 人の operator が、1 つの local repository 上で review runtime を起動する
- 実行に必要な prompts、policies、schemas、validators は repo 内にある
- 実行結果は repo の定めた evidence path に保存される

## 3. deploy 可能とみなす条件

この repo では、少なくとも以下を満たしたときに「deploy 可能」とみなす。

- clone 直後に必要文書と runtime artifact が揃っている
- 実行に必要な versioned asset が repo 内に存在する
- run metadata を記録できる
- validator が valid / invalid を機械判定できる
- operator が repo 外 memory を足さなくても定常運用できる

deploy 可能とは、public release 可能という意味ではない。まずは local 環境で信頼できる運用が成立することが条件である。

## 4. deploy unit

この system の deploy unit は、初期段階では repository 単位である。

含まれるもの:

- `intent/`
- `operations/`
- `.kiro/specs/`
- `runtime/`
- `experiments/`
- `learning/`
- `paper/` の interface 的成果物

含まれないもの:

- operator の個人 memory
- repo 外 prompt 置き場
- undocumented shell alias や local-only helper

## 5. 運用前提

### 5.1 operator 前提

- operator は repo の文書に従って実行する
- operator は phase approval を行う
- operator は invalid run の扱いを確認する

### 5.1.5 開発運用前提

- この repo の開発は `cc-sdd` の phase gate に従う
- Codex は文書具体化、実装、検証の主担当として動いてよい
- ただし deploy 可能状態の定義変更や scope change は人間承認を要する

### 5.2 runtime 前提

- runtime は repo-contained artifact のみを norm とする
- local 環境依存がある場合は config と metadata に露出させる

### 5.3 evidence 前提

- raw run output は repository-defined path に保存する
- derived analysis は raw output とは分離する

## 6. 初期段階で対象外の deploy 形態

以下は初期 target に含めない。

### 6.1 embedded use from arbitrary other repositories

他 repo から library 的に埋め込んで使う形態は後段に回す。

理由:

- interface の安定化前に埋め込みを許すと contract が固定できない

### 6.2 packaged CLI distribution

一般配布用 CLI は後段に回す。

理由:

- install UX より先に runtime clarity を確保する必要がある

### 6.3 hosted shared service

共有 web service や team-hosted runtime は対象外とする。

理由:

- auth、storage、tenant separation、privacy の課題が別に立つ

## 7. 旧 repo との関係

deploy という観点では、旧 repo は runtime の実行対象ではなく reference source である。

旧 repo の役割:

- spec source
- implementation source
- log and failure archive
- migration source

旧 repo に期待しないこと:

- 新 runtime の正本
- 再構築後の deploy target

## 8. 将来の deploy 拡張

将来は以下の deploy 形態へ拡張する余地がある。

- embedded use from other repos
- packaged CLI
- GitHub-based contribution intake
- external run submission

ただし、これらは foundation、runtime、evaluation、self-improvement が安定した後に扱う。初期再構築の acceptance gate には入れない。

### 8.1 First expansion path: distributed local collection with central ingestion

初期 target の次に想定する拡張は、shared hosted runtime ではなく、複数の local 環境で採取した evidence を central repository 側に持ち寄って分析・改善する形である。

基本 flow:

1. 各 local operator が各自の repository 上で review runtime を実行する
2. 各 local environment が portable evidence bundle を生成する
3. central 側の rebuild repository が bundle を ingest する
4. central 側で validation / admission / analysis を実行する
5. central 側で improvement proposal を作成し、採否を管理する

この形を優先する理由:

- shared hosted service を先に作らずに provenance を保ちやすい
- operator ごとの local execution 条件を evidence bundle に閉じ込めやすい
- raw evidence 収集と central analysis を分離できる

### 8.2 Implications of the first expansion path

この拡張を成立させるには、少なくとも次が必要になる。

- local runtime が export 可能な evidence bundle contract
- central evaluation が ingest / validate / admit できる intake contract
- source repository, source revision, review mode, protocol version を含む provenance contract
- standard comparison set に入れる条件と exploratory / rejected に落とす条件

これらは初期再構築の acceptance gate には入れないが、external run submission を将来扱うなら設計上の先行考慮が必要である。

## 9. 設計上の含意

この deploy model は各層に以下を要求する。

### 9.1 foundation への要求

- repo-contained asset rule
- versioned prompts and schemas
- config contract

### 9.2 runtime への要求

- relative path で asset を解決できる
- hidden operator memory に依存しない
- local run metadata を残せる

### 9.3 evaluation への要求

- local run の validity を機械判定できる
- invalid data を切り離せる

### 9.4 self-improvement への要求

- local evidence だけで proposal loop を回せる
- external contribution がなくても改善可能

## 10. 逸脱防止ルール

以下が起きた場合、deploy model 逸脱とみなす。

- repo 外 memory が runtime-critical に使われる
- local-only で運用できない前提が silently 入る
- package 化の都合で foundation contract が崩れる
- shared service 前提の状態管理が runtime に混入する

## 11. この文書の完成条件

本書は、少なくとも以下を満たすときに有効とみなす。

- 初期 target が local-only であることが明確
- deploy 可能の意味が runtime trust の観点で定義されている
- 将来拡張と初期 scope が混同されていない
