#!/usr/bin/env python3
"""Verify and normalize the four local supplemental asset archives."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs" / "assets" / "manifests" / "supplemental_source_archives.json"
DEFAULT_SOURCE = ROOT / "vendor" / "local" / "supplemental"
TARGET = ROOT / "assets" / "source" / "supplemental"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def slug(value: str) -> str:
    value = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", value.strip())
    value = value.lower().replace("+", " plus ")
    value = value.replace("(", "_").replace(")", "_")
    return re.sub(r"_+", "_", re.sub(r"[^a-z0-9._-]+", "_", value)).strip("_")


def safe_name(name: str) -> Path:
    parts = [part for part in Path(name).parts if part not in {"", "."}]
    if any(part == ".." for part in parts):
        raise ValueError(f"Unsafe archive path: {name}")
    return Path(*(slug(part) for part in parts))


def load_manifest() -> dict:
    return json.loads(MANIFEST.read_text(encoding="utf-8"))


def verify(entry: dict, source_dir: Path) -> Path:
    archive = source_dir / entry["file"]
    if not archive.is_file():
        raise FileNotFoundError(f"Missing source archive: {archive}")
    actual = sha256(archive)
    if actual != entry["sha256"]:
        raise ValueError(f"Checksum mismatch for {archive.name}: {actual}")
    with zipfile.ZipFile(archive) as bundle:
        bad = bundle.testzip()
        if bad:
            raise ValueError(f"CRC failure in {archive.name}: {bad}")
    return archive


def usable(info: zipfile.ZipInfo) -> bool:
    return not info.is_dir() and "__MACOSX" not in info.filename and not info.filename.endswith(".DS_Store")


def copy_zip(archive: Path, destination: Path, drop_parts: int = 1) -> None:
    with zipfile.ZipFile(archive) as bundle:
        for info in bundle.infolist():
            if not usable(info):
                continue
            original = Path(info.filename)
            reduced = Path(*original.parts[drop_parts:])
            if not reduced.parts:
                continue
            target = destination / safe_name(reduced.as_posix())
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(bundle.read(info))


def run_ffmpeg(arguments: list[str]) -> None:
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *arguments],
        check=True,
    )


def import_sfx(archive: Path, destination: Path) -> None:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg is required to normalize Cozy SFX Volume 1")
    with tempfile.TemporaryDirectory(prefix="cozy_sfx_") as temp_name:
        temp = Path(temp_name)
        with zipfile.ZipFile(archive) as bundle:
            for info in bundle.infolist():
                if not usable(info):
                    continue
                rel = Path(info.filename)
                if rel.parts and rel.parts[0].lower().startswith("cozy sfx"):
                    rel = Path(*rel.parts[1:])
                if not rel.parts:
                    continue
                top = rel.parts[0].upper()
                if top in {"BONUS TRACK", "DEMO TRACK.WAV", "SOUND DEM0.MP4"}:
                    continue
                source = temp / safe_name(rel.as_posix())
                source.parent.mkdir(parents=True, exist_ok=True)
                source.write_bytes(bundle.read(info))
                category = slug(rel.parts[0])
                out_rel = safe_name(Path(*rel.parts[1:]).as_posix())
                output = destination / category / out_rel
                output.parent.mkdir(parents=True, exist_ok=True)
                if category == "background_ambience":
                    run_ffmpeg(["-i", str(source), "-c:a", "libvorbis", "-q:a", "5", str(output.with_suffix(".ogg"))])
                elif source.name == "stone_footstep_2.wav":
                    run_ffmpeg(["-i", str(source), "-t", "0.50", "-c:a", "pcm_s16le", str(output)])
                elif source.suffix.lower() == ".mp3":
                    run_ffmpeg(["-i", str(source), "-c:a", "libvorbis", "-q:a", "5", str(output.with_suffix(".ogg"))])
                elif source.suffix.lower() == ".wav":
                    shutil.copy2(source, output)


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


def import_all(manifest: dict, source_dir: Path) -> None:
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="supplemental_", dir=TARGET.parent) as temp_name:
        staging = Path(temp_name) / "content"
        staging.mkdir()
        verified = {entry["kind"]: verify(entry, source_dir) for entry in manifest["archives"]}
        copy_zip(verified["hero"], staging / "hero_cowboy")
        copy_zip(verified["horses"], staging / "horses")
        copy_zip(verified["fishing_ui"], staging / "fishing_ui")
        import_sfx(verified["cozy_sfx"], staging / "cozy_sfx")
        marker = {
            "schema": 1,
            "imported_at": datetime.now(timezone.utc).isoformat(),
            "archives": [
                {"file": item["file"], "sha256": item["sha256"]}
                for item in manifest["archives"]
            ],
        }
        (staging / ".import_complete.json").write_text(
            json.dumps(marker, indent=2) + "\n", encoding="utf-8"
        )
        atomic_replace(staging)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--clean", action="store_true")
    args = parser.parse_args()

    if args.clean:
        if TARGET.exists():
            shutil.rmtree(TARGET)
        print(f"Removed {TARGET}")
        return 0

    manifest = load_manifest()
    for entry in manifest["archives"]:
        verify(entry, args.source_dir)
    print(f"Verified {len(manifest['archives'])} supplemental archives.")
    if not args.verify_only:
        import_all(manifest, args.source_dir)
        print(f"Imported supplemental assets to {TARGET}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
