# dual-reviewer-self-improvement design 個別レビュー

## 取得メタデータ

- 実施日：2026-05-16
- 対象：`dual-reviewer-self-improvement/design.md`（要件承認後の差分追従済み）
- 契約入力：`dual-reviewer-self-improvement/requirements.md`（承認済み）、上流 `foundation/requirements.md`
- 方式：claude --print --disallowedTools "Read,Write,Edit"（ファイルアクセス技術的遮断）
- 主役：claude-sonnet-4-6 / 敵対役：claude-opus-4-7 / 判断役：claude-opus-4-6
- 通信構造：β 逐次方式（主役 → 敵対役 → 判断役）
- 手順：REVIEW_PROTOCOL.md 節 3（設計レビュー 10 観点）

---

## 主役発見（claude-sonnet-4-6）

# 設計レビュー：dual-reviewer-self-improvement / design.md

## Round 1：要件全件の網羅

全 8 要件 × AC を照合した。主な対応状況：

- Req 1（改善入力定義）：3 class 分類、valid/invalid 分離、provenance 阻止規則いずれも記述あり。AC6（provenance 欠落時の proposal 阻止）は本文中に明文化済み。
- Req 2（proposal 契約）：proposal unit フィールド一覧・state enum・register 分離で充足。ただし `motivation_class` の enum 値が未定義（→P-1）。
- Req 3（replay / backtest）：test mode selection、分岐基準（変更規模・リスク・対象レイヤー）、`foundation_run_metadata_ref` フィールドで AC6/AC7 まで網羅。replay path の具体解決が委任先不明（→P-7）。
- Req 4（承認・採用フロー）：state enum、approval gate、adoption gate、version update 条件で充足。採用変更の適用メカニズムが空白（→P-4）。
- Req 5（rollback）：supersession 区別、rollback_register フィールド群、invalidation 連鎖言及あり。AC1「発動条件」が未定義（→P-2）、invalidation 検知機構が空白（→P-5）。
- Req 6（論文分離）：禁止ルール明文化、`target_layer` / `motivation_class` フィールドで意図分離。ただし `motivation_class` enum 未定義（P-1 に同じ）。
- Req 7（手動 vs runtime 証拠）：`source_origin` enum で識別。AC5「手動→runtime 引き継ぎ境界」の記述が空白（→P-3）。
- Req 8（外部インポート証跡）：`source_origin`・`source_repository_refs`・`source_admission_refs` で充足。

---

**P-1 ERROR**
- 対象：Proposal Model「1. Proposal Unit」フィールド一覧
- 説明：`motivation_class` がフィールドとして列挙されているが enum 値が定義されていない。Design Drivers には「runtime quality / workflow quality / evidence quality」という 3 区分が散文で登場するが、`target_layer` の enum 節のように形式化されていない。
- 根拠：要件 6 AC3「preserve whether an improvement is motivated by runtime quality, workflow quality, or evidence quality」を proposal artifact に構造的に記録するには enum が必要。未定義では実装者が任意文字列を使い、cross-proposal 集計・filtering が壊れる。

**P-2 ERROR**
- 対象：Rollback Model セクション
- 説明：`rollback_trigger_signal_refs` フィールドは存在するが、「どの条件で rollback が発動するか」が定義されていない。foundation 無効化契約経由のトリガー（AC6）は言及済みだが、「有害と判断する基準」や「品質劣化の観測方法」が具体化されていない。
- 根拠：要件 5 AC1「define rollback-triggering conditions」が直接の根拠。実装者は「何をもって rollback を開始するか」を判断できない。

---

## Round 2：アーキテクチャ整合性

5 段パイプライン（signal intake → proposal builder → test gate → decision gate → history registry）は本設計の目的に対して適切な粒度。

**P-3 WARN**
- 対象：Interfaces to Other Features → Runtime 節、および adoption gate
- 説明：`adoption_register.json` は proposal と repo change を結ぶ registry として定義されているが、その register を読んで実際の変更を適用するコンポーネント・手順が設計されていない。「runtime に直接書き戻さない」という制約は明記されているが、代替の適用メカニズム（人間オペレーター手順、CI フック等）が空白。
- 根拠：要件 4 AC4「require version updates for adopted runtime-affecting changes」を誰がどう実施するかが不明なため、adoption gate の「repo change が version update と結びつく」という条件を検証できない。

**P-4 WARN**
- 対象：Architecture セクションの Mermaid 図
- 説明：「rollback も次の proposal の input になりうる」と本文に記述されているが、アーキテクチャ図では `History → RuntimeChange` の一方向だけが示され、rollback / post-adoption failure signal が再び signal intake に戻るフィードバックループが図示されていない。
- 根拠：self-improvement の「継続的改善」という目的（Introduction）においてループ構造は主概念であり、図から抜けると実装者が一方向パイプラインとして実装するリスクがある。

---

## Round 3：データモデル・スキーマ詳細

**P-5 WARN**
- 対象：Learning Artifact Layout → findings/ 節
- 説明：`recurring_failure_signals.json`、`workflow_failure_signals.json`、`pattern_candidates.json` の 3 ファイルがレイアウトに列挙されているが、これらのスキーマが一切定義されていない。Signal Extraction の記述は例示に留まりフィールド定義がない。
- 根拠：proposal の `source_evidence_refs` がこれらのファイルを参照する場合、スキーマ不在では参照の解釈が実装者依存になり、provenance traceability（要件 1 AC5）が崩れる。

**P-6 INFO**
- 対象：Proposal Model「1. Proposal Unit」フィールド一覧
- 説明：`proposal_id` の形式（UUID・連番・プレフィックス付き文字列等）が定義されていない。`rollback_register` や `adoption_register` が `proposal_id` を参照するため、一意性保証の根拠がないと参照の信頼性が実装依存になる。
- 根拠：要件 2 AC1「structured proposal unit」のもと、artifact 間参照が機械的に解決できる必要がある。

**P-7 INFO**
- 対象：全 Learning Artifact Layout
- 説明：proposal は `.yaml`、その他（backtest、各 register）は `.json` という非対称な形式選択の根拠が記述されていない。意図を一行記述しておかないと実装者が統一しようとして仕様逸脱する可能性がある。
- 根拠：設計上の判断として明示する価値がある（INFO 止まり）。

---

## Round 4：API 接合面の具体化

**P-8 WARN**
- 対象：Replay and Backtest Model → Replay Inputs 節
- 説明：replay 入力として `review_case.json`・`steps/*.json` が列挙されているが、これらが `experiments/runs/<run_id>/` のどのサブパスに存在するかは runtime spec に委任されており未確定。manifest-based discovery で解決すると述べているが、その discovery アルゴリズムが記述されていない。
- 根拠：要件 3 AC2「require replay or backtest inputs to reference concrete run evidence」を満たすには参照が解決可能でなければならない。本設計単独では参照が具体的に成立しない。

---

## Round 5：アルゴリズム + 性能達成手段

本 feature は performance-critical 実行レイヤーではなく artifact 管理・意思決定レイヤーのため、性能要件は定義不要。

アルゴリズム面では:
- test mode 分岐（replay vs backtest vs manual_review）の判定基準は「変更規模・リスク水準・対象レイヤー」の 3 要素と明記されており、要件 3 AC6 を充足。
- 閾値（「何回繰り返されれば repeated とするか」等）は意図的に実装委任とみられる。ただし Proposal Normalization Rules は例示付きで記述されており、実装上十分な粒度。

**所見なし（観点確認済み）**

---

## Round 6：失敗モード処理 + 観測性

**P-9 WARN**
- 対象：Rollback Model 末尾段落「採用済み改善の motivating evidence が事後に invalidate された場合」
- 説明：foundation 無効化契約を起点に再評価・rollback を起動すると記述されているが、どのコンポーネントがその invalidation イベントを検知し起動するかのメカニズムがない。「自動検知」か「人間によるポーリング」かが不明。
- 根拠：要件 5 AC6「trigger re-evaluation or rollback of an adopted improvement when its motivating evidence is later invalidated」は発動の obligation を課しているが、設計はそれを概念として述べるに留め「どう検知するか」が空白。

**P-10 WARN**
- 対象：design 全体（test gate 実行失敗の扱い）
- 説明：replay 実行がクラッシュする、backtest 入力が欠落する、等の test gate 内部失敗に対する error handling が記述されていない。result_label の `untested` と `inconclusive` は定義されているが、それらに至るエラーパスが不明。
- 根拠：要件 3 AC4「distinguish 'proposal unsupported' from 'proposal untested'」は達成されているが、test gate が error exit した場合の状態管理が空白で、実装者は proposal state を手動設定するしかない。

---

## Round 7：セキュリティ・プライバシー

本 feature は内部研究用途であり、外部公開 API を持たない設計。

- `source_repository_refs` や `source_admission_refs` に外部プロジェクトの識別子が含まれる可能性があるが、アクセス制御の記述はなし。
- 設計文書の性質（contract 定義）上、セキュリティ設計は実装レイヤーの責務として委任されていると解釈できる。

**所見なし（観点確認済み、懸念は実装レイヤー委任として許容範囲）**

---

## Round 8：依存選定

本設計は artifact レイアウトと contract 定義が主体であり、外部ライブラリ依存は意図的に排除されている。foundation schema への依存は `foundation_run_metadata_ref` フィールドで表現されており適切。

**P-7（YAML/JSON 混在）** は Round 3 で計上済み。重複回避のためここでは参照のみ。

**所見なし（新規）**

---

## Round 9：テスト戦略

**P-11 INFO**
- 対象：設計全体（テスト戦略節が存在しない）
- 説明：本設計は「対象 proposal の検証工程」としての replay/backtest を定義しているが、self-improvement コンポーネント自体（signal intake・proposal builder・test gate）の正しさを検証する手段が記述されていない。
- 根拠：REVIEW_PROTOCOL 観点 9 に対し、learning layer 自体のテスト方針が空白。INFO 止まりだが、特に `findings/` スキーマが未定義（P-5）な状態での signal intake テストは困難になる。

---

## Round 10：移行戦略

**P-12 INFO**
- 対象：設計全体（移行戦略節が存在しない）
- 説明：`learning/` ディレクトリを新規作成する前提が暗黙化されており、旧 repo の prototype 資産（もし存在するなら）や過去の改善記録の扱いが記述されていない。
- 根拠：foundation requirements.md の Change Intent が「旧 repo 資産を流用しつつ再構築」としているため、既存 data がある可能性を無視できない。`learning/` が空の状態から始まる想定であれば、その旨を明記して閉じるべき。

**P-13 WARN**
- 対象：Req 7 AC5 対応箇所（設計全体で未登場）
- 説明：要件 7 AC5「preserve the handoff boundary when later runtime-mediated evidence supersedes earlier manual evidence」に対応する設計記述が存在しない。`source_origin` enum は `manual_review_record` を識別できるが、その後 runtime evidence が蓄積された際に manual 由来 proposal が obsolete になることをどう記録するかが空白。
- 根拠：要件 7 AC5 は明示的に「handoff boundary の保存」を求めており、設計の対応節が存在しない状態は要件未対応とみなす。

---

## 観点別発見要約

- **Round 1（要件網羅）**：P-1（motivation_class enum 欠落）、P-2（rollback 発動条件未定義）、P-13（AC5 handoff boundary 未記述）の 3 件。
- **Round 2（アーキテクチャ整合性）**：P-3（採用変更の適用メカニズム未定義）、P-4（フィードバックループ図示なし）の 2 件。
- **Round 3（データモデル・スキーマ）**：P-5（findings/ スキーマ未定義）、P-6（proposal_id 形式未定義）、P-7（YAML/JSON 混在根拠なし）の 3 件。
- **Round 4（API 接合面）**：P-8（replay path 解決アルゴリズム未定義）の 1 件。
- **Round 5（アルゴリズム + 性能）**：所見なし。
- **Round 6（失敗モード + 観測性）**：P-9（invalidation 連鎖トリガー機構未定義）、P-10（test gate 内部失敗の error handling 未定義）の 2 件。
- **Round 7（セキュリティ・プライバシー）**：所見なし（実装委任として許容）。
- **Round 8（依存選定）**：所見なし（P-7 既計上）。
- **Round 9（テスト戦略）**：P-11（learning layer 自体のテスト戦略欠如）の 1 件。
- **Round 10（移行戦略）**：P-12（移行戦略節の不在）の 1 件。

---

## 全所見 一覧

- P-1：ERROR / motivation_class enum 未定義（要件 6 AC3 未充足）
- P-2：ERROR / rollback 発動条件未定義（要件 5 AC1 未充足）
- P-3：WARN / 採用変更の適用メカニズム空白（要件 4 AC4 実装不可）
- P-4：WARN / フィードバックループ図示なし（目的との不整合）
- P-5：WARN / findings/ スキーマ未定義（provenance traceability リスク）
- P-6：INFO / proposal_id 形式未定義（artifact 参照の信頼性低下リスク）
- P-7：INFO / YAML/JSON 混在の根拠未記述（実装逸脱リスク）
- P-8：WARN / replay path 解決アルゴリズム未定義（要件 3 AC2 不完全）
- P-9：WARN / invalidation 連鎖トリガー機構未定義（要件 5 AC6 概念止まり）
- P-10：WARN / test gate 内部失敗の error handling 未定義（要件 3 AC4 穴）
- P-11：INFO / learning layer 自体のテスト戦略なし
- P-12：INFO / 移行戦略節の不在
- P-13：WARN / handoff boundary 保存記述なし（要件 7 AC5 未対応）

---

## 敵対役レビュー（claude-opus-4-7）

# 敵対役レビュー：dual-reviewer-self-improvement / design.md

主役の発見を契約（self-improvement requirements / foundation requirements）と突き合わせて再検証した。安易な同調はせず、根拠・重大度・委任境界を独立に判定する。

---

## パート1：主役の各発見への反論

- **P-1（motivation_class enum 未定義）：反論あり（部分的）**
  値そのものは未定義ではない。Design Drivers に「runtime quality / workflow quality / evidence quality」という閉じた 3 区分が明記され、Input Classes の 3 分類（review_quality / workflow_failure / evidence_quality）とも対応関係を読み取れる。問題は「形式化（enum 節）の欠落」であって「値の不在」ではない。要件 6 AC3 は構造的保存を求めるので穴自体は実在するが、重大度は ERROR ではなく WARN が妥当。指摘の方向は支持、格付けに反論。

- **P-2（rollback 発動条件未定義）：反論あり（部分的）**
  発動条件はゼロではない。本文末尾で「motivating evidence の事後 invalidate を foundation 無効化契約起点に rollback 起動」と 1 条件は定義済み（要件 5 AC6）。未定義なのは「有害判定の一般基準」であって AC1 全体ではない。AC1 を完全未充足と断ずるのは過大。穴は認めるが ERROR は強すぎ、WARN 相当。

- **P-3（採用変更の適用メカニズム空白）：反論あり（部分的）**
  Non-Goals に「runtime 変更の自動適用」が明示され、適用器（applier）はこの spec の責務外。要件 4 AC4 が求めるのは「version update を要求すること」＝ゲート条件であり、Adoption Gate 条件 3 でその契約は表現済み。さらに「proposal から repo version update をどう参照するか」は Open Issues に既出で、見落としではなく既知の未決事項。残る正当な懸念は「条件 3 を誰が機械的に検証するか」のみ。WARN → INFO 相当に格下げすべき。

- **P-4（フィードバックループ図示なし）：反論あり（部分的）**
  ループは Rollback Model 本文「rollback も次の proposal の input になりうる」で言語化済み。Mermaid は high-level スケッチで規範ではない。「実装者が一方向で作るリスク」は推測的。所見は成立するが INFO 相当。

- **P-5（findings/ スキーマ未定義）：反論なし**
  完全同意。むしろ `source_evidence_refs` の解決可能性（要件 1 AC5 / provenance）に直結するため、ERROR への格上げを支持する。`pattern_candidates.json` / `workflow_remediation_templates.json` も同様に未定義であり、影響範囲は主役記述より広い。

- **P-6（proposal_id 形式未定義）：反論なし**
  同意。register 群の機械的参照解決の前提なので妥当。INFO 据え置きで異論なし。

- **P-7（YAML/JSON 混在根拠なし）：反論なし**
  同意。軽微だが contract 文書として一行の根拠記述は妥当な要求。

- **P-8（replay path 解決アルゴリズム未定義）：反論あり（部分的）**
  run directory layout は foundation 要件 1 AC6 で明示的に runtime spec へ委任されている。本設計は anchor を `run_manifest.yaml` + `run_id` に固定し、fixture 名・固定 path 列挙を禁止する原則も書いている。具体 path 解決を runtime に委ねるのは正しい責務分割であって設計穴ではない。WARN → INFO 相当。

- **P-9（invalidation 連鎖トリガー機構未定義）：反論あり（部分的）**
  所見は正しいが P-2 と同根（トリガー検知コンポーネント不在）の二重計上。独立 2 件として数えると重大度プロファイルが歪む。P-2 と統合し「invalidation/rollback 起動の検知主体不在」1 件として扱うべき。

- **P-10（test gate 内部失敗の error handling 未定義）：反論なし**
  同意。`untested` / `inconclusive` への到達エラーパスが空白で、proposal state を手動設定するしかない点は実在の穴。WARN 妥当。

- **P-11（learning layer 自体のテスト戦略なし）：反論なし**
  同意。ただし P-5（findings/ スキーマ未定義）依存で signal intake テスト不能という連鎖は主役指摘どおり。

- **P-12（移行戦略節の不在）：反論あり（部分的）**
  learning/ は新設 learning layer であり prototype 側に対応資産が存在しない可能性が高い。「既存 data があるかも」は本レイヤーに限れば投機的。必要なのは「learning/ は greenfield」と一行明記するだけで、移行設計そのものは不要。所見は支持するが重大度は最小 INFO。

- **P-13（handoff boundary 保存記述なし／要件 7 AC5）：反論なし（重大度はむしろ強化）**
  同意。設計の「supersession」は proposal 間の置換概念であり、manual→runtime の証跡引き継ぎ境界（AC5）とは別物。完全未対応。WARN ではなく ERROR（AC 丸ごと設計応答なし）への格上げを支持する。後述 A-1 と併せると深刻。

---

## パート2：主役が見落とした独立発見

**A-1 ERROR ／ Round 1（要件全件の網羅）**
- 対象：Requirements Traceability 表
- 説明：表の行は要件 1〜6 の 6 行のみ。要件 7（Manual-vs-Runtime Evidence Provenance）と要件 8（Imported Evidence Provenance Preservation）の行が表から完全に欠落している。
- 根拠：contract 文書の self-audit である traceability 表に 2 要件が不在なのは、設計が両要件を体系的に追跡していない徴候。主役は P-13 で要件 7 AC5 を、Req8 を「フィールドで充足」と個別評価したが、表レベルの構造的欠落自体は未指摘。

**A-2 WARN ／ Round 1（要件全件の網羅）**
- 対象：Replay Inputs／Valid vs Invalid Inputs（要件 8 AC5 対応）
- 説明：imported external bundle の `source_repository_id` 等を保持する記述はあるが、「provenance 不十分な imported evidence を admitted standard comparison evidence と同等に扱わない」という否定制約が明文化されていない。フィールドの存在＝制約の充足ではない。
- 根拠：要件 8 AC5 は負の制約（同等扱い禁止）であり、保持フィールドの列挙では満たせない。主役は Req8 を「`source_*` で充足」と判定したが AC5 の制約面を見落とし。

**A-3 WARN ／ Round 2・3（アーキテクチャ／データモデル）**
- 対象：Proposal States と Architecture 図
- 説明：proposal state は 7 値（draft / awaiting_test / tested / approved / rejected / adopted / rolled_back）だが、状態遷移図が一切なく、5 段アーキテクチャ図にも `rolled_back` に対応する段が存在しない。enum 列挙のみで遷移規則が不在。
- 根拠：要件 2 AC1 / 要件 4 AC1（明示的 state 定義）に対し、遷移条件が `untested`→`tested` の 1 文しかなく、不正遷移の防止が実装者依存になる。主役 P-4 は図の矢印欠落のみ指摘し、状態機械そのものの不在は未検出。

**A-4 WARN ／ Round 2・4（アーキテクチャ／API 接合面）**
- 対象：v2 Supporting Inputs／Architecture 図の source ノード
- 説明：図の入力源は `experiments/runs/`・`experiments/analysis/` だが、supporting input は `v2/signal_linkage_note.json`・`derived/comparison_eligibility_note.json` 等で、これらが run root 相対のどこに在るか（experiments/runs/<run_id>/ 配下か別 namespace か）が一切固定されていない。
- 根拠：要件 3 AC2（concrete run evidence 参照）。主役 P-8 は replay path に限定したが、supporting input 群の path namespace 不整合は別問題で未指摘。

**A-5 WARN ／ Round 3（データモデル・スキーマ）**
- 対象：Decision and Adoption Model「2. Adoption Gate」
- 説明：`rejection_register.json`（4 フィールド明示）と `rollback_register.json`（5 フィールド明示）には field 列挙があるのに、`adoption_register.json` は「proposal と repo change を結ぶ registry」と散文記述のみで required field が定義されていない。同格 artifact 間で記述粒度が非対称。
- 根拠：要件 4 AC3（adopted change と proposal の link 保存）を機械的に検証するには field 定義が必要。主役 P-3 は適用器の不在を論じたが、adoption_register 自体のスキーマ欠落は別の独立穴。

**A-6 INFO ／ Round 3（データモデル・スキーマ）**
- 対象：Learning Artifact Layout の `proposal_index.json` / `backtest_index.json`
- 説明：両 index ファイルがレイアウトに列挙されるが、本文中で目的・スキーマ・更新責任が一度も説明されない。
- 根拠：index は artifact 横断参照の起点になりうるため、未定義は traceability を弱める。主役は findings/ スキーマ（P-5）には触れたが index 2 件は未指摘。

**A-7 INFO ／ Round 3（データモデル・スキーマ）**
- 対象：proposal の `required_test_mode` と backtest artifact の `test_mode`
- 説明：proposal 側 `required_test_mode` と backtest 側 `test_mode` が別名で、両者の関係（一致必須か、test gate が上書き可か）が定義されていない。
- 根拠：要件 3 AC4（unsupported と untested の区別）の状態整合は両フィールドの関係に依存する。命名・関係の未定義は contract 整合性の穴。

**A-8 WARN ／ Round 4・8（API 接合面／依存選定）**
- 対象：Project-Specific Pattern Extraction 内「`scripts/track_runs/contracts/runtime_validation_summary.schema.json` を canonical contract とする」記述
- 説明：specs 配下でない具体 path の外部スキーマ依存が本文中に注入されているが、Interfaces to Other Features にも Boundary Context にも現れず、所有 spec（foundation か runtime か）が不明。
- 根拠：foundation 要件 7（repo-contained / runtime-critical 依存の明示）と整合確認が必要な cross-tooling 結合。主役 Round 8 は「新規所見なし」としたが、この未宣言の具体 path 依存を見落としている。

**A-9 WARN ／ Round 5（アルゴリズム＋性能：主役「所見なし」への反論）**
- 対象：Signal Extraction「2.5 Proposal Normalization Rules」
- 説明：「closely-coupled workflow failure signal は 1 proposal に統合してよい」の "closely-coupled" が未定義述語で、判定例（同一 run の validator_failed + invalidation_marker_issued）が 1 つあるのみ。統合の境界が実装者解釈に委ねられ、proposal identity が不安定化する。
- 根拠：proposal identity は adoption / rollback / 集計の参照単位（要件 2 AC1）。統合述語の曖昧さは dedup の正しさに直結する。主役は Round 5 を「十分な粒度／所見なし」と結論したが、これは過小評価であり独立に反論する。

**A-10 WARN ／ Round 6（失敗モード＋観測性）**
- 対象：Decision and Adoption Model「1. Approval Gate」「2. Adoption Gate」
- 説明：rejection_register には `reviewer_note` があるが、approval / adoption 側に承認者識別・sign-off 記録フィールドが存在しない。誰が承認したかの監査証跡が取れない。
- 根拠：foundation 要件 6 AC2 は human sign-off status を必須メタデータに含める。要件 4 AC2（runtime-affecting change 前の human approval）を観測可能にするには承認者証跡が必要。主役 P-3/P-10 とは別軸（観測性・監査）の独立穴。

**A-11 INFO ／ Round 7（セキュリティ・プライバシー：主役「所見なし」からの分岐）**
- 対象：Replay Inputs／imported external bundle 取り込み
- 説明：imported external bundle を steady-state の repo-contained `learning/` に取り込む際、外部プロジェクト由来データの取り扱い（機微情報の混入禁止・scrub 方針）への注意喚起が contract レベルで一切ない。
- 根拠：contract 文書でも外部証跡 intake は最小限の data-handling 注記が通例。主役は「実装委任として許容・所見なし」としたが、敵対役として最小 INFO で独立計上し分岐する。

**A-12 INFO ／ Round 9（テスト戦略）**
- 対象：Valid vs Invalid Inputs 末尾「provenance 欠落時の proposal 生成阻止」（要件 1 AC6）
- 説明：provenance 欠落で proposal 生成を阻止すると断言するが、その阻止挙動の検証方法（負経路テスト・fixture）が示されない。P-11 の一般論とは別に、この強い断定の検証可能性が個別に空白。
- 根拠：要件 1 AC6 は blocking obligation。検証契約がないと「阻止する」と書いただけで担保されない。主役 P-11 は learning layer 全般のテスト欠如に留まり、この特定 obligation の testability は未指摘。

**A-13 WARN ／ Round 10（移行戦略）**
- 対象：learning/ 配下 artifact 全般（proposal yaml / 各 register）
- 説明：proposal 契約や register が将来変わった場合の `schema_version` フィールドや移行規則がない。foundation 要件 3 AC3 は versioned schema artifact を要求し silent incompatible edit を禁じるが、learning/ 側 artifact はこの versioning 契約に接続されていない。
- 根拠：契約進化時に既存 `proposals/<id>.yaml` が解釈不能化し、長期 learning history（要件 5 AC5）の連続性が壊れる。主役 P-12 は learning/ ディレクトリの初期生成のみを論じ、artifact スキーマの世代管理という別軸を見落としている。

---

## 総括（敵対役視点）

- 主役所見の方向性はおおむね妥当。ただし **P-3 / P-8 は責務委任・Open Issues 既出を考慮すると重大度過大**、**P-9 は P-2 と二重計上**、**P-1 / P-2 は ERROR ではなく WARN 相当**。
- 一方、**P-5 / P-13 は主役の格付けより深刻**（それぞれ ERROR 格上げを支持）。
- 独立発見の最重要は **A-1（traceability 表から要件 7・8 が丸ごと欠落）**。これは A-2・P-13 と合流し、「manual/imported provenance 系要件（7・8）への設計応答が体系的に薄い」という単一の構造的弱点を示す。設計整合ゲートでは A-1 を最優先 must-fix とし、A-3（状態遷移図不在）・A-5（adoption_register スキーマ非対称）を次点とすることを推奨する。

---

## 判断役レビュー（claude-opus-4-6）

# 判断役：最終判定

## 判定基準

- **must-fix**：要件契約の明確な未充足、または実装者が設計だけでは正しい実装を導出できない構造的欠落
- **should-fix**：設計品質を高め実装リスクを低減するが、不在でも要件違反とは断定できないもの
- **leave-as-is**：責務委任として正当、既知 Open Issues で捕捉済み、またはフェーズ外

---

## 主役発見への判定

### P-1（motivation_class enum 未定義）

**判定：should-fix**

敵対役反論を採用する。Design Drivers に「runtime quality / workflow quality / evidence quality」の 3 値は散文で記述済みであり、概念は不在ではない。形式化（enum 節）の欠落は実装上の曖昧さを生むが、値自体は導出可能。ERROR → WARN 格下げ。一行の enum 節追加で閉じる。

### P-2（rollback 発動条件未定義）

**判定：should-fix**

敵対役反論を採用する。foundation 無効化契約起点の条件が 1 件定義済み（要件 5 AC6 対応）であり、AC1「全件未充足」は過大。ただし品質劣化ベースのトリガー（adoption 後に metric 悪化を観測した場合等）が欠落しているのは事実。ERROR → WARN 格下げ。

### P-3（採用変更の適用メカニズム空白）

**判定：leave-as-is**

敵対役反論を採用する。Non-Goals に「runtime 変更の自動適用」が明示排除され、Open Issues に「proposal から repo version update をどう参照するか」が既出。adoption gate 条件 3 は契約として定義済みであり、適用器の設計はこの spec の責務外。

### P-4（フィードバックループ図示なし）

**判定：leave-as-is**

敵対役反論を採用する。ループは Rollback Model 本文に「rollback も次の proposal の input になりうる」と言語化済み。Mermaid 図は概観スケッチであり規範的仕様ではない。

### P-5（findings/ スキーマ未定義）

**判定：must-fix**

敵対役の格上げ主張を採用する。`source_evidence_refs` が findings/ 内 artifact を参照する以上、参照先の構造が未定義では provenance 連鎖（要件 1 AC5）が検証不能。`pattern_candidates.json`・`workflow_remediation_templates.json` も同様に未定義であり、影響範囲は主役記述より広い。最低限の required fields 定義が必要。

### P-6（proposal_id 形式未定義）

**判定：leave-as-is**

artifact 間参照で一意性が前提になるのは事実だが、設計フェーズで ID 形式を固定する必要はない。実装フェーズで UUID 等の標準方式を選択すれば足りる。

### P-7（YAML/JSON 混在根拠なし）

**判定：leave-as-is**

一行の判断根拠があれば親切だが、設計ゲートの阻害要因ではない。

### P-8（replay path 解決アルゴリズム未定義）

**判定：leave-as-is**

敵対役反論を採用する。foundation 要件 1 AC6 が step storage layout を明示的に runtime へ委任しており、本設計は anchor（`run_manifest.yaml` + `run_id`）と禁止事項（fixture 名列挙の排除）を定義している。具体 path 解決は runtime spec の責務。

### P-9（invalidation 連鎖トリガー機構未定義）

**判定：leave-as-is**

敵対役反論を採用する。P-2 と同根（検知主体の不在）であり、二重計上。P-2 の should-fix で包含される。

### P-10（test gate 内部失敗の error handling 未定義）

**判定：should-fix**

主役・敵対役とも合意。`untested` / `inconclusive` への到達パスが空白で、test gate 障害時に proposal state がどう遷移するかが実装者判断になる。一段落の error path 記述で閉じる。

### P-11（learning layer 自体のテスト戦略なし）

**判定：leave-as-is**

テスト戦略は tasks フェーズで具体化すべき内容。設計ゲートの責務外。

### P-12（移行戦略節の不在）

**判定：leave-as-is**

敵対役指摘のとおり learning/ は greenfield の可能性が高い。「greenfield：既存資産なし」と一行明記すれば足りるが、設計ゲート阻害とまでは言えない。

### P-13（handoff boundary 保存記述なし）

**判定：must-fix**

敵対役の格上げ主張を採用する。要件 7 AC5 は「later runtime-mediated evidence supersedes earlier manual evidence」のときの境界保存を明示的に要求している。`source_origin` enum は初期タグ付けを担うが、事後の supersession をどう記録するかの設計応答がゼロ。AC 丸ごと未対応。

---

## 敵対役独立発見への判定

### A-1（traceability 表から要件 7・8 が欠落）

**判定：must-fix**

8 要件中 2 要件が traceability 表から丸ごと脱落している。表は設計の self-audit 機能であり、欠落は「追跡していない」ことの徴候。P-13・A-2 と合流して「manual/imported provenance 系要件への体系的追跡不足」を示す。修正は表への 2 行追加＋対応節の補完。

### A-2（要件 8 AC5 否定制約の未明文化）

**判定：should-fix**

フィールドの存在は必要条件であって十分条件ではない。「provenance 不十分な imported evidence を admitted standard comparison evidence と同等に扱ってはならない」という否定制約を明文化する必要がある。一文の追加で閉じる。

### A-3（proposal state 遷移図・遷移規則不在）

**判定：must-fix**

7 つの状態を列挙しながら遷移規則が `untested`→`tested` の 1 件しかないのは、状態機械として不完全。実装者は「draft から直接 rejected に遷移してよいか」「adopted から rolled_back 以外に遷移があるか」を判断できない。要件 4 AC1 は「explicit states for proposal review, approval, rejection, and adoption」を要求しており、state の列挙だけでなく遷移の明示が「explicit」の内実。

### A-4（supporting input の path namespace 不整合）

**判定：should-fix**

supporting input が `experiments/runs/<run_id>/` 相対なのか別 namespace なのかの一行注記がないと、実装者が lookup 対象を誤る。ただし「読めなくても基本 flow 維持」と graceful degradation が明記されているため、must-fix には至らない。

### A-5（adoption_register スキーマ非対称）

**判定：must-fix**

rejection_register（4 fields）と rollback_register（5 fields）に field 列挙がある一方、最重要の adoption_register は散文のみ。要件 4 AC3「preserve the link between an adopted change and the proposal that justified it」を機械的に検証するには field 定義が必須。

### A-6（proposal_index / backtest_index 未説明）

**判定：leave-as-is**

index の目的は自明（一覧性）。実装で具体化すれば足りる。

### A-7（required_test_mode vs test_mode 関係未定義）

**判定：leave-as-is**

命名の一貫性は実装で解消可能。

### A-8（scripts/track_runs/contracts/ path の未宣言依存）

**判定：should-fix**

specs 外の具体 path への依存が Boundary Context にも Interfaces にも現れないのは契約文書として不整合。Boundary Context の Adjacent expectations に一行追加するか、依存先の所有 spec を明示すべき。

### A-9（"closely-coupled" 未定義述語）

**判定：leave-as-is**

「してよい」（許容）表現であり mandatory rule ではない。例示が 1 件あり、運用上の裁量範囲として許容。

### A-10（approval/adoption に承認者識別フィールド不在）

**判定：should-fix**

要件 4 AC2 が human approval を必須とし、foundation 要件 6 AC2 が human sign-off status を含む以上、「誰が承認したか」の記録フィールドは監査上必要。adoption_register / approval gate いずれかに `approver_id` 相当を追加すべき。

### A-11（imported bundle の data-handling 注記なし）

**判定：leave-as-is**

内部研究用途。実装レイヤー委任として許容。

### A-12（provenance 阻止の検証方法なし）

**判定：leave-as-is**

テスト手法は tasks フェーズの責務。

### A-13（learning/ artifact の世代管理不在）

**判定：must-fix**

foundation 要件 3 AC3 は「versioned schema artifacts、silent incompatible edit 禁止」を要求する。learning/ 配下の proposal yaml・各 register は長期保存前提（要件 5 AC5「learning from failed improvements」）であり、スキーマ進化時に既存 artifact が解釈不能化するリスクがある。versioning 規約への接続（`schema_version` field または evolution policy）が必要。

---

## 集計

| 判定 | 件数 | 番号 |
|------|------|------|
| must-fix | 6 | P-5, P-13, A-1, A-3, A-5, A-13 |
| should-fix | 7 | P-1, P-2, P-10, A-2, A-4, A-8, A-10 |
| leave-as-is | 13 | P-3, P-4, P-6, P-7, P-8, P-9, P-11, P-12, A-6, A-7, A-9, A-11, A-12 |

---

## must-fix 帰属別分類

### dual-reviewer-self-improvement 設計固有（本設計内で修正完結）

- **P-5**：findings/ 配下 artifact の required fields 定義を追加
- **P-13**：manual→runtime 引き継ぎ境界の保存メカニズムを設計に追加（要件 7 AC5 応答）
- **A-1**：Requirements Traceability 表に要件 7・8 の行と対応設計応答を追記
- **A-3**：proposal state の遷移規則（許可遷移と遷移条件）を定義
- **A-5**：adoption_register の required fields を rejection_register / rollback_register と同等粒度で定義
- **A-13**：learning/ 配下 artifact に schema_version field または evolution policy を定義し、foundation 要件 3 AC3 の versioning 規約に接続

### 要件への差し戻し

- なし（要件自体は十分に明確。問題は設計側の応答欠落）

### 他 spec 設計への波及

- なし（A-13 は foundation の versioning 規約を参照するが、foundation 側の修正は不要。self-improvement が自身の artifact を foundation 規約に接続する宣言を追加すれば足りる）
