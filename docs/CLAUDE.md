# CLAUDE.md

## Purpose

This repository is an LLM Wiki for curated research knowledge.

It is a controlled knowledge pipeline, not a document generator.

---

# Core Principles

## Layer Separation (Strict)

- raw/ is the immutable source layer (READ ONLY)
- raw/incoming/ contains unverified inputs (DO NOT commit)
- review/ is the validation and staging layer
- wiki/ is the curated knowledge layer
- wiki/synthesis/ contains only approved reusable knowledge

---

## Knowledge Flow (Mandatory)

All knowledge MUST follow:

raw → review → (human approval) → wiki

### Critical Rules

- NEVER move content directly from raw/ to wiki/
- NEVER move content directly from raw/llm_logs/ to wiki/synthesis/
- ALL knowledge entering wiki/ MUST pass through review/

---

## Raw Data Integrity

LLM MUST NOT modify raw under any circumstance.

- raw/ is read-only for direct LLM editing
- raw/ may only be updated via the defined ingest process
- If required data is missing → STOP and ask user

---

## Approval Rule

Human approval is mandatory for any knowledge promoted from review to wiki.

- No automatic approval
- No inferred approval
- Missing approval metadata MUST NOT be fabricated
- Approved artifacts MUST include required approval metadata and MUST NOT be re-promoted.

---

## Wiki Consistency Rule

- Every wiki page MUST appear in index.md
- Every update MUST append to log.md
- log.md is append-only

---

## Commit Rule

raw, review, and wiki updates MUST be committed separately.

Additional constraint:

- downstream tasks MUST operate on committed inputs only
- mixing uncommitted and committed state is prohibited

---

# Task Model

## Task Types (Mandatory Classification)

Every request MUST be classified into exactly one:

- ingest
- lint
- synthesize
- synthesize_logs
- approve
- query_answer
- query_extract
- query_fix
- audit

---

## Task Selection Rule

Priority:

1. explicit command
2. natural language classification
3. otherwise → STOP

------

### Task Model Note

The task model defines logical execution categories.

Not all tasks are implemented in CLI (`scripts/rw_cli.py`).
Some tasks are handled via prompt-level orchestration.

---

## Ambiguity Rule

If task classification is unclear → STOP

---

# Agent Loading Rule

Do NOT load all files under AGENTS/ by default.

- Load ONLY the AGENTS required for the current task
- CLAUDE.md defines control
- AGENTS define execution

---

# Task → AGENTS Mapping (Default)

- ingest → AGENTS/ingest.md
- lint → AGENTS/lint.md
- synthesize → AGENTS/synthesize.md
- synthesize_logs → AGENTS/synthesize_logs.md
- approve → AGENTS/approve_synthesis.md
- query_answer → AGENTS/query_answer.md
- query_extract → AGENTS/query.md
- query_fix → AGENTS/query_fix.md
- audit → AGENTS/audit.md

---

# Execution Model

## Execution Declaration (Mandatory)

Before execution, declare when operating interactively:

- Task Type
- Loaded Agents
- Execution Plan

Note:

- In CLI-based execution, the command itself acts as the declaration.

---

## Multi-Step Rule

Multi-step workflows MUST be decomposed.

Forbidden:

- ingest → wiki in one step
- raw → wiki without review
- query → synthesis promotion in one step

Rule:

- Each step MUST correspond to a valid task boundary.

---

# Audit Rule

audit is read-only and evaluates the integrity, consistency, and structure of the wiki.

- Do NOT modify files during audit
- Report issues first
- Repair only after explicit instruction

---

# Failure Conditions

STOP immediately if:

- task is unclear
- required inputs are missing
- attempting to bypass review
- attempting to modify raw/
- required AGENTS are not identified
- attempting to write to wiki without approved review artifacts
- attempting to use uncommitted source inputs for downstream tasks

---

# Final Principle

You are not writing documents.

You are building:

a controlled, validated knowledge system
