# AI Platform Deployment - UGREEN NAS Server Guide

## Quick Start Commands

### 1. Connect to Server
```bash
ssh Vladyslav@192.168.1.173
```

### 2. Check Prerequisites
```bash
# Check Docker
docker --version
docker ps

# Check kubectl
kubectl version --client

# Check kind
kind version
```

### 3. Install Missing Tools (if needed)

#### Install Docker (if not installed)
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Logout and login again
```

#### Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### Install kind
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### 4. Transfer Project to Server

From your Windows machine, use SCP or create the project directly on server:

#### Option A: Use Git (Recommended)
```bash
# On server
cd ~
git clone https://github.com/vlamay/ai-platform-infra.git
cd ai-platform-infra
```

#### Option B: Copy from Windows
```bash
# On Windows (PowerShell)
scp -r z:\Проекты\ai-platform-infra Vladyslav@192.168.1.173:~/
```

### 5. Build Docker Images on Server
```bash
cd ~/ai-platform-infra

# Build images
docker build -t ghcr.io/vlamay/api-gateway:latest apps/api-gateway/
docker build -t ghcr.io/vlamay/llm-inference:latest apps/llm-inference/
```

### 6. Run Deployment Script
```bash
cd scripts
chmod +x setup-local.sh
./setup-local.sh
```

### 7. Load Images into Kind
```bash
kind load docker-image ghcr.io/vlamay/api-gateway:latest --name ai-platform-local
kind load docker-image ghcr.io/vlamay/llm-inference:latest --name ai-platform-local
```

### 8. Restart Deployments
```bash
kubectl rollout restart deployment/api-gateway -n ai-services
kubectl rollout restart deployment/llm-inference -n ai-services
```

### 9. Configure OpenAI Secret
```bash
kubectl create secret generic openai-credentials \
  --from-literal=api-key=YOUR_OPENAI_API_KEY \
  -n ai-services

kubectl rollout restart deployment/llm-inference -n ai-services
```

### 10. Configure Hosts
```bash
echo "127.0.0.1 ai-gateway.local" | sudo tee -a /etc/hosts
```

### 11. Test Deployment
```bash
# Check pods
kubectl get pods -n ai-services

# Test health
curl http://ai-gateway.local/healthz

# Test API
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","model":"gpt-3.5-turbo"}'
```

### 12. Access from Windows

To access from your Windows machine, add to Windows hosts file:
```
192.168.1.173 ai-gateway.local
```

Then test from Windows:
```bash
curl http://ai-gateway.local/healthz
```

---

## Automated Deployment Script

Save this as `deploy-to-nas.sh` on your Windows machine:

```bash
#!/bin/bash

SERVER="Vladyslav@192.168.1.173"
PROJECT_DIR="ai-platform-infra"

echo "🚀 Deploying AI Platform to UGREEN NAS..."

# Copy project
echo "📦 Copying project files..."
scp -r z:/Проекты/ai-platform-infra $SERVER:~/

# Execute deployment on server
echo "🔧 Running deployment on server..."
ssh $SERVER << 'ENDSSH'
cd ~/ai-platform-infra

# Build images
echo "🐳 Building Docker images..."
docker build -t ghcr.io/vlamay/api-gateway:latest apps/api-gateway/
docker build -t ghcr.io/vlamay/llm-inference:latest apps/llm-inference/

# Run setup
echo "☸️ Setting up Kubernetes..."
cd scripts
chmod +x setup-local.sh
./setup-local.sh

# Load images
echo "📥 Loading images into kind..."
kind load docker-image ghcr.io/vlamay/api-gateway:latest --name ai-platform-local
kind load docker-image ghcr.io/vlamay/llm-inference:latest --name ai-platform-local

# Restart deployments
kubectl rollout restart deployment/api-gateway -n ai-services
kubectl rollout restart deployment/llm-inference -n ai-services

# Wait for pods
kubectl wait --for=condition=ready pod -l app=api-gateway -n ai-services --timeout=120s
kubectl wait --for=condition=ready pod -l app=llm-inference -n ai-services --timeout=120s

# Test
echo "✅ Testing deployment..."
kubectl get pods -n ai-services
curl http://ai-gateway.local/healthz

ENDSSH

echo "✨ Deployment complete!"
```

---

## Monitoring & Management

### View Logs
```bash
kubectl logs -n ai-services -l app=api-gateway -f
kubectl logs -n ai-services -l app=llm-inference -f
```

### Port Forward Prometheus (from server)
```bash
kubectl port-forward -n observability svc/prometheus 9090:9090
```

### Access from Windows
```bash
ssh -L 9090:localhost:9090 Vladyslav@192.168.1.173
# Then open http://localhost:9090 in browser
```

### Scale Services
```bash
kubectl scale deployment api-gateway --replicas=5 -n ai-services
kubectl get hpa -n ai-services
```

---

## Troubleshooting

### Check cluster status
```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

### Delete and recreate
```bash
kind delete cluster --name ai-platform-local
cd ~/ai-platform-infra/scripts
./setup-local.sh
```

### Check Docker
```bash
docker ps
docker images
sudo systemctl status docker
```
