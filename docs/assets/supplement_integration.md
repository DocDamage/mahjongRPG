# Supplemental Asset Integration

## Canonical expanded source tree

The normal local source is already expanded under the repository's ignored `assets/` tree:

```text
assets/Hero - Cowboy - AssetPack/
assets/horses/
assets/fishing UI/
assets/Cozy SFX Volume 1/
```

Verify these four directories without changing imported content:

```powershell
python tools/import_supplemental_assets.py --expanded-source-dir assets --verify-only
```

## Optional archive provenance

When provided, place the four original ZIPs in:

```text
vendor/local/supplemental/
```

Their names and SHA-256 values are recorded in `manifests/supplemental_source_archives.json`. Archive verification is provenance checking; it is not required when the canonical expanded source tree above is available.

## Import

```bash
python tools/import_supplemental_assets.py
```

The importer:

1. Reads the canonical expanded source directories under `assets/`
2. Rejects unsafe paths
3. Normalizes names to lowercase snake case
4. Imports Doc, horses, and fishing UI
5. Requires `ffmpeg` with a Vorbis encoder only when converting long ambience to OGG
6. Trims the anomalous stone footstep to 0.50 seconds
7. Excludes demo video, demo track, and bonus music
8. Atomically replaces `assets/source/supplemental/`
9. Writes an import marker with checksums

Use `--archive-source-dir vendor/local/supplemental --verify-only` to validate ZIP provenance without extracting.

## Generated correction

Tracked file:

```text
assets/generated/npcs/dynamite_bill/rotations/east.png
```

Generation rule: horizontal mirror of the original west-facing 92×92 RGBA image.

## Hero mapping

- Cell: 64×64
- Walk: 8 frames per direction
- Breathing idle: 15 frames per direction
- Draw: 6 frames per direction
- Shoot: 3 frames per direction
- Run: accelerated walk playback for launch

## Horse mapping

- Cell: 128×128
- Four columns
- Twenty rows
- Five colorways
- Row mapping requires a Godot data resource before integration

## Fishing mapping

- Rod sheet: 768×512
- Cell: 64×64
- Grid: 12×8
- Rows cover prepare, cast, idle, hook, reel, catch, and one extra state

The supplied directional-arrow language will be adapted into the planned tug-of-war mechanic rather than copied as a separate rhythm game.
