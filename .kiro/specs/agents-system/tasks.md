# Implementation Plan

## Implementation Notes

<!-- タスク実装中に判明したクロスカッティングな知見をここに記録する -->

---

- [ ] 1. ポリシーファイルの確立
- [ ] 1.1 page_policy.md を templates/AGENTS/ に作成する
  - `templates/AGENTS/` ディレクトリを作成する（このタスクで初めてディレクトリを作成）
  - `docs/page_policy.md` 素案をベースに、ポリシー形式（Purpose / Rules）に変換する
  - Wikiページ種別（concepts, methods, projects, entities, synthesis）と各種別の選択ルールを網羅する
  - `templates/AGENTS/page_policy.md` が存在し、docs/ 素案の主要ルールが含まれていること
  - _Requirements: 4.1, 4.2, 4.3_
  - _Boundary: ポリシーファイル_

- [ ] 1.2 (P) naming.md を templates/AGENTS/ に作成する
  - `docs/naming.md` 素案をベースに、ポリシー形式（Purpose / Rules）に変換する
  - ファイル名・ディレクトリ名・frontmatterフィールドの命名規則を網羅する
  - `templates/AGENTS/naming.md` が存在し、docs/ 素案の主要ルールが含まれていること
  - _Requirements: 4.1, 4.2, 4.3_
  - _Boundary: ポリシーファイル_

- [ ] 1.3 (P) git_ops.md を templates/AGENTS/ に作成する
  - `docs/git_ops.md` 素案をベースに、ポリシー形式（Purpose / Rules）に変換する
  - コミット分離ルール・コミットメッセージ形式・ステージング規則を網羅する
  - `templates/AGENTS/git_ops.md` が存在し、docs/ 素案の主要ルールが含まれていること
  - _Requirements: 4.1, 4.2, 4.3_
  - _Boundary: ポリシーファイル_

- [ ] 2. CLIモードタスクエージェントの作成
- [ ] 2.1 ingest.md を templates/AGENTS/ に作成する
  - `docs/ingest.md` 素案（50行）を8セクション共通テンプレート（Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions）に変換する
  - 実行モードを「CLI」として明記し、入力元（`raw/incoming/`）・出力先（`raw/各カテゴリ`）のレイヤー境界制約を定義する
  - `rw_light.py` の `cmd_ingest()` と照合し、入出力パス・エラー処理・コミットルールを整合させる。不整合がある場合は CLI の現行動作を正としてエージェントファイルを合わせ、差異を Implementation Notes に記録する（rw_light.py はスコープ外のため修正しない）
  - Processing Rules にマルチステップルール違反パターン（raw → wiki 直接移動の指示など）がないことを確認する
  - `git_ops.md` との整合性を確認し、Output セクションのコミットルールが一致すること
  - `templates/AGENTS/ingest.md` が8セクション構造で存在し、CLI実装との整合性が確認されていること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 2.2 (P) lint.md を templates/AGENTS/ に作成する
  - `docs/lint.md` 素案（58行）を8セクション共通テンプレートに変換する
  - 実行モードを「CLI」として明記し、入力元（`raw/`）・出力なし（検証のみ）のレイヤー境界制約を定義する
  - `rw_light.py` の `cmd_lint()` と照合し、検証項目・終了コードを整合させる。不整合がある場合は CLI を正とし、差異を Implementation Notes に記録する
  - Processing Rules にマルチステップルール違反パターンがないことを確認する
  - `naming.md` との整合性を確認する（命名規則の検証項目が一致すること）
  - `templates/AGENTS/lint.md` が8セクション構造で存在し、CLI実装との整合性が確認されていること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 2.3 (P) synthesize_logs.md を templates/AGENTS/ に作成する
  - `docs/synthesize_logs.md` 素案（155行）を8セクション共通テンプレートに変換する
  - 実行モードを「CLI (Hybrid)」として明記する
  - `rw_light.py` の `cmd_synthesize_logs()` 内ハードコードプロンプト（`build_synth_prompt` 関数付近を検索）と素案ルールを照合し、両ソースを統合した内容にする。不整合がある場合は CLI を正とし、差異を Implementation Notes に記録する
  - 最終行数を確認し、300行を超える場合はメインファイル＋`synthesize_logs_process.md`に分割する。分割時はメインファイルの Processing Rules 冒頭にサブファイル参照を記載し、マッピング表にはメインファイルのみを記載する
  - `naming.md` との整合性を確認する
  - `templates/AGENTS/synthesize_logs.md` が存在し、CLIハードコードプロンプトとの初期整合性が確認されていること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 2.5_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 2.4 (P) approve.md を templates/AGENTS/ に作成する
  - `docs/approve_synthesis.md` 素案（220行）を8セクション共通テンプレートに変換し、`approve.md` として配置する
  - 実行モードを「CLI」として明記する
  - `git_ops.md` および `page_policy.md` との整合性を確認する（コミットルールとページ種別検証が一致すること）
  - Output セクションに承認メタデータ必須4フィールド（`status: approved`・`reviewed_by` 非空・`approved` が有効ISO日付・`promoted != true`）を明記する
  - `rw_light.py` の `approved_candidate_files()` 関数（関数名で検索）と4フィールド契約を照合し一致を確認する。不整合がある場合は CLI を正とし、差異を Implementation Notes に記録する
  - 最終行数を確認し、300行を超える場合はメインファイル＋`approve_process.md`に分割する。分割時はメインファイルの Processing Rules 冒頭にサブファイル参照を記載し、マッピング表にはメインファイルのみを記載する
  - `templates/AGENTS/approve.md` が存在し、4フィールド承認メタデータ契約がOutput セクションに明記されていること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 2.5_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 3. プロンプトモードタスクエージェントの作成
- [ ] 3.1 synthesize.md を templates/AGENTS/ に作成する
  - `docs/synthesize.md` 素案（175行）を8セクション共通テンプレートに変換する
  - 実行モードを「Prompt」として明記し、入力元（`review/synthesis_candidates/`）・出力先（`wiki/`）のレイヤー境界制約を定義する
  - Processing Rules にマルチステップルール違反パターン（review経由せずwikiへ直接移動等）がないことを確認する
  - Prohibited Actions に raw への書き込み禁止を明記する
  - `page_policy.md` および `naming.md` との整合性を確認する
  - `templates/AGENTS/synthesize.md` が8セクション構造で存在すること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 3.2 (P) query_extract.md を templates/AGENTS/ に作成する
  - `docs/query.md` 素案（278行）を8セクション共通テンプレートに変換し、`query_extract.md` として配置する
  - 実行モードを「Prompt」として明記する
  - Output セクションに出力契約（`review/query/<query_id>/` 配下の4ファイル: `query.md`, `answer.md`, `evidence.md`, `metadata.json`）を明記する（cli-query スペックの前提条件）
  - 他エージェントファイルへの直接参照（`.md` リンク）を除去し、タスク種別名での言及に変換する
  - `naming.md` および `page_policy.md` との整合性を確認する
  - Processing Rules にマルチステップルール違反パターンがないことを確認する
  - 最終行数を確認し、300行を超える場合はメインファイル＋`query_extract_process.md`に分割する。分割時はメインファイルの Processing Rules 冒頭にサブファイル参照を記載し、マッピング表にはメインファイルのみを記載する
  - 確定した出力契約を Implementation Notes に記録する（cli-query スペックの前提条件として参照されるため）
  - `templates/AGENTS/query_extract.md` が存在し、4ファイル出力契約がOutput セクションに明記されていること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 2.5_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 3.3 (P) query_answer.md を templates/AGENTS/ に作成する
  - `docs/query_answer.md` 素案（297行）を8セクション共通テンプレートに変換する
  - 実行モードを「Prompt」として明記し、入出力先（`review/query/<query_id>/`）を定義する
  - 他エージェントへの直接ファイル参照を除去し、タスク種別名（`query_extract タスク`）での言及に変換する
  - `page_policy.md` との整合性を確認する
  - Processing Rules にマルチステップルール違反パターンがないことを確認する
  - 最終行数を確認し、300行を超える場合はメインファイル＋`query_answer_process.md`に分割する（素案297行のため分割が必要になる可能性が高い）。分割時はメインファイルの Processing Rules 冒頭にサブファイル参照を記載し、マッピング表にはメインファイルのみを記載する
  - `templates/AGENTS/query_answer.md` が存在し、300行以内または適切に分割されていること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4, 2.5_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 3.4 (P) query_fix.md を templates/AGENTS/ に作成する
  - `docs/query_fix.md` 素案（106行）を8セクション共通テンプレートに変換する
  - 実行モードを「Prompt」として明記し、入出力先（`review/query/<query_id>/`）を定義する
  - `naming.md` との整合性を確認する
  - Processing Rules にマルチステップルール違反パターンがないことを確認する
  - `templates/AGENTS/query_fix.md` が8セクション構造で存在すること
  - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 2.3, 2.4_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 3.5 (P) audit.md を templates/AGENTS/ に作成する
  - `docs/audit.md` 素案（174行）を8セクション共通テンプレートに変換する
  - 実行モードを「Prompt」として明記する
  - Processing Rules に4監査ティア（Micro-check・Structural・Semantic・Strategic）の定義と各ティアの実行条件を明記する
  - 全3ポリシーファイル（`page_policy.md`, `naming.md`, `git_ops.md`）との整合性を確認する
  - `templates/AGENTS/audit.md` が存在し、4ティアの定義と実行条件が明記されていること
  - _Requirements: 1.1, 1.2, 1.3, 1.6, 2.1, 2.2, 2.3, 2.4_
  - _Boundary: 9タスクエージェントファイル_

- [ ] 4. CLAUDE.md カーネルの更新
- [ ] 4.1 タスク→エージェント+ポリシー+実行モードのマッピング表を更新する
  - 既存マッピング表（Task → AGENTS Mapping セクションを検索）の既存9行の対応関係を保持したまま、ポリシー列・実行モード列を追加してテーブルを拡張する（既存情報の削除は不可。テーブルフォーマットの拡張のみ許可）
  - 9タスク種別すべての行（タスク種別・エージェントパス・ポリシーパス・実行モード）を含む
  - 更新対象セクション以外（Core Principles, Knowledge Flow, Execution Model 等）に変更がないことを確認する
  - 更新後の `templates/CLAUDE.md` にポリシー列・実行モード列を含む9行のマッピング表が存在すること
  - _Requirements: 3.2, 4.5_
  - _Boundary: CLAUDE.md カーネル更新_

- [ ] 4.2 実行フロー・ロード手順・失敗条件判定基準・拡張ガイドを追記する
  - Execution Model セクション直後にExecution Flowセクション（Prompt実行5ステップ・エージェントライフサイクル・CLI実行・Rule Hierarchy）を挿入する
  - Agent Loading Rule セクション内にAgent Loading Procedure（Readツール使用の3ステップ）を追記する
  - Failure Conditions セクションに「required AGENTS are not identified」の3判定基準を追記する
  - Failure Conditions 直後（Final Principle 直前）にExtension Guide（4ステップ）を挿入する
  - git diff を確認し、Core Principles（6項目）、Task Model（タスク選択ルール・曖昧性ルール）、および Execution Model（実行宣言・マルチステップルール）のグローバルルール計10項目が変更されていないことを確認する
  - 更新後のカーネルにタスク固有の処理手順（ingestの移動手順詳細、lintの検証項目一覧等）が残留していないことを確認する
  - 更新後の `templates/CLAUDE.md` にExecution Flow・Agent Loading Procedure・Extension Guideの各セクションが存在し、グローバルルール10項目（Core Principles 6 + Task Model 2 + Execution Model 2）が保全されていること
  - _Requirements: 3.1, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_
  - _Boundary: CLAUDE.md カーネル更新_
  - _Depends: 4.1_

- [ ] 5. AGENTS/README.md の作成
  - エージェント体系の概要（目的・カーネルとの関係・ロードルール）を記載する
  - 全9エージェントファイルの一覧（ファイル名・タスク種別・実行モード・説明）をテーブルで記載する
  - 全3ポリシーファイルの一覧と位置づけ（タスクエージェントとの違い）を記載する
  - タスク×ポリシー依存マトリクス（9タスク × 3ポリシー）を記載する
  - 新しいエージェントの追加手順（4ステップ）を記載する
  - ファイル冒頭に「`templates/CLAUDE.md` が権威ソース、本ファイルは派生コピー」の注記を記載する
  - `templates/AGENTS/README.md` が存在し、概要・エージェント一覧・ポリシー位置づけ・依存マトリクス・追加手順が含まれること
  - _Requirements: 1.4, 1.5, 5.1, 5.2, 5.3, 5.4_
  - _Boundary: AGENTS/README.md_
  - _Depends: 4.2_

- [ ] 6. (P) docs/user-guide.md 初版の作成
  - 基本的な運用サイクル（lint → ingest → synthesize → approve → audit）の詳細手順を記載する
  - 既存CLIコマンド（init, ingest, lint, lint query, synthesize-logs, approve）のリファレンス（使用方法・引数・出力例）を記載する
  - プロンプトレベルタスク（synthesize, query_answer, query_extract, query_fix, audit）のClaude CLIでのAGENTSロード手順を記載する
  - 既存Vaultのエージェント更新手順（`rw init` の re-init による `templates/AGENTS/` 再配置）を記載する
  - `docs/user-guide.md` が存在し、運用サイクル・CLIリファレンス・プロンプト実行・Vault更新の4セクションが含まれること
  - _Requirements: 6.1, 6.2, 6.3, 6.4_
  - _Boundary: docs/user-guide.md_
  - _Depends: 4.2_

- [ ] 7. 統合検証
  - `templates/AGENTS/` 配下に9エージェント + 3ポリシー + README.md = 計13ファイル（分割ファイルがある場合はそれを含む）が存在することを確認する
  - 全エージェントファイルに Purpose, Execution Mode, Prerequisites, Input, Output, Processing Rules, Prohibited Actions, Failure Conditions の8セクション見出しが存在することを確認する
  - grep で全エージェントファイル内に他エージェントファイル名（例: `query_extract.md`, `ingest.md`）への直接参照がないことを確認する
  - `templates/CLAUDE.md` のマッピング表に9行全て存在することを確認する
  - git diff で Core Principles、Task Model、Execution Model の3セクション内容が変更されていないことを確認する（AC 3.4 の保全対象10項目）
  - `audit.md` に Micro-check, Structural, Semantic, Strategic の4ティアが記載されていることを確認する
  - 各エージェントファイルの入出力先が仕様案の知識フロー（raw → review → wiki）に違反しないことを横断的に確認する
  - 全確認項目がパスすること（問題がある場合は該当タスクに戻り修正する）
  - _Requirements: 1.1, 1.2, 1.3, 1.6, 2.1, 2.2, 3.2, 3.3, 3.4_
  - _Depends: 5, 6_

- [ ] 8. CHANGELOG.md への agents-system エントリ追記
  - `[Unreleased]` セクションに agents-system スペック成果物を追記する
  - 成果物として、9エージェントファイル・3ポリシーファイル・CLAUDE.md更新・AGENTS/README.md・docs/user-guide.md を列挙する
  - `CHANGELOG.md` に agents-system の追記セクションが存在すること
  - _Requirements: 7.1_
  - _Depends: 7_
