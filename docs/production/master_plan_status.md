# Master-plan implementation status

This is an evidence ledger for `CODEX_MASTER_EXECUTION_PLAN.md`. It is not a completion claim: **complete** means the current checkout has direct local evidence, **partial** means a vertical-slice foundation exists but one or more explicit requirements remain, and **external gate** requires a toolchain, integration, or user-authorized network action.

## Phase status

| Plan phase | Status | Current evidence / remaining work |
| --- | --- | --- |
| A–C: orientation and source import | Complete for the expanded canonical asset folder | `docs/assets/master_import.md` establishes `assets/MahjongRPG/` as the local source. The user explicitly retained archives outside the repo; no archive is committed. |
| D: Godot 4.7.1 smoke | External gate | `tools/verify_export_environment.py` reports installed Godot 4.6.2 and missing 4.7.1 Windows templates. |
| E: foundation integration | External gate | Work is on `agent/project-foundation`; no merge into `develop`, push, or PR is claimed. |
| F: architecture and headless tests | Complete for the slice | Versioned `GameSession`, focused services, data tables, native runner, 300 LOC validator, and recursive runtime-resource audit are present. |
| G: runtime assets | Partial | Hero actions, five horses, audio categories, and deterministic 34-face Mahjong atlas are cataloged. The compact presentation adds Brand patterns, but it does not yet generate every orientation/state atlas named in the full plan. |
| H: player and controls | Partial | Movement, run, interaction prompts, device-aware bindings, remapping, display modes, footsteps, story animations, and tested keyboard/controller tab focus exist. The vertical slice uses fixed-screen scenes rather than a scrolling player camera; no moving camera is claimed. |
| I: time, weather, saves | Partial | Session-owned time, clear/rain, autosave, manual slots, backup recovery, checksum, and transient save restrictions exist. The pre-finale slot/API exists, but no finale content currently triggers it. |
| J–K: Trail Rules, Brands, AI, tutorial | Complete for the slice | Domain tests cover hand validation, wall/replay determinism, claims, wagers, Orange/Blue/High Noon, AI, and Tenderfoot lessons. |
| L: farm loop and placement | Partial | Crop lifecycle, save persistence, animal care, route/terrain validation, guarded-route pathfinding, data-driven paths/fences/decorations/machines/pens/buildings, and relocation exist. Dynamic navigation-server updates and broad constructed-building coverage remain beyond the small slice grid. |
| M: fishing | Complete for the slice | All required session states, deterministic conditions, keyboard/controller controls, overlay, catch records/economy, non-color tension feedback, controller haptics, and a default rod/bait/lure/hook/line catalog with applied modifiers are present. |
| N: horse travel | Complete for the slice | All five colorways are cataloged; selected horse state, safe dismount, discovered hitch posts, and fast travel are save-backed and tested. |
| O: world and narrative | Complete for the slice | Wayward Farm, Dustward, Riverbend, general store, inn, hall, three opponents, First Lantern, helper unlock, access dispute, shipping, store, sleep, bonfire, and horse route are playable scenes. |
| P: QA, export, PR | Partial / external gate | Validation, 28 suites, smoke, editor, scene loads, and export preflight run locally. Controller-only/manual display passes, a clean-profile Windows development export, push, and draft PR remain unverified or require authorization. |

## Current local validation evidence

```powershell
python tools/validate_repository.py
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --editor --quit
```

The current native run reports 28 suites. The complete commands and latest milestones are maintained in `implementation_log.md`.

## Required delivery actions

1. Install or provide the exact Godot 4.7.1 runtime and matching Windows export templates.
2. Run `python tools/verify_export_environment.py`, then create and launch the Windows development export on a clean user profile.
3. Perform the plan's manual controller, display, crop, fishing, horse, schedule, Hall, and audio passes.
4. With user authorization, push the focused branch and open the required draft PR into `develop`.

Until those gates have evidence, the plan is not complete.
