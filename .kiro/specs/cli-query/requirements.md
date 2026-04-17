# Requirements Document

## Introduction

仕様案で定義されているquery系タスク（query_extract, query_answer, query_fix）のCLIコマンドを実装する。既存の `rw lint query` がクエリアーティファクトの検証を担い、`review/query/<query_id>/` の4ファイル構造（question.md, answer.md, evidence.md, metadata.json）を定義済みである。本スペックでは、アーティファクトの生成（extract）・修復（fix）およびwiki知識に基づく直接回答（answer）を行うCLIサブコマンドを追加する。

extract は `review/query/` にファイルを生成する。fix は `review/query/` 内の既存ファイルを修復する。answer は標準出力のみで、ファイルを生成しない。wikiへの直接書き込みは行わない。

## Boundary Context

- **In scope**: `rw query extract`・`rw query answer`・`rw query fix` の3サブコマンド実装、extract による `review/query/<query_id>/` への4ファイル出力、usage表示更新、`docs/user-guide.md` へのqueryリファレンス追記、CHANGELOG.md追記、実行モード更新（templates/CLAUDE.md・AGENTS/query_*.md・AGENTS/README.md の Execution Mode を Prompt → CLI (Hybrid) に変更）、AGENTS/ファイルをプロンプトの正規ソースとする一元管理方式の実装
- **Out of scope**: query結果のwikiへの昇格プロセス（approveコマンドの拡張として別途検討）、AGENTS/ファイルのルール定義・処理内容の変更（agents-systemスペック管轄。ただし Execution Mode 表記の更新は本スペックで実施する — Req 8）、テスト（test-suiteスペック管轄）、クエリのUI
- **Adjacent expectations**:
  - `rw lint query` が既に定義する4ファイル構造・QLコード・必須フィールドをquery生成時の品質契約として前提とする。lint query自体の変更は本スペックでは行わない
  - `templates/AGENTS/query_extract.md`・`query_answer.md`・`query_fix.md` がプロンプトルールの正規ソースである。CLIはこれらをプロンプト構築に使用するが、ルール定義内容の変更は行わない
  - `wiki/` のコンテンツが存在し、コミット済みであることを前提とする
- **Design constraint: プロンプトの二重管理を解消すること**:
  - 既存の `synthesize-logs` では Claude CLI 呼び出し時のプロンプトが Python コードにハードコードされており、AGENTS/ファイルのルール定義との二重管理が発生している（agents-system Implementation Notes 参照）。cli-query ではこの問題を繰り返さず、AGENTS/ファイルとCLIプロンプトの一元管理を実現すること。具体的な方式は設計フェーズで決定する
- **Design decision: scope なし時の wiki コンテンツ選択方式**:
  - `--scope` が省略された場合の wiki コンテンツ選択方式（全ページ読み込み、index.md からの関連ページ特定、その他）は設計フェーズで決定する

## Requirements

### Requirement 1: query extract サブコマンド

**Objective:** 運用者として、wikiから構造化された知識アーティファクトを抽出し `review/query/` に配置したい。後続のレビュー・lint・昇格ワークフローで再利用するためである。

#### Acceptance Criteria

1.1. When 運用者が `rw query extract "<質問文>"` を実行した場合, the CLI shall `review/query/<query_id>/` ディレクトリに question.md・answer.md・evidence.md・metadata.json の4ファイルを生成する

1.2. When query extract のファイル生成および自動lint検証（Req 4.5）が共に成功した場合, the CLI shall 生成した各ファイルのパスを標準出力に表示し、終了コード 0 で終了する

1.3. When `--scope <ページパス>` オプションが指定された場合, the CLI shall 指定されたwikiページのみを回答のソースとして使用する

1.4. When `--type <query_type>` オプションが指定された場合, the CLI shall 指定されたクエリタイプ（fact / structure / comparison / why / hypothesis）を使用する

1.5. When `--type` オプションが省略された場合, the CLI shall Claude CLIに質問文からクエリタイプを自動判定させる

1.6. The CLI shall query_id を Req 4.6 の共通規則に従って自動生成する

1.7. If 同一の query_id を持つディレクトリが既に存在する場合, then the CLI shall エラーメッセージを表示し、上書きせずに終了コード 1 で終了する。再生成の手段（オプションまたは手動削除）は設計フェーズで決定する

1.8. The CLI shall 生成する answer.md 内の推論・解釈・クロスページ推論に `[INFERENCE]` マーカーを付与するようClaude CLIに指示する

1.9. When 運用者が `rw query` をサブコマンドなしで実行した場合, the CLI shall 利用可能なサブコマンド（extract / answer / fix）の一覧と使用方法を表示する

### Requirement 2: query answer サブコマンド

**Objective:** 運用者として、wikiの知識に基づく直接回答を素早く取得したい。アーティファクト生成なしに質問への回答を確認するためである。

#### Acceptance Criteria

2.1. When 運用者が `rw query answer "<質問文>"` を実行した場合, the CLI shall wikiの知識に基づく回答を標準出力に表示する

2.2. When query answer が回答を生成した場合, the CLI shall 回答とともに参照したwikiページのパスを表示する

2.3. The CLI shall query answer の出力を標準出力のみとし、ファイルを生成しない

2.4. When `--scope <ページパス>` オプションが指定された場合, the CLI shall 指定されたwikiページのみを回答のソースとして使用する

2.5. If wikiにコンテンツが存在しないか不十分な場合, then the CLI shall 回答の限界を明示し、不足している情報を説明する

2.6. When query answer が正常に回答を生成した場合, the CLI shall 終了コード 0 で終了する

### Requirement 3: query fix サブコマンド

**Objective:** 運用者として、lint結果に基づいてクエリアーティファクトを修復したい。手動での修正作業を削減するためである。

#### Acceptance Criteria

3.1. When 運用者が `rw query fix <query_id>` を実行した場合, the CLI shall `review/query/<query_id>/` 内のアーティファクトを `rw lint query` の結果に基づいて修復する

3.2. When query fix の修復および自動lint再検証（AC 3.9）が共に成功した場合, the CLI shall 修復した項目（対象ファイルとQLコード）を標準出力に表示し、終了コード 0 で終了する

3.3. When `rw lint query <query_id>` が未実行の場合, the CLI shall lint を自動実行してから修復を開始する

3.4. The CLI shall lintが報告した問題への対処以外のセマンティックな内容変更を行わず、最小限の編集で修正する

3.5. The CLI shall 修復時に wiki/ のコミット済みコンテンツを参照し、不足しているevidenceの補完に使用してよい

3.6. If evidence が不足しており wiki にも該当情報が存在しない場合, then the CLI shall 回答を弱めるか `[INFERENCE]` マーカーを付与し、evidence を創作しない

3.7. When 全てのlintエラーが修復済み（FAIL が 0）の場合, the CLI shall 「修復不要」と表示し、終了コード 0 で終了する

3.8. If Claude CLIで修復不可能なlintエラー（ファイル欠落等）が存在する場合, then the CLI shall 修復可能な項目のみ修復し、修復不可能な項目をスキップ理由とともに報告する。終了コードは修復後の自動lint検証（AC 3.9）の結果に基づいて決定する

3.9. When query fix の修復処理が終了した場合（部分修復を含む）, the CLI shall `rw lint query` を自動実行し、修復結果の検証を標準出力に表示する

### Requirement 4: 4ファイル出力契約

**Objective:** 運用者として、query extract が生成するアーティファクトが `rw lint query` のバリデーションを通過する品質であることを保証したい。

#### Acceptance Criteria

4.1. The CLI shall question.md に query（質問文）・query_type・scope・date の4フィールドを含める

4.2. The CLI shall answer.md を空でない構造化された内容（見出しまたは箇条書き）として生成する

4.3. The CLI shall evidence.md の各ブロックに `source:` 行を含め、最小限の十分な抜粋のみを記載する

4.4. The CLI shall metadata.json に query_id・query_type・scope・sources・created_at の5フィールドを含める

4.5. When 4ファイルの生成が完了した場合, the CLI shall `rw lint query` を自動実行し、検証結果を標準出力に表示する

4.6. The CLI shall query_id を `YYYYMMDD-<質問文のスラッグ>` 形式で生成する。スラッグは `templates/AGENTS/naming.md` の命名規則（ASCII のみ・小文字・ハイフン区切り）に従い、最大長を設計フェーズで定義する。この規則は query extract に適用される

4.7. If 自動lint検証でERRORレベルのFAILが検出された場合, then the CLI shall 警告メッセージとともに該当QLコードを表示し、生成したファイルは保持したまま非ゼロの終了コードで終了する

### Requirement 5: 知識フロー遵守

**Objective:** 運用者として、queryコマンドが知識パイプラインの制約（raw → review → wiki）を遵守することを保証したい。

#### Acceptance Criteria

5.1. The CLI shall query のファイル出力（extract・fix）を `review/query/` 配下にのみ配置する

5.2. The CLI shall `wiki/` に直接書き込まない

5.3. The CLI shall 回答生成時に `wiki/` のコミット済みコンテンツのみをソースとして使用する

5.4. The CLI shall `raw/` のコンテンツを回答ソースとして使用しない

5.5. If `wiki/` の作業ツリーがdirtyな場合, the CLI shall 警告メッセージを表示する

5.6. The CLI shall query実行後に自動コミットを行わない。生成・修復されたファイルのコミットは運用者が手動で行う

### Requirement 6: エラー処理

**Objective:** 運用者として、queryコマンド実行時のエラーが明確に報告され、データが破損しないことを保証したい。

#### Acceptance Criteria

6.1. If Claude CLIの呼び出しが失敗した場合, then the CLI shall エラーメッセージを表示し、終了コード 1 で終了する

6.2. If Claude CLIのレスポンスが有効なフォーマットでない場合, then the CLI shall パースエラーを表示し、部分的なファイルの生成または修正を行わずに終了コード 1 で終了する

6.3. If 指定された `<query_id>` のディレクトリが存在しない場合（query fix 実行時）, then the CLI shall エラーメッセージを表示し、終了コード 1 で終了する

6.4. If `wiki/` ディレクトリが存在しない、または `.md` ファイルが1つも存在しない場合, then the CLI shall エラーメッセージを表示し、終了コード 1 で終了する

6.5. If プロンプト構築に必要な AGENTS/ファイルが存在しない、または CLAUDE.md のマッピング表がパースできない場合, then the CLI shall エラーメッセージを表示し、終了コード 1 で終了する

### Requirement 7: ドキュメント更新

**Objective:** 運用者として、queryコマンドの使い方が `docs/user-guide.md` とCHANGELOGに記載されていることで、コマンドの正しい利用法を把握したい。

#### Acceptance Criteria

7.1. 本スペックの成果物として、`docs/user-guide.md` に `rw query extract`・`rw query answer`・`rw query fix` の使用方法・引数・出力例が追記されていること

7.2. 本スペックの成果物として、CHANGELOG.md の `[Unreleased]` セクションに cli-query スペックの変更内容が追記されていること

### Requirement 8: 実行モード更新

**Objective:** 運用者として、query系タスクの実行モードがCLI実装を反映した正確な情報であることで、正しい実行手順を把握したい。

#### Acceptance Criteria

8.1. 本スペックの成果物として、`templates/CLAUDE.md` のマッピング表で query_extract・query_answer・query_fix の Execution Mode が「CLI (Hybrid)」に更新されていること

8.2. 本スペックの成果物として、`templates/AGENTS/query_extract.md`・`query_answer.md`・`query_fix.md` の Execution Mode セクションの実行モード表記および関連する説明文（実行手順・実行宣言の要否等）が CLI (Hybrid) の実態に合わせて更新されていること

8.3. 本スペックの成果物として、`templates/AGENTS/README.md` のエージェント一覧テーブルで query_extract・query_answer・query_fix の実行モードが「CLI (Hybrid)」に更新されていること

### Requirement 9: プロンプトの一元管理

**Objective:** 運用者として、AGENTS/ファイルのルール変更がCLIの動作に自動的に反映されることで、ルール定義の二重管理による乖離を防ぎたい。

#### Acceptance Criteria

9.1. The CLI shall AGENTS/ファイルをプロンプトの正規ソースとして使用し、プロンプトルールを Python コード内にハードコードしない

9.2. When AGENTS/ファイルのルール定義が更新された場合, the CLI shall 次回実行時に更新後の内容を使用する（CLIコードの変更なしに反映される）
