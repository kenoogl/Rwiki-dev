# implementation-conformance-review

## 1. この文書の役割

この文書は、feature 実装完了後に実施する
`implementation conformance review` の工程定義である。

ここでいう conformance review は、単なる smoke check ではない。
prototype が動くことを前提に、次を横断確認する。

- 仕様準拠性
- 境界条件
- 証跡性

本書は spec の正本を置き換えない。implementation 後の棚卸し手順を固定する補助文書である。

## 2. なぜ必要か

tasks 完了と smoke pass だけでは、次の種類の問題が残りうる。

- spec 上は分離されている state が implementation convenience で混線する
- fixture 依存や path hard-code が prototype 成功の裏で隠れる
- caveat / provenance / review history が silent に弱まる

これらは feature task 単位では見落としやすく、横断 review を別工程として持つ必要がある。

## 3. 実施タイミング

少なくとも次のいずれかで実施する。

- feature 群の prototype 実装が一巡した時点
- major branch push 前
- PR 作成前
- `implementation-signal-register` に `medium` 以上の signal が蓄積した時点
- trust boundary、invalidation、provenance、approval/adoption の境界を触った後

## 4. review scope

conformance review では、少なくとも次を対象にする。

- 対象 commit / branch
- 対象 feature 群
- smoke validator の再実行結果
- spec / design / dependency map との照合
- implementation-coordination / signal register の未解消項目

## 5. review 観点

### 5.1 仕様準拠性

- requirements / design で明示した gate や contract が code 上で維持されているか
- state flow が shortcut されていないか
- phase boundary が implementation convenience で崩れていないか

### 5.2 境界条件

- hard-coded fixture path
- basename match のような heuristic linkage
- placeholder / deferred 実装
- manual exception path
- silent fallback

### 5.3 証跡性

- review finding が review artifact として残るか
- finding が signal register または disposition に接続されるか
- provenance / caveat / adoption / rollback が source ref で追えるか

## 6. required outputs

conformance review 実施時は、少なくとも次を残す。

- `docs/reviews/<date>-<scope>-review.md`
- 必要なら `implementation-signal-register` への finding 起票
- 必要なら `implementation-coordination-log` への review entry
- `implementation-conformance-metric-register.md` に定義された metric の current snapshot

## 7. finding severity

- `P1`
  - approval/adoption、trust boundary、invalidation、provenance を破る
  - smoke pass でも即修正対象
- `P2`
  - 現状の fixture / prototype では通るが、少し条件が変わると破綻する
  - 次タスクへ進む前に修正方針を持つ
- `P3`
  - 即壊れないが、traceability や maintainability を弱める

## 8. disposition

各 finding には少なくとも次の disposition を付ける。

- `fix-before-next-feature`
- `fix-in-current-branch`
- `record-and-watch`
- `reopen-design`
- `reopen-requirements`

## 9. signal / handback 連携

- implementation-only 修正で吸収できる finding は `A`
- 設計境界の見直しが必要なら `B`
- requirement contract 不足なら `C`
- 上位 intent の見直しが必要なら `D`

finding が未修正でも、少なくとも signal register には残す。
handback が必要なら coordination log に再記録する。

## 10. completion rule

実装区切りは、原則として次で閉じる。

1. task 実装完了
2. relevant smoke validator pass
3. implementation conformance review 実施
4. finding が 0 件、または finding が artifact と disposition を伴って記録済み
