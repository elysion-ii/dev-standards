# Exports database schemas into SQL database projects at <this folder>/<database>/.
#
# The databases to export, and where each one is read from, are listed in
# export-schema.json beside this script. That file is local to each developer and
# untracked; the first run creates it from the tracked export-schema.template.json and
# stops so the server names can be filled in. Each run regenerates the object scripts
# (sqlpackage Extract) and DatabaseOptions.props (collation, ANSI settings, target
# platform) from the source database. <database>.sqlproj is created on the first export and
# kept afterwards, so references and exclusions written into it survive later exports.
#
# A "SqlServer" entry whose user or password is empty in the file is prompted for at run
# time, once per server and user. "Windows" entries use Windows authentication.

param(
    [string]$ConfigPath,
    # Export only these databases from the file (default: all of them)
    [string[]]$Database
)

$ErrorActionPreference = "Stop"

$OutputRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ConfigPath) { $ConfigPath = Join-Path $OutputRoot "export-schema.json" }
if (-not (Test-Path $ConfigPath)) {
    $templatePath = Join-Path $OutputRoot "export-schema.template.json"
    if (-not (Test-Path $templatePath)) { throw "Neither $ConfigPath nor $templatePath exists" }
    Copy-Item $templatePath $ConfigPath
    Write-Host "Created $ConfigPath from the template. Fill in each server, then run again." -ForegroundColor Yellow
    exit 1
}
$Config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
$Entries = @($Config.databases)
$noServer = @($Entries | Where-Object { -not $_.server } | ForEach-Object { $_.name })
if ($noServer) { throw "No server is set in ${ConfigPath} for: $($noServer -join ', ')" }
if ($Database) {
    # powershell -File passes "a,b" as one string, so split it here as well
    $names = @($Database | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $unknown = @($names | Where-Object { $Entries.name -notcontains $_ })
    if ($unknown) { throw "Not listed in ${ConfigPath}: $($unknown -join ', ')" }
    $Entries = @($Entries | Where-Object { $names -contains $_.name })
}

# Master database references per SQL Server major version (Microsoft.SqlServer.Dacpacs.Master)
$MasterDacpacVersions = @{ 11 = "110.0.0"; 12 = "120.0.0"; 13 = "130.0.2"; 14 = "140.0.4"; 15 = "150.1.2"; 16 = "160.2.8"; 17 = "170.0.4" }
$SqlSdkVersion = "2.3.0"

# Credentials typed at run time, keyed by server and the user named in the file
$CredentialCache = @{}

function Resolve-Credential($Entry) {
    $key = "$($Entry.server)|$($Entry.user)"
    if ($CredentialCache.ContainsKey($key)) { return $CredentialCache[$key] }
    $user = $Entry.user
    if (-not $user) { $user = Read-Host "User ID for $($Entry.server)" }
    if ($Entry.password) {
        $password = $Entry.password
    } else {
        $secure = Read-Host "Password for $user@$($Entry.server)" -AsSecureString
        $password = [System.Net.NetworkCredential]::new("", $secure).Password
    }
    $CredentialCache[$key] = @{ User = $user; Password = $password }
    return $CredentialCache[$key]
}

# Servers differ in whether they offer encryption and whether their certificate can be
# verified, and the person running the export rarely knows which, so the combinations are
# tried from the safest one and the first that connects is used
$EncryptionAttemptOrder = @(
    @{ Encrypt = $true;  TrustServerCertificate = $false },
    @{ Encrypt = $true;  TrustServerCertificate = $true },
    @{ Encrypt = $false; TrustServerCertificate = $false }
)

function New-ConnectionString($Entry) {
    $builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
    $builder["Data Source"] = $Entry.server
    $builder["Initial Catalog"] = $Entry.name
    switch ($Entry.authentication) {
        "Windows" { $builder["Integrated Security"] = $true }
        "SqlServer" {
            $credential = Resolve-Credential $Entry
            $builder["User ID"] = $credential.User
            $builder["Password"] = $credential.Password
        }
        default { throw "$($Entry.name): authentication must be 'Windows' or 'SqlServer'" }
    }
    for ($i = 0; $i -lt $EncryptionAttemptOrder.Count; $i++) {
        $attempt = $EncryptionAttemptOrder[$i]
        $builder["Encrypt"] = $attempt.Encrypt
        $builder["TrustServerCertificate"] = $attempt.TrustServerCertificate
        $settings = "Encrypt=$($attempt.Encrypt), TrustServerCertificate=$($attempt.TrustServerCertificate)"
        $connection = New-Object System.Data.SqlClient.SqlConnection $builder.ConnectionString
        try {
            $connection.Open()
            Write-Host "$($Entry.name): connected with $settings" -ForegroundColor Cyan
            return $builder.ConnectionString
        } catch {
            if ($i -eq $EncryptionAttemptOrder.Count - 1) { throw }
            Write-Host "$($Entry.name): $settings failed ($($_.Exception.GetBaseException().Message)); trying the next setting" -ForegroundColor Yellow
        } finally {
            $connection.Dispose()
        }
    }
}

# Reads the settings that change query results, so a database built from the project behaves like the source
function Get-DatabaseOptions([string]$ConnectionString) {
    $sql = @"
SELECT d.collation_name, d.compatibility_level,
       d.is_ansi_nulls_on, d.is_ansi_padding_on, d.is_ansi_warnings_on,
       d.is_ansi_null_default_on, d.is_arithabort_on, d.is_concat_null_yields_null_on,
       d.is_quoted_identifier_on, d.is_numeric_roundabort_on,
       d.snapshot_isolation_state, d.is_read_committed_snapshot_on,
       CAST(SERVERPROPERTY('ProductMajorVersion') AS int) AS product_major_version
FROM sys.databases d
WHERE d.name = DB_NAME();
"@
    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $sql
        $reader = $command.ExecuteReader()
        try {
            if (-not $reader.Read()) { throw "sys.databases returned no row" }
            $row = @{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) { $row[$reader.GetName($i)] = $reader.GetValue($i) }
            return $row
        } finally { $reader.Dispose() }
    } finally { $connection.Dispose() }
}

function Write-Utf8([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding $false))
}

function Write-DatabaseOptionsProps([string]$Path, [hashtable]$Options) {
    function B($value) { if ($value) { "True" } else { "False" } }
    Write-Utf8 $Path @"
<!-- Generated by Export-Schema.ps1 from the source database. Do not edit; re-run the script. -->
<Project>
  <PropertyGroup>
    <DSP>Microsoft.Data.Tools.Schema.Sql.Sql$($Options.product_major_version)0DatabaseSchemaProvider</DSP>
    <DefaultCollation>$($Options.collation_name)</DefaultCollation>
    <CompatibilityMode>$($Options.compatibility_level)</CompatibilityMode>
    <AnsiNulls>$(B $Options.is_ansi_nulls_on)</AnsiNulls>
    <AnsiPadding>$(B $Options.is_ansi_padding_on)</AnsiPadding>
    <AnsiWarnings>$(B $Options.is_ansi_warnings_on)</AnsiWarnings>
    <AnsiNullDefault>$(B $Options.is_ansi_null_default_on)</AnsiNullDefault>
    <ArithAbort>$(B $Options.is_arithabort_on)</ArithAbort>
    <ConcatNullYieldsNull>$(B $Options.is_concat_null_yields_null_on)</ConcatNullYieldsNull>
    <QuotedIdentifier>$(B $Options.is_quoted_identifier_on)</QuotedIdentifier>
    <NumericRoundAbort>$(B $Options.is_numeric_roundabort_on)</NumericRoundAbort>
    <AllowSnapshotIsolation>$(B ($Options.snapshot_isolation_state -eq 1))</AllowSnapshotIsolation>
    <ReadCommittedSnapshot>$(B $Options.is_read_committed_snapshot_on)</ReadCommittedSnapshot>
  </PropertyGroup>
</Project>
"@
}

function New-SqlProject([string]$Path, [string]$DatabaseName, [int]$MajorVersion) {
    $masterVersion = $MasterDacpacVersions[$MajorVersion]
    if (-not $masterVersion) { throw "No master dacpac version is known for SQL Server major version $MajorVersion" }
    Write-Utf8 $Path @"
<Project Sdk="Microsoft.Build.Sql/$SqlSdkVersion">
  <!-- Collation, ANSI settings, and target platform exported from the source database -->
  <Import Project="DatabaseOptions.props" />
  <PropertyGroup>
    <Name>$DatabaseName</Name>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.SqlServer.Dacpacs.Master" Version="$masterVersion" />
  </ItemGroup>
</Project>
"@
}

# Logins, users, and role memberships belong to the source server, which a test server is not.
# A schema owned by a removed user is dropped when it holds no objects, and otherwise handed
# to dbo, so the remaining scripts still resolve.
function Remove-ServerBoundObjects([string]$ExtractDir) {
    $securityDir = Join-Path $ExtractDir "Security"
    if (-not (Test-Path $securityDir)) { return }
    $removedUsers = @()
    Get-ChildItem $securityDir -Recurse -File | ForEach-Object {
        $text = Get-Content $_.FullName -Raw -Encoding UTF8
        if ($text -match '(?im)^\s*CREATE\s+USER\s+\[([^\]]+)\]') { $removedUsers += $Matches[1] }
        if ($text -match '(?im)^\s*(CREATE\s+LOGIN|CREATE\s+USER|ALTER\s+ROLE\s+.+\s+ADD\s+MEMBER)\b') {
            Remove-Item $_.FullName -Force
        }
    }
    Get-ChildItem $securityDir -Recurse -File | ForEach-Object {
        $text = Get-Content $_.FullName -Raw -Encoding UTF8
        if ($text -match '(?im)^\s*CREATE\s+SCHEMA\s+\[([^\]]+)\]\s+AUTHORIZATION\s+\[([^\]]+)\]' -and
            $removedUsers -contains $Matches[2]) {
            $schema = $Matches[1]
            if (Test-Path (Join-Path $ExtractDir $schema)) {
                $text = $text -replace ('AUTHORIZATION\s+\[' + [regex]::Escape($Matches[2]) + '\]'), 'AUTHORIZATION [dbo]'
                [System.IO.File]::WriteAllText($_.FullName, $text, (New-Object System.Text.UTF8Encoding $true))
            } else {
                Remove-Item $_.FullName -Force
            }
        }
    }
    Get-ChildItem $securityDir -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending |
        Where-Object { -not (Get-ChildItem $_.FullName -Force) } | Remove-Item -Force
    if (-not (Get-ChildItem $securityDir -Force)) { Remove-Item $securityDir -Force }
}

# Two runs on one output folder delete and rename each other's files, so only one may run
$mutexName = "Global\ExportSchema_" + [System.BitConverter]::ToString(
    [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($OutputRoot.ToLowerInvariant()))).Replace("-", "")
$mutex = New-Object System.Threading.Mutex($false, $mutexName)
try {
    if (-not $mutex.WaitOne(0)) { throw "Another Export-Schema run is already using $OutputRoot" }
} catch [System.Threading.AbandonedMutexException] {
    # The previous holder ended without releasing; the work area it left is cleared below
}

# Work happens inside the output folder: only the run holding the mutex uses it, so whatever
# an interrupted run left there is cleared here, and finished exports move into place on the
# same volume
$WorkRoot = Join-Path $OutputRoot ".export-work"

# sqlpackage is pinned in the repository's dotnet tool manifest
Push-Location $OutputRoot
try {
    if (Test-Path $WorkRoot) { Remove-Item $WorkRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $WorkRoot | Out-Null

    dotnet tool restore | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "dotnet tool restore failed" }
    $localTools = dotnet tool list --local | Out-String
    if ($localTools -notmatch '(?im)^\s*microsoft\.sqlpackage\s') {
        throw "sqlpackage is not in the repository's dotnet tool manifest; at the repository root run 'dotnet new tool-manifest' (when there is none) and 'dotnet tool install microsoft.sqlpackage'"
    }

    # Ask for every credential first, so the exports then run without waiting on input
    $connectionStrings = @{}
    foreach ($entry in $Entries) { $connectionStrings[$entry.name] = New-ConnectionString $entry }

    foreach ($entry in $Entries) {
        $databaseName = $entry.name
        Write-Host "`n=== Exporting $databaseName from $($entry.server) ===" -ForegroundColor Green
        $projectDir = Join-Path $OutputRoot $databaseName
        $projectFile = Join-Path $projectDir "$databaseName.sqlproj"
        $connectionString = $connectionStrings[$databaseName]
        $extractDir = Join-Path $WorkRoot $databaseName
        $previousDir = Join-Path $WorkRoot "$databaseName.previous"

        dotnet sqlpackage -a:Extract "-scs:$connectionString" "-tf:$extractDir" `
            -p:ExtractTarget=SchemaObjectType -p:ExtractApplicationScopedObjectsOnly=true
        if ($LASTEXITCODE -ne 0) { throw "sqlpackage Extract failed for $databaseName" }
        Remove-ServerBoundObjects $extractDir
        $options = Get-DatabaseOptions $connectionString

        # Assemble the complete new folder first, then swap it in with two moves, so a
        # failure leaves either the previous export or the new one, never a mix
        Write-DatabaseOptionsProps (Join-Path $extractDir "DatabaseOptions.props") $options
        if (Test-Path $projectFile) {
            Copy-Item $projectFile $extractDir
        } else {
            New-SqlProject (Join-Path $extractDir "$databaseName.sqlproj") $databaseName ([int]$options.product_major_version)
            Write-Host "Created $projectFile" -ForegroundColor Cyan
        }
        if (Test-Path $projectDir) { Move-Item $projectDir $previousDir }
        Move-Item $extractDir $projectDir
    }
} finally {
    Pop-Location
    Remove-Item $WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}

Write-Host "`n=== Export finished ===" -ForegroundColor Green
