# AGENTS/audit.md — Wiki Audit Policy

## Role

You are performing a **read-only audit** of the wiki.

You MUST:
- detect issues
- classify them by type and priority
- report findings in the standard format

You MUST NOT:
- modify any files
- fix issues automatically
- proceed to repair without explicit user confirmation

**Audit is report-first, repair-second.**

---

# AUDIT TYPES

## 0. Micro-check — every ingest

Lightweight check run after each ingest. Covers only:

- Broken `[[links]]` in recently updated pages
- `index.md` missing entries for new or updated wiki pages
- YAML frontmatter integrity (missing title, malformed fields)

Scope: only pages affected by the current ingest or recent wiki update.
This is NOT a full structural audit.

## 1. Structural Audit — weekly or every 10 ingests

Check:
- Broken `[[links]]`
- Orphan pages (no incoming links; `index.md` links excluded)
- `index.md` missing entries or stale entries
- YAML frontmatter issues (missing title / tags / updated)
- Missing required sections per template
- File naming violations (non-kebab-case, non-ASCII)
- Source path existence mismatch (`sources:` field points to non-existent raw file)

## 2. Semantic Audit — monthly

Detect inconsistencies:
- Conflicting definitions of the same concept across pages
- Inconsistent method comparisons (different evaluation axes)
- Project `status` field vs `Current Status` section mismatch
- Same person's affiliation or role described differently
- Same source cited with divergent summaries

## 3. Strategic Audit — quarterly

Evaluate knowledge graph structure:
- Isolated topic clusters (no cross-domain links)
- Papers ingested but not reflected in projects
- Tools pages not linked to methods
- Synthesis pages underdeveloped relative to concepts volume
- Domains with dense coverage vs empty domains
- Propose CLAUDE.md schema amendments if needed

---

# CONFLICT CLASSIFICATION

Apply tags inline within the relevant wiki page (as a blockquote note):

| Tag | Meaning |
|-----|---------|
| `[CONFLICT]` | Clear, direct contradiction between pages |
| `[TENSION]` | Condition-dependent difference — may both be valid |
| `[AMBIGUOUS]` | Underspecified; interpretation is unclear |

When tagging, always include reason:
```
> [CONFLICT] Definition differs from [[sindy]]: here noise-robust, there noise-sensitive.
```

Do NOT tag until after reporting to user and receiving confirmation.

---

# PRIORITY LEVELS

## Severity Level

詳細: [developer-guide.md §Severity Vocabulary](developer-guide.md#6-severity-vocabulary)

| Severity | Meaning | Examples |
|----------|---------|---------|
| `CRITICAL` | Breaks system integrity | Broken YAML, missing source paths, index duplicates |
| `ERROR` | Reduces knowledge trustworthiness | Fact conflicts, unsourced key claims, project status mismatch |
| `WARN` | Quality degradation signals | Orphan pages, missing sections, one-directional links |
| `INFO` | Improvement suggestions | Tag inconsistencies, heading granularity, type field missing |

<!-- severity-vocab: legacy-reference -->
旧語彙（`HIGH` / `MEDIUM` / `LOW`）は廃止されました。新語彙（`ERROR` / `WARN` / `INFO`）を使用してください。
<!-- /severity-vocab -->

---

# AUDIT METRICS

Report the following counts in every audit:

### Structural
- Total pages scanned
- Orphan page count
- Broken link count
- Index missing entries
- Frontmatter issues

### Connectivity
- Average internal links per page
- Bidirectional link compliance rate (%)
- concepts → methods → projects cross-links count
- Synthesis pages referencing other wiki pages count

### Reliability
- Pages with at least one source (%)
- `[CONFLICT]` count
- `[TENSION]` count
- `[AMBIGUOUS]` count

### Growth
- New pages / updated pages ratio (last period)
- Raw sources without corresponding wiki pages
- Synthesis accumulation rate

---

# AUDIT SCHEDULE

| Frequency | Type | Trigger |
|-----------|------|---------|
| Every ingest | Micro-check | broken links, index update, frontmatter |
| Weekly | Structural | full structural audit |
| Monthly | Semantic | conflict detection, project alignment |
| Quarterly | Strategic | graph structure, schema review |

---

# OUTPUT FORMAT

Produce a report only. Do not modify files.

```md
# Wiki Audit Report — YYYY-MM-DD

## Summary
- pages scanned:
- critical:
- error:
- warn:
- info:

## Structural Findings
- [CRITICAL] ...
- [WARN] ...

## Semantic Findings
- [ERROR] Conflict candidate between [[a]] and [[b]]: ...
- [WARN] [TENSION] ...

## Strategic Findings
- synthesis underdeveloped in <domain> cluster
- tools pages weakly connected to methods

## Metrics
- orphan rate: X / total
- bidirectional compliance: XX%
- sourced pages: XX%
- [CONFLICT] count: X

## Recommended Actions
1.
2.
3.
```

