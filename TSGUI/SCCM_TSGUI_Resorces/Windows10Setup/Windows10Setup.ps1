<#
.SYNOPSIS
Configures popular settings on a workstation for first time use 

.DESCRIPTION
This script can be used to remove built in windows 10 apps,Export a Custome Start Menu config file,Import a default start menu config file,
Disable OneDrive, Disbale Cortana, Disable Hibernate, Join a workstation to a domain, Rename the workstation, Set the page file size, Disable Windows Tips,
Disable the Consumer experience and Disable the Xbox Services.

.PARAMETER RemoveApps
Use this switch enable app removal

.PARAMETER AppsToRemove
Specifyes the list of apps to be removed, if not used then will use a list of apps built into the script

.PARAMETER Preset
The preset parameter will run the script with specific settings
CleanOS - Disables Ads, Widnows Store, Consumer Experience, Windows Tip, Cortana, Xbox Services, and OneDrive. Sets the page file removes all most all apps 
EveryDayUser - Disables Ads, Removes all most all apps and Sets the page file size

.PARAMETER StartMenuLayout
Specifyes the xml file for the start menu layout

.PARAMETER ExportStartMenuLayout
Exports the curent start menu layout to be used on other workstation

.PARAMETER DisableAds
Disables all ads and sujected apps from the start menu, explorer, and lock screen

.PARAMETER DisableOneDrive
Disables OneDrive on the workstation

.PARAMETER DisableCortana
Disables Cortana on the workstation

.PARAMETER DisableHibernate
Disables the hibernate power setting

.PARAMETER SetPowerConfig
Sets the power settings by defult I have this set to disable standby and Disk Timeout

.PARAMETER DisableWindowsStore
Disables access to the Windows Store, The app is still listed

.PARAMETER DisableConsumerExperience
Disables The installation of extra apps and the pinning of links to Windows Store pages of third-party applications

.PARAMETER SetWiredAutoConfigService
Seting this service will disable the wired ethernet card when wirless is in use and disables the wireless when the ethernet card is in use.

.PARAMETER JoinDomain
Joins the computer to a domain

.PARAMETER Account
Account used to join to a domain, if not specified you will be asked for the account

.PARAMETER Domain
Domain to join when the JoinDomain Parameter is used, if not specified you will be asked for the domain

.PARAMETER RenameComputer
Renames the workstation to what is specified for the parameter

.PARAMETER SetPageFile
Sets the page file size to the recomended ammount based on the ammount of memmory installed on the device

.PARAMETER PageFileDrive
Moves the page file to a new drive, if not specified will default to the C drive

.PARAMETER Reboot 
Reboots the computer after all other taskes have been performed

.EXAMPLE
.\Win10Setup.ps1 -RemoveApps -AppsToRemove AppsList.txt
Removes all apps in the AppsList.txt file

.EXAMPLE
.\Win10Setup.ps1 -StartMenuLayout StartMenuLayout.xml
Imports the xml file to use as the default start menu layout for all new users
To build your xml run Export-StartLayout -Path "C:\example\StartMenuLayout.xml"

.EXAMPLE 
.\Win10Setup.ps1 -StartMenuLayout StartMenuLayout.xml -RemoveApps -AppsToRemove AppsToRemove.txt -DisableOneDrive -DisableCortana
Imports the start menu config removes apps listed in the txt file disbales one drive and cortana.

.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 2.1.0.2

.LINK
You can get updates to this script and others from here
http://www.sccmtst.com/
#>

Param(
        [Switch]$RemoveApps,
        [string]$AppsToRemove,
        [string]$StartMenuLayout,
        [Switch]$SetPageFile,
        $PageFileDrive,
        [Switch]$EnableRDP,
        [Switch]$DisableOneDrive,
        [Switch]$DisableCortana,
        [Switch]$DisableWindowsTips,
        [Switch]$DisableConsumerExperience,
        [Switch]$DisableHibernate,
        [Switch]$SetPowerConfig,
        [Switch]$DisableXboxServices,
        [Switch]$DisableAds,
        [Switch]$DisableWindowsStore,
        [Switch]$DisableConnectToInternetUpdates,
        [ValidateSet('Mountain Standard Time','Pacific Standard Time','Eastern Standard Time','Central Standard Time')]
        $SetTimeZone,
        [Switch]$InstallDC,
        [Switch]$JoinDomain,
        [string]$Account,
        [string]$Domain,
        [string]$RenameComputer,
        [ValidateSet('CleanOS','EveryDayUser','DomainComputerSetup')]
        $Preset,
        [Switch]$ExportStartMenuLayout,
        [Switch]$Reboot
    )

function Read-Error
{
    Write-Error "$ErrorText"
    exit
}

Function Export-StartMenuLayout
{
    $ExportFile = Read-Host "Export Config Name (Must be a XML file)"
    Export-StartLayout -Path "$PSScriptRoot\$ExportFile"
    Write-Host "Config Saved To: $PSScriptRoot\$ExportFile"
}

Function Import-StartMenuLayout
{
    Param
    (
        [ValidateSet('Blank','Admin','EveryDayUser')]
        $PreSetLayout
    )
$BlankLayout = @"
<LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="6" />
    <DefaultLayoutOverride>
    <StartLayoutCollection>
        <defaultlayout:StartLayout GroupCellWidth="6" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout">
        <start:Group Name="" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout">
            <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
        </start:Group>
        </defaultlayout:StartLayout>
    </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

$EveryDayUser = @"
<LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
<LayoutOptions StartTileGroupCellWidth="6" />
<DefaultLayoutOverride>
  <StartLayoutCollection>
    <defaultlayout:StartLayout GroupCellWidth="6" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout">
      <start:Group Name="" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout">
        <start:Tile Size="2x2" Column="4" Row="2" AppUserModelID="Microsoft.WindowsCalculator_8wekyb3d8bbwe!App" />
        <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\computer.lnk" />
        <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
        <start:Tile Size="2x2" Column="0" Row="0" AppUserModelID="Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge" />
        <start:Tile Size="2x2" Column="0" Row="2" AppUserModelID="Microsoft.ZuneVideo_8wekyb3d8bbwe!Microsoft.ZuneVideo" />
        <start:Tile Size="2x2" Column="2" Row="2" AppUserModelID="Microsoft.Windows.Photos_8wekyb3d8bbwe!App" />
        <start:Tile Size="2x2" Column="0" Row="4" AppUserModelID="Microsoft.WindowsStore_8wekyb3d8bbwe!App" />
        <start:Tile Size="2x2" Column="2" Row="4" AppUserModelID="windows.immersivecontrolpanel_cw5n1h2txyewy!microsoft.windows.immersivecontrolpanel" />
        <start:Tile Size="2x2" Column="4" Row="4" AppUserModelID="Microsoft.BingWeather_8wekyb3d8bbwe!App" />
      </start:Group>
    </defaultlayout:StartLayout>
  </StartLayoutCollection>
</DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

    #Configures the start menu layout
    
    #Copyies a IE Shortcut to the all users start menu so all users will have it on the start menu
    #Copy-Item -Path "Internet Explorer.lnk" -Destination "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
    IF (!($StartMenuLayout) -and ($PreSetLayout -EQ "Blank")) 
    {
        add-content $Env:TEMP\BlankLayout.xml $BlankLayout
        $StartMenuLayout = "$Env:TEMP\BlankLayout.xml"
    }
    IF (!($StartMenuLayout) -and ($PreSetLayout -EQ "EveryDayUser")) 
    {
        add-content $Env:TEMP\EveryDayUser.xml $EveryDayUser
        $StartMenuLayout = "$Env:TEMP\EveryDayUser.xml"
    }
    Write-Host importing $StartMenuLayout
    Import-StartLayout -LayoutPath $StartMenuLayout -MountPath C:\
}

Function Disable-OneDrive
{
    Write-Host 'Disabling OneDrive'
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
    $Name = "DisableFileSyncNGSC"
    $Value = "1"
    $Type = "DWORD"

    Set-Location HKLM:
    if (!(test-Path .\SOFTWARE\Policies\Microsoft\Windows\OneDrive)) {New-Item .\SOFTWARE\Policies\Microsoft\Windows\OneDrive}
    New-ItemProperty -Path $RegPath -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Set-Location $PSScriptRoot
}

Function Disable-XboxServices
{
    Write-Host "Disabling Xbox Services"
    Get-Service XblAuthManager,XblGameSave,XboxNetApiSvc,WMPNetworkSvc | stop-service -passthru | set-service -startuptype disabled
}

Function Disable-Cortana
{
    Write-Host "Disabling Cortana"
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    $Name = "AllowCortana"
    $Value = "0"
    $Type = "DWORD"

    Set-Location HKLM:
    if (!(test-Path .\SOFTWARE\Policies\Microsoft\Windows\"Windows Search")) {New-Item .\SOFTWARE\Policies\Microsoft\Windows\"Windows Search"}
    New-ItemProperty -Path $RegPath -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Set-Location $PSScriptRoot
}

Function Disable-WindowsTips
{
    Write-Host 'Disabling Windows Tip'
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    $Name = "DisableSoftLanding"
    $Value = "1"
    $Type = "DWORD"

    Set-Location HKLM:
    if (!(test-Path .\SOFTWARE\Policies\Microsoft\Windows\CloudContent)) {New-Item .\SOFTWARE\Policies\Microsoft\Windows\CloudContent}
    New-ItemProperty -Path $RegPath -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Set-Location $PSScriptRoot
}

Function Disable-ConsumerExperience
{
    Write-Host 'Disabling Consumer Experience'
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    $Name = "DisableWindowsConsumerFeatures"
    $Value = "1"
    $Type = "DWORD"

    Set-Location HKLM:
    if (!(test-Path .\SOFTWARE\Policies\Microsoft\Windows\CloudContent)) {New-Item .\SOFTWARE\Policies\Microsoft\Windows\CloudContent}
    New-ItemProperty -Path $RegPath -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Set-Location $PSScriptRoot
}

Function Disable-Hibernate
{
    powercfg.exe /hibernate off
    If (!(test-Path -path $Env:SystemDrive\Hiberfil.sys)) {Write-Host "Hibernate Disabled"}
    IF (Test-Path -Path $Env:SystemDrive\Hiberfil.sys) {Write-Host "Hibernate was not Disabled"}
}

Function Disable-Ads
{
    $reglocation = "HKCU"
    #Start menu ads
    Write-Host 'Disabling Start Menu Ads for Current User'
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /T REG_DWORD /V "SystemPaneSuggestionsEnabled" /D 0 /F
    #Lock Screen suggestions
    Write-Host 'Disabling Lock Screen Suggentions for Current User'
    Reg Add "$reglocation\SOFTWARE\Microsoft\CurrentVersion\ContentDeliveryManager" /T REG_DWORD /V "SoftLandingEnabled" /D 0 /F
    Write-Host "Disabling explorer ads for current user"
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /T REG_DWORD /V "ShowSyncProviderNotifications" /D 0 /F

    $reglocation = "HKLM\AllProfile"
    reg load "$reglocation" c:\users\default\ntuser.dat
    Write-Host 'Disabling Start Menu Ads for default user'
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /T REG_DWORD /V "SystemPaneSuggestionsEnabled" /D 0 /F
    Write-Host 'Disabling Lock Screen Suggentions for Current User'
    Reg Add "$reglocation\SOFTWARE\Microsoft\CurrentVersion\ContentDeliveryManager" /T REG_DWORD /V "SoftLandingEnabled" /D 0 /F
    Write-Host "Disabling explorer ads for default user"
    Reg Add "$reglocation\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /T REG_DWORD /V "ShowSyncProviderNotifications" /D 0 /F
    #unload default user hive
    [gc]::collect()
    reg unload "$reglocation"
}

Function Disable-WindowsStore
{
    Write-Host 'Disabling Windows Tip'
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    $Name = "DisableSoftLanding"
    $Value = "1"
    $Type = "DWORD"

    Set-Location HKLM:
    if (!(test-Path .\SOFTWARE\Policies\Microsoft\Windows\CloudContent)) {New-Item .\SOFTWARE\Policies\Microsoft\Windows\CloudContent}
    New-ItemProperty -Path $RegPath -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Set-Location $PSScriptRoot
}

Function Remove-Apps
{
    If ($AppsToRemove) 
    {
        If (!(Test-Path $AppsToRemove))
        {
            $ErrorText = "Could not find $AppsToRemove"
            Read-Error
        }
        $AppsList = Get-Content $AppsToRemove
        #Removes some windows apps
        Foreach ($App in ($AppsList))
        {
            $item = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -Like "*$App*"} 
            Write-Host "Removing $App"
            Remove-AppxProvisionedPackage -Online -PackageName $item.PackageName -erroraction silentlycontinue
            Remove-AppxProvisionedPackage -Online -PackageName $item.PackageName -erroraction silentlycontinue
            Get-AppxPackage -AllUsers | Where-Object Name -Like "*$App*" | Remove-AppxPackage -erroraction silentlycontinue
        }
    }
    If (!($AppsToRemove))
    {
        Get-AppxPackage -AllUsers | where-object {$_.name -notlike "*Store*" -and $_.name -notlike "*Calculator*" -and $_.name -notlike "*Windows.Photos*" -and $_.name -notlike "*SoundRecorder*" -and $_.name -notlike "*MSPaint*" -and $_.name -notlike "*ZuneVideo*" -and $_.name -notlike "*BingWeather*" -and $_.name -notlike "*sticky*"} | Remove-AppxPackage -erroraction silentlycontinue
        Get-AppxPackage -AllUsers | where-object {$_.name -notlike "*Store*" -and $_.name -notlike "*Calculator*" -and $_.name -notlike "*Windows.Photos*" -and $_.name -notlike "*SoundRecorder*" -and $_.name -notlike "*MSPaint*" -and $_.name -notlike "*ZuneVideo*" -and $_.name -notlike "*BingWeather*" -and $_.name -notlike "*sticky*" } | Remove-AppxPackage -erroraction silentlycontinue
        Get-AppxProvisionedPackage -online | where-object {$_.displayname -notlike "*Store*" -and $_.displayname -notlike "*Calculator*" -and $_.displayname -notlike "*Windows.Photos*" -and $_.displayname -notlike "*SoundRecorder*"  -and $_.displayname -notlike "*MSPaint*" -and $_.name -notlike "*ZuneVideo*" -and $_.name -notlike "*BingWeather*" -and $_.name -notlike "*sticky*" } | Remove-AppxProvisionedPackage -online -erroraction silentlycontinue
    }
}

Function Set-PageFile
{
    #Gets total memory 
    $Getmemorymeasure = Get-WMIObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    #Converts the memory into GB
    $TotalMemSize = $($Getmemorymeasure.sum/1024/1024/1024)

    if ($PageFileDrive -eq $null)
    {
        $Drive = "C:"
    }
    else 
    {
        IF ($PageFileDrive -like "*:")
        {
            $Drive = $PageFileDrive
        }
        else 
        {
            $Drive = $PageFileDrive + ":"
        }
    }
    #recomended Page file size is double the memory installed
    Write-Host "Setting Page file size on: $Drive"
    write-host "Total Memory Installed (gb): $TotalMemSize"
    #2gb
    If (($TotalMemSize -gt "1") -and ($TotalMemSize -le "2.1")) 
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 4096 4096"
        Write-Host "Set page file for 2 gb of memory"
    }
    #4gb
    If (($TotalMemSize -gt "2") -and ($TotalMemSize -le "4.1")) 
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 8194 8194"
        Write-Host "Set page file for 4 gb of memory"
    }
    #6gb
    If (($TotalMemSize -gt "4") -and ($TotalMemSize -le "6.1"))
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 12288 12288"
        Write-Host "Set page file for 6 gb of memory"
    }
    #8gb
    If (($TotalMemSize -gt "6") -and ($TotalMemSize -le "8.1"))
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 16384 16384"
        Write-Host "Set page file for 8 gb of memory"
    }
    #12
    If (($TotalMemSize -gt "8") -and ($TotalMemSize -le "12.1")) 
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 24576 24576"
        Write-Host "Set page file for 12 gb of memory"
    }
    #16
    If (($TotalMemSize -gt "12") -and ($TotalMemSize -le "16.1"))
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 32768 32768"
        Write-Host "Set page file for 16 gb of memory"
    }
    #24
    If (($TotalMemSize -gt "16") -and ($TotalMemSize -le "24.1"))
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 49152 49152"
        Write-Host "Set page file for 24 gb of memory"
    }
    #32
    If (($TotalMemSize -gt "24") -and ($TotalMemSize -le "32.1"))
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 65536 65536"
        Write-Host "Set page file for 32 gb of memory"
    }
    #64
    If (($TotalMemSize -gt "32") -and ($TotalMemSize -le "64.1"))
    {
        Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'PagingFiles' -Value "$Drive\pagefile.sys 131072 131072"
        Write-Host "Set page file for 32 gb of memory"
    }
}

function Enable-RDP 
{
    Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled "False"
    If (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections") 
    {
        Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value "0"
    }
    Else 
    {
        New-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value "0"
    }
}

Function Install-DC
{
    Write-Warning "User imput is needed for Domain Controller setup"
    #loads the ad feature
    Get-WindowsFeature AD-Doamin-Services
    Add-WindowsFeature "RSAT-AD-Tools"

    #installs the Ad servics and sets variabls for the domain
    Get-WindowsFeature AD-Domain-Services | Install-WindowsFeature
    Write-Host
    $Domain = Read-Host 'What will be the name of the domain?'
    $NetBIOS = Read-Host 'What will be the netbios name?(please type in all caps)'
    $Account = Read-Host 'What is the name of the local admin account?'
    Write-Host
    net user $Account /passwordreq:yes
    net user $Account /expires:never
    
    Import-Module ADDSDeployment
    Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "Win2012" `
    -DomainName "$Domain" `
    -DomainNetbiosName "$NetBIOS" `
    -ForestMode "Win2012" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$true `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true
}

function Join-Domain
{
    IF (!($Domain)) {$domain = Read-Host "Domain"}
    IF (!($Account)) {$account = Read-Host "Account"}
    $password = Read-Host "Password for $Account" -AsSecureString
    Write-host "Joining $Domain as $Account"
    $username = "$domain\$account" 
    $credential = New-Object System.Management.Automation.PSCredential($username,$password)
    Add-Computer -DomainName $domain -Credential $credential
    $password = $null
    $credential = $null    
}

Function Set-Time
{
    Set-TimeZone -Name "$SetTimeZone"
}

Function Set-PowerConfig
{
    powercfg.exe -X disk-timeout-ac 0
    powercfg.exe -X disk-timeout-dc 0
    powercfg.exe -x -standby-timeout-ac 0
    powercfg.exe -x -standby-timeout-dc 0
}

Function Disable-ConnectToInternetUpdates
{
    Write-Host 'Disabling Consumer Experience'
    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $Name = "DoNotConnectToWindowsUpdateInternetLocations"
    $Value = "1"
    $Type = "DWORD"

    Set-Location HKLM:
    New-ItemProperty -Path $RegPath -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Set-Location $PSScriptRoot
}

#Checks to see what switches are being used 
If (($StartMenuLayout) -and ($ExportStartMenuLayout))
{
    $ErrorText =  "You can not use ExportStartMenuLayout parameter and StartMenuLayout parameter at the sametime"
    Read-Error
}

If ($Preset -EQ "CleanOS")
{
    IF (!($StartMenuLayout)) {Import-StartMenuLayout -PreSetLayout Blank}
    Set-PageFile
    Disable-Ads
    Disable-WindowsStore
    Disable-ConsumerExperience
    Disable-WindowsTips
    Disable-Cortana
    Disable-XboxServices
    Disable-OneDrive
    Remove-Apps
}

IF ($Preset -EQ "EveryDayUser")
{
    IF (!($StartMenuLayout)) {Import-StartMenuLayout -PreSetLayout EveryDayUser}
    Disable-Ads
    Remove-Apps 
    Set-PageFile
}

IF ($Preset -EQ "DomainComputerSetup")
{
    Join-Domain
    Set-PageFile
    Disable-Ads
    Disable-ConsumerExperience
    Disable-WindowsTips
    Disable-XboxServices
    Remove-Apps
}

#Exports the current start menu config 
If ($ExportStartMenuLayout){ Export-StartMenuLayout}

#If a config file is specifed will import it 
IF ($StartMenuLayout) {Import-StartMenuLayout}

#Enable RDP 
IF ($EnableRDP) {Enable-RDP}

IF ($SetTimeZone) {Set-Time}

#Disbales Xbox Services and stops them
If ($DisableXboxServices) {Disable-XboxServices}

#Add regkeys to disable OneDrive
If ($DisableOneDrive) {Disable-OneDrive}

#adds regkey needed to disable Cortana
If ($DisableCortana) {Disable-Cortana}

#Disables the windows store, The app is still listed
If ($DisableWindowsStore) {Disable-WindowsStore}

#Disables add on the start menu and lock screen
If ($DisableAds) {Disable-Ads}

#Disables Hibernate
If ($DisableHibernate) {Disable-Hibernate}

#Disables Windows Tips
If ($DisableWindowsTips) {Disable-WindowsTips}

#Disables Consumer Experience
If ($DisableConsumerExperience) {Disable-ConsumerExperience}

#Disable Connect to Windows Update Internet Location
IF ($DisableConnectToInternetUpdates) {Disable-ConnectToInternetUpdates}

#If a list file is specifyed will run the uninstall process
IF ($RemoveApps) {Remove-Apps}

#renames the computer
If ($RenameComputer) {Rename-Computer -NewName $RenameComputer}

#joins the computer to a domain
If ($JoinDomain) {Join-Domain}

#Sets the page file
If ($SetPageFile) {Set-PageFile}

#Sets power config
IF ($SetPowerConfig) {Set-PowerConfig}

IF ($InstallDC) {Install-DC}

#Reboots the computer
If ($Reboot)
{
    Restart-Computer -ComputerName $env:COMPUTERNAME
}
else 
{
    Write-Host "You will need to reboot the computer before you see the change take affect"
    Exit 0 
}