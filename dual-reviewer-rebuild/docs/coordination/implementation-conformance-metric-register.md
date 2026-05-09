# implementation-conformance-metric-register

## 1. この文書の役割

この文書は `implementation conformance review` を形骸化させないための
metric 定義台帳である。

ここで扱う metric は performance metric ではなく、
prototype 実装が仕様、境界、証跡をどれだけ守れているかを測るためのものだ。

## 2. 基本ルール

- metric の primary collection point は conformance review 実施時
- 自動算出できないものは review artifact で manual snapshot を残す
- trend を見たい場合は各 review artifact に current value を残す
- metric 自体は handback 判定を自動化しないが、reopen 判断の補助に使う

## 3. metric definition

### 3.1 `conformance_findings_count`

- definition: 1 回の conformance review で記録された finding 総数
- unit: count per review
- collection timing: review 完了時
- interpretation:
  - `0`: major nonconformance なし
  - `>0`: review artifact と disposition が必須

### 3.2 `severity_weighted_finding_score`

- definition: severity ごとの重み付き合計
- formula:
  - `P1 = 3`
  - `P2 = 2`
  - `P3 = 1`
- unit: weighted score per review
- collection timing: review 完了時
- interpretation:
  - 高いほど implementation risk が高い

### 3.3 `post_smoke_nonconformance_count`

- definition: smoke validator pass 後に発見された nonconformance 件数
- unit: count per review
- collection timing: smoke 再実行後の review
- interpretation:
  - `0` が望ましい
  - `>0` は smoke だけでは品質境界を守れていないことを示す

### 3.4 `fixture_bound_resolution_count`

- definition: 固定 fixture 名、固定 path、限定列挙に依存する resolution / lookup 箇所数
- unit: count per reviewed scope
- collection timing: code review 時
- interpretation:
  - 増加は prototype 依存の固定化シグナル

### 3.5 `heuristic_linkage_count`

- definition: structured reference ではなく、basename match や string include など heuristic で artifact を結んでいる箇所数
- unit: count per reviewed scope
- collection timing: code review 時
- interpretation:
  - provenance / caveat / traceability の silent weakening 候補

### 3.6 `placeholder_or_deferred_count`

- definition: placeholder、deferred、暫定 proxy のまま残っている implementation 箇所数
- unit: count per reviewed scope
- collection timing: review または signal register 更新時
- interpretation:
  - downstream 依存が近いのに減らない場合は `B/C` handback 候補

### 3.7 `review_artifact_presence_rate`

- definition: conformance review が必要な implementation checkpoint のうち、review artifact が存在する割合
- formula: `review artifact がある checkpoint 数 / review 必須 checkpoint 数`
- unit: ratio
- collection timing: branch / PR 棚卸し時
- interpretation:
  - `1.0` が望ましい

### 3.8 `finding_to_signal_link_rate`

- definition: review finding のうち、signal register または coordination log にリンクされた割合
- formula: `linked finding 数 / total finding 数`
- unit: ratio
- collection timing: review artifact 記録後
- interpretation:
  - `1.0` 未満なら review 証跡が孤立している

## 4. current baseline snapshot

prototype 一巡後の初回 conformance review では、少なくとも次を snapshot として残す。

- `conformance_findings_count`
- `severity_weighted_finding_score`
- `post_smoke_nonconformance_count`
- `fixture_bound_resolution_count`
- `heuristic_linkage_count`
- `review_artifact_presence_rate`
- `finding_to_signal_link_rate`
