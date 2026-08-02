# Hybrid vertical-slice implementation log

## Current branch state

- Active local branch: `agent/project-foundation`
- Integration target defined by the plan: `develop`
- Local foundation work remains unpushed and is ahead of `origin/agent/project-foundation`.
- This log records verified local milestones; it does not claim that the full execution plan is complete.

## Verified milestones

| Commit | Milestone |
| --- | --- |
| `ae196a0` | Player scene and position persist through versioned saves. |
| `0e3b93a` | Cross-scene autosave plus six-slot manual save/load pause menu. |
| `598dc92` | Twelve-step, save-persistent Tenderfoot Mahjong lessons. |
| `e7a9376` | Friendly, serious, and high-stakes cash wagers for Trail Rules matches. |
| `c4b7c05` | Safe, save-persistent farm-field placement on Wayward Farm. |
| `e703035` | Runtime smoke test for autoloads, inputs, content tables, scenes, and generated assets. |
| `b62fc4e` | Independent Master, Music, Ambience, SFX, Mahjong, and UI volume controls. |
| Animal care foundation | Feed Juniper's hens once per day, collect next-day eggs, track happiness, and sell eggs through existing shipping and store flows. |
| Autosave recovery | Autosave safely after travel, rest, quest completion, and finished Mahjong matches using the existing checksum and backup flow. |
| Runtime hero and horse catalog | Deterministically generate all directional hero actions and five horse colorways from the canonical `assets` folders, then resolve them through a runtime data catalog. |
| First Lantern story arc | Persisted three-stage Mabel storyline with data-driven dialogue, a distinct hand-in and lighting return step, helper unlock, Riverbend access, and a visible Hall lantern. |
| NPC schedules | Data-driven clear and rain schedules relocate all three Dustward opponents and preserve their authored challenge windows. |
| Mahjong tile atlas | Deterministically rasterized the canonical 34 face set into one compact runtime atlas, with testable identity regions and presentation-layer Brand tinting. |
| Crop catalog | Cataloged all 20 canonical ranch crops while enforcing the four balanced active slice crops at the farm-service boundary. |
| Accessible controls | Added a pause-menu controls screen with keyboard, controller button, stick, and trigger remapping, duplicate-binding protection, reset controls, controller-first focus, and remap-aware keyboard/controller prompt labels. |
| Farm construction | Added data-driven paths, fences, decorations, machines, pens, and buildings with protected-route checks, footprint validation, safe relocation/removal, persistent snapshots, and an in-game build palette. |
| Display settings | Added persisted windowed, borderless, and fullscreen preferences through the pause menu, with safe headless-runtime handling. |
| Mahjong patterns | Added six distinct, data-driven non-color Brand patterns to tile controls and tooltips for color-independent Brand identification. |
| Fishing controller feedback | Added active-controller bite and escalating tension haptics, while making all fishing instructions reflect remapped live bindings. |
| Off-farm crop progression | Centralized crop day advancement in `GameSession` so crops process correctly during travel, inn rests, and any other off-farm time change. |
| Save safety | Added nested, reason-based save restrictions for active fishing and Mahjong, preserving post-match autosaves and the dedicated pre-finale slot. |
| Export preflight | Added a deterministic Windows export preflight that verifies the required Godot 4.7.1 runtime, Windows templates, and archive-safe export preset before packaging. |
| Resource audit | Deferred the native runner until autoloads exist and added a recursive `src` script/scene load suite, so broken resources now fail the automated gate. |
| Fishing gear data | Added a validated default rod, bait, lure, hook, and line catalog, then applied its deterministic reel, bite-window, and line-tension modifiers to Riverbend fishing. |
| Placement route safety | Added guarded-route breadth-first validation to construction placement, preventing a non-walkable build from sealing the farm's traversable route while allowing walkable paths. |
| Controller focus regression | Added a viewport-attached controls-screen test that verifies initial binding focus and focus retention when the controller tab becomes active. |
| Weather catalog | Moved deterministic clear/rain selection into validated weather data while defining cloudy, thunderstorm, dust wind, and supernatural fog for later activation. |
| Godot 4.7.1 Windows export | Validated the official 4.7.1 runtime and matching templates, passed repository validation plus 31 native suites/smoke/editor checks, packaged the ignored Windows debug build, and headlessly launched it with an isolated AppData environment. |

## Current local verification baseline

The following checks passed after the milestones above:

```powershell
python tools/validate_repository.py
<Godot 4.7.1 engine> --headless --path . --script res://tests/test_runner.gd
<Godot 4.7.1 engine> --headless --path . --script res://tests/smoke_test.gd
<Godot 4.7.1 engine> --headless --path . --editor --quit
```

The portable validation engine is official Godot 4.7.1 with matching Windows templates. The Windows debug export and isolated-AppData headless launch are verified; the plan's user-observed clean-profile and manual device/display passes remain outstanding. See [export_validation.md](export_validation.md).
