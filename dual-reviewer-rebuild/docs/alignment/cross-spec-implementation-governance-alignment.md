# Cross-Spec Implementation Governance Alignment

_作成日: 2026-05-09_  
_対象: `dual-reviewer-implementation-governance` と既存 5 feature の接続_

## 1. 目的

この文書は、`dual-reviewer-implementation-governance` を
既存 feature 群の workflow に正しく接続するための
cross-spec alignment memo である。

governance spec は独立 feature のように見えるが、
実際には

- implementation completion rule
- conformance review gate
- finding の reopen / disposition rule

を既存 feature 全体に波及させる cross-cutting spec である。

したがって、単体 spec を作って終わりにせず、
feature 間で何が変わり、何が変わらないかを横断確認する必要がある。

## 2. 確認した論点

- governance spec が foundation/runtime/evaluation/self-improvement/paper-interface の data contract を書き換えていないか
- governance spec が implementation 後の gate を formalize するだけに留まっているか
- `implementation-coordination-log` と `implementation-signal-register` の役割を侵食していないか
- `A/B/C/D` handback と conformance finding の関係が矛盾していないか
- implementation checkpoint の close 条件が feature ごとにぶれていないか
- governance spec 自体が cross-spec alignment gate を通る必要性を明示できているか

## 3. 揃っている点

### 3.1 data contract 非侵食

- foundation の metadata / schema ownership は変更していない
- runtime の raw evidence production は変更していない
- evaluation の intake / classification / metrics ownership は変更していない
- self-improvement の proposal / backtest / history ownership は変更していない
- paper-interface の evaluation consumer 境界は変更していない

governance spec は feature artifact の shape ではなく、
implementation completion rule を追加しているだけである。

### 3.2 review gate 追加の位置

- `implementation conformance review` は `implementation` の後段に追加されている
- `requirements -> design -> tasks` の既存 progression を置き換えていない
- feature 実装は従来どおり `foundation -> runtime -> evaluation -> self-improvement -> paper-interface`
  の順を維持する

### 3.3 evidence 接続

- concrete review artifact は `docs/reviews/` に残る
- open finding は `implementation-signal-register` に接続される
- review 実施自体は `implementation-coordination-log` に残る

これにより review 結果が会話だけに留まらない構造になっている。

## 4. 今回明示した governance-specific rule

### 4.1 checkpoint close rule

feature 実装区切りは、少なくとも次の 4 条件で閉じる。

1. task 実装完了
2. relevant smoke validator pass
3. implementation conformance review 実施
4. finding が 0 件、または finding が artifact と disposition を伴って記録済み

### 4.2 open finding の扱い

- `P1` は次 feature 開始前修正対象
- `P2` は同一 branch または近接 checkpoint で回収対象
- `P3` は記録と watch を許容するが、signal register には残す

### 4.3 reopen rule

conformance finding が次に触れる場合は、通常の handback 判定に従う。

- implementation-only fix なら `A`
- 設計境界見直しが必要なら `B`
- requirement contract 不足なら `C`
- system intent の見直しが必要なら `D`

governance spec は handback rule を置き換えず、
finding をそこへ流し込む入口として機能する。

## 5. 追加で必要だった補強

今回の alignment で、governance spec には次が必要と分かった。

- cross-spec alignment memo 自体
- current gate status を残す artifact
- governance spec の `spec.json` に alignment required/completed を反映

これがないと、governance spec 自体が workflow 外で成立したように見えてしまう。

## 6. gate result

- 状態: completed
- 判定: `implementation-governance` は cross-cutting workflow spec として許容可能
- 条件:
  - feature data contract を書き換えない
  - review artifact / signal / coordination 接続を保つ
  - open finding は backlog 化ではなく explicit evidence として残す

## 7. 次の正しい作業

この alignment 後の次段は、

1. open finding 3 件の implementation fix
2. relevant smoke validator rerun
3. implementation conformance review short rerun

である。
