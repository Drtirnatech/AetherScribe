# run_aetherscribe.ps1
# This script automates the setup, validation, and execution of AetherScribe.

$ErrorActionPreference = "Stop"

Write-Host "--- AetherScribe Automation Suite ---" -ForegroundColor Cyan

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

if (!(Get-Command $condaExe -ErrorAction SilentlyContinue) -and ($condaExe -eq "conda")) {
    Write-Error "Conda was not found in PATH or common locations. Please ensure Anaconda/Miniconda is installed."
    exit
}

# 1. Environment Check/Setup
if (!(& $condaExe env list | Select-String "aetherscribe")) {
    Write-Host "[1/3] Environment 'aetherscribe' not found. Running setup..." -ForegroundColor Yellow
    powershell.exe -File ./setup_env.ps1
} else {
    Write-Host "[1/3] Environment 'aetherscribe' detected." -ForegroundColor Green
}

# 2. Validation
Write-Host "[2/3] Validating CUDA and Dependencies..." -ForegroundColor Cyan
$cudaCheck = & $condaExe run -n aetherscribe python -c "import torch; print(torch.cuda.is_available())"
if ($cudaCheck -eq "True") {
    Write-Host "CUDA is AVAILABLE. RTX A6000 Ada optimization active." -ForegroundColor Green
} else {
    Write-Warning "CUDA is NOT detected by PyTorch. The app will run on CPU (Slow)."
}

# 3. Launching Application
Write-Host "[3/3] Launching Backend and Frontend..." -ForegroundColor Cyan

# Check if vite is installed in node_modules
if (!(Test-Path "frontend/node_modules/vite")) {
    Write-Host "Vite or dependencies missing. Installing frontend dependencies..." -ForegroundColor Yellow
    cd frontend
    npm install
    cd ..
}

# Start Backend in a new window
Write-Host "Starting FastAPI Backend on port 8000..." -ForegroundColor Green
$condaRoot = Split-Path (Split-Path $condaExe -Parent) -Parent
$condaHook = Join-Path $condaRoot "etc\profile.d\conda.ps1"
# Ensure the sub-shell also knows where conda is by using the full path for activation if needed
$launchCmd = "if (Test-Path '$condaHook') { . '$condaHook' }; & '$condaExe' activate aetherscribe; python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000"
Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $launchCmd

# Start Frontend in a new window
Write-Host "Starting Vite Frontend on port 5173..." -ForegroundColor Green
Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd frontend; npm run dev"

Write-Host "`nAetherScribe is now starting!" -ForegroundColor Green
Write-Host "Backend: http://localhost:8000"
Write-Host "Frontend: http://localhost:5173"
Write-Host "Press any key to exit this orchestrator (the app windows will stay open)."
Pause
