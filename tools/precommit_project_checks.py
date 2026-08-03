#!/usr/bin/env python3
"""Advisory naming and staged-new-file checks for project-owned content."""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKED_SUFFIXES = {".gd", ".py", ".json"}
HANDWRITTEN_SUFFIXES = {".gd", ".py"}
EXCLUDED_PREFIXES = ("assets/", "vendor/", "exports/", "artifacts/", ".godot/")
SNAKE_CASE = re.compile(r"^(?:__init__|[a-z0-9]+(?:_[a-z0-9]+)*)$")
MAX_NEW_LINES = 300


def relative(path: Path) -> str:
    return path.resolve().relative_to(ROOT).as_posix()


def eligible(path: Path) -> bool:
    if not path.is_file() or path.suffix.lower() not in CHECKED_SUFFIXES:
        return False
    return not relative(path).startswith(EXCLUDED_PREFIXES)


def staged_new_files() -> set[str]:
    result = subprocess.run(
        ["git", "diff", "--cached", "--diff-filter=A", "--name-only"],
        cwd=ROOT,
        capture_output=True,
        check=False,
        text=True,
    )
    return {line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()}


def validate(paths: list[Path], check_all_sizes: bool = False) -> list[str]:
    errors: list[str] = []
    new_files = staged_new_files()
    for path in paths:
        if not eligible(path):
            continue
        rel = relative(path)
        if not SNAKE_CASE.fullmatch(path.stem):
            errors.append(f"Project-owned filename must be lower_snake_case: {rel}")
        if path.suffix.lower() in HANDWRITTEN_SUFFIXES and (check_all_sizes or rel in new_files):
            lines = len(path.read_text(encoding="utf-8").splitlines())
            if lines > MAX_NEW_LINES:
                errors.append(f"New handwritten file exceeds {MAX_NEW_LINES} lines: {rel} ({lines})")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="*")
    parser.add_argument("--all", action="store_true", dest="check_all")
    args = parser.parse_args()
    paths = [ROOT / value for value in args.files]
    if args.check_all:
        paths = [path for path in ROOT.rglob("*") if path.is_file()]
    errors = validate(paths, args.check_all)
    if errors:
        print("Project convention checks failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"Project convention checks passed ({len(paths)} candidate file(s)).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
