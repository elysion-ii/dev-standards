---
name: init-dotnet-app
description: Scaffold a new .NET application repository in the current directory. Use immediately after `git clone` of an empty repo. Clones the elysion-ii/dev-standards template repository (network required), asks for app type (Console/WPF/WinUI 3/Win32), .NET version, target OS, optional README/LICENSE, AGENTS.md language, and installer UI language, then writes every path the scaffold mapping in the cloned tag (dist/templates/dotnet/mapping.md) selects — Build scripts with test gate, Inno Setup installer, xUnit test project, AGENTS.md router + CLAUDE.md import, docs/rules with the distributed rule files plus app-rules and spec skeletons — and enforces squash-only merges on GitHub. Aborts on any file conflict.
allowed-tools: AskUserQuestion, Read, Write, Bash, Glob
---

# init-dotnet-app

Initialize a new .NET application in the current directory (= cloned repo root). Creates a single-`.slnx` solution structure with Build scripts, Inno Setup installer, the `AGENTS.md` router, the shared rule bodies pre-distributed at `docs/rules/`, and skeletons for the application rules file and the specification.

Templates, rules, and the mapping from each template to the path it generates come from the public repository **`elysion-ii/dev-standards`**, cloned at its newest release tag. Network access is required; there is no local fallback.

```
STANDARDS_REPO = https://github.com/elysion-ii/dev-standards.git
STANDARDS_TAG  = the newest semver tag on the remote, resolved in Step 2
MAPPING        = <STD>/dist/templates/dotnet/mapping.md
MAPPING_FORMAT = 1   (the mapping format this copy of the skill is written for)
```

This skill carries no list of target paths. Every target, its source, and the rules distribution are read from `MAPPING` in the clone, so the paths always match the templates of the tag being applied.

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

Read `MAPPING` in full. Confirmation: it exists and states `Mapping format: <MAPPING_FORMAT>`. If it is missing or states another number, STOP and report: this copy of the skill was written for mapping format `<MAPPING_FORMAT>`, and the user obtains the skills again from `<STANDARDS_TAG>` (the `skills/` directory of that tag) before re-running. Do not interpret a mapping of another format.

The clone is untracked and nothing ignores it, so it must be gone before the run ends — see Step 10. If the run aborts at any later step, delete it there too.

---

## Step 3: Conflict detection (abort-on-conflict)

Build the full list of target paths from every section of `MAPPING` that names a target — **Always generated**, **Type-specific entry points**, **Optional**, and **Distributed rules** — using `defaultName` for `{{APP_NAME}}`. Then check existence:

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

If app type ≠ Console, omit Q4 entirely and set `os = windows` automatically.

---

## Step 5: Question Round 2 — `AskUserQuestion`

Ask 3 questions in one call:

5. **README/LICENSE generation** — Both / README only / LICENSE only (MIT) / Neither
6. **AGENTS.md language** — English (Recommended) / Japanese
7. **Installer UI language** — English (Recommended) / Japanese

Q6 and Q7 are independent: Q6 controls developer-facing files (`AGENTS.md`, README, ADR), Q7 controls the end-user-facing Inno Setup wizard (`Setup_*.iss`).

---

## Step 6: Compute derived values

### Mapping placeholders

| Placeholder in `MAPPING` | Source |
|---|---|
| `{type}` | Q2: `console` / `wpf` / `winui3` / `win32` |
| `{lang}` | Q6: `en` / `ja` |
| `{ilang}` | Q7: `en` / `ja` |
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
| `{{APP_ID_GUID}}` | `powershell -Command "[guid]::NewGuid().ToString().ToUpper()"` (hyphenated, no braces, uppercase) |
| `{{YEAR}}` | `date +%Y` |
| `{{DATE}}` | `date +%F` (ISO date, used as `created` front matter in the rules/spec skeletons) |
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

### GUID generation

```bash
powershell -Command "[guid]::NewGuid().ToString().ToUpper()"
```

Output is `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` (no surrounding braces, uppercase). Inject this string into the `{{APP_ID_GUID}}` placeholder.

The `Setup.iss.tmpl` templates contain `AppId={{{{APP_ID_GUID}}}` — after substitution it becomes `AppId={{<GUID>}` which is the correct Inno Setup form (literal `{` is escaped as `{{`).

---

## Step 7: Generate files

The targets are the rows of `MAPPING` selected by the answers: every row of **Always generated**, the rows of **Type-specific entry points** whose App type is Q2, and the rows of **Optional** that Q5 selected. For each:

1. Resolve the placeholders in the Source path (Step 6) and read `<STD>/<Source>`.
2. Replace every `{{TOKEN}}` with its computed value (literal string replace, case-sensitive).
3. Write the result to the Target path (with `{{APP_NAME}}` replaced).

Use `Bash mkdir -p` to ensure parent directories exist before each `Write`.

Do NOT generate `.claude/CLAUDE.md`, `.claude/rules/`, or `GEMINI.md` — repository rules live in the root `AGENTS.md` only (`CLAUDE.md` is its one-line import; Antigravity reads `AGENTS.md` natively and a `GEMINI.md` would take precedence over it). Never generate a file listed under **Not generated** in `MAPPING`.

Confirmation: every selected row has a written target, and no other file was written.

---

## Step 8: Distribute rules

**Rules** (single copy — rule bodies live only in `docs/rules/`): copy every row of the **Distributed rules** section of `MAPPING` **verbatim** (no token replacement) from `<STD>/<Source>` to the Target.

These are dev-standards-managed files, copied byte-identical apart from line endings (converted to CRLF per **Operational Notes**; git stores them as LF under `* text=auto`, so the committed content still equals dev-standards) (no in-file marker — `AGENTS.md`'s conditional reading instructions mark them as managed); the application rules file and the specification generated in Step 7 are repository-authored.

No skill is copied into the generated repository. `dist/skills/` was retired in dev-standards v4.0.0 — document placement/naming/front-matter rules and the Git/PR procedure now live in `documentation.md` and `git.md`, read conditionally per `AGENTS.md`, not as event-driven skills. The skills dev-standards publishes under `skills/` (this one included) are installed in a user's harness, never generated into a repository. Do NOT create `.claude/skills/doc-placement/`, `.claude/skills/merge-pr/`, `.agents/skills/doc-placement/`, or `.agents/skills/merge-pr/` — nor a `standards` skill, retired earlier in dev-standards v2.0.0.

---

## Step 9: Enforce squash-only merges

If the repository has an `origin` remote on GitHub, run:

```bash
gh repo edit --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false
```

If there is no remote yet or the command fails (e.g., not authenticated for the owner), do not abort — list the command in the final report's next steps instead.

---

## Step 10: Cleanup

Delete the clone:

```bash
rm -rf .dev-standards
```

Confirmation: `test -e .dev-standards` is false. This is mandatory, not tidiness — the clone is untracked and nothing ignores it, so the final report's `git add -A` would commit the whole template repository into the new project.

---

## Step 11: Final report

Emit a summary listing every generated path — the targets written in Steps 7 and 8, in `MAPPING` order — and the next steps. Example:

```
[OK] Initialized {{APP_NAME}} ({{APP_TYPE_LABEL}}, TargetFramework={{TFM}})
     from dev-standards <STANDARDS_TAG>

Generated:
  .gitignore
  .gitattributes
  ...
  <every target written in Steps 7 and 8>

Merge settings: squash-only enforced via gh repo edit  (or: run the command listed below)

Next steps:
  1. dotnet restore {{APP_NAME}}/{{APP_NAME}}.csproj
  2. dotnet test {{APP_NAME}}.Tests/{{APP_NAME}}.Tests.csproj
  3. build/Menu.bat   (interactive build)
  4. git add -A && git commit -m "feat: initial scaffolding"
```

For WinUI 3, prepend a hint that the first `dotnet restore` will fetch `Microsoft.WindowsAppSDK` (~tens of MB).

---

## Operational Notes

- **Token replacement is literal string replace.** No escaping logic — templates already handle the only tricky case (`Setup.iss.tmpl` uses `{{{{APP_ID_GUID}}}` to produce Inno Setup's `{{<GUID>}` form).
- **Japanese installer language** requires `Languages\Japanese.isl`, which ships with Inno Setup 6. No extra download is needed.
- **Working directory must be the repo root.** The skill writes everything under CWD. Do not `cd` during execution.
- **The dev-standards clone lives at `./.dev-standards`.** Inside the invocation directory, never a temp directory and never an absolute path, so the clone is always in the one place both the run and the user can find. It is deleted in Step 10 — an untracked clone left in the repo root is swept into the first `git add -A`.
- **No git operations.** The skill does not run `git init`, `git add`, or `git commit` (`gh repo edit` is a GitHub server-side setting, not a git operation). The user runs those after review.
- **Never touch `core.hooksPath`** — globally or per-repository. The user's own hook setup may live there; a repository-local `core.hooksPath` (husky, lefthook, etc.) silently disables it. Enforcement belongs in server-side settings, analyzers, and CI, never in git hooks.
- **Encoding.** All generated files are UTF-8 without BOM.
- **Line endings: every generated text file is CRLF, with no mixed lines** — Step 7 output and Step 8 rule copies alike. The files follow the template's settings; `.gitattributes` and `.editorconfig` stay exactly as the templates have them. `dotnet format` on Windows writes CRLF wherever it rewrites whitespace, so an LF file fails `build/Build.ps1`'s format gate once the gate rewrites anything in it — the v4.19.0 console `Program.cs` fails on a fresh scaffold. Neither source of the bytes yields CRLF on its own: the `Write` tool writes LF, and the clone's templates come out LF or CRLF depending on the machine's `core.autocrlf`. Git Bash's `sed` drops CR when it reads a file, so a `\r$` pattern never matches there. Confirmation: for every generated file, the CR count equals the line count (`file` omits "with CRLF line terminators" for JSON and `.iss` files, so `file` alone cannot confirm those).
