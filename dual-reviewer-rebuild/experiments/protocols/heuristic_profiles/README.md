# heuristic profile template policy

_作成: 2026-05-12_  
_status: active guidance v0.1_  
_scope: `intent / spec / implementation` track の heuristic profile 作成方針_

---

## 1. 目的

この directory の `heuristic_profile` は、
review runner が case 固有の stress を読むための **最小追加 layer** である。

ここで重要なのは、
**既存 case をコピーしないこと** と
**最小 template から始めること** である。

---

## 2. Start From Minimal Template

新しい case を起こすときは、まず次を複製する。

- implementation:
  - [implementation/_minimal_template.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/implementation/_minimal_template.yaml:1)
- intent:
  - [intent/_minimal_template.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/intent/_minimal_template.yaml:1)
- spec:
  - [spec/_minimal_template.yaml](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/experiments/protocols/heuristic_profiles/spec/_minimal_template.yaml:1)

`heat3d`、`phase-field`、`iot-arduino` の profile は template ではなく
**case 固有の完成例** とみなす。

runner 側の既定動作としても、
`heuristic_profile_ref` が未指定なら track ごとの minimal template を使ってよい。

---

## 3. Minimal Policy

初期状態の原則:

- `primary_detection.rules` は空でもよい
- `adversarial_review.rules` も空でもよい
- target 固有の contract が明確になるまで rule を増やさない

最初に足してよい rule 数の目安:

- primary: 1-2 件
- adversarial: 0-1 件

---

## 4. いつ rule を足すか

rule を足す条件は次のどれかである。

1. approved upstream spec に review-critical contract が明示されている
2. implementation snapshot に boundary caveat が固定されている
3. intent/spec phase に drift しやすい ownership or phase contract がある

逆に、次の理由では rule を足さない。

- なんとなく case を rich に見せたい
- 既存 case に同じ数の rule がある
- 実装修正案そのものを heuristic に埋め込みたい

---

## 5. Rule Style

大きく 2 種類ある。

### 5.1 pattern-id based

主に `intent / spec` track で使う。

使うキー:

- `source_pattern_ids`
- `counter_evidence_pattern_ids`

これは seed document や review artifact に既に登録された pattern catalog を使う。

### 5.2 structural-evidence based

主に `implementation` track で使う。

使うキー:

- `required_evidence_types`
- `required_source_kinds`
- `required_section_classes`
- `structural_source_requirements`
- `structural_counter_requirements`

これは heading、親見出し、bullet、section class に anchored して
source 根拠を絞る。

---

## 6. Minimal Authoring Checklist

新しい rule を 1 件足す前に、次を言えるか確認する。

1. 何の contract を見たいのか
2. その contract はどの source に anchored しているか
3. なぜ generic workflow だけでは不足するのか
4. review 結果として何を残したいのか

この 4 点を 1 文ずつ言えないなら、rule を足すのは早い。

---

## 7. Anti-Patterns

避けるべきこと:

- `heat3d` の heading pattern を別 case に流用する
- target 固有でない medium severity rule を量産する
- implementation fix plan を heuristic rule に変換する
- adversarial rule を primary rule より先に増やす

---

## 8. Validation Expectation

profile を追加・更新したら、少なくとも次を通す。

- `ruby dual-reviewer-rebuild/scripts/validate_protocol_runners.rb`
- `ruby dual-reviewer-rebuild/scripts/validate_track_run_artifacts.rb`

必要なら case 固有 runner も再実行する。
