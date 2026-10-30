# dev-standards

Shared engineering standards and project templates, consumed by scaffolding and
retrofit tooling that clones this repository at a pinned tag (`vMAJOR.MINOR.PATCH`).

Everything normative lives in the repository's own documents:

- **What this repository provides** — structure, distribution contract, versioning:
  [docs/specs/dev-standards.md](docs/specs/dev-standards.md)
- **Rules for changing it**: [docs/rules/dev-standards.md](docs/rules/dev-standards.md)
- **Release procedure**: [docs/guides/release.md](docs/guides/release.md)
- **Agent instructions** start at [AGENTS.md](AGENTS.md)

## Scaffolding skills

Two agent skills apply the .NET template set:

| Skill | What it does |
|---|---|
| [`skills/init-dotnet-app/`](skills/init-dotnet-app/SKILL.md) | Scaffolds a new .NET application repository in the current (empty, freshly cloned) directory |
| [`skills/retrofit-dotnet-app/`](skills/retrofit-dotnet-app/SKILL.md) | Converges an existing .NET repository onto the newest tag, interactively |

At run time each skill clones the newest tag of this repository and reads the templates,
the rules, and the scaffold mapping
([`dist/templates/dotnet/mapping.md`](dist/templates/dotnet/mapping.md)) from that
clone, so network access is required.

### Getting the skills

Copy both skill directories from the newest tag into your agent harness's skills
directory:

```bash
git clone --depth 1 --branch <newest tag> https://github.com/elysion-ii/dev-standards.git dev-standards-skills
cp -r dev-standards-skills/skills/init-dotnet-app dev-standards-skills/skills/retrofit-dotnet-app <your skills directory>/
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
`/init-dotnet-app` and `/retrofit-dotnet-app`.

For another harness, adapt the harness-specific parts after copying: drop or translate
the `allowed-tools` front matter, and replace each mention of `AskUserQuestion` (and of
the `Write`, `Edit`, and `Bash` tools) with that harness's own way of asking the user
and of editing files and running commands. The procedure itself is harness-neutral.

## Tools

Opt-in tools under [`dist/tools/`](dist/tools/), copied into a repository only when it
needs them. Each directory's README states the prerequisites, what to copy where, how to
run the tool, and what it produces. Take them from a tag, as everything else.

| Tool | What it does |
|---|---|
| [`dist/tools/sqlserver/`](dist/tools/sqlserver/README.md) | Exports SQL Server database schemas into SQL database projects, from which a database with the same structure and settings can be built |

## License

MIT — see [LICENSE](LICENSE).
