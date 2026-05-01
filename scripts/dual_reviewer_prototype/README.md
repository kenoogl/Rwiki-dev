# dual-reviewer-foundation prototype (本 README は placeholder / This README is a placeholder)

## 概要 (Overview)

本 directory は `dual-reviewer-foundation` spec の **portable 7 artifact** を配置する foundation install location である。後続 spec (`dual-reviewer-design-review` / `dual-reviewer-dogfeeding`) が単独で機能するための portable 基盤を提供する。

本 README は Task 1 (skeleton) 段階の placeholder で、後続 Task で各 artifact が配置されるに伴い skeleton を full README に拡充する。

## 注意 (Phase A scope)

- 本 prototype は **Rwiki repo 内 prototype 段階 (Phase A)** に限定される。
- Phase B (独立 fork / npm package 化 / `--lang en` 対応 / 固有名詞除去) は本 spec scope 外。
- `seed_patterns.yaml` 内の固有名詞 (Rwiki / Spec X 等) は Phase A scope では保持され、Phase B-1.0 release prep で generalization 予定。

## 7 portable artifact 一覧 (Seven Portable Artifacts)

1. **Layer 1 framework 定義** (`framework/layer1_framework.yaml`) — phase 横断 review framework の portable definition (Req 1)
2. **dr-init skill** (`skills/dr-init/`) — target project bootstrap (`.dual-reviewer/` 生成 + all-or-nothing rollback) (Req 2)
3. **共通 JSON schema 5 file** (`schemas/`) — `review_case` / `finding` / `impact_score` / `failure_observation` / `necessity_judgment` (Req 3)
4. **seed_patterns** (`patterns/seed_patterns.yaml`) — 23 件 retrofit パターン (origin: `rwiki-v2-dev-log`) (Req 4)
5. **fatal_patterns** (`patterns/fatal_patterns.yaml`) — 致命級 8 種固定 enum (data 提供のみ責務、matching logic は Layer 2) (Req 5)
6. **V4 §5.2 judgment subagent prompt template** (`prompts/judgment_subagent_prompt.txt`) — `.kiro/methodology/v4-validation/v4-protocol.md` §5.2 と byte-level 整合 (Req 6)
7. **用語抽象化 + 設定 template 2 種** (`terminology/terminology.yaml.template` + `config/config.yaml.template`) — dr-init が copy する placeholder (Req 7)

## Directory layout (skeleton 段階)

```
scripts/dual_reviewer_prototype/
├── README.md
├── framework/                # Layer 1 framework yaml
├── schemas/                  # JSON Schema 5 file
├── patterns/                 # seed_patterns + fatal_patterns
├── prompts/                  # V4 §5.2 prompt template
├── config/                   # config.yaml.template
├── terminology/              # terminology.yaml.template
├── skills/                   # dr-init skill
└── tests/                    # unit + integration tests (Validation phase)
```

## 利用前提 (Runtime Prerequisites)

- Python 3.10+
- `pyyaml`
- `jsonschema>=4.18` (Draft 2020-12 + `Registry` API 対応)
- `pytest`

(詳細 install 手順は後続 Task で本 README を拡充する際に追記)

## 関連 spec (Related Specs)

- `.kiro/specs/dual-reviewer-foundation/` — 本 spec (Layer 1 framework + portable artifact 提供)
- `.kiro/specs/dual-reviewer-design-review/` — Layer 2 design extension + 3 review skill (`dr-design` / `dr-log` / `dr-judgment`) を提供
- `.kiro/specs/dual-reviewer-dogfeeding/` — Phase A-2 dogfeeding (Spec 6 適用 + 3 系統対照実験 + 論文化 metrics 抽出)
