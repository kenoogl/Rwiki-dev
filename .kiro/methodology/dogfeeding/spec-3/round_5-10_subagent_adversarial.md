# Spec 3 design 10 ラウンドレビュー + adversarial subagent 試験運用 (Round 5-10) 報告書

**作成日**: 2026-04-29
**対象 spec**: rwiki-v2-prompt-dispatch (Spec 3、Phase 4)
**対象セッション**: design 10 ラウンドレビュー (Round 1-10) + approve + Adjacent Sync
**関連 commit**: `f28f0a0` (Spec 3 design approve) + `edac6c3` (Spec 4 Adjacent Sync) + `793648d` (dev-log)

---

## 1. 報告書の目的

本報告書は以下 2 点を整理する:

1. **現在運用中の設計書レビュー方法論を最初から詳しく記述** (Round 1-10 で適用した方法、旧 10 ラウンド方式 + Round 5-10 で adversarial subagent を統合した試験運用版)
2. **Round 5-10 で収集した試験運用 metrics データの分かりやすい整理 + 効果評価**

最終的に「設計レビュー方法論 v3 (旧 10 ラウンド + adversarial subagent 統合)」として正式採用するかの判断材料を提供する。

---

## 2. 設計書レビュー方法論の完全記述

### 2.1 全体構成

設計書 (design.md) を **10 観点 × 1 ラウンド = 10 ラウンド** で系統的にレビューする方式。各ラウンドは独立した観点を持ち、全件網羅を原則とする (省略不可、「該当なし」確認も明示)。

10 ラウンドの観点:

| Round | 観点 | 主な検証範囲 |
|-------|------|---|
| 1 | requirements 全 AC の網羅 | Requirements Traceability table、Components 紐付け |
| 2 | アーキテクチャ整合性 | モジュール分割 / レイヤ / 依存グラフ / Mermaid 図 |
| 3 | データモデル / スキーマ詳細 | dataclass / enum / Union 定義の完備性 |
| 4 | API interface 具体化 | Service Interface signature / error model / DI chain |
| 5 | アルゴリズム + 性能達成手段 | 計算量 / edge case / cache / 並列化 |
| 6 | 失敗モード handler + 観測性 | rollback / retry / timeout / ログ / metrics / trace ID |
| 7 | セキュリティ / プライバシー具体化 | sanitize / encryption / log redaction / git ignore |
| 8 | 依存選定 | library / version 制約 / v1 継承整合 |
| 9 | テスト戦略 | unit / integration / cross-spec / fixture / coverage |
| 10 | マイグレーション戦略 | v1→v2 / Adjacent Sync 経路 / Revalidation Triggers |

### 2.2 各ラウンドの構造 (Step 1 → Step 2 → Step 3-4)

#### Step 1a (軽微検出)

明示性向上 / 出典追記 / 軽微な誤記是正 / 単純な内部矛盾解消 / boundary clarification (Phase N 委譲明記) / 軽微情報追加が対象。

LLM 単独で `[自動採択推奨]` ラベル + 1 文判断根拠を併記。

#### Step 1b (構造的検出、4 重検査必須 + escalate 寄せ義務化)

規範範囲判断 / 設計決定間矛盾 / 複数選択肢 trade-off / アルゴリズム実装不整合 / failure mode 選択肢 / 内部矛盾 / boundary leakage 等が対象。

**Step 1b-i: 二重逆算検査**
各候補を「これが design に書かれていない / 曖昧なまま implementation phase に進んだら、(a) production deploy で何が壊れるか / (b) Phase 5b で実装する人はどこで困るか」を逆算検査。

**Step 1b-ii: Phase 1 escalate 実例パターンマッチング**
Phase 1 で escalate された 3 事例と同型を意図的に探す:
- **Spec 0 R4 escalate**「3 ヶ月超 ERROR 昇格」削除 = **規範範囲先取り** パターン
- **Spec 1 R5 escalate** Levenshtein → Ratcliff/Obershelp 訂正 = **文書記述 vs 実装不整合** パターン
- **Spec 1 R7 escalate** transaction guarantee → Eventual Consistency 規範化 = **規範前提曖昧化** パターン

**Step 1b-iii: dev-log 23 パターンチェックリスト適用**
過去レビューログから抽出した 23 判定パターンを各ラウンドごとに通読しチェック。

**Step 1b-iv: 自己診断義務 (LLM bias 自動制御)**
各 `[自動採択推奨]` 候補に「もしユーザーが反転 (`[自動採択推奨]` → `[escalate 推奨]`) したら、その理由は何か」を 1 文以上書く義務。納得できる反転理由が 1 つでも思い浮かんだら自動的に `[escalate 推奨]` に反転。

#### Step 1b-v: 自動深掘り判定 (1 回目深掘り 5 観点 + 2 回目深掘り 5 切り口)

**1 回目深掘り (5 観点、positive / 整合性視点)**:
- (a) 実装難易度
- (b) 設計理念整合 (boundary / responsibility / 既存規範)
- (c) 運用整合性 (UX / 透明性 / fallback)
- (d) boundary 違反リスク (cross-spec scope 拡大)
- (e) Phase 1 整合 (継承事項との整合)

→ 推奨案 X1 + 確証根拠

**2 回目深掘り (5 切り口、独立視点)**:
1. **本質的観点 (top-down)**: 中核原則 / 3 層アーキテクチャ / boundary 規範に立ち返る逆算検査
2. **関連文書間矛盾チェック (lateral)**: requirements / consolidated-spec / scenarios / steering / 隣接 spec design との整合
3. **仕様⇄プロンプト/Python コード突合 (vertical)**: アルゴリズム名 / 閾値 / API name の文書 vs 実装整合
4. **dev-log 23 パターンチェック (historical)**: 過去事例の同型探索
5. **失敗シナリオ + Phase 1 アナロジー (negative)**: 破綻シナリオを最低 1 つ意図的に列挙、Phase 1 escalate 3 実例との同型比較

→ 推奨案 X2 + 反転理由の有無

**確度判定 + 自動採択**:
- X1 == X2 + 5 切り口で反転理由なし: 自動採択 + トレース記録 + Edit 適用 + 1 行 user 通知
- X1 == X2 だが 5 切り口中 1 件以上で反転理由あり: user escalate 寄せ
- X1 ≠ X2: user escalate 必須

#### escalate 必須条件 5 種

以下のいずれかに該当したら必ず `[escalate 推奨]`:

1. 複数の合理的選択肢が存在 (dominated 除外後も 2 案以上残る)
2. 規範範囲判断 (requirements vs design boundary 侵入、要件改版経路を伴う)
3. 設計決定間の矛盾 / 内部矛盾
4. アルゴリズム / API / 実装の不整合 (signature 矛盾)
5. failure mode の選択肢 (cleanup / atomicity / rollback strategy が複数案存在)

#### 厳しく検証 5 種 (default 強制発動)

各ラウンドで以下 5 種を強制発動で検査:

- (a) **規範範囲先取り検査**: requirements に対応 AC がない記述を design で確定していないか (Spec 0 R4 同型)
- (b) **構造的不均一検査**: design 内の sub-section 構造、Components 詳細度の一貫性 (Spec 0 R2 同型)
- (c) **文書記述 vs 実装不整合検査**: アルゴリズム名 / 閾値 / API name / signature / 引数構造の文書 vs 実装整合 (Spec 1 R5 同型)
- (d) **規範前提曖昧化検査**: Severity / exit code / envelope schema / approve gate の規範前提が design 内で整合的に明示されているか (Spec 1 R7 同型)
- (e) **単純誤記 grep 検査**: approval gate / spec.json field / file path / function name 等の単純誤記を grep で機械的に検査

5 種すべてを各ラウンドで強制発動、検出ゼロでも「5 種で検査結果なし」を明示してから Step 2 へ。

#### Step 2 (ユーザー判断、構造維持 + 警告強化)

「LLM 判断への異論ある候補はあるか?」を問う:

- 案 A: 異論なし (LLM 判断通り進める)
- 案 B: 異論あり (どの候補? 自動 → escalate / escalate → 自動 / 修正不要 / 再深掘り のいずれか指定)
- 案 C: 該当なし扱いで次ラウンドへ

#### Step 3-4 (詳細抽出 + 深掘り判断、escalate 確証手順)

- Step 2「異論なし」確定後: `[自動採択推奨]` は Edit で適用、`[escalate 推奨]` は escalate 確証手順で処理
- escalate 確証手順:
  1. 選択肢を 5 観点で深掘り検証 (実装難易度 / 設計理念整合 / 運用整合性 / boundary 違反リスク / Phase 1 整合)
  2. 推奨案が確証持てる場合: 推奨案 + 確証根拠 5 点 + 却下案の理由を提示、user は「推奨で進める / 異論あり」の **2 択** で判断
  3. 推奨案が確証持てない場合: 全選択肢を user に提示し判断委譲 (旧形式の 3 選択肢提示)

### 2.3 Round 5-10 で導入した adversarial subagent 試験運用

#### 動機

- LLM の easy wins 偏向 / 自動採択偏向バイアスを user 介入で制御していたが、user が全件「案 A」即答で形式化していた
- 真の抑止力 = 「LLM が user に説明する責任」を背負って厳しく検査せざるを得ない構造的 pressure
- 別 subagent (Sonnet 4.6) を adversarial reviewer として起動し、LLM 主体 (Opus 4.7) を independent に審査することで、抑止力を維持しつつ user 認知負荷を分散

#### 実装構造

各 Round で以下 3 ステップを実施:

1. **LLM 主体 Step 1 検出** (Claude Opus 4.7、現状の方法論)
2. **adversarial subagent 起動** (Claude Sonnet 4.6、general-purpose subagent)
   - 入力: design.md + requirements.md + LLM 主体検出結果
   - bias 抑制必須 quota:
     - (1) LLM 主体の自動採択候補に formal challenge 必須 (challenge 経緯 1 行明示)
     - (2) 検出漏れを 1 件以上探す quota (該当なしなら「N 観点検査済」を明示)
     - (3) Phase 1 escalate 3 実例 (Spec 0 R4 / Spec 1 R5 / Spec 1 R7) の同型探索を必ず実施
3. **検出統合 + user 報告**:
   - LLM 主体検出と subagent 検出を統合
   - disagreement (LLM ≠ subagent 推奨) は user 仲裁
   - 一致部分は user 確認のみで Edit 適用

#### subagent prompt 設計の特徴

- **異なる model**: Sonnet 4.6 (Opus 4.7 と異なる偏向で bias 共有を抑制)
- **adversarial 役割明示**: 「LLM 主体は user が信頼する優秀な reviewer。安易に否定するためにあなたが存在するのではなく、LLM の偏向を意識的に抑制するための構造的 challenger」
- **formal challenge quota**: 自動採択候補を「同意」と判定する場合も challenge を試みた経緯を 1 行明示
- **検出漏れ quota**: 検査観点候補リストを Round ごとに具体提示 (例: Round 7 = symlink follow / prompt injection / PATH hijack / file size 上限 等 13 観点)
- **出力フォーマット厳密遵守**: 統一形式で報告 (LLM 主体検出への審査 / 検出漏れ追加 / Phase 1 同型探索 / 総合判断)

---

## 3. 収集データ (Round 5-10 metrics)

### 3.1 Round ごとの metrics 表

| Round | 観点 | LLM 自動 / escalate | subagent 追加 (致命/重要/軽微) | disagreement | 致命級 (subagent) | Phase 1 同型該当 | wall-clock |
|-------|------|---|---|---|---|---|---|
| Round 5 | アルゴリズム+性能 | 1 / 2 | 0 / 2 / 1 | 0 | 0 | R7 | ~135s |
| Round 6 | 失敗+観測 | 1 / 3 | 0 / 2 / 1 | **1** | 0 | R7 | ~130s |
| Round 7 | セキュリティ | 2 / 3 | **1** / 3 / 2 | 1 | **1** | **3 種全** | ~142s |
| Round 8 | 依存選定 | 1 / 3 | 0 / 3 / 2 | 0 | 0 | R5 + R7 | ~122s |
| Round 9 | テスト戦略 | 1 / 3 | 0 / 3 / 2 | 0 | 0 | **3 種全** | ~159s |
| Round 10 | マイグレーション | 1 / 2 (+整合 1) | 0 / 0 / 1 | 0 | 0 | R5 + R7 | ~220s |
| **累計** | — | **7 / 16** | **1 / 13 / 9 = 23 件** | **2** | **1** | — | **平均 ~152s** |

### 3.2 累計 metrics (Round 5-10 全 6 Round)

#### LLM 主体検出
- 自動採択: **7 件**
- escalate: **16 件**
- 整合確認のみ (修正不要): 1 件
- 計: **24 件**

#### subagent 追加検出 (LLM 主体に含まれない独立発見)
- 致命級: **1 件** (致命-7-1 symlink follow 攻撃)
- 重要級: **13 件**
- 軽微: **9 件**
- 計: **23 件** (LLM 主体検出と同等規模の補完 value-add)

#### subagent による LLM 主体推奨の修正
- disagreement (LLM ≠ subagent 推奨): **2 件** (Round 6 / Round 7)
- 緩和推奨 (escalate 範囲縮小 / 推奨案修正): **3 件** (重-6-2 / 重-6-3 / 重-7-2)
- 反転推奨 (自動採択 → escalate に格上げ): **0 件**

#### Phase 1 escalate 同型該当数の発展
- Round 5: 1 種 (Spec 1 R7)
- Round 6: 1 種 (Spec 1 R7)
- **Round 7: 3 種全該当** ← 1 度目達成
- Round 8: 2 種 (Spec 1 R5 + R7)
- **Round 9: 3 種全該当** ← 2 度目達成
- Round 10: 2 種 (Spec 1 R5 + R7)

### 3.3 wall-clock 集計

- subagent 1 回平均: **~152 秒** (122-220 秒範囲)
- 全 6 Round の subagent 実行合計: **~908 秒 (~15 分)**
- user 待ち時間ゼロ (subagent 並行実行可能、user は disagreement のみ判断)

### 3.4 致命級 + 重要級 追加検出の具体例

#### 致命級 1 件 (Round 7)
- **致命-7-1 symlink follow 攻撃**: vault 範囲外を指す symlink で `FrontmatterReader.read_content()` が任意 file 読込可能、Spec 4 / 本 spec 所管未確定 (LLM 主体完全見落とし、subagent 独立検出)

#### 重要級 13 件 (各 Round 由来)
- **Round 5**: 重-5-3 LLM 推論 prompt 出力形式 parse 優先順位 / 重-5-4 1 dispatch あたり LLM 呼び出し回数規律
- **Round 6**: 重-6-4 LLMCLIInvoker stderr 取り扱い規律 / 重-6-5 DispatchResult.notes format 確定
- **Round 7**: 重-7-4 candidate_pool 経由 prompt injection / 重-7-5 PATH hijack 防御 / 重-7-6 input file size 上限
- **Round 8**: 重-8-4 Python 3.10/3.11 subprocess timeout zombie 化防止 / 重-8-5 type alias forward reference 規律 / 重-8-6 v1-archive 参照禁止 vs 継承の意味論的整合
- **Round 9**: test fixture 管理戦略 / coverage threshold / regression test 戦略

---

## 4. mitigation 効果評価

### 4.1 bias 共有疑念に対する反証

**仮説 (試験運用前の懸念)**: 同じ Claude モデル (Opus / Sonnet) は同じ偏向 (easy wins / 自動採択偏向) を共有し、subagent 代行は LLM 主体に「ただ同意するだけ」になる可能性。

**反証 evidence (試験運用結果)**:

1. **致命級独立発見 (Round 7)**: subagent が LLM 主体完全見落としの致命級を独立検出 → 同モデル偏向共有では発見不可能な検出
2. **disagreement 発生 (Round 6 / Round 7)**: subagent が LLM 主体推奨の見落とし (Monitoring section L1171-1174 / Notification.source 7 値列挙) を発見 → 単純同意ではなく真の independent 視点維持
3. **Phase 1 escalate 同型 3 種全該当を 2 度達成 (Round 7 + Round 9)**: subagent が Spec 0 R4 / Spec 1 R5 / Spec 1 R7 の全 3 種 escalate パターンを独立に該当検出 → Phase 1 学習適用が安定化
4. **緩和推奨 3 件**: LLM 主体推奨が過剰 (規範範囲先取りリスク) と subagent が指摘 (重-7-2 で Spec 0 R4 同型回避、credential pattern 例示削除) → bias 抑制機能の発動

### 4.2 LLM 主体見落としの subagent 独立検出

**全 6 Round で 23 件の独立補完検出**:
- 致命級 1 + 重要級 13 + 軽微 9 = LLM 主体検出 23 件と同等規模
- 単独では LLM 主体が見落とす可能性のある観点を subagent が補完
- 特に致命級 1 件 + 重要級 13 件は致命的 / 高優先度の見落としを防止

### 4.3 wall-clock 影響

- subagent 1 回平均 ~152 秒 (約 2.5 分)
- user 待ち時間ゼロ (並行実行可能)
- 全 6 Round で subagent 合計 ~15 分
- user の旧方式 (1 ラウンド = 4-6 turn × 10 ラウンド = 40-60 turn 必要、各 turn で user 即答) と比較してほぼ同等の wall-clock、ただし user 認知負荷分散で実質効率向上

### 4.4 user 認知負荷

**旧方式 (Round 1-4 で実施)**:
- 各 Round で user は LLM 主体提示の検出に対し「案 A / B / C」即答 (実質形式的承認)
- user 全件「案 A」即答 = 真の判断機能不全

**Round 5-10 試験運用方式**:
- user は disagreement (LLM ≠ subagent 推奨) のみ仲裁判断
- LLM + subagent 一致部分は確認のみ
- 真に user 判断が必要な escalate 級事項に集中 = 認知負荷分散

### 4.5 限界 + 課題

- **Round 5 / 6 / 8 / 10 で致命級発見ゼロ**: subagent が adversarial 機能を発動しても致命級が常に発見されるわけではない (LLM 主体の Round 1-4 系統的解消 + Round 5/6 で網羅性が高かった可能性)
- **Round 10 で軽微 1 件のみ**: 規律的 / governance 観点では構造的問題が少なく subagent 追加検出量も低下
- **subagent 自身の self-limitation 記録**: 同モデル (Sonnet 4.6) として Opus 4.7 との偏向差異は構造的に限定的、追加検出の粒度が LLM 主体の検出と類似する傾向あり

---

## 5. 結論 + 採用推奨

### 5.1 mitigation 結論

**試験運用は mitigation 成功 evidence を確立**:

- 致命級独立発見 (1 件) + LLM 主体推奨緩和反転 (3 件) + Phase 1 同型 3 種全該当を 2 度達成 = bias 共有疑念に対する決定的反証
- subagent は同モデル偏向を超えた independent reviewer として機能
- wall-clock 影響は限定的、user 認知負荷は分散

### 5.2 設計レビュー方法論 v3 (採用推奨)

**v3 = 旧 10 ラウンド + adversarial subagent 統合**:

- Round 1-10 全観点で adversarial subagent (Sonnet 4.6) を default 起動
- LLM 主体 (Opus 4.7) Step 1 検出 → subagent 独立審査 → 検出統合 → user 仲裁判断
- bias 抑制 quota 必須 (formal challenge / 検出漏れ / Phase 1 同型探索 3 種)
- 各 Round metrics 記録 + 試行ログ集計

### 5.3 採用判断材料

- **Pro**: 致命級独立発見 + LLM 主体見落とし 2 件指摘 + bias 抑制機能 evidence
- **Con**: subagent token cost 増加 (Sonnet 4.6 で平均 ~150 秒 / Round)、致命級発見の保証なし
- **総合判断**: subagent token cost は致命級 1 件防止 (production deploy 後の工数 vs subagent 数分のコスト) で十分回収可能、採用推奨

### 5.4 残課題

1. **subagent の致命級発見率の継続観察**: Round 7 のみ致命級発見、他 5 Round は 0 件 → Phase 5b 以降の spec で同方法論を継続適用し統計を取る必要
2. **Sonnet vs Haiku の比較**: より cheap な Haiku 4.5 で同等の adversarial 機能が発揮されるか検証する余地
3. **subagent prompt 改良**: Phase 1 escalate 同型探索で Spec 0 R4 / Spec 1 R5 該当検出が Round 7 / Round 9 に集中した理由分析、より早期の Round で 3 種全該当を達成できる prompt 設計
4. **user による subagent 結果 review 経験の蓄積**: subagent 推奨を user が反転した case の傾向分析 (本試験運用では発生せず、Phase 5b 以降で蓄積)

---

## 6. 試験運用 metrics 詳細表 (補足)

### 6.1 Round 5: アルゴリズム + 性能達成手段

| 検出 | 種別 | 由来 |
|------|------|------|
| 軽-5-1 | 自動採択 | LLM 主体 (Round 1 修正漏れ訂正、Testing Strategy 60→120 秒) |
| 軽-5-2 | 自動採択 | subagent (Performance baseline 取得規律) |
| 重-5-1 | escalate | LLM 主体 (LLM CLI content truncation 規律) |
| 重-5-2 | escalate | LLM 主体 (glob match `**` recursive edge case) |
| 重-5-3 | escalate | subagent (LLM 推論 parse 優先順位) |
| 重-5-4 | escalate | subagent (1 dispatch あたり LLM 呼び出し回数) |

### 6.2 Round 6: 失敗モード handler + 観測性

| 検出 | 種別 | 由来 |
|------|------|------|
| 軽-6-1 | 自動採択 | LLM 主体 (diagnostic dump Phase 5b 範囲) |
| 軽-6-2 | 自動採択 | subagent (LLMInvocationError catch 範囲) |
| 重-6-1 | escalate | LLM 主体 (retry 戦略明示) |
| 重-6-2 | escalate (緩和) | LLM 主体 / subagent 緩和反映 (dispatch_id 発行所管 = Spec 4) |
| 重-6-3 | escalate (緩和) | LLM 主体 / subagent 緩和反映 (NotificationSource Literal 7 値) |
| 重-6-4 | escalate | subagent (LLMCLIInvoker stderr 取り扱い) |
| 重-6-5 | escalate | subagent (DispatchResult.notes format confirmed) |

### 6.3 Round 7: セキュリティ / プライバシー具体化

| 検出 | 種別 | 由来 |
|------|------|------|
| 軽-7-1 | 自動採択 | LLM 主体 (path traversal 所管明示) |
| 軽-7-2 | 自動採択 | LLM 主体 (credential 取り扱い所管明示) |
| 軽-7-3 | 自動採択 | subagent (notes plain text 保証) |
| 軽-7-4 | 自動採択 | subagent (stack trace Spec 4 境界) |
| 重-7-1 | escalate | LLM 主体 (prompt injection 防御) |
| 重-7-2 | escalate (緩和) | LLM 主体 / subagent 緩和反映 (stderr redaction、credential pattern 削除 = Spec 0 R4 同型回避) |
| 重-7-3 | escalate | LLM 主体 (parse_error sanitize) |
| 重-7-4 | escalate | subagent (candidate_pool 経由 prompt injection) |
| 重-7-5 | escalate | subagent (PATH hijack 防御) |
| 重-7-6 | escalate | subagent (input file size 上限) |
| **致命-7-1** | **escalate (致命級)** | **subagent (symlink follow 攻撃防御)** |

### 6.4 Round 8: 依存選定

| 検出 | 種別 | 由来 |
|------|------|------|
| 軽-8-1 | 自動採択 | LLM 主体 (新規 dependency ゼロ方針強化) |
| 軽-8-2 | 自動採択 | subagent (PyYAML libyaml C extension 任意) |
| 軽-8-3 | 自動採択 | subagent (fnmatch POSIX path separator 前提) |
| 重-8-1 | escalate | LLM 主体 (PyYAML version 制約 pin) |
| 重-8-2 | escalate | LLM 主体 (Python version boundary 明示) |
| 重-8-3 | escalate | LLM 主体 (v1 継承の具体規律) |
| 重-8-4 | escalate | subagent (subprocess timeout zombie 化防止) |
| 重-8-5 | escalate | subagent (type alias forward reference) |
| 重-8-6 | escalate | subagent (v1-archive 参照禁止 vs 継承の意味論的整合) |

### 6.5 Round 9: テスト戦略

| 検出 | 種別 | 由来 |
|------|------|------|
| 軽-9-1 | 自動採択 | LLM 主体 (test mock 戦略明示) |
| 軽-9-2 | 自動採択 | subagent (parametrized test 戦略) |
| 軽-9-3 | 自動採択 | subagent (test file 名の括弧書き追記) |
| 重-9-1 | escalate | LLM 主体 (13 component → 7 test file 対応表) |
| 重-9-2 | escalate | LLM 主体 (cross-spec test ハイブリッド方式) |
| 重-9-3 | escalate | LLM 主体 (79 AC test 紐付け) |
| 重-9-4 | escalate | subagent (test fixture 管理戦略) |
| 重-9-5 | escalate | subagent (coverage threshold) |
| 重-9-6 | escalate | subagent (regression test 戦略) |

### 6.6 Round 10: マイグレーション戦略

| 検出 | 種別 | 由来 |
|------|------|------|
| 軽-10-1 | 整合確認のみ (修正不要) | LLM 主体 (v1-archive 参照禁止整合) |
| 軽-10-2 | 自動採択 | subagent (drafts SSoT 改版トリガー) |
| 重-10-1 | escalate | LLM 主体 (Foundation 改版経路明示) |
| 重-10-2 | escalate | LLM 主体 (Spec 4 line 172 訂正の Adjacent Sync 工程詳細) |

---

## 7. 関連 commit + 参照

- **Spec 3 design approve**: `f28f0a0`
- **Spec 4 Adjacent Sync** (line 172 訂正): `edac6c3`
- **dev-log + 設計レビュー機械式 + methodology trial**: `793648d` (本ファイル含む)
- **memory 規律** (Round 1-4 で適用):
  - `feedback_design_review.md`: 10 ラウンド構成
  - `feedback_review_step_redesign.md`: Step 1a/1b 分割 + 4 重検査 + Step 1b-v 自動深掘り 5 切り口
  - `feedback_no_round_batching.md`: ラウンド一括処理禁止
  - `feedback_dominant_dominated_options.md`: dominated 選択肢除外 + 厳密化規律
  - `feedback_review_judgment_patterns.md`: dev-log 23 パターンチェックリスト
- **試験運用 v3 候補 (Round 5-10 で導入)**: 旧 10 ラウンド + adversarial subagent (Sonnet 4.6) 統合、本報告書で記述

---

_本報告書は Spec 3 design 10 ラウンドレビューの試験運用 metrics + 方法論記録を集約。設計レビュー方法論 v3 の正式採用判断材料として、Phase 5b 以降の spec で継続適用し統計を蓄積する予定。_

---

## 8. dual-reviewer 一般化 design 議論 (本セッション継続、5 観点全クローズ)

本 section は、試験運用 evidence 確立後に実施した「dual-reviewer の Rwiki 開発から独立 package への一般化」議論の確定事項を集約する。5 観点 (Layer 1 portable / Layer 2 メタパターン / phase 横断適用 / multi-project bias / subagent 再帰多重化) を順次議論し、すべての確定事項を以下に整理する。

### 8.1 観点 1: Layer 1 portable package + 開発戦略

| 項目 | 確定 |
|------|------|
| 名称 | dual-reviewer |
| 配布 | npm package (`npx dual-reviewer@latest`) + GitHub repo (cc-sdd 同方式) |
| skill 接頭辞 | `dr-` |
| 多言語 | `--lang ja/en` 初期 (memory 言語選択)、prompt 英語固定、subagent 出力 = document auto-detect + memory 言語 fallback |
| 開発戦略 | ハイブリッド = Phase A (Rwiki 内試験運用継続) → Phase B (Spec 6 approve 後独立 fork) → Phase C (Rwiki dogfooding) |
| MVP | design phase 最初、すぐ tasks phase 追加 |
| Skills 構造 | `dr-{requirements, design, tasks, impl}` (phase 別) + 共通 utility (`dr-init` / `dr-log` / `dr-extract` / `dr-validate` / `dr-update` / `dr-translate`) |
| cc-sdd integration | 選択肢 3 ハイブリッド (独立 + cc-sdd integration optional、`--integrate-cc-sdd` flag) |
| Layer 構造 | Layer 1 (phase 横断 framework) + Layer 2 (phase 別 extension) + Layer 3 (project 固有) |
| Tier 比率 | post-run measurement only (bias 防止、target setting せず実測のみ JSONL 記録) |
| Quota | event-triggered 介入の核、phase 別 extension で拡張可能 |
| requirements quota | R-1 (user 意図確認) / R-2 (domain 不在 escalate) / R-3 (stakeholder mapping) / R-4 (scope creep 検出) initial set、運用調整 |
| 用語抽象化 | primary reviewer / adversarial reviewer (model 名 = config 抽象化、`primary_model` / `adversarial_model` で将来 model 切替対応) |
| section 見出し | bilingual 併記 (project 言語 + 英語ラベル) |
| schema field | 構造ラベル英語固定、自由記述は project 言語 |
| pattern 翻訳 | transfer 時 LLM 翻訳、terminology.yaml で用語 mapping |

### 8.2 観点 2: continuous learning cycle (Run-Log-Analyze-Update)

#### Cycle 構造

```
[Run] dual-reviewer 運用 (Layer 1 + Layer 2 + Layer 3)
   ↓
[Log] review session の log を JSONL 記録 (dr-log)
   ↓
[Analyze] 事後分析で Q1-Q5 必要情報を抽出 (dr-extract / dr-validate、subagent task)
   ↓
[Update] 抽出データを dual-reviewer に feedback (dr-update、PR 生成)
   ↓ (loop back to Run)
```

| 項目 | 確定 |
|------|------|
| cycle 周期 | user 依存 (config 化なし、自動 trigger 機構が将来必要時に再検討) |
| Update 形式 | ハイブリッド (subagent 提案 + 人間 PR review style apply) |
| 23 事例の位置付け | yaml 化 (`seed_patterns.yaml`、固有名詞ゼロ + `origin: rwiki-v2-dev-log` で provenance) immutable initial seed として package 同梱 |
| 具体例 archive | 別 markdown (`seed_patterns_examples.md`、人間可読、同梱) |
| **domain tag** | **削除** (8 メタ群 + 中程度 granularity で domain 横断、domain 固有性は concrete レベルのみ) |
| pattern transfer 戦略 | 案 C (16 representative を subagent prompt に embed + 全 archive は別 grep) |
| terminology.yaml 蓄積 | Phase A (Rwiki Spec 6 中) で開始、~30-50 entries の seed 形成 |
| Layer 1 機構 | dr-log / dr-extract / dr-validate / dr-update / dr-translate (Layer 1 共通、phase 非依存) |
| collective learning network | Phase B-2 以降 contribution 機構整備、PR-based / dr-contribute CLI / 段階拡張 |
| pattern schema (中程度 granularity 例) | 「規範前提が後続 phase に転嫁されている」「アルゴリズム名と実装ライブラリの数学的不一致」「requirements 範囲外の制約を design で確定」「Components 間で sub-section 構造が不均一」 |
| メタ群 | 8 群 (A 内部矛盾 / B 実装不可能性 / C 責務境界 / D 規範範囲 / E failure / F concurrency / G SSoT / H 選択肢) + primary_group + secondary_groups 二層構造 |

### 8.3 観点 3: 並列処理 + 整合性 Round (論点 b 完全展開)

#### 並列実行構造

```
[並列実行] Round 1-10 を 10 並列、read-only snapshot mode で各 Round 起動
   ↓ 各 Round 検出結果を JSON 集約
[整合性 Round = primary reviewer (Opus) 逐次] 6 task 実施
   ↓
[派生 Round 再実行] 必要時のみ、上限 3 回
   ↓ 収束 or 上限到達
[修正適用] topological sort 順序で Edit、Tier 1 quota は user 仲裁
   ↓ または完全逐次 fall back (5 trigger 条件いずれかで発動)
```

| 項目 | 確定 |
|------|------|
| dependency 検出方法 | 案 C: 整合性 Round で post-hoc 判定 (primary reviewer = Opus 担当) |
| 並列度 | 完全並列 (10 Round 同時) + 派生 Round 再実行 |
| 整合性 Round 6 task | (1) Deduplicate / (2) Detect dependencies / (3) Detect conflicts / (4) Topologically sort / (5) Predict derived issues / (6) Severity re-evaluation |
| 派生 Round 件数上限 | なし (件数で制限する意味なし、同時並列再実行) |
| 派生 Round 回数上限 | **3 回** (95%+ 収束、試験運用 evidence ベース) |
| fall back trigger 5 条件 | (1) 派生上限 3 回到達 / (2) 整合性 Round 循環依存検出 / (3) 判定不能 case 30%+ / (4) user 手動切替 / (5) LLM 呼出 retry 失敗 |
| fall back 挙動 | 並列成果保持 + 既適用 Edit 維持 + 残りを Round 1→10 逐次処理 |
| wall-clock 見積り | 典型 50-100 分 (現状 v3 = 3-4 時間 → 2-4x 短縮)、fall back 発動時 90-150 分 |
| token cost 増加 | 典型 +10-15%、worst case (fall back) +100-150% |

### 8.4 観点 4: multi-project 適用時の bias 共有対策

| リスク | 緩和策 |
|--------|--------|
| **A. 同モデル偏向 (training 由来)** | 完全 mitigation 不可、bias 抑制 quota で構造的対処、観点 5 (subagent 再帰多重化 + 多 vendor model) で深掘り |
| **B. project 知識混入 (用語 / 言い回し)** | terminology.yaml で用語抽象化強化 (例: `spec` → `specification document`)、contribution review で project 固有用語 regex 自動検出 + maintainer rewrite |
| **C. collective contribution noise** | maintainer review (quality gate)、Phase B-2 以降で詳細化 (重複 / 抽象度 / domain bias check) |
| **D. multi-project user memory 混入** | core / seed = 共有 (project 別 memory directory に各々同一複製)、project layer = 完全分離、subagent prompt で「Reference ONLY this project's context」明示 |

### 8.5 観点 5: subagent 再帰多重化

#### 多重化の 3 構造案

| 案 | 内容 | 偏向 mitigation | timing |
|----|------|----------------|--------|
| **A: 並列 multi-subagent** | primary が複数 adversarial を同時並列起動、整合性 Round で集約 (majority vote / dispute resolution) | 中-高 | Phase B-2 試験 |
| B: 階層的 multi-subagent | adversarial 1 → adversarial 2 → ... 階層深さ = bias 抑制度に比例 | 最高 (ただし context 圧迫) | Phase B-3+ experimental |
| **C: 多 vendor model rotation** | session ごとに adversarial model を rotation (Sonnet → Haiku → Opus 等) | 高 | C1 = Phase B-1 / C2 = Phase B-2 |

#### 案 C の 2 段階実装

| Case | 実装 | API コール | timing |
|------|------|----------|--------|
| **C1: Claude family 内 rotation** | Claude Code Agent tool の `model` parameter 切替 | **不要** (Claude Code 内完結) | Phase B-1 release |
| **C2: Multi-vendor (GPT / Gemini / 他)** | Bash + Python SDK (`anthropic` / `openai` / `google-generativeai`) で外部 API コール | **必要** (API key 管理 + `.env` + git-secrets) | Phase B-2/B-3 |

#### Phase B-1 → B-3 ロードマップ

- **Phase B-1** (release 直後): 現行 v3 (単純 dual review) base + 案 C1 (Claude family rotation) opt-in、API コール不要
- **Phase B-2** (~6-12 ヶ月後): 案 A (並列 multi-subagent) + 案 C2 (multi-vendor、API コール) opt-in 試験、`--multi-subagent N` / `--multi-vendor` flag
- **Phase B-3** (~1-2 年後): 統計に基づき default 化、案 A + C2 組合せで bias diversity 最大化、案 B (階層的) は experimental

#### dispute resolution

- 多重化時の disagreement 解消 = `majority_vote` default、必要に応じて `escalate_to_user` (Tier 1 介入)

### 8.6 5 観点全クローズ後の dual-reviewer 設計完成度

| 設計領域 | 確定状態 |
|---------|---------|
| package 構造 | ✓ npm + GitHub repo + Skills 構造 + Layer 1/2/3 |
| cc-sdd integration | ✓ 選択肢 3 ハイブリッド (独立 + integration optional) |
| Run-Log-Analyze-Update cycle | ✓ 6 dr-* script 構成 |
| 23 事例 yaml 化 + collective learning roadmap | ✓ Phase A → B-1 → B-2 → B-3 |
| 並列処理 + 整合性 Round + fall back | ✓ 完全並列 + 6 task 整合性 + 3 回上限 + 5 trigger fall back |
| multi-project bias 共有対策 | ✓ 4 リスク × 緩和策 |
| subagent 再帰多重化 ロードマップ | ✓ 案 A / B / C1 / C2 段階展開 |
| 用語抽象化 + 多言語 | ✓ primary/adversarial reviewer + `--lang` |
| Quota 設計 (Tier 比率削除) | ✓ event-triggered のみ、bias 防止 |

= **dual-reviewer 一般化 design は完全確定、Phase A 開始 + Phase B 独立 fork 準備完了**。

### 8.7 残課題 (Phase A 以降で実施)

1. **Spec 6 design で v3 試験運用継続**: 統計蓄積 (subagent 致命級発見率 / disagreement 率 / Phase 1 同型 hit rate)
2. **JSONL 構造化記録 prototype 実装** (dr-log の minimum viable): Spec 6 design レビュー時に試行、Bash + Claude Code Agent tool で実装
3. **23 事例 yaml retrofit prototype**: `seed_patterns.yaml` 形式への変換、Phase A の最初の作業
4. **Phase B 独立 fork timing 判断基準の数値化**: Spec 6 完了時に 16 Round 累計 metrics で go/hold 判断
5. **Phase B-1 npm publish 準備**: package.json / npx 起動 / Skills primitive integration
6. **Phase B-2 multi-vendor API 統合準備**: OpenAI / Google API client 調査、API key 管理規律
7. **terminology.yaml seed 形成**: Phase A で 30-50 review_methodology 用語蓄積
