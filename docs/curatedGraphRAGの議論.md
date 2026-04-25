# Curated graph RAG



~~~
❯ 知識発見の過程でエンティティの関係性をどのように実装するのか？

  1. Entity 固有の関係型（authored_by / collaborated_with / critiqued 等）
  2. Relationship の storage 形式（frontmatter のみ vs 別ファイル）
  3. Relationship 抽出メカニズム（手動 vs LLM 自動 vs ハイブリッド）
  4. 方向性の扱い（directional / symmetric / 両方向記録）
  5. Discovery での利用（Perspective / Hypothesis / Query で relation type をどう活用）
  を検討
  
  
  
❯ 具体的なグラフの実装はどうする
  選択肢 C: ハイブリッド（source = markdown、derived index = SQLite）

  Source of truth は markdown、SQLite index は derived（再生成可能）

  ┌──────────┬─────────────────────────────────────┐
  │   観点   │                評価                 │
  ├──────────┼─────────────────────────────────────┤
  │ 実装     │ ○ 中程度、invalidation 単純化可     │
  ├──────────┼─────────────────────────────────────┤
  │ 起動時間 │ ◎ index 利用で即時                  │
  ├──────────┼─────────────────────────────────────┤
  │ スケール │ ◎ SQLite で数万ノード               │
  ├──────────┼─────────────────────────────────────┤
  │ 一貫性   │ ○ stale detection + auto rebuild    │
  ├──────────┼─────────────────────────────────────┤
  │ 外部依存 │ ◎ sqlite3（標準）                   │
  ├──────────┼─────────────────────────────────────┤
  │ Git 管理 │ ◎ markdown だけ、index は gitignore │
  └──────────┴─────────────────────────────────────┘

  推奨: 選択肢 C（ハイブリッド）
  
  7. 他選択肢（neo4j 等）を避ける理由
┌────────────────────────┬──────────────────────────────────────────────────────┐
  │      検討した代替      │                       却下理由                       │
  ├────────────────────────┼──────────────────────────────────────────────────────┤
  │ neo4j / dgraph         │ 重い、外部 DB 依存、Rwiki のゼロ外部依存原則に反する │
  ├────────────────────────┼──────────────────────────────────────────────────────┤
  │ networkx（メモリ）のみ │ 持続性なし、毎回 rebuild で遅い                      │
  ├────────────────────────┼──────────────────────────────────────────────────────┤
  │ RDF / Turtle           │ 過剰な形式、markdown との親和性低い                  │
  ├────────────────────────┼──────────────────────────────────────────────────────┤
  │ Obsidian graph cache   │ API 安定性なし、Obsidian 前提に反する                │
  └────────────────────────┴──────────────────────────────────────────────────────┘

  SQLite が最適解。Python 標準、ACID、Git でも管理可能（optional）、スケーラブル。



❯ grapRAGを使うアイデアはないか？
⏺ 良い着眼点です。GraphRAG（Microsoft）は Rwikiと関連する技術ですが、哲学的に異なる部分もあります。取り入れる要素と避ける要素を整理します。

  1. GraphRAG とは何か

  Microsoft の GraphRAG は、通常の vector RAG を拡張した「graph-augmented retrieval」：

  ┌─────────────────────────┬─────────────────────────────────────────────────────────────┐
  │          段階           │                            挙動                             │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ 1. Entity/Relation 抽出 │ LLM が未キュレート corpus からエンティティ・関係を自動抽出  │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ 2. Graph 構築           │ 抽出結果を graph として格納                                 │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ 3. Community 検出       │ Leiden 等のアルゴリズムで cluster 発見                      │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ 4. 階層的要約           │ 各 community を LLM で要約、階層的に集約                    │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ 5. Query 応答           │ Local query（特定エンティティ）/ Global query（全体テーマ） │
  └─────────────────────────┴─────────────────────────────────────────────────────────────┘

  主要革新：
  - Vector 類似度を超えた構造的理解
  - Global query（「この corpus の主要テーマは？」）が可能
  - 多文書を横断する推論

  ---
  2. Rwiki との哲学的差分

┌─────────────────┬────────────────────────────────────┬──────────────────────────────────────────────┐
  │       軸        │              GraphRAG              │                    Rwiki                     │
  ├─────────────────┼────────────────────────────────────┼──────────────────────────────────────────────┤
  │ 入力            │ 未キュレート corpus（PDF、web 等） │ 人間承認済み wiki                            │
  ├─────────────────┼────────────────────────────────────┼──────────────────────────────────────────────┤
  │ Graph 構築      │ 完全自動（LLM 抽出）               │ 人間承認 + LLM 提案（Scenario 14 〜 Spec 5） │
  ├─────────────────┼────────────────────────────────────┼──────────────────────────────────────────────┤
  │ Entity/Relation │ 動的に見つける                     │ 構造化 frontmatter で明記                    │
  ├─────────────────┼────────────────────────────────────┼──────────────────────────────────────────────┤
  │ Summary         │ 自動で community ごと生成          │ wiki/synthesis/ は手動キュレーション         │
  ├─────────────────┼────────────────────────────────────┼──────────────────────────────────────────────┤
  │ Trust chain     │ 曖昧（LLM 推論に依存）             │ 厳格（approve gate + evidence chain）        │
  ├─────────────────┼────────────────────────────────────┼──────────────────────────────────────────────┤
  │ Trust の源      │ LLM 抽出の信頼性                   │ 人間承認                                     │
  └─────────────────┴────────────────────────────────────┴──────────────────────────────────────────────┘

  Rwiki が GraphRAG をそのまま採用できない理由

  1. 「人間承認を必須」原則と衝突: GraphRAG の自動 graph 構築は人間 gate を飛ばす
  2. Wiki はすでに構造化: 未キュレート corpus 前提の GraphRAG とは入力の質が違う
  3. 外部依存の原則: Microsoft GraphRAG library は Azure OpenAI 前提、Python 標準依存の Rwiki と合わない
  
  ---
  3. GraphRAG から取り入れられる技術要素

  ただし、個別の技術手法は Rwiki の機能強化に有効：

  要素 A: Entity / Relation 自動抽出のプロンプト設計

  GraphRAG はエンティティ・関係抽出の LLM プロンプト技法が洗練されている：

  - 2-stage extraction（first pass で広く、second pass で精緻化）
  - Gleaning（初回抽出 + 「他に抜けは？」で繰り返し）
  - Type-aware extraction（entity type ごとに異なるプロンプト）

  Rwiki への取り込み: Scenario 14 の rw extract-relations 実装で採用。

  rw extract-relations <wiki-page>
    → 内部で GraphRAG 風の 2-stage extraction + gleaning
    → review/relation_candidates/ に提案
    → 人間承認後に frontmatter へ反映

  重要: 自動抽出結果を直接 wiki に書かない。review レイヤー経由で承認ゲートを通す。

  要素 B: Community Detection（クラスタ発見）

  GraphRAG は Leiden アルゴリズムで community を検出。これは純粋な graph algorithm で、Python の networkx または graspologicで実装可能。

  Rwiki への取り込み: rw audit graph --communities（新機能）

  rw audit graph --communities
    # Leiden/Louvain で wiki graph を cluster 化
    # 結果: 孤立クラスタ、主要ハブ、bridge 候補を提示

  応用:
  - 孤立クラスタ検出: 他と繋がらないトピック群 → 統合または archive 候補
  - 主要 hub 特定: 多くのエッジを持つ中心ページ → synthesis 候補
  - Missing bridges: 共通近傍を持つが直接リンクなしのクラスタ対 → Hypothesis 生成のヒント

  これは現在の rw audit strategic（Tier 3 戦略的監査）をアルゴリズム的に強化する。

  要素 C: 階層的 summary（限定的採用）

  GraphRAG は community ごとに LLM summary を自動生成、階層化。

  Rwiki の原則と衝突する部分:
  - 自動 summary を wiki に常駐させるのは Trust chain 違反

  採用できる形:
  - Community summary を 一時的な perspective として提供（永続化しない）
  - ユーザーが価値を見出したら review を経て wiki/synthesis/ に昇格
  - つまり「自動生成 → stdout で提示 → 明示的 --save で永続化 → review → approve」のチェーン

  rw perspective "<topic>" --method graphrag-summary
    # wiki の特定クラスタを LLM で要約
    # 結果は stdout or review/perspectives/（--save 時）
    # 永続化は人間承認が前提（既存 Scenario 14 の流れ）

  要素 D: Global query サポート

  GraphRAG の global query（「corpus 全体のテーマは？」）は Rwiki でも有用：

  rw perspective --scope global
    # wiki 全体を俯瞰、主要テーマ・研究方向を surface
  rw perspective "この wiki で過剰に扱われているトピックは？" --scope global
  rw perspective "最近 approve された synthesis の傾向" --scope global

  実装:
  - Community detection で主要 cluster を特定
  - 各 cluster の代表ノード（hub）の title / frontmatter を LLM に渡す
  - 統合的な global perspective を生成

  これは Scenario 14 の Perspective generation の拡張。--scope <path> に加えて --scope global を追加。

  要素 E: Query-time graph-aware retrieval

  GraphRAG は vector search + graph expansion のハイブリッド検索。Rwiki は graph のみだが、graph traversal の戦略は参考になる：

  - Seed から 1-hop / 2-hop で広がる候補
  - Community 所属で絞り込み
  - Edge type の重要度で re-ranking

  Scenario 14 の Step 1-5 フロー（Graph-based retrieval + 段階的 loading）は基本的に GraphRAG と同じ構造だが、community
  情報も利用できるように拡張。
  
  ---
  4. 採用しないもの（明示的に却下）

  ┌─────────────────────────────────────┬────────────┬─────────────────────────────────────────┐
  │            GraphRAG 機能            │ Rwiki 採用 │                  理由                   │
  ├─────────────────────────────────────┼────────────┼─────────────────────────────────────────┤
  │ 自動 corpus 取込 → graph 構築       │ ✗          │ Rwiki は人間承認済み wiki が入力        │
  ├─────────────────────────────────────┼────────────┼─────────────────────────────────────────┤
  │ Embedding vector DB                 │ ✗          │ 「RAG ではない」原則、外部依存回避      │
  ├─────────────────────────────────────┼────────────┼─────────────────────────────────────────┤
  │ Azure OpenAI 依存のパイプライン     │ ✗          │ LLM CLI 抽象化（Claude/GPT 等どれでも） │
  ├─────────────────────────────────────┼────────────┼─────────────────────────────────────────┤
  │ Community summary を自動で永続化    │ ✗          │ Trust chain、wiki への書込は承認必須    │
  ├─────────────────────────────────────┼────────────┼─────────────────────────────────────────┤
  │ Microsoft GraphRAG library そのまま │ ✗          │ 重い、外部依存、必要以上                │
  └─────────────────────────────────────┴────────────┴─────────────────────────────────────────┘

  ---
  5. 推奨アーキテクチャ：Rwiki = SQLite graph + GraphRAG 技法

  Core infrastructure（前回の議論）

  - .rwiki/graph/index.db (SQLite)
  - Markdown frontmatter が source of truth
  - 外部依存は sqlite3 + networkx（Python 標準または軽量）

  GraphRAG 由来の機能拡張

  ┌──────────────────────────┬────────────────────────────────────────────────────┐
  │           機能           │                      実装方法                      │
  ├──────────────────────────┼────────────────────────────────────────────────────┤
  │ Entity/Relation 自動抽出 │ rw extract-relations で GraphRAG 風プロンプト採用  │
  ├──────────────────────────┼────────────────────────────────────────────────────┤
  │ Community detection      │ rw audit graph --communities、networkx ベース      │
  ├──────────────────────────┼────────────────────────────────────────────────────┤
  │ Global perspective       │ rw perspective --scope global                      │
  ├──────────────────────────┼────────────────────────────────────────────────────┤
  │ Missing bridge 検出      │ rw audit graph --find-bridges、Hypothesis の素材に │
  ├──────────────────────────┼────────────────────────────────────────────────────┤
  │ 階層 summary             │ perspective の拡張、review 層経由で永続化可        │
  └──────────────────────────┴────────────────────────────────────────────────────┘

  依存パッケージ

  - sqlite3 — Python 標準
  - networkx — Python の軽量 graph library（community detection 含む）

  # requirements.txt（想定）
  # Python 3.10+ 標準
  sqlite3       # built-in
  # 追加
  networkx>=3.0     # graph algorithms

  networkx は Python のデファクト graph library、軽量、純 Python。外部依存は最小限に保つ方針（§2.7 エディタ非依存、§1.4
  想定ツール）を尊重。
  
  ---
  7. 議論のポイント

  Pro GraphRAG（取り入れる）

  - Entity/Relation 抽出の精度向上: Rwiki の graph 構築を加速
  - Community 検出: audit strategic の強化
  - Global query: 現在の Perspective 単独では扱えない「corpus 全体」の問い
  - Missing bridge 発見: Hypothesis 生成の種
  - 実装コスト低: SQLite + networkx で必要機能を実装

  Against GraphRAG（避ける）

  - 自動化しすぎると Trust chain 破綻: 人間承認の意義を失う
  - External library（Microsoft GraphRAG）採用は重い: Azure 前提で不適合
  - Rwiki の本質は「curated wiki」: 未キュレート corpus 用の GraphRAG はオーバースペック

  結論

  「GraphRAG-inspired features、full adoption ではない」 という方針。Rwiki の core 原則（人間承認、trust
  chain、外部依存最小）を保ちつつ、GraphRAG の優れた技術要素（entity extraction、community detection、global query）を取り込む。
  
  
  
❯ graphRAGのグローバルクエリは有用。MSgraphRAGではなく、lightRAGは使えないか。また、graphRAGの適用先としてキュレーションされたデータを対象とするとどうか


  LightRAG の優れた設計思想（取り込み価値あり）

  1. Dual-level retrieval: 「具体的な質問」と「俯瞰的な質問」を同じ graph から別モードで処理 — Rwiki の Perspective (local) と global query
  を統合する概念
  2. Simpler community summary: 階層化を単純化
  3. LLM agnostic: Claude / GPT / Gemini どれでも動く設計

  しかし LightRAG library を直接採用する課題

  ┌───────────────────────────────────────┬────────────────────────────────────────────────────────────────────────┐
  │                 課題                  │                                  詳細                                  │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
  │ Embedding / vector DB 前提            │ LightRAG も内部で embedding を使う、Rwiki の「RAG ではない」原則と衝突 │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
  │ Corpus 構築前提                       │ 未キュレート文書から graph 構築する設計、Rwiki は既にキュレート済み    │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
  │ 外部依存追加                          │ Python 標準依存の Rwiki 方針と合わない                                 │
  ├───────────────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
  │ Rwiki の frontmatter 構造を活用しない │ LightRAG は独自の graph 形式を使う                                     │
  └───────────────────────────────────────┴────────────────────────────────────────────────────────────────────────┘

  結論: LightRAG の設計思想を取り入れる、library は使わない

  具体的には：
  - Dual-level retrieval の概念 を採用（local / global の 2 モード）
  - シンプルな community summary を参考に
  - Library 採用なし（networkx + 既存インフラで実装）
  
  
  ---
  2. 「Curated data に GraphRAG を適用する」発想の評価

  これが本質的な洞察です。

  通常の GraphRAG の前提

  Input: 未キュレート corpus（PDF、Web、Email 等）
           ↓ LLM 自動抽出（entity + relation）
         Graph 構築（自動）
           ↓
         Community detection + 自動 summary
           ↓
         Query 応答

  GraphRAG は unstructured data から structure を抽出するツール。

  「Curated GraphRAG」の前提（ユーザー提案）

  Input: キュレート済み wiki（人間承認済み、frontmatter 構造化）
           ↓ （frontmatter の graph が既にある）
         Graph は既存（手動 + 部分的 LLM 補助）
           ↓
         Community detection + 俯瞰的分析
           ↓
         Query 応答（Perspective / Hypothesis）

  GraphRAG の技法は活用するが、構築は人間主導。

  この発想のメリット（通常 GraphRAG より優位）


  ┌────────────────────────────┬──────────────────────────────┬──────────────────────────────────────────────────┐
  │            観点            │        通常 GraphRAG         │             Curated GraphRAG（提案）             │
  ├────────────────────────────┼──────────────────────────────┼──────────────────────────────────────────────────┤
  │ Signal-to-noise            │ 低（未キュレートの雑音含む） │ 高（キュレート済み）                             │
  ├────────────────────────────┼──────────────────────────────┼──────────────────────────────────────────────────┤
  │ Hallucination リスク       │ あり（LLM 抽出の誤り）       │ 低（verified knowledge が基盤）                  │
  ├────────────────────────────┼──────────────────────────────┼──────────────────────────────────────────────────┤
  │ Entity/Relation の精度     │ LLM 推論依存                 │ frontmatter に明記、高精度                       │
  ├────────────────────────────┼──────────────────────────────┼──────────────────────────────────────────────────┤
  │ Community detection の意義 │ 雑多なクラスタ               │ 意味的に明確なクラスタ（手動承認されたもの同士） │
  ├────────────────────────────┼──────────────────────────────┼──────────────────────────────────────────────────┤
  │ Global query の信頼性      │ 「corpus 全体」が曖昧        │ 「承認された知識全体」、明確な範囲               │
  ├────────────────────────────┼──────────────────────────────┼──────────────────────────────────────────────────┤
  │ Scale                      │ 数万〜数百万文書             │ 数百〜数千ページ（十分小さい）                   │
  ├────────────────────────────┼──────────────────────────────┼──────────────────────────────────────────────────┤
  │ Trust chain                │ 曖昧                         │ 厳格、evidence chain 維持                        │
  └────────────────────────────┴──────────────────────────────┴──────────────────────────────────────────────────┘

  Rwiki が取るべき位置付け

  「Curated Graph Query System」（新カテゴリ）

  - RAG ではない（embedding retrieval しない）
  - GraphRAG（通常）ではない（未キュレート前提ではない）
  - Curated knowledge を graph として扱い、GraphRAG の技法で query する

  これはオリジナルなポジショニングで、Karpathy の LLM Wiki 思想と完全に整合：

  ┌────────────────┬───────────────────────┬───────────────────────────────────────────────┐
  │      観点      │   Karpathy LLM Wiki   │         Curated GraphRAG（Rwiki v2）          │
  ├────────────────┼───────────────────────┼───────────────────────────────────────────────┤
  │ キュレーション │ 人間                  │ 人間（Rwiki の review/approve）               │
  ├────────────────┼───────────────────────┼───────────────────────────────────────────────┤
  │ Graph 構造     │ wiki リンク           │ Typed edges + frontmatter                     │
  ├────────────────┼───────────────────────┼───────────────────────────────────────────────┤
  │ LLM の役割     │ 要約・記帳・検出      │ Community 検出、global query、hypothesis 生成 │
  ├────────────────┼───────────────────────┼───────────────────────────────────────────────┤
  │ 検索           │ 全テキスト + index.md │ Graph-aware dual-level retrieval              │
  ├────────────────┼───────────────────────┼───────────────────────────────────────────────┤
  │ 発見           │ lint 機能             │ Community analysis, bridge detection          │
  └────────────────┴───────────────────────┴───────────────────────────────────────────────┘


  3.4 Rwiki の哲学的ポジショニング（更新）

  ┌───────────────────────────────────────────────┐
  │ Rwiki v2 = Curated Graph Query System        │
  │                                                │
  │  Trust      : 人間承認済み wiki                │
  │  Graph      : Typed edges（frontmatter）       │
  │  Perspective: Graph-aware local query          │
  │  Hypothesis : Structure gaps の発見             │
  │  Global     : Community-based global query     │← NEW
  │  Discovery  : Missing bridges の検出           │← Enhanced
  └───────────────────────────────────────────────┘
  
  
  ---
  5. 通常 GraphRAG / LightRAG との差別化（明文化）

  User-guide や comparison docs で明示する立場：

  ┌─────────────────────────────┬───────────────────┬───────────────────────┬───────────────────┬───────────────────────┐
  │          システム           │       入力        │      Graph 構築       │       検索        │       位置付け        │
  ├─────────────────────────────┼───────────────────┼───────────────────────┼───────────────────┼───────────────────────┤
  │ ChatGPT 素                  │ LLM 内部          │ なし                  │ LLM 内部          │ 一般知識              │
  ├─────────────────────────────┼───────────────────┼───────────────────────┼───────────────────┼───────────────────────┤
  │ Vector RAG                  │ 未キュレート      │ なし（chunk + embed） │ Vector            │ 検索増強              │
  ├─────────────────────────────┼───────────────────┼───────────────────────┼───────────────────┼───────────────────────┤
  │ GraphRAG (MS)               │ 未キュレート      │ 自動（LLM 抽出）      │ Graph + Vector    │ Corpus 構造化         │
  ├─────────────────────────────┼───────────────────┼───────────────────────┼───────────────────┼───────────────────────┤
  │ LightRAG                    │ 未キュレート      │ 自動（軽量）          │ Dual-level        │ Corpus 構造化（軽量） │
  ├─────────────────────────────┼───────────────────┼───────────────────────┼───────────────────┼───────────────────────┤
  │ Rwiki v2 (Curated GraphRAG) │ キュレート済 wiki │ 人間承認 + LLM 提案   │ Graph、Dual-level │ 信頼できる発見・仮説  │
  └─────────────────────────────┴───────────────────┴───────────────────────┴───────────────────┴───────────────────────┘
  
~~~





# ChatGPTの分析



## ⑦ ブレイクスルー：新しい定義が誕生

ここが今回の最大の進展👇

👉 **Curated GraphRAG**

つまり：

| 従来             | Rwiki v2               |
| ---------------- | ---------------------- |
| 未整理 → graph化 | 既に整理済 → graph活用 |
| LLM中心          | 人間承認中心           |
| ノイズあり       | 高信頼                 |

------

## ⑧ 展開④：Curated GraphRAG の具体機能

GraphRAGから取り込んだ要素：

- Community detection
- Global query
- Missing bridge detection
- Hierarchical summary（オンデマンド）

👉 Scenario 14 が拡張された



# 🧠 本質的に何が起きたか

この議論、実はかなり重要なジャンプをしています。

### Before

- Rwiki = LLM付きwiki + RAGっぽい何か

### After

- Rwiki =
   👉 **「Curated Knowledge Graph に対する探索・発見システム」**



