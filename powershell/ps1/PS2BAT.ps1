 [CmdletBinding()]
    param()

    $Path = Read-Host "Enter the path of the PowerShell script you want to convert"
    if (-not (Test-Path $Path -PathType Leaf)) {
        Write-Error "File not found at the specified path: $Path"
        return
    }

    $Destination = Read-Host "Enter the destination folder for the new batch file"
    if (-not (Test-Path $Destination -PathType Container)) {
        Write-Error "Destination folder not found: $Destination"
        return
    }

    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes((Get-Content -Path $Path -Raw -Encoding UTF8)))
    $newPath = Join-Path -Path $Destination -ChildPath ([Io.Path]::GetFileNameWithoutExtension($Path) + ".bat")
    "@echo off`npowershell.exe -NoExit -encodedCommand $encoded" | Set-Content -Path $newPath -Encoding Ascii