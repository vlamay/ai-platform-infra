# Install AWS Tools for EKS
# Run as Administrator

Write-Host "Installing AWS EKS Tools..." -ForegroundColor Cyan
Write-Host ""

# Create tools directory
$ToolsDir = "C:\aws-tools"
New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null

# Install eksctl
Write-Host "1. Installing eksctl..." -ForegroundColor Yellow
$eksctlVersion = "0.167.0"
$eksctlUrl = "https://github.com/weaveworks/eksctl/releases/download/v$eksctlVersion/eksctl_Windows_amd64.zip"
$eksctlZip = "$ToolsDir\eksctl.zip"

Invoke-WebRequest -Uri $eksctlUrl -OutFile $eksctlZip
Expand-Archive -Path $eksctlZip -DestinationPath "$ToolsDir\eksctl" -Force
Remove-Item $eksctlZip

Write-Host "   eksctl installed to $ToolsDir\eksctl" -ForegroundColor Green

# Install kubectl
Write-Host "2. Installing kubectl..." -ForegroundColor Yellow
$kubectlUrl = "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"
$kubectlDir = "$ToolsDir\kubectl"
New-Item -ItemType Directory -Force -Path $kubectlDir | Out-Null

Invoke-WebRequest -Uri $kubectlUrl -OutFile "$kubectlDir\kubectl.exe"
Write-Host "   kubectl installed to $kubectlDir" -ForegroundColor Green

# Add to PATH
Write-Host "3. Adding to PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
$newPaths = @("$ToolsDir\eksctl", "$kubectlDir")

foreach ($path in $newPaths) {
    if ($currentPath -notlike "*$path*") {
        $currentPath += ";$path"
    }
}

[Environment]::SetEnvironmentVariable("Path", $currentPath, [EnvironmentVariableTarget]::User)
$env:Path = $currentPath

Write-Host "   PATH updated" -ForegroundColor Green
Write-Host ""

# Verify installations
Write-Host "4. Verifying installations..." -ForegroundColor Yellow
Write-Host ""

& "$ToolsDir\eksctl\eksctl.exe" version
& "$kubectlDir\kubectl.exe" version --client

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Close and reopen PowerShell"
Write-Host "2. Run: aws configure"
Write-Host "3. Run: eksctl create cluster -f eks-cluster.yaml"
