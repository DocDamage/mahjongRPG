# Test-to-module coverage inventory

The native Godot runner is the authoritative automated suite registry: `tests/test_runner.gd`. This inventory maps every runtime responsibility added through P2 to a focused test or smoke gate; it is a traceability map, not a numeric line-coverage claim.

| Module / player contract | Automated evidence |
| --- | --- |
| Session clock, pause, migration, player location | `tests/unit/test_game_session.gd` |
| Save checksum, backup recovery, slots, full snapshot persistence | `tests/unit/test_save_service.gd` |
| P1 Brand loadout, Mabel action, evidence, mounted location, schedules | `tests/unit/test_phase_one_services.gd` |
| Crop catalog, lifecycle, planting, route-safe placement | `tests/unit/test_crop_catalog.gd`, `tests/unit/test_farm_service.gd` |
| Trail Rules, claims, wagering, wall/replay, AI | `tests/unit/test_trail_hand_validator.gd`, `test_brand_claims.gd`, `test_match_flow.gd`, `test_match_wager.gd`, `test_wall_builder.gd`, `test_basic_trail_ai.gd` |
| Input remapping, controller focus, display preferences | `tests/unit/test_input_service.gd`, `test_input_settings.gd`, `test_display_preferences.gd` |
| Project resources and scene references | `tests/unit/test_project_resources.gd`, `tests/smoke_test.gd` |
| Connected First Lantern progression/save continuation | `tests/integration/test_vertical_slice_progression.gd` |
| Whole project bootstrap/editor load | `tests/smoke_test.gd`; target-engine CI editor initialization |

All new behaviors need a row here and a matching runner registration before a phase can be marked complete.
