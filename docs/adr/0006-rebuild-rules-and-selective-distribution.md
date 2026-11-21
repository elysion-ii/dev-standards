---
status: accepted
supersedes: 0003-grow-rules-by-applicability-and-samples
---

# Rebuild Distributed Rules for Fresh-Reader Clarity and Selective Distribution

## Context

Growing `dist/rules/` piecemeal left four structural problems:

1. **Cross-file overlap and implicit scope**: `standard.md`, `documentation.md`, `testing.md`, and `dotnet.md` overlapped on error handling, file paths, logging, comments, and writing standards, while `standard.md` carried configuration-value rules and `dotnet.md` mixed portable .NET rules with Windows client packaging/XAML rules (`NATIVEDEP`, `XAML-VISIBILITY`).
2. **Unconditional distribution of domain rules**: Under ADR 0003, every conditional rule file was copied into every consuming repository regardless of whether the application used that domain. Expanding domain coverage to client packaging, configuration, security, external file exchange, precision values, outbound remote calls, Web APIs, and cloud storage would copy ten domain files into every simple console or desktop repository, burying applicable obligations under irrelevant files.
3. **Git workflow coupled to shared code standards**: `dist/rules/git.md` prescribed branching and pull-request workflow preferences alongside code and architecture rules, tying scaffolding obligations (such as host merge-strategy enforcement) to developer workflow preferences that vary across repositories and contributors.
4. **Coupled skill responsibilities**: `retrofit-dotnet-app` combined `.NET` template and build-gate convergence with `docs/rules/` synchronization and whole-repository rule auditing, leaving non-.NET repositories with no shared skill to initialize, update, or audit `docs/rules/`. Meanwhile, placing an inline `Shared Knowledge` table inside `AGENTS.md` duplicated repository-structure documentation inside every router file.

## Decision

- **Rebuild `dist/rules/` into a 16-file layered set**:
  - **Four universal shared files** (`standard.md`, `documentation.md`, `specs.md`, `testing.md`) distributed to every repository. Every requirement in `documentation.md` `Writing` and `Procedure Design` stands on its own without separate prose checklists, `documentation.md` moves the code map from `AGENTS.md` into `docs/references/code-map.md`, and `standard.md` carries a short ten-domain index (`Missing conditional rules`) requiring agents to report whenever a change introduces behavior in a domain whose conditional file is absent from `docs/rules/`.
  - **Ten conditional shared files** (`cli.md`, `client.md`, `cloud.md`, `configuration.md`, `db.md`, `file-exchange.md`, `remote-calls.md`, `security.md`, `values.md`, `web-api.md`), each opening with a factual `Applies when` boundary and cross-cutting only non-redundant domain ideals.
  - **Two .NET stack files** (`dotnet.md` for general .NET development, and `dotnet-client.md` for packaged Windows client applications where `client.md` applies), each opening with an honest enforcement matrix marking rules `Enforced` only when 100% mechanically guarded and keeping partial or manual rules `AUDIT` with both mechanical gates and manual checks explicitly distinguished.
- **Retire `dist/rules/git.md` from distribution**: Remove `git.md` from `dist/rules/`, router templates, and host-setting requirements (`H4` squash-only enforcement in `docs/specs/template-requirements.md`), leaving version-control workflow choices to each repository or contributor harness. (This retires the `git.md` distribution portion of ADR 0002 while preserving ADR 0002's prohibition against copying skills into consuming repositories.)
- **Adopt selective distribution via a single shared rules catalog (`dist/templates/shared/rules-mapping.md`)**:
  - Only the four universal shared files go to every repository unconditionally (`standard.md` indexes the ten conditional domains so subsequent feature work detects missing files reliably).
  - Conditional shared files and stack rule files are distributed selectively to repositories where they apply (based on app type and packaging defaults during scaffolding and explicit applicability checks during rule initialization or sync).
  - `dist/templates/shared/rules-mapping.md` (with its own `Mapping format` number) is the single source cataloging every file under `dist/rules/` plus optional shared starter files (`AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, `.codex/hooks.json`), so skills never duplicate rule lists or starter tables.
  - Note that existing repositories adopting the rebuilt contract retain any retired managed rule files (such as `git.md`) until synchronized with a newer tag.
- **Publish `skills/sync-rules/` and `skills/audit-repo/`, separate client packaging, and bump `.NET` scaffold mapping to `Mapping format: 2`**:
  - Publish `skills/sync-rules/` as a stack-agnostic operational skill focused solely on `docs/rules/` initialization, synchronization, retired-rule cleanup, and optional starter seeding from `dist/templates/shared/rules-mapping.md`.
  - Publish `skills/audit-repo/` as a stack-agnostic, offline operational skill that runs whole-repository `AUDIT` against local `docs/rules/` (and flags missing conditional rule domains per `standard.md`), separated from `sync-rules` so `.NET` retrofit (`docs/rules/<APP>.md` consolidation, docs layout, build gates) completes before whole-repo code auditing and mid-project rule syncs stay lightweight.
  - Separate installer artifacts (`build/Installer.ps1`, `build/Menu.bat`, `build/Setup_{{APP_NAME}}.iss`) into `## Client packaging` in `dist/templates/dotnet/mapping.md` (`Mapping format: 2`), writing the packaging-dependent text of `AGENTS.md` and `README.md` as conditional blocks inside the templates (so the generated text comes from the tag, not from the scaffolding tool), and having the router name the always-distributed rule files by path while referring to selectively distributed ones as the files under `docs/rules/` (an enumeration would go stale when `sync-rules` later adds or retires a file).
  - Narrow `skills/retrofit-dotnet-app/` (`Mapping format: 2`) to `.NET` templates, client-conditional packaging mechanisms, router/`code-map.md` migration, and staged build gates.
  - Keep `skills/init-dotnet-app/` (`Mapping format: 2`) one-shot ready for new `.NET` repositories by reading `rules-mapping.md` alongside `dist/templates/dotnet/mapping.md`.
  - Keep `dist/templates/dotnet/` packaging on self-contained side-by-side publish without `<PublishSingleFile>true</PublishSingleFile>`, aligning all four app types with `client.md` and `dotnet-client.md`.

## Alternatives Considered

- **Keep distributing all conditional rule files unconditionally to every repository** — rejected: copying ten conditional domain files plus multiple stack files into every minimal utility forces agents to read and classify irrelevant rule files on every task and inflates every consumer's `docs/rules/`.
- **Embed rule synchronization inside `retrofit-dotnet-app` only** — rejected: non-.NET repositories need a stack-agnostic way to initialize, update, retire, and audit `docs/rules/` without `.NET` build scripts or project templates.
- **Keep `git.md` inside `dist/rules/`** — rejected: Git branching and pull-request habits vary by team and personal harness setup, unlike architectural and defect-prevention engineering rules.
- **Separate repository-level guidelines for writing and procedure design outside `dist/rules/`** — rejected: keeping standalone writing quality and operational procedure design inside `documentation.md` (`Writing` and `Procedure Design`) makes every consumer repository self-contained under the blank-slate standard.

## Consequences

- `dist/rules/` grows from 8 files to 16 focused files while removing `dist/rules/git.md`.
- Consumers pin this change as a **MAJOR** release (`Mapping format` increments to `2` in `dist/templates/dotnet/mapping.md`, accompanied by `dist/templates/shared/rules-mapping.md` at format `1`, removed `dist/rules/git.md`, removed `<PublishSingleFile>` defaults, and separated `code-map.md`).
- Existing `.NET` repositories upgrade cleanly in sequence: `sync-rules` (sync/retire rules) → `retrofit-dotnet-app` (converge templates, `code-map.md`, client packaging where applicable, and staged gates) → `audit-repo` (whole-repo `AUDIT` and missing-domain check) → `specify-app` (bring specifications to `specs.md` completeness).
- Non-.NET repositories adopt `sync-rules` → `audit-repo` → `specify-app`.
- Every new file added under `dist/rules/` must register in `dist/templates/shared/rules-mapping.md`, and the release coverage check verifies both `dist/templates/shared/rules-mapping.md` and `dist/templates/*/mapping.md`.

## Revisit When

- A second stack template set is added (`dist/templates/<stack>/`): evaluate whether `.NET`-specific scaffolding/retrofit skills remain per-stack alongside stack-agnostic `sync-rules` or generalize across stacks.
- Automated Roslyn analyzers reliably cover currently `AUDIT`-only rules (e.g., `ORG` one-top-level-type-per-file or `VAR` exact right-hand-type checks) without noisy false positives or third-party supply-chain burden, allowing rows in `dotnet.md` to advance to `Enforced`.
- Selective distribution causes conditional rules to be omitted when applications quietly cross a domain boundary (e.g., adding database access later without adding `db.md`), making periodic domain re-checks in `sync-rules` insufficient.
