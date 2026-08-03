# Six Brands at High Noon 1.0.0-rc.1

## Release candidate scope

This Windows release candidate (distribution label `1.0.0-rc.1`; Godot numeric project version `1.0.0`) completes the P17 presentation pass and P18 release tooling for the current playable game: all seven regions, eleven opponents, six Brands, Trail and Frontier Rules, ten community arcs, Texas King, four endings, and postgame.

## Player-facing release changes

- The postgame Hall ledger now exposes one concise journal covering evidence, Brands, fish records, community arcs and secrets, property cases, and desert records.
- Portrait cards declare steady, determined, and warm expression coverage for every authored community resident.
- The runtime catalog now verifies title/pause UI art, hero action sheets, horse colorways, and the Mahjong face atlas.
- Keyboard/controller prompts can expose Xbox, PlayStation, or family-neutral glyph labels. No critical prompt depends only on a color, sound, vibration, mouse, or rapid response.
- Accessibility adds persistent relaxed fishing timing, high-contrast preference, and a vibration toggle. Relaxed timing expands the fishing hook window by 75%; vibration is always optional.
- The audio catalog has keyed UI, journal, farm, fishing, Mahjong, finale, credits, ambience, and music entries using tracked runtime assets.

## Compatibility and rollback

- Save schema: forward migration from schemas 1–21 to current schema 21. There is no P17/P18 gameplay-save bump.
- Settings schema: configuration schema 1 migrates to schema 2, retaining prior controls and adding safe defaults for timing, contrast, and vibration.
- Rollback: retain the prior P16 package and a copy of `%APPDATA%\Godot\app_userdata\Six Brands at High Noon\saves`. Older builds are not expected to read newer files, but this release does not alter the game-save schema.

## Legal and credits decision

The package includes the supplied CC0/fallback asset-license notice and the proprietary-source notice. The included credits screen contains the current game credit lines; no additional asset attribution is required by the supplied license. Do not represent the game source as open source unless the proprietary notice is replaced by an authorized license.

## Known release gates

Automated regression, resource, export, package, corrupt-save, and isolated-profile launch evidence is recorded in `release_candidate_evidence.md`. A physical clean-Windows-machine install and the controller/display/accessibility matrix still require a human tester with the target hardware; they must be signed off before public distribution.
