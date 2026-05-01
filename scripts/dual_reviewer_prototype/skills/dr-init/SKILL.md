---
name: dr-init
description: dual-reviewer foundation の target project bootstrap skill。`.dual-reviewer/` directory + 4 file (config.yaml / extracted_patterns.yaml / terminology.yaml / dev_log.jsonl) を all-or-nothing で配置する。Phase A scope では --lang ja のみ対応 (他 lang は exit 3 + Phase B-1.3 reference)。
---

# dr-init Skill (target project bootstrap)

## 概要 (Overview)

`dr-init` skill は dual-reviewer の target project に対して `.dual-reviewer/` directory を bootstrap し、Layer 3 artifact placeholder + config + dev_log JSONL を all-or-nothing で配置する。Req 2.1-2.7 に対応する Claude Code skill。

## 起動規約 (Invocation)

```
python3 scripts/dual_reviewer_prototype/skills/dr-init/bootstrap.py --target <target_project_root> [--lang ja]
```

- `--target` (必須): target project root の path
- `--lang` (optional, default = `ja`): 言語指定。Phase A scope では `ja` のみ対応。他 lang は exit 3 + Phase B-1.3 reference を stderr に出力して reject。

## 動作 (Behavior)

### Success path (exit 0)

1. target project root 配下に `.dual-reviewer/` directory を作成
2. 4 file を配置:
    - `config.yaml` (5 field placeholder = primary_model / adversarial_model / judgment_model / lang=ja / dev_log_path)
    - `extracted_patterns.yaml` (Layer 3 placeholder = version + 空 patterns list)
    - `terminology.yaml` (terminology.yaml.template から copy = version + 空 entries list)
    - `dev_log.jsonl` (空 file、append target)
3. stdout に `.dual-reviewer/` directory の absolute path を 1 行出力
4. exit code = 0 で終了

### Pre-check (4 重 mechanical pre-check)

bootstrap 開始前に以下 4 件を順次 check し、いずれか fail で early exit:

- (a) target が directory か (= `target.is_dir()`)
- (b) `.dual-reviewer/` 既存か (= conflict 検出)
- (c) `--lang` が `ja` か (= unsupported lang 検出)
- (d) target に書込権限あるか (= `os.access(target, os.W_OK)`)

### Exit code 規約 (Exit Code Contract)

- `0` = success (.dual-reviewer/ 配置完了)
- `1` = conflict (既存 `.dual-reviewer/` 検出、partial write 一切なし)
- `2` = filesystem error (write error / permission denied / partial write 検出 → all-or-nothing rollback 完了)
- `3` = unsupported lang (`--lang ja` 以外、stderr に Phase B-1.3 reference message)
- `4` = rollback failure (rollback 中の write error、stderr に残存 file の絶対 path list を **1 line per path** 形式で enumerate + 手動削除指示。silent fail 禁止)

### All-or-nothing rollback semantics

bootstrap 途中で write error / permission denied / partial write を検出した場合、生成済 file を全削除して pre-bootstrap state に復元する。partial state を残さない。

rollback 自体が失敗した場合 (= 削除も permission denied 等で失敗) は、削除失敗 file の absolute path を **1 line per absolute path** 形式で stderr に enumerate し、user に手動削除を指示する (silent fail 禁止、exit 4)。

## Invariants

- target project の `.dual-reviewer/` 配下以外の任意 file (`CLAUDE.md` / `.kiro/` / source code 等) を一切改変しない (Req 2.7)。
- config.yaml の 5 field は必ず populate される (Req 2.2)。
- lang default は必ず `ja` (Req 2.4)。

## 関連 (Related)

- 設定 template: `scripts/dual_reviewer_prototype/config/config.yaml.template`
- 用語 template: `scripts/dual_reviewer_prototype/terminology/terminology.yaml.template`
- spec: `.kiro/specs/dual-reviewer-foundation/` (Req 2)
