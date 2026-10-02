---
status: accepted
---

# Grow the Rule Set by Applicability and Samples

## Context

The distributed rules had one stack rule file (`dotnet.md`) and one conditional core
file (`cli.md`, read only by applications that expose a command line). Consuming
repositories on other stacks wrote their own stack rule files, and a review of those
files against the core found two kinds of gap:

- Stack-agnostic principles — validating external input, never building executable
  text from input, applying related writes atomically, storing time in UTC, migrating
  schemas through scripts — had been written into a single repository's stack rule
  file, so every other repository lacked them
- Rules that bind only applications with a given property (a database, a command line)
  had nowhere to go except the core, where they bind applications without that
  property, or a stack rule file, where they bind only one stack

The core also said nothing about what makes a rule ready to distribute. A stack rule
file drawn from one repository carries that repository's platform and product choices:
the one non-.NET stack rule file available mixed TypeScript rules with rules for a
specific hosting platform and its database.

## Decision

- Rules are placed by applicability: the core for every application, a conditional
  core file for applications with a factual property, a stack rule file for a stack's
  toolchain, and the consuming repository for its platform and product
  (`docs/rules/dev-standards.md` Growing the rule set)
- Conditional core files generalize `cli.md`: each opens with its condition as a fact
  about the application, is distributed to every repository, and is skipped only while
  its condition is false. `db.md` is the second one, for applications that read or
  write a database
- A new stack rule file is created only after its rules have been written for two
  consuming repositories on that stack, because a stack rule file states mechanisms and
  the sample count guards against generalizing one repository's mechanism
- A new conditional core file is created only when applications meeting its condition
  exist in two consuming repositories on two stacks. Its content is principles, which
  carry no mechanism to over-generalize; what the threshold guards is that the
  condition is not one stack's property in disguise. `db.md` meets it: a .NET
  repository and a TypeScript repository both hold applications that use a database,
  although only the TypeScript one had written database rules
- A stack-agnostic principle is promoted from one sample, for the same reason a
  conditional core file's content needs no second written sample
- A property stated in two stack rule files moves to the core, leaving each stack rule
  file its mechanism

## Consequences

- The core gains the stack-agnostic principles found in the review in the same release
  that introduces `db.md`
- Every list that names the distributed rule files — the specification, the template
  requirements, the router templates, `documentation.md`, and the scaffolding
  implementation's distribution step — names `db.md`
- Rules duplicated across `dotnet.md` and repository-authored stack rule files (error
  handling, constants, comment language, suppression discipline) are now required to
  move to the core; that move is a later release
- A TypeScript stack rule file is not distributed yet: its rules come from one
  repository, and its platform-specific rules stay in that repository

## Alternatives considered

- **Split the extra files by interface only (command line, web, desktop)** — rejected:
  a database is something an application uses, not an interface it exposes, yet its
  rules have the same shape — stack-agnostic and binding only when a factual property
  holds
- **Declare each conditional file's applicability (yes/no) in the router** — rejected:
  the scaffold cannot know whether an application will use a database, so the
  declaration would need a new token and would go stale the moment an application
  gained the property. The condition stated in the file, checked against the
  application's code, cannot go stale
- **Distribute the repository-authored TypeScript rule file as it is** — rejected: its
  hosting-platform and database-service rules would bind TypeScript applications that
  use neither
- **One file per application type (`gui.md`, `web.md`)** — deferred: the rules shared
  by desktop and browser screens are core principles, and a web-specific file has one
  sample

## Revisit when

- A second consuming repository on a stack other than .NET writes a stack rule file —
  the TypeScript stack rule file becomes a candidate
- A second web application exists — a conditional core file for applications that
  expose an HTTP interface becomes a candidate
- A conditional core file's condition proves undecidable from an application's code in
  practice — the router declaration rejected above becomes the alternative to weigh
