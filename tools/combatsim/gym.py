# Uso: python gym.py [nivel_jugador] [nivel_lider] [vida_x] [dano_x] pokemon_lider...
# Ejemplo (Brock): python gym.py 20 20 3 1.5 geodude onix
# Cociente < 1: ganas (0.6-0.9 = combate ajustado); > 1: pierdes.
import sys
from sim import *
def curve(L): return 1.0 if L<=0 else 1.3+0.06*min(L,30)+0.015*max(L-30,0)
LP,LB,M,DM=int(sys.argv[1]),int(sys.argv[2]),float(sys.argv[3]),float(sys.argv[4])
leader=[a.lower() for a in sys.argv[5:]]
team=['bulbasaur','charmander','squirtle','pikachu','mankey','nidoran male','oddish','bellsprout','poliwag','pidgey']
for s in team:
    out=[]
    for b in leader:
        A,B=P[s],P[b]; fa,fb=curve(LP),curve(LB)
        pd,_=dps_player(A,fa,B,fb,1); bd=dps_ai(B,fb,A,fa,DM/3)
        out.append(f"{b}: {(B['hp']*fb*M/pd)/(A['hp']*fa/bd):.2f}")
    print(f"{s:15}", '  '.join(out))
