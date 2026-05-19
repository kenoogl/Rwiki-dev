#!/usr/bin/env python3
"""PreToolUse(Bash) auto-allow hook.

Reads the PreToolUse hook JSON on stdin. If the Bash command is composed
entirely of safe read-only / verification segments (and contains no
dangerous pattern), emit permissionDecision=allow so it runs without a
prompt. Otherwise emit nothing and exit 0 so the normal permission flow
(existing allow/ask rules + human confirmation) still applies.

Design: only ever emits "allow" or nothing. Never "deny". Any parse
ambiguity or unknown command -> emit nothing (fail-safe: confirm side).

Safety invariant: DANGEROUS_RES is scanned against the RAW command
string (including the contents of $(...) / `...` substitutions and
subshell groups) before any segmentation. So leniency added to
segmentation/command-identification can never auto-allow a command
that contains a dangerous token anywhere.
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
    Operators inside '...' or "..." are literal (not split points).
    Operators inside an unquoted command substitution $( ... ) or a
    backtick span are also NOT split points (so `X=$(a && b)` and
    `$(a; b)` stay in one segment for correct command identification)."""
    segs = []
    buf = []
    i = 0
    n = len(cmd)
    sq = dq = False
    sub = 0   # unquoted $( ) nesting depth
    bt = False  # inside backtick substitution
    while i < n:
        c = cmd[i]
        if sq:
            buf.append(c)
            if c == "'":
                sq = False
            i += 1
            continue
        if bt:
            buf.append(c)
            if c == "\\" and i + 1 < n:
                buf.append(cmd[i + 1])
                i += 2
                continue
            if c == "`":
                bt = False
            i += 1
            continue
        if sub > 0:
            # opaque: only track $( ) nesting and escapes; do not split.
            if c == "\\" and i + 1 < n:
                buf.append(c)
                buf.append(cmd[i + 1])
                i += 2
                continue
            if c == "$" and i + 1 < n and cmd[i + 1] == "(":
                sub += 1
                buf.append("$(")
                i += 2
                continue
            if c == "(":
                sub += 1
                buf.append(c)
                i += 1
                continue
            if c == ")":
                sub -= 1
                buf.append(c)
                i += 1
                continue
            buf.append(c)
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
        if c == "`":
            bt = True
            buf.append(c)
            i += 1
            continue
        if c == "$" and i + 1 < n and cmd[i + 1] == "(":
            sub += 1
            buf.append("$(")
            i += 2
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
    if sq or dq or sub > 0 or bt:
        # unbalanced quotes/substitution -> ambiguous; signal with None
        return None
    segs.append("".join(buf))
    return segs


def find_substitutions(cmd):
    """Return inner command strings of every $( ... ) and `...`
    substitution (including nested and those inside double quotes),
    skipping single-quoted (literal) regions. Used to require that
    substituted commands are themselves safe."""
    inners = []
    i = 0
    n = len(cmd)
    sq = False
    while i < n:
        c = cmd[i]
        if sq:
            if c == "'":
                sq = False
            i += 1
            continue
        if c == "'":
            sq = True
            i += 1
            continue
        if c == "\\" and i + 1 < n:
            i += 2
            continue
        if c == "`":
            j = i + 1
            depth_buf = []
            while j < n and cmd[j] != "`":
                if cmd[j] == "\\" and j + 1 < n:
                    depth_buf.append(cmd[j + 1])
                    j += 2
                    continue
                depth_buf.append(cmd[j])
                j += 1
            inners.append("".join(depth_buf))
            i = j + 1
            continue
        if c == "$" and i + 1 < n and cmd[i + 1] == "(":
            depth = 1
            j = i + 2
            start = j
            while j < n and depth > 0:
                if cmd[j] == "(":
                    depth += 1
                elif cmd[j] == ")":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            inners.append(cmd[start:j])
            i = i + 2  # continue scanning so nested $( ) are also found
            continue
        i += 1
    return inners


def strip_subst(s):
    """Remove balanced $( ... ) and `...` spans from a segment (for
    command identification only). Single-quoted regions are literal."""
    out = []
    i = 0
    n = len(s)
    sq = False
    while i < n:
        c = s[i]
        if sq:
            out.append(c)
            if c == "'":
                sq = False
            i += 1
            continue
        if c == "'":
            sq = True
            out.append(c)
            i += 1
            continue
        if c == "\\" and i + 1 < n:
            out.append(c)
            out.append(s[i + 1])
            i += 2
            continue
        if c == "`":
            j = i + 1
            while j < n and s[j] != "`":
                if s[j] == "\\" and j + 1 < n:
                    j += 2
                    continue
                j += 1
            i = j + 1
            continue
        if c == "$" and i + 1 < n and s[i + 1] == "(":
            depth = 1
            j = i + 2
            while j < n and depth > 0:
                if s[j] == "(":
                    depth += 1
                elif s[j] == ")":
                    depth -= 1
                    if depth == 0:
                        j += 1
                        break
                j += 1
            i = j
            continue
        out.append(c)
        i += 1
    return "".join(out)


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
    "basename", "dirname", "mkdir", "mktemp", "test", "true", "false",
    "python3", "jq", "date", "env", "pwd", "cd", ":", "[", "wait",
    "sleep", "xargs", "tee", "comm", "column", "fold", "nl", "tac",
    "yes", "seq", "expr", "read", "local", "export", "unset", "set",
    "shopt", "type", "command",
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

# `cp` is auto-allowed only when its destination is under a temp root:
# a literal temp path prefix, or a shell variable assigned from `mktemp`
# in the same command. Sources may be anything (copy is read-only at the
# source); the bounded risk is destination overwrite, contained to temp.
TEMP_DEST_PREFIXES = (
    "/tmp/", "/private/tmp/", "/var/folders/", "/private/var/folders/",
)
TEMP_ASSIGN_RE = re.compile(
    r"\b([A-Za-z_][A-Za-z0-9_]*)\s*=\s*[\"']?(?:\$\(\s*mktemp\b|`\s*mktemp\b)"
)
LEADING_VAR_RE = re.compile(r"^\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?")
# Populated per-invocation in main() from the raw command.
TEMP_VARS = set()


def _unquote(tok):
    t = tok.strip()
    if len(t) >= 2 and t[0] in "'\"" and t[-1] == t[0]:
        t = t[1:-1]
    return t.lstrip("'\"")


def dest_is_temp(dest):
    """True if a cp destination resolves under a temp root."""
    d = _unquote(dest)
    if d == "/tmp" or d.startswith(TEMP_DEST_PREFIXES):
        return True
    m = LEADING_VAR_RE.match(d)
    if m and m.group(1) in TEMP_VARS:
        return True
    return False


def cp_is_temp_scoped(rest):
    """rest = token list starting with 'cp'. Safe only if a clear
    src... dest form whose destination is temp-scoped. Conservative:
    any ambiguity (target-dir flag, redirection, <2 operands) -> False."""
    operands = []
    for t in rest[1:]:
        if t == "-t" or t.startswith("--target-directory"):
            return False  # GNU target-dir form -> too ambiguous, confirm
        if REDIR_RE.match(t) or t in (">", ">>", "<", "&", "&&", "2>&1"):
            break
        if ">" in t or "<" in t:
            break
        if t.startswith("-"):
            continue
        operands.append(t)
    if len(operands) < 2:
        return False
    return dest_is_temp(operands[-1])

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
    # NOTE: `cp` is intentionally NOT a blanket dangerous pattern. It is
    # handled in is_safe_segment as conditionally-safe: auto-allowed only
    # when the destination is under a temp root (literal /tmp//var/folders
    # or a shell var assigned from mktemp in the same command). Any other
    # cp destination falls through to the normal confirm flow.
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
    """Strip leading env assignments / keywords / grouping parens; return
    token list of the effective command, or None if it cannot be
    determined. Command substitutions are removed first (validated
    separately) so `X=$(safe ...)` reduces to a pure assignment."""
    seg = strip_subst(seg)
    try:
        raw = seg.split()
    except Exception:
        return None
    # Strip subshell / grouping parens that are glued to tokens, and drop
    # tokens that are only parentheses. `(for` -> `for`, `done)` -> `done`.
    toks = []
    for t in raw:
        t = t.strip("()")
        if t == "":
            continue
        toks.append(t)
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
    if cmd == "cp":
        return cp_is_temp_scoped(rest)
    return False


def main():
    cmd = read_command()
    if not cmd:
        return 0  # nothing -> normal flow
    # Shell vars assigned from mktemp in THIS command are temp-scoped
    # destinations for the conditional cp rule.
    TEMP_VARS.clear()
    for m in TEMP_ASSIGN_RE.finditer(cmd):
        TEMP_VARS.add(m.group(1))
    # Any dangerous pattern anywhere (incl. inside substitutions / subshells)
    # -> normal flow (confirm). Scanned on the raw command first.
    for dr in DANGEROUS_RES:
        if dr.search(cmd):
            return 0
    segs = split_segments(cmd)
    if segs is None:
        return 0  # unbalanced quotes/substitution -> normal flow (fail-safe)
    # Every substituted command must itself be safe (an unknown command
    # hidden in $(...) / `...` must not be auto-allowed).
    for inner in find_substitutions(cmd):
        inner_segs = split_segments(inner)
        if inner_segs is None:
            return 0
        for s in inner_segs:
            if not is_safe_segment(s):
                return 0
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
