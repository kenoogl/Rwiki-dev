---
name: レビュー Step 1-2 改修版 (Step 1 を 1a/1b 分割 + 多重検査必須 + escalate 寄せ義務化)
description: 設計 / 仕様レビューの Step 1 を Step 1a (軽微検出) / Step 1b (構造的検出) に分割、Step 1b で 4 重検査 (production deploy 逆算 + Phase 1 パターンマッチング + dev-log 23 パターン + 自己診断義務) を必須化。LLM の自動採択偏向バイアスを構造的に防止。Spec 4 design 試行で escalate 寄せ機能不全が判明したため改修。
type: feedback
originSessionId: d8fd6618-0784-4212-9ecc-ebbb641383e3
---

設計 / 仕様レビューの **Step 1 を 1a / 1b に分割** し、Step 1b で 4 重検査を必須化する。Step 2 (ユーザー判断) と Step 3-4 (詳細抽出 + 深掘り) は構造維持、ただし escalate 必須条件と自己診断義務を厳格化。

**Why:** 旧版 Step 1 (試行段階) では LLM の自動採択偏向バイアスが構造的に制御できなかった。Spec 4 design レビュー (2026-04-27) で 12 ラウンド × 7 候補 = 84 件すべて `[自動採択推奨]` 判定 → escalate 0 件、しかし厳しく再精査 + dev-log 学習で escalate 漏れ計 11 件 (致命級 1 含む) 発見。LLM の easy wins 偏向 / self-confirmation / 軽微寄せ楽観 / 完璧主義の欠如 が原因。視点を与えても LLM が安易に流れる根本問題は「判定深度・検出基準・意図的厳しさ」の構造的強制が必要。

**How to apply:**

## 新 Step 1a (軽微検出、LLM 単独で `[自動採択推奨]` 提示可能)

対象: 明示性向上 / 出典追記 / 軽微な誤記是正 / 単純な内部矛盾解消 / boundary clarification (Phase N 委譲明記) / 軽微情報追加。

LLM 単独で `[自動採択推奨]` ラベル + 1 文判断根拠を併記。判断根拠は簡潔で OK (例: 「明示性向上、boundary 拡張なし、要件不変」)。

## 新 Step 1b (構造的検出、4 重検査必須 + escalate 寄せ義務化)

対象: 規範範囲判断 / 設計決定間矛盾 / 複数選択肢 trade-off / アルゴリズム実装不整合 / failure mode 選択肢 / 内部矛盾 / boundary leakage 等。

**4 重検査を必ず順次実施**:

### Step 1b-i: 二重逆算検査 (production deploy 視点 + Phase 5b 困窮検査)

各候補を「これが design に書かれていない / 曖昧なまま implementation phase に進んだら、(a) production deploy で何が壊れるか / (b) Phase 5b で実装する人はどこで困るか / 判断不能になるか / bug / boundary 違反が発生するか」を**逆算**で検査。曖昧さで実装者が判断不能なら → escalate。LLM の楽観的判定を「具体的破綻シナリオ」で打ち消す。

### Step 1b-ii: Phase 1 escalate 実例パターンマッチング

Phase 1 で escalate された 3 事例と同型を本 spec で**意図的に**探す:

- **Spec 0 escalate** (「3 ヶ月超で ERROR 昇格」削除): 設計決定が requirements 範囲を先取りしているパターン → 規範範囲判断
- **Spec 1 R5 escalate** (Levenshtein → Ratcliff/Obershelp 訂正): アルゴリズム名 / 閾値 / API 名が実装と整合しないパターン → 文書記述 vs 実装不整合
- **Spec 1 R7 escalate** (transaction guarantee → Eventual Consistency 規範): 規範前提が曖昧化しているパターン → 規範前提の曖昧化

3 共通パターン: (a) 設計決定の requirements 範囲先取り / (b) 実装名・閾値の文書不整合 / (c) 規範前提の曖昧化。本 spec で同型検出を意図的に試行 (見つかれば escalate 候補)。

### Step 1b-iii: dev-log 23 パターンチェックリスト適用

`feedback_review_judgment_patterns.md` の dev-log 23 判定パターン (内部矛盾 / 実装不可能性 / 責務境界 / 規範範囲判断 / 複数選択肢 trade-off / state observation integrity / atomicity / concurrency / timeout / race window / failure exhaustiveness / API bidirectional 等) を**ラウンドごとに通読しチェック**。該当箇所が見つかれば escalate 候補。

### Step 1b-iv: 自己診断義務 (LLM bias 自動制御)

各 `[自動採択推奨]` 候補に **「もしユーザーが反転 (`[自動採択推奨]` → `[escalate 推奨]`) したら、その理由は何か」を 1 文以上書く義務**。納得できる反転理由が 1 つでも思い浮かんだら自動的に `[escalate 推奨]` に反転。

例:
```
 重-N-1 (検出: ConfirmResult.CONFIRMED が --dry-run walkthrough 完走時にも返却される、cmd_* 側で args.dry_run 別途チェック規律未明示)
根拠: 内部矛盾 = cmd_* が CONFIRMED を見て本処理 (write 操作) に進む誤読リスク、Spec 1 本-19 successor field 同型
自己診断 (反転理由): cmd_* 側 args.dry_run チェック規律を明示する 1 案 vs ConfirmResult を CONFIRMED_DRY_RUN / CONFIRMED_LIVE の 2 値に分離する 1 案 が存在 = 複数選択肢 trade-off
[escalate 推奨]
```

### Step 1b-v: 自動深掘り判定 (1 回目深掘り 5 観点 + 2 回目深掘り 5 切り口、user 判断負荷軽減)

**Why**: Step 1b で escalate 寄せ義務化 → escalate 件数増加 → user 判断負荷過大 (「細かすぎて判断できない」フィードバック)。LLM が **2 回独立 深掘り** で意見不変なら自動採択することで、user は真に重大な案件のみ介入する形にする。同一 bias での 2 回判定にならないよう、2 回目は 1 回目と独立な 5 切り口で再検証。

**1 回目深掘り (5 観点、positive / 整合性視点)**:
- (a) 実装難易度
- (b) 設計理念整合 (boundary / responsibility / 既存規範)
- (c) 運用整合性 (UX / 透明性 / fallback)
- (d) boundary 違反リスク (cross-spec scope 拡大)
- (e) Phase 1 整合 (継承事項との整合)

→ 推奨案 X1 + 確証根拠

**2 回目深掘り (5 切り口、独立視点)**:

1. **本質的観点 (設計理念根本、top-down)**: 中核原則 / 3 層アーキテクチャ / boundary 規範に立ち返る逆算検査
- 「この決定は §2.X 中核原則 (例: Git + 層別履歴媒体 / Evidence chain) と整合するか?」
- 「この決定は L1/L2/L3 層別適用マトリクスを侵害していないか?」
- 「Curated GraphRAG 本質 (人間承認中心 / Hygiene 自己進化 / Reject-only) と矛盾しないか?」

2. **関連文書間矛盾チェック (cross-document consistency、lateral)**:
- requirements.md (本 spec) との整合: AC 文言と design 記述の grep 一致
- consolidated-spec.md (drafts SSoT): §X.Y 引用先の最新記述との一致
- scenarios.md: Scenario N シナリオフローと design 動作の一致
- steering (product / tech / structure / roadmap): 横断規範との整合
- 隣接 spec design.md (Phase 1 完了): 用語 / API 名 / 数値の一致

3. **仕様⇄プロンプト/Python コード突合 (抽象⇄具体、vertical)**:
- アルゴリズム名 / 閾値 (Phase 1 R5 escalate Levenshtein 同型): 文書記述と実装ライブラリの数学的一致
- API name / 引数構造: design signature と implementation 想定の一致
- prompt template と dispatch logic: AGENTS/skills/ 内 prompt と本 spec dispatch の一致
- v1-archive 参照禁止規律遵守: フルスクラッチ方針との一致

4. **dev-log 23 パターンチェック (過去事例、historical)**: feedback_review_judgment_patterns.md の同型探索

5. **失敗シナリオ + Phase 1 アナロジー (破綻 / 同型、negative)** — **「該当なし」で skim 禁止 (LLM の easy wins 偏向の典型)、強制発動義務化 (2026-04-28 user 指示で追加)**:
- 推奨案 X1 の **破綻シナリオを最低 1 つ意図的に列挙** (例: 将来拡張時の負荷 / 境界曖昧化 / 文書記述 vs 実装乖離 / 規範範囲拡大の連鎖等)。「軽微で該当なし」は判定回避、必ず想像力を使って破綻シナリオを 1 つ捻り出す義務
- Phase 1 escalate 3 実例との **同型比較を必ず実施**:
- Spec 0 R4 escalate「3 ヶ月超 ERROR 昇格」削除 = **規範範囲先取り** パターン (本検出案件に同型はないか?)
- Spec 1 R5 escalate Levenshtein → Ratcliff/Obershelp 訂正 = **文書記述 vs 実装不整合 / アルゴリズム名・閾値の文書誤り** パターン
- Spec 1 R7 escalate transaction guarantee → Eventual Consistency 規範化 = **規範前提曖昧化** パターン
- 破綻シナリオが 1 つ以上見つかれば、または Phase 1 アナロジーで同型疑いがあれば、**反転理由として記録、X1 ≠ X2 の判定材料に**
- 「該当なし」と判定する場合も明示的に「破綻シナリオ列挙の試行 → 該当なし」「Phase 1 アナロジー 3 種比較 → いずれも非同型」と記録 (skim 禁止の証跡)

**Why 強化**: 2026-04-28 Spec 0 R1-R10 やり直しセッションで、各検出案件の 2 回目深掘り 5 切り口のうち 5 番目 (negative) を形式的に「該当なし」で skim していた問題が user 指摘で発覚。LLM の easy wins 偏向で、想像力を要する negative 視点が後回しになる構造的問題。強制発動義務化で skim を構造的に防止。

→ 推奨案 X2 + 反転理由の有無

**確度判定 + 自動採択**:
- **X1 == X2** かつ **5 切り口すべてで反転理由なし**: **自動採択** + トレース記録 + Edit 適用 + 1 行 user 通知
- X1 == X2 だが 5 切り口中 1 件以上で反転理由あり: 確度中、user escalate 寄せ
- X1 ≠ X2 (推奨変動): user escalate 必須

**escalate 必須条件 5 種との関係 (false positive 回避)**:

自動採択対象 = (a) dominated 除外で唯一案 + (b) 5 切り口で反転理由なし + (c) escalate 必須条件 5 種いずれにも非該当。複数選択肢 trade-off / 規範範囲判断 / 内部矛盾 / アルゴリズム不整合 / failure mode 選択肢 のいずれか該当時は自動採択せず user escalate 必須 (false positive = 楽観自動採択を防止)。

**user 通知形式**:

自動採択時、1 ターンで以下を通知 (user 判断不要、確認のみ):

```
[自動採択] 重-厳-N (<検出内容>) → 推奨案 X (理由: <1 行>)
2 回目深掘り 5 切り口で反転理由なし、経緯は research.md「自動採択トレース」に記録
```

複数案件をまとめて 1 ターンで通知可。user は気になる案件のみ「これ反転して」と指定可能。

**トレース記録 (reproducibility)**:

`research.md` に「自動採択トレース」section を追加 (新規 sub-section):

```
## 自動採択トレース

### 重-厳-N (検出: <検出内容>)
 1 回目深掘り (5 観点): <観点別評価> → 推奨案 X1
 2 回目深掘り (5 切り口):
 本質的観点: <評価> → 反転理由なし
 関連文書間矛盾: <grep 結果> → 反転理由なし
 仕様⇄実装突合: <評価> → 反転理由なし
 dev-log 23 パターン: <該当 / 該当なし>
 失敗 + Phase 1 アナロジー: <評価> → 反転理由なし
 確度判定: X1 == X2、5 切り口反転理由なし → 自動採択
 Edit 適用箇所: design.md L<行>
 user 通知: 1 行サマリで通知済
```

各案件で「検出 / 1 回目深掘り 5 観点 / 2 回目深掘り 5 切り口 / 結論 / 自動採択」を記録、後で reproducibility 検証可能。

## escalate 必須条件 5 種 (LLM 単独採択禁止規律)

以下のいずれかに該当したら **必ず `[escalate 推奨]`** を提示しユーザー判断を仰ぐ:

1. **複数の合理的選択肢が存在** (dominated 除外後も 2 案以上残る)
2. **規範範囲判断** (requirements vs design boundary 侵入、要件改版経路を伴う)
3. **設計決定間の矛盾 / 内部矛盾** (cross-Req / cross-決定 / 同一 spec 内 R.X vs R.Y)
4. **アルゴリズム / API / 実装の不整合** (文書記述と実装の数学的・物理的不一致、または signature 矛盾)
5. **failure mode の選択肢** (cleanup / atomicity / partial failure / rollback strategy が複数案存在)

## 新 Step 2 (ユーザー判断、構造維持 + 警告強化)

「LLM 判断への異論ある候補はあるか?」を問う:

- 案 A 異論なし (LLM 判断通り進める = `[自動採択推奨]` 適用 + `[escalate 推奨]` を Step 4 で選択肢提示)
- 案 B 異論あり (どの候補? どう変える? 自動 → escalate / escalate → 自動 / 修正不要 / 再深掘り のいずれか指定)
- 案 C (省略可) 該当なし扱いで次ラウンドへ

**警告強化**: ユーザーは LLM が `[自動採択推奨]` と判定した候補も反転 (escalate に格上げ) する権利がある。LLM が Step 1b の 4 重検査を実施した上での `[自動採択推奨]` でも、ユーザー視点で「これは escalate 級」と判定したら案 B で反転を指示してください。

## ラウンド自動進行規律 廃止 + 厳しく検証 default 化 (2026-04-28 user 再指示で改訂)

**Why 廃止**: 2026-04-28 セッションで「致命・重要級なしで自動承認」モードを試行した結果、LLM の easy wins 偏向 / self-confirmation / 軽微寄せ楽観が再発、Spec 0 で本質的問題 3 件 (重-厳-3 Components §1/§6/§8/§9 sub-section 欠落 / 重-厳-4 subprocess shell injection 防止規律未明示 / 重-厳-5 approvals.requirements 誤記 2 箇所) を見過ごした。user が「厳しく行う」と明示指示してから 3 件発見 = 自動承認モードの判定甘さが原因。「致命/重要なし」の判定自体が LLM の楽観偏向を増幅する構造的問題のため、自動進行規律を廃止。

### 新規律 1: 各ラウンドで必ず Step 2 (user 判断) を経る、自動承認禁止

- 検出なしのラウンドでも Step 1 (検出 + 判定) → Step 2 (user 判断) を必ず経る
- 1 ラウンド = 1 turn 以上 (memory `feedback_no_round_batching.md` 規律遵守)
- user は「異論なし」(案 A)、「異論あり」(案 B)、「該当なし扱い」(案 C) のいずれかで応答
- 1 turn で複数ラウンド連続処理を禁止 (前回の自動進行で軽微寄せ楽観が促進されたため)

### 新規律 2: 厳しく検証 default 化 (本質的観点 5 種を強制発動)

各ラウンドで以下 5 種を **強制発動** で検査:

- **a) 規範範囲先取り検査**: requirements に対応 AC がない記述を design で確定していないか (Phase 1 Spec 0 R4 escalate「3 ヶ月超 ERROR 昇格」削除 / Spec 0 R1 重-厳-2 性能 target 示唆値化 と同型)
- **b) 構造的不均一検査**: design 内の sub-section 構造、Components 詳細度、Boundary Commitments 記述、各セクション同形式での一貫性 (Spec 0 R2 重-厳-3 Components §1/§6/§8/§9 欠落 と同型)
- **c) 文書記述 vs 実装不整合検査**: アルゴリズム名 / 閾値 / API name / signature / 引数構造の文書 vs 実装整合 (Phase 1 Spec 1 R5 escalate Levenshtein → Ratcliff/Obershelp と同型)
- **d) 規範前提曖昧化検査**: 規範前提 (Severity / exit code / envelope schema / approve gate / etc.) が design 内で整合的に明示されているか (Phase 1 Spec 1 R7 escalate Eventual Consistency / Spec 0 R1 重-厳-1 R10.7 (a) のみ採用根拠 と同型)
- **e) 単純誤記 grep 検査**: approval gate / spec.json field / file path / function name 等の単純誤記を grep で機械的に検査 (Spec 0 R7-R10 重-厳-5 approvals.requirements 誤記 2 箇所 と同型)

5 種すべてを各ラウンドで強制発動、検出ゼロでも「5 種で検査結果なし」を明示してから Step 2 へ。

**Why default 化**: 「厳しく検証」を user が明示指示した時点でのみ発動する modal 設計だと、LLM の easy wins 偏向で平常時の検証深度が不十分になる。default 化することで構造的に厳しさを強制、user 介入頻度を減らす。

### 通知形式

各ラウンド終了時の通知 (Step 2 直前):

```
[ラウンド N 厳しく検証結果]
本質的観点 5 種:
 a) 規範範囲先取り: <検出 N 件 / 検出なし>
 b) 構造的不均一: <検出 N 件 / 検出なし>
 c) 文書記述 vs 実装不整合: <検出 N 件 / 検出なし>
 d) 規範前提曖昧化: <検出 N 件 / 検出なし>
 e) 単純誤記 grep: <検出 N 件 / 検出なし>

検出件数: <自動採択 N 件 / escalate M 件 / 検出なし>

[Step 2] LLM 判断への異論ある候補は?
 案 A 異論なし
 案 B 異論あり
 案 C 該当なし扱い
```

user 判断後、次ラウンドへ進む。

### 関連 memory 整合

- memory `feedback_no_round_batching.md`: 1 ラウンド = 1 turn 以上、batching 禁止 — 本規律で各ラウンド user 判断必須化により遵守強化
- memory `feedback_review_judgment_patterns.md` (dev-log 23 パターン): 厳しく検証 5 種 (a)-(e) と組み合わせ、Step 1b-iii で通読
- memory `feedback_design_review.md`: 10 ラウンド観点と組み合わせ、各ラウンドの観点に厳しく検証 5 種を強制発動

## Step 3-4 (詳細抽出 + 深掘り判断、escalate 確証手順を追加)

- Step 2「異論なし」確定後: `[自動採択推奨]` は Edit で適用、`[escalate 推奨]` は **escalate 確証手順** (下記) で処理
- Step 2「異論あり」確定後: ユーザー指定の方向で再深掘り or 反転判断

### escalate 案件処理時の確証手順 (深掘り検証 → 推奨案確証 → 2 択判断)

LLM の判断負荷を user に転嫁しないため、escalate 案件は以下の手順で処理:

1. **選択肢を 5 観点で深掘り検証**:
- (a) 実装難易度
- (b) 設計理念整合 (boundary / responsibility / 既存規範)
- (c) 運用整合性 (UX / 透明性 / fallback)
- (d) boundary 違反リスク (cross-spec scope 拡大)
- (e) Phase 1 整合 (継承事項との整合)

2. **推奨案が確証持てる場合** (dominated 除外で唯一案 or 5 観点で他案を凌駕):
- 推奨案 + 確証根拠 5 点 + 却下案の理由を提示
- user は「推奨で進める / 異論あり」の **2 択** で判断 (3 選択肢提示は不要、認知負荷軽減)

3. **推奨案が確証持てない場合** (5 観点で各案優劣分かれる):
- 全選択肢を user に提示し判断委譲 (旧形式の 3 選択肢提示)

4. **複数 escalate を一括提示する場合** (例: 同型の事後追認 escalate):
- 各候補の推奨案を列挙、各々 5 観点深掘り根拠を併記
- user は「全件推奨で OK / 項目 X / Y を個別反転」の **2 択** で判断 (一括効率)

**Why**: Spec 4 design レビュー試行中、escalate 寄せ義務化で escalate 件数が増加 → user 判断負荷が過大 (「細かすぎて判断できない」フィードバック発生)。LLM が深掘り検証で確証推奨案を提示することで、user は推奨案を確認するだけで OK or 異論で個別反転、となる形で認知負荷を最小化する。

## ラベル付与の判定基準 (改修版、escalate 寄せ厳格化)

- `[自動採択推奨]`: Step 1a 軽微検出 (明示性向上 / 誤記是正 / boundary clarification / 軽微情報追加) + Step 1b で 4 重検査クリア + escalate 必須条件 5 種に**いずれも該当しない** + 自己診断で反転理由が思い浮かばない
- `[escalate 推奨]`: Step 1b 4 重検査でいずれか発見 OR escalate 必須条件 5 種いずれか該当 OR 自己診断で反転理由 1 つ以上 OR 判定迷う場合 (false negative より false positive 安全)

## 適用範囲と評価

- **本 memory は Spec 4 design 試行 (2026-04-27) で escalate 寄せ機能不全が判明したため改修**、改修版を Spec 4 design に再適用 + Spec 7 design 以降は初手から適用
- **Spec 0 / Spec 1 にも遡り適用** (2026-04-28 セッションで決定): 旧 Step 1-2 の自動採択偏向 + ラウンド 4-12 一括処理 batching の影響で escalate 漏れリスクあり、Phase 1 design approve を取り消し + 全 10 ラウンド (12 → 10 統合反映) を新方式 (4 重検査 + Step 1b-v 自動深掘り 5 切り口) で再実施。Spec 0 → Spec 1 順、design.md / research.md は残し再レビュー結果で上書き
- 試行結果 (escalate 件数 / ユーザー反転介入頻度 / レビュー所要時間 / false positive 比率) を Phase 1 やり直し + Phase 2 完了後に評価し、本格採用 or 再調整を判断

## 関連 memory (継続適用)

- `feedback_review_judgment_patterns.md` — dev-log 23 判定パターンチェックリスト (Step 1b-iii で適用)
- `feedback_no_round_batching.md` — 1 ラウンド = 1 turn 以上、batching 禁止
- `feedback_dominant_dominated_options.md` — dominated 除外 (escalate 必須条件 1 の前提)
- `feedback_choice_presentation.md` — 1 ターン 3 選択肢以内 + 階層性 + ラベル
- `feedback_design_review.md` — 12 ラウンド構成 (本 memory は各ラウンド Step 1 内で適用)
- `feedback_review_rounds.md` — 5 ラウンド構成 (仕様レビュー)
- `feedback_approval_required.md` — visible action gate
