# Research & Design Decisions

## Summary
- **Feature**: `agents-system`
- **Discovery Scope**: Extension（既存テンプレート体系にAGENTS/サブプロンプトを追加）
- **Key Findings**:
  - docs/ に12の素案ファイルが存在し、そのうち9がタスクエージェント、3がポリシー
  - 素案サイズは30行（page_policy）〜297行（query_answer）と大きく異なる
  - ポリシーファイルは小規模（合計142行）で、独立ファイルとしてAGENTS/に配置可能
  - 既存CLAUDE.mdカーネル（207行）への追記は最小限に抑え、肥大化を防止

## Research Log

### docs/ 素案の構造分析
- **Context**: 各素案のサイズ・構造・ポリシー依存を調査
- **Sources Consulted**: docs/ 配下12ファイル
- **Findings**:

| ファイル | 行数 | 分類 | ポリシー依存 |
|---------|------|------|------------|
| ingest.md | 50 | エージェント | git_ops |
| lint.md | 58 | エージェント | naming (暗黙) |
| synthesize.md | 175 | エージェント | page_policy, naming (暗黙) |
| synthesize_logs.md | 155 | エージェント | naming (暗黙) |
| query.md | 278 | エージェント | naming, page_policy (暗黙) |
| query_answer.md | 297 | エージェント | page_policy (暗黙) |
| query_fix.md | 106 | エージェント | naming (暗黙) |
| audit.md | 174 | エージェント | 全3ポリシー（メタ監査） |
| approve_synthesis.md（→ approve.md に改名） | 220 | エージェント | git_ops, page_policy (暗黙) |
| page_policy.md | 30 | ポリシー | — |
| naming.md | 47 | ポリシー | — |
| git_ops.md | 65 | ポリシー | — |

- **Implications**: 
  - ポリシーは小規模で安定的。独立ファイルとして配置し、��要時にエージェントと共にロードする方式が適切
  - 大規模��案（query系���approve）は精査時に整理・圧縮が必要。分割は最終サイズ判定後に決定

### エージェントファイルの共通構造分析
- **Context**: 素案間で共通するセクションパターンの調査
- **Findings**:
  - 全素案に共通: Purpose/目的、Rules/ルール、Output/出力形式、Failure Conditions/失敗条件
  - 多くの素案に存在: Input制約、Prohibited Actions/禁止事項
  - 一部のみ: Process（ステップ定義）、Quality Checklist
- **Implications**: 共通テンプレートを定義可能。必須8セクション: 目的、実行モード、前提条件、入力元、出力先、処理ルール、禁止事項、失敗条件

### カーネル更新の影響分析
- **Context**: CLAUDE.mdへの追記がカーネルサイズに与える影響
- **Findings**:
  - 現在のカーネル: 207行
  - 必要な追記: 実行フロー詳細化（~15行）、CLI/プロンプト区別（~10行）、ロード手順（~10行）、失敗条件判定基準（~5行）、拡張ルール（~5行）、ルール階層原則（~5行）
  - 推定追記量: ~50行、削減量（タスク固有ルールのAGENTS/移動）: ~0行（現カーネルにはタスク固有ルールがほぼない）
  - 更新後推定: ~257行
- **Implications**: カーネルは現状でもタスク固有ルールをほぼ含まないため、「移動」よりも「追記」が主な変更。257行は許容範囲

## Design Decisions

### Decision: ポリシーファイルの配置方式
- **Context**: page_policy(30行), naming(47行), git_ops(65行) の配置先
- **Alternatives Considered**:
  1. CLAUDE.mdカーネルに統合 — 常時ロード、追加ロード不要。ただし+142行で肥大化リスク
  2. AGENTS/ に独立ファイルとして配置 — 必要時のみロード、カーネル軽量維持
  3. 各エージェントファイルに埋め込み — 自己完結、ただし重複発生
- **Selected Approach**: AGENTS/ に独立ファイルとして配置
- **Rationale**: カーネルの肥大化を防ぐ（Req 3 Objective）。ポリシーは全タスクで共通ではなく、タスクごとに必要なものが異なる。タスク→エージェント+ポリシーの複合マッピングで必要時のみロード。ポリシー更新時にエージェントファイルを修正する必要がない
- **Trade-offs**: ロード時に複数ファイルを読む必要あり。しかしファイル数は最大3で管理可能

### Decision: エージェントファイルの命名方針
- **Context**: タスク種別とファイル名の非対称（query_extract → query.md、approve → approve_synthesis.md）
- **Alternatives Considered**:
  1. 現行名維持 — docs/素案との一貫性、既存マッピングの継続
  2. タスク種別名に統一 — 全ファイルを1:1マッピング（query_extract.md、approve.md）
- **Selected Approach**: タスク種別名に統一（query.md → query_extract.md、approve_synthesis.md → approve.md）
- **Rationale**: 9ファイル全てがタスク種別名と1:1対応となり、マッピング表の非対称説明が不要になる。query.md は query_answer, query_fix と並ぶ3ファイルの中で曖昧、approve_synthesis.md は過剰に詳細。docs/ 素案は参照元であり成果物ではないため、素案との命名不一致は許容可能
- **Trade-offs**: docs/ 素案との追跡時にファイル名が異なる（query.md → query_extract.md、approve_synthesis.md → approve.md）。design.md Implementation Notes にマッピングを明記して対応する

### Decision: 大規模エージェントファイルの分割方針
- **Context**: query_extract.md（素案query.md: 278行）, query_answer.md(297行), approve.md（素案approve_synthesis.md: 220行）の分割要否
- **Alternatives Considered**:
  1. 即座に分割 — サブファイル参照構造を導入
  2. 単一ファイル維持 + 閾値ガイドライン — 精査後の最終サイズで再判定
- **Selected Approach**: 単一ファイル維持 + 300行閾値ガイドライン
- **Rationale**: docs/素案のサイズは精査後に変動する（不要部分の削除、構造の整理で短縮される可能性）。300行以内であればClaude のコンテキスト消費として許容範囲。分割は複数ファイルロードの複雑性を増す
- **Trade-offs**: 最終版が300行を超えた場合、タスク実装時に分割が必要。分割パターン: メインファイル（ルール・制約）+ サブファイル（プロセス・手順詳細）

### Decision: CLI/プロンプト実行の区別方式
- **Context**: 9タスク中、CLI実行とプロンプトレベル実行が混在
- **Findings**:
  - CLI実行: ingest, lint, synthesize-logs, approve（rw_light.py に実装済み）
  - プロンプトレベル: synthesize, query_answer, query_extract, query_fix, audit
  - ハイブリッド: synthesize-logs（CLI が内部で Claude CLI を呼び出す）
- **Selected Approach**: 各エージェントファイルに「実行モード」セクションを設け、CLI/プロンプト/ハイブリッドを明記。CLAUDE.mdのマッピング表にも実行モード列を追加
- **Rationale**: 運用者とClaude双方が、どのタスクでエージェントファイルのロードが必要かを即座に判断できる

## Synthesis Outcomes

### 一般化
- 9エージェントファイルに共通テンプレート（8セクション）を適用
- ポリシーファイルはエージェントと同じ��ィレクトリに配置するが、テンプレート構造は異なる（ポリシー独自の簡潔な形式）

### 構築 vs 採用
- 全てMarkdownファイルとして構築。外部ツール・ライブラリ不要
- エージェントファイルテンプレートは独自設計（既存のフレームワークに相当するものが存在しない）

### 簡素化
- ポリシーの埋め込みではなく独立ファイル方式を採用し、重複を排除
- 分割���即座に行わず、閾値ベースの遅延判断とする
- 命名は現行維持し、リネームの追加作業を回避

## Risks & Mitigations
- エージェントファイルとCLI実装のルール二重管理 → Adjacent expectationsに記録済み。短期的にはエージェントファイルを「正」とし、CLI側はスコープ外
- ポリシー独立ファイル方式でのロード忘れ → マッピング表に必須ポリシーを明記、README.mdに依存関係マトリクスを記載
- 大規模ファイルのコンテキスト消費 → 300行閾値ガイドライン、精査時に圧縮を優先
