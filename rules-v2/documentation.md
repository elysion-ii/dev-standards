# Documentation

Shared rules for every non-source document in the repository (e.g., specifications,
guides, references, ADRs, investigations, notes, plans, and routing entry files).
Strictly follow these rules for all document classification, naming, placement,
writing, and retirement.

## Principles

- **Valid documents only in active paths**: active category folders (every folder outside `archive/` and `adr/archive/`) hold only currently valid documents; never mix retired documents with active ones.
- **Classify by role**: organize documents by role (e.g., specification, rule, decision, procedure, reference, investigation, note) rather than by feature area.
- **Flat active folders**: place active documents directly inside their category folder (or directly under `<App>/` when split per application under `Application Scope`); never create `current/` or `active/` subfolders except where lifecycle state itself structures the directory (`investigations/`, `adr/archive/`).
- **Archive vs delete**: archiving removes obsolete documents with historical traceability from active paths while keeping version-control history; delete documents that carry no future reference value.

## Document Responsibilities

- `AGENTS.md`: router holding repository facts, commands, the Applications table, the path of the code map (`Code Map`), and reading instructions — no rule text. A sentence pointing to a rule ("pass the AUDIT gate in `standard.md`") is a reading instruction; a sentence stating an obligation itself ("run tests before committing") is rule text.
- `docs/rules/`: development and change rules (shared rules, stack rules, and application rules; mechanical tooling enforces what it can, and these files govern the obligations code and documents must uphold).
- `docs/specs/`: externally observable behavior the system must exhibit.
- `docs/adr/`: adopted architectural decisions, reasoning, consequences, rejected alternatives, and revisit conditions.
- `docs/guides/`: reproducible working procedures.
- `docs/references/`: durable factual knowledge consulted during work.
- `docs/investigations/`, `docs/notes/`, `docs/plans/`, `docs/inbox/`, and `docs/archive/`: single-purpose roles defined in Category Notes below; never blend them.
- **Input/output test vectors belong in tests**: place exhaustive input → output specification expectations in table-driven test code rather than prose specifications; human-readable reference mapping tables maintained under `docs/references/` follow `Source of Truth` below.

## Writing

Applies to all documents across the repository unless narrowed to normative documents below:

- **State purpose before procedure**: explain *what* and *why* before *how*, making all required 5W1H context explicit instead of leaving it to inference.
- **Distinguish criteria from mechanism**: state the invariant property or goal first, then name any concrete mechanism satisfying it when the document's role permits implementation details (for `docs/specs/`, omit implementation mechanisms per Category Notes); never present temporary tools as the end goal itself.
- **Include numbers only as true criteria**: cite numeric values only when they represent enforceable boundaries (e.g., system limits, protocol thresholds, versions, defaults), never as arbitrary illustrations dressed up as limits.
- **Write contracts, not admonitions**: express obligations and prohibitions verifiably; avoid scolding, reassurance, or commentary about writing.
- **Criteria must be checkable**: specify observable inclusion, exclusion, and completion conditions — never vague adjectives alone (e.g., "simple", "short", "readable", "clean").
- **Normative structure (`docs/rules/`, `docs/specs/`, `docs/adr/`, acceptance criteria)**:
  - **Open with the rule, not an essay**: open every normative section directly with what it requires or decides followed by its conditions — never with reflection, rhetorical questions, or reader-directed filler.
  - **Each item stands alone**: include the requirement and its reason inside the item itself whenever the reason is non-obvious, rather than justifying it merely by analogy or naming another rule.
  - **One item, one verdict**: format rule bullets as `**headword**: condition + required action + reason where non-obvious` so each bullet resolves to a single pass or fail, rather than chaining unrelated rules in one sentence.

### Requirement Text

Applies to every text stating normative requirements (rule files, specifications, acceptance criteria) so two readers applying a requirement to any case reach the same verdict without guessing.

- **Define boundary terms by observable tests**: any term determining whether a rule applies (e.g., "decision", "layer", "external input", "environment") is defined by a verifiable test in the text.
- **State requirements as requirements**: never bury an obligation inside a consequence or rationale clause ("so ...", "which means ...").
- **Label every list's completeness**: mark lists whose membership affects verdicts explicitly as illustrative (`e.g.`) or exhaustive (`only`, `one of`).
- **Make conditional permissions two-way**: whenever granting a permission under a condition, state what holds when the condition fails, and repeat the condition at every subsequent reference.
- **Scope rules by hazard**: scope each requirement to the condition that creates the hazard it prevents (e.g., where a value is used), rather than an incidental property (e.g., where the value originated).
- **Keep one strength per requirement**: ensure a section's lead statement and its items use the same obligation strength, and use "default" (a baseline unless overridden) only alongside who may override it and where. (Built-in fallback defaults for missing configuration values are unaffected.)
- **Specify the property, not a proxy**: state the underlying property being protected as the checkable criterion; measurable proxies (e.g., line counts, keyword checks) appear only as examples unless a number itself is the literal property (e.g., an external system limit).
- **Resolve overlaps explicitly in text**: where two requirements govern the same artifact or boundary, at least one explicitly states how both interact.
- **Locate external facts**: when a verdict depends on external facts (e.g., framework mandates, platform limits), name where those facts are verified or define fallback behavior when unknown.

### Requirement IDs

- **Every requirement carries an ID**: every specification requirement appears as a heading opening with `<ID>: <statement>` (e.g., `### ORD-1: An order without lines is rejected`). Content under that heading up to the next same- or higher-level heading constitutes that requirement; un-IDed headings only group requirements and state none themselves.
- **ID syntax**: `<PREFIX>-<number>` where `<PREFIX>` begins with an uppercase ASCII letter and contains only uppercase ASCII letters and digits (e.g., `ORD-1`, `CLI2-14`).
- **Unique and non-reusable**: each ID uniquely identifies one requirement across the repository's specifications; retired IDs are never reassigned.
- **Legacy migration**: any older specification lacking requirement IDs assigns IDs to all requirements on the first edit that touches it.

### Procedure Design

Applies to every ordered step sequence written for humans or agents (e.g., guides under `docs/guides/`, release procedures, setup checklists, and ordered task plans).

- **Define boundaries first**: fix the exact starting state and goal state before drafting steps, and reorder the sequence on breakdown instead of patching with ad-hoc workarounds.
- **Two-layer structure for multi-stage procedures**: group procedures spanning multiple distinct lifecycle stages (e.g., prepare → change → verify → clean up) under narrative phase headings each covering one stage so the headings show the end-to-end flow; keep single-stage procedures flat without phase headings.
- **Group and justify order**: place related operations adjacent unless dependencies or verification gates demand interleaving, so every step's position is justified by prerequisites, verification, or locality.
- **Explicit step contracts**: each step depends solely on declared preconditions or earlier step outputs and ends with an observable confirmation (e.g., "command exits 0"), never a vague "done". Format steps crossing hosts, contexts, or stateful transitions as `Precondition → Operation → Confirmation`.
- **Name exact operational locations**: state the exact context (e.g., working directory, host, screen, URL) at each step, make transitions explicit steps, and verify real locations against the live environment rather than assuming.
- **Separate automation from human gates**: automate repetitive mechanical tasks in build scripts or tooling, while keeping irreversible actions and critical judgment calls explicit manual steps tagged accordingly (e.g., "requires manual confirmation", "irreversible").

## Directory Layout

```text
AGENTS.md                   router: repository facts, commands, Applications table,
                            code map path, reading instructions — no rule text

docs/
  rules/                    rule bodies: shared rules + stack rules (managed by
                            dev-standards) + application rules
  adr/                      active ADRs
    archive/                superseded / rejected / withdrawn ADRs
  specs/                    specifications: externally observable system behavior
  guides/                   reproducible procedures
  references/               durable repository facts
  investigations/
    active/                 ongoing investigations
    closed/                 finished investigations worth keeping
  notes/                    lightweight, classified valid memos
  plans/                    in-progress work plans (excluded from version control unless enabled)
  inbox/                    unclassified documents awaiting triage
  archive/                  retired non-ADR documents, mirrored by category
    rules/ specs/ guides/ references/ investigations/ notes/ plans/
```

Repositories may add dedicated role subfolders (e.g., `docs/design/`) when multiple documents share a distinct role fitting no standard folder; added categories follow identical placement, archiving, and front-matter rules.

## Application Scope

One scope rule applies across all categories: a document directly under `docs/<category>/` is repository-wide, while a document at `docs/<category>/<App>.md` or under `docs/<category>/<App>/` belongs to that application. Single files and directories are interchangeable per category based on file count, using the exact same application identifier across all categories.

- **Exact application identifier**: choose one identifier per application (matching the project or solution name is recommended, not mandatory) and use it verbatim across filenames and directories, exempt from lowercase kebab-case naming.
- **Mandatory rules/specs pair**: each application declares its `docs/rules/<App>...` and `docs/specs/<App>...` paths explicitly in the root `AGENTS.md` Applications table; splitting other categories per application is optional.
- **Independent ADR numbering**: `docs/adr/` and each `docs/adr/<App>/` maintain separate monotonic sequences spanning active and archived ADRs; retired app-scoped ADRs move to `docs/adr/archive/<App>/`.
- **Retiring an application**: move its authored rules file and specification to `docs/archive/rules/` and `docs/archive/specs/`; never archive dev-standards-managed rule files.

## Placement Decision Table

| Question | Destination |
|---|---|
| Development or change rule? | `docs/rules/` (repository/application rules in application rules file; shared and stack rules managed by dev-standards) |
| Repository fact, command, or routing instruction (no rule text)? | Root `AGENTS.md` (or nested `AGENTS.md` for a subtree) |
| Folder of a feature, or home of a mechanism shared across features? | The code map (`Code Map`) |
| Exhaustive input → output specification test vectors? | Table-driven test code |
| Record of an architectural decision and its rationale? | `docs/adr/` |
| Externally observable system behavior (specification)? | `docs/specs/` |
| Reproducible working procedure? | `docs/guides/` (excluding generic rules already covered in `docs/rules/`) |
| Durable reference fact consulted during work? | `docs/references/` |
| Record of a specific technical investigation? | `docs/investigations/` |
| Valid, lightweight classified memo? | `docs/notes/` |
| In-progress work plan? | `docs/plans/` (finished: `docs/archive/plans/`) |
| Placement undecided? | `docs/inbox/` |
| Retired non-ADR document worth retaining? | `docs/archive/<category>/` |
| Retired ADR? | `docs/adr/archive/` |
| No future reference value? | Delete |

## Category Notes

- **`AGENTS.md` (router)**: holds descriptions, technology stack, Applications table, real commands, the code map path, and reading/AUDIT instructions — zero rule bodies. Never duplicate rule text across `AGENTS.md` and `docs/rules/`.
- **`docs/rules/`**: holds rule bodies across the three tiers defined in `standard.md` (Application rules > Stack rules > Shared rules). Never duplicate rules across files.
- **`docs/specs/`**: specifies externally observable system behavior (e.g., purpose, scope, users and external systems, required behavior, inputs/outputs, error behavior, invariants, non-functional requirements, out of scope — including whichever sections apply to the system) with zero implementation details (no internal classes, libraries, or algorithms). Every requirement carries an ID verified by tests (`testing.md` Requirement Coverage), and decision completeness follows `specs.md`.
- **`docs/adr/`**: records adopted decisions in Nygard structure (`Context`, `Decision`, `Consequences` required; `Alternatives considered`, `Revisit when` when applicable). Superseded ADRs name their successor in `superseded-by` and move to `docs/adr/archive/`, never `docs/archive/`.
- **`docs/guides/`**: holds repository- or application-specific reproducible procedures. Do not duplicate generic procedures already established in shared rule files or external tool documentation; include only repository-specific steps or repository decisions layered atop a shared standard.
- **`docs/references/`**: holds durable facts hard to recover from source alone (e.g., external protocol quirks, auth flows, data mappings, legacy constraints, domain glossary, architecture overviews).
- **`docs/investigations/`**: separates ongoing work (`active/`) from finished reference value (`closed/`, distinct from archive). Promote durable findings on completion: rules → `docs/rules/`, decisions → `docs/adr/`, procedures → `docs/guides/`, facts → `docs/references/`.
- **`docs/notes/` vs `docs/inbox/`**: `inbox/` holds items awaiting classification; `notes/` holds intentionally lightweight valid documents. Placing a document "for now" signals `inbox/`; promote authoritative answers to `references/`.
- **`docs/plans/`**: working area excluded from version control alongside `docs/archive/plans/` unless an explicit application rule under `docs/rules/` enables tracking plans. Repositories tracking plans move completed plans to `docs/archive/plans/` (renaming on collision) before committing.

## Code Map

The code map tells where code lives, so that code holding the same knowledge is found before new code is written (`standard.md` One Home per Piece of Knowledge).

- **Location**: `docs/references/code-map.md`; in a multi-application repository, `docs/references/<App>/code-map.md` for each application (`Application Scope`). `AGENTS.md` names its path and holds no copy of its content.
- **Content**: one line for each feature folder and for each home of a mechanism shared across features (e.g., database connection, logging, configuration loading, test infrastructure), giving its path and the knowledge it holds. It lists folders and homes, not individual types, so adding a type inside an existing folder leaves it unchanged.

## Front Matter

Every document carries YAML front matter with at least `created` and `status`, with four explicit exemptions:

1. Repository-root entry files (e.g., `README.md`, `CHANGELOG.md`, `CLAUDE.md`) and agent routing files (`AGENTS.md`, both repository-root and nested) read directly by external tools or agent harnesses expecting immediate Markdown headings.
2. In-progress plans under `docs/plans/` (front matter added only when archived).
3. ADRs, which omit `created` (sequence numbers and version-control history track chronology) and carry only `status` plus `supersedes`/`superseded-by` when applicable.
4. Managed files under `docs/rules/` distributed verbatim from dev-standards (repository-authored application rules files carry standard front matter).

```yaml
---
status: active
created: 2026-07-15
---
```

### `status` Vocabulary

| Document type | Allowed values |
|---|---|
| ADR | `accepted` / `superseded` / `rejected` / `withdrawn` |
| Investigation | `active` / `closed` / `archived` |
| Everything else | `active` / `archived` |

Do not invent unlisted status values. Permitted optional fields (only these unless application rules extend them; ADRs carry only `supersedes` and `superseded-by` per Exemption 3 above): `last-reviewed`, `topics`, `supersedes`, `superseded-by`.

## Naming

- **Lowercase kebab-case**: name general documents descriptively in lowercase kebab-case (e.g., `database-migration.md`, `authentication-flow.md`); never use content-free names (e.g., `memo.md`, `temp.md`, `note1.md`, `misc.md`).
- **Application identifiers exempt**: `<App>.md` files and `<App>/` directories preserve the exact casing declared in `AGENTS.md`.
- **No sequential numbers for general docs**: rely on version-control history for chronology rather than prefixing `0001-`, except ADRs.
- **ADR sequential IDs**: format ADRs as `NNNN-description.md` using append-only 4-digit zero-padded numbers (`max(docs/adr/, docs/adr/archive/) + 1` per directory scope); never renumber or backfill gaps.
- **Directory casing**: keep documentation infrastructure folders lowercase (`docs/`, `adr/`, `guides/`); source-code folders follow the stack's naming convention.

## Lifecycle

```text
inbox → (rules | adr | specs | guides | references | investigations | notes) → archive → delete when worthless
investigations: active → closed → archive/investigations
adr:            adr/ → adr/archive/
plans:          docs/plans/ → docs/archive/plans/ (or delete)
```

Move documents only along one arrow at a time; finished investigations worth reading move to `closed/`, never straight to `archive/`. Retire documents from active paths as soon as they are superseded or describe obsolete system behavior.

## Archive vs Delete

Archive documents that are no longer valid when their historical context helps trace past incidents or decision rationale. Delete duplicates, spent temporary memos, factually wrong notes with no historical value, or documents wholly superseded by version-control history.

## Source of Truth

When a human-readable reference document (e.g., a mapping table in `docs/references/`) coexists with automated tests, declare the source of truth in the document itself. Precedence: table-driven tests > reference document > current code. Behavior ledgers (`specs.md` Ledgers) record implementation facts, not intended behavior, and are not reference documents under this precedence. Snapshot tests detect unintended change only and are never a source of truth.
