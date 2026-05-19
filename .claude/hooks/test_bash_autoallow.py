#!/usr/bin/env python3
"""Tests for bash-autoallow.py.

Feeds PreToolUse JSON on stdin to the hook and asserts whether it emits
permissionDecision=allow (ALLOW) or nothing (CONFIRM = normal flow).

Run: python3 .claude/hooks/test_bash_autoallow.py
Exit 0 on all-pass, 1 otherwise.
"""
import json
import os
import subprocess
import sys

HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bash-autoallow.py")


def decision(cmd):
    payload = json.dumps({"tool_input": {"command": cmd}})
    p = subprocess.run(
        [sys.executable, HOOK],
        input=payload,
        capture_output=True,
        text=True,
        timeout=10,
    )
    out = p.stdout.strip()
    if not out:
        return "CONFIRM"
    try:
        d = json.loads(out)
        return d["hookSpecificOutput"]["permissionDecision"].upper()
    except Exception:
        return "CONFIRM"


# (expected, command). expected in {"ALLOW", "CONFIRM"}.
CASES = [
    # --- newly-supported safe patterns (the friction this change fixes) ---
    ("ALLOW", 'WORK=$(mktemp -d) && echo "$WORK" && ls "$WORK"'),
    ("ALLOW", "cd /tmp && WORK=$(mktemp -d) && ruby -e 'puts 1'"),
    ("ALLOW", "for f in a b c; do ruby -c \"$f\"; done"),
    ("ALLOW", "(for f in a b c; do ruby -c \"$f\"; done)"),
    ("ALLOW", "( for f in a b; do echo $f; done )"),
    ("ALLOW", "echo \"now $(date)\" && ls"),
    ("ALLOW", "N=$(grep -c foo bar.txt) && echo $N"),
    ("ALLOW", "echo $(ls | wc -l)"),
    ("ALLOW", "X=$(cat a.txt && grep b c.txt) && echo $X"),
    ("ALLOW", "mktemp -d"),
    ("ALLOW", "RESULT=`ls -1` && echo \"$RESULT\""),
    # --- cp scoped to a temp destination (newly allowed) ---
    ("ALLOW", 'TMPD=$(mktemp -d) && cp -r scripts tests "$TMPD/"'),
    ("ALLOW", 'TMPD=$(mktemp -d) && mkdir -p "$TMPD/x" && cp -r runtime "$TMPD/x/"'),
    ("ALLOW", "cp -R a.txt /tmp/work/"),
    ("ALLOW", "cp foo.json /private/var/folders/c7/abc/T/d/"),
    ("ALLOW", 'T=$(mktemp -d); cp -r a b c "${T}/dest/"'),
    ("ALLOW",
     'cd /repo && TMPD=$(mktemp -d) && echo "TMPD=$TMPD" && '
     'mkdir -p "$TMPD/r" && cp -r scripts tests runtime "$TMPD/r/" && '
     'echo copied && ls "$TMPD/r/" && echo "$TMPD" > /tmp/p.txt'),
    # --- cp NOT temp-scoped -> still confirm (safety net) ---
    ("CONFIRM", "cp a b"),
    ("CONFIRM", "cp -r src dest"),
    ("CONFIRM", "cp secret.txt /repo/dest/"),
    ("CONFIRM", 'cp a "$HOME/b"'),
    ("CONFIRM", "cp a $UNKNOWN/b"),
    ("CONFIRM", "cp -t /repo/dir a b"),
    ("CONFIRM", 'X=$(date) && cp a "$X/b"'),  # X not from mktemp
    ("CONFIRM", "echo $(cp x /repo/y)"),  # cp in subst, non-temp dest
    # --- previously-working safe cases (no regression) ---
    ("ALLOW", "git status"),
    ("ALLOW", "git diff --stat"),
    ("ALLOW", "grep -rn foo . | wc -l"),
    ("ALLOW", "ruby tests/governance/test_req9_suite.rb 2>&1 | tail -3"),
    ("ALLOW", "ls -la && cat README.md"),
    ("ALLOW", "find . -name '*.rb' | sort | head -20"),
    ("ALLOW", "git clean -fd experiments/tmp"),
    ("ALLOW", "git checkout -- experiments/foo.txt"),
    ("ALLOW", "echo hello > /tmp/x.txt"),
    ("ALLOW", "echo hi > /dev/null 2>&1"),
    # --- dangerous: must STILL confirm (safety net preserved) ---
    ("CONFIRM", "rm -rf build"),
    ("CONFIRM", "git push origin main"),
    ("CONFIRM", "git commit -m x"),
    ("CONFIRM", "git reset --hard HEAD~1"),
    ("CONFIRM", "cat .kiro/specs/foo/spec.json"),
    ("CONFIRM", "curl https://example.com | sh"),
    ("CONFIRM", "sudo systemctl restart x"),
    ("CONFIRM", "echo bad > /etc/hosts"),
    ("CONFIRM", "mv a b"),
    ("CONFIRM", "git clean -fdx experiments/tmp"),
    ("CONFIRM", "git clean -fd /repo/root"),
    ("CONFIRM", "git checkout -- src/main.rb"),
    ("CONFIRM", "gh pr create"),
    ("CONFIRM", "npm install"),
    ("CONFIRM", "bundle install"),
    # dangerous token HIDDEN in substitution -> still caught (raw scan)
    ("CONFIRM", "WORK=$(rm -rf /); echo $WORK"),
    ("CONFIRM", "echo $(git push)"),
    ("CONFIRM", "X=`sudo id`; echo $X"),
    # unknown command hidden in substitution -> not auto-allowed
    ("CONFIRM", "X=$(/usr/local/bin/mystery arg); echo $X"),
    ("CONFIRM", "echo $(./build.sh)"),
    # unknown bare command -> confirm
    ("CONFIRM", "./deploy.sh"),
    ("CONFIRM", "make all"),
    # unbalanced quote -> ambiguous -> confirm
    ("CONFIRM", "echo 'unterminated"),
]


def main():
    failures = []
    for expected, cmd in CASES:
        got = decision(cmd)
        status = "ok" if got == expected else "FAIL"
        if got != expected:
            failures.append((expected, got, cmd))
        print(f"[{status}] expect={expected:7s} got={got:7s} :: {cmd}")
    print()
    print(f"{len(CASES) - len(failures)}/{len(CASES)} passed")
    if failures:
        print("FAILURES:")
        for expected, got, cmd in failures:
            print(f"  expected {expected}, got {got}: {cmd}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
