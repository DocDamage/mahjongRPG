#!/usr/bin/env python3
"""Build one runtime Trail Rules tile atlas from canonical Brand tile SVGs."""

from __future__ import annotations

import argparse
import hashlib
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "mahjong tiles"
OUTPUT = ROOT / "assets" / "generated" / "mahjong" / "trail_rules_faces.png"
CHECKSUM = OUTPUT.with_suffix(".sha256")
BRANDS = ("blue", "dark", "green", "orange", "pink", "purple")
CELL = (48, 64)


def identity_sources() -> list[Path]:
    sources: list[Path] = []
    for suit in ("bamboo", "character", "dot"):
        sources.extend(Path(suit) / f"{rank:02}.svg" for rank in range(1, 10))
    sources.extend(Path("wind") / f"{rank:02}.svg" for rank in range(1, 5))
    sources.extend(Path("dragon") / f"{rank:02}.svg" for rank in range(1, 4))
    return sources


def run(arguments: list[str]) -> None:
    subprocess.run(arguments, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        if handle.read(8) != b"\x89PNG\r\n\x1a\n" or handle.read(4) != b"\x00\x00\x00\r" or handle.read(4) != b"IHDR":
            raise ValueError(f"Not a PNG image: {path}")
        return struct.unpack(">II", handle.read(8))


def build(output: Path) -> None:
    magick = shutil.which("magick")
    if not magick:
        raise RuntimeError("ImageMagick 'magick' is required to generate the Mahjong atlas")
    sources = identity_sources()
    if len(sources) != 34:
        raise ValueError("Trail Rules atlas requires exactly 34 identities")
    with tempfile.TemporaryDirectory(prefix="mahjong_atlas_") as temporary:
        temporary_path = Path(temporary)
        cells = [SOURCE / "raw" / identity_path for identity_path in sources]
        for source in cells:
            if not source.is_file():
                raise FileNotFoundError(f"Missing canonical tile source: {source}")
        output.parent.mkdir(parents=True, exist_ok=True)
        run([magick, "montage", *map(str, cells), "-background", "none", "-resize", f"{CELL[0]}x{CELL[1]}!", "-tile", f"1x{len(sources)}", "-geometry", f"{CELL[0]}x{CELL[1]}+0+0", "-border", "0", f"PNG32:{output}"])
    if png_size(output) != (CELL[0], CELL[1] * len(sources)):
        raise ValueError(f"Unexpected Mahjong atlas dimensions: {output}")


def source_checksum() -> str:
    digest = hashlib.sha256()
    for path in identity_sources():
        source = SOURCE / "raw" / path
        digest.update(path.as_posix().encode())
        digest.update(source.read_bytes())
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        if not OUTPUT.is_file() or not CHECKSUM.is_file() or CHECKSUM.read_text(encoding="utf-8").strip() != source_checksum() or png_size(OUTPUT) != (CELL[0], CELL[1] * 34):
            raise ValueError("Mahjong runtime atlas is missing or out of date")
        print("Mahjong runtime atlas is current.")
        return 0
    build(OUTPUT)
    CHECKSUM.write_text(source_checksum() + "\n", encoding="utf-8")
    print(f"Generated Mahjong runtime atlas: {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
