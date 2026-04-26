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







## レビューキーワード

### 仕様

- 厳しく精査してください
- roadmap.md, brief.mdを照合して、厳しく精査
- 多様な観点から厳しくレビュー
- 他にレビューの観点を挙げてください
- これまでとは異なる視点でレビュー
- 本質的な観点からレビュー
- 全体をみて、齟齬がないかをチェック
- 文書内、他の文書間の観点から矛盾をチェック

#### 設計

- 厳しく精査してください
- 仕様、およびプロンプト、pythonコードと付き合わせてチェック
- 設計案をpythonコードとの関係の視点からレビュー
- roadmap.md, brief.md, requirements.mdと付き合わせて精査
- 多様な観点から厳しくレビュー
- 他にレビューの観点を挙げてください
- これまでとは異なる視点でレビュー
- 本質的な観点からレビュー
- 全体をみて、齟齬がないかをチェック
- 文書内、他の文書間の観点から矛盾をチェック

#### タスク

- 多様な観点から厳しくレビュー
- 仕様、設計と齟齬がないか、入念に確認してください。
- 他タスクとの境界に留意して、精査。
- 他にレビューの観点を挙げてください
- これまでとは異なる視点でレビュー
- 本質的な観点からレビュー
- 全体をみて、齟齬がないかをチェック
- 文書内、他の文書間の観点から矛盾をチェック

 

 

  