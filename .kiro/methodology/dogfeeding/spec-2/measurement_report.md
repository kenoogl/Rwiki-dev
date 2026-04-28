# Design Review v2 Dogfeeding 計測 Report (Spec 2)

> 旧方式 (10 ラウンド本質的レビュー) Spec 5 結果と新方式 (5 種機械検証) Spec 2 結果の比較計測

## サマリ

**新方式の dogfeeding は技術的には完走、ただし risk_level = D (人間判断必須) で着地。** 主因は Phase 2-B uncovered requirements 22 件 ERROR で、これは「design.parent_specs の granularity 不足」という本物の検出。Phase 2-E (LLM 意味的ドリフト) は 0 件、構造検査のみで人間判断 trigger を引けることを示した。

## 計測表 (Spec 5 旧方式 vs Spec 2 新方式)

- **検出件数**:
  - Spec 5 旧方式 = 18 件 (重要級 7 + 軽微 6 + 本質的 5)、累計 Edit 18 件
  - Spec 2 新方式 = 33 件 (ERROR 22 + WARN 11、drift 0)
- **採用件数 / 採用率**:
  - Spec 5 旧方式 = 18/18 全件採用 (100%)、すべて design 改版で吸収
  - Spec 2 新方式 = 未採用 (本セッションは dogfeeding のみ、採用判断は user 委ね)
- **LLM 呼出回数**:
  - Spec 5 旧方式 = ~30 回 (10 ラウンド × Step 1a/1b/1b-v 内検査)
  - Spec 2 新方式 = 2 回 (Phase 1 メタデータ抽出 + Phase 2-E 意味的ドリフト)
  - 削減率 = 約 93%
- **所要時間**:
  - Spec 5 旧方式 = 数セッション (Round 1-10 + 本質的レビュー)
  - Spec 2 新方式 = 1 セッション内完了 (Phase 1 抽出 + Phase 2 script 実装 + Phase 2-E 判定 + Phase 3 採点)
- **risk_level 判定**:
  - Spec 5 旧方式 = approve 確定 (commit `abea6f3`)
  - Spec 2 新方式 = D (人間判断必須)、理由 = ERROR 22 件 (Phase 2-B B-2 uncovered)
- **検出種別**:
  - Spec 5 旧方式 = sub-section 欠落 / API signature 乖離 / 規範前提曖昧化 / Skill 1 module 集約 1500 行制約超過 等の構造的観点 + 本質的観点 5 種
  - Spec 2 新方式 = 構造 (A) / トレーサビリティ (B) / 型 (C) / リスクパターン (D) / 意味的ドリフト (E) の 5 軸機械検証

## Spec 2 新方式の検出内訳 (詳細)

- **Phase 2-A 構造**: 39/39 = 1.000 (検出 0)
- **Phase 2-B トレーサビリティ**: 154/180 = 0.856
  - **B-2 ERROR 22 件 (uncovered requirements)**: design.parent_specs に列挙されない AC = R2.1, R2.2, R2.5, R3.1, R3.2, R3.5, R3.6, R6.2, R6.3, R6.4, R10.1, R10.2, R10.3, R13.6, R13.7, R14.1, R14.2, R14.3, R14.4, R14.5, R14.6, R15.2 (22 件)
  - **B-3 WARN 4 件 (uncovered design)**: data_model 4 種 (extraction_output_schema / dialogue_log_frontmatter / diff_marker_attribute / skill_candidate_frontmatter) に test 紐付けなし → data model なので test 紐付けは概念的に薄い、本物の改善余地は低い
- **Phase 2-C 型**: 24/24 = 1.000 (検出 0)
- **Phase 2-D リスクパターン**: 35/42 = 0.833
  - **D-1 WARN 7 件 (responsibilities ≥ 3)**: 全 7 design_unit にヒット、boundary 3 が低すぎる可能性
- **Phase 2-E 意味的ドリフト**: 0/48 = 1.000 (drift 0、no_drift 48)

## 検出の真贋分析 (false positive 率推定)

- **B-2 ERROR 22 件 (uncovered requirements)**:
  - **真**: design.parent_specs が AC 単位で列挙されていない部分は確かに traceability 欠落。R14 (Foundation 規範準拠) は cross-cutting 性質で個別 component 紐付けが薄いのは妥当な側面もあるが、design 改善余地として記録に値する
  - **偽**: design.md 本文では Requirements Traceability table で範囲表現 "R1.1-1.5" を使用、metadata 抽出ルール「明示 AC ID のみ」で展開しなかったことが直接原因。granularity ルール調整で減らせる
  - 推定: 22 件中 8-10 件は真の改善余地、残り 12-14 件は granularity ルール由来の偽
- **B-3 WARN 4 件 (uncovered design)**:
  - **偽が大半**: data_model に test 紐付けが必要かは設計哲学次第。本 spec では data model = schema 固定なので unit test 不要、validator 経由で test される
  - 推定: 4 件中 0-1 件のみ真
- **D-1 WARN 7 件 (responsibilities ≥ 3)**:
  - **偽が大半**: boundary 3 が低すぎ、現実の component は 3-7 個の responsibilities を持つのが標準
  - 推定: 7 件中 0-1 件のみ真、boundary 5+ または 7+ への上方修正が妥当
- **Phase 2-E drift 0 件**:
  - **真**: design.md は requirements を忠実に実装、明示的な意味的ドリフトはない (Spec 5 旧方式の本質的レビューでも drift は検出されず、Spec 2 でも整合)
  - 推定: false negative 率は低 (drift がないという判定は妥当)

## 計測結果からの示唆

- **新方式の核心メリット (LLM 呼出削減 93%)**: 大規模に有効、Phase 2-A〜D の機械検証が低コストで構造観点を網羅
- **新方式の弱点 1 (granularity 過敏)**: B-2 / D-1 の boundary が現実より厳しく、false positive 率が高め (推定 50-70%)。boundary 調整 (Phase 3 の weight / boundary 設定) が必要
- **新方式の弱点 2 (本質的観点の検出力)**: Spec 5 旧方式が検出した「本質的厳しいレビュー 5 件」(規範範囲先取り / 構造的不均一 / 文書 vs 実装不整合 / 規範前提曖昧化 / 単純誤記 grep) のような検出は Phase 2-A〜D では構造的にカバーされない。Phase 2-E の drift detection も「意図と振る舞いのズレ」のみで、より深い欠陥 (例: 設計が暗黙前提を抱えている) は検出できない可能性
- **新方式の強み 1 (再現性)**: Python script + 固定プロンプトで決定論的、レビュアー差・セッション差を最小化
- **新方式の強み 2 (採点による gradation)**: approve/reject の二値ではなく risk_level (A/B/C/D) + composite_score で「どこまで人間判断が要るか」が明確

## Boundary / Weight 調整提案 (次回 dogfeeding 用)

- **D-1 boundary**: 3 → 5 または 7 に上方修正 (現実の design では 3-7 が標準)
- **B-2 granularity ルール追加**: design.md の Requirements Traceability table での範囲表現 ("1.1-1.5") を metadata 抽出時に展開するか、または Phase 1 プロンプトで「範囲表現を AC 単位に展開する」を明示
- **B-3 type=data_model 除外**: data_model kind は test 紐付け check 対象外とする (Phase 2-A 構造側の A-5 は既に component 限定)
- **risk_level 判定強化**: Phase 2-B の uncovered requirement の閾値判定を入れる (例: uncovered 率 30% 以下なら C、30% 以上なら D)、現状は ERROR 1 件で D 直行

## 判断基準 (新方式継続 vs 旧方式併用 vs 旧方式回帰)

- **新方式継続が妥当**: LLM 呼出 93% 削減 + 1 セッション内完了 + 構造 + drift 5 軸網羅という効率性は決定的
- **ただし旧方式 (10 ラウンド本質的レビュー) は補完用に保持**: 致命的な再設計が必要なケース (例: 設計の根本的な責務分離ミス、Spec 5 で検出したような「本質的観点 5 種」の深い検出) は新方式でカバーしきれない。次々セッションで Spec 1 や Spec 6 design に新方式を試行して、検出力が許容範囲か追加検証
- **次セッション以降の改善項目**:
  1. boundary / weight の上方修正適用 (D-1 boundary 5+ / B-3 data_model 除外)
  2. 範囲表現展開ルールを Phase 1 プロンプトに追加
  3. Phase 2-B の uncovered 率閾値判定を Phase 3 採点に追加
  4. 新方式を別 spec (Spec 1 design 等) に再適用して検出力比較

## Artifacts

- `design_metadata.yaml` (Phase 1 出力、328 行、design_units 7 + requirements_index 83 + cross_references 24)
- `phase2_findings.yaml` (Phase 2-A〜D 出力、findings 22+11+0+7=40 件)
- `drift_input.yaml` (Phase 2-E 入力、constraints 62 + pairs 48)
- `drift_findings.yaml` (Phase 2-E 出力、48 ペア全 no_drift)
- `review_report.yaml` (Phase 3 統合、composite_score 0.9150 + risk_level D)
- `measurement_report.md` (本 file、Spec 5 vs Spec 2 比較計測)

---

_計測日: 2026-04-28_
_次の判断: user 確認後に次々セッションで boundary 調整 + Spec 1 design 再試行で検出力比較_
