param(
    [switch]$Gui,
    [int]$Freq = 100000
)

Set-Location $PSScriptRoot

$bytes = New-Object byte[] 256
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()
[System.IO.File]::WriteAllBytes((Join-Path $PSScriptRoot '03.dev'), $bytes)

java -cp sictools.jar sic.Asm game.asm
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($Gui) {
    java -jar sictools.jar -freq $Freq game.asm
} else {
    java -cp sictools.jar sic.VM -freq $Freq game.asm
}
