---
status: accepted
---

# Distribute Rule Bodies as Documents in docs/rules, with AGENTS.md as the Only Router

## Context

Consuming repositories serve three agent harnesses (Claude Code, Codex, Antigravity).
Harness-specific skill trees (`.claude/skills/` and `.agents/skills/`) required every
rule body to exist as two copies per repository. The shared files could be refreshed
from this repository, but repository-authored rule files would be edited in place —
every edit would need to be made twice, and the copies would inevitably drift. A
separate question was how distributed files should be marked as "managed": an in-file
header carrying a version drifts from the release tag whenever a release does not touch
that file, and keeping it synced is a manual step.

## Decision

- Rule bodies live in one place per consuming repository: `docs/rules/`, in three
  layers applied in order — shared core (`standard.md`) → language files → application
  rules files. The more specific file wins on conflict.
- The root `AGENTS.md` is the only router: facts, commands, an Applications table, and
  reading/AUDIT instructions — no rule text. All three harnesses read `AGENTS.md`
  natively (`CLAUDE.md` is a one-line import), so no per-harness rule copies exist.
- Application rules pair with a specification (`docs/rules/<App>` ↔ `docs/specs/<App>`,
  same identifier, declared in the Applications table). The scope rule generalizes to
  every docs category: directly under the category = repository-wide, `<App>.md` or
  `<App>/` = application-specific.
- Distributed files are copied **verbatim with no in-file marker**. `AGENTS.md` and the
  `doc-placement` skill mark them as managed; retrofit tooling detects local edits by
  matching the existing file against this repository's tag history.
- Only event-driven procedures (`doc-placement`, `merge-pr`) remain distributed as
  skills, in both harness trees — they change rarely and are refreshed from tags, so
  the two-copy cost is negligible.

## Alternatives Considered

- **Per-harness `standards` skill trees (the v1.x design)** — rejected: two copies of
  every rule body per repository; repository-authored rules would drift between trees.
- **In-file managed headers carrying a version** — rejected: the version drifts from
  the release tag whenever a release does not touch the file, and syncing it is a
  manual step that will be forgotten.
- **Stripping a header at distribution time** — rejected: breaks byte-identical
  distribution, which is what makes local-edit detection mechanical.

## Consequences

- Rule edits happen once, in one file; no synchronization mechanism exists because none
  is needed.
- Retrofitting a repository to a new tag is a file replacement plus a mechanical
  local-edit check, not a merge.
- Rules are ordinary repository documents: visible in `docs/`, reviewable in PRs, and
  covered by the same placement rules as every other document.
- Agents must follow one indirection (`AGENTS.md` → `docs/rules/`); the AUDIT procedure
  is the safety net when the reading instruction is skipped.

## Revisit When

- A harness stops reading `AGENTS.md` natively, or the Agent Skills standard becomes
  the only reliable distribution channel — per-harness copies would then need a
  mechanical parity gate instead.
