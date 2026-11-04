---
name: specify-app
description: Write the specification of an existing application from its implementation, on any stack, to the criteria of the repository's docs/rules/specs.md. Use when an application has no specification or only a skeleton, when retrofit-dotnet-app names this skill as the next step, or when the user says "write the spec from the code", "specify this app", or "bring the spec up to specs.md". Inventories every decision in the code, settles each question specs.md asks of it, classifies the code's answers as specified, unconfirmed, or violation, asks the user in batched rounds, then writes the requirements, the ledgers beside the specification, the tests the requirements bring, and the fixes the user approves. Run from the repository root; no network access needed.
allowed-tools: AskUserQuestion, Read, Write, Edit, Glob, Grep, Bash
---

# specify-app

One goal: after the run, the application's specification meets `docs/rules/specs.md` for
every decision of the application — each question that applies to each decision is
answered by a requirement or recorded in one of the application's ledgers — and every
answer has the source `specs.md` allows. Nothing in the specification is the skill's own
choice.

This skill restates no rule. What a decision is, which questions apply, what answers
them, where an answer may come from, how the code's answers are classified and handled,
and where the ledgers live are all in `docs/rules/specs.md`; requirement text and IDs are
in `docs/rules/documentation.md`; the tests a requirement brings are in
`docs/rules/testing.md`. Read them from the repository, never from memory.

The skill uses the rules the repository holds under `docs/rules/`, not a clone of
dev-standards: every later AUDIT of the repository checks the specification against
those rules.

**No commits.** The run ends with a proposed commit split — the user decides.

### Question round conventions

Batch questions with `AskUserQuestion`, up to 4 per call, repeating calls until every
open item has the user's answer or the user's decision to leave it open. Each question
names the decision and the question ID from `specs.md`, states what the code does now
and where, and offers the answers the rules allow. Mark a recommended option only where
a rule makes one answer the rules' own. Never resolve an item the user has not answered.

---

## Phase 1: Context

1. **Load the rules.** Read the root `AGENTS.md` and every file under `docs/rules/`.
   Confirmation: `docs/rules/specs.md` exists. If it does not, STOP: the repository's
   rules predate `specs.md`, and the user brings `docs/rules/` onto a dev-standards tag
   that has it first (for a .NET repository, `retrofit-dotnet-app` does this).
2. **Choose the application.** Take the applications from the `AGENTS.md` Applications
   table. With more than one, ask which to specify. Confirmation: the application's
   identifier `<App>`, its projects or content, and its specification path are known.
3. **Read what exists.** Read the specification and, if present, the ledgers at the paths
   `specs.md` (Ledgers) gives. Every requirement already there is a statement of the user
   (`specs.md`, Where Answers Come From).
4. **Check the working tree.** Run `git status`. If it is dirty, ask whether to proceed —
   this run's changes should not mix with unrelated edits.

## Phase 2: Inventory the decisions

1. **Read every source file of the application**, folder by folder, without sampling, and
   list every decision as `specs.md` (Decisions) defines it: what outcome it chooses, its
   inputs, and the code that carries it (file and symbol). Keep the inventory in a
   working file under `docs/plans/` (gitignored), so an interrupted run resumes from it.
2. **Map existing requirements.** For each requirement already in the specification, name
   the decisions it states answers for.

Confirmation: every source file of the application appears in the inventory, with its
decisions or "no decisions".

## Phase 3: Settle every question

For each decision and each question in `specs.md`:

1. **Applicability.** Decide whether the question applies, by its condition in
   `specs.md`. Record the fact about the code or the deployment that settles it.
2. **The code's answer.** For each question that applies, record what the code does in
   the case the question asks about, the code that produces it, and whether a comment, a
   test, or a guard declares it.
3. **Class.** Classify the code's answer as `specs.md` (Classifying an Implementation's
   Behavior) directs, recording the rule, the user's statement, or the absence of both
   that decides the class.

Confirmation: in the inventory, every decision carries every question with "does not
apply" and its reason, or the code's answer and its class.

## Phase 4: Ask the user

1. **Present the findings.** Show a table of the violations and one of the unconfirmed
   answers, each grouped by question ID, before asking.
2. **Question Round 1 — unconfirmed answers.** For each, the options are: confirm what the
   code does; give another answer; leave it open. Group answers that share a decision
   and a question, or a question and the same code answer, into one question.
3. **Question Round 2 — violations**, including the unconfirmed answers the user answered
   otherwise in Round 1. For each, the options are: fix now; defer; and, for a violation
   of a statement already in the specification, replace the statement with what the code
   does. Where the rules admit several answers, the fix-now option asks which.

Confirmation: every item has the user's answer or the user's decision to leave it open or
defer it.

## Phase 5: Write

1. **Requirements.** State every specified answer as a requirement of the specification,
   with an ID, as `documentation.md` (Requirement text, Requirement IDs) directs. Remove
   or move every existing statement the user's Round 2 decisions changed.
2. **Ledgers.** Write each open unconfirmed answer and each deferred violation as a ledger
   entry, at the paths and with the content `specs.md` (Ledgers) gives, with the front
   matter `documentation.md` requires. Write no ledger that would be empty.
3. **Tests.** Every requirement this run added brings what `testing.md` requires for it
   (Tests Accompany the Change, Requirement Coverage), with the stack's test framework and
   the commands in `AGENTS.md`.

Confirmation: the inventory has no decision with a question that applies and is neither
answered by a requirement nor recorded in a ledger.

## Phase 6: Fix the approved violations

Each fix is an implementation change under the repository's rules: the specification
states the answer before or with the code change (spec-first, `standard.md`), and the
tests the rules require come with it. Remove the fixed items from the ledgers.

Confirmation: AUDIT (`standard.md`) passes over every file this run changed, with every
gate command in `AGENTS.md` exiting 0.

## Phase 7: Report

Delete the working inventory under `docs/plans/` once the report is written, unless the
user asks to keep it.

Report:

- The number of decisions and source files covered
- The requirements added, by ID, and the existing statements changed or moved
- The ledger entries, by question ID: open unconfirmed answers and deferred violations
- The violations fixed, with the tests that verify them
- The gate results with exit codes
- Proposed commit split (do not commit until the user confirms):
  1. Specification, ledgers, and the tests of the requirements that describe existing
     behavior
  2. Each approved fix, one commit per violation or per group the user approved together
