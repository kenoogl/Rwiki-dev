# dual-reviewer 論文草稿 — first prose draft

_作成: 2026-05-12_  
_status: draft v0.2_  
_scope: Chapter 1-11 working draft_

---

## Chapter 1. Introduction

LLM を使った review 研究は、コードレビューの精度や finding の数に関心が集まりやすい。しかし実際の開発では、問題はコードだけで起きるわけではない。`intent` しかない初期段階では、何を作るべきかの理解が揺れやすい。`requirements`、`design`、`tasks` と文書が増えるにつれて、確認すべき論点も増える。さらに implementation と review の段階では、反対意見、注意点、手戻りの必要性が途中で落ちやすい。したがって本当に難しいのは、reviewer が何件の指摘を出すかではなく、`intent` から implementation までの流れをどう保つか、そして途中で出た論点をどう残すかである。

本研究は、この問題に対して `dual-reviewer` を code review assistant ではなく、**意図駆動開発を支えるワークフロー支援システム** として捉える。中心に置くのは、adversarial reviewer と judgment reviewer の組合せそのものではない。重要なのは、それらを gate、reopen、conformance summary、signal register、reporting interface と組み合わせ、開発の流れ全体を崩さずに運用できるかである。言い換えると、本研究が見たいのは finding 生成だけではなく、phase ごとの review をどう進め、どの論点を次の段階へ引き渡せるかである。

本論文の貢献は 3 つある。第一に、`Intent Track`、`Spec Track`、`Implementation Track` の 3 層からなる評価枠組みを示し、`intent-only`、`spec-present`、`implementation-present` という異なる開始条件を同じ枠組みで扱う。第二に、finding だけでなく handback、reopen、caveat、disposition、downstream obligation を成果物として残す review workflow を示す。第三に、その成果物を reporting と self-improvement に再利用できる形で接続する。

本論文で強く支えるのは、ワークフローが保たれること、証跡が残ること、複数の開始条件で回せること、の 3 点である。人間の認知負荷をどれだけ下げたか、あるいは一般に software quality をどれだけ改善したかは、補助的に触れるに留める。以降では、まずシステムの考え方とワークフローを説明し、その後で claim ごとの証拠を定義し、`F1` を主線、`heat3d` を橋渡しケース、`iot-arduino` を補助ケースとして結果を示す。

---

## Chapter 2. Related Work And Positioning

LLM を使った code review の研究は、主にコード上の finding をどれだけ増やせるか、あるいは指摘の質をどこまで高められるかに焦点を当ててきた。これは重要な方向だが、開発の流れ全体を扱うには不十分である。実際の開発では、問題は `intent` が曖昧な段階から始まり、`requirements`、`design`、`tasks` と下る途中で形を変える。したがって code review 単体の改善だけでは、途中で落ちる論点や手戻りの管理までは説明できない。

複数 reviewer や debate 型の研究は、単独 reviewer より多くの候補を出しやすいという点で有用である。しかし多くの場合、焦点は candidate expansion にある。どの段階で人間に戻すか、どこまで handback するか、reopen をどう記録するか、そしてその結果を次の phase にどう渡すかまでは十分に扱われない。言い換えると、複数 agent の構成はあっても、phase-aware な運用契約までは明示されないことが多い。

一方、requirements や設計を支援する研究は、上流文書の質を高める点で重要である。だが、そうした支援が implementation/review phase まで同じ枠組みでつながるとは限らない。上流では文書支援、下流では code review、と別々の問題として扱われやすいからである。その結果、requirements で出た注意点が design や tasks にどう伝わったか、あるいは implementation で見つかった問題が本当に code issue なのか spec/design の拘束不足なのかを、同じケースの中で追いにくい。

traceability や provenance を重視する研究もある。これは、どの成果物がどの入力や判断に支えられているかを残すうえで重要である。ただし、証跡を残すこと自体と、review workflow を運用することは別問題である。本研究が狙うのは、この 2 つを切り離さないことである。つまり、review の進行、handback、reopen、conformance summary、signal linkage、reporting provenance を同じ artifact chain の中で扱う。

したがって本研究の位置づけは、より良い code review model を作ることでも、requirements 支援だけを行うことでもない。意図駆動開発の流れ全体を対象にし、review をその流れの中で管理し、さらに得られた証跡を後で再利用できるようにすることにある。この点で本研究は、code review assistant 論文というより、workflow support と evidence preservation の論文として読むのが適切である。

---

## Chapter 3. System Framing And Design Goal

`dual-reviewer` は、複数の LLM reviewer を並べただけの仕組みではない。設計の中心にあるのは、各段階で何を review し、どこで人間の判断に戻し、何を次の段階へ残すかを決めるワークフローである。adversarial review は、見落とされやすい候補を広げるために使う。judgment review は、増えた候補を整理し、どれを残すかを決めるために使う。これらは単独で働くのではなく、workflow-gate-status、ACTIVE_WORKLIST、execution control ledger、conformance summary、signal linkage などの周辺成果物と一体で機能する。

このシステムが直接支えようとするのは、`intent-only`、`spec-present`、`implementation-present` の 3 つの開始条件である。`Intent Track` では `intent` を出発点にして `requirements / design / tasks` への伝播を助ける。`Spec Track` では、すでにある spec を見直し、reopen や alignment を管理する。`Implementation Track` では、承認済みの upstream artifact と implementation acquisition、さらにその後の修正履歴を結びつける。重要なのは、利用者が毎回細かい停止条件を指示しなくても、システムが既定で「次の human gate まで進む」ことである。これにより、人間は作業の運転役ではなく、判断役に集中できる。

同時に、本論文の主張の境界もここで明確にしておく。第一に、全ドメインへの一般化は主張しない。今回のケースは simulation 系と embedded/event-driven 系に偏っている。第二に、correctness proof は主張しない。`heat3d` では reduced validation を通った一方で reference behavior との差が残っている。`iot-arduino` でも hardware-ready な妥当性までは扱わない。第三に、人間の認知負荷を有意に下げたという強い主張もしない。ここで言えるのは、システムが review attention を段階ごとに整理し、論点が途中で落ちにくいように設計されていることまでである。

このように整理すると、本研究の新しさは「より良い code review model」ではなく、「意図駆動開発を支えるワークフローと証跡の仕組み」にある。以降の章では、その仕組みがどんな成果物を持ち、どの claim をどのケースで支えるかを具体的に示す。

---

## Chapter 4. Workflow And Artifact Contract

dual-reviewer の基本的な流れは、`intent -> requirements -> design -> tasks -> implementation -> review acquisition` である。ただし、これは単純な waterfall ではない。各段階には feature-local review、phase review wave、feature 間 alignment gate、human gate が入る。新しいケースの開始時には、短い指示だけでよい。システムは source document を読み、現在の理解を固定し、active feature set を提案し、次の gate input まで進む。`requirements wave`、`design wave`、`tasks wave` も同様で、それぞれ「文書を書くだけ」ではなく、その段階の review、alignment、gate package 準備を含む。

この流れを支える制御用の成果物として、本研究では `workflow-gate-status`、`ACTIVE_WORKLIST`、`ECL` を重視する。`workflow-gate-status` は phase と approval state の正本である。`ACTIVE_WORKLIST` は、現在の blocker と次の作業を示す制御板である。`ECL` は、実行上の制約や例外を記録する ledger である。ここで reopen や handback が大事なのは、単に枝分かれが起きるからではない。重要なのは、「どこまで戻るか」「何が未解決か」「何を下流へ渡すか」が明示的に残ることである。

review の出力も finding list だけでは終わらない。runtime と protocol 層では、review artifact、decision units、invalidation markers、invalid-run triage note、conformance summary、comparison eligibility note、signal linkage note が生成される。paper interface はこれらを provenance として参照し、self-improvement 側は signal intake、pattern candidate、remediation template へ接続する。つまり dual-reviewer の成果物は、一回きりの対話ログではなく、後続処理に使える構造化データである。

本論文で特に重視するのは、指摘の数そのものよりも、論点を失わずに残せることである。handback、caveat、disagreement、downstream obligation、rework trace をどこまで保てるかが、システムの価値を決める。この考え方が、次章以降の評価設計と case tier にそのままつながる。

---

## Chapter 5. Evaluation Design And Evidence Basis

### 5.1 Claim set and interpretation boundary

本論文では、finding quality だけでなく、ワークフローの質と証跡の質も見る。ここでいうワークフローの質とは、各段階の review を適切な gate で止め、handback、reopen、alignment を残したまま下流へ進められるかである。証跡の質とは、finding だけでなく caveat、disagreement、disposition、downstream obligation を失わずに保持し、それを後続の reporting や self-improvement に使えるかである。

この観点から、本論文の claim は 4 つに整理する。`Claim 1` は、dual-reviewer が下流工程で review attention を整理し、cognitive brittleness を緩和するよう設計されている、という設計意図に関する claim である。`Claim 2` は、finding だけでなく disagreement、caveat、disposition、handback depth を traceable に残せるという claim である。`Claim 3` は、`intent-only`、`spec-present`、`implementation-present` の異なる開始条件でも workflow を維持できるという claim である。`Claim 4` は、review の成果を self-improvement と reporting に再利用できるという claim である。

このうち、本文で強く支えるのは `Claim 2-4` である。`Claim 1` は補助的な framing として扱い、認知負荷を有意に下げたといった強い効能主張にはしない。ここで言いたいのは、dual-reviewer が phase ごとの論点を整理し、途中で失われにくくする設計になっている、ということである。そのため、本論文の中心は efficacy paper ではなく、ワークフローと証跡のシステムにある。

### 5.2 Case classes

評価 case は 3 種類に分ける。`Intent-origin` case は、明示的な `intent` を最上位入力に持ち、そこから `requirements`、`design`、`tasks` への伝播を観測できるケースである。`Spec-origin` case は、`intent` を持ちながら開始点が `requirements / design / tasks` にあるケースであり、既存 spec の refinement、reopen、alignment を観測する。`Implementation-origin` case は、upstream `intent/spec` と結びついた implementation artifact から始まり、review acquisition、conformance summary、downstream rework trace を観測する。

この分け方は、単なる分類ではない。各 claim を支えるための条件でもある。`Claim 1` の主証拠は `Intent-origin` case に限る。これは、認知的な難しさが最も強く現れるのが、`intent` を下流の detail に落としていく局面だからである。`Claim 3` を言うには、3 つの開始条件が少なくとも一度ずつ acquisition-backed に成立していなければならない。`Claim 4` には implementation artifact が必要だが、見るのは code quality そのものではなく、証跡が再利用できるかどうかである。

逆に、本論文で main evidence にしない case も定義する。`intent` がない case、review 用に上流 spec が固定されていない case、あるいは code-only snapshot は main evidence にしない。これらは補助的な歴史的記録としては使えても、意図駆動ワークフローの主張を直接支えるケースにはならない。

### 5.3 Selection-driven analysis basis

本研究では、analysis の対象をその場で選ばない。selection manifest で固定した protocol-backed run set に基づいて evaluation と paper artifact を再生成する。各 manifest は `track`、`case_id`、`phase_profile`、`protocol_root`、`review_modes`、`treatments` を持ち、selector はそれに一致する closed runtime run だけを集める。こうすることで、analysis の母集団と paper の根拠が明確につながる。

この仕組みには 2 つの意味がある。第一に、現在の `experiments/analysis` と `paper/reports` が、どの run 群に基づいているかを成果物として示せる。第二に、同じ case でも protocol root を分ければ、旧 batch と再取得 batch を混ぜずに扱える。`F1-phase-field-cpp` ではこの点が重要だった。旧 batch では `dual` の protocol artifact は残っていたが、対応する closed runtime run が current tree に存在しなかった。そのため旧 selection manifest では `single` と `dual+judgment` しか採用できなかった。これに対して `F1-phase-field-cpp-r2` では fresh protocol root を切り、`single`、`dual`、`dual+judgment` の 3 treatment を runtime-backed に再取得したことで、比較の土台をきれいに作り直せた。

selection-driven analysis のもう一つの役割は、coverage を示すことである。analysis manifest には `runtime_validation_summary_coverage` を記録し、input run 数に対して protocol-facing summary がどれだけ揃っているかを示す。これにより、paper 側で provenance が空になることを見落とさず、分析の土台そのものの完全性を成果物として残せる。本論文では、main line に使う case はすべて protocol-backed run set と coverage artifact を持つものに限定する。

### 5.4 Tiering of evidence

以上を踏まえ、本論文の case tier は 4 層に固定する。main upstream line は `F1-intent-dual-reviewer-rebuild` と `F1-phase-field-reverse-spec` である。これらは `Intent-origin` と `Spec-origin` の主証拠であり、上流 bootstrap と中流 refinement を acquisition-backed に示す。main implementation comparison line は `F1-phase-field-cpp-r2` である。これは `single / dual / dual+judgment` を runtime-backed に揃えた clean 3-treatment package であり、implementation track における treatment 差を最も素直に読める。

これに対して `F2-heat3d-julia` は bridge case として扱う。`heat3d` は単なる second implementation case ではない。`Spec-origin / Implementation-origin` の両方を持ち、restart、reopen、readability recheck、review acquisition、actual implementation、reduced validation、behavioral-boundary judgment を 1 本の長い trace に束ねている。このため `heat3d` は、ワークフローが回ったこと、implementation 起点の evidence が得られたこと、証跡が再利用できること、そして spec/design の拘束が足りない可能性を露出したことを、同時に示す。

最後に `F3-iot-arduino` は supporting line である。これは external `intent.md` と `仕様.md` からケースを起動し、feature recomposition、tasks-approved implementation entry、review acquisition、two-snapshot implementation acquisition を通したケースである。ここでの読みは hardware-ready adequacy ではない。stable safety finding と preserved caveat が implementation-local refinement 後も保たれたことにある。したがって本文では、`F1 upstream`、`F1-phase-field-cpp-r2`、`F2 heat3d` を主線とし、`F3 iot-arduino` は一般化を補う補助 evidence として位置づける。

---

## Chapter 6. Main Longitudinal Case: F1

### 6.1 Intent Track: F1-intent-dual-reviewer-rebuild

`F1-intent-dual-reviewer-rebuild` は、`intent-only` 開始条件で dual-reviewer workflow が成立するかを見る最初の上流ケースである。ここで重要なのは、`intent` を review した結果、単に finding が増えるかではなく、どの論点を下流へ伝えるべきかが成果物として残るかである。fresh batch では `single_review` が `2` finding、`0` handback だったのに対し、`dual_reviewer_workflow` は `3` finding、`1` handback となり、`dual_requires_intent_handback = true` が記録された。両 treatment とも propagation target は `requirements`、`design`、`tasks` であり、問題は「次の段階で見直すべきこと」として明示された。

この結果が示すのは、dual-reviewer の価値が単なる finding 数の増分に尽きないことである。`single_review` では懸念が finding の列挙に留まりやすいが、`dual_reviewer_workflow` では handback requirement が残り、`intent` をそのまま下流へ流してよいかが gate judgment として保存される。つまり `Intent Track` の役割は、「上流で止めるべきものを downstream に押し流さない」ことを traceable に示す点にある。

本論文では、この case を `Claim 1` と `Claim 3` の上流側主証拠として使う。ただし、ここで言えるのは first-batch level の workflow support までであり、大規模な intent review benchmark を与えるわけではない。本文では、`intent-only` でも artifact-preserving workflow が成立したことと、dual workflow では handback obligation が明示的に残ったことを中心に述べる。

### 6.2 Spec Track: F1-phase-field-reverse-spec

`F1-phase-field-reverse-spec` は、既存の `requirements / design / tasks` を持つ `Spec-origin` case として、refinement、reopen、alignment を acquisition-backed に示すケースである。fresh batch では `single_review` と `dual_reviewer_workflow` の双方で `phase_blocking_issue_count = 1`、`phase_reopen_required_count = 1` が残った。これは、reopen の必要性そのものは reviewer style に依存せず保持されたことを示す。一方で dual workflow では `phase_nonblocking_open_point_count = 2`、`phase_major_correction_count = 1` となり、single より強い correction obligation が見える。

ここで重要なのは、dual workflow が reopen を増やしたというより、同じ reopen boundary の中で correction の質を変えたことである。single では handback class が `A`、major correction は `0` に留まるが、dual では handback class が `B`、major correction は `1` になる。さらに `phase_intent_attributed_issue_count = 1` は両 treatment で共通しており、問題が implementation detail ではなく upstream intent contract に接続されていることも保たれた。したがって `Spec Track` の価値は、detail が増えた段階でも reopen、major correction、intent attribution を成果物として残せることにある。

このケースは `Claim 2` と `Claim 3` の中流側主証拠として機能する。`Intent Track` が propagation obligation を示し、`Spec Track` が reopen と alignment の obligation を示す。両者を合わせることで、上流から中流への workflow continuity が acquisition-backed になる。

### 6.3 Implementation Track: F1-phase-field-cpp-r2

`F1-phase-field-cpp-r2` は、`F1` 系統の implementation line を clean 3-treatment package として再取得したケースである。original `F1-phase-field-cpp` では protocol artifact と comparison summary は残っていたが、`dual` の closed runtime run が current tree から失われていたため、default population には `single` と `dual+judgment` しか入れられなかった。そこで `F1-phase-field-cpp-r2` では fresh protocol root を切り、original first snapshot を同条件で再取得した。

再取得の結果、`single_review` は `2` finding、`dual_review` は `3` finding、`dual_reviewer_workflow` は `3` finding となった。つまり `dual_minus_single_findings = +1` であり、adversarial reviewer を加えることで候補が 1 件増えた。一方 `dual_plus_judgment_minus_dual_only_findings = 0` であり、judgment phase は finding 数を増やさず、候補の整理を trace-bearing な判断記録へ変換した。この形は、adversarial review が候補の拡張に効き、judgment review が候補の整理に効くという本研究の読みと整合する。

さらに、`dual_review` と `dual_reviewer_workflow` はどちらも `adversarial_reviewer` を source role に含むが、後者だけが `judgment_ref_present = 3` を持つ。したがって `F1-phase-field-cpp-r2` は、`single`、`dual`、`dual+judgment` の 3 treatment を揃えたうえで、adversarial contribution と judgment-bearing trace の違いをきれいに観測できる。この点で `F1-phase-field-cpp-r2` は、本論文の implementation track における最も素直な比較ケースである。

### 6.4 F1 as the main longitudinal line

`F1` の重要性は、3 つの track が同じ系統のケースとして繋がっている点にある。`F1-intent-dual-reviewer-rebuild` は `intent-only` から始まり、propagation obligation を残した。`F1-phase-field-reverse-spec` は `spec-present` から始まり、reopen と major correction の保持を示した。`F1-phase-field-cpp-r2` は `implementation-present` から始まり、clean 3-treatment comparison を runtime-backed に示した。したがって `F1` は、本論文のもっとも強い longitudinal evidence line である。

このため、本文の中心は `F1` に置くのが妥当である。`F1` だけで `Intent-origin`、`Spec-origin`、`Implementation-origin` の 3 開始条件が揃い、implementation line では `single / dual / dual+judgment` の clean comparison まで含められるからである。`heat3d` はこの主線を置き換えるものではなく、次章で解釈の深さを与える bridge case として使う。`iot-arduino` は別ドメインへの移植性を補う supporting case として使う。したがって論文全体の backbone は `F1` であり、残りのケースはその backbone を補強する位置づけになる。

---

## Chapter 7. Bridge Case: F2 heat3d

### 7.1 Why heat3d is not just another implementation case

`heat3d` は、`F1-phase-field-cpp-r2` の代わりになる比較ケースではない。ここで重要なのは、`Spec-origin` と `Implementation-origin` の両方を 1 つのケースに重ねている点である。`heat3d` では canonical source から `intent` を作り、single-feature 前提の不適切さを見つけて discovery に戻し、その後 multi-feature decomposition へ組み直したうえで、`requirements`、`design`、`tasks`、`review acquisition`、`actual implementation` までを 1 本の case lineage として追えている。

この長い trace には、単純な implementation comparison では得られない情報が含まれる。restart、reopen、readability recheck、gate approval、review acquisition、implementation-local rework、validation-boundary judgment が同じケースの中に並ぶからである。したがって `heat3d` の役割は、「3 treatment で何件差が出たか」を示すことより、「意図駆動ワークフローが actual implementation 到達まで保たれたか」を示すことにある。

### 7.2 Workflow validity and implementation arrival

`heat3d` の phase evidence では、requirements で `6 findings / 6 blocking / 6 fixed / 1 recheck`、design で `7 findings / 7 blocking / 7 fixed`、tasks で `6 findings / 6 blocking / 6 fixed` が記録されている。ここで大事なのは数そのものより、上流で差し戻しが起きてもワークフローが崩れず、次の gate に向けて成果物が更新され続けた点である。single-feature 開始が不適切と判明して discovery に戻したこと、review-before-gate を破った request を reopen したこと、readability 指摘を受けて requirements prose を平易な日本語へ書き直したことは、その具体例である。

review acquisition の後も、この流れは続く。`heat3d` は approved `requirements / design / tasks` を upstream bundle として `single / dual / dual+judgment = 2 / 3 / 3` の acquisition を取り、その後 actual implementation に進んだ。implementation-phase では coding-layer blocking issue が `3` 件観測されたが、それらは module boundary、guard-cell material contract、project configuration に閉じており、upstream reopen は `0` 件だった。つまり `heat3d` は、review acquisition と actual implementation を同じ governance contract の下に接続できた bridge case である。

### 7.3 Underconstraint exposure

`heat3d` を bridge case として特に重要にしているのは、reduced validation を通過しながら reference behavior mismatch が残った点である。この観測は、implementation defect をすぐに断定するよりも、approved spec/design が所望の挙動を十分には拘束していなかった可能性を示している。言い換えると、`heat3d` は implementation-origin evidence であると同時に、spec/design underconstraint exposure の evidence でもある。

この解釈は、本論文の claim boundary にも関わる。本文で強く言うのは、`heat3d` が workflow validity、implementation-origin evidence、evidence reuse、underconstraint exposure を同時に示すことまでである。reference behavior mismatch の責任分解そのもの、つまり code deviation なのか spec/design underconstraint なのかは本稿では確定しない。その切り分けは `v3` の code-conformance line に委ねる。こうすることで `heat3d` は、correctness proof case ではなく、解釈の幅を持つ橋渡しケースとして位置づけられる。

### 7.4 Reusability role

`heat3d` のもう一つの価値は、review evidence が downstream reuse にそのまま接続されることである。implementation track で観測された `boundary`、`update-order`、`parameter-caveat` は `phase-field` と共通する finding pattern として報告できる。一方 behavior mismatch は supplementary behavioral evidence と future conformance evaluation の両方に再利用できる。つまり `heat3d` は、review acquisition の結果を reporting と future evaluation にどう渡すかを最も豊かに示すケースである。

---

## Chapter 8. Supporting Case: F3 iot-arduino

### 8.1 Why the case is included

`iot-arduino` は、本論文の primary core case ではない。位置づけは generalized first implementation case であり、event-driven / embedded domain transfer を補う supporting case である。それでも paper から外さない理由は、external `intent.md` と `仕様.md` を seed にして、reference-free bootstrap からケースを起動し、requirements、design、tasks、review acquisition、two-snapshot implementation acquisition までを 1 本の case lineage で通したからである。

さらに `iot-arduino` は、実運用で重要な 2 つの振る舞いを見せた。第一に、開始指示が短くても `intent-fixed` から次の human gate まで自然に進めたこと。第二に、最初の feature decomposition 提案がそのまま通らず、人間が実質 reject し、対話の中で `6 feature` から `2 feature` へ再構成したことである。これは dual-reviewer が提案を機械的に積み増すのではなく、人間の介入を含む形で feature 粒度を調整できることを示している。

### 8.2 What happened in the case

requirements phase では最初の `6 feature` 分割が細かすぎると判断され、`loop-outside-control` と `watering-loop` の 2 feature に畳み直された。design phase では `loop entry -> loop outcome -> final status` の handoff chain と thin entrypoint rule が固定された。tasks phase では implementation order、shared owner、smoke ordering が固定された。その後 review acquisition gate を通し、first snapshot に対して `single / dual / dual+judgment = 2 / 3 / 3` を取得した。

続く second snapshot では、`restart boundary` の persistence/time-sync seam、`relay fail-safe` の single finalization path、`telemetry warning-return boundary` を明示したうえで、再度 `single / dual / dual+judgment = 2 / 3 / 3` を取得した。ここで重要なのは、この結果を `refinement failed` と読むべきではないことである。むしろ safety-sensitive contract と operational caveat が implementation-local refinement の後も静かに消えなかった、と読むべきである。

### 8.3 What the case supports

このケースが支えるのは 3 点である。第一に、event-driven IoT domain でも gate-based workflow と成果物の保持が成立すること。第二に、external intent/spec seed から generalized first case を起動できること。第三に、stable safety finding と preserved caveat が two-snapshot loop 後も保持されること。ここで stable safety finding と呼ぶのは `restart boundary` と `relay fail-safe`、preserved caveat と呼ぶのは `telemetry non-blocking / stub boundary` である。

逆に、このケースで主張しないことも明確である。`iot-arduino` は hardware-ready implementation quality を示さない。real WiFi/NTP、EEPROM/RTC、OLED/Blynk、ISR wiring の妥当性は current boundary の外にある。したがって本文では、`iot-arduino` を workflow continuity、domain transfer、signal stability、caveat retention を支える supporting line としてのみ扱う。

---

## Chapter 9. Cross-Track Discussion

### 9.1 Claim 2: traceability as the primary strength

cross-track で最も強いのは `Claim 2` である。`F1-intent-dual-reviewer-rebuild` では handback obligation が残り、`F1-phase-field-reverse-spec` では reopen と major correction が残り、`F1-phase-field-cpp-r2` と `F2-heat3d-julia` では implementation-phase finding、caveat、downstream rework trace が残った。さらに `F3-iot-arduino` では、implementation-local refinement 後も safety-sensitive finding と caveat が保持された。共通しているのは、dual-reviewer が finding だけを返すのではなく、下流へ持ち越すべき論点を成果物として残すことである。

この意味で、本研究の主たる強みは detection efficacy より preservation efficacy にある。dual workflow は問題を見つけるだけでなく、どこに戻るか、何を保留するか、何が caveat として残るかを trace structure に変える。これは `Intent Track`、`Spec Track`、`Implementation Track` のすべてで観測された。

### 9.2 Claim 3: multiple-entry viability as existence proof

`Claim 3` について本論文が示すのは、広い一般化ではなく existence proof である。`F1-intent-dual-reviewer-rebuild` は `intent-only`、`F1-phase-field-reverse-spec` は `spec-present`、`F1-phase-field-cpp-r2` と `F2-heat3d-julia` は `implementation-present` の workflow を acquisition-backed に成立させた。`F3-iot-arduino` は、その構図が external seed を持つ generalized case でも成り立つことを補助的に示した。

ただし、ここで言えるのは first-batch level の viability までである。ケース数はまだ少なく、domain も simulation / embedded に偏る。したがって本文では「dual-reviewer はどんな開始条件でも一般に機能する」と強く言うのではなく、「今回のケース集合では、複数の開始条件の下で artifact-preserving workflow を維持した」と述べるに留める。

### 9.3 Claim 4: evidence reuse and downstream reuse

`Claim 4` は implementation track を中心にかなり強く支えられる。`F1-phase-field-cpp-r2` は clean 3-treatment package として treatment 差の reporting に使える。`heat3d` は workflow validity と underconstraint exposure の両方を paper-facing note と `v3` evaluation line に再利用できる。`iot-arduino` は stable safety finding と preserved caveat の具体例として supporting note に再利用できる。加えて、system 側では runtime validation summary、triage note、signal intake、proposal/backtest、paper-interface provenance がすでに繋がっているため、review evidence は一回限りのログではなく、後続の利用先を持つ構造化成果物になっている。

ここでの reuse には 2 種類ある。第一は narrative reuse であり、review artifact を paper claim や method note に接続する使い方である。第二は operational reuse であり、signal inventory、self-improvement、remediation template、runtime triage に接続する使い方である。本研究の特徴は、この 2 種類の reuse を同じ成果物の契約の上で扱っている点にある。

### 9.4 Claim 1: weak wording only

`Claim 1` だけは本文で強く押し出さない。dual-reviewer が human cognitive burden を有意に下げた、あるいは一般に software quality を改善した、という強い効能主張には今の evidence は足りない。必要なのは human study や broader quality benchmark であり、現在の artifact-centered evaluation とは別のコストがかかる。

それでも `Claim 1` を完全に捨てる必要はない。現在の evidence から安全に言えるのは、dual-reviewer が review attention を段階ごとに整理し、handback、reopen、caveat、judgment を可視化することで brittle downstream review を緩和するよう設計されている、という水準である。したがって本文では、`support`、`structure`、`mitigate` の語で補助的に触れ、中心主張は `Claim 2-4` に置く。

---

## Chapter 10. Limitations And Future Work

本研究の第一の限界は、case 数がまだ少ないことである。`Intent Track`、`Spec Track`、`Implementation Track` の 3 開始条件は acquisition-backed に成立したが、`Intent` と `Spec` 側の支えはなお first-batch level に留まる。したがって本論文は、成熟した benchmark comparison を与えるものではなく、artifact-preserving workflow が複数の開始条件で成立した existence proof として読むべきである。より広い domain-general regularity や large-N の process pattern を議論するには、追加の比較と集計が必要である。

第二の限界は、implementation domain と adequacy boundary にある。`heat3d` は workflow validity と underconstraint exposure を強く示すが、behavior mismatch の責任所在はまだ確定していない。`iot-arduino` は event-driven transfer を示すが、current boundary は snapshot-based review に留まり、real WiFi/NTP、EEPROM/RTC、ISR、OLED/Blynk を含む hardware-ready adequacy は主張しない。したがって本論文の implementation evidence は correctness proof ではなく、ワークフローを保った implementation review として読む必要がある。

第三の限界は、efficacy claim の強さにある。human cognitive load reduction や general software quality improvement を主張するには、human study、broader benchmark、external quality oracle が必要である。現在の evidence basis は、そのために設計されたものではない。したがって今後の課題は、cross-track metric aggregation を進めること、case coverage を広げること、そして `v3` code-conformance line により `code ↔ tasks/design/requirements` の責任分解を行うことの 3 つに整理できる。

---

## Chapter 11. Conclusion

本論文は、`dual-reviewer` を code review assistant ではなく、意図駆動開発を支えるワークフローと証跡のシステムとして位置づけた。`Intent Track`、`Spec Track`、`Implementation Track` の 3 層を通じて、dual-reviewer は `intent-only`、`spec-present`、`implementation-present` の異なる開始条件で、成果物を保ったままワークフローを維持できることを示した。特に `F1` 系統では、上流 bootstrap、中流 refinement、下流 implementation comparison が同じ系統のケースとして繋がり、本研究の main longitudinal line を構成した。

さらに本研究は、finding 数だけでなく handback、reopen、caveat、disposition、downstream obligation、rework trace を構造化成果物として残す review workflow を示した。`F1-phase-field-cpp-r2` は clean 3-treatment implementation comparison case として adversarial と judgment の寄与を分けて読めることを示し、`heat3d` は workflow validity、implementation-origin evidence、evidence reuse、spec/design underconstraint exposure を束ねる bridge case として機能した。`iot-arduino` は generalized supporting case として、event-driven domain への移植性と stable safety finding / preserved caveat を補った。

したがって本論文が確実に示したのは、dual-reviewer が意図駆動ワークフローを支え、review evidence を保ち、複数の開始条件の下で downstream reuse 可能な成果物の連鎖を維持できることである。一方で、strong efficacy、universal quality improvement、correctness proof は本稿の claim boundary の外にある。今後は、より広いケース群と code-conformance line を通じて、このワークフローと証跡の仕組みの一般性と責任分解をさらに精密にする。

---

## Evidence Refs For Current Draft

- [claim-case-matrix.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/claim-case-matrix.md:1)
- [dual-reviewer-spec-driven-preliminary-report.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/dual-reviewer-spec-driven-preliminary-report.md:1)
- [cross-track-narrative-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/cross-track-narrative-note.md:1)
- [analysis-run-set-selection-policy.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/analysis-run-set-selection-policy.md:1)
- [F1-selection-rollout-status-2026-05-12.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/F1-selection-rollout-status-2026-05-12.md:1)
- [F1-phase-field-cpp-r2-rollout-status-2026-05-12.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/docs/coordination/F1-phase-field-cpp-r2-rollout-status-2026-05-12.md:1)
- [F1-intent-dual-reviewer-rebuild comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/intent-track-runs/F1-intent-dual-reviewer-rebuild/comparison_summary.json:1)
- [F1-spec-phase-field-reverse-spec comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/spec-track-runs/F1-spec-phase-field-reverse-spec/comparison_summary.json:1)
- [F1-phase-field-cpp-r2 comparison summary](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/implementation-track-runs/F1-phase-field-cpp-r2/comparison_summary.json:1)
- [heat3d-c3-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-c3-evidence-bundle.md:1)
- [heat3d-main-paper-observation-note.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/heat3d-main-paper-observation-note.md:1)
- [iot-arduino-case-decision.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-case-decision.md:1)
- [iot-arduino-c4-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-c4-evidence-bundle.md:1)
