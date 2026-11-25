# Busca anclajes circulares en archivos .otui del cliente (A se ancla a B y B a A, directa o indirectamente).
# El OTClient entra en bucle con eso ("is recursively anchored to itself") y el cliente puede cerrarse.
# Uso: python tools/otui_anchors.py archivo.otui ...
import re, sys


def widgets(path):
    """lista de (indentacion, id, [destinos de sus anclajes]) en orden"""
    out = []
    current = None
    for raw in open(path, encoding='utf-8', errors='replace'):
        line = raw.rstrip('\n').rstrip('\r')
        if not line.strip() or line.strip().startswith('//'):
            continue
        indent = len(line) - len(line.lstrip(' '))
        text = line.strip()
        if re.match(r'^[A-Z][\w]*(\s*<\s*\w+)?\s*$', text):
            current = {'indent': indent, 'id': None, 'anchors': []}
            out.append(current)
            continue
        if current is None:
            continue
        m = re.match(r'^id:\s*(\w+)', text)
        if m and indent == current['indent'] + 2:
            current['id'] = m.group(1)
        m = re.match(r'^anchors\.(\w+):\s*(\w+)', text)
        if m and indent == current['indent'] + 2:
            current['anchors'].append(m.group(2))
    return out


def cycles(path):
    ws = widgets(path)
    graph = {}
    for w in ws:
        if w['id']:
            graph.setdefault(w['id'], set()).update(a for a in w['anchors'] if a not in ('parent', 'prev', 'next'))
    found = []
    state = {}

    def visit(node, stack):
        state[node] = 1
        for nxt in graph.get(node, ()):
            if state.get(nxt) == 1:
                found.append(stack[stack.index(nxt):] + [nxt] if nxt in stack else [node, nxt])
            elif state.get(nxt) is None and nxt in graph:
                visit(nxt, stack + [nxt])
        state[node] = 2

    for node in graph:
        if state.get(node) is None:
            visit(node, [node])
    return found


bad = 0
for p in sys.argv[1:]:
    for c in cycles(p):
        print('%s: anclaje circular: %s' % (p, ' -> '.join(c)))
        bad += 1
print('ok' if bad == 0 else '%d problemas' % bad)
sys.exit(1 if bad else 0)
