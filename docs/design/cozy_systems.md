# Cozy Systems

## Time and schedules

- One complete game day lasts about 60 real-time minutes before pauses
- Time advances naturally during movement, farming, fishing, and ordinary indoor activity
- Time pauses during dialogue, menus, Mahjong, and cutscenes
- A full Mahjong match consumes 90 in-game minutes
- Important events never disappear permanently
- NPCs follow daily schedules and may require specific times, locations, weather, friendship, or story access before accepting challenges
- Doc may remain outside all night without punishment
- Inns provide sleep away from the farm
- Resource-built bonfires allow sleep, cooking, and saving anywhere outside town

Initial weather:

- Clear
- Cloudy
- Rain
- Thunderstorm
- Dry wind or dust
- Rare supernatural fog

There is one launch season. Weather affects crop care, fish tables, NPC schedules, animal behavior, ambience, parallax, and clearly displayed table conditions.

## Farming

Wayward Farm supports free grid placement for fields, paths, fences, decorations, machines, barns, coops, pens, and most constructed buildings. The farmhouse remains fixed.

Placement validation rejects:

- Invalid terrain
- Overlapping footprints
- Blocked doors or exits
- Sealed map transitions
- Unreachable animal areas
- Occupied water
- Permanent story objects
- Layouts that completely prevent scheduled NPC navigation

Large structures can be relocated later through a dedicated mode.

All crops in the supplied animated crop package may be used. Crops wilt after neglect, recover after watering, and die only after several neglected days. Quality reflects watering, fertilizer, weather, and harvest timing.

Tools do not use durability. They receive permanent upgrades.

## Animals

Launch animals are determined by the supplied ranch and cozy packs. Animals:

- Have individual names
- Age over time
- Reproduce
- Track happiness and product quality
- Retire to a pasture instead of dying on-screen
- Produce less as they become elderly

Pasture and NPC helpers reduce daily maintenance so animal care does not become a mandatory morning checklist.

## Processing and economy

Supported systems include:

- Kitchen and cooking
- Preserves
- Grain and flour processing
- Cheese and butter
- Smoked fish
- Bait crafting
- Animal feed
- Nonalcoholic tonics
- Saloon recipes

Goods may be sold through the farm shipping crate, sold directly to shops, supplied through posted orders, or negotiated through Mahjong. Money and table tokens are separate currencies. Mahjong is one balanced income source rather than the dominant economy.

Prepared food can modify world activity, fishing tension, crop quality, relationship gains, or initial Brand charge. Effects must remain clear and bounded.

## Helpers

After defeat and relationship progress, NPCs provide both permanent bonuses and active assistance. Help can be requested directly or assigned from the farmhouse board.

Examples:

- Water one field
- Feed one animal group
- Process a batch
- Deliver goods
- Reveal rare-fish conditions
- Improve store inventory
- Repair structures
- Identify high-quality produce
- Unlock a fast-travel or property route

## Fishing

The fishing interface overlays one side of the full world view. The shoreline remains visible with Doc, bobber motion, fish shadows, line direction, obstacles, weather, time, and contest spectators.

Recommended controller mapping:

- Left stick — counter the fish's pull
- Right trigger — reel
- Left trigger — release tension
- A / Cross — set hook or perform a short pull
- Right stick — adjust rod angle
- Vibration — bite, struggle, low tension, and dangerous tension

Fishing phases:

1. Aim and cast
2. Detect the bite through animation, sound, and vibration
3. Set the hook
4. Directional tug-of-war with line tension
5. Catch presentation and record update

Fish vary by location, time, weather, bait, lure, rod, hook, and line. Fish can be sold, cooked, gifted, collected, used in quests, used as wagers, released, or converted into bait.

On beginner difficulty, failure may cost only time. Higher settings may also consume bait, hook durability, lure durability, or occasionally break the line. Boat fishing is expansion content.

## Horse travel

The launch implementation does not require a mounted Doc sprite:

1. Doc approaches the horse
2. A short fade plays
3. Doc is replaced by the selected horse animation
4. Travel speed increases
5. Discovered hitching posts enable fast travel
6. Dismounting restores Doc at a valid navigation point

Five horse colors are currently available.

## Saving and accessibility

Save system:

- Six manual slots
- One autosave
- One rotating emergency backup
- Save outside Mahjong matches, cutscenes, and the final draw sequence
- Autosave on waking, entering major regions, completing quests, finishing Mahjong, and confirming major construction
- Recovery support for damaged or incompatible saves

Baseline accessibility:

- Fully remappable keyboard and controller input
- Xbox, PlayStation, and generic glyphs
- Text size and dialogue-speed options
- Hold/toggle alternatives
- Brand symbols and patterns for color accessibility
- Reduced flash and screen shake
- Fishing assists
- Independent Mahjong hint level
- Faster or skipped repeated table animations
- Pause in any single-player sequence
- Separate music, ambience, SFX, callout, and UI volume
- Windowed, borderless, and fullscreen display
