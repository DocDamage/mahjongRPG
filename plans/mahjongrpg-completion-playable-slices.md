# MahjongRPG Completion Plan: Playable Slices

**Created:** 2026-08-02
**Baseline:** `agent/project-foundation` at `102a593`
**Inputs:** `docs/production/REPOSITORY_COMPLETENESS_AUDIT_2026-08-02.md`, `docs/CODEX_MASTER_EXECUTION_PLAN.md`, and `docs/SIX_BRANDS_AT_HIGH_NOON_COMPLETE_GAME_PLAN.md`
**Status:** Reviewed blueprint; critical and major review findings resolved

## Objective

Turn the current tested vertical-slice foundation into the complete Windows game through dependency-ordered phases. Every phase must finish with a coherent build that starts from bootstrap, preserves all earlier loops, loads supported saves, and adds a player-visible reason to play it.

## Non-negotiable invariants

1. **Playable after every phase:** no merged phase may leave fake doors, inert rewards, unreachable feedback, broken saves, or half-connected menus.
2. **Small files:** target 80–220 lines, warn at 250, and keep project-owned handwritten files at or below 300 lines wherever a safe responsibility split exists.
3. **Correctness over line count:** never split a cohesive state machine mechanically. Document a justified exception in `docs/architecture/size_exceptions.md` before accepting more than 300 lines.
4. **Data-driven growth:** content belongs in region/tier catalogs; rules belong in domain services/evaluators; scenes coordinate rather than own global state.
5. **Save continuity:** every schema change ships with forward migration, round-trip, corrupt-save recovery, and prior-public-save fixtures before new content depends on it. Rollback restores a phase-start backup; older binaries are not expected to parse newer schemas.
6. **Accessible by construction:** keyboard/controller parity and non-color/non-audio cues are phase gates, not end-of-project cleanup.
7. **Evidence before status:** update completion ledgers only after automated and manual gates pass.
8. **External actions:** pushing, opening PRs, publishing builds, or changing remote resources still requires explicit user approval.

## What “playable slice” means

A phase is complete only when a fresh save and the previous phase's save can enter the new loop, complete its main objective, return to a safe hub or credits/postgame, save and reload, and continue without developer commands. Disabled future content must be absent or clearly locked, never presented as working.

## File-size architecture

- Add a 250-line warning to `tools/validate_repository.py`; retain the 300-line failure for handwritten source. Report counts in every PR.
- Before feature growth, characterize and review the current pressure points: `mahjong_table.gd` (299), `game_session.gd` (295), `match_flow.gd` (294), `input_service.gd` (288), `farm_service.gd` (260), and `player.gd` (258).
- Preferred seams: session clock/catalog/snapshot assembly; Mahjong match controller/wager panel/turn presenter; hand flow/series scoring; input defaults/device tracking/profile persistence; crop/construction/snapshot state; player movement/animation/interaction.
- Split tests by scenario, JSON by domain/region/tier, and large scenes into reusable subscenes. Generated resources and declarative tables may exceed 300 lines only when splitting would make them less reliable.
- No phase may add a responsibility to a 250+ line file without first extracting that responsibility or recording why the cohesive file is safer unchanged.

## Delivery workflow

- P0–P2 stay on the current foundation lineage or a dedicated local staging branch. After the user-authorized P2 integration, P3 onward starts from the latest integrated `develop`.
- A phase may use several narrow work PRs into a phase branch, followed by one playable integration PR into `develop`.
- Every PR records: player entry path, automated/manual evidence, save-schema impact, files at 250+ lines, feature flags/gates, and exact rollback.
- Keep unfinished content behind data availability and progression flags. Reverting a phase must leave the prior build and its saves usable.
- Seed the Silas/bargain evidence spine in P1 and add an authored clue in every region phase; do not retrofit Acts I–III after the world is built.

## Common phase gates

Run after every phase with the explicit Godot 4.7.1 console executable:

```powershell
python tools/validate_repository.py
<godot-4.7.1> --headless --path . --script res://tests/test_runner.gd
<godot-4.7.1> --headless --path . --script res://tests/smoke_test.gd
<godot-4.7.1> --headless --path . --editor --quit
```

Also test a fresh save, a previous-phase save, keyboard-only, controller-only, two save/load cycles in the new loop, one display mode, audio/settings sanity, and the phase-specific player checkpoint. Export preflight is required from Phase 2 onward; clean-profile launch is required for demo, beta, and release-candidate phases.

## Dependency chain

`P0 → P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8 → P9 → P10 → P11 → P12 → P13 → P14 → P15 → P16 → P17 → P18`

Asset preparation, map blockouts, dialogue drafts, and test fixtures for later region phases may proceed in parallel after P2, using separate region folders. Runtime integration stays serial because progression and save schemas are shared.

## P0 — Safe seams and trusted baseline

- **Context:** the current slice passes 31 suites, smoke, editor load, and export preflight, but four core files sit within 12 lines of the limit.
- **Build:** add characterization tests, a 250-line warning/report, test discovery or small suite registries, and behavior-preserving extractions only where the tests prove a stable seam.
- **Primary areas:** `src/core`, `src/mahjong`, `src/input`, `src/farm`, `src/player`, `tests`, and `tools/validate_repository.py`.
- **Player checkpoint:** the existing Wayward → Dustward → First Lantern → Riverbend loop behaves identically.
- **Exit/rollback:** zero save-schema change and zero intentional gameplay change; revert any extraction that changes replay output, controls, timing, or save bytes.

## P1 — Honest vertical slice

- **Context:** closes audit findings COMP-02/03, DATA-01, and GAME-01/02 before scope expands.
- **Build:** real Orange/Blue unlock and pre-match selection; one visible Mabel helper action; mounted location persistence; four-crop planting choice; inspectable schedule feedback; a minimal localization-ready dialogue/evidence contract with the first Silas clue; focused orchestration tests.
- **Primary areas:** new Mahjong meta/application modules, canonical helper service/data, horse snapshot state/migrator, crop picker, opponent presenter, story/evidence state, and progression integration fixtures.
- **Player checkpoint:** finish First Lantern, use Mabel's help, choose a loadout, plant any active crop, save mounted, reload at the same location, and reach Riverbend.
- **Exit/rollback:** one backward-compatible save bump; old saves receive starter Brands, no helper assignment, and a safe horse fallback.

## P2 — Demo-grade delivery foundation

- **Context:** closes QA, release, reproducibility, documentation, engine-path, and integration findings without adding world scope.
- **Build:** target-engine CI for validator/tests/smoke/editor and test-to-module coverage inventory; restore and verify the complete user-supplied source-archive evidence; correct `ffmpeg` requirements; canonical setup/status/recovery docs; manual device/display matrix; title/load/settings/accessibility shell with persistent text/UI scale, dialogue speed, hold/toggle, reduced motion, subtitles, and controller glyph base; code-license disposition.
- **Primary areas:** `.github/workflows`, `tools`, `docs/assets`, `docs/qa`, `docs/release`, `README.md`, manifests, UI/accessibility/settings, and save recovery guidance.
- **Player checkpoint:** a clean Windows profile can launch the debug demo, configure keyboard/controller and accessibility settings, complete P1, recover a backed-up save, and relaunch.
- **Exit/rollback:** P2 stays blocked while archive, license-disposition, CI, or manual evidence is missing; integrate the foundation and P1 into `develop` only after approval; operational changes must not alter gameplay saves.

## P3 — Four-Brand mastery

- **Context:** extend the honest Orange/Blue loadout without taking on Frontier Rules simultaneously.
- **Build:** Green and Pink claims/powers, unlock quests, bounded upgrades, data-backed Brand definitions, tutorial/advisor steps, UI charge/loadout states, and deterministic replay evidence.
- **Primary areas:** `data/brands`, Mahjong domain/application/presentation, tutorial, save migration, and Brand fixtures.
- **Player checkpoint:** earn Green and Pink through existing-world mastery tasks, equip any two of four, and win a rematch using each new power.
- **Exit/rollback:** cumulative target 4/6 playable Brands; locked Brands remain absent from selection; rollback uses the phase-start save backup while old schemas migrate forward.

## P4 — Frontier Rules and complete Mahjong

- **Context:** later opponents, tournaments, and the finale require the complete table rules first.
- **Build:** Dark/Purple powers, Brand upgrades, 136-tile Frontier wall, 14-tile hands, quads, expanded Deeds/Renown, assistance modes, advanced visible-information AI, replay explanations, and Hall stage 2.
- **Primary areas:** small rule-set strategies, quad/claim evaluators, Deed files, AI memory/evaluation/action modules, Hall data, and rule-specific tests.
- **Player checkpoint:** complete Hall cleanup/structural access, learn Frontier Rules at the reopened tables, choose any two of six Brands, and finish a legal Trail or Frontier match.
- **Exit/rollback:** schema adds rule/loadout/Deed/Hall-cleanup IDs with pre-P4 fixtures; cumulative targets 6/6 Brands, 2/2 rulesets, and 2/5 Hall stages; replay hashes and AI knowledge-boundary tests are mandatory.

## P5 — Bridlewood farm expansion

- **Context:** establish the first new region and a complete crop-to-property loop before multiplying content.
- **Build:** Bridlewood Ranch, opponents 4–5, ten active crops, seeds/quality explanations, first barn/coop/machines, ranch shops, horse identity/location, one property shortcut, region schedules, and the next Silas clue.
- **Primary areas:** `data/regions/bridlewood`, regional scenes, farm catalogs/services, shops, horses, opponents, quests, and schedules.
- **Player checkpoint:** fulfill a Bridlewood crop order, win a regional table, repair a structure, and unlock the farm shortcut.
- **Exit/rollback:** schema adds stable region/opponent/crop/building IDs with pre-P5 fixtures; cumulative target 5/11 opponents and three connected launch regions; old saves begin with Bridlewood locked.

## P6 — Ranch legacy and open-ended farm

- **Context:** complete the farm/animal pillar while its content footprint is still localized.
- **Build:** all 20 supplied crops usable; full launch animal roster with naming, variants, breeding, aging, retirement, capacity, products, buildings, quality, farm/ranch actions extending the P1 helper contract, and route-safe dense placement.
- **Primary areas:** crop/animal/building data, animal state/services, construction/navigation, helper assignments, processing, migrations, and stress fixtures.
- **Player checkpoint:** raise a named lineage from birth to retirement, process its output, and maintain a dense farm without sealing routes.
- **Exit/rollback:** schema adds stable animal/lineage/building IDs; sparse, maximum-placement, large-roster, long-calendar, and pre-P6 fixtures migrate; rollback restores the P6-start backup.

## P7 — Saint’s Landing civic restoration

- **Context:** connect Mahjong mastery and farm wealth to property, government, and Hall progression.
- **Build:** Saint’s Landing, opponents 6–7, major interiors/homes, the canonical relationship/dialogue/property stack with first real cases, civic shops, beginner table night, schedules, a government-record clue, and Hall stage 3.
- **Primary areas:** `data/regions/saints_landing`, property/relationship/dialogue services, quests, opponents, Hall layouts, events, and world routes.
- **Player checkpoint:** resolve one property dispute by match or quest, open a route, and restore the functional Hall practice stage.
- **Exit/rollback:** schema adds stable relationship/property IDs; cumulative targets 7/11 opponents and 3/5 Hall stages; every property outcome and pre-P7 save has a migration fixture.

## P8 — Ironhook trade network

- **Context:** turn inventory and production into a territory-scale economy rather than two sell-all counters.
- **Build:** Ironhook Docks, opponent 8, warehouses/offices, table tokens, posted orders, shop inventories, cooking/preserves/flour/dairy/smoked fish/feed/tonics, bounded food effects, a dock property arc, and a cargo-ledger clue.
- **Primary areas:** `data/regions/ironhook`, economy/orders/shops/crafting/cooking, items/recipes, interiors, dialogue, schedules, and save data.
- **Player checkpoint:** source goods across prior regions, complete a dock order, process a recipe, and use the reward in a Mahjong or access decision.
- **Exit/rollback:** schema adds currencies/order/recipe/effect records; full-inventory, duplicate-delivery, active-order, and pre-P8 fixtures migrate; rollback restores the P8-start backup.

## P9 — Gull’s Rest angler path

- **Context:** complete fishing as an independent profession tied to the trade network.
- **Build:** Gull’s Rest, opponent 9, full launch fish roster, all shore conditions, rods/lines/hooks/bobbers/lures/bait progression, rare conditions, records, market/cabins, recipes, a relationship clue, and repeatable fishing contest.
- **Primary areas:** `data/regions/gulls_rest`, fish/gear/records, contest events, coastal scenes, shops, quests, audio cues, and accessibility assists.
- **Player checkpoint:** discover a rare fish condition, upgrade gear, enter a contest, and sell/cook/wager the catch.
- **Exit/rollback:** schema adds stable fish/gear/record/contest IDs with empty/full-record and pre-P9 fixtures; cumulative target 9/11 opponents; no critical cue is audio/vibration-only.

## P10 — Red Testament mystery

- **Context:** complete Red Testament and most of the seventh region while keeping King's Reach honestly gated until the story converges.
- **Build:** Red Testament and the locked King's Reach approach, opponent 10, desert routes/ruins/bonfires, remaining weather variants, supernatural records, final-rule clues, region secrets, and expert schedules.
- **Primary areas:** `data/regions/red_testament`, weather, story clues, property access, horse/fast travel, scenes/interiors, opponents, quests, and audio.
- **Player checkpoint:** survive a weather-dependent desert route, defeat the final non-King tier, and recover a counterable Texas King rule clue.
- **Exit/rollback:** cumulative targets 10/11 opponents and six complete regions plus a partial seventh; King's Reach/world-complete status waits for P14, and weather/clue/route state has pre-P10 migration fixtures.

## P11 — Community arcs, first half

- **Context:** region records are not complete characters; finish relationships before the finale can depend on allies.
- **Build:** use the canonical P7 stack to author choices/relationships, conditioned schedules, complete arcs for opponents 1–5, active helpers/passives, first required portrait subsets, and post-resolution states.
- **Primary areas:** dialogue/relationships/quests/helpers, opponent-specific data folders, schedules, portraits, localization keys, and arc fixtures.
- **Player checkpoint:** complete five distinct multi-stage arcs and use their helpers/passives in farm, fishing, economy, or Mahjong play.
- **Exit/rollback:** schema adds stable choice/relationship/arc/helper-assignment IDs; active/completed/mixed and pre-P11 fixtures migrate; cumulative target 5/10 arcs.

## P12 — Community arcs, second half

- **Context:** finish the authored people and homes before public-system state changes depend on their outcomes.
- **Build:** arcs 6–10, all opponent homes, remaining helpers/passives, finale-support states, remaining portrait subsets, and eight region secrets.
- **Primary areas:** remaining opponent folders, homes/scenes, quests/dialogue, relationships/helpers, schedules, portraits, rewards, and arc fixtures.
- **Player checkpoint:** resolve all ten community arcs, visit every opponent home, use the late helpers/passives, and find all eight secrets.
- **Exit/rollback:** schema extends the P11 IDs; active/completed/mixed and pre-P12 fixtures migrate; cumulative targets 10/10 arcs and 8/8 secrets.

## P13 — Hall, property, rank, and public life

- **Context:** converge the completed community into public institutions without mixing five more character arcs into the same migration.
- **Build:** full property system, Mahjong rank, Hall stages 4–5, town tournament, market day, Hall reopening, final championship scheduling, passive contributions, and repeatable/reschedulable events.
- **Primary areas:** Hall/property/rank/event services, authored layouts, region routes, schedules, quests/dialogue, rewards, and event fixtures.
- **Player checkpoint:** resolve remaining disputes, restore the legendary Hall, win a public tournament, attend the reopening, and unlock finale readiness.
- **Exit/rollback:** schema adds stable property/rank/event/Hall-stage IDs; every event phase and pre-P13 save migrates; targets 5/5 Hall stages and a complete non-final public loop.

## P14 — Act III convergence and King’s Reach

- **Context:** P1 and every region have already seeded Acts I–III evidence; this phase converges the authored investigation instead of retrofitting the whole story.
- **Build:** validate/complete the clue chain, bargain discovery, choice consequences, all altered-rule explanations, King's Reach exploration, finale support convergence, and explicit readiness warning.
- **Primary areas:** story state/coordinators, quests/dialogue/localization, evidence/property records, King's Reach scenes, journals, schedules, and migrations.
- **Player checkpoint:** play from inheritance through the bargain reveal, prove Silas is alive, explore King's Reach, and stop safely at the final warning.
- **Exit/rollback:** schema adds final evidence/support/readiness IDs; each clue mix and pre-P14 save migrates; all seven regions are now fully explorable and final entry stays separately gated.

## P15 — Texas King, standoff, and four endings

- **Context:** deliver one cohesive Act IV so no intermediate build ends after an unresolved championship.
- **Build:** opponent 11, legal/counterable final match, final championship, dedicated pre-finale backup, dialogue standoff with local retry, father reveal, Silas return, transparent category evaluator, four endings, epilogues, and credits.
- **Primary areas:** final rules/opponent AI, finale coordinator, ending data/evaluators, credits, save checkpoints, presentation, audio, and full-story fixtures.
- **Player checkpoint:** defeat Texas King, retry a failed standoff without replaying Mahjong, receive the earned ending, and reach credits.
- **Exit/rollback:** schema adds finale checkpoint/ending result IDs; pre-finale, failed-standoff, credits, and pre-P15 fixtures migrate; targets 11/11 opponents and 4/4 endings.

## P16 — Stable postgame and completion

- **Context:** every ending must return to a world where unfinished play remains valid.
- **Build:** postgame transition, public Hall, advanced tables, repeat tournaments, unfinished arcs, King's Reach access, farm/animals/fishing continuity, collections/records, ending summary, and completion support.
- **Primary areas:** postgame state, scene/schedule variants, event reset rules, journals/collections, saves/migrations, dialogue, and long-running fixtures.
- **Player checkpoint:** continue after each ending, finish an old arc, enter a tournament, tend the farm, fish, and complete a collection.
- **Exit/rollback:** schema adds one canonical postgame state with ending provenance; all four transitions and pre-P16 saves migrate; no ending destroys completionist access.

## P17 — Presentation completion and content lock

- **Context:** menu/settings/accessibility infrastructure has shipped since P2; this phase completes content coverage and final presentation after gameplay stabilizes.
- **Build:** complete journals/records, portrait/expression and required-animation coverage, final UI art, all glyph variants, assist tuning, localization coverage, runtime atlases, and full event-keyed audio/music/ambience.
- **Primary areas:** UI/accessibility/input/audio, localization, runtime atlases, portraits/animations, menus/journals, settings migrations, and visual/audio QA.
- **Player checkpoint:** complete the game and core postgame using keyboard or controller with required assists, without relying only on color, sound, vibration, mouse, or rapid timing.
- **Exit/rollback:** settings/localization additions migrate from every prior settings schema; content freezes with stable 60 FPS target and no prototype presentation on the release path.

## P18 — Windows release candidate

- **Context:** gameplay/content are frozen; only verified blockers may change code.
- **Build:** full regression, every public-save migration, corrupt recovery, performance/memory/stutter pass, release export/package, clean-machine launch, legal/credits decision, release notes, support/recovery docs, version/tag, and rollback package.
- **Primary areas:** CI/release tooling, export presets, `docs/release`, legal/credits, migration fixtures, performance evidence, and packaging checks.
- **Player checkpoint:** install on a clean Windows machine, start or load, complete a representative loop and finale/postgame transition, quit, and resume without data loss.
- **Exit/rollback:** every release checklist item has evidence; the last accepted phase build and compatible save-schema range are documented for rollback.

## Target-count checkpoints

| After phase | Opponents | Brands / rules | Regions | Hall | Character arcs | Endings |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| P4 | 3/11 | 6/6, Trail + Frontier | 2 + Riverbend | 2/5 | foundation | 0/4 |
| P7 | 7/11 | complete | 4 + Riverbend | 3/5 | in progress | 0/4 |
| P10 | 10/11 | complete | 6 + partial seventh | 3/5 | in progress | 0/4 |
| P12 | 10/11 | complete | 6 + partial seventh | 3/5 | 10/10 | 0/4 |
| P13 | 10/11 | complete | 6 + partial seventh | 5/5 | 10/10 | 0/4 |
| P14 | 10/11 | complete | 7/7 | 5/5 | 10/10 | 0/4 |
| P15 | 11/11 | complete | 7/7 | 5/5 | 10/10 + King | 4/4 |
| P18 | 11/11 | complete | 7/7 | 5/5 | complete | 4/4 + postgame |

## Audit closure map

| Audit finding | Planned closure |
| --- | --- |
| COMP-02/03, DATA-01, GAME-01/02 | P1 |
| COMP-04, QA-01/02, REPRO-01/02, DOC-01/02, OPS-01/02 | P2, enforced thereafter |
| REL-01/02 | P2 demo evidence; P18 release evidence |
| LEGAL-01 | disposition in P2; final verification in P18 |
| COMP-01 and GAME-03 | P3–P17 content/system slices |

## Anti-patterns to reject

- Growing `GameSession`, `MahjongTable`, or a new “manager” into a cross-domain god object.
- Adding a flag or dialogue reward with no player-visible consumer.
- Merging a region without its return route, objective, reward, schedule, save coverage, and controller path.
- Bumping save schema without prior-save fixtures and recovery behavior.
- Hiding incomplete work behind misleading completion text.
- Splitting files by line number instead of responsibility, or keeping oversized files merely to avoid interface design.
- Treating test-suite count, green repository guard, or a headless launch as proof of a completed player journey.

## Plan mutation protocol

1. **Split a phase** when it needs more than one risky schema migration, changes more than three shared core owners, or cannot produce one coherent checkpoint.
2. **Insert a repair phase** immediately when the latest integrated build loses a prior playable path; feature work waits until the repair gate passes.
3. **Reorder only with dependencies:** content authoring may move earlier, but runtime integration cannot bypass its required rule, economy, region, or story phase.
4. **Defer honestly:** mark content unavailable in data and remove player-facing promises; never ship an inert placeholder to preserve a schedule.
5. **Record mutations:** update this file's status/changelog, the dependency chain, target counts, save compatibility note, and `master_plan_status.md` in the same planning change.

## Registration

This file is the execution blueprint. `docs/production/master_plan_status.md` remains the evidence ledger; it must report achieved gates rather than restating future work. No separate project memory index exists in this repository. An adversarial review completed on 2026-08-02; its Hall-stage, world-count, accessibility, sequencing, phase-size, branch-base, and migration findings are incorporated above.
