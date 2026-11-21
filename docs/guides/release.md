---
status: active
created: 2026-07-17
---

# Release Procedure

After landing a change on `main` (or merging a pull request), decide whether a release
is due.

## When a release is due

- The change touched anything under `dist/` or `skills/` → a release is due. Follow
  the procedure below. Users obtain the published skills from a tag, so a skill change
  is not available until tagged.
- The change touched only `docs/`, `README.md`, or `AGENTS.md` → no tag is due; the
  change rides along with the next release.

## Procedure

1. For template changes, verify `dist/templates/dotnet/en/` ↔ `ja/` parity (same structure
   and meaning; see `docs/rules/dev-standards.md`).
2. Run the mapping coverage check below. It must print nothing.
3. Commit to `main` (conventional commits, English).
4. Choose the version per the criteria in `docs/specs/dev-standards.md` (MAJOR:
   layout/token/mapping-format breaking; MINOR: new content; PATCH: fixes and wording).
5. Tag and push:

   ```bash
   git tag vX.Y.Z
   git push origin main --tags
   ```

6. Update every consumer that pins a tag of this repository to the new tag (or run
   `sync-rules` / `retrofit-dotnet-app` from the new tag). The published skills pin
   nothing — they resolve the newest tag at run time.

## Mapping coverage check

Confirms the invariant in `docs/specs/dev-standards.md`: every file under
`dist/templates/`, `dist/rules/`, and `dist/tools/` is named by
`dist/templates/shared/rules-mapping.md` or a stack's mapping file
(`dist/templates/<stack>/mapping.md`) as a source or as deliberately not generated, and
every `dist/` path those mappings name exists for every value of its placeholders. Run it
from the repository root in a POSIX shell (Git Bash on Windows). It prints one line per
problem and nothing when the mappings are complete:

```bash
find dist/templates dist/rules dist/tools -type f | sort | while read -r f; do
  lang=$(printf '%s' "$f" | sed -E 's#/(en|ja)/#/{lang}/#')
  ilang=$(printf '%s' "$f" | sed -E 's#/(en|ja)/#/{ilang}/#')
  type=$(printf '%s' "$f" | sed -E 's#/csproj/(console|wpf|winui3|win32)\.#/csproj/{type}.#')
  cat dist/templates/shared/rules-mapping.md dist/templates/*/mapping.md | grep -qF -e "\`$f\`" -e "\`$lang\`" -e "\`$ilang\`" -e "\`$type\`" \
    || echo "unmapped: $f"
done
grep -ohE '`dist/[^`]*`' dist/templates/shared/rules-mapping.md dist/templates/*/mapping.md | tr -d '`' | sort -u | while read -r p; do
  for l in en ja; do
    for t in console wpf winui3 win32; do
      q=$(printf '%s' "$p" | sed -E "s#\{(lang|ilang)\}#$l#; s#\{type\}#$t#")
      test -e "$q" || echo "missing: $q"
    done
  done
done | sort -u
```

- `unmapped: <file>` — add the file's row to `dist/templates/shared/rules-mapping.md` or
  the stack's `mapping.md` (target and class), or list it under **Not generated**
- `missing: <path>` — a mapping names a source that does not exist; fix the row or
  restore the file

The placeholder values in the check (`en`/`ja`, the four app types) mirror the
placeholder table in `dist/templates/dotnet/mapping.md`; a new placeholder or value
there is added here in the same commit.
