dim Computerdn, strComputerName

dim Args
Set WshShell = WScript.CreateObject("WScript.Shell")

'----Get Computer DN------
Set objADSysInfo = CreateObject("ADSystemInfo")
ComputerDN = objADSysInfo.ComputerName
strcomputerdn = "LDAP://" & computerDN
Set objADSysInfo = Nothing
'-----Read commandline---
Set args = WScript.Arguments
strdesc = args(0)
Addcompdesc strdesc
Function addcompdesc(strPCdescription)
 Set objComputer = GetObject (strComputerDN)
 objComputer.Put "Description", strPCdescription
 objComputer.SetInfo

end function