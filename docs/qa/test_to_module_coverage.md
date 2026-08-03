# Test-to-module coverage inventory

The native Godot runner is the authoritative automated suite registry: `tests/test_runner.gd`. This inventory maps every runtime responsibility added through P16 and quest-objective phases Q0-Q4 to a focused test or smoke gate; it is a traceability map, not a numeric line-coverage claim.

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
| P11/P12 ten multi-stage relationship arcs, choices, active/completed/mixed migration, helpers/passives, ten homes, procedural portrait cards, eight gated secrets, post-resolution schedules, and finale-support state | `tests/unit/test_phase_eleven_twelve.gd`, `test_project_resources.gd`, `tests/smoke_test.gd` |
| P13 public property contributions, rank, reschedulable Market Day, real-match-gated Town Tournament, Hall stages 4–5, reopening, final-championship scheduling, and schema-18 continuity | `tests/unit/test_phase_thirteen_fourteen.gd`, `test_project_resources.gd`, `tests/smoke_test.gd` |
| P14 inheritance-to-bargain clue chain, one saved consequence, altered-rule explanations, Silas proof, King's Reach exploration, explicit readiness warning, and schema-19 continuity | `tests/unit/test_phase_thirteen_fourteen.gd`, `test_project_resources.gd`, `tests/smoke_test.gd` |
| P15 Texas King gate/checkpoint, legal final result, local standoff retry, father/Silas reveal, all four transparent endings, credits, and schema-20 continuity | `tests/unit/test_phase_fifteen_sixteen.gd`, `test_project_resources.gd`, `tests/smoke_test.gd` |
| P16 all-ending postgame transitions/provenance, repeatable Hall Legends tournament, collections ledger, King's Reach/farm/animal/fishing continuity, audio feedback, and schema-21 continuity | `tests/unit/test_phase_fifteen_sixteen.gd`, `test_project_resources.gd`, `tests/smoke_test.gd` |
| Horse identity and mounted-location continuity | `tests/unit/test_horse_travel_state.gd`, `test_phase_one_services.gd` |
| Input remapping, controller focus, display preferences | `tests/unit/test_input_service.gd`, `test_input_settings.gd`, `test_display_preferences.gd` |
| Project resources and scene references | `tests/unit/test_project_resources.gd`, `tests/smoke_test.gd` |
| Connected First Lantern progression/save continuation | `tests/integration/test_vertical_slice_progression.gd` |
| Q1 quest definition/state validation and stable schema-21 mapping | `tests/unit/test_quest_definition_validator.gd`, `tests/unit/test_quest_service.gd`, `tests/integration/test_first_lantern_objectives.gd` |
| Q1 closed quest-event envelope, normalization, receipt authentication, adapter lifecycle, dedupe, ordering, and same-event cascade prevention | `tests/unit/test_quest_event.gd`, `tests/unit/test_quest_event_adapter.gd`, `tests/unit/test_quest_objective_evaluator.gd`, `tests/unit/test_quest_service.gd` |
| Q2 First Lantern explicit delivery, transactional rollback, completion effects, legacy fixtures, restore/replacement, and exactly-once behavior | `tests/integration/test_first_lantern_objectives.gd`, `tests/integration/test_vertical_slice_progression.gd`, `tests/unit/test_inventory_service.gd`, `tests/unit/test_quest_service.gd` |
| Q2 read-only quest projection, tracker/journal presentation, focus neutrality, selection modal, and accessibility preferences | `tests/unit/test_quest_ui.gd`, `tests/integration/test_first_lantern_objectives.gd` |
| Q3 linear dialogue schema, graph/reference validation, and forbidden side-effect fields | `tests/unit/test_dialogue_sequence_validator.gd`, `tests/unit/test_content_validation_report.gd` |
| Q3 sequence presentation, typewriter speed, reduced motion, contrast/scaling, focus, keyboard/controller input, cancel, rapid confirm, and persistence restriction teardown | `tests/unit/test_dialogue_sequence_runner.gd` |
| Q3 Mayor Bell fresh/legacy-stage flow, exact relationship changes, helper/schedule outcome, completion reopen, service replacement, and exactly-once domain commit | `tests/integration/test_mayor_bell_dialogue_pilot.gd`, `tests/fixtures/community/*.json` |
| Q4 shared production content report: invalid definitions, duplicates, missing references/keys, unsupported schemas, unreachable nodes, save-schema requirements, and source diagnostics | `tests/unit/test_content_validation_report.gd`; `tools/run_content_validation.ps1` |
| Q4 repository JSON/naming/size checks, advisory pre-commit exclusions, and CI wiring | `tools/validate_repository.py`; `tools/precommit_project_checks.py --all`; `pre-commit validate-config`; `pre-commit run --all-files`; `.github/workflows/godot-validation.yml` |
| Q4 contributor-tool exclusion and production-validator inclusion in Windows release data | `tools/verify_export_environment.py`; post-export PCK contract audit documented in `docs/production/QUEST_Q3_Q4_COMPLETION_AUDIT_2026-08-03.md` |
| Whole project bootstrap/editor load | `tests/smoke_test.gd`; target-engine CI editor initialization |

All new behaviors need a row here and a matching runner registration before a phase can be marked complete.
