<#
.SYNOPSIS
Installs roles and features for SCCM servers

.DESCRIPTION
The scrip will install all required features for a SCCM site server and other server roles  

.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd

.LINK
http://www.sccmtst.com/
#>

PARAM(
    [Parameter(Mandatory=$True,HelpMessage="Enter Location of .net 3.5 install files")]
    [string]$DotNetSource
)

Get-Module servermanager

Write-Host "Installing Web-Windows-Auth"
Install-WindowsFeature Web-Windows-Auth
Write-Host "Installing Web-ISAPI-Ext"
Install-WindowsFeature Web-ISAPI-Ext
Write-Host "Installing Web-Metabase"
Install-WindowsFeature Web-Metabase
Write-Host "Installing Web-WMI"
Install-WindowsFeature Web-WMI
Write-Host "Installing BITS"
Install-WindowsFeature BITS
Write-Host "Installing RDC"
Install-WindowsFeature RDC
Write-Host "Installing NET-Framework-Features"
Install-WindowsFeature NET-Framework-Features -source $DotNetSource
Write-Host "Installing Web-Asp-Net"
Install-WindowsFeature Web-Asp-Net
Write-Host "Installing Web-Asp-Net45"
Install-WindowsFeature Web-Asp-Net45
Write-Host "Installing NET-HTTP-Activation"
Install-WindowsFeature NET-HTTP-Activation
Write-Host "Installing NET-Non-HTTP-Activ"
Install-WindowsFeature NET-Non-HTTP-Activ

$reboot = Read-Host "A reboot is recomended, Would you like to reboot now ? (Y,N)"
if ($reboot -eq "Y") {restart-computer}