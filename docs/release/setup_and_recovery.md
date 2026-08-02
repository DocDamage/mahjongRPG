# Windows demo setup, validation, and save recovery

## Canonical toolchain

This project targets Godot `4.7.1.stable.official.a13da4feb`. Do not use an arbitrary `godot` executable from `PATH`; on the development machine it resolves to 4.6.2. Set a local variable to the explicit 4.7.1 console executable, then run:

```powershell
$SixBrandsGodot = 'C:\Users\Doc\AppData\Local\GodotPortable\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
python tools/validate_repository.py
& $SixBrandsGodot --headless --path . --script res://tests/test_runner.gd
& $SixBrandsGodot --headless --path . --script res://tests/smoke_test.gd
& $SixBrandsGodot --headless --path . --editor --quit
python tools/verify_export_environment.py --godot $SixBrandsGodot
```

For source-asset rebuilding, install `Python 3.12`, `ffmpeg` with a Vorbis encoder, and `7-Zip` for the master split archive. The tracked debug build does not require the ignored source archives because its generated runtime assets are versioned.

## Source archive evidence

Place the exact four supplemental ZIPs in `vendor/local/supplemental/` and all nine `MahjongRPG.z01`…`MahjongRPG.zip` parts in `vendor/local/master/`. These are deliberately ignored and must be supplied by the asset owner. Verify without modifying generated content:

```powershell
python tools/import_supplemental_assets.py --archive-source-dir vendor/local/supplemental --verify-only
python tools/import_master_assets.py --archive-source-dir vendor/local/master --verify-only --seven-zip 7z
```

The master manifest is only eligible to be pinned after the complete set passes integrity verification. Never substitute re-zipped or incomplete content for the supplied archives.

## Save recovery

Godot maps `user://saves` to `%APPDATA%\Godot\app_userdata\Six Brands at High Noon\saves` on Windows. Every slot is JSON with a SHA-256 checksum. A later successful save moves the former primary to the same filename with `.backup` appended.

If a slot will not load, close the game, copy both files elsewhere, and replace `manual_N.json` with `manual_N.json.backup` after removing the `.backup` suffix. The game automatically attempts this backup when the primary is corrupt. `pre_finale.json` is reserved for a future finale checkpoint and should not be used as an ordinary manual slot.

## Clean-profile launch

Use the included helper to create an isolated Windows profile for the manual P2 checkpoint:

```powershell
.\tools\launch_clean_profile.ps1 -Executable .\exports\SixBrandsAtHighNoon.exe
```

Complete the corresponding clean-profile row in the manual matrix after the player-visible launch, configuration, P1 playthrough, relaunch, and load have been observed.

## Troubleshooting

- Missing `ffmpeg`: install it and ensure `ffmpeg -encoders` includes `libvorbis` or `vorbis`.
- Export preflight reports a wrong engine: pass the explicit 4.7.1 console path shown above.
- Archive verification fails: check filename, byte-identical source, checksum, and the complete split set before retrying.
- A manual matrix row fails: record the build commit and exact device/display state; do not mark the demo gate as passed.
