# Quick Start Guide

This guide will help you get the AI Platform Infrastructure up and running locally in under 10 minutes.

## Prerequisites

Ensure you have the following installed:

- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (1.28+)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) (0.20+)
- OpenAI API key

### Install Prerequisites (macOS)

```bash
# Install Docker Desktop
# Download from https://www.docker.com/products/docker-desktop

# Install kubectl
brew install kubectl

# Install kind
brew install kind
```

### Install Prerequisites (Linux)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

## Step-by-Step Setup

### 1. Clone the Repository

```bash
git clone https://github.com/vlamay/ai-platform-infra.git
cd ai-platform-infra
```

### 2. Run the Setup Script

```bash
cd scripts
./setup-local.sh
```

This script will:
- Create a local Kubernetes cluster using kind
- Install NGINX Ingress Controller
- Install metrics-server (for HPA)
- Deploy all AI platform components
- Set up observability stack

**Expected time**: 3-5 minutes

### 3. Configure OpenAI API Key

Replace the placeholder API key with your actual OpenAI key:

```bash
# Delete the example secret
kubectl delete secret openai-credentials -n ai-services

# Create a new secret with your API key
kubectl create secret generic openai-credentials \
  --from-literal=api-key=sk-YOUR_REAL_OPENAI_API_KEY \
  -n ai-services
```

> **Important**: Never commit your actual API key to git!

### 4. Wait for Pods to be Ready

```bash
# Check AI services
kubectl get pods -n ai-services

# Check observability stack
kubectl get pods -n observability
```

Wait until all pods show `Running` status and are `READY (1/1)`.

### 5. Configure Local Access

Add the following to your `/etc/hosts` file:

```bash
echo "127.0.0.1 ai-gateway.local" | sudo tee -a /etc/hosts
```

## Testing the Platform

### Test API Gateway

```bash
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is Kubernetes?",
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

Expected response:
```json
{
  "response": "Kubernetes is an open-source container orchestration platform...",
  "tokens_used": 45,
  "latency_ms": 523.4,
  "model": "gpt-3.5-turbo"
}
```

### Check Health Endpoints

```bash
# API Gateway health
curl http://ai-gateway.local/healthz

# LLM Inference health (via port-forward)
kubectl port-forward -n ai-services svc/llm-inference 8001:8001 &
curl http://localhost:8001/healthz
```

### View Metrics

```bash
# API Gateway metrics
curl http://ai-gateway.local/metrics

# Prometheus (port-forward)
kubectl port-forward -n observability svc/prometheus 9090:9090
# Open http://localhost:9090 in browser
```

## Access Monitoring Dashboards

### Prometheus

```bash
kubectl port-forward -n observability svc/prometheus 9090:9090
```

Open http://localhost:9090 in your browser.

Try these queries:
- `rate(api_gateway_requests_total[5m])` - Request rate
- `histogram_quantile(0.95, rate(api_gateway_request_duration_seconds_bucket[5m]))` - p95 latency

### Grafana (when deployed)

```bash
kubectl port-forward -n observability svc/grafana 3000:3000
```

Open http://localhost:3000 in your browser.

## Using Make Commands

The project includes a Makefile for convenience:

```bash
# Show all available commands
make help

# Deploy all manifests
make deploy

# Check status
make status

# Port-forward API Gateway
make port-forward-api

# Port-forward Prometheus
make port-forward-prometheus

# View logs
make logs-api
make logs-llm

# Scale services
make scale-up
make scale-down
```

## Verify Autoscaling

### Generate Load

```bash
# Install hey (HTTP load generator)
# macOS: brew install hey
# Linux: go install github.com/rakyll/hey@latest

# Generate load
hey -z 60s -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Test","max_tokens":10}' \
  http://ai-gateway.local/v1/chat
```

### Watch HPA

```bash
# In another terminal, watch HPA scaling
watch -n 2 kubectl get hpa -n ai-services
```

You should see the replica count increase as CPU usage rises.

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n ai-services

# View pod logs
kubectl logs -n ai-services <pod-name>

# Describe pod for events
kubectl describe pod -n ai-services <pod-name>
```

### Common Issues

**Issue**: `ImagePullBackOff` error
- **Solution**: Images are not built yet. You need to build and push them first:
  ```bash
  make build
  make push
  ```

**Issue**: `CrashLoopBackOff` for llm-inference
- **Solution**: Check if the OpenAI API key is set correctly:
  ```bash
  kubectl get secret openai-credentials -n ai-services -o yaml
  ```

**Issue**: Cannot access http://ai-gateway.local
- **Solution**: 
  1. Check if ingress is running: `kubectl get pods -n ingress-nginx`
  2. Verify /etc/hosts entry: `cat /etc/hosts | grep ai-gateway`
  3. Check ingress resource: `kubectl get ingress -n ai-services`

**Issue**: HPA shows `<unknown>` for CPU
- **Solution**: Wait for metrics-server to collect data (1-2 minutes)
  ```bash
  kubectl top nodes
  kubectl top pods -n ai-services
  ```

## Cleanup

To delete the local cluster and free up resources:

```bash
make clean
# or
kind delete cluster --name ai-platform-local
```

## Next Steps

After getting the platform running:

1. **Explore the architecture**: Read [docs/architecture.md](docs/architecture.md)
2. **Learn about SRE practices**: Read [docs/sre-slo.md](docs/sre-slo.md)
3. **Customize dashboards**: Import Grafana dashboards from `kubernetes/observability/`
4. **Experiment with scaling**: Try different HPA configurations
5. **Test security**: Review NetworkPolicies and Pod Security Standards

## Getting Help

- Check the [main README](README.md)
- Review [documentation](docs/)
- Open an issue on GitHub

Happy exploring! 🚀
