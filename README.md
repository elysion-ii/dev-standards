# dev-standards

Shared engineering standards and project templates, consumed by scaffolding tools
(`init-dotnet-app` / `retrofit-dotnet-app` skills) and distributed into individual
repositories as agent skills.

## Structure

```text
skills/
  standards/
    SKILL.md        Language-agnostic core: code design principles, comment
                    philosophy, testing principles, Git conventions, and the
                    AUDIT procedure run before reporting completion
    dotnet.md       .NET standards with an enforcement matrix (which rules the
                    scaffold enforces mechanically vs. which AUDIT checks)
  doc-placement/
    SKILL.md        Placement, naming, front matter, and archiving rules for
                    all non-source documents

templates/
  AGENTS.md         Generic agent-instruction boilerplate for any repository
  dotnet/
    common/         Language-independent scaffold files (csproj, entry points,
                    build scripts, .editorconfig, Directory.Build.props, ...)
    en/, ja/        Language variants (AGENTS.md, README, ADR-0001, Setup.iss)
```

## Usage

- Scaffolding clones this repository at a **tag** and generates a project from
  `templates/dotnet/common/` plus one language variant. Template files use literal
  `{{TOKEN}}` placeholders replaced at generation time.
- `skills/standards/` and `skills/doc-placement/` are copied into each generated
  repository at `.claude/skills/` (Claude Code) and `.agents/skills/` (Codex,
  Antigravity), so every repository carries the standards it is audited against.
- Each repository's root `AGENTS.md` holds only repository-specific rules and real
  commands; the shared standards live here, once. `CLAUDE.md` in generated
  repositories is a one-line `@AGENTS.md` import.
- The `standards` skill is multi-language by file selection: the core `SKILL.md` is
  language-agnostic, and each `<language>.md` file carries that stack's rules. New
  stacks are added as new files (e.g. `typescript.md`) with the same enforcement-matrix
  format — no editing of existing content.

## Versioning

Tags (`vMAJOR.MINOR.PATCH`) are the consumption interface — scaffolding pins a tag, and
retrofitting means "catch up to tag vX.Y.Z".

- **MAJOR**: restructuring that breaks consumers (moved/renamed files, changed token names)
- **MINOR**: new content (new rules, new language files, new templates)
- **PATCH**: fixes and wording corrections

## License

MIT — see [LICENSE](LICENSE).
