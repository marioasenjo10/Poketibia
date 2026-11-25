# Orbes de evolucion shiny: que shiny son destino de una evolucion (segun los archivos de los shiny),
# que orbe les toca por su rareza (data/pokemon-tiers-review.csv) y si tienen ilustracion para el holograma.
# Uso: python tools/shinyorbs.py            -> resumen
#      python tools/shinyorbs.py --names    -> un nombre por linea (para generar los hologramas)
import os, re, sys, collections

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'bases', 'pokedashpota1.0', 'data')
CLIENT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'bases', 'pokedashpota1.0_client', 'modules')

index = open(os.path.join(ROOT, 'monster', 'monsters.xml'), encoding='latin-1').read()
files = {n: f for n, f in re.findall(r'<monster name="(Shiny [^"]+)" file="([^"]+)"', index)}
targets = collections.OrderedDict()
for name, f in sorted(files.items()):
    p = os.path.join(ROOT, 'monster', f)
    if not os.path.exists(p):
        continue
    for evo in re.findall(r'<evolution name="(Shiny [^"]+)"', open(p, encoding='latin-1').read()):
        targets.setdefault(evo, []).append(name)

tiers = {}
for line in open(os.path.join(ROOT, 'pokemon-tiers-review.csv'), encoding='utf-8-sig'):
    m = re.match(r'^"?([^,"]+)"?,([^,]+),', line)
    if m:
        tiers[m.group(1).lower()] = m.group(2).strip('"')

COLOR = {'mythic': 'mythic', 'legendary': 'legendary', 'ultra rare': 'ultra', 'super rare': 'super', 't1': 't1', 't2': 't2'}

def color(target):
    # fila propia del shiny (Shiny Dragonite = Mythic); si no, la del Pokemon normal
    tier = tiers.get(target.lower()) or tiers.get(target[6:].lower(), '')
    return COLOR.get(tier.lower(), 'bronze')

if '--names' in sys.argv:
    for t in targets:
        print(t)
    sys.exit(0)

art = os.path.join(CLIENT, 'game_pokedex', 'artwork')
missing = [t for t in targets if not os.path.exists(os.path.join(art, t.lower() + '.png'))]
by_color = collections.Counter(color(t) for t in targets)
print('Shiny que son destino de una evolucion:', len(targets))
print('Por orbe:', dict(by_color))
print('Sin ilustracion para el holograma:', missing or 'ninguno')
