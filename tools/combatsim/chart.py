# Tabla de tipos (igual que monsterhealthchange.lua)
CH={
"normal":([],["rock","steel"],["ghost"]),
"fire":(["grass","ice","bug","steel"],["fire","water","rock","dragon"],[]),
"water":(["fire","ground","rock"],["water","grass","dragon"],[]),
"electric":(["water","flying"],["electric","grass","dragon"],["ground"]),
"grass":(["water","ground","rock"],["fire","grass","poison","flying","bug","dragon","steel"],[]),
"ice":(["grass","ground","flying","dragon"],["fire","water","ice","steel"],[]),
"fighting":(["normal","ice","rock","dark","steel"],["poison","flying","psychic","bug","fairy"],["ghost"]),
"poison":(["grass","fairy"],["poison","ground","rock","ghost"],["steel"]),
"ground":(["fire","electric","poison","rock","steel"],["grass","bug"],["flying"]),
"flying":(["grass","fighting","bug"],["electric","rock","steel"],[]),
"psychic":(["fighting","poison"],["psychic","steel"],["dark"]),
"bug":(["grass","psychic","dark"],["fire","fighting","poison","flying","ghost","steel","fairy"],[]),
"rock":(["fire","ice","flying","bug"],["fighting","ground","steel"],[]),
"ghost":(["psychic","ghost"],["dark"],["normal"]),
"dragon":(["dragon"],["steel"],["fairy"]),
"dark":(["psychic","ghost"],["fighting","dark","fairy"],[]),
"steel":(["ice","rock","fairy"],["fire","water","electric","steel"],[]),
"fairy":(["fighting","dragon","dark"],["fire","poison","steel"],[]),
}
STRONG=1.5; WEAK=1/1.5; IMM=0.0
def tm(el,d):
    if el=='earth': el='poison'
    st,wk,im=CH.get(el,([],[],[]))
    m=1.0
    for r in (d['r1'],d['r2']):
        if r in im: return IMM
        if r in st: m*=STRONG
        if r in wk: m*=WEAK
    return m
