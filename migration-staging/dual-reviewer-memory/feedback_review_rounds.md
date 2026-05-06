---
name: spec レビューラウンド構成 (5 ラウンド + 波及精査必須)
description: requirements 段階の spec レビューを 5 ラウンドで実施、第 5 ラウンドで隣接 spec への影響伝達を必須プロセス化、Foundation 改版時は傘下全 spec への精査必須
type: feedback
originSessionId: ab0afad3-4130-433a-86ce-46090be98883
---
requirements 段階の spec レビューは以下 5 ラウンド構成で実施する。**第 5 ラウンドは隣接 spec への影響伝達を必須プロセス化** する。Foundation のような上流 spec を改版した場合は **傘下全 spec への影響精査** を必ず行う。

**Why:** 過去 4 spec のレビュー（旧 6 ラウンド + 事後精査ラウンド）で以下の問題が顕在化した。

- 旧第 5 ラウンド「他 spec 波及」が形骸化、Spec 5 修正で Spec 4 への波及（Query API 14 → 15 種、5 箇所未更新）をユーザー指摘で初めて発見
- 旧 6 ラウンド構成では精査が「事後対応」で、修正適用時の連鎖更新漏れが多発（Spec 5 では精査ラウンドで 7 件発見）
- Foundation 改版時の傘下精査ルールが暗黙、Foundation R13.5 拡張時に Spec 4 への波及を見落としかけた

**How to apply:**

## レビュー 5 ラウンド構成

### 第 1 ラウンド: 基本整合性

- **観点**: 内部矛盾 / 参照漏れ / 既知 coordination 要求の反映状況
- **対象**: AC 番号、表記揺れ、上流 spec の Adjacent expectations が requirements に反映されているか
- **典型発見**: enum 値の追加忘れ / API シグネチャ抜け / フィールド整合
- **進め方**: 当該 spec の Requirement 一覧 + 上流 spec 由来 coordination 要求 + Important 該当項目 + 過去セッション由来波及項目を網羅的に列挙

### 第 2 ラウンド: 上位文書照合 (roadmap / brief / drafts)

- **観点**: 上位文書 (SSoT) との齟齬
- **対象**: roadmap.md Constraints / MVP / Coordination、brief.md Scope.In/Out、drafts §7.X / §5.X / §2.X
- **典型発見**: drafts と requirements の field 数 / API 列挙の不一致、運用ルール継承漏れ、SSoT 矛盾

### 第 3 ラウンド: 本質的観点

- **観点**: 異なる視点での全体俯瞰、文書内矛盾、概念定義の整合性
- **対象**: Subject 一貫性、Phase マーカー、event/decision の網羅性、用語使用、内部参照する enum 値が固定リストに欠落していないか
- **典型発見**: 内部参照する値が固定リストに欠落、概念の用法不一致、Objective と AC の乖離

### 第 4 ラウンド: B 観点 (failure mode / 並行 / セキュリティ / 観測 / 可逆性 / 規模)

- **観点**: 暗黙前提が崩れた時の動作仕様
- **対象**: crash recovery、partial failure、permission denied、disk full、大規模時の cap 接触、privacy mode、暗黙前提崩壊
- **典型発見**: transaction の crash 後 clean-up 規定欠落、batch 処理の continue/halt 方針未明示、failure 時の rollback 範囲

### 第 5 ラウンド: 波及精査 (隣接 spec 影響伝達 + drafts 整合 + 連鎖更新漏れ)

**修正適用後に必ず実施する最終ガード**。3 観点を統合的に精査する。

- **観点 (a) 隣接 spec への影響伝達**: 既 approve 済 spec への波及、未 approve spec へのチェックリスト追加
- **観点 (b) drafts / scenarios 整合**: drafts Adjacent Sync TODO の特定
- **観点 (c) 連鎖更新漏れ精査**: 第 1-4 ラウンドの修正で生じた他 AC への波及不整合 (例: enum 拡張時の他参照箇所、Phase 表概要文、Boundary Context の概要記述更新)

#### 第 5 ラウンド必須手順 (5 step)

**修正適用後に Claude が必ず実施する**。手順を機械的に踏むことで形骸化を防ぐ。

1. **変更値リスト化**: 第 1-4 ラウンドで修正した値 (数値、enum、API 名、AC 番号、シグネチャ、必須 field、event type、decision_type 等) をすべてリスト化
2. **網羅的 grep 検索**: 各変更値について、以下の対象を grep で参照箇所を特定
  - 既 approve 済の他 spec 全件 (当該 spec を除く)
  - drafts (= upstream design documents)
  - Foundation spec の requirements.md
  - 当該 spec 自身の他 AC (連鎖更新漏れ精査、Boundary / Objective / Phase 表 / change log を除く本文)
3. **Foundation 改版時の傘下精査必須**: Foundation を改版した場合は **下記「Foundation 改版時の傘下精査ルール」** を必ず実行
4. **Adjacent Sync TODO 整理**: 文言同期が必要な箇所を Adjacent Sync TODO として記録 (D-N 通し番号)。各 TODO は (a) 対象 spec / drafts、(b) 修正前後の文言、(c) 同期理由 ( spec の修正由来) を記載
5. **内同期判断**: 各 Adjacent Sync TODO について、内で同期適用するか別セッションに残すかをユーザー判断する。判断材料は (a) 既 approve spec か未 approve spec か、(b) 文言同期レベル (再 approval 不要) か実質要件変更か、(c) 関連 spec の現状

#### Foundation 改版時の傘下精査ルール

Foundation を改版した場合、傘下 7 spec (Spec 1 / 2 / 3 / 4 / 5 / 6 / 7) **全てに対して** 影響精査を必ず実行する。Foundation は規範文書であり、傘下 spec はすべて Foundation を SSoT として参照しているため、Foundation の変更は傘下全 spec に潜在的影響がある。

- **必須手順**: Foundation 改版した requirement 番号 (例: R13.5) と内容 (例: 必須 field 7 → 8 拡張) について、傘下 7 spec 全件に対して以下を実施
- 「Foundation Requirement R13.5」相当の参照を grep
- 「Foundation R13」相当の章番号参照を grep
- 改版した内容に依存する具体的記述 (例: 必須 field の数、enum の固定列挙) を grep
- **波及判定基準**: 参照箇所があった場合、参照内容が改版前提に依存しているかを判定
- **依存あり (=波及あり)**: 数値・列挙・field 数を直接引用 → Adjacent Sync 必須
- **依存なし (=波及なし)**: 個別ルール・運用方針への参照のみ → Adjacent Sync 不要
- **記録**: 波及あり / なしの判定結果をすべて報告 (波及なしも明示記録、後で誤って見落としと判断されないため)
- **適用例 (Spec 5 → Foundation R13.5 拡張時)**: Spec 1 (参照なし) / Spec 4 (参照あり、reject_reason_text 空文字禁止のルール参照のみ → 波及なし) / Spec 7 (参照なし、ledger ファイル名言及のみ) / Spec 5 (参照あり、本 spec が起源) を全件確認

## 各ラウンドの自動採択 / escalate 判断

各ラウンドで発見した修正候補は深掘り検討し、escalate 条件 5 種に該当する場合は必ずユーザー判断を仰ぐ。

## ラウンドの所要時間と発見数の目安

過去実績 (Spec 5 = 174 → 184 AC) を参考値:

- 第 1 ラウンド: 致命級 5 / 重要級 3 (8 件) — 最も発見数が多い
- 第 2 ラウンド: escalate 1 件 (上位文書 SSoT 矛盾)
- 第 3 ラウンド: 致命級 1 / 重要級 2 (3 件) — 本質的観点で初出する致命級
- 第 4 ラウンド: 重要級 3 / 軽微 3 (6 件) — failure mode 系
- 第 5 ラウンド: 連鎖更新漏れ 7 件 + Adjacent Sync TODO 7 件 — 修正適用後に必須

## ラウンドを跳ばさない原則

「もう致命級は出ないだろう」と感じても全 5 ラウンド必ず実施する。Spec 1 / 4 / 7 のレビューで第 3-4 ラウンド以降に致命級が初出した実例から、ラウンド跳ばしは禁止。

## 関連 memory

- `feedback_dominant_dominated_options.md`: 修正案候補から dominated 案を除外
- `feedback_choice_presentation.md`: escalate 時の選択肢提示方法 (大局 → 細部、ラベル付き)
- `feedback_approval_required.md`: spec.json approve / commit / push は別工程、明示承認必須
