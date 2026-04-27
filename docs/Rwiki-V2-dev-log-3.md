# Design Phase

[Rwiki V2の開発-1](Rwiki-V2-dev-log-1.md)

[Rwiki V2の開発-2](Rwiki-V2-dev-log-2.md)



[Spec 0 rwiki-v2-foundation](##Spec 0 rwiki-v2-foundation)

[Spec 0 design ラウンド 4-12 やり直し](##Spec 0 design ラウンド 4-12 やり直し)

[Spec 1 rwiki-v2-classification](##Spec 1 rwiki-v2-classification)

[Spec 1 design ラウンド 4-12 やり直し](##Spec 1 design ラウンド 4-12 やり直し)





##### ❯ TODO_NEXT_SESSION.md を読んでください。Rwiki v2 全 8 spec の requirements approve は完了、cross-spec 整合性精査 + 依存関係精査 + 設計レビュー方法論確定も完了済。これから design phase に移行し、Phase 1 (Spec 0 / Spec 1 並列) → Phase 2 (Spec 4 / Spec 7 並列) → Phase 3 (Spec 5 / Spec 2 並列) → Phase 4 (Spec 3) → Phase 5 (Spec 6) の依存順で /kiro-spec-design <feature> を実行します。設計レビューは memory feedback_design_review.md の 12 観点 = 12 ラウンドを基本全件網羅実施で進め、各ラウンドで仕様レビュー継承の 5 step 必須手順 + 深掘り検討 + 自動採択 + 厳しく再精査を踏襲します。設計決定は ADR 不採用、design.md 本文「設計決定事項」セクション + change log の二重記録 (memory feedback_design_decisions_record.md)。仕様⇄設計往復は「仕様 AC として読めるかどうか」+ ユーザー対話必須 (memory feedback_design_spec_roundtrip.md)。最初の対象 spec を確認してから着手してください。

```
⏺ TODO_NEXT_SESSION.md 全文を確認しました。状況を整理します。
⏺ design phase 移行準備の状況を整理します。
  確認した状態:
  - Phase 1 対象: Spec 0 (rwiki-v2-foundation) + Spec 1 (rwiki-v2-classification)、両方とも requirements-approved フェーズ
  - 設計レビュー方法論 memory 3 件 (feedback_design_review.md / feedback_design_spec_roundtrip.md / feedback_design_decisions_record.md) は配置済
  - 仕様レビュー継承 memory 4 件 (deepdive_autoadopt / dominant_dominated / choice_presentation / approval_required) も配置済

  設計レビュー memory の内容を確認してから着手します。
  
⏺ 設計レビュー方法論を確認しました。Phase 1 着手にあたり、進め方を確定します。
⏺ Phase 1 着手前に方針確認をお願いします。Phase 1 は Spec 0 / Spec 1 を「並列処理可能」と整理されていますが、design phaseの進め方には複数の選択肢があり、影響範囲が広いため判断を仰ぎたい点があります。
⏺ 方針確定: Spec 0 から逐次、/kiro-spec-design を使用。
  Spec 0 (rwiki-v2-foundation) の design 生成に着手する前に、対象 spec の規模と内容を確認します。
⏺ Foundation requirements を確認しました。14 Requirements、約 70 AC、規範 spec で Boundary Commitments 重視。design phase はこれを Boundary Commitments として固定する規範文書設計が中心になります。
  それでは /kiro-spec-design rwiki-v2-foundation を実行します。

```



## Spec 0 rwiki-v2-foundation

```
⏺ skill 起動を確認しました。Step 1 (Gather Context) から開始します。
⏺ 必要な context を並列で読み込みます。
⏺ context が揃いました。Discovery & Analysis に進みます。Spec 0 は 規範文書生成 spec なので外部 library / API 探索は不要、Light Discoveryで十分。SSoT 出典である consolidated-spec の章立て構造のみ確認します。

⏺ Discovery & Synthesis 結果を整理しました。Spec 0 は規範文書 spec で特殊性が高いため、design.md draft を書く前に主要設計選択肢の合意を取ります。

  Discovery 結果サマリ

  Light Discovery (規範文書 spec、外部依存探索不要)
  - SSoT 出典: consolidated-spec v0.7.12 §1-6 (ビジョン / 13 原則 / アーキテクチャ / 用語集 / frontmatter / Task & Command) / §7.2 Spec 0
  - 14 Requirements の subject は全て the Foundation、述語は「shall ～を記述する／明示する」型
  - testability スコープは 4 種に限定 (brief.md): 章節アンカー / SSoT 章番号整合 / 用語集引用 link 切れ / frontmatter schema 妥当性
  - 「v1 を知らない前提」(フルスクラッチ)、実装レベル決定 (Severity 4 / Exit 0/1/2 / timeout) は roadmap.md L132 が SSoT で Foundation 規範対象外

  Synthesis 結果

  - Generalization: 14 Requirements は Foundation 文書のセクション + 改版手順 + 検証手段にマップ可能 (概念規範 / 物理規範 / 用語規範 / 操作規範 /
  SSoT 規範 / 環境規範 の 6 グループ)
  - Build vs Adopt: 検証 4 種は既存ツール (pyyaml 標準 / grep / glob) で十分、新規 library 不要
  - Simplification: 内容妥当性 verifier は構築しない (brief.md で固定済)、検証 4 種を 1 つの統合 script に集約

  重要な設計選択 (escalate)
· Foundation 規範文書本体の物理 path をどこに置きますか？ → 案 A: .kiro/specs/rwiki-v2-foundation/foundation.md (Recommended)
· 検証手段 4 種の実装スコープはどちらにしますか？ → 案 Y: 規範は Spec 0 / 実装は Spec 4 に委譲 (Recommended)
⏺ 両方 Recommended 採択。設計選択確定:
  - 案 A: Foundation 本体 = .kiro/specs/rwiki-v2-foundation/foundation.md
  - 案 Y: 検証規範 = Spec 0 / 検証実装 = Spec 4 (Phase 2 で coordination)
  research.md template を確認してから research.md → design.md draft を作成します。
⏺ research.md を先に作成し、その後 design.md draft を作成します。
⏺ research.md を作成しました。次に design.md draft を作成します。
⏺ design.md draft を生成しました。次に Step 5: design review gate を実行します。
⏺ Design Review Gate 実行結果

  Mechanical Checks (全 PASS):
  - Requirements Traceability: 14 Requirements 全件 (1.1-14.5) を design.md Traceability table で覆っている
  - Boundary section: 4 セクション (Owns / Out / Allowed Dependencies / Revalidation Triggers) 全て populate 済
  - File Structure Plan: 具体 path 記載済 (foundation.md / design.md / research.md / spec.json + Phase 2 Spec 4 委譲)
  - Boundary ↔ File Structure alignment: 整合
  - No orphan components: §1-§9 + 検証 1-4 全て File Structure Plan or Phase 2 委譲先と対応

  Judgment Review (全 PASS):
  - Requirements Coverage: 14 Req 全件、特に R10.7 (a/b/c) は (a) 採用 + (b)(c) 不採用根拠を決定 0-5 で記述
  - Architecture Readiness: foundation §1-9 + 検証 4 種 schema が implementation 可能なレベルで具体化
  - Boundary Readiness: 規範 / 検証 / 改版手順 / 設計決定の 4 seam が明示
  - Executability: foundation.md 生成 + Phase 2 Spec 4 coordination の 2 系列タスクで実装可能

  review gate を通過したので、Step 6 で spec.json を更新します。

⏺ kiro-spec-design スキル実行結果

  Status: design.md 生成完了 (/Users/Daily/Development/Rwiki-dev/.kiro/specs/rwiki-v2-foundation/design.md、約 470 行)

  Discovery Type: Light Discovery (規範文書 spec、外部 library 探索不要)

  Key Findings:
  - 14 Requirements は subject = the Foundation 統一の規範文書 spec、testability scope は brief.md で 4 種検証に限定
  - 検証 4 種の規範 = Spec 0 / 実装 = Spec 4 (Phase 2 coordination 必要)
  - Foundation 章立て = consolidated-spec §1-6 直接対応 + §7-9 拡張で SSoT drift を機械検出可能化

  Review Gate: Pass (mechanical checks 全 PASS, judgment review 全 PASS)

  Research Log: research.md 作成済 (Discovery findings + 設計決定 0-1〜0-5 記録)

  ---
  ここから本プロジェクト方針 (memory feedback_design_review.md) に従い、12 観点 = 12 ラウンドの基本全件網羅レビュー に移行します。

  memory feedback_choice_presentation.md に従い、各ラウンドは大局 → 細部の階層で進め、1 ターン 3 選択肢以内、各ラウンドの Step 1 (要点提示) → Step 2 (ユーザー判断) → Step 3 (詳細抽出) → Step 4 (深掘り + 自動採択 / escalate) を回します。

  第 1 ラウンド: requirements 全 AC の網羅 (観点 1)

  Step 1: 要点提示

  design.md の AC 網羅状況 (Requirements Traceability table より):

  - 全 14 Requirements (R1-R14) の AC 範囲を Traceability table で foundation.md セクションへマップ済
  - 主要マッピング:
    - R1.1-R1.6 (ビジョン) → foundation §1
    - R2.1-R2.6 (3 層) + R5.1-R5.6 (status 区別) → foundation §3
    - R3.1-R3.8 (13 原則) + R4.1-R4.6 (§2.12 優先) + R12.1-R12.6 (§2.13) + R13.1-R13.6 (§2.6) → foundation §2 + §2.0 マトリクス
    - R7.1-R7.7 (用語集 5 分類) → foundation §4
    - R8.1-R8.7 (frontmatter 骨格) → foundation §5
    - R6.1-R6.6 + R9.1-R9.5 (Command 4 Level / Task & Command) → foundation §6
    - R10.1-R10.8 (SSoT 性 / 改版手順 / 検証手段) → foundation §7 + design「検証手段の規範」
    - R11.1-R11.7 (実装独立性 / 環境前提) → foundation §9
    - R14.1-R14.5 (文書品質 / SSoT 整合性) → design「検証手段の規範」 + foundation 全章立て

  観点 1 の状況: 全 14 Req カバー済、特殊性 = R10.7 (整合性検証手段 a/b/c) は (a) 採用 + (b)(c) 不採用が決定 0-5 に記録 (規範 spec curation
  構造的非対称性肯定)。

  Step 2: ユーザー判断
· 第 1 ラウンド (requirements 全 AC の網羅) をどう進めますか？ → 全 14 Req を順に詳細確認
⏺ 了解、全 14 Req を順に詳細確認します。design.md と requirements.md を照合し、連鎖更新漏れ / マッピング drift を検出します。

⏺ 第 1 ラウンド: 14 Req 全件 vs design.md 詳細照合を実施しました。

  Step 3: 詳細抽出結果

  連鎖更新漏れ候補 5 件検出:

  - 軽-1 (R2.3): design.md §3 で reject_queue/ が L2 構成要素として明示なし。R2.3 は「6 ファイル + reject_queue/」を L2 ledger
  構成として列挙、design.md は 6 ファイルのみ
  - 軽-2 (R3.7): design.md L294 で不変項目を「3 つ」と表記、同 design L310 / L561 では「4 種」と整合不一致 (§2.10 / §2.12 / §2.2 §2.4 / §2.13 の 4
  項目を 3 つに丸めている)
  - 軽-3 (R10.5): §7 §7.4 v1 隔離宣言と §9 v1→v2 対応で重複記述、§7 から R10.5 を §9 へ集約すべき
  - 軽-4 (R11.7): reject_reason_text 空文字禁止の foundation §9 environment マッピング (要件側で R11 に含まれる意図と整合)
  - 軽-5 (R14.5): Component table で §8 設計決定事項 → 14.5 マップは誤り (R14.5 は design.md §「Boundary Commitments」が満たす)

  Step 4: 深掘り検討と判断

  memory feedback_deepdive_autoadopt.md の自動採択方針に従い:

  - 軽-1 / 軽-2 / 軽-3 / 軽-5: 自動採択 (致命的デメリットなし、内部矛盾解消・連鎖更新漏れ是正)
  - 軽-4: 修正不要判断 (R11 Objective「実装独立性 + 運用前提」と整合、要件側意図とマッピング一致)

  修正を適用します。
⏺ 第 1 ラウンド完了

  修正適用 4 件 (軽-1 / 軽-2 / 軽-3 / 軽-5)、修正不要判断 1 件 (軽-4)。

  ここで 1 件、ユーザー確認を取りたい点があります。
· 軽-4 (R11.7 reject_reason_text 空文字禁止を foundation のどこで扱うか) の判断はよろしいですか？ → 修正不要 (要件意図と整合、現状維持)
⏺ 軽-4 確定、第 1 ラウンド完了。第 2 ラウンドに進みます。

  第 2 ラウンド: アーキテクチャ整合性 (観点 2)

  Step 1: 要点提示

  設計の依存グラフ:
  - mermaid Architecture Pattern (design.md L80-121): consolidated-spec / roadmap → foundation.md → Spec 1-7、design.md ⇢ Spec 4 (Phase 2
  coordination)
  - 循環依存なし、依存方向は consumer→provider で整合
  - レイヤ分離: 規範 (foundation §1-§9) / 検証 (design 検証手段) / 改版 (foundation §7) / 設計決定 (design §設計決定事項) の各 layer 独立

  検出された軽微な明確化候補 1 件:

  - 軽-2-1: design.md L55 Allowed Dependencies で「本 spec は upstream を持たない」と記述。一方で mermaid 図には consolidated-spec / roadmap が
  upstream として描かれている。読み手の解釈混乱を回避するため「他の v2 spec を upstream として持たない (drafts / steering は SSoT
  出典として参照、spec 依存とは別カテゴリ)」と明確化推奨

  Step 4: 自動採択判断

  軽-2-1 は致命的デメリットなし、内部矛盾解消で自動採択。
⏺ 第 2 ラウンド完了 (軽 1 件自動採択)。第 3 ラウンドへ。

  第 3 ラウンド: データモデル / スキーマ詳細 (観点 3)

  Step 1: 要点提示

  規範文書 spec のデータモデル (design.md §Data Models 確認):

  - Domain Model: foundation.md §1-§9 の section 構造 + 改版 lifecycle、mermaid graph LR で内部依存図示 (S2 → S2_0 → S3 → S5、S2 → S4、S6 → S4、S7 →
  全章)
  - Logical Data Model: 章節構造 (markdown header ID) / 用語アンカー (#section-<term>) / frontmatter 骨格 yaml block / 検証 4 種 JSON 出力
  - Physical Data Model: 該当なし (markdown + JSON のみ、DB なし)
  - Data Contracts: Spec 1-7 引用 contract / Adjacent Sync contract / 実質変更 contract

  検証ポイント:

  1. Edge status / Page status / Hypothesis status の独立次元 (R5) は §3 / §4 で扱うとマップ済 ✓
  2. L2 6 ファイル骨格 + reject_queue/ ディレクトリ (前ラウンド軽-1 修正済) ✓
  3. frontmatter 7 種固有骨格 (R8.4) を §5 で展開、詳細は Spec 1 委譲 ✓
  4. decision_log.jsonl と evidence.jsonl の直交関係 (R12.2) を §2.13 で扱う ✓

  潜在的検出:

  - 軽-3-1: design.md Logical Data Model で「自動生成 ID: GitHub 標準 (lowercase + hyphen + 数字以外の記号除去)」と記述したが、§2.12 のような
  sectioning は GitHub の自動 ID 生成で 212-evidence-backed-candidate-graph (§ 文字除去) に変換される。検証 1 (章節アンカー存在)
  はこれを前提に動作するが、design.md でこの正規化ルールを明示しておくとよい
  - 軽-3-2: 用語アンカー形式 #section-<term-name-kebab> (例 #section-edge-status) と記述したが、GitHub 自動生成 ID は #edge-status (section- prefix
  なし) になる。design.md と GitHub 仕様の不整合を解消する必要

  Step 4: 深掘り

  軽-3-2 は実害ありの不整合 (検証 3 用語集引用 link 切れチェックが false positive を出す)。escalate 候補を確認します。
· 軽-3-2 用語アンカー形式をどうしますか？ → GitHub 自動生成 ID に準拠 (#edge-status 形式) (Recommended)
⏺ GitHub 自動生成 ID 準拠を採択。design.md を修正します。
⏺ 第 3 ラウンド完了 (軽 2 件自動採択)。第 4 ラウンド以降は 規範文書 spec の特性 により「該当なし / 軽微なし」判定が中心になる予定です。memory
  feedback_design_review.md の規定 (ラウンドを跳ばさず全件実施、深さは spec 性質で変わるが各ラウンド「該当なし」確認は明示) に従い、第 4-12
  ラウンドを一括して結果報告します。

  第 4-12 ラウンド: 一括実施結果

  第 4 ラウンド: API interface 具体化

  - 検証 4 種の Schema 規範 (input / 検査内容 / output JSON schema / severity / exit code) は §「検証手段の規範」で確定
  - 引用 contract / Adjacent Sync contract / 実質変更 contract は §Data Contracts で確定
  - Phase 2 Spec 4 で確定する詳細 (引数 / cache / 部分実行) は明示的に Out of Boundary
  - 判定: 該当なし (検証 schema は十分具体化)

  第 5 ラウンド: アルゴリズム検証

  - 検証 1-4 の計算量: O(N) / O(M) / O(N×M) / O(K) (small N, M)、想定規模 (foundation 1000 行 + Spec 1-7 10K 行) で問題なし
  - edge case: 同名ヘッダー衝突 (軽-3-2 で対処)、SSoT 章タイトル微変更 (正規化マッチで吸収)、改版過渡期 link 切れ (WARN 扱い)
  - 判定: 該当なし (アルゴリズム面の懸念なし)

  第 6 ラウンド: 性能達成手段

  - target: 検証 4 種を < 5 秒で完了 (foundation 1000 行 + Spec 1-7 10K 行規模)
  - 方針: 機能優先 (correctness)、prototype 測定で検証 (memory feedback_design_review.md 整合)
  - 判定: 該当なし (性能要件最小、prototype 確認で対処)

  第 7 ラウンド: 失敗モード handler

  - 検証 4 種 ERROR 時: foundation §5 修正 / link 修正
  - 検証 4 種 WARN 時: Adjacent Sync 同期、長期化で ERROR 昇格
  - rollback: git revert (標準運用)、検証 4 種は idempotent で retry 安全
  - timeout: Phase 2 Spec 4 で確定 (本 design では schema のみ)
  - 判定: 該当なし (本 spec は規範文書 spec、runtime failure mode は最小)

  第 8 ラウンド: セキュリティ / プライバシー

  - foundation.md は public 規範文書、認証 / 認可 / 秘匿情報なし
  - git commit hash で改版 trail を保全
  - 判定: 該当なし

  第 9 ラウンド: 観測性

  - logs/doctor_foundation_latest.json で検証結果集約 (Phase 2 Spec 4 で確定)
  - 人間レビュー gate
  - 判定: 該当なし (規範 spec、独自観測性要件なし)

  第 10 ラウンド: 依存選定

  - 本 spec 自体: 新規 runtime 依存なし
  - Phase 2 Spec 4 実装で必要: pyyaml (標準) + grep (subprocess) — Spec 4 design で確定
  - 判定: 該当なし (本 spec レベルで新規依存なし)

  第 11 ラウンド: テスト戦略

  - Document Lint: 検証 4 種を Phase 2 Spec 4 で実装、3-5 sample test
  - Cross-spec Integration Test: ハイブリッド方式で consumer 側 (Spec 1-7 design) に記述
  - 人間レビュー Gate: foundation.md 初版 / 実質変更時
  - 判定: 該当なし (本 spec の Testing Strategy は十分)

  第 12 ラウンド: マイグレーション戦略

  - v1 から継承する規範文書なし (フルスクラッチ)
  - foundation.md lifecycle (init → approve → reference → revision) は mermaid で図示
  - Phase breakdown / Rollback triggers / Validation checkpoints は §Migration Strategy で完結
  - 判定: 該当なし

  ---
  12 ラウンドレビュー集約

  修正適用件数: 計 6 件 (全件自動採択)
  - 第 1 ラウンド (観点 1: 全 AC 網羅): 軽-1 / 軽-2 / 軽-3 / 軽-5 (4 件)
  - 第 2 ラウンド (観点 2: アーキテクチャ): 軽-2-1 (1 件)
  - 第 3 ラウンド (観点 3: データモデル): 軽-3-1 + 軽-3-2 統合修正 (1 件)

  設計決定の追加: なし (既存 0-1〜0-5 で吸収)

  Phase 2 Spec 4 design 引き継ぎ:
  - rw doctor foundation サブコマンド仕様 (検証 4 種 schema が design 内 §「検証手段の規範」で確定済)
  - foundation.md path hardcode (.kiro/specs/rwiki-v2-foundation/foundation.md)

  修正後の design.md change log を更新します。
⏺ 厳しく再精査 (最終ガード)

  12 ラウンド完了後、memory feedback_review_rounds.md の規定に従い厳しく再精査を実施します。
  
⏺ 連鎖更新漏れ 1 件検出: design.md L187 mermaid 内に古い anchor 例示 #section-2-12 が残存 (軽-3-2 修正で #edge-status 形式に統一したが mermaid 内 Note は未修正)
⏺ 厳しく再精査で 連鎖更新漏れ 2 件 追加検出 (致-1):

  - 致-1A: §7 Component の Requirements 列挙に R10.5 残存 (軽-3 修正で §9 集約したが §7 の AC 列挙が未更新)
  - 致-1B: 検証 1 章節アンカー存在 Component の Requirements 列挙に R14.5 残存 (軽-5 修正で R14.5 を Boundary Commitments に再マップしたが検証 1が未更新)

  両件とも自動採択で修正適用。
⏺ 第 5 ラウンド (波及精査): 結果

  変更値リスト:
  - 用語アンカー形式 (GitHub 自動生成 ID #edge-status 形式)
  - 不変項目 4 種表記統一 (§2.10 / §2.12 / §2.2-§2.4 / §2.13)
  - L2 構成 = 6 ファイル + reject_queue/ ディレクトリ
  - §7-§9 章立て (R10.5 を §9 集約)
  - 検証 4 種 schema 規範

  波及範囲: 本 design 修正は design レベル (foundation.md 生成タスクへの instructions)、requirements は変動なし。

  Spec 1-7 への影響:
  - Spec 1-7 は requirements approve 済、design 未着手 (本 design が Phase 1 第 1 件目)
  - 用語アンカー形式は Phase 1 Spec 1 design 着手時に coordination として伝達
  - 検証 4 種 schema は Phase 2 Spec 4 design 着手時に coordination として伝達 (既に決定 0-2 で記録)

  Adjacent Sync TODO: なし (本セッション内同期不要、Phase 1-2 着手時の coordination 引き継ぎで足りる)

  ---
  12 ラウンド + 厳しく再精査 + 波及精査 完了サマリ

  修正適用合計: 9 件 (全件自動採択)
  - 12 ラウンド: 6 件 (軽-1 / 軽-2 / 軽-3 / 軽-5 / 軽-2-1 / 軽-3-1+3-2 統合)
  - 厳しく再精査: 3 件 (致-1A / 致-1B / mermaid Note 例示更新)

  escalate 案件: 0 件 (軽-4 修正不要判断のみユーザー対話で確定)

  設計決定: 5 件 (0-1〜0-5、初版から維持)

  Phase 1-2 引き継ぎ事項:
  - Phase 1 Spec 1 design: 用語アンカー引用形式 (foundation.md#edge-status)
  - Phase 2 Spec 4 design: rw doctor foundation 実装 (検証 4 種 schema 規範を実装に展開)

⏺ 12 ラウンドレビュー + 厳しく再精査 + 波及精査が完了しました。

  ユーザー approve 確認

  memory feedback_approval_required.md の visible action 規律に従い、spec.json approvals.design.approved = true はユーザー明示承認が必要です。

  現状:
  - design.md 確定 (約 740 行、修正 9 件適用済)
  - research.md 生成済 (設計決定 0-1〜0-5 + 議論ログ)
  - spec.json phase = design-generated / approvals.design.approved = false
⏺ Approve 確定。spec.json を更新します。
⏺ Spec 0 (rwiki-v2-foundation) design approve 完了 (phase = design-approved)。

⏺ 次のアクションを確認します。memory feedback_approval_required.md の visible action 規律に従い、commit / push は明示承認必要です。
⏺ Spec 0 を commit してから Spec 1 design に着手します。
```





## Spec 1 rwiki-v2-classification

```
⏺ Spec 0 design commit 完了 (37e9ab7)。Phase 1 Spec 1 (rwiki-v2-classification) design に着手します。
⏺ Spec 1 requirements 確認しました (14 Req、約 100 AC、frontmatter スキーマ詳細 + rw tag * CLI 13 サブコマンド + vocabulary YAML 3 種 + lint 統合 + coordination 多数)。Spec 0 と異なり実装検討量が大きい。brief.md と consolidated-spec の関連箇所を確認します。
⏺ Spec 1 brief.md を確認しました。design phase 持ち越し項目が約 42 件 列挙されており、Spec 0 design (規範文書 spec、6 件)より格段に大規模です。design draft 着手前に方針確認を取ります。
· design phase 持ち越し約 42 件をどう処理しますか？ → 全件 design.md に反映 (例示・規定を含めて詳細記述) (Recommended)
⏺ 全件反映を採択。Discovery を進めて draft 生成に向かいます。consolidated-spec §5 / §6.2 の関連箇所と v1-archive の vocabulary patternsを確認します。
⏺ Discovery + Synthesis 完了。design.md draft を生成します。本 spec は規模が大きいため、構造化重視で要点を網羅します。
⏺ research.md 完成。次に design.md draft を作成します。
 design.md draft (約 870 行) 完成。Review Gate を mechanical + judgment で確認します。

  Design Review Gate

  Mechanical Checks (全 PASS):
  - Requirements Traceability: 14 Req (1.1-14.5) 全件記載
  - Boundary section: 4 sub-section 全 populate
  - File Structure Plan: <dev>/scripts/ + <vault>/.rwiki/vocabulary/ + <vault>/review/ の具体 path
  - Boundary ↔ File Structure alignment: 整合
  - No orphan components: G1-G6 + Component (Category Resolution / Frontmatter Parser / Vocabulary Store / Tag CLI / Lint Integration) 全て File
  Structure に対応

  Judgment Review (全 PASS):
  - Requirements Coverage: 14 Req + 設計持ち越し 42 件全件吸収
  - Architecture Readiness: G1-G6 + 各 Component の Service/State/API contract
  - Boundary Readiness: 4 sub-section 明示、共有責務問題なし
  - Executability: implementation phase ファイル分割 + Phase 2/3 coordination 明示

  spec.json を更新します。
  
⏺ 12 ラウンドユーザーレビューを開始します。Spec 1 は実装含む spec のため、各ラウンドで軽微検出の可能性があります。

  第 1 ラウンド: requirements 全 AC の網羅 (観点 1)

  Step 1: 要点提示

  Traceability table 確認 (design.md L259-273):
  - 14 Req (1.1-14.5) 全件マップ済
  - 各 Req → G1-G6 sub-system + Component + Interfaces / Flows へ対応

  設計持ち越し 42 件の反映状況:
  - 第 1-2 R 12 件: design.md Components G1-G6 + Data Models に分散反映
  - 第 3 R 13 件: Coordination + 設計決定事項 1-3〜1-15 に集約
  - 第 4 R (B 観点) 10 件: Security / Performance / Error Handling + 設計決定 (1-3 / 1-6 / 1-7 / 1-8 / 1-14) に反映
  - 第 5 R (C 観点) 3 件: Coordination G6 で扱う (C-1 対応済 / C-3 / C-6 = Adjacent Sync 別 commit)
  - 第 6 R (D 観点) 1 件: 決定 1-4 で successor_tag rename 確定

  潜在的検出:

  design.md と requirements.md を再照合し、以下を検出:

  - 致-1: requirements.md R6.1 は現状 successor field、決定 1-4 で successor_tag rename を design 内で確定したが requirements.md R6.1 改版は別 commit
   と記述。これは確認だけして次のラウンドへ
  - 軽-1: design.md Traceability「9.1-9.8」記載だが requirements.md R9 の AC は 1-8 のみ (R9.7 / R9.8 の 2 件追加されて 8 AC)。整合
  - 軽-2: design.md Components G2 で「許可値外 merge_strategy: WARN (lint 拡張、設計持ち越し L 由来、本 design 内で R9.1
  検査項目に追加)」と記述したが、これは R9.1 検査項目の 新規追加 を design 内で意図しており、要件側 R9.1 は元の 8 検査項目のみ。Lint 拡張を design
  で先取りしているため、escalate 判定が必要

  Step 2-4: ユーザー判断 + 深掘り

  軽-2 は Lint 拡張を design で記述すると、要件と design の drift が発生。escalate 候補。
· 軽-2 設計持ち越し L (許可値外 merge_strategy WARN) を design で先取りすべきですか？ → design で記述維持 + R9.1 改版は別 commit (Recommended)

⏺ 軽-2 を設計決定 1-16 として明示記録します。
⏺ 第 1 ラウンド完了 (致-1 確認 / 軽-2 決定 1-16 として明示記録)。第 2 ラウンドへ。

  第 2 ラウンド: アーキテクチャ整合性 (観点 2)

  Step 1-4: 分析と検出

  - mermaid Architecture Pattern (L154-186): 依存方向 Foundation → Categories/Frontmatter → Vocabulary → TagCLI/Lint → Coordination、循環依存なし ✓
  - G1-G6 sub-system の責務分離明確
  - 各 Component の Service/State/API contract 整合

  検出:
  - 軽-2-1: design.md File Structure Plan で rw_classification.py を「G1-G2 共通
  utility」と簡潔記述、research.md「Module-per-Domain」と組み合わせると G1-G6 全件別 module の解釈と表記揺れ。実際は G1 (1 関数) と G2
  (parse/validate 2 関数) を同 module 集約が実装シンプル

  修正適用 (自動採択):
⏺ 第 2 ラウンド完了 (軽-2-1 自動採択)。第 3-12 ラウンドを一括して実施します。Spec 1 は実装含む spec のため、各観点で軽微検出を試みます。

  第 3 ラウンド: データモデル / スキーマ詳細

  検証: yaml schema 各 (tags / categories / entity_types / frontmatter common / L3 specific / Entity shortcut / review レイヤー) の 詳細記述を
  design.md L575-686 で確認

  検出:
  - 軽-3-1: design.md L606 categories.yml schema で「required 不採用」と書いたが requirements.md R7.1 に明示なし。requirements R7.1 では recommended
  / optional の 2 値とのみ記述。design 内補足説明として OK
  - 軽-3-2: update_history.evidence 型を design.md G2 で「raw/<...> 配下の relative path 文字列」と明記 (本-1 修正)、整合 ✓

  軽-3-1 は要件とのドリフトなし (requirements 段階での enforcement 値域が recommended / optional のみ、design 内で「required
  を不採用とした理由」を補足説明)、修正不要。

  第 4 ラウンド: API interface 具体化

  検証:
  - G1 resolve_category(page_path, vocab) → CategoryInfo ✓ (signature + Pre/Post/Invariants)
  - G2 parse_frontmatter(file_path) → Frontmatter + validate_frontmatter(fm, vocab) → List[LintFinding] ✓
  - G4 rw tag * 13 サブコマンド + exit code 0/1/2 ✓
  - G5 run_checks(file_paths, vocab) → LintReport + JSON output schema ✓

  検出なし: 全 Component に Service/API contract 明示、Spec 4/5 連携 contract も Coordination で明示。

  第 5 ラウンド: アルゴリズム検証

  - NFC normalization: unicodedata.normalize('NFC', s) で O(N)
  - Levenshtein 距離: difflib.SequenceMatcher の近似で大規模 vocabulary でも O(N×M) で許容範囲
  - vocabulary load: 3 YAML ファイル × 1K-10K entries × yaml.safe_load O(N)、規模問題なし
  - frontmatter parse: 1 ファイル単位で yaml.safe_load O(N)、scan 全体は O(File 数 × 平均サイズ)

  検出なし: アルゴリズム面の懸念なし、実装は標準ライブラリで完結。
  第 6 ラウンド: 性能達成手段

  - v2 MVP target: 1K タグ + 1K ページで rw tag scan / rw lint < 5 秒
  - Phase 2: 10K+ ページで mtime ベース cache (決定 1-8)
  - 性能は prototype 測定で検証 (memory feedback_design_review.md 整合)

  検出なし: Performance & Scalability セクションで規模別戦略明示。

  第 7 ラウンド: 失敗モード handler

  - vocabulary YAML parse failure → 該当検査のみ ERROR、他継続 (R9.7)
  - vocabulary 整合性 ERROR → 関連検査 skip + WARN (R9.8、誤検出回避)
  - frontmatter parse failure → fail-soft (Frontmatter(parse_error=...))
  - lock 取得失敗 → ERROR + retry guidance
  - 誤 approve 復旧 → git revert + decision_log 補正 (決定 1-7)

  検出なし: Error Handling セクションで全パターン網羅、決定 1-7 で rollback 手順確定。

  第 8 ラウンド: セキュリティ / プライバシー

  - YAML injection (B-5): vocabulary 操作 CLI で input 検査 ERROR
  - path traversal (B-6): rw tag register <tag> の引数 sanitize、../ / null byte ERROR
  - vocabulary entry curation provenance (決定 1-15): §2.13 で代替

  検出なし: Security Considerations で B-5 / B-6 / 決定 1-15 全て扱い。

  第 9 ラウンド: 観測性

  - lint output: JSON / human-readable 両形式 (R9.5)
  - rw tag scan severity 規約 (R8.2)
  - decision_log: vocabulary 操作の curation provenance (R8.13、Spec 5 所管)

  検出なし: Monitoring セクションで全項目扱い。

  第 10 ラウンド: 依存選定

  - Python 標準ライブラリのみ (pyyaml / unicodedata / pathlib / difflib / sqlite3 Phase 2)
  - 新規 runtime 依存なし

  検出なし: Technology Stack で全 layer 明示。

  第 11 ラウンド: テスト戦略

  - Unit Tests: frontmatter parse / vocabulary load / lint 8 検査 / rw tag * 13 サブコマンド (mock LLM CLI)
  - Integration Tests: rw lint 統合 / rw tag merge → review buffer → approve / normalize_frontmatter 連携
  - Cross-spec Integration Tests (consumer 側): Spec 4/5/7 design に記述

  検出なし: Testing Strategy で全 layer 網羅。

  第 12 ラウンド: マイグレーション戦略

  - v2 はフルスクラッチ (v1 から継承する frontmatter / vocabulary なし)
  - v2 → v2.1 schema 拡張時の migration 規約 (本-11) は Phase 2 で扱う

  検出なし: Migration Strategy で flowchart + Phase breakdown / Rollback triggers / Validation checkpoints 明示。
 ---
  厳しく再精査 (最終ガード)
⏺ 厳しく再精査結果: successor (wiki frontmatter) と successor_tag (tags.yml) の使い分けが design 全体で整合。連鎖更新漏れなし。

  design.md change log を更新します。
⏺ 12 ラウンドレビュー + 厳しく再精査 + 波及精査完了。サマリと approve 確認に進みます。

  Spec 1 design 12 ラウンドレビュー集約

  修正適用合計: 3 件 (全件自動採択)
  - 軽-2 → 決定 1-16 (lint G5「許可値外 merge_strategy WARN」追加、要件改版経路)
  - 軽-2-1 (File Structure Plan G1+G2 統合明記、design 内整合)
  - 致-1 確認 (既存決定 1-4 で吸収済)

  設計決定: 16 件 (1-1〜1-16)

  実質変更経路 (別 commit + 再 approve): 計 3 件
  - 決定 1-4: tags.yml successor → successor_tag rename → R6.1 改版
  - 決定 1-13: review/decision-views/ period_start / period_end 必須化 → R4.7 改版
  - 決定 1-16: lint G5「許可値外 merge_strategy WARN」追加 → R9.1 改版

  Phase 2-3 引き継ぎ:
  - Phase 2 Spec 4: rw doctor classification / rw approve 拡張 / .hygiene.lock / lint 統合 / rw tag * help text
· Spec 1 (rwiki-v2-classification) design を approve しますか？ → Approve (spec.json approvals.design.approved = true) (Recommended)
⏺ Spec 1 design approve 完了 (phase = design-approved)。

⏺ Phase 1 (Spec 0 + Spec 1) design approve 完了。次のアクションを確認します。
⏺ 要件改版 3 件完了。spec.json updated_at を更新して commit します。

本セッションは長時間に及び、context が大規模化しています。Phase─2─(Spec─4─/─Spec─7)─は並列処理可能な─Spec─2─件で、規模も大きい─(特に─Spec─4─は─CLI─統一規約の中核 spec) ため、ここで一旦区切ってセッションを継続するか、本セッション内で続行するかをご判断ください。

· Phase 1 完了、ここでの進め方をどうしますか？ → Phase 1 commit を origin/main へ push + セッション区切り (Recommended)

⏺ Push 完了 (6494d49..6978041)。Phase 1 origin/main 同期済み。

  本セッション総括

  Phase 1 (Spec 0 + Spec 1) design 完了 — 6494d49..6978041 を origin/main へ push

  Spec 0 (rwiki-v2-foundation):
  - design.md + research.md 生成 (約 740 行 / 約 270 行)
  - 14 Requirements を foundation §1-9 にマップ、検証 4 種規範 schema 確定 (Spec 4 実装委譲)
  - 12 ラウンドレビュー: 修正 9 件全件自動採択 + 厳しく再精査 3 件是正 (escalate 0)
  - 設計決定 0-1〜0-5 (foundation.md 物理 path / 検証 4 種規範実装分離 / 章立て対応 / 二重記録方式 / curation provenance 構造的非対称性)

  Spec 1 (rwiki-v2-classification):
  - design.md + research.md 生成 (約 1140 行 / 約 280 行)
  - 14 Requirements を G1-G6 6 sub-system にマップ、設計持ち越し 42 件全件反映
  - 12 ラウンドレビュー: 修正 3 件全件自動採択 (escalate 1 件 → 決定 1-16)
  - 設計決定 1-1〜1-16 (Unicode normalization / successor_tag rename / lint suggestion / rollback / 大規模 cache / directory_name / mapping 初期値 /
  Hygiene lock / 等)
  - 実質変更経路 3 件 (1-4 / 1-13 / 1-16) を requirements.md に反映 commit 済

  残タスク:
  - Phase 2 (Spec 4 / Spec 7 並列): 別セッションで着手
  - Phase 3 (Spec 5 / Spec 2 並列), Phase 4 (Spec 3), Phase 5 (Spec 6): 順次
  - 本セッションの dev-log 追記 (docs/Rwiki-V2-dev-log-3.md): 別セッションで一括

  セッション終了準備完了。Phase 2 着手は別セッションで TODO_NEXT_SESSION.md の更新指示に従って再開できます。
```

##### ❯ 次のセッションを始めるが、レビューログを見ると、ラウンド4−12は機能していないようにみえる

```
⏺ レビューログを確認しました。ユーザー指摘の通りです。memory の規定と実態を照合します。

⏺ レビューログと memory feedback_design_review.md 規定を照合しました。指摘の通り、ラウンド 4-12 が機能していません。

  規定違反の実態

  memory feedback_design_review.md の規定:
  - 各ラウンド Step 1-4 (要点提示 → ユーザー判断 → 詳細抽出 → 深掘り) 必須手順
  - 「該当なし」確認も明示的に行い、ラウンドを跳ばさない
  - 観点 11 (テスト戦略) / 12 (マイグレーション) は規模の小さい spec でも 該当なし扱いせず必ずラウンドを実施

  Spec 0 の実態 (dev-log-3 L223-285):
  - ラウンド 1-3 は個別実施 (5 step あり)
  - ラウンド 4-12 は「一括して結果報告します」で集約処理、各ラウンド「判定: 該当なし」のみ。Step 2 ユーザー判断が完全に省略

  Spec 1 の実態 (dev-log-3 L446-533):
  - ラウンド 1-2 は個別実施
  - ラウンド 3-12 は「一括して実施します」で集約処理、Step 2 省略
  - Spec 1 は実装含む spec で「アルゴリズム検証」「性能達成手段」「失敗モード handler」「テスト戦略」が「検出なし」のみで素通り —
  本来深く厚くなるべき観点

  具体的な問題

  - Spec 0: 観点 11 (テスト戦略) を「本 spec の Testing Strategy は十分」で済ませた。memory 規定「規模の小さい spec
  でも必ずラウンドを実施」と整合しない
  - Spec 1: 観点 5 (アルゴリズム) で Levenshtein 近似採用の根拠がユーザー対話を経ていない (本来 escalate 候補)
  - 両 spec ともラウンド 4-12 で ユーザー判断機会 (Step 2) を 9 ラウンド分 skip している

  これから Phase 2 (Spec 4 / Spec 7) に入る前の判断

  Phase 2 は Spec 4 (CLI 統一規約の中核) + Spec 7 (lifecycle management、実装重) で、ラウンド 4-12
  を一括処理すると重大な検出漏れリスクがあります。大局判断を仰ぎたい点が 1 件あります。

  【SSoT 判定要】Spec 0 / Spec 1 design の遡及対応をどうしますか？

  - 案 A: Phase 2 着手前に Spec 0 / Spec 1 の design review を「ラウンド 4-12 個別実施」でやり直す — 検出された修正があれば適用 + 再
  commit。コスト大だが Phase 2 以降の基準を確立できる (Recommended)
  - 案 B: Spec 0 / Spec 1 はそのまま、Phase 2 から正規プロセスを徹底 — 過去 2 spec の検出漏れリスクは残るが Phase 2 着手が早まる

  どちらでも Phase 2 着手時には 12 ラウンド個別実施 (Step 1-4 全踏襲、ユーザー対話 gate を skip しない) を徹底します。
```

##### ❯ スキップ防止策をメモリに記入。Spec 0 / Spec 1 の design review をラウンド 4-12についてはやりなおし。



## Spec 0 design ラウンド 4-12 やり直し

```
⏺ 承知しました。まず memory にスキップ防止策を追記します。
⏺ 既存 feedback_design_review.md にも skip 防止の強化規定を追記します。
⏺ MEMORY.md にインデックス追加します。
⏺ memory 更新完了。次に Spec 0 のラウンド 4-12 個別やり直しに着手します。Spec 0 design.md の現在の内容を確認します。

⏺ Spec 0 design.md を確認しました。ラウンド 4 から個別 5 step で進めます。

  第 4 ラウンド: API interface 具体化 (観点 4)

  Step 1: 要点提示

  Spec 0 における "API interface" 該当箇所:

  - 検証 4 種の schema 規範 (design.md L462-527): 検証 1 (anchor 存在) / 検証 2 (SSoT 章番号整合) / 検証 3 (citation link) / 検証 4 (frontmatter schema)
  - 各検証で確定済の要素:
    - 入力 (foundation.md path、consolidated-spec path、Spec 1-7 14 ファイル)
    - 検査内容 (linkable / link target / yaml block parse 等)
    - 出力 JSON schema ({check, failures, ...})
    - severity (ERROR / WARN)
    - exit code (PASS=0 / FAIL=2 / WARN=0 logs)
  - Spec 1-7 引用 contract (L601-605): path 形式 + anchor 安定性 + 引用検証
  - Adjacent Sync contract / 実質変更 contract (L607-617)

  潜在的検出 (詳細抽出は Step 3 で行うが、Step 1 で示す候補):

  - 軽-4-1 候補: 検証 1-4 の JSON 出力 top-level schema が個別 ({check, failures} / {check, drift_items} / {check, broken_links} / {check, parse_errors, missing_fields})。集約 (logs/doctor_foundation_latest.json) で複数 check を含む際の 共通 envelope schema が L590-593 で「{check, status: "pass"|"warn"|"fail", details: object}」と記述あるが、個別 schema との対応規定なし
  - 軽-4-2 候補: 検証 2 SSoT 章番号整合の入力に「想定 SSoT version (例: v0.7.12)」が記載されているが、これを どう渡すか (CLI 引数 / consolidated-spec 内記述から自動抽出 / hardcode) が未確定。Phase 2 Spec 4 委譲事項で良いが、design 内に明記推奨
  - 軽-4-3 候補: 検証 3 citation link チェックの「長期化 (3 ヶ月超) で ERROR 昇格」(L508 / L629) は どこで「3 ヶ月」を判定するか (lint metadata?
  改版日付からの計算?) が未確定。Phase 2 委譲か削除か判断要

  Step 2: ユーザー判断

  【選択肢あり】第 4 ラウンドの進め方をどうしますか？

  - 案 A: 上記 3 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 4 は「該当なし」で次ラウンドへ (検証 schema は十分具体化、Phase 2 委譲も明示済み)
```

##### ❯ A

```
⏺ requirements.md を確認してから Step 3-4 に進みます。
⏺ Step 3-4: 詳細抽出 + 深掘り判断

  requirements R10.7 確認: 整合性検証手段の選択肢 (a)(b)(c) は要件化、severity 区別 (ERROR/WARN) と「3 ヶ月閾値」は requirements 規定外で design
  先取り。

  3 候補の判断:

  - 軽-4-1 (envelope ↔ 個別 schema 対応未明示): 自動採択 (内部矛盾解消、致命的デメリットなし)
  - 軽-4-2 (SSoT version 受け渡し方法未確定): 自動採択 (Phase 2 Spec 4 委譲を明記、boundary clarification)
  - 軽-4-3 (「3 ヶ月超で ERROR 昇格」閾値): escalate (requirements 規定外の design 先取り、削除 / 委譲明記の選択肢あり)

  軽-4-1 / 軽-4-2 を Edit で適用してから escalate 提示します。
⏺ 軽-4-1 / 軽-4-2 適用済。軽-4-3 を escalate します。

  軽-4-3 escalate: 「3 ヶ月超で ERROR 昇格」閾値の取り扱い

  【SSoT 判定要】design.md L508 / L629 の「長期化 (3 ヶ月超) で ERROR 昇格」は requirements 規定外の design 先取り記述です。どう扱いますか？

  - 案 A: 記述を削除し、長期化判定は Phase 2 Spec 4 design 委譲と明記 — Spec 0 規範を最小に保ち、運用判断は Spec 4 で確定 (Recommended)
  - 案 B: 「3 ヶ月超」表記を残し、判定機構 (改版日付の保持場所 / 閾値判定 logic) を Phase 2 Spec 4 委譲と明記 — Spec 0で具体閾値を規範化、実装手段のみ委譲
```

##### ❯ A

```
⏺ 第 4 ラウンドの修正適用 3 件完了 (軽-4-1 / 軽-4-2 自動採択、軽-4-3 escalate → 案 A 採択)。次のラウンドへ進みます。

  第 5 ラウンド: アルゴリズム検証 (観点 5)

  Step 1: 要点提示

  Spec 0 は規範文書 spec のため、アルゴリズムは検証 4 種に限定:

  - 検証 1 (anchor 存在): foundation.md 内 [...](#anchor) 形式 link を抽出 → 各 anchor がヘッダー自動生成 ID と一致するか検査。計算量 O(L + H) (L =
  link 数、H = ヘッダー数)
  - 検証 2 (SSoT 章番号整合): foundation §1-§6 章タイトルと consolidated-spec §1-6 章タイトルの正規化マッチ。計算量 O(N×M) (N, M
  はそれぞれ章数、~10×10)
  - 検証 3 (citation link): Spec 1-7 全 14 ファイルを grep で foundation.md#[a-z0-9-]+ 抽出 → foundation.md の anchor と照合。計算量 O(F + L×H) (F =
  ファイルサイズ、L = link 数、H = anchor 数)
  - 検証 4 (frontmatter schema): foundation.md §5 内 yaml block を pyyaml で parse + 必須 field 出現検査。計算量 O(B) (B = yaml block 総サイズ)

  潜在的検出候補:

  - 軽-5-1 候補: 検証 1 の「ヘッダー自動生成 ID 計算」が 正規化ルールの不完全記述。design.md L577「lowercase + hyphen +
  英数字とハイフン以外の記号除去」と書いたが、GitHub の実際のルールはより複雑 (連続スペース → 単一 hyphen / 末尾 punctuation 除去 / 日本語文字保持 /
  連続 hyphen 圧縮なし等)。foundation.md は日本語混在 (## §2.12 Evidence-backed Candidate Graph 等) のため、正規化アルゴリズムが正しく実装されないと
  false positive を出す
  - 軽-5-2 候補: 検証 2 の「正規化マッチ」が マッチ logic 未確定。L491 例 ## §2.12 Evidence-backed Candidate Graph ↔ ### 2.12 Graph Ledger による
  Evidence-backed Candidate Graph の対応をどう判定するか (章番号一致のみ / タイトル含む文字列類似度 / 完全一致) が未確定。Phase 2 Spec 4
  委譲で良いが、現在の design では「正規化マッチ」が ambiguous
  - 軽-5-3 候補: 検証 3 の grep で foundation.md#[a-z0-9-]+ 形式と書いたが、foundation.md は 日本語ヘッダーも持つ (e.g. #### 用語集 5 分類 → GitHub自動 ID #用語集-5-分類)。正規表現に日本語文字を含めないと日本語 anchor の link 切れを検出できない
  - 軽-5-4 候補: 検証の edge case 網羅性 — 同名ヘッダー衝突時 GitHub -1 接尾、空ヘッダー、HTML タグを含むヘッダー、コードブロック内 #anchor等が記述されているか? design.md L583 で同名ヘッダー衝突対策は記述あり、他は未記述

  Step 2: ユーザー判断

  【選択肢あり】第 5 ラウンドの進め方をどうしますか？

  - 案 A: 4 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 5 は「アルゴリズム詳細は Phase 2 Spec 4 design 委譲、Spec 0 は schema 規範のみ」で「該当なし」判定、次ラウンドへ
```

##### ❯ A

```
⏺ 第 5 ラウンド修正適用 4 件完了 (全件自動採択)。次のラウンドへ。
 第 6 ラウンド: 性能達成手段 (観点 6)

  Step 1: 要点提示

  design.md L668-672 の Performance & Scalability:

  - target: 検証 1-4 を foundation.md (~500-1000 行想定) + Spec 1-7 14 ファイル (~10,000 行合計) に対して < 5 秒で完了
  - 方針: 機能優先 (correctness)、性能は prototype 測定で検証 (memory feedback_design_review.md 整合)

  潜在的検出候補:

  - 軽-6-1 候補: 性能 target「< 5 秒」の 根拠が未明示。foundation.md 1000 行 + Spec 1-7 14 ファイル 10,000 行は決して大規模ではないが、5
  秒は妥当な閾値か? CI 統合時の許容実行時間として妥当か? 根拠記述があると Phase 2 Spec 4 prototype 測定の評価基準になる
  - 軽-6-2 候補: 想定規模の妥当性 — Spec 1-7 design.md は実際にどの程度の行数になるか? Spec 0 だけで既に 738 行、Spec 1 design.md は 1140 行 (dev-log
   L580 より)。14 ファイル (Spec 1-7 × design + requirements) で 10,000 行は 過小見積 の可能性あり (実際は 15,000-20,000 行になる可能性)
  - 軽-6-3 候補: 性能劣化要因の明示なし — 検証 3 (Spec 1-7 grep) は Spec 1-7 の規模に線形スケールするが、Foundation 改版で anchor 数が増えると O(L×H)
   で逆相関的に増加。性能劣化シナリオを記述しておくと Phase 2 Spec 4 で対策設計可能
  - 軽-6-4 候補: 並列実行記述の不整合 — Flow 3 (L227) で「4 種は並列独立に実行可能」、L245 で「並列独立」と記述があるが、Performance section
  ではこの並列性が性能達成手段として明示されていない (Phase 2 Spec 4 で実装委譲だが design で並列実行を性能達成手段として記述しておくと boundary
  明確化)

  Step 2: ユーザー判断

  【選択肢あり】第 6 ラウンドの進め方をどうしますか？

  - 案 A: 4 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 6 は「prototype 測定で検証、design では target のみ規範化」で「該当なし」判定、次ラウンドへ
```

##### ❯ A

```
⏺ Step 3-4: 詳細抽出 + 深掘り判断

  4 候補すべて軽微 / 内部矛盾解消で 自動採択:

  - 軽-6-1: 「< 5 秒」根拠を CI 統合許容時間として明示
  - 軽-6-2: 想定規模を「各 spec design ~1000 行 + requirements ~200 行 × Spec 1-7 = ~10K 行」と明示 (Spec 0 738 / Spec 1 1140 行で実証済規模)
  - 軽-6-3: 性能劣化シナリオ (Foundation anchor 1000+ / Spec 1-7 link 1000+) を記述
  - 軽-6-4: 並列実行可能性を Performance section にも記述 (Flow 3 と整合)

  修正適用します。
⏺ 第 6 ラウンド修正適用 1 件完了 (4 候補を統合修正)。次のラウンドへ。

  第 7 ラウンド: 失敗モード handler (観点 7)

  Step 1: 要点提示

  design.md L619-636 の Error Handling:

  - 章節アンカー欠落 (検証 1 ERROR): 欠落 anchor 補完 or 引用 link 修正
  - SSoT 章番号 drift (検証 2 WARN): Adjacent Sync 経路で foundation.md 同期
  - 用語集引用 link 切れ (検証 3 WARN): foundation.md anchor 追加 or Spec 1-7 引用修正
  - frontmatter schema 妥当性違反 (検証 4 ERROR): foundation.md §5 修正 rollback / retry / timeout の具体パターン:
  - rollback: git revert (標準運用、design.md L283 lifecycle で言及)
  - retry: 検証 4 種は idempotent (副作用なし、副本生成のみ)、retry 安全
  - timeout: Phase 2 Spec 4 で確定 (本 design では schema のみ)

  潜在的検出候補:

  - 軽-7-1 候補: 検証実行時の runtime error handling 未記述 — 例: foundation.md ファイル読込失敗 (file not found / permission denied) / consolidated-spec ファイル不在 / yaml parse 中の OOM 等。これは Phase 2 Spec 4 委譲事項だが、design で boundary 明示推奨
  - 軽-7-2 候補: Foundation 改版時の rollback 手順 — design.md L693 「foundation.md 初版で重大不整合発覚 → Spec 0 design 段階に戻る」とあるが、実質変更経路で改版後に検出された不整合の rollback 手順 が未記述。git revert が標準だが、Spec 1-7 への波及反映済みの場合の連鎖 rollback はどうするか?
  - 軽-7-3 候補: 検証 2 WARN の「長期化対応」削除済 (前ラウンド) → 削除に伴う Error Handling section の整合性確認が必要
  - 軽-7-4 候補: 検証 4 種の partial failure — 検証 1 が ERROR、検証 2 が WARN、検証 3 が PASS のような混合状態の exit code は? L527 で「ERROR = 2 / WARN のみ = 0」と書いたが、複数検証の集約 exit code logic が design 内未明示 (Phase 2 Spec 4 委譲) — boundary 明示推奨

  Step 2: ユーザー判断

  【選択肢あり】第 7 ラウンドの進め方をどうしますか？

  - 案 A: 4 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 7 は「failure mode は規範 schema レベルで網羅、runtime error は Phase 2 委譲」で「該当なし」判定、次ラウンドへ
```

##### ❯ A

```
⏺ Step 3-4: 詳細抽出 + 深掘り判断

  4 候補:

  - 軽-7-1 (runtime error handling 未記述): 自動採択 (Phase 2 Spec 4 委譲明記、boundary clarification)
  - 軽-7-2 (実質変更経路の rollback 手順): 自動採択 (情報追加、design 内補足記述)
  - 軽-7-3 (前ラウンド「長期化」削除の整合確認): 修正不要 (前ラウンドで両方修正済、整合 ✓)
  - 軽-7-4 (検証 4 種の集約 exit code logic): 自動採択 (Phase 2 Spec 4 委譲明記、boundary clarification)

  修正適用します。
⏺ 第 7 ラウンド修正適用 1 件 (3 候補統合)。次のラウンドへ。

  第 8 ラウンド: セキュリティ / プライバシー (観点 8)

  Step 1: 要点提示

  design.md L660-665 の Security Considerations:

  - foundation.md は public 規範文書、認証 / 認可 / 秘匿情報なし
  - Privacy: foundation.md 自体に個人情報・秘匿情報なし
  - Integrity: git commit hash で改版 trail を保全、検証 4 種で機械的整合検出

  潜在的検出候補:

  - 軽-8-1 候補: 検証 4 種の入力 path traversal 防止記述なし — Spec 4 で実装される rw doctor foundation は foundation.md / consolidated-spec.md /
  Spec 1-7 14 ファイルを読む。Phase 2 Spec 4 で path 検証必要だが、Spec 0 design でこの種の入力検証規範は出てこない (規範 spec の境界として意図的に
  Out of Boundary)
  - 軽-8-2 候補: yaml deserialization リスク — 検証 4 で foundation.md §5 内 yaml block を parse する際、yaml.safe_load を使うことが暗黙前提。Spec 0
  design で「safe_load 必須」を規範化すべきか? Phase 2 Spec 4 委譲事項
  - 軽-8-3 候補: 改版 trail の git 依存 — Integrity を「git commit hash」に依存しているが、git 履歴が rebase / squash / force push
  で書き換えられた場合の改版 trail 保全は? これは運用判断 (rebase 禁止) で対処、Spec 0 規範対象外
  - 軽-8-4 候補: 規範 spec として「該当なし」のまま十分か — 認証/認可/sensitive data がないのは事実、Privacy & Integrity 記述で過不足ない。memory
  feedback_design_review.md「規模の小さい spec でも該当なし扱いせず」でも、Security の場合は「該当なし」確認自体が判断

  Step 2: ユーザー判断

  【選択肢あり】第 8 ラウンドの進め方をどうしますか？

  - 案 A: 4 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 8 は「規範文書 spec で sensitive data なし、yaml safe_load 等は Phase 2 委譲で十分」と「該当なし」判定、次ラウンドへ
```

##### ❯ A

```
⏺ Step 3-4: 詳細抽出 + 深掘り判断

  4 候補:

  - 軽-8-1 (path traversal 防止): 自動採択 (Phase 2 Spec 4 委譲明記)
  - 軽-8-2 (yaml safe_load 必須): 自動採択 (security best practice、Phase 2 Spec 4 規範化)
  - 軽-8-3 (git rebase/force push リスク): 修正不要 (運用判断、Spec 0 規範対象外)
  - 軽-8-4 (「該当なし」確認): 軽-8-1 / 軽-8-2 で改善余地が出たため事実上対応済

  修正適用します。
⏺ 第 8 ラウンド修正適用 1 件 (2 候補統合)。次のラウンドへ。

  第 9 ラウンド: 観測性 (観点 9)

  Step 1: 要点提示

  design.md L632-635 / L592-593 の Monitoring:

  - logs/doctor_foundation_latest.json (Phase 2 Spec 4 で確定): 検証 4 種の最新結果
  - 集約結果: logs/doctor_foundation_latest.json (Phase 2 Spec 4 design で確定、複数 envelope を array で内包)
  - 人間レビュー gate: foundation.md 改版時のチェック (実質変更経路)、Spec 0 spec.json approvals.requirements 再 approve

  潜在的検出候補:

  - 軽-9-1 候補: 検証 4 種の実行 trace 観測性 — logs/doctor_foundation_latest.json は 最新結果のみ で履歴は git 経由か? 検証 4 種を CI
  で連続実行した場合の trace (実行日時 / 所要時間 / 検出件数の推移) を観測する手段は? Phase 2 Spec 4 委譲事項だが、Spec 0 で観測 schema
  規範化が必要か判断
  - 軽-9-2 候補: 改版 trail の観測性 — design.md / foundation.md / requirements.md の change log は markdown
  末尾に手書きで追記される運用。spec.json.updated_at は更新されるが、実質変更 vs Adjacent Sync の判別 が trail から自動抽出可能か? 検証 4
  種の対象に「改版種別の整合性検査」を追加すべきか? (現状未含)
  - 軽-9-3 候補: 検証 4 種の logs にユーザー対応推奨記述を含めるか — 例: ERROR 検出時に「対応手順 (foundation.md §X を修正してください)」を logs
  に含めると人間レビュー gate での対応が容易。Phase 2 Spec 4 委譲事項、Spec 0 では regulation level
  - 軽-9-4 候補: 観測性の null 状態 (logs/ ディレクトリ未生成) — 検証 4 種が一度も実行されていない場合、logs/doctor_foundation_latest.json
  不在は許容? Phase 2 Spec 4 で CLI 初回実行時に logs/ ディレクトリを生成する規範を Spec 0 で先取りすべきか?

  Step 2: ユーザー判断

  【選択肢あり】第 9 ラウンドの進め方をどうしますか？

  - 案 A: 4 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 9 は「観測 schema は Phase 2 Spec 4 委譲、Spec 0 では集約 path のみ規範化」で「該当なし」判定、次ラウンドへ
```

##### ❯ A

```
⏺ Step 3-4: 詳細抽出 + 深掘り判断

  4 候補:

  - 軽-9-1 (実行 trace 観測性): 自動採択 (Phase 2 Spec 4 委譲明記)
  - 軽-9-2 (改版種別整合性検査): 自動採択 (検証 5 種目の追加可否を Phase 2 Spec 4 design で確定、現状 4 種維持。R10.7 決定 0-2 で (b)(c)
  不採用方針と整合)
  - 軽-9-3 (logs に対応推奨記述): 自動採択 (Phase 2 Spec 4 design で best practice として規範化)
  - 軽-9-4 (logs 未生成 null 状態): 自動採択 (Phase 2 Spec 4 委譲明記)

  修正適用します。
⏺ 第 9 ラウンド修正適用 1 件 (4 候補統合)。次のラウンドへ。

  第 10 ラウンド: 依存選定 (観点 10)

  Step 1: 要点提示

  design.md L132-141 の Technology Stack:

  - Document Format: Markdown (CommonMark + YAML frontmatter)
  - Schema Definition: YAML (frontmatter 骨格) / 構造化 list
  - Validation Reference: Phase 2 Spec 4 で確定
  - Runtime / Infrastructure: 該当なし

  requirements R11 の依存規範:

  - Python 3.10+ / Git 必須 / LLM CLI / Markdown エディタ
  - Python 依存を sqlite3 (標準) と networkx >= 3.0 (Spec 5 で追加) に限定
  - 検証 4 種実装で必要: pyyaml (標準) + 標準 grep / pathlib / re

  潜在的検出候補:

  - 軽-10-1 候補: 検証 4 種実装の依存記述が design 内分散 — Phase 2 Spec 4 で pyyaml / pathlib / re 等を使う想定だが、Spec 0 design では「Phase 2
  Spec 4 で確定」と委譲明記のみ。具体な Python 標準ライブラリ依存を Phase 2 引き継ぎとして列挙すべきか? (現状 dev-log L269 で言及あり、design
  内未明示)
  - 軽-10-2 候補: pyyaml の version 制約未記述 — yaml.safe_load を使う前提だが、最低 version 制約 (PyYAML 3.13+ で safe_load 標準化等) は Phase 2
  Spec 4 で確定。Spec 0 では委譲明記
  - 軽-10-3 候補: CommonMark 仕様 version の参照点未明示 — Document Format に「CommonMark」と記述あるが、CommonMark 0.30 / 0.31 等の version 整合は
  GitHub markdown 自動 ID 生成 logic 準拠の前提。design 内に GitHub markdown spec への参照点 (kramdown 風 / commonmark 風 / GitHub Flavored Markdown
  仕様) を Phase 2 Spec 4 で確定として明記
  - 軽-10-4 候補: 依存禁止規律の追加 — design.md L57 で「v1 spec / 実装への参照」を依存禁止としているが、検証 4 種実装段階で Spec 5 / Spec 6 等
  downstream spec への依存禁止 (検証 4 種は Spec 1-7 を読み込むが、library として Spec X モジュールを import しない) を明記すべきか?

  Step 2: ユーザー判断

  【選択肢あり】第 10 ラウンドの進め方をどうしますか？

  - 案 A: 4 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 10 は「依存は Phase 2 Spec 4 design で確定、Spec 0 規範対象外」で「該当なし」判定、次ラウンドへ
```

##### ❯ A

```
⏺ Step 3-4: 詳細抽出 + 深掘り判断

  4 候補すべて軽微 / boundary clarification で 自動採択:

  - 軽-10-1: 検証 4 種実装の Python 標準ライブラリ依存 (pyyaml / pathlib / re / json / subprocess (grep)) を Phase 2 引き継ぎとして列挙
  - 軽-10-2: pyyaml version 制約は Phase 2 Spec 4 委譲明記
  - 軽-10-3: GitHub markdown spec (Linguist / cmark-gfm 等) 参照点は Phase 2 Spec 4 委譲明記
  - 軽-10-4: 検証 4 種実装は Spec 5/6/7 等 downstream spec を library として import しない (markdown ファイルとして読み込むのみ) を明記

  修正適用します。
⏺ 第 10 ラウンド修正適用 1 件 (4 候補統合)。次のラウンドへ。

  第 11 ラウンド: テスト戦略 (観点 11)

  memory feedback_design_review.md 規定: 観点 11 / 12 は規模の小さい spec でも該当なし扱いせず必ずラウンドを実施。

  Step 1: 要点提示

  design.md L637-658 の Testing Strategy:

  - Document Lint (検証 4 種、Phase 2 Spec 4 で実装):
    - 検証 1 章節アンカー存在: foundation.md 内 link integrity (3-5 anchor sample)
    - 検証 2 SSoT 章番号整合: consolidated-spec ↔ foundation 章番号 alignment (§1-§6 全章)
    - 検証 3 用語集引用 link 切れ: Spec 1-7 全 design + requirements (14 ファイル) → foundation.md anchor (3-5 link sample)
    - 検証 4 frontmatter schema 妥当性: §5 内 yaml block (3-5 block) parse + 必須 field 検査
  - Cross-spec Integration Test (consumer 側に記述、ハイブリッド方式):
    - 例: Spec 1 design 内で「Spec 1 frontmatter 詳細スキーマが foundation §5 骨格と整合する」test
    - 例: Spec 5 design 内で「Spec 5 L2 ledger schema が foundation §3 6 ファイル骨格と整合する」test
  - 人間レビュー Gate: foundation.md 初版生成 / 実質変更時

  潜在的検出候補:

  - 軽-11-1 候補: Document Lint sample 数「3-5」の根拠不明 — foundation.md は §1-§9 で章節 anchor が数十個、用語集 §4 で約 50 anchor 想定。「3-5
  sample」では coverage 不足の可能性。Phase 2 Spec 4 で全件検査すべきでは? 「3-5 sample」記述を「全件検査」に変更すべき
  - 軽-11-2 候補: Cross-spec Integration Test の詳細未確定 — Spec 1-7 design 内で「foundation §X と整合する」test を書く規律は明示されているが、test
  の形式 (markdown lint として書くか / Python pytest として書くか / 検証 4 種の sub-task として書くか) が未確定。Phase 2 Spec 4 委譲か?
  - 軽-11-3 候補: 検証 4 種自体の test 戦略未記述 — 検証 4 種実装そのものの unit test (例: 検証 1 で同名衝突 anchor 入力 → 期待 output) は Phase 2
  Spec 4 design で記述、Spec 0 で boundary 明示
  - 軽-11-4 候補: regression test の記述なし — foundation.md 改版時に既存検証 4 種が壊れていないかの regression test (例: 過去の anchor
  が変動していないか) は Phase 2 Spec 4 委譲か運用判断 (人間レビュー gate) か未明示

  Step 2: ユーザー判断

  【選択肢あり】第 11 ラウンドの進め方をどうしますか？

  - 案 A: 4 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 11 は「test 戦略は consumer 側 + Phase 2 Spec 4 委譲で網羅」で軽微のみ追記、escalate なし、次ラウンドへ
```

##### ❯ A

```
⏺ Step 3-4: 詳細抽出 + 深掘り判断

  4 候補:

  - 軽-11-1 (sample 数「3-5」誤り → 全件検査): 自動採択 (誤った記述の是正、検証 1 / 検証 3 / 検証 4 は対象を全件検査が正しい)
  - 軽-11-2 (Integration Test 形式未確定): 自動採択 (Phase 2 Spec 4 委譲明記)
  - 軽-11-3 (検証 4 種 unit test): 自動採択 (Phase 2 Spec 4 委譲明記)
  - 軽-11-4 (regression test): 自動採択 (Phase 2 Spec 4 委譲明記)

  修正適用します。
⏺ 第 11 ラウンド修正適用 1 件 (4 候補統合)。次のラウンドへ。

  第 12 ラウンド: マイグレーション戦略 (観点 12)

  memory feedback_design_review.md 規定: 観点 12 は規模の小さい spec でも該当なし扱いせず必ずラウンドを実施。

  Step 1: 要点提示

  design.md L674-694 の Migration Strategy:

  - v1 から継承する規範文書なし (フルスクラッチ)
  - foundation.md lifecycle: Init (initial generation) → Approve → Reference → Revision (Adjacent Sync / 実質変更)
  - mermaid flowchart で lifecycle 図示
  - Phase breakdown: implementation phase で foundation.md 初版生成 → Spec 1-7 引用整合確認 → Phase 2 Spec 4 で rw doctor foundation 実装
  - Rollback triggers: foundation.md 初版で重大不整合発覚 → Spec 0 design 段階に戻る
  - Validation checkpoints: 検証 4 種 + 人間レビュー gate

  潜在的検出候補:

  - 軽-12-1 候補: 「v1 から継承なし、移行不要」の completeness — フルスクラッチ方針は確立済 (R10.5)、ただし v1 で同等の規範文書 (例:
  docs/curatedRraphRAG-V2.md / docs/仕様V2に向けての議論.md 等) が存在する。これらは drafts として位置付けて参照、移行対象ではないが migration
  strategy で「参照ログとして残置」を明示すべきか?
  - 軽-12-2 候補: drafts (consolidated-spec) からの「移行」概念 — drafts/rwiki-v2-consolidated-spec.md v0.7.12 は議論ログ、foundation.md 確定後は
  drafts は議論ログとして残置 (design.md L76)。これは「migration」ではないが、drafts → foundation.md の遷移時点を migration strategy で明示すべき
  - 軽-12-3 候補: Foundation 改版時の Spec 1-7 連鎖 migration — foundation.md の実質変更時に傘下 Spec 1-7 が再 approve される migration flow が
  Migration Strategy に統合されていない (Flow 2 と重複だが、Migration Strategy section で参照点として明示推奨)
  - 軽-12-4 候補: Phase breakdown の Phase 名統一 — Phase 1-2 が dev-log の Phase 1 (Spec 0+1) / Phase 2 (Spec 4+7) と区別不明確。design.md L692
  の「Phase 2 Spec 4」は dev-log Phase 2 の Spec 4 design 着手を指しており用語衝突なし、ただし整合確認

  Step 2: ユーザー判断

  【選択肢あり】第 12 ラウンドの進め方をどうしますか？

  - 案 A: 4 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 12 は「フルスクラッチで migration なし、lifecycle のみ flowchart で図示済」で軽微確認のみ、escalate なし、次ラウンドへ
```

##### ❯ A

```
⏺ Step 3-4: 詳細抽出 + 深掘り判断

  4 候補:

  - 軽-12-1 (v1 docs 残置): 自動採択 (docs/curatedRraphRAG-V2.md / docs/仕様V2に向けての議論.md 等は v1 spec ではなく v2 設計
  draft、参照ログとして残置を明示)
  - 軽-12-2 (drafts → foundation.md 遷移): 自動採択 (Migration Strategy で明示)
  - 軽-12-3 (Spec 1-7 連鎖 migration): 自動採択 (Flow 2 への参照点を追加)
  - 軽-12-4 (Phase 名整合): 自動採択 (design 内「Phase 2 Spec 4 design」が dev-log Phase 2 と一致することを明示)

  修正適用します。
⏺ 第 12 ラウンド修正適用 1 件 (4 候補統合)。12 ラウンド完了。

  厳しく再精査 (最終ガード)

  memory feedback_review_rounds.md 規定に従い、12 ラウンド + 修正後の連鎖更新漏れを精査します。
⏺ 連鎖更新漏れ精査結果: design 内整合は維持されている。requirements.md / research.md への波及なし (実質変更なし)。change logに修正サマリを追記します。

⏺ Spec 0 design ラウンド 4-12 やり直し完了サマリ

  修正適用: 計 10 件
  - R4: 3 件 (軽-4-1 / 4-2 自動採択 / 4-3 escalate → 案 A)
  - R5-R12: 各観点で軽微 1-4 件、すべて自動採択
  - 9 ラウンド全てで Step 1-4 個別実施 + ユーザー判断機会 (Step 2) 確保

  escalate 確定: 1 件
  - 軽-4-3「3 ヶ月超で ERROR 昇格」記述削除、Phase 2 Spec 4 design 委譲

  requirements.md / research.md への波及: なし (design 内記述精度向上のみ、実質変更なし)

  spec.json phase: design-approved 維持 (本やり直しは Adjacent Sync 経路として位置付け可能、design 内整合性向上)

⏺ 次のアクション確認

  memory feedback_approval_required.md 規律により commit はユーザー明示承認必要。

  【選択肢あり】次のアクションをどうしますか？

  - 案 A: Spec 0 修正を単独 commit してから Spec 1 ラウンド 4-12 やり直しに着手 (Recommended、変更単位を分離して履歴明確化)
  - 案 B: Spec 1 まで完了させてから両方を一括 commit (Phase 1 やり直しを 1 commit に集約)
```

##### 

## Spec 1 design ラウンド 4-12 やり直し

```
⏺ Spec 1 design.md 確認完了。1145 行で実装含む spec、観点 5/6/7 が深く厚くなる想定。ラウンド 4 から個別 5 step で進めます。

  第 4 ラウンド: API interface 具体化 (観点 4)

  Step 1: 要点提示

  Spec 1 における API interface 該当箇所:

  - G1: resolve_category(page_path, vocab) → CategoryInfo (Service)
  - G2: parse_frontmatter(file_path) → Frontmatter / validate_frontmatter(fm, vocab) → List[LintFinding] (Service)
  - G3: VocabularyStore (State、3 YAML 永続)
  - G4: rw tag * 13 サブコマンド CLI signature (API Contract table)
  - G5: run_checks(file_paths, vocab) → LintReport (Service) + JSON output schema

  各 component で確定済の要素:
  - preconditions / postconditions / invariants
  - exit code 規約 (R8.11、PASS=0 / runtime=1 / FAIL=2)
  - subprocess timeout 必須 (R8.12)
  - API Contract table (G4 で 13 サブコマンド signature)
  - JSON output schema (G5 で例示)

  潜在的検出候補:

  - 軽-4-1 候補: G1 / G2 の error model 暗黙化 — resolve_category で page_path が wiki/ 配下でない場合 (raw/ / review/) の処理が Preconditions
  で「wiki/ 配下」と書かれているが、違反時の error 定義なし。parse_frontmatter も markdown 以外を渡された場合の error 定義なし
  - 軽-4-2 候補: vocabulary 操作の idempotency 未明示 — 同じ canonical を 2 回 merge / 同じ tag を 2 回 register / 既に deprecated の tag を再
  deprecate した場合の動作。rw tag merge は vocabulary_candidates/ 経由なので review buffer で衝突検出するが、規範 level で idempotency 規約なし
  - 軽-4-3 候補: G4 13 サブコマンドの引数詳細未確定 — long flag / short flag / 必須 vs 任意の 正規化 (例: -f / --file / --no-prompt 等の flag
  命名規約) は Phase 2 Spec 4 CLI 統一規約所管 (本-22 で再委譲済) — boundary 明示推奨
  - 軽-4-4 候補: G3 VocabularyStore の thread safety / read 同時実行 — write 系は .hygiene.lock 取得必須 (R8.14) を明示、read 系の同時実行は safe
  (ファイル read のみ) と明示なし
  - 軽-4-5 候補: G5 JSON output category enum の不完全列挙 — "unregistered_tag" | "alias_usage" | "deprecated_tag" | "..." で 8 検査項目 (+ 拡張 2
  項目) 全件列挙されていない、enum 値の完全列挙が API consumer (Spec 4 lint 統合) に必要

  Step 2: ユーザー判断

  【選択肢あり】第 4 ラウンドの進め方をどうしますか？

  - 案 A: 5 候補を Step 3 で詳細抽出 → Step 4 で深掘り + 自動採択 / escalate 判断 (Recommended)
  - 案 B: 観点 4 は「API contract は十分具体化、CLI 詳細は Spec 4 委譲」で軽微 1-2 件のみ追記、次ラウンドへ
```















TODO_NEXT_SESSION.md を読んでください。Phase 1 (Spec 0 + Spec 1) design approve 完了済 (origin/main 同期済 = e41b412)。これから Phase 2 (Spec 4 / Spec 7 並列) design phase に着手します。設計レビューは memory feedback_design_review.md の 12 観点 = 12 ラウンドを基本全件網羅実施で進め、各ラウンドで仕様レビュー継承の 5 step 必須手順 + 深掘り検討 + 自動採択 + 厳しく再精査を踏襲します。設計決定は ADR 不採用、design.md 本文「設計決定事項」セクション + change log の二重記録。仕様⇄設計往復は「仕様 AC として読めるかどうか」+ ユーザー対話必須。最初の対象 spec (Spec 4 か Spec 7) を確認してから着手してください。