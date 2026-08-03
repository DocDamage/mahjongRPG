#!/usr/bin/env python3
"""Validate the versioned Windows release-candidate contract and optional package."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
METADATA = ROOT / "data" / "release" / "release_candidate.json"
REQUIRED_DOCUMENTS = (
    ROOT / "docs" / "release" / "RELEASE_NOTES.md",
    ROOT / "docs" / "release" / "setup_and_recovery.md",
    ROOT / "docs" / "release" / "release_candidate_evidence.md",
    ROOT / "legal" / "THIRD_PARTY_ASSET_LICENSE_CC0.txt",
    ROOT / "legal" / "PROPRIETARY_SOURCE_NOTICE.md",
)


def game_schema() -> int:
    source = (ROOT / "src" / "core" / "game_session.gd").read_text(encoding="utf-8")
    match = re.search(r"SAVE_SCHEMA_VERSION := (\d+)", source)
    return int(match.group(1)) if match else -1


def validate_metadata(data: dict) -> list[str]:
    errors: list[str] = []
    if data.get("schema_version") != 1:
        errors.append("release metadata schema_version must be 1")
    if not re.fullmatch(r"\d+\.\d+\.\d+-rc\.\d+", str(data.get("version", ""))):
        errors.append("release metadata version must be an rc semantic version")
    if not re.fullmatch(r"\d+\.\d+\.\d+", str(data.get("engine_project_version", ""))):
        errors.append("engine project version must be numeric for Godot export metadata")
    if data.get("engine_version") != "4.7.1":
        errors.append("release metadata must target Godot 4.7.1")
    save_schema = data.get("save_schema", {})
    if save_schema.get("minimum_supported") != 1 or save_schema.get("current") != game_schema():
        errors.append("release metadata save-schema range does not match GameSession")
    if data.get("settings_schema", {}).get("current") != 2:
        errors.append("release metadata must record settings schema 2")
    package = data.get("package", {})
    if package.get("executable") != "SixBrandsAtHighNoon.exe" or package.get("data") != "SixBrandsAtHighNoon.pck":
        errors.append("release metadata package names do not match the Windows preset")
    return errors


def validate_package(package_dir: Path, metadata: dict) -> list[str]:
    errors: list[str] = []
    package = metadata["package"]
    for name in [package["executable"], package["data"], *package["documents"], "SHA256SUMS.txt"]:
        path = package_dir / name
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"release package is missing {name}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-dir", type=Path, help="validate a built package directory")
    args = parser.parse_args()
    errors: list[str] = []
    try:
        metadata = json.loads(METADATA.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"Unable to read release metadata: {error}", file=sys.stderr)
        return 1
    errors.extend(validate_metadata(metadata))
    for path in REQUIRED_DOCUMENTS:
        if not path.is_file() or not path.read_text(encoding="utf-8").strip():
            errors.append(f"missing or empty release document: {path.relative_to(ROOT)}")
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    if f'config/version="{metadata["engine_project_version"]}"' not in project:
        errors.append("project version does not match release metadata")
    if args.package_dir:
        errors.extend(validate_package(args.package_dir, metadata))
    if errors:
        print("Release-candidate validation failed:", file=sys.stderr)
        print(*[f"- {error}" for error in errors], sep="\n", file=sys.stderr)
        return 1
    print("Release-candidate validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
