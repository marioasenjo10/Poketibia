# Revision de las quests: lee la tabla `quests` de data/lib/core/newfunctions.lua y busca en el mapa
# (global_dash.otbm) los cofres con cada uniqueid, y en los scripts quien da cada premio.
# Uso: python tools/questreview.py  -> imprime una ficha por quest (tambien en tools/questreview.txt)
import os, re, struct, collections

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'bases', 'pokedashpota1.0', 'data')
src = open(os.path.join(ROOT, 'lib', 'core', 'newfunctions.lua'), encoding='latin-1').read()

# ---------- quests ----------
qstart = src.index('quests = ')
qtext = src[qstart:]
quests = collections.OrderedDict()
for m in re.finditer(r'\n(\w+)\s*=\s*\{\s*\n\s*prizes\s*=\s*\{(.*?)\n\s*level\s*=\s*(\d+)\s*,[^\n]*\n\s*teleportCP\s*=\s*(\d+)', qtext, re.S):
    key, body, level, tp = m.group(1), m.group(2), int(m.group(3)), int(m.group(4))
    prizes = []
    for pm in re.finditer(r'uid\s*=\s*([\w]+)\s*,(.*?)badges\s*=\s*\{(.*?)\}', body, re.S):
        uid = pm.group(1)
        items = re.findall(r'item\s*=\s*"([^"]+)"\s*,\s*count\s*=\s*(\d+)', pm.group(2))
        pokes = re.findall(r'name\s*=\s*"([^"]+)"\s*,\s*boost\s*=\s*(\d+)', pm.group(2))
        prizes.append(dict(uid=uid, items=items, pokes=pokes))
    quests[key] = dict(level=level, teleport=tp, prizes=prizes)
    if key == 'terrorQuest' or len(quests) > 200:
        pass

# storages con nombre (uid = storageXxx)
named = dict((k, int(v)) for k, v in re.findall(r'^(storage\w+)\s*=\s*(\d+)', src, re.M))
def uid_value(u):
    return int(u) if u.isdigit() else named.get(u)

# ---------- items.xml (nombres) ----------
items_xml = open(os.path.join(ROOT, 'items', 'items.xml'), encoding='latin-1').read()
item_names = set()
for m in re.finditer(r'<item (?:id="(\d+)"|fromid="(\d+)" toid="(\d+)")[^>]*name="([^"]*)"', items_xml):
    item_names.add(m.group(4).lower())

# ---------- monstruos ----------
mons = set(n.lower() for n in re.findall(r'<monster name="([^"]+)"', open(os.path.join(ROOT, 'monster', 'monsters.xml'), encoding='latin-1').read()))

# ---------- mapa: items con uniqueid / actionid ----------
data = open(os.path.join(ROOT, 'world', 'global_dash.otbm'), 'rb').read()

def unescape_node(buf, i):
    """lee un nodo desde buf[i] (que es 0xFE); devuelve (tipo, bytes_propios, hijos, fin)"""
    assert buf[i] == 0xFE
    i += 1
    ntype = buf[i]; i += 1
    props = bytearray()
    children = []
    while True:
        c = buf[i]
        if c == 0xFD:
            props.append(buf[i + 1]); i += 2
        elif c == 0xFE:
            child, i = unescape_node(buf, i)
            children.append(child)
        elif c == 0xFF:
            return (ntype, bytes(props), children), i + 1
        else:
            props.append(c); i += 1

import sys
sys.setrecursionlimit(10000)

def parse_item_attrs(props):
    """props empieza tras el id (u16). Devuelve dict de atributos simples."""
    out = {}
    j = 0
    while j < len(props):
        a = props[j]; j += 1
        if a == 4 and j + 2 <= len(props):  # action id
            out['aid'] = struct.unpack('<H', props[j:j + 2])[0]; j += 2
        elif a == 5 and j + 2 <= len(props):  # unique id
            out['uid'] = struct.unpack('<H', props[j:j + 2])[0]; j += 2
        elif a in (6, 7) and j + 2 <= len(props):  # texto / descripcion
            n = struct.unpack('<H', props[j:j + 2])[0]; j += 2 + n
        elif a == 8:  # teleport destino
            j += 5
        elif a == 15:  # count / subtype
            j += 1
        elif a in (14, 16, 17, 18, 20, 22, 24):
            j += {14: 2, 16: 2, 17: 4, 18: 2, 20: 1, 22: 4, 24: 2}[a]
        else:
            break
    return out

found = collections.defaultdict(list)  # uid -> [(x,y,z,itemid)]
aids = collections.defaultdict(list)

def walk_items(node, pos):
    ntype, props, children = node
    if ntype == 6 and len(props) >= 2:
        iid = struct.unpack('<H', props[:2])[0]
        attrs = parse_item_attrs(props[2:])
        if 'uid' in attrs:
            found[attrs['uid']].append(pos + (iid,))
        if 'aid' in attrs:
            aids[attrs['aid']].append(pos + (iid,))
    for ch in children:
        walk_items(ch, pos)

root, _ = unescape_node(data, 4)
for mapdata in root[2]:
    for area in mapdata[2]:
        if area[0] != 4:
            continue
        bx, by, bz = struct.unpack('<HHB', area[1][:5])
        for tile in area[2]:
            if tile[0] not in (5, 14):
                continue
            tx, ty = tile[1][0], tile[1][1]
            pos = (bx + tx, by + ty, bz)
            for ch in tile[2]:
                walk_items(ch, pos)
            # items inline en el tile (atributo 9 = item) no se tratan: los cofres van como nodo

# ciudades (para decir "cerca de")
towns = []
for m in re.finditer(rb'\xfe\x0d(.{4})(..)', data, re.S):
    ln = struct.unpack('<H', m.group(2))[0]
    if 0 < ln < 40:
        name = data[m.start() + 8:m.start() + 8 + ln]
        if re.fullmatch(rb"[A-Za-z' .]+", name):
            x, y, z = struct.unpack('<HHB', data[m.start() + 8 + ln:m.start() + 13 + ln])
            if x < 60000:
                towns.append((name.decode(), x, y, z))

def near(x, y):
    best = min(towns, key=lambda t: max(abs(t[1] - x), abs(t[2] - y)))
    return '%s (%d)' % (best[0], max(abs(best[1] - x), abs(best[2] - y)))

# ---------- quien usa cada quest en los scripts ----------
users = collections.defaultdict(set)
for dirpath, _, files in os.walk(ROOT):
    for f in files:
        if f.endswith('.lua'):
            p = os.path.join(dirpath, f)
            t = open(p, encoding='latin-1').read()
            for key in quests:
                if re.search(r'quests\.%s\b|quests\["%s"\]' % (key, key), t):
                    users[key].add(os.path.relpath(p, ROOT).replace('\\', '/'))

lines = []
for key, q in quests.items():
    lines.append('== %s  (nivel %d%s)' % (key, q['level'], ', vuelve al templo' if q['teleport'] else ''))
    for p in q['prizes']:
        u = uid_value(p['uid'])
        where = found.get(u, []) if u else []
        place = '; '.join('%d,%d,%d %s' % (x, y, z, near(x, y)) for x, y, z, _ in where) or 'SIN COFRE EN EL MAPA'
        bad_items = [i for i, _ in p['items'] if i.lower() not in item_names]
        bad_pokes = [n for n, _ in p['pokes'] if n.lower() not in mons]
        lines.append('   uid %s=%s | %s' % (p['uid'], u, place))
        if p['items']:
            lines.append('     objetos: ' + ', '.join('%sx %s' % (c, i) for i, c in p['items']) +
                         ('   NO EXISTEN: ' + ', '.join(bad_items) if bad_items else ''))
        if p['pokes']:
            lines.append('     pokemon: ' + ', '.join('%s +%s' % (n, b) for n, b in p['pokes']) +
                         ('   NO EXISTEN: ' + ', '.join(bad_pokes) if bad_pokes else ''))
        if not p['items'] and not p['pokes']:
            lines.append('     (sin premio de objetos)')
    if users.get(key):
        lines.append('   usado en: ' + ', '.join(sorted(users[key])))
out = '\n'.join(lines)
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'questreview.txt'), 'w', encoding='utf-8').write(out)
print(out)
print('\nquests:', len(quests), '| cofres con uniqueid en el mapa:', sum(len(v) for v in found.values()))
