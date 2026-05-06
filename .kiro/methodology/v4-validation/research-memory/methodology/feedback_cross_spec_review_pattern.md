---
name: phase 完走後 cross-spec review = Group A/B/C 3 分類 pattern (design + tasks 2 phase 適用済)
description: 3 spec 累計 phase 完走後 (design or tasks) の cross-spec review で 20 観点 integrity check + Group A (確認済整合) / B (既存対応済) / C (新規 implication) 3 分類で structured review、Group C apply で完走する pattern (12th 末 design phase + 14th 末 tasks phase 累計適用)
type: feedback
originSessionId: 4c67776f-efa3-4a91-a1d7-36330ad3c35b
---
3 spec 累計 phase 完走後 (= req phase Step 5 cross-spec review に対応する後続 phase 版)、20 観点 integrity check を実施し、結果を Group A (確認済整合) / B (既存対応済) / C (新規 implication) の 3 分類で structured review。Group C 軽微 implication は全 apply で完走、不整合 0 件確認で 3 spec phase 終端確立。**12th 末 design phase + 14th 末 tasks phase = 2 phase 累計適用、両 phase で不整合 0 件 = pattern 安定性確認**。

**Why:** req phase Step 5 cross-spec review (10th セッション、12 implication 全処理) のように、design phase でも spec 間の contract integrity (= consumer-driven contract / revalidation triggers / install location resolve mechanism / phase 解釈) は 3 spec 累計で再 check が必要。各 spec design phase 内では visible だが、3 spec 横断で見ると軽微 implication が残存する (= 各 spec が独立に design されたが cross reference 整合は別途 check 必要)。

**Evidence (12th 末 design phase cross-spec review 適用)**:

3 spec design phase 完走 (foundation v1.1 + design-review v1.1 + dogfeeding v1.2) 後、20 観点 integrity check 実施:

- **Group A 確認済整合 (6 件)**: install location / relative path canonical form / source field 2 階層 disambiguate / V4 §5.2 prompt sync / skill format 統一 / 3 系統対応 = 各 spec design 内で確定済
- **Group B 既存対応済 (11 件)**: design-review revalidation pending / counter_evidence decompose 整合 / dr-log session lifecycle 整合 / 8 月 timeline + Spec 6 commit hash variance / forced_divergence prompt 利用 / Phase A scope constraints 統一 / A-1 解釈 / treatment flag = revalidation trigger / SSoT chain 1-hop / req phase Step 5 12 件処理済 = req phase Step 5 + 各 spec design phase 内 fix で対応済
- **Group C 新規 implication (3 件)**:
  - C1: design-review/design.md Revalidation Triggers section に dogfeeding 要請 3 件 (treatment flag / timestamp / commit_hash) 反映 (v1.2-prep)
  - C2: dogfeeding 3 Python script に foundation install location resolve mechanism 注記 (`--dual-reviewer-root` flag or `DUAL_REVIEWER_ROOT` env var)
  - C3: dogfeeding/design.md Decision 7 追加 = foundation Decision 5 (A-1 = design+impl 一体) の dogfeeding 適用解釈明示 (Python script 実装 = A-1 内 / Spec 6 適用 = A-2)
- **不整合 0 件**

user 判断 = 全 apply (A 採択) で 3 件 design.md 反映、cross-spec review 通過 → dogfeeding approve commit + cross-spec review C1-C3 fix 統合 commit (`aa40934`)。

**Evidence (14th 末 tasks phase cross-spec review 適用)**:

3 spec tasks phase 完走 (foundation v1.1 + design-review v1.1 + dogfeeding v1.1、各 V4 ad-hoc review apply 済) 後、20 観点 integrity check 実施:

- **Group A 確認済整合 (17 件)**: install location 統一 / resolve mechanism (CLI flag + env fallback) / cross-file `$ref` resolver foundation Task 7.5 集約 / Consumer 拡張 4 field / Severity 4 水準 / Python 3.10+ + 2 スペースインデント / Phase A scope constraints / Decision 7 解釈 / sample 1 round 通過 test / 3 系統対照実験 treatment flag / 8 月 timeline failure 基準 / Phase B fork 5 条件 / bilingual heading 適用範囲 / frontmatter 規約 / tasks-phase ad-hoc V4 caveat 4 件 / dispatch payload 構造 / forced_divergence vs fix-negation 役割分離 = 各 spec tasks 内で確定済 (design phase 6 件から大幅増 = tasks phase で各 spec が consumer-driven contract 整合確認に厚め)
- **Group B 既存対応済 (2 件)**: design-review v1.2 revalidation cycle 3 改修要件 (3 spec で適切に対応済) / TDD 規律 (各 spec で別 representation だが intent 一致) = 3 spec 累計で重複対応なし
- **Group C 新規 implication (1 件)**:
  - C-1: foundation tasks Task 1 に `jsonschema>=4.18` version pin 同期適用 (= design-review tasks v1.1 P6 apply の cross-spec implication、Task 7.5 cross-file `$ref` resolver で `Registry` 必須)
- **不整合 0 件**

user 判断 = 全 apply (a 採択) で 1 件 foundation/tasks.md v1.2 反映、cross-spec review 通過 → 3 spec approve commit (`021ec65`) で 1 commit 一括統合。

**2 phase 比較 (Group 分布)**:
- design phase = Group A 6 / B 11 / C 3 (= 各 spec 内で contract integrity 部分確定、3 spec 横断で軽微 implication 残)
- tasks phase = Group A 17 / B 2 / C 1 (= design phase で確定した contract integrity が tasks phase で広く再確認、Group C は version pin 同期のみ)
- 両 phase で 不整合 0 件、Group C 軽微 implication 全 apply で完走 = pattern 安定性確認

**How to apply:**

## 20 観点 integrity check (各 spec の design phase 完走後)

各 spec design 内では visible でも、3 spec 累計で再 check が必要な観点:

1. install location 規約整合 (foundation install location = consumer relative path 規約整合)
2. relative path canonical form (`./` prefix 統一)
3. naming overlap (例: source field 2 階層 disambiguate)
4. SSoT sync mechanism (例: V4 §5.2 prompt header 3 行 manual sync)
5. forced_divergence prompt 利用 (3 spec 横断 reference)
6. skill format 統一 (SKILL.md + Python helper)
7. 3 系統対応 (single/dual/dual+judgment、treatment flag + state field + source field の組合せ)
8. consumer 拡張 mechanism 整合 (foundation Req 3.6 = additionalProperties: true)
9. JSONL append target path resolution (config.yaml dev_log_path 動的読込)
10. attach contract 3 要素 (location 規約 + identifier + 失敗 signal、Layer 2/3 共通)
11. override 階層 (Layer 3 > Layer 2 > Layer 1)
12. Phase A scope constraints (3 spec で統一)
13. 3 系統 step 構成異なる (single = A only / dual = A+B / dual+judgment = A+B+C+D)
14. seed_patterns mapping (foundation A4 type、各 spec で placeholder strategy 整合)
15. Severity 4 水準 (foundation Req 3 AC3 + steering tech.md、3 spec 整合)
16. cross-spec contract reference (各 spec の Allowed Dependencies SSoT chain 1-hop 限定)
17. revalidation triggers 双方向 (downstream → upstream への要請が upstream に反映されているか)
18. Phase B fork judgment (5 条件 + go/hold + comparison-report append)
19. timestamp + commit_hash payload (consumer-driven contract、design-review revalidation 要請)
20. 8 月 timeline failure 基準 (figure data 完了基準、各 spec 整合)

## Group A/B/C 3 分類 pattern

Check 結果を以下に分類:

- **Group A 確認済整合**: 各 spec design 内で既に確定済、3 spec 横断で整合確認 → no-op
- **Group B 既存対応済**: req phase Step 5 cross-spec review or 各 spec design phase 内 fix で対応済 → no-op (記録のみ)
- **Group C 新規 implication**: 3 spec 横断 review で初めて顕在化した implication → 各 spec design 軽微追記 で apply
- **不整合**: 各 spec の AC 違反 / 実装不可能性 → req phase 改訂 or design phase 再 review (= blocking)

通常: Group A + B が大部分 (12th 末 = 17 件)、Group C 少数 (12th 末 = 3 件)、不整合 0 件。Group C 全 apply で cross-spec review 通過。

## Group C apply 規律

- 各 implication は **fix_cost low** (1 段落〜数行追記レベル) であること
- 修正対象は 各 spec design.md / research.md (新規 spec 化禁止 = 既存 spec 内追記)
- user 判断 3 択 (全 apply / 個別 review / Group A+B 確認のみ skip Group C) で進行

## Cross-spec review 実施 timing

- 3 spec 累計 design phase 完走時 (= 各 spec の最後 spec の design approve 直前)
- req phase 完走時 (= Step 5 cross-spec review、本 pattern の前段)
- A-2 終端時 (= dogfeeding 完走後の最終 comparison-report 集計時)、Phase A 終端 integrity check

## 関連 reference

- 12th 末 cross-spec review 結果: dogfeeding/research.md v1.0 + dogfeeding/design.md v1.2 Change Log + foundation/design.md + design-review/design.md v1.2-prep
- req phase Step 5 cross-spec review (10th、12 implication 処理): `feedback_main_merge_3req_audit.md` audit gap-list 整合
- 関連 memory: `feedback_main_merge_3req_audit.md` (req phase 後 audit、本 pattern の前段) / `feedback_review_rounds.md` (第 5 ラウンド規範 = Foundation 改版時の傘下 spec 精査必須、本 pattern と整合) / `feedback_v4_design_phase_3spec_completion.md` (3 spec design phase 連続完走 evidence)
