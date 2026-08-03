# Phase 7–8 completion audit

## Scope and evidence

This audit records the code-complete P7/P8 slice. It does not claim the manual player checkpoints or the older P2 device/display gates are complete.

| Planned outcome | Local implementation and automated evidence |
| --- | --- |
| Saint's Landing, opponents 6–7, schedules, interiors, civic shop, government clue | `src/world/saints_landing.tscn`, records/practice interiors, `registrar_elise` and `constable_mara` data/schedules, civic catalog, `test_phase_seven_eight.gd`, smoke resource audit |
| Canonical relationship, dialogue, property, and Hall stage 3 state | `relationship_service.gd`, `property_service.gd`, `civic_landmark.gd`, `brand_loadout_state.gd`; a named dialogue choice and both legal case paths are persisted and tested |
| Ironhook, opponent 8, warehouses/offices, cargo clue | `src/world/ironhook.tscn`, warehouse/office scenes, `mariner_ves`, `trade_landmark.gd`, Ironhook data catalogs |
| Territory economy and no inert production categories | `trade_service.gd`, `crafting_service.gd`, `food_effect_service.gd`; all cooking/preserves/flour/dairy/smoked-fish/feed/tonic recipes have visible buttons, consumable outputs, and a bounded next-match Brand-charge consumer |
| Token-gated Mahjong and dock property arc | completed Smokehouse Supply Run awards a persisted table token, unlocks the customs claim, and lets the player open Mariner Ves's table; covered by P8 service tests |
| Save compatibility | `session_snapshot_migrator.gd` moves schema 11 through P7 civic defaults and schema 12 through P8 economy defaults into schema 13; the focused suite verifies pre-P7 migration and full round trips |

## Automated gates run

```powershell
python tools/validate_repository.py
& $SixBrandsGodot --headless --path . --script res://tests/test_runner.gd
& $SixBrandsGodot --headless --path . --script res://tests/smoke_test.gd
& $SixBrandsGodot --headless --path . --editor --quit
```

All gates passed with Godot `4.7.1.stable.official.a13da4feb`: repository validation, 41 native suites, runtime smoke, and headless editor initialization.

## Manual evidence still required

- Resolve one Landing Depot dispute through each intended player path across separate saves, travel to Ironhook, and reload after the Hall/route change.
- Source goods from prior regions, deliver the Smokehouse order, use the token at Mariner Ves's table, and verify two save/load cycles.
- Perform the existing keyboard-only, controller-only, display, accessibility, and clean-profile matrix before claiming a release gate.
