# Requirements Document

## Project Description (Input)

Rwiki v2 の L3 Curated Wiki ページと Skill ファイルの lifecycle（active / deprecated / retracted / archived / merged の状態遷移と active 復帰）は、Spec 1 が宣言する frontmatter `status:` を介して管理される。しかし状態遷移時の dangerous op（8 段階対話、警告 blockquote 自動挿入、backlink 更新、follow-up タスク化）が定義されていなければ、ユーザーが手動で全てを処理することになり、誤操作で trust chain が壊れる。さらに L2 Edge lifecycle（Spec 5 が所管する `weak / candidate / stable / core / deprecated / rejected`）との相互作用（Page deprecation → 関連 Edges demotion / Page retracted → Edges を rejected に準ずる扱い / Page merged → Edges を merged target に付け替え）も orchestrate されなければ、Page と Edge の状態が乖離する。

本 spec（Spec 7、Phase 2）は、`rwiki-v2-foundation`（Spec 0）が固定したビジョン・原則・用語、特に Page status 5 種と Edge status 6 種の独立性、§2.3 status frontmatter over directory movement、§2.4 Dangerous operations 8 段階、§2.5 Simple dangerous operations の規範に準拠しつつ、`rwiki-v2-classification`（Spec 1）が宣言した lifecycle field（`status` / `status_changed_at` / `status_reason` / `successor` / `merged_from` / `merged_into` / `merge_strategy` / `merge_conflicts_resolved` / `update_history`）の **状態遷移セマンティクスと操作 handler ロジック** を所管する。具体的には、(a) Page status 5 種の状態遷移ルール、(b) Page lifecycle と Edge lifecycle の相互作用（Spec 5 edge API の orchestration）、(c) 8 段階チェックリスト共通ガイド（`AGENTS/guides/dangerous-operations.md`）、(d) 操作固有ガイド（`deprecate-guide.md` / `merge-guide.md` 等）、(e) Follow-up タスク仕組み（`wiki/.follow-ups/`）、(f) 警告 blockquote の自動挿入、(g) Backlink 更新（merge / deprecate 時）、(h) Simple dangerous op（unapprove / reactivate）の 1 段階確認、(i) Skill lifecycle（deprecate / retract / archive）、(j) Dangerous op 13 種の分類（必須 / 推奨 / 簡易、--auto 可否）、を定義する。

Page status の field 宣言は Spec 1、Edge status の定義と進化則は Spec 5 の責務であり、本 spec は Page lifecycle の操作セマンティクスと Page→Edge 相互作用の orchestration のみを所管する。Dangerous op CLI のフレーム（dispatch / argparse / chat 統合）は Spec 4 の所管であり、本 spec は handler ロジックを Spec 4 の `cmd_*` 関数として呼び出せる形で提供する。

出典 SSoT: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.3（Status frontmatter over directory movement）/ §2.4（Dangerous operations 8 段階、L3 対象）/ §2.5（Simple dangerous operations）/ §7.2 Spec 7（Page status 5 種、Page と Edge lifecycle の相互作用、Dangerous op 13 種の分類）。Upstream: `rwiki-v2-foundation` requirements.md（13 中核原則・用語集・Edge/Page status の区別）/ `rwiki-v2-classification` requirements.md（frontmatter `status:` field 宣言と許可値）。

## Introduction

本 requirements は、Rwiki v2 の Spec 7 として L3 Page と Skill の **lifecycle 操作セマンティクス** を定義する。読者は Spec 7 の実装者と、本 spec が所管する dangerous op handler を呼び出す Spec 4（cli-mode-unification、CLI dispatch）/ Spec 5（knowledge-graph、Page→Edge interaction の edge API 提供）/ Spec 6（perspective-generation、Confirmed hypothesis の wiki 昇格時に本 spec の dangerous op を経由）の起票者である。

本 spec は **lifecycle 操作の handler ロジックと AGENTS/guides ドキュメント群を直接定義する spec** であり、規範文書（Foundation）とも frontmatter 宣言（Spec 1）とも異なり実装される機能と運用ガイドを含む。したがって本 requirements の各 acceptance criterion は、(a) Page status 5 種の状態遷移ルール、(b) Page→Edge 相互作用の orchestration 動作、(c) 8 段階チェックリスト / 操作固有ガイドが満たすべき記述要件、(d) Follow-up / 警告 blockquote / Backlink 更新が満たすべき動作要件、(e) Simple dangerous op の動作要件、(f) Skill lifecycle の動作要件、(g) 周辺 spec（Spec 1 / 4 / 5 / 6）との境界・coordination 要件、として記述される。Subject は概ね `the Lifecycle Manager` または個別コンポーネント（`the deprecate handler` / `the merge handler` / `the dangerous operation guide` / `the follow-up registry` 等）を用いる。

本 spec の成果物は次の 7 種類に分類される。

- Page status 5 種（active / deprecated / retracted / archived / merged）の状態遷移ルールと active 復帰の規定
- Page lifecycle と Edge lifecycle の相互作用 orchestration（Spec 5 edge API の呼出規約）
- Dangerous op 8 段階共通チェックリスト（`AGENTS/guides/dangerous-operations.md`）と操作固有ガイド（`deprecate-guide.md` / `merge-guide.md` 等）
- Dangerous op 13 種の分類（必須 / 推奨 / 簡易、--auto 可否）と handler の動作要件
- Follow-up タスク仕組み（`wiki/.follow-ups/`）、警告 blockquote の自動挿入、Backlink 更新
- Simple dangerous op（unapprove / reactivate / edge reject 等は Spec 5 / 本 spec は L3 のみ）の 1 段階確認動作
- Skill lifecycle（deprecate / retract / archive）の動作要件

Spec 4-6 が本 spec を引用することで、Page lifecycle 操作の手順・対話階段・Page→Edge 相互作用の API 契約が複数 spec で分岐することを防ぐ。

## Boundary Context

- **In scope**:
  - Page status 5 種（`active` / `deprecated` / `retracted` / `archived` / `merged`）の状態遷移ルールと active 復帰の規定
  - 各 status における参照元扱い・Query/Distill 対象・Wiki 位置の動作仕様（§7.2 Spec 7 の「Page 状態と挙動」表に準ずる）
  - Page lifecycle と Edge lifecycle の相互作用 orchestration（Page deprecation → 関連 Edges demote 候補化、Page retracted → 関連 Edges を rejected に準ずる扱い、Page merged → Edges を merged target に付け替え）
  - 8 段階チェックリスト共通ガイド（`AGENTS/guides/dangerous-operations.md`）の作成と維持
  - 操作固有ガイド（`AGENTS/guides/deprecate-guide.md` / `retract-guide.md` / `archive-guide.md` / `merge-guide.md` / `split-guide.md` / `tag-merge-guide.md` / `tag-split-guide.md` / `skill-install-guide.md` / `skill-retract-guide.md` / `hypothesis-approve-guide.md` / `query-promote-guide.md` 等）の作成と維持
  - Dangerous op 13 種の分類（必須 / 推奨 / 簡易、--auto 可否）と handler の動作要件
  - Follow-up タスク仕組み（`wiki/.follow-ups/` の自動生成、frontmatter スキーマ、reactivate / 解消フロー）
  - 警告 blockquote の自動挿入（deprecate / retract / archive 時に該当ページ本文先頭に追加）
  - Backlink 更新（wiki merge / deprecate 時に該当ページを参照する markdown を走査して successor / merged_into への誘導を加える）
  - Simple dangerous op（`rw unapprove` / `rw reactivate`）の 1 段階確認動作
  - Skill lifecycle（`rw skill deprecate` / `rw skill retract` / `rw skill archive`）の動作要件
  - `--auto` 不可指定の固定（`retract` / `split` / `tag split` / `skill retract` / `promote-to-synthesis` の 5 種は --auto 不可）
  - Page→Edge 相互作用 orchestration における Spec 5 edge API（`edge demote` / `edge reject` / `edge reassign` 等）の呼出規約と失敗時の rollback ポリシー
- **Out of scope**:
  - Page status field 自体のスキーマ宣言（Spec 1 が field 名・型・許可値を所管、Foundation Requirement 5 / Spec 1 Requirement 3 と整合）
  - Edge status の定義・遷移ルール・進化則（Spec 5 Graph Hygiene が所管）
  - Edge 個別操作 API の実装（`edge demote` / `edge reject` / `edge reassign` 等の内部ロジックは Spec 5 が所管。本 spec は API 契約の呼出側）
  - L2 ledger の data model（`edges.jsonl` / `edge_events.jsonl` / `evidence.jsonl` / `rejected_edges.jsonl`、Spec 5）
  - L2 edge 操作の 1 段階確認動作（`rw edge reject` / `rw edge unreject` / `rw edge promote` / `rw edge demote`、Spec 5 が所管。Foundation §2.5 で「L2 対象」として明記）
  - 個別 CLI コマンドの dispatch / argparse / chat 統合フレーム（Spec 4 が所管。本 spec は handler ロジックを `cmd_*` 関数として提供）
  - Skill 内容（Spec 2 が所管）
  - Hypothesis 生成・verify ロジック（Spec 6 が所管。`hypothesis approve` の wiki 昇格段階のみ本 spec の dangerous op を経由）
  - L3 frontmatter `related:` の sync / cache invalidation 実装（Spec 5 が所管。本 spec は merge 時に Edge 付け替えを Spec 5 に依頼するのみ）
  - Severity 4 水準と exit code 0/1/2 分離の規約定義（Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」が固定済、本 spec は継承）
- **Adjacent expectations**:
  - 本 spec は Foundation（Spec 0、`rwiki-v2-foundation`）が固定する 13 中核原則のうち §2.3 status frontmatter over directory movement / §2.4 Dangerous operations 8 段階 / §2.5 Simple dangerous operations / §2.10 Evidence chain / §2.13 Curation Provenance を **設計前提** として参照し、独自定義による再解釈・再命名を行わない。
  - 本 spec は Spec 1（`rwiki-v2-classification`）が宣言する `status` / `status_changed_at` / `status_reason` / `successor` / `merged_from` / `merged_into` / `merge_strategy` / `merge_conflicts_resolved` / `update_history` field の存在・型・許可値を **唯一の入力スキーマ** として参照し、独自に field を追加・改名しない。新規 field が必要になった場合は先に Spec 1 を改版する（roadmap.md「Adjacent Spec Synchronization」運用ルール）。
  - Spec 4 は本 spec の handler ロジックを `cmd_deprecate` / `cmd_retract` / `cmd_archive` / `cmd_merge` / `cmd_split` / `cmd_unapprove` / `cmd_reactivate` / `cmd_skill_install` / `cmd_skill_deprecate` / `cmd_skill_retract` / `cmd_skill_archive` 等として CLI dispatch する。本 spec は handler の signature と動作要件を提供し、CLI フレーム（argparse / chat 統合 / exit code）は Spec 4 の所管とする。
  - Spec 5 は本 spec の Page→Edge 相互作用 orchestration から呼び出される edge API（`edge demote(edge_id, reason)` / `edge reject(edge_id, reason)` / `edge reassign(edge_id, new_target_path)` 等）を提供する。本 spec は呼出側、Spec 5 は edge 内部状態遷移の実装側として責務を分離する。
  - Spec 6 は Confirmed hypothesis の wiki 昇格段階で本 spec の `promote-to-synthesis` 8 段階対話を経由する。本 spec は handler を提供し、Spec 6 は呼出元（hypothesis status `confirmed` → `promoted` 遷移時）として責務を分離する。
  - 本 spec は Severity 4 水準（CRITICAL / ERROR / WARN / INFO）と exit code 0/1/2 分離（PASS / runtime error / FAIL 検出）を Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 経由で継承し、独自に再定義しない。
  - 本 spec は Foundation §2.12「L2 専用優先関係」を遵守し、Page→Edge 相互作用 orchestration（Requirement 3）において Edge 内部状態遷移 / Hygiene による decay / reinforcement / Competition / Contradiction tracking 等の L2 自律進化ロジックに立ち入らない（Requirement 12.5 と整合、Edge status 6 種は Spec 5 所管）。

## Requirements

### Requirement 1: Page status 5 種の状態遷移ルール

**Objective:** As a Spec 4 起票者および Rwiki v2 ユーザー, I want Page status 5 種（`active` / `deprecated` / `retracted` / `archived` / `merged`）の状態遷移ルールと active 復帰可能な遷移が一意に定義されている, so that lifecycle handler が遷移可否を判定でき、ユーザーが手動で frontmatter を編集する場合にも合法な遷移系列が分かる。

#### Acceptance Criteria

1. The Lifecycle Manager shall Page status 5 種を `active` / `deprecated` / `retracted` / `archived` / `merged` として固定し、Foundation Requirement 5 / Spec 1 Requirement 3 の許可値と完全一致させる。
2. The Lifecycle Manager shall 各 status の遷移先を以下のとおり規定する: `active → {deprecated, retracted, archived, merged}` / `deprecated → {active（reactivate）, retracted, archived, merged}` / `archived → {active（reactivate）, retracted}` / `retracted → {}`（不可逆、git revert のみで戻る）/ `merged → {}`（不可逆、git revert のみで戻る）。`archived` は意図的に終端的 lifecycle 状態として設計され、deprecated / merged への直接遷移は不可とする（変更時は `rw reactivate` で `active` に戻してから別の lifecycle 操作を実行する 2 段階運用を採る）。これにより archived の「履歴扱い、Query 履歴として検索可」（Requirement 2.4）セマンティクスと deprecated / merged の警告セマンティクスが意味的に分離される。
3. When 任意の dangerous op handler が status 遷移を要求する, the Lifecycle Manager shall Acceptance Criterion 2 の遷移表を参照し、許可されない遷移を CRITICAL severity で拒否する。
4. The Lifecycle Manager shall status 遷移時に必ず `status_changed_at`（YYYY-MM-DD）と `status_reason`（自由文字列、空文字禁止）を frontmatter に記録する。
5. If `status_reason` が空文字または未指定で status 遷移が要求された, then the Lifecycle Manager shall ERROR severity で操作を拒否し、reason の入力を求める。
6. The Lifecycle Manager shall status 遷移を **frontmatter 編集のみ** で表現し、ディレクトリ移動を伴わないことを規定する（Foundation §2.3 status frontmatter over directory movement / Spec 1 Requirement 1 と整合）。
7. While `merged` への遷移を扱う場合, the Lifecycle Manager shall `merged_from`（path 配列）/ `merged_into`（path）/ `merge_strategy`（**初期セット**として `complementary` / `dedup` / `canonical-a` / `canonical-b` / `restructure` の 5 値、Spec 1 Requirement 3.4 と整合）の 3 field を必須記録項目として要求する。本 spec は merge_strategy 5 値を初期セットとして継承し、6 番目以降の strategy が必要となった場合は本 spec の requirements で新値を宣言した上で Spec 1 を Adjacent Sync で更新する手順を採る（roadmap.md「Adjacent Spec Synchronization」運用ルール、許可値リストの正本は Spec 1）。
8. The Lifecycle Manager shall 全 status 遷移 dangerous op の approve 完了時に対象ページの `update_history:` field へ要素 `{date, type, summary, evidence?}` を自動追記する。`type` の lifecycle 起源許可値として `deprecation` / `retract` / `archive` / `merge` / `split` / `reactivate` / `promote_to_synthesis` を本 spec が初期セットとして規定する（Spec 1 Requirement 3.6 が宣言した `update_history` schema と整合、`type` の正規許可値リストの所管は本 spec）。新 `type` 値の追加時は Spec 1 への Adjacent Sync を経由する（roadmap.md「Adjacent Spec Synchronization」運用ルール）。**Skill ファイルには本 AC を v2 MVP では適用せず**、Skill の lifecycle 履歴は `decision_log.jsonl` の Skill 起源 4 種（`skill_install` / `skill_deprecate` / `skill_retract` / `skill_archive`、本 spec Requirement 12.7 / Spec 5 Requirement 11.2 と整合）で網羅する（Spec 2 Requirement 3.6 と整合）。

### Requirement 2: 各 status における参照元扱い・Query/Distill 対象の挙動

**Objective:** As a Spec 4 / Spec 6 起票者, I want 各 Page status における参照元扱い（警告注記 / 強警告 / そのまま / 誘導）と Query / Distill 対象範囲（対象 / 原則除外 / 完全除外 / 履歴として検索可）が一意に定義されている, so that query / perspective / distill の動作が status を尊重した形に揃う。

#### Acceptance Criteria

1. The Lifecycle Manager shall `status: active` のページを通常扱いとし、Query / Distill / Perspective 生成いずれの対象にも含めることを規定する。
2. The Lifecycle Manager shall `status: deprecated` のページを警告注記付き（successor 誘導の blockquote 自動挿入）として扱い、Query / Distill 対象から原則除外（明示フラグ `--include-deprecated` 等で含める）することを規定する。
3. The Lifecycle Manager shall `status: retracted` のページを強警告付き（撤回理由を含む blockquote 自動挿入）として扱い、Query / Distill / Perspective から完全除外することを規定する。
4. The Lifecycle Manager shall `status: archived` のページを警告なしの履歴扱いとし、Query / Distill から履歴として検索可能（明示フラグまたは history mode で含める）に位置付ける。
5. The Lifecycle Manager shall `status: merged` のページを `merged_into` への誘導付きとして扱い、Query / Distill 対象から除外することを規定する（candidate ページのみが元の位置に残る）。
6. The Lifecycle Manager shall いずれの status においても Wiki 上の物理位置（パス）を変更しないことを規定する（§2.3 と整合、Requirement 1.6 と整合）。
7. While Query / Distill / Perspective の実装側（Spec 4 / Spec 6）が status による絞り込みを行う場合, the Lifecycle Manager shall 自身が status の意味と除外規約を所管し、絞り込みフィルタ自体の実装は呼出側 spec が担うことを明示する。

### Requirement 3: Page lifecycle と Edge lifecycle の相互作用 orchestration

**Objective:** As a Spec 5 起票者, I want Page status 遷移時に関連 L2 Edges に対する demotion / rejection / reassignment を本 spec が orchestrate し、Spec 5 の edge API を呼出側として利用する責務分離が明確である, so that Page と Edge の状態が乖離せず、edge 内部状態遷移は Spec 5 の所管にとどまる。

#### Acceptance Criteria

1. When Page が `active → deprecated` に遷移した, the Lifecycle Manager shall Spec 5 の edge API（例: `edge demote(edge_id, reason="page_deprecated")`）を該当ページが source または target である全 stable / core edges に対して呼び出し、Edges を demote 候補化する。
2. When Page が `active → retracted` または `deprecated → retracted` に遷移した, the Lifecycle Manager shall Spec 5 の edge API（例: `edge reject(edge_id, reason_category="page_retracted", reason_text=<status_reason>)`）を該当ページが source または target である全 edges（rejected 以外）に対して呼び出し、Edges を rejected に準ずる扱いに移す。
3. When Page A と Page B が `merged_into` Page C へと merge された, the Lifecycle Manager shall Spec 5 の edge API（例: `edge reassign(edge_id, new_endpoint=C)`）を該当 edges の source または target が A / B である全 edges に対して呼び出し、エンドポイントを C に付け替える。
4. The Lifecycle Manager shall Page→Edge 相互作用 orchestration 中に Spec 5 edge API のいずれかが失敗した場合、既に成功した edge 操作を rollback せず、frontmatter status 遷移自体は維持し、失敗した edge 操作を follow-up タスク（Requirement 7）として `wiki/.follow-ups/` に記録することを規定する。
5. The Lifecycle Manager shall Page→Edge 相互作用 orchestration の呼出規約として、Spec 5 が提供する edge API の signature（`edge_id` / `reason_category` / `reason_text` / `actor` / `pre_status` 等の必須パラメータ）を本 spec の design 段階で確定すべき coordination 項目として明示する。
6. While Spec 5 が edge 内部状態遷移ロジック（confidence 更新 / `edge_events.jsonl` への append / `rejected_edges.jsonl` への移動 / `relations.yml` 参照等）を実装する場合, the Lifecycle Manager shall 自身が呼出側として API のみを利用し、edge 内部状態遷移の実装に立ち入らないことを明示する。
7. If Page→Edge 相互作用 orchestration の API 呼出が rollback 不能な部分的失敗を起こした, then the Lifecycle Manager shall 失敗状態を decision_log（Foundation Requirement 12 / Spec 5 所管）に記録するよう Spec 5 へ追加情報を渡し、follow-up タスクで人間の事後判断を促す。
8. When Page→Edge orchestration が rollback 不能な部分的失敗を起こした, the Lifecycle Manager shall handler の exit code を `1`（runtime error、Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」exit code 0/1/2 分離と整合）として返し、JSON 出力に `partial_failure: true` / `successful_edge_ops: <count>` / `failed_edge_ops: <count>` / `followup_ids: [<id>...]` を含めることを規定する。完全成功時は exit `0`（PASS）、handler 自身の例外（lock 取得失敗 / I/O error 等）は exit `1` として返し、これらは JSON 出力の `partial_failure` field 有無で区別する。
9. The Lifecycle Manager shall 8 段階対話の step 8 (approve) 完了後の一括実行（frontmatter 編集 / Edge 状態変更 / Backlink 追記 / `update_history` 追記 / 警告 blockquote 挿入 / Follow-up 生成等、Requirement 4.7 と整合）の前に `.rwiki/.hygiene.lock` を取得し、一括実行完了後に解放することを規定する（Foundation Requirement 11.5 / Spec 4 Requirement 10.1 / Spec 5 Requirement 17 と整合）。lock 取得失敗時は handler の exit code を `1`（runtime error）として返し、JSON 出力に `lock_acquisition_failed: true` / `lock_holder_pid: <pid>` を含めることを規定する（Requirement 3.8 と整合）。Simple dangerous op（`rw unapprove` / `rw reactivate`、Requirement 10）も同様に lock 取得を経由する。lock 取得直後に Requirement 4.2 の step 6 (Pre-flight warning) を再実行し、step 1〜7 期間中に対象ページの状態が変化した場合（`status` / `successor` / `merged_from` / `merged_into` / 関連 edges 等）は ERROR severity で operation を abort し、ユーザーに 8 段階対話の再実行を促す。再確認は read-only 操作で lock 範囲内に含めることで race window を消失させる。

### Requirement 4: 8 段階共通チェックリストガイド

**Objective:** As a 全 dangerous op handler 実装者および Rwiki v2 ユーザー（特に LLM ガイド利用者）, I want 8 段階チェックリストが `AGENTS/guides/dangerous-operations.md` に共通ガイドとして集約されている, so that 個別操作ガイドが共通部分を再記述せず、LLM が `rw chat` 経由でガイドする際にも単一の参照点を持てる。

#### Acceptance Criteria

1. The Dangerous Operation Guide shall 共通ガイドを `AGENTS/guides/dangerous-operations.md` に配置し、本 spec の所管成果物として作成・維持する。
2. The Dangerous Operation Guide shall 8 段階チェックリストを (1) 意図確認 / (2) 現状把握 / (3) 依存グラフ解析 / (4) 代替案の提示 / (5) 各参照元の個別判断 / (6) Pre-flight warning / (7) 差分プレビュー生成（review 層）/ (8) 人間レビュー → approve として固定する（Foundation §2.4 / SSoT §2.4 と完全一致）。
3. The Dangerous Operation Guide shall 各段階について「目的」「LLM が確認すべき項目」「ユーザーへの提示形式」「次段階へ進む条件」の 4 項目を最低限記述する。
4. The Dangerous Operation Guide shall 8 段階対話の **適用範囲を L3 Curated Wiki の不可逆操作に限定** し、L2 Graph Ledger の edge 操作には適用しないことを §2.4 / §2.5 / §2.12 への参照とともに明示する。
5. While 個別操作ガイド（`deprecate-guide.md` 等）が共通 8 段階を引用する場合, the Dangerous Operation Guide shall 個別ガイドが共通段階を再記述せず、共通ガイドへの参照と固有差分（操作固有の Pre-flight チェック項目 / 警告 blockquote の文言テンプレート等）のみを記述する形式を取ることを規定する。
6. The Dangerous Operation Guide shall 共通ガイドが Markdown で記述され、`rw chat` 経由で LLM が読み込み可能な形式（標準的な Markdown 見出し階層）で構成されることを規定する。
7. The Dangerous Operation Guide shall 8 段階対話の **step 1〜7（意図確認 → 現状把握 → 依存グラフ解析 → 代替案提示 → 各参照元の個別判断 → Pre-flight warning → 差分プレビュー生成）を read-only 操作として実装** することを規定し、frontmatter 編集 / Edge 状態変更 / Backlink 追記 / `update_history` 追記 / `decision_log` 記録 / Follow-up 生成 / 警告 blockquote 自動挿入等の永続的副作用は **step 8 (approve) 完了後に一括実行** する。途中キャンセル（Ctrl+C / プロセス終了 / chat セッション中断等）時は永続化前のため状態整合性が保たれることを保証する（一括実行の atomicity / fsync / トランザクション境界の詳細は design phase で確定）。

### Requirement 5: 操作固有ガイドの作成と維持

**Objective:** As a 各 dangerous op handler 実装者, I want 操作固有のガイド（`deprecate-guide.md` / `merge-guide.md` 等）が共通ガイドの差分として作成され、それぞれの Pre-flight チェック項目・警告 blockquote 文言テンプレート・代替案候補が明文化されている, so that handler 実装が一意のテキスト出力を生成でき、LLM ガイドが操作ごとに揺らがない。

#### Acceptance Criteria

1. The Lifecycle Manager shall L3 8 段階対話の対象操作（`deprecate` / `retract` / `archive` / `merge`（wiki page 統合）/ `split` / `tag merge` / `tag split` / `skill install` / `skill deprecate` / `skill retract` / `skill archive` / `hypothesis approve`（wiki/synthesis/ への promote）/ `query promote`）の各々について、`AGENTS/guides/<operation>-guide.md` を作成・維持する。
2. The Lifecycle Manager shall 各操作固有ガイドが共通ガイド（Requirement 4）への参照と、固有差分として「Pre-flight チェック項目」「警告 blockquote 文言テンプレート」「代替案候補（例: deprecate を提案する代わりに status update / extension）」「典型的な拒否理由」の 4 項目を含むことを規定する。
3. While `merge-guide.md` を扱う場合, the Lifecycle Manager shall merge strategy 5 値（`complementary` / `dedup` / `canonical-a` / `canonical-b` / `restructure`）ごとの差分プレビュー手順を記述することを規定する。
4. While `tag-merge-guide.md` / `tag-split-guide.md` を扱う場合, the Lifecycle Manager shall Spec 1 Requirement 8 が定める `rw tag merge` / `rw tag split` の `review/vocabulary_candidates/` 経由 approve フローを参照し、本 spec が新規 review 層を作らないことを明示する。
5. The Lifecycle Manager shall `tag merge` / `tag split` の handler ロジックを **Spec 1 の `rw tag *` 実装側に委譲** することを明示し、本 spec のガイドは 8 段階対話階段の固有差分を記述するに留める。
6. The Lifecycle Manager shall `skill install` / `skill retract` / `hypothesis approve` / `query promote` の各ガイドが、それぞれ Spec 2（skill 内容） / Spec 6（hypothesis 生成）/ Spec 4（query 結果の wiki 昇格）の所管領域に踏み込まず、本 spec が所管する dangerous op 階段のみを記述することを明示する。
7. The Lifecycle Manager shall `deprecate-guide.md` の Pre-flight チェック項目に「successor 設定が deprecated chain 循環を作らないかの事前チェック（既存 deprecated ページの `successor:` field を辿り、循環検出時は ERROR severity で operation を拒否）」を必須項目として規定し、Requirement 15.5 の事後検出 API（`rw doctor` 経由）と独立した事前防止メカニズムとして機能させる。`merge-guide.md` でも同様に「`merged_from` / `merged_into` の循環チェック（merged target が再び `merged_from` 側を指すケース等）」を必須 Pre-flight 項目として規定する。

### Requirement 6: Dangerous op 13 種の分類と handler 動作要件

**Objective:** As a Spec 4 起票者, I want Dangerous op 13 種の各々について危険度・対話ガイド有無・--auto 可否が固定され、handler が `--auto` フラグを受けたときの動作と拒否すべきケースが明確である, so that CLI dispatch が一貫した挙動を取れる。

#### Acceptance Criteria

1. The Lifecycle Manager shall Dangerous op 13 種を `deprecate` / `retract` / `archive` / `reactivate` / `merge (review)` / `merge (wiki)` / `split` / `unapprove` / `tag merge` / `tag split` / `skill install` / `skill retract` / `promote-to-synthesis` として定義し、SSoT §7.2 Spec 7 の表と完全一致させる。
2. The Lifecycle Manager shall 各操作の危険度を SSoT §7.2 Spec 7 表に従って `deprecate=中 / retract=高 / archive=低 / reactivate=低 / merge (review)=中 / merge (wiki)=高 / split=中〜高 / unapprove=中 / tag merge=中 / tag split=中〜高 / skill install=中 / skill retract=高 / promote-to-synthesis=最高` として固定する。
3. The Lifecycle Manager shall 対話ガイド有無を `deprecate=必須 / retract=必須 / archive=推奨 / reactivate=簡易 / merge (review)=必須 / merge (wiki)=必須 / split=必須 / unapprove=簡易（1 段階） / tag merge=必須 / tag split=必須 / skill install=推奨 / skill retract=必須 / promote-to-synthesis=必須` として固定する。
4. The Lifecycle Manager shall **`--auto` 不可** の操作を `retract` / `split` / `tag split` / `skill retract` / `promote-to-synthesis` の 5 種として固定し、これらの handler は `--auto` フラグを受けても 8 段階対話を必ず経由することを規定する。
5. If `--auto` 不可指定の操作に対して `--auto` フラグが渡された, then the Lifecycle Manager shall 警告 INFO を出力したうえで 8 段階対話を実行する（拒否はせず、対話を強制する設計）。
6. The Lifecycle Manager shall `--auto` 可指定の操作（`deprecate` / `archive` / `reactivate` / `merge (review)` / `merge (wiki)` / `unapprove` / `tag merge` / `skill install` の 8 種）について、`--auto` 受領時に 8 段階対話を skip し pre-flight check / 差分プレビュー / 自動 approve を一連で実行することを規定する。`merge (wiki)` の `--auto` は drafts §7.2 Spec 7 の Dangerous op の分類表「✓（慎重）」と Spec 4 Requirement 3.2 の許可リスト規定に従い、`merge_strategy` field が確定済みの場合のみ許可する。明示フラグ名（例: `--yes` 同等）の確定は Spec 4 Requirement 3.2 の CLI フラグ規定に委ね、本 spec は条件（`merge_strategy` 確定済）のみ規定する。
7. While `unapprove` の `--auto` を扱う場合, the Lifecycle Manager shall SSoT §7.2 表「✓（`--yes`）」に従い、`--yes` フラグの明示を要求することを規定する。
8. The Lifecycle Manager shall 13 種の handler 関数の signature（`cmd_deprecate(target, reason, ...)` 等）と返り値（exit code / 出力 JSON / human-readable message）を Spec 4 の CLI dispatch から呼び出せる形で本 spec の design 段階で確定すべき coordination 項目として明示する。
9. The Lifecycle Manager shall `skill deprecate` / `skill archive` の 2 操作を drafts §7.2 Spec 7 の Dangerous op の分類表（13 種）に未列挙の Skill lifecycle 拡張として扱い、危険度 / 対話ガイド要否 / `--auto` 可否は本 spec の design phase で確定することを明示する（Spec 4 Requirement 13.7 が保留中の `rw skill deprecate` 分類確定と整合、drafts D-8 Adjacent Sync 完了後に drafts §7.2 Spec 7 の Dangerous op の分類表へ反映可）。Requirement 11.1 が提供する `rw skill deprecate` / `rw skill archive` handler および Requirement 13.1 が提供する `cmd_skill_deprecate` / `cmd_skill_archive` 関数は本 AC の Skill lifecycle 拡張として扱う。

### Requirement 7: Follow-up タスク仕組み

**Objective:** As a Rwiki v2 ユーザーおよび Page→Edge 相互作用 orchestration の rollback 不能な部分的失敗の事後処理者, I want Follow-up タスクが `wiki/.follow-ups/` に自動生成・管理される仕組みが固定されている, so that 即時解消できない事項（後続 edge 操作 / 参照元更新 / 手動レビュー）が忘却されず、reactivate 等の後続操作で適切に解消される。

#### Acceptance Criteria

1. The Lifecycle Manager shall Follow-up タスクの保存先を `wiki/.follow-ups/` ディレクトリとし、git 管理対象であることを規定する。
2. The Lifecycle Manager shall 各 Follow-up タスクファイルの frontmatter を `id`（unique 文字列、必須）/ `created_at`（YYYY-MM-DD、必須）/ `origin_operation`（生成元の dangerous op 名、必須）/ `origin_target`（操作対象 path、必須）/ `task_type`（`edge_followup` / `backlink_update` / `manual_review` / `reactivation_check` 等、必須）/ `status`（`open` / `resolved` / `dismissed`、必須、デフォルト `open`）/ `description`（自由文字列、必須）/ `evidence`（任意、関連 path / edge_id 配列）として宣言する。
3. When Page→Edge 相互作用 orchestration が rollback 不能な部分的失敗を起こした（Requirement 3.4）, the Lifecycle Manager shall 失敗内容を `wiki/.follow-ups/<auto-id>.md` として自動生成し、`task_type: edge_followup` を設定する。
4. When Backlink 更新（Requirement 9）が一部失敗した, the Lifecycle Manager shall 未更新ページを `wiki/.follow-ups/<auto-id>.md` として自動生成し、`task_type: backlink_update` を設定する。
5. When 任意の dangerous op の 8 段階対話で「ユーザーが代替案として後で人間判断する」を選択した, the Lifecycle Manager shall その判断保留事項を `wiki/.follow-ups/<auto-id>.md` として自動生成し、`task_type: manual_review` を設定する。
6. When `rw reactivate <page>` が deprecated / archived ページに対して実行された, the Lifecycle Manager shall そのページに紐付く `task_type: reactivation_check` の Follow-up タスクが存在する場合に、それらを自動的に再オープンまたは確認プロンプトに昇格させる。
7. The Lifecycle Manager shall Follow-up タスクの一覧表示・解消・dismiss を行うコマンド（`rw follow-up list` / `rw follow-up show <id>` / `rw follow-up resolve <id>` / `rw follow-up dismiss <id>`）の handler ロジックを所管し、CLI dispatch フレーム自体は Spec 4 の所管とする。
8. The Lifecycle Manager shall Follow-up タスク自体が L3 wiki ページの dangerous op を経由しない（`wiki/.follow-ups/` 配下は通常の wiki ページではない）ことを明示し、Follow-up タスクの解消は通常の編集 / `rw follow-up resolve` で完結する。

### Requirement 8: 警告 blockquote の自動挿入

**Objective:** As a Rwiki v2 ユーザー（読者）および Spec 4 / Spec 6 の query / perspective 実装者, I want deprecate / retract / archive 時に該当ページ本文先頭に警告 blockquote が自動挿入され、successor / 撤回理由 / archived 注記が読み取れる, so that ページを開いた瞬間に lifecycle 状態が視覚的に分かり、誤った参照が防げる。

#### Acceptance Criteria

1. When `rw deprecate <page>` の 8 段階対話が approve まで完了した, the Lifecycle Manager shall 該当ページの本文先頭（frontmatter 直後）に警告 blockquote `> [!WARNING] Deprecated\n> このページは {status_changed_at} に deprecated されました。理由: {status_reason}\n> 後継: {successor のリスト、リンク形式}` を自動挿入する。`successor:` field が未指定または空配列の場合（Spec 1 Requirement 3.3 で `successor:` は 0 個以上を許可、後継未定の deprecate も実用シナリオ）、blockquote の `後継:` 行を `後継: 未指定（後日 successor 設定可、`rw reactivate` で active 化後に再 deprecate も可）` と表示するか、または `後継:` 行自体を省略する仕様を `deprecate-guide.md`（Requirement 5.2 のテンプレート）で確定する。
2. When `rw retract <page>` の 8 段階対話が approve まで完了した, the Lifecycle Manager shall 該当ページの本文先頭に強警告 blockquote `> [!CAUTION] Retracted\n> このページは {status_changed_at} に retracted されました。理由: {status_reason}\n> このページの内容は信頼できません。Query / Perspective 対象から完全除外されています。` を自動挿入する。
3. When `rw archive <page>` の handler が approve まで完了した, the Lifecycle Manager shall 該当ページの本文先頭に注記 blockquote `> [!NOTE] Archived\n> このページは {status_changed_at} に archived されました。履歴として保存されています。理由: {status_reason}` を自動挿入する。
4. When `rw merge` の handler が approve まで完了した, the Lifecycle Manager shall `merged_from` 側の各ページ本文先頭に誘導 blockquote `> [!NOTE] Merged\n> このページは {status_changed_at} に {merged_into} へ merge されました。strategy: {merge_strategy}` を自動挿入する（GFM 標準 callout 5 種準拠、`[!NOTE]` は archived と同じ履歴扱いセマンティクス）。
5. When `rw reactivate <page>` の handler が approve まで完了した, the Lifecycle Manager shall 該当ページから上記の `[!WARNING] Deprecated` / `[!NOTE] Archived` blockquote を除去し、`update_history:` に reactivate イベントを追記する。
6. The Lifecycle Manager shall 警告 blockquote の文言テンプレートを操作固有ガイド（Requirement 5）に集約し、handler はテンプレート参照のみを行うことを規定する。
7. If 警告 blockquote 自動挿入時に該当ページが既に同種の blockquote を含んでいる, then the Lifecycle Manager shall 既存 blockquote を新規内容で更新（重複生成しない）し、`update_history:` に「blockquote updated」イベントを追記する。

### Requirement 9: Backlink 更新

**Objective:** As a Rwiki v2 ユーザー（読者）, I want wiki merge / deprecate 時に該当ページを参照する markdown ページ群が自動走査され、successor / merged_into への誘導が追加される, so that 古いリンクで読者が deprecated / merged ページに辿り着いても、後続ページへの導線が壊れない。

#### Acceptance Criteria

1. When `rw deprecate <page>` の 8 段階対話が approve まで完了した, the Lifecycle Manager shall 該当 page を参照する全 wiki / raw markdown ページを走査し、リンク箇所の **直後** に注記 `（注: このリンク先は deprecated。後継: {successor}）` を追記することを規定する。
2. When `rw merge` の handler が approve まで完了した, the Lifecycle Manager shall `merged_from` 側の各ページを参照する全 wiki / raw markdown ページを走査し、リンク箇所の **直後** に注記 `（注: このリンク先は {merged_into} へ merge されました）` を追記することを規定する。
3. The Lifecycle Manager shall Backlink 走査対象を `wiki/**/*.md` および `raw/**/*.md` とし、`v1-archive/**` および `.rwiki/**` は対象外とする。
4. While Backlink 更新を実行する場合, the Lifecycle Manager shall 同一ページに対する追記が既に行われている場合（同種の注記が既に存在する場合）、新規追記を skip する（重複追記を防止）ことを規定する。
5. If Backlink 走査中に一部ページの更新が失敗した, then the Lifecycle Manager shall 操作全体を rollback せず、未更新ページを Follow-up タスク（Requirement 7、`task_type: backlink_update`）として記録し、操作自体は完了として扱う。ただし Backlink 走査対象が全数失敗した場合（disk full / permission denied 等の根本的 I/O 障害）は ERROR severity で operation 自体を rollback し、frontmatter status 遷移と Edge orchestration を取り消す（lock 範囲内のため atomicity 保証可能、Requirement 3.9 と整合）。一部 / 全失敗の判定基準（例: 失敗率 ≥ 95% を全失敗とみなす等）は design phase で確定する。
6. The Lifecycle Manager shall Backlink 更新の前後で git diff が大きくならないよう、注記追加のみを行い既存のリンクテキストや本文は変更しないことを規定する。
7. While `retract` / `archive` を扱う場合, the Lifecycle Manager shall Backlink 更新を **行わない**（retracted は完全除外で誘導不要、archived は履歴扱いで誘導不要）ことを規定する。

### Requirement 10: Simple dangerous op の 1 段階確認動作

**Objective:** As a Rwiki v2 ユーザー, I want 軽量な可逆操作（`unapprove` / `reactivate`）が 1 段階確認のみで実行できる, so that 8 段階対話の重さに沮喪されず、誤 approve のすぐ取消や deprecated ページの復帰が現実的に行える。

#### Acceptance Criteria

1. The Lifecycle Manager shall `rw unapprove <commit-or-target>` を 1 段階確認の Simple dangerous op として実装し、git revert の薄いラッパーとして直前 approve を取消することを規定する（Foundation §2.5 / SSoT §2.5 と整合）。
2. The Lifecycle Manager shall `rw reactivate <page>` を 1 段階確認の Simple dangerous op として実装し、`status: deprecated` または `status: archived` の page を `status: active` に戻すことを規定する。
3. While `rw reactivate <page>` を実行する場合, the Lifecycle Manager shall 該当ページの警告 blockquote 除去（Requirement 8.5）/ Follow-up タスクの再オープン（Requirement 7.6）/ `update_history:` への reactivate イベント追記を一連で実行する。
4. The Lifecycle Manager shall Simple dangerous op の運用ルールとして「1 コマンド、最小フラグ」「Preview + y/N confirm のみ（対話 1 段階）」「可逆（git revert で戻る）」の 3 項目を遵守する（Foundation §2.5 / SSoT §2.5 と整合）。
5. If `rw reactivate <page>` が `status: retracted` または `status: merged` のページに対して実行された, then the Lifecycle Manager shall ERROR severity で拒否し、retracted / merged は不可逆である旨を明示する（Requirement 1.2 と整合）。
6. The Lifecycle Manager shall L2 edge 操作（`rw edge reject` / `rw edge unreject` / `rw edge promote` / `rw edge demote`）の handler ロジックを **本 spec の所管外** とすることを明示し、それらは Spec 5 の Simple dangerous op として実装されることを参照点として残す（Foundation §2.5 「L2 対象」/ SSoT §2.5 と整合）。

### Requirement 11: Skill lifecycle

**Objective:** As a Spec 2 / Spec 3 起票者および Skill library の運用者, I want Skill ファイルにも Page と類似の lifecycle 操作（deprecate / retract / archive）が提供され、skill 内容自体は Spec 2 の所管・lifecycle 操作セマンティクスは本 spec の所管という責務分離が明確である, so that Skill の世代交代・撤回・履歴化が一貫した dangerous op 階段で行える。

#### Acceptance Criteria

1. The Lifecycle Manager shall Skill ファイル（典型的には `AGENTS/skills/<name>/SKILL.md`、配置は Spec 2 の所管）に対して `rw skill deprecate <name>` / `rw skill retract <name>` / `rw skill archive <name>` の handler ロジックを提供する。
2. The Lifecycle Manager shall Skill lifecycle の status 遷移ルールを Page status 5 種（Requirement 1）と同じ集合および同じ遷移表で扱うことを規定する。
3. While `rw skill install` を扱う場合, the Lifecycle Manager shall SSoT §7.2 Spec 7 表に従い 8 段階対話の **対話ガイド推奨**（必須ではない）として動作要件を規定し、`--auto` 可とする。
4. While `rw skill retract` を扱う場合, the Lifecycle Manager shall SSoT §7.2 Spec 7 表に従い 8 段階対話の **対話ガイド必須** とし、`--auto` 不可とする（Requirement 6.4 と整合）。
5. The Lifecycle Manager shall Skill 内容自体（SKILL.md の本文 / metadata / allowed-tools 等）の編集・追加を **本 spec の所管外** とすることを明示し、それらは Spec 2 の所管である旨を参照点として残す。
6. While Skill ファイルの警告 blockquote 自動挿入と Backlink 更新を扱う場合, the Lifecycle Manager shall Page 用のロジック（Requirement 8 / 9）を Skill ファイルにも適用するが、Backlink 更新の走査対象に `AGENTS/**/*.md` を含めることを規定する。

### Requirement 12: Spec 7 ↔ Spec 5 coordination の責務分離

**Objective:** As a Spec 5 起票者, I want Page lifecycle operation の orchestration（本 spec）と edge 内部状態遷移の実装（Spec 5）の境界が明文で固定されている, so that Spec 5 の edge API 設計時に本 spec の Page→Edge 相互作用を再定義せずに参照でき、edge 操作の責務が二重に分散しない。

#### Acceptance Criteria

1. The Lifecycle Manager shall Page→Edge 相互作用 orchestration の **呼出側責務**（どの Page status 遷移時にどの edge 操作を要求するかの判断）を本 spec の所管として固定する（Requirement 3 と整合）。
2. The Lifecycle Manager shall edge 内部状態遷移の **実装側責務**（confidence 更新 / `edge_events.jsonl` への append / `rejected_edges.jsonl` への移動 / `relations.yml` 参照 / decision_log 記録）を Spec 5 の所管として固定する（Requirement 3.6 と整合）。
3. The Lifecycle Manager shall Spec 5 が提供すべき edge API として `edge demote(edge_id, reason)` / `edge reject(edge_id, reason_category, reason_text)` / `edge reassign(edge_id, new_endpoint)` の 3 種を最低限の coordination 項目として明示し、API signature と error code の確定を本 spec の design 段階で行うことを規定する。
4. The Lifecycle Manager shall Spec 5 の edge API が同期 API として提供されることを前提とし、orchestration が逐次呼出可能であることを規定する。非同期化が必要となった場合は本 spec を先に改版する手順（roadmap.md「Adjacent Spec Synchronization」）を参照点として残す。
5. While Spec 5 が L2 edge の独自 lifecycle（Hygiene による decay / reinforcement / Competition / Contradiction tracking 等）を実装する場合, the Lifecycle Manager shall それらが本 spec から呼び出されないことを明示し、Spec 5 内の自律進化として完結する旨を確認する（Foundation §2.12 / Edge status 6 種は Spec 5 所管）。
6. If Spec 5 起票時に edge API の signature 変更が必要になった, then the Lifecycle Manager shall 本 spec を先に改版する手順を参照点として残し、本 spec が独自に呼出側ロジックを変更しないことを規定する。
7. The Lifecycle Manager shall Spec 4 Requirement 15.10 が dangerous op 完了時に呼び出す `record_decision()` API の `decision_type` 値として、Page lifecycle 起源の初期セット 7 種（`page_deprecate` / `page_retract` / `page_archive` / `page_merge` / `page_split` / `page_reactivate` / `page_promote_to_synthesis`）を本 spec が規定する（順序は Requirement 3.8 の `update_history.type` 列挙と整合）。Skill 起源 4 種（`skill_install` / `skill_deprecate` / `skill_retract` / `skill_archive`）も同じ pattern で本 spec が規定する（`skill_install` は Spec 2 Requirement 12.4 が install 完了時の履歴保全で参照する起点として宣言、Spec 5 Requirement 11.2 と整合）。新 `decision_type` 値の追加時は Spec 5 への Adjacent Sync を経由する（roadmap.md「Adjacent Spec Synchronization」運用ルール、Spec 4 Requirement 15.10 の「Spec 7 / Spec 1 が拡張可」と整合）。`record_decision()` の自動呼出責務自体は Spec 4 が CLI 側で行い、`decision_log.jsonl` schema・privacy mode・selective recording ルール本体は Spec 5 の所管とする（Requirement 12.2 と整合）。
8. The Lifecycle Manager shall edge API（`edge demote` / `edge reject` / `edge reassign` 等）の各呼出に timeout を必須として規定し、timeout 値の確定は本 spec の design phase の coordination 項目とする（roadmap.md「v1 から継承する技術決定」の LLM CLI subprocess timeout 必須と並列概念、ただし edge API は内部関数呼出のため値・実装機構は別系統）。timeout 発生時は当該 edge 操作を partial failure として扱い（Requirement 3.4 / 3.8 と整合）、`failed_edge_ops` に計上して follow-up タスク化する。timeout 後は orchestration 全体を継続し、残りの edge 操作を順次実行する。

### Requirement 13: Spec 7 ↔ Spec 4 coordination の責務分離

**Objective:** As a Spec 4 起票者, I want dangerous op CLI の dispatch / argparse / chat 統合フレーム（Spec 4）と handler ロジック（本 spec）の境界が明文で固定されている, so that CLI 設計が本 spec の handler を再実装せず、handler signature の coordination が一意に行える。

#### Acceptance Criteria

1. The Lifecycle Manager shall handler ロジックを `cmd_deprecate` / `cmd_retract` / `cmd_archive` / `cmd_reactivate` / `cmd_merge_review` / `cmd_merge_wiki` / `cmd_split` / `cmd_unapprove` / `cmd_skill_install` / `cmd_skill_deprecate` / `cmd_skill_retract` / `cmd_skill_archive` / `cmd_promote_to_synthesis` / `cmd_followup_list` / `cmd_followup_show` / `cmd_followup_resolve` / `cmd_followup_dismiss` 等の関数群として提供することを規定する（命名は design 段階で確定）。
2. The Lifecycle Manager shall handler 関数の返り値として exit code（Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 0/1/2 分離）と JSON / human-readable 出力を Spec 4 の CLI dispatch が利用可能な形で提供することを規定する。
3. The Lifecycle Manager shall CLI dispatch / argparse / chat 統合 / `rw` symlink / exit code 出力 / `--auto` フラグの parse を **本 spec の所管外** とし、Spec 4 の CLI フレームが担うことを明示する。
4. While Spec 4 の `rw chat` が dangerous op を LLM ガイドする場合, the Lifecycle Manager shall handler が 8 段階対話を内部で実装するのではなく、対話ステップを順次返す形（コールバック / generator / step API）で chat 統合可能なインターフェイスを提供することを設計時の検討事項として残す。
5. The Lifecycle Manager shall `tag merge` / `tag split` の handler を **Spec 1 の `rw tag *` 実装側に委譲** し、本 spec は AGENTS guide のみを提供することを明示する（Requirement 5.5 と整合）。
6. If Spec 4 起票時に handler signature 変更が必要になった, then the Lifecycle Manager shall 本 spec を先に改版する手順（roadmap.md「Adjacent Spec Synchronization」）を参照点として残す。
7. The Lifecycle Manager shall Spec 4 Requirement 16.2 が `review/synthesis_candidates/*` を本 spec へ dispatch する際、`cmd_promote_to_synthesis(candidate_path, target_path, merge_strategy, target_field)` を提供し、`merge_strategy` field と `target` field から **新規 wiki page 生成 / `extend` / `merge` / `deprecate` のいずれか**を自動判定する handler を所管する（Spec 1 Requirement 3 の frontmatter スキーマと整合、判定ロジックは drafts §7.2 Spec 7 の Dangerous op の分類表「promote-to-synthesis」=「最高 / 必須 / `--auto` 不可」に従い 8 段階対話を必ず経由する）。signature と判定アルゴリズム詳細は本 spec の design phase で確定すべき coordination 項目として明示する。

### Requirement 15: L3 診断 API の提供

**Objective:** As a Spec 4 起票者, I want Spec 4 Requirement 4.7 が要求する L3 診断項目（未 approve 件数 / audit 未実行期間 / deprecated chain 循環 / tag vocabulary 重複候補 / 未解決 follow-up）の計算 API が本 spec で提供責務として固定されている, so that Spec 4 の `rw doctor` / Maintenance UX / autonomous mode が L3 診断を一意の API 経由で実行でき、診断ロジックが Spec 4 と本 spec で重複しない。

#### Acceptance Criteria

1. The Lifecycle Manager shall L3 診断項目として (a) 未 approve 件数（`review/synthesis_candidates/*` / `review/vocabulary_candidates/*` / `wiki/.follow-ups/*` 等の未 approve エントリ件数）/ (b) audit 未実行期間（最終 audit 実行からの経過時間）/ (c) deprecated chain 循環（`successor:` field の循環参照検出）/ (d) tag vocabulary 重複候補（同一意味の tag 候補検出）/ (e) 未解決 follow-up（`status: open` の Follow-up タスク件数）の 5 項目を計算する API を提供する。
2. The Lifecycle Manager shall 各 L3 診断 API の返り値構造（件数 / 該当 path 配列 / severity / 最終実行日時等）を Spec 4 Requirement 4 の `rw doctor` および Requirement 8 の Autonomous Maintenance UX が利用可能な形で提供することを規定する。
3. The Lifecycle Manager shall L3 診断 API の名前 / signature / 返り値スキーマの確定を本 spec の design phase で行う coordination 項目として明示し、Spec 5 Requirement 20.8（L2 診断 API）と並列構造で定義する。
4. While `rw doctor` の CLI dispatch / 出力整形 / exit code 制御 / 並列診断 orchestration を扱う場合, the Lifecycle Manager shall それらが Spec 4 の所管であることを明示し、本 spec は計算 API 本体のみを提供する。
5. The Lifecycle Manager shall L3 診断 API が deprecated chain 循環検出時に `status: deprecated` ページの `successor:` field を辿り、循環が検出された場合に CRITICAL severity で報告する規約を本 spec の所管とする（Foundation Requirement 11 / Severity 4 水準と整合）。

### Requirement 16: Foundation 規範への準拠と文書品質

**Objective:** As a 本 spec の品質保証および将来の更新者, I want 本 spec が Foundation（Spec 0）の 13 中核原則・用語集・3 層アーキテクチャ・Page/Edge status の区別・dangerous op 共通ガイドラインを SSoT として参照し、CLAUDE.md の出力ルール（日本語・表は最小限・長文は表外箇条書き）に準拠する, so that 用語と原則の解釈が複数 spec で分岐せず、本 spec の可読性と運用整合性が保たれる。

#### Acceptance Criteria

1. The Lifecycle Manager shall Foundation の 13 中核原則のうち §2.3 status frontmatter over directory movement / §2.4 Dangerous operations 8 段階 / §2.5 Simple dangerous operations / §2.6 Git + 層別履歴媒体 / §2.10 Evidence chain / **§2.12 L2 専用優先関係（Page→Edge orchestration が L2 自律進化に立ち入らない原則）** / §2.13 Curation Provenance を本 spec の設計前提として参照することを明示する。
2. The Lifecycle Manager shall Foundation Requirement 5 の Page status 5 種を遷移対象として継承し、独自に状態を追加・改名しない（Requirement 1.1 と整合）。
3. The Lifecycle Manager shall Foundation Requirement 5 の Edge status 6 種を本 spec の所管外として扱い、Page→Edge 相互作用において Edge 内部状態遷移を独自定義しない（Requirement 3 / 12 と整合）。
4. The Lifecycle Manager shall 本 spec の requirements / design / tasks 文書を日本語で記述し、`spec.json.language=ja` および CLAUDE.md「All Markdown content written to project files MUST be written in the target language」要件に準拠する。
5. While 本 spec 文書中で表形式を用いる場合, the Lifecycle Manager shall 表は最小限に留め、長文・解説は表外の箇条書きまたは段落で記述する。
6. The Lifecycle Manager shall 運用前提（Python 3.10+ / git 必須 / LLM CLI subprocess timeout 必須 / Severity 4 水準 / exit code 0/1/2 分離）を Foundation Requirement 11 / roadmap.md「v1 から継承する技術決定」 経由で継承し、独自に再定義しない。
7. The Lifecycle Manager shall 本 spec 自身が `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §2.3 / §2.4 / §2.5 / §7.2 Spec 7 を SSoT 出典とすることを明示する。
8. If Foundation の用語・原則・マトリクスと矛盾する記述が本 spec に必要となった, then the Lifecycle Manager shall 先に Foundation を改版する手順（roadmap.md「Adjacent Spec Synchronization」運用ルール）を参照点として残し、本 spec を独自に逸脱させない。
9. The Lifecycle Manager shall 本 requirements が定める 16 個の Requirement の各々について、design 段階で「Boundary Commitments」として境界が再確認されることを前提とし、本 requirements の境界（in scope / out of scope / adjacent expectations）を design phase に渡せる形で固定する。

---

_change log_

- 2026-04-26: 初版生成 + 6 ラウンドレビュー反映（AC 数 96 → 112、Requirement 14 → 16）。
- 2026-04-27 (Adjacent Sync): Spec 2 レビュー由来の重-2 修正反映 — R12.7 を Skill 起源 3 種 → 4 種に再分類、`skill_install` を追加宣言（Spec 2 R12.4 が install 完了時の履歴保全で参照する起点として、Spec 5 R11.2 と同期宣言）。Adjacent Spec Synchronization 運用ルールに従い再 approval は不要、`spec.json.updated_at` 更新のみ。
- 2026-04-28 (本 spec design Round 3 重-3-4 由来): R12.7 を Page lifecycle 起源 6 種 → 7 種に拡張（`page_reactivate` を追加、挿入位置は `page_split` と `page_promote_to_synthesis` の間 = Requirement 3.8 の `update_history.type` 列挙順序と整合）。本拡張は本 spec design L551 の cmd_reactivate handler が `decision_type=page_reactivate` で記録する旨と、Spec 4 design L685-690 が同 type を含む旨との不整合を解消する目的で実施（design Round 3 重-3-4 ancillary 発見）。本 spec requirements 改版のため再 approval 必要。連動更新: Spec 5 R11.2 を 22 → 23 種拡張、Spec 5 R11.6 の `'retract'` → `'page_retract'` 改版（命名規則整合、本 spec design Round 1 重-1-2 由来）も同セッションで実施。
- 2026-04-27 (精査): Spec 2 第 1 ラウンド精査ラウンドで発見した連鎖更新漏れを修正 — Boundary Context line 61 の Spec 4 ↔ Spec 7 dispatch handler 列挙に `cmd_skill_install` を追加（R13.1 line 248 では既に含まれていたが Boundary Context は 3 種のみ列挙の不整合を解消）。R3.8 の update_history `type` 値「Skill lifecycle 起源 3 種」は status 遷移用 field の性質上 install を含めず現状維持（Spec 2 R3.1 が update_history を skill 必須に含めない事実とも整合）。
- 2026-04-27 (Adjacent Sync): Spec 2 第 5 ラウンド再精査由来 軽-B 案 (ii) 採択反映 — R3.8 の Skill lifecycle 起源 update_history 適用を v2 MVP 外として明示化（「Skill lifecycle 起源（`skill_deprecation` / `skill_retract` / `skill_archive`）も同じ pattern で本 spec が規定する」を削除し、「Skill ファイルには本 AC を v2 MVP では適用せず、Skill の lifecycle 履歴は `decision_log.jsonl` の Skill 起源 4 種で網羅する」に変更）。本変更により Spec 7 R3.8 の `skill_deprecation` 表記と R12.7 / Spec 5 R11.2 の `skill_deprecate` 表記との命名不一致も同時解消。Skill 履歴管理を `decision_log.jsonl` の Skill 起源 4 種（`skill_install` / `skill_deprecate` / `skill_retract` / `skill_archive`）に single source of truth として集約。Adjacent Spec Synchronization 運用ルールに従い再 approval は不要、`spec.json.updated_at` 更新のみ。
