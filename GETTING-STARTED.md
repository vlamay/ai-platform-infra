# Getting Started with AI Platform Infrastructure

This guide will walk you through setting up the AI Platform Infrastructure from scratch to production deployment.

## 📋 Table of Contents

1. [Initial Setup](#initial-setup)
2. [Local Development](#local-development)
3. [Building Docker Images](#building-docker-images)
4. [Git Repository Setup](#git-repository-setup)
5. [Production Deployment](#production-deployment)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

## Initial Setup

### System Requirements

**Minimum**:
- 4 CPU cores
- 8 GB RAM
- 20 GB disk space
- macOS, Linux, or Windows (WSL2)

**Software Requirements**:
- Docker Desktop or Docker Engine (20.10+)
- kubectl (1.28+)
- kind or minikube
- git
- make (optional, but recommended)

### Installation

**macOS**:
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install kubectl kind docker git

# Start Docker Desktop
open -a Docker
```

**Linux (Ubuntu/Debian)**:
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**Windows (WSL2)**:
```bash
# Install WSL2 and Ubuntu
wsl --install

# In WSL2 terminal, follow Linux instructions above
```

## Local Development

### Step 1: Clone and Setup

```bash
# Clone from git
git clone https://github.com/vlamay/ai-platform-infra.git
cd ai-platform-infra
```

### Step 2: Quick Setup with Script

The fastest way to get started:

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run automated setup
cd scripts
./setup-local.sh
```

This script will:
- ✅ Create a local Kubernetes cluster
- ✅ Install NGINX Ingress Controller
- ✅ Install metrics-server
- ✅ Deploy all platform components
- ✅ Set up observability stack
- ✅ Apply security policies

**Time**: ~5 minutes

### Step 3: Configure Secrets

Get your OpenAI API key:
1. Go to https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Copy the key (starts with `sk-...`)

Apply the secret:
```bash
kubectl create secret generic openai-credentials \
  --from-literal=api-key=sk-YOUR_ACTUAL_API_KEY_HERE \
  -n ai-services
```

**⚠️ Important**: Never commit this key to git!

### Step 4: Configure Local Access

Add the service to your hosts file:

```bash
# macOS/Linux
echo "127.0.0.1 ai-gateway.local" | sudo tee -a /etc/hosts

# Windows (run as Administrator in PowerShell)
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "127.0.0.1 ai-gateway.local"
```

### Step 5: Test the Deployment

```bash
# Test health endpoint
curl http://ai-gateway.local/healthz

# Expected output:
# {"status":"healthy","service":"api-gateway"}

# Test chat endpoint
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is Kubernetes?",
    "max_tokens": 50,
    "temperature": 0.7
  }'
```

### Step 6: Access Monitoring

**Prometheus**:
```bash
kubectl port-forward -n observability svc/prometheus 9090:9090
# Open http://localhost:9090
```

**Pod Logs**:
```bash
# API Gateway logs
make logs-api
# or
kubectl logs -n ai-services -l app=api-gateway -f

# LLM Inference logs
make logs-llm
# or
kubectl logs -n ai-services -l app=llm-inference -f
```

## Building Docker Images

### Prerequisites

1. **GitHub account** with Container Registry enabled
2. **Personal Access Token** with `write:packages` scope

Create token:
- Go to GitHub Settings → Developer settings → Personal access tokens
- Click "Generate new token (classic)"
- Select `write:packages` scope
- Copy and save the token

### Step 1: Login to GitHub Container Registry

```bash
# Set your GitHub username
export GITHUB_USERNAME=vlamay

# Login
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
```

### Step 2: Build Images

```bash
# Build both images
make build

# Or build individually
make build-api   # Build API Gateway
make build-llm   # Build LLM Inference
```

### Step 3: Push to Registry

```bash
# Push both images
make push

# Or push individually
make push-api    # Push API Gateway
make push-llm    # Push LLM Inference
```

### Step 4: Make Images Public

1. Go to https://github.com/USERNAME?tab=packages
2. Click on each package
3. Go to "Package settings"
4. Under "Danger Zone", click "Change visibility"
5. Select "Public"
6. Confirm the change

## Git Repository Setup

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `ai-platform-infra`
3. Description: `Production-ready AI Platform Infrastructure on Kubernetes`
4. **Public** repository
5. **Do NOT** initialize with README, .gitignore, or license
6. Click "Create repository"

### Step 2: Initialize Git and Push

```bash
# Run the automated script
bash scripts/init-git.sh

# Or manually:
git init
git add .
git commit -m "Initial commit: AI Platform Infrastructure"
git branch -M main
git remote add origin git@github.com:vlamay/ai-platform-infra.git
git push -u origin main
```

### Step 3: Create Release

```bash
# Tag the release
git tag -a v1.0.0 -m "Initial release: AI Platform Infrastructure v1.0.0"
git push origin v1.0.0

# Create release on GitHub
# Go to: https://github.com/vlamay/ai-platform-infra/releases/new
# - Tag: v1.0.0
# - Title: "AI Platform Infrastructure v1.0.0"
# - Description: See PROJECT-SUMMARY.md for details
```

## Production Deployment

For detailed production deployment, see [docs/deployment.md](docs/deployment.md).

### Quick Production Setup (AWS EKS)

```bash
# 1. Create EKS cluster
eksctl create cluster \
  --name ai-platform-prod \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3 \
  --managed

# 2. Deploy platform
kubectl apply -f kubernetes/base/
kubectl apply -f kubernetes/platform/

# 3. Configure secrets (use AWS Secrets Manager in production!)
kubectl create secret generic openai-credentials \
  --from-literal=api-key=$OPENAI_API_KEY \
  -n ai-services

# 4. Deploy services
kubectl apply -f kubernetes/ai-services/
kubectl apply -f kubernetes/observability/
kubectl apply -f kubernetes/security/

# 5. Get external IP
kubectl get ingress -n ai-services
```

## Verification

### Health Checks

```bash
# Check all pods are running
kubectl get pods -n ai-services
kubectl get pods -n observability

# All pods should show:
# NAME                              READY   STATUS    RESTARTS   AGE
# api-gateway-xxx                   1/1     Running   0          2m
# llm-inference-xxx                 1/1     Running   0          2m
```

### Functional Tests

```bash
# Run test suite (when available)
make test-api

# Or manual tests
curl http://ai-gateway.local/healthz
curl http://ai-gateway.local/metrics
```

### Load Testing

```bash
# Install hey
brew install hey  # macOS
# or download from: https://github.com/rakyll/hey

# Run load test
hey -z 30s -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Test","max_tokens":10}' \
  http://ai-gateway.local/v1/chat

# Watch autoscaling
watch -n 2 kubectl get hpa -n ai-services
```

## Troubleshooting

### Common Issues

**1. Pods stuck in `ImagePullBackOff`**

```bash
# Check if images exist and are public
docker pull ghcr.io/vlamay/api-gateway:latest
docker pull ghcr.io/vlamay/llm-inference:latest

# If not, build and push:
make build
make push
```

**2. Pods in `CrashLoopBackOff`**

```bash
# Check logs
kubectl logs -n ai-services <pod-name>

# Common causes:
# - Missing or invalid OpenAI API key
# - Configuration errors
# - Resource limits too low
```

**3. Cannot access `ai-gateway.local`**

```bash
# Verify /etc/hosts entry
cat /etc/hosts | grep ai-gateway

# Check ingress
kubectl get ingress -n ai-services
kubectl describe ingress api-gateway-ingress -n ai-services

# Check NGINX Ingress Controller
kubectl get pods -n ingress-nginx
```

**4. High latency or errors**

```bash
# Check external API status
# OpenAI Status: https://status.openai.com/

# Check rate limits
kubectl logs -n ai-services -l app=llm-inference | grep "rate limit"

# Check resource usage
kubectl top pods -n ai-services
```

**5. Metrics not showing**

```bash
# Verify metrics-server is running
kubectl get pods -n kube-system | grep metrics-server

# Check HPA
kubectl get hpa -n ai-services

# If showing <unknown>, wait 1-2 minutes for metrics collection
```

### Getting Help

1. **Check Documentation**:
   - [Architecture](docs/architecture.md)
   - [SRE Guide](docs/sre-slo.md)
   - [API Testing](docs/api-testing.md)
   - [Deployment Checklist](docs/deployment.md)

2. **Check Logs**:
   ```bash
   make logs-api
   make logs-llm
   ```

3. **Review Events**:
   ```bash
   kubectl get events -n ai-services --sort-by='.lastTimestamp'
   ```

4. **GitHub Issues**:
   - Create an issue at: https://github.com/vlamay/ai-platform-infra/issues

## Next Steps

After successful deployment:

1. **📊 Set up Grafana**: Import dashboards and configure datasources
2. **🔒 Harden Security**: Review NetworkPolicies and Pod Security
3. **💰 Optimize Costs**: Monitor token usage and resource utilization
4. **📈 Scale**: Test autoscaling under different load patterns
5. **🚀 Deploy to Production**: Follow the [deployment checklist](docs/deployment.md)

## Useful Commands

```bash
# Get current status
make status

# Port-forward services
make port-forward-api        # API Gateway → localhost:8080
make port-forward-prometheus # Prometheus → localhost:9090

# Scale manually
make scale-up      # Scale to max replicas
make scale-down    # Scale to min replicas

# Restart services
make restart-api   # Restart API Gateway
make restart-llm   # Restart LLM Inference

# Clean up
make clean         # Delete local cluster
```

## Resources

- **Main README**: [README.md](README.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Architecture**: [docs/architecture.md](docs/architecture.md)
- **Deployment**: [docs/deployment.md](docs/deployment.md)
- **GitHub Repository**: https://github.com/vlamay/ai-platform-infra

---

**Questions?** Open an issue or check the documentation!

**Happy deploying!** 🚀
