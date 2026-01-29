#!/bin/bash

# AI Platform Infrastructure - NAS Deployment Script
# Usage: ./deploy-to-nas.sh [openai-api-key]

set -e

SERVER="Vladyslav@192.168.1.173"
PROJECT_NAME="ai-platform-infra"
OPENAI_KEY="${1:-}"

echo "🚀 AI Platform Infrastructure - NAS Deployment"
echo "================================================"
echo ""

# Test SSH connection
echo "📡 Testing SSH connection to $SERVER..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes $SERVER exit 2>/dev/null; then
    echo "❌ Cannot connect to server. Please check:"
    echo "   1. Server is running"
    echo "   2. SSH is enabled"
    echo "   3. You have SSH keys configured or can enter password"
    exit 1
fi
echo "✅ SSH connection successful"
echo ""

# Check prerequisites on server
echo "🔍 Checking prerequisites on server..."
ssh $SERVER << 'PREREQ_CHECK'
echo "Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "⚠️  Please logout and login again, then re-run this script"
    exit 1
fi
echo "✅ Docker: $(docker --version)"

echo "Checking kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "⚠️  kubectl not found. Installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
fi
echo "✅ kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"

echo "Checking kind..."
if ! command -v kind &> /dev/null; then
    echo "⚠️  kind not found. Installing..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi
echo "✅ kind: $(kind version)"
PREREQ_CHECK

echo ""
echo "📦 Copying project files to server..."
rsync -avz --exclude='.git' --exclude='node_modules' \
    "$(dirname "$0")/../" "$SERVER:~/$PROJECT_NAME/"
echo "✅ Files copied"
echo ""

# Deploy on server
echo "🔧 Running deployment on server..."
ssh $SERVER << ENDSSH
set -e
cd ~/$PROJECT_NAME

echo "🐳 Building Docker images..."
docker build -t ghcr.io/vlamay/api-gateway:latest apps/api-gateway/
docker build -t ghcr.io/vlamay/llm-inference:latest apps/llm-inference/

echo ""
echo "☸️  Setting up Kubernetes cluster..."
cd scripts
chmod +x setup-local.sh
./setup-local.sh

echo ""
echo "📥 Loading images into kind cluster..."
kind load docker-image ghcr.io/vlamay/api-gateway:latest --name ai-platform-local
kind load docker-image ghcr.io/vlamay/llm-inference:latest --name ai-platform-local

echo ""
echo "🔄 Restarting deployments..."
kubectl rollout restart deployment/api-gateway -n ai-services
kubectl rollout restart deployment/llm-inference -n ai-services

echo ""
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=api-gateway -n ai-services --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=llm-inference -n ai-services --timeout=120s || true

echo ""
echo "📊 Deployment Status:"
kubectl get pods -n ai-services
kubectl get svc -n ai-services
kubectl get hpa -n ai-services

echo ""
echo "🧪 Testing health endpoint..."
sleep 5
curl -s http://ai-gateway.local/healthz || echo "⚠️  Health check failed (may need to wait)"

ENDSSH

echo ""
echo "✨ Deployment complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Configure OpenAI API key:"
echo "      ssh $SERVER"
echo "      kubectl create secret generic openai-credentials \\"
echo "        --from-literal=api-key=YOUR_KEY -n ai-services"
echo "      kubectl rollout restart deployment/llm-inference -n ai-services"
echo ""
echo "   2. Add to your Windows hosts file:"
echo "      192.168.1.173 ai-gateway.local"
echo ""
echo "   3. Test from Windows:"
echo "      curl http://ai-gateway.local/healthz"
echo ""
