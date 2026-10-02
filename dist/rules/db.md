# Database Standards

**Applies when** the application reads or writes a database: a store it queries through a
database engine, whether the engine runs as a server, a hosted service, or a file the
application opens.

A conditional core file of the shared core rules (`docs/rules/`). Governs who changes a
database schema, how schema changes are written, recorded, and deployed, and the shape of
the queries the application sends. Stack-agnostic: the migration tool, the database
engine, and the data-access library are the stack's or the application's choice.

Rules that bind every durable store and every input, databases included, are in
`standard.md`: atomic and concurrency-safe writes (Writes That Hold Together), bound
parameters (External Input), and tests against a database the test run creates (Boundary
Tests).

## Enforcement matrix

No rule in this file has a mechanical guard: every rule is an **AUDIT** item. A stack or
an application that adds a guard (e.g., a check that fails when a migration file that was
already applied changes) records it in its own rules file.

| ID | Rule | Mechanism | Check |
|----|------|-----------|-------|
| OWNER | Each schema has one owning repository, and only the owner changes it | — | AUDIT |
| MIGRATION | The owner changes the schema only through migration scripts committed to its repository | — | AUDIT |
| APPLIED | The database records which migrations it has applied | — | AUDIT |
| FORWARD | Migrations are applied forward only; an applied migration is never edited | — | AUDIT |
| MEANING | A migration that changes what stored data means converts the stored rows | — | AUDIT |
| DEPLOY | A deployment applies its migrations before the code that depends on them runs | — | AUDIT |
| QUERY | Set work runs in the query; one query per decision, never one per row | — | AUDIT |

## OWNER: Schema Ownership

- **One owner per schema**: each schema (each database, or each set of tables one team changes) is owned by exactly one repository, and only that repository's migrations change it. Two repositories that both change one schema each hold a definition the other does not know about.
- **Other users treat the schema as external**: an application that reads or writes a schema it does not own changes nothing in it. A schema change it needs is made by the owner's migration, and the application states its dependency on that change in its own specification.

## MIGRATION: Schema Changes

- **Scripts only**: the owner changes the schema only through migration scripts committed to its repository. A change made by hand in a database tool cannot be reviewed, and cannot be reproduced in another environment.
- **Ordered**: migration scripts carry an order that the repository's own files settle (e.g., a sequence number or a timestamp in the file name). An order kept only in someone's memory is lost the first time someone else applies them.
- **Data that defines the schema is a migration too**: rows the application cannot run without (code tables, master values the code refers to by key) are inserted and changed by migration scripts, under the same rules as the schema.

## APPLIED: Applied Migrations

- **The database records what it has applied**: each database holds the list of migrations already applied to it, written by the same step that applies them. The next migration to apply is then read from the database being changed, not remembered by the person applying it.

## FORWARD: Forward Only

- **Undo is a new migration**: reverting a schema change is done by adding a migration that reverses it. A deleted or edited migration leaves databases that already applied it different from databases built afterwards.
- **An applied migration is never edited**: once a migration has been applied to any shared environment, its content stays as it was applied. A database records only that a migration ran, not what the file said at the time.

## MEANING: Changing What Data Means

- **Stored rows follow the new meaning**: a migration that changes what a column or a code value means (a new unit, a split value, a renamed state) also converts the rows already stored under the old meaning, in the same migration. Rows left in the old meaning are read with the new one, and nothing marks which is which.

## DEPLOY: Deploying Schema Changes

- **Migrations go first**: a deployment applies its migrations before any code that depends on them runs against the database. Code that runs against a schema it does not expect fails on its first query, or writes rows the next migration misreads.
- **A deployment without its migrations is incomplete**: a deployment counts as done only when every migration it carries has been applied to that environment's database.

## QUERY: Query Shape

- **Set work runs in the query**: filtering, joining, sorting, and aggregating rows happen in the query the database executes, not by fetching rows and processing them in code. Fetching rows to discard or count them moves data the decision never needed, and the cost grows with the table.
- **One query per decision, never one per row**: data that a decision needs is fetched by a query that returns all of it, not by issuing a query for each row of an earlier result. A query per row multiplies round trips by the row count.
