# .NET Scaffold Mapping

Mapping format: 2

The single source of what scaffolding generates from the .NET template set, and of the
template/mechanism target state retrofit converges an existing repository onto.
Scaffolding and retrofit tooling read this file from the tag they apply, so the mapping
always matches that tag's templates. Distributed rule files (`dist/rules/`) and generic
non-stack starter files are cataloged separately in `dist/templates/shared/rules-mapping.md`
and synchronized by `sync-rules`.

This file is read by tooling, never generated into a repository (see **Not
generated**).

## Format

- **Mapping format** above is the number of the structure tooling reads: the sections,
  their columns, the placeholders, and the retrofit classes below. It increments when
  that structure changes incompatibly — a MAJOR change per the versioning contract in
  `docs/specs/dev-standards.md`. A tool that reads a different number than it was
  written for stops instead of guessing
- **Source** paths are relative to the root of dev-standards. Every path under `dist/`
  that this file names is written in full, in backticks
- **Target** paths are relative to the root of the generated repository. `{{APP_NAME}}`
  in a target is replaced like every other template token
- Placeholders in a Source path select a variant:

  | Placeholder | Values | Selected by |
  |---|---|---|
  | `{type}` | `console` / `wpf` / `winui3` / `win32` | the app type (Console / WPF / WinUI 3 / Win32 P/Invoke) |
  | `{lang}` | `en` / `ja` | the language of developer-facing documents (`AGENTS.md`, README, ADR, code map, rules and spec skeletons) |
  | `{ilang}` | `en` / `ja` | the language of the end-user-facing installer wizard (only when client packaging applies) |

- **Processing**: every row in **Always generated**, **Type-specific entry points**,
  **Client packaging**, and **Optional** is generated in two passes:
  1. **Conditional blocks.** A template may carry blocks whose text depends on whether
     client packaging applies. A block opens with a line that holds only
     `{{IF_CLIENT_PACKAGING}}` or only `{{IF_NO_CLIENT_PACKAGING}}`, and closes with the
     next line that holds only `{{END_IF}}`; blocks do not nest. When the block's
     condition holds, only its two marker lines are removed; otherwise the marker lines
     and every line between them are removed. Whether client packaging applies is the
     same decision that selects the **Client packaging** rows
  2. **Tokens.** Every `{{TOKEN}}` is replaced by literal string replacement

  No marker or token remains in a generated file. Distributed rule files selected from
  `dist/templates/shared/rules-mapping.md` are copied verbatim with no processing.
- **Retrofit class** assigns every target to the scope retrofit reconciles it in:

  | Class | What falls in it |
  |---|---|
  | mechanism | configuration, build scripts, harness settings, and the router |
  | authored | the application rules file, the specification, and the code map — ensured to exist, then maintained by the repository |
  | substance | the application's own code and content — retrofit never diffs it against a template or overwrites it from one; `audit-repo` audits existing code against the local `docs/rules/` |

## Always generated

| Target | Source | Retrofit class |
|---|---|---|
| `.gitignore` | `dist/templates/dotnet/common/gitignore.tmpl` | mechanism |
| `.gitattributes` | `dist/templates/dotnet/common/gitattributes.tmpl` | mechanism |
| `.editorconfig` | `dist/templates/dotnet/common/editorconfig.tmpl` | mechanism |
| `Directory.Build.props` | `dist/templates/dotnet/common/Directory.Build.props.tmpl` | mechanism |
| `BannedSymbols.txt` | `dist/templates/dotnet/common/BannedSymbols.txt.tmpl` | mechanism |
| `{{APP_NAME}}.slnx` | `dist/templates/dotnet/common/solution.slnx.tmpl` | substance |
| `AGENTS.md` | `dist/templates/dotnet/{lang}/AGENTS.md.tmpl` | mechanism |
| `CLAUDE.md` | `dist/templates/shared/CLAUDE.md.tmpl` | mechanism |
| `{{APP_NAME}}/{{APP_NAME}}.csproj` | `dist/templates/dotnet/common/csproj/{type}.csproj.tmpl` | substance |
| `{{APP_NAME}}.Tests/{{APP_NAME}}.Tests.csproj` | `dist/templates/dotnet/common/csproj/tests.csproj.tmpl` | substance |
| `{{APP_NAME}}.Tests/SanityTest.cs` | `dist/templates/dotnet/common/SanityTest.cs.tmpl` | substance |
| `build/Build.ps1` | `dist/templates/dotnet/common/build/Build.ps1.tmpl` | mechanism |
| `docs/rules/{{APP_NAME}}.md` | `dist/templates/dotnet/{lang}/app-rules.md.tmpl` | authored |
| `docs/specs/{{APP_NAME}}.md` | `dist/templates/dotnet/{lang}/spec.md.tmpl` | authored |
| `docs/references/code-map.md` | `dist/templates/dotnet/{lang}/code-map.md.tmpl` | authored |
| `docs/adr/0001-cancellation-token-plumbing.md` | `dist/templates/dotnet/{lang}/0001-cancellation-token-plumbing.md.tmpl` | substance |
| `.claude/settings.local.json` | `dist/templates/dotnet/common/settings.local.json.tmpl` | mechanism |
| `.claude/settings.json` | `dist/templates/shared/settings.json.tmpl` | mechanism |
| `.codex/hooks.json` | `dist/templates/shared/hooks.json.tmpl` | mechanism |

## Client packaging

Generated by `init-dotnet-app` and converged by `retrofit-dotnet-app` **only** when
client packaging applies to the repository — i.e., `client.md` and `dotnet-client.md`
are distributed (WPF, WinUI 3, Win32 P/Invoke, or Windows-only Console packaged for user
machines) or an existing repository already uses the installer scripts. Server/Web API
and standalone/cross-platform Console repositories omit these targets.

| Target | Source | Retrofit class |
|---|---|---|
| `build/Installer.ps1` | `dist/templates/dotnet/common/build/Installer.ps1.tmpl` | mechanism |
| `build/Menu.bat` | `dist/templates/dotnet/common/build/Menu.bat.tmpl` | mechanism |
| `build/Setup_{{APP_NAME}}.iss` | `dist/templates/dotnet/{ilang}/Setup.iss.tmpl` | mechanism |

## Type-specific entry points

Only the rows of the selected app type are generated.

| App type | Target | Source | Retrofit class |
|---|---|---|---|
| Console | `{{APP_NAME}}/Program.cs` | `dist/templates/dotnet/common/entrypoint/console.Program.cs.tmpl` | substance |
| WPF | `{{APP_NAME}}/App.xaml` | `dist/templates/dotnet/common/entrypoint/wpf.App.xaml.tmpl` | substance |
| WPF | `{{APP_NAME}}/App.xaml.cs` | `dist/templates/dotnet/common/entrypoint/wpf.App.xaml.cs.tmpl` | substance |
| WPF | `{{APP_NAME}}/MainWindow.xaml` | `dist/templates/dotnet/common/entrypoint/wpf.MainWindow.xaml.tmpl` | substance |
| WPF | `{{APP_NAME}}/MainWindow.xaml.cs` | `dist/templates/dotnet/common/entrypoint/wpf.MainWindow.xaml.cs.tmpl` | substance |
| WinUI 3 | `{{APP_NAME}}/App.xaml` | `dist/templates/dotnet/common/entrypoint/winui3.App.xaml.tmpl` | substance |
| WinUI 3 | `{{APP_NAME}}/App.xaml.cs` | `dist/templates/dotnet/common/entrypoint/winui3.App.xaml.cs.tmpl` | substance |
| WinUI 3 | `{{APP_NAME}}/MainWindow.xaml` | `dist/templates/dotnet/common/entrypoint/winui3.MainWindow.xaml.tmpl` | substance |
| WinUI 3 | `{{APP_NAME}}/MainWindow.xaml.cs` | `dist/templates/dotnet/common/entrypoint/winui3.MainWindow.xaml.cs.tmpl` | substance |
| Win32 P/Invoke | `{{APP_NAME}}/Program.cs` | `dist/templates/dotnet/common/entrypoint/win32.Program.cs.tmpl` | substance |

## Optional

Generated only when the scaffolding user selects the file.

| Option | Target | Source | Retrofit class |
|---|---|---|---|
| README | `README.md` | `dist/templates/dotnet/{lang}/README.md.tmpl` | substance |
| LICENSE (MIT) | `LICENSE` | `dist/templates/dotnet/common/LICENSE.MIT.tmpl` | substance |

## Rule distribution

`dist/templates/shared/rules-mapping.md` is the single catalog of every distributed rule
file under `dist/rules/`. On new `.NET` repositories, `init-dotnet-app` copies the four
**Universal shared rules** and `.NET` `dotnet.md` unconditionally, pre-selects the app-type
defaults below, and offers all remaining **Conditional shared rules** from
`dist/templates/shared/rules-mapping.md` for user selection. On existing repositories,
`sync-rules` synchronizes `docs/rules/`.

| App type / Packaging | Default additional rules from `rules-mapping.md` | Client packaging |
|---|---|---|
| Console (Cross-platform) | `cli.md` | No |
| Console (Windows-only, standalone without installer) | `cli.md` | No |
| Console (Windows-only, packaged with installer) | `cli.md`, `client.md`, `dotnet-client.md` | Yes |
| WPF / WinUI 3 / Win32 P/Invoke | `client.md`, `dotnet-client.md` (required, not offered for deselection: the app type meets their condition) | Yes |

## Not generated

Files under `dist/` that the .NET template set deliberately does not generate (excluding
`dist/rules/` and `dist/templates/shared/rules-mapping.md`, which are cataloged by
`dist/templates/shared/rules-mapping.md`).

| Source | Reason |
|---|---|
| `dist/templates/shared/AGENTS.md` | the generic router for repositories without a stack template set; the .NET set ships its own router variants |
| `dist/templates/dotnet/mapping.md` | this file — read by tooling, never generated |
| `dist/tools/sqlserver/README.md` | opt-in tool: a repository copies the tool's files when it adopts the tool, as this README directs |
| `dist/tools/sqlserver/Export-Schema.ps1` | opt-in tool (see `dist/tools/sqlserver/README.md`) |
| `dist/tools/sqlserver/Export-Schema.bat` | opt-in tool (see `dist/tools/sqlserver/README.md`) |
| `dist/tools/sqlserver/export-schema.template.json` | opt-in tool (see `dist/tools/sqlserver/README.md`) |
| `dist/tools/sqlserver/.gitignore` | opt-in tool (see `dist/tools/sqlserver/README.md`) |
| `dist/tools/sqlserver/Setup-SqlServerHost.ps1` | opt-in tool (see `dist/tools/sqlserver/README.md`) |
| `dist/tools/sqlserver/Start-TestSqlServer.ps1` | opt-in tool (see `dist/tools/sqlserver/README.md`) |
| `dist/tools/sqlserver/Stop-TestSqlServer.ps1` | opt-in tool (see `dist/tools/sqlserver/README.md`) |

## Mechanism markers

How retrofit recognizes that a template-carried mechanism is already applied in an
existing file. Present = applied; absent = port the template's block into the existing
file, preserving project-specific content around it. `{{APP_NAME}}` in this table is
the application's name. Rows marked **(Client packaging only)** apply solely when client
packaging applies to the repository.

| File | Marker | Port source |
|---|---|---|
| `build/Build.ps1` | a `dotnet format` verification call before `dotnet test` | the `Verifying code format...` block of `Build.ps1.tmpl` (`{{APP_NAME}}` → the application's name) |
| `build/Build.ps1` | a `Verifying configuration files...` block failing when git tracks the real name derived from a tracked `*.template.*` file | the template's block. Where the project carries a placeholder under another name (`*.sample.*`, `*.example.*`), rename it to `<name>.template.<ext>` and update the build-script and installer references. Where the real file is **tracked**, `git rm --cached` it in the same commit and report it prominently — it may carry credentials, and they stay in history (`dotnet.md` CONFIGFILE) |
| `Directory.Build.props` | `Microsoft.VisualStudio.Threading.Analyzers` PackageReference | the template's VSTHRD block. **Special rules:** never add `<TreatWarningsAsErrors>` here — it is enabled only after the build has been measured warning-free. Add `<Nullable>`/`<ImplicitUsings>` (and remove them from csprojs) only if **every** csproj already sets them; otherwise leave per-csproj and report — enabling Nullable on legacy code is separate work |
| `Directory.Build.props` | `Microsoft.CodeAnalysis.BannedApiAnalyzers` PackageReference and an `AdditionalFiles` item naming `BannedSymbols.txt` | the template's BannedApiAnalyzers block. **Staged:** before porting it into a build that already treats warnings as errors, build with the block once and report every RS0030 it raises — existing uses of the APIs `BannedSymbols.txt` bans; port the block once those uses are replaced (`dotnet.md` ANALYZERS, FILEPATH) |
| `BannedSymbols.txt` | every entry of the template's list is present, and no `.editorconfig` section suppresses RS0030 | add missing entries; never remove existing ones without asking. Report each `.editorconfig` section that suppresses RS0030 together with the entries it exempts: RS0030 is never suppressed, so an API that some code calls for a legitimate purpose belongs off the list (`dotnet.md` ANALYZERS) |
| `Directory.Build.props` | `IncludeSourceRevisionInInformationalVersion` property set to `false` | the template's version block (keeps `AssemblyInformationalVersion` equal to `<Version>` by default so the displayed version carries no commit hash — see `dotnet.md` VERSION and `standard.md` Version Display) |
| `Directory.Build.props` | a `RemoveSymbolsFromPublish` target that drops every `.pdb` from `@(ResolvedFileToPublish)` | the template's target (keeps publish outputs free of `.pdb` symbols by default, and satisfies `dotnet-client.md` NATIVEDEP when client packaging applies) |
| `Directory.Build.props` | a `ForbidSelfExtractingPublish` target that errors when `IncludeNativeLibrariesForSelfExtract` or `IncludeAllContentForSelfExtract` is set | the template's guard target (blocks single-file temp-folder self-extraction, and satisfies `dotnet-client.md` NATIVEDEP when client packaging applies) |
| `build/Build.ps1` | a `Verifying requirement coverage...` block failing when a requirement ID from a `docs/specs/` heading appears in no `.cs` file under a `*Tests` directory, or when a `[Trait("Requirement", ...)]` names an ID no specification states | the template's block. **Staged:** before enabling it, run the block's check alone and report the IDs it lists; add the missing references (or, for a specification without IDs, leave it to `documentation.md` Requirement IDs, Legacy migration), then port the block. Where the test projects are not top-level `*Tests` directories, adjust only the directory selection (`dotnet.md` REQCOV) |
| `build/Installer.ps1` *(Client packaging only)* | reads the version from `Directory.Build.props` and passes `/DMyAppVersion` to ISCC | the version-read + CHANGELOG-gate blocks (after the ISCC existence check), preserving project-specific `/D` arguments |
| `build/Setup_{{APP_NAME}}.iss` *(Client packaging only)* | `#ifndef MyAppVersion` guard and **no** `#define MyAppVersion` | the guard block from `Setup.iss.tmpl`; delete the local `#define` |
| `build/Setup_{{APP_NAME}}.iss` *(Client packaging only)* | the `[Files]` section ships the whole publish directory (wildcard `Source`), not a named executable | the `[Files]` block from `Setup.iss.tmpl`, keeping project-specific entries such as a user-config file installed with `onlyifdoesntexist` (`dotnet-client.md` NATIVEDEP) |
| `.claude/settings.local.json` | permissions.allow ⊇ the template's entries | add missing entries; never remove existing ones |
| `.claude/settings.json`, `.codex/hooks.json` | the shared templates' session-start and pre-commit hook entries | merge the missing hook entries; never remove existing ones |
| `AGENTS.md` | router shape: facts, commands, Applications table, Code Map path, always-distributed rule files named by path with selectively distributed ones referred to as the files under `docs/rules/` (never enumerated), the build text of the repository's `clientPackaging` state, read/AUDIT instructions, **no rule text** | reshape per `{lang}/AGENTS.md.tmpl` when rule text is consolidated (rule text found here is consolidation input, not a deletion target) |
| `AGENTS.md` | a Code Map section naming `docs/references/code-map.md` and carrying **no** inline Shared Knowledge table | the section from `{lang}/AGENTS.md.tmpl`, paired with `docs/references/code-map.md` (`{lang}/code-map.md.tmpl`). Where the existing `AGENTS.md` carries an inline `Shared Knowledge` table, migrate valid feature-folder and shared-mechanism rows (`standard.md` One Home per Piece of Knowledge; `documentation.md` Code Map) into `docs/references/code-map.md` and drop entries that name individual types without shared knowledge (report duplicates instead of listing) |
| `CLAUDE.md` | contains exactly `@AGENTS.md` | rewrite after rule text is consolidated |
| `.editorconfig`, `.gitignore`, `.gitattributes` | byte-equal or a recognizable superset of the template (including `IDE0130 = warning` and updated `VAR` suggestion entries) | equal/superset: skip; otherwise *ask* with the diff. An `.editorconfig` section that suppresses RS0030 never makes a superset: it is reported as the `BannedSymbols.txt` row states. **Line endings:** `eol=` in `.gitattributes` and `end_of_line` in `.editorconfig` are ported together, with the same values, or not at all. When the run changes either, report prominently that Git does not rewrite the files already checked out: every existing clone, the one the run worked in included, re-checks out its working tree once, after the change is committed and with no uncommitted work (`git rm -r -q --cached . && git reset -q --hard`). Until a clone does, the format check reports ENDOFLINE in every file whose working copy has the other line ending, and `dotnet format` fixes only the C# files among them |
