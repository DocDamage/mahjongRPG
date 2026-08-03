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

For normal source-asset verification, install `Python 3.12`. Install `ffmpeg` with a Vorbis encoder only when regenerating normalized supplemental audio. Install `7-Zip` only when auditing optional historical master split archives. The tracked debug build does not require either source rebuilding or archive files because its generated runtime assets are versioned.

## Source asset evidence

The expanded source asset trees already supplied in `assets/` are authoritative. Verify without modifying generated content:

```powershell
python tools/import_supplemental_assets.py --expanded-source-dir assets --verify-only
python tools/import_master_assets.py --expanded-source-dir assets/MahjongRPG --verify-only
```

The historical supplemental ZIPs and master split archive can be placed under `vendor/local/` to verify their provenance, but their absence does not block P2 while the expanded source trees are present. Never substitute re-zipped or incomplete content for an original archive when performing provenance verification.

## Save recovery

Godot maps `user://saves` to `%APPDATA%\Godot\app_userdata\Six Brands at High Noon\saves` on Windows. Every slot is JSON with a SHA-256 checksum. A later successful save moves the former primary to the same filename with `.backup` appended.

If a slot will not load, close the game, copy both files elsewhere, and replace `manual_N.json` with `manual_N.json.backup` after removing the `.backup` suffix. The game automatically attempts this backup when the primary is corrupt. `pre_finale.json` is reserved and is captured automatically immediately before Texas King's championship; do not use it as an ordinary manual slot. Loading it returns to the safe pre-table state, so the championship can be started again without losing prior world progress.

## Clean-profile launch

Use the included helper to create an isolated Windows profile for the manual P18 release checkpoint:

```powershell
.\tools\launch_clean_profile.ps1 -Executable .\exports\SixBrandsAtHighNoon.exe
```

Complete the corresponding clean-profile and release-install/resume rows in the manual matrix after the player-visible launch, configuration, representative loop, finale/postgame transition, relaunch, and load have been observed.

## Release-candidate package

Create a release candidate only after the full validation block above passes:

```powershell
& $SixBrandsGodot --headless --path . --export-release 'Windows Desktop' 'exports/SixBrandsAtHighNoon.exe'
python tools/verify_release_candidate.py
python tools/package_windows_release.py
```

The packager refuses to overwrite an existing folder and creates `exports/release/SixBrandsAtHighNoon-<version>/` with the executable, PCK, CC0 asset-license notice, release notes, recovery guide, and SHA-256 manifest. Verify the package again with `python tools/verify_release_candidate.py --package-dir <folder>`. The package directory is intentionally ignored by Git.

The release-candidate contract and honest automated/manual evidence ledger are in [release_candidate_evidence.md](release_candidate_evidence.md). Do not publish until its human hardware/install rows are signed off.

## Troubleshooting

- Missing `ffmpeg`: install it and ensure `ffmpeg -encoders` includes `libvorbis` or `vorbis`.
- Export preflight reports a wrong engine: pass the explicit 4.7.1 console path shown above.
- Archive verification fails: check filename, byte-identical source, checksum, and the complete split set before retrying.
- A manual matrix row fails: record the build commit and exact device/display state; do not mark the demo gate as passed.
