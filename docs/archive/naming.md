# AGENTS/naming.md

## Purpose

Define naming rules to ensure consistency, uniqueness, and stable linking.

## Rules

- lowercase
- use hyphen
- no spaces
- use URL-safe characters only

## Naming Principle

- Use the most commonly accepted canonical name
- Prefer widely used abbreviations when standard (e.g., sindy)
- Names should be concise but descriptive
- filename (slug) should be a normalized form of the title

## Uniqueness

- Names must be unique within the same directory
- If conflict occurs → STOP and ask user

## ASCII Constraint

- Filenames MUST be ASCII-only
- Titles may contain Unicode, but slugs must not

## Stability

- Do not rename existing files unless explicitly required

## Scope

- The same name may exist across different page types if meanings differ

## Slug

- Use lowercase ASCII characters
- Replace spaces with hyphens
- Remove special characters

## Frontmatter

- Follow page-type-specific frontmatter rules defined elsewhere
- Do not enforce a single schema across all page types