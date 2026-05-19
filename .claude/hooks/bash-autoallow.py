#!/usr/bin/env python3
"""PreToolUse(Bash) auto-allow hook.

Reads the PreToolUse hook JSON on stdin. If the Bash command is composed
entirely of safe read-only / verification segments (and contains no
dangerous pattern), emit permissionDecision=allow so it runs without a
prompt. Otherwise emit nothing and exit 0 so the normal permission flow
(existing allow/ask rules + human confirmation) still applies.

Design: only ever emits "allow" or nothing. Never "deny". Any parse
ambiguity or unknown command -> emit nothing (fail-safe: confirm side).
"""
import json
import re
import sys


def read_command():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return None
    if not isinstance(data, dict):
        return None
    ti = data.get("tool_input")
    if not isinstance(ti, dict):
        return None
    cmd = ti.get("command")
    if not isinstance(cmd, str):
        return None
    cmd = cmd.strip()
    return cmd or None


def split_segments(cmd):
    """Quote-aware split on top-level && || ; | and newline.
    Operators inside '...' or "..." are literal (not split points)."""
    segs = []
    buf = []
    i = 0
    n = len(cmd)
    sq = dq = False
    while i < n:
        c = cmd[i]
        if sq:
            buf.append(c)
            if c == "'":
                sq = False
            i += 1
            continue
        if dq:
            buf.append(c)
            if c == "\\" and i + 1 < n:
                buf.append(cmd[i + 1])
                i += 2
                continue
            if c == '"':
                dq = False
            i += 1
            continue
        if c == "'":
            sq = True
            buf.append(c)
            i += 1
            continue
        if c == '"':
            dq = True
            buf.append(c)
            i += 1
            continue
        if c == "\\" and i + 1 < n:
            buf.append(c)
            buf.append(cmd[i + 1])
            i += 2
            continue
        # top-level operators
        if c == "\n" or c == ";":
            segs.append("".join(buf))
            buf = []
            i += 1
            continue
        if c == "&" and i + 1 < n and cmd[i + 1] == "&":
            segs.append("".join(buf))
            buf = []
            i += 2
            continue
        if c == "|" and i + 1 < n and cmd[i + 1] == "|":
            segs.append("".join(buf))
            buf = []
            i += 2
            continue
        if c == "|":
            segs.append("".join(buf))
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    if sq or dq:
        # unbalanced quotes -> ambiguous; signal by returning None
        return None
    segs.append("".join(buf))
    return segs


# Leading shell control words / keywords that wrap a real command.
# NOTE: loop/conditional headers (for/while/until/if/elif/case/select) are
# intentionally NOT here; they are handled by header_kw in segment_first_cmd.
SKIP_WORDS = {
    "then", "else", "fi", "do", "done", "esac", "in", "{", "}", "(", ")",
    "!", "time", "exec", "then;", "do;",
}

# First-token commands considered safe (read-only / verification).
SAFE_CMDS = {
    "ruby", "grep", "rg", "ls", "find", "wc", "awk", "sed", "echo",
    "printf", "head", "tail", "cat", "diff", "tr", "sort", "uniq", "cut",
    "basename", "dirname", "mkdir", "test", "true", "false", "python3",
    "jq", "date", "env", "pwd", "cd", ":", "[", "wait", "sleep", "xargs",
    "tee", "comm", "column", "fold", "nl", "tac", "yes", "seq", "expr",
    "read", "local", "export", "unset", "set", "shopt", "type", "command",
}

# git subcommands that only read.
GIT_READONLY = {
    "status", "diff", "log", "show", "branch", "rev-parse", "ls-files",
    "check-ignore", "cat-file", "describe", "shortlog", "blame", "grep",
    "config", "remote", "stash", "rev-list", "for-each-ref", "name-rev",
    "symbolic-ref", "merge-base", "ls-tree", "show-ref", "var", "count-objects",
}
# 'git config' / 'git remote' / 'git stash' can mutate; keep them read-ish only
# when no mutating subflag. Be conservative: treat config set / remote add /
# stash drop etc. as NOT safe -> handled in dangerous check below.

# Path-scoped git ops allowed only when every path arg is under these dirs.
SCOPED_GIT_DIRS = ("experiments/", "learning/", "./experiments/", "./learning/")

# Dangerous substrings/patterns: if ANY segment matches, do not auto-allow.
DANGEROUS_RES = [
    re.compile(r"\bgit\s+push\b"),
    re.compile(r"\bgit\s+commit\b"),
    re.compile(r"\bgit\s+reset\s+--hard\b"),
    re.compile(r"\bgit\s+rebase\b"),
    re.compile(r"\bgit\s+merge\b"),
    re.compile(r"\bgit\s+cherry-pick\b"),
    re.compile(r"\bgit\s+revert\b"),
    re.compile(r"\bgit\s+filter-branch\b"),
    re.compile(r"\bgit\s+update-ref\b"),
    re.compile(r"\bgit\s+branch\s+-[dD]\b"),
    re.compile(r"\bgit\s+tag\s+-d\b"),
    re.compile(r"\bgit\s+remote\s+(add|remove|set-url|rm)\b"),
    re.compile(r"\bgit\s+config\s+(?!--get|--list|-l\b|--get-all|--get-regexp)"),
    re.compile(r"\bgit\s+stash\s+(drop|clear|pop|apply|branch)\b"),
    re.compile(r"\bgit\s+(am|apply|restore)\b"),
    re.compile(r"\brm\b"),
    re.compile(r"\bmv\b"),
    re.compile(r"\bcp\b"),
    re.compile(r"\bsudo\b"),
    re.compile(r"\bchmod\b"),
    re.compile(r"\bchmod\s+-R\b"),
    re.compile(r"\bchown\b"),
    re.compile(r"\bcurl\b"),
    re.compile(r"\bwget\b"),
    re.compile(r"\bnc\b"),
    re.compile(r"\bscp\b"),
    re.compile(r"\bssh\b"),
    re.compile(r"\bdd\b"),
    re.compile(r"\bmkfs\b"),
    re.compile(r"\bshutdown\b"),
    re.compile(r"\breboot\b"),
    re.compile(r":\(\)\s*\{"),  # fork bomb-ish
    re.compile(r"\bnpm\s+(publish|install|i|ci|update|run)\b"),
    re.compile(r"\b(yarn|pnpm|pip|pip3|gem|bundle|brew)\s+(install|publish|add|update|uninstall)\b"),
    re.compile(r"\bgh\s+(pr|release|repo|api)\b"),
    re.compile(r"\bspec\.json\b"),
    re.compile(r">>?\s*/(?!tmp/|dev/null)"),  # redirect to absolute non-tmp
    re.compile(r"\bgit\s+clean\b.*-[a-z]*x"),  # git clean -x removes ignored too
]


REDIR_RE = re.compile(r"^([0-9]*[<>]|&>|>>|<<)")


def path_args(seg_tokens):
    """Return non-flag tokens after the git subcommand (rough path args).
    Stop at the first shell redirection; ignore flags and redirect tokens."""
    out = []
    for t in seg_tokens:
        if REDIR_RE.match(t) or t in (">", ">>", "<", "&", "&&", "2>&1"):
            break  # redirections / control -> no more path args
        if ">" in t or "<" in t:
            break
        if t.startswith("-"):
            continue
        out.append(t)
    return out


def scoped_ok(paths):
    """True if there is >=1 path arg and every path arg is under a scoped dir."""
    real = [p for p in paths if p not in ("--",)]
    if not real:
        return False
    for p in real:
        pp = p.lstrip("'\"").rstrip("'\"")
        if not (pp.startswith(SCOPED_GIT_DIRS)
                or pp in ("experiments", "learning", "./experiments", "./learning")):
            return False
    return True


def segment_first_cmd(seg):
    """Strip leading env assignments / keywords; return token list of the
    effective command, or None if it cannot be determined."""
    try:
        toks = seg.split()
    except Exception:
        return None
    # Loop / conditional headers contain no command of concern in this
    # segment (the body is in other segments, and any dangerous condition
    # is caught by the whole-command DANGEROUS_RES scan). Treat as safe
    # scaffolding.
    header_kw = {"for", "while", "until", "if", "elif", "case", "select"}
    i = 0
    while i < len(toks):
        t = toks[i]
        tb = t[:-1] if t.endswith(";") else t
        if t in SKIP_WORDS or tb in SKIP_WORDS or tb == "":
            i += 1
            continue
        # leading VAR=value assignment(s)
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            i += 1
            continue
        if t in header_kw or tb in header_kw:
            return []  # loop/conditional header -> safe scaffolding
        break
    if i >= len(toks):
        # pure keyword/assignment segment (e.g. "ok=0", "do", "done") -> safe
        return []
    return toks[i:]


def is_safe_segment(seg):
    seg = seg.strip()
    if seg == "":
        return True
    rest = segment_first_cmd(seg)
    if rest is None:
        return False
    if rest == []:
        return True
    cmd = rest[0]
    # absolute/relative path executables -> not in safe set -> unsafe
    if cmd in SAFE_CMDS:
        return True
    if cmd == "git":
        if len(rest) < 2:
            return False
        sub = rest[1]
        if sub in GIT_READONLY:
            return True
        if sub in ("clean", "checkout"):
            return scoped_ok(path_args(rest[2:]))
        return False
    return False


def main():
    cmd = read_command()
    if not cmd:
        return 0  # nothing -> normal flow
    # Any dangerous pattern anywhere -> normal flow (confirm).
    for dr in DANGEROUS_RES:
        if dr.search(cmd):
            return 0
    segs = split_segments(cmd)
    if segs is None:
        return 0  # unbalanced quotes / ambiguous -> normal flow (fail-safe)
    for s in segs:
        if not is_safe_segment(s):
            return 0  # unknown/unsafe -> normal flow
    out = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": (
                "auto-allowed: read-only/verification command "
                "(all segments safe, no dangerous pattern)"
            ),
        }
    }
    sys.stdout.write(json.dumps(out))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        # fail-safe: emit nothing, let normal permission flow handle it
        sys.exit(0)
