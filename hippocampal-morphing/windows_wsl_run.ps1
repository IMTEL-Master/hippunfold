param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Command
)

<#
.SYNOPSIS
    Run a project command inside WSL (Linux) from Windows PowerShell.

.DESCRIPTION
    This script converts the current project directory to a WSL path and then
    executes the given command inside WSL using `wsl.exe bash -lc`.

    It allows you to keep using Windows + PowerShell while all heavy
    neuroimaging tools (ANTs, HippUnfold, etc.) are installed in WSL.

.EXAMPLE
    # From the project root (hippocampal-morphing/)
    powershell -ExecutionPolicy Bypass -File .\windows_wsl_run.ps1 `
        "./scripts/download_templates.sh"

.EXAMPLE
    # Register labels
    .\windows_wsl_run.ps1 `
        "./scripts/register_labels.sh --template ./data/raw/mouse_template.nii.gz --labels ./data/raw/mouse_labels.nii.gz --output ./data/labels/mouse"

.EXAMPLE
    # Convert a GIFTI surface to OBJ
    .\windows_wsl_run.ps1 `
        "python ./scripts/convert_gii_to_obj.py --input ./meshes/gii/human_hippo.L.surf.gii --output ./meshes/obj/human_hippo_L.obj"

.NOTES
    Requirements:
      - WSL installed (e.g., Ubuntu)
      - Neuroimaging tools installed inside WSL
      - This repo located on a drive that WSL exposes under /mnt/<drive> (C:, D:, etc.)
#>

function Get-WslPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $WindowsPath
    )

    # Normalize to full path
    $full = [System.IO.Path]::GetFullPath($WindowsPath)

    # Expect something like C:\Users\...
    $driveLetter = $full.Substring(0, 1).ToLower()
    $relative = $full.Substring(2) -replace '\\', '/'

    return "/mnt/$driveLetter$relative"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wslProjectRoot = Get-WslPath -WindowsPath $scriptDir

Write-Host "[INFO] Project root (Windows): $scriptDir"
Write-Host "[INFO] Project root (WSL):     $wslProjectRoot"
Write-Host "[INFO] Executing in WSL:       $Command"

# Build the command that will run inside WSL
$inner = "cd '$wslProjectRoot' && $Command"

wsl.exe bash -lc "$inner"

