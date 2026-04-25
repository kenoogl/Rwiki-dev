# Rwiki V2の開発



##### ❯ 次の方針に沿って開発を進める。として、`.kiro/drafts/rwiki-v2-consolidated-spec.md`の9章をはりつける

~~~
⏺ 方針を理解しました。要点を確認します。

  実装順序（5 Phase）の起点
  - Phase 1a: Spec 0（foundation）の requirements 起草 → Spec 1（classification）
  - 残り 2 件の coordination（Spec 1↔3、Spec 2↔5）は起票中に自然解決

  MVP 範囲
  - Spec 0-7、ただし Spec 5 は P0+P1+P2 まで
  - Scenario 13/18/26/34-38 を含む

  v1 archive
  - .kiro/specs/* を .kiro/specs/v1-archive/ に移動してから新 spec 群を .kiro/specs/ 直下に起票

  確認させてください。次のいずれから着手しますか？

  1. v1 archive の実行（.kiro/specs/* → v1-archive/ への移動）から始める
  2. archive はスキップして Spec 0 起票から（/kiro-spec-init で foundation を作成）
  3. Spec 0 の brief 確認から（既存 drafts / consolidated-spec v0.7.10 を読み込んで起票準備の整合確認）

  個人的推奨は 1 → 3 → 2 の順（archive を先に済ませて新 spec の置き場を整理 → consolidated-spec の最新版を読み込んで Spec 0 起票材料を固める →/kiro-spec-init）ですが、方針があれば従います。
~~~

##### ❯ 現在はconsolidated-specはv0.7.12になっている。参考シナリオが.kiro/drafts/rwiki-v2-scenarios.mdにある。cc-sddの方針に沿って開発を進める。各スペックは一応起草しているが、全体を管理するため、/kiro-discoveryで始めるのが良いか？また、このディレクトリはv1となっている。v2を開発するにあたり、退避の必要はないか

~~~
⏺ 現状把握のため、.kiro/ 配下の構造と consolidated-spec / scenarios の最新を確認します。
 把握しました。状況は次の通りです。

  現状確認
  - .kiro/specs/* 8 件（agents-system, cli-audit, cli-query, module-split, project-foundation, rw-light-rename, severity-unification, test-suite）はすべて v1 系（rw_light.py 前提）
  - .kiro/drafts/rwiki-v2-consolidated-spec.md は v0.7.12（2731 行、2026-04-25）
  - .kiro/drafts/rwiki-v2-scenarios.md は 2406 行
  - .kiro/steering/roadmap.md も v1 用（rw_light.py 言及）
  - v2 用の起票済 spec は .kiro/specs/ 直下にはまだ無い（「一応起草している」は consolidated-spec §6/§9 の骨子のことですね？）

  ---
  回答

  1. v1 退避は必要です

  consolidated-spec §9.2 方針通り、新 spec 起票前に下記を退避すべきです：
  - .kiro/specs/* 8 件 → .kiro/specs/v1-archive/
  - .kiro/steering/roadmap.md → v1 用なので .kiro/steering/v1-archive/ に退避（v2 用に新規作成）
  - .kiro/steering/product.md tech.md structure.md も v1 前提のはず → 同様に退避が必要か要確認

  退避しないと、/kiro-spec-status や /kiro-spec-batch が v1/v2 を混在で扱ってしまいます。

  2. /kiro-discovery から始めるべきか

  推奨：スキップして良い。理由：
  - /kiro-discovery は「idea から brief + roadmap を作る」探索フェーズ。本件は既に v0.7.12 consolidated-spec で discovery 相当の成果物（vision,
  scope, 5 Phase 実装順、MVP 範囲、依存関係）が完成済み
  - 再度 discovery を回すと議論が二度手間になり、v0.7.12 の合意が揺らぐリスク

  ただし /kiro-spec-batch を将来使うなら、.kiro/steering/roadmap.md（v2 用）に Spec 0-7 を dependency-wave 形式 で記述する必要があります。これはdiscovery のロードマップ生成機能に相当するので、軽量版として：

  - consolidated-spec §9.4 の 5 Phase 順序を .kiro/steering/roadmap.md に手動転記（30 分程度）
  - もしくは、brief 段階を skip して /kiro-spec-init で Spec 0 から個別起票（roadmap は後で書く）

  ---
  推奨フロー

  Step 1: v1 archive
    - .kiro/specs/* → .kiro/specs/v1-archive/
    - .kiro/steering/{product,tech,structure,roadmap}.md を確認、v1 前提なら退避

  Step 2: v2 steering 整備
    - .kiro/steering/roadmap.md を新規作成（§9.4 の 5 Phase + MVP 範囲を記述）
    - product.md / tech.md / structure.md を v2 用に新規作成 or /kiro-steering 実行

  Step 3: Spec 0 から起票
    - /kiro-spec-init project-foundation "Rwiki v2 foundation: 3層アーキテクチャ + 12中核原則 + 用語集"
    - 以後 §9.4 の依存順で進める

  この順で進めて良いですか？ Step 1（v1 archive）から着手します。
~~~

##### ❯ まず、step1を実行。.kiro/はdrafts, settings以外は全てv1

~~~
⏺ 退避を実行します。
⏺ 51 ファイル全て git tracked です。git mv で履歴を保ったまま移動します。
⏺ 退避完了。

  結果
  - .kiro/specs/v1-archive/ に 8 spec を移動（agents-system, cli-audit, cli-query, module-split, project-foundation, rw-light-rename,
  severity-unification, test-suite）
  - .kiro/steering/v1-archive/ に 4 ファイルを移動（product, tech, structure, roadmap）
  - git mv により 51 ファイル全て rename として履歴保持
  - .kiro/settings/ .kiro/drafts/ は不変
  - .kiro/specs/ .kiro/steering/ 直下は v2 起票用の空スペースが確保された

  未コミット状態です。コミットしますか？ コミットメッセージ案：

  chore(kiro): v1 specs/steering を v1-archive/ に退避（v2 起票準備）

  - .kiro/specs/* (8 spec) → .kiro/specs/v1-archive/
  - .kiro/steering/{product,tech,structure,roadmap}.md → .kiro/steering/v1-archive/
  - .kiro/settings/ と .kiro/drafts/ は温存
  - consolidated-spec v0.7.12 §9.2 方針に準拠

  次は Step 2（v2 steering 整備） ですが、コミット先行で良いですか？
~~~

##### ❯ コミットしてください

 ~~~    
 ⏺ コミット完了 (f80a77a)。51 ファイル全て rename として記録され、履歴は完全に保持されています。
 
   Step 1 完了
 
   次の Step 2（v2 steering 整備） の選択肢：
 
   1. /kiro-steering を実行（標準フロー）
     - product.md tech.md structure.md を skill が自動生成
     - ただし v2 はまだ実装ゼロ（フルスクラッチ方針）なので、skill が現状の v1 コードを読んで誤った steering を生成する可能性あり
   2. 手動で steering 整備（推奨）
     - roadmap.md: consolidated-spec §9.4 の 5 Phase 順 + §9.6 MVP 範囲を転記（dependency-wave 形式で /kiro-spec-batch でも使える形）
     - product.md: §1 ビジョンと価値提案から要約
     - tech.md: §3 技術スタック（あれば）から
     - structure.md: §4 ディレクトリ構造から
     - 全て consolidated-spec v0.7.12 を出典として明記
   3. roadmap.md のみ最低限作成して即起票へ
     - /kiro-spec-init には steering 全部は不要（roadmap だけあれば dependency 順が見える）
     - product/tech/structure は Spec 0 起票後に追加で良い
 
   私の推奨は 2 または 3。/kiro-steering は v1 コードを読み取るので適しません。
 ~~~

##### ❯ docsとsample, tVault以外のｖ1の生成物は退避しなくてよいか？v2開発と混ざらないか

~~~
⏺ 良い指摘です。ルート構造を確認して、v1 生成物を全て洗い出します。
⏺ review/ と wiki/ の中身と git 管理状況も確認します。
⏺ ルート構成を分析しました。consolidated-spec §9.1-9.2 の方針と照合した結果です。

  v1 確定（退避すべき）

  ┌────────────────────┬──────────────────────────────────────────────────┬───────────────┐
│         対象       │                       内容                        │     退避理由    │
├────────────────────┼──────────────────────────────────────────────────┼───────────────┤
│ scripts/ (6 files) │ rw_audit/cli/config/prompt_engine/query/utils.py │ v1 実装本体     │
├────────────────────┼──────────────────────────────────────────────────┼───────────────┤
│ templates/ (15 files) │ AGENTS/, CLAUDE.md（vault 配布物）              │ v1 テンプレート │
├────────────────────┼──────────────────────────────────────────────────┼───────────────┤
│ tests/ (14 files)  │ 644 テスト（v1 仕様カバレッジ）                      │ v1 仕様の暗黙仕様│
├────────────────────┼──────────────────────────────────────────────────┼───────────────┤
│ pytest.ini         │ テスト設定                                         │ v1 テスト用     │
├────────────────────┼──────────────────────────────────────────────────┼───────────────┤
│ CHANGELOG.md       │ v1 変更履歴                                      │ rw_light 等を言及│
├────────────────────┼──────────────────────────────────────────────────┼───────────────┤
│ README.md          │ v1 概要（Karpathy/raw→review→wiki/rw_light）      │ v1 説明         │
├────────────────────┼──────────────────────────────────────────────────┼───────────────┤
│ review/ wiki/      │ 空ディレクトリ（v1 vault 構造の残骸）                 │ v1 構造の名残   │
└────────────────────┴──────────────────────────────────────────────────┴───────────────┘

  温存（v1/v2 共通 or ユーザー指定）

  ┌───────────────────────┬──────────────────────────────────────────────────┐
  │         対象          │                       理由                       │
  ├───────────────────────┼──────────────────────────────────────────────────┤
  │ CLAUDE.md (root)      │ Kiro SDLC 設定で v1/v2 共通                      │
  ├───────────────────────┼──────────────────────────────────────────────────┤
  │ docs/                 │ ユーザー指定（議論ログ・ドラフト・archive 含む） │
  ├───────────────────────┼──────────────────────────────────────────────────┤
  │ sample/               │ ユーザー指定                                     │
  ├───────────────────────┼──────────────────────────────────────────────────┤
  │ tVault/               │ ユーザー指定（gitignore 済）                     │
  ├───────────────────────┼──────────────────────────────────────────────────┤
  │ .kiro/ .claude/ .git/ │ 設定・履歴                                       │
  └───────────────────────┴──────────────────────────────────────────────────┘

  ---
  提案する退避先構造

  /v1-archive/
  ├── scripts/      ← rw_*.py 6 ファイル
  ├── templates/    ← AGENTS/ + CLAUDE.md
  ├── tests/        ← 14 テストファイル
  ├── review/       ← 空ディレクトリ
  ├── wiki/         ← 空ディレクトリ
  ├── pytest.ini
  ├── CHANGELOG.md
  └── README.md

  §9.1 「scripts/ tests/ templates/AGENTS/ は 実装時の参考資料」「v2 実装完了後に 段階的に置換」と明記されているので、削除ではなく v1-archive/
  配下で参照可能な形を保つのが筋です。

  ---
  懸念点 2 つ

  1. README.md が消えると GitHub 顔が無くなる
    - 案 A: 空の最小スタブを置く（「Rwiki v2 — 開発中。v1 の説明は v1-archive/README.md」）
    - 案 B: README.md は退避せず、冒頭に「v2 リライト中、v1 説明は下記」追記
    - 案 C: そのまま退避してスタブ無し（v2 README 完成まで README なし）
  2. Python の import パス
    - v2 実装時に v1-archive/scripts/rw_utils.py を from v1_archive.scripts.rw_utils import ... で参照する手もあるが、v1-archive はハイフンで Python
  パッケージ不可
    - → v2 では rw_utils 等を 完全に書き直す 想定（§9.1）なので import 不要、参照はファイルとして読むだけで OK

  README どれにしますか？ 私の推奨は 案 A（最小スタブ）。
~~~

##### ❯ Aで進めて

~~~
⏺ 退避を実行します。
⏺ サブディレクトリが入ってました（v1 vault 構造の残骸）。通常の mv で移動します。
⏺ ルートが整理されました。README.md スタブを作成します。
⏺ 少し気になる点が 2 つ。
⏺ 2 点判断が必要です。
  1. CLAUDE.md の未コミット変更

  +## 出力フォーマット
  +    - 表のセルは日本語全角45文字以内
  +    - 長文は表外に出す

  これは ユーザーが先に追加された未コミット変更（私は触っていません）。先ほどの「再確認」は、この未コミット変更が私の目に入っているかの確認だったのかもしれません。

  → どう扱いますか？
  - A: この退避コミットに 含める
  - B: 別コミットで分けて先にコミット
  - C: ユーザーが手動で別途コミット予定

  2. v1-archive/review/ v1-archive/wiki/ が空ディレクトリで git に乗らない

  v1-archive/review/  (空、git は追跡しない)
  v1-archive/wiki/    (空、git は追跡しない)

  空サブディレクトリ（review/query/, review/synthesis_candidates/, wiki/synthesis/）も全て空。gitは空ディレクトリを記録しないので、コミットすると消える扱い。

  → どうしますか？
  - A: .gitkeep を置いて v1 vault 構造の参考として残す
  - B: 元々空なので git で消えても良い（v1 の vault 構造は consolidated-spec §4 や v1-archive/templates/ に文書化されている前提）

  私の推奨は 1-B（別コミット先行）+ 2-B（空 dir は記録しない）。CLAUDE.md は v1 archive と無関係な変更なので別コミットの方が履歴が綺麗。空 dirは意味が無いので残さない。

  判断お願いします。
~~~

##### ❯ 推奨どおり。

~~~ 
⏺ CLAUDE.md を先に分離コミットし、その後 v1 archive をコミットします。
⏺ Step 1 完全完了。3 コミットを記録：
  現在のルート構成（クリーン）

  Rwiki-dev/
  ├── CLAUDE.md           ← Kiro SDLC（共通）
  ├── README.md           ← v2 開発中スタブ
  ├── docs/               ← 議論ログ・ドラフト・archive
  ├── sample/             ← サンプル
  ├── tVault/             ← テスト Vault（gitignored）
  ├── .kiro/
  │   ├── drafts/         ← v0.7.12 consolidated-spec, scenarios 等
  │   ├── settings/       ← kiro skill 共通テンプレート
  │   ├── specs/v1-archive/      ← v1 8 spec
  │   └── steering/v1-archive/   ← v1 4 steering
  └── v1-archive/         ← v1 実装一式（scripts/templates/tests/...）

  v2 開発と v1 実装は完全に分離されました。v1-archive/ から rw_utils.py の汎用関数や 644 テストの暗黙仕様を参照可能です。

  ---
  Step 2 候補

  先ほどの選択肢を再掲：
  1. /kiro-steering（skill 自動生成）— v2 実装ゼロなので skill が困る可能性
  2. 手動で v2 steering 整備（roadmap/product/tech/structure を consolidated-spec から抽出）
  3. roadmap.md のみ最低限作成 → 即起票
~~~

##### ❯ 手動で v2 steering 整備

~~~
⏺ consolidated-spec の構造を把握してから 4 つの steering を起草します。
⏺ 各セクションを並列で読み込みます。
⏺ 4 つの steering ファイルを並列で起草します。
⏺ v2 steering 4 ファイルを作成しました。


product.md   ビジョン、Curated GraphRAG ポジショニング、4 位一体価値、設計信念               
tech.md      技術スタック、Python 依存、3 実行モード、13 中核原則の層別適用マトリクス、開発標準
structure.md 3 層アーキテクチャ、Vault 構造、開発リポジトリ構造、データフロー、4 Level コマンド階層、用語集要約
roadmap.md   Spec 0-7 一覧、5 Phase 実装順序、Coordination 必要事項、MVP 範囲、期間見積り、開発フロー

  合計 484 行（steering は常時 context 投入されるためコンパクトを意識）。

  全ファイルに > 出典: consolidated-spec v0.7.12 §x を冒頭明記 し、参照元を追跡可能にしています。

  ---
  レビュー観点の提案

  1. 過不足チェック: consolidated-spec の重要事項で steering に拾われていないものはないか
  2. 粒度: steering は「kiro skill が常時参照する project memory」想定。今のサイズで適切か、もっと圧縮 / 拡張すべきか
  3. roadmap.md の Phase 構成: §9.4 通りに転記したが、kiro-spec-batch の dependency-wave として機能する形になっているか
  4. structure.md の Vault 構造: consolidated-spec §3.2 から転記。Edge status / Page status の対比など、tech.md と重複していないか

  内容を確認してください。修正なしならコミット、修正ありなら指摘事項を反映してからコミットします。
~~~

##### ❯ 作成した4つのファイルに対応するｖ1のファイルの粒度をみて、精査。

~~~
⏺ v1 の同名 4 ファイルを並列で読み、v2 と比較します。
⏺ v1 と v2 を比較した結果です。

  行数とセクション粒度比較
┌──────────────┬─────┬─────┬───────────────────────────────────────────────────────────────────────────────────────────────┐
  │   ファイル   │ v1  │ v2  │                                             差分                                              │
  ├──────────────┼─────┼─────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ product.md   │  30 │  77 │ v2 +47（哲学・GraphRAG ポジショニングを充実、ただし Target Use Cases 欠落）                   │
  ├──────────────┼─────┼─────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ tech.md      │  67 │ 106 │ v2 +39（13 原則マトリクス追加、ただし Common Commands・Key Technical Decisions 理由付け薄い） │
  ├──────────────┼─────┼─────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ structure.md │  78 │ 160 │ v2 +82（3 層 Vault 構造を充実、ただし Code Organization・Naming・Import 欠落）                │
  ├──────────────┼─────┼─────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ roadmap.md   │ 204 │ 141 │ v2 -63（5 Phase は OK、ただし Constraints/Technical Debt/Governance 欠落 が大きい）           │
  └──────────────┴─────┴─────┴───────────────────────────────────────────────────────────────────────────────────────────────┘

  v1 にあって v2 で抜けている重要セクション
┌──────────────────────────────────┬──────────────┬───────────────────────────────────────────────────────────────────────────────────┬────────┐
  │            セクション            │ v1 ファイル  │                                    欠落の影響                                     │ 優先度 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Technical Debt（v1               │ roadmap.md   │ severity 4 水準・exit code 分離・timeout 必須・vault-migration                    │     高 │
  │ から学ぶ事項）                   │              │ 等の重要決定が継承されない                                                        │        │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Constraints                      │ roadmap.md   │ フルスクラッチ方針、LLM 非依存、Python 3.10+ などの制約が見えない                 │     高 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Governance（Adjacent Spec Sync   │ roadmap.md   │ spec 間調整の運用ルールが無い                                                     │     高 │
  │ 等）                             │              │                                                                                   │        │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Approach Decision（採用 + 却下） │ roadmap.md   │ v2 は「順序理由」はあるが「却下案と却下理由」が無い                               │     中 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Specs チェックリスト形式         │ roadmap.md   │ - [ ] Spec 0 -- ... で進捗管理しやすい                                            │     中 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Code Organization Principles     │ structure.md │ モジュール分割方針・フロントマター駆動・JSONL 採用理由が欠落                      │     中 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Naming Conventions               │ structure.md │ snake_case、ISO 日付、Edge ID format 等の規約                                     │     中 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Import Organization              │ structure.md │ 標準 + networkx 等の依存リスト                                                    │     低 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Key Technical                    │ tech.md      │ JSONL vs Graph DB、reject-only vs 全件 approve 等の判断記録                       │     高 │
  │ Decisions（理由付き）            │              │                                                                                   │        │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Common Commands                  │ tech.md      │ rw chat / pytest 等の開発用コマンド例                                             │     中 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Target Use Cases                 │ product.md   │ 知識ワーカー・研究者・Obsidian ユーザー等の対象                                   │     低 │
  ├──────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────┼────────┤
  │ Design Principles                │ product.md   │ Safety Guardrails 等の運用上の設計信念（v2 は「哲学」あり、運用観点弱い）         │     中 │
  └──────────────────────────────────┴──────────────┴───────────────────────────────────────────────────────────────────────────────────┴────────┘

  v1 にあって v2 で意図的に削除すべきもの

  - v1 の Architecture Decision: 開発リポジトリと Vault の分離（ASCII 図）→ v2 では structure.md にあり ✓ 対応済
  - v1 roadmap の各 spec の - [x] 完了一覧 → 全 v1 spec なので v2 では不要

  評価

  過不足の最大の問題は roadmap.md:
  - v2 (141 行) は Phase / MVP / 期間見積りに偏重、Constraints / Technical Debt / Governance が欠落
  - v1 (204 行) の Technical Debt セクション（severity 4 水準・exit code 分離・call_claude timeout・vault-migration・multi-user）は v2
  が継承すべき重要決定。これが steering に無いと、Spec 0 起票時に再議論になる

  tech.md / structure.md は中程度の補強が必要:
  - v2 の 13 原則マトリクスは強い、ただし「実装に直結する技術判断（JSONL 採用理由等）」「規約（Naming / Import）」が抜けている

  product.md は概ね OK:
  - Target Use Cases だけ補強すれば良い

  ---
  補強案

  私の推奨は 以下を追加（優先度高のみ即追加、中以下は確認）：

  1. roadmap.md に追加:
    - ## Constraints（フルスクラッチ、LLM 非依存、Python 3.10+、.rwiki/.hygiene.lock 必須等）
    - ## Approach Decision（Curated GraphRAG 採用、却下：全件 approve / Graph DB 正本 / 完全自動 Hygiene）
    - ## v1 から継承する技術決定（Technical Debt 継承）（severity 4 水準・exit 0/1/2・call_claude timeout 必須・vault-migration 先送り・multi-user
  先送り）
    - ## Governance（Adjacent Spec Sync ルール、spec 完了マーク、coordination 合意の記録方式）
    - Spec 一覧をチェックボックス形式に変更（- [ ] Spec 0 -- ...）
  2. tech.md に追加:
    - ## Key Technical Decisions（JSONL vs Graph DB の選択理由、reject-only vs 全件 approve、on-demand summary、Edge status 6 階段の理由）
    - ## Common Commands（rw chat / rw perspective / pytest / 開発用例）
  3. structure.md に追加:
    - ## Code Organization Principles（フロントマター駆動、構造化 JSON ログ、JSONL append-only、derived cache の gitignore）
    - ## Naming Conventions（snake_case、ISO 日付、CLI 動詞、Edge ID / Evidence ID format）
  4. product.md に追加:
    - ## Target Use Cases（v1 のリスト + v2 固有: Perspective/Hypothesis 探索ユーザー）

  ---
  実行方針の確認

  A: 上記 4 ファイル全部を補強（各ファイル +30〜80 行、合計 +200〜300 行）
  B: roadmap.md の高優先度のみ補強（Constraints / Approach / Technical Debt 継承 / Governance）、他はスキップ
  C: 全部追加した上で、v2 過剰部分（哲学繰り返し等）を圧縮して総量はあまり増やさない

  私の推奨は C（v1 並みの実用性を保ちつつ、steering 肥大を避ける）。どれで進めますか？
~~~

❯ C案で進める

~~~ 
⏺ サイズ確認：

  ┌──────────────┬─────┬───────┬───────┐
  │   ファイル   │ v1  │ v2 新 │ v1 比 │
  ├──────────────┼─────┼───────┼───────┤
  │ product.md   │  30 │    93 │   +63 │
  ├──────────────┼─────┼───────┼───────┤
  │ tech.md      │  67 │   145 │   +78 │
  ├──────────────┼─────┼───────┼───────┤
  │ structure.md │  78 │   194 │  +116 │
  ├──────────────┼─────┼───────┼───────┤
  │ roadmap.md   │ 204 │   210 │    +6 │
  ├──────────────┼─────┼───────┼───────┤
  │ 合計         │ 379 │   642 │  +263 │
  └──────────────┴─────┴───────┴───────┘
    ┌──────────────────┬────────────────────────────────────────────────────┬──────────┬──────┐
  │   ファイル:行    │                        セル                        │ 全角換算 │ 判定 │
  ├──────────────────┼────────────────────────────────────────────────────┼──────────┼──────┤
  │ product.md:24    │ LLM が未検証の仮説を生成、検証ワークフロー供給     │     約22 │ OK   │
  ├──────────────────┼────────────────────────────────────────────────────┼──────────┼──────┤
  │ product.md:38    │ evolving（使用で育つ、不活性で痩せる）             │     約20 │ OK   │
  ├──────────────────┼────────────────────────────────────────────────────┼──────────┼──────┤
  │ product.md:78-82 │ hallucination/graph/Hygiene 等を含む差別化セル     │    18-35 │ OK   │
  ├──────────────────┼────────────────────────────────────────────────────┼──────────┼──────┤
  │ structure.md:142 │ Decay / Reinforcement / Competition / Merging 総称 │     約22 │ OK   │
  └──────────────────┴────────────────────────────────────────────────────┴──────────┴──────┘
---
  C 案完遂サマリ

  ┌─────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │        観点         │                                                          状況                                                          │
  ├─────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ v1                  │ ✅ Constraints / Approach Decision / Technical Debt 継承 / Governance / Code Org / Naming / Import / Common Commands / │
  │ 不足セクション補強  │  Key Tech Decisions / Target Use Cases / Design Principles                                                             │
  ├─────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ v2 過剰部分圧縮     │ ✅ GraphRAG 哲学・Vault 構造図・データフロー図を簡潔化                                                                 │
  ├─────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 表セル全角45以内    │ ✅ 全セル準拠                                                                                                          │
  ├─────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 長文は表外          │ ✅ Key Tech Decisions / Approach Rejected / Code Org 等は表外配置                                                      │
  └─────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  合計 642 行（v1 379 + 263）。v2 の追加要素（13 原則マトリクス・5 Phase・MVP・Curated GraphRAG）を含めれば妥当な増分です。

  ---
  レビュー後コミットしますか？ コミットメッセージ案：

  docs(steering): v2 steering 4 ファイルを起草

  - product.md / tech.md / structure.md / roadmap.md を新規作成
  - v0.7.12 consolidated-spec から各 §を抽出（出典明記）
  - v1 steering の構成（Constraints / Approach Decision / Technical Debt /
    Governance / Naming / Import 等）を継承して補強
  - v2 固有要素（13 中核原則マトリクス、5 Phase 順序、MVP 範囲、
    Curated GraphRAG 哲学）を追加
  - CLAUDE.md 表整形ルール（全角 45 文字以内、長文は表外）に準拠
~~~

##### ❯ レビュー後コミット

~~~
⏺ セルフレビューしてからコミットします。
⏺ docs/Rwiki-V2-dev-log.md は私が触っていないユーザー作業のため除外し、steering 4 ファイルのみコミットします。
⏺ コミット完了 (0dd2ba4)。

  Step 1-2 完了サマリ

  0dd2ba4 docs(steering): v2 steering 4 ファイルを起草
  ae596e9 chore(repo): v1 ルート生成物を v1-archive/ に退避（v2 起票準備）
  c396e76 docs(claude): 出力フォーマット指示を追記
  f80a77a chore(kiro): v1 specs/steering を v1-archive/ に退避（v2 起票準備）

  .kiro/steering/ には 4 ファイル 642 行が配置され、kiro skill 群が project memory として常時参照できる状態になりました。
~~~



~~~ 
  確認事項

  1. Spec 名: project-foundation で良いか？（v1 と同名で衝突しないか）
    - v1 は .kiro/specs/v1-archive/project-foundation/ に退避済 → 衝突なし
    - consolidated-spec §7.1 では rwiki-v2-foundation と表記
    - 推奨: rwiki-v2-foundation（v2 と明記、混同防止）
  2. 起票方式:
    - A: /kiro-spec-init で 1 spec ずつ手動起票（標準フロー）
    - B: /kiro-spec-batch で全 8 spec を Phase 順に並列起票（roadmap.md の dependency-wave 利用）
  3. ドラフトの扱い:
    - consolidated-spec §6 / §7.2 で各 spec の Key Requirements が既に骨子レベルで起草済
    - これを /kiro-spec-init の description に渡せば、/kiro-spec-requirements の生成精度が上がる

  どう進めますか？
~~~

