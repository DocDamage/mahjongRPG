# Six Brands at High Noon
## Complete Game Implementation Plan

**Document purpose:** production roadmap for building the complete launch game after the validated hybrid vertical slice.  
**Engine:** Godot 4.7.1  
**Platform:** Windows first  
**Presentation:** top-down pixel art, 960×540 internal resolution, 48×48 world grid  
**Launch structure:** open-ended cozy RPG with a definitive story ending and continuing postgame  
**Combat:** no conventional combat in the initial release

---

# 1. Product definition

## 1.1 Core fantasy

The player is Doc, a 35-year-old cowboy who inherits Wayward Farm from his missing Uncle Silas. The farm sits outside Mercy’s Wake, a Gulf Coast frontier town in the fictional San Perdido Territory.

Poker never took hold in this town. Mahjong became the local institution for settling debts, status, property, political influence, and access to information. Texas King, an ageless outlaw and land baron, owns the legendary Six Brands Hall and has used supernatural table rules to bind much of the town to him.

The launch game combines:

- Cozy farming and ranch life
- Involved fishing
- One-on-one Western Mahjong
- NPC schedules and relationships
- Property disputes and town restoration
- Exploration and hidden interiors
- Dry comedy
- Serious Western drama
- Supernatural mystery
- A final non-gory but bloody standoff

Doc eventually learns that Texas King is his father. Uncle Silas survives the bargain and returns in the ending.

## 1.2 Primary player goals

- Develop and customize Wayward Farm
- Grow every supplied crop
- Raise, name, breed, age, and retire animals
- Catch and record fish across the territory
- Master all six Mahjong Brands
- Defeat all eleven recognized opponents
- Complete every opponent’s multi-stage storyline
- Restore all five stages of the Six Brands Hall
- Recover disputed properties and public routes
- Rescue Uncle Silas
- Defeat Texas King under legitimate rules
- Reach one of four endings
- Continue in an open-ended postgame

## 1.3 Launch boundaries

Do not silently expand launch scope to include:

- Conventional combat
- Party combat
- Additional playable heroes
- Boat fishing
- Full mounted Doc animations
- Multiple seasons
- Additional settlements
- Procedural world generation
- Online multiplayer

Architect expansion points, but do not allow deferred systems to delay the complete launch game.

---

# 2. Locked design rules

## 2.1 Tone

The tone blends:

- Dry, dark, sarcastic humor
- Friendly small-town relationships
- Serious land and family conflict
- Cozy daily routine
- Relaxed exploration
- Supernatural danger
- Some pixel blood in the finale
- No gore

## 2.2 Time

- A full day lasts about 60 real-world minutes before pauses.
- Time advances during movement, farming, fishing, and ordinary indoor activity.
- Time pauses during dialogue, menus, Mahjong, and cutscenes.
- A completed Mahjong match advances time by 90 in-game minutes.
- Doc may remain outside all night without punishment.
- Inns allow sleep away from the farm.
- Bonfires allow sleep, cooking, and saving outside town when the player has the required resources.
- Important events never become permanently missable.

## 2.3 Weather and season

Launch uses one visual season with:

- Clear
- Cloudy
- Rain
- Thunderstorm
- Dry wind or dust
- Rare supernatural fog

Weather affects:

- Crop watering and quality
- Fish availability and behavior
- NPC locations and schedules
- Animal behavior
- Ambience and parallax
- Visibility and lighting
- Clearly disclosed Mahjong table conditions

## 2.4 Progression

There are no launch character levels, HP, MP, armor, or combat statistics.

Progression comes from:

- Mahjong rank
- Deed discovery
- Brand unlocks and upgrades
- Tool upgrades
- Fishing gear
- Farm construction
- Animal bloodlines
- Recipes and processing
- Relationships
- Helper abilities
- Property deeds
- Region access
- Hall restoration
- Story choices
- Collections

## 2.5 Failure

The player may lose:

- Time
- Money
- Table tokens
- Produce
- Fish
- Ordinary wagered items
- Bait or fishing gear durability on harder settings

The player may not permanently lose:

- Wayward Farm
- Main story access
- Essential tools
- Unique progression items
- Hall restoration
- Required relationships

Lost unique wagers return through rematch or retrieval quests.

---

# 3. Engineering principles

## 3.1 File limits

Project-owned handwritten files should stay below 300 LOC where practical and safe.

- Preferred: 80–220 LOC
- Review: 250 LOC
- Soft maximum: 300 LOC

Split by responsibility. Do not split cohesive logic merely to satisfy a number.

## 3.2 Data-driven content

Use typed data resources and registries for:

- Tiles
- Brands
- Deeds
- Opponents
- AI personalities
- Items
- Crops
- Animals
- Fish
- Fishing gear
- Recipes
- Buildings
- Shops
- Regions
- Weather
- Schedules
- Quests
- Dialogue
- Hall stages
- Endings

Scenes and UI should render data; they should not become authoritative databases.

## 3.3 Determinism

Use separate deterministic random streams for:

- Mahjong wall construction
- Mahjong AI tie-breaking
- Weather
- Fish selection
- Fish behavior
- Crop quality
- Animal breeding
- Shop rotations
- Optional world events

Save the necessary seeds and stream state.

## 3.4 Versioning

Version:

- Save schema
- Content data
- Mahjong replay schema
- Asset catalogs
- Generated atlases
- Dialogue state
- Quest state
- Construction placement data

Provide migrations before changing persistent formats.

## 3.5 Testing

Build automated tests for rule-heavy or state-heavy systems. At minimum:

- Mahjong legality
- Claims
- Deeds
- Brands
- High Noon
- AI information boundaries
- Match replay
- Save migration
- Crop growth
- Animal aging
- Breeding
- Fishing state transitions
- Economy transactions
- Construction placement
- Navigation safety
- Quest transitions
- Ending evaluation

---

# 4. Target repository architecture

```text
assets/
  generated/
  runtime/
  source/                  # ignored local imports

data/
  animals/
  brands/
  buildings/
  crops/
  deeds/
  dialogue/
  endings/
  fish/
  fishing_gear/
  items/
  localization/
  opponents/
  quests/
  recipes/
  regions/
  schedules/
  shops/
  weather/

docs/
  architecture/
  assets/
  design/
  production/
  qa/
  release/

legal/

src/
  bootstrap/
  core/
  content/
  input/
  audio/
  save/
  time/
  weather/
  player/
  interaction/
  world/
  navigation/
  dialogue/
  quests/
  npcs/
  relationships/
  inventory/
  economy/
  shops/
  crafting/
  cooking/
  mahjong/
    domain/
    application/
    ai/
    presentation/
  farm/
  crops/
  construction/
  animals/
  fishing/
  horses/
  ui/
  accessibility/
  story/
  testing/

tests/
  unit/
  integration/
  fixtures/

tools/
  asset_import/
  atlas_generation/
  validation/
  release/

vendor/
  local/                   # ignored source archives
```

---

# 5. Content targets

## 5.1 Seven regions

### Wayward Farm

Purpose:

- Home
- Farming
- Construction
- Animals
- Processing
- Shipping
- Helper assignment
- Save and sleep
- Family mystery clues

Recommended baseline footprint:

- Approximately four camera screens wide by three screens tall
- Fixed farmhouse
- Eight starting crop plots
- Barn
- Repairable animal pen
- Stable or hitching post
- Pond or well
- Shipping crate
- Decoration zone
- Two locked expansions
- Secret route to water unlocked later

### Bridlewood Ranch

Purpose:

- Horse introduction
- Animal systems
- Neighbor storyline
- Breeding
- Pasture retirement
- Ranch contests
- Farm shortcut

Recommended baseline footprint:

- Four camera screens wide by two screens tall
- Main ranch house
- Pastures
- Pens
- Horse corral
- Training area
- One hidden structure or cave

### Dustward

Purpose:

- Rough frontier main street
- General store
- Saloon
- Inn
- Beginner opponents
- Notice board
- Early quests
- Comedy and town identity

Recommended baseline footprint:

- Five camera screens wide by two screens tall
- Street-facing named buildings
- Important interiors
- Alleys and rear entrances
- Hitching post
- Restricted route toward Saint’s Landing

### Saint’s Landing

Purpose:

- Wealthy port neighborhood
- Texas King’s public influence
- Six Brands Hall
- Government and property records
- Experts
- Political conflict
- Tournament content

Recommended baseline footprint:

- Five camera screens wide by three screens tall
- Hall/private club
- Town office
- Wealthy homes
- Shops
- Bridge or gate control
- Hidden service routes

### Ironhook Docks

Purpose:

- Cargo
- Traders
- Imported goods
- Warehouses
- Delivery jobs
- Property disputes
- Dock ambience
- Night activity

Recommended baseline footprint:

- Four camera screens wide by two screens tall
- Warehouses
- Commercial pier
- Customs or office building
- Cargo puzzles
- Secret storage room

### Gull’s Rest

Purpose:

- Fishing village
- Fish market
- Cabins
- Main fishing progression
- Contests
- Rare fish
- Quiet relationship scenes

Recommended baseline footprint:

- Four camera screens wide by three screens tall
- Fish market
- Fisher cabin
- Several shore conditions
- Tidal or weather-dependent routes
- One secret shoreline interior

### Red Testament and King’s Reach

Purpose:

- Desert exploration
- Supernatural history
- Final rule discoveries
- Texas King’s secret compound
- Finale preparation
- Postgame exploration

Recommended baseline footprint:

- Six camera screens wide by three screens tall, plus compound interiors
- Desert trails
- Bonfire sites
- Ruins
- Hidden records
- Town-facing office connection
- Secret compound
- Finale approach

These are baseline targets, not rigid dimensions. Adjust to the supplied map assets while preserving density and navigation clarity.

## 5.2 Interiors

Every major named building and every opponent’s home should be enterable.

Decorative background buildings may remain closed unless they contain:

- A quest
- A shop
- A schedule destination
- A secret
- A restoration function
- A meaningful interaction

Target eight secret interiors or hidden entry routes across the launch world.

## 5.3 Hall restoration

The Six Brands Hall uses five authored stages:

1. Restricted private club
2. Cleanup and structural access
3. Functional practice room
4. Public tournament hall
5. Legendary restoration

Players may place optional decorations, but major state changes use authored layouts to protect story staging and navigation.

---

# 6. Mahjong implementation plan

## 6.1 Tile model

Every tile contains:

- Traditional identity
- Suit or honor group
- Rank where applicable
- Brand color
- Orientation presentation
- Runtime visual key
- Optional state overlay

Brands:

- Blue — River
- Dark — Night
- Green — Homestead
- Orange — High Noon
- Pink — Hospitality
- Purple — Omen

Every Brand also has a symbol and pattern so color is not the only identifier.

## 6.2 Trail Rules

Used by early opponents:

- 11-tile hand structure
- Three groups and one pair
- Three copies of each traditional identity
- 102-tile wall
- Exactly 17 tiles per Brand
- Runs
- Matching Sets
- Honor pairs and Sets
- No quads

## 6.3 Frontier Rules

Used by advanced opponents and restored-hall play:

- 14-tile hand structure
- Four groups and one pair
- Four copies per traditional identity
- 136-tile wall
- Approximately 22–23 tiles per Brand
- Extra color allocation rotates
- Quads supported
- Expanded Deeds
- Stronger opponent planning

## 6.4 Match structure

1. Morning Hand
2. High Noon Hand
3. Sundown Hand
4. Midnight Hand
5. Showdown Hand only on tied Renown

Dealer alternates automatically.

Target full-match duration:

- Approximately 15–25 real minutes
- Repeated animations can be accelerated or skipped

## 6.5 Loadouts

- All six colors appear in every match.
- Doc equips two unlocked Brands before the match.
- The two Brands remain locked for the full match.
- Each NPC has fixed primary and secondary Brands.
- Charges reset every hand.
- Three matching discards produce one activation.
- Maximum two stored activations per Brand.
- Every Brand supports later upgrade choices.

Doc begins with Orange and Blue.

## 6.6 Claims and abilities

### Blue — River

- Claim: complete a Run
- Active: recover one of the player’s latest two discards, then discard another tile

### Dark — Night

- Claim: counter or deny an opponent claim
- Active family: inspect, temporarily lock, make unclaimable, or cancel a Brand power

### Green — Homestead

- Claim: complete a matching Set
- Active: place a tile in the Corral, draw a replacement, recover the stored tile later

### Orange — High Noon

- Claim: complete any group while granting the opponent one Brand charge
- Active: draw two, keep one, return the other to the bottom of the wall

### Pink — Hospitality

- Claim: establish the Pair
- Active: neutral face-up exchange or cleanse a hostile effect

### Purple — Omen

- Claim: reserve a marked discard until the next turn
- Active: inspect and reorder the next three wall tiles

Every player may always claim a discard that immediately completes a winning hand.

## 6.7 High Noon

When one tile from victory:

- Lock hand
- Disable Brand powers
- Start three-draw countdown
- Resolve draw/discard automatically
- Grant major Renown bonus on success
- Allow visible personality-specific opponent counters
- Release hand normally on failure

## 6.8 Deeds and Renown

Traditional scoring language is replaced by Western names.

Initial Deeds include:

- Three Trails
- The Posse
- Claimed Territory
- Home Turf
- Cattle Rustler
- Full Frontier
- Quickdraw
- Self-Made
- Long Trail
- Against the Odds

Build Deeds as independent evaluators with:

- Stable ID
- Display name
- Description
- Rule-set availability
- Renown value
- Discovery condition
- Tutorial text
- Replay evidence

## 6.9 Assistance

### Tenderfoot

- Full tutorial
- Auto-sort
- Legal highlights
- Explained recommendations
- Wait display
- Danger warnings
- Deed explanations
- One undo per turn

### Trailhand

- Legal highlights
- Optional recommendations
- Wait and Deed display
- Reduced warnings

### Gunslinger

- Minimal assistance
- No recommendations
- No automatic danger warnings
- Legal validation and scoring remain

## 6.10 AI opponents

Every opponent data record needs:

- Final name and nickname
- Primary Brand
- Secondary Brand
- Fixed skill level
- Preferred hand structures
- Claim aggression
- Defense threshold
- High Noon behavior
- Wager behavior
- Memory quality
- Risk tolerance
- Favorite Deeds
- Hostile ability preference
- Emotional reactions
- Tutorial role
- Replay explanation labels

AI difficulty changes reasoning, not access to hidden information.

## 6.11 Texas King

Texas King uses Dark and Purple.

His altered rules are:

- Supernatural but legal within learnable rule extensions
- Foreshadowed through opponents, hall records, property documents, and desert discoveries
- Fully discoverable before the final match
- Logged in the match interface
- Counterable by systems the player has mastered

He may never secretly change the wall, force a result, inspect hidden tiles without a declared effect, or ignore normal costs.

---

# 7. Farming and construction plan

## 7.1 Free placement

The player may freely place:

- Crop plots
- Paths
- Fences
- Gates
- Decorations
- Processing machines
- Barns
- Coops
- Pens
- Storage
- Most constructed buildings

The farmhouse remains fixed.

Placement must validate:

- Terrain
- Footprint
- Overlap
- Door clearance
- Region exits
- Water
- Story objects
- Animal reachability
- NPC route availability
- Construction access

Use preview states:

- Valid
- Invalid terrain
- Collision
- Blocks exit
- Blocks route
- Requires upgrade
- Requires ownership

## 7.2 Crops

Use all twenty supplied animated crops:

- Bamboo
- Beetroot
- Berry
- Broccoli
- Carrot
- Cauliflower
- Celery
- Corn
- Eggplant
- Grape
- Leek
- Lettuce
- Onion
- Pepper
- Potato
- Pumpkin
- Radish
- Tallgrass
- Tomato
- Wheat

Each crop data record should define:

- Seed item
- Growth stages
- Stage duration
- Water requirement
- Wilt threshold
- Death threshold
- Recovery behavior
- Base yield
- Quality factors
- Weather modifiers
- Sell value
- Recipe uses
- Gift tags
- Quest uses
- Wager eligibility

Tools have permanent upgrades and no durability.

## 7.3 Crop quality

Quality derives from bounded factors:

- Watering consistency
- Fertilizer
- Weather
- Harvest timing
- Tool upgrades
- Helper effect

Show the player why quality changed.

## 7.4 Farm progression

Unlock through:

- Story
- Money
- Materials
- NPC help
- Mahjong victories
- Property deeds
- Hall milestones

The farm may accumulate manageable debt or stalled construction, but it can never be permanently lost.

---

# 8. Animal system plan

## 8.1 Launch animal coverage

Use animated supplied species first. Static livestock may enter only after consistent animation is created.

Potential launch species from supplied content include:

- Cows
- Pigs
- Birds or chickens
- Bunnies
- Cats
- Mice
- Foxes where narratively appropriate
- Additional sheep, goats, donkey, ducks, turkey, and chicks after animation production

## 8.2 Individual animal data

Each animal tracks:

- Unique ID
- Name
- Species
- Color or variant
- Birth date
- Age stage
- Parents
- Happiness
- Health state
- Product quality
- Pregnancy or breeding cooldown
- Home structure
- Current schedule
- Retirement state

## 8.3 Breeding

Breeding should produce:

- Parent linkage
- Inherited color weighting
- Bounded quality inheritance
- Name prompt
- Growth stages
- Space validation

Prevent uncontrolled population growth through:

- Capacity limits
- Breeding cooldown
- Player confirmation
- Retirement pasture
- Adoption or sale options where appropriate

## 8.4 Aging and retirement

Animals age but do not die on-screen from ordinary time passage.

Elderly animals:

- Produce less
- Stop breeding
- May move to a retirement pasture
- Remain named and visible
- May unlock relationship or legacy bonuses

## 8.5 Care burden

Pasture, feeders, upgrades, and helpers reduce repetitive maintenance. Animal systems should reward care without forcing the player into an inflexible morning checklist.

---

# 9. Fishing plan

## 9.1 Presentation

The world remains full-screen. Fishing UI overlays one side while preserving:

- Doc at the shoreline
- Bobber
- Surface movement
- Fish shadow
- Line direction
- Obstacles
- Weather
- Time
- Contest spectators

Place the panel opposite Doc’s facing direction when possible.

## 9.2 State machine

1. Select equipment
2. Aim
3. Cast
4. Lure lands
5. Wait
6. Bite cue
7. Hook set
8. Directional struggle
9. Reel/release tension
10. Catch or escape
11. Presentation
12. Inventory and record update

## 9.3 Equipment

Track:

- Rod
- Line
- Hook
- Bobber
- Lure
- Bait

Tools may affect:

- Cast distance
- Tension tolerance
- Reel speed
- Hook timing
- Fish attraction
- Rarity
- Obstacle resistance
- Durability loss

## 9.4 Fish data

Every fish defines:

- Locations
- Time windows
- Weather
- Bait
- Lure
- Depth
- Pull pattern
- Speed
- Stamina
- Weight range
- Quality
- Rarity
- Sell value
- Recipes
- Gifts
- Quest uses
- Wager use
- Record category
- Release reward where applicable

## 9.5 Failure by difficulty

Beginner:

- Lose time only

Higher settings may add:

- Bait consumed
- Hook durability
- Lure durability
- Line-break chance

Fishing difficulty is independent from Mahjong assistance.

## 9.6 Expansion boundary

Boat fishing remains post-launch expansion work. Launch may show boats and docks but must not implement player-controlled water travel.

---

# 10. Horse travel plan

## 10.1 Launch implementation

- Doc approaches horse
- Fade
- Doc is replaced by horse
- Horse movement uses supplied directional animation
- Speed increases
- Hitching posts unlock fast travel
- Dismount validates position
- Doc returns

## 10.2 Horse data

Track:

- Selected color
- Name
- Unlock state
- Current location
- Discovered hitching posts
- Travel state

Available colors:

- Black
- Brown
- Golden
- Gray
- White

## 10.3 Restrictions

- No horse indoors
- No horse in narrow interiors
- No horse on invalid docks or water
- No dismount inside collision
- No fast travel while a story sequence forbids it

---

# 11. Economy, inventory, crafting, and processing

## 11.1 Currencies

- Dollars
- Table tokens

## 11.2 Item categories

- Seeds
- Crops
- Animal products
- Fish
- Food
- Ingredients
- Bait
- Lures
- Hooks
- Lines
- Rods
- Tools
- Materials
- Furniture
- Clothing
- Table charms
- Recipes
- Property documents
- Story items
- Collectibles

## 11.3 Sale paths

- Farm shipping crate
- Direct shop sale
- Posted town orders
- Mahjong-negotiated price or access

## 11.4 Processing

Launch systems:

- Cooking
- Preserves
- Grain/flour
- Cheese/butter
- Smoked fish
- Bait crafting
- Animal feed
- Nonalcoholic tonics
- Saloon recipes

## 11.5 Food effects

Food may grant clear, bounded effects such as:

- Crop quality bonus
- Slower fishing tension
- Extra relationship gain
- One opening Brand charge
- Better sale negotiation
- Weather resistance

Prevent stacking exploits through categories, duration limits, and visible caps.

---

# 12. NPC, relationship, schedule, and quest plan

## 12.1 Opponent roster

Current source identities:

1. Dusty Kid
2. Sheriff Blackwood
3. Deadshot Jake
4. Prairie Ranger
5. Gold Prospector
6. Rose McGraw
7. Dynamite Bill
8. Bison Hunter
9. Outlaw Queen
10. Iron Marshal
11. Texas King

Treat the first ten as provisional names until final names and nicknames are assigned. Texas King remains fixed.

## 12.2 Tier structure

- Three beginners
- Four established townspeople
- Three experts
- Texas King

Players may challenge available opponents in any order within an unlocked tier.

## 12.3 Required data per NPC

- Final name
- Nickname
- Age range
- Occupation
- Home
- Work location
- Daily schedule
- Weather alternatives
- Personality
- Comedic surface trait
- Serious underlying conflict
- Primary Brand
- Secondary Brand
- AI profile
- Wager pools
- Relationship thresholds
- Portrait expressions
- Required world animations
- Personal quest
- First-victory reward
- Active helper action
- Passive bonus
- Hall role
- Finale contribution
- Postgame state

## 12.4 Multi-stage story template

Every opponent receives one substantial arc:

1. Introduction
2. Initial table challenge
3. Personal problem revealed
4. Investigation or material task
5. Relationship complication
6. Rematch or decisive choice
7. Resolution
8. Helper/passive unlock
9. Finale support state
10. Postgame dialogue

Not every stage needs equal length, but every opponent must feel authored rather than functioning as a table menu.

## 12.5 Schedules

NPC schedules may depend on:

- Day
- Time
- Weather
- Quest state
- Relationship
- Hall stage
- Property access
- Festivals
- Fishing contests
- Tournaments

Important events shift to the next valid opportunity rather than vanishing.

## 12.6 Helpers

NPCs provide:

- Active help chosen through direct conversation or farmhouse board
- Permanent passive bonuses

Examples:

- Water field
- Feed animal group
- Process batch
- Deliver goods
- Reveal rare fish conditions
- Improve shop inventory
- Repair structures
- Improve produce identification
- Unlock routes
- Improve tournament preparation

Limit simultaneous active help so the farm does not run itself.

---

# 13. Dialogue, choices, and localization

## 13.1 Dialogue architecture

Use a localization-ready data format with stable keys.

Dialogue nodes should support:

- Speaker
- Text key
- Portrait and expression
- Sprite emote
- Conditions
- Choices
- State changes
- Item checks
- Relationship checks
- Quest changes
- Camera or staging command
- Audio cue
- Next node

Do not embed major conversations directly into map scripts.

## 13.2 Choice effects

Choices may affect:

- Relationship
- Quest route
- Information access
- Wager options
- Helper quality
- Finale support
- Ending evaluation

Avoid fake choices that produce identical immediate and long-term results unless the difference is purely characterization and clearly intended.

## 13.3 Language

Launch in English while keeping all player-facing text localization-ready.

---

# 14. Portrait and animation production

## 14.1 Portraits

Create 128×128 pixel portraits from the supplied sprites with one shared style guide:

- Same outline weight
- Same light direction
- Same palette density
- Same crop and framing
- Same background treatment
- Controlled expression library

Recommended expressions:

- Neutral
- Friendly
- Amused
- Irritated
- Worried
- Sad
- Surprised
- Angry
- Determined
- Defeated

Not every NPC requires all ten; use role-based subsets.

## 14.2 Shared world animation library

Create only the animations each character needs:

- Table idle
- Reach for tile
- Soft tile placement
- Slam or declaration
- Win reaction
- Loss reaction
- Fishing
- Watering
- Feeding
- Carrying
- Eating/drinking
- Pointing/arguing
- Gun reaction
- Indoor idle
- Sleeping where required

Use controlled key-pose production and pixel cleanup. Do not generate inconsistent freeform animation that ignores the original sprite design.

## 14.3 Dynamite Bill

Use the generated east-facing rotation created by mirroring the west-facing source. Preserve the original source and record the generation rule.

---

# 15. Hall, property, rank, and tournament systems

## 15.1 Property system

Property and access records should support:

- Owner
- Disputed owner
- Current access
- Required deed
- Match condition
- Quest alternative
- Restoration effect
- Map route effect
- Ending contribution

## 15.2 Mahjong rank

Track:

- Opponents defeated
- Match record
- Renown
- Deeds discovered
- High Noon victories
- Brand mastery
- Trail Rules completion
- Frontier Rules completion
- Tournament results

Rank unlocks opponents, events, and hall content without functioning as a combat level.

## 15.3 Tournaments and festivals

Launch event types:

- Beginner table night
- Town tournament
- Fishing contest
- Market day
- Hall reopening
- Final championship

Events repeat or reschedule so they cannot be permanently missed.

---

# 16. Story implementation

## 16.1 Act structure

### Act I — Inheritance

- Doc arrives at Wayward Farm
- Learns local Mahjong culture
- Meets beginner opponents
- Learns Orange and Blue
- Encounters the restricted town route
- Finds first clue that Silas investigated Texas King

### Act II — Respect

- Defeats beginner and established opponents
- Develops farm and fishing life
- Opens property routes
- Begins hall restoration
- Learns more Brands
- Town divisions become clear

### Act III — The Bargain

- Faces expert opponents
- Learns Frontier Rules
- Discovers the legal and supernatural mechanics of Texas King’s bargain
- Finds evidence Silas is alive
- Gains access to Red Testament and King’s Reach
- Learns every altered final-match rule

### Act IV — High Noon

- Restores the hall
- Final tournament warning and separate save
- Championship against Texas King
- Texas King loses under legitimate rules
- Dialogue-driven standoff
- Direct shot with some pixel blood and no gore
- Texas King dies
- Father reveal
- Silas returns
- Ending evaluation
- Postgame unlock

## 16.2 Texas King’s bargain

The bargain:

- Prevents Texas King from aging
- Protects land, wealth, status, and influence legitimately won under Six Brands rules
- Spiritually binds people who accept his table
- Can be broken only by a blood descendant who masters all six Brands, defeats him under the hall’s legitimate rules, and wins the hall back

Texas King knows Doc is his son from the beginning.

## 16.3 Final standoff

Flow:

1. Post-match dialogue
2. Evidence and allies reflected in scene
3. Texas King draws
4. Timing interaction
5. Doc fires directly
6. Pixel-blood impact
7. Texas King physically dies
8. Supernatural age and identity are exposed
9. Father reveal
10. Failure restarts immediately before the timing interaction

Do not replay the entire final Mahjong match after a failed timing input.

---

# 17. Endings and postgame

## 17.1 Four endings

### A Town Reclaimed

Requires strong property recovery and major NPC resolutions.

### Keeper of the Six Brands

Requires full hall restoration, Mahjong mastery, Deed discovery, and supernatural-history completion.

### The Good Earth

Requires exceptional farm, ranch, fishing, and community development.

### A Hollow Victory

Texas King dies, but insufficient preparation leaves Mercy’s Wake divided and vulnerable.

The finale displays a clear readiness warning and creates a separate autosave.

## 17.2 Ending evaluation

Use transparent category scores rather than one hidden total:

- Community
- Hall
- Mahjong
- Farm
- Fishing
- Property
- Truth
- Relationships

Show a post-credits summary explaining the achieved ending without exposing every internal variable beforehand.

## 17.3 Postgame

After every ending:

- Texas King remains dead
- Silas returns
- Hall remains publicly operated
- Unfinished stories remain available
- Advanced Mahjong tables unlock
- King’s Reach becomes explorable
- Farm and animals continue
- Fishing and records continue
- Tournaments repeat
- Collections remain completable

---

# 18. UI, UX, controller, and accessibility

## 18.1 Main menus

- Title
- Continue
- Load
- New game
- Settings
- Accessibility
- Credits
- Quit

## 18.2 In-game UI

- Clock and weather
- Money and tokens
- Context prompt
- Inventory
- Map
- Quest journal
- Relationships
- Mahjong journal
- Fish records
- Crop records
- Animal registry
- Recipe book
- Hall restoration
- Settings
- Save/load

## 18.3 Mahjong UI

- Hand
- Opponent status
- Discard rivers
- Brand loadouts
- Charge meters
- Legal claims
- High Noon countdown
- Deed preview
- Renown breakdown
- Wager
- Tutorial explanation
- Replay history

## 18.4 Accessibility

- Full remapping
- Keyboard/controller parity
- Xbox, PlayStation, generic glyphs
- Adjustable text size
- Dialogue speed
- Hold/toggle alternatives
- Brand symbols and patterns
- Reduced flash
- Reduced screen shake
- Fishing assists
- Independent Mahjong hints
- Animation speed/skip
- Pause in single-player sequences
- Separate volume buses
- Windowed, borderless, fullscreen
- UI scale
- High contrast focus
- Subtitle support for callouts

No critical information may rely only on:

- Color
- Sound
- Vibration
- Rapid timing

---

# 19. Audio plan

## 19.1 Buses

- Master
- Music
- Ambience
- SFX
- Mahjong callouts
- UI

## 19.2 Existing sources

Use supplied:

- Western music loops
- Town, field, and village music
- Mahjong sound pack
- Cozy ambience
- Footsteps
- Water and material interactions
- Birds and bees
- UI sounds

## 19.3 Additional authored or sourced needs

- Revolver draw
- Gunshot
- Bullet impact
- Horse steps and vocalizations
- Livestock
- Doors and gates
- Bonfire
- Line tension
- Reel
- Bobber
- Fish struggle
- Catch accent
- Saloon ambience
- Dock ambience
- Desert wind
- Hall crowd
- Supernatural Brand effects

Map every sound through an event key rather than direct scene file paths.

---

# 20. Production milestones

Each milestone ends with a runnable build and pull request.

## Milestone 0 — Foundation

Status:

- Repository
- Legal record
- Initial docs
- Asset manifests
- Supplemental importer
- Repository guard
- Minimal Godot shell

Exit:

- Foundation merged into `develop`

## Milestone 1 — Reproducible asset pipeline

Deliver:

- Supplemental import
- Master split-archive import
- Asset catalogs
- Mahjong atlas generation
- Audio normalization
- Import validation

Exit:

- Clean local import from source archives

## Milestone 2 — Core runtime

Deliver:

- Session
- Scene routing
- Input
- Audio
- Content registry
- Test runner
- Save skeleton
- Settings

Exit:

- Stable bootstrap and automated smoke test

## Milestone 3 — Player and world foundation

Deliver:

- Doc movement
- Camera
- Interaction
- Doors
- Map transitions
- Surface footsteps
- Controller prompts

Exit:

- Wayward Farm graybox and one interior playable

## Milestone 4 — Time, weather, schedules, and saves

Deliver:

- Clock
- Pause rules
- Clear/rain
- NPC schedule framework
- Save slots
- Autosave
- Emergency backup
- Migrations

Exit:

- Full day loop survives save/load

## Milestone 5 — Trail Rules Mahjong

Deliver:

- Domain model
- Wall
- Hand validation
- Claims
- Match flow
- Renown
- Replay
- Tests

Exit:

- Complete legal headless match simulation

## Milestone 6 — Orange, Blue, AI, and tutorial

Deliver:

- Starting Brands
- High Noon
- First AI profiles
- Tenderfoot tutorial
- Match UI

Exit:

- New player completes first full match

## Milestone 7 — Farm vertical slice

Deliver:

- Free placement
- Four crops
- Water/wilt/recover/death/harvest
- Shipping
- Basic shop

Exit:

- Complete crop-to-sale loop

## Milestone 8 — Fishing vertical slice

Deliver:

- Overlay
- Gear
- Six to eight fish
- Tension
- Catch presentation
- Records

Exit:

- Complete catch-to-sale/cook loop

## Milestone 9 — Horse and connected slice

Deliver:

- Horse replacement
- Hitching posts
- Farm
- Dustward
- First fishing location
- Three interiors

Exit:

- Connected traversal loop

## Milestone 10 — Narrative vertical slice

Deliver:

- Three opponents
- One substantial arc
- One helper
- First hall stage
- First property dispute

Exit:

- Hybrid vertical slice complete

## Milestone 11 — Full Mahjong expansion

Deliver:

- Green, Pink, Dark, Purple
- Brand upgrades
- Expanded Deeds
- Frontier Rules
- Quads
- Advanced AI
- Full opponent framework

Exit:

- All six Brands and both rule sets complete

## Milestone 12 — Full farm and animals

Deliver:

- All crops
- Buildings
- Processing
- Animals
- Breeding
- Aging
- Retirement
- Helpers

Exit:

- Complete open-ended farm simulation

## Milestone 13 — Full fishing and economy

Deliver:

- All launch fish
- All shore locations
- Contests
- Rare conditions
- Full gear progression
- Orders
- Recipes
- Shops
- Wager economy

Exit:

- Balanced non-Mahjong progression path

## Milestone 14 — Full world

Deliver:

- Seven regions
- Major interiors
- All opponent homes
- Eight secrets
- Weather variants
- Routes and fast travel

Exit:

- Entire launch territory explorable

## Milestone 15 — NPC stories and hall

Deliver:

- Ten non-final opponent arcs
- Helpers
- Passive bonuses
- Five hall stages
- Property system
- Tournaments

Exit:

- All community content complete

## Milestone 16 — Main story and finale

Deliver:

- Silas investigation
- Bargain discovery
- King’s Reach
- Final match
- Gun standoff
- Father reveal
- Silas return

Exit:

- Complete story playable start to finish

## Milestone 17 — Endings and postgame

Deliver:

- Four ending evaluators
- Credits
- Epilogues
- Postgame state
- Repeat tournaments
- Completion support

Exit:

- Every ending and postgame validated

## Milestone 18 — Presentation and accessibility

Deliver:

- Portraits
- Required NPC animations
- UI final art
- Audio completion
- Accessibility
- Controller remapping
- Settings
- Visual cohesion

Exit:

- No prototype presentation remains

## Milestone 19 — Release candidate

Deliver:

- Performance pass
- Save migration tests
- Full regression
- Windows packaging
- Clean-machine test
- Credits
- Legal files
- Release notes

Exit:

- Launch candidate passes all gates

---

# 21. Quality gates

## 21.1 Gameplay

- No fake doors on important buildings
- No disconnected minigame rewards
- No progression softlocks
- No permanently missed critical events
- No hidden Mahjong cheating
- No farm layout that seals required routes
- No save loss from schema changes
- No controller-only dead ends
- No required mouse interaction

## 21.2 Performance

Target:

- Stable 60 FPS at 1920×1080 on the project owner’s Windows system
- Bounded world-memory usage
- No loading stutter during ordinary movement
- Short authored transitions between major map packs
- Mahjong UI remains responsive with full replay logging
- Large SVG source library replaced by runtime atlases

## 21.3 Content

- Eleven opponents
- Ten non-final multi-stage arcs plus Texas King
- Seven regions
- Five hall stages
- Eight secrets
- All six Brands
- Both rule sets
- Four endings
- Open-ended postgame
- All supplied crops cataloged and usable
- Launch animal roster implemented consistently
- Launch fish roster fully integrated

## 21.4 Save compatibility

Before release:

- New game
- Upgrade from every public milestone save
- Corrupted-save recovery
- Missing optional content
- Pre-finale backup
- Postgame transition
- Farm with maximum placement
- Large animal roster
- Full inventory
- Long-running calendar
- Completed and incomplete quest mixes

---

# 22. Release checklist

- Godot 4.7.1 project opens without errors
- All automated tests pass
- Repository validator passes
- No unauthorized source archive in Git
- No missing legal file
- No unrecorded handwritten file-size exception
- No absolute local asset path
- No missing resource after clean reimport
- Windows export launches on a clean machine
- Save directory is writable
- Controller hot-plug works
- Remapping persists
- Audio sliders persist
- UI scaling persists
- Fullscreen modes persist
- Credits include optional provenance acknowledgments
- Four endings tested
- Postgame tested
- Final standoff retry tested
- Texas King’s match replay tested
- Every opponent can be challenged repeatedly
- Every unique wager can be recovered
- Every major event can reschedule
- Main story can be completed without mastering optional collections
- Completionist path remains achievable after ending

---

# 23. Completion definition

The whole game is complete when a new player can:

1. Begin at Wayward Farm.
2. Learn Six Brands Mahjong from zero knowledge.
3. Develop the farm and ranch.
4. Fish meaningfully across the territory.
5. Build relationships with all eleven opponents.
6. Unlock and use all six Brands.
7. Progress from Trail Rules to Frontier Rules.
8. Restore all five stages of the hall.
9. Recover the town’s disputed access and property.
10. Find and rescue Uncle Silas.
11. Learn every final-match rule.
12. Defeat Texas King legally.
13. Complete the gun standoff.
14. Witness the father reveal.
15. Receive one of four endings.
16. Continue in a stable postgame.
17. Save, load, remap controls, and use accessibility features without losing progress.
18. Complete the game without encountering a placeholder, fake system, hidden AI cheat, or critical softlock.
