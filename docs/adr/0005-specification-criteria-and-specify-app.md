---
status: accepted
---

# Specification Criteria, Ledgers Beside the Specification, and the specify-app Skill

## Context

The distributed rules said what a specification is (`documentation.md`), that it comes
before the code (`standard.md` Specifications), and that its requirements are tested
(`testing.md`). They said nothing about what a specification must state about the
decisions an application makes. Formal verification of implementations keeps finding the
same kinds of defect — a condition set that matches nothing, a setting another one
silently overrides, a check racing the write it guards, a limit enforced against a stale
copy, a failure returned as "false" and then negated, an empty rule that matches
everything, a value trusted because of where it sits in a request — and every one of them
is a decision nobody stated, settled by whoever wrote the code.

Existing applications add a second problem. Retrofit generated a specification skeleton
and left the rest to be backfilled change by change, so an existing application's actual
behavior was specified nowhere. Writing it down from the code raises two kinds of finding
that need a defined home: behavior nobody has confirmed as intended, and behavior a rule
prohibits.

`standard.md` Configuration Values also asked for two incompatible things for a value
such as an output folder: a built-in default for every configurable value, and no
constant in code for the target environment.

## Decision

- **A new task-specific core file, `dist/rules/specs.md`**, binds every application. It
  defines a decision by an observable test, and states thirteen questions a
  specification answers for each decision in three groups — conditions and settings,
  concurrency and time, boundaries and trust — each with the condition under which it
  applies and the statement that answers it. Some questions also require a property of
  the answer itself (a loop has a bound the application counts; a reader sees a write
  whole or not at all; a change that must reach another place survives a stop), so a
  specification cannot require the defect
- **The same questions before and after the code**. Only the sources of an answer
  differ: a rule that admits one answer, the user (the request, an answer, an existing
  statement), and — when writing from an implementation — the code, which is only ever a
  candidate. An answer the specification's writer picked because nothing ruled it out is
  not an answer
- **The code's answers are classified, first match wins**: violation (a rule prohibits
  it, or it contradicts the specification or the user), specified (a rule admits only
  it, or the user confirms it), unconfirmed (everything else). A comment, a test, or a
  guard does not confirm anything: it shows what a developer wrote, not what the user
  decided
- **Handling follows the class**: specified answers become requirements; the user
  decides to fix or defer each violation; unconfirmed answers are asked. Neither a
  deferred violation nor an open unconfirmed answer is ever a requirement, because a
  specification stating behavior the code lacks fails every later AUDIT, and one stating
  prohibited or unconfirmed behavior turns a guess into a requirement
- **Two ledgers beside the specification**, at
  `docs/references/<App>/unconfirmed-behavior.md` and
  `docs/references/<App>/violating-behavior.md`. They hold facts about the
  implementation, not required behavior, so they are references, not specifications;
  `specs.md` makes them required reading wherever the specification is read
- **Scope for existing applications**: `specs.md` binds a decision from the change that
  adds or changes it, and every decision once the specification is written from the
  implementation. Without this, the first change to touch a specification would have to
  specify the whole application
- **A new published skill, `specify-app`**, writes an existing application's
  specification from its implementation to these criteria, on any stack. It is separate
  from scaffolding and retrofit because it runs on its own event (an application whose
  specification does not meet `specs.md`), needs no template set, and works for stacks
  that have none. It applies the rules the repository holds, because every later AUDIT
  checks the specification against those. It extends the published set of ADR 0004 on
  the terms that ADR set: event-driven, procedure only, no rule text
- **`retrofit-dotnet-app` names `specify-app` as the next step** when the specification
  does not meet `specs.md`, instead of writing the specification itself
- **Configuration Values gets one criterion**: a value has a built-in default only when
  that default — a constant or a rule resolved at run time — is correct at every
  installation where the setting is empty; a value whose correct value is chosen per
  installation is required and fails fast. The default rule, the target-environment
  rule, Required values fail fast, and Validate on read now read as one rule

## Trap coverage

Each trap the formal-methods playbook lists is closed by the question named:

| Trap | Question in `specs.md` |
|---|---|
| Dead configuration (conditions that can never hold together) | SETTINGS (combinations that match nothing) |
| Subsumption (a setting another one already decides) | SETTINGS (settings that override) |
| Coverage gaps and dead branches | OUTCOMES (classes cover every value, one outcome per class) |
| Change impact | OUTCOMES (a complete class table states the outcomes a changed setting flips); STALE (settings read once and kept) |
| Expression equivalence (old and new formats, refactors) | FORMATS; OUTCOMES as the reference both versions must meet |
| Read-modify-write race | SHARED (simultaneous operations, invariant named) |
| Check and record split | SHARED (admitted means counted, where the limit is kept — in another system too) |
| Staleness | STALE |
| Torn reads | PARTIAL |
| Counter invariants under duplicates and races | SHARED (the invariant holds in the outcome of simultaneous operations), REPEAT |
| Non-terminating loops | LOOPS |
| Lost propagation | PROPAGATION |
| Idempotency, fresh identifiers per attempt | REPEAT (an identifier fixed before the first attempt; a later arrival gets the first arrival's outcome) |
| Inconsistent fail-open and fail-closed | UNAVAILABLE (checks guarding one operation agree) |
| Errors collapsed into false, then negated | UNAVAILABLE (a class of its own, stated after every combination) |
| Empty-set semantics | EMPTY |
| Spoofable trust boundary | ORIGIN |
| Cross-boundary representation mismatch | REPRESENTATION |
| Client-only validation | ORIGIN (a check in a program the party controls does not count) |
| Missing preconditions | OUTCOMES (every value the input can carry, invalid ones included) |

## Alternatives Considered

- **Put the criteria into `documentation.md`** — rejected: `documentation.md` governs
  every document's placement and text; the questions about decisions bind only
  specifications and grow with their own subject
- **Name the checking tools (an SMT solver, a model checker)** — rejected: dev-standards
  is stack- and tool-agnostic; a tool is one way to check a specification against the
  questions, and the questions hold without it
- **State deferred violations and unconfirmed behavior in the specification, marked** —
  rejected: a specification states behavior the application must exhibit; a marked
  guess is still read as a requirement, and tests and AUDIT would pin it
- **Write the required (rule-compliant) behavior into the specification while the code
  lags** — rejected: the requirement could not be verified by a passing test, and every
  AUDIT of the application would fail on it until the fix lands
- **Ledgers inside `docs/specs/`** — rejected: the specification already holds the
  single-file shape `docs/specs/<App>.md`, which the scaffold generates, and a ledger is
  not a specification
- **Let retrofit write the specification** — rejected: the work is independent of the
  template set, applies to every stack, and is far larger than converging scaffolding

## Consequences

- A specification written to `specs.md` states, for every decision, what the traps above
  would otherwise leave to the code, and an implementation built from it has those
  decisions made up front
- Existing applications get a complete picture of their behavior: requirements for what
  is confirmed, ledgers for what is not, and nothing left unexamined
- Writing a specification from an implementation asks the user many questions; the
  unanswered ones stay in the ledger, and any change that alters a recorded behavior must
  resolve its entry first
- Requirements added to an existing specification bring their tests (`testing.md`), so
  `specify-app` writes tests as well as text
- A new core file reaches every list that names the distributed files, and the mapping
  carries its managed-rule row

## Revisit When

- Applications written to `specs.md` still show one of the playbook's traps: the
  question that should have closed it is missing or its condition is too narrow
- The ledgers prove too large to read with every change: split them by area, keeping
  them beside the specification
- A second stack template set appears: decide whether its retrofit skill also names
  `specify-app`
