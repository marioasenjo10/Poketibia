"""Genera la lista de escaleras del mapa para el cliente (modules/game_minimap/stairs.txt).

Una linea por escalera: "z x y u|d" (u = sube, d = baja). Repetir si cambia el mapa:
    python tools/stairs.py
"""
import os
import struct
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(ROOT, "bases", "pokedashpota1.0", "data")
OUT = os.path.join(ROOT, "bases", "pokedashpota1.0_client", "modules", "game_minimap", "stairs.txt")

NODE_START, NODE_END, ESCAPE = 0xFE, 0xFF, 0xFD

# escaleras de mano que se usan con clic (actions/scripts/other/teleport.lua)
USE_UP = {1386, 3678, 5543}
USE_DOWN = {430, 1369}
MAX_CELLS = 12     # mas casillas seguidas que esto no es una escalera
HOUSE_REACH = 2    # al subir o bajar se puede caer a un par de casillas de la escalera


def floor_change_items():
    up, down = set(USE_UP), set(USE_DOWN)
    tree = ET.parse(os.path.join(SERVER, "items", "items.xml"),
                    ET.XMLParser(encoding="iso-8859-1"))
    for item in tree.getroot().iter("item"):
        for attr in item.findall("attribute"):
            if (attr.get("key") or "").lower() != "floorchange":
                continue
            first = int(item.get("id") or item.get("fromid"))
            last = int(item.get("id") or item.get("toid"))
            target = down if attr.get("value").lower() == "down" else up
            target.update(range(first, last + 1))
    return up, down


def read_tree(data):
    """Recorre los nodos del OTBM: devuelve (profundidad, datos) en orden de apertura."""
    depth, pos, size = 0, 4, len(data)
    while pos < size:
        marker = data[pos]
        pos += 1
        if marker == NODE_END:
            depth -= 1
            continue
        assert marker == NODE_START, "OTBM mal formado en %d" % (pos - 1)
        depth += 1
        node = bytearray()
        while data[pos] not in (NODE_START, NODE_END):
            if data[pos] == ESCAPE:
                pos += 1
            node.append(data[pos])
            pos += 1
        yield depth, node


def teleport_floor(node):
    """Piso de destino de un item teleport (atributo 8), o None."""
    q = 3
    while q < len(node):
        attr = node[q]
        q += 1
        if attr == 8:
            return node[q + 4]
        if attr in (4, 5, 10):      # actionid, uniqueid, depot
            q += 2
        elif attr in (14, 15):      # house door, count
            q += 1
        else:
            return None
    return None


def group(stairs):
    """Una marca por escalera: junta las casillas contiguas y descarta las manchas enormes
    (el item 459, "bajar" invisible, rellena zonas enteras del mapa que no son escaleras)."""
    marks, seen = [], set()
    for start, kind in sorted(stairs.items()):
        if start in seen:
            continue
        seen.add(start)
        cells, pending = [], [start]
        while pending:
            z, x, y = pending.pop()
            cells.append((x, y))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    near = (z, x + dx, y + dy)
                    if near not in seen and stairs.get(near) == kind:
                        seen.add(near)
                        pending.append(near)
        if len(cells) > MAX_CELLS:
            continue
        # la casilla real mas cercana al centro del grupo
        cx = sum(c[0] for c in cells) / len(cells)
        cy = sum(c[1] for c in cells) / len(cells)
        x, y = min(cells, key=lambda c: ((c[0] - cx) ** 2 + (c[1] - cy) ** 2, c))
        marks.append((start[0], x, y, kind))
    return marks


def leads_to_house(mark, houses):
    """Escalera de una casa particular (casillas de casa del mapa): esta dentro o lleva a una."""
    z, x, y, kind = mark
    if (z, x, y) in houses:
        return True
    target = z - 1 if kind == "u" else z + 1
    return any((target, x + dx, y + dy) in houses
               for dx in range(-HOUSE_REACH, HOUSE_REACH + 1)
               for dy in range(-HOUSE_REACH, HOUSE_REACH + 1))


def main():
    up, down = floor_change_items()
    with open(os.path.join(SERVER, "world", "global_dash.otbm"), "rb") as f:
        data = f.read()

    stairs = {}
    houses = set()
    area = tile = None

    def add(item_id, kind=None):
        if kind is None:
            kind = "u" if item_id in up else "d" if item_id in down else None
        if kind:
            stairs[tile] = kind

    for depth, node in read_tree(data):
        kind = node[0]
        if depth == 3 and kind == 4:
            area = struct.unpack_from("<HHB", node, 1)
        elif depth == 4 and kind in (5, 14):
            tile = (area[2], area[0] + node[1], area[1] + node[2])
            if kind == 14:              # casilla de una casa
                houses.add(tile)
            q = 7 if kind == 14 else 3
            while q < len(node):
                if node[q] == 3:
                    q += 5
                elif node[q] == 9:
                    add(struct.unpack_from("<H", node, q + 1)[0])
                    q += 3
                else:
                    break
        elif depth == 5 and kind == 6:
            add(struct.unpack_from("<H", node, 1)[0])
            floor = teleport_floor(node)
            if floor is not None and floor != tile[0]:
                add(0, "u" if floor < tile[0] else "d")

    marks = [mark for mark in group(stairs) if not leads_to_house(mark, houses)]
    with open(OUT, "w", newline="\n") as f:
        for z, x, y, kind in marks:
            f.write("%d %d %d %s\n" % (z, x, y, kind))
    kinds = [mark[3] for mark in marks]
    print("escaleras: %d suben, %d bajan -> %s" % (kinds.count("u"), kinds.count("d"), OUT))


if __name__ == "__main__":
    main()
