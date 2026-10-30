# dev-standards — Agent Instructions

Shared engineering standards and project templates, distributed into consuming
repositories by scaffolding/retrofit tooling pinned to a tag of this repository, plus
the published skills that implement that tooling for .NET. What
the repository provides and its consumption contract are specified in
`docs/specs/dev-standards.md`.

`CLAUDE.md` at the repository root is a one-line import of this file. This file is the
repository's router — facts and reading instructions; it holds no rule text.

## Repository Map

| Path | Content |
|------|---------|
| `dist/` | **Everything distributed** — nothing outside it is copied into consuming repositories |
| `dist/rules/` | The product: rule bodies (`standard.md`, `documentation.md`, `git.md`, `cli.md`, `db.md`, `dotnet.md`, ...) distributed **verbatim** into consuming repositories at `docs/rules/` |
| `dist/templates/` | Scaffold templates with literal `{{TOKEN}}` placeholders |
| `dist/templates/dotnet/mapping.md` | The .NET scaffold mapping: template → generated path, retrofit classes, mechanism markers — the single source both published skills read |
| `skills/` | Published skills (`init-dotnet-app`, `retrofit-dotnet-app`), installed by users in their own harness, never copied into consuming repositories |
| `docs/` | Documents about this repository itself (rules for editing it, ADRs, guides) |

## Applications

This repository ships documents and templates, not a runnable application — the
repository content itself takes the application slot:

| Application | Content | Rules | Specification |
|---|---|---|---|
| dev-standards | `dist/`, `skills/` | `docs/rules/dev-standards.md` | `docs/specs/dev-standards.md` |

## Rules and AUDIT

Rules for this repository follow the three-tier model:
- **Application rules**: `docs/rules/dev-standards.md` (repository-specific rules and overrides)
- **Core rules**: `dist/rules/` (this repository's own product doubles as its core standards: `standard.md`, `documentation.md`, `git.md`, and the conditional core files `cli.md` and `db.md`)
- **Specifications**: `docs/specs/dev-standards.md` (contract) and `docs/specs/template-requirements.md` (template requirements)

**Precedence on conflict**: Application rules (`docs/rules/dev-standards.md`) > Core rules.

- **Spec-First**: stated for this repository in `docs/rules/dev-standards.md` (Changing this repository).
- **Completion Gate (AUDIT)**: pass the AUDIT gate at the end of `dist/rules/standard.md`. This repository has no build or test gates, so AUDIT step 4 has no command to run.

## Commands

There are no build, format, or test commands. The one mechanical check is the mapping
coverage check in `docs/guides/release.md`; when it runs is stated in
`docs/rules/dev-standards.md` (Distributed content). Releases are git
tags — the procedure is `docs/guides/release.md`; the versioning criteria are in
`docs/specs/dev-standards.md`.

## `docs/`

Documents about this repository, in role-based subfolders (`rules/`, `adr/`, `guides/`,
...) per `dist/rules/documentation.md`. Everything under `docs/` is about maintaining
this repository; everything under `dist/` is the distributed product, and `skills/`
holds the published skills.
