# Spawns del primer tramo (Pallet -> Pewter): solo Pokemon debiles en el piso 0.
import re,collections,itertools,sys
# Uso: python respawn.py   (sobrescribe data/world/map-spawn.xml; haz commit antes)
# Cambia especies fuertes por debiles en el piso 7 dentro de las zonas indicadas.
import os
SRC=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','bases','pokedashpota1.0','data','world','map-spawn.xml')
DST=SRC
# zonas del primer tramo en el piso 7 (x0,x1,y0,y1)
ZONES={
 'Afueras de Pallet':(600,800,1130,1250),
 'Oeste de Ciudad Verde':(560,700,1070,1130),
 'Ruta 1':(700,800,1095,1130),
 'Ciudad Verde':(640,800,1040,1095),
 'Ruta 2 y Bosque Verde':(560,820,870,1040),
 'Ciudad Plateada':(640,820,775,870),
}
# fuerte -> debiles (se reparten en rotacion)
R={
 'Sunflora':['Sunkern','Pidgey','Rattata'], 'Tangela':['Oddish','Pidgey'], 'Sableye':['Rattata'],
 'Scyther':['Pidgey'], 'Sceptile':['Rattata','Pidgey'], 'Gloom':['Oddish','Caterpie','Pidgey','Bellsprout'],
 'Bellossom':['Oddish'], 'Primeape':['Mankey','Spearow'], 'Nidoking':['Nidoran Male'],
 'Nidoqueen':['Nidoran Female'], 'Ditto':['Rattata'], 'Arbok':['Ekans'], 'Sandslash':['Sandshrew'],
 'Fearow':['Spearow'], 'Pinsir':['Pidgey'], 'Weezing':['Koffing'], 'Marowak':['Cubone'],
 'Parasect':['Paras'], 'Crobat':['Zubat'], 'Venomoth':['Venonat'], 'Smeargle':['Sentret'],
 'Stantler':['Rattata'], 'Heracross':['Pidgey'], 'Shieldon':['Geodude'], 'Shiny Shuppet':['Shuppet'],
 'Beedrill':['Weedle'], 'Butterfree':['Caterpie'], 'Furret':['Sentret'], 'Golem':['Geodude'],
 'Graveler':['Geodude'], 'Rhydon':['Geodude','Sandshrew'], 'Machamp':['Machop'], 'Hariyama':['Makuhita'],
 'Steelix':['Onix'], 'Sudowoodo':['Bonsly'],
}
cyc={k:itertools.cycle(v) for k,v in R.items()}
def zone(x,y):
    for k,(x0,x1,y0,y1) in ZONES.items():
        if x0<=x<x1 and y0<=y<y1: return k
src=open(SRC,encoding='latin-1',newline='').read()
lines=src.split('\n')
cx=cy=0; changes=collections.Counter(); after=collections.defaultdict(collections.Counter)
for i,l in enumerate(lines):
    m=re.search(r'<spawn\s+centerx="(\d+)"\s+centery="(\d+)"',l)
    if m: cx,cy=int(m[1]),int(m[2]); continue
    m=re.search(r'<monster name="([^"]+)" x="(-?\d+)" y="(-?\d+)" z="(\d+)"',l)
    if not m: continue
    name,x,y,z=m[1],cx+int(m[2]),cy+int(m[3]),int(m[4])
    zn=zone(x,y) if z==7 else None
    if not zn: continue
    if name in R:
        new=next(cyc[name]); lines[i]=l.replace(f'name="{name}"',f'name="{new}"',1)
        changes[(zn,name,new)]+=1; name=new
    after[zn][name]+=1
open(DST,'w',encoding='latin-1',newline='').write('\n'.join(lines))
for k in ZONES: print(k, sum(after[k].values()), dict(after[k].most_common()))
print('cambios:',sum(changes.values()))
