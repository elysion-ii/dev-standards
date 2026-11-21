# dev-standards — Agent Instructions

Shared engineering standards and project templates, distributed into consuming
repositories by rule-synchronization, scaffolding, and retrofit tooling pinned to a tag
of this repository, plus the published skills that implement those procedures. What the
repository provides and its consumption contract are specified in
`docs/specs/dev-standards.md`.

`CLAUDE.md` at the repository root is a one-line import of this file. This file is the
repository's router — facts and reading instructions; it holds no rule text.

## Repository Map

| Path | Content |
|------|---------|
| `dist/` | **Everything distributed** — nothing outside it is copied into consuming repositories |
| `dist/rules/` | The product: 4 universal shared rules (`standard.md`, `documentation.md`, `specs.md`, `testing.md`), 10 conditional shared rules (`cli.md`, `client.md`, `cloud.md`, `configuration.md`, `db.md`, `file-exchange.md`, `remote-calls.md`, `security.md`, `values.md`, `web-api.md`), and stack rules (`dotnet.md`, `dotnet-client.md`), distributed selectively and **verbatim** into consuming repositories at `docs/rules/` |
| `dist/templates/` | Scaffold templates with literal `{{TOKEN}}` placeholders and shared harness/router templates |
| `dist/templates/shared/rules-mapping.md` | The shared rules mapping: catalogs every distributed rule file, its applicability (`universal` / `conditional` / `stack`), and its `Mapping format` number — the single source read by `sync-rules` and scaffolding skills |
| `dist/templates/dotnet/mapping.md` | The .NET scaffold mapping: template → generated path, app-type rule defaults, retrofit classes, mechanism markers — the single source read by `init-dotnet-app` and `retrofit-dotnet-app` |
| `dist/tools/` | Opt-in tools, one directory each with its `README.md`, copied verbatim into a consuming repository only when it adopts the tool |
| `skills/` | Published skills (`sync-rules`, `init-dotnet-app`, `retrofit-dotnet-app`, `audit-repo`, `specify-app`), installed by users in their own harness, never copied into consuming repositories |
| `docs/` | Documents about this repository itself (rules for editing it, ADRs, guides) |

## Applications

This repository ships documents, templates, and skills, not a runnable application — the
repository content itself takes the application slot:

| Application | Content | Rules | Specification |
|---|---|---|---|
| dev-standards | `dist/`, `skills/` | `docs/rules/dev-standards.md` | `docs/specs/dev-standards.md` |

## Rules and AUDIT

Rules for this repository follow the three-tier model:
- **Application rules**: `docs/rules/dev-standards.md` (repository-specific rules and overrides)
- **Shared rules**: `dist/rules/` (this repository's own universal shared rules double as its standards: `standard.md`, `documentation.md`, `specs.md`, `testing.md`)
- **Specifications**: `docs/specs/dev-standards.md` (contract) and `docs/specs/template-requirements.md` (template requirements)

**Precedence on conflict**: Application rules (`docs/rules/dev-standards.md`) > Shared rules.

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
