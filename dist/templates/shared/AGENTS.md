# <PROJECT NAME> — Agent Instructions

<!-- Generic boilerplate for any repository (language-agnostic). Replace every
     <PLACEHOLDER>, fill in the tables, and delete these comments. For .NET
     applications, use dist/templates/dotnet/ instead. -->

<ONE-PARAGRAPH PROJECT OVERVIEW: what this repository is and what it produces.>

`CLAUDE.md` at the repository root is a one-line import of this file. This file is the
repository's router — facts, commands, and reading instructions; it holds no rule text.
Rule bodies live under `docs/rules/`. Edit this file, never `CLAUDE.md`.

## Technology Stack

| Item | Detail |
|------|--------|
| Language | <LANGUAGE(S)> |
| Runtime / framework | <RUNTIME> |
| Distribution | <HOW IT SHIPS> |

## Applications

| Application | Projects | Rules | Specification |
|---|---|---|---|
| <APP> | <PROJECT LIST> | `docs/rules/<APP>.md` | `docs/specs/<APP>.md` |

## Rules and AUDIT

- **Before implementing any change**, read in order: `docs/rules/standard.md` (shared core), every language file under `docs/rules/` matching this project's stack, then the application's rules file and specification from the Applications table. On conflict the more specific file wins (application > language > core)
- **Before creating, changing, moving, renaming, archiving, or deleting any document**, also read `docs/rules/documentation.md`
- **Before any Git write operation or PR operation** (commit, branch, push, PR creation, update, or merge), also read `docs/rules/git.md`
- When a change requires behavior not in the specification, update the specification **before** implementing (spec-first — see the Specifications section of `docs/rules/standard.md`)
- **When transitioning from a plan to implementation**, re-read this file (root and any nested `AGENTS.md` covering the work area) and the rules files first, so all rules are loaded before code is written
- **Before reporting an implementation task as complete**, run the AUDIT procedure at the end of `docs/rules/standard.md`
- `docs/rules/standard.md`, `docs/rules/documentation.md`, `docs/rules/git.md`, and the language files are managed by dev-standards — never edit them; repository- and application-specific rules go in the application's rules file

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

All non-source documents, placed in role-based subfolders (`rules/`, `adr/`, `specs/`,
`guides/`, `references/`, `investigations/`, `notes/`, `plans/`, `inbox/`, `archive/`).
Before creating, changing, moving, renaming, archiving, or deleting any document — or
when unsure where one belongs — read `docs/rules/documentation.md` (also distributed
in this repository) first; it defines placement, naming, and front matter. Do not
classify or name documents from memory.

- `docs/rules/` — rule bodies: `standard.md`, `documentation.md`, `git.md`, and language files (managed by dev-standards) and the application rules files
- `docs/specs/` — application specifications
