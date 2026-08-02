"""Normalize extracted paths without accepting traversal or silent collisions."""

from __future__ import annotations

import hashlib
import re
import shutil
import unicodedata
from pathlib import Path
from typing import Any


IGNORED_SUFFIXES = {".cache", ".ctex", ".import", ".pck"}
IGNORED_NAMES = {".ds_store", "thumbs.db"}
IGNORED_PARTS = {"__macosx", ".godot", ".import"}


def is_ignored(relative: Path) -> bool:
    lowered = [part.lower() for part in relative.parts]
    return (
        any(part in IGNORED_PARTS for part in lowered)
        or relative.name.lower() in IGNORED_NAMES
        or relative.suffix.lower() in IGNORED_SUFFIXES
    )


def normalize_part(value: str) -> str:
    ascii_value = unicodedata.normalize("NFKD", value).encode("ascii", "ignore").decode("ascii")
    ascii_value = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", ascii_value)
    normalized = re.sub(r"[^a-z0-9._-]+", "_", ascii_value.lower()).strip("._-")
    return normalized or "asset"


def normalized_relative(relative: Path) -> Path:
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError(f"Unsafe extracted path: {relative}")
    return Path(*(normalize_part(part) for part in relative.parts))


def hash_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_tree(extracted: Path, destination: Path) -> tuple[list[dict[str, str]], dict[str, list[str]]]:
    """Copy usable files and return original-to-normalized and duplicate mappings."""
    mapping: list[dict[str, str]] = []
    hashes: dict[str, list[str]] = {}
    occupied: set[Path] = set()
    for source in sorted(extracted.rglob("*")):
        if not source.is_file():
            continue
        relative = source.relative_to(extracted)
        if is_ignored(relative):
            continue
        normalized = normalized_relative(relative)
        candidate = normalized
        suffix = 2
        while candidate in occupied or (destination / candidate).exists():
            candidate = normalized.with_name(f"{normalized.stem}__{suffix}{normalized.suffix}")
            suffix += 1
        occupied.add(candidate)
        target = destination / candidate
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        mapping.append({"original": relative.as_posix(), "normalized": candidate.as_posix()})
        hashes.setdefault(hash_file(target), []).append(candidate.as_posix())
    duplicates = {digest: paths for digest, paths in hashes.items() if len(paths) > 1}
    return mapping, duplicates
