# Product Overview

Rwiki は、Andrej Karpathy の LLM Wiki アプローチに着想を得た **AI 支援ナレッジベース構築システム**。断片的な情報（記事、論文、会議メモ、コードスニペット、LLM ログ）を、制御された 3 層パイプラインを通じて体系的・キュレーション済みのナレッジベースへ変換する。

## Core Capabilities

1. **Raw → Review → Wiki パイプライン**: 非構造データを取り込み、LLM 分析で統合候補を抽出し、人間の明示的承認を経て Wiki に公開
2. **5 ステップ運用サイクル**: ingest → lint → synthesize → approve → audit
3. **テンプレートベースの Vault 初期化**: `rw init` でディレクトリ構造・Git・CLAUDE.md カーネル・テンプレートを自動構成
4. **Query & Audit**: Raw 素材からの回答抽出、整合性修正、多階層監査（micro/weekly/monthly/quarterly）

## Target Use Cases

- 複雑で進化し続ける情報を管理するナレッジワーカー・研究者
- トレーサビリティと監査可能性を求めるチーム
- Obsidian Vault ワークフロー上で AI キュレーションを活用したいユーザー

## Value Proposition

**Human-in-the-Loop の知識品質保証** — LLM は統合・分析を支援するが、Wiki への直接書き込みは禁止。すべての Wiki 書き込みに人間の承認を必須とすることで、信頼性を担保する。

## Design Principles

- **Safety Guardrails**: LLM は raw/wiki 層を直接変更できない
- **Traceability**: すべての変更は Git で追跡、JSON ログで監査証跡を保持
- **Zero-dependency**: 外部ライブラリ不要、Python 標準ライブラリのみで動作

---
_created_at: 2026-04-18_
