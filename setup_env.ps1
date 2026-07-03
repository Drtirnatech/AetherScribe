# setup_env.ps1
# This script assumes Conda is installed and in the PATH.

Write-Host "Creating Conda environment 'aetherscribe'..." -ForegroundColor Cyan
conda create -n aetherscribe python=3.10 -y

Write-Host "Activating environment and installing PyTorch with CUDA 11.8..." -ForegroundColor Cyan
# Note: In PowerShell, we usually use 'conda activate', but for script execution, 
# it's often better to call conda run or similar if available.
# Here we'll just output the instructions for the user as a fallback.

conda run -n aetherscribe conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y
conda run -n aetherscribe pip install -r requirements.txt

Write-Host "Environment setup complete!" -ForegroundColor Green
