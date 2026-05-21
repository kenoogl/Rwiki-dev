# ReviewCompass 再構築計画（戦略転換）

_作成日: 2026-05-21（セッション 14 末）_
_位置付け: 現リポジトリ（dual-reviewer-rebuild）の知見を抽出し、ReviewCompass という名称の新リポジトリでデプロイ可能な形に再構築する計画。本セッションで利用者が決定した戦略転換を記録し、抽出計画・再構築方針・段階的スケジュールを示す_
_配置先：新リポジトリ作成時に ReviewCompass 側へ移管する暫定保管。現時点は現リポジトリ内に置く_

---

## 1. 戦略転換の経緯

セッション 14（2026-05-21）末で利用者が次の判断を下した：

- 現リポジトリ（`dual-reviewer-rebuild/` を含む）は何度も改変を重ねた結果、複雑になりすぎている
- 仕様とコードに自己適用前提が染み込んでおり、他のアプリへのデプロイには向かない構造
- 得られた仕様とノウハウを抽出して新リポジトリ（ReviewCompass）として再構築するほうが筋がよい

転換の根拠：

- 自己適用前提のシステムは他プロジェクトで再利用できない。デプロイ可能な形に作り直す必要がある
- 再構築でデプロイ可能なシステムを作れば、事例として参照可能・再現可能な成果物になる
- 複雑なリポジトリを抱えたまま機能を増やすより、白紙から設計し直すほうが結果的に早い

## 2. 再構築の基本方針

### 2.1 抽出と再構築の分離

- **現リポジトリ＝素材**として保全。変更は加えない（または最小限）
- **新リポジトリ ReviewCompass＝再構築物**として独立
- 両者を混ぜない

### 2.2 クリーンスレート（白紙）から始める

- 新リポジトリは空から作る
- コードや構造を機械的に移植するのではなく、抽出した知見を踏まえて設計し直す
- 自己適用前提の歪みを引き継がない

### 2.3 デプロイの強制設計

- ReviewCompass の最初の関門は **「自分自身をデプロイ可能な状態で動かす」** こと
- アプリ側に置く部分（仕様・レビュー記録）と、ツール側に置く部分（スキーマ・テンプレート・実行コード）の分離を最初から明示する
- 自己適用は可能だが、デプロイ前提の枠組みの上で行う

### 2.4 スタブ先行・段階的な機能載せ

- まずデプロイの枠組みをスタブ（最小限の実装）で作る
- スタブがエンドツーエンドで動くようになったら、それを土台に実機能を順次載せる
- いきなり全機能を作らない

## 3. 抽出計画

抽出対象を 5 カテゴリに分け、それぞれの抽出方針を定める。

### 3.1 5 機能の仕様（self-improvement は当初対象外）

対象：`dual-reviewer-rebuild/.kiro/specs/dual-reviewer-{foundation, runtime, evaluation, paper-interface, implementation-governance}/`

self-improvement は当初の再構築範囲から **外す**。理由：自己改善ループは現状の仕様では効果測定機構が未設計（本セッションで発見した課題のひとつ）であり、デプロイの初期段階に組み込むには重い。スタブと基本機能が動いた後、別フェーズで再設計して追加する。

抽出する要素：

- `intent.md`（意図）
- `brief.md`（簡潔な概要）
- `requirements.md`（要件）
- `design.md`（設計）
- `tasks.md`（タスク）
- `spec.json`（承認状態）の構造のみ

抽出時のクリーニング規律：

- 自己適用前提の記述（「本対象システム」「dual-reviewer 自身」など）を取り除き、「対象アプリは外部にある」前提に書き換える
- ツール側に残すものとアプリ側に置くものを明示的に分ける
- implementation-governance は **workflow-management** という名称に統一する（本セッションで「ワークフロー管理」に改名）
- workflow-management の抽出時は §5.4 の軽量化方針に従い、現仕様の Requirement 9（実行台帳・節ハッシュ・独立再導出パーサ・supersedes・grandfathering）の大部分を削り、思想だけを継承する
- paper-interface は **report-interface** に変更

### 3.2 正本文書（複数の場所に分散）

対象（実際の配置に従う）：

- **`dual-reviewer-rebuild/operations/`**：DATA_INVALIDATION_POLICY、DEPLOYMENT_MODEL、HUMAN_WORKFLOW、REVIEW_PROTOCOL、TRUST_BOUNDARY、WORKFLOW_OVERVIEW
- **`dual-reviewer-rebuild/docs/coordination/`**：workflow-repair-procedure（他の調整記録は実例として参考、必須抽出対象ではない）
- **`dual-reviewer-rebuild/` 直下**：CONVENTIONS、DOCUMENT_INDEX、EVIDENCE_PROTOCOL、MIGRATION_MANIFEST、SELF_IMPROVEMENT_LOOP、SYSTEM_BOUNDARY、REPRODUCIBILITY_CONTRACT、README

抽出方針：

- 規律と用語の定義はそのまま継承
- パス例などの自己適用前提を一般化（`dual-reviewer-rebuild/...` のような具体例を抽象化）
- リポジトリ直下に分散している正本文書は、ReviewCompass では `docs/operations/` に集約する。文書ごとの仕分け（運用文書か基盤文書かの判別など）はフェーズ 1 で作成する `docs/extraction-mapping.md` に記録する

### 3.3 規律ファイル（プロジェクトメモリ）

対象：`dual-reviewer-rebuild/.kiro/memory/`

- discipline_*.md（10 件程度）

抽出方針：

- 適用範囲を「アプリ開発支援ツールとしての規律」に書き換える
- 「3 役レビュー」「規律間の優先順位」など、本質的な規律はそのまま継承

### 3.4 本セッションで発見した課題（5 つ）

すべて再構築の初期設計に反映する：

- **3 軸統一**（重大度・対応優先度・深さ）：レビュー記録テンプレートで 3 軸を必須項目とする。詳細は `rework-classification-unification-plan-2026-05-21.md`
- **I-1 記号**：実装段からタスク段への差し戻し記号を最初から完全に導入する
- **名称変更（ReviewCompass）**：新リポジトリ名・ディレクトリ名・コード内の名称を一貫させる
- **アプリとツールの分離**：パス解決・スキーマ版整合・テンプレート配布・ワークフロー管理機能の対象範囲を明示的に設計する
- **アプリ側のディレクトリ規約**：アプリ側構造を `.reviewcompass/specs/` に確定済み（§4 参照）

### 3.5 テンプレートとプロンプト

対象：`dual-reviewer-rebuild/` 内の主役・敵対役・判定役のプロンプト雛形、レビュー記録テンプレート

抽出方針：

- 3 軸対応の新テンプレートとして書き直す
- アプリ側に配置するもの（記入用）とツール側に配置するもの（プロンプト本体）を分ける

## 4. ReviewCompass リポジトリの初期構造案

抽出対象の 5 機能は `foundation` / `runtime` / `evaluation` / `report-interface` / `workflow-management` の 5 つ（旧 `paper-interface` を `report-interface` に、旧 `implementation-governance` を `workflow-management` に改名済み）。

```
ReviewCompass/
├── README.md                          （プロジェクトの説明と使い方）
├── docs/
│   ├── design/                        （設計方針）
│   ├── operations/                    （正本文書、抽出元 operations/）
│   └── disciplines/                   （規律ファイル、抽出元 memory/）
├── stub/                              （デプロイスタブ、Python 実装）
│   ├── path_resolver/                 （アプリパスの解決）
│   ├── spec_discovery/                （アプリ側仕様の発見）
│   └── reviewer_stub/                 （レビューのモック実装）
├── schemas/                           （foundation 由来の契約・スキーマ）
├── templates/                         （レビューテンプレート、3 軸対応）
├── stages/                            （所定手続きごとの段集合 YAML、詳細は §5.5）
│   ├── intent.yaml                    （drafting／review／approval）
│   ├── feature-partitioning.yaml      （candidate-proposal／approval）
│   ├── feature-dependency.yaml        （機能一覧と依存関係、全フェーズが参照）
│   ├── requirements.yaml              （drafting／review-wave／alignment-gate）
│   ├── design.yaml                    （同上）
│   ├── tasks.yaml                     （同上）
│   ├── implementation.yaml            （同上）
│   ├── reopen-procedure.yaml          （第 1〜10 ステップ）
│   ├── cross-spec-alignment.yaml
│   ├── in-progress/                   （session 跨ぎ用、実行時ディレクトリ）
│   └── completed/                     （完了済み手続きの記録、実行時ディレクトリ）
└── reviewcompass.yaml                 （ツール本体の設定）
```

注：Python の慣習に合わせ、スタブ配下のディレクトリ名はハイフン区切りからアンダースコア区切りに改めた（パッケージとして読み込み可能にするため）。

対象アプリ側のディレクトリ規約（暫定）：

```
<app-repo>/
├── .reviewcompass/
│   ├── config.yaml                    （ReviewCompass 版数の指定）
│   └── specs/
│       └── <feature>/
│           ├── intent.md
│           ├── requirements.md
│           ├── design.md
│           ├── tasks.md
│           ├── spec.json
│           └── reviews/
└── src/
```

対象アプリ側のディレクトリ規約は **`.reviewcompass/specs/`** に確定（2026-05-21）。理由：ツール名と保管先を一致させることで、対象アプリのリポジトリで ReviewCompass が管理する範囲を視覚的に明確にする。既存の `.kiro/specs/` を併用するアプリは、フェーズ 3 で移行コマンドを提供する余地を残す（必須機能ではない）。

## 5. デプロイスタブの設計と完成条件

### 5.1 実装言語と実行形態

- **言語**：Python（理由：仕様文書の解析と大規模言語モデル呼び出しのライブラリが揃っており、後段の実機能まで言語を変えずに伸ばせる）
- **実行形態**：独立したコマンドライン道具（`reviewcompass <subcommand>` の形で対象アプリのリポジトリから呼び出す）
- **理由**：§2.3 の「デプロイ可能な独立成果物」を最も素直に満たし、Claude Code との統合は将来このコマンドライン道具を呼ぶ薄い層（Skill または MCP サーバー：Model Context Protocol サーバー＝外部ツール接続規格）を後から重ねれば済む

### 5.2 スタブが満たすべき条件（設計レベル）

次に実機能開発へ進めるための完成基準を設計レベルで示す。コマンドレベルの検証手順は §7 フェーズ 3 の完了条件を参照。

- **パス認識**：ReviewCompass が「対象アプリのルート」をコマンドライン引数または設定ファイルで受け取り、そのアプリの仕様ディレクトリを発見できる
- **仕様読み込み**：アプリ側の requirements.md を読み込み、内容を構造化できる（簡単な解析でよい）
- **スタブレビュー**：実際のレビューは行わない（モック）が、アプリ側 reviews/ ディレクトリに「スタブレビュー記録」を書き出す
- **エンドツーエンド動作**：上記が連続で動き、アプリ開発者が「ReviewCompass を呼んだら何かが起きた」と確認できる
- **承認関門のモック**：人間承認をシミュレートする入力を受け付け、spec.json の状態を更新する

### 5.3 スタブの上に載せる実機能の順序

スタブが動くようになったら、次の順で実機能を載せる。実機能は「レビュー機能」と「ワークフロー管理機能」の 2 群に分ける。

**レビュー機能**（3 役レビューの中身、各フェーズの「レビュー波」段で動く）：

1. 主役レビューの実装（プロンプト＋大規模言語モデル呼び出し）
2. 敵対役レビューの実装
3. 判定役レビューの実装

**ワークフロー管理機能**（§5.4〜§5.8、レビュー機能の上位構造）：

4. 段集合 YAML と検査スクリプト（§5.4・§5.5）。各フェーズの整合ゲート段や実装フェーズの適合レビュー段は、この段集合 YAML に含まれる
5. reopen の trigger_map による機械強制（§5.6）
6. session 跨ぎ用の in-progress 機構（§5.7）

自己改善ループは **当初は外す**。上記の基本機能が動いた後、別フェーズで効果測定機構を含めて新規設計する。

### 5.4 ワークフロー管理の軽量化方針（2026-05-21 確定）

現リポジトリのワークフロー管理（旧 `implementation-governance`、§3.1 で `workflow-management` に改名済み）は、節ハッシュ・独立再導出パーサ・通過マーカーの後続確認・supersedes リンク・移行戦略などを含む大規模な機構として組み上がっている。再構築では **思想は継承、実装は 1／10** を目標とする。

継承する思想：

- 不可逆操作の直前にしか機械ゲートを置かない（fail-closed の最小集合）
- 証跡 artifact の存在＋構造適合で完了を判定する（主張ではなく証拠）
- 起草者と判定者を分ける（自己承認の禁止）
- 検査が結論不能なら遮断（fail-closed の既定）

削る実装：

- 節ハッシュ（`section_content_hash`）と陳腐化／改竄検知
- supersedes リンクによる旧台帳保全
- grandfathering と format-migration の機構
- 権威マップ（独立文書）と独立再導出パーサ
- 通過マーカーの後続確認（二次防御）

採用する実装：

- 各所定手続きの段集合を YAML（構造化テキスト形式）に静的列挙する（例：`stages/<process_id>.yaml`）。Markdown 節からの動的パースはしない
- 各段に「期待する証跡ファイルのパスと、含むべき節名のリスト」を書く
- 検査スクリプト（Python 実装）は「YAML に列挙された証跡ファイルがすべて存在し、必須節名がすべて含まれるか」だけを判定する
- 検査が落ちたら fail（pass にしない）
- 起草者と判定者の分離は、レビュー記録の冒頭メタデータ（front-matter）に `author` と `reviewer` の異名を必須化することで担保

受け入れるリスク（明文化）：

- 段集合の正本が YAML に固定されるため、Markdown 文書側で段集合が変わった場合に YAML との整合は人手で取る必要がある
- 検査スクリプト自体が呼ばれない経路を機械検知しない（人間がフェーズの境目で確認する前提）
- 多人数開発に拡張する段階で、上記「削る実装」のいずれかを再導入する余地を残す

### 5.5 所定手続きの階層構造（2026-05-21 確定）

現リポジトリの `workflow-process-authority-map.md` は 17 件の所定手続きを 2 階層に分けるが、17 件中 16 件が「未適合」または「未確立」の状態。加えて、intent と requirements の間にあるべき「機能分離（アプリ全体を機能に分割する判断と承認）」段が現状の正本に存在しないという穴も発見された（2026-05-21 のセッション 16 で確認）。再構築では次を行う。

- intent フェーズの縮退（機能横断は概念として成立しないため）
- 機能分離手続きの新設（intent と requirements の間）
- 機能依存マップの YAML 化（台帳機構の対象に含める）
- 実装フェーズの波と整合ゲートの整備（現状「未確立」を解消）
- フェーズ単位 1 ファイル方式での形式統一

階層構造（段名は YAML キー＝英語、和訳は対応関係を併記）：

- **intent 層手続き（intent と requirements の間に位置）**
  - intent.yaml
    - `drafting`（起草、actor=human）
    - `review`（レビュー、actor=llm、単発・波なし）
    - `approval`（承認 gate、actor=human）
  - feature-partitioning.yaml
    - `candidate-proposal`（LLM 候補提示、actor=llm、新設）
    - `approval`（人間承認、actor=human、新設）
- **フェーズ別手続き（requirements 以降の 4 フェーズ）**
  - requirements.yaml／design.yaml／tasks.yaml／implementation.yaml の各フェーズ：3 段ずつ
    - `drafting`（草案、最初の文書または成果物の生成）
    - `review-wave`（レビュー波、複数機能を横断する複数ラウンドレビュー、actor=llm）
    - `alignment-gate`（整合ゲート、フェーズ終端の機能横断整合確認、actor=llm／human 混在）
- **ワークフロー全体レベル手続き**
  - reopen-procedure.yaml（reopen 手続き、第 1〜10 ステップ）
  - cross-spec-alignment.yaml（機能横断整合、段集合は別途確定）

intent 層の設計補足：

- intent 文書の起草は人間担当（LLM は起草しない）。intent.yaml には actor=human の段として記載し、ファイル存在のみを検査対象とする
- intent レビューは LLM 担当で、actor=llm。証跡＋必須節充足を検査
- intent 文書の承認 gate は人間担当・別段。LLM レビューが承認 gate を兼ねない（自走防止）
- 機能横断レビュー波および機能横断整合ゲートは intent には設けない（機能に分かれていないため）

機能分離手続きの設計：

- 入力：承認済み intent 文書
- 作業：機能候補の抽出、責務境界の整理、機能依存関係の初版作成
- 成果物：機能一覧と機能依存マップ（`stages/feature-dependency.yaml`）
- LLM 担当：候補提示と整理（依存関係や責務重なりの検出）
- 人間担当：最終決定と承認
- 完了条件：feature-dependency.yaml が存在し、必須節（features 一覧／depends_on／phase_order）を含むこと

機能間処理順の取り込み（選択肢 X：独立 YAML 参照方式）：

- `stages/feature-dependency.yaml` に機能間処理順を一元化する。各フェーズの YAML はこのファイルを参照する（重複させない）
- feature-dependency.yaml の構造例：

  ```yaml
  features:
    foundation:
      depends_on: []
    runtime:
      depends_on: [foundation]
    evaluation:
      depends_on: [foundation, runtime]
    report-interface:
      depends_on: [foundation, evaluation]
    workflow-management:
      depends_on: [foundation, runtime, evaluation, report-interface]
  phase_order:
    - foundation
    - runtime
    - evaluation
    - report-interface
    - workflow-management
  ```

- requirements.yaml／design.yaml／tasks.yaml／implementation.yaml の草案段とレビュー波段は `feature_order: <feature-dependency.yaml#phase_order>` のような参照を持つ
- 機能の追加・削除や依存関係の変更は feature-dependency.yaml 1 か所のみ修正

実装フェーズの再構築：

- 現リポジトリでは `implementation-review-wave` と `implementation-alignment-gate` が「未確立」のまま。再構築で他フェーズと同形の 3 種類を整備する
- 整合ゲートは複数機能を実装した段階で発火する。スタブ段階（1 機能のみ）では空段として定義のみ

ファイル配置（フェーズ単位 1 ファイル方式）：

```
stages/
├── intent.yaml                  （drafting／review／approval の 3 段）
├── feature-partitioning.yaml    （candidate-proposal／approval の 2 段、新設）
├── feature-dependency.yaml      （機能一覧と依存関係、機能分離の成果物・全フェーズが参照）
├── requirements.yaml            （drafting／review-wave／alignment-gate の 3 段、feature-dependency を参照）
├── design.yaml                  （同上）
├── tasks.yaml                   （同上）
├── implementation.yaml          （同上）
├── reopen-procedure.yaml        （第 1〜10 ステップ）
├── cross-spec-alignment.yaml    （段集合は別途確定）
├── in-progress/                 （session 跨ぎ用、現在進行中の手続き状態ファイルを置く）
└── completed/                   （完了済み手続きの記録、選択肢 P）
```

合計 9 ファイル（in-progress／completed は実行時ディレクトリ）。

各段のフィールド：

- 段名
- `actor`（`human` または `llm`）
- 期待する証跡ファイルのパスパターン
- 必須節名のリスト
- 完了判定（actor=llm は「証跡＋必須節充足」、actor=human は「ファイル存在」）
- 機能横断段の場合は `feature_order: <feature-dependency.yaml#phase_order>` を参照

### 5.6 reopen 手続きの機械強制（2026-05-21 確定）

reopen 手続きの第 7 ステップ「該当ゲートの再実施」を機械強制対象に含める。手戻り種別から再実施対象を機械的に決定するため、`stages/reopen-procedure.yaml` の第 7 段に `trigger_map` を持たせる。

手戻り種別の表記：

- セッション 14 で確定した新表記「起点フェーズの記号 N／R／D／A／I ＋ 深さの数字 0〜4」を使用
  - N = intent、R = requirements、D = design、A = tasks、I = implementation
  - 旧表記 A／B／C／D は I-0／I-2／I-3／I-4 に対応、旧表記で欠落していた I-1 を含めた完全二次元表記

機能分離の表記上の扱い（案 Y）：

- 機能分離は intent 層の一部とみなし、フェーズ記号は N／R／D／A／I の 5 種のまま維持
- N まで戻る場合は、intent 文書と機能分離（feature-partitioning）の両方を再実施対象に含める

連鎖再実施の対象範囲（起点を含める方針）：

- 連鎖は「根本原因フェーズの整合ゲート」から「起点フェーズの整合ゲート」まで、上流から下流へ順に並べる
- 起点フェーズの整合ゲートまで再実施することで、上流変更が下流に正しく伝播したか機械判定できる
- 連鎖の長さ 1 の特殊例（X-0）は「起点フェーズのゲートのみ再実施」として統一的に表現

actor=human の段の扱い（方針 α）：

- trigger_map には actor=llm の段だけでなく actor=human の段（intent.yaml#approval、feature-partitioning.yaml#approval など）も含める
- LLM が trigger_map に沿って連鎖を進めるとき、actor=human の段に来たら作業を止め、in-progress ファイルに「人間承認待ち」を記録して待機
- 人間が承認するまで次の段に進めない（fail-closed）。これにより「LLM が intent を勝手に書き換えて承認なしで進む」リスクを構造的に止める

trigger_map の構造例：

```yaml
- name: 該当ゲートの再実施
  actor: llm
  trigger_map:
    # I 起点（実装段で検出）
    I-0: [stages/implementation.yaml#alignment-gate]
    I-1:
      - stages/tasks.yaml#alignment-gate
      - stages/implementation.yaml#alignment-gate
    I-2:
      - stages/design.yaml#alignment-gate
      - stages/tasks.yaml#alignment-gate
      - stages/implementation.yaml#alignment-gate
    I-3:
      - stages/requirements.yaml#alignment-gate
      - stages/design.yaml#alignment-gate
      - stages/tasks.yaml#alignment-gate
      - stages/implementation.yaml#alignment-gate
    I-4:
      - stages/intent.yaml#review
      - stages/intent.yaml#approval
      - stages/feature-partitioning.yaml#candidate-proposal
      - stages/feature-partitioning.yaml#approval
      - stages/requirements.yaml#alignment-gate
      - stages/design.yaml#alignment-gate
      - stages/tasks.yaml#alignment-gate
      - stages/implementation.yaml#alignment-gate

    # A 起点（タスク段で検出）
    A-0: [stages/tasks.yaml#alignment-gate]
    A-1:
      - stages/design.yaml#alignment-gate
      - stages/tasks.yaml#alignment-gate
    A-2:
      - stages/requirements.yaml#alignment-gate
      - stages/design.yaml#alignment-gate
      - stages/tasks.yaml#alignment-gate
    A-3:
      - stages/intent.yaml#review
      - stages/intent.yaml#approval
      - stages/feature-partitioning.yaml#candidate-proposal
      - stages/feature-partitioning.yaml#approval
      - stages/requirements.yaml#alignment-gate
      - stages/design.yaml#alignment-gate
      - stages/tasks.yaml#alignment-gate

    # D 起点（設計段で検出）
    D-0: [stages/design.yaml#alignment-gate]
    D-1:
      - stages/requirements.yaml#alignment-gate
      - stages/design.yaml#alignment-gate
    D-2:
      - stages/intent.yaml#review
      - stages/intent.yaml#approval
      - stages/feature-partitioning.yaml#candidate-proposal
      - stages/feature-partitioning.yaml#approval
      - stages/requirements.yaml#alignment-gate
      - stages/design.yaml#alignment-gate

    # R 起点（要件段で検出）
    R-0: [stages/requirements.yaml#alignment-gate]
    R-1:
      - stages/intent.yaml#review
      - stages/intent.yaml#approval
      - stages/feature-partitioning.yaml#candidate-proposal
      - stages/feature-partitioning.yaml#approval
      - stages/requirements.yaml#alignment-gate

    # N 起点（intent 段で検出）
    N-0:
      - stages/intent.yaml#review
      - stages/intent.yaml#approval
      - stages/feature-partitioning.yaml#candidate-proposal
      - stages/feature-partitioning.yaml#approval
```

種別判定の証跡：

- reopen の第 6 ステップ「証跡を残す」の中で、種別判定の根拠を `docs/reviews/reopen-classification-<日付>.md` として残す
- 第 7 ステップで、その判定ファイルを読み込んで trigger_map から再実施対象を決定
- 種別判定が後で誤りと分かったら、reopen 自体をやり直す（in-progress ファイルを新しいものに置き換え、旧ファイルは削除せず証跡として保全）

### 5.7 session 跨ぎ時の状態管理（選択肢 P：2026-05-21 確定）

長期にわたる実行では session-cont（セッション継続）で session を跨ぐ。軽量版 YAML 検査は状態ベース（証跡ファイルの存在＋必須節充足のみ）なので、各 session で同じ検査を走らせれば結論は変わらず、session 跨ぎ自体に専用機構は不要。

ただし「複数段にまたがる手続きの途中状態」（典型例は reopen で第 6 ステップまで完了し第 7 ステップが未着手の場合）は状態ベース検査の盲点。これを次の方法で扱う。

途中状態の明示ファイル：

- 現在進行中の手続きは `stages/in-progress/<process_id>-<日付>.yaml` を置く
- 構造例：

  ```yaml
  process_id: reopen-procedure
  started_at: 2026-05-21T10:00:00Z
  trigger: 設計矛盾の発見（C 手戻り）
  completed_steps: [1, 2, 3, 4, 5, 6]
  next_step: 7
  pending_gates:
    - stages/requirements.yaml#alignment-gate
    - stages/design.yaml#alignment-gate
    - stages/tasks.yaml#alignment-gate
  ```

- 手続きが完了したら、ファイルを `stages/completed/` に移動するか削除する

検査スクリプトの拡張：

- `stages/in-progress/` に何かファイルがあれば「未完了の手続きあり、優先処理せよ」と警告を出す
- 警告がある状態で不可逆操作を実行しようとしたら遮断（fail-closed）

session 開始時の標準フロー：

1. TODO_NEXT_SESSION.md と git log で全体の到達点を把握
2. 検査スクリプトを `stages/*.yaml` 全件に走らせる
3. `stages/in-progress/` の有無を確認
4. 進行中手続きがあれば、それを優先的に完了させる
5. 完了済み・未着手の状態に基づき、次の作業を決定

対象となる手続き：

- reopen（10 ステップに分かれる）
- 機能分離（LLM 候補提示と人間承認の間で session が切れる可能性）
- 各フェーズのレビュー波（複数ラウンドの途中で session が切れる可能性）
- 機能横断整合（複数機能を順に確認する途中で session が切れる可能性）

### 5.8 多層防御の必要性と段階的導入（2026-05-21 確定）

§5.4〜§5.7 で確定した軽量版 YAML 検査機構は、LLM がワークフローを正しく実行しないという根本問題に対する **第 1 層の防御** に位置づける。この機構は必要だが十分ではない。100% の規律遵守は原理的に不可能であり、複数の層を重ねることで実効的な遵守率を引き上げる。

#### 第 1 層の限界（明文化）

軽量版 YAML 検査機構が解決しない失敗モード：

- **中身の空疎**：必須節（Findings、Disposition 等）の存在は検査するが、内容の妥当性は検査しない。「特に問題なし」とだけ書いて通すことが可能
- **検査スクリプトの呼び出し依存**：LLM が検査を呼ばない、結果を読まない、独断で進めるという経路は機構の上にある
- **in-progress ファイルの自己申告性**：「いま reopen 中」「次は第 7 ステップ」を書くのは LLM 自身。嘘・古い・欠落の余地が残る
- **事前コンテキストへの引きずられ**：LLM が文脈圧力下で規律ファイルの優先度を下げる現象は、規律ファイルを増やすほど悪化しうる

#### 第 2〜5 層（フェーズ 4 以降の宿題）

スタブが動き、基本機能（5 機能のうち 1〜2 機能）が動くようになった後、次の層を順次導入する。

- **第 2 層：git フックによる外部強制**
  - 検査スクリプトを git の commit／push フックに組み込み、LLM が「呼ばない」選択をできなくする
  - 検査が落ちたら commit 自体が成立しない
  - 適用範囲は git 経由の不可逆操作に限定（spec.json 更新等の非 git 経路には別途配慮）

- **第 3 層：フェーズ境目の利用者監査**
  - フェーズの境目（要件 → 設計、設計 → タスク等）で、利用者が検査結果を必ず確認する手続きを必須化
  - LLM が承認に進む前に、利用者が「検査結果は本当に正しいか」「中身が空疎でないか」を毎回確認
  - 利用者の負担と自走性のトレードオフを明示

- **第 4 層：定期事後監査**
  - 一定 session 数または一定期間ごとに、過去の証跡全件を独立した LLM で監査
  - 第 1〜3 層が見逃した中身の空疎・累積した drift（積み重なったずれ）を検出
  - 監査自体も LLM が行うため絶対ではないが、独立視点が入ることで検知率が上がる

- **第 5 層：処理表面積の抑制方針**
  - 手続き・規律・記号体系を増やさない方針を運用ルールとして明示
  - 「新規規律を追加するときは既存規律 1 つ以上を統廃合する」等の縮減義務を併設
  - 複雑性の累積を構造的に防ぐ

#### 受け入れる残余リスク

第 1〜5 層を重ねても、次の残余リスクは残る。これは明示的に受け入れる。

- 中身の空疎を最終的に検知するのは利用者と独立 LLM の判断であり、両方が見落とす可能性は 0 にならない
- 第 2 層の git フックは git 経由の経路にしか効かない。git を介さない操作は別系で守る必要がある
- 第 4 層の事後監査は「事後」であり、検出されたときには既に何 session か進行している
- 長期実行（数十 session 以上）では累積失敗確率が上昇し続けるため、定期的なリセット（state の作り直し）も選択肢に入る

#### 計画書上の位置付け

本節は再構築計画の **限界の正直な記録** として残す。第 2〜5 層の具体設計はフェーズ 4 以降の宿題とし、本計画書では設計を確定しない。フェーズ 4 開始時に本節を読み返し、当時の知見でアップデートする。

## 6. 統合する課題（本セッション発見の 5 つ）

それぞれを再構築の初期設計に反映する：

| 課題 | 再構築での扱い |
|---|---|
| 3 軸統一 | レビュー記録テンプレートで重大度・対応優先度・深さの 3 軸を必須項目とする |
| I-1 記号 | 深さの記号体系（N／R／D／A／I × 0／1／2／3／4）を完全に導入する |
| 名称変更（ReviewCompass） | 新リポジトリ名・ディレクトリ名・コード内の名称を一貫させる。加えて機能名の改名（`implementation-governance` → `workflow-management`、`paper-interface` → `report-interface`）も同時に適用する |
| アプリとツールの分離 | パス解決・スキーマ版整合・テンプレート配布・ワークフロー管理機能の対象範囲を明示的に設計 |
| アプリ側ディレクトリ規約 | `.reviewcompass/specs/` などのアプリ側構造を仕様化 |

## 7. 段階的スケジュール

具体的な日付は付さない。各フェーズの完了条件で次へ進む。

### フェーズ 1：抽出作業（次セッション以降）

作業内容：

- 5 機能の仕様の抽出と一般化（self-improvement は当初対象外）
- 正本文書の整理
- 規律ファイルの一般化

完了条件（すべて満たす）：

- 5 機能分の仕様一式（intent.md／brief.md／requirements.md／design.md／tasks.md／spec.json の構造）が ReviewCompass 用に書き換えられ、自己適用前提の表現（「dual-reviewer 自身」「本対象システム」等）が grep で 0 件であることを確認できる
- 正本文書（operations 配下 6 件、docs/coordination 1 件、リポジトリ直下 7 件、計 14 件）が `docs/operations/` に配置済みで、抽出元と抽出先の対応表が `docs/extraction-mapping.md` に記録されている
- 規律ファイル（`dual-reviewer-rebuild/.kiro/memory/discipline_*.md` 10 件程度）が `docs/disciplines/` に配置済みで、内容が「アプリ開発支援ツールとしての規律」に書き換えられている

### フェーズ 2：ReviewCompass リポジトリ新設

作業内容：

- GitHub 上に新リポジトリ作成
- 抽出物の配置
- README と初期設計方針の執筆

完了条件（すべて満たす）：

- GitHub 上に新リポジトリが存在し、URL が本計画書に追記されている
- フェーズ 1 の抽出物が新リポジトリの該当パスに配置済み
- README.md に「目的」「対象利用者」「スタブ完成までの段取り」の 3 つの見出しが存在する（各 1 ページ以内）

### フェーズ 3：デプロイスタブの実装

作業内容：

- パス解決
- 仕様読み込み
- スタブレビュー
- 承認関門のモック

完了条件（§5.2 の各条件に検証手順を付ける）：

- パス認識：`reviewcompass --app <パス>` を実行し、標準出力に発見した仕様ディレクトリの一覧が出力される
- 仕様読み込み：`reviewcompass parse-spec <feature>` で、requirements.md を構造化した JSON（または同等の構造化出力）が標準出力に出力される
- スタブレビュー：`reviewcompass review <feature>` で、対象アプリ側 `<feature>/reviews/` にタイムスタンプ付きのスタブレビュー記録が新規作成される
- 承認関門のモック：`reviewcompass approve <feature> <phase>` で、対象アプリ側 spec.json の該当フェーズ承認フラグが更新される
- エンドツーエンド動作：上記 4 コマンドを順に実行する統合テスト（integration test）が 1 本通る

### フェーズ 4：スタブの上で実機能開発

作業内容：

- ReviewCompass 自身を ReviewCompass で開発する（デプロイ前提の自己適用）
- 機能を順次載せる（§5.3 の順序）

完了条件（すべて満たす）：

- 5 機能のうち少なくとも 1 機能（主役レビューを推奨）が、実 LLM（大規模言語モデル）呼び出しを伴って動き、スタブ版でなく実 LLM 版のレビュー記録を出力する
- その 1 機能について、自己適用の最初の 1 サイクルが完走している（仕様 → 主役レビュー → 利用者承認）

### スコープ外：self-improvement の再設計

self-improvement（自己改善ループ）は、本計画書のフェーズ 1〜4 のスコープ外。フェーズ 4 完了後に、効果測定機構を含む再設計を別計画書として起こす。本計画書では扱わない。

### スコープ外：多層防御の第 2〜5 層

§5.8 で位置付けた多層防御のうち、本計画書のフェーズ 1〜4 で実装するのは第 1 層（軽量版 YAML 検査機構）のみ。第 2 層（git フック）・第 3 層（フェーズ境目の利用者監査）・第 4 層（定期事後監査）・第 5 層（処理表面積の抑制方針）はフェーズ 4 完了後の宿題とする。

具体的な導入順序と設計はフェーズ 4 完了時の知見でアップデートする（先に決め打ちしない）。ただし第 5 層（処理表面積の抑制方針）はフェーズ 1〜4 を通じて運用ルールとして意識する：「新規規律を追加するときは既存規律 1 つ以上を統廃合する」の縮減義務を本計画書の運用方針とし、フェーズ 4 までは利用者の意識に依拠して維持する（機械強制は第 5 層導入時に検討）。

## 8. 関連文書

- `rework-classification-unification-plan-2026-05-21.md`：3 軸統一計画。フェーズ 1〜3 の設計に組み込む
- 個人記憶 `feedback_completion_verification_protocol.md`：規律として継承
- 個人記憶 `feedback_no_unilateral_approach_change.md`（射程外を含む）：規律として継承
- 個人記憶 `feedback_intent_conformance_is_the_acceptance_gate.md`：規律として継承
- 個人記憶 `feedback_standing_directives_are_hard_constraints.md`：規律として継承

## 9. 本ドキュメントの位置付け

本ドキュメントは戦略転換の記録と再構築方針の整理であり、本セッションで実装は行わない。次セッション以降、本計画に沿ってフェーズ 1（抽出作業）から着手する。
