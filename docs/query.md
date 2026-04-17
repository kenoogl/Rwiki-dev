# AGENTS/query.md

## Purpose

Generate reusable query artifacts from curated wiki knowledge.

This process is NOT simple retrieval or one-off Q&A.
It is a structured knowledge extraction process.

The goal is to create reusable knowledge units under:

- `review/query/<query_id>/query.md`
- `answer.md`
- `evidence.md`
- `metadata.json`

------

## Source of Truth

- Primary source is `wiki/`
- Read `index.md` first if available
- Use only wiki content unless explicitly instructed otherwise

Do NOT rely on:

- `raw/`
- external knowledge
- unstated assumptions

If information is missing, state it explicitly.

------

## Core Rules

### 1. Fact–Evidence Separation

You must strictly separate:

- answer = structured explanation
- evidence = supporting excerpts

Do NOT mix them.

------

### 2. No Hallucination

Every important claim in `answer.md` must be grounded in `evidence.md`.

If you perform:

- interpretation
- abstraction
- cross-page reasoning
- extension

you MUST mark it as:

```
[INFERENCE]
```

------

### 3. Reusability First

The result must be usable without chat context.

Avoid:

- 前述 / 上記
- これ / あれ
- 今回
- as mentioned above

------

### 4. Query Type

Choose exactly one:

- `fact`
- `structure`
- `comparison`
- `why`
- `hypothesis`

The query type determines how reasoning should be constructed.

------

### 5. Granularity Control

Each query must be:

- **atomic but meaningful**

Avoid:

- overly broad summaries
- trivial single-fact extraction
- context-dependent questions

Good examples:

- "Why is nonuniform Z grid used?"
- "Difference between Quasi-3D and full 3D solver"

------

### 6. Structured Reasoning

The answer must not be a flat extraction.

It must:

- highlight relationships between concepts
- connect reasoning across pages
- explain not only "what" but also "how" and "why" when possible

------

## Query Process (MANDATORY)

Follow this order strictly:

### Step 1: Scope Identification

- Identify relevant wiki pages
- Define query_type

------

### Step 2: Evidence Collection

- Extract candidate passages
- Prefer minimal sufficient excerpts
- Avoid redundancy

------

### Step 3: Evidence Selection

Select only:

- directly supporting evidence
- minimal coverage for each claim

Avoid:

- full paragraph dumping
- unrelated context

------

### Step 4: Answer Construction

- Build structured answer from evidence
- explicitly connect reasoning
- highlight relationships between concepts
- mark `[INFERENCE]` where needed

------

### Step 5: Validation

Check:

- every claim has support OR `[INFERENCE]`
- evidence is not excessive
- answer is reusable
- relationships between concepts are clear

------

## Required Output Contract

------

### 1. query.md

Must include:

- query
- query_type
- scope
- date

------

### 2. answer.md

Requirements:

- non-empty
- structured (headings or bullets)
- concise but meaningful
- claims supported by evidence
- `[INFERENCE]` used when needed

------

### 3. evidence.md

Requirements:

- non-empty
- each block must include `source:`
- minimal sufficient excerpts
- no bulk dumping

------

### 4. metadata.json

Must include:

- `query_id`
- `query_type`
- `scope`
- `sources`
- `created_at`

------

## Metadata Requirements

Required:
- query_id
- sources

Recommended:
- query_type
- scope
- created_at

## Synthesis Candidate Rule

If the result is:

- cross-page integrated
- reusable
- generalizable

then:

- set `synthesis_candidate = true`

BUT:

- DO NOT write to `wiki/synthesis/`
- only propose candidate

------

## Failure Behavior

If wiki is insufficient:

- state limitation clearly
- still produce all four files
- include available evidence
- do NOT fabricate

------

## Design Principle

```text
query = structured knowledge extraction

NOT:
QA
NOT:
free-form summarization
```
