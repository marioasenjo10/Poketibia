# Busca textos de Lua sin cerrar ('...' o "..." que acaban en un salto de linea). luaparser no lo
# detecta y el servidor/cliente no cargaria el archivo. Uso: python tools/luacheck_strings.py archivo.lua ...
import sys


def check(path):
    text = open(path, encoding='utf-8', errors='replace').read()
    problems = []
    i, line, n = 0, 1, len(text)
    while i < n:
        c = text[i]
        if c == '\n':
            line += 1
        elif text.startswith('--[[', i) or text.startswith('--[=', i):
            end = text.find(']]', i)
            end = n if end < 0 else end
            line += text.count('\n', i, end)
            i = end + 2
            continue
        elif text.startswith('--', i):
            end = text.find('\n', i)
            i = n if end < 0 else end
            continue
        elif text.startswith('[[', i) or text.startswith('[=[', i):
            close = ']]' if text.startswith('[[', i) else ']=]'
            end = text.find(close, i + 2)
            end = n if end < 0 else end
            line += text.count('\n', i, end)
            i = end + len(close)
            continue
        elif c in '\'"':
            j = i + 1
            while j < n and text[j] != c:
                if text[j] == '\\':
                    j += 2
                    continue
                if text[j] == '\n':
                    problems.append(line)
                    break
                j += 1
            line += text.count('\n', i, min(j, n))
            i = j + 1
            continue
        i += 1
    return problems


bad = 0
for path in sys.argv[1:]:
    for line in check(path):
        print('%s:%d: texto sin cerrar' % (path, line))
        bad += 1
print('ok' if bad == 0 else '%d problemas' % bad)
sys.exit(1 if bad else 0)
