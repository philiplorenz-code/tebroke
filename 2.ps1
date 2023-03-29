function Replace-SetMacroParam([string]$Filename) {
  # Prob: Technologie nicht angesprochen
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
  # Prob: Depth 0 statt Parameter
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