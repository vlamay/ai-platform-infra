# AWS EKS Tools Installation Guide (Windows)

## Current Status
✅ AWS CLI installed (v2.33.8)
❌ eksctl not installed
❌ kubectl not installed

## Installation Steps

### Option 1: Using Chocolatey (Recommended)

```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install eksctl
choco install eksctl -y

# Install kubectl
choco install kubernetes-cli -y

# Verify
eksctl version
kubectl version --client
```

### Option 2: Manual Installation

#### Install eksctl
```powershell
# Download latest release
$EKSCTL_VERSION = "0.167.0"
Invoke-WebRequest -Uri "https://github.com/weaveworks/eksctl/releases/download/v$EKSCTL_VERSION/eksctl_Windows_amd64.zip" -OutFile "eksctl.zip"

# Extract
Expand-Archive -Path eksctl.zip -DestinationPath C:\eksctl

# Add to PATH
$env:Path += ";C:\eksctl"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\eksctl", [EnvironmentVariableTarget]::User)

# Verify
eksctl version
```

#### Install kubectl
```powershell
# Download
curl.exe -LO "https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe"

# Move to Program Files
New-Item -ItemType Directory -Force -Path "C:\Program Files\kubectl"
Move-Item kubectl.exe "C:\Program Files\kubectl\"

# Add to PATH
$env:Path += ";C:\Program Files\kubectl"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\kubectl", [EnvironmentVariableTarget]::User)

# Verify
kubectl version --client
```

## After Installation

### Configure AWS Credentials
```powershell
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key  
# - Default region: us-east-1
# - Default output: json
```

### Verify Setup
```powershell
aws sts get-caller-identity
eksctl version
kubectl version --client
```

## Next Steps

Once tools are installed, run:
```powershell
cd z:\Проекты\ai-platform-infra
eksctl create cluster -f eks-cluster.yaml
```
