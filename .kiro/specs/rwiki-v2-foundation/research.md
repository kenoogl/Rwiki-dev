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

## ラウンド別自動採択 / escalate 採択トレース (新方式 4 重検査 + Step 1b-v 自動深掘り、2026-04-28 遡り適用)

### ラウンド 1 (requirements 全 AC 網羅)

#### 軽-1: Traceability table R10 内部分断脚注追加 (自動採択)

- **検出**: design.md Requirements Traceability table で R10 が「10.1-10.4, 10.6-10.8」と「10.5」の 2 行に分かれているが脚注なし
- **1 回目深掘り (5 観点)**: 実装難易度容易 / 設計理念整合 / 運用整合性向上 / boundary 違反なし / Phase 1 整合 → 推奨案 X1 = 脚注追加
- **2 回目深掘り (5 切り口)**:
  - 本質的観点: §7 / §9 集約構造の整合性反映、本質的構造変更なし → 反転理由なし
  - 関連文書間矛盾: requirements.md R10.5 / design §9 集約と整合 → 反転理由なし
  - 仕様⇄実装突合: 該当なし
  - dev-log 23 パターン: 該当なし
  - 失敗+Phase 1 アナロジー: 該当なし
- **確度判定**: X1 == X2、5 切り口反転理由なし → **自動採択**
- **Edit 適用箇所**: design.md Traceability table 直後に脚注追加
- **user 通知**: ラウンド 1 提示時に [自動採択推奨] ラベル併記、案 A 異論なしで採択

#### 重-厳-1: R10.7 整合性検証手段 (a) のみ採用根拠 — escalate → 推奨案 A 採択

- **検出**: R10.7 で (a)/(b)/(c) のいずれか以上を design phase で確定すべき。design は (a) のみ採用と Error Handling L660 括弧書きで言及するも、(b)(c) 不採用根拠が設計決定事項として未記録
- **escalate 必須条件該当**: (3) 設計決定間矛盾 + (1) 複数選択肢 trade-off
- **5 観点深掘り (推奨案確証)**:
  - 案 A 設計決定事項 0-6 新規追加 (推奨)
  - 案 B Error Handling 強化のまま (dominated 除外: 二重記録方式と不整合 / grep 困難)
  - 案 C 要件改版で (b)(c) 削除 (dominated 除外: 規範範囲拡大 / 傘下 7 spec 波及精査必須)
- **確証根拠 5 点**: 実装容易 / 二重記録方式整合 / grep 可能 / boundary 違反なし / Phase 1 整合
- **user 判断**: 推奨案 A で進める (案 A 異論なし)
- **Edit 適用箇所**: design.md 設計決定事項 section に決定 0-6 新規追加 + change log 1 行サマリ

#### 重-厳-2: Performance target 規範範囲先取り — escalate → 推奨案 A 採択

- **検出**: design.md L707 「target: < 5 秒で完了」を Spec 0 で確定。requirements (R1-R14) に性能 AC なし = overcoverage、規範範囲先取り (Spec 0 R4 escalate「3 ヶ月超 ERROR 昇格」削除と同型)
- **escalate 必須条件該当**: (2) 規範範囲判断 + (1) 複数選択肢 trade-off
- **5 観点深掘り (推奨案確証)**:
  - 案 A target を示唆値化 + Phase 2 Spec 4 design 委譲明記 (推奨)
  - 案 B 規範として確定 (dominated 除外: 決定 0-2 と緊張 / boundary 違反疑い)
  - 案 C section 完全削除 (dominated 除外: Phase 2 申し送り情報損失)
- **確証根拠 5 点**: wording 変更で容易 / 決定 0-2 と整合 / Spec 4 で柔軟調整可 / boundary 違反なし / Spec 0 R4 escalate 同型処理
- **user 判断**: 推奨案 A で進める (案 A 異論なし)
- **Edit 適用箇所**: design.md L703-712 Performance section の wording 変更 (target → 示唆値 target)

### 厳しく再レビュー (本質的観点、user 指示で 2026-04-28 追加実施)

#### 重-厳-3: Components and Interfaces で §1 / §6 / §8 / §9 の独立 sub-section 欠落 — escalate → 推奨案 A 採択

- **検出**: design.md Components and Interfaces section の table (L281-292) に §1 ビジョン / §6 Task & Command / §8 設計決定事項 / §9 v1→v2 + 環境前提 が割り当てられているが、対応する独立 sub-section が欠落 (§2 / §3 / §4 / §5 / §7 のみ独立 sub-section あり = アーキテクチャレベル不均一)
- **本質的影響**: implementation phase の foundation.md 生成者は §2-§5 / §7 を Component 詳細から実装、§1 / §6 / §8 / §9 を table 1 行のみで実装する必要 = Foundation 構造の規範レベル不整合
- **escalate 必須条件該当**: (3) 設計決定間矛盾 (table と独立 sub-section の混在)
- **5 観点深掘り (推奨案確証)**:
  - 案 A §1 / §6 / §8 / §9 の独立 sub-section を §2-§5 / §7 と均一化のため追加 (推奨)
  - 案 B 修正不要 (table で十分、foundation.md 構造詳細は consolidated-spec が SSoT) — dominated 除外 (アーキテクチャレベル不均一が implementation phase で問題化)
- **確証根拠 5 点**: 実装容易 (4 sub-section 追加) / 設計理念整合 (§2-§5 / §7 と同形式) / 運用整合 (foundation 生成者の判断負荷低減) / boundary 違反なし / Phase 1 整合
- **user 判断**: 推奨案 A で進める (案 A 異論なし)
- **Edit 適用箇所**: design.md Components and Interfaces section に §1 / §6 / §8 / §9 の独立 sub-section 4 件を追加

#### 重-厳-4: subprocess shell injection 防止規律 — escalate → 推奨案 A 採択

- **検出**: design.md Security Considerations section (L694-701) で yaml.safe_load + Path traversal を明示するが、検証 3 で grep を subprocess 経由で実行する際の shell injection 防止規律が未明示。Tech Stack L146 で subprocess 用途 = grep 実行と明示するが `shell=False` 必須規律なし
- **本質的影響**: Phase 2 Spec 4 design 実装で `subprocess.run(..., shell=True)` 採用時、foundation.md / consolidated-spec / Spec 1-7 path に special characters 混入 (file rename 等) で injection 発生
- **escalate 必須条件該当**: (4) 実装の不整合 (subprocess 呼び出し方法規範未明示)
- **5 観点深掘り (推奨案確証)**:
  - 案 A Security Considerations に「`shell=False` 必須、args list 形式」規律追加 (推奨)
  - 案 B Phase 2 Spec 4 design で確定 (修正不要) — dominated 除外 (Security 規律は規範レベル明示が安全側)
- **確証根拠 5 点**: 実装容易 (1 行追加) / 設計理念整合 (規範文書として security 規律明示) / 運用整合 (Phase 2 実装者の参照点) / boundary 違反なし / Phase 1 整合
- **user 判断**: 推奨案 A で進める (案 A 異論なし)
- **Edit 適用箇所**: design.md Security Considerations section に Subprocess shell injection 防止規律 1 行追加

#### 重-厳-5: approvals.requirements 誤記 (L690 + L729 の 2 箇所) — escalate → 推奨案 A 採択

- **検出**: design.md L690 (Testing 人間レビュー Gate) と L729 (Migration Lifecycle) で「spec.json approvals.requirements approve」と記述。foundation.md 初版生成は implementation phase であり、requirements は既に approve 済 (`approvals.requirements.approved = true`)。意味的不整合
- **本質的影響**: foundation.md 初版生成時の approve gate が曖昧、kiro spec workflow との整合不整合
- **escalate 必須条件該当**: (4) 実装不整合 (approval gate 文書記述不正)
- **5 観点深掘り (推奨案確証)**:
  - 案 A L690 / L729 の「approvals.requirements」を「`approvals.tasks` (foundation.md 生成タスク完了時) または implementation 完了 review」に修正 (推奨)
  - 案 B 修正不要 (誤記の可能性低、現状維持) — dominated 除外 (明らかな誤記)
- **確証根拠 5 点**: 実装容易 (2 箇所修正) / 設計理念整合 (kiro spec workflow と整合) / 運用整合 (approve gate の意味明確化) / boundary 違反なし / Phase 1 整合
- **user 判断**: 推奨案 A で進める (案 A 異論なし)
- **Edit 適用箇所**: design.md L690 (Testing 人間レビュー Gate) + L729 (Migration Lifecycle) の 2 箇所修正

### 厳しく検証 default 化 + R4 やり直し (本質的観点 5 種強制発動、user 再指示で 2026-04-28 実施)

#### 重-4-1: 検証 4 種 output JSON field 構造変更経路の規範粒度未明示 — escalate → 推奨案 A 採択

- **検出**: design.md Components 検証 1-4 で output JSON field 構造を具体的に確定。Revalidation Triggers L67「検証 4 種の規範 schema 変更」が実質変更経路 = field 単位の追加・改名・削除でも傘下 7 spec 波及精査必須 = 過剰規範化
- **本質的影響**: Phase 2 Spec 4 design 着手者が field minor change でも実質変更経路を辿る運用 inflexible
- **escalate 必須条件該当**: (2) 規範範囲判断
- **5 観点深掘り推奨**:
  - 案 A: 規範粒度明示 — 「core schema (envelope structure / check field 値 / details 内 array 名) = 実質変更経路、details 内 array element field 構造の追加・改名・削除 = Adjacent Sync 経路」(推奨)
  - 案 B 現状維持 — dominated 除外 (運用 inflexible)
  - 案 C 全 field を Adjacent Sync — dominated 除外 (整合性検査不可)
- **確証根拠 5 点**: 実装容易 (Revalidation Triggers 1 行細分化) / 設計理念整合 (規範粒度の正しい設計) / 運用整合 (Phase 2 Spec 4 design 柔軟性) / boundary 違反なし / Phase 1 整合
- **user 判断**: 推奨案 A で進める (案 A 異論なし)
- **Edit 適用箇所**: design.md Boundary Commitments §「Revalidation Triggers」の「検証 4 種の規範 schema 変更」を core schema / details element field の 2 段階に細分化

#### 重-4-2: envelope/details 構造の design 内不整合 — escalate → 推奨案 A 採択

- **検出**: design.md Data Models L597-604 envelope `{check, status, details}` vs Components L484/499/514/532 output 例 (envelope 非包含、status field なし、details 展開済) が表現不整合。前 turn で重-厳-3/4/5 を見落とした際にこれも見落としていた本質的検出
- **本質的影響**: Phase 2 Spec 4 design 着手者が envelope 包含/非包含の解釈余地、集約 logs JSON の structure 不整合リスク
- **escalate 必須条件該当**: (4) 文書記述 vs 実装不整合
- **5 観点深掘り推奨**:
  - 案 A Components 各 output 例を envelope 包含形式 `{check, status, details: {...}}` に書き換え (推奨)
  - 案 B Data Models で「Components の output 例は details 部分のみ抜粋」を補足 — dominated 除外 (簡易補正、表現分散のまま)
  - 案 C envelope 放棄 — dominated 除外 (集約 logs uniform parsing 失う)
- **確証根拠 5 点**: 実装容易 (4 箇所書き換え) / 設計理念整合 (design 内表現統一) / 運用整合 (Phase 2 着手者の迷いゼロ) / boundary 違反なし / Phase 1 整合
- **user 判断**: 推奨案 A で進める (案 A 異論なし)
- **Edit 適用箇所**: Components 検証 1/2/3/4 の output JSON 例を envelope 包含形式に書き換え

#### 軽-4-2: envelope status 値域 vs severity マッピング未明示 — escalate → 推奨案 A 採択 (前回 R3 軽微判定の見直し)

- **検出**: L597 envelope status `"pass" | "warn" | "fail"` と Components severity (ERROR / WARN / PASS) の対応マッピングが design 内で明示されていない。roadmap.md L132 Severity 4 水準 (CRITICAL/ERROR/WARN/INFO) との関係も未明示。前回 R3 で「修正不要」判定したが厳しく検証で見直し
- **本質的影響**: Phase 2 Spec 4 design 実装で envelope status 生成時の mapping が曖昧、CRITICAL/INFO 扱いも不明確
- **escalate 必須条件該当**: (4) 規範前提曖昧化
- **5 観点深掘り推奨**:
  - 案 A: Data Models に対応マッピングを 1 段落で明示「ERROR → "fail" / WARN → "warn" / PASS → "pass"、CRITICAL は本 spec 想定外、INFO は扱わない」(推奨)
  - 案 B Phase 2 Spec 4 design 委譲 (前回採用) — dominated 除外 (規範前提曖昧化が再発)
- **確証根拠 5 点**: 実装容易 (1 段落追記) / 設計理念整合 (規範前提明示) / 運用整合 (Phase 2 着手者の参照点) / boundary 違反なし / Phase 1 整合
- **user 判断**: 推奨案 A で進める (案 A 異論なし)
- **Edit 適用箇所**: Data Models §「Logical Data Model」envelope schema 説明に mapping 1 段落追記

#### 軽-4-1: 検証 3 broken_links[].missing field 冗長性除外 (自動採択)

- **検出**: design.md L514 検証 3 output `details = {broken_links: [{source_file, line, target_anchor, missing}]}` で `missing: bool` field が冗長 (broken_links 配列に入っている時点で missing == true 自明)、design 内で意味説明なし
- **判断根拠**: 軽微な明示性向上、boundary 拡張なし
- **1 回目深掘り (5 観点)**: 実装容易 / 設計整合 / 運用整合 / boundary 違反なし / Phase 1 整合 → 推奨案 X1 = field 削除
- **2 回目深掘り (5 切り口)**:
  - 本質的観点: broken_links は missing 用途のみ、冗長 → 反転理由なし
  - 関連文書間矛盾: 該当なし → 反転理由なし
  - 仕様⇄実装突合: Phase 2 Spec 4 design 実装で missing field を生成する logic 不要 → 反転理由なし
  - dev-log 23 パターン: 該当なし
  - 失敗+Phase 1 アナロジー: 該当なし
- **確度判定**: X1 == X2、5 切り口反転理由なし → 自動採択
- **Edit 適用箇所**: Components 検証 3 output から `missing: bool` field を削除、Data Models 検証 3 details からも削除

#### 軽-5-1: Performance section design 行数 rot リスク (自動採択、R5 やり直し)

- **検出**: design.md L709「想定規模の根拠: Spec 0 design 738 行 / Spec 1 design 1140 行」と固定値で記述、改版で rot するリスク
- **判断根拠**: 軽微な明示性向上 + 改版 rot 回避
- **2 回目深掘り (5 切り口) で反転理由なし** → 自動採択
- **Edit 適用箇所**: design.md Performance section L709「想定規模の根拠」を近似値表現に修正 (~1000 行 design + ~200 行 requirements 規模)

#### 軽-5-2: 検証 1/2/4 計算量未明示 — escalate → 推奨案 B 採択 (修正不要)

- **検出**: design.md L711「性能劣化シナリオ」で検証 3 のみ O(L×H) 計算量明記、検証 1/2/4 未明示
- **escalate 必須条件該当**: (4) 規範前提曖昧化 (軽微)
- **5 観点深掘り推奨**: 案 A 計算量明示 / 案 B 修正不要 (Phase 2 Spec 4 design 委譲)
- **LLM 推奨案 B**: 計算量も性能 target と同様に Phase 2 委譲、決定 0-2「規範 = Spec 0 / 実装 = Spec 4」と整合
- **user 判断**: 推奨案 B 採択 (修正不要、案 A 異論なし)

#### R6 やり直し (失敗モード+観測性、統合) — 適用件数 0

##### 軽-6-1: Error Categories response 詳細度不均一 — escalate → 推奨案 B 採択 (修正不要)

- **検出**: design.md L641-647 Error Categories で検証 1 一般 / 検証 2 具体 / 検証 3 具体+委譲 / 検証 4 一般 と response 詳細度不均一
- **escalate 必須条件該当**: (4) 規範前提曖昧化 (軽微)
- **5 観点深掘り推奨**: 案 A 統一形式 / 案 B 修正不要 (現状で機能、推奨)
- **LLM 推奨案 B**: 現状記述で Phase 2 着手者の理解可能、統一形式書き換えで現状の意味を変えるリスク
- **user 判断**: 推奨案 B 採択 (案 A 異論なし)

##### 軽-6-2: Severity vs Category "ERROR" 用語曖昧 — escalate → 推奨案 B 採択 (修正不要)

- **検出**: design.md L641「(検証 1 ERROR)」表記で "ERROR" が severity か category 名か曖昧
- **escalate 必須条件該当**: (4) 規範前提曖昧化 (軽微)
- **5 観点深掘り推奨**: 案 A severity = ERROR と明示 / 案 B 修正不要 (推奨)
- **LLM 推奨案 B**: Components L484 で severity = ERROR と確定済を参照、文脈上理解可能、severity 明示は冗長
- **user 判断**: 推奨案 B 採択 (案 A 異論なし)

#### R7 やり直し (セキュリティ / プライバシー) — 適用件数 0

##### 軽-7-1: foundation.md 生成プロセスのセキュリティ + 秘匿情報定義曖昧化 — escalate → 推奨案 B 採択 (修正不要)

- **検出**: design.md Security Considerations で foundation.md 生成プロセス自体 (Spec 0 implementation phase) のセキュリティ未明示 + 「秘匿情報」定義曖昧 (個人情報 / secrets / 内部情報のいずれか不明)
- **escalate 必須条件該当**: (4) 規範前提曖昧化 (軽微)
- **5 観点深掘り推奨**: 案 A 定義明示 + 生成プロセス規律追加 / 案 B 修正不要 (推奨)
- **LLM 推奨案 B**: foundation.md は public 規範文書 = sensitive data 混入リスク低、Privacy 規律で十分カバー、生成プロセス規律は冗長
- **user 判断**: 推奨案 B 採択 (案 A 異論なし)

#### R8 やり直し (依存選定) — 適用件数 0

##### 軽-8-1: 依存方向 vs 検証目的 markdown 読込の区別の明示性曖昧 — escalate → 推奨案 B 採択 (修正不要)

- **検出**: design.md L55 「本 spec は他の v2 spec を upstream として持たない」と L147「検証 4 種実装は Spec 1-7 markdown を読み込む」の関係が示唆レベル、「依存 vs 参照」distinction 明示性曖昧
- **escalate 必須条件該当**: (4) 規範前提曖昧化 (軽微)
- **5 観点深掘り推奨**: 案 A distinction 明示追記 / 案 B 修正不要 (推奨)
- **LLM 推奨案 B**: L56 で SSoT 出典 / steering の「依存ではなく出典 / 規範参照」distinction が既に明示済、Spec 1-7 markdown 読込もこの延長で解釈可能、distinction 明示は冗長
- **user 判断**: 推奨案 B 採択 (案 A 異論なし)

#### R9 やり直し (テスト戦略) — 適用件数 0

##### 軽-9-1: Cross-spec Integration Test 実行方法の明示性曖昧 — escalate → 推奨案 B 採択 (修正不要)

- **検出**: design.md L682-687 で Cross-spec Integration Test の test 形式は Phase 2 + consumer spec design 委譲とあるが、test 実行方法 (CI 自動 / 人間 review / その他) が未明示
- **escalate 必須条件該当**: (4) 規範前提曖昧化 (軽微)
- **5 観点深掘り推奨**: 案 A 実行方法明示追記 / 案 B 修正不要 (推奨)
- **LLM 推奨案 B**: test 形式と実行方法は表裏一体、Phase 2 + consumer spec で併せて確定が妥当、Spec 0 で先取り明示は冗長
- **user 判断**: 推奨案 B 採択 (案 A 異論なし)

#### R10 やり直し (マイグレーション戦略) — 適用件数 0

##### 軽-10-1: 「Spec 1-7 連鎖 migration」用語の誤用 — escalate → 推奨案 B 採択 (修正不要)

- **検出**: design.md L741「Spec 1-7 連鎖 migration」記述で migration は v1→v2 移行を指す用語と context 上の不整合 (本 spec はフルスクラッチで v1 移行不要)
- **escalate 必須条件該当**: (4) 規範前提曖昧化 (軽微)
- **5 観点深掘り推奨**: 案 A「Spec 1-7 連鎖波及 (Foundation 改版経由)」に修正 / 案 B 修正不要 (推奨)
- **LLM 推奨案 B**: Migration Strategy section 内の用語、context 上 implicit に Foundation 改版による波及と理解可能
- **user 判断**: 推奨案 B 採択 (案 A 異論なし)

### Spec 0 全 10 ラウンドやり直し完了サマリ (2026-04-28)

- **R1**: 3 件適用 (軽-1 自動採択 / 重-厳-1 決定 0-6 新規 / 重-厳-2 Performance 示唆値化)
- **R2-R3**: 軽微 escalate 各 1 件のみ、いずれも LLM 推奨 = 修正不要で採択 (適用 0 件)
- **本質的観点厳しく再レビュー**: 3 件適用 (重-厳-3 §1/§6/§8/§9 sub-section / 重-厳-4 subprocess shell injection 規律 / 重-厳-5 approvals.requirements 誤記是正)
- **R4 やり直し**: 4 件適用 (重-4-1 規範粒度 / 重-4-2 envelope 包含 / 軽-4-2 status mapping / 軽-4-1 missing field 削除)
- **R5 やり直し**: 1 件適用 (軽-5-1 design 行数近似値化)
- **R6-R10 やり直し**: 各軽微 escalate 1 件のみ、いずれも LLM 推奨 = 修正不要で採択 (適用 0 件)

**合計適用件数**: 11 件、design.md 編集箇所 約 18 箇所

**新方式の効果検証**:
- 自動承認モードの限界が明確化 (R2-R10 自動承認時に重-厳-3/4/5 を見落とした)
- 厳しく検証 default 化で R4 やり直し時に重-4-1/4-2 など本質的検出
- 「LLM 推奨 = 修正不要」軽微 escalate を user 判断で採択することで、過剰修正を防ぎつつ LLM 視点の検出を user に提示
- 各ラウンドで Step 2 user 判断を経ることで自動承認モードの easy wins 偏向を構造的に抑制

**次のステップ**: Spec 0 design approve commit (spec.json approve = true + design.md / research.md / spec.json commit)。

#### 2 回目深掘り 5 切り口 negative 視点 skim 問題対応 (user 指摘、2026-04-28)

**user 指摘**: 各検出案件の 2 回目深掘り 5 切り口のうち、5 番目 (失敗シナリオ + Phase 1 アナロジー、negative 視点) を形式的に「該当なし」で skim していた問題。LLM の easy wins 偏向の典型、memory 規律と実態の乖離。

**negative 視点で全検出 (R1-R10) を再検証した結果**: 概ね整合だが追加検出 2 件:

##### 追加-1: 重-厳-5 修正の「implementation 完了 review」誤導性 — escalate → 推奨案 A 採択

- **検出**: 重-厳-5 適用時に「approvals.tasks (foundation.md 生成タスク完了時) または implementation 完了 review (kiro spec workflow の implementation phase 完了 review)」と修正したが、kiro spec workflow には implementation phase の明示的 approve gate は存在しない (CLAUDE.md 3-phase approval workflow = Requirements → Design → Tasks のみ)。「implementation 完了 review」は誤導的
- **破綻シナリオ (negative 視点)**: Phase 2 Spec 4 design 着手者が「implementation 完了 review」を kiro spec workflow の存在 gate と誤解、approve flow が定義されていない gate を待つ deadlock リスク
- **Phase 1 アナロジー**: Spec 1 R7 escalate Eventual Consistency 同型 = 規範前提曖昧化
- **escalate 必須条件該当**: (4) 文書記述 vs 実装不整合
- **5 観点深掘り推奨**: 案 A 「implementation 完了 review」削除、approvals.tasks のみに simplify (推奨) / 案 B 現状維持 — dominated 除外
- **user 判断**: 推奨案 A 採択 (案 A 異論なし)
- **Edit 適用箇所**: design.md L690 Testing 人間レビュー Gate + L729 Migration Lifecycle の 2 箇所

##### 追加-2: 軽-4-2 envelope status mapping で CRITICAL 将来扱い明示なし — escalate → 推奨案 B 採択 (現状維持)

- **検出**: 軽-4-2 で「CRITICAL は本 spec 想定外」と書いているだけ、将来 CRITICAL を扱いたくなった場合の手順明示なし
- **破綻シナリオ (negative 視点)**: 重-4-1 細分化で「status 値域変更は core schema に該当」と implicit カバーしているが、明示性は薄い
- **Phase 1 アナロジー**: Spec 0 R1 重-厳-1 (R10.7 (b)(c) 不採用根拠の決定 0-6 同型) = 規範前提明示が必要
- **5 観点深掘り推奨**: 案 A status 値域変更を core schema 明示 + CRITICAL 将来扱い明示 / 案 B 現状維持 (重-4-1 細分化で implicit カバー、推奨)
- **LLM 推奨案 B**: 重-4-1 で envelope structure (status 含む) は core schema = 実質変更経路と既に明示済、追加明示は冗長
- **user 判断**: 推奨案 B 採択 (案 A 異論なし)

**memory 規律強化**: `feedback_review_step_redesign.md` Step 1b-v 5 切り口の 5 番目に「該当なし skim 禁止、強制発動義務化」を明示 (破綻シナリオ最低 1 つ列挙 + Phase 1 アナロジー 3 種同型比較を必ず実行、「該当なし」と判定する場合も明示的記録の証跡)。
