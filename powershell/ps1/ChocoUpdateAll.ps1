param (
    [string]$UpdateApp='true',
    [string]$NewApp='false',
    [string]$Applications=''
)

if ([Environment]::GetEnvironmentVariable("UpdateApplications", "Process")) {
    $UpdateApp = [Environment]::GetEnvironmentVariable("UpdateApplications", "Process")
}
if ([Environment]::GetEnvironmentVariable("NewApplications", "Process")) {
    $NewApp = [Environment]::GetEnvironmentVariable("NewApplications", "Process")
}
if ([Environment]::GetEnvironmentVariable("Applications", "Process")) {
    $Applications = [Environment]::GetEnvironmentVariable("Applications", "Process")
}

try {
	[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
} catch [system.exception] {
	write-host "- ERROR: Could not implement TLS 1.2 Support."
	write-host "  This can occur on Windows 7 devices lacking Service Pack 1."
	write-host "  Please install that before proceeding."
	exit 1
}

function InstallUpdateChoco {
    $bool = 0
    Try {
        if (!(Test-Path($env:ChocolateyInstall + "\choco.exe"))) {
            Write-Host '----------------------------------------------------------------------------------------------------------'`n
            iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
        }
    } Catch {
        Write-Host $($_.Exception.Message)
        exit 1
    }
}

InstallUpdateChoco

Write-Host '----------------------------------------------------------------------------------------------------------'`n
if ($UpdateApp -like "true") {
    & "$env:ChocolateyInstall\choco.exe" upgrade all -y
    Write-Host `n
} else {
    & "$env:ChocolateyInstall\choco.exe" upgrade chocolatey -y
    Write-Host `n
}

if ($NewApp -like "true") {
    if ($Applications -ne " ") {
        $Applications.Split(" ") | % {
            if (!($_ -like " ") -and $_.length -ne 0) {
                Write-Host '----------------------------------------------------------------------------------------------------------'`n
                Write-Host Installing $_ 
                & "$env:ChocolateyInstall\choco.exe" install $_ -y
            }
        }
    } else {
        $VersionChoco = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($env:ChocolateyInstall + "\choco.exe").ProductVersion
        Write-Host '----------------------------------------------------------------------------------------------------------'`n
        Write-Host Installing
        Write-Host Chocolatey v$VersionChoco
        Write-Host Package name is required. Please pass at least one package name to install.`n
    }
}
Write-Host `n'----------------------------------------------------------------------------------------------------------'
exit 0