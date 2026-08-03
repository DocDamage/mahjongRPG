param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [string]$ProfileRoot = (Join-Path $env:TEMP 'six-brands-clean-profile')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
    throw "Debug executable not found: $Executable"
}

New-Item -ItemType Directory -Force -Path $ProfileRoot | Out-Null
$environment = @{
    APPDATA = $ProfileRoot
    LOCALAPPDATA = $ProfileRoot
}
Write-Host "Launching with isolated profile: $ProfileRoot"
Start-Process -FilePath $Executable -WorkingDirectory (Split-Path -Parent $Executable) -Wait -Environment $environment
