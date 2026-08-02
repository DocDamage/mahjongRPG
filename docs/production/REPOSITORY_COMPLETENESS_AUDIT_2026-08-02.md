# Repository Completeness Audit

**Audit date:** 2026-08-02
**Checkout:** `agent/project-foundation` at `102a593`
**Scope:** Local repository contents, ignored local asset inputs/build outputs, source and scene wiring, tests, CI, documentation, and release evidence. No external service or live GitHub state was used.

> **Production audit: 64/100 for the stated hybrid vertical-slice target (risky). The full launch game is blocked: full-game milestones 11–19 remain incomplete, and several explicit vertical-slice exit gates are only partially implemented or unverified.**

The score applies to the hybrid vertical slice described in `docs/CODEX_MASTER_EXECUTION_PLAN.md`, not to the complete game described in `docs/SIX_BRANDS_AT_HIGH_NOON_COMPLETE_GAME_PLAN.md`. It is a prioritization aid, not a coverage percentage.

## Verdict

| Target | Status | Finding |
| --- | --- | --- |
| Repository integrity | Passing | The repository validator passes; tracked runtime assets and resource paths load. |
| Hybrid vertical slice | Incomplete / risky | The connected slice is playable and well tested at the domain level, but Brand selection, helper behavior, mounted save position, source reproducibility, and required manual acceptance evidence are incomplete. |
| Full launch game | Blocked | The checkout implements a narrow slice, not the seven-region, eleven-opponent, full-story game with all systems, endings, and postgame. |
| Windows development build | Automated evidence passes | Target-engine preflight and existing debug-build evidence pass; clean-profile, controller, display, and other manual gates remain open. |
| Release candidate | Not ready | CI does not run the Godot suite, only a debug export is evidenced, and the complete-game release checklist is largely unfulfilled. |

## Blockers before claiming the full game is complete

### COMP-01 — Most full-game content milestones are not complete

**Severity: Blocker**

The complete-game plan defines milestones 11–19 for full Mahjong, farming and animals, fishing and economy, seven regions, ten non-final opponent arcs, all five Hall stages, the main story/finale, four endings/postgame, final presentation, and a release candidate (`docs/SIX_BRANDS_AT_HIGH_NOON_COMPLETE_GAME_PLAN.md:1853-1997`). The current connected runtime instead consists of Wayward Farm, Dustward, three small Dustward interiors, and a quest-gated Riverbend fishing annex. The committed data contains three opponents, one quest, one animal group, four active crops, six fish, and two active weather states.

The full-game completion definition requires relationships with eleven opponents, all six Brands, Frontier Rules, five Hall stages, Silas's rescue, Texas King's match, the gun standoff, four endings, and stable postgame (`docs/SIX_BRANDS_AT_HIGH_NOON_COMPLETE_GAME_PLAN.md:2089-2110`). No player-facing path to those later chapters, finale, endings, credits, or postgame exists in the current runtime.

**Conclusion:** the repository is a vertical-slice foundation, not a complete game or launch candidate.

### COMP-02 — The player Brand loadout is hardcoded

**Severity: High**

The slice plan requires the player to select two unlocked Brands before a match (`docs/CODEX_MASTER_EXECUTION_PLAN.md:841-849`), while the status ledger calls phases J–K complete for the slice (`docs/production/master_plan_status.md:16`). Actual match setup always equips Orange and Blue:

- `src/mahjong/presentation/mahjong_table.gd:245-252` calls `configure_loadouts([&"orange", &"blue"], opponent_loadout)`.
- No `data/brands/` catalog or player unlock/selection flow exists.
- `src/mahjong/domain/brand_power_resolver.gd:4-44` implements only Orange and Blue powers; the other four Brands are identities/presentation data for now.

This is an explicit slice requirement, not merely deferred full-game content. Phase K should remain partial until loadout selection and unlock state are real player-facing systems.

### COMP-03 — The advertised helper unlock has no gameplay behavior

**Severity: High**

Completing First Lantern records `unlocked_helpers["mabel"] = true` (`src/quests/quest_service.gd:64-78`) and dialogue tells the player that Mabel is unlocked (`data/dialogue/vertical_slice_dialogue.json:9-10`). Repository-wide usage of `unlocked_helpers` is limited to reward bookkeeping and save/restore (`src/quests/quest_service.gd:95-116`); no helper action, assignment UI, passive effect, or world behavior consumes the flag.

The slice definition of done explicitly requires one complete helper unlock (`docs/CODEX_MASTER_EXECUTION_PLAN.md:1224`). The present behavior is a persisted narrative flag rather than a functioning helper system.

### COMP-04 — Foundation integration and acceptance gates are still open

**Severity: High**

The slice definition of done requires integration into `develop`, a focused slice branch/PR, working keyboard and controller paths, and a cleanly launching Windows development build (`docs/CODEX_MASTER_EXECUTION_PLAN.md:1214-1229`). At audit time:

- `HEAD` is synchronized with `origin/agent/project-foundation`, but is not contained in `origin/develop` and is 90 commits ahead of it.
- `docs/production/master_plan_status.md:21,34-39` explicitly leaves controller-only, display-mode, clean-Windows-profile, push/PR, and other manual passes open. Some push/PR wording is stale, but integration and manual acceptance remain unproven locally.
- `docs/production/export_validation.md:19` states that the automated isolated-AppData launch is not a substitute for clean-profile, controller, and display passes.

The current build can support an internal demo, but the repository's own completion gate has not closed.

## Functional and data-integrity findings

### DATA-01 — Mounted position is not preserved in saves

**Severity: High**

`HorseActor` moves the horse node while mounted but does not record its position (`src/horses/horse_actor.gd:29-41`). `HorseTravelState.snapshot()` stores color, mounted state, and discovered posts, but no coordinate (`src/horses/horse_travel_state.gd:39-54`). `GameSession.snapshot()` persists that horse state and the last separately recorded player position (`src/core/game_session.gd:134-145`). On restore, the rider is snapped to the scene's authored horse-node position (`src/horses/horse_actor.gd:69-77`).

A save made while mounted can therefore restore the rider/horse at a different position from the save point. There is no focused regression test for this path.

### GAME-01 — New farm plots always plant beans

**Severity: Medium**

Four crops are marked active in `data/crops/vertical_slice_crops.json:4-8`, but `FarmPlot.starter_crop` defaults to beans and empty-plot interaction plants that value directly (`src/farm/farm_plot.gd:5-7,33-49`). Dynamically created plots set only `grid_cell` (`src/world/wayward_farm.gd:96-107`). There is no seed inventory or crop-selection step, so the advertised four-crop slice is data-complete but not fully player-selectable through the normal new-field flow.

### GAME-02 — Off-schedule opponent feedback is unreachable

**Severity: Medium**

`MahjongOpponent._on_interacted()` includes a useful "check back" message for unavailable opponents (`src/mahjong/presentation/mahjong_opponent.gd:30-38`), but `_update_availability()` also makes an unavailable opponent invisible and disables monitoring (`src/mahjong/presentation/mahjong_opponent.gd:57-68`). The player cannot interact with the missing node to receive that message. Meanwhile, Dustward always says that three opponents await (`src/world/dustward.gd:36-38`).

This does not break schedule gating, but it makes the schedule state opaque and the HUD misleading.

### GAME-03 — Riverbend is connected but very thin

**Severity: Low**

The scene is reachable after First Lantern, but contains only a return exit and one fishing spot (`src/world/riverbend.tscn:18-38`). This satisfies the narrow "first fishing location" requirement, but should not be interpreted as broader region completion.

## Test, CI, and release findings

### QA-01 — Local Godot checks pass, but CI does not run them

**Severity: High**

The only workflow, `.github/workflows/repository-guard.yml`, runs `python tools/validate_repository.py` and nothing else (`.github/workflows/repository-guard.yml:13-26`). It does not install the target Godot version or run:

- the 31-suite native runner;
- the runtime smoke test;
- headless editor/resource initialization;
- Windows export preflight;
- packaging or launch checks.

This means pull requests can be green while GDScript parsing, scene loading, runtime wiring, or export compatibility is broken.

### QA-02 — Orchestration and player-flow coverage is incomplete

**Severity: Medium**

The test runner has 30 unit suites and one integration suite and reports pass/fail only (`tests/test_runner.gd:3-55`); no coverage measurement exists. Domain and service coverage is strong, but important orchestration scripts lack focused peers, including `scene_router`, `bootstrap`, `mahjong_table`, `fishing_overlay`, `horse_actor`, `hitching_post`, `wayward_farm`, and `save_menu`.

The current smoke test verifies autoloads, input actions, data tables, the main scene, and selected generated assets (`tests/smoke_test.gd:3-69`), but it does not play the new-game-to-Hall progression, exercise mounted save/load, choose crops, validate helper effects, or traverse all settings with physical devices.

### REL-01 — Packaging evidence stops at a development export

**Severity: Medium**

`export_presets.cfg:1-27` defines one Windows Desktop preset, and the recorded packaging command is `--export-debug` (`docs/production/export_validation.md:13-19`). Existing ignored debug artifacts are present and match documented sizes. There is no release-export result, installer/package metadata, release notes, or clean-machine release-candidate evidence.

### REL-02 — Required manual passes remain unverified

**Severity: High**

The plan requires new-game, save/load, controller-only, keyboard-only, window-mode/resolution, weather, full Mahjong/High Noon, farm, fishing, horse, schedule, Hall, audio, hot-plug, alt-tab, and clean-profile passes (`docs/CODEX_MASTER_EXECUTION_PLAN.md:1113-1142`). The status ledger and export report explicitly leave several of these outstanding. Automated headless checks cannot close device, display, feel, or clean-machine gates.

## Reproducibility, assets, and legal findings

### REPRO-01 — The checkout is runnable, but not reproducible from all recorded source archives

**Severity: High for the plan's definition of done; Low for running the tracked slice**

The tracked generated hero, horse, audio, NPC correction, and Mahjong atlas assets are present, and repository validation passes. A clean source rebuild is less complete:

- The supplemental setup requires four ZIPs (`README.md:22-29`; `docs/assets/supplement_integration.md:3-11`), but the local `vendor/local/supplemental/` contains only `Cozy SFX Volume 1.zip`.
- The existing supplemental import marker says the input was expanded directories rather than the verified ZIP set (`assets/source/supplemental/.import_complete.json:4-12`).
- The expanded master asset library exists locally at ignored `assets/MahjongRPG/`, but the optional split-archive fingerprint manifest still has an empty `archives` array (`docs/assets/manifests/master_source_archives.json:1-16`) and `vendor/local/master/` is absent.

This conflicts with the execution plan's requirement that the repository be locally reproducible from recorded source archives (`docs/CODEX_MASTER_EXECUTION_PLAN.md:1214-1217`). It does not prevent the already generated, tracked slice from running.

### REPRO-02 — Supplemental import prerequisites are documented incorrectly

**Severity: Medium**

`docs/assets/supplement_integration.md:25` describes OGG conversion as occurring when `ffmpeg` is available, and the root README does not name `ffmpeg` as a prerequisite. The importer instead stops with an exception when `ffmpeg` is missing (`tools/import_supplemental_assets.py:128-131`). A clean setup following the docs can fail unexpectedly.

### LEGAL-01 — Original code has no redistribution license

**Severity: Conditional**

The asset license is present, but `legal/README.md:3-12` and `README.md:60-62` explicitly state that original project code has no separate open-source license. This is acceptable for a proprietary repository, but it must be resolved before any intended open-source or source-redistribution release.

## Documentation and operations findings

### DOC-01 — Root onboarding and status records are stale

**Severity: Medium**

- `README.md:7-9` still describes a minimal Godot shell and says the playable vertical slice is not complete, while the checkout contains a connected runtime, eight autoloads, tests, and a debug export.
- `docs/production/implementation_log.md:7` says the branch is unpushed and ahead of its origin branch; local Git reports zero divergence from `origin/agent/project-foundation`.
- `docs/production/master_plan_status.md:11,37` says no push or PR is claimed, while the ignored local environment report records an open draft PR. The PR state was not externally verified during this local-only audit.

These discrepancies make the status ledger unreliable as a current handoff document.

### DOC-02 — There are duplicate canonical plans

**Severity: Low**

These pairs are byte-identical at audit time:

- `docs/CODEX_MASTER_EXECUTION_PLAN.md` and `docs/production/CODEX_MASTER_EXECUTION_PLAN.md`;
- `docs/SIX_BRANDS_AT_HIGH_NOON_COMPLETE_GAME_PLAN.md` and `docs/production/SIX_BRANDS_AT_HIGH_NOON_COMPLETE_GAME_PLAN.md`.

Keeping two canonical copies invites future drift.

### OPS-01 — The default `godot` command resolves to the wrong version

**Severity: Medium**

The project requires Godot 4.7.1. On this machine, `godot` resolves to 4.6.2, causing `python tools/verify_export_environment.py --godot godot` to fail. The explicit portable executable at `C:\Users\Doc\AppData\Local\GodotPortable\4.7.1\Godot_v4.7.1-stable_win64_console.exe` passes. The root README does not provide a single reproducible setup/run/test/export command path or warn about this resolution issue.

### OPS-02 — Recovery and troubleshooting procedures are absent

**Severity: Low**

Save backup/recovery exists in code, but the documentation does not explain the Windows location of `user://saves`, how to recover from `.backup`, how the `pre_finale` slot is intended to be used, or how to diagnose failed import/export/manual checks. There is no consolidated operator troubleshooting page.

## Verified strengths

- The main scene and autoload configuration are valid and load on Godot 4.7.1.
- The playable scene graph is connected: bootstrap → Wayward Farm ↔ Dustward and its three interiors, with quest-gated Riverbend. No orphaned runtime world scene or broken transition resource path was found.
- Farming, fishing, animal care, selling, Mahjong, horse travel, save/load, audio settings, display settings, and input remapping all have reachable entry points.
- Generated runtime assets required by the validator and smoke test are tracked and loadable.
- The repository has versioned saves, checksum/backup handling, data-driven catalogs, deterministic Mahjong tests, and a useful recursive resource audit.
- No TODO/FIXME-style source stub was found; the main gaps are incomplete behavior and scope rather than explicit empty functions.
- The current branch was clean before this audit report was added.

## Validation performed

| Check | Result |
| --- | --- |
| `python tools/validate_repository.py` | Passed: `Repository validation passed.` |
| Target Godot version | Passed: `4.7.1.stable.official.a13da4feb` |
| `python tools/verify_export_environment.py --godot <4.7.1-console>` | Passed: `Windows export preflight passed.` |
| `<4.7.1-console> --headless --path . --script res://tests/test_runner.gd` | Passed: all 31 suites |
| `<4.7.1-console> --headless --path . --script res://tests/smoke_test.gd` | Passed: runtime smoke |
| `<4.7.1-console> --headless --path . --editor --quit` | Passed |
| Default-PATH export preflight | Failed as expected: `godot` is 4.6.2, not 4.7.1 |
| Existing ignored Windows debug export | Present; sizes match `docs/production/export_validation.md` |
| Actual export command during this audit | Not rerun; it would rewrite build artifacts and prior evidence already exists |

## Evidence not available or not performed

- A full manual start-to-slice-completion playthrough.
- Physical controller, controller hot-plug, keyboard-only, focus, haptics, and remapping passes.
- Windowed/borderless/fullscreen, 960×540/1920×1080, alt-tab, and UI-scaling passes.
- A user-observed clean Windows profile or separate clean machine launch.
- A clean rebuild from all pinned supplemental and master source archives.
- Release-mode export, packaging, installer, performance profiling, or soak testing.
- External verification of the draft PR or remote CI state.
- Full-game story, ending, postgame, content-completeness, and migration matrices because those systems/content are not present.

## Recommended closure order

1. Decide and label the next deliverable unambiguously: internal vertical slice, public demo, or full game. Do not use full-game completion language for the current checkout.
2. Close the slice's false-completion gaps: implement Brand loadout selection/unlocks, make Mabel's helper unlock functional, preserve mounted save position, and add crop selection.
3. Add focused tests for those paths plus one automated new-game-to-First-Lantern progression flow.
4. Run the Godot target-engine tests and smoke/editor checks in CI, not only the Python repository guard.
5. Restore and verify the complete recorded source-archive set, correct the `ffmpeg` prerequisite, and prove a clean rebuild.
6. Complete the documented manual device/display/save/export matrix and a clean-profile Windows launch.
7. Refresh the README/status ledger, choose one canonical location for each plan, and document recovery/troubleshooting.
8. Only after the slice gates pass, schedule milestones 11–19 for the full game.

## Final assessment

The checkout is a credible, connected, automated-test-backed vertical-slice foundation. It is not a complete game, and it should not yet be labeled a complete vertical slice under its own definition of done. The most important discrepancy is not missing code volume; it is the mismatch between status claims and player-visible behavior: two Brands are forced rather than selected, the helper unlock has no effect, mounted saves can restore at the wrong position, and release acceptance remains partially manual and unverified.
