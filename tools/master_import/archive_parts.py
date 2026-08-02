"""Locate and fingerprint the required split ZIP archive set."""

from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Any


DEFAULT_ARCHIVE_NAMES = (
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


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def required_names(manifest: dict[str, Any]) -> tuple[str, ...]:
    names = tuple(manifest.get("required_files", ()))
    if names != DEFAULT_ARCHIVE_NAMES:
        raise ValueError("Master archive manifest must list the nine expected split ZIP filenames")
    return names


def inspect_archive_set(source_dir: Path, manifest: dict[str, Any]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    missing: list[str] = []
    for name in required_names(manifest):
        path = source_dir / name
        if not path.is_file():
            missing.append(name)
            continue
        records.append({"file": name, "bytes": path.stat().st_size, "sha256": sha256(path)})
    if missing:
        raise FileNotFoundError(f"Missing master archive files: {', '.join(missing)}")
    return records


def validate_pinned_records(manifest: dict[str, Any], observed: list[dict[str, Any]]) -> bool:
    """Return whether the committed manifest pins this exact archive revision."""
    expected = manifest.get("archives", [])
    if not expected:
        return False
    expected_by_name = {entry.get("file"): entry for entry in expected}
    if set(expected_by_name) != {entry["file"] for entry in observed}:
        raise ValueError("Pinned master manifest filenames do not match the required archive set")
    for entry in observed:
        recorded = expected_by_name[entry["file"]]
        if recorded.get("bytes") != entry["bytes"] or recorded.get("sha256") != entry["sha256"]:
            raise ValueError(f"Master archive fingerprint mismatch: {entry['file']}")
    return True
