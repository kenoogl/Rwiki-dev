# Requirements Document

## Project Description (Input)

Rwiki v2 は v1 から完全リライトされる Curated GraphRAG 型の知識発見・探索システムである。Spec 1-7 が個別機能を実装するに先立ち、それらが共通参照する上位規範（ビジョン・13 中核原則・3 層アーキテクチャ・用語集・frontmatter スキーマ・Task & Command モデル）が固定されていなければ、各 spec が独自解釈で実装し整合性が崩れる。

本 spec（Spec 0、傘 spec）は規範定義に徹し、個別機能の実装には立ち入らない。ビジョン・原則・用語・アーキテクチャを 1 つの SSoT として確立し、Spec 1-7 が参照する Single Source of Truth を提供する。13 中核原則の層別適用マトリクスを明文化し、L1/L2/L3 で異なる人間と LLM の関与モデルが各 spec に正しく伝わるようにする。Edge status 6 種と Page status 5 種の混同等、用語の不統一を防ぐ。

出典 SSoT: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §1-6 / §7.2 Spec 0。

## Introduction

本 requirements は、Rwiki v2 の傘 spec として固定すべき上位規範の集合を定義する。読者は Spec 1-7 の起票者・実装者であり、本 spec を「v2 全体のビジョン・原則・用語・アーキテクチャを引用するときの SSoT」として参照する。

本 spec は **規範文書** を生成する spec であり、CLI コマンドや実行時挙動を新規実装するわけではない。したがって本 requirements の各 acceptance criterion は「Rwiki v2 Foundation 文書群」（以下 Foundation）が満たすべき記述要件・整合性要件として記述される。Subject は概ね `the Foundation` または `the Rwiki v2 Foundation document` を用いる。

本 spec の成果物は次の 3 種類に分類される。

- ビジョンと中核価値の明文化（Trust + Graph + Perspective + Hypothesis 四位一体、Curated GraphRAG ポジショニング）
- 13 中核原則と層別適用マトリクスの固定（L1/L2/L3 ごとの人間と LLM の関与モデルの差を含む）
- 共通用語・3 層アーキテクチャ・frontmatter スキーマ・Task & Command モデルの定義

Spec 1-7 が本 Foundation を参照することで、用語不統一・原則の層適用ミス・edge と page 状態の混同を防ぐ。

## Boundary Context

- **In scope**: ビジョンと中核価値の明文化 / 3 層アーキテクチャ（L1 Raw / L2 Graph Ledger / L3 Curated Wiki）の定義 / 13 中核原則（§2.1-§2.13）と層別適用マトリクス / コマンド 4 Level 階層（L1 発見 / L2 判断 / L3 メンテ LLM ガイド / L4 Power user）/ エディタとの責務分離ポリシー（Obsidian を参照実装として）/ 用語集 5 分類（基本 / アーキテクチャ / Graph Ledger / Perspective-Hypothesis / Operations）/ Edge status 6 種と Page status 5 種の明確な区別 / Evidence-backed Candidate Graph 原則（§2.12）。
- **Out of scope**: frontmatter フィールドの詳細スキーマと vocabulary 実装（Spec 1 が所有）/ L2 Graph Ledger の data model と API の実装（Spec 5 が所有）/ 個別 CLI コマンドの実装（Spec 4 が所有）/ Skill 設計と dispatch の実装（Spec 2 / Spec 3 が所有）/ Page lifecycle 操作の実装（Spec 7 が所有）/ Perspective / Hypothesis 生成ロジックの実装（Spec 6 が所有）。
- **Adjacent expectations**: Spec 1-7 は本 Foundation の用語・原則・層別適用マトリクスを単一の引用元として扱い、独自定義による再解釈・拡張・再命名を行わない。Spec 1-7 が本 Foundation の内容と矛盾する設計を採る場合、先に本 Foundation を改版し（roadmap.md の「Adjacent Spec Synchronization」運用ルールに従う）、その後個別 spec を更新する。v1 spec / 実装は `v1-archive/` に隔離されており、本 Foundation は v1 を知らない前提で自己完結する（フルスクラッチ方針）。

## Requirements

### Requirement 1: ビジョンと中核価値の明文化

**Objective:** As a Spec 1-7 起票者, I want Rwiki v2 のビジョンと中核価値を SSoT として参照できる Foundation, so that 各 spec が独自解釈ではなく共通の価値前提に基づいて設計される。

#### Acceptance Criteria

1. The Foundation shall Rwiki v2 を「Curated Knowledge Graph に対する探索・発見システム」として一行定義し、Karpathy LLM Wiki と Vannevar Bush Memex を起源として明示する。
2. The Foundation shall 中核価値を Trust / Graph / Perspective / Hypothesis の四位一体として定義し、各軸の役割（Trust = 人間承認と evidence chain による裏付け、Graph = typed edges を持つ知識グラフ、Perspective = LLM が graph traverse で既存知識を再解釈、Hypothesis = LLM が未検証の新命題を生成し検証ワークフローに供給）を明記する。
3. The Foundation shall Perspective と Hypothesis の差異を「再解釈 vs 新命題」「Trust chain 維持 vs `[INFERENCE]` マーカー必須」「再利用 vs 検証ワークフロー」の観点で区別する。
4. The Foundation shall Rwiki v2 の位置付けを Curated GraphRAG（候補 graph + 人間承認 + Hygiene + Evidence chain）として宣言し、通常 GraphRAG との対比軸（起点・主体・品質・用途・知識の時間変化）を明示する。
5. The Foundation shall GraphRAG から採用する 4 技法（Community detection / Global query / Missing bridge detection / Hierarchical summary on-demand）と、事前構築しない原則（graph evolving のため）を記録する。
6. Where 設計信念を記述する箇所において, the Foundation shall 「Graph は evolving」「Evidence は first-class」「人間は戦略判断と reject に集中」「知識の正誤は時間の関数」「LLM は実務、人間は方向性決定」「使われる知識を残す」の 6 信念を含める。

### Requirement 2: 3 層アーキテクチャの定義

**Objective:** As a Spec 1-7 起票者, I want L1/L2/L3 各層の責務・物理格納位置・更新頻度・人間関与の差を一意に定義した Foundation, so that 各 spec が層境界を誤らず、層をまたぐ責務配分を正しく行える。

#### Acceptance Criteria

1. The Foundation shall 3 層アーキテクチャを L1 Raw（`raw/**/*.md`、人間入力、append-only、trust 起点）/ L2 Graph Ledger（`.rwiki/graph/`、LLM 抽出 + reject-only + Hygiene 自律進化）/ L3 Curated Wiki（`wiki/**/*.md`、人間承認済 markdown）として定義する。
2. The Foundation shall 各層の更新頻度（L1 = append-only / L2 = 頻繁 / L3 = 人間承認時）と人間関与モデル（L1 = 入力のみ / L2 = reject only / L3 = approve 必須）を明示する。
3. The Foundation shall L2 Graph Ledger の構成ファイルとして `entities.yaml` / `edges.jsonl` / `edge_events.jsonl` / `evidence.jsonl` / `rejected_edges.jsonl` / `reject_queue/` を列挙し、いずれも JSONL/YAML の append-only または ledger 本体であること、derived cache（`.rwiki/cache/graph.sqlite`、`networkx.pkl`）は gitignore 対象であることを記述する。
4. When 横断要素を記述する場合, the Foundation shall `review/*_candidates/`（L2 → L3 承認 buffer）/ `AGENTS/`（LLM 運用ルール）/ `.rwiki/vocabulary/`（tags / relations / categories / entity_types）/ `logs/` を 3 層と独立した横断要素として位置付ける。
5. The Foundation shall 3 層を貫くデータフロー（L1 raw → LLM extract-relations → L2 candidate edge → Hygiene 進化 → review buffer → 人間 approve → L3 wiki）を記述し、L3 frontmatter `related:` が L2 stable/core edges からの derived cache であることを明示する。
6. If ある記述が L2 ledger の正本性を疑わせる, then the Foundation shall L2 JSONL を正本、`.rwiki/cache/graph.sqlite` を rebuild 可能な derived cache とする立場を再確認できる根拠を提供する。

### Requirement 3: 13 中核原則と層別適用マトリクスの固定

**Objective:** As a Spec 1-7 起票者, I want 13 中核原則（§2.1-§2.13）の各々と、それらが L1/L2/L3 のどの層にどの強度で適用されるかを 1 つのマトリクスとして固定した Foundation, so that 各 spec が「全層一律適用」の誤解を避け、層ごとに異なる人間と LLM の関与モデルを反映できる。

#### Acceptance Criteria

1. The Foundation shall 13 中核原則を §2.1 Paradigm C（対話 + 直接編集ハイブリッド）/ §2.2 Review layer first / §2.3 Status frontmatter over directory / §2.4 Dangerous ops 8 段階 / §2.5 Simple dangerous ops / §2.6 Git + 層別履歴媒体 / §2.7 エディタ責務分離 / §2.8 Skill library / §2.9 Graph as first-class / §2.10 Evidence chain / §2.11 Discovery primary / Maintenance LLM guide / §2.12 Evidence-backed Candidate Graph / §2.13 Curation Provenance の 13 項目として定義する。
2. The Foundation shall 各原則について L1 Raw / L2 Graph Ledger / L3 Curated Wiki の 3 層への適用度を「完全適用 / 限定適用 / 適用外 / 該当しない」の 4 区分で明示する。
3. While L2 Graph Ledger の原則適用を記述する場合, the Foundation shall §2.12 Evidence-backed Candidate Graph が §2.2 Review layer first および §2.4 Dangerous ops 8 段階より優先することを明記し、L2 では review/ 層を経由しない append-only JSONL + reject-only filter + Hygiene 自律進化が標準であることを記述する。
4. While L3 Curated Wiki の原則適用を記述する場合, the Foundation shall §2.2 Review layer first（review/ 層経由）/ §2.4 Dangerous ops 8 段階対話 / §2.3 Page status frontmatter による状態管理が必須であることを記述する。
5. The Foundation shall §2.10 Evidence chain のみが全層を貫く唯一の不変原則であり、L1 起点 → L2 evidence.jsonl 集約 → L3 `sources:` まで切れずに辿れることを記述する。
6. If ある spec が「全原則を全層に一律適用する」と読み取れる記述を含む, then the Foundation shall §2.0 層別適用マトリクスを根拠として誤読を是正できる説明（凡例の意味、最重要の帰結 4 項目）を提供する。

### Requirement 4: §2.12 Evidence-backed Candidate Graph 原則の優先関係

**Objective:** As a Spec 5 / Spec 6 起票者, I want §2.12 が L2 専用であり、§2.2 / §2.4 より優先するという関係性を明文で固定した Foundation, so that L2 Graph Ledger の設計が「全件 approve」「8 段階対話」を誤って要求しない。

#### Acceptance Criteria

1. The Foundation shall §2.12 の適用範囲を「L2 Graph Ledger のみ。L3 wiki / L1 raw には適用されない」と明示する。
2. The Foundation shall §2.12 の 3 つの核心ルール（Evidence 必須 / Reject-only filter / 使用で育つ）を列挙する。
3. The Foundation shall L2 edge の追加が review/ 層を経由せず edges.jsonl への append-only 記録で完結することを §2.2 との優先関係として説明する。
4. The Foundation shall L2 edge の reject が 1-stage confirm で実行される §2.5 Simple dangerous op であり、§2.4 の 8 段階対話を要求しないことを §2.4 との優先関係として説明する。
5. The Foundation shall L3 wiki/ への昇格には従来通り approve が必須であり、L3 frontmatter `related:` は L2 stable/core edges から derived cache として sync されることを記述する。
6. If 入力コスト問題（全件 approve 必須が知識蓄積のボトルネック）を緩和する根拠を求められた, then the Foundation shall §1.3.2 を引用元として reject-only filter + Hygiene 自己進化への転換が回答であることを示せる記述を含む。

### Requirement 5: Edge status 6 種と Page status 5 種の明確な区別

**Objective:** As a Spec 1 / Spec 5 / Spec 7 起票者, I want Edge status と Page status を別次元として定義し、混同を防ぐ Foundation, so that frontmatter / ledger / lifecycle 設計で誤って共通の状態セットを使うことを防ぐ。

#### Acceptance Criteria

1. The Foundation shall Edge status を `weak / candidate / stable / core / deprecated / rejected` の 6 種として定義し、L2 Graph Ledger の edge ライフサイクル状態であることを明記する。
2. The Foundation shall Page status を `active / deprecated / retracted / archived / merged` の 5 種として定義し、L3 wiki ページの frontmatter `status:` で管理されるライフサイクル状態であることを明記する。
3. The Foundation shall Edge status と Page status が独立した別次元の概念であることを、用語集または 3 層アーキテクチャ説明の中で明示する。
4. Where Hypothesis を扱う箇所において, the Foundation shall Hypothesis status `draft / verified / confirmed / refuted / promoted / evolved / archived` の 7 種が Page status / Edge status とさらに独立した第 3 の status 軸であることを明示する。
5. If ある spec が「Edge status と Page status を共通の状態セットとして扱う」記述を含む, then the Foundation shall この区別を根拠に誤読を是正できる定義を提供する。
6. The Foundation shall Edge status 各値の意味（weak = 表示抑制低優先 / candidate = 監視対象 / stable = auto-accept / core = 高 confidence + 高 usage / deprecated = traverse 対象外 / rejected = rejected_edges.jsonl に保持）を簡潔に説明する。

### Requirement 6: コマンド 4 Level 階層とエディタ責務分離

**Objective:** As a Spec 4 / Spec 6 起票者, I want コマンド階層 4 Level の分類とエディタとの責務分離ポリシーを Foundation で固定する, so that CLI 設計とユーザー UX 設計が「ユーザーは知識発見、メンテナンスは LLM ガイド」という上位原則を守る。

#### Acceptance Criteria

1. The Foundation shall コマンドを L1 発見（日常入口、ユーザーが優先習得すべき最小コマンド）/ L2 判断（L3 昇格・検証）/ L3 メンテナンス（20+ コマンド、`rw chat` 経由で LLM が自然言語ガイド）/ L4 Power user / CI（全コマンド直接実行）の 4 Level に分類する。
2. The Foundation shall L1 発見コマンドの代表として `rw chat` / `rw perspective` / `rw hypothesize` を例示する。
3. The Foundation shall L3 メンテナンスコマンドが原則として全て `rw chat` 内で LLM ガイド可能であるべきであるという §2.11 設計指針を記述する。
4. The Foundation shall エディタとの責務分離を「編集体験はエディタ、パイプラインは Rwiki」として定義し、Obsidian を参照実装としつつ Rwiki 自体はエディタ非依存であることを明示する。
5. While L2 Graph Ledger の編集を扱う場合, the Foundation shall L2 JSONL は人間が直接編集する対象ではなく Rwiki が管理する領域であることを記述する。
6. If ユーザーが「Rwiki を綺麗にしたい」のような自然言語意図を発した場合に LLM がオーケストレーションする UX が想定される, then the Foundation shall §2.11 maintenance autonomous の例（reject queue 蓄積警告、未 approve 候補警告、edge decay 警告等）を参照点として残す。

### Requirement 7: 用語集 5 分類の存在

**Objective:** As a Spec 1-7 起票者, I want 用語が 5 分類で整理された Foundation 用語集, so that 用語不統一による spec 間の解釈ずれを防ぐ。

#### Acceptance Criteria

1. The Foundation shall 用語集を「基本用語 / アーキテクチャ用語 / Graph Ledger 用語 / Perspective-Hypothesis 用語 / Operations 用語」の 5 分類に編成する。
2. The Foundation shall 基本用語として Rwiki / Vault / Curated GraphRAG / Distill / Synthesis / Skill / Paradigm C / Follow-up を含める。
3. The Foundation shall アーキテクチャ用語として L1 / L2 / L3 / Evidence-backed Candidate Graph / Trust chain / Review layer / Derived cache を含める。
4. The Foundation shall Graph Ledger 用語として Entity / Edge / Edge status / Page status / Confidence / Evidence ledger / Edge event / Dangling edge / Extraction mode / Graph Hygiene（Decay/Reinforcement/Competition/Contradiction tracking/Edge Merging）/ Usage signal / Reject queue / Curation provenance / Decision log を含める。
5. The Foundation shall Perspective-Hypothesis 用語として Perspective generation / Hypothesis generation / Hypothesis status / Discovery / `[INFERENCE]` マーカー / Community detection / Global query / Missing bridge detection / Hierarchical summary / Autonomous mode / Maintenance autonomous trigger を含める。
6. The Foundation shall Operations 用語として Dangerous operation / Simple dangerous operation / 8 段階対話ガイド / Reject-only filter / Pre-flight check / コマンド階層 4 Level / Hygiene batch / Dry-run / Stale detection / Rebuild を含める。
7. If 同じ概念が複数の異なる名称で参照される懸念がある, then the Foundation shall 各用語に正規名と必要に応じた alias を併記し、spec 間で同義語が独立に増殖しないようにする。

### Requirement 8: Frontmatter スキーマの上位規範

**Objective:** As a Spec 1 起票者, I want frontmatter の共通必須・推奨・任意フィールドと wiki / review / skill / vocabulary / follow-up / hypothesis / perspective 各種のスキーマ骨格を Foundation で参照できる, so that 個別フィールドの実装は Spec 1 に委ねつつ、スキーマ全体像と意味的役割は spec 横断で固定される。

#### Acceptance Criteria

1. The Foundation shall 全 markdown ファイルに共通の必須フィールドとして `title` / `source` / `added` を定義する。
2. The Foundation shall 推奨フィールドとして `type`（content type 単一値、スキル選択ヒント）と `tags`（多次元分類）を定義する。
3. The Foundation shall Wiki ページ固有フィールドとして `status` / `status_changed_at` / `status_reason` / `successor`（deprecated 時）/ `merged_from` / `merged_into` / `merge_strategy` / `related`（typed edges、L2 derived cache）/ `update_history` を骨格として記述する。
4. The Foundation shall Review レイヤー固有 / Skill ファイル / Skill candidate / Vocabulary candidate / Follow-up / Hypothesis candidate / Perspective 保存版の各スキーマ骨格を一覧として位置付け、詳細なフィールド仕様は Spec 1 に委譲する旨を記述する。
5. While L2 Graph Ledger の記録形式を記述する場合, the Foundation shall `entities.yaml`（正規化エンティティ）/ `edges.jsonl`（edge 正本）/ `edge_events.jsonl`（confidence 変遷 append-only）/ `evidence.jsonl`（根拠引用集 first-class）/ `rejected_edges.jsonl`（reject 履歴）の 5 ファイルが core schema を構成することを明示する。
6. The Foundation shall L3 frontmatter `related:` が L2 edges からの derived cache であり、正本は `.rwiki/graph/edges.jsonl` であることを記述する。
7. If 詳細なフィールド型・vocabulary・validation rule を求められた, then the Foundation shall それらを Spec 1 の所管とする境界を明示し、本 spec は骨格と意味的役割の固定に留めることを示す。

### Requirement 9: Task & Command モデルの一覧化

**Objective:** As a Spec 4 起票者, I want Foundation で Task 一覧と Command 一覧を上位カタログとして固定する, so that 個別 CLI の実装は Spec 4 に委ねつつ、コマンド名・実行モード・対話ガイド有無の対応が spec 横断で参照できる。

#### Acceptance Criteria

1. The Foundation shall Task 一覧として lint / ingest / distill / approve / query (answer/extract/fix) / audit (links/structure/semantic/strategic/deprecated/tags/evidence/followups) / perspective / hypothesize / discover を、それぞれの実行モード（CLI / CLI Hybrid）と対話ガイドの有無とともに記述する。
2. The Foundation shall Command 一覧をコア / Input Pipeline / Knowledge Generation / Approval / Query / Audit / L2 Graph Ledger 管理 / Edge 個別操作 / Entity-Relation 抽出 / Reject workflow / Page Lifecycle / Tag Vocabulary / Skill Library / Follow-up / Vault 管理 のカテゴリ別に整理する。
3. The Foundation shall 各コマンドの一行説明を含め、引数フラグの詳細仕様は Spec 4 / Spec 5 / Spec 6 / Spec 7 の所管である旨を明示する。
4. While 実行モードを記述する場合, the Foundation shall Interactive（`rw chat`、推奨）/ CLI 直接（`rw <task>`、自動化・熟練）/ CLI Hybrid（内部で LLM CLI 呼出）の 3 モードがいずれも同じ `cmd_*` エンジン関数を呼ぶことを記述する。
5. If 個別コマンドのフラグ・出力形式・exit code 仕様を求められた, then the Foundation shall それらが Spec 4 以降の所管であることを明示する。

### Requirement 10: Spec 1-7 が参照する SSoT 性

**Objective:** As a Spec 1-7 起票者および将来の v2 開発者, I want Foundation を Spec 1-7 が単一引用元として参照する SSoT として位置付ける, so that 用語・原則・アーキテクチャの解釈が複数 spec で分岐することを防ぐ。

#### Acceptance Criteria

1. The Foundation shall 自身が `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §1-6 / §7.2 Spec 0 を SSoT 出典とすることを明示する。
2. The Foundation shall 自身が Spec 1-7 全 spec の上位規範であり、Spec 1-7 がビジョン・原則・用語・アーキテクチャを引用する際の単一参照元であることを Introduction に記述する。
3. While Foundation の内容と個別 spec の内容に矛盾が発生した場合の運用を記述する箇所において, the Foundation shall roadmap.md の「Adjacent Spec Synchronization」運用ルール（先行 spec 変更による波及的な文言同期は再 approval 不要、`spec.json.updated_at` 更新と各 markdown 末尾 `_change log` への追記で足りる）を参照点として残す。
4. If ある spec が Foundation の用語・原則・マトリクスを再定義・再解釈・再命名しようとする, then the Foundation shall その変更は本 Foundation を先に改版した上で個別 spec へ反映する手順が必要であることを示す。
5. The Foundation shall v1 spec / 実装が `v1-archive/` に隔離されており、本 Foundation は v1 を知らない前提で自己完結する（フルスクラッチ方針、§9.1）ことを明示する。
6. The Foundation shall Spec 1-7 の依存順（Spec 0 → 1 → {4, 7} → 5 → 2 → 3 → 6）が roadmap.md に定義されていることを参照し、本 Foundation がその起点として位置付けられることを記述する。

### Requirement 11: 実装独立性と運用前提

**Objective:** As a Spec 2 / Spec 3 / Spec 4 起票者, I want LLM CLI とエディタへの実装独立性、および運用上の前提（Python 3.10+ / Git 必須 / Concurrency lock 等）を Foundation で固定する, so that 個別 spec が特定 LLM CLI / 特定エディタに固有の前提を埋め込むことを防ぐ。

#### Acceptance Criteria

1. The Foundation shall LLM 実装の独立性を「特定 LLM に依存しない、Claude Code は参照実装、抽象層は Spec 3 が提供」として明記する。
2. The Foundation shall エディタ実装の独立性を「Obsidian は推奨だが必須ではない、生成 markdown は任意エディタで編集可能」として明記する。
3. The Foundation shall 必須環境を Git / Python 3.10+ / LLM CLI インターフェイス / Markdown エディタとして列挙する。
4. The Foundation shall Python 依存を `sqlite3`（標準）と `networkx >= 3.0`（Spec 5 で追加）に限定する方針を記述する。
5. While Concurrency / Lock を記述する場合, the Foundation shall `.rwiki/.hygiene.lock` が Hygiene バッチと CLI 操作の排他制御を担い、Spec 4 と Spec 5 の境界で整合させるべき項目であることを記述する。
6. The Foundation shall L2 ledger が append-only JSONL である方針を採用した理由（git diff 親和、人間可読、Graph DB 正本化の却下、rebuild 可能性）を §2.6 を引用元として記述する。
7. If reject 理由の記述義務に関する質問がある, then the Foundation shall `rejected_edges.jsonl` の `reject_reason_text` が空文字禁止であり、`reject_learner` skill の学習素材として必須であることを明記する。

### Requirement 12: Curation Provenance（§2.13）の規範化

**Objective:** As a Spec 5 / Spec 6 起票者, I want §2.13 Curation Provenance の原則が Foundation で固定されている, so that decision_log.jsonl の存在と「what + why」の二層化が個別 spec で見落とされない。

#### Acceptance Criteria

1. The Foundation shall §2.13 の原則を「知識は what（edge / page / entity 等の結果）+ why（なぜそう判断したかの decision rationale）の二層で構成される」として明記する。
2. The Foundation shall `evidence.jsonl` が source の WHAT を保全するのに対し、`decision_log.jsonl` が curator の WHY を保全する直交関係であることを記述する。
3. The Foundation shall §2.13 の 3 つの核心ルール（Selective recording で volume 抑制 / Append-only / Selective privacy）を列挙する。
4. The Foundation shall Decision log の自動記録対象が「境界決定 / 矛盾検出 / 人間 approve・reject・merge・split / Hypothesis verify / Hygiene による status 遷移 / synthesis 操作」であり、routine extraction や routine decay は記録しないことを記述する。
5. While §2.10 Evidence chain との関係を記述する場合, the Foundation shall Evidence chain が trust chain の縦軸（L1 → L2 → L3）、Curation provenance が横軸（decision_log → context_ref → chat-session）であり、両者が直交することを明示する。
6. If decision_log の詳細スキーマ（decision_id / decision_type / actor / subject_refs / reasoning / alternatives_considered / outcome / context_ref / evidence_ids 等）を求められた, then the Foundation shall その詳細仕様が Spec 5 の所管であり、本 spec は原則と直交関係の固定に留めることを記述する。

### Requirement 13: §2.6 Git + 層別履歴媒体の規範化

**Objective:** As a Spec 5 / Spec 7 起票者, I want Git を第一の履歴ソースとしつつ、層ごとに補助履歴媒体が異なるという §2.6 原則を Foundation で固定する, so that 各 spec が層に不適合な履歴媒体（例: L2 で frontmatter update_history を使う等）を採用しない。

#### Acceptance Criteria

1. The Foundation shall 全層共通原則として「Git が第一の履歴ソース」「補助履歴で細粒度トレース」「derived cache は gitignore」「退避ディレクトリを作らない（status / rejected ledger で論理管理）」の 4 項目を記述する。
2. The Foundation shall 層別履歴媒体の対応を L1 = Git log のみ / L2 = `edge_events.jsonl`（append-only event log）/ L3 = frontmatter `update_history:`（page-level 意味的変更）として明示する。
3. The Foundation shall L2 補助履歴の event type として `created / reinforced / decayed / promoted / demoted / rejected / merged / contradiction_flagged` を列挙する。
4. The Foundation shall `rejected_edges.jsonl` が物理削除ではなく履歴の一部として保存され、`rw edge unreject` で復元可能であることを「失敗からも学ぶ」思想（§1.3.5）と紐付けて記述する。
5. While L2 edge reject の必須記録項目を記述する場合, the Foundation shall `edge_id` / `rejected_at` / `reject_reason_category`（6 種定型）/ `reject_reason_text`（空文字禁止）/ `rejected_by` / `pre_reject_status` / `pre_reject_evidence_ids` を必須フィールドとして列挙する。
6. If `rejected_edges.jsonl` の reject 理由を空文字で記録しようとする, then the Foundation shall reject_reason_text の空文字禁止と `reject_learner` skill の学習素材としての必要性を根拠として参照できるようにする。

### Requirement 14: 文書品質と SSoT 整合性

**Objective:** As a Spec 0 自身の品質保証および将来の更新者, I want Foundation 自体が CLAUDE.md の出力ルールに準拠し、SSoT 出典との整合を維持する, so that 規範文書としての可読性と信頼性が損なわれない。

#### Acceptance Criteria

1. The Foundation shall 本文を日本語で記述し、`spec.json.language=ja` および CLAUDE.md「All Markdown content written to project files MUST be written in the target language」要件に準拠する。
2. While 本文中で表形式を用いる場合, the Foundation shall 表は最小限に留め、長文・解説は表外の箇条書きまたは段落で記述する。
3. The Foundation shall 各記述項目について SSoT 出典（`.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 のセクション番号）を辿れるよう、章立て番号を SSoT と整合させる。
4. If SSoT が改版された場合に Foundation の更新が必要となる, then the Foundation shall 自身の更新が roadmap.md の「Adjacent Spec Synchronization」運用ルールに従い、`spec.json.updated_at` 更新と markdown 末尾 `_change log` への追記で足りる旨を参照点として残す。
5. The Foundation shall 本 requirements が定める 14 個の Requirement の各々について、design 段階で「Boundary Commitments」として境界が再確認されることを前提とし、本 requirements の境界（in scope / out of scope / adjacent expectations）を design phase に渡せる形で固定する。
