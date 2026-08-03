# Hybrid vertical-slice implementation log

## Current branch state

- Active local branch: `agent/project-foundation`
- Integration target defined by the plan: `develop`
- Local P1–P10 code is complete; physical checkpoints and target-engine release evidence remain pending.
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
| P1 honest vertical slice | Added persisted Orange/Blue ownership/loadout selection, Mabel's visible daily crop-watering action, four-crop picker, first localized Silas evidence, inspectable schedule feedback, and safe mounted-location persistence with schema-8 migration. |
| P2 demo delivery foundation | Added target-engine GitHub Actions checks, a 250-LOC warning report, title/load/accessibility shell with persistent preferences, canonical setup/recovery guidance, coverage inventory, manual QA matrix, and a proprietary-code disposition. |
| P3 four-Brand mastery | Added data-backed six-Brand definitions, River Rose/Dynamite Bill mastery unlocks for Green/Pink, saved bounded upgrades, charge/loadout state, and expanded Tenderfoot lessons. |
| P4 Frontier Rules | Added the Hall stage-2 Frontier table, Mayor Bell/Dark and cleanup/Purple progression, deterministic 136-tile Frontier walls, 14-tile validation, quad claims/replacement draws, expanded Deeds, saved ruleset/Deed IDs, assistance modes, visible-information AI explanations, and replay hash/explanation evidence. |
| P5 Bridlewood | Added a persisted gated Bridlewood Ranch route, crop order, Ada Rook/Gideon Shaw schedules and tables, ranch actions/shops, damaged barn repair, shortcut, and the next Silas ledger clue. |
| P6 Ranch legacy | Activated all supplied crops with quality feedback, expanded the route-safe farm, added named variant animals with capacity, lineage, breeding, aging, retirement, products, ranch-hand feeding, repairable processing machines, and persisted horse names. Schema 11 migrates all earlier saves safely. |
| P7 Saint's Landing civic restoration | Added the connected Saint's Landing route, records and practice interiors, two scheduled civic opponents, data-backed relationships/dialogue choices, a cheese-backed petition or Mahjong property resolution, government-record clue, civic supply, and Hall stage 3. Schema 12 defaults every prior save to safe empty civic state. |
| P8 Ironhook trade network | Added Ironhook's docks, warehouses/offices, token-gated opponent, atomic posted orders, persistent shop stock, dock property arc, cargo-ledger clue, seven recipe categories, and bounded prepared-food Brand-charge effects. Schema 13 migrates token/order/shop/recipe/effect records from every older save. |
| P9 Gull's Rest angler path | Added Gull's Rest ferry, market/cabin interiors, Captain Coral Fenn, all shore-condition fish data, saved six-category gear upgrades, rare conditions, independent records, tarpon contest, grouper recipe, relationship clue, and a tarpon catch wager. Schema 14 migrates prior saves with starter gear and empty records/contest state. |
| P10 Red Testament mystery | Added the Red Testament route, Ash Varela, deterministic remaining weather and ambience, Windward Pass, bonfire, expedition-property ruins, supernatural record, complete expert schedules, and counterable final-rule clue while keeping King's Reach locked. Schema 15 migrates prior saves with empty desert state. |
| Target-engine CI evidence | GitHub Actions run `30770900107` passed Linux resource import, validator, all 33 suites, smoke, and editor initialization plus Windows Godot-template/export preflight. |

## Current local verification baseline

The following checks passed after the milestones above:

```powershell
python tools/validate_repository.py
<Godot 4.7.1 engine> --headless --path . --script res://tests/test_runner.gd
<Godot 4.7.1 engine> --headless --path . --script res://tests/smoke_test.gd
<Godot 4.7.1 engine> --headless --path . --editor --quit
```

The most recent local implementation run used Godot 4.6.2 and reports 42 suites plus smoke/editor success. Godot 4.7.1 with matching Windows templates remains the required target for release/export evidence. The Windows debug export and isolated-AppData headless launch are verified on the P2 baseline; user-observed clean-profile, manual device/display/accessibility, and P5–P10 physical player-path passes remain external evidence gates. See [setup_and_recovery.md](../release/setup_and_recovery.md).
