# AGENTS/synthesize_logs.md

## Purpose

Convert committed `raw/llm_logs/` into reusable knowledge candidates.

This process extracts high-value, generalizable knowledge from LLM interaction logs and produces structured synthesis candidates.

## Input

- Source: `raw/llm_logs/**/*.md`
- Only committed files under raw/llm_logs/ are valid input
- Uncommitted logs MUST NOT be used

## Output

- Destination: `review/synthesis_candidates/`
- Type: `synthesis_candidate`
- Format: structured markdown (NOT conversation)

## Critical Rules

### 1. Never write directly to wiki

- DO NOT write to `wiki/synthesis/`
- Always write to `review/synthesis_candidates/`
- All generated notes are review candidates, not approved knowledge

### 2. Remove conversation structure

- No dialogue
- No Q&A format
- No "user said", "assistant said"

### 3. Remove noise

Exclude:

- trial-and-error steps
- redundant explanations
- context-dependent statements
- incorrect intermediate content unless useful as a rejected alternative

### 4. Extract only reusable knowledge

Include ONLY:

- clear decisions
- design patterns
- general principles
- reusable workflows

- Do not over-generalize beyond what is supported by the log

### 5. One topic per note

- Split by reusable topic
- Avoid fragmenting one coherent decision into many trivial notes
- Each note should represent a meaningful, self-contained unit of reusable knowledge

## Extraction Criteria

For each log, extract:

### Decision
- What was chosen?

### Reason
- Why was it chosen?

### Alternatives
- What was rejected?

### Reusable Pattern
- What can be generalized?

## Output Format (MANDATORY)

```markdown
---
title: "<clear topic name>"
source: "<raw/llm_logs/...>"
type: "synthesis_candidate"
status: "pending"
created: YYYY-MM-DD
tags: [tag1, tag2]
---

## Summary
<3–5 lines concise summary>

## Decision
<final decision>

## Reason
<why>

## Alternatives
<rejected options>

## Reusable Pattern
<generalized rule>
```

## Naming Rules

- lowercase
- hyphen-separated
- concise and descriptive

------

## Duplicate Handling

- If a candidate with the same slug already exists:
  - merge or skip
  - do NOT overwrite blindly

------

## Quality Checklist

Before saving each note, verify:

- Can it be understood without the original conversation?
- Is it reusable?
- Is it concise?
- Is it free from noise?
- Does it represent a final decision or pattern?

If NOT, discard it.

------

## Failure Conditions

DO NOT create a note if:

- content is too context-specific
- no clear decision exists
- information is redundant with existing `review/synthesis_candidates/` or `wiki/synthesis/`
- the log does not support a reusable conclusion

## Additional Rules (Optional but Recommended)

- Prefer merging with an existing candidate when appropriate
- Each note should represent a meaningful, self-contained unit of reusable knowledge

------

## Design Principle

- llm_logs = raw thinking
- synthesis_candidates = refined knowledge
- wiki/synthesis = approved knowledge
