"""Draws the egg's spawn-menu icon.

The crawler's own icons come out of render_assets.py as a silhouette of the built model, but the egg
is a scaled HL2 watermelon with a tint, so there is nothing to render: it is drawn straight in the
same tile style instead, in the shell's own red rather than the suite's bone silhouette ink, so it
reads as the red egg it is in game.

    python tools/make_egg_icon.py
"""

import math
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "materials/entities/evil_crawler_egg.png")

SIZE = 128
BG_IN = (42, 38, 41)
BG_OUT = (12, 11, 12)
FLOOR = 104
SS = 4  # drawn large and scaled down, so the edge is smooth without an AA pass

SHELL = (180, 35, 30)  # EvilCrawler.EGG_COLOR
HALF_W = 30.0          # egg is taller than it is wide, as the scaled melon is
HALF_H = 42.0


def draw():
    w = SIZE * SS
    im = Image.new("RGB", (w, w))
    px = im.load()

    cx = w / 2.0
    cy = (FLOOR - HALF_H) * SS
    rx, ry = HALF_W * SS, HALF_H * SS

    for j in range(w):
        for i in range(w):
            # tile background first: the same radial falloff the other spawn icons use
            t = min(1.0, math.hypot(i - w / 2, j - w / 2) / (w * 0.72)) ** 2
            bg = tuple(round(a + (b - a) * t) for a, b in zip(BG_IN, BG_OUT))

            u = (i - cx) / rx
            v = (j - cy) / ry
            d = math.hypot(u, v)
            if d > 1.0:
                px[i, j] = bg
                continue

            # rounded shading: lit from the upper left, falling off to the shell's own dark edge
            shade = 1.0 - 0.5 * d * d
            rim = 1.0 - 0.35 * max(0.0, (d - 0.72) / 0.28) ** 1.5
            # melon stripes running the short way round it, faint: the model's own pattern
            stripe = 1.0 - 0.16 * (0.5 + 0.5 * math.cos(u * 9.0))
            lit = shade * rim * stripe
            glow = 0.22 * max(0.0, -0.55 * u - 0.85 * v) * (1.0 - d)

            r = SHELL[0] * lit + 255 * glow
            g = SHELL[1] * lit + 235 * glow
            b = SHELL[2] * lit + 225 * glow
            px[i, j] = (min(255, round(r)), min(255, round(g)), min(255, round(b)))

    return im.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    draw().save(OUT, optimize=True)
    print("materials/entities/evil_crawler_egg.png  %dx%d" % (SIZE, SIZE))


if __name__ == "__main__":
    main()
