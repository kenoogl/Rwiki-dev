# dual-reviewer-foundation design 個別レビュー

## 取得メタデータ

- 実施日：2026-05-16
- 対象：`dual-reviewer-foundation/design.md`（要件承認後の差分追従済み）
- 契約入力：`dual-reviewer-foundation/requirements.md`（承認済み）、上流 `foundation/requirements.md`
- 方式：claude --print --disallowedTools "Read,Write,Edit"（ファイルアクセス技術的遮断）
- 主役：claude-sonnet-4-6 / 敵対役：claude-opus-4-7 / 判断役：claude-opus-4-6
- 通信構造：β 逐次方式（主役 → 敵対役 → 判断役）
- 手順：REVIEW_PROTOCOL.md 節 3（設計レビュー 10 観点）

---

## 主役発見（claude-sonnet-4-6）

## 設計レビュー：dual-reviewer-foundation/design.md

---

### Round 1：要件全件の網羅

**P-1 ERROR / Req 4 AC1 / Step A・B のプロンプト配置が設計に存在しない**

要件 4 受入 1 は「Steps A, B, C のプロンプトテンプレートの canonical 配置を定義すること」を求める。成果物レイアウト（§Shared Artifact Layout）には `runtime/prompts/judgment/judgment_reviewer.prompt.md` だけが記載されており、Step A（primary_detection）と Step B（adversarial_review）のプロンプトディレクトリ・ファイル命名規約が設計に存在しない。runtime 実装者はこの 2 ステップのプロンプトをどこに置けばよいか決定できない。

**P-2 ERROR / Req 3 AC9 / B-1.0 必須フィールドと defer 拡張点の区別が未記述**

要件 3 受入 9 は「B-1.0 相当運用に必須なフィールドと意図的に defer する拡張点を明示すること」を要求する。設計 §4 の各スキーマ節はフィールドを列挙するが、どのフィールドが必須でどれが将来拡張かを示すマーカーが一切ない。`finding` の例でいえば `decision_unit_id` や `human_decision_ref` が B-1.0 時点で必須かどうかが判断できない。

**P-3 WARN / Req 1 AC3 / 状態遷移ラベルの語彙が不定義**

要件 1 受入 3 は「ログが同一概念ステージを参照できるよう required state transition names を定義すること」を求める。設計はステップ名（primary_detection 等）を固定するが、遷移ラベル（started / completed / failed 等）は `layer1_framework.yaml` の `required_metadata_refs` セクションに存在を示唆するのみで、具体的な語彙が提示されていない。

**P-4 WARN / Req 6 AC6 / review_mode 語彙が「例示」止まりで closed set か不明**

要件 6 受入 6 は canonical review-mode 語彙の定義を求める。設計は `manual_dogfooding / runtime_mediated などの mode` と記述し「などの（etc.）」で開放的にしているため、実装者は追加値を定義できるのか、それとも foundation が閉じた語彙を持つのかを判断できない。

**P-5 WARN / Req 6 AC8 / evidence_class の状態遷移ルールが未定義**

設計 §3 は「validator_status と human_signoff_status が揃った後に valid / invalid / exploratory へ遷移する」と説明するが、どの組合せが何の evidence_class に遷移するかのルールが不在。`exploratory` はいつ誰がセットするか（human が明示的に指定する場合のみ？）も不明。evaluation と paper-interface はこのロジックに依存する。

---

### Round 2：アーキテクチャ整合性

**P-6 WARN / アーキテクチャ / foundation 成果物を `runtime/` 配下に置く命名上の曖昧さ**

後続の spec 名も `dual-reviewer-runtime` であるため、「foundation が所有する shared asset の置き場所が `runtime/` ディレクトリ」という設計は、directory 名から所有者が読み取れない。`runtime/foundation/` という内側パスが foundation の正本であることは分かるが、`runtime/schemas/` や `runtime/prompts/` が foundation 所有なのか runtime 所有なのかをディレクトリ名からは区別できない。downstream 開発者が所有境界を誤解するリスクがある。

**P-7 INFO / アーキテクチャ / meta layer のうち foundation が実際に担う部分の記述が不完全**

設計 §Architecture は general / meta / project-specific の 3 層を説明しながら「foundation は主に最初の 2 層の土台を作る」と述べる。しかし pattern assets を本 spec の責務外にしたため、meta layer のうち foundation が具体的に何を担うのかが不明のまま。軽微だが将来の spec 整合確認時の混乱源になりうる。

---

### Round 3：データモデル・スキーマ詳細

**P-8 ERROR / Req 3 AC7 / `impact_score` スキーマのフィールド定義が不在**

設計 §4 は「foundation では field 形状のみを固定する」と述べるが、impact_score の具体的フィールド名がどこにも記述されていない。要件 3 受入 7 が要求する「finding severity / fix cost estimate / downstream effect scope を cover する multi-axis 構造」をフィールド名なしに schema ファイルとして実装することはできない。

**P-9 ERROR / Req 3 AC8 / `failure_observation` スキーマのフィールド定義が不在**

設計 §4 は「finding と分離した独立 schema とする」と述べるが、フィールドが一切列挙されていない。要件 3 受入 8 が要求する「cross-run research metrics に必要な failure mode 分類データ構造」を定義するには、何を記録するか（failure_type, missed_by_role, detected_at_step 等）の最低限の形状が必要。

**P-10 ERROR / §Validation and Invalidation Model / `validator_result.schema.json` のフィールド定義が不在**

設計 §8 は `invalidation_marker` のフィールドを列挙する（run_id, reason_code, reason_detail, scope, issued_by, issued_at）が、`validator_result` については形状が一切記述されていない。validator 実装者は、validation 結果に何を書けばよいか（status, checked_fields, error_list, timestamp 等）を設計から読み取れない。

**P-11 WARN / Req 3 AC6 / `necessity_judgment` の 5-field 名が要件書に明記されているのに設計が引き継いでいない**

要件 3 受入 6 は 5 フィールド名（requirement_link, ignored_impact, fix_cost, scope_expansion, uncertainty）を明示する。設計 §4 は「5-field structure, final label, recommended action, optional override reason を固定する」と述べるにとどまり、フィールド名を展開していない。要件がフィールド名まで定義している珍しいケースであり、設計で追認または改訂する必要がある。

**P-12 WARN / §4, §5 / `review_case` における step record のネスト構造が不明**

設計 §4 は review_case が「step record 境界を持つ」と述べ、§5 の step-level replay model では step_id / step_name / step_status / step_prompt_artifact_id / step_started_at / step_closed_at を列挙する。しかし review_case スキーマ内でこれらがどのように格納されるか（例: `steps[]` 配列フィールド）が示されていない。schema 実装者は構造を推測することになる。

---

### Round 4：API 接合面の具体化

**P-13 WARN / §Domain Model §1 / `layer1_framework.yaml` の 4 セクションが内容未記述**

設計 §1 は top-level sections として `step_intents`, `required_metadata_refs`, `asset_locations`, `override_policy` を列挙するが、それぞれの内容形式が記述されていない。特に `asset_locations` は runtime が schema・prompt を path 解決するための接合面であり、形式（相対パスのキーバリューマップ等）が不明では runtime 実装が開始できない。`override_policy` についても、「runtime 責務の prompt override 選択順序と重複しない」ことを設計で明示する必要がある。

**P-14 WARN / Req 4 AC2 / finding → step → prompt artifact の traceability chain が設計で説明されていない**

設計は run レベルで `prompt_set_version`、step レベルで `step_prompt_artifact_id`、prompt artifact フロントマターに `prompt_id` を持たせる。しかしこの 3 段 chain が「各 run record から使用した prompt artifact への traceability」を実現する仕組みとして明示的に説明されていない。実装者がこの chain を把握できるよう設計への記述が必要。

---

### Round 5：アルゴリズム + 性能達成手段

**（該当なし確認）**

本 spec は contract と schema の定義であり、runtime の実行制御・性能要件を範囲外とする。Step D の「追加 LLM 呼び出しなし」は設計 §1 で明示済み。要件書も性能達成手段を求めていない。観点 5 における重大懸念なし。

---

### Round 6：失敗モード処理 + 観測性

**P-15 WARN / §5 / `step_status` の値語彙が未定義**

設計 §5 は step-level replay model で `step_status` を field として挙げるが、値語彙（例: pending / running / completed / failed / skipped）を定義していない。run_status・validator_status・human_signoff_status については enum を定義しているのに step_status は欠けており、ログ間で一貫した状態参照が成立しない。

**P-16 WARN / §Design Drivers / raw evidence の immutability が慣習のみで担保されている**

設計は「raw evidence は immutable とし」と述べるが、immutability を実現する手段（write-once 規約、content-addressable 参照、ファイルパーミッション制限等）が記述されていない。foundation が「immutable を contract として固定する」なら、最低限の保護手段方針が必要。

**P-17 INFO / Req 6 AC4 / 部分書き込み時の validator 判定最小条件が未定義**

実行途中クラッシュ時、review_case のどのフィールドが揃っていれば validator が「incomplete/failed」と機械的に判定できるかが定義されていない。Req 6 AC4「必須メタデータ欠如はバリデーション失敗を引き起こす」との接続で、必須フィールドの最小記録順序の方針が有用。

---

### Round 7：セキュリティ・プライバシー

**P-18 INFO / §3 / `target_artifact_hash` のアルゴリズムが未定義**

設計は target_artifact_hash を run metadata 必須フィールドとするが、使用するハッシュアルゴリズム（SHA-256 等）を指定していない。複数の runtime が異なるアルゴリズムを使うと、同一 artifact の cross-run 比較が成立しない恐れがある。

**P-19 INFO / §3 / `source_repository_id` の形式・一意性保証が未定義**

cross-project evidence intake を見据えたフィールドとして定義されているが、識別子の形式（URL、UUID、short name 等）と一意性の保証方法が記述されていない。形式の非統一は後続 evaluation / paper-interface での集計バグを招く。

---

### Round 8：依存選定

**（該当なし確認）**

設計は YAML（framework・metadata contract・config template）、JSON Schema（schema ファイル）、Markdown+frontmatter（prompt artifact）を採用しており、いずれも標準的かつ外部依存なし。Req 7 の repo-contained ルールに適合する。選定根拠の記述は欠けるが選定の妥当性に問題なし。観点 8 における重大懸念なし。

---

### Round 9：テスト戦略

**P-20 ERROR / 設計全体 / テスト戦略が完全に欠如**

設計に test strategy の節または記述が存在しない。foundation が定義する schema ファイルが有効な JSON Schema として解釈可能か、layer1_framework.yaml が必須フィールドを持つか、prompt frontmatter が parse 可能か等を検証する手段が不明。Completion Criteria（設計末尾）は「説明できる」という narrative 基準のみであり、自動検証可能な assertion がない。foundation は後続 4 spec の土台であるため、ここに欠陥があると連鎖して downstream が崩れる。最低限の schema lint・frontmatter parse の確認手順を定義すべき。

---

### Round 10：移行戦略

**P-21 WARN / introduction / 旧 prototype 資産からの移行方針が記述されていない**

introduction と change intent は「旧 repo の prototype 資産を流用しつつも」と述べるが、具体的な移行手順・既存 run record との互換方針・旧スキーマとの対応が設計に記述されていない。クリーンスタート（移行対象なし）であれば明示すべき。記述がないと実装者が旧資産との互換性を誤って維持しようとするリスクがある。

---

## 観点別 発見要約

- **観点 1（要件網羅）**：P-1, P-2, P-3, P-4, P-5。Step A/B プロンプト配置の欠落（P-1）と B-1.0 必須フィールド区別の欠如（P-2）が ERROR。
- **観点 2（アーキテクチャ整合）**：P-6, P-7。`runtime/` ディレクトリ命名の曖昧さが WARN。重大欠陥なし。
- **観点 3（データモデル）**：P-8, P-9, P-10, P-11, P-12。`impact_score`・`failure_observation`・`validator_result` 3 スキーマのフィールド不在が ERROR 3 件。スキーマ節が最も問題集中。
- **観点 4（API 接合面）**：P-13, P-14。`layer1_framework.yaml` の 4 未記述セクションと traceability chain の説明欠如が WARN。
- **観点 5（アルゴリズム・性能）**：該当なし確認済み。
- **観点 6（失敗モード・観測性）**：P-15, P-16, P-17。`step_status` 語彙未定義と immutability 手段の不記述が WARN。
- **観点 7（セキュリティ・プライバシー）**：P-18, P-19。ハッシュアルゴリズムと識別子形式の未定義が INFO。
- **観点 8（依存選定）**：該当なし確認済み。
- **観点 9（テスト戦略）**：P-20。テスト戦略の完全欠如が ERROR。foundation の特性上影響範囲が広い。
- **観点 10（移行戦略）**：P-21。旧資産移行方針の不記述が WARN。

---

**ERROR 以上の集計：6 件（P-1, P-2, P-8, P-9, P-10, P-20）**

---

## 敵対役レビュー（claude-opus-4-7）

# 敵対役レビュー：dual-reviewer-foundation/design.md

主役の発見 P-1〜P-21 への反論と、独立発見 A-1〜A-6 を提示する。安易な同調はせず、severity の不整合・scope 越境・要件文言の精読差をもって独立に検証した。

---

## パート1：主役の各発見への反論

- **P-1（Step A/B プロンプト配置欠落・ERROR）：反論あり(部分的)**
  配置「規約」自体は `runtime/prompts/{purpose}/{role}.prompt.md` という一意パターンとして暗黙に読み取れるため「定義が存在しない」は言い過ぎである。ただし Step A/B の concrete artifact とディレクトリ命名が成果物レイアウトに一切無いのは事実で、要件 4 受入 1 が「A, B, C」を明示している以上、未充足は成立する。指摘自体は維持、ただし「規約は推測可能・具体物が欠落」と精密化すべき。

- **P-2（B-1.0 必須/defer 区別欠如・ERROR）：反論なし**
  むしろ補強する。設計 §4 finding 節の「必須に近い field」という表現は、要件 3 受入 9 が要求する「必須」と「意図的 defer」の二値明示を能動的に裏切っている。曖昧化が要件違反の核心である。

- **P-3（状態遷移ラベル語彙不定義・WARN）：反論あり(部分的)**
  要件 1 受入 3 の "state transition names" は、遷移イベント名（started/completed）ではなく canonical な stage 名（Step A→D）を指す解釈も成り立つ。その解釈なら step_pipeline 固定と run_status enum で最低限充足しうる。純粋な遷移欠落というより P-15（step_status 語彙欠如）と同根の問題として扱うのが正確。

- **P-4（review_mode が「など」止まり・WARN）：反論あり(部分的)**
  要件 6 受入 6 は「at minimum ... を区別できれば足りる」と書いており、閉じた集合を要求していない。文言上は最小充足する。真の欠陥は「canonical（正本所有）」を謳いながら他 enum を厳密列挙しているのに review_mode だけ開放的という設計内の一貫性破れであり、要件未充足ではなく設計品質問題に reframe すべき。

- **P-5（evidence_class 遷移ルール未定義・WARN）：反論あり(部分的)**
  要件 6 受入 8 が要求するのは「語彙の定義」であり、遷移ロジックではない。candidate/valid/invalid/exploratory の語彙は定義済みで受入 8 は文言上充足する。遷移規則と exploratory の付与者・タイミング不明は実在する設計内部の曖昧さだが、要件網羅の欠落ではなく設計の未具体化として分類すべき。

- **P-6（runtime/ 命名の曖昧さ・WARN）：反論あり(部分的)**
  所有境界は §Placement Decisions と §Boundary Clarification で散文として明示されており、誤解リスクは仕様文で緩和済み。runtime が主要消費者である以上 `runtime/` 直下に置く選択も防御可能。severity は INFO 相当に過大。

- **P-7（meta layer 記述不完全・INFO）：反論なし**
  pattern assets を責務外にした結果 meta layer の foundation 担当範囲が空洞化している点は事実。INFO 据え置きで妥当。

- **P-8（impact_score フィールド不在・ERROR）：反論なし**
  維持。要件 3 受入 7 が 3 軸（severity / fix cost / downstream scope）を明示しているのに設計が「field 形状のみ固定」と述べてフィールド名へ展開していない。要件が内容を与えているのに設計が受け取らない型の欠陥。

- **P-9（failure_observation フィールド不在・ERROR）：反論なし**
  維持。受入 8 はフィールド名を与えていないため foundation が最小形状を発明する義務があるが、設計は「独立 schema とする」のみで形状ゼロ。P-8 より深刻ですらある。

- **P-10（validator_result フィールド不在・ERROR）：反論なし**
  維持。ただし性質は「要件網羅」ではなく「設計が自ら導入した artifact の自己完結性欠如」。invalidation_marker を列挙して validator_result を放置した非対称が問題。分類を設計内部完全性として明記すべき。

- **P-11（necessity_judgment 5-field 名を引き継いでいない・WARN）：反論あり(部分的)**
  severity 不整合を指摘する。P-8（impact_score）と P-11（necessity_judgment）は「要件が内容を明示／設計が再掲しない」という同一構造であるにもかかわらず、P-8 を ERROR、P-11 を WARN としている。判定基準が一貫しない。両者を同一 severity（ERROR 寄り）に揃えるか、P-8 を WARN に下げるかのいずれかが必要。

- **P-12（review_case の step record ネスト構造不明・WARN）：反論あり(部分的)**
  Boundary Clarification は「run directory layout と step file naming」「concrete storage」を runtime へ明示委譲している。steps を配列ネストするか別ファイルにするかは concrete storage 判断であり、意図的 scope 外の可能性が高い。論理的包含関係（review_case が step identity を参照する）の言及不足という、より弱い指摘に留めるべき。

- **P-13（layer1_framework.yaml 4 セクション未記述・WARN）：反論なし**
  維持。特に `asset_locations` は runtime の path 解決接合面であり形式未定義は実装阻害。なお override_policy の扱いは独立発見 A-1 として強化する。

- **P-14（traceability chain 未説明・WARN）：反論あり(部分的)**
  要件 4 受入 2 は traceability の「存在」を要求しており、narrative を要求していない。prompt_set_version → step_prompt_artifact_id → prompt_id の連結フィールドは揃っており、契約としては成立する。欠落は契約不在ではなく説明明瞭性であり severity 過大。

- **P-15（step_status 値語彙未定義・WARN）：反論なし**
  維持。他 3 status は enum 定義済みなのに step_status のみ欠落で、ログ間の一貫した状態参照が破れる。P-3 と束ねて扱うとなお説得力が増す。

- **P-16（immutability が慣習のみ・WARN）：反論あり(部分的)**
  foundation は contract spec であり、immutability を契約義務として宣言し強制手段を runtime へ委ねる構成は妥当。さらに §8 が validation/invalidation を別 artifact に分離する設計で immutability を部分的に裏付けている。severity は INFO 相当。

- **P-17（部分書込時の validator 最小条件未定義・INFO）：反論あり(部分的)**
  要件 6 受入 4 は「必須メタデータ欠如＝バリデーション失敗」という機械規則を既に与えており、これだけで部分書込は失敗判定可能。最小記録順序は強化提案であって欠落ではない。INFO でも過大気味。

- **P-18（hash アルゴリズム未定義・INFO）：反論あり(部分的)**
  指摘は支持するが severity を争う。要件 6 受入 7 が cross-project intake を明示要求しており、アルゴリズム不統一は cross-run/cross-project 比較を直接破壊する。これは契約レベルで固定すべき事項で、INFO ではなく WARN へ昇格すべき。

- **P-19（source_repository_id 形式・一意性未定義・INFO）：反論あり(部分的)**
  要件 6 受入 7 は「field names sufficient to identify」を要求し、フィールド名は存在する。形式・一意性は受入 7 文言の範囲外で、要件未充足ではない。集計実務上の設計品質メモとしては有効だが分類は INFO 据え置きで足りる。

- **P-20（テスト戦略完全欠如・ERROR）：反論なし**
  全面支持・補強。foundation は JSON Schema・YAML・frontmatter という機械検証可能 artifact を定義しているのに、schema lint・frontmatter parse・必須 section assertion が皆無。Completion Criteria が「説明できる」という narrative のみである点も併せて、最重要 ERROR。

- **P-21（旧 prototype 移行方針不記述・WARN）：反論あり(部分的)**
  実体上、要件 5・設計 §7 削除により v1 のパターン照合は LLM 呼び出しへ全面置換され、v1 evidence は別スキーマで移行対象が実質存在しない可能性が高い。真の欠陥は「クリーンスタート＝移行なし」と明記しないドキュメント欠落であり、severity は INFO 相当。

---

## パート2：主役が見落とした独立発見

形式：採番 / severity / 要件・箇所 / 表題 / 内容。

- **A-1 / ERROR / §Domain Model §1 ⇔ Boundary Context・Boundary Clarification / `override_policy` セクションの scope 越境**
  Boundary Context の Out of scope は「prompt override の選択順序」を明示除外し、Boundary Clarification も「prompt override の選択順序」を runtime 責務と断言している。にもかかわらず §1 は `override_policy` を layer1_framework.yaml の top-level section として foundation が固定すると列挙しており、設計が自らの境界宣言と矛盾している。主役は P-13 で「未記述」とのみ扱い、存在自体が scope 違反である点を見落とした。section を削除するか、foundation が固定するのは override 機構の有無のみで選択順序は runtime と明記する整合修正が必要。

- **A-2 / ERROR / §3 Run Metadata Contract ⇔ 要件 7 受入 3・要件 2 受入 4 / config を run に束ねる metadata フィールド不在**
  要件 7 受入 3 は「environment-level config は config に明示モデル化され、かつ run metadata に記録される場合のみ許可」と要求する。設計 §10 は config template を定義するが、§3 の必須 metadata 一覧に config 参照（config_version / config_hash 等）が一切無い。どの config がその run を生成したかを metadata だけで追跡できず、要件 7 受入 3 と要件 2 受入 4（config は runtime input であり hidden operator memory ではない）の機械追跡性が成立しない。主役は metadata 欠落を schema 系（P-8〜P-10）でしか見ておらず、この config↔run binding 欠落を見落とした。

- **A-3 / WARN / §3 metadata 表 ⇔ 要件 1 受入 5・要件 6 受入 2 / `schema_set_version` が要件にトレースされない追加必須フィールド**
  要件 1 受入 5 の最小束は protocol/prompt/runtime version であり、要件 6 受入 2 の superset 列挙にも "schema set version" は含まれない。設計 §3 は `schema_set_version` を必須フィールドとして追加しているが、これがどの受入由来か（要件 3 受入 3 の派生か）を Requirements Traceability で説明していない。foundation が契約超過の必須フィールドを無注釈で導入しており、要件↔設計トレーサビリティの穴である。主役の P-2/P-11 は逆方向（要件→設計の欠落）のみで、設計→要件の過剰方向を検出していない。

- **A-4 / WARN / §8 ⇔ 要件 6 受入 9 / 陳腐化伝播を機械的に履行する provenance 逆参照が schema に無い**
  設計 §8 は「無効化標識付与は下流派生成果物への陳腐化伝播義務を伴う」と契約宣言するが、review_case にも validator/invalidation artifact にも「どの派生成果物がこの run を参照しているか」を辿る逆参照フィールド（derived_from_run_ids 等）が存在しない。義務の存在だけ宣言し、それを下流が機械的に履行する schema hook を提供していないため、要件 6 受入 9 は宣言倒れになる。主役は P-5 で evidence_class 遷移は見たが、伝播履行を可能にする provenance 逆リンク欠落は見落とした。

- **A-5 / ERROR / §2・§4 finding ⇔ 要件 1 受入 4 / 「反証なし」を意図的結果として記録する schema フィールドが無い**
  要件 1 受入 4 は「adversarial が同意する場合でも、反証の不在自体を意図的結果として記録する」ことを明示要求する。設計 §2 はこの振る舞いを散文で再掲するが、§4 の finding schema には反証不在を deliberate outcome として記録する専用フィールド／フラグが無い。`counter_evidence_refs` の空配列は「反証を試みた結果ゼロ」と「反証を試みていない」を区別できず、受入 4 が要求する「不在の意図的記録」を schema レベルで担保できない。主役は Round 1 で受入 4 を網羅確認せず、この schema 化欠落を見落とした。

- **A-6 / WARN / §Shared Artifact Layout・Domain Model ⇔ 要件 3 受入 3 / schema 非互換 silent 編集を検出する versioning 機構の不在**
  要件 3 受入 3 は「versioned schema artifact を要求し、silent な非互換編集を禁止する」と命じる。設計は schema ファイル列挙と metadata 側 `schema_set_version` を持つが、schema ファイル自身に version/$id をどう持たせるか、何をもって「非互換編集」を検出するか（semver 規約・$id 必須・diff 検出規約）の機構が一切無い。要件 4 受入 5 は prompt について diff 履歴検出可能性を規定しているのに、schema には対応規約が欠落しており非対称。主役の P-2 は受入 9（必須/defer）に限定され、受入 3 の versioning 機構欠落は別論点として未検出。

---

## 総括（敵対役所見）

- 主役の ERROR 6 件（P-1, P-2, P-8, P-9, P-10, P-20）はいずれも実在。ただし P-1 は「規約は推測可能・具体物欠落」へ精密化、P-10 は「設計内部完全性」へ分類変更が必要。
- severity 一貫性破れを 1 件指摘：P-8（ERROR）と P-11（WARN）は同一構造であり判定基準が不整合。
- 過大評価 4 件：P-6・P-14・P-16・P-17 は契約 spec の性質上 INFO 相当へ降格が妥当。逆に過小評価 1 件：P-18 は cross-project intake 要件直撃のため WARN へ昇格すべき。
- 独立発見の重大度上位は **A-1（override_policy の scope 越境＝設計の自己矛盾）**、**A-2（config↔run binding 欠落）**、**A-5（反証不在の記録 schema 欠落＝要件 1 受入 4 の schema 化漏れ）** の 3 件で、いずれも主役の 10 ラウンドが検出していない要件未充足または境界違反である。

---

## 判断役レビュー（claude-opus-4-6）

# 判断役レビュー：dual-reviewer-foundation/design.md

---

## 判定一覧

### Round 1：要件全件の網羅

| # | 判定 | 根拠 |
|---|------|------|
| **P-1** | **must-fix** | 敵対役の精密化（規約は推測可能だが具体物が欠落）を採用するが、要件 4 受入 1 は「Steps A, B, and C」を列挙しており、成果物レイアウトに Step A/B が一切出現しないのは実装者が canonical 配置を確定できない実害がある。命名規約の明文化か、具体ディレクトリの追記が必要。 |
| **P-2** | **must-fix** | 敵対役の補強を支持。「必須に近い field」という表現は要件 3 受入 9 が要求する二値分類を能動的に曖昧化している。各 schema フィールドに `[mandatory-B1.0]` / `[deferred]` のマーカーを付すか、一覧表で明示するかのいずれかが必須。 |
| **P-3** | **should-fix** | 敵対役の「step 名と遷移イベント名の解釈が分離可能」という反論を部分採用。受入 3 文言は stage names を指す読みも成立し、step_pipeline で部分充足する。ただし P-15（step_status 語彙欠如）と合わせて「step 内ライフサイクルの語彙」を一箇所で定義すべき。 |
| **P-4** | **should-fix** | 敵対役の「受入 6 は at minimum であり閉じた集合を要求しない」という反論を採用。要件未充足ではない。ただし他 enum が閉じているのに review_mode だけ開放的という設計内一貫性の破れは修正すべき（拡張規約を注記するか enum を閉じるか）。 |
| **P-5** | **should-fix** | 敵対役の「受入 8 が要求するのは語彙の定義であり遷移論理ではない」という反論を採用。要件網羅の欠落ではなく設計内部の不完全。ただし設計自身が「candidate から遷移する」と述べているため、遷移ルールを書くか遷移記述を削除するか明確にすべき。 |

---

### Round 2：アーキテクチャ整合性

| # | 判定 | 根拠 |
|---|------|------|
| **P-6** | **leave-as-is** | 敵対役の反論を採用。所有境界は §Placement Decisions と §Boundary Clarification で散文明示されており、ディレクトリ名のみで所有者を伝えることは必須ではない。contract spec としてはこれで十分。 |
| **P-7** | **leave-as-is** | 両役とも INFO。pattern assets 責務外化に伴う meta layer の空洞化は後続 spec 整合時に自然解消する見込みであり、foundation 設計修正は不要。 |

---

### Round 3：データモデル・スキーマ詳細

| # | 判定 | 根拠 |
|---|------|------|
| **P-8** | **must-fix** | 要件 3 受入 7 が「finding severity, fix cost estimate, downstream effect scope」を明示的に命名しているにもかかわらず、設計がフィールド名ゼロのまま「形状のみ固定する」と述べているのは空約束。最低限の 3 フィールド名を記述する義務がある。 |
| **P-9** | **must-fix** | 要件 3 受入 8 はフィールド名を直接与えていないが「failure mode classification data structure」を要求しており、「独立 schema とする」と宣言しながら形状ゼロは実装不能。failure_type / missed_by_role / detected_at_step 等の最小形状を foundation が発明すべき。 |
| **P-10** | **must-fix** | 敵対役の分類修正（要件トレースではなく設計内部の自己完結性欠如）を採用するが、severity は維持。invalidation_marker が 6 フィールド列挙されているのに validator_result が形状ゼロは非対称であり、validator 実装者が何を書けばよいか判断できない。 |
| **P-11** | **should-fix** | 敵対役の「P-8 と同一構造なのに severity が異なる」という一貫性指摘は認める。ただし P-8 は内容ゼロであるのに対し P-11 は「5-field structure, final label, recommended action, optional override reason を固定する」と構造的言及がある点で一段軽い。should-fix として 5 フィールド名（requirement_link 等）を展開記述すべき。 |
| **P-12** | **leave-as-is** | 敵対役の反論を採用。Boundary Clarification が「run directory layout と step file naming」を明示的に runtime へ委譲しており、step record の物理ネスト構造は意図的な scope 外。論理的包含関係（review_case → steps 参照）は §5 の field list で最低限表現されている。 |

---

### Round 4：API 接合面の具体化

| # | 判定 | 根拠 |
|---|------|------|
| **P-13** | **should-fix** | 敵対役も同意。特に `asset_locations` は runtime の path 解決 API であり、形式（相対パスのキーバリューマップ等）を示さなければ runtime 設計が着手できない。`step_intents` も各 step の期待出力を補足する必要がある。`override_policy` は A-1 で別途 must-fix。 |
| **P-14** | **leave-as-is** | 敵対役の反論を採用。要件 4 受入 2 は traceability の「存在」を要求しており、説明の明瞭性は要求していない。prompt_set_version → step_prompt_artifact_id → prompt frontmatter の prompt_id という chain は field として設計に存在し、contract 充足。 |

---

### Round 5：アルゴリズム + 性能達成手段

該当なし確認。本 spec は contract 定義であり性能要件を含まない。Step D の「追加 LLM 呼び出しなし」は設計 §1 で明示済み。

---

### Round 6：失敗モード処理 + 観測性

| # | 判定 | 根拠 |
|---|------|------|
| **P-15** | **should-fix** | 両役とも支持。run_status / validator_status / human_signoff_status は全て enum 定義済みで step_status のみ語彙なし。P-3 と合わせ、step 内ライフサイクル語彙を metadata_contract または layer1_framework に追記すべき。 |
| **P-16** | **leave-as-is** | 敵対役の反論を採用。foundation は contract spec であり、immutability を「契約義務」として宣言した上で強制手段を runtime に委ねる構成は妥当。§8 で validation/invalidation を別 artifact に分離する設計が immutability の構造的裏付けになっている。 |
| **P-17** | **leave-as-is** | 敵対役の反論を採用。要件 6 受入 4「必須メタデータ欠如＝バリデーション失敗」が機械判定条件として既に成立しており、追加の最小記録順序方針は強化提案であって欠落ではない。 |

---

### Round 7：セキュリティ・プライバシー

| # | 判定 | 根拠 |
|---|------|------|
| **P-18** | **should-fix** | 敵対役の昇格提案を採用。要件 6 受入 7 が cross-project evidence intake を明示要求しており、hash アルゴリズムの不統一は cross-run/cross-project 比較を直接破壊する。foundation が「使用アルゴリズムを metadata または config に記録すること」を contract として要求すべき。 |
| **P-19** | **leave-as-is** | 主役・敵対役とも INFO。形式の標準化は operational concern であり、field 存在で受入 7 文言は充足。 |

---

### Round 8：依存選定

該当なし確認。YAML / JSON Schema / Markdown+frontmatter はいずれも標準的かつ外部依存なし。Req 7 の repo-contained ルールに適合。

---

### Round 9：テスト戦略

| # | 判定 | 根拠 |
|---|------|------|
| **P-20** | **must-fix** | 両役とも最重要 ERROR として一致。foundation は JSON Schema・YAML・frontmatter という機械検証可能 artifact を定義しているのにテスト手段が皆無。後続 4 spec がこの基盤に依存する以上、schema lint / YAML parse / frontmatter 必須 field assertion 等の最低限の検証手順を設計に含めるべき。Completion Criteria の「説明できる」も自動検証可能な基準に置き換える必要がある。 |

---

### Round 10：移行戦略

| # | 判定 | 根拠 |
|---|------|------|
| **P-21** | **should-fix** | 敵対役の「実質クリーンスタートの可能性が高い」という観察を採用。移行計画の策定は不要だが、「本 spec はクリーンスタートであり v1 evidence との互換維持は行わない」と 1 行明記すべき。記述がないと実装者が旧資産との互換性を誤って考慮する。 |

---

## 敵対役独立発見への判定

| # | 判定 | 根拠 |
|---|------|------|
| **A-1** | **must-fix** | Boundary Context（Out of scope）と Boundary Clarification がともに「prompt override の選択順序」を明示的に runtime 委譲としているにもかかわらず、§1 が `override_policy` を foundation 所有の top-level section として列挙するのは自己矛盾。section を削除するか、foundation が固定するのは「override 機構の存在宣言のみ」であり選択順序は runtime 責務と明記して section 名を変更するか、いずれかで解消必須。 |
| **A-2** | **must-fix** | 要件 7 受入 3「environment-level config は config に明示モデル化され、かつ run metadata に記録される場合のみ許可」と要件 2 受入 4「config は runtime input」を合わせると、どの config がその run を生成したかを metadata から追跡できなければならない。§3 の必須 metadata 一覧に config_version / config_hash 等が欠落しており、機械追跡性が成立しない。 |
| **A-3** | **should-fix** | `schema_set_version` は要件 3 受入 3（versioned schema artifacts）の自然な設計展開として正当だが、Requirements Traceability 表にその派生元が記載されていない。トレーサビリティ注記を追加すべき。field 自体の削除は不要。 |
| **A-4** | **should-fix** | 陳腐化伝播義務の宣言は要件 6 受入 9 を充足するが、下流が義務を機械的に履行するための最低限のガイダンス（「下流 schema は参照元 run_id を保持すべし」等）を foundation が注記しないと宣言倒れになるリスクがある。具体 schema 定義は下流に委ねてよいが、接合面の方針を 1 文加えるべき。 |
| **A-5** | **must-fix** | 要件 1 受入 4 は「反証の不在自体を意図的結果として記録する」ことを明示要求する。`counter_evidence_refs` の空配列は「反証を試みた結果ゼロ」と「反証を試みていない」を区別できず、受入 4 が要求する deliberate outcome の記録を schema レベルで担保できない。finding schema に `challenge_attempted: boolean` または `adversarial_outcome` enum 等の専用フィールドが必要。 |
| **A-6** | **should-fix** | 要件 3 受入 3「versioned schema artifacts / silent 非互換編集の禁止」に対し、prompt artifact（§6）は frontmatter に version を持たせる機構を記述しているのに、schema ファイル（JSON Schema）には対応する versioning 機構（$id 必須 / semver 規約 / 破壊的変更の定義）が欠落し非対称。 |

---

## 敵対役反論の採否まとめ

- **採用**（severity 変更）：P-6 を leave-as-is へ降格、P-12 を leave-as-is へ降格、P-14 を leave-as-is へ降格、P-16 を leave-as-is へ降格、P-17 を leave-as-is へ降格、P-18 を should-fix へ昇格
- **部分採用**（精密化のみ、判定据え置き）：P-1（規約推測可能の注記を加えるが must-fix 維持）、P-3（P-15 との統合を推奨）、P-4（設計一貫性問題へ reframe）、P-5（設計内部不完全へ reframe）、P-10（分類修正を受容）
- **不採用**：P-11 の「P-8 と同一 severity にすべき」（構造的言及の有無で一段差を認める）、P-21 の「INFO 相当」（クリーンスタート明記が無いこと自体が実装者の誤解を招く設計欠陥）

---

## 集計

- **must-fix：9 件** — P-1, P-2, P-8, P-9, P-10, P-20, A-1, A-2, A-5
- **should-fix：11 件** — P-3, P-4, P-5, P-11, P-13, P-15, P-18, P-21, A-3, A-4, A-6
- **leave-as-is：7 件** — P-6, P-7, P-12, P-14, P-16, P-17, P-19

---

## must-fix の帰属別分類

### dual-reviewer-foundation 設計固有（9 件すべて）

- **P-1** — Step A/B プロンプト配置の具体化（成果物レイアウトへの追記）
- **P-2** — 各 schema フィールドの B-1.0 必須 / deferred 区別の明記
- **P-8** — impact_score の最低 3 フィールド定義
- **P-9** — failure_observation の最小形状定義
- **P-10** — validator_result の形状定義（invalidation_marker との対称性確保）
- **P-20** — テスト戦略の追加（schema lint / frontmatter parse / 必須 section assertion）
- **A-1** — override_policy セクションの scope 矛盾解消（削除または scope 限定明記）
- **A-2** — run metadata への config 参照フィールド追加（config_version / config_hash）
- **A-5** — finding schema への反証不在記録用フィールド追加

### 要件への差し戻し

なし。要件は十分に具体的であり、不足は設計側の対応漏れに帰属する。

### 他 spec 設計への波及

なし。9 件すべて foundation 設計文書内で完結する修正であり、他 spec の requirements / design を変更する必要はない。ただし修正後、downstream 4 spec の設計が foundation の新フィールド（A-2 の config 参照、A-5 の adversarial outcome フィールド）を活用する改訂が推奨される。これは波及というより下流側の任意強化であり、foundation の修正自体は自己完結する。
