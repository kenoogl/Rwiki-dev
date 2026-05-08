# TRUST_BOUNDARY

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` において何を誰が担い、何を system として信頼するかを定義する。

本 repo では、LLM が review の一部を実行し、Codex が開発の多くを支援する。したがって「誰が何を決めたことになっているのか」を明示しないと、以下の問題が起きる。

- LLM の自然言語出力をそのまま system truth と見なしてしまう
- validator で判定すべきことが人間の雰囲気判断になる
- 人間が責任を持つべき最終判断が曖昧になる
- system failure と operator judgment を区別できなくなる

本書の目的は、LLM、validator、人間の責務境界を切り分け、system として何を信頼対象に置くかを固定することにある。

## 2. 基本原則

- LLM は提案者であり、正本ではない
- validator は構文的・手続き的整合性の判定者である
- 人間は承認と例外判断の最終責任者である
- 見た目にもっともらしい出力ではなく、contract を満たした出力だけを system success とみなす

## 3. 信頼の階層

本 repo では、信頼対象を次の順で考える。

### 3.1 最も強く信頼するもの

- repo 内に version 付きで保存された artifact
- schema に適合した structured output
- required metadata を満たした run record
- validator pass / fail の記録
- explicit な human approve / reject / defer

### 3.2 条件付きで信頼するもの

- LLM が生成した finding
- LLM が生成した counter-evidence
- LLM が生成した necessity judgment
- Codex が提案した implementation change

条件:

- 対応 schema に適合していること
- required metadata が揃っていること
- human workflow における適切な decision point を通過すること

### 3.3 信頼しないもの

- version 不明の prompt 由来出力
- repo 外 memory に依存した恒久補正
- human が「たぶんそうだった」と回想した運用知識
- paper narrative の都合で後から整えられた runtime 解釈

## 4. LLM の責務

LLM は以下を担う。

- finding 候補の生成
- counter-evidence の生成
- necessity judgment 候補の生成
- review text や structured output の作成

LLM が担わないもの:

- final approval
- validator の代替
- invalid run の救済判断
- runtime rule の採否決定

重要なのは、LLM が「判断材料」を作るのであって、「正本の判断」を確定するのではないという点である。

## 5. validator の責務

validator は以下を担う。

- schema 適合性の確認
- required metadata 完備性の確認
- protocol version / prompt version / runtime version の整合性確認
- invalidation 条件への該当確認
- valid run / invalid run の機械的な仕分け

validator が担わないもの:

- finding が本質的に良い指摘かどうかの意味判断
- business / research 上の妥当性判断
- human approval の代替

validator は「意味の正しさ」を保証するものではなく、「system contract が守られているか」を保証する。

## 6. 人間の責務

人間は以下を担う。

- phase approval
- review output の approve / reject / defer
- invalid data の最終扱い
- runtime-affecting change の採否
- scope change の最終判断

人間が担わないもの:

- schema validation の手作業代替
- raw evidence の書き換え
- protocol drift の黙認

人間は例外判断の責任を持つが、手続き整合性の仕事まで肩代わりすべきではない。

## 7. Codex の位置づけ

Codex は開発支援者かつ実装担当であり、runtime の一部ではない。

Codex が担うもの:

- 文書起草
- spec 具体化
- 実装
- validator / script / test 整備

Codex が担わないもの:

- 承認の代行
- invalid run の黙殺
- hidden policy の注入

## 8. decision point の分離

この repo では decision point を少なくとも以下に分離する。

### 8.1 generation point

LLM が output を生成する点。

ここでは何も確定しない。

### 8.2 validation point

validator が schema / metadata / consistency を確認する点。

ここでは「手続き上 accept 可能か」だけが分かる。

### 8.3 approval point

人間が output を approve / reject / defer する点。

ここで初めて system の次工程に流してよいかが決まる。

### 8.4 adoption point

self-improvement proposal や runtime change を正式採用する点。

ここでは run-level 判断ではなく system-level 判断を行う。

## 9. trust boundary を破る例

以下は trust boundary violation とみなす。

- LLM の自由文を schema 不要の正本として扱う
- validator failure を human intuition で見逃す
- human approval なしに runtime-affecting change を導入する
- repo 外 memory に依存して steady-state behavior を変える
- paper convenience を理由に runtime judgment を後付けで書き換える

## 10. trust boundary と各 spec の関係

### 10.1 foundation

- role abstraction
- metadata contract
- schema contract

を定義し、trust boundary の土台を作る。

### 10.2 runtime

- LLM output の unit
- validator integration point
- human approval point

を具体化する。

### 10.3 evaluation

- valid / invalid run の切り分け
- metrics 対象となる evidence の制約

を具体化する。

### 10.4 self-improvement

- proposal を evidence-based にする
- intuition-based change を防ぐ

役割を持つ。

### 10.5 paper-interface

- paper-facing artifact が trust boundary を越えて runtime の正本にならないようにする

## 11. trust boundary のテスト観点

この文書に基づき、少なくとも以下を確認できる必要がある。

- required metadata が欠けた run は validator failure になる
- validator failure の run は valid run として集計されない
- human approval を通っていない output は採用扱いにならない
- runtime 変更は proposal / approval の記録なしに反映されない

## 12. この文書の完成条件

本書は、少なくとも以下を満たすときに有効とみなす。

- LLM、validator、人間、Codex の責務境界を説明できる
- 何を信頼対象に置くかが明確である
- system failure と human judgment の違いを説明できる
