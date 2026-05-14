# HUMAN_WORKFLOW

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` において人間、Codex、意図駆動ワークフロー review process がどう分担するかを定義する。

本 repo では、system の一部を LLM が動かし、開発そのものも Codex が支援する。そのため、

- 誰が何を決めるのか
- どこで人間が承認するのか
- どこまで Codex が進めてよいのか

を明示しないと、runtime と開発 process の両方で責任境界が崩れる。

用語と status の共通規約は [CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md) を正本とする。

## 2. 基本方針

- 上位意図と最終判断は人間が持つ
- 仕様具体化、実装、validator 整備、migration 作業は Codex が主担当になってよい
- ただし意図駆動ワークフローの phase approval は人間が行う
- Codex は承認の代行者ではない
- progress / reopen / alignment の current state は `spec.json` を正本とする

## 2.5 採用する開発スタイル

本 repo では、完全自律型でも完全フレームワーク型でもなく、意図駆動ワークフローを骨格にした LLM 協調開発を採用する。

意味:

- 上位の方法論と phase gate は意図駆動ワークフローに従う
- 各 phase の具体化、文書起草、実装、検証は Codex が主担当になってよい
- 承認、scope change、runtime-affecting change の採否は人間が持つ

このため、Codex は「流儀を守りながら進める実装担当」であり、意図駆動ワークフローを置き換える存在ではない。

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

### 3.3 意図駆動ワークフロー review process

主責務:

- requirements phase の gate
- design phase の gate
- tasks phase の gate
- multi-feature 間の alignment gate
- implementation への流入制御

意図駆動ワークフローは開発 process の骨格であり、Codex の補助機能ではない。Codex はその骨格の中で作業する。

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
- 意図駆動ワークフロー開発の主作業場
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

- 意図駆動ワークフローは phase の順序と gate を規定する
- Codex は各 gate の内側で、必要な調査、文書化、整合チェック、修正を進める
- feature 間で依存が強い場合は、vertical に 1 feature を最後まで進めず、requirements wave や cross-spec review を優先する
- feature 間依存と phase 進行順は [phase-and-feature-dependency-map.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md) を参照する
- 本 repo の spec 文書は、初期の dogfooding review 対象としても扱う

### 5.2.1 開始指示の既定解釈

本 repo では、user が case 開始時に

- `<case-slug> を intent から進めてください`
- `この intent と仕様から case を始めてください`

のように短く指示した場合、細かい stop 条件がなくても
**次の human gate まで進める**
のを既定とする。

intent-start の既定解釈:

1. source docs を読む
2. `intent` の current understanding を固定する
3. active feature set 案を作る
4. feature dependency order と主要 open question を整理する
5. 最初の human gate input として提示する

この既定では、user が明示的に追加指示しない限り、

- requirements 文書を勝手に生成し切らない
- design / tasks へ自動で進まない
- implementation へ入らない

つまり、開始指示は
`最初の意味ある gate まで自然に進める`
ための短い command として扱う。

例外:

- user が明示的に
  - `requirements wave まで進めて`
  - `最初の gate を越えて続けて`
  のように指示した場合は、その追加条件を優先する

### 5.2.1.1 参照 case なしの bootstrap

本番運用では、特定の既存 case を参照しなくても
新しい case を始められなければならない。

そのため、新規 case は原則として次から始める。

- bootstrap guide:
  - [reference-free-case-bootstrap-guide.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/reference-free-case-bootstrap-guide.md:1)
- bootstrap script:
  - `ruby dual-reviewer-rebuild/scripts/bootstrap_reference_free_case.rb <case-slug> --intent-source <path> --canonical-source <path>`

この bootstrap で最初に起こすもの:

- umbrella `intent.md`
- umbrella `spec.json`
- case workflow overlay
- active worklist
- workflow path

ルール:

- 既存 case の中身はコピーしない
- 再利用してよいのは template と gate structure だけとする
- case 固有 stress は、その case 自身の source から書く

### 5.2.1.2 heuristic profile の既定方針

`heuristic_profile` は、case を rich に見せるために最初から増やさない。

既定方針:

- `heuristic_profile_ref` を case manifest に書かない場合、
  runner は track ごとの minimal template を使ってよい
- minimal template は次を正本とする
  - implementation:
    - [implementation/_minimal_template.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/implementation/_minimal_template.yaml:1)
  - intent:
    - [intent/_minimal_template.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/intent/_minimal_template.yaml:1)
  - spec:
    - [spec/_minimal_template.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/spec/_minimal_template.yaml:1)
- case 固有 rule は、approved source に anchored した review-critical contract があるときだけ追加する

詳細方針は [heuristic_profiles/README.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/README.md:1) を正本とする。

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
- 下流 phase がまだ生成されていない段階で上流文書の不整合を発見した場合、その場で上流を修正せず、下流 phase の起草開始時の入力として保留する。修正の着手は対応する alignment gate の文脈で判断する。
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

### 5.2.5.5 wave 指示の既定解釈

本 repo では、user が

- `requirements wave を進めてください`
- `design wave を進めてください`
- `tasks wave を進めてください`

のように指示した場合、stop 条件を細かく追加で書かなくても、既定でその phase の gate package 作成まで進める。

既定解釈:

- `requirements wave`
  - 各 feature の requirements 起草
  - feature-local review
  - requirements review wave
  - requirements alignment gate
  - human requirements gate package 作成
  - `design` には自動で進まない
- `design wave`
  - 各 feature の design 起草
  - feature-local review
  - design review wave
  - design alignment gate
  - human design gate package 作成
  - `tasks` には自動で進まない
- `tasks wave`
  - 各 feature の tasks 起草
  - feature-local review
  - tasks review wave
  - tasks alignment gate
  - human tasks gate package 作成
  - `implementation` には自動で進まない

この既定を置く理由は、user が
`どこで止めるか`
を毎回細かく指示しなくても、phase 単位で自然に使えるようにするためである。

各 wave の終端では、gate package に
`今ここで人間が何を判断すればよいか`
を明示する。

最低限含めるもの:

- この gate で承認すべき対象
- まだ判断しなくてよい対象
- 重要な方針選択と current proposal
- `approve / reject / defer` が次の phase にどう効くか

例外:

- user が明示的に
  - `design まで続けて`
  - `tasks まで一気に`
  - `approval 後を仮定して先へ進めて`
  のように指示した場合は、その追加指示を優先する
- upstream phase が未承認の場合は、下流 phase には進まない

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

### 5.2.6.1 設計フェーズで判明した仕様課題の取り扱い

設計レビュー中に「現状の requirements と設計上の制約が衝突する」「設計の具体化で仕様に書かれていない事項が必要」と判明することがある。このとき、仕様改版（requirements 改版 + 再承認）が必要か、設計内吸収（仕様の文言は変えず設計で対処）が可能かの判断は、利用者対話で確定する。

判断軸は memory `feedback_design_spec_roundtrip.md` を参照する。判断の結果に応じて次の手順を採る。

#### 仕様改版が確定した場合

1. 当該 spec の requirements.md を改版する。設計レビューで上がった論点を AC として明確に書き起こす（軽微修正で済ませない）
2. 他 spec への波及を再点検する（節 5.2.5 の requirements alignment gate を参照）
3. spec.json の `approvals.requirements.approved` は再承認が必要となる（節 5.2.6 の遡上修正再調整に該当）
4. 利用者の明示承認を得てから承認状態を更新する（memory `feedback_approval_required.md` 参照）

#### 設計内吸収が確定した場合

1. design.md 内に「設計決定事項」として記録する（memory `feedback_design_decisions_record.md` 参照）
2. requirements.md は改版しない（本文・変更履歴とも変更なし）
3. 仕様 AC との整合は design.md 本文で明示的に参照する（例：「本設計は requirements R3.5 の自然な実装具体化として、X を Y で実現する」）

### 5.2.7 phase evidence summary

`requirements / design / tasks` の human gate に進む前に、本 repo では phase ごとに
`phase evidence summary` を 1 つ作成する。

これは review artifact, alignment memo, workflow gate status を gate package として読むための
**derived artifact** であり、正本そのものではない。

最低限含めるもの:

- reviewed feature set
- feature-local review artifact refs
- phase-level review wave artifact ref
- phase alignment memo ref
- workflow gate status ref
- metric snapshot
- open point carried forward
- human decision guide
- gate readiness statement

ルール:

- source of truth は review artifact / alignment memo / workflow gate status であり、summary はそれらの参照と集約に徹する
- summary と source artifact が衝突した場合、source artifact を優先する
- findings が `0` 件でも summary は作成する
- human gate request は、原則としてこの summary を入口に行う
- `intent` と `requirements` の gate input 文書は、人間が意味を追える平易な文章で書かれていなければならない
- `design` と `tasks` は、責務・依存・実装順序が追える限り、ソフトウェア工学的なフォーマットを許容する
- summary には `この gate で何を判断するか / 今は何を判断しないか` を平易に書く

### 5.2.8 要件レビューの 5 ラウンド構成と波及精査

要件フェーズのレビューは 5 ラウンド構成で実施する。第 5 ラウンドは隣接フィーチャーへの影響伝達を必須プロセス化する。基盤フィーチャーのような上流フィーチャーを改版した場合は、下位の全フィーチャーへの影響精査を必ず行う。

#### レビュー 5 ラウンド構成

##### 第 1 ラウンド：基本整合性

- **観点**：内部矛盾、参照漏れ、既知の調整要求の反映状況
- **対象**：受け入れ基準の番号、表記揺れ、上流フィーチャーの隣接期待事項が要件に反映されているか
- **典型発見**：列挙値の追加忘れ、API シグネチャ抜け、フィールド整合
- **進め方**：当該フィーチャーの要件一覧 + 上流フィーチャー由来の調整要求 + 重要該当項目 + 過去セッション由来の波及項目を網羅的に列挙

##### 第 2 ラウンド：上位文書照合

- **観点**：上位文書(唯一の正本)との齟齬
- **対象**：ロードマップの制約・最小限機能・調整要件、概要書の対象範囲(含む・含まない)、設計草案の節
- **典型発見**：設計草案と要件のフィールド数や API 列挙の不一致、運用ルール継承漏れ、唯一の正本における矛盾

##### 第 3 ラウンド：本質的観点

- **観点**：異なる視点での全体俯瞰、文書内矛盾、概念定義の整合性
- **対象**：主題の一貫性、フェーズ表記、イベント・決定の網羅性、用語使用、内部参照する列挙値が固定リストに欠落していないか
- **典型発見**：内部参照する値が固定リストに欠落、概念の用法不一致、目的と受け入れ基準の乖離

##### 第 4 ラウンド：例外系(失敗モード / 並行 / セキュリティ / 観測 / 可逆性 / 規模)

- **観点**：暗黙前提が崩れたときの動作仕様
- **対象**：クラッシュ復旧、部分失敗、権限拒否、ディスク満杯、大規模時の上限到達、プライバシーモード、暗黙前提崩壊
- **典型発見**：トランザクションのクラッシュ後の清掃規定欠落、一括処理の継続・中断方針未明示、失敗時の巻き戻し範囲

##### 第 5 ラウンド：波及精査(隣接フィーチャーへの影響伝達 + 上位文書との整合 + 連鎖更新漏れ)

修正適用後に必ず実施する最終ガード。3 観点を統合的に精査する。

- **観点 (a) 隣接フィーチャーへの影響伝達**：既承認済の他フィーチャーへの波及、未承認フィーチャーへのチェックリスト追加
- **観点 (b) 上位文書との整合**：設計草案の隣接同期 TODO の特定
- **観点 (c) 連鎖更新漏れの精査**：第 1〜4 ラウンドの修正で生じた他の受け入れ基準への波及不整合(例：列挙拡張時の他参照箇所、フェーズ表の概要文、境界文脈の概要記述更新)

#### 第 5 ラウンド必須手順(5 ステップ)

修正適用後にエージェントが必ず実施する。手順を機械的に踏むことで形骸化を防ぐ。

1. **変更値リスト化**：第 1〜4 ラウンドで修正した値(数値、列挙、API 名、受け入れ基準番号、シグネチャ、必須フィールド、イベント種別、決定種別など)をすべてリスト化
2. **網羅的な検索**：各変更値について、以下の対象を検索で参照箇所を特定
   - 既承認済の他フィーチャー全件(当該フィーチャーを除く)
   - 設計草案やシナリオ集
   - 基盤フィーチャー
   - 当該フィーチャー自身の他の受け入れ基準(連鎖更新漏れ精査、境界文脈・目的・フェーズ表・変更履歴を除く本文)
3. **基盤フィーチャー改版時の下位精査必須**：基盤フィーチャーを改版した場合は下記「基盤フィーチャー改版時の下位精査ルール」を必ず実行
4. **隣接同期 TODO 整理**：文言同期が必要な箇所を隣接同期 TODO として記録(通し番号)。各 TODO は (a) 対象フィーチャー / 設計草案、(b) 修正前後の文言、(c) 同期理由を記載
5. **本セッション内同期判断**：各隣接同期 TODO について、本セッション内で同期適用するか別セッションに残すかを利用者判断する。判断材料は (a) 既承認フィーチャーか未承認フィーチャーか、(b) 文言同期レベル(再承認不要)か実質要件変更か、(c) 関連フィーチャーの現状

#### 基盤フィーチャー改版時の下位精査ルール

基盤フィーチャーを改版した場合、下位の全フィーチャーに対して影響精査を必ず実行する。基盤フィーチャーは規範文書であり、下位フィーチャーはすべて基盤フィーチャーを唯一の正本として参照しているため、基盤フィーチャーの変更は下位の全フィーチャーに潜在的影響がある。

- **必須手順**：基盤フィーチャーで改版した要件番号と内容について、下位の全フィーチャーに対して以下を実施
  - 「基盤要件 R13.5」相当の参照を検索
  - 「基盤 R13」相当の章番号参照を検索
  - 改版した内容に依存する具体的記述(例：必須フィールドの数、列挙の固定列挙)を検索
- **波及判定基準**：参照箇所があった場合、参照内容が改版前提に依存しているかを判定
  - **依存あり(波及あり)**：数値・列挙・フィールド数を直接引用 → 隣接同期必須
  - **依存なし(波及なし)**：個別ルール・運用方針への参照のみ → 隣接同期不要
- **記録**：波及あり / なしの判定結果をすべて報告(波及なしも明示記録、後で誤って見落としと判断されないため)

#### 各ラウンドの自動採択 / 利用者判断を仰ぐ判定

各ラウンドで発見した修正候補は、深掘り検討して致命的なデメリットがなければ自動採択、複数の合理的選択肢が残る場合や致命的影響がある場合は利用者判断を仰ぐ。明らかに劣る選択肢は提示しない。

#### ラウンドの所要時間と発見数の傾向

- 第 1 ラウンド：致命級・重要級が最も多く発見される
- 第 2 ラウンド：上位文書との矛盾が中心
- 第 3 ラウンド：本質的観点で致命級が初出することがある
- 第 4 ラウンド：例外系(失敗モード・並行・観測など)
- 第 5 ラウンド：連鎖更新漏れと隣接同期 TODO

#### ラウンドを跳ばさない原則

「もう致命級は出ないだろう」と感じても全 5 ラウンドを必ず実施する。第 3〜4 ラウンド以降に致命級が初出した実例があるため、ラウンド跳ばしは禁止。

### 5.2.9 設計レビューの 10 観点と進め方

設計レビューは要件レビューと観点が異なる。要件レビューは「何(WHAT)を満たすか」の宣言を検査するが、設計レビューは「どう(HOW)実現するか」の具体化を検査する。本節は設計フェーズのレビュー観点と進め方を規定する。

要件レビューの 5 ラウンド構成(節 5.2.8)を設計に流用すると、設計特有の観点(アーキテクチャ整合、性能達成手段、失敗時の処理の具体化、観測性など)が不足する。要件レビューで確定済みの内部矛盾や唯一の正本整合は、設計時には再検証コストが低いため割愛し、代わりに設計特有の観点を網羅すべきである。設計フェーズはラウンド数を要件レビューの 5 から増やし、10 観点 = 10 ラウンドとして全ラウンドを基本実施する。

#### 10 観点(基本全 10 ラウンドを網羅実施、省略しない)

1. **要件全件の網羅**：設計が要件の受け入れ基準をすべて漏れなくカバーしているか
2. **アーキテクチャ整合性**：モジュール分割、レイヤ、依存グラフが要件と整合しているか
3. **データモデル・スキーマ詳細**：要件で宣言されたフィールド・値域が実装スキーマで具体化されているか
4. **API 接合面の具体化**：シグネチャ、エラーモデル、冪等性、ページ送り
5. **アルゴリズム + 性能達成手段(統合)**：計算量・数値安定性・端境界の網羅 + 試作測定・索引・キャッシュ・並列化(アルゴリズム選択 = 性能直結のため統合)
6. **失敗モード処理 + 観測性(統合)**：巻き戻し・再実行・タイムアウトの具体的実装パターン + ログ形式・指標収集点・トレース ID・診断ダンプ(失敗観測 = 復旧設計の前提のため統合)
7. **セキュリティ・プライバシーの具体化**：入力清浄化、暗号化、ログの伏字、版管理除外
8. **依存選定**：ライブラリ、版制約、旧版継承との整合
9. **テスト戦略**：単体・統合・フィーチャー横断
10. **移行戦略**：旧版から新版への移行、台帳形式変更時の移行スクリプト

#### ラウンド構成

基本 10 ラウンド(10 観点)を網羅実施し、省略しない。フィーチャーの性質によって変わるのは「各ラウンドの深さ・検出量」であって、ラウンドそのものの有無ではない。

- 規範を多く含むフィーチャー(基盤フィーチャーなど)：全 10 ラウンドを実施、結果として観点 2〜9 で「該当なし / 軽微」が多くなる程度の差。観点を割愛するのではなく、「該当なし」を確認して次ラウンドへ進む
- 実装の重いフィーチャー：全 10 ラウンドを実施、観点 3 / 5 / 6(データモデル / アルゴリズム+性能 / 失敗+観測)が深く厚くなる
- 接合面の重いフィーチャー：全 10 ラウンドを実施、観点 4 / 9(API 接合面 / テスト戦略)が深く厚くなる

特に観点 9(テスト戦略)と観点 10(移行戦略)は実装フェーズに直結するため、規模の小さいフィーチャーでも該当なし扱いせず必ずラウンドを実施する(テスト戦略は最小でも単体・統合の境界を明示、移行戦略は旧版から継承の有無を明示)。

#### 各ラウンドの進め方

各ラウンドでは「要点提示 → 利用者判断 → 詳細抽出 → 深掘り検討と自動採択 / 利用者判断を仰ぐ判定 → 修正適用」の手順を踏む。「該当なし」確認も明示的に行い、ラウンドを跳ばさない。

**ラウンド一括処理は禁止**：「ラウンド N から M を一括して実施」「複数ラウンド分集約」「結果報告」の形は禁止。1 ラウンドにつき 1 つ以上の応答単位で個別実施し、各ラウンドで利用者判断機会を確保する。「該当なし」判定でも要点提示 → 利用者確認 → 次ラウンドという応答単位の境界を作る。詳細は memory `feedback_no_round_batching.md` を参照。

#### 要件レビューから継承する方針

- **深掘り検討と自動採択**：致命的なデメリットがなければ自動採択する。複数の合理的選択肢が残る場合は利用者判断を仰ぐ
- **明らかに劣る選択肢は提示しない**：推奨案と比較して明白に劣後する案は提示の意味がない
- **選択肢提示の方法**(memory `feedback_choice_presentation.md`)：設計時の代替案提示にも適用
- **承認なしで進めない**(memory `feedback_approval_required.md`)：設計フェーズ移行や設計書の承認も対象

#### 設計特有の追加方針

- **独立した決定記録(ADR)形式は採用しない**：機能しなかった経験がある。決定事項は設計書本文「設計決定事項」節と変更履歴に二重記録する(詳細は memory `feedback_design_decisions_record.md`)
- **性能は試作(プロトタイプ)で測定する**：機能優先、性能は実測ベース
- **失敗シナリオのウォークスルーは可能な範囲で実施**：必須ではなく、できる範囲で行う
- **フィーチャー横断の統合テスト設計は方式分け**：2 フィーチャー間のテストは呼び出し側の設計に記述する。3 フィーチャー以上で関連する場合は中心フィーチャーの設計で端から端までのフローを記述する(中心フィーチャーは利用者視点の起点となるフィーチャーで判断)
- **要件⇄設計の往復改版の判断軸**：要件の受け入れ基準として読めるかどうか、利用者対話で確定(詳細は memory `feedback_design_spec_roundtrip.md`)

### 5.2.10 フェーズ完走後のフィーチャー横断レビューパターン

複数のフィーチャーが同じフェーズ(設計、タスク、実装など)を完走したあと、フィーチャー横断で整合性を観点リストに沿ってチェックし、結果を 3 つの群に分類して構造的に整理する。各群の扱いを明確化することで、軽微な含意を取りこぼさず、フェーズ終端を確実に確立する。

各フィーチャーの各フェーズの内部レビューでは、そのフィーチャー内の整合性は確認できるが、複数のフィーチャーを横断したときの整合性(共通契約、命名、参照、修正の双方向反映など)は別途確認が必要である。各フィーチャーが独立してフェーズを進めると、横断的な軽微含意が残存しやすい。フェーズ完走時に構造的なチェックを 1 回入れることで、こうした残存を捕捉できる。

#### 整合性チェックの観点(例)

各フィーチャー内では見えていても、複数のフィーチャーを横断するときに再確認すべき観点(環境によって追加・削除する)：

- インストール場所の規約整合
- 相対パスの正規形(接頭辞の統一など)
- 命名の重複や曖昧性
- 唯一の正本の同期メカニズム
- 共通プロンプト・テンプレートの利用形
- スキルやコマンドの形式統一
- 系統別の対応(単独・複数・判定付きなど)
- 利用側拡張の仕組みの整合(追加プロパティ許容など)
- ログや成果物の追記先のパス解決
- 接続契約の 3 要素(場所規約・識別子・失敗信号)
- 上書きの階層(上位レイヤが下位レイヤを上書きする規律)
- フェーズの対象範囲制約
- 系統別のステップ構成の違い
- 種別マッピング(識別子と中身の対応)
- 重要度の水準分類の整合
- フィーチャー間の契約参照(依存関係の連鎖の深さ制限)
- 再検証の双方向反映(下流から上流への要請が上流に反映されているか)
- 分岐判定のルール(条件、進行・保留、報告書追記など)
- 利用者向け契約のメタ情報(時刻、コミットハッシュなど)
- 期限と完了基準の整合

各環境で固有の項目があるため、観点リストは適宜更新する。観点の本質は「複数のフィーチャーの整合性をチェックする」ことなので、対象環境に合わせてカスタマイズしてよい。

#### 3 群分類

チェック結果を以下の 3 群に分類する。

- **A 群：確認済整合**：各フィーチャー内で既に確定済み、複数のフィーチャーを横断しても整合 → 何もしない
- **B 群：既存対応済**：前フェーズの横断レビューや各フィーチャーのフェーズ内修正で既に対応済 → 何もしない(記録のみ)
- **C 群：新規含意**：今回の横断レビューで初めて顕在化した含意 → 各フィーチャーに軽微な追記で対応
- **不整合**：受け入れ基準の違反や実装不可能性 → フェーズ改訂や再レビュー(進行を止める)

通常は A 群と B 群が大部分を占め、C 群は少数、不整合 0 件で完走する。

#### C 群の対応規律

- 各含意は修正コストが低い(1 段落から数行の追記)レベルであること
- 修正対象は各フィーチャーの既存文書(新規フィーチャーの作成は不要、既存文書に追記)
- 利用者判断は 3 択(全採用 / 個別レビュー / A 群と B 群のみ確認して C 群は次回送り)

#### 横断レビューの実施時期

- 複数のフィーチャーが同じフェーズを累計完走したとき(例：最後のフィーチャーのフェーズ承認直前)
- 要件フェーズ完走時の横断レビュー(要件レビューの第 5 ラウンドが該当)
- 全フェーズ完走後の最終整合性チェック時

#### 経験から得られたパターン

- 設計フェーズの横断レビューでは、A 群・B 群が中程度、C 群は少数(数件レベル)
- タスクフェーズの横断レビューでは、A 群が大幅に増え、C 群はさらに少数(版固定の同期など軽微なもの)
- 両フェーズとも不整合 0 件で完走する場合、パターンとして安定している

各フェーズで横断レビューを実施することで、各フィーチャーの独立な進行と、横断的な整合性の両立を確保する。

### 5.3 implementation フェーズ

この workflow でいう `implementation` は、通常どおり
**approved tasks に基づいて実際にコードを書く execution phase**
を指す。

`ready_for_implementation` の意味もここで固定する。

- `ready_for_implementation = true` は
  `approved tasks に基づいて coding を開始してよい`
  を意味する
- これは
  `implementation source tree complete`
  を意味しない
- tasks gate approval を通過した時点で true にしてよい
- review acquisition の可否とは別に扱う

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

### 5.4 optional review acquisition extension

reverse-engineered case や clean-room case では、coding そのものとは別に
**review acquisition**
を tasks approval 後に差し込むことがある。

この extension を使うときは、
`review acquisition gate package`
を 1 回作成する。

この package は少なくとも次の 2 artifact からなる。

1. `review acquisition preparation`
2. `review acquisition gate summary`

#### review acquisition preparation

これは human `review acquisition gate` 前に、

- review target statement
- approved upstream spec set
- implementation snapshot / review acquisition boundary
- implementation order / shared artifact owner
- validation / conformance entrypoint

を固定するための memo である。

ルール:

- source of truth は approved `requirements / design / tasks`, implementation snapshot ref, workflow gate status とする
- preparation memo はそれらの固定と参照に徹し、新しい要件を暗黙追加してはならない
- multi-feature case では、shared file owner と implementation order を preparation で再確認する
- clean-room case では、除外すべき implementation source を preparation で明示する
- implementation protocol と snapshot boundary は、原則として次の template から起こす
  - [implementation-phase-protocol-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-phase-protocol-template.md:1)
  - [implementation-phase-snapshot-template.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/implementation-phase-snapshot-template.md:1)

#### review acquisition gate summary

これは `phase evidence summary` と同様の derived artifact であり、
human `review acquisition gate` の入口とする。

最低限含めるもの:

- target / case id
- review acquisition preparation ref
- implementation snapshot ref
- upstream approved spec refs
- fixed boundary statement
- implementation-order statement
- gate readiness statement

ルール:

- source of truth は review acquisition preparation, approved spec refs, workflow gate status とする
- summary と source artifact が衝突した場合は source artifact を優先する
- review acquisition gate request は、原則としてこの summary を入口に行う

この extension を使う case では、追加 state として次を使ってよい。

- `approvals.review_acquisition.generated`
- `approvals.review_acquisition.approved`
- `ready_for_review_acquisition`

意味は次である。

- `ready_for_review_acquisition = true` は
  `review acquisition boundary is ready`
  を意味する
- これは coding readiness と別物である
- approved tasks と review acquisition gate package が揃った時点で true にする

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
- `requirements` / `design` / `tasks` は意図駆動ワークフロー gate、人間承認、Codex 具体化
- `implementation` は Codex 主導、人間 review
- `evaluation` と `self-improvement` は Codex が分析し、人間が採否を持つ

## 9. 逸脱防止ルール

以下が起きた場合、workflow 逸脱とみなす。

- requirements / design / tasks を飛ばして implementation に進む
- 遡上修正後に対応する alignment gate を再実施せず前進する
- multi-feature なのに phase 終端の alignment gate を飛ばして次 phase に進む
- `requirements / design / tasks` gate を phase evidence summary または同等の gate package なしで人間へ回す
- Codex が approval 済みとみなして進む
- 旧 repo の暫定判断を新 repo の正本として扱う
- review output unit と human decision unit がずれる
- invalid run を明示せずに次工程へ流す

## 10. この文書の完成条件

本書は、少なくとも以下を満たすときに有効とみなす。

- 人間、Codex、意図駆動ワークフローの役割分担を一読で説明できる
- 旧 repo と新 repo の使い分けが明確である
- phase approval の責任が曖昧でない
