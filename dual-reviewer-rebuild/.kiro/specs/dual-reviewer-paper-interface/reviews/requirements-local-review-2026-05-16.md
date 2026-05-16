# dual-reviewer-paper-interface requirements 個別レビュー

## 取得メタデータ

- 実施日：2026-05-16
- 対象：`dual-reviewer-paper-interface/requirements.md`
- 上流入力：`dual-reviewer-foundation/requirements.md`（must-fix #1〜#8 適用後）
- 方式：claude --print --disallowedTools "Read,Write,Edit"（ファイルアクセス技術的遮断）
- 主役：claude-sonnet-4-6
- 敵対役：claude-opus-4-7
- 判断役：claude-opus-4-6
- 通信構造：β 逐次方式（主役 → 敵対役 → 判断役、各役が前段出力を入力として受け取る）

---

## 主役発見（claude-sonnet-4-6）

以下、5 ラウンドの要件レビューを実施する。

---

## 第 1 ラウンド：基本整合性

対象文書内部の論理矛盾・曖昧表現・内部重複を検査する。

**P-1: ERROR**
- 対象箇所：Req 1 AC 5
- 説明：「shall not allow claim-supporting artifacts that cannot be traced to versioned evidence」の "allow" は否定形で禁止を表しているが、違反時の帰結（拒否・警告・フラグ付け）が未規定。他の AC と比べて enforced contract ではなく願望として読める。
- 根拠：他の AC（例：Req 3 AC 5 "shall not upgrade"）も類似の受動的禁止表現だが、Req 1 AC 5 は claim が実際に入力される経路で gate として機能する必要があるため、処置の具体化が必要。

**P-2: WARN**
- 対象箇所：Req 2 AC 4
- 説明：「support regeneration when upstream evaluation outputs are unchanged」は上流が変化した場合の再生成ポリシーを規定しない。変化時の挙動（旧レポートを無効化する・差分のみ更新する・ユーザー確認を求める）が空白。
- 根拠：再生成可能性を保証するなら、上流変化時の取り扱いこそが主要ケースになる。

**P-3: WARN**
- 対象箇所：Req 3 AC 4 と Req 5 AC 1
- 説明：Req 3 AC 4「preliminary labeling where evidence is intentionally incomplete」と Req 5 AC 1「support explicit labeling of preliminary evidence」は実質的に同一の要件を 2 か所で述べている。
- 根拠：Req 3 はカバット全般の追跡、Req 5 は mature/preliminary の区分が主旨だが、AC レベルで重複しており、どちらが規範的かが不明。

---

## 第 2 ラウンド：上位文書照合

foundation/requirements.md の契約と paper-interface/requirements.md の対応を検査する。

**P-4: ERROR**
- 対象箇所：Req 6 全体
- 説明：paper-interface Req 6 は "manual dogfooding review" および "runtime-mediated review" という語彙を使うが、これらを定義した foundation Req 6 AC 6 を明示的に参照していない。paper-interface が独立して同じ語彙を定義しようとすると、将来的に vocabulary の diverge（乖離）が起こるリスクがある。
- 根拠：foundation Req 6 AC 6「The foundation shall define a canonical review-mode vocabulary…」が canonical 定義の所有者と明示されているため、下流 spec は「foundation の review-mode vocabulary に従う」と宣言する必要がある。

**P-5: ERROR**
- 対象箇所：Req 1 AC 2
- 説明：「preserve run and analysis provenance for each claim-supporting artifact」は provenance を保存することを要求するが、foundation Req 6 AC 7 が定義した標準 provenance フィールド名（source repository identity / source revision）を参照していない。paper-interface が独自フィールドを定義した場合、foundation との field naming 整合が保証されない。
- 根拠：Boundary Context には「`dual-reviewer-foundation` の evidence field naming に依存する」とあるが、依存の宣言だけでは具体的な field 名のバインドにならない。

**P-6: WARN**
- 対象箇所：Req 4 AC 3「shall not override invalidation policy」
- 説明：foundation Req 6 AC 3/5 は無効化マーカーシステムを積極的契約として定義しているが、paper-interface の対応 AC は「無効化ポリシーを上書きしない」という消極的禁止のみ。paper-facing artifact から invalidated run を除外するという積極的要件が存在しない。
- 根拠：foundation Req 6 AC 5「support downstream … excluding invalid runs by metadata alone」は下流 spec がこの機能を能動的にサポートすることを期待している。

**P-7: WARN**
- 対象箇所：Boundary Context および全 Req
- 説明：foundation Req 7（repo-contained asset rule）に paper-interface が対応しているかどうかが不明。paper-facing report fragment や figure source data がリポジトリ内に置かれるのか、出力専用ファイルとして外部に置かれるのかが未規定。
- 根拠：foundation Req 7 AC 1「require all prompts, schemas, and templates … to be stored inside the repository」の射程が paper-interface artifact まで及ぶかどうかの明示が必要。

---

## 第 3 ラウンド：本質的観点

機能として必要なものが抜けていないかを検査する。

**P-8: CRITICAL**
- 対象箇所：Req 1 全体
- 説明：claim-to-evidence mapping を規定する Req 1 全体を通して、「claim とは何か」が未定義。claim の分類体系（仮説・手法の主張・定量的比較・限界の主張など）がなければ、AC を実装するための対象が確定しない。
- 根拠：claim は本 spec の中心的概念であり、Req 1〜Req 3 が全面的に依拠しているが、Introduction にも Boundary Context にも claim の定義が存在しない。これは実装を不可能にする根本的な欠落である。

**P-9: ERROR**
- 対象箇所：Req 1、Req 2（intake 全般）
- 説明：`dual-reviewer-evaluation` からの intake インターフェースが paper-interface 側にも evaluation 側にも定義されていない。Boundary Context には「comparison-ready data を受け取る」とあるが、受け取るフィールド・形式・バリデーション規則が未規定。
- 根拠：Req 2 AC 1「define required fields for figure and table source artifacts」は fields を定義せよと言うが、それが evaluation 出力のどの fields に対応するかを指定しない。評価側が変更した場合の検知手段もない。

---

## 第 4 ラウンド：例外系（失敗モード・並行・セキュリティ・観測・可逆性・規模）

**P-10: WARN**
- 対象箇所：全 Req（失敗モード全般）
- 説明：以下の失敗モードがどの要件でも扱われていない。
  - claim に紐づく evidence が存在しないとき（Req 1 AC 5 は禁止するが処置が不明）
  - evaluation 出力の provenance メタデータが不完全なとき
  - 同一 claim に矛盾する evidence が複数あるとき
- 根拠：paper-facing artifact は論文証拠として使われるため、不正入力時に誤った主張を通過させないための gate 要件が必要。

---

## 第 5 ラウンド：波及精査

他 spec への影響・他 spec との依存整合を検査する。

**P-11: WARN**
- 対象箇所：Req 4 AC 5
- 説明：「make downstream narrative transformations explicit and versionable」が foundation の versioning 体系（schema versioning、prompt version traceability）とどう接続するかが未定義。narrative transformation の version を foundation の versioned artifact と同一システムで管理するのか、paper-interface 独自の tracking を持つのかが不明。
- 根拠：foundation Req 3 AC 3「forbid silent incompatible edits」および Req 4 AC 2「require prompt version traceability」は versioning を repo-level artifact として定義しているが、paper-interface の transformation versioning がその傘に入るかどうかが明示されていない。

---

## 発見件数要約

- CRITICAL：1 件（P-8：claim 未定義）
- ERROR：4 件（P-1 enforcement 欠落、P-4 review-mode vocabulary 参照欠如、P-5 provenance フィールド名未結合、P-9 intake インターフェース未定義）
- WARN：6 件（P-2 上流変化時ポリシー欠落、P-3 AC 重複、P-6 invalidated run の積極的除外なし、P-7 repo-contained ポリシー未対応、P-10 失敗モード欠落、P-11 transformation versioning 未接続）
- INFO：0 件

合計 11 件。過剰検出を避けた結果、INFO は除外している。最優先対処は P-8（claim 定義）と P-9（evaluation intake 契約）で、これらは仕様の実装可能性に直結する。

---

## 敵対役レビュー（claude-opus-4-7）

要件レビューの敵対役として、強制反論の姿勢で精査した。安易な同調はせず、severity（重大度）の過大評価と発見の重複に踏み込む。

---

## パート1：主役の各発見への反論

**P-1（Req 1 AC 5 / ERROR）→ 反論あり**
- 「〜を許さない（shall not allow）」は EARS 形式（要件を定型文で書く記法）における正当な制約型の受け入れ基準であり、これ自体が強制契約として読める。違反時の処置（拒否か、警告か、印を付けるか）は設計段階で決める実装方針であって、要件文に書くべき内容ではない。「来歴をたどれない証拠が出力に存在しない」ことは処置を指定しなくても検証できるため、テスト可能性は満たされている。ERROR は過大。残る論点は「取り込み口で弾く」のか「印を付けて通す」のかの境界だけで、これは WARN 相当、しかも設計課題である。

**P-2（Req 2 AC 4 / WARN）→ 反論あり（部分的）**
- AC 4 の主旨は再現性（同じ入力なら同じ出力を作り直せる）であり、「変わっていないとき」という限定はべき等性を述べたものだ。上流が変わったときは新しい評価出力から作り直すのが Req 4 AC 1（評価出力を消費する）の既定経路であり、欠落ではなく自明な通常動作である。主役は「再生成ポリシーの空白」と性格付けしているが、本当に残るのは「古いレポートが陳腐化したことを検知する仕組み」だけで、論点を広げすぎている。WARN は維持してよいが、論拠の言い換えが必要。

**P-3（Req 3 AC 4 と Req 5 AC 1 / WARN）→ 反論あり**
- この 2 つは重複ではなく相補である。Req 3 AC 4 は「意図的に不完全な証拠」に対する限界追跡の文脈でのラベル付け、Req 5 AC 1 は「成熟した証拠と暫定的な証拠の区別」という研究精度の文脈でのラベル付けで、目的（Objective）も想定読者（著者と研究者）も異なる。表面の語（preliminary）が一致するだけで要件としての同一性はない。「重複だから統合せよ」と扱うと一方の目的が消える危険がある。むしろ後述 A-3 の通り、真の問題は Req 1 AC 3・Req 3 AC 2・Req 5 に散在する3系統の証拠分類が統一されていないことであり、主役はこの大きい問題を見落として小さい誤検出を出している。

**P-4（Req 6 / ERROR）→ 反論あり（部分的）**
- 指摘の方向は妥当だが2点で過大。第一に Boundary Context が「foundation の証拠フィールド命名に依存する」と既に弱い結合を宣言している。第二に、これは P-5 と同一の根本原因（下流が上流の正準語彙へ明示的に結びつく宣言文を欠く）であり、別々の ERROR として2件計上するのは件数の水増しである。1件に統合し、severity は ERROR と WARN の境界。

**P-5（Req 1 AC 2 / ERROR）→ 反論あり（部分的）**
- 「来歴を保存する」は要件として正しい抽象度であり、具体的フィールド名（ソースリポジトリ識別子・ソースリビジョン）への結合は設計段階の対応付けである。要件文がフィールド名を列挙する必要はない。ERROR は過大。P-4 と同根のため統合すべき。

**P-6（Req 4 AC 3 / WARN）→ 反論あり**
- これは層の取り違えを含む。foundation Req 6 AC 5 は無効実行の除外を支援する下流として「評価（evaluation）と自己改善（self-improvement）」を明示し、paper-interface を挙げていない。paper-interface は Req 4 AC 1 により評価から「比較可能な状態に整えられたデータ」を受け取る層であり、無効実行の能動的除外を要求すると、無効化ロジックを上位のレポート層へ押し上げ Req 4 の分離原則に反する。受動的な「上書きしない」姿勢こそ正しい。ただし「paper-interface は既に妥当性選別済みのデータのみを消費する」という積極要件の欠落は別個の真の課題であり、主役の枠組みとは違う。

**P-7（Boundary Context / WARN）→ 反論あり（部分的）**
- foundation Req 7 は「runtime 動作に必要なプロンプト・スキーマ・テンプレート」と射程を自ら限定しており、論文向け成果物は runtime 動作資産ではない（Req 4 AC 4 が論文都合を従属させ、Out of scope が runtime rule を除外）。よって foundation Req 7 適合の欠落として枠付けるのは誤り。真に残るのは内部課題、すなわち Req 2 AC 3 が「分離」と言うのみで保管場所（リポジトリ内/外）を述べない点で、後述 A-4 に接続する。

**P-8（Req 1 / CRITICAL）→ 反論あり（部分的）**
- 「claim（主張）」の最小定義や用語集項目が無い点は確かに Req 1 のテスト可能性を損なう。だが分類体系（仮説・手法主張・定量比較・限界主張）の必須化は要件段階の過剰仕様であり範囲逸脱に近い。claim の構造は設計で定義でき、実装が「不可能」になるわけではない。最小定義の欠落は WARN〜ERROR 相当で、CRITICAL と分類体系の強制は退ける。

**P-9（Req 1・Req 2 / ERROR）→ 反論あり（部分的）**
- 取り込みフィールド・形式・バリデーション規則は設計レベルの契約であり、評価 spec の出力契約か設計フェーズに属す。要件として適切な残課題は「評価→論文の明示的入力契約が存在することを要求する文」が無いことだけで、これは要件相応だが、フィールドや形式を今要求するのは設計侵食。ERROR は過大。さらに「評価側変更の検知手段が無い」は主役自身の P-2 と重複している。

**P-10（全 Req / WARN）→ 反論あり（部分的）**
- 3つの失敗モードのうち「証拠が無い」は P-1（Req 1 AC 5）の、「評価来歴が不完全」は P-5/P-9 の再掲であり、主役自身が二重計上している。独立して新規なのは「同一 claim に矛盾する証拠が複数」だけで、これは確かに有効。WARN を矛盾証拠の1点に絞るべきで、丸ごとの WARN は過大。

**P-11（Req 4 AC 5 / WARN）→ 反論あり（部分的）**
- 「versionable（版管理可能）」が既に版管理下に置くことを含意しており、foundation の傘に入れるか独自管理かは設計判断である。要件は「明示的かつ版管理可能」を求めれば足り、AC 5 はそれを満たす。注記としては有益だが要件欠陥ではなく INFO 相当。P-4/P-5 の「明示結合欠如」系統とも一部重なる。

---

## パート2：主役が見落とした独立発見

**A-1（ERROR）**
- 対象箇所：Req 1 AC 4 と Req 4 AC 1 の整合
- 説明：Req 1 AC 4 は「評価出力が既に存在する場合は生ログの再解釈を避ける」と書く。この「存在する場合は」という限定は、裏返すと「存在しない場合は paper-interface が生ログを直接解釈してよい」という抜け道を許す。これは Req 4（評価/runtime を支配しない・消費に徹する）の分離原則と、Introduction の「論文都合が下層へ逆流してはならない」に正面から反する。
- 根拠：層分離を謳う Req 4 と AC 1 AC 4 の条件節が論理的に衝突しており、論文層が生証拠を直接処理する経路が要件上開いている。これは設計ではなく要件文の内部矛盾である。
- 重大度：ERROR

**A-2（WARN）**
- 対象箇所：Req 2・Req 3 全体（部分生成ポリシーの欠落）
- 説明：一部の claim にだけ証拠が対応し、他は未対応のままレポート生成を実行する場合の方針が無い。Req 3 AC 4 は「不完全な証拠」の暫定ラベルを扱うが、「対応証拠が無い claim を含むレポートを出してよいか、出すなら未対応 claim をどう明示するか」は別問題で未規定。
- 根拠：論文向け成果物は主張の網羅性が品質要件になるため、未対応 claim の取り扱いは機能要件として必要。P-8（claim 定義）や P-10（証拠欠落の失敗モード）とは別の、レポート単位の網羅性課題である。
- 重大度：WARN

**A-3（ERROR）**
- 対象箇所：Req 1 AC 3 / Req 3 AC 2 / Req 5 AC 1-2、および foundation Req 6 AC 2
- 説明：証拠の分類語が3系統に散在し統一されていない。Req 1 AC 3 は「直接/caveat 付き/暫定」、Req 3 AC 2 は「無効データ除外/部分証拠/方法論的限界」、Req 5 は「成熟/暫定/探索的」「安定比較集合/探索分析」。これらは重なり合うが正準語彙へ統合されておらず、さらに foundation Req 6 AC 2 が定義する「evidence class（証拠クラス）」フィールドに一切結合されていない。
- 根拠：分類が分裂したまま foundation の正準フィールドに紐付かないと、レポート間で証拠等級の解釈が乖離する。これは主役 P-3 が見た1組の重複より広く深い、語彙断片化＋上流未結合の構造的欠陥。
- 重大度：ERROR

**A-4（WARN）**
- 対象箇所：Req 2 AC 3
- 説明：「論文向け成果物を生証拠および中核評価出力から分離して保つ」の「分離（separate）」が定量化されておらず検証不能。別ディレクトリか、別スキーマか、別リポジトリかが不明で、合否を機械的に判定できない。
- 根拠：要件はテスト可能でなければならない。「分離」の測定基準欠如は曖昧表現の defect であり、P-7（foundation Req 7 適合）とは別個の内部テスト可能性の問題。
- 重大度：WARN

**A-5（WARN）**
- 対象箇所：Req 6 AC 4（および foundation Req 6 AC 6 の "at minimum" 条項）
- 説明：foundation Req 6 AC 6 は review-mode 語彙を「最低限」手動 dogfooding と runtime 媒介の2区分と定義し、拡張余地を残す。paper-interface Req 6 AC 4「混在時に caveat を付ける」は2区分前提で書かれており、上流が将来モードを追加した場合に第3以降のモード混在の扱いが規定されない。
- 根拠：上流が明示的に拡張余地を残している語彙に対し下流が二値前提で固定すると、前方互換性が崩れる。主役 P-4 は「参照欠如」を見たが、参照を付けても残るこの拡張耐性の欠落は別問題。
- 重大度：WARN

---

## 総評（系統的批判）

- 主役のレビューは要件文に対し設計レベルの詳細（強制処置・取り込みフィールド・バリデーション規則・分類体系）を要求する傾向があり、P-1/P-5/P-9/P-11 で severity を過大評価している。CRITICAL 1・ERROR 4 のうち、純粋な要件欠陥として ERROR を維持できるのは P-4/P-5 統合後の1件程度。
- 件数に重複がある：P-4 と P-5 は同根、P-10 は P-1/P-5/P-9 と重なる。実効件数は主役の11件より少ない。
- 一方で主役は内部矛盾（A-1）と語彙断片化＋上流未結合（A-3）という ERROR 級の構造欠陥を見落としており、検出の網羅性に穴がある。最優先は A-1（層分離を破る要件内矛盾）と A-3（証拠分類の断片化）で、これらは P-8 より実装可能性への影響が直接的である。

---

## 判断役レビュー（claude-opus-4-6）

# 判断役：最終判定

## 主役発見への判定

### P-1（Req 1 AC 5 / 主役：ERROR）→ leave-as-is

**敵対役反論：採用**

「shall not allow」は要件としてテスト可能な禁止文である。出力に「来歴を辿れない成果物が存在しないこと」を検証すれば合否が判定できる。違反時の処置（取り込み口で弾くか、印を付けるか）は設計段階の実装方針であり、要件文に書く内容ではない。敵対役の「EARS 形式の正当な制約型」という論拠は妥当。

---

### P-2（Req 2 AC 4 / 主役：WARN）→ leave-as-is

**敵対役反論：採用**

AC 4 はべき等性（同じ入力なら同じ出力）を規定したものであり、上流が変化した場合は Req 4 AC 1 の通常経路（評価出力を消費して再生成）が適用される。残る論点は「古いレポートの陳腐化検知」だが、これは設計課題であり、要件としての欠落ではない。

---

### P-3（Req 3 AC 4 と Req 5 AC 1 / 主役：WARN）→ leave-as-is

**敵対役反論：採用**

Req 3 AC 4 は限界追跡文脈の暫定ラベル付け、Req 5 AC 1 は研究精度文脈の成熟度区分であり、目的も想定読者も異なる。「preliminary」という語の表面一致をもって重複とするのは誤り。真に重要なのは敵対役が指摘した A-3（3系統の証拠分類語彙が断片化している構造的問題）であり、そちらで対処する。

---

### P-4（Req 6 / 主役：ERROR）→ should-fix

**敵対役反論：部分採用**

敵対役の「P-5 と同根であり2件計上は水増し」という指摘は妥当であり、P-4 と P-5 を1件に統合する。ただし「Boundary Context の依存宣言で十分」という反論は退ける。Boundary Context は「evidence field naming に依存」と述べるのみで、review-mode vocabulary の正準定義元を指していない。Req 6 の AC に「foundation が定義する正準 review-mode 語彙に従う」旨の1文が必要。

**判断根拠：** 下流 spec が上流の正準語彙定義を明示参照しないと、将来の語彙追加時に乖離が起きる。要件として「どの定義に従うか」を1文述べる負担は小さく、効果は大きい。

---

### P-5（Req 1 AC 2 / 主役：ERROR）→ P-4 に統合（should-fix）

**敵対役反論：部分採用**

具体的フィールド名の列挙は設計段階の仕事であり、要件に書く必要はない。ただし「foundation が定義する provenance フィールド命名規約に準拠する」という結合宣言は要件レベルで妥当。P-4 と同根のため1件として扱う。

---

### P-6（Req 4 AC 3 / 主役：WARN）→ leave-as-is

**敵対役反論：採用**

敵対役の層分析は正確である。foundation Req 6 AC 5 が能動的除外の責務を付与する対象は evaluation と self-improvement であり、paper-interface は挙げられていない。paper-interface は評価出力を消費する層であり、無効化ロジックを上位に押し上げると Req 4 の分離原則に反する。「上書きしない」という受動的姿勢が正しい設計。

---

### P-7（Boundary Context / 主役：WARN）→ leave-as-is

**敵対役反論：採用**

foundation Req 7 は「runtime 動作に必要なプロンプト・スキーマ・テンプレート」と射程を限定しており、論文向け成果物は runtime 資産ではない。主役の枠付けは foundation Req 7 の射程を超えた適用であり、妥当でない。保管場所の曖昧性は A-4 として別途扱う。

---

### P-8（Req 1 / 主役：CRITICAL）→ must-fix（ERROR に降格）

**敵対役反論：部分採用**

「分類体系（仮説・手法主張・定量比較・限界主張）の必須化」は設計レベルの過剰仕様であり、この点で敵対役の反論を採用する。「実装不可能」も言い過ぎであり CRITICAL は退ける。

ただし「claim とは何か」の最小定義の欠如は要件欠陥として有効。Req 1 の Objective は「claims map to concrete evidence sources」と述べるが、mapping 対象の claim が何を指すかが文書内で一切定義されていない。これは Req 1〜3 の全 AC のテスト可能性を損なう。

**判断根拠：** claim は本 spec の中心的ドメイン概念であり、最小定義（1〜2文の用語定義 + 構造の最小期待）が無ければ、設計者が何を mapping すればよいか判断できない。

---

### P-9（Req 1・Req 2 / 主役：ERROR）→ should-fix（縮小）

**敵対役反論：部分採用**

フィールド・形式・バリデーション規則の列挙は設計段階の仕事であり、要件に書くべき内容ではない。この点で敵対役の反論を採用する。

ただし「evaluation からの明示的入力契約の存在を要求する AC」が1つも無い点は要件欠陥である。Boundary Context の「comparison-ready data を受け取る」は testable な requirement ではない。

**判断根拠：** 依存先の出力契約が存在することを前提条件として明示する1文は、要件レベルで必要かつ妥当。

---

### P-10（全 Req / 主役：WARN）→ should-fix（1点に縮小）

**敵対役反論：部分採用**

「証拠が無い」は P-1 の、「来歴が不完全」は P-5/P-9 の再掲であり、二重計上である。独立して新規なのは「同一 claim に矛盾する証拠が複数ある場合」のみ。この1点に絞って should-fix とする。

**判断根拠：** 論文向け成果物において矛盾する証拠の取り扱いは品質に直結し、設計者に方針を示すべき要件である。

---

### P-11（Req 4 AC 5 / 主役：WARN）→ leave-as-is

**敵対役反論：採用**

「explicit and versionable」は要件として十分な制約を述べている。foundation の versioning 体系との統合方法は設計判断であり、要件文が規定する責務ではない。

---

## 敵対役独立発見への判定

### A-1（Req 1 AC 4 vs Req 4 層分離矛盾 / 敵対役：ERROR）→ must-fix

Req 1 AC 4「shall avoid requiring re-interpretation of raw logs **where evaluation outputs already exist**」の条件節は、裏返すと「evaluation outputs が存在しない場合は paper-interface が生ログを直接解釈してよい」と読める。これは Req 4 AC 1「consume outputs from evaluation rather than directly modifying evaluation rules」および Introduction の「paper convenience が runtime rule を逆流的に変えてはならない」に論理的に矛盾する。

**判断根拠：** 要件文内部の論理矛盾であり、設計解釈で解消できる曖昧性ではない。Req 1 AC 4 の条件節を削除するか、「evaluation 出力が存在しない場合は生ログへのアクセスを禁じ、評価プロセスの実行を前提とする」に書き換える必要がある。

---

### A-2（部分生成ポリシー欠落 / 敵対役：WARN）→ should-fix

一部の claim にのみ証拠が対応する状態でレポート生成を実行する場合の方針が無い。P-8（claim 定義欠如）や P-10（証拠欠落の失敗モード）とは区別される、レポート単位の網羅性に関する要件である。

**判断根拠：** 論文向け成果物は主張の網羅性が品質指標になるため、部分カバレッジ時の生成可否と未対応 claim の明示方法は機能要件として必要。

---

### A-3（証拠分類語彙の3系統断片化 / 敵対役：ERROR）→ must-fix

3系統の証拠分類語（Req 1 AC 3「直接/caveat 付き/暫定」、Req 3 AC 2「無効データ除外/部分証拠/方法論的限界」、Req 5「成熟/暫定/探索的」）が重なり合いながら統一されておらず、さらに foundation Req 6 AC 2 が定義する「evidence class」フィールドへの結合が皆無。

**判断根拠：** 3系統が未統一のまま実装に入ると、成果物間で証拠等級の解釈が乖離する。また foundation が用意した正準フィールドに結びつかないため、上下流の整合性が機械的に検証できない。P-3 が表面的に見た1組の語の重複より根本的な構造欠陥。

---

### A-4（Req 2 AC 3「separate」が検証不能 / 敵対役：WARN）→ should-fix

「論文向け成果物を生証拠から分離して保つ」の「分離」に測定基準が無く、合否を機械的に判定できない。

**判断根拠：** テスト可能性は要件の基本品質であり、「分離」の意味（別ディレクトリ・別スキーマ・別名前空間など）を最低1つ示す必要がある。

---

### A-5（Req 6 AC 4 の二値前提 / 敵対役：WARN）→ should-fix

foundation Req 6 AC 6 は「at minimum」と拡張余地を明示的に残しているが、paper-interface Req 6 AC 4 は2モード混在のみを想定した記述になっている。上流が第3モードを追加した場合に paper-interface の AC が前方互換性を失う。

**判断根拠：** 上流が拡張を想定している以上、下流は N 値対応の書き方にすべき。修正は「混在時」を「複数モード混在時」と一般化する程度の軽微な変更で済む。

---

## 集計

| 判定 | 件数 | 番号 |
|------|------|------|
| must-fix | 3 | P-8, A-1, A-3 |
| should-fix | 6 | P-4/P-5（統合）, P-9, P-10（縮小）, A-2, A-4, A-5 |
| leave-as-is | 6 | P-1, P-2, P-3, P-6, P-7, P-11 |

---

## must-fix の帰属別分類

**paper-interface 固有（paper-interface の要件文を修正すれば解決）**
- P-8：claim の最小定義を Introduction または Requirement 1 冒頭に追加
- A-1：Req 1 AC 4 の条件節を修正し、evaluation 出力が存在しない場合の生ログ直接解釈経路を閉じる

**paper-interface 固有 + foundation への確認要請**
- A-3：paper-interface 内の3系統の証拠分類語彙を統一し、foundation の evidence class フィールドに結合する。加えて foundation 側で evidence class フィールドの値域定義の所有者（paper-interface が定義するのか、evaluation が定義するのか）を明示する必要がある

---

## 補足：敵対役の系統的批判への判断

敵対役が述べた「主役は設計レベルの詳細を要件に求める傾向がある」という批判は概ね妥当であり、P-1/P-5/P-9/P-11 の4件を leave-as-is または縮小判定に反映した。一方で敵対役の独立発見 A-1 と A-3 は主役が見落とした構造的欠陥であり、must-fix として採用した。最終的な実効件数（must-fix 3 + should-fix 6 = 対処必要 9件）は、主役の当初 11件から重複除去・設計侵食排除により適正化されている。
