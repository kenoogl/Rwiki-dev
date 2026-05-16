#!/bin/bash
# SSoT order/dependency reminder
# 横断/順序/依存系の指示のときだけ最小 1 行を注入。それ以外は無出力。
input=$(cat)
prompt=$(printf '%s' "$input" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null)
case "$prompt" in
  *依存*|*順序*|*順番*|*横断*|*シーケンス*|*着手順*|*進行順*|*どの機能から*|*並べ*)
    echo "[SSoT] 横断/順序/依存の判断前に dual-reviewer-rebuild/docs/alignment/phase-and-feature-dependency-map.md を確認"
    ;;
esac
exit 0
