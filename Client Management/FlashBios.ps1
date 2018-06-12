<#
.SYNOPSIS
Flashs a new BIOS to a Dell Device, Ment to be used in a SCCM Task Sequence

.DESCRIPTION
The script will compair the version the BIOS to the version of the exe and perform the appropriate action.

1. Create a folder in your content Library called DellBIOS
2. Create a folder for each comeputer model you wnat the scrip to run for (Name must be exactly the same as the model)
3. Place the BIOS file in that folder with a txt file called version.txt, In the txt file write the version of the bios file

Error codes 
268: Could not mount BIOS file location
256: An Error ocured when trying to copy files to PE location
1: Could not Flash the BIOS
20: BIOS dosnt need to be updated
2: Reboot is needed 
0: success

.PARAMETER Password
Password for the account used to connect to your content library

.PARAMETER AccessAccount
Account used to connect to the content library 

.PARAMETER Log 
Path to the log file

.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 1.0.0.0

.LINK
You can get updates to this script and others from here
http://www.sccmtst.com/
#>


PARAM(
    [String]$Password,
    [String]$Log = "$Env:SystemDrive\FlashBIOS.txt",
    [string]$AccessAccount
)

#Creates the object for a SCCM TS Variable
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue
$tsenv.Value("SMSTS_BiosUpdate") = "True"

$BIOSVersion = (Get-WmiObject win32_BIOS).name 
$ComputerModel = (Get-WmiObject win32_ComputerSystem).Model
#Path to where BIOS files are held
$BIOSFilePath = "\\ServerName\ContentLibrary\DellBIOS"

Net use J: $BIOSFilePath /user:$AccessAccount $Password 
IF ($LASTEXITCODE -eq 1)
{
    Write-Error "Could not mount BIOS loaction:$_"
    Add-Content $Log "Could not mount BIOS loaction:$_"
    #Writes exist the script in a way that allows sccm to see the exit code 
    [System.Environment]::Exit(268)
}

$FlashBIOSVersion = Get-Content "J:\$ComputerModel\Version.txt"
$FlashBIOSVersion = $FlashBIOSVersion.Trim()

IF ($BIOSVersion -ge  $FlashBIOSVersion) 
{
    Write-Host "BIOS dosnt need to be updated"
    Add-Content $Log "BIOS dosnt need to be updated"
    [System.Environment]::Exit(20)
}

IF ($BIOSVersion -lt $FlashBIOSVersion)
{
    Write-Host "BIOS needs updated"
    Add-Content $Log "BIOS needs updated"
    
    
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
        [System.Environment]::Exit(256)
    }

    $Run = Start-Process $PSScriptRoot\FlashBIOS\Flash64W.exe -ArgumentList $Commands -PassThru -Wait 
    $Run
}

If ($Run.ExitCode -eq 2) 
{
    $tsenv.Value("SMSTS_BiosUpdateRebootRequired") = "True"
    [System.Environment]::Exit(2)
} 
else 
{ 
    $tsenv.Value("SMSTS_BiosUpdateRebootRequired") = "False"
}

If ($Run.ExitCode -eq 0) {[System.Environment]::Exit(0)}

If ($Run.ExitCode -eq 1) 
{
    Write-Error "Could not Flash BIOS: $_"
    Add-Content $Log "Could not Flash BIOS: $_"
    [System.Environment]::Exit(1)
}

Start-Sleep -Seconds 45