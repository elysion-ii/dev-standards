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
scaffolding and retrofit tooling that clones this repository at a pinned tag — and the
publisher of skills that implement that tooling for the .NET template set.

## Scope

The repository's content structure and its consumption interface. How to *work on* the
repository is `docs/rules/dev-standards.md`; how to *release* is
`docs/guides/release.md`.

## Consumers

- Scaffolding tooling: generates a new repository from `dist/templates/` and
  distributes `dist/rules/`, as the stack's scaffold mapping directs
- Retrofit tooling: brings an existing repository up to a newer tag, deriving the
  target state from the same mapping
- Agent harnesses (Claude Code, Codex, Antigravity): read the distributed files inside
  consuming repositories, not this repository directly

This repository publishes one implementation of the scaffolding and retrofit tooling
for the .NET template set, as agent skills under `skills/` (see **Published skills**).

## Required structure

Everything distributed lives under `dist/` — the boundary between the product and the
repository's own maintenance files is that single path prefix.

| Path | Must contain |
|------|--------------|
| `dist/` | The entire consumption interface — nothing outside it is distributed |
| `dist/rules/standard.md` | The stack-agnostic core: design principles (including atomic, re-runnable, and concurrency-safe writes, and stored time), comment philosophy, testing principles, the spec-first principle, external-input handling, keeping values out of executed text, configuration-value handling, failure reporting, procedure-design principles, and the AUDIT procedure |
| `dist/rules/documentation.md` | Task-specific rule file for documentation work: document responsibility, classification, placement, naming, front matter, specification content and structure, and document lifecycle |
| `dist/rules/git.md` | Task-specific rule file for Git write operations: commit, branch, and PR rules, merge strategy, and the generic `gh pr merge` procedure |
| `dist/rules/cli.md` | Conditional core file for applications that expose a command-line interface: option and subcommand naming and syntax, help, output streams, exit codes, configuration precedence, and version output. Stack-agnostic; starts with an enforcement matrix like the stack rule files |
| `dist/rules/db.md` | Conditional core file for applications that read or write a database: schema ownership, schema constraints, migrations, deployment of schema changes, and query shape. Stack-agnostic; starts with an enforcement matrix like the stack rule files |
| `dist/rules/<stack>.md` | One file per supported stack (`dotnet.md`, `typescript.md`, `python.md`, ...), each starting with an enforcement matrix that classifies every rule as mechanically Enforced or AUDIT-checked |
| `dist/templates/shared/` | Stack-agnostic templates: generic router `AGENTS.md` (for repositories without a stack template set — a stack template set ships its own router variants), plus `settings.json.tmpl` (Claude Code hooks) and `hooks.json.tmpl` (Codex hooks) — each carrying a session-start hook that directs the agent to read `docs/rules/` in full before acting, and a pre-commit hook that blocks `git commit` until the AUDIT procedure is confirmed |
| `dist/templates/dotnet/common/` | Language-independent scaffold files |
| `dist/templates/dotnet/en/`, `ja/` | Language variants in parity: AGENTS.md, README, ADR-0001, Setup.iss, app-rules and spec skeletons |
| `dist/templates/<stack>/mapping.md` | The stack's scaffold mapping (see **Scaffold mapping**); `dist/templates/dotnet/mapping.md` for .NET |
| `skills/` | The published skills (see **Published skills**) — outside `dist/`, because they are installed in a user's agent harness, never copied into a consuming repository |
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
- No skill is copied into a consuming repository (`docs/adr/0002-retire-distributed-skills.md`).
  The published skills under `skills/` are tooling a user installs, not distributed
  content

## Scaffold mapping

- Each stack template set carries one mapping file, `dist/templates/<stack>/mapping.md`,
  read by scaffolding and retrofit tooling from the tag they apply. It is the single
  source for: which template or rule file generates which path in a consuming
  repository (including type-specific entry points, optional files, the rules
  distribution, and the `dist/templates/shared/` templates), which retrofit class each
  generated path belongs to, which files under `dist/` the stack deliberately does not
  generate, and the mechanism markers retrofit uses to recognize a template-carried
  mechanism in an existing file
- No tooling carries its own copy of any of these tables: tooling derives every target
  path and marker from the mapping file of the tag it applies
- The mapping file states a **mapping format** number: the number of the structure
  tooling reads (sections, columns, placeholders, retrofit classes). Tooling that reads
  a format number it was not written for stops
- The mapping file itself is read by tooling and never generated into a consuming
  repository

## Published skills

- `skills/init-dotnet-app/` (scaffold a new .NET repository) and
  `skills/retrofit-dotnet-app/` (converge an existing .NET repository onto the newest
  tag) are agent skills written in the Claude Code skill format (`SKILL.md` with
  `allowed-tools` front matter, questions through the `AskUserQuestion` tool). Another
  harness uses them after adapting those harness-specific parts
- A user obtains them by copying the skill directories from a tag of this repository
  into their harness's skills directory. Untagged `main` is not a source, as for every
  other consumable
- At run time each skill clones the newest tag of this repository and reads the stack's
  mapping file from that clone; it carries no mapping of its own. A skill written for a
  different mapping format stops and tells the user to obtain the skills again from the
  tag it resolved
- Only procedures that are event-driven and hold no standing rule text are published as
  skills (`docs/adr/0004-publish-scaffolding-skills.md`). Rule text stays in
  `dist/rules/`

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
  changed or removed token names, a moved or renamed mapping file, a changed mapping
  format (its format number increments)
- **MINOR**: new content — new rules, new stack rule files, new templates (with their
  new mapping rows), new mechanism markers, new capabilities of a published skill
- **PATCH**: fixes and wording corrections, in distributed content and in the published
  skills alike
- A change under `dist/` or `skills/` is consumable only once tagged. Changes outside
  both need no tag and ride along with the next release

## Invariants

- Each stack's `dist/templates/<stack>/en/` and `ja/` express the same content
- `dist/rules/` files are token-free and repository-agnostic
- Core rule files never contradict each other: each subject is stated in exactly one
  core file
- Distributed bytes at a tag never change after the tag is published
- Every file under `dist/templates/` and `dist/rules/` is named by a stack's mapping
  file, either as a source or as deliberately not generated. The coverage check in
  `docs/guides/release.md` confirms it

## Out of scope

- Consumer-side tooling other than the published skills: how scaffolding/retrofit is
  invoked is the consumer's concern. The obligations any scaffolding implementation
  honors (rule distribution, repository settings, optional files) are stated in
  `docs/specs/template-requirements.md`, and the target paths it generates in the
  stack's mapping file
- Concrete per-repository commands — those live in each consuming repository's
  `AGENTS.md`
