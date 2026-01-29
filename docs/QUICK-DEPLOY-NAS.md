# AI Platform - Quick Deployment Commands for NAS

## Step 1: Test SSH Connection

```bash
ssh Vladyslav@192.168.1.173
```

If this works, continue. If not, you may need to:
- Set up SSH keys
- Enable SSH on the NAS
- Check firewall settings

## Step 2: Copy Project to Server

### Option A: Using SCP (from Windows PowerShell)
```powershell
scp -r z:\Проекты\ai-platform-infra Vladyslav@192.168.1.173:~/
```

### Option B: Using Git (on server)
```bash
ssh Vladyslav@192.168.1.173
cd ~
git clone https://github.com/vlamay/ai-platform-infra.git
# Or if not pushed yet, use SCP option above
```

## Step 3: Check Prerequisites on Server

```bash
ssh Vladyslav@192.168.1.173

# Check Docker
docker --version

# Check kubectl
kubectl version --client

# Check kind
kind version
```

## Step 4: Install Missing Tools (if needed)

### Install Docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Logout and login again
```

### Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
```

### Install kind
```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## Step 5: Build Docker Images

```bash
cd ~/ai-platform-infra

docker build -t ghcr.io/vlamay/api-gateway:latest apps/api-gateway/
docker build -t ghcr.io/vlamay/llm-inference:latest apps/llm-inference/
```

## Step 6: Run Setup Script

```bash
cd ~/ai-platform-infra/scripts
chmod +x setup-local.sh
./setup-local.sh
```

Wait for completion (3-5 minutes).

## Step 7: Load Images into Kind

```bash
kind load docker-image ghcr.io/vlamay/api-gateway:latest --name ai-platform-local
kind load docker-image ghcr.io/vlamay/llm-inference:latest --name ai-platform-local
```

## Step 8: Restart Deployments

```bash
kubectl rollout restart deployment/api-gateway -n ai-services
kubectl rollout restart deployment/llm-inference -n ai-services
```

## Step 9: Wait for Pods

```bash
kubectl wait --for=condition=ready pod -l app=api-gateway -n ai-services --timeout=120s
kubectl wait --for=condition=ready pod -l app=llm-inference -n ai-services --timeout=120s
```

## Step 10: Check Status

```bash
kubectl get pods -n ai-services
kubectl get svc -n ai-services
kubectl get hpa -n ai-services
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
api-gateway-xxxxx                 1/1     Running   0          2m
api-gateway-xxxxx                 1/1     Running   0          2m
llm-inference-xxxxx               1/1     Running   0          2m
llm-inference-xxxxx               1/1     Running   0          2m
```

## Step 11: Configure OpenAI Secret (Optional)

```bash
kubectl create secret generic openai-credentials \
  --from-literal=api-key=YOUR_OPENAI_API_KEY \
  -n ai-services

kubectl rollout restart deployment/llm-inference -n ai-services
```

## Step 12: Test Locally on Server

```bash
curl http://ai-gateway.local/healthz
```

Expected: `{"status":"ok"}`

## Step 13: Configure Access from Windows

### Add to Windows hosts file (PowerShell as Admin):
```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "192.168.1.173 ai-gateway.local"
```

### Test from Windows:
```powershell
curl http://ai-gateway.local/healthz
```

## Step 14: Test API

```bash
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"What is Kubernetes?","model":"gpt-3.5-turbo"}'
```

---

## Quick All-in-One Script

Save this and run on the server:

```bash
#!/bin/bash
cd ~/ai-platform-infra

# Build images
docker build -t ghcr.io/vlamay/api-gateway:latest apps/api-gateway/
docker build -t ghcr.io/vlamay/llm-inference:latest apps/llm-inference/

# Run setup
cd scripts
./setup-local.sh

# Load images
kind load docker-image ghcr.io/vlamay/api-gateway:latest --name ai-platform-local
kind load docker-image ghcr.io/vlamay/llm-inference:latest --name ai-platform-local

# Restart
kubectl rollout restart deployment/api-gateway -n ai-services
kubectl rollout restart deployment/llm-inference -n ai-services

# Wait
kubectl wait --for=condition=ready pod -l app=api-gateway -n ai-services --timeout=120s
kubectl wait --for=condition=ready pod -l app=llm-inference -n ai-services --timeout=120s

# Status
kubectl get pods -n ai-services
curl http://ai-gateway.local/healthz
```

---

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n ai-services
kubectl logs <pod-name> -n ai-services
```

### Delete and start over
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
