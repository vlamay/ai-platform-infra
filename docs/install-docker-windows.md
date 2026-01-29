# Docker Desktop Installation - Windows

## Quick Installation Steps

### 1. Download Docker Desktop
- **URL**: https://www.docker.com/products/docker-desktop/
- **Click**: "Download for Windows"
- **File**: Docker Desktop Installer.exe (~500MB)

### 2. Run Installer
1. Double-click the downloaded file
2. Follow the installation wizard
3. **Important**: Check "Use WSL 2 instead of Hyper-V" (recommended)
4. Click "Install"

### 3. Restart Computer
Docker Desktop requires a system restart to complete installation.

### 4. Start Docker Desktop
1. Launch Docker Desktop from Start Menu
2. Wait for Docker to start (whale icon in system tray)
3. Accept the service agreement

### 5. Verify Installation
Open PowerShell and run:
```powershell
docker --version
docker ps
```

Expected output:
```
Docker version 24.x.x
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

## After Installation

Once Docker is running, we'll:

1. **Login to GitHub Container Registry**:
   ```powershell
   $env:GITHUB_TOKEN = "your_token_here"
   echo $env:GITHUB_TOKEN | docker login ghcr.io -u vlamay --password-stdin
   ```

2. **Build images**:
   ```powershell
   cd z:\Проекты\ai-platform-infra
   docker build -t ghcr.io/vlamay/api-gateway:v1.0.0 apps/api-gateway/
   docker build -t ghcr.io/vlamay/llm-inference:v1.0.0 apps/llm-inference/
   ```

3. **Push to registry**:
   ```powershell
   docker push ghcr.io/vlamay/api-gateway:v1.0.0
   docker push ghcr.io/vlamay/llm-inference:v1.0.0
   ```

## Timeline

- **Download**: 5-10 minutes (depending on internet speed)
- **Installation**: 5 minutes
- **Restart**: 2 minutes
- **First start**: 2-3 minutes
- **Total**: ~15-20 minutes

## Meanwhile

While Docker is installing, the EKS cluster is still being created in the background. By the time Docker is ready, the cluster should be close to completion!

## Troubleshooting

### WSL 2 Error
If you get WSL 2 errors:
```powershell
wsl --install
```
Then restart and try Docker again.

### Virtualization Not Enabled
1. Restart computer
2. Enter BIOS (usually F2, F10, or Del during boot)
3. Enable "Intel VT-x" or "AMD-V"
4. Save and restart
