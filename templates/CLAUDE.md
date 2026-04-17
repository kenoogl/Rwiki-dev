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

Not all tasks are implemented in CLI (`scripts/rw_light.py`).
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

## Agent Loading Procedure

1. Identify task type from the request
2. Look up required Agent and Policy files in the Task → AGENTS Mapping table
3. Load each file using Read tool: `Read("AGENTS/<file>.md")`

---

# Task → AGENTS Mapping (Default)

| Task | Agent | Policy | Execution Mode |
|---|---|---|---|
| ingest | AGENTS/ingest.md | AGENTS/git_ops.md | CLI |
| lint | AGENTS/lint.md | AGENTS/naming.md | CLI |
| synthesize | AGENTS/synthesize.md | AGENTS/page_policy.md, AGENTS/naming.md | Prompt |
| synthesize_logs | AGENTS/synthesize_logs.md | AGENTS/naming.md | CLI (Hybrid) |
| approve | AGENTS/approve.md | AGENTS/git_ops.md, AGENTS/page_policy.md | CLI |
| query_answer | AGENTS/query_answer.md | AGENTS/page_policy.md | Prompt |
| query_extract | AGENTS/query_extract.md | AGENTS/naming.md, AGENTS/page_policy.md | Prompt |
| query_fix | AGENTS/query_fix.md | AGENTS/naming.md | Prompt |
| audit | AGENTS/audit.md | AGENTS/page_policy.md, AGENTS/naming.md, AGENTS/git_ops.md | Prompt |

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

# Execution Flow

## Prompt Execution (5 steps)

When handling a task in interactive / prompt mode:

1. Classify task type from the request
2. Identify required Agent and Policy files from the Mapping table
3. Load Agent and Policy files using Read tool
4. Declare: Task Type / Loaded Agents / Execution Plan
5. Execute according to the loaded Agent rules

## Agent Lifecycle

- Load ONLY the files required for the current task
- Do NOT retain agent context across different task types
- Re-load if task type changes within a session

## CLI Execution

For CLI-based tasks (ingest, lint, synthesize_logs, approve):

- The command itself acts as the execution declaration
- Agent files define the rules that the CLI implementation follows
- No interactive agent loading is required

## Rule Hierarchy

1. Core Principles (this file) — always in effect
2. Task Model rules (this file) — always in effect
3. Agent rules (AGENTS/*.md) — loaded per task
4. Policy rules (AGENTS/page_policy.md etc.) — loaded alongside agent

When conflicts arise between layers, higher layer takes precedence.

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

## Failure Condition Judgment Criteria for "required AGENTS are not identified"

Stop if ANY of the following:

1. Task type maps to an agent file that does not exist under AGENTS/
2. Agent file is present but does not contain the required 8 sections (Purpose / Execution Mode / Prerequisites / Input / Output / Processing Rules / Prohibited Actions / Failure Conditions)
3. Task type cannot be determined from the request (ambiguity rule also applies)

---

# Extension Guide

To add a new task type:

1. Create `AGENTS/<new-task>.md` with all 8 required sections
2. Add a row to the Task → AGENTS Mapping table (Task / Agent / Policy / Execution Mode)
3. Add the new task type to the Task Types list in Task Model
4. Update `AGENTS/README.md` with the new agent entry and dependency matrix

---

# Final Principle

You are not writing documents.

You are building:

a controlled, validated knowledge system
