# <PROJECT NAME> — Agent Instructions

<!-- Generic boilerplate for any repository (stack-agnostic). Replace every
     <PLACEHOLDER>, fill in the tables, create `docs/rules/<APP>.md`,
     `docs/specs/<APP>.md`, and `docs/references/code-map.md` (this starter file does
     not generate them), and delete these comments. For .NET applications, use
     dist/templates/dotnet/ instead. -->

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
- **Shared rules**: Universal engineering standards (`standard.md`, `documentation.md`, `specs.md`, `testing.md`) plus any applicable conditional shared rule files distributed under `docs/rules/` (managed by dev-standards)

**Precedence on conflict**: Application rules > Stack rules > Shared rules.

- **Rule Scope**: which rule files and specification every change complies with is stated in `docs/rules/standard.md` (How to Use These Rules).
- **Loading Rules**: Read this file, every applicable rule file under `docs/rules/`, the touched application's specification (`docs/specs/<APP>.md`), and `docs/references/code-map.md` before writing code (including when transitioning from a plan to implementation).
- **Completion Gate (AUDIT)**: Before reporting an implementation task as complete, pass the AUDIT gate in `docs/rules/standard.md`.
- **File Ownership**: rules managed by dev-standards (shared rules and distributed stack rules) are copies of its pinned tag; repository-authored rules (application rules, and local stack rules) are maintained in this repository.

## Commands

| Purpose | Command |
|---------|---------|
| Format | `<FORMATTER COMMAND>` |
| Format check (must pass before completion) | `<FORMATTER CHECK COMMAND>` |
| Build | `<BUILD COMMAND>` |
| Test | `<TEST COMMAND>` |
| End-to-end test | `<END-TO-END TEST COMMAND>` (none until the first end-to-end test; `docs/rules/testing.md`, Test Layers) |

## Code Map

Feature folders and shared mechanism homes are cataloged in `docs/references/code-map.md` (see `docs/rules/documentation.md`, Code Map, and `docs/rules/standard.md`, One Home per Piece of Knowledge).

## Directory Layout

<DESCRIBE THE TOP-LEVEL DIRECTORIES AND WHAT BELONGS IN EACH.>

### `docs/`

All non-source documents, placed in role-based subfolders (`rules/`, `adr/`, `specs/`,
`guides/`, `references/`, `investigations/`, `notes/`, `plans/`, `inbox/`, `archive/`).
Before creating, changing, moving, renaming, archiving, or deleting any document — or
when unsure where one belongs — read `docs/rules/documentation.md` (also distributed
in this repository) first; it defines placement, naming, and front matter.

- `docs/rules/` — rule bodies: universal shared rules (`standard.md`, `documentation.md`, `specs.md`, `testing.md`), applicable conditional shared rules and stack rules, and the application rules files
- `docs/specs/` — application specifications
- `docs/references/code-map.md` — feature folders and shared mechanism homes
