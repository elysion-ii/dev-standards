---
status: active
created: 2026-07-17
---

# dev-standards Repository Rules

Repository-specific rules for working on dev-standards. Deltas and overrides against
`rules/standard.md` only — never copy shared rule text here. On conflict, this file
wins.

## Language

- All content in this repository is written in **English** (public repository)

## Distributed content (`rules/`, `skills/`, `templates/`)

- `rules/` files are **token-free**: concrete commands with real project names live in each consuming repository's `AGENTS.md`, never here
- `rules/` files carry **no front matter and no in-file marker** — they are distributed byte-identical, and consuming repositories detect local edits by matching against this repository's tag history. Do not add either
- Templates use literal `{{TOKEN}}` placeholders. Token names are part of the consumption interface: renaming or removing one is a MAJOR change
- `templates/dotnet/en/` and `templates/dotnet/ja/` are variants of the same content and must stay in parity: a change to one is applied to the other in the same commit
- Never reference private, user-specific tooling (personal skill names, local paths) anywhere in this repository — consumers only know the tag interface described in `README.md`

## Releases

- Tags are the consumption interface. Any change to distributed content is not consumable until tagged — follow `docs/guides/release.md`
