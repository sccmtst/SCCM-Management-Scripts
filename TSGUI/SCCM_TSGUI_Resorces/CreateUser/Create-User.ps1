<#
Be sure to change the $user and $Password
#>

$User = "LocalUser"
$Password = "P@ssword1"

$Computer = [ADSI]"WinNT://$Env:COMPUTERNAME,Computer"
$LocalAdmin = $Computer.Create("User", $User)
$LocalAdmin.SetPassword("$Password")
$LocalAdmin.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
$LocalAdmin.SetInfo()

([ADSI]"WinNT://$Env:ComputerName/Users,group").Add("WinNT://$User")