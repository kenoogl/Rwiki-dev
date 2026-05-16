# 要件フェーズ 横断整合ゲート

## メタデータ

- 実施日：2026-05-16
- 対象：再開中 6 機能の requirements.md（foundation / runtime / evaluation / paper-interface / self-improvement / implementation-governance）
- 契機：仕様修正 must-fix #1〜#8 ＋ 2026-05-16 個別レビュー（評価/論文/自己改善）＋基盤波及・機能固有 must-fix 適用後の横断整合確認
- 方式：claude --print --disallowedTools "Read,Write,Edit"（ファイルアクセス技術的遮断）、独立分析 1 パス
- 分析モデル：claude-opus-4-7
- 手順：REVIEW_PROTOCOL.md 節 4（フィーチャー横断レビューパターン、3 群分類）

---

6 機能の requirements.md を横断点検しました。所見を以下にまとめます（対象文書は英語ですが所見は日本語、表は使わず箇条書きで記述します）。

---

## A 群（確認済みの横断整合）

各機能内で確定済みで、機能をまたいでも矛盾しない点。13 件。要点のみ。

- **最小メタデータと上位メタデータの包含関係**：foundation 要件1 受入5（最小実行メタデータ）を、foundation 要件6 受入2 が「上位集合であり最小集合を拡張する」と明文で述べており、包含関係が一意。
- **共通スキーマ5種の所有と利用**：foundation 要件3 が5種（review_case / finding / impact_score / failure_observation / necessity_judgment）を定義し、runtime 要件4 が準拠出力。とくに runtime 要件4 受入7 が failure_observation を実際に出力させ、「未使用スキーマ」化を防いでいる。
- **プロンプト配置・相対パス・版管理**：foundation 要件4 と runtime 要件3／要件8 受入6 が整合。Step D（統合）は foundation 要件1 受入7 で追加 LLM 呼び出し不要のため、foundation 要件4 がプロンプト雛形を Step A/B/C のみに限定している点も内部整合。
- **treatment（系統＝single/dual/dual+judgment の処理形）語彙の委譲**：foundation 要件1 受入9 が語彙列挙を runtime 要件2 に委譲し、evaluation 要件2・self-improvement・paper-interface が runtime 列挙を正典として参照。
- **phase/profile（審査段階＝intent/requirements/design/tasks）語彙の委譲**：foundation 要件1 受入8 が runtime 要件8 に委譲、evaluation 要件7／要件8 が同じ4段階を参照（ただし「実装」段階の重複については C 群#3 を参照）。
- **証跡区分（valid/invalid/exploratory）語彙の所有**：foundation 要件6 受入8 が所有し、evaluation 要件1 と paper-interface 要件5 受入6 が foundation の正典フィールドへ束縛（再定義しない）。
- **審査様式（手動ドッグフード／runtime 経由）語彙の所有と直交性**：foundation 要件6 受入6 が所有、evaluation 要件1 受入6 が「実行妥当性」と「審査様式」を直交独立軸と明記、self-improvement 要件7・paper-interface 要件6 も準拠。
- **系統別の手順実行・省略の区別**：foundation 要件1 受入4（Step B は同意時も独立反証を残す）、runtime 要件2 受入3/4・要件1 受入4（設計上の省略と事故的欠落の区別）、evaluation 要件2 受入3（系統由来の省略と実行失敗の区別）が一貫。
- **実行締結の順序**：foundation 要件1 受入7（Step D は締結時に消費）、runtime 要件1 受入5・要件5 受入4・要件6 受入9（人手承認→検証→締結の順序固定）が矛盾なし。
- **可搬証跡バンドルの連鎖**：runtime 要件9（搬出）→ evaluation 要件10（中央取込・受入判定）→ self-improvement 要件8（取込元来歴の保全）が責務分離して連結。
- **paper-interface の非逆流**：paper-interface 要件1 受入4／要件4 と runtime の「原則 evaluation 経由」期待が整合。
- **無効化標識の生証跡不改変**：foundation 要件6 受入3 と runtime 要件6 受入3 が一致。
- **self-improvement から foundation への明示参照**：self-improvement 要件1 受入6・要件3 受入7 が foundation 要件6（メタデータ欠落＝検証失敗規則）を明示引用。

---

## B 群（本セッションの個別レビュー＋must-fix で既対応）

直近コミット「foundation/runtime 要件書の must-fix #1〜#8 を適用」および evaluation／paper-interface／self-improvement の reviews/ ディレクトリ生成から、横断にも触れる以下の項目は個別レビュー段階で既に処理済み。記録のみ。

- foundation 要件1 受入8/9 の委譲条項（treatment／phase 二重所有の予防）。
- foundation 要件6 受入2 の「上位集合」明記（最小集合との関係の一意化）。
- foundation 要件1 受入7 の Step D 追加 LLM 不要の明確化。
- runtime 要件6 受入9 の締結順序条項。
- runtime 要件4 受入7 の failure_observation 出力（foundation 要件3 受入8 の孤立スキーマ解消）。
- self-improvement 要件1 受入6／要件3 受入7／要件5 受入6 の foundation メタデータ・無効化契約への明示束縛。
- paper-interface 要件5 受入6 の証跡区分語彙の foundation 一本化。
- evaluation 要件2 受入6（比較集合内の版一様性）・要件1 受入6（直交性）・要件9 受入6（比較母集団規則の所有）。

---

## C 群（今回の横断で初めて顕在化）

3 件。各々を 4 要素で記述する。

### C-1：事後無効化の下流再評価への双方向反映が非対称

- **重大さ**：中
- **対象箇所**：self-improvement 要件5 受入6 ／ evaluation 要件3 受入4・要件5 受入2 ／ paper-interface 要件1 受入4・要件4 受入3
- **説明**：self-improvement 要件5 受入6 は「採用済み改善の根拠証跡が後から無効化されたら再評価または巻き戻しを起動する」と一方向の事後反映を明示している。一方、evaluation には「過去に有効だった実行が後から無効化されたとき、それを参照した派生成果物を陳腐化扱いまたは再導出する」起動条件がない。paper-interface 要件1 受入4 は「evaluation 出力が存在しないとき再実行を要求」するだけで、出力は存在するが上流無効化で陳腐化した場合を扱わない。結果として、無効化済み実行を含む evaluation 派生成果物の上に paper 成果物が陳腐化したまま残りうる。
- **根拠**：self-improvement 要件5 受入6 が事後無効化トリガを持つのに対し、evaluation 要件3 受入4 は「スキーマ互換の生証跡が不変なら再計算を許可」と受動的許可にとどまり、paper-interface 要件1 受入4 の再実行要求条件が「出力非存在」限定であること。
- **横断修正方針**：foundation 要件6（無効化契約）に「無効化標識付与は下流派生成果物への陳腐化伝播トリガを伴う」旨を1条追加し、evaluation 側に「参照実行が事後無効化されたら該当派生成果物を陳腐化フラグ付けまたは再導出」、paper-interface 側に「上流陳腐化時は再生成必須」を対応付ける。self-improvement 要件5 受入6 と対称化する。

### C-2：heuristic_profile_ref／最小ヒューリスティック雛形の所有者欠落

- **重大さ**：中〜高
- **対象箇所**：foundation 要件5（削除済み）／ runtime 要件10（削除済み）／ implementation-governance 要件8 受入4・受入5、要件5・要件6 受入6
- **説明**：foundation 要件5 は「パターン関連の資産配置規約を本 spec の責務から外す」、runtime 要件10 は「規則ファイル参照（heuristic_profile_ref）と種パターン照合は v2 で実 LLM 呼び出しに置換、トラック検証は v2 取得 spec で再設計」と、ともに削除されている。ところが implementation-governance 要件8 受入4 は依然「heuristic_profile_ref を省略可とし、runtime はトラック別の repo 内最小雛形を既定で使う」と現行 runtime の既定挙動として要求し、受入5 は「ヒューリスティック方針メモとトラック別最小雛形の正典参照」を要求、要件5／要件6 受入6 の検証エントリがその実体ファイルの存在検査を求める。所有者が runtime から外れ v2 取得 spec（今回の点検対象6機能に含まれない）へ移動したため、governance が所有者不在の契約を参照している。
- **根拠**：runtime 要件10 削除文が heuristic_profile_ref と最小雛形を runtime 責務外と明言し再設計先を v2 取得 spec に指定しているのに対し、governance 要件8 受入4 が同じ概念を「runtime の既定」として能動要求し、要件5 受入4・要件6 受入6 が実体検査を課していること。
- **横断修正方針**：governance 要件8 の受入4/5 と検証要件（要件5・要件6 受入6）で、ヒューリスティック既定挙動と最小雛形の正典所有者を「v2 取得 spec」と明示再帰属し、runtime への帰属表現を除去する。v2 取得 spec 側の語彙確定までは governance 検証エントリが当該実体を必須検査しないよう条件節を付す（さもないと governance 要件5 受入4「検証を通過する具体成果物の提供」が所有者不在の対象で要求され、実装不能化のおそれ）。

### C-3：「phase（段階）」語彙の二重使用

- **重大さ**：低〜中
- **対象箇所**：implementation-governance 要件7 受入5 ／ runtime 要件8 受入1 ／ evaluation 要件7 受入2・要件8 受入5
- **説明**：foundation 要件1 受入8 が phase/profile 語彙を runtime（4値：intent/requirements/design/tasks）に委譲する一方、governance 要件7 受入5 は自身の phase-review メトリクス登録簿に「implementation」を加えた5段階を正典として定義する。evaluation 要件7 受入2 の段階別スライスは runtime の4段階前提、evaluation 要件8 受入5 は実装志向審査を将来拡張扱い。同じ「phase」語が、runtime 所有の審査プロファイル（4値）と governance 所有の phase-review メトリクス（5値）を指し、横断でメトリクスを跨ぐと4対5の取り違えが起こりうる。
- **根拠**：foundation 要件1 受入8 の委譲先語彙が4値であるのに対し、governance 要件7 受入5 が独自登録簿で5値（実装を含む）を正典化し、evaluation 要件8 受入5 が実装審査を「将来拡張」と位置づけて段階数が一致しないこと。
- **横断修正方針**：governance 要件7 受入5 に「ここでの implementation は governance 所有の phase-review メトリクス値であり、runtime の phase/profile 語彙値ではない」旨の1文を追加し、evaluation／paper-interface が runtime 段階スライスへ「implementation」を期待しないよう曖昧性を断つ。

---

## 不整合（受入基準違反・実装不可能）

- **0 件。** 受入基準どうしが直接矛盾する箇所、または単独で実装不能となる箇所は、点検対象6機能の範囲内では検出されなかった。最も矛盾に近いのは C-2（所有者不在参照）であり、これは厳密な受入基準衝突ではなく失効した横断参照のため C 群に分類し、重大さを中〜高へ引き上げて扱った。

---

要約：横断整合は概ね良好で、確認済み13点・既対応8点。新規顕在化は3件（事後無効化の下流双方向反映の非対称＝C-1、ヒューリスティック所有者欠落＝C-2、phase 語彙二重使用＝C-3）で、いずれも横断修正方針を併記しました。厳密な不整合は0件です。
