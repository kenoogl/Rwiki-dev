# ledgers/

_purpose: prescribed workflow process ごとの実行台帳インスタンスの配置先_
_正本参照: `.kiro/specs/dual-reviewer-implementation-governance` design「Workflow Execution Ledger and Enforcement Model」Owned Artifacts／小節 1_

---

## 配置規則

- ファイル名: `<process_id>-<date>.md`
  - `<process_id>` は `../workflow-process-authority-map.md` の `process_id` と一致
  - `<date>` は当該 process 着手日（`YYYY-MM-DD`）
- 各インスタンスは `../workflow-execution-ledger-template.md` の記入様式に従う
- prescribed workflow process の起草または実質作業の前に、権威ソースから段集合を導出して新規生成する（事後の遡及生成は不可）

## 保全規律

- 陳腐化／改竄遮断などで台帳を再生成した場合も、旧インスタンスは削除せず証跡として保全する
- 新インスタンスは旧インスタンスを `supersedes` でリンクし、`supersede_reason` に人手の置換理由を記録する（破壊的上書き禁止）

## 自己ブートストラップ（導入期の特例）

- 強制関数（Requirement 9 / Task 11〜18）の実装が完了するまでの移行期は、手作業で本様式の台帳を置いてよい
- その場合の証跡は `../workflow-gate-status.md` に記録する（design 移行戦略・Task 16）
