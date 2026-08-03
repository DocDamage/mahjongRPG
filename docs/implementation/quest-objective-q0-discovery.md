# Q0 Quest Objective Discovery

**Grounded:** 2026-08-03
**Baseline commit:** current `HEAD` before Q1/Q2 work
**Outcome:** Q0 exit gate passed; schema 21, staged restore, receipt-backed delivery, and player-owned tracker selected.

## Existing quest surface and callers

Before the objective work, `src/quests/quest_service.gd` owned `definitions`, `active`, `completed`, numeric `progress`, `unlocked_helpers`, and `hall_milestones`. Its signals were `quest_started`, `quest_progressed`, and `quest_completed`; its snapshot stored the five mutable state dictionaries without a separate objective record.

Repository caller inventory:

| Surface | Callers before migration |
| --- | --- |
| `start`, `is_active`, `stage`, `advance`, `complete`, `requirement_count` | `src/story/hall_foreman.gd`; quest unit/integration tests |
| `stage_count`, `snapshot`, `restore` | `QuestService` internals, `GameSessionSnapshot`, quest tests |
| `completed` | Hall foreman, Dustward status, Hall frontier table, game-session tests |
| `unlocked_helpers`, `hall_milestones` | progression tests; `scene_exit.gd` reads the milestone |
| `quest_completed` | Hall foreman and `wayward_farm.gd` |
| `quest_started`, `quest_progressed`, `active`, `progress` | no production caller outside `QuestService`; tests/save data read state |

No wrapper or indirect quest mutation path was found. `CommunityArcService` is separate and remains out of Q1/Q2.

## First Lantern before migration

The catalog already contained exactly three ordered stages: `meet_mabel`, `gather_provisions`, and `light_lantern`. Schema-21 saved the active numeric stage in `quests.progress`.

```text
inactive
  -- interact Mabel: start + manual advance --> stage 1 gather
  -- own bean + fish, interact Mabel:
       remove one bean + first dictionary fish + manual advance --> stage 2 light
  -- interact Mabel: QuestService.complete
       -> quest reward flags
       -> HelperService.assign(mabel)
       -> EvidenceService.discover(silas_first_lantern_note)
       -> SaveService.autosave(quest_completion)
       -> feedback
```

Possession was checked in `hall_foreman.gd`; the same scene automatically chose the first fish and performed two independent removals. `InventoryService` had no batch API, receipt, or rollback. Q2 intentionally replaces only that automatic choice with an explicit selection/confirmation transaction.

Reward/effect ownership was already split: `QuestService.complete` wrote completed/reward/milestone state; Hall foreman assigned the operational helper, discovered evidence, emitted completion feedback, and requested autosave. That ownership is preserved.

## Save and restore facts

- `GameSession.SAVE_SCHEMA_VERSION` is 21.
- `SessionSnapshotMigrator` adds an empty quest record only for schema 2 and older; no schema-21 objective migration existed or is needed.
- `QuestService.restore` previously assigned `active`, `completed`, and `progress` before all stage validation finished, so a rejected restore could mutate live state.
- `GameSessionSnapshot.restore` previously restored services sequentially and checked cross-service invariants afterward. A later semantic failure could therefore leave earlier live services mutated.
- Q0 selected full candidate-session staging. `GameSessionSnapshot.stage` restores and cross-validates isolated services; only `commit` swaps live references.
- Fixtures now cover schema-21 First Lantern stages 0, 1, 2, and completed state. Numeric JSON values are accepted only when integral and in range.

## Session, inventory, UI, dialogue, and Mahjong facts

- `GameSession.start_new_game` replaces inventory, quest, and dependent services. Restore now also replaces staged service objects. The session-owned `QuestSessionRuntime` deterministically unbinds and rebinds its adapter/presenter for both paths.
- Scene changes do not replace `GameSession`, so the adapter survives without scene subscriptions. A player scene owns one tracker instance; the old instance is freed with the outgoing player.
- Existing world feedback is a scene-owned label (`interior.gd` and regional scene scripts). The player already owns an interaction-prompt `CanvasLayer`; `player.gd` was already above the review threshold, so the tracker is a separate script/child rather than more player code.
- `SaveService` already had reference-counted save restrictions but load did not honor them. Q2 makes load return `ERR_BUSY` while a provision/dialogue-style modal restriction is active.
- `DialogueCatalog` provides localized lookup and `CommunityPortrait` provides drawing, but there is no modal authored sequence runner. Q1/Q2 correctly use `interaction.completed`; dialogue work remains Q3.
- Mahjong presentation exposes `mahjong_table.gd::match_closed(winner)` and presentation-owned calls to `BrandLoadoutState.record_match_win(opponent_id, ruleset)`. There is no stable persisted `match_id`; no `mahjong.won` adapter is wired.

## Mayor Bell characterization for the later Q3 gate

Mayor Bell remains a three-action linear community arc in `data/community/community_arcs.json`: `meet`, `favor`, `resolve`, each with relationship delta `+1`. `CommunityArcService.advance` records stable choice IDs `mayor_bell_<action>`, advances numeric state, assigns helper `mayor_bell` on resolution, and emits its arc signals. The home scene uses `community_landmark.gd`, which simply submits the expected action and displays the returned text. `OpponentSchedule.state` selects `resolved_activity` after `CommunityArcService.is_completed` becomes true. There is no property mutation or branch in this arc.

## Baseline and file-size inventory

Pre-change handwritten LOC:

| File | LOC | Finding |
| --- | ---: | --- |
| `src/core/game_session.gd` | 286 | already at review threshold; quest composition extracted |
| `src/player/player.gd` | 258 | already at review threshold; tracker added as child component |
| `src/mahjong/presentation/mahjong_table.gd` | 234 | inspected only; no Q1/Q2 wiring |
| `src/story/hall_foreman.gd` | 82 | automatic delivery/effects owner |
| `src/quests/quest_service.gd` | 117 | compatibility state owner |
| `src/inventory/inventory_service.gd` | 86 | no atomic batch/receipt API |
| tracker host | none | selected `src/player/player.tscn` child |

The baseline repository validator passed and the pre-change native runner reported 46 suites. The PATH engine is the known-wrong 4.6.2; all implementation gates use the documented explicit Godot 4.7.1 console executable. No third-party source or assets were added.

## Mismatches resolved

The plan's suspected restore mutation was confirmed and resolved with staging. The inventory API lacked receipts/rollback, so Q2 adds both. The preferred player tracker host was viable without increasing `player.gd`. The existing First Lantern mapping exactly matched the proposed schema-21 strategy. No contradictory shipped-save or Mayor Bell branching evidence was found.
