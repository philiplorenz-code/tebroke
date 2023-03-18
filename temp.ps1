# Variablen
$filePath = "./test.xcs"

# Lese die Datei
$content = Get-Content -Path $filePath

# Variablen für die gefundenen Zeilen
$setMachiningParametersLine = $null
$createFinishedWorkpieceBoxLine = $null

# Suche die relevanten Zeilen
foreach ($line in $content) {
    if ($line -match '^SetMachiningParameters\("AB",') {
        $setMachiningParametersLine = $line
    }
    if ($line -match '^CreateFinishedWorkpieceBox\(') {
        $createFinishedWorkpieceBoxLine = $line
    }
}

# Überprüfe, ob SetMachiningParameters-Zeile gefunden wurde
if ($null -eq $setMachiningParametersLine) {
    Write-Output "Die Zeile mit SetMachiningParameters wurde nicht gefunden."
    return
}

# Überprüfe die Länge, die in CreateFinishedWorkpieceBox angegeben ist, oder ob sie fehlt
if ($null -ne $createFinishedWorkpieceBoxLine -and $createFinishedWorkpieceBoxLine -match '^CreateFinishedWorkpieceBox\(".+?", (.+?), .+?, .+?\);') {
    $length = [double]$matches[1]
    
    if ($length -gt 1800) {
        $newSetMachiningParametersLine = $setMachiningParametersLine -replace 'SetMachiningParameters\("AB"', 'SetMachiningParameters("AD"'
    }
    else {
        $newSetMachiningParametersLine = $setMachiningParametersLine
    }
}
else {
    $newSetMachiningParametersLine = $setMachiningParametersLine -replace 'SetMachiningParameters\("AB"', 'SetMachiningParameters("AD"'
}

# Ersetze die Zeile SetMachiningParameters
$content = $content -replace [regex]::Escape($setMachiningParametersLine), $newSetMachiningParametersLine

# Schreibe die Datei
Set-Content -Path $filePath -Value $content
