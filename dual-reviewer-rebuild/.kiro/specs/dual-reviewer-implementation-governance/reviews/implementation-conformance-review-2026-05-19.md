# implementation conformance review

_実施日: 2026-05-19_
_レビュー種別: implementation conformance review（独立適合レビュー。実装者とは別プロセス・別視点）_
_対象 feature: dual-reviewer-implementation-governance（統治中核 Requirement 1 ほか中核 ＋ 強制関数 Requirement 9）_
_reviewed commit: `81dfee1cb170611410afc26503514f62e52c60d2`_
_review focus: 統治の現実装／現プロセス成果物が現行承認仕様（requirements 1〜11／design 466 行／tasks 1〜18）へ適合し、かつ再実装済み他 5 機能（foundation/runtime/evaluation/self-improvement/paper-interface）の新契約と整合するか、強制関数（実行台帳・独立再導出・enforcement point・独立印・fail-closed）が design どおり機能するか、自己ブートストラップ証跡（workflow-gate-status §3.4）と整合するかを独立確認する_
_正本: docs/coordination/implementation-conformance-review.md_

本証跡は生証跡として不変扱いとする。本レビューにおいてコード・spec・design・requirements・tasks・基盤資産・fixture を一切変更していない（点検と所見記録のみ）。Requirement 9 のテストは tmpdir で完結し、`experiments/`・`learning/`・`docs/coordination/ledgers/`（README.md のみ・台帳インスタンス未生成）への一時生成物は一切作られていない（`git status --short` でサブツリー内に差分なしを確認。サブツリー外の既存差分は本レビュー対象外）。paper-interface の同名証跡（`dual-reviewer-paper-interface/reviews/implementation-conformance-review-2026-05-19.md`）の構成・節立て・finding 4 要素・metric snapshot・disposition・末尾判定に厳密に倣ったが、所見は独立判断した。

## 1. review scope

- review type: `implementation conformance review`
- reviewed branch: `claude/v2-acquisition-code-mod`
- reviewed commit: `81dfee1cb170611410afc26503514f62e52c60d2`
- reviewed feature: `dual-reviewer-implementation-governance`
  - 中核（Requirement 1〜8）＝ procedure / metric register / template / validator / gate status / alignment memo の文書・プロセス成果物
  - 強制関数（Requirement 9）＝ `scripts/governance/` 5 ファイル ＋ `scripts/validate_implementation_governance_artifacts.rb` 拡張 ＋ `docs/coordination/`（authority-map・台帳テンプレ・ledgers skeleton）
- review focus:
  - requirements 1〜11 受入・design 全構成要素・tasks 1〜18 完了条件を現実装／現プロセス成果物が満たすか
  - 統治が前提する他 5 機能の成果物・契約が再実装済み新実体と整合するか（旧 v1 契約・旧命名・撤廃資産への依存残存の有無）
  - 強制関数（台帳の正本からの生成／独立再導出と突合／enforcement point／独立印／fail-closed／全 process 適用）が design どおり機能するか
  - 権威マップ（process→権威文書一意指定）と各正本の整合
  - 自己ブートストラップ運用証跡（workflow-gate-status §3.4）と実装の整合
  - 静的・決定的テスト・無回帰
- 点検対象とした実装の所在:
  - `scripts/governance/{enforcement_point,independence_marker,independent_rederivation,ledger_generator,migration_policy}.rb`（5 ファイル・いずれも 2026-05-18 付）
  - `tests/governance/{test_enforcement_point,test_independence_marker,test_independent_rederivation,test_ledger_generator,test_migration_policy,test_req9_suite}.rb`（6 ファイル）
  - `scripts/validate_implementation_governance_artifacts.rb`（Requirement 5 entrypoint ＋ `--rederive` 拡張モード、2026-05-18 付）
  - プロセス成果物: `docs/coordination/{workflow-process-authority-map,workflow-execution-ledger-template,workflow-gate-status,implementation-conformance-review,implementation-conformance-metric-register,phase-review-metric-register,workflow-repair-procedure}.md`、`docs/coordination/ledgers/README.md`、`docs/alignment/cross-spec-implementation-governance-alignment.md`、`docs/reviews/templates/{intent-review-template,implementation-conformance-review-template}.md`、`docs/reviews/2026-05-09-{intent-baseline-review,prototype-shelf-review}.md`

## 2. validation rerun

- rerun commands:
  - `ruby -c` 構文検査：`scripts/governance/` 全 5 ＋ `scripts/validate_implementation_governance_artifacts.rb` ＋ `tests/governance/` 全 6
  - `tests/governance/test_*.rb` 全 6 を実行（決定的テスト）
  - `ruby scripts/validate_implementation_governance_artifacts.rb`（既定モード＝Requirement 5 entrypoint）を **既定ロケール（`LANG` 未設定）** および `RUBYOPT=-EUTF-8` の両方で実行
  - `ruby scripts/validate_implementation_governance_artifacts.rb --rederive <process_id>`（`reopen-procedure`／`design-review-wave`）
  - 実 authority-map × 実 `workflow-repair-procedure.md` に対する独立再導出を `Governance::IndependentRederivation` で直接実行（台帳生成器と非共有経路）
  - 無回帰：`tests/foundation/test_foundation_contracts.rb`、`tests/runtime/test_*.rb`（15）、`tests/evaluation/test_*.rb`（10）、`tests/self_improvement/test_*.rb`（10）、`tests/paper_interface/test_*.rb`（8）
  - 統治 scripts の旧 v1 契約／旧命名／撤廃資産依存を grep（`treatment_comparison`／`phase_comparison`／`caveat_register`／`adoption_register`／`evidence_class`／`review_mode`／`exclusion_report`／`v1`／`legacy`）
- result summary:
  - `ruby -c`：統治 scripts 5 ＋ validator 1 ＋ tests 6、全件 `Syntax OK`（FAIL ゼロ）
  - `tests/governance/`：6 ファイル全 clean（`test_req9_suite` 6/10/0、`test_enforcement_point` 7/26/0、`test_independence_marker` 6/14/0、`test_independent_rederivation` 6/16/0、`test_ledger_generator` 7/23/0、`test_migration_policy` 8/15/0。合計 40 runs / 104 assertions / 0 failures）
  - validator 既定モード（`LANG` 未設定）：**起動後に `Encoding::CompatibilityError`（US-ASCII vs UTF-8）で例外停止**。`RUBYOPT=-EUTF-8` 強制時のみ `implementation governance artifact validation passed`（Finding 3 参照）
  - `--rederive reopen-procedure`（authority-map が「確定書式適合」と宣言する唯一の process）：**`result=fail reason=authoritative_section を一意特定できない（曖昧＝fail-closed）`**（Finding 1 参照）
  - `--rederive design-review-wave`：`result=fail reason=確定書式でない下位見出し（曖昧＝fail-closed）: ラウンド構成`（authority-map §6 が「未適合＝fail-closed」と宣言するとおりで設計どおり）
  - 実 authority-map × 実 `workflow-repair-procedure.md` 直接再導出：`reopen-procedure` で `FailClosed`（同 Finding 1）
  - 無回帰：foundation 8 runs/107 assertions/0、runtime 15 ファイル全 clean、evaluation 10 ファイル全 clean、self_improvement 10 ファイル全 clean、paper_interface 8 ファイル全 clean（統治点検が他 5 機能を壊していない傍証）
  - grep：統治 scripts に旧 v1 契約／旧命名／撤廃資産への参照ゼロ（統治は workflow-control owner であり feature business data を consume しない設計＝想定どおり。新契約との不整合は構造的に発生しない）

## 3. findings

### Finding 1 `P1`

- title: authority-map の `reopen-procedure` 権威節引用が実文書見出しと不一致で、実 artifact に対し常時 fail-closed（強制関数が実 process で一度も pass し得ない）
- 所在: `docs/coordination/workflow-process-authority-map.md:32`（`reopen-procedure` 行の `authoritative_section` セル＝`## 2. 手続き一覧（Step 1〜10）`）／`docs/coordination/workflow-repair-procedure.md:18`（実見出し＝`## 2. 手続き一覧`、括弧なし）／`scripts/governance/ledger_generator.rb:103-104`（`lines[i].rstrip == target` の完全一致判定）／`scripts/governance/independent_rederivation.rb:66-67`（同 `lines[i].rstrip == section`）
- 現状: authority-map §6 は process を 3 区分し、`reopen-procedure` のみを「確定書式適合（番号付き段見出しの単一リスト）」と宣言する（他はすべて「確定書式未適合＝fail-closed」または「権威ソース未確立＝fail-closed」）。すなわち `reopen-procedure` が実 artifact 上で実際に台帳生成・独立再導出・enforcement pass まで到達できる唯一の process である。しかし authority-map の `authoritative_section` セル文字列は `## 2. 手続き一覧（Step 1〜10）`（括弧付き補足語あり）で、`workflow-repair-procedure.md` の実見出しは `## 2. 手続き一覧`（括弧なし）。`ledger_generator#section_body`／`independent_rederivation#slice_section` はともに `行 == セル文字列` の完全一致で節を特定するため一致せず、`authoritative_section を一意特定できない（曖昧＝fail-closed）` を送出する。実測でも `--rederive reopen-procedure` および直接再導出が `FailClosed`。結果、authority-map が機械強制の対象に挙げる全 process のうち、未確立／未適合で意図的 fail-closed のもの以外は `reopen-procedure` だけだが、それも引用ずれで fail-closed となり、**実 artifact に対して強制関数が pass を返し得る process が 1 つも存在しない**。
- 問題: Requirement 9 受入 1（権威文書から段集合導出）・受入 5（独立再導出と台帳突合）・受入 10（process ごと単一権威の一意読取）・受入 11（曖昧時 fail-closed の正しさ）に関し、fail-closed 自体は安全側に倒れているが、authority-map（プロセス成果物）と権威文書（正本）の整合（review focus「権威マップと各正本の整合」）が破れており、強制関数が「導入完了後の新規 process から機械強制へ移行する」（design 小節 10）という移行目標を実 artifact 上で達成不能。fail-closed が「設計どおりの安全」ではなく「成果物間の引用不整合に起因する全面遮断」である点が中核の不適合。
- 推奨対応: authority-map の `reopen-procedure` セルを実見出しと完全一致させる（`## 2. 手続き一覧`）、または slicer を見出し前方一致＋補足語許容に正規化する（どちらを正本とするかは design 小節 1.2/1.3 の `authoritative_section` 解釈に従う）。あわせて Finding 5（`### 2.1` 段混入）も同時解消する。
- handback class: A（task-local。authority-map の引用文字列の実装側ずれ。design 小節 1.2/1.3 の権威指定方式・要件は不変。プロセス成果物と正本の整合修正で吸収）
- impact severity: P1（trust boundary に相当する強制関数が実 artifact で一度も機能しない＝実効的に未稼働。enforcement の存在意義を毀損）
- status: open / disposition=`fix-before-next-feature`

### Finding 2 `P1`

- title: Requirement 9 の全テストが tmpdir に手製の authority-map・権威文書を仮装し、実 artifact を一度も検証しない（Finding 1/5 を隠蔽。過去レビュー中心指摘の再発）
- 所在: `tests/governance/test_req9_suite.rb:21-30,111-120`（`setup` で `write_doc`／`write_map` が tmpdir に合成文書を生成。`write_map("reopen-procedure" => { s: "## 2. 手続き一覧" })`＝括弧なしの仮装題、`write_doc` は `### Step 1..n` のみで `### 2.1` 相当を含まない合成文書）／`test_req9_suite.rb:8-9`（`Encoding.default_external = Encoding::UTF_8` をテスト先頭で固定＝Finding 3 の実環境エンコーディング欠陥を隠蔽）／`tests/governance/test_ledger_generator.rb`・`test_independent_rederivation.rb`・`test_enforcement_point.rb` も同様に tmpdir 合成 fixture のみ（実 `docs/coordination/workflow-process-authority-map.md`／実 `workflow-repair-procedure.md` を入力にしたケースが皆無）
- 現状: Req9 のテスト 6 ファイル・40 runs は全緑だが、入力はすべて各テストが tmpdir に手で書き起こした authority-map・権威文書・台帳である。合成 authority-map のセルは `## 2. 手続き一覧`（括弧なし）で実 authority-map の `## 2. 手続き一覧（Step 1〜10）`（括弧付き）と異なり、合成権威文書は `### Step 1..n` の連番見出しのみで実 `workflow-repair-procedure.md` の `### 2.1 reopen 手続きへの Workflow Execution Ledger 内包`（`## 2` 配下の番号付き非 stage 小節）を含まない。さらにテスト先頭で外部エンコーディングを UTF-8 に固定し、validator が既定ロケールで起こす `Encoding::CompatibilityError`（Finding 3）も再現しない。結果、テストは「実 artifact が強制関数を pass する世界」ではなく「実 artifact の不適合点を取り除いた仮装世界」を検証している。
- 問題: design 小節 9 テスト戦略は単体／統合／異常系 fixture を要求するが、利用者方針「fixture は実出力形を手製で仮装しない（過去レビューの中心指摘）」に正面から反する。Req9 の検証境界が実 authority-map・実権威文書・実 validator 環境を一切通らないため、Finding 1（reopen-procedure 引用ずれ）・Finding 3（既定ロケール例外）・Finding 5（`### 2.1` 段混入）という実 artifact 上の致命/重要不適合が緑のテストの裏で全て見逃された。tasks Task 18 完了条件「design 小節 9 のテスト境界が検証可能」が、実体準拠でないため実質未達。
- 推奨対応: Req9 テストに、実 `docs/coordination/workflow-process-authority-map.md` と実権威文書を入力とする end-to-end ケース（少なくとも `reopen-procedure` の実 artifact に対する独立再導出・台帳生成・enforcement の期待結果）を追加し、合成 fixture は実体スキーマに一致させる。validator は既定ロケールでの起動も検証対象に含める。
- handback class: A（task-local。テストの実体準拠化・追加で吸収。design 小節 9 の検証境界自体・要件は不変）
- impact severity: P1（強制関数の正しさを担保すべきテストが仮装世界のみを検証し、実 artifact 上の P1 級不適合 3 件を検出できなかった根因。証跡性 §5.3 の構造的弱体化）
- status: open / disposition=`fix-before-next-feature`

### Finding 3 `P2`

- title: Requirement 5 validation entrypoint が既定ロケール（US-ASCII）下で `Encoding::CompatibilityError` 例外停止し pass しない（Req5 受入 4 が環境依存で破綻）
- 所在: `scripts/validate_implementation_governance_artifacts.rb:55,78,97,101,105,108,111,120,129`（`.read`／`.join(...).read` がエンコーディング指定なし。既定外部エンコーディングが US-ASCII の場合 US-ASCII 文字列を返す）／同 `:136`（`required_alignment_sections.reject { |section| alignment_memo.include?(section) }`＝UTF-8 リテラルとの `include?` で `Encoding::CompatibilityError`）／対照：`scripts/governance/ledger_generator.rb:24`・`independent_rederivation.rb:32` 等は明示的に `read(encoding: "UTF-8")` を使用
- 現状: 当環境は Ruby 2.6.10、`LANG`／`LC_ALL` 未設定で既定外部エンコーディングが US-ASCII。validator は `repo_root.join(...).read` をエンコーディング無指定で呼ぶため US-ASCII 文字列を読み、日本語節名（UTF-8 リテラル）との `include?` 比較で例外停止する。`RUBYOPT=-EUTF-8` を与えた場合のみ `implementation governance artifact validation passed`。統治の `scripts/governance/` 配下は一貫して `read(encoding: "UTF-8")` を使うのに対し、Requirement 5 の entrypoint だけがこの規律を欠く。
- 問題: Requirement 5 受入 1〜4（repo-contained validation entrypoint が存在・必須文書／セクション／metric キーを検査し、pass する concrete artifact が最低 1 つ）が「環境が UTF-8 のとき」しか成立せず、既定ロケールの実行者の手元では entrypoint 自体が機能しない。AC5 で Req9 拡張がこの entrypoint の上位集合とされるため、基盤側の堅牢性欠如が強制関数全体の起動信頼性を弱める。境界条件 §5.2（環境依存で隠れる脆さ）。
- 推奨対応: validator の全 `.read` を `read(encoding: "UTF-8")` に統一する（`scripts/governance/` と同規律）。あわせてテストで既定ロケール起動を検証する（Finding 2 と一体）。
- handback class: A（task-local。エンコーディング指定の実装規律漏れ。要件・design は不変）
- impact severity: P2（現 fixture/環境が UTF-8 なら通るが、既定ロケールでは entrypoint が破綻＝Req5 受入 4 が条件付きでしか満たされない）
- status: open / disposition=`fix-before-next-feature`

### Finding 4 `P2`

- title: authority-map の行スキーマが design 小節 1.2／tasks Task 11 の必須 4 欄から `stage_extraction_rule` を脱落（3 欄表）。パーサも 3 セル固定で設計記述と乖離
- 所在: `docs/coordination/workflow-process-authority-map.md:30-33,39-65`（全 process 表が `| process_id | authority_document_path | authoritative_section |` の 3 列。`stage_extraction_rule` 列なし。§3 で「全 process 共通の散文定数」として記載）／`scripts/governance/ledger_generator.rb:73`（`next unless cells && cells.length == 3`）／`scripts/governance/independent_rederivation.rb:44`（`next unless cols.length == 3`）／design.md「小節 1.2」（行スキーマ 4 欄を明示列挙：`process_id`／`authority_document_path`／`authoritative_section`／`stage_extraction_rule`）／tasks.md Task 11（「行スキーマ＝`process_id`／`authority_document_path`／`authoritative_section`／`stage_extraction_rule`」）
- 現状: design 小節 1.2 と tasks Task 11 は authority-map の **各行スキーマ**として 4 欄（`stage_extraction_rule` を含む）を明示列挙する。実装の authority-map は 3 列表で、`stage_extraction_rule` を行欄ではなく §3 の散文「全 process 共通で『番号付き stage 見出しの単一リストとして機械抽出』」へ移している。両パーサは `cells.length == 3` を厳格条件にしており、仮に設計どおり 4 列化すると現パーサは全行を読み飛ばす（将来の設計準拠化と現実装が非互換）。
- 問題: review focus「統治 design 全構成要素を現実装が満たすか」に対し、design 小節 1.2 が行レベル必須欄として挙げた `stage_extraction_rule` が行スキーマから欠落。全 process 共通定数化は実害が小さい合理的選択ではあるが、design が「行スキーマ」と明記した構成要素を散文へ移す改変であり、要件レベル不変条件（受入 10 の単一権威）には反しないものの design 記述との整合が破れている。保守判定として上流（B：design 差し戻しで「共通定数化を design に反映」か、A：authority-map を 4 列化し設計に追従）かの判断は利用者に委ねるべき型（過剰修正偏り回避のため B 候補として明示）。
- 推奨対応: design 小節 1.2 を「`stage_extraction_rule` は全 process 共通定数として §3 に単一記載」と改めて authority-map を正とする（B＝design 差し戻し）か、authority-map を 4 列化しパーサを追従させる（A）。いずれを正本とするかは利用者判断（dominated でない 2 案が残るため自動採択しない）。
- handback class: B 候補（design 構成要素「行スキーマ」と実装の乖離。判定に迷うため WORKFLOW_OVERVIEW §4 の保守規律に従い上流寄せで提示。A での吸収も可能だが design 記述との整合を要するため利用者判断事項）
- impact severity: P2（即破綻せず現テストも緑だが、design 構成要素と実装の構造的乖離。将来の設計準拠化と現パーサが非互換でトレーサビリティを弱める）
- status: open / disposition=`reopen-design`（候補。利用者判断で A 吸収なら `fix-in-current-branch`）

### Finding 5 `P3`

- title: 段集合抽出が `## 2` 配下の文書小節 `### 2.1`（非 stage の Req9 内包注記）を 1 つの「段」として混入させる（権威ソース構造と段集合の混同）
- 所在: `scripts/governance/ledger_generator.rb:116-134`（`derive_stage_set`：`authoritative_section` 配下の全見出しから番号付き token を抽出。`### 2.1 ...` も `2.1` token として stage 化）／`scripts/governance/independent_rederivation.rb:82-96`（`extract_stages` も同様）／`docs/coordination/workflow-repair-procedure.md:122`（`### 2.1 reopen 手続きへの Workflow Execution Ledger 内包（dual-reviewer-implementation-governance Requirement 9）`＝`## 2. 手続き一覧` 配下だが Step ではない注記小節）
- 現状: 仮に Finding 1 の引用ずれを解消し `## 2. 手続き一覧` が一意特定できた場合、その配下の番号付き見出しは `Step 1`〜`Step 10` に加え `### 2.1 ...` を含む。`derive_stage_set`／`extract_stages` は「番号付き見出しはすべて段」とみなすため、`reopen-procedure` の段集合が `[Step 1..Step 10, 2.1]` の 11 段となり、`2.1`（手続きの段ではなく Req9 内包を説明する文書小節）が prescribed stage として台帳・突合に載る。authority-map §6 は「Step 1〜10 の番号付き段見出し単一リストとして維持」と宣言するが、`### 2.1` の存在でその不変条件は実文書上すでに崩れている（Finding 1 で fail-closed のため顕在化していないだけ）。
- 問題: Requirement 9 受入 1〜2（段集合の正確な導出）・design 小節 4「確定書式（番号付き stage 見出しの単一リスト）」に対し、文書構造上の補足小節と prescribed stage の区別がない。`2.1` を段として扱うと completion predicate・独立印・enforcement が架空段を要求し、Finding 1 解消後に新たな不整合源となる。即破綻ではない（現状 Finding 1 が先に fail-closed）が、段集合の意味的正確性とトレーサビリティを弱める。
- 推奨対応: 段抽出を `Step N`（または authority-map で process ごとに宣言する stage prefix）に限定するか、`workflow-repair-procedure.md §2` の `### 2.1` を `## 2` 配下から外す／別節へ移す上位文書同期（design 小節 6 C-3 の確定書式付与と一体）。
- handback class: A（task-local。抽出規則の厳密化、または C-3 上位文書同期で吸収。要件・design の段集合定義自体は不変）
- impact severity: P3（Finding 1 解消後に顕在化する潜在不整合。現時点は先行 fail-closed で未発露。即破綻せずトレーサビリティを弱める）
- status: open / disposition=`fix-in-current-branch`

### Finding 6 `P3`

- title: design「Owned Artifacts」が要求する Requirement 8 系 methodology artifact 群（bootstrap guide／protocol／snapshot template）が repo に不在
- 所在: `.kiro/methodology/dual-reviewer-spec-driven-paper/`（**ディレクトリごと不在**。`reference-free-case-bootstrap-guide.md`／`implementation-phase-protocol-template.md`／`implementation-phase-snapshot-template.md` のいずれも存在せず）／design.md「Owned Artifacts」（同 3 ファイルを governance 所有 artifact として列挙）／tasks.md Task 1 完了条件（同 3 ファイルを `.kiro/methodology/dual-reviewer-spec-driven-paper/` に配置）／requirements Requirement 8 受入 5
- 現状: design「Owned Artifacts」と Task 1 は `.kiro/methodology/dual-reviewer-spec-driven-paper/{reference-free-case-bootstrap-guide.md,implementation-phase-protocol-template.md,implementation-phase-snapshot-template.md}` を governance 所有 artifact として固定する。`scripts/bootstrap_reference_free_case.rb` は存在するが、当該 methodology ディレクトリは repo に存在しない。Requirement 8 受入 6 により governance validator はこれら（および heuristic template）を必須検査しないため validator は通る（UTF-8 環境下）が、design Owned Artifacts と repo 実態が乖離している。
- 問題: review focus「design 全構成要素を現実装／現プロセス成果物が満たすか」に対し、Requirement 8（reference-free bootstrap）系の所有 artifact が物理的に欠落。Requirement 9 中核の健全性には直接影響しないが、統治 design の Owned Artifacts 宣言と repo 実態の乖離（証跡性 §5.3／Task 1 完了条件「governance 所有 artifact が repo 内に配置」未達）。
- 推奨対応: design Owned Artifacts どおり 3 ファイルを `.kiro/methodology/dual-reviewer-spec-driven-paper/` に配置するか、Requirement 8 受入 5/6 の所有・配置を v2-acquisition spec 側へ寄せる旨を design に明記して整合させる。
- handback class: A（task-local。artifact 配置の欠落。Requirement 8 受入 6 で validator 必須化外のため強制関数中核には非影響。配置追加で吸収）
- impact severity: P3（Req9 中核に非影響。design Owned Artifacts と repo 実態の乖離でトレーサビリティ／可説明性を弱める）
- status: open / disposition=`record-and-watch`

## 4. metric snapshot

- `conformance_findings_count`: 6（P1=2 / P2=2 / P3=2）
- `severity_weighted_finding_score`: 12（重み P1=3・P2=2・P3=1：P1 2×3 + P2 2×2 + P3 2×1 = 6+4+2 = 12）
- `post_smoke_nonconformance_count`: 6（テスト 40 件は全緑だがすべて tmpdir 仮装 fixture 上であり、実 artifact に対する適合を一切保証していない＝Finding 2。全 finding は緑テストの裏で実 artifact 検証により独立検出）
- `fixture_bound_resolution_count`: 6（Req9 テスト 6 ファイル全てが手製 tmpdir 合成 authority-map／権威文書／台帳に依存。実 `docs/coordination/` artifact を入力にした決定的ケースが皆無＝Finding 2 が全 finding 隠蔽の根因）
- `heuristic_linkage_count`: 1（Finding 1：authority-map セルと実見出しの完全一致前提が、補足語付き引用で破綻＝文字列完全一致の脆い linkage）
- `placeholder_or_deferred_count`: 1（Finding 6：design Owned Artifacts の methodology 3 ファイルが未配置の欠落 placeholder）
- `review_artifact_presence_rate`: 1.0（本証跡ファイルを新規作成）
- `finding_to_signal_link_rate`: 0.0（本レビュー時点で signal register への起票は未実施。disposition で追跡）

## 5. disposition summary

- immediate disposition:
  - `fix-before-next-feature`: Finding 1（reopen-procedure 引用ずれで実 artifact 常時 fail-closed）・Finding 2（Req9 テスト全件が仮装 fixture・実 artifact 未検証）・Finding 3（validator 既定ロケール例外で Req5 受入 4 環境依存破綻）
  - `reopen-design`（候補）: Finding 4（authority-map 行スキーマと design 小節 1.2 の乖離。利用者判断で A 吸収なら `fix-in-current-branch`）
  - `fix-in-current-branch`: Finding 5（`### 2.1` 段混入の潜在不整合）
  - `record-and-watch`: Finding 6（Req8 methodology artifact 未配置）
- evidence linkage: 本証跡＝`.kiro/specs/dual-reviewer-implementation-governance/reviews/implementation-conformance-review-2026-05-19.md`。finding 6 件のうち handback A=5（実装／プロセス成果物／テストの追随・実装漏れ＝要件・design の権威指定方式は不変）、B 候補=1（Finding 4＝design 構成要素「行スキーマ」と実装の乖離。保守判定で上流寄せ提示。利用者判断で A 吸収可）。C/D=0。
- next action:
  - 結論: 統治の Requirement 1〜8 中核プロセス成果物（procedure／metric register／template／gate status／alignment memo／自己ブートストラップ証跡 workflow-gate-status §3.4）は現行承認仕様に概ね適合し、自己ブートストラップ運用（導入期＝手作業台帳）も §3.4 の証跡と整合する。しかし **Requirement 9 強制関数は実 artifact 上で実効的に未稼働**：authority-map が機械強制対象に挙げる全 process のうち pass 到達可能な唯一の `reopen-procedure` が引用ずれで常時 fail-closed（Finding 1）、それを担保すべきテストが全件 tmpdir 仮装 fixture で実 artifact を一度も通らず P1 級不適合 3 件を見逃し（Finding 2）、Req5 entrypoint は既定ロケールで例外停止（Finding 3）。fail-closed の方向自体は安全側で、要件・design の権威指定方式・段集合定義・enforcement モデルは健全（B/C/D の要件・上位 intent 欠陥は Finding 4 の design 行スキーマ整合を除き検出されず）。
  - 手戻り種別の総括: A=5件（実装／プロセス成果物／テストの実体準拠化・追随漏れ。要件・design の権威指定方式は不変）／ B=1件（Finding 4＝design 小節 1.2 行スキーマと authority-map 実装の乖離、利用者判断で A 吸収可）／ C=0 / D=0。
  - 推奨: **要手戻り（GO 不可）**。**設計差し戻しは Finding 4 の 1 点に限り要検討（B 候補。利用者判断で design 小節 1.2 を authority-map 実装に追従させる軽微改訂か、authority-map 4 列化の A 吸収か）。それ以外は設計差し戻し不要**（要件・design の強制関数モデル＝台帳生成・独立再導出・enforcement・fail-closed・移行戦略は明文化済みで健全。Finding 1/2/3/5/6 はすべて実装・プロセス成果物・テストの実体準拠化で吸収可能）。**スクラッチ全面再実装は不要、部分修正で足りる**：`scripts/governance/` 5 モジュールのモデル構造（FailClosed 一元化、独立再導出の非共有、通過マーカー、独立印の証跡リンク化）は design 小節 1〜10 に忠実で、旧 v1 契約・撤廃資産への依存もゼロ（統治は workflow-control owner で他機能 business data を consume しない）。要修正は限定的：(a) authority-map の `reopen-procedure` 引用を実見出しと一致（Finding 1）、(b) Req9 テストを実 `docs/coordination/` artifact 入力の end-to-end ＋既定ロケール検証へ実体準拠化（Finding 2/3）、(c) validator 全 `.read` を `encoding: "UTF-8"` 統一（Finding 3）、(d) 段抽出を stage prefix 限定か `### 2.1` を §2 外へ（Finding 5）、(e) Finding 4 の design/実装どちらを正本にするか利用者判断、(f) methodology 3 ファイル配置または design 明記（Finding 6）。これらは task-local 修正の範囲で、基盤・実行系・評価・自己改善・論文のような全面スクラッチ再実装は不要。
  - 他機能新契約との整合: 統治は feature logic graph に data producer を追加しない設計（design Architecture／Boundary）どおり、`scripts/governance/` は runtime/evaluation/self-improvement/paper-interface の business schema を一切 consume しない。grep で旧 v1 契約・旧命名・撤廃資産への参照ゼロを確認。**統治と再実装済み他 5 機能の新契約の間に不整合は検出されず**（構造的に発生し得ない＝想定どおり）。authority-map の権威ソースは workflow 正本文書（`workflow-repair-procedure.md`／`REVIEW_PROTOCOL.md`／`HUMAN_WORKFLOW.md`）であり他機能 spec 成果物に依存しない。
  - Req9 強制関数の実装健全性と自己ブートストラップ証跡: モデル実装（台帳生成器の冪等／陳腐化／改竄 3 条件 AND・supersedes 保全、独立再導出の非共有一次解釈、enforcement の不可逆操作最小集合・通過マーカー・遮断記録、独立印の証跡 artifact リンク化、migration の grandfathering／bootstrap／format 移行）は design 小節 1〜10 に忠実で構文・単体・統合・異常系テストは全緑。ただし全テストが仮装 fixture で実 artifact 上は Finding 1 により未稼働（実効性ギャップ）。自己ブートストラップ証跡（workflow-gate-status §3.4）は導入期＝手作業台帳・強制関数未稼働を明記しており、現状（実 artifact で機械強制が pass し得ない＝手作業台帳継続）と矛盾しない。ただし §3.4 は強制関数を「実装完了・テスト 40 件全緑」と記すのみで、実 artifact 上で一度も pass し得ない事実（Finding 1）は証跡に反映されておらず、移行完了判定の前提として Finding 1/2 解消が必要。
  - 無回帰: foundation 8 runs/107 assertions/0 failures、runtime 15 ファイル全 clean、evaluation 10 ファイル全 clean、self_improvement 10 ファイル全 clean、paper_interface 8 ファイル全 clean、governance 6 ファイル 40 runs/104 assertions/0 failures。統治点検が他 5 機能を壊していないことの傍証。

## 6. 検証コマンド結果（要点）

- `ruby -c`：`scripts/governance/` 5 ＋ validator 1 ＋ `tests/governance/` 6、全件 `Syntax OK`（FAIL ゼロ）
- `tests/governance/test_*.rb`：6 ファイル全 clean（合計 40 runs / 104 assertions / 0 failures。ただし全件 tmpdir 仮装 fixture＝Finding 2）
- `scripts/validate_implementation_governance_artifacts.rb`（既定ロケール `LANG` 未設定）：**`Encoding::CompatibilityError` で例外停止**（`RUBYOPT=-EUTF-8` 強制時のみ `validation passed`＝Finding 3）
- `--rederive reopen-procedure`（authority-map が「確定書式適合」と宣言する唯一の process）：**`result=fail reason=authoritative_section を一意特定できない（曖昧＝fail-closed）`**＝Finding 1（実 artifact 上で強制関数が pass し得ない）
- `--rederive design-review-wave`：`result=fail reason=確定書式でない下位見出し（曖昧＝fail-closed）`（authority-map §6 が「未適合＝fail-closed」と宣言するとおり＝設計どおりの安全側挙動）
- `tests/foundation/test_foundation_contracts.rb`：8 runs / 107 assertions / 0 failures（無回帰）
- `tests/runtime/test_*.rb`：15 ファイル全 clean（0 failures。無回帰）
- `tests/evaluation/test_*.rb`：10 ファイル全 clean（0 failures。無回帰）
- `tests/self_improvement/test_*.rb`：10 ファイル全 clean（0 failures。無回帰）
- `tests/paper_interface/test_*.rb`：8 ファイル全 clean（0 failures。無回帰）
- 統治 scripts の旧 v1 契約／旧命名／撤廃資産依存 grep：参照ゼロ（統治は workflow-control owner で他機能 business data を consume しない＝想定どおり）

**判定: 統治中核（Requirement 1〜8）プロセス成果物は概ね適合だが、Requirement 9 強制関数が実 artifact 上で実効的に未稼働（GO 不可・要手戻り）。手戻り種別は A=5（実装／プロセス成果物／テストの実体準拠化・追随漏れ）＋ B 候補=1（Finding 4＝design 行スキーマ整合、利用者判断で A 吸収可）。全面スクラッチ再実装は不要＝モデル実装は design 小節 1〜10 に忠実で他機能新契約との不整合ゼロ。authority-map 引用一致・テストの実体準拠化・validator エンコーディング統一・段抽出厳密化の部分修正で足りる。設計差し戻しは Finding 4 の 1 点のみ要検討。**
