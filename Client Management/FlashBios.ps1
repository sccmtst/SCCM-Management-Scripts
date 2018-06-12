<#
Error codes 
268: Could not moint BIOS location
256: And Error ocured when trying to copy files to PE location
1: Could not Flash the BIOS
20: BIOS dosnt need to be updated
2: Reboot is needed 
0: success

#>

PARAM(
    [String]$Password,
    [String]$Log = "$Env:SystemDrive\FlashBIOS.txt",
    [string]$AccessAccount
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
    [System.Environment]::Exit(268)
}

$FlashBIOSVersion = Get-Content "J:\$ComputerModel\Version.txt"
$FlashBIOSVersion = $FlashBIOSVersion.Trim()

IF ($BIOSVersion -ge  $FlashBIOSVersion) 
{
    Write-Host "BIOS dosnt need to be updated"
    Add-Content $Log "BIOS dosnt need to be updated"
    [System.Environment]::Exit(20)
    # $host.SetShouldExit(20)
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
    #     $host.SetShouldExit(256)
    }

    $Run = Start-Process $PSScriptRoot\FlashBIOS\Flash64W.exe -ArgumentList $Commands -PassThru -Wait 
    $Run
}

If ($Run.ExitCode -eq 2) 
{
    $tsenv.Value("SMSTS_BiosUpdateRebootRequired") = "True"
    [System.Environment]::Exit(2)
    # $host.SetShouldExit(0)
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