# Codex Master Execution Plan
## Six Brands at High Noon — Foundation, Asset Integration, and Hybrid Vertical Slice

**Repository:** `https://github.com/DocDamage/mahjongRPG`  
**Engine:** Godot 4.7.1  
**Primary platform:** Windows  
**Integration branch:** `develop`  
**Current foundation branch:** `agent/project-foundation`  
**Current foundation pull request:** PR #1  
**Target internal resolution:** 960×540  
**World art grid:** 48×48  
**Project rule:** keep project-owned handwritten files below 300 lines where practical and safe.

---

## 1. How Codex should use this plan

Treat this document as an execution directive, not a brainstorming brief.

Codex must:

1. Inspect the current repository and existing documentation before changing anything.
2. Preserve every locked design decision unless a technical contradiction is proven.
3. Make reasonable implementation decisions without repeatedly asking for clarification.
4. Work in focused branches and commits.
5. Keep the project runnable after every completed milestone.
6. Run validation after every meaningful change.
7. Report failures honestly, fix them when possible, and record unresolved blockers precisely.
8. Avoid placeholders, fake implementations, disconnected demo scenes, and systems that only appear to work.
9. Never commit the large source archives, Godot import cache, temporary extraction output, or duplicated vendor content.
10. Never exceed the 300-line soft limit merely for convenience. Split by responsibility, not arbitrary line count.

This plan covers two outcomes:

- A clean local development environment with all supplied assets imported and verified.
- A production-quality hybrid vertical slice that uses architecture suitable for the complete game.

The separate complete-game plan defines the work after this slice.

---

## 2. Locked product identity

The game is **Six Brands at High Noon**, a top-down pixel-art Western cozy narrative RPG set in the fictional late-1800s San Perdido Territory.

Doc, a 35-year-old dry, dark, sarcastic but ultimately friendly cowboy, inherits Wayward Farm near Mercy’s Wake. The town settles property, debt, status, influence, and information disputes through a local one-on-one Mahjong variant. Doc must develop the farm, fish, build relationships, defeat eleven recognized opponents, restore the Six Brands Hall, rescue Uncle Silas, and ultimately defeat Texas King.

Launch scope intentionally excludes conventional combat. Gun animations support story scenes and the final standoff.

---

## 3. Non-negotiable engineering constraints

### 3.1 Repository and branch discipline

- `main` contains stable milestones only.
- `develop` is the integration branch.
- Feature work uses `agent/<focused-scope>`.
- Every feature branch receives a pull request.
- Do not commit directly to `main`.
- Do not mix unrelated systems in one commit.
- Do not rewrite repository history to hide mistakes.

### 3.2 File-size discipline

Project-owned handwritten files should normally remain:

- Preferred: 80–220 LOC
- Review warning: 250 LOC
- Soft maximum: 300 LOC

Exceptions are allowed only when splitting would reduce correctness or cohesion. Record justified exceptions in:

```text
docs/architecture/size_exceptions.md
```

The limit does not apply to:

- Generated files
- Third-party source
- Godot-generated scene/resource text
- Machine-generated manifests
- Large declarative data tables

### 3.3 Asset discipline

Keep source archives outside Git:

```text
vendor/local/
```

Imported source assets remain ignored:

```text
assets/source/
```

Only approved runtime-ready assets, generated atlases, corrections, manifests, and legally required documentation may become tracked content.

Never commit:

- `MahjongRPG.z01` through `.z08`
- `MahjongRPG.zip`
- The reconstructed 838 MiB master ZIP
- `Hero - Cowboy - AssetPack.zip`
- `horses.zip`
- `fishing UI.zip`
- `Cozy SFX Volume 1.zip`
- Marketplace/demo archives
- `.godot/`
- Import caches
- Temporary render/export folders
- Duplicate WAV/MP3/OGG versions unless each has a defined runtime purpose

### 3.4 Gameplay integrity

- Mahjong AI must not inspect concealed information without a visible legal ability.
- Match results must be reproducible from deterministic seeds.
- Important events may be delayed but never permanently missed.
- Main progression items may never be destroyed permanently.
- No stamina system.
- No conventional combat in the initial game.
- Time pauses during dialogue, menus, Mahjong, and cutscenes.
- A full Mahjong match advances the game clock by 90 minutes.
- Accessibility and controller support are foundation requirements, not final polish.

---

## 4. Required local inputs

Codex should locate or request access to these files on the Windows machine.

### 4.1 Supplemental archives

Exact filenames:

```text
Hero - Cowboy - AssetPack.zip
horses.zip
fishing UI.zip
Cozy SFX Volume 1.zip
```

Expected destination:

```text
vendor/local/supplemental/
```

### 4.2 Master split archive

Expected files:

```text
MahjongRPG.z01
MahjongRPG.z02
MahjongRPG.z03
MahjongRPG.z04
MahjongRPG.z05
MahjongRPG.z06
MahjongRPG.z07
MahjongRPG.z08
MahjongRPG.zip
```

Expected destination:

```text
vendor/local/master/
```

Codex should search, in order:

1. Repository-adjacent folders
2. `%USERPROFILE%\Downloads`
3. `%USERPROFILE%\Desktop`
4. Google Drive synchronized folders
5. OneDrive synchronized folders
6. Any path supplied through an environment variable such as `SIX_BRANDS_ASSET_ROOT`

Copy files into `vendor/local/`; do not move or delete the originals.

### 4.3 Required tools

Detect before installing anything:

- Git
- GitHub CLI
- Python 3
- FFmpeg
- 7-Zip or an equivalent split-ZIP-capable extractor
- Godot 4.7.1 Windows executable

Do not silently replace a different Godot installation. Record the exact Godot executable used.

---

## 5. Phase A — Repository orientation and safety snapshot

### Goal

Confirm the repository state and establish a reproducible baseline before asset import or implementation.

### Tasks

1. Clone the repository if no local checkout exists.
2. Fetch all remote branches and tags.
3. Inspect:
   - `README.md`
   - `docs/design/`
   - `docs/production/hybrid_vertical_slice.md`
   - `docs/assets/`
   - `docs/architecture/`
   - `legal/`
   - `tools/`
4. Confirm PR #1 and its check status.
5. Check out `agent/project-foundation`.
6. Confirm the branch contains the foundation commit and no unrelated local changes.
7. Run:

```bash
python tools/validate_repository.py
```

8. Record:
   - Git commit
   - Python version
   - Godot path and version
   - FFmpeg version
   - 7-Zip version
   - Operating system
   - Current validation output

Store the local environment record in:

```text
artifacts/local/environment_report.json
```

Keep `artifacts/local/` ignored by Git.

### Exit gate

- Repository validator passes.
- PR #1 is readable and has no unexpected changes.
- Toolchain status is known.
- No source archives are tracked.

---

## 6. Phase B — Supplemental asset import

### Goal

Run the existing deterministic importer and prove that Doc, horses, fishing UI, and Cozy SFX are available to Godot.

### Tasks

1. Place the four supplemental ZIP files in:

```text
vendor/local/supplemental/
```

2. Run verify-only mode first:

```bash
python tools/import_supplemental_assets.py --verify-only
```

3. If FFmpeg is unavailable, install or configure it, then rerun verification.
4. Run the full import:

```bash
python tools/import_supplemental_assets.py
```

5. Confirm:

```text
assets/source/supplemental/.import_complete.json
```

6. Verify expected categories:
   - `hero_cowboy`
   - `horses`
   - `fishing_ui`
   - `cozy_sfx`
7. Confirm the anomalous stone footstep is trimmed.
8. Confirm long ambience has been converted to OGG.
9. Confirm demo media and bonus tracks were excluded.
10. Run the repository validator again.
11. Run a file audit that reports:
    - Imported count
    - Extensions
    - Dimensions
    - Audio duration
    - Missing expected categories
    - Duplicate hashes

### Required fix behavior

If an archive checksum differs:

- Do not bypass the check.
- Determine whether the local file is a different source revision or corrupted.
- Generate a report.
- Update the committed manifest only when the file is confirmed to be the intended source package.

### Exit gate

- All four archives pass checksum and CRC verification.
- Imported output exists.
- No source ZIP is staged by Git.
- Godot-readable hero, horse, fishing, and audio files are present.

---

## 7. Phase C — Master archive import pipeline

### Goal

Create a deterministic, safe, repeatable pipeline for the full world, Mahjong, farm, NPC, music, item, parallax, and environment library.

### Required new files

Prefer these boundaries:

```text
tools/master_import/archive_parts.py
tools/master_import/archive_verifier.py
tools/master_import/extractor.py
tools/master_import/path_normalizer.py
tools/master_import/catalog_builder.py
tools/import_master_assets.py
docs/assets/manifests/master_source_archives.json
docs/assets/master_import.md
```

Keep each handwritten file below 300 LOC where practical.

### Tasks

1. Locate all nine master archive files.
2. Calculate and record:
   - Exact filename
   - Byte size
   - SHA-256
3. Use 7-Zip to test the split archive before extraction.
4. Extract to a temporary staging directory outside the tracked tree.
5. Reject unsafe paths and normalize filenames without overwriting collisions.
6. Preserve a mapping from original path to normalized path.
7. Exclude:
   - `__MACOSX`
   - `.DS_Store`
   - Engine caches
   - Compiled demos
   - Duplicate exported formats where a preferred source exists
8. Atomically replace:

```text
assets/source/master/
```

9. Generate:

```text
assets/source/master/.import_complete.json
artifacts/local/master_asset_catalog.json
artifacts/local/master_duplicate_report.json
artifacts/local/master_collision_report.json
```

10. Catalog at minimum:
    - Hero/NPC/horse character assets
    - Mahjong SVGs
    - Crops and growth stages
    - Animals and animation coverage
    - Fish and tackle
    - World tilesets
    - Interiors
    - Parallax
    - Music
    - Mahjong SFX
    - General item icons
    - Fonts
    - Source project files
11. Verify Dynamite Bill’s generated east pose is used when the source east pose is absent.
12. Never overwrite the original west pose.
13. Run import twice and confirm equivalent output hashes where timestamps are excluded.

### Exit gate

- The split archive passes integrity testing.
- Import is repeatable and safe.
- Every runtime category has a machine-readable catalog.
- No master archive part is tracked by Git.

---

## 8. Phase D — Godot 4.7.1 smoke validation

### Goal

Prove that the repository opens and imports cleanly in the required engine.

### Tasks

1. Locate the exact Godot 4.7.1 executable.
2. Run a headless editor import against the project.
3. Capture all import warnings and errors.
4. Run the bootstrap scene headlessly.
5. Open the project interactively and verify:
   - 960×540 internal viewport
   - Pixel filtering and integer scaling
   - Main scene loads
   - Input actions exist
   - No broken resource paths
   - No script parse errors
6. Add a smoke-test script that exits nonzero on:
   - Missing autoload
   - Missing main scene
   - Script parse failure
   - Missing required input action
   - Invalid runtime asset catalog
7. Add the smoke test to GitHub Actions when it can run without committing proprietary binaries or enormous assets.

### Exit gate

- Godot imports the repository without errors.
- Bootstrap launches.
- Runtime settings match the design.
- Validation failures are machine-detectable.

---

## 9. Phase E — Foundation merge and next branch

### Goal

Move from setup work into vertical-slice implementation without losing reviewability.

### Tasks

1. Resolve all local validation issues on `agent/project-foundation`.
2. Update PR #1 with any required setup fixes.
3. Ensure repository guard passes.
4. Mark PR #1 ready for review.
5. Squash-merge PR #1 into `develop`.
6. Delete the merged remote feature branch only after the merge is confirmed.
7. Pull updated `develop`.
8. Create:

```text
agent/hybrid-vertical-slice
```

9. Add a branch-start record to:

```text
docs/production/implementation_log.md
```

### Exit gate

- `develop` contains the validated foundation.
- The vertical-slice branch starts from the merged integration state.
- Working tree is clean.

---

## 10. Phase F — Core architecture scaffold

### Goal

Establish the complete architectural boundaries needed by the game while implementing only the vertical-slice content.

### Target structure

```text
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
  dialogue/
  quests/
  npcs/
  economy/
  inventory/
  mahjong/
    domain/
    application/
    ai/
    presentation/
  farm/
  crops/
  animals/
  fishing/
  horses/
  ui/
  accessibility/
  story/
  testing/

data/
  brands/
  deeds/
  opponents/
  crops/
  fish/
  items/
  recipes/
  regions/
  schedules/
  quests/
  dialogue/
  localization/

tests/
  unit/
  integration/
  fixtures/
```

### Autoload policy

Use autoloads only for truly cross-scene services. Prefer a small set:

- `SceneRouter`
- `SaveService`
- `AudioService`
- `InputService`
- `ContentRegistry`
- `GameSession`

Keep clocks, weather, quests, inventory, and other state owned by `GameSession` or scoped scene services rather than creating a global singleton for every system.

### Core requirements

- Typed GDScript
- Explicit signals
- No stringly typed global event soup
- Versioned data schemas
- Deterministic RNG streams
- Dependency injection through constructors, setup methods, or scene composition
- Data-driven content
- No hard-coded dialogue in scene scripts
- No hard-coded item databases in UI scripts
- No scene that owns authoritative save logic

### Testing foundation

Create a native headless test runner that can execute pure GDScript tests without requiring a third-party testing plugin.

Minimum commands:

```bash
godot --headless --path . -s res://tests/test_runner.gd
python tools/validate_repository.py
```

### Exit gate

- Architecture folders and interfaces exist.
- A basic game session can start and end.
- Test runner works.
- No handwritten file exceeds policy without a recorded exception.

---

## 11. Phase G — Runtime asset catalogs and generation

### Goal

Convert the supplied source library into predictable runtime resources without manually wiring thousands of files.

### Required pipelines

#### Hero

Generate or configure:

- Four-direction walk
- Breathing idle
- Accelerated walk used as run
- Gun draw
- Armed still
- Shooting
- Animation metadata
- Collision footprint
- Shadow toggle

#### Horses

Catalog:

- Black
- Brown
- Golden
- Gray
- White

Create directional animation mappings and horse replacement-travel resources.

#### Mahjong

Create a deterministic core atlas pipeline for:

- 34 traditional identities
- 6 Brand colors
- Horizontal and vertical orientations
- Raw face layers
- Brand symbols
- Colorblind patterns
- Selected state
- Legal-action highlight
- Locked state
- High Noon state
- Tutorial ghost
- Opponent-hidden back

Do not load 2,220 independent SVG resources during every match. Generate compact atlases and a manifest.

#### World

Create source-pack metadata for:

- Wayward Farm
- Bridlewood Ranch
- Dustward
- Saint’s Landing
- Ironhook Docks
- Gull’s Rest
- Red Testament / King’s Reach

#### Audio

Build categorized buses and event maps:

- Music
- Ambience
- SFX
- Mahjong callouts
- UI

### Exit gate

- Runtime code resolves assets through catalogs, not handwritten file paths.
- Atlas generation is deterministic.
- Missing mappings fail validation.
- Source and generated assets remain distinguishable.

---

## 12. Phase H — Player, camera, interaction, and controls

### Goal

Make Doc controllable and production-ready before building content on top of him.

### Tasks

- Four-direction movement
- Accelerated walk animation for running
- Analog stick dead-zone handling
- Keyboard and controller parity
- Interaction detection
- Context prompt
- Collision and terrain layers
- Camera bounds and transitions
- Indoor/outdoor entry handling
- Pause
- Input remapping foundation
- Controller glyph switching
- Footstep surface routing
- Gun animations callable only by story state
- No conventional attack controls in launch gameplay

### Acceptance criteria

- Doc moves correctly at 60 FPS.
- Diagonal movement is normalized.
- Controller focus never becomes trapped.
- Prompts change with active input device.
- Doors and map edges cannot double-trigger.
- Movement state survives save/load correctly.
- Run animation does not visually skip or desynchronize.

---

## 13. Phase I — Time, weather, save, and world state

### Goal

Build the systems that every other feature depends on.

### Time

- 60 real-time minutes per complete in-game day before pauses
- Pause during dialogue, menus, Mahjong, and cutscenes
- Full match costs 90 in-game minutes
- Night has no forced penalty
- Inn sleep and outdoor bonfire sleep
- Events roll forward rather than disappearing

### Weather

Implement vertical-slice weather first:

- Clear
- Rain

Architect data for:

- Cloudy
- Thunderstorm
- Dust wind
- Supernatural fog

### Save

Implement:

- Six manual slots
- One autosave
- One rotating emergency backup
- Versioned schema
- Atomic write
- Backup before migration
- Checksum or integrity marker
- Recovery path
- Separate pre-finale save
- Safe save restrictions

### Exit gate

- Time advances and pauses correctly.
- Weather changes visuals, ambience, and system modifiers.
- Save/load round-trips every current system.
- Corrupted primary save falls back to backup.
- No event becomes permanently unavailable due to time.

---

## 14. Phase J — Trail Rules Mahjong domain

### Goal

Implement the first complete, deterministic, test-heavy version of Six Brands Mahjong.

### Domain modules

Prefer small files such as:

```text
tile_identity.gd
brand_id.gd
mahjong_tile.gd
wall_builder.gd
hand_state.gd
meld.gd
trail_hand_validator.gd
claim_resolver.gd
turn_state.gd
match_seed.gd
match_replay_log.gd
renown_calculator.gd
deed_evaluator.gd
high_noon_state.gd
match_flow.gd
```

### Trail Rules requirements

- 11-tile structure
- Three groups plus one pair
- 102-tile wall
- Three copies per traditional identity
- Exactly 17 tiles from each Brand
- Runs
- Matching Sets
- Honor pairs and Sets
- No quads
- Four named hands plus tie Showdown
- Alternating dealer
- Legal winning-discard claim
- Brand-dependent non-winning claims
- Open hand has no automatic penalty
- Deterministic seed
- Complete replay history

### Test matrix

At minimum:

- Valid and invalid Runs
- Valid and invalid Sets
- Honors
- Multiple decomposition paths
- Duplicate identities with different Brands
- Wall color balance
- Exhausted wall
- Winning claim precedence
- Tie Showdown
- Deterministic replay
- Invalid action rejection
- High Noon entry and expiration

### Exit gate

- Domain logic runs without UI.
- Every match can be reconstructed from a seed and action log.
- Hundreds or thousands of generated hands can be validated without crashes.
- AI and UI cannot bypass domain legality.

---

## 15. Phase K — Orange, Blue, High Noon, AI, and tutorial

### Orange — High Noon Brand

- Special claim: complete any group
- Cost: grant opponent one Brand charge
- Active: draw two, keep one, return the other to the bottom

### Blue — River Brand

- Special claim: complete a Run
- Active: retrieve one of the player’s two latest discards, then discard another

### Shared Brand rules

- Player selects two unlocked Brands before a match
- Loadout is locked for the full match
- Charges reset every hand
- Three charges create one activation
- Two activations maximum per Brand
- Discarding a matching Brand charges it
- Every activation is logged

### High Noon

- Available one tile from victory
- Locks hand
- Disables Brand powers
- Three-draw visible countdown
- Major Renown bonus
- Opponent counter window
- Failed declaration releases the hand without destroying it

### AI

Create separate modules for:

- Visible knowledge
- Memory
- Candidate generation
- Hand evaluation
- Risk evaluation
- Brand strategy
- Personality weights
- Action selection

The AI must never access hidden wall order or concealed tiles except through visible abilities.

### Tenderfoot tutorial

Teach through play:

1. Tile identities
2. Draw and discard
3. Runs
4. Sets
5. Pair
6. Claims
7. Brands
8. Orange ability
9. Blue ability
10. High Noon
11. Deeds and Renown
12. Wagers

### Exit gate

- A first-time player can finish a match without external Mahjong knowledge.
- AI visibly follows the same rules.
- Advice explanations are accurate.
- Undo restores a legal prior state.
- Full match length can be tuned toward 15–25 minutes.

---

## 16. Phase L — Farming and free placement

### Goal

Deliver a real farm loop rather than decorative planting.

### Vertical-slice crop scope

Activate four crops first while cataloging all twenty supplied crops.

### Required states

- Seed
- Planted
- Watered
- Growth stages
- Ready
- Wilted
- Recovered
- Dead
- Harvested

### Placement

Support free grid placement for:

- Fields
- Paths
- Fences
- Decorations
- Machines
- Pens
- Most constructed buildings

Reject:

- Invalid terrain
- Overlap
- Blocked doors
- Sealed exits
- Inaccessible animals
- Occupied water
- Permanent story objects
- Complete NPC route blockage

Use dynamic navigation updates and validation previews.

### Exit gate

- Crops survive save/load.
- Wilt and recovery work.
- Neglect can eventually kill crops.
- Placement cannot softlock the map.
- Structures can be relocated safely.

---

## 17. Phase M — Fishing overlay

### Goal

Implement the supplied fishing mechanics as a world-integrated system.

### States

1. Aim
2. Cast
3. Wait
4. Bite
5. Hook set
6. Directional struggle
7. Catch
8. Escape
9. Presentation
10. Cleanup

### Controls

- Left stick: counter pull
- Right trigger: reel
- Left trigger: release tension
- A/Cross: hook set or short pull
- Right stick: rod angle
- Vibration: bite and tension feedback

### Vertical-slice content

- One river or coastal location
- Six to eight fish
- Rod, bait, lure, hook, and line data
- Time and weather conditions
- World view remains visible
- Overlay occupies one side
- Catch card
- Record update
- Beginner failure can cost only time

### Exit gate

- Fishing works with keyboard and controller.
- Tension is readable without relying only on color.
- Fish behavior is deterministic enough for testing but varied in play.
- UI never blocks the world-side bobber and line.
- Catch results feed inventory, records, and economy.

---

## 18. Phase N — Horse travel

### Goal

Implement launch horse travel without waiting for mounted Doc artwork.

### Flow

1. Doc approaches horse.
2. Interaction locks movement.
3. Short fade.
4. Doc is hidden.
5. Selected horse becomes controlled character.
6. Speed increases.
7. Hitching posts support fast travel.
8. Dismount validates a safe position.
9. Doc returns.

### Exit gate

- All five horse colorways are cataloged.
- One colorway is active in the slice.
- Fast travel only uses discovered posts.
- Horse cannot enter invalid interiors or narrow spaces.
- Save/load preserves selected horse and travel state safely.

---

## 19. Phase O — Vertical-slice world and narrative

### Required playable locations

- Wayward Farm
- Dustward
- First river or coastal fishing area
- Three complete interiors

### Required content

- Three Mahjong opponents
- One full multi-stage NPC storyline
- First hall-restoration milestone
- Shipping crate
- General store interaction
- One helper unlock
- One property or access dispute
- Clear and rainy schedules
- One bonfire
- One inn sleep path
- One horse fast-travel link

### Map construction

Use the source-pack construction method appropriate to each location:

- Scrolling maps where tilesets support it
- Fixed-screen layouts where large backgrounds require it
- Brief transitions between incompatible asset packs

Use shared lighting, signage, roads, shoreline treatment, and color grading to unify art.

### Exit gate

A new player can:

1. Start at Wayward Farm.
2. Move to Dustward.
3. Plant and harvest.
4. Fish.
5. Meet and challenge three opponents.
6. Complete one substantial story arc.
7. Unlock one helper.
8. Restore the first part of the hall.
9. Save and reload.
10. Continue without fake doors, disconnected menus, or placeholder systems.

---

## 20. Phase P — Integration, QA, export, and pull request

### Automated checks

Run:

```bash
python tools/validate_repository.py
godot --headless --path . -s res://tests/test_runner.gd
godot --headless --editor --path . --quit
```

Add focused checks for:

- Broken resources
- Missing input actions
- Over-300-LOC handwritten files
- Invalid data resources
- Save round-trip
- Mahjong replay determinism
- Placement route safety
- Crop state transitions
- Fishing state transitions
- Controller focus traversal

### Manual test passes

- New game
- Save/load
- Controller-only navigation
- Keyboard-only navigation
- Windowed/borderless/fullscreen
- 960×540 and 1920×1080
- Clear-to-rain transition
- Full Mahjong match
- High Noon
- Farm placement
- Crop death/recovery
- Fishing catch/escape
- Horse mount/dismount/fast travel
- NPC schedule changes
- Hall milestone
- Audio bus controls

### Windows export

Produce a development export and verify:

- Launches on a clean Windows user profile
- No missing DLL or asset
- Save path works
- Controller hot-plug works
- Alt-tab recovery works
- No development-only absolute paths
- No vendor archives packaged

### Git workflow

1. Keep commits focused.
2. Push `agent/hybrid-vertical-slice`.
3. Open a draft PR into `develop`.
4. Include:
   - Systems implemented
   - Validation results
   - Known limitations
   - Screenshots or capture
   - Save compatibility note
   - File-size exceptions
5. Do not mark ready until all exit gates pass.

---

## 21. Required commit sequence

A sensible sequence is:

1. `Verify local toolchain and source archives`
2. `Add deterministic master asset importer`
3. `Add core game architecture and test runner`
4. `Add runtime asset catalogs and Mahjong atlases`
5. `Implement player movement and interaction`
6. `Implement time weather and versioned saves`
7. `Implement Trail Rules Mahjong domain`
8. `Implement Orange Blue and High Noon`
9. `Add first Mahjong AI and Tenderfoot tutorial`
10. `Implement farm placement and crop loop`
11. `Implement fishing overlay and fish data`
12. `Implement horse travel and hitching posts`
13. `Author vertical slice maps and storyline`
14. `Validate and export hybrid vertical slice`

Combine commits only when the result remains reviewable and coherent.

---

## 22. Codex completion report

At the end, Codex must report:

```text
Branch:
Latest commit:
Pull request:
Godot version:
Python version:
Asset archives found:
Asset archives missing:
Supplemental import result:
Master import result:
Repository validation:
Godot headless import:
Automated tests:
Windows export:
Playable content completed:
Known defects:
Deferred full-game work:
Files over 300 LOC:
Save schema version:
```

Do not claim completion when a required exit gate has not passed.

---

## 23. Definition of done

The Codex execution is complete only when:

- The repository is locally reproducible from the recorded source archives.
- Godot 4.7.1 opens without script or resource errors.
- Foundation work is integrated into `develop`.
- A focused vertical-slice branch and PR exist.
- Wayward Farm, Dustward, and the first fishing location are connected and playable.
- Doc can move, run, interact, save, farm, fish, ride, and play a full Trail Rules match.
- Orange, Blue, and High Noon work legally and deterministically.
- Three distinct opponents are playable.
- One substantial NPC storyline and one helper unlock are complete.
- The first Six Brands Hall restoration milestone is complete.
- Keyboard and controller paths work.
- Automated validation passes.
- A Windows development build launches cleanly.
- No large source archive is committed.
- No project-owned handwritten file violates the size policy without a justified exception.
