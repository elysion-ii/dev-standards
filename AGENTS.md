# dev-standards — Agent Instructions

Shared engineering standards and project templates, distributed into consuming
repositories by scaffolding/retrofit tooling pinned to a tag of this repository (see
`README.md` for the consumer-facing description).

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

None — this repository ships documents and templates, not an application. The
rules ↔ specification pairing does not apply here.

## Rules and AUDIT

- **Before changing anything**, read `rules/standard.md` (the product doubles as this repository's own shared core) and `docs/rules/dev-standards.md` (repository-specific rules)
- **Before reporting a change as complete**, run the AUDIT procedure at the end of `rules/standard.md`. This repository has no build or test gates, so treat every applicable rule as an AUDIT item
- **Before creating, moving, renaming, or archiving any document**, read `skills/doc-placement/SKILL.md` (the source copy in this repository)
- **Before running any `gh pr merge`**, read `skills/merge-pr/SKILL.md`

## Commands

There are no build, format, or test commands. Releases are git tags — the procedure is
`docs/guides/release.md`; the versioning criteria are in `README.md`.

## `docs/`

Documents about this repository, in role-based subfolders (`rules/`, `adr/`, `guides/`,
...) per the `doc-placement` skill. Do not confuse `docs/rules/` (rules for working on
this repository) with `rules/` (the distributed product).
