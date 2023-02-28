function DelApps
{
Write-Host "***** Delete preInstall programs *****" -ForegroundColor Green
$appname = @(
"E046963F.LenovoCompanion"
"*E0469640.LenovoUtility"
"*SkypeApp*"
"*LinkedIn*"
"*Xbox*"
"*3DViewer*"
"*SolitaireCollection*"
"*FeedbackHub*"
"*Maps*"
"*YourPhone*"
"*Portal"
"*Getstarted*"
"*Alarms*"
"*GetHelp*"
"*Messaging"
"*People"
"*news*"
"*office*"
"*Print3D*"
"*Wallet*"
"Windows PC Health Check"
"*SmartAudio3*"
"*communicationsapps*" #Mail, calendar
"*Disney*"
"*Spotify*"
"*Dolby*"
"*ScreenSketch*"
"*IntelGraphicsExperience*"
"*MSPaint*" #Paint 3D
"*Bing*"
"*PrimeVideo*"
"*TikTok*"
"*AdobePhotoshopExpress*"
"*SoundRecorder*"
"*549981C3F5F10*" #Cortana
"*Photos*" #Photos, Video editor
"*GlancebyMirametrix*"
"*LenovoSettingsforEnterprise*"
"*RealtekAudioControl*"
"*NVIDIAControlPanel*"
"*SynapticsUtilities*"
)

ForEach($app in $appname)
{
Get-AppxPackage -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-Package -Name $app | Uninstall-Package -Name $app -ErrorAction SilentlyContinue
Get-AppXProvisionedPackage -Online | where DisplayName -like $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
}

DelApps