# HUMAN_WORKFLOW

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` において人間、Codex、`cc-sdd` review process がどう分担するかを定義する。

本 repo では、system の一部を LLM が動かし、開発そのものも Codex が支援する。そのため、

- 誰が何を決めるのか
- どこで人間が承認するのか
- どこまで Codex が進めてよいのか

を明示しないと、runtime と開発 process の両方で責任境界が崩れる。

用語と status の共通規約は [CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md) を正本とする。

## 2. 基本方針

- 上位意図と最終判断は人間が持つ
- 仕様具体化、実装、validator 整備、migration 作業は Codex が主担当になってよい
- ただし `cc-sdd` の phase approval は人間が行う
- Codex は承認の代行者ではない
- progress / reopen / alignment の current state は `spec.json` を正本とする

## 2.5 採用する開発スタイル

本 repo では、完全自律型でも完全フレームワーク型でもなく、`cc-sdd` を骨格にした LLM 協調開発を採用する。

意味:

- 上位の方法論と phase gate は `cc-sdd` に従う
- 各 phase の具体化、文書起草、実装、検証は Codex が主担当になってよい
- 承認、scope change、runtime-affecting change の採否は人間が持つ

このため、Codex は「流儀を守りながら進める実装担当」であり、`cc-sdd` を置き換える存在ではない。

## 3. 役割定義

### 3.1 人間

主責務:

- `intent/` 文書の内容決定
- `operations/` 文書の最終判断
- spec phase ごとの承認
- runtime-affecting 変更の採否
- ambiguous case の最終判断
- invalid data の扱いに関する最終判断

人間が持つべき権限:

- approve
- reject
- defer
- scope change
- phase gate open / close

### 3.2 Codex

主責務:

- 文書の初稿作成と改訂
- spec requirements / design / tasks の具体化
- コード実装
- schema / validator / script 整備
- migration manifest 作成
- テスト実行と技術的確認

Codex がやってよいこと:

- 提案
- 実装
- 整理
- 検証

Codex がやってはいけないこと:

- 人間の承認を飛ばすこと
- scope change を暗黙に決めること
- invalid data を valid 扱いで前進させること
- paper 都合で runtime rule を変えること

### 3.3 `cc-sdd` review process

主責務:

- requirements phase の gate
- design phase の gate
- tasks phase の gate
- multi-feature 間の alignment gate
- implementation への流入制御

`cc-sdd` は開発 process の骨格であり、Codex の補助機能ではない。Codex はその骨格の中で作業する。

## 4. 旧 repo と新 repo の扱い

### 4.1 旧 repo

旧 repo は以下として扱う。

- archive
- source reference
- migration source
- failure evidence source

旧 repo で今後原則やらないこと:

- review runtime の再構築本体
- 新しい正本 spec の育成
- 本格的な新実験の継続

例外:

- 参照用メモの追加
- 移行経路を説明する整理文書の追加

### 4.2 新 repo

新 repo は以下として扱う。

- 正本
- `cc-sdd` 開発の主作業場
- runtime / evaluation / self-improvement の再構築場

## 5. 開発 workflow

### 5.1 上位文書フェーズ

1. 人間が intent と scope を提示する
2. Codex が `intent/` と `operations/` 文書を具体化する
3. 人間が内容を確認し、修正方針を決める

補足:

- `spec phase`、`review phase/profile`、`run status` の用語は [CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md) の定義に従う
- 初期段階では、この repo 自身が `dual-reviewer` 方法論の手動適用対象になる

### 5.2 spec フェーズ

1. Codex が requirements を起草する
2. 人間が requirements を review して approve / reject する
3. approve 後に Codex が design を起草する
4. 人間が design を review して approve / reject する
5. approve 後に Codex が tasks を起草する
6. 人間が tasks を approve する

補足:

- `cc-sdd` は phase の順序と gate を規定する
- Codex は各 gate の内側で、必要な調査、文書化、整合チェック、修正を進める
- feature 間で依存が強い場合は、vertical に 1 feature を最後まで進めず、requirements wave や cross-spec review を優先する
- feature 間依存と phase 進行順は [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md) を参照する
- 本 repo の spec 文書は、初期の dogfooding review 対象としても扱う

### 5.2.2 手動適用方針

初期再構築では、`dual-reviewer` の方法論をまず手動で適用する。

意味:

- review runtime の完全自動運用を前提にしない
- 人間が `intent` / `requirements` / `design` / `tasks` を読み、`dual-reviewer` 的な観点で点検する
- その結果を spec 修正、alignment、self-improvement input に戻す

この段階では、system を作ることと system の方法論を試すことが並行して進む。

### 5.2.3 Review Wave Order

manual review も実装や spec 作成と同様に、上流から下流へ段階的に進める。

順序:

1. `intent review`
2. `requirements review`
3. `design review`
4. `tasks review`

ルール:

- review は `intent` から `tasks` へ段階的に流す
- 各 review stage の内部では feature を水平展開して扱う
- 1 feature だけを先に深く review し切るのではなく、その stage に属する feature 群を一通り見てから次段へ進む
- 上流 review で修正が入った場合、下流 review は未確定扱いに戻す
- 下流 phase で観測した issue のうち、原因が intent の再解釈や intent 不整合にある場合は `intent-attributed issue` として記録する

例:

- `intent review` 完了後に `requirements review wave` へ進む
- `requirements review` は 5 feature を横断して行う
- `requirements` 修正が入った後は、`design review` を始める前に requirements alignment を再確認する

`intent review` artifact では少なくとも次を残す。

- `intent_revision_count`
- `intent_handback_count`
- `intent_review_findings_count`

下流 phase artifact では、必要に応じて次を残す。

- `phase_intent_attributed_issue_count`

是正ルール:

- review wave の finding を反映して同じ `spec phase` の文書が変わった場合、その phase の alignment gate を次段へ進む前に必ず再実施する
- 例:
  - `requirements review wave` の結果 requirements を修正した場合、`design review wave` の前に `requirements alignment recheck` を実施する
  - `design review wave` の結果 design を修正した場合、`tasks review wave` の前に `design alignment recheck` を実施する

この rule は optional ではなく、review progression にも multi-feature alignment を適用するための補助規則である。

### 5.2.5 multi-feature alignment gate

複数 feature が存在する場合、本 repo では各 phase の終端に feature 間調整 gate を置く。

#### requirements alignment gate

- 各 feature の requirements が一通り揃った後に実施する
- shared metadata contract
- invalidation rule
- prompt / schema / artifact 依存
- responsibility boundary

を横断確認し、齟齬を解消してから design フェーズへ進む

#### design alignment gate

- 各 feature の design が一通り揃った後に実施する
- interface
- file / directory placement
- versioning strategy
- validator integration point
- replay / paper / improvement への受け渡し

を横断確認し、齟齬を解消してから tasks フェーズへ進む

#### tasks alignment gate

- 各 feature の tasks が一通り揃った後に実施する
- implementation order
- shared artifact migration timing
- blocking dependency
- test sequencing

を横断確認し、implementation フェーズへ進む

この gate は optional ではなく、multi-feature 開発では標準手順とする。

### 5.2.6 遡上修正時の強制再調整

本 repo では、いったん先の phase に進んだ後でも、上流文書や既存 spec に遡って修正が入ることを前提にする。

その場合は、修正した文書だけを直して先へ進んではならない。修正が属する phase に応じて、対応する feature 間調整チェックを必ず再実施する。

ルール:

- `intent/` または `operations/` の修正
  - 少なくとも影響を受ける spec 群の requirements/design 整合確認を再実施する
  - すでに完了済みと見なしていた下流 phase も reopen し、再チェック対象に含める
- `requirements.md` の修正
  - `requirements alignment gate` を再実施する
  - すでに完了済みの design/tasks も requirements 変更の影響対象として再確認する
- `design.md` の修正
  - `design alignment gate` を再実施する
  - すでに完了済みの tasks も design 変更の影響対象として再確認する
- `tasks.md` の修正
  - `tasks alignment gate` を再実施する

この再調整は optional ではない。局所修正に見えても、shared metadata、artifact placement、評価指標、責務境界に波及しうるためである。

実務ルール:

- 遡上修正を行ったら、そのターン内または直後のターンで再調整結果を記録する
- 再調整結果は `docs/alignment/cross-spec-*.md` 系の文書に残す
- 上位 phase の修正が入った場合、完了済みの下流 phase も「確定済み」とは見なさず、再確認完了まで reopen 状態として扱う
- 再調整未実施のまま次 phase へ進むことは workflow 逸脱とみなす
- `INTENT` と `requirements` の意味対応を管理する trace matrix がある場合、更新トリガーは [intent-to-requirements-trace-matrix.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/traceability/intent-to-requirements-trace-matrix.md) を正本とし、該当時点で同 matrix も更新対象に含める

### 5.3 implementation フェーズ

1. approved tasks に基づいて Codex が実装する
2. Codex が validator / tests / local checks を実施する
3. Codex が implementation 横断調整事項を `docs/coordination/implementation-coordination-log.md` に記録する
4. 人間が結果を review し、次段へ進める

補足:

- implementation フェーズでも Codex は approved tasks の範囲を越えて scope を広げない
- implementation 中に新しい要件や境界変更が必要と判明した場合は、requirements または design に戻す
- requirements / design / tasks に戻した場合は、対応する alignment gate を再実施してから前進する
- multi-feature 実装では shared file 競合、validator 順序、integration blocker を `docs/coordination/implementation-coordination-log.md` に残す
- implementation 中に requirement 不足や intent 未接続 requirement が見つかった場合は、trace matrix と requirements spec を同時に reopen する
- implementation handback の判定は `docs/coordination/implementation-coordination-log.md` の `Handback Decision Rule` を正本とする

## 6. review session 実行時の人間関与

review runtime の実行時は、少なくとも以下を人間が保持する。

- target 選定
- protocol version 採用判断
- approve / reject / defer
- invalid run の扱い
- runtime-affecting 改善の採否

LLM に委譲しないもの:

- final sign-off
- experiment continuation / abort
- invalid data の救済判断

## 7. 承認単位

承認単位を曖昧にしない。

### 7.1 文書承認

- `intent/`
- `operations/`
- `requirements.md`
- `design.md`
- `tasks.md`

は phase 単位で承認する。

### 7.2 runtime 出力承認

review finding は user decision unit ごとに approve / reject / defer する。

### 7.3 変更承認

prompt / policy / schema / runtime の変更は proposal 単位で承認する。

## 8. Codex に委ねる深さ

Codex は「実装担当」であって「意思決定の代替」ではない。ただし、次は積極的に 맡せてよい。

- ファイル構成の具体化
- 文書草稿
- schema 設計のたたき台
- validator 実装
- テスト整備
- migration 手順の具体化

一方、次は人間が明示的に決める。

- 何を non-goal にするか
- 何を valid evidence とみなすか
- いつ phase を進めるか
- どの改善を正式採用するか

実務上の整理:

- `intent` と `operations` は人間主導、Codex 起草支援
- `requirements` / `design` / `tasks` は `cc-sdd` gate、人間承認、Codex 具体化
- `implementation` は Codex 主導、人間 review
- `evaluation` と `self-improvement` は Codex が分析し、人間が採否を持つ

## 9. 逸脱防止ルール

以下が起きた場合、workflow 逸脱とみなす。

- requirements / design / tasks を飛ばして implementation に進む
- 遡上修正後に対応する alignment gate を再実施せず前進する
- multi-feature なのに phase 終端の alignment gate を飛ばして次 phase に進む
- Codex が approval 済みとみなして進む
- 旧 repo の暫定判断を新 repo の正本として扱う
- review output unit と human decision unit がずれる
- invalid run を明示せずに次工程へ流す

## 10. この文書の完成条件

本書は、少なくとも以下を満たすときに有効とみなす。

- 人間、Codex、`cc-sdd` の役割分担を一読で説明できる
- 旧 repo と新 repo の使い分けが明確である
- phase approval の責任が曖昧でない
