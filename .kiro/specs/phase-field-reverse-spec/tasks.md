# Implementation Plan

> 本 plan は `/Users/Daily/Development/DR-pfm/` 直下 (= 別 git、local only) で実行する C++ clean-room 再実装の作業を定める。`spec_seed/` (= `DEVELOPMENT_SPEC.md` + `wingxa.h`) は touch 禁止、本 plan で参照のみ行う。各 sub-task は CLAUDE.md TDD 規律 (= test first → fail 確認 → impl → pass 確認) に準拠する。

> 各 task の `_Depends:_` field は **直接依存** のみを列挙する (= transitive 依存は省略、依存解決は task graph 探索で行う)。

> 各 sub-task の cost 推定は 1-3h 範囲を default 規律とする。例外 = task 7.5 acceptance test の 100000 step run 部分は 1 回実行 cost 5-10 min を含み、再実行は最終 acceptance 段階のみとする (= TDD cycle 外置き、smoke 100 step run で代替可)。

## 1. Foundation — プロジェクト基盤と build 基盤

- [x] 1.1 プロジェクトディレクトリ初期化
  - `DR-pfm/` 直下に `include/`, `src/`, `tests/`, `output/` の 4 dir を作成
  - 既存 `spec_seed/` (= `DEVELOPMENT_SPEC.md` + `wingxa.h`) は touch せず保持
  - `DR-pfm/` 直下で `git init` (= local only、Rwiki-dev/ git とは独立)
  - 観測条件: `ls DR-pfm/` で `include/`, `src/`, `tests/`, `output/`, `spec_seed/`, `.git/` の 6 entry 確認できる
  - _Boundary: project skeleton (layer: Build artifact); allowed_outbound: filesystem 操作のみ_

- [x] 1.2 Field 型 + 共通定数 header
  - `field_types.h` で `namespace pfm` + `inline constexpr int ND = 100` + `using Field = double[ND][ND]` 定義
  - `concentration_clamp.h` で `inline constexpr double CLAMP_EPS = 1.0e-6` 定義
  - `renderer.h` で `inline constexpr int DRAW_W = 400` + `inline constexpr int DRAW_H = 400` 定義
  - 観測条件: header 群を include しただけの最小 .cpp が C++17 mode で compile success
  - _Requirements: 2.3, 2.5, 2.6, 2.9_
  - _Boundary: header types (layer: Core); allowed_outbound: 標準 library のみ_

- [x] 1.3 Makefile + test runner + wingxa stub
  - `Makefile` に C++17 flag、`libpfmcore.a` target、`tests` target、3 executable target (= placeholder rules) を定義
  - test runner = 軽量 main() ベース (= TDD 準拠、外部 framework 不要)、`-UNDEBUG` flag 強制 (= debug / release 両 build で `assert` 有効化、`NDEBUG` no-op 回避)、各 test を `void test_xxx()` 関数化、main() で list 呼出、fail 時 `std::cerr << "FAIL: " << #fn << " at " << __FILE__ << ":" << __LINE__` 出力後 `std::exit(1)`
  - test runner 規約 = 同一 .cpp file 内の sequential test (= 例 task 4.1 + 4.2 が共有する `tests/test_snapshot_io.cpp`) は 4.1 が main を持ち、4.2 以降は test 関数追加のみで main 重複定義禁止 (= ODR 違反 link error 防止)
  - Makefile `CXXFLAGS_TEST = -UNDEBUG -O0 -g` で `tests` target に強制付与
  - wingxa stub 提供 = `src/wingxa_stub.cpp` で wingxa.h 宣言 9 関数全 no-op 実装 (= `gwinsize`/`ginit`/`gsetorg`/`gcolor`/`grect`/`swapbuffers` は空 body、`keypress` は `return 0`、`save_screen` は `return 0`、`itoa` は `if (buffer) buffer[0] = '0'; buffer[1] = '\0'; return buffer;`)
  - Makefile default = `LDFLAGS = wingxa_stub.o`、wingxa 実体がある場合は `make LDFLAGS='-L/path/to -lwingxa'` で上書き
  - test 専用 mock との link 衝突回避 = 例 task 5.1 で導入する `tests/fixtures/mock_wingxa_record.cpp` (= recording mock) は test 専用 LDFLAGS で link、production `wingxa_stub.o` と同時 link 禁止 (= ODR 違反回避)
  - 観測条件: `make tests` で空 test list が exit 0 で終了、`make` で 3 executable が placeholder build success、故意 1 assertion fail させた test を `make tests` 実行 → exit code 非 0 + stderr に test 名出力確認
  - _Requirements: 7.1 (= placeholder build、最終受け入れは task 7.1 で取得)_
  - _Boundary: Makefile, tests runner, wingxa_stub (layer: Build artifact); allowed_outbound: 全 layer source compile + libpfmcore.a + 3 executable link + wingxa.h (= 9 関数 prototype 参照、stub 実装の declarations 出所) + wingxa_stub no-op 実装 (= 外部 link fallback 兼用、design L40 Out of Boundary 例外配置)_

## 2. Core Library — Concentration Clamp + Mean Composition Corrector

- [x] 2.1 (P) Concentration Clamp 実装
  - test first = `tests/test_concentration_clamp.cpp` 作成 = (a) `c2 = 0` → `eps` (= `std::abs(actual - 1.0e-6) < 1e-15` で literal 値 round-trip 検証)、(b) `c2 = 1` → `1 - eps` (= 同 tolerance)、(c) `c3` 同様、(d) `c2 + c3 = 1.5` → 同比例縮小で `c2 + c3 ≤ 1 - 2*eps + 1e-15` (= 浮動小数点 buffer 含む)、(e) idempotency (= 2 連続呼出で全 grid `==` 完全一致)、(f) AC8 後 AC4-7 再違反 case (= 比例縮小で `c2 + c3 = 1 - 2*eps` strict 下回り) で再 iter 後収束、(g) MAX_ITER 超過 case (= 病的入力 `c2 = eps/2`, `c3 = 1 - eps/2` 等) で last-resort 適用 + non-zero return + stderr に "clamp non-convergence after MAX_ITER=10" 文字列 + step 値 ("init" or step 数値) + grid index (i,j) + 違反値 c2/c3/c1 含有 grep 確認、`make tests` で fail 確認
  - impl = `src/concentration_clamp.cpp` で `int clamp_concentrations(Field&, Field&, int step = -1)` 実装、step は MAX_ITER 超過時 stderr diagnostic 用 caller context (= Numerical Engine は実 step 渡し、Initial Field Builder は -1 渡し = 初期化時を示す sentinel)、全 grid に `§10` AC4-AC8 統合適用 loop (= MAX_ITER=10 上限) + last-resort sum constraint enforcing 比例縮小、超過時 stderr diagnostic (= step (= -1 なら "init" 表示) / 該当 grid index / 違反値 c2/c3/c1 / "clamp non-convergence after MAX_ITER=10") + non-zero return → caller `time_step` non-zero return → main `return 6`
  - 注 = `MAX_ITER=10` は req `## Boundary Context` out-of-scope「反復制御の書き方」に対する design L368 上書き規範 (= 病的入力 fail-safe 確保のため本 spec で具体値固定)
  - 観測条件: `make tests` で全 test pass + 境界 case 5 種で期待値完全一致 + MAX_ITER 超過 case 1 件発動 + last-resort 後 sum constraint `c2 + c3 ≤ 1 - 2*eps` 必ず満足
  - _Requirements: 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_
  - _Boundary: Concentration Clamp (layer: Core); allowed_outbound: <cstdio> (stderr diagnostic on MAX_ITER overflow only、pure 補正本体は外部依存なし)_

- [x] 2.2 Mean Composition Corrector 実装
  - test first = `tests/test_mean_correction.cpp` 作成 = (a) 平均偏差 `0.01` 与え補正後の平均 - target が `< 2 * CLAMP_EPS * ND * ND = 2.0e-2` 以内 (= 本 spec 内 unit test + acceptance test 統一閾値、Req 3 AC9 priority note bounded 範囲の実装規範化)、(b) 補正後 4 濃度制約満足 (= 各 grid で `c2 > 0`, `c3 > 0`, `c2 + c3 < 1` を `>= CLAMP_EPS` 余裕付きで assert)、(c) 内部 Clamp non-convergence 注入 case (= 病的入力で内部 `clamp_concentrations` MAX_ITER 超過) で `correct_mean_composition()` non-zero return 確認、`make tests` で fail 確認
  - impl = `src/mean_correction.cpp` で `int correct_mean_composition(Field&, Field&, double c2a, double c3a)` (= 0 success / non-zero on internal clamp non-convergence) 実装、`§12` 4 step (= avg → delta → 一様減算 → 再 clamp)、内部 `clamp_concentrations()` 戻り値非 0 で本関数も非 0 return → caller (= Numerical Engine step (6)) non-zero return → time_step non-zero return → main `return 6`
  - 観測条件: `make tests` で 3 test pass + 補正後の Field 平均が target 値に収束 + 内部 Clamp 失敗 propagation 確認
  - _Requirements: 3.9_
  - _Boundary: Mean Composition Corrector (layer: Core); allowed_outbound: Concentration Clamp (再 clamp)_
  - _Depends: 2.1_

## 3. Core Library — Initial Field + Numerical Engine

- [x] 3.1 Initial Field Builder 実装
  - test first = `tests/test_initial_field.cpp` 作成 = (a) 同 seed (= `seed = 42`) で 2 回呼出し結果 `Field` 全 grid `==` 完全一致 (= deterministic RNG = bit-exact、tolerance 不要)、(b) 平均が `c2a - fluct_amp <= avg_c2 <= c2a + fluct_amp + 1e-12` (= 浮動小数点 naive sum 誤差 buffer)、(b') 病的 c2a 入力 case (= `c2a = 0.005, c3a = 0.005, fluct_amp = 0.01` の初期 clamp 多発条件) で `build_initial_field` 呼出後、本関数 0 return (= clamp 非 non-convergence)、ただし initial field の実際平均 `avg_c2` が `c2a = 0.005` から bounded deviation で乖離していることを assert (= 初期 clamp が field 変更した事実を test layer に記録、Mean Composition Corrector が time step 1 で補正する前提条件、Req 3 AC2 Note 整合)、(c) 4 濃度制約満足 (= `>= CLAMP_EPS` 余裕付き assert)、`make tests` で fail 確認
  - impl = `src/initial_field.cpp` で `int build_initial_field(c2, c3, c2a, c3a, fluct_amp, seed)` (= 0 success / non-zero on internal clamp non-convergence) 実装、`std::mt19937` + uniform `[-fluct_amp, +fluct_amp]` ゆらぎ追加 + 終端で `clamp_concentrations()` 呼出 (= `§10` 4 timing の「初期化時」、戻り値 non-zero で本関数も非 0 return → caller `pfm_sim_main` で `return 6` 伝播)
  - 注 = `fluct_amp` は caller (= Simulation Module) が `§9` 既定値 `0.01` を渡す前提、本 builder 自身は default 値固定しない (= Req 3 AC1 / design L688 SSoT 規約)
  - 注 = `std::mt19937` は req `## Boundary Context` out-of-scope「乱数生成器の具体実装」に対する design L296 上書き規範 (= deterministic seed reproducibility 確保のため本 spec で具体実装固定)
  - 観測条件: `make tests` で 3 test pass + deterministic 性確認
  - _Requirements: 3.1, 3.2_
  - _Boundary: Initial Field Builder (layer: Core); allowed_outbound: Concentration Clamp (終端 clamp), std::mt19937 (RNG)_
  - _Depends: 2.1_

- [x] 3.2 Numerical Engine 実装
  - test first = `tests/test_numerical_engine.cpp` 作成 = (a) `compute_potentials` で 4 grid 単純例 (= `c2 = c3 = 0.3` uniform field、Laplacian = 0) の `μ2_chem` / `μ3_chem` が `tests/precompute_reference.py` で算出した anchor 値と一致 (= tolerance `1e-12`、Python script は `§6` 数式 + `§8` 13 定数を full precision で代入し `print(repr(value))` で test source 埋込、test source 冒頭 comment に `// reference computed by tests/precompute_reference.py @ commit XXX` 明記)、(b) `laplacian` で周期境界 case (= grid 端点 `(0, 0)`, `(ND-1, ND-1)`) の値が手計算と tolerance `1e-12` で一致、(c) 1 step `time_step` 結果が 4 grid 単純例で reference 一致 (= 同 tolerance)、(d) NaN/Inf 注入 case (= 病的 delt or 異常初期値で step (4) で c2_new に nan 注入する fixture 経由) で `time_step` non-zero return + stderr 1 行に `[NUM_DIVERGENCE]` 識別子 + `step_num` 数値 + grid index `(i,j)` tuple + 違反値 c2/c3/c1 浮動小数点 + sub-case "NaN/Inf detected" 文字列 の 5 項目すべて grep 検証 (= design L882 normative)、(e) step (0) entry-clamp 順序検証 (= 入力 c2/c3 が制約逸脱でも step (0) 後に正常範囲)、`make tests` で fail 確認
  - impl = `src/numerical_engine.cpp` で `compute_potentials()` (= `§6` 化学ポテンシャル + 勾配エネルギー)、`laplacian()` (= 5 点差分 + 周期境界 `(i ± 1 + ND) % ND`)、`int time_step(Field& c2, Field& c3, double c2a, double c3a, double delt, int step_num = -1)` (= 0 success / 1 NaN/Inf or clamp non-convergence、`step_num` は caller pfm_sim main から累積 step 値渡し = NaN/Inf 検出時 stderr diagnostic に出力、`§11` 7 step + step (0) entry-clamp 順厳守 = step (0) Concentration Clamp pre-potential / step (1) μ 計算 / step (2) lap(μ) / step (3) dc/dt / step (4) temp 配列更新 / step (5) Clamp / step (6) Mean Correction (内部 Clamp、戻り値 non-zero で time_step non-zero return 伝播 → main return 6) / step (7) post-correction Clamp、計 1 time step に Clamp 3 + Mean Correction 1 invoke = 階層委譲: Numerical Engine → Mean Composition Corrector → Concentration Clamp)
  - impl 追加 = step (4) → step (5) 間で c2_new/c3_new に対し `std::isnan` / `std::isinf` check、検出時 stderr diagnostic (= step / grid index (i,j) / 違反値 c2/c3/c1) 出力 + non-zero return → caller `pfm_sim_main` で `return 6` (Numerical divergence)
  - impl 追加 = 内部 static 配列 lifecycle (= mu2/mu3/temp_c2/temp_c3 = 320 KB を Numerical Engine 内部 static で 1 度確保、外部から不可視、step (2) lap(μ) は on-the-fly stencil 再計算で追加配列なし)
  - Risks = `delt` CFL-like 安定条件目安 (= Cahn-Hilliard explicit Euler の `delt < O(dx^4 / (kappa * M))`、`ND = 100` / `§8` 既定値下で `delt < 1e-3` 程度を推奨)、user 責任
  - 観測条件: `make tests` で 5 test pass + 計算順序 step (0) + (1)-(7) の 8 step 厳守 (= step (0) entry-clamp invoke 確認 + step 5/6/7 で適切な dependency 呼出 + step 6 内部 Clamp invoke 確認 + step 6 戻り値 propagation 確認)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3.3_
  - _Boundary: Numerical Engine (layer: Core); allowed_outbound: Concentration Clamp (step 0/5/7), Mean Composition Corrector (step 6), <cmath> (log/isnan/isinf), <cstdio> (stderr diagnostic on NaN/Inf detection)_
  - _Depends: 2.1, 2.2_

## 4. I/O Library — Snapshot Writer + Reader

- [x] 4.1 (P) Snapshot Writer 実装
  - test runner structure = `tests/test_snapshot_io.cpp` 内 1 個の `main()` で write tests + read tests を sequential 呼出、4.1 では write 関数 + main 骨格 (= write tests のみ呼出)、4.2 では read 関数追加 + main から read 呼出 (= main 二重定義回避、link error 防止)
  - test first = `tests/test_snapshot_io.cpp` の write 部 = (a) `time1 = 0.0` + 既知 `c2/c3` Field を Overwrite mode で write、出力 file が `§16` 形式 (= `time1` + `ND*ND` 個の `(c2, c3)` ペア、空白/改行区切り) を満たす、(b) Append mode で 2 snapshot 連続書出後 file size が 2 倍程度、(c) round-trip test = `time1 = 0.5`, `c2 = 0.25`, `c3 = 0.125` (= dyadic fraction = exact IEEE 754 representable) で write → read 後 `std::memcmp(&original, &readback, sizeof(double)) == 0` で bit-exact 一致 (= `%.17g` IEEE 754 round-trip 仕様検証、test 環境 = `g++ -std=c++17` glibc / libstdc++ 前提)、(d) write 中 I/O error mock = `fopen` success 後の最初の `fprintf` を mock 戻り値 -1 にする fixture (= LD_PRELOAD or wrapper 経由の writer mock) で `fprintf` 失敗注入、本関数 non-zero return + `std::filesystem::exists(path)` false (= partial file 削除済) + stderr に `[FS]` 識別子 + path + errno 含有確認、(e) `fclose` 失敗 mock = `fclose` を EOF return に差替えた fixture で同 contract 検証、`make tests` で fail 確認
  - impl = `src/snapshot_io.cpp` で `int write_snapshot(path, time1, c2, c3, mode)` (= 0 success / non-zero on I/O error) 実装、`enum class WriteMode { OverwriteOrCreate, Append }` を引数で受け、Overwrite/Append で `fopen` の mode `"w"` / `"a"` 切替、`fprintf("%.17g", ...)` で IEEE 754 double round-trip safe (= `%.15g` では一部値で誤差残存 + read 側 `fscanf("%lf")` との対称性で round-trip 完全復元保証)
  - impl 追加 = `time1 = step_count * delt` (= 物理時刻 = 累積 step 数 × delt、初期 snapshot は `time1 = 0.0`、Req 4 AC1)
  - error path = `fprintf` 戻り値 < 0 検出 + `fclose` 戻り値 EOF 検出時 = stderr diagnostic (= `[FS]` 識別子 + path + `errno` + 失敗 step) + `std::filesystem::remove(path)` で partial file 削除 (= 後続 reader の parse error 連鎖防止) + non-zero return → main `return 3`、`std::filesystem::remove` が例外 throw or false return した second-level error 時は additional stderr diagnostic (= `[FS_CLEANUP]` + path) 出力で remove 失敗を通知し non-zero return を継続
  - 観測条件: `make tests` の write test 3 件 pass + 出力 file が後続 task 4.2 の reader で round-trip 可能
  - _Requirements: 4.1, 4.2, 4.3, 4.4_
  - _Boundary: Snapshot Writer (layer: I/O); allowed_outbound: <cstdio> (fopen/fprintf/fclose), <filesystem> (remove on partial)_

- [x] 4.2 (P) Snapshot Reader 実装
  - test first = `tests/test_snapshot_io.cpp` の read 部 = (a) 4.1 で書いた 3-snapshot file を `read_snapshot()` で順次 read、各 snapshot の `time1, c2, c3` が write 時と完全一致、(b) `seek_snapshot(2)` で index 2 取得、(c) 不正形式 file (= 値欠損 / 非数値混入) で non-zero return + stderr に `[SNAPSHOT_PARSE]` 識別子 + 行番号 + 期待 token 種別 含有確認 (= design L880 normative)、`make tests` で fail 確認
  - impl = `src/snapshot_io.cpp` で `int read_snapshot(FILE*, time1, c2, c3)` / `int seek_snapshot(FILE*, snapshot_index, time1, c2, c3)` 実装、`fscanf("%lf", ...)` の戻り値 check で error 検出
  - 責務分担 = `fopen` は caller (= Re-render Function / BMP Writer) 担当、Snapshot Reader は `FILE*` を引数で受け read 段階の I/O / parse error のみ責務 (= Req 6 AC4 file open 失敗は caller、Req 6 AC5 parse error は本 component)
  - failure 時 contract = `seek_snapshot` 失敗時 FILE* position は不定、caller は次 read 前に rewind/fseek で再 positioning が必要
  - 観測条件: `make tests` の read test 3 件 pass + 不正 input で exit code non-zero
  - _Requirements: 4.7, 4.8, 6.4, 6.5_
  - _Boundary: Snapshot Reader (layer: I/O); allowed_outbound: <cstdio> (fscanf)、test source = test_snapshot_io.cpp に test 関数のみ追加 (= 4.1 の main を再利用、test runner 二重定義禁止、task 1.3 規約整合)_
  - _Depends: 4.1_

## 5. Visualization Library — Renderer + BMP Writer + Re-render

- [x] 5.1 Renderer 実装
  - test first = `tests/test_renderer.cpp` 作成 = `compute_color(c2, c3)` を pure 関数として抽出、(a) `c2 = c3 = 0` → `(R, G, B) = (255, 0, 0)`、(b) `c2 = 1, c3 = 0` → `(0, 255, 0)`、(c) `c2 = c3 = 0.5` → `(0, 127, 127)` (= `static_cast<int>(0.5 * 255) = 127` truncation 結果)、(d) `c2 + c3 > 1` overflow case で `[0, 255]` clamp、(e) 負値 float → int 変換境界 = `c2 = -0.001`, `c3 = -0.001` で compute_color 戻り値 `(R=255, G=0, B=0)` (= float 段階 clamp で int 負値 path 不到達)、(f) `poll_keypress()` の non-interactive mode 動作 (= CI 環境前提、`isatty(STDIN_FILENO)` false で 0 return、interactive mode = 端末で `wingxa.h::keypress()` wrapper 経由動作は手動確認)、(g) `init_drawing_buffer()` の wingxa API 呼出順検証 = `tests/fixtures/mock_wingxa_record.cpp` (= 各 wingxa API 呼出を順次 vector に push する recording mock) を test 専用 LDFLAGS で link、`init_drawing_buffer()` 呼出後の record vector が `[gwinsize(400,400), ginit(0), gsetorg(0,0)]` の 3 entry 厳密一致、(h) `render_field()` 全 grid 描画完了検証 = recording mock を render_field にも適用、`render_field(c2_uniform, c3_uniform)` 呼出後 mock の `gcolor` 呼出回数 = `grect` 呼出回数 = `ND * ND` = 10000 確認 (= for loop 早期 return バグ検出、production wingxa での void return silent fail に対する代替 observability)、`make tests` で fail 確認
  - impl = `src/renderer.cpp` で `compute_color()` (= `§17` formula `R = std::clamp(1.0 - c2 - c3, 0.0, 1.0)` / `G = std::clamp(c2, 0.0, 1.0)` / `B = std::clamp(c3, 0.0, 1.0)` で float 段階 clamp + `static_cast<int>(R * 255)` 等で `0..255` 整数化、負値 float → int 変換の implementation-defined 回避) + `render_field()` (= 全 grid 走査 + `gcolor` + `grect` 呼出、描画域 400x400 を `ND=100` の 4x4 ピクセル整数倍 fill = `static_assert(DRAW_W % ND == 0)` 担保、wraparound 列追加描画は採用しない、Req 5 AC5 pass 条件 = 全格子点 (`0 ≤ i, j ≤ ND - 1`) 描画 + 隣接格子間 visible gap なし)
  - impl 追加 = `int init_drawing_buffer()` (= 内部で wingxa API 呼出順 `gwinsize(DRAW_W, DRAW_H)` → `ginit(0)` → `gsetorg(0, 0)` の順で呼出 (= `§14` (e) 内部の 3 API 呼出順、`§14` 全体の (d)(e)(f) step 番号とは別)、3 関数すべて `void` return = wingxa.h SSoT 制約下で失敗検出 mechanism なし、本 wrapper は best-effort 実装で常に 0 return、Application 層の wingxa.h 直接依存禁止のみ責務 = Req 1 AC9 / Req 5 AC6 / 依存方向 Application → Visualization → wingxa.h 単一方向)
  - 注 = `return 7` Renderer init failure exit code は本 spec で採用しない (= wingxa.h `void` return 制約下で失敗検出 mechanism が SSoT 違反なしに実装不能、exit code 体系は `return 2-6` の 5 category)
  - 注 (Limitation) = production 実 wingxa link 時の `gwinsize`/`ginit`/`gsetorg` silent fail (= void return で内部 error 隠蔽) は本 spec で観測手段なし (= wingxa.h SSoT 制約、design L52 Revalidation Triggers で wingxa.h signature 変更時に再 review 規範)。BMP Writer silent fail fallback (= 5.2 (e) test) が間接的に検出する範囲のみ運用上保証、init 段階の silent fail は user 受容前提、Limitation として acceptance test 7.5 結果 record に明示する
  - impl 追加 = `int poll_keypress()` (= `isatty(STDIN_FILENO)` で stdin 非対話判定、非対話なら即 0 return、対話なら `wingxa.h::keypress()` 戻り値 return、`§15` 停止条件は本 wrapper 経由で安全吸収)
  - mock fixture Boundary: `tests/fixtures/mock_wingxa_record.cpp` (layer: Test artifact); allowed_outbound: `<vector>`, wingxa.h API 9 関数 declarations のみ (= 各関数で呼出順 record 副作用のみ実装、production `wingxa_stub.cpp` と link 衝突回避のため test 専用 LDFLAGS で link、本 spec scope 内 Test artifact layer に隔離)
  - 観測条件: `make tests` で compute_color test 5 件 + poll_keypress test 1 件 + init_drawing_buffer 呼出順 record test 1 件 + render_field call count test 1 件 pass、`render_field()` の visual 確認自体は手動目視 (= task 5.3 完成後、call count automated check は本 task で実装)
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 1.9_
  - _Boundary: Renderer (layer: Visualization); allowed_outbound: wingxa.h::gcolor/grect (= render_field 内のみ、直接呼出可), wingxa.h::gwinsize/ginit/gsetorg (= init_drawing_buffer 内のみ呼出), wingxa.h::keypress (= poll_keypress 内のみ呼出); `itoa` は本 spec scope で不使用 (= req.md L114 9 関数 declare 済の中で本 spec は 8 関数のみ依存、BMP 名生成は `std::to_string` 等 C++ 標準で代替), <unistd.h> (isatty)_

- [x] 5.2 (P) BMP Writer 実装
  - test first = `tests/test_bmp_writer.cpp` 作成 = (a) `write_bmp_default_steps` の 17 step 列挙が `§19` の `{0, 2000, 4000, ..., 80000}` と完全一致 (= 内部 step 配列 expose or BMP file 名 grep)、(b) `write_bmp_steps(snapshot, dir, K=5000, max=50000, D=2000)` で `{0, 5000, ..., 50000}` 11 step 生成、(c) snapshot index 計算 = `step / data_interval` 検証 (= `step=10000, data_interval=2000` で `index=5`)、(d) FILE* `fopen(snapshot_path)` NULL case で `fclose` 不呼出 + non-zero return 確認、(e) `save_screen` silent fail = mock save_screen 提供で BMP file 不生成 case の `std::filesystem::exists` 経由検出 + stderr に `[BMP_SAVE]` 識別子 + bmp path + snapshot index + `save_screen` 戻り値 0 含有確認 (= design L881 normative diagnostic format grep 検証、silent fail を観測 layer で確実に検出)、(f) `seek_snapshot` 失敗連鎖防止検証 = 17 step batch loop で step index 4 のみ seek 失敗注入 fixture、step index 5 以降の seek が正常動作 (= 連鎖しない) 確認 + first-fail-exit 規則により step index 5-16 未生成、`make tests` で fail 確認
  - impl = `src/bmp_writer.cpp` で `int write_bmp_for_snapshot(snapshot_path, snapshot_index, bmp_path)` (= snapshot read → render_field → save_screen → 出力 path) + `int write_bmp_default_steps(snapshot_path, bmp_dir)` (= `§19` 17 step hardcode batch 出力 = `0, 2000, 4000, 6000, 8000, 10000, 12000, 14000, 16000, 18000, 20000, 30000, 40000, 50000, 60000, 70000, 80000`、step `N` の snapshot index = `N / data_interval`、内部 hardcode `data_interval = 2000`) + `int write_bmp_steps(snapshot_path, bmp_dir, bmp_interval, max_step, data_interval)` (= 動的等差列 step 群 `{0, K, 2K, ...} ∩ {≤ max_step}` 生成、各 step → snapshot index = `step / data_interval` で seek、Req 4 AC5 param 変更時規則対応)
  - 注 = `write_bmp_default_steps` は `§13` 既定 `data_interval = 2000` を内部 hardcode 前提 (= `§19` 17 step 列挙が既定 param 依存のため)、`write_bmp_steps` は caller (= pfm_bmp_main) から `--data-interval D` 引数値を渡す (= param 変更時規則対応、Req 4 AC5)
  - partial 完了規則 = `write_bmp_default_steps` + `write_bmp_steps` ともに **first-fail-exit** (= 最初の step 失敗で即 return non-zero、残 step は実行しない、partial BMP 出力 avoid)、`seek_snapshot` 失敗時は次 step seek 前に `rewind(fp)` で FILE* を先頭に再 positioning (= seek 失敗連鎖防止、design L501 義務転記、ただし first-fail-exit 規則下では rewind 後に return non-zero で loop 終了)
  - error path = read 失敗で `return 3` / parse 失敗で `return 4` / save_screen 失敗で `return 5`
  - error path 判定順位 = (1) `save_screen` 戻り値非 0 で即 `return 5`、(2) 0 でも `std::filesystem::exists(bmp_path)` false または `std::filesystem::file_size(bmp_path) == 0` なら stderr diagnostic + `return 5` (= silent fail fallback)、両 check 通過で success
  - error path 追加 = FILE* failure path (= `fopen(snapshot_path)` NULL なら `fclose` 呼ばず stderr diagnostic + non-zero return → main `return 3`、fopen 成功後は `fclose` 必ず呼出)
  - 観測条件: `write_bmp_default_steps` で `§19` 17 step BMP 全 file 存在 + `write_bmp_steps` で K=2000, max-step=100000 で 51 step 出力の両 branch 動作、`ls output/*.bmp` で存在確認、不正 input で non-zero
  - _Requirements: 4.5, 4.9, 6.6_
  - _Boundary: BMP Writer (layer: Visualization); allowed_outbound: Snapshot Reader (I/O direct), Renderer (Visualization), wingxa.h::save_screen (external P0), <cstdio> (fopen/fclose), <filesystem> (exists/file_size); forbidden: wingxa.h::save_screen 以外の 8 関数 direct (= gcolor/grect は Renderer 経由、gwinsize/ginit/gsetorg は caller pfm_bmp_main 起動時 init_drawing_buffer で呼出済、keypress/swapbuffers/itoa は BMP Writer 責務範囲外)_
  - _Depends: 4.2, 5.1_

- [x] 5.3 (P) Re-render Function 実装
  - impl = `src/re_render.cpp` で `int re_render_all(snapshot_path)` (= snapshot file 全 snapshot を順次 `render_field` + `swapbuffers`、`Renderer::poll_keypress()` wrapper 経由で停止判定 = wingxa.h 直接依存禁止 = Req 5 AC6 / Application → Visualization 単一方向)
  - 停止 contract = poll_keypress 戻り値非 0 検出時に「現 snapshot 描画 + swapbuffers 完了後」のタイミングで停止 (= `§15` 停止 semantics、即時停止 / 次 snapshot 前停止ではない)
  - error path = file open 失敗で `return 3` / parse 失敗で `return 4`
  - 観測条件: snapshot file load → live display 動作 (= 手動目視)、不正 file で exit non-zero
  - 注 (Limitation) = `swapbuffers` は void return のため silent fail 検出手段なし、wingxa stub vs production wingxa の動作差異は本 task 観測範囲外 (= known limitation、design Monitoring 節 L871 へも明示記録、production deploy 時の手動確認に依存)
  - _Requirements: 4.6_
  - _Boundary: Re-render Function (layer: Visualization); allowed_outbound: Snapshot Reader (I/O direct), Renderer (Visualization、render_field + poll_keypress), wingxa.h::swapbuffers (external P0); forbidden: wingxa.h::keypress direct (= Renderer::poll_keypress 経由のみ), wingxa.h::gwinsize/ginit/gsetorg direct (= caller pfm_render_main が起動時 1 度 init_drawing_buffer 呼出済、本 component は init 不依存)_
  - _Depends: 4.2, 5.1_

## 6. Application — 3 Executables

- [x] 6.1a pfm_sim CLI parser + 値域 check (Simulation Module 第 1 段) [推定 2h]
  - test first = `tests/test_pfm_sim_cli.cpp` 作成 = (a) 正常系 `--c2a 0.3 --c3a 0.3 --delt 0.005` で parse 成功 + parameter struct 値域内、(b) `--c2a -0.1` で exit code 2 + stderr `[CLI]` 識別子 + 違反引数名 + 違反値、(c) `--c2a 0.6 --c3a 0.5` (= `c2a + c3a >= 1`) で exit code 2、(d) `--delt 0` で exit code 2、(e) 必須 `--delt` 欠落で exit code 2、(f) 数値変換失敗 (= `--c2a abc`) で exit code 2、`make tests` で fail 確認
  - impl = `src/pfm_sim_cli.cpp` で `int parse_cli(int argc, char** argv, SimParams& out)` (= 0 success / 2 不正引数 + stderr diagnostic) 実装、CLI = `--c2a / --c3a / --delt` 必須 (= SSoT `§13` 「平均組成 `c2`」「平均組成 `c3`」の正規名、`§9`/`§12` 命名統一)、`--max-step / --data-interval / --bmp-interval / --output-dir / --seed` 既定値あり (= `§13` reference、`--seed` 既定 `0`)
  - 値域 check = `0 < c2a < 1`, `0 < c3a < 1`, `c2a + c3a < 1`, `delt > 0`, `max-step / data-interval / bmp-interval > 0` (= 整数)、文字列引数の数値変換失敗 (= `std::stod` exception) も exit code 2
  - 観測条件: `make tests` で 6 unit test pass、main 統合は 6.1c で行うため本 task は parser + 値域 check 単独で完結
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 6.1, 6.2_
  - _Boundary: pfm_sim CLI parser (layer: Application); allowed_outbound: <string> (std::stod), <iostream> (stderr); forbidden: wingxa.h direct_

- [x] 6.1b pfm_sim 起動 sequence + 初期 snapshot/BMP (Simulation Module 第 2 段) [推定 1.5h]
  - test first = smoke test = `tests/test_pfm_sim_init.sh` 作成 = (a) 0 step run (= `--max-step 0` で起動 sequence のみ実行) で `output/snapshot.txt` 存在 + 初期 BMP 1 file 存在 + exit 0、(b) 出力 dir 不在で `create_directories` 動作確認、(c) 病的 c2a/c3a 入力 case (= `c2a = CLAMP_EPS / 4 = 2.5e-7` 等で `build_initial_field` 内 `clamp_concentrations` が MAX_ITER 超過 trigger) で `run_init_sequence` non-zero return + main exit code 6 + stderr `[NUM_DIVERGENCE]` 識別子 + sub-case `clamp non-convergence after MAX_ITER=10` + `step="init"` 含有確認 (= chain 伝播検証 = build_initial_field non-zero → run_init_sequence non-zero → main return 6)、`make tests` で fail 確認
  - impl = `src/pfm_sim_init.cpp` で `int run_init_sequence(const SimParams& p)` (= 0 success / non-zero on filesystem or 初期 snapshot/BMP 失敗) 実装、`§14` 起動順 (a) parameter 解釈済 (= 6.1a 完了) → (b) 出力 dir 確認 (`std::filesystem::exists`) → (c) 必要なら作成 (`std::filesystem::create_directories`) → (d) `build_initial_field()` (= `fluct_amp = 0.01` を `§9` 既定値として Simulation Module から渡す、Initial Field Builder 自身は default 持たない、Req 3 AC1 / design L688 SSoT 規範) → (e) `Renderer::init_drawing_buffer()` (= Renderer wrapper、内部で wingxa.h gwinsize/ginit/gsetorg 呼出、Application 層は wingxa.h 直接依存禁止 = Req 1 AC9 / Req 5 AC6) → (f) 初期 snapshot (= `time1 = 0.0`, OverwriteOrCreate mode) + 初期 BMP (= step 0 で `write_bmp_for_snapshot`) 出力
  - error path = filesystem 操作失敗で stderr `[FS]` + `return 3`、`build_initial_field` non-zero return で stderr `[NUM_DIVERGENCE]` + `return 6`、Snapshot Writer / BMP Writer non-zero return で `return 3` / `return 5` 伝播
  - 観測条件: `make tests` で smoke test 2 件 pass + 0 step run output が parse 可能
  - _Requirements: 1.6, 3.1, 4.1, 4.3, 5.6, 6.3_
  - _Boundary: pfm_sim 起動 sequence (layer: Application); allowed_outbound: Initial Field Builder, Snapshot Writer, BMP Writer, Renderer (= Core/I/O/Visualization service), <filesystem> (exists/create_directories); forbidden: wingxa.h direct_
  - _Depends: 3.1, 4.1, 5.1, 5.2, 6.1a_

- [x] 6.1c pfm_sim main loop + 停止条件 + stderr diagnostic (Simulation Module 第 3 段) [推定 2.5h]
  - test first = `tests/test_pfm_sim_loop.sh` 作成 = (a) 10 step run で正常終了 + step 10 で snapshot/BMP 出力、(b) `Renderer::poll_keypress()` mock = 第 5 step で 1 return 注入 → exit 0 (= `§15` 停止条件) + exit 後の output dir 状態確認 = `snapshot.txt` 内 snapshot 数が `data_interval` 規則に従う数量 (= 5 step で `data_interval=10` なら 1 snapshot のみ = 初期 step 0 のみ)、BMP file 数が `bmp_interval` 規則に従う数量 (= 同 1 file のみ)、partial / 中途半端な write がないこと assert (= 停止 semantics の partial state 検証)、(c) NaN/Inf 注入 (= `--delt 0.5` CFL violation) で exit code 6 + stderr `[NUM_DIVERGENCE]`、(d) Snapshot Writer mock fail で exit code 3 + stderr `[FS]` (= write 失敗 path)、(e) BMP Writer mock fail で exit code 5 + stderr `[BMP_SAVE]`、`make tests` で fail 確認
  - impl = `src/pfm_sim_main.cpp` で `int main(int argc, char** argv)` 実装 = `parse_cli` → `run_init_sequence` → main loop (= `§11` 7 step + step (0) entry-clamp 経由 `time_step` 呼出、step counter / `data_interval` 判定で snapshot Append 出力 / `bmp_interval` 判定で BMP 出力、`§15` 停止条件 = `max-step` / `Renderer::poll_keypress()` 非 0 / `time_step` non-zero return = `return 6` / I/O error = `return 3` or `return 5`)
  - 異常終了 = design Error Categories normative = 5 category × return code 2-6 (= `return 2` 不正引数 / `return 3` FS or Snapshot file open / `return 4` Snapshot parse / `return 5` BMP save / `return 6` Numerical divergence or clamp non-convergence)、`std::abort` 不採用 (= stdio buffer flush 保証 + exit code 1-127 統一、`std::cerr.flush() + std::cout.flush()` を `return` 直前に明示呼出)、stderr diagnostic は category 別 normative format (= `[CLI]` / `[FS]` / `[SNAPSHOT_OPEN]` / `[SNAPSHOT_PARSE]` / `[BMP_SAVE]` / `[NUM_DIVERGENCE]` 識別子 + 1 行 1 message + category 必須情報項目)
  - 観測条件: `make tests` で 5 unit test pass、加えて `./pfm_sim --c2a 0.3 --c3a 0.3 --delt 0.005 --max-step 10` で 10 step 実行 → output dir に `snapshot.txt` + 初期 BMP + step 10 BMP 生成、exit 0
  - _Requirements: 1.7, 1.8, 1.9, 1.10, 4.4, 6.4, 6.5, 6.6_
  - _Boundary: pfm_sim main loop (layer: Application); allowed_outbound: Numerical Engine, Snapshot Writer, BMP Writer, Renderer (= Core/I/O/Visualization service); forbidden: wingxa.h direct, Snapshot Reader direct (= Visualization service (BMP Writer) 経由のみ、design L118 / L592 整合)_
  - _Depends: 3.2, 6.1b_

- [x] 6.2 (P) pfm_render 実装
  - impl = `src/pfm_render_main.cpp` で CLI parser (= snapshot file path 1 引数) + `Renderer::init_drawing_buffer()` (= Renderer wrapper、内部で wingxa.h gwinsize/ginit/gsetorg 呼出) + `re_render_all()` 呼出
  - error path = `re_render_all()` 戻り値非 0 で適切な error code (= snapshot open `return 3` / parse `return 4`) 伝播
  - 観測条件: `./pfm_render <snapshot_file>` で連続描画動作 (= 手動目視)、不正 file で exit non-zero (= 3 or 4)
  - _Requirements: 4.6, 5.6, 6.4, 6.5_
  - _Boundary: pfm_render_main (layer: Application); allowed_outbound: Renderer (init_drawing_buffer wrapper), Re-render Function (Visualization service); forbidden: wingxa.h direct, Snapshot Reader direct (= Re-render Function 経由のみ、design L118 / L592 整合)_
  - _Depends: 5.3_

- [x] 6.3 (P) pfm_bmp 実装
  - impl = `src/pfm_bmp_main.cpp` で CLI parser (= snapshot file + 出力 dir + optional `--bmp-interval K` + `--max-step N` + `--data-interval D` (= `§13` 既定 `2000`)) + `Renderer::init_drawing_buffer()` (= Renderer wrapper) + branch: `--bmp-interval` 未指定なら `write_bmp_default_steps()` 呼出 (= `§19` 17 step hardcode)、指定なら `write_bmp_steps(snapshot, out_dir, K, N, D)` 呼出 (= 動的等差列、Req 4 AC5)
  - error path = BMP write 戻り値非 0 で適切な error code (= `return 3` / `return 5`) 伝播
  - 観測条件: `./pfm_bmp <snapshot> <out_dir>` 実行後、`out_dir` 内に `§19` 17 step 群 BMP 全 file 存在、exit 0、`./pfm_bmp <snapshot> <out_dir> --bmp-interval 5000 --max-step 50000` で `{0, 5000, ..., 50000}` 11 step BMP 出力
  - _Requirements: 4.5, 4.9, 6.4, 6.5, 6.6_
  - _Boundary: pfm_bmp_main (layer: Application); allowed_outbound: Renderer (init_drawing_buffer wrapper), BMP Writer (Visualization service); forbidden: wingxa.h direct, Snapshot Reader direct (= BMP Writer 経由のみ、design L118 / L592 整合)_
  - _Depends: 5.2_

## 7. Integration & Acceptance

- [x] 7.1 Makefile build target 完結
  - 全 source file の compile rule + `libpfmcore.a` 生成 (= core / I/O lib object 集約) + 3 executable link rule (= libpfmcore.a + Visualization object + wingxa external link via LDFLAGS)
  - debug / release flag (= `-O0 -g` / `-O2`) 切替 variable
  - 観測条件: `make` 1 コマンドで `pfm_sim`, `pfm_render`, `pfm_bmp` 3 binary 全 build success、exit 0
  - _Requirements: 7.1_
  - _Boundary: Makefile (layer: Build artifact); allowed_outbound: 全 layer source compile + libpfmcore.a + 3 executable link_
  - _Depends: 6.1c, 6.2, 6.3_

- [x] 7.2 Integration test = pfm_sim 100 step run + 異常 path 2 case
  - test = `tests/integration_pfm_sim.sh` 作成 = (主 case) `./pfm_sim --c2a 0.3 --c3a 0.3 --delt 0.005 --max-step 100 --data-interval 10 --bmp-interval 10 --output-dir test_output` 実行
  - 観測条件 (主 case 詳細) = (1) snapshot 各 token 数値 + 4 制約満足 (= shell parser `awk '/^[0-9]/{...}'` で全 grid 値 `0 < c2 < 1`, `0 < c3 < 1`, `c2 + c3 < 1`, `c1 = 1 - c2 - c3 > 0` 違反 0 件確認、`§10` 4 制約検証)、(2) `test_output/*.bmp` ちょうど 11 file (= step `0, 10, 20, ..., 100` の 11 個)、(3) `pfm_sim` の stderr に `NaN`/`Inf`/`[NUM_DIVERGENCE]` 識別子 grep 0 件 (= Req 7 AC5)、(4) exit code 0
  - Adversarial test = (a) 病的 `delt = 0.5` (= CFL violation) で 100 step 実行 → step 途中で NaN/Inf 検出 → exit code 6 + stderr diagnostic に `[NUM_DIVERGENCE]` カテゴリ識別子 + step number + grid index `(i, j)` + 違反値 c2/c3/c1 + sub-case (= `NaN/Inf 検出`) 含有確認 (= MAX_ITER 超過 trigger 系 test は task 2.1 unit test (g) で網羅、integration では NaN/Inf path のみ検証)、(b) `pfm_sim --c2a -0.1 --c3a 0.3 --delt 0.005` (= c2a 値域違反) で exit code 2 + stderr `[CLI]` 識別子 + 違反引数名 + 違反値含有確認 (= return 2 carrier、Req 6 AC1 normative)、(c) read-only output dir = `chmod 555 read_only_test_dir` 後 `./pfm_sim --output-dir read_only_test_dir` で exit code 3 + stderr `[FS]` 識別子 + path + errno 含有 grep 確認 (= integration level で実 filesystem error path 発火、unit test (d) mock との対称検証、test 末尾で `chmod` 復元)
  - 観測条件: shell test runner で全 assertion pass (= 主 case 4 項目 + 異常 3 case)、各 exit code (0, 6, 2, 3) 期待通り
  - _Requirements: 1.1-1.10, 2.1-2.9, 3.1-3.9, 4.1-4.5, 5.1-5.6, 6.1-6.6, 7.2, 7.5_
  - _Boundary: pfm_sim integration (layer: Test artifact); allowed_outbound: pfm_sim binary execution_
  - _Depends: 7.1_

- [x] 7.3 Integration test = pfm_render snapshot round-trip
  - test = `tests/integration_pfm_render.sh` 作成 = 7.2 出力 `test_output/snapshot.txt` を `./pfm_render test_output/snapshot.txt` で再描画起動、exit 0、不正 file = `tests/fixtures/broken.txt` (= parse 失敗用) で exit code 4 + stderr `[SNAPSHOT_PARSE]` 識別子 grep 確認、`tests/fixtures/missing.txt` (= 不在 path、open 失敗用) で exit code 3 + stderr `[SNAPSHOT_OPEN]` 識別子 grep 確認
  - 観測条件: shell test runner で 3 case pass (= 正常 + parse 失敗 + open 失敗)
  - _Requirements: 4.6, 4.7, 4.8, 7.3_
  - _Boundary: pfm_render integration (layer: Test artifact); allowed_outbound: pfm_render binary execution_
  - _Depends: 7.1_

- [x] 7.4 Integration test = pfm_bmp 17 step 群 + 動的 step 群
  - test = `tests/integration_pfm_bmp.sh` 作成
  - 事前条件 = test script 冒頭で 100000 step snapshot 生成 = `./pfm_sim --c2a 0.3 --c3a 0.3 --delt 0.001 --max-step 100000 --data-interval 2000 --output-dir test_output_long` 実行 (= wall-clock 約 5 min reference、本 fixture は task 7.5 acceptance test と共用、`test_output_long/snapshot.txt` を re-use)
  - test 本体 = (主 case) `./pfm_bmp test_output_long/snapshot.txt bmp_output` 実行、`§19` 17 step (`0, 2000, ..., 80000`) 群の BMP 全 17 file が `bmp_output/` に存在 + (動的 case) `./pfm_bmp test_output_long/snapshot.txt bmp_output_dyn --bmp-interval 5000 --max-step 50000 --data-interval 2000` で `{0, 5000, ..., 50000}` 11 file が `bmp_output_dyn/` に存在 + (partial fail case) step index 4 で seek 失敗を注入する fixture (= snapshot file の途中切詰版) で `./pfm_bmp` 実行、exit code non-zero + first-fail-exit 規則により BMP file 4 個 (= step 0/1/2/3) のみ存在 + step 4 以降未生成 確認
  - 観測条件: shell test runner で 17 file (主) + 11 file (動的) + 4 file (partial fail) 存在 assertion 全 pass、事前 100000 step run は 1 回のみ (= 7.5 と共用、再実行回避)
  - _Requirements: 4.5, 4.9, 7.4_
  - _Boundary: pfm_bmp integration (layer: Test artifact); allowed_outbound: pfm_bmp binary execution + pfm_sim long run_
  - _Depends: 7.1, 7.2_

- [x] 7.5 Acceptance test = §22 6 項目 final 検証 + Level 6 観測 record
  - test = `tests/acceptance_22.sh` 作成 = (1) `make` build success、(2) `pfm_sim` 起動 + 初期 snapshot + 初期 BMP 出力 (= smoke 100 step run で代替、再実行 cost 軽減)、(3) `pfm_render` で snapshot file load 成功 (= smoke 100 step snapshot 使用)、(4) `pfm_bmp` で 17 step 群出力 (= 7.4 と共用 100000 step snapshot 使用)、(5) 100000 step run 中の `log(c1/c2/c3)` 定義域逸脱なし (= NaN/Inf 検出 grep)、(6) 平均組成保存 (= snapshot 平均算出値が input ± `2 * CLAMP_EPS * ND * ND` 程度、Req 3 AC9 規範下の bounded 範囲、unit test 閾値と統一) 以内 + 全 grid で `§10` 4 制約満足
  - 観測条件: 6 項目全 pass、(5)(6) の 100000 step run は 1 回のみ実行 (= wall-clock 約 5 min reference、再実行 cost 高のため最終 acceptance 段階のみ、(2)(3)(4) の smoke 100 step 出力は別途 short cycle で代替可)。観測 (5) の信頼性は task 7.2 Adversarial test (a) (= 病的 `delt = 0.5` で NaN/Inf 検出 → exit code 6 + diagnostic 5 項目 grep 完全) との対称検証で担保 (= acceptance level の negative assertion = grep 0 件 が positive 検証 carrier に依存する明示、観測 mechanism 完全性の cross-task 連携)。Limitation 記録 = task 5.1 注 (= production 実 wingxa link 時 `gwinsize`/`ginit`/`gsetorg` silent fail 観測手段なし) + task 5.3 注 (= `swapbuffers` void return silent fail 観測手段なし) は本 acceptance test 結果に「known limitation」として明示。結果を Rwiki-dev/.kiro/methodology/v4-validation/samples/a3/3_7_6_1_phase_field_cpp/dev_log.jsonl + rework_log.jsonl に sub_group_key=phase_field_reverse_cpp で append (= Step (3.3) Level 6 観測 trigger)
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_
  - _Boundary: acceptance integration (layer: Test artifact); allowed_outbound: 3 binary execution + dev_log.jsonl/rework_log.jsonl append (= Rwiki-dev/.kiro/methodology/v4-validation/ への cross-spec write、本 spec scope 例外、Step (3.3) Level 6 観測 trigger)_
  - _Depends: 7.2, 7.3, 7.4_
