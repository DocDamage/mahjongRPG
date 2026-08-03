param(
    [string]$Godot = ""
)

$ErrorActionPreference = "Stop"
$documentedGodot = "C:\Users\Doc\AppData\Local\GodotPortable\4.7.1\Godot_v4.7.1-stable_win64_console.exe"
if ([string]::IsNullOrWhiteSpace($Godot)) {
    $configured = Get-Item -LiteralPath Env:GODOT_4_7_1 -ErrorAction SilentlyContinue
    if ($null -ne $configured) {
        $Godot = $configured.Value
    } elseif (Test-Path -LiteralPath $documentedGodot) {
        $Godot = $documentedGodot
    } else {
        $command = Get-Command godot -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            $Godot = $command.Source
        }
    }
}
if ([string]::IsNullOrWhiteSpace($Godot) -or -not (Test-Path -LiteralPath $Godot)) {
    Write-Error "Godot 4.7.1 was not found. Set GODOT_4_7_1 or pass -Godot."
    exit 1
}
$version = (& $Godot --version | Select-Object -First 1)
if (-not $version.StartsWith("4.7.1")) {
    Write-Error "Content validation requires Godot 4.7.1; found $version."
    exit 1
}
python tools/validate_repository.py
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
& $Godot --headless --path . --script res://tools/validate_content.gd
exit $LASTEXITCODE
