# Handwritten File-Size Policy

Project-owned handwritten files should stay below 300 lines where practical and safe.

## Thresholds

- Preferred range: 80–220 LOC
- Review warning: 250 LOC
- Soft maximum: 300 LOC

## Rules

1. Split by responsibility, not by arbitrary line ranges.
2. Do not fragment cohesive logic when the split would increase coupling or reduce reliability.
3. Keep public interfaces narrow and explicit.
4. Prefer data resources over repeated conditional logic.
5. Prefer small services, state objects, evaluators, and coordinators over large manager classes.
6. Record justified handwritten exceptions in `size_exceptions.md`.

## Exclusions

The limit does not apply to:

- Generated files
- Third-party source
- Godot-generated scene and resource text
- Machine-generated manifests
- Large declarative tables that are safer as data

## Planned Mahjong boundaries

Examples include:

- Tile definition
- Wall builder
- Hand state
- Trail Rules validator
- Frontier Rules validator
- Claim resolver
- Deed evaluator
- Renown calculator
- Brand loadout
- Brand charge tracker
- High Noon state
- Match flow
- Replay log
- AI memory
- AI evaluator
- AI action selector

Farming, fishing, dialogue, schedules, placement, saves, and world streaming follow the same principle.
