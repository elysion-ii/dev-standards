# Client Distribution and Desktop Standards

**Applies when** the application is packaged, distributed to, and run directly on user or operator machines (e.g., desktop GUI applications, installed local utilities, packaged workstation tools). Does not apply to server-hosted web/API applications, remote container services, or scripts executed strictly from a developer source tree.

Defines stack-agnostic ideals for resolving paths on end-user machines, minimizing and
cleaning packaged footprints, handling
running instances during update or removal, bounding local logs, and keeping scrollable UI
lists responsive.

## Application Path Anchoring

- **Anchor application-owned paths explicitly**: resolve every application-owned file or directory (e.g., configuration, local data, logs, bundled assets) relative to the application's own executable directory or a platform-designated application-data directory — never relative to the process's current working directory, which varies by shortcut, scheduler, or parent process. (By contrast, user-supplied path arguments such as CLI inputs intentionally resolve against the caller's working directory.)

## Packaging and Distributable Footprint

- **Minimize distributable file count without runtime unpacking**: ship the smallest self-contained footprint the stack achieves cleanly (ideally a single executable), and exclude debug symbols from shipped packages unless the repository's application rules file explicitly requires shipping symbols for field crash diagnostics. Never use self-extracting bundles that unpack runtime or native files into shared temporary folders on launch without automatic cleanup; prefer removing unneeded native dependencies first, and ship unavoidable native libraries alongside the executable instead.
- **Package the entire verified build output**: configure packaging to collect the entire verified build output directory rather than a manually maintained executable-only list, ensuring unavoidable side-by-side runtime dependencies are never dropped.
- **Gate release packaging on single-sourced version and changelog**: derive the package version solely from the project's single version definition (`standard.md` Version Display), failing fast if missing, and fail release packaging whenever `CHANGELOG.md` exists without an entry matching that version.

## Installation, Update, and Removal

- **Detect running processes on update and uninstall**: detect open processes locking installed application executables before overwriting files during updates or deleting files during uninstalls, preventing partial removals or locked-file failures.
- **Offer graceful close without forced termination**: in interactive runs, inform the user which application is running and offer graceful shutdown and retry, manual retry, or cancel — never force-kill running processes without explicit user direction, because forced termination discards unsaved work.
- **Close gracefully during unattended runs**: in silent/unattended updates or uninstalls where no UI can be shown, request graceful process closure and proceed once the processes have exited; when they do not exit, end the update or uninstall with a failure exit code rather than force-killing them or hanging silently, because a failed deployment can be rerun while work lost to forced termination cannot be recovered.
- **Never block uninstall on detector failure**: if process detection itself fails or cannot answer during uninstall, let removal proceed rather than preventing users from uninstalling.
- **Preserve operator configuration across updates**: update application binaries without overwriting existing operator configuration files (`configuration.md`, when present) or user data.

## Logs on the Host Machine

- **Predictable log location with writable fallback**: write logs inside an application-owned log directory beside the executable when writable, falling back automatically to an application-specific folder under the user's local application-data directory when installed under a read-only directory.
- **Bounded rotation and automatic retention**: rotate log files on a regular cycle (e.g., daily) and automatically prune old logs to a bounded retention limit defined by the repository's stack or application rules so logs cannot grow without bound on unattended machines.
- **Delete only application-owned log files**: match strictly this application's own log filename pattern during cleanup; never sweep shared directories.
- **Best-effort log cleanup**: log cleanup failures and continue; never abort application startup or primary operations because an old log could not be deleted.
- **Log language**: write log entries in English unless the repository's application rules state otherwise.

## Leave No Debris on the Host Machine

- **Bound and clean transient local state**: ensure caches, extracted assets, temporary working files, and other transient artifacts the application writes (never user-saved documents or the application's persistent data) obey bounded retention and crash-resilient cleanup touching solely files owned by this application.

## Responsive UI for Large Lists

- **Keep UI virtualization enabled on scrollable lists**: render scrollable collections (e.g., tables, lists, grids) using viewport-only item virtualization rather than materializing visual controls for every row upfront, and never place virtualized lists inside layout containers that grant unbounded height and silently disable virtualization.
