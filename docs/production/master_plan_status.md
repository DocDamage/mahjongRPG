# Master-plan implementation status

This is an evidence ledger for `CODEX_MASTER_EXECUTION_PLAN.md`. It is not a completion claim: **complete** means the current checkout has direct local evidence, **partial** means a vertical-slice foundation exists but one or more explicit requirements remain, and **external gate** requires a toolchain, integration, or user-authorized network action.

## Phase status

| Plan phase | Status | Current evidence / remaining work |
| --- | --- | --- |
| P1: honest vertical slice | Code complete / manual checkpoint pending | Save schema 8 adds starter Orange/Blue Brand ownership and persisted pre-match loadout state, Mabel's assigned once-per-day crop-watering action, first Silas evidence, four-crop picker, inspectable unavailable-opponent schedules, and mounted horse scene/position persistence. Focused migration/orchestration tests, progression, save, smoke, and editor checks pass with Godot 4.7.1; the physical player checkpoint is part of the pending manual matrix. |
| P2: demo-grade delivery foundation | Partial / external evidence gate | Target-engine [GitHub Actions run 30770900107](https://github.com/DocDamage/mahjongRPG/actions/runs/30770900107) is green for validator, resource import, 33 suites, smoke, editor, and Windows template/export preflight. The 250-LOC report, canonical setup/recovery, manual matrix, coverage inventory, title/load/accessibility shell, persistent preferences, controller-glyph base, and proprietary code notice are present. Complete supplied source archives, physical controller/display matrix, and user-observed clean-profile pass remain evidence gates. |
| A–C: orientation and source import | Complete for the expanded canonical asset folder | `docs/assets/master_import.md` establishes `assets/MahjongRPG/` as the local source. The user explicitly retained archives outside the repo; no archive is committed. |
| D: Godot 4.7.1 smoke | Complete | Official Godot `4.7.1.stable.official.a13da4feb` and matching Windows templates passed preflight, the 31-suite native runner, runtime smoke, and headless editor initialization. |
| E: foundation integration | External gate | Work is on `agent/project-foundation`; no merge into `develop`, push, or PR is claimed. |
| F: architecture and headless tests | Complete for the slice | Versioned `GameSession`, focused services, data tables, native runner, 300 LOC validator, and recursive runtime-resource audit are present. |
| G: runtime assets | Partial | Hero actions, five horses, audio categories, and deterministic 34-face Mahjong atlas are cataloged. The compact presentation adds Brand patterns, but it does not yet generate every orientation/state atlas named in the full plan. |
| H: player and controls | Partial | Movement, run, interaction prompts, device-aware bindings, remapping, display modes, footsteps, story animations, and tested keyboard/controller tab focus exist. The vertical slice uses fixed-screen scenes rather than a scrolling player camera; no moving camera is claimed. |
| I: time, weather, saves | Partial | Session-owned time, catalog-driven clear/rain with deferred cloudy/thunderstorm/dust-wind/fog definitions, autosave, manual slots, backup recovery, checksum, and transient save restrictions exist. The pre-finale slot/API exists, but no finale content currently triggers it. |
| J–K: Trail Rules, Brands, AI, tutorial | Complete for the slice | Domain tests cover hand validation, wall/replay determinism, claims, wagers, Orange/Blue/High Noon, AI, and Tenderfoot lessons. |
| L: farm loop and placement | Partial | Crop lifecycle, save persistence, animal care, route/terrain validation, guarded-route pathfinding, data-driven paths/fences/decorations/machines/pens/buildings, and relocation exist. Dynamic navigation-server updates and broad constructed-building coverage remain beyond the small slice grid. |
| M: fishing | Complete for the slice | All required session states, deterministic conditions, keyboard/controller controls, overlay, catch records/economy, non-color tension feedback, controller haptics, and a default rod/bait/lure/hook/line catalog with applied modifiers are present. |
| N: horse travel | Complete for the slice | All five colorways are cataloged; selected horse state, safe dismount, discovered hitch posts, and fast travel are save-backed and tested. |
| O: world and narrative | Complete for the slice | Wayward Farm, Dustward, Riverbend, general store, inn, hall, three opponents, First Lantern, helper unlock, access dispute, shipping, store, sleep, bonfire, and horse route are playable scenes. |
| P: QA, export, PR | Partial / external gate | Validation, 31 suites, smoke, editor, export preflight, Windows debug packaging, and an isolated-AppData headless launch passed locally. Controller-only/manual display passes, a user-observed clean-Windows-profile pass, push, and draft PR remain unverified or require authorization. |

## Current local validation evidence

```powershell
python tools/validate_repository.py
<Godot 4.7.1 engine> --headless --path . --script res://tests/test_runner.gd
<Godot 4.7.1 engine> --headless --path . --script res://tests/smoke_test.gd
<Godot 4.7.1 engine> --headless --path . --editor --quit
```

The current native run reports 33 suites. The complete commands and latest milestones are maintained in `implementation_log.md`.

## Required delivery actions

1. Restore and verify the complete user-supplied supplemental and master archive sets against their manifests, then pin the master fingerprints.
2. Perform the P2 manual controller, display, accessibility, backup recovery, and clean-Windows-profile matrix in `docs/qa/manual_device_display_matrix.md`.
3. Execute and record the manual matrix against the debug export; target-engine CI is already green on the pushed branch.

Until those gates have evidence, the plan is not complete.
