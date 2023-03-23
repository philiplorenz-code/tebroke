[CmdletBinding()]
Param(
  $SystemPath, # the value can be set in PYTHA Interface Setup
  $SystemCommand, # the value can be set in PYTHA Interface Setup
  $SystemProfile, # the value can be set in PYTHA Interface Setup
  [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$Program
)
############################################################################

#$inputimport = Get-Content "./input.txt" | ConvertFrom-Json

Start-Transcript -Path "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\transcript.txt"




$input | ConvertTo-Json | Out-File "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\dbg.txt"

$input | ConvertTo-Json | Set-Content -Path "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\input.txt"
$SystemPath | ConvertTo-Json | Set-Content -Path "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\SystemPath.txt"
$SystemCommand | ConvertTo-Json | Set-Content -Path "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\SystemCommand.txt"
$SystemProfile | ConvertTo-Json | Set-Content -Path "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\SystemProfile.txt"


$XConverter = "C:\Program Files\SCM Group\Maestro\XConverter.exe"
$Tooling = "C:\Users\Public\Documents\SCM Group\Maestro\Tlgx\def.tlgx"


$count = 0
$inFiles = @()
$tmpFiles = @()
$outFiles = @()

function convert-xcs-to-pgmx {
  Write-Output "Converting" $inFiles to $outFiles
  # Konvertieren in tmp pgmx
  & $XConverter -ow -s -report -m 0  -i $inFiles -t $Tooling -o $tmpFiles | Out-Default

  # Sauger positionieren
  & $XConverter -ow -s -m 13  -i $tmpFiles -t $Tooling -o $outFiles | Out-Default

  # Loesche die temporaeren Dateien
  Remove-Item $tmpFiles  
}
function Search-Array() {
  param(
    [array]$text,
    [string]$searchkey
  )

  $searchkey = "*" + $searchkey + "*"
  foreach ($line in $text) {
    if ($line -like $searchkey) {
      #return $line
      return $line
    }
  }
}

function Add-StringBefore {
  param(
    [array]$insert,
    [string]$keyword,
    # in $textfile muss eigentlich immer $Prog.CamPath übergeben werden
    [string]$textfile
  )
  Write-Host "Das ist der insert: $insert"
  Write-Host "Das ist das keyword: $keyword"
  Write-Host "Das ist der PFad: $textfile"

  $content = Get-Content $textfile

  Write-Host "Das ist der aktuelle inhalt: $content"
  $counter = 0
  $keywordcomplete = ""
  foreach ($string in $content) {

    if ($string -like "*$keyword*") {
      $keywordcomplete = $string

      $content[$counter] = ""
      for ($i = 0; $i -lt $insert.Count; $i++) {
        $content[$counter] = $content[$counter] + $insert[$i] + "`n"
      }

      $content[$counter] = $content[$counter] + $keywordcomplete + "`n"
      

    }
    $counter++
  }


  $content | Out-File $textfile



}

function Initial-Replace([string]$Filename) {

  function Remove-FirstMacro {
    param(
      $FilePath
    )


    "Date:" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"
    (Get-Date).ToString() | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    "FilePath:" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"
    $FilePath | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    "" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    $Content = Get-Content $FilePath
    "Initial Content:" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"
    $Content | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    "" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    $FirstMacro = ($Content | Select-String "CreateMacro")[0]
    #$FirstMacro = $FirstMacro.ToString() -replace '\s',''
    "FirstMacro:" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"
    $FirstMacro | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    "" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    $Content = $Content.Replace($FirstMacro, "")
    "New Content After Replacement:" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"
    $Content | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    "" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"

    # $Content | Set-Content $FilePath


    $CheckContent = Get-Content $FilePath
    "New Content After Reimport:" | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"
    $CheckContent | Out-File -Append "C:\Users\$env:USERNAME\AppData\Local\PYTHA25.0\temp\log.txt"
    return $Content
  }
  
  $Content = Get-Content $Filename
  $Filepath = $Filename
  $Filename = ($Filename.Split("\"))[-1]
  Set-Content -Path $Filename -Value $Content
}

function Replace-CreateBladeCut([string]$Filename) {
  $Content = Get-Content $Filename

  # Add Lines Before
  $Array = @()
  $Array += 'SetApproachStrategy(true, true, 0.8);'
  $Array += 'SetRetractStrategy(true, true, 0.8, 0);'
  $Array += 'CreateSectioningMillingStrategy(3, 150, 0);'

  $KeyWord = Search-Array -text $Content -searchkey 'CreateBladeCut("SlantedBladeCut1", "", TypeOfProcess.GeneralRouting,*, "-1",*, 2);'
  if ($KeyWord) {
    Add-StringBefore -insert $Array -keyword $KeyWord -textfile $Filename
  }

  # 78.1113 kann sich ändern

  # Replace Line
  $Content = Get-Content $Filename
  $2replace = Search-Array -text $Content -searchkey 'CreateBladeCut("SlantedBladeCut1", "", TypeOfProcess.GeneralRouting,*, "-1",*, 2);'
  if ($2replace) {
    $replacant = ($2replace.Replace(");", "")) + ", -1, -1, -1, 0, true, true, 0, 10);"
    $Content = $Content.Replace($2replace, $replacant)
  }
  #$replacant = 'CreateBladeCut("SlantedBladeCut1", "", TypeOfProcess.GeneralRouting, "E041", "-1", 78.1113, 2, -1, -1, -1, 0, true, true, 0, 10);'
  # 78.1113 kann sich ändern
  
  Set-Content -Path $Filename -Value $Content
}
function Bohrer([string]$path) {
  $content = Get-Content $path
  $output = @()
  foreach ($string in $content) {
    if ($string -match 'CreateDrill\(".+?", .+?, .+?, .+?, .+?, "", TypeOfProcess\.Drilling, "-1", "-1", 0, -1, -1, "L"\);') {
      $string -match 'CreateDrill\("(.+?)", (.+?), (.+?), (.+?), (.+?), "", TypeOfProcess\.Drilling, "-1", "-1", 0, -1, -1, "L"\);'
      $name, $val1, $val2, $val3, $val4 = $matches[1], $matches[2], $matches[3], $matches[4], $matches[5]
      # Erhöhe die Zahl (19.0000 im Beispiel) um 3
      $newVal3 = [double]$val3 + 3
      # Erstelle den neuen String

      $newVar = "CreateDrill(`"$name`", $val1, $val2, {0:N4}, $val4, `"`", TypeOfProcess.Drilling, `"-1`", `"-1`", 0, -1, -1, `"P`");" -f $newVal3.ToString("F4", [System.Globalization.CultureInfo]::InvariantCulture)
      $output += $newVar
    }
    else {
      $output += $string
    }
        
  }
  Set-Content -Path $path -Value $output
}


function Feldanpassung([string]$filePath) {

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
}


function Replace-CreateSlot([string]$Filename) {
  $Content = Get-Content -Path $Filename
  $Output = @()
  foreach ($string in $content) {
    if ($string -like "*CreateSlot*") {
      $string = $string.Replace("-1", "6")
    }
    $output += $string
  }
  
  Set-Content -Path $Filename -Value $Output
}

function Replace-CreateContourPocket([string]$Filename) {
  $Content = Get-Content $Filename
  
  # Add Lines Before
  $Array = @()
  $Array += 'SetApproachStrategy(true, false, 2);'
  $Array += 'CreateContourParallelStrategy(true, 0, true, 7, 0, 0);'
  
  $KeyWord = Search-Array -text $Content -searchkey 'CreateContourPocket("",*, "", TypeOfProcess.ConcentricalPocket,*);'

  If ($KeyWord) {
    Add-StringBefore -insert $Array -keyword $KeyWord -textfile $Filename
  }

  #Add-StringBefore -insert $Array -keyword 'CreateContourPocket("", 12.0000, "", TypeOfProcess.ConcentricalPocket, "E010");' -textfile $Filename
  # "E010" und 12.0000 kann anders sein
}

function Replace-SetMacroParam([string]$Filename) {
  $charCount = ($Filename.ToCharArray() | Where-Object { $_ -eq '_' } | Measure-Object).Count
  if ($charCount -gt 3) {

    $Filename = Split-Path $Filename -leaf
    $Elements = $Filename.split('_')
    
    $MM = $Elements[3]

    if ($Filename -like "*__*") {
      $MM = 0
    }

    $content = Get-Content $Filename
    $output = @()
    foreach ($string in $content) {
      $output += $string
      if ($string -like "*SetMacroParam*Angle*") {
        #$output += 'SetMacroParam("Depth", ' + $MM + ');'
      }

    }

    Set-Content -Path $Filename -Value $output
    
  }
}

function Replace-CreateRoughFinish([string]$Filename) {
  $Content = Get-Content $Filename
  # Add Lines Before
  $Array = @()
  $Array += 'CreateHelicMillingStrategy(9, true, 0);'

  $KeyWord = Search-Array -text $Content -searchkey 'CreateRoughFinish("",*,"",TypeOfProcess.GeneralRouting,*, "-1", 2);'
  if ($KeyWord) {
    Add-StringBefore -insert $Array -keyword $KeyWord -textfile $Filename
  }
  

  $KeyWord = Search-Array -text $Content -searchkey 'CreateRoughFinish("",*,"",TypeOfProcess.GeneralRouting,*, "-1", 0);'
  if ($KeyWord) {
    Add-StringBefore -insert $Array -keyword $KeyWord -textfile $Filename
  }


    # Approach- und RetractStrategie ersetzen
  $Content| ForEach-Object {

      # Im Bogen an- und abfahren mit 5 mm Überlappung für Bauteilumfräsung
      $_.Replace("SetApproachStrategy(true, false, -1)", "SetApproachStrategy(false, true, 2)").
      Replace("SetRetractStrategy(true, false, -1, 0)", "SetRetractStrategy(false, true, 2, 5)")

  } | Set-Content $Filename


  #Add-StringBefore -insert $Array -keyword 'CreateRoughFinish("",22.0000,"",TypeOfProcess.GeneralRouting, "E010", "-1", 2);' -textfile $Filename
  #Add-StringBefore -insert $Array -keyword 'CreateRoughFinish("",1.5000,"",TypeOfProcess.GeneralRouting, "E031", "-1", 0);' -textfile $Filename
  # kann sich aendern: 22.0000,E010 und 1.5000,E031
  # hier war im Bsp schon Helic gesetzt -> wird deshalb doppelt geschrieben
}


function Replace-SetMacroParam([string]$Filename) {

    $filename = Split-Path $Filename -leaf
    $split = $filename.split("_")
    $PosNr = $split[0]
    $Bauteilname = $split[1]
    $Material = $split[2]
    $Fraestiefe = $split[3]
    $Technologie = $split[4]
    $ProgrammNr = $split[5]
    
    if ([string]::IsNullOrEmpty($Fraestiefe)) {
      $MM = 0
    }
    else {
      $MM = $Fraestiefe
    }
    
    # SetMacroParam
    $content = Get-Content $filename
    $output = @()
    foreach ($string in $content) {
      $output += $string
      if ($string -like "*SetMacroParam*Angle*") {
        $output += 'SetMacroParam("Depth", ' + $MM + ');'
      }
    
    }
    Set-Content -Path $filename -Value $output


    # ApplyTechnology
    if (![string]::IsNullOrEmpty($Technologie) -and $ProgrammNr -eq "1.xcs") {
      Write-Host "Technologie ist $Technologie !! und ProgNr ist 1!"

      # Einstellungen für Tech aus Config holen
      $configpath = Join-path $PSScriptRoot "configtech.txt"
      $content = Get-Content $configpath

      "Content:" | Out-File -Append -FilePath ([IO.Path]::Combine($PSScriptRoot, "logs", "log.log"))

      $content | Out-File -Append -FilePath ([IO.Path]::Combine($PSScriptRoot, "logs", "log.log"))

      $hashtable = @{}
      foreach ($line in $content) {
        $hashtable.Add(($line.Split("_"))[0], $line)
      }

      # Check Function 
      function lineinfile($con) {
        foreach ($line in $con) {
          if ($line -like "*ResetRetractStrategy();*") {
            return $true
          }
        }
        return $false
      }


      $content_prog = Get-Content $filename
      if (lineinfile -con $content_prog) {
        Write-Host "ResetRetractStrategy() enthalten!"
        $newcontent = @()
        $found = $false
        foreach ($line in $content_prog) {
          $newcontent += $line
          if ($line -like "*ResetRetractStrategy();*" -and !$found) {
            $newcontent += 'ApplyTechnology("' + $hashtable.($Technologie) + '");'
            $found = $true
          }
        }
        Set-Content -Value $newcontent -Path $filename
      }
    }
}



$i = 0
foreach ($Prog in $input) {
  if ($count -ge 200) { 
    # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden      

    convert-xcs-to-pgmx

    $count = 0
    $inFiles = ""
    $tmpFiles = ""
    $outFiles = ""
  }


  $XCS = $Prog.CamPath
    
  Initial-Replace -Filename $XCS
  Replace-CreateBladeCut -Filename $XCS
  Replace-CreateSlot -Filename $XCS
  Replace-CreateContourPocket -Filename $XCS
  Replace-CreateRoughFinish -Filename $XCS
  Replace-SetMacroParam -Filename $XCS
  Feldanpassung -filePath $XCS
  Bohrer -path $XCS
 

  $xcsPath = $Prog.CamPath
  $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
  $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
    
        
  $count += 1
  $inFiles += $xcsPath
  $outFiles += $pgmxPath
  $tmpFiles += $tmpPath

  $i++
}


convert-xcs-to-pgmx

Start-Sleep 1

Stop-Transcript