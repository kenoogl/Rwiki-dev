# Execution Control Ledger

_作成: 2026-05-10_
_最終更新: 2026-05-13_
_status: draft v0.2_
_purpose: generic execution layer の設計制約を一般則として固定する_

---

## 1. 文書の役割

本書は、generic execution layer 設計が満たすべき制約を、case 固有性から離れた一般則として記録する設計制約の正本である。

本書は workflow 制御板ではない。current step の制御は ACTIVE_WORKLIST が担う（case ごとにテンプレートから生成する instance）。

---

## 2. 設計制約

generic execution layer は次を満たす必要がある。

1. case identity（case 名や target id）は analyzer の branch 条件に使わない。
2. finding は case 名ではなく taxonomy（分類体系）で first-class に表現する。
3. case 固有性は input refs、extracted excerpts、final rendered finding text にのみ残す。
4. track ごとの差は `intent` / `spec` / `implementation` の input contract 差に閉じる。
5. batch wiring は execution rule ではなく case manifest 層に落とす。

---

## 3. 許容される固定 / 除去対象

### 3.1 許容される固定

execution rule ではなく case manifest または batch wiring として扱えるもの。

- batch runner が特定 case の `intent` / `spec` / `snapshot` を入力として渡すこと。
- pilot 用 output root や `run_label` を固定すること。
- 比較 summary が pilot scope を説明すること。

### 3.2 除去対象

generic execution layer 設計で除去対象とする。

- `case_id` や `target_id` を見て review 内容を分岐する。
- 特定 case だけで finding を生成する。
- 特定 case 専用の issue summary / caveat / handback / metric を埋め込む。
- 特定 spec path を前提に reopen target や signal id を決める。

---

## 4. 次段への引き渡し

本書の設計制約は次の文書が引き取って具体化する。

- generic execution layer の上位仕様：[generic-execution-layer-v2-spec.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/generic-execution-layer-v2-spec.md)
- v2 取得 spec：[dual-reviewer-rebuild/.kiro/specs/dual-reviewer-v2-acquisition/](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/.kiro/specs/dual-reviewer-v2-acquisition/)

引き取るべき論点：

1. analyzer / writer / decision の責務をどこで切るか。
2. finding をどの taxonomy で表現するか。
3. case manifest 層の contract をどう設計するか。
4. v2 実装完了の判定基準。

---

## 5. ACTIVE_WORKLIST との関係

本書と ACTIVE_WORKLIST は独立した役割を持つ。

- 本書（ECL）：execution layer 設計の一般制約台帳。case 横断で適用される。
- ACTIVE_WORKLIST：case ごとに生成される instance control board。テンプレート（[active-worklist-template.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/reviews/templates/active-worklist-template.md)）から case 初期化時に生成する。

case 横断の設計制約は本書に置き、特定 case の current step は ACTIVE_WORKLIST instance に置く。
