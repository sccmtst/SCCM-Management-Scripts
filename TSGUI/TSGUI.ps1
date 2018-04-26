<#
.SYNOPSIS
Runs a GUI for a SCCM Task Sequence

.NOTES
Created By: Kris Gross
Contact: Krisgross@sccmtst.com
Twitter: @kmgamd
Version 1.0.0.0

.LINK
You can get updates to this script and others from here
http://www.sccmtst.com/
#>

Function Start-Form
{

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

#Variable list for software
$OptionalSoftware = @"
DisplayName,TSVariable
"",""
"Access 2007",Access2007
"Access 2010",Access2010
"Acrobat Pro 17","AcrobatPro17"
"Acrobat Standard 17","AcrobatStandard17"
"Visio Pro",Visiopro
"Visio Standard",Visiostr
"@ | ConvertFrom-Csv

Try {
    $TSProgressUI = New-Object -ComObject Microsoft.SMS.TSProgressUI
    $TSProgressUI.CloseProgressDialog()
    $TSProgressUI = $null
    $TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $TSEnv.Value("SMSTSAssignUsersMode") = "Auto"
    If ($TSEnv.Value("OSDComputerName")) {
        $TSComputerName = $TSEnv.Value("OSDComputerName")
        }
        ElseIf ($TSEnv.Value("_SMSTSMACHINENAME")) {
            $TSComputerName = $TSEnv.Value("_SMSTSMACHINENAME")
            }
        Else {
            $TSComputerName = ""
            }
    }
    Catch {
        # EXIT 1
        # Write-Error "$_"
        }

# Start form code
$form = New-Object System.Windows.Forms.Form
$form.Text = "SCCM TS GUI"
$form.Size = New-Object System.Drawing.Size(550,650) 
$form.StartPosition = "CenterScreen"
$Form.MinimizeBox = $False
$Form.MaximizeBox = $False
$Form.SizeGripStyle = "Hide"
$Form.AutoSize = $true
$Form.AutoScroll = $True 
$Icon = [system.drawing.icon]::ExtractAssociatedIcon("$ENV:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe")
$Form.Icon = $Icon

$tooltip = New-Object System.Windows.Forms.ToolTip
$ShowHelp={
    Switch ($this.name) 
    {
        "StartButton"  {$tip = "Start the image process"}
        "ComputerName" {$tip = "Name of the computer"}
        "TSType" {$tip = "Type of image to apply to the computer"}
        "ComputerDescription" {$tip = "Description of the computer that will be added to AD"}
        "SoftwareSelect" {$tip = "Possible software to install"}
        "SoftwareInstall" {$tip = "Software that will be installed"}
        "AddSoftware" {$tip = "Adds the selected software to the install list"}
        "RemoveSoftware" {$tip = "Removes the selected software from the install list"}
        "BitLocker" {$tip = "Enables bitlocker, You will be prompt for the PIN"}
        "LocalAccount" {$tip = "Adds a local user account"}
        "Email" {$tip = "Sends a completion email to you"}
        "AddMapDrivesBatFile" {$tip = "Adds the map drives bat file to the public user desktop"}
    }
    $tooltip.SetToolTip($this,$tip)
} 

#Sets the Label for the Computer name box
$ComputerNameBoxlabel = New-Object System.Windows.Forms.Label
$ComputerNameBoxlabel.Location = New-Object System.Drawing.Point(200,20) 
$ComputerNameBoxlabel.Size = New-Object System.Drawing.Size(120,20)
$ComputerNameBoxlabel.Text = "Computer Name"
$ComputerNameBoxlabel.TextAlign = "MiddleCenter"

#Sets the Computer name entry box
$ComputerNameBox = New-Object System.Windows.Forms.TextBox
$ComputerNameBox.Name = "ComputerName"
$ComputerNameBox.Location = New-Object System.Drawing.Point(135,40) 
$ComputerNameBox.Size = New-Object System.Drawing.Size(260,20)
$ComputerNameBox.Text = $TSComputerName
$ComputerNameBox.add_MouseHover($ShowHelp)
$ComputerNameBox.TextAlign = "Center"
$ComputerNameBox.MaxLength = 15
#Enables the Ok Button if Computer name is entered and Ts Type is selected
$handler_ComputerNameBox_KeyUp= {
    If (($ComputerNameBox.Text) -and ($TSTypeBox.Text)) {
            $OKButton.Enabled = 1
            }
        Else {
            $OKButton.Enabled = 0
            }
    }
$ComputerNameBox.add_KeyUp($handler_ComputerNameBox_KeyUp)

#Sets the 1st Computer Description box label
$ComputerDecBoxlabel1 = New-Object System.Windows.Forms.Label
$ComputerDecBoxlabel1.Location = New-Object System.Drawing.Point(200,70) 
$ComputerDecBoxlabel1.Size = New-Object System.Drawing.Size(120,20)
$ComputerDecBoxlabel1.Text = "Computer Description"
$ComputerDecBoxlabel1.TextAlign = "MiddleCenter"

#Sets the 2nd Computer Description box label
$ComputerDecBoxLabel2 = New-Object System.Windows.Forms.Label
$ComputerDecBoxLabel2.Location = New-Object System.Drawing.Point(115,90) 
$ComputerDecBoxLabel2.Size = New-Object System.Drawing.Size(300,20)
$ComputerDecBoxLabel2.Text = "EX: Sam Smith - Dell OptiPlex 3040 - Win 7 x64 - 8 GB"
$ComputerDecBoxLabel2.TextAlign = "MiddleCenter"

#Sets the Computer description box
$ComputerDescriptionBox = New-Object System.Windows.Forms.TextBox
$ComputerDescriptionBox.Name = "ComputerDescription"
$ComputerDescriptionBox.Location = New-Object System.Drawing.Point(135,110)
$ComputerDescriptionBox.Size = New-Object System.Drawing.Size(260,20)
$Model = (Get-WmiObject win32_ComputerSystem).Model
$ComputerDescriptionBox.Text = "$Model"
$ComputerDescriptionBox.TextAlign = "Center"
$ComputerDescriptionBox.add_MouseHover($ShowHelp)

#Sets the TS type slection box label
$TSTypeBoxlabel = New-Object System.Windows.Forms.Label
$TSTypeBoxlabel.Location = New-Object System.Drawing.Point(203,140)
$TSTypeBoxlabel.Size = New-Object System.Drawing.Size(120,20)
$TSTypeBoxlabel.Text = "Task Sequence Type"
$TSTypeBoxlabel.TextAlign = "MiddleCenter"

#Sets the TS type selection box
$TSTypeBox = New-Object System.Windows.Forms.ComboBox
$TSTypeBox.Name = "TSType"
$TSTypeBox.Location = New-Object System.Drawing.Point(190,160)
$TSTypeBox.Size = New-Object System.Drawing.Size(145,20)
$TSTypeBox.add_MouseHover($ShowHelp)
$TSTypeBox.DropDownStyle = "DropDownList"
$handler_TSTypeBox_SelectedIndexChanged= {
        If (($TSTypeBox.Text) -and ($ComputerNameBox.Text)) 
        {
            $OKButton.Enabled = 1
        }
        Else 
        {
            $OKButton.Enabled = 0
        }
    }
Foreach ($item in ("Windows 7 x64","Windows 10 1607","Windows 10 1709","Non Domain Device")) {
    $TSTypeBox.Items.Add($item) | Out-Null
    }
$TSTypeBox.add_SelectedIndexChanged($handler_TSTypeBox_SelectedIndexChanged)

#Sets the Software selection box
$SoftwareSelectBox = New-Object System.Windows.Forms.ListBox
$SoftwareSelectBox.Name = "SoftwareSelect"
$SoftwareSelectBox.Location = New-Object System.Drawing.Point(10,220)
$SoftwareSelectBox.Size = New-Object System.Drawing.Size(200,150)
$OptionalSoftware.DisplayName | Sort-Object | Foreach-Object { $SoftwareSelectBox.Items.Add("$($_)") }
$SoftwareSelectBox.SelectionMode = "MultiExtended"
$SoftwareSelectBox.add_MouseHover($ShowHelp)

#Sets the Software Conforamtion box 
$SoftwareInstallBox = New-Object System.Windows.Forms.ListBox
$SoftwareInstallBox.Name = "SoftwareInstall"
$SoftwareInstallBox.Location = New-Object System.Drawing.Point(320,220)
$SoftwareInstallBox.Size = New-Object System.Drawing.Size(200,150)
$SoftwareInstallBox.SelectionMode = "MultiExtended"
$SoftwareInstallBox.add_MouseHover($ShowHelp)

#Sets the Add Software button
$AddSoftwareButton = New-Object System.Windows.Forms.Button
$AddSoftwareButton.Name = "AddSoftware"
$AddSoftwareButton.Location = New-Object System.Drawing.Point(225,250)
$AddSoftwareButton.Size = New-Object System.Drawing.Size(75,23)
$AddSoftwareButton.Text = ">>"
$AddSoftwareButton.Add_Click({Click_Add})
$AddSoftwareButton.add_MouseHover($ShowHelp)

$RemoveSoftwareButton = New-Object System.Windows.Forms.Button
$RemoveSoftwareButton.Name = "RemoveSoftware"
$RemoveSoftwareButton.Location = New-Object System.Drawing.Point(225,300)
$RemoveSoftwareButton.Size = New-Object System.Drawing.Size(75,23)
$RemoveSoftwareButton.Text = "<<"
$RemoveSoftwareButton.Add_Click({Click_Remove})
$RemoveSoftwareButton.add_MouseHover($ShowHelp)

#Sets the label for the software select box
$SoftwareSelectBoxlabel = New-Object System.Windows.Forms.Label
$SoftwareSelectBoxlabel.Location = New-Object System.Drawing.Point(50,190)
$SoftwareSelectBoxlabel.Size = New-Object System.Drawing.Size(120,25)
$SoftwareSelectBoxlabel.Text = "Optional Software"
$SoftwareSelectBoxlabel.TextAlign = "MiddleCenter"

#Sets the label for the software select box
$InstallSoftwareLabel = New-Object System.Windows.Forms.Label
$InstallSoftwareLabel.Location = New-Object System.Drawing.Point(350,190)
$InstallSoftwareLabel.Size = New-Object System.Drawing.Size(135,25)
$InstallSoftwareLabel.Text = "Software to be Installed"
$InstallSoftwareLabel.TextAlign = "MiddleCenter"

#group box for the options
$OptionsGroupBox = New-Object System.Windows.Forms.GroupBox
$OptionsGroupBox.Location = New-Object System.Drawing.Size(55,380) 
$OptionsGroupBox.size = New-Object System.Drawing.Size(415,150) 
$OptionsGroupBox.text = "Options" 

#Sets the BitLocker Check Box
$BitlockerCheckBox = New-Object System.Windows.Forms.Checkbox
$BitlockerCheckBox.Name = "BitLocker"
$BitlockerCheckBox.Location = New-Object System.Drawing.Point(10,15)
$BitlockerCheckBox.Size = New-object System.Drawing.Size(80,40)
$BitlockerCheckBox.Text = "Enable Bitlocker"
$BitlockerCheckBox.Checked = $False
$BitlockerCheckBox.add_MouseHover($ShowHelp)

#Sets the Create local account check box
$LocalAccountCheckBox = New-Object System.Windows.Forms.Checkbox
$LocalAccountCheckBox.Name = "LocalAccount"
$LocalAccountCheckBox.Location = New-Object System.Drawing.Point(10,55)
$LocalAccountCheckBox.Size = New-object System.Drawing.Size(100,40)
$LocalAccountCheckBox.Text = "Create Local Account"
$LocalAccountCheckBox.Checked = $False
$LocalAccountCheckBox.add_MouseHover($ShowHelp)

#Sets the Email checkbox
$EmailCheckBox = New-Object System.Windows.Forms.Checkbox
$EmailCheckBox.Name = "Email"
$EmailCheckBox.Location = New-Object System.Drawing.Point(10,95)
$EmailCheckBox.Size = New-object System.Drawing.Size(100,40)
$EmailCheckBox.Text = "Send Completion Email"
$EmailCheckBox.Checked = $False
$EmailCheckBox.add_MouseHover($ShowHelp)

$MapDrivesBatCheckBox = New-Object System.Windows.Forms.Checkbox
$MapDrivesBatCheckBox.Name = "AddMapDrivesBatFile"
$MapDrivesBatCheckBox.Location = New-Object System.Drawing.Point(130,15)
$MapDrivesBatCheckBox.Size = New-object System.Drawing.Size(100,40)
$MapDrivesBatCheckBox.Text = "Add Map Drives BAT File"
$MapDrivesBatCheckBox.Checked = $False
$MapDrivesBatCheckBox.add_MouseHover($ShowHelp) 


#Sets the Ok Button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Name = "StartButton"
$OKButton.Location = New-Object System.Drawing.Point(220,545)
$OKButton.Size = New-Object System.Drawing.Size(100,55)
$OKButton.Text = "Start"
$OKButton.Enabled = 0
$OKButton.add_MouseHover($ShowHelp)
$OKButton.Add_Click({Click_Start})

#Add all objects to the form
$form.Controls.Add($OKButton)
$form.Controls.Add($ComputerNameBox)
$form.Controls.Add($ComputerDescriptionBox)
$form.Controls.Add($TSTypeBox)
$form.Controls.Add($SoftwareSelectBox)
$form.Controls.Add($ComputerNameBoxlabel)
$form.Controls.Add($ComputerDecBoxlabel1)
$form.Controls.Add($ComputerDecBoxLabel2)
$form.Controls.Add($TSTypeBoxlabel)
$form.Controls.Add($SoftwareSelectBoxlabel)
$form.Controls.Add($OptionsGroupBox)
$form.Controls.Add($SoftwareInstallBox)
$form.Controls.Add($AddSoftwareButton)
$form.Controls.Add($RemoveSoftwareButton)
$form.Controls.Add($InstallSoftwareLabel)

#Adds all object to the options group box
$OptionsGroupBox.Controls.Add($BitlockerCheckBox)
$OptionsGroupBox.Controls.Add($BitlockerTextBox)
$OptionsGroupBox.Controls.Add($BitlockerTextBoxLabel)
$OptionsGroupBox.Controls.Add($LocalAccountCheckBox)
$OptionsGroupBox.Controls.Add($EmailCheckBox)
$OptionsGroupBox.Controls.Add($MapDrivesBatCheckBox)


#Shows the form
[void]$form.ShowDialog()
[void]$form.Activate()

}

function Click_Add
{
    ForEach ($Item in $SoftwareSelectBox.SelectedItems)
    {
        $SoftwareInstallBox.Items.Add("$Item")
    }

    for ($i = $SoftwareSelectBox.SelectedIndices.Count-1; $i -ge 0; $i--)
    {
        $SoftwareSelectBox.Items.RemoveAt($SoftwareSelectBox.SelectedIndices[$i])
    }
}

function Click_Remove  
{
    Foreach ($Item in $SoftwareInstallBox.SelectedItems)
    {
        $SoftwareSelectBox.Items.Add("$Item")
    }

    for ($i = $SoftwareInstallBox.SelectedIndices.Count-1; $i -ge 0; $i--)
    {
        $SoftwareInstallBox.Items.RemoveAt($SoftwareInstallBox.SelectedIndices[$i])
    }
}

Function Click_Start
{
    #Sets TS variables based on user imput
        If ($TSEnv) 
        {
            $TSEnv.Value("OSDComputerName") = $ComputerNameBox.Text
            $TSEnv.Value("Description") = $ComputerDescriptionBox.Text
            If ($BitlockerCheckBox.Checked)
            {
                $ComputerName = $ComputerNameBox.Text | Out-String
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
                $PIN = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Bitlocker PIN for $ComputerName ", "BitLocker PIN", "")
                IF ($PIN -ne "")
                {
                    $TSEnv.Value("EnableBitlocker") = "True"
                    $TSEnv.Value("OSDBitlockerPIN") = $PIN
                }
            }
            If ($LocalAccountCheckBox.Checked) {$TSEnv.Value("AddLocalAccount") = "True"}
            IF ($TSTypeBox.Text -eq "Non Domain Device") {$TSEnv.Value("OSType") = "NonDomainDevice"}
            If ($TSTypeBox.Text -eq "Windows 7 x64") {$TSEnv.Value("OSType") = "Windows7"}
            If ($TSTypeBox.Text -eq "Windows 10 1607") {$TSEnv.Value("OSType") = "Windows10"}
            If ($TSTypeBox.Text -eq "Windows 10 1607") {$TSEnv.Value("Win10Type") = "1607"}
            If ($TSTypeBox.Text -eq "Windows 10 1709") {$TSEnv.Value("OSType") = "Windows10"}
            If ($TSTypeBox.Text -eq "Windows 10 1709") {$TSEnv.Value("Win10Type") = "1709"}
            IF ($EmailCheckBox.Checked)
            {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
                $EmailBox = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Your Email Address", "Email", "")
                IF ($EmailBox -ne "")
                {
                    $TSEnv.Value("Email") = "$EmailBox"
                    $TSEnv.Value("SendEmail") = "True"
                }
            }

            If ($MapDrivesBatCheckBox.Checked)
            {
                $TSEnv.Value("AddMapDrivesBat") = "True" 
            }

            IF ($SoftwareInstallBox.Items)
            {
                Foreach ($Item in $SoftwareInstallBox.Items)
                {
                    IF ($item -notlike "")
                    {
                        $TSEnv.Value("$(($OptionalSoftware | Where-Object {$_.DisplayName -eq $Item}).TSVariable)") = "True"
                        Write-Host $TSEnv.Value("$Item") 
                    }
                }
            }
        }
        Else 
        {
            $props = @{"Name"=$ComputerNameBox.Text;"OSType"=$TSTypeBox.Text;"Software"=$($SoftwareInstallBox.Items | Foreach-Object { $_ });}
            New-Object PSCustomObject -Property $props | Select-Object Name,OSType,Software
        } 
    $Form.Close()
}

Start-Form