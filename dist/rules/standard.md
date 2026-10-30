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
- **Core rules**: Shared standards (`standard.md`, `documentation.md`, `git.md`) and the conditional core files (`cli.md`, `db.md`)

**Precedence on conflict**: Application rules > Stack rules > Core rules. `AGENTS.md` provides routing and commands only.

- **No conflicts within the core**: Core rule files never contradict each other. A contradiction found between two core files is a defect in the rules: do not resolve it by choosing one — report it to the user and continue only on the user's decision.
- **Rule Scope**: Every change complies with every file under `docs/rules/` and the specification of the application being changed under `docs/specs/`.
- **Required reading**: Read all of them before implementing any change. The conditional core files are the only exception.
- **Conditional core files**: Each conditional core file opens with the condition under which it applies, a fact about the application settled by its code. Leave the file unread only while that condition is false for the application being changed. Whether the task at hand touches the file's subject never decides it.
- **A change that makes a condition true**: A change that gives the application the property (its first command-line option, its first database access) is subject to that conditional core file.
- **Stack conformance**: Repositories apply the stack rules matching their technology stack, verified by commands in `AGENTS.md`.
- **Enforcement matrix**: Each stack rule file opens with a matrix classifying every rule as mechanically enforced (analyzers, build gates) or verified by AUDIT.
- **Completion requirement**: Passing the AUDIT gate at the end of this file is mandatory before reporting any task complete.

---

## Code Design

### Separation of Concerns

- Structure code in layers with distinct responsibilities (e.g., UI → business logic → infrastructure)
- Keep the UI layer thin: event handlers delegate to logic, they do not contain it
- What the UI shows is decision logic too: a color, whether a control is enabled or visible, and which message appears are decided outside the UI layer, where a test reaches the decision without rendering anything

### Dependency Direction

- Dependencies must flow in one direction only (e.g., UI → Service → Common → Database)
- Never introduce reverse or circular dependencies. If a change would require one, reconsider the design before implementing

### Minimal Visibility

A declaration's visibility tells the reader who calls it. A declaration visible wider than its callers claims callers that do not exist, and invites the first one to depend on it.

- **Visible only as widely as its callers**: each type and member is visible to the narrowest scope that contains every caller it has. Visibility widens when a caller that needs it is written, never in advance
- **The declaration states the reach it has**: a member is never declared wider than its containing type lets it reach, unless a framework that calls the member requires the wider declaration. A modifier that claims more than the member gets misstates who can call it
- **A framework that calls code is a caller**: a test runner, a serializer, a UI binding, and code a tool generates reach code by their own rules, and the visibility they require is the visibility the code needs. Configuring a framework to reach past the visibility it reads by default is not narrower — it opens every member of that visibility to the framework, not only the ones meant for it
- **Tests never widen visibility**: a test reaches code it cannot see through the stack's test-access mechanism, or through the code it can see. Code is never made more visible so that a test can call it
- Stack rules give the modifiers and the mechanisms that enforce this

### Functional Core, Imperative Shell

- Separate decisions from I/O: do not make business decisions while reading from DB/files/network — read the data first, then decide on the data already read
- Decision logic takes data as arguments and returns results (pure functions), so it can be tested without infrastructure
- Keep I/O in a thin shell that orchestrates: fetch → decide (pure) → write
- Time, randomness, and environment values are inputs too: pass them as arguments; introduce clock abstractions or DI only when argument-passing is not enough

### Declared Mutation

A call changes only what its name and signature show it changes, and state changes only where something has to change it. A change neither the name nor the signature shows is found only by reading the body, and a value that anything could have changed has to be traced before it can be trusted.

- **Arguments change only when declared**: a function changes an object it receives only when its name or signature declares that change (e.g., a name stating that it sorts or fills its argument, a parameter the language marks as modified). Every other result leaves through the return value. A function named for computing one value that also rewrites an argument hands its caller a change the caller neither asked for nor can see.
- **Fixed unless something must change it**: a field, a variable, and an object's state are declared unchangeable once set, unless code that runs after they are set has to change them. Changeable state can be changed by any code that reaches it, so a reader has to rule out all of that code before trusting the value.
- **A framework that writes is a writer**: a framework that sets values on an object after creating it (a UI binding, an object-relational mapper, a deserializer) is code that has to change that object, and the state it sets stays changeable. A framework that sets values only while creating the object changes nothing afterwards, and the state stays fixed.

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
- A narrowed type checks its rule wherever an instance is created or changed, so every instance that exists is valid and code that receives one does not check the rule again. A narrowed type that can hold an invalid value only renames the unchecked value
- When a rule can be broken silently (wrong call order, configuration after startup, out-of-range values), make the code fail fast with a clear message instead of relying on documentation
- The error message should state the rule itself

### Writes That Hold Together

Applies to every write to durable state — a database, files, a message sent to another system.

- **Atomic units**: writes that are only valid together (a header and its rows, a file and the record pointing at it) are applied as one unit that either completes or leaves no trace (e.g., a database transaction, writing to a temporary file and then moving it into place). A process that stops between separate writes leaves a half-applied state nothing repairs.
- **Safe to re-run**: a process that can stop partway (a crash, a killed job, a request sent twice) reaches the same final state when run again as when it runs once to completion. Whoever re-runs it cannot see how far the first run got.
- **Concurrent updates**: where two users or processes can change the same data, a write checks that the state it was based on is still current, and a write whose basis changed is reported instead of applied (e.g., a version column compared on update). Without the check, the later write silently discards the earlier one.

### Stored Time

- **Instants are UTC**: a point in time that is stored or sent to another system is UTC, or carries its UTC offset; conversion to a local time zone happens only when the value is displayed. A local time without an offset changes meaning when the machine, the server's location, or daylight saving time changes.
- **Dates are not instants**: a calendar date with no time of day (a due date, a delivery date) is stored as a date, not as midnight of some time zone. Midnight in one time zone is a different date in another.

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

### Tests Accompany the Change

- **Decisions are tested**: a change that adds or changes decision logic includes tests that pin the new behavior. Behavior no test observes is free to break in the next change without any gate failing.
- **Defects are reproduced first**: a defect fix includes a test that fails without the fix and passes with it. That test is what stops the same defect from returning.

### Boundary Tests

- **Test the boundary itself**: code that crosses the program's boundary (a database query, a file format another system reads, a network protocol) is tested through that boundary, with data the test creates (e.g., a database the test run creates and migrates, a file the test writes and parses back). A test of the logic behind the boundary leaves the query or the format unverified.
- **No third-party services**: tests never call a service the project does not run, such as one that charges per call, limits the call rate, or answers nondeterministically. The test substitutes it behind the interface the code depends on.

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

## External Input

Applies to data the application receives while it runs — user input, imported files,
requests, and responses from other systems, including generated output such as a
language model's. Values an operator sets to configure the application are
Configuration Values below.

- **Validate at the boundary**: input is checked against its expected shape and range where it enters the program, and only checked data travels inward. A check repeated at each use site is missing from at least one of them.
- **Canonicalize, then validate**: a deterministic canonicalization that the input's specification defines (e.g., trimming surrounding whitespace, unifying line endings, Unicode normalization) is applied before the check. Guessing what an invalid value was meant to be is not canonicalization.
- **Reject, never repair**: input that fails the check is rejected — the whole input, or only the failing items when the input is a set of independent items — and the rejection states what was wrong. Beyond canonicalization, input is never altered into something that passes: unlike a configuration value, input has no known-good value to fall back on, and a repaired input produces a result nobody submitted.
- **Input never becomes code**: input is never concatenated into text that something executes or interprets (SQL, a shell command, HTML, a query language) — it is passed through the mechanism that keeps it data (e.g., bound query parameters, an argument array, encoding by the rendering layer). Concatenated input can rewrite the command it was placed in.

---

## Configuration Values

Applies to every value an operator sets to configure the application — configuration
files, environment variables, and any other external store.

- **Every configurable value has a built-in default in code**, and the application runs on that default whenever the external value is missing, unparsable, or out of range. A configuration source that is absent or corrupt never fails startup on account of such a value
- **Required values fail fast**: a value no default can stand in for (a credential, the address of the only database the application uses) is checked once at startup, and the application stops with a message naming the missing value before doing any work. Discovering it on the first operation that needs it hides the cause behind an unrelated failure
- **The target environment is configuration**: which database, service address, or directory the application works against is a configuration value, never a constant in code. A target fixed in code ties the build to one environment, so the build that is tested is not the build that runs in production
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

## Failure Reporting

- **Unattended failures reach a person**: a process that runs with nobody watching (a scheduled job, a service, a background task) reports a failure where a person sees it without going to look (e.g., a notification, a monitored event log, an exit code the scheduler alerts on). A failure recorded only in a log file is found when someone notices the missing result.

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

- **Core rules, in every target file**: Zero violations against `standard.md`, `documentation.md`, and each conditional core file (`cli.md`, `db.md`) whose condition holds for the application after the change.
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
