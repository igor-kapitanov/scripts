function CopS
{
	Set-ExecutionPolicy Bypass -Scope Process -Force
	$sourceFileName = "UnivSetup.bat"
	$sourceFilePath = Join-Path -Path $env:USERPROFILE\Desktop -ChildPath $sourceFileName
	$destinationFolderPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
	$destinationFilePath = Join-Path -Path $destinationFolderPath -ChildPath $sourceFileName
	if (Test-Path -Path $destinationFilePath) {
		Write-Host "File already exists in the Startup folder."
	} else {
		Move-Item -Path $sourceFilePath -Destination $destinationFolderPath
		Write-Host "File copied to the Startup folder."
	}
}
function Mod
{
	Write-Host "***** Install Modules *****" -ForegroundColor Green
	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
	Start-Process cmd -ArgumentList "/c PresentationSettings /start" -NoNewWindow
	Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
	Install-PackageProvider -Name NuGet -Force
	Install-Module PSWindowsUpdate -Force
}
function Drv
{
	$mfc = Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer

    switch -Wildcard ($mfc) {
        '*dell*' {
            Write-Host "***** Update Dell Drivers *****" -ForegroundColor Green
            $DownloadURL = "https://wolftech.cc/6516510615/DCU.EXE"
            $DownloadLocation = "C:\Temp"
            $Reboot = "enable"

            Write-Host "Download URL is set to $DownloadURL"
            Write-Host "Download Location is set to $DownloadLocation"

            $DCUExists32 = Test-Path "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
            Write-Host "Does C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe exist? $DCUExists32"
            $DCUExists64 = Test-Path "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"
            Write-Host "Does C:\Program Files\Dell\CommandUpdate\dcu-cli.exe exist? $DCUExists64"

            if ($DCUExists32 -eq $true) {
                $DCUPath = "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
            } elseif ($DCUExists64 -eq $true) {
                $DCUPath = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"
            }

            if (-not $DCUExists32 -and -not $DCUExists64) {
                $TestDownloadLocation = Test-Path $DownloadLocation
                Write-Host "$DownloadLocation exists? $TestDownloadLocation"

                if (-not $TestDownloadLocation) {
                    New-Item $DownloadLocation -ItemType Directory -Force
                    Write-Host "Temp Folder has been created"
                }

                $TestDownloadLocationZip = Test-Path "$DownloadLocation\DellCommandUpdate.exe"
                Write-Host "DellCommandUpdate.exe exists in $DownloadLocation? $TestDownloadLocationZip"

                if (-not $TestDownloadLocationZip) {
                    Write-Host "Downloading DellCommandUpdate..."
                    Invoke-WebRequest -UseBasicParsing -Uri $DownloadURL -OutFile "$DownloadLocation\DellCommandUpdate.exe"
                    Write-Host "Installing DellCommandUpdate..."
                    Start-Process -FilePath "$DownloadLocation\DellCommandUpdate.exe" -ArgumentList "/s" -Wait
                    $DCUExists = Test-Path $DCUPath
                    Write-Host "Done. Does $DCUPath exist now? $DCUExists"
                    Set-Service -Name 'DellClientManagementService' -StartupType Manual
                    Write-Host "Just set DellClientManagementService to Manual"
                }
            }

            $DCUExists = Test-Path $DCUPath
            Write-Host "About to run $DCUPath. Let's be sure to be sure. Does it exist? $DCUExists"

            Start-Process $DCUPath -ArgumentList "/scan -report=$DownloadLocation" -Wait
            Write-Host "Checking for results."

            $XMLExists = Test-Path "$DownloadLocation\DCUApplicableUpdates.xml"
            if (-not $XMLExists) {
                Write-Host "Something went wrong. Waiting 60 seconds then trying again..."
                Start-Sleep -Seconds 60
                Start-Process $DCUPath -ArgumentList "/scan -report=$DownloadLocation" -Wait
                $XMLExists = Test-Path "$DownloadLocation\DCUApplicableUpdates.xml"
                Write-Host "Did the scan work this time? $XMLExists"
            }

            if ($XMLExists) {
                [xml]$XMLReport = Get-Content "$DownloadLocation\DCUApplicableUpdates.xml"
                $AvailableUpdates = $XMLReport.updates.update

                $BIOSUpdates = ($XMLReport.updates.update | Where-Object { $_.type -eq "BIOS" }).name.Count
                $ApplicationUpdates = ($XMLReport.updates.update | Where-Object { $_.type -eq "Application" }).name.Count
                $DriverUpdates = ($XMLReport.updates.update | Where-Object { $_.type -eq "Driver" }).name.Count
                $FirmwareUpdates = ($XMLReport.updates.update | Where-Object { $_.type -eq "Firmware" }).name.Count
                $OtherUpdates = ($XMLReport.updates.update | Where-Object { $_.type -eq "Other" }).name.Count
                $PatchUpdates = ($XMLReport.updates.update | Where-Object { $_.type -eq "Patch" }).name.Count
                $UtilityUpdates = ($XMLReport.updates.update | Where-Object { $_.type -eq "Utility" }).name.Count
                $UrgentUpdates = ($XMLReport.updates.update | Where-Object { $_.Urgency -eq "Urgent" }).name.Count

                Write-Host "Bios Updates: $BIOSUpdates"
                Write-Host "Application Updates: $ApplicationUpdates"
                Write-Host "Driver Updates: $DriverUpdates"
                Write-Host "Firmware Updates: $FirmwareUpdates"
                Write-Host "Other Updates: $OtherUpdates"
                Write-Host "Patch Updates: $PatchUpdates"
                Write-Host "Utility Updates: $UtilityUpdates"
                Write-Host "Urgent Updates: $UrgentUpdates"
            }

            if (-not $XMLExists) {
                Write-Host "We tried again and the scan still didn't run. Not sure what the problem is, but if you run the script again it'll probably work."
                exit 1
            } else {
                Remove-Item "$DownloadLocation\DCUApplicableUpdates.xml" -Force
            }

            $Result = $BIOSUpdates + $ApplicationUpdates + $DriverUpdates + $FirmwareUpdates + $OtherUpdates + $PatchUpdates + $UtilityUpdates + $UrgentUpdates
            Write-Host "Total Updates Available: $Result"

            if ($Result -gt 0) {
                $OPLogExists = Test-Path "$DownloadLocation\updateOutput.log"
                if ($OPLogExists) {
                    Remove-Item "$DownloadLocation\updateOutput.log" -Force
                }

                Write-Host "Lets do it! Updating Drivers. This may take a while..."
                Start-Process $DCUPath -ArgumentList "/applyUpdates -autoSuspendBitLocker=enable -reboot=$Reboot -outputLog=$DownloadLocation\updateOutput.log" -Wait
                Start-Sleep -Seconds 60
                Get-Content -Path "$DownloadLocation\updateOutput.log"
                Write-Host "Done."
                exit 0
            }
        }

        '*HP*' {
            Write-Host "***** Install HP Assistant *****" -ForegroundColor Green
            choco install hpsupportassistant -y
            choco install hp-bios-cmdlets -y
        }

        '*lenovo*' {
            Write-Host "***** Update Lenovo Drivers *****" -ForegroundColor Green
            choco install lenovo-thinkvantage-system-update -y
            Start-Process cmd -ArgumentList "/c PresentationSettings /start" -NoNewWindow
            Install-Module -Name 'LSUClient' -Force
            Get-LSUpdate | Install-LSUpdate -Verbose
        }
    }
}

function WUpd
{
	Write-Host "***** Update Windows *****" -ForegroundColor Green
	Get-WindowsUpdate -AcceptAll -Install -AutoReboot
}

function Prog
{
	Write-Host "***** Install Programs *****" -ForegroundColor Green
	$appname = @(
		"chocolateypackageupdater"
		"adobereader"
		"7zip.install"
		"dotnetfx"
		"netfx-4.8"
		"zoom"
		"office365business"
		"vcredist140"
		"firefox"
		"anydesk.install"
		"dotnet4.5.2"
		"directx"
		"speedtest-by-ookla"
		"powershell-core"
		"autoruns"
		"googlechrome"
		"grammarly-for-windows"
		"grammarly-chrome"
		"advanced-ip-scanner"
		"procmon"
		"displaylink"
		"adblockpluschrome"
		"lastpass-chrome"
		"onedrive"
		"naps2"
		"hp-universal-print-driver-pcl"
		"hp-universal-print-driver-ps"
		"kmupd"
		"kmupd4"
		"geupd"
		"geupd4"
		"xeroxupd"		
	)

	ForEach($app in $appname)
	{
		choco install $app -y
	}
}

function PwSet
{
	Write-Host "***** Change Power Network *****" -ForegroundColor Green
	$adapters = Get-NetAdapter -Physical | Get-NetAdapterPowerManagement
    foreach ($adapter in $adapters)
        {
        $adapter.AllowComputerToTurnOffDevice = 'Disabled'
        $adapter | Set-NetAdapterPowerManagement
        }
		
	Write-Host "***** Change Power Settings *****" -ForegroundColor Green
	Powercfg /Change monitor-timeout-ac 30
	Powercfg /Change monitor-timeout-dc 15
	Powercfg /Change standby-timeout-ac 0
	Powercfg /Change standby-timeout-dc 30
}

function RegSet
{
	Write-Host "***** UnPin programs from TaskBar *****" -ForegroundColor Green
	Set-ItemProperty -Path REGISTRY::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 1
	Set-ItemProperty -Path REGISTRY::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0
	Set-ItemProperty -Path REGISTRY::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowCortanaButton -Value 0
	Set-ItemProperty -Path REGISTRY::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds -Name ShellFeedsTaskbarViewMode -Value 2
	Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 5
	Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings -Name RestartNotificationsAllowed2 -Value 1
}

function Usr
{
	Write-Host "***** Create admin users *****" -ForegroundColor Green
    $users = @(
        @{
            UserName        = "name"
            FullName        = "fullname"
            Password        = "password"
            Description     = "First admin user"
        },
        @{
            UserName        = "name"
            FullName        = "fullname"
            Password        = "password"
            Description     = "The second admin user"
        }
    )

    $users | ForEach-Object {
        $user = $_
        $password = ConvertTo-SecureString $user.Password -AsPlainText -Force
        New-LocalUser -Name $user.UserName -Password $password -FullName $user.FullName -Description $user.Description
        Set-LocalUser -Name $user.UserName -AccountNeverExpires -PasswordNeverExpires $true -UserMayChangePassword $false
    }

    $usernames = $users.UserName
    Add-LocalGroupMember -Group "Administrators" -Member $usernames -ErrorAction Stop
    Add-LocalGroupMember -Group "Users" -Member $usernames -ErrorAction Stop
    Add-LocalGroupMember -Group "Users" -Member "User"
	Remove-LocalGroupMember -Group "Administrators" "User"
}

function DelS
{
	$filePath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\UnivSetup.bat"

	if (Test-Path $filePath) {
		Remove-Item $filePath -Force
		Write-Host "File deleted."
	} else {
		Write-Host "File does not exist."
	}
}

CopS
Mod
Drv
WUpd
Prog
PwSet
RegSet
Usr
DelS