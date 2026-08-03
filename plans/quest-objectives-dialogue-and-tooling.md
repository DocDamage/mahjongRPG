# Quest Objectives, Dialogue Authoring, and Tooling Plan

**Created:** 2026-08-03
**Revision:** 4
**Status:** Q0–Q2 implemented with automated gates passing; physical input/display checkpoint pending; Q3/Q4 remain proposed
**Implementation readiness:** Q0 discovery and contracts are recorded in `docs/implementation/quest-objective-q0-discovery.md` and `docs/architecture/quest-objective-contract.md`. Q1/Q2 implementation evidence is recorded in `docs/implementation/first-lantern-objective-pilot.md`.
**Scope:** Improve authored quest progression, dialogue ownership, player-facing quest feedback, save safety, and contributor guardrails without replacing the working Six Brands Mahjong, save, world, content-registry, scene-owned HUD, or accessibility architecture.

**Revision 3 grounding decisions:** Preserve First Lantern's three schema-21 stages; treat explicit fish selection as an intentional improvement; use interaction events rather than a new Q2 dialogue runner; wire only First-Lantern-required events in Q1; use Mayor Bell strictly as a linear Q3 dialogue pilot; choose a reusable tracker host instead of assuming a global HUD; and require validate-before-commit restore behavior.

---

## 1. Intended outcome

Evolve the current ordered-stage `QuestService` into a small, deterministic, event-aware objective system that is easier to author, validate, save, restore, and test.

The system must preserve deliberate player actions:

- Owning an item may satisfy a possession objective, but must never silently turn in or consume that item.
- Opening or displaying dialogue must not count as completing it.
- Highlighting a dialogue choice must not count as committing it.
- A Mahjong win must originate from a completed, validated match result rather than UI state or a scene shortcut.
- Observing an event must not directly award rewards, advance time, change relationships, resolve property state, or mutate inventory.
- Restore and migration must reconstruct state without replaying rewards, completion side effects, autosaves, or player feedback.

The first implementation pilots are:

1. **The First Lantern**, migrated end to end.
2. **Mayor Bell's existing linear community arc**, used as a low-risk dialogue-authoring pilot for ordered lines, relationship commits, helper assignment, schedule-facing completion, and save boundaries.

The quest-objective pattern may expand to remaining quests after Q2 passes. The linear dialogue-authoring pattern may expand to remaining linear community arcs only after Q3 passes. Branching dialogue, property-resolution choices, and other multi-outcome narrative flows require a separate follow-on pilot and are not approved by the Mayor Bell pilot alone.

---

## 2. Definition of success

The work is successful only when all of the following are true:

1. Existing quest callers continue to work through Q2 using the current public API: `start`, `is_active`, `stage`, `stage_count`, `advance`, `complete`, `requirement_count`, `snapshot`, and `restore`; the current quest signals and externally read state dictionaries also remain compatible until their callers migrate.
2. Migrated quests no longer calculate generic quest progress inside scene scripts.
3. The objective evaluator is deterministic, side-effect free, and testable without loading gameplay scenes.
4. Events are validated, deduplicated where required, and applied only to the objectives active when processing begins.
5. One event cannot accidentally complete the current stage and then spill into the newly activated stage.
6. Save/load and schema migration do not duplicate rewards, consume inventory, repeat choices, or emit completion feedback.
7. The First Lantern retains its current narrative order, reward behavior, and post-completion autosave while intentionally replacing automatic first-fish removal with explicit provision selection and confirmation.
8. The Mayor Bell pilot preserves its three authored linear actions, three relationship commits, helper assignment, completion state, dialogue meaning, and post-resolution schedule behavior.
9. The quest tracker is read-only, keyboard/controller usable, non-color-dependent, and coherent with text/UI scale, contrast, and reduced-motion settings; the Q3 dialogue runner also honors dialogue speed.
10. Invalid quest or dialogue content fails closed with actionable diagnostics that identify the file and JSON path.
11. The exact Godot 4.7.1 validation, test, import, smoke, and Windows export-preflight baseline continues to pass.
12. Handwritten GDScript follows the project file-size policy: target 80–220 LOC, review at 250, and remain at or below 300 wherever a safe responsibility split exists.

---

## 3. Non-negotiable constraints

1. Stay on Godot 4.7.1.
2. Retain project-owned services, JSON catalogs, the existing save architecture, and the native test runner.
3. Do not import OpenRPG, PaperTown, QuestSystem, Dialogic, Pandora, Godot RPG Creator, or any donor-project source into `src/` or `addons/` for this work.
4. Do not replace Six Brands Mahjong, free overworld movement, the current UI shell, the content registry, or the save service.
5. Maintain the current quest methods, signals, and externally read state through Q2. This includes `requirement_count`, `stage_count`, `completed`, `unlocked_helpers`, and `hall_milestones`, not only the stage-mutation methods. Deprecation may begin only after every caller has migrated and compatibility tests prove equivalent behavior.
6. Objective definitions may contain only declarative data. Do not allow script paths, expressions, serialized `Callable`s, arbitrary commands, or content-authored code execution.
7. Runtime event payloads may contain only stable IDs, booleans, integers, floats where explicitly allowed, strings, and arrays/dictionaries composed of those values. They must not retain `Node`, `Resource`, UI control, `Callable`, or mutable gameplay references.
8. An event observer must never own the domain transaction that caused the event.
9. Domain effects must be committed by their owning service before a corresponding committed event is published.
10. Rewards remain with their current owner unless a separate ADR explicitly approves moving them. The objective evaluator must never award them.
11. Stable quest, stage, objective, dialogue-sequence, line, choice, item, opponent, ruleset, interaction, and transaction IDs become serialized contracts once shipped. Renaming one requires an explicit migration.
12. No broad event-bus singleton is introduced. The adapter is session-scoped and binds only to the services required by the current session.
13. Do not perform unrelated cleanup, mass formatting, or file moves in the migration PRs.
14. Any save-schema bump must include migration fixtures from schema 21, round-trip tests, idempotent migration, corrupt-state rejection, and a documented rollback boundary.
15. No phase may merge with placeholder code, TODO-only behavior, disabled tests, or a knowingly broken player path.
16. Restore and migration code added or changed by this work must validate before committing state. A rejected quest/objective restore must leave the previously valid in-memory state unchanged; Q0 must determine whether the existing session-wide restore path also needs staging or rollback to meet this guarantee.

---

## 4. Q0 facts that must be verified before production changes

The source plan names the intended components but does not establish the repository’s exact current implementation. Q0 must verify, document, and link the following facts rather than assuming them:

- The exact `QuestService` state shape, signal surface, reward ownership, and save representation.
- Every caller of quest methods, signals, and directly read state dictionaries, including indirect wrappers.
- The exact schema-21 quest fields and all existing schema-21 migration fixtures.
- Whether quest stages are currently persisted as numeric indices, IDs, or both.
- The existing inventory API for validating and atomically removing a selected batch of items.
- Whether inventory transactions already produce a stable receipt or transaction ID.
- The actual three-stage First Lantern sequence, its current automatic bean/first-fish removal, provision rules, eligible fish rules, rewards, milestones, evidence, helper assignment, and autosave owner.
- The existing dialogue catalog and portrait-presentation interfaces.
- The fact that the current project has localized text lookup and feedback labels but no modal dialogue-sequence runner; Q3 must therefore choose a save policy for newly introduced sequences rather than claim to preserve an existing one.
- The exact Mahjong result signal/API and the trusted owner of opponent and ruleset IDs.
- Session creation, replacement, restore, and teardown order in `GameSession`.
- Current keyboard/controller focus rules for the UI shell.
- Mayor Bell's actual linear relationship/helper/schedule/save coupling and the absence of a property or branching-choice outcome in that arc.
- The actual LOC of every likely touched file, including `game_session.gd`, `player.gd`, and any Mahjong presentation owner, and whether any must be split before feature wiring.
- Whether a semantically rejected session restore can currently leave earlier services partially mutated, and the smallest safe staging or rollback seam if it can.

Q0 must produce a short discovery report. Any mismatch between this plan and the repository is resolved in that report and the architecture ADR before Q1 begins.

---

## 5. Target architecture

```text
Player-confirmed action or trusted domain result
                    |
                    v
        Owning domain service commits change
                    |
                    v
      Stable transaction/result receipt is created
                    |
                    v
      Session-scoped QuestEventAdapter normalizes it
                    |
                    v
           QuestService.submit_event(event)
              |                     |
              v                     v
 Definition validation      Pure objective evaluation
              |                     |
              +-----------> Quest state commit
                                      |
                     +----------------+----------------+
                     v                                 v
           Read-only projection signals       Existing effect owner
                     |                         handles rewards/feedback
                     v
        QuestJournalPresenter / world UI
```

### 5.1 Ownership boundaries

| Component | Owns | Must not own |
| --- | --- | --- |
| World interaction coordinator | Player confirmation, interaction flow, calling domain transactions | Generic objective matching or direct quest-state edits |
| Inventory service | Item counts, selection validation, atomic add/remove, transaction receipt | Quest-stage decisions |
| Mahjong service/result owner | Match completion and validated result | Quest rewards or stage edits |
| Dialogue runner | Rendering, text progression, focus, choice confirmation, resumable sequence state | Quest, relationship, property, inventory, or reward mutation |
| `QuestEventAdapter` | Signal binding, normalization, event-envelope construction | Quest state, rewards, inventory mutation, dialogue rendering |
| `QuestDefinitionValidator` | Structural and semantic definition validation | Runtime state mutation |
| `QuestObjectiveEvaluator` | Pure match/progress calculation | Signals, saves, service calls, rewards, UI, Nodes |
| `QuestService` | Active/completed quest state, compatibility API, event application, snapshot/restore | Player-facing rendering or domain transactions |
| `QuestJournalPresenter` | Read-only projection for tracker/journal | Calling `advance`, `complete`, or mutating services |
| Existing reward/effect owner | Exactly-once rewards and existing completion effects | Objective matching |

For The First Lantern, the current owners are explicit contracts unless Q0 approves a change:

- `QuestService.complete` owns the completed record, `unlocked_helpers`, and the `first_lantern` hall milestone.
- The Hall interaction coordinator owns the ordered call to assign Mabel, discover the Silas evidence, present completion feedback, and request the post-completion autosave.
- `InventoryService` will own selection validation and atomic batch removal; the coordinator will own confirmation and transaction ordering.

### 5.2 Proposed file boundaries

Final paths may be adjusted during Q0 to match existing project conventions, but responsibilities must remain separated.

| Responsibility | Proposed file | Target LOC |
| --- | --- | ---: |
| Objective and quest-definition validation | `src/quests/quest_definition_validator.gd` | 120–200 |
| Pure event matching and progress calculation | `src/quests/quest_objective_evaluator.gd` | 140–220 |
| Event result codes and envelope helpers, if not small enough to colocate | `src/quests/quest_event.gd` | 80–140 |
| Persisted state and compatibility quest API | `src/quests/quest_service.gd` | 180–260 |
| Session signal bindings and event normalization | `src/quests/quest_event_adapter.gd` | 120–200 |
| Read-only tracker/journal projection | `src/quests/quest_journal_presenter.gd` | 100–180 |
| Dialogue definition validation, introduced only in Q3 | `src/dialogue/dialogue_sequence_validator.gd` | 120–200 |
| Dialogue sequence runner/adapter, only if existing UI cannot serve the contract | `src/dialogue/dialogue_sequence_runner.gd` | 160–260 |
| Reusable player-owned tracker UI, final host selected in Q0 | `src/ui/quest_tracker.gd` and/or `src/ui/quest_tracker.tscn` | 100–180 |
| Focused unit suites | `tests/unit/test_quest_*.gd` | ≤220 each |
| Focused dialogue suites | `tests/unit/test_dialogue_*.gd` | ≤220 each |

`GameSession`, `player.gd`, `hall_foreman.gd`, Mahjong presentation, and community scenes must not absorb evaluator logic. `game_session.gd` is already at the review threshold and `player.gd` is already above it; if adapter or tracker wiring would grow either file, extract composition or add a reusable child component first. The current world uses scene-owned HUDs rather than one persistent gameplay UI shell, so Q0 must choose and test a concrete cross-scene tracker host. The preferred seam is a reusable `CanvasLayer` child of `player.tscn`, provided it does not duplicate after scene changes.

---

## 6. Quest event contract

### 6.1 Closed event kinds and rollout

The contract is closed, but runtime wiring is introduced only when a pilot requires it:

| Kind | Meaning | Required payload | Dedupe requirement | Runtime rollout |
| --- | --- | --- | --- | --- |
| `interaction.completed` | A named interaction completed after player confirmation and domain validation | `interaction_id` | Required | Q1/Q2 |
| `inventory.changed` | An observer-only item-count report; never a delivery or turn-in | `item_id`, `previous_count`, `current_count`, `reason` | State replacement, not additive | Q1/Q2 |
| `inventory.delivered` | A selected inventory batch was removed successfully as one explicit transaction | `delivery_id`, `transaction_id`, `items` | Required; `transaction_id` is the idempotence key | Q1/Q2 |
| `dialogue.seen` | A named authored sequence reached its terminal node and the final line was acknowledged | `sequence_id` | Required for committed progression | Q3, after a runner exists |
| `mahjong.won` | A completed match was validated as a win by the trusted match-result owner | `match_id`, `opponent_id`, `ruleset_id` | Required; `match_id` is the idempotence key | Reserved; no runtime adapter until a real objective needs it |
| `story.choice` | A stable player-selected choice was confirmed and committed | `sequence_id`, `choice_id` | Required | Reserved for a later branching pilot |

Q1 validates and evaluates only the kinds enabled in Q1. Reserved kinds may be documented as future contract names, but Q1 must not refactor Mahjong completion or add choice persistence merely to make an unused adapter exist.

`dialogue.seen` has strict semantics once enabled: displaying, opening, or partially advancing a sequence does not emit it. The First Lantern Q2 pilot uses `interaction.completed` for Mabel's current instant text presentation so that Q2 does not silently introduce a dialogue runner.

### 6.2 Event envelope

Every submitted event uses a normalized envelope:

```gdscript
{
    "contract_version": 1,
    "event_id": "stable-id-or-empty-for-state-report",
    "kind": "inventory.delivered",
    "source_id": "hall_foreman",
    "payload": {
        "delivery_id": "first_lantern.provisions",
        "transaction_id": "stable-transaction-id",
        "items": [
            {"item_id": "stable-item-id", "quantity": 1}
        ]
    }
}
```

Rules:

1. `contract_version`, `kind`, `source_id`, and `payload` are always required.
2. `event_id` is required for committed or cumulative events. It may be empty only for non-additive state reports such as `inventory.changed`.
3. `source_id` identifies the trusted producer, not a scene-node path.
4. IDs must match the project’s stable-ID pattern selected in Q0 and must not be localized display strings.
5. Quantities must be integers greater than or equal to zero. Delivery quantities must be greater than zero.
6. Unknown keys are rejected in development/test validation to catch authoring mistakes. Production behavior fails closed without mutating quest state.
7. Invalid events produce a structured result and one diagnostic; they do not throw uncontrolled errors in normal gameplay.
8. Event payloads are copied before evaluation so later mutation by a caller cannot affect quest state.

### 6.3 Event submission results

`QuestService.submit_event(event)` returns a clear enum or equivalent result object. Required outcomes:

- `PROGRESSED`
- `STAGE_COMPLETED`
- `QUEST_COMPLETED`
- `ACCEPTED_NO_PROGRESS`
- `DUPLICATE`
- `REJECTED_INVALID`
- `REJECTED_NOT_ACTIVE`
- `REJECTED_OUT_OF_ORDER`

Callers use the result only for transaction safety and diagnostics. They must not manually compensate by calling `advance` after a no-progress result.

### 6.4 Deterministic application rules

For every event:

1. Validate and deep-copy the envelope.
2. Capture the active quest/stage/objective set before evaluation.
3. Reject a previously processed committed `event_id` while its bounded dedupe record exists. After an irreversible stage transition, the stage preflight must reject the old action before any domain mutation even if the event result is `REJECTED_OUT_OF_ORDER` rather than `DUPLICATE`.
4. Evaluate only the captured objective set.
5. Apply non-additive state reports by replacement, never by increment.
6. Commit objective progress and at most one stage transition.
7. Never reapply the same event to objectives activated by that transition.
8. Update quest completion state once.
9. Emit progress/stage/quest signals only after state is committed.
10. Let the existing effect owner perform rewards and completion feedback using an idempotence key.
11. Schedule autosave only after every domain and quest mutation for that player action has completed.

This explicitly prevents event cascading, duplicate rewards, and restore-time replay.

---

## 7. Objective-definition contract

### 7.1 Initial supported objective types

Q1 intentionally ships one objective type:

1. `event_once`
   Completes after one matching committed event.

The following types are reserved but not implemented or enabled in shipped Q1/Q2 content:

- `event_count`: counts distinct committed events. It requires schema 22 unless progress is read from an authoritative bounded domain record.
- `inventory_at_least`: evaluates current counts without consuming items. Before enabling it, an ADR must decide whether completion is dynamic or latched and how a latched completion persists. The First Lantern does not need this type; live provision counts are read-only projection/preflight data.

Stage completion supports `all` in Q1. Schema-21 authored stages used in Q2 contain one irreversible `event_once` objective each. Multiple partially completed objectives, `any`, optional objectives, loops, or a generic branching language require a later ADR and, where state cannot be derived, schema 22. The linear Mayor Bell pilot does not add a choice-transition primitive.

### 7.2 Illustrative quest schema

The exact catalog wrapper must follow the repository's current JSON structure. This example deliberately preserves the existing three numeric stages so schema 21 remains viable through Q2:

```json
{
  "objective_schema": 1,
  "id": "first_lantern",
  "definition_version": 2,
  "requirements": {"crop_beans": 1, "any_fish": 1},
  "stages": [
    {
      "id": "meet_mabel",
      "legacy_stage": 0,
      "completion_mode": "all",
      "objectives": [
        {
          "id": "meet_mabel",
          "type": "event_once",
          "label_key": "quest.first_lantern.meet_mabel",
          "event_kind": "interaction.completed",
          "match": {
            "interaction_id": "first_lantern.meet_mabel"
          }
        }
      ]
    },
    {
      "id": "gather_provisions",
      "legacy_stage": 1,
      "completion_mode": "all",
      "objectives": [
        {
          "id": "deliver_selected_provisions",
          "type": "event_once",
          "label_key": "quest.first_lantern.gather_provisions",
          "event_kind": "inventory.delivered",
          "match": {
            "delivery_id": "first_lantern.provisions"
          }
        }
      ]
    },
    {
      "id": "light_lantern",
      "legacy_stage": 2,
      "completion_mode": "all",
      "objectives": [
        {
          "id": "complete_lantern_interaction",
          "type": "event_once",
          "label_key": "quest.first_lantern.light_lantern",
          "event_kind": "interaction.completed",
          "match": {
            "interaction_id": "first_lantern.lantern"
          }
        }
      ]
    }
  ]
}
```

The existing top-level requirements remain the authoritative read-only source for Q2 tracker counts and delivery preflight. Meeting those counts does not complete or latch a separate objective and never removes inventory. The explicit selection UI must allow one eligible fish and one bean under the current authored rule; eligibility, selection, revalidation, and atomic removal remain in the inventory/interaction transaction. The quest objective matches the successful `delivery_id`; it does not choose or remove items.

This is an intentional behavior improvement: the current interaction automatically removes a bean and the first fish found. Q2 replaces that automatic removal with player-visible selection and confirmation while preserving the same quantities, narrative order, final reward, and save boundary.

### 7.3 Definition validation rules

The validator must reject or report:

- Unknown schema versions.
- Missing or duplicate quest, stage, objective, sequence, line, or choice IDs.
- IDs that violate the project’s stable-ID format.
- Unknown objective or event kinds.
- Invalid targets or quantities.
- Empty stages or objectives.
- Missing localization, speaker, portrait, item, opponent, ruleset, interaction, or sequence references when those catalogs are available for cross-validation.
- Duplicate or non-unique `legacy_stage` mappings.
- Stage links to missing targets.
- Unsupported cycles or unreachable stages.
- Event match fields not allowed for the selected event kind.
- Runtime-only data such as node paths, script paths, expressions, or arbitrary commands.
- Definitions that require partial persisted progress while the active save schema cannot represent it.

Diagnostics must identify the source file and a JSON-style path such as:

```text
data/quests/vertical_slice_quests.json $.quests[0].stages[2].objectives[0].match.delivery_id
```

Legacy quest definitions without `objectives` remain valid through Q2 and continue to use manual stage progression.

---

## 8. State, persistence, migration, and restore

### 8.1 Persistence decision table

| State | Authoritative source | Duplicate in quest save? |
| --- | --- | --- |
| Active/completed quest and current legacy stage | Existing `QuestService` state | Preserve existing representation through Q2 |
| Current inventory count | Inventory service | No |
| A one-shot event that immediately completes its stage | Current stage after commit | No additional record required |
| Multiple independent one-shot objectives partially complete in one stage | Quest objective progress | Yes; requires schema 22 |
| Cumulative `event_count` progress | Quest objective progress | Yes; requires schema 22 unless a trusted domain record is queried |
| Event IDs needed to deduplicate active cumulative progress | Quest objective progress | Yes; bounded and requires schema 22 |
| Completed quest reward state | Existing reward/save owner | Preserve existing authoritative state; do not infer from UI |
| Active dialogue node | Not persisted in Q3; save/load/session replacement is scoped-restricted while open | Schema-22 follow-on only if exact mid-sequence resume is later approved |

### 8.2 Default schema strategy

The selected default is to keep schema 21 through Q2 by preserving The First Lantern's three numeric stages, authoring one irreversible `event_once` objective per stage, and deriving live provision counts from the inventory service without latching them as objective progress.

The Q2 mapping is fixed unless Q0 discovers contradictory shipped-save evidence:

| Schema-21 numeric stage | Stable stage ID | Next intentional action |
| ---: | --- | --- |
| 0 | `meet_mabel` | Complete the initial Mabel interaction; this state is valid even though normal play currently advances it synchronously |
| 1 | `gather_provisions` | Gather, explicitly select, confirm, and atomically deliver one bean and one eligible fish |
| 2 | `light_lantern` | Return to the Hall and complete the lantern interaction |

Adding a fourth persisted possession/delivery stage is not permitted under the schema-21 strategy. If Q0 proves that a separate latched possession stage is required, Q0 must select schema 22 and replace this mapping before Q1 begins.

A schema-22 bump becomes mandatory when any shipped phase needs state that cannot be reconstructed safely from:

- current quest stage,
- completed quest records,
- authoritative domain state, or
- stable committed domain records.

Q0 must record the concrete decision. Do not postpone that decision into the middle of Q1.

### 8.3 Schema-22 shape, when triggered

The exact placement must match the existing save document, but objective state must be bounded and keyed by stable IDs:

```json
{
  "quest_objective_progress": {
    "first_lantern": {
      "definition_version": 2,
      "stage_id": "example-stage-id",
      "objectives": {
        "example-objective-id": {
          "current": 2,
          "seen_event_ids": ["event-a", "event-b"]
        }
      }
    }
  }
}
```

Rules:

- Persist only active partial progress that cannot be derived.
- Bound `seen_event_ids` by the objective target and discard the record when the objective or quest completes.
- Never store Nodes, service references, localized labels, or full event payloads.
- Save the quest definition version used to interpret the progress.
- Definition-version changes require a mapping or migration; do not silently reinterpret old progress under reordered content.

### 8.4 Schema-21 migration requirements

For every schema-21 fixture:

1. Map numeric stages 0, 1, and 2 to `meet_mabel`, `gather_provisions`, and `light_lantern` respectively.
2. Preserve active/completed state exactly.
3. Create no partial objective progress for the Q2 mapping; each stage is represented by its current numeric/stable stage alone.
4. Rehydrate read-only inventory projection counts only after inventory has restored; do not convert counts into a latched completion.
5. Do not emit progress, stage-completed, quest-completed, reward, feedback, or autosave signals during migration or restore.
6. Do not rerun helper assignment, evidence awards, milestones, relationship changes, or schedules.
7. Reject impossible stage values, unknown quest IDs, invalid progress values, and mismatched definition versions through the existing corrupt-state path. Do not guess.
8. Prove migration idempotence: migrating an already migrated snapshot must not alter it again.
9. Prove round-trip stability: migrate, save, restore, save again, and compare normalized state.
10. Validate all proposed quest/objective state before assigning it. A rejected restore must leave the prior `QuestService` snapshot byte-for-byte equivalent after normalization.

### 8.5 Required restore order

The session restore pipeline must be explicit and tested:

1. Load and validate catalogs.
2. Validate or stage authoritative domain service state such as inventory, relationships, property, and Mahjong history before exposing it as committed session state.
3. Validate and restore quest active/completed/stage/progress state with signals suppressed and without partial assignment on failure.
4. Restore dialogue-session state if Q3 introduces it.
5. Construct or reset the session-scoped `QuestEventAdapter`.
6. Bind each source signal exactly once.
7. Resynchronize read-only derived projection facts, including current inventory counts, without treating them as player transactions or objective completion.
8. Rebuild the journal projection.
9. Emit one read-only `projection_refreshed` or equivalent signal.
10. Resume gameplay without rewards, completion effects, or autosaves caused solely by restore.

---

## 9. Transaction and idempotence rules

### 9.1 Inventory delivery

The First Lantern delivery flow must use an explicit transaction boundary:

1. Confirm the quest is active and currently expects the named delivery through a read-only query.
2. Present the current eligible inventory to the player.
3. Require explicit item selection and confirmation.
4. Validate selected IDs, eligibility, and quantities against current inventory.
5. Atomically remove the complete selected batch through the inventory service.
6. Receive or create a stable transaction receipt for the successful batch operation.
7. Submit `inventory.delivered` using that receipt’s transaction ID.
8. Accept only `PROGRESSED`, `STAGE_COMPLETED`, or `QUEST_COMPLETED` as successful quest outcomes.
9. If the event is unexpectedly rejected after removal, roll back the same inventory transaction when the inventory API supports rollback. The current inventory API has neither batch transactions nor rollback, so Q0 must approve either a new atomic batch/rollback method or a synchronous preflight-and-commit design before Q2 begins.
10. Do not autosave until inventory, quest progression, rewards, milestones, helper assignment, and evidence mutations for the action have settled. Player-visible feedback may be emitted after the save result is known, matching the current completion flow.

The coordinator must preflight the expected stable stage before any removal. Repeating the action or receipt must never remove more inventory or progress the quest again. A replay while a bounded receipt record exists returns `DUPLICATE`; a replay after the irreversible stage transition may return `REJECTED_OUT_OF_ORDER`.

### 9.2 Mahjong results

- This contract is reserved and has no Q1 runtime wiring. The current match flow has no stable persisted `match_id`, and presentation code currently owns opponent/ruleset-aware reward calls.
- Only the trusted match-result owner may emit `mahjong.won`.
- The adapter must include stable `match_id`, `opponent_id`, and `ruleset_id` values.
- UI buttons, result labels, and scene state are not accepted as proof of a win.
- A repeated `match_id` is a duplicate.
- Wrong opponent, wrong ruleset, abandoned match, loss, or malformed result produces no progress.

### 9.3 Dialogue and choices

- `dialogue.seen` is enabled in Q3 only and is emitted only after the terminal line is fully acknowledged and the owning coordinator has committed the corresponding community action.
- Fast-forwarding text may accelerate presentation but must not skip required terminal acknowledgment.
- Cancelling, reopening, or repeatedly pressing confirm must not duplicate the community action, relationship change, or helper assignment.
- `story.choice`, branching choice state, and property effects are reserved for a later pilot; Q3 does not implement them.

### 9.4 Rewards and completion effects

Retain the current reward/effect owner. Add or verify an idempotence key such as a stable quest completion ID. Quest restore and repeated completion signals must not issue the reward twice.

For The First Lantern, explicitly preserve exactly-once behavior for:

- helper assignment,
- evidence,
- hall milestone,
- player-visible completion feedback, and
- post-completion autosave.

The Q0 ownership report must record the exact call order. Q2 may centralize that order in a thin coordinator, but it must not move rewards into the pure evaluator or trigger effects solely by replayable restore signals.

---

## 10. Signals and read-only UI projection

### 10.1 Required quest signals

Use the project’s signal conventions, but the behavior must distinguish state changes:

```gdscript
signal objective_progressed(quest_id: StringName, objective_id: StringName, current: int, target: int)
signal objective_completed(quest_id: StringName, objective_id: StringName)
signal quest_stage_changed(quest_id: StringName, stage_id: StringName)
signal quest_completed(quest_id: StringName)
signal projection_refreshed()
```

Do not emit duplicates when the projected values have not changed. Restore may emit only the final projection refresh, not progression/completion signals.

### 10.2 Projection API

The presenter receives immutable/read-only data containing only what UI needs:

- quest ID,
- quest title key,
- active stage ID,
- objective ID,
- objective label key,
- current count,
- target count,
- completion state,
- next intentional action text key,
- optional location/speaker hint key if already supported by the project.

The presenter must not receive direct access to `QuestService` mutation methods.

### 10.3 Tracker behavior

The compact tracker/journal entry must:

- Show the active step and next intentional action.
- Show live provision counts where relevant.
- Distinguish complete/incomplete state with text or iconography, not color alone.
- Refresh after quest progress, inventory change, restore, scene transition, and service replacement during `start_new_game`.
- Preserve focus and controller navigation when updating.
- Avoid animation or use the existing reduced-motion preference.
- Use current text-scale, UI-scale, contrast, and readability conventions; dialogue speed applies only to the Q3 runner, not the read-only tracker.
- Avoid stealing focus when progress updates during world play.
- Display a safe fallback string in development if localization is missing, while CI treats the missing key as an error.

---

## 11. Dialogue-sequence contract for Q3

Q3 introduces the smallest linear contract that can preserve Mayor Bell's three existing community actions. It is not a general visual-novel engine and does not approve branching dialogue.

### 11.1 Allowed node types

- `line`: one stable line with speaker, portrait key, text key, and next node.
- `end`: a terminal node that reports acknowledged sequence completion to the owning coordinator.

Illustrative structure:

```json
{
  "dialogue_schema": 1,
  "id": "community.mayor_bell.meet",
  "start_node_id": "opening",
  "nodes": [
    {
      "id": "opening",
      "type": "line",
      "speaker_id": "mayor_bell",
      "portrait_key": "mayor_bell.neutral",
      "text_key": "community.mayor_bell.meet",
      "next_node_id": "acknowledged"
    },
    {
      "id": "acknowledged",
      "type": "end"
    }
  ]
}
```

### 11.2 Prohibited content behavior

Dialogue JSON must not contain:

- arbitrary service calls,
- script paths,
- embedded expressions,
- inventory/reward/relationship/property mutation commands,
- quest-stage numbers to set directly,
- node paths or scene references,
- arbitrary delays or animations that bypass accessibility preferences.

The runner reports terminal acknowledgment to a thin coordinator. The coordinator verifies the still-current expected action, calls `CommunityArcService.advance`, and only then publishes `dialogue.seen` if a quest objective actually observes it. `CommunityArcService`, `RelationshipService`, and `HelperService` retain their current state/effect ownership.

### 11.3 Dialogue validation

Validate:

- unique sequence and node IDs,
- a valid start node,
- valid next-node references,
- at least one reachable terminal node,
- no unreachable nodes unless explicitly marked as retained content,
- no unsupported cycles in the pilot,
- valid speaker, portrait, and localization references,
- deterministic restore target,
- no forbidden side-effect fields.

Choice-node validation is defined only when a later branching pilot adds that node type.

### 11.4 Mid-sequence save policy

The current project has no modal dialogue sequence to resume. For the schema-21 linear pilot, Q3 uses one explicit policy:

- Request a scoped persistence restriction while a sequence is open. The current service restricts saving but not loading, so Q3 must either add a compatibility-preserving load restriction or ensure the modal input owner blocks load/session replacement until cancel or commit.
- On cancel or scene teardown before terminal acknowledgment, commit no community, relationship, helper, or dialogue event state.
- On terminal acknowledgment, synchronously commit the expected community action, release the restriction, and return to ordinary save behavior.
- A load therefore resumes from the last committed community action and starts its uncommitted sequence from the first node.

Persisting an active sequence/node becomes a schema-22 follow-on feature. Do not partially implement both policies in Q3.

---

## 12. Implementation phases

### Phase Q0 — Discovery, characterization, contracts, and safe seams

**Purpose:** Freeze the behavior that must survive, establish exact repository facts, and make the save/event decisions before changing production state.

#### Work

1. Produce a caller map for all quest methods, signals, and directly read dictionaries, including `requirement_count`, `completed`, `unlocked_helpers`, and `hall_milestones`.
2. Record the current three-stage First Lantern and Mayor Bell state diagrams, including the current automatic provision removal, relationship calls, helper/evidence/milestone owners, schedule behavior, feedback, and save points.
3. Capture baseline LOC for every likely touched file, explicitly including `game_session.gd`, `player.gd`, `mahjong_table.gd`, and the proposed tracker host.
4. Add characterization tests for:
   - current stage transitions,
   - duplicate `start` behavior for an already active quest,
   - out-of-order manual calls,
   - duplicate completion calls,
   - rewards and autosave,
   - save round-trips,
   - schema-21 recovery behavior,
   - First Lantern's full current player path,
   - a rejected `QuestService.restore` leaving prior state unchanged,
   - whether a rejected session-wide semantic restore can leave partial state,
   - service replacement on `start_new_game`, restore reuse, and adapter lifecycle seams.
5. Add schema-21 fixtures at every relevant First Lantern legacy stage.
6. Write `docs/architecture/quest-objective-contract.md` covering:
   - ownership boundaries,
   - event envelope and result codes,
   - event application order,
   - stable-ID policy,
   - compatibility API strategy,
   - confirmation of the three-stage schema-21 strategy or evidence requiring schema 22,
   - restore signal-suppression policy,
   - validate-before-commit/rollback policy for rejected restores,
   - concrete tracker host and lifecycle,
   - decision not to vendor an addon.
7. Define the versioned objective JSON contract and diagnostics format.
8. Prototype validator/evaluator behavior against copied fixtures only.
9. Prove in tests:
   - duplicate committed events do not count twice,
   - state reports replace rather than increment for read-only projection,
   - out-of-order events do not progress,
   - one event cannot spill into a newly activated stage,
   - restore is idempotent,
   - rejected restore does not mutate prior valid quest state,
   - inventory is never consumed by evaluation.
10. Record any repository mismatch and update this plan before Q1.

#### Likely files

- `docs/architecture/quest-objective-contract.md`
- `docs/implementation/quest-objective-q0-discovery.md`
- `tests/unit/test_quest_service.gd`
- focused objective validator/evaluator test fixtures
- `tests/integration/test_vertical_slice_progression.gd`
- schema-21 save fixtures

#### Exit gate

- Discovery report is complete and references actual files/callers.
- Baseline behavior is characterized before refactoring.
- All existing validation commands pass or pre-existing failures are separately documented.
- The ADR confirms the three-stage schema-21 strategy through Q2 or replaces it with a fully specified schema-22 migration.
- The discovery report records a concrete atomic delivery design, tracker host, reward/effect order, and restore failure policy.
- The event envelope, result enum, stable-ID rules, and same-event stage-cascade rule are final.
- No production runtime behavior or data has changed.

#### Rollback

Delete test-only prototypes and Q0 documentation. No production data or saves are affected.

---

### Phase Q1 — Validator, objective engine, compatibility facade, and adapter

**Purpose:** Add the reusable engine without migrating any existing authored quest.

#### Work

1. Implement `QuestDefinitionValidator` with actionable JSON-path diagnostics.
2. Implement the pure `QuestObjectiveEvaluator`.
3. Add the event envelope/result helpers.
4. Refactor `QuestService` so it remains the persisted state owner and backwards-compatible facade.
5. Make `QuestService.restore` validate all candidate state before assigning it, then add `submit_event` and read-only objective projection APIs.
6. Preserve manual `advance` for legacy stages.
7. For an event-owned stage, make `advance` return a clear incompatibility result in production and assert in tests/debug builds. Do not silently progress it.
8. Add session-scoped `QuestEventAdapter` bindings:
   - inventory changes for read-only projection through a compatibility-preserving signal binding,
   - explicit trusted submission for `interaction.completed` and `inventory.delivered`.
9. Make bind/unbind deterministic for:
   - service replacement during `start_new_game`,
   - restore,
   - repeated initialization,
   - scene changes, which must not destroy or duplicate the session-scoped binding.
10. Add projection signals and a presenter API without adding the visible tracker yet.
11. Validate all quest catalogs during tests and development startup. Invalid objective content must not leave a partially registered playable quest; return an actionable initialization failure or disable the invalid definition according to the Q0 ADR.
12. Keep existing definitions in legacy mode; do not add objectives to First Lantern in this phase.

#### Required unit coverage

- Every event kind enabled in Q1; reserved kinds must be rejected as not enabled without runtime wiring.
- Every objective type enabled in Q1.
- Exact and non-matching payloads.
- Unknown kind, unknown field, malformed ID, invalid quantity, and invalid target.
- Duplicate event IDs.
- Event before quest start and after completion.
- Out-of-order event.
- One event cannot affect a newly activated stage.
- Multiple matching objectives within the captured stage only if Q0 keeps that capability; shipped schema-21 Q2 content uses one objective per stage.
- State-report replacement.
- Restore with signals suppressed.
- Adapter double-bind and reconnect.
- `start_new_game` service replacement, restore reuse, and old-service disconnect.
- Legacy `advance` compatibility.
- Event-owned `advance` rejection.
- Reward and completion idempotence.
- Rejected restore leaves the prior quest snapshot unchanged.

#### Exit gate

- All legacy quests behave identically.
- First Lantern remains untouched and passes all characterization tests.
- Every schema-21 fixture restores correctly.
- Evaluator tests run without gameplay scenes.
- Adapter connections do not duplicate after two restore/session cycles.
- No evaluator path can call inventory, reward, relationship, property, UI, save, or scene APIs.
- File-size policy passes or approved exceptions are recorded.

#### Rollback

Disconnect/remove the adapter and event APIs. Legacy definitions continue through the unchanged compatibility facade.

---

### Phase Q2 — First Lantern pilot and player-visible tracker

**Purpose:** Migrate one complete quest while preserving its three-stage narrative order, transaction ownership, rewards, and save behavior, while intentionally improving automatic provision removal into explicit selection and confirmation.

#### Work

1. Add stable objective data to `data/quests/vertical_slice_quests.json` for:
   - complete Mabel's existing initial interaction,
   - explicitly deliver the selected provisions while showing live read-only counts,
   - complete the lantern-lighting interaction.
2. Preserve the fixed mapping `0 -> meet_mabel`, `1 -> gather_provisions`, and `2 -> light_lantern`, with one irreversible objective per stage, unless Q0 explicitly approved schema 22.
3. Refactor `hall_foreman.gd` into a thin interaction coordinator.
4. Remove generic stage-number branching from migrated interaction logic where stable objective/stage queries replace it.
5. Replace the current automatic first-fish removal with an explicit, visible eligible-fish selection and confirmation flow; record this as an intentional behavior change.
6. Use an atomic inventory batch transaction and stable delivery receipt.
7. Submit `inventory.delivered` only after a successful removal transaction.
8. Implement rollback or the Q0-approved preflight alternative for an unexpected event rejection.
9. Finalize the lantern interaction in its owning world script/service, then submit `interaction.completed`.
10. While the selection/confirmation UI is open, prevent save/load or new-game service replacement from leaving a stale modal against a replaced service; release that guard on cancel, teardown, or synchronous commit.
11. Add the compact tracker/journal through the Q0-approved reusable host, preferably a `CanvasLayer` child of `player.tscn`; do not copy tracker logic into every scene HUD.
12. Refresh the tracker after:
    - progress,
    - inventory change,
    - save/load,
    - scene transition,
    - service replacement during new game,
    - controller device/focus changes where applicable.
13. Preserve current exactly-once behavior for helper assignment, evidence, hall milestone, feedback, and post-completion autosave.
14. Add schema migration only if Q0 determined it is required.
15. Add an implementation note documenting the final First Lantern stage/objective mapping and transaction order.

#### First Lantern acceptance matrix

| Scenario | Required result |
| --- | --- |
| Interact with Mabel for the current instant introduction | `interaction.completed` advances `meet_mabel` once |
| Repeat the introduction interaction after stage advancement | No additional progress |
| Own some but not all required provisions | Live counts update; no stage completion |
| Own all required provisions | Live counts show readiness; no objective completes and no item is removed |
| Drop/use an item before delivery | Delivery revalidation fails safely and tracker reflects current counts |
| Confirm a valid selected batch | Inventory removes exactly that batch once |
| Repeat the same delivery action or receipt | No additional removal or quest progress; result may be duplicate or out of order |
| Submit delivery event without a successful inventory transaction | Rejected/no progress |
| Interact with lantern before required stage | Rejected/out of order |
| Save/load at every objective boundary | Equivalent next intentional action is restored |
| Restore a completed quest | No repeated rewards, milestone, feedback, or autosave |
| Keyboard-only walkthrough | Pass |
| Controller-only walkthrough | Pass |
| Reduced motion plus text/UI scale and contrast settings | Pass |

#### Exit gate

- A fresh game completes The First Lantern through normal play.
- Possession alone never performs delivery.
- The player explicitly chooses the eligible fish; the fixed bean quantity is shown and confirmed.
- Save/load at every boundary preserves the next action.
- Every schema-21 stage fixture maps to an equivalent objective state.
- Reward and autosave behavior is exactly once.
- No migrated scene calculates generic objective progress.
- Tracker state is read-only, accessible, and correct after two consecutive save/load cycles.
- All Q1 and baseline tests continue to pass.

#### Rollback

- Keep a phase-start release/build and save backup.
- Objective definitions are data-gated so the legacy path can be restored during development.
- A schema-22 migration, if introduced, is forward-only. Production rollback uses the pre-Q2 build and phase-start save, not backward parsing of a newer save.

---

### Phase Q3 — Community-arc and dialogue-authoring pilot

**Purpose:** Prove a minimal linear dialogue-authoring pattern can replace Mayor Bell's automatic expected-action button flow without changing community, relationship, helper, schedule, or save outcomes.

#### Pilot boundary

Mayor Bell is the selected linear pilot because its current behavior is exactly three ordered actions (`meet`, `favor`, `resolve`), one relationship commit per action, helper assignment on completion, and schedule-facing completed state. It has no authored branch or property mutation. Q3 must not claim evidence for choice persistence, property effects, or branching authoring.

If discovery shows Mayor Bell has acquired new coupling after this revision, stop and update the plan; do not silently substitute a branching system. A later branching pilot may inspect the Saint's Landing civic/property flow under its own ADR and save contract.

#### Work

1. Record Mayor Bell's current three-action state diagram, relationship choice IDs/deltas, helper assignment, schedule change, dialogue keys, and committed save points.
2. Add the minimal dialogue-sequence schema and validator.
3. Reuse `DialogueCatalog` and portrait presentation, and integrate the new runner with current input-device, text/UI-scale, dialogue-speed, contrast, and reduced-motion preferences.
4. Add the minimal linear runner because the current project has text lookup and feedback labels but no sequence executor.
5. On terminal acknowledgment, have a thin coordinator revalidate the expected community action and call the existing `CommunityArcService.advance` exactly once.
6. Publish `dialogue.seen` only after that domain commit succeeds and only if an objective consumer exists.
7. Keep relationship mutation and helper assignment in their current services through `CommunityArcService`; do not migrate Mayor Bell into `QuestService`.
8. Apply the scoped persistence restriction while a sequence is open and release it on cancel, teardown, or committed completion.
9. Add fixtures for every current committed legacy save point: inactive, active at stages 0/1/2, and completed.
10. Add authoring validation for unreachable nodes, missing keys, invalid portraits/speakers, duplicate IDs, and unsupported cycles.
11. Document the before/after authoring workflow.

#### Required linear-pilot tests

- Each of the three expected actions and its authored sequence.
- Cancel before commitment.
- Repeated confirm input.
- Reopening a completed sequence.
- Saving and loading/session replacement are rejected or safely deferred while a sequence is open and allowed after cancel/completion.
- Load at each previously committed community stage starts the expected sequence from its first node.
- Relationship update exactly once per action.
- Helper assignment exactly once on resolution.
- Post-resolution schedule correct after fresh play and restore.
- Normal, reduced-motion, and multiple dialogue-speed settings.
- Keyboard-only and controller-only focus/navigation.

#### Decision gate: definition of “materially simpler”

Expansion is approved only if the pilot demonstrates all of the following against the Q3 baseline:

1. The migrated scene/panel contains no Mayor-specific stage branching or direct relationship/helper mutation.
2. Adding or editing ordinary linear lines is primarily a validated data change rather than scene-code branching.
3. All domain side effects remain explicit and owned by their services.
4. The total scene-specific quest/dialogue code is lower or more narrowly responsible than before.
5. The number of required manual authoring steps is reduced and documented.
6. Save behavior is no more complex for authors than the previous implementation.
7. Test coverage is equal or stronger for every committed stage and cancellation boundary.
8. Accessibility and input behavior are unchanged or improved.
9. No duplicate community advance, relationship update, helper assignment, or schedule change is possible.
10. The pattern can be explained as a repeatable linear-arc checklist without adding new engine code for ordinary content.

If the gate fails, retain the objective engine for The First Lantern, keep the existing community implementation, and record why general dialogue migration was rejected.

#### Exit gate

- One full community arc is playable from a fresh save and every supported legacy fixture.
- All three authored actions produce the same intended committed outcome as before.
- The persistence restriction and deterministic restart-from-first-node policy pass at every stage.
- No duplicate domain effect or reward is possible.
- The decision-gate comparison is documented with actual files, LOC, tests, and authoring steps.

#### Rollback

The pilot dialogue sequence and presentation path remain data-gated until the decision gate passes. The existing community service/button path remains available during development.

---

### Phase Q4 — Content tooling and selective engineering guardrails

**Purpose:** Make authored data failures easy to catch while supplementing, not weakening, the existing CI baseline.

#### Work

1. Add a headless content-validation entry point that reuses the production validators rather than reimplementing schema rules in a separate language.
2. Integrate quest and dialogue validation into the existing repository validation/test flow.
3. Add a contributor-facing report containing:
   - invalid definitions,
   - duplicate IDs,
   - missing references/localization keys,
   - unsupported schema versions,
   - unreachable dialogue nodes,
   - quest definitions that require a newer save schema,
   - handwritten GDScript files over policy thresholds.
4. Add an advisory pre-commit configuration for:
   - merge-conflict markers,
   - malformed JSON,
   - project naming conventions,
   - oversized newly added handwritten files,
   - repository/content validation.
5. Trial `gdformat` and `gdlint` on a non-mutating branch.
6. Configure exclusions for generated, imported, third-party, scene/resource, and asset files.
7. Do not make formatting/lint blocking until a clean repository-wide report exists and Q2 is stable.
8. Preserve the exact target-engine Godot 4.7.1 tests, editor import, smoke, and Windows export preflight as authoritative gates.
9. Do not enable Git LFS during this work. Reconsider only when a required tracked binary exceeds normal Git review/storage limits and clone/CI/export behavior has been validated end to end.
10. Add concise contributor documentation with the exact local commands and expected success output.

#### Exit gate

- A fresh contributor setup can validate content without modifying production files.
- Runtime and CI use the same authoritative quest/dialogue validation rules.
- The target Godot 4.7.1 pipeline passes.
- No third-party addon, art, audio, or incompatible license is incorporated.
- Advisory tooling has no unresolved false-positive class that would block normal work.

#### Rollback

Remove the advisory workflow/configuration and documentation. Gameplay, saves, and release artifacts remain unaffected.

---
## 13. Shared automated verification

Run the baseline after every implementation slice, not only at phase completion:

```powershell
python tools/validate_repository.py
<godot-4.7.1> --headless --path . --script res://tests/test_runner.gd
<godot-4.7.1> --headless --path . --script res://tests/smoke_test.gd
<godot-4.7.1> --headless --path . --editor --quit
```

Also run the project’s existing Windows export preflight command exactly as currently documented.

### Required test layers

| Layer | Purpose |
| --- | --- |
| Validator unit tests | Reject malformed or semantically invalid quest/dialogue data |
| Evaluator unit tests | Prove deterministic matching, ordering, dedupe, and no same-event cascade for the enabled `event_once` type |
| Service unit tests | Prove state transitions, compatibility API, snapshot, restore, and signal suppression |
| Adapter unit/integration tests | Prove trusted normalization and exact bind/unbind lifecycle |
| Save migration tests | Prove schema-21 mapping, corrupt rejection, idempotence, and round trips |
| Interaction integration tests | Prove explicit delivery, rollback/preflight, and lantern completion; Mahjong result integration is deferred until a real objective enables it |
| UI tests/manual checks | Prove projection, focus, keyboard/controller parity, and accessibility settings |
| Vertical-slice integration | Prove fresh-game and legacy-save completion paths |

### Manual phase checklist

For each phase that changes runtime behavior:

- Fresh save.
- Immediately prior supported schema fixture.
- Two consecutive save/load cycles.
- Save/load at each changed objective boundary; for Q3 dialogue, verify save restriction while open and load from each prior committed community stage.
- Keyboard-only navigation.
- Controller-only navigation.
- Device switch during tracker/dialogue use if currently supported.
- Reduced motion enabled.
- At least two dialogue-speed settings.
- Cancel/back behavior.
- Repeated/rapid confirm input.
- Scene transition, service replacement during new game, and restore reuse.
- Completion followed by another save/load to check exactly-once effects.

---

## 14. Risk register

| Risk | Failure mode | Mitigation / required evidence |
| --- | --- | --- |
| Same event advances multiple stages | One interaction skips required content | Freeze active objective set before evaluation; at most one stage transition per event; unit test |
| Duplicate signal bindings | Progress or rewards occur twice after restore | Session-scoped adapter; deterministic unbind/rebind; two-cycle integration test |
| Invalid content silently accepted | Quest becomes impossible or progresses incorrectly | Fail-closed validator with JSON-path diagnostics in development and CI |
| Stage IDs reordered or renamed | Old saves restore to the wrong objective | Immutable stable IDs, `legacy_stage` map, definition version, explicit migration |
| Inventory removed but event rejected | Player loses items without progression | Atomic transaction receipt plus rollback or approved preflight-and-commit design |
| Possession treated as delivery | Items disappear or quest skips intent | Separate `inventory.changed` and `inventory.delivered`; acceptance test |
| Restore replays side effects | Duplicate rewards, milestones, feedback, autosaves | Restore signal suppression and final projection refresh only |
| Rejected restore partially mutates live state | Load reports failure but leaves mixed old/new services | Validate before assignment; characterize session-wide restore; stage or roll back if semantic failure can leak partial state |
| Dialogue terminal commits twice | Duplicate community progress, relationship delta, or helper assignment | Input lock, expected-action revalidation, exactly-once coordinator test |
| Save/load occurs during an unpersisted sequence | Load or later restore repeats an ambiguous partial presentation | Scoped persistence restriction with guaranteed release on cancel, teardown, and commit |
| Objective save grows without bound | Save bloat/corruption risk | Persist only active non-derivable progress; bound dedupe IDs by target; discard completed records |
| UI mutates quest state | Tracker becomes another progression path | Read-only projection object/API; no mutation methods exposed |
| Lint rollout disrupts feature work | Large unrelated diffs or blocked CI | Advisory trial only; no auto-mutation; exclude non-source files |
| Community pilot expands into branching/property work | Linear pilot becomes a new narrative engine | Fixed Mayor Bell boundary, data gate, decision gate, and separate ADR for any branching follow-on |

---

## 15. Delivery slices and PR boundaries

Each row should land as a narrow branch/PR with no unrelated changes.

| Slice | Scope | Runtime behavior change? | Required evidence |
| --- | --- | --- | --- |
| Q0-A | Caller inventory, state diagrams, save fixture inventory, LOC report | No | Discovery document |
| Q0-B | Characterization tests and schema-21 fixtures | No | Baseline test output |
| Q0-C | ADR, objective schema, evaluator prototype tests | No | ADR and passing prototype tests |
| Q1-A | Definition validator and diagnostics | No authored quest migration | Unit tests and invalid fixtures |
| Q1-B | Pure evaluator and event result contract | No authored quest migration | Event/order/dedupe tests |
| Q1-C | `QuestService` facade integration and projection API | Internal only | Compatibility and snapshot/restore tests |
| Q1-D | Session-scoped adapter lifecycle | Internal only | New-game service replacement, restore reuse, and double-bind tests |
| Q2-A | First Lantern objective data and migration mapping | Yes, data-gated | Content validation and stage-map tests |
| Q2-B | Explicit delivery/lantern coordinator changes | Yes | Transaction and integration tests |
| Q2-C | Tracker/journal UI | Yes | Keyboard/controller/accessibility evidence |
| Q2-D | End-to-end saves, rewards, autosave, release checkpoint | Yes | Acceptance matrix and manual checkpoint |
| Q3-A | Mayor Bell linear pilot characterization | No | Three-action/effect/save diagram |
| Q3-B | Linear dialogue schema, validator, runner, and persistence restriction | Data-gated | Graph, input, cancellation, and restriction tests |
| Q3-C | Mayor Bell presentation migration | Yes, data-gated | Full action/relationship/helper/schedule matrix |
| Q3-D | Before/after decision-gate report | No new behavior | LOC, authoring, tests, save comparison |
| Q4-A | Shared content validation command/report | No gameplay change | Fresh-clone validation evidence |
| Q4-B | Advisory pre-commit/lint trial | No gameplay change | False-positive report and CI evidence |

Every PR must include:

- affected save schema,
- files changed and responsibility summary,
- handwritten file LOC report,
- automated command output,
- manual player checkpoint when applicable,
- migration and rollback note,
- confirmation that no third-party source/assets were added.

---

## 16. Implementation-agent rules

1. Inspect the repository before editing and update Q0 documentation with actual paths and APIs.
2. Do not invent a service method because this plan uses a conceptual name; adapt to the existing architecture or document the required addition.
3. Add failing characterization or contract tests before changing existing behavior.
4. Make one responsibility change per slice.
5. Preserve existing methods, signals, externally read state, and serialized data until the relevant phase explicitly permits migration.
6. Do not delete working behavior merely to make new tests pass.
7. Do not weaken assertions, skip tests, or convert errors to warnings without an ADR update.
8. Do not add a global event bus.
9. Do not let scene scripts write objective progress directly.
10. Do not let objective evaluation call domain services.
11. Do not place arbitrary side-effect commands in JSON.
12. Keep production GDScript below 300 LOC wherever a safe split exists; record the rationale for any exception before merge.
13. Run the full baseline after each slice and record pre-existing failures separately.
14. Avoid drive-by formatting and unrelated renames.
15. Stop a phase at its exit gate. Do not begin the next phase while required evidence is missing.
16. Do not wire reserved `mahjong.won` or `story.choice` runtime sources until a separately approved objective or branching pilot needs them.

---

## 17. Expansion checklist after the pilots

A remaining linear community arc may migrate only when its own PR includes:

- current state diagram,
- stable arc/action/sequence/node IDs,
- domain effect ownership map,
- legacy save fixtures,
- dialogue data validation,
- ordered-action and cancellation tests,
- exactly-once reward/effect tests,
- keyboard/controller/accessibility checks,
- before/after scene-specific code comparison,
- rollback/data-gate procedure.

Ordinary linear-arc migration should require data, fixtures, and thin coordination only. If each new arc requires new runner or coordinator logic, stop expansion and revise the contract rather than accumulating special cases.

A branching or property-affecting flow may not use this checklist as approval. It requires a separate ADR, stable choice IDs, explicit domain-effect ownership, a schema/save decision, every-branch fixtures, cancellation/restore tests, and exactly-once property/relationship/reward evidence.

---

## 18. Explicit non-goals

- Replacing Six Brands Mahjong with classical RPG combat or a PaperTown-style QTE battle loop.
- Converting free overworld movement to OpenRPG’s grid gameboard model.
- Rebuilding the project in Godot RPG Creator or using its alpha toolchain in production.
- Replacing the current save service, scene-owned HUD architecture, content registry, or every community arc in one migration.
- Building a general-purpose visual-novel engine, node editor, scripting language, or arbitrary quest expression system.
- Copying donor-project source, art, audio, vendored add-ons, or third-party assets without separate license and provenance review.
- Enabling Git LFS without a demonstrated repository need and end-to-end validation.
- Adding optional objective types, loops, timers, procedural quest generation, multiplayer replication, or localization tooling beyond what the two pilots require.
- Claiming support for branching dialogue, property choices, or exact mid-sequence save/resume based solely on the linear Mayor Bell pilot.

---

## 19. Delivery order

```text
Q0 -> Q1 -> Q2 -> Q3 -> Q4
```

Q4’s non-mutating tooling trial may begin after Q0, but it must not become a blocking merge condition before the Q2 gameplay pilot is stable.

The migration is considered complete only when Q2 passes. Q3 and Q4 determine whether the pattern is suitable for wider narrative adoption and contributor use; they must not destabilize the working First Lantern implementation.
