---
name: finding 提示は箇所 / 現状 / 問題 / 修正後の 4 要素で書く
description: review finding を user に提示する場面で、各 finding を「箇所 / 現状 / 問題 / 修正後」の 4 要素で書く。抽象 1 行で済ませない、具体引用 (= before/after) を必ず含める。
type: feedback
originSessionId: 1283956e-4c99-432f-93a6-d028407b7c75
---
review finding (= dual-reviewer の primary / adversarial / judgment 結果) を user に提示する場面で、**各 finding を以下の 4 要素で書く**:

1. **箇所** = どの file / 行 / 節 か (= path + line number + section)
2. **現状** = 該当箇所の引用 (= 実際の文言 / コード block で 1-3 行)
3. **問題** = 何が不整合 / 不適切 / 不足か (= 具体的に「何と何が違う」「何が抜けている」)
4. **修正後** = どう変えるか (= 提案文言 / コード block で 1-3 行)

抽象 1 行 (例: 「X と Y が drift」「文言齟齬」「整合不全」) では不可。**具体引用必須** (= 現状の actual text + 修正後の actual text)。

クラスター集約は概要として併用可、各 finding 詳細は 4 要素で展開。

**Why**: 2026-05-05 51st セッション (= phase-field-reverse-spec design phase Round 2 user 判断材料提示) で発生した failure case = クラスター集約 + 1 行説明 + 「箇所 + 1 行で何を直すか」のみで、user から「分かりにくい」指摘が 2 回連続。各 finding の rendering が抽象的で、user が「これは具体的に何の問題か」を頭で再構成する手間が残った。具体引用 (= before/after) を含めることで再構成の手間ゼロ。

**How to apply**: review finding を user に提示する場面で、各 finding を以下のテンプレートで書く:

```
### {issue_id} = {finding 一行要約}

**箇所**: {file path}:{line} ({section name})

**現状**:
\`\`\`
{actual text from file, 1-3 行}
\`\`\`

**問題**: {何が不整合か、具体的に。抽象表現禁止}

**修正後** ({3 択 / 単一案}):
\`\`\`
{proposed text, 1-3 行}
\`\`\`
```

クラスター集約は finding 一覧の概要として併用、必要なら個別 finding 詳細をドリルダウン展開する 2 段構造。

self-rewrite「user simulate」step (= feedback_self_rewrite_user_simulate.md) と併用 = simulate 段階で「この finding の中身が user に rendering されているか」を check、不足なら 4 要素で書き直す。
