# workflow-execution-ledger-template

_purpose: prescribed workflow process の実行を、後段の独立再導出・enforcement・事後監査が機械的に突合できる形で記録するための実行台帳ひな型_
_正本参照: `.kiro/specs/dual-reviewer-implementation-governance` requirements Requirement 9（受入 1・2・10）／design「Workflow Execution Ledger and Enforcement Model」小節 1／1.1／1.2／1.3／2／3／4_

---

## 1. このひな型の役割

prescribed workflow process（`operations/WORKFLOW_OVERVIEW.md` が規定する phase execution / review wave / alignment gate / reopen procedure / cross-spec alignment）に着手する前に、`workflow-process-authority-map.md` が一意指定する権威ソース文書から段集合を導出し、本ひな型に従って台帳インスタンスを `docs/coordination/ledgers/<process_id>-<date>.md` に新規生成する。

本ひな型は記入様式の正本であり、各欄の値を主張や体裁で満たすことはできない（完了は repo 内証跡 artifact の存在＋構造適合で判定する）。

---

## 2. ヘッダ欄（台帳インスタンス先頭に 1 つ）

- `process_id` — 対象 prescribed workflow process の識別子（authority-map の `process_id` と一致）
- `ledger_format_version` — 本ひな型の形式版番号（形式移行は破壊的一括書換でなく本版番号で扱う）
- `generated_at` — 台帳インスタンス生成日時（ISO 8601）
- 導出元 provenance（design 小節 1.3 の確定値域）
  - `authority_path` — 権威ソース文書の repo 相対パス（authority-map の `authority_document_path` と一致）
  - `authoritative_section_id` — authority-map の `authoritative_section`（節見出しまたは節番号）
  - `section_content_hash` — `authoritative_section` の本文を正規化（行末・連続空白・前後空白を正規化）したうえでの content hash。文書全文ではなく当該節のみが対象。ハッシュアルゴリズムの具体は実装段（Task 12）で確定
  - `authority_git_commit` — 補助。権威文書の git commit を併記してよい（一致判定の正本は `section_content_hash`）
- `supersedes` — 本台帳が置換した旧台帳インスタンスへの参照（無ければ空）。破壊的上書きは禁止。陳腐化／改竄遮断で再生成した場合に旧台帳をリンクし監査の足跡を残す
- `supersede_reason` — `supersedes` が非空のとき、人手による置換理由記録（必須）

---

## 3. 段集合表（権威ソースの段ごとに 1 行）

各行は権威ソースから導出した段（stage）に対応する。行の追加・削除・改名は権威ソースの段集合からの導出に従い、台帳側で独自に増減しない。

各行の欄:

- `stage` — 段名（権威ソースの番号付き stage 見出しと一致）
- `sot_citation` — 当該段の正本出典（文書 + 節）
- `completion_predicate` — 完了判定条件。repo 内証跡 artifact の存在＋構造適合で定義し、主張や体裁では満たせない（design 小節 2、Requirement 5 必須セクション／metric キー検査と同型）
- `independence_requirement` — 独立性要件。独立プロセスが生成した証跡 artifact（`docs/reviews/` または `docs/coordination/` 配下の実体）への必須リンク。台帳内の自己申告文字列では満たせない（design 小節 3）
- `evidence_artifact_path` — completion を満たした証跡 artifact の repo 相対パス（completion 充足時に記入。未充足時は空）
- `independent_evidence_ref` — independence requirement を満たす独立証跡 artifact への参照（要件がある段のみ。未充足時は空）
- `stage_status` — 段状態。foundation 所有の正準 validator 状態語彙（`not_run` / `passed` / `failed` / `blocked`）を参照し、統治側で再定義しない

記入例（値はプレースホルダ）:

```
| stage | sot_citation | completion_predicate | independence_requirement | evidence_artifact_path | independent_evidence_ref | stage_status |
|-------|--------------|----------------------|--------------------------|------------------------|--------------------------|--------------|
| <段名> | <文書>#<節>  | <証跡 artifact 存在＋構造適合条件> | <独立証跡へのリンク要否と対象> | <repo 相対パス or 空> | <独立証跡参照 or 空> | not_run |
```

---

## 4. 通過マーカー記録欄（enforcement pass 時に追記）

不可逆ワークフロー操作（design 小節 4 の最小集合）の直前判定が pass したとき、本欄に通過マーカーを追記する。マーカー無き不可逆遷移はバイパス＝fail-closed。

各通過マーカーの最低限の記録項目:

- `process_id`
- `target_irreversible_operation` — 対象の不可逆操作
- `timestamp` — ISO 8601
- `reconciliation_hash` — 独立再導出と台帳の突合ハッシュ

---

## 5. 遮断・検知記録欄（blocked / fail-closed / 陳腐化・改竄）

pass だけでなく、遮断・検知の各イベントも本台帳内（別証跡に分散させない）に記録する。これにより遮断・検知の事実が事後監査可能となる（design 小節 4）。

各イベントの最低限の記録項目:

- `process_id`
- `target_irreversible_operation` — 対象の不可逆操作
- `decision` — `pass` / `blocked`
- `reason` — 欠落した段、または不一致理由の区別（`provenance 不一致` / `段集合不一致` / `権威ソース曖昧` / `enforcement バイパス` / `台帳不在` / `検査不能` 等）
- `timestamp` — ISO 8601

---

## 6. 記入規律

- 着手前生成: 起草または実質作業の前に権威ソースから段集合を導出し本ひな型で新規生成する。事後の遡及生成は不可
- 黙った再利用・上書きの禁止: 既存台帳がある場合、(a) provenance 一致 ∧ (b) 構造検査合格 ∧ (c) 独立再導出の段集合一致 の AND を満たすときのみ冪等に追記。いずれか不満なら fail-closed で遮断し、旧台帳保全＋`supersedes` リンク＋`supersede_reason` 記録のうえ新台帳を生成する（design 小節 1.1）
- 検査不能は pass としない: 不在・実行失敗・権威ソース曖昧・台帳不在はいずれも pass とみなさず fail-closed（design 小節 4・Requirement 9 受入 11）
- 状態語彙は foundation 正準語彙（`not_run` / `passed` / `failed` / `blocked`）を参照し再定義しない
