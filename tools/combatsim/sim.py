# Simulador de combates de Poketibia: lee monstruos (data/monster/Pokes1) y ataques (data/spells)
# y reproduce la formula de dano del servidor (onHealthChange + scripts de ataques).
import re,glob,sys,os
D=os.environ.get('POKE_DATA') or os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','bases','pokedashpota1.0','data')
# --- move info from scripts
sp=open(D+'/spells/spells.xml',encoding='latin-1').read()
MOVES={}
for m in re.finditer(r'<instant[^>]*name="([^"]+)"[^>]*script="([^"]+)"',sp):
    name,path=m.group(1).lower(),m.group(2)
    try: s=open(D+'/spells/scripts/'+path,encoding='latin-1').read()
    except: continue
    c=re.search(r'damageMultiplierMoves\.(\w+)',s)
    if not c: continue
    MOVES[name]=dict(cat=c.group(1),phys='getTotalMeleeAttack' in s,
        el=path.split('/')[1])
MULT=dict(areawaves=2.75,singletargetweak=2.0,singletarget=3.5,singletargetstrong=4.0,areatarget=3.0,frontlinear=5.0,frontarea=4.0,passive=3.0,ultimate=6.0)
RS={"fire":(["grass","ice","bug","steel"],["water","ground","rock"]),"grass":(["water","ground","rock"],["fire","ice","poison","flying","bug"]),"normal":([],["fighting"]),"water":(["fire","ground","rock"],["electric","grass"]),"flying":(["grass","fighting","bug"],["electric","ice","rock"]),"poison":(["grass","fairy"],["ground","psychic"]),"electric":(["water","flying"],["ground"]),"ground":(["fire","electric","poison","rock","steel"],["water","grass","ice"]),"psychic":(["fighting","poison"],["bug","ghost","dark"]),"rock":(["fire","ice","flying","bug"],["water","grass","fighting","ground","steel"]),"ice":(["grass","ground","flying","dragon"],["fire","fighting","rock","steel"]),"bug":(["grass","psychic","dark"],["fire","flying","rock"]),"dark":(["psychic","ghost"],["fighting","bug","fairy"]),"fighting":(["normal","ice","rock","dark","steel"],["flying","psychic","fairy"])}
P={}
for f in glob.glob(D+'/monster/Pokes1/*.xml'):
    s=open(f,encoding='latin-1').read()
    g=lambda p,d=0:(re.search(p,s) or [None,d])[1]
    n=g(r'monster name="([^"]+)')
    mv=[(a.lower(),int(b)) for a,b in re.findall(r'<move name="([^"]+)" interval="(\d+)"',s)]
    P[n.lower()]=dict(name=n,r1=g(r' race="(\w+)'),r2=g(r'race2="(\w+)'),hp=int(g(r'max="(\d+)"')),
        melee=abs(int(g(r'name="melee"[^>]*min="(-?\d+)',0))),df=int(g(r'defense="(\d+)"',0)),
        matk=int(g(r'moveMagicAttackBase="(\d+)"',0)),mdef=int(g(r'moveMagicDefenseBase="(\d+)"',0)),moves=mv,
        atk=[(a.lower(),int(b),int(c)) for a,b,c in re.findall(r'<attack name="([^"]+)" interval="(\d+)" chance="(\d+)"',s)])
import chart as _chart
def _old_tmul(el,d):
    st,wk=RS.get(el,([],[]))
    m=1.0
    if d['r1'] in st or d['r2'] in st: m*=1.5
    if d['r1'] in wk or d['r2'] in wk: m/=1.5
    return m
RAND=0.405
def hit(att,fa,move,dfn,fd,extra):
    """att stats, fa = status multiplier of attacker (applied twice: move + onHealthChange)
    fd = status multiplier of defender (defense)."""
    mi=MOVES[move]; base=att['melee'] if mi['phys'] else att['matk']
    dmg=MULT[mi['cat']]*base*fa*fa
    if mi['phys']: damp=1-dfn['df']*fd/600
    else: damp=1-dfn['mdef']*fd/600
    damp=min(1,max(.5,damp))
    return dmg*damp*tmul(mi['el'],dfn)*RAND*extra
def dps_player(att,fa,dfn,fd,extra):
    best=0; tot=0
    for mv,iv in att['moves']:
        if mv not in MOVES: continue
        h=hit(att,fa,mv,dfn,fd,extra); best=max(best,h); tot+=h/(iv/1000)
    tot+=att['melee']*fa*RAND*extra/2  # melee each 2s, formula once
    return tot,best
def dps_ai(att,fa,dfn,fd,extra):
    tot=0
    for mv,iv,ch in att['atk']:
        if mv=='melee' or mv not in MOVES: continue
        tot+=hit(att,fa,mv,dfn,fd,extra)*ch/100/(iv/1000)
    tot+=att['melee']*fa*RAND*extra/2
    return tot

tmul=_chart.tm
