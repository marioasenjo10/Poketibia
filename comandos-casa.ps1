# =====================================================================
# Comandos para ejecutar en el ordenador de casa.
# Uso: haz git pull, abre este archivo, copia el bloque que toque
# y pégalo en una terminal PowerShell.
# =====================================================================

# ---------------------------------------------------------------------
# [1] Revisión de seguridad de la base PokeDash
#     Genera revision-base.txt. Después: commit + push.
# ---------------------------------------------------------------------
Set-Location 'C:\Develop\Poketibia-project'
$b = 'bases\pokedashpota1.0'
$o = 'revision-base.txt'

"=== CONFIG ===" | Out-File $o
Get-Content "$b\config.lua" | Out-File $o -Append

"=== SOSPECHOSOS ===" | Out-File $o -Append
Get-ChildItem "$b\data", 'bases\pokedashpota1.0_client\modules' -Recurse -Include *.lua |
    Select-String -Pattern 'os\.execute|io\.popen|io\.open|loadstring|dofile|require|socket|http|setGroup|setAccountType|db\.query|getAccountType|ACCOUNT_TYPE_GOD|groupId' |
    ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" } |
    Out-File $o -Append -Width 400

"=== POKES ===" | Out-File $o -Append
Get-ChildItem "$b\data\monster\Pokes1" -Recurse -File |
    Select-Object -ExpandProperty Name |
    Out-File $o -Append

"=== THINGS ===" | Out-File $o -Append
Get-ChildItem 'bases\pokedashpota1.0_client\data\things' -Recurse -File |
    Select-Object FullName, Length |
    Out-File $o -Append -Width 300

git add $o
git commit -m "Revision de seguridad de la base PokeDash"
git push
