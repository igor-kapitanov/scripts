#######Script Starts#########
# Silent Install Autodesk Desktop Connector

# Path for the workdir
$workdir = "c:\temp\"

$sixtyFourBit = Test-Path -Path "C:\Program Files"

# Check if work directory exists if not create it
If (Test-Path -Path $workdir -PathType Container){
Write-Host "$workdir already exists" -ForegroundColor Red
} ELSE {
New-Item -Path $workdir -ItemType directory
}

# Download the installer
$source = "https://www.autodesk.com/adsk-connect-64"
$destination = "$workdir\DesktopConnector-x64.exe"

Invoke-WebRequest -Uri $source -OutFile $destination

# Start the installation
Start-Process -FilePath "$workdir\DesktopConnector-x64.exe" -ArgumentList "--quiet"

#######Script Ends#########