# Phase 9–10 completion audit

## Scope and evidence

This audit records the code-complete P9/P10 slice as it was delivered. It does not claim the physical player checkpoints or the existing P2 manual device/display matrix; P11–P12 are documented separately in the later community completion audit.

| Planned outcome | Local implementation and automated evidence |
| --- | --- |
| Gull's Rest, opponent 9, market/cabin, and all shore conditions | `gulls_rest.tscn`, `gulls_market.tscn`, `gulls_cabin.tscn`, Captain Coral Fenn, and a 14-fish catalog cover creek, river, harbor, coast, and reef conditions. |
| Full fishing profession | `fishing_progress_service.gd` persists six gear categories, equipped loadout, rare conditions, independent records, and contest results; its catch path retains normal inventory fish records. Six interaction points sell and equip the advanced rod/bait/lure/hook/line/bobber. |
| Contest, recipes, relationship clue, and wager | The tarpon contest consumes a catch, calculates a saved score, can be entered repeatedly, and gives an explicit prize. The coastal grouper recipe is a normal bounded food recipe. Coral's letter records both relationship and evidence state. `angler_catch` is a named tarpon Mahjong term with loss/removal and win/reward behavior. |
| P9 accessibility and audio | Bite and tension retain the visible text, meter, remappable controls, and controller haptics from the fishing overlay; catalog audio is additive. No fishing-critical state is communicated only by audio or vibration. |
| Red Testament, opponent 10, routes, ruins, and locked King's Reach | `red_testament.tscn` supplies the desert route, bonfire, Ash Varela's expert table, saved expedition right, and a property-gated ruin interior. The King's Reach approach has no destination and states its Act III lock. |
| Remaining weather, supernatural records, secrets, and final-rule clue | Cloudy, thunderstorm, dust wind, and supernatural fog are active deterministic weather states with available ambience. Windward Pass accepts only dust wind/fog, supernatural records and the Red Testament sun-dial/buried-seal secrets persist, every active weather has Coral/Ash schedule data, and the rule clue has a visible counter explanation. |
| Save compatibility | Schema 14 adds safe empty P9 fish/gear/record/contest state; schema 15 adds safe empty P10 route/record/clue state. `test_phase_nine_ten.gd` exercises pre-P9/pre-P10 migrations, full record/contest round-trip, and desert/property/clue round-trip. |

## Automated gates run

```powershell
python tools/validate_repository.py
& godot_console.exe --headless --path . --script res://tests/test_runner.gd
& godot_console.exe --headless --path . --script res://tests/smoke_test.gd
& godot_console.exe --headless --path . --editor --quit
```

The local run passed repository validation, 42 native suites, runtime smoke, and headless editor initialization. The available local executable identified itself as Godot 4.6.2; the configured release target remains Godot 4.7.1 and must be used for the planned release/export evidence.

## Manual evidence still required

- From Ironhook, enter Gull's Rest, chart high tide, buy/equip a gear upgrade, catch a rare fish, enter the contest, and sell/cook/wager catches across save/load cycles.
- Reach Red Testament, rest until dust wind or supernatural fog, survive Windward Pass, defeat Ash Varela, open the expedition ruins, recover the clue, and confirm the King's Reach approach remains locked.
- Perform the existing keyboard-only, controller-only, display, accessibility, backup-recovery, and clean-profile matrix before claiming a release gate.
