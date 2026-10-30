# SQL Server schema export

Exports the schema of SQL Server databases into SQL database projects inside a
repository, so that a database with the same structure and the same settings can be
built anywhere from the repository alone (for example, a disposable test database).
Re-running the export refreshes the projects from the source databases; the diff in
version control shows what changed on the server.

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
