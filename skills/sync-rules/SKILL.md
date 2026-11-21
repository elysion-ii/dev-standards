---
name: sync-rules
description: Initialize or synchronize dev-standards rules (`docs/rules/`) in any repository. Clones the newest tag of `elysion-ii/dev-standards` (network required), reads the shared rule catalog (`dist/templates/shared/rules-mapping.md`), selects universal, conditional, and stack rules for the repository, adds missing rules in fresh or existing repositories, updates stale managed rules, prompts to retire obsolete rules (such as retired `git.md`), and optionally seeds starter router/hook files defined in `rules-mapping.md`. Stack-agnostic; use on a new repository to pull initial rules, on any repository when updating dev-standards rules or adopting new domains, or before running `retrofit-dotnet-app` and `audit-repo`.
allowed-tools: AskUserQuestion, Read, Write, Edit, Glob, Grep, Bash
---

# sync-rules

Synchronize dev-standards-managed rules under `docs/rules/` for **both** fresh/uninitialized repositories (fetching initial rules from the newest tag) and existing repositories (bringing `docs/rules/` onto the newest tag, adding newly applicable conditional or stack rules, and retiring obsolete managed rules).

This skill is **stack-agnostic** and focuses solely on `docs/rules/` synchronization (plus optional generic starter setup on uninitialized non-stack repositories). Whole-repository code auditing lives in the sibling skill **`audit-repo`** (`skills/audit-repo/`). Recommended upgrade sequence for an existing repository:
- `.NET` repositories: `/sync-rules` → `/retrofit-dotnet-app` → `/audit-repo` → `/specify-app`
- Non-.NET repositories: `/sync-rules` → `/audit-repo` → `/specify-app`

```
STANDARDS_REPO       = https://github.com/elysion-ii/dev-standards.git
STANDARDS_TAG        = the newest semver tag on the remote, resolved in Phase 2
RULES_MAPPING        = <STD>/dist/templates/shared/rules-mapping.md
RULES_MAPPING_FORMAT = 1   (the mapping format this copy of the skill is written for)
```

This skill carries no static rule list or template path table of its own. Every distributed rule file, its category, and every optional shared starter file come from `RULES_MAPPING` in the cloned tag; when a file applies comes from the opening `**Applies when**` paragraph of that file in the same clone.

The skill is idempotent: unchanged current rules are skipped, locally edited managed rules require explicit user confirmation before overwriting, and repository-authored rules (`docs/rules/<App>.md` or custom files matching no tag history) stay untouched.

**Never touch `core.hooksPath`** — globally or per-repository.

**No commits.** Steps may stage removals (`git rm`) when retiring obsolete rules; Phase 5 resets the index and proposes a commit split for the user to approve.

### Question round conventions

Batch questions with `AskUserQuestion`, up to 4 per call, repeating calls until every open item is resolved. Mark a recommended option when one exists. Ask only what cannot be settled from the repository and `RULES_MAPPING`. Never silently resolve an item marked for asking.

---

## Phase 1: Context

1. **Detect repository state and mode.**
   - Run `git status` (if `.git` exists; if invoked in a brand-new folder before `git init`, treat the repository as fresh with no git history yet).
   - If the working tree is dirty (excluding a leftover `./.dev-standards` clone), add "proceed with dirty working tree?" to Question Round 1.
   - Determine mode:
     - **Initial setup mode**: `docs/rules/` does not exist, or contains no managed rule file matching any existing rule name.
     - **Synchronization mode**: `docs/rules/` already contains one or more rule files.
2. **Inspect codebase and existing setup.**
   - Scan project markers (`*.slnx`/`*.csproj`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, config files, entrypoints, `Dockerfile`, etc.) plus root router/hook files and existing `docs/rules/` files.
   - Record factual hints for which stack rule files and conditional shared rule conditions appear true or false for the repository (to guide pre-selections in Phase 3, never to skip asking ambiguous cases).

---

## Phase 2: Resolve tag and read catalog

1. **Resolve `<STANDARDS_TAG>`** — the newest `v*` tag on the remote, in semver order:

   ```bash
   git ls-remote --tags --refs --sort=-v:refname <STANDARDS_REPO> 'v*' | head -1 | sed 's#.*refs/tags/##'
   ```

   Confirmation: prints one tag name. If empty, STOP and report — never synchronize rules from memory or a stale local copy.

2. **Clone into `./.dev-standards`** inside the invocation directory (the repository root), removing any leftover clone from an earlier aborted run first. Clone full tag history so Phase 3 can classify stale vs locally modified vs retired managed rules accurately:

   ```bash
   test -e .dev-standards && rm -rf .dev-standards
   git clone --branch <STANDARDS_TAG> <STANDARDS_REPO> .dev-standards
   ```

   Confirmation: `git -C .dev-standards rev-parse --show-toplevel` resolves inside the invocation directory. `<STD>` refers to `./.dev-standards`. If cloning fails, STOP and report (delete partial `.dev-standards` if created).

3. **Read `RULES_MAPPING` in full** (`<STD>/dist/templates/shared/rules-mapping.md`). Confirmation: it exists and states `Mapping format: <RULES_MAPPING_FORMAT>`. If it is missing or states another number, STOP, run `rm -rf .dev-standards`, and report that this skill expects rules-mapping format `<RULES_MAPPING_FORMAT>` and must be recopied from `<STANDARDS_TAG>` (`skills/sync-rules/`). Do not interpret a mapping of another format.

---

## Phase 3: Select rules and classify targets

1. **Select target rules from `RULES_MAPPING`.**
   - Every entry under **Universal shared rules** is always included.
   - Review every entry under **Stack rules** and **Conditional shared rules** against Phase 1 repository evidence (and already-present `docs/rules/*.md` in synchronization mode).
   - Run **Question Round 1** (`AskUserQuestion`, `multiSelect: true` where multiple choices apply, batching conditional rules into groups if needed so all rows fit clearly):
     - Confirm dirty-tree continuation if flagged in Phase 1.
     - Select applicable **Stack rules** from `RULES_MAPPING` (skipping stack rules when none match the repository's stack).
     - Select applicable **Conditional shared rules** from `RULES_MAPPING`, displaying the opening `**Applies when**` paragraph of each file's source in the clone and marking evidence-matched files as recommended defaults (and preserving existing conditional rules unless the user explicitly deselects them).
     - **Shared starter files check (`RULES_MAPPING` Shared starter files)**: if any target under **Shared starter files (optional)** in `RULES_MAPPING` is absent in a repository with no stack scaffolding run planned (for `.NET` repositories lacking scaffolding, note that `init-dotnet-app` / `retrofit-dotnet-app` generates `.NET`-specific router and gates instead), ask whether `sync-rules` should copy the missing **Shared starter files** from `RULES_MAPPING` verbatim (never overwriting existing files).

2. **Classify every target under `docs/rules/`.**
   - For each **selected** rule target (`Universal` + user-selected `Conditional` / `Stack` rows in `RULES_MAPPING`):
     - File does not exist locally → **add** (copy verbatim from `<STD>/<Source>`).
     - File exists locally and matches `<STD>/<Source>` (comparing normalized content ignoring working-tree LF/CRLF differences) → **skip (current)**.
     - File exists locally, differs from `<STD>/<Source>`, and byte-matches that path at some earlier tag in `<STD>` (`git -C <STD> show <tag>:<Source>`) → **update** (overwrite cleanly with `<STD>/<Source>`).
     - File exists locally, differs from `<STD>/<Source>`, and matches NO tag in `<STD>` → **ask (diverged — locally edited)**: show diff against `<STD>/<Source>` and ask whether to overwrite with the tag version or keep local edits.
   - For every **other `.md` file already in `docs/rules/`** not in the selected set:
     - Check whether any tag in `<STD>` shipped that filename under `dist/rules/<name>.md` (`git -C <STD> log --all --format=%H -- dist/rules/<name>.md` and compare content against tag snapshots).
     - Matches an historical distributed rule (either a retired rule such as `git.md` removed from `RULES_MAPPING`, or a conditional rule the user deselected) → **ask**: **retire (`git rm` / delete)** (Recommended when retired from `RULES_MAPPING`) or **keep**.
     - Matches NO tag snapshot at all → **keep (repository-authored)** (e.g., `docs/rules/<App>.md`).

3. **Present reconciliation table and resolve open questions.**
   Show a table of `Path` / `Status` / `Planned Action` for every file under `docs/rules/` (plus any missing **Shared starter files** selected in step 1), and run **Question Round 2** (`AskUserQuestion`) for every *ask* item (*diverged*, *retired/deselected*). Do not edit files until every open item is decided.

---

## Phase 4: Apply synchronization

1. Ensure `docs/rules/` exists (`mkdir -p docs/rules`).
2. Execute approved **add**, **update**, and **retire** (`git rm` if tracked, `rm` if untracked) actions cleanly.
   - Match working-tree line endings assigned by `.gitattributes` if present; otherwise write UTF-8 without BOM using LF endings with a trailing LF.
3. For any missing **Shared starter files** selected from `RULES_MAPPING` in Phase 3, create parent directories (`mkdir -p`) and copy `<STD>/<Source>` to `<Target>` verbatim without overwriting any existing file.
4. Scan `AGENTS.md` and `docs/` for any dangling reference to retired rules (e.g., `git.md`) and list them in Phase 5 so the user (or subsequent `/retrofit-dotnet-app` / `/audit-repo`) cleans them up.
5. **Confirmation**: every selected rule file in `docs/rules/` matches `<STD>/<Source>`, every approved retirement is removed, and every *diverged* file reflects the user's explicit choice.

---

## Phase 5: Cleanup and final report

1. If `.git` exists, run `git reset` (index only, preserving working-tree changes) so staging is not left mixed before the user reviews commits.
2. Delete the clone:

   ```bash
   rm -rf .dev-standards
   ```

   Confirmation: `test -e .dev-standards` is false. This is mandatory so untracked clone files are never committed into the consuming repository.

3. Report:
   - Resolved tag (`<STANDARDS_TAG>`) and mode (initial setup / synchronization)
   - Rule reconciliation summary: added, updated, skipped (current), retired, kept (repository-authored or diverged)
   - **Shared starter files** created (if any; if generic `AGENTS.md` was copied from `RULES_MAPPING`, remind the user to replace `<PLACEHOLDER>` markers and create `docs/rules/<APP>.md`, `docs/specs/<APP>.md`, and `docs/references/code-map.md`)
   - Dangling references to retired rules found in existing `AGENTS.md` or `docs/` (if any)
   - Recommended next steps where applicable:
     - On an existing `.NET` repository whose templates, mechanisms, router, or build gates have not yet converged onto this tag: run `/retrofit-dotnet-app`
     - After converging scaffolding (or directly on non-.NET repositories with existing code) to audit the whole codebase against the synced rules: run `/audit-repo`
     - When an application specification is missing or does not satisfy `docs/rules/specs.md`: run `/specify-app`
     - *(When adding a newly applicable conditional rule mid-project on an already-converged repository, review or test only the domain covered by that new rule unless a full `/audit-repo` run is desired.)*
   - Proposed commit split (if applicable; do NOT commit automatically):
     1. Rule synchronization (`docs/rules/` additions/updates/retirements, optional starter files if added)
