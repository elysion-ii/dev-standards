---
status: accepted
supersedes: 0001-rules-as-documents
---

# Retire Distributed Skills — Consolidate into Task-Specific Rule Files

## Context

ADR 0001 established that rule bodies live in `docs/rules/` as documents, with
`AGENTS.md` as the only router, and reserved skill distribution for event-driven
procedures with no reusable rule text: `doc-placement` (document
classification/placement/naming/front matter/lifecycle) and `merge-pr` (the
`gh pr merge` procedure). Both turned out to hold almost entirely standing rule text —
decision tables, naming conventions, front-matter schemas, commit and merge conventions
— with only a thin sequence of `gh` commands genuinely event-driven. Distributing them
as skills required two identical copies per repository (`.claude/skills/`,
`.agents/skills/`), duplicated the reasoning ADR 0001 rejected for rule bodies, and left
a growing set of user-specific, harness-side synchronization tooling responsible for
keeping them in parity across harnesses and persistence layers.

## Decision

- No skill is distributed by this repository. `dist/skills/` is removed, along with
  `doc-placement` and `merge-pr` in both harness trees (`.claude/skills/`,
  `.agents/skills/`) of this repository and of every consumer.
- Document classification, placement, naming, front matter, and lifecycle rules move to
  a new distributed rule file, `dist/rules/documentation.md`, consumed at
  `docs/rules/documentation.md`.
- Git write-operation and PR-operation rules — commit format, branch rules, PR rules,
  merge strategy, squash message composition, and the generic `gh pr merge` procedure —
  move to a new distributed rule file, `dist/rules/git.md`, consumed at
  `docs/rules/git.md`.
- These two files are **task-specific rule files**: unlike the always-read chain
  (`standard.md` → language files → application rules), they are read only when that
  kind of work is underway — document work for `documentation.md`, a Git write or PR
  operation for `git.md`. `AGENTS.md` states the reading condition for each; it holds no
  rule text of its own for either.
- dev-standards' own post-merge decision — whether a merged PR makes a release due — is
  not part of the generic `git.md` distributed to consumers. It stays in this
  repository's own `docs/guides/release.md`, referenced conditionally from this
  repository's own `AGENTS.md`, because it depends on this repository's own
  distribution and versioning contract, which consumers do not share.
- The decisions ADR 0001 made about rule bodies stand and are restated here so this
  record remains self-contained once 0001 is archived:
  - Rule bodies live in one place per consuming repository, `docs/rules/`, applied in
    layers with the more specific file winning on conflict.
  - The root `AGENTS.md` is the only router: facts, commands, an Applications table,
    and reading/AUDIT instructions — no rule text. Every harness that reads `AGENTS.md`
    natively needs no per-harness rule copies.
  - Distributed files (`dist/rules/*.md`) are copied byte-identical with no front
    matter and no in-file marker; retrofit tooling detects local edits by matching
    against this repository's tag history, not by a version header.

## Alternatives Considered

- **Keep `doc-placement` and `merge-pr` as skills, only trim their content** — rejected:
  even a trimmed skill still needs two identical copies per repository and a
  cross-harness synchronization step. ADR 0001 accepted that two-copy cost as
  negligible for a short, genuinely event-driven procedure; it stopped being negligible
  once each skill's body turned out to be almost entirely standing rule text.
- **Fold `documentation.md` and `git.md` content into `standard.md`** — rejected: it
  would force every task to read document-placement and Git-merge rules regardless of
  whether the task touches either, and would make `standard.md` the largest,
  least-focused rule file. Splitting by task keeps each file read only when relevant.
- **Make `documentation.md` and `git.md` part of the always-read chain, like language
  files** — rejected: most implementation tasks touch neither documents nor Git
  operations directly; adding them to the unconditional chain would add reading cost
  with no benefit for the common case.

## Consequences

- Every consuming repository loses two skills (`doc-placement`, `merge-pr`) from both
  harness trees and gains two rule files (`docs/rules/documentation.md`,
  `docs/rules/git.md`).
- `AGENTS.md` routing has three systems instead of two: the always-read implementation
  chain, plus two conditional task-specific reads.
- The Claude-Code-specific synchronization skills that previously had to keep
  `doc-placement` in parity across `.claude/` and `.codex/` no longer need to — there is
  nothing left to synchronize for it.
- This is a breaking change to the distribution contract (removed `dist/skills/`,
  moved and added `dist/rules/*.md` files) and ships as the next MAJOR version per
  `docs/specs/dev-standards.md`.
- Consumers pinned to an older tag keep their installed `doc-placement`/`merge-pr`
  skills until retrofitted; nothing in this decision retroactively removes them.

## Revisit When

- A future need arises for a genuinely event-driven procedure with no meaningful
  standing rule content (unlike `doc-placement` and `merge-pr`, which turned out to be
  mostly rule text) — that would be a legitimate case for reintroducing `dist/skills/`.
- A harness stops reading `AGENTS.md` natively, or the Agent Skills standard becomes the
  only reliable distribution channel — the same condition ADR 0001 named, still
  applicable to `documentation.md` and `git.md`.
