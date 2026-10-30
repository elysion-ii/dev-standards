# Starts a disposable SQL Server container and builds every database project beside this
# script into it, for manual checks and for automated tests alike.
#
# The container runs in the WSL distribution Setup-SqlServerHost.ps1 prepares (created on
# the first run). Its SQL Server version and server collation come from the projects'
# DatabaseOptions.props, so it matches the servers the schemas were exported from. Each
# run gets a new container with a random sa password, and no data: whatever a check or a
# test needs, it inserts itself. Remove the container with Stop-TestSqlServer.ps1.
#
# Prints the connection details; -OutputFile also writes them as JSON for a caller.

param(
    [string]$Name = ("sqltest-" + [guid]::NewGuid().ToString("N").Substring(0, 8)),
    [string]$DistroName = "sqlserver-test",
    [string]$OutputFile,
    [int]$ReadyTimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"
$env:WSL_UTF8 = "1"

$ProjectsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# SQL Server major version (from the schema provider name) -> container image
$Images = @{
    140 = "mcr.microsoft.com/mssql/server:2017-latest"
    150 = "mcr.microsoft.com/mssql/server:2019-latest"
    160 = "mcr.microsoft.com/mssql/server:2022-latest"
    170 = "mcr.microsoft.com/mssql/server:2025-latest"
}

function Invoke-Wsl([string[]]$Arguments) {
    $output = & wsl.exe -d $DistroName -u root -- @Arguments
    if ($LASTEXITCODE -ne 0) { throw "wsl $($Arguments -join ' ') failed (exit code $LASTEXITCODE)" }
    return $output
}

# Every project with its options and the projects it references, so references publish first
function Get-Projects {
    $projects = @{}
    foreach ($file in Get-ChildItem $ProjectsRoot -Filter *.sqlproj -Recurse -Depth 1) {
        if ($file.Directory.Parent.FullName -ne $ProjectsRoot) { continue }
        $optionsFile = Join-Path $file.DirectoryName "DatabaseOptions.props"
        if (-not (Test-Path $optionsFile)) { throw "$optionsFile is missing; run Export-Schema first" }
        $options = ([xml](Get-Content $optionsFile -Raw -Encoding UTF8)).Project.PropertyGroup
        $references = @(([xml](Get-Content $file.FullName -Raw -Encoding UTF8)).Project.ItemGroup.ProjectReference |
            Where-Object { $_ } | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Include) })
        $projects[$file.BaseName] = @{
            Name = $file.BaseName
            File = $file.FullName
            Dacpac = Join-Path $file.DirectoryName "bin\Debug\$($file.BaseName).dacpac"
            Version = [int]($options.DSP -replace '^.*\.Sql(\d+)DatabaseSchemaProvider$', '$1')
            Collation = $options.DefaultCollation
            References = $references
        }
    }
    if ($projects.Count -eq 0) { throw "No database project under $ProjectsRoot; run Export-Schema first" }
    return $projects
}

function Get-PublishOrder($Projects) {
    $order = New-Object System.Collections.ArrayList
    $visiting = @{}
    function Visit([string]$ProjectName) {
        if ($order -contains $ProjectName) { return }
        if ($visiting[$ProjectName]) { throw "Project references form a cycle at $ProjectName" }
        if (-not $Projects.ContainsKey($ProjectName)) { throw "A project references $ProjectName, which is not under $ProjectsRoot" }
        $visiting[$ProjectName] = $true
        foreach ($reference in $Projects[$ProjectName].References) { Visit $reference }
        [void]$order.Add($ProjectName)
    }
    foreach ($projectName in ($Projects.Keys | Sort-Object)) { Visit $projectName }
    return $order
}

function Get-SingleValue($Projects, [string]$Property) {
    $values = @($Projects.Values | ForEach-Object { $_[$Property] } | Sort-Object -Unique)
    if ($values.Count -ne 1) {
        throw "The projects disagree on $Property ($($values -join ', ')); one container cannot serve them all"
    }
    return $values[0]
}

$projects = Get-Projects
$publishOrder = Get-PublishOrder $projects
$version = Get-SingleValue $projects "Version"
$collation = Get-SingleValue $projects "Collation"
$image = $Images[$version]
if (-not $image) { throw "No container image is known for schema provider version $version" }

# Build first: a project that does not build should fail before a container exists
Push-Location $ProjectsRoot
try {
    # sqlpackage is pinned in the repository's dotnet tool manifest
    dotnet tool restore | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "dotnet tool restore failed" }
    $localTools = dotnet tool list --local | Out-String
    if ($localTools -notmatch '(?im)^\s*microsoft\.sqlpackage\s') {
        throw "sqlpackage is not in the repository's dotnet tool manifest; at the repository root run 'dotnet new tool-manifest' (when there is none) and 'dotnet tool install microsoft.sqlpackage'"
    }

    foreach ($projectName in $publishOrder) {
        Write-Host "Building $projectName..." -ForegroundColor Green
        $buildOutput = dotnet build $projects[$projectName].File -nologo -v q
        if ($LASTEXITCODE -ne 0) {
            $buildOutput | Where-Object { $_ -match ' error ' } | Write-Host
            throw "Building $projectName failed"
        }
    }
} finally {
    Pop-Location
}

$registered = @(wsl.exe --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($registered -notcontains $DistroName) {
    & (Join-Path $ProjectsRoot "Setup-SqlServerHost.ps1") -DistroName $DistroName
}

# sa password rules: upper, lower, digit, and symbol
$password = "Aa1!" + [guid]::NewGuid().ToString("N")

Write-Host "Starting $Name ($image, $collation)..." -ForegroundColor Green
Invoke-Wsl @("docker", "run", "-d", "--name", $Name, "--label", "purpose=sqlserver-test",
    "-e", "ACCEPT_EULA=Y", "-e", "MSSQL_PID=Developer", "-e", "MSSQL_SA_PASSWORD=$password",
    "-e", "MSSQL_COLLATION=$collation", "-p", "1433", $image) | Out-Null

try {
    # WSL stops a distribution that no process uses, and Docker with it, so a hidden process
    # waits on the container for as long as the container exists
    Start-Process wsl.exe -ArgumentList @("-d", $DistroName, "-u", "root", "--", "docker", "wait", $Name) -WindowStyle Hidden

    # Windows reaches the container through the distribution's address, not localhost
    $address = ((Invoke-Wsl @("hostname", "-I")) -split '\s+')[0]
    $port = ((Invoke-Wsl @("docker", "port", $Name, "1433")) | Select-Object -First 1) -replace '^.*:', ''
    $server = "$address,$port"
    $masterConnection = "Server=$server;Database=master;User ID=sa;Password=$password;Encrypt=False;Connect Timeout=5"

    Write-Host "Waiting for SQL Server at $server..." -ForegroundColor Green
    $deadline = (Get-Date).AddSeconds($ReadyTimeoutSeconds)
    while ($true) {
        $connection = New-Object System.Data.SqlClient.SqlConnection $masterConnection
        try {
            $connection.Open()
            break
        } catch {
            if ((Get-Date) -gt $deadline) { throw "SQL Server did not accept connections within $ReadyTimeoutSeconds seconds: $($_.Exception.GetBaseException().Message)" }
            Start-Sleep -Seconds 2
        } finally {
            $connection.Dispose()
        }
    }

    Push-Location $ProjectsRoot
    try {
        foreach ($projectName in $publishOrder) {
            Write-Host "Publishing $projectName..." -ForegroundColor Green
            $target = "Server=$server;Database=$projectName;User ID=sa;Password=$password;Encrypt=False"
            $publishOutput = dotnet sqlpackage -a:Publish "-sf:$($projects[$projectName].Dacpac)" "-tcs:$target" -p:CreateNewDatabase=true
            if ($LASTEXITCODE -ne 0) {
                $publishOutput | Select-Object -Last 20 | Write-Host
                throw "Publishing $projectName failed"
            }
        }
    } finally {
        Pop-Location
    }
} catch {
    Write-Host "Removing $Name after the failure" -ForegroundColor Yellow
    & wsl.exe -d $DistroName -u root -- docker rm -f $Name | Out-Null
    throw
}

$result = [ordered]@{
    container = $Name
    distro = $DistroName
    server = $server
    user = "sa"
    password = $password
    databases = @($publishOrder)
}
if ($OutputFile) {
    [System.IO.File]::WriteAllText($OutputFile, ($result | ConvertTo-Json), (New-Object System.Text.UTF8Encoding $false))
}

Write-Host "`n=== $Name is ready ===" -ForegroundColor Green
Write-Host "Server   : $server"
Write-Host "User     : sa"
Write-Host "Password : $password"
Write-Host "Databases: $($publishOrder -join ', ')"
Write-Host "Remove it with: Stop-TestSqlServer.ps1 -Name $Name"
