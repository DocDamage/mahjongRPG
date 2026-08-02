"""Build a machine-readable category inventory of imported master assets."""

from __future__ import annotations

from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from master_import.path_normalizer import is_ignored


CATEGORY_TERMS = {
    "characters": ("npc", "hero", "cowboy", "horse", "wolf"),
    "mahjong_tiles": ("mahjong",),
    "crops": ("crop", "farm", "plant", "seed"),
    "animals": ("animal", "cow", "pig", "cat", "bunny", "bird", "fox", "mouse"),
    "fish_and_tackle": ("fish", "fishing", "tackle", "rod", "lure", "bait"),
    "world_tilesets": ("tileset", "tile-", "western", "desert", "city", "dock", "coastal"),
    "interiors": ("interior", "kitchen", "furniture"),
    "parallax": ("parallax", "mountain", "background"),
    "music": ("music", "loop", "theme"),
    "mahjong_sfx": ("mahjong_sound", "mahjong sound"),
    "item_icons": ("item", "icon", "weapon"),
    "fonts": ("font",),
    "source_projects": ("project.godot", ".tscn", ".gdshader", "unity", "engines"),
}


def category_for(relative: Path) -> str:
    value = relative.as_posix().lower()
    for category, terms in CATEGORY_TERMS.items():
        if any(term in value for term in terms):
            return category
    return "uncategorized"


def build_catalog(root: Path) -> dict[str, Any]:
    categories: dict[str, list[str]] = defaultdict(list)
    extensions: Counter[str] = Counter()
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.name == ".import_complete.json":
            continue
        relative = path.relative_to(root)
        if is_ignored(relative):
            continue
        categories[category_for(relative)].append(relative.as_posix())
        extensions[path.suffix.lower() or "[none]"] += 1
    return {
        "schema": 1,
        "file_count": sum(len(paths) for paths in categories.values()),
        "extensions": dict(sorted(extensions.items())),
        "categories": {
            category: {"count": len(paths), "files": paths}
            for category, paths in sorted(categories.items())
        },
    }
