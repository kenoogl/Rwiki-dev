# Requirements Local Review — dual-reviewer-implementation-governance（Requirement 9）

- 実施日: 2026-05-18
- 方式: 独立要件レビュアー（起草者とは別視点、REVIEW_PROTOCOL 節 2 の 5 ラウンド構成）
- 対象: requirements.md の Requirement 9「Workflow Execution Ledger and Compliance Enforcement」受入基準 1〜9
- 照合対象: 既存 Requirement 1〜8（特に 5/6/7）、INTENT.md、WORKFLOW_OVERVIEW.md、REVIEW_PROTOCOL.md、workflow-repair-procedure.md、CONVENTIONS.md、他 6 spec の requirements.md
- 生証跡（不変扱い）。レビュー結果をそのまま記録する。

---

## 第 1 ラウンド：基本整合性

### F1-1: 重要 — AC5 と既存 Requirement 5 AC1 の validation entrypoint 二重定義リスク

- 所在: requirements.md Requirement 9 AC5 ↔ Requirement 5 AC1〜AC3
- 問題: Requirement 5 AC1 は「conformance review artifacts と metric register artifacts に対する repo-contained validation entrypoint」を要求する。Requirement 9 AC5 は「正本文書から段集合を独立再導出してエージェント作成台帳と突き合わせる validation entrypoint」を要求する。両者が同一エントリポイントなのか別物なのかが要件文面から判別できない。
- 根拠: validation 実装者が、Requirement 5 のエントリポイントを拡張するのか新規に別エントリポイントを作るのかを推測するしかない。前回レビュー（2026-05-13 A-4）でも Requirement 5 の入出力契約未規定が should-fix 指摘済みであり、Requirement 9 が同じ曖昧さを増幅する。
- 推奨対応: AC5 に「Requirement 5 の validation entrypoint を拡張する／別エントリポイントとする」のいずれかの包含関係を一文で明示する（前回 P-2 の「上位集合であることを明示」と同型の最小修正）。
- 必要性判定: 要件に書くべき。二重正本は実装分岐を生む致命的曖昧さで、設計まで放置すると Requirement 5 設計と衝突する。包含関係明示は文言追記のみで致命的デメリットなし → 自動採択可。

### F1-2: 軽微 — Objective と AC の対象語の表記揺れ（process / stage / phase）

- 所在: requirements.md Requirement 9 Objective、AC1、AC7
- 問題: Objective と AC は「prescribed workflow process」を主語にするが、AC7 は「every prescribed workflow process」かつ「without specialization to any particular phase or stage」と書き、process / stage / phase の 3 語が定義なしに混在する。CONVENTIONS.md 節 3 は `phase` を 3 種（spec phase / review phase/profile / run status）に分けることを正本として要求している。
- 根拠: AC7 の「phase or stage」は CONVENTIONS.md 節 3 の `phase` 語使い分け規約に未準拠。「prescribed workflow process」が WORKFLOW_OVERVIEW の wave / gate / reopen を指すのか spec phase を指すのか、新概念なら CONVENTIONS.md 節 6（新 phase-like 概念は先に定義）に従い定義が要る。
- 根拠: AC1 が「phase execution, review wave, alignment gate, reopen procedure, and cross-spec alignment」を例示しており実体は読み取れるが、用語の正本整合は未達。
- 推奨対応: Requirement 9 冒頭または AC1 で「prescribed workflow process」の定義（= WORKFLOW_OVERVIEW で規定される phase execution / review wave / alignment gate / reopen / cross-spec alignment の総称）を一文で固定し、AC7 の「phase or stage」は CONVENTIONS.md 節 3 の語に整合させる。
- 必要性判定: 要件に書くべき（CONVENTIONS.md が用語定義を要件相当の正本としているため）。ただし定義一文の追加で足り、設計以降で吸収すると正本規約違反が固定化する → 自動採択可。

### F1-3: 軽微 — AC 受入番号・構造の整合は問題なし（記録）

- 所在: requirements.md Requirement 9 AC1〜AC9
- 確認: 受入番号 1〜9 連番、欠番なし。各 AC は単一の shall 文で構成され、Requirement 1〜8 の書式（"The governance feature shall ..."）と整合。表記揺れは F1-2 を除き検出なし。

---

## 第 2 ラウンド：上位文書照合

### F2-1: 重要 — 「canonical workflow documents」が正本文書群と一意に対応しない

- 所在: requirements.md Requirement 9 AC1・AC5（"the canonical workflow documents"）
- 問題: AC1/AC5 は「正本文書から段一式を再導出／再構築」を要求するが、正本が複数文書に分散している。WORKFLOW_OVERVIEW 節 7 は正本を 6 系統（INTENT.md、HUMAN_WORKFLOW.md、workflow-repair-procedure.md、workflow-gate-status.md、CONVENTIONS.md、各 spec.json）に列挙し、かつ WORKFLOW_OVERVIEW 自身は「概観であり判断根拠は上記正本を優先」と明記する。一方 wave の段構成（feature-local review → review wave → alignment gate → gate package）は WORKFLOW_OVERVIEW 節 2 と HUMAN_WORKFLOW 節 5.2.1 に、reopen 10 ステップは WORKFLOW_OVERVIEW 節 5 と workflow-repair-procedure 節 2 に二重記載されている。「どの文書を読めば段集合が一意に再導出できるか」が AC から定まらない。
- 根拠: AC5 の独立再導出（本要件の最重要機序）は「正本が機械的に段集合を一意に与える」ことが前提。現状の上位文書は同じ段集合を概観文書と正本文書に重複記述しており、どちらを権威ソースとするかが未指定だと、独立再導出器とエージェント台帳が別文書を読んで合法的に食い違い、検査が空振りする。
- 推奨対応: AC1/AC5 に「prescribed workflow process ごとの段集合の権威ソースを単一文書（例：process→文書の対応表）として指定すること」を要件として追加するか、独立再導出の入力を一意化する責務を AC に明記する。具体的にどの文書を権威にするかは設計判断でよいが、「権威ソースが process ごとに一意であること」自体は要件レベルの不変条件。
- 必要性判定: 要件に書くべき。これは抜け穴の核心（背景の「最重要」＝台帳書き落とし対策の実効性が、入力非一意だと成立しない）。一意化義務を要件に置くのは最小で、選択肢は「権威ソース一意性を要件化する」一択（劣後案＝設計任せは検査空振りを招くため明らかに劣る）→ 自動採択可。

### F2-2: 重要 — AC9 の「reopen-propagation 保存」が workflow-repair-procedure の 10 ステップ／状態遷移表と接続していない

- 所在: requirements.md Requirement 9 AC9 ↔ workflow-repair-procedure.md 節 2 Step 1〜10・節 3 状態遷移表（最終行 `governance spec introduced`）／Requirement 6 AC5
- 問題: AC9 は「この契約が複数 feature の完了基準を変えるとき、既存の reopen-propagation と cross-spec-alignment 義務を保存する」とだけ述べる。しかし Requirement 9 自体が新たに「irreversible action での機械的遮断」「台帳必須」を導入し、これは workflow-repair-procedure 節 2 の Step 7（gate 再実施）・Step 9（再開条件）や節 3 状態遷移表の「必須アクション」列に新義務を足す変更である。AC9 は「保存する」と言うのみで、reopen 手続き側に台帳・enforcement が組み込まれることを要求していない。reopen 経路（既存 phase の再開）でも台帳と独立再導出が要るのか、それとも新規着手時のみかが AC1（"at entry of any prescribed workflow process ... including ... reopen procedure"）と AC9 の間で不明瞭。
- 根拠: AC1 は reopen procedure を prescribed workflow process に含め台帳を要求する。AC9 は既存 reopen-propagation を「壊さない」とするのみ。両者を合わせると「reopen でも台帳必須」と読めるが、workflow-repair-procedure の 10 ステップに台帳ステップが無いため、独立再導出器が reopen 経路の段集合を再導出する根拠が上位文書に存在しない（F2-1 と連動）。
- 推奨対応: AC9 を「保存する」から一歩進め、「reopen procedure を含む既存手続き文書（workflow-repair-procedure）が本契約の台帳・独立再導出・enforcement を内包するよう同期されること」を要件として明示するか、少なくとも reopen 経路における台帳適用範囲を AC1 と矛盾しない形で確定する。
- 必要性判定: 要件に書くべき（AC1 と AC9 の内部整合に関わり、放置すると reopen 経路が enforcement の抜け穴になる）。ただし「workflow-repair-procedure をどう同期するか」の具体は設計／文書同期作業でよく、要件は「reopen 経路も本契約の適用対象であることを AC9 で曖昧にしない」程度で足りる。複数の合理的書き方が残る（AC9 改稿 vs AC1 に reopen 限定注記）→ 利用者判断。

### F2-3: 軽微 — 「独立生成」概念は CONVENTIONS.md 節 8.4 の 3 役独立性と整合（記録、波及なし方向）

- 所在: requirements.md Requirement 9 AC2・AC4 ↔ CONVENTIONS.md 節 8.4
- 確認: AC2/AC4 の「drafting author が self-review しない」「独立プロセスで生成」は、CONVENTIONS.md 節 8.4 の「各役は独立した呼び出し（会話履歴を共有しないセッション）」「メイン応答主体は 3 役のいずれにもならない」と概念整合。矛盾なし。表記は「independent」で統一されており上位文書と齟齬なし。

---

## 第 3 ラウンド：本質的観点

### F3-1: 致命 — AC8 の非 spec.json 経路封鎖が「遮断」でなく「文面埋め込み」止まりで、enforcement の機序が成立しない

- 所在: requirements.md Requirement 9 AC8 ↔ AC6・背景意図（非 spec.json 経路の抜け道を塞ぐ）
- 問題: 背景の照合基準は「非 spec.json 経路の抜け道を塞ぐ」=「機械的に遮断」を意図する。しかし AC8 は「human approval request の文面に各段→証拠パスの対応表を embed する」ことしか要求していない。AC6 の enforcement point は「spec.json approval or phase-transition writes and any irreversible workflow state change」を遮断対象とするが、HUMAN_WORKFLOW 節 5.2.7 の phase evidence summary／gate package を介した人間承認依頼は「文書（gate package）を人間に渡す」行為であり、spec.json 書き込みでも phase-transition write でもない。すなわち AC8 の経路は「対応表が埋め込まれているか」を誰も機械検査しない限り、起草者が対応表を自作・自己申告して人間に渡せる。AC3（完了述語は証拠ファイル存在・構造で判定、appearance で満たせない）と AC5（独立再導出）の保護が AC8 経路には掛かっていない。
- 根拠: 本 Requirement 9 の存在理由は「注意喚起型対策（1 行出すだけ）では機序が止まらなかった」こと。AC8 が「文面に埋め込むことを要求」だけで終わると、これはまさに失敗した注意喚起型対策と同型（フォーマット遵守を起草者の善意に委ねる）になり、enforcement の核（AC6 の機械遮断・AC5 の独立検査）が非 spec.json 経路に適用されない。これは受入基準が目的（抜け穴封鎖）を満たさない＝致命。
- 推奨対応: AC8 に「human approval request 生成／提示を AC6 の enforcement point に含め、台帳・全証拠述語・独立再導出が pass しない限り承認依頼の生成（gate package 化）自体を機械的に遮断する」ことを追加する。「対応表 embed」だけでなく「対応表が独立再導出と突合され不一致なら承認依頼を出せない」ことを要件化する。
- 必要性判定: 要件に書くべき（目的との乖離＝致命、設計では補えない。AC6 の遮断対象集合に承認依頼経路が入っていないと設計者は遮断を実装しない）。修正方向は実質一択（AC8 経路を AC6 enforcement に編入）。劣後案＝検査なし embed は失敗対策の再現で明らかに劣る → 自動採択候補だが、AC6 の文言（"irreversible workflow state change"）に承認依頼生成が含まれるかの解釈に幅があり、AC8 をどう AC6 に接続するか（AC6 拡張 vs AC8 に遮断文追加）に複数合理案 → 利用者判断。

### F3-2: 重要 — AC5 の「independent re-derivation」の独立性が同一エージェント同一文脈では実効しない懸念が要件に表れていない

- 所在: requirements.md Requirement 9 AC5
- 問題: AC5 は「エージェント作成台帳とは independently に、正本から段集合を再導出し突合する」検査エントリポイントを要求する。だが「independently」の独立性が何に対する独立かが未規定。検査スクリプトが、台帳を書いたのと同じエージェントが同じ実行内で書いたスクリプトであれば、エージェントが正本の同じ読み落としを台帳とスクリプト両方に再現でき、独立再導出が形だけになる（背景の「台帳の書き落とし対策。最重要」が無効化）。AC2/AC4 は「drafting author と別プロセス」を明記するが、AC5 の検査器自体の独立性（誰がいつ書くか／正本パースが台帳作成ロジックを共有しないこと）には独立性要件が無い。
- 根拠: 本要件の最重要機序は「検査が台帳と無関係に正本から独立再導出」すること。独立性の対象（再導出ロジックは台帳生成ロジックと別実装・別正本パースであること）を要件化しないと、AC5 は「同じ誤読を二度する」攻撃面を残す。
- 推奨対応: AC5 に「再導出は台帳生成に用いたロジック・パース結果を共有せず、正本文書を一次ソースとして独立に解釈すること（台帳生成器の出力に依存しない）」という独立性条件を一文追加する。
- 必要性判定: 要件に書くべき（最重要機序の実効性に直結、設計で「独立」をどう実装しても要件に独立対象が無いと検証不能）。修正は条件一文追加で足り劣後案なし → 自動採択可。

### F3-3: 軽微 — AC3 の「structural conformance」と Requirement 5 AC3 の「minimum required sections / metric keys」の用語一貫（記録）

- 所在: requirements.md Requirement 9 AC3 ↔ Requirement 5 AC3
- 確認: AC3 の「存在＋構造適合（structural conformance）で完了述語を定義」は Requirement 5 AC3 の「必須セクション・metric キーの存在検査」と概念整合し、appearance では満たせない方針が一貫。二重定義ではなく Requirement 9 が Requirement 5 の検査を完了述語の根拠として参照する包含関係。ただし F1-1 の通り「同一エントリポイントか」は別途要明示。

---

## 第 4 ラウンド：例外系（強制関数自体の失敗モード）

### F4-1: 致命 — 検査スクリプト不在・破損・正本不在/曖昧時の挙動（fail-open/fail-closed）が未規定

- 所在: requirements.md Requirement 9 AC5・AC6 全般
- 問題: AC6 は「台帳が存在し全述語と独立再導出検査が pass しない限り遮断」とする。だが (a) 検査スクリプト自体が存在しない／実行時例外で結果を返せない、(b) 正本文書が不在または段集合を一意に再導出できないほど曖昧（F2-1）、(c) 台帳生成器がクラッシュした、これらの状況で enforcement が fail-closed（遮断を維持）か fail-open（検査不能なら通す）かが要件に無い。fail-open なら「検査スクリプトを壊す／消す」が最大の抜け穴になり、本要件が防ごうとした「機序の無言省略」が検査破壊という形で復活する。
- 根拠: 強制関数の要件は失敗モードでの既定挙動を定めないと、強制関数の不調＝迂回路になる。背景の不遵守はまさに「機序を無言で省略」したものであり、検査器の不調を fail-open にすると同じ結果を別経路で許す。
- 推奨対応: AC（新 AC または AC6 拡張）に「validation entrypoint または独立再導出が結果を確定できない場合（不在・実行失敗・正本曖昧）は pass とみなさず irreversible action を遮断する（fail-closed）」を明示する。併せて緊急時の人間明示オーバーライドを置くなら、その経路自体を証跡必須化する（F4-2 と連動）。
- 必要性判定: 要件に書くべき（失敗モード既定が無いと強制関数が無効化可能＝致命、設計判断に委ねると fail-open が選ばれ得る）。fail-closed 一択（fail-open は要件目的を破壊するため明らかに劣る）→ 自動採択可。

### F4-2: 重要 — 緊急時の人間オーバーライド（迂回可否）と可逆性が未規定

- 所在: requirements.md Requirement 9 AC6・AC7
- 問題: AC7 は「no process exempt（例外なし）」を要求する。実運用では検査器バグや正本不備で正当な作業が完全停止する事態が起こり得るが、AC に人間による明示的・記録付きオーバーライド経路が無い。一方で安易なオーバーライドを許せば抜け穴になる。AC6/AC7 はこの緊張（完全強制 vs デッドロック回避）に対する立場を示していない。HUMAN_WORKFLOW は「承認・最終判断・ambiguous case は人間」と役割分担するが、Requirement 9 はその人間裁量と「例外なし遮断」の関係を規定しない。
- 根拠: 例外なし強制は、強制関数自体の欠陥時に作業をデッドロックさせる。要件として「オーバーライドは存在しない」のか「証跡必須の人間オーバーライドのみ許す」のかを決めないと、運用で非公式回避（=本要件が防ぐべき挙動）が発生する。
- 推奨対応: AC に「強制の唯一の合法的迂回は、理由・対象 process・欠落段を記録した人間明示オーバーライド証跡を伴う場合に限る。証跡なき迂回は workflow 逸脱」を追加する（AC8 の対応表埋め込みと整合させる）。または「オーバーライドを設けない」と明示し、その場合のデッドロック解消手順（正本修正→reopen）を AC9 と接続する。
- 必要性判定: 要件に書くべき（例外なし条項 AC7 と運用現実の整合は要件レベルの方針判断）。ただし「オーバーライドを設ける／設けない」は複数の合理選択肢が残り、いずれも致命影響あり（設けないとデッドロック、設けると抜け穴）→ 利用者判断。

### F4-3: 軽微 — 規模・コストの扱い（全 process 着手前に台帳必須のオーバーヘッド）が未言及

- 所在: requilements.md Requirement 9 AC1・AC7
- 問題: AC1/AC7 は「あらゆる prescribed workflow process の着手前に毎回 repo-contained 台帳を新規生成」を例外なく求める。微小な reopen や軽微 signal 処理にも全段台帳生成を課すと運用コストが過大化し、形骸化（台帳を機械的に空生成する）を誘発し得る。要件はこのコスト/形骸化リスクへの立場（最小プロセスでも完全台帳か、規模比例か）を示していない。
- 根拠: 過剰な強制は形骸化（背景の「体裁で満たす」回帰）を生む。ただしこれは過剰修正に倒れやすい論点でもある。
- 推奨対応: 要件には「例外なし」を維持しつつ、台帳の粒度（小規模 process では段が少数になるのは段集合が正本で小さいため自然、という解釈）を Introduction か AC で一文補足する程度。本格的なコスト最適化は設計判断。
- 必要性判定: 設計以降で足りる。AC7 の「例外なし」を緩めると本要件の趣旨が崩れるため要件変更は不要。形骸化対策は AC3（証拠構造判定）・AC5（独立再導出）が既にカバー。→ 自動採択（要件変更なし、記録のみ）。

---

## 第 5 ラウンド：波及精査（必須 5 ステップ）

### ステップ 1: 第 1〜4 で指摘した変更/不足値のリスト化

- V1（F1-1）: AC5 と Requirement 5 AC1 の validation entrypoint 包含関係明示
- V2（F1-2）: 「prescribed workflow process」定義固定、AC7 の phase/stage を CONVENTIONS 節 3 整合
- V3（F2-1）: 段集合の権威ソース一意化（process→文書対応）の要件化
- V4（F2-2）: AC9 と workflow-repair-procedure（reopen 10 ステップ）の適用範囲整合
- V5（F3-1）: AC8 非 spec.json 経路を AC6 enforcement に編入
- V6（F3-2）: AC5 独立再導出の独立性対象明示
- V7（F4-1）: 検査不能時 fail-closed 明示
- V8（F4-2）: 人間オーバーライド経路の有無と証跡条件

### ステップ 2: 各値の網羅検索（他 6 spec の requirements.md、上位文書、統治内他受入）

- 検索コマンド: `grep -niE "governance|ledger|enforcement|spec.json approval|irreversible|re-deriv|reopen|alignment gate|conformance review"` を foundation/runtime/evaluation/self-improvement/paper-interface の requirements.md に対し実行。
- 結果: 該当ヒットは evaluation requirements.md AC（行 94）の「invalidated runs に基づく derived artifact の stale 化／再導出」1 件のみ。これは run invalidation 文脈であり、Requirement 9 の「workflow execution ledger / 正本からの段独立再導出」とは概念が異なる（語 "re-derive" の偶然一致）。foundation/runtime/self-improvement/paper-interface の requirements.md には Requirement 9 関連語のヒットなし。
- 統治内他受入: Requirement 5（validation entrypoint）、Requirement 6（cross-spec alignment / gate status / intent-triggered reopen）、Requirement 7（phase-review metrics）が Requirement 9 と概念隣接。F1-1（Req5）・F2-2（Req6 AC5）・F3-3（Req5）で整合所見済み。

### ステップ 3: 統治が他 5 spec に暗黙の契約変更／新義務を課していないかの精査

- 判定: **波及なし（全件明示記録）**。
- 根拠: Requirement 9 は「workflow 実行手続き（wave/gate/reopen/cross-spec alignment）の遂行に台帳と機械強制を課す」cross-cutting workflow contract であり、対象は workflow を実行するエージェント／検査器である。foundation/runtime/evaluation/self-improvement/paper-interface の各 requirements.md は feature の business contract（schema、orchestration、metrics、improvement loop、paper export）を定義しており、Requirement 9 が要求するのは「それら spec の requirements/design/tasks フェーズを進めるワークフロー手続き」への強制であって、各 spec の AC（フィールド・挙動）を変更しない。Requirement 9 の completion 基準変更は「フェーズ遂行手続き」に対するもので、各 feature の「何を実装するか」には新義務を課さない。
- 補足: Requirement 8 AC6 が v2-acquisition spec を heuristic-default の正本所有者とする既存の従属関係があるが、Requirement 9 はこの所有関係に触れず、波及なし。
- 結論: 隣接 6 spec（foundation/runtime/evaluation/self-improvement/paper-interface/v2-acquisition）への暗黙契約変更・新義務付与は**なし**。後で「見落とし」と誤認されないよう、波及なしをここに明示記録する。

### ステップ 4: 隣接同期 TODO（通し番号）

- 他 spec への文言同期 TODO: **0 件**（ステップ 3 により波及なし）。
- 上位文書同期 TODO（統治 spec 内ではなく operations 側、本要件承認後に発生し得るもの。要件レビュー段では実施せず記録のみ）:
  - TODO-1: workflow-repair-procedure.md 節 2/節 3 に Requirement 9 の台帳・独立再導出・enforcement を内包させる同期（F2-2/V4 由来）。理由: AC1 が reopen procedure を対象に含めるが reopen 10 ステップに台帳ステップが無く、独立再導出の入力根拠が欠ける。対象=workflow-repair-procedure.md、修正前=台帳ステップなし、修正後=reopen 経路にも台帳・enforcement 適用を明記。設計フェーズ以降の文書同期作業。
  - TODO-2: WORKFLOW_OVERVIEW 節 7／HUMAN_WORKFLOW 節 5.2.7 に「prescribed workflow process ごとの段集合権威ソース」対応を追加する同期（F2-1/V3 由来）。理由: 独立再導出の入力一意化。対象=WORKFLOW_OVERVIEW.md・HUMAN_WORKFLOW.md。設計／文書同期作業。
  - いずれも他 feature spec ではなく上位運用文書側であり、Requirement 9 の設計フェーズで扱う範囲。要件レビュー段（本セッション）では同期適用しない。

### ステップ 5: 本セッション同期か別送りかの利用者判断材料

- 他 feature spec への隣接同期: 0 件のため判断不要（波及なし確定）。
- TODO-1/TODO-2（上位文書同期）: いずれも「Requirement 9 が要件承認 → 設計フェーズ丸ごと再実施」の流れ（spec.json custom.alignment.design.note と整合）の中で扱う実質変更含み。要件レビュー段での文言同期ではなく、要件承認後の設計／文書修復作業に属する。判断材料:
  - 統治 spec requirements は spec.json 上 `approved: false`（未承認、reopened）。本要件レビューは承認前の精査であり、TODO-1/2 は本要件の文言修正（F2-1/F2-2 の推奨対応を requirements.md に反映するか）と、その後の上位文書同期に分かれる。
  - requirements.md への文言反映自体は要件改版（実質変更）であり利用者の明示承認が必要（規律 discipline_approval_required）。本レビューは所見提示のみで requirements.md/spec.json は変更しない。

---

## 総合所見

- Requirement 9 の意図（台帳必須・証拠ベース完了判定・独立生成・独立再導出・不可逆操作遮断・例外なし適用・承認文面への対応表埋め込み・既存 reopen 義務保存）は受入基準として概ね表現されているが、**enforcement の機序が成立するための核心条件に致命級の欠落が 2 件**ある（AC8 の非 spec.json 経路が遮断でなく文面埋め込み止まり＝F3-1、検査不能時の fail-closed 未規定＝F4-1）。この 2 件を残したまま要件承認すると、本要件が「失敗した注意喚起型対策」の再現になる構造的リスクがある。
- 重要級 4 件（F1-1 validation entrypoint 二重定義、F2-1 権威ソース非一意、F2-2 reopen 経路整合、F3-2 独立再導出の独立性対象）は、いずれも「台帳書き落とし対策＝最重要機序」の実効性に直結し、設計では補えない要件レベルの不変条件である。
- 波及精査: 他 6 spec への暗黙契約変更・新義務は**なし（明示記録済み）**。隣接同期 TODO は他 feature spec には 0 件、上位運用文書（workflow-repair-procedure / WORKFLOW_OVERVIEW / HUMAN_WORKFLOW）に対する設計フェーズ同期が 2 件、いずれも要件承認後の作業。

---

## 集計

- 致命: 2 件（F3-1、F4-1）
- 重要: 4 件（F1-1、F2-1、F2-2、F3-2）
- 軽微: 4 件（F1-2、F3-3、F4-3、F2-3。うち F3-3/F2-3 は整合確認の記録）

### must-fix 候補一覧（番号・1 行要約・必要性判定の別）

1. F3-1（致命）: AC8 の非 spec.json 承認経路を AC6 の機械遮断に編入する — 利用者判断（AC6/AC8 の接続方法に複数合理案）
2. F4-1（致命）: 検査不能・正本曖昧・スクリプト不在時を fail-closed と明示 — 自動採択可（fail-closed 一択）
3. F1-1（重要）: AC5 と Requirement 5 AC1 の validation entrypoint 包含関係を明示 — 自動採択可
4. F2-1（重要）: prescribed workflow process ごとの段集合権威ソース一意化を要件化 — 自動採択可
5. F2-2（重要）: AC9／AC1 と reopen 10 ステップの適用範囲整合 — 利用者判断（AC9 改稿 vs AC1 注記）
6. F3-2（重要）: AC5 の independent re-derivation の独立性対象（台帳生成ロジック非共有）を明示 — 自動採択可
7. F1-2（軽微）: prescribed workflow process 定義固定・AC7 の phase/stage を CONVENTIONS 節 3 整合 — 自動採択可

### 波及あり件数

- 0 件（他 6 spec への暗黙契約変更・新義務なし。明示記録済み）。上位運用文書への設計フェーズ同期 TODO は 2 件（要件承認後）。
