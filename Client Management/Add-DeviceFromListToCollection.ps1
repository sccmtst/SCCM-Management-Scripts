<#
.SYNOPSIS
Adds a list of devices to a SCCM Collection
.DESCRIPTION
Adds a list of devices to a SCCM Collection

.PARAMETER Collection
The collection you want the devices added to

.PARAMETER ComputerList
List of devices you want added to the collection

.PARAMETER SiteServer
Your site server

.PARAMETER SiteCode
The site code of your enviroment

.PARAMETER LoadLocal
Loads the PowerShell module locally instead of from teh server 

.EXAMPLE 
.\Add-DeviceFromListToCollection -Collection Devices -ComputerList C:\Computers.txt -SiteServer IT-SCCM -SiteCode SM1

.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 1.0.0.0

.LINK
You can get updates to this script and others from here
http://www.sccmtst.com/
#>

param(
    [Parameter(Mandatory=$True)]
    [string]$Collection,
    [Parameter(Mandatory=$True)]
    [string]$ComputerList,
    [Parameter(Mandatory=$True)]
    [string]$SiteServer,
    [Parameter(Mandatory=$True)]
    [string]$SiteCode,
    [switch]$LoadLocal
)

#Gets computer names from file
$Computers = Get-Content $ComputerList

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

#sets the site variable to be used for the Set-Location command
$site = $SiteCode + ":"
Set-Location $site

#Gets the collection ID be be used for the refresh
$CollectionID = (Get-CMDeviceCollection -Name $Collection).CollectionID
#For each computer in in the computer list 
foreach ($Computer in $Computers)
{
    #pauses the script for 5 seconds
    start-sleep -Seconds 5
    #gets the Resource ID of the device to be added
    $PCID = (get-cmdevice -Name $Computer).ResourceID
    #Checks to see if the device is already a member of a collection 
    if (Get-CMCollectionMember -CollectionName "$Collection" -ResourceID $PCID) 
    {
          Write-Warning "$Computer is already in $Collection"                       
    }
    else 
    {
        #Adds the device 
        Add-CMDeviceCollectionDirectMembershipRule -CollectionName "$Collection" -ResourceID $PCID
        #Updates the collection membership 
        Invoke-WmiMethod -Path "ROOT\SMS\Site_$($SiteCode):SMS_Collection.CollectionId='$CollectionId'" -Name RequestRefresh -ComputerName $SiteServer
        #pauses the script
        start-sleep -Seconds 5
        #checks to see if the device was added correctly
        if (Get-CMCollectionMember -CollectionName "$Collection" -ResourceID $PCID)
        {
            Write-Host "SUCCESS: $Computer was added to $Collection"
        }
        else 
        {
            Write-Error "ERROR: $Computer was not added to $Collection"
        }
    }
}
