# dev-standards

Shared engineering standards and project templates, consumed by rule-synchronization,
scaffolding, and retrofit tooling that clones this repository at a pinned tag
(`vMAJOR.MINOR.PATCH`).

Everything normative lives in the repository's own documents:

- **What this repository provides** — structure, selective rule distribution,
  versioning: [docs/specs/dev-standards.md](docs/specs/dev-standards.md)
- **Rules for changing it**: [docs/rules/dev-standards.md](docs/rules/dev-standards.md)
- **Release procedure**: [docs/guides/release.md](docs/guides/release.md)
- **Agent instructions** start at [AGENTS.md](AGENTS.md)

## Skills

Five agent skills cover rule management and auditing on any stack, .NET repository
scaffolding and template convergence, and existing-application specification authoring:

| Skill | What it does |
|---|---|
| [`skills/sync-rules/`](skills/sync-rules/SKILL.md) | Initializes `docs/rules/` in a fresh repository or brings an existing repository's `docs/rules/` onto the newest tag (adding newly applicable conditional rules, updating stale files, prompting to retire obsolete rules, and optionally seeding shared starter files from `dist/templates/shared/rules-mapping.md`) |
| [`skills/init-dotnet-app/`](skills/init-dotnet-app/SKILL.md) | Scaffolds a new .NET application repository in the current (empty, freshly cloned) directory with build/test gates, optional client installer packaging, concrete router, code map, and selectively distributed rules |
| [`skills/retrofit-dotnet-app/`](skills/retrofit-dotnet-app/SKILL.md) | Converges an existing .NET repository's scaffolding, build/installer mechanisms, router, code map, docs layout, and staged gates onto the newest tag |
| [`skills/audit-repo/`](skills/audit-repo/SKILL.md) | Audits an entire repository's tracked code, tests, and documents against its local `docs/rules/`, checks for newly exercised conditional domains absent from `docs/rules/`, applies user-approved fixes, and records deferred violations (offline; no network required) |
| [`skills/specify-app/`](skills/specify-app/SKILL.md) | Writes the specification of an existing application from its implementation, to the criteria of [`dist/rules/specs.md`](dist/rules/specs.md), asking the user to confirm what the code alone cannot settle |

At run time `sync-rules`, `init-dotnet-app`, and `retrofit-dotnet-app` clone the newest
tag of this repository and read the rules, templates, shared rules mapping
([`dist/templates/shared/rules-mapping.md`](dist/templates/shared/rules-mapping.md)), and
stack scaffold mapping
([`dist/templates/dotnet/mapping.md`](dist/templates/dotnet/mapping.md)) from that
clone, so network access is required. `audit-repo` and `specify-app` read the rules the
repository already holds under `docs/rules/` and need no network access.

For existing repositories, run `sync-rules` first, then `retrofit-dotnet-app` (for .NET
repositories), then `audit-repo` once rules, router, and gates are in place, then
`specify-app` when the specification does not yet meet `docs/rules/specs.md`. For
non-.NET repositories, run `sync-rules` → `audit-repo` → `specify-app`.

### Getting the skills

Copy the skill directories from the newest tag into your agent harness's skills
directory:

```bash
git clone --depth 1 --branch <newest tag> https://github.com/elysion-ii/dev-standards.git dev-standards-skills
cp -r dev-standards-skills/skills/sync-rules dev-standards-skills/skills/init-dotnet-app dev-standards-skills/skills/retrofit-dotnet-app dev-standards-skills/skills/audit-repo dev-standards-skills/skills/specify-app <your skills directory>/
rm -rf dev-standards-skills
```

Take them from a tag, never from `main`. When a skill reports that the mapping format of
the newest tag differs from the one it was written for, copy the skills again from that
tag.

### Harness format

The skills are written in the **Claude Code** skill format: a `SKILL.md` with
`allowed-tools` in its front matter, asking questions through Claude Code's
`AskUserQuestion` tool. In Claude Code, place them in a personal or project skills
directory as described in the Claude Code documentation and invoke them as
`/sync-rules`, `/init-dotnet-app`, `/retrofit-dotnet-app`, `/audit-repo`, and
`/specify-app`.

For another harness, adapt the harness-specific parts after copying: drop or translate
the `allowed-tools` front matter, and replace each mention of `AskUserQuestion` (and of
the `Read`, `Write`, `Edit`, `Glob`, `Grep`, and `Bash` tools) with that harness's own
way of asking the user and of reading/editing files and running commands. The procedure
itself is harness-neutral.

## Tools

Opt-in tools under [`dist/tools/`](dist/tools/), copied into a repository only when it
needs them. Each directory's README states the prerequisites, what to copy where, how to
run the tool, and what it produces. Take them from a tag, as everything else.

| Tool | What it does |
|---|---|
| [`dist/tools/sqlserver/`](dist/tools/sqlserver/README.md) | Exports SQL Server database schemas into SQL database projects, and builds them into disposable SQL Server test servers (WSL + Docker Engine) |

## License

MIT — see [LICENSE](LICENSE).
