# workflow-process-authority-map

_purpose: prescribed workflow process → 段集合の単一権威ソース文書の対応表（Requirement 9 受入 10）_
_正本参照: `.kiro/specs/dual-reviewer-implementation-governance` requirements Requirement 9（受入 1・2・10）／design「Workflow Execution Ledger and Enforcement Model」小節 1／1.2／1.3_

---

## 1. この表の役割

各 prescribed workflow process の段集合を、ただ 1 つの権威ソース文書・節へ一意対応づける。実行台帳生成器（Task 12）と独立再導出器（Task 13）は本表の行から `authority_document_path` の `authoritative_section` を一意特定し、`stage_extraction_rule` で段集合を抽出する。

権威ソースが一意特定できない、抽出が空・重複、または当該節が確定書式でない場合は「曖昧」とし、黙って段集合を返さず fail-closed とする（design 小節 4）。

## 2. process taxonomy（2 階層）

- **workflow-level process**（ワークフロー全体に及ぶ。phase 非分割）: `reopen-procedure`、`cross-spec-alignment`
- **phase-level process**（spec phase に紐づき phase 別に分割）: spec phase ∈ {`intent` / `requirements` / `design` / `tasks` / `implementation`} の各々について `<phase>-phase-execution`、`<phase>-review-wave`、`<phase>-alignment-gate`

## 3. 行スキーマ

- `process_id` — 上記値域（workflow-level は単一名、phase-level は `<phase>-<process-type>`）
- `authority_document_path` — 段集合の権威ソース文書の repo 相対パス（単一）
- `authoritative_section` — 当該 process の段集合が記された節（見出しまたは節番号で一意特定）
- `stage_extraction_rule` — `authoritative_section` 内の段集合は番号付き stage 見出しの単一リストとして機械抽出する（確定書式 D5-1 と一体。曖昧時 fail-closed）

`stage_extraction_rule` は全 process 共通で「番号付き stage 見出しの単一リストとして機械抽出」とする。

## 4. workflow-level process

| process_id | authority_document_path | authoritative_section |
|------------|-------------------------|-----------------------|
| `reopen-procedure` | `docs/coordination/workflow-repair-procedure.md` | `## 2. 手続き一覧`（Step 1〜10） |
| `cross-spec-alignment` | `operations/REVIEW_PROTOCOL.md` | `## 4. フェーズ完走後のフィーチャー横断レビューパターン` |

## 5. phase-level process

### 5.1 review-wave

| process_id | authority_document_path | authoritative_section |
|------------|-------------------------|-----------------------|
| `requirements-review-wave` | `operations/REVIEW_PROTOCOL.md` | `## 2. 要件レビューの 5 ラウンド構成と波及精査` |
| `design-review-wave` | `operations/REVIEW_PROTOCOL.md` | `## 3. 設計レビューの 10 観点と進め方` |
| `tasks-review-wave` | `operations/REVIEW_PROTOCOL.md` | `## 5. タスクレビューの 7 観点と進め方` |
| `intent-review-wave` | 未確立 | 未確立 |
| `implementation-review-wave` | 未確立 | 未確立 |

### 5.2 alignment-gate

| process_id | authority_document_path | authoritative_section |
|------------|-------------------------|-----------------------|
| `requirements-alignment-gate` | `operations/HUMAN_WORKFLOW.md` | `### 5.2.5 multi-feature alignment gate` / `#### requirements alignment gate` |
| `design-alignment-gate` | `operations/HUMAN_WORKFLOW.md` | `### 5.2.5 multi-feature alignment gate` / `#### design alignment gate` |
| `tasks-alignment-gate` | `operations/HUMAN_WORKFLOW.md` | `### 5.2.5 multi-feature alignment gate` / `#### tasks alignment gate` |
| `intent-alignment-gate` | 未確立 | 未確立（intent に multi-feature alignment gate は定義されない） |
| `implementation-alignment-gate` | 未確立 | 未確立 |

### 5.3 phase-execution

| process_id | authority_document_path | authoritative_section |
|------------|-------------------------|-----------------------|
| `intent-phase-execution` | `operations/HUMAN_WORKFLOW.md` | `### 5.2 spec フェーズ` |
| `requirements-phase-execution` | `operations/HUMAN_WORKFLOW.md` | `### 5.2 spec フェーズ` |
| `design-phase-execution` | `operations/HUMAN_WORKFLOW.md` | `### 5.2 spec フェーズ` |
| `tasks-phase-execution` | `operations/HUMAN_WORKFLOW.md` | `### 5.2 spec フェーズ` |
| `implementation-phase-execution` | `operations/HUMAN_WORKFLOW.md` | `### 5.3 implementation フェーズ` |

## 6. 確定書式適合状態（fail-closed 既定の明示）

`stage_extraction_rule` は段集合が「番号付き stage 見出しの単一リスト」で記されていることを要求する。本表が指す各権威節の確定書式適合は現時点で次のとおり。未適合・未確立はいずれも設計どおり fail-closed であり、黙って段集合を返さない。

- 確定書式適合（番号付き段見出しの単一リスト）:
  - `reopen-procedure` → `workflow-repair-procedure.md` `## 2. 手続き一覧` は Step 1〜10 の番号付き段見出し単一リストとして維持（同 §2.1 で確定書式維持を明記）
- 確定書式 未適合（権威文書は指せるが当該節が番号付き段見出し単一リストでない＝抽出時 fail-closed）:
  - `cross-spec-alignment`、`requirements-review-wave`、`design-review-wave`、`tasks-review-wave`、`requirements-alignment-gate`、`design-alignment-gate`、`tasks-alignment-gate`、`intent-phase-execution`、`requirements-phase-execution`、`design-phase-execution`、`tasks-phase-execution`、`implementation-phase-execution`
- 権威ソース 未確立（単一権威節が未特定＝fail-closed）:
  - `intent-review-wave`、`implementation-review-wave`、`intent-alignment-gate`、`implementation-alignment-gate`

確定書式を権威ソース文書へ課す追記（未適合の解消）は、design 小節 6（要件横断整合ゲート C 群の取り込み先＝上位文書同期 C-2／C-3）と一体で行う。本表は対応の一意性を確定するものであり、未適合・未確立の解消は別途の上位文書同期で扱う。それまでは当該 process の不可逆操作直前判定は fail-closed となる。
