# intent-to-requirements-trace-matrix

## 1. この文書の役割

この文書は、`INTENT.md` の主要命題が各 feature の `requirements` にどう流れているかを追跡する trace matrix である。

目的:

- 上位意図と feature requirement の接続を明示する
- 後から追加された観点が requirements に落ちているか確認できるようにする
- requirement がどの intent を受けて存在しているかを監査可能にする

この文書は [TRACEABILITY.md](../../intent/TRACEABILITY.md) の補助的正本であり、`intent -> requirements` の具体対応を保持する。

## 2. 更新必須トリガー

次の場合、この matrix は同一ターン内または直後のターンで更新しなければならない。

- `INTENT.md` の主要命題の追加、削除、意味変更
- `NON_GOALS.md` の変更で requirement の存在理由や適用範囲が変わる場合
- `DESIGN_PRINCIPLES.md` の変更で requirement へ波及する設計原則が変わる場合
- `operations/` 文書の変更で requirement 前提が変わる場合
- いずれかの `requirements.md` の追加、削除、分割、統合、意味変更
- feature の新設、統合、廃止
- `cross-spec-requirements-alignment.md` により requirement の責務移管が起きた場合
- implementation 中に requirement 不足または intent 未接続 requirement が発見され、spec を reopen した場合

更新不要:

- typo 修正のみ
- `design.md` または `tasks.md` だけの変更で requirement の意味が変わらない場合
- `docs/` の補足説明のみの変更

## 3. 対応ラベル

- `direct`
  - intent 命題を requirement が直接実装する
- `supporting`
  - 他 spec の実現を支える形で間接的に支える
- `deferred`
  - intent にはあるが、この初期再構築では requirement にまだ落とさない
- `gap`
  - intent に対して現時点で requirement 対応が不足している

## 4. Matrix

| Intent 命題 | Feature | Requirement | Relation | Note |
|-------------|---------|-------------|----------|------|
| repo 内完結の再現可能 runtime を作る | foundation | Requirement 4 `Canonical Prompt Placement` | direct | prompt を repo 内 versioned artifact として固定 |
| repo 内完結の再現可能 runtime を作る | foundation | Requirement 7 `Repo-Contained Asset Rule` | direct | repo 外 memory 依存を禁止 |
| repo 内完結の再現可能 runtime を作る | runtime | Requirement 3 `Prompt Resolution and Version Traceability` | direct | runtime が repo 内 prompt のみ解決する |
| 実験条件の drift を防ぐ | foundation | Requirement 1 `Review State Machine Contract` | supporting | protocol / phase / treatment を束ねる metadata 基盤 |
| 実験条件の drift を防ぐ | foundation | Requirement 6 `Validator-Oriented Metadata Contract` | direct | protocol / prompt / runtime / target hash を required metadata 化 |
| manual dogfooding を valid review evidence として区別する | foundation | Requirement 6 `Validator-Oriented Metadata Contract` | direct | shared metadata に review-mode vocabulary を追加 |
| manual dogfooding を valid review evidence として区別する | runtime | Requirement 4 `Structured Evidence Emission` | direct | runtime-produced evidence に review-mode provenance を残す |
| manual dogfooding を valid review evidence として区別する | runtime | Requirement 6 `Validator Integration and Run Close` | supporting | runtime-mediated mode を downstream 推定に頼らず明示する |
| 実験条件の drift を防ぐ | evaluation | Requirement 1 `Valid / Invalid Run Separation` | direct | invalid run の機械的分離 |
| 実験条件の drift を防ぐ | evaluation | Requirement 6 `Evaluation-Ready Metadata Completeness` | direct | required metadata 不足を fail fast |
| runtime と evaluation / paper の混線を防ぐ | runtime | Requirement 4 `Structured Evidence Emission` | supporting | raw evidence と derived summary を runtime 内でも分離する |
| runtime と evaluation / paper の混線を防ぐ | evaluation | Requirement 5 `Derived Artifact Production` | supporting | raw evidence と analysis artifact の分離 |
| runtime と evaluation / paper の混線を防ぐ | paper-interface | Requirement 4 `Separation from Runtime and Evaluation Logic` | direct | paper が lower layer を支配しない |
| 自己改善を ad-hoc memory ではなく formal loop にする | self-improvement | Requirement 1 `Improvement Input Definition` | direct | operator intuition 単独を不十分とする |
| 自己改善を ad-hoc memory ではなく formal loop にする | self-improvement | Requirement 2 `Proposal Artifact Contract` | direct | proposal を structured artifact 化 |
| 自己改善を ad-hoc memory ではなく formal loop にする | self-improvement | Requirement 3 `Replay and Backtest Requirements` | direct | replay / backtest を formalize |
| 自己改善を ad-hoc memory ではなく formal loop にする | self-improvement | Requirement 4 `Approval and Adoption Flow` | direct | human approval と version update を必須化 |
| 人が system 全体像を理解できるようにする | foundation | Requirement 2 `Role and Config Abstraction` | supporting | role と config の境界を operator-visible にする |
| 人が system 全体像を理解できるようにする | foundation | Requirement 3 `Shared Schema Set` | supporting | 共通 schema を単一 contract として整理する |
| 人が system 全体像を理解できるようにする | runtime | Requirement 5 `Human Decision Integration` | supporting | human sign-off と decision unit を明示 |
| design / tasks の複雑性増大局面を主戦場にする | runtime | Requirement 8 `Phase-Aware Review Profiles` | direct | phase ごとの review emphasis を持つ |
| design / tasks の複雑性増大局面を主戦場にする | evaluation | Requirement 7 `Phase-Aware Evaluation` | direct | phase-aware slicing を保持する |
| design / tasks の複雑性増大局面を主戦場にする | evaluation | Requirement 8 `Phase-Specific Effectiveness Metrics` | direct | phase ごとの primary metric を許容する |
| phase ごとに有効性指標が異なりうる | evaluation | Requirement 3 `Metric Extraction` | supporting | core metric layer の抽出基盤 |
| phase ごとに有効性指標が異なりうる | evaluation | Requirement 8 `Phase-Specific Effectiveness Metrics` | direct | phase-specific overlay を明示 |
| 人間 gate を残す | runtime | Requirement 5 `Human Decision Integration` | direct | approve / reject / defer を first-class にする |
| 人間 gate を残す | self-improvement | Requirement 4 `Approval and Adoption Flow` | direct | runtime-affecting change の human approval |
| manual dogfooding を valid review evidence として区別する | evaluation | Requirement 9 `Review-Mode Distinction` | direct | manual review evidence と runtime-mediated evidence を混在させず、standard comparison population の owner になる |
| manual dogfooding を valid review evidence として区別する | self-improvement | Requirement 7 `Manual-vs-Runtime Evidence Provenance` | direct | manual evidence を runtime behavior と過剰同一視しない |
| manual dogfooding を valid review evidence として区別する | paper-interface | Requirement 6 `Review-Mode Provenance in Reporting` | direct | paper-facing artifact で evidence mode を保持する |
| 他 local で採取した evidence を central 側で分析・改善へ接続できるようにする | foundation | Requirement 6 `Validator-Oriented Metadata Contract` | direct | cross-project provenance field naming を shared contract に上げる |
| 他 local で採取した evidence を central 側で分析・改善へ接続できるようにする | runtime | Requirement 9 `Portable Evidence Bundle Export` | direct | local run を portable bundle として export 可能にする |
| 他 local で採取した evidence を central 側で分析・改善へ接続できるようにする | evaluation | Requirement 10 `External Bundle Ingestion and Admission` | direct | central-side ingest / validate / admit の owner |
| 他 local で採取した evidence を central 側で分析・改善へ接続できるようにする | self-improvement | Requirement 8 `Imported Evidence Provenance Preservation` | direct | imported evidence を proposal provenance まで維持する |
| paper convenience が runtime rule を汚染しない | paper-interface | Requirement 2 `Paper-Facing Data Contract` | supporting | formatting convenience で schema を変えない |
| paper convenience が runtime rule を汚染しない | paper-interface | Requirement 4 `Separation from Runtime and Evaluation Logic` | direct | paper layer を consumer に限定 |
| cross-project learning は将来拡張とする | self-improvement | Requirement 6 `Separation from Paper Narrative` AC5 | supporting | full external contributor network は将来拡張のままにする |
| GitHub PR ベースの public evidence intake は初期対象外 | evaluation | deferred | deferred | public-facing intake channel はまだ requirement に含めない |
| GitHub PR ベースの public evidence intake は初期対象外 | self-improvement | deferred | deferred | external contributor learning network は初期 requirement に含めない |

## 5. 現時点のギャップ

現時点で大きな `gap` はない。ただし次の点は今後の再確認対象である。

- `implementation-oriented review` を正式な phase として requirements に入れるか
- external evidence bundle の concrete shape を foundation にどこまで上げるか
- manual review record と runtime evidence の shared field mapping をどこまで foundation に上げるか

## 6. 運用メモ

- この matrix を更新した場合、必要に応じて [cross-spec-requirements-alignment.md](../alignment/cross-spec-requirements-alignment.md) を再確認する
- matrix と各 feature `spec.json` の `custom.traceability` 状態を一致させる
- trace matrix 更新トリガーの正本は本書 `2. 更新必須トリガー` とする
