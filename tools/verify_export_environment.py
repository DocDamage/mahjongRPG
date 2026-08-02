#!/usr/bin/env python3
"""Check the local prerequisites for the required Windows development export."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_VERSION = "4.7.1"
REQUIRED_PRESET_LINES = (
    'name="Windows Desktop"',
    'platform="Windows Desktop"',
    'export_path="exports/SixBrandsAtHighNoon.exe"',
)
REQUIRED_EXCLUSIONS = (
    "assets/source/*",
    "assets/MahjongRPG/*",
    "vendor/local/*",
    "artifacts/local/*",
    "docs/*",
    "tests/*",
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot", help="Godot executable to validate")
    args = parser.parse_args()
    errors: list[str] = []
    godot = shutil.which(args.godot) or (args.godot if Path(args.godot).is_file() else "")
    if not godot:
        errors.append(f"Godot executable not found: {args.godot}")
    else:
        version = subprocess.run([godot, "--version"], capture_output=True, text=True, check=False).stdout.strip()
        if not version.startswith(REQUIRED_VERSION + "."):
            errors.append(f"Godot {REQUIRED_VERSION} is required; found {version or 'unknown'}")
        template_root = Path(os.environ.get("APPDATA", "")) / "Godot" / "export_templates" / f"{REQUIRED_VERSION}.stable"
        for template in ("windows_debug_x86_64.exe", "windows_release_x86_64.exe"):
            if not (template_root / template).is_file():
                errors.append(f"Missing Godot {REQUIRED_VERSION} export template: {template_root / template}")
    preset = ROOT / "export_presets.cfg"
    content = preset.read_text(encoding="utf-8") if preset.is_file() else ""
    if not content:
        errors.append("Missing export_presets.cfg")
    for line in REQUIRED_PRESET_LINES:
        if line not in content:
            errors.append(f"Windows export preset is missing {line}")
    excluded_match = re.search(r'exclude_filter="([^"]*)"', content)
    exclusions = excluded_match.group(1) if excluded_match else ""
    for pattern in REQUIRED_EXCLUSIONS:
        if pattern not in exclusions:
            errors.append(f"Windows export preset must exclude {pattern}")
    if errors:
        print("Windows export preflight failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Windows export preflight passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
