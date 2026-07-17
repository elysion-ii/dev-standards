# <PROJECT NAME> — Agent Instructions

<!-- Generic boilerplate for any repository (language-agnostic). Replace every
     <PLACEHOLDER>, fill in the tables, and delete these comments. For .NET
     applications, use templates/dotnet/ instead. -->

<ONE-PARAGRAPH PROJECT OVERVIEW: what this repository is and what it produces.>

`CLAUDE.md` at the repository root is a one-line import of this file — this file is the
single body of repository rules. Edit this file, never `CLAUDE.md`.

## Technology Stack

| Item | Detail |
|------|--------|
| Language | <LANGUAGE(S)> |
| Runtime / framework | <RUNTIME> |
| Distribution | <HOW IT SHIPS> |

## Standards and AUDIT

- **Before implementing any change**, read the `standards` skill, distributed in this repository at `.claude/skills/standards/` and `.agents/skills/standards/`: `SKILL.md` plus every language file matching this project's stack
- **Before reporting an implementation task as complete**, run the AUDIT procedure at the end of the skill's `SKILL.md`
- When rules in this file conflict with the skill, this file takes precedence

## Commands

| Purpose | Command |
|---------|---------|
| Format | `<FORMATTER COMMAND>` |
| Format check (must pass before completion) | `<FORMATTER CHECK COMMAND>` |
| Build | `<BUILD COMMAND>` |
| Test | `<TEST COMMAND>` |

## Directory Layout

<DESCRIBE THE TOP-LEVEL DIRECTORIES AND WHAT BELONGS IN EACH.>

### `docs/`

All non-source documents, placed in role-based subfolders (`adr/`, `specs/`, `guides/`,
`references/`, `investigations/`, `notes/`, `plans/`, `inbox/`, `archive/`). Every
document carries front matter (at least `created` and `status`; ADRs carry `status`
only). Follow the `doc-placement` skill (also distributed in this repository) for
placement, naming, and archiving decisions.

## Repository-Specific Rules

<RULES THAT APPLY ONLY TO THIS REPOSITORY. Keep them concise and declarative; put
rationale in an ADR under docs/adr/ and reference it from here.>
