# setup_env.ps1
# This script assumes Conda is installed and in the PATH.

# 0. Conda Path Discovery
$condaExe = "conda"
if (!(Get-Command $condaExe -ErrorAction SilentlyContinue)) {
    $commonPaths = @(
        "$env:USERPROFILE\anaconda3\Scripts\conda.exe",
        "$env:USERPROFILE\miniconda3\Scripts\conda.exe",
        "C:\ProgramData\anaconda3\Scripts\conda.exe"
    )
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $condaExe = $path
            break
        }
    }
}

# 1. Environment Creation
Write-Host "Creating Conda environment 'aetherscribe'..." -ForegroundColor Cyan
& $condaExe create -n aetherscribe python=3.12 -y

Write-Host "Activating environment and installing PyTorch with CUDA 11.8..." -ForegroundColor Cyan
# Note: In PowerShell, we usually use 'conda activate', but for script execution, 
# it's often better to call conda run or similar if available.
# we use 'conda run' to execute commands in the environment without needing complex shell hooks.
& $condaExe run -n aetherscribe pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
& $condaExe run -n aetherscribe pip install -r requirements.txt

Write-Host "Environment setup complete!" -ForegroundColor Green
