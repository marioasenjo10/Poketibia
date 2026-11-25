# Curva de experiencia de la historia de Kanto: cuanto hace falta entre gimnasios y de donde sale.
# Lee los topes de nivel y las tareas de data/lib/core/progression.lua y la config de experiencia
# (expKillsPerLevel, expReferenceBase...) del mismo archivo, e imprime por tramo:
#   exp necesaria | exp de tareas | exp de capturas | derrotas necesarias | minutos de caza
# Uso: python tools/combatsim/expcurve.py [derrotas_por_minuto]   (por defecto 2)
import os, re, sys

D = os.environ.get('POKE_DATA') or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'bases', 'pokedashpota1.0', 'data')
src = open(os.path.join(D, 'lib', 'core', 'progression.lua'), encoding='utf-8').read()
stages_xml = open(os.path.join(D, 'XML', 'stages.xml'), encoding='utf-8').read()
KILLS_PER_MIN = float(sys.argv[1]) if len(sys.argv) > 1 else 2.0


def num(name, default):
    m = re.search(r'^%s\s*=\s*([\d.]+)' % name, src, re.M)
    return float(m.group(1)) if m else default


KILLS_PER_LEVEL = num('expKillsPerLevel', 0)       # 0 = sistema nuevo desactivado
REF_BASE = num('expReferenceBase', 33)
CATCH_FRACTION = num('catchExpLevelFraction', 0)
CATCH_TIER_FACTOR = 2                              # T6, lo normal en Kanto
CATCHES_PER_SEGMENT = 4                            # capturas nuevas por tramo (de tarea y por gusto)
BASE_EXP_HUNT = 33                                 # experiencia base de lo que se caza (basicos de Kanto)

stages = [(int(a), int(b) if b else 10**9, float(c)) for a, b, c in
          re.findall(r'<stage minlevel="(\d+)"(?: maxlevel="(\d+)")? multiplier="([\d.]+)"', stages_xml)]


def stage(level):
    for a, b, m in stages:
        if a <= level <= b:
            return m
    return 1


def need(level):  # experiencia total para tener ese nivel
    return 50 * (level ** 3 - 6 * level ** 2 + 17 * level - 12) // 3


def delta(level):
    return need(level + 1) - need(level)


def multiplier(level):
    m = stage(level)
    if KILLS_PER_LEVEL > 0:
        m = max(m, delta(level) / (KILLS_PER_LEVEL * REF_BASE))
    return m


def catch_exp(level):
    if CATCH_FRACTION > 0:
        return delta(level) * CATCH_FRACTION * CATCH_TIER_FACTOR
    return (500 + 25 * 20) * CATCH_TIER_FACTOR


# topes y tareas en orden
caps = [int(x) for x in re.findall(r'maxLevel = (\d+)', src)]
tasks_block = src[src.index('progressionTasks = {'):src.index('-- ===================== Bono de las medallas')]
tasks = []
for m in re.finditer(r'\{\s*\n\s*(?:--[^\n]*\n\s*)?id = "([^"]+)"(.*?)\n\t\},', tasks_block, re.S):
    tid, body = m.group(1), m.group(2)
    if 'disabled = true' in body:
        continue
    kind = re.search(r'kind = "(\w+)"', body).group(1)
    exp = re.search(r'exp = (\d+)', body)
    count = re.search(r'count = (\d+)', body)
    tasks.append(dict(id=tid, kind=kind, exp=int(exp.group(1)) if exp else 0,
                      count=int(count.group(1)) if count else 1))

# reparte las tareas en tramos: cada tarea de gimnasio cierra un tramo
segments, current = [], []
for t in tasks:
    current.append(t)
    if t['kind'] == 'badge':
        segments.append(current); current = []
if current:
    segments.append(current)

print('Derrotas por minuto supuestas: %.1f | expKillsPerLevel=%s | captura=%s del nivel x tier'
      % (KILLS_PER_MIN, KILLS_PER_LEVEL or 'off', CATCH_FRACTION or 'fija'))
print('%-10s %-8s %12s %10s %6s %10s %6s %9s %8s' % ('Gimnasio', 'Niveles', 'Necesaria', 'Tareas', '%', 'Capturas',
                                                     '%', 'Derrotas', 'Minutos'))
low = 1
for i, seg in enumerate(segments):
    high = caps[i] if i < len(caps) else None
    if high is None:
        break
    required = need(high) - need(low)
    task_exp = sum(t['exp'] for t in seg)
    mid = (low + high) // 2
    catches = CATCHES_PER_SEGMENT * catch_exp(mid)
    # derrotas necesarias: se simula nivel a nivel
    level, exp_have, kills = low, task_exp + catches, 0
    remaining = required - exp_have
    lv = low
    while remaining > 0 and lv < high:
        per_kill = BASE_EXP_HUNT * multiplier(lv)
        lvl_need = delta(lv)
        k = lvl_need / per_kill
        kills += k
        remaining -= lvl_need
        lv += 1
    # descuenta lo que ya aportan tareas y capturas
    share_free = max(0.0, 1 - (task_exp + catches) / required)
    kills_needed = kills * share_free
    task_kills = sum(t['count'] for t in seg if t['kind'] == 'defeat')
    minutes = max(0, kills_needed - task_kills) / KILLS_PER_MIN + task_kills / KILLS_PER_MIN
    name = seg[-1]['id']
    print('%-10s %3d-%-4d %12s %10s %5.0f%% %10s %5.0f%% %9.0f %8.0f' % (
        name, low, high, f'{required:,}'.replace(',', '.'), f'{task_exp:,}'.replace(',', '.'),
        100 * task_exp / required, f'{int(catches):,}'.replace(',', '.'), 100 * catches / required,
        kills_needed, minutes))
    low = high
