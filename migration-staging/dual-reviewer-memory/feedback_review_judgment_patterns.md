---
name: dev-log 学習による escalate 判定パターンチェックリスト (23 種)
description: 過去レビューログ (docs/-dev-log-1.md / 2.md / 3.md) から抽出したユーザーの escalate 判定パターン 23 種。Step 1b-iii で各ラウンドごとに通読しチェック、該当箇所が見つかれば escalate 候補。LLM の自動採択偏向を回避する実例ベース校正リスト。
type: feedback
originSessionId: d8fd6618-0784-4212-9ecc-ebbb641383e3
---

LLM が レビュー Step 1b で**ラウンドごとに通読しチェック**するパターンリスト。dev-log 学習 (subagent 抽出) 由来、ユーザー (Kenji Ono) が過去に escalate 級 / 致命級と判定した実例の共通基準。

**Why:** LLM の自動採択偏向バイアスは「視点を与えても安易に流れる」根本問題。dev-log 実例ベースのチェックリストで判定深度を構造的に強制する。各パターンに該当する箇所が design / requirements 内に見つかれば、Step 1b で escalate 候補として提示する。

**How to apply:** Step 1b-iii で各ラウンドごとに 23 パターンを順次通読、該当箇所を grep / 文脈検査で確認、見つかれば escalate 候補に列挙 (escalate 必須条件 5 種と整合)。判定迷う候補は escalate 寄せ。

## 23 判定パターンチェックリスト

### A 群: 内部矛盾系

1. **同一 spec 内の禁止 vs 許可矛盾**: R.X が「A を禁止」と R.Y が「A を許可」両方記述されていないか (例: Spec 1 本-1 「カテゴリは強制ディレクトリではなく推奨パターン」R1.2 vs R7.1 `enforcement: required` 許可)
2. **スキーマと動作の参照ずれ**: スキーマ定義 R.X に存在しない field を動作規定 R.Y が前提にしていないか (例: Spec 1 本-19 R6.1 に successor 不在なのに R6.5 が successor 参照)
3. **設計決定間の矛盾**: 同一 design 内の複数決定が共存不可な規律になっていないか (例: Spec 4 致-1 決定 4-7 --dry-run 提供 vs 決定 4-18 --auto バイパス禁止 の運用整合性)

### B 群: 実装不可能性 / 逆算系

4. **実装不可能性 (逆算)**: 「要件に書かれている動作は、spec で定義されたデータ構造で実装可能か」逆算検証 (例: 「R.X が動作 A を行う」ならば「R.Y で field F が必須」か)
5. **下流システム実装可能性**: 自 spec の定義が下流 spec で「判定・分岐可能」か、曖昧な依存性が後段で検証不可に陥らないか (例: Spec 1 本-2 type field 二系統で Spec 3 dispatcher / Spec 5 normalize API が判定不可)
6. **アルゴリズム / 実装メカニズムの不整合**: 文書記述 (例: Levenshtein 距離) vs 実装コード (例: SequenceMatcher = Ratcliff/Obershelp) の数学的・物理的不一致 (Spec 1 R5 escalate 同型)

### C 群: 責務境界系

7. **責務境界の明確性**: パラメータ値・エラー処理・スキーマで「誰が決定権を持つか」が spec 間で曖昧でないか、field 名・型 (定義側) と許可値集合 (利用側) の所管分離 (例: Spec 1 本-7 merge_strategy 5 値を Spec 1 が固定 vs lifecycle 操作は Spec 7 所管)
8. **API Signature Bidirectional Check**: coordination requirement で「API を呼ぶ」記述あれば、呼び出し側 (caller spec) と被呼出側 (callee spec) 両方で signature が整合しているか確認 (例: Spec 7 C-1 Spec 4 R16.2 dispatch 先 cmd_promote_to_synthesis signature 不在)
9. **Coordination Requirement Completeness**: 「Spec X で〇〇と言及」 → 「対応 spec で実装 AC あるか」双方向確認、ownership 明確か (例: Spec 7 C-2 Spec 4 R4.7 L3 診断 API 提供責務 AC 不在)

### D 群: 規範範囲判断系

10. **規範範囲判断 (Boundary Determination)**: 設計決定が requirements 範囲を先取り / 不必要に狭めていないか (例: Spec 0 escalate 「3 ヶ月超で ERROR 昇格」が requirements 規定外で design 先取り)
11. **規範前提の曖昧化**: transaction guarantee / consistency model / atomicity 等の規範前提が明示されていないか曖昧か (例: Spec 1 R7 transaction guarantee → Eventual Consistency 規範化)
12. **Adjacent spec との整合 (過剰拘束)**: 自 spec の設計が先行 spec と整合か、後続 spec が拘束されないか (例: 先行 spec の Adjacent Sync 受領済確認、過剰拘束検出)

### E 群: failure / 状態系

13. **State Observation Integrity**: 状態遷移 (partial failure / 中間状態 / archived → deprecated 等) が定義される場合、observer (dispatcher / user / downstream) が判定可能な signal (exit code / JSON field / log message) が同時に規定されているか (例: Spec 7 第 3-1 partial failure 時 exit code 未定義)
14. **Atomicity & Crash Safety**: long-running operation (8 段階対話 / multi-step batch) で「中間状態の永続化」発生可能性、明示的に「step N まで read-only」「step M で atomic commit」境界が規定されているか (例: Spec 7 第 3-2 8 段階対話 atomicity 暗黙前提)
15. **Failure Mode Exhaustiveness**: failure を「成功 / 失敗」二値でなく「全失敗 / 部分失敗 / 成功」段階化、各々の rollback / recovery strategy 明示、曖昧な「follow-up 化」で root cause 埋没していないか (例: Spec 7 第 4-3 全失敗 vs 部分失敗 同扱い)

### F 群: concurrency / timeout 系

16. **Concurrency Boundary Explicit Rule**: file I/O / concurrent edit risk がある操作で、lock / transaction 機制が foundation で規定済か確認、本 spec で「明示的に lock 取得タイミング規定」しているか、「Foundation に従う」だけでは不十分 (例: Spec 7 第 3-3 Backlink 更新で .hygiene.lock 取得言及なし)
17. **Timeout Resilience**: external API 呼出 (たとえ「同期」でも) は遅延 / hang 可能性 assume、timeout 規定必須、resource leak / deadlock trap 防止 (例: Spec 7 第 4-1 edge API timeout 不在)
18. **Race Condition Window Detection**: lock 取得前後で「状態変化のリスク window」がないか、step 1-7 (lock なし) と step 8 (lock あり) 境界で check/approve 矛盾起きる可能性、lock 取得直後の「pre-flight 再確認」明示か (例: Spec 7 第 4-2 lock 取得後 pre-flight 再確認規定なし)

### G 群: 整合性 / SSoT 系

19. **SSoT 引用の完全性**: 他文書を参照する場合、「引用先が実装時に確認可能か」「更新時に同期するか」、「参照している」と「参照先を特定できる」は別 (例: SSoT は『定義の存在』だけでは機能しない、『引用の正しさ』を検証する仕組みが伴って初めて SSoT)
20. **Cross-Spec Grep Validation (第 5 ラウンド必須)**: 修正で変更した値 (数値 / enum / API name / field name) をリスト化、既 approve spec 全件を grep で網羅参照箇所確認、「coordination requirement の言及」でなく「実装で参照されているか」機械的チェック (例: Spec 7 第 5 ラウンドで Spec 4 Query API 15 種化 5 箇所未更新を後発見)
21. **Foundation 改版時の傘下 7 spec 精査**: Foundation 改版時は傘下 7 spec (Spec 1-7) に対して改版要件番号 / 関連章番号 / 改版内容依存記述を grep、波及有無を全件報告 (波及なしも明示記録)

### H 群: 選択肢系 (escalate 寄せ最重要)

22. **複数選択肢 trade-off (LLM 単独採択禁止)**: dominated 除外後も合理的選択肢 2 案以上残る場合、LLM 単独で「採択」と書かず必ず escalate (例: Spec 4 致-厳-1 決定 4-6 / 4-9 / 4-10 / 4-12 / 4-14 / 4-15 / 4-16 が複数選択肢から LLM 単独採択 7 件)
23. **運用現実との接地**: 「初期セット / 将来拡張」「手動 / 自動」「強制 / 推奨」など二項選択が曖昧、実装者が「どちらに判定すべきか」で困るパターン

## チェックリスト適用フロー (各ラウンド)

1. **Step 1b 開始時**: 主観点 (例: 観点 5 = アルゴリズム) に対応する設計記述を抽出
2. **Step 1b-iii**: 上記 23 パターンを順次通読、各パターンに該当する箇所を design / requirements で検索
3. **該当発見時**: escalate 候補として Step 1b 出力に列挙、`[escalate 推奨]` ラベル + 該当パターン番号 + 根拠を併記
4. **該当なし時**: 通読完了を Step 1b 出力に明示 (「23 パターン通読、該当なし」と 1 文宣言)、Step 1a の軽微検出のみで Step 2 へ
5. **Step 2 ユーザー判断**: 異論あり/なし確認、ユーザーが「23 パターンチェック甘い、別視点で再精査」を要求したら反転対応

## 追加: ユーザーの「核心を突く一言」(LLM が忘れがちな判定基準)

- 「致命的な思想矛盾を design phase に転嫁する設計の悪臭」 — 要件段階での論理矛盾を後送しない
- 「スキーマ宣言と許可値集合の所管を分けるべき」 — 責務分離が本質的な整合性の基準
- 「SSoT は『定義の存在』だけでは機能しない、『引用の正しさ』を検証する仕組みが伴って初めて SSoT」 — 参照可能性の検証
- 「規範の核心 (例: 39 セルの具体値) が要件レベルではなく設計レベルにあるなら、下流 spec が起票時に引用できないのでは」 — 実装フローからの逆算思考
- 「LLM が見逃す傾向 = 複数選択肢が共存する時、『合理的だから自動採択』と楽観化する癖」 — 複数選択肢 = 必ず escalate

## 評価基準

本チェックリストの効果評価指標 (Phase 2 完了後 + Spec 4 試行段階):

- escalate 件数 (旧版で 0 → 改修版で増加が期待)
- ユーザー反転介入頻度 (旧版で 0 → 改修版で減少が期待 = LLM 判定が user 期待値に近づく)
- false positive 比率 (escalate 提示したが user が「自動採択で OK」と反転した件数 / escalate 提示総数)
- false negative 比率 (LLM が `[自動採択推奨]` 提示したが user が反転した件数 / 自動採択総数)
- レビュー所要時間 (1 ラウンド × 4 重検査で増加するが許容範囲か)

## 関連 memory

- `feedback_review_step_redesign.md` — Step 1 を 1a/1b 分割、本 memory は Step 1b-iii で適用
- `feedback_design_review.md` — 12 ラウンド構成
- `feedback_review_rounds.md` — 5 ラウンド構成 (仕様)
- `feedback_no_round_batching.md` — batching 禁止
- `feedback_dominant_dominated_options.md` — dominated 除外 (パターン 22 の前提)
