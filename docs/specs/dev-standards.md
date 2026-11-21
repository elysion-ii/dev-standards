---
status: active
created: 2026-07-17
---

# dev-standards Specification

What this repository provides: its required structure, and the distribution and
versioning contract its consumers rely on. Spec-first applies here as everywhere: a
change that alters this contract updates this document before (or with) the change.

## Purpose

Single source of shared engineering rules, project scaffold templates, and opt-in tools,
consumed by rule-synchronization, scaffolding, and retrofit tooling that clones this
repository at a pinned tag — and the publisher of skills that implement rule
synchronization on any stack (`sync-rules`), .NET scaffolding and retrofit
(`init-dotnet-app`, `retrofit-dotnet-app`), whole-repository rule auditing (`audit-repo`),
and writing an application's specification from its implementation (`specify-app`).

## Scope

The repository's content structure and its consumption interface. How to *work on* the
repository is `docs/rules/dev-standards.md`; how to *release* is
`docs/guides/release.md`.

## Consumers

- Rule-synchronization tooling (`sync-rules`): initializes `docs/rules/` in a fresh
  repository or updates an existing repository's `docs/rules/` onto a newer tag per
  `dist/templates/shared/rules-mapping.md`, retires removed managed rules, and optionally
  copies starter router/hook files defined in `dist/templates/shared/rules-mapping.md`
- Auditing tooling (`audit-repo`): audits an existing repository's tracked code, tests,
  and documents against the rules currently held in its `docs/rules/`, and reports any
  conditional shared rule domains newly exercised by code whose rule file is absent. A
  violation is fixed only where the user approves; every other violation is reported as
  deferred
- Scaffolding tooling (`init-dotnet-app` for .NET): generates a new repository from
  `dist/templates/` and distributes universal, conditional, and stack rule files from
  `dist/rules/`, as `dist/templates/shared/rules-mapping.md` and the stack's scaffold
  mapping direct
- Retrofit tooling (`retrofit-dotnet-app` for .NET): brings an existing repository's
  templates, mechanisms, router, documentation layout, and build gates up to a newer tag,
  deriving the target state from `dist/templates/dotnet/mapping.md` and delegating
  `docs/rules/` synchronization to `sync-rules` and whole-repository rule auditing to
  `audit-repo`
- Agent harnesses (Claude Code, Codex, Antigravity): read the distributed files inside
  consuming repositories, not this repository directly
- Developers of a consuming repository: copy an opt-in tool from `dist/tools/` at a
  tag into their repository when they adopt it, as the tool's README directs

This repository publishes five operational agent skills under `skills/` (see **Published
skills**).

## Required structure

Everything distributed lives under `dist/` — the boundary between the product and the
repository's own maintenance files is that single path prefix.

| Path | Must contain |
|------|--------------|
| `dist/` | The entire consumption interface — nothing outside it is distributed |
| `dist/rules/standard.md` | Universal shared core: design principles (separation of concerns, dependency direction, functional core/imperative shell, declared mutation, snapshot before mutate, no lasagna code, one home per piece of knowledge, shared algorithm/local data, change as addition, leave no vestiges, enforce invariants, named constants, resource and lifetime discipline, atomic/re-runnable/conflict-aware writes, synchronous vs asynchronous), conditional-domain index (`Missing conditional rules`), code organization, code comments, spec-first timing, version display and single version definition, explicit deterministic application paths, external-input handling, keeping values out of executed text, failure handling and reporting, build hygiene and static analysis, and the AUDIT procedure |
| `dist/rules/documentation.md` | Universal documentation rules: document responsibility, classification, placement, naming, front matter, writing quality and requirement IDs, procedure design, code map (`docs/references/code-map.md`), document lifecycle, and source-of-truth precedence |
| `dist/rules/specs.md` | Universal specification rules: what a specification states about each decision of the application (the questions it answers), where each answer comes from, and how an existing implementation's behavior that no answer confirms is classified, handled, and recorded in ledgers beside the specification |
| `dist/rules/testing.md` | Universal testing rules: test layers (unit, boundary, end-to-end) and which an application has, environment independence, test data, structure, change coverage, boundary and end-to-end tests, requirement coverage, and when each layer runs |
| `dist/rules/cli.md` | Conditional shared rule file for applications exposing a command-line interface: command structure, option/subcommand naming and syntax, help, output streams, exit codes, configuration precedence, and version output. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/client.md` | Conditional shared rule file for applications packaged and run directly on user or operator machines: minimal packaged footprint without runtime self-extraction or debug symbols, running-instance handling during update or removal, bounded local logs, and scrollable UI list virtualization. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/cloud.md` | Conditional shared rule file for applications storing objects in cloud storage, using managed cloud services, or keeping cloud backups: private container defaults, encryption at rest and key hygiene, short-lived signed transfer URLs, short-lived or managed workload identities, and backup restoration verification. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/configuration.md` | Conditional shared rule file for applications reading installation or preference settings: distinguishing required installation settings vs optional preference defaults, validation on read, separating environment targets and active config files from version control, and source precedence. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/db.md` | Conditional shared rule file for applications reading or writing a database: schema ownership, schema-enforced invariants, migrations, concurrent rollouts, query shape and parameterized bindings, transactions and concurrency, and connection pooling. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/file-exchange.md` | Conditional shared rule file for applications exchanging files with users or external programs: boundary validation, path-traversal prevention, bounded sizes and safe archive extraction, explicit encodings and schema checks, and transient staging over unreliable network paths. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/remote-calls.md` | Conditional shared rule file for applications calling external systems over a network: explicit connection and request timeouts, safe retries and circuit breaking, connection reuse, authenticated encrypted transport, and response validation. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/security.md` | Conditional shared rule file for applications handling secrets, credentials, personal data, or user/role authorization: secret leakage prevention, password hashing and credential storage, authenticated encryption and cryptographic randomness, and default-deny per-action authorization. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/values.md` | Conditional shared rule file for applications persisting or exchanging precision-sensitive values: decimal/minor-unit money representation, explicit rounding, UTC instant and calendar-date types, culture-invariant serialization, and Unicode-aware text limits and comparisons. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/web-api.md` | Conditional shared rule file for applications exposing HTTP or Web APIs: uniform error payloads and HTTP status codes, keyset/cursor pagination, additive contract evolution, request size and rate bounds, and encrypted credential transport. Stack-agnostic; opens with an `Applies when` boundary |
| `dist/rules/<stack>.md` | Stack rule files (`dotnet.md`, `dotnet-client.md`, ...), each starting with an enforcement matrix that classifies every rule as mechanically `Enforced` (when fully checked by tooling) or `AUDIT`-checked (naming partial mechanisms and manual checks) |
| `dist/templates/shared/` | Stack-agnostic templates and shared catalog: generic router `AGENTS.md`, `CLAUDE.md.tmpl`, `settings.json.tmpl` (Claude Code hooks), `hooks.json.tmpl` (Codex hooks), and `rules-mapping.md` (single source cataloging all distributed rule files, their category, and optional shared starter files) |
| `dist/templates/dotnet/common/` | Language-independent scaffold files |
| `dist/templates/dotnet/en/`, `ja/` | Language variants in parity: `AGENTS.md`, `README`, `ADR-0001`, `Setup.iss`, app-rules, spec, and code-map skeletons |
| `dist/templates/<stack>/mapping.md` | The stack's scaffold mapping (see **Scaffold mapping**); `dist/templates/dotnet/mapping.md` for .NET |
| `dist/tools/<tool>/` | One directory per opt-in tool: files a consuming repository copies only when it needs the tool, and a `README.md` stating the tool's prerequisites, which files to copy where, how to run it, and what it produces |
| `dist/tools/sqlserver/` | Schema export of SQL Server databases into SQL database projects, and disposable SQL Server test servers built from those projects in a dedicated WSL distribution running Docker Engine |
| `skills/` | The published skills (see **Published skills**) — outside `dist/`, because they are installed in a user's agent harness, never copied into a consuming repository |
| `docs/` | Documents about this repository itself |

## Distribution contract

- `dist/rules/*.md` are copied **byte-identical** into each consuming repository at
  `docs/rules/` — no front matter, no in-file markers, no token replacement:
  - The four **universal shared files** (`standard.md`, `documentation.md`, `specs.md`,
    `testing.md`) go to every repository.
  - The ten **conditional shared files** (`cli.md`, `client.md`, `cloud.md`,
    `configuration.md`, `db.md`, `file-exchange.md`, `remote-calls.md`, `security.md`,
    `values.md`, `web-api.md`) and **stack rule files** (`dotnet.md`, `dotnet-client.md`,
    ...) are distributed **selectively** to repositories where they apply, per
    `dist/templates/shared/rules-mapping.md` (`docs/adr/0006-rebuild-rules-and-selective-distribution.md`).
  - Local edits and retired managed rules (files no longer in `dist/rules/`, or no
    longer applicable) are detected in consumers by matching against this repository's
    tag history.
- Templates generate files by literal `{{TOKEN}}` replacement. The token set is part of
  this contract.
- Every generated `.NET` repository receives the pair `docs/rules/<App>.md` ↔
  `docs/specs/<App>.md` (same identifier, declared in its `AGENTS.md` Applications
  table), `docs/references/code-map.md`, and an `AGENTS.md` router that holds no rule
  text.
- `dist/tools/<tool>/` files are copied verbatim — no token replacement — into a
  consuming repository only when that repository adopts the tool, to the place the
  tool's README names. Scaffolding and retrofit do not generate them: the stack's
  mapping lists them under **Not generated**.
- No skill is copied into a consuming repository (`docs/adr/0002-retire-distributed-skills.md`).
  The published skills under `skills/` are tooling a user installs, not distributed
  content.

## Scaffold mapping

- **Shared rules mapping (`dist/templates/shared/rules-mapping.md`)**: read by `sync-rules`
  and stack scaffolding skills from the tag they apply. It is the single source listing
  every distributable file under `dist/rules/`, classifying each as universal shared,
  conditional shared, or stack-specific (when a file applies is stated only in that file's opening `**Applies when**` paragraph, which tooling reads from the same tag), listing the
  optional **Shared starter files** (`AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`,
  `.codex/hooks.json`) for repositories without a stack template set, and registering
  itself under **Not generated**. It states its own **Mapping format** number.
- **Stack scaffold mapping (`dist/templates/<stack>/mapping.md`)**: read by scaffolding
  and retrofit tooling from the tag they apply. It is the single source for: which
  template generates which path in a consuming repository (including **Client packaging**
  targets, type-specific entry points, optional files, and shared harness templates),
  app-type default selections from `dist/templates/shared/rules-mapping.md`, which
  retrofit class each generated path belongs to, which template/tool files under `dist/`
  the stack deliberately does not generate, and the mechanism markers retrofit uses to
  recognize a template-carried mechanism in an existing file. It states its own
  **Mapping format** number.
- No tooling carries its own copy of rule catalogs, target tables, or mechanism markers:
  tooling derives every entry from the mapping files of the tag it applies.
- A tool reading a **Mapping format** number it was not written for stops rather than
  guessing.
- Neither mapping file is ever generated into a consuming repository.

## Published skills

- Five agent skills live under `skills/`:
  - `skills/sync-rules/` — stack-agnostic rule synchronization: fetches initial rules into
    a fresh repository or brings an existing repository's `docs/rules/` onto the newest
    tag (adding newly applicable conditional rules, updating stale managed files,
    prompting to retire obsolete managed files, and optionally copying shared starter files
    listed in `dist/templates/shared/rules-mapping.md`)
  - `skills/init-dotnet-app/` — scaffolds a new .NET repository from
    `dist/templates/dotnet/mapping.md` (including client packaging targets only when
    client distribution applies) and distributes selected rules from
    `dist/templates/shared/rules-mapping.md`
  - `skills/retrofit-dotnet-app/` — converges an existing .NET repository's scaffolding,
    mechanisms, `AGENTS.md` router, `docs/references/code-map.md`, docs tree, and staged
    build/test gates onto the newest tag per `dist/templates/dotnet/mapping.md`,
    relying on `sync-rules` for `docs/rules/` synchronization and `audit-repo` for
    whole-repository rule auditing
  - `skills/audit-repo/` — stack-agnostic whole-repository audit: audits every tracked
    non-binary file against the repository's local `docs/rules/`, checks for newly
    exercised conditional rule domains absent from `docs/rules/`, applies approved fixes
    with tests and gates, and records deferred violations
  - `skills/specify-app/` — writes the specification of an existing application, on any
    stack, from its implementation to the criteria of `specs.md`
- All five skills are written in the Claude Code skill format (`SKILL.md` with
  `allowed-tools` front matter, questions through the `AskUserQuestion` tool). Another
  harness uses them after adapting those harness-specific parts.
- A user obtains them by copying the skill directories from a tag of this repository
  into their harness's skills directory. Untagged `main` is not a source, as for every
  other consumable.
- At run time `sync-rules`, `init-dotnet-app`, and `retrofit-dotnet-app` clone the newest
  tag of this repository and read the mapping files from that clone; they carry no rule
  list, starter table, or template mapping of their own. A skill written for a different
  mapping format stops and tells the user to obtain the skills again from the tag it
  resolved.
- Recommended sequence for an existing repository: `sync-rules` → `retrofit-dotnet-app`
  (for .NET repositories) → `audit-repo` → `specify-app` (when the application
  specification does not yet meet `specs.md`); non-.NET repositories run `sync-rules` →
  `audit-repo` → `specify-app`.
- `audit-repo` and `specify-app` clone nothing: they apply the rules the repository
  already holds under `docs/rules/`, because every task AUDIT checks the repository and
  its specifications against those rules. `specify-app` requires `docs/rules/specs.md`
  and `audit-repo` requires `docs/rules/standard.md`; both stop and direct the user to
  run `sync-rules` first when absent.
- Only procedures that are event-driven and hold no standing rule text are published as
  skills (`docs/adr/0004-publish-scaffolding-skills.md`,
  `docs/adr/0005-specification-criteria-and-specify-app.md`,
  `docs/adr/0006-rebuild-rules-and-selective-distribution.md`). Rule text stays in
  `dist/rules/`.

## Placement model (what consumers end up with)

- Rule bodies live only in `docs/rules/`, organized in three tiers:
  - **Application rules**: repository- and application-specific rules and overrides
  - **Stack rules**: distributed stack rule files (e.g., `dotnet.md`, `dotnet-client.md`)
  - **Shared rules**: the four universal files (`standard.md`, `documentation.md`,
    `specs.md`, `testing.md`), plus any conditional shared files distributed to the
    repository
  On conflict the more specific rule wins: Application rules > Stack rules > Shared
  rules. Every distributed universal file is read and applied to every change; a
  conditional shared or conditionally scoped stack file present in `docs/rules/` opens
  with `**Applies when**` and is skipped in multi-application repositories only for
  applications where its condition is false.
- `AGENTS.md` is the only router: repository facts, commands, the Applications table,
  the path to the code map (`docs/references/code-map.md`, never an inline table), and
  reading/AUDIT instructions.
- Scope rule for every docs category: directly under `docs/<category>/` =
  repository-wide; `<App>.md` or `<App>/` = application-specific.
- Managed vs. authored: distributed files under `docs/rules/` are never edited in
  consumers; application rules files, specifications, and code maps are
  repository-authored.

## Versioning contract

- Tags (`vMAJOR.MINOR.PATCH`) are the consumption interface; consumers pin a tag.
  Untagged `main` is never consumed.
- **MAJOR**: restructuring that breaks consumers — moved, renamed, or removed distributed
  files, changed or removed token names, a moved or renamed mapping file, or a changed
  mapping format (its `Mapping format` number increments).
- **MINOR**: new content — new rules, new conditional or stack rule files, new
  templates (with their new mapping rows), new mechanism markers, new tools and new
  capabilities of a tool, new published skills or capabilities of a published skill.
- **PATCH**: fixes and wording corrections, in distributed content and in the published
  skills alike.
- A change under `dist/` or `skills/` is consumable only once tagged. Changes outside
  both need no tag and ride along with the next release.

## Invariants

- Each stack's `dist/templates/<stack>/en/` and `ja/` express the same content.
- `dist/rules/` files are token-free and repository-agnostic.
- Shared rule files never contradict each other: each subject is stated in exactly one
  canonical rule file.
- Distributed bytes at a tag never change after the tag is published.
- Every file under `dist/templates/`, `dist/rules/`, and `dist/tools/` is named by
  `dist/templates/shared/rules-mapping.md` or a stack's `dist/templates/<stack>/mapping.md`,
  either as a source or as deliberately not generated. The coverage check in
  `docs/guides/release.md` confirms it.

## Out of scope

- Consumer-side tooling other than the published skills: how rule sync, scaffolding, or
  retrofit is invoked is the consumer's concern. The obligations any scaffolding
  implementation honors (rule distribution, optional files, code map) are stated in
  `docs/specs/template-requirements.md`, the shared rule catalog in
  `dist/templates/shared/rules-mapping.md`, and stack target paths in the stack's
  mapping file.
- Concrete per-repository commands — those live in each consuming repository's
  `AGENTS.md`.
