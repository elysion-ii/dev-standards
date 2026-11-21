---
name: audit-repo
description: Audit an entire repository's tracked code, tests, and documentation against its local `docs/rules/` using the AUDIT procedure in `docs/rules/standard.md`. Checks every file folder by folder, reports any conditional rule domains newly exercised by the code whose rule file is missing from `docs/rules/`, groups findings by rule, asks to fix now or defer, applies approved fixes with tests and mechanical gates, and records deferred violations cleanly. Stack-agnostic and offline (no network access required); run after `sync-rules` and any stack retrofit skill (such as `retrofit-dotnet-app`), or whenever running a whole-repository conformance check.
allowed-tools: AskUserQuestion, Read, Write, Edit, Glob, Grep, Bash
---

# audit-repo

Audit an entire repository against the rules currently held in its own `docs/rules/`, using the `AUDIT` procedure at the end of `docs/rules/standard.md`.

This skill is **stack-agnostic** and requires **no network access**: it clones nothing and verifies against the repository's committed/local rules under `docs/rules/`, matching the rules every subsequent task AUDIT checks.

Recommended sequence for converging an existing repository before running this audit:
1. `/sync-rules` (synchronize `docs/rules/` and retire obsolete managed files)
2. Stack retrofit if applicable (e.g., `/retrofit-dotnet-app` for `.NET` templates, router, `docs/`, and build gates)
3. `/audit-repo` (this skill — audit the entire codebase and docs once rules and gates are in place)
4. `/specify-app` (when any application specification does not yet meet `docs/rules/specs.md`)

**No commits.** Approved fixes are left in the working tree for user review with a proposed commit split.

### Question round conventions

Batch questions with `AskUserQuestion`, up to 4 per call, repeating calls until every open item is settled. Recommend *fix now* for safe local fixes. Never silently resolve or defer an item without the user's decision.

---

## Phase 1: Context and prerequisites

1. **Check prerequisites.** Verify `docs/rules/standard.md` exists. If it is absent (or `docs/rules/` is missing), STOP and tell the user to run `/sync-rules` first.
2. **Check the working tree.** Run `git status`. If dirty, ask via `AskUserQuestion` whether to proceed anyway — audit fixes should not mix inadvertently with unrelated uncommitted edits.
3. **Load rules and repository map (`standard.md` AUDIT step 1).**
   - Read root `AGENTS.md` (and any nested `AGENTS.md`).
   - Read every file under `docs/rules/` in full.
   - Read every specification under `docs/specs/`, behavior ledgers (`docs/references/<App>/unconfirmed-behavior.md`, `violating-behavior.md`), `docs/references/code-map.md`, and any existing deferred-violation notes under `docs/notes/`.
   - Confirmation: list every file loaded, and for multi-application repositories note any conditional rule file under `docs/rules/` skipped for an application whose factual `Applies when` condition is false.

---

## Phase 2: Inspect the repository (`standard.md` AUDIT steps 2–3)

1. **Enumerate target files.** Collect every tracked non-binary file from `git ls-files` plus any newly added non-ignored files, excluding dev-standards-managed rule files under `docs/rules/` (never repository-authored `<App>.md` files).
2. **Inspect folder by folder without sampling.** Check every line of every target file against:
   - Universal shared rules (`standard.md`, `documentation.md`, `specs.md`, `testing.md`)
   - Applicable conditional shared rules present in `docs/rules/`
   - Applicable stack rules present in `docs/rules/` (all `AUDIT` rows, plus any `Enforced` row whose mechanical gate is missing)
   - Repository application rules (`docs/rules/<App>.md`)
   - Application specifications (`docs/specs/<App>.md`) and `One Home per Piece of Knowledge` across the repository
   - **`Missing conditional rules`** (`standard.md` How to Use These Rules and `AUDIT` step 3): check whether the codebase exercises any conditional shared domain whose rule file is absent from `docs/rules/`. Record every missing domain file separately so the user can run `/sync-rules` to add it (never invent unprinted obligations from memory for absent files).
   - **Specification completeness check**: note whether any existing specification lacks decisions required by `docs/rules/specs.md` (so the report recommends `/specify-app`).
3. **Record findings.** Assign each violation an ID (`V1`, `V2`, ...), naming file and line, rule file and heading/matrix ID, defect summary, proposed fix, and reach:
   - *local* (contained within one file)
   - *cross-cutting* (updates callers or multiple files)
   - *needs specification change* (requires updating `docs/specs/` first per `standard.md` Specifications).
   Confirmation: every inspected file appears in the audit record with its violation IDs or "no violations".

---

## Phase 3: Question round (`AskUserQuestion`)

Skip this phase when Phase 2 recorded zero violations.

1. Present all recorded violations in a table grouped by rule (and summarize any missing conditional domain files detected).
2. Ask via `AskUserQuestion` (batched up to 4 questions per call) whether to **fix now** or **defer** per violation or coherent rule group:
   - Recommend **fix now** for low-risk *local* fixes.
   - For violations marked *needs specification change*, clarify that fixing starts by updating `docs/specs/<App>.md` first.
   - Do not start Phase 4 until every violation is decided.

---

## Phase 4: Apply approved fixes, record deferrals, and verify

1. **Apply approved fixes** strictly under the repository's rules:
   - Update specifications before behavior changes (`standard.md` Specifications).
   - Add or update tests alongside fixes (`docs/rules/testing.md`).
   - Run every verification command listed in `AGENTS.md` (format verification, zero-warning build, tests — skipping any non-applicable command) and confirm exit code `0`.
2. **Record user-deferred violations (`standard.md` AUDIT step 5)** without modifying code for them:
   - Decision violations go into `docs/references/<App>/violating-behavior.md` per `docs/rules/specs.md` (moving any contradicted requirement out of `docs/specs/`).
   - Other code or documentation violations go into `docs/notes/<App>/deferred-violations.md` or `docs/notes/deferred-violations.md`.
3. **Re-verify touched files.** Re-inspect every file modified during Phase 4 to confirm zero newly introduced violations and passing mechanical gates.

---

## Phase 5: Report

Report:
- Number of files audited and list of rules loaded (including skipped conditional rules with factual reasons in multi-app repos)
- Missing conditional domain files detected (if any) → recommend running `/sync-rules` to add them
- Violation summary table (`V1`, `V2`, ...) with final outcome (*fixed* / *deferred* and deferral location)
- Mechanical gate outcomes and exact exit codes from Phase 4
- Next steps where applicable:
  - `/sync-rules` if missing conditional domains were detected
  - `/specify-app` if any application specification does not meet `docs/rules/specs.md`
- Proposed commit split (do NOT commit automatically):
  1. Approved conformance fixes (one commit per rule or coherent group, including spec/test updates)
  2. Deferred violation records under `docs/references/` or `docs/notes/`
