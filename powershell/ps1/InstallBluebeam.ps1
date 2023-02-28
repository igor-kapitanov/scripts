function BluebeamInstall
{
######Script Starts#########
# Silent Install Bluebeam

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
$source = "https://downloads.bluebeam.com/software/downloads/20.2.85/BbRevu20.2.85.exe"
$destination = "$workdir\BbRevu20.2.85.exe"

Invoke-WebRequest -Uri $source -OutFile $destination

# Start the installation
Start-Process -FilePath "$workdir\BbRevu20.2.85.exe" -ArgumentList "--quiet"

#######Script Ends#########
}

BluebeamInstall