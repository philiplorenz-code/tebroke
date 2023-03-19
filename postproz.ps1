[CmdletBinding()]
param(
  $SystemPath, # the value can be set in PYTHA Interface Setup
  $SystemCommand, # the value can be set in PYTHA Interface Setup
  $SystemProfile, # the value can be set in PYTHA Interface Setup
  [Parameter(Mandatory = $true, ValueFromPipeline = $true)] $Program
)
#-------------------------------------------------------------#
#----Initial Declarations-------------------------------------#
#-------------------------------------------------------------#
$inputjson = $input
$DesktopPath = [Environment]::GetFolderPath("Desktop") 
$inputjson | ConvertTo-Json | Set-Content -Path ([IO.Path]::Combine($DesktopPath, "logs", "input.json"))


function Write-ToLog {
  param(
    [string]$logmessage
  )
  $logmessage = ((Get-Date).ToString()) + $logmessage
  $logmessage | Out-File -Append -FilePath ([IO.Path]::Combine($State.PSScriptRoot, "logs", "log.log"))
}
# Ermöglicht es einen Text vor einem definierten anderen Text einzufügen
function Add-StringBefore ([array]$insert, [string]$keyword, [string]$textfile, [boolean]$bc) {
  $content = Get-Content $textfile
  $counter = 0
  $keywordcomplete = ""

  # Loope über alle Elemente -> wenn Match, dann mach das aktuelle Match leer und fülle es auf mit dem eingegeben Array
  foreach ($string in $content) {
    if ($string -like "*$keyword*") {
      # Zwischenspeichern des KeyWords (wird weiter unten wieder eingesetzt)
      $keywordcomplete = $string
      $content[$counter] = ""
      for ($i = 0; $i -lt $insert.Count; $i++) {
        $content[$counter] = $content[$counter] + $insert[$i] + "`n"
      }
      if ($bc) {
        # Momentan nicht in Benutzung afaik!
        $keywordcomplete = $keywordcomplete.Substring(0, $keywordcomplete.Length - 1)
        $keywordcomplete = $keywordcomplete.Substring(0, $keywordcomplete.Length - 1)
        $keywordcomplete = $keywordcomplete + ", -1, -1, -1, 0, true, true, 0, 5);"
        $content[$counter] = $content[$counter] + $keywordcomplete
      }
      else {
        # Am Ende dann noch den eigentlichen String einfügen, vor dem weitere Zeilen geschrieben werden!
        $content[$counter] = $content[$counter] + $keywordcomplete + "`n"
      }

    }
    $counter++
  }
  $content | Out-File $textfile
}

function Bohrer() {
  foreach ($pathCam in $State.input) {
    $path = $pathCam.CamPath
    $content = Get-Content $path
    $output = @()
    foreach ($string in $content) {
      if ($string -match 'CreateDrill\(".+?", .+?, .+?, .+?, .+?, "", TypeOfProcess\.Drilling, "-1", "-1", 0, -1, -1, "L"\);') {
        $string -match 'CreateDrill\("(.+?)", (.+?), (.+?), (.+?), (.+?), "", TypeOfProcess\.Drilling, "-1", "-1", 0, -1, -1, "L"\);'
        $name, $val1, $val2, $val3, $val4 = $matches[1], $matches[2], $matches[3], $matches[4], $matches[5]
        # Erhöhe die Zahl (19.0000 im Beispiel) um 3
        $newVal3 = [double]$val3 + 3
        # Erstelle den neuen String
        $newVar = "CreateDrill(`"$name`", $val1, $val2, {0:N4}, $val4, `"`", TypeOfProcess.Drilling, `"-1`", `"-1`", 0, -1, -1, `"`"P`"`");" -f $newVal3
        $output += $newVar
      }
      else {
        $output += $string
      }
        
    }
    Set-Content -Path $path -Value $output
  }
}

function Feldanpassung() {
  foreach ($pathCam in $State.input) {
    $filePath = $pathCam.CamPath


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
}
# ImplementedButNotCheckedYet: TODO: foreach ($Filename in $State.input.CamPath)!! über Funktion loopen
# Hier wird außerdem der TEchnologie-Stuff gemacht!!
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

# Aktuell nicht in Verwendung:
function Set-Exlamationmarks {
  param(
    [array]$files
  )
  $files = $files | Select-Object -Unique
  foreach ($textfile in $files) {
    $textfile = $textfile.Replace("xcs", "pgmx")
    $dir = (Get-Item $textfile).Directory.FullName
    $filename = "!!!" + ((Get-Item $textfile).Name)
    $newsave = $dir + "\" + $filename
    $content | Out-File $newsave
    #Remove-Item $textfile
  }
}

# Sorgt dafür, dass bei einer zweiten Datei das CreateRawWorkPiece genullt wird
# ImplementedButNotCheckedYet: TODO: foreach ($Filenme in ((Get-ChildItem $State.WorkingDir | Where-Object { $_.FullName -like "*_2.xcs" } | Select-Object FullName).FullName)) {
function Correct-Offset_2 {
  foreach ($file2 in ((Get-ChildItem $State.WorkingDir | Where-Object { $_.FullName -like "*_2.xcs" } | Select-Object FullName).FullName)) {
    Write-Host "diese Datei wird nun von Correct-Function gecheckt: $file2" -ForegroundColor Green
    $count = 0
    Write-Host "HIER STEHT FILE2: $file2" -ForegroundColor Red
    $content = Get-Content $file2
    foreach ($line in $content) {
      if ($line -like "*CreateRawWorkpiece*") {
        $newstring = ($content[$count]) -replace ".{49}$"
        $newstring = $newstring + " 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000);"
        $content[$count] = $newstring
      }
      if ($line -like "*SetWorkpieceSetupPosition*") {
        $newstring = ($content[$count]) -replace ".{32}$"
        $newstring = $newstring + "0.0000, 0.0000, 0.0000, 0.0000);"
        $content[$count] = $newstring
      }
      $count++
    }

    $content | Out-File $file2

  }

}

# Öffnet das Verzeichnis, in welchem die Daten gespeichert werden
function Open-Dir {
  Invoke-Item $State.WorkingDir
}

# Erste Änderungen für die Dateien, die für alle Maschinen gültig sind
function First-Replace {
  param(
    $State
  )
  foreach ($Prog in $State.input) {

    (Get-Content $Prog.CamPath) | ForEach-Object {

      # Hier können Textersetzungen angegeben werden, welche dann in der xcs- bzw. pgmx-Datei wirksam werden
      $_.Replace("SlantedBladeCut", "Saegeschnitt_").
      Replace("Routing_", "Fraesen_").
      Replace("VerticalDrilling", "Vertikale Bohrung").
      Replace("HorizontalDrilling", "Horizontale Bohrung").
      Replace("PYTHA_INIT_", "Blindes Makro_").
      Replace("PYTHA_PARK_", "Wegfahrschritt_")

    } | Set-Content $Prog.CamPath

    # An- und Abfahrbewegung fliegend bohrend für Nut
    $insertnut = @()
    $insertnut += 'SetApproachStrategy(true, false, 1.5);'
    $insertnut += 'SetRetractStrategy(true, false, 1.5, 0);'
    $keywordnut = "CreateSlot"
    $textfile = $Prog.CamPath
    Add-StringBefore -insert $insertnut -keyword $keywordnut -textfile $textfile -bc $false

    # Anfahrbewegung fliegend bohrend und Strategie für Tasche (wenn nur 2 inserttaschen aktiv sind geht es nicht richtig)
    $inserttasche = @()
    $inserttasche += 'SetApproachStrategy(true, false, 5);'
    $inserttasche += 'SetRetractStrategy(true, false, 5, 5);'
    $inserttasche += 'CreateContourParallelStrategy(true, 0, true, 8, 0, 0);'
    $keywordtasche = "CreateContourPocket"
    $textfile = $Prog.CamPath
    Add-StringBefore -insert $inserttasche -keyword $keywordtasche -textfile $textfile -bc $false


    # Vorritzen, an- und abfahren mit dem Sägeblatt
    $insertblatt = @()
    $insertblatt += 'SetApproachStrategy(true, true, 0.25);'
    $insertblatt += 'SetRetractStrategy(true, true, 0.25, 0);'
    $insertblatt += 'CreateSectioningMillingStrategy(5, 120, 0);'
    $keywordblatt = "CreateBladeCut"
    $textfile = $Prog.CamPath
    Add-StringBefore -insert $insertblatt -keyword $keywordblatt -textfile $textfile -bc $true

  }

}



# Interaktion mit nativer CNC-Software (M200)
function convert-xcs-to-pgmx_m200 {

  #XConverter Maestro 64 Bit
  $State.XConverter = 'C:\Program Files\SCM Group\Maestro\XConverter.exe'
  #Maschineneinstellung M200
  $M200 = "C:\Users\Public\Documents\SCM Group\Maestro\Environments\M200"


  # Konvertieren in tmp pgmx
  & $State.XConverter -ow -s -report -m 0 -i $State.M200Infiles -env $M200 -o $State.M200tmpFiles | Out-Default
  # Bearbeitungen optimieren
  & $State.XConverter -ow -s -m 2 -i $State.M200tmpFiles -env $M200 -o $State.M200tmpFiles2 | Out-Default
  # Sauger positionieren
  & $State.XConverter -ow -s -m 13 -i $State.M200tmpFiles2 -env $M200 -o $State.M200outFiles | Out-Default
}

#############################################################################################################################################################################################################
# Beginn GUI Zeug
#############################################################################################################################################################################################################

Add-Type -AssemblyName PresentationCore, PresentationFramework

$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="800" Height="550" Topmost="True">
  <Grid>
    <TabControl Margin="2,0,-2,0" SelectedIndex="{Binding tabIndex}" Name="name">
      <TabItem Visibility="Collapsed" Header="Auswahl">
        <Grid Margin="0,-2,0,2" Name="selection" Background="#9b9b9b">
          <Button Content="5-Achs M200" HorizontalAlignment="Left" VerticalAlignment="Top" Width="210" Margin="33,160,0,0" Height="64" BorderBrush="#9b9b9b" Foreground="#000000" OpacityMask="#4a90e2" BorderThickness="5,5,5,5" FontFamily="Yu Gothic UI Bold *" FontSize="22" FontWeight="DemiBold" Background="#ffffff" Name="m200button"/>
          <Image HorizontalAlignment="Left" Height="171" VerticalAlignment="Top" Width="313" Margin="393,110,0,0" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\m200.png" Name="m200"/>
          <Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,320,0,0" Name="icon1" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\icon.png"/>
          <Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,320,0,0" Name="IconText1" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
        </Grid>
      </TabItem>
      <TabItem Visibility="Collapsed" Header="Fortschritt">
        <Grid Background="#9b9b9b" Margin="1,1,-1,-1" Name="wait">
          <Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,406,0,0" Name="icon2" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\icon.png"/>
          <Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,414,0,0" Name="IconText2" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
          <Image HorizontalAlignment="Left" Height="255" VerticalAlignment="Top" Width="571" Margin="185,97,0,0" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\warten.png"/>
          <Image HorizontalAlignment="Left" Height="245" VerticalAlignment="Top" Width="123" Margin="41,102,0,0" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\sanduhr.png"/>
        </Grid>
      </TabItem>
      <TabItem Visibility="Collapsed" Header="Ende">
        <Grid Background="#FFE5E5E5">
          <Image HorizontalAlignment="Left" Height="40" VerticalAlignment="Top" Width="40" Margin="722,406,0,0" Name="icon3" Source="C:\usr\Texturen GS Ravensburg\Geraete+Sonstiges\icon.png"/>
          <Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Gewerbliche Schule Ravensburg" Margin="387,414,0,0" Name="IconText3" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
          <Image HorizontalAlignment="Left" Height="102" VerticalAlignment="Top" Width="102" Margin="12,5,0,0" Name="errorimage" Source="C:\DevStuff\Projekt\Theo\error.png"/>
          
          <TextBox HorizontalAlignment="Left" VerticalAlignment="Top" Height="102" Width="356" TextWrapping="Wrap" Margin="94,224,0,0" Text="In der Konfiguration liegt ein Fehler vor! Bitte oeffne den Exportbericht!"/>
          <TextBlock HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="Fehler:" Margin="664,29,0,0" FontFamily="Yu Gothic UI Bold *" FontSize="021" FontWeight="DemiBold"/>
        </Grid>
      </TabItem>
    </TabControl>
  </Grid>
</Window>

"@
# <TextBox HorizontalAlignment="Left" VerticalAlignment="Top" Height="306" Width="471" Text="In der Konfiguration liegt ein Fehler vor!" TextWrapping="Wrap" Margin="292,82,0,0" Name="errorbox"/>
#-------------------------------------------------------------#
#----Control Event Handlers-----------------------------------#
#-------------------------------------------------------------#



#endregion

#-------------------------------------------------------------#
#----Script Execution-----------------------------------------#
#-------------------------------------------------------------#

$Window = [Windows.Markup.XamlReader]::Parse($Xaml)

[xml]$xml = $Xaml

$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }

$m200button.Add_Click({ Run-M200 $this $_ })

$State = [pscustomobject]@{}

function Set-Binding {
  param($Target, $Property, $Index, $Name)

  $Binding = New-Object System.Windows.Data.Binding
  $Binding.Path = "[" + $Index + "]"
  $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay



  [void]$Target.SetBinding($Property, $Binding)
}

function FillDataContext ($props) {

  for ($i = 0; $i -lt $props.Length; $i++) {

    $prop = $props[$i]
    $DataContext.Add($DataObject. "$prop")

    $getter = [scriptblock]::Create("return `$DataContext['$i']")
    $setter = [scriptblock]::Create("param(`$val) return `$DataContext['$i']=`$val")
    $State | Add-Member -Name $prop -MemberType ScriptProperty -Value $getter -SecondValue $setter

  }
}



$DataObject = ConvertFrom-Json @"

{
    "tabIndex" : 0,
    "GlobalError" : null,
    "Systempath" : null,
    "SystemCommand" : null,
    "SystemProfile" : null,
    "Program" : null,
    "XConverter" : null,
    "Infiles" : null,
    "M200Infiles" : null,
    "tmpFiles" : null,
    "M200tmpFiles" : null,
    "tmpFiles2" : null,
    "M200tmpFiles2" : null,
    "outFiles" : null,
    "M200outFiles" : null,
    "Tooling" : null,
    "WorkingDir" : null,
    "WorkingDirTemp" : null,
    "input" : null,
    "PSScriptRoot" : null
    
}

"@

$DataContext = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
FillDataContext @("tabIndex", "GlobalError", "Systempath", "SystemCommand", "SystemProfile", "Program", "XConverter", "Infiles", "tmpFiles", "tmpFiles2", "outFiles", "Tooling", "WorkingDir", "WorkingDirTemp", "input", "M200Infiles", "M200tmpFiles", "M200tmpFiles2", "M200outFiles", "PSScriptRoot")


$Window.DataContext = $DataContext
Set-Binding -Target $name -Property $([System.Windows.Controls.TabControl]::SelectedIndexProperty) -Index 0 -Name "tabIndex"



$Global:SyncHash = [hashtable]::Synchronized(@{})
$SyncHash.Window = $Window
$Jobs = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
$initialSessionState = [initialsessionstate]::CreateDefault()

function Start-RunspaceTask {
  [CmdletBinding()]
  param([Parameter(Mandatory = $True, Position = 0)] [scriptblock]$ScriptBlock,
    [Parameter(Mandatory = $True, Position = 1)] [PSObject[]]$ProxyVars)

  $Runspace = [runspacefactory]::CreateRunspace($InitialSessionState)
  $Runspace.ApartmentState = 'STA'
  $Runspace.ThreadOptions = 'ReuseThread'
  $Runspace.Open()
  foreach ($Var in $ProxyVars) { $Runspace.SessionStateProxy.SetVariable($Var.Name, $Var.Variable) }
  $Thread = [powershell]::Create('NewRunspace')
  $Thread.AddScript($ScriptBlock) | Out-Null
  $Thread.Runspace = $Runspace
  [void]$Jobs.Add([psobject]@{ PowerShell = $Thread; Runspace = $Thread.BeginInvoke() })
}

$JobCleanupScript = {
  do {
    foreach ($Job in $Jobs) {
      if ($Job.Runspace.IsCompleted) {
        [void]$Job.PowerShell.EndInvoke($Job.Runspace)
        $Job.PowerShell.Runspace.Close()
        $Job.PowerShell.Runspace.Dispose()
        $Job.PowerShell.Dispose()

        $Jobs.Remove($Job)
      }
    }

    Start-Sleep -Seconds 1
  }
  while ($SyncHash.CleanupJobs)
}

Get-ChildItem Function: | Where-Object { $_.Name -notlike "*:*" } | Select-Object name -ExpandProperty name |
ForEach-Object {
  $Definition = Get-Content "function:$_" -ErrorAction Stop
  $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList "$_", $Definition
  $InitialSessionState.Commands.Add($SessionStateFunction)
}


$Window.Add_Closed({
    Write-Verbose 'Halt runspace cleanup job processing'
    $SyncHash.CleanupJobs = $False
  })

$SyncHash.CleanupJobs = $True
function Async ($scriptBlock) { Start-RunspaceTask $scriptBlock @([psobject]@{ Name = 'DataContext'; Variable = $DataContext }, [psobject]@{ Name = "State"; Variable = $State }, [psobject]@{ Name = "SyncHash"; Variable = $SyncHash }) }

Start-RunspaceTask $JobCleanupScript @([psobject]@{ Name = 'Jobs'; Variable = $Jobs })


#############################################################################################################################################################################################################
# Ende GUI Zeug
#############################################################################################################################################################################################################



# Verhindert, dass eine PowerShell-Konsole angezeigt wird (lediglich GUI wird an Frontend ausgegeben)
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)

# State-Variables: Programm ist multithreaded - diese Variablen sind aus jedem Thread heraus lesend/schreibend zugreifbar
$State.Systempath = $Systempath
$State.SystemCommand = $SystemCommand
$State.SystemProfile = $SystemProfile
$State.Program = $Program

$State.input = $inputjson

$State.Infiles = @()
$State.tmpFiles = @()
$State.tmpFiles2 = @()
$State.outFiles = @()

$State.M200Infiles = @()
$State.M200tmpFiles = @()
$State.M200tmpFiles2 = @()
$State.M200outFiles = @()


$State.WorkingDir
$State.WorkingDirTemp


# Set WorkingDir (Directory where the magic happens)
if ($inputjson -is [array]) {
  $inputarray = $inputjson[0]
  $raw = [System.IO.DirectoryInfo]$inputarray.CamPath
  $State.WorkingDir = $raw.Parent.FullName
}
else {
  $raw = [System.IO.DirectoryInfo]$inputjson.CamPath
  $State.WorkingDir = $raw.Parent.FullName
}

# M200-spezifische Änderungen
function Run-M200 () {
  $State.PSScriptRoot = $PSScriptRoot
  # HINWEIS: Hier muss man auf m200cb verweisen, da das die Checkbox unter dem M220-Button ist!
  Async {
					   

    function Run-Modification {
      param (
        $State,
        $int
      )

      # Logging


      if ($int -eq 2) {
        # Clear CreateRawWorkpiece 
        if ($State.input -is [array]) {
          foreach ($one in $State.input) {
            $temppath = $State.WorkingDir + "\temp.xcs"
            Get-Content $one.CamPath | Where-Object { $_ -notlike 'CreateRawWorkpiece*' } | Set-Content $temppath
            Get-Content $temppath | Set-Content $one.CamPath
            #Remove-Item $temppath
          }
      
        }
        else {
          $temppath = $State.WorkingDir + "\temp.xcs"
          Get-Content $State.input.CamPath | Where-Object { $_ -notlike 'CreateRawWorkpiece*' } | Set-Content $temppath
          Get-Content $temppath | Set-Content $State.input.CamPath
          #Remove-Item $temppath
        }

        # Edit Set MachineParameters
        if ($State.input -is [array]) {
          foreach ($one in $State.input) {
            $temppath = $State.WorkingDir + "\temp.xcs"
            $currentcontent = Get-Content $one.CamPath | Where-Object { $_ -notlike 'SetMachiningParameters*' }
            'SetMachiningParameters("AB", 1, 10, 16777216, false);' | Set-Content $temppath
            $currentcontent | Add-Content $temppath
            Get-Content $temppath | Set-Content $one.CamPath
            #Remove-Item $temppath
          }
        
        }
        else {
          $temppath = $State.WorkingDir + "\temp.xcs"
          $currentcontent = Get-Content $State.input.CamPath | Where-Object { $_ -notlike 'SetMachiningParameters*' }
          'SetMachiningParameters("AB", 1, 10, 16777216, false);' | Set-Content $temppath
          $currentcontent | Add-Content $temppath
          Get-Content $temppath | Set-Content $State.input.CamPath
          #Remove-Item $temppath
        }
      }

      # Global Vars
      $count = 0
      # Change Screen
      $State.tabIndex = 1

      First-Replace -State $State

      #foreach ($Filename in $State.input.CamPath) {
      Replace-SetMacroParam
      Bohrer
      Feldanpassung
      #}

      if ($int -eq 1) {
        Foreach ($Prog in $State.input) {
          # Approach- und RetractStrategie ersetzen
            (Get-Content $Prog.CamPath) | ForEach-Object {
      
            # Im Bogen an- und abfahren mit 5 mm Überlappung für Bauteilumfräsung
            $_.Replace("SetApproachStrategy(true, false, -1)", "SetApproachStrategy(false, true, 2)").
            Replace("SetRetractStrategy(true, false, -1, 0)", "SetRetractStrategy(false, true, 2, 5)")
      
          } | Set-Content $Prog.CamPath
        }
      
        # Edit Set MachineParameters
        # Wenn Array
        if ($State.input -is [array]) {
          foreach ($one in $State.input) {
            $temppath = $State.WorkingDir + "\temp.xcs"
            $currentcontent = Get-Content $one.CamPath | Where-Object { $_ -notlike 'SetMachiningParameters*' }
            'SetMachiningParameters("AB", 1, 11, 10, false);' | Set-Content $temppath
            $currentcontent | Add-Content $temppath
            Get-Content $temppath | Set-Content $one.CamPath
            #Remove-Item $temppath
          }
        
        }
        # Wenn kein Array
        else {
          $temppath = $State.WorkingDir + "\temp.xcs"
          $currentcontent = Get-Content $State.input.CamPath | Where-Object { $_ -notlike 'SetMachiningParameters*' }
          'SetMachiningParameters("AB", 1, 11, 10, false);' | Set-Content $temppath
          $currentcontent | Add-Content $temppath
          Get-Content $temppath | Set-Content $State.input.CamPath
          #Remove-Item $temppath
        }
      }
        
      if ($int -eq 2) {
        try {
          foreach ($Filenme in ((Get-ChildItem $State.WorkingDir | Where-Object { $_.FullName -like "*_2.xcs" } | Select-Object FullName).FullName)) {
            Correct-Offset_2($Filename)
          }
        }
        catch {}
      }




      # CNC-Software nativ
      if ($int -eq 1) {
        foreach ($Prog in $State.input) {
          if ($count -ge 200) {
            # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden		
            
            convert-xcs-to-pgmx_m200
            
            $count = 0
            $State.M200Infiles = ""
            $State.M200tmpFiles = ""
            $State.M200tmpFiles2 = ""
            $State.M200outFiles = ""
          }
            
            
          $xcsPath = $Prog.CamPath
          $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
          $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
          $tmpPath2 = $xcsPath -replace '.xcs$', '__tmp2.pgmx'
            
            
          $count += 1
          [array]$State.M200Infiles += $xcsPath
          [array]$State.M200outFiles += $pgmxPath
          [array]$State.M200tmpFiles += $tmpPath
          [array]$State.M200tmpFiles2 += $tmpPath2
        }
        convert-xcs-to-pgmx_m200
      }
      elseif ($int -eq 2) {
        foreach ($Prog in $State.input) {
          if ($count -ge 200) {
            # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden		
            
            convert-xcs-to-pgmx_m200

          }
            
            
          $xcsPath = $Prog.CamPath
          $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
          $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
          $tmpPath2 = $xcsPath -replace '.xcs$', '__tmp2.pgmx'
            
          $count += 1

        }
      }

          
      # Kurz warten
      Start-Sleep 1
              
              
              
              

        
    }
    $path = $State.WorkingDir + "\exportbericht.txt"
    Start-Transcript -Path $path
      
    # Global Vars
    $count = 0
    
    $State.tabIndex = 1
    First-Replace -State $State
    Replace-SetMacroParam
        
    
    Foreach ($Prog in $State.input) {
      # Approach- und RetractStrategie ersetzen
          (Get-Content $Prog.CamPath) | ForEach-Object {
    
        # Im Bogen an- und abfahren mit 5 mm Überlappung für Bauteilumfräsung
        $_.Replace("SetApproachStrategy(true, false, -1)", "SetApproachStrategy(false, true, 2)").
        Replace("SetRetractStrategy(true, false, -1, 0)", "SetRetractStrategy(false, true, 2, 5)")
    
      } | Set-Content $Prog.CamPath
    }
    
    # Edit Set MachineParameters
    # Wenn Array
    if ($State.input -is [array]) {
      foreach ($one in $State.input) {
        $temppath = $State.WorkingDir + "\temp.xcs"
        $currentcontent = Get-Content $one.CamPath | Where-Object { $_ -notlike 'SetMachiningParameters*' }
        'SetMachiningParameters("AB", 1, 11, 10, false);' | Set-Content $temppath
        $currentcontent | Add-Content $temppath
        Get-Content $temppath | Set-Content $one.CamPath
        #Remove-Item $temppath
      }
      
    }
    # Wenn kein Array
    else {
      $temppath = $State.WorkingDir + "\temp.xcs"
      $currentcontent = Get-Content $State.input.CamPath | Where-Object { $_ -notlike 'SetMachiningParameters*' }
      'SetMachiningParameters("AB", 1, 11, 10, false);' | Set-Content $temppath
      $currentcontent | Add-Content $temppath
      Get-Content $temppath | Set-Content $State.input.CamPath
      #Remove-Item $temppath
    }
        
    
    try {
      foreach ($Filenme in ((Get-ChildItem $State.WorkingDir | Where-Object { $_.FullName -like "*_2.xcs" } | Select-Object FullName).FullName)) {
        Correct-Offset_2($Filename)
      }
    }
    catch {}
    
    
    # CNC-Software nativ
    foreach ($Prog in $State.input) {
      if ($count -ge 200) {
        # Die Kommandozeile darf nicht laenger als 8000 Zeichen werden		
    
        convert-xcs-to-pgmx_m200
    
        $count = 0
        $State.M200Infiles = ""
        $State.M200tmpFiles = ""
        $State.M200tmpFiles2 = ""
        $State.M200outFiles = ""
      }
    
    
      $xcsPath = $Prog.CamPath
      $pgmxPath = $xcsPath -replace '.xcs$', '.pgmx'
      $tmpPath = $xcsPath -replace '.xcs$', '__tmp.pgmx'
      $tmpPath2 = $xcsPath -replace '.xcs$', '__tmp2.pgmx'
    
    
      $count += 1
      [array]$State.M200Infiles += $xcsPath
      [array]$State.M200outFiles += $pgmxPath
      [array]$State.M200tmpFiles += $tmpPath
      [array]$State.M200tmpFiles2 += $tmpPath2
    }
    convert-xcs-to-pgmx_m200
    
    # Kurz warten
    Start-Sleep 1
    

    # Remove TmpFiles
    $errorc = $error.Count
    Get-ChildItem -Path $State.WorkingDir *tmp* | ForEach-Object { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue }
    Get-ChildItem -Path $State.WorkingDir *temp* | ForEach-Object { Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue }
    if ($errorc -eq 0) {
      $error.Clear()
    }
  
    # Error Handling
    if ($error.Count -gt 0) {
      Write-ToLog -logmessage ($error[0].ToString() + $error[0].InvocationInfo.PositionMessage)
      $State.tabIndex = 2
      Stop-Transcript
      Open-Dir
    }
    else {
      Open-Dir
      Stop-Transcript
      Stop-Process -Name *powershell*
    }
  }

}




# Definition der Pfade zu Speicherdateien
# SConverter Maestro 64 Bit
$State.XConverter = 'C:\Program Files\SCM Group\Maestro\XConverter.exe'
$Window.ShowDialog()