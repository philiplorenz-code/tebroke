function Replace-SetMacroParam() {
  foreach ($pathCam in $State.input) {
    $path = $pathCam.CamPath
    $filename = Split-Path $path -leaf
    $split = $filename.split("_")
    $path | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
    $PosNr = $split[0]
    $Bauteilname = $split[1]
    $Material = $split[2]
    $Fraestiefe = $split[3]
    $Technologie = $split[4]
    $ProgrammNr = $split[5]
    $Technologie | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
    $error | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
    (![string]::IsNullOrEmpty($Technologie) -and $ProgrammNr -eq 1) | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
    $ProgrammNr | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
    if ([string]::IsNullOrEmpty($Fraestiefe)) {
      $MM = 0
    }
    else {
      $MM = $Fraestiefe
    }
    # SetMacroParam
    $content = Get-Content $path
    $output = @()
    foreach ($string in $content) {
      $output += $string
      if ($string -like "*SetMacroParam*Angle*") {
        $output += 'SetMacroParam("Depth", ' + $MM + ');'
      }
    }
    Set-Content -Path $path -Value $output
    # ApplyTechnology
    if (![string]::IsNullOrEmpty($Technologie) -and $ProgrammNr -eq "1.xcs") {
      Write-Host "Technologie ist $Technologie !! und ProgNr ist 1!"
      "Technologie ist $Technologie !! und ProgNr ist 1!" | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
      # Einstellungen für Tech aus Config holen
      $configpath = Join-path $State.PSScriptRoot "configtech.txt"
      $content = Get-Content $configpath
      "Content:" | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
      $content | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
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
      $content_prog = Get-Content $path
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
        Set-Content -Value $newcontent -Path $path
      }
    }
  }
}