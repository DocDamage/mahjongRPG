# Six Brands at High Noon

A top-down, pixel-art Western cozy RPG built with Godot 4.7.1 for Windows.

Doc inherits Wayward Farm outside Mercy's Wake, a Gulf Coast frontier town where poker never took hold. Property, reputation, debts, political influence, and access to information are settled through a local one-on-one Mahjong variant called **Six Brands Mahjong**. Doc must master all six Brands, restore the legendary hall that Texas King converted into a private club, and uncover what happened to his missing uncle.

## Playable-slice status

This checkout contains the Phase 1 honest vertical slice and Phase 2 demo-delivery foundation. From the title shell, a player can start or load, configure accessibility preferences, complete First Lantern, use Mabel's daily crop-watering action, choose Orange/Blue before a match, plant any of four crops, save while mounted, recover a backup, and reach Riverbend. It is not a claim that the full planned game is complete.

## Technical target

- Godot 4.7.1
- Windows first
- 960×540 internal resolution
- 1920×1080 at 2× integer scaling
- Four-direction movement and controller-first support
- Project-owned handwritten files below 300 LOC where practical and safe

## Setup and validation

The large source archives are intentionally excluded from Git history. Place these verified ZIP files in `vendor/local/supplemental/`:

```text
Hero - Cowboy - AssetPack.zip
horses.zip
fishing UI.zip
Cozy SFX Volume 1.zip
```

`ffmpeg` with a Vorbis encoder is required for source audio normalization. Then run:

```bash
python tools/import_supplemental_assets.py
python tools/validate_repository.py
```

The importer verifies SHA-256 and ZIP integrity before normalizing the assets into the ignored `assets/source/supplemental/` directory. The approximately 838 MiB master split archive remains outside Git.

Use the target Godot 4.7.1 executable—not an arbitrary `godot` on `PATH`. The canonical setup, validation, recovery, archive, and troubleshooting instructions are in [Windows setup and recovery](docs/release/setup_and_recovery.md).

## Branch model

- `main`: stable milestones
- `develop`: integration branch
- `agent/*`: focused implementation branches and pull requests

## Documentation

- [Game vision](docs/design/game_vision.md)
- [World and story](docs/design/world_and_story.md)
- [Six Brands Mahjong](docs/design/six_brands_mahjong.md)
- [Cozy systems](docs/design/cozy_systems.md)
- [Hybrid vertical slice](docs/production/hybrid_vertical_slice.md)
- [Asset status](docs/assets/asset_status.md)
- [Supplemental integration](docs/assets/supplement_integration.md)
- [Repository architecture](docs/architecture/repository_structure.md)
- [File-size policy](docs/architecture/file_size_policy.md)
- [Test-to-module coverage inventory](docs/qa/test_to_module_coverage.md)
- [Manual device/display/accessibility matrix](docs/qa/manual_device_display_matrix.md)
- [Windows setup and recovery](docs/release/setup_and_recovery.md)

## Licensing

The supplied third-party asset license is stored under `legal/`. The original project's proprietary source-code disposition is explicit in [legal/PROPRIETARY_SOURCE_NOTICE.md](legal/PROPRIETARY_SOURCE_NOTICE.md).
