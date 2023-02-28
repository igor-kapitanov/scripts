Set-ExecutionPolicy unrestricted
$LiveCred = Get-Credential
$Org = Read-Host "Input client Organization name (before onmicrosoft.com)"
write-host $Org
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/PowerShell-LiveID?DelegatedOrg=$org.onmicrosoft.com -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -Credential $LiveCred