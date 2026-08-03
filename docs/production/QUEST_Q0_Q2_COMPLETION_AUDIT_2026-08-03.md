# Quest Objectives Q0–Q2 Completion Audit — 2026-08-03

## Outcome

Q0 discovery/contracts, the Q1 event-aware objective engine, and the Q2 First Lantern pilot are implemented. Save schema remains 21. No third-party source or assets were introduced.

Automated acceptance is green on the required target engine. Physical keyboard-only/controller-only and display-preference walkthroughs remain a human release-evidence checkpoint; this audit does not claim those observations were performed by automation.

## Delivered

- Grounded caller/save/LOC/ownership report and accepted architecture contract.
- Closed version-1 event envelope, structured result codes, strict payload validation, deep copy, dedupe, out-of-order rejection, and same-event cascade prevention.
- Declarative schema-1 `event_once` quest definitions with source/path/message diagnostics and startup validation.
- Backward-compatible `QuestService` facade with legacy manual progression, event-owned advance rejection, read-only projections, signal-suppressed atomic restore, and unchanged schema-21 snapshot shape.
- Session-owned adapter and presenter with deterministic disconnect/rebind on new game and staged restore.
- Candidate-session restore staging that prevents semantically rejected restores from mutating live services.
- Inventory atomic batch preflight/removal, stable receipt, commit, rollback, and adapter receipt authentication.
- First Lantern's three stable objective stages, explicit eligible-fish selection/confirmation, exact batch removal, exactly-once helper/evidence/reward/milestone/autosave ordering, and thin Hall interaction coordination.
- Player-owned, focus-neutral, non-color-dependent quest tracker and modal save/load/session-replacement guard behavior.
- Four schema-21 First Lantern fixtures and six new focused test suites (52 total).

## Acceptance evidence

The following commands passed from the repository root using `C:\Users\Doc\AppData\Local\GodotPortable\4.7.1\Godot_v4.7.1-stable_win64_console.exe`:

```powershell
python tools/validate_repository.py
& $SixBrandsGodot --headless --path . --editor --quit
& $SixBrandsGodot --headless --path . --script res://tests/test_runner.gd
& $SixBrandsGodot --headless --path . --script res://tests/smoke_test.gd
python tools/verify_export_environment.py --godot $SixBrandsGodot
```

Results:

- Repository validation passed. The only size warnings are existing threshold files plus the reviewed 276-line compatibility/state owner `quest_service.gd`; every changed production file remains below the 300-line soft maximum.
- Godot 4.7.1 editor import passed without script/resource errors.
- All 52 native suites passed.
- Runtime smoke passed.
- Windows export preflight passed with the matching 4.7.1 templates.
- `git diff --check` passed.
- A clean `HEAD` archive, imported before test execution, passed the pre-change 46-suite baseline on the same Godot 4.7.1 runtime.

## Acceptance-matrix coverage

Automated tests cover introduction replay, possession without progress, partial and ready live counts, a selected fish disappearing before confirmation, exact chosen-fish removal, untrusted/duplicate receipts, forced post-removal rollback, early lantern rejection, every schema-21 stage, real save/restore boundaries, two consecutive restore cycles, completed restore without effect replay, service replacement, adapter double-bind/old-service disconnect, tracker refresh/focus neutrality, modal selection requirement, load restriction, and new-game modal teardown.

Manual release checkpoint still required:

- play the fresh-save First Lantern path using only keyboard;
- repeat using only a physical controller;
- switch active device while the tracker/delivery UI is visible;
- inspect at two UI/text scales, high contrast on/off, and reduced motion on;
- verify the selected-fish confirmation and completion feedback visually in the shipped Windows build.

## Rollback boundary

Schema 21 is unchanged. During development, the First Lantern objective fields/UI coordinator can be data-gated back to the legacy path. Once the stable objective IDs ship, production rollback uses the phase-start build and save backup; IDs are not silently renamed or reinterpreted.
