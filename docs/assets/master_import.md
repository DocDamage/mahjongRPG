# Master asset import

The expanded source library at `assets/MahjongRPG/` is the normal local input for this checkout. It is ignored by Git and is cataloged in place, so the project does not need a second copy of the archive or an 800+ MiB normalized duplicate.

## First audit

Catalog and validate the expanded source library:

```powershell
python tools/import_master_assets.py --verify-only
```

This writes the machine-readable asset catalog without changing the source library. It also verifies that the generated Dynamite Bill east-facing correction is available for use when the source pack has no east pose.

## Import

```powershell
python tools/import_master_assets.py --import-normalized
```

Use `--import-normalized` only when a normalized copy is required for a specific runtime-generation pipeline. Unsafe, cache, macOS metadata, and import-cache files are excluded. Remaining paths are normalized without overwriting collisions, then atomically replace `assets/source/master/`.

## Optional archive verification

The historical split archive path remains available when it is needed to audit a new source package. Keep all nine parts outside Git in `vendor/local/master/`, then run:

```powershell
python tools/import_master_assets.py --archive-source-dir vendor/local/master --verify-only --write-observed-manifest artifacts/local/master_observed_archives.json
```

Compare the generated fingerprint record with the confirmed source package before adding it to `master_source_archives.json`. The archive mode deliberately refuses a full import until that committed manifest is pinned to the verified archive revision.

The import writes an ignored marker and local reports:

- `assets/source/master/.import_complete.json`
- `artifacts/local/master_asset_catalog.json`
- `artifacts/local/master_duplicate_report.json`
- `artifacts/local/master_collision_report.json`

Run the import twice and compare the `output_tree_sha256` marker value; it excludes the import timestamp and must be identical for the same archive revision.
