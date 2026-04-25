# Roadmap

> 出典: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 §7, §9

## Overview

Rwiki v2 は **Curated GraphRAG**（候補 graph + 人間承認 wiki + Hygiene + Evidence chain + Perspective/Hypothesis 生成）の実装。**フルスクラッチ**で再構築（v1 は `v1-archive/` に退避済、参照のみ）。

8 spec を 5 Phase の依存順で起票・実装する。

## Approach Decision

- **Chosen**: Curated GraphRAG（候補 graph + 人間承認 + Hygiene + Evidence chain）
- **Why**: 入力コスト問題（全件 approve 必須が知識蓄積のボトルネック）を reject-only で解消しつつ、L3 wiki の trust 担保と graph as first-class を両立できる唯一の構成
- **Rejected alternatives**:
  - **全件 approve（通常型）**: 入力コスト問題が再発、知識蓄積が頭打ち
  - **Graph DB 正本（Neo4j 等）**: diff 管理困難、trust chain の人間検証困難、append-only の git 親和性を失う
  - **完全自動 Hygiene（人間 reject なし）**: 誤抽出が unrejected のまま蓄積、reject_learner が学習素材を持てない
  - **L2 を review 経由（§2.2 適用）**: 全件レビュー復活で入力コスト問題が再発

## Constraints

- **フルスクラッチ方針**: v1 は `v1-archive/` に隔離、v2 spec は v1 を知らない前提で新名称のみ自己完結（§9.1）
- **LLM 非依存**: 特定 LLM CLI に縛らない、Spec 3 で抽象層を定義
- **Python 3.10+**: 型ヒント完全対応、追加依存は networkx ≥ 3.0 のみ
- **Git 必須**: trust chain の保全媒体、層別補助履歴（edge_events.jsonl / frontmatter update_history）と併用
- **エディタ非依存**: Obsidian は推奨だが必須ではない、生成 markdown は任意エディタで編集可能
- **L2 append-only JSONL**: edges / events / evidence / rejected_edges は全て JSONL、derived sqlite cache は gitignore
- **Concurrency lock**: `.rwiki/.hygiene.lock` で Hygiene バッチと CLI 操作を排他（Spec 4 ↔ Spec 5）
- **Reject 理由必須**: rejected_edges.jsonl の `reject_reason_text` は空文字禁止（reject_learner 学習素材）

## Specs (dependency order)

- [ ] rwiki-v2-foundation -- 傘 spec、ビジョン・原則・用語集・3 層アーキテクチャ. Dependencies: none
- [ ] rwiki-v2-classification -- カテゴリ、frontmatter、vocabulary. Dependencies: rwiki-v2-foundation
- [ ] rwiki-v2-cli-mode-unification -- rw chat、全コマンド rw 統一、対話 default. Dependencies: rwiki-v2-foundation, rwiki-v2-classification
- [ ] rwiki-v2-lifecycle-management -- deprecate/retract/archive/merge/split/rollback. Dependencies: rwiki-v2-foundation, rwiki-v2-classification
- [ ] rwiki-v2-knowledge-graph -- typed edges、graph query、P0-P4 段階実装. Dependencies: rwiki-v2-foundation, rwiki-v2-classification, rwiki-v2-cli-mode-unification, rwiki-v2-lifecycle-management
- [ ] rwiki-v2-skill-library -- スキル定義・dispatch・custom skill、extraction skills 含む. Dependencies: rwiki-v2-knowledge-graph
- [ ] rwiki-v2-prompt-dispatch -- スキル選択メカニズム. Dependencies: rwiki-v2-classification, rwiki-v2-skill-library
- [ ] rwiki-v2-perspective-generation -- 視点創発・仮説生成（本丸）. Dependencies: rwiki-v2-foundation, rwiki-v2-classification, rwiki-v2-cli-mode-unification, rwiki-v2-lifecycle-management, rwiki-v2-knowledge-graph, rwiki-v2-skill-library, rwiki-v2-prompt-dispatch

## 5 Phase 実装順序

```
Phase 1: Foundation
  Spec 0 (foundation: 3 層、13 中核原則、用語集)
    ↓
  Spec 1 (classification: L3 frontmatter、tag vocabulary、categories.yml)

Phase 2: L3 操作基盤
  Spec 4 (cli-mode-unification: 全コマンド、chat、Maintenance UX)
    ↓
  Spec 7 (lifecycle-management: Page + Edge lifecycle 連携)

Phase 3: L2 Graph Ledger（最重要・最大規模）
  Spec 5 (knowledge-graph: 内部 P0-P4 で段階実装)
    P0: Ledger 基盤（edges/evidence/entities/scorer）
    P1: Query cache（sqlite + neighbor/path/orphans/hubs API）
    P2: Usage event + Hygiene 基礎（Decay/Reinforce/Comp L1）
    [MVP 範囲はここまで = P0+P1+P2]
    P3: Competition L2/L3 + Edge Merging（v0.8 候補）
    P4: 外部 Graph DB export（optional）
    ↓
  Spec 2 (skill-library: extraction skills 含む)

Phase 4: Skill Dispatch
  Spec 3 (prompt-dispatch: skill 選択ロジック)

Phase 5: 本丸
  Spec 6 (perspective + hypothesis: standalone CLI + skill invoke)
```

### 順序理由

1. Spec 0 → 1: Foundation と L3 frontmatter スキーマが全 spec の基盤
2. Spec 4 → 7 を Spec 5 より前: CLI 統一と Page lifecycle が揃えば Spec 5 の CLI entry 点が決まる
3. Spec 5 の先行実装: Spec 2 の extraction skill は Spec 5 の `edges.jsonl` / Query API に書き込む
4. Spec 2 → 3: Skill library が定義されてから dispatch ロジックを詰める
5. Spec 6 を最後: 全前 spec に依存

### Coordination 必要事項（起票中に決定）

- **Spec 1 ↔ Spec 3**: frontmatter 推奨フィールドに `type:` 追加（distill dispatch の手掛かり）
- **Spec 1 ↔ Spec 3**: `categories.yml` の default_skill mapping 方式（inline / 別ファイル）
- **Spec 2 ↔ Spec 5**: extraction skill（relation_extraction / entity_extraction）の出力 validation interface
- **Spec 5 ↔ Spec 7**: Page deprecation → Edge demotion の interaction flow
- **Spec 4 ↔ Spec 5**: `.rwiki/.hygiene.lock` concurrency strategy の整合

## MVP 範囲（v2.0）

**含まれる**:

- Spec 0-7 全 spec、Spec 5 は P0+P1+P2 まで
- Scenario 7, 8, 10, 11, 12, 14, 15, 16, 17, 19, 20, 25, 33（合意済 13 件）
- Scenario 13, 18, 26（v0.7.1 で L2 統合書き換え済）
- Scenario 34-38（skeleton、Spec 5 P0+P1+P2 範囲）

**Phase 2（v0.8）以降に先送り**:

- Spec 5 P3（Competition L2/L3 + Edge Merging）
- Spec 5 P4（外部 Graph DB export）
- Scenario 9（ページ分割、未議論）
- Scenario 21-24, 28, 29, 31（外部連携・マルチ Vault・migration）

**Phase 2 起動条件**:

- MVP Vault 規模が拡大（edges > 10,000）し Competition L1 だけでは整理しきれない時
- チーム利用で multi-user 同期が必要になった時

## 期間見積り

合計: **11〜17 日（2〜3.5 週間）**

| Phase | 作業 | 期間 | 並列 |
|-------|------|:---:|:---:|
| 1a | Spec 0, 1 requirements | 2〜3 日 | — |
| 1b | Spec 0, 1 design + tasks | 2〜3 日 | — |
| 2a | Spec 4, 7 requirements | 2〜3 日 | 並列可 |
| 2b | Spec 4, 7 design + tasks | 2〜3 日 | 並列可 |
| 3a | Spec 5 requirements | 2〜3 日 | — |
| 3b | Spec 5 design + tasks | 3〜4 日 | — |
| 3c | Spec 5 実装（P0+P1+P2） | 4〜6 日 | — |
| 3d | Spec 2 spec 群 | 2〜3 日 | 3c 一部並列 |
| 4 | Spec 3 spec 群 | 1〜2 日 | — |
| 5a | Spec 6 spec 群 | 2〜3 日 | — |
| 5b | Spec 2,3,4,6,7 実装 | 6〜9 日 | 部分並列 |
| 6 | docs / steering 再構築 | 1〜2 日 | — |

## v1 から継承する技術決定

v1 で確定済の重要決定。v2 spec 起草時に再議論不要、そのまま継承する。

### Severity 4 水準（v1 severity-unification spec で確定）

`CRITICAL / ERROR / WARN / INFO`。AGENTS と CLI で同名 align。`map_severity()` は identity（4→3 マッピングコスト解消済）。

### Exit code 0/1/2 分離（v1 severity-unification）

`exit 0 = PASS / exit 1 = runtime error / exit 2 = FAIL 検出`。全コマンド共通。`cmd_ingest` 等は 0/1 のみ。

### LLM CLI subprocess timeout 必須（v1 cli-audit で確定）

v1 で未設定だった `call_claude()` ハングリスクが顕在化。v2 では timeout 必須、デフォルト値は spec ごとに決定。

### モジュール責務分割（v1 module-split で確定）

v1 で `rw_light.py` 3,490 行を 6 モジュール（rw_config / rw_utils / rw_prompt_engine / rw_audit / rw_query / rw_cli）に DAG 分割。v2 でも各モジュール ≤ 1,500 行・モジュール修飾参照（`rw_<module>.<symbol>`）・後方互換 re-export 禁止を継承。

### CLI 命名統一（v1 rw-light-rename で確定）

エントリポイント `rw_<責務>.py` パターン、`rw` symlink、`--reinstall-symlink` migration helper。v2 でも同パターンを採用。

### 先送り事項（v1 で起票したが v2 MVP に含めない）

- **vault-migration framework**: Scenario 28、外部ユーザーの実運用 Vault が増えるまで保留
- **multi-user-collaboration**: Scenario 29, 31、個人利用範囲を超える共有要求が発生するまで保留
- **observability-infra**（severity-unification Y Cut 残件）: drift 実例観察・下流 JSON consumer 特定・flakiness 報告のいずれかが顕在化するまで保留

## Governance

### Adjacent Spec Synchronization

後続 spec による先行 spec の `requirements.md` / `design.md` の整合更新は **再 approval を要求しない**。対象 spec の `spec.json.updated_at` 更新と各 markdown 末尾 `_change log` への 1 行追記で足りる。

**適用条件**: 更新が「先行 spec 変更による波及的な文言同期」であり、要件・設計の実質変更でないこと。

**根拠**: v1 severity-unification spec が cli-audit / cli-query / test-suite を整合更新した運用ルール（2026-04-20）を継承。

### Spec 完了マーク

- 起票時: `Spec N` を本ファイルの「Spec 一覧」に `- [ ]` で記載済
- 完了時: `- [x]` に更新、`spec.json.phase = "implemented"` を確認
- 各 phase 完了時: 本ファイルの完了状況を更新

### Coordination 合意の記録

spec 間 coordination で決定した事項は **両方の spec の design.md に記載**。片方だけだと将来読み手が他方を参照しない可能性がある。

## 開発フロー

各 spec は kiro 標準 3-phase 承認：

```
/kiro-spec-init {feature} "description"
   ↓
/kiro-spec-requirements {feature}    → 人間承認
   ↓
/kiro-validate-gap {feature}         （v1 暗黙仕様取込時）
   ↓
/kiro-spec-design {feature}          → 人間承認
   ↓
/kiro-validate-design {feature}      （optional）
   ↓
/kiro-spec-tasks {feature}           → 人間承認
   ↓
/kiro-impl {feature}                 （autonomous mode）
   ↓
/kiro-validate-impl {feature}
```

並列起票は `/kiro-spec-batch` を使用（本 roadmap の 5 Phase が dependency wave として機能）。

## 参考資料

- 詳細仕様: `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12
- ユースケース集: `.kiro/drafts/rwiki-v2-scenarios.md`
- v1 spec 退避: `.kiro/specs/v1-archive/`
- v1 実装退避: `v1-archive/`
- v1 → v2 命名対応: consolidated-spec §11.3
