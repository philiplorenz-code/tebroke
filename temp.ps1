# Variablen
$var = 'CreateDrill("Vertikale Bohrung_2", 250.1817, 309.0415, 19.0000, 8.0000, "", TypeOfProcess.Drilling, "-1", "-1", 0, -1, -1, "L");'

# Überprüfe, ob der String $var der Vorlage entspricht und die letzte Position "L" ist
if ($var -match 'CreateDrill\(".+?", .+?, .+?, .+?, .+?, "", TypeOfProcess\.Drilling, "-1", "-1", 0, -1, -1, "L"\);') {
    
    # Extrahiere die relevanten Werte
    $var -match 'CreateDrill\("(.+?)", (.+?), (.+?), (.+?), (.+?), "", TypeOfProcess\.Drilling, "-1", "-1", 0, -1, -1, "L"\);'
    $name, $val1, $val2, $val3, $val4 = $matches[1], $matches[2], $matches[3], $matches[4], $matches[5]
    
    # Erhöhe die Zahl (19.0000 im Beispiel) um 3
    $newVal3 = [double]$val3 + 3

    # Erstelle den neuen String
    $newVar = "CreateDrill(`"$name`", $val1, $val2, {0:N4}, $val4, `"`", TypeOfProcess.Drilling, `"-1`", `"-1`", 0, -1, -1, `"`"P`"`");" -f $newVal3

    # Ausgabe des neuen Strings
    Write-Output $newVar
}
else {
    Write-Output "Der String $var entspricht nicht dem geforderten Muster oder endet nicht mit 'L'."
}
