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

```















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

 

 

  