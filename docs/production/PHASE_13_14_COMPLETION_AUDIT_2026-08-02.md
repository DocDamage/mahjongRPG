# Phase 13–14 completion audit

## Scope and result

P13–P14 are implemented as two save-compatible playable loops. `PublicLifeService` owns public rank, property contributions, event phases, and Hall milestones; `ActThreeService` owns the investigation chain and finale-readiness state. The existing `GameSession` remains a composition root rather than a new cross-domain manager.

| Requirement | Evidence |
| --- | --- |
| Full public property loop | Six stable property IDs now carry outcomes and public contributions. Existing civic/dock/desert cases remain valid; the Hall ledger adds Bridlewood water, Gull's Rest mooring, and Market Charter proof turn-ins. |
| Rank, events, and Hall stages 4–5 | Persisted rank points, event states, contributions, and Hall milestones drive Market Day, a reschedulable event day, the reopening, and stages 4–5. |
| Real town tournament | A scheduled Town Tournament opens a dedicated Frontier Rules table. Its event can only complete from the table's `match_closed` win signal; losing leaves the schedule intact for retry/reschedule. |
| Final championship safety | The championship can be scheduled only after the legendary reopening and community support. It is never attended or started in P13/P14. |
| Act III evidence chain | The Wayward inheritance deed plus First Lantern, Bridlewood, Saint's Landing, Ironhook, Gull's Rest, and Red Testament evidence must validate before the bargain record appears. |
| Consequences and rule clarity | Exactly one saved investigation consequence is accepted. All three altered rules have named evidence requirements and player-facing explanations. |
| King's Reach and safe stopping point | Proving Silas alive unlocks the Red Testament route to King's Reach. The gate, sealed study, and watchtower are saved exploration sites; the final warning needs all three, community support, and a scheduled championship. |
| Save continuity | Schema 18 creates safe empty P13 public-life state; schema 19 creates safe empty P14 story state while preserving P13 records. Round trips plus pre-P13/pre-P14 migration cases are automated. |

## Automated evidence

- `python tools/validate_repository.py`
- Godot 4.6.2 local runner: 44 suites, including `test_phase_thirteen_fourteen.gd`
- runtime smoke test
- headless editor initialization

The target Godot 4.7.1 and P13/P14 physical player checkpoints remain manual evidence gates. This audit does not claim those external/manual gates are complete.
