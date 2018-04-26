<#
.SYNOPSIS
Updates the BIOS for Dell Computers

.DESCRIPTION
Flashes the BIOS for dell computers using the Flash64W.exe utility

.PARAMETER Password
The password of the service account used to connect to the location of the BIOS files

.PARAMETER Log
Path to the log file 

.NOTES
This script is part of the SCCM Task Sequence GUI 
You will need to download the Flash64W.exe utility before you use it 
http://en.community.dell.com/techcenter/enterprise-client/w/wiki/12237.64-bit-bios-installation-utility

1. Create a Folder in your Content Library called FlashBIOS
2. Create a Folder called Script, Copy this script to that folder
3. Create a Folder in the FlashBIOS folder Called Flash64W
4. Download the Flash64W utility and place it in the Flash64W folder 
5. Create a package for the script file and do not create a program for it 
6. Create a task in your TS for running a command line, Command Line: %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command ".\FlashBios.ps1 -AccessAccount Domain\User -Password PASSWORD"
7. Check the box for a Package and point it to the package you created for the script 
8. If you only want the script to run for a specific model add an option for a wmi query: Select * FROM Win32_ComputerSystem WHERE Model = 'Latitude 5590'
9. Create a Reboot task, add an option for a TS veriable, Variable: SMSTS_BiosUpdateRebootRequired  Condition: True  Value: True

For each computer model that you want to update the BIOS on create a folder in the FlashBIOS folder exactly what the model is
Place the exe file in the folder and create a Version.txt file containg the BIOS version number of the exe 

Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 1.0.0.0

.LINK
You can get updates to this script and others from here
http://www.sccmtst.com/
#>

PARAM(
    [string]$AccessAccount,
    [String]$Password,
    [String]$Log = "$Env:SystemDrive\FlashBIOS.txt"
)

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue
$tsenv.Value("SMSTS_BiosUpdate") = "True"

$BIOSVersion = (Get-WmiObject win32_BIOS).name 
$ComputerModel = (Get-WmiObject win32_ComputerSystem).Model
$BIOSFilePath = "\\it-cmmp\ContentLibrary\BIOS"

Net use J: $BIOSFilePath /user:$AccessAccount $Password 
IF ($LASTEXITCODE -eq 1)
{
    Write-Error "Could not mount BIOS loaction:$_"
    Add-Content $Log "Could not mount BIOS loaction:$_"
    $host.SetShouldExit(268)
}

$FlashBIOSVersion = Get-Content "J:\$ComputerModel\Version.txt"

IF ($BIOSVersion -ge  $FlashBIOSVersion) 
{
    Write-Host "BIOS dosnt need to be updated"
    Add-Content $Log "BIOS dosnt need to be updated"
    $host.SetShouldExit(20)
}

IF ($BIOSVersion -lt $FlashBIOSVersion)
{
    Write-Host "BIOS needs updated"
    Add-Content $Log "BIOS needs updated"
    
    # $FlashBIOSFile = Get-ChildItem "J:\$ComputerModel\*.exe"
    $BiosFileName = Get-ChildItem "J:\$ComputerModel\*.exe" -Verbose | Select-Object -ExpandProperty Name
    $Commands = "/b=$PSScriptroot\FlashBIOS\$BiosFileName /s /p=$BiosPassword /l=$LogPath\$BiosLogFileName"
    
    try {
        New-Item "$PSScriptRoot\FlashBIOS" -ItemType Directory -ErrorAction Stop
        Copy-Item "J:\Flash64W\Flash64W.exe" "$PSScriptRoot\FlashBIOS" -Force -ErrorAction Stop
        Copy-Item "J:\$ComputerModel\*.exe" "$PSScriptRoot\FlashBIOS" -Force -ErrorAction Stop
    }
    catch {
        Write-Error "$_"
        Add-Content $Log "Could not copy files: $_"
        $host.SetShouldExit(256)
    }

    $Run = Start-Process $PSScriptRoot\FlashBIOS\Flash64W.exe -ArgumentList $Commands -PassThru -Wait 
    $Run
}

If ($Run.ExitCode -eq 2) 
{
    $tsenv.Value("SMSTS_BiosUpdateRebootRequired") = "True"
    $host.SetShouldExit(0)
} 
else 
{ 
    $tsenv.Value("SMSTS_BiosUpdateRebootRequired") = "False"
}

If ($Run.ExitCode -eq 0) {$host.SetShouldExit(0)}

If ($Run.ExitCode -eq 1) 
{
    Write-Error "Could not Flash BIOS: $_"
    Add-Content $Log "Could not Flash BIOS: $_"
    $host.SetShouldExit(263)
}

Start-Sleep -Seconds 45