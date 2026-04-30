# dual-reviewer Design Phase Defer List

_生成: 2026-04-30、req approve 直前 gate (V3 5 ラウンド + cross-spec + 単独 audit + 3 観点追加 audit 完走後)_

dual-reviewer 3 spec (foundation / design-review / dogfeeding) の requirements で「design phase で確定」と defer した事項を集約。design phase 開始時に本 list を参照し、design.md 策定中に各事項を解決する。

合計 **38 defer 事項** (foundation 10 / design-review 18 / dogfeeding 10)。

---

## foundation (10 件)

| # | Req AC | defer 内容 | 確定方針候補 |
|---|--------|-----------|-------------|
| F-1 | Req 1 AC 1 | Step A/B/C 構造の具体提供 form (関数 / class / config / yaml / markdown) | yaml / markdown 推奨 (portable) |
| F-2 | Req 1 AC 3 | pattern schema primary_group の数 / secondary_groups の種類数 | 23 事例 retrofit 結果から逆算 |
| F-3 | Req 2 AC 3 | Layer 3 placeholder の `.gitignore` 更新方針 | project repo 内 .gitignore 追記方針推奨 |
| F-4 | Req 2 AC 4 | `config.yaml` schema 非互換改版 (upgrade scenario) の挙動 | Phase A scope = single version、本 spec では skip 可能 |
| F-5 | Req 2 AC 6 | file system error の具体 failure mode 列挙 + atomic 操作 vs 失敗時 cleanup の選択 + SIGINT/SIGTERM 中断 signal 取扱 | atomic = temp dir + rename 方式推奨 |
| F-6 | Req 3 AC 5 | `impact_score.fix_cost` / `downstream_effect` の有限値 enum 値 | LOW / MEDIUM / HIGH の 3 値推奨 (post-run measurement 整合) |
| F-7 | Req 3 AC 9 | JSON Schema Draft 版 (Draft 2020-12 / Draft-07 等) | Draft 2020-12 推奨 (latest stable) |
| F-8 | Req 3 AC 10 | `phase1_meta_pattern` の JSON Schema 実装方式 (`nullable: true` / `not required` のいずれを default) | nullable: true 推奨 (escalate 検出フラグの semantic 一致) |
| F-9 | Req 6 AC 6 | encapsulation 検証基準 | unit test での internal symbol 不可視性確認 |
| F-10 | Req 6 AC 7 | malformed 検出粒度 (syntax check / schema validation) + error 提供 agent (dr-init / schema validator / runtime) | schema validation + dr-init skill 推奨 |

---

## design-review (18 件)

| # | Req AC | defer 内容 | 確定方針候補 |
|---|--------|-----------|-------------|
| DR-1 | Req 1 AC 2 | 10 ラウンド構成詳細 (memory `feedback_design_review.md` 規範) | memory 規範を design.md に転写 |
| DR-2 | Req 1 AC 5 | ラウンド別分離 / その他形式 (累積 default) | 累積累計 default + ラウンド別分離 optional |
| DR-3 | Req 1 AC 6 (a) | fatal error 失敗 mode 列挙 | subagent dispatch 失敗 / config 不正 / artifact load 失敗 を network / IO / parse error に分類 |
| DR-4 | Req 1 AC 6 (b) | partial flush vs in-memory のいずれかを選択 | JSONL partial flush 推奨 (`dual-reviewer-dogfeeding` Req 1 AC 4 (a) integration) |
| DR-5 | Req 1 AC 6 (c) | 自動 resume 方式 (Phase A scope 外、design phase で具体方式確定) | Phase A は手動 resume のみ、自動 resume は B-1.x 以降 |
| DR-6 | Req 2 AC 3 | strict context 分離の technical 検証 + 検証失敗時の代替 dispatch 機構 | Claude Code Agent tool の context isolation を unit test で検証、失敗時は別 process spawn fallback |
| DR-7 | Req 2 AC 4 | subagent dispatch 失敗 mode + fall back 挙動 (primary 単独継続 vs ラウンド中断) | primary 単独継続 default、user 設定で ラウンド中断切替可 |
| DR-8 | Req 2 AC 5 | single mode 切替の skill argument flag 名 | `--single` / `--mode=single` 推奨 |
| DR-9 | Req 3 AC 3 | escalate 必須条件 5 種の発動 logic | memory `feedback_review_step_redesign.md` 規範を design.md に転写 |
| DR-10 | Req 3 AC 6 | Step 1b 深掘り判定基準 | memory 規範を design.md に転写 |
| DR-11 | Req 3 AC 7 | escalate 必須 user 判断機会の形式 (blocking prompt / log 記録 + 後続 flag 等) | log 記録 + 後続 flag 推奨 (non-blocking、batch user review) |
| DR-12 | Req 4 AC 2 | forced divergence prompt 文言最終確定 | 素案「primary reviewer の暗黙前提を 1 つ identify し、別の妥当な代替前提に置換した場合に同じ結論が成立するか評価せよ」を base、英語固定 1 行 |
| DR-13 | Req 5 AC 4 | JSONL 書込失敗 mode + atomic 書込方式 (temp file + rename) + SIGINT/SIGTERM 中断 signal 取扱 | temp file + rename 方式、SIGINT は graceful shutdown |
| DR-14 | Req 5 AC 5 | validator 実装 (jsonschema 等) + 検証失敗時挙動 (abort / warn-and-continue) | jsonschema python lib + warn-and-continue default (`dual-reviewer-dogfeeding` Req 3 AC 6 (c) integration) |
| DR-15 | Req 5 AC 9 | JSONL 重複 record 防止戦略 (review_case ID + round 番号 dedup / append-only post-run dedup) | review_case ID + round 番号 dedup default |
| DR-16 | Req 6 AC 7 | 自己ラベリング失敗時 fallback 値 (default value / re-prompt / log warning) | default value (`miss_type: implicit_assumption` 等の最小 risk default) + log warning |
| DR-17 | Req 7 AC 3 | sample design 文書 1 件の入力と通過判定基準 | Spec 6 design 初版 draft を sample 入力、通過基準 = JSONL output schema validate pass + finding ≥ 5 件検出 |
| DR-18 | Req 7 AC 6 / AC 7 | encapsulation 検証基準 + error 提供 agent | F-9 / F-10 整合 |

---

## dogfeeding (10 件)

| # | Req AC | defer 内容 | 確定方針候補 |
|---|--------|-----------|-------------|
| DF-1 | Req 2 AC 4 | cross-context isolation 実装方式 (session 起動方式 / state クリア方式) | 別 Claude Code session 起動 + memory state 全リセット |
| DF-2 | Req 2 AC 6 | `trigger_state.alternative_considered` 識別 distinction (forced divergence skip vs primary 自身代替案) → 依存元 design phase | DR-9 (escalate 必須条件 5 種) + DR-12 (forced divergence prompt) と integration |
| DF-3 | Req 3 AC 2 | schema validation 失敗時挙動 → 依存元 design phase | DR-14 整合、warn-and-continue default |
| DF-4 | Req 3 AC 3 | archive path naming convention | `dev_log/dogfeeding-spec6-{single\|dual}-{timestamp}.jsonl` 推奨 |
| DF-5 | Req 3 AC 6 (c) | schema 違反 record 除外ロジック / limitation 注記方式 → 依存元 design phase | DR-14 integration |
| DF-6 | Req 3 AC 7 | review_case ID cross-mode 識別 (mode prefix / path 分離 / field 付加) | mode prefix `single-` / `dual-` を ID に付与推奨 |
| DF-7 | Req 4 AC 2 | disagreement 細分化 (primary 否定された finding を含む真の disagreement) | adversarial 追加 finding (本 spec 主指標) + primary 否定 finding (subagent 緩和推奨で記録) を別 metric として分離 |
| DF-8 | Req 4 AC 6 | metric 比較形式 | table 形式 (single mode / dual mode 各列、metric 各行、差分 + ratio 列) 推奨 |
| DF-9 | Req 5 AC 4 | figure 1-3 比較形式 | DF-8 と同形式、figure として visualize は Phase 3 論文ドラフト時 |
| DF-10 | Req 6 AC 5 | judgment 結果の deliverable documenting 形式 | `.kiro/specs/dual-reviewer-dogfeeding/phase-b-fork-judgment.md` 推奨 |

---

## design phase 開始時の運用

1. 本 list を design.md 策定の input として参照
2. 各 defer 事項 (F-1〜F-10 / DR-1〜DR-18 / DF-1〜DF-10) を design.md の対応 section で確定
3. design 完了時に本 list の各 entry を「✓ resolved (design.md §X.Y で確定)」と更新
4. Phase B-1.0 release prep 移行時に本 list の resolution が approve evidence の一部となる

---

## 関連 ファイル

- `.kiro/specs/dual-reviewer-foundation/requirements.md`
- `.kiro/specs/dual-reviewer-design-review/requirements.md`
- `.kiro/specs/dual-reviewer-dogfeeding/requirements.md`
- `.kiro/drafts/dual-reviewer-draft.md` v0.3 (上位文書)
- memory `~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_review_v3_generalization_design.md` §1-14
