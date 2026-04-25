# Rwiki v2 シナリオ仕様書（Draft v0.7.5）

**Version**: 0.7.5
**Date**: 2026-04-25
**Purpose**: Rwiki v2 の**ユースケース集**。各 Spec の requirements 起草時に「このシナリオをどう満たすか」の基点として参照される。

**Scope 契約（v0.7.3 確定）**:
- ✅ **本書に書く**: シナリオのみ（ユーザー意図・対話フロー例・ユーザー可視な入出力・シナリオ間連携・Dangerous op 分類）
- ❌ **本書に書かない**: ビジョン / アーキテクチャ / コマンド階層 / 中核原則 / Skill カタログ / Review layer 設計 / Dangerous op 8 段階チェックリスト / データ構造 / 閾値・数式 / API 設計 / 内部動作 / **CLI コマンドの正式シグネチャ・オプション flag・サブコマンド列挙** — 全て `rwiki-v2-consolidated-spec.md` および個別 Spec に所管
- 各 Scenario は「何のために、誰が、どう使うか」のみを示し、「どう実装するか」「どんなコマンド形式か」は対応 Spec 参照で委譲する
- コマンドは **ユーザーが呼ぶ意図** のリスト形式で記述し、`rw <command-name>` の抽象的な言及に留める

**Relation**: 本ドキュメントは `rwiki-v2-consolidated-spec.md` の姉妹資料。あちらが設計原則・アーキテクチャ・Spec 構成、こちらは**ユースケース集**。

---

参考情報：[仕様V2](rwiki-v2-consolidated-spec.md)



## 目次

1. [シナリオ一覧（索引）](#1-シナリオ一覧索引)
2. [知識の取り込み](#2-知識の取り込み)
3. [知識の生成](#3-知識の生成)
4. [既存知識の進化・編集](#4-既存知識の進化編集)
5. [品質管理・メンテナンス](#5-品質管理メンテナンス)
6. [活用・探索](#6-活用探索)
7. [運用・保守](#7-運用保守)
8. [L2 Graph Ledger 管理](#8-l2-graph-ledger-管理)
   - Scenario 34-38（entity/relation 抽出、reject workflow、Hygiene 実行、lifecycle 管理、events 監査）
9. [将来拡張](#9-将来拡張)
10. [シナリオ連携と改訂履歴](#10-シナリオ連携と改訂履歴)

> **重要**: 本書は **純粋にユースケース集**。ビジョン・アーキテクチャ・コマンド階層・中核原則・Skill カタログ・Review layer 設計・Dangerous op 8 段階チェックリスト等の**横断仕様は一切含まれない**。全て `rwiki-v2-consolidated-spec.md` および個別 Spec が所管する。シナリオ側に仕様を書き込むと requirements 起草時に混乱を招くため、記載は**ユーザー視点のフロー**のみに制限する。

---

## 1. シナリオ一覧（索引）

| # | タイトル | テーマ | Layer | 優先度 | 状態 | 主要 Spec |
|---|---------|------|------|------|------|---------|
| 7 | 既存 wiki 拡張 | 進化・編集 | L3 | MVP | 合意済 | 2, 4, 7 |
| 8 | synthesis 候補 merge | 進化・編集 | L2/L3 | MVP | 合意済 | 4, 7 |
| 9 | wiki ページ分割 | 進化・編集 | L3 / L2 振り分け | MVP | 合意済（v0.7.5、High gap 解消、Medium 残） | 7, 5 |
| 10 | audit ERROR 修正ループ（+ graph consistency） | 品質管理 | L2/L3 | MVP | 合意済（v0.7.1） | 7, 5 |
| 11 | archive / deprecation | 品質管理 | L3（+L2 edges 連動） | MVP | 合意済 | 7 |
| 12 | タグ vocabulary 管理 | 品質管理 | L3 | MVP | 合意済 | 1 |
| 13 | evidence 検証（+32 統合、evidence.jsonl） | 品質管理 | L2/L3 | MVP | 合意済（v0.7.1） | 7, 5 |
| 14 | perspective + hypothesis generation | 活用・探索 | L2 主 | MVP | **合意済（v0.7.1 簡略化完了）** | **6, 5** |
| 15 | interactive_synthesis | 生成 | L1→L3 | MVP | 合意済（25 と連携） | 2, 6 |
| 16 | query → synthesis 昇格 | 活用・探索 | L2/review→L3 | MVP | 合意済 | 2, 7 |
| 17 | daily note | 運用 | L1 | MVP | 合意済（エディタ委譲） | 0 |
| 18 | pre-flight check（+ L2 edge state） | 運用 | L2/L3 | MVP | 合意済（v0.7.1） | 7, 5 |
| 19 | rollback / unapprove | 運用 | L3 | MVP | 合意済 | 4, 7 |
| 20 | custom skill 作成 | 運用・拡張 | Meta | MVP | 合意済 | 2 |
| 25 | llm_log_extract | 生成 | L1→L3 | MVP | 合意済 | 2 |
| 26 | incoming lint-fail リカバリ | 取り込み | L0→L1 | MVP | 合意済（v0.7.5、High gap 解消、Medium 残） | 0, 4, 2 |
| 33 | メンテナンス UX 全般原則 | 運用 | All | MVP | 合意済（v0.7.1 L2 統合） | 0, 4 |
| **34** | **Entity/Relation 自動抽出** | **L2 管理** | **L1→L2** | **MVP** | **skeleton（v0.7.1、要件化待ち）** | **5, 2** |
| **35** | **Edge reject workflow** | **L2 管理** | **L2** | **MVP** | **skeleton（v0.7.1、要件化待ち）** | **5, 4** |
| **36** | **Graph Hygiene 実行** | **L2 管理** | **L2** | **MVP** | **skeleton（v0.7.1、要件化待ち）** | **5** |
| **37** | **Edge lifecycle 管理** | **L2 管理** | **L2** | **MVP** | **skeleton（v0.7.1、要件化待ち）** | **5, 7** |
| **38** | **Edge events 監査** | **L2 管理** | **L2** | **MVP** | **skeleton（v0.7.1、要件化待ち）** | **5** |
| 21 | 外部ソース自動取込 | 拡張・連携 | L0 | Future | 将来拡張 | — |
| 22 | 外部 Export | 拡張・連携 | L3→外部 | Future | 将来拡張 | — |
| 23 | 複数人 Vault | 拡張・連携 | All | Future | 将来拡張 | — |
| 24 | 複数 Vault 横断 | 拡張・連携 | All | Future | 将来拡張 | — |
| 27 | incoming 混在ディレクトリ | — | L1 | MVP | Spec 1 要件に統合 | 1 |
| 28 | vault スキーマ migration | 運用進化 | All | Future | 先送り | — |
| 29 | dirty tree 並行操作 | 運用進化 | All | Future | 将来拡張 | — |
| 30 | index/log 整合性 | — | L3 | MVP | Scenario 10 に統合 | 7 |
| 31 | vault ポータビリティ | 運用進化 | All | Future | 将来拡張 | — |
| 32 | raw dead-link / source chain | — | L1/L2 | MVP | Scenario 13 に統合 | 7, 5 |

**集計（v0.7.5 時点）**: MVP 対象 22 件（合意済 18、skeleton 5、未議論 0）、統合済 3 件、将来拡張 7 件、計 32 件。**全 MVP scenario が合意済 or skeleton に到達**。

**凡例**:
- **合意済**: ユーザーフローと spec 参照で要件化完了、`/kiro-spec-init` 起票可能
- **合意済（v0.7.X）**: 本版で L2 Graph Ledger 統合 / High gap 解消等の改訂を受けた scenario
- **skeleton**: フロー骨子は確定、詳細要件化は Phase B-2 以降
- ~~**未議論**~~（v0.7.5 で 0 件に到達）

---

## 2. 知識の取り込み

### Scenario 26: Incoming lint-fail 滞留リカバリ

**Status**: 合意済（v0.7.5、High gap 解消、Medium 残）  
**Priority**: MVP  
**Theme**: 取り込み  
**Related**: Scenario 10（audit ERROR 修正、層が違う）、Scenario 33（長期滞留の autonomous 通知）  
**Specs**: Spec 0 (lint policy), Spec 4 (CLI), Spec 2 (frontmatter_completion skill)

#### ユースケース

**User intent**: 一括投入した文書のうち、lint FAIL 分を滞留させず効率的に修復したい。  
**Trigger**: `rw lint` で FAIL が複数検出された後。  
**Context**: `raw/incoming/` に未検証文書が複数、一部は不備（frontmatter 欠損、空ファイル、形式崩れ）。

**典型シーン**:
- Zotero から 10 本の論文を export → 8 本は frontmatter 完備、2 本は不足
- ブレインダンプで 5 つの notes を書いた → 3 つが 80 文字未満で WARN、1 つが空で FAIL
- ユーザーは PASS 分だけ先に ingest したい、FAIL は後で修復したい

#### 対話フロー

```
You: 論文 10 本を raw/incoming/papers/local/ に入れた、lint して

Claude: [内部: rw lint]
  結果: 8 PASS / 1 WARN / 2 FAIL

  FAIL 対象（修復が必要）:
    - raw/incoming/papers/local/draft-2024.md  (empty file)
    - raw/incoming/papers/local/notes-a.md     (frontmatter not valid YAML)

  WARN（修復推奨）:
    - raw/incoming/papers/local/short-memo.md  (too short: 42 chars)

  選択肢:
    (a) PASS 分 8 本だけ先に ingest、FAIL は後で修復
    (b) 全件を一度に修復してから ingest
    (c) 各 FAIL を個別に対話で修復
  どうしますか？

You: (a)

Claude: [内部: rw ingest --only-pass]
  → 8 ファイルを raw/ に移動、FAIL/WARN は raw/incoming/ に残留
  → git commit "ingest: 8 files (2 pending FAIL in raw/incoming/)"

  FAIL 2 件は滞留中です。後で `rw lint --show-pending` で一覧できます。
```

#### 修復方法 (b)(c) の詳細（ユーザー視点）

**(b) 一括修復**: LLM が FAIL 全件を一気に分析し、修復案をまとめて提示

```
You: (b) 一括修復で

Claude: [内部: frontmatter_completion skill で各 FAIL に proposal 生成]

  修復提案:
    1. draft-2024.md (empty file)
       → 提案: 空ファイルは削除を推奨（誤作成と推測）
    2. notes-a.md (YAML 不正、tags: [foo, bar の閉じカッコなし)
       → 提案: tags: [foo, bar] に修正

  各提案の処理:
    [a] 全件採用（一括 fix）
    [b] 個別に確認（次の対話へ）
    [c] 部分採用（採用するものだけ番号で指示）

You: [a]

Claude: 2 件修正、再 lint で 10 PASS 確認、ingest 続行可能。
```

**(c) 個別対話**: ファイルごとに `rw chat` 内で深掘り修復

```
You: (c) 個別に

Claude: 1 ファイル目: draft-2024.md (empty)
  → 削除しますか？ それとも内容を書く予定ですか？

You: 削除して

Claude: [削除 + 次のファイル]
  2 ファイル目: notes-a.md (YAML parse error)
  問題箇所: line 3 'tags: [foo, bar' の閉じカッコ欠落
  修正案: tags: [foo, bar]
  どうしますか？
...
```

frontmatter_completion skill の詳細は **Spec 2 所管**。修復行為そのもの（提案採用 / 棄却）は **decision_log（§2.13）** に記録される。

#### Pending list 機構（ユーザー視点）

```bash
rw lint --show-pending   # 滞留中の FAIL/WARN 一覧
```

出力例:
```
滞留 FAIL 2 件 / WARN 1 件:
  draft-2024.md      empty file       3 日前から滞留
  notes-a.md         YAML parse error  3 日前から滞留
  short-memo.md      too short (warn)  3 日前から滞留

長期滞留（7 日超）: なし
```

長期滞留が一定件数を超えると Maintenance autonomous mode で通知（Scenario 33 連携）。

Pending list の記録 schema・retry 機構・autonomous 通知閾値は **Spec 0 / Spec 4 所管**。

#### ユーザーが呼ぶ意図

- 「incoming を検証したい」
- 「FAIL 滞留を一覧したい」
- 「特定ファイルを対話修復したい」
- 「PASS 分だけ先に取り込みたい」

CLI コマンド名・オプション・サブコマンド体系は **Spec 0 / Spec 4** 所管。

#### Dangerous op category

非 dangerous（raw/incoming/ は未検証層、git commit 前）

#### Edge cases（ユーザー視点）

- 全件 FAIL → ingest 対象 0 件（警告表示）
- FAIL 滞留が多数蓄積 → Maintenance autonomous mode で通知（Scenario 33 連携）
- 長期滞留（30 日超）→ 自動アーカイブ提案 or 削除促進
- WARN の扱い（default 通過 / strict モード）は Spec 0 参照
- Empty file → user に「削除 / placeholder として保持」を確認

#### 残 Medium gap（v0.8 候補）

- WARN の選択肢別扱いの細分化
- frontmatter_completion skill との連携の詳細仕様（prompt / output / validation）
- Curation Provenance での修復決定の記録粒度（個別 fix or batch fix で粒度が違う）

---

## 3. 知識の生成

### Scenario 15: 対話型 synthesis（interactive_synthesis）

**Status**: 合意済（詳細要件確定、2026-04-24、v0.7 軽微: L2 traversed_edges 記録を注記、2026-04-25）  
**Priority**: MVP  
**Theme**: 知識生成  
**Layer**: **L3 wiki 生成が主目的、L2 Graph Ledger は補助参照**  
**Related**: Scenario 14（perspective との境界）、Scenario 25（対話の二次利用で連携）、Scenario 34（対話が L2 抽出の素材になり得る）  
**Specs**: Spec 2 (skill), Spec 6 (autonomous mode 注入点)

**v0.7 注記**: 対話型 synthesis で L3 wiki 関連を参照した際、traversed edges の記録・reinforcement は Scenario 14 Perspective と同仕組み（詳細は consolidated-spec §5.9.2 / Spec 5 Graph Hygiene）。

---

#### 0. Scenario 14（perspective/hypothesize）との境界

| 軸 | Scenario 14 | Scenario 15 |
|----|------|------|
| **主な入力** | wiki/ のみ（既存知識） | raw/ の新規ソース + wiki 関連 + user 対話 |
| **目的** | 既存知識の深化・整理・検証 | 新知識の取り込み・構造化 |
| **対話の位置** | autonomous mode 時のみ | skill の core、常に対話型 |
| **出力** | stdout / hypothesis_candidates | review/synthesis_candidates/（新 wiki 候補） |
| **後続** | 記録任意 or 検証必須 | 通常の approve フロー（wiki 昇格） |

**原則**: 両者は**独立スキル、overlap 許容**。ユーザーが用途に応じて使い分ける。

---

#### ユースケース

**User intent**: 新しい概念・トピックを wiki に取り込む際、**自分の視点・既存理解を LLM に先に伝え**、それを反映した synthesis draft を作らせる。  
**Trigger**: ユーザーが「～を synthesis したい、でも先に自分の理解を整理したい」と発話。  
**Context**: raw/ に関連文書が ingest 済み、wiki/ に関連ページがいくつか存在。

**典型シーン**:
- "implicit neural representations" を wiki 化したいが、自分の興味領域（CV 応用）を反映させたい
- 論文 3 本 + 既存 wiki の関連ページを踏まえて、偏った視点ではなく自分の問題意識に沿った draft が欲しい
- 一問一答ではなく、往復を通じて draft を磨きたい

#### 1. 対話フロー（LLM 動的質問生成版）

**質問は固定ではなく**、LLM が raw ファイルと skill の `dialogue_guide:` から動的に生成。max 4 問（default、調整可）。

```
You: implicit neural representations について蒸留（distill）したい、
     raw/papers/local/{inr-sitzmann, inr-mildenhall, inr-tancik}.md が手元にある
     自分の理解を先に整理したい

Claude: [Stage 1: 意図確認 + コンテンツ判定]
  対話型 distill を行います。skill: interactive_synthesis
  [内部: 3 論文を軽く読んで raw のタイプ判定]
  → 判定: academic papers
  → 質問生成: 論文向けの 3 問を生成（max 4 設定）

  [Stage 2: 動的質問で視点収集]
  Q1. implicit neural representations を一言で言うと、あなたの中での
      位置付けは？

You: 従来の explicit な表現（mesh, voxel）と対比して、連続的な関数で
     信号を表現する手法全般

Claude: Q2. あなたが興味のある応用・使いどころは？

You: シーン再構成（NeRF 系）とコンピュータビジョン全般

Claude: Q3. 既存の wiki/ で関連しそうなページ、もしあれば教えてください
      （既に wiki/methods/nerf.md を発見済み、他にありますか？）

You: wiki/concepts/signed-distance-function.md も関連する

Claude: [Stage 3: Context 確認]
  理解したあなたの視点:
    - Explicit vs Implicit の対比構造
    - CV / Scene reconstruction 応用寄り
    - NeRF / SDF を関連ページとして参照

  この視点で draft を作成します。よろしいですか？

You: OK

Claude: [Stage 4: Draft 生成（対話中は autonomous 無効、静か）]
  [内部: 3 論文 + 関連 2 wiki を読込、user context を含めて generate]
  → review/synthesis_candidates/inr-with-user-context-2026-04-24.md 生成

  対話ログ自動保存:
  → raw/llm_logs/interactive/interactive_synthesis-20260424-153000.md

  [Stage 5: Draft 生成後の autonomous 挿入]
  💡 **関連観点**
    生成した draft は以下と類似しています:
    - wiki/synthesis/neural-field-representations.md が近い主題
    - merge を検討してください（`rw merge` または `rw extend --target`）

  Obsidian で確認・編集後、rw approve で wiki 昇格してください。

You: [確認・編集後 rw approve]
```

**注目点**:
- Stage 1 で LLM が raw タイプ判定 → 適切な質問生成（固定ではない）
- Stage 4（対話中）は autonomous mode 無効、静かに集中
- Stage 5（draft 生成後）に autonomous 挿入で関連性提示

---

#### 2. ユーザーが呼ぶ意図

- 「この素材を対話しながら synthesis したい」 → `rw distill ... --skill interactive_synthesis`

質問数調整・対話スキップ等のオプション、Skill frontmatter（`interactive`, `dialogue_guide`, `auto_save_dialogue` 等）、対象カテゴリ、対話ログ markdown フォーマットは **Spec 2 (skill)** 所管。

**Dangerous op category**: 非 dangerous（review 生成のみ、wiki/ 直接編集なし）

---

#### 3. 対話ログの保存先（ユーザー可視）

```
raw/llm_logs/
├── interactive/        # interactive_synthesis の対話ログ
├── chat-sessions/      # rw chat のセッションログ（Scenario 14）
└── manual/             # ユーザーが手動 export した対話
```

命名規則・対話ログの構造化 markdown スキーマ（type: dialogue_log、Turn 表現等）・auto-save 方針は **Spec 2** 参照。

---

#### 4. Autonomous mode との関係

| フェーズ | Autonomous mode |
|---------|----------------|
| Stage 1-3（意図確認・質問・context 確認） | 無効（意図引き出しに集中） |
| Stage 4（Draft 生成中） | 無効 |
| Stage 5（Draft 生成後） | 有効（関連性 surface） |

Stage 5 の挿入は Scenario 14 autonomous mode と同じ仕組み。

---

#### 5. Edge cases

- **wiki に関連ページがない**: raw/ のみで draft（警告付き）
- **ユーザーが Q を飛ばしたい**: `--skip-questions` で固定 skill 相当の挙動
- **途中で中断**: 対話ログは途中まで保存（再開機能は将来拡張）
- **max 質問数を超える需要**: `--max-questions N` で調整
- **対話中に autonomous を手動起動**: `/ask perspective`

---

#### 6. Scenario 25 との連携

`raw/llm_logs/interactive/*.md` は Scenario 25（llm_log_extract）で後日再処理可能:
- **即時**: wiki 候補として（content-centric）
- **後日**: 決定パターン・推論手順として（process-centric）

---

### Scenario 25: LLM 対話ログからの継続的知識化（llm_log_extract）

**Status**: 合意済（v0.7 軽微: L2 抽出連携を注記、2026-04-25）  
**Priority**: MVP  
**Theme**: 知識生成  
**Layer**: **L1 raw（対話ログ）→ L3 review（synthesis/query 候補）**、L2 relation 抽出も同素材から可能  
**Related**: Scenario 15（対話の二次利用で連携）、Scenario 34（同対話ログから extract-relations 実行可能）  
**Specs**: Spec 2

**v0.7 注記**: 同じ対話ログ（`raw/llm_logs/chat-sessions/`）は `rw extract-relations` の入力にもなり得る（Scenario 34）。本 scenario は review/synthesis_candidates/ 生成に特化、L2 edge 抽出は Scenario 34 所管。

#### ユースケース

**User intent**: 日常的に LLM（Claude / ChatGPT 等）と行った研究議論から、**再利用可能な判断・設計パターン・推論手順**を抽出して蓄積する。  
**Trigger**: 対話セッション完了後、手動で distill 実行、または週次バッチ。  
**Context**: `raw/llm_logs/` に対話ログが蓄積。以下 3 つのサブディレクトリに分類（Scenario 15 で確定）:
- `raw/llm_logs/interactive/` — interactive skill の対話ログ（自動保存）
- `raw/llm_logs/chat-sessions/` — `rw chat` セッションログ（自動保存、Scenario 14）
- `raw/llm_logs/manual/` — 手動 export の対話ログ

**典型シーン**:
- ChatGPT で 30 分討議して design 決定を下した → ログを残して決定事項を構造化
- `rw chat` での対話中に重要なパターンを発見した → 後日整理
- Scenario 15 の対話ログが積み上がった → 月次で extract して synthesis 候補化

#### 対話フロー（最小）

```
You: raw/llm_logs/manual/2026-04-20-claude-session-architecture.md を distill

Claude: [内部: rw distill raw/llm_logs/manual/2026-04-20-claude-session-architecture.md
                 --skill llm_log_extract]
  → review/synthesis_candidates/architecture-decisions-2026-04-24.md 生成

  出力形式（llm_log_extract スキル）:
    ## Summary
    ## Decision: <何を決めたか>
    ## Reason: <理由・根拠>
    ## Alternatives considered: <却下案>
    ## Reusable Pattern: <他に応用可能な原理>

  Obsidian で確認、approve で wiki/synthesis/ or wiki/entities/people/<user>.md
  に昇格可能です。
```

#### ユーザーが呼ぶ意図

- 「手動 export した対話ログを知識化したい」
- 「直近の対話をまとめて再処理したい」

対象ファイル指定・期間フィルタ・Skill 定義（対話ログ形式の判別ロジック、Claude Code / ChatGPT / 自由形式の扱い）は **Spec 2** 所管。

**昇格先**: `wiki/synthesis/`（再利用可能パターン）または `wiki/entities/people/<user>.md`（思考履歴）

**Dangerous op category**: 非 dangerous

#### Edge cases

- **対話ログが長い（100k+ tokens）**: 段階的要約、セクション単位の extract
- **対話が分岐している**: 決定に至らなかった支脈も「Alternatives」に含める
- **複数セッション統合**: 同トピックの複数ログを `rw merge` で統合

#### Scenario 15 との連携（再掲）

**自動保存された対話ログ**（`raw/llm_logs/interactive/*.md` および `raw/llm_logs/chat-sessions/*.md`）を後日 llm_log_extract で再処理可能。この連携により「同じ対話から content と process の両方を抽出」が実現。

---

## 4. 既存知識の進化・編集

### Scenario 7: 既存 wiki ページへの追記

**Status**: 合意済  
**Priority**: MVP  
**Theme**: 進化・編集  
**Related**: Scenario 8（merge）、Scenario 11（deprecate）  
**Specs**: Spec 2, 4, 7

#### ユースケース

**User intent**: 既存 wiki ページに新情報（新しい論文、追補事項）を追加したい。元ページの構造は尊重しつつ、追加部分を明示的に区別したい。  
**Trigger**: ユーザーが「wiki/methods/sindy.md に ～ を追記したい」と発話。  
**Context**: 対象 wiki ページが存在、追加ソースが raw/ に ingest 済み。

**典型シーン**:
- SINDy の新しい拡張論文（SINDy-MPC）を読んだ → 既存 sindy.md に章追加
- 概念の定義を精緻化する新しい引用が見つかった → 既存 concepts/xxx.md の該当段落を強化
- 会議で聞いた話を既存の projects/xxx.md の進捗セクションに追加

#### 対話フロー

```
You: wiki/methods/sindy.md に sindy-mpc の新情報を追記したい

Claude: [確認]
  raw/papers/local/sindy-mpc-2024.md を追加ソースとしますか？

You: はい

Claude: [Stage 1-5: 差分生成]
  [内部: rw extend raw/papers/local/sindy-mpc-2024.md \
            --target wiki/methods/sindy.md \
            --skill paper_summary]
  → review/synthesis_candidates/sindy-update-2026-04-24.md 生成
    （差分マーカー付き全文形式、target = wiki/methods/sindy.md）

  差分:
    <!-- BEGIN UPDATE: sindy-mpc-addition [2026-04-24] -->
    ## SINDy-MPC
    SINDy を Model Predictive Control に統合した拡張...
    [evidence: raw/papers/local/sindy-mpc-2024.md]
    <!-- END UPDATE -->

  修正方法:
    (1) ここで対話指示（細かな修正）
    (2) Obsidian で直接編集
    (3) 両方混ぜて OK

You: (1) "SINDy-MPC" を "SINDy for Model Predictive Control" と略さないで

Claude: 修正しました。確認してください。
  最終的に `rw approve` で wiki/methods/sindy.md に統合されます。
```

#### ユーザーが呼ぶ意図

- 「既存 wiki ページに新 raw の内容を追記したい」 → `rw extend`
- 「候補を本体に統合したい」 → `rw approve` または `rw merge`

差分マーカー形式・Obsidian preview での振る舞い・approve 時の解釈・`update_history:` 記録・extend 系 skill の一覧は **Spec 2 / Spec 4 / Spec 7** 所管。

**Dangerous op category**: 非 dangerous（簡易対話、approve で可逆）

#### Edge cases（ユーザー視点）

- **差分マーカー競合**: 2 人同時 extend → approve 時に conflict 表示（将来のマルチユーザー対応）
- **target が deprecated**: extend 前に警告、successor への転送提案
- **大規模変更（ページの大部分を書き換える場合）**: extend ではなく restructure 系 merge を推奨

---

### Scenario 8: 複数 synthesis 候補の merge

**Status**: 合意済  
**Priority**: MVP  
**Theme**: 進化・編集  
**Related**: Scenario 7  
**Specs**: Spec 4, 7

#### ユースケース

**User intent**: 同じトピックで複数の synthesis 候補が生成されてしまった場合、1 つに統合したい。  
**Trigger**: ユーザーが「candidate-a と candidate-b を merge」と発話、または audit が重複検出。  
**Context**: review/synthesis_candidates/ に同トピックの候補が 2+ 件存在。

**典型シーン**:
- 論文 A と 論文 B を別々に distill → 同じ概念を別ページにしてしまった
- 先月の synthesis 候補と今月の候補に重複 → 統合したい
- interactive_synthesis と paper_summary の出力を組み合わせたい

#### Merge の 4 タイプ

| タイプ | 戦略 | 例 |
|-------|------|-----|
| Complementary | 両視点を統合 | method 寄り + application 寄り → 両方を含む |
| Dedup | 重複除去 | 80% 同じ → 差分のみ統合 |
| Canonical-biased | 一方を正とする | A を canonical、B の補足を追加 |
| Restructure | 新構造で再編成 | 両方破棄、完全に新しい章立て |

#### 対話フロー（8 段階）

**Stage 1 意図確認 → Stage 2 Semantic diff → Stage 3 矛盾解決 → Stage 4 Evidence 統合 → Stage 5 構造選択 → Stage 6 Pre-flight → Stage 7 差分生成 → Stage 8 レビュー**

（詳細は `rwiki-v2-consolidated-spec.md` §3.3 参照）

#### ユーザーが呼ぶ意図

- 「複数 synthesis 候補を 1 つに統合したい」 → `rw merge`
- 「統合結果を事前に確認したい」 → merge preview
- 「未 approve merge を取消したい」 → merge cancel

merge strategy の列挙、preview / cancel のサブコマンド体系、frontmatter スキーマ（`merged_from`, `merge_strategy`, `merge_conflicts_resolved` 等）、review merge と wiki merge の backlinks 解析差は **Spec 4 / Spec 7** 所管。

**Dangerous op category**: review merge は中（8 段階対話）、wiki merge は高（backlinks 解析追加）

#### Edge cases（ユーザー視点）

- **3 件以上の merge**: 並列分析可能だが、件数過多時は警告
- **矛盾が解決不能**: 「両論併記」で `[INFERENCE]` マーカー付き表記
- **evidence 重複**: 統合、片方にしかない evidence は和集合で保持

---

### Scenario 9: 肥大化した wiki ページの分割

**Status**: 合意済（v0.7.5、High gap 解消、Medium 残）  
**Priority**: MVP  
**Theme**: 進化・編集  
**Layer**: L3 wiki 中心、L2 edges 振り分けと L3 trust chain 保全を伴う  
**Related**: Scenario 11（archive、元ページの処遇）、Scenario 8（merge、逆操作）、Scenario 10（audit でも検出）  
**Specs**: Spec 7（中心）、Spec 5（L2 edges 振り分け API）

#### ユースケース

**User intent**: 時間と共に大きくなった wiki ページを意味的な単位で分割し、可読性と再利用性を回復したい。  
**Trigger**: `audit structure` で `page_too_large` 警告、またはユーザーが手動で判断。  
**Context**: wiki/ の 1 ページが 3000 行超など、肥大化。

#### 対話フロー（8 段階、概略）

```
You: wiki/methods/sindy.md が 5000 行超えた、分割したい

Claude: [Stage 1-3: 構造分析と分割案生成]
  [内部: rw split wiki/methods/sindy.md --skill concept_map]

  構造分析結果:
    - "## Core Algorithm": 800 行（基本原理）
    - "## Extensions": 1500 行（E-SINDy, SINDy-MPC 等）
    - "## Applications": 1200 行（実例）
    - "## Implementation notes": 600 行
    - ...

  分割案（初回提案）:
    1. wiki/methods/sindy.md (1200 行、概要・基本アルゴリズム)
    2. wiki/methods/sindy-extensions.md (1500 行、拡張アルゴリズム群)
    3. wiki/methods/sindy-applications.md (1200 行、実例)
    4. wiki/methods/sindy-implementation.md (600 行、実装詳細)

  この分割で進めますか？ それとも構造を調整？

You: 2 と 3 を 1 つにまとめて

Claude: [再計算]
  分割案 B:
    1. wiki/methods/sindy.md (1200 行)
    2. wiki/methods/sindy-advanced.md (2700 行、拡張 + 応用)
    3. wiki/methods/sindy-implementation.md (600 行)

  これで進めますか？

You: OK

Claude: [Stage 4-5: 参照元解析 + L2 edges 振り分け + 差分生成]

  L3 backlinks 解析:
    元 wiki/methods/sindy.md への wiki 内参照 42 件を検出。
    分割後の振り分け:
      - 「SINDy の概要」言及 20 件: 新 wiki/methods/sindy.md で継続
      - 「SINDy-MPC」言及 8 件: sindy-advanced.md に向ける
      - 「SINDy 実装例」言及 3 件: sindy-implementation.md に向ける
      - 曖昧 11 件: 要確認（Stage 5 個別判断）

  L2 edges 振り分け（Spec 5 API 経由）:
    元 wiki/methods/sindy.md を source / target に持つ edges 38 件:
      - 「概要」関連の edge（数学基盤、入門的関係）22 件 → 新 sindy.md
      - 「Extensions」関連 edge（E-SINDy 等への extended_by）9 件 → sindy-advanced.md
      - 「Implementation」関連 edge 4 件 → sindy-implementation.md
      - 不明 3 件: 個別判断
    各 edge の evidence_ids は分割後ページにも継承（trust chain 保全）。

  Trust chain への影響:
    元ページの sources（raw/papers/local/brunton-2016.md 等 5 件）は
    全分割後ページに**複製継承**（同じ raw が複数 wiki ページに裏付けを与える）。
    L2 evidence.jsonl の関連 evidence_id は影響なし（raw は変わらないため）。

  review/synthesis_candidates/ に生成:
    - sindy-split-new-overview.md
    - sindy-split-new-advanced.md
    - sindy-split-new-implementation.md
    - backlinks-update-XXX.md × N
    - edge_redistribution-sindy-2026-04-25.md ★ L2 振り分け案

  Curation Provenance（§2.13）への記録:
    decision_log に以下を記録予定（approve 時確定）:
      - decision_type: split
      - subject_refs: [wiki/methods/sindy.md, sindy-advanced.md, sindy-implementation.md]
      - reasoning: "Core 概念 / 拡張 / 実装の 3 軸で分離。User が
                    Extensions と Applications を統合判断（chat session 参照）"
      - alternatives_considered: [4-way 分割案 (rejected by user)]
      - context_ref: raw/llm_logs/chat-sessions/chat-<ts>.md

  曖昧 14 件（L3 11 + L2 3）について個別確認が必要です...（Stage 5）
```

#### Trust chain と L2 edges の保全（v0.7.5 明確化）

分割は L1 raw → L2 ledger → L3 wiki の trust chain を破壊しない設計:
- **L1 raw**: 変更なし（元 source ファイルは保持）
- **L2 evidence.jsonl**: 変更なし（evidence そのものは raw 由来で不変）
- **L2 edges.jsonl**: 元ページ id を持つ edges を分割後ページに振り分け、`split_event` を edge_events.jsonl に記録（type: split_origin / split_target）
- **L3 wiki**: 元ページが分割後ページに分割、各分割後ページが元の sources を継承

**Audit による検証**: 分割後に `rw audit graph` で trust chain 整合性を verify、dangling evidence なきことを確認。

#### ユーザーが呼ぶ意図

- 「肥大化した wiki ページを分割したい」 → `rw split`

自動クラスタリング等のオプション、Skill 選択（構造分析系）、backlinks 解析、L2 edges 振り分け API、`superseded_by:` frontmatter、分割判断基準（行数閾値）、follow-up 追跡は **Spec 7** 所管。L2 edges 振り分けの API spec は **Spec 5 所管**（既存 `normalize_frontmatter` の拡張または別 API）。

**Dangerous op category**: 高（8 段階 + backlinks 解析 + L2 edges 振り分け + Curation Provenance reasoning 必須）

#### Edge cases

- **参照元が大量（100+）**: 一括更新時の commit 分割戦略（Spec 7 所管）
- **分割境界が曖昧**: LLM が人間判断を求める（Curation Provenance に判断理由が記録される）
- **既に synthesis に統合されている内容**: `wiki/synthesis/` 側も連動更新必要、audit で検出
- **L2 edges 振り分けが曖昧**: 各 edge の evidence を見て user が個別判断、または複数ページに複製継承
- **段階的分割が必要な場合**: 1 回目で粗い分割、後日 audit で細分化提案（v0.8 候補、Medium gap）

#### 残 Medium gap（v0.8 候補）

- 分割閾値の default 値（3000 行 / 5000 行 等）の合意 → Spec 7 起票時に決定
- 段階的分割 vs 一括分割の選択 UI
- L3 `related:` cache invalidation の挙動（通常の stale_pages mechanism で十分か検証）
- 外部参照（source URL）の振り分けポリシー
- 自動 trigger（audit 警告）vs user 主導の default
- Hypothesis / Perspective scoring への影響（分割後ページの novelty / recency 計算リセット？）

---

## 5. 品質管理・メンテナンス

### Scenario 10: audit ERROR 修正ループ（+ index/log 整合性、v0.7 graph consistency 統合）

**Status**: 合意済（v0.7 更新、L2 Graph consistency を統合、2026-04-25）  
**Priority**: MVP  
**Theme**: 品質管理  
**Layer**: **L3 wiki 中心、L2 Graph Ledger consistency も対象**  
**Related**: Scenario 26（raw 層 fix loop 対比）、Scenario 13（evidence）、Scenario 38（edge events 監査）  
**Specs**: **Spec 7**（中心）、**Spec 5**（L2 consistency）

#### ユースケース

**User intent**: audit が検出した wiki 層 + L2 Graph Ledger の ERROR を効率的に修復。自動修正可能なものは一括、人間判断要のものは個別確認。  
**Trigger**: 各種 audit tier（links / structure / semantic / strategic / deprecated / tags / evidence / graph）で ERROR 検出。audit コマンドの tier 分類は Spec 7 所管。  
**Context**: L3 wiki / L2 Graph Ledger の定期監査で問題が浮上。

**Scenario 13 との責務分離**: 本シナリオは `rw audit graph` = **L2 graph の構造整合性**（L3 `related:` cache との乖離、edge_events の矛盾、rejected 再出現）を第一次検出する。Evidence そのものの健全性（dangling evidence の raw 参照死活、URL 404、L1→L2→L3 の trust chain 分断）は **Scenario 13 の `rw audit evidence`** が所管。**L2 dangling evidence 参照**のみ両シナリオの重複領域で、本シナリオは「graph 側で dangling を検知 → 深掘りは Scenario 13 に誘導」という第一次通知役を担う。

#### 典型的な ERROR 種類

| 種類 | audit tier | auto-fix 可能？ |
|------|----------|--------------|
| リンク切れ (`[[nonexistent]]`) | links | 部分（近似候補提示） |
| frontmatter YAML error | links | ✓（quote 補完等） |
| index.md 未登録 | structure | ✓ |
| log.md エントリ欠落 | structure | △（承認フロー経由） |
| 孤立ページ | structure | ✗（人間判断） |
| 命名規則違反 | structure | ✓（rename 提案） |
| 定義の矛盾 | semantic | ✗ |
| deprecated chain 循環 | deprecated | ✗ |
| タグ vocabulary 違反 | tags | ✓（エイリアス置換） |
| source URL 404 | evidence | ✗ |
| **L2 edges.jsonl の dangling evidence 参照** | **graph** | △（evidence 復元 or edge 切断、要判断） |
| **L2 edge_events.jsonl の矛盾**（reject 済 edge の reinforcement event 等） | **graph** | ✗（人間判断） |
| **rejected_edges の再出現** | **graph** | △（再 reject or 方針見直し） |
| **L3 wiki `related:` cache と L2 ledger 乖離** | **graph** | ✓（ledger から sync） |

#### 対話フロー

```
You: 最近の audit で ERROR 出てたから修正したい

Claude: [内部: 最新の audit_latest.json を読込]

  直近の audit 結果:
    audit structure (2026-04-23): ERROR 5, WARN 8

  ERROR 内訳:
    1. wiki/concepts/x.md: [[nonexistent-page]] リンク切れ (auto-fix 不可)
    2. wiki/methods/y.md: YAML frontmatter パースエラー (auto-fix 可)
    3. wiki/projects/z.md: index.md に未登録 (auto-fix 可)
    4. wiki/entities/a.md: 命名規則違反 (CamelCase → kebab-case) (auto-fix 可)
    5. wiki/synthesis/b.md: 定義矛盾 (auto-fix 不可、semantic layer)

  修復方針:
    (A) auto-fix 可能な 3 件を一括修復、残り 2 件は個別対応
    (B) 全て個別確認して対応
    (C) auto-fix のみ

You: (A)

Claude: [Stage 1: Auto-fix]
  [内部: rw audit-fix --auto-fixable-only]
  → review/audit_candidates/auto-fix-2026-04-24.md に 3 件の修復 diff 生成

  Obsidian で確認、OK なら approve で反映。

You: [確認後] approve

Claude: [内部: rw approve]
  → 3 件修復完了、git commit
  
  残り 2 件の対応:
    1. [[nonexistent-page]] — リンク先の候補:
       - wiki/methods/actually-existing.md (類似度 85%)
       - [削除を提案]
    5. 定義矛盾 — wiki/concepts/a.md と wiki/synthesis/b.md で
       「sparse regression」の定義が食い違う。
       - (i) b を updated、
       - (ii) a を updated、
       - (iii) 両論併記、
       - (iv) follow-up として記録（後日対応）

    どうしますか？

You: 1 は削除、5 は follow-up に

Claude: [内部: 削除差分 + follow-up 記録]
  → review/audit_candidates/links-fix-2026-04-24.md
  → wiki/.follow-ups/2026-04-24-sparse-regression-definition-conflict.md

  approve で反映します。
```

#### graph audit 対話フロー例（v0.7 新規）

```
You: graph 層の audit もかけたい

Claude: [内部: rw audit graph]

  L2 Graph Ledger consistency:
    総 edges 380 / 総 evidence 542
    ◎ 正常: 365 edges, 537 evidence
    ⚠ 警告:
      - dangling evidence 参照: 5 edges
      - rejected 再出現: 1 edge (sindy→transformer)
    ✗ エラー:
      - L3 wiki `related:` と L2 ledger の乖離: wiki/methods/sindy.md
      - edge_events.jsonl 矛盾: reject 済 e_099 に reinforcement event

  修復方針:
    (A) wiki `related:` を L2 ledger から再 sync（auto-fix）
    (B) dangling evidence は個別判断（Scenario 13 連携）
    (C) rejected 再出現は Scenario 35 reject workflow に送付
    (D) edge_events 矛盾は Scenario 38 で履歴確認

You: (A) から
...
```

#### 技術基盤（詳細は Spec 7 / Spec 5 参照）

- Commands 一覧、auto-fix 判定、review/audit_candidates/ フロー → **Spec 7**
- `rw audit graph` の consistency チェック内容、dangling 検出、L3↔L2 sync → **Spec 5 Graph Hygiene + §5.10**
- index.md / log.md の CLI-MANAGED / 手動領域分離（HTML コメントマーカー方式） → **Spec 7**
- 連鎖 ERROR dry-run、パターン化一括適用、audit 結果 staleness 対策 → **Spec 7**

#### Dangerous op category

- **wiki auto-fix 一括**: 軽量（review/audit_candidates/ 経由）
- **graph auto-fix（related sync 等）**: 軽量（L2 ledger が source of truth、wiki は cache）
- **L2 ledger 直接修復**: 無（edge 切断等は必ず Scenario 35 経由で reject → re-extract）

#### シナリオ間連携

- **Scenario 13 (evidence 検証)**: dangling evidence 検出の一次情報源
- **Scenario 26 (incoming lint-fail)**: raw 層の fix loop と対比（本 scenario は L2/L3 担当）
- **Scenario 35 (edge reject workflow)**: rejected 再出現はここに送付
- **Scenario 36 (Graph Hygiene)**: consistency 修復後の confidence 再計算トリガ
- **Scenario 38 (edge events 監査)**: edge_events.jsonl 矛盾はここで履歴確認

---

### Scenario 11: Archive / Deprecation

**Status**: 合意済  
**Priority**: MVP  
**Theme**: 品質管理  
**Related**: Scenario 7, 8, 9  
**Specs**: Spec 7

#### ユースケース

**User intent**: 古くなった・誤った・終了した wiki ページを適切に処遇する。状態を明示し、参照元を誘導し、歴史記録として保全する。  
**Trigger**: ユーザーが「このページもう使わない」と発話、または audit が提案。  
**Context**: wiki ページが不要または無効化した。

#### 4 つの状態

| status | 意味 | 警告 | 検索対象 |
|--------|------|------|---------|
| active | 現役（default） | なし | 対象 |
| deprecated | 古いが歴史として残す | ⚠ 警告 blockquote | 対象（新ユーザーには警告） |
| retracted | 主張無効（ソース撤回等） | 🚨 強警告 | 完全除外 |
| archived | プロジェクト終了等、非活性 | 📦 軽い note | 履歴として検索可 |

#### 対話フロー（8 段階）

詳細は `rwiki-v2-consolidated-spec.md` § Scenario 11 参照。概要：

1. 意図確認（deprecate / retract / archive / merge）
2. 現状把握
3. 依存グラフ解析（参照元列挙 + 重要度評価）
4. 代替案提示（successor）
5. 各参照元の個別判断
6. Pre-flight warning
7. 差分プレビュー生成
8. レビュー → approve

#### ユーザーが呼ぶ意図

- 「古い記述を非推奨にしたい（後継を指す）」 → `rw deprecate`
- 「誤情報を撤回したい」 → `rw retract`
- 「今は使わないが残したい」 → `rw archive`
- 「deprecate/archive を取り消したい」 → `rw reactivate`

引数・オプション（理由・successor 指定・auto 許可の区別）、Frontmatter スキーマ（`status`, `status_changed_at`, `status_reason`, `successor`）、警告 blockquote 挿入、参照元更新差分生成は **Spec 7** 所管。

**Dangerous op category**: 
- deprecate: 中（8 段階）、auto 許可
- retract: 高（8 段階必須）、auto 不可
- archive: 低（対話推奨）、auto 許可
- reactivate: 低（簡易 confirm、Simple dangerous op）

#### Follow-up タスク連携

対話中に「後日判断」とした項目は `wiki/.follow-ups/` に記録、follow-up 管理コマンドで一覧化（コマンド仕様は Spec 7）。

---

### Scenario 12: タグ vocabulary 管理

**Status**: 合意済（v0.7 軽微更新、2026-04-25）  
**Priority**: MVP  
**Theme**: 品質管理  
**Layer**: L3 wiki（tags.yml、L2 の typed edges とは独立）  
**Related**: Scenario 10（audit tags）、Scenario 34（タグは edge relation_type とは別概念）  
**Specs**: Spec 1

#### ユースケース

**User intent**: 時間と共に乱立するタグを整理し、vocabulary の一貫性を保つ。  
**Trigger**: ユーザーが「タグ整理したい」と発話、または `rw audit tags` が問題検出。  
**Context**: tags が数十〜数百、同義語・表記揺れ・単発タグが混在。

#### 問題類型

1. 同義語並存（ml / machine-learning / ML）
2. 類義語の過剰分割（dl / deep-learning / DNN）
3. 単数・複数揺らぎ（paper / papers）
4. 表記揺れ（CamelCase、空白）
5. 言語混在（paper / 論文）
6. 単発タグ（typo or 意図的？）
7. 意味ドリフト
8. 階層不明示

#### 対話フロー（8 段階）

詳細は `rwiki-v2-consolidated-spec.md` § Scenario 12 参照。

#### ユーザーが呼ぶ意図

- 「問題タグを洗い出したい」 → scan
- 「タグの使用統計を見たい」 → stats
- 「2 タグの類似度を見たい」 → diff
- 「同義語を canonical に統合したい」 → merge
- 「多義タグを分割したい」 → split
- 「改名／非推奨／新規登録したい」 → rename / deprecate / register
- 「vocabulary 本体を見たい・編集したい」 → vocabulary サブコマンド
- 「対話的に整理セッションを走らせたい」 → review

各サブコマンドの正式 CLI 形、`.rwiki/vocabulary/tags.yml` スキーマ（canonical / description / aliases / parent / deprecated_tags）、review/vocabulary_candidates/ フロー、一括 approve 設計は **Spec 1** 所管。

**Dangerous op category**: 中〜高（tag split は必須対話、merge は簡易）

---

### Scenario 13: Evidence 検証（+ Raw data dead-link / Scenario 32 統合、v0.7 L2 対応）

**Status**: 合意済（v0.7 更新、L2 evidence.jsonl を一級市民として統合、2026-04-25）  
**Priority**: MVP  
**Theme**: 品質管理  
**Layer**: **L1 raw / L2 Graph Ledger / L3 wiki の 3 層全体を検証**  
**Related**: Scenario 10（audit ERROR）、Scenario 36（Graph Hygiene）、Scenario 38（Edge events 監査）  
**Specs**: **Spec 7**（中心、audit）、**Spec 5**（L2 Graph Ledger）

#### ユースケース

**User intent**: Trust chain 全体（raw → graph ledger → review → wiki）の健全性を検証し、死リンク・消失 raw・evidence と edge の乖離・rejected edge 再出現を検出する。  
**Trigger**: `rw audit evidence` 実行、または定期 audit。  
**Context**: L1 raw / L2 Graph Ledger / L3 wiki が蓄積、source ポインタや evidence 参照が古くなる可能性。

**Scenario 10 との責務分離**: 本シナリオは `rw audit evidence` = **evidence chain そのもの**（raw ファイル／URL の死活、dangling evidence の深掘り調査、L1→L2→L3 の trust 分断検出、re-archive 判断）を所管。Graph の構造整合性（L3 `related:` cache 乖離、edge_events の矛盾、rejected 再出現）は **Scenario 10 の `rw audit graph`** が所管。**L2 dangling evidence 参照**のみ両シナリオの重複領域で、本シナリオは「第一次通知を Scenario 10 から受け取り、evidence 復元 / edge 切断の判断を深掘り」する役割を担う。

#### 検証対象（3 層 + L2 Ledger 統合）

```
L1 raw/  ←─── source ファイル／URL
  ↓
L2 .rwiki/graph/  ←─── evidence.jsonl / edges.jsonl / edge_events.jsonl
  ↓
L3 review/ → wiki/  ←─── sources / merged_from / related
```

各段階で検証:

1. **L3 wiki → L1 raw ポインタ生存**: wiki `source:` が raw/ パスを指す場合、ファイルが存在するか
2. **L1 raw URL 生存**: raw/ ページの `source:` が URL の場合、到達可能か
3. **L3 review chain**: wiki の `merged_from:` や synthesis の `sources:` が存在するか
4. **L3 query artifacts の evidence.md**: 各引用の source が有効か
5. **L2 evidence.jsonl ↔ L1 raw 整合**: L2 evidence が参照する raw ファイル／URL の生存
6. **L2 edges.jsonl の evidence_ids 整合**: dangling 参照（消失 evidence への参照）の検出
7. **L2 rejected_edges.jsonl の再出現**: 過去に reject 済の edge が自動抽出で再出現していないか

#### 対話フロー

```
You: evidence chain の健全性チェックしたい

Claude: [内部: rw audit evidence --check-all]

  検証結果 (2026-04-25):
    L1 raw   : 正常 212 / dead-link 警告 3 / エラー 1
    L2 graph : evidence 542 / edges 380
               dangling evidence 警告 5 / 消失 raw 参照エラー 2
               rejected 再出現（要確認）1
    L3 wiki  : 正常 528 / 参照切れエラー 3

  エラー詳細:
    L1-1. raw/papers/local/old.md: wiki/methods/xyz.md の source が参照、実体不在
    L2-1. .rwiki/graph/evidence.jsonl ev_221: 参照先 raw/blog/post-2023.md 消失
    L2-2. .rwiki/graph/edges.jsonl e_154: evidence_ids に dangling 参照 [ev_089]
    L2-3. rejected_edges.jsonl r_012（sindy→transformer）が candidate edge として再出現
    L3-1. wiki/synthesis/def.md sources: [wiki/methods/deleted-xyz.md] 存在しない

  対応方針の概要:
    L1 dead-link   → raw/ 検索・URL archive・明示削除
    L2 dangling    → evidence 復元 or edge 切断（要判断）
    L2 再出現      → Scenario 35 reject workflow で再 reject or 方針見直し
    L3 参照切れ    → wiki 側の参照修正 or synthesis 更新

  個別に見ていきますか？ (L1 / L2 / L3 / all)

You: L2 から
...
```

#### 技術基盤（詳細は Spec 7 / Spec 5 参照）

- Commands, URL 生存確認方針、リトライ・タイムアウト、dead 判定ロジック → **Spec 7**
- L2 evidence.jsonl / edges.jsonl / rejected_edges.jsonl の整合性チェック → **Spec 5 Graph Hygiene + §5.10**
- `review/audit_candidates/` への修復 diff 生成、承認フロー → **Spec 7**
- Rejected edge 再出現時の扱い → **Scenario 35（Edge reject workflow）**

#### Dangerous op category

- **個別修復**: 非 dangerous（review/audit_candidates/ に diff 生成のみ）
- **一括修復の承認**: 中（通常の approve と同等、Scenario 11 dangerous op 原則準拠）
- **L2 ledger への直接書込**: 無（修復は必ず diff 経由、approve 必須）

#### Edge cases

- **URL 一時ダウン**: `last_checked` と `failed_count` を記録、連続 3 回失敗で dead 判定（詳細は Spec 7）
- **raw ファイル rename**: Git history から元 hash を検索、自動 rename 提案
- **L2 evidence 復元不可**: 該当 edges の evidence_ids から除外、confidence 再計算を促す（Hygiene 連携）
- **rejected edge 再出現**: LLM 抽出が reject 理由を学習していない場合、skill 側の improvement 候補として `review/skill_candidates/` に記録

#### シナリオ間連携

- **Scenario 10 (audit ERROR)**: Evidence 検証で発見した ERROR は通常の audit 修正ループに合流
- **Scenario 35 (Edge reject workflow)**: rejected 再出現は reject queue の再評価対象
- **Scenario 36 (Graph Hygiene)**: dangling evidence は Hygiene サイクルの confidence 再計算のトリガ
- **Scenario 38 (Edge events 監査)**: edge_events.jsonl の整合性検証はここで行う

---

## 6. 活用・探索

### Scenario 14: Perspective generation & Hypothesis generation（本丸、v0.7 完全対応版）

**Status**: **合意済**（Group A-D 議論、2026-04-24）+ **v0.7 更新**（L2 Graph Ledger 統合、2026-04-25）  
**Priority**: MVP  
**Theme**: 活用・探索  
**Layer**: **L2 Graph Ledger が主要 query 対象**、L3 wiki を補助的に参照  
**Related**: Scenario 15（対話型 synthesis）、Scenario 16（query → synthesis 昇格）、Scenario 25（llm_log_extract）、Scenario 34（relation extraction、L2 を育てる）、Scenario 36（Hygiene、query の reinforcement が Hygiene の入力）  
**Specs**: **Spec 6**（中心）、**Spec 5**（L2 Graph Ledger 基盤）

#### ユースケース

**User intent**: Rwiki に蓄積された**L2 Graph Ledger（進化する候補 graph）+ L3 curated wiki**から、**ユーザーが単独では気づかない視点**や**未検証の新命題**を LLM に surface させる。v2 の最大の差別化機能。  
**Trigger**: `rw perspective` / `rw hypothesize` コマンド、または `rw chat` の autonomous mode で LLM が能動的に提示。  
**Context**: L2 ledger に一定規模の edges（目安: 100+ edges、stable+core 比率が高いほど精度向上）、L3 wiki 50+ ページ推奨。

---

#### 1. 概念設計

##### Perspective / Hypothesis / Discovery の関係

```
Discovery（探索アルゴリズム・内部機構）
    ↓ 共通基盤として L2 Graph Ledger を traverse
┌─────────────────┬─────────────────┐
Perspective       Hypothesis
（独立コマンド）   （独立コマンド）
```

- **Discovery** = L2 Graph Ledger 上の探索アルゴリズム（**何を見つけるか**）: 共通基盤
- **Perspective** = 既存知識の再解釈（**どう解釈するか**）: 独立コマンド、主に **stable + core edges** を活用
- **Hypothesis** = 新命題の生成（**どう前進するか**）: 独立コマンド、主に **candidate edges + missing bridges** を活用
- **MVP**: Discovery は内部機構のみ、独立 CLI (`rw discover`) は Phase 2 で検討

##### Perspective vs Hypothesis の性質差

| 軸 | Perspective（視点創発） | Hypothesis（仮説生成） |
|----|---------------------|---------------------|
| 性質 | 既存知識の再解釈・関係性発見 | 未検証の新命題・洞察 |
| **主に traverse する L2 edges** | **stable / core edges**（高 confidence） | **candidate edges + missing bridges** |
| Trust chain | 維持（wiki 引用 + evidence.jsonl 参照） | 仮説は検証前、`[INFERENCE]` 必須、L2 の weak/candidate edges を種に |
| 出力例 | 「A と B は同じ原理の別表現」 | 「A と C を組み合わせると D が予測できる」 |
| 後続 | そのまま再利用（approve 不要） | `rw verify` → L1 raw で検証 → 承認後に wiki 昇格 |
| 位置付け | 知識の深化・整理 | 知識の前進・拡張 |
| 検証対象 | 検証不要（既存 evidence 引用） | **evidence 検証可能な命題に限定** |
| **L2 への feedback** | 使われた edge に `usage_signal` → reinforcement（confidence 上昇） | 検証済み hypothesis が候補 edge を stable 化 |

**注**: 純粋な理論的命題（定義変更提案、概念の一般化等）は **Perspective skill の担当**。Hypothesis は raw/ で検証可能なものに限る。

##### 代表的な機能パターン

**パターン A: 関連性サジェスト（Perspective）**
```
You: SINDy で非線形ダイナミクスを同定したい

Claude: 関連する観点:
  (1) wiki/methods/dmd.md — 数学的基盤を共有
  (2) wiki/concepts/bayesian-sparse-regression.md — 不確実性の観点
  (3) wiki/entities/people/brunton.md — 関連研究者
  どれから深掘りしますか？
```

**パターン B: 反対視点の提示（Perspective）**
```
You: ネットワーク分析は社会現象の理解に有効だ

Claude: あなたの視点を支持する wiki と反論 wiki:
  支持: wiki/methods/network-analysis.md, wiki/synthesis/emergence-in-social-systems.md
  反論: wiki/concepts/ecological-fallacy.md, wiki/synthesis/network-causality-limits.md
```

**パターン C: wiki の欠落発見**
```
You: 強化学習と制御理論の関係について考えたい

Claude: 関連ページあり:
  - wiki/methods/reinforcement-learning.md
  - wiki/methods/optimal-control.md

  ⚠ 両者に共通の関連ページはあるものの、直接結ぶ確立された関係がありません。
  提案:
    (a) wiki/synthesis/ に両者を結ぶページを drafting
    (b) 関係性を LLM で自動抽出（`rw extract-relations`、Scenario 34）
```

**パターン D: 仮説生成（Hypothesis）**
```
You: 現在の wiki から「今後検証したい仮説」を出して

Claude: [INFERENCE] 仮説候補（review/hypothesis_candidates/ に保存）:

  1. SINDy に variational inference を統合できる可能性
     根拠: wiki/methods/sindy.md と wiki/concepts/vi.md の概念的類似性
     検証方法: `rw verify hyp-042`

  2. Transformer と manifold learning の融合
     根拠: 未発見の関連性パターン（Discovery で surface）
```

**パターン E: 過去探索の再利用**
```
You: SINDy について調べたい

Claude: 過去の関連探索 3 件:
  - review/query/20260115-sindy-intro/ (2 ヶ月前)
  - wiki/synthesis/sindy-dynamical-identification.md (1 ヶ月前、promoted)
  今回はどの角度で？
```

**パターン F: 分野全体の大局ビュー（global query）**
```
You: 私の wiki における「sparse regression」まわりを大局的に俯瞰したい

Claude: 該当領域の全体像（L2 Graph Ledger 全体から集約）:
  主要 cluster:
    (1) sparse identification 系: SINDy, E-SINDy, SINDy-MPC（8 ページ、core edge 多数）
    (2) 関連数理基盤: L1 regularization, compressed sensing（5 ページ、stable）
    (3) 応用: 流体・気候・神経科学（12 ページ、確信度混在）

  主要人物・著者: Brunton, Kutz, Rudy
  未検証の仮説: 2 件（review/hypothesis_candidates/）
  この俯瞰から深掘りしますか？
```

**パターン G: 関連クラスタの surface（community detection）**
```
You: dmd.md を見てるけど、近い位置にある他の手法は？

Claude: dmd が所属する cluster 内の近接ページ:
  - wiki/methods/sindy.md (数学基盤を共有、core edge)
  - wiki/methods/koopman.md (同 cluster、stable)
  - wiki/concepts/dynamic-systems.md (上位概念、core)
  cluster 境界の bridge 候補: Transformer-based dynamics（candidate、検証推奨）
```

内部では L2 Graph Ledger 上の community detection / global query / missing bridge detection / hierarchical summary（on-demand）を組み合わせて surface する。技法の詳細は **consolidated-spec §1.3.3 / Spec 5 / Spec 6** 参照。

---

#### 2. 技術基盤

ユーザーは `rw perspective` / `rw hypothesize` を実行、または対話中に関連性が提示される。裏側の処理フロー、depth/confidence 閾値、Ledger 成熟度別 fallback、edge reinforcement の仕組み、SQLite cache / edges.jsonl のデータ格納は **Spec 6 Key Requirements** および **Spec 5 Graph Hygiene + §5.10** 参照。

---

#### 3. Hypothesis 専用

##### 検証ワークフロー（`rw verify`）

```
You: manifold-sindy-2026-04-24 を verify

Claude: 仮説: "SINDy の sparse regression を manifold 上で実行可能"

  raw/ から evidence 候補を探索しました:
    支持候補:
      - raw/papers/local/chen-2024.md: "manifold SINDy" 章で類似提案あり
    反証候補:
      - raw/papers/local/euclidean-constraint-2022.md: "SINDy は Euclidean 前提" 言及

  各 evidence を評価してください（supporting / refuting / partial / none）

You: [評価入力]

Claude: 判定: confirmed
  - verification_attempts に記録しました
  - `rw approve <hypothesis-id>` で wiki/synthesis/ 昇格可能です
  （内部で L2 Graph Ledger の関連 edges も強化されます）
```

##### ingest 時の自動通知（補助）

```
You: rw ingest
Claude: 💡 直近 ingest が pending hypothesis 2 件に関連する可能性:
    - chen-2024.md ↔ manifold-sindy
  verify してみますか？
```

##### 7 状態の遷移

Hypothesis は Page status / Edge status とは**独立した 7 状態**を持つ：

```
[生成] ─→ draft
          ↓ rw verify
        verified （検証済み、判定待ち）
          ↓ 判定
     ┌────┼────┐
     ↓    ↓    ↓
 confirmed  refuted  evolved
     ↓         ↓        ↓
 rw approve   archived  新 hypothesis 生成
     ↓
 promoted (wiki/synthesis/ に昇格)
```

##### 承認条件

- **confirmed のみ wiki 昇格可能**（Trust chain 保全）
- **Hypothesis 本体は `review/hypothesis_candidates/` に残る**（歴史保全）
- **Refuted も記録として残す**（Karpathy 思想「失敗からも学ぶ」）

**承認フロー（ユーザー視点）**:

```
1. rw verify <id>              → evidence 候補提示、判定
2. status = confirmed           → rw approve <id> 可能
3. rw approve <id>              → review/synthesis_candidates/<slug>-synthesis.md
4. 通常の synthesis review → approve → wiki/synthesis/<slug>.md
5. hypothesis 本体は status: promoted、successor_wiki を記録
```

##### frontmatter・内部構造・Trust chain

- Frontmatter スキーマ（`origin_edges`, `verification_attempts`, `edge_reinforcements` 等）は **consolidated-spec §5.9.1** 参照
- L2 Graph Ledger 連携（検証時の edge reinforcement、evidence.jsonl への追記、L1 raw → L2 ledger → L3 wiki の trust chain 全体像）は **Spec 5 Graph Hygiene** および **Spec 6 Key Requirements** 参照
- 全段階で evidence_id / edge_id による逆参照が可能（詳細は §5.10）

---

#### 4. UX

##### Autonomous mode

本題回答**後**に `💡` マーカーで分離して提案し、無効化手段も毎回示す：

```
You: SINDy の数式を教えて

Claude: [本題回答]
  Ξ = argmin ||Ẋ - Θ(X)Ξ||_2 + λ||Ξ||_1

  💡 **関連観点**（autonomous mode）
    wiki/methods/dmd.md とは数学的基盤を共有しています。
    → `/show related dmd` で詳細
    → `/mute autonomous` で提案を無効化
```

発火条件・閾値・頻度制限・config スキーマは **consolidated-spec §2.11（Maintenance UX）** および **Spec 4（cli-mode-unification）** 参照。

**Maintenance 提案との統合（Scenario 33 連携）**: Autonomous は知識発見だけでなく、未 approve 候補・audit 未実行・L2 Graph Ledger の reject queue / edge decay 等の**メンテナンス状態 surface** も提示する。詳細は Scenario 33 参照。

##### 結果の記録形式

| 種類 | 既定の記録 |
|------|---------|
| **Hypothesis** | 常にファイル化（`review/hypothesis_candidates/`） |
| **Perspective** | stdout default、`--save` / `/save` で `review/perspectives/` |
| **Discovery** | 内部処理のみ（MVP） |

Perspective 保存時の frontmatter スキーマ（`traversed_edges` 含む L2 連携フィールド）は **consolidated-spec §5.9.2** 参照。保存に伴う L2 edge reinforcement の挙動は **Spec 5 Graph Hygiene** 参照。

##### 対話ログ連携

- `rw chat` セッションは `raw/llm_logs/chat-sessions/chat-<ts>.md` に自動保存（Scenario 15/25 と同仕組み）
- 保存し忘れた perspective も対話ログから後日 `rw distill --skill llm_log_extract` で抽出可能

---

#### 5. ユーザーが呼ぶ意図

- 「このトピックで視点を広げたい」 → `rw perspective`
- 「今後検証したい仮説を出したい」 → `rw hypothesize`
- 「この仮説を検証したい」 → `rw verify`
- 「confirmed 仮説を wiki に昇格したい」 → `rw approve <hypothesis-id>`
- 「対話しながら進めたい」 → `rw chat`

depth / mode / save 等の CLI オプション、対話型モード切替の引数体系、hypothesis_candidates や synthesis_candidates との紐付けは **Spec 4 / Spec 6** 所管。

---

#### 6. 新 review 層（Scenario 14 で追加）

```
review/
├── synthesis_candidates/        (既存)
├── query/                       (既存)
├── skill_candidates/            (Scenario 20)
├── vocabulary_candidates/       (Scenario 12)
├── audit_candidates/            (Scenario 10)
├── hypothesis_candidates/       (Scenario 14 Group C 追加)
└── perspectives/                (Scenario 14 Group D 追加)
```

---

#### 7. Dangerous op category

| 操作 | 分類 | 備考 |
|------|-----|------|
| `rw perspective` | 非 dangerous | stdout のみ default、ファイル化も軽量 |
| `rw hypothesize` | 非 dangerous | review 生成のみ |
| `rw verify` | 非 dangerous | frontmatter 更新のみ |
| `rw approve <hypothesis>` | **最高** | wiki/synthesis/ への promote、`--auto` 不可、8 段階対話必須 |

---

#### 8. シナリオ間連携

- **Scenario 15 (interactive_synthesis)**: 対話ログが perspective/hypothesis の素材として蓄積
- **Scenario 16 (query → synthesis 昇格)**: Hypothesis の approve は内部で query → synthesis 昇格と類似フロー、hypothesis → synthesis 候補 → wiki/synthesis/
- **Scenario 25 (llm_log_extract)**: `rw chat` / perspective の対話ログが `raw/llm_logs/` に保存、後日再処理可能
- **Scenario 34 (Entity/Relation 自動抽出)**: L2 Graph Ledger を育てる、perspective/hypothesis の精度向上の源
- **Scenario 35 (Edge reject workflow)**: 低 confidence candidate edges の reject が Hypothesis 生成品質を保つ
- **Scenario 36 (Graph Hygiene 実行)**: perspective/hypothesize が使った edges の reinforcement は Hygiene サイクルの一部
- **Scenario 37 (Edge lifecycle 管理)**: candidate → stable 昇格した edges が perspective のメイン対象に
- **Scenario 38 (Edge events 監査)**: query で使われた edges の history 追跡、perspective/hypothesize の振り返り
- **Spec 5 (knowledge-graph)**: **L2 Graph Ledger の成熟度**が Perspective/Hypothesis 精度を直接決める

---

### Scenario 16: Query → Synthesis 昇格

**Status**: 合意済（5 論点議論で要件確定、2026-04-24）  
**Priority**: MVP  
**Theme**: 活用・探索  
**Related**: Scenario 7（extend）、Scenario 8（merge）、Scenario 11（dangerous op 8 段階）、Scenario 14（perspective/hypothesize との連動）  
**Specs**: Spec 2, 7

#### ユースケース

**User intent**: `rw query extract` で生成した 4 ファイル契約（question/answer/evidence/metadata）の中で、**再利用価値が高く横断的な知識**を `wiki/synthesis/` に昇格させる。  
**Trigger**: ユーザーが「この query 結果 synthesis 化したい」と発話、または LLM が `synthesis_candidate: true` を提案。  
**Context**: review/query/ に複数の query artifact、一部が特に優れた統合知識。

---

#### 1. `synthesis_candidate` フラグの判定基準（論点 1）

##### LLM 自動判定 + ユーザー承認（Option C）

**query extract 時に LLM が採点**:

| 条件 | スコア |
|------|-------|
| sources 3 件以上（横断性） | +1 |
| query_type が `structure` / `comparison` / `why` / `hypothesis`（統合的） | +1 |
| answer に `[INFERENCE]` が含まれる（推論統合） | +1 |
| 類似 synthesis が既存にない | +1 |
| 結果が atomic すぎる（1 事実だけ） | -2 |

**合計 ≥ 2 で `synthesis_candidate: true`** を推奨値として metadata.json に記録。

**昇格時（`rw query promote`）に再確認**:

```
Claude: この query の synthesis_candidate は true（LLM 提案値）:
  根拠:
    - 4 wiki ページを横断（sources 4 件）
    - query_type: comparison
    - [INFERENCE] による統合あり

  昇格に妥当と判断しますが、進めますか？
  または false に変更しますか？
```

---

#### 2. 4 ファイル → 1 synthesis ページへの変換（論点 2）

##### 構造変換

| 入力 | 出力先 |
|------|-------|
| question.md | `## Motivation` セクション（質問を文脈化） |
| answer.md | **メイン本文**（構造化回答） |
| evidence.md | `sources:` frontmatter + 本文インライン `[evidence: ...]` マーカー |
| metadata.json | frontmatter（query_id, tags, scope 等転記） |

##### Slug 決定（LLM 提案 + ユーザー確認、Option C）

```
Claude: slug 候補:
  (1) sindy-koopman-dynamical-identification（推奨、意味的）
  (2) sindy-vs-koopman-comparison（直訳）
  (3) 別名を指定

You: (1)

Claude: wiki/synthesis/sindy-koopman-dynamical-identification.md として生成します。
  元 query_id は frontmatter `query_id:` に保持。
```

---

#### 3. evidence.md の扱い（論点 3、インラインマーカー + frontmatter + promoted_from）

##### Synthesis ページの完整な構造例

```markdown
---
title: "Data-driven Dynamical Identification: SINDy と Koopman の統合的視点"
type: synthesis
sources:
  - wiki/methods/sindy.md
  - wiki/methods/koopman.md
  - wiki/methods/dmd.md
  - wiki/concepts/sparse-regression.md
promoted_from: review/query/20260420-sindy-koopman-comparison/
promoted_at: 2026-04-24
query_id: 20260420-sindy-koopman-comparison
user_approved: true
tags: [synthesis, sparse-regression, dynamical-systems, comparison]
---

# Data-driven Dynamical Identification: SINDy と Koopman の統合的視点

## Motivation

SINDy と Koopman 演算子の違いは何か？ という問いは ...
(question.md の内容を文脈化)

## 概念的基盤

SINDy は sparse regression に基づき [evidence: wiki/methods/sindy.md L23-45]、
Koopman は operator-theoretic approach を取る [evidence: wiki/methods/koopman.md L10-28]。

[INFERENCE] 両者は異なる数学的視点から同じ問題に取り組んでおり、...

## 比較

| 軸 | SINDy | Koopman |
|----|-------|---------|
| 前提 | sparse representation [evidence: ...] | linear in infinite-dim [evidence: ...] |

## References

詳細な引用は元 query の evidence.md を参照（ `promoted_from:` を参照）。
```

**特徴**:
- **インライン `[evidence: ...]` マーカー**: 主張ごとに traceability
- **`sources:` frontmatter**: wiki 参照の和集合
- **`promoted_from:` frontmatter**: 元 query artifact への逆参照
- **詳細 evidence は元 query に残る**（削除しない、Trust chain 保全）

---

#### 4. 既存 synthesis との衝突解決（論点 4）

昇格先 `wiki/synthesis/<slug>.md` が既に存在する、または類似がある場合、**ユーザーが選択**。

```
Claude: wiki/synthesis/ に類似トピックあり:
  - wiki/synthesis/sindy-dynamical-identification.md（1 ヶ月前 approve）
    類似度: 75%（主題が重複）

  選択肢:
    (1) extend — 既存 synthesis に追記（Scenario 7 フロー）
    (2) merge — 統合版を作成、既存を status: merged に（Scenario 8 フロー）
    (3) 別 synthesis として新規作成（例: sindy-koopman-comparison.md として並立）
    (4) cancel — 昇格中止

You: (2) merge で

Claude: [Scenario 8 merge フロー起動]
  ...
```

**設計原則**: Scenario 16 単独では「新規作成」のみを扱い、**衝突時は Scenario 7/8 に委譲する統合的な設計**。

---

#### 5. Dangerous op 認定（論点 5）

wiki/synthesis/ は Rwiki の**最も価値の高い層**。**最高ランク** dangerous op:

| 項目 | 設定 |
|------|-----|
| 対話ガイド | **8 段階必須** |
| `--auto` | **不可**（常に対話必須） |
| Pre-flight | 必須（変換プレビュー、衝突解析） |

##### 8 段階マッピング

| Stage | Scenario 16 での内容 |
|-------|-------------------|
| 1. 意図確認 | promote / extend / merge / cancel の選択 |
| 2. 現状把握 | query artifact の内容確認、metadata 提示、`synthesis_candidate` 再確認 |
| 3. 衝突解析 | 類似 wiki/synthesis/ ページの検索（論点 4） |
| 4. 代替案提示 | slug 候補、衝突解消案 |
| 5. 個別判断 | sources 選別、evidence 転記方針 |
| 6. Pre-flight warning | 変換後のプレビュー（frontmatter、本文構造） |
| 7. 差分プレビュー生成 | `review/synthesis_candidates/<slug>-synthesis-<ts>.md` |
| 8. レビュー → approve | 通常の approve フロー |

---

#### 6. ユーザーが呼ぶ意図

- 「この query 結果を synthesis に昇格したい」 → `rw query promote`（対話 8 段階、auto 不可）
- 「昇格結果だけ事前に見たい」 → promote-preview
- 「synthesis_candidate: true の query を一覧したい」 → query list

サブコマンド名・フラグ体系は **Spec 4 / Spec 7** 所管。

---

#### 7. 完整フロー例

```
You: review/query/20260420-sindy-koopman-comparison/ を synthesis に昇格

Claude: [Stage 1: 意図確認]
  query artifact 確認:
    question_type: comparison
    sources: 4 wiki ページ
    synthesis_candidate: true (LLM 推奨、根拠: 横断性・INFERENCE あり)

  この昇格を進めますか？

You: はい

Claude: [Stage 2-3: 現状把握・衝突解析]
  wiki/synthesis/ に類似トピック 1 件発見:
    - wiki/synthesis/sindy-dynamical-identification.md (1 ヶ月前)
    類似度: 75%

  選択肢:
    (1) extend  (2) merge  (3) 新規  (4) cancel

You: (3) 新規

Claude: [Stage 4: slug 確定]
  slug 候補:
    (a) sindy-koopman-dynamical-identification（推奨）
    (b) sindy-vs-koopman-comparison

You: (a)

Claude: [Stage 5-6: 個別判断・Pre-flight]
  変換プレビュー:
    wiki/synthesis/sindy-koopman-dynamical-identification.md
      frontmatter: sources (4 件), promoted_from, query_id, tags
      本文: question → Motivation, answer → メイン本文
            evidence 参照: インライン [evidence: ...]

  注意:
    - sources 4 件中 1 件 (wiki/methods/dmd.md) は DMD 専用で
      SINDy-Koopman 比較には marginal。除外しますか？

You: OK、除外

Claude: [Stage 7: 差分生成]
  review/synthesis_candidates/sindy-koopman-dynamical-identification-2026-04-24.md 生成

  [Stage 8: レビュー]
  Obsidian で確認、approve で wiki/synthesis/ 昇格。

You: [確認後 rw approve]

Claude: 完了:
  - wiki/synthesis/sindy-koopman-dynamical-identification.md 生成
  - review/query/20260420-.../metadata.json の status を promoted に更新
  - git commit
```

---

#### 8. Edge cases

- **metadata.json の `synthesis_candidate: false`**: 警告 + 昇格の根拠確認を求める
- **evidence の wiki 参照が deprecated**: promote 前に警告、successor への置換提案
- **元 query の evidence.md が lint FAIL**: `rw query fix <query-id>` 先行推奨
- **query が promote 済（`status: promoted`）**: 再昇格を拒絶、unapprove フローを案内
- **sources の 1 つが途中で deprecated 化**: promote 進行中に検出 → 継続判断

---

#### 9. Scenario 14 との関係

Hypothesis の `rw approve` フロー（Scenario 14 §3 承認フロー）は **実質的に Scenario 16 の特殊形**：

```
Hypothesis (confirmed) --approve--> synthesis candidate --approve--> wiki/synthesis/
                            ↑ Scenario 16 と同じ 8 段階フローを通る
```

つまり hypothesis promotion は「evidence 検証済みの命題を wiki/synthesis/ に昇格する」Scenario 16 の一種として処理される。

---

## 7. 運用・保守

### Scenario 17: Daily note（エディタに委譲）

**Status**: 合意済  
**Priority**: MVP  
**Theme**: 運用  
**Related**: Scenario 25（対話ログ）  
**Specs**: Spec 0（責務分離）

#### ユースケース

**User intent**: 日記的な研究メモを日常的に記録し、Rwiki のパイプラインで知識化したい。  
**Trigger**: 毎日・週次など。  
**Context**: Obsidian 等のエディタで `raw/journal/` or `raw/notes/` に daily note を書く。

#### 方針

**Rwiki は daily note 生成機能を提供しない**。編集はエディタ（推奨: Obsidian Daily Note プラグイン + Templater）に委譲。

**Rwiki の関与**: Obsidian が `raw/journal/` に書いた内容を、ユーザーが後日 `rw distill ... --skill personal_reflection` でパイプラインに投入する。

#### ユーザーが呼ぶ意図

- 「直近の daily note をまとめて reflection 化したい」 → `rw distill raw/journal/ --skill personal_reflection`

期間フィルタ・Skill `personal_reflection`（observation / interpretation / action の 3 層）定義は **Spec 2** 所管。

**Dangerous op category**: 非 dangerous

---

### Scenario 18: Pre-flight check（v0.7 L2 state サマリ統合）

**Status**: 合意済（v0.7 更新、L2 edge state サマリを pre-flight に統合、2026-04-25）  
**Priority**: MVP  
**Theme**: 運用  
**Layer**: **全層（L1 / L2 / L3）の俯瞰**  
**Related**: 全 approve / dangerous op、Scenario 33（Maintenance UX）、Scenario 35（reject workflow）、Scenario 36（Hygiene）  
**Specs**: **Spec 7**（中心）

#### ユースケース

**User intent**: 重要な一括操作（approve、deprecate、merge 等）前に、候補ファイルだけでなく **L2 Graph Ledger の健康状態** も含めた全体の影響を俯瞰したい。  
**Trigger**: ユーザーが「これから approve する、一旦確認したい」と発話、または dangerous op 直前に自動挿入。

#### 対話フロー

```
You: これから approve 予定の 5 件、一括確認したい

Claude: [内部: preflight 診断を実行]

  対象候補 5 件の検査:
    ✓ 全件に status: approved + reviewed_by + approved: が揃っている
    ✓ lint PASS
    ✗ candidate-c.md: wiki/synthesis/ に同名ファイル存在（上書き注意）
    ✗ candidate-e.md: evidence URL https://... が 404

  L2 Graph Ledger 状態サマリ:
    edges: 380 (core 45 / stable 220 / candidate 112 / weak 3)
    reject queue: 12 件（要レビュー、Scenario 35）
    decay 進行中: 30 edges（1 週間未 usage、Hygiene 推奨）
    dangling evidence: 5 edges（Scenario 13 連携）
    ※ 今回の approve は上記とは独立、後続で対応可能

  対応推奨:
    candidate-c: merge 戦略で進める or ファイル名変更
    candidate-e: URL 更新 or "source unavailable" 注記追加

  全件 approve を進めますか？ 問題 2 件を先に解決しますか？
```

#### 技術基盤（詳細は Spec 7 参照）

- 独立コマンドとしての pre-flight／各コマンドへのフラグ統合のコマンド設計 → **Spec 7**
- L2 edge state サマリの取得元 → **Spec 5 §5.10**（edges.jsonl / edge_events.jsonl / rejected_edges.jsonl）
- 検査項目の標準化（approve 前 / deprecate 前 / merge 前で異なる） → **Spec 7**
- ファイル操作は読込のみ（診断、review layer なし）

#### Dangerous op category

非 dangerous（読込のみ、実際の変更なし）

#### シナリオ間連携

- **Scenario 11/19 (dangerous op)**: pre-flight は 8 段階対話の第 0 ステップとして機能可能
- **Scenario 13 (evidence 検証)**: dangling evidence の存在を surface
- **Scenario 33 (Maintenance UX)**: 同じ L2 状態サマリを autonomous mode で定常的に提示
- **Scenario 35 (edge reject workflow)**: reject queue の件数を surface
- **Scenario 36 (Graph Hygiene)**: decay 進行中の件数から Hygiene 実行を推奨

---

### Scenario 19: Rollback / unapprove

**Status**: 合意済  
**Priority**: MVP  
**Theme**: 運用  
**Related**: Scenario 11  
**Specs**: Spec 4, 7

#### ユースケース

**User intent**: 間違えた approve を戻したい（緊急・シンプル）。  
**Trigger**: ユーザーが「さっきの approve を戻したい」と発話。

#### 対話フロー（最小）

```
You: さっきの approve を戻したい

Claude: 直近の approve commit:
  commit 3f4a5b6 (2026-04-24 15:30, 3 分前)
  files (1):
    - wiki/synthesis/sindy-identification.md (created)
  復元対象:
    - review/synthesis_candidates/sindy-candidate-2026-04-24.md
      (status: approved → draft、reviewed_by/approved_at クリア)

  実行しますか？ (y/N)

You: y

Claude: [内部: rw unapprove]
  完了（git revert + candidate 復元、commit: abc1234）
```

#### ユーザーが呼ぶ意図

- 「直前の approve を取り消したい」 → `rw unapprove`

対象指定・commit 指定・dry-run・無確認実行などの引数、`git revert` の打ち消し範囲、candidate 復元時の `status: draft` 戻し、commit 粒度は **Spec 4 / Spec 7** 所管。

**Dangerous op category**: **Simple dangerous op**（1 段階対話、8 段階ガイドは過剰）

---

### Scenario 20: Custom skill 作成

**Status**: 合意済（v0.7 軽微: reject 学習 skill も対象、2026-04-25）  
**Priority**: MVP  
**Theme**: 運用・拡張  
**Layer**: Skill 作成は L3 側、L2 の extract-relations skill カスタマイズも本 scenario の対象  
**Related**: Scenario 34（extract-relations skill）、Scenario 35（reject 理由を学習した skill）  
**Specs**: Spec 2

#### ユースケース

**User intent**: 既存スキルに合致しないコンテンツ用に、独自の出力パターンを定義したい。  
**Trigger**: ユーザーが「～用のスキルを作りたい」と発話。

#### 対話フロー（7 段階）

1. 意図確認（既存ベース？ ゼロから？）
2. 情報収集（8 section の埋め）
3. 草案生成（`review/skill_candidates/`）
4. Validation（YAML、8 section、衝突、参照）
5. Dry-run（テストサンプル）
6. 修正ループ
7. Install（`AGENTS/skills/` に配置）

（詳細は `rwiki-v2-consolidated-spec.md` § Scenario 20 参照）

#### ユーザーが呼ぶ意図

- 「新 skill の草案を作りたい」 → skill draft
- 「サンプルで挙動を試したい」 → skill test
- 「完成した skill を使える状態にしたい」 → skill install
- 「既存 skill を一覧・表示・非推奨・撤回したい」 → skill list / show / deprecate / retract

各サブコマンドの正式 CLI 形、Skill frontmatter 8 section スキーマ、`review/skill_candidates/` フロー、validation ルール、`AGENTS/skills/` への install ロジックは **Spec 2** 所管。

**Dangerous op category**: 中（install）、高（retract）

---

### Scenario 33: メンテナンス UX 全般原則（旧: Ambiguity 時の UX、v0.7 L2 統合）

**Status**: 合意済（v0.7 更新、L2 Graph Ledger メンテナンス surface を統合、2026-04-25）  
**Priority**: MVP  
**Theme**: 運用・UX  
**Layer**: **全層（L1 / L2 / L3）を横断診断**  
**Related**: 全 L3 メンテナンスシナリオ、Scenario 14（autonomous mode）、Scenario 18（pre-flight）、Scenario 35/36（L2 reject / Hygiene）  
**Specs**: Spec 0（原則）、Spec 4（rw chat 実装）、Spec 5（L2 診断）

#### ユースケース（拡張版）

**User intent**: ユーザーは**メンテナンス手順を知らなくても**、意図を自然言語で伝えれば LLM が適切なコマンドをガイド・実行する。コマンド名・オプション・前提条件を覚える必要がない。  
**Trigger**: `rw chat` 内でメンテナンス意図の発話（曖昧含む）。  
**Context**: ユーザーは知識発見（L1）に集中したい。メンテナンス（L3）は LLM に委任。

**典型シーン**:
- 「このメモを整理しておいて」→ lint / ingest を適切にガイド
- 「Rwiki を綺麗にしたい」→ 複数メンテナンスを診断してオーケストレーション
- 「古いページをしまいたい」→ deprecate / archive / merge の判断を助ける
- 「チェックして」→ 適切な audit tier を選ぶ
- 「タグがぐちゃぐちゃ」→ tag review セッションを起動

#### 対話フロー

**Bad UX（拒絶）**:
```
You: このメモを整理しておいて
Claude: 申し訳ありません、タスクが不明瞭です。STOP。
```

**Good UX（候補提示）**:
```
You: このメモを整理しておいて

Claude: 「整理」の意図を確認させてください。候補タスク:
  (a) lint — raw/incoming/ の検証のみ
  (b) ingest — raw/incoming/ を raw/ に取り込む
  (c) distill — 知識を review/ に抽出（どの skill で？）
  (d) tag review — タグを整理
  (e) audit tags — タグの問題検出
  (f) merge — 重複候補を統合

  直近の作業から推測:
    3 分前に raw/incoming/meeting-2026-04-24.md を作成 → (a) or (b) の
    流れの可能性高。

  どれに該当しますか？ それとも別の意図ですか？

You: b から順に

Claude: 了解、lint → ingest で進めます。
```

#### 複合メンテナンス シーン

**シーン A: 状態診断 + オーケストレーション（v0.7 L2 診断含む）**

```
You: 最近忙しくて放っといた、Rwiki を綺麗にしたい

Claude: [内部: 全層の複数診断を並行実行]
  L1 raw 状態:
    - raw/incoming/ に未 ingest 3 件（うち 2 件 FAIL 滞留）← Scenario 26

  L2 Graph Ledger 状態:
    - reject queue 12 件（要レビュー）← Scenario 35
    - decay 進行中 30 edges（1 週間未 usage、Hygiene 推奨）← Scenario 36
    - typed edges 整備率 15%（`rw extract-relations` 推奨）← Scenario 34
    - dangling evidence 5 edges ← Scenario 13

  L3 wiki 状態:
    - review/synthesis_candidates/ に未 approve 5 件
    - audit structure が 2 週間前（ERROR 2 件推定）← Scenario 10
    - tag vocabulary に重複候補 4 件 ← Scenario 12
    - wiki/.follow-ups/ に未解決 2 件

  順番に案内します。優先順位は Scenario 35/36（L2 ベース）か、
  L1 incoming FAIL 滞留（作業を進めるため）か、どちらから？

You: 全部お任せ

Claude: 優先順位で進めます:
  (1) L1: lint FAIL 滞留 → 自動修復可能な 1 件を先に fix
  (2) L2: reject queue → 10 分レビュー、Hygiene 推奨を後処理
  (3) L3: 未 approve 5 件 → レビュー要求
  ...（必要に応じて個別に相談）
```

**ユーザー発話 1 つで複数メンテナンスシナリオをオーケストレーション**。これが v2 の目指す UX。

**シーン B: 曖昧指示 → 候補提示**

```
You: このメモを整理しておいて

Claude: 「整理」の意図を確認させてください。候補タスク:
  (a) lint — raw/incoming/ の検証のみ
  (b) ingest — raw/incoming/ を raw/ に取り込む
  (c) distill — 知識を review/ に抽出（どの skill で？）
  (d) tag review — タグを整理
  (e) audit tags — タグの問題検出
  (f) merge — 重複候補を統合

  直近の作業から推測:
    3 分前に raw/incoming/meeting-2026-04-24.md を作成 → (a) or (b) の
    流れの可能性高。

  どれに該当しますか？

You: b から順に

Claude: 了解、lint → ingest で進めます。
```

**シーン C: Autonomous メンテナンス提案（Scenario 14 autonomous mode の拡張、v0.7 L2 含む）**

対話中または `rw chat` 起動時に、LLM が能動的に surface：

```
💡 **メンテナンス提案**
  L3 wiki:
    - 未 approve の候補が 5 件あります、レビューしませんか？
    - audit を 2 週間実行していません、structure チェックを推奨
    - deprecated chain の循環が発生しています、修正しますか？

  L2 Graph Ledger:
    - reject queue に 12 件の candidate edge（Scenario 35 reject workflow）
    - edge decay が進行中 30 edges（1 週間未 usage、Hygiene 推奨）
    - typed edges 整備率 15%（`rw extract-relations` で育成可能）

  → `/dismiss` でこのセッションは無視
  → `/mute maintenance` で今後も無視
```

定期的な状態確認を LLM が代行、ユーザーは意思決定だけ行う。

#### 原則（一般化版）

1. **STOP の前に候補提示**: 代替選択肢を常に示す（旧 Ambiguity 原則）
2. **文脈からの推測**: 直近の作業・対象ファイル・曖昧な語から候補を絞る
3. **前提条件の可視化**: 各候補の前提（コミット状態、前提タスク）も明示
4. **学習を促す**: 「このパターンは distill と言います」のような説明を添える
5. **複合診断 + オーケストレーション**: 単一タスクだけでなく、複数メンテナンスを並行診断
6. **Autonomous 提案**: ユーザーが尋ねなくても状態変化・累積タスクを surface
7. **無効化手段の常時提示**: `/dismiss` / `/mute` 等でユーザーが制御可能

#### 技術基盤（詳細は Spec 0 / Spec 4 / Spec 5 参照）

- Maintenance UX protocol の AGENTS ロード、candidate 提示モード、信頼度閾値 → **Spec 0 + Spec 4**
- 全層並行スキャンの対象（L1 incoming / L2 reject queue / decay / typed-edge 率 / L3 approve queue / audit / follow-up） → **Spec 4 + Spec 5**
- Autonomous maintenance 閾値設定（config スキーマ、`include_maintenance`） → **Spec 4**
- L2 診断項目（reject queue, decay, typed-edge 率, dangling evidence） → **Spec 5 Graph Hygiene**
- `rw doctor` コマンド（診断のみ） → **Spec 7**

#### ユーザーが呼ぶ意図

- 「対話で整理・診断したい」 → `rw chat`（Maintenance UX 込み）
- 「今セッションはメンテ提案を止めたい」 → chat の mute オプション
- 「全層診断だけ明示的に走らせたい」 → `rw doctor`

引数・オプション・mute 対象の粒度は **Spec 4 / Spec 7** 所管。

#### シナリオ間連携

- **Scenario 14 (autonomous mode)**: 同じ UX 基盤、提案内容はここで定義
- **Scenario 18 (pre-flight)**: pre-flight と同じ L2 state サマリを再利用
- **Scenario 26 (incoming lint-fail)**: L1 診断の一部
- **Scenario 34 (extract-relations)**: typed-edge 整備率から推奨
- **Scenario 35 (reject workflow)**: reject queue サマリから誘導
- **Scenario 36 (Graph Hygiene)**: decay 進行中の件数から Hygiene 実行を推奨
- **Scenario 38 (edge events 監査)**: 矛盾検出時は audit graph へ誘導

---

## 8. L2 Graph Ledger 管理

L2 Graph Ledger（Evidence-backed Candidate Graph + Hygiene）の育成・保守サイクルに関するシナリオ群。詳細な内部動作は **Spec 5 (knowledge-graph)** が所管し、本節ではユーザーフロー skeleton のみを記述する。

---

### Scenario 34: Entity / Relation 自動抽出

**Status**: skeleton（v0.7 新規、2026-04-25）  
**Priority**: MVP  
**Theme**: L2 育成  
**Layer**: L2 Graph Ledger  
**Related**: Scenario 14（perspective/hypothesis の精度源）、Scenario 15（interactive_synthesis の対話ログが抽出素材）、Scenario 25（llm_log_extract と同対話ログから extract 可能）、Scenario 35（reject queue への流入）、Scenario 36（Hygiene サイクル）  
**Specs**: **Spec 5**（中心）

#### ユースケース

**User intent**: L1 raw や L3 wiki の既存テキストから、entity（人物・概念・手法）と relation（edge）を LLM で自動抽出し、L2 Graph Ledger の candidate edges として蓄積する。入力源には `raw/llm_logs/` の対話ログ（Scenario 15/25 由来）も含まれる。  
**Trigger**: `rw extract-relations`、または Maintenance UX からの推奨。  
**Context**: typed-edge 整備率が低い、新規 ingest が大量にある、手動での edge 整備が追いつかない状況。

#### 対話フロー（skeleton）

```
You: relation 自動抽出かけたい

Claude: [内部: extract-relations を直近 scope で実行]

  抽出対象: raw/ 直近 2 週間 + wiki/methods/ + wiki/concepts/
  結果サマリ:
    新規 candidate edges: 48 件
    既存 edge の reinforcement: 23 件
    低 confidence（< 0.5）: 12 件 → reject queue へ

  詳細見ますか？ / 全件受け入れますか？ / reject queue だけレビュー？
```

#### 技術基盤（詳細は Spec 5 参照）

- LLM プロンプト設計・抽出スキーマ、confidence 初期値計算、evidence 登録 → **Spec 5**
- scope 指定（`--scope=recent|wiki|all|path:...`）、バッチサイズ、再実行冪等性 → **Spec 5**
- 出力先（edges.jsonl / evidence.jsonl / edge_events.jsonl 追記） → **§5.10**

#### Dangerous op category

- **抽出のみ**: 非 dangerous（candidate として追加、既存 stable edge は変更しない）
- **既存 edge の書き換え**: 無（reinforcement は append-only の event として記録）

#### シナリオ間連携

- 低 confidence edges は **Scenario 35** の reject queue に自動流入
- 抽出後の Hygiene サイクルは **Scenario 36**
- 新 edges の活用は **Scenario 14** perspective/hypothesis

---

### Scenario 35: Edge reject workflow

**Status**: skeleton（v0.7 新規、2026-04-25）  
**Priority**: MVP  
**Theme**: L2 品質管理  
**Layer**: L2 Graph Ledger  
**Related**: Scenario 13（evidence 検証、rejected 再出現）、Scenario 33（Maintenance UX の surface）、Scenario 34（流入源）  
**Specs**: **Spec 5**（中心）

#### ユースケース

**User intent**: 低 confidence / 不正確 / 文脈誤認の candidate edges を reject して reject queue に移し、以降の LLM 抽出・perspective/hypothesis から除外する。  
**Trigger**: `rw reject <edge-id>`、または `rw reject` で queue を対話 review。  
**Context**: extract-relations や ingest で流入した候補が蓄積、ユーザーが人間判断で選別したい。

#### 対話フロー（skeleton）

```
You: reject queue を 10 分レビューしたい

Claude: [内部: reject queue から 10 件ずつ interactive レビュー]

  reject 候補 12 件（confidence 昇順）:
    1. sindy → transformer （confidence 0.32、根拠 1 件）
       抽出元: raw/papers/tmp-note.md
       → reject / keep / more-evidence-needed / skip ?

You: reject（理由: tmp-note は仮記録で根拠が薄い）

Claude: 了解、rejected_edges.jsonl に記録し reject 理由も保存しました。
  次: ...
```

#### 技術基盤（詳細は Spec 5 参照）

- reject 理由の schema、reject_reason カテゴリ、rejected_edges.jsonl のフォーマット → **§5.10**
- reject 済 edge の再出現検知（Scenario 13 連携） → **Spec 5 Graph Hygiene**
- reject の skill 学習ループ（reject 理由を LLM の次回抽出 prompt に反映） → **Spec 5**

#### Dangerous op category

- **通常の reject**: 軽量（1 段階確認、rejected_edges.jsonl に append）
- **再 reject（再出現）**: 軽量（同上）
- **keep（reject 取り消し・unreject）**: 中（Scenario 19 の unapprove に準じる 1-stage confirm）

#### シナリオ間連携

- **Scenario 13**: 再出現検出の通知源
- **Scenario 14**: reject された edges は perspective/hypothesis から除外
- **Scenario 34**: reject 履歴を学習した抽出で再出現率を下げる
- **Scenario 36**: reject は Hygiene の confidence 再計算に反映

---

### Scenario 36: Graph Hygiene 実行

**Status**: skeleton（v0.7 新規、2026-04-25）  
**Priority**: MVP  
**Theme**: L2 品質管理  
**Layer**: L2 Graph Ledger  
**Related**: Scenario 10（audit ERROR）、Scenario 14（reinforcement の受け側）、Scenario 37（lifecycle 遷移）  
**Specs**: **Spec 5**（中心）

#### ユースケース

**User intent**: L2 edges の confidence を usage signal / reinforcement / decay / competition / contradiction / merging ルールに基づき再計算し、edge lifecycle 状態（weak / candidate / stable / core / deprecated）を更新する。  
**Trigger**: graph Hygiene 実行コマンド、または Maintenance UX からの推奨。コマンド名・オプション（dry-run 等）は Spec 5 所管。  
**Context**: extract-relations / perspective / hypothesize による edge 活用が蓄積、直近で未実行。

#### 対話フロー（skeleton）

```
You: Hygiene 回したい

Claude: [内部: Hygiene を dry-run 実行]

  Hygiene 結果プレビュー:
    confidence 再計算: 380 edges
    状態遷移候補:
      - candidate → stable: 24 edges（reinforcement 充足）
      - stable → deprecated: 3 edges（1 ヶ月以上未 usage + decay）
      - weak → reject queue: 8 edges（decay 限界）
    contradiction 検出: 2 組（両立しない edges、要判断）

  apply しますか？ （dry-run を詳細に見る / 競合だけ見る / apply / cancel）
```

#### 技術基盤（詳細は Spec 5 参照）

- 5 ルール（decay / reinforcement / competition / contradiction / merging）の数式と閾値 → **Spec 5 Graph Hygiene**
- usage_signal の計算式（base_score × contribution × sqrt(confidence) × independence × time_weight） → **Spec 5**
- state transitions（weak / candidate / stable / core / deprecated）の境界条件 → **Spec 5**
- edge_events.jsonl への append フォーマット → **§5.10**

#### Dangerous op category

- **dry-run**: 非 dangerous
- **apply（通常）**: 軽量（L2 ledger への append-only 記録、L3 wiki の `related:` cache は別途 sync）
- **contradiction 強制解決**: 中（ユーザーに明示確認、理由記録必須）

#### シナリオ間連携

- **Scenario 10**: `rw audit graph` の一部として Hygiene 異常をサルベージ
- **Scenario 14**: Hygiene 後の edges で精度向上
- **Scenario 35**: weak → reject queue は Scenario 35 で処理
- **Scenario 37**: lifecycle 遷移の詳細

---

### Scenario 37: Edge lifecycle 管理

**Status**: skeleton（v0.7 新規、2026-04-25）  
**Priority**: MVP  
**Theme**: L2 品質管理  
**Layer**: L2 Graph Ledger  
**Related**: Scenario 14（stable/core を主に活用）、Scenario 35（rejected 遷移）、Scenario 36（Hygiene が主な driver）  
**Specs**: **Spec 5**（中心）

#### ユースケース

**User intent**: Edge が weak / candidate / stable / core / deprecated / rejected の 6 状態をどのように遷移するかを可視化・管理し、stable/core の育成と deprecated の整理を行う。  
**Trigger**: edge 表示・昇格・Maintenance UX からの推奨。コマンド名（`rw edge show / promote / deprecate / history` 等）は Spec 5 所管。  
**Context**: Hygiene サイクル後に状態分布を確認したい、特定 edge の履歴を見たい。

#### 対話フロー（skeleton）

```
You: 主要 edge の lifecycle を見たい

Claude: [内部: stable/core edges を使用 signal 順に上位 20 件表示]

  上位 edges（usage_signal 降順）:
    1. sindy → koopman (core, confidence 0.96, 使用 42 回)
       初期: candidate (2026-02-10) → stable (03-02) → core (04-18)
    2. ...

You: 2 の deprecate 候補理由も見たい

Claude: [内部: 指定 edge の history を表示]
  ...
```

#### 技術基盤（詳細は Spec 5 参照）

- 6 状態の定義と遷移条件 → **Spec 5 + §4**
- `rw edge show / promote / deprecate / history` のコマンド設計 → **Spec 5**
- edge_events.jsonl からの履歴再構成 → **§5.10**

#### Dangerous op category

- **show / history**: 非 dangerous
- **promote（手動昇格）**: 中（通常は Hygiene 自動、手動は理由記録必須）
- **deprecate（手動）**: 中（理由記録必須、Scenario 11 archive と整合）

#### シナリオ間連携

- **Scenario 14**: perspective は主に stable/core を traverse
- **Scenario 35**: deprecated → rejected への遷移は reject workflow 経由
- **Scenario 36**: 自動遷移の主な driver

---

### Scenario 38: Edge events 監査

**Status**: skeleton（v0.7 新規、2026-04-25）  
**Priority**: MVP  
**Theme**: L2 品質管理・トレーサビリティ  
**Layer**: L2 Graph Ledger  
**Related**: Scenario 10（graph audit の一部）、Scenario 13（evidence 整合）、Scenario 36（reinforcement event）  
**Specs**: **Spec 5**（中心）

#### ユースケース

**User intent**: 特定 edge の全履歴（生成・reinforcement・decay・state 遷移・reject・merge）を確認し、perspective/hypothesis の根拠を逆追跡できる。edge_events.jsonl の矛盾も検出する。  
**Trigger**: edge の history 確認、graph events 整合性監査、perspective/hypothesis からの逆参照リンク。コマンド名・オプションは Spec 5 所管。  
**Context**: 「なぜこの関連性が提示されたか」を説明可能にする、または矛盾検出時の根本原因分析。

#### 対話フロー（skeleton）

```
You: e_042 の history 見せて

Claude: [内部: 指定 edge の history を取得]

  e_042: sindy → koopman (similar_approach_to)
  events:
    2026-02-10  created (extract-relations, confidence 0.58, evidence ev_034)
    2026-02-28  reinforced (perspective で使用、usage_signal +0.12)
    2026-03-02  promoted: candidate → stable
    2026-03-15  reinforced (hypothesis verification、edge_reinforcements に記録)
    2026-04-18  promoted: stable → core
    2026-04-22  reinforced (perspective "SINDy と Koopman"、保存済)

  現状: core, confidence 0.96, 累積使用 42 回
  参照している review/: hypothesis_candidates/manifold-sindy.md, perspectives/sindy-koopman.md
```

#### 技術基盤（詳細は Spec 5 参照）

- edge_events.jsonl のイベント種別一覧（created / reinforced / decayed / promoted / demoted / rejected / merged） → **§5.10**
- `rw audit graph --events` の矛盾検出ロジック（rejected 済 edge に reinforcement 等） → **Spec 5 Graph Hygiene**
- perspective / hypothesis の traversed_edges / edge_reinforcements からの逆引き → **§5.9.1, §5.9.2**

#### Dangerous op category

- **history 表示・監査**: 非 dangerous（読込のみ）
- **event 削除**: 無（append-only、訂正は compensating event で表現）

#### シナリオ間連携

- **Scenario 10**: graph audit の events 整合性チェック
- **Scenario 13**: evidence.jsonl との cross-check
- **Scenario 14**: perspective/hypothesis の traceability 提供
- **Scenario 36**: Hygiene の driver となる events の総覧

---

## 9. 将来拡張

### Scenario 21: 外部ソース自動取り込み

**Priority**: Future  
**Status**: 将来拡張、roadmap

**概要**: Zotero / arXiv / Readwise 等の外部ソースから定期的に raw/ に取り込む（sync 系コマンド、将来設計）。

**課題**: 各外部ソース固有の API / 認証、メタデータ変換

---

### Scenario 22: 外部 Export

**Priority**: Future  
**Status**: 将来拡張、roadmap

**概要**: wiki/ から講演スライド、論文素材、Web ページ等を生成する export 系コマンド（将来設計）。

---

### Scenario 23: 複数人 Vault

**Priority**: Future  
**Status**: 将来拡張、roadmap（`multi-user-collaboration`）

**概要**: チームで共有 Vault を運用、approve の排他制御、reviewer 管理。

---

### Scenario 24: 複数 Vault 横断

**Priority**: Future  
**Status**: 将来拡張、roadmap（`multi-user-collaboration`）

**概要**: 個人 Vault とチーム Vault の連携、知識の export/import。

---

### Scenario 28: Vault スキーマ migration（先送り）

**Priority**: Future  
**Status**: v2 MVP 外、roadmap（`vault-migration-framework`）

**概要**: frontmatter スキーマや JSON ログ schema の破壊的変更に対する共通マイグレーション基盤。

**v2 方針**: 個別スペック毎に CHANGELOG + requirements で対応。

---

### Scenario 29: Dirty tree と並行操作

**Priority**: Future  
**Status**: 将来拡張、`multi-user-collaboration`

**概要**: 複数セッション・並行 CLI 実行時のロック、タイムスタンプ管理、競合解決。

---

### Scenario 31: Vault ポータビリティ

**Priority**: Future  
**Status**: 将来拡張、`multi-user-collaboration`

**概要**: Vault の別マシンへの移動、マルチデバイス同期、symlink の可搬化。

---

## 10. シナリオ連携と改訂履歴

### 10.1 シナリオ間の連携関係

#### Scenario 15 ↔ Scenario 25: 対話の二次利用

- Scenario 15（interactive_synthesis）の対話ログが `raw/llm_logs/interactive/*.md` に**自動保存**
- 後日 Scenario 25（llm_log_extract）の対象に
- 同じ対話を 2 観点から再利用: content-centric（即時）/ process-centric（後日）

#### Scenario 7 ↔ Scenario 11 ↔ Scenario 8: 既存知識の進化サイクル

- 7（extend）で新情報を追記
- 11（deprecate）で古い記述を処遇
- 8（merge）で重複を統合

#### Scenario 16 ↔ Scenario 14: query → synthesis の知識創発

- 14（perspective / hypothesis）で探索
- 16（query promote）で優れた探索結果を synthesis に昇格

#### Scenario 26 ↔ Scenario 10: 2 層の ERROR 修正ループ

- 26: raw/incoming/ 層の lint FAIL リカバリ
- 10: wiki/ 層の audit ERROR 修正（v0.7 で L2 graph consistency も統合）
- 層が違うだけで「FAIL 検出 → 修復ループ → 再検証」のパターンは共通

#### Scenario 34-38 ↔ Scenario 14: L2 Graph Ledger サイクル（v0.7 新規）

- 34（extract-relations）で L2 candidate edges を供給
- 35（reject workflow）で品質フィルタ
- 36（Hygiene）で confidence 再計算・lifecycle 遷移
- 37（lifecycle 管理）で edge 状態を可視化
- 38（edge events 監査）でトレーサビリティ維持
- 14（perspective/hypothesis）が L2 の最終需要者、使用 signal が Hygiene にフィードバック

#### Scenario 13 ↔ Scenario 10 ↔ Scenario 38: Evidence / Graph 整合性の 3 層（v0.7 新規）

- 13（evidence 検証）: L1↔L2 の evidence chain（dangling evidence 検出）
- 10（audit ERROR）: `rw audit graph` で L2↔L3 の cache 整合
- 38（edge events 監査）: L2 内部の event 整合（reject 済に reinforcement 等）

#### Scenario 18 ↔ Scenario 33: L2 state サマリの共通基盤（v0.7 新規）

- 18（pre-flight）と 33（Maintenance UX）は同じ L2 state サマリを使用
- pre-flight は dangerous op 前、Maintenance UX は定常的 surface

---

### 10.2 改訂履歴

| 日付 | 版 | 変更 |
|------|-----|------|
| 2026-04-24 | Draft v0.1 | 初版作成、Scenario 7-33 を整理 |
| 2026-04-24 | Draft v0.2 | Scenario 14 を Group A-D 4 回議論で完全要件化（概念設計 / 技術基盤 / Hypothesis 専用 / UX）。Open Questions 10 項目すべて解決。Status を「未議論」→「合意済」に更新 |
| 2026-04-24 | Draft v0.3 | Scenario 15 を 5 論点議論で完全要件化（Perspective との境界、動的質問生成、Autonomous mode 連携、Skill 属性、ログ命名と構造化）。`dialogue_guide:` frontmatter、ログディレクトリ分離（`interactive/` / `chat-sessions/` / `manual/`）を確定 |
| 2026-04-24 | Draft v0.4 | Scenario 16 を 5 論点議論で完全要件化（synthesis_candidate 判定、4 ファイル → 1 synthesis 変換、evidence 転記、衝突解決、dangerous op 認定）。インライン `[evidence: ...]` マーカー + `promoted_from:` / `query_id:` frontmatter、8 段階対話必須を確定。Scenario 14 hypothesis promote が 16 の特殊形であることを明記 |
| 2026-04-24 | Draft v0.5 | consolidated-spec §11.3 の v1→v2 命名対応表との齟齬を修正: (a) ユーザー発話 `synthesize したい` → `蒸留（distill）したい` (b) `promoted: true` フラグ → `status: promoted`（v2 lifecycle 統合） (c) llm_logs パス構造の統一（`interactive/`・`chat-sessions/`・`manual/` サブディレクトリ形式に Scenario 14/15/25 全体を揃える） |
| 2026-04-24 | Draft v0.6 | UX 方針転換の反映: §1 ビジョンに**コマンド 4 Level 階層**を追加（L1 発見 / L2 判断 / L3 メンテ LLM ガイド / L4 Power user）。Scenario 33 を「Ambiguity 時の UX」から**「メンテナンス UX 全般原則」**に拡張、複合診断・オーケストレーション・Autonomous maintenance の 3 シーンを明記。consolidated-spec §2.11 として中核原則化した内容と対応 |
| 2026-04-25 | Draft v0.7 (Phase A + Scenario 14 完全書き直し) | **3 層アーキテクチャ統合**: §1 ビジョンに L1/L2/L3 明示、Edge status / Page status の区別、Evidence-backed Candidate Graph 原則を反映。§2 シナリオ分類表を v0.7 状態に更新（Scenario 34-38 追加、Layer 列追加）。**Scenario 14 完全書き直し**: L2 Graph Ledger 中心の設計、evidence_id / edge_id による参照、perspective の traversed_edges 追跡、Hypothesis 検証で edge reinforcement、3 種類 status（Page/Edge/Hypothesis）の明示、Trust chain の L1→L2→L3 連鎖を明記、メンテナンス autonomous に reject queue / Hygiene / typed edges 率を含める |
| 2026-04-25 | Draft v0.7.1（Phase B-1 完了: scenario 簡略化 + L2 統合） | **方針転換**「シナリオに仕様を書き込むのは過剰、内部動作は spec に委譲」を受け、Scenario 14 の YAML config / frontmatter schema / Step 1-5 詳細等を consolidated-spec §5.9.1 / §5.9.2 / Spec 5 / Spec 6 参照に委譲（~40% 削減）。**Scenario 13/10/18/33 を L2 統合で v0.7 書き換え**: 13 evidence.jsonl 一級市民化、10 `rw audit graph` 追加、18 pre-flight に L2 state サマリ、33 maintenance surface に reject queue / decay / typed-edge 率。**Scenario 34-38 skeleton 追加**: extract-relations / reject workflow / Hygiene 実行 / lifecycle 管理 / edge events 監査（全 skeleton、詳細は Spec 5 所管）。**Scenario 12/15/20/25 軽微更新**: Layer 列追加、L2 連携注記。**§10 付録 v0.7 対応**: シナリオ連携に 4 組追加、review layer 表に L2 ledger ファイル群を併記、skill マッピング v0.7 更新。 |
| 2026-04-25 | Draft v0.7.2（Phase B-1 仕上げ: 純粋なユースケース集化） | 「シナリオには**シナリオ以外を書かない**」方針を徹底。**削除**: §1 ビジョン要約（Trust+Graph+Perspective+Hypothesis、3 層アーキテクチャ、Graph Ledger 核心、中核原則、コマンド階層 4 Level — 全て consolidated-spec §1-§3 に所管）、各シナリオの `#### 内部動作` セクション全削（Scenario 26/15/25/7/8/9/11/12/17/19/20）、§10.2 共通パターン・§10.3 Skill マッピング・§10.4 Review 層の種類（横断仕様で scenarios スコープ外、consolidated-spec 所管）。**残置**: シナリオ本体、§1 索引表、§10.1 シナリオ間連携、§10.2 改訂履歴。各シナリオでは **コマンド（ユーザー視点）** と **Dangerous op category** / **Edge cases** / **シナリオ間連携** のみ残し、frontmatter スキーマ・File operations・Skill 定義・差分マーカー書式・git 操作詳細等は全て対応 Spec 参照に委譲。 |
| 2026-04-25 | Draft v0.7.3（未定コマンド詳細の抽象化） | 「詳細未定なコマンドを含むと spec 策定時に混乱する」方針を受け、**全シナリオの具体的な CLI コマンド表記を「ユーザーが呼ぶ意図」のリストに置換**。削除: 詳細 flag（`--since "7 days"`, `--only-pass`, `--max-questions N`, `--commit <sha>`, `--dry-run`, `--yes`, `--auto-fixable-only`, `--check-all`, `--filter=...` 等）、サブコマンド列挙表（`rw tag scan/stats/diff/merge/split/rename/...`, `rw skill draft/test/install/list/show/...`, `rw merge preview/cancel`, `rw query promote/promote-preview/list`）、Scenario 34-38 タイトルからの具体コマンド名括弧、将来拡張の `rw sync --source zotero ...`, `rw export --format marp` 等。**残置**: ユーザー意図記述と、そのコマンドの正式仕様が所管 Spec（主に Spec 4 CLI / Spec 2 Skill / Spec 5 L2 / Spec 7 Audit）であることの明示。 |
| 2026-04-25 | Draft v0.7.5（Scenario 9 / 26 未議論の High gap 解消） | 「未議論」扱いだった 2 シナリオを精査し、High 優先度 gap 計 5 件を解消。MVP 全 22 件が合意済 or skeleton に到達:<br>• **Scenario 26 Incoming lint-fail リカバリ**:<br>  - Gap #1（pending list 機構）解消: `rw lint --show-pending` の出力例、長期滞留時の Maintenance autonomous 通知（Scenario 33 連携）、retry 機構は Spec 0/4 所管<br>  - Gap #3（修復方法 (b)(c) の詳細）解消: (b) 一括修復は frontmatter_completion skill 経由で全件 proposal、user が一括/個別 approve、(c) 個別対話は rw chat で 1 ファイルずつ深掘り。修復行為は decision_log に記録（§2.13 連携）<br>  - Status: 未議論 → 合意済（v0.7.5、High gap 解消、Medium 残）<br>• **Scenario 9 肥大化 wiki ページ分割**:<br>  - Gap #1（L2 edges 振り分け）解消: 元ページ id を持つ edges を分割後ページに振り分け（Spec 5 API 経由）、各 edge の evidence_ids を継承して trust chain 保全<br>  - Gap #3（Trust chain 保全）解消: L1 raw / L2 evidence は不変、L2 edges を振り分け、`split_event` を edge_events.jsonl に記録（type: split_origin / split_target）、分割後 audit graph で verify<br>  - Gap #7（Curation Provenance）解消: split は重要 decision として decision_log に reasoning 必須記録（章ごとの振り分け理由、user 判断と alternatives）<br>  - Status: 未議論 → 合意済（v0.7.5、High gap 解消、Medium 残）<br>• **Index 表更新**: 集計を MVP 22 件（合意済 18 / skeleton 5 / 未議論 0）に、凡例から「未議論」を削除（0 件到達）<br>• **残 Medium gap**: Scenario 26 は WARN 細分化 / skill prompt 仕様 / Curation 記録粒度、Scenario 9 は分割閾値 default / 段階的分割 / 自動 trigger / Hypothesis scoring 影響等。これらは Spec 7 / Spec 0 / Spec 2 起票時に決定可能。 |
| 2026-04-25 | Draft v0.7.4（シナリオ間矛盾レビュー patch） | 9 次元 thorough レビューを実施し、Medium 2 件を修正:<br>• **Scenario 34 Related を補完**: Scenario 15（interactive_synthesis 対話ログが抽出素材）と Scenario 25（llm_log_extract と同素材から extract 可能）への双方向参照を追加。ユースケース説明にも `raw/llm_logs/` 由来の対話ログが入力源である旨を明記<br>• **Scenario 10 / 13 の audit 責務分離**: `rw audit graph`（Scenario 10）= L2 graph 構造整合性（cache 乖離 / event 矛盾 / rejected 再出現）、`rw audit evidence`（Scenario 13）= evidence chain 健全性（raw 死活 / dangling 深掘り / trust 分断）、重複領域である L2 dangling evidence 参照は「Scenario 10 で第一次検出 → Scenario 13 で深掘り」という役割分担を両シナリオに明記<br><br>**誤検として却下した 4 件**（検査済みとして記録）:<br>• Scenario 14 hypothesis approve と Scenario 16 query promote の dangerous op 分類差 — 両方「最高 / 8 段階必須」で既に整合、実装複雑度の違いは dangerous op 分類とは別次元<br>• Scenario 12 `.rwiki/vocabulary/tags.yml` と Scenario 33 のパス表記差 — Scenario 33 は maintenance UX 診断で Scenario 12（vocabulary 所管）に委譲する構造（既に「← Scenario 12」参照あり）、矛盾ではない<br>• Scenario 7 ↔ 11 の Related 片方向参照 — 実際は双方向記載あり（agent の自己誤検）<br>• Perspective autonomous mode の記録先不明 — Scenario 14 §4「結果の記録形式」で `review/perspectives/` と明示済み<br><br>**スキップ**（Low 1 件）: Scenario 8 synthesis merge の skill 名明示 — skill 詳細は Spec 2 (skill-library) 所管、scenarios 側で書かない方針と整合 |

---

_本ドキュメントは `rwiki-v2-consolidated-spec.md` と並行参照される。v0.7.5 時点で全 MVP scenario が合意済 or skeleton に到達（未議論 0 件）、コマンド仕様は全て対応 Spec 所管。_
