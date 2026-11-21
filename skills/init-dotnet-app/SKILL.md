---
name: init-dotnet-app
description: Scaffold a new .NET application repository in the current directory. Use immediately after `git clone` of an empty repo. Clones the elysion-ii/dev-standards template repository (network required), asks for app type (Console/WPF/WinUI 3/Win32), .NET version, target OS and client packaging choice, optional README/LICENSE, AGENTS.md language, installer UI language (when client packaging applies), and applicable conditional rules, then writes every selected path from `dist/templates/dotnet/mapping.md` (with concrete distributed rule paths resolved in `AGENTS.md`) and copies selected rules from `dist/templates/shared/rules-mapping.md`. Aborts on any file conflict.
allowed-tools: AskUserQuestion, Read, Write, Bash, Glob
---

# init-dotnet-app

Initialize a new .NET application in the current directory (= cloned repo root). Creates a single-`.slnx` solution structure with gated build configuration, optional client packaging (`Installer.ps1`, `Menu.bat`, Inno Setup `.iss`), a concrete `AGENTS.md` router, `docs/references/code-map.md`, selectively distributed shared/stack rules at `docs/rules/`, and skeletons for the application rules file and the specification.

Templates, rules, and mappings come from the public repository **`elysion-ii/dev-standards`**, cloned at its newest release tag. Network access is required; there is no local fallback.

```
STANDARDS_REPO       = https://github.com/elysion-ii/dev-standards.git
STANDARDS_TAG        = the newest semver tag on the remote, resolved in Step 2
MAPPING              = <STD>/dist/templates/dotnet/mapping.md
MAPPING_FORMAT       = 2   (the .NET mapping format this copy of the skill is written for)
RULES_MAPPING        = <STD>/dist/templates/shared/rules-mapping.md
RULES_MAPPING_FORMAT = 1   (the shared rules mapping format this copy of the skill is written for)
```

This skill carries no list of target paths or distributed rule files. Template paths, client-packaging separation, and app-type rule defaults are read from `MAPPING`, and distributed rule entries are read from `RULES_MAPPING` in the clone, so the generated repository always matches the tag being applied.

## Invocation

```
/init-dotnet-app
/init-dotnet-app --name MyApp
```

If `--name` is omitted, the basename of the current directory is used as the default.

---

## Step 1: Establish defaultName

1. Get CWD basename via `Bash`:
   ```bash
   basename "$(pwd)"
   ```
2. If the user's invocation contained `--name <X>`, use `<X>` as `defaultName`. Otherwise use the CWD basename.

---

## Step 2: Clone dev-standards

Resolve `<STANDARDS_TAG>` — the newest `v*` tag on the remote, in semver order:

```bash
git ls-remote --tags --refs --sort=-v:refname <STANDARDS_REPO> 'v*' | head -1 | sed 's#.*refs/tags/##'
```

Confirmation: the command prints one tag name. If it prints nothing, STOP and report — a tag taken from memory or from a local copy scaffolds rules that are silently out of date, so there is no fallback.

Clone that tag into **`./.dev-standards`** — inside the invocation directory, never anywhere else. The invocation directory is where the harness was started and where this skill runs (= the repo root, per **Operational Notes**); the path is relative to it, so every worker and every harness puts the clone in the same place and no clone is left behind in a location nobody looks at:

```bash
test -e .dev-standards && rm -rf .dev-standards          # leftover from an aborted run
git clone --depth 1 --branch <STANDARDS_TAG> <STANDARDS_REPO> .dev-standards
```

Do **not** clone into a temp directory, the home directory, a sibling directory, or any absolute path — and do not reuse a clone that already sits somewhere outside the invocation directory, however current it looks. Confirmation before continuing: `git -C .dev-standards rev-parse --show-toplevel` resolves inside the invocation directory.

`<STD>` below refers to this clone (`./.dev-standards`). If the clone fails, STOP and report — do not scaffold from memory or from any local copy. Confirmation: `<STD>/dist/templates/dotnet/` exists.

Read BOTH `MAPPING` and `RULES_MAPPING` in full:
- Confirm `MAPPING` exists and states `Mapping format: <MAPPING_FORMAT>`.
- Confirm `RULES_MAPPING` exists and states `Mapping format: <RULES_MAPPING_FORMAT>`.

If either file is missing or states another format number, STOP, delete `.dev-standards`, and report: this copy of the skill expects `.NET` mapping format `<MAPPING_FORMAT>` and shared rules mapping format `<RULES_MAPPING_FORMAT>`, and the user obtains the skills again from `<STANDARDS_TAG>` (`skills/` of that tag) before re-running. Do not interpret a mapping of another format.

The clone is untracked and nothing ignores it, so it must be gone before the run ends — see Step 10. If the run aborts at any later step, delete it there too.

---

## Step 3: Conflict detection (abort-on-conflict)

Build the full list of potential target paths from every template section of `MAPPING` (**Always generated**, **Client packaging**, **Type-specific entry points**, **Optional**) and all distributed rule `Target` entries in `RULES_MAPPING`, using `defaultName` for `{{APP_NAME}}`. Then check existence:

```bash
for f in <each target path>; do test -e "$f" && echo "$f"; done
```

If any path exists, STOP and emit:

```
[Abort] One or more target files already exist. The skill does not overwrite.
Conflicts:
  - <path1>
  - <path2>
  ...
Delete the listed files and run /init-dotnet-app again, or start in a fresh empty directory.
```

Do NOT call `AskUserQuestion`. Do NOT write any file. Delete the clone (`rm -rf .dev-standards`) before emitting — an abort must not leave it behind either.

---

## Step 4: Question Round 1 — `AskUserQuestion`

Ask 3 or 4 questions in a single call:

1. **App name** — confirm `defaultName`.
   - Options: `<defaultName>` (Recommended). Free-text via Other for override.
2. **App type** — Console / WPF / WinUI 3 / Win32 P/Invoke
3. **.NET version** — `net10.0` (Recommended) / `net11.0`
4. **Target OS** (ONLY if app type = Console) — Windows-only / Cross-platform

If app type ≠ Console, omit Q4 entirely and set `os = windows` and `clientPackaging = true` automatically. If Console + Cross-platform, set `clientPackaging = false` automatically.

---

## Step 5: Question Round 2 — `AskUserQuestion`

- **When `App type = Console` and `Target OS = Windows-only`**, ask 3 questions in Round 2 (determining `clientPackaging` first):
  - **Q4b (Client packaging)**: Package and distribute to Windows user/operator machines with Inno Setup installer (`clientPackaging = true`) vs Standalone/server build without installer (`clientPackaging = false`)
  - **Q5 (README/LICENSE generation)**: Both / README only / LICENSE only (MIT) / Neither
  - **Q6 (AGENTS.md language)**: English (Recommended) / Japanese
- **When `App type ≠ Console`** (`clientPackaging = true`), ask Q5, Q6, and Q7 in Round 2:
  - **Q5 (README/LICENSE generation)**: Both / README only / LICENSE only (MIT) / Neither
  - **Q6 (AGENTS.md language)**: English (Recommended) / Japanese
  - **Q7 (Installer UI language)**: English (Recommended) / Japanese
- **When `App type = Console` and `Target OS = Cross-platform`** (`clientPackaging = false`), ask Q5 and Q6 in Round 2 (omit Q7 entirely):
  - **Q5 (README/LICENSE generation)**: Both / README only / LICENSE only (MIT) / Neither
  - **Q6 (AGENTS.md language)**: English (Recommended) / Japanese

Q6 and Q7 are independent: Q6 controls developer-facing files (`AGENTS.md`, README, ADR, code map, skeletons), Q7 controls the end-user-facing Inno Setup wizard (`Setup_*.iss`).

---

## Step 6: Question Round 3 — Conditional Rule Selection (`AskUserQuestion`)

Note to the user that all **Universal shared rules** and the default `.NET` core stack rule from `RULES_MAPPING` (`docs/rules/`) are distributed automatically.

- If `App type = Console`, `Target OS = Windows-only`, and Q4b answered `clientPackaging = true`, ask **Q7 (Installer UI language: English (Recommended) / Japanese)** in this call alongside conditional rule selection (keeping total questions in the call ≤ 4).
- Read the app-type default rule selections for Q2/Q4/`clientPackaging` from **Rule distribution** in `MAPPING`, and present every **Conditional shared rule** and conditional `.NET` stack rule from `RULES_MAPPING` with the opening `**Applies when**` paragraph of its source file in the clone via `AskUserQuestion` (`multiSelect: true`, splitting cleanly across 2 multi-select questions in the call so option labels stay concise). Pre-mark the app-type defaults from `MAPPING`.
- For WPF, WinUI 3, and Win32 P/Invoke, the app type itself meets the condition of `client.md` and `dotnet-client.md` (the application runs directly on user machines), so both are distributed without being offered for deselection, and `clientPackaging` stays `true`.
- For Console, keep `clientPackaging` consistent with rule selection: if the user adds `client.md`/`dotnet-client.md` on a Windows-only Console app, confirm enabling `clientPackaging` (and ask Q7 if not yet asked); if the user deselects them, set `clientPackaging = false`. `client.md` and `dotnet-client.md` are selected or deselected together.

---

## Step 7: Compute derived values

### Mapping placeholders

| Placeholder in `MAPPING` | Source |
|---|---|
| `{type}` | Q2: `console` / `wpf` / `winui3` / `win32` |
| `{lang}` | Q6: `en` / `ja` |
| `{ilang}` | Q7 (only when `clientPackaging = true`): `en` / `ja` |
| App type column (**Type-specific entry points**) | Q2 |
| Option column (**Optional**) | Q5: Both = README and LICENSE; README only; LICENSE only; Neither = no row |

### Template tokens

| Token | Source / Rule |
|-------|--------------|
| `{{APP_NAME}}` | Q1 answer |
| `{{TFM}}` | See table below |
| `{{APP_VERSION}}` | Always `0.1.0` |
| `{{APP_TYPE_LABEL}}` | `Console` / `WPF` / `WinUI 3` / `Win32 P/Invoke` |
| `{{APP_UI_DESCRIPTION}}` | See table below |
| `{{APP_ID_GUID}}` | (Only when `clientPackaging = true`) `powershell -Command "[guid]::NewGuid().ToString().ToUpper()"` |
| `{{YEAR}}` | `date +%Y` |
| `{{DATE}}` | `date +%F` (ISO date, used as `created` front matter in rules/spec/code-map skeletons) |
| `{{AUTHOR}}` | (LICENSE only) `git config user.name` if non-empty, else literal `[Author]` |

### TFM rules

| App type | OS | TFM |
|----------|-----|-----|
| Console | Cross-platform | `net{N}.0` |
| Console | Windows-only | `net{N}.0-windows` |
| WPF | (forced Windows) | `net{N}.0-windows` |
| WinUI 3 | (forced Windows) | `net{N}.0-windows10.0.19041.0` |
| Win32 P/Invoke | (forced Windows) | `net{N}.0-windows` |

`{N}` is `10` / `11` from Q3.

### APP_UI_DESCRIPTION

| App type | Value |
|----------|-------|
| Console | `CLI (no UI)` |
| WPF | `WPF (Windows Presentation Foundation)` |
| WinUI 3 | `WinUI 3 (Windows App SDK)` |
| Win32 P/Invoke | `Raw Win32 API via P/Invoke (no UI framework)` |

Notice: if `Cross-platform` Console (`net{N}.0`) builds with `Build.ps1`, remind the user that `Build.ps1`'s default `-Runtime "win-x64"` can be overridden via `-Runtime linux-x64` etc. when needed.

### GUID generation (only when `clientPackaging = true`)

```bash
powershell -Command "[guid]::NewGuid().ToString().ToUpper()"
```

Output is `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` (no surrounding braces, uppercase). Inject this string into the `{{APP_ID_GUID}}` placeholder.

The `Setup.iss.tmpl` templates contain `AppId={{{{APP_ID_GUID}}}` — after substitution it becomes `AppId={{<GUID>}` which is the correct Inno Setup form (literal `{` is escaped as `{{`).

---

## Step 8: Generate files

The targets are the rows of `MAPPING` selected by the answers:
- every row of **Always generated**
- the rows of **Client packaging** ONLY when `clientPackaging = true`
- the rows of **Type-specific entry points** whose App type is Q2
- the rows of **Optional** that Q5 selected

For each selected row:
1. Resolve `{type}`, `{lang}`, and `{ilang}` placeholders in Source (Step 7) and read `<STD>/<Source>`.
2. Process the text in the two passes **Processing** in `MAPPING` defines — conditional blocks by `clientPackaging`, then every `{{TOKEN}}` by its Step 7 value (literal string replace, case-sensitive).
3. Write the result to Target (with `{{APP_NAME}}` replaced).

Use `Bash mkdir -p` to ensure parent directories exist before each `Write`.

Do NOT generate `.claude/CLAUDE.md`, `.claude/rules/`, or `GEMINI.md` — repository rules live in the root `AGENTS.md` only (`CLAUDE.md` is its one-line import; Antigravity reads `AGENTS.md` natively and a `GEMINI.md` would take precedence over it). Never generate a file listed under **Not generated** in `MAPPING` or `RULES_MAPPING`, and never generate unrequested **Client packaging** files when `clientPackaging = false`.

Confirmation: every selected template row has a written target, no client-packaging file exists when `clientPackaging = false`, and no conditional-block marker and no `{{...}}` token remains in any generated file.

---

## Step 9: Distribute rules

**Rules** (single copy — rule bodies live only in `docs/rules/`): from `RULES_MAPPING`, copy verbatim (no token replacement) from `<STD>/<Source>` to `<Target>`:
- every row of **Universal shared rules**
- the `.NET` core stack rule from **Stack rules**
- every conditional shared rule and conditional stack rule selected in Step 6.

These are dev-standards-managed files, copied byte-identical apart from line endings (written with the line ending the generated `.gitattributes` assigns, per **Operational Notes**; git stores them as LF, so the committed content still equals dev-standards) (no in-file marker — `AGENTS.md` marks them as managed); the application rules file, specification, and code map generated in Step 8 are repository-authored.

No skill is copied into the generated repository. `dist/skills/` was retired in dev-standards v4.0.0 — the operational skills dev-standards publishes under `skills/` (`sync-rules`, `init-dotnet-app`, `retrofit-dotnet-app`, `audit-repo`, `specify-app`) are installed in a user's harness, never generated into a repository. Do NOT create `.claude/skills/doc-placement/`, `.claude/skills/merge-pr/`, `.agents/skills/doc-placement/`, or `.agents/skills/merge-pr/` — nor a `standards` skill.

---

## Step 10: Cleanup

Delete the clone:

```bash
rm -rf .dev-standards
```

Confirmation: `test -e .dev-standards` is false. This is mandatory, not tidiness — the clone is untracked and nothing ignores it, so the final report's `git add -A` would commit the whole template repository into the new project.

---

## Step 11: Final report

Emit a summary listing every generated path — the targets written in Steps 8 and 9 — and the next steps. Example:

```
[OK] Initialized {{APP_NAME}} ({{APP_TYPE_LABEL}}, TargetFramework={{TFM}}, ClientPackaging=<yes/no>)
     from dev-standards <STANDARDS_TAG>

Generated templates:
  .gitignore
  .gitattributes
  ...
  docs/references/code-map.md

Distributed rules (docs/rules/):
  <every file copied from RULES_MAPPING>

Next steps:
  1. dotnet restore {{APP_NAME}}/{{APP_NAME}}.csproj
  2. dotnet test {{APP_NAME}}.Tests/{{APP_NAME}}.Tests.csproj
  3. <build/Menu.bat (interactive build, if ClientPackaging=yes) OR powershell -ExecutionPolicy Bypass -File build/Build.ps1>
  4. git add -A && git commit -m "feat: initial scaffolding"
```

For WinUI 3, prepend a hint that the first `dotnet restore` will fetch `Microsoft.WindowsAppSDK` (~tens of MB). Remind the user that whenever the application later adopts another domain capability covered by `RULES_MAPPING`, they can run `/sync-rules` to add those rules and update existing managed rule files.

---

## Operational Notes

- **Token replacement is literal string replace**, after the conditional-block pass (`MAPPING` **Processing**). No escaping logic — templates already handle the only tricky case (`Setup.iss.tmpl` uses `{{{{APP_ID_GUID}}}` to produce Inno Setup's `{{<GUID>}` form).
- **Japanese installer language** requires `Languages\Japanese.isl`, which ships with Inno Setup 6. No extra download is needed.
- **Working directory must be the repo root.** The skill writes everything under CWD. Do not `cd` during execution.
- **The dev-standards clone lives at `./.dev-standards`.** Inside the invocation directory, never a temp directory and never an absolute path, so the clone is always in the one place both the run and the user can find. It is deleted in Step 10 — an untracked clone left in the repo root is swept into the first `git add -A`.
- **No git operations.** The skill does not run `git init`, `git add`, or `git commit`. The user runs those after review.
- **Never touch `core.hooksPath`** — globally or per-repository. The user's own hook setup may live there; a repository-local `core.hooksPath` (husky, lefthook, etc.) silently disables it.
- **Encoding.** All generated files are UTF-8 without BOM.
- **Line endings: every generated text file has the line ending the generated `.gitattributes` assigns it, with no mixed lines** — Step 8 template output and Step 9 rule copies alike: LF, except the file types that file pins to CRLF (the Windows scripts). `.gitattributes` and `.editorconfig` stay exactly as the templates have them. The format gate in `build/Build.ps1` compares every line ending of a C# file with `end_of_line` in `.editorconfig`, so a file written with the other line ending fails the gate on a fresh scaffold. Neither source of the bytes is right on its own: the `Write` tool writes LF, so the CRLF types need converting, and the clone's templates come out LF or CRLF depending on the machine's `core.autocrlf`, so a file copied from the clone needs checking. Git Bash's `sed` drops CR when it reads a file, so a `\r$` pattern never matches there. Confirmation: for every generated file, the CR count is zero — or, for the CRLF types, equals the line count.
