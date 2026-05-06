---
name: TODO_NEXT_SESSION.md slim 化 + 過去履歴 repo archive 分離 pattern (確定)
description: TODO_NEXT_SESSION.md が session 累積で線形増加する pattern を repo 追跡対象の archive file (TODO_HISTORY_through_<N>th.md) に過去履歴を分離して抑制。treatment / phase 切替境界での実施推奨
type: feedback
originSessionId: ed94b3f5-13e9-4c08-95da-28207898de36
---
TODO_NEXT_SESSION.md は session 末更新で過去履歴 section + セッション要約 section + Round 別 evidence section が累積し、放置すると session 数に線形比例で増加 (で 500 → 653 行 = +30-50 行 / session pace)。session 跨ぎでの context 圧迫 / 読込 cost 増加 / 不要詳細混入 risk を抑制するため、**treatment / phase 切替境界**で過去履歴を repo 追跡対象 archive file `TODO_HISTORY_through_<N>th.md` に分離する。

**Why:** user 提案 = 「次のセッションからは double で single とは異なるタスク。これまでの履歴はファイル保存で、コンテキスト圧迫は抑えられるのではないか」。 完走後 以降は session で 履歴は immediate context 不要、archive 保存で十分。slim TODO は次 session 開始時に必要な情報 (= 直前 endpoint state + 次 session ガイド + 持ち越し summary) のみ保持、archive は paper data analysis / comparison-report v0.2 final 集約 / treatment 比較時参照可能。`.gitignore` で TODO_NEXT_SESSION.md は追跡解除済 (= local 保存) だが、archive file は repo 追跡対象として保存 (= traceability + 全 session 共有)。

**How to apply:**

### archive 実施 trigger

- treatment / phase 切替境界 (= 次 session 以降のタスク性質が前 N session と質的に異なる境界、例: 完走 → 着手境界)
- TODO_NEXT_SESSION.md が 500 行を超え、過去履歴 section が 50% 以上を占める時点
- session 累積で context 圧迫が顕在化したと user / LLM が判断した時点

### archive file 構造 (= repo 追跡対象、`.gitignore` 除外なし)

- 命名: `TODO_HISTORY_through_<N>th.md` (= N が直近 archive 対象 session 番号、例: `TODO_HISTORY_through_.md`)
- 配置: project root (= TODO_NEXT_SESSION.md と同階層)
- 内容: 過去 session 進展サマリ詳細 + 過去 session 要約 + 旧過去履歴 + 評価 evidence の Round 別 enumeration を 1 file に集約
- header: 「paper data analysis / comparison-report v0.2 final 集約 / treatment 比較時参照」目的明示 + 「最新状態は TODO_NEXT_SESSION.md 参照」 pointer
- footer: archive 範囲明示 (= 何 session 末まで含むか)

### slim TODO_NEXT_SESSION.md 構造 (推定 200-250 行)

- 冒頭サマリ 1 段落 (= 直前 session 末 endpoint state + 次 session 着手内容)
- treatment / phase 完走 evidence summary 1 段落 (= 次 treatment / phase 比較 input、累計 metric + Round 別 evidence の数値のみ)
- 現在の状態サマリ (branch / commit / line / 数値、必須詳細のみ)
- 次セッションガイド (開始メッセージ template + 最初のアクション + 規律)
- 進捗追跡シンボル (v2 + dual-reviewer の overall progress)
- 関連リソース (前セッション継承 + 直近 session 追加)
- 末尾 archive pointer 1 行 = `_過去 session 履歴 (-<N>th 詳細) は TODO_HISTORY_through_<N>th.md 参照_`

### branch policy (= 確定)

- archive file は **main branch で commit** (= treatment-single / treatment-dual branch は paper data archive で metadata 含めない)
- 一時的な branch 切替が必要な場合: 現 branch から main checkout → archive commit + push → 元 branch 戻る (= working tree は kept で reversible)
- treatment branch 上で TODO_HISTORY を含めると paper data analysis 時に metadata が混入 risk = main 隔離が clean

### 削減効果 (実証)

- TODO_NEXT_SESSION.md: 653 → 248 行 (= 62% 削減)
- TODO_HISTORY_through_.md: 234 行 (新規 archive、main )
- 以降の session 累積 pace = +30-50 行 / session 想定 (= 過去履歴 archive で session 累積回避、Round 別 evidence のみ追加)
- 次 archive cycle 候補 = 完走時 (= 推定 末) で `TODO_HISTORY_through_.md` 新設

### future session 適用場面

- A-2.1 完走時 (= 完走後): A-2.1 全 30 review session 履歴を `TODO_HISTORY_through_<N>th.md` 第 2 弾として archive
- A-3 + batch 完走時: A-3 batch session 履歴を archive 第 3 弾
- Phase A 終端時: 全 Phase A 履歴を `TODO_HISTORY_phase_a_complete.md` で final archive
- Phase B fork 後: Phase A archive を Phase B project の reference として継承

## 関連 memory

- 親規律: `feedback_todo_ssot_verification.md` (= TODO 更新時 SSoT 確認義務、本規律は archive 分離 pattern を SSoT 確認の延長として位置付け)
- 親規律: `feedback_avoid_unnecessary_confirmation.md` (= 派生 routine 判断は再確認しない、archive file path / 命名 / 残す範囲は派生 routine で自己判断、treatment / phase 切替境界判断は user 方針確認推奨)
