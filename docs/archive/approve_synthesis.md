# AGENTS/approve_synthesis.md

## Purpose

Promote reviewed synthesis candidates from `review/synthesis_candidates/` to `wiki/synthesis/`.

This step handles only **human-approved** knowledge.

------

## Input

- Source: `review/synthesis_candidates/**/*.md`
- Use only committed files under `review/synthesis_candidates/`

------

## Output

- Destination: `wiki/synthesis/`

------

## Approval Rule

Only process files whose frontmatter contains all of the following fields:

- `status`: must be `approved`
- `reviewed_by`: non-empty string
- `approved`: valid date in `YYYY-MM-DD` format

  Example:

      ---
      status: approved
      reviewed_by: alice
      approved: 2026-04-15
      ---

  Rules:

- `status` MUST be exactly `approved`
- `reviewed_by` MUST be present and non-empty
- `approved` MUST be a valid date in `YYYY-MM-DD` format
- Missing approval metadata MUST NOT be fabricated

If any of the above is missing, do not promote the candidate.

------

## Critical Rules

### 1. Human review is mandatory

Do not approve content automatically.

Approval must be made by a human before promotion.

Do not invent or fill missing approval metadata.

### 2. Promote only reusable knowledge

The candidate must:

- be understandable without the original conversation
- express a stable decision, principle, or reusable pattern
- be concise and structured

If not, do not promote.

Do not promote content already sufficiently covered in existing wiki pages unless it adds a distinct reusable synthesis.

### 3. Avoid duplication

Before creating a new note in `wiki/synthesis/`:

- check for similar notes
- merge if similar content exists

### 4. Preserve provenance

The promoted note must retain traceability to:

- the approved candidate
- the original llm log

### 5. Prevent re-promotion

A candidate MUST NOT be promoted more than once.

If the candidate frontmatter contains:

- `promoted: true`

then skip it.

------

## Promotion Behavior

For each approved candidate:

1. read the candidate
2. validate approval metadata
3. check the promoted flag
4. check for a similar existing note in `wiki/synthesis/`
5. if a similar note exists:
   - merge relevant content
   - update metadata
6. otherwise:
   - create a new note in `wiki/synthesis/`
7. update the candidate metadata:
   - `promoted: true`
   - `promoted_at: YYYY-MM-DD`
   - `promoted_to: wiki/synthesis/<slug>.md`
8. update `index.md` if a new note was created
9. append to `log.md`
10. commit: review/ と wiki/ の変更は**別々に**コミットすること
    - first: `review/` の promoted フラグ更新をコミット
    - then: `wiki/` のノート作成 + `index.md` + `log.md` をコミット

------

## Output Format

Promoted notes in `wiki/synthesis/` MUST use frontmatter equivalent to the following:

    ---
    title: "<title>"
    source: "<original source>"
    candidate_source: "<review/synthesis_candidates/...>"
    type: "synthesis"
    reviewed_by: "<name>"
    approved: YYYY-MM-DD
    created: YYYY-MM-DD
    updated: YYYY-MM-DD
    tags: [tag1, tag2]
    ---

Body structure:

    ## Summary
    ...
    
    ## Decision
    ...
    
    ## Reason
    ...
    
    ## Alternatives
    ...
    
    ## Reusable Pattern
    ...

Rules:

- `candidate_source` is mandatory
- Provenance must be preserved

------

## Merge Rule

If a similar note exists:

- preserve the existing file
- append or integrate only new useful content
- do not overwrite blindly
- update `updated`
- preserve provenance

------

## Index / Log Rule

After promotion:

- update `index.md` when a new note is created
- append to `log.md`

------

## Quality Checklist

Before promotion, verify:

- approved by human
- reusable
- non-redundant
- understandable as a standalone note
- provenance preserved

If not, skip it.

------

## Post-Promotion Checklist

After promotion, verify:

- `promoted: true` is set
- `promoted_at` is recorded
- `promoted_to` is recorded
- the promoted note includes `candidate_source`
- the operation is append-only with respect to `log.md`

------

## Additional Constraint

- do not re-promote candidates that have already been processed

------

## Design Principle

- candidate = generated proposal
- approved synthesis = trusted reusable knowledge
