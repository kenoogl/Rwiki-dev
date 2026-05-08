# dual-reviewer-rebuild Working Notes

## Development Mode

- This repository uses `cc-sdd` style spec-driven development.
- `intent/` and `operations/` are upstream inputs to `.kiro/specs/`.
- Runtime changes must be traceable to evidence and spec updates.

## Core Rules

- Keep prompts, policies, schemas, and validators inside the repo.
- Do not rely on repo-external memory for steady-state behavior.
- Treat raw evidence as immutable.
- Route behavior changes through spec updates, not ad-hoc prompt edits.

## Current Priority

1. Fix upper-layer documents.
2. Write requirements for the 5 specs.
3. Migrate foundation artifacts.
