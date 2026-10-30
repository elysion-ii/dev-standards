# Prepares a dedicated WSL distribution that runs Docker Engine, the host for disposable
# SQL Server test containers.
#
# The distribution is created for this purpose only and is never shared with other work,
# so tests start from a known state on every machine. Running the script again is safe:
# each step checks whether it is already done. Remove everything it created with
#   wsl --unregister <DistroName>

param(
    [string]$DistroName = "sqlserver-test",
    # A distribution name accepted by 'wsl --install'
    [string]$BaseDistro = "Ubuntu-24.04"
)

$ErrorActionPreference = "Stop"
# wsl.exe writes UTF-16 unless told otherwise, which PowerShell 5.1 misreads
$env:WSL_UTF8 = "1"

function Invoke-InDistro([string]$Script) {
    # Passed as base64, because PowerShell 5.1 ends piped input with a CR that bash rejects
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Script.Replace("`r`n", "`n"))
    $encoded = [System.Convert]::ToBase64String($bytes)
    wsl.exe -d $DistroName -u root -- bash -c "echo $encoded | base64 -d | bash"
    if ($LASTEXITCODE -ne 0) { throw "The provisioning step failed inside $DistroName (exit code $LASTEXITCODE)" }
}

wsl.exe --status | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "WSL is not available. Run 'wsl --install --no-distribution' as an administrator, restart Windows, then run this script again"
}

$registered = @(wsl.exe --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ })
if ($registered -contains $DistroName) {
    Write-Host "$DistroName already exists" -ForegroundColor Cyan
} else {
    Write-Host "Creating $DistroName from $BaseDistro..." -ForegroundColor Green
    wsl.exe --install $BaseDistro --name $DistroName --no-launch
    if ($LASTEXITCODE -ne 0) { throw "wsl --install failed" }
}

Write-Host "Installing Docker Engine and enabling systemd..." -ForegroundColor Green
Invoke-InDistro @'
set -eu
export DEBIAN_FRONTEND=noninteractive
if ! command -v dockerd >/dev/null 2>&1; then
  apt-get update -qq
  apt-get install -y -qq docker.io >/dev/null
fi
# dockerd is started by systemd whenever the distribution starts
if ! grep -qs '^[[:space:]]*systemd[[:space:]]*=[[:space:]]*true' /etc/wsl.conf; then
  printf '\n[boot]\nsystemd=true\n' >> /etc/wsl.conf
fi
'@

# wsl.conf is read when the distribution starts, so restart it to bring systemd up
wsl.exe --terminate $DistroName | Out-Null

Write-Host "Starting Docker..." -ForegroundColor Green
Invoke-InDistro @'
set -eu
systemctl enable --now docker >/dev/null 2>&1
for i in $(seq 1 30); do
  if docker info >/dev/null 2>&1; then exit 0; fi
  sleep 1
done
echo "Docker did not become ready within 30 seconds" >&2
exit 1
'@

$version = wsl.exe -d $DistroName -u root -- docker version --format "{{.Server.Version}}"
Write-Host "`n=== $DistroName is ready: Docker Engine $version ===" -ForegroundColor Green
