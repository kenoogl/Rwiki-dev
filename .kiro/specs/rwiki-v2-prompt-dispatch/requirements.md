# Requirements Document

## Project Description (Input)

Rwiki v2 の distill タスクは、L1 raw を L2 / review 候補に蒸留する際に複数の skill（`paper_summary` / `multi_source_integration` / `personal_reflection` 等の知識生成 12 種ほか）から最適な 1 つを選ばなければならない。選択ロジックが固定されていないと、毎回ユーザーが `--skill` を明示する負担が発生し、逆に固定ヒューリスティックだけで決定するとコンテンツによって最適 skill が変わる現実に追従できない（精度低下）。

本 spec（Spec 3、Phase 4）は §2.8 Skill library 原則を distill タスク側から接続するレイヤーとして、distill 起動時の **スキル選択メカニズム** を定義する。具体的には、(a) スキル選択の優先順位（明示 `--skill` → frontmatter `type:` → `categories.yml` の `default_skill` → LLM 毎回判定）、(b) LLM 毎回判定方式（コンテンツを毎回読み込み、精度優先で最適 skill を推論）、(c) `type:` または明示指定と LLM 推論結果が食い違う場合のユーザー確認フロー、(d) 解決後 skill が AGENTS/skills/ に存在しない / install されていない場合の `generic_summary` fallback、(e) Spec 1 が確定済みの `categories.yml` `default_skill` inline 方式と frontmatter `type:` の dispatch hint 利用契約、(f) Spec 2 の `applicable_categories` を解釈に取り込む契約、を所管する。

本 spec は dispatch ロジック自体を所管するが、skill 内容（prompt / 出力 schema）は Spec 2、frontmatter フィールド宣言と vocabulary は Spec 1、`rw distill` CLI の引数 parse / exit code / 出力整形は Spec 4、Perspective / Hypothesis の skill 呼び出し（固定 skill `perspective_gen` / `hypothesis_gen`、dispatch 対象外）は Spec 6 が所管する。

出典 SSoT: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §7.2 Spec 3（line 1556-1573）/ §6.1 distill / §1.2 LLM 非依存 / §11.2 v0.7.10 決定 6-1（Perspective / Hypothesis dispatch 対象外）。Upstream: `rwiki-v2-foundation`（13 中核原則・用語集）/ `rwiki-v2-classification`（frontmatter `type:`、`categories.yml` の inline `default_skill` 方式）/ `rwiki-v2-skill-library`（skill 一覧、`applicable_categories`、`generic_summary` fallback）。

## Introduction

本 requirements は、Rwiki v2 の Spec 3 として distill タスクの **スキル選択（dispatch）メカニズム** を、user / operator から観測可能な振る舞いとして定義する。読者は Spec 3 の実装者と、本 spec の dispatch を呼び出す Spec 4（cli-mode-unification、`rw distill` CLI）/ Spec 6（perspective-generation、本 spec の対象外確認）/ Spec 2（skill-library、本 spec が解釈する skill メタデータの提供元）の起票者である。

本 spec が SSoT として固定するのは、(1) 5 段階優先順位（明示 `--skill` → frontmatter `type:` → `categories.yml` の `default_skill` → `applicable_input_paths` glob match → LLM 毎回判定）の判断順序とその個別実行条件、(2) LLM 毎回判定の振る舞い契約、(3) `type:` / 明示指定と LLM 推論の不一致時のコンセンサス確認手順、(4) skill 欠如時の `generic_summary` fallback 規約、(5) 解決済み skill 名と input file の組を呼び出し側（Spec 4）に返却する内部契約、(6) 上位 spec（Spec 1 / Spec 2）との coordination 契約である。

本 spec が想定する subject は次の 2 種類である。

- **Skill Dispatcher**: distill 起動時に呼び出され、(skill_name, input_file) を解決する論理コンポーネント。本 spec が振る舞いを規定する中核 subject
- **LLM Skill Inferencer**: Skill Dispatcher が呼び出す内部 step。LLM CLI を介してコンテンツを読み込み最適 skill を推論する subroutine

本 spec は Perspective / Hypothesis 生成（Spec 6）の skill 呼び出しに **介入しない**。Spec 6 は固定 skill（`perspective_gen` / `hypothesis_gen`）を直接呼び、本 spec の dispatch を経由しない。

## Boundary Context

- **In scope**:
  - distill タスク（`rw distill`）起動時のスキル選択 5 段階優先順位の判断ロジック（明示 `--skill` → frontmatter `type:` → `categories.yml` の `default_skill` → `applicable_input_paths` glob match → LLM 毎回判定）
  - LLM 毎回判定方式の振る舞い契約（毎回コンテンツを読み込み、cache せず推論、精度優先）
  - 明示 `--skill` 指定時の最優先扱いと、LLM 推論結果との食い違い検出 + ユーザー確認フロー
  - frontmatter `type:` 値が存在する場合の LLM 推論結果とのコンセンサス確認手順
  - 解決された skill 名が `AGENTS/skills/` に存在しない、または `status` が `active` でない場合の `generic_summary` fallback 規約
  - `categories.yml` の inline `default_skill` field を読み取る契約（Spec 1 ↔ Spec 3 coordination で確定済の inline 方式）
  - `AGENTS/skills/*.md` frontmatter `applicable_categories` を解釈し、LLM 推論時のヒントおよび整合 check に用いる契約（Spec 2 ↔ Spec 3 coordination、L3 wiki content category 系統 dispatch hint）
  - `AGENTS/skills/*.md` frontmatter `applicable_input_paths` を解釈し、Requirement 1 段階 3.5 の path glob match dispatch および LLM 推論時のヒントとして用いる契約（Spec 2 ↔ Spec 3 coordination で 2 系統 dispatch logic として確定、L1 raw 入力 path 系統 dispatch hint、extended glob 互換）
  - dispatch 結果として返却される (skill_name, input_file, dispatch_reason) の内部契約（Spec 4 が呼び出して使用する）
  - LLM CLI 呼び出しの subprocess timeout 設定の必須化（roadmap.md「v1 から継承する技術決定」継承）
  - 本 spec が `rw distill` 以外の自然言語意図解釈（`rw chat` 内で「これを蒸留して」等）から呼び出される場合も、同一 dispatch ロジックを共有する規約
- **Out of scope**:
  - skill 内容そのもの（prompt / Processing Rules / Output schema、Spec 2 が所管）
  - skill ファイルの 8 section スキーマ・frontmatter フィールド定義・install validation（Spec 2）
  - frontmatter `type:` field の宣言と vocabulary 整合（Spec 1 が所管。本 spec は読み取り側）
  - `categories.yml` のスキーマ定義と編集 CLI（Spec 1）
  - `rw distill` CLI の引数 parse / `--skill` / `--extend` flag / 出力整形 / exit code（Spec 4 が所管。本 spec は dispatch 内部契約のみ）
  - Perspective / Hypothesis 生成での skill 呼び出し（Spec 6 が固定 skill `perspective_gen` / `hypothesis_gen` を直接呼ぶ。本 spec の dispatch を経由しない）
  - Graph 抽出 skill（`entity_extraction` / `relation_extraction`）の起動 dispatch（Spec 4 の `rw extract-relations` が直接呼ぶ。本 spec の対象外）
  - lint 支援 skill（`frontmatter_completion`）の起動（Spec 4 の `rw lint --fix` が直接呼ぶ）
  - Custom skill 作成・install フロー（Spec 2）
  - Skill lifecycle（deprecate / retract / archive、Spec 7）
  - LLM CLI 抽象層の実装（v0.7.12 §1.2 で「Spec 3 で抽象層を定義」と記載されているが、本 spec の dispatch 範囲では LLM CLI を「subprocess timeout 付きで呼び出す」抽象を前提とし、抽象層の API 設計詳細は本 spec の design phase で扱う）
- **Adjacent expectations**:
  - 本 spec は Foundation（Spec 0）が固定する 13 中核原則 / 用語集 / 3 層アーキテクチャ を **唯一の引用元** として参照し、独自定義による再解釈・再命名を行わない。Foundation の用語と矛盾する記述が必要になった場合は先に Foundation を改版し、その後本 spec を更新する（roadmap.md「Adjacent Spec Synchronization」運用ルールに従う）。
  - 本 spec は Spec 1 が確定済みの (a) frontmatter 推奨フィールド `type:` の存在、(b) `.rwiki/vocabulary/categories.yml` の inline `default_skill` field 方式、を前提として参照する。本 spec はこれらフィールドのスキーマを再定義しない。
  - 本 spec は Spec 2 が SSoT として固定する skill カタログ（initial 15 種のうち distill 向け 12 種 + `generic_summary` fallback）と各 skill frontmatter `applicable_categories` を入力として参照する。本 spec は skill メタデータを再定義・再命名しない。
  - 本 spec の dispatch を呼び出す Spec 4 は、本 spec が返却する (skill_name, input_file, dispatch_reason) を `rw distill` 実行に渡す。Spec 4 は本 spec の判断ロジックを再実装しない。
  - 本 spec は Spec 6 が独立 CLI（`rw perspective` / `rw hypothesize`）から固定 skill を直接呼ぶ事実を認知し、Perspective / Hypothesis 生成は本 spec の dispatch 対象外であることを規定するに留める。
  - 本 spec は roadmap.md「v1 から継承する技術決定」のうち、(a) Severity 4 水準（CRITICAL / ERROR / WARN / INFO）、(b) exit code 0/1/2 分離、(c) LLM CLI subprocess timeout 必須、を継承する。

## Requirements

### Requirement 1: スキル選択 5 段階優先順位の規定

**Objective:** As a Spec 4 起票者および distill タスク利用者, I want スキル選択が 5 段階の固定優先順位（明示 `--skill` → frontmatter `type:` → `categories.yml` の `default_skill` → `applicable_input_paths` glob match → LLM 毎回判定）で決定される, so that distill 起動時に常に予測可能な順序で skill が解決され、明示意図がある場合は必ず尊重され、L1 raw 入力対象 skill が path から deterministic に dispatch される。

#### Acceptance Criteria

1. The Skill Dispatcher shall スキル選択を以下 5 段階の優先順位で評価することを規定する：(1) 明示 `--skill <name>` 指定 → (2) 入力ファイルの frontmatter `type:` 値からの推定 → (3) 入力ファイルが配置された categories（`.rwiki/vocabulary/categories.yml` のカテゴリエントリ）の `default_skill` field → (3.5) 入力ファイル path に対する `AGENTS/skills/*.md` の `applicable_input_paths` glob match（Spec 2 Requirement 3.2 で定義された L1 raw 入力 path glob 一覧、extended glob 互換）→ (4) LLM 毎回判定。
2. While 上位段階で候補が確定可能な場合, the Skill Dispatcher shall 下位段階を **評価しない**（短絡評価）。ただし Requirement 3 / Requirement 4 のコンセンサス確認が必要な場合は、その範囲で例外的に LLM 推論を併走させる。
3. When 段階 1 で `--skill <name>` が指定された, the Skill Dispatcher shall 当該 skill を最優先候補として扱い、Requirement 3 のコンセンサス確認のみ追加で実行することを規定する。
4. When 段階 2 で frontmatter `type:` 値が存在する, the Skill Dispatcher shall 当該 `type:` 値から派生する skill 候補を確定し、Requirement 4 のコンセンサス確認を経て決定することを規定する。
5. When 段階 3 で入力ファイルが属する category の `default_skill` が `categories.yml` に登録されている, the Skill Dispatcher shall 当該 `default_skill` を候補として確定することを規定する。
6. When 段階 3.5 で入力ファイル path が `AGENTS/skills/*.md` の `applicable_input_paths` glob と match する skill が **唯一** に絞れる, the Skill Dispatcher shall 当該 skill を候補として確定することを規定する。path match の評価対象は frontmatter `status: active` の skill のみとし（段階 3.5 候補絞り込み時に非 active skill を予め除外することで、Requirement 6.1 の dispatch 実行直前 check と整合させ、無駄な path match 計算を回避する）、path match は extended glob 互換（POSIX glob `*` / `?` / `[...]` + `**` recursive match、Spec 2 Requirement 3.2 と整合）として評価する。段階 3.5 で確定した候補は段階 1 / 2 のコンセンサス確認対象外（配置から自然に決まる deterministic dispatch、段階 3 と同じ扱い）とする。
7. While 段階 3.5 で複数 skill が `applicable_input_paths` glob match する, the Skill Dispatcher shall 曖昧性回避のため段階 3.5 をスキップして段階 4 の LLM 毎回判定に進むことを規定し、WARN severity で「path match 複数該当のため LLM 推論にエスカレート」を呼び出し側（Spec 4）に通知することを規定する。
8. When 段階 1〜3.5 のいずれでも候補が確定しない, the Skill Dispatcher shall 段階 4 の LLM 毎回判定に進むことを規定する。
9. The Skill Dispatcher shall 各段階で確定した候補に対し、Requirement 6 の skill 存在確認（`AGENTS/skills/<name>.md` 存在 + `status: active`）を実施し、不存在 / 非 active の場合は Requirement 6 の `generic_summary` fallback に降格することを規定する。

### Requirement 2: LLM 毎回判定方式の振る舞い契約

**Objective:** As a distill タスク利用者および Spec 4 起票者, I want LLM 判定が毎回コンテンツを読み込んで推論を行い、cache に依存しない（精度優先）, so that コンテンツが既存カテゴリの典型から外れる場合でも、その時点で最適な skill を選べる。

#### Acceptance Criteria

1. When 段階 4（LLM 毎回判定）が発火する, the LLM Skill Inferencer shall 入力ファイルのコンテンツ全体（または LLM CLI が許容する最大長まで）を **その都度** 読み込み、Spec 2 が提供する skill カタログを参照対象として推論を行うことを規定する。
2. The LLM Skill Inferencer shall 推論結果として「推奨 skill 名」「推論根拠の簡潔な説明（人間可読）」「信頼度（任意、推論器が出力可能な場合）」を内部に保持し、Skill Dispatcher に返却することを規定する。
3. The LLM Skill Inferencer shall 推論時に Spec 2 が SSoT として提供する各 skill の frontmatter `applicable_categories` および `applicable_input_paths`（Spec 2 Requirement 3.2 で定義された optional field 2 種、L3 wiki content category 系統と L1 raw 入力 path 系統）を **入力ヒント** として LLM プロンプトに含めることを規定する。
4. The LLM Skill Inferencer shall 推論結果を **cache しない** ことを規定する（同一ファイルを再 distill する場合も毎回推論を再実行する。精度優先のため）。
5. While LLM CLI を呼び出す場合, the LLM Skill Inferencer shall subprocess timeout を必須設定とすることを規定する（roadmap.md「v1 から継承する技術決定」、`call_claude()` ハングリスク回避）。timeout のデフォルト値は本 spec の design phase で確定する。
6. If LLM CLI 呼び出しが timeout / 異常終了 / 推論失敗で結果を返せない, then the Skill Dispatcher shall Requirement 6 の `generic_summary` fallback に降格し、ERROR severity ではなく WARN severity でその旨を呼び出し側（Spec 4）に通知することを規定する。
7. If LLM 推論結果として返された skill 名が `AGENTS/skills/` に存在しない, then the Skill Dispatcher shall Requirement 6 の `generic_summary` fallback に降格することを規定する。

### Requirement 3: 明示 `--skill` 指定と LLM 推論結果のコンセンサス確認

**Objective:** As a distill タスク利用者, I want 明示 `--skill` を最優先で尊重しつつ、LLM 推論結果と明示指定が食い違う場合にユーザー確認の機会が提供される, so that 誤った skill 名を意図せず指定したり、コンテンツに対し明らかに不適切な skill を強行したりする事故を防げる。

#### Acceptance Criteria

1. While 段階 1 で `--skill <name>` が指定されている, the Skill Dispatcher shall 当該 skill を最優先扱いとしつつ、追加で LLM 推論（Requirement 2）を **併走** させ、推論結果と明示指定の一致 / 不一致を判定することを規定する。
2. If 明示指定された skill と LLM 推論結果が **一致** する（同一 skill 名）, then the Skill Dispatcher shall コンセンサス成立として確認なしに明示 skill を採用することを規定する。
3. If 明示指定された skill と LLM 推論結果が **不一致** である, then the Skill Dispatcher shall ユーザーに対して「明示指定」「LLM 推論結果」「LLM 推論根拠」を提示し、(a) 明示指定を採用 / (b) LLM 推論を採用 / (c) abort のいずれかを選ぶ確認プロンプトを発行することを規定する。
4. While ユーザーが対話を許容しない実行モード（`--auto` 等の Spec 4 所管 flag）で起動された場合, the Skill Dispatcher shall コンセンサス不一致時にも明示指定を採用し、WARN severity で「LLM 推論と不一致だが明示指定を採用」を呼び出し側（Spec 4）に通知することを規定する。
5. If LLM 併走推論が timeout / 異常終了 / 推論失敗で結果を返せない, then the Skill Dispatcher shall コンセンサス確認をスキップし、明示指定をそのまま採用しつつ INFO severity で「LLM 併走推論失敗」を通知することを規定する（明示指定の優先性を維持するため）。
6. The Skill Dispatcher shall コンセンサス確認の対話 UI 詳細（プロンプト文言・キー入力受付方式）を Spec 4（CLI / `rw chat` 対話レイヤー）の所管とし、本 spec は確認の必要性とユーザーが選べる 3 択（明示採用 / LLM 採用 / abort）の振る舞い契約のみを規定することを明示する。

### Requirement 4: frontmatter `type:` と LLM 推論結果のコンセンサス確認

**Objective:** As a distill タスク利用者, I want frontmatter `type:` がある場合に LLM 推論結果との整合が確認され、不一致時にユーザーに通知される, so that ファイルに記録された type ヒントと現実のコンテンツのドリフトを検出でき、誤分類された frontmatter のまま distill が進行することを防げる。

#### Acceptance Criteria

1. While 段階 2 で frontmatter `type:` 値が存在する（明示 `--skill` 指定なし）, the Skill Dispatcher shall `type:` から派生する候補 skill を確定しつつ、追加で LLM 推論（Requirement 2）を **併走** させ、推論結果との一致 / 不一致を判定することを規定する。
2. If frontmatter `type:` から派生した skill と LLM 推論結果が **一致** する, then the Skill Dispatcher shall コンセンサス成立として確認なしに当該 skill を採用することを規定する。
3. If frontmatter `type:` から派生した skill と LLM 推論結果が **不一致** である, then the Skill Dispatcher shall ユーザーに対して「`type:` 由来候補」「LLM 推論結果」「LLM 推論根拠」を提示し、(a) `type:` 由来を採用 / (b) LLM 推論を採用 / (c) abort のいずれかを選ぶ確認プロンプトを発行することを規定する。
4. While ユーザーが対話を許容しない実行モードで起動された場合, the Skill Dispatcher shall コンセンサス不一致時に LLM 推論結果を採用する（精度優先方針、frontmatter `type:` はあくまで「ヒント」であり権威ではない）ことを規定し、WARN severity で「`type:` と不一致のため LLM 推論を採用」を通知することを規定する。
5. The Skill Dispatcher shall frontmatter `type:` 値を skill 候補に変換する具体的マッピング（`type:` 値 → skill 名）を、Spec 1 の `categories.yml` `recommended_type` と Spec 2 の `applicable_categories` の整合表から導出することを規定する。マッピング表自体は本 spec の design phase で確定する。
6. If frontmatter `type:` 値が Spec 1 / Spec 2 のいずれの整合表にも該当しない（許可値外）, then the Skill Dispatcher shall 段階 2 をスキップして段階 3（`categories.yml` の `default_skill`）に降格することを規定し、INFO severity で「`type:` 値 unknown のため次段階に降格」を通知することを規定する。
7. If 入力ファイルの frontmatter 自体が YAML として parse できない（部分破損・syntax error 等）, then the Skill Dispatcher shall 段階 2 をスキップして段階 3 以降に進むことを規定し、WARN severity で「frontmatter parse 失敗のため `type:` ヒントを利用不可、後続段階で dispatch 継続」を呼び出し側（Spec 4）に通知することを規定する。本規定は dispatch の継続性を優先し、frontmatter 整合性の根本検知は Spec 1 lint task（Spec 1 Requirement 9 系）に委譲する二重防御として位置付ける。

### Requirement 5: `categories.yml` の `default_skill` 読み取り契約

**Objective:** As a Spec 1 起票者と本 spec の利用者, I want 段階 3 で `categories.yml` の inline `default_skill` field を直接読み取り、別ファイル（例: `category_skill_map.yml`）に分離しない, so that vocabulary の単一源泉性が保たれ、ユーザーが 1 ファイルで category と skill mapping を管理できる。

#### Acceptance Criteria

1. The Skill Dispatcher shall 段階 3 評価時に `.rwiki/vocabulary/categories.yml` を起動時に読み込み、入力ファイルが属する category エントリの `default_skill` field を参照することを規定する。
2. The Skill Dispatcher shall `categories.yml` の inline `default_skill` field 方式を採用することを Spec 1 ↔ Spec 3 coordination 確定事項として継承し、別ファイルへの分離は採用しないことを明示する（Spec 1 Requirement 7.2 / Requirement 11.2 と整合）。
3. While 入力ファイルがどの category にも明示的に属していない（推奨カテゴリディレクトリ外配置、`type:` 未指定）, the Skill Dispatcher shall 段階 3 をスキップして段階 4 に進むことを規定する（Spec 1 Requirement 1 の「カテゴリは強制ではなく推奨」原則と整合）。
4. While 入力ファイルが属する category の `default_skill` field が空（未設定）である, the Skill Dispatcher shall 段階 3 をスキップして段階 4 に進むことを規定し、INFO severity で「category `<name>` に default_skill 未設定のため LLM 判定」を通知することを規定する。
5. The Skill Dispatcher shall `categories.yml` を **cache せず** 起動毎に最新を反映することを規定する（Spec 1 Requirement 9.3 と整合、vocabulary 変更が即座に dispatch に反映されるため）。
6. If `categories.yml` がそもそも配置されていない, then the Skill Dispatcher shall 段階 3 をスキップして段階 4 に進むことを規定し、INFO severity で「vocabulary 未初期化」を通知することを規定する（Spec 1 Requirement 9.4 と整合）。
7. The Skill Dispatcher shall `categories.yml` の `default_skill` 値が `AGENTS/skills/` に存在する skill 名であることの整合 check を Spec 1 の lint task に委譲し（Spec 1 Requirement 11.3 と整合）、本 spec の dispatch 実行時には不存在を Requirement 6 の `generic_summary` fallback で扱うことを規定する。
8. If `categories.yml` が YAML として parse できない（部分破損・syntax error 等）, then the Skill Dispatcher shall 段階 3 をスキップして段階 3.5 以降に進むことを規定し、WARN severity で「`categories.yml` parse 失敗のため category default を利用不可、後続段階で dispatch 継続」を呼び出し側（Spec 4）に通知することを規定する。本規定は Spec 1 Requirement 9.7 の lint task partial broken handling 原則（「parse 不可は当該 vocabulary 関連検査のみ ERROR で fail、他検査は継続」）と整合的に、本 spec の dispatch では当該段階のみスキップして dispatch 継続を優先し、`categories.yml` の根本修復は Spec 1 lint task / vocabulary 編集（Spec 1 Requirement 8）に委譲する二重防御として位置付ける。

### Requirement 6: skill 欠如時の `generic_summary` fallback 規約

**Objective:** As a distill タスク利用者, I want 5 段階のいずれかで解決された skill が `AGENTS/skills/` に install されていない / `status` が `active` でない場合に、`generic_summary` skill が確実に fallback として呼ばれる, so that 任意の入力ファイルに対して distill が必ず実行可能で、skill 不存在を理由に distill が破綻することを防げる。

#### Acceptance Criteria

1. The Skill Dispatcher shall 5 段階のいずれかで解決された skill 候補に対して、`AGENTS/skills/<name>.md` の存在および frontmatter `status: active` を **dispatch 実行直前** に check することを規定する。
2. If 解決済み skill が `AGENTS/skills/` に存在しない（未 install / install 後に削除）, then the Skill Dispatcher shall `generic_summary` skill を fallback として採用することを規定する。
3. If 解決済み skill の frontmatter `status` が `active` 以外（`deprecated` / `retracted` / `archived`）, then the Skill Dispatcher shall `generic_summary` skill を fallback として採用することを規定する。
4. While `generic_summary` fallback が発動する場合, the Skill Dispatcher shall WARN severity で「(元の解決 skill 名) が利用不可のため generic_summary に fallback」を呼び出し側（Spec 4）に通知することを規定する。
5. If `generic_summary` skill 自体も `AGENTS/skills/` に存在しない / `status: active` でない, then the Skill Dispatcher shall ERROR severity で「fallback skill 不在」を通知し、distill 起動を拒否することを規定する（exit code 2 = FAIL 検出 に該当、Spec 4 が exit code 制御）。
6. The Skill Dispatcher shall 明示 `--skill <name>` で指定された skill が不存在の場合も同じ fallback ロジックを適用することを規定する（明示指定の優先性は「指定先 skill が利用可能な場合のみ」という暗黙の前提を Requirement 6 で明文化）。
7. The Skill Dispatcher shall fallback 採用は Requirement 1 の優先順位段階に **依存しない**（どの段階で解決された候補でも、不存在なら一律 `generic_summary` fallback）ことを規定する。

### Requirement 7: dispatch 結果の返却契約（Spec 4 が呼び出すための内部 API）

**Objective:** As a Spec 4 起票者, I want 本 spec の Skill Dispatcher が返却する内部結果オブジェクトの構造（解決 skill 名・入力ファイル・dispatch 経緯）が固定されている, so that Spec 4 が `rw distill` 実装時に dispatch 結果を予測可能な形で受け取り、後続 skill 実行に渡せる。

#### Acceptance Criteria

1. The Skill Dispatcher shall dispatch 完了時に返却する結果オブジェクトの必須フィールドとして以下を規定する。
   - `skill_name`: 解決された skill 名（snake_case 文字列、Spec 2 の skill カタログに存在する名前または `generic_summary`、`aborted` 時は空文字列または明示的な sentinel 値、Requirement 7.3 と整合）
   - `input_file`: distill 対象ファイルの絶対 path
   - `dispatch_reason`: dispatch 経緯（以下 Requirement 7.2 の enumeration 値）
   - `severity`: 通知 severity（CRITICAL / ERROR / WARN / INFO のいずれか、Foundation Requirement 11 / roadmap.md と整合、複数通知発生時は最重 severity を採用、Requirement 11.4 と整合）
   - `notes`: 人間可読な補足メッセージ（コンセンサス不一致の詳細、fallback 理由、aborted 時の経緯等を集約、Requirement 11.4 と整合）
2. The Skill Dispatcher shall `dispatch_reason` の値域を以下の enumeration として規定する：`explicit_match`（段階 1 で明示指定 + LLM コンセンサス成立）/ `explicit_user_chosen`（段階 1 不一致 + ユーザーが明示採用）/ `explicit_llm_chosen`（段階 1 不一致 + ユーザーが LLM 採用）/ `type_match`（段階 2 で `type:` + LLM コンセンサス成立）/ `type_user_chosen`（段階 2 不一致 + ユーザーが `type:` 採用）/ `type_llm_chosen`（段階 2 不一致 + ユーザーが LLM 採用 / `--auto` 時の自動 LLM 採用）/ `category_default`（段階 3 で `categories.yml` `default_skill` 採用）/ `path_match`（段階 3.5 で `applicable_input_paths` glob match による唯一 skill 確定、Requirement 1.6 と整合）/ `llm_inference`（段階 4 で LLM 推論採用）/ `fallback_generic_summary`（Requirement 6 fallback 発動）/ `aborted`（コンセンサス確認でユーザーが abort 選択）。
3. While `aborted` を返却する場合, the Skill Dispatcher shall `skill_name` を空文字列または明示的な sentinel 値とし、Spec 4 が distill 実行を起動しない契約を提供することを規定する（exit code 2 / 0 のいずれを返すかは Spec 4 所管）。aborted 時の `severity` は **INFO**（ユーザー選択による正常な abort、dispatch 失敗ではなく user intent の表明として扱う、Foundation Requirement 11 の severity 4 水準内に収め、Requirement 11.2 INFO 列挙と整合）とし、`notes` には abort 時のコンセンサス確認段階（段階 1 / 段階 2）と提示された候補（明示指定 / `type:` 由来 / LLM 推論結果）を集約することを規定する。
4. The Skill Dispatcher shall 返却オブジェクトの構造（フィールド名・型・enumeration 値域）を本 spec の design phase で具体的データ構造として固定し、Spec 4 が当該構造を入力 contract として `rw distill` を実装する責務分離を明示する。
5. If 本 spec が dispatch 結果オブジェクトの構造を変更する必要が生じた, then the Skill Dispatcher shall 変更を Spec 4 と先行合意した上でしか反映できない手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を本 requirements に参照点として残すことを規定する。

### Requirement 8: Spec 1 ↔ Spec 3 coordination 契約の継承

**Objective:** As a Spec 1 起票者と Spec 3 起票者, I want Spec 1 が確定済みの 2 件 coordination 決定（frontmatter `type:` の存在、`categories.yml` の inline `default_skill` 方式）を Spec 3 が前提として参照し、再交渉が不要であることが本 spec で明文化されている, so that 起票完了後に Spec 1 を再変更する coordination リスクが消える。

#### Acceptance Criteria

1. The Skill Dispatcher shall frontmatter 推奨フィールドに `type:` を含めることが Spec 1 Requirement 2 / Requirement 11.1 で確定済みであることを認知し、本 spec は `type:` field を distill dispatch の hint として **読み取る側** として参照することを明示する（Requirement 4 と整合）。
2. The Skill Dispatcher shall `categories.yml` の default skill mapping 方式が **inline `default_skill` field** として Spec 1 Requirement 7.2 / Requirement 11.2 で確定済みであることを認知し、本 spec は当該 field を **読み取る側** として参照することを明示する（Requirement 5 と整合）。
3. The Skill Dispatcher shall 本 spec の dispatch 優先順位（明示 → `type:` → `default_skill` → `applicable_input_paths` glob match → LLM）の **判断ロジック自体** が Spec 1 ではなく本 spec の所管であることを Spec 1 Requirement 11.4 と整合する形で明示する（Spec 1 R11.4 は 4 段階記述だが、本 spec が段階 3.5 を追加した 5 段階化は Spec 2 R3.2 由来の coordination であり、Spec 1 R11.4 への Adjacent Sync を別途実施する手順を残す）。
4. If 将来 Spec 1 の frontmatter `type:` 値域 / `categories.yml` `default_skill` 方式に変更が必要となった, then the Skill Dispatcher shall 本 spec ではなく **Spec 1 を先に改版する手順**（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残すことを規定する。
5. The Skill Dispatcher shall Spec 1 と本 spec の境界を「Spec 1 = field 宣言と vocabulary 定義」「Spec 3 = field 値の解釈と判断ロジック」として明文化し、`type:` 値 → skill 名のマッピング表（Requirement 4.5）が Spec 1 Requirement 11.3（`type:` 値の許可集合 = `categories.yml.recommended_type` + Spec 2 `applicable_categories` 整合）と Spec 2 Requirement 3.2（skill frontmatter `applicable_categories`）双方の整合表から導出される派生情報であることを明示する。

### Requirement 9: Spec 2 ↔ Spec 3 coordination 契約

**Objective:** As a Spec 2 起票者と Spec 3 起票者, I want 本 spec が Spec 2 から提供される skill カタログ（initial 15 種）と各 skill frontmatter `applicable_categories` を読み取り、独自に skill メタデータを再定義しないことが明文化されている, so that skill 一覧が複数 spec で分岐するリスクが消える。

#### Acceptance Criteria

1. The Skill Dispatcher shall Spec 2 が SSoT として固定する skill カタログ（initial 15 種：知識生成 12 種 / Graph 抽出 2 種 / lint 支援 1 種）のうち、distill 向け **知識生成 12 種** を本 spec の dispatch 候補集合として参照することを規定する（Spec 2 Requirement 4 と整合）。
2. The Skill Dispatcher shall `generic_summary` skill が Spec 2 Requirement 4.1 / Requirement 4.4 で `origin: standard` 配布対象として固定されていることを認知し、本 spec の Requirement 6 fallback がこの固定を前提とすることを明示する。
3. The Skill Dispatcher shall 各 skill frontmatter `applicable_categories`（Spec 2 Requirement 3.2 で optional フィールドとして定義、L3 wiki content category 系統の dispatch hint）を、(a) LLM 推論時の入力ヒント（Requirement 2.3）、(b) `type:` 値からの skill 候補導出時の整合 check 材料、として参照することを規定する。
4. The Skill Dispatcher shall 各 skill frontmatter `applicable_input_paths`（Spec 2 Requirement 3.2 で optional フィールドとして定義、L1 raw 入力 path glob 系統の dispatch hint、extended glob 互換）を、(a) Requirement 1 段階 3.5 における入力 path glob match dispatch の判定対象、(b) LLM 推論時の入力ヒント（Requirement 2.3）として参照することを規定する。本 spec の dispatch 実行時に当該 glob と入力 path の match 計算を行い（Spec 2 Requirement 3.2 が本 spec の所管として明記する「実 path の存在検証」）、Spec 2 は path 形式の構文妥当性のみを Skill Validator で検査することを認知する。
5. While Spec 2 の `applicable_categories` field が `null` または空配列である skill, the Skill Dispatcher shall 当該 skill を「全カテゴリで利用可能」として扱うことを規定する。
6. While Spec 2 の `applicable_input_paths` field が `null` または空配列である skill, the Skill Dispatcher shall 当該 skill が Requirement 1 段階 3.5 の path match 評価対象に含まれない（path match 候補から除外）ことを規定する。L1 raw 入力 path 系統の dispatch hint を持たない skill は path 起点では deterministic dispatch されないため、当該 skill は段階 1 / 2 / 3 / 4 のいずれかで選択される。
7. If Spec 2 が新規 standard skill を追加した（initial 15 種から増えた）, then the Skill Dispatcher shall `categories.yml` の `default_skill` および `applicable_categories` / `applicable_input_paths` の整合再 check 必要性を本 spec の design phase で扱う旨を明示し、本 requirements の dispatch ロジック自体は再変更不要であることを規定する。
8. The Skill Dispatcher shall Graph 抽出 skill（`entity_extraction` / `relation_extraction`）と lint 支援 skill（`frontmatter_completion`）が distill dispatch の **対象外** であり、本 spec の dispatch 候補集合に含めないことを規定する（Spec 2 Requirement 5 / Requirement 6 と整合、これらは Spec 4 の `rw extract-relations` / `rw lint --fix` が直接呼ぶ）。
9. The Skill Dispatcher shall `AGENTS/skills/*.md` を **cache せず** dispatch 実行毎に最新を読み込むことを規定する（Spec 1 Requirement 9.3 / 本 spec Requirement 5.5 の vocabulary cache 規定と整合、skill install / deprecate / archive 等の lifecycle 変更が即座に dispatch に反映されるため）。これは Requirement 1 段階 3.5 の path match 候補絞り込み、Requirement 2 LLM 推論時の skill カタログ参照、Requirement 6.1 の dispatch 実行直前 check の各場面で適用される。性能上の cache 必要性は本 spec の design phase で扱い、要件レベルでは整合性優先を固定する。

### Requirement 10: Perspective / Hypothesis dispatch 対象外の規定

**Objective:** As a Spec 6 起票者と本 spec の利用者, I want Perspective / Hypothesis 生成が本 spec の dispatch 対象外であり、Spec 6 が固定 skill `perspective_gen` / `hypothesis_gen` を直接呼ぶことが明文化されている, so that Spec 6 起票時に本 spec の dispatch を経由する必要がないことが明確になり、二重実装や境界違反を防げる。

#### Acceptance Criteria

1. The Skill Dispatcher shall 本 spec の dispatch メカニズムが **distill タスク専用** であることを明示し、Perspective / Hypothesis 生成は dispatch 対象外であることを規定する（SSoT v0.7.12 §11.2 v0.7.10 決定 6-1 と整合）。
2. The Skill Dispatcher shall `rw perspective` / `rw hypothesize` の独立 CLI（Spec 6 / Spec 4 所管）から本 spec の dispatch が呼ばれない契約を規定する。
3. The Skill Dispatcher shall Spec 6 が固定 skill `perspective_gen` / `hypothesis_gen` を直接呼ぶ実装を採用することを認知し、これらの skill 選択に `--skill <name>` 指定や frontmatter `type:` 解釈が **不要** であることを明示する（SSoT §7.2 1971-1973 行と整合）。
4. If 将来 Perspective / Hypothesis に複数 skill 候補が生まれ dispatch が必要になった, then the Skill Dispatcher shall 本 spec の dispatch を再利用するか、Spec 6 内部に独自 dispatch を持つかの判断を新規 spec 改版で扱う手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残すことを規定する。
5. The Skill Dispatcher shall Graph 抽出 skill（Spec 4 の `rw extract-relations` 経由）と lint 支援 skill（Spec 4 の `rw lint --fix` 経由）も同様に本 spec の dispatch 対象外であることを Requirement 9.8 と重複しない範囲で再確認する。

### Requirement 11: 通知 severity と exit code の整合

**Objective:** As a Spec 4 起票者, I want 本 spec の Skill Dispatcher が呼び出し側に返す通知 severity が 4 水準（CRITICAL / ERROR / WARN / INFO）に揃い、Spec 4 が exit code 0/1/2 分離規約に変換可能である, so that ユーザーと CI が dispatch の結果を一意の基準で判断できる。

#### Acceptance Criteria

1. The Skill Dispatcher shall 通知 severity を CRITICAL / ERROR / WARN / INFO の 4 水準として規定し、roadmap.md「v1 から継承する技術決定」の severity-unification 結果を継承することを明示する。
2. The Skill Dispatcher shall 各 Requirement で発火する通知の severity を以下のとおり規定する。
   - **ERROR**: Requirement 6.5（fallback skill `generic_summary` 自体も不在）
   - **WARN**: Requirement 1.7（段階 3.5 path match 複数該当で LLM 推論にエスカレート）/ Requirement 2.6（LLM CLI 失敗で fallback）/ Requirement 3.4（`--auto` 時 LLM 不一致を明示採用）/ Requirement 4.4（`--auto` 時 LLM 採用）/ Requirement 4.7（frontmatter parse 失敗で段階 2 スキップ）/ Requirement 5.8（`categories.yml` parse 失敗で段階 3 スキップ）/ Requirement 6.4（`generic_summary` fallback 発動）
   - **INFO**: Requirement 3.5（LLM 併走推論失敗で明示そのまま採用）/ Requirement 4.6（`type:` 値 unknown で次段階降格）/ Requirement 5.4（`default_skill` 未設定で次段階降格）/ Requirement 5.6（`categories.yml` 未配置で次段階降格）/ Requirement 7.3（aborted 時のユーザー選択による正常な abort、dispatch 失敗ではなく user intent 表明）
   - **CRITICAL**: 本 spec の dispatch 範囲では発火しない（Foundation Requirement 11 と整合、CRITICAL は L2 ledger 破損等の不可逆事象に予約）
3. The Skill Dispatcher shall 通知 severity と exit code 0/1/2 分離（PASS / runtime error / FAIL 検出）の対応関係 を Spec 4 所管とし、本 spec は severity を返却するに留めることを規定する。
4. While 通知が複数発生した場合（例: Requirement 5 段階 3 で `default_skill` 未設定 INFO + Requirement 4 で `type:` 不一致 WARN）, the Skill Dispatcher shall 全ての通知を `notes` フィールドに集約し、最終 severity は最も重い severity を採用することを規定する。
5. If LLM CLI 呼び出し時に subprocess timeout を未設定で実装した, then the Skill Dispatcher shall 当該実装は本 spec の Requirement 2.5 違反として ERROR で reject されることを規定する（roadmap.md「v1 から継承する技術決定」継承）。

### Requirement 12: Foundation 規範への準拠と SSoT 整合

**Objective:** As a Spec 0 規範遵守者および将来の更新者, I want 本 requirements が Foundation の用語・原則・SSoT 出典に準拠する, so that spec 横断の整合性が損なわれない。

#### Acceptance Criteria

1. The Skill Dispatcher shall 本 requirements の用語使用を Spec 0 Foundation の用語集 5 分類（特に「Skill」「Skill candidate」「Distill」「Perspective」「Hypothesis」「LLM CLI インターフェイス」「Severity」）と整合させ、独自の再定義・再命名を行わないことを規定する。
2. The Skill Dispatcher shall 本 requirements を日本語で記述し、`spec.json.language=ja` および CLAUDE.md「All Markdown content written to project files MUST be written in the target language」要件に準拠することを規定する。
3. While 本文中で表形式を用いる場合, the Skill Dispatcher shall 表は最小限に留め、長文・解説は表外の箇条書きまたは段落で記述することを規定する。
4. The Skill Dispatcher shall 本 requirements の各記述項目について SSoT 出典（`.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §7.2 Spec 3 / §6.1 distill / §1.2 LLM 非依存 / §11.2 v0.7.10 決定 6-1）を辿れるよう参照点を残すことを規定する。
5. If SSoT が改版された場合に本 requirements の更新が必要となる, then the Skill Dispatcher shall 自身の更新が roadmap.md「Adjacent Spec Synchronization」運用ルールに従い、`spec.json.updated_at` 更新と markdown 末尾 `_change log` への追記で足りる旨を参照点として残すことを規定する。
6. The Skill Dispatcher shall 本 requirements が定める 12 個の Requirement の各々について、design 段階で「Boundary Commitments」として境界が再確認されることを前提とし、本 requirements の境界（in scope / out of scope / adjacent expectations）を design phase に渡せる形で固定することを規定する。
