# .claude/hooks

このプロジェクト専用の Claude Code フック。

## bash-autoallow.py（PreToolUse / Bash 自動許可）

安全な検証・調査用 Bash コマンドを無確認で通し、破壊的操作は確認に倒す
（`allow` か無出力のみ。`deny` は出さない＝判定不能・未知は従来確認）。

### 自動許可されるもの

- 安全コマンドの複合：ruby / grep / rg / ls / find / wc / awk / sed /
  echo / printf / head / tail / cat / diff / sort / uniq / cut / mkdir /
  mktemp / test / python3 / jq / date / xargs / tee / seq / expr など
- git の読み取り専用サブコマンド（status / diff / log / show / branch /
  rev-parse / ls-files / cat-file / blame / grep / rev-list /
  for-each-ref / merge-base / ls-tree / show-ref など）
- サブシェルで囲んだループ `(for ...; do ...; done)`
- コマンド置換 `X=$(安全コマンド ...)` / `$(安全コマンド)` / バッククォート
- `mktemp`
- `git clean` / `git checkout` は引数パスが `experiments/` または
  `learning/` 配下限定のとき
- `cp` は複製先が一時領域のときのみ（`/tmp`・`/private/tmp`・
  `/var/folders`、または同一コマンド内で `mktemp` から代入した変数配下）

### 確認に倒すもの（意図的な安全網）

- rm / mv / 一時領域外への cp
- git push / commit / reset --hard / rebase / merge / cherry-pick /
  revert / branch -d / stash drop|pop|apply、git config の set 系
- gh の pr|release|repo|api、npm/yarn/pip/gem/bundle/brew の
  install|publish|add|update、sudo / chmod / chown / curl / wget /
  scp / ssh / dd など
- 文字列 `spec.json` を含むコマンド（spec.json は Read ツールで読む）
- `/tmp`・`/dev/null` 以外の絶対パスへのリダイレクト
- 置換やサブシェルの中に隠した危険語・未知コマンド
- 引用符（' "）が不均衡なコマンド（曖昧＝安全側）

危険判定は生コマンド文字列全体を最初に走査するため、置換・サブシェルの
内側に危険語があっても従来どおり捕捉される。

### テスト

`python3 .claude/hooks/test_bash_autoallow.py` で全ケース検証
（自動許可される新パターンと、破壊操作の安全網維持を網羅）。
判定仕様の正本はこのテストの期待値とする。フック変更時は必ず再実行する。

### コミット運用

commit / push はこのフックでは自動化しない。明示承認のまま。
