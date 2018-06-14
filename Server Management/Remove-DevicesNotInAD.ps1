<#
.SYNOPSIS
Looks at devices that are either Inactive or do not have a client and verifies they are in AD

.DESCRIPTION
Looks at devices that are either Inactive or do not have a client and verifies they are in AD

.PARAMETER SiteCode
Site Code of your SCCM enviroment

.PARAMETER SiteServer
Your site server

.PARAMETER LoadLocal
will load the powershell module locally 

.PARAMETER Log
log of the devices it is looking at

.PARAMETER RemoveDevice
if used will remove the device from SCCM if it is not in AD

.EXAMPLE 

.EXAMPLE 

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
    [Parameter(Mandatory=$true)]
    [String]$SiteCode,
    [Parameter(Mandatory=$true)]
    [String]$SiteServer,
    [string]$Collection = "All Desktops without Clients/Inactive",
    [switch]$LoadLocal,
    [string]$Log = "$PSScriptRoot\Results.csv",
    [switch]$RemoveDevice
)

# Importing modules
Import-Module ActiveDirectory
if ($LoadLocal -eq "$True") 
{
    Set-Location 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\'
    Import-Module .\ConfigurationManager.psd1 -verbose:$false   
}
else 
{
    Import-Module \\$SiteServer\SMS_$SiteCode\AdminConsole\bin\ConfigurationManager.psd1 -verbose:$false
}

#Connection the the server
$site = $SiteCode + ":"
Set-Location $site

Add-Content $Log "Device Name, User Name, Is Active, Client, Last DDR, Last Hardware Scan, Last Software Scan, Last Policy Request, In AD"
$DeviceList = Get-CMDevice -CollectionName $Collection

foreach ($item in $DeviceList) {
    $Name = $item.Name 
    $UserName = $item.UserName
    $Active = $item.IsActive
    $Client = $item.IsClient
    $DDR = $item.LastDDR
    $Hardware = $item.LastHardwareScan
    $Software = $item.LastSoftwareScan
    $Policy = $item.LastPolicyRequest
    try {
        Get-ADComputer -Identity $item.Name | Out-Null
        Add-Content -Path $Log "$Name,$UserName,$Active,$Client,$DDR,$Hardware,$Software,$Policy,True"
    }
    catch {
        Add-Content -Path $Log "$Name,$UserName,$Active,$Client,$DDR,$Hardware,$Software,$Policy,False"
        If ($RemoveDevice) {Remove-CMDevice -Name $item.Name -Force}
        Write-Host ""
    }
}
Set-Location $PSScriptRoot