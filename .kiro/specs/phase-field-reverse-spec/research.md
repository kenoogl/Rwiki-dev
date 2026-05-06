# Research & Design Decisions

## Summary

- **Feature**: `phase-field-reverse-spec`
- **Discovery Scope**: Simple Addition (= clean-room re-implementation of fully-spec'd C++ phase-field code)
- **Key Findings**:
  - SSoT `DEVELOPMENT_SPEC.md` (= 22 章 9007 byte) が全 numerical scheme + I/O 契約 + 描画 API 契約を含む、外部 API 研究不要
  - `wingxa.h` (= 14 行 9 関数 prototype のみ) が描画依存の唯一 interface、実体は外部 link 前提
  - 静的配列確保 (= Req 2 AC 9、`§21` 上書き) が user 決定済、動的 alloc strategy 検討は不要

## Research Log

### Discovery Process Decision

- **Context**: kiro-spec-design skill の Step 2 で feature classification を判定
- **Sources Consulted**: `requirements.md` 6 requirements + `DEVELOPMENT_SPEC.md` 22 章 + `wingxa.h` 9 関数
- **Findings**:
  - 全 numerical scheme が `§5`-`§12` で完全規定 (= 支配方程式 / 化学ポテンシャル / 5 点差分 / 既定定数 / 時間発展 7 step / 平均組成保存)
  - 入出力契約が `§13` (= CLI 入力) + `§16` (= snapshot text format) + `§19` (= BMP 17 step 群) で完全規定
  - 描画 API 契約が `§18` で 9 関数に限定
  - 外部 dependency 研究 (= 最新 best practice / API version compatibility) 不要
- **Implications**:
  - `kiro-spec-design` の Discovery 種別 = **Simple Addition** に分類
  - WebSearch / WebFetch dispatch skip
  - 既存 codebase 探索 skip (= clean-room 規律で `pfm1/` 参照禁止)

### Layered Architecture Decision

- **Context**: 3 機能 (= simulation / re-render / BMP from saved data) を実装する全体構造の選択
- **Findings**:
  - 3 機能は全て snapshot text file を共通 input/output の hub とする (= 機能 1 の出力を機能 2/3 が input)
  - 数値計算 (Core) と I/O / Visualization は責務が明確に分離可能
  - `wingxa.h` 描画 API 依存は Visualization layer のみに局所化可能
- **Implications**:
  - **Layered + Library-based CLI** pattern 採用
  - 依存方向 = `Executable Main → Visualization → I/O → Core → wingxa.h API` 単一方向
  - Core layer (= Numerical Engine / Initial Field Builder / Concentration Clamp / Mean Composition Corrector) は I/O / Visualization に依存しない (= 数値計算純粋層、unit testability 確保)

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Layered + Library + 3 executables | core/io/viz lib を共通化、3 binary | 責務明確 / 単一 binary 肥大化なし / テスト容易 | binary 数増加で `make` target 多 | 採用 |
| 1 executable + sub-command | 単一 binary、`pfm sim/render/bmp` のような sub-command | binary 1 個 / CLI 統一 | 機能追加時に binary 全体再 link / sub-command parser 複雑化 | 却下 |
| 単一巨大 binary | 全機能を 1 binary に flat 統合 | build simple | 責務混在 / 機能切替が runtime flag で曖昧 | 却下 |

## Design Decisions

### Decision: Static Array Allocation Strategy

- **Context**: Req 2 AC 9 で「静的配列確保 + runtime 動的再確保なし」が確定、`Field` 型の具体表現を決定する必要
- **Alternatives Considered**:
  1. **Raw 2D static array** (`double[ND][ND]`) — C 慣習、最 minimal overhead
  2. **`std::array<std::array<double, ND>, ND>`** — C++ 標準、bounds-check option (debug)
  3. **`std::vector<double>` 1D + 手動 indexing** — heap alloc、Req 2 AC 9 違反候補で却下
- **Selected Approach**: **Raw 2D static array** (`using Field = double[ND][ND]`)
- **Rationale**:
  - Req 2 AC 9 の「compile time fixed sizes、runtime 動的再確保なし」と最 strict に整合
  - C++ で `Field&` 参照渡し (= ポインタ degenerate 防止)
  - C-style だが C++ 関数 signature で safety を確保 (= `const Field&` / `Field&`)
- **Trade-offs**:
  - 利点: minimal overhead、stack alloc 可能 (= ND=100 で 80 KB / Field、stack overflow risk なし)
  - 欠点: bounds-check が言語標準で提供されない (= debug assertion で代替)
- **Follow-up**: unit test で bounds-check (`i, j ∈ [0, ND)`) assertion を deg build で有効化

### Decision: Build System = GNU Make

- **Context**: C++ build system の選択
- **Alternatives Considered**:
  1. **GNU Make** — scientific C++ 慣習、依存追跡 simple
  2. **CMake** — modern、cross-platform、generator 経由
  3. **Bazel / Meson** — 大規模対応、本 spec scope に対し overkill
- **Selected Approach**: **GNU Make** (Makefile 1 本)
- **Rationale**:
  - 本 spec の規模 (= 11 source file、3 executable) で Make が最 minimal
  - phase-field 系は科学計算 community で Make が dominant
  - V4 review で build system が研究軸でない
- **Trade-offs**:
  - 利点: minimal、依存追跡 explicit
  - 欠点: cross-platform は手動対応 (= macOS / Linux 動作確認、Windows scope 外)

### Decision: RNG Choice = `std::mt19937`

- **Context**: 初期 Field のランダムゆらぎ生成 (Req 3 AC 1) の RNG 選定
- **Alternatives Considered**:
  1. **`std::mt19937`** (`<random>`) — 32-bit Mersenne Twister、deterministic、C++11 標準
  2. **`std::rand()`** — implementation-defined、再現性低
  3. **Custom LCG** — full custom、`§21` 実装裁量で許容、ただし test 困難
- **Selected Approach**: **`std::mt19937`** + uniform distribution
- **Rationale**:
  - 同 seed で同結果 (= reverse engineering 評価で再現性必須)
  - C++ 標準で portable
  - `§9` 「乱数生成器の具体実装は任意」に integrate
- **Trade-offs**:
  - 利点: deterministic、C++ 標準
  - 欠点: 32-bit state → period 2^19937-1 で十分

### Decision: 3 Executables vs 1 Multi-Mode Binary

- **Context**: `§3` 3 機能を 1 binary or 3 binary で提供するかの選択
- **Alternatives Considered**:
  1. **3 separate executables** (`pfm_sim` / `pfm_render` / `pfm_bmp`) — 責務分離 clear
  2. **1 binary + sub-command** (`pfm sim/render/bmp`) — CLI 統一
- **Selected Approach**: **3 separate executables**
- **Rationale**:
  - 各 executable が単一責務 (= V4 review boundary 明確化)
  - 機能追加時に他 binary に影響なし
  - 共通 library (`libpfmcore.a`) を共有することで code 重複なし
- **Trade-offs**:
  - 利点: 責務明確 / 並列開発容易 / V4 review boundary 整合
  - 欠点: build target 増 (= Makefile 内 3 target、minimal)

## Risks & Mitigations

- **Risk 1: 浮動小数点誤差累積で平均組成 drift** — Req 3 AC 9 (= Mean Composition Corrector) で各 step に correction 適用、`§10` clamp の許容範囲内で吸収。100000 step run 後の累積 drift を integration test で `< CLAMP_EPS * ND * ND` で監視。
- **Risk 2: `delt` 過大で陽的 Euler 発散** — `§13` で user 入力責任、本 spec で stability 自動制限なし。documentation で `delt = 0.005` 程度 (= forward 系統経験値、本 spec では reference 値として記載のみ) を recommend。
- **Risk 3: `wingxa.h::keypress()` が non-interactive 環境で block** — `§21` 実装裁量で off-screen mode を許容、Simulation Module は keypress check を per-step に行わない (= max-step or signal trap 経由停止) 戦略を選択可能。
- **Risk 4: `§19` 17 step 群が `max-step = 100000` を超える step (`80000` 等) を含む** — Req 4.5 は「少なくとも `0..80000` の step」を要求、ただし actual snapshot file の中で indexing が必要。BMP Writer は snapshot index で seek、step 番号と snapshot index の mapping は `data-interval` から逆算 (= step `N` の snapshot index = `N / data_interval`)。
- **Risk 5: `c2 + c3 = 1 - 2 * eps` strict 達成** — Concentration Clamp AC 3.8 で「`c2 + c3 ≥ 1` の場合は両者を同比例で縮小し、合計を `1 - 2 * eps` 以下にする」を idempotent 実装、unit test で境界 case 網羅。

## References

- `DEVELOPMENT_SPEC.md` (= `/Users/Daily/Development/DR-pfm/spec_seed/DEVELOPMENT_SPEC.md`、22 章 9007 byte SSoT)
- `wingxa.h` (= `/Users/Daily/Development/DR-pfm/spec_seed/wingxa.h`、9 関数 prototype)
- `requirements.md` (= 本 spec)
