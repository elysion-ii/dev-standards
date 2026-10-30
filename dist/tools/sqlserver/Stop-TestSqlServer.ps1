# Removes a container Start-TestSqlServer.ps1 started, with everything in it.
# Without -Name, removes every container Start-TestSqlServer.ps1 started.

param(
    [string]$Name,
    [string]$DistroName = "sqlserver-test"
)

$ErrorActionPreference = "Stop"
$env:WSL_UTF8 = "1"

if ($Name) {
    $names = @($Name)
} else {
    $names = @(& wsl.exe -d $DistroName -u root -- docker ps -aq --filter "label=purpose=sqlserver-test")
    if ($LASTEXITCODE -ne 0) { throw "Listing the test containers failed" }
    $names = @($names | Where-Object { $_ })
}

foreach ($container in $names) {
    & wsl.exe -d $DistroName -u root -- docker rm -f $container | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Removing $container failed" }
    Write-Host "Removed $container"
}
if ($names.Count -eq 0) { Write-Host "No test container is running" }
