# dual-reviewer-foundation requirements 個別レビュー

## 取得メタデータ

- 実施日：2026-05-13
- 対象：`dual-reviewer-foundation/requirements.md`
- 方式：claude --print --disallowedTools "Read,Write,Edit"（ファイルアクセス技術的遮断）
- 主役：claude-sonnet-4-6
- 敵対役：claude-opus-4-7
- 判断役：claude-opus-4-6
- 通信構造：β 逐次方式（主役 → 敵対役 → 判断役、各役が前段出力を入力として受け取る）

---

## 主役発見（claude-sonnet-4-6）

---
重大さ: CRITICAL
対象箇所: Introduction 本文 / Boundary Context "In Scope" / Requirement 5
説明: Introduction と "In Scope" に明記されたパターンファイル配置規約が、Req 5 で本 spec の責務から除外されており、文書内で矛盾が生じている
根拠: Introduction は「パターンデータソースと用語テンプレートの共通配置規約」を本 spec の担当範囲として列挙し、Boundary Context の In Scope も「初期検出パターン定義ファイル・重大エラーパターン定義ファイルの配置規約」を明示している。一方 Req 5 は「パターン関連の資産配置規約は本 spec の責務から外す」と明言している。後続の実行基盤の実装者が Introduction / In Scope を見てパターン配置を本 spec で定義されるものと誤解し、v2 取得 spec と二重定義を生む可能性がある。
---

---
重大さ: CRITICAL
対象箇所: Req 1 AC 5 / Req 6 AC 2
説明: 実行記録の必須フィールド定義が 2 箇所に存在し、フィールド数と用語が食い違っており、どちらが正規定義か不明
根拠: Req 1 AC 5 は 7 フィールド（プロトコルバージョン・プロンプトバージョン・実行基盤バージョン・対象成果物のハッシュ値・フェーズとプロファイル・実験条件区分・作業承認状態）を列挙する。Req 6 AC 2 は同じ文脈でさらにレビュー区分・実行状態・検証器の判定状態・証拠の種別を加えた 11 フィールドを列挙する。また同一概念に対して Req 1 は "operator sign-off status"、Req 6 は "human sign-off status" と異なる用語を使っている。実行基盤の実装者が Req 1 を正規定義として 7 フィールドを実装し、評価基盤の実装者が Req 6 を正規定義として 11 フィールドを期待した場合、相互運用性が壊れる。
---

---
重大さ: ERROR
対象箇所: Req 3 AC 6
説明: `necessity_judgment`（必要性判定）が依拠する「5 項目の必要性評価構造」の具体的な内容が文書内で一切定義されていない
根拠: AC 6 は「The `necessity_judgment` contract shall support the 5-field necessity structure, final label, recommended action, and optional override reason」と述べるが、"5-field necessity structure" が何を指すかを説明する記述が文書内に存在しない。実装者が独自に 5 項目を定義すれば、自己改善基盤・論文インターフェース基盤とのデータ形式の互換性が失われる。
---

---
重大さ: ERROR
対象箇所: Req 3 AC 7
説明: 「B-1.0-equivalent operation（B-1.0 相当の運用）」が文書内で未定義であり、必須フィールドと将来拡張フィールドの境界を決定できない
根拠: AC 7 は「which fields are mandatory for B-1.0-equivalent operation and which future extension points are intentionally deferred」と要求するが、"B-1.0" という語の定義が本文書のどこにも存在しない。実装者ごとに解釈が異なれば、必須・先送りの分類が実装によって食い違い、バージョン管理が無意味になる。
---

---
重大さ: ERROR
対象箇所: Requirement 4 全般 / Req 4 AC 1
説明: Requirement 4 は「プロンプト配置規約全般」を扱うと宣言しているにもかかわらず、AC が Step C（判定ステップ）のプロンプトのみを対象としており、Step A・Step B のプロンプト配置規約が欠落している
根拠: Objective は「canonical prompt placement and version rules」と言うが、AC 1 は「a canonical in-repo location for the judgment prompt template（判定プロンプトの雛形）」のみを定義する。Step A（一次検出）と Step B（反論レビュー）にもプロンプトが必要であることは Req 1 AC 1 の 4 ステップ定義から明らかだが、これらの配置規約は AC のどこにも現れない。一方 Req 7 AC 1 は「実行に必要なすべてのプロンプト」をリポジトリ内に置くと要求しており、正規配置場所が未定義のまま収容だけ義務付けられる不整合が生じる。
---

---
重大さ: WARN
対象箇所: Req 2 AC 3
説明: 設定情報の必須項目として挙げられる「project language」が、自然言語（日本語・英語など）なのかプログラミング言語なのかを区別できない
根拠: AC 3 は「model identifiers per role, project language, protocol version, and evidence output location fields」を最小設定項目と定めるが、"project language" の意味が文書内で説明されていない。実装者がプログラミング言語と解釈した場合、設定ファイルの項目が意図と異なる内容になる。
---

---
重大さ: WARN
対象箇所: Req 6 AC 3
説明: 無効化マーカーを「元の証拠記録を書き換えずに」付与する具体的な方式が未定義のため、実装が分岐する
根拠: AC 3 は「how invalidation markers are attached to run records without mutating raw evidence」を定義すると要求するが、付与方式（別ファイル・付属ファイル・別項目など）の方向性を示す記述が文書内にない。評価基盤と自己改善基盤が異なる無効化形式を前提に実装されると、無効な実行記録の機械的な除外（Req 6 AC 5 の要件）が機能しなくなる。
---

---
重大さ: WARN
対象箇所: Req 6 AC 6
説明: レビュー区分の語彙に使われる「manual dogfooding（開発者自身による手動動作確認）」が文書内で未定義であり、実装者が語彙を自己解釈する
根拠: AC 6 は「distinguish at minimum manual dogfooding review records from runtime-mediated review records」と要求するが、"manual dogfooding" の操作的な定義が本文書にない。語彙の境界が曖昧なまま定義されると、実行基盤と評価基盤でレビュー区分の値が食い違う。
---

---
重大さ: WARN
対象箇所: Req 6 AC 7 / Boundary Context "Out of scope"
説明: AC 7 が要求する「プロジェクト横断の証拠取り込み」向けの出所フィールド定義と、Out of scope に除外された「外部貢献者データの取り込み」の関係が不明であり、実装範囲を判断できない
根拠: Out of scope は「外部 contributor data intake」を明示的に除外するが、AC 7 は「cross-project evidence intake（プロジェクト横断の証拠取り込み）」のために出所フィールドの定義を求める。両者が同一概念なのか異なる概念なのかが文書内で区別されていない。同一であれば AC 7 が対象外項目の基盤を作ることになり、spec の境界が崩れる。
---

---
重大さ: WARN
対象箇所: Req 7 AC 2
説明: 「steady-state（通常運用状態）」の定義がなく、「通常運用外」を口実にリポジトリ外依存を正当化する実装が許容される余地がある
根拠: AC 2 は「steady-state dependence on repo-external memory files for runtime-critical behavior」を禁止するが、「通常運用外」（例：初期構成時・移行期）の定義が文書内に存在しない。実装者が初期セットアップ期間を「非 steady-state」と定義すれば、その期間の外部依存が許容でき、AC の制約力が実質的に失われる。
---

---
重大さ: INFO
対象箇所: Req 1 AC 3
説明: 「必須の状態遷移名を定義する」と宣言しているが、その名前の候補や形式の制約が文書内に示されておらず、設計フェーズで任意に定義される余地が広い
根拠: AC 3 は「define required state transition names so that logs can refer to the same conceptual stages」と要求するが、名前に対する命名規約も例示も制約も記載がない。4 ステップ（A/B/C/D）のラベルは AC 1 で示されているが、それらをつなぐ遷移の名前の形式は完全に設計側に委ねられており、実装間で名前が揃わないリスクがある。
---

---

## 敵対役レビュー（claude-opus-4-7）

### パート1：主役発見への反論

対象: 主役発見 P-1（Introduction / In scope / Requirement 5 の矛盾）
判断: 反論なし

対象: 主役発見 P-2（Requirement 1 AC 5 と Requirement 6 AC 2 のフィールド食い違い）
判断: 反論あり（部分的）
内容: Requirement 1 AC 5 は「review event を版・対象成果物ハッシュなどに結びつけるための最小メタデータ」と限定しており、Requirement 6 AC 2 は「検証担当者が必要とするフィールド」とより広い範囲を扱う。役割の違いと読み取れるため、フィールド数の差そのものは矛盾と断定し切れない。ただし「operator sign-off status」と「human sign-off status」の用語混在は文書内で和解できず、この点には反論なし。

対象: 主役発見 P-3（Requirement 3 AC 6 の「5 項目の必要性評価構造」未定義）
判断: 反論なし

対象: 主役発見 P-4（Requirement 3 AC 7 の「B-1.0 相当の運用」未定義）
判断: 反論なし

対象: 主役発見 P-5（Requirement 4 が Step C プロンプトのみで Step A・B のプロンプト配置規約が欠落）
判断: 反論あり（部分的）
内容: Requirement 4 AC 4 は「プロンプト配置規則を下流の実行コードが相対パスのみで参照できるよう定める」と一般形で書かれており、AC 3 と AC 5 も複数形の「プロンプトテンプレート群」を対象としている。したがって配置規約自体は Step C 限定とは読めない。ただし AC 1 が判定プロンプトのみを名指しで要求するのは事実であり、Step A・Step B のプロンプトをどう扱うかは明示されていない。AC 1 単体の欠落点は反論不能。

対象: 主役発見 P-6（Requirement 2 AC 3 の「project language」が自然言語かプログラミング言語か不明）
判断: 反論あり
内容: Requirement 3 AC 8 が「スキーマの項目ラベルは英語とする」と述べており、本文書において「language」が自然言語（日本語と英語）を指す文脈であることが他箇所から読み取れる。したがって「project language」はプロジェクトで用いる自然言語と解釈する根拠が文書内に存在する。

対象: 主役発見 P-7（Requirement 6 AC 3 の無効化マーカー付与方式が未定義）
判断: 反論あり（部分的）
内容: AC 3 は「生の証跡を改変せずに記録に付与する」という制約を与えており、本 spec が契約レベルに留まる以上、具体的なマーカー形式は runtime 担当という整理が文書全体の方針と整合する。実装が分岐する不確実性は残るが、「未定義」と単純化するのは過剰。

対象: 主役発見 P-8（Requirement 6 AC 6 の「manual dogfooding」未定義）
判断: 反論なし

対象: 主役発見 P-9（Requirement 6 AC 7 と Out of scope の関係不明）
判断: 反論あり（部分的）
内容: Out of scope は「外部 contributor data intake」（外部の貢献者からの証跡受け入れ）と書かれ、AC 7 は「ソースリポジトリ識別と版識別」を求める。前者は受け入れ運用、後者は記録項目という別レイヤーと読み取れるため、文書内の語彙レベルでは衝突を主張し切れない。ただし両者の境界を文書がはっきり書き分けていない不明瞭さは残る。

対象: 主役発見 P-10（Requirement 7 AC 2 の「steady-state」未定義）
判断: 反論あり
内容: AC 3 が「環境レベルの設定は、設定として明示的に取り扱われ、かつ実行記録に残される場合にのみ許容される」と例外条件を厳格に定めている。したがって非 steady-state を口実に外部依存を持ち込む抜け道は AC 3 で塞がれており、AC 2 単独の懸念は緩和される。

対象: 主役発見 P-11（Requirement 1 AC 3 の必須状態遷移名の命名規約欠落）
判断: 反論なし

### パート2：敵対役独立発見

---
重大さ: CRITICAL
対象箇所: Req 3 AC 1 と AC 4〜6 の整合
説明: 本 spec が提供すると宣言する 5 つのスキーマのうち、`impact_score` と `failure_observation` の契約内容が AC から欠落している
根拠: AC 1 は `review_case` / `finding` / `impact_score` / `failure_observation` / `necessity_judgment` の 5 ファイルを宣言するが、続く AC 4〜6 は review_case / finding / necessity_judgment のみ契約を述べ、impact_score と failure_observation には触れない。
---

---
重大さ: CRITICAL
対象箇所: Boundary Context "In scope" 第 5 項目 / Req 5
説明: In scope にファイル名つきで「pattern files の配置規約」を残したまま Req 5 が責務を全削除（P-1 と同根だが In scope の直接矛盾として独立した指摘）
根拠: Boundary Context は「pattern files (`seed_patterns.yaml` / `fatal_patterns.yaml`) の配置規約」を In scope に列挙するが、Requirement 5 は「パターン関連の資産配置規約は本 spec の責務から外す」と書く。
---

---
重大さ: ERROR
対象箇所: Req 1 AC 1 の Step D
説明: 4 ステップ構成のうち Step D（統合）の役割定義が他の AC で一切補足されていない
根拠: AC 1 で Step A〜D を canonical pipeline と宣言するが、AC 4 は Step B と Step C の役割境界を明示するのみで Step D の役割境界に触れない。runtime 実装者は Step D が何を統合するのか判定できない。
---

---
重大さ: ERROR
対象箇所: Req 3 AC 5 の severity
説明: finding 契約が severity を保持すると規定するが severity の語彙が文書内に存在しない
根拠: AC 5 は severity を含むと述べるが、語彙の規定がない。Requirement 6 AC 6 が review-mode の正規語彙を明示的に要件化しているのと対照的。
---

---
重大さ: ERROR
対象箇所: Req 6 AC 2 の run status / validator status / evidence class
説明: AC 2 が必須と宣言する 11 フィールドのうち run status / validator status / evidence class の語彙が未指定
根拠: AC 6 は review-mode の正規語彙、AC 7 は provenance の正規項目名を扱うが、run status / validator status / evidence class の語彙は文書内に規定がない。
---

---
重大さ: WARN
対象箇所: Req 6 AC 4 と AC 5 の整合
説明: メタデータ欠落（検証失敗）と無効化マーカー付与の扱いの境界が文書内で線引きされていない
根拠: AC 4 は「missing required metadata causes validator failure」、AC 5 は「excluding invalid runs by metadata alone」とそれぞれ書く。欠落と無効化マーカー付与の双方が「無効な実行」と扱われ得るが、両者を区別する語彙が文書内にない。
---

---
重大さ: WARN
対象箇所: Introduction 末尾
説明: 入力として参照される `intent/` と `operations/` 上位文書の位置・版・参照方法が文書内で特定できない
根拠: Introduction は「本 spec は `intent/` と `operations/` の上位文書を入力とし」と述べるが、相対パスも版数も示されていない。
---

---
重大さ: WARN
対象箇所: Req 4 AC 5
説明: プロンプトの保存形式に制約がなく「通常のリポジトリ差分履歴で検知できる」要請が形式によって成立しない可能性がある
根拠: AC 5 は「prompt content updates be detectable through ordinary repository diff history」と述べるが、保存形式の制約が文書内にない。
---

---
重大さ: INFO
対象箇所: Req 2 AC 5 と Req 7 AC 1
説明: 「設定とテンプレートをリポジトリ内に置く」要請が Req 2 と Req 7 の双方に存在し管轄が曖昧
根拠: Requirement 2 AC 5 は「terminology and config templates as repo-contained files」、Requirement 7 AC 1 は templates を含む総論要求と重複する。
---

---

## 判断役レビュー（claude-opus-4-6）

### 主役発見（11 件）

### 発見 P-1（主役）
対象箇所: Introduction / Boundary Context "In Scope" / Requirement 5
重大さ: CRITICAL
説明: パターンファイル配置規約が Introduction と In Scope に残存するが Req 5 で責務から除外されており文書内矛盾
敵対役反論: なし
判断: **must-fix**
判断根拠: Introduction は「pattern data source … の共通配置規約」を本 spec の責務と明言し、In Scope は `seed_patterns.yaml` / `fatal_patterns.yaml` をファイル名つきで列挙している。一方 Req 5 は「本 spec の責務から外す」と明記。これは同一文書内の直接矛盾であり、実装者がどちらに従うか判断できない。Req 5 の削除意図を信頼するなら、Introduction と In Scope からパターン配置規約の記述を除去する必要がある。

### 発見 P-2（主役）
対象箇所: Req 1 AC 5 / Req 6 AC 2
重大さ: CRITICAL
説明: 実行記録必須フィールド定義が 2 箇所で食い違い、"operator sign-off status" と "human sign-off status" の用語混在
敵対役反論: あり（部分的）—フィールド数の差は役割の違いで説明できるが、用語混在は反論不能
判断: **must-fix**
判断根拠: 敵対役の反論を踏まえても、同じ概念を指す項目に異なる名前を使っている点は解消されない。foundation spec は下流 spec 共通の用語を定義する役割を担うため、ここが曖昧だと全下流に混乱が波及する。どちらかに統一するか、異なる概念であれば違いを明記する必要がある。

### 発見 P-3（主役）
対象箇所: Req 3 AC 6
重大さ: ERROR
説明: necessity_judgment の「5 項目の必要性評価構造」の具体的内容が文書内で未定義
敵対役反論: なし
判断: **must-fix**
判断根拠: AC 6 は「5-field necessity structure」を名指しで必須としているが、その 5 項目が何であるかは文書内のどこにも記載がない。下流 spec がこの契約に依存してスキーマを実装する以上、少なくとも 5 項目の列挙が必要。数字だけ書いて中身がないのは契約として機能しない。

### 発見 P-4（主役）
対象箇所: Req 3 AC 7
重大さ: ERROR
説明: 「B-1.0-equivalent operation」が文書内で未定義のため必須・先送りフィールドの境界を決定できない
敵対役反論: なし
判断: **should-fix**
判断根拠: AC 7 はフィールドの必須/先送りを「B-1.0 相当の動作」を基準に線引きする設計だが、B-1.0 の定義が本文書にない。ただし、これはプロジェクト全体の rebuild 文脈に既出の概念であり、簡潔な定義か上位文書への明示的参照を 1 行加えれば解決する。文書の構造を壊す問題ではないため should-fix とする。

### 発見 P-5（主役）
対象箇所: Req 4 全般 / Req 4 AC 1
重大さ: ERROR
説明: Req 4 は配置規約全般を扱うと宣言するが AC は Step C プロンプトのみ名指し、Step A・B の配置規約が欠落
敵対役反論: あり（部分的）—AC 3/4/5 は複数形で書かれているが、AC 1 の欠落は反論不能
判断: **must-fix**
判断根拠: 敵対役の反論を踏まえても、AC 1 が「judgment prompt template」だけを名指ししている以上、Step A・Step B のプロンプトに正規の配置場所が契約上存在しない。foundation spec として全ステップのプロンプトをカバーするか、Step C のみに限定するなら Objective の文言を修正する必要がある。

### 発見 P-6（主役）
対象箇所: Req 2 AC 3
重大さ: WARN
説明: 「project language」が自然言語かプログラミング言語か区別できない
敵対役反論: あり—Req 3 AC 8 の文脈から自然言語と読み取れる
判断: **should-fix**
判断根拠: 敵対役の反論は妥当で、文脈から自然言語と推測可能。ただし foundation spec は他 spec の「定義の土台」であり、推測に頼る書き方は好ましくない。「project language（レビュー対象の記述自然言語）」のように 1 語の補足を加えれば解消する軽微な修正。

### 発見 P-7（主役）
対象箇所: Req 6 AC 3
重大さ: WARN
説明: 無効化マーカー付与の具体的方式が未定義のため実装が分岐する
敵対役反論: あり（部分的）—制約は存在するが完全解決にはならない
判断: **leave-as-is**
判断根拠: AC 3 は「生の証拠を変更せずにマーカーを付与する」という制約を明示しており、要件としての意図は伝わる。具体的な付与方式は設計フェーズで決定すべき事項であり、要件段階でこれ以上詳細化する必要はない。

### 発見 P-8（主役）
対象箇所: Req 6 AC 6
重大さ: WARN
説明: "manual dogfooding" が文書内で未定義のため実装者が語彙を自己解釈する
敵対役反論: なし
判断: **should-fix**
判断根拠: AC 6 は「正規の review-mode 語彙を定義せよ」と要求しつつ、その最低限の区別として「manual dogfooding」を挙げている。しかしこの用語自体が定義されていないため、何を区別する語彙なのかが曖昧になる。用語の簡潔な定義を付記すべき。

### 発見 P-9（主役）
対象箇所: Req 6 AC 7 / Out of scope
重大さ: WARN
説明: "cross-project evidence intake" と "外部 contributor data intake" の関係が不明で AC 7 が対象外の基盤を作る可能性
敵対役反論: あり（部分的）—別レイヤーと読めるが文書が書き分けていない
判断: **should-fix**
判断根拠: AC 7 は出所を識別するフィールド名の定義だけを求めており、取り込み処理自体は求めていない。ただし Out of scope の「外部 contributor data intake」との境界が明文化されていないため、読者が混乱する。AC 7 が対象外処理の基盤を侵食しているのではなく、メタデータ識別と処理実装の違いである旨を一文補足すれば解消する。

### 発見 P-10（主役）
対象箇所: Req 7 AC 2
重大さ: WARN
説明: 「steady-state」未定義で非 steady-state を口実に repo 外依存を正当化する余地がある
敵対役反論: あり—AC 3 で例外条件が厳格に閉じられているため懸念は緩和される
判断: **leave-as-is**
判断根拠: AC 3 は repo 外を許容する条件を「明示的に config でモデル化し、実行記録に記録する場合のみ」と厳格に制限している。この制約があれば「steady-state ではないから」という口実での抜け穴は実質的に閉じられる。追加定義は不要。

### 発見 P-11（主役）
対象箇所: Req 1 AC 3
重大さ: INFO
説明: 「必須の状態遷移名」の命名規約・例示・制約が文書内に示されていない
敵対役反論: なし
判断: **leave-as-is**
判断根拠: AC 3 は「必須の状態遷移名を定義せよ」という契約義務を課しており、要件としての意図は明確。具体的な命名規約や遷移名の列挙は設計フェーズの責務であり、要件段階で規約を決める必要はない。

---

### 敵対役独立発見（9 件）

### 発見 A-1（敵対役）
対象箇所: Req 3 AC 1 と AC 4〜6 の整合
重大さ: CRITICAL
説明: 宣言した 5 スキーマのうち impact_score と failure_observation の契約内容が AC から欠落
判断: **must-fix**
判断根拠: AC 1 は 5 つのスキーマファイルを明示的に列挙しているが、AC 4〜6 は review_case / finding / necessity_judgment の 3 つしかカバーしていない。`impact_score` と `failure_observation` は名前だけ宣言されて契約内容が一切ない。foundation spec としてスキーマを提供するなら、全スキーマに最低限の契約を定義するか、あるいは AC 1 のリストから外して後続 spec に委ねるかを明確にする必要がある。

### 発見 A-2（敵対役）
対象箇所: Boundary Context "In scope" 第 5 項目 / Req 5
重大さ: CRITICAL
説明: In scope にファイル名つきでパターン配置規約を残したまま Req 5 が責務を全削除
判断: **must-fix**
判断根拠: P-1 と同根の問題。In Scope が `seed_patterns.yaml` / `fatal_patterns.yaml` を具体的なファイル名つきで列挙しているにもかかわらず、Req 5 がこれを責務から除外している。P-1 の修正（Introduction + In Scope からのパターン関連記述の除去）が行われれば本件も同時に解消される。修正対象が重複するため P-1 と一括で対応すべき。

### 発見 A-3（敵対役）
対象箇所: Req 1 AC 1 の Step D
重大さ: ERROR
説明: Step D（統合）の役割定義が他の AC で一切補足されていない
判断: **should-fix**
判断根拠: AC 1 は 4 ステップのパイプラインを定義し、AC 4 は Step B と Step C の差異を明記している。しかし Step D（integration）は名前だけで、何を統合するのか、出力は何かが一切ない。最低限の目的を 1 文加えるべき。

### 発見 A-4（敵対役）
対象箇所: Req 3 AC 5 の severity
重大さ: ERROR
説明: finding 契約が severity を保持すると規定するが severity の語彙が文書内に存在しない
判断: **should-fix**
判断根拠: AC 5 は `finding` スキーマに severity フィールドを求めているが、使用可能な severity 値の列挙がない。foundation spec はスキーマの契約を定義する場であり、語彙の列挙もしくは「設計フェーズで語彙を確定する」旨の明示があるべき。ただし語彙の具体的内容は設計で決定可能なため must-fix ではなく should-fix とする。

### 発見 A-5（敵対役）
対象箇所: Req 6 AC 2 の run status / validator status / evidence class
重大さ: ERROR
説明: AC 2 が必須と宣言する 11 フィールドのうち run status / validator status / evidence class の語彙が未指定
判断: **should-fix**
判断根拠: A-4 と同様の構造。要件段階ではフィールドの存在義務を課すことが主目的であり、語彙の確定は設計で行える。「語彙は設計フェーズで定義する」旨の補足、あるいは最低限の例示を加えることが望ましい。

### 発見 A-6（敵対役）
対象箇所: Req 6 AC 4 と AC 5 の整合
重大さ: WARN
説明: メタデータ欠落（検証失敗）と無効化マーカー付与の扱いの境界が文書内で線引きされていない
判断: **leave-as-is**
判断根拠: AC 4 は「必須メタデータの欠落は検証失敗を引き起こす」と規定し、AC 3 / AC 5 は「無効化マーカーによる事後排除」を規定している。前者は入口での遮断、後者は事後の除外であり、役割は異なる。この区別は設計フェーズで具体化すれば十分であり、要件段階で境界線を引く必要はない。

### 発見 A-7（敵対役）
対象箇所: Introduction 末尾
重大さ: WARN
説明: 入力として参照される intent/ と operations/ 上位文書の位置・版・参照方法が文書内で特定できない
判断: **should-fix**
判断根拠: Introduction は「intent/ と operations/ の上位文書を入力とする」と明言しているが、これらの文書がどのパスにあるか、どの版を参照するかの手がかりがない。foundation spec は再現性を重視する文書であり、入力文書の参照先が不明なのは読者に不親切。相対パスか正式名称を補記すべき。

### 発見 A-8（敵対役）
対象箇所: Req 4 AC 5
重大さ: WARN
説明: プロンプト保存形式に制約がなく diff で検知できるとの要請が形式によって成立しない可能性がある
判断: **leave-as-is**
判断根拠: AC 5 は「通常のリポジトリ差分履歴で変更を検知できること」を要求しており、これは暗黙にテキストベースの保存形式を前提としている。バイナリ形式のプロンプトテンプレートは現実的にありえず、この文脈で形式制約を明記する必要性は低い。

### 発見 A-9（敵対役）
対象箇所: Req 2 AC 5 と Req 7 AC 1
重大さ: INFO
説明: 「設定とテンプレートをリポジトリ内に置く」要請が Req 2 と Req 7 の双方に存在し管轄が曖昧
判断: **leave-as-is**
判断根拠: Req 7 は「全 foundation 資産のリポジトリ内配置」という包括的な原則を定め、Req 2 AC 5 はその原則を config/template という具体的対象に適用している。包括原則と個別適用の関係であり、矛盾や管轄の衝突ではない。

---

## 集計

- **must-fix：6 件**（P-1, P-2, P-3, P-5, A-1, A-2）
  - うち P-1 と A-2 は同根のため修正作業は 1 回で済む（実質 5 件）
- **should-fix：8 件**（P-4, P-6, P-8, P-9, A-3, A-4, A-5, A-7）
- **leave-as-is：6 件**（P-7, P-10, P-11, A-6, A-8, A-9）

must-fix が 6 件（実質 5 件）あるため、要件フェーズをこのまま先に進めるべきではない。
