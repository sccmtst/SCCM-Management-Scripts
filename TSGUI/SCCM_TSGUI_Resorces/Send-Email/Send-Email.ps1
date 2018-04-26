<#
.SYNOPSIS
Send a Email

.DESCRIPTION
Sends a email and allowes you to specify a diffrent device to sned from

.PARAMETER To
Address to send the email to

.PARAMETER From 
Address the email will come from

.PARAMETER SMTPServer
Email server

.PARAMETER Subject
Subject of the email

.PARAMETER Body
Body of the email

.PARAMETER ComputerToSendFrom
Computer that will conenct to the SMTP server. 
This can be handy when only specific device are allowed to connect to the SMTP server anonymously
PowerShell removing will need to be enabled on the target computer to use this.  


.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 1.0.0.0

.LINK
You can get updates to this script and others from here
http://www.sccmtst.com/
#>


Param
(
    [Parameter(Mandatory=$true)]
    [string]$To,
    [Parameter(Mandatory=$true)]
    [string]$From = "Notice@sccmtst.com",
    [Parameter(Mandatory=$true)]
    [string]$SMTPServer = "",
    [string]$Subject = "$ENV:COMPUTERNAME has completed",
    [string]$Body = "$ENV:COMPUTERNAME has completed the imaging process",
    [string]$ComputerToSendFrom
)


IF ($ComputerToSendFrom)
{
    $ScriptBlockContent = {
        Param(
            $To,
            $From,
            $SMTPServer,
            $Subject,
            $Body
        )
    
        Send-MailMessage -To "$To" -From "$From" -Subject "$Subject" -BodyAsHtml $Body -SmtpServer "$SMTPServer"
    }
    
    Invoke-Command -ComputerName $ComputerToSendFrom -Scriptblock $ScriptBlockContent -ArgumentList $To, $From, $SMTPServer, $Subject, $Body
}

IF (!($ComputerToSendFrom))
{
    Send-MailMessage -To "$To" -From "$From" -Subject "$Subject" -BodyAsHtml $Body -SmtpServer "$SMTPServer"
}
