"""Parche del servidor: los salvajes reaparecen aunque un jugador este viendo el sitio.

Sin parche, Spawn::checkSpawn no repone nada que un jugador pueda ver y ademas reinicia su cuenta
atras. Se cambia un solo salto (je -> jmp) despues de la llamada a findPlayer. Los que aparecen a la
vista salen pacificos (data/lib/core/passivewild.lua).

    python tools/patch_respawn.py            aplica el parche
    python tools/patch_respawn.py --quitar   lo deshace

Se puede ejecutar con el servidor abierto: vale al reiniciarlo.
"""
import os
import shutil
import sys

EXE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "bases", "pokedashpota1.0", "pokedashpota_win64.exe")
OFFSET = 0x1C9C85                       # el salto, justo despues de "call findPlayer / test al,al"
BEFORE = bytes.fromhex("e87d040000 84c0".replace(" ", ""))
ORIGINAL, PATCHED = bytes([0x74, 0x23]), bytes([0xEB, 0x23])


def main():
    undo = "--quitar" in sys.argv
    with open(EXE, "rb") as f:
        data = bytearray(f.read())
    current = bytes(data[OFFSET:OFFSET + 2])
    if bytes(data[OFFSET - len(BEFORE):OFFSET]) != BEFORE or current not in (ORIGINAL, PATCHED):
        sys.exit("El ejecutable no es el esperado: no se toca.")
    wanted = ORIGINAL if undo else PATCHED
    if current == wanted:
        print("Ya estaba asi, no se cambia nada.")
        return
    data[OFFSET:OFFSET + 2] = wanted

    # Windows no deja sobrescribir un programa abierto, pero si renombrarlo
    old = EXE + ".antes-respawn.bak"
    number = 1
    while os.path.exists(old):
        number += 1
        old = "%s.antes-respawn%d.bak" % (EXE, number)
    os.rename(EXE, old)
    try:
        with open(EXE, "wb") as f:
            f.write(data)
        shutil.copymode(old, EXE)
    except OSError:
        os.replace(old, EXE)
        raise
    print("Parche %s. Copia anterior: %s" % ("quitado" if undo else "aplicado", old))


if __name__ == "__main__":
    main()
