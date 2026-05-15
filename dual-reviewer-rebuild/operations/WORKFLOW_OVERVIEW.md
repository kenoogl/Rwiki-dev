# Workflow Overview

_作成: 2026-05-13_
_最終更新: 2026-05-13_
_status: draft v0.1_
_purpose: 意図駆動ワークフローの全体を 1 ページで把握できるようにする_

---

## 1. 全体の流れ

phase の連鎖は次の通り。

`intent` → `requirements` → `design` → `tasks` → `implementation` → `review acquisition`

各 phase の終端には人間関門があり、承認を得て次へ進む。承認状態は各 feature の `spec.json` に記録され、これが正本（[CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md) 第 2 節）。

---

## 2. 各 phase の中身（wave）

「`<phase> wave` を進めてください」と指示された場合、既定では次の連鎖が自動で走る（次 phase には自動で進まない）。

requirements wave 例：

1. 各 feature の `requirements.md` 起草。
2. feature-local review（feature ごとの個別レビュー）。
3. **requirements review wave**（複数 feature を横断して水平にレビュー）。
4. **requirements alignment gate**（feature 間整合性ゲート、後述）。
5. human requirements gate package 作成。

design wave、tasks wave も同様の構造を持つ。

---

## 3. multi-feature alignment gate

multi-feature 開発では、各 phase の終端に必須の alignment gate を置く。

- **requirements alignment gate**：metadata contract、invalidation rule、prompt / schema 依存、責務境界を横断確認。
- **design alignment gate**：interface、file / directory 配置、versioning 戦略、validator 統合点、後段への引き渡しを横断確認。
- **tasks alignment gate**：implementation order、shared artifact migration、blocking dependency、test sequencing を横断確認。

**是正ルール**：review wave で同じ phase の文書が修正された場合、次 phase の review wave に進む前に、その phase の alignment gate を再実施する。

---

## 4. handback class（手戻り種別）

- **A**：task-local adjustment。task の意図を変えず、実装内で吸収できる微修正。
- **B**：design handback。task の意図は維持できるが、設計境界を直す必要がある。
- **C**：requirements handback。feature contract が不足している。
- **D**：intent handback。contract より上位の system intent が不適切である。

判定に迷う場合は、より上流へ戻す側に倒す（保守的判定）。

詳細：[workflow-repair-procedure.md 第 4 節](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md)。

---

## 5. reopen 10 ステップ

問題を検出した場合は次の 10 ステップを踏む。

1. 問題を検出（実装中、review 中、alignment 中）。
2. 手戻り種別を判定（A/B/C/D）。
3. 影響範囲を特定（同一 phase か上流か、連鎖 reopen の必要範囲）。
4. 正本を更新（`intent/` / spec / `operations/` / traceability matrix）。
5. `spec.json` を更新（`updated_at`、`custom.reopened.<phase>`、`custom.recheck.upstream_change_pending`、`custom.recheck.impacted_downstream_phases`）。
6. 証跡を残す（intent review なら `docs/reviews/`、実装判断なら `implementation-coordination-log.md`、軽微 signal は `implementation-signal-register.md`、gate 状態は `workflow-gate-status.md`）。
7. 該当 gate を再実施（intent review / requirements alignment gate / design alignment gate / tasks alignment gate / implementation conformance review）。
8. 下流 phase を再判定（完了済みでも影響下なら reopen 扱いに戻す）。
9. approved / rechecked 済み phase から再開。
10. implementation close を再判定。

詳細：[workflow-repair-procedure.md 第 2 節](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md)。

---

## 6. 役割分担

- **人間**：承認、scope change、最終判断、ambiguous case の判定。
- **Codex（LLM 支援者）**：文書起草、要件 / 設計 / タスクの具体化、コード実装、検証、提案。承認の代行はしない。
- **ワークフロー review process**：phase gate を持つ（intent review、requirements / design / tasks alignment gate、implementation conformance review）。

詳細：[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)。

---

## 7. 正本文書

各論点の正本は次の通り。

- 意図：[INTENT.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/intent/INTENT.md) と `intent/` 配下。
- 運用と役割分担：[HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md)。
- 修復手続き（reopen）：[workflow-repair-procedure.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-repair-procedure.md)。
- gate 状態台帳：[workflow-gate-status.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/workflow-gate-status.md)。
- 共通規約：[CONVENTIONS.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/CONVENTIONS.md)。
- 各 feature の状態正本：`.kiro/specs/<feature>/spec.json`。

本書は概観であり、判断の根拠としては上記の正本文書を優先する。

---

## 8. 文書構造マップ

詳細を辿る入り口。

### HUMAN_WORKFLOW.md の主要節

- 節 5.1：上位文書フェーズ
- 節 5.2：spec フェーズ
  - 節 5.2.1：開始指示の既定解釈
  - 節 5.2.3：Review Wave Order（intent → requirements → design → tasks の順序）
  - 節 5.2.5：multi-feature alignment gate
  - 節 5.2.6：遡上修正時の強制再調整
  - 節 5.2.6.1：設計フェーズで判明した仕様課題の取り扱い
  - 節 5.2.7：phase evidence summary
  - 節 5.2.8〜5.2.11：レビュー詳細 → [REVIEW_PROTOCOL.md](REVIEW_PROTOCOL.md) に分離（プレースホルダのみ）
- 節 5.3：implementation フェーズ
- 節 5.4：optional review acquisition extension
- 節 6〜10：人間関与・承認単位・委ね深さ・逸脱防止・完成条件

### REVIEW_PROTOCOL.md の節構成

- レビュー基本規律：全レビュー段階で適用（検出 / 提示 / 判定 / 記録の 4 段階）
- 節 5.2.8：要件レビューの 5 ラウンド構成と波及精査
- 節 5.2.9：設計レビューの 10 観点と進め方
- 節 5.2.10：フェーズ完走後のフィーチャー横断レビューパターン
- 節 5.2.11：タスクレビューの 7 観点と進め方

### CONVENTIONS.md の主要節

- 節 3：Phase Terminology（`phase` 語の 3 種使い分け）
- 節 7：日本語用語の整理（「仕様」の単独使用回避）
- 節 8：レビュー 3 役の用語定義（主役・敵対役・判定役の名称と責務の正本）

### 規律ファイル群

規律は 2 箇所に分かれて配置される。

- `.kiro/memory/feedback_*.md`（8 件）：エージェントの応答品質に関する行動規律。索引は `.kiro/memory/MEMORY.md`。
- `operations/disciplines/feedback_*.md`（7 件）：ワークフロー実行の手順・方針に関する規律（手順 5 件 + 方針 2 件）。

### 節 8 の同期ルール

本マップは次の文書の節構成・配置を変更したとき、同じ変更の中で更新する。

- `HUMAN_WORKFLOW.md`：節の追加・削除・番号変更
- `REVIEW_PROTOCOL.md`：節の追加・削除・番号変更
- `CONVENTIONS.md`：本マップが掲げる節（現状 節 3 / 節 7 / 節 8）の追加・削除・番号変更
- 規律ファイル：`.kiro/memory/` と `operations/disciplines/` 間の移動、件数の増減

文書構造の変更と本マップの更新は同一コミットにまとめ、片方だけが先行する状態を残さない。
