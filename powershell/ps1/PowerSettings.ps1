function PowerSettings
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

PowerSettings