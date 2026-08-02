#!/usr/bin/env python3
"""Verify, extract, normalize, and catalog the local master split ZIP archive."""

from __future__ import annotations

import argparse
import json
import shutil
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from master_import.archive_parts import inspect_archive_set, validate_pinned_records
from master_import.archive_verifier import resolve_seven_zip, test_archive
from master_import.catalog_builder import build_catalog
from master_import.extractor import extract_archive
from master_import.path_normalizer import hash_file, normalize_tree


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "assets" / "manifests" / "master_source_archives.json"
DEFAULT_SOURCE = ROOT / "vendor" / "local" / "master"
DEFAULT_EXPANDED_SOURCE = ROOT / "assets" / "MahjongRPG"
TARGET = ROOT / "assets" / "source" / "master"
LOCAL_ARTIFACTS = ROOT / "artifacts" / "local"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def tree_digest(root: Path) -> str:
    import hashlib

    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        if path.is_file() and path.name != ".import_complete.json":
            relative = path.relative_to(root).as_posix().encode("utf-8")
            digest.update(relative + b"\0" + hash_file(path).encode("ascii") + b"\n")
    return digest.hexdigest()


def atomic_replace(staging: Path) -> None:
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    backup = TARGET.with_name(TARGET.name + ".backup")
    if backup.exists():
        shutil.rmtree(backup)
    if TARGET.exists():
        TARGET.replace(backup)
    staging.replace(TARGET)
    if backup.exists():
        shutil.rmtree(backup)


def generated_dynamite_bill_status() -> dict[str, Any]:
    patch = ROOT / "assets" / "generated" / "npcs" / "dynamite_bill" / "rotations" / "east.png"
    if not patch.is_file():
        raise RuntimeError("Missing generated Dynamite Bill east-facing correction")
    data = patch.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise RuntimeError("Generated Dynamite Bill east-facing correction is not PNG data")
    return {"fallback_path": patch.relative_to(ROOT).as_posix(), "sha256": hash_file(patch)}


def verify(source_dir: Path, manifest: dict[str, Any], seven_zip: str) -> tuple[list[dict[str, Any]], bool]:
    observed = inspect_archive_set(source_dir, manifest)
    pinned = validate_pinned_records(manifest, observed)
    test_archive(source_dir / "MahjongRPG.zip", seven_zip)
    return observed, pinned


def import_assets(extracted: Path, source_record: dict[str, Any]) -> None:
    with tempfile.TemporaryDirectory(prefix="six_brands_master_") as temp_name:
        temporary = Path(temp_name)
        staging = temporary / "normalized"
        staging.mkdir()
        mapping, duplicates = normalize_tree(extracted, staging)
        catalog = build_catalog(staging)
        marker = {
            "schema": 1,
            "imported_at": datetime.now(timezone.utc).isoformat(),
            "source": source_record,
            "output_tree_sha256": tree_digest(staging),
            "dynamite_bill": generated_dynamite_bill_status(),
        }
        write_json(staging / ".import_complete.json", marker)
        atomic_replace(staging)
    write_json(LOCAL_ARTIFACTS / "master_asset_catalog.json", catalog)
    write_json(LOCAL_ARTIFACTS / "master_duplicate_report.json", {"schema": 1, "duplicates": duplicates})
    write_json(LOCAL_ARTIFACTS / "master_collision_report.json", {"schema": 1, "paths": mapping})


def catalog_expanded_source(source_dir: Path) -> dict[str, Any]:
    if not source_dir.is_dir():
        raise FileNotFoundError(f"Missing expanded master asset directory: {source_dir}")
    if not any(path.is_file() for path in source_dir.rglob("*")):
        raise RuntimeError(f"Expanded master asset directory contains no files: {source_dir}")
    catalog = build_catalog(source_dir)
    catalog["source_root"] = source_dir.relative_to(ROOT).as_posix() if source_dir.is_relative_to(ROOT) else source_dir.name
    catalog["dynamite_bill"] = generated_dynamite_bill_status()
    return catalog


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive-source-dir", type=Path)
    parser.add_argument("--expanded-source-dir", type=Path, default=DEFAULT_EXPANDED_SOURCE)
    parser.add_argument("--manifest", type=Path, default=MANIFEST)
    parser.add_argument("--seven-zip")
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--import-normalized", action="store_true")
    parser.add_argument("--write-observed-manifest", type=Path)
    args = parser.parse_args()

    if not args.archive_source_dir:
        if args.write_observed_manifest:
            parser.error("--write-observed-manifest requires --archive-source-dir")
        catalog = catalog_expanded_source(args.expanded_source_dir)
        write_json(LOCAL_ARTIFACTS / "master_asset_catalog.json", catalog)
        print(f"Cataloged {catalog['file_count']} expanded master assets from {catalog['source_root']}")
        if args.verify_only or not args.import_normalized:
            return 0
        import_assets(args.expanded_source_dir, {"kind": "expanded_directory", "path": catalog["source_root"]})
        print(f"Normalized expanded master assets to {TARGET}")
        return 0

    manifest = load_json(args.manifest)
    seven_zip = resolve_seven_zip(args.seven_zip)
    observed, pinned = verify(args.archive_source_dir, manifest, seven_zip)
    if args.write_observed_manifest:
        write_json(args.write_observed_manifest, {"schema": 1, "archives": observed})
    if not pinned:
        print("Master archive integrity passed, but the committed fingerprint manifest is not yet pinned.")
    else:
        print("Verified pinned master archive fingerprints and split ZIP integrity.")
    if args.verify_only:
        return 0
    if not pinned:
        raise RuntimeError("Refusing import until the committed master archive fingerprint manifest is pinned")
    with tempfile.TemporaryDirectory(prefix="six_brands_master_extract_") as temp_name:
        extracted = extract_archive(args.archive_source_dir / "MahjongRPG.zip", Path(temp_name) / "extracted", seven_zip)
        import_assets(extracted, {"kind": "pinned_archives", "archives": observed})
    print(f"Imported master assets to {TARGET}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
