# Windows development export validation

## Preset

`export_presets.cfg` defines the `Windows Desktop` debug preset. It exports all runtime resources while excluding local source packs, vendor archives, validation artifacts, documentation, and tests.

## Current environment result

On 2026-08-02, the project was validated with the official portable Godot `4.7.1.stable.official.a13da4feb` executable at `C:\Users\Doc\AppData\Local\GodotPortable\4.7.1\Godot_v4.7.1-stable_win64_console.exe`. Its matching official Windows templates are installed in `%APPDATA%\Godot\export_templates\4.7.1.stable`.

`python tools/verify_export_environment.py --godot <portable-engine>` passed. Repository validation, all 31 native test suites, the runtime smoke test, and headless editor initialization also passed on that engine.

The following command completed successfully and wrote an ignored Windows development build:

```powershell
<portable-engine> --headless --path . --export-debug "Windows Desktop" "exports/SixBrandsAtHighNoon.exe"
```

The resulting `exports/SixBrandsAtHighNoon.exe` is 102,982,144 bytes and its accompanying PCK is 33,702,504 bytes. The executable also launched successfully with `--headless --quit-after 12` while the process used an isolated temporary `APPDATA` directory. This automated launch is not a substitute for the plan's user-observed clean-Windows-profile, controller, and display-mode passes.

The preset excludes `assets/source/*`, `assets/MahjongRPG/*`, `vendor/local/*`, `artifacts/local/*`, documentation, and tests. No source archive has been added to the repository.
