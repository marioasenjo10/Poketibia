"""Dibuja las marcas de escalera del minimapa (data/images/map/stair_<up|down>_<lado>.png).

Una imagen por tamano, sin reescalar: lado impar para que la flecha quede centrada al pixel.
    python tools/stair_icons.py
"""
import os
import struct
import zlib

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "bases", "pokedashpota1.0_client", "data", "images", "map")
COLORS = {"up": (31, 122, 58, 238), "down": (180, 72, 15, 238)}  # verde sube, naranja baja
SIZES = {9: (3, 2), 11: (3, 2), 13: (4, 3)}  # lado: (medio ancho de la flecha, grosor)
WHITE = (255, 255, 255, 255)


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data))


for side, (half, thick) in SIZES.items():
    top = (side - half - thick) // 2
    for name, color in COLORS.items():
        pixels = [[color] * side for _ in range(side)]
        for dx in range(-half, half + 1):
            for t in range(thick):
                y = top + abs(dx) + t
                if name == "down":
                    y = side - 1 - y
                pixels[y][side // 2 + dx] = WHITE
        raw = b"".join(b"\0" + bytes(v for p in row for v in p) for row in pixels)
        with open(os.path.join(OUT, "stair_%s_%d.png" % (name, side)), "wb") as f:
            f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", side, side, 8, 6, 0, 0, 0))
                    + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))
