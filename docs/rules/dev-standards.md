---
status: active
created: 2026-07-17
---

# dev-standards Repository Rules

Repository-specific rules for working on dev-standards. Deltas and overrides against
`dist/rules/standard.md` only — never copy shared rule text here. On conflict, this file
wins.

## Language

- Maintenance documents (`docs/`, `AGENTS.md`, `README.md`) and the distributed rules and skills (`dist/rules/`, `dist/skills/`) are written in **English** (public repository)
- Localized template variants (`dist/templates/dotnet/ja/`, ...) are deliberately in their target language — they are exempt, per the parity invariant in `docs/specs/dev-standards.md`

## Distributed content (`dist/`)

- `dist/rules/` files are **token-free**: concrete commands with real project names live in each consuming repository's `AGENTS.md`, never here
- `dist/rules/` files carry **no front matter and no in-file marker** — they are distributed byte-identical, and consuming repositories detect local edits by matching against this repository's tag history. Do not add either
- Templates use literal `{{TOKEN}}` placeholders. Token names are part of the consumption interface: renaming or removing one is a MAJOR change
- `dist/templates/dotnet/en/` and `ja/` are variants of the same content and must stay in parity: a change to one is applied to the other in the same commit
- Never reference private, user-specific tooling (personal skill names, local paths) anywhere in this repository — consumers only know the tag interface specified in `docs/specs/dev-standards.md`

## Changing this repository

- **Spec-first applies to this repository too**: a change that alters the structure or the distribution/versioning contract updates `docs/specs/dev-standards.md` before (or with) the change
- **Grep before renaming**: when renaming, moving, or deleting any file or section heading, search the whole repository for references and update them in the same commit — `dist/` and `docs/` cross-reference each other, and a stale reference in a distributed file ships to every consumer
- **New rule → matrix row**: adding a rule to a language file includes its enforcement-matrix row (Enforced with the mechanism named, or AUDIT)
- **Impact check before editing distributed content**: a change under `dist/` lands in every consuming repository at its next retrofit — classify it against the versioning contract (MAJOR/MINOR/PATCH per the specification) before committing
- **Rule text goes to `dist/rules/`, never to templates**: template `AGENTS.md` variants carry facts, commands, and routing only

## Releases

- Tags are the consumption interface. Any change to distributed content (`dist/`) is not consumable until tagged — follow `docs/guides/release.md`. Changes outside distributed content need no tag
