"""Extract the verified split ZIP archive into an external temporary directory."""

from __future__ import annotations

import subprocess
from pathlib import Path


def extract_archive(main_archive: Path, destination: Path, seven_zip: str) -> Path:
    destination.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [seven_zip, "x", "-y", f"-o{destination}", str(main_archive)],
        cwd=main_archive.parent,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        output = (result.stdout + "\n" + result.stderr).strip()
        raise RuntimeError(f"7-Zip extraction failed for {main_archive.name}: {output}")
    if not any(destination.rglob("*")):
        raise RuntimeError("7-Zip reported success but extracted no files")
    return destination
