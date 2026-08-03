# Pre-Playtest App-Wide Audit

**Project:** Six Brands at High Noon
**Audit date:** 2026-08-03
**Scope:** World construction, collision, character scale, story flow, gameplay depth, level coverage, props, and test readiness
**Readiness:** **62/100 — ready for internal mechanics testing, but not yet ready for a blind art, navigation, or story-flow playtest**

## Executive Summary

The underlying game systems are substantially healthier than the current presentation suggests. Repository validation, all 56 automated test suites, the runtime smoke test, content validation, Windows export preflight, and the headless performance smoke pass.

The main pre-playtest risk is that the playable world is still presented as a functional prototype. The current environments are not tile-built maps: floors, walls, roads, buildings, water, and most props are drawn as flat rectangles and lines. There are no `TileMap` or `TileMapLayer` nodes, no wall or prop physics bodies, no camera or Y-sorting setup, and no navigation layer. Players can therefore walk through visual buildings, water, props, NPC markers, and other scenery until stopped by the rectangular scene boundary.

The macro story is coherent and complete through finale and postgame, but most of it is communicated through abstract interactable markers and short HUD messages. Only **The First Lantern** is currently presented as a formal tracked quest. Before testing atmosphere, exploration, story comprehension, or world readability with outside players, the project should produce one fully presented opening route and extend quest/journal guidance across the main progression.

Internal testing of Mahjong, farming, fishing, progression state, economy, save/load, migration, and finale gating can begin now. Findings about art quality, spatial design, navigation, NPC readability, or narrative pacing should be deferred until the presentation pass described below.

## Direct Findings

| Area | Current finding | Recommendation |
| --- | --- | --- |
| Floors and walls | No world scene uses `TileMap` or `TileMapLayer`. Environments are drawn procedurally with rectangles and lines. | Build layered tile maps for ground, terrain transitions, below-player props, collision, and above-player/roof elements. |
| Collision | Player movement is limited only by per-scene rectangular bounds. Buildings, water, walls, props, and NPCs do not physically block movement. | Add tile collisions and small foot-level collisions to solid props and actors before evaluating map layout. |
| Camera and depth | There is no `Camera2D`, Y-sorting, navigation region, or occlusion setup. All maps act as fixed 960×540 screens. | Decide which scenes remain fixed screens and which scroll. Add a camera, limits, Y-sorting, and consistent depth rules to scrolling maps. |
| Hero scale | Doc uses a 64×64 animation frame and a small capsule collision shape. This is a reasonable scale for a 32-pixel logical world grid. | Keep Doc at 1× scale. Standardize world construction around 32-pixel cells, or render compatible 16-pixel source art at 2×. |
| NPC scale | Procedural NPC drawings are approximately Doc's height, but their circles and rectangles read as abstract tokens rather than characters. | Normalize NPC sprites to a 64×64 canvas, place their feet on the same baseline as Doc, and use foot-level body collision plus a separate interaction area. |
| Horse scale | Horse frames use 128×128 cells and are appropriately larger than Doc, but only a static region is currently shown. | Preserve the approximate 2:1 canvas relationship and integrate directional idle/walk/run animation before judging final scale. |
| Story structure | The broad progression from inheritance to Hall restoration, regional investigation, Texas King, four endings, and postgame is coherent. | Preserve the macro structure, but add stronger player-facing scene work, dialogue, quest guidance, and transitions. |
| Story delivery | Most later story actions are interactable markers that immediately mutate state and print one or two lines into the bottom HUD. | Turn major beats into tracked quests and staged conversations. Reserve one-line feedback for routine actions. |
| Levels | The project already contains seven regions, 29 world scenes, multiple homes/interiors, a finale, and postgame. | Do not add more levels yet. Finish and deepen the current spaces first. |
| Props | Thousands of source images are available, but decorative world props are almost entirely absent from runtime scenes. | Add region-specific, collision-aware props that establish navigation, activity, history, and atmosphere. |

## World Construction and Tile Placement

### Current state

The question is not yet whether the floor and wall tiles are placed correctly; they have not been integrated into the playable maps. Representative world scripts draw their entire environment in `_draw()` using calls such as:

- A single background rectangle for the ground
- Large rectangles for buildings, fields, water, or interior floors
- Lines for roads or paths
- Procedurally drawn rectangles and circles for interactables

The source asset library contains farm, Western town, European city, dock, fishing village, desert, interior, wall, floor, door, vegetation, furniture, and prop art. Only a small generated runtime subset is currently used for Doc, horses, Mahjong faces, audio, and a few UI decorations.

### Recommended world-layer contract

Each authored map should use a predictable layer structure:

1. `Ground` — base grass, dirt, sand, wood, stone, or water bed
2. `TerrainDetail` — paths, shoreline edges, tracks, floor transitions, shadows
3. `BelowPlayerProps` — rugs, flowers, low debris, crop ground details
4. `WorldCollision` — walls, water boundaries, cliffs, fences, solid furniture
5. `ActorsAndInteractables` — player, NPCs, doors, tools, tables, landmarks
6. `AbovePlayerProps` — roofs, tree crowns, awnings, tall foreground objects
7. `LightingAndWeather` — shadows, lantern light, rain, fog, supernatural effects

Use one canonical logical grid. A 32-pixel grid is the best fit for Doc's 64×64 frames: the character reads as roughly two tiles tall while retaining a compact foot collision area. Source tiles authored at 16×16 can be rendered at 2× using nearest-neighbor filtering. Packs with other native dimensions should be normalized deliberately rather than scaled independently per scene.

### Collision requirements

- Buildings, fences, walls, water, cliffs, heavy furniture, and large props must block the player's feet.
- Character body collision should remain near the feet rather than cover the full sprite.
- NPCs should have physical body collision separate from their larger interaction radius.
- Doors and exits should sit in visible architectural openings.
- Every required route should remain at least two logical tiles wide where possible.
- Collision should be tested with walking and running from all four directions.
- Decorative foreground art must not imply a blocked route when collision allows passage, or an open route when collision blocks it.

## Character Scale and Presentation

### Doc

Doc's 64×64 frame size is suitable and does not need to be enlarged. His current sprite offset and foot-level capsule establish the right general approach. The apparent scale problem comes from oversized abstract world regions and interactable shapes, not primarily from Doc's sprite.

### NPCs

The current procedural NPCs are close to Doc's total height but visually incompatible with him. Doc is detailed pixel art while NPCs are colored geometric symbols. This makes them read as map markers or placeholders even when their dimensions are technically similar.

Standardize every standing NPC around these rules:

- 64×64 working canvas
- Feet aligned to the same world baseline as Doc
- Comparable head-to-body proportions and pixel density
- Small body collision at the feet
- Separate 28–36 pixel interaction area
- Four directional idles where source art permits
- Walk animation for schedules and scene movement
- Y-sorting based on foot position
- Portrait, palette, and world sprite that clearly represent the same person

### Horses and animals

The 128×128 horse canvas is a reasonable match for the 64×64 hero canvas. Integrate the available directional frames and verify that the visible body occupies an appropriate footprint after the world grid is established. Animals should receive the same foot-baseline and collision treatment rather than being represented solely by abstract pen markers.

## Interaction Density and Spatial Readability

Several scenes place many interactables into one fixed screen:

- Gull's Rest: 22 `Area2D` interactables
- Six Brands Hall: 18
- Bridlewood: 18
- Wayward Farm: 15
- King's Reach: 13
- Ironhook: 12

The Six Brands Hall contains two interactables at exactly `Vector2(285, 235)`: `FrontierTable` and `ReopeningSchedule`. Other scenes contain pairs less than 50–75 pixels apart. Because Doc's interaction circle overlaps nearby areas and selects the nearest target, crowded objects can produce unclear or unintended selection.

### Required changes

- Remove the exact Hall overlap.
- Do not draw or monitor late-game actions before their relevant state becomes available.
- Replace abstract action markers with understandable objects: ledgers, notice boards, doors, tables, repair sites, crates, lanterns, maps, and NPCs.
- Combine closely related actions into a single contextual interface when they belong to the same physical object.
- Provide a visible focus or highlight for the object Doc will interact with.
- Ensure critical interactions cannot be obscured by a nearer optional marker.

## Story Flow Audit

### What works

The overall arc has a clear escalation:

1. Doc inherits Wayward Farm from missing Uncle Silas.
2. Mabel introduces Hall restoration through The First Lantern.
3. Doc learns Trail Rules and wins the early Brand matches.
4. Regional property disputes and community arcs open new territory.
5. Silas's clues converge into the supernatural bargain investigation.
6. Doc restores the Hall and unites community support.
7. King's Reach reveals that Silas survived and establishes the final rules.
8. Doc defeats Texas King, resolves the standoff, and receives one of four endings.
9. Postgame preserves prior progression and continues optional activities.

The finale is legally and mechanically counterable, failed stages retry safely, and save data preserves ending provenance. Those are strong structural decisions.

### What needs improvement

#### Opening

New Game currently begins directly on Wayward Farm. The player is not given a strong dramatic introduction to Doc, Silas, the inheritance, Mercy's Wake, or Texas King's influence.

Add a three-to-five-minute opening sequence:

1. Doc arrives at the farm or steps out of the farmhouse.
2. The player reads Silas's letter or inheritance deed.
3. One small movement and interaction tutorial establishes control.
4. A visitor, notice, or distant Hall lantern directs Doc toward Dustward and Mabel.
5. The First Lantern becomes the explicit first objective.

Replace development-facing title text such as “Demo foundation ready” with narrative or release-facing copy.

#### Main progression

Only The First Lantern is currently defined as a formal tracked quest. Later regions rely on service state, location status labels, abstract markers, and short feedback messages. This makes the underlying progression valid but difficult for a new player to reconstruct.

Add tracked act and region quests for:

- Early Hall cleanup and the three Trail Rules opponents
- Riverbend and Bridlewood access
- Saint's Landing depot dispute
- Ironhook supply run and cargo clue
- Gull's Rest tide, contest, and Silas letter
- Red Testament expedition and counter-Deed
- Community-allies requirement
- Public Hall reopening and tournament
- Converged investigation and King's Reach
- Final championship preparation

Each quest should provide a current objective, region, prerequisite, completion state, and next lead without exposing internal implementation terminology.

#### Community arcs

All ten residents have coherent three-stage outlines, but only Mayor Bell currently receives the richer authored dialogue-runner treatment. Most others can be advanced quickly from a region-level Community Journal button.

For blind testing, move the emotional content into the world:

- Require the player to meet the resident physically.
- Give each stage at least one authored conversation.
- Connect the favor stage to a small observable task or location.
- Let resolution visibly change the NPC's schedule, home, workplace, or helper behavior.
- Keep the Community Journal as a summary and navigation aid rather than the primary method of completing relationships.

#### Finale

Texas King's father reveal and Silas's return are currently summarized through feedback text. These are major emotional payoffs and require dedicated presentation:

- Pre-match conversation with Texas King
- Visible reaction to the counter-Deed and altered-rule evidence
- Standoff framing with clearly presented choices
- Father reveal dialogue and Doc's response
- Silas reunion scene
- Short ending-specific epilogue before credits
- Postgame conversations acknowledging the chosen ending

## Missing Player Interfaces

The project records substantial information but does not currently expose a complete player-facing interface for it.

### Inventory

Add a browsable inventory that shows:

- Crops, fish, animal products, crafted food, materials, and key items
- Quantity, description, value, and known use
- Quest-reserved or important items
- Equipped fishing gear
- Selective shipping, storage, and selling

The current “ship all” behavior should remain an optional convenience, not the only general inventory-disposal tool.

### Journal

Add sections for:

- Active and completed quests
- Evidence and Silas investigation chain
- Community relationships and secrets
- Properties and resolution methods
- Brands, opponents, and first-win rewards
- Fish and crop records
- Desert and supernatural records
- Finale readiness

### World map

The map should show unlocked regions, known connections, current objective region, blocked routes, discovered fast-travel points, and major services. It should not reveal undiscovered secrets.

## Gameplay Recommendations

Do not add another large game system before the existing systems receive better presentation and feedback.

### Farming

- Render actual soil and crop growth sprites.
- Add watering, planting, harvest, and wilt feedback.
- Show construction previews directly over the world grid.
- Give barns, pens, processors, paths, and expansion areas physical representations.
- Add storage and selective shipping.

### Fishing

- Use the supplied rod, prompt, gear, and catch art.
- Show a cast from Doc into the correct body of water.
- Add visible line tension and fish movement feedback in addition to meters.
- Let location, weather, time, tide, and equipment be understandable before casting.
- Add a catch card and clear record update.

### Ranching and animals

- Render individual named animals and their variants.
- Show feeding, happiness, product readiness, maturity, and breeding state in-world.
- Make repaired structures visually change.
- Give helpers visible schedules or work animations.

### Mahjong

- Preserve the existing rules, assistance, tutorial, AI profiles, wagers, replay explanation, and Brand systems.
- Add opponent-specific introductions, reactions, victory/defeat lines, and rematch context.
- Give each table and venue a distinct visual identity.
- Make first-win rewards and Hall restoration effects visible outside the result text.
- Ensure the final table's counter-Deed and declared-category logic are visually explained before play.

## Levels and Props

### Should more levels be added?

**No, not before the first polished vertical route is tested.**

The current level count is sufficient for the planned launch territory. Adding more scenes would multiply the unfinished art, collision, navigation, dialogue, and prop work. The better sequence is:

1. Finish Wayward Farm, Dustward, and Six Brands Hall.
2. Test the complete opening loop with new players.
3. Establish reusable map, collision, door, NPC, prop, and quest patterns.
4. Apply those patterns to the remaining regions.
5. Add or enlarge a location only if testing identifies a specific pacing or world-logic gap.

Existing fixed-screen maps may be expanded into scrolling maps when their activities genuinely require more space. They should not be enlarged merely to display more decoration.

### Should more props be added?

**Yes. Props are one of the highest-value improvements after tile and collision integration.**

Props should communicate purpose and direct movement:

| Region | Suggested prop vocabulary |
| --- | --- |
| Wayward Farm | Fences, gates, tools, water troughs, seed sacks, scarecrow, wood piles, farmhouse furniture, storage, crop signs |
| Bridlewood | Barn equipment, tack, hay, feed bins, animal shelters, auction board, repaired bridge states |
| Dustward | Storefront signs, hitching rails, barrels, wagon parts, porch furniture, street lamps, wanted notices |
| Saint's Landing | Stone planters, lamps, civic signs, records shelves, benches, statues, gated property markers |
| Ironhook | Cargo crates, ropes, nets, cranes, manifests, scales, barrels, smokehouse equipment, dock pilings |
| Gull's Rest | Boats, drying nets, tide markers, fish baskets, lanterns, shells, driftwood, market stalls |
| Red Testament | Ruined structures, bones, tracks, mining equipment, torn banners, supernatural lanterns, wind debris |
| King's Reach | Guard structures, sealed records, watch equipment, corrupted Hall motifs, evidence of Silas's imprisonment |
| Interiors | Beds, tables, chairs, shelves, stoves, rugs, windows, lamps, personal keepsakes, work-specific clutter |

Keep primary walkways visually clean. Use larger props as navigation landmarks and smaller props to support storytelling, not to fill every empty tile.

## Prioritized Work Plan

### P0 — Before a blind playtest

1. Establish the canonical 32-pixel logical world grid and scale rules.
2. Build finished tile, depth, and collision layers for Wayward Farm, Dustward, and Six Brands Hall.
3. Replace opening-route NPC markers with matching sprites.
4. Remove overlapping and premature interactables, especially in the Hall.
5. Add the opening sequence and release-facing title copy.
6. Add inventory, journal, and map access.
7. Track the main progression beyond The First Lantern.
8. Rebuild the Windows executable from the current source.

### P1 — Before story and content tuning

1. Apply the established environment pattern to Riverbend and Bridlewood.
2. Author dialogue and visible tasks for the remaining community arcs.
3. Integrate visual growth, fishing, animal, helper, and restoration feedback.
4. Give each Mahjong opponent a world sprite and table personality.
5. Stage the Texas King confrontation, father reveal, Silas return, and epilogues.

### P2 — After the first external playtest

1. Adjust route lengths and map dimensions using observed player behavior.
2. Add or remove props based on navigation mistakes and visual confusion.
3. Tune economy, match difficulty, fishing timing, and daily pacing.
4. Add new rooms or levels only when evidence identifies a specific missing beat.
5. Complete the physical keyboard, controller, display, accessibility, clean-install, and resume matrix.

## Recommended Testing Sequence

### Testing that can begin now

- Mahjong rules, AI behavior, wagers, retries, and Brand progression
- Farming state transitions and farm-grid constraints
- Fishing timing and equipment calculations
- Animal, trade, crafting, property, relationship, and evidence state
- Quest-objective events and persistence
- Save/load, backup recovery, schema migration, finale checkpoint, and postgame persistence
- Keyboard/controller focus behavior in implemented overlays

### Testing that should wait for the P0 presentation pass

- Tile placement and visual seams
- Spatial navigation and collision quality
- Prop density and environmental storytelling
- NPC visual readability and scale
- Region identity and atmosphere
- Blind story comprehension
- Exploration pacing
- Emotional impact of the finale

## Evidence Checked

- Project configuration and runtime entry scene
- All 29 world `.tscn` scenes and their scripts
- Player animation, collision, movement, and interaction implementation
- Runtime asset catalog and generated sprite dimensions
- Available farm, Western, city, dock, coastal, desert, wall, floor, and prop assets
- Scene transition graph and progression gates
- Quest, dialogue, community, opponent, story, finale, and postgame data
- Farming, fishing, animal, trade, construction, Mahjong, and helper presentation code
- Release documentation and pending manual-device matrix
- Current source runtime at the title screen and Wayward Farm

### Automated checks run

- `python tools/validate_repository.py` — passed
- Godot test runner — all 56 suites passed
- Runtime smoke test — passed
- Content validation — 0 errors, 5 handwritten-file size warnings
- Windows export preflight — passed
- Release performance smoke — 10 scene initializations in 1,744 ms

## Evidence Still Missing

- Full human playthrough from a clean save using current source
- Physical keyboard-only and controller-only completion
- Controller hot-plug behavior
- Display-mode and text/UI scale observation
- Rendered frame-rate and stutter testing
- Clean Windows installation and representative save/resume
- Blind-player comprehension and navigation results
- Art-integrated tile, collision, NPC, and prop testing

The pending human checks remain documented in `docs/qa/manual_device_display_matrix.md` and must not be described as passed.

## Final Recommendation

Begin internal systems testing now, but do not treat the current prototype maps as evidence that the final world layout, scale, navigation, or story pacing works. Pause additional level creation and make **Wayward Farm → Dustward → Six Brands Hall** the gold-standard opening route.

That route should establish the reusable rules for tiles, collisions, camera behavior, Y-sorting, doors, NPC scale, prop density, interaction highlighting, quest guidance, dialogue, and story presentation. Once it succeeds in a blind playtest, apply the same construction language across the remaining regions.
