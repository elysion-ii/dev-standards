---
status: active
created: 2026-07-17
---

# dev-standards Repository Rules

Repository-specific rules for working on dev-standards. Deltas and overrides against
the core shared rules in `dist/rules/` — never copy shared rule text here. On conflict,
this file wins.

## Language

- Maintenance documents (`docs/`, `AGENTS.md`, `README.md`), the distributed rules (`dist/rules/`), the rule and scaffold mappings (`dist/templates/shared/rules-mapping.md`, `dist/templates/<stack>/mapping.md`), the opt-in tools (`dist/tools/`), and the published skills (`skills/`) are written in **English** (public repository)
- Localized template variants (`dist/templates/dotnet/ja/`, ...) are deliberately in their target language — they are exempt, per the parity invariant in `docs/specs/dev-standards.md`

## No Private References

- Never reference private, user-specific tooling or paths in **any file in this repository** — not only `dist/`, but every document, including ADRs, guides, and this file itself. Consumers and the public only know the tag interface specified in `docs/specs/dev-standards.md`
- Excluded, for example: personal Claude Code/Codex global skill names and other individual automation tooling, local absolute paths (`C:\Users\...`, a personal `~/...` tree outside this repository), and anything identifying a specific person's machine or account setup
- When a design decision was actually prompted by personal tooling (e.g., an ADR's Context section explaining a maintenance burden), describe the underlying problem generically instead of naming the tool — e.g., "harness-side synchronization tooling" rather than a specific skill name

## Distributed content (`dist/`)

- `dist/rules/` files are **token-free**: concrete commands with real project names live in each consuming repository's `AGENTS.md`, never here
- `dist/rules/` files carry **no front matter and no in-file marker** — they are distributed byte-identical, and consuming repositories detect local edits and retired rules by matching against this repository's tag history. Do not add either
- Templates use literal `{{TOKEN}}` placeholders. Token names are part of the consumption interface: renaming or removing one is a MAJOR change
- Each stack's `dist/templates/<stack>/en/` and `ja/` are variants of the same content and must stay in parity: a change to one is applied to the other in the same commit
- **Every rule, template, and tool file is registered in a mapping**: a file added, renamed, or removed under `dist/rules/` changes `dist/templates/shared/rules-mapping.md` (and any affected stack app-type default table) in the same commit; a file added, renamed, or removed under `dist/templates/` or `dist/tools/` changes `dist/templates/<stack>/mapping.md` (or `rules-mapping.md` if under `shared/`) in the same commit — a row naming its target and class, or an entry under **Not generated**. Run the mapping coverage check in `docs/guides/release.md` before committing such a change
- **A tool is self-contained and documented**: everything a tool under `dist/tools/<tool>/` needs at run time is in its directory or named as a prerequisite in its `README.md`, and the README states which files to copy where, how to run the tool, and what it produces. A change to the tool's behavior updates the README in the same commit
- **A new mechanism inside an existing scaffold file gets a marker row**: a new or changed block in a template that already exists (a build-script step, a required `Directory.Build.props` entry, a hook entry) reaches existing repositories only through retrofit's **Mechanism markers** in the stack's mapping — add or update the marker row in the same commit
- **Each mapping's structure is part of the interface**: a change to sections, columns, placeholders, or retrofit classes in `dist/templates/shared/rules-mapping.md` or `dist/templates/<stack>/mapping.md` that a tool written for the current structure cannot read increments that mapping's `Mapping format` number, is a MAJOR change, and updates the format number stated by the affected published skills in the same commit

## Published skills (`skills/`)

- The published skills hold procedure only — what to clone, ask, write, and confirm. Rule text stays in `dist/rules/`, distributed rule catalogs stay in `dist/templates/shared/rules-mapping.md`, and target paths and mechanism markers stay in the stack's mapping: a skill never carries its own copy of any of them
- The published skills are written in the Claude Code skill format, and `README.md` says so. A change that adds a dependency on another harness-specific feature updates `README.md`'s adaptation notes in the same commit

## Changing this repository

- **Spec-first applies to this repository too**: a change that alters the structure or the distribution/versioning contract updates `docs/specs/dev-standards.md` before (or with) the change
- **Grep before renaming**: when renaming, moving, or deleting any file or section heading, search the whole repository for references and update them in the same commit — `dist/` and `docs/` cross-reference each other, and a stale reference in a distributed file ships to every consumer
- **New or edited document → re-check against No Private References**: before committing any new or edited file under `docs/` (ADRs and guides especially), re-read it against the No Private References rule above — this is the rule most likely to be missed because a personal tool or path name slips in naturally while drafting a Context or rationale section
- **A core change creates no contradiction**: a change to a universal or conditional shared rule file is checked against every other shared rule file before committing. A subject already stated in another shared file is referenced there, never restated
- **New rule → matrix row**: adding a rule to a stack rule file includes its enforcement-matrix row (`Enforced` with the mechanism named solely when 100% mechanically checked, or `AUDIT`)
- **Impact check before editing distributed content**: a change under `dist/` lands in every consuming repository at its next sync or retrofit — classify it against the versioning contract (MAJOR/MINOR/PATCH per the specification) before committing
- **`docs/specs/template-requirements.md` may name concrete .NET mechanisms**: its reference-realization column maps each stack-agnostic requirement to the .NET template set for traceability — a deliberate, authorized exception to `documentation.md`'s no-implementation rule for specifications
- **Rule text goes to `dist/rules/`, never to templates**: template `AGENTS.md` variants carry facts, commands, and routing only. The one exception is the app-rules skeleton (`app-rules.md.tmpl`) — it seeds the repository-authored rules file, the place rule text belongs in a generated repository

## Growing the rule set

Where a new rule goes, and when a new distributed rule file is created. Rationale:
`docs/adr/0006-rebuild-rules-and-selective-distribution.md`.

- **Placement by applicability**: a rule goes to the narrowest file whose readers it binds without exception — one of the four universal shared files (`standard.md`, `documentation.md`, `specs.md`, `testing.md`) when it binds every application; a conditional shared rule file (`cli.md`, `client.md`, `cloud.md`, `configuration.md`, `db.md`, `file-exchange.md`, `remote-calls.md`, `security.md`, `values.md`, `web-api.md`, or a new domain file) when it binds only applications meeting a factual domain or interface condition; a stack rule file when its statement needs a stack's toolchain; the consuming repository's own rules when it needs a product, organization, or that repository's layout. A rule placed wider than its readers is skipped where it does not fit; a rule placed narrower goes unread where it applies
- **Principle versus mechanism**: a rule that spans layers is split — the property goes to a universal or conditional shared rule file, and the mechanism that satisfies it goes to the stack rule file or the template set. A mechanism stated in a shared rule file binds every stack to one toolchain
- **A conditional shared file states its condition first**: the file's opening states `**Applies when**` as a factual condition about the application settled by its code and deployment (e.g., it exposes a CLI, packages a local client app, reads/writes a database). Never phrase a condition as relevance to the current edit, which turns skipping the file into an ad-hoc guess
- **A conditional shared file carries only what its condition requires**: a hazard that can arise in any application even without the domain feature (e.g., unsafe polymorphic deserialization or working-directory-dependent application paths) belongs in `standard.md` (`Authoring distributed rules` — Scope by hazard), never hidden inside a conditional file
- **A new stack rule file needs two samples**: create one in `dist/rules/` only when its rules have been written for at least two consuming repositories on that stack. Until then the rules stay repository-authored in the consuming repository's `docs/rules/`. A stack rule file states mechanisms, and mechanisms drawn from one sample carry that sample's platform and product choices into every consumer. Scope stack files into facets (like `dotnet-client.md` alongside `dotnet.md`) when a large subset of stack rules applies only under a specific conditional shared file
- **A new conditional shared file requires a stack-agnostic domain hazard**: create a new conditional shared file only for an independent operational or architectural hazard domain whose ideals contain zero stack or framework bindings (applicable across multiple stacks); because conditional files are distributed selectively via `dist/templates/shared/rules-mapping.md`, existing unrelated consumers stay unaffected
- **The same rule in two stack rule files moves to shared rules**: when two stack rule files state the same property, the property moves to a universal or conditional shared file and each stack rule file keeps only its mechanism
- **A new distributed rule file reaches every catalog and list**: `dist/templates/shared/rules-mapping.md`, `dist/rules/standard.md` (`How to Use These Rules` — `Missing conditional rules` for conditional shared files), `docs/specs/dev-standards.md` (`Required structure` and `Distribution contract`), `docs/specs/template-requirements.md` R4, and any affected stack mapping's app-type defaults (`dist/templates/<stack>/mapping.md`)
- **A changed `Applies when` updates the `standard.md` list**: the list in `dist/rules/standard.md` (`Missing conditional rules`) repeats the opening of each conditional file's `Applies when`, so a change to that opening updates the list in the same commit

## Rule selection criteria

What qualifies to enter a distributed rule file (`dist/rules/`), before choosing where it goes:

- **Current best practice is the default**: a distributed rule adopts the established current best practice of its subject, except for prose, code comments, and document placement (`documentation.md` and `standard.md` Code Comments), where dev-standards states conventions of its own
- **Opinionated conventions require an engineering advantage and a stated reason**: a rule that departs from or narrows general practice is added only when it provides a concrete engineering advantage (e.g., preventing a real class of defect, operational failure, or review blind spot), and the rule text states that advantage directly
- **Preferences without engineering advantage stay out**: a choice whose alternatives carry no clear engineering superiority (e.g., arbitrary default numbers, fixed filenames where multiple layouts work equally well, stylistic conventions with no defect-prevention benefit) is never written as a rule
- **Application-specific choices stay in specifications or application rules**: decisions that vary by product, audience, or deployment (e.g., log storage paths, log or comment language, retention periods, exact version display formatting) belong in each application's specification or application rules file, never in shared or stack rule files
- **Template tooling stays out of distributed rules**: concrete build scripts, installer scripts, custom template build targets, and scaffold-generated file paths (e.g., a specific build script name, installer directives, a scaffolded ADR path) belong in template comments, never named or described in `dist/rules/`. Every distributed rule must stand on its own in a repository that did not use the scaffold templates

## Authoring distributed rules

How rules under `dist/rules/` are written, in addition to `documentation.md` (`Writing`):

- **Stack-agnostic files state ideals only**: universal and conditional shared rule files state what property to protect, its applicability boundary, and its reason — never stack, library, API, or template names outside illustrative `e.g.` examples. Common mechanisms appear only as `e.g.`, never as mandatory means
- **Stack rule files state means and stack constraints only**: stack rule files state how that stack satisfies the ideals in the shared rule files (referencing the shared rule rather than restating it) plus constraints unique to that stack's toolchain. Never duplicate a shared ideal in a stack rule file
- **Scope by hazard**: place each rule in the narrowest file covering every application exposed to the hazard it prevents (`documentation.md` Writing). A hazard that can occur in any application (e.g., untrusted type-polymorphic deserialization, working-directory-dependent application paths) belongs in `standard.md`, never hidden inside a conditional file that skips unaffected application categories
- **Never add per-rule override clauses**: `standard.md` establishes the three-tier precedence (application rules override stack and shared rules) uniformly across every distributed rule; never add "unless overridden in application rules" to an individual rule, because stating it on one rule implies other rules cannot be overridden (the only exception is a rule that defines a concrete opt-in condition of its own, such as shipping debug symbols for field diagnostics)
- **Enforcement matrix honesty**: in stack rule files, mark a rule `Enforced` only when a mechanical gate enforces the entire rule; any rule with partial mechanical enforcement or manual checks stays `AUDIT` with the enforced and manual parts distinguished (refining New rule → matrix row above)

## Verifying rule changes

Required checks before completing a change to distributed rules (`dist/rules/` or a staging rule directory):

- **Fresh-reader comprehension verification**: any change that adds a rule, moves a rule across files, or alters a rule's meaning or applicability — every edit except pure typo or formatting fixes — is verified by fresh, blank-slate readers (e.g., separate read-only sessions that read only the consuming-application rule bundle, never the conversation history, plan documents, or diff). Test the scenarios whose bundles include the changed files (all scenarios when a change spans multiple universal or conditional files), and repeat with new fresh readers after each edit until a full pass reports zero in-scope defects
- **Pass criterion and defect boundary**:
  - **Pass**: every fresh reader can accurately state what each rule wants to protect (its purpose) without misreading
  - **In-scope defects (must fix)**: (1) a rule whose purpose cannot be determined, (2) a rule whose purpose admits two conflicting readings that change the goal, (3) a contradiction within a file or across files in the bundle, (4) a broken cross-reference to a nonexistent file, heading, or rule ID, and (5) any violation of Rule selection criteria or Authoring distributed rules above
  - **Out of scope (do not fix)**: open implementation means intentionally left to stack rules, application rules, or specifications ("I understand what to protect, but it does not specify which library or path to use"). Never make rule prose convoluted to silence out-of-scope remarks
- **Mechanical checks before completion**: confirm that every edited distributed rule file is English-only, uses LF line endings with a trailing LF, carries no YAML front matter and no `{{TOKEN}}` placeholders, contains no private references or template-tool names, has valid Markdown structure (e.g., a blank line before every `---` horizontal rule), resolves every cross-file heading reference, and keeps stack rule files in sync with their Enforcement Matrix
- **Escalate policy conflicts instead of compromising in prose**: when verification uncovers a conflict or boundary ambiguity that cannot be resolved by wording alone without changing intent, stop and obtain a policy decision rather than inventing a prose compromise

## Testing and specifications (overrides `dist/rules/testing.md`, `dist/rules/specs.md`, and `dist/rules/documentation.md` Requirement IDs)

- This repository is not an application and has no test code: `testing.md` and `documentation.md` Requirement IDs do not apply to its own content, and its specifications (`docs/specs/`) carry no requirement IDs. Both bind the consuming repositories in full
- This repository makes no decisions at run time: `specs.md` does not apply to its own specifications, and it binds the consuming repositories in full
- A distributed script is checked by running it, and the commit that changes the script states how it was run

## Git

- Work directly on `main`: this repository does not branch per ordinary change; commit changes directly when approved

## Releases

- Tags are the consumption interface. Any change to distributed content (`dist/`) or to the published skills (`skills/`) is not consumable until tagged — follow `docs/guides/release.md`. Changes outside both need no tag
