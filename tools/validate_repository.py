#!/usr/bin/env python3
"""Validate repository size, source length, manifests, and generated patch."""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAX_BYTES = 95 * 1024 * 1024
MAX_LINES = 300
WARNING_LINES = 250
SOURCE_EXTENSIONS = {".gd", ".py", ".cs", ".js", ".ts", ".tsx", ".jsx", ".sh"}
EXCLUDED_PREFIXES = (
    ".git/",
    ".godot/",
    "assets/source/",
    "assets/MahjongRPG/",
    "vendor/local/",
    "artifacts/local/",
    "exports/",
    ".godot-bin/",
    ".template-unpack/",
)
REQUIRED = (
    "project.godot",
    "legal/THIRD_PARTY_ASSET_LICENSE_CC0.txt",
    "docs/assets/manifests/supplemental_source_archives.json",
    "docs/assets/manifests/master_source_archives.json",
    "docs/assets/master_import.md",
    "docs/architecture/file_size_policy.md",
    "assets/generated/npcs/dynamite_bill/rotations/east.png",
    "tools/import_master_assets.py",
    "data/release/release_candidate.json",
    "docs/release/RELEASE_NOTES.md",
    "docs/release/release_candidate_evidence.md",
    "tools/verify_release_candidate.py",
    "tools/package_windows_release.py",
    ".pre-commit-config.yaml",
    "tools/validate_content.gd",
    "tools/run_content_validation.ps1",
    "tools/precommit_project_checks.py",
    "docs/contributing/content-validation.md",
)
MASTER_ARCHIVE_NAMES = (
    "MahjongRPG.z01",
    "MahjongRPG.z02",
    "MahjongRPG.z03",
    "MahjongRPG.z04",
    "MahjongRPG.z05",
    "MahjongRPG.z06",
    "MahjongRPG.z07",
    "MahjongRPG.z08",
    "MahjongRPG.zip",
)
RUNTIME_HERO_ACTIONS = ("walk", "idle", "draw", "armed", "shoot")
RUNTIME_HERO_FRAME_COUNTS = {"walk": 8, "idle": 15, "draw": 6, "armed": 1, "shoot": 3}
RUNTIME_DIRECTIONS = ("up", "down", "left", "right")
RUNTIME_HORSE_COLORS = ("black", "brown", "golden", "gray", "white")
MAHJONG_ATLAS_PATH = "assets/generated/mahjong/trail_rules_faces.png"
RELEASE_UI_ART = ("menu_closed.png", "inventory_slot.png", "attention_marker.png")
RELEASE_AUDIO = ("ui_confirm.wav", "ui_focus.wav", "journal_updated.wav", "item_pickup.wav", "crop_water.wav", "crop_harvest.wav", "door_open.wav", "animal_care.wav", "fishing_catch.wav", "mahjong_win.wav", "music_theme.wav")


def relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def excluded(path: Path) -> bool:
    rel = relative(path)
    return rel.startswith(EXCLUDED_PREFIXES)


def check_required(errors: list[str]) -> None:
    for rel in REQUIRED:
        if not (ROOT / rel).is_file():
            errors.append(f"Missing required file: {rel}")


def check_files(errors: list[str], warnings: list[str]) -> None:
    for path in ROOT.rglob("*"):
        if not path.is_file() or excluded(path):
            continue
        rel = relative(path)
        if path.stat().st_size > MAX_BYTES:
            errors.append(f"File exceeds 95 MiB: {rel}")
        if path.suffix.lower() in SOURCE_EXTENSIONS:
            try:
                lines = len(path.read_text(encoding="utf-8").splitlines())
            except UnicodeDecodeError:
                errors.append(f"Source is not UTF-8: {rel}")
                continue
            if lines > MAX_LINES:
                errors.append(f"Handwritten source exceeds 300 LOC: {rel} ({lines})")
            elif lines >= WARNING_LINES:
                warnings.append(f"Handwritten source is at the 250 LOC review threshold: {rel} ({lines})")


def check_manifest(errors: list[str]) -> None:
    path = ROOT / "docs/assets/manifests/supplemental_source_archives.json"
    if not path.is_file():
        return
    data = json.loads(path.read_text(encoding="utf-8"))
    expected = {"hero", "horses", "fishing_ui", "cozy_sfx"}
    actual = {entry.get("kind") for entry in data.get("archives", [])}
    if actual != expected:
        errors.append(f"Supplement manifest kinds differ: {sorted(actual)}")
    for entry in data.get("archives", []):
        digest = entry.get("sha256", "")
        if len(digest) != 64 or any(ch not in "0123456789abcdef" for ch in digest):
            errors.append(f"Invalid SHA-256 for {entry.get('file')}")


def check_master_manifest(errors: list[str]) -> None:
    path = ROOT / "docs/assets/manifests/master_source_archives.json"
    if not path.is_file():
        return
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        errors.append(f"Invalid master archive manifest JSON: {error}")
        return
    if tuple(data.get("required_files", ())) != MASTER_ARCHIVE_NAMES:
        errors.append("Master archive manifest filenames differ from the required split ZIP set")
    archives = data.get("archives", [])
    if archives and {entry.get("file") for entry in archives} != set(MASTER_ARCHIVE_NAMES):
        errors.append("Pinned master archive manifest is incomplete")


def check_patch(errors: list[str]) -> None:
    path = ROOT / "assets/generated/npcs/dynamite_bill/rotations/east.png"
    if not path.is_file():
        return
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        errors.append("Dynamite Bill east patch is not a valid PNG header")
        return
    width, height = struct.unpack(">II", data[16:24])
    if (width, height) != (92, 92):
        errors.append(f"Dynamite Bill east patch is {width}x{height}, expected 92x92")


def check_runtime_catalog(errors: list[str]) -> None:
    path = ROOT / "data" / "runtime_assets" / "vertical_slice_assets.json"
    if not path.is_file():
        errors.append("Missing runtime asset catalog")
        return
    try:
        catalog = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        errors.append(f"Invalid runtime asset catalog JSON: {error}")
        return
    hero = catalog.get("hero", {})
    horses = catalog.get("horses", {})
    if tuple(hero.get("actions", ())) != RUNTIME_HERO_ACTIONS or tuple(hero.get("directions", ())) != RUNTIME_DIRECTIONS:
        errors.append("Runtime hero catalog mappings differ from the required action and direction set")
    if hero.get("frame_counts") != RUNTIME_HERO_FRAME_COUNTS:
        errors.append("Runtime hero catalog frame counts differ from the approved sheets")
    if tuple(horses.get("colors", ())) != RUNTIME_HORSE_COLORS:
        errors.append("Runtime horse catalog mappings differ from the required color set")
    for direction in RUNTIME_DIRECTIONS:
        for action in RUNTIME_HERO_ACTIONS:
            path = ROOT / "assets" / "generated" / "player" / f"cowboy_{direction}_{action}.png"
            if not path.is_file():
                errors.append(f"Missing generated hero asset: {relative(path)}")
    for color in RUNTIME_HORSE_COLORS:
        path = ROOT / "assets" / "generated" / "horses" / f"horse_{color}.png"
        if not path.is_file():
            errors.append(f"Missing generated horse asset: {relative(path)}")


def check_mahjong_atlas(errors: list[str]) -> None:
    catalog_path = ROOT / "data" / "mahjong" / "vertical_slice_tile_atlas.json"
    atlas_path = ROOT / MAHJONG_ATLAS_PATH
    if not catalog_path.is_file() or not atlas_path.is_file():
        errors.append("Missing Trail Rules Mahjong atlas or catalog")
        return
    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        errors.append(f"Invalid Trail Rules Mahjong atlas JSON: {error}")
        return
    if catalog.get("cell_size") != [48, 64] or catalog.get("columns") != 1 or catalog.get("rows") != 34:
        errors.append("Trail Rules Mahjong atlas dimensions differ from the required 34-face layout")
        return
    data = atlas_path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        errors.append("Trail Rules Mahjong atlas is not a valid PNG header")
        return
    width, height = struct.unpack(">II", data[16:24])
    if (width, height) != (48, 2176):
        errors.append(f"Trail Rules Mahjong atlas is {width}x{height}, expected 48x2176")


def check_release_assets(errors: list[str]) -> None:
    for name in RELEASE_UI_ART:
        path = ROOT / "assets" / "generated" / "ui" / name
        if not path.is_file():
            errors.append(f"Missing release UI art: {relative(path)}")
    for name in RELEASE_AUDIO:
        path = ROOT / "assets" / "generated" / "audio" / name
        if not path.is_file():
            errors.append(f"Missing release audio: {relative(path)}")


def check_release_metadata(errors: list[str]) -> None:
    path = ROOT / "data" / "release" / "release_candidate.json"
    if not path.is_file():
        return
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        errors.append(f"Invalid release metadata JSON: {error}")
        return
    if data.get("schema_version") != 1 or data.get("engine_version") != "4.7.1":
        errors.append("Release metadata must identify schema 1 and Godot 4.7.1")
    if data.get("save_schema", {}).get("current") != 21 or data.get("settings_schema", {}).get("current") != 2:
        errors.append("Release metadata compatibility versions differ from the P17/P18 contract")


def check_json_documents(errors: list[str]) -> None:
    for root_name in ("data", "tests/fixtures"):
        for path in (ROOT / root_name).rglob("*.json"):
            try:
                json.loads(path.read_text(encoding="utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError) as error:
                errors.append(f"Malformed JSON: {relative(path)} ({error})")


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    check_required(errors)
    check_files(errors, warnings)
    check_manifest(errors)
    check_master_manifest(errors)
    check_patch(errors)
    check_runtime_catalog(errors)
    check_mahjong_atlas(errors)
    check_release_assets(errors)
    check_release_metadata(errors)
    check_json_documents(errors)
    if errors:
        print("Repository validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    if warnings:
        print("Repository size warnings:")
        for warning in warnings:
            print(f"- {warning}")
    print("Repository validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
