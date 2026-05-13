# Requirements Document

本文書は dual-reviewer v2 取得処理の機能要件と非機能要件を記録する。本要件は `design.md` で参照する v2-acquisition-design.md と整合する。

## Functional Requirements

### FR-1：役割設計

- 3 方式比較（single / dual / dual+judgment）を維持できること。
- 通信構造は β 逐次方式（主役 → 敵対役 → 判断役、各役が前段の出力を入力として受け取る）。
- 主役、敵対役、判断役の 3 役とも別セッションで動作すること。メイン LLM は 3 役のいずれにもならないこと。

### FR-2：モデル選定

- 主役は Claude Opus。
- 敵対役は Claude Sonnet（主役と異なる版）。
- 判断役は Claude Opus（主役と同じ版だが別セッション）。
- 温度はすべて 0。

### FR-3：各役割の責務

- 件数指示：下限のみ（少なくとも 1 件）+ 優先順位（重大さの順）。上限なし。
- 主役のトピック誘導：大まかなカテゴリ（正確性 / 安全性 / 互換性 / 保守性）のみ。
- 敵対役のトピック誘導：なし。「主役が見落とした重要問題を挙げよ」のみ。
- 判断役の判断方針：「重要なものを残し、弱い指摘や重複に注記を付ける」のような判断指針のみ。
- 主役・敵対役の出力は 4 フィールド構造化 Markdown（重大さ / 対象箇所 / 説明 / 根拠）。
- 敵対役の出力は追加で種別フィールド（反論 / 独立発見）を持ち、両者を別パートに分離。
- 判断役は発見数を変えず、判断ラベル（must-fix / should-fix / leave-as-is）と根拠を注釈付与。

### FR-4：入力設計

- ケース文脈は中間案（ケース名は伝えるが、ドメイン情報や期待結果は伝えない）。
- 入力ファイルは構造化区切り方式（`<file path="...">...</file>`）で渡す。
- LLM の Read ツール呼び出しは介在させない。
- 入力範囲：主役は対象 + 直上の上流、敵対役は主役の入力 + 主役の出力、判断役は主役の入力 + 主役の出力 + 敵対役の出力。

### FR-5：出力設計

- 保存形式は Markdown と JSON の両方併記。
- メタデータは 10 項目すべて必須：`run_id` / `timestamp` / `case_id` / `mode` / `role` / `model_version` / `temperature` / `input_hash` / `prompt_version` / `acquisition_design_version`。

### FR-6：取得反復

- 各設定で 3 回ずつ繰り返す。
- ばらつきは全フィールド一致で観察する。
- 失敗時は自動リトライ最大 3 回。

### FR-7：運用

- 方式 B（Claude Code CLI `claude --print`）が中心。
- ログは詳細（各 LLM 呼び出しの入出力全体を保存）。
- 取得は完全逐次（1 ケース 1 取得ずつ順番）。

### FR-8：結果保存

- v2 専用パスに保存（具体パスは実装段階で確定）。
- v1 archive とは別管理。論文や設計書で対比は行う。
- ディレクトリ階層はトラック別優先（v1 と同じ階層）。

### FR-9：3 方式の構成

- 3 方式間で主役・敵対役・判断役の呼び出しを再利用する。
- single = 主役 1 回、dual = single の主役出力 + 敵対役 1 回、dual+judgment = dual の出力 + 判断役 1 回。

## Non-Functional Requirements

### NFR-1：再現性

- 温度ゼロ前提、構造化入力、メタデータ完全記録により、同じ入力に対する取得が再現可能であること。

### NFR-2：ログ詳細性

- すべての LLM 呼び出しの入出力を保存する。

### NFR-3：コスト把握

- subscription 利用枠（方式 B）と API コスト（方式 D、将来）を取得ごとに記録する。

## Acceptance Criteria

- AC-1：3 方式（single / dual / dual+judgment）の取得が、少なくとも 1 ケースで完了する。
- AC-2：取得結果が Markdown と JSON で保存され、メタデータが全項目記録される。
- AC-3：同じ設定で 3 回繰り返し取得が完了し、ばらつきの有無が観察できる。
- AC-4：取得処理は規則ファイルに依存しない。Ruby ランタイム層の `build_rule_matched_analysis` 系の処理は除去または無効化される。
- AC-5：v1 で観測された「2/3/3」の偽の規則性が再現しないこと。3 方式の発見数は LLM の判断によって決まり、事前固定されない。

## References

- [v2-acquisition-design.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/v2-acquisition-design.md)（設計本体）
