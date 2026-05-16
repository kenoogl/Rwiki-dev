# dual-reviewer-implementation-governance design 個別レビュー

## 取得メタデータ

- 実施日：2026-05-16
- 対象：`dual-reviewer-implementation-governance/design.md`（要件承認後の差分追従済み）
- 契約入力：`dual-reviewer-implementation-governance/requirements.md`（承認済み）、上流 `foundation/requirements.md`
- 方式：claude --print --disallowedTools "Read,Write,Edit"（ファイルアクセス技術的遮断）
- 主役：claude-sonnet-4-6 / 敵対役：claude-opus-4-7 / 判断役：claude-opus-4-6
- 通信構造：β 逐次方式（主役 → 敵対役 → 判断役）
- 手順：REVIEW_PROTOCOL.md 節 3（設計レビュー 10 観点）

---

## 主役発見（claude-sonnet-4-6）

10 観点を順に精査する。

---

## ラウンド 1：要件全件の網羅

**P-1 ERROR** — 要件 1 受入 3（適用タイミング列挙）の欠落
- 対象箇所：設計「Stage 3: Implementation Conformance Review」節
- 説明：要件は「プロトタイプ完了時・pre-push／pre-PR チェックポイント・trust boundary／無効化／provenance／承認採用ロジック変更後」という 3 種のトリガー条件を明文化するよう要求している。設計のワークフローモデルは「Smoke → Conformance → Close」という線形フローを示すだけで、変更起因のトリガー（trust boundary 変更時にも conformance review を走らせる）への言及がない。
- 根拠：requirements.md Req 1 AC3

**P-2 ERROR** — 要件 2 受入 2（"reviewed commit or branch" フィールド）の欠落
- 対象箇所：設計「Stage 3」の reviewer 活動一覧および「Finding Model」フィールド定義
- 説明：要件は review artifact の最小コンテンツセットとして「reviewed commit or branch」を明示列挙している。設計の Stage 3 活動リストにも Finding Model のフィールド定義にも、この項目が存在しない。コミット識別子がなければ再現性検証の前提が崩れる。
- 根拠：requirements.md Req 2 AC2

**P-3 ERROR** — 要件 3 受入 3（各メトリクスの意味・収集タイミング・解釈）の欠落
- 対象箇所：設計「Metric Model」節
- 説明：要件は各メトリクスについて「意味・収集タイミング・解釈」の 3 点を定義するよう要求している。設計はメトリクス名の箇条書きと簡単な説明を載せるだけで、いずれのメトリクスにも収集タイミング（例：recheck 後か close 前か）と解釈基準（例：スコア閾値や "良好" の定義）が定義されていない。
- 根拠：requirements.md Req 3 AC3

**P-4 WARN** — 要件 5 受入 4（具体的 review artifact の指定）が glob 参照のみ
- 対象箇所：設計「Owned Artifacts」の `docs/reviews/*.md`
- 説明：要件はバリデーターを通過できる「少なくとも 1 件の具体的 review artifact」を要求している。設計はグロブパターン `docs/reviews/*.md` でカバーするとしているが、固有のファイル名が挙げられていない。バリデーター実装時にどのファイルを "具体例" として使うかが設計から読み取れず、実装者が裁量で選ぶ余地が生じる。
- 根拠：requirements.md Req 5 AC4

---

## ラウンド 2：アーキテクチャ整合性

**P-5 WARN** — Mermaid ダイアグラムにステージ -1 と ステージ 0 が欠落
- 対象箇所：設計「Architecture」節のフロー図
- 説明：設計は「Stage -1: Reference-Free Case Bootstrap」と「Stage 0: Intent Review」を独立した workflow stage として定義しているが、Architecture 節の Mermaid ダイアグラムはこれらを省略し `Tasks → Smoke → Conformance → Close` しか示していない。図を見ただけでは governance workflow の全体像が把握できず、upstream stage の位置づけが不明確になる。cross-spec alignment memo や workflow-gate-status artifact もダイアグラムに現れていない。
- 根拠：requirements.md Req 7 AC1、Req 6 AC2

---

## ラウンド 3：データモデル・スキーマ詳細

**P-6 WARN** — 上位基盤の `finding` スキーマとガバナンス独自 Finding Model の関係が未定義
- 対象箇所：設計「Finding Model」節
- 説明：foundation requirements は `finding` スキーマに「source attribution・severity・counter-evidence linkage・judgment linkage・human decision linkage」フィールドを要求している。governance の Finding Model は「scope・file reference・description・impact・recommended action・handback assessment・status」という別フィールドセットを持つ。両者が別物である合理的な理由があるとしても（対象が conformance finding vs runtime finding）、設計がその区別を明示していないため、後続実装者が foundation スキーマを誤適用するリスクがある。
- 根拠：foundation requirements.md Req 3 AC5、governance design「Finding Model」

**P-7 WARN** — ガバナンス成果物の内部スキーマが未定義
- 対象箇所：`docs/coordination/workflow-gate-status.md`、`implementation-conformance-metric-register.md`、`phase-review-metric-register.md` の各 owned artifact
- 説明：これらのファイルが存在すること・目的は定義されているが、各ファイルが持つべきフィールドの構造（必須フィールド・型・フォーマット）は設計に記載がない。バリデーター（Req 5 AC3）が「required section と metric key の存在を確認する」と定義されているにもかかわらず、確認対象のキーが設計から特定できない。
- 根拠：requirements.md Req 5 AC3、Req 3 AC1

---

## ラウンド 4：API 接合面の具体化

**P-8 ERROR** — 要件 4 受入 1（finding → signal register マッピングルール）が未定義
- 対象箇所：設計「Stage 3」の「signal / coordination への接続」、Architecture ダイアグラム
- 説明：要件は conformance finding が `implementation-signal-register` にどう反映されるかを定義するよう求めている。設計は「signal / coordination への接続」と矢印を示すだけで、どのフィールドが何のキーに対応するか、どの条件の finding が signal register に起票されるかが記述されていない。この粒度では実装者が接続ルールを独自に解釈してしまう。
- 根拠：requirements.md Req 4 AC1

---

## ラウンド 5：アルゴリズム＋性能達成手段

**P-9 ERROR** — `severity_weighted_finding_score` の計算式が未定義
- 対象箇所：設計「Metric Model」の `severity_weighted_finding_score`
- 説明：このメトリクスは "重み付き" であることを名称で主張しているが、P1・P2・P3 それぞれの重みが設計のどこにも書かれていない。複数の reviewer が異なる重みで計算すれば同一 conformance 状態で異なるスコアが出る。Req 3 AC3 が求める「解釈」を与えるには計算式の定義が前提となる。
- 根拠：requirements.md Req 3 AC2、AC3

---

## ラウンド 6：失敗モード処理＋観測性

**P-10 WARN** — P1 所見残存時の次フィーチャー開始ブロック機構が宣言のみ
- 対象箇所：設計「Stage 4: Checkpoint Close」節
- 説明：設計は「P1 が open の場合は次フィーチャー開始前修正の対象」と述べているが、このブロックを実際に機能させる仕組み（workflow-gate-status.md の状態確認手順、validator によるゲートチェック、誰が確認するかの手順）が設計に存在しない。宣言だけでは P1 所見が暗黙のまま次フィーチャーに持ち越されるリスクを防げない。
- 根拠：requirements.md Req 1 AC4、Req 6 AC3

---

## ラウンド 7：セキュリティ・プライバシー

**該当なし（確認済み）** — 本 spec は review 手順と evidence contract を扱う内部ガバナンス仕様であり、外部入力処理・個人情報・認証・アクセス制御のいずれも適用範囲外である。機密性の高い所見（例：セキュリティ脆弱性の conformance finding）を隔離配置する運用ルールは human reviewer assignment policy として明示的に Out of scope とされており、本観点では指摘事項なし。

---

## ラウンド 8：依存選定

**P-11 WARN** — スクリプト言語として Ruby を採用した根拠が設計に記載なし
- 対象箇所：`scripts/validate_implementation_governance_artifacts.rb`、`scripts/bootstrap_reference_free_case.rb`
- 説明：設計は両スクリプトを `.rb` 拡張子で列挙しているが、Ruby を選択した理由（リポジトリ内の他スクリプトと揃えるため、既存 Gemfile があるため等）が記述されていない。リポジトリの主要言語や CI 環境に Ruby がなければ実装・保守コストが跳ね上がる。スクリプトの入力・出力・終了コードのインターフェース定義も欠落しており、呼び出し側が何を期待すべきかが不明。
- 根拠：requirements.md Req 5 AC1、Req 8 AC2

---

## ラウンド 9：テスト戦略

**P-12 WARN** — バリデータースクリプト自身のテスト戦略が未定義
- 対象箇所：設計「Validation Model」節
- 説明：Req 5 AC4 は「バリデーターを通過できる具体的 review artifact を少なくとも 1 件提供する」ことを求めているが、これはバリデーターの受け入れ確認に相当する。設計はバリデーターが "artifact completeness と structure のみを担う" と述べるが、バリデーター自身の単体テストや誤検知防止の戦略がない。バリデーターにバグがあった場合に形式的合格が偽陰性を生む点について設計は言及していない。
- 根拠：requirements.md Req 5 AC4

---

## ラウンド 10：移行戦略

**P-13 WARN** — 既存進行中ケースへのガバナンス適用（移行）戦略が未定義
- 対象箇所：設計全体、特に「Stage -1: Reference-Free Case Bootstrap」節
- 説明：設計は新規ケース向けの reference-free bootstrap path を定義しているが、governance spec 導入時点で既に prototype 段階や smoke 完了段階にある既存ケースに対して conformance review を後付けする手順が示されていない。既存ケースを `completed_with_open_findings` として登録するのか、`reopen_required` に戻すのか、あるいは適用免除とするのかの方針がなければ、workflow-gate-status.md を整合させる際に混乱が生じる。
- 根拠：requirements.md Req 6 AC2（ゲートステータス成果物）、Req 1 AC1（review stage の必須化）

---

## 観点別発見要約

- **観点 1（要件網羅）**：P-1・P-2・P-3（3 件 ERROR）・P-4（1 件 WARN）。trigger 条件、artifact フィールド、メトリクス定義の 3 か所で要件の AC を設計が拾いきれていない。
- **観点 2（アーキテクチャ整合性）**：P-5（1 件 WARN）。Mermaid 図が workflow の前半ステージを省略しており、全体構造の誤読を招く。
- **観点 3（データモデル・スキーマ）**：P-6・P-7（2 件 WARN）。foundation finding スキーマとの関係不明、governance 成果物の内部スキーマ未定義。
- **観点 4（API 接合面）**：P-8（1 件 ERROR）。signal register へのマッピング規則が欠落。
- **観点 5（アルゴリズム・性能）**：P-9（1 件 ERROR）。重み付きスコアの計算式未定義。
- **観点 6（失敗モード・観測性）**：P-10（1 件 WARN）。P1 ブロック機構が宣言のみ。
- **観点 7（セキュリティ・プライバシー）**：該当なし。
- **観点 8（依存選定）**：P-11（1 件 WARN）。Ruby 採用根拠・スクリプトインターフェースが未記載。
- **観点 9（テスト戦略）**：P-12（1 件 WARN）。バリデーター自身のテスト計画なし。
- **観点 10（移行戦略）**：P-13（1 件 WARN）。既存ケースへの governance 後付け手順なし。

| 重大さ | 件数 |
|---|---|
| ERROR | 5 件（P-1 / P-2 / P-3 / P-8 / P-9） |
| WARN | 8 件（P-4 / P-5 / P-6 / P-7 / P-10 / P-11 / P-12 / P-13） |
| INFO | 0 件 |

---

## 敵対役レビュー（claude-opus-4-7）

敵対役として、主役の発見 13 件への反論可否と、主役が見落とした独立発見を提示する。出力は表を使わず箇条書きで記す（プロジェクト規約により表形式禁止）。

# パート1：主役の各発見への反論

- **P-1（要件1受入3：適用タイミング列挙の欠落／ERROR）：反論あり（部分的）**
  - ワークフローモデルの段階1→3の並びが「プロトタイプ完了時に走らせる」契機を暗黙に含むため、3 種のうち 1 種は線形フローで読み取れる。ただし「pre-push／pre-PR チェックポイント」および「trust boundary（信頼境界。外部入力と内部処理の切れ目）／無効化／provenance（来歴。証跡がどのリポジトリのどの版から来たか）／承認採用ロジック変更後」という変更起因トリガーは設計のどこにも書かれていないため、ERROR の核心は維持される。深刻度は妥当だが指摘範囲を「変更起因トリガーと事前チェックポイントの 2 種に限定」と精緻化すべきである。

- **P-2（要件2受入2：reviewed commit or branch フィールド欠落／ERROR）：反論あり（部分的）**
  - 要件 2 受入 2 は「フィーチャーが最小コンテンツセットを定義する」ことを求めており、設計はその定義先を所有成果物である再利用テンプレート（`implementation-conformance-review-template.md`）へ委譲している、と読む余地がある。設計本文がフィールドを列挙していないこと自体は委譲設計として許容され得る。ただし設計はテンプレートが当該フィールドを必須化すると一言も明記していないため、委譲の宣言が欠けている点で不備は残る。深刻度は ERROR から WARN へ引き下げるのが妥当である。

- **P-3（要件3受入3：各メトリクスの意味・タイミング・解釈の欠落／ERROR）：反論あり（部分的）**
  - P-2 と同じ委譲構造である。意味・収集タイミング・解釈はメトリクスレジスタ成果物（`implementation-conformance-metric-register.md`、用途は「metric definitions」と明記）の責務であり、設計本文に全件を書く必要はないと反論できる。ただしレジスタが「タイミングと解釈」まで含むという接続宣言が設計に欠けるため不備自体は残る。深刻度 ERROR は過大で WARN 相当。

- **P-4（要件5受入4：具体的 review artifact がグロブ参照のみ／WARN）：反論あり（部分的）**
  - 固有ファイル名の決定はタスクフェーズの実装詳細であり、設計フェーズで具体ファイル名を欠くこと自体は設計粒度として許容される。設計上の本質的不備は「バリデーターが要求する必須セクション契約が未定義（P-7 と同根）」であって、ファイル名の不在ではない。本指摘は INFO へ引き下げるべきである。

- **P-5（Mermaid 図に Stage -1／Stage 0 欠落／WARN）：反論あり（部分的）**
  - Architecture 節は「governance はフィーチャー論理グラフに新規データ生産者を追加せず、実装チェックポイントへ後段ゲートを足すだけ」と明言しており、図はその後段ゲートのみへ意図的にスコープを絞っている。よって「アーキテクチャ不整合」ではなく図の網羅性に関する注記にとどまる。ただし図のルートが「Tasks implementation」であり、ワークフローモデルが定義する段階1（Implementation）の前段（bootstrap・intent review）と読者の理解を食い違わせる余地があるため、相互参照注記の追加要求は妥当。深刻度据え置きで指摘の性質を「不整合」から「図の網羅性」へ修正すべきである。

- **P-6（foundation の finding スキーマと governance Finding Model の関係未定義／WARN）：反論あり（部分的）**
  - 設計の Boundary Clarification 節は「foundation 等＝レビュー対象」「governance＝レビュー手順と証跡契約の所有者」と役割を分離しており、conformance finding（適合性所見）と runtime の `finding` スキーマが別ドメインであることは構造的に示唆されている。完全な未定義ではない。ただし両者が別フィールドセットを持つ理由の明示文が欠けるため、誤適用リスクの指摘自体は維持。WARN は妥当。

- **P-7（governance 成果物の内部スキーマ未定義／WARN）：反論あり（部分的）**
  - メトリクスレジスタのキーは Metric Model に 8 件（`conformance_findings_count` 等）が列挙済みで、バリデーターの「metric key 確認」対象は部分的に定義されている。よって指摘は `workflow-gate-status.md` の内部スキーマと review artifact の「required section」構造に範囲を絞るべきである。範囲限定の上で不備は維持。

- **P-8（要件4受入1：finding→signal register マッピング未定義／ERROR）：反論あり（部分的）**
  - 設計の Handback Model が A／B／C／D の 4 段（task-local／design／requirements／intent への差し戻し）を定義しており、これが finding を signal/coordination へ流す媒体になっている。完全な未定義ではない。ただし signal register の具体フィールド対応（どの finding 属性がどのキーに入るか）は欠落しており、要件 4 受入 1 の核心は未充足。深刻度 ERROR と WARN の境界だが、媒体が存在する分 WARN 寄り。

- **P-9（severity_weighted_finding_score の計算式未定義／ERROR）：反論あり（部分的）**
  - 重み定義はメトリクスレジスタ成果物の責務であり、かつ要件 3 受入 4 がプロトタイプ段階の manual snapshot（手作業での値記録）を許容しているため、設計本文に計算式を固定しない選択は要件に反しない。ただしレジスタが重みを定義するという接続宣言が欠ける点で不備は残る。深刻度 ERROR は過大で WARN 相当。

- **P-10（P1 ブロック機構が宣言のみ／WARN）：反論あり（部分的）**
  - Workflow Status Model が `completed_with_open_findings` と `reopen_required` の状態を持ち、`workflow-gate-status.md` がその状態を記録し、バリデーターが当該成果物の存在を確認する、という骨組みは存在する。完全な宣言のみではない。ただし「P1 open → どの状態 → 次フィーチャー開始をブロック」という規則の接続が欠けるため指摘は維持。WARN 妥当。

- **P-11（Ruby 採用根拠とスクリプトインターフェース未記載／WARN）：反論あり（部分的）**
  - 言語選定根拠を内部 governance バリデーターに求めるのは設計粒度として過剰である。リポジトリ既存スクリプトとの一貫性で `.rb` を選ぶのは合理的で、設計が言語選定を正当化する義務はない。よって「Ruby 採用根拠」の指摘は棄却が妥当。一方、検証エントリポイント（要件 5 受入 1）の入出力・終了コード契約（成果物欠落時に非ゼロ終了するか等）の欠落は正当な指摘であり、こちらに限定して維持すべきである。

- **P-12（バリデーター自身のテスト戦略未定義／WARN）：反論あり（大筋で棄却）**
  - これは要件契約からの逸脱要求である。要件 5 は検証エントリポイントと「通過する具体的 artifact を 1 件」を求めるのみで、バリデーターのメタテスト（バリデーター自体の単体試験や偽陰性防止戦略）はどの受入基準も要求していない。要件 5 受入 4 の「通過する具体 artifact 1 件」が事実上の正例フィクスチャ（正常系の検証用固定データ）として機能しており、これ以上を設計不備として挙げるのは scope 拡大である。負例フィクスチャ追加は INFO 級の改善提案にとどまり、設計欠陥として計上すべきでない。

- **P-13（既存進行中ケースへの移行戦略未定義／WARN）：反論あり（部分的）**
  - Workflow Status Model の状態語彙、Reopen Propagation Model、cross-spec alignment memo、`workflow-gate-status.md` が、既存ケースの状態を記録・整合させる受け皿として既に存在する。完全な未定義ではない。ただし「すでに smoke 完了済みのケースを免除とするか reopen に戻すか」の後付け判定規則そのものは欠けるため、指摘は「受け皿はあるが retrofit 判定規則が無い」と精緻化した上で維持。WARN 妥当。

# パート2：主役が見落とした独立発見

- **A-1：レビューテンプレートの必須セクション契約とドリフト防止機構が未定義**
  - 対象：`docs/reviews/templates/intent-review-template.md` および `implementation-conformance-review-template.md`、Validation Model 節
  - 説明：設計はテンプレートを所有成果物として列挙するが、各テンプレートが強制すべき必須セクションの中身を一切定義していない。要件 2 受入 5 はテンプレートの目的を「後続レビューが構造的にドリフト（記載構造が回ごとにばらつくこと）しないため」と明示しており、ドリフト防止は必須セクションの固定なしには成立しない。主役の P-7 はメトリクスレジスタとゲート状態に範囲を絞っており、テンプレート側のセクション契約とドリフト防止という別目的の欠落を取りこぼしている。
  - 根拠：requirements.md Req 2 AC5、Req 7 AC2、Req 5 AC3
  - 重大さ：ERROR

- **A-2：heuristic テンプレートの「所有成果物列挙」と「v2-acquisition 所有・必須検査しない」の内部矛盾**
  - 対象：Owned Artifacts の `experiments/protocols/heuristic_profiles/README.md` と `*/_minimal_template.yaml`、Minimal Heuristic Default Rule 節
  - 説明：設計はこれら heuristic（経験則）テンプレートを governance の「所有成果物」として列挙する一方、同じ設計内で「heuristic default 挙動と minimal template 語彙の canonical owner は v2-acquisition spec であり、governance バリデーターはこれら実体を必須検査しない」と述べる。所有成果物として列挙しながら語彙所有権を他 spec に譲り必須検査もしないという二重の立場が、ファイル配置の所有と内容語彙の所有の境界を曖昧にしている。設計はこの矛盾を調停していない。
  - 根拠：requirements.md Req 8 AC6、Req 8 AC5
  - 重大さ：WARN

- **A-3：バリデーターが artifact 種別を判別する仕組みが未定義**
  - 対象：Validation Model 節、Owned Artifacts の `docs/reviews/*.md`
  - 説明：intent review artifact と conformance review artifact が同一ディレクトリにグロブ `docs/reviews/*.md` で同居する設計でありながら、バリデーターがどのファイルにどのスキーマ（必須セクション集合）を適用すべきかを判別する手段（ファイル名規約、front-matter の type フィールド等）が定義されていない。要件 5 受入 3 は「conformance review artifact が最小必須セクションとメトリクスキーを含むことを確認する」と種別固有の検査を要求しており、種別判別器がなければバリデーターは実装不能である。主役の P-7 はキー未列挙を指摘するが、種別ルーティング機構の不在は別の API／検証接合面の欠落である。
  - 根拠：requirements.md Req 5 AC3、Req 7 AC6
  - 重大さ：ERROR

- **A-4：Handback Model と Reopen Propagation Model の intent 差し戻し範囲が三者不一致**
  - 対象：Handback Model 節、Reopen Propagation Model 節、requirements.md Req 6 AC5
  - 説明：Handback Model は `D`（intent 差し戻し）が「少なくとも intent → requirements → design → tasks の連鎖 reopen を引き起こす」とし `implementation` を含めない。一方 Reopen Propagation Model は intent 修正が「requirements、design、tasks、必要なら implementation」を reopen 対象にすると条件付きで implementation を含める。さらに要件 6 受入 5 は intent 変更が「requirements、design、tasks チェックポイント」を無効化し得るとし implementation を挙げない。設計内の 2 モデルと要件 1 件で intent 差し戻しの到達範囲（implementation を含むか、含むなら必須か条件付きか）が三者不一致のまま放置されている。
  - 根拠：requirements.md Req 4 AC2、Req 6 AC5、Req 1 AC4
  - 重大さ：WARN

- **A-5：rate 系メトリクスの母数と無効 run 除外との相互作用が未定義**
  - 対象：Metric Model の `review_artifact_presence_rate` と `finding_to_signal_link_rate`
  - 説明：両メトリクスは「率（rate）」を名乗るが分母となる母集団（チェックポイント単位か、フィーチャー単位か、有効 run のみか）が定義されていない。foundation 要件 6 受入 5 は下流評価が「メタデータのみで無効 run を除外する」ことを支援すると規定しており、率の母数に無効 run を含めるか除外するかで同一適合状態でも値が変わる。主役の P-9 は `severity_weighted_finding_score` の重みのみを扱い、率メトリクスの母数定義および無効 run 除外との上流契約相互作用という別の未定義点を取りこぼしている。
  - 根拠：requirements.md Req 3 AC2、Req 3 AC3、foundation requirements.md Req 6 AC5
  - 重大さ：WARN

---

総括として、主役の 13 件のうち、P-12 は要件契約外の要求であり設計欠陥として棄却が妥当、P-11 は半分（言語選定根拠）が過剰要求である。P-2／P-3／P-9 は委譲構造を見落としており深刻度 ERROR→WARN の引き下げが妥当である。一方、設計内部の三者不一致（A-4）と所有権の二重立場（A-2）、バリデーター種別判別器の不在（A-3）、テンプレートのドリフト防止契約欠落（A-1）は主役が捕捉できていない独立の重大論点である。

---

## 判断役レビュー（claude-opus-4-6）

# 判断役：最終判定

主役の発見 13 件と敵対役の反論・独立発見 5 件について、個別に判定根拠とともに裁定する。

---

## 主役発見への判定

### P-1（要件1受入3：変更起因トリガーの欠落）

- **判定：must-fix**
- 敵対役反論の採否：**部分採用**。線形フローが「プロトタイプ完了時」を暗黙に含む点は認める。ただし「pre-push／pre-PR」と「trust boundary 等の変更後」の 2 種は設計に痕跡すらなく、要件が明示列挙を求めている以上これは設計欠陥。指摘範囲を「変更起因トリガー＋事前チェックポイントの 2 種」に精緻化した上で ERROR 維持。

### P-2（要件2受入2：reviewed commit/branch フィールド欠落）

- **判定：should-fix**
- 敵対役反論の採否：**採用**。テンプレート成果物への委譲は設計構造として妥当。ただし設計本文に「テンプレートが当該フィールドを必須化する」という委譲宣言が欠けている点は不備。深刻度を WARN へ引き下げ、修正内容は委譲宣言の追加に限定。

### P-3（要件3受入3：メトリクスの意味・タイミング・解釈の欠落）

- **判定：should-fix**
- 敵対役反論の採否：**採用**。メトリクスレジスタ成果物の用途が「metric definitions」と明記されており、詳細定義をそこに委譲する構造は合理的。設計本文に「レジスタがタイミングと解釈を含む」と接続を宣言すれば足りる。深刻度を WARN へ引き下げ。

### P-4（要件5受入4：具体的 review artifact がグロブ参照のみ）

- **判定：leave-as-is**
- 敵対役反論の採否：**採用**。具体ファイル名の決定はタスクフェーズの責務であり、設計フェーズで欠くこと自体は粒度として許容される。本質的不備は P-7 および A-1 が正しく捕捉している。

### P-5（Mermaid 図に Stage -1／Stage 0 欠落）

- **判定：leave-as-is**
- 敵対役反論の採否：**採用**。Architecture 節は「後段ゲートを追加するだけ」と明言しており、図のスコープ限定は意図的。アーキテクチャ不整合ではなく図の網羅性の注記にとどまり、設計修正は不要。

### P-6（foundation finding スキーマと governance Finding Model の関係未定義）

- **判定：should-fix**
- 敵対役反論の採否：**部分採用**。Boundary Clarification が構造的分離を示唆する点は認める。ただし「conformance finding は foundation の `finding` スキーマとは別ドメインである」旨の明示一文が欠ける以上、後続実装者の誤適用リスクは残る。一文追加で解消できる軽微な修正。

### P-7（governance 成果物の内部スキーマ未定義）

- **判定：should-fix**
- 敵対役反論の採否：**部分採用**。メトリクスキーは 8 件列挙済みであり、指摘範囲を `workflow-gate-status.md` の状態フィールド構造と review artifact の必須セクション定義に絞る。

### P-8（要件4受入1：finding → signal register マッピング未定義）

- **判定：must-fix**
- 敵対役反論の採否：**部分採用**。Handback Model（A/B/C/D）が分類媒体として存在する点は認める。しかし Handback Model は差し戻し先の分類であり、signal register のどのフィールドに何を書くかというマッピング規則とは別物。finding 属性とレジスタキーの対応が欠落している限り実装者の独自解釈を防げない。ERROR 維持。

### P-9（severity_weighted_finding_score の計算式未定義）

- **判定：should-fix**
- 敵対役反論の採否：**採用**。要件が manual snapshot を許容し、メトリクスレジスタが「metric definitions」を担う成果物である以上、計算式の本体はレジスタに置くのが妥当。ただし「P1/P2/P3 の重み定義はレジスタが所有する」という接続宣言を設計本文に追加する必要がある。深刻度を WARN へ引き下げ。

### P-10（P1 ブロック機構が宣言のみ）

- **判定：should-fix**
- 敵対役反論の採否：**部分採用**。状態モデル・workflow-gate-status・バリデーターという骨組みは存在する。しかし「P1 open → `reopen_required` 状態 → 次フィーチャー開始前に解消義務」という接続規則が明示されていない。接続規則を追加すれば骨組みで十分機能する。

### P-11（Ruby 採用根拠とスクリプトインターフェース未記載）

- **判定：should-fix（範囲限定）**
- 敵対役反論の採否：**採用**。言語選定の正当化は設計義務として過剰であり、この部分は棄却。一方、検証エントリポイントの入出力契約（引数・出力形式・終了コードの意味）が欠落している点は正当な指摘。修正範囲をスクリプトインターフェース定義のみに限定。

### P-12（バリデーター自身のテスト戦略未定義）

- **判定：leave-as-is**
- 敵対役反論の採否：**採用（棄却判定を支持）**。要件はバリデーターのメタテストを要求していない。受入 4 の「通過する具体 artifact 1 件」が正例フィクスチャとして機能しており、それ以上の要求は要件契約外のスコープ拡大。

### P-13（既存進行中ケースへの移行戦略未定義）

- **判定：should-fix**
- 敵対役反論の採否：**部分採用**。状態モデルと Reopen Propagation が受け皿として存在する点は認める。ただし「governance 導入時点で既に smoke 完了済みのケースをどの状態に分類し、conformance review を後付けするか免除するか」の判定規則が欠落している。retrofit 判定規則の追加が必要。

---

## 敵対役独立発見への判定

### A-1（テンプレート必須セクション契約とドリフト防止機構の未定義）

- **判定：must-fix**
- 判断根拠：要件 2 受入 5 はテンプレートの目的を「後続レビューの構造的ドリフト防止」と明示している。テンプレートがどのセクションを必須とするかが設計に定義されなければ、テンプレートは単なる参考例に堕し、要件の意図を達成できない。バリデーター（要件 5 受入 3）が「必須セクション存在確認」を行う以上、確認対象のセクション名は設計段階で確定している必要がある。P-7 とは対象（メトリクスキー vs テンプレートセクション）が異なる独立の欠落。

### A-2（heuristic テンプレートの所有権二重立場）

- **判定：should-fix**
- 判断根拠：Owned Artifacts 一覧に列挙しつつ「語彙と挙動の所有者は v2-acquisition」「必須検査しない」と記すのは読者を混乱させる。解消方法は単純で、Owned Artifacts 欄に「配置のみ governance 所有、内容語彙は v2-acquisition 所有」と注記するか、一覧から外して「参照成果物」として別記する。

### A-3（バリデーターの artifact 種別判別機構の不在）

- **判定：must-fix**
- 判断根拠：intent review artifact と conformance review artifact が `docs/reviews/*.md` に同居する設計で、バリデーターが種別固有の必須セクション検査を行うには判別器（ファイル名規約・front-matter の type フィールド等）が不可欠。これがなければ要件 5 受入 3 の「conformance review artifact に最小必須セクションが含まれることを確認する」という検査自体が実装不能になる。P-7 とは「何を確認するか」ではなく「どのファイルに対して確認するかの判別」という観点で別問題。

### A-4（Handback Model と Reopen Propagation Model の intent 差し戻し範囲の三者不一致）

- **判定：should-fix**
- 判断根拠：Handback Model が「少なくとも intent → requirements → design → tasks」、Reopen Propagation が「requirements, design, tasks, 必要なら implementation」。両方とも「最低限」を示すが implementation の扱いが揺れている。要件 6 受入 5 が implementation を挙げていないことを踏まえれば、設計内の 2 モデルを要件に合わせて揃え、implementation への波及は任意条件であることを両方で統一表記すればよい。

### A-5（rate 系メトリクスの母数と無効 run 除外の相互作用未定義）

- **判定：should-fix**
- 判断根拠：`review_artifact_presence_rate` と `finding_to_signal_link_rate` は率を名乗る以上、分母の定義がなければ計測不能。foundation の evidence-class 語彙（valid/invalid/exploratory）との相互作用を考えると、母数から invalid run を除外するか否かで値が変わる。P-9（重み未定義）とは別軸の問題であり、メトリクスレジスタへの委譲宣言に「母数定義を含む」と明記する修正が必要。

---

## 集計

- **must-fix：4 件**（P-1, P-8, A-1, A-3）
- **should-fix：11 件**（P-2, P-3, P-6, P-7, P-9, P-10, P-11〔範囲限定〕, P-13, A-2, A-4, A-5）
- **leave-as-is：3 件**（P-4, P-5, P-12）

---

## must-fix の帰属別分類

**全 4 件とも `dual-reviewer-implementation-governance` 設計固有の修正**

- P-1：変更起因トリガーと事前チェックポイントのワークフロー stage 記述追加
- P-8：finding 属性から signal register キーへのマッピング規則の定義追加
- A-1：intent review テンプレートと conformance review テンプレートの必須セクション名の確定
- A-3：`docs/reviews/*.md` 内の artifact 種別判別機構（命名規約または front-matter type フィールド）の定義

**要件への差し戻し：0 件**
- 要件は十分に具体的であり、設計が拾いきれていないだけ。要件の曖昧さや矛盾に起因する問題はない。

**他 spec 設計への波及：0 件**
- 4 件すべてが governance 設計の内部補完で完結し、foundation や runtime 等の設計変更を要しない。
