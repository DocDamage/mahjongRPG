# Asset Status

## Main source assets

The canonical master source is the expanded `assets/MahjongRPG/` tree. The repository's catalog verifier reports 4,430 master asset files from that tree.

Historical archive-provenance records (not a normal checkout requirement) record that the reconstructed source archive passed CRC validation:

- 5,791 archive entries tested
- 4,607 extracted files inventoried
- No missing split volumes
- No CRC failures
- Approximately 838 MiB reconstructed archive size

Original master archive parts remain outside Git and are optional provenance inputs.

## World coverage

The collection supports the seven planned regions:

| Region | Primary source material |
|---|---|
| Wayward Farm | Ranch and cozy farm assets |
| Bridlewood Ranch | Ranch kit and Western props |
| Dustward | Wild West packs 1 and 2 |
| Saint's Landing | 19th Century European City |
| Ironhook Docks | 19th Century European Dock |
| Gull's Rest | Coastal Fishing Village Port |
| Red Testament / King's Reach | Desert and selected Western structures |

A shared lighting, signage, path, shoreline, and color-grading pass will unify the source packs.

## Mahjong

The collection contains 2,220 SVG assets covering:

- Blue, Dark, Green, Orange, Pink, and Purple
- Horizontal and vertical forms
- The traditional core 34 identities
- Transparent raw face layers
- Physical tile-body variants
- Additional optional themed pieces

The raw faces support generated atlases, Brand marks, colorblind patterns, tutorial ghosts, locked states, highlights, and supernatural variants.

The vertical slice now generates `assets/generated/mahjong/trail_rules_faces.png`: one compact 34-face Trail Rules atlas. The table resolves atlas regions at runtime and applies the six Brand colors in presentation, avoiding per-match SVG loading.

## Crops and animals

Animated crop material covers twenty launch candidates, including vegetables, grain, fruit, bamboo, and tallgrass. Most provide approximately six to eight growth states.

All twenty ranch crop candidates are cataloged in the runtime crop data. The vertical slice intentionally activates only beans, corn, tomato, and wheat; the remaining source-backed candidates stay data-validated but unavailable until their economy and art presentation are authored.

Animated animal material includes birds, bunnies, cats, cows, foxes, mice, pigs, eggs, and fireflies. Additional static livestock will require derived animation before being presented as active animals.

## Supplemental visual assets

The verified expanded supplemental source directories add:

- Doc's four-direction 64×64 hero animations
- Idle, walk, gun draw, armed still, and shooting states
- Editable Aseprite source
- Five 128×128-cell horse colorways
- Fishing rod states, directional prompts, fish, gear, store icons, and catch presentation
- Generated Dynamite Bill east rotation

The runtime generator promotes the canonical expanded asset folders into tracked, reproducible game assets:

- Five hero action sheets in each cardinal direction: walk, breathing idle, gun draw, armed still, and shooting
- Black, brown, golden, gray, and white horse sheets
- A data-driven runtime catalog at `data/runtime_assets/vertical_slice_assets.json`

Running initially accelerates the existing walk cycle. Farming, table, carrying, sleeping, and helper animations remain authored production work based on the supplied style.

## Supplemental audio

`Cozy SFX Volume 1` provides:

- Six ambience recordings
- Grass, gravel, stone, and wood footsteps
- Fabric, leaves, water, and wood interactions
- Bee and bird one-shots
- Pickup, click, hover, notification, and level-up UI sounds

During import, long ambience is converted to OGG, the anomalous stone footstep is trimmed, and demo media plus bonus music are excluded from the runtime-oriented output.

The vertical slice promotes these verified `Cozy SFX Volume 1` outputs into tracked runtime assets:

- `assets/generated/audio/outdoor_generic_ambience.ogg`
- `assets/generated/audio/rain_ambience.ogg`
- `assets/generated/audio/footstep_grass.wav`
- `assets/generated/audio/footstep_gravel.wav`
- `assets/generated/audio/footstep_wood.wav`
- `assets/generated/audio/mahjong_tile_wood.wav`

They are mapped by `data/audio/vertical_slice_audio.json`; the ignored `assets/source/supplemental/` copies remain import inputs only.

Dedicated revolver, horse, livestock, door, bonfire, and specialized fishing-line sounds remain polish tasks, not foundation blockers.

## License

The user-supplied universal license allows commercial and non-commercial use, modification, remixing, redistribution, optional attribution, and a CC0 public-domain dedication with a broad fallback license. It is stored under `legal/`.
