# AGENTS/audit.md

## Purpose

wikiの整合性・一貫性・構造を読み取り専用で評価する。
問題を検出・分類・報告する。ファイルを修正しない。

**Audit is report-first, repair-second.**

---

## Execution Mode

**CLI (Hybrid)** — `rw audit <tier>` コマンドで実行。
- `rw audit micro` / `rw audit weekly`: Python静的チェック（Claude CLI不使用）
- `rw audit monthly` / `rw audit quarterly`: 本ファイルをプロンプトソースとして Claude CLI を呼び出す

CLI実行時はコマンド自体が実行宣言を兼ねる。
対話型プロンプトで直接実行する場合は、本ファイルをロードしてから実行すること。

---

## Prerequisites

- `wiki/` にコンテンツが存在すること

---

## Input

- 対象: `wiki/` 配下の全ファイル（ティアに応じてスコープを絞る）
- `index.md`・`log.md` を含む

---

## Output

- 監査レポートのみ（ファイルの変更なし）

### 出力フォーマット

```markdown
# Wiki Audit Report — YYYY-MM-DD

## Summary
- pages scanned:
- critical:
- error:
- warn:
- info:

## Structural Findings
- [CRITICAL] ...
- [WARN] ...

## Semantic Findings
- [ERROR] Conflict candidate between [[a]] and [[b]]: ...
- [WARN] [TENSION] ...

## Strategic Findings
- synthesis underdeveloped in <domain> cluster
- tools pages weakly connected to methods

## Metrics
- orphan rate: X / total
- bidirectional compliance: XX%
- sourced pages: XX%
- [CONFLICT] count: X

## Recommended Actions
1.
2.
3.
```

---

## Processing Rules

### 4監査ティアの定義と実行条件

#### Tier 0: Micro-check（ingest毎）

**実行条件**: 各ingest後、または最近のwiki更新後

**スコープ**: 現在のingestまたは更新に影響されたページのみ（full structural auditではない）

**チェック項目**:
- 最近更新されたページの broken `[[links]]`
- 新規・更新されたwikiページに対する `index.md` の欠落エントリ
- YAML frontmatterの整合性（title欠落・フィールド異常）

#### Tier 1: Structural Audit（週次または10 ingest毎）

**実行条件**: 週次、またはingest10回毎

**チェック項目**:
- Broken `[[links]]`
- Orphanページ（incoming linksなし・index.mdリンク除く）
- `index.md` 欠落エントリ・陳腐化エントリ
- YAML frontmatterの問題（title・tags・updated 欠落）
- テンプレートごとの必須セクション欠落
- ファイル命名違反（non-kebab-case・非ASCII）
- `sources:` フィールドの存在しないrawファイルへの参照

#### Tier 2: Semantic Audit（月次）

**実行条件**: 月次

**チェック項目**:
- 同一コンセプトのページ間で矛盾する定義
- 不整合なメソッド比較（異なる評価軸）
- プロジェクトの `status` フィールドと `Current Status` セクションの不一致
- 同一人物の所属・役割の異なる記述
- 同一ソースの矛盾するサマリー

#### Tier 3: Strategic Audit（四半期）

**実行条件**: 四半期

**チェック項目**:
- 孤立トピッククラスター（クロスドメインリンクなし）
- ingest済みだがprojectsに反映されていないpapers
- methodsにリンクされていないtoolsページ
- conceptsボリュームに対して未発達なsynthesisページ
- 密カバレッジのドメインと空のドメインの対比
- 必要に応じてCLAUDE.mdスキーマ修正の提案

### コンフリクト分類タグ

| タグ | 意味 |
|---|---|
| `[CONFLICT]` | ページ間の明確な矛盾 |
| `[TENSION]` | 条件依存の差異（両方が有効な可能性） |
| `[AMBIGUOUS]` | 不十分な定義・解釈が不明瞭 |

タグ付けは、ユーザーへの報告と確認の後にのみ行う。
確認なしにファイルにタグを書き込まない。

### 優先度レベル

| レベル | 意味 | 例 |
|---|---|---|
| CRITICAL | システム整合性を破壊 | YAML破損・ソースパス欠落・indexの重複 |
| ERROR | 知識の信頼性を低下 | 事実の矛盾・根拠なし主張・プロジェクト状態の不一致 |
| WARN | 品質低下シグナル | Orphanページ・必須セクション欠落・一方向リンク |
| INFO | 改善提案 | タグの不整合・見出し粒度・typeフィールド欠落 |

### 監査メトリクス

**Structural**:
- スキャンページ数
- Orphanページ数
- Broken link数
- index欠落エントリ数
- Frontmatter問題数

**Connectivity**:
- ページあたりの平均内部リンク数
- 双方向リンク準拠率（%）
- concepts→methods→projectsのクロスリンク数
- 他wikiページを参照するSynthesisページ数

**Reliability**:
- 1つ以上のsourceを持つページの割合（%）
- `[CONFLICT]` 数
- `[TENSION]` 数
- `[AMBIGUOUS]` 数

**Growth**:
- 新規ページ / 更新ページの比率（直近期間）
- 対応するwikiページのないrawソース数
- Synthesis蓄積率

---

## Prohibited Actions

- auditモード中のファイル変更
- 自動修正（ユーザーの明示的な指示なし）
- コンフリクトタグを確認なしにファイルに書き込む
- `raw/` の変更
- `wiki/` への書き込み
- Micro-checkでfull structural auditを実行する（スコープ超過）

---

## Failure Conditions

即座に中止する条件:

- ファイルの変更を試みている → 即座に停止
- ユーザーの確認なしにコンフリクトタグを書き込もうとしている → 停止して確認を求める
- `wiki/` が空またはコンテンツがない → 監査スキップ・報告のみ
