# Quest Objective Contract

**Decision:** Accepted for Q1/Q2
**Save schema:** 21 (unchanged)
**Pilot:** The First Lantern

## Decisions

- Keep the existing `QuestService` methods, signals, state dictionaries, numeric stage persistence, rewards, and schema-21 save shape through Q2.
- Add one declarative objective type, `event_once`, with exactly one irreversible objective per authored schema-21 stage. Multiple partial objectives and cumulative counts require a later save-schema ADR.
- Use a closed, version-1 event envelope. Q1/Q2 enable `interaction.completed`, `inventory.changed`, and `inventory.delivered`; dialogue, Mahjong, and story-choice kinds remain reserved and fail closed.
- Keep the objective evaluator pure. It receives copied definitions/events and returns matching objective IDs; it owns no Nodes, inventory, rewards, saves, UI, or domain calls.
- Bind domain signals with one session-owned `QuestEventAdapter`. Rebinding disconnects old services first. Scenes may submit named interactions through the adapter but do not calculate generic progress.
- Keep inventory possession observational. `inventory.changed` replaces live projection counts and can never consume items or satisfy First Lantern delivery.
- Authenticate `inventory.delivered` with an inventory-owned atomic batch receipt. The adapter observes the batch-removal signal, authorizes that receipt once, and rejects invented or replayed receipts. Unexpected quest rejection rolls the open inventory transaction back.
- Stage the complete candidate session before committing a restore. A semantic failure frees the candidate and leaves the live session unchanged. A successful commit emits `session_replacing`, swaps services, rebinds the adapter/presenter, then emits the existing restore notifications.
- Host the compact tracker in `player.tscn` as a reusable `CanvasLayer`. The tracker consumes copies from `QuestJournalPresenter`, has no quest mutation reference, uses no focusable controls, and is recreated with the player on scene transitions.
- Do not vendor a quest/dialogue addon. The required contract is smaller than a general quest or visual-novel framework and must retain existing project ownership boundaries.

## Ownership and transaction order

```text
confirmed interaction / selected delivery
  -> owning domain operation commits
  -> stable event/transaction receipt
  -> QuestEventAdapter validates trust and normalizes
  -> QuestService validates and captures active stages
  -> pure evaluator matches captured objectives only
  -> QuestService commits at most one transition per quest
  -> read-only projection refresh
  -> existing coordinator applies completion effects
  -> autosave after all mutations settle
```

`QuestService` remains the owner of active/completed records, the Mabel reward flag, and the `first_lantern` Hall milestone. `InventoryService` owns counts, batch preflight, atomic removal, receipt creation, commit, and rollback. `FirstLanternCoordinator` owns the ordered Mabel assignment, Silas evidence discovery, and post-completion autosave call. The evaluator owns none of those effects.

## Event envelope and results

Every event contains exactly `contract_version`, `event_id`, `kind`, `source_id`, and `payload`. Stable IDs use lowercase ASCII letters followed by lowercase letters, digits, `.`, `_`, or `-`. Committed events require an ID; replacement state reports require an empty ID. Payloads admit only stable scalar/container values and reject Objects, Nodes, Resources, Callables, expressions, commands, and unknown fields.

Submission results are `PROGRESSED`, `STAGE_COMPLETED`, `QUEST_COMPLETED`, `ACCEPTED_NO_PROGRESS`, `DUPLICATE`, `REJECTED_INVALID`, `REJECTED_NOT_ACTIVE`, and `REJECTED_OUT_OF_ORDER`.

Application order is fixed: normalize/deep-copy, authenticate delivery if applicable, deduplicate, capture every active quest's current stage, evaluate only that capture, commit progress and at most one transition, record the event ID, then emit signals. A newly activated stage is never evaluated against the same event.

## Definition and diagnostic contract

Objective definitions use `objective_schema: 1`, a positive `definition_version`, ordered stages with immutable `id` and `legacy_stage`, `completion_mode: all`, and one `event_once` objective. Match fields are restricted by event kind. Legacy definitions without objectives remain valid.

Diagnostics are dictionaries containing `source`, `path`, and `message`. Paths use JSON notation, for example:

```text
data/quests/vertical_slice_quests.json $.quests[0].stages[2].objectives[0].match.interaction_id
```

Invalid definitions are not registered. Startup logs every actionable diagnostic and leaves the invalid quest unavailable rather than partially playable.

## Persistence and restore

Schema 21 remains sufficient because each objective immediately and irreversibly maps to one existing numeric stage transition:

| Numeric stage | Stable stage | Next intentional action |
| ---: | --- | --- |
| 0 | `meet_mabel` | Acknowledge Mabel's introduction |
| 1 | `gather_provisions` | Select and deliver one bean and one eligible fish |
| 2 | `light_lantern` | Complete the lantern interaction |

Inventory counts remain authoritative in `InventoryService`; runtime dedupe and trusted open receipts are not serialized. Restoring a stage is sufficient to reject an earlier action as out of order. Restore emits no progression, completion, reward, feedback, or autosave signal; `QuestService.restore` emits one projection refresh after assignment.

Stable quest, stage, objective, event target, delivery, item, and transaction IDs are serialized or replay contracts. Renaming one after release requires an explicit migration.

## Compatibility and future boundary

Legacy `advance` remains valid only on legacy stages and returns `ERR_UNAVAILABLE` on event-owned stages. Existing `start`, `is_active`, `stage`, `stage_count`, `complete`, `requirement_count`, `snapshot`, `restore`, legacy signals, and externally read dictionaries remain available.

This ADR does not approve `event_count`, latched possession objectives, Mahjong wiring, dialogue sequences, story choices, branching, or schema 22. Those require their phase-specific decision and persistence evidence.
