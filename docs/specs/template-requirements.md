---
status: active
created: 2026-07-30
---

# Stack Template Requirements

The stack-agnostic requirements every stack template set must satisfy, so that a
repository generated from it complies with the shared standards. Work through this
document when adding a new stack (a new `dist/rules/<language>.md` plus
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

The .NET template set (`dist/rules/dotnet.md` + `dist/templates/dotnet/`) is the
reference realization; the **.NET realization** column shows how each requirement is
met there. A new stack meets the same requirement with its own toolchain's means —
the mechanism may differ, the guarantee may not.

## What a stack template set consists of

| Part | Content |
|---|---|
| `dist/rules/<language>.md` | The language rule file, opening with an enforcement matrix |
| `dist/templates/<stack>/common/` | Scaffold files identical across natural-language variants |
| `dist/templates/<stack>/en/`, `ja/` | Natural-language variants, in parity (invariant in `docs/specs/dev-standards.md`) |

The agent hook templates under `dist/templates/shared/` are consumed as-is by every
stack — never fork them into a stack directory. The generic `AGENTS.md` in the same
directory serves repositories that have **no** stack template set; a stack template
set always ships its own router variants (R1) and never uses the generic one.

Realization cells abbreviate template paths: `common/...` and `{lang}/...` are
relative to `dist/templates/dotnet/`, where `{lang}` stands for the natural-language
variant directory (`en` or `ja`).

Parts of the requirements bind the scaffolding procedure rather than a template file:
the distribution acts in R4 and R6 (copying rule files, generating the scaffold),
the whole of H4, and in S6 the offering of the choice (the templates themselves are
`dist/`-verifiable). Those parts are verifiable only against a scaffolding
implementation, never against `dist/` — what `dist/` proves is that the files to
distribute exist; that they actually land in a generated repository is the scaffolding
implementation's obligation. Realization cells mark such parts **scaffolding
obligation**; duties that can only be discharged when releasing a template set are
marked **release-check obligation**. Beyond the marked cells, one class of behavior
is always the scaffolding implementation's: where a generated file lands (the root
`CLAUDE.md`, `.claude/settings.json`, ...) and which variant or app-type template is
selected — realization cells name the template sources; target paths and selection
live in the scaffolding implementation. With that understood, everything unmarked is
verifiable against `dist/`.

## 1. Routing and rule distribution

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| R1 | `AGENTS.md` router: stack facts, real commands, Applications table, reading and AUDIT instructions — no rule text. The boundary: a router line may state a trigger and point at the rule body ("spec-first applies — read ..."), and may state facts about maintaining the router files themselves (which file to edit, which files are dev-standards-managed); any other sentence that would still bind on its own if the rule file dropped it is rule text and belongs in `docs/rules/` | `dev-standards.md` Placement model; `documentation.md` Document responsibilities; the boundary criterion: **this document** | `{lang}/AGENTS.md.tmpl` |
| R2 | `CLAUDE.md` at the root is a one-line import of `AGENTS.md`, so both harness entry files route to the same single router | **this document** (each generated router restates it in place) | `dotnet/common/CLAUDE.md.tmpl` |
| R3 | The `AGENTS.md` Commands table names the stack's real commands for format, format check, build, and test; AUDIT step 4 runs the format check, build, and test entries (the plain format command exists to fix code, not to verify it) | `standard.md` How to use §2 (`AGENTS.md` states the concrete commands) and AUDIT step 4; the Commands-table form: **this document** | Commands table in `AGENTS.md.tmpl` |
| R4 | `docs/rules/` receives, verbatim: `standard.md`, `documentation.md`, `git.md`, `cli.md`, and the stack's `<language>.md` | `dev-standards.md` Distribution contract | Scaffolding obligation — copy each file this row selects, byte-identical (never the whole `dist/rules/` directory: other stacks' language files stay out) |
| R5 | Application rules file and specification skeletons: front-mattered, declared as a pair in the Applications table, and the specification skeleton carries the section structure `documentation.md` requires (purpose, scope, users/external systems, behavior, I/O, errors, invariants, non-functional, out of scope) | `dev-standards.md` Distribution contract; `documentation.md` Category notes (`docs/specs/`) and Front matter | `{lang}/app-rules.md.tmpl`, `{lang}/spec.md.tmpl` |
| R6 | When a language rule's rationale lives in an ADR, that ADR is scaffolded into every generated repository so the citation resolves — and the ADR itself conforms to `documentation.md`'s ADR rules (front matter `status` only; body sections Context / Decision / Consequences) | scaffolding: **this document**; ADR conformance: `documentation.md` Category notes (`docs/adr/`) | `{lang}/0001-cancellation-token-plumbing.md.tmpl` for `dotnet.md` CANCEL; landing it in the generated repository is a scaffolding obligation |

## 2. Agent harness wiring

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| H1 | Session-start hook directing the agent to read `docs/rules/` in full before acting, for every harness the shared templates provide hooks for (Claude Code, Codex); harnesses without a hook mechanism rely on the `AGENTS.md` router alone | `dev-standards.md` Required structure (`dist/templates/shared/`); the no-hook fallback: **this document** | `.claude/settings.json`, `.codex/hooks.json` ← `shared/` |
| H2 | Pre-commit hook blocking `git commit` until the AUDIT procedure is confirmed | `dev-standards.md` Required structure | Same files |
| H3 | For each harness that supports a permission allowlist, the allowlist covers the commands the AUDIT procedure runs (format check, build, test), so the mechanical checks run without permission prompts; harnesses without one simply prompt | **this document** | `common/settings.local.json.tmpl` for Claude Code (`dotnet build/test/format/...`) |
| H4 | When the repository is hosted on a service that exposes server-side merge-strategy settings, squash-only is enforced there — the default strategy in `git.md`; without such a host the behavioral rule alone applies; a repository whose application rules file specifies another strategy adjusts the setting to match | `git.md` Merge Strategy (the default); enforcement: **this document** | Scaffolding obligation — a repository setting applied at scaffold time (e.g. `gh repo edit --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false` on GitHub) |

H1 and H2 are stack-agnostic: reuse `dist/templates/shared/` unchanged. A new stack
contributes only H3's command list.

## 3. Mechanical gates

Every stack provides these guarantees. The language file's enforcement matrix
classifies each resulting rule as Enforced (mechanism named) or AUDIT; a stack whose
toolchain cannot enforce one mechanically still states the rule and marks it AUDIT.

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| G1 | A code formatter exists with a single root configuration and a check mode; the check is a build-script gate and a completion condition | `standard.md` How to use §2 and AUDIT step 4 (a formatter with a check mode is presupposed and run); root configuration and build-script wiring: **this document**; `dotnet.md` FORMAT (stack form) | `.editorconfig`; `dotnet format --verify-no-changes` in `Build.ps1` |
| G2 | Static analysis (lint) is configured, enabling at least the toolchain's standard recommended ruleset — an effectively empty diagnostic set does not qualify; warnings fail the build (zero-warnings); disabling the gate wholesale is prohibited; individual diagnostics are suppressed at the narrowest scope with a current reason | `standard.md` AUDIT step 4 (zero-warning build); analysis configuration, no wholesale disabling, suppression discipline: **this document**; `dotnet.md` ANALYZERS (stack form) | `Directory.Build.props`: `AnalysisLevel=latest-recommended`, `EnforceCodeStyleInBuild`, `TreatWarningsAsErrors`; VSTHRD analyzers |
| G3 | Tests run as a gate before any distributable artifact is produced | **this document** (generic); `dotnet.md` OUTPUT (stack form) | `Build.ps1`: format check → tests → publish; `dotnet.md` OUTPUT requires distributables to come only from the build scripts |
| G4 | The version is defined in exactly one place and every artifact and displayed value derives from it. The language file enumerates every derivation path the stack's artifacts actually have (e.g. artifact or package metadata, an installer where one exists, the displayed value); each path either carries a build-time guard that fails when the value does not come from the single source, or appears as an AUDIT item with the reason no guard is possible. Fallback constants that mask a missing source value are prohibited — a derivation that cannot obtain the value fails fast | `standard.md` Version Display (display side); single-sourcing: `dotnet.md` VERSION (stack form), generic: **this document** | `<Version>` in `Directory.Build.props`; the installer build injects it and the `.iss` fails with `#error` when not injected; "no `<Version>` in a csproj" has no guard and stays AUDIT (`dotnet.md` VERSION) |
| G5 | Each stack designates its release packaging step — the step that produces what end users receive — and that step fails when `CHANGELOG.md` exists without a heading for the current version. Build steps that emit runnable outputs for development are not release steps and carry no gate | `dotnet.md` VERSION (stack form, including the designation); generic: **this document** | `Installer.ps1` is the designated release step and carries the gate; the EXE from `Build.ps1` is the build output the installer wraps |
| G6 | The displayed version is the bare `AppName X.Y.Z` by default — the application rules file may override the format; absent an override, the toolchain is configured so no build metadata (commit hash, date) is appended | `standard.md` Version Display; `cli.md` VERSIONOUT | `IncludeSourceRevisionInInformationalVersion=false` in `Directory.Build.props` |
| G7 | Build output directories are produced only by the build scripts and are gitignored | `dotnet.md` OUTPUT (stack form); generic: **this document** | `common/gitignore.tmpl` keeps outputs out of normal staging (not forced adds or already-tracked files); produced-only-by-scripts is behavioral (`dotnet.md` OUTPUT, AUDIT) |
| G8 | The distributable leaves nothing behind in a shared location that nothing cleans up: it does not unpack part of itself into a temp directory at run time, and its packaging step ships the whole build output rather than a named artifact — so the delivered file set follows from the dependencies instead of a packaging setting | `dotnet.md` NATIVEDEP (stack form); generic: **this document** | `Directory.Build.props` fails the publish when `IncludeNativeLibrariesForSelfExtract` is enabled; `Setup.iss` ships the publish directory by wildcard; whether a native dependency can be removed altogether is AUDIT (`dotnet.md` NATIVEDEP) |

## 4. Seeded implementation

The scaffold is compliant from its first commit — the gates in §3 have something real
to run against, and the seeded code already satisfies the rules it will be audited
against (S8 turns that claim into a checkable duty).

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| S1 | An executable test suite the G3 gate runs, containing a passing sanity test that conforms to the language file's test rules — a separate test project or an in-package test directory, per the stack's convention | **this document** | `common/csproj/tests.csproj.tmpl` + `common/SanityTest.cs.tmpl` |
| S2 | CLI entry point seeds implement, compliantly with `cli.md`: `--version`/`-V` printing `appname X.Y.Z` from the single version source (mandatory); `--help`/`-h` (recommended by `cli.md`; seeding it is required here); `--` ends option parsing; unknown option → `app: <message>` on stderr with a `--help` hint, exit 2. The version read carries no hardcoded fallback constant — it fails fast when the version metadata is absent; paths the seed cannot guard (a toolchain substituting its own default when the single source is deleted) are G4 AUDIT items | `cli.md` RESERVED, VERSIONOUT, OPTIONS, ERRORMSG, EXITCODES; help seeding and the fail-fast version read: **this document** (G4) | `common/entrypoint/console.Program.cs.tmpl` |
| S3 | GUI entry points display `AppName X.Y.Z` somewhere always reachable, read from the single version source with no hardcoded fallback constant (unguardable toolchain-default paths are G4 AUDIT items) | `standard.md` Version Display; the fail-fast read: **this document** (G4) | WPF/WinUI 3 title bar; Win32 caption |
| S4 | `docs/plans/` and `docs/archive/plans/` are gitignored (plans stay local by default) | `documentation.md` Category notes (`docs/plans/`) | `common/gitignore.tmpl` |
| S5 | Text normalization and encoding policy is pinned at the root: text files are normalized in the Git index, file types that demand a fixed line ending declare it explicitly, and the charset is pinned in the editor/formatter configuration | **this document** | `common/gitattributes.tmpl` (`* text=auto` plus per-type refinements; explicit `eol=` for platform scripts); `common/editorconfig.tmpl` (`charset = utf-8`) |
| S6 | README and LICENSE exist as template variants; whether they are generated is the scaffolding procedure's choice — the template set never forces them | **this document** | Templates: `{lang}/README.md.tmpl`, `common/LICENSE.MIT.tmpl`; offering the choice is a scaffolding obligation |
| S7 | Non-artifact files generated by the stack toolchain, IDEs, and the OS (caches, virtual environments, editor state, `Thumbs.db`/`.DS_Store`) are gitignored | **this document** | `common/gitignore.tmpl` IDE and OS sections |
| S8 | Every template-generated file passes the AUDIT rules that apply to it — core and language file for code, `documentation.md` for documents | **this document** | All of `common/` and `{lang}/`; checking them against the rules is a release-check obligation |
| S9 | A fresh scaffold of every application type and every natural-language variant passes the three gates — the format check, the build, and the tests all exit 0 | `standard.md` AUDIT step 4 (the gates); running them per scaffold combination: **this document** | Release-check obligation — scaffold each combination and run the three commands |

## 5. Language rule file obligations

What `dist/rules/<language>.md` itself must contain.

| ID | Requirement | Stated in | .NET realization |
|----|-------------|-----------|------------------|
| L1 | Opens with an enforcement matrix classifying **every** rule in the file as Enforced (mechanism named) or AUDIT | `standard.md` How to use §4; `docs/rules/dev-standards.md` (new rule → matrix row) | `dotnet.md` matrix |
| L2 | States the stack form of each §3 gate, naming the mechanism where one exists and classifying the rule Enforced or AUDIT accordingly — a partially guarded rule stays AUDIT with its mechanism named | **this document** | FORMAT, ANALYZERS (Enforced); VERSION, OUTPUT (mechanism named, AUDIT) — OUTPUT is the stack form of G3 |
| L3 | Refines `standard.md` Synchronous vs Asynchronous for the stack's concurrency model | `standard.md` (language files refine it) | ASYNC |
| L4 | States the stack's version-management rules: where the single version definition lives and how the displayed value derives from it | `standard.md` Version Display (delegates to the language file) | VERSION |
| L5 | Token-free and free of front matter, like every distributed rule file | `docs/rules/dev-standards.md` Distributed content | — |
| L6 | Every matrix row marked Enforced names a mechanism the template set actually ships — configuration, dependencies, and gate wiring included — and, for each Enforced row, a representative violation fails the build on a fresh scaffold | `standard.md` How to use §4 (Enforced means scaffold-guaranteed); the verification duty: **this document** | `Directory.Build.props` + `.editorconfig` + the VSTHRD package carry ANALYZERS, NAMESPACE, ASYNC; `Build.ps1` wires the FORMAT gate; the fresh-scaffold violation check is a release-check obligation |
| L7 | States the stack's logging rules: where log files go, how they rotate, and a retention policy that bounds what an application keeps — including the default an application overrides only in its own rules file. The limiting axis follows what the stack's logging tooling makes first-class | **this document** | LOGGING |

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
- Router templates (`AGENTS.md` variants) carry facts, commands, and routing only —
  rule text lives in `dist/rules/` (`docs/rules/dev-standards.md`). The app-rules
  skeleton is the exception by design: it seeds the repository-authored rules file,
  the one place rule text belongs in a generated repository
- A new stack template set is a MINOR release (`docs/specs/dev-standards.md`
  Versioning contract)

## Out of scope

- How scaffolding/retrofit tooling is invoked — the consumer's concern
  (`docs/specs/dev-standards.md` Out of scope)
- Stack- and platform-specific implementation choices inside a template set (UI
  frameworks, packaging technology, project defaults): the requirements state what to
  guarantee, never which technology to use
- The content of the shared rule files themselves — governed by
  `docs/specs/dev-standards.md`

## New stack checklist

Confirm every item before releasing a new stack template set:

- [ ] R1–R2: `AGENTS.md` router variant (en/ja) with `CLAUDE.md` one-line import
- [ ] R3: Commands table filled with the stack's real format / format check / build / test commands
- [ ] R4: distribution list covers `standard.md`, `documentation.md`, `git.md`, `cli.md`, `<language>.md`
- [ ] R5: app-rules and spec skeletons — front-mattered, paired in the Applications table, spec sections per `documentation.md`
- [ ] R6: every ADR cited by the language file has a scaffolded, `documentation.md`-conformant template
- [ ] H1–H2: `shared/` hooks reused unchanged
- [ ] H3: permission allowlist lists the AUDIT commands (format check, build, test)
- [ ] H4: squash-only repository setting applied by the scaffolding procedure when the host supports it (default strategy per `git.md`)
- [ ] G1: formatter + root config + check mode wired as a build gate
- [ ] G2: static analysis with zero-warnings gate; suppression tiers defined in the language file
- [ ] G3: tests gate artifact production in the build script
- [ ] G4: single version definition wired to artifacts and display; every derivation path guarded or an AUDIT item with reason; no fallback constants
- [ ] G5: the designated release packaging step gated on the `CHANGELOG.md` heading
- [ ] G6: displayed version bare `X.Y.Z` by default — toolchain appends no metadata
- [ ] G7: build outputs gitignored and produced only by the build scripts
- [ ] G8: no run-time self-unpacking into a shared temp location; the packaging step ships the whole build output
- [ ] S1: sanity test passes on a fresh scaffold and follows the language file's test rules
- [ ] S2–S3: entry-point seeds satisfy `cli.md` / Version Display
- [ ] S4: `docs/plans/` and `docs/archive/plans/` gitignored
- [ ] S5: text normalization and charset pinned at the root
- [ ] S6: README/LICENSE offered as options by the scaffolding procedure, never forced
- [ ] S7: toolchain/IDE/OS-generated non-artifacts gitignored
- [ ] S8: every template-generated file (all of `common/` and `{lang}/`) passes its applicable AUDIT rules
- [ ] S9: fresh scaffolds of every app type and variant pass format check, build, and test (exit 0)
- [ ] L1–L5: language file complete, matrix rows for every rule
- [ ] L6: every Enforced mechanism ships in the scaffold; per Enforced row, a representative violation fails a fresh-scaffold build
- [ ] L7: log location, rotation, and a bounded retention policy stated for the stack
- [ ] §6: en/ja parity, token vocabulary respected, no rule text outside the app-rules skeleton
