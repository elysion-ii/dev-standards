---
status: accepted
---

# Publish the Scaffolding and Retrofit Skills, with the Mapping Next to the Templates

## Context

This repository publishes rules and templates, but the two procedures that turn them
into a repository — scaffolding a new .NET repository and converging an existing one
onto the newest tag — existed only as one maintainer's personal agent skills. Anyone
else who adopted dev-standards received the rules without the means to apply them.

Both procedures also depended on data that describes this repository's templates: the
mapping from each template to the path it generates, and the markers retrofit uses to
recognize a template-carried mechanism in an existing file. That data lived inside the
skill bodies, outside the repository whose templates it described. A template added at
a tag without a matching edit to the skills was invisible to scaffolding and retrofit,
and nothing at the tag could show the omission.

ADR 0002 retired *distributed* skills — skills copied into every consuming repository —
because their bodies turned out to be standing rule text. Its Revisit When names a
genuinely event-driven procedure with no standing rule content as the case for
reintroducing skills.

## Decision

- Two skills are published under `skills/`: `init-dotnet-app` (scaffold a new .NET
  repository) and `retrofit-dotnet-app` (converge an existing .NET repository onto the
  newest tag). They form a new category: **repository-owned operational skills** —
  published by this repository and installed by a user in their own agent harness,
  never copied into a consuming repository. They live outside `dist/`, the boundary of
  what is copied into consuming repositories
- These two skills are the case ADR 0002 left open. Each runs once per event — a new
  repository, a new tag to converge onto — and holds procedure only: what to clone,
  what to ask, in what order to write, how to confirm. Every rule they apply is read
  from `dist/rules/` at the tag; every path and marker is read from the mapping file.
  ADR 0002 stands for rule content: no rule text moves into a skill, and no skill is
  distributed into consuming repositories
- Only these two are published. The procedure for maintaining this repository's own
  rules stays outside it: it edits this repository and a maintainer's personal
  configuration layers, so it is tied to one maintainer's setup and has no use for an
  adopter
- Delivery is the skill files in this repository. A user copies the skill directories
  from a tag into their harness's skills directory. There is no plugin marketplace or
  other packaging: the skills are plain files, and a tag already versions them together
  with the templates they read
- The skills are written in the Claude Code skill format. Another harness uses them
  after adapting the harness-specific parts (the tool names and the `allowed-tools`
  front matter)
- The template-to-path mapping and the mechanism-marker table move out of the skills
  into `dist/templates/dotnet/mapping.md`. Every copy of the skills — the published ones
  and any personal copy a maintainer keeps with setup-specific additions — reads that
  file from the cloned tag instead of carrying its own table. The mapping therefore
  always matches the templates of the tag being applied, and a new template file is
  registered in exactly one place, in the same commit as the template
- The mapping file states a format number. A skill reads the newest tag at run time, so
  an older copy of a skill can meet a mapping whose structure has changed; on a format
  number it was not written for, it stops and tells the user to obtain the skills again
  from that tag, rather than misreading the mapping

## Alternatives Considered

- **Reintroduce `dist/skills/` and copy the skills into consuming repositories** —
  rejected: a consuming repository has no use for the procedure that created it, and
  copying would reopen every cost ADR 0002 removed (per-harness copies in each
  repository, synchronization across them)
- **Publish the skills but keep the mapping inside them** — rejected: the mapping
  describes the templates, so it drifts whenever a template changes without a matching
  skill edit, and a personal copy and a published copy would each carry their own table
- **Pin each skill copy to the MAJOR version it was published with** — rejected: it
  would change the established behavior of always applying the newest tag, and an
  adopter would have to recopy the skills to move to a new MAJOR anyway; the format
  number gives the same protection while keeping that behavior
- **A machine-readable mapping (JSON)** — rejected: the marker table's port sources are
  prose instructions to an agent, and an agent reads a Markdown table directly; the
  coverage check needs only the backticked source paths, which Markdown carries as well

## Consequences

- An adopter can scaffold and retrofit .NET repositories with the same procedures the
  maintainer uses
- `skills/` becomes part of what a tag publishes: a change there makes a release due,
  like a change under `dist/`
- Adding a template file means adding its mapping row in the same commit. A coverage
  check in `docs/guides/release.md` confirms that every file under `dist/templates/`
  and `dist/rules/` is named by a mapping file before a release
- Changing the mapping's structure is a MAJOR change and increments the format number;
  older skill copies stop at the newest tag until their user recopies them
- A maintainer's personal copies shrink to the published procedure plus setup-specific
  additions, and no longer need editing when a template is added

## Revisit When

- A second stack template set appears: decide whether its skills are separate or the
  published skills become stack-generic, reading the stack from the mapping file
- A harness-neutral skill format becomes reliably supported by the harnesses in use —
  the skills could then be published once in that format instead of in one harness's
  format
- The procedure for maintaining this repository's rules loses its tie to a personal
  setup, which would make it publishable on the same terms
