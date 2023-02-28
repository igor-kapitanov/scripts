function HPAsist
{
#######Script Starts#########
# Silent Install HP Asistant

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
$source = "https://ftp.ext.hp.com/pub/softpaq/sp142501-143000/sp142943.exe"
$destination = "$workdir\sp142943.exe"

Invoke-WebRequest -Uri $source -OutFile $destination

# Start the installation
Start-Process -Wait -FilePath "$workdir\sp142943.exe" -ArgumentList "/S" -PassThru

#######Script Ends#########
}

HPAsist