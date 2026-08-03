# Six Brands at High Noon

A top-down, pixel-art Western cozy RPG built with Godot 4.7.1 for Windows.

Doc inherits Wayward Farm outside Mercy's Wake, a Gulf Coast frontier town where poker never took hold. Property, reputation, debts, political influence, and access to information are settled through a local one-on-one Mahjong variant called **Six Brands Mahjong**. Doc must master all six Brands, restore the legendary hall that Texas King converted into a private club, and uncover what happened to his missing uncle.

## Playable-slice status

This checkout contains the Phase 1–17 playable game and Phase 18 release-candidate tooling. After the Act III warning, the Hall captures a dedicated `pre_finale` backup before seating Texas King in a legal, counterable Frontier Rules championship. A lost match can be retried; a failed standoff retries locally without replaying Mahjong. The transparent choice/category evaluator yields one of four saved endings, followed by credits and a non-destructive postgame. The reopened public Hall offers repeatable advanced tournaments and a complete evidence/collection ledger while King's Reach, farm/animals, fishing, and existing world progress remain available. Saves migrate through schema 21 from every earlier schema; settings schema 2 forwards legacy preferences safely.

## Technical target

- Godot 4.7.1
- Windows first
- 960×540 internal resolution
- 1920×1080 at 2× integer scaling
- Four-direction movement and controller-first support
- Project-owned handwritten files below 300 LOC where practical and safe

## Setup and validation

The authoritative source assets are already expanded in the ignored `assets/` tree. Verify them with:

```powershell
python tools/import_supplemental_assets.py --expanded-source-dir assets --verify-only
python tools/import_master_assets.py --expanded-source-dir assets/MahjongRPG --verify-only
```

`ffmpeg` with a Vorbis encoder is required only when normalizing/reimporting audio. Original archives may be kept under `vendor/local/` for optional provenance verification. To regenerate supplemental imports, run:

```bash
python tools/import_supplemental_assets.py --expanded-source-dir assets
```

The supplemental importer normalizes the expanded source into ignored `assets/source/supplemental/`; `assets/MahjongRPG/` remains the expanded master source tree.

Use the target Godot 4.7.1 executable—not an arbitrary `godot` on `PATH`. The canonical setup, validation, recovery, archive, and troubleshooting instructions are in [Windows setup and recovery](docs/release/setup_and_recovery.md).

Quest/dialogue authors should also run the read-only production content report and optional advisory hooks documented in [Content validation and advisory tooling](docs/contributing/content-validation.md).

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
- [Phase 3–4 completion audit](docs/production/PHASE_3_4_COMPLETION_AUDIT_2026-08-02.md)
- [Phase 5–6 completion audit](docs/production/PHASE_5_6_COMPLETION_AUDIT_2026-08-02.md)
- [Phase 7–8 completion audit](docs/production/PHASE_7_8_COMPLETION_AUDIT_2026-08-02.md)
- [Phase 9–10 completion audit](docs/production/PHASE_9_10_COMPLETION_AUDIT_2026-08-02.md)
- [Phase 11–12 completion audit](docs/production/PHASE_11_12_COMPLETION_AUDIT_2026-08-02.md)
- [Phase 13–14 completion audit](docs/production/PHASE_13_14_COMPLETION_AUDIT_2026-08-02.md)
- [Phase 15–16 completion audit](docs/production/PHASE_15_16_COMPLETION_AUDIT_2026-08-02.md)
- [Windows setup and recovery](docs/release/setup_and_recovery.md)
- [Release notes](docs/release/RELEASE_NOTES.md)
- [Release-candidate evidence](docs/release/release_candidate_evidence.md)

## Licensing

The supplied third-party asset license is stored under `legal/`. The original project's proprietary source-code disposition is explicit in [legal/PROPRIETARY_SOURCE_NOTICE.md](legal/PROPRIETARY_SOURCE_NOTICE.md).
