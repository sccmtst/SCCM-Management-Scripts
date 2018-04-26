<#
.SYNOPSIS
SCCM client health check and repair

.DESCRIPTION
This script will check components used by the SCCM client 
and if an issue is found it will attempt to fix the issue.

1. Looks to see if the the client is installed, if not it 
will install the client from the specified location.

2. Next the script will check the startup type and status 
of services needed for SCCM

3. Runs specific client actions to verify they are working

4. Checks to see if basic WMI queries are working and that 
the SCCM name space is working. 

5. If an issue is found that can be resolved by reinstalling 
the SCCM client this will happen last. The scrip will also 
look for any reaming client files and remove them to be sure 
there are no corrupted files left behind. 


.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 1.0.1.1

.LINK
You can get updates to this script and others from here
http://www.sccmtst.com/
#>

### Variables that can be changed ###
# Location of the SCCM Client install files
$SCCMClientLocation = ""
# Log file the script writes to
$LogFile = "$ENV:windir\SCCMClientHealthCheck.log"
# Allows the log file to age for specified amount of days
$LogAge = "31"
#################################################

### Not recomended to change these variables ###
$CCMPath = "$ENV:windir\CCM"
$ScriptName = $MyInvocation.MyCommand.Name
$Computername = $ENV:COMPUTERNAME
################################################

# Clears log if its larger then 1MB or older then the specified amount of days # 
function Get-LogFileSize
{
	$LogFileSize = (Get-Item -path $LogFile).Length
	$LogFileAge = (Get-Item -Path $LogFile).CreationTime
	$AcceptableDate = (Get-Date).AddDays(-"$LogAge")
	If (($LogFileSize -ge 999999) -or ($LogFileAge -le $AcceptableDate)) 
	{
		Remove-Item $LogFile -Force
		$Global:LogCleaned = "True"
	}
}

# Creates a new log file for the script #
function New-LogFile
{
    $LogFilePaths =  "$LogFile"
    Foreach ($LogFilePath in $LogFilePaths) 
    {
        $script:NewLogError = $null
        $script:ConfigMgrLogFile = $LogFilePath
		Add-LogEntry "********************************************************************************************************************" "1"
		Add-LogEntry "Starting SCCM Client Health Check" "1"
		If ($Global:LogCleaned -EQ "True") {Add-LogEntry "Log was cleaned due to being too large or older then $LogAge Days"}
        If (-Not($script:NewLogError)) { break }
    }
    If ($script:NewLogError) 
    {
        $script:Returncode = 1
        Exit $script:Returncode
    }
}

# Logs the status of the script in a CMtrace format #
function Add-LogEntry ($LogMessage, $Messagetype) 
{
    # Date and time is set to the CMTrace standard
    # The Number after the log message in each function corisponts to the message type
    # 1 is info
    # 2 is a warning
    # 3 is a error
    Add-Content $script:ConfigMgrLogFile "<![LOG[$LogMessage]LOG]!><time=`"$((Get-Date -format HH:mm:ss)+".000+300")`" date=`"$(Get-Date -format MM-dd-yyyy)`" component=`"$ScriptName`" context=`"`" type=`"$Messagetype`" thread=`"`" file=`"powershell.exe`">"  -Errorvariable script:NewLogError
}

# Closes the log file and exits the script #
function Exit-Script() 
{
    Remove-Item env:SEE_MASK_NOZONECHECKS
    Add-LogEntry "Closing the log file for $ScriptName." "1"
    Add-LogEntry "********************************************************************************************************************" "1"
    Exit $script:Returncode    
}

# Check if SCCM Client is installed #
Function Get-ClientInstalled
{
	Add-LogEntry "---------------------------" "1"
	Add-LogEntry "Checking if SCCM Client is installed" "1"
	If ((Get-WmiObject win32_Product | Where-Object Name -EQ "Configuration Manager Client") -and (Get-Service -Name ccmexec -ErrorAction SilentlyContinue))
	{
		Add-LogEntry "SCCM Client is installed" "1"
	}
	Else
	{
		Add-LogEntry "WARNING: SCCM Clinet is not installed" "2"
		Add-LogEntry "SCCM Client will be installed after other checks have been completed" "1"
		$Global:InstallClient = "True"
	}
}

# Installs SCCM Client #
Function Install-SCCMClient
{
	Add-LogEntry "---------------------------" "1"
	IF ($Global:InstallClient -eq "True")
	{
		IF (Test-path -Path $CCMPath) 
		{
			Add-LogEntry "SCCM client install files found" "1"
			Add-LogEntry "Removing old client install files" "1"
			Remove-Item -Path C:\Windows\ccmsetup -Recurse -Force
			start-sleep -Seconds 10
			IF (Test-Path -Path C:\Windows\ccmsetup) {Add-LogEntry "WARNING: Could not remove ccmsetup folder" "2"}
			Add-LogEntry "Running SCCM Client uninstall" "1"
			$UninstallClient = @"
			@ECHO off
			ECHO Uninstalling the old client...Please Wait
			%1\ccmsetup.exe /Uninstall
			
			:start
			tasklist /FI "IMAGENAME eq ccmsetup.exe" | find /i "ccmsetup.exe" >> null
			 
			IF ERRORLEVEL 2 GOTO running
			IF ERRORLEVEL 1 GOTO end
			
			:running
			goto start
			
			:end
			ECHO uninstall Complete
			exit cmd.exe 
"@
			Add-Content $Env:TEMP\UninstallClient.bat $UninstallClient
			Invoke-Expression "$Env:TEMP\UninstallClient.bat $SCCMClientLocation"
			Remove-Item "$Env:TEMP\UninstallClient.bat"
			If (Get-WmiObject win32_Product | Where-Object Name -EQ "Configuration Manager Client")
			{
				Add-LogEntry "ERROR: Could not uninstall SCCM Client" "3"
			}
			If (!(Get-WmiObject win32_Product | Where-Object Name -EQ "Configuration Manager Client"))
			{
				Add-LogEntry "SCCM Client successfully uninstalled" "1"
			}
			Add-LogEntry "Remove leftover client files" 
			Start-Sleep -Seconds 60
			Remove-Item C:\Windows\ccmcache -Recurse -Force
			Start-Sleep -Seconds 10
			IF (Test-Path -Path C:\Windows\ccmcache) { Add-LogEntry "Could not remove ccmcache folder" "2"}
			Remove-Item $CCMPath -Recurse -Force
			Start-Sleep -Seconds 10
			IF (Test-Path -Path $CCMPath) { Add-LogEntry "Could not remove CCM folder" "2"}
		}

		Add-LogEntry "Running SCCM Client Install" "1"
		IF (!(Test-Path $SCCMClientLocation))
		{
			Add-LogEntry "ERROR: Cannont find $SCCMClientLocation" "3"
			Exit-Script
		}
		$InstallClientScript = @"
		@ECHO off
		ECHO Installing the new client...Please Wait
		%1\ccmsetup.exe SMSMP=it-cmmp.city.thornton.local DNSSUFFIX=city.thornton.local SMSSITECODE=CT1 CCMLOGLEVEL=0 CCMLOGMAXSIZE=16000000 CCMLOGMAXHISTORY=1 CCMDEBUGLOGGING=0 SMSCACHSIZE=25600
		
		:start
		tasklist /FI "IMAGENAME eq ccmsetup.exe" | find /i "ccmsetup.exe" >> null
		 
		IF ERRORLEVEL 2 GOTO running
		IF ERRORLEVEL 1 GOTO end
		
		:running
		goto start
		
		:end
		ECHO Install Complete
		exit cmd.exe
"@
		Add-Content $Env:TEMP\InstallClient.bat $InstallClientScript
		Invoke-Expression "$Env:TEMP\InstallClient.bat $SCCMClientLocation"
		Remove-Item "$Env:TEMP\InstallClient.bat"
		If (!(Get-WmiObject win32_Product | Where-Object Name -EQ "Configuration Manager Client"))
		{
			Add-LogEntry "ERROR: Could not install SCCM Client" "3"
		}
		If (Get-WmiObject win32_Product | Where-Object Name -EQ "Configuration Manager Client")
		{
			Add-LogEntry "SCCM Client successfully installed" "1"
			Add-LogEntry "Running Machine Policy Cycle"
			$SMSClient = [wmiclass] "\\$env:COMPUTERNAME\root\ccm:SMS_Client"
			$SMSClient.TriggerSchedule("{00000000-0000-0000-0000-000000000021}")
			$Global:InstallClient = "False"
		}
		If ($Global:CheckWMI -eq "True")
		{
			if(Get-WmiObject -Namespace root\ccm -Class sms_client) 
			{
				Add-LogEntry "SUCCESS: SCCM WMI was repaired" "1"
			}
			else 
			{
				Add-LogEntry "ERROR: SCCM WMI was not repaired" "3"
			}
		}
	}
}

# Check if dependent services are running and set them to correct startup type #
Function Get-DependentServices
{
	If ($Global:InstallClient -ne "True")
	{
		Add-LogEntry "---------------------------" "1"
		Add-LogEntry "Checking startup type of CcmExec service" "1"
		IF ((Get-Service "CcmExec").StartType -ne "Automatic")
		{
			Add-LogEntry "WARNING: CcmExec service needs to be set to Automatic" "2"
			Add-LogEntry "Attempting to change start type to Automatic" "1"
			Set-Service "CcmExec" -StartupType "Automatic"
			IF ((Get-Service "CcmExec").StartType -ne "Automatic")
			{
				Add-LogEntry "ERROR: Could not change start type" "3"
			}
			IF ((Get-Service "CcmExec").StartType -eq "Automatic")
			{
				Add-LogEntry "SUCCESS: CcmExec service start type was set to Automatic" "1"
			}
		}
		else 
		{
			Add-LogEntry "CcmExec service startup type is correct" "1"
		}
		Add-LogEntry "Checking status of Ccmexec service" "1"
		if((Get-Service -Name "ccmexec").Status -eq "Stopped")
		{
			Add-LogEntry "WARNING: CCMExec service stopped" "2"
			Add-LogEntry "Attempting to startng CCMExec service " "1"
			Start-Service -Name CcmExec
			start-Sleep -Seconds 10
			if((Get-Service -Name "ccmexec").Status -eq "Stopped")
			{
				Add-LogEntry "ERROR: Could not start CCMExec service" "3"
			}
			if((Get-Service -Name "ccmexec").Status -ne "Stopped")
			{
				Add-LogEntry "SUCCESS: started CcmExec service"
			}
		}
		Else 
		{
			Add-LogEntry "Ccmexec service is running" "1"
		}		
	}

	Add-LogEntry "---------------------------" "1"
	Add-LogEntry "Checking startup type of BITS service" "1"
	IF ((Get-Service "BITS").StartType -ne "Automatic")
	{
		Add-LogEntry "WARNING: BITS service needs to be set to Automatic" "2"
		Add-LogEntry "Attempting to change startup type to Automatic" "1"
		Set-Service "BITS" -StartupType "Automatic"
		IF ((Get-Service "BITS").StartType -ne "Automatic")
		{
			Add-LogEntry "ERROR: Could not change startup type" "3"
		}
		IF ((Get-Service "BITS").StartType -eq "Automatic")
		{
			Add-LogEntry "SUCCESS: BITS service startup type was set to Automatic"
		}
	}
	else 
	{
		Add-LogEntry "BITS service startup is set correctly" "1"
	}
		
	Add-LogEntry "Checking status of BITS service" "1"
	if((Get-Service -Name "BITS").status -eq "Stopped")
	{
		Add-LogEntry "WARNING: BITS service Stopped" "2"
		Add-LogEntry "Attempting to start BITS service" "1"
		Start-Service -Name "BITS"
		start-Sleep -Seconds 10
		if((Get-Service -Name "BITS").status -eq "Stopped")
		{
			Add-LogEntry "ERROR: Could not start BITS service" "3"
		}
		if((Get-Service -Name "BITS").status -ne "Stopped")
		{
			Add-LogEntry "SUCCESS: started BITS service" "1"
		}
	}
	else 
	{
		Add-LogEntry "BITS service is started" "1"
	}

	Add-LogEntry "---------------------------" "1"
	Add-LogEntry "Checking startup type of wuauserv service" "1"
	IF ((Get-Service "wuauserv").StartType -ne "Manual")
	{
		Add-LogEntry "WARNING: Wuauserv service needs to be set to Manual" "2"
		Add-LogEntry "Attempting to change start type to Manual" "1"
		Set-Service "wuauserv" -StartupType "Manual"
		IF ((Get-Service "wuauserv").StartType -ne "Manual")
		{
			Add-LogEntry "ERROR: Could not change start type" "3"
		}
		IF ((Get-Service "wuauserv").StartType -eq "Manual")
		{
			Add-LogEntry "SUCCESS: wuauserv service start type was set to Manual"
		}
	}
	else 
	{
		Add-LogEntry "Wuauserv service startup type is correct" "1"
	}

	Add-LogEntry "---------------------------" "1"
	Add-LogEntry "Checking startup type of Winmgmt service" "1"
	IF ((Get-Service "Winmgmt").StartType -ne "Automatic")
	{
		Add-LogEntry "WARNING: Winmgmt service needs to be set to Automatic" "2"
		Add-LogEntry "Attempting to change start type to Automatic" "1"
		Set-Service "Winmgmt" -StartupType "Automatic"
		IF ((Get-Service "Winmgmt").StartType -ne "Automatic")
		{
			Add-LogEntry "ERROR: Could not change start type" "3"
		}
		IF ((Get-Service "Winmgmt").StartType -eq "Automatic")
		{
			Add-LogEntry "SUCCESS: Winmgmt service startup type set to Automatic"
		}
	}
	else 
	{
		Add-LogEntry "Winmgmt service startuptype correctly set" "1"
	}

	Add-LogEntry "Checking status of Winmgmt service" "1"
	if((Get-Service -Name "Winmgmt").status -eq "Stopped")
	{
		Add-LogEntry "WARNING: Winmgmt service Stopped" "2"
		Add-LogEntry "Attempting to start Winmgmt service" "1"
		Start-Service -Name "Winmgmt"
		start-Sleep -Seconds 10
		if((Get-Service -Name "Winmgmt").status -eq "Stopped")
		{
			Add-LogEntry "ERROR: Could not start Winmgmt service" "3"
		}
		if((Get-Service -Name "Winmgmt").status -ne "Stopped")
		{
			Add-LogEntry "SUCCESS: Winmgmt service started" "1"
		}
	}
	else 
	{
		Add-LogEntry "Winmgmt service is running" "1"
	}

	Add-LogEntry "---------------------------" "1"
	Add-LogEntry "Checking startup type of RemoteRegistry service" "1"
	IF ((Get-Service "RemoteRegistry").StartType -ne "Automatic")
	{
		Add-LogEntry "WARNING: RemoteRegistry service needs to be set to Automatic" "2"
		Add-LogEntry "Attempting to change startup type to Automatic" "1"
		Set-Service "RemoteRegistry" -StartupType "Automatic"
		IF ((Get-Service "RemoteRegistry").StartType -ne "Automatic")
		{
			Add-LogEntry "ERROR: Could not change start type" "3"
		}
		IF ((Get-Service "RemoteRegistry").StartType -eq "Automatic")
		{
			Add-LogEntry "SUCCESS: RemoteRegistry service start type set to Automatic"
		}
	}
	else 
	{
		Add-LogEntry "RemoteRegistry service startup type correctly set" "1"
	}

	Add-LogEntry "Checking status of RemoteRegistry service" "1"
	if((Get-Service -Name "RemoteRegistry").status -eq "Stopped")
	{
		Add-LogEntry "WARNING: RemoteRegistry service Stopped" "2"
		Add-LogEntry "Attempting to start RemoteRegistry service" "1"
		Start-Service -Name "RemoteRegistry"
		start-Sleep -Seconds 10
		if((Get-Service -Name "RemoteRegistry").status -eq "Stopped")
		{
			Add-LogEntry "ERROR: Could not start RemoteRegistry service" "3"
		}
		if((Get-Service -Name "RemoteRegistry").status -eq "Running")
		{
			Add-LogEntry "SUCCESS: started RemoteRegistry service" "1"
		}
	}
	else 
	{
		Add-LogEntry "RemoteRegistry service started" "1"
	}
}

# check if cycles are working #
Function Get-ClientActionsStatus
{
	IF ($Global:InstallClient -ne "True")
	{
		Add-LogEntry "---------------------------" "1"
		$MachinePolicyRetrievalEvaluation = "{00000000-0000-0000-0000-000000000021}"
		$SoftwareUpdatesDeployment = "{00000000-0000-0000-0000-000000000108}"
		$ApplicationDeployment = "{00000000-0000-0000-0000-000000000121}"
	
		If (Get-WmiObject win32_Product | Where-Object Name -EQ "Configuration Manager Client")
		{
			$machine_status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $MachinePolicyRetrievalEvaluation
			IF($machine_status)
			{
				Add-LogEntry "Machine Policy Retrieval Evaluation Action is working correctly" "1" 
			}
			IF (!($machine_status))
			{
				Add-LogEntry "WARNING: Machine Policy Retrieval Evaluation Action is not working correctly" "2"
				Add-LogEntry "This will be resolved by reinstalling the SCCM Client"
				$Global:InstallClient = "True"
			}
	
			$SoftwareUpdate_status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $SoftwareUpdatesDeployment
			IF($SoftwareUpdate_status)
			{
				Add-LogEntry "Software Update Deployment Action is working correctly" "1"
			}
			IF(!($softwareUpdate_status))
			{
				Add-LogEntry "WARNING: Software Update Deployment Action is not working correctly" "2"
				Add-LogEntry "This will be resolved by reinstalling the SCCM Client"
				$Global:InstallClient = "True"
			}
	
			$ApplicationDeployment_Status = Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule $ApplicationDeployment
			IF($ApplicationDeployment_Status)
			{
				Add-LogEntry "Application Deployment Action is working correctly"
			}
			IF(!($ApplicationDeployment_Status))
			{
				Add-LogEntry "WARNING: Application Deployment Action is not working correctly" "2"
				Add-LogEntry "This will be resolved by reinstalling the SCCM Client"
				$Global:InstallClient = "True"
			}
		}
	}
}

# Checks if WMI is working correctly #
Function Get-WMIStatus
{
	Add-LogEntry "---------------------------" "1"
	Add-LogEntry "Checking status of WMI" "1"
	IF ($Global:InstallClient -eq "True")
	{
		Add-LogEntry "SCCM Client set to be reinstalled, will not check SCCM WMI" "1"
		try
		{
			Get-WmiObject win32_ComputerSystem -ErrorAction Stop
			Get-WmiObject win32_OperatingSystem -ErrorAction Stop
			Get-WmiObject win32_Service -ErrorAction stop
			$WMIStatus = "Good"
		}
		Catch
		{
			Add-LogEntry "ERROR: $_" "3"
		}
	}
	IF ($Global:InstallClient -ne "True")
	{
		Add-LogEntry "Checking system and SCCM components of WMI" "1"
		try 
		{
			Get-WmiObject win32_ComputerSystem -ErrorAction Stop
			Get-WmiObject win32_OperatingSystem -ErrorAction Stop
			Get-WmiObject win32_Service -ErrorAction Stop
			Get-WmiObject -Namespace root\ccm -Class sms_client -ErrorAction Stop
			$WMIStatus = "Good"
		}
		catch 
		{
			Add-LogEntry "ERROR: $_" "3"	
		}
	}

	if($WMIStatus -eq "Good")
	{
		Add-LogEntry "WMI Seems to be working correctly" "1"
	}
	else
	{
		Add-LogEntry "WARNING: One or more WMI classes are corrupted" "2"
		IF ($Global:InstallClient -ne "True") {Add-LogEntry "WARNING: SCCM Client will need to be reinstalled" "2"}
		Add-LogEntry "Attempting to repair WMI" "1"
		$DependentServices = Get-Service winmgmt -DependentServices | Where-Object Status -eq "Running"

		IF ((Get-Service CcmExec).Status -eq "Running") 
		{
			Add-LogEntry "Attempting to stop CcmExec service" "1"
			Stop-Service "CcmExec" -Force -ErrorAction SilentlyContinue
			Start-Sleep -Seconds 10
			IF ((Get-Service CcmExec).Status -eq "Running") 
			{
				Add-LogEntry "ERROR: Could not stop CcmExec service" "3"
				Add-LogEntry "It is not recommened to continue with WMI repair proccess, Stopping Script" "2"
				Add-LogEntry "ACTION: try to stop SMS Agent Host service manully if you cannont uninstall the SCCM client and run the script again" "2"
				Exit-Script
			}
		}

		IF ((Get-Service Winmgmt).Status -eq "Running") 
		{
			Add-LogEntry "Attempting to stop winmgmt service" "1"
			Stop-Service "winmgmt" -Force -ErrorAction SilentlyContinue
			Start-Sleep -Seconds 10
			IF ((Get-Service Winmgmt).Status -eq "Running") 
			{
				Add-LogEntry "ERROR: Could not stop winmgmt service" "3"
				Add-LogEntry "It is not recommened to continue with WMI repair proccess, Stopping Script" "2"
				Add-LogEntry "ACTION: Try to stop the Windows Management Instrumentation service manully if you cannont the computer will need to be reimaged"
				Exit-Script
			}
		}

		IF ((Get-Service wmiApSrv).Status -eq "Running") 
		{
			Add-LogEntry "Attempting to stop wmiApSrv service" "1"
			Stop-Service "wmiApSrv" -Force -ErrorAction SilentlyContinue
			Start-Sleep -Seconds 10
			IF ((Get-Service wmiApSrv).Status -eq "Running") 
			{
				Add-LogEntry "ERROR: Could not stop wmiApSrv service" "3"
				Add-LogEntry "It is not recommened to continue with WMI repair proccess, Stopping Script" "2"
				Exit-Script
			}
		}

		Foreach ($Service in $DependentServices)
		{
			IF ((Get-Service $Service).Status -eq "Running")
			{
				Add-LogEntry "Attempting to stop $Service service" "1"
				Stop-Service "$Service" -Force -ErrorAction
				Start-Sleep 10
				IF ((Get-Service $Service).Status -eq "Running") 
				{
					Add-LogEntry "ERROR: Could not stop $Service service" "3"
					Add-LogEntry "It is not recommened to continue with WMI repair proccess, Stopping Script" "2"
					Exit-Script
				}
			}
		}

		Add-LogEntry "All Services stopped, Repairing WMI" "1"
		& ($ENV:SystemRoot+"\system32\wbem\winmgmt.exe") /resetrepository
		& ($ENV:SystemRoot+"\system32\wbem\winmgmt.exe") /salvagerepository
		Add-LogEntry "Completed running the repaire process" "1"
		Add-LogEntry "Attempting to restart services needed for WMI" "1"
		
		Add-LogEntry "Attempting to restart Winmgmt service" "1"
		Start-Service "Winmgmt"
		Start-Sleep -Seconds 5
		IF ((Get-Service Winmgmt).Status -eq "Stopped") 
		{
			Add-LogEntry "ERROR: Could not restart winmgmt service" "3"
			Add-LogEntry "Attempting to restart winmgmt service in 10 seconds" "1"
			Start-Sleep -Seconds 10 
			Start-Service "Winmgmt"
			IF ((Get-Service Winmgmt).Status -eq "Running") 
			{ 
				Add-LogEntry "SUCCESS: Winmgmt service is now running" "1"
			}
			Else 
			{
				Add-LogEntry "ERROR: Still Could not start winmgmt service" "3"
				Add-LogEntry "ACTION: try to restart Windows Management Instrumentation service manully if you are unable to computer will need to me reimaged" "2"
			}
		}
		Else 
		{
			Add-LogEntry "SUCCESS: Winmgmt service is now running" "1"
		}

		Add-LogEntry "Attempting to restart wmiApSrv service" "1"
		Start-Service "wmiApSrv" 
		Start-Sleep -Seconds 5
		IF ((Get-Service wmiApSrv).Status -eq "Stopped") 
		{
			Add-LogEntry "ERROR: Could not restart wmiapSrv service" "3"
			Add-LogEntry "Attempting to restart wimApSrv service in 10 seconds" "1"
			Start-Sleep -Seconds 10
			Start-Service "wmiApSrv"
			IF ((Get-Service wmiApSrv).Status -eq "Running") 
			{
				Add-LogEntry "SUCCESS: wmiApSrv service is now running" "1"
			}
		}
		else 
		{
			Add-LogEntry "SUCCESS: wmiApSrv service is now running" "1"
		}

		Add-LogEntry "Attempting to restart WmiPrvSE service" "1"
		Start-Service "WmiPrvSE"
		Start-Sleep -Seconds 5
		IF ((Get-Service WmiPrvSE).Status -eq "Stopped") 
		{
			Add-LogEntry "ERROR: Could not restart WmiPrvSE service" "3"
			Add-LogEntry "Attempting to restart WmiPrvSE service in 10 seconds" "1"
			Start-Sleep -Seconds 10
			Start-Service "WmiPrvSE"
			IF ((Get-Service WmiPrvSE).Status -eq "Running") {Add-LogEntry "SUCCESS: WmiPrvSE service is now running" "1"}
		}
		else 
		{
			Add-LogEntry "SUCCESS: WmiPrvSE service is now running" "1"
		}

		Foreach ($Service in $DependentServices)
		{
			Add-LogEntry "Attempting to restart $Service service" "1"
			Start-Service $Service
			Start-Sleep -Seconds 5 
			IF ((Get-Service "$Service").Status -eq "Stopped")
			{
				Add-LogEntry "ERROR: Could not restart $Service" "3"
				Add-LogEntry "Attempting to restart $Service service in 10 seconds"
				Start-Sleep -Seconds 10
				Start-Service $Service
				IF ((Get-Service "$Service").Status -eq "Running") {Add-LogEntry "SUCCESS: $Service service is now running" "1"}
			}
			else 
			{
				Add-LogEntry "SUCCESS: $Service service is now running" "1"
			}
		}
		$Global:InstallClient = "True"
		try 
		{
			Get-WmiObject win32_ComputerSystem -ErrorAction Stop
			Get-WmiObject win32_OperatingSystem -ErrorAction Stop
			Get-WmiObject win32_Service -ErrorAction Stop
			Add-LogEntry "SUCCESS: Standard WMI has been repaired" "1"
			Add-LogEntry "Will Check SCCM WMI after client install" "1"
			Add-LogEntry "Reinstalling the SCCM Client to repair the SCCM part of WMI" "1"
			$Global:CheckWMI = "True"
		}
		catch 
		{
			Add-LogEntry "ERROR: Standard WMI was not repaired - $_" "3"
			Add-LogEntry "ACTION: This device needs to be reimaged" "2"
			Exit-Script
		}
	}
}

# Counts number of items in computer temp folder #
Function Get-TempFiles
{
	Add-LogEntry "---------------------------" "1"
	Add-LogEntry "Gathering Temp file count"
	Add-LogEntry "More then 60000 items can be problematic for the SCCM client"
	$TempCount = ( Get-ChildItem c:\windows\temp -recurse -Force | Measure-Object ).Count 
	IF ($TempCount -ge "60000") 
	{
		Add-LogEntry "WARNING: $TempCount items found" "2"
		Add-LogEntry "Removeing temp items" "1"
		Remove-Item C:\Windows\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
	}
	Else 
	{
		Add-LogEntry "$TempCount items found" "1"
		Add-LogEntry "Nothing needs to be removed"
	}
}

####################################
# Runs the functions of the script #
# If you need to only run part of the script comment out the functions here you dont need
Get-LogFileSize
New-LogFile
Get-ClientInstalled
Get-DependentServices
# This function is disabled by defuelt, Running a manual proccess to clean the temp folder too often is not supported by Microsoft
#Get-TempFiles
Get-ClientActionsStatus
Get-WMIStatus
Install-SCCMClient
Exit-Script