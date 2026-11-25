# Revision de los objetos de evolucion shiny (lib/core/shinyevolution.lua, ids 46001+).
# Para cada evolucion normal X -> Y en la que existen "Shiny X" y "Shiny Y" como monstruos, mira si hay
# un objeto cuyo target sea "Shiny Y". Tambien lista los dibujos base repetidos y los objetos sobrantes.
# Uso: python tools/shinyitems.py   (escribe tools/shinyitems.txt)
import os, re, collections

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'bases', 'pokedashpota1.0', 'data')
lua = open(os.path.join(ROOT, 'lib', 'core', 'shinyevolution.lua'), encoding='latin-1').read()
items = []
for m in re.finditer(r'\[(\d+)\]\s*=\s*\{target\s*=\s*"([^"]+)",\s*item\s*=\s*(\d+),\s*tier\s*=\s*(\d+)\},?\s*--\s*(.*)', lua):
    items.append(dict(id=int(m.group(1)), target=m.group(2), base=int(m.group(3)), tier=int(m.group(4)), note=m.group(5).strip()))

xml = open(os.path.join(ROOT, 'items', 'items.xml'), encoding='latin-1').read()
names = {int(i): n for i, n in re.findall(r'<item id="(\d+)"[^>]*name="([^"]*)"', xml)}

index = open(os.path.join(ROOT, 'monster', 'monsters.xml'), encoding='latin-1').read()
files = {n.lower(): f for n, f in re.findall(r'<monster name="([^"]+)" file="([^"]+)"', index)}
evolutions = []  # (de, a)
dex = {}
for name, f in files.items():
    if name.startswith('shiny '):
        continue
    p = os.path.join(ROOT, 'monster', f)
    if not os.path.exists(p):
        continue
    t = open(p, encoding='latin-1').read()
    d = re.search(r'dexentry="(\d+)"', t)
    dex[name] = int(d.group(1)) if d else 0
    for evo in re.findall(r'<evolution name="([^"]+)"', t):
        if not evo.lower().startswith('shiny '):
            evolutions.append((name, evo.lower()))

by_target = collections.defaultdict(list)
for it in items:
    by_target[it['target'].lower()].append(it)

lines = []
missing, ok = [], []
for frm, to in sorted(set(evolutions), key=lambda e: (dex.get(e[1], 9999), e[1])):
    if 'shiny ' + frm in files and 'shiny ' + to in files:
        got = by_target.get('shiny ' + to)
        if got:
            ok.append((frm, to, got))
        else:
            missing.append((frm, to))

def region(n):
    d = dex.get(n, 0)
    return 'Kanto' if 0 < d <= 151 else 'Johto' if d <= 251 else 'Hoenn' if d <= 386 else 'Sinnoh+' if d else '?'

lines.append('Objetos de evolucion shiny: %d | evoluciones shiny posibles: %d | con objeto: %d | SIN objeto: %d'
             % (len(items), len(ok) + len(missing), len(ok), len(missing)))
lines.append('\n== Evoluciones shiny SIN objeto (no se pueden hacer)')
for frm, to in missing:
    lines.append('  [%s] Shiny %s -> Shiny %s' % (region(to), frm.title(), to.title()))

lines.append('\n== Objetos que no evolucionan a nadie (el target no es evolucion de ningun shiny)')
targets_valid = set('shiny ' + to for _, to, _ in ok)
for it in items:
    if it['target'].lower() not in targets_valid:
        lines.append('  %d %s (target %s)' % (it['id'], names.get(it['id'], '?'), it['target']))

lines.append('\n== Dibujos base repetidos (varios objetos shiny con el mismo dibujo)')
by_base = collections.defaultdict(list)
for it in items:
    by_base[it['base']].append(it)
for base, group in sorted(by_base.items(), key=lambda kv: -len(kv[1])):
    if len(group) > 1:
        lines.append('  %dx %s (%d): %s' % (len(group), names.get(base, '?'), base,
                                             ', '.join(g['target'].replace('Shiny ', '') for g in group)))

lines.append('\n== Todos los objetos, por region (id | nombre | evoluciona a | tier | dibujo base)')
for it in sorted(items, key=lambda i: (dex.get(i['target'].lower().replace('shiny ', ''), 9999))):
    n = it['target'].lower().replace('shiny ', '')
    lines.append('  [%s] %d | %s | %s | T%d | %s' % (region(n), it['id'], names.get(it['id'], '?'), it['target'], it['tier'],
                                                    names.get(it['base'], '?')))
out = '\n'.join(lines)
open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'shinyitems.txt'), 'w', encoding='utf-8').write(out)
print(out)
