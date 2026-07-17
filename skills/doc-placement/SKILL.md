---
name: doc-placement
description: Placement, classification, naming, front matter, and archiving procedure for all non-source documents (specs, guides, references, investigations, notes, ADRs). Use BEFORE creating, moving, renaming, or archiving any document, when deciding where a new document belongs, or when unsure how to name one or what front matter to add. Do not guess placement from memory — read this skill first.
---

# doc-placement

Classification and placement procedure for every non-source document in a repository.

## Principles

- Folders in normal reference paths contain only documents that are currently valid. Retired documents never mix with active ones.
- Classify by the document's role (rule / decision / procedure / reference / investigation / note), not by the feature it relates to.
- Active documents live directly under their category folder. Never create `current/` or `active/` subfolders whose only meaning is "not archived" — the sole exceptions are categories where state itself is meaningful (`investigations/`, and `adr/archive/`).
- Archiving is not deletion: it removes a document from the normal reference path while keeping history. Documents with no future reference value are deleted, not archived.

## Directory layout

```text
AGENTS.md                   agent rules (always-on instructions; root entry point)

docs/
  adr/                      active ADRs
    archive/                superseded / rejected / withdrawn ADRs
  specs/                    specifications: what the system must do
  guides/                   reproducible procedures
  references/               durable project-specific facts
  investigations/
    active/                 ongoing investigations
    closed/                 finished investigations still worth reading
  notes/                    lightweight but classified, valid memos
  plans/                    in-progress work plans (working area, gitignored)
  inbox/                    unclassified documents awaiting triage
  archive/                  retired non-ADR documents, mirrored by category
    specs/ guides/ references/ investigations/ notes/ plans/
```

The category set is extensible: a project may add role subfolders (e.g., `docs/design/`)
when a role clearly fits no existing category and several documents will share it. Every
added category follows the same rules: active documents directly under the folder,
retirement into `docs/archive/<category>/`, standard front matter. In a multi-solution
repository, split the first level of `docs/` by solution, then by role within each.

## Placement decision table

| Question | Destination |
|---|---|
| Must agents or developers follow it? | Root `AGENTS.md` (or a nested `AGENTS.md` for a subtree) |
| Does it define correct results (input → output)? | Test code (table-driven) |
| Does it record why a decision was made? | `docs/adr/` |
| Does it state what the system must do (a specification)? | `docs/specs/` |
| Is it a reproducible working procedure? | `docs/guides/` |
| Is it a durable fact referenced during work? | `docs/references/` |
| Does it record how a specific problem was investigated? | `docs/investigations/` |
| Valid, but too light for a formal category? | `docs/notes/` |
| Is it an in-progress work plan? | `docs/plans/` (finished: `docs/archive/plans/`) |
| Placement not yet decided? | `docs/inbox/` |
| Retired non-ADR document worth keeping? | `docs/archive/<category>/` |
| Retired ADR? | `docs/adr/archive/` |
| No future reference value? | Delete |

## Category notes

- **`AGENTS.md` (rules)**: currently valid rules only — conventions, prohibitions, constraints, work rules. No rationale, history, or investigation memos; rationale goes to an ADR referenced from the rule. When rule text grows long, move the body to `docs/` and keep a pointer. Never duplicate a rule across files.
- **`docs/adr/`**: the adopted decision plus reasoning, constraints, rejected alternatives, and revisit conditions. Body sections (Nygard-style): Context, Decision, Consequences (required); Alternatives considered, Revisit when (when they exist). A superseded ADR names its successor in front matter (`superseded-by`); an ADR stays an ADR — retired ones go to `docs/adr/archive/`, never `docs/archive/`.
- **`docs/references/`**: durable facts that are hard to read from source alone: external API constraints, auth flows, data mappings, legacy caveats, domain vocabulary. Current-state architecture/design descriptions default here; promote to a dedicated category when numerous.
- **`docs/investigations/`**: state matters — `active/` (ongoing) vs `closed/` (finished, still worth reading; not an archive). When finished, promote durable outcomes: rules → `AGENTS.md`, decisions → `docs/adr/`, procedures → `docs/guides/`, facts → `docs/references/`.
- **`docs/notes/` vs `docs/inbox/`**: the line is whether the placement decision has been made — `inbox` holds unclassified documents; `notes` holds documents decided to be lightweight-but-valid. Putting something in `notes` "for now" means it belongs in `inbox`. Promote a note to `references/` when it becomes the authoritative answer you would point someone to.
- **`docs/plans/`**: working area, gitignored and local-only by default (as is `docs/archive/plans/`) — plans stay out of the repository, in progress or archived, unless a project rule deliberately tracks them. In projects that do track plans, clean `docs/plans/` before committing (move finished plans to `docs/archive/plans/`, renaming on collision).

## Front matter

Every document carries front matter with at least `created` and `status`. Two exemptions:
in-progress plans under `docs/plans/` (front matter is added when archived), and ADRs,
which do **not** carry `created` — the sequence number and git history already encode
chronology, so ADR front matter is `status` only, plus `supersedes`/`superseded-by` when
applicable. Never add `created` to an ADR.

```yaml
---
status: active
created: 2026-07-15
---
```

### `status` vocabulary

| Document type | Allowed values |
|---|---|
| ADR | `accepted` / `superseded` / `rejected` / `withdrawn` |
| Investigation | `active` / `closed` / `archived` |
| Everything else | `active` / `archived` |

Do not invent other values. Optional fields: `last-reviewed`, `topics`,
`supersedes` / `superseded-by`.

## Naming

- Lowercase kebab-case describing the content: `database-migration.md`, `authentication-flow.md`.
- Never content-free names: `memo.md`, `temp.md`, `note1.md`, `misc.md`.
- No sequential numbering for general documents (`0001-`) — chronology belongs in `git log`.
- **ADRs are the exception**, following the community convention: `NNNN-description.md` with a 4-digit zero-padded number. Numbers are immutable IDs allocated append-only: next = highest existing number across `docs/adr/` **and** `docs/adr/archive/` + 1. Never renumber and never fill gaps.
- Infrastructure directories are lowercase (`docs/`, `adr/`, `guides/`); code directories follow the language convention.

## Lifecycle

```text
inbox → (rules | adr | specs | guides | references | investigations | notes) → archive → delete when worthless
investigations: active → closed → archive/investigations
adr:            adr/ → adr/archive/
plans:          docs/plans/ → docs/archive/plans/ (or delete)
```

## Archive vs delete

Archive when the document is invalid or replaced but still traces past incidents or
decision background. Delete when it is duplicated, a spent temporary memo, wrong with no
historical value, or fully covered by Git history.

## Source of truth

When a human-readable reference (e.g., a mapping table) coexists with tests, declare the
source of truth in the document itself. Precedence: table-driven tests > reference
document > current code. Snapshot tests only detect change; they are never a source of
truth.
