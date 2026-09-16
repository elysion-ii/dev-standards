# <PROJECT NAME> — Agent Instructions

<!-- Generic boilerplate for any repository (stack-agnostic). Replace every
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

Rules in `docs/rules/` are organized into three tiers:
- **Application rules**: `docs/rules/<APP>.md` (repository- and application-specific rules)
- **Stack rules**: Technology-stack rules (`docs/rules/<STACK>.md`; <CHOOSE: managed by dev-standards | repository-authored>)
- **Core rules**: Shared engineering standards (`standard.md`, `documentation.md`, `git.md`, `cli.md`; managed by dev-standards)

**Precedence on conflict**: Application rules > Stack rules > Core rules.

- **Rule Scope**: Every change must strictly comply with every rule file under `docs/rules/` and the application specification under `docs/specs/`. `cli.md` applies only when the application exposes a command-line interface.
- **Loading Rules**: Read this file and every file under `docs/rules/` before writing code (including when transitioning from a plan to implementation).
- **Completion Gate (AUDIT)**: Before reporting an implementation task as complete, pass the AUDIT gate in `docs/rules/standard.md`.
- **File Ownership**: Rules managed by dev-standards (core rules, and distributed stack rules) are read-only; repository-authored rules (application rules, and local stack rules) are edited in this repository.

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
in this repository) first; it defines placement, naming, and front matter.

- `docs/rules/` — rule bodies: `standard.md`, `documentation.md`, `git.md`, `cli.md`, stack rules (managed by dev-standards or repository-authored), and the application rules files
- `docs/specs/` — application specifications
