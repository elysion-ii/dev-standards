# dev-standards

Shared engineering standards and project templates, consumed by scaffolding tools
(`init-dotnet-app` / `retrofit-dotnet-app` skills). Rule bodies are distributed into
each repository at `docs/rules/`; event-driven procedures (`doc-placement`, `merge-pr`)
are distributed as agent skills.

## Structure

```text
rules/
  standard.md       Language-agnostic core: code design principles, comment
                    philosophy, testing principles, specification rules, Git
                    conventions, and the AUDIT procedure run before reporting
                    completion. Distributed to docs/rules/standard.md
  dotnet.md         .NET standards with an enforcement matrix (which rules the
                    scaffold enforces mechanically vs. which AUDIT checks).
                    Distributed to docs/rules/dotnet.md

skills/
  doc-placement/
    SKILL.md        Placement, naming, front matter, application scope, and
                    archiving rules for all non-source documents
  merge-pr/
    SKILL.md        gh operating procedure for merging PRs (strategy and
                    message rules live in rules/standard.md's Git section)

templates/
  AGENTS.md         Generic router boilerplate for any repository
  dotnet/
    common/         Language-independent scaffold files (csproj, entry points,
                    build scripts, .editorconfig, Directory.Build.props, ...)
    en/, ja/        Language variants (AGENTS.md, README, ADR-0001, Setup.iss,
                    app-rules and spec skeletons)
```

## Placement model

- **`docs/rules/` is the single home of rule bodies**, in three layers applied in
  order: `standard.md` (shared core) → `<language>.md` → `<App>.md` (application
  rules, repository-authored, deltas only). The more specific file wins on conflict.
- **`AGENTS.md` is the only router.** It holds repository facts, real commands, an
  Applications table (application → projects → rules → specification paths), and the
  read/AUDIT instructions — never rule text. `CLAUDE.md` is a one-line `@AGENTS.md`
  import. `AGENTS.md` is read natively by Claude Code, Codex, and Antigravity, so no
  per-tool skill copies of the rules are needed.
- **Application rules pair with a specification**: `docs/rules/<App>...` ↔
  `docs/specs/<App>...`, same identifier, declared in the Applications table. The
  scope rule generalizes to every docs category: directly under `docs/<category>/` =
  repository-wide; `<App>.md` or `<App>/` = application-specific.
- **Managed vs. authored**: distributed files carry a
  `managed by elysion-ii/dev-standards vX.Y.Z` header (the tag in which the file last
  changed) and are never edited in consuming repositories — retrofit updates them from
  a pinned tag. Application rules files and specifications are repository-authored.
- Only `skills/doc-placement/` and `skills/merge-pr/` are still distributed as skills
  (event-driven procedures), copied to `.claude/skills/` (Claude Code) and
  `.agents/skills/` (Codex, Antigravity).

## Usage

- Scaffolding clones this repository at a **tag** and generates a project from
  `templates/dotnet/common/` plus one language variant. Template files use literal
  `{{TOKEN}}` placeholders replaced at generation time.
- `rules/` is copied to the generated repository's `docs/rules/`, and skeletons for
  the application rules file and the specification are generated alongside it.
- New stacks are added as new `rules/<language>.md` files with the same
  enforcement-matrix format — no editing of existing content.

## Versioning

Tags (`vMAJOR.MINOR.PATCH`) are the consumption interface — scaffolding pins a tag, and
retrofitting means "catch up to tag vX.Y.Z".

- **MAJOR**: restructuring that breaks consumers (moved/renamed files, changed token names)
- **MINOR**: new content (new rules, new language files, new templates)
- **PATCH**: fixes and wording corrections

When a release changes a file under `rules/`, update that file's managed header to the
new tag in the same commit.

## License

MIT — see [LICENSE](LICENSE).
