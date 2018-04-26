<#
.SYNOPSIS
Creates a SCCM Device Collections

.DESCRIPTION
Creates SCCM Device Collections from a single Collection name, a list of names in a text file or from a group of Active Directory OUs

.PARAMETER CollectionName
If createding only a single Collection use this parameter to specify the name of the Collection

.PARAMETER CollectionsFile
Use this parameter to specify a list of Collection names to create, must be full file path

.PARAMETER LimitingCollection
The Collection you want to limmit the collection members from

.PARAMETER LoadLocal
When used will load the Powershell Module from the local system rather then the Site Server

.PARAMETER SiteServer
Sets the SCCM Site Server

.PARAMETER SiteCode
Sets the SCCM Site Code

.PARAMETER ColletionsByOUs
Create Collctions based on Active Directory organizationl Units members
use the ou destinquised name 
you must have remote server adminsitration tools installed for this parameter to work

.PARAMETER ScheduleType
Weeks - Sets the Collection to update every x weeks on a spesific days of the week
Days - Sets the Collection to update every x days
Hours - Sets the Collection to update every x Hours
Minutes - Sets the Collection to update every x Minutes
Continuous - Sets the Collection to update Incrementally

.PARAMETER AddCollections
Allows you to add a member collection to the collections you are created

.EXAMPLE
Create-Collection.ps1 -SiteServer SCCM-1 -SiteCode MSN -CollctionName "Testing Collection" -LimmitingCollection "All Desktops" -ScheduleType "Hours"
Creates a Collection Named Testing Collection with a limmiting Collection of All Desktops that will refresh hourly. 

.EXAMPLE
Create-Collection.ps1 -CollectionsByOUs "OU=Europe,CN=Users,DC=corp,DC=contoso,DC=com"
Create a Collection for each OU in the Europe OU

.Example 
Create-Collelctions.ps1 -CollectionsFile List.txt -ScheduleType "Hours" -AddCollections "Install*"
Each collection listed in List.txt will be created with a refesh schedule for hours and will have all Collections that start with Install added to them

.NOTES
Created By: Kris Gross
Email: KrisGross@sccmtst.com
Twitter: @kmgamd
Version: 2.0.0.0

.LINK
http://sccmtst.com
#>

Param(  
        #Create Collection From Settings
        $CollectionName,
        $CollectionsFile,
        $CollectionsByOUs,
        #SCCM Moduel Settings
        [switch]$LoadLocal,
        [Parameter(Mandatory=$True)]
        $SiteServer,
        [Parameter(Mandatory=$True)]
        $SiteCode,        
        [Parameter(Mandatory=$True)]
        $LimitingCollection,
        [Parameter(Mandatory=$True)]    
        [ValidateSet('Weeks','Days','Hours','Minutes','Continuous')]
        [string]$ScheduleType,
        [string]$AddCollections
        )

#checks if the script should load the local PowerShell Module
if ($LoadLocal -eq "$True") 
{
    Set-Location 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\'
    Import-Module .\ConfigurationManager.psd1 -verbose:$false   
}
else 
{
    Import-Module \\$SiteServer\SMS_$SiteCode\AdminConsole\bin\ConfigurationManager.psd1 -verbose:$false
}

#Sets the loacation to the SCCM Site so the script can run
$site = $SiteCode + ":"
Set-Location $site

#Sets the Schedule based on the ScheduleType parameter
If ($Scheduletype -eq "Hours") 
{   
    $Hours = Read-Host "How many hours between refresh"
    $Schedule = New-CMSchedule -RecurInterval Hours -RecurCount $Hours
}

If ($Scheduletype -eq "Days") 
{   
    $Days = Read-Host "How many days between refresh"
    $Schedule = New-CMSchedule -RecurInterval Days -RecurCount $Days
}

If ($Scheduletype -eq "Weeks") 
{   
    $DayOfWeek = Read-Host "Day of the week for reshresh"
    $WeeksBetween = Read-Host "Number of weeks between refresh"
    $Schedule = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek $DayOfWeek -RecurCount $WeeksBetween
}

If ($Scheduletype -eq "Minutes") 
{   
    $Minutes = Read-Host "How many minutes between refresh"
    $Schedule = New-CMSchedule -RecurInterval Minutes -RecurCount $Minutes
}

#Create a Collection based on a list in a file
If ($CollectionsFile)
{
    $CollectionsFromFile = Get-Content "$CollectionsFile"
    If ($ScheduleType -eq "Continuous")
    {
        If($AddCollections){$CollectionFilter = (Get-CMDeviceCollection | Where-Object Name -Like "$AddCollections").name}
        Foreach ($Collection in ($CollectionsFromFile))
        {
            New-CmDeviceCollection -Name "$Collection" -LimitingCollectionName "$LimitingCollection" -RefreshType Continuous -ErrorAction SilentlyContinue | Out-Null
            If($AddCollections)
            {
                ForEach ($CollectionToAdd in ($CollectionFilter))
                {
                    Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$Collection" -IncludeCollectionName "$CollectionToAdd" -ErrorAction SilentlyContinue | Out-Null
                }
            }
            If (!(Get-CMCollection -name "$Collection"))
            {
                Write-Error "$Collection Not Created" 
            }
            IF (Get-CMCollection -name "$Collection")
            {
                write-Host "$Collection Created"
            }
        }
    }
    else 
    {
        If($AddCollections){$CollectionFilter = (Get-CMDeviceCollection | Where-Object Name -Like "$AddCollections").name}
        Foreach ($Collection in ($CollectionsFromFile))
        {
            New-CmDeviceCollection -Name "$Collection" -LimitingCollectionName "$LimitingCollection" -RefreshSchedule $Schedule -ErrorAction SilentlyContinue | Out-Null
            If($AddCollections)
            {
                ForEach ($CollectionToAdd in ($CollectionFilter))
                {
                    Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$Collection" -IncludeCollectionName "$CollectionToAdd" -ErrorAction SilentlyContinue | Out-Null
                }
            }
            If (!(Get-CMCollection -name "$Collection"))
            {
                Write-Error "$Collection Not Created" 
            }
            IF (Get-CMCollection -name "$Collection")
            {
                write-Host "$Collection Created"
            }
        }
    }
}

#If only a name is specified will only create a single collection
IF ($CollectionName)
{
    If ($ScheduleType -eq "Continuous") 
    {
        If($AddCollections){$CollectionFilter = (Get-CMDeviceCollection | Where-Object Name -Like "$AddCollections").name}
        New-CmDeviceCollection -Name "$CollectionName" -LimitingCollectionName "$LimitingCollection" -RefreshType Continuous -ErrorAction SilentlyContinue | Out-Null
        If($AddCollections)
        {
            ForEach ($CollectionToAdd in ($CollectionFilter))
            {
                Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$CollectionName" -IncludeCollectionName "$CollectionToAdd" -ErrorAction SilentlyContinue | Out-Null
            }
        }
        If (!(Get-CMCollection -name "$CollectionName"))
        {
            Write-Error "$CollectionName Not Created" 
        }
        IF (Get-CMCollection -name "$CollectionName")
        {
            write-Host "$CollectionName Created"
        }
    }       
    else 
    {
        If($AddCollections){$CollectionFilter = (Get-CMDeviceCollection | Where-Object Name -Like "$AddCollections").name}
        New-CmDeviceCollection -Name "$CollectionName" -LimitingCollectionName "$LimitingCollection" -RefreshSchedule $Schedule -ErrorAction SilentlyContinue | Out-Null
        If($AddCollections)
        {
            ForEach ($CollectionToAdd in ($CollectionFilter))
            {
                Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$CollectionName" -IncludeCollectionName "$CollectionToAdd" -ErrorAction SilentlyContinue | Out-Null
            }
        }
        If (!(Get-CMCollection -name "$CollectionName"))
        {
            Write-Error "$CollectionName Not Created" 
        }
        IF (Get-CMCollection -name "$CollectionName")
        {
            write-Host "$CollectionName Created"
        }
    }
}

#Creates the Collections based on AD OU members
If ($CollectionsByOUs)
{
    #gets the OUs in a OU
    $OUs = (Get-ADOrganizationalUnit -Filter * -SearchBase $CollectionsByOUs -SearchScope subtree).Name
    If ($ScheduleType -eq "Continuous")
    {
        If($AddCollections){$CollectionFilter = (Get-CMDeviceCollection | Where-Object Name -Like "$AddCollections").name}
        Foreach ($OU in $OUS)
        {
            New-CmDeviceCollection -Name "$OU" -LimitingCollectionName "$LimitingCollection" -RefreshType Continuous -ErrorAction SilentlyContinue | Out-Null
            If($AddCollections)
            {
                ForEach ($CollectionToAdd in ($CollectionFilter))
                {
                    Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$OU" -IncludeCollectionName "$CollectionToAdd" -ErrorAction SilentlyContinue | Out-Null
                }
            }
            If (!(Get-CMCollection -name "$OU"))
            {
                Write-Error "$OU Not Created" 
            }
            IF (Get-CMCollection -name "$OU")
            {
                write-Host "$OU Created"
            }
        }
    }
    Else
    {
        If($AddCollections){$CollectionFilter = (Get-CMDeviceCollection | Where-Object Name -Like "$AddCollections").name}
        Foreach ($OU in $OUS)
        {
            New-CmDeviceCollection -Name "$OU" -LimitingCollectionName "$LimitingCollection" -RefreshSchedule $Schedule -ErrorAction SilentlyContinue | Out-Null
            If($AddCollections)
            {
                ForEach ($CollectionToAdd in ($CollectionFilter))
                {
                    Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$OU" -IncludeCollectionName "$CollectionToAdd" -ErrorAction SilentlyContinue | Out-Null
                }
            }
            If (!(Get-CMCollection -name "$OU"))
            {
                Write-Error "$OU Not Created" 
            }
            IF (Get-CMCollection -name "$OU")
            {
                write-Host "$OU Created"
            }
        }
    }
}

#Changes the location back to where the script was ran from
Set-Location $PSScriptRoot