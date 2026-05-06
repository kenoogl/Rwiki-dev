---
name: req phase main 統合 + 3 req 整合性 audit プロセス
description: 11th 末 main 統合 (case A 即 merge) + V3 design phase artifact cleanup + 3 req 整合性 audit gap-list 記録の標準プロセス
type: feedback
originSessionId: 4c67776f-efa3-4a91-a1d7-36330ad3c35b
---
req phase 完走後の main 統合は (1) case A 即 merge + (2) 旧 artifact cleanup (archive で完全保全前提) + (3) 3 req 整合性 audit gap-list 記録 の 3 step を必ず実施。design phase 着手前に implementation 可能な軽微 implication を gate で capture する。

**Why:** req phase の Step 5 cross-spec review (主 implication 処理) 後でも、main 統合後の SSoT で軽微な naming overlap / install location confirmation timing / cosmetic gap が残存する。design phase 着手前に audit で顕在化させて design phase 内 fix track することで、implementation phase での scope 拡張を防止。

**Evidence (11th 末 main 統合 + 3 req audit プロセス)**:

- 11th セッション末: req phase V4 redo broad 3 spec approve (`b6b850c`、worktree branch) → case A 即 merge `git merge --no-ff v4-redo-broad` で main 統合 (`bcd604f`)
- conflict 解消: 全 10 file (3 spec brief + 3 req + 3 spec.json + draft) で v4-redo-broad 版採用 (`--theirs`)
- V3 design phase artifact cleanup: foundation/design.md (896 行) + foundation/research.md + dual-reviewer-design-phase-defer-list.md 削除 (archive branch + tag で完全保全済)
- evidence-catalog 起草 (本 process 起源 = file 削除 + archive 操作 + session 末 TODO 更新時の追記漏れ確認の運用規律)
- 3 req 整合性 audit 実施 → 主要 contract 整合 OK + soft gap 4 件 (G1-G4) 識別:
  - G1: `source` field naming overlap (semantic、design phase で対応 = foundation Decision 2 で解決)
  - G2: `judgment_reviewer` vs `judgment subagent` 用語揺れ (cosmetic、並列容認)
  - G3: foundation install location 確定 timing (semantic、foundation design phase で確定 = scripts/dual_reviewer_prototype/ で解決)
  - G4: relative path canonical form (`patterns/` vs `./patterns/`、cosmetic)
- 12th 末: G1+G3 design phase 解決済、G2+G4 cosmetic 残

**How to apply:**

## req phase main 統合 3 step

### Step 1: case A 即 merge (worktree branch → main)

- `git merge --no-ff <feature-branch>` で fast-forward 禁止 merge
- conflict 発生時の戦略を sessionで明確化 (= 通常 `--theirs` で feature branch 版採用、main 側 evidence 必要なら `--ours`)
- merge 後の commit message: "Merge branch '<feature>' into main: <description>"

### Step 2: 旧 artifact cleanup (archive 完全保全前提)

- 旧 phase artifact (= V3 design phase など旧 V4 整合化前の docs) を main から削除
- 削除 file は archive branch + (optional) tag で完全保全済 = origin push 済も確認
- cleanup commit message: "chore(<spec>): <旧 era> artifact cleanup + <new artifact> 起草"
- evidence-catalog.md / data-acquisition-plan.md など連動更新も同 commit に含める

### Step 3: 整合性 audit (= 3 req / 3 spec / 全 spec horizonal review)

20 観点で integrity check:
- contract 主要構造 (3 subagent 構成 / 4 skills 責務分離 / Step A/B/C/D / 共通 schema 2 軸並列 / Adjacent expectations 双方向 / Phase A scope vs B-1.x demarcation / escalate mapping / dogfeeding 5 条件 / cross-spec reference 実存性 等)
- naming overlap (= 同名 field が複数 階層に存在しないか、disambiguate 必要か)
- install location 確定 timing (= 委任先 spec とのconsistency)
- relative path canonical form (`./` prefix 統一)
- 用語抽象化 (role 抽象名 vs 具体 name)

audit 結果を gap-list として記録:
- 主要 contract 整合 OK (= verified) を明示
- Soft gap (cosmetic / 軽微 semantic、blocking なし) を G1, G2, ... として列挙
- 各 gap に対応 timing (design phase / 自然修正 / Phase A 終端 cleanup) 明示
- 判断: 軽微 gap で blocking なし = req phase 改訂せず gap-list で track して design phase で対応

audit gap-list 配置: `.kiro/methodology/v4-validation/evidence-catalog.md` §3.9 etc に記録 (= 本 dual-reviewer の場合)

## 「軽微 gap は req phase 改訂せず design phase で対応」判断基準

- gap が **既存 AC 違反** = req phase 改訂必須
- gap が **既存 AC 範囲内の cosmetic / semantic 補強** = design phase で track 対応
- gap が **新規 AC 追加要請** = req phase 改訂 (scope 拡張 = user 判断要)

## 関連 reference

- evidence-catalog.md §3.9 (本 audit gap-list 12th 末 = 3 件 design phase 解決済 + 1 件 cosmetic 残)
- 関連 memory: `feedback_review_v4_necessity_judgment.md` (V4 protocol 構造) / `feedback_v4_redo_lessons.md` (V4 redo 教訓) / `feedback_cross_spec_review_pattern.md` (design phase 完走後 cross-spec review pattern、本 audit pattern と類似 + Group 分類で extension)
