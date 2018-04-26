<#
.SYNOPSIS
Create SCCM Collections based on AD OUs
.DESCRIPTION
The Script creates collections to mimic your AD OU structure 
.PARAMETER SiteCode
The Site Code of your enviroment

.PARAMETER SiteServer
Name of your site server

.PARAMETER LoadLocal 
If specified will load the SCCM PowerShell Module from the local install locaton otherwise 
The Module will be loaded from the Site Server.

.EXAMPLE 
.\Create-SCCMCollections-ADOUs.ps1 -SiteCode SC1 -SiteServer IT-SCCMServer -LoadLocal

.EXAMPLE 
.\Create-SCCMCollections-ADOUs.ps1 -SiteCode SC1 -SiteServer IT-SCCMServer

.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 1.0.0.0

.LINK
Original script can be found here 
https://www.windows-noob.com/forums/topic/15173-the-script-to-create-device-collections-based-on-ad-ous/

You can get updates to this script and others from here
http://www.sccmtst.com/
#>

PARAM(
    [Parameter(Mandatory=$True)]
    [String]$SiteCode,
    [Parameter(Mandatory=$True)]
    [String]$SiteServer,
    [switch]$LoadLocal
)
$site = $SiteCode + ":"
$TargetFolder = "$site\DeviceCollection\AD_OUs"

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
Set-Location $site

#Checking that the Target folder exists if not will create it 
IF (!(Test-Path $TargetFolder)) {New-Item $TargetFolder -ItemType Directory}

# Defining refresh interval for collection. I've selected 2 hours.
$Refr = New-CMSchedule -RecurCount 2 -RecurInterval Hourse -Start "01/01/2017 0:00"

<# Getting Canonical name and GUID from AD OUs. 
-SearchScope is Subtree by default, you can use it or use "Base" or "OneLevel".
OUs are listed from the root of AD. To change this i.e. to OU SomeFolder use -SearchBase "OU=SomeFolder,DC=maestro,DC=local"
#>
$ADOUs = Get-ADOrganizationalUnit -Filter * -Properties Canonicalname | Select-Object CanonicalName, ObjectGUID

foreach ($OU in $ADOUs)
{
    $O_Name = $OU.CanonicalName
    $O_GUID = $OU.ObjectGUID

    try {
        Write-Host "Creating Collection for $O_Name"
        # Creating the Collection
        New-CMDeviceCollection -LimitingCollectionName 'All Systems' -Name $O_Name -RefreshSchedule $Refr -Comment $O_GUID
        # Creating Query Membership rule for collection
        Add-CMDeviceCollectionQueryMembershipRule -CollectionName $O_Name -QueryExpression "select *  from  SMS_R_System where SMS_R_System.SystemOUName = '$O_Name'" -RuleName "OU Membership"
        # Getting collection ID
        $ColID = (Get-CMDeviceCollection -Name $O_Name).collectionid
        # Moving collection to folder
        Move-CMObject -FolderPath $TargetFolder -ObjectId "$ColID"
        # Updating collection membership at once
        Invoke-CMDeviceCollectionUpdate -Name $O_Name
    }
    catch {
        Write-Error "$_"
    }

}
Write-Host ""
Write-Host "Complete"