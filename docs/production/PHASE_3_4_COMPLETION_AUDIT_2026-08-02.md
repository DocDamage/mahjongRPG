# Phase 3–4 completion audit

**Scope:** Four-Brand mastery and Frontier Rules on the P1–P2 playable foundation.

## Delivered player path

1. Complete First Lantern, then speak to Mabel for the Hall cleanup ledger.
2. Win a Trail Rules rematch against River Rose for Green, Dynamite Bill for Pink, and Mayor Bell for Dark.
3. The third victory completes cleanup, unlocks Purple, grants access to the Hall's real Frontier table, and allows any two of the six unlocked Brands to be selected.
4. Spend earned, bounded upgrade points in the loadout picker. Brand ranks, selected loadout, mastery wins, Hall stage, rulesets, and discovered Deeds persist in schema 9.
5. Play either the existing Trail table or Frontier Rules. Frontier uses a deterministic 136-tile wall, fourteen-tile hands, public quad claims/replacement draws, explained Deeds/Renown, assistance modes, and deterministic replay event/hash feedback.

## Code and automated evidence

| Requirement | Evidence |
| --- | --- |
| Data-backed Brand definitions, Green/Pink/Dark/Purple mastery and upgrades | `data/brands/six_brands.json`, `BrandLoadoutState`, `test_brand_mastery.gd` |
| Four new powers and Green/Pink claims | `brand_power_resolver.gd`, `claim_resolver.gd`, `test_six_brand_powers.gd`, `test_brand_claims.gd` |
| Complete Frontier structure and quads | `match_ruleset.gd`, `frontier_hand_validator.gd`, `wall_builder.gd`, `test_frontier_rules.gd` |
| Deeds/Renown, replay hashes/explanations, knowledge-boundary AI | `deed_evaluator.gd`, `match_replay_log.gd`, `match_replay_explainer.gd`, `frontier_ai.gd`, dedicated tests |
| Hall stage 2 and player entry | `hall_frontier_table.gd`, `six_brands_hall.tscn`, `hall_foreman.gd` |
| Save continuity | Schema 9 `session_snapshot_migrator.gd`, `test_phase_three_four_migration.gd` |

On 2026-08-02, `python tools/validate_repository.py`, the Godot 4.7.1 native runner (**39 suites**), runtime smoke, and headless editor initialization passed. The remaining evidence gates are manual: keyboard/controller-only walkthroughs, two save/load cycles through the new loop, display/audio sanity, and the player-performed Trail/Frontier checkpoints. Those must not be represented as automated completion.
