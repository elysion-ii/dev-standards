---
status: active
created: 2026-07-30
---

# Stack Template Requirements

The stack-agnostic requirements every stack template set must satisfy, so that a
repository generated from it complies with the shared standards. Work through this
document when adding a new stack (a new `dist/rules/<stack>.md` plus
`dist/templates/<stack>/`), and when auditing an existing template set against the
standard.

The distributed rule files state how *code* must behave; much of what makes a
*generated repository* compliant is carried by mechanisms in the template files —
build gates, analyzer configuration, agent hooks, seeded implementations. Some of
those mechanisms realize a requirement that the rule files state only in a
stack-specific form (e.g. `dotnet.md` ANALYZERS): for those, the **Stated in** column
reads "**this document**", meaning this is the only stack-agnostic statement of the
requirement — do not look for it in `standard.md`. Everywhere else the column names
the rule or specification that states it; rule anchors refer to files under
`dist/rules/`. The unqualified name `dev-standards.md` always means the specification
`docs/specs/dev-standards.md`; the repository rules file is always cited with its full
path `docs/rules/dev-standards.md`. Realization cells refer to generated files
(`.editorconfig`, `Directory.Build.props`, `Build.ps1`, ...) by their generated name;
each maps to the template source of the same name under `common/`
(`editorconfig.tmpl`, `Directory.Build.props.tmpl`, `build/Build.ps1.tmpl`, ...).

The .NET template set (`dist/rules/dotnet.md`, `dist/rules/dotnet-client.md`, and
`dist/templates/dotnet/`) is the reference realization; the **.NET realization** column
shows how each requirement is met there. A new stack meets the same requirement with
its own toolchain's means — the mechanism may differ, the guarantee may not.

## What a stack template set consists of

| Part | Content |
|---|---|
| `dist/rules/<stack>.md` (plus conditional stack facet files if needed) | The stack rule file(s), opening with an enforcement matrix |
| `dist/templates/<stack>/common/` | Scaffold files identical across natural-language variants |
| `dist/templates/<stack>/en/`, `ja/` | Natural-language variants, in parity (invariant in `docs/specs/dev-standards.md`) |
| `dist/templates/<stack>/mapping.md` | The scaffold mapping: target path → source for every generated file, app-type rule defaults from `dist/templates/shared/rules-mapping.md`, the retrofit class of each, the files deliberately not generated, and the mechanism markers (`docs/specs/dev-standards.md` Scaffold mapping) |

The shared rule catalog (`dist/templates/shared/rules-mapping.md`) and agent hook
templates (`dist/templates/shared/settings.json.tmpl`, `hooks.json.tmpl`) under
`dist/templates/shared/` are consumed as-is by every stack — never fork them into a
stack directory. The generic `AGENTS.md` in `dist/templates/shared/` serves repositories
that have **no** stack template set; a stack template set always ships its own router
variants (R1) and never uses the generic one.

Realization cells abbreviate template paths: `common/...` and `{lang}/...` are
relative to `dist/templates/dotnet/`, where `{lang}` stands for the natural-language
variant directory (`en` or `ja`).

Parts of the requirements bind the scaffolding procedure rather than a template file:
the distribution acts in R4 and R6 (copying selected rule files, generating the scaffold),
and in S6 the offering of the choice (the templates themselves are `dist/`-verifiable).
Those parts are verifiable only against a scaffolding implementation, never against
`dist/` — what `dist/` proves is that the files to distribute exist; that they actually
land in a generated repository is the scaffolding implementation's obligation. Realization
cells mark such parts **scaffolding obligation**; duties that can only be discharged when
releasing a template set are marked **release-check obligation**. Beyond the marked
cells, one class of behavior is always the scaffolding implementation's: where a
generated file lands (the root `CLAUDE.md`, `.claude/settings.json`, ...) and which
variant, app-type template, or conditional rule file is selected — realization cells name
the template sources; target paths live in the stack's scaffold mapping
(`dist/templates/<stack>/mapping.md`), and rule selection lives in
`dist/templates/shared/rules-mapping.md` (specified in `docs/specs/dev-standards.md`
Scaffold mapping), which tooling reads from the tag it applies. With that understood,
everything unmarked is verifiable against `dist/`.

## 1. Routing and rule distribution

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| R1 | `AGENTS.md` router: stack facts, real commands, Applications table, the path of the code map (`documentation.md` Code Map; `standard.md` One Home per Piece of Knowledge — no inline code map table in `AGENTS.md`), and reading/AUDIT instructions — no rule text. The boundary: a router line may state a trigger and point at the rule body ("spec-first applies — read ..."), and may state facts about maintaining the router files themselves (which file to edit, which files are dev-standards-managed); any other sentence that would still bind on its own if the rule file dropped it is rule text and belongs in `docs/rules/` | `dev-standards.md` Placement model; `documentation.md` Document responsibilities and Code Map; the boundary criterion: **this document** | `{lang}/AGENTS.md.tmpl` |
| R2 | `CLAUDE.md` at the root is a one-line import of `AGENTS.md`, so both harness entry files route to the same single router | **this document** (each generated router restates it in place) | `shared/CLAUDE.md.tmpl` |
| R3 | The `AGENTS.md` Commands table names the stack's real commands for format, format check, build, and test, and has an end-to-end test row (stating that none exists yet in a fresh scaffold, per `testing.md` Test Layers); AUDIT step 4 runs the format check, build, and test entries (the plain format command exists to fix code, not to verify it) | `standard.md` How to Use These Rules and AUDIT step 4; the Commands-table form: **this document** | Commands table in `AGENTS.md.tmpl` |
| R4 | `docs/rules/` receives, verbatim per `dist/templates/shared/rules-mapping.md`: the four universal shared files (`standard.md`, `documentation.md`, `specs.md`, `testing.md`), every applicable conditional shared file (pre-selected by app-type defaults and user selection), and the stack's applicable rule file(s) | `dev-standards.md` Distribution contract | Scaffolding obligation (`init-dotnet-app` / `sync-rules`) — copy each selected file byte-identical, always including universal shared files + `dotnet.md`, plus `dotnet-client.md` and `cli.md`/`client.md`/other conditional shared files when selected (never copy unrelated stack rule files or unselected domain files) |
| R5 | Application rules file, specification, and code map skeletons: front-mattered, the app-rules and specification files declared as a pair in the Applications table, the specification skeleton carrying the section structure `documentation.md` requires (purpose, scope, users/external systems, required behavior, inputs/outputs, error behavior, invariants, non-functional, out of scope), and `docs/references/code-map.md` initialized empty per `documentation.md` Code Map | `dev-standards.md` Distribution contract; `documentation.md` Category Notes (`docs/specs/`), Code Map, and Front Matter | `{lang}/app-rules.md.tmpl`, `{lang}/spec.md.tmpl`, `{lang}/code-map.md.tmpl` |
| R6 | Where a stack scaffold seeds standing stack-level ADRs explaining an up-front architectural discipline required across new applications on the stack, each seeded ADR conforms to `documentation.md` ADR rules (front matter `status` only; body sections Context / Decision / Consequences; token-resolved cleanly) | scaffolding: **this document**; ADR conformance: `documentation.md` Category Notes (`docs/adr/`) and Front Matter | `{lang}/0001-cancellation-token-plumbing.md.tmpl` seeds up-front `CancellationToken` plumbing guidance alongside `dotnet.md` CANCEL; landing it in the generated repository is a scaffolding obligation |
| R7 | The router names every always-distributed rule file (the universal files and the stack's base rule file), the code map, and the application's rules and specification files by their generated paths, and refers to the selectively distributed rule files as the files present under `docs/rules/` without enumerating them — rule synchronization adds and retires those files later, and an enumeration in the router would then state a false fact. Nothing in the router leaves the reader to guess a filename or to resolve a "when distributed" condition | **this document** | `{lang}/AGENTS.md.tmpl` names `docs/rules/standard.md`, `docs/rules/documentation.md`, `docs/rules/specs.md`, `docs/rules/testing.md`, `docs/rules/dotnet.md`, `docs/rules/{{APP_NAME}}.md`, `docs/specs/{{APP_NAME}}.md`, and `docs/references/code-map.md`, and refers to conditional shared and .NET facet rule files as those under `docs/rules/` |

## 2. Agent harness wiring

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| H1 | Session-start hook directing the agent to read `docs/rules/` before acting, for every harness the shared templates provide hooks for (Claude Code, Codex); harnesses without a hook mechanism rely on the `AGENTS.md` router alone | `dev-standards.md` Required structure (`dist/templates/shared/`); the no-hook fallback: **this document** | `.claude/settings.json`, `.codex/hooks.json` ← `shared/` |
| H2 | Pre-commit hook blocking `git commit` until the AUDIT procedure is confirmed | `dev-standards.md` Required structure | Same files |
| H3 | For each harness that supports a permission allowlist, the allowlist covers the commands the AUDIT procedure runs (format check, build, test), so the mechanical checks run without permission prompts; harnesses without one simply prompt | **this document** | `common/settings.local.json.tmpl` for Claude Code (`dotnet build/test/format/...`) |

H1 and H2 are stack-agnostic: reuse `dist/templates/shared/` unchanged. A new stack
contributes only H3's command list.

## 3. Mechanical gates

Every stack provides these guarantees. The stack rule file's enforcement matrix
classifies each resulting rule as `Enforced` (solely when the entire rule is mechanically
enforced) or `AUDIT` (naming every mechanical gate alongside any remaining manual check).

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| G1 | A code formatter exists with a single root configuration and a check mode; the check is a build-script gate and a completion condition | `standard.md` How to Use These Rules, Build Hygiene and Static Analysis, and AUDIT step 4 (a formatter with a check mode is presupposed and run); root configuration and build-script wiring: **this document**; `dotnet.md` FORMAT | `.editorconfig`; `dotnet format --verify-no-changes` in `Build.ps1` |
| G2 | Static analysis (lint) is configured, enabling at least the toolchain's standard recommended ruleset — an effectively empty diagnostic set does not qualify; warnings fail the build (zero-warnings); disabling the gate wholesale is prohibited; individual diagnostics are suppressed at the narrowest scope with a current reason | `standard.md` Build Hygiene and Static Analysis and AUDIT step 4 (zero-warning build); analysis configuration, suppression tiers: **this document**; `dotnet.md` ANALYZERS | `Directory.Build.props`: `AnalysisLevel=latest-recommended`, `EnforceCodeStyleInBuild`, `TreatWarningsAsErrors`; VSTHRD analyzers |
| G3 | Tests run as a gate before any distributable artifact is produced | `standard.md` Build Hygiene and Static Analysis (Gated distributable builds); `dotnet.md` OUTPUT | `Build.ps1`: format check → requirement coverage → tests → publish; `dotnet.md` OUTPUT requires distributables to come only from the build scripts |
| G4 | The version is defined in exactly one place and every artifact and displayed value derives from it. The stack rule file enumerates the derivation path(s); each path either carries a build-time guard that fails when the value does not come from the single source, or appears as an AUDIT item with the reason no guard is possible. Fallback constants that mask a missing source value are prohibited — a derivation that cannot obtain the value fails fast | `standard.md` Version Display; `dotnet.md` VERSION | `<Version>` in `Directory.Build.props`; the installer build injects it and the `.iss` fails with `#error` when not injected; keeping `<Version>` out of individual `.csproj` files stays AUDIT (`dotnet.md` VERSION) |
| G5 | Where a stack designates a release packaging step — the step that produces installer/end-user distribution packages (omitted on stacks or app modes with no installer package) — that step fails when `CHANGELOG.md` exists without a heading for the current version. Build steps that emit runnable outputs for development are not release steps and carry no gate | **this document** (packaging gate) | `Installer.ps1` (generated under **Client packaging** when client packaging applies) carries the `CHANGELOG.md` heading gate; `Build.ps1` wraps no installer gate |
| G6 | The displayed version defaults to the bare product version: the template configures the toolchain so no build metadata (commit hash, date) is appended by default | **this document** (template default); `standard.md` Version Display; `dotnet.md` VERSION | `IncludeSourceRevisionInInformationalVersion=false` in `Directory.Build.props` |
| G7 | Build output directories are produced only by the build scripts and are gitignored | `standard.md` Build Hygiene and Static Analysis; `dotnet.md` OUTPUT | `common/gitignore.tmpl` keeps outputs out of normal staging (not forced adds or already-tracked files); produced-only-by-scripts is behavioral (`dotnet.md` OUTPUT, AUDIT) |
| G8 | The distributable publishes self-contained with minimal footprint (no self-extracting bundles unpacking into shared temporary folders at runtime without cleanup, unneeded dependencies dropped, and `.pdb` debug symbols excluded during build assembly unless the application rules request them), and any packaging step ships the whole build output directory rather than a single named binary | `client.md` Packaging and Distributable Footprint; `dotnet-client.md` NATIVEDEP | All four app types publish side-by-side (`<SelfContained>true</SelfContained>` with no `<PublishSingleFile>`); `Directory.Build.props` fails any publish enabling `IncludeNativeLibrariesForSelfExtract` or `IncludeAllContentForSelfExtract` and strips `.pdb` files via `RemoveSymbolsFromPublish`; when client packaging applies, `Setup.iss` packages `{{APP_NAME}}\*` by wildcard |
| G9 | A configuration file that ships with the application is tracked only as a placeholder template; the build step fails when the real file it derives is under version control, so credentials cannot reach the repository unnoticed | `configuration.md` Configuration Files in the Repository; `dotnet.md` CONFIGFILE | `Build.ps1` derives the real name of every tracked `*.template.*` configuration file and fails when git tracks it; `gitignore.tmpl` ignores `appsettings.json`; deriving the shipped copy and the installer's `onlyifdoesntexist` entry are AUDIT (`dotnet.md` CONFIGFILE) |
| G10 | Where the stack's distribution mechanism installs over an existing installation or removes one, it handles the application being in use: running processes holding installed files are detected, the user is offered a graceful way to close them in interactive mode, nothing is force-closed without explicit user consent, and an unattended (silent) run attempts a graceful close and fails with a non-zero exit code if processes remain open (while a detection failure does not block proceeding) | `client.md` Installation, Update, and Removal; enforcement details: **this document** | When client packaging applies, `Setup.iss` sets `CloseApplications=yes` for interactive/silent update via Restart Manager (no force close, no `restartreplace`), and drives Restart Manager (`RM_SHUTDOWN_GRACEFUL`) from `InitializeUninstall` for removal, returning `False` (non-zero exit) on silent close failure; `AppMutex` is omitted so updates reach Restart Manager recovery cleanly |
| G11 | Static analysis fails the build on every use of an API no code in the repository may call, read from one root list whose entries each carry the message a violation reports. No folder is exempted from the list: an API some code calls for a legitimate purpose stays off it. The scaffold seeds the list with prohibited APIs from the stack rule file | `standard.md` One Home per Piece of Knowledge and Build Hygiene and Static Analysis; `dotnet.md` ANALYZERS and FILEPATH | `Directory.Build.props`: `Microsoft.CodeAnalysis.BannedApiAnalyzers` reading `BannedSymbols.txt`, seeded with `Directory.GetCurrentDirectory` and `Environment.CurrentDirectory` |

## 4. Seeded implementation

The scaffold is compliant from its first commit — the gates in §3 have something real
to run against, and the seeded code already satisfies the rules it will be audited
against (S8 turns that claim into a checkable duty).

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| S1 | An executable test suite the G3 gate runs, containing a passing sanity test that conforms to the stack rule file's test rules — a separate test project or an in-package test directory, per the stack's convention | **this document** | `common/csproj/tests.csproj.tmpl` + `common/SanityTest.cs.tmpl` |
| S2 | CLI entry point seeds implement, compliantly with `cli.md`: `--version`/`-V` printing the application name and version as `AppName X.Y.Z` (the notation the seed uses) from the single version source (mandatory); `--help`/`-h` (seeded here per `cli.md` Help Output and Standard Streams); `--` ends option parsing; unknown option → `app: <message>` on stderr with a `--help` hint, exit 2. The version read carries no hardcoded fallback constant — it fails fast when the version metadata is absent; paths the seed cannot guard (a toolchain substituting its own default when the single source is deleted) are G4 AUDIT items | `cli.md` Reserved and Conventional Options, Version Output, Option Form, Help Output, Standard Streams, Error Messages, Exit Codes; help seeding and fail-fast read: **this document** (G4) | `common/entrypoint/console.Program.cs.tmpl` |
| S3 | GUI entry points display the application name and version as `AppName X.Y.Z` (the same notation as S2) somewhere always reachable, read from the single version source with no hardcoded fallback constant (unguardable toolchain-default paths are G4 AUDIT items) | `standard.md` Version Display; fail-fast read: **this document** (G4) | WPF/WinUI 3 title bar; Win32 caption |
| S4 | `docs/plans/` and `docs/archive/plans/` are gitignored (plans stay local by default) | `documentation.md` Category Notes (`docs/plans/`) | `common/gitignore.tmpl` |
| S5 | Text normalization and encoding policy is pinned at the root: text files are normalized in the Git index; the working-tree line ending is pinned — one default for every text file plus the file types that demand another — so that it never depends on a developer's Git configuration; the editor/formatter configuration states the same line endings; and the charset is pinned in the editor/formatter configuration | **this document** | `common/gitattributes.tmpl` (`* text=auto eol=lf` plus per-type refinements; `eol=crlf` for Windows scripts); `common/editorconfig.tmpl` (`end_of_line = lf` under `[*]`, `end_of_line = crlf` for the same scripts, `charset = utf-8`). The format check (`dotnet format --verify-no-changes`) compares every line ending with `end_of_line`, so a working tree whose line endings differ from it fails the check in every file |
| S6 | README and LICENSE exist as template variants; whether they are generated is the scaffolding procedure's choice — the template set never forces them | **this document** | Templates: `{lang}/README.md.tmpl`, `common/LICENSE.MIT.tmpl`; offering the choice is a scaffolding obligation |
| S7 | Non-artifact files generated by the stack toolchain, IDEs, and the OS (caches, virtual environments, editor state, `Thumbs.db`/`.DS_Store`) are gitignored | **this document** | `common/gitignore.tmpl` IDE and OS sections |
| S8 | Every template-generated file passes the AUDIT rules that apply to it — shared and stack rule files for code, `documentation.md` for documents | **this document** | All of `common/` and `{lang}/`; checking them against the rules is a release-check obligation |
| S9 | A fresh scaffold of every application type, every natural-language variant, and every scaffolding choice that changes generated text or the generated file set (.NET: Console with and without client packaging) passes the three gates — the format check, the build, and the tests all exit 0 | `standard.md` AUDIT step 4 (the gates); running them per scaffold combination: **this document** | Release-check obligation — scaffold each combination and run the three commands |

## 5. Stack rule file obligations

What `dist/rules/<stack>.md` (plus any conditional stack facet files) itself must contain.

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| L1 | Opens with an enforcement matrix classifying **every** rule in the file: marked `Enforced` solely when a mechanical gate enforces the entire rule without manual checks, or `AUDIT` naming every partial mechanical gate alongside any unguarded manual checks | `docs/rules/dev-standards.md` Enforcement matrix honesty and New rule → matrix row | `dotnet.md` matrix; `dotnet-client.md` matrix |
| L2 | States the stack form of each §3 gate, naming the mechanism where one exists and classifying the rule `Enforced` or `AUDIT` per L1 (`AUDIT` whenever gate integrity or edge cases remain manual checks) | **this document** | `FORMAT`, `ANALYZERS`, `NAMESPACE`, `UNUSED`, `DEFERRED`, `VISIBILITY`, `ASYNC`, `FILEPATH`, `VERSION`, `OUTPUT`, `CONFIGFILE` in `dotnet.md`; `XAML-VISIBILITY`, `NATIVEDEP` in `dotnet-client.md` |
| L3 | Refines `standard.md` Synchronous vs Asynchronous for the stack's concurrency model | `standard.md` (stack rules refine it) | `ASYNC`, `CANCEL` in `dotnet.md` |
| L4 | States the stack's version-management means: where the single version definition lives and how the displayed value derives from assembly/package metadata | `standard.md` Version Display | `VERSION` in `dotnet.md` |
| L5 | Token-free and free of front matter, like every distributed rule file | `docs/rules/dev-standards.md` Distributed content | — |
| L6 | Every mechanical gate named in a matrix row's Mechanism column (whether the row is marked `Enforced` or `AUDIT`) actually ships in the template set — configuration, dependencies, and gate wiring included — and a representative violation fails the named gate on a fresh scaffold | `docs/rules/dev-standards.md` Enforcement matrix honesty; verification duty: **this document** | `Directory.Build.props` + `.editorconfig` + `BannedSymbols.txt` + VSTHRD package + `Build.ps1` gates (`dotnet format`, `TreatWarningsAsErrors`, `IDE0130`, `IDE0051`/`52`/`60`, `CA1851`, `CA1515`, `IDE0040`, `VSTHRD002`/`VSTHRD100`, `RS0030`, REQCOV, CONFIGFILE); fresh-scaffold violation check is a release-check obligation |

## 6. Template-set invariants

- Each stack's `en/` and `ja/` variants express the same content
  (`docs/specs/dev-standards.md` Invariants) and change in the same commit
  (`docs/rules/dev-standards.md` Distributed content)
- The authoritative token set is what appears in `dist/templates/**` at a tag
  (`{{TOKEN}}` occurrences); it is part of the consumption contract — additions are
  MINOR, renames and removals MAJOR. Reuse the stack-agnostic tokens where the concept
  matches (`{{APP_NAME}}`, `{{APP_VERSION}}`, `{{DATE}}`, `{{YEAR}}`, `{{AUTHOR}}`);
  a stack may add tokens for stack-specific concepts, as .NET does with `{{TFM}}`,
  `{{APP_TYPE_LABEL}}`, `{{APP_UI_DESCRIPTION}}`, and `{{APP_ID_GUID}}`
- Text that differs by a scaffolding choice is written in the template itself, as
  conditional blocks the stack's mapping defines (.NET: `{{IF_CLIENT_PACKAGING}}`,
  `{{IF_NO_CLIENT_PACKAGING}}`, `{{END_IF}}`, per `dist/templates/dotnet/mapping.md`
  Processing) — never as a token whose value the scaffolding tool composes. The block
  markers are part of the token vocabulary under the same MAJOR/MINOR rules
- Router templates (`AGENTS.md` variants) carry facts, commands, and routing only —
  rule text lives in `dist/rules/` (`docs/rules/dev-standards.md`). The app-rules
  skeleton is the exception by design: it seeds the repository-authored rules file,
  the one place rule text belongs in a generated repository
- A new stack template set is a MINOR release (`docs/specs/dev-standards.md`
  Versioning contract)

## Out of scope

- How rule-sync, scaffolding, or retrofit tooling is invoked — the consumer's concern
  (`docs/specs/dev-standards.md` Out of scope)
- Stack- and platform-specific implementation choices inside a template set (UI
  frameworks, packaging technology, project defaults): the requirements state what to
  guarantee, never which technology to use
- The content of the shared rule files themselves — governed by
  `docs/specs/dev-standards.md`

## New stack checklist

Confirm every item before releasing a new stack template set:

- [ ] Scaffold and rule mappings: `dist/templates/shared/rules-mapping.md` catalogs all distributed rule files for the stack, and `dist/templates/<stack>/mapping.md` names every template and tool file (or lists it as **Not generated**), app-type rule defaults, and mechanism marker rows; the mapping coverage check in `docs/guides/release.md` prints nothing
- [ ] R1–R2: `AGENTS.md` router variant (en/ja) naming the `docs/references/code-map.md` path (with no inline code map table), plus `CLAUDE.md` one-line import
- [ ] R3: Commands table filled with the stack's real format / format check / build / test commands, plus the end-to-end test row
- [ ] R4: scaffolding/sync distribution selects universal 4 (`standard.md`, `documentation.md`, `specs.md`, `testing.md`), applicable conditional shared files, and the stack rule file(s) from `dist/templates/shared/rules-mapping.md`
- [ ] R5: app-rules, specification, and code-map skeletons — front-mattered, app-rules and spec paired in the Applications table, spec sections per `documentation.md`
- [ ] R6: any seeded standing stack-level ADRs conform to `documentation.md` ADR structure and front matter
- [ ] R7: the router names every generated rule, code-map, app-rules, and specification path explicitly
- [ ] H1–H2: `shared/` hooks reused unchanged
- [ ] H3: permission allowlist lists the AUDIT commands (format check, build, test)
- [ ] G1: formatter + root config + check mode wired as a build gate
- [ ] G2: static analysis with zero-warnings gate; suppression tiers defined in the stack rule file
- [ ] G3: tests gate artifact production in the build script
- [ ] G4: single version definition wired to artifacts and display; every derivation path guarded or an AUDIT item with reason; no fallback constants
- [ ] G5: the designated release packaging step gated on the `CHANGELOG.md` heading
- [ ] G6: displayed version bare by default — template configures toolchain to append no build metadata
- [ ] G7: build outputs gitignored and produced only by the build scripts
- [ ] G8: side-by-side self-contained publish without self-extracting temp bundles, unneeded native dependencies dropped, debug symbols excluded, packaging ships the whole build output directory
- [ ] G9: only the placeholder template of a configuration file is tracked; the build fails when the derived real file is under version control
- [ ] G10: installing over and removing a running application is handled — detected, the user is offered graceful closure interactively, nothing force-closed without consent, silent runs attempt graceful closure and exit non-zero if still running
- [ ] S1: sanity test passes on a fresh scaffold and follows the stack rule file's test rules
- [ ] S2–S3: entry-point seeds satisfy `cli.md` / Version Display
- [ ] S4: `docs/plans/` and `docs/archive/plans/` gitignored
- [ ] S5: text normalization, working-tree line endings (the same in both files), and charset pinned at the root
- [ ] S6: README/LICENSE offered as options by the scaffolding procedure, never forced
- [ ] S7: toolchain/IDE/OS-generated non-artifacts gitignored
- [ ] S8: every template-generated file (all of `common/` and `{lang}/`) passes its applicable AUDIT rules
- [ ] S9: fresh scaffolds of every app type, variant, and text-changing scaffolding choice pass format check, build, and test (exit 0)
- [ ] L1–L5: stack rule file(s) complete, honest matrix rows for every rule
- [ ] L6: every named mechanism in the matrix ships in the scaffold, and a representative violation fails the named gate on a fresh scaffold
- [ ] §6: en/ja parity, token vocabulary respected, no rule text outside the app-rules skeleton
