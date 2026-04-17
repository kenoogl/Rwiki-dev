# AGENTS/query_answer.md

## Purpose

Answer user questions using the curated wiki knowledge.

This mode is for **direct explanation to the user**.

It is NOT the artifact-generation mode.
If the task is to generate reusable knowledge artifacts under `review/query/`, use:

- `AGENTS/query.md` for extraction
- `AGENTS/query_fix.md` for repair

------

## Mode Definition

This agent handles:

- question answering
- explanation
- clarification using existing wiki knowledge
- lightweight cross-page synthesis for the sake of answering

This agent does NOT handle:

- generating `review/query/<query_id>/...` artifacts
- fixing query lint failures
- writing directly to `wiki/synthesis/`

------

## Source of Truth

- Primary source is `wiki/`
- Read `index.md` first when useful
- Identify relevant wiki pages before answering
- Prefer existing curated knowledge over unstaged or raw material

Do NOT rely on:

- `raw/`
- `raw/incoming/`
- `raw/llm_logs/`
- external assumptions

unless explicitly instructed by the user.

------

## Core Rules

### 1. Wiki-first answering

Always answer from the current wiki knowledge.

Do NOT bypass the knowledge system by inventing facts that are not supported by `wiki/`.

If the wiki is incomplete, say so explicitly.

Recommended phrasing:

- "insufficient knowledge in current wiki"
- "the current wiki does not contain enough information to answer this fully"

------

### 2. Direct explanation, not artifact generation

The goal in this mode is to help the user understand something now.

Therefore:

- produce a clear answer in chat-style prose
- do not force the 4-file artifact contract
- do not generate `query.md`, `answer.md`, `evidence.md`, or `metadata.json` unless explicitly asked to switch to extraction mode

------

### 3. Structured but lightweight answers

Prefer answers that are:

- clearly organized
- concise but complete
- easy to scan

Use when appropriate:

- short sections
- compact bullet lists
- `[[wiki links]]` for related concepts

Avoid over-structuring simple answers.

------

### 4. Maintain terminology consistency

Use terminology consistent with the existing wiki.

Do NOT introduce conflicting definitions.

If multiple terms exist in the wiki:

- prefer the dominant/canonical one
- mention aliases only when useful for clarity

------

### 5. Distinguish fact from interpretation

In answer mode, strict artifact-style evidence separation is not required.

However:

- do not present unsupported interpretation as established fact
- when making a cross-page interpretation or lightweight synthesis, clearly signal uncertainty

Use phrases such as:

- "based on the current wiki, ..."
- "the wiki suggests that ..."
- "it appears that ..."
- "[INFERENCE] ..." when strong explicit marking is useful

If a claim is not directly grounded in wiki content, weaken it or label it.

------

### 6. Do not hallucinate missing knowledge

If relevant wiki pages cannot be found, or the answer cannot be supported:

- state the limitation clearly
- explain what is missing
- optionally suggest a better next step

Possible next steps:

- create a query artifact
- ingest missing source material
- synthesize missing knowledge into wiki later

------

## Answering Process

### Step 1. Identify the question type

Classify the user’s request informally, for example:

- definition
- explanation
- comparison
- why / rationale
- summary
- relationship between concepts

This classification is only to improve answer quality.
Do not over-expose it unless useful.

------

### Step 2. Locate relevant wiki knowledge

- check `index.md` if needed
- identify the most relevant wiki pages
- prefer directly relevant pages over broad summarization

------

### Step 3. Build the answer

Construct an answer that:

- starts with the direct answer
- adds structure only as needed
- highlights key relationships across pages when useful
- stays inside the boundary of current wiki knowledge

------

### Step 4. Handle insufficiency explicitly

If the wiki is not enough:

- say so directly
- do not fill the gap with fabricated content
- separate what is known from what is missing

------

### Step 5. Suggest escalation only when useful

If the answer naturally reveals reusable cross-page knowledge, you may suggest:

- turning it into a query artifact under `review/query/`
- later proposing a synthesis candidate

But do NOT automatically generate or save anything unless instructed.

------

## Output Style

### Default style

Use a clear explanatory style.

Prefer:

- direct opening sentence
- short sections where helpful
- compact lists for comparisons or reasons
- internal wiki links when they genuinely help navigation

------

### When the user asks a simple question

Answer simply.

Do NOT turn a simple question into a formal report.

------

### When the user asks a cross-page or conceptual question

You may:

- compare concepts
- connect related pages
- point out tensions or gaps
- summarize the current wiki position

But keep the output in **answer mode**, not extraction mode.

------

## What This Agent May Do

- answer based on existing wiki pages
- explain relationships between concepts
- summarize the current state of knowledge in the wiki
- point out missing knowledge
- suggest artifact generation when it would help

------

## What This Agent Must Not Do

- generate `review/query/<query_id>/...` by default
- repair lint issues in query artifacts
- write directly to `wiki/synthesis/`
- treat `raw/` as if it were curated knowledge
- fabricate support for missing claims

------

## Escalation Rule

If the user’s request is better treated as reusable knowledge extraction rather than direct answering, suggest switching modes.

Typical examples:

- "整理して保存したい"
- "再利用可能な形にしたい"
- "後で synthesis に回したい"
- "evidence 付きで残したい"

In such cases, prefer:

- `AGENTS/query.md` for extraction
- `AGENTS/query_fix.md` if repair is needed

------

## Failure Conditions

If the answer would require unsupported claims, do NOT bluff.

Instead:

1. state what the current wiki supports
2. state what the current wiki does not support
3. answer only within that boundary

------

## Design Principle

```text
query_answer = wiki-based direct explanation
not artifact generation
not free-form guessing
```