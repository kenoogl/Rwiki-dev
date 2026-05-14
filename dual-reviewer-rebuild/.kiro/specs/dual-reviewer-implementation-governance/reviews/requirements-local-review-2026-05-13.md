# Requirements Local Review — dual-reviewer-implementation-governance

- 実施日: 2026-05-13
- 方式: β 逐次 3 役（主役 Sonnet 4.6 → 敵対役 Opus 4.7 → 判断役 Opus 4.6）
- 入力: foundation requirements.md（上流）+ implementation-governance requirements.md（対象）

---

## 主役（Sonnet 4.6）発見 — 13 件

### P-1: CRITICAL — foundation Req 1 AC1 ↔ Req 4 AC1（Step D にプロンプト配置規約がない）

**対象箇所**: foundation Req 1 AC1 / Req 4 AC1
**説明**: 4-step pipeline の Step D が foundation で定義されているが、Req 4 AC1 は Steps A/B/C のみへのプロンプト配置を要求し Step D を除外している。
**根拠**: Step D が LLM プロンプトを不要とする設計なら Req 1 の定義に明記すべき。

**判断: should-fix**（敵対役反論を採用し CRITICAL → should-fix）
→ Step D がプロンプトを必要としないなら、その旨を Req 1 または Req 4 に明記する。

---

### P-2: CRITICAL — foundation Req 1 AC5 ↔ Req 6 AC2（必須 run metadata フィールドの二重定義）

**対象箇所**: foundation Req 1 AC5 / Req 6 AC2
**説明**: Req 1 AC5 は 7 項目、Req 6 AC2 は 11 項目を列挙。どちらが正規契約か判断できない。
**根拠**: runtime 実装者と validation 実装者が別の AC を参照した場合、フィールドの欠落または過剰記録が発生する。

**判断: must-fix**
→ Req 6 AC2 が Req 1 AC5 を包含する上位集合であることを明示する。

---

### P-3: CRITICAL — foundation Req 3 AC5 ↔ governance Req 2 AC2（finding schema の互換性）

**対象箇所**: foundation Req 3 AC5 / governance Req 2 AC2
**説明**: 両者で finding のフィールドセットが異なる（重複は severity のみ）。
**根拠**: foundation の "shared schema set" の SSoT としての位置付けと矛盾するように見える。

**判断: should-fix**（敵対役反論を採用し CRITICAL → should-fix）
→ foundation AC5 は finding 単体スキーマ、governance AC2 は conformance review 文書全体の必須項目リスト（finding スキーマを参照する側）という包含関係を補記する。

---

### P-4: ERROR — foundation Req 7 AC1 ↔ Req 5 削除済み（pattern assets の残留参照）

**対象箇所**: foundation Req 7 AC1 / Req 5 削除済み
**説明**: Req 5 削除により pattern assets はスコープ外になったが、Req 7 AC1 に "pattern assets" が残留している。
**根拠**: 実装者が存在しない資産を前提にする可能性がある。

**判断: must-fix**
→ foundation Req 7 AC1 から "pattern assets" を削除する。

---

### P-5: ERROR — governance Req 4 AC1（implementation-signal-register が未定義のまま参照）

**対象箇所**: governance Req 4 AC1
**説明**: `implementation-signal-register` が境界文脈の Adjacent expectations に列挙されておらず、契約が未定義のまま統合先として参照されている。
**根拠**: 実装者は統合先の schema・配置・所有 spec を推測するしかない。

**判断: should-fix**
→ `implementation-signal-register` の定義元 spec を Adjacent expectations に追記する。

---

### P-6: ERROR — governance Req 4 AC2（handback classes A/B/C が未定義）

**対象箇所**: governance Req 4 AC2
**説明**: "handback classes A / B / C / intent-level handback" が本ドキュメント内で未定義であり、どの spec が定義しているかも不明。
**根拠**: クラスの意味・判定条件が不明ではクラス分類自体が不可能。

**判断: should-fix**
→ Adjacent expectations に定義元を追記する。

---

### P-7: ERROR — governance Req 8 AC4（heuristic_profile_ref が未定義のまま省略可能と宣言）

**対象箇所**: governance Req 8 AC4
**説明**: `heuristic_profile_ref` が本ドキュメントで初出かつ唯一の言及であり、どのスキーマに属するフィールドか不明。
**根拠**: 省略可能フィールドの省略動作を定義するには、そのフィールドが属するスキーマと規定のデフォルト値が先に確立されている必要がある。

**判断: should-fix**
→ フィールドが属するスキーマを定義するか、参照先を明記する。

---

### P-8: WARN — foundation Req 5 削除済み（番号スロット欠番）

**対象箇所**: foundation Req 5 削除済み
**説明**: 削除済み要件が番号スロットを占有し続けており、追跡性に欠番が生じているように見える。

**判断: leave-as-is**（敵対役反論を採用）
→ 欠番維持は追跡性強化の標準的慣行。再採番すると過去の参照が壊れる。

---

### P-9: WARN — governance Req 5 AC4（要件フェーズが実装フェーズ成果物の存在を完了条件とする）

**対象箇所**: governance Req 5 AC4
**説明**: AC4 は validation entrypoint を通過する具体的な review artifact の存在を要求しており、実装フェーズでしか満たせない条件が要件フェーズに含まれているように見える。

**判断: leave-as-is**
→ AC4 は仕様の完成物にサンプルを含めるという一般的な手法であり、フェーズ間の循環依存ではない。

---

### P-10: WARN — governance Req 3 AC2（fixture-bound resolution count / heuristic linkage count が未定義）

**対象箇所**: governance Req 3 AC2
**説明**: 指定メトリクスのうち "fixture-bound resolution count" と "heuristic linkage count" が本ドキュメント内で未定義。

**判断: leave-as-is**
→ AC3 が「各指標の意味・収集タイミング・解釈を定義すること」を要求しており、個々の指標の具体定義は設計フェーズで詰める想定。要件文書としては指標名の列挙で十分。

---

### P-11: WARN — governance Req 6 AC5（intent 変更の下流伝播機構が未定義）

**対象箇所**: governance Req 6 AC5
**説明**: intent 変更が下流チェックポイントを無効化する伝播機構（検出方法・伝播範囲・トリガー権限者）が定義されていない。

**判断: leave-as-is**
→ 要件文書は「何を実現するか」を定め、「どう実現するか」は設計で定める。AC5 は「intent 変更が下流チェックポイントを無効化できること」を要求しており、伝播の具体機構は設計の責務。

---

### P-12: INFO — foundation Req 3 AC10（スキーマフィールドラベルの英語ルール適用範囲が不明）

**対象箇所**: foundation Req 3 AC10
**説明**: 「スキーマフィールドラベルは英語」というルールの適用範囲が schema ファイルに限定されるか否かが不明。

**判断: leave-as-is**
→ 「schema field labels」はスキーマファイル内のフィールド名を指すことが文脈上十分明確。

---

### P-13: INFO — governance Req 7 AC4（intent-attributed 記録の判定基準と判定権限が未定義）

**対象箇所**: governance Req 7 AC4
**説明**: 下流フェーズで観測された問題を "intent-attributed" として記録できるとあるが、判定基準と判定権限が未定義。

**判断: leave-as-is**
→ AC4 は「再分類せずに intent 帰属として記録できる」という許容規定。判定基準の詳細は設計フェーズまたは運用規約で具体化すれば足りる。

---

## 敵対役（Opus 4.7）— 反論 3 件 + 独立発見 8 件

### 反論 R-1: P-3 の CRITICAL は過剰（finding schema 互換性）

**対象**: P-3
**反論内容**: foundation AC5 は finding 単体スキーマ、governance AC2 は conformance review 文書全体の項目リスト。後者は前者を呼び出す側であり二重定義ではない。WARN 相当。

**判断: should-fix（反論を採用し CRITICAL → should-fix に格下げ）**

---

### 反論 R-2: P-1 の CRITICAL は過剰（Step D プロンプト配置）

**対象**: P-1
**反論内容**: Step D は integration（統合）工程で新規 LLM 呼び出しを必須としない可能性が高い。指摘するなら「Step D の入出力契約が未定義」が正確。

**判断: should-fix（反論を部分採用し CRITICAL → should-fix に格下げ）**

---

### 反論 R-3: P-8 の WARN は不要（番号スロット欠番）

**対象**: P-8
**反論内容**: 番号保持は追跡性強化の通常実務。

**判断: leave-as-is（反論を採用）**

---

### 独立発見 A-1: CRITICAL — foundation Req 6 AC7 ↔ Boundary Context Out of scope

**対象箇所**: foundation Req 6 AC7 / Boundary Context Out of scope
**説明**: Req 6 AC7 は cross-project 由来の証拠取り込みを支える provenance フィールドを必須化しているが、同じ spec の Out of scope に「外部 contributor data intake」がある。必須メタデータが対象外スコープを前提にして書かれている。

**判断: should-fix**（CRITICAL ではなく should-fix）
→ Boundary Context か AC7 にフィールド定義と取り込み処理の区別を補記する。

---

### 独立発見 A-2: ERROR — foundation Req 4 AC4 ↔ Req 2 AC3（相対パス縛りが prompt 切替経路を閉ざす可能性）

**対象箇所**: foundation Req 4 AC4 / Req 2 AC3
**説明**: Req 4 AC4 は「相対 repo パスのみで prompt を解決する」と縛るのに対し、config の prompt 切替や override の表現方法が未規定。

**判断: leave-as-is**
→ Boundary Context が「prompt override の選択順序」を明示的に対象外としており、AC4 は正規配置のパス解決方法を規定するもの。Override の仕組みは runtime spec の責務。

---

### 独立発見 A-3: ERROR — governance Req 7 AC5 ↔ foundation Req 1 AC1（「フェーズ」と「ステップ」の用語混乱）

**対象箇所**: governance Req 7 AC5 / foundation Req 1 AC1
**説明**: foundation の "Step A/B/C/D"（単一レビュー実行内の工程）と governance の "phase: intent/requirements/design/tasks/implementation"（開発ライフサイクルの段階）は異なる概念だが、両 spec で用語の区別が明記されていない。

**判断: should-fix**
→ 各 spec の Introduction か用語節で明確に区別すべき。

---

### 独立発見 A-4: ERROR — governance Req 5 AC1-AC4（validation entrypoint の入出力契約・失敗判定が未規定）

**対象箇所**: governance Req 5 AC1-AC4
**説明**: 「repo 内に validation entrypoint を備える」と要求するが、起動手段・入出力契約・失敗時の終了コードがすべて未規定。

**判断: should-fix**
→ 要件文書で「成功・失敗の判定方法」程度は定義すべき。

---

### 独立発見 A-5: WARN — foundation Req 7 AC2（steady-state の定義がなく過渡期の許容範囲が不明）

**対象箇所**: foundation Req 7 AC2
**説明**: 「steady-state での repo 外メモリ依存を禁止」とあるが、steady-state の定義がなく過渡的状態での外部依存の許容範囲が不明。

**判断: should-fix**
→ steady-state の判断基準を定義するか、過渡期の扱いを明記する。

---

### 独立発見 A-6: WARN — governance Req 1 AC3 ↔ Boundary Context（pre-push/pre-PR と Out of scope の矛盾）

**対象箇所**: governance Req 1 AC3 / Boundary Context Out of scope
**説明**: AC3 は「push 前または PR 提出前」のチェックポイントを含めるが、Out of scope に「PR 運用や外部 CI の詳細」がある。

**判断: leave-as-is**
→ AC3 は実施タイミングを定めているだけで、PR ワークフローの詳細には踏み込んでいない。

---

### 独立発見 A-7: WARN — governance Req 8 AC3（出典文書の保管場所・識別方法が未定義）

**対象箇所**: governance Req 8 AC3
**説明**: 「case content は提供された出典文書から導出すること」と書くが、出典文書の保管場所・識別方法が未定義。

**判断: should-fix**
→ AC に出典文書の所在指定を追加すべき。

---

### 独立発見 A-8: INFO — foundation Req 3 AC6 ↔ Boundary Context（5 フィールド固定と judgment 具体挙動 Out of scope の整合）

**対象箇所**: foundation Req 3 AC6 / Boundary Context Out of scope
**説明**: Out of scope に「judgment_reviewer の具体的挙動」があるが、AC6 で 5 フィールド構造を固定している。スキーマの構造定義（どんなフィールドがあるか）と具体挙動の定義（フィールドにどう値を入れるか）は別の責務。

**判断: leave-as-is**
→ AC6 はデータ構造の契約を定めるだけで、judgment_reviewer がどう判断するかには踏み込んでおらず矛盾しない。

---

## 集計（判断役 Opus 4.6）

- **must-fix: 2 件** — P-2（metadata 二重定義）、P-4（pattern assets 残留参照）
- **should-fix: 10 件** — P-1, P-3, P-5, P-6, P-7 ＋ A-1, A-3, A-4, A-5, A-7
- **leave-as-is: 12 件** — P-8, P-9, P-10, P-11, P-12, P-13 ＋ R-3 ＋ A-2, A-6, A-8

### must-fix の帰属別分類

governance 固有の must-fix: **0 件**

foundation 修正が必要な must-fix（2 件）:
- P-2: foundation Req 1 AC5 / Req 6 AC2 の包含関係明示
- P-4: foundation Req 7 AC1 から "pattern assets" 削除
