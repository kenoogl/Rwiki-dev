# 図1 キャプション案（メモ）

_対象: `fig1-severity-distribution.{py,svg,png}`_
_最終更新: 2026-05-20_
_状態: 本文執筆時に確定。本書は素材_

---

## キャプション案（日本語版・本文用）

> **図1**: 仕様サイクルのフェーズ別 重大度分布（6機能累計の積み上げ棒）。横軸は仕様サイクルのフェーズ（**Requirements**＝要件、**Design**＝設計、**Design rework**＝差し戻し後の再レビュー、**Tasks**＝タスク、**Conformance pre**＝再実装前の独立適合レビュー、**Conformance post**＝再実装後の独立適合レビュー）。色は重大度を粗く3段階に統一したもの（**High** 高＝CRITICAL／致命／P1／判断役 must-fix、**Medium** 中＝ERROR／重要／P2／should-fix、**Low** 低＝WARN／INFO／軽微／P3／leave-as-is）。各棒の中の数値は重大度別件数、上部の数値は棒の合計件数。**Design rework** 列は基盤・実行系の2機能のみが該当する（N=2 と注記）。他の列は6機能の累計。フェーズで記録語彙が異なるため統一は粗く、フェーズ間の同一指標比較には限界がある（本文§5議論で限界を明示）。出典: `evidence-extract-2026-05-20.md` §1〜§6。

---

## キャプション案（英語版・将来の国際投稿向け参考）

> **Fig. 1**: Severity distribution by phase across the spec-driven cycle (stacked bars, aggregated over six features). The x-axis lists phases: **Requirements**, **Design**, **Design rework** (post-handback re-review), **Tasks**, **Conformance pre** (independent conformance review before reimplementation), and **Conformance post** (after reimplementation). Severities are coarsely unified into three levels: **High** (CRITICAL / fatal / P1 / judge must-fix), **Medium** (ERROR / major / P2 / should-fix), and **Low** (WARN / INFO / minor / P3 / leave-as-is). In-bar numbers are per-severity counts; numbers above each bar are bar totals. The **Design rework** column applies only to two features (foundation and runtime); other columns aggregate all six features (the N=2 caveat is annotated on the x-axis). Phases record severity using different vocabularies, so the unification is coarse and cross-phase comparison on a single index has a limit discussed in Section 5. Source: `evidence-extract-2026-05-20.md` §1–§6.

---

## ラベル対応表（簡易）

- **Requirements**：要件 個別レビュー（6機能、各機能の §x.1）
- **Design**：設計 個別レビュー（6機能、各機能の §x.2）
- **Design rework**：差し戻し後の再レビュー（基盤・実行系のみ、§1.3 と §2.3）
- **Tasks**：タスク 個別レビュー（6機能、各機能の §x.3）
- **Conformance pre**：再実装前の独立適合レビュー（6機能、各機能の §x.5 等）
- **Conformance post**：再実装後の独立適合レビュー（6機能、基盤§1.6 を含む）
- **High／Medium／Low**：粗統一した重大度3段階

---

## 重大度語彙の統一基準（粗統一）

各フェーズで使われる重大度語彙が異なるため、本図では以下のとおり粗く統一した。

- **High** には次を含める：CRITICAL（要件・設計の個別レビュー）、致命（タスクの個別レビュー）、P1（適合レビュー）、判断役の must-fix
- **Medium** には次を含める：ERROR（要件・設計）、重要（タスク）、P2（適合）、should-fix
- **Low** には次を含める：WARN／INFO（要件・設計）、軽微（タスク）、P3（適合）、leave-as-is

統一の粗さは本文§5議論で限界として明記する。具体的な原文重大度語の対応は evidence-extract §0.1 に整理。

---

## データ（参考、出典付き）

各フェーズの値は evidence-extract から集計したもの。本図の試作データと一致。

- Requirements（6機能累計）：High 29 / Medium 60 / Low 40 / 計 129
- Design（6機能累計）：High 46 / Medium 74 / Low 40 / 計 160
- Design rework（N=2機能：基盤・実行系）：High 0 / Medium 4 / Low 6 / 計 10
- Tasks（6機能累計）：High 0 / Medium 15 / Low 28 / 計 43
- Conformance pre（6機能累計）：High 26 / Medium 16 / Low 7 / 計 49
- Conformance post（6機能累計、基盤§1.6 を含む）：High 0 / Medium 1 / Low 4 / 計 5

---

## 注意事項（本文執筆時に確認）

- 重大度語彙の粗統一は本文§5議論で限界として明示（観察D との対応）
- N=2 機能（Design rework 列）の非対称は本図の脚注と本文§5で説明
- 各フェーズの数値は evidence-extract §1〜§6 から導出。コミットハッシュは個別出典として本文に列挙
