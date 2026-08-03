#!/usr/bin/env python3
"""Promote approved hero and horse source art into tracked runtime assets."""

from __future__ import annotations

import argparse
import shutil
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HERO_SOURCE = ROOT / "assets" / "Hero - Cowboy - AssetPack" / "Assets"
HORSE_SOURCE = ROOT / "assets" / "horses"
RUNTIME = ROOT / "assets" / "generated"
HERO_ACTIONS = {
	"walk": ("walk", "Walk", 8),
	"idle": ("idle(breathe)", "Idle(breathe)", 15),
	"draw": ("draw-gun", "Draw", 6),
	"armed": ("draw(still)", "Draw(still)", 1),
	"shoot": ("shoot-gun", "Shoot", 3),
}
DIRECTIONS = ("up", "down", "left", "right")
HORSE_COLORS = ("black", "brown", "golden", "gray", "white")
UI_ASSETS = {
    "menu_closed.png": ("fishing UI", "fishingAssetPack", "MENU + UI", "menuClosedSprite.png"),
    "inventory_slot.png": ("fishing UI", "fishingAssetPack", "MENU + UI", "inventorySlotSprite.png"),
    "attention_marker.png": ("fishing UI", "fishingAssetPack", "MENU + UI", "exclamationSprite.png"),
}
AUDIO_ASSETS = {
    "ui_confirm.wav": ("Cozy SFX Volume 1", "UI", "MENU_CLICK_1.wav"),
    "ui_focus.wav": ("Cozy SFX Volume 1", "UI", "MENU_HOVER_1.wav"),
    "journal_updated.wav": ("Cozy SFX Volume 1", "UI", "NOTIFICATION_1.wav"),
    "item_pickup.wav": ("Cozy SFX Volume 1", "UI", "ITEM_PICKUP_1.wav"),
    "crop_water.wav": ("Cozy SFX Volume 1", "INTERACTIONS", "WATER_1.wav"),
    "crop_harvest.wav": ("Cozy SFX Volume 1", "INTERACTIONS", "LEAFS_1.wav"),
    "door_open.wav": ("Cozy SFX Volume 1", "INTERACTIONS", "WOOD_1.wav"),
    "animal_care.wav": ("Cozy SFX Volume 1", "INTERACTIONS", "FABRIC_1.wav"),
    "fishing_catch.wav": ("Cozy SFX Volume 1", "INTERACTIONS", "WATER_2.wav"),
    "mahjong_win.wav": ("Cozy SFX Volume 1", "UI", "PLAYER_LEVELUP.wav"),
    "music_theme.wav": ("Cozy SFX Volume 1", "BONUS TRACK", "BONUS_TRACK.wav"),
}


def copy(source: Path, target: Path, check: bool) -> None:
    if not source.is_file():
        raise FileNotFoundError(f"Missing approved source asset: {source}")
    if check:
        if not target.is_file():
            raise FileNotFoundError(f"Missing runtime asset: {target}")
        if source.read_bytes() != target.read_bytes():
            raise ValueError(f"Runtime asset differs from source: {target}")
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


def hero_filename(direction: str, label: str) -> str:
    return f"Cowboy-{direction.capitalize()}-{label}.png"



def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        if handle.read(8) != b"\x89PNG\r\n\x1a\n" or handle.read(4) != b"\x00\x00\x00\r" or handle.read(4) != b"IHDR":
            raise ValueError(f"Not a PNG image: {path}")
        return struct.unpack(">II", handle.read(8))


def generate(check: bool) -> None:
    for direction in DIRECTIONS:
        for action, (folder, label, frames) in HERO_ACTIONS.items():
            source = HERO_SOURCE / direction / folder / hero_filename(direction, label)
            target = RUNTIME / "player" / f"cowboy_{direction}_{action}.png"
            copy(source, target, check)
            if png_size(target) != (64 * frames, 64):
                raise ValueError(f"Unexpected hero sheet dimensions: {target}")
    for color in HORSE_COLORS:
        copy(HORSE_SOURCE / f"horse-{color}.png", RUNTIME / "horses" / f"horse_{color}.png", check)
    for target_name, source_parts in UI_ASSETS.items():
        copy(ROOT / "assets" / Path(*source_parts), RUNTIME / "ui" / target_name, check)
    for target_name, source_parts in AUDIO_ASSETS.items():
        copy(ROOT / "assets" / Path(*source_parts), RUNTIME / "audio" / target_name, check)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    generate(args.check)
    print("Runtime asset catalog is current." if args.check else "Generated runtime hero and horse assets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
