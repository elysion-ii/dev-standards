# SQL Server schema export and disposable test servers

Two parts that build on each other:

- **Schema export** (`Export-Schema`): exports the schema of SQL Server databases into SQL
  database projects inside a repository. Re-running it refreshes the projects from the
  source databases; the diff in version control shows what changed on the server.
- **Disposable test server** (`Start-TestSqlServer` / `Stop-TestSqlServer`): builds those
  projects into a new, empty SQL Server running in a container, with the same SQL Server
  version, collation, and database settings as the source, on any developer machine and
  from the repository alone. One server per run, removed when done.

The tool is a foundation: how a repository's tests use the server (fixtures, test data,
UI automation) is the repository's own design. See **Using the server from tests**.

## Prerequisites

- Windows with Windows PowerShell 5.1 (`powershell.exe`)
- .NET SDK
- `sqlpackage` in the repository's dotnet tool manifest. At the repository root:

  ```
  dotnet new tool-manifest            # only when the repository has no manifest yet
  dotnet tool install microsoft.sqlpackage
  ```

  Commit the manifest, so every developer runs the same `sqlpackage` version.
- Network access to the source servers, and to NuGet for the first build of a project
- For the test server only: WSL 2 (`wsl --install --no-distribution` as an administrator
  once per machine) and network access to download Ubuntu and the SQL Server image on
  first use. Docker Desktop is **not** used

## Files

Copy every file in this directory into the folder that will hold the projects (for
example `Database/`). The projects are written beside the files.

| File | Tracked | Role |
|---|---|---|
| `Export-Schema.ps1` | yes | The export |
| `Export-Schema.bat` | yes | Runs the export with a double-click and pauses at the end |
| `export-schema.template.json` | yes | The databases to export, with placeholder connection values |
| `.gitignore` | yes | Keeps the local configuration and the work area out of version control |
| `export-schema.json` | **no** | Each developer's copy of the template with real servers and, optionally, credentials |
| `Setup-SqlServerHost.ps1` | yes | Creates the WSL distribution that hosts the test servers and installs Docker Engine in it |
| `Start-TestSqlServer.ps1` | yes | Starts a test server and builds every project beside it into it |
| `Stop-TestSqlServer.ps1` | yes | Removes a test server, or all of them |

## Setup

1. Edit `export-schema.template.json` to list the repository's databases. Each entry has
   `name` (the database name), `authentication` (`SqlServer` or `Windows`), and
   `server`, `user`, `password` left empty. Commit it.
2. Run the export once. With no `export-schema.json`, it copies the template to
   `export-schema.json` and stops.
3. Fill in `server` for every entry in `export-schema.json`. Leave `user` and `password`
   empty to be asked for them at run time. Values written there are used as they are —
   the file is ignored by git, so they stay on the machine.

## Running

Double-click `Export-Schema.bat`, or:

```
powershell -NoProfile -ExecutionPolicy Bypass -File Export-Schema.ps1 [-Database <name>[,<name>...]] [-ConfigPath <file>]
```

`-Database` exports only the named entries; by default every entry is exported.

What a run does:

- Asks for every missing user and password before the first export, once per server and
  user, so the exports then run unattended
- Connects with the safest encryption setting the server accepts, trying in order:
  encrypted with certificate validation, encrypted trusting the certificate, unencrypted.
  The setting that connected is printed for each database
- Allows one run at a time per folder; a second run stops with an error
- Works in `.export-work/` and swaps each finished project into place, so a failed or
  interrupted run leaves every project either as it was or fully refreshed. A work area
  an interrupted run left behind is removed by the next run

## Output

For each database, a folder named after it:

| Path | Produced | Content |
|---|---|---|
| `<database>/<database>.sqlproj` | on the first export, then kept | The SQL database project (`Microsoft.Build.Sql`). Edit it freely: later exports never overwrite it |
| `<database>/DatabaseOptions.props` | every export | Collation, compatibility level, ANSI settings, snapshot settings, and target platform read from the source database, imported by the project. Do not edit |
| `<database>/<schema>/<object type>/*.sql` | every export | One `CREATE` script per object (`dbo/Tables/`, `dbo/Views/`, `dbo/StoredProcedures/`, ...) |
| `<database>/Security/` | every export, when needed | Schemas and roles. Logins, users, and role memberships are removed, because they belong to the source server; a schema owned by a removed user is dropped when empty and otherwise handed to `dbo` |

The object scripts are definitions, not scripts to run. A database is created or updated
from the built project (`dotnet build <database>/<database>.sqlproj` produces a
`.dacpac`), and `sqlpackage /Action:Publish` derives the `CREATE` and `ALTER`
statements a target needs from the difference between the `.dacpac` and that target.

## Adjusting a project

Edits go into `<database>.sqlproj`, which every later export keeps.

- **References to another database**: a three-part name such as
  `[OtherDb].[dbo].[Table]` resolves only when the project references the other
  database's project:

  ```xml
  <ItemGroup>
    <ProjectReference Include="..\OtherDb\OtherDb.sqlproj">
      <DatabaseVariableLiteralValue>OtherDb</DatabaseVariableLiteralValue>
    </ProjectReference>
  </ItemGroup>
  ```

- **Objects that fail validation**: the project's model validation is stricter than the
  server. An object the server accepts can still fail the build, for example when an
  identifier matches another only under the database's width- or case-insensitive
  collation, or when it references a database outside the projects. When nothing uses
  such an object, exclude it with a reason, and re-check the list after each export:

  ```xml
  <!-- Fail model validation (reason), and nothing in this repository uses them -->
  <ItemGroup>
    <Build Remove="dbo\StoredProcedures\OldProcedure.sql" />
  </ItemGroup>
  ```

Unresolved references inside stored procedures are build warnings, not errors; they can
stay when the referenced database is outside the repository's concern.

## Disposable test server

```
powershell -NoProfile -ExecutionPolicy Bypass -File Start-TestSqlServer.ps1 [-Name <container>] [-OutputFile <file>]
powershell -NoProfile -ExecutionPolicy Bypass -File Stop-TestSqlServer.ps1 [-Name <container>]
```

`Start-TestSqlServer.ps1`:

1. Builds every `<database>/<database>.sqlproj` beside the script. A project that fails to
   build stops the run before any container exists
2. Creates the WSL distribution `sqlserver-test` with `Setup-SqlServerHost.ps1` when it
   does not exist yet (about a minute and a half on first use). The distribution is
   dedicated to test servers; `wsl --unregister sqlserver-test` removes everything
3. Starts a container from the SQL Server image matching the projects' target platform
   (`DSP` in `DatabaseOptions.props`: 2017, 2019, 2022, or 2025), with the projects' collation
   as the server collation — so temporary tables compare like on the source server — and a
   random `sa` password. All projects must agree on both, or the run stops
4. Publishes the projects in dependency order (a project's `ProjectReference`s first) as
   new, empty databases
5. Prints the server (`<address>,<port>`), user, password, and databases. `-OutputFile`
   also writes them as JSON (`container`, `distro`, `server`, `user`, `password`,
   `databases`) for a calling program

A failed run removes the container it started. `Stop-TestSqlServer.ps1 -Name <container>`
removes one server; without `-Name` it removes every server the script started.

Things the scripts handle that a caller should know about:

- **Address**: Windows reaches the container through the WSL distribution's IP address,
  not `localhost`, so always use the printed server
- **Lifetime**: WSL stops a distribution no process uses, and the containers with it. The
  start script leaves a hidden process waiting on the container, so the server lives
  until it is removed
- **Data**: the databases are empty. Whatever a check or a test needs, it inserts itself

For a manual check, point the application's connection setting at the printed server and
remove the server afterwards.

## Using the server from tests

A typical test fixture:

1. Runs `Start-TestSqlServer.ps1 -OutputFile <temp file>` once for the test run, reads the
   JSON, and deletes the file
2. Inserts the rows each test needs, and anything the application needs to start, through
   the same path a real installation gets it where one exists
3. Runs the tests against the server
4. Runs `Stop-TestSqlServer.ps1 -Name <container>` when the run ends

Run tests that start a server one at a time per solution, as they share the WSL
distribution's resources.
