function InstallPrograms
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
		"grammarly-for-windows"
		"grammarly-chrome"
		"advanced-ip-scanner"
		"procmon"
		"displaylink"
		"adblockpluschrome"
		"googlechrome"
		"onedrive"
		"hp-universal-print-driver-pcl"
		"hp-universal-print-driver-ps"
		"kmupd"
		"kmupd4"
		"geupd"
		"geupd4"
		"xeroxupd"
		"naps2"
		
	)

	ForEach($app in $appname)
	{
		choco install $app -y
	}
	
	#Install CrystalDiskInfo
	#choco install crystaldiskinfo.install -y
	
	#Install Dell Command Update
	#choco install dellcommandupdate -y
	
	#Install HP Support Assistant
	#choco install hpsupportassistant -y
	
	#Install PuTTY
	#choco install putty.install -y
	
	#Install NotePad++
	#choco install notepadplusplus -y
	
	#Install Avira Free Antivirus
	#choco install avirafreeantivirus -y
	
	#Install Speccy
	#choco install speccy -y
	
	#Install iCloud
	#choco install icloud -y
	
	#Install LastPass for Chrome
	#choco install lastpass-chrome -y
	
	#Install Slack
	#choco install slack -y
	
	#Install Microsoft RDP client
	#choco install remote-desktop-client -y
	
	#Install mRemoteNG
	#choco install mremoteng -y
}