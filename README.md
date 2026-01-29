# AI Platform Infra – Kubernetes-based LLM/AI Infrastructure

Production-ready **AI platform infrastructure** on Kubernetes, focused on LLM/AI agents, observability, and autoscaling.
This repository contains a minimal but realistic framework for an AI platform: API gateway, LLM inference service, HPA, and basic integration with an observability stack.

## 🎯 Project Goals

- Demonstrate the design and implementation of an AI platform on Kubernetes.
- Showcase MLOps/SRE practices: metrics, SLO/SLI, autoscaling.
- Serve as a foundation for further development (security, cost optimization, GitOps).

## 🧱 Architecture (Minimal Version)

Logical Layers:

- `platform` – Base cluster components (ingress, etc., to be added).
- `ai-services` – Application AI services:
  - `api-gateway` – FastAPI gateway, accepts client requests, orchestrates calls to LLM.
  - `llm-inference` – Service that calls external LLM APIs (OpenAI/Claude/etc.).
- `observability` – Prometheus / Grafana / Loki (monitoring foundation).

Network Flow:

```text
Client → API Gateway → LLM Inference → External LLM API
                  ↘ metrics/logs → Observability stack
```

## 🗂️ Repository Structure

```text
kubernetes/
  base/
    namespaces.yaml              # Base namespaces for the platform
  ai-services/
    api-gateway-deployment.yaml  # Deployment for API gateway
    api-gateway-service.yaml     # Service for API gateway
    llm-inference-deployment.yaml# Deployment for LLM proxy
    llm-inference-service.yaml   # Service for LLM proxy
    hpa-api-gateway.yaml         # HPA for API gateway
    hpa-llm-inference.yaml       # HPA for LLM proxy
  observability/
    prometheus-scrape-config.yaml# Placeholder for Prometheus scrape config
```

## 🚀 Quick Start (Local Cluster)

**Requirements:**
- `kubectl`
- Local cluster (`kind` / `minikube`, or existing K8s)

**Apply namespaces and services:**

```bash
kubectl apply -f kubernetes/base/namespaces.yaml
kubectl apply -f kubernetes/ai-services/
```

**Check status:**

```bash
kubectl get pods -n ai-services
kubectl get svc -n ai-services
```

**(Temporary) Access to API Gateway:**

```bash
kubectl port-forward -n ai-services svc/api-gateway 8080:80
# Now the API is available at http://localhost:8080
```

## 🔄 Autoscaling

Both services (`api-gateway`, `llm-inference`) have HPA configured based on CPU utilization:
- `minReplicas`: 2
- `maxReplicas`: 10
- Target CPU: 60%

In the future, custom metrics (latency/RPS) will be added for smarter autoscaling.

## 📌 Roadmap

Planned improvements:
- Ingress (NGINX) and public access to API.
- Full observability stack: Prometheus, Grafana, Loki with ready-made dashboards.
- NetworkPolicies and basic security hardening.
- SLO/SLI description and alerting rules.
- Integration with GitOps approach (Argo CD) and separate repository for applications.

**Author:** Vladyslav Maidaniuk
**GitHub:** @vlamay
