# Hybrid Vertical Slice

## Strategy

Build complete architecture and data boundaries for the full project while fully authoring only a narrow playable slice. This prevents disposable prototype code without pretending all seven regions and eleven stories are finished.

## Fully playable content

- Wayward Farm
- Dustward
- First river or coastal fishing location
- Three interiors
- Three Mahjong opponents
- One substantial NPC storyline
- First Six Brands Hall restoration milestone
- Four crops for the first playable pass, with all supplied crops cataloged for later activation
- Six to eight fish
- One horse color in active use, with all colors cataloged
- Clear and rainy weather
- Day/night cycle
- Save/load
- Keyboard and controller support

## Mahjong scope

- Complete Trail Rules domain model
- 11-tile hands
- Four-hand match plus tie Showdown
- Orange and Blue player Brands
- NPC primary and secondary Brand loadouts
- Brand charge reset per hand
- High Noon declaration
- Deterministic match seed and replay log
- Tenderfoot tutorial
- First pass of fixed-personality AI

## Cozy scope

- Free-grid farm placement with navigation safety
- Plant, water, wilt, recover, die, and harvest loop
- Basic animal care foundation
- Shipping crate and direct shop selling
- Fishing cast, hook, directional struggle, tension, escape, and catch presentation
- Horse replacement travel and hitching-post fast travel
- NPC schedules and no permanently missed events

## Foundation order

1. Repository and legal structure
2. Asset verification and import tooling
3. Project settings and input foundation
4. Doc movement and interaction
5. Time, weather, and save services
6. Trail Rules domain implementation
7. Orange and Blue Brand implementation
8. First opponent and tutorial
9. Farm placement and crop loop
10. Fishing state machine and overlay
11. Horse travel
12. First connected maps and interiors
13. NPC schedule, quest, and helper integration
14. Hall restoration milestone
15. Windows export validation

## Definition of done

The slice is complete when a new player can begin at Wayward Farm, move through a connected town route, tend crops, fish, challenge and defeat three distinct opponents, progress one character story, restore the first hall section, save and reload safely, and continue without encountering a fake or disconnected system.
