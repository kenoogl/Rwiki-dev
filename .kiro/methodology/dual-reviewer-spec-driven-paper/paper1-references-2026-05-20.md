# 論文1（SES 2026 実践論文）参考文献 書誌情報

_作成日: 2026-05-20_
_位置付け: 骨子§7「参考文献の位置決め」と §2 関連研究の引用予定13文献の完全書誌（BibTeX 相当）。本文執筆時の引用素材_
_対の正本: `paper1-outline-2026-05-20.md`（§7 参考文献の位置決め）／`docs/deep-research-report.md`_
_調査方式: サブエージェント4本での Web 並列調査（dblp、ACM DL、IEEE Xplore、Springer、arXiv ほか）_

---

## 0. 凡例と運用

- 各文献は以下を記述：Authors（全著者）／Title（正式タイトル）／Venue（正式会議名・雑誌名）／Year／Volume・Issue・Pages（あれば）／Publisher／DOI／URL／Type／Notes
- BibTeX 相当の完全形式。本文執筆時にそのまま参照可能
- 引用キーは `[著者姓 出版年]`（例：`[Femmer 2017]`）。実際の BibTeX キーは投稿前に確定（例：`femmer2017requirements` など）
- 要追加調査の項目は明示。本文執筆前に補完
- 引用方針メモは §15 に集約

---

## 1. Dautovic, Plösch, Saft 2011

- **Authors**: Dautovic, Andreas; Plösch, Reinhold; Saft, Matthias
- **Title**: Automated Quality Defect Detection in Software Development Documents
- **Venue**: 5th International Workshop on Software Quality and Maintainability (SQM 2011)、15th European Conference on Software Maintenance and Reengineering (CSMR 2011) のサテライトワークショップ
- **Year**: 2011
- **Date**: 2011年3月1日、ドイツ・オルデンブルク開催
- **Pages**: 29–37
- **Publisher**: CEUR-WS（CEUR Workshop Proceedings）
- **Volume**: Vol-708
- **DOI**: なし（CEUR-WS 収録のため未付与）
- **URL**: https://ceur-ws.org/Vol-708/sqm2011-dautovic-et-al-11-autoQualityDefectDetect.pdf
- **Type**: workshop paper
- **Notes**: CEUR-WS Vol-708 目次より pp. 29–37 を確認

---

## 2. Arora, Sabetzadeh, Briand, Zimmer 2015

- **Authors**: Arora, Chetan; Sabetzadeh, Mehrdad; Briand, Lionel; Zimmer, Frank
- **Title**: Automated Checking of Conformance to Requirements Templates Using Natural Language Processing
- **Venue**: IEEE Transactions on Software Engineering
- **Year**: 2015
- **Volume**: 41
- **Issue**: 10
- **Pages**: 944–968
- **Publisher**: IEEE
- **ISSN**: 0098-5589
- **DOI**: 10.1109/TSE.2015.2428709
- **URL**: https://people.svv.lu/sabetzadeh/pub/TSE15.pdf
- **Type**: journal article
- **Notes**: Monash University 研究リポジトリ、著者公開PDFで確認

---

## 3. Femmer, Méndez Fernández, Wagner, Eder 2017

- **Authors**: Femmer, Henning; Méndez Fernández, Daniel; Wagner, Stefan; Eder, Sebastian
- **Title**: Rapid Quality Assurance with Requirements Smells
- **Venue**: Journal of Systems and Software
- **Year**: 2017（オンライン公開 2016年、印刷版 2017年1月）
- **Volume**: 123
- **Issue**: 通巻（issue 番号なしの可能性、要追加調査）
- **Pages**: 190–213
- **Publisher**: Elsevier
- **DOI**: 10.1016/j.jss.2016.02.047
- **URL**: https://www.sciencedirect.com/science/article/abs/pii/S0164121216000789
- **arXiv**: https://arxiv.org/abs/1611.08847
- **Type**: journal article

---

## 4. Veizaga, Shin, Briand 2024

- **Authors**: Veizaga, Alvaro; Shin, Seung Yeob; Briand, Lionel C.
- **Title**: Automated Smell Detection and Recommendation in Natural Language Requirements
- **Venue**: IEEE Transactions on Software Engineering
- **Year**: 2024
- **Volume**: 50
- **Issue**: 4（April 2024）
- **Pages**: 695–720
- **Publisher**: IEEE
- **DOI**: 10.1109/TSE.2024.3361033
- **URL**: https://orbilu.uni.lu/handle/10993/57739（機関リポジトリ）／https://arxiv.org/abs/2305.07097（プレプリント）
- **Type**: journal article（FSE 2024 Journal-First トラックにも採録）
- **Notes**: 金融ドメイン13システム・2725件要件で Paska ツールを評価

---

## 5. Nayak, Timmapathini, Murali, Ponnalagu, Venkoparao, Post 2022

- **Authors**: Nayak, Anmol; Timmapathini, Hariprasad; Murali, Vidhya; Ponnalagu, Karthikeyan; Venkoparao, Vijendran Gopalan; Post, Amalinda
- **Title**: Req2Spec: Transforming Software Requirements into Formal Specifications Using Natural Language Processing
- **Venue**: Requirements Engineering: Foundation for Software Quality (REFSQ 2022) — 28th International Working Conference, Birmingham, UK, March 21–24, 2022, Proceedings
- **Year**: 2022
- **Series**: Lecture Notes in Computer Science (LNCS), vol. 13216
- **Pages**: 87–95
- **Publisher**: Springer, Cham
- **DOI**: 10.1007/978-3-030-98464-9_8
- **URL**: https://link.springer.com/chapter/10.1007/978-3-030-98464-9_8
- **Type**: conference paper（REFSQ 2022 Research Papers トラック）
- **Notes**: Bosch 自動車ドメインの要件222件を HANFOR 向けに形式化、71%を正しく形式化

---

## 6. Ali, Naganathan, Bork 2024

- **Authors**: Ali, Syed Juned; Naganathan, Varun; Bork, Dominik
- **Title**: Establishing Traceability Between Natural Language Requirements and Software Artifacts by Combining RAG and LLMs
- **Venue**: Conceptual Modeling (ER 2024) — 43rd International Conference, Pittsburgh, PA, USA, October 28–31, 2024, Proceedings
- **Year**: 2024
- **Series**: Lecture Notes in Computer Science (LNCS), vol. 15238
- **Pages**: 295–314
- **Publisher**: Springer, Cham
- **DOI**: 10.1007/978-3-031-75872-0_16
- **URL**: https://repositum.tuwien.at/handle/20.500.12708/205507（TU Wien）／https://model-engineering.info/publications/papers/ER24-Requirements2Code.pdf
- **Type**: conference paper（ER 2024 本会議）
- **Notes**: キーワード・ベクトル・グラフ（KG）3種インデックスを RAG に組み合わせ、Function Dependency Graph を Neo4j に格納

---

## 7. Liu, Hou, Chen, Jin, Wang 2025

- **Authors**: Liu, Yuhao; Hou, Junjie; Chen, Yuxuan; Jin, Jie; Wang, Wenyue
- **Title**: LLM-ACNC: Aerospace Requirement Texts Knowledge Graph Construction Utilizing Large Language Model
- **Venue**: Aerospace (MDPI)
- **Year**: 2025
- **Volume**: 12
- **Issue**: 6
- **Article Number**: 463
- **Publisher**: MDPI
- **DOI**: 10.3390/aerospace12060463
- **URL**: https://www.mdpi.com/2226-4310/12/6/463
- **Type**: journal article
- **Date**: 2025年5月23日発行
- **Notes**: 全著者の所属は China Aerospace Academy of Systems Science and Engineering（北京）。著者フルネームは Google Scholar 表示と Aerospace 誌情報から確認

---

## 8. Li ほか 2025（MAAD、2バージョン）

本論文には2つのバージョンが存在する。本文で引用する際はいずれか1つを選ぶ（推奨：FSE 2025 確定版）。

### 8a. FSE 2025 ビジョンペーパー（確定）

- **Authors**: Zhang, Yiran; Li, Ruiyin; Liang, Peng; Sun, Weisong; Liu, Yang
- **Title**: Knowledge-Based Multi-Agent Framework for Automated Software Architecture Design
- **Venue**: Proceedings of the 33rd ACM International Conference on the Foundations of Software Engineering (FSE 2025) — Industry Visions and Reflections (IVR) Track
- **Year**: 2025
- **Pages**: 5ページ
- **Publisher**: ACM
- **DOI**: 10.1145/3696630.3728493
- **URL**: https://dl.acm.org/doi/10.1145/3696630.3728493、著者公開: https://wssun.github.io/papers/2025-FSE-IVR-MAAD.pdf
- **Type**: conference paper（ビジョンペーパー、5ページ）
- **Date**: 2025年6月23〜28日、ノルウェー・トロンハイム開催

### 8b. TOSEM 投稿中の拡張版（プレプリント）

- **Authors**: Li, Ruiyin; Zhang, Yiran; Zhou, Xiyu; Liang, Peng; Sun, Weisong; Xuan, Jifeng; Jin, Zhi; Liu, Yang
- **Title**: MAAD: Automate Software Architecture Design through Knowledge-Driven Multi-Agent Collaboration
- **Venue**: ACM Transactions on Software Engineering and Methodology (TOSEM)（投稿中・未掲載）
- **Year**: 2025（投稿中）
- **arXiv ID**: 2507.21382
- **URL**: https://arxiv.org/abs/2507.21382
- **Type**: preprint（ジャーナル査読中）
- **Date**: arXiv 投稿 2025年7月28日

---

## 9. Fukuda, Nakagawa, Miyazaki, Tokumoto 2025

- **Authors**: Fukuda, Takasaburo; Nakagawa, Takao; Miyazaki, Keisuke; Tokumoto, Susumu
- **Title**: Development of Automated Software Design Document Review Methods Using Large Language Models
- **Venue**: 32nd IEEE International Conference on Software Analysis, Evolution and Reengineering (SANER 2025)
- **Year**: 2025
- **Pages**: 91–101
- **Publisher**: IEEE
- **DOI**: 10.1109/SANER64311.2025.00017
- **URL**: https://dblp.org/rec/conf/saner/FukudaNMT25
- **arXiv**: 2509.09975（事後プレプリント、2025年9月12日投稿）
- **Type**: conference paper
- **Date**: 2025年3月4〜7日、カナダ・モントリオール開催
- **Notes**: 全著者の所属は Fujitsu Ltd.（川崎）。英語論文

---

## 10. Elberzhager, Gerbershagen, Ginkel 2026

- **Authors**: Elberzhager, Frank; Gerbershagen, Matthias; Ginkel, Joshua
- **Title**: Using LLMs to Evaluate Architecture Documents: Results from a Digital Marketplace Environment
- **Venue**: 18th International Conference on Software Quality (SWQD 2026) — 論文集タイトル: "Software Architecture as the Backbone of Software Quality"
- **Year**: 2026
- **Series**: Lecture Notes in Business Information Processing (LNBIP), vol. 581
- **Pages**: 65–81
- **Publisher**: Springer
- **DOI**: 10.1007/978-3-032-24216-7_4
- **URL**: https://link.springer.com/chapter/10.1007/978-3-032-24216-7_4／https://arxiv.org/abs/2601.19693
- **Type**: conference paper（proceedings 章）
- **Date**: 2026年5月19〜21日、オーストリア・ウィーン開催
- **Notes**: 第1著者の所属は Fraunhofer IESE（Kaiserslautern）。論文集 ISBN（eBook）978-3-032-24216-7、softcover 978-3-032-24215-0

---

## 11. Krakovna ほか 2020

- **Authors**: Krakovna, Victoria; Uesato, Jonathan; Mikulik, Vladimir; Rahtz, Matthew; Everitt, Tom; Kumar, Ramana; Kenton, Zac; Leike, Jan; Legg, Shane
- **Title**: Specification gaming: the flip side of AI ingenuity
- **Venue**: Google DeepMind Blog
- **Year**: 2020
- **Date**: 2020年4月21日
- **DOI**: なし（ブログ記事のため）
- **URL**: https://deepmind.google/blog/specification-gaming-the-flip-side-of-ai-ingenuity/
- **Type**: blog post
- **Notes**: 著者全9名はいずれも当時 DeepMind 所属

---

## 12. Goodhart 1975

原典（1975年発表・1976年刊行）と再録版（1984年）が存在。引用する際はいずれか1つを選ぶ（推奨：1984 Macmillan 再録版のほうがアクセス容易）。

### 12a. 原典（1975年発表 / 1976年刊行）

- **Authors**: Goodhart, Charles A. E.
- **Title**: Problems of Monetary Management: The U.K. Experience
- **Venue**: Papers in Monetary Economics, Vol. I（Reserve Bank of Australia 主催「Conference in Monetary Economics」、シドニー、1975年7月）
- **Year**: 1975（会議発表）／1976（刊行）
- **Publisher**: Reserve Bank of Australia, Sydney
- **DOI**: なし
- **ISBN**: 9780642928672 / 0642928673
- **OCLC**: 27495749
- **Type**: conference proceedings paper
- **Notes**: 「グッドハートの法則」の初出論文。ページ範囲は要追加調査（WorldCat OCLC 27495749 で確認）

### 12b. Macmillan 再録版（1984年）

- **Authors**: Goodhart, Charles A. E.
- **Title**: Problems of Monetary Management: The UK Experience
- **Book Title**: Monetary Theory and Practice: The U.K. Experience
- **Chapter**: 4
- **Pages**: 91–121
- **Publisher**: Macmillan / Palgrave, London
- **Year**: 1984
- **DOI**: 10.1007/978-1-349-17295-5_4
- **ISBN（ハードカバー）**: 9780333360590
- **ISBN（ペーパーバック）**: 9780333360606
- **URL**: https://link.springer.com/chapter/10.1007/978-1-349-17295-5_4
- **Type**: book chapter

---

## 13. Sharma ほか 2023

- **Authors**: Sharma, Mrinank; Tong, Meg; Korbak, Tomasz; Duvenaud, David; Askell, Amanda; Bowman, Samuel R.; Cheng, Newton; Durmus, Esin; Hatfield-Dodds, Zac; Johnston, Scott R.; Kravec, Shauna; Maxwell, Timothy; McCandlish, Sam; Ndousse, Kamal; Rausch, Oliver; Schiefer, Nicholas; Yan, Da; Zhang, Miranda; Perez, Ethan
- **Title**: Towards Understanding Sycophancy in Language Models
- **Venue**: International Conference on Learning Representations (ICLR 2024)
- **Year**: 2024（arXiv 初出 2023年10月20日）
- **arXiv ID**: 2310.13548
- **arXiv URL**: https://arxiv.org/abs/2310.13548
- **DOI（arXiv）**: 10.48550/arXiv.2310.13548
- **ICLR ページ**: https://iclr.cc/virtual/2024/poster/17593
- **Type**: conference paper（ICLR 2024 採録）
- **Notes**: 全19名の著者はいずれも Anthropic 所属。「Published as a conference paper at ICLR 2024」と論文冒頭に明記

---

## 14. 要追加調査事項（投稿前に補完）

- **Dautovic 2011** の DOI：CEUR-WS Vol-708 はワークショップ論文のため DOI 未付与の可能性が高い。DBLP で再確認推奨
- **Femmer 2017** の Issue 番号：JSS vol.123 は2017年1月発行で issue 番号なし（通巻のみ）の可能性が高い。Elsevier 直接アクセスで確認推奨
- **Liu 2025** の著者フルネーム：MDPI サイトが403で直接取得できなかったため、Google Scholar 短縮表示から推定。CrossRef API で確認推奨
- **Goodhart 1975** 原典のページ範囲：WorldCat OCLC 27495749 または図書館蔵書データで確認推奨（学術的に厳密に引くなら再録版 1984 のほうがアクセス容易）
- **Li 2025（MAAD）**：FSE 2025 IVR ビジョンペーパー（確定）と TOSEM 投稿中の arXiv 版のどちらを本文で引用するか。本文執筆時に判断
- **投稿前**：各文献の BibTeX キー（例 `femmer2017requirements`）を確定し、SES 投稿テンプレートに合わせて整形

---

## 15. 引用方針メモ（骨子§7 の位置決めに対応）

### 決定的lint・スメル検出・テンプレート準拠の系譜（§2 で背景）

- **Dautovic 2011**：自動レビュー研究の概観で「コード静的解析の文書版」という発想の起点として
- **Arora 2015**：要件テンプレート準拠の決定的検査の典型例として
- **Femmer 2017**：「自動裁定ではない補助」（precision 59%、recall 82%）の位置として
- **Veizaga 2024**：検出に加えて推薦を返す進化形として、Femmer 系列の到達点

### formalization の系譜（§2 で参考、本論文の対象外）

- **Nayak 2022**：要求→形式仕様変換の代表として

### RAG・グラフ統合の系譜（§2 で「過去 escalate 照合は薄い」隙間の議論に）

- **Ali 2024**：要求→コードの追跡に RAG＋グラフを使った代表例として
- **Liu 2025**：要件文から知識グラフを構築する LLM 強化手法として

### 多役エージェント・設計書レビューの系譜（§2 で本論文と最近接、差別化を明示）

- **Li 2025（MAAD）**：本論文の三役レビューとの差別化（用途・役割関係・時間軸）を §2 末尾で明示する対象
- **Fukuda 2025**：設計書レビューの観点分解＋入力正規化の手法、本論文と最も近い既存研究として
- **Elberzhager 2026**：文書品質と LLM 評価品質の関係を示す。本論文の fixture 仮装議論の補強として §5 で

### 既知議論（§2 で問題定式化の理論的接続、§5 で対応関係）

- **Krakovna 2020**：報酬ハッキング・specification gaming の代表的事例集として
- **Goodhart 1975**：グッドハートの法則の典拠として（推奨：1984 再録版を引用）
- **Sharma 2023**：追従バイアスの背景言及として（本論文では中核議論から外し、§2 背景言及のみ）

---

## 16. 進め方（次の作業）

- 各文献の BibTeX キーを確定（投稿テンプレートと整合）
- 引用箇所を本文執筆と並行して確定
- 要追加調査5件（§14）を投稿前に補完
- 本文執筆時に本書を主要素材として参照
