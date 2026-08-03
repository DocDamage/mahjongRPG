# Quest Objectives Q3-Q4 Completion Audit — 2026-08-03

## Outcome

Q3's Mayor Bell linear-dialogue pilot and Q4's shared content-validation/advisory-tooling work are implemented. Save schema remains 21. The dialogue catalog advances to schema 4 and its linear sequence schema is 1. No third-party source, runtime addon, art, audio, or incompatible-license asset was incorporated.

The automated decision and exit gates pass. Physical keyboard/controller and display-preference observations remain explicit release-evidence checkpoints in `docs/qa/manual_device_display_matrix.md`; this audit does not claim that headless input events replace a physical-device walkthrough.

## Q3 requirements and evidence

| Requirement | Delivered evidence |
| --- | --- |
| Record existing behavior | `docs/implementation/mayor-bell-dialogue-pilot.md` records the three committed actions, choice IDs, +1 relationship deltas, helper, resolved schedules, save points, and state diagram. |
| Minimal validated linear schema | Dialogue catalog schema 4 contains schema-1 sequences. `DialogueSequenceValidator` rejects unknown or side-effect fields, bad/duplicate IDs, missing keys/references, missing targets, unreachable nodes, cycles, and unsupported schema versions. |
| Accessible, input-complete presentation | `DialogueSequenceRunner` reuses catalog portraits and honors dialogue speed, reduced motion, high contrast, text scale, and UI scale. It has explicit Continue/Cancel focus and keyboard/controller handling. |
| Exactly-once domain commit | `CommunityDialogueCoordinator` revalidates captured arc/action/sequence state and calls `CommunityArcService.advance` only on terminal acknowledgement. Its finished/input locks reject repeated confirmation. |
| Objective event boundary | `dialogue.seen` is constructed only after a successful domain commit and published only when an objective-consumer predicate exists and accepts it. Mayor Bell has no consumer, so ordinary pilot play emits none. |
| Existing side-effect ownership | Relationship, helper, completion, and schedule-facing state remain owned by `CommunityArcService` and existing collaborators; dialogue data contains no arbitrary commands. |
| Persistence restriction | A scoped `SessionGate` blocks save, load, new game, and restore while a sequence is open. Cancel, failed open, teardown, and successful completion release it. Mid-sequence presentation is not serialized. |
| Legacy save coverage | Five fixtures cover inactive, active stage 0, stage 1, stage 2, and completed. Every incomplete fixture starts the expected sequence at its first node and can reach the unchanged final state. |
| Scene migration | `community_arc_panel.gd` and `community_landmark.gd` use a generic sequence data gate and contain no Mayor-specific stage/effect branch. Unmigrated arcs retain the legacy action path. |
| Decision gate | All ten criteria are evaluated and pass in `docs/implementation/mayor-bell-dialogue-pilot.md`, including author steps, LOC, rollback, save policy, stronger tests, and no duplicate effects. |

## Q4 requirements and evidence

| Requirement | Delivered evidence |
| --- | --- |
| Production-rule content entry point | `tools/validate_content.gd` invokes `ContentValidationReport`, which reuses `QuestDefinitionValidator` and `DialogueSequenceValidator`. |
| Contributor report | The report covers malformed/unsupported catalogs, invalid definitions, duplicates, missing references/localization, unreachable dialogue nodes, newer required save schemas, and handwritten GDScript thresholds with source paths. |
| Repository and CI integration | Repository validation parses all `data/` and test-fixture JSON. CI runs editor import, production content validation, native tests, smoke, and the target export checks. |
| Advisory pre-commit | Merge-conflict, JSON, case, naming, new-file-size, repository, and content hooks pass. Generated/imported/third-party/asset/scene/resource/UID/binary paths are excluded. |
| Non-mutating lint/format trial | `docs/implementation/q4-content-tooling-trial.md` records the gdtoolkit 4.5.0 check-only results. `gdformat`/`gdlint` remain manual-stage advisory hooks because the repository-wide report is not clean. |
| Contributor workflow | `docs/contributing/content-validation.md` contains exact setup and validation commands plus expected success output. |
| Release isolation | Contributor scripts and `ContentValidationReport` are excluded from export data; the two production quest/dialogue validators needed by runtime content paths remain packaged. |
| LFS/licensing boundary | Git LFS was not enabled. The optional gdtoolkit trial environment is ignored local tooling, not a runtime or repository dependency. |

## Files and responsibilities

- `src/dialogue/dialogue_sequence_validator.gd`: fail-closed sequence graph/content validation.
- `src/dialogue/dialogue_sequence_runner.gd`: modal presentation, focus, input, accessibility, and terminal/cancel signals.
- `src/dialogue/community_dialogue_coordinator.gd`: captured-state revalidation and exactly-once community commit.
- `src/dialogue/community_dialogue_flow.gd`: generic composition with session restriction ownership.
- `src/core/session_gate.gd`: scoped persistence/session-replacement counters.
- `src/content/content_validation_report.gd`: shared repository-wide production content report.
- `tools/validate_content.gd` and `tools/run_content_validation.ps1`: headless entry points.
- `tools/precommit_project_checks.py` and `.pre-commit-config.yaml`: opt-in engineering guardrails.
- `data/dialogue/vertical_slice_dialogue.json` and `data/community/community_arcs.json`: Mayor Bell lines, sequences, and stage references.

## Handwritten production LOC

Physical line counts include blank lines and were checked at completion.

| File | LOC |
| --- | ---: |
| `src/dialogue/dialogue_sequence_validator.gd` | 147 |
| `src/dialogue/dialogue_sequence_runner.gd` | 244 |
| `src/dialogue/community_dialogue_coordinator.gd` | 55 |
| `src/dialogue/community_dialogue_flow.gd` | 82 |
| `src/core/session_gate.gd` | 23 |
| `src/content/content_validation_report.gd` | 192 |
| `src/world/community_arc_panel.gd` | 80 |
| `src/world/community_landmark.gd` | 53 |

All Q3/Q4 production additions are below the 250-line review threshold. Existing 250-300 line files remain report warnings; no file exceeds the 300-line policy maximum.

## Automated acceptance evidence

The completion pass used Godot 4.7.1 and the repository-root commands below:

```powershell
python tools/validate_repository.py
pwsh -NoProfile -File tools/run_content_validation.ps1
& $SixBrandsGodot --headless --path . --editor --quit
& $SixBrandsGodot --headless --path . --script res://tests/test_runner.gd
& $SixBrandsGodot --headless --path . --script res://tests/smoke_test.gd
python tools/verify_export_environment.py --godot $SixBrandsGodot
pre-commit validate-config
pre-commit run --all-files
python tools/precommit_project_checks.py --all
git diff --check
```

Results at completion:

- repository validation passed;
- shared production content validation passed with 0 errors and 5 existing size warnings across 213 GDScript files;
- Godot editor import passed;
- all 56 native suites passed with no leak/error warning;
- runtime smoke passed;
- Windows export preflight and debug export passed;
- the exported PCK contains the production quest/dialogue validators and excludes contributor validation/pre-commit scripts and the report-only class;
- the exported executable launched under a fresh temporary AppData profile and exited successfully;
- standard-stage pre-commit hooks and standalone project checks passed;
- Python compilation, PowerShell parsing, secret-pattern scan, placeholder scan, and whitespace/diff checks passed.

Automated Q3 coverage includes all three actions, cancel, repeated confirm, completed reopen, save/load/new-game/restore restriction and release, every committed fixture, exact relationship effects, helper assignment, fresh/restored clear-and-rain schedules, normal/reduced motion, two dialogue speeds, scaled/high-contrast presentation, separate keyboard-only/controller-only event paths, focus, both migrated caller paths without legacy fallthrough, and fresh full-arc completion.

## Manual release checkpoint

Before release handoff, record physical evidence for:

- fresh and restored Mayor Bell completion using keyboard only and controller only;
- cancel/reopen, rapid confirm, and active-device switching while the dialogue is visible;
- two text/UI scales, two dialogue speeds, reduced motion, and high contrast in the Windows build;
- save/load/new-game restriction while open and release after cancel/commit;
- a post-completion save/load confirming relationship 3, one helper assignment, and resolved schedule text.

These are observational release checks, not unresolved implementation or automated-contract failures.

## Migration and rollback

Schema 21 is unchanged, so Q3/Q4 require no save migration. Legacy committed community stages deterministically open the first node of their expected sequence. During development, removing Mayor Bell's three `dialogue_sequence_id` fields returns its presentation to the retained legacy action path. Q4 can be rolled back by removing the advisory configuration, scripts, CI step, and contributor documentation; gameplay and save data do not depend on those tools.
