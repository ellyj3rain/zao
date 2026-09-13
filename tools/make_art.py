#!/usr/bin/env python3
"""Generate ZAO's placeholder icon and poster."""

from __future__ import annotations

import pathlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOD = ROOT / "mod"


def icon() -> None:
    image = Image.new("RGBA", (128, 128), (18, 20, 24, 255))
    draw = ImageDraw.Draw(image)
    draw.polygon([(64, 12), (112, 100), (16, 100)], fill=(36, 112, 78, 255))
    draw.polygon([(64, 34), (95, 94), (33, 94)], fill=(18, 20, 24, 255))
    draw.ellipse((52, 52, 76, 76), fill=(220, 236, 224, 255))
    image.save(MOD / "icon.png")
    image.save(MOD / "42.20" / "icon.png")


def poster() -> None:
    image = Image.new("RGBA", (512, 512), (12, 13, 16, 255))
    draw = ImageDraw.Draw(image)
    for index in range(12):
        shade = 20 + index * 6
        draw.polygon(
            [
                (256, 30 + index * 12),
                (450, 430 + index * 5),
                (62, 430 + index * 5),
            ],
            fill=(shade, shade + 12, shade + 18, 255),
        )
    draw.polygon([(256, 120), (400, 420), (112, 420)], fill=(32, 96, 72, 255))
    draw.polygon([(256, 160), (350, 390), (162, 390)], fill=(12, 13, 16, 255))
    draw.ellipse((226, 220, 286, 280), fill=(220, 236, 224, 255))
    image.save(MOD / "poster.png")
    image.save(MOD / "42.20" / "poster.png")


def main() -> int:
    icon()
    poster()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
