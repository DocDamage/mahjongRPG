# Windows release-candidate evidence

## Candidate contract

- Version: `1.0.0-rc.1`
- Target: Windows x86_64, Godot `4.7.1.stable`
- Game-save compatibility: schemas `1–21` migrate forward to schema `21`
- Settings compatibility: schemas `1–2` migrate forward to schema `2`
- Rollback source: the last accepted P16 package and its copied save directory

## Automated release gate

Run from the repository root with the explicit Godot 4.7.1 console executable:

```powershell
$SixBrandsGodot = 'C:\Users\Doc\AppData\Local\GodotPortable\4.7.1\Godot_v4.7.1-stable_win64_console.exe'
python tools/validate_repository.py
& $SixBrandsGodot --headless --path . --script res://tests/test_runner.gd
& $SixBrandsGodot --headless --path . --script res://tests/smoke_test.gd
& $SixBrandsGodot --headless --path . --script res://tests/release_performance_smoke.gd
& $SixBrandsGodot --headless --path . --editor --quit
python tools/verify_export_environment.py --godot $SixBrandsGodot
& $SixBrandsGodot --headless --path . --export-release 'Windows Desktop' 'exports/SixBrandsAtHighNoon.exe'
python tools/verify_release_candidate.py
python tools/package_windows_release.py
```

The release suite includes all public-schema restore paths, primary-save checksum recovery via backup, settings-schema migration, resource/audio/localization coverage, a bounded cold scene-initialization guard, and a package-contract check. The headless performance guard is not a rendered 60-FPS benchmark; the physical display matrix remains the rendered performance/stutter gate.

| Gate | Date / commit | Evidence | Result |
| --- | --- | --- | --- |
| Repository, suite, smoke, editor, preflight | 2026-08-03 / pre-commit worktree | Validator passed; 46 suites passed; smoke/editor/preflight passed | Pass |
| Headless cold initialization | 2026-08-03 / pre-commit worktree | 10 release scenes initialized in 1,062.4 ms (10,000 ms budget), without leak output | Pass |
| Release export and package checksum | 2026-08-03 / pre-commit worktree | `SixBrandsAtHighNoon.pck` 6,366,308 bytes; package `SixBrandsAtHighNoon-1.0.0-rc.1-final5`; PCK SHA-256 `f09ce166ebd04c5153dd553040014a3e95375e8b01b2df717c04ef3bb95120ea` | Pass |
| Keyboard/controller/display physical matrix | Human tester required | `docs/qa/manual_device_display_matrix.md` | Pending |
| Clean Windows installation and representative finale/postgame resume | Human tester required | Installation observation | Pending |

No pending row may be described as passed in public release communications.
