# .NET Client Standards

Stack rule file specifying the .NET and Windows desktop packaging means that satisfy
`client.md`, used alongside `dotnet.md`.

**Applies when** the application is a .NET application packaged, distributed to, and run
directly on Windows user or operator machines (`client.md` applies). Does not apply to
server-hosted web/API applications, cross-platform console tools not packaged for Windows
clients, or scripts executed strictly from a developer source tree.

## Enforcement Matrix

Rules marked **Enforced** are checked mechanically by project properties or build
targets; rules marked **AUDIT** require manual verification during AUDIT (including any
rule with partial mechanical checks). Where a repository lacks a listed mechanism, treat
that entire rule as **AUDIT** until added.

| ID | Rule | Mechanism | Check |
|---|---|---|---|
| LOGGING | Application log path, daily rotation, and 30-file retention (`client.md` Logs on the Host Machine) | — | AUDIT |
| XAML-VISIBILITY | WPF `x:ClassModifier="internal"` and WinUI 3 `App` exception (`standard.md` Minimal Visibility) | `.editorconfig` `CA1515` + `[SuppressMessage]` on WinUI 3 `App` | AUDIT — `CA1515` enforces non-exempt `public` types; XAML `x:ClassModifier` and constructor visibility stay AUDIT |
| VIRTUALIZATION | Keep UI virtualization active on scrollable WPF/WinUI collections (`client.md` Responsive UI for Large Lists) | — | AUDIT |
| NATIVEDEP | Self-contained single-file target without self-extraction or `.pdb` shipping (`client.md` Packaging and Distributable Footprint) | — | AUDIT |

---

## LOGGING: Log Output and Retention

Implements `client.md` (Logs on the Host Machine) in .NET:

- **Default directory and fallback**: write logs to `{AppContext.BaseDirectory}\Logs\`, falling back automatically when non-writable to `{Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData)}\{AppName}\Logs\`.
- **Rotation and naming**: rotate daily using `{AppName}_yyyyMMdd.log`.
- **Default retention policy**: retain the newest 30 log files by default (e.g., Serilog `retainedFileCountLimit`); an application whose cadence or log volume requires another bound overrides this count and states the value and reason in its application rules file.
- **Axis and configurability**: bind retention using the logging library's native count/age parameter (adding a total-size cap only alongside it, never instead of it), delete only files matching `{AppName}_*.log` best-effort, follow `client.md` for log language, and validate configurable limits per `configuration.md` (when present) without allowing invalid settings to disable cleanup.

## XAML-VISIBILITY: XAML Entry Points

Refines `dotnet.md` (VISIBILITY) for WPF and WinUI 3 XAML types where generated partials must match code-behind modifiers (`CS0262`):

- **WPF**: set `x:ClassModifier="internal"` on `App.xaml` and every XAML root declaring `x:Class` (e.g., windows, `UserControl`, `Page`, and code-behind `ResourceDictionary`) to match `internal sealed partial class` (for concrete non-base code-behinds); keep a `public` parameterless constructor on any XAML root instantiated directly by XAML `Activator.CreateInstance` (e.g., `StartupUri`).
- **WinUI 3**: keep concrete non-`App` XAML code-behinds (e.g., windows, `UserControl`, `Page`, and code-behind `ResourceDictionary`) `internal sealed partial class`, and keep `App` `public` with `[SuppressMessage]` for `CA1515` because XAML compilation generates `public partial class App` in `XamlTypeInfo.g.cs` without supporting `x:ClassModifier`; never set `NoTypeInfoCodeGen` to bypass this, as XAML type resolution depends on generated type info.

## VIRTUALIZATION: List Virtualization

Implements `client.md` (Responsive UI for Large Lists) in WPF and WinUI 3:

- **Preserve panel virtualization**: keep virtualization active on `DataGrid`, `ListView`, `ListBox`, and `ItemsRepeater`; never disable `VirtualizingPanel.IsVirtualizing` or place virtualized controls inside layout containers that measure children with infinite height (e.g., `ScrollViewer` or vertical `StackPanel`).

## NATIVEDEP: Native Dependencies and Publish Layout

Implements `client.md` (Packaging and Distributable Footprint) in .NET:

- **Earn single-file publishing without self-extraction**: target `PublishSingleFile` by avoiding NuGet packages carrying native binaries or stripping unreachable transitive native assets (`ExcludeAssets="all"` or managed `AppContext` switches); never set `IncludeNativeLibrariesForSelfExtract` or `IncludeAllContentForSelfExtract`.
- **Disable single-file on self-extracting frameworks**: on frameworks such as WinUI 3 where single-file publishing implicitly enables `IncludeAllContentForSelfExtract`, publish side-by-side without `PublishSingleFile`.
- **Ship remaining native libraries beside the executable and strip symbols**: leave unavoidable runtime/UI native binaries beside the executable, package the entire publish output directory rather than naming only the executable, and keep `.pdb` files out of the published package unless the application rules file explicitly requires shipping symbols for field crash diagnostics per `client.md`.
