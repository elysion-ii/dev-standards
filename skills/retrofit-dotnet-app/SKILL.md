---
name: retrofit-dotnet-app
description: Converge an existing .NET repository's scaffolding, build/installer mechanisms, AGENTS.md router (with concrete distributed rule paths), code map, and staged build gates onto the current dev-standards tag. Clones the tag, derives the target state from `dist/templates/dotnet/mapping.md` (applying Client packaging mechanisms only to packaged client apps), diffs mechanisms against the working tree, ports missing gates cleanly, and migrates shared knowledge to `docs/references/code-map.md`. Delegates `docs/rules/` synchronization to `sync-rules` and whole-repo code auditing to `audit-repo`, and names `specify-app` when the specification does not meet `specs.md`. Run from the project's repo root; network required. Use when the user says "retrofit this project", "apply the new gates to this project", or "bring this old project up to the current template".
allowed-tools: AskUserQuestion, Read, Write, Edit, Glob, Grep, Bash
---

# retrofit-dotnet-app

One goal: converge an existing .NET repository's scaffolding, mechanisms, documentation layout, router, and build gates onto the newest `dev-standards` tag (`dist/templates/dotnet/mapping.md`).

This skill owns **.NET templates, build/installer scripts (when client packaging applies), mechanism ports, router/`code-map.md` migration, documentation layout, and staged build gates**. It does **not** manage distributed files under `docs/rules/` (`sync-rules`) or run whole-repository rule auditing (`audit-repo`). Recommended upgrade sequence for an existing `.NET` repository:

1. `/sync-rules` (synchronize `docs/rules/`, add newly applicable conditional rules, retire obsolete managed rules)
2. `/retrofit-dotnet-app` (this skill — converge `.NET` mechanisms, router, `code-map.md`, docs tree, and staged gates)
3. `/audit-repo` (run the whole-repository `AUDIT` gate against the converged rules and gates)
4. `/specify-app` (when `docs/specs/<APP>.md` does not yet meet `docs/rules/specs.md`)

```
STANDARDS_REPO       = https://github.com/elysion-ii/dev-standards.git
STANDARDS_TAG        = the newest semver tag on the remote, resolved in Phase 2
MAPPING              = <STD>/dist/templates/dotnet/mapping.md
MAPPING_FORMAT       = 2   (the .NET mapping format this copy of the skill is written for)
RULES_MAPPING        = <STD>/dist/templates/shared/rules-mapping.md
RULES_MAPPING_FORMAT = 1   (the shared rules mapping format used for the prerequisite check)
```

This skill carries no list of target paths and no mechanism markers. Both are read from `MAPPING` in the clone, so the target state always matches the templates of the tag being applied.

The skill is idempotent: every action checks whether it is already applied and skips if so, so it can be re-run after a partial application.

**Never touch `core.hooksPath`** — globally or per-repository. The user's own hook setup may live there; a repository-local `core.hooksPath` (husky, lefthook, etc.) silently disables it.

**No commits.** Steps may stage changes as a side effect (`git mv`, `git rm`); the run ends with the index normalized and a proposed commit split — the user decides.

### Question round conventions

Batch questions with `AskUserQuestion`, up to 4 per call, repeating calls until every open item is resolved. Mark a recommended option when one exists. Ask only what is genuinely undecidable from the repository and the clone — a round with nothing to ask is skipped. Never silently resolve an item that was marked for asking.

---

## Phase 1: Context

1. **Identify the app and packaging scope.**
   - Find `*.slnx` (or `*.sln`) in the repo root; derive `<APP>` from its name. If none exists, stop and report. Confirmation: `<APP>` names an existing csproj directory.
   - Determine **`clientPackaging`** (`true` / `false`):
     - `true` if `docs/rules/client.md` or `docs/rules/dotnet-client.md` is present, or `build/Setup_*.iss` / `build/Installer.ps1` exists, or the `.csproj` builds a WPF, WinUI 3, or Win32 GUI application.
     - `false` if the project builds an ASP.NET/Web API server application (`Microsoft.NET.Sdk.Web`) or clearly non-packaged CLI/worker without `client.md`/`Setup_*.iss`.
     - If ambiguous (e.g., Windows-targeting Console tool with no installer files yet), add `clientPackaging` confirmation to Question Round 1.
2. **Detect the rules language** (`{lang}` ∈ `en` / `ja`) from the root `AGENTS.md` if present, otherwise from existing rule files. Confirmation: a language was chosen; if genuinely undetectable, add it to Question Round 1.
3. **Check the working tree.** Run `git status`. If dirty, add "proceed anyway?" to Question Round 1 — retrofit changes should not mix with unrelated edits. An untracked `./.dev-standards` is not project dirt: it is a clone left by an aborted earlier run, and Phase 2 removes it.
4. **Question Round 1** (only if any of the above raised an item): app identifier, `clientPackaging`, language, dirty tree.

---

## Phase 2: Target state and rule-sync check

1. **Resolve `<STANDARDS_TAG>`** — the newest `v*` tag on the remote, in semver order:

   ```bash
   git ls-remote --tags --refs --sort=-v:refname <STANDARDS_REPO> 'v*' | head -1 | sed 's#.*refs/tags/##'
   ```

   Confirmation: prints one tag name. If it prints nothing, STOP and report — never converge from memory.

2. **Clone that tag** into **`./.dev-standards`** inside the invocation directory (= repo root):

   ```bash
   test -e .dev-standards && rm -rf .dev-standards
   git clone --depth 1 --branch <STANDARDS_TAG> <STANDARDS_REPO> .dev-standards
   ```

   Confirmation: `git -C .dev-standards rev-parse --show-toplevel` resolves inside the invocation directory. `<STD>` refers to `./.dev-standards`. If cloning fails, STOP and report.

3. **Check mapping formats.** Read `MAPPING` and `RULES_MAPPING` in full. Confirmation: `MAPPING` states `Mapping format: <MAPPING_FORMAT>` and `RULES_MAPPING` states `Mapping format: <RULES_MAPPING_FORMAT>`. If either is missing or states another number, STOP (deleting `.dev-standards`) and report that this skill requires `.NET` mapping format `<MAPPING_FORMAT>` and rules mapping format `<RULES_MAPPING_FORMAT>`, and must be re-copied from `<STANDARDS_TAG>` (`skills/retrofit-dotnet-app/`). Do not interpret a mapping of another format.

4. **Check `docs/rules/` synchronization prerequisite.** Compare local `docs/rules/` against `RULES_MAPPING`:
   - Check whether all **Universal shared rules** and the `.NET` core stack rule from `RULES_MAPPING` exist locally and match `<STD>/<Source>` (and if `clientPackaging = true`, whether `client.md` and `dotnet-client.md` match `<STD>/<Source>`), and whether every other managed rule filename from `RULES_MAPPING` that exists in `docs/rules/` matches `<STD>/<Source>` (note any stale or unrecognized `.md` file in `docs/rules/` outside `docs/rules/<APP>.md`).
   - If `docs/rules/` is missing required rules, out of date, or holds files outside `RULES_MAPPING` and `<APP>.md`: warn the user and ask via `AskUserQuestion`:
     - **Stop now and run `/sync-rules` first (Recommended)** — delete `./.dev-standards` (`rm -rf .dev-standards`) and stop cleanly so the user runs `/sync-rules` before returning to `/retrofit-dotnet-app`.
     - **Proceed with template/gate convergence only** — continue Phase 3–6 against `<STANDARDS_TAG>` and run `/sync-rules` immediately afterwards.

5. **Build the target list.** Instantiate template rows of `MAPPING`:
   - **Always generated**
   - **Client packaging** ONLY when `clientPackaging = true` (omit `Installer.ps1`, `Menu.bat`, `Setup_{{APP_NAME}}.iss` completely when `clientPackaging = false`)
   - **Type-specific entry points** for the detected app type
   - **Optional** (README/LICENSE if already present or requested)
   with this project's facts (`<APP>` for `{{APP_NAME}}`, TFM from existing `.csproj`, `{lang}`, `{ilang}` when `clientPackaging = true`). Confirmation: every file under `<STD>/dist/templates/` (outside `dist/templates/shared/rules-mapping.md`) and `<STD>/dist/tools/` is accounted for by `MAPPING`.

6. **Partition the target list by scope.** Every row of `MAPPING` carries its **Retrofit class**:

   | Class | Reconcile action |
   |---|---|
   | mechanism | port or add (Phase 3.1) |
   | authored | ensure-exists / migrate in Phase 5 (`app-rules`, `spec`, `code-map.md`) |
   | substance | **no template diff, no overwrite** (`audit-repo` audits code once convergence completes) |

---

## Phase 3: Diff and classify

### 3.1 Forward pass — every in-scope template target gets exactly one state

- **missing** — the `mechanism` path does not exist → plan: *add* (token-substituted).
- **current** — all mechanism markers in `MAPPING` (excluding `(Client packaging only)` rows when `clientPackaging = false`) are present → plan: *skip*.
- **diverged** — a `mechanism` file is missing one or more markers, or has non-obvious customization → plan: *port mechanism* (when the **Mechanism markers** row gives an unambiguous port) or *ask* (show diff in Question Round 2).

Follow the special rules in **Mechanism markers** (`<TreatWarningsAsErrors>` stays off until Phase 6; `BannedApiAnalyzers` / REQCOV / line-ending changes follow their staged/report notes; `AGENTS.md` reshape, `CLAUDE.md` rewrite, and `code-map.md` migration happen in Phase 5).

### 3.2 Reverse pass — nothing unexplained remains

Scan the scaffolding territory: root-level agent/config files (`CLAUDE.md` with a body, `GEMINI.md`, stray `*.md` routers), `.claude/**`, `.codex/**`, `.agents/**`, `build/**`. Anything found there that the selected `MAPPING` scope does not generate, and that is not evidently the project's own work, goes on the Question Round 2 list with options: **retire** (`git rm`), **keep** (project-specific), or **migrate content, then retire**. Leave `docs/rules/**` to `sync-rules` (note any unexpected files there in the report rather than deleting managed rules here).

(`docs/` outside `docs/rules/` is converged in Phase 5 against `documentation.md`.)

### 3.3 Present and ask

Present the reconciliation plan table (`Path` / `State` / `Planned Action`), noting `clientPackaging` state (`true`/`false`), `substance` targets excluded from template diffing, and `docs/rules/` ownership by `sync-rules`. Run **Question Round 2** for every *ask* item. Do not start Phase 4 while any item is unresolved.

---

## Phase 4: Converge scaffolding

Execute the approved plan, in this order: adds → mechanism ports → retirements (`git rm` / `git rm -r`) → settings merges.

**Confirmation (completeness check):** re-run Phase 3.1 forward pass. Every in-scope `mechanism` target must now be *current* (with router/code-map items queued cleanly for Phase 5) or covered by an explicit user decision from Round 2.

---

## Phase 5: Consolidate content

Judgment work — each step reads its governing rule file first (`docs/rules/` if synced, or `<STD>/dist/rules/` for the rules being targeted), asks when debatable.

1. **Rule text → `docs/rules/<APP>.md`, router, and Code Map (`docs/references/code-map.md`).**
   - Generate `docs/rules/<APP>.md` from `{lang}/app-rules.md.tmpl` (`{{DATE}}` = `date +%F`) if missing, then merge every rule found in legacy stores (`.claude/CLAUDE.md`, `.claude/rules/*.md`, pre-existing root `CLAUDE.md`/`AGENTS.md` body), classifying each:
     - covered by the shared/stack rules → drop
     - conflicts with shared/stack rules (deliberate override) → carry over cleanly
     - facts/commands → keep in `AGENTS.md`
     - repository-specific rule → carry over intact
   - Ensure `docs/references/code-map.md` exists (generate from `{lang}/code-map.md.tmpl` if missing). If an existing `AGENTS.md` has an inline `## Shared Knowledge` (or entry-point) table, judge every row against `standard.md` (One Home per Piece of Knowledge) and `documentation.md` (Code Map): migrate valid feature-folder and shared-mechanism rows into `docs/references/code-map.md`, omit single-type non-mechanism rows, and report duplicated knowledge rather than listing it.
   - Compose `AGENTS.md` per `{lang}/AGENTS.md.tmpl` with real project values, filled Applications table, `## Code Map` pointing to `docs/references/code-map.md` (no inline table, no rule text), and the template text processed as **Processing** in `MAPPING` defines (conditional blocks by `clientPackaging`, then tokens) — no conditional-block marker or token remains; write `CLAUDE.md` as `@AGENTS.md`; remove emptied legacy stores per Round 2 decisions.
   - Confirmation: no rule text, no inline code map table, no enumeration of selectively distributed rule files, and no conditional-block marker or token remain in `AGENTS.md`.

2. **Specification.** Ensure `docs/specs/<APP>.md` exists (generate `{lang}/spec.md.tmpl`, filling Purpose/Scope from README/`AGENTS.md`; pair existing spec under another name in Applications table or rename with `git mv` after asking).
   Judge whether `docs/specs/<APP>.md` meets `specs.md` for every decision of `<APP>` — every applicable question answered by a requirement or recorded in the ledgers (`specs.md`, Questions and Ledgers). If any decision lacks complete answers (including a skeleton), record the negative judgment with a concrete decision/question example and name `/specify-app` in the report.

3. **Docs tree → `documentation.md`.** Converge `adr/` → `docs/adr/` (`git mv`), ADR filenames to `NNNN-description.md`, loose `docs/*.md` into role subfolders, plan folders to `docs/plans/` + `docs/archive/plans/` with matching `.gitignore` entries, front matter (`status` + `created`, and ADRs `status` only without `created`), and update path references across `AGENTS.md`, `docs/`, `README.md`, and code comments. Confirmation: every `docs/` document sits in a role folder with valid front matter.

4. **Version single-sourcing.** Skip (with report note) when `clientPackaging = false` and the project has neither `build/Installer.ps1` nor `build/Setup_*.iss`. Collect every `<Version>` (`Directory.Build.props`, `.csproj`) and `#define MyAppVersion` (`.iss`). If values disagree, STOP and ask which is correct. Ensure `<Version>` stays solely in `Directory.Build.props`, port Installer/ISS injection guards, check `CHANGELOG.md` gate readiness, and run `build/Installer.ps1` if `build/<APP>/<APP>.exe` exists.

---

## Phase 6: Staged gates

1. **Format.** `dotnet format <APP>.slnx`, then confirm `dotnet format <APP>.slnx --verify-no-changes` exits 0.
2. **Measure, then enable.** `dotnet build <APP>.slnx -c Release`; tally warnings by diagnostic ID (including `VSTHRD*` and `IDE0130`).
   - Zero warnings → add `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` (with template comment) to `Directory.Build.props`, rebuild, confirm exit 0.
   - Warnings remain → do NOT enable the gate. Report ID / count / representative location / suggested handling (fix vs narrowest-scope suppression per `dotnet.md` `ANALYZERS`).
3. **Tests.** `dotnet test` — confirm existing tests pass (exit 0).

---

## Phase 7: Report and cleanup

First run `git reset` (index only — working tree untouched) so incidental staging from `git mv` / `git rm` is cleared before user commit review.

Delete the clone:

```bash
rm -rf .dev-standards
```

Confirmation: `test -e .dev-standards` is false. Mandatory so untracked clone files are never committed into the project.

Report:

- Resolved tag (`<STANDARDS_TAG>`), detected `clientPackaging` mode (`true`/`false`), and `docs/rules/` synchronization status
- Reconciliation table with final outcomes (added / ported / retired / kept / deferred) and Phase 4 completeness check
- Consolidation and Code Map migration outcomes (legacy rules dropped/kept, migrated `code-map.md` rows, reported knowledge duplicates)
- Phase 6 verification results with exit codes and `<TreatWarningsAsErrors>` status
- Any special reports requested by `MAPPING` (e.g., working-tree line-ending re-checkout instructions if `.gitattributes`/`.editorconfig` changed, `BannedApiAnalyzers` RS0030 findings, staged REQCOV gaps)
- Next steps (in order):
  1. Run `/sync-rules` first if `docs/rules/` was not yet synchronized before this run
  2. Run **`/audit-repo`** next (now that `docs/rules/`, `docs/rules/<APP>.md`, `code-map.md`, `docs/`, and build gates are converged) to audit existing code, tests, and documents against `<STANDARDS_TAG>` rules
  3. Run **`/specify-app`** after committing if Phase 5 step 2 judged `docs/specs/<APP>.md` incomplete under `docs/rules/specs.md`
- Proposed commit split (do NOT commit until user confirms):
  1. Mechanism introduction (`.editorconfig`, `Directory.Build.props`, `BannedSymbols.txt`, build scripts, hooks, and installer scripts if `clientPackaging = true`)
  2. Router, Code Map, and rule consolidation (`AGENTS.md`, `CLAUDE.md`, `docs/references/code-map.md`, `docs/rules/<APP>.md`, `docs/specs/<APP>.md`, legacy removals)
  3. Mechanical bulk formatting changes (`dotnet format` diff)
  4. Documentation placement (moves, renames, front matter, path reference updates)
