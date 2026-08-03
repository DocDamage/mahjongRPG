# Test-to-module coverage inventory

The native Godot runner is the authoritative automated suite registry: `tests/test_runner.gd`. This inventory maps every runtime responsibility added through P10 to a focused test or smoke gate; it is a traceability map, not a numeric line-coverage claim.

| Module / player contract | Automated evidence |
| --- | --- |
| Session clock, pause, migration, player location | `tests/unit/test_game_session.gd` |
| Save checksum, backup recovery, slots, full snapshot persistence | `tests/unit/test_save_service.gd` |
| P1 Brand loadout, Mabel action, evidence, mounted location, schedules | `tests/unit/test_phase_one_services.gd` |
| Crop catalog, lifecycle, planting, route-safe placement | `tests/unit/test_crop_catalog.gd`, `tests/unit/test_farm_service.gd` |
| Trail Rules, claims, wagering, wall/replay, AI | `tests/unit/test_trail_hand_validator.gd`, `test_brand_claims.gd`, `test_match_flow.gd`, `test_match_wager.gd`, `test_wall_builder.gd`, `test_basic_trail_ai.gd` |
| P3 mastery, Green/Pink powers, bounded upgrades, four-Brand loadouts | `tests/unit/test_brand_mastery.gd`, `tests/unit/test_six_brand_powers.gd` |
| P4 Frontier rules, 136-tile wall, 14-tile hands, quads, Dark/Purple, Deeds, replay hash/explanations | `tests/unit/test_frontier_rules.gd`, `test_six_brand_powers.gd`, `test_match_replay_explainer.gd` |
| Advanced AI visible-information boundary and explanation | `tests/unit/test_frontier_ai.gd` |
| P3/P4 schema migration | `tests/unit/test_phase_three_four_migration.gd` |
| P5 Bridlewood region, crop order, stable region migration, fifth opponent tier | `tests/unit/test_phase_five_six.gd`, `tests/smoke_test.gd` |
| P6 all-crop activation, dense route safety, named animal lineage/capacity/aging/retirement, repairable processing | `tests/unit/test_phase_five_six.gd`, `test_crop_catalog.gd`, `test_farm_service.gd`, `test_animal_care_service.gd` |
| P7 civic relationships, dialogue choices, property outcomes, route unlock, Hall stage 3, and pre-P7 migration | `tests/unit/test_phase_seven_eight.gd`, `tests/smoke_test.gd` |
| P8 posted orders, duplicate-delivery rejection, full-inventory safety, table tokens, recipes, bounded food effects, dock property arc, and schema-13 round trip | `tests/unit/test_phase_seven_eight.gd`, `tests/smoke_test.gd` |
| P9 fish roster/shore conditions, six-category gear progression, rare conditions, records, contest, recipe, and catch wager | `tests/unit/test_phase_nine_ten.gd`, `test_fishing_session.gd`, `test_fishing_gear_catalog.gd`, `test_match_wager.gd`, `tests/smoke_test.gd` |
| P10 active weather, expert schedules, weather route, supernatural record, secret, property access, clue, and schema-15 migration | `tests/unit/test_phase_nine_ten.gd`, `test_weather_catalog.gd`, `test_audio_service.gd`, `tests/smoke_test.gd` |
| Horse identity and mounted-location continuity | `tests/unit/test_horse_travel_state.gd`, `test_phase_one_services.gd` |
| Input remapping, controller focus, display preferences | `tests/unit/test_input_service.gd`, `test_input_settings.gd`, `test_display_preferences.gd` |
| Project resources and scene references | `tests/unit/test_project_resources.gd`, `tests/smoke_test.gd` |
| Connected First Lantern progression/save continuation | `tests/integration/test_vertical_slice_progression.gd` |
| Whole project bootstrap/editor load | `tests/smoke_test.gd`; target-engine CI editor initialization |

All new behaviors need a row here and a matching runner registration before a phase can be marked complete.
