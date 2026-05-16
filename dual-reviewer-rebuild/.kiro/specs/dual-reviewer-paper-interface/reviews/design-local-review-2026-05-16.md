# dual-reviewer-paper-interface design 個別レビュー

## 取得メタデータ

- 実施日：2026-05-16
- 対象：`dual-reviewer-paper-interface/design.md`（要件承認後の差分追従済み）
- 契約入力：`dual-reviewer-paper-interface/requirements.md`（承認済み）、上流 `foundation/requirements.md`
- 方式：claude --print --disallowedTools "Read,Write,Edit"（ファイルアクセス技術的遮断）
- 主役：claude-sonnet-4-6 / 敵対役：claude-opus-4-7 / 判断役：claude-opus-4-6
- 通信構造：β 逐次方式（主役 → 敵対役 → 判断役）
- 手順：REVIEW_PROTOCOL.md 節 3（設計レビュー 10 観点）

---

## 主役発見（claude-sonnet-4-6）

10 観点・10 ラウンドの設計レビューを実施します。

---

# 設計レビュー所見：dual-reviewer-paper-interface / design.md

---

## ラウンド 1：要件全件の網羅

**Req 1（主張-証拠対応）**：claim_map.json の 6 フィールド定義により AC1〜AC6 を概ね網羅。AC6（claim 単位の構造化）も明示的に対処。

**Req 2（データ契約）**：AC1〜AC6 を figure/table bundle と stale 再生成ルールで対処。

**Req 3（注意事項追跡）**：paper_caveat_register.json の `limitation_type` で AC1〜AC5 を意図しているが、語彙未定義（後述 P-3）。

**Req 4（分離）**：No Reverse Control / No Silent Strengthening で AC1〜AC5 に対処。

**Req 5（成熟度区別）**：maturity label と統一語彙宣言で AC1〜AC6 に対処しているが、foundation 語彙との整合に問題（後述 P-2）。

**Req 6（review-mode 来歴）**：設計本文に言及なし。Requirements Traceability 表にも Req 6 の行が存在しない。

---

**P-1** ｜ **CRITICAL**
- 対象箇所：design.md「Requirements Traceability」表、evidence_register モデル、claim_map モデル
- 説明：Requirement 6（Review-Mode Provenance in Reporting）が設計から全面欠落している。traceability 表に行が存在せず、`evidence_register.json` にも `claim_map.json` にも `review_mode` フィールドがない。Req 6 AC2（手動 dogfooding 証拠とランタイム証拠の分離報告）・AC3（手動レビュー記録をランタイム証拠として提示しない）は、明示的フィールドがなければ設計レベルでは実現不能である。
- 根拠：paper-interface Req 6 AC1〜AC5；foundation Req 6 AC6（review-mode 語彙の正準定義）

---

## ラウンド 2：アーキテクチャ整合性

4 段パイプライン（claim mapping → bundle generation → caveat attachment → export）は要件の変換フローに対応しており、evaluation が上流・paper/ が下流という依存方向も正しい。Separation Rules が明示されており逆流防止の設計意図も明確。

---

**P-2** ｜ **WARN**
- 対象箇所：design.md「Architecture」mermaid 図
- 説明：図は `experiments/analysis/` のみを入力として描くが、「Interfaces to Other Features」節には `runtime_validation_summary.yaml` / `conformance_review_result.yaml` というオプション取り込み経路が記述されている。図が実際の入力仕様と一致していないため、実装者が取り込み対象を誤読する恐れがある。
- 根拠：design.md「Interfaces to Other Features / Evaluation」

---

## ラウンド 3：データモデル・スキーマ詳細

---

**P-3** ｜ **ERROR**
- 対象箇所：claim_map.json、evidence_register.json、paper_caveat_register.json、table/figure_source_bundle.json 全フィールド
- 説明：`supporting_artifact_refs`・`caveat_refs`・`provenance_refs`・`artifact_ref`・`source_analysis_manifest_ref`・`input_run_set_ref`・`source_caveat_ref`・`applies_to_claim_refs` など、すべての「参照フィールド」の形式が未定義である。文字列ファイルパスか、UUID か、構造化オブジェクトかが不明であり、クロスドキュメントリンクを機械的に検証できない。Req 1 AC5「バージョン管理された証拠に辿れない成果物は claim に使わない」の検証が、参照形式が決まらないと実施不能になる。
- 根拠：paper-interface Req 1 AC2・AC5；Req 2 AC2

---

**P-4** ｜ **ERROR**
- 対象箇所：paper_caveat_register.json の `limitation_type` フィールド
- 説明：Req 3 AC2 は「無効データ除外・部分的証拠・方法論的限界」の 3 分類を区別することを要求しているが、設計は `limitation_type` というフィールド名を列挙するだけで語彙を一切定義していない。列挙型や例示すら存在しないため、実装者が独自解釈するリスクがあり、受入基準が機械的に検証不能になる。
- 根拠：paper-interface Req 3 AC2

---

**P-5** ｜ **ERROR**
- 対象箇所：design.md「Evidence Register Model / 1. Evidence Maturity」
- 説明：設計は evidence maturity 語彙として `mature / preliminary / exploratory` を定義し、「foundation の正準 evidence-class に結合する」と宣言している。しかし foundation Req 6 AC8 が定義する正準語彙は `valid / invalid / exploratory` であり、`mature` と `preliminary` は foundation に存在しない。evidence_register.json にも `evidence_class` フィールドが存在しないため、foundation 語彙への結合が schema レベルで実現されていない。paper-interface Req 5 AC6「foundation 正準 evidence-class フィールドに結合、独自再定義しない」に抵触する。2 つの語彙の関係（例：`mature` = `valid` の部分集合か）を設計で明示する必要がある。
- 根拠：foundation Req 6 AC8；paper-interface Req 5 AC6

---

**P-6** ｜ **WARN**
- 対象箇所：figures/figure_source_bundle.json の `plot_contract` フィールド
- 説明：`plot_contract` は「どの slice / metric / grouping を使うかの reporting-side definition」とのみ説明されており、フィールド構造が未定義。figure bundle の再生成可能性（Req 2 AC4）は `plot_contract` の内容が確定していないと保証できない。
- 根拠：paper-interface Req 2 AC1・AC4

---

**P-7** ｜ **WARN**
- 対象箇所：tables/table_source_bundle.json の `field_projection` フィールド
- 説明：`field_projection` が「どのフィールドを射影するか」を意図していることは読み取れるが、型・形式（フィールド名のリストか JSONPath か）が未定義。同フィールドが table source bundle の再生成可能性に直結するにもかかわらず形式が不明確。
- 根拠：paper-interface Req 2 AC1・AC4

---

## ラウンド 4：API 接合面の具体化

---

**P-8** ｜ **ERROR**
- 対象箇所：design.md「Separation Rules / Stale Upstream Regeneration」および「Interfaces to Other Features」
- 説明：Req 2 AC6 は「上流評価出力が run 無効化により stale とされたとき paper-facing artifact を再生成すること」を要求し、design もこれを受けて「再生成の対象とする」と述べる。しかし stale をどのように検出するか（ファイルのタイムスタンプか、マーカーファイルか、manifest フラグか）、誰が再生成をトリガーするか（自動実行か、手動コマンドか）が設計に一切記述されていない。foundation Req 6 AC9 が定める「無効化マーカー付与時の陳腐化伝播義務」の実現方法も未定義のままである。
- 根拠：paper-interface Req 2 AC6；foundation Req 6 AC9

---

**P-9** ｜ **WARN**
- 対象箇所：design.md「Interfaces to Other Features / Evaluation」
- 説明：評価出力の取り込み元パスは mermaid 図に `experiments/analysis/` と示されているのみで、interface 節に正式な相対パス定義がない。また、オプション取り込みとして挙げられる `runtime_validation_summary.yaml` / `conformance_review_result.yaml` について、paper-interface が参照する具体的なフィールドが未定義であり、intake 契約が曖昧。
- 根拠：paper-interface Req 2 AC2；foundation Req 4 AC4（repo 相対パスで参照）

---

## ラウンド 5：アルゴリズム・性能達成手段

本 spec は reporting 変換層であり、性能要件はない。該当なし確認済み。

---

**P-10** ｜ **INFO**
- 対象箇所：design.md「Claim Mapping Model / 1. Claim Unit」
- 説明：設計は「文字列 heuristic ではなく構造化参照を使う」と宣言しているが、claim mapper がどのロジックで supporting_artifact を特定するかは未定義。P-3 の参照形式が決まれば自然に解消する可能性が高いため INFO とするが、実装フェーズ前に照合ロジックを明示する必要がある。
- 根拠：paper-interface Req 1 AC1

---

## ラウンド 6：失敗モード処理・観測性

---

**P-11** ｜ **ERROR**
- 対象箇所：design.md「Design Drivers」（評価出力不在時の扱い）
- 説明：設計は「evaluation output が存在しない場合は生ログにフォールバックせず、評価プロセスの実行を要求する」と述べるが、「要求する」の具体的な形（エラーメッセージ・終了コード・ログ出力・通知方法）が未定義。また、paper-facing artifact が stale になった後に author がそれを知る手段も設計に存在しない。失敗時の観測手段がなければ、誤った paper artifact が无声のまま使われる恐れがある。
- 根拠：paper-interface Req 1 AC4；Req 2 AC6

---

## ラウンド 7：セキュリティ・プライバシー

本 spec はローカルリポジトリ完結型のレポーティング層であり、外部通信・認証・PII を扱わない。该当なし確認済み。

---

## ラウンド 8：依存選定

設計レベルとして実装言語・ライブラリを未定義としている点は適切。foundation への依存（evidence-class 語彙の参照）は正しい方向だが実現に問題があり P-5 で指摘済み。evaluation への依存は消費のみ（逆流なし）で方向正しい。該当なし（P-5 で記録済み）。

---

## ラウンド 9：テスト戦略

---

**P-12** ｜ **ERROR**
- 対象箇所：design.md 全体（テスト戦略節が不在）
- 説明：設計にテスト戦略節が存在しない。受入基準（AC）がどのように検証可能かを設計が示していないため、「claim に evidence が辿れること」「preliminary を mature に昇格しないこと」「stale 時に再生成が起きること」などの核心的 AC の確認方法が不明。テスト対象となるスキーマ検証・統合検証の方針がないと実装フェーズの完了判定基準が曖昧になる。
- 根拠：paper-interface Req 1〜6 各 AC；REVIEW_PROTOCOL 設計レビュー観点 9

---

## ラウンド 10：移行戦略

新規機能であり移行は不要。該当なし確認済み。

---

**P-13** ｜ **INFO**
- 対象箇所：design.md「Completion Criteria」および Req 4 AC5
- 説明：Req 4 AC5 は「下流の物語的変換を明示的かつバージョン管理可能にすること」を要求するが、design は `paper/` 成果物自体のバージョン管理方針（reporting_fragments のバージョン付け方法、過去版の保持規則など）を定義していない。移行は不要だが成果物版管理の方針として付記する。
- 根拠：paper-interface Req 4 AC5

---

## 観点別発見要約

| ラウンド | 結果 | 主な所見 |
|---|---|---|
| 1 要件網羅 | **CRITICAL** | Req 6 全面欠落、traceability 表にも行なし |
| 2 アーキテクチャ | WARN | 図がオプション入力を反映せず |
| 3 データモデル | ERROR×3、WARN×2 | 参照形式未定義、limitation_type 語彙なし、maturity と foundation 語彙の不一致 |
| 4 API 接合面 | ERROR、WARN | stale 検出メカニズム未定義、intake パス未正式定義 |
| 5 アルゴリズム | INFO | 該当なし（claim matcher ロジックは INFO） |
| 6 失敗モード | ERROR | 評価不在・stale 通知の観測手段なし |
| 7 セキュリティ | 該当なし | ローカル完結、PII なし |
| 8 依存選定 | 該当なし | P-5 に統合済み |
| 9 テスト戦略 | **ERROR** | テスト戦略節が不在 |
| 10 移行戦略 | INFO | 新規機能、成果物版管理方針は付記 |

---

## must-fix 候補（CRITICAL / ERROR）

- **P-1** Requirement 6 の設計対応とフィールド追加（`review_mode` in evidence_register）
- **P-3** 参照フィールドの形式統一定義
- **P-4** `limitation_type` 語彙の列挙定義
- **P-5** foundation evidence-class 語彙との関係を明示（`evidence_class` フィールドの追加か、あるいは paper-facing maturity と run-class の関係説明）
- **P-8** stale 検出・再生成トリガーのメカニズム定義
- **P-11** 失敗モードの観測出力（エラー形式・stale 通知）の定義
- **P-12** テスト戦略節の追加

---

## 敵対役レビュー（claude-opus-4-7）

# 敵対役レビュー：dual-reviewer-paper-interface / design.md

主役の 10 ラウンド網羅を確認した。安易な同調はせず、反論と独立検出を以下に提示する。

---

## パート1：主役の各発見への反論

**P-1（Req 6 全面欠落・CRITICAL）**
- 判断：反論なし。
- 内容：要件 6（レビュー様式の来歴。手動 dogfooding〔自己試用〕レビューとランタイム経由レビューを区別して報告すること）が設計本文・traceability 表の双方から完全に脱落していることを確認した。CRITICAL 妥当。ただし主役は受入 2・3 のみ引用しているが、受入 4（混在時の caveat 付与）・受入 5（後発のランタイム証拠で初期手動証拠を置換する追跡性）も未対応である。P-1 の指摘範囲をこの 2 点まで広げる必要がある（独立補足は A-1 で採番）。

**P-2（mermaid 図がオプション入力を反映せず・WARN）**
- 判断：反論あり（部分的）。
- 内容：当該オプション取り込みは設計本文で「provenance convenience として追加 intake してよい」と明示的に任意扱いされている。高水準アーキテクチャ図が任意入力を省略するのは抽象化として許容範囲であり、欠陥というより記述精度の問題。重大度は INFO が妥当。なお同種の本質的問題は P-9（intake パス未定義）が捕捉しており、P-2 は P-9 に統合してよい。

**P-3（参照フィールド形式未定義・ERROR）**
- 判断：反論なし。
- 内容：全 `*_refs` 系フィールドの形式（文字列パス／識別子／構造化オブジェクト）が未定義で、機械的なクロスドキュメント追跡（要件 1 受入 5）を阻害する。ERROR 妥当。設計層で必ず確定すべき契約事項である。

**P-4（`limitation_type` 語彙未定義・ERROR）**
- 判断：反論なし。
- 内容：要件 3 受入 2 は「無効データ除外・部分的証拠・方法論的限界」の 3 分類区別を明示要求しているのに、設計はフィールド名のみで列挙値ゼロ。ERROR 妥当。

**P-5（maturity 語彙と foundation 正準語彙の不一致・ERROR）**
- 判断：反論あり（部分的＝重大度の引き上げ）。
- 内容：指摘内容は正しい。設計は `mature / preliminary / exploratory` を foundation 正準 evidence-class（`valid / invalid / exploratory`）へ「結合する」と自称しながら、`mature` と `preliminary` は foundation 側に存在せず、`evidence_class` フィールドも持たない。これは単なる定義漏れではなく、設計が要件 5 受入 6 への準拠を明文で主張しつつ違反しているクロス spec 契約違反である。自称準拠と実体の矛盾は ERROR ではなく CRITICAL に引き上げるべき。

**P-6（`plot_contract` 未定義・WARN）／ P-7（`field_projection` 未定義・WARN）**
- 判断：反論なし。
- 内容：いずれも再生成可能性（要件 2 受入 4）に直結する未定義フィールドであり WARN 妥当。

**P-8（stale 検出メカニズム未定義・ERROR）**
- 判断：反論あり（部分的＝スコープの切り分け）。
- 内容：ERROR 妥当だが、must-fix 範囲を分離すべき。陳腐化を表す信号の表現方法（manifest 上のフラグか無効化マーカーか）は foundation 要件 6 受入 9 の伝播義務を受ける契約事項であり、設計層で必須。一方「誰が自動／手動で再生成を起動するか」は実装層へ委譲可能。must-fix は前者（陳腐化信号の契約定義）に限定し、起動自動化は委譲明記で足りる、と切り分けることを推奨する。

**P-9（intake パス未正式定義・WARN）**
- 判断：反論なし。
- 内容：妥当。P-2 はこれに統合可。

**P-10（claim matcher 照合ロジック未定義・INFO）**
- 判断：反論なし。
- 内容：P-3 の参照形式確定でほぼ解消する従属的事項であり INFO 妥当。

**P-11（失敗モード観測手段なし・ERROR）**
- 判断：反論あり（部分的＝スコープ）。
- 内容：「評価プロセスの実行を要求する」の出力形式（終了コード等）は実装裁量で、それ自体を ERROR 化するのは過剰。ただし「paper-facing 成果物が stale 化した後に著者がそれを知る手段が皆無」という観測性欠落は実在のリスクで、ここに限れば ERROR 相当。指摘は維持しつつ、対象を「stale 状態の著者向け可視化の欠落」に絞るべき。

**P-12（テスト戦略節が不在・ERROR）**
- 判断：反論なし。
- 内容：設計にテスト戦略節がなく、核心 AC（証拠追跡性・無声昇格禁止・stale 再生成）の検証方法が示されていない。ERROR 妥当。

**P-13（成果物バージョン管理方針未定義・INFO）**
- 判断：反論あり（重大度の引き上げ）。
- 内容：要件 4 受入 5 は「下流の物語的変換を明示的かつバージョン管理可能にすること」を明確な受入基準として課している。設計は `reporting_fragments` 等にバージョンフィールドも過去版保持規則も持たない。これは付記レベルの INFO ではなく、明示 AC の直接的不充足であり ERROR（最低でも WARN）に引き上げるべき。INFO 据え置きは契約不充足の過小評価である。

---

## パート2：主役が見落とした独立発見

**A-1**｜**ERROR**
- 対象箇所：`evidence_register.json`、`paper_caveat_register.json`（要件 6 受入 4・5 への対応欠落）
- 説明：主役 P-1 は要件 6 を「全面欠落」と一括したが、受入 4（同一報告セットに複数レビュー様式が混在するときの caveat 付与）と受入 5（初期手動証拠を後発のランタイム証拠で置換する追跡性）は、`review_mode` フィールド 1 個を足すだけでは充足しない独立の構造要件である。混在検知トリガーと置換系譜（誰が誰を置換したか）の保持先が別途必要で、P-1 の修正案（evidence_register への review_mode 追加）だけでは取りこぼす。
- 根拠：paper-interface 要件 6 受入 4・5；foundation 要件 6 受入 6
- 重大度：ERROR

**A-2**｜**ERROR**
- 対象箇所：`evidence_register.json`、`claim_map.json`（置換・系譜フィールドの不在）
- 説明：要件 5 受入 5（後の精緻化・置換に必要な追跡性の保持）と要件 6 受入 5 は、いずれも証拠の世代交代（preliminary → mature、手動 → ランタイム）を辿る系譜リンクを要求する。設計のどのモデルにも `supersedes` / `replaced_by` 相当の前後関係フィールドが存在しない。`maturity_label` は現時点の成熟度を示すのみで、置換履歴を表現できない。これは P-1（要件 6）にも P-5（語彙不一致）にも含まれない、要件 5 側にまたがる独立欠落である。
- 根拠：paper-interface 要件 5 受入 5；要件 6 受入 5
- 重大度：ERROR

**A-3**｜**WARN**
- 対象箇所：design.md「Open Issues for Design Alignment Gate」
- 説明：設計は未解決の Open Issue を 3 件抱えたまま提示されているが、その全てが検証可能な AC に直接触れる契約事項である。すなわち「claim ID taxonomy の formalize 範囲」＝要件 1 受入 6（claim は識別子を持つ）、「figure/table bundle の field naming を evaluation とどこまで揃えるか」＝要件 2 受入 2（評価出力への provenance 結合）、「adopted change history を methodology note に含める範囲」＝要件 4 受入 1・Self-Improvement 分離。契約 AC に直結する論点が未決のまま残る設計は、設計整合ゲートを通すべきでない。主役はこの節を欠陥として扱っていない。
- 根拠：paper-interface 要件 1 受入 6；要件 2 受入 2；要件 4 受入 1
- 重大度：WARN

**A-4**｜**ERROR**
- 対象箇所：design.md「Supporting Artifact Sources」一覧（`comparisons/treatment_comparisons.json`、`classifications/exclusion_report.json`、`caveats/caveat_register.json` 等）
- 説明：これらの入力パスはどれも基準ディレクトリ（リポジトリ相対の起点）が明記されない、宙に浮いた相対パスである。特に `caveats/caveat_register.json` は、設計が別途定義する出力先 `paper/caveats/paper_caveat_register.json` と語が衝突し、上流側の `caveats/` か `paper/caveats/` かが文面から判別できない。foundation 要件 4 受入 4（相対リポジトリパスのみで所在特定可能であること）の趣旨と要件 1 受入 2（provenance 保持）に反する具体的契約欠陥であり、P-9（オプション yaml の intake 曖昧）とは別個の問題である。
- 根拠：paper-interface 要件 1 受入 2；要件 2 受入 2；foundation 要件 4 受入 4
- 重大度：ERROR

**A-5**｜**ERROR**
- 対象箇所：design.md「Reporting Fragment Model」（`comparison_summary` 等の多元集約 fragment）
- 説明：設計の No Silent Strengthening 規則は「preliminary/exploratory を mature と同列に扱わない」＝昇格禁止のみを定める。しかし `comparison_summary` のように複数 source artifact を 1 fragment に集約する型では、成熟度の異なる出典を束ねた結果として fragment の `maturity_label` が単一値に潰れ、最も保守的でない値が採用される「集約による成熟度喪失」が起こりうる。設計には「fragment の成熟度は出典の最小（最保守）値とする」または「混在時は区別が可視に残るときのみ許可」というルールがない。要件 5 受入 3・4（混在報告は区別が見える場合のみ／成熟・予備を未分化成果物に潰さない）と要件 3 受入 5（caveated 証拠を無声で強い証拠に昇格しない）に対する、昇格とは別経路の独立リスクである。
- 根拠：paper-interface 要件 5 受入 3・4；要件 3 受入 5
- 重大度：ERROR

**A-6**｜**WARN**
- 対象箇所：design.md「Interfaces to Other Features / Evaluation」、ラウンド 8（依存選定）
- 説明：主役はラウンド 8 を「該当なし」としたが、本設計は evaluation の成果物形状（`treatment_comparisons.json` 等）に強く依存しているにもかかわらず、依存先スキーマのバージョン固定・互換性契約を一切定義していない。evaluation 側が形状を変えた場合、paper-interface は無声で破綻する。これは消費方向（逆流なし）が正しいか否かとは別の、上流依存の版整合という設計レベルの欠落であり、ラウンド 8 は「該当なし」ではなく本件を計上すべきである。
- 根拠：paper-interface 要件 2 受入 2・受入 4；要件 4 受入 1
- 重大度：WARN

---

## 統合所見（敵対役の結論）

- 主役の must-fix（P-1, P-3, P-4, P-5, P-8, P-11, P-12）は全て支持する。重大度の是正提案：**P-5 は CRITICAL へ引き上げ**（自称準拠と実体の矛盾）、**P-13 は INFO → ERROR/WARN へ引き上げ**（明示 AC の不充足）。
- 重大度の引き下げ提案：P-2 は INFO（任意入力の図省略）、P-2 は P-9 へ統合。
- 独立追加の must-fix 候補：**A-1（要件 6 受入 4/5 の構造欠落）**、**A-2（置換・系譜フィールド不在）**、**A-4（宙に浮いた相対パスと caveats 名称衝突）**、**A-5（多元 fragment の成熟度集約規則欠如）**。
- 設計ゲート判定：未解決 Open Issue が契約 AC に直結する（A-3）こと、要件 6 系の構造欠落（P-1＋A-1＋A-2）が広範であることから、本 design は現状で設計整合ゲート通過不可と判断する。

---

## 判断役レビュー（claude-opus-4-6）

# 判断役：最終判定

---

## 各所見への判定

### P-1（Req 6 全面欠落）

- **判定：must-fix**
- 判断根拠：要件 6 が設計本文にも traceability 表にも一切現れないのは、要件 1 件分の設計対応が丸ごと脱落している状態であり、弁明の余地がない。
- 敵対役反論（受入 4/5 の追加不足指摘）：**採用**。A-1 として後述。

---

### P-2（mermaid 図がオプション入力を省略）

- **判定：leave-as-is（INFO に引き下げ、P-9 に統合）**
- 判断根拠：敵対役の反論を採用する。設計本文が「provenance convenience として追加 intake してよい」と明記しており、高水準図が任意経路を省略するのは許容範囲の抽象化。実質的な契約不明確性は P-9 が捕捉済み。

---

### P-3（参照フィールド形式未定義）

- **判定：must-fix**
- 判断根拠：`*_refs` 系フィールドがパス文字列か識別子か構造体か決まらないと、クロスドキュメント追跡の機械的検証（要件 1 受入 5）が設計レベルで不可能。全モデルに共通する基盤的欠落。

---

### P-4（limitation_type 語彙未定義）

- **判定：must-fix**
- 判断根拠：要件 3 受入 2 が「無効データ除外・部分的証拠・方法論的限界」の 3 分類を名指しで要求しており、設計がフィールド名だけで列挙値ゼロなのは直接的 AC 不充足。

---

### P-5（maturity 語彙と foundation 正準語彙の不一致）

- **判定：must-fix（CRITICAL に引き上げ）**
- 判断根拠：敵対役の引き上げ提案を採用する。設計が「foundation 正準 evidence-class に結合する」と自称しながら、foundation 側に存在しない語彙（`mature` / `preliminary`）を用い、結合用フィールド（`evidence_class`）も持たない。自称準拠と実体の矛盾は単なる定義漏れより深刻なクロス spec 契約違反。設計は foundation の `valid / invalid / exploratory` と paper-interface の `mature / preliminary / exploratory` の関係を明示的に定義する必要がある。

---

### P-6（plot_contract 未定義）

- **判定：should-fix**
- 判断根拠：再生成可能性（要件 2 受入 4）に影響するが、bundle としてのフィールド存在は示されており、構造化は実装前に確定すれば間に合う。設計承認の阻害要因とまでは言えない。

---

### P-7（field_projection 未定義）

- **判定：should-fix**
- 判断根拠：P-6 と同種。形式確定は実装前で足りるが、設計に型の方向性（フィールド名リストか JSONPath か等）は示すべき。

---

### P-8（stale 検出メカニズム未定義）

- **判定：must-fix（スコープ限定を採用）**
- 判断根拠：敵対役のスコープ切り分けを採用する。must-fix 対象は「陳腐化を表す信号の表現方法」（manifest フラグ・マーカーファイル等の契約定義）に限定する。「誰が再生成を自動起動するか」は実装委譲を設計に明記すればよい。foundation 要件 6 受入 9 の伝播義務を受ける設計レベルの責務。

---

### P-9（intake パス未正式定義）

- **判定：should-fix（P-2 統合）**
- 判断根拠：evaluation 出力の正式な相対パスと、オプション取り込み対象のフィールド仕様を設計に明記すべき。ただし A-4（入力パス基準不在）がより本質的な上位問題を捕捉しており、A-4 解消に付随して解決可能。

---

### P-10（claim matcher 照合ロジック未定義）

- **判定：leave-as-is（INFO 維持）**
- 判断根拠：P-3（参照形式確定）の解消で自然に方向が決まる従属事項。独立 must-fix にする必要なし。

---

### P-11（失敗モード観測手段なし）

- **判定：should-fix（スコープ限定）**
- 判断根拠：敵対役のスコープ指摘を採用する。「evaluation 不在時のエラー出力形式」は実装裁量で決められる。一方「stale 化した paper-facing 成果物を著者が知る手段の欠落」は実在のリスクだが、P-8 の staleness 信号契約が定まれば、著者への可視化方法は実装で対処可能。設計には「staleness は著者から観測可能であること」という要求を一文添えれば足りる。

---

### P-12（テスト戦略節不在）

- **判定：must-fix**
- 判断根拠：核心 AC（証拠追跡性の機械検証・無声昇格禁止の検出・stale 再生成の確認）をどう検証するかが設計に皆無。実装フェーズの完了判定が曖昧になり、レビュー品質が担保されない。

---

### P-13（成果物バージョン管理方針未定義）

- **判定：should-fix（INFO → WARN に引き上げ）**
- 判断根拠：敵対役の引き上げ提案を部分的に採用する。要件 4 受入 5 は「バージョン管理可能」を明示的に要求しており INFO は過小評価。ただし「git 履歴で追跡する」という判断で充足可能な受入基準であるため、設計にその方針を一文明記すれば足り、ERROR までは不要。WARN（should-fix）が妥当。

---

### A-1（要件 6 受入 4/5 の構造欠落）

- **判定：must-fix（P-1 に統合）**
- 判断根拠：`review_mode` フィールドを 1 個追加するだけでは受入 4（混在時 caveat 自動付与）・受入 5（手動→ランタイム置換の追跡）を満たせない。混在検知ルールと置換系譜の保持先を P-1 の修正スコープに含める。

---

### A-2（置換・系譜フィールド不在）

- **判定：must-fix**
- 判断根拠：要件 5 受入 5 と要件 6 受入 5 の双方が、証拠の世代交代（preliminary→mature、手動→ランタイム）を辿るリンクを要求している。`maturity_label` は現時点のスナップショットであり、「何が何を置き換えたか」を表現できない。`supersedes` / `superseded_by` 相当のフィールドが evidence_register または claim_map に必要。

---

### A-3（Open Issues が契約 AC に直結）

- **判定：should-fix**
- 判断根拠：設計の Open Issues は承認前に解決すべき論点の明示として機能している点で一概に欠陥とは言えない。ただし 3 件すべてが AC に直結する以上、解決なしにゲート通過は不適切。修正方針は「Open Issues 各項に対して暫定決定と根拠を記載し、実装着手条件を明確化する」ことで足りる。

---

### A-4（入力パスの基準ディレクトリ不在と caveats 名称衝突）

- **判定：must-fix**
- 判断根拠：`caveats/caveat_register.json`（評価の上流出力）と `paper/caveats/paper_caveat_register.json`（自身の出力）が文面上で衝突し、foundation 要件 4 受入 4（相対リポジトリパスのみで所在特定可能）に反する。全入力パスに基準ディレクトリを明記し、命名衝突を解消する必要がある。

---

### A-5（多元 fragment の成熟度集約規則欠如）

- **判定：must-fix**
- 判断根拠：`comparison_summary` のように複数出典を束ねる fragment において、成熟度の異なる出典が混在した場合の取り扱いが未定義。要件 5 受入 3（区別が見える場合のみ混在許可）・受入 4（未分化成果物への圧縮禁止）は、「fragment の成熟度は出典の最も保守的な値とする」等の明示規則なしには実現不能。

---

### A-6（上流 evaluation スキーマの版互換性契約欠落）

- **判定：should-fix**
- 判断根拠：paper-interface は evaluation の artifact 形状に強く依存するが、上流がスキーマを変更した場合の検出・互換性保証が皆無。foundation 要件 3 受入 3（バージョン付きスキーマ、無声の非互換編集禁止）の消費者側義務として設計に言及すべき。ただし evaluation 側の設計が互換性契約を持っていれば paper-interface 側の対応は軽微なため should-fix。

---

## 敵対役反論の採否一覧

| 対象 | 反論内容 | 採否 |
|------|----------|------|
| P-2 | INFO に引き下げ、P-9 統合 | **採用** |
| P-5 | CRITICAL に引き上げ | **採用** |
| P-8 | must-fix スコープを信号契約に限定 | **採用** |
| P-11 | stale 著者可視化に限定 | **採用** |
| P-13 | ERROR への引き上げ | **部分採用**（WARN 止まり） |

---

## 集計

**must-fix：9 件**
- P-1 + A-1、P-3、P-4、P-5、P-8、P-12、A-2、A-4、A-5

**should-fix：7 件**
- P-6、P-7、P-9（P-2 統合）、P-11、P-13、A-3、A-6

**leave-as-is：2 件**
- P-2（P-9 に統合）、P-10

---

## must-fix の帰属別分類

### paper-interface 設計固有（8 件）

- **P-1 + A-1**：Req 6 の設計対応（`review_mode` フィールド＋混在検知規則＋置換系譜の構造追加、traceability 表への行追加）
- **P-3**：全 `*_refs` 系フィールドの参照形式定義
- **P-4**：`limitation_type` 語彙の列挙（3 分類の正準値）
- **P-8**：陳腐化信号の表現契約と再生成対象の判定方法
- **P-12**：テスト戦略節の追加（スキーマ検証・統合検証・回帰防止の方針）
- **A-2**：evidence_register に `supersedes` / `superseded_by` 相当の系譜フィールド追加
- **A-4**：全入力パスへの基準ディレクトリ明記と `caveats/` 名称衝突の解消
- **A-5**：多元 fragment の成熟度集約規則の明示（出典最小値ルール等）

### 他 spec 設計への波及（1 件）

- **P-5**：foundation の `valid / invalid / exploratory` と paper-interface の `mature / preliminary / exploratory` の関係を明示する必要がある。foundation 語彙が「run の妥当性」を表し、paper-interface の maturity が「証拠の成熟度」を表す別次元であるなら、その旨を設計に明記し `evidence_class`（foundation 由来）と `maturity_label`（paper-interface 固有）を両方持つ構造にする。もし同一次元と見做すなら foundation 側の語彙拡張提案が必要（dual-reviewer-foundation 設計への波及）。

### 要件への差し戻し

- **なし**。全 must-fix は要件の記述が明確であり、設計の対応不足に帰属する。

---

## 総合ゲート判定

**設計整合ゲート：不通過**

理由：must-fix 9 件のうち、P-1+A-1（要件 1 件分の全面欠落）と P-5（クロス spec 契約の自称準拠と実体の矛盾）は設計の構造的問題であり、局所修正では吸収しきれない。must-fix 全件の解消後に再レビューを要する。
