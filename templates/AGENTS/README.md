# AGENTS/ — エージェントシステム概要

> **注記**: `templates/CLAUDE.md` が権威ソース。本ファイルはその派生コピーである。
> マッピング表・タスク種別・ロードルールに変更がある場合は `CLAUDE.md` を先に更新すること。

---

## 目的

このディレクトリには、Rwikiの各タスク種別に対応するサブプロンプトファイルが格納されている。

**カーネル（CLAUDE.md）** はグローバルルール・タスク分類・エージェントロードルールを定義する。
**エージェントファイル（AGENTS/*.md）** は各タスクの実行ルール・制約・出力形式を定義する。

Claudeは常にCLAUDE.mdをロードし、タスク実行時に必要なエージェントファイルのみを追加ロードする。

---

## エージェントファイル一覧

| ファイル | タスク種別 | 実行モード | 説明 |
|---|---|---|---|
| ingest.md | ingest | CLI | raw/incoming/ から raw/ へのファイル移動 |
| lint.md | lint | CLI | raw/incoming/ のバリデーション・正規化 |
| synthesize.md | synthesize | Prompt | raw/ から review/ への知識候補生成 |
| synthesize_logs.md | synthesize_logs | CLI (Hybrid) | llm_logsからsynthesis候補の抽出 |
| approve.md | approve | CLI | synthesis候補の wiki/synthesis/ への昇格 |
| query_answer.md | query_answer | Prompt | wiki知識を使った直接回答 |
| query_extract.md | query_extract | Prompt | 構造化クエリアーティファクトの生成 |
| query_fix.md | query_fix | Prompt | クエリアーティファクトのlint修復 |
| audit.md | audit | Prompt | wiki整合性・一貫性・構造の監査 |

---

## ポリシーファイル一覧

ポリシーファイルはエージェントファイルと同じディレクトリに配置されるが、タスクエージェントとは異なる役割を持つ。

| ファイル | 説明 |
|---|---|
| page_policy.md | Wikiページ種別定義と選択ルール |
| naming.md | ファイル名・スラッグ・frontmatterの命名規則 |
| git_ops.md | Gitオペレーション・コミット分離ルール |

**タスクエージェントとの違い**:
- ポリシーファイルは単体でロードされることはない
- 必要なタスクエージェントと組み合わせてロードする
- ポリシーはルール定義のみを含み、処理手順（8セクション）は持たない

---

## タスク×ポリシー依存マトリクス

| タスク | page_policy.md | naming.md | git_ops.md |
|---|---|---|---|
| ingest | — | — | ✓ |
| lint | — | ✓ | — |
| synthesize | ✓ | ✓ | — |
| synthesize_logs | — | ✓ | — |
| approve | ✓ | — | ✓ |
| query_answer | ✓ | — | — |
| query_extract | ✓ | ✓ | — |
| query_fix | — | ✓ | — |
| audit | ✓ | ✓ | ✓ |

---

## エージェントロードルール

- AGENTS/ 配下の全ファイルを一度にロードしてはならない
- タスク実行時は、CLAUDE.mdのマッピング表に基づいて必要なエージェント+ポリシーのみをロードする
- ロード手順:
  1. リクエストからタスク種別を特定する
  2. CLAUDE.mdのマッピング表で必要なAgent・Policyファイルを確認する
  3. Read toolで各ファイルをロードする: `Read("AGENTS/<file>.md")`

---

## 新しいエージェントの追加手順

新しいタスク種別に対応するエージェントを追加する場合:

1. `AGENTS/<new-task>.md` を8セクション構造（Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions）で作成する
2. `CLAUDE.md` のマッピング表に新しい行（Task / Agent / Policy / Execution Mode）を追加する
3. `CLAUDE.md` のTask Model「Task Types」リストに新しいタスク種別を追加する
4. 本ファイル（README.md）のエージェント一覧・依存マトリクスを更新する
