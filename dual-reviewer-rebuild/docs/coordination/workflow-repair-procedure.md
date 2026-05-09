# workflow-repair-procedure

## 1. この文書の役割

この文書は、`dual-reviewer-rebuild` において
workflow 逸脱、spec 手戻り、review finding に対応するための
修正手続きを固定する補助文書である。

目的は、

- 問題検出後にどこまで戻るか
- 何を更新するか
- どの gate を再実施するか
- どう状態を記録するか

を一貫した手順として参照可能にすることにある。

## 2. 手続き一覧

### Step 1: 問題を検出する

実装中、review 中、alignment 中に次を見つける。

- contract 不足
- phase 境界逸脱
- ownership 不整合
- trust boundary 逸脱
- intent 不整合
- heuristic / fixture 依存

### Step 2: 手戻り種別を判定する

問題を `A/B/C/D` のいずれかに分類する。

- `A`
  - task-local adjustment
- `B`
  - design handback
- `C`
  - requirements handback
- `D`
  - intent handback

### Step 3: 影響範囲を特定する

どの feature のどの phase が影響を受けるかを決める。

- 同一 phase 修正なら、その phase の gate を再実施する
- 上流 phase 修正なら、完了済みの下流 phase を reopen 対象にする
- `D` の場合は、少なくとも `requirements -> design -> tasks` を連鎖 reopen 対象とする

### Step 4: 正本を更新する

該当する正本を更新する。

- `intent/`
- `.kiro/specs/*/requirements.md`
- `.kiro/specs/*/design.md`
- `.kiro/specs/*/tasks.md`
- 必要なら `operations/`
- 必要なら traceability matrix

### Step 5: `spec.json` を更新する

少なくとも次を更新する。

- `updated_at`
- `custom.reopened.<phase>`
- `custom.recheck.upstream_change_pending`
- `custom.recheck.impacted_downstream_phases`

### Step 6: 証跡を残す

問題と対応は次へ記録する。

- 実装判断:
  - `docs/coordination/implementation-coordination-log.md`
- 軽微 signal:
  - `docs/coordination/implementation-signal-register.md`
- review finding:
  - `docs/reviews/*.md`
- gate 状態:
  - `docs/coordination/workflow-gate-status.md`

### Step 7: 該当 gate を再実施する

修正 phase に応じて再実施する。

- `intent review`
- `requirements alignment gate`
- `design alignment gate`
- `tasks alignment gate`
- `implementation conformance review`

### Step 8: 下流 phase を再判定する

完了済みでも影響下にある phase は reopen 扱いに戻す。

- `completed`
- `completed_with_open_findings`

のような状態を維持したままにはしない。

### Step 9: approved / rechecked 済み phase から再開する

gate 再通過後にのみ implementation や次 review wave に進む。

### Step 10: implementation close を再判定する

implementation checkpoint は次でのみ閉じる。

1. task 実装完了
2. relevant smoke validator pass
3. implementation conformance review 実施
4. finding が 0 件、または artifact と disposition を伴って記録済み

## 3. 状態遷移表

| 起点状態 | 事象 | 判定 | 必須アクション | 次状態 |
|---|---|---|---|---|
| `intent completed` | intent 修正発生 | `D` | `intent/` 更新、intent review 再実施、影響 feature の requirements/design/tasks reopen | `intent recheck in_progress` |
| `requirements completed` | requirements 修正発生 | `C` | requirements 更新、`spec.json` 更新、requirements alignment 再実施、下流 design/tasks reopen | `requirements recheck in_progress` |
| `design completed` | design 修正発生 | `B` | design 更新、`spec.json` 更新、design alignment 再実施、tasks reopen | `design recheck in_progress` |
| `tasks completed` | task 順序や依存が変わる | `B` または `C` | 上流 design/requirements を見直し、tasks alignment 再実施 | `tasks reopen_required` |
| `implementation in_progress` | task-local 微修正で吸収可能 | `A` | coordination log 記録、実装継続 | `implementation in_progress` |
| `implementation in_progress` | 設計境界不足が判明 | `B` | design reopen、design/tasks alignment 再実施 | `design reopen_required` |
| `implementation in_progress` | requirement contract 不足が判明 | `C` | requirements reopen、requirements/design/tasks 再実施 | `requirements reopen_required` |
| `implementation in_progress` | intent 不整合が判明 | `D` | intent reopen、requirements/design/tasks の連鎖 reopen | `intent reopen_required` |
| `implementation completed` | smoke 未実施 | なし | relevant smoke validator 実行 | `smoke in_progress` |
| `smoke completed` | conformance review 未実施 | なし | review artifact、finding、metric snapshot 記録 | `conformance review in_progress` |
| `conformance review completed` | finding なし | なし | gate status 更新 | `completed` |
| `conformance review completed` | open finding あり | `A/B/C/D` | signal / coordination / review artifact へ接続 | `completed_with_open_findings` |
| `completed_with_open_findings` | finding 修正着手 | severity と handback に従う | 実装修正、smoke rerun、conformance review short rerun | `recheck in_progress` |
| `governance spec introduced` | completion rule 変更 | cross-spec review 必須 | alignment memo、gate status、`spec.json` alignment 更新 | `governance alignment completed` |

## 4. handback quick rule

- `A`
  - task の意図を変えない
- `B`
  - task の意図は維持できるが設計境界を直す必要がある
- `C`
  - feature contract が不足している
- `D`
  - contract より上位の system intent が不適切である

判定に迷う場合は、より上流へ戻す側に倒す。

## 5. intent handback の特記事項

`D` は requirements handback より重い。

最低限次を伴う。

- `intent/` 正本の更新
- intent と requirements の対応再点検
- 影響 feature requirements の reopen
- その下流 design / tasks の reopen
- 必要なら implementation も invalidated とみなす

## 6. update rule

この文書は次の場合に更新する。

- handback taxonomy が変わったとき
- reopen propagation rule が変わったとき
- workflow gate status vocabulary が変わったとき
- new review phase が追加されたとき
