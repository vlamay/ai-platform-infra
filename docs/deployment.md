# Deployment Checklist

Complete checklist for deploying the AI Platform Infrastructure to production.

## Pre-Deployment Checklist

### 1. Repository Setup

- [ ] **Create GitHub repository**
  ```bash
  # Go to https://github.com/new
  # Repository name: ai-platform-infra
  # Description: Production-ready AI Platform Infrastructure on Kubernetes
  # Public repository
  # Do NOT initialize with README
  ```

- [ ] **Initialize git and push**
  ```bash
  cd ai-platform-infra
  bash scripts/init-git.sh
  git push -u origin main
  ```

- [ ] **Create initial release tag**
  ```bash
  git tag -a v1.0.0 -m "Initial release: AI Platform Infrastructure v1.0.0"
  git push origin v1.0.0
  ```

### 2. Container Registry Setup

- [ ] **Enable GitHub Container Registry**
  - Go to GitHub Settings → Developer settings → Personal access tokens
  - Create token with `write:packages` scope
  - Save token securely

- [ ] **Login to GitHub Container Registry**
  ```bash
  echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
  ```

### 3. Build and Push Docker Images

- [ ] **Build API Gateway image**
  ```bash
  make build-api
  # or
  docker build -t ghcr.io/vlamay/api-gateway:v1.0.0 apps/api-gateway/
  docker tag ghcr.io/vlamay/api-gateway:v1.0.0 ghcr.io/vlamay/api-gateway:latest
  ```

- [ ] **Build LLM Inference image**
  ```bash
  make build-llm
  # or
  docker build -t ghcr.io/vlamay/llm-inference:v1.0.0 apps/llm-inference/
  docker tag ghcr.io/vlamay/llm-inference:v1.0.0 ghcr.io/vlamay/llm-inference:latest
  ```

- [ ] **Push images to registry**
  ```bash
  make push
  # or
  docker push ghcr.io/vlamay/api-gateway:v1.0.0
  docker push ghcr.io/vlamay/api-gateway:latest
  docker push ghcr.io/vlamay/llm-inference:v1.0.0
  docker push ghcr.io/vlamay/llm-inference:latest
  ```

- [ ] **Make images public**
  - Go to https://github.com/vlamay?tab=packages
  - For each package, go to Package settings → Change visibility → Public

### 4. Secrets Management

- [ ] **Obtain OpenAI API Key**
  - Go to https://platform.openai.com/api-keys
  - Create new secret key
  - Save securely (1Password, etc.)

- [ ] **Store secrets in secure location**
  ```bash
  # Using 1Password CLI (example)
  op item create \
    --category=Login \
    --title="AI Platform - OpenAI API Key" \
    --field="api-key=YOUR_KEY_HERE"
  ```

## Local Deployment

### 5. Local Kubernetes Setup

- [ ] **Install prerequisites**
  ```bash
  # Check versions
  kubectl version --client
  kind version
  docker --version
  ```

- [ ] **Create local cluster**
  ```bash
  cd scripts
  ./setup-local.sh
  ```

- [ ] **Verify cluster is running**
  ```bash
  kubectl cluster-info
  kubectl get nodes
  ```

### 6. Deploy Platform Components

- [ ] **Create namespaces**
  ```bash
  kubectl apply -f kubernetes/base/namespaces.yaml
  kubectl get namespaces
  ```

- [ ] **Install NGINX Ingress**
  ```bash
  kubectl apply -f kubernetes/platform/nginx-ingress-controller.yaml
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=90s
  ```

### 7. Configure Secrets

- [ ] **Create OpenAI credentials secret**
  ```bash
  kubectl create secret generic openai-credentials \
    --from-literal=api-key=YOUR_OPENAI_API_KEY \
    -n ai-services
  ```

- [ ] **Verify secret creation**
  ```bash
  kubectl get secret openai-credentials -n ai-services
  # Do NOT run: kubectl get secret openai-credentials -n ai-services -o yaml
  # This would expose the secret!
  ```

### 8. Deploy AI Services

- [ ] **Deploy API Gateway**
  ```bash
  kubectl apply -f kubernetes/ai-services/api-gateway-serviceaccount.yaml
  kubectl apply -f kubernetes/ai-services/api-gateway-deployment.yaml
  kubectl apply -f kubernetes/ai-services/api-gateway-service.yaml
  kubectl apply -f kubernetes/ai-services/hpa-api-gateway.yaml
  ```

- [ ] **Deploy LLM Inference**
  ```bash
  kubectl apply -f kubernetes/ai-services/llm-inference-serviceaccount.yaml
  kubectl apply -f kubernetes/ai-services/llm-inference-deployment.yaml
  kubectl apply -f kubernetes/ai-services/llm-inference-service.yaml
  kubectl apply -f kubernetes/ai-services/hpa-llm-inference.yaml
  ```

- [ ] **Verify deployments**
  ```bash
  kubectl get pods -n ai-services
  kubectl get svc -n ai-services
  kubectl get hpa -n ai-services
  ```

### 9. Deploy Observability Stack

- [ ] **Deploy Prometheus**
  ```bash
  kubectl apply -f kubernetes/observability/prometheus-config.yaml
  kubectl apply -f kubernetes/observability/prometheus-rules.yaml
  kubectl apply -f kubernetes/observability/prometheus-deployment.yaml
  ```

- [ ] **Verify Prometheus**
  ```bash
  kubectl get pods -n observability
  kubectl port-forward -n observability svc/prometheus 9090:9090
  # Open http://localhost:9090
  ```

### 10. Apply Security Policies

- [ ] **Apply NetworkPolicies**
  ```bash
  kubectl apply -f kubernetes/security/network-policies.yaml
  ```

- [ ] **Verify NetworkPolicies**
  ```bash
  kubectl get networkpolicies -n ai-services
  ```

### 11. Configure Ingress

- [ ] **Deploy Ingress resource**
  ```bash
  kubectl apply -f kubernetes/platform/ingress.yaml
  ```

- [ ] **Add to /etc/hosts**
  ```bash
  echo "127.0.0.1 ai-gateway.local" | sudo tee -a /etc/hosts
  ```

## Testing & Validation

### 12. Smoke Tests

- [ ] **Test health endpoints**
  ```bash
  curl http://ai-gateway.local/healthz
  # Expected: {"status":"healthy","service":"api-gateway"}
  ```

- [ ] **Test API endpoint**
  ```bash
  curl -X POST http://ai-gateway.local/v1/chat \
    -H "Content-Type: application/json" \
    -d '{"prompt":"Hello, what is Kubernetes?","max_tokens":50}'
  ```

- [ ] **Verify metrics are being collected**
  ```bash
  curl http://ai-gateway.local/metrics | grep api_gateway_requests_total
  ```

### 13. Load Testing

- [ ] **Run basic load test**
  ```bash
  hey -z 30s -c 10 -m POST \
    -H "Content-Type: application/json" \
    -d '{"prompt":"Test","max_tokens":10}' \
    http://ai-gateway.local/v1/chat
  ```

- [ ] **Verify autoscaling works**
  ```bash
  # In another terminal
  watch -n 2 kubectl get hpa -n ai-services
  # Should see replicas increase under load
  ```

### 14. Monitoring Validation

- [ ] **Check Prometheus targets**
  ```bash
  # Port-forward Prometheus
  kubectl port-forward -n observability svc/prometheus 9090:9090
  # Go to http://localhost:9090/targets
  # All targets should be "UP"
  ```

- [ ] **Verify metrics**
  ```bash
  # In Prometheus UI, run queries:
  # - rate(api_gateway_requests_total[5m])
  # - histogram_quantile(0.95, rate(api_gateway_request_duration_seconds_bucket[5m]))
  # - sum(rate(llm_tokens_total[5m])) by (type)
  ```

- [ ] **Check for alerts**
  ```bash
  # In Prometheus UI, go to /alerts
  # Should see configured alerts (not firing if healthy)
  ```

## Production Deployment (AWS/GCP/Azure)

### 15. Cloud Prerequisites

**For AWS (EKS)**:
- [ ] AWS account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] eksctl or Terraform ready

**For GCP (GKE)**:
- [ ] GCP project with billing enabled
- [ ] gcloud CLI installed and configured
- [ ] GKE API enabled

**For Azure (AKS)**:
- [ ] Azure subscription
- [ ] Azure CLI installed and configured
- [ ] Resource group created

### 16. Create Production Cluster

**AWS EKS Example**:
```bash
eksctl create cluster \
  --name ai-platform-prod \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 10 \
  --managed
```

- [ ] Cluster created successfully
- [ ] kubectl configured for cluster
- [ ] Verify cluster access: `kubectl cluster-info`

### 17. Production Configuration

- [ ] **Update image tags in manifests**
  ```bash
  # Change from :latest to :v1.0.0
  sed -i 's/:latest/:v1.0.0/g' kubernetes/ai-services/*.yaml
  ```

- [ ] **Configure production secrets**
  - Use AWS Secrets Manager / GCP Secret Manager / Azure Key Vault
  - Or use Sealed Secrets

- [ ] **Configure resource limits appropriately**
  - Review CPU/memory requests and limits
  - Adjust based on expected load

- [ ] **Set up TLS/SSL certificates**
  - Install cert-manager
  - Configure Let's Encrypt or use cloud provider certs

### 18. Deploy to Production

- [ ] **Deploy in order**:
  1. Namespaces
  2. Platform components (Ingress)
  3. Secrets
  4. AI services
  5. Observability
  6. Security policies

- [ ] **Verify each step**:
  ```bash
  kubectl get all -n ai-services
  kubectl get all -n observability
  kubectl get networkpolicies -n ai-services
  ```

### 19. Production Testing

- [ ] Smoke tests pass
- [ ] Load tests pass
- [ ] Monitoring working
- [ ] Alerts configured
- [ ] SSL/TLS working
- [ ] DNS configured correctly

## Post-Deployment

### 20. Documentation Updates

- [ ] **Update README with production URL**
- [ ] **Document production setup specifics**
- [ ] **Create runbook for common issues**
- [ ] **Document incident response process**

### 21. Monitoring Setup

- [ ] **Configure Grafana dashboards**
  - Import dashboard from `kubernetes/observability/grafana-dashboard-overview.json`
  - Configure datasource

- [ ] **Set up alerting channels**
  - Slack/PagerDuty/Email
  - Test alert routing

- [ ] **Configure log aggregation**
  - Deploy Loki (if not done)
  - Configure log shipping

### 22. CI/CD Setup

- [ ] **GitHub Actions secrets configured**
  ```
  GHCR_TOKEN
  KUBECONFIG (base64 encoded)
  OPENAI_API_KEY (for testing)
  ```

- [ ] **Enable automatic deployments** (optional)
  - ArgoCD / Flux setup
  - GitOps workflow

### 23. Security Review

- [ ] **Pod Security Standards enabled**
- [ ] **NetworkPolicies tested**
- [ ] **Secrets properly managed**
- [ ] **RBAC configured**
- [ ] **Image vulnerability scanning** (Trivy)

### 24. Cost Optimization

- [ ] **Review resource utilization**
  ```bash
  kubectl top nodes
  kubectl top pods -n ai-services
  ```

- [ ] **Configure cluster autoscaler** (cloud)
- [ ] **Set up cost monitoring** (Kubecost, etc.)
- [ ] **Review HPA settings for efficiency**

## Ongoing Maintenance

### 25. Regular Tasks

**Daily**:
- [ ] Check monitoring dashboards
- [ ] Review error logs
- [ ] Check cost metrics

**Weekly**:
- [ ] Review SLO compliance
- [ ] Check for security updates
- [ ] Review resource utilization

**Monthly**:
- [ ] Update dependencies
- [ ] Review and update documentation
- [ ] Conduct load testing
- [ ] Review and optimize costs

## Rollback Procedure

In case of issues:

1. **Identify the issue**
   ```bash
   kubectl get pods -n ai-services
   kubectl logs -n ai-services <pod-name>
   kubectl describe pod -n ai-services <pod-name>
   ```

2. **Rollback deployment**
   ```bash
   kubectl rollout undo deployment/api-gateway -n ai-services
   kubectl rollout undo deployment/llm-inference -n ai-services
   ```

3. **Verify rollback**
   ```bash
   kubectl rollout status deployment/api-gateway -n ai-services
   kubectl rollout status deployment/llm-inference -n ai-services
   ```

4. **Restore previous image version**
   ```bash
   kubectl set image deployment/api-gateway \
     api-gateway=ghcr.io/vlamay/api-gateway:v0.9.0 \
     -n ai-services
   ```

## Support & Troubleshooting

**Common Issues**:

1. **ImagePullBackOff**: Check image exists and is public
2. **CrashLoopBackOff**: Check logs and environment variables
3. **Pods not starting**: Check resource limits and node capacity
4. **High latency**: Check external API rate limits and pod resources
5. **Autoscaling not working**: Verify metrics-server is running

**Get Help**:
- Check documentation in `docs/`
- Review logs: `make logs-api` or `make logs-llm`
- GitHub Issues: https://github.com/vlamay/ai-platform-infra/issues

---

**Deployment completed**: _______________  
**Deployed by**: _______________  
**Version**: v1.0.0  
**Environment**: [ ] Local [ ] Staging [ ] Production
