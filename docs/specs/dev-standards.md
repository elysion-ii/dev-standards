---
status: active
created: 2026-07-17
---

# dev-standards Specification

What this repository provides: its required structure, and the distribution and
versioning contract its consumers rely on. Spec-first applies here as everywhere: a
change that alters this contract updates this document before (or with) the change.

## Purpose

Single source of shared engineering rules and project scaffold templates, consumed by
scaffolding and retrofit tooling that clones this repository at a pinned tag.

## Scope

The repository's content structure and its consumption interface. How to *work on* the
repository is `docs/rules/dev-standards.md`; how to *release* is
`docs/guides/release.md`.

## Consumers

- Scaffolding tooling: generates a new repository from `templates/` and distributes
  `rules/` and `skills/`
- Retrofit tooling: brings an existing repository up to a newer tag
- Agent harnesses (Claude Code, Codex, Antigravity): read the distributed files inside
  consuming repositories, not this repository directly

## Required structure

| Path | Must contain |
|------|--------------|
| `rules/standard.md` | The language-agnostic core: design principles, comment philosophy, testing principles, specification rules, Git conventions, and the AUDIT procedure |
| `rules/<language>.md` | One file per supported stack (`dotnet.md`, ...), each starting with an enforcement matrix that classifies every rule as mechanically Enforced or AUDIT-checked |
| `skills/` | Event-driven procedures only (`doc-placement`, `merge-pr`) — never standing rules, which belong in `rules/` |
| `templates/AGENTS.md` | Generic router boilerplate for any repository |
| `templates/dotnet/common/` | Language-independent scaffold files |
| `templates/dotnet/en/`, `ja/` | Language variants in parity: AGENTS.md, README, ADR-0001, Setup.iss, app-rules and spec skeletons |
| `docs/` | Documents about this repository itself |

## Distribution contract

- `rules/*.md` are copied **byte-identical** into each consuming repository at
  `docs/rules/` — no front matter, no in-file markers, no token replacement. Local
  edits in consumers are detected by matching against this repository's tag history
- `skills/*` are copied verbatim to both harness trees (`.claude/skills/` and
  `.agents/skills/`) of consuming repositories
- Templates generate files by literal `{{TOKEN}}` replacement. The token set is part of
  this contract
- Every generated repository receives the pair `docs/rules/<App>.md` ↔
  `docs/specs/<App>.md` (same identifier, declared in its `AGENTS.md` Applications
  table) and an `AGENTS.md` router that holds no rule text

## Placement model (what consumers end up with)

- Rule bodies live only in `docs/rules/`, in three layers applied in order:
  `standard.md` → language files → application rules files; the more specific file wins
  on conflict
- `AGENTS.md` is the only router: facts, commands, Applications table, reading and
  AUDIT instructions
- Scope rule for every docs category: directly under `docs/<category>/` =
  repository-wide; `<App>.md` or `<App>/` = application-specific
- Managed vs. authored: distributed files are never edited in consumers; application
  rules files and specifications are repository-authored

## Versioning contract

- Tags (`vMAJOR.MINOR.PATCH`) are the consumption interface; consumers pin a tag.
  Untagged `main` is never consumed
- **MAJOR**: restructuring that breaks consumers — moved/renamed distributed files,
  changed or removed token names
- **MINOR**: new content — new rules, new language files, new templates
- **PATCH**: fixes and wording corrections
- Changes outside distributed content (`docs/`, `README.md`, `AGENTS.md`) need no tag
  and ride along with the next release

## Invariants

- `templates/dotnet/en/` and `ja/` express the same content
- `rules/` files are token-free and repository-agnostic
- Distributed bytes at a tag never change after the tag is published

## Out of scope

- Consumer-side tooling (how scaffolding/retrofit is invoked is the consumer's concern)
- Concrete per-repository commands — those live in each consuming repository's
  `AGENTS.md`
