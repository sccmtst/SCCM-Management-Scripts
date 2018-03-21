<#
.SYNOPSIS
Send Component status to an email 

.DESCRIPTION
the script will gather the component status of your site and send it as an email color cordination errors warnings and ok status.
For best use create a sceduled task on the server to run this script

.PARAMETER SiteCode
Site code of your SCCM enviroment uses to connect to the server

.PARAMETER SiteServer
The name of your site server used to load the powershell modules needed

.PARAMETER LoadLocal
Loads the locally installed PowerShell modules instead of the modules on the Site Server

.PARAMETER To
The to address for the email 

.PARAMETER From
the From address to the email

.PARAMETER Subject
The subject of the email

.PARAMETER SMTPServer
The smtp serve that will be used to send the email

.EXAMPLE 
.\Get-CMComponentSttus.ps1 -SiteCode SM1 -SiteServer Server-CM.Contoso.com -To SCCMAdmins@Contoso.com -From SCCMAlerts@Contoso.com -Subject "SCCM Component Status" -SMTPServer Server-Email.Contoso.com

.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 1.0.0.0

.LINK
You can get updates to this script and others from here
http://www.sccmtst.com/
#>

Param(
    [Parameter(Mandatory=$true)]
    [string]$SiteCode,
    [Parameter(Mandatory=$true)]
    [string]$SiteServer,
    [switch]$LoadLocal,
    [Parameter(Mandatory=$true)]
    [string]$To,
    [Parameter(Mandatory=$true)]
    [string]$From,
    [Parameter(Mandatory=$true)]
    [string]$Subject,
    [Parameter(Mandatory=$true)]
    [string]$SMTPServer
)


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


$ComponentStatus = Get-CMSiteComponent | Select-Object -Unique ComponentName | Foreach-Object {
    $Component = $_
    $Messages = Get-CMComponentStatusMessage -Severity Error -StartTime (Get-Date 00:00) -ComponentName $Component.ComponentName
    $NumMessages = ($Messages | Group-Object -Property RecordID).Count
    New-Object PSCustomObject -Property @{"Name"=$Component.ComponentName;"Status"=$(If ($NumMessages -gt 5) { "Error" } ElseIf ($NumMessages -gt 1) { "Warning" } Else { "OK" });"NumMessages"=$NumMessages;}
    } | Select-Object Name,Status,NumMessages

$Body = "<h3>CT1 ConfigMgr Component Status</h3><table><tr><td style='padding: 2px 10px'>Component Name</td><td style='padding: 2px 10px'># Error Messages</td></tr>"
$ComponentStatus | Foreach-Object {
    $StatusColor = $(Switch ($_.Status) { "Error" { "red" } ; "Warning" { "orange" } ; "OK" { "green" } })
    $Body = "$($Body)<tr><td style='padding: 2px 10px;color:$($StatusColor)'>$($_.Name)</td><td style='padding: 2px 10px;color:$($StatusColor)'>$($_.NumMessages)</td></tr>"
    }
$Body = "$($Body)</table>"

Send-MailMessage -To "$To" -From "$From" -Subject "$Subject" -BodyAsHtml $Body -SmtpServer "$SMTPServer"