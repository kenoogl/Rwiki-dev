# Requirements Local Review — dual-reviewer-runtime

- 実施日: 2026-05-13
- 方式: β 逐次 3 役（主役 Sonnet 4.6 → 敵対役 Opus 4.7 → 判断役 Opus 4.6）
- 入力: foundation requirements.md（上流）+ runtime requirements.md（対象）

---

## 主役（Sonnet 4.6）発見 — 10 件

### P-1: CRITICAL — foundation Req 7 AC1 / Req 5 削除済み

**対象箇所**: foundation Req 7 AC1 / Req 5 削除済み
**説明**: Req 7 AC1 は "pattern assets" を repo 格納義務の対象に含めるが、削除済み Req 5 には「パターン関連の資産配置規約は本 spec の責務から外す」と明言されている。同一文書内で pattern assets の責務帰属が真逆。
**根拠**: 実装者が従うべき指示を一意に決められない。

**判断: must-fix**
→ Req 7 AC1 の列挙から "pattern assets" を削除するか、Req 5 削除注と整合させる。

---

### P-2: CRITICAL — foundation Req 1 AC1 / AC4 / runtime Req 1 AC1（Step D 定義欠落）

**対象箇所**: foundation Req 1 AC1, AC4 / runtime Req 1 AC1
**説明**: foundation は 4-step pipeline（A/B/C/D）を宣言しているが、Step D "integration" の目的・出力形式・前後条件が foundation に一切存在しない。
**根拠**: runtime Req 1 AC1 が 4-step モデルを import するため、上流の定義欠落が下流の実装曖昧性になる。

**判断: must-fix**
→ foundation Req 1 に Step D の最小 contract を定義する。

---

### P-3: CRITICAL — foundation Boundary Context / Req 6 AC7（外部 contributor intake vs cross-project evidence）

**対象箇所**: foundation Boundary Context Out of scope / Req 6 AC7
**説明**: Out of scope に「外部 contributor data intake」があるが、Req 6 AC7 は「cross-project evidence intake」向けの provenance フィールドを必須化している。同概念かどうかが未区別。
**根拠**: 同義なら Req 6 AC7 は out-of-scope 要件を含む。別概念なら区別の明示が必要。

**判断: should-fix**（敵対役反論採用で CRITICAL → should-fix）
→ Boundary Context または AC7 に「フィールド定義のみであり取り込み処理そのものではない」旨を補記。

---

### P-4: ERROR — foundation Req 1 AC5 / Req 6 AC2（必須 run metadata の SSoT 二重定義）

**対象箇所**: foundation Req 1 AC5 / Req 6 AC2
**説明**: Req 1 AC5 は 7 項目、Req 6 AC2 は 11 項目を列挙。2 つのリストは内容が異なり、どちらが規範的 SSoT か不明。
**根拠**: validator 実装者と runtime 実装者が異なるフィールドリストを参照する可能性がある。

**判断: must-fix**（敵対役反論を棄却）
→ 包含関係を文書に明示する（例: Req 6 AC2 は Req 1 AC5 を拡張する上位集合である）。

---

### P-5: ERROR — foundation Req 3 AC8 / runtime Req 4（failure_observation emit 義務欠落）

**対象箇所**: foundation Req 3 AC8 / runtime Req 4 AC1-6
**説明**: foundation が failure_observation スキーマを定義しているが、runtime Req 4 の AC に emit 義務が記述されていない。
**根拠**: スキーマは定義されるが runtime が emit しなければ dead artifact になる。

**判断: must-fix**
→ Runtime Req 4 に failure_observation の emit 条件を追加する。

---

### P-6: ERROR — foundation Req 6 AC2（evidence class 値域未定義）

**対象箇所**: foundation Req 6 AC2
**説明**: evidence class が必須フィールドとして列挙されているが、取りうる値・意味が定義されていない。
**根拠**: validator が何を検証すべきか決まらない。

**判断: should-fix**
→ 最低限の初期値域を列挙するか「runtime spec で定義する」旨の委譲先を明記する。

---

### P-7: WARN — foundation Req 3 AC5 / AC7（finding.severity と impact_score severity axis の関係未定義）

**対象箇所**: foundation Req 3 AC5 / AC7
**説明**: finding schema の severity（AC5）と impact_score 内の finding severity axis（AC7）の関係（参照か・冗長か・どちらが規範か）が定義されていない。
**根拠**: 同一 run で 2 つの severity 値が異なり得る。

**判断: should-fix**
→ 一文の関係定義を追記する。

---

### P-8: WARN — foundation Req 3 AC6（uncertainty フィールド意味未定義）

**対象箇所**: foundation Req 3 AC6
**説明**: necessity_judgment の 5-field 構造に含まれる uncertainty フィールドが「何に対する不確実性か」を定義していない。
**根拠**: 同じ review run を 2 人の実装者が解釈した場合に異なる値が記録される可能性がある。

**判断: should-fix**
→ 一文の定義を追加する。

---

### P-9: WARN — foundation Req 3 AC9（B-1.0-equivalent operation 用語未定義）

**対象箇所**: foundation Req 3 AC9
**説明**: 「B-1.0-equivalent operation」という用語が文書内で未定義のまま使用されている。
**根拠**: 新規実装者が判断基準を持てない。

**判断: should-fix**
→ 用語定義または旧 repo Phase B-1.0 release を指す旨の注記を入れる。

---

### P-10: INFO — 削除済み要件の外部参照（追跡性）

**対象箇所**: foundation Req 5 削除済み / runtime Req 10 削除済み
**説明**: 削除された両要件が v2-acquisition spec への外部参照を含んでいる。参照先が動いた場合に検出が困難。

**判断: leave-as-is**（敵対役反論を採用）
→ 削除注記は追跡性強化の適切な慣行。修正不要。

---

## 敵対役（Opus 4.7）— 反論 3 件 + 独立発見 12 件

### 反論 R-1: P-3 の CRITICAL は過剰

**対象**: P-3（外部 contributor intake vs cross-project evidence）
**反論内容**: provenance フィールド命名と data intake 処理は別関心事。INFO 相当が妥当。

**判断: should-fix（反論部分採用）**

---

### 反論 R-2: P-4 の ERROR は過剰、意図的な層別構造

**対象**: P-4（Req 1 AC5 vs Req 6 AC2）
**反論内容**: 意図的な層別構造（state machine 最小集合 vs validator 拡張集合）と読める。INFO 相当が妥当。

**判断: must-fix（反論を棄却）**
→ 意図的であっても包含関係が文書上にない以上、実装者の推測に依存してはならない。

---

### 反論 R-3: P-10 の INFO は不要（削除済み要件の外部参照）

**対象**: P-10（削除済み要件の外部参照）
**反論内容**: 削除理由と移行先を残すことは追跡性強化であり問題なし。

**判断: leave-as-is（反論を採用）**

---

### 独立発見 A-1: CRITICAL — foundation Req 1 AC4（Step B forced-divergence 振る舞い規約未定義）

**対象箇所**: foundation Req 1 AC4
**説明**: AC4 は Step B の forced-divergence と Step C の necessity judgment を分離すると宣言しているが、forced-divergence の振る舞い規約（主役と異なる結論を必ず提示する義務があるのかなど）が定義されていない。
**根拠**: 治療比較の妥当性に直結する。

**判断: must-fix**
→ foundation Req 1 AC4 に forced-divergence の最低限の振る舞い規約を追加する。

---

### 独立発見 A-2: CRITICAL — foundation Req 1 AC5 / runtime Req 8 AC1（phase/profile 語彙が foundation に不在）

**対象箇所**: foundation Req 1 AC5 / runtime Req 8 AC1
**説明**: foundation が phase/profile を必須メタデータに含めているが、取りうる値の集合が foundation に定義されていない。Runtime Req 8 AC1 で初めて列挙される（語彙所有権の流出）。
**根拠**: 複数 runtime 実装間で値が揺れる可能性がある。

**判断: must-fix**
→ foundation に最低限の語彙定義を置くか、語彙所有権を runtime に明示的に委譲する記述が必要。

---

### 独立発見 A-3: CRITICAL — foundation Req 1 AC5 / Req 6 AC2 / runtime Req 2（treatment 語彙が foundation に不在）

**対象箇所**: foundation Req 1 AC5, Req 6 AC2 / runtime Req 2 AC2
**説明**: foundation が treatment を必須メタデータに含めているが single/dual/dual+judgment の語彙が foundation に不在。Runtime Req 2 AC2 で初出する。
**根拠**: 異なる runtime が異なる treatment 名を採用すると、評価 spec の比較分析が機械的に崩壊する。

**判断: must-fix**
→ A-2 と同じ対処が必要。

---

### 独立発見 A-4: ERROR — foundation Req 2 AC3 / Req 7 AC3（環境設定の許容条件と最小 config contract の不整合）

**対象箇所**: foundation Req 2 AC3 / Req 7 AC3
**説明**: Req 7 AC3 が環境設定を「config に明示的にモデル化された場合のみ許容」と定めているが、Req 2 AC3 の最小 config contract に環境設定を表す項目がない。
**根拠**: 許容条件を定義しているが、それを表現する場所がない。

**判断: should-fix**
→ config contract に「環境由来の項目を格納するための拡張点」を明記する。

---

### 独立発見 A-5: ERROR — foundation Req 6 AC3 / runtime Req 6 AC3（invalidation marker の保存場所・形式・付与方式未定義）

**対象箇所**: foundation Req 6 AC3 / runtime Req 6 AC3
**説明**: raw evidence を変更せずに invalidation marker を付与すると要求しているが、標識の保存場所・形式・付与方式の contract が定義されていない。
**根拠**: 無効化判定の機械化が不可能になる。

**判断: should-fix**
→ foundation に付与方式の最低限の制約（例: raw evidence ファイルとは別の場所に格納する）を明示する。

---

### 独立発見 A-6: ERROR — runtime Req 5 AC4 / Req 6 AC1（sign-off と validator の前後関係未定義）

**対象箇所**: runtime Req 5 AC4 / Req 6 AC1
**説明**: Req 5 AC4 は「明示的な sign-off の前に run を closed として扱ってはならない」と要求し、Req 6 AC1 は「validator を run close 時に呼び出す」と要求しているが、両者の前後関係が未定義。
**根拠**: sign-off が先か validator が先かによって「人間承認済みだが無効」や「人間が見る前に無効化」という状態が生まれる。

**判断: must-fix**
→ runtime Req 5 または Req 6 に sign-off → validator → close の順序を明記する。

---

### 独立発見 A-7: ERROR — foundation Req 3 AC8 / runtime Req 4（failure_observation emit 義務の補足）

**対象箇所**: foundation Req 3 AC8 / runtime Req 4
**説明**: P-5 と同一の根本問題。Runtime Req 4 AC1 が review_case スキーマのみを指している場合、failure_observation を別 AC として明示する必要がある。

**判断: must-fix（P-5 に統合）**

---

### 独立発見 A-8: WARN — foundation 境界文脈 / Req 4 / runtime Req 8 AC6（prompt override 概念の未定義）

**対象箇所**: foundation 境界文脈 Out of scope / Req 4 / runtime Req 8 AC6
**説明**: foundation が「prompt override の選択順序」を out-of-scope に宣言し、runtime Req 8 AC6 が「prompt override resolution policy」を所有すると述べているが、prompt override という概念自体が両 spec で定義されていない。

**判断: should-fix**
→ foundation に一文の概念定義を置く。

---

### 独立発見 A-9: WARN — foundation Req 2 AC3（evidence output location と repo-contained 原則の矛盾可能性）

**対象箇所**: foundation Req 2 AC3
**説明**: config に evidence output location フィールドがあるが、Req 7 の repo-contained 原則との関係が定義されていない。出力先を repo 外に向けられるなら repo-contained 原則と整合性が崩れる可能性がある。

**判断: leave-as-is**
→ Req 7 の repo-contained 原則は runtime 動作に必要な入力資産に適用されるものであり、review 実行の出力先（evidence output location）は性質が異なる。矛盾しない。

---

### 独立発見 A-10: WARN — foundation Req 3 AC6（necessity_judgment の recommended action 語彙未定義）

**対象箇所**: foundation Req 3 AC6
**説明**: necessity_judgment の recommended action フィールドの値語彙（取りうる値の集合）が未定義で機械集計が行えない。P-8 の uncertainty と同じ構造の問題。

**判断: should-fix**
→ 推奨対応として取りうる値（例: accept/reject/defer/modify）を定義する。

---

### 独立発見 A-11: WARN — runtime Req 9 / foundation 全体（portable evidence bundle の構造規約未定義）

**対象箇所**: runtime Req 9 / foundation 全体
**説明**: runtime Req 9 は bundle export を要求しているが、bundle の構造規約（必須ファイル・メタデータ記述・bundle hash）が foundation にも runtime にも定義されていない。

**判断: should-fix**
→ foundation の schema 5 種に「bundle manifest」相当を追加するか、bundle の最低限の取り決めを foundation 側に置く判断が必要。

---

### 独立発見 A-12: WARN — runtime Req 1 AC4 / Req 2 AC4（omitted / skip / failed の三状態の関係未定義）

**対象箇所**: runtime Req 1 AC4 / Req 2 AC4
**説明**: Req 1 AC4 が "omitted steps" と "failed steps" を区別し、Req 2 AC4 が "skip markers" を発行すると述べているが、omitted と skip が同義なのか別概念なのかが不明。三状態の定義と関係が不明。

**判断: should-fix**
→ 用語を統一するか、三状態の定義と関係を一箇所にまとめる。

---

## 集計（判断役 Opus 4.6）

- **must-fix: 9 件** — P-1, P-2, P-4, P-5 / A-1, A-2, A-3, A-6 / A-7（P-5 に統合）
- **should-fix: 12 件** — P-3, P-6, P-7, P-8, P-9 / R-1（部分採用） / A-4, A-5, A-8, A-10, A-11, A-12
- **leave-as-is: 4 件** — P-10 / R-3 / A-9

### must-fix の帰属別分類

foundation 修正が必要な must-fix（7 件）:
- P-1: foundation Req 7 AC1 から "pattern assets" 削除
- P-2: foundation Req 1 に Step D contract 定義
- P-4: foundation Req 1 AC5 / Req 6 AC2 の包含関係明示
- A-1: foundation Req 1 AC4 に Step B forced-divergence 振る舞い規約追加
- A-2: foundation に phase/profile 語彙定義
- A-3: foundation に treatment 語彙定義

runtime 修正が必要な must-fix（2 件）:
- P-5: runtime Req 4 に failure_observation emit 義務追加
- A-6: runtime Req 5 または Req 6 に sign-off/validator 順序明記
