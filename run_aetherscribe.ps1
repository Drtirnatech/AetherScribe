# run_aetherscribe.ps1
# This script automates the setup, validation, and execution of AetherScribe.

$ErrorActionPreference = "Stop"

Write-Host "--- AetherScribe Automation Suite ---" -ForegroundColor Cyan

# 1. Environment Check/Setup
if (!(conda env list | Select-String "aetherscribe")) {
    Write-Host "[1/3] Environment 'aetherscribe' not found. Running setup..." -ForegroundColor Yellow
    powershell.exe -File ./setup_env.ps1
} else {
    Write-Host "[1/3] Environment 'aetherscribe' detected." -ForegroundColor Green
}

# 2. Validation
Write-Host "[2/3] Validating CUDA and Dependencies..." -ForegroundColor Cyan
$cudaCheck = conda run -n aetherscribe python -c "import torch; print(torch.cuda.is_available())"
if ($cudaCheck -eq "True") {
    Write-Host "CUDA is AVAILABLE. RTX A6000 Ada optimization active." -ForegroundColor Green
} else {
    Write-Warning "CUDA is NOT detected by PyTorch. The app will run on CPU (Slow)."
}

# 3. Launching Application
Write-Host "[3/3] Launching Backend and Frontend..." -ForegroundColor Cyan

# Check if node_modules exists
if (!(Test-Path "frontend/node_modules")) {
    Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
    cd frontend
    npm install
    cd ..
}

# Start Backend in a new window
Write-Host "Starting FastAPI Backend on port 8000..." -ForegroundColor Green
Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "conda activate aetherscribe; python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000"

# Start Frontend in a new window
Write-Host "Starting Vite Frontend on port 5173..." -ForegroundColor Green
Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "cd frontend; npm run dev"

Write-Host "`nAetherScribe is now starting!" -ForegroundColor Green
Write-Host "Backend: http://localhost:8000"
Write-Host "Frontend: http://localhost:5173"
Write-Host "Press any key to exit this orchestrator (the app windows will stay open)."
Pause
