---
status: active
created: 2026-07-17
---

# Release Procedure

This is this repository's own addition on top of the generic `gh pr merge` procedure in
`dist/rules/git.md`: after merging a PR (or landing any change on `main`), decide
whether a release is due.

## When a release is due

- The change touched anything under `dist/` → a release is due. Follow the procedure
  below.
- The change touched only `docs/`, `README.md`, or `AGENTS.md` → no tag is due; the
  change rides along with the next release.

## Procedure

1. For template changes, verify `dist/templates/dotnet/en/` ↔ `ja/` parity (same structure
   and meaning; see `docs/rules/dev-standards.md`).
2. Commit to `main` (conventional commits, English).
3. Choose the version per the criteria in `docs/specs/dev-standards.md` (MAJOR:
   layout/token breaking; MINOR: new content; PATCH: fixes and wording).
4. Tag and push:

   ```bash
   git tag vX.Y.Z
   git push origin main --tags
   ```

5. Update every consumer that pins a tag of this repository to the new tag (scaffolding
   and retrofit tooling carry the pin).
