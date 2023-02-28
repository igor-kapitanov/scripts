##########################################################################################
# Office 365 SharedMailbox Management GUI
# Built by Patrick Klingele-Bechinger with support from Dan Rowley
# Version 3.0
##########################################################################################
#Load the .net assembly
##########################################################################################
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") > $Null
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")  > $Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Collections")  > $Null


##########################################################################################
#Code to create the GUI
##########################################################################################
$nameOfTool = "Office 365 Shared Mailbox Tool"
$form = new-object System.Windows.Forms.form 
$global:LastFolder = ""
$use_creds = $true
if ($use_creds)
{
$admin = $Host.UI.PromptForCredential("Office 365 Administrator Credentials","Enter your Office 365 user name and password.","","") 
$creds = $ADMIN.USERNAME 


get-pssession | Remove-PSSession
$ps = New-PSSession -ConfigurationName microsoft.exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $admin -Authentication basic -AllowRedirection
if ($error[0] -ne $null)
{
	[Windows.Forms.MessageBox]::Show( $error[0], "Error logging in",  [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
	$error.Clear()

	$Form.Close()
	exit
}
Import-PSSession $ps
}
else
{
	$admin = $null;
	$creds = "not connected"
}
##########################################################################################
#Functions
##########################################################################################


function HandleCmdletError( $errorCode )
{
	if ($errorCode[0] -ne $null)
	{
		[Windows.Forms.MessageBox]::Show( $errorCode[0], "An error occurred ...",  [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
		$errorCode.Clear()
		return 1
	}
	return 0
}

function DetectWhiteSpace( $stringToCheck )
{
	return $stringToCheck.Contains( " " )
}

function checkDistroGroup( $distroName )
{
	$distro = Get-DistributionGroup -id $distroName
	if ($error[0] -ne $null)
	{
		# either distro does not exist 
		# or it is a name with a space like "Distro Group"
		#    that will look like "domain\distroAlias"

		$error.Clear()
		# removing the domain name and then try again
		[string]$domainUser1 = $distroName
		$stringArray = $domainUser1.Split('\')
		if ($stringArray.Length -eq 2)
		{
			# we now try with the alias of the distro group
			$distro = Get-DistributionGroup -id $stringArray[1]
		}
		else
		{
			# we must have something different than a domain\alias 
			# maybe distroGroup does not exist
			# we give up...
			$distro = $null
		}
	}
	$error.Clear()
	return $distro
}

function CONFIGURE
{
	if ( $script:objTextBox1.text -ne "" -and $script:objTextBox2.text -ne "" -and $script:objTextBox3.text -ne "")
	{
		$sharedMbxName = $script:objTextBox1.text.Trim();         # remove white space
		$securGroup = $script:objTextBox3.text.Trim();            # remove white space
		$sharedMbxAlias = $script:objTextBox2.text.Trim();        # remove white space
		if( DetectWhiteSpace $sharedMbxAlias )
		{
			[Windows.Forms.MessageBox]::Show( "The shared mailbox alias must not contain white space characters.", $script:nameOfTool, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::information)
			return
		}

		#
		# TODO:  validate the input args
		# 		 or just let it fail
		#

		$securGroupExist = checkDistroGroup $securGroup
		if( $securGroupExist -eq $null )
		{
			[Windows.Forms.MessageBox]::Show( "The security group doesn’t exist.", $script:nameOfTool, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::warning)
		}
		else
		{
			# security group must exist, lets do it now...
			
			New-Mailbox -Name $sharedMbxName -Alias $sharedMbxAlias -Shared

			if($error[0] -eq $null)
			{
				Set-Mailbox $sharedMbxAlias -ProhibitSendReceiveQuota 5GB -ProhibitSendQuota 4.75GB -IssueWarningQuota 4.5GB
				if($error[0] -eq $null)
				{			
					Add-MailboxPermission $sharedMbxName -User $securGroup -AccessRights FullAccess
					if($error[0] -eq $null)
					{
						Add-RecipientPermission $sharedMbxName -Trustee $securGroup -AccessRights SendAs -Confirm:$False
						if($error[0] -eq $null)
						{
							[Windows.Forms.MessageBox]::Show( "The shared mailbox was created successfully.", $script:nameOfTool, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::information)
						}
					}
				}
			}
			HandleCmdletError $error
			$script:objTextBox1.text = "";
			$script:objTextBox2.text = "";
			$script:objTextBox3.text = "";
		}

	}
	else
	{
		[Windows.Forms.MessageBox]::Show( "The shared mailbox couldn’t be created because required data was missing.", $script:nameOfTool, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::information)
	}
}




function DisplayPermissions
{
	# use 
	#    sharedMbx = $objtextbox8
	#    $objtextbox9.text = distributionGroup
	$sharedMbxAlias = $script:objTextBox8.text.Trim();             # remove white space

	if ( $sharedMbxAlias -ne "")
	{
		# clear the result text boxes
		$script:objTextBox9.text = "<searching...>"
		$script:objTextBox10.text = "<searching...>"
		$users = $null
		$usersSendAs = $null
		
		if( DetectWhiteSpace $sharedMbxAlias )
		{
			[Windows.Forms.MessageBox]::Show( "The shared mailbox alias must not contain white space characters.", $script:nameOfTool, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::information)
			$script:objTextBox9.text = "<empty>"
			$script:objTextBox10.text = "<empty>"
			return
		}
		
		$users = (Get-MailboxPermission -id $sharedMbxAlias | where {($_.IsInherited -ne  "True") -and ($_.User -ne 'nt authority\self') -and ($_.IsValid -eq "True") })
		if( HandleCmdletError $error )
		{
			# we encountered an error, bail out, so we do not show the same error twice
			return;
		}
		
		# check for the 'SendAs' permissions...
		# $usersSendAs  will only contain the distributionGroup and not the sharedMailbox itself "($_.Trustee -ne 'nt authority\self')"
		$usersSendAs = ( Get-RecipientPermission -id $sharedMbxAlias | where {($_.IsInherited -ne  "True") -and ($_.Trustee -ne 'nt authority\self') -and ($_.IsValid -eq "True") })
		if( HandleCmdletError $error )
		{
			# we encountered an error, bail out, so we do not make it worse
			return;
		}		
		
		[string]$name = ""
		[string]$n = ""
		[string]$accessRights = ""
		$lines = New-Object System.Collections.ArrayList
		#$lines.Add($accessRights)
		foreach ($u in $users)
		{
			if ($u -ne $null)
			{			
				if ($name -ne "")
				{
					$name += ", "
				}
				# is our returned ID a distribution group? ...
				$distro = checkDistroGroup $u.user
				$sendAsUserAccessRights = $true
				
				# we should not get a user alias, but if it does...
				if ($distro -eq $null)
				{
					$error.Clear()
					$n = get-mailbox -id $u.user
					$name += $n
					$sendAsUserAccessRights = $false
				} 
				else 
				{
					$name += $distro.alias
					$n = $distro.alias
				}
				$accessRights += $n
				$accessRights += " : "
				$accessRights += $u.accessRights                         ## FullAccess  rights
				if ($sendAsUserAccessRights -eq $true)
				{
					$accessRights += ", "
					$accessRights += $usersSendAs.accessRights            ## SendAS   rights
				}

				$lines.Add($accessRights)
				$accessRights = ""

			}
			else
			{
				$accessRights = "<empty>"
				$lines.Add($accessRights)
				$name = "<empty>"
				$error.Clear()
			}
		}
		$script:objTextBox9.text = $name
		$script:objTextBox10.Lines = $lines
	}
	else
	{
		[Windows.Forms.MessageBox]::Show( "The shared mailbox wasn’t found because required data was missing or is incorrect.", $script:nameOfTool, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::information)
	}
		
}




##########################################################################################
# setting "Running as"
##########################################################################################
function SetRunningAs
{ param($thisTab)

	$objLabel1 = New-Object System.Windows.Forms.Label
	$objLabel1.Location = New-Object System.Drawing.Size(10,390) 
	$objLabel1.Size = New-Object System.Drawing.Size(400,60) 
	$objLabel1.Text = "Running as: $CREDS"
	$thisTab.Controls.Add($objLabel1) 
}


##########################################################################################
# create TextField & Label
##########################################################################################
function TextFieldAndLabel( $thisTab, $thisLabel, $locX, $locY, $sizeX, $labelSizeY, $boxSizeY )
{
	$objLabel2 = New-Object System.Windows.Forms.Label
	$objLabel2.Location = New-Object System.Drawing.Size($locX, $locY) 
	$objLabel2.Size = New-Object System.Drawing.Size($sizeX,$labelSizeY) 
	$objLabel2.Text = $thisLabel
	$thisTab.Controls.Add($objLabel2) 
	$objTextBox = New-Object System.Windows.Forms.TextBox 

	$objTextBox.Location = New-Object System.Drawing.Size($locX,($locY+$labelSizeY)) 
	$objTextBox.Size = New-Object System.Drawing.Size($sizeX,$boxSizeY) 
	$thisTab.Controls.Add($objTextBox)
	return $objTextBox
}



##########################################################################################
#Setup Tabs
##########################################################################################
function SetupTabs 
{

	$script:tab = new-object System.Windows.Forms.tabcontrol
	$script:tab.Location = New-object System.Drawing.Point(1, 1)
	$script:tab.Size = New-object System.Drawing.Size(590, 470)
	$script:tab.SelectedIndex = 0
	$script:tab.TabIndex = 0

	$script:tabConfig   = new-object System.Windows.Forms.tabpage
	$script:tabsetuser   = new-object System.Windows.Forms.tabpage
	$script:tabDisplayUsers = new-object System.Windows.Forms.tabpage
	$script:tabDisplayMbxPerms = new-object System.Windows.Forms.tabpage
	$script:tabAbout   = new-object System.Windows.Forms.tabpage

	$script:tabConfig.Text     = "New Shared Mailbox"
	$script:tabConfig.Size     = New-object System.Drawing.Size(550, 450)
	$script:tabConfig.TabIndex = 0
	$script:tab.controls.add($script:tabConfig)

	$script:tabDisplayUsers.Text     = "Shared Mailbox Permissions"
	$script:tabDisplayUsers.Size     = New-object System.Drawing.Size(550, 450)
	$script:tabDisplayUsers.TabIndex = 2
	$script:tab.controls.add($script:tabDisplayUsers)

	$script:tabAbout.Text     = "About"
	$script:tabAbout.Size     = New-object System.Drawing.Size(300, 250)
	$script:tabAbout.TabIndex = 4
	$script:tab.controls.add($script:tabAbout)
}
##########################################################################################
# Create Shared Mailbox Tab
##########################################################################################
function ConfigureMbx
{

	$btnConfigure          = new-object System.Windows.Forms.Button
	$btnConfigure.Location = new-object System.Drawing.Size(400,400)
	$btnConfigure.Size     = new-object System.Drawing.Size(120,23)
	$btnConfigure.Text     = "Create"
	$btnConfigure.visible  = $True
	$btnConfigure.Add_Click({CONFIGURE})
	$script:tabConfig.Controls.Add($btnConfigure)

	SetRunningAs($script:tabConfig)
	
	$script:objTextBox1 = TextFieldAndLabel $script:tabConfig "Shared mailbox name:" 10 30 280 20 20

	$script:objTextBox2 = TextFieldAndLabel $script:tabConfig "Shared mailbox alias:" 10 80 280 20 20

	$script:objTextBox3 = TextFieldAndLabel $script:tabConfig "Name or alias of the security group that will be assigned permissions to this shared mailbox:" 10 130 280 35 20
}

##########################################################################################
#Display Users Tab
##########################################################################################
function  DisplayUsersTab
{

	$btnApply          = new-object System.Windows.Forms.Button
	$btnApply.Location = new-object System.Drawing.Size(400,400)
	$btnApply.Size     = new-object System.Drawing.Size(120,23)
	$btnApply.Text     = "View Permissions"
	$btnApply.visible  = $True
	$btnApply.Add_Click({DisplayPermissions})
	$script:tabDisplayUsers.Controls.Add($btnApply)

	SetRunningAs($script:tabDisplayUsers)

	$script:objTextBox8 = TextFieldAndLabel $script:tabDisplayUsers "Shared mailbox name or alias:" 10 30 280 20 20
	
	$script:objTextBox9 = TextFieldAndLabel $script:tabDisplayUsers "Security groups assigned permissions to this mailbox:" 10 80 280 20 60
	$script:objTextBox9.ReadOnly = $true
	$script:objTextBox9.Multiline = $true

	$script:objTextBox10 = TextFieldAndLabel $script:tabDisplayUsers "Permissions assigned to security groups that have access to this mailbox:" 10 180 280 35 60
	$script:objTextBox10.ReadOnly = $true
	$script:objTextBox10.Multiline = $true	

}


##########################################################################################
#About Tab
##########################################################################################
function About
{
	$lblAbout           = New-Object System.Windows.Forms.Label
	$lblAbout.Location  = New-Object System.Drawing.Size(10,40)
	$lblAbout.Size      = New-Object System.Drawing.Size(400,60)
	$lblAbout.Text      = "This application was created by Patrick Klingele-Bechinger. Send feedback to patkling@microsoft.com." 

	$script:tabAbout.Controls.Add($lblAbout) 

	$disclaimerTxt = "############################################################################
# 
# The sample scripts are not supported under any Microsoft standard support 
# program or service. The sample scripts are provided AS IS without warranty 
# of any kind. Microsoft further disclaims all implied warranties including, without 
# limitation, any implied warranties of merchantability or of fitness for a particular 
# purpose. The entire risk arising out of the use or performance of the sample scripts 
# and documentation remains with you. In no event shall Microsoft, its authors, or 
# anyone else involved in the creation, production, or delivery of the scripts be liable 
# for any damages whatsoever (including, without limitation, damages for loss of business 
# profits, business interruption, loss of business information, or other pecuniary loss) 
# arising out of the use of or inability to use the sample scripts or documentation, 
# even if Microsoft has been advised of the possibility of such damages.
#
############################################################################"

	$script:objTextBox20 = TextFieldAndLabel $script:tabAbout "Disclaimer:" 10 110 550 20 220
	$script:objTextBox20.Text = $disclaimerTxt
	$script:objTextBox20.ReadOnly = $true
	$script:objTextBox20.Multiline = $true	
	
	SetRunningAs($script:tabAbout)
}

##########################################################################################
#Draw the GUI
##########################################################################################

$script:tab = $null;
$script:tabConfig = $null;
$script:tabsetuser = $null;
$script:tabDisplayUsers = $null;
$script:tabDisplayMbxPerms = $null;
$script:tabAbout = $null;

SetupTabs
ConfigureMbx
DisplayUsersTab
About


$form.Controls.Add($tab)
$form.Text = $script:nameOfTool
$form.size = new-object System.Drawing.Size(600,500) 
$form.autoscroll = $false
$form.MinimumSize  = new-object System.Drawing.Size(600,500)
$form.topmost = $false
$form.MaximizeBox = $False
$form.Add_Shown({$form.Activate()})
$x = $form.ShowDialog()
$Form.KeyPreview = $True



#Write-host "$x"
If ($x -eq "Cancel")
{
	
	#write-host "Form Close"
}
$Form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
	{$Form.Close()}}) 
##########################################################################################
#END
##########################################################################################

