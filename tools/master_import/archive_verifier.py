"""Run an integrity test against a split ZIP archive through 7-Zip."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


def resolve_seven_zip(configured: str | None) -> str:
    executable = configured or shutil.which("7z") or shutil.which("7zz")
    if not executable:
        raise RuntimeError("7-Zip is required to test and extract the master split ZIP archive")
    return executable


def test_archive(main_archive: Path, seven_zip: str) -> None:
    result = subprocess.run(
        [seven_zip, "t", str(main_archive)],
        cwd=main_archive.parent,
        text=True,
        capture_output=True,
    )
    if result.returncode != 0:
        output = (result.stdout + "\n" + result.stderr).strip()
        raise RuntimeError(f"7-Zip integrity test failed for {main_archive.name}: {output}")
