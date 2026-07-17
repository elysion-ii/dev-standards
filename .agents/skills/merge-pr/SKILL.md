---
name: merge-pr
description: dev-standards-specific procedure for merging a GitHub pull request and deciding whether to tag a release. Read BEFORE running any gh pr merge command in this repository, whenever asked to merge a PR.
---

# merge-pr (dev-standards)

This repository's variant of the distributed `merge-pr` procedure. It exists because in
this repository the Git conventions live at `dist/rules/standard.md` (not
`docs/rules/standard.md` as in consuming repositories), and because merging here can
make a release due.

## Procedure

1. Follow the merge procedure in `dist/skills/merge-pr/SKILL.md` (the source copy),
   reading the strategy, message composition, and branch cleanup rules from the Git
   section of `dist/rules/standard.md`.
2. **After the merge, decide whether a release is due:**
   - The PR changed anything under `dist/` → follow `docs/guides/release.md`: classify
     the change (MAJOR/MINOR/PATCH per `docs/specs/dev-standards.md`), tag, push the
     tag, and update every consumer pinning a tag of this repository.
   - The PR touched only `docs/`, `README.md`, `AGENTS.md`, or the local skill
     installs → no tag; the changes ride along with the next release.
