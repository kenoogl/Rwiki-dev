# iot-arduino case decision

_作成: 2026-05-12_  
_status: fixed decision v0.1_  
_role: `C-4 iot-arduino` を main paper でどう扱って閉じるかを明文化する_

---

## 1. decision

`iot-arduino` は、**main paper の snapshot-based supporting case として閉じる**。

この case は fixed core case には上げない。  
一方で、paper から外すこともしない。

位置づけは次の通りとする。

1. main paper の primary core case
   - `dual-reviewer-rebuild`
   - `phase-field`
   - `heat3d`
2. `iot-arduino`
   - generalized first implementation case
   - event-driven / embedded domain transfer 補助 case
   - stable safety finding / preserved caveat の supporting evidence

したがって、`iot-arduino` は main paper の supporting case として保存し、**現 boundary での追加 rerun は打ち切る**。

---

## 2. why close now

この判断の理由は 4 つある。

1. external `intent.md` と `仕様.md` から case を起動し、`requirements -> design -> tasks -> review acquisition` を gate ベースで一周できた
2. first snapshot と refined second snapshot の両方で `single / dual / dual+judgment = 2 / 3 / 3` を取得できた
3. second snapshot でも `restart boundary` と `relay fail-safe` は stable safety finding として残り、`telemetry caveat` は preserved caveat として残った
4. これ以上、同じ snapshot-boundary のまま rerun を重ねても、paper-facing incremental value は小さい

したがって、`iot-arduino` は

- workflow continuity
- generalized first-case viability
- event-driven domain transfer
- signal stability after implementation-local refinement

を示す supporting case としては十分である。

---

## 3. what is fixed

この decision で fixed にするのは次である。

- `iot-arduino` を `C-4` の snapshot-based supporting case として使うこと
- external intent/spec seed から始めた generalized implementation-first trace をこの case の正本 evidence として使うこと
- first/second acquisition の `2 / 3 / 3` を、`stable safety finding / preserved caveat` の読みで使うこと

---

## 4. what is not claimed

この decision で確定しないものは次である。

1. `iot-arduino` が fixed core case に上がった
2. current implementation が hardware-ready である
3. real WiFi/NTP, EEPROM/RTC, OLED/Blynk, ISR wiring の adequacy が確認できた
4. `2 / 3 / 3` が event-driven domain の一般則だといえる

つまり、fixed なのは **case role と paper reading** であって、device-ready correctness ではない。

---

## 5. reading rule

`iot-arduino` を main paper で使うときは、次のように読む。

### 5.1 workflow side

- short command start から case を始められた
- 最初の `6 feature` 分割案は human に reject され、対話的な修正議論を経て `2 feature` へ再構成された
- requirements defer / reopen を trace artifact に残せた
- approved upstream bundle と implementation acquisition を同一 case lineage で接続できた

### 5.2 implementation side

- first snapshot baseline と second snapshot refinement loop を 1 回回せた
- finding count は `2 / 3 / 3` のまま維持された
- この維持は `refinement failed` ではなく、safety-sensitive contract と caveat retention が silent に失われなかった evidence として読む

---

## 6. preserved caveat

`iot-arduino` で最も重要な caveat は次である。

この case は real hardware integration 完了版ではなく、**snapshot-boundary review case** である。

したがって、現在の evidence は

- hardware adequacy
  ではなく
- workflow continuity
- signal stability
- caveat retention

を支えるものとして使う。

将来 real WiFi/NTP, EEPROM/RTC, ISR, OLED/Blynk を入れて再度回すなら、それは **新しい implementation boundary** として別 cycle で扱うべきであり、この decision を reopen しない。

---

## 7. consequence for the paper

main paper では次の書き方を採る。

1. `iot-arduino` は generalized first implementation case として置く
2. `Claim 2 / 3 / 4` の supporting evidence に使う
3. `stable safety finding / preserved caveat` の例として読む
4. hardware-ready adequacy claim には使わない

---

## 8. linked artifacts

- [core-case-iot-arduino.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/core-case-iot-arduino.md:1)
- [iot-arduino-c4-evidence-bundle.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-c4-evidence-bundle.md:1)
- [implementation-evidence-summary.md](/Users/Daily/Development/Rwiki-dev/.kiro/specs/iot-arduino-spec/reviews/implementation-evidence-summary.md:1)
- [iot-arduino-workflow-path.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/iot-arduino-workflow-path.md:1)
