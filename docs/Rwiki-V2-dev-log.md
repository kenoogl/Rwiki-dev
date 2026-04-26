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

---
  新ルール「レスポンスは、表形式禁止。箇条書きを使う。」について確認が必要です。

  - 解釈 A: 私のチャット応答のみが対象（steering 等の project files は対象外）
  - 解釈 B: 全出力対象（先ほど作成した steering 4 ファイルも書き直し必要）

  先ほど起草した steering 4 ファイル（commit 0dd2ba4）は表を多用しています。

  - product.md: 6 表
  - tech.md: 6 表（13 中核原則マトリクスを含む）
  - structure.md: 5 表
  - roadmap.md: 2 表

  解釈 B の場合、これらを箇条書きに書き直すべきです。ただし 13 中核原則マトリクス（13 項目 × 3 層）は表が圧倒的に読みやすいので、判断が分かれます。

  どちらの解釈で進めますか？

  - A: チャット応答のみ表禁止 → steering はそのまま、私の今後の応答だけ箇条書き化
  - B: 全て表禁止 → steering 4 ファイルを書き直し（マトリクスはネスト箇条書きで表現）
  - C: 部分採用 → チャットは原則箇条書き、steering は表 OK だが乱用しない

✻ Sautéed for 1m 9s

❯ A

⏺ 解釈 A で進めます。

  - steering 4 ファイル（0dd2ba4）はそのまま維持
  - 私のチャット応答のみ今後は表禁止・箇条書きに統一

  ---
  Step 3: Spec 0 起票準備

  次の判断事項です。

  Spec 名の確定

  - 候補 1: project-foundation（v1 と同名、v1 は v1-archive に退避済なので衝突は無い）
  - 候補 2: rwiki-v2-foundation（consolidated-spec §7.1 表記に合わせる、v1 と明示分離）
  - 推奨: 候補 2（混同防止、v2 spec 群を rwiki-v2-* 命名で統一する案も視野）

  起票方式

  - A: /kiro-spec-init で 1 spec ずつ手動起票（標準フロー、Phase 順に逐次承認）
  - B: /kiro-spec-batch で全 8 spec を Phase 順に並列起票（roadmap.md の dependency-wave 利用、初期生成だけ並列・承認は逐次）

  ドラフト材料の渡し方

  - consolidated-spec §6（Task & Command モデル）と §7.2（各 spec の Key Requirements）に骨子が既にある
  - これを /kiro-spec-init の description に渡せば /kiro-spec-requirements の生成精度が上がる

  確認事項です。

  - Spec 名は rwiki-v2-foundation で良いか
  - 起票方式は A（逐次）と B（並列起票）どちらか
  - v2 spec 群を rwiki-v2-* プレフィックスで統一するか、シンプルに foundation classification skill-library 等にするか

~~~

##### ❯ spec名はrwiki-v2-foundation、起票方式はB、v2 spec 群を rwiki-v2-* プレフィックスで統一

~~~
⏺ roadmap.md と他 steering の spec 名を rwiki-v2-* に統一する必要があります。まず現状の出現箇所と /kiro-spec-batch skill の仕様を確認します。
⏺ /kiro-spec-batch の前提条件を確認しました。重要な制約があります。

  - 前提 1: ## Specs (dependency order) セクションが必須（私の roadmap は ## Spec 一覧 で不一致）
  - 前提 2: 各 feature に .kiro/specs/<feature>/brief.md が 存在しないと batch は走らない
  - 不在時の skill の指示: "Run /kiro-discovery to generate briefs first"

  /kiro-discovery の挙動を確認します。

  Read 1 file (ctrl+o to expand)

⏺ /kiro-spec-batch を使うには、全 spec の brief.md が事前に必要 です。これを満たす方法が 3 つあります。

  - A. /kiro-discovery Path D で再実行（対話で全 brief.md と roadmap.md を生成、標準フロー）
    - 既存 v0.7.12 議論を再度なぞる対話が発生
    - skill 標準フォーマットが保証される
  - B. 手動で 8 brief.md 作成 + roadmap.md 修正（私が consolidated-spec §7.2 から brief を抽出）
    - v0.7.12 で議論は完了済、再議論不要
    - consolidated-spec §7.2 に各 spec の Key Requirements が既にある（brief 素材として十分）
    - skill 想定（ideas → discovery → brief）と実態（既に完全設計済）が乖離しているケース
  - C. /kiro-discovery を最小対話で走らせる（context を私が事前に提示して、skill は brief 出力のみ実施）

  roadmap.md 修正も必要（どの方式でも）

  - ## Spec 一覧 → ## Specs (dependency order)（kiro-spec-batch が parse するセクション名）
  - 各エントリ形式を - [ ] feature-name -- description. Dependencies: ... に統一
  - spec 名を rwiki-v2-* プレフィックスに統一
  - 本文中の Spec 1 Spec 2 等の参照も rwiki-v2-classification 等に置換

  私の推奨は B

  - consolidated-spec §7.2 が brief 相当の内容を既に持っている
  - ユーザー対話を最小化、context 効率良
  - 8 brief.md を並列 Write で一気に作成可能
  - skill の想定（discovery で refine する）は本ケースでは不要（議論完了済）

  どれで進めますか？
~~~

##### ❯ B

~~~
⏺ consolidated-spec §7.2 の全 8 spec の詳細を取得します。
⏺ 8 spec の brief.md を並列作成します。
⏺ 確認して、git に追加するファイルを stage します。
⏺ dependency 構造を確認すると、consolidated-spec §9.5「Spec 4, 7 requirements 並列可」と整合しません。Spec 7 の dependency を緩めて Wave 3で並列化します。
⏺ 8 brief と roadmap 修正をコミットします。docs/Rwiki-V2-dev-log.md はユーザー作業のため除外。
⏺ /kiro-spec-batch 実行準備が完了しました。
  - コミット 574c963: 8 brief.md + roadmap.md dependency 更新（9 files, 657 insertions）
  - dependency wave は 7 wave（並列性は Wave 3 で 2 spec、他は 1 spec ずつ）

  ---
  /kiro-spec-batch 実行前の最終確認

  skill の動作（kiro-spec-batch SKILL.md より）

  - 各 wave で並列 subagent 起動（spec.json + requirements.md + design.md + tasks.md を生成）
  - 全 spec が auto-approve（-y フラグ相当）モードで自動生成される
  - 全 wave 完了後に cross-spec consistency review（1 subagent）
  - roadmap.md を [x] で完了マーク

  時間とコスト

  - 7 wave × 各 wave 数分〜十数分の subagent 実行 → 全体で 30-90 分程度の見込み
  - 8 spec 分の context 消費（subagent 内に隔離されるが、controller の context にも cross-review 結果等が入る）

  リスクと対応策

  - 全 spec が一気に生成されるため、設計判断の細部は後で人間レビューが必要
  - consolidated-spec v0.7.12 §7.2 / §9 の方針が brief に反映されているので、生成内容は方針整合
  - 生成後に問題があれば個別 spec を /kiro-spec-requirements <feature> 等で再生成可能
  - cross-spec review が boundary overlap や interface 不整合を検出してくれる

  実行しますか？

  - A: /kiro-spec-batch を即実行（全 8 spec を一気に起票）
  - B: 最初に Spec 0（rwiki-v2-foundation）だけ /kiro-spec-init で個別起票し、内容を確認してから残りを batch
  - C: 別の方針
~~~

##### ❯ Cとして、各 wave で並列 subagent 起動するが、spec.json, requirements.mdのみを対象とすることはできるか

~~~
⏺ 可能です。kiro-spec-batch skill そのものは spec.json + requirements + design + tasks を一括生成しますが、カスタム実装で spec.json + requirements.mdだけ生成 することができます。

  実装方針
  - 私が roadmap.md の ## Specs (dependency order) を parse して dependency wave を構築
  - 各 wave で Agent tool を使って並列 subagent 起動
  - 各 subagent への指示：
    - brief.md と roadmap.md を読む
    - .claude/skills/kiro-spec-init/SKILL.md の手順で spec.json + requirements-init.md を作成
    - .claude/skills/kiro-spec-requirements/SKILL.md の手順で完全な requirements.md を生成
    - spec.json の approvals.requirements.generated = true / approved = true に設定（auto-approve）
    - design.md / tasks.md は生成しない
    - 完了報告（生成ファイル一覧 + 主要 requirement 数）
  - 全 wave 完了後、optional で cross-spec consistency review（requirements に絞ったもの）を 1 subagent で実行

  実装方法の選択肢

  - A. 私が今このセッションで Agent tool を直接呼び出して各 wave dispatch（即実行可、本セッション内で完結、再利用なし）
  - B. プロジェクト固有 skill .claude/skills/kiro-spec-batch-requirements-only/SKILL.md を新規作成（再利用可、初期コスト 1 ファイル作成）

  利点・欠点

  - A: 即実行可、context 内で進捗が見える、ただし 8 spec の wave 7 段階を私が monitor する必要がある
  - B: 将来 spec を追加するときも使える、skill ファイルを作る分初期コスト、ただし skill 完成後は /kiro-spec-batch-requirements-only 1 コマンドで実行

  私の推奨は A

  - 現状 v2 MVP の 8 spec 起票が一回限りの作業
  - B（skill 化）は現状不要（同じ手順を繰り返し使う見込みが低い）
  - A なら今すぐ Wave 1 から開始できる

  どちらで進めますか？
~~~

##### ❯ Aで進めるが、approved = falseとする。レビューするため。

~~~
⏺ 了解。approved = false で各 spec の人間レビュー gate を残します。
  Wave 1（rwiki-v2-foundation）から開始します。
⏺ Wave 1 完了。生成内容を簡易確認します。
⏺ subagent の指摘事項確認結果。本文は SSoT 準拠で正しいが、見出しのみ brief の誤記（Page status 4 種 → 正しくは 5種）に引きずられている。即修正します。
 Wave 1 完了報告。

  生成状態

  - rwiki-v2-foundation/spec.json: phase = "requirements-generated", approvals.requirements.generated = true / approved = false ✅
  - rwiki-v2-foundation/requirements.md: 14 Requirement、約 85 acceptance criteria（EARS 形式、日本語）

  修正 2 件（即適用済）

  - brief.md: Page status 「4 種」→「5 種」（私の brief 記述ミス、SSoT v0.7.12 §4.3/§5.9.1 では 5 種が正）
  - requirements.md Requirement 5 見出し: 「4 種」→「5 種」（subagent が brief に引きずられた箇所）

  subagent からの指摘事項

  - Subject の選定: criterion の subject を the Foundation（規範文書）とした。Spec 0 の特殊性として人間レビューで妥当性確認推奨
  - 境界線引き: Frontmatter スキーマ骨格 (Req 8) と Spec 1 の所管境界は設計時に再点検すべき
  - Hypothesis status の追加: SSoT §5.9.1 を参照して Hypothesis status 7 種を Edge/Page と独立した第 3 軸として Req 5 に明示（briefには記載なかったが追加）

  Wave 2 以降の進め方

  - A. Wave 2 を即実行（全 wave 連続 batch、最後に一括レビュー）
  - B. Spec 0 をユーザーが先にレビュー → 承認または修正指示 → Wave 2 進む
  - C. Wave 2 以降を全部走らせ、cross-spec review もかけてから一括レビュー

  私の推奨は A

  - Spec 0 の boundary は brief で固定済、subagent の自由度は限定的
  - 各 wave 逐次レビューは時間コスト大（7 wave）
  - 各 spec は approved = false なので人間レビュー gate は維持される

  ただし基盤 spec のため B も合理的。どれで進めますか？
~~~

##### ❯ 理解のために説明してください。wave2、連続 batch、cross-spec reviewとは何か

 ~~~
 ⏺ 3 つの用語を解説します。
 
   Wave 2
 
   - 「dependency wave」の 2 段目
   - roadmap.md の ## Specs (dependency order) から私が構築した依存グラフを並列実行可能なグループに分けたもの
   - 各 wave 内の spec は 互いに依存しない ので並列起票可能、wave 間は逐次（前 wave 完了が前提）
 
   具体的に v2 の dependency wave
 
   - Wave 1: rwiki-v2-foundation（依存なし）
   - Wave 2: rwiki-v2-classification（Wave 1 のみに依存）
   - Wave 3: rwiki-v2-cli-mode-unification, rwiki-v2-lifecycle-management（Wave 1+2 のみに依存、互いに独立）— 並列 2 spec
   - Wave 4: rwiki-v2-knowledge-graph
   - Wave 5: rwiki-v2-skill-library
   - Wave 6: rwiki-v2-prompt-dispatch
   - Wave 7: rwiki-v2-perspective-generation
 
   つまり「Wave 2」は rwiki-v2-classification の requirements 生成を 1 subagent で実行する段階。
 
   連続 batch
 
   - Wave 1 完了 → Wave 2 完了 → ... → Wave 7 完了 を 間に人間レビューを挟まず連続実行 すること
   - 各 wave で生成される spec.json と requirements.md は approved = false のまま（レビューゲート維持）
   - 全 wave 完了後にユーザーが各 spec を順次レビュー → 承認 or 修正指示
 
   対比
 
   - 連続 batch = 7 wave 全てを subagent dispatch で一気に完了 → 後でまとめてレビュー
   - 逐次レビュー = Wave 1 完了 → ユーザーレビュー → Wave 2 → レビュー → ... → 各 wave で人間判断ゲート
 
   cross-spec review
 
   - 全 spec が生成された後の 横断的整合性チェック 工程
   - kiro-spec-batch SKILL.md の Step 4 で定義されている標準手順
   - 1 subagent が全 spec の requirements.md を読んで以下を検出
     - データモデル整合性: 同じ entity を複数 spec が参照している場合、フィールド名・型・関係が揃っているか
     - Interface alignment: spec A の output が spec B の input になる箇所で、契約が一致しているか
     - 機能の重複: 同じ capability を複数 spec が抱え込んでいないか
     - 依存完全性: spec A の requirements が暗黙的に spec B に依存しているのに roadmap に書かれていない、等
     - 命名規約: component 名 / file パス / API ルート / table 名が spec 間で一貫しているか
     - Boundary 整合: tasks.md の _Boundary:_ annotation が spec 間で重複なく分割されているか（v2 では tasks 未生成なので requirements/design
   ベースに調整が必要）
   - v2 のケースでは Spec 0-7 が consolidated-spec という共通 SSoT を参照しているので、矛盾は少ないと予想されるが、subagent が独自解釈した部分（例:
   Spec 0 が Hypothesis 第 3 軸を追加したような追加事項）の整合確認に有用
 
   cross-spec review が見つける典型例
 
   - Spec 5 が定義した Edge schema と Spec 6 が利用する Edge schema のフィールド名がずれている
   - Spec 1 が「frontmatter type: field を新設」と書いているが Spec 3 の dispatch ロジックがそれを参照していない
   - Spec 7 の Page deprecation 処理が Spec 5 の Edge demotion API と signature が一致しない
 
   ---
   整理
 
   - Wave 2 = 次の subagent dispatch 段階（rwiki-v2-classification を生成）
   - 連続 batch = Wave 1-7 を間にレビューを挟まず一気通貫で実行
   - cross-spec review = 全 wave 完了後に整合性チェック（標準的にはやる）
 
   私が推奨案 A で言ったのは「Wave 1-7 を連続 batch で実行し、最後に cross-spec review、その後ユーザーがまとめてレビュー」という流れでした。
 ~~~

##### ❯ 推奨案 Aで実行

~~~
⏺ Wave 2 から順次実行します。Wave 2 dispatch。
⏺ Wave 2 完了。Spec 1 ↔ Spec 3 coordination で inline default_skill 方式に決定 という重要な決定がされました。Wave 3（2 spec 並列）dispatch します。
⏺ Wave 3 完了。Wave 4（Spec 5 = knowledge-graph、最大規模）dispatch。
⏺ Wave 4 完了（23 Req / 174 criteria）。Wave 5（Spec 2 = skill-library）dispatch。
⏺ Wave 5 完了（14 Req / 74 criteria）。Wave 6（Spec 3 = prompt-dispatch）dispatch。
⏺ Wave 6 完了（12 Req / 72 criteria）。Wave 7（最後、Spec 6 = perspective-generation）dispatch。
⏺ 全 7 wave dispatch 完了。Cross-spec consistency review を実行します。
⏺ 全 wave + cross-spec review 完了です。

  全 8 spec 生成サマリ

  - rwiki-v2-foundation: 14 Req / ~85 criteria
  - rwiki-v2-classification: 14 Req / 92 criteria
  - rwiki-v2-cli-mode-unification: 14 Req / 98 criteria
  - rwiki-v2-lifecycle-management: 14 Req / 96 criteria
  - rwiki-v2-knowledge-graph: 23 Req / 174 criteria（最大）
  - rwiki-v2-skill-library: 14 Req / 74 criteria
  - rwiki-v2-prompt-dispatch: 12 Req / 72 criteria
  - rwiki-v2-perspective-generation: 15 Req / ~130 criteria

  合計 120 Requirement / 約 821 acceptance criteria。全 spec とも approved = false で人間レビュー待ち。

  Cross-spec review の検出結果

  整合性が取れている領域

  - Edge status 6 種、Page status 5 種、Hypothesis status 7 種が全 spec で一致
  - §2.12 L2 専用優先関係が一貫
  - normalize_frontmatter API の責務分離（Spec 1 ↔ Spec 5 ↔ Spec 4）が三方一致
  - edge API 3 種（demote/reject/reassign）の signature と error 伝搬契約が Spec 5 ↔ Spec 7 で整合
  - .hygiene.lock Concurrency が Spec 4 ↔ Spec 5 で整合
  - Severity 4 水準 / exit 0/1/2 / timeout が roadmap.md v1 継承として一貫
  - roadmap.md の Coordination 5 件全てカバー済

  検出された問題

  Critical（2 件、即修正推奨）

  - C-1: Spec 5 Query API 14 種に entity 正規化系（get_entity(name) / resolve_entity(alias)）が未明示。Spec 6 Req 11.2 が依存しており動作不能
    - 修正案: Spec 5 Req 14.1 に [P0] get_entity(name_or_alias) → Entity を 15 種目として追加
  - C-2: generic_summary 不在時の severity 不整合。Spec 2 配布規約に「rw init 配布完了後に generic_summary 不在はERROR」と明文追加で解消（軽微な追記）

  Important（6 件、design phase 持ち越し可）

  - I-1: /mute maintenance 永続化媒体（.rwiki/config.toml か ~/.rwiki/）の所管、Spec 4 design で確定
  - I-2: 対話ログ自動保存の Spec 4 vs Spec 6 責任分担、両 spec design で coordination
  - I-3: HTML 差分マーカー attribute 詳細（Spec 2 ↔ Spec 7）
  - I-4: merge (wiki) --auto の 2 段階フラグ仕様（Spec 4 許可リストにも禁止リストにも未明示）
  - I-5: Skill lifecycle の Backlink 走査範囲（AGENTS/** を含めるか、Spec 2 ↔ Spec 7）
  - I-6: Foundation の subject = the Foundation を testable にする方法、Spec 0 design で扱う

  Minor（4 件、後回し可）

  - M-1: Spec 0 Req 8（frontmatter 骨格）と Spec 1 の境界範囲（design で再確認）
  - M-2: Hypothesis status evolved の遷移定義（生成元 trigger の明文化不足）
  - M-3: Spec 4 rw follow-up vs Spec 7 rw followup の表記揺れ（ハイフン有無）
  - M-4: Spec 0 line 7（Project Description）に「Page status 4 種」の旧表記が残存（先ほど Req 5 タイトルは修正済、Project Description は未修正）

  推奨アクション

  A. Critical 2 件 + Minor M-3/M-4 を即修正（私が手動）

  - C-1: Spec 5 Req 14.1 に entity 正規化 API を追加（subagent or 手動）
  - C-2: Spec 2 Req 11 に配布完整性 check の 1 行追加
  - M-3: コマンド名表記統一（私が grep + Edit）
  - M-4: Spec 0 Project Description の Page status 4 → 5（私が Edit）
  - Important 6 件は design phase で扱う旨を各 spec に追記 or roadmap.md に記録

  B. コミット先行、修正は別タスク

  - 8 brief コミット済 → 8 spec の spec.json + requirements.md は未コミット
  - まず現状をコミット（Critical 含む状態を保存）
  - 修正はユーザーレビューと並行で別コミット

  C. 修正してからコミット

  - Critical/Minor を修正してから一括コミット
  - 整合性問題が解消された状態で spec が並ぶ

  私の推奨は C（整合性が解消された状態でコミット）。Critical 2 件と Minor M-3/M-4 は修正コストが小さく、私の手で 10-15 分程度。

  どれで進めますか？
~~~

##### ❯  まず、C案を実行

~~~
⏺ 修正対象箇所を並列確認します。
⏺ Spec 0 と Spec 7 の修正対象行を Read してから並列 Edit します。
⏺ 並列で 8 件の Edit を適用します。
⏺ 修正完了。git status で確認してコミットします。
⏺ コミット完了 (2f34148)。17 files changed, 2591 insertions

  C 案完遂サマリ

  - 8 spec の spec.json + requirements.md を新規追加（16 ファイル）
  - Spec 0 brief.md の修正（M-4）を含む 17 ファイル
  - 全 spec とも approved = false で人間レビュー待ち
  - Critical 2 件、Minor 2 件は修正済
  - Important 6 件は design phase の coordination 議題として持ち越し（コミットメッセージに記録）

  現在の commit 履歴

  - 2f34148 v2 8 spec の requirements.md を生成 + cross-spec review 反映
  - 574c963 v2 8 spec の brief.md 起票 + roadmap dependency 更新
  - 041eb32 Rwiki v2 開発セッションログを追加
  - 4a268ab 出力フォーマットを表禁止・箇条書きに変更
  - 0dd2ba4 v2 steering 4 ファイルを起草
  - ae596e9 v1 ルート生成物を v1-archive/ に退避
  - c396e76 出力フォーマット指示を追記
  - f80a77a v1 specs/steering を v1-archive/ に退避

  次のステップ候補

  A. 8 spec の requirements.md をユーザーがレビュー → 順次 approved = true に更新

  - Spec 0 から順にレビュー、approve または修正指示
  - approve したら次の /kiro-spec-design <feature> に進める

  B. Spec 0 のみ先にレビュー → approve 後に design phase へ進む

  - 基盤 spec の妥当性を最初に確認
  - 残り 7 spec は並行レビュー or design phase 着手後に順次

  C. 全 8 spec を一度に design phase 起票（再び subagent dispatch）

  - requirements の細部レビューより、design 段階で全体像を見てから一括レビュー
  - ただし requirements が approved = false なので標準フローでは design に進めない
  - skill のフローを破る形になる

  D. 未コミット dev log を別途コミット

  - docs/Rwiki-V2-dev-log.md がユーザー作業として残っている

  私の推奨は A → B → 都度 design phase 起票（C 案のような batch を design でも繰り返す）。ただし requirements レビューは時間がかかる作業（120 Req /821 criteria）なので、優先度を絞るなら B（Spec 0 から逐次）が現実的です。

  ---
  現状

  - 8 spec の brief.md と requirements.md がコミット済
  - 全 spec とも approvals.requirements.approved = false（人間レビュー待ち）
  - design.md / tasks.md は未生成
  - dev log もコミット済
  - v1 archive、v2 steering、cross-spec review 修正全て履歴に保存

  次の選択肢

  - A. 8 spec の requirements.md レビュー → 順次 approved=true に更新 → design phase 進行
    - Spec 0 から順または並列でレビュー
    - approve 後は /kiro-spec-design <feature> を subagent dispatch（design batch）
  - B. Spec 0 のみ先にレビュー → approve 後に他 spec をどうするか判断
    - 基盤 spec の妥当性を最優先で確認
    - 残り 7 spec はその後
  - C. セッションを一旦区切る
    - requirements 生成・cross-review・修正・コミットまで完了
    - レビューは別セッションで腰を据えて行う

  私の推奨は C。120 Requirement / 821 acceptance criteria は本セッションで一気にレビューするには重く、新しいセッションで集中したほうが質の高い reviewになります。本セッションの成果物は全てコミット済なので安全に区切れます。
~~~

##### ❯ ここで一旦/kiro-steeringしたほうがいいか

~~~
⏺ /kiro-steering の挙動を確認してから判断します。

  Read 1 file (ctrl+o to expand)

⏺ 現時点では 推奨しません。/kiro-steering skill の挙動を確認した結論です。

  skill の挙動

  - 既存 steering 4 ファイル（product/tech/structure/roadmap）が揃っているので Sync mode で動作
  - Sync mode は codebase を analyze して drift detection を行う
  - 提案は additive（user 内容を保持、上書きしない）

  現時点で推奨しない理由

  - v2 実装がゼロ: skill は codebase analysis 中心。v2 実装は未着手で、v1-archive/ を読んで誤った drift を検出するリスクがある
  - steering は SSoT 出典で陳腐化していない: 私が手書きした 4 ファイルは consolidated-spec v0.7.12 の §1-9から抽出済、出典明記。要件側で更新が必要な箇所は今のところ無い
  - cross-spec review で steering ↔ spec 不整合は未検出: 検出された Critical/Important/Minor 12 件はすべて spec 間の coordination 問題、steering
  との不整合は無し
  - subagent は steering を参照して動作した: 各 wave subagent が .kiro/steering/ を読み込み、整合した requirements を生成済

  適切なタイミング候補

  - Spec 0 (rwiki-v2-foundation) が approve された後: 規範文書として確定した時点で steering との整合を sync で確認
  - Spec 5 P0+P1+P2 実装完了後: 実装パターンが揃った時点で steering に「実装規約」を追加（例: rw_graph.py のモジュール構成、edges.jsonl
  のフォーマット詳細）
  - MVP 完了後: 全実装が揃った時点で steering を全面 sync、project memory として安定化

  現時点で steering を更新するなら手動で十分

  - 例: cross-spec review で確定した「Spec 1 ↔ Spec 3 inline default_skill 方式」「Spec 5 Query API 15 種」などを roadmap.md の coordination
  セクションに追記（数行の手動 Edit で済む）

  ---
  要約: 今は spec が確定したばかりで、steering を sync する材料が薄いです。一旦セッションを区切るタイミングなら、/kiro-steeringは次のセッション以降（Spec 0 approve 後 or 実装着手後）に回すのが妥当です。
~~~

##### ❯ v1-archive/ を読んで誤った drift を検出するリスクがあるならば、常に/kiro-steeringは実行できないのではないか

```
⏺ 鋭い指摘です。確認します。

  Searched for 1 pattern (ctrl+o to expand)

⏺ 良い指摘です。整理すると、リスクは「永続的に実行不可」ではなく緩和可能です。

  緩和材料 1: skill は additive、user 内容を preservation

  - steering-principles.md に「Add, don't replace」「Preserve user sections」と明記
  - 私が手書きした「出典: consolidated-spec v0.7.12」セクションや 13 中核原則マトリクス等は skill が上書きしない
  - 仮に skill が誤った提案をしても、私が確認して reject 可能（skill は提案して終わり、強制適用しない）

  緩和材料 2: skill は exhaustive list を avoid

  - steering-principles.md の Golden Rule: 「If new code follows existing patterns, steering shouldn't need updating」
  - v1-archive の実装ファイル全部を steering に列挙するような挙動はしない
  - v1-archive のパターンを抽出しても、v2 では使わない方針（フルスクラッチ）が既に steering に明記されている

  緩和材料 3: steering で既に v1-archive 位置付けを明示済

  - structure.md: 「v1-archive/: v1 実装一式（参考資料）」「v2 開発は v1 を知らない前提で新名称のみで自己完結」と明記
  - tech.md: v1 から継承する技術決定（severity / exit code / module-split / DAG）のみ列挙、v1 実装パターンは継承しない方針
  - skill が steering を読んだ上で codebase analysis すれば、v1-archive を「v2 の codebase」として扱わない判断ができる

  緩和材料 4: 起動時に context 明示できる

  - skill 起動時のメッセージ（または直前の会話）に「v1-archive/ は v1 retired code、v2 codebase ではない、analysis 対象外」と明示
  - skill の subagent 内（または skill 内部）で context を参照できる

  ただし sync 効果が薄い理由は別

  - リスクが緩和可能でも、本質的に「v2 codebase ゼロ」のため drift detection の対象が無い
  - 実装が進んでパターンが蓄積された後（例: Spec 5 P0 完了後）に sync すると、新しい実装規約や naming convention が steering に反映される
  - 現時点 sync = 私の手書きを skill が確認するだけ → 価値が小さい

  結論

  - 「v1-archive のリスクで永続的に実行不可」ではない（緩和可能）
  - 「現状 sync 効果が薄いから推奨しない」が正しい理由
  - 適切なタイミング: Spec 0 approve 後、または Spec 5 P0 実装完了後など、v2 codebase に追加情報が蓄積されたタイミング

  ---
  もし「念のため今 1 回回しておきたい」なら、起動時に「v1-archive/ は除外」と明示すれば実行可能です。ただし期待できる成果は限定的です。
```

##### ❯ 新セッションで実行します

```
⏺ 了解。本セッションの区切りとして最終ステータスを確認します。
⏺ 本セッション完了サマリ

  コミット履歴（本セッションで追加した 8 コミット）

  - 5efd4bd v2 8 spec 起票セッションの議論を追記
  - 2f34148 v2 8 spec の requirements.md を生成 + cross-spec review 反映
  - 574c963 v2 8 spec の brief.md 起票 + roadmap dependency 更新
  - 041eb32 v2 開発セッションログを追加
  - 4a268ab 出力フォーマットを表禁止・箇条書きに変更
  - 0dd2ba4 v2 steering 4 ファイルを起草
  - ae596e9 v1 ルート生成物を v1-archive/ に退避
  - c396e76 出力フォーマット指示を追記
  - f80a77a v1 specs/steering を v1-archive/ に退避

  成果物

  - v1 退避: .kiro/specs/v1-archive/ 8 spec、.kiro/steering/v1-archive/ 4 file、v1-archive/ ルート v1 実装
  - v2 steering: .kiro/steering/{product,tech,structure,roadmap}.md 642 行
  - v2 brief: .kiro/specs/rwiki-v2-*/brief.md 8 ファイル 647 行
  - v2 requirements: .kiro/specs/rwiki-v2-*/requirements.md 8 ファイル、120 Requirement / ~821 acceptance criteria
  - 全 spec とも approvals.requirements.approved = false で人間レビュー待ち

  残件

  - docs/Rwiki-V2-dev-log.md に本会話の続き（/kiro-steering 議論部分）が未コミット
  - 本会話を更に追記する可能性があれば新セッション開始時にまとめてコミット可

  新セッション開始時の推奨アクション

  - dev log の追記を最初にコミット（または続けて追記してから一括コミット）
  - /kiro-steering を起動時 context に「v1-archive/ は除外」と明示して Sync mode 実行
    - 結果は additive 提案のみなので、内容を確認してから受け入れ判断
  - その後、Spec 0 (rwiki-v2-foundation) の requirements.md レビューに進む
    - 14 Requirement / ~85 criteria
    - 規範 spec として最初に approve すれば後段が動かしやすい
  - Spec 0 approve → 残り 7 spec を順次 or 並列レビュー → 全 spec approve 後に design phase 起票

  お疲れ様でした。
```

#####  ❯ 8 spec の requirements.md レビュー → 順次 approved=true に更新までを確実に行いたい。今回は手動で行うのが良いと思うが、手順が煩雑。サポートして

```
⏺ レビューフローをサポートする手順を提案します。「ユーザーがレビュー判断、私が機械的作業」の役割分担で煩雑さを軽減します。

  役割分担

  - ユーザー: requirements.md の内容を読んで approve / 修正の判断
  - 私: spec の要点抽出、修正の Edit 適用、spec.json 更新、進捗追跡、最終コミット

  推奨フロー（dependency 順）

  レビュー順は dependency wave 順（Wave 1 → 7）が妥当。基盤が固まれば下流の判断が早くなる。

  順序:

  - Spec 0: rwiki-v2-foundation（14 R / ~85 criteria）
  - Spec 1: rwiki-v2-classification（14 R / 92 criteria）
  - Spec 4: rwiki-v2-cli-mode-unification（14 R / 98 criteria）
  - Spec 7: rwiki-v2-lifecycle-management（14 R / 96 criteria）
  - Spec 5: rwiki-v2-knowledge-graph（23 R / 174 criteria, 最大）
  - Spec 2: rwiki-v2-skill-library（14 R / 74 criteria）
  - Spec 3: rwiki-v2-prompt-dispatch（12 R / 72 criteria）
  - Spec 6: rwiki-v2-perspective-generation（15 R / ~130 criteria）

  1 spec あたりのプロセス（4 step）

  各 spec で以下を回します。

  - Step 1: 私が当該 spec の Requirement タイトル一覧 と cross-spec review で指摘された懸念 を提示
    - ユーザーは「全部読む」「気になる Req だけ詳細を見る」「approve」のいずれかを選択
  - Step 2: ユーザーが「Req X の詳細を見たい」と言えば、私が該当箇所を Read で抽出して提示
  - Step 3: 修正指示があれば私が Edit で適用、コミットメッセージは spec ごとにまとめる
  - Step 4: approve 判定なら私が spec.json を更新（approvals.requirements.approved = true、updated_at 更新、phase = "requirements-approved"）

  私が提供するサポート機能

  - 要点抽出: spec の Requirement 一覧、Boundary Context、主要 acceptance criteria を箇条書きで提示
  - クロスリファレンス: 該当 spec が他 spec とどう coordination しているか即提示
  - 修正の機械的適用: ユーザーが「Req X の文言を Y にして」と言えば即 Edit
  - spec.json 更新: 1 コマンドで approve（コマンド例下記）
  - 進捗追跡: 各 spec の状態（未着手 / レビュー中 / approve 済 / 修正中）を会話内で常時表示

  spec.json 更新コマンド（私が実行）

  python3 -c "
  import json
  from pathlib import Path
  from datetime import datetime, timezone, timedelta

  JST = timezone(timedelta(hours=9))
  p = Path('.kiro/specs/<feature-name>/spec.json')
  data = json.loads(p.read_text())
  data['approvals']['requirements']['approved'] = True
  data['updated_at'] = datetime.now(JST).isoformat(timespec='seconds')
  data['phase'] = 'requirements-approved'
  p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n')
  "

  進捗追跡（会話内テーブル形式の代替: 箇条書き）

  各 spec のステータスを以下のシンボルで追跡:

  - ⬜ 未着手
  - 🔍 レビュー中
  - ✏️ 修正適用中
  - ✅ approve 済

  私が応答末尾に「現在: ⬜⬜⬜⬜⬜⬜⬜⬜（0/8 完了）」のような形で常時表示します。

  レビュー観点のチェックリスト（ユーザー判断の補助）

  各 spec で確認すべきポイント:

  - Requirement の網羅: brief.md の Scope.In 全項目がカバーされているか
  - EARS 形式の妥当性: trigger / system / response が明確か
  - 境界の明示: Boundary Context / Out of Boundary が他 spec と重複・隙間なく分割されているか
  - Coordination の記録: 他 spec との coordination が Requirement として明文化されているか
  - subagent の指摘事項: 各 wave で subagent が「気になる境界」と報告した項目への対応
  - CLAUDE.md ルール準拠: 表が最小化されているか、長文が表外にあるか
  - 日本語: 全ての acceptance criteria が日本語で書かれているか

  一括コミット戦略

  - 個別コミット: 各 spec approve ごとに 1 コミット → 履歴が細かい、rollback が spec 単位
  - バッチコミット: 全 8 spec approve 後にまとめて 1 コミット → 履歴が簡潔、rollback は all-or-nothing
  - ハイブリッド: 修正なしで approve なら一括、修正ありなら個別

  私の推奨は ハイブリッド:

  - 修正なしの spec は spec.json 更新のみ → 最後にバッチコミット
  - 修正ありの spec は requirements.md 更新 + spec.json 更新 → spec ごとに個別コミット

  ロードマップ更新

  全 8 spec approve 後:

  - .kiro/steering/roadmap.md の ## Specs (dependency order) の - [ ] を - [x] に変更（8 件）
  - ただしレビュー approved だけでは spec 完成ではない（design / tasks / impl が残る）ので、roadmap 上は別マーク使う方が正確かも
    - 案 A: [ ] のまま（approve はマイルストーンではない、impl まで完了で [x]）
    - 案 B: [~] 等の中間マークで「requirements approved」を表現（kiro 標準ではない）
    - 案 C: roadmap.md は [x] を impl 完了専用とし、approve ステータスは spec.json で追跡
  - 推奨: 案 C（roadmap は最終完了マーク、進捗詳細は spec.json）

  一時保留オプション

  - レビューが長くなる場合、各 spec のレビュー開始時に「Spec X 開始、現状 approved N/8」を私が表示
  - ユーザーが途中中断する場合、現状を会話末尾でまとめれば次セッションで再開可能

  ---
  今すぐ Spec 0 のレビューを開始しますか？

  開始するなら、私から Spec 0 の Requirement タイトル 14 件 + 懸念 3 件 を提示します。ユーザーは「全部読む / 気になる Req のみ詳細 /approve」を選択してください。
```

##### ❯ レビュー手順はこれでOK.しかし、その前に、積み残しだった、Important6件を先に詰めておくべきか、あるいは、レビュー段階で検討しても問題ないか？

```
⏺ レビュー段階で検討して問題ありません。むしろレビュー時の方が context が新鮮で効率的です。

  Important 6 件の分類

  要件レベルの判断 vs 設計レベルの判断で分けると、対処タイミングが見えます。

  レビュー段階で詰めるのが効率的な 3 件（要件レベル）

  - I-2: 対話ログ自動保存の責任分担（Spec 4 vs Spec 6）
    - 「誰が保存責務を持つか」は要件レベルの境界判断
    - Spec 4 と Spec 6 のレビュー時に「Spec 6 が trigger を規定、Spec 4 が保存実装を所管」など確定
    - 対象 Edit: 該当 Requirement の文言調整（軽微）
  - I-4: merge (wiki) --auto の許可・禁止判定
    - Spec 4 の --auto 許可リスト / 禁止リストに含めるかは要件レベルの方針
    - Spec 4 と Spec 7 のレビュー時に「許可リストに条件付きで追加」または「禁止リストに追加」を確定
    - 対象 Edit: Spec 4 Req 3.2 と Spec 7 Req 6.6 の文言調整
  - I-5: Skill lifecycle の Backlink 走査範囲
    - AGENTS/** を含めるかは要件レベルの方針
    - Spec 7 と Spec 2 のレビュー時に確定
    - 対象 Edit: Spec 7 Req 9.3 / 11.6 の走査範囲明示

  design phase に持ち越し可能な 3 件（設計レベル）

  - I-1: /mute maintenance 永続化媒体（.rwiki/config.toml か ~/.rwiki/）
    - 媒体決定は実装詳細、要件レベルでは「Spec 4 所管」で十分
    - Spec 4 design phase で確定
  - I-3: HTML 差分マーカー attribute 詳細（target / reason 等）
    - 要件レベルでは「対の必須性」「Spec 7 と整合」で十分
    - Spec 2 と Spec 7 の design phase で coordination
  - I-6: Foundation の subject = the Foundation を testable にする方法
    - テスト戦略は設計レベル
    - Spec 0 design phase で「doc-link presence check」「heading 構造 check」「用語 grep」等を確定

  レビュー時の意識ポイント

  各 spec のレビュー開始時に、私が「この spec に関連する Important」を提示します。具体例:

  - Spec 4 レビュー時: I-2（対話ログ）+ I-4（merge --auto）+ I-1（mute 永続化、ただし design 持ち越し可）
  - Spec 6 レビュー時: I-2（対話ログ）
  - Spec 7 レビュー時: I-4（merge --auto）+ I-5（Backlink 走査）+ I-3（HTML マーカー、ただし design 持ち越し可）
  - Spec 2 レビュー時: I-5（Backlink 走査、AGENTS/skills 配置）+ I-3（HTML マーカー、ただし design 持ち越し可）
  - Spec 0 レビュー時: I-6（Foundation testability、ただし design 持ち越し可）

  進め方の推奨

  - レビュー段階で I-2 / I-4 / I-5 を確定: 該当 spec のレビュー時に判断、私が即 Edit
  - I-1 / I-3 / I-6 は design phase メモ化: roadmap.md または各 spec の design.md 起票時に渡す TODO list として保持
  - 過剰な事前検討は不要: Important 6 件すべてを「先に詰める」と本セッション/次セッションで議論が膨らむ。レビューと並行で吸収する方が早い

  design phase への引き継ぎ方法

  I-1 / I-3 / I-6 を design phase に確実に渡すための仕組み:

  - オプション A: roadmap.md の Coordination セクションに「Design phase 持ち越し」項目として追記
  - オプション B: 各 spec の brief.md の Coordination セクションに追記
  - オプション C: 新ファイル .kiro/specs/_design-phase-todos.md を作って一元管理
  - 推奨: オプション B（各 spec に紐付くので design phase 起票時に自動参照される）

  レビュー後、未解消の Important を該当 spec の brief.md に追記すれば、design phase 起票時に subagent が読み込みます。

  ---
  要約: Important 6 件は「先に詰める」必要なし。レビュー段階で 3 件（I-2/I-4/I-5）を吸収し、3 件（I-1/I-3/I-6）は design phase 持ち越しで brief.mdに追記するのが効率的です。
```

##### SESSION-CONT

```
⏺ TODO_NEXT_SESSION.md を v2 用に書き換えます。
⏺ セッション継続準備完了。

  完了状況

  - git status: クリーン
  - origin/main 同期: 完了（ahead 0、本セッションの 10 コミット全てが push 済）
  - TODO_NEXT_SESSION.md: 9.5 KB で更新済（gitignore 対象、ローカルのみ保持）
  - dev log: コミット済 0d1f999、push 済

  次セッション開始時のガイドライン

  新セッションを開く際、最初に以下を実行してください。

  1. コンテキスト復元

  新セッションで Claude に最初に伝えるメッセージ案:

TODO_NEXT_SESSION.md を読んでください。8 spec の requirements レビューを Spec 0 から開始します。dependency 順、4 step 手順、Important該当項目を意識してください。Spec 0 の Requirement 一覧と要点を提示してください。

  2. レビュー実行手順

  各 spec で 4 step を回す。

  - Step 1: Claude が Requirement タイトル一覧 + cross-spec review 懸念 + Important 該当項目を提示
  - Step 2: ユーザーが「全部読む / 気になる Req のみ詳細 / approve」を選択
  - Step 3: 詳細確認時、Claude が該当 Requirement を Read で抽出
  - Step 4: 修正があれば Edit、approve なら spec.json 更新

  3. レビュー順（dependency 順）

  - Spec 0 → Spec 1 → Spec 4 → Spec 7 → Spec 5 → Spec 2 → Spec 3 → Spec 6

  4. Important 6 件の対処

  - 要件レベル（レビュー時に詰める）: I-2（対話ログ責任分担）、I-4（merge --auto）、I-5（Backlink 走査範囲）
  - 設計レベル（design phase 持ち越し）: I-1（mute 永続化）、I-3（HTML マーカー attribute）、I-6（Foundation testability）

  5. レビュー方針（dev log 末尾より）

  - これまでとは異なる視点
  - 本質的な観点
  - 全体俯瞰での齟齬チェック
  - 文書間の矛盾チェック

  6. コミット戦略

  - 修正なし approve: spec.json 更新のみ → 最後にバッチコミット
  - 修正あり approve: requirements.md + spec.json → spec ごとに個別コミット
  - 全 8 approve 後に push

  ---
  セッション区切りの準備は整いました。新セッションで TODO_NEXT_SESSION.md を最初に読み込めば、本セッションのコンテキストを失わずに Spec 0のレビューから即座に始められます。お疲れ様でした。
```



------

## Spec 0 (rwiki-v2-foundation) 

##### ❯ TODO_NEXT_SESSION.md を読んでください。8 spec の requirements レビューを Spec 0 から開始します。dependency 順、4 step 手順、Important該当項目を意識してください。Spec 0 の Requirement 一覧と要点を提示してください。

```
⏺ Spec 0 (rwiki-v2-foundation) の概況を提示します。

  Spec 0: rwiki-v2-foundation

  - 位置付け: v2 の傘 spec、Spec 1-7 が参照する SSoT（規範文書）
  - Requirement 数: 14 / 想定 acceptance criteria 数: 約 85
  - 特性: CLI 実装 spec ではなく、規範文書群（Foundation）が満たす記述要件として全 criterion が記述されている
  - Subject 統一: the Foundation または the Rwiki v2 Foundation document

  Requirement 一覧（14 件）

  - R1: ビジョンと中核価値（Trust+Graph+Perspective+Hypothesis 四位一体、Curated GraphRAG 位置付け、6 信念）
  - R2: 3 層アーキテクチャ（L1 Raw / L2 Graph Ledger / L3 Curated Wiki、横断要素、データフロー、L2 ledger 正本性）
  - R3: 13 中核原則と層別適用マトリクス（§2.1〜§2.13、4 区分の適用度、§2.12 / §2.2 優先関係、§2.10 のみ全層貫通）
  - R4: §2.12 Evidence-backed Candidate Graph の優先関係（L2 専用、§2.2 / §2.4 への優先、reject-only filter 根拠）
  - R5: Edge status 6 種 / Page status 5 種 / Hypothesis status 7 種の独立 3 軸定義
  - R6: コマンド 4 Level 階層（L1 発見 / L2 判断 / L3 メンテ LLM ガイド / L4 Power user）+ エディタ責務分離
  - R7: 用語集 5 分類（基本 / アーキテクチャ / Graph Ledger / Perspective-Hypothesis / Operations）
  - R8: Frontmatter スキーマの上位規範（共通必須 / 推奨、wiki / review / skill / vocabulary / follow-up / hypothesis / perspective 骨格、Spec 1
  へ詳細委譲）
  - R9: Task & Command モデルの一覧化（実行 3 モード、フラグ詳細は Spec 4 以降委譲）
  - R10: Spec 1-7 が参照する SSoT 性（Adjacent Spec Synchronization 運用、依存順）
  - R11: 実装独立性と運用前提（LLM/エディタ非依存、Python 3.10+、.hygiene.lock 境界）
  - R12: §2.13 Curation Provenance（what + why 二層、decision_log.jsonl の自動記録対象、§2.10 との直交関係）
  - R13: §2.6 Git + 層別履歴媒体（L1 = Git log / L2 = edge_events.jsonl / L3 = update_history:、reject 必須フィールド）
  - R14: 文書品質と SSoT 整合性（日本語、表最小化、SSoT v0.7.12 章番号整合、design phase への境界引き継ぎ）

  本 spec で意識すべき項目

  Important（design 持ち越し）

  - I-6: Foundation の subject = the Foundation を testable にする方法 が未定
    - 今回のレビューでは「design phase 持ち越し」として brief.md の Coordination セクションに追記する方針
    - 規範文書ゆえに「文書 X が Y を含む」を verifiable にする手段（例: 章節アンカー / 機械検証スクリプト）を design で詰める

  subagent 境界懸念

  - Foundation Boundary subject 統一の妥当性: 全 14 Req が the Foundation を subject としており、CLI 系 spec の testability と差がある（design
  持ち越し可）
  - Frontmatter スキーマ骨格 (R8) と Spec 1 の所管境界: M-1 として識別済、design phase で再確認

  Cross-spec review で修正済（参考）

  - M-4: Spec 0 と brief の Page status を 4 種 → 5 種 に統一（active / deprecated / retracted / archived / merged、R5.2 で確認可能）

  レビュー観点チェックリスト適用状況（一次所見）

  - brief.md Scope.In カバー: 8 項目すべてが R1〜R8 にマップされている見込み
  - EARS 形式: shall / Where / While / If…then / When を使い分けており、規範文書要件としては妥当
  - 境界明示: Boundary Context の Out of scope に Spec 1/4/5/6/7 の所管が明記
  - Coordination 記録: R10（SSoT 性）/ R14（Adjacent Spec Synchronization）に集約
  - CLAUDE.md 準拠: 表は使用なし、全文箇条書き / 段落、日本語

  Step 2: 進め方の選択

  次のいずれかをご指示ください。

  - A) 全部読む: 14 Req すべてを順に詳細確認（Edge / Page status の R5、frontmatter R8、SSoT R10 等の長めの Req は重点）
  - B) 気になる Req のみ詳細: 番号指定（例: 「R3, R5, R8 を詳細」）
  - C) approve: 修正なしで承認 → spec.json 更新 + I-6 を brief.md Coordination に追記
  - D) その他: レビュー観点を絞った確認（例: 「subject testability 観点で R1〜R14 を横断チェック」「Spec 1-7 との境界整合のみ」など）
```

#####  ❯A

```
⏺ 全 14 Req を詳細レビューします。まず整合性チェックの根拠として steering と他 spec の brief を確認します。
⏺ 全 14 Req を要件本文・brief.md・steering 3 ファイル横断で精読しました。以下、本質的観点の所見を Req 番号順に提示します（OKのみは省略、懸念あり項目を中心に）。

  R1: ビジョンと中核価値

  - R1.6 の 6 信念: product.md §設計信念 と概ね一致（表現揺れ「first-class」/「裏付ける」は許容）
  - R1.4 5 軸対比（起点・主体・品質・用途・知識の時間変化）: product.md §Curated GraphRAG 位置付け と完全一致
  - OK

  R2: 3 層アーキテクチャ

  - 【最重要・本質的指摘 A】R2.3 の構成ファイル列挙に decision_log.jsonl が欠落
    - 列挙は 6 ファイル: entities.yaml / edges.jsonl / edge_events.jsonl / evidence.jsonl / rejected_edges.jsonl / reject_queue/
    - R12 で decision_log.jsonl を「curator の WHY を保全」と規範化しているのに、L2 構成要素として列挙されていない
    - SSoT 内部の不整合。下流 spec が「decision_log がどこに置かれるか」を Foundation から特定できない
  - structure.md の .rwiki/graph/ 配下にも decision_log.jsonl が無い → 同じ欠落が steering にも波及

  R3: 13 中核原則と層別適用マトリクス

  - R3.5 の主張: 「§2.10 Evidence chain のみが全層を貫く唯一の不変原則」
    - 強い主張だが、R12 で §2.13 Curation Provenance を「§2.10 と直交（縦軸 vs 横軸）」と整理しており、矛盾しない
    - 「縦軸の不変性」と読み替えれば妥当
  - OK

  R4: §2.12 優先関係

  - §2.12 の L2 専用性、§2.2 / §2.4 への優先、reject-only filter の根拠（§1.3.2 引用）— roadmap.md "Approach Decision" と完全整合
  - OK

  R5: status 3 軸の独立

  - R5.2 Page status 5 種: structure.md L140 と一致（M-4 修正反映済確認）
  - R5.4 Hypothesis status 7 種: 列挙は OK。evolved の遷移は Spec 6 所管（M-2、Minor）として Foundation 範囲外で妥当
  - OK

  R6: コマンド 4 Level 階層

  - 【中・指摘 B】R6.2 の L1 発見コマンド例に rw discover が無い
    - R9.1 の Task 一覧に discover が含まれている
    - R6 と R9 で discover の Level 位置付けに揺れがある
    - 対処案: R6.2 に rw discover を追記、もしくは「discover task は Level X」を R6 内で位置付ける
  - R6.1 「L4 Power user / CI」: 並記が曖昧（CI 用は別 level か）。本質的問題ではないが、構造.md の「全コマンド直接」と表現を揃える余地あり

  R7: 用語集 5 分類

  - 【低・指摘 C】R7.4 で「Hypothesis status」が Graph Ledger 用語に分類
    - R5.4 で Hypothesis status は Page/Edge と独立した第 3 軸として定義
    - 自然な配置は R7.5 Perspective-Hypothesis 用語
    - 対処案: R7.4 から削除し、R7.5 に追加

  R8: Frontmatter スキーマ上位規範

  - 【最重要・本質的指摘 A の再発】R8.5 の core schema 5 ファイルにも decision_log.jsonl が欠落
    - R2.3 と同じ問題が R8.5 でも発生
    - R12 との内部矛盾が二箇所で生じている
  - 【低・指摘 D】R8.4 のスキーマ骨格 7 種列挙の網羅性
    - 列挙: Review レイヤー固有 / Skill ファイル / Skill candidate / Vocabulary candidate / Follow-up / Hypothesis candidate / Perspective 保存版
    - structure.md の review/ 配下には synthesis_candidates / audit_candidates / relation_candidates も存在
    - 「Review レイヤー固有」が傘表現なら明示、そうでなければ列挙拡張が必要

  R9: Task & Command モデル

  - 【中・指摘 B 関連】R9.1 の discover の Level 位置付け不明
    - R6 と R9 の整合
  - OK（カテゴリ 15 種は consolidated-spec §6 と整合の見込み）

  R10: SSoT 性

  - R10.6 の依存順表記: 「Spec 0 → 1 → {4, 7} → 5 → 2 → 3 → 6」
    - roadmap.md L37 で Spec 7 は Spec 4 に直接依存していない（依存先は foundation, classification のみ）
    - 中括弧 {4, 7} は「並列可能」の意。roadmap.md と整合
    - TODO_NEXT_SESSION.md の Spec 0 → 1 → 4 → 7 → 5 → 2 → 3 → 6 表記とは表現揺れだが実質同じ。OK

  R11: 実装独立性

  - networkx ≥ 3.0、Python 3.10+、.rwiki/.hygiene.lock の Spec 4↔Spec 5 境界 — roadmap.md と完全整合
  - R11.7 reject_reason_text の空文字禁止: roadmap.md L30 と整合
  - OK

  R12: Curation Provenance

  - §2.13 二層化、decision_log.jsonl の役割、§2.10 との直交関係 — 規範として妥当
  - ただし指摘 A により R2.3 / R8.5 と整合させる必要

  R13: §2.6 Git + 層別履歴媒体

  - L1 = Git log / L2 = edge_events.jsonl / L3 = update_history: — structure.md と整合
  - OK

  R14: 文書品質と SSoT 整合性

  - R14.5 で「14 個の Requirement」を自己参照 — 整合
  - R14.3「章立て番号を SSoT と整合」: design phase で I-6（subject testability）と組み合わせる材料になる
  - OK

  まとめ：要修正項目

  優先度順に整理します。

  【高】要件レベル修正（approve 前）

  - 指摘 A: decision_log.jsonl の所在を R2.3 と R8.5 に追加
    - R2.3: L2 Graph Ledger 構成ファイルに decision_log.jsonl を追加（7 ファイルへ）
    - R8.5: core schema を 5 → 6 ファイルに拡張、もしくは「core schema 5 + decision_log.jsonl」と二層化
    - structure.md にも波及反映が必要（.rwiki/graph/ 配下に追加）

  【中】要件レベル修正（approve 前）

  - 指摘 B: rw discover の Level 位置付けを R6 で明示、または R6.2 に追記
  - 指摘 C: R7.4 から「Hypothesis status」を削除し R7.5 に移動

  【低】要件レベル修正（approve 前）

  - 指摘 D: R8.4 のスキーマ骨格列挙の網羅性を「傘表現」と明示、もしくは列挙拡張
  - OK

  まとめ：要修正項目


  優先度順に整理します。

  【高】要件レベル修正（approve 前）

  - 指摘 A: decision_log.jsonl の所在を R2.3 と R8.5 に追加
    - R2.3: L2 Graph Ledger 構成ファイルに decision_log.jsonl を追加（7 ファイルへ）
    - R8.5: core schema を 5 → 6 ファイルに拡張、もしくは「core schema 5 + decision_log.jsonl」と二層化
    - structure.md にも波及反映が必要（.rwiki/graph/ 配下に追加）

  【中】要件レベル修正（approve 前）

  - 指摘 B: rw discover の Level 位置付けを R6 で明示、または R6.2 に追記
  - 指摘 C: R7.4 から「Hypothesis status」を削除し R7.5 に移動

  【低】要件レベル修正（approve 前）

  - 指摘 D: R8.4 のスキーマ骨格列挙の網羅性を「傘表現」と明示、もしくは列挙拡張

  【低・design 持ち越し】

  - I-6: Subject the Foundation の testability — brief.md Coordination セクションに追記

  Step 4 への進行確認

  次の選択肢をご指示ください。

  - a) 指摘 A〜D すべて修正 → requirements.md edit + I-6 を brief.md 追記 + spec.json approve（structure.md 反映は別 PR にするか同梱するか別途判断）
  - b) 指摘 A のみ修正、B/C/D は別途議論
  - c) 一部のみ修正（番号指定）
  - d) 修正なしで approve（指摘は dev-log に残すのみ）
  - e) 私のレビューを再検討したい指摘番号がある（例: 「指摘 A は decision_log を別文書に置く設計を想定しているので不要」など）
```

#####  ❯ a)で対応、その後に指摘することがある。

```
⏺ 指摘 C を一点撤回します — R7.5 を再確認したところ「Perspective-Hypothesis 用語」リストに Hypothesis status がすでに含まれており、R7.4 (Graph Ledger
   用語) には入っていませんでした。私の誤読です。指摘 C は不要、修正対象外とします。
  修正対象は 指摘 A / B / D + I-6 brief.md 追記 + structure.md 波及修正 に確定します。実施します。
⏺ structure.md にも decision_log.jsonl を追加します（Spec 0 修正の波及同期、Adjacent Spec Synchronization の対象）。
⏺ 修正実施完了です。spec.json approve は追加指摘待ちのため未実施です。

  適用した修正

  requirements.md（4 箇所）

  - R2.3: L2 Graph Ledger 構成ファイルに decision_log.jsonl を追加（6 → 7 ファイル列挙）
  - R8.5: core schema を 5 → 6 ファイル化、evidence.jsonl に「§2.10 trust chain 縦軸」、decision_log.jsonl に「§2.13 curation provenance
  横軸」を併記して直交関係を明示
  - R6.2: L1 発見コマンド例に rw discover を追加、R9.1 task との対応を明示
  - R8.4: Review レイヤー固有の対象範囲を「review/*_candidates/ 全般（synthesis / audit / relation 等を含む）」と傘表現に拡張、candidate
  サブディレクトリの完全列挙を Spec 1 に委譲する旨を明示

  brief.md（1 箇所）

  - 新設「Coordination」セクション に I-6（Foundation subject の testability）を design phase 持ち越しとして追記、検証手段候補と R14.3 との関連を明記

  structure.md（1 箇所、Adjacent Spec Synchronization）

  - .rwiki/graph/ 配下に decision_log.jsonl を追加、evidence.jsonl / decision_log.jsonl の§参照コメントを併記

  撤回した指摘

  - 指摘 C: R7.5 を再確認したところ既に Hypothesis status が含まれており、私の誤読でした。修正不要。

  追加の指摘をどうぞ。
```

#####   ❯ docs/キュレートプロセス可視化.mdの議論がスペックに正しく反映されているか？

```
⏺ 「キュレートプロセス可視化.md」の議論を Spec 0 に対して 1 対 1 でチェックしました。主要な規範化（§2.13 = R12, decision_log.jsonl の所在 = 修正済
  R2.3/R8.5, 直交関係 = R12.5）は反映済ですが、用語集・コマンドカタログ・Review 骨格に欠落ありです。

  反映済（OK）

  - §2.13 Curation Provenance の規範化 → R12 全 6 criteria で網羅
  - what + why 二層 → R12.1
  - evidence.jsonl (WHAT) vs decision_log.jsonl (WHY) の直交 → R12.2 / R12.5（§2.10 縦軸 vs §2.13 横軸）
  - 3 核心ルール (Selective / Append-only / Selective privacy) → R12.3
  - decision_log.jsonl の物理位置 → R2.3 / R8.5（先ほどの修正で追加済）
  - 詳細スキーマは Spec 5 委譲 → R12.6
  - §2.13 を 13 原則の 13 番目として固定 → R3.1
  - 用語集に "Curation provenance" / "Decision log" → R7.4

  未反映（指摘事項）

  【高・指摘 E】R9.2 Command カテゴリに Decision log カテゴリが欠落

  - 元ドキュメント: rw decision history / recent / stats / search / contradictions / render の 8 種コマンド群 が Spec 4 / Spec 5 で新設される
  - R9.2 の現行カテゴリ（コア / Input Pipeline / Knowledge Generation / Approval / Query / Audit / L2 Graph Ledger 管理 / Edge 個別操作 /
  Entity-Relation 抽出 / Reject workflow / Page Lifecycle / Tag Vocabulary / Skill Library / Follow-up / Vault 管理）の 15 カテゴリに「Decision Log /
   Curation Provenance」が独立カテゴリとして無い
  - 「Query」や「L2 Graph Ledger 管理」に内包させる暗黙設計か、独立カテゴリにするかは Foundation の SSoT として明示が必要
  - 対処案: R9.2 の列挙に「Decision Log / Curation Provenance」カテゴリを追加（一行説明で rw decision * 系を統括する旨）

  【高・指摘 F】R7.4 の用語集で 4 用語が欠落

  - 元ドキュメント「用語集 §4.3 に 6 語追加」: Curation provenance / Decision log / Decision type / Selective recording / Decision visualization Tier
   1-5 / Context ref
  - R7.4 に含まれているのは前 2 語のみ
  - 残り 4 語（Decision type / Selective recording / Decision visualization / Context ref）が欠落
  - 特に Selective recording は R12.3 の「3 核心ルール」の一つで規範本文には登場するのに用語集に無い → SSoT として不整合
  - 対処案: R7.4 に上記 4 用語を追加。なお Decision visualization は Spec 4 / Spec 5 所管寄りだが、Foundation 用語集に登録して spec 横断の参照を担保

  【中・指摘 G】Review レイヤーの review/decision-views/ が欠落

  - 元ドキュメント: 「新 review 層 review/decision-views/」（Tier 2 markdown timeline 出力先）
  - R8.4 の Review レイヤー骨格列挙にも、structure.md の review/ 配下にも未記載
  - 先の R8.4 修正で「review/*_candidates/ 全般」と傘表現にしたが、decision-views/ は _candidates 命名規則の外にあるためカバーされない
  - 対処案:
    - R8.4 を「review/*_candidates/ 全般 + review/decision-views/」と二系統で表現
    - structure.md の review/ 配下に decision-views/ を追加

  【中・指摘 H】R12.4 の自動記録対象の網羅性

  - 元ドキュメントの 8 trigger と R12.4 の現行記述の対応:
    - 境界決定（confidence 0.45 ± 0.05） → R12.4「境界決定」 ✅
    - Contradiction 検出 → R12.4「矛盾検出」 ✅
    - 人間 reject / approve → R12.4「人間 approve・reject」 ✅
    - Hypothesis verify → R12.4「Hypothesis verify」 ✅
    - Hygiene status 遷移 → R12.4「Hygiene による status 遷移」 ✅
    - Synthesis 作成 → R12.4「synthesis 操作」 ✅
    - 記録しない側: routine extraction (高 confidence) / routine decay-reinforcement → R12.4「routine extraction や routine decay
  は記録しない」で反映 ✅
  - 概ね対応している。ただし「人間 merge・split」の追加は元ドキュメントには無く、R12.4 で先行拡張されている形（lifecycle-management 由来か）
    - これは矛盾ではなく 規範拡張だが、Spec 7 (lifecycle-management) との整合性確認が望ましい

  【低・参考】可視化 Tier 1-5 の MVP 区切り

  - 元ドキュメント: Tier 1-3 を MVP、Tier 4-5 を Phase 2
  - これは実装範囲の話で Foundation の SSoT 範疇外。Spec 4 / Spec 5 brief.md または roadmap.md で確認すべき項目
  - Spec 0 では対応不要

  修正提案

  - a) 指摘 E / F / G 全て修正（H は確認のみ、Spec 7 レビュー時に再確認）
  - b) E / F のみ修正、G は Spec 1 レビュー時に持ち越し
  - c) カスタム指定
```

#####  ❯ a)で対応

```
⏺ 指摘 E / F / G を修正します。
⏺ 修正完了です。

  適用した修正（指摘 E / F / G）

  requirements.md（3 箇所）

  - R9.2 (指摘 E): Command カテゴリに 「Decision Log（Curation Provenance、rw decision history / recent / stats / search / contradictions / render
  等を統括）」 を 16 番目のカテゴリとして追加
  - R7.4 (指摘 F): Graph Ledger 用語に 「Decision type / Selective recording / Decision visualization（Tier 1-5）/ Context ref」 の 4
  用語を追加（既存の Curation provenance / Decision log と並ぶ）
  - R8.4 (指摘 G): Review レイヤー骨格に 「review/decision-views/（Decision log の Tier 2 markdown timeline 出力先、_candidates 命名規則の対象外）」
  を二系統目として明示

  structure.md（1 箇所、Adjacent Spec Synchronization）

  - review/ 配下に decision-views/ を追加、コメントで「Tier 2 markdown timeline（§2.13）」と用途明示

  残件

  - 指摘 H（中）: R12.4 の「人間 merge・split」拡張は Spec 7 lifecycle-management レビュー時に整合性確認
  - 元 docs の論文 outline / categorical roadmap への反映は Spec 0 範疇外、別途確認

  追加の指摘をどうぞ。なければ次は spec.json の approve に進みます。
```

##### ❯ roadmap.md, brief.mdを照合して、厳しく精査

```
⏺ roadmap.md / brief.md / requirements.md の三角照合を厳しく実施しました。4 件の指摘（うち 1 件は明確な誤記）を検出しました。

  精査の手順

  - brief.md（70 行、Scope/Out/Boundary/Coordination/Constraints/Touchpoints）
  - roadmap.md（210 行、Approach Decision/Constraints 8 項目/Specs 依存順/MVP/v1 継承事項/Governance）
  - requirements.md（修正後の Boundary Context / R10.1〜R10.6 / R11.1〜R11.7 / R14）
  - これらを 3 軸全マッピング、矛盾と欠落を抽出

  検出した指摘

  【最重要・指摘 L】brief.md L19 で Page status「4 種」のまま（明確な誤記）

  - TODO_NEXT_SESSION.md L42 で「M-4: Spec 0 と brief の Page status 4 種 → 5 種」が修正済と記録されているが、brief.md Desired Outcome
  部分が未修正で残存
  - 該当行: 用語の不統一を防ぐ（Edge status 6 種 vs Page status 4 種の混同等）
  - requirements.md R5.2 / structure.md L140 / R7.4 はすべて 5 種に統一済
  - 対処: 4 種 → 5 種、即修正

  【高・指摘 K】brief.md Out of Boundary に Spec 6 / Spec 7 が欠落

  - brief.md Out of Boundary (4 項目): Spec 1 / Spec 5 / Spec 4 / Spec 2-3
  - requirements.md Boundary Context Out of scope (6 項目): Spec 1 / Spec 5 / Spec 4 / Spec 2-3 / Spec 7 (Page lifecycle 操作) / Spec 6
  (Perspective/Hypothesis 生成ロジック)
  - brief 起票時の境界整理に 2 spec 分の漏れ
  - requirements 側は subagent dispatch で適切に補完されているが、brief は SSoT として未同期
  - 対処: brief.md Out of Boundary に 2 項目追加

  【中・指摘 I】brief.md Constraints が roadmap.md Constraints と乖離

  - roadmap.md Constraints: 8 項目（フルスクラッチ / LLM 非依存 / Python+networkx / Git / エディタ非依存 / L2 append-only JSONL / Concurrency lock /
  Reject 理由必須）
  - brief.md Constraints: 4 項目（フルスクラッチ / Python+Git+LLM CLI 非依存 / 層別適用 / §2.12 優先）
  - 欠落: エディタ非依存 / L2 append-only JSONL / Concurrency lock / Reject 理由必須
  - これらは requirements.md (R11.2 / R2.3 / R11.5 / R11.7 / R13.5) ではカバー済だが、brief レベルで漏れている
  - 一方、brief.md にあって roadmap.md にない「層別適用前提」「§2.12 L2 専用優先」は Spec 0 固有の内容で正当
  - 対処案: brief.md Constraints に「v2 全体の Constraints は roadmap.md が SSoT、ここでは Spec 0 固有のみ列挙」を一行追記し、現行 4 項目を Spec 0
  固有として明示。roadmap.md との関係を SSoT 構造として整理

  【中・指摘 J】「v1 を知らない前提」と「v1 から継承する技術決定」の整理不明確

  - brief.md Constraint: 「v1 を『知らない前提』で自己完結的に設計（§9.1 フルスクラッチ方針）」
  - roadmap.md L132: 「v1 から継承する技術決定。v2 spec 起草時に再議論不要、そのまま継承する」（Severity 4 水準 / Exit code 0/1/2 / LLM CLI timeout
  必須 / モジュール責務分割 / CLI 命名統一）
  - 一見矛盾だが、整理すると:
    - Foundation（規範文書）= 「v1 を知らない前提」OK: ビジョン・原則・用語は v2 でフルスクラッチ
    - roadmap.md（プロジェクト管理）= 「v1 実装決定は継承」OK: 技術的 detail は引き継ぐ
  - 整理は健全だが、brief.md / requirements.md でこの分離が明示されていない ため将来の読み手が混乱する可能性
  - 対処案: brief.md Coordination セクションに「v1 から継承される実装レベル技術決定（Severity / Exit code / Module split / CLI naming / LLM CLI timeout）は roadmap.md L132- が SSoT、Foundation の規範対象外」を一行追記

  矛盾なし（OK）項目

  - brief.md Scope.In 8 項目 → requirements.md R1-R8 / R12 / R13 にすべてマッピング済
  - brief.md Boundary Candidates 3 項目 → requirements.md Boundary Context と整合
  - brief.md Upstream/Downstream → roadmap.md L34 "Dependencies: none" と完全一致
  - brief.md Constraints「§2.12 L2 専用、§2.2/§2.4 より優先」→ requirements.md R4 で完全規範化済
  - brief.md Approach 章引用 §1〜§6 vs requirements.md R10.1 §1-6/§7.2 → 微妙な揺れあるが許容範囲

  修正提案

  - a) 指摘 L / K / I / J すべて修正
  - b) L (誤記) と K (Out of Boundary 漏れ) のみ修正、I / J は別途議論
  - c) L (誤記) のみ即修正、他は判断保留
  - d) カスタム指定

  ご指示ください。
```

##### ❯ a)で対応

```
⏺ 指摘 L / K / I / J を修正します。
⏺ 修正完了です。

  適用した修正（指摘 L / K / I / J）

  brief.md（4 箇所）

  - 指摘 L (Desired Outcome L19): Page status 4 種 → Page status 5 種（M-4 修正の取りこぼし解消）
  - 指摘 K (Out of Boundary): 6 項目化、追加した 2 項目:
    - Page lifecycle 操作の実装（deprecate / retract / archive / merge / split / rollback、Spec 7）
    - Perspective / Hypothesis 生成ロジックの実装（Spec 6）
  - 指摘 I (Constraints): SSoT 構造を明示
    - 冒頭に「v2 全体の Constraints は roadmap.md L22- が SSoT」と参照
    - Spec 0 固有制約として 4 項目を整理（フルスクラッチ自己完結 / 層別適用 / §2.12 優先 / §2.10⊥§2.13 直交関係）
    - 既存項目は Foundation 規範レベルに sharpening、Python 3.10+ / Git / LLM CLI 非依存 のような実装制約は roadmap 委譲
  - 指摘 J (Coordination): 新セクション「v1 から継承される技術決定の SSoT」を追加
    - Severity 4 水準 / Exit code 0/1/2 分離 / LLM CLI timeout 必須 / モジュール責務分割 / CLI 命名統一 は roadmap.md L132- 委譲を明示
    - 「v1 を知らない前提」と「v1 継承」の分離（Foundation = 規範、roadmap = 実装決定）を整理
    - I-6（既存）は Coordination 内の独立サブセクションへ整理

  残件・次の選択肢

  追加の指摘がなければ、Spec 0 の approve に進みます。次のステップ:

  - a) approve に進む: spec.json の approvals.requirements.approved = true + phase = "requirements-approved" + updated_at 更新 → 修正ありで approve
  のためコミット作成
  - b) 別の照合観点で精査続行（例: scenarios.md / consolidated-spec との照合、他 spec brief.md との Adjacent expectations 整合 など）
  - c) 他に指摘

  ご指示ください。
```

##### ❯ 本質的な観点からレビュー

```
⏺ これまでの「内部整合性」「他文書照合」とは違う視座で、Spec 0 という規範 spec の methodology そのものを問い直します。7つの本質的観点を、優先度順に提示します。

  観点 1（最も根本的）: 規範文書を spec として扱う methodology の testability 限界

  - I-6（design 持ち越し）として認識済の問題を、より根本的に問い直す
  - 全 14 Req の subject が the Foundation、述語が「shall ～を記述する／含める／明示する」
  - これは事実上 「Foundation 文書の目次の規範化」 であり、testable なのは「目次に項目が存在するか」のみ
  - 提案候補（章節アンカー / 文書 lint / link 切れ検出）はすべて
  「項目の存在」確認止まりで、「項目の内容が規範として正しく記述されているか」は誰も検証できない
  - 例: 「13 中核原則を §2.1〜§2.13 として定義する」を満たすには、文書に 13 個の章があれば passing するが、内容が誤っていても検出不能
  - 本質的問い: 規範文書を実装可能 spec の枠組みに無理に乗せていないか？ steering 強化 + Architecture Decision Records (ADR) の方が適合的では？
  - 方向性:
    - (a) このまま spec として進める（testability の弱さは受容）
    - (b) brief.md / requirements.md に「規範文書 spec の testability
  は『目次の存在チェック』に限定される。内容検証は人間レビューに委ねる」と明示し、design phase で過剰な検証手段に走らない方針を固定
    - (c) Spec 0 を解体し steering + ADR 構造に移行（roadmap への影響大、現時点で非現実的）

  観点 2: SSoT を称しながら違反検出機構が無い

  - R10 で「Spec 1-7 が SSoT として引用」「再解釈・再命名を行わない」と謳う
  - R10.4 で「Foundation 改版 → 個別 spec 反映」の順序は規範化
  - しかし 「Spec 1-7 が SSoT に違反したことを検出する仕組み」が要件化されていない
  - 結果、SSoT 違反は人間レビューに完全依存。Spec 1-7 が無自覚に独自定義を生やしても気付けない
  - 例: Spec 1 で Page status を 4 種に戻しても、自動検出されない（M-4 が手作業で修正されたのは偶然）
  - 本質的問い: SSoT は「定義の存在」だけでは機能しない。「引用の正しさ」を検証する仕組みまで含めて初めて SSoT
  - 方向性:
    - (a) Foundation の役割範囲外と割り切り、SSoT 違反検出は別 spec / 別 task として将来扱う
    - (b) 新 Requirement「SSoT 引用整合性検証」として追加。具体的には「Spec 1-7 で Foundation 用語を引用した箇所が Foundationの最新版と一致することを検証する手段（例: shared glossary file からの参照）」を design phase 持ち越しで規範化
    - (c) §2.13 Curation Provenance の応用として、Foundation 改版時の Adjacent Spec Synchronization を decision_log で追跡する仕組みを Foundation自身が要求

  観点 3: 「層別適用マトリクス」の具体値が requirements で固定されていない

  - R3.2「4 区分で明示する」は 形式の規範化のみ
  - 実際の各セル値（13 原則 × 3 層 = 39 セル）の具体値は要件外
  - 「§2.12 が L2 で完全適用 / L1 で該当しない / L3 で適用外」のような 規範の核心 が requirements に存在しない
  - design phase で初めて具体値が固定される構造
  - これは Spec 1-7 が requirements approve 後に Foundation 設計を待つ間、マトリクス具体値が未決定のまま Spec 1 開発が始まる可能性を意味する
  - 本質的問い: 規範の核心（39 セルの具体値）が要件レベルではなく設計レベルにあるなら、Spec 1-7 が要件起票時に Foundation を引用できないのでは？
  - 方向性:
    - (a) 受容: 39 セル具体値は design phase で確定。Spec 1-7 の requirements は概念レベルで Foundation を引用、design 以降で詳細を引用
    - (b) requirements 強化: 少なくとも §2.10 (全層貫通) / §2.12 (L2 専用) / §2.2 (L3 専用) などの 層別 binding が原則の本質である項目
  はマトリクス値を requirements に固定（部分マトリクス、全 39 セルではなく約 5-10 セル）
    - (c) requirements に全 39 セルを記述（重い）

  観点 4: 13 中核原則の固定が「凍結」か「拡張可能」かが曖昧

  - §2.13 が後付けで追加された経緯（キュレートプロセス可視化.md → consolidated-spec v0.7.12）が示すように、原則は実際に増える
  - requirements.md は「13 原則」と数値固定しており、14 番目が追加された場合の手順が要件化されていない
  - R10.3 の Adjacent Spec Synchronization は「先行 spec 変更による波及的同期」を扱うが、原則自体の追加 は「波及的同期」を超える本質変更
  - 本質的問い: Foundation が「凍結 SSoT」なら 13 で固定で良い。「拡張可能 SSoT」なら拡張手順が要件化されるべき
  - 方向性:
    - (a) 「13 で凍結」を明示。14 番目以降は別 spec / 次世代 Foundation として扱う
    - (b) 拡張手順を要件化: 「§2.X として原則が追加される場合、Foundation requirements の改版 → §2.0 マトリクスへの追加 → 全 spec の Adjacent Sync」を規範化

  観点 5: Foundation 自身の curation provenance が無い構造的非対称性

  - §2.13 で Curation Provenance を全層に規範化（特に L2/L3 の curation 決定は decision_log.jsonl に保全）
  - しかし Foundation 自身の curation 決定（13 原則の選択根拠 / 用語集 5 分類の境界決定 / §2.13 後付けの判断 etc.）は decision_log
  として保全されていない
  - これらは docs/キュレートプロセス可視化.md / docs/Rwiki-V2-dev-log.md に散在するのみで、Foundation の SSoT 構造には組み込まれていない
  - 本質的問い: 「why の保全」を規範化する Foundation 自身が、自分の why を体系的に保全していない非対称性は許容されるか?
  - 方向性:
    - (a) 規範文書の curation は「文書 change log + dev-log」で十分とし、decision_log の対象外と明示
    - (b) Foundation 改版に伴う curation 決定も decision_log.jsonl の対象に含める（Foundation を「meta-L3 wiki」として扱う）
    - (c) brief.md Coordination に「Foundation の curation 決定は dev-log + brief change log + roadmap.md L82 Coordination必要事項で記録される。decision_log.jsonl は L2/L3 操作専用」と明示し、非対称性を意識的に肯定

  観点 6: 想定読者「Spec 1-7 起票者」への過剰な絞り込み

  - 全 14 Req の Objective が「As a Spec 1-7 起票者, I want ... so that ...」
  - 起票フェーズは 一回性（最大 8 回）の活動。一方、SSoT は spec 起票後も実装・レビュー・保守・拡張で継続的に参照される
  - Objective が起票最適化されているため、実装者 / レビュアー / LLM agent / 将来の v3 設計者 / 外部協力者 への配慮が要件レベルで読み取れない
  - 本質的問い: Foundation を「永続的 SSoT」と謳うなら、Objective も永続的読者に開く必要があるのでは
  - 方向性:
    - (a) 受容: 起票フェーズが最重要、他読者は文書品質で自然にカバー
    - (b) Objective の主体を「Spec 1-7 起票者および将来の v2 開発者」に拡張（R10 のみそうなっている、他 Req も同様に拡張）
    - (c) R14 に「想定読者の永続性」要件を追加

  観点 7: 3 層対称性の崩れ（L2 詳細、L1 / L3 簡素）

  - L2 Graph Ledger の core schema は 6 ファイル詳細列挙（R8.5）、reject_queue/ 横断、edge event types（R13.3）、reject 必須フィールド（R13.5）と詳細
  - 一方 L1 Raw は raw/**/*.md の一行のみ（R2.1）、内部構造（incoming / llm_logs / category subdirectory）は Foundation 範囲外
  - L3 Curated Wiki も wiki/**/*.md の一行のみ、frontmatter 骨格 (R8.3-R8.4) で部分的に補完
  - 本質的問い: 3 層対称性をモデルとして掲げながら、Foundation の規範密度が L2 に偏っているのは意図的か漏れか
  - 方向性:
    - (a) 意図的: L2 は新規概念で詳細規範必要、L1/L3 は markdown という既存形式で詳細規範不要
    - (b) 漏れ: L1 raw の subdirectory 規約 (incoming / llm_logs / categories) と L3 wiki の subdirectory 規約 (concepts / methods / projects / entities / synthesis / .follow-ups) を Foundation で扱うべき
    - (c) brief.md / requirements.md で「L1 / L3 内部構造は Spec 1 (frontmatter) と structure.md (Vault layout) が SSoT」と明示し、Foundationの対称性は「層モデル」レベルで完結することを宣言

  まとめ：本質的観点への対処

  これらは 修正で済む話ではなく、Spec 0 の方向性判断です。私の推奨整理:

  - 観点 1 (testability 限界): 方向性 (b) 推奨 — methodology の限界を brief で明示、design phase での過剰検証を防ぐ
  - 観点 2 (SSoT 違反検出): 方向性 (c) 推奨 — §2.13 の応用として decision_log で違反検出 (Foundation 自身が要求)
  - 観点 3 (層別マトリクス): 方向性 (b) 推奨 — 層別 binding が本質の原則 (§2.10 / §2.12 / §2.2) のみ部分マトリクスを requirements に固定
  - 観点 4 (拡張手順): 方向性 (b) 推奨 — 拡張手順を R10 か新 Requirement で規範化
  - 観点 5 (Foundation の curation provenance): 方向性 (c) 推奨 — 非対称性を意識的に肯定
  - 観点 6 (想定読者): 方向性 (b) 推奨 — 全 Objective の主体を「Spec 1-7 起票者および将来の v2 開発者」に拡張（軽微）
  - 観点 7 (3 層対称性): 方向性 (c) 推奨 — 対称性は層モデルで完結、内部構造は Spec 1 / structure.md 委譲を明示

  次のアクション選択

  - a) 推奨整理どおり 7 観点すべて対応 — requirements.md / brief.md の本質的強化
  - b) 観点 1 / 2 / 3 / 4 のみ対応（testability・SSoT 検出・マトリクス具体値・拡張手順 = methodology の核心）
  - c) 観点 1 のみ対応（最も根本的）+ 残りは design phase 持ち越し
  - d) 全部受容、ただし「これらの本質的論点を認識した」記録だけ dev-log に残す
  - e) 個別観点を再議論したい（番号指定）
  - f) 私のレビューを再検討したい論点がある

  ご指示ください。
```

##### ❯ a)で対応

```
⏺ 7 観点を推奨方向性で実装します。spec.json を確認してから作業します。
⏺ Step 1: brief.md Coordination 拡張（観点 1, 5, 7）
⏺ Step 2: requirements.md の Objective 主体拡張（観点 6、12 箇所）
⏺ Objective 主体拡張 12 箇所完了。次に R3 強化（観点 3 / 4）と R10 強化（観点 2）と Boundary Context 強化（観点 7）を実施します。
  Step 3: R3 に層別 binding 不変項目 + 拡張手順を追加（観点 3 / 4）
⏺ Step 4: R10 に SSoT 引用整合性検証を追加（観点 2）
⏺ Step 5: Boundary Context 強化（観点 7、3 層対称性の意図的限定）
⏺ 7 観点の修正完了です。

  適用した修正サマリ

  brief.md（Coordination 拡張、3 サブセクション追加）

  - 観点 1 (testability スコープ): 「Foundation 規範文書 spec の testability スコープ」セクション新設
    - 要件レベル testable は「項目存在チェック」までと明示
    - design phase で構築する検証手段を 4 種に限定（章節アンカー / SSoT 出典整合 / link 切れ検出 / schema 妥当性）
    - I-6 の design 持ち越し対応の 設計上限 として固定
  - 観点 5 (curation provenance 非対称性): 「Foundation 自身の curation provenance 構造」セクション新設
    - Foundation の curation 決定は dev-log / docs/ / roadmap.md Coordination が記録媒体
    - decision_log.jsonl は L2/L3 操作専用との 構造的非対称性を意識的に肯定
  - 観点 7 (3 層対称性): 「3 層対称性の意図的限定」セクション新設
    - L1 / L3 内部構造は Spec 1 と structure.md が SSoT
    - 対称性は「層モデル」レベルで完結することを宣言

  requirements.md（Objective 主体拡張 + criterion 追加 + Boundary Context 強化）

  - 観点 6 (想定読者): R1〜R13 の Objective 主体（R10 / R14 を除く 12 箇所）を 「Spec X 起票者および将来の v2 開発者・実装者・保守者」 に拡張
  - 観点 3 (層別マトリクス具体値): R3.7 を新設
    - 層別 binding 不変項目 を 4 件固定: §2.10 全層貫通 / §2.12 L2 専用 / §2.2 §2.4 L3 専用 / §2.13 L2/L3 機能・L1 lint pass のみ
    - design phase での再解釈・緩和を不可と規範化
  - 観点 4 (拡張手順): R3.8 を新設
    - 13 原則の追加・削除・改名・適用度変更は Foundation requirements 改版を要する
    - Adjacent Spec Synchronization では扱わない（実質変更のため Spec 1-7 全体の再 approval 検討対象）と明記
  - 観点 2 (SSoT 違反検出): R10.7 / R10.8 を新設
    - SSoT 引用整合性検証手段を design phase で確定すべきと要件化
    - 候補 3 種: link 切れ検出 / decision_type: foundation_revision の §2.13 枠組み記録 / Adjacent Sync 影響範囲の機械生成
    - 「定義の存在」だけでは SSoT は機能しない、「引用の正しさ」検証が伴って初めて機能との立場明示
    - SSoT 違反検出時は Foundation 改版を要する変更提案として扱う規範
  - 観点 7 (3 層対称性の意図的限定): Boundary Context Out of scope に L1 raw / L3 wiki の subdirectory 規約は Spec 1 + structure.md が SSoT
  を追記、規範文書内容妥当性の機械検証は人間レビュー gate に委譲する旨を追記

  構造変化サマリ

  - Requirement 数: 14 → 14（変化なし、R14.5 の自己言及も整合維持）
  - Acceptance criteria 数: 約 85 → 約 89（R3 +2 / R10 +2）
  - brief.md Coordination: 1 サブセクション → 5 サブセクション（v1 継承 / testability スコープ / curation provenance 非対称性 / 3 層対称性限定 / I-6 design 持ち越し）

  次のアクション

  これで Spec 0 の本質的レビューは出尽くしたと判断します。

  - a) approve に進む: spec.json 更新 + 修正コミット（requirements.md / brief.md / structure.md の 3 ファイル）
  - b) 追加レビュー観点を続ける（例: 他 spec brief.md と Adjacent expectations の照合、scenarios.md との整合）
  - c) 個別観点の再考

  ご指示ください。
```

##### ❯ Spec0の修正内容に対して、他のスペックとの整合性をチェック

```
⏺ Spec 0 の修正内容（10 項目）が Spec 1-7 でどう扱われているか、並列で網羅的にチェックします。

⏺ Explore(Spec 0 修正内容と他 spec の整合性チェック)

⏺ 整合性チェック結果が出ました。Spec 0 自身の規範化は完了しており、他 spec への波及項目が 8 件浮上しています。

  整合性チェック総括

  優先度 1（高、実装責務の宙ぶらりん）

  - B: rw discover の実装責務不在
    - Spec 0 R6.2 で L1 発見コマンドとして規範化、Spec 4 CLI list には存在
    - Spec 6 requirements で内部ロジック所管が割り当てられていない
    - 修正先: Spec 6 または Spec 4
  - D: rw decision * 6 コマンドの CLI 層未定義
    - Spec 0 R9.2 で Command カテゴリ化、Spec 5 で API 層のみ実装
    - Spec 4 requirements に CLI dispatch 明示なし
    - 修正先: Spec 4
  - C: review/decision-views/ frontmatter スキーマ未定義
    - Spec 5 で出力先明示、Spec 1 で固有スキーマ記載なし
    - Spec 0 R8.4 が「Spec 1 に委譲」と明記したので、Spec 1 レビュー時に補完すれば OK
    - 修正先: Spec 1

  優先度 2（中、層別適用・責務分離の明示不足）

  - F: 層別 binding 不変項目（§2.12 優先性）の表現明示 — Spec 5 / Spec 7 で機能整合は確保、明文化のみ不足 → Spec 5 / Spec 7
  - E: Spec 7 での page merge/split の decision_log 自動記録 — Spec 5 で trigger 5 条件定義済、Spec 7 で API 呼出ポイント未明示 → Spec 7
  - G: L1 raw subdirectory 規約の SSoT 参照 — Spec 1 requirements に「steering structure.md が SSoT」の明示なし → Spec 1

  優先度 3（低、Spec 0 R10.7 で design phase 持ち越しを明記済）

  - H: SSoT 引用整合性検証手段 — design phase 確定、現時点で他 spec 未対応は想定通り
  - I: 用語集の引用メカニズム — 定義は Spec 5 にあり、引用形式は design phase

  重要な観察

  - Spec 0 自身の規範化は完了: 8 件の波及項目はいずれも Spec 0 が他 spec へ委譲した責務（R8.4 「Spec 1 委譲」、R10.7 「design phase持ち越し」等）か、各 spec の本来の所管事項
  - Adjacent Spec Synchronization の対象: roadmap.md Governance ルールにより、先行 spec 変更による波及的同期は 対象 spec の spec.json.updated_at　更新と各 markdown 末尾 _change log 追記で足りる（再 approval 不要）
  - TODO_NEXT_SESSION.md の手順通りであれば、これら 8 件は 各 spec のレビュー時に検出・修正される予定（Spec 1 / Spec 4 / Spec 5 / Spec 6 / Spec 7のレビュー時のチェック項目）

  次のアクション選択

  これは 「Spec 0 を approve するか」と「波及項目をどう管理するか」の二段階判断です。

  - a) Spec 0 を approve、波及 8 件を TODO_NEXT_SESSION.md に追記して各 spec レビュー時のチェック項目として固定（推奨、レビュー手順を尊重）
  - b) Spec 0 を approve、Adjacent Sync として今すぐ他 spec の優先度 1 / 2 を修正（5 spec へ波及修正、コミット数増、change log 追記）
  - c) Spec 0 approve を保留、他 spec の修正と一括で Spec 0-7 整合確認後にバッチ approve（重い、レビュー順序を逆転）
  - d) Spec 0 修正に追加項目を入れる（例: R8.4 / R12 等を更に強化して Spec 1 / 7 への要求を明示化）

  私の推奨は a): Spec 0 自身は完成度十分、波及項目は各 spec のレビュー時に検出される設計通りの構造、TODO_NEXT_SESSION.md に明示することで失念を防ぐ。

  ご指示ください。
```

##### ❯ a)案でいきましょう。

```
⏺ Spec 0 を approve し、波及 8 件を TODO_NEXT_SESSION.md に追記します。
⏺ Spec 0 approve 完了、TODO_NEXT_SESSION.md に波及項目 W-1〜W-8 を追記しました。
  完了サマリ

  Spec 0 (rwiki-v2-foundation) approve 完了

  - spec.json: approvals.requirements.approved = true / phase = "requirements-approved" / updated_at = 2026-04-26T14:06:41+09:00
  - 修正 ファイル数: 4 ファイル
    - requirements.md — R2.3 / R3.7 / R3.8 / R5.4 / R6.2 / R7.4 / R8.4 / R8.5 / R9.2 / R10.7 / R10.8 / Boundary Context + Objective 主体拡張 12 箇所
    - brief.md — Page status 5 種修正 / Out of Boundary 拡張 / Constraints 整理 / Coordination 5 サブセクション化
    - steering/structure.md — decision_log.jsonl 追加 / review/decision-views/ 追加（Adjacent Spec Synchronization）
    - spec.json — approve 状態反映

  TODO_NEXT_SESSION.md 更新

  - 進捗シンボル: ✅⬜⬜⬜⬜⬜⬜⬜（1/8 完了）
  - 新セクション「Spec 0 レビュー由来の波及項目」追加 — W-1〜W-8 の 8 件を優先度別に整理
  - 各 spec レビュー時の波及項目チェックリスト を追加 — Spec 1 / 4 / 5 / 6 / 7 のレビュー Step 1 で必ず確認すべき項目を spec ごとに集約
```

##### ❯ /session-cont

```
⏺ セッション継続準備を実施します。現状確認から。
⏺ セッション継続準備完了。

  完了状況

  - git: working tree clean、origin/main 同期済（ahead 0 / behind 0）
  - 本セッションのコミット 3 件はすべて push 済:
    - 2009d4f Spec 0 approve
    - 205f7de structure.md Adjacent Sync
    - 28aefd8 dev-log 追記
  - TODO_NEXT_SESSION.md は最新化済（gitignore 対象、ローカル保持）
    - 進捗: ✅⬜⬜⬜⬜⬜⬜⬜（1/8 完了）
    - 次対象: Spec 1 (rwiki-v2-classification)
    - 波及項目 W-1〜W-8 を spec ごとに整理済

  次セッション開始時のガイドライン

  新セッションを開いたら、Claude に最初に伝えるメッセージ:

TODO_NEXT_SESSION.md を読んでください。Spec 0 (foundation) は approve 完了。dependency 順の次対象 Spec 1 (rwiki-v2-classification) のrequirements レビューを開始します。本セッションで判明した波及項目（W-3 / W-6）を必ずチェック対象に含めてください。4 step 手順で進め、Spec 1 のRequirement 一覧と要点（cross-spec review 懸念 + 波及項目）を提示してください。

  Spec 1 レビュー時のチェック項目

  - 波及項目（必須）:
    - W-3: review/decision-views/ 固有 frontmatter スキーマを Spec 1 requirements に追加
    - W-6: 「L1 raw subdirectory 規約は steering structure.md が SSoT」を Spec 1 requirements に明示
  - Important: なし
  - Cross-spec review 懸念:
    - Spec 1 ↔ Spec 3: frontmatter type: 追加（Wave 2 で確定済）
    - Spec 1 ↔ Spec 3: categories.yml の default_skill mapping 方式（Wave 2 で確定済）
    - Frontmatter スキーマ骨格 (Spec 0 R8) と Spec 1 の所管境界（M-1、design phase で再確認）

  レビュー手順（4 step）

  1. Claude: Requirement 一覧 + cross-spec 懸念 + 波及項目（W-3 / W-6）+ Important 提示
  2. ユーザー: 「全部読む / 気になる Req のみ詳細 / approve」を選択
  3. Claude: 該当 Req を Read で抽出
  4. Claude: 修正があれば Edit、approve なら spec.json 更新

  セッション区切りの準備は完了しました。安心してセッションを切ってください。お疲れ様でした。
```



## Spec 1 rwiki-v2-classification

##### TODO_NEXT_SESSION.md を読んでください。Spec 0 (foundation) は approve 完了。dependency 順の次対象 Spec 1 (rwiki-v2-classification) のrequirements レビューを開始します。本セッションで判明した波及項目（W-3 / W-6）を必ずチェック対象に含めてください。4 step 手順で進め、Spec 1 のRequirement 一覧と要点（cross-spec review 懸念 + 波及項目）を提示してください。

```
⏺ TODO の状況把握できました。Spec 1 の requirements と brief を確認します。

⏺ Spec 1 (rwiki-v2-classification) の Requirement 一覧と要点を提示します。Step 1: 要点提示 です。

  Spec 1 の概要

  - scope: L3 Curated Wiki の分類体系基盤（カテゴリ / frontmatter スキーマ / vocabulary / rw tag * CLI / lint vocabulary 統合）
  - Requirement 数: 14 個（acceptance criteria 計 92 件）
  - 現状: approvals.requirements.approved = false、phase = requirements-generated

  Requirement 一覧（タイトルのみ）

  - R1: カテゴリディレクトリ構造の推奨パターン（初期 7 種、強制ではなく推奨）
  - R2: 共通・任意 frontmatter フィールドの確定（必須 3 + 推奨 2 + 任意）
  - R3: L3 wiki ページ固有 frontmatter のスキーマ宣言（status / successor / merged_* / related / update_history）
  - R4: Review レイヤー固有 frontmatter のスキーマ宣言（synthesis_candidates/ / 新規 vocabulary_candidates/）
  - R5: Entity 固有ショートカット field のスキーマ宣言（authored: 等、entity_types.yml mapping）
  - R6: .rwiki/vocabulary/tags.yml の最小スキーマ（canonical / aliases / deprecated）
  - R7: .rwiki/vocabulary/categories.yml のスキーマと default skill mapping（inline 方式）
  - R8: Tag 操作 CLI 群（rw tag scan / stats / diff / merge / split / rename / deprecate / register / vocabulary / review）
  - R9: lint task の vocabulary 統合（CRITICAL/ERROR/WARN/INFO 4 水準）
  - R10: L3 frontmatter related: を Spec 5 derived cache とする規約（eventual consistency）
  - R11: Spec 1 ↔ Spec 3 coordination の確定（type: field、inline default_skill）
  - R12: Spec 1 ↔ Spec 5 coordination の責務分離（宣言は Spec 1、展開は Spec 5）
  - R13: Foundation 規範への準拠（13 原則 / Page status 5 種 / Edge status 6 種）
  - R14: 文書品質と運用前提（日本語 / 表禁止 / Python 3.10+ / subprocess timeout）

  Cross-spec review の懸念（subagent 由来、TODO より）

  - (M-1) Frontmatter スキーマ骨格 (Spec 0 Req 8) と Spec 1 の所管境界 → R13.4 で「Foundation 委譲を Spec 1 が引き受け、Skill / Hypothesis /
  Perspective のみ Spec 2 / Spec 6 に再委譲」と明示済 ✅
  - Spec 1 ↔ Spec 3 inline default_skill 方式 → R7.2 / R11.2 に確定記載済 ✅
  - Important 該当: なし

  波及項目（必須チェック、Spec 0 approve 由来）

  W-3（要件レベル、要修正）: review/decision-views/ 固有 frontmatter 未定義

  - Spec 0 側の前提: R8.4 で「Spec 1 委譲」と明記、Spec 5 で出力先指定あり
  - Spec 1 現状: R4 で review/synthesis_candidates/ と review/vocabulary_candidates/ のみ列挙、review/decision-views/ 不在
  - 修正方針: R4 に新たな acceptance criterion を追加し、review/decision-views/* の timeline frontmatter（推定 field: decision_id / period / entity /
   generated_at / source_decisions 等）を宣言
  - 要判断: 具体的な field 集合を Spec 1 で確定するか、骨格のみ宣言して詳細 schema は Spec 5 に再委譲するか

  W-6（要件レベル、要修正）: L1 raw subdirectory 規約の SSoT 参照未明示

  - Spec 0 側の前提: Boundary Out of scope に「L1/L3 subdirectory 規約 SSoT は Spec 1 + steering structure.md」と明記
  - Spec 1 現状: R1 で L3 categories は規定するが、L1 raw subdirectory（例: raw/articles/ raw/papers/ 等の規約 / 強制 vs 推奨）への言及・SSoT
  参照なし
  - 修正方針:
    - 案A: R1 に L3 だけでなく L1 raw subdirectory 規約も含めるよう拡張、SSoT 委譲を明示
    - 案B: 新規 Requirement（例: R15 「L1 raw subdirectory 規約」）を追加
    - 案C: Boundary Context に「L1 raw subdirectory 規約は steering structure.md が SSoT、本 spec は L3 のみ所管」と明示する委譲記述のみ追加（Spec 1
  を肥大化させない）
  - 要判断: Spec 1 で L1 規約まで所管するか、steering 単独 SSoT で Spec 1 はポインタのみ持つか

  次の Step（あなたの選択）

  - A: 全 Requirement を順次詳細レビュー（R1 → R14）
  - B: 気になる Requirement のみ Read で抽出（番号指定）
  - C: 波及項目 W-3 / W-6 の修正方針を先に判断・適用してから、本体レビュー
  - D: 修正なしで approve（W-3 / W-6 を skip する場合は理由要確認）

  どれで進めますか？
```

##### ❯ A

```
⏺ 全 Requirement レビューに入ります。整合性チェックのため Foundation requirements と steering structure を並列で読み込みます。

⏺ 全 14 Requirement を Foundation requirements / steering structure と照合してレビューしました。本質的観点・整合性観点での指摘を分類して提示します。

  全体所感

  - brief.md Scope.In との整合: 9 項目すべて R1〜R10 でカバー済 ✓
  - Foundation との用語整合: Page status 5 種 / Edge status 6 種 / 13 原則の引用 (R13) は適切 ✓
  - CLAUDE.md ルール準拠: 表は不使用、長文は箇条書き、日本語 ✓
  - EARS 形式: subject 統一（the Classification System / the rw tag command / the lint task）、trigger / response 明確 ✓

  必須対応 3 件

  【1】W-3: review/decision-views/ のスキーマ宣言不在（要件追加）

  - 根拠: Foundation R8.4 が「review/*_candidates/ 全般、および review/decision-views/」を Spec 1 委譲と明示
  - 現状: R4 は synthesis_candidates/ と新設 vocabulary_candidates/ のみ宣言。decision-views/ への言及なし
  - 修正方針: R4 に新 acceptance criterion を追加し、review/decision-views/* の Tier 2 markdown timeline frontmatter を宣言（Spec 5 が rw decision
  render 等で出力する先）
  - 要判断: スキーマの粒度
    - 案A: 骨格のみ（例: decision_id / period / entity / generated_at / tier=2）を Spec 1 で確定
    - 案B: Spec 5 へ詳細スキーマを再委譲し、Spec 1 は出力先 dir の存在と Tier 2 marker のみ宣言
    - 推奨: 案A（Spec 1 が R4 で全 review 層を所管している原則と整合）

  【2】W-6: L1 raw subdirectory 規約の SSoT 参照不在

  - 根拠: Foundation Boundary Out of scope に「L1 raw subdirectory 規約は Spec 1 + steering structure.md が SSoT」と明記
  - 現状: Spec 1 は L3 categories のみ規定、L1 raw subdirectory への言及なし
  - 修正方針: Boundary Context Out of scope に「L1 raw subdirectory 規約（raw/incoming/ / raw/llm_logs/{interactive,chat-sessions,manual}/ 等）は
  steering structure.md が一次 SSoT、本 spec は L3 wiki カテゴリのみ所管」と明示参照を追加
  - 要判断: Spec 1 で L1 規約まで所管拡張するか、ポインタのみで足りるか
    - 推奨: ポインタのみ（TODO 修正方針に整合、Spec 1 を肥大化させない）

  【3】R4 網羅性不足（指摘 19、Foundation R8.4 委譲漏れ）

  Foundation R8.4 の委譲リストと Spec 1 R4 の対応マッピング:

  - review/synthesis_candidates/ → R4.1, R4.2 ✓
  - review/vocabulary_candidates/ → R4.4, R4.5 ✓
  - review/audit_candidates/ → 言及なし ❌
  - review/relation_candidates/ → 言及なし ❌（Spec 5 所管？）
  - review/decision-views/ → 言及なし ❌（W-3）
  - Follow-up → 言及なし ❌（Spec 7 所管？）
  - Skill ファイル / Skill candidate → R4.6 で Spec 2 再委譲 ✓
  - Hypothesis candidate / Perspective → R4.6 で Spec 6 再委譲 ✓
  - Vocabulary candidate → R4.4, R4.5 ✓
  - 修正方針: R4.6 を拡張し、audit_candidates/ / relation_candidates/ / Follow-up の所管も明示（Spec 4 / Spec 5 / Spec 7 への再委譲または Spec 1
  引受の判断）
  - 要判断:
    - audit_candidates/ → Spec 4 audit task 出力先 → Spec 4 再委譲が自然
    - relation_candidates/ → Spec 5 typed edge 候補 → Spec 5 再委譲が自然
    - Follow-up → Foundation 用語集に「Follow-up」あり、wiki/.follow-ups/ は L3 配下 → Spec 1 で骨格宣言、操作セマンティクスは Spec 7 が自然

  中重要度指摘 4 件

  【4】R2.7 の type: 許可値の参照先統合規約が曖昧

  - R2.7: type: の許可値を categories.yml または entity_types.yml と整合
  - categories.yml.recommended_type（R7.1）と entity_types.yml.name（R5.2）が併存 → 統合規約が不明
  - 修正候補: R2.7 に「type: 値の判定 = categories.yml.recommended_type ∪ entity_types.yml.name の合併集合」と明示。または design phase
  持ち越しとして brief.md Coordination に追記

  【5】R3.5 と R10.4 の related: schema 重複

  - R3.5 と R10.4 で target / relation / edge_id の 3 項目を二重宣言
  - 整合は取れているが冗長 → design phase で R10.4 を「R3.5 を参照」に簡素化が望ましい
  - 修正候補: R10.4 を「R3.5 で確定した schema を参照、本 Requirement では cache 規約のみ扱う」に書き換え（軽微 refactor、approve 前でも後でも可）

  【6】R8（rw tag scan）と R9（rw lint）の機能境界が不明示

  - R8.2: rw tag scan が「Requirement 6 の severity 規約に従って一覧出力」
  - R9.1: rw lint も「未登録タグ INFO / エイリアス WARN / 非推奨 WARN」を含む
  - 両コマンドの責務分担（vocabulary 専用詳細 vs 全体検査の一部）が requirements 上で明示されていない
  - 修正候補: R8.2 に「rw lint の vocabulary 検査と severity を共有しつつ、tag 統計・重複候補等の vocabulary
  専用情報を追加出力する」と境界明示。または design phase 持ち越し

  【7】R9.2 の severity-unification spec 参照の出典曖昧性

  - R9.2: 「severity-unification spec で確定済の map_severity() identity マッピングを継承」
  - v2 では severity-unification spec は v1-archive の話、v2 roadmap.md「v1 から継承する技術決定」が窓口
  - 修正候補: R9.2 を「roadmap.md「v1 から継承する技術決定」経由で severity 4 水準（CRITICAL/ERROR/WARN/INFO）を継承」に書き換え（v1-archive
  を直接参照しない）

  軽微指摘 4 件

  - 【8】R3.6: update_history.evidence の型定義「raw path」が曖昧 → 「raw/ 配下の relative path（文字列）」と明示推奨
  - 【9】R5.6 vs R9.1 の言い回しズレ: 「ショートカット field が未登録 entity type に属する」 vs 「未登録 entity type のショートカット field 使用」 →
  同義だが文言統一推奨
  - 【10】R4.5: review/vocabulary_candidates/* field の必須/任意区別なし → operation / target 必須、aliases 任意、status デフォルト draft の整理推奨
  - 【11】R7.3: 「初期値が将来 Spec 3 起票時に確定可能な形で空欄を許可」 → 空欄が valid であることを明示推奨

  あなたの判断が必要な項目

  以下の判断を頂ければ、Step 4（修正適用）に進めます。

  - Q1（W-3 / 指摘1）: review/decision-views/ のスキーマ粒度 → 案A（骨格 5-6 field を Spec 1 で確定）/ 案B（Spec 5 再委譲）
  - Q2（W-6 / 指摘2）: L1 raw subdirectory 規約 → ポインタのみ（推奨）/ Spec 1 で所管拡張
  - Q3（指摘3 / R4 網羅性）: audit_candidates/ / relation_candidates/ / Follow-up の所管 → 提示通り Spec 4 / Spec 5 / Spec 7 再委譲（Follow-up は
  Spec 1 骨格 + Spec 7 操作）
  - Q4-Q7（中重要度指摘 4-7）: いずれも修正適用するか、design phase 持ち越しか
  - Q8-Q11（軽微指摘）: 修正適用するか、approve して後続 phase で処理するか

  提案デフォルト方針: 必須 3 件 + 中重要度 4 件は requirements 段階で修正、軽微 4 件は approve 後の design phase触りで対応。この方針で良いですか、または個別判断を聞きたい項目はありますか？
```

##### ❯ 提案で対応

```
⏺ 提案方針で修正を適用します。各修正を順次編集します。
  修正1: Boundary Context Out of scope に L1 raw subdirectory ポインタ追加（W-6）
⏺ 修正2: R2.7 の type: 許可値統合規約を明示
⏺ 修正3: R4 に decision-views/ 宣言（W-3）と audit_candidates/ / relation_candidates/ / Follow-up の所管整理を追加
⏺ 修正4: R8.2 に rw lint との境界を明示
⏺ 修正5: R9.2 の severity 出典を roadmap.md 経由に修正
⏺ 修正6: R10.4 を簡素化（R3.5 schema を参照）
⏺ 修正6件すべて適用しました。R9.2 で参照した roadmap.md の継承記述が実在するか念のため確認します。
⏺ roadmap.md L130-136 に「v1 から継承する技術決定 / Severity 4 水準 / map_severity() identity」の記述あり、R9.2 の参照は正当でした。修正後の R4 /Boundary 周辺の整合性を再確認します。
⏺ 軽微 4 件の design phase 持ち越しを brief.md Coordination セクションに追記します。
⏺ 修正完了しました。approve 前の最終確認を提示します。

  適用した修正サマリ（計 6 箇所）

  requirements.md

  - Boundary Out of scope に追加 (W-6): L1 raw subdirectory 規約は steering structure.md が SSoT、本 spec は L3 のみ所管と明示
  - R2.7 修正: type: 許可値を「categories.yml.recommended_type ∪ entity_types.yml.name の合併集合」と明示
  - R4.7 新規追加 (W-3): review/decision-views/* の Tier 2 timeline frontmatter 7 field（decision_id / tier=2 / period_start / period_end / entity /
  source_decisions / generated_at）を宣言、render 実装は Spec 5 委譲
  - R4.8 新規追加 (R4 網羅性): audit_candidates/ → Spec 4 / relation_candidates/ → Spec 5 / Follow-up → Spec 7 への再委譲を明示
  - R8.2 修正: rw tag scan と rw lint の機能境界（severity 共有 + vocabulary 専用詳細出力）を明示
  - R9.2 修正: severity 出典を「v1-archive の severity-unification spec 直接参照」から「roadmap.md「v1 から継承する技術決定」経由」に変更
  - R10.4 修正: related: 要素 schema を R3.5 参照に簡素化、本 Requirement は cache 規約のみ扱う

  brief.md

  - Coordination セクションに Design phase 持ち越し 4 件追記: R3.6 / R5.6・R9.1 / R4.5 / R7.3 の軽微指摘を design phase で確実に拾う

  影響範囲

  - AC 数の変化: R4 が 6 → 8（+2）、合計 92 → 94 criteria
  - brief.md ↔ requirements.md ↔ Foundation の整合: ✓（W-3 / W-6 / R4 網羅性すべて Foundation 規範と整合）
  - roadmap.md 参照（R9.2）: roadmap L130-136 に「v1 から継承する技術決定 / Severity 4 水準 / map_severity() identity」記述あり、参照正当性確認済

  approve 判断のお願い

  修正内容で問題なければ、Spec 1 (rwiki-v2-classification) を approve します（spec.json の approvals.requirements.approved = true、phase = requirements-approved）。

  - A: approve OK → spec.json 更新 + コミット
  - B: 修正内容に追加の確認/微調整が必要 → 該当箇所を指摘してください
```

##### ❯ roadmap.md, brief.mdを照合して、厳しく精査

```
⏺ roadmap.md を全体読み、brief.md と requirements.md（修正後）と照合します。
⏺ roadmap.md / brief.md と requirements.md（修正後）を厳しく精査しました。新たに発見した齟齬・誤りを整理します。

  修正必須 5 件（approve 前に対応推奨）

  【指摘 H】R8.5 の Foundation 参照誤り（重要）

  - 現状: Foundation Requirement 6 の dangerous operations 8 段階対話に準じる
  - 誤り: Foundation R6 は「コマンド 4 Level 階層とエディタ責務分離」であり、dangerous ops の話ではない
  - 正しい参照: Foundation R3.1（13 中核原則）の §2.4 dangerous ops 8 段階
  - 修正: 「Foundation §2.4 / Requirement 3 の dangerous operations 8 段階対話」

  【指摘 I】R5.5 の rw graph rebuild 所管混在（重要）

  - 現状: 呼び出し側（Spec 4 の rw ingest/rw approve/rw graph rebuild 等）
  - 誤り: rw graph rebuild は Spec 5 (knowledge-graph) 所管。Foundation R9.2 / structure.md で L2 Graph Ledger 管理コマンド
  - 修正: 「Spec 4 の rw ingest / rw approve、および Spec 5 の rw graph rebuild 等」と所管を分離

  【指摘 K】R8.8 のタイポ（軽微）

  - 現状: descrption が指定されていればそれを記録する
  - 修正: description

  【指摘 D】コマンド名の不一致（中、brief.md 修正）

  - brief.md L70: rw graph sync で整合
  - requirements.md R10.3 / Boundary Out of scope: rw graph rebuild --sync-related
  - 修正: brief.md を rw graph rebuild --sync-related に揃える（requirements.md / Foundation 表記が正規）

  【指摘 C】brief.md Downstream の Spec 7 抜け（中、brief.md 修正）

  - brief.md L58: Downstream に Spec 4 / Spec 5 / Spec 3 のみ
  - requirements.md R3.7, R12 で Spec 7 (lifecycle-management) が status / merged_* field のセマンティクスを実装
  - roadmap.md L37: rwiki-v2-lifecycle-management ... Dependencies: rwiki-v2-foundation, rwiki-v2-classification → Spec 7 は Spec 1 に依存
  - 修正: brief.md Downstream に「rwiki-v2-lifecycle-management（Spec 7 — Page lifecycle field のセマンティクス実装）」を追加

  Design phase 持ち越し 8 件（軽微〜中、approve 後で OK）

  - 【F】 R5.3 entity-person/tool ショートカット → typed edge 名の初期 mapping 例（authored → ?）
  - 【G】 typed edge の directed/undirected 区別（mentored は directed、collaborated_with は undirected 等）
  - 【L】 lint で許可値外 merge_strategy: の WARN 検出（R9.1 に追加可能）
  - 【M】 type 表記統一（R3.4 「path」「path 配列」の表記揺れ）
  - 【N】 R4.7 decision-views/ の period_start/period_end 必須/任意の妥当性
  - 【O】 Decision visualization Tier 1, 3, 4, 5 の出力先所管
  - 【S】 categories.yml.enforcement: required のセマンティクスと R1.2「いずれの推奨カテゴリ外でも valid」との関係
  - 【T】 merge_strategy: canonical-a / canonical-b の a/b 順序規約

  roadmap.md / brief.md 同期 1 件（任意、後追い可）

  【指摘 E】Coordination 決定の roadmap / brief 同期

  - roadmap.md L85: default_skill mapping 方式（inline / 別ファイル） → 二択提示のまま
  - brief.md L75: 同上
  - requirements.md R11.2 で inline 確定済
  - 修正候補: Adjacent Spec Synchronization 運用ルール（roadmap L162-168）に従い、roadmap.md と brief.md の Coordination 記載を「inline 確定（R11.2
  参照）」に更新
  - 必要性: 将来読み手が「未確定」と誤解しないよう更新が望ましい
  - 軽微度: brief.md の更新は本セッションで実施可能、roadmap.md は steering 改版で共通管理

  整合確認できた項目（参考）

  - brief.md Scope.In 9 項目すべて requirements.md でカバー ✓
  - brief.md Constraints 5 項目すべて requirements.md と整合 ✓（コマンド名【D】を除く）
  - brief.md Coordination 必要事項 → R11 / R12 で確定 ✓
  - roadmap.md Spec 1 dependencies → Spec 0 のみ → ✓
  - roadmap.md L130-152 v1 継承技術決定 → R8.11, R8.12, R9.2, R14.3 ですべて引用 ✓
  - roadmap.md Phase 1 配置 → ✓

  提案する対応順

  1. 必須 5 件を修正（H / I / K → requirements.md、D / C → brief.md）
  2. roadmap / brief 同期 1 件（E）→ brief.md の Coordination も更新
  3. Design phase 持ち越し 8 件は brief.md の Design phase 持ち越しセクションに追記
  4. その後 approve

  この順で進めますか？修正必須 5 件と同期 1 件は本セッションで実施し、持ち越し 8 件を brief.md に追記してから approve、で良いか確認をお願いします。
```

##### ❯ OK

```
⏺ 順次対応します。まず requirements.md の必須 3 件を並列で修正します。
⏺ 次に brief.md の修正（コマンド名統一・Downstream 追加・Coordination 確定状態反映・Design phase 持ち越し追記）を実施します。
⏺ Design phase 持ち越しセクションに新たな 8 件を追記します。
⏺ 修正完了。spec.json を approve に更新します。

❯ approveは承認していない

⏺ 失礼しました。approve はまだ承認されていない状態に戻します。

  これまでに本セッションで適用した修正内容を整理します。

  適用済の修正（requirements.md）

  - Boundary Out of scope に L1 raw subdirectory 規約のポインタ追加（W-6）
  - R2.7: type: 許可値を「categories.yml.recommended_type ∪ entity_types.yml.name」と明示
  - R4.7 新規追加: review/decision-views/* の Tier 2 timeline frontmatter 7 field 宣言（W-3）
  - R4.8 新規追加: audit_candidates/ (Spec 4) / relation_candidates/ (Spec 5) / Follow-up (Spec 7) の再委譲明示
  - R5.5: rw graph rebuild の所管を Spec 5 に分離（指摘 I）
  - R8.2: rw tag scan と rw lint の機能境界明示
  - R8.5: Foundation 参照を §2.4 / Requirement 3 に修正（指摘 H）
  - R8.8: typo descrption → description（指摘 K）
  - R9.2: severity 出典を roadmap.md 経由に修正
  - R10.4: R3.5 schema 参照に簡素化

  適用済の修正（brief.md）

  - Constraints のコマンド名を rw graph rebuild --sync-related に統一（指摘 D）
  - Downstream に Spec 7 を追加（指摘 C）
  - Coordination 必要事項に確定状態を反映（指摘 E、inline 確定明示）
  - Design phase 持ち越しセクション拡充（軽微指摘 4 件 + 第 2 ラウンド 8 件）

  状態

  - spec.json は未更新（approvals.requirements.approved = false のまま）
  - approve せずに次の判断をお願いします

  選択肢

  - 追加レビュー: 別観点（v1-archive 参照、consolidated-spec 詳細、scenarios.md 等）でさらに精査
  - 修正の見直し: 本セッションで適用した修正のうち、再考が必要なものを指摘
  - コミット only: approve せずに本セッションの修正だけを「modify only」としてコミット
  - 保留: 何もせず、次セッションに判断を持ち越し

  どの選択肢で進めますか？または別の指示があればお知らせください。
```

#####  ❯ 本質的な観点からレビュー

```
⏺ 設計思想・論理整合・暗黙前提の本質的観点で再度精査しました。これまでの整合チェック（網羅・参照・命名）では拾えない、要件設計レベルの問題を検出しています。

  致命的 5 件（思想・論理矛盾、approve 前に判断要）

  【本-1】「強制ではなく推奨」と enforcement: required の自己矛盾

  - R1.2: 「強制ディレクトリではなく推奨パターン」を中核思想として固定
  - R7.1: enforcement 3 値（required / recommended / optional）を許可
  - ユーザーが enforcement: required を設定した時の挙動が、R1.2 と論理矛盾する
  - 本質: 「強制を許さない」思想なら required を排除すべき、または「required は将来拡張、初期は実装しない」と明示
  - 判断要: required 削除 vs 限定実装 vs design phase で詰める

  【本-2】type: field の二系統由来の混乱

  - R2.7: type: 許可値 = categories.yml.recommended_type ∪ entity_types.yml.name
  - 例: type: paper（categories 由来）と type: entity-person（entity_types 由来）が同じ field を共用
  - Spec 3 dispatch hint としての type: の意味が分裂（コンテンツ種別判定か entity 種別判定か）
  - 本質: type: は「コンテンツ種別」と「entity 種別」を別 field（例: type: と entity_type:）に分離すべきか、union で良いか
  - 判断要: union 維持（現状）/ 別 field 分離 / design phase で詰める

  【本-3】Entity-specific shortcuts の発火条件が未定義

  - ショートカット field (authored: 等) を書いた wiki ページの type: は何を持つか？
  - ショートカット展開判定は type: entity-person ベースか、ショートカット field の存在ベースか？
    - type: ベース: type がない entity ページではショートカットが無視される
    - field ベース: 誤って一般 wiki ページに authored: を書いても展開される
  - 本質: 「どのページがショートカットを持てるか」の発火条件が requirements で未明示。Spec 5 normalize_frontmatter API が判断ロジックを持つことになるが、Spec 1 で規約を決めないと Spec 5 が独自に決めることになる
  - 判断要: Spec 1 で type: ベースと明示 / Spec 5 に再委譲 / design phase

  【本-7】merge_strategy 5 値の固定が Spec 7 への過剰拘束

  - R3.4: merge_strategy: の 5 値（complementary / dedup / canonical-a / canonical-b / restructure）を Spec 1 が確定
  - R3.7: lifecycle 操作セマンティクスは Spec 7 所管
  - merge 操作の戦略選択は実質 lifecycle 操作のパラメータ → Spec 7 後発時に「6 番目の strategy が必要」となった場合、Spec 1 改版が必要
  - 本質: スキーマ宣言（field 名・型）と「許可値集合」の所管を分けるべき
  - 判断要: 5 値を「合意済事前固定」として現状維持（Spec 7 起票時に Adjacent Sync で再評価）/ Spec 7 に再委譲（許可値は Spec 7 が確定）

  【本-19】非推奨タグの successor 指定方法の不整合

  - R6.5: 非推奨タグ警告で「possible なら successor または deprecated_reason」をメッセージに含める
  - R6.1 のスキーマ定義: canonical / description / aliases / deprecated / deprecated_reason の 5 項目のみ、successor field なし
  - successor をどう表現するか不明 → deprecated_reason テキスト内に手書き想定？それとも忘れた要件？
  - 本質: R6.5 は「successor 機能あり前提」、R6.1 は「successor field なし」 → 内部不整合
  - 判断要: R6.1 に successor field 追加 / R6.5 から「successor」削除し deprecated_reason のみとする

  重要 7 件（設計判断が必要、要修正 or design phase で詰める）

  - 【本-4】source: 自由文字列の trust / dedup 機能: 同じ paper が複数表記で別ページ登録される可能性、canonical 化規約なし
  - 【本-5】related: cache stale 時の UX 保護: stale 警告 / stale 期間上限 / perspective 出力時の信頼度低下表示等が未規定
  - 【本-6】rw approve の所管が宙ぶらりん: 本 spec が新設した vocabulary_candidates/ の approve が rw approve であることを Spec 4 に暗黙要求 →
  coordination として明示が必要
  - 【本-8】update_history の生成責務分散: 誰が追記するか（手動 / Spec 6 rw extend / Spec 7 lifecycle 操作）の所管マップが Spec 1 にない
  - 【本-14】L1 raw/llm_logs/ と L3 wiki/llm_logs/ の同名混乱: 両者の関係（昇格対応？独立？）が未明示
  - 【本-17】vocabulary 操作の decision_log 自動記録対象性: tag merge/split が Foundation R12.4 の自動記録対象「人間 merge・split」に含まれるか曖昧 →
   Foundation 改版が必要かも
  - 【本-20】Entity shortcuts と related: の重複問題: Spec 5 sync が shortcuts を related: に重複展開するか、別 field として残すかが未規定

  中重要度 8 件（design phase で詰める想定が妥当）

  - 【本-9】Vocabulary 競合（並行編集時）: Git conflict 解決規約なし
  - 【本-10】tags.yml 大規模時の lint 性能: R9.3「cache せず毎回最新」が 1 万タグ超で問題化
  - 【本-11】既存 markdown への migration 手順: 本 spec 確定スキーマを既存ページに適用する規約なし
  - 【本-13】narratives / essays カテゴリ重複: 両者の使い分けが曖昧
  - 【本-15】type: 不在 entity ページの扱い: 上記【本-3】と同源
  - 【本-16】CLI 起動しないユーザーの cache stale: Spec 5 stale detection の前提崩壊
  - 【本-18】vocabulary entry の evidence chain: §2.10 適用範囲外として明示すべきか
  - 【本-21】entity_types.yml.description の用途: lint / rw tag での使い道不明

  軽微 2 件

  - 【本-12】entity-person (単数) と wiki/entities/people/ (複数) の命名不統一
  - 【本-22】rw tag * の help text / man page 所管

  総括

  これまでの修正は「文書整合・参照・命名」レベル。今回検出した本質的観点では、致命的 5 件のうち最低 3 件（本-1 / 本-3 / 本-19）は requirements
  段階で判断が必要です。

  特に 【本-19】R6.1 と R6.5 の successor 不整合は明確な内部矛盾で、本 spec 単独の修正で解決可能。

  推奨対応

  - 致命的 5 件: 1 件ずつ判断を確認しながら進める（特に本-19 は即修正対象）
  - 重要 7 件: design phase 持ち越しまたは brief.md に「今回確認しておくべき事項」として追記
  - 中 8 件 + 軽微 2 件: brief.md Design phase 持ち越しに追加

  致命的 5 件について、1 件ずつ判断を伺います。最初に 【本-19】successor 不整合 の修正方針について確認したいですが、それでよろしいですか？
```

##### ❯ はい

```
⏺ 【本-19】R6.1 と R6.5 の successor 不整合

  問題の整理

  - R6.1（スキーマ）: canonical / description / aliases / deprecated / deprecated_reason の 5 項目、successor field なし
  - R6.5（lint 動作）: 非推奨タグ警告メッセージに「possible なら successor または deprecated_reason」を含める
  - → R6.5 が前提とする successor field が R6.1 にない（内部矛盾）

  解決方針 3 案

  案A: R6.1 に successor field を追加（タグ単位の後継明示）

  - R6.1 を 6 項目に拡張: canonical / description / aliases / deprecated / deprecated_reason / successor（後継 canonical タグ名、deprecated: true 時に推奨、配列または単数文字列）
  - メリット: lint がメッセージで「old-tag は非推奨です。new-tag に置換してください」と提案できる、機械的置換も可能
  - デメリット: スキーマが 1 項目増える。successor が複数あり得る tag では複数指定の規約が必要
  - consolidated-spec §5 / §6.2 に successor field の記述があれば自然な追加

  案B: R6.5 から「successor」を削除し、deprecated_reason のみとする

  - R6.5 を「非推奨タグ警告で deprecated_reason をメッセージに含める」に修正
  - メリット: スキーマ最小化、自由文字列 deprecated_reason 内に「→ new-tag に置換」のような提案を書ける
  - デメリット: 機械的置換不可、ユーザーが deprecated_reason を毎回テキスト解析する必要

  案C: aliases 機構を流用（deprecated tag を旧 canonical の alias として扱う）

  - R6.5 から「successor」を削除
  - 運用規約: tag を deprecate する場合、その canonical を新 canonical の aliases に追加し、旧エントリは削除（完全 rename と同等）
  - メリット: 既存の alias 機構（R6.4 で WARN 報告 + canonical 提案）で「非推奨 → 後継 canonical」が自動表現される
  - デメリット: 「deprecated だが後継なし」（純粋な廃止）の場合は別扱いが必要 → deprecated: true + aliases なし

  推奨と判断材料

  - 案A 推奨: tag rename 操作（R8.6 rw tag rename）と整合し、deprecated タグの後継を機械可読にする最もシンプルな方法。スキーマを 6項目に拡張するだけで R6.5 を変更不要にできる
  - 案B: スキーマを増やさないが、UX の機械的支援を捨てる
  - 案C: 既存機構流用は美しいが、「deprecate」と「rename」のセマンティクスを混ぜることになる（非推奨 = 即時 alias 化、本来 deprecatedは「警告期間を設けてから廃止」の段階的ニュアンス）

  A / B / C どれを選択しますか？それとも別案（例: design phase 持ち越し）が良いですか？
```

##### ❯ 案A

```
⏺ R6.1 に successor field を追加します。
⏺ 【本-19】修正完了。次に【本-1】「強制ではなく推奨」と enforcement: required の自己矛盾について判断を伺います。

  【本-1】R1.2「強制せず推奨」と R7.1 enforcement: required の論理矛盾

  問題の整理

  - R1.2: カテゴリは「強制ディレクトリではなく推奨パターン」、L3 wiki ページがいずれの推奨カテゴリディレクトリに属していなくても valid
  - R1.5: 推奨カテゴリディレクトリ外のページは INFO severity 以下
  - R7.1: categories.yml の enforcement 3 値（required / recommended / optional）を許可、デフォルト recommended
  - R1.6: 初期セット 7 カテゴリの強制力は「推奨」として登録
  - → enforcement: required を許可した時の挙動が R1.2 / R1.5 の「いずれのカテゴリ外でも valid」と矛盾。required カテゴリのページがそのディレクトリ外に置かれた場合、ERROR にすべきか valid にすべきかが規定されていない

  解決方針 4 案

  案A: enforcement: required を削除し、2 値（recommended / optional）に縮約

  - R7.1 を 2 値に変更: recommended（lint で INFO 通知）/ optional（lint で何も言わない）
  - メリット: R1.2 の「強制せず推奨」原則と完全整合、思想と機能の一致
  - デメリット: 将来「特定カテゴリは厳格に置く必要がある」という運用要求が出た場合、再度 spec 改版が必要
  - 思想に最忠実

  案B: required を残し、R1.2 / R1.5 の例外規約を明示

  - R7.1: 3 値維持
  - R1.5 を修正: 「推奨カテゴリディレクトリ外のページは INFO severity 以下、ただし enforcement: required のカテゴリに該当する type:を持つページがそのディレクトリ外に配置された場合は WARN または ERROR」
  - メリット: 中核思想は保ちつつ、ユーザーが必要な時だけ厳格化を選べる
  - デメリット: 「カテゴリ該当性の判定」（ページがどのカテゴリに「該当する」のか）が type: ベースなのか別の判定なのか不明 → 新たな複雑性
  - 柔軟性最大

  案C: required を残し、「将来拡張、初期実装は recommended / optional のみ」と明示

  - R7.1 を修正: 3 値を宣言可能だが「required は将来拡張のための予約値、初期実装では受理しても WARN として扱う / 将来の severity-unification系決定で挙動確定」
  - メリット: スキーマの柔軟性を残しつつ、現在の挙動矛盾を回避
  - デメリット: 「予約だけして実装しない field」は技術負債、明確な廃止条件がないと風化する

  案D: design phase 持ち越し（最低限 R1.5 を「enforcement: required 時の挙動は design phase で確定」と但し書き）

  - requirements は両立可能な書き方に修正、design phase で詰める
  - メリット: requirements approve を急げる
  - デメリット: 致命的な思想矛盾を design phase に転嫁する設計の悪臭

  推奨

  - 案A（required 削除して 2 値に縮約） が最も中核思想と整合。R1.2「強制せず推奨」が固定方針なら、機能でも強制を許さないのが純粋
  - 将来「厳格化したい」要求が出たら、その時点で Adjacent Sync で R7.1 を 3 値に拡張すれば良い（YAGNI 原則）

  A / B / C / D どれを選択しますか？
```

##### ❯ 案A

```
⏺ R7.1 から required を削除し 2 値に縮約します。
⏺ 【本-1】修正完了。次に【本-2】type: field の二系統由来の混乱について判断を伺います。

  【本-2】R2.7 type: 許可値の二系統由来の混乱

  問題の整理

  - R2.7（修正済）: type: 許可値 = categories.yml.recommended_type ∪ entity_types.yml.name
  - 例:
    - type: paper（categories papers の recommended_type 由来 → コンテンツ種別）
    - type: entity-person（entity_types 由来 → entity 種別）
  - 同じ type: field に「コンテンツ種別」と「entity 種別」が混在
  - 影響:
    - Spec 3 dispatch hint としての type: の意味が分裂（distill skill 選択 vs entity 操作 skill 選択）
    - Spec 5 normalize_frontmatter API がショートカット展開対象を判定する時、type: を見るか別の指標を見るかが曖昧
    - lint が type: 値を検証する時、「カテゴリ由来か entity 由来か」のメタ情報を持たない

  解決方針 4 案

  案A: type: と entity_type: を別 field に分離

  - R2.2 修正: 推奨フィールドを type（コンテンツ種別、categories.yml.recommended_type 由来）と tags に固定
  - 新 field 追加: entity_type（entity 種別、entity_types.yml.name 由来、entity ページのみ）を任意フィールドとして宣言
  - メリット:
    - 意味の分離が明確、lint / Spec 3 dispatch / Spec 5 ショートカット展開がそれぞれ責務に応じた field を見れる
    - 「コンテンツ種別」と「entity 種別」は概念的に直交するので、別 field が自然
  - デメリット:
    - frontmatter field が 1 つ増える
    - 既存の Foundation R8.2「推奨フィールドとして type」との整合: entity_type は推奨ではなく「entity ページの場合の必須/推奨」と階層化が必要

  案B: type: を維持し、prefix 規約で意味を分ける

  - type: 値に prefix 規約: entity-* で始まれば entity 種別、それ以外はコンテンツ種別
  - R2.7 修正: 「type: 値が entity-* で始まる場合は entity_types.yml.name と照合、それ以外は categories.yml.recommended_type と照合」
  - メリット:
    - 既存スキーマを維持（field 追加なし）
    - prefix 規約は単純で機械判定可能
  - デメリット:
    - entity-* prefix を強制 → entity_types.yml の name が必ず entity- で始まる必要、命名が制限される
    - 将来「entity- prefix を持たない entity type」が必要になった時の拡張困難

  案C: union 維持（現状）、ただし衝突時の優先順位を明示

  - R2.7: union のまま
  - 追加規約: 「categories.yml.recommended_type と entity_types.yml.name に同名がある場合、entity_types を優先」（または逆）
  - メリット: 最小変更
  - デメリット:
    - 「両系統の値が混在」という根本問題は未解決
    - Spec 3 / Spec 5 が type: 値から「カテゴリ由来か entity 由来か」を逆引きする必要 → categories.yml / entity_types.yml 両方を読まないと判定不可

  案D: type: をコンテンツ種別のみに限定、entity 判定はディレクトリ配置で行う

  - R2.7 修正: type: 許可値 = categories.yml.recommended_type のみ
  - entity 判定: ページが wiki/entities/people/ 配下なら entity-person、wiki/entities/tools/ 配下なら entity-tool（structure.md L48-49
  のディレクトリ規約と整合）
  - メリット:
    - type: の意味がコンテンツ種別単一化、シンプル
    - structure.md のディレクトリ規約を活用
  - デメリット:
    - R1.4「frontmatter からの自動推論ではなく、ディレクトリ配置で表現」と整合だが、「カテゴリ判定はディレクトリ非依存（R1.5 でディレクトリ外も
  valid）」と矛盾（カテゴリ判定だけはディレクトリ非依存、entity 判定だけはディレクトリ依存）

  推奨

  - 案A（type: と entity_type: 分離） が最も論理的に整合
    - Foundation R8.2 の「推奨フィールドとして type」と矛盾しない（entity_type を任意フィールドとして追加）
    - Spec 3 dispatch / Spec 5 ショートカット展開 / lint がそれぞれ独立に判定可能
    - entity 機能の将来拡張（新 entity type 追加）が entity_type: field 内で完結
  - ただし 影響範囲: R2.2 / R2.7 / R5.5 / R7.1 / R11.1, 11.3 を更新する必要あり、大きめの修正

  A / B / C / D どれを選択しますか？
```

#####  ❯ 案A

```
  影響範囲

  - R2.2 / R2.3 / R2.7 / R5.5 / R5.6 / R5.7 / R7.1 / R9.1 / R11.1 / R11.3 と Boundary Context In scope

  修正計画:
  1. R2.3 (任意フィールド) に entity_type 追加（entity ページで推奨）
  2. R2.2 の type: の意味を「コンテンツ種別」に限定
  3. R2.7 を type = categories 由来、entity_type = entity_types 由来に分離
  4. R5.5 のショートカット展開判定を entity_type: ベースに明示
  5. R5.6 を「entity_type: 値が entity_types.yml.name に未登録」も対象化
  6. R9.1 の lint 項目に「許可値外の entity_type:」追加
  7. R11.3 で type と entity_type の整合分離
  8. Boundary Context In scope L33 を更新

  順次修正します。
⏺ 【本-2】修正完了。残るは【本-3】Entity-specific shortcuts の発火条件と【本-7】merge_strategy 5 値の所管。

  実は 【本-3】は【本-2】の修正で解決済です。R5.5 で「展開対象判定は entity_type: field の値ベース」と明示し、R5.6 で「entity_type:未指定でショートカット記述」を WARN 化したため、発火条件が entity_type: ベースに確定しました。

  では【本-7】の判断を伺います。

  【本-7】R3.4 merge_strategy 5 値固定の Spec 7 への過剰拘束

  問題の整理

  - R3.4: merge_strategy: の 5 値（complementary / dedup / canonical-a / canonical-b / restructure）を Spec 1 が固定
  - R3.7: lifecycle 操作セマンティクス（merge/split 動作）は Spec 7 所管
  - merge 操作の戦略選択は実質「lifecycle 操作のパラメータ」 → 本来 Spec 7 の責務領域
  - Spec 7 起票時に「6 番目の strategy が必要」となった場合、Spec 1 改版が必要（Adjacent Sync 運用ルールの適用範囲か微妙）

  解決方針 3 案

  案A: 現状維持（5 値固定）+ Spec 7 起票時 Adjacent Sync で再評価

  - R3.4 のまま、5 値を「Foundation 委譲を引き受けた事前合意」として固定
  - Spec 7 起票時に必要なら R3.4 を Adjacent Sync で更新（roadmap.md L162-168 の「先行 spec 変更による波及的な文言同期」相当か、要件追加なら再
  approval）
  - メリット:
    - 既に合意された値、本セッションで触らない
    - consolidated-spec §5 由来の値なら根拠あり
  - デメリット:
    - Spec 7 が拘束される
    - 「許可値の拡張は Spec 1 改版」が常に必要

  案B: R3.4 で 5 値を「初期セット」と明示し、Spec 7 が拡張可能と規定

  - R3.4 を修正: 「merge_strategy: の 初期許可値 として 5 値を宣言する。Spec 7 は本 spec を改版することなく、merge_strategy:
  値を追加可能とする（field 自体のスキーマと初期セットのみが本 spec の所管）」
  - 追加: 「拡張時は Spec 7 の requirements で新値を宣言し、本 spec への Adjacent Sync で値リストを反映する」
  - メリット:
    - スキーマ宣言（Spec 1）と許可値拡張（Spec 7）の責務分離が明確
    - Spec 7 の自由度確保
  - デメリット:
    - 「許可値が複数 spec で管理される」 → どこが正本か曖昧化リスク
    - Adjacent Sync の運用が増える

  案C: R3.4 から 5 値リストを削除し、Spec 7 に再委譲

  - R3.4 を修正: 「merge_strategy:（文字列、許可値集合の確定は Spec 7 所管）」と field 名と型のみ宣言
  - メリット:
    - 責務分離が最もクリーン
    - Spec 7 が完全自由
  - デメリット:
    - lint で merge_strategy: の許可値外検出（design phase 持ち越し【本-L】）が Spec 7 まで実装できない
    - 現状の Wave 2 起票時に既に値合意がある場合、削除はもったいない

  推奨

  - 案B（初期セット明示 + Spec 7 拡張可） がバランス良
    - 現在の合意値を保持しつつ、Spec 7 の拡張余地を確保
    - 「値の正本は Spec 1、Spec 7 が追加要請を出す」と明示することで多重管理を回避
    - Adjacent Sync 運用ルールの典型的な適用ケース
  - 本質的には案C（完全委譲）も論理的だが、現状で値合意がある（consolidated-spec 由来）なら案B が無駄がない

  A / B / C どれを選択しますか？
```

##### ❯ 案B

```
⏺ R3.4 を修正します。
⏺ 致命的 5 件すべて修正完了です。

  致命的 5 件修正サマリ

  - 【本-1】: R7.1 の enforcement を 2 値に縮約（required 削除、思想統一）
  - 【本-2】: R2.2 / R2.3 / R2.7 で type: と entity_type: を別 field に分離、責務直交化
  - 【本-3】: R5.5 / R5.6 でショートカット展開判定を entity_type: ベースに明示（【本-2】修正で連動解決）
  - 【本-7】: R3.4 の merge_strategy 5 値を「初期セット + Spec 7 拡張可」に変更
  - 【本-19】: R6.1 に successor field 追加（内部矛盾解消）

  連動修正

  - R5.5 / R5.6: ショートカット発火条件
  - R9.1: lint 検査項目に entity_type: 系 4 種追加 + entity_types.yml 重複登録 ERROR
  - R11.3: type: と entity_type: の許可集合を独立規定

  残対応の選択肢

  1. 重要 7 件【本-4 〜 8, 14, 17, 20】の判断: 今回の致命的修正の波及で軽くなったものもあれば、依然要判断のものも
  2. brief.md の Design phase 持ち越しに残課題追記
  3. 本セッションで適用した致命的修正の最終整合確認（R5.5 / R5.6 など修正後の文面チェック）
  4. approve は次セッション持ち越し

  どれで進めますか？特に 重要 7 件の議論を続けるか、致命的修正の確認に絞るか の判断を伺いたいです。
```

##### ❯ 重要 7 件の議論を続ける

```
⏺ 【本-4】R2.1 source: 自由文字列の trust / dedup 機能

  問題の整理

  - R2.1: source を「自由文字列、URL / DOI / meeting ID / 書籍名等」として固定
  - 影響シナリオ:
    - 同じ paper が https://arxiv.org/abs/2401.12345 / arXiv:2401.12345 / Smith et al. 2024 と複数表記で別 wiki ページとして登録
    - Trust chain（§2.10）の起点として source: が機能するには、何らかの canonical 化が必要
    - 一方、自由度を持たせないと「meeting ID」「書籍名」「会話ログ」等の多様性に対応できない
  - 本質: trust 機能 vs 表記柔軟性のバランス

  解決方針 4 案

  案A: 現状維持（自由文字列、canonical 化はユーザー責任）

  - R2.1 のまま、本 spec では何も追加しない
  - 重複検出は別 spec / 別 task が担当（暗黙）
  - メリット: 最小変更、表記柔軟性最大
  - デメリット: dedup 問題が解決されない、trust chain の信頼性が source 表記の self-discipline 任せ

  案B: lint で同一識別子の検出を支援（緩い canonical 化）

  - R9.1 に追加: 「複数ページの source: に類似識別子（URL の正規化形 / DOI / arXiv ID 等の機械抽出可能パターン）が検出された場合、INFO で通知」
  - メリット: 表記柔軟性を保ちつつ、dedup の人間チェックを支援
  - デメリット: 「類似識別子」の検出ロジックの所管が曖昧（design phase で確定）

  案C: source: を構造化（source: { type: arxiv, id: 2401.12345 } 等）

  - R2.1 を修正: source を構造化 dict として定義、type（必須、url/doi/arxiv/meeting/book/free の値域）+ value（必須、type に応じた識別子）
  - メリット: 機械可読、dedup / audit が容易、trust chain の信頼性向上
  - デメリット:
    - 既存の自由度を失う（free 型でカバー可能だが）
    - frontmatter の冗長化（YAML 1 行 source: https://... → 3 行）
    - Foundation R8.1 の「共通必須フィールドとして title / source / added」との整合は保たれるが、R2.1 の「自由文字列」前提が変わる

  案D: Spec 1 で「source: の dedup / canonical 化責務」を Spec 4 audit task に再委譲、本 spec では言及せず design phase で詰める

  - R2.1 のまま、Boundary Adjacent expectations に「source: の重複検出・canonical 化支援は Spec 4 audit task が所管」と明示
  - メリット: 本 spec の責務範囲を明確に絞る
  - デメリット: Spec 4 への暗黙要求の追加、Spec 4 起票時に拘束

  推奨

  - 案D（Spec 4 audit に再委譲 + design phase で詰める） がバランス良
    - 本 spec は「frontmatter スキーマ宣言」が責務、dedup logic は audit task の領域
    - Spec 4 audit task カテゴリ（Foundation R9.2 で audit (links/structure/semantic/strategic/deprecated/tags/evidence/followups) がある）に「source
   dedup」を追加する自然な拡張
    - 構造化（案C）は将来の拡張余地として残せる
  - 案C（構造化） は最も厳格だが、「自由文字列」合意の覆しになるため、本セッションでは過大変更
  - 案B（lint INFO） は中庸だが、dedup ロジックの所管曖昧化リスク

  A / B / C / D どれを選択しますか？
```

##### ❯ 案D

```
⏺ R2.1 はそのまま、Boundary Adjacent expectations に Spec 4 への再委譲を明示し、brief.md に design phase 持ち越しを追加します。
⏺ 【本-4】完了。次に【本-5】related: cache stale 時の UX 保護です。

  【本-5】R10 related: cache stale 時の UX 保護

  問題の整理

  - R10.2: cache 鮮度は eventual consistency
  - R10.7: ユーザー手動編集を許可、次回 sync で上書き
  - 影響シナリオ:
    - stale な related: を見た perspective generator が誤った関係性を出力 → ユーザーは正しい関係性を知らない
    - 「最後に sync したのが 6 ヶ月前」のような長期 stale がユーザー UX で気付かれない
    - eventual consistency の許容は妥当だが、stale 警告 UX / stale 期間上限規約等の保護機構がない
  - 本質: cache の信頼性を eventual consistency にした時の「stale を許容する範囲」と「stale を可視化する責務」が未明示

  解決方針 4 案

  案A: 現状維持（保護機構は Spec 5 に完全委譲、本 spec で言及せず）

  - R10 のまま
  - stale 検出・警告 UX は Spec 5 / Spec 6 が独自に判断
  - メリット: 本 spec の責務を絞る
  - デメリット: cache 利用側の各 spec が独自判断 → UX 一貫性が崩れる

  案B: 本 spec で「stale マーカー frontmatter field」を宣言（受動的保護）

  - R10 に追加: 「related: cache の各要素に任意 field stale: true / stale_since: YYYY-MM-DD を Spec 5 sync 機構が追記可能にする schema 拡張を本 spec
  で宣言する」
  - メリット: cache 利用側 spec が stale flag を見て信頼度を判断可能、UX 一貫性確保
  - デメリット: schema が複雑化、Spec 5 sync 機構の実装複雑度増

  案C: Boundary Adjacent expectations で「stale UX 責務は Spec 5 / Spec 6」と明示

  - R10 のまま、Adjacent expectations に追加: 「related: cache の stale 検出・警告 UX・stale 期間上限規約は Spec 5（sync 機構実装側）と Spec
  6（perspective / hypothesize 利用側）が所管」
  - メリット: 責務再委譲が明確、本 spec は最小変更
  - デメリット: Spec 5 / Spec 6 への暗黙要求の追加、interface 詳細は design phase 持ち越し

  案D: 案B と案C を組み合わせ（schema 拡張 + adjacent 委譲）

  - R10 に「stale flag schema 拡張」（案B）を追加、かつ「警告 UX / 期間上限は Spec 5 / Spec 6」（案C）を Adjacent expectations に明示
  - メリット: schema 一貫性 + UX 責務分離が両立
  - デメリット: 修正箇所が多い

  推奨

  - 案C（Adjacent 委譲のみ） が本 spec の責務範囲と整合
    - 本 spec は「cache 規約（正本は Spec 5、eventual consistency 許容、上書きされ得る）」までを所管
    - stale 検出 / UX / 期間上限は cache 利用側 の責務 → Spec 5 (sync 実装) と Spec 6 (perspective 出力時の信頼度表示) が所管
    - schema 拡張（案B / D）は将来必要になれば Adjacent Sync で追加可、初期から複雑化させない（YAGNI）

  A / B / C / D どれを選択しますか？
  
```

##### ❯ 案Dを再検討

```
⏺ 案D を詳細化します。stale 表現の粒度に応じて 3 サブ案あります。

  案D の詳細化（schema 拡張 + Adjacent 委譲の組み合わせ）

  共通部分

  - R10 Adjacent expectations: 「stale 検出・警告 UX・stale 期間上限規約は Spec 5 (sync 機構実装側) と Spec 6 (perspective / hypothesize 利用側)
  が所管」
    - R10 に schema 拡張 AC を追加

  Schema 拡張の粒度（3 サブ案）

  案D-a: 要素レベル stale flag（細粒度）

  - related: の各オブジェクトに任意 field を追加: stale（boolean、デフォルト false）/ stale_since（YYYY-MM-DD、stale 化日）
  - Spec 5 sync 機構が個別 edge を比較して stale を flag
  - Pros: 個別 edge ごとの stale 判定可能（一部 edge のみ古いケースに対応）
  - Cons:
    - cache 構造の冗長化（各要素に flag 2 つ）
    - sync 機構の実装複雑度増（edge ごとに比較必要）
    - 要素レベル stale を活用する UX が複雑（perspective が 5 関係のうち 2 つだけ stale をどう表現するか）

  案D-b: ページレベル synced_at timestamp（軽量）

  - ページ frontmatter に任意 field を追加: related_synced_at（YYYY-MM-DD、最終 sync 日付、Spec 5 sync 機構が更新）
  - stale 判定は age で行う（30 日経過なら警告、180 日経過なら ERROR 等は Spec 5 / Spec 6 が決定）
  - Pros:
    - 軽量・シンプル（field 1 つ追加のみ）
    - stale age による判定は実装が容易
    - cache 利用側 (Spec 6) が「related_synced_at を見て信頼度を表示」できる
  - Cons: 一部 edge のみ stale でもページ全体が stale 扱い

  案D-c: 両方併用

  - ページレベル + 要素レベル両方
  - Pros: 最大の表現力
  - Cons: 過剰、初期実装 burden 大、YAGNI 違反

  推奨

  - 案D-b（ページレベル related_synced_at:） が実用的
    - 単一 timestamp field の追加のみで schema 影響最小
    - Spec 5 sync 機構の実装が単純（ページ単位で sync 完了時刻を書き込む）
    - Spec 6 perspective が信頼度表示する時の判断材料になる（「関係情報は X 日前のデータに基づきます」等）
    - 要素レベル stale が必要になれば将来 Adjacent Sync で D-a 相当を追加可能
  - 案D-a / D-c は要素単位の stale 表現が必要になる具体的シナリオが見えないと過剰設計

  D-a / D-b / D-c どれを選択しますか？
```

##### ❯ D-bを選択したとして、R10 related: cache stale 時の UX 保護の問題は解決できるか

```
 慎重に解決度を分析します。

  【本-5】4 つの本質問題と案D-b の解決度マッピング

  問題1: stale な related: を見た perspective が誤った関係性を出力

  - 案D-b の解決度: △ 部分解決
  - related_synced_at の age が表示されることで、Spec 6 perspective は「N 日前のデータに基づく信頼度」を表示できる
  - ただし: age が新しくても「sync 後に L2 で edge_status が変わった / edge が削除された / 新 edge が追加された」等の 質的乖離 は age では検出不可能
  - 質的乖離の完全検出には rebuild 実行が必要 → これは Spec 5 sync 機構の責務、案D-b の schema では捉えきれない

  問題2: 「最後に sync したのが 6 ヶ月前」のような長期 stale が UX で気付かれない

  - 案D-b の解決度: ○ 解決
  - related_synced_at の age を Spec 5 / Spec 6 が読み、閾値超過で警告 UX 表示
  - 30 日 / 180 日 等の閾値は Spec 5 / Spec 6 が決定（本 spec は schema 提供のみ）

  問題3: stale 警告 UX / stale 期間上限規約等の保護機構がない

  - 案D-b の解決度: ○ schema レベルで解決、UX 実装は委譲
  - schema として related_synced_at を提供 → cache 利用側が判断できる基盤になる
  - 検出・警告 UX・期間上限の実装は Spec 5 / Spec 6（Adjacent 委譲）

  問題4: stale を許容する範囲 / 可視化する責務が未明示

  - 案D-b の解決度: ○ 解決
  - Adjacent expectations で「Spec 5 が sync 機構と stale 検出、Spec 6 が利用側の信頼度表示」を明示
  - 責務分担が明確化

  解決度の総括

  - 案D-b で解決: 4 つのうち 3 つ（問題2 / 3 / 4）
  - 案D-b で部分解決: 1 つ（問題1、age による近似支援）
  - 案D-b で解決できない: 質的乖離の完全検出（rebuild なしでは原理的に不可能、sync 機構の責務）

  - 案D-b で解決: 4 つのうち 3 つ（問題2 / 3 / 4）
  - 案D-b で部分解決: 1 つ（問題1、age による近似支援）
  - 案D-b で解決できない: 質的乖離の完全検出（rebuild なしでは原理的に不可能、sync 機構の責務）

  「Spec 1 の責務範囲内」では完全解決か

  - 本 spec の責務範囲: frontmatter スキーマ宣言 + cache 利用側の規約定義
  - 本 spec の責務範囲外: sync 機構の実装、UX 表示の実装、質的乖離の検出ロジック
  - 判定: 案D-b は Spec 1 の責務範囲内では問題完全解決。Spec 1 がやれることは「schema を提供して責務を委譲する」までで、それを超える UX 保護は他 spec
   の責務として明示済み

  ただし、残課題

  - 質的乖離問題（問題1の完全解決）: 案D-b では支援不可。これは Spec 5 sync 機構の「rebuild ポリシー」と Spec 6 の「stale 時の不確実性表示
  UX」で対応すべき → brief.md Design phase 持ち越しに明示する必要あり
  - stale age 閾値: 本 spec で固定しない方針 → Spec 5 / Spec 6 が決定、これも brief.md 持ち越し

  結論

  - 案D-b で本 spec 責務範囲内の解決は完了
  - ただし「Spec 1 だけで本-5 の全側面が解決」ではない（design 設計レベルでは Spec 5 / Spec 6 への要求事項として残る）
  - これを正直に明示するため、brief.md の design phase 持ち越しに「本-5 の質的乖離検出と UX 閾値は Spec 5 / Spec 6 の design
  段階で確定」を追記する必要あり

  判断

  案D-b で進めて良いか、それとも以下の選択肢を検討するか：

  - A: 案D-b で進める（schema 拡張 + Adjacent 委譲、本 spec 責務内では十分）
  - B: 案D-c（要素レベル + ページレベル両方）に格上げ → 質的乖離の部分検出に近づくが、schema 複雑化
  - C: 案D-b + Spec 5 / Spec 6 への要求項目を Boundary Adjacent expectations に詳細記載（本 spec から積極的に「rebuild ポリシー要件」「UX
  閾値要件」を委譲）
  - D: 案D 系を諦め、案C（schema 拡張なし、Adjacent 委譲のみ）に戻る → 本 spec の責務範囲を最小化

  どれで進めますか？
```

##### ❯ 案Cで問題解決を図れるか

```
⏺ 案C と案D-b を【本-5】問題解決度で再評価します。

  案C による解決度マッピング

  問題1: stale な related: で誤った関係性出力

  - 案C: ✗ schema 拡張なし → cache 利用側が「stale か否か」を frontmatter から判定する手段がない
  - ただし Spec 5 sync 機構が独自に sync 履歴メタデータ（例: .rwiki/graph/sync_log.jsonl）を持てば、cache 利用側 (Spec 6) はそれを読んで判定可能
  - 案D-b との差: 判定情報の所在が「frontmatter」か「Spec 5 独自メタデータ」か

  問題2: 長期 stale の気付き

  - 案C: △ 解決可能（条件付き）
  - Spec 5 が sync ログメタデータを管理し、Spec 6 が age を取得して UX 警告すれば対応可能
  - ただし Spec 5 / Spec 6 設計に完全依存

  問題3: 保護機構の不在

  - 案C: △ 解決可能だが UX 一貫性リスク
  - Spec 5 / Spec 6 が独自実装するため、メタデータの形式・場所が本 spec で規定されない
  - → 将来別の cache 利用側（perspective / hypothesize / extend 等）が増えた時、各自の実装が分岐するリスク

  問題4: 責務未明示

  - 案C: ○ Adjacent expectations で明示すれば解決

  案C と案D-b の本質的トレードオフ

  案D-b（frontmatter 拡張）の特徴

  - Pros:
    - cache 利用側 (Spec 6) が frontmatter を読むだけで stale 判定可能、実装が単純
    - schema として明示されるため、将来増える cache 利用側で UX 一貫性確保しやすい
  - Cons:
    - frontmatter の純度低下: 「人間が編集する文書メタデータ」に「機械が管理する sync 状態」が混在
    - Spec 5 sync 機構が wiki ページの frontmatter を更新する必要 → ファイル更新の副作用増

  案C（Adjacent 委譲のみ）の特徴

  - Pros:
    - frontmatter 純度維持: 文書メタデータと cache 状態メタデータを別レイヤーに分離（責務分離としてクリーン）
    - 本 spec の責務範囲が最小、Spec 5 sync 機構が独自にメタデータ設計できる自由度
    - Spec 5 sync は wiki ページを物理更新せず、.rwiki/graph/ 配下に sync ログを書くだけで済む（ファイル更新の副作用最小）
  - Cons:
    - Spec 5 / Spec 6 のメタデータ設計が分岐するリスク（design phase での coordination が重要）
    - cache 利用側が Spec 5 メタデータに依存（実装結合度増）

  本質的観点での再評価

  - frontmatter は「人間が読み書きする文書メタデータ」、sync 状態は「機械が管理する cache 鮮度」
  - 概念的に直交する 2 種類のメタデータを別レイヤーに分けるのが、設計原則（関心の分離）に忠実
  - L3 wiki の frontmatter を機械が頻繁に書き換えるのは、§2.3「Status frontmatter over directory」の精神と微妙に衝突（status は人間判断、sync
  は機械処理）

  結論

  - 案C で問題解決可能、ただし以下の条件付き:
    a. Adjacent expectations で「Spec 5 が sync 履歴メタデータ（場所・形式は Spec 5 設計）を独自管理し、cache 利用側がそれを参照する」と明示
    b. brief.md design phase 持ち越しに「Spec 5 sync メタデータの設計（場所 / 形式 / sync log エントリ schema）」「Spec 6 stale UX
  閾値・警告表示の設計」を追加
    c. UX 一貫性のため、design phase で Spec 5 / Spec 6 間の coordination を明示
  - 本質的には案C の方が設計品質が高い:
    - frontmatter 純度維持
    - 関心の分離（文書 vs cache 状態）
    - §2.3 精神との整合
    - 本 spec 責務範囲の最小化（YAGNI 原則）

  推奨判定

  - 案C を選択 し、Adjacent expectations 明示 + brief.md design phase 持ち越し追加で対応
  - 案D-b は「frontmatter に機械管理 field を追加する」設計汚染を伴うため、本-5 の解決手段としては過剰

  案C で進めて良いですか？
```

##### ❯ 案Cで

```
⏺ 【本-5】完了。次に【本-6】rw approve の所管が宙ぶらりんです。

  【本-6】rw approve の所管が宙ぶらりん

  問題の整理

  - R8.5: rw tag merge / split → review/vocabulary_candidates/ に candidate 生成 → rw approve で初めて vocabulary と既存 markdown が更新される
  - rw approve は本 spec 所管外（Foundation R9.2 で Approval カテゴリのコマンド、Spec 4 cli-mode-unification 想定）
  - ただし rw approve がどの review 層を扱うかが未明示:
    - review/synthesis_candidates/ → 既存（Foundation R8.4 で言及）
    - review/vocabulary_candidates/ → 本 spec で新設（R4.4, R4.5）
    - review/audit_candidates/ → R4.8 で Spec 4 委譲
    - review/relation_candidates/ → R4.8 で Spec 5 委譲
    - review/decision-views/ → R4.7 新設（render は Spec 5、approve は？）
  - 本質: 本 spec が新設した vocabulary_candidates/ の approve が rw approve であることを Spec 4 に 暗黙要求 している。coordination として明示が必要

  解決方針 4 案

  案A: R4 / R8.5 に「rw approve 拡張責務は Spec 4」と明示（最小修正）

  - R4.5 または新 AC で「review/vocabulary_candidates/* の approve 処理は Spec 4 の rw approve コマンドが扱うこと」を本 spec の Spec 4
  への要求として明示
  - Adjacent expectations に Spec 4 拡張責務を追加
  - メリット: 最小変更、暗黙要求を明示化
  - デメリット: rw approve の各 review 層への分岐ロジックは Spec 4 design 持ち越し

  案B: Spec 4 への要求事項を Boundary Adjacent expectations に統合

  - 案A に加えて、Adjacent expectations の Spec 4 関連箇所を拡張: 「Spec 4 の rw approve は本 spec が新設する review/vocabulary_candidates/、および本
   spec が再委譲する review/audit_candidates/ / review/relation_candidates/ / review/decision-views/ 等の各 review
  層を統括的に扱うコマンドとして実装する」
  - メリット: 全 review 層の approve 責務が一元的に明示される
  - デメリット: 他 spec の責務（audit_candidates の approve は Spec 4 audit task 自身が扱うかも、relation_candidates は Spec 5
  が独自コマンドを持つかも）を Spec 1 が決めることになる

  案C: 本 spec では rw approve に言及せず、generic な「approve 機構」と表記

  - R8.5 を修正: 「rw approve で初めて」→「approve 機構で初めて」
  - 「approve 機構」の具体実装（コマンド名・呼出方法）は Spec 4 に完全委譲、本 spec では言及しない
  - メリット: 本 spec の責務を最小化
  - デメリット: 暗黙要求は残る（Spec 4 が approve 機構を実装することは前提）

  案D: Spec 4 起票時の coordination として brief.md / design phase に持ち越し

  - requirements.md は変更なし
  - brief.md design phase 持ち越しに「Spec 4 起票時に rw approve の各 review 層対応範囲を coordination で確定」と追記
  - メリット: 修正最小
  - デメリット: requirements 段階で coordination が明示されないリスク

  推奨

  - 案A（最小修正で明示化） が本 spec の責務範囲として妥当
    - 本 spec が新設した vocabulary_candidates/ の approve は本 spec が責務マップする必要がある
    - audit_candidates/ / relation_candidates/ / decision-views/ は R4.8 で既に Spec 4/5/7 への再委譲を明示済 → それぞれの所管 spec が approve機構を含めて設計
    - 案B は他 spec 領域への過剰介入、案C は暗黙要求が残る、案D は coordination 機会を逃す

  A / B / C / D どれを選択しますか？
```

#####   ❯ 案A

```
⏺ R4 に新 AC を追加し、R8.5 と Adjacent expectations を更新します。
⏺ 【本-6】完了。次に【本-8】update_history の生成責務分散です。

  【本-8】R3.6 update_history の生成責務不明

  問題の整理

  - R3.6: update_history: 要素を宣言（date / type / summary / evidence）
  - 誰が update_history を追記するのか？:
    - type: extension → Spec 6 rw extend の出力時？ ユーザー手動？
    - type: refactor → ユーザー手動？
    - type: deprecation → Spec 7 lifecycle 操作時の自動追記？
    - type: merge → Spec 7 merge 操作時の自動追記？
  - 影響: 生成責務が複数 spec に分散する可能性、Spec 1 でその全体像を見渡せていない
  - 本質: スキーマ宣言（field 名・型）と「誰が・いつ書くか」のセマンティクスが Spec 1 の責務領域から外れているが、責務マップが不在

  解決方針 4 案

  案A: R3.7 と同じ方針で「セマンティクス（生成責務）は所管 spec」と明示

  - R3.6 の末尾または新 AC で「update_history の 生成責務（誰が・いつ追記するか）は各操作所管 spec が担う: type: deprecation / merge / split 等のlifecycle 起源は Spec 7、type: extension 等の synthesis 起源は Spec 6、ユーザー手動編集は許可」と明示
  - メリット: Spec 1 は schema 宣言のみ、生成責務マップを明示することで暗黙要求を解消
  - デメリット: 各 spec への要求事項が増える（ただし既に責務分離されているので確認に近い）

  案B: update_history.type の許可値を定義し、各 type → 所管 spec のマッピング表を本 spec で固定

  - R3.6 を修正: type 許可値（extension / refactor / deprecation / merge / split / manual 等）を確定し、各 type に「自動追記主体 spec」を併記
  - メリット: 責務マップが requirements で完全可視化
  - デメリット:
    - スキーマと所管マップを Spec 1 が一手に握る → 各 spec の自由度低下
    - 新 type 追加のたびに Spec 1 改版必要

  案C: schema 宣言のみ維持、生成責務は完全に design phase 持ち越し

  - R3.6 のまま、brief.md design phase 持ち越しに「update_history 生成責務マップを各 spec design phase で確定」と追記
  - メリット: 修正最小
  - デメリット: requirements 段階で責務マップが曖昧、各 spec 起票時に再議論

  案D: 案A + 案B の中間（生成責務 spec のみ明示、type 許可値は examples 程度）

  - R3.6 はそのまま「type: の例として extension / refactor / deprecation / merge 等」を維持
  - 新 AC で「生成責務マップ: lifecycle 起源（deprecation / merge / split / archive 等）は Spec 7、synthesis 起源（extension / refactor 等）は Spec 6
   / Spec 4 distill、ユーザー手動編集は許可。各 type の正規許可値リストは所管 spec が確定」と明示
  - メリット: 責務分離明示 + type 拡張の自由度確保
  - デメリット: 案A とほぼ同等、若干詳細

  推奨

  - 案A がバランス良
    - R3.7 で既に「status: 等の field のセマンティクスは Spec 7 所管」と委譲している方針と一貫
    - schema 宣言（field 存在・型）と生成責務（誰が書くか）の責務分離が明確
    - 案B は Spec 1 が type 許可値を固定する過剰拘束、案C は明示機会を逃す

  A / B / C / D どれを選択しますか？
```

##### ❯ 案A

```
⏺ 【本-8】完了。次に【本-14】L1 raw/llm_logs/ と L3 wiki/llm_logs/ の同名混乱です。

  【本-14】L1 raw/llm_logs/ と L3 wiki/llm_logs/ の同名混乱

  問題の整理

  - R1.1: L3 wiki 配下の初期推奨カテゴリに llm_logs を含む
  - structure.md L36: L1 raw 配下に raw/llm_logs/{interactive,chat-sessions,manual}/
  - → L1 raw / L3 wiki の両方に llm_logs/ 同名ディレクトリ
  - 影響シナリオ:
    - 「LLM ログを wiki ページとして承認したもの」が L3 llm_logs/ か？
    - L1 raw の LLM ログは distill されて L3 の他のカテゴリ（articles / notes 等）に行くのか、llm_logs/ に残るのか？
    - ユーザーが「LLM 関連の wiki」を探す時、L1/L3 のどちらを見るか混乱
  - 本質: L1 raw llm_logs/ と L3 wiki llm_logs/ の関係（昇格対応？独立？）が未明示

  解決方針 4 案

  案A: L3 llm_logs/ を初期カテゴリから削除（混乱の根本除去）

  - R1.1 修正: 初期推奨カテゴリ 7 種から llm_logs を削除し、6 種に縮約
  - 理由: L1 raw からの distill 出力は他カテゴリ（articles / notes 等）に分類すれば足り、L3 で llm_logs/ を保持する必然性がない
  - ユーザーが LLM 由来の wiki を欲しい場合は frontmatter source: で「llm chat session」等を記入する規約で代替
  - メリット: 混乱の根本除去、命名衝突解消
  - デメリット: consolidated-spec §X / brief.md L12 で 7 カテゴリ合意済の覆し（合意覆しコスト）

  案B: L3 llm_logs/ を残し、L1 との関係性を明示（昇格対応規約）

  - R1 に新 AC 追加: 「L3 llm_logs/ は L1 raw/llm_logs/ 由来のログを承認・整形した wiki ページの配置先として位置付ける（昇格対応関係）。L1 rawのログを distill した結果は、対象 LLM 出力の性質に応じて L3 llm_logs/ または他カテゴリ（notes / essays 等）のいずれかに配置可能」
  - メリット: 既存合意維持、関係性明示で混乱解消
  - デメリット: 昇格対応関係の暗黙ルールが increases、distill skill 選択が複雑化

  案C: L3 を rename して衝突回避（例: llm_logs/ → llm_synthesis/ / llm_records/）

  - R1.1 修正: 初期 7 カテゴリのうち llm_logs → llm_records（または別名）
  - メリット: 命名衝突解消、L1/L3 の役割を字面で区別
  - デメリット: 7 カテゴリの一貫性（articles/papers/notes 等は contents 種別、llm_records だけ origin 種別）が崩れる

  案D: 両者の関係性を Adjacent expectations / Boundary Out of scope で明示するのみ

  - R1.1 はそのまま（7 カテゴリ維持）
  - Boundary Out of scope か Adjacent expectations に「L1 raw/llm_logs/ と L3 wiki/llm_logs/ は同名だが独立ディレクトリ。L1 raw は LLM
  出力の生ログ蓄積、L3 wiki は承認済 LLM ログの整理版として位置付ける」と明示
  - メリット: 最小変更、関係性明示
  - デメリット: 暗黙の昇格対応ルールは未確定（design phase or 別 spec で詰める）

  推奨

  - 案D（明示のみ） がバランス良
    - 7 カテゴリ合意を覆さない
    - 「同名だが独立、関係性は緩い」という軽い明示で混乱を避ける
    - 厳密な昇格規約は distill skill 設計（Spec 2/3）に依存するので design phase 持ち越し
    - 案A は合意覆しコスト、案B は規約の重さ、案C は一貫性破壊

  ただし、本質的観点で再評価すると：

  - 「LLM ログ」を独立カテゴリとして L3 に置く必要性自体が疑問（案A の正当性）
  - 7 カテゴリのうち他 6 つ（articles / papers / notes / narratives / essays / code-snippets）は content 種別
  - llm_logs だけが origin 種別（出所が LLM）
  - 概念軸が不一致 → 一貫性として案A or 案C が論理的にクリーン

  A / B / C / D どれを選択しますか？
```

##### ❯ 今後の長い開発過程を考えると、論理的な明確性の点でAかCが良いと思う。現時点での対応コストは今後に比べると少ない。どちらがよいか？

```
⏺ 長期開発・論理明確性の観点で案A と案C を本質的に比較します。

  概念軸の統一性で評価

  案A（L3 llm_logs/ 削除、6 カテゴリ）

  - 残る 6 カテゴリ（articles / papers / notes / narratives / essays / code-snippets）は すべて content 種別（書かれている内容の性質で分類）
  - 概念軸が完全統一 → カテゴリの意味が一貫
  - 「カテゴリは content 種別」という単一原則 が将来の全カテゴリ追加判断の基準になる

  案C（rename して llm_records 等、7 カテゴリ維持）

  - 6 カテゴリは content 種別、llm_records だけ origin 種別（出所が LLM）
  - 概念軸が混在 → カテゴリ概念の意味が不純
  - 将来「voice_transcription」「ai_generated_images」「ocr_notes」等の origin 起源が登場した時、カテゴリ追加すべきか tagsで表現すべきかの判断基準が曖昧

  長期拡張耐性で評価

  案A の拡張シナリオ

  - 新しい origin（音声録音 / 動画要約 / OCR / API 取得 等）が登場 → カテゴリ追加せず source: 自由文字列 + tags: で対応
  - カテゴリは content 種別軸でのみ拡張（例: 将来 tutorials / reviews 追加検討時、軸が明確）
  - → Spec 1 改版頻度が低い

  案C の拡張シナリオ

  - 新 origin が登場するたびに「これは専用カテゴリ持つべきか」の議論が必要
  - llm_records を許した非対称性が「voice / ai_image 等も独自カテゴリ持って良い」前例化 → カテゴリ膨張リスク
  - → Spec 1 改版頻度が高くなる、カテゴリ概念の純度が時間経過で更に薄まる

  L1 / L3 の役割明確化で評価

  案A

  - L1 = raw 入力（origin 起源の物理分類）: raw/incoming/ / raw/llm_logs/ 等
  - L3 = 整理済 content（content 種別の論理分類）: articles/ / notes/ 等
  - 層の意味が直交 → アーキテクチャ理解が容易

  案C

  - L1 / L3 両方に同種カテゴリ（content/origin 混在）
  - 層別の意味的差異が見えにくい

  「LLM 起源だけ特別」の正当性

  案C で llm_records を残す根拠は「LLM ログは高頻度・自動生成・大量で特殊」だが、これは長期で見て本当に正当か？

  - 短期（現在 v2 開発）: ✓ Claude Code 等の LLM 出力が主要な origin → 特別扱いに合理性あり
  - 中期（2-3 年後）: △ 音声入力・AI 画像・他 AI tool が主流化 → LLM だけ特別扱いの根拠が薄れる
  - 長期（5 年+）: ✗ 「AI 出力」が普通の origin になり、llm_records カテゴリは時代遅れの命名

  → 案C の正当性は短期的には強いが、長期では崩れる

  推奨判定: 案A

  長期開発・論理明確性の観点で、案A が以下の点で優位:

  1. 概念軸の単一性（カテゴリ = content 種別のみ）
  2. 将来拡張耐性（新 origin が来てもカテゴリ増やさず対応）
  3. L1 / L3 の役割明確化（origin vs content の層別分担）
  4. 時代非依存性（LLM 特別扱いを避け、5 年後も意味が薄れない設計）

  案A 採用時の補足対応

  - 「LLM 関連 wiki だけ見たい」UX 要求は tags: 運用 で代替（例: tags: [llm-derived, claude-output]）
  - v1 の llm_logs/ 利用実績は v2 が新規なので影響なし
  - 既存合意覆しコストは「カテゴリ 7 → 6」の brief.md / consolidated-spec 同期のみで小

  採用しない案C の合理性

  - LLM ログ専用 navigate UX は短期的に便利
  - ただし tags 運用でも実用十分

  案A で進めて良いですか？
```

##### ❯ 案Aで進める。この場合、他スペックへの影響がでるが、それも精査

```
⏺ llm_logs 参照箇所を全プロジェクトで精査します。
⏺ L1 raw 関連と L3 wiki カテゴリ関連で参照が分かれています。L3 カテゴリとしての llm_logs 参照のみを精査します。
⏺ 精査結果を整理します。

  影響範囲の精査結果

  必須修正（L3 wiki カテゴリ参照、本セッションで修正）

  Spec 1 (本 spec)

  - requirements.md L32 (Boundary In scope): 7 カテゴリ列挙
  - requirements.md L71 (R1.1): 7 カテゴリ定義
  - requirements.md L76 (R1.6): 「7 カテゴリの強制力」
  - requirements.md L157 (R7.3): 7 カテゴリ列挙
  - brief.md L12: 7 カテゴリ合意記述
  - brief.md L95 (Design phase 持ち越し S): 「初期 7 カテゴリ」表記

  影響なし（L1 raw 関連のみ）

  - steering/structure.md L34: raw/llm_logs/{interactive,chat-sessions,manual}/ → L1 raw のみ、影響なし
  - Spec 0 (foundation): raw/llm_logs/ 例示のみ
  - Spec 5: raw/llm_logs/chat-sessions/ のみ
  - Spec 6: raw/llm_logs/chat-sessions/ raw/llm_logs/interactive/ 多数だが全て L1 raw

  要確認・後続対応

  Spec 2 (skill-library) — 中重要度

  - L99: applicable_categories（文字列配列、推奨される content category 一覧）を skill frontmatter に許容
  - 現状の Spec 2 requirements には具体的な category 名は列挙なし
  - 問題: consolidated-spec.md L2572 で llm_log_extract skill が applicable_categories: [llm_logs] を持つ
  - 影響評価:
    - もし llm_log_extract の applicable_categories が L3 wiki llm_logs 前提 → Spec 2 起票時に修正必要
    - ただし llm_log_extract は L1 raw raw/llm_logs/ を入力対象とする skill → 本来 L3 カテゴリ llm_logs ではなく L1 raw input path 規約で表現すべき
  - 対応方針: Spec 1 → Spec 2 への coordination 要求として brief.md design phase 持ち越しに「skill applicable_categories の値域は L3
  categories.yml.name のみ、L1 raw 対象 skill は別規約（input path 限定）で表現」を明示

  consolidated-spec.md (drafts) — 軽微

  - L1502: カテゴリディレクトリ構造（articles / papers / notes / narratives / essays / code-snippets / llm_logs）
  - drafts は SSoT 出典として参照されているが、本 spec を最新の SSoT として位置付け、Adjacent Sync で後続更新可
  - 本セッションでは Spec 1 内で修正、drafts 反映は別セッション

  修正実施計画

  1. Spec 1 requirements.md の 4 箇所を 6 カテゴリに更新
  2. Spec 1 R1 に「除外理由」を新 AC として追加（概念軸統一・L1 同名衝突回避・長期拡張耐性）
  3. Spec 1 brief.md の 2 箇所を 6 カテゴリに更新
  4. brief.md design phase 持ち越しに「Spec 2 ↔ Spec 1 coordination 要求」を追加
  5. brief.md design phase 持ち越しに「consolidated-spec.md drafts への Adjacent Sync」を追加

  順次実施します。
  
⏺ 【本-14】完了。次に【本-17】vocabulary 操作の decision_log 自動記録対象性です。

  【本-17】vocabulary 操作の decision_log 自動記録対象性

  問題の整理

  - R13.1: §2.13 Curation Provenance を本 spec の設計前提として参照
  - Foundation R12.4: decision_log 自動記録対象 = 「境界決定 / 矛盾検出 / 人間 approve・reject・merge・split / Hypothesis verify / Hygiene によるstatus 遷移 / synthesis 操作」
  - 問題: 「人間 approve・reject・merge・split」に vocabulary 操作（tag merge/split） は含まれるか？
    - tag merge/split は本 spec が新設する dangerous op（R8.5）
    - decision_log 自動記録対象として明示されていない（Foundation 側で「page merge/split」を想定？「vocabulary merge/split」は別物？）
  - 本質: vocabulary 操作も curation decision の一種だが、Foundation R12.4 の文言が曖昧

  解決方針 4 案

  案A: Spec 1 で「vocabulary 操作も decision_log 自動記録対象」と明示（Foundation 改版なし）

  - R8.5 または新 AC で「rw tag merge / split / rename / deprecate / register の approve 時、Spec 5 record_decision() API 経由で decision_log.jsonlに自動記録する責務を Spec 5 への coordination 要求として明示」
  - メリット:
    - Spec 1 内で完結、Foundation 改版不要
    - vocabulary 操作の curation provenance が保全される
  - デメリット:
    - Foundation R12.4 の文言が「page merge/split のみ」を想定していた場合、解釈拡張になる
    - Foundation との整合性確認が必要

  案B: Foundation R12.4 を改版し「vocabulary 操作」を自動記録対象として追加

  - Foundation requirements.md R12.4 を「人間 approve・reject・(page) merge・split・(vocabulary) merge・split / ...」と拡張
  - 本 spec R13.1 で「Foundation R12.4 の vocabulary 操作含む」を明示参照
  - メリット:
    - Foundation 規範として明確化、他 spec も参照可能
    - Curation Provenance の網羅性向上
  - デメリット:
    - Foundation 改版必要 → Spec 0 を再 approve（Adjacent Sync で済むか、要評価）
    - 本セッションで完結しない

  案C: 案A + Foundation 改版を別セッションで（Adjacent Sync 想定）

  - 本セッションでは案A の修正を実施
  - brief.md design phase 持ち越しに「Foundation R12.4 への vocabulary 操作追加（Adjacent Sync）」を追記、Spec 0 を別セッションで微修正
  - メリット: 本 spec で実用整合を取りつつ、Foundation 規範整合を後続で確実化
  - デメリット: 二重管理リスク（一時的）

  案D: vocabulary 操作は decision_log 記録対象外と明示（最小変更）

  - R8.5 または新 AC で「vocabulary 操作（tag merge/split 等）は decision_log 自動記録の対象外」と明示
  - 理由: vocabulary 操作は「curation decision」より下位の「ツール運用」として扱う
  - メリット: Foundation 文言を変えず、Spec 1 で明示的に除外
  - デメリット:
    - Curation Provenance の保全が部分的（vocabulary 変動の追跡が git log のみに依存）
    - tag merge による wiki ページの一括変更が「なぜ起きたか」が後追い不可

  推奨

  - 案C（案A + Foundation 改版を Adjacent Sync） が最もバランス良
    - 本セッションで Spec 1 の coordination 要求を明示し、実用整合を取る
    - Foundation 改版は brief.md design phase 持ち越しに記録、別セッションで微修正
    - vocabulary 操作も「人間判断による wiki への波及効果がある操作」として decision_log 対象とする方が、§2.13 Curation Provenance の本質（「what +why」の二層保全）に忠実
  - 案D（記録対象外） は短期的にはシンプルだが、「tag merge で 50 ページの tags が変わった理由」を後追いできなくなる UX 損失大

  A / B / C / D どれを選択しますか？
```

##### ❯ 案C

```
⏺ R8 に新 AC を追加し、brief.md に Foundation 改版の Adjacent Sync を持ち越し記録します。
⏺ 【本-17】完了。最後の重要 7 件【本-20】Entity shortcuts と related: の重複問題です。

  【本-20】Entity shortcuts と related: の重複問題

  問題の整理

  - 例: entity-person ページに authored: [page-A, page-B] が書かれている
  - Spec 5 sync が走ると、authored: が typed edge authored として L2 edges.jsonl に展開される
  - 同時に Spec 5 sync が related: cache（L2 stable/core edge から derived）を更新する → authored edge が stable/core になれば related:にも反映される
  - 問題シナリオ:
    - シナリオA（重複）: Spec 5 sync が authored: edge を related: にも書き込む → 同じ関係が 2 箇所（authored: と related:）に出現、ユーザーがauthored: を編集しても related: は古いまま（次回 sync まで）
    - シナリオB（分離）: Spec 5 sync が authored: edge は related: に書かない → related: には他 typed edge のみ。authored: を見るには別 fieldを読む必要、UX 不一致
  - 本質: Entity-specific shortcuts と generic related: cache の関係性が未規定。Spec 5 sync の挙動依存

  解決方針 4 案

  案A: Entity shortcuts と related: を完全分離（重複防止）

  - 規定: 「Entity-specific shortcuts (authored: 等) で表現される typed edge は、related: cache に 重複展開しない」
  - ユーザーが entity の関係性を見たい時は authored: 等の shortcut field を直接読む、related: には他 typed edge のみ
  - メリット: 重複なし、shortcut field がユーザーの編集対象として意味を持つ
  - デメリット:
    - cache 利用側 (Spec 6) が「全 typed edge を見たい」場合、related: + shortcuts の両方を読む必要 → 実装複雑度
    - related: の意味が「shortcut で表現されない typed edge のみ」と限定的

  案B: Entity shortcuts は related: に重複展開する（重複許容）

  - 規定: 「Entity-specific shortcuts は related: cache にも展開される（重複）」
  - ユーザーは shortcuts でも related: でも同じ関係性を見られる
  - メリット: cache 利用側がシンプル（related: 1 つを読めば全関係取得）
  - デメリット:
    - shortcut field と related: の同期問題（ユーザーが authored: を編集しても related: は次回 sync まで stale）
    - shortcut field の意味が薄れる（書いても related: で表現される）

  案C: Entity shortcuts は「ユーザー編集 input」、related: は「読み取り cache」と役割分離

  - 規定:
    - shortcuts (authored: 等) = ユーザーが書く入力 field（人間判断で edge を宣言）
    - related: = L2 から sync される読み取り cache（shortcut 由来 + 他抽出由来を統合）
    - shortcut field の値変更 → 次回 sync で related: に反映
    - 双方向ルールは Spec 5 sync 機構で吸収
  - メリット:
    - 役割が明確（書く側 vs 読む側）
    - cache 利用側はシンプル（related: 1 つを読めば全関係取得、案B 同等）
    - shortcut field は「入力意図表現」として意味を持つ（読み取り対象としては related: を見る）
  - デメリット:
    - 重複は残る（shortcut field と related: で同じ関係が表現される）
    - ただし役割分離により混乱は少ない

  案D: Spec 5 design phase に完全委譲、本 spec で言及せず

  - requirements.md 変更なし
  - brief.md design phase 持ち越しに「entity shortcuts と related: の重複規約は Spec 5 設計時に確定」
  - メリット: 修正最小
  - デメリット: 暗黙設計依存、Spec 5 起票時に揉める可能性

  推奨

  - 案C（役割分離） が本質的に最も整合
    - shortcuts = 入力（ユーザーの宣言意図）、related: = 出力 cache（機械が管理）の役割分離
    - cache 利用側 (Spec 6) はシンプル（related: のみ読む）
    - shortcut field の存在意義（簡潔な表現）を保持
    - 重複は許容するが「shortcut は入力、related は読み取り cache」と意味が違うため概念混乱なし
  - 案A（完全分離） は重複なしだが UX 一貫性損失大
  - 案B（重複許容） は役割分離が不明示
  - 案D（完全委譲） は本 spec の責務範囲として不十分

  A / B / C / D どれを選択しますか？
```

##### ❯ 案Cで重複は許容するが「shortcut は入力、related は読み取り cache」と意味が違うため概念混乱なしを再検討

```
⏺ 案C の「概念混乱なし」主張を厳密に再検証します。

  案C で実際に発生する混乱・破綻の精査

  混乱1: 同期タイミングのずれが UX に露出

  ユーザーが entity-person ページの authored: を編集したケース:

  # 編集直後（sync 前）
  authored: [page-A, page-B, page-D]  # ← 編集済（D 追加）
  related:
    - target: page-A, relation: authored  # ← まだ古い（D なし）
    - target: page-B, relation: authored

  - ユーザーが直後に同じページを開くと「authored: には D あるのに related: には D ない」と気付く
  - eventual consistency で「次回 sync まで stale」が ユーザーの目に直接見える形で露出
  - 案D-b（前述で却下した frontmatter related_synced_at:）の問題と同じ構造

  混乱2: 編集権限の二重化

  - R10.7: related: は「ユーザー手動編集を禁じない（緊急時 override）」
  - shortcuts: ユーザー入力 field（編集前提）
  - → ユーザーが「authored: か related: か、どちらを編集すべきか？」と迷う場面が常に発生
  - 「shortcut が入力、related は機械管理だから触るな」と教育しても、R10.7 の手動編集許可と矛盾

  混乱3: frontmatter サイズ肥大化

  - 多数 authored: を持つ entity-person（例: 50 papers）の frontmatter が 2 倍
  - shortcut と related: で同じ関係を 2 重表現 → YAML 可読性低下

  混乱4: shortcut の本来の利点（簡潔性）が半減

  - shortcut の存在意義: 「authored: [...] 1 行で typed edge 表現」
  - 案C では related: にも展開されるため、結局両方書かれる → 「簡潔表現」のメリット消失

  概念混乱なし主張の崩壊

  - 「役割分離（書く側 vs 読む側）」は理論的には明確
  - ただし上記 4 つの実用問題が「概念混乱」を生む（同じ関係が 2 箇所に書かれていることを見たユーザーは混乱する）
  - → 案C の「概念混乱なし」は楽観的すぎる

  案A（完全分離）の再評価

  案A のメリット再考

  - 重複ゼロ: frontmatter サイズ最小
  - shortcut の簡潔性メリット最大化: 「authored: [...] 1 行で typed edge 表現」が真に意味を持つ
  - 編集権限の単純化: ユーザーは shortcut のみ編集、related: は LLM extract 由来等の他関係のみ（手動編集の頻度低）
  - 同期タイミング問題の縮小: shortcut は L2 edges.jsonl 経由で typed edge 化される時点で正規化、related:
  には現れないので「同期ずれが目に見える」問題なし

  案A のデメリット再評価

  - 「全 typed edge を見たい」場合の cache 利用側実装複雑度:
    - 再評価: cache 利用側 (Spec 6 perspective 等) は L2 edges.jsonl を直接読むのが本来の姿
    - L2 が正本（Foundation R8.6）であり、related: cache はあくまで補助
    - Spec 6 が L2 を直接読む設計なら、related: cache を統合して読む必要はない
    - → 案A のデメリットは「L2 を読まず frontmatter のみ参照する設計」を前提とした場合のみ発生
    - 本来の正しい設計では案A のデメリットは消える

  案A の正しい位置付け

  - shortcut 由来 typed edge: ユーザー入力 → Spec 5 normalize_frontmatter → L2 edges.jsonl
  - 他由来 typed edge（LLM extract 等）: → L2 edges.jsonl
  - L3 frontmatter related:: L2 stable/core edges のうち shortcut で表現されない typed edge のみを cache
  - 全 typed edge の閲覧: L2 edges.jsonl を直接参照（Spec 5 Query API 経由）

  推奨判定の修正

  - 案C は実用上の混乱を 4 つ抱える、「概念混乱なし」は楽観的
  - 案A（完全分離）が本質的に整合:
    - 重複ゼロ
    - shortcut 本来の意義保持
    - 同期ずれの UX 露出なし
    - cache 利用側は L2 直接アクセスが本来の姿

  ただし案A 採用時の追加規定:
  - 「related: cache の対象は shortcut で表現されない typed edge のみ」
  - 「全 typed edge の閲覧用途は L2 edges.jsonl を直接参照すべき（Spec 5 Query API 経由）」
  - Spec 6 の implementation guideline として「cache を統合せず L2 を直接読む」原則を明示

  結論

  案A を推奨に変更します。案C の「概念混乱なし」主張は実用上 4 つの破綻があり、長期的には案A の概念純度が優位です。

  A / C どれで進めますか？（または案A を別案 E と統合する余地があるかご指示があれば）
```

##### ❯ 案A

```
⏺ 案A の修正を実施します。R5.5 と R10.1 を更新し、Adjacent expectations に Spec 6 への要求を追加します。
⏺ Adjacent expectations に Spec 6 への要求を追加します。
⏺ brief.md design phase 持ち越しに本-20 を追記します。
⏺ 重要 7 件すべての修正完了です。

  重要 7 件 修正サマリ

  - 【本-4】 source: 重複検出 → Adjacent expectations で Spec 4 audit task に再委譲
  - 【本-5】 related: cache stale UX → 案C（schema 拡張なし、Spec 5 / Spec 6 委譲、文書/cache メタデータ分離原則）
  - 【本-6】 rw approve 所管 → R4.9 新規追加で Spec 4 への coordination 要求明示
  - 【本-8】 update_history 生成責務 → R3.6 拡張で生成責務マップ明示（lifecycle = Spec 7 / synthesis = Spec 6 / Spec 4）
  - 【本-14】 L1/L3 llm_logs/ 同名混乱 → 案A（L3 llm_logs/ 削除、6 カテゴリ縮約）+ Spec 1 4 箇所 + brief 2 箇所修正 + Spec 2 / drafts への波及を
  design phase に記録
  - 【本-17】 vocabulary 操作の decision_log 記録 → R8.13 新規追加で Spec 5 record_decision() への coordination 要求 + Foundation 改版を Adjacent
  Sync で持ち越し
  - 【本-20】 Entity shortcuts と related: 重複 → 案A（完全分離）、R5.5 / R10.1 拡張 + Adjacent expectations に Spec 5 フィルタ責務 / Spec 6 L2
  直接参照原則明示

  残対応

  - 中重要度 8 件 + 軽微 2 件: brief.md design phase 持ち越しに追記（まだ未追加分あり）
  - 本セッション全修正の最終整合確認
  - approve 判断

  中重要度 8 件【本-9 〜 11, 13, 15, 16, 18, 21】+ 軽微 2 件【本-12, 22】を brief.md 持ち越しに追記しますか？それとも別観点でレビュー継続しますか？
```

##### ❯ まず、中重要度 8 件【本-9 〜 11, 13, 15, 16, 18, 21】+ 軽微 2 件【本-12, 22】を brief.md 持ち越しに追記。その後、またレビューを行う

```
⏺ 中重要度 8 件 + 軽微 2 件を brief.md に追記します（【本-15】は【本-2】修正で解決済として明示）。
⏺ 中重要度 8 件 + 軽微 2 件すべて brief.md design phase 持ち越しに追記完了です。

  現在の brief.md design phase 持ち越し全構成

  - 第 1 ラウンド指摘 4 件 (R3.6 / R5.6&R9.1 / R4.5 / R7.3)
  - 第 2 ラウンド指摘 8 件 (F / G / L / M / N / O / S → S は本-1 修正で解消済 / T)
  - 第 3 ラウンド指摘 致命的 5 件: 全件 requirements 段階で解消済（持ち越しなし）
  - 第 3 ラウンド指摘 重要 7 件 (本-4 / 本-5 / 本-6 / 本-8 / 本-14 / 本-17 / 本-20)
  - 第 3 ラウンド指摘 中重要度 8 件 (本-9 / 本-10 / 本-11 / 本-13 / 本-15 → 本-2/3 修正で実質解決 / 本-16 / 本-18 / 本-21)
  - 第 3 ラウンド指摘 軽微 2 件 (本-12 / 本-22)

  次のレビュー観点

  次回レビューに進める準備が整いました。観点候補:

  - A: 適用済修正全体の整合確認（requirements.md 全文を読み返し、矛盾・冗長・参照ずれを精査）
  - B: 第 4 ラウンド本質的観点（これまで未検出の角度、例: failure mode / セキュリティ / accessibility / 国際化 / 並行制御 / バックアップ）
  - C: 他 spec への波及影響再精査（Spec 1 修正が Spec 0 / 2 / 3 / 4 / 5 / 6 / 7 に与える影響を改めて全件 grep）
  - D: scenarios.md / consolidated-spec.md との整合再精査（drafts SSoT が Spec 1 修正と矛盾しないか）
  - E: 他観点（指定願います）

  どの観点で進めますか？
```

##### ❯ A,B,C,Dを順に実行

```
⏺ 観点A: 適用済修正全体の整合確認
  requirements.md 全文を再読し、矛盾・冗長・参照ずれを精査します。
⏺ 観点A: 適用済修正全体の整合確認
  requirements.md 全文を再読し、矛盾・冗長・参照ずれを精査します。
⏺ 観点A: 整合性精査結果

  要修正 1 件

  A1: R13.4 と R4 の網羅整合不足（中重要度）

  - R13.4 現状: 「Skill ファイル / Skill candidate / Hypothesis candidate / Perspective 保存版 のみ Foundation 委譲先（Spec 2 / Spec 6）に再委譲」
  - ただし R4 修正で R4.7 (decision-views/ → Spec 1 引受) と R4.8 (audit_candidates/ → Spec 4, relation_candidates/ → Spec 5, Follow-up → Spec 7)
  が新設済
  - R13.4 はこれらの再委譲を反映していない → Foundation R8.4 委譲リストの所管マップが R13.4 と R4.7/R4.8 で食い違う
  - 修正方針: R13.4 を「Spec 2 / Spec 6 / Spec 4 / Spec 5 / Spec 7 への各再委譲（R4.6 / R4.8）」を含めた網羅形に拡張

  修正推奨 4 件（中重要度）

  A2: Adjacent expectations 内の余分な空行（軽微体裁）

  - L62 に空行があり、Spec 4 関連（L61）と Spec 7 関連（L63）の間に体裁不揃い
  - 削除推奨

  A3: Project Description (Input) の項目列挙更新（軽微〜中）

  - L7 の (a) ... (h) 8 項目は当初の作成時点。修正セッションで以下が追加されたが反映なし:
    - entity_type field 新設、L3 llm_logs/ 除外、successor field 追加、enforcement 2 値化、review/decision-views/ 宣言、vocabulary_candidates/
  approve coordination、vocabulary 操作の decision_log 連携、shortcuts と related: 完全分離
  - 推奨: 「Project Description (Input) は当初記述として履歴的に保存」と判断するなら触らず、新規読者向けに最新化するなら更新

  A4: Introduction L19-L25 の成果物 5 種類列挙更新（軽微〜中）

  - 同上、修正で追加された側面が反映されていない
  - 推奨: 同上

  A9: R5.6 と R9.1 の表記重複整理（軽微〜中）

  - R5.6: 「entity_type: 値が登録 entity type のいずれにも属さない」+「entity_type: 未指定でショートカット記述」を 1 つの AC で WARN 化
  - R9.1: 「許可値外の entity_type:（WARN）」「entity_type: 未指定でショートカット記述（WARN）」「entity_type: 値が登録 entity type
  に未該当（WARN）」と 3 項目に分解
  - 「許可値外」と「登録 entity type に未該当」は同義、表記重複
  - 推奨: R9.1 で「entity_type: 値が entity_types.yml.name に未登録」に統合、R5.6 と用語統一

  軽微 5 件（修正不要、design phase 確認可）

  - A5: R8.13 と R4.9 の相互参照（既に明示済、追加修正不要）
  - A6: R10.7 のユーザー手動編集と shortcut 完全分離の関係（次回 sync で除外フィルタが効くと解釈、整合）
  - A7: R1.6 と R7.1 の enforcement 2 値整合（OK 確認）
  - A8: R4.5 vs R4.7 の field 必須/任意区別の表記不統一（design phase 持ち越し済）
  - A10: successor 表記（OK 確認）

  修正方針提案

  - 必須 1 件 (A1): R13.4 を網羅形に拡張
  - 修正推奨 3 件 (A2, A4, A9): 体裁整理 + 表記統一
  - A3 (Project Description 更新): 履歴記述として残すか更新するかの判断要

  A1 / A2 / A4 / A9 を本セッションで修正、A3 は判断を伺いたいですが、進めて良いですか？
```

##### ❯ 推奨案で実施

```
⏺ A3 は Project Description (Input) の性質上 spec-init 時のスナップショット記録として残し、A1 / A2 / A4 / A9 を修正します。

  A1: R13.4 を網羅形に拡張
⏺ A2: Adjacent expectations の余分な空行削除
⏺ A4: Introduction の成果物 5 種類列挙更新
⏺ A9: R5.6 と R9.1 の表記統一
⏺ 観点A 完了。次は観点B（第 4 ラウンド本質的観点）です。

  観点B: 第 4 ラウンド本質的観点

  これまで未検出の角度から精査します。観点候補:

  1. Failure mode / エラー境界: 想定外入力・破損 vocabulary・部分的な vocabulary 不整合の対応
  2. 並行制御 / 競合: 複数 CLI 同時実行、Hygiene batch との競合
  3. セキュリティ: vocabulary YAML の YAML injection、ファイル path traversal
  4. migration / 後方互換: スキーマ拡張時の既存ページ扱い、v2.0 → v2.1
  5. 国際化 / 文字コード: tag canonical の Unicode normalization、大文字小文字
  6. 観測可能性 / Debugging: lint 結果の root cause 追跡、vocabulary 変更履歴の audit trail
  7. 可逆性 / Rollback: tag merge / split 後のロールバック、誤 approve からの復旧
  8. 規模・性能: 大規模 vault（10,000+ pages）での lint / scan 性能
  9. 暗黙の前提崩壊: ユーザーが想定外の使い方をした場合（カテゴリ削除 / 既存タグ大量改名 / 全ページ deprecated 化）
  10. 責務分離の真の境界: Spec 1 と Spec 4 / Spec 5 / Spec 7 の境界が「規定 vs 実装」で本当に切れているか

  これら 10 観点で精査します。
⏺ 観点B 精査結果

  10 の本質的観点から精査し、これまで未検出の問題を 18 件検出しました。

  要修正 3 件（中重要度、本セッションで修正推奨）

  【B-1】vocabulary YAML 破損時の lint 動作未規定

  - R9.4: 「いずれも存在しない」ケースのみ規定（INFO で「未初期化」通知 + 他 lint 継続）
  - 未規定: YAML parse 不可 / 部分破損 / 一部のみ存在の場合の動作
  - 例: tags.yml だけ破損していても categories.yml 検査は走るべきか
  - 修正方針: R9.4 を拡張、または新 AC で「個別 vocabulary ファイルが parse 不可の場合、当該 vocabulary 関連検査のみ ERROR で fail
  させ、他検査は継続」を明示

  【B-2】vocabulary 整合性 ERROR 時の連鎖検査の信頼性

  - R6.2: tags.yml 重複登録 → ERROR
  - 問題: 重複 ERROR がある時、その vocabulary を使う他検査（未登録タグ判定等）が信頼できる結果を出せるか不明
  - 例: canonical 重複 → どちらを正規として「未登録タグ」判定するか曖昧
  - 修正方針: R9 に新 AC で「vocabulary 自体に ERROR がある場合、関連検査は skip して WARN で通知（誤検出を避ける）」を明示

  【B-3 / B-4】vocabulary 編集と .hygiene.lock の関係未明示

  - Foundation R11.5: .rwiki/.hygiene.lock は Hygiene batch と CLI 操作の排他制御（Spec 4 ↔ Spec 5）
  - 問題: 本 spec の rw tag merge/split/rename/deprecate/register が vocabulary を変動させるが、Hygiene batch との競合 / 複数 CLI
  同時実行の排他制御が未明示
  - 例: Hygiene batch 中に rw tag merge 実行 / 2 端末から同時に rw tag rename 実行
  - 修正方針: R8 に新 AC で「vocabulary 変動操作は .hygiene.lock を取得して実行する責務を Spec 4 への coordination 要求として明示」を追加

  Design phase 持ち越し 11 件

  中重要度 7 件

  - B-7: スキーマ拡張時の既存ページ扱い → 本-11 で対応済（重複）
  - B-9: tag canonical の Unicode normalization（NFC vs NFD / 大文字小文字 / 全角半角）
  - B-11: lint 結果の root cause 追跡（distance metric / suggestion 等）
  - B-13: tag merge / rename 後の rollback 手順
  - B-14: 誤 approve からの復旧 + decision_log 補正記録
  - B-15: 大規模 vault（10,000+ pages）での scan 性能 → 本-10 で部分対応
  - B-16: ユーザーがカテゴリディレクトリ削除時の categories.yml 残存 lint 動作

  軽微 4 件

  - B-5: vocabulary YAML の YAML injection リスク
  - B-6: rw tag register 等の引数 path traversal
  - B-10: entity_types.yml.name の日本語命名許容性
  - B-17: entity_types.yml 空時の WARN 大量発生抑制

  確認済（修正不要）

  - B-8: v1 → v2 vocabulary 引き継ぎ → roadmap フルスクラッチ方針で影響なし
  - B-12: 手動編集の audit → git log で追える前提で OK
  - B-18: 規定 vs 実装境界 → R3.4 の修正で妥当な妥協済

  修正方針提案

  - 本セッションで修正: B-1, B-2, B-3/B-4（要修正 3 件、いずれも実装の安全性に関わる中重要度）
  - brief.md design phase 持ち越し追加: 中重要度 6 件 + 軽微 4 件 = 10 件追記

  要修正 3 件の修正と持ち越し 10 件の追加を進めて良いですか？
```

##### ❯ はい

```
⏺ 順次実施します。まず requirements.md に要修正 3 件を追加します。
⏺ 次に brief.md に第 4 ラウンド指摘 10 件を追記します。
⏺ 観点B 完了。次は観点C（他 spec への波及影響再精査）です。
⏺ Spec 4 で rw approve の各 review 層対応の有無を追加確認します。
⏺ 観点C 精査結果

  整合確認 OK（Spec 1 修正と他 spec が一貫）

  - Foundation R8.3: Wiki 固有 field 骨格と R3 修正 → 整合 ✓
  - Foundation R13.2: L3 = update_history: と R3.6 修正 → 整合 ✓
  - Spec 7 R6.7: merge_strategy 5 値と R3.4 → 整合 ✓（Spec 7 拡張可規定）
  - Spec 7 R7-R10: update_history / successor / merged_* 自動追記と R3.6 生成責務マップ → 整合 ✓
  - Spec 7 R10.4: tag-merge-guide.md / tag-split-guide.md で Spec 1 R8.5 参照 → 整合 ✓
  - Spec 3 全般: type: を distill dispatch hint として参照 → R2.2 修正後の content 種別限定と整合 ✓
  - Spec 5 R2.3: 初期 entity type entity-person / entity-tool と R5.3 → 整合 ✓
  - Spec 5 R12 (Entity Normalizer): normalize_frontmatter API → R5.5 修正と整合 ✓
  - Spec 5 R30 (coordination 13): Spec 5 ↔ Spec 1 責務分離明示 → R12 と整合 ✓
  - structure.md L60: .rwiki/vocabulary/ 4 ファイル → 整合 ✓

  要 coordination 注意 3 件（brief.md design phase 持ち越しに追記推奨）

  C-1: Spec 5 / Spec 2 の type 表記が entity type を指している箇所

  - Spec 5 R1.2 (entities.yaml): type (entity type、entity_types.yml の値)
  - Spec 5 R5.5 (relation_extraction skill 出力): type (entity_types.yml の値)
  - Spec 2 R7.2 (entity_extraction skill 出力): type (entity_types.yml の値)
  - 問題: 本 spec 修正で type: (content 種別) と entity_type: (entity 種別) を分離したが、Spec 5 / Spec 2 の出力 schema では entity type を typeと表記している
  - 対応方針: Spec 5 / Spec 2 起票時に schema field 名を entity_type に揃える coordination が必要

  C-3: Spec 4 で rw approve の各 review 層対応 AC が未記述

  - Spec 4 では rw approve がサブコマンドリストに登場するのみ、各 review 層への対応 AC はなし
  - 本 spec R4.9 で「vocabulary_candidates/ の approve 拡張」を Spec 4 への coordination 要求として明示済
  - 対応方針: Spec 4 起票時または Adjacent Sync で rw approve の対応 review 層リスト（synthesis_candidates / vocabulary_candidates / audit_candidates
   / decision-views / 等）を Spec 4 requirements に明示

  C-6: Foundation R8.4 の Spec 1 委譲リストと R4.6 / R4.7 / R4.8 / R4.9 の対応マップ整合

  - Foundation R8.4 は委譲リストとして「Skill ファイル / Skill candidate / Vocabulary candidate / Follow-up / Hypothesis candidate / Perspective
  保存版」を列挙
  - 本 spec 修正で audit_candidates/ / relation_candidates/ / decision-views/ の所管も明示
  - Foundation R8.4 と Spec 1 R4 の対応マップが拡張済（暗黙整合）
  - 対応方針: Foundation R8.4 と Spec 1 R4 の対応関係を Adjacent Sync で確認・必要なら Foundation 微改訂

  Spec 1 内の修正不要、brief.md 追記のみで対応

  C 観点では requirements.md の追加修正は不要、brief.md design phase 持ち越しに上記 3 件を追記すれば十分です。

  追記しますか？
```

##### ❯ 追記

```
⏺ 観点C 完了。最後の観点D（drafts SSoT との整合）です。
⏺ 観点D 精査結果

  drafts (consolidated-spec.md v0.7.12 / scenarios.md) と Spec 1 修正の整合を精査しました。

  整合確認 OK（本 spec 修正と一貫）

  - consolidated-spec L242 / L794 / L1162: review/vocabulary_candidates/ → 整合 ✓
  - consolidated-spec L691 / L1786 / L1789: review/decision-views/ Tier 2 timeline → 整合 ✓
  - consolidated-spec L759 / L828-829: .rwiki/vocabulary/ 4 種 → 整合 ✓
  - consolidated-spec L1087-1089: successor: (wiki page path 配列) → R3.3 と整合 ✓
  - consolidated-spec L1094: merge_strategy: 5 値 → R3.4 と整合 ✓
  - consolidated-spec L1148: applicable_categories: Skill frontmatter → Spec 2 整合 ✓
  - consolidated-spec L1502 以外の categories 関連: 整合 ✓
  - consolidated-spec L1565: categories.yml default skill mapping → R7.2 / R11.2 整合 ✓
  - consolidated-spec L2362-2377: Spec 1 ↔ Spec 3 coordination → R11 整合 ✓
  - scenarios.md 全般: wiki page lifecycle 関連の successor / merge_strategy 表記 → Spec 1 / Spec 7 整合 ✓

  要対応 2 件

  D-1: consolidated-spec.md L1502 の 7 カテゴリ列挙（要 Adjacent Sync）

  - 現状: カテゴリディレクトリ構造（articles / papers / notes / narratives / essays / code-snippets / llm_logs）
  - 本-14 修正で L3 llm_logs/ 除外 → 6 カテゴリ
  - 対応方針: 本-14 持ち越しで「consolidated-spec.md drafts への Adjacent Sync」を別セッション対応として記載済。本セッションで drafts修正するか、別セッションで対応するかの判断

  D-3: tags.yml.successor と wiki frontmatter.successor の同名 field 意味的衝突（新規発見）

  - R6.1 (修正済): tags.yml の successor（後継 canonical タグ名、文字列または文字列配列）
  - R3.3 (既存): wiki page frontmatter の successor:（後継 wiki ページ path の配列）
  - 同名 field が wiki page 文脈と tag 文脈で意味が異なる → 命名衝突
  - 対応方針:
    - 案A: tags.yml field 名を successor_tag 等に rename（命名衝突回避）
    - 案B: 同名 field で文脈依存と明示（schema doc で「tag context = canonical タグ名、page context = wiki path」を明示）
  - design phase 持ち越し推奨

  Spec 2 起票時に対応（持ち越し済）

  - D-2: consolidated-spec.md L2572 applicable_categories: [llm_logs] の llm_log_extract skill → 本-14 持ち越し済

  修正方針提案

  本セッションで対応

  - D-3 (命名衝突): brief.md design phase 持ち越しに追加（軽微〜中、design phase で命名統一判断）

  別セッション対応

  - D-1 (drafts 7→6 カテゴリ): 本-14 持ち越しに既に記載済、別セッションで consolidated-spec.md v0.7.12 → v0.7.13 に微改訂
  - D-2 (drafts L2572 applicable_categories): 本-14 持ち越しに記載済、Spec 2 起票時に対応

  D-3 のみ brief.md に追記しますか？（D-1 / D-2 は既に持ち越し記載済のため新規追記不要）
```

##### ❯ 追記

```
⏺ 観点A〜D 全ラウンド完了です。

  観点A〜D 全 6 ラウンドの精査総括

  Spec 1 requirements.md への修正

  - 致命的 5 件 (本-1, 2, 3, 7, 19): すべて requirements 段階で解消
  - 重要 7 件 (本-4, 5, 6, 8, 14, 17, 20): 5 件 requirements 修正 + 全件 design phase 持ち越し記録
  - 中重要度 8 件 (本-9〜11, 13, 15, 16, 18, 21): brief.md design phase 持ち越し
  - 軽微 2 件 (本-12, 22): brief.md design phase 持ち越し
  - 観点A 整合性 (A1, A2, A4, A9): requirements 修正
  - 観点B failure mode (B-1, B-2, B-3/4): R9.7 / R9.8 / R8.14 として requirements 追加
  - 観点B 持ち越し 10 件: brief.md
  - 観点C 波及影響 (C-1, C-3, C-6): brief.md
  - 観点D drafts (D-3): brief.md

  requirements.md の最終構成

  - Boundary Context: In/Out/Adjacent expectations 拡張
  - Requirement 14 → 14（数変わらず、AC 数増加）
  - AC 数: R4 (6→9), R6 (5→6), R8 (12→14), R9 (6→8) 等で総 92 → 約 110+ AC

  brief.md の design phase 持ち越し構成

  - 第 1 ラウンド: 4 件
  - 第 2 ラウンド: 8 件（うち S は本-1 で解消）
  - 第 3 ラウンド致命的: 0 件（全件解消）
  - 第 3 ラウンド重要: 7 件
  - 第 3 ラウンド中重要度: 8 件
  - 第 3 ラウンド軽微: 2 件
  - 第 4 ラウンド B 観点: 中重要度 6 件 + 軽微 4 件 + 確認済 4 件
  - 第 5 ラウンド C 観点: 3 件
  - 第 6 ラウンド D 観点: 1 件 + 確認済 2 件

  次の選択肢

  1. 本セッション全修正の最終確認: requirements.md / brief.md を読み返して整合確認
  2. 第 5 ラウンド本質的観点: 別の観点で更にレビュー
  3. approve 判断: spec.json 更新の判断
  4. コミット only: approve せずに本セッション修正をコミット

  どれで進めますか？
```

##### ❯ 本セッション全修正の最終確認

```
⏺ requirements.md と brief.md を全文確認しました。整合性は概ね良好、軽微な不整合 1 件のみ検出。

  全修正の最終整合確認結果

  整合確認 OK

  - Requirement 構造: R1〜R14（14 個変更なし）、AC 数 92 → 99（+7）
  - Requirement 間の参照整合性:
    - R5.5 → R10.1 の完全分離方針相互参照 ✓
    - R10.4 → R3.5 の schema 参照 ✓
    - R4.9 → R8.5 の rw approve coordination ✓
    - R13.4 → R4.6/R4.7/R4.8/R4.9 の所管マップ網羅 ✓
  - Boundary Context: In scope / Out of scope / Adjacent expectations が整合
  - Introduction 更新: 成果物 5 → 6 種類列挙更新済
  - brief.md ↔ requirements.md ↔ Foundation の整合: 主要点すべて確認済

  軽微修正 1 件（F5）

  brief.md L78 「軽微指摘 12 件」表記が古い

  - L78: ## Design phase 持ち越し（2026-04-26 requirements approve 時に確認、軽微指摘 12 件）
  - 実態: 第 1 ラウンド 4 + 第 2 ラウンド 7（S 解消） + 第 3 ラウンド重要 7 + 中重要度 8 + 軽微 2 + 第 4 ラウンド B 観点 中重要度 6 + 軽微 4 + 第 5
  ラウンド C 観点 3 + 第 6 ラウンド D 観点 1 = 42 件（うち本-15 は本-2/本-3 で実質解決と注記）
  - 「軽微指摘 12 件」は完全に古い表記

  確認済（不修正で OK）

  - F1〜F4: brief.md の Scope.In / Desired Outcome 等は spec-init 時点のスナップショットとして履歴的価値あり、更新不要
  - F6, F10: requirements.md の長文 AC は内容整合 OK、読みやすさは犠牲だが意味的に問題なし
  - F7: 第 2 ラウンド指摘 S を「解消済」として残す形式 → 履歴的価値で OK
  - F8: D-3 (successor 衝突) は brief.md design phase 持ち越しに記載済
  - F9: AC 数増加 (92→99) と Requirement 数 14 維持、R14.5 表記整合 OK

  修正提案

  F5 のみ修正、その他は現状維持で approve に進める準備が整います。

  F5 修正しますか？
```

##### ❯ 修正後、approve

```
⏺ F5 を修正し、approve します。
⏺ spec.json を approve 状態に更新します。
⏺ Spec 1 (rwiki-v2-classification) の requirements approve 完了です。

  approve 完了サマリ

  - spec.json: approvals.requirements.approved = true、phase = requirements-approved、updated_at = 2026-04-26T15:46:12+09:00
  - 進捗: ✅✅⬜⬜⬜⬜⬜⬜（2/8 完了 — Spec 0 + Spec 1）

  本セッション全変更

  requirements.md

  - Requirement: 14 個（変更なし）
  - AC 数: 92 → 99（+7）
  - 修正サマリ: 致命的 5 件解消 + 重要 5 件 requirements 反映 + B 観点 failure mode 3 件追加 + A 観点整合 4 件 + 第 2 ラウンド指摘 6 件 + W-3/W-6
  反映

  brief.md

  - Coordination 拡張: Downstream に Spec 7 追加 + inline default_skill 確定明示
  - Constraints 修正: コマンド名 rw graph rebuild --sync-related に統一
  - Design phase 持ち越し: 計約 42 件（第 1〜第 6 ラウンドで段階的追加）

  コミット戦略

  修正ありで approve したため spec ごと個別コミット推奨。コミット作成しますか？それとも別タイミングですか？
```



Spec1の修正内容に対して、他のスペックとの整合性をチェック







全スペックのレビュー後、Cross-validate



------



## レビューキーワード

### 共通

- 厳しく精査してください
- 多様な観点から厳しくレビュー
- 本質的な観点からレビュー
- これまでとは異なる視点でレビュー
- 他にレビューの観点を挙げてください
- 関連する文書間をみて、矛盾がないかをチェック

### 仕様

- roadmap.md, brief.mdを照合して、厳しく精査

#### 設計

- 仕様、およびプロンプト、pythonコードと付き合わせてチェック
- 設計案をpythonコードとの関係の視点からレビュー
- roadmap.md, brief.md, requirements.mdと付き合わせて精査

#### タスク

- 仕様、設計と齟齬がないか、入念に確認してください。
- 他タスクとの境界に留意して、精査。

 

 

  