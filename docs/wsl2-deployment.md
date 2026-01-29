# WSL2 Installation and Deployment Guide

## Step 1: Install WSL2

### Open PowerShell as Administrator

Right-click on PowerShell and select "Run as Administrator", then run:

```powershell
wsl --install
```

This command will:
- Enable WSL feature
- Install Ubuntu (default distribution)
- Set WSL2 as default version

**Important**: You will need to restart your computer after this step.

### After Restart

Open PowerShell and verify installation:

```powershell
wsl --list --verbose
```

You should see Ubuntu listed with VERSION 2.

---

## Step 2: Install Docker Desktop

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop
2. Run the installer
3. During installation, ensure "Use WSL 2 instead of Hyper-V" is checked
4. Restart your computer if prompted

### Configure Docker Desktop for WSL2

1. Open Docker Desktop
2. Go to Settings → General
3. Ensure "Use the WSL 2 based engine" is checked
4. Go to Settings → Resources → WSL Integration
5. Enable integration with your Ubuntu distribution
6. Click "Apply & Restart"

---

## Step 3: Set Up WSL2 Environment

### Open WSL Terminal

```powershell
wsl
```

You should now be in Ubuntu terminal.

### Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### Install kubectl

```bash
# Download latest kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

### Install kind

```bash
# Download kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

# Make executable
chmod +x ./kind

# Move to PATH
sudo mv ./kind /usr/local/bin/kind

# Verify
kind version
```

### Verify Docker

```bash
docker --version
docker ps
```

If Docker is not accessible, restart Docker Desktop and WSL.

---

## Step 4: Navigate to Project

```bash
# Navigate to your project (Windows drives are mounted at /mnt/)
cd /mnt/z/Проекты/ai-platform-infra

# Verify you're in the right place
ls -la
```

---

## Step 5: Run Deployment Script

```bash
# Navigate to scripts directory
cd scripts

# Make script executable
chmod +x setup-local.sh

# Run the setup script
./setup-local.sh
```

The script will:
- ✅ Create kind cluster
- ✅ Install NGINX Ingress
- ✅ Deploy namespaces
- ✅ Deploy AI services
- ✅ Install metrics-server
- ✅ Apply security policies

This will take approximately 3-5 minutes.

---

## Step 6: Configure OpenAI API Key

After the script completes, you need to add your OpenAI API key:

```bash
# Delete the example secret (if it exists)
kubectl delete secret openai-credentials -n ai-services --ignore-not-found

# Create your secret with real API key
kubectl create secret generic openai-credentials \
  --from-literal=api-key=YOUR_OPENAI_API_KEY_HERE \
  -n ai-services

# Restart pods to pick up the new secret
kubectl rollout restart deployment/llm-inference -n ai-services
```

**Get your API key from**: https://platform.openai.com/api-keys

---

## Step 7: Configure Hosts File

### In WSL

```bash
echo "127.0.0.1 ai-gateway.local" | sudo tee -a /etc/hosts
```

### In Windows (Optional, for browser access)

Open PowerShell as Administrator:

```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 ai-gateway.local"
```

---

## Step 8: Verify Deployment

### Check Cluster

```bash
kubectl cluster-info
kubectl get nodes
```

Expected: 1 node in Ready state

### Check Pods

```bash
kubectl get pods -n ai-services
kubectl get pods -n observability
kubectl get pods -n ingress-nginx
```

Expected: All pods Running (1/1 or 2/2)

### Check Services

```bash
kubectl get svc -n ai-services
```

Expected: api-gateway and llm-inference services

### Check HPA

```bash
kubectl get hpa -n ai-services
```

Expected: Both HPAs showing metrics (may take 1-2 minutes)

---

## Step 9: Test the API

### Test Health Endpoint

```bash
curl http://ai-gateway.local/healthz
```

Expected output:
```json
{"status":"ok"}
```

### Test Chat Endpoint

```bash
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is Kubernetes?",
    "model": "gpt-3.5-turbo"
  }'
```

Expected: JSON response with chat completion

---

## Step 10: Access Monitoring

### Port-forward Prometheus

```bash
kubectl port-forward -n observability svc/prometheus 9090:9090
```

Then open in browser: http://localhost:9090

---

## Troubleshooting

### Docker not accessible in WSL

```bash
# Check Docker Desktop is running
# Restart Docker Desktop
# Restart WSL: exit and run 'wsl --shutdown' in PowerShell, then 'wsl' again
```

### Pods stuck in ImagePullBackOff

The manifests reference `ghcr.io/vlamay/*` images. Build them locally:

```bash
cd /mnt/z/Проекты/ai-platform-infra

# Build images
docker build -t ghcr.io/vlamay/api-gateway:latest apps/api-gateway/
docker build -t ghcr.io/vlamay/llm-inference:latest apps/llm-inference/

# Load into kind cluster
kind load docker-image ghcr.io/vlamay/api-gateway:latest --name ai-platform-local
kind load docker-image ghcr.io/vlamay/llm-inference:latest --name ai-platform-local

# Restart deployments
kubectl rollout restart deployment/api-gateway -n ai-services
kubectl rollout restart deployment/llm-inference -n ai-services
```

### Cannot access ai-gateway.local

```bash
# Verify ingress
kubectl get ingress -n ai-services

# Check NGINX controller
kubectl get pods -n ingress-nginx

# Test with port-forward instead
kubectl port-forward -n ai-services svc/api-gateway 8080:80
# Then use: curl http://localhost:8080/healthz
```

---

## Useful Commands

```bash
# View logs
kubectl logs -n ai-services -l app=api-gateway -f
kubectl logs -n ai-services -l app=llm-inference -f

# Scale manually
kubectl scale deployment api-gateway --replicas=5 -n ai-services

# Delete and recreate cluster
kind delete cluster --name ai-platform-local
cd scripts && ./setup-local.sh

# Check resource usage
kubectl top nodes
kubectl top pods -n ai-services
```

---

## Summary

After completing these steps, you will have:

✅ WSL2 with Ubuntu installed
✅ Docker Desktop integrated with WSL2
✅ kubectl and kind installed
✅ Local Kubernetes cluster running
✅ AI Platform Infrastructure deployed
✅ All services accessible via ai-gateway.local
✅ Prometheus monitoring available

**Total time**: 30-45 minutes (including installations and restarts)
