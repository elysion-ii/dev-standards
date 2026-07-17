---
status: active
created: 2026-07-17
---

# Release Procedure

A tag is needed only when distributed content (`dist/`)
changed — `docs/`, `README.md`, and `AGENTS.md` changes ride along with the next
release.

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
