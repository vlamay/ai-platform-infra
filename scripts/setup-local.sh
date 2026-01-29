#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🤖 Setting up AI Platform Infrastructure...${NC}"

# Check prerequisites
if ! command -v kind &> /dev/null; then
  echo -e "${RED}Error: kind is not installed${NC}"
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}Error: kubectl is not installed${NC}"
  exit 1
fi

# Create cluster
if kind get clusters | grep -q "ai-platform-local"; then
  echo -e "${BLUE}Cluster ai-platform-local already exists${NC}"
else
  echo -e "${BLUE}Creating kind cluster...${NC}"
  kind create cluster --name ai-platform-local --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
fi

# Switch context
kubectl config use-context kind-ai-platform-local

echo -e "${BLUE}Applying base artifacts...${NC}"

# 1. Namespaces
kubectl apply -f ../kubernetes/base/namespaces.yaml

# 2. Platform (Ingress)
echo -e "${BLUE}Installing NGINX Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s    

kubectl apply -f ../kubernetes/platform/ingress.yaml

# 3. Observability
echo -e "${BLUE}Setting up Observability stack...${NC}"
kubectl apply -f ../kubernetes/observability/

# 4. Security
echo -e "${BLUE}Applying security policies...${NC}"
kubectl apply -f ../kubernetes/security/network-policies.yaml
# Note: User needs to create the secret manually or we use the example
kubectl apply -f ../kubernetes/security/secret-example.yaml

# 5. Metrics Server (for HPA)
echo -e "${BLUE}Installing Metrics Server...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch -n kube-system deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# 6. AI Services
echo -e "${BLUE}Deploying AI Services...${NC}"
# We assume images are pulled or loaded. For local dev, we might need to build and load.
# This script assumes images are available or pulled from GHCR. 
# If running locally without pushing, use 'kind load docker-image'
kubectl apply -f ../kubernetes/ai-services/

echo -e "${GREEN}✅ Setup complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Configure your OpenAI API key:"
echo "   kubectl delete secret openai-credentials -n ai-services"
echo "   kubectl create secret generic openai-credentials --from-literal=api-key=YOUR_KEY -n ai-services"
echo "2. Add '127.0.0.1 ai-gateway.local' to /etc/hosts"
echo "3. Test with: curl http://ai-gateway.local/healthz"
