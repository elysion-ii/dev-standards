# dev-standards — Agent Instructions

Shared engineering standards and project templates, distributed into consuming
repositories by scaffolding/retrofit tooling pinned to a tag of this repository. What
the repository provides and its consumption contract are specified in
`docs/specs/dev-standards.md`.

`CLAUDE.md` at the repository root is a one-line import of this file. This file is the
repository's router — facts and reading instructions; it holds no rule text.

## Repository Map

| Path | Content |
|------|---------|
| `rules/` | The product: rule bodies (`standard.md`, `dotnet.md`, ...) distributed **verbatim** into consuming repositories at `docs/rules/` |
| `skills/` | Distributed event-driven skills (`doc-placement`, `merge-pr`) |
| `templates/` | Scaffold templates with literal `{{TOKEN}}` placeholders |
| `docs/` | Documents about this repository itself (rules for editing it, ADRs, guides) |

## Applications

This repository ships documents and templates, not a runnable application — the
repository content itself takes the application slot:

| Application | Content | Rules | Specification |
|---|---|---|---|
| dev-standards | `rules/`, `skills/`, `templates/` | `docs/rules/dev-standards.md` | `docs/specs/dev-standards.md` |

## Rules and AUDIT

- **Before changing anything**, read `rules/standard.md` (the product doubles as this repository's own shared core), `docs/rules/dev-standards.md` (repository-specific rules), and `docs/specs/dev-standards.md` (the structure and consumption contract)
- **When a change alters the structure or the distribution/versioning contract**, update the specification before (or with) the change — spec-first
- **Before reporting a change as complete**, run the AUDIT procedure at the end of `rules/standard.md`. This repository has no build or test gates, so treat every applicable rule as an AUDIT item
- **Before creating, moving, renaming, or archiving any document**, read `skills/doc-placement/SKILL.md` (the source copy in this repository)
- **Before running any `gh pr merge`**, read `skills/merge-pr/SKILL.md`

## Commands

There are no build, format, or test commands. Releases are git tags — the procedure is
`docs/guides/release.md`; the versioning criteria are in `docs/specs/dev-standards.md`.

## `docs/`

Documents about this repository, in role-based subfolders (`rules/`, `adr/`, `guides/`,
...) per the `doc-placement` skill. Do not confuse `docs/rules/` (rules for working on
this repository) with `rules/` (the distributed product).
