# Research & Design Decisions: rwiki-v2-foundation

## Summary

- **Feature**: `rwiki-v2-foundation`
- **Discovery Scope**: Extension (規範文書 spec、外部 library / API 探索不要、SSoT 出典 = consolidated-spec v0.7.12 §1-6 / §7.2 / §11.2 への構造マッピング中心)
- **Key Findings**:
  - 14 Requirements の subject は全て `the Foundation`、述語は「shall ～を記述する／含める／明示する」型 (規範文書生成 spec の特性)
  - testability スコープは brief.md Coordination で 4 種に限定 (章節アンカー存在 / SSoT 章番号整合 / 用語集引用 link 切れ / frontmatter schema 妥当性)、内容妥当性 verifier は不採用
  - Foundation 改版時は roadmap.md L163 Adjacent Spec Synchronization 運用 + 傘下 7 spec 全件波及精査 (memory feedback_review_rounds.md 第 5 ラウンド規定) の二重 gate
  - 実装レベル決定 (Severity 4 / Exit code 0/1/2 / LLM CLI subprocess timeout / モジュール責務分割 / CLI 命名統一) は roadmap.md L132- が SSoT で Foundation 規範対象外 (brief.md Coordination)

## Research Log

### Foundation 文書の物理 path

- **Context**: Foundation 規範文書本体を `.kiro/specs/` 内に置くか、`docs/` 等の独立場所に置くかで Spec 1-7 からの引用 path の安定性と spec ライフサイクル整合が変わる
- **Sources Consulted**: brief.md / R10.1-R10.8 / steering structure.md L75-97 (開発リポジトリ構造) / 既 approve 済 Spec 1-7 の SSoT 出典記述パターン
- **Findings**:
  - 既 approve 済 Spec 1-7 は consolidated-spec を `.kiro/drafts/` から引用しており、`.kiro/specs/` 配下からの引用はまだ確立されていない
  - design.md / requirements.md と同じディレクトリに foundation.md を置くと、spec.json.updated_at と Adjacent Sync の追跡単位が一致する
  - 案 A (`.kiro/specs/rwiki-v2-foundation/foundation.md`) を採用: spec ライフサイクルと規範文書ライフサイクルを一致させる
- **Implications**:
  - Spec 1-7 design 内の引用は `.kiro/specs/rwiki-v2-foundation/foundation.md#section-name` 形式 (相対 path or repo-root path) に固定される
  - Foundation 改版 = `foundation.md` 改版 = `spec.json.updated_at` 更新 + design.md change log 追記 (Adjacent Sync 運用と整合)

### 検証手段 4 種の実装スコープ

- **Context**: brief.md で「章節アンカー / SSoT 章番号整合 / 用語集引用 link 切れ / frontmatter schema 妥当性」の 4 検証を design phase で確定すると規定されている。実装担当 spec の選択
- **Sources Consulted**: Spec 4 R4.5 (rw doctor) / Spec 4 R16.8 (健全性診断 4 項目) / brief.md Coordination Section 1
- **Findings**:
  - Spec 4 は既に `rw doctor` 系の健全性診断 CLI を所管しており (R4.5 / R16.8)、Foundation 検証もこの diagnostic interface に自然に統合できる
  - 案 Y (規範 = Spec 0 / 実装 = Spec 4) を採用: Spec 0 は「規範 spec」の境界を保ち、CLI 実装は Spec 4 に委譲
  - Phase 2 (Spec 4 design 着手時) で Spec 0 検証 4 種を `rw doctor foundation` サブコマンドとして組み込む coordination が必要
- **Implications**:
  - Spec 0 design は検証 4 種の **schema 規範** (何を検査するか / 入出力 / severity) を確定
  - Spec 0 design は Python script 実装は持たず、Phase 2 Spec 4 design へ Adjacent Sync coordination 申し送り
  - 検証スクリプトの物理位置は Spec 4 が確定 (例: `scripts/rw_doctor.py` 内の `check_foundation()` 関数)

### Foundation 文書の章立て構造

- **Context**: R14.3 で「章立て番号を SSoT と整合させる」と規定。consolidated-spec §1-6 への対応をどう取るか
- **Sources Consulted**: consolidated-spec §1-6 sub-section 構造 (TOC) / R1-R14 各 AC の対応関係
- **Findings**:
  - consolidated-spec §1.1-§1.5 (ビジョン) / §2.0-§2.13 (13 原則) / §3.1-§3.5 (アーキテクチャ) / §4.1-§4.5 (用語集) / §5.1-§5.10 (frontmatter) / §6.1-§6.2 (Task & Command) は完全な構造を持つ
  - Foundation 文書は consolidated-spec の §1-6 + §11.2 設計決定事項 + §11.3 v1→v2 命名対応を **Foundation 章立てに直接マップ** することで R14.3 を満たせる
  - 案 P (consolidated-spec §1-6 を Foundation 文書 §1-6 に直接対応) を採用、案 Q (独自番号体系) は drift リスクで却下
- **Implications**:
  - Foundation 章立て = §1 ビジョンと中核価値 / §2 13 中核原則 + §2.0 層別適用マトリクス / §3 3 層アーキテクチャ / §4 用語集 5 分類 / §5 Frontmatter スキーマ骨格 / §6 Task & Command モデル / §7 改版手順と SSoT 検証 / §8 設計決定事項 (ADR 代替) / §9 v1→v2 対応 + 環境前提
  - SSoT 出典の章番号整合は `.kiro/drafts/rwiki-v2-consolidated-spec.md` v0.7.12 の現状を baseline として Foundation 内に明示

### 「設計決定事項」セクションのフォーマット

- **Context**: ADR 不採用方針 (memory feedback_design_decisions_record.md) のもと、design.md と foundation.md の両方で「設計決定事項」セクションをどう構造化するか
- **Sources Consulted**: drafts §11.2 v0.7.10 決定 5-1〜6-3 の記述形式 / memory feedback_design_decisions_record.md の二重記録規定
- **Findings**:
  - drafts §11.2 形式 = 「決定 N-M: タイトル / 経緯 / 決定 / 影響」の 4 項目構造で、過去の議論ログから昇格された設計決定を恒久記録
  - 二重記録方式: design.md 本文「設計決定事項」セクション (決定の詳細) + change log (1 行サマリ「YYYY-MM-DD 決定 N-M 確定 (タイトル)」)
- **Implications**:
  - design.md §「設計決定事項」 + design.md change log の二重記録を採用
  - foundation.md §8 にも「設計決定事項」セクションを設け、規範レベルの決定 (例: Foundation 改版手順の運用ルール / 検証 4 種の実装委譲先) を恒久記録

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Document-as-Spec | 規範文書本体 (foundation.md) を spec ディレクトリ内に独立配置、design.md は文書設計のみ | spec ライフサイクル一致、Adjacent Sync 単位明示 | foundation.md と design.md の境界を読み手に説明する必要 | 案 A 採択、本 spec の特性に最適 |
| Doc-Embedded | 規範本体を design.md に埋め込み、独立 foundation.md を持たない | ファイル数最小 | design 文書と規範文書の役割混在、サイズ肥大 | 案 C 却下 |
| External-Doc | docs/foundation.md として独立配置、spec から参照 | ユーザーアクセス容易 | spec ライフサイクルと規範ライフサイクルの二重管理 | 案 B 却下 |

## Design Decisions

### Decision: `Foundation 文書本体の物理 path = .kiro/specs/rwiki-v2-foundation/foundation.md`

- **Context**: Foundation 規範文書本体を spec 内・`docs/` 独立配置・design.md 埋込のいずれにするか
- **Alternatives Considered**:
  1. 案 A: `.kiro/specs/rwiki-v2-foundation/foundation.md` (採択)
  2. 案 B: `docs/foundation.md` (却下: spec ライフサイクル不整合)
  3. 案 C: design.md 本文に埋込 (却下: 役割混在 + サイズ肥大)
- **Selected Approach**: 案 A、Spec 1-7 は `.kiro/specs/rwiki-v2-foundation/foundation.md#anchor` 形式で引用
- **Rationale**: spec.json.updated_at と Adjacent Sync 運用 (`_change log`) が foundation.md の改版単位と一致し、Spec 1-7 から見た SSoT path の安定性も保たれる
- **Trade-offs**: ユーザーから見た規範文書アクセスは `docs/` より深い path になるが、Spec 1-7 引用整合のほうが優先
- **Follow-up**: Phase 2 (Spec 4 design) 時に `rw doctor` から foundation.md path を hardcode するか config で抽象化するか確定

### Decision: `検証 4 種の規範 = Spec 0 / 実装 = Spec 4`

- **Context**: brief.md で 4 種検証を design phase で確定と規定、実装担当 spec を選択
- **Alternatives Considered**:
  1. 案 Y: 規範 = Spec 0 / 実装 = Spec 4 (採択)
  2. 案 X: Spec 0 内で `validate_foundation.py` を実装 (却下: 規範 spec 境界混在)
  3. 案 Z: 機械検証スキップ、人間レビューのみ (却下: brief.md で 4 種実施を固定済)
- **Selected Approach**: Spec 0 design §「検証手段の規範」で 4 種の schema (検査内容 / 入出力 / severity) を確定、実装は Phase 2 Spec 4 design で `rw doctor foundation` サブコマンドとして組み込む
- **Rationale**: Spec 4 は既に `rw doctor` 系の健全性診断 CLI を所管しており、Foundation 検証はこの interface に自然に統合できる。Spec 0 の規範 spec 境界 (CLI 実装を持たない) を守る
- **Trade-offs**: Phase 2 で coordination 必要、Foundation 改版時に検証 spec 側 (Spec 4) も Adjacent Sync 対象になる
- **Follow-up**: Phase 2 (Spec 4 design 着手) で `rw doctor foundation` サブコマンドの正式仕様を確定

### Decision: `Foundation 章立て = consolidated-spec §1-6 直接対応 + §7-9 (改版手順 / 設計決定 / 環境前提)`

- **Context**: R14.3 「章立て番号を SSoT と整合させる」の実装方法
- **Alternatives Considered**:
  1. 案 P: consolidated-spec §1-6 を Foundation §1-6 に直接対応 (採択)
  2. 案 Q: Foundation 独自番号体系 (却下: drift リスク)
- **Selected Approach**: Foundation 章立て = §1 ビジョン / §2 13 原則 + §2.0 マトリクス / §3 3 層アーキテクチャ / §4 用語集 / §5 frontmatter / §6 Task & Command / §7 改版手順と SSoT 検証 / §8 設計決定事項 / §9 v1→v2 対応 + 環境前提
- **Rationale**: SSoT 出典 (consolidated-spec) と Foundation の章番号が一致するため、改版時の追跡が機械的に行える
- **Trade-offs**: consolidated-spec が将来章立てを変更した場合、Foundation も追従改版が必要 (Adjacent Sync 運用で吸収)
- **Follow-up**: 検証 4 種の 1 つ「SSoT 章番号整合検査」がこの decision を機械的に守る役割

### Decision: `設計決定事項の二重記録方式 (design.md 本文 + change log) を採用`

- **Context**: ADR 独立ファイルは過去機能しなかった (memory feedback_design_decisions_record.md)、代替記録方式を確定
- **Alternatives Considered**:
  1. 案 1: drafts §11.2 形式 (タイトル / 経緯 / 決定 / 影響 4 項目) で design.md 本文 + change log 二重記録 (採択)
  2. 案 2: 簡易形式 (タイトル + 決定 + 一文根拠) (却下: 経緯が失われると将来読み手が判断根拠を再構成できない)
- **Selected Approach**: design.md §「設計決定事項」セクションに drafts §11.2 形式で詳細記録、design.md 末尾 change log に「YYYY-MM-DD 決定 N-M 確定 (タイトル)」1 行サマリ
- **Rationale**: memory feedback_design_decisions_record.md で確立済の方針、drafts §11.2 v0.7.10-v0.7.12 で実績済の形式
- **Trade-offs**: 二重記録のメンテナンス負荷は微増、しかし change log のみで決定の存在を grep 可能になり長期可読性が向上
- **Follow-up**: Phase 1-5 全 spec design で同形式を踏襲

## Risks & Mitigations

- **Risk 1**: consolidated-spec が draft (v0.7.12) のため、Foundation 章立て確定後に SSoT 出典が改版される可能性 → **Mitigation**: Foundation 章立てを SSoT に整合 (R14.3) させ、SSoT 改版時は Adjacent Sync 運用 (`spec.json.updated_at` + change log) で追従、検証 4 種の 1 つ「SSoT 章番号整合検査」が drift を機械検出
- **Risk 2**: 「規範 = Spec 0 / 実装 = Spec 4」の coordination が Phase 2 で破綻するリスク (Spec 4 が `rw doctor foundation` を所管しないと宣言する) → **Mitigation**: Phase 1 完了時に Phase 2 引き継ぎノート (Adjacent Sync TODO) を design.md change log に明記、Spec 4 design 着手時の coordination チェック項目に追加
- **Risk 3**: 検証 4 種以外の機械検証要望が将来出るリスク (例: 13 原則の表記揺れ自動検査 / 用語集の整合性検査の自動化) → **Mitigation**: brief.md で「検証範囲は 4 種に限定 (= 設計上限)」と固定済、scope creep は Adjacent Sync 経由で本 spec を改版する手続きで吸収
- **Risk 4**: Foundation 改版時に傘下 7 spec への波及精査が省略されるリスク → **Mitigation**: memory feedback_review_rounds.md 第 5 ラウンドで Foundation 改版時の傘下 7 spec 全件精査を必須プロセス化済、本 design でも改版手順 §7 にこの規律を明記

## References

- [consolidated-spec v0.7.12](.kiro/drafts/rwiki-v2-consolidated-spec.md) — SSoT 出典、§1-6 / §7.2 Spec 0 / §11.2 設計決定事項 / §11.3 v1→v2 命名対応
- [roadmap.md L132-](/.kiro/steering/roadmap.md) — v1 から継承される実装レベル決定の SSoT (Foundation 規範対象外)
- [roadmap.md L163-](/.kiro/steering/roadmap.md) — Adjacent Spec Synchronization 運用ルール
- [memory feedback_design_decisions_record.md](~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_design_decisions_record.md) — 二重記録方式の根拠
- [memory feedback_review_rounds.md](~/.claude/projects/-Users-Daily-Development-Rwiki-dev/memory/feedback_review_rounds.md) — Foundation 改版時の傘下 7 spec 精査必須プロセス
