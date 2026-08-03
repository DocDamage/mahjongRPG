# First Lantern Objective Pilot (Q1/Q2)

The First Lantern now uses one `event_once` objective for each existing schema-21 stage:

| Stage | Objective | Committed event |
| --- | --- | --- |
| `meet_mabel` / 0 | `meet_mabel` | `interaction.completed:first_lantern.meet_mabel` |
| `gather_provisions` / 1 | `deliver_selected_provisions` | authenticated `inventory.delivered:first_lantern.provisions` |
| `light_lantern` / 2 | `complete_lantern_interaction` | `interaction.completed:first_lantern.lantern` |

Delivery order is: verify the named objective; show current eligible fish; require fish selection and confirmation; atomically remove the selected fish plus one `crop_beans`; publish the receipt from `InventoryService`; authenticate and submit the delivery event; commit the inventory transaction only for a progression result; otherwise roll it back. Possession and inventory projection updates never deliver items.

Completion order is: commit the final objective and QuestService reward/milestone state; assign Mabel through `HelperService`; discover `silas_first_lantern_note`; request the `quest_completion` autosave; then show completion feedback including save status. Restore never invokes this coordinator, so effects are not replayed.

The modal delivery UI pauses world time, restricts save and load, cancels before a validated session replacement, releases every guard on cancel/confirm/teardown, starts with no fish selected, and uses ordinary focusable buttons for keyboard/controller parity. The player-owned tracker is read-only, non-color-dependent (`[NEEDED]`/`[READY]` text), focus-neutral, and refreshes through the session presenter after progress, inventory changes, restore, new game, scene recreation, and device changes.

Schema remains 21. Rollback during development is data-gated by removing `objective_schema`/objective fields and restoring the legacy Hall coordinator; production rollback must use a pre-Q2 build/save backup because shipped stable IDs must not be reinterpreted.
