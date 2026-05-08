# NON_GOALS

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` が「今回は何をやらないか」を明示するための文書である。

再構築では、やることを定義するのと同じくらい、やらないことを定義することが重要である。旧 system の複雑化は、価値のある論点が多すぎるために、runtime、evaluation、paper preparation、将来構想が同時進行したことでも生じた。したがって本書は、scope を守るための防波堤として機能する。

本書でいう non-goal は、「永久に不要」という意味ではない。現段階では扱わず、後段で扱うべき論点を明示するものである。

## 2. なぜ non-goals が必要か

`dual-reviewer` の再構築対象には、以下のような魅力的だが危険な論点が多い。

- 多様な project から data を集めて改善したい
- 多言語、多 vendor、多 domain に広げたい
- 早く paper-ready にしたい
- 共有しやすい CLI や hosted service にしたい

いずれも価値はあるが、foundation が不安定な段階で同時に取り込むと、system の境界が再び曖昧になる。特に今回は、前回の失敗が「やることが多すぎて runtime の信頼境界が崩れた」ことに起因しているため、non-goals を先に固定する必要がある。

## 3. 初期再構築で扱わないもの

### 3.1 public contribution intake

GitHub PR などを通じて外部から measurement data を受け取る仕組みは、将来的には重要である。しかし初期再構築では扱わない。

理由:

- contribution schema が未確立の段階で受け入れると、ノイズが蓄積する
- anonymization、sensitivity、trust tier の扱いが未確定
- local-only で valid / invalid を機械判定できる状態が先に必要

位置づけ:

- 将来の `Phase 2` 課題
- foundation / evaluation / self-improvement 安定後に検討

### 3.2 multi-vendor collective learning

複数 LLM vendor を横断して runtime や learning loop を構築することは、初期再構築では扱わない。

理由:

- model 差の吸収が foundation を不必要に複雑化する
- runtime contract より先に vendor abstraction を最適化すると、本質がぶれる
- まずは abstract role contract のみを固定し、実装は single-vendor 前提で安定化させる

### 3.3 packaged CLI distribution

再構築直後から広く配布可能な CLI package を目標にしない。

理由:

- 配布形態を先に最適化すると、deploy convenience が runtime clarity に優先してしまう
- 今必要なのは install UX ではなく、repo-contained reproducibility である

初期目標:

- local repository 上で clone 直後に起動可能

### 3.4 hosted service 化

共有サービスや web application としての提供は初期再構築では扱わない。

理由:

- 認証、永続化、tenant 分離、機密管理など別問題が大量に増える
- 信頼境界の問題が infra 問題に埋もれる

### 3.5 paper-first optimization

論文化のために runtime を最適化することをしない。

これは「論文化を軽視する」という意味ではない。paper-facing artifact は重要だが、paper が runtime rule を決めるのではなく、runtime と evaluation の結果を paper が利用する構造を守る。

扱わないこと:

- figure を作りやすくするための field 追加を先行させること
- claim に都合のよいように runtime contract を後付け変更すること
- narrative を正当化するために invalid data を温存すること

### 3.6 speculative optimization

evidence のない prompt 追加、memory 増補、policy 増強を行わない。

扱わないこと:

- operator の感覚で「厳しそうだから」ルールを足すこと
- 再現されていない failure を想像で潰しに行くこと
- 変更コストを追わずに prompt を肥大化させること

### 3.7 broad domain generalization

再構築直後から、あらゆる言語、あらゆる artifact type、あらゆる review phase に対して equally good な system を目標にしない。

理由:

- 最初から汎化しすぎると contract が空疎になる
- まずは current use case に対する信頼できる runtime を成立させる必要がある

扱い:

- generalization を意識した抽象名は使う
- しかし実証と deploy target は狭く保つ

## 4. 初期再構築では後回しにするもの

以下は不要ではないが、初期の完了条件には入れない。

- external contribution schema
- contributor trust tier system
- federated evidence collection
- cross-project ranking or leaderboard
- automatic prompt synthesis from external corpora
- large-scale benchmark curation
- fully automated release pipeline

これらは foundation と self-improvement loop が安定した後に、別 spec または次段階計画として扱う。

## 5. 何を切らずに残すか

non-goal を定義することは、すべてを捨てることではない。以下は後段に回しても設計上の拡張点として残す。

- metadata で多言語・多 target を表現する余地
- protocol version を外部 data intake に拡張できる構造
- abstract role names による vendor 置換余地
- paper-interface による external communication の接続口
- self-improvement spec による将来の collective learning 接続余地

つまり、今は実装しないが、後で足せるように設計する。

## 6. scope を逸脱したと判断する条件

以下が起きた場合は、再構築が non-goal を侵食しているとみなす。

- runtime が安定する前に contribution intake の実装へ進み始める
- single-repo reproducibility が未達なのに distribution 設計に時間を使い始める
- invalidation policy が固まる前に comparative paper output を主目的にし始める
- self-improvement loop が未完成なのに external learning network を作り始める
- operator convenience を優先して repo 外 memory を再導入する

その場合は、spec の追加ではなく scope の切り戻しが必要である。

## 7. この文書が spec に与える影響

本書の非目標は、各 spec の要件から直接除外事項として反映されるべきである。

例:

- `dual-reviewer-foundation`
  - multi-vendor 実装や hosted service 要件を入れない
- `dual-reviewer-runtime`
  - paper convenience のための runtime rule を入れない
- `dual-reviewer-evaluation`
  - external contribution ingestion を初期要件にしない
- `dual-reviewer-self-improvement`
  - repo 外 memory による恒久補正を認めない
- `dual-reviewer-paper-interface`
  - runtime contract を逆流的に変更する責務を持たせない

## 8. 将来拡張との関係

本書に書かれた non-goals は、将来の拡張候補でもある。したがって将来これらを扱う場合は、

- 本書から当該項目を削る
- あるいは「initial rebuild の non-goal」から「Phase 2 goal」へ格上げする

という明示的変更が必要である。暗黙の scope creep を避けることが重要である。
