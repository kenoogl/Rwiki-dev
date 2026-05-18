# 設計逆方向トレース監査（design → requirements）

- 監査日：2026-05-18
- 対象 feature：`dual-reviewer-implementation-governance`
- 監査種別：設計→要件の逆方向トレース（孤児・陳腐・矛盾の検出）
- 監査人：独立設計トレース監査人（起草者と独立）
- 入力正本：
  - 要件正本：`.kiro/specs/dual-reviewer-implementation-governance/requirements.md`（Requirement 1〜9）
  - 監査対象：同 spec `design.md` 全節・全小節
  - 補助：`intent/INTENT.md`、`CONVENTIONS.md`、`docs/coordination/workflow-repair-procedure.md`、`operations/WORKFLOW_OVERVIEW.md`
- 生証跡（不変）。`design.md` / `requirements.md` / `spec.json` は変更しない。

---

## 1. 現行要件 AC 全件リスト

削除済み要件：**なし**（spec.json・requirements.md とも Requirement 1〜9 が現行。過去削除を示す痕跡なし）。

- Requirement 1（Post-Implementation Conformance Review）：AC1 conformance review を必須段として定義 / AC2 review focus（spec conformance・boundary・evidence traceability）/ AC3 実行タイミング（prototype 完了・pre-push/PR・trust boundary 等変更後）/ AC4 finding 0 か disposition 付きでなければ未閉鎖。
- Requirement 2（Review Artifact and Finding Contract）：AC1 review artifact の canonical location（repo 内 review dir）/ AC2 最小内容集合（scope・commit/branch・rerun summary・findings・severity・recommended action・disposition）/ AC3 severity class（critical 区別）/ AC4 open finding は signal register か coordination log にリンク / AC5 再利用 review template。
- Requirement 3（Conformance Metric Register）：AC1 canonical metric register / AC2 最小 metric 群（finding count・severity-weighted・post-smoke nonconformance・fixture-bound resolution・heuristic linkage・artifact presence rate）/ AC3 各 metric の意味・収集時点・解釈 / AC4 manual snapshot 許容。
- Requirement 4（Signal and Handback Integration）：AC1 finding→`implementation-signal-register` 写像 / AC2 handback class A/B/C/intent との関係 / AC3 trust boundary 等の未解決 finding を黙殺しない / AC4 implementation-only fix と reopen 要 finding の区別保存。
- Requirement 5（Governance Artifact Validation）：AC1 repo 内 validation entrypoint / AC2 必須 governance 文書・review template の存在検査 / AC3 review artifact の必須 section・metric key 検査 / AC4 entrypoint を通る具体 review artifact 1 件以上。
- Requirement 6（Workflow Gate Status and Cross-Spec Alignment）：AC1 多 feature completion 変更時 cross-spec alignment review 必須 / AC2 workflow gate status artifact / AC3 `completed` と `completed_with_open_findings` 区別 / AC4 spec.json に alignment 要否・完了反映 / AC5 intent-triggered reopen propagation。
- Requirement 7（Intent Review and Phase-Review Metrics）：AC1 `intent review` を first-class review 段に / AC2 intent review template + 具体 artifact / AC3 `intent_revision_count`・`intent_handback_count` / AC4 downstream の `intent-attributed` 記録（再分類しない）/ AC5 phase-review metric register（intent/requirements/design/tasks/implementation）/ AC6 validator が intent template・具体 artifact・phase-review register を検査 / AC7 phase-review 語彙（implementation 含む）は governance 所有、runtime phase/profile と別物。
- Requirement 8（Reference-Free Case Bootstrap and Minimal Heuristic Policy）：AC1 reference-free bootstrap を first-class entry に / AC2 repo 内 bootstrap artifact/script で最小 case-control artifact 生成 / AC3 template・gate 構造は再利用可、case content は供給文書から起こす（pilot copy 禁止）/ AC4 minimal heuristic policy（`heuristic_profile_ref` 省略可、track 別最小 template 既定）/ AC5 bootstrap guide・script・protocol/snapshot template・heuristic policy note・track 別最小 template の canonical reference / AC6 v2-acquisition を heuristic-default の canonical owner とし、AC4/AC5 参照は従属、語彙確定まで governance validator は heuristic template を必須検査しない。
- Requirement 9（Workflow Execution Ledger and Compliance Enforcement）：AC1 各 prescribed workflow process 着手前に正本から新規導出した執行台帳 / AC2 台帳各段に stage name・SoT citation・evidence ベース completion predicate・independence requirement / AC3 completion predicate は artifact 存在＋構造適合（主張不可）/ AC4 横断/横段 alignment 段は author 独立プロセス生成＋台帳に independent-production marker / AC5 Requirement 5 entrypoint の上位集合として独立再導出（台帳生成と非共有）し欠落段を failure / AC6 不可逆操作（spec.json approval/phase 書込・不可逆状態変更・人間承認依頼生成）で enforcement point block / AC7 全 process に例外なく一様適用 / AC8 人間承認依頼に台帳突合表を埋め込み / AC9 reopen-propagation・cross-spec-alignment 義務を保存、`workflow-repair-procedure.md` 等を同期 / AC10 各 process の段集合権威ソースは単一かつ明示指定（単一権威性は要件不変条件）/ AC11 validator/独立再導出/台帳が確定的 pass を出せない状態は fail-closed。

---

## 2. design.md 節・小節ごとの 3 区分判定

総数：**26 単位**（主要節 + 小節を計上）。区分＝traceable / orphan / stale-conflict。

| # | design.md 所在 | 紐づく現行 AC または正当根拠 | 区分 |
|---|---|---|---|
| 1 | Overview（所有物列挙 = repo-contained artifact 固定方針）| R5-AC2, R7-AC2/AC6, R8-AC5, R9-AC1（所有 artifact 全体像）+ INTENT 4.1 repo-contained | traceable |
| 2 | Goals | R1-AC1, R2 全体, R3-AC1, R4-AC1, R5-AC1 + INTENT 4.3 可観測 | traceable |
| 3 | Non-Goals | Boundary Context Out of scope + INTENT 9（最適化しない範囲）| traceable |
| 4 | Design Drivers | R1（smoke 後 nonconformance）, R4（silent weakening 不可）, R5（mechanical validation）, R4-AC1（既存 log/register 再利用）| traceable |
| 5 | Architecture（data producer 追加せず post-stage gate）| R1-AC1 + INTENT 11.1/Boundary（ownership 不変）| traceable |
| 6 | Owned Artifacts（既存分、Req1〜8）| R5-AC2, R7-AC2/AC6, R8-AC5（各 artifact 名が個別 AC に対応）| traceable |
| 7 | Review Template Required Sections | R2-AC2/AC5, R7-AC2, R5-AC3 + `type` 判別は AC3 検査の設計判断 | traceable |
| 8 | Boundary Clarification | R1-AC1, R6, Boundary Context + INTENT 11 | traceable |
| 9 | Workflow Model / Stage -1（Reference-Free Case Bootstrap）| R8-AC1/AC2/AC3 | traceable |
| 10 | Stage 0（Intent Review）| R7-AC1/AC3/AC4 | traceable |
| 11 | Minimal Heuristic Default Rule | R8-AC4/AC6 | traceable |
| 12 | Stage 1（Implementation）| R1-AC1（段の連鎖上の位置づけ）| traceable |
| 13 | Stage 2（Relevant Smoke Validation）| R1-AC1（smoke validation 段）| traceable |
| 14 | Stage 3（Implementation Conformance Review）| R1-AC1/AC2/AC3, R2-AC2, R3, R4-AC1 | traceable |
| 15 | Stage 4（Checkpoint Close、P1 open 扱い含む）| R1-AC4 + P1 ブロックは R4-AC3 の設計判断 | traceable |
| 16 | Workflow Status Model（5 状態）| R6-AC3（`completed`/`completed_with_open_findings` 区別。他 3 状態は遷移表現の設計判断）| traceable |
| 17 | Cross-Spec Alignment Model | R6-AC1/AC2/AC4 | traceable |
| 18 | Reopen Propagation Model | R6-AC5 + workflow-repair-procedure 3 章状態遷移表 | traceable |
| 19 | Finding Model（P1/P2/P3 + 属性）| R2-AC2/AC3 | traceable |
| 20 | Finding → Signal Register Mapping | R4-AC1/AC2/AC3 | traceable |
| 21 | Handback Model（A/B/C/D）| R4-AC2/AC4 + workflow-repair-procedure 2 章 | traceable |
| 22 | Metric Model（baseline + phase-review）| R3-AC2/AC3/AC4, R7-AC3/AC5/AC7 | traceable |
| 23 | Validation Model | R5-AC2/AC3, R7-AC6 | traceable |
| 24 | Workflow Execution Ledger and Enforcement Model（導入文 + Owned Artifacts 追加分 + 小節 1〜1.3）| R9-AC1/AC2/AC5/AC10/AC11 | traceable |
| 25 | 同 小節 2〜5（Completion Predicate / Independence / Enforcement Point / Uniform Application）| R9-AC3/AC4/AC6/AC7/AC8/AC9/AC11 | traceable |
| 26 | 同 小節 6〜10（上位文書同期 / Validation 拡張 / Boundary / テスト戦略 / 移行戦略）| R9-AC5/AC9 + 横断整合ゲート C 群決定 + R9-AC11 fail-closed | traceable |

### 重点確認項目（手順 3）の結果

- (a) 旧 v1 由来パターン資産・heuristic の取り残し：design.md に v1 パターン件数固定（主役 1〜2 等）・heuristic 規則資産を温存する記述は **なし**。Minimal Heuristic Default Rule は逆に増殖抑制・最小 default 方向で INTENT 2.1/4.7 と整合。取り残しなし。
- (b) Requirement 8（reference-free bootstrap・最小 heuristic、v2-acquisition 所有従属）と Workflow Model：Stage -1 と Minimal Heuristic Default Rule が R8-AC1〜AC6 を過不足なく反映。小節中で「canonical owner は v2-acquisition、governance は参照のみ・語彙確定まで必須検査しない」と R8-AC6 を明示。整合。
- (c) セッション 7/8 差分で要件変更されたのに設計に残った記述：要件側は R1〜8 が現行で削除なし。設計の Req1〜8 部分に現行要件と乖離する記述は検出されず。
- (d) Requirement 9 差分追加による既存節との二重・矛盾：下記 stale/conflict 候補 S-1（Validation Model と Validation Model 拡張の関係）を要確認として所見化。明確な矛盾ではなく軽微。
- (e) Owned Artifacts に現行要件で不要な artifact：全 artifact が R5/R7/R8/R9 のいずれかに対応。不要 artifact なし。

---

## 3. orphan / stale-conflict 所見

### 区分集計

- traceable：**26 / 26 単位**
- orphan（孤児）：**0 件**
- stale/conflict：**1 件（軽微・S-1）**

「孤児なし」を明示記録する（後で見落とし誤認されないため）。design.md の全節・全小節は現行要件 AC または intent/上位文書由来の正当な設計判断に紐づき、どの現行要件にも正当な設計判断にも紐づかない記述（過去要件削除の取り残し）は検出されなかった。

### S-1（stale/conflict・軽微）

- 所在：design.md「Validation Model」節（350〜364 行）と「Workflow Execution Ledger and Enforcement Model」小節 7「Validation Model 拡張」（438〜442 行）。
- 問題：本体「Validation Model」節は Requirement 9 追加前に書かれた既存 8 項目の確認リストで、Requirement 9 で validator は AC5 の独立再導出を含む上位集合に拡張された。小節 7 が「既存 Validation Model の確認項目に加え」と上位集合宣言で接続しており、要件矛盾ではない。ただし本体節を単独で読むと R9-AC5 の検査範囲（台帳・独立再導出・provenance）が見えず、Requirement 9 追従前の前提のまま読める形になっている。陳腐化矛盾ではなく「差分追従で本体節が更新されず小節側に追記された」構造的二層化。
- 根拠：R5-AC1〜AC3 は本体 Validation Model で充足、R9-AC5 は小節 7 で充足。両者は上位集合関係が小節 7 で明記され実体矛盾なし。よって致命/重要ではない。
- 推奨対応：**要件側正当化は不要**（要件と矛盾しない）。設計内の可読性向上として、本体「Validation Model」節に小節 7 への前方参照（「Requirement 9 による拡張は小節 7 を参照」の 1 行）を加えるのが望ましいが、必須ではない。**修正（任意・利用者判断）**。差分追従設計では既存節を不変保持し新節で上位集合化する方針は spec.json design note の宣言（「既存 Requirement 1〜8 の設計は不変」）と一貫しているため、現状維持も正当。
- 重大度：**軽微**（冗長だが無害。実装矛盾なし）。
- 必要性判定：除去対象ではない。本体節も小節 7 も現行要件に紐づき両方必要。二層化は差分追従設計の意図的帰結であり、orphan ではない。

---

## 4. 総合所見

- design.md 全 26 単位は現行要件 Requirement 1〜9 の AC、または intent/上位運用文書（INTENT.md、CONVENTIONS.md、workflow-repair-procedure.md、横断整合ゲート C 群決定）由来の正当な設計判断に紐づく。
- **孤児（orphan）：0 件**。過去要件の削除・変更で取り残された余計な設計記述は検出されなかった。削除済み要件も存在しない。
- **陳腐・矛盾（stale/conflict）：1 件（S-1、軽微、修正は任意・利用者判断）**。現行要件との実装矛盾はなく、Validation Model 本体節と Req9 小節 7 の二層化（差分追従設計の意図的帰結）に起因する可読性上の冗長のみ。致命・重要はゼロ。
- 旧 v1 パターン資産・heuristic 取り残し（重点 a）、Requirement 8 と Workflow Model 整合（重点 b）、セッション 7/8 要件変更の取り残し（重点 c）、Requirement 9 と既存節の二重・矛盾（重点 d）、Owned Artifacts の不要 artifact（重点 e）は、いずれも問題なし（d のみ軽微 S-1 を記録）。
- 現行要件と設計は逆方向で過不足なく対応する。設計側に余計物（孤児）はない。S-1 は軽微かつ任意修正であり、設計の正当性・完全性を損なわない。
- 結論：本逆方向監査の観点では design.md は健全。タスク個別レビュー（節 5 の 7 観点）へ進んでよい。S-1 は任意改善として後段で扱えば足り、設計差し戻しは不要。

---

## 5. 証跡パス

- 本監査証跡：`.kiro/specs/dual-reviewer-implementation-governance/reviews/design-reverse-trace-audit-2026-05-18.md`（本ファイル、不変）
- 参照（鵜呑みにせず独立判断）：`reviews/requirements-local-review-2026-05-18.md`、`reviews/design-local-review-2026-05-18.md`
