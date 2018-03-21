<#
.SYNOPSIS
Gets the updates in a update group

.DESCRIPTION
Pulls the info about the updates that are in an update group and exports the info to a CSV file for reporting

.PARAMETER SiteCode
Site code of your SCCM enviroment uses to connect to the server

.PARAMETER SiteServer
The name of your site server used to load the powershell modules needed

.PARAMETER LoadLocal
Loads the locally installed PowerShell modules instead of the modules on the Site Server

.PARAMETER GroupName
Name of the update group you want the members of 

.EXAMPLE 
.\get-UpdateGroupMembers.ps1 -SiteCode SM1 -SiteServer Server-SCCM -LoadLoacl -GroupName "Windows 7 Updates"

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
    [string]$SiteCode,
    [Parameter(Mandatory=$true)]
    [string]$SiteServer,
    [switch]$LoadLocal,
    [Parameter(Mandatory=$true)]
    [string]$GroupName
)

if ($LoadLocal -eq "True") 
{
    Set-Location 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\'
    Import-Module .\ConfigurationManager.psd1 -verbose:$false   
}
else 
{
    Import-Module \\$SiteServer\SMS_$SiteCode\AdminConsole\bin\ConfigurationManager.psd1 -verbose:$false
}

#sets the site variable to be used for the Set-Location command
$site = $SiteCode + ":"
Set-Location $site

$U1 = (Get-CMSoftwareUpdateGroup -Name "$GroupName").Updates
$UpdatesFile = "$GroupName-UpdatesList.csv"
Add-Content $PSScriptroot\$UpdatesFile "Artical ID, Name, Description, Type, Info"


Foreach ($Item in $U1)
{
    $ArticalID = (Get-CMSoftwareUpdate -Id $Item -Fast).ArticleID
    $Name = (Get-CMSoftwareUpdate -Id $Item -Fast).LocalizedDisplayName
    $Description = (Get-CMSoftwareUpdate -Id $Item -Fast).LocalizedDescription
    $Description = $Description -replace "`n|`r",""
    $Description = $Description.replace(',','')
    $Type = (Get-CMSoftwareUpdate -Id $Item -Fast).SeverityName
    $Info = (Get-CMSoftwareUpdate -ID $Item -Fast).LocalizedInformativeURL
    $Info = $Info -replace "`n|`r",""
    $Info = $Info.replace(',','')
    Add-Content $PSScriptroot\$UpdatesFile "$ArticalID,$Name,$Description,$Type,$Info"
}

Set-Location $PSScriptroot