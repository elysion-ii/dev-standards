# Shared Engineering Standards (core)

Shared engineering standards, distributed into each repository at `docs/rules/`. This
file is the stack-agnostic core. Stack-specific rules live in sibling files in the
same directory (`dotnet.md`, `typescript.md`, `python.md`, ...); application-specific
rules live in the application's rules file listed in the repository's `AGENTS.md`
Applications table.

## How to use these rules

Rules in `docs/rules/` are organized into three tiers:
- **Application rules**: `docs/rules/<App>.md` (repository- and application-specific rules)
- **Stack rules**: Technology-stack rules (`dotnet.md`, `typescript.md`, `python.md`, ...)
- **Core rules**: Shared standards (`standard.md`, `documentation.md`, `git.md`, `cli.md`)

**Precedence on conflict**: Application rules > Stack rules > Core rules. `AGENTS.md` provides routing and commands only.

- **Rule Scope**: Every change complies with every file under `docs/rules/` and the specification of the application being changed under `docs/specs/`.
- **Required reading**: Read all of them before implementing any change. `cli.md` is the single exception, left unread only while that application exposes no command-line interface.
- **Stack conformance**: Repositories apply the stack rules matching their technology stack, verified by commands in `AGENTS.md`.
- **Enforcement matrix**: Each stack rule file opens with a matrix classifying every rule as mechanically enforced (analyzers, build gates) or verified by AUDIT.
- **Completion requirement**: Passing the AUDIT gate at the end of this file is mandatory before reporting any task complete.

---

## Code Design

### Separation of Concerns

- Structure code in layers with distinct responsibilities (e.g., UI → business logic → infrastructure)
- Keep the UI layer thin: event handlers delegate to logic, they do not contain it

### Dependency Direction

- Dependencies must flow in one direction only (e.g., UI → Service → Common → Database)
- Never introduce reverse or circular dependencies. If a change would require one, reconsider the design before implementing

### Functional Core, Imperative Shell

- Separate decisions from I/O: do not make business decisions while reading from DB/files/network — read the data first, then decide on the data already read
- Decision logic takes data as arguments and returns results (pure functions), so it can be tested without infrastructure
- Keep I/O in a thin shell that orchestrates: fetch → decide (pure) → write
- Time, randomness, and environment values are inputs too: pass them as arguments; introduce clock abstractions or DI only when argument-passing is not enough

### Declarative Where It Removes Machinery

Choose between declarative pipelines (LINQ, map/filter) and imperative loops based on which form minimizes cognitive load:

- **Use declarative pipelines** when doing so removes boilerplate machinery: mutable accumulators, manual index tracking, nested loops, or manual list appending. Pure data transformations (filtering, mapping, grouping, sorting) belong here.
- **Use imperative loops** when a declarative form forces unnecessary complexity: tuple accumulators mimicking mutable state, multiple traversals where one suffices, or complex folds with convoluted state.
- **Keep complex control flow imperative**: early exits with reasons, per-item error handling, cancellation checks, and dependencies on previous element states belong in loops.
- **Performance claims require measurement**: never justify a harder-to-read construct by unmeasured performance assumptions. Keep the cleaner form unless profiler data proves otherwise.
- **Function boundary precedence**: this rule governs implementation inside a function. Across function boundaries, Functional Core, Imperative Shell governs.

### Snapshot Before Mutate

- Never modify a data source while lazily iterating over it. This applies to any deferred/streaming enumeration in any language: directory listings (e.g., C# `Directory.EnumerateFiles`, Python `os.scandir`, POSIX `readdir`), collections under `foreach`, DB cursors, lazy queries (LINQ, generators)
- Some environments throw immediately; others fail silently — entries get skipped, processed twice, or the loop ends early. Absence of an exception does not mean absence of the bug
- Snapshot first, then mutate: materialize the full item list (e.g., `.ToList()`, `Directory.GetFiles`, `list(...)`, fetch-all) before the loop that modifies the source

### No Lasagna Code

Every layer must add behavior. A layer that only forwards to another is prohibited:

- Do not create pass-through delegation methods that just call another service with the same arguments
- When extracting shared logic into a new service, update **all** callers to use the new service directly
- Do not leave wrapper methods on the original class

### Shared Algorithm, Local Data

- When deduplicating similar code, extract only the algorithm (the steps identical everywhere); keep each call site's data (queries, mappings, registrations) local
- If sharing would require flags or parameters that grow with each new caller, stop sharing

### Change as Addition

Adding a variation must not require editing existing code:

- Prefer structures where adding a variation (new screen, format, identifier) means adding a new unit plus a registration, not editing branches across existing code

### Leave No Vestiges

Code must read as though the current implementation were the only one that ever existed. Never preserve superseded code or transitional artifacts in the working tree.

- **Delete replaced code completely**: remove superseded implementations, unreachable fields/parameters/branches, obsolete feature flags, and temporary wrapper methods.
- **Avoid relational naming**: never name symbols after their predecessor (`_old`, `_new`, `V2`, `Legacy`, `Ex`). The replacement assumes the canonical name directly.
- **Rely on Git history**: past implementations belong in Git history, never as commented-out code, dead branches, or duplicate classes in the working tree.
- **External compatibility exception**: preserve superseded shapes only for unmodifiable external dependents (published APIs, wire protocols, stored data schemas). When all callers exist within the repository, update the callers instead of preserving compatibility wrappers.
- **Document retained compatibility paths**: when preserving a path for external compatibility, explicitly document which external dependent requires it and what condition ends the obligation.

### Enforce Invariants in Code

- Prefer compile-time impossibility over runtime checks: where practical, express the rule in types (stage-specific interface return types for call order, required constructor arguments, narrowed parameter types) so violations do not compile
- When a rule can be broken silently (wrong call order, configuration after startup, out-of-range values), make the code fail fast with a clear message instead of relying on documentation
- The error message should state the rule itself

### Synchronous vs Asynchronous

- Use async for I/O-bound work (network, DB, file access); keep CPU-bound and pure logic synchronous
- Async propagates end-to-end: never block on async code (`.Result`, `.Wait()`, `GetAwaiter().GetResult()`)
- Do not mark a method async when nothing in it awaits
- Stack rules refine this per stack; they take precedence

---

## Code Comments

### Principle

Comments are generally unnecessary. Prefer clear naming, explicit types, and self-explaining structure.

Write comments only when code cannot express the necessary context by itself. A valid comment explains **why the current shape, condition, guard, or order is required now**.

A justified comment must be concise (1–2 lines at most):
- **Enforce with code first**: do not write comments for constraints that types or fail-fast assertions can enforce mechanically.
- **Cite decisions**: when an ADR exists, cite its path alongside a 1-line summary conclusion.
- **Offload document-sized context**: context exceeding 1–2 lines belongs in an ADR or `docs/references/`, leaving only a 1-line conclusion and a file path in the code comment.

Before writing a comment, verify:
- Can a clearer name, extracted function, type, or test express this? If yes, do that instead.
- Is this historical context (what changed, who asked, what was reviewed)? If yes, place it in Git history or a PR description, never in code.
- Can this be phrased as an active constraint ("this must be this way because...")? If not, omit the comment.

### Good Comments

Good comments explain current constraints that code cannot show:

- Business rules that are not obvious from the code
- External constraints such as API limits, protocol requirements, or legacy system behavior
- Invariants, ordering requirements, and exceptional states
- Non-obvious guards that are required only in specific runtime states
- Why the code has a shape a reader would not have chosen, when a measured result rejected the shape they would have chosen. State the measurement — that is what makes the comment checkable later, and deletable when the measurement stops holding

```csharp
// config is null only on first launch (before the settings file is generated)
if (config != null) { ... }

// The contractual matching key is aaa only; extra conditions drop update history (rationale: docs/adr/0002-order-matching-key.md)
var sql = "SELECT ... FROM [Order_TBL] WHERE aaa = @bbb";

// Three passes over 200k rows cost 400ms; one pass keeps the report inside its 1s budget
var count = 0; var sum = 0m; var max = decimal.MinValue;
```

### Do Not Write

Do not write comments that explain the work history instead of the current constraint:

- What was changed or removed
- Commented-out code, conditions, fields, or parameters
- Notes like "X removed", "X excluded", "changed after review", or "aligned with screen Y"
- Comments that only restate the next line of code
- Bare prohibitions without the current reason
- Performance claims with nothing measured behind them ("for performance", "this is faster") — without the number, the claim cannot be checked, cannot be refuted, and no one dares delete it

If the current code is clear without a comment, write no comment. If the reason matters, explain the reason as a current rule or constraint without preserving removed implementation details.

### Where to Put What

| Information Type | Location |
|-----------------|----------|
| Why the current shape/order/guard is required now | Code comment, only when code cannot express it |
| External constraints, business rules, invariants | Code comment |
| What was changed or removed | Git history / ChangeLog / Release notes |
| Why code was changed | Git commit message / PR description |
| Why something is prohibited | ADR (`docs/adr/`), plus a brief current reason at the usage site if needed |
| Context needing more than 1–2 lines to explain | ADR (`docs/adr/`) or `docs/references/`, with a one-line conclusion + path comment at the site |
| Implementation decisions | ADR (`docs/adr/`) or Docs (`docs/`) |
| Author's work process (review fixes, what was aligned with) | Nowhere in code — that is what PR / commit history is for |

---

## Testing

### Environment Independence

- Tests must not depend on the execution environment: OS culture/locale, timezone, machine state, pre-existing database contents, or network availability
- When behavior depends on culture or time, pin them explicitly inside the test

### Self-Sufficient Test Data

- Each test creates the minimal data it needs (e.g., via test data builders with sensible defaults)
- Do not depend on shared fixture databases or data prepared outside the test — shared mutable test data rots; per-test data keeps tests independent

### Table-Driven Tests

- When a function's spec is "input → output", write tests as a specification table (parameterized tests), not as near-identical separate test methods
- Order rows consistently: null/none → empty → minimal → main cases → boundaries
- Make input values self-describing so the table reads as documentation

---

## Specifications

- **Spec-first**: when a change requires behavior not in the specification (`docs/specs/...`, listed in the `AGENTS.md` Applications table), update the specification before implementing. Never retro-fit the spec to the implementation afterwards
- What a specification must contain and how it is structured is defined in `documentation.md`

---

## Version Display

The first thing to establish about a reported problem is which build produced it. An
application that cannot state its own version turns that into guesswork, and every answer
after it is built on a guess.

- Every application must expose the version it was built with, in the form `<AppName> X.Y.Z` (e.g., `MyApp 1.22.3`)
- `<AppName>` is the application's own name, spelled as the application spells it — the GUI and the CLI print the identical string
- GUI applications display it somewhere always reachable in the UI (title bar, about screen, footer)
- CLI applications provide `--version` / `-V`; the concrete requirements are in `cli.md`
- The default format is the bare product version — no build hash, build date, or other metadata
- The displayed value comes from the project's single version definition (see the stack rule's version-management rules), never from a hardcoded string

---

## Configuration Values

Applies to every value the application reads from outside its own code — configuration
files, environment variables, and any other external store.

- **Every configurable value has a built-in default in code**, and the application runs on that default whenever the external value is missing, unparsable, or out of range. A configuration source that is absent or corrupt never fails startup
- **Validate on read**: replace or clamp invalid values while the configuration is being loaded, so no later code has to defend against them. The valid range belongs to the value's definition, not to checks scattered across its use sites
- **Report every substitution once**, naming the value, what was rejected, and the default applied. A silent fallback hides operator mistakes and turns a typo into an invisible change of behavior
- **Externalizing a value is a choice**: a value nobody adjusts in the field stays a named constant in code (see the stack rule's constants rule). Making it configurable adds the obligations above
- This does not relax Enforce Invariants in Code — that rule governs values the program itself produces, where a violation is a defect and must fail fast. An external value is operator input: the program keeps running on a known-good value and reports what it rejected
- Precedence between sources, for applications that expose a command line, is in `cli.md` (CONFIG)

### Configuration Files in the Repository

Applies to every configuration file that ships with the application — application
settings, deployment descriptors, workflow definitions, and the like.

- **The repository tracks a placeholder template, never a working configuration.** The tracked file is `<name>.template.<ext>` and carries placeholder values only; the file the application actually reads is derived from it and stays untracked. A working configuration holds the credentials, host names, and paths of whoever wrote it — committing one leaks them and makes every other environment inherit them
- **A developer's own configuration is local to that developer.** Derive it from the template, keep it out of version control, and never treat it as a source of truth for anyone else
- **What ships is derived from the template by the build**, so the distributed file is placeholder-clean by construction. Distribution never picks up a configuration file that happened to be sitting in a working tree
- **Installation never overwrites an existing configuration.** The derived file is written only when none is present, so updating an installation keeps what the operator configured
- The template is a real, complete configuration in shape: every key the application reads appears in it, so the file doubles as the documentation of what is configurable

---

## Procedure Design

Applies to all ordered step sequences written for execution by humans or agents: guides (`docs/guides/`), release steps, setup instructions, and procedure lists in PRs or tasks.

### Design Before Writing

- **Define boundaries first**: fix the entry state and target goal state before drafting any step.
- **Redesign on failure**: when a procedure design breaks midway, re-evaluate and reorder the flow rather than patching around it with ad-hoc steps.

### Phases and Steps

- **Two-layer structure**: organize long procedures into phases (headings) and discrete steps. One phase = one clear concern; one step = one distinct operation.
- **Narrative sequence**: phase headings alone must convey the full end-to-end lifecycle (e.g., prepare → change → verify → clean up).
- **Proportional granularity**: avoid over-splitting. Work that constitutes a single logical operation remains one step; short procedures require no phase headings.

### Motivated Order

- **Group related operations**: keep operations of the same kind adjacent (e.g., updating configuration across multiple services) unless sequencing or verification requirements demand interleaving.
- **Justifiable positioning**: every step's placement must be strictly explainable by prerequisite dependencies, verification needs, or locality. Regroup steps that could be moved arbitrarily without impact.

### Step Contract

- **Explicit prerequisites**: each step relies exclusively on explicit inputs or outputs from prior steps. Never assume implicit preconditions or require looking ahead.
- **Observable confirmations**: conclude every step with a verifiable outcome (e.g., "command exits 0", "service responds on port 8080"), never a vague "done".
- **Structured format**: for substantial procedures, format steps as: Precondition → Operation → Confirmation.

### Name the Place

- **Explicit operational context**: state the exact operational location (URL, screen, working directory, window) at the start of each step so the reader can verify context before acting. Never leave location implicit.
- **Explicit transitions**: moving between environments, directories, or screens is an independent operation; write every transition as an explicit step.
- **Ground truth verification**: verify stated locations against the real system (actual UI tree, current directory layout), never assuming continuity from prior steps.

### Automation Boundary

- **Automate mechanical tasks**: fold repetitive or mechanical steps into scripts and build tooling where available.
- **Preserve human gates**: keep irreversible actions and critical judgment calls as explicit manual steps, clearly tagged (e.g., "requires manual confirmation", "irreversible").

---

## AUDIT

Run this procedure after completing an implementation task and **before reporting it as
complete**. Do not report completion until AUDIT passes.

### 1. Reload the rules

Re-read the following before verifying anything:

- **Routers**: the root `AGENTS.md`, and every nested `AGENTS.md` covering a directory you touched.
- **Rule files**: every file under `docs/rules/`.
- **Specifications**: the specification of each application you touched under `docs/specs/`.
- **Already-read exemption**: a file read in full earlier in the same session and unchanged since does not require re-reading.

### 2. Identify target files

Git changes determine which **files** are targets — not which lines:

| Input | Target Scope |
|-------|--------------|
| (none specified) | All uncommitted changes: `git status --porcelain` (modified, added, untracked) |
| A file path | Only that file |
| A folder path | All files in that folder |

Check ALL target files. Verification applies to **the entire content of every target file** —
not merely changed lines. Pre-existing violations in a touched file carry the same weight
as newly introduced violations; every line must comply. Do not sample or skip any target file.

### 3. Verify the change against rules and specifications

Verify all of the following:

- **Core rules, in every target file**: Zero violations against `standard.md`, `documentation.md`, and `cli.md` — `cli.md` only while the application exposes a command-line interface.
- **Git operations, in the change itself**: Zero violations against `git.md`. What `git.md` governs is the commit split, the commit messages, the branch name, and the pull request of this change, so the object verified against it is the change, never a file's content.
- **Stack rules, in every target file**: Zero violations against all stack rules marked **AUDIT** in their enforcement matrix (if an enforcing mechanism is missing from the repository, treat those rules as AUDIT items as well).
- **Application rules, in every target file**: Zero violations against `docs/rules/<App>.md` and any other repository-authored rules under `docs/rules/`.
- **Specification**: Implemented behavior must strictly match the application specification under `docs/specs/`. Any needed specification change must be committed before or alongside implementation, never retrospectively.

### 4. Run mechanical gates

Run the commands defined in `AGENTS.md`. All must execute and exit with code 0:
- **Format check**: Formatter in check mode.
- **Build**: Zero-warning build.
- **Tests**: Clean execution of the full test suite.

### 5. Fix and report

Fix any violations found and re-run from step 2. Report completion only when clean, including:

- Files checked
- Violations found and fixed (file / line / rule), or "no violations"
- Gate results with exit codes
- Anything deliberately left unresolved, stated explicitly
