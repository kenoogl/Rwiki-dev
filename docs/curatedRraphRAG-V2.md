# Rwiki - Curated GraphRAG version 2.x

~~~
この議論は v2 設計の根幹を揺るがすほど重要です。これまで積み重ねた 20シナリオ以上の設計を再評価する価値があるパラダイム転換です。整理しつつ、既存設計との和解案を提示します。

  ---
  1. この議論の本質的インパクト

  3 つの核心的転換

│      軸    │           これまでの v2            │                  新議論               │
│ 構造の生成   │ 人間が書く（frontmatter related:） │ LLM が仮説生成、人間は reject のみ       │
│ Graph の性質 │ Static、決定論的、approve 時確定   │ Probabilistic、confidence 付き、進化する │
│ 人間の役割   │ Approve（承認が原則）              │ Filter（否定のみ）+ L4 Curation          │


  用語が指す新しいオブジェクト
  - Graph Hygiene: decay / reinforcement / competition の進化則
  - Usage signal: 推論への貢献度 × 独立性 × 時間減衰
  - Evidence-backed Candidate Graph: 根拠付き候補 edge の台帳
  - Edge events: confidence の時系列変化履歴

  ---
  2. 既存 v2 設計との緊張点

  緊張 1: 「人間承認必須」vs「Reject-only」

  既存 v2 で何度も確認した原則：

  - Spec 7 (lifecycle): 承認 gate（approve が原則）
  - Scenario 11 (deprecate): 8 段階対話ガイド
  - Scenario 16 (query → synthesis 昇格): 最高ランク dangerous op

  新議論：
  - 全部 approve → O(N²) で破綻
  - confidence 閾値で auto-accepted
  - 人間は例外的に reject

  本当の対立点: 「wiki 正本に入るもの」vs「candidate graph に残るもの」の境界が曖昧。

  緊張 2: Frontmatter vs Edge ledger

  既存 v2:
  - Markdown frontmatter が source of truth
  - related: で typed edges を記述
  - SQLite index は derived

  新議論:
  - JSONL edge ledger が正本
  - confidence、events、evidence 分離
  - frontmatter よりリッチな動的構造

  対立: どちらが source of truth か？

  緊張 3: 構造化前提 vs 構造は副産物

  既存 v2:
  - Scenario 1 (classification): カテゴリ + frontmatter 必須
  - Scenario 12 (vocabulary): 明示的な vocabulary 管理

  新議論:
  - raw は自由記述
  - 構造は LLM が後で抽出
  - ontology は使用を通じて「創発」

  対立: Rwiki のコアが「キュレート済 wiki」か「進化する candidate graph」か。

  緊張 4: 単一 Graph vs 階層 Graph

  既存 v2:
  - Curated GraphRAG（前回の議論）
  - wiki 全体を 1 つの graph として扱う

  新議論:
  - L0 raw → L4 curated の 4 層
  - 各層で扱いが違う
  - 下位層はノイジー、上位層はクリーン

  ---
  3. 和解案: 4 層アーキテクチャで統合

  v2 の既存設計を破棄せず、新議論を第 2 層として追加する提案：

  4 層の位置付け

  L0: Raw Input（自由記述、ELN、対話ログ）
        ↓ ingest（Scenario 26 既存）
  L1: Extracted Candidate Graph（LLM 自動抽出）← 新議論の中核
        - entities.yaml
        - candidate_edges.jsonl
        - evidence.jsonl
        - edge_events.jsonl（Hygiene 適用）
        ↓ confidence 閾値 + query 使用で昇格候補
  L2: Stable Graph（auto-accepted 高 confidence edges）← 新議論の deliverable
        - confidence > 0.75
        - reject されていない
        - query で繰り返し使用
        ↓ 人間承認（重要な subset のみ）
  L3: Curated Wiki（既存 v2 の wiki/）← 既存 v2 の中核
        - 人間承認済み markdown pages
        - frontmatter: title, source, tags, status
        - `related:` は stable edges のみ（L2 からの derived）
        ↓ 更に慎重な承認
  L4: Synthesis Layer（既存 v2 の wiki/synthesis/）← 既存 v2 の最高峰
        - 横断的・創発的知識
        - 8 段階対話必須
        - 「最も信頼できる」層

  各層での人間の関与

│     層     │                入力      │           人間の関与         │ cognitive load │
│L0 Raw      │ 自由記述                  │ゼロ（commit のみ）            │ 最小           │
│L1 Candidate│ LLM 自動抽出              │Reject only（dashboard で否定）│ 軽い           │
│L2 Stable   │ L1 から confidence /     │ なし（全自動）                 │ ゼロ           │
│            │ usage で自動昇格          │                              │               │
│L3 Wiki     │ L2 + 人間記述             │Approve（主要ページのみ）       │ 中             │
│L4 Synthesis│ L3 + 対話的精緻化          │8 段階対話必須                 │ 高             │

  この階層で既存 v2 が救われる理由

│             既存シナリオ    │      L? に位置する      │      変更点                     │
│ Scenario 7 (extend wiki)  │ L3                    │ そのまま維持                     │
│ Scenario 8 (merge)        │ L3 + L4               │ そのまま                         │
│ Scenario 11 (deprecate)   │ L3 + L4               │ status は L3 以降のみ、           │
│                           │                       │ L1/L2 edges には status 不要     │
│ Scenario 14 (perspective) │ L2 の graph を traverse │ 精度向上（candidate edges も活用）│
│ Scenario 14 (hypothesis)  │ L1 candidate edges +   │ 自然な発展（hypothesis は未検証    │
│                           │  L2 missing bridges    │  candidate）                    │
│ Scenario 16               │ L2 → L3 → L4           │ そのまま                         │
│ (query → synthesis 昇格)   │                        │                                │
│ Scenario 20 (custom skill)│ Any layer              │ そのまま                         │
│ Scenario 26               │ L0 → L1                │ そのまま                         │
│(lint-fail recovery)       │                        │                                │

  ---
  4. 既存 v2 の何を修正すべきか

  Spec 5（knowledge-graph）: 大幅更新

  Before: SQLite + frontmatter related: / ショートカット

  After:
  - JSONL ledger が L1/L2 の source of truth（.rwiki/graph/candidate_edges.jsonl, edge_events.jsonl, evidence.jsonl）
  - Frontmatter related: は L3 以降の stable edges のみ（ledger から derived）
  - SQLite は全層の cache index
  - 新要素: confidence、status (weak/candidate/stable/core/deprecated)、events、decay/reinforcement

  新 Spec?: Graph Hygiene

  Spec 5 に含めるか、新 Spec として独立させるか：

  - decay / reinforcement / competition の進化則
  - usage_signal 計算
  - confidence 更新ロジック
  - 定期バッチ（cron 的）

  提案: Spec 5 に統合（knowledge-graph の運用則として）

  Spec 6（perspective-generation）: 強化

  - Perspective: L2+L3 を対象（candidate edges も活用で精度向上）
  - Hypothesis: L1 candidate + L2 missing bridges から発見
  - rw verify が candidate edge を stable に昇格させるフローに統合

  Spec 7（lifecycle-management）: 適用範囲の明確化

  - L3/L4 ページに対する lifecycle（deprecate / retract / archive / merge）はそのまま
  - L1/L2 edges には page lifecycle 適用しない
  - L1/L2 edges には edge lifecycle（candidate → stable → core → deprecated）が適用、これは Spec 5 の進化則

  Scenario 33（Maintenance UX）: さらに強化

  - L1 candidate edges の reject UI（dashboard）
  - Autonomous mode で「新 candidate edges が 50 件溜まっています、数件 reject しますか？」

  ---
  5. 新概念の整理

  (a) Confidence

  - 定義: evidence-backed trust score（LLM の自信ではない）
  - 計算: evidence × explicitness × source_reliability × graph_consistency × recurrence × human_feedback
  - 更新: decay、reinforcement、query usage、reject

  (b) Edge status

  status:
    - weak          # confidence 低、ほぼ使われない
    - candidate     # 見込みあり、review queue
    - stable        # 高 confidence、自動採用
    - core          # 頻用、graph の骨格
    - deprecated    # 古い・矛盾、使わない
    - rejected      # 人間が明示否定

  (c) Edge lifecycle（Page lifecycle とは別）

  candidate (ingest 直後)
      ↓ confidence 上昇、usage、no reject
  stable
      ↓ 頻用、多 source 再出現
  core
      ↓ (長期) use されない、矛盾、新 edge に吸収
  deprecated

  (d) Evidence ledger

  {"evidence_id":"ev_001","file":"raw/logs/2026-04-24.md","quote":"...","span":"L20-L24"}

  全 edge は evidence_id 参照。evidence なし = confidence 上限 0.3。

  (e) Usage signal

  usage_signal =
    base_score            # direct / support / retrieval / co-activation
    × contribution        # core / chain / peripheral
    × sqrt(confidence)    # 低品質 edge の暴走防止
    × independence        # 同一 source の重複を割引
    × time_weight         # 最近 usage を重視

  (f) Graph Hygiene（進化則）

  3 つの基本ダイナミクス + 2 つの重要機能：

  1. Decay: confidence *= (1 - λ) per day
  2. Reinforcement: confidence += α × usage_signal
  3. Competition: 類似 edge 同士で scoring
  4. Contradiction tracking: 矛盾を削除せず contradicts 関係に変換
  5. Merging: 似た relation（improves ≒ enhances）を統合

  ---
  6. 実装上の選択（新議論から）

  ファイル構造（提案）

  <vault>/
  ├── wiki/ (L3, L4)                     # 既存、curated markdown
  ├── raw/ (L0)                          # 既存、自由記述
  ├── review/                            # 既存、approve 待ち
  │   ├── synthesis_candidates/
  │   ├── skill_candidates/
  │   ├── ...
  │   └── reject_queue/                  # 新: 人間 reject 待ちの edges
  └── .rwiki/
      ├── graph/                         # 新: L1/L2 の source of truth
      │   ├── entities.yaml              # normalized entities
      │   ├── candidate_edges.jsonl      # L1 全 edges
      │   ├── stable_edges.jsonl         # L2 昇格済 edges
      │   ├── rejected_edges.jsonl       # 人間 reject 済
      │   ├── evidence.jsonl             # 根拠引用集
      │   └── edge_events.jsonl          # confidence 変遷ログ
      └── cache/
          └── graph.sqlite               # 全層の high-perf index

  Git 管理方針

│       ファイル        │         git 管理      │                      理由              │
│ wiki/                │ ✓                    │ human-authored curated                │
│ raw/                 │ ✓                     │ 生データ、evidence 参照元               │
│ review/              │ ✓（.gitignore にしない）│ approve 進行中の state                 │
│ .rwiki/graph/*.jsonl │ ✓                     │ Edge ledger は 再生成困難なので git 管理 │
│ .rwiki/cache/*.sqlite│ ✗（gitignore）        │ cache、再生成可能                       │

  ここは前回の議論と違う: 前回は .rwiki/graph/ を全部 gitignore にしたが、ledger は git 管理すべき（decay の進化史は reproducible ではない）。

  ---
  7. 最も重要な確認事項

  この議論は v2 の中核哲学を変えるため、慎重に合意が必要です。

  決定事項 1: 4 層アーキテクチャの採用

  Rwiki v2 を「単一 curated wiki」ではなく「4 層（Raw → Candidate → Stable → Wiki → Synthesis）」として再構築する。L1/L2の新設で、新議論の内容を取り込みつつ L3/L4 で既存 v2 の approve 文化を保つ。

  Yes/No?

  決定事項 2: Edge ledger（JSONL）の採用

  L1/L2 edges は frontmatter ではなく JSONL ledger に記録。frontmatter related: は L3/L4 の stable edges のみを持つ（derived from ledger）。

  Yes/No?

  決定事項 3: Graph Hygiene の進化則

  Decay / reinforcement / competition / contradiction tracking / merging を edge level の lifecycle として Spec 5 に統合。定期バッチ + query 時強化。

  Yes/No?

  決定事項 4: Reject-only flow の追加

  既存の approve flow は L3/L4 で維持。新たに L1/L2 candidate edges に対する reject-only UI（review/reject_queue/ or dashboard）を追加。

  Yes/No?

  決定事項 5: Autonomous maintenance の拡張

  Scenario 33 の autonomous mode に「candidate edges が蓄積しています、dashboard で reject しますか？」等の提案を追加。

  Yes/No?

  ---
  8. もし決定事項 1-5 全て yes なら

  両 Draft に反映する作業は大きい：

  - consolidated-spec v0.7: §2.11 の後に「§3: 4 層アーキテクチャ」を新設、Spec 5 の大幅書換え
  - scenarios v0.7: 既存 scenarios の L 層位置付けを明示、新シナリオ（edge reject flow、Graph Hygiene 運用）を追加
  - 新 docs: docs/architecture/layered-graph.md（技術詳細）

  ---
  9. 私の意見

  この議論の方向性は正しいと強く思います。理由：

  1. 「入力コスト問題」は実在: Rwiki 単独運用では 3-6 ヶ月で破綻する懸念
  2. Evidence-backed で trust chain 維持: confidence × evidence で人間承認の代替が成立
  3. 既存 v2 と統合可能: 4 層モデルで L3/L4 に既存設計を温存
  4. Progressive disclosure: L0 でスタート、L4 で本気、という段階的使い込み
  5. 現実的な運用想定: 毎日毎週の負担が減り、長期持続性が上がる

ただし、このパラダイム転換を採用すると、これまで合意した 20+ シナリオの再評価が必要です。軽くはありません。

  ---
  10. 進め方の選択肢

  (A) 全面採用、両 Draft を v0.7 として大幅書換え

  数時間〜1 日の作業。v2 設計が完全に新しい形に。

  (B) 段階的採用 — Phase 1 として L1/L2 candidate graph を別 layer として追加

  既存 v2 の Spec 0-7 はそのまま、Spec 5 の中に新要素を追加する形で実装。既存合意を壊さない。

  (C) さらに議論 — この新パラダイムの盲点を先に洗い出す

  ユーザーの指摘通り「これが最大の問題」。採用決定前に追加反論をもう一度。

  私の推奨

  (B) 段階的採用を推奨します。理由:
  - 既存 v2 の approve 文化（wiki/synthesis 最高ランク等）は保護すべき価値
  - 新議論は「下層の自動化」の強化であり、並立可能
  - Spec 5 (knowledge-graph) を拡張して L1/L2 candidate graph layer を追加するだけで済む
  - 影響は Spec 5, 6, 7 に限定、Spec 0-4 は維持

  ただし、ユーザーが (A) を選ぶなら、それに沿った大規模改訂も実施します。
  ---

~~~



### 4層の議論

~~~
❯ 議論を続けます。まず、4層にする理由は何か？

⏺ 良い指摘です。実は私の「4 層（正確には 5 層）」提案は構造的区別と状態属性を混同していました。再考させてください。

  ---
  1. 私が提案した 5 層の内訳と、その混乱

  L0: Raw Input            ← 入力層（自由記述）
  L1: Candidate Graph      ← 自動抽出された候補 edges
  L2: Stable Graph         ← 高 confidence で auto-accepted
  L3: Curated Wiki         ← 人間承認済 markdown
  L4: Synthesis Layer      ← 最高峰キュレーション

  この提案を分解すると、3 種類の区別軸が混ざっています：

  ┌─────────────────────────┬──────────────────────────────────────┐
  │           軸            │           区別している対象           │
  ├─────────────────────────┼──────────────────────────────────────┤
  │ データ格納の物理位置    │ raw/ vs graph ledger vs wiki/        │
  ├─────────────────────────┼──────────────────────────────────────┤
  │ Edge の信頼状態         │ weak → candidate → stable → core     │
  ├─────────────────────────┼──────────────────────────────────────┤
  │ Wiki ディレクトリの種類 │ concepts / methods / synthesis / ... │
  └─────────────────────────┴──────────────────────────────────────┘

  これらを全部「層」という言葉で表現したため、冗長な 5 層になっていました。

  ---
  2. 本当に必要な architectural layer は何層か

  物理的に異なるストレージ・アクセスパターンで考える

  ┌──────────────┬──────────────────────┬─────────────────────────────────────┬────────────────────┐
  │      層      │       格納形式       │          アクセスパターン           │   誰が生成・更新   │
  ├──────────────┼──────────────────────┼─────────────────────────────────────┼────────────────────┤
  │ Raw          │ raw/**/*.md          │ immutable、append-only              │ 人間入力           │
  ├──────────────┼──────────────────────┼─────────────────────────────────────┼────────────────────┤
  │ Graph Ledger │ .rwiki/graph/*.jsonl │ 頻繁に update（events、confidence） │ LLM 抽出 + Hygiene │
  ├──────────────┼──────────────────────┼─────────────────────────────────────┼────────────────────┤
  │ Wiki         │ wiki/**/*.md         │ 編集あり、human-curated             │ 人間承認           │
  └──────────────┴──────────────────────┴─────────────────────────────────────┴────────────────────┘

  architectural layer は 3 つ。これ以上は 層ではなく属性で表現すべき。

  状態属性（層ではない）

  - Edge status: weak / candidate / stable / core / deprecated / rejected
  - Page status: active / deprecated / retracted / archived（既存 v2 合意済）
  - Wiki subdirectory: concepts/ vs methods/ vs synthesis/（意味的分類、層ではない）

  ---
  3. 3 層アーキテクチャに整理し直す

  新提案: 3 層 + 属性

  ┌──────────────────────────────────────────────────┐
  │ Layer 1: Raw                                      │
  │   raw/**/*.md                                      │
  │   人間入力、evidence 源                             │
  └──────────────────────────────────────────────────┘
            ↓ （LLM 自動抽出）
  ┌──────────────────────────────────────────────────┐
  │ Layer 2: Graph Ledger                             │
  │   .rwiki/graph/                                    │
  │     entities.yaml                                  │
  │     edges.jsonl                                    │
  │     edge_events.jsonl                              │
  │     evidence.jsonl                                 │
  │                                                    │
  │   各 edge に status:                                │
  │     weak / candidate / stable / core /             │
  │     deprecated / rejected                          │
  │                                                    │
  │   Graph Hygiene が confidence を進化させる           │
  └──────────────────────────────────────────────────┘
            ↓ （人間承認、明示的な curation）
  ┌──────────────────────────────────────────────────┐
  │ Layer 3: Curated Wiki                              │
  │   wiki/concepts/, methods/, projects/,             │
  │       entities/people/, entities/tools/,           │
  │       synthesis/                                    │
  │                                                    │
  │   markdown + frontmatter                            │
  │   frontmatter status: active/deprecated/…          │
  │   synthesis/ は「より慎重な approve」の          │
  │   subdirectory であり、層ではなく subset           │
  └──────────────────────────────────────────────────┘

  Review はどこに行った？

  review/*_candidates/ は Layer 2 と Layer 3 の間の「承認待ち buffer」。独立した層というより、Layer 3 への昇格ゲート。

  Data flow で表現：

  Raw (L1) ─LLM extract─→ Ledger (L2: candidate edges)
                            ↓ Hygiene で進化
                          Ledger (L2: stable / core)
                            ↓ 人間が明示的に wiki ページ化したい時
                          review/ (承認 buffer)
                            ↓ approve
                          Wiki (L3)

  ---
  4. 「Synthesis を別層にしたい」誘惑への対処

  前回 L4 として synthesis を独立層扱いにしたのは、Scenario 16（query → synthesis 昇格）で「最高ランク dangerous
  op」としたから。これは魅力的だが、architectural に separate layer を作るほどではない。

  代替案: wiki/synthesis/ は subdirectory + 強い承認要件

  - Layer は 3 つのまま
  - wiki/synthesis/ は他の wiki subdirectory と同じ物理格納
  - ただし 昇格時の承認フローが 8 段階必須（Scenario 16 ですでに合意済）
  - これは「層の違い」ではなく「wiki 内での subdirectory ごとの運用ルール」

  これなら synthesis の特別扱いは運用則で表現でき、architectural に余分な層を設けなくて済む。

  ---
  5. 3 層モデルでの各要素の位置付け

  ┌────────────────────────────────────────────────┬────────────────────────────────────────────────────┐
  │                  既存 v2 要素                  │                    どの layer?                     │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ raw/**/*.md                                    │ L1 Raw                                             │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ raw/llm_logs/                                  │ L1 Raw（特殊扱い）                                 │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ .rwiki/graph/*.jsonl                           │ L2 Graph Ledger（新規追加）                        │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ .rwiki/cache/*.sqlite                          │ L2 derived cache                                   │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ review/synthesis_candidates/                   │ L2 → L3 昇格 buffer                                │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ review/query/                                  │ L2 → L3 昇格 buffer（query artifact）              │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ review/hypothesis_candidates/                  │ L2 → L3 昇格 buffer                                │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ review/perspectives/                           │ L2 出力の明示保存                                  │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ review/skill_candidates/                       │ AGENTS/ への昇格 buffer                            │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ review/vocabulary_candidates/                  │ vocabulary 更新 buffer                             │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ wiki/concepts/, methods/, projects/, entities/ │ L3 Curated Wiki                                    │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ wiki/synthesis/                                │ L3 Curated Wiki（特別な承認則付きの subdirectory） │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ wiki/.follow-ups/                              │ L3 Curated Wiki（作業記録）                        │
  ├────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ AGENTS/skills/                                 │ Meta（運用ツール）                                 │
  └────────────────────────────────────────────────┴────────────────────────────────────────────────────┘

  整然と分類できます。

  ---
  6. 既存 v2 との対応は維持される

  既存で合意した承認ゲート（L3 進入時）

  - Scenario 11: deprecate / retract / archive の 8 段階対話 → L3 内部のページ状態変更（status frontmatter）
  - Scenario 16: query → synthesis 昇格 → L2/review から L3 wiki/synthesis/ への最高ランク昇格
  - Scenario 7: 既存 wiki 拡張 → L3 内部の変更（差分マーカー経由）
  - Scenario 8: merge → L2 内 merge（review candidate 統合）or L3 内 merge（wiki 統合）

  新議論の「auto-accept」は L2 内で完結

  - L2 Graph Ledger 内で confidence 閾値で candidate → stable への自動遷移
  - Hygiene 進化則は L2 内で動く
  - 人間の reject は L2 の reject_queue で処理
  - L3（wiki/）への昇格には従来通り approve が必要

  つまり 「人間承認は L2→L3 の gate で維持」、「L1→L2 の flow は自動化」。

  ---
  7. 言葉の整理

  前回「L0 〜 L4」と書いたのを、L1 〜 L3 に改める：

  ┌──────────────────────────────────────┬───────────────────────────────────────────────────┐
  │               前回提案               │                    今回の整理                     │
  ├──────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ L0 Raw                               │ Layer 1: Raw                                      │
  ├──────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ L1 Candidate Graph + L2 Stable Graph │ Layer 2: Graph Ledger（中に edge status で区別）  │
  ├──────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ L3 Curated Wiki + L4 Synthesis       │ Layer 3: Curated Wiki（中に subdirectory で区別） │
  └──────────────────────────────────────┴───────────────────────────────────────────────────┘

  5 層 → 3 層に整理。機能は何も削減していない（状態属性で表現しているだけ）。

  ---
  8. なぜ 3 層が「ちょうど良い」か

  2 層は不足

  「Raw + Wiki」の 2 層だと：
  - 中間の Graph Ledger 概念が消える
  - Candidate edges の居場所がない
  - Hygiene の対象が明確でない
  - 新議論の「evidence-backed candidate graph」が表現できない

  4+ 層は過剰

  - status 属性で表現できるものを層として分離している
  - Wiki subdirectory の区別を architectural layer にする必要はない
  - Review 等の buffer を独立層にすると flow が混乱

  3 層が自然

  - 物理的格納パターンの差が明確に 3 つ（raw, graph ledger, wiki）
  - アクセスパターンの差も 3 通り（read-only, frequent update, curated read-write）
  - 人間関与のタイミングも 3 段階（入力、reject filter、approve）

  ---
  9. 確認事項

  3 層アーキテクチャ（Raw / Graph Ledger / Curated Wiki）で整理し直すことに合意できますか？

  - Layer 1: Raw = raw/**/*.md（既存）
  - Layer 2: Graph Ledger = .rwiki/graph/*.jsonl（新規、Scenario 14/Spec 5 の核心）、内部に edge status で区別
  - Layer 3: Curated Wiki = wiki/**/*.md（既存、synthesis は subdirectory + 強承認則）

  これに合意できれば：
  - consolidated-spec § アーキテクチャ概観を 3 層で書き直す
  - Spec 5 の Graph Ledger 設計を詰める（edge status、Hygiene、confidence、events）
  - 既存 14-16 シナリオは影響なし（synthesis は subdirectory のまま）

  Scenario 33 の「L3 は LLM ガイド」の考え方も、L2 の Hygiene 運用として自然に取り込めます。
~~~



~~~
❯ 3層を承諾。これに伴い、他の項目も修正の影響を受けるか

⏺ はい、多くの項目が影響を受けます。変更の影響度で分類して整理します。

  ---
  1. 影響度マトリクス

  ┌──────────────────────────────────────────┬─────────────────┬─────────────────────────────────────────────────────────┐
  │                   項目                   │     影響度      │                          理由                           │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 5 (knowledge-graph)                 │ 🔴 大改訂       │ Ledger モデル、confidence、Hygiene、events が中核に     │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 0 (foundation) §2.11                │ 🔴 改訂         │ L2 edge 管理まで LLM guide の範囲を拡張                 │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 0 (foundation) § アーキテクチャ概観 │ 🔴 全面書き直し │ 3 層の明示、Graph Ledger の位置付け                     │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 6 (perspective-generation)          │ 🟡 強化         │ L2 の candidate edges / missing bridges を活用          │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 7 (lifecycle-management)            │ 🟡 拡張         │ Page lifecycle に加え Edge lifecycle を追加             │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 2 (skill-library)                   │ 🟡 拡張         │ Relation extraction skill、edge ledger 出力を扱う skill │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 1 (classification-system)           │ 🟡 修正         │ frontmatter related: の位置付け変更（derived cache）    │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 4 (cli-mode-unification)            │ 🟡 追加         │ 新コマンド群（graph, hygiene, reject, etc.）            │
  ├──────────────────────────────────────────┼─────────────────┼─────────────────────────────────────────────────────────┤
  │ Spec 3 (prompt-dispatch)                 │ 🟢 軽微         │ 基本維持、ledger を context として使える拡張            │
  └──────────────────────────────────────────┴─────────────────┴─────────────────────────────────────────────────────────┘

  ---
  2. シナリオへの影響

  🔴 大きく変わる / 新設

  ┌───────────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────┐
  │               シナリオ                │                                             変更内容                                              │
  ├───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Scenario 14（perspective/hypothesis） │ Graph traverse を L2 ledger 対象に。Hypothesis は「L2 candidate edges + missing bridges」から生成 │
  ├───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Scenario 10（audit ERROR）            │ L3 page ERROR に加え、L2 edge consistency（矛盾、確信度低下）も対象に                             │
  ├───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Scenario 13（evidence 検証）          │ L2 の evidence.jsonl が first-class concept に、URL 生存確認も ledger 側で管理                    │
  ├───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Scenario 18（pre-flight check）       │ Page state + edge state の両方を pre-flight で確認                                                │
  ├───────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Scenario 33（Maintenance UX）         │ L2 edge reject queue、Hygiene ステータス、autonomous edge proposals を追加                        │
  └───────────────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────┘

  🟢 変わらない（L3 内のまま）

  ┌──────────────────────────────────────────┬────────────────────────────────────────────────────┐
  │                 シナリオ                 │                        理由                        │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 7（extend wiki）                │ L3 内部の page 変更、差分マーカー方式そのまま      │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 8（merge）                      │ L3 内部 + review/ の処理、そのまま                 │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 9（split）                      │ L3 内部、そのまま                                  │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 11（deprecate/archive/retract） │ L3 page lifecycle、そのまま                        │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 12（tag vocabulary）            │ L3 tags、そのまま（ただし edge tags への派生あり） │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 15（interactive_synthesis）     │ raw + user 対話 → review/ → L3、そのまま           │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 16（query → synthesis 昇格）    │ review/ → L3 wiki/synthesis/、最高ランクガード維持 │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 17（daily note）                │ L1 Raw、エディタ委譲、そのまま                     │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 19（unapprove）                 │ L3 page rollback、そのまま                         │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 20（custom skill）              │ Meta（AGENTS/）、そのまま                          │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 25（llm_log_extract）           │ L1 → review/ → L3、そのまま                        │
  ├──────────────────────────────────────────┼────────────────────────────────────────────────────┤
  │ Scenario 26（lint-fail recovery）        │ L0 → L1 ingest flow、そのまま                      │
  └──────────────────────────────────────────┴────────────────────────────────────────────────────┘

  🆕 新規追加が必要なシナリオ

  ┌───────────────────────────────────────┬────────────────────────────────────────────────────────────┐
  │              新 Scenario              │                            主題                            │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────┤
  │ Scenario 34: Entity/Relation 自動抽出 │ rw extract-relations、L1 raw から L2 ledger へ             │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────┤
  │ Scenario 35: Edge reject workflow     │ Candidate edges の dashboard/CLI での reject               │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────┤
  │ Scenario 36: Graph Hygiene 実行       │ decay/competition/merge の定期バッチ、status 確認          │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────┤
  │ Scenario 37: Edge lifecycle 管理      │ Edge status 遷移（candidate → stable → core → deprecated） │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────┤
  │ Scenario 38: Edge events 監査         │ edge_events.jsonl による confidence 変遷の調査             │
  └───────────────────────────────────────┴────────────────────────────────────────────────────────────┘

  ---
  3. 新 Vocabulary（用語集に追加）

  ┌───────────────────────┬─────────────────────────────────────────────────────────────────────────────────┐
  │         用語          │                                      定義                                       │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Graph Ledger          │ L2 層の JSONL ベース edge/entity/evidence/events 管理基盤                       │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Edge status           │ weak / candidate / stable / core / deprecated / rejected                        │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Confidence            │ Evidence-backed trust score（LLM の自信ではない）                               │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Edge event            │ confidence 変更の時系列記録（used_in_query, decay, human_reject 等）            │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Hygiene               │ Graph の進化則（decay / reinforcement / competition / contradiction / merging） │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Usage signal          │ query 時の推論貢献度 × 独立性 × 時間減衰                                        │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Reject queue          │ 人間が reject を判断する candidate edges の待機所                               │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Evidence ledger       │ evidence.jsonl、edge の根拠引用集（first-class concept）                        │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Auto-accept threshold │ confidence ≥ 閾値（例: 0.75）で candidate → stable に自動昇格                   │
  ├───────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Core edge             │ 頻繁に使われる graph の骨格 edge（status の最高）                               │
  └───────────────────────┴─────────────────────────────────────────────────────────────────────────────────┘

  既存用語との整理：
  - Typed edges（既存） = 主に L2 の stable/core edges、 frontmatter related: で cache される
  - Related（既存 frontmatter）= L3 page の derived view、L2 ledger からのエクスポート
  - Status（既存）= Page status と Edge status の 2 種類が存在（明確に区別）

  ---
  4. コマンド追加・変更

  新規コマンド（Scenario 33 の L3 扱い = LLM ガイド対象）

  # Graph 管理
  rw graph rebuild                       # ledger から SQLite cache 再生成
  rw graph status                        # 統計表示（edge 数、confidence 分布、status 別件数）
  rw graph hygiene                       # decay/competition/merge 実行
  rw graph hygiene --dry-run             # 適用なし、影響のみ表示

  # Edge 個別操作
  rw edge show <edge-id>                 # edge 詳細 + events 履歴
  rw edge promote <edge-id>              # candidate → stable 手動昇格
  rw edge demote <edge-id>               # 下方修正
  rw edge history <edge-id>              # events の時系列

  # Reject flow
  rw reject                              # reject queue を対話的に処理
  rw reject <edge-id>                    # 特定 edge を reject
  rw reject --auto-batch                 # 低 confidence (< 0.2) を一括 reject 候補に

  # Entity/Relation 抽出
  rw extract-relations <page>            # 特定ページから
  rw extract-relations --all             # wiki 全体
  rw extract-relations --since "7 days"  # 直近更新分

  既存コマンドの拡張

  rw audit graph                         # edge consistency（新、Scenario 10 拡張）
  rw audit evidence                      # evidence.jsonl の URL 生存確認（Scenario 13 拡張）
  rw verify <hypothesis-id>              # 内部で L2 edge 検索 + confidence 強化
  rw perspective "<topic>"               # L2 ledger を traverse（精度向上）
  rw hypothesize "<topic>"               # L2 missing bridges を発見源に

  ---
  5. .rwiki/ と Vault 構造の変更

  Before（既存 v2 draft）

  <vault>/
  ├── raw/ wiki/ review/ AGENTS/ logs/
  └── .rwiki/
      ├── vocabulary/
      │   ├── tags.yml
      │   └── relations.yml
      └── graph/
          ├── index.db
          └── ...

  After（3 層統合版）

  <vault>/
  ├── raw/                              # L1 Raw（既存）
  ├── review/                           # L2 ↔ L3 buffer（既存）
  ├── wiki/                             # L3 Curated（既存）
  ├── AGENTS/ logs/
  └── .rwiki/
      ├── vocabulary/                   # 既存
      │   ├── tags.yml
      │   ├── relations.yml
      │   └── entity_types.yml
      ├── graph/                        # L2 Graph Ledger（拡張）
      │   ├── entities.yaml             # 新
      │   ├── edges.jsonl               # 新、L2 の source of truth
      │   ├── edge_events.jsonl         # 新、confidence 変遷
      │   ├── evidence.jsonl            # 新、first-class evidence
      │   ├── rejected_edges.jsonl      # 新、reject 履歴
      │   └── reject_queue/             # 新、人間判断待ち
      ├── cache/                        # derived、gitignore
      │   ├── graph.sqlite
      │   └── network.pkl               # networkx pickle（optional）
      └── config.yml                    # 設定（閾値、decay rate 等）

  Git 管理方針変更:
  - .rwiki/graph/*.jsonl: git 管理（decay 履歴は reproducible でない、ledger は資産）
  - .rwiki/cache/: gitignore（再生成可能）

  ---
  6. frontmatter スキーマへの影響

  Page frontmatter（L3 wiki/）

  related: の位置付けが変わる：

  Before:
  related:
    - target: wiki/methods/sindy.md
      relation: similar_approach_to
  これが primary（人間が書く、audit で検査）。

  After:
  # 基本は derived（Graph Ledger の stable/core edges から生成される）
  related:
    - target: wiki/methods/sindy.md
      relation: similar_approach_to
      # edge_id: e_042  (optional、ledger への逆参照)
  これは human-readable cache。正本は .rwiki/graph/edges.jsonl。

  運用:
  - ユーザーは frontmatter に手書きしてもよい（その場合 ledger に反映）
  - Ledger が primary source、frontmatter は表示用 snapshot
  - 両者のズレは rw audit graph --sync で検出・修復

  Edge frontmatter（L2 ledger の 1 行）

  {
    "edge_id": "e_042",
    "source": "wiki/methods/sindy.md",
    "type": "similar_approach_to",
    "target": "wiki/methods/dmd.md",
    "confidence": 0.82,
    "status": "stable",
    "evidence_ids": ["ev_001", "ev_007"],
    "extraction_mode": "explicit",
    "created_at": "2026-04-24T15:30:00",
    "updated_at": "2026-04-28T10:00:00",
    "source_file": "raw/papers/local/brunton-2024.md"
  }

  これが新しい「edge」の完全な表現。

  ---
  7. ドキュメント（docs/）への影響

  ┌───────────────────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────┐
  │         ドキュメント          │                                             変更                                             │
  ├───────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
  │ user-guide.md                 │ 3 層アーキテクチャの説明追加、L2 edge 管理の UX（reject flow）を明記                         │
  ├───────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
  │ developer-guide.md            │ Graph Ledger 実装詳細、Hygiene rules、confidence 計算、events 処理                           │
  ├───────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
  │ karpathy-comparison.md        │ Rwiki = "Evidence-backed Evolutionary Graph" という位置付け強化（Curated GraphRAG の発展形） │
  ├───────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
  │ rwiki-v2-consolidated-spec.md │ §3（アーキテクチャ）全面書き直し、§2.11 拡張、Spec 5 大改訂                                  │
  ├───────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────┤
  │ rwiki-v2-scenarios.md         │ 新 5 シナリオ（34-38）追加、既存 Scenario 14 の大幅強化                                      │
  └───────────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────┘

  ---
  8. 実装 Phase への影響（§9.4 の実装順序を再計算）

  Before（Draft v0.6）

  Spec 0 → 1 → 2 + 5 (knowledge-graph) → 3 → 4 → 7 → 6

  After（3 層対応版）

  Spec 0（foundation、3 層原則）
    ↓
  Spec 1（classification、frontmatter の役割見直し）
    ↓
  Spec 5（knowledge-graph）【Phase 5a: 基礎 Ledger + SQLite cache】
    ↓
  Spec 2（skill-library、relation extraction skill 追加）
    ↓
  Spec 5 【Phase 5b: Hygiene + events + confidence 進化】
    ↓
  Spec 3（prompt-dispatch）
    ↓
  Spec 4（cli-mode-unification、graph / edge / reject コマンド追加）
    ↓
  Spec 7（lifecycle-management、edge lifecycle 統合）
    ↓
  Spec 6（perspective + hypothesis、L2 ledger 活用の本丸）

  Spec 5 を 2 phase に分割するのが最も大きな変更。Phase 5a で基礎を作り、他の Spec が進行してから Phase 5b の Hygiene を実装する方が現実的。

  期間見積もり（Draft v0.6 → 新計画）:

  ┌─────────┬─────────────────────────────────────┬─────────────────────────────────┐
  │  Phase  │                作業                 │              期間               │
  ├─────────┼─────────────────────────────────────┼─────────────────────────────────┤
  │ Phase 0 │ 全 spec の requirements 起草 + 承認 │ 4-6 日（3 日増）                │
  ├─────────┼─────────────────────────────────────┼─────────────────────────────────┤
  │ Phase 1 │ design + tasks                      │ 4-6 日                          │
  ├─────────┼─────────────────────────────────────┼─────────────────────────────────┤
  │ Phase 2 │ autonomous 実装                     │ 12-18 日（Graph Ledger が重い） │
  ├─────────┼─────────────────────────────────────┼─────────────────────────────────┤
  │ Phase 3 │ docs / steering                     │ 2 日                            │
  └─────────┴─────────────────────────────────────┴─────────────────────────────────┘

  合計: 3-4 週間規模（従来の 2-3 週間から拡大）。

  ---
  9. 現実的な統合戦略の提案

  新議論の内容は重いですが、段階的導入が可能です：

  Stage 1（MVP、必須）

  - 3 層アーキテクチャの明文化（Spec 0, Spec 5）
  - Graph Ledger の基礎（edges.jsonl + SQLite cache）
  - Frontmatter related: は ledger との sync 機構

  Stage 2（MVP+1、推奨）

  - Entity/Relation 自動抽出（rw extract-relations）
  - Confidence scoring（初期値のみ、update なし）
  - Evidence ledger（evidence.jsonl）

  Stage 3（Post-MVP、進化）

  - Hygiene rules（decay / reinforcement / competition）
  - Usage signal from query
  - Edge events 完全実装

  Stage 4（Mature）

  - Contradiction tracking
  - Merging consolidation
  - Autonomous maintenance UI

  MVP では Stage 1 + Stage 2 の一部で、「evidence-backed candidate graph の台帳」として動かし、Hygiene の進化則は運用開始後に段階実装が現実的。

  ---
  10. 確認事項

  1. 影響範囲の認識

  Spec 0, 1, 2, 4, 5, 6, 7 すべてが影響を受け、Spec 5 は大改訂。この大きな変更に取り組むことで合意できますか？

  2. 段階的実装

  MVP では Stage 1 + Stage 2 の一部（基礎 Ledger + Evidence + 初期 confidence）、Hygiene は Post-MVP、で OK ですか？

  3. Vocabulary 区別

  - Edge status （weak/candidate/stable/core/deprecated/rejected）
  - Page status（active/deprecated/retracted/archived、既存）

  この 2 種類を明確に区別して運用することで OK ですか？

  4. Frontmatter の位置付け変更

  wiki/*.md の frontmatter related: は derived cache（Ledger が source of truth）。両者の sync は audit で管理。

  これで OK ですか？

  5. 新シナリオ追加（Scenario 34-38）

  - 34: Entity/Relation 自動抽出
  - 35: Edge reject workflow
  - 36: Graph Hygiene 実行
  - 37: Edge lifecycle 管理
  - 38: Edge events 監査

  これらの新シナリオを Scenarios v0.7 に追加することで OK ですか？

  6. Git 管理方針

  .rwiki/graph/*.jsonl を git 管理（ledger は資産、decay 履歴は reproducible でない）。.rwiki/cache/ は gitignore。

  これで OK ですか？

  ---
  合意できれば、両 Draft（consolidated-spec v0.7 / scenarios v0.7）を大幅改訂します。特に Spec 5 の書き直しと新 Scenario 34-38 の追加が主作業。

  どう判断しますか？
  
❯ 2以外はOK.まず、全仕様を確定し、cc-sddを使い、仕様駆動開発を行う。


⏺ 承諾事項を確定し、次のアクションを計画します。

  ---
  1. 決定事項の確認

  ┌───────────────────────────┬───────────────────────────────────────────────────────────────────┐
  │           項目            │                               決定                                │
  ├───────────────────────────┼───────────────────────────────────────────────────────────────────┤
  │ #1 影響範囲の認識         │ OK — Spec 0/1/2/4/5/6/7 を更新、Spec 5 は大改訂                   │
  ├───────────────────────────┼───────────────────────────────────────────────────────────────────┤
  │ #2 段階的実装             │ 変更 — 全仕様を先に確定、cc-sdd で仕様駆動開発                    │
  ├───────────────────────────┼───────────────────────────────────────────────────────────────────┤
  │ #3 Vocabulary 区別        │ OK — Edge status / Page status を明確に区別                       │
  ├───────────────────────────┼───────────────────────────────────────────────────────────────────┤
  │ #4 Frontmatter の位置付け │ OK — related: は derived cache、Ledger が source of truth         │
  ├───────────────────────────┼───────────────────────────────────────────────────────────────────┤
  │ #5 新シナリオ 34-38       │ OK — Scenarios v0.7 に追加                                        │
  ├───────────────────────────┼───────────────────────────────────────────────────────────────────┤
  │ #6 Git 管理方針           │ OK — .rwiki/graph/*.jsonl は git 管理、.rwiki/cache/ は gitignore │
  └───────────────────────────┴───────────────────────────────────────────────────────────────────┘

  #2 の変更がもたらす意味

  「MVP → 段階的」ではなく「Full spec → 実装」へ：

  - Hygiene、events、confidence evolution をすべて仕様化してから実装
  - cc-sdd（kiro-spec-*）を使って、仕様から tasks を自動生成
  - これにより「仕様と実装の乖離」を防ぐ
  - 仕様策定に時間がかかるが、実装は体系的に進む

  ---
  2. 「全仕様を確定」するための作業一覧

  A. 既存ドラフトの v0.7 化（consolidated-spec + scenarios）

  consolidated-spec.md v0.7 で追加・書き直し:

  1. §3 アーキテクチャ概観を 3 層モデルで全面書き直し
  2. §2.11 をL2 edge management まで拡張
  3. 新 §4.x: Graph Ledger 詳細（ファイル構造、JSONL フォーマット）
  4. 用語集（§4）に Edge status / Confidence / Hygiene / Usage signal / Edge events / Evidence ledger 等を追加
  5. Vault 構造図の更新（.rwiki/graph/ 詳細）
  6. §5 Frontmatter スキーマ更新（related: を derived に）
  7. §6 Task & Command: 新コマンド追加（graph / edge / reject / extract-relations / hygiene）
  8. §7 Spec 群: Spec 5 を全面書き直し、他は差分更新
  9. §9 実装戦略: フルスクラッチ方針（段階的ではない）
  10. §11 改訂履歴に v0.7

  scenarios.md v0.7 で追加・書き直し:

  1. §1 ビジョン: 3 層アーキテクチャ追加
  2. §2 シナリオ分類表: 新 34-38 追加、14/10/13/18/33 の状態更新
  3. Scenario 14: L2 candidate edges + missing bridges 活用に全面強化
  4. Scenario 10: edge consistency を統合
  5. Scenario 13: evidence.jsonl first-class として強化
  6. Scenario 18: edge state も pre-flight 対象
  7. Scenario 33: reject queue / Hygiene status / autonomous edge proposals 拡張
  8. 新 Scenario 34-38 を詳細追加

  B. 未議論シナリオの詳細化

  まだ未議論または詳細不十分のシナリオ：

  ┌─────────────┬───────────────────────────┬─────────────────────────────────────────────────┐
  │  シナリオ   │           状態            │                    議論内容                     │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 9  │ 未議論                    │ wiki ページ分割（既に scenarios.md に概要あり） │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 10 │ 未議論（+ edge 統合）     │ audit ERROR 修正ループ + edge consistency       │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 13 │ 未議論（+ evidence 統合） │ Evidence 検証 + dead-link + ledger evidence     │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 18 │ 未議論                    │ Pre-flight check（+ edge state）                │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 26 │ 未議論                    │ Incoming lint-fail リカバリ                     │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 34 │ 新規、未議論              │ Entity/Relation 自動抽出                        │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 35 │ 新規、未議論              │ Edge reject workflow                            │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 36 │ 新規、未議論              │ Graph Hygiene 実行                              │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 37 │ 新規、未議論              │ Edge lifecycle 管理                             │
  ├─────────────┼───────────────────────────┼─────────────────────────────────────────────────┤
  │ Scenario 38 │ 新規、未議論              │ Edge events 監査                                │
  └─────────────┴───────────────────────────┴─────────────────────────────────────────────────┘

  合計 10 シナリオの詳細化が必要。

  C. cc-sdd による Spec 起票

  両ドラフト確定後、以下の順に /kiro-spec-init から始める：

  Spec 0: rwiki-v2-foundation
  Spec 1: classification-system
  Spec 5: knowledge-graph            ← 並行、重要度高
  Spec 2: skill-library
  Spec 3: prompt-dispatch
  Spec 4: cli-mode-unification
  Spec 7: lifecycle-management
  Spec 6: perspective-generation     ← 本丸、最後

  各 Spec で /kiro-spec-requirements → /kiro-validate-gap（optional）→ /kiro-spec-design → /kiro-validate-design（optional）→ /kiro-spec-tasks。

  D. cc-sdd による実装

  /kiro-impl <spec-name> で autonomous 実装。8 Spec 分。

  ---
  3. 提案する進め方

  Step 1（次のアクション）: Draft v0.7 への更新

  両ドラフトを v0.7 に更新する作業を着手。影響が大きい順に：

  1. consolidated-spec.md v0.7 — §3 アーキテクチャ、Spec 5 書き直し（最優先）
  2. scenarios.md v0.7 — Scenario 14 強化、Scenario 34-38 新設

  この Step だけで数時間の作業量。

  Step 2: 残り未議論シナリオ 10 件の議論

  - 簡単なもの（9, 18, 26）は 1-2 交換で詰められる
  - 複雑なもの（10, 13, 34-38）は 5-10 交換必要
  - 合計で議論 30-50 往復見込み

  Step 3: Spec ごとの kiro-spec-* 実行

  完成した両ドラフトを input として、各 Spec の requirements → design → tasks を起票。

  Step 4: kiro-impl で autonomous 実装

  Spec 順次実装。

  ---
  4. 推奨する次のアクション

  Step 1（Draft v0.7 化）から始めるのが自然です。理由：

  - 既存の合意内容を 3 層モデルで整理しないと、未議論シナリオの土台が定まらない
  - 特に Scenario 14 と Scenario 34-38 は L2 Graph Ledger の仕様を前提にする
  - Draft の全体像が見える状態で個別シナリオ議論を進めた方が整合性が取れる

  Step 1 の着手順（提案）

  1. consolidated-spec §3 アーキテクチャ概観 を 3 層で全面書き直し（3 層の物理構造、データフロー、格納形式）
  2. Spec 5 (knowledge-graph) を大改訂（Graph Ledger、confidence、Hygiene、events、Reject）
  3. §2.11 と §2.12 新設（edge management、Hygiene 運用）
  4. 用語集（§4）追加（Edge status、Hygiene、Usage signal 等）
  5. scenarios.md: Scenario 14 を L2 対応に強化、Scenario 33 を Hygiene 追記
  6. Scenario 34-38 の初期記述（骨子のみ、詳細は Step 2 で）

  Step 1 完了後に Step 2（残りシナリオ議論）に進む。

  ---
  確認事項

  1. この進め方（Step 1 → 2 → 3 → 4）で OK ですか？

  2. Step 1 を今から着手しますか？ それとも他の準備を先に？

  3. Step 1 の作業量は数時間見込みです。一気に進めますか、あるいはセクションごとに確認しながら進めますか？

  ---
  承諾いただければ、すぐに Step 1（consolidated-spec.md の §3 アーキテクチャ書き直し + Spec 5 改訂）から着手します。
~~~

