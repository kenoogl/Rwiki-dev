# AGENTS/synthesize.md

## Purpose

Transform committed `raw/` sources into review-stage structured knowledge.

This process does NOT produce final wiki knowledge.

It produces:

→ reusable, structured, review-ready knowledge artifacts

---

## Position in Knowledge Flow

This agent implements:

raw → review

It MUST NOT perform:

review → wiki

Promotion to `wiki/` is handled ONLY by approval tasks
(e.g., AGENTS/approve_synthesis.md).

---

## Input Rules

- Use ONLY committed files under `raw/`
- NEVER use `raw/incoming/`
- `raw/` is strictly read-only

---

## Output Rules

All outputs MUST go to:

- `review/` layer

Typical destinations:

- `review/synthesis_candidates/`
- (future) `review/wiki_updates/` or equivalent

---

## Critical Constraints

### 1. NEVER write to wiki

DO NOT write to wiki/ under any circumstance.

- Do NOT update `wiki/`
- Do NOT update `wiki/synthesis/`
- Do NOT update `index.md` or `log.md`

---

### 2. Respect Review Enforcement

All generated knowledge MUST pass through review.

- Do NOT bypass review
- Do NOT simulate approval
- Do NOT mark content as final knowledge

---

### 3. Raw Integrity

- Do NOT modify any file under `raw/`
- If required data is missing → STOP and ask user

---

## Core Strategy

### 1. Prefer integration over fragmentation

- Try to align with existing knowledge structures
- Avoid generating isolated notes
- Think in terms of future wiki integration

---

### 2. Extract reusable knowledge

Focus on:

- concepts
- methods
- design decisions
- patterns
- structured relationships

Avoid:

- raw summaries
- context-dependent explanations
- conversational artifacts

---

### 3. One unit = one meaningful knowledge block

- Do not fragment trivial pieces
- Do not merge unrelated concepts
- Each output must be reusable independently

---

## Output Types

### A. Synthesis Candidates (Primary)

Location:

review/synthesis_candidates/

Used for:

- cross-cutting insights
- reusable patterns
- design decisions

Format should follow:

- AGENTS/synthesize_logs.md structure (recommended)

---

## Relationship to Other Agents

### synthesize_logs

- input: raw/llm_logs/
- output: candidates

### synthesize (this agent)

- input: general raw/
- output: candidates / structured review artifacts

### approve

- ONLY approval tasks may promote to wiki

---

## Failure Conditions

STOP if:

- attempting to write to wiki/
- attempting to bypass review
- raw data is insufficient
- output would be non-reusable
- output is purely a summary

---

## Design Principle

synthesize = knowledge structuring (NOT publishing)

publish = approve

---

## Key Invariant

NO knowledge reaches wiki without review.