<#
.SYNOPSIS
Remove device from SCCM

.DESCRIPTION
Remove a single device or a list of devices from SCCM

.PARAMETER DeviceList
Path to the list of device you want to remove 
Cannot be use with the $DeviceToRemove parameter

.PARAMETER DeviceToRemove
Name of a sinlge device you want remove
Cannot be used with the $DeviceList parameter

.PARAMETER SiteCode
Site code of your SCCM enviroment uses to connect to the server

.PARAMETER SiteServer
The name of your site server used to load the powershell modules needed

.PARAMETER LoadLocal
Loads the locally installed PowerShell modules instead of the modules on the Site Server

.EXAMPLE 
.\Remove-Devices.ps1 -DeviceList C:\Devices.txt -SiteCode SM1 -SiteServer Server-CM

.EXAMPLE 
.\Remove-Devices.ps1 -DeviceToRemove JohnPC -SiteCode SM1 -SiteServer Server-CM

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
    $DeviceList,
    $DeviceToRemove,
    [Parameter(Mandatory=$true)]
    [string]$SiteCode,
    [Parameter(Mandatory=$true)]
    [string]$SiteServer,
    [switch]$LoadLocal
)

IF (($DeviceList) -and ($DeviceToRemove) {
    Write-Error "You cant use DeviceList and DeviceToRemove togeather"
    Exit
}

IF ($DeviceList)
{
    $DTR = Get-Content $DeviceList
}
Else 
{
    $DTR = $DeviceToRemove
}

#Imports the module for your site server so you dont need to have the sccm console installed to use it
if ($LoadLocal -eq "$True") 
{
    Set-Location 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\'
    Import-Module .\ConfigurationManager.psd1 -verbose:$false   
}
else 
{
    Import-Module \\$SiteServer\SMS_$SiteCode\AdminConsole\bin\ConfigurationManager.psd1 -verbose:$false
}
Set-Location $SiteCode


Foreach ($Item in $DTR)
{
    IF (Get-CMDevice -Name $Item)
    {
        Write-Host "removing $Item"
        Remove-CMDevice -Name $Item -Force
    }
    Else
    {
        Write-Host "Cound not find $Item"        
    } 
}

Set-Location $PSScriptRoot

