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

- Scaffolding tooling: generates a new repository from `dist/templates/` and
  distributes `dist/rules/`
- Retrofit tooling: brings an existing repository up to a newer tag
- Agent harnesses (Claude Code, Codex, Antigravity): read the distributed files inside
  consuming repositories, not this repository directly

## Required structure

Everything distributed lives under `dist/` — the boundary between the product and the
repository's own maintenance files is that single path prefix.

| Path | Must contain |
|------|--------------|
| `dist/` | The entire consumption interface — nothing outside it is distributed |
| `dist/rules/standard.md` | The stack-agnostic core: design principles (including atomic, re-runnable, and concurrency-safe writes, and stored time), comment philosophy, testing principles, the spec-first principle, external-input handling, configuration-value handling, failure reporting, procedure-design principles, and the AUDIT procedure |
| `dist/rules/documentation.md` | Task-specific rule file for documentation work: document responsibility, classification, placement, naming, front matter, specification content and structure, and document lifecycle |
| `dist/rules/git.md` | Task-specific rule file for Git write operations: commit, branch, and PR rules, merge strategy, and the generic `gh pr merge` procedure |
| `dist/rules/cli.md` | Conditional core file for applications that expose a command-line interface: option and subcommand naming and syntax, help, output streams, exit codes, configuration precedence, and version output. Stack-agnostic; starts with an enforcement matrix like the stack rule files |
| `dist/rules/db.md` | Conditional core file for applications that read or write a database: schema ownership, schema constraints, migrations, deployment of schema changes, and query shape. Stack-agnostic; starts with an enforcement matrix like the stack rule files |
| `dist/rules/<stack>.md` | One file per supported stack (`dotnet.md`, `typescript.md`, `python.md`, ...), each starting with an enforcement matrix that classifies every rule as mechanically Enforced or AUDIT-checked |
| `dist/templates/shared/` | Stack-agnostic templates: generic router `AGENTS.md` (for repositories without a stack template set — a stack template set ships its own router variants), plus `settings.json.tmpl` (Claude Code hooks) and `hooks.json.tmpl` (Codex hooks) — each carrying a session-start hook that directs the agent to read `docs/rules/` in full before acting, and a pre-commit hook that blocks `git commit` until the AUDIT procedure is confirmed |
| `dist/templates/dotnet/common/` | Language-independent scaffold files |
| `dist/templates/dotnet/en/`, `ja/` | Language variants in parity: AGENTS.md, README, ADR-0001, Setup.iss, app-rules and spec skeletons |
| `docs/` | Documents about this repository itself |

## Distribution contract

- `dist/rules/*.md` are copied **byte-identical** into each consuming repository at
  `docs/rules/` — no front matter, no in-file markers, no token replacement. The core,
  the task-specific files, and the conditional core files (`cli.md`, `db.md`) go to
  every repository; each stack rule file goes to repositories of the matching stack. A
  conditional core file is distributed even where its condition is false, so an
  application that gains the property needs no redistribution. Local edits in consumers
  are detected by matching against this repository's tag history
- Templates generate files by literal `{{TOKEN}}` replacement. The token set is part of
  this contract
- Every generated repository receives the pair `docs/rules/<App>.md` ↔
  `docs/specs/<App>.md` (same identifier, declared in its `AGENTS.md` Applications
  table) and an `AGENTS.md` router that holds no rule text

## Placement model (what consumers end up with)

- Rule bodies live only in `docs/rules/`, and every one of them is read before
  implementing any change. The conditional core files (`cli.md`, `db.md`) are the only
  exception: each opens with the condition under which it applies — a fact about the
  application — and is skipped while that condition is false for the application being
  changed. On conflict the more specific rule wins — application rules > stack rules >
  core rules
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
- **MINOR**: new content — new rules, new stack rule files, new templates
- **PATCH**: fixes and wording corrections
- Changes outside `dist/` need no tag and ride along with the next release

## Invariants

- Each stack's `dist/templates/<stack>/en/` and `ja/` express the same content
- `dist/rules/` files are token-free and repository-agnostic
- Core rule files never contradict each other: each subject is stated in exactly one
  core file
- Distributed bytes at a tag never change after the tag is published

## Out of scope

- Consumer-side tooling: how scaffolding/retrofit is invoked is the consumer's
  concern. The obligations any scaffolding implementation honors (rule distribution,
  repository settings, optional files) are stated in
  `docs/specs/template-requirements.md`
- Concrete per-repository commands — those live in each consuming repository's
  `AGENTS.md`
