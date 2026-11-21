# Shared Rules Mapping

Mapping format: 1

The single catalog of all rule files distributed from `dist/rules/`. Both
`skills/sync-rules/` and stack scaffolding skills read this file from the tag they
apply, so rule lists never drift across skills. When a distributed file applies is
stated only in that file: each conditional shared file and each conditional stack file
opens with its `**Applies when**` paragraph, and tooling shows that paragraph, read from
the same tag, wherever it asks whether a file applies.

This file is read by tooling and never generated into a consuming repository (see **Not
generated**).

## Format

- **Mapping format** above versions this catalog's structure (sections, columns, and
  classification categories). Tooling written for a different number stops rather than
  guessing.
- **Source** paths are relative to the root of dev-standards. **Target** paths are
  relative to the root of the consuming repository.
- **Processing**: every rule file listed here and every optional starter file under
  **Shared starter files** is copied verbatim (byte-identical apart from configured
  working-tree line endings) with no front matter, no in-file marker, and no
  `{{TOKEN}}` replacement.

## Universal shared rules

Copied into every consuming repository regardless of stack or application features.

| Target | Source |
|---|---|
| `docs/rules/standard.md` | `dist/rules/standard.md` |
| `docs/rules/documentation.md` | `dist/rules/documentation.md` |
| `docs/rules/specs.md` | `dist/rules/specs.md` |
| `docs/rules/testing.md` | `dist/rules/testing.md` |

## Conditional shared rules

Copied selectively: a file is copied when the condition its opening `**Applies when**`
paragraph states holds for the repository, evaluated as a fact settled by the code and
deployment.

| Target | Source |
|---|---|
| `docs/rules/cli.md` | `dist/rules/cli.md` |
| `docs/rules/client.md` | `dist/rules/client.md` |
| `docs/rules/cloud.md` | `dist/rules/cloud.md` |
| `docs/rules/configuration.md` | `dist/rules/configuration.md` |
| `docs/rules/db.md` | `dist/rules/db.md` |
| `docs/rules/file-exchange.md` | `dist/rules/file-exchange.md` |
| `docs/rules/remote-calls.md` | `dist/rules/remote-calls.md` |
| `docs/rules/security.md` | `dist/rules/security.md` |
| `docs/rules/values.md` | `dist/rules/values.md` |
| `docs/rules/web-api.md` | `dist/rules/web-api.md` |

## Stack rules

Copied selectively for repositories built on the matching technology stack.

| Stack | Target | Source | Copied |
|---|---|---|---|
| .NET | `docs/rules/dotnet.md` | `dist/rules/dotnet.md` | always, for a .NET repository |
| .NET | `docs/rules/dotnet-client.md` | `dist/rules/dotnet-client.md` | when its opening `**Applies when**` paragraph holds |

## Shared starter files (optional)

Starter harness and router files for repositories without a stack template set, offered
by `sync-rules` during initial setup (never overwriting existing files). Stack template
sets reuse `CLAUDE.md`, `.claude/settings.json`, and `.codex/hooks.json` via their own
mapping while shipping a stack-specific router instead of `dist/templates/shared/AGENTS.md`.

| Target | Source | Notes |
|---|---|---|
| `AGENTS.md` | `dist/templates/shared/AGENTS.md` | Generic router template (contains `<PLACEHOLDER>` markers for the user to fill, alongside creating `docs/rules/<APP>.md`, `docs/specs/<APP>.md`, and `docs/references/code-map.md`) |
| `CLAUDE.md` | `dist/templates/shared/CLAUDE.md.tmpl` | One-line import `@AGENTS.md` |
| `.claude/settings.json` | `dist/templates/shared/settings.json.tmpl` | Claude Code session-start and pre-commit AUDIT hooks |
| `.codex/hooks.json` | `dist/templates/shared/hooks.json.tmpl` | Codex session-start and pre-commit AUDIT hooks |

## Not generated

Files under `dist/` cataloged here that are read by tooling and never generated into a
consuming repository.

| Source | Reason |
|---|---|
| `dist/templates/shared/rules-mapping.md` | this file — read by tooling, never generated |
