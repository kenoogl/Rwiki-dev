# Design Review v2 — 機械検証中心レビュー方式 詳細仕様

> 連携 memory: `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_review_mechanical.md` (方針 + 中核原則)

## 位置付け

- **適用対象**: design.md / tasks.md (requirements.md は旧方式 5 ラウンドを継続適用)
- **目的**: 設計・タスク層のレビューで LLM の判断介入を 2 箇所に限定し、構造性質を機械検証中心で評価する
- **試行先**: Spec 2 design (commit `23fffd0`、design.md 918 行)
- **比較対象**: Spec 5 design 旧方式 10 ラウンド適用結果 (累計 18 件 Edit、本質的レビュー後検出ゼロ)

## 全体パイプライン

```
[design.md / tasks.md + requirements.md]
        │
        ↓ Phase 1: メタデータ抽出 (LLM 呼出 1 回目)
[design_metadata.yaml]
        │
        ↓ Phase 2-A: 構造チェック (Python script)
        ↓ Phase 2-B: トレーサビリティチェック (Python script)
        ↓ Phase 2-C: 型チェック (Python script)
        ↓ Phase 2-D: リスクパターンチェック (Python script)
        ↓ Phase 2-E: 意味的ドリフト検出 (LLM 呼出 2 回目)
[findings[]]
        │
        ↓ Phase 3: 採点 + risk_level 判定 (Python script)
[review_report.yaml]
```

LLM 呼出は **2 回のみ** (Phase 1 / Phase 2-E)。Phase 2-A〜D / Phase 3 はすべて決定論的 Python script で機械検証。

---

## Phase 1: メタデータ抽出 LLM プロンプト

### 入力

- `{design_path}`: design.md ファイルパス
- `{requirements_path}`: requirements.md ファイルパス
- `{tasks_path}` (optional): tasks.md ファイルパス (tasks 層レビュー時のみ)

### LLM プロンプト本文

````
あなたは設計書の機械可読メタデータを抽出する extractor である。判断・評価・改善提案・良し悪しの採点は一切行わない。設計書から事実のみを構造化して抽出することが任務である。

# 入力

- {design_path} の内容: 設計書 markdown
- {requirements_path} の内容: 上位仕様書 markdown (parent_specs ID 解決用)
- (tasks レビュー時のみ) {tasks_path} の内容: タスクリスト markdown

# 出力形式 (YAML、すべてのキーを必ず出力する。値が無い場合は null か空配列を明示)

```yaml
feature_name: <spec name>
extraction_warnings: []                        # 抽出不能だった項目を「unit_id + 理由」のみで列挙、判断は書かない

design_units:                                   # 設計書内の各「設計対象」を 1 unit として抽出
  - id: design.<snake_case>                     # design.md の component / module / data model / flow heading から命名
    type: component | module | data_model | flow | interface
    location: <file>:<line>                     # 抽出元の行番号 (heading 行)
    parent_specs:                               # 設計書本文に明示記載された AC ID (例: 5.2) のみ抽出。推測しない
      - <numeric_id>
    components: [<name>, ...]                   # この unit に含まれる下位 component (なければ空配列)
    responsibilities:                           # 設計書の「Responsibilities & Constraints」等 bullets
      - <text>
    inputs:                                     # signature / API contract から抽出
      - name: <param>
        type: <type or null if unknown>
    outputs:                                    # 同上 (return / write target)
      - name: <ret>
        type: <type or null if unknown>
    dependencies:                               # Allowed Dependencies / Outbound dependency 明示分のみ
      - kind: internal | external | spec
        target: <name or spec_id>
        criticality: P0 | P1 | P2 | null
    failure_modes:                              # Failure Conditions / Error Handling 明示分のみ
      - <name>
    state_change: bool                          # write 操作 / persistence の有無
    rollback_defined: bool                      # 状態変更時の rollback / cleanup / atomic 記述があるか
    llm_judgment: bool                          # LLM 呼出を含むか
    llm_confidence_or_escalation: bool          # llm_judgment=true 時の信頼度 / human gate / escalation 記述があるか
    auto_approval: bool                         # 自動承認系の振る舞いを含むか
    human_gate: bool                            # auto_approval=true 時の人間判断 gate があるか
    tests:                                      # Testing Strategy で名指しされたテスト
      - <test_name>

requirements_index:                             # requirements.md から AC ID 一覧を抽出
  - id: <numeric_id>                            # 例: 1.1, 5.3
    summary: <1 行 text>
    location: <file>:<line>
    constraint_kind: authority | conservatism | scope | invariant | normal
                                                # authority = 「人間判断必須」等、conservatism = 「危険側に倒す」等、
                                                # scope = 適用範囲規定、invariant = 不変条件、normal = それ以外
    constraint_text: <quoted text 1-2 sentence> # 制約文の原文 (Phase 2-E 入力)

cross_references:                               # 設計書本文に書かれた spec → design / task → design 等の関係
  - from: <id>
    to: <id>
    relation: implements | decomposed_into | verifies | depends_on
    location: <file>:<line>

tasks_index:                                    # tasks.md がある場合のみ
  - id: task.<snake_case>
    parent_design: design.<id>
    completion_condition: <1 行 text>
    verification_method: <1 行 text>
    tests: [<test_name>, ...]
```

# 抽出ルール (厳守)

1. 抽出元の「明示記述」のみを使う。設計書 / 仕様書に書かれていないことは推測しない
2. 値が欠けている項目は省略でなく `null` または空配列で明示。Phase 2 機械検証が欠落を検出するため、省略すると検出精度が落ちる
3. judgement / 改善提案 / 良し悪し評価 / 「これは責務多すぎ」等のコメントは出力に含めない (これは別フェーズの責務)
4. 抽出が不能な箇所 (例: signature が散文のみで構造不明) は `extraction_warnings` に「unit_id + 理由」のみ記録
5. `parent_specs` は設計書本文に明示書かれた AC ID (Requirements Traceability table 等) のみ拾う。design unit 名と requirement 内容の semantic 類似で推測しない
6. `state_change` / `rollback_defined` / `llm_judgment` / `llm_confidence_or_escalation` / `auto_approval` / `human_gate` の bool は、設計書本文に該当記述があれば true、無ければ false (推測 false ではなく、未記述 = 構造的欠落として false)
7. `constraint_kind` (requirements_index) は requirement の文面で判定:
   - authority: 「ユーザー判断必須」「人間が決定」「明示承認」等
   - conservatism: 「fail-fast」「安全側」「ERROR で停止」等
   - scope: 「適用範囲は X に限る」「Y の場合のみ」等
   - invariant: 「常に」「不変」「atomic」「monotonic」等
   - normal: 上記以外
````

### 出力 schema 検証

メタデータ extractor が出力した YAML は、Python 側で `pydantic` 等で schema validation する (Phase 2 入力前)。schema 違反は extraction error として人間判断送り。

---

## Phase 2-A: 構造チェック (Python script)

### Input
`design_metadata.yaml`

### Check 規約

| Check ID | 内容 | severity |
|----------|------|----------|
| A-1 | 各 design_unit が `parent_specs` 非空 (type=interface 以外) | ERROR |
| A-2 | type=component / interface の design_unit が `inputs` / `outputs` どちらかが非空 | ERROR |
| A-3 | 各 design_unit が `components` 列挙 (上位 type=module は空可) | WARN |
| A-4 | 各 design_unit の `dependencies[].target` が他 design_unit / requirements / 標準 lib に解決可能 (未定義参照なし) | ERROR |
| A-5 | type=component の design_unit が `tests` 非空 | WARN |
| A-6 | `extraction_warnings` 件数 0 | INFO (件数 > 0 で件数を report) |

### Output

```yaml
findings:
  - check_id: A-1
    severity: ERROR
    location: design.<unit_id>
    detail: "parent_specs 空、上位仕様への traceability なし"
  - ...
score:
  total_checks: <件数>
  passed_checks: <件数>
  structural_score: <ratio>
```

---

## Phase 2-B: トレーサビリティチェック (Python script)

### Input
`design_metadata.yaml`

### Check 規約

| Check ID | 内容 | severity |
|----------|------|----------|
| B-1 | 各 design_unit.parent_specs[i] が requirements_index に実在 (orphan design 検出) | ERROR |
| B-2 | 各 requirements_index.id が少なくとも 1 design_unit に implemented_by (uncovered requirement 検出) | ERROR |
| B-3 | 各 design_unit が少なくとも 1 test に紐付け (uncovered design 検出) | WARN |
| B-4 | tasks_index がある場合、各 task.parent_design が design_unit に実在 (orphan task 検出) | ERROR |
| B-5 | tasks_index がある場合、各 task.tests が非空 (verification 経路あり) | ERROR |
| B-6 | cross_references の連結性 (Spec → Design → Task → Test の chain が成立) | WARN |

### Output

```yaml
findings: [...]
score:
  traceability_score: <ratio>
  orphan_designs: [<id>, ...]
  uncovered_requirements: [<id>, ...]
  uncovered_designs: [<id>, ...]
  orphan_tasks: [<id>, ...]
```

---

## Phase 2-C: 型チェック (Python script)

### 許容関係集合

```python
ALLOWED_RELATIONS = {
  ('Design', 'implements', 'Spec'),
  ('Task', 'implements', 'Design'),
  ('Test', 'verifies', 'Spec'),
  ('Test', 'verifies', 'Task'),
  ('Design', 'depends_on', 'Design'),       # 内部依存
  ('Design', 'depends_on', 'Spec'),         # 外部 spec 依存
  ('Task', 'depends_on', 'Task'),           # task 順序依存
}
```

### Check 規約

| Check ID | 内容 | severity |
|----------|------|----------|
| C-1 | cross_references の各 (from_kind, relation, to_kind) が ALLOWED_RELATIONS に含まれる | ERROR |
| C-2 | Spec → Design / Spec → Task / Spec → Test の関係が `implements` / `verifies` であって、`decomposed_into` でない (Spec 自身は分解されない) | ERROR |
| C-3 | Test → Design は不正 (Test は振る舞い検証で Design 構造を検証しない、verifies 関係は Spec or Task のみ) | ERROR |

### Output

```yaml
findings: [...]
score:
  type_score: <ratio>
  invalid_relations: [<from_kind>::<relation>::<to_kind>, ...]
```

---

## Phase 2-D: リスクパターンチェック (Python script)

### Check 規約

| Check ID | 内容 | severity |
|----------|------|----------|
| D-1 | 単一 design_unit の `responsibilities` 配列長 >= 3 (責務過剰) | WARN |
| D-2 | `inputs` 非空かつ `outputs` 空 (出力なし、副作用のみ?) | WARN |
| D-3 | `state_change == true` かつ `rollback_defined == false` | ERROR |
| D-4 | `dependencies[].kind == 'external'` を持つが `failure_modes` 空 | ERROR |
| D-5 | `llm_judgment == true` かつ `llm_confidence_or_escalation == false` | ERROR |
| D-6 | `auto_approval == true` かつ `human_gate == false` | ERROR |

### Output

```yaml
findings: [...]
score:
  risk_pattern_score: <ratio>
  risk_units:
    - unit_id: design.<id>
      risk_codes: [D-3, D-5]
```

---

## Phase 2-E: 意味的ドリフト検出 LLM プロンプト

### 入力

- Phase 1 出力 `design_metadata.yaml` のうち以下サブセット:
  - `requirements_index` のうち `constraint_kind != normal` の項目のみ (authority / conservatism / scope / invariant)
  - 上記 requirement を `parent_specs` に持つ `design_units` の `responsibilities` + `auto_approval` / `llm_judgment` / `state_change` / `rollback_defined` 等の bool 値

### LLM プロンプト本文

````
あなたは上位仕様と設計の意味整合性のみを検査する。構造的妥当性 / 細かな改善提案 / コードスタイル / 性能評価は検査しない。「もっと良い設計」も提案しない。

# タスク

各 (requirement, design_unit) ペアについて、以下のいずれかに該当するかを判定する:

1. **drift_authority**: 上位仕様が「人間判断必須 / ユーザー明示承認 / 明示確認」を要求しているのに、設計が「LLM 自動判断 / auto_approval / 自動進行」になっている
2. **drift_conservatism**: 上位仕様が「危険側に倒す / fail-fast / ERROR で停止」と書いているのに、設計が「効率側に倒す / 暫定通過 / WARN で継続」になっている
3. **drift_scope**: 上位仕様が規定する適用範囲 (kind, file 種別, 操作種別) と、設計の適用範囲がズレている
4. **drift_invariant**: 上位仕様の不変条件 (atomicity / consistency / monotonicity / append-only / read-only) を、設計が破る経路を含む
5. **no_drift**: 構造上も意味上も整合 (該当ペアでも no_drift を必ず明示記録)

# 入力 (YAML)

```yaml
constraints:
  - requirement_id: <id>
    constraint_kind: <kind>
    constraint_text: <quoted>
designs:
  - design_unit_id: <id>
    parent_specs: [<id>, ...]
    responsibilities: [<text>, ...]
    auto_approval: bool
    human_gate: bool
    llm_judgment: bool
    llm_confidence_or_escalation: bool
    state_change: bool
    rollback_defined: bool
```

# 出力形式 (YAML)

```yaml
drift_findings:
  - pair_id: <requirement_id>::<design_unit_id>
    drift_kind: drift_authority | drift_conservatism | drift_scope | drift_invariant | no_drift
    severity: ERROR | WARN | INFO   # drift_authority / drift_invariant = ERROR、drift_conservatism / drift_scope = WARN、no_drift = INFO
    excerpt_requirement: <quoted text from constraint_text>
    excerpt_design: <quoted text from responsibilities or bool justification>
    explanation: <1-2 文、客観的に「意図と異なる経路はこれ」を記述>
```

# 厳守ルール

- 内容批評・改善提案・「もっと良い設計」は出力に含めない
- ズレが見当たらない場合は drift_kind: no_drift で必ず記録 (省略禁止、判定済の証跡)
- 推測で drift を捏造しない。constraint_text / responsibilities に明示記載がない場合は no_drift
- explanation は対立構造のみを記述: 「上位は X を要求、設計は Y で進む経路あり」形式
- ペア数が多い場合 (例: 10+) でも、すべてのペアを判定する (sampling 禁止)
````

### 採点

```python
total_pairs = len(drift_findings)
drift_count = sum(1 for f in drift_findings if f.drift_kind != 'no_drift')
semantic_alignment_score = 1 - (drift_count / total_pairs) if total_pairs > 0 else 1.0
```

---

## Phase 3: 採点 + risk_level 判定 (Python script)

### Input
Phase 2-A〜E の findings + scores

### 採点ロジック

```python
weights = {
  'traceability': 0.30,
  'risk_pattern': 0.25,
  'structural': 0.20,
  'type': 0.15,
  'semantic': 0.10,
}

composite_score = sum(scores[k] * weights[k] for k in weights)
```

### risk_level 判定

```python
def determine_risk_level(scores: dict, findings: list) -> str:
  error_count = sum(1 for f in findings if f.severity == 'ERROR')
  if error_count == 0 and all(s >= 0.95 for s in scores.values()):
    return 'A'              # auto-approve 可
  if error_count >= 1 or scores['semantic'] < 0.8:
    return 'D'              # 人間判断必須
  if composite_score >= 0.85:
    return 'B'
  return 'C'
```

### human_review_required 判定

```python
def determine_human_review(risk_level: str, drift_findings: list) -> bool:
  if risk_level == 'A':
    return False
  return True   # B / C / D はすべて人間判断必須
```

### Output (`review_report.yaml`)

```yaml
feature_name: <name>
generated_at: <ISO 8601>
scores:
  structural_score: <ratio>
  traceability_score: <ratio>
  type_score: <ratio>
  risk_pattern_score: <ratio>
  semantic_alignment_score: <ratio>
composite_score: <weighted average>
risk_level: A | B | C | D
human_review_required: bool
findings:
  - phase: A | B | C | D | E
    check_id: <id>
    severity: ERROR | WARN | INFO
    location: <design_unit_id or requirement_id>
    detail: <text>
summary:
  total_findings: <int>
  errors: <int>
  warnings: <int>
  info: <int>
recommended_action:
  - if risk_level == A: "approve as-is、人間判断不要"
  - if risk_level == B: "ERROR 0 件確認後 approve、WARN は読み流し可"
  - if risk_level == C: "ERROR / WARN を逐一精査、必要に応じて design 改版"
  - if risk_level == D: "人間判断必須、設計改版または requirements 改版を要検討"
```

---

## 実装順序 (次セッション以降)

1. **メタデータ抽出 LLM 試行 (Spec 2 design)**: Phase 1 プロンプトを Claude に投げて design_metadata.yaml を生成、schema validation で問題ないか確認
2. **Phase 2-A〜D Python script 実装**: 6 + 6 + 3 + 6 = 21 check を function 化、findings + scores を返す
3. **Phase 2-E LLM 試行**: メタデータから constraints / designs を抽出して Phase 2-E プロンプトを Claude に投げて drift_findings を生成
4. **Phase 3 採点 script 実装**: weights + risk_level boundaries で review_report.yaml 生成
5. **Spec 2 design に dogfeeding**: 旧方式 18 件 (Spec 5) と比較、新方式が検出した件数 / 採用件数 / 所要時間を計測
6. **計測結果に基づく weight / boundary 調整**: 初期値で過剰検出 / 過小検出があれば調整

## 計測項目 (Spec 5 vs Spec 2 比較)

| 項目 | Spec 5 (旧方式 10 ラウンド) | Spec 2 (新方式 5 種機械検証) |
|------|---------------------------|----------------------------|
| 検出件数 | 18 件 (重要級 7 + 軽微 6 + 本質的 5) | (未測定) |
| 採用件数 / 採用率 | 18 件全件採用 (100%) | (未測定) |
| LLM 呼出回数 | ~30 回 (Step 1a/1b/1b-v 含) | 2 回 (Phase 1 / Phase 2-E) |
| 所要時間 | 数セッション | 1 セッション内見込み |
| design 改版 vs 採用却下 比率 | 18/18 改版 | (未測定) |
| Phase 1 メタデータ抽出精度 | — | (未測定) |
| 機械検証 false positive 率 | — | (未測定) |
| 意味的ドリフト false negative 率 | — | (未測定) |
