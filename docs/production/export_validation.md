# Windows development export validation

## Preset

`export_presets.cfg` defines the `Windows Desktop` debug preset. It exports all runtime resources while excluding local source packs, vendor archives, validation artifacts, documentation, and tests.

## Current environment result

On 2026-08-02, the installed executable was Godot `4.6.2.stable.official.71f334935` at `C:\Users\Doc\AppData\Local\Microsoft\WinGet\Links\godot.exe`.

The checked-in plan requires Godot 4.7.1; this executable was not replaced. A quoted headless debug-export attempt correctly found the preset but failed because this machine lacks the Godot 4.6.2 Windows export templates:

```text
C:/Users/Doc/AppData/Roaming/Godot/export_templates/4.6.2.stable/windows_debug_x86_64.exe
C:/Users/Doc/AppData/Roaming/Godot/export_templates/4.6.2.stable/windows_release_x86_64.exe
```

Therefore no Windows binary is claimed as validated. Install the exact Godot 4.7.1 executable and its matching export templates, then run:

```powershell
godot --headless --path . --export-debug "Windows Desktop" "exports/SixBrandsAtHighNoon.exe"
```
