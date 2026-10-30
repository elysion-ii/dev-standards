---
status: active
created: 2026-07-17
---

# dev-standards Repository Rules

Repository-specific rules for working on dev-standards. Deltas and overrides against
the core rules in `dist/rules/` — never copy shared rule text here. On conflict, this file
wins.

## Language

- Maintenance documents (`docs/`, `AGENTS.md`, `README.md`), the distributed rules (`dist/rules/`), the scaffold mappings (`dist/templates/<stack>/mapping.md`), the opt-in tools (`dist/tools/`), and the published skills (`skills/`) are written in **English** (public repository)
- Localized template variants (`dist/templates/dotnet/ja/`, ...) are deliberately in their target language — they are exempt, per the parity invariant in `docs/specs/dev-standards.md`

## No Private References

- Never reference private, user-specific tooling or paths in **any file in this repository** — not only `dist/`, but every document, including ADRs, guides, and this file itself. Consumers and the public only know the tag interface specified in `docs/specs/dev-standards.md`
- Excluded, for example: personal Claude Code/Codex global skill names and other individual automation tooling, local absolute paths (`C:\Users\...`, a personal `~/...` tree outside this repository), and anything identifying a specific person's machine or account setup
- When a design decision was actually prompted by personal tooling (e.g., an ADR's Context section explaining a maintenance burden), describe the underlying problem generically instead of naming the tool — e.g., "harness-side synchronization tooling" rather than a specific skill name

## Distributed content (`dist/`)

- `dist/rules/` files are **token-free**: concrete commands with real project names live in each consuming repository's `AGENTS.md`, never here
- `dist/rules/` files carry **no front matter and no in-file marker** — they are distributed byte-identical, and consuming repositories detect local edits by matching against this repository's tag history. Do not add either
- Templates use literal `{{TOKEN}}` placeholders. Token names are part of the consumption interface: renaming or removing one is a MAJOR change
- Each stack's `dist/templates/<stack>/en/` and `ja/` are variants of the same content and must stay in parity: a change to one is applied to the other in the same commit
- **Every template, rule, and tool file is registered in the stack's mapping**: a file added, renamed, or removed under `dist/templates/`, `dist/rules/`, or `dist/tools/` changes `dist/templates/<stack>/mapping.md` in the same commit — a row naming its target and retrofit class, or an entry under **Not generated**. Run the mapping coverage check in `docs/guides/release.md` before committing such a change
- **A tool is self-contained and documented**: everything a tool under `dist/tools/<tool>/` needs at run time is in its directory or named as a prerequisite in its `README.md`, and the README states which files to copy where, how to run the tool, and what it produces. A change to the tool's behavior updates the README in the same commit
- **A new mechanism inside an existing scaffold file gets a marker row**: a new or changed block in a template that already exists (a build-script step, a required `Directory.Build.props` entry, a hook entry) reaches existing repositories only through retrofit's **Mechanism markers** in the stack's mapping — add or update the marker row in the same commit
- **The mapping's structure is part of the interface**: a change to its sections, columns, placeholders, or retrofit classes that a tool written for the current structure cannot read increments its `Mapping format` number, is a MAJOR change, and updates the `MAPPING_FORMAT` the published skills state in the same commit

## Published skills (`skills/`)

- The published skills hold procedure only — what to clone, ask, write, and confirm. Rule text stays in `dist/rules/`, and target paths and mechanism markers stay in the stack's mapping: a skill never carries its own copy of either
- The published skills are written in the Claude Code skill format, and `README.md` says so. A change that adds a dependency on another harness-specific feature updates `README.md`'s adaptation notes in the same commit

## Changing this repository

- **Spec-first applies to this repository too**: a change that alters the structure or the distribution/versioning contract updates `docs/specs/dev-standards.md` before (or with) the change
- **Grep before renaming**: when renaming, moving, or deleting any file or section heading, search the whole repository for references and update them in the same commit — `dist/` and `docs/` cross-reference each other, and a stale reference in a distributed file ships to every consumer
- **New or edited document → re-check against No Private References**: before committing any new or edited file under `docs/` (ADRs and guides especially), re-read it against the No Private References rule above — this is the rule most likely to be missed because a personal tool or path name slips in naturally while drafting a Context or rationale section
- **A core change creates no contradiction**: a change to a core file is checked against every other core file before committing. A subject already stated in another core file is referenced there, never restated
- **New rule → matrix row**: adding a rule to a stack rule file includes its enforcement-matrix row (Enforced with the mechanism named, or AUDIT)
- **Impact check before editing distributed content**: a change under `dist/` lands in every consuming repository at its next retrofit — classify it against the versioning contract (MAJOR/MINOR/PATCH per the specification) before committing
- **`docs/specs/template-requirements.md` may name concrete .NET mechanisms**: its reference-realization column maps each stack-agnostic requirement to the .NET template set for traceability — a deliberate, authorized exception to `documentation.md`'s no-implementation rule for specifications
- **Rule text goes to `dist/rules/`, never to templates**: template `AGENTS.md` variants carry facts, commands, and routing only. The one exception is the app-rules skeleton (`app-rules.md.tmpl`) — it seeds the repository-authored rules file, the place rule text belongs in a generated repository

## Growing the rule set

Where a new rule goes, and when a new distributed rule file is created. Rationale:
`docs/adr/0003-grow-rules-by-applicability-and-samples.md`.

- **Placement by applicability**: a rule goes to the narrowest file whose readers it binds without exception — the core (`standard.md`, or `documentation.md`/`git.md`/`testing.md` by subject) when it binds every application; a conditional core file when it binds only applications with a property such as exposing a command line or using a database; a stack rule file when its statement needs a stack's toolchain; the consuming repository's own rules when it needs a platform, a product, or that repository's layout. A rule placed wider than its readers is skipped where it does not fit; a rule placed narrower goes unread where it does
- **Principle versus mechanism**: a rule that spans layers is split — the property goes to the core or the conditional core file, and the mechanism that satisfies it goes to the stack rule file or the template set. A mechanism stated in the core binds every stack to one toolchain
- **A conditional core file states its condition first**: the file's opening names the condition under which it applies, as a fact about the application that its code settles (it exposes a command line; it reads or writes a database). A condition phrased as relevance to a task turns skipping the file into a judgment, and a skipped rule goes unapplied
- **A conditional core file carries only what its condition requires**: a rule that also binds applications without the property stays in the core. A core principle moved into a conditional file goes unread by every application the condition excludes
- **A new stack rule file needs two samples**: create one in `dist/rules/` only when its rules have been written for at least two consuming repositories on that stack. Until then the rules stay repository-authored in the consuming repository's `docs/rules/`. A stack rule file states mechanisms, and mechanisms drawn from one sample carry that sample's platform and product choices into every consumer
- **A new conditional core file needs its condition met on two stacks**: create one in `dist/rules/` only when at least two consuming repositories, on at least two stacks, hold applications that meet its condition. A conditional core file states principles only, so the guard is not where its rules were first written but whether the condition spans stacks: a condition met on one stack only describes that stack, and its rules belong in that stack rule file
- **A stack-agnostic principle needs no second sample**: a rule whose statement names no stack, platform, or product may be promoted from a single consuming repository into the core or a conditional core file. The sample count guards against generalizing a mechanism, and such a rule has none to generalize
- **The same rule in two stack rule files moves to the core**: when two stack rule files state the same property, the property moves to the core and each stack rule file keeps only its mechanism. Two copies of one rule drift apart at the next edit
- **A new distributed rule file reaches every list that names the distributed files**: the specification's Required structure and Distribution contract, `docs/specs/template-requirements.md` R4, the router templates, and `documentation.md`'s description of `docs/rules/`. A file missing from a list is not copied, or not read, by whatever follows that list

## Testing (overrides `dist/rules/testing.md` and `dist/rules/documentation.md` Requirement IDs)

- This repository is not an application and has no test code: `testing.md` and `documentation.md` Requirement IDs do not apply to its own content, and its specifications (`docs/specs/`) carry no requirement IDs. Both bind the consuming repositories in full
- A distributed script is checked by running it, and the commit that changes the script states how it was run

## Git

- Work directly on `main`: this repository does not branch per change, so `dist/rules/git.md`'s default of always branching does not apply here

## Releases

- Tags are the consumption interface. Any change to distributed content (`dist/`) or to the published skills (`skills/`) is not consumable until tagged — follow `docs/guides/release.md`. Changes outside both need no tag
