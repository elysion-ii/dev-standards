---
name: retrofit-dotnet-app
description: Converge an existing .NET repository onto the current dev-standards tag. Clones the tag, derives the target state from the scaffold mapping in that tag (dist/templates/dotnet/mapping.md, the same mapping init-dotnet-app generates from), diffs it against the working tree, and closes the gap interactively — missing scaffolding is added, stale dev-standards-managed rules are updated, template-carried mechanisms (format gate, static analysis, version single-sourcing, hooks) are ported into existing files, and anything that cannot be attributed to either the template or the project is resolved by asking, in batched question rounds like init-dotnet-app. Risky gates are staged (measure → report → enable); existing files are never overwritten without approval. Run from the project's repo root; network required. Use when the user says "retrofit this project", "apply the new gates to this project", or "bring this old project up to the current template".
allowed-tools: AskUserQuestion, Read, Write, Edit, Glob, Grep, Bash
---

# retrofit-dotnet-app

One goal: after the run, the repository contains everything `init-dotnet-app` at the tag
below would have generated for this project — plus the project's own code and documents,
and **nothing unexplained in between**. The whole procedure is a diff between that target
state and the working tree:

- the target has it, the project lacks it → **add**
- the project has it in an older distributed form → **update**
- the project has it with the template's mechanism missing → **port the mechanism**
- the project has something the target does not generate → it is either the project's own
  work (**keep**) or leftover scaffolding from an older template era (**retire**) — and
  when the attribution is unclear, **ask**. Never guess, and never rely on a memorized
  list of historical artifacts: the user supplies that knowledge through the question
  rounds.

```
STANDARDS_REPO = https://github.com/elysion-ii/dev-standards.git
STANDARDS_TAG  = the newest semver tag on the remote, resolved in Phase 2
MAPPING        = <STD>/dist/templates/dotnet/mapping.md
MAPPING_FORMAT = 1   (the mapping format this copy of the skill is written for)
```

This skill carries no list of target paths and no mechanism markers. Both are read from
`MAPPING` in the clone — the same file `init-dotnet-app` generates from — so the target
state always matches the templates of the tag being applied.

The skill is idempotent: every action checks whether it is already applied and skips if
so, so it can be re-run after a partial application.

**Never touch `core.hooksPath`** — globally or per-repository. The user's own hook setup
may live there; a repository-local `core.hooksPath` (husky, lefthook, etc.) silently
disables it. Enforcement belongs in server-side settings, analyzers, and build gates.

**No commits.** Steps may stage changes as a side effect (`git mv`, `git rm`); the run
ends with the index normalized and a proposed commit split — the user decides.

### Question round conventions

Like init-dotnet-app: batch questions with `AskUserQuestion`, up to 4 per call, repeating
calls until every open item is resolved. Mark a recommended option when one exists. Ask
only what is genuinely undecidable from the repository and the clone — a round with
nothing to ask is skipped. Never silently resolve an item that was marked for asking.

---

## Phase 1: Context

1. **Identify the app.** Find `*.slnx` (or `*.sln`) in the repo root; derive `<APP>` from
   its name. If none exists, stop and report. Confirmation: `<APP>` names an existing
   csproj directory.
2. **Detect the rules language** (`{lang}` ∈ `en` / `ja`) from the root `AGENTS.md` if
   present, otherwise from existing rule files. Confirmation: a language was chosen; if
   genuinely undetectable, add it to Question Round 1.
3. **Check the working tree.** Run `git status`. If dirty, add "proceed anyway?" to
   Question Round 1 — retrofit changes should not mix with unrelated edits. An untracked
   `./.dev-standards` is not project dirt: it is a clone left by an aborted earlier run,
   and Phase 2 removes it.
4. **Question Round 1** (only if any of the above raised an item): app identifier,
   language, dirty tree.

## Phase 2: Target state

1. **Resolve `<STANDARDS_TAG>`** — the newest `v*` tag on the remote, in semver order:

   ```bash
   git ls-remote --tags --refs --sort=-v:refname <STANDARDS_REPO> 'v*' | head -1 | sed 's#.*refs/tags/##'
   ```

   Confirmation: the command prints one tag name. If it prints nothing, STOP and report —
   a tag taken from memory converges the project onto rules that are silently out of
   date, which reads as success and is not.

2. **Clone that tag** into **`./.dev-standards`** — inside the invocation directory, never
   anywhere else. The invocation directory is where the harness was started and where this
   skill runs (= the project's repo root), so the path stays relative to it and every
   worker and every harness puts the clone in the same place. Full clone — tag history is
   used in Phase 3 to recognize older distributed files:

   ```bash
   test -e .dev-standards && rm -rf .dev-standards        # leftover from an aborted run
   git clone --branch <STANDARDS_TAG> <STANDARDS_REPO> .dev-standards
   ```

   Do **not** clone into a temp directory, the home directory, a sibling directory, or any
   absolute path — and do not reuse a clone that already sits outside the invocation
   directory, however current it looks. Confirmation:
   `git -C .dev-standards rev-parse --show-toplevel` resolves inside the invocation
   directory.

   `<STD>` below is this clone (`./.dev-standards`). If the clone fails, STOP and report —
   never retrofit from memory. The clone is untracked and nothing ignores it, so Phase 7
   deletes it; if the run stops early, delete it at the abort point. The final report names
   the resolved tag, so the run states which version it converged onto.

   Read `MAPPING` in full. Confirmation: it exists and states
   `Mapping format: <MAPPING_FORMAT>`. If it is missing or states another number, STOP
   (deleting the clone) and report: this copy of the skill was written for mapping format
   `<MAPPING_FORMAT>`, and the user obtains the skills again from `<STANDARDS_TAG>` (the
   `skills/` directory of that tag) before re-running. Do not interpret a mapping of
   another format.

3. **Build the target list.** Instantiate every row of `MAPPING` that names a target
   (**Always generated**, **Type-specific entry points**, **Optional**, **Distributed
   rules**) with this project's facts: `<APP>` for `{{APP_NAME}}`, app type and TFM from
   the existing csproj (selecting `{type}` and the entry-point rows), `{lang}`, and the
   other placeholders `MAPPING` defines, taken from the project's existing files (add any
   that is genuinely undetectable to Question Round 2). Confirmation: every file under
   `<STD>/dist/templates/` and `<STD>/dist/rules/` is either on the target list, listed
   under **Not generated** in `MAPPING`, or consciously excluded by the scope rule below.

4. **Partition the target list by scope.** Retrofit converges *scaffolding*, never the
   application's substance. Every row of `MAPPING` carries its **Retrofit class**; the
   class decides the reconcile action:

   | Class | Reconcile action |
   |---|---|
   | managed rule | byte-sync (Phase 3.1) |
   | mechanism | port (Phase 3.1) |
   | authored pair | ensure-exists (Phase 5) |
   | substance | **out of scope — never diffed, never overwritten** |

## Phase 3: Diff and classify

### 3.1 Forward pass — every in-scope target gets exactly one state

- **missing** — the path does not exist → plan: *add* (verbatim for managed rules;
  token-substituted per init's derived-values rules for templates).
- **current** — byte-identical to the tag (managed rules), or the mechanism markers
  all present (mechanisms) → plan: *skip*.
- **stale** — a managed rules file that differs from the current tag but byte-matches
  that file in some older tag (`git -C <STD> tag` then compare against
  `git -C <STD> show <tag>:dist/rules/<file>`) → plan: *update* (overwrite; the tag is
  the source of truth).
- **diverged** — differs and matches no tag (managed rules: locally edited), or a
  mechanism file whose reconciliation is not obvious → plan: *ask* (show the diff in
  Question Round 2).

Mechanism markers are the **Mechanism markers** section of `MAPPING`: for each mechanism
file, a marker that shows the mechanism is already applied, and the port source to apply
when it is absent — port the template's block into the existing file, preserving
project-specific content around it, and follow the special rules a row states. The
`AGENTS.md` reshape and the `CLAUDE.md` rewrite those rows call for happen in Phase 5,
after rule text is consolidated; `<TreatWarningsAsErrors>` is enabled only by Phase 6.

### 3.2 Reverse pass — nothing unexplained remains

Scan the territory the template family owns: root-level agent/config files (`CLAUDE.md`
with a body, `GEMINI.md`, stray `*.md` routers), `.claude/**`, `.codex/**`, `.agents/**`,
`build/**`, `docs/rules/**`. Anything found there that the target state does not
generate, and that is not evidently the project's own work, goes on the Question Round 2
list with options: **retire** (leftover scaffolding — `git rm`), **keep**
(project-specific), or **migrate content, then retire** (its rule/doc content is merged
in Phase 5 before removal). Do not decide from memory which artifacts old templates used
to distribute — that is exactly what the question is for.

(The `docs/` tree outside `docs/rules/` is converged in Phase 5 against
`documentation.md`, not here.)

### 3.3 Present and ask

Present the full reconciliation plan as a table — path / state / planned action — with
out-of-scope substance listed once as excluded. Then run **Question Round 2** for every
*ask* item. Do not start Phase 4 while any item is unresolved.

## Phase 4: Converge scaffolding

Execute the approved plan, in this order: adds → updates → mechanism ports → retirements
(`git rm` / `git rm -r`) → settings merges. Then, if the repository has a GitHub
`origin`, enforce squash-only merges (skip if already set):

```bash
gh repo edit --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
```

If there is no remote or the command fails, list the command in the report instead.

**Confirmation (completeness check):** re-run the Phase 3.1 forward pass. Every in-scope
target must now be *current*, or covered by an explicit user decision from Round 2. A
target still *missing*/*stale*/*diverged* without a decision means the convergence is
incomplete — fix it before moving on.

## Phase 5: Consolidate content

Judgment work — each step reads its governing rule file first, asks when debatable.

1. **Rule text → `docs/rules/<APP>.md`.** Generate from `{lang}/app-rules.md.tmpl`
   (`{{DATE}}` = `date +%F`) if missing, then merge every rule found in legacy stores
   (`.claude/CLAUDE.md`, `.claude/rules/*.md`, a pre-existing root `CLAUDE.md`/`AGENTS.md`
   body), classifying each:
   - covered by the shared rules (same meaning in `<STD>/dist/rules/*.md`) → drop
   - conflicts with the shared rules (the repository deliberately differs) → carry over
     as an explicit override (repository wins — say so)
   - facts/commands, not rules → belongs in `AGENTS.md`, keep the repository's wording
   - repository-specific rule matching nothing in dev-standards → carry over intact

   Then finish the Phase 3 router work: compose `AGENTS.md` per `{lang}/AGENTS.md.tmpl`
   with real project values and a filled Applications table; write `CLAUDE.md` as exactly
   `@AGENTS.md`; remove the emptied legacy stores per their Round 2 decisions.
   Confirmation: no rule text exists outside `docs/rules/`.

2. **Specification.** Ensure `docs/specs/<APP>.md` exists: generate the skeleton from
   `{lang}/spec.md.tmpl`, filling Purpose/Scope from README/`AGENTS.md`; the rest is
   backfilled incrementally by future changes, never as a retrofit precondition. If a
   specification already exists under another name, pair it in the Applications table
   instead (rename to the `<APP>` identifier with `git mv`, after asking).

3. **Docs tree → `documentation.md`.** Read the distributed `documentation.md`, then
   converge: `adr/` → `docs/adr/` (`git mv`; both existing → ask how to merge), ADR
   filenames to `NNNN-description.md` (creation order via
   `git log --follow --diff-filter=A`), loose `docs/*.md` into role subfolders per the
   decision table (ask on debatable classifications and well-known names), plan folders
   to `docs/plans/` + `docs/archive/plans/` with the matching `.gitignore` entries
   (untrack in-progress plans with `git rm --cached`; previously committed archived plans
   stay tracked unless the user says otherwise), front matter added where missing
   (`status` + `created`; ADRs carry `status` only — remove `created` from ADRs; never
   overwrite existing values; use `date +%F` as `created`, not reconstructed history).
   Rewrite path references (`AGENTS.md`, `docs/`, README, source comments) for everything
   moved. Confirmation: every `docs/` document sits in a role folder and carries front
   matter.

4. **Version single-sourcing.** Skip (with a report note) if the project has neither
   `build/Installer.ps1` nor `build/Setup_*.iss`. Collect every version definition —
   `<Version>` in csprojs and `Directory.Build.props`, `#define MyAppVersion` in the
   `.iss`. If the values disagree, STOP and ask which is correct — the drift this
   mechanism prevents may already have happened. Then: `<Version>` lives only in
   `Directory.Build.props`; the Installer/iss mechanism ports from Phase 3.1 make the
   build fail without injection; if `CHANGELOG.md` exists but lacks a heading for the
   current version, report it. Confirmation: if `build/<APP>/<APP>.exe` exists, run
   `build/Installer.ps1` — it prints the props version and completes or stops only at the
   CHANGELOG gate; otherwise state that end-to-end verification still needs a build.

## Phase 6: Staged gates

1. **Format.** `dotnet format <APP>.slnx`, then confirm
   `dotnet format <APP>.slnx --verify-no-changes` exits 0.
2. **Measure, then enable.** `dotnet build <APP>.slnx -c Release`; tally warnings by
   diagnostic ID (including `VSTHRD*`).
   - Zero warnings → add `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` (with the
     template's comment) to `Directory.Build.props`, rebuild, confirm success.
   - Warnings remain → do NOT enable the gate. Report ID / count / representative
     location / suggested handling (fix vs suppress per the ANALYZERS tiers in
     `docs/rules/dotnet.md`) and leave the gate for a re-run after the user decides.
3. **Tests.** `dotnet test` — existing tests still pass.

## Phase 7: Report

First run `git reset` (index only — the working tree is untouched): some steps stage as
a side effect while Write/Edit steps do not, and the commit split below — not incidental
staging — should be what puts things into the index.

Report:

- The reconciliation table with final outcomes, including every Round 2 decision
  (added / updated / ported / retired / kept / deferred)
- The completeness-check result: no in-scope target left unexplained
- Consolidation outcomes: rules dropped as covered, overrides, repository-specific
  carries, anything awaiting a decision
- Verification results with exit codes (format verify, build, tests, installer if run)
- Gate status: enabled, or the warning table awaiting decisions
- Proposed commit split (do not commit until the user confirms):
  1. Mechanism introduction (config, props, build scripts, installer, merge settings)
  2. Rule consolidation (`AGENTS.md`, `CLAUDE.md`, `docs/rules/` + `docs/specs/`,
     legacy-store removals and retirements)
  3. Mechanical bulk changes only (the `dotnet format` diff)
  4. Documentation placement (moves, renames, reference rewrites, front matter)

Delete the clone:

```bash
rm -rf .dev-standards
```

Confirmation: `test -e .dev-standards` is false. Mandatory, not tidiness — the clone is
untracked and nothing ignores it, so the proposed commit split above would otherwise sweep
the whole template repository into the project.
