#!/usr/bin/env python3
"""Assemble a non-destructive Windows release-candidate folder from a Godot export."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
METADATA = ROOT / "data" / "release" / "release_candidate.json"


def digest(path: Path) -> str:
    hasher = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            hasher.update(block)
    return hasher.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--export-dir", type=Path, default=ROOT / "exports")
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    metadata = json.loads(METADATA.read_text(encoding="utf-8"))
    package = metadata["package"]
    export_dir = args.export_dir.resolve()
    output_dir = (args.output_dir or export_dir / "release" / f"SixBrandsAtHighNoon-{metadata['version']}").resolve()
    if output_dir.exists():
        print(f"Refusing to overwrite existing package: {output_dir}", file=sys.stderr)
        return 1
    sources = {
        package["executable"]: export_dir / package["executable"],
        package["data"]: export_dir / package["data"],
        "THIRD_PARTY_ASSET_LICENSE_CC0.txt": ROOT / "legal" / "THIRD_PARTY_ASSET_LICENSE_CC0.txt",
        "PROPRIETARY_SOURCE_NOTICE.md": ROOT / "legal" / "PROPRIETARY_SOURCE_NOTICE.md",
        "RELEASE_NOTES.md": ROOT / "docs" / "release" / "RELEASE_NOTES.md",
        "SETUP_AND_RECOVERY.md": ROOT / "docs" / "release" / "setup_and_recovery.md",
    }
    missing = [str(path) for path in sources.values() if not path.is_file()]
    if missing:
        print("Cannot package; missing source files:", *missing, sep="\n- ", file=sys.stderr)
        return 1
    output_dir.mkdir(parents=True)
    for name, source in sources.items():
        shutil.copy2(source, output_dir / name)
    checksums = "".join(f"{digest(output_dir / name)}  {name}\n" for name in sorted(sources))
    (output_dir / "SHA256SUMS.txt").write_text(checksums, encoding="utf-8")
    result = subprocess.run([sys.executable, str(ROOT / "tools" / "verify_release_candidate.py"), "--package-dir", str(output_dir)], check=False)
    if result.returncode:
        return result.returncode
    print(f"Windows release candidate packaged at {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
