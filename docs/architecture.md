# AI Platform Architecture

## Overview

Production-ready AI platform infrastructure on Kubernetes designed for LLM/AI agents with comprehensive observability, autoscaling, and security.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        External Clients                          │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ HTTPS
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NGINX Ingress Controller                      │
│                       (platform namespace)                       │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     ai-services namespace                        │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                   API Gateway                          │     │
│  │  - Request validation & routing                        │     │
│  │  - Metrics export (Prometheus)                         │     │
│  │  - Health checks                                       │     │
│  │  - Rate limiting                                       │     │
│  │  HPA: 2-10 replicas (CPU 60%, Memory 70%)            │     │
│  └─────────────────────┬──────────────────────────────────┘     │
│                        │                                         │
│                        │ HTTP                                    │
│                        ▼                                         │
│  ┌────────────────────────────────────────────────────────┐     │
│  │                 LLM Inference Service                  │     │
│  │  - OpenAI API integration                              │     │
│  │  - Token tracking                                      │     │
│  │  - Cost metrics                                        │     │
│  │  - Metrics export (Prometheus)                         │     │
│  │  HPA: 2-10 replicas (CPU 60%, Memory 70%)            │     │
│  └─────────────────────┬──────────────────────────────────┘     │
│                        │                                         │
└────────────────────────┼─────────────────────────────────────────┘
                         │
                         │ HTTPS (External API)
                         ▼
              ┌──────────────────────┐
              │   OpenAI/Claude API   │
              └──────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   observability namespace                        │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │   Prometheus     │  │     Grafana      │  │     Loki     │  │
│  │  - Metrics       │  │  - Dashboards    │  │  - Logs      │  │
│  │  - Alerts        │  │  - SLO tracking  │  │  - Search    │  │
│  │  - Recording     │  │  - Visualization │  │              │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. Platform Layer
- **NGINX Ingress Controller**: Manages external access, SSL/TLS termination, rate limiting
- **Ingress Resources**: Routes traffic to appropriate services

### 2. AI Services Layer

#### API Gateway
- **Purpose**: Front-end service for all AI platform requests
- **Features**:
  - Request validation and routing
  - Prometheus metrics export
  - Health checks
  - Correlation ID tracking
- **Scaling**: HPA based on CPU (60%) and Memory (70%)
- **Replicas**: 2-10 (min-max)

#### LLM Inference Service
- **Purpose**: Proxy to external LLM APIs (OpenAI/Claude)
- **Features**:
  - API key management (Kubernetes Secrets)
  - Token usage tracking
  - Cost estimation
  - Error handling and retries
- **Scaling**: HPA based on CPU (60%) and Memory (70%)
- **Replicas**: 2-10 (min-max)

### 3. Observability Layer

#### Prometheus
- **Metrics Collection**:
  - Request rate, latency, errors
  - Token usage and cost
  - Resource utilization
  - Custom SLO/SLI metrics
- **Alerting**: Based on SLO violations
- **Recording Rules**: Pre-calculated metrics for dashboards

#### Grafana
- **Dashboards**:
  - AI Platform Overview
  - SLO/SLI Tracking
  - Cost Analysis
  - Resource Utilization
- **Visualization**: Real-time monitoring

#### Loki (Planned)
- Log aggregation
- Log search and filtering
- Correlation with metrics

## Security

### Pod Security
- **Pod Security Standards**: Baseline enforcement, restricted audit
- **Security Context**:
  - Non-root user (UID 1000)
  - Read-only root filesystem
  - No privilege escalation
  - Capabilities dropped

### Network Security
- **NetworkPolicies**:
  - Default deny all ingress
  - Explicit allow rules for service-to-service communication
  - Observability namespace can scrape metrics
  - LLM service can access external APIs

### Secrets Management
- **Kubernetes Secrets**: For API keys
- **Future**: Sealed Secrets or external secret management (AWS Secrets Manager, HashiCorp Vault)

## Scalability

### Horizontal Pod Autoscaling (HPA)
- **Metrics**: CPU and Memory utilization
- **Policies**:
  - Scale up: Fast (30s stabilization, 100% or 2 pods per 30s)
  - Scale down: Slow (300s stabilization, 50% per 60s)
- **Future**: Custom metrics (latency, request rate)

### Resource Management
- **Requests**: Guaranteed resources for scheduling
- **Limits**: Maximum resource usage
- **Quality of Service**: Guaranteed QoS for critical services

## Observability & SRE

### SLI (Service Level Indicators)
1. **Latency**: p50, p95, p99 response time
2. **Error Rate**: Percentage of 5xx responses
3. **Availability**: Uptime percentage
4. **Token Usage**: Tokens per request
5. **Cost**: Estimated cost per 1K requests

### SLO (Service Level Objectives)
1. **Latency SLO**: p95 < 500ms
2. **Error Rate SLO**: < 1%
3. **Availability SLO**: > 99.9%

### Alerts
- High latency (p95 > 500ms for 5 minutes)
- High error rate (> 1% for 5 minutes)
- Service down (> 1 minute)
- High resource usage (> 85% for 5 minutes)
- Frequent pod restarts

## Cost Optimization

### Tracking
- Token usage metrics by model
- Estimated cost per request
- Cost trends over time

### Optimization Strategies
- Right-sizing pod resources
- Efficient autoscaling policies
- Request batching (future)
- Model selection optimization (future)

## Deployment Strategy

### Rolling Updates
- **Max Surge**: 1 additional pod during update
- **Max Unavailable**: 0 pods (zero-downtime deployments)

### Health Checks
- **Readiness Probes**: Service ready to accept traffic
- **Liveness Probes**: Service is healthy and responsive

## Future Enhancements

1. **Service Mesh**: Istio or Linkerd for advanced traffic management
2. **Rate Limiting**: Per-user or per-API-key limits
3. **Caching**: Redis for frequently accessed responses
4. **Multi-tenancy**: Namespace isolation for different teams
5. **GitOps**: ArgoCD for declarative infrastructure
6. **Cost Allocation**: Detailed cost tracking per team/project
7. **A/B Testing**: Traffic splitting for model comparison
8. **Custom Metrics**: Latency-based autoscaling
