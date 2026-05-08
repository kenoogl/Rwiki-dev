# cross-spec-tasks-alignment

## 1. この文書の役割

この文書は、multi-feature 開発における `tasks phase` の feature 間整合を記録するための文書である。

`requirements` と `design` の整合が取れていても、`tasks` では次のずれが生じうる。

- 実装順序の衝突
- shared artifact の移行タイミングの不整合
- validator / test の依存順序の逆転
- 同一 directory や同一 file への競合編集
- 下流 feature が上流 feature の未実装 artifact を前提にしている状態

この文書は、それらを implementation 着手前に横断確認し、必要な reopen と修正を記録する。

## 2. alignment gate の対象

`tasks alignment gate` では少なくとも次を確認する。

- implementation order
- blocking dependency
- shared artifact migration timing
- validator / schema / prompt の生成順
- test sequencing
- shared file ownership
- reopen が必要な task 群

## 3. 現在の対象 feature

- `dual-reviewer-foundation`
- `dual-reviewer-runtime`
- `dual-reviewer-evaluation`
- `dual-reviewer-self-improvement`
- `dual-reviewer-paper-interface`

## 4. 確認観点

### 4.1 implementation order

確認すること:

- どの feature が先に artifact を提供する側か
- 後続 feature が未生成 artifact を前提にしていないか

初期の想定順序:

1. `foundation`
2. `runtime`
3. `evaluation`
4. `self-improvement`
5. `paper-interface`

### 4.2 shared artifact migration timing

確認すること:

- `runtime/schemas/`
- `runtime/prompts/`
- `runtime/config/`
- `runtime/validators/`
- `experiments/analysis/`

の各 artifact を、どの task で生成し、どの task から依存してよいか。

### 4.3 validator and test sequencing

確認すること:

- schema 実装前に validator 実装 task が置かれていないか
- runtime artifact 生成前に evaluation fixture task が置かれていないか
- invalidation marker 定義前に exclusion logic task が置かれていないか

### 4.4 shared file ownership

確認すること:

- 同一 file / directory に対して複数 feature が曖昧に ownership を持っていないか
- 共有 file は foundation 側 task に寄せるべきか

## 5. 記録フォーマット

各 alignment 実施時には次を記録する。

- 実施日
- 対象 phase
- 対象 feature
- blocking issue
- reopen した task
- 修正方針
- gate 結果

## 6. 再実施条件

次の場合、`tasks alignment gate` を再実施する。

- いずれかの `tasks.md` に遡上修正が入った場合
- 上流 `design.md` の変更により task の順序や依存が変わる場合
- 上流 `requirements.md` の変更により task 自体の存在理由が変わる場合
- implementation 中に task 分解の誤りが判明し、spec へ戻す場合

## 7. 実施ログ

### 7.1 Initial status

- 状態: pending
- 理由: 各 feature の `tasks.md` がまだ再構築方針に合わせて具体化されていない
- 次の着手条件: 5 feature の `tasks.md` が一通り揃うこと

### 7.2 Tasks wave alignment recheck 2026-05-09

- 状態: completed
- 対象:
  - `dual-reviewer-foundation`
  - `dual-reviewer-runtime`
  - `dual-reviewer-evaluation`
  - `dual-reviewer-self-improvement`
  - `dual-reviewer-paper-interface`

確認したこと:

- implementation order が `foundation -> runtime -> evaluation -> self-improvement -> paper-interface` で一貫しているか
- foundation-owned shared artifact と runtime-owned execution artifact の ownership が衝突していないか
- exported bundle handoff が runtime と evaluation で整合しているか
- self-improvement と paper-interface が evaluation output を前提にしているか
- optional methodology linkage が core dependency を汚染していないか

今回修正した点:

- runtime downstream handoff に `exports/<bundle_id>/checksums/bundle_checksums.json` を追加
- evaluation imported bundle ingestion task に checksum verification を追加

結果:

- blocking 級の task ordering conflict は見つからなかった
- foundation 共有 artifact -> runtime raw evidence -> evaluation analysis -> self-improvement learning -> paper reporting の依存列は維持されている
- paper-interface の self-improvement adopted history 参照は optional path として扱われ、core blocking dependency には含めない

残る implementation-phase 注意点:

- foundation asset 実装前に runtime metadata emission に着手しない
- runtime export 実装前に evaluation imported bundle ingestion に着手しない
- evaluation admission artifact 実装前に self-improvement imported provenance handling に着手しない
