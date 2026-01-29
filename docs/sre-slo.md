# SRE & SLO Documentation

## Service Level Objectives (SLO)

### 1. Latency SLO

**Objective**: 95th percentile latency should be less than 500ms

**Measurement**:
```promql
histogram_quantile(0.95, rate(api_gateway_request_duration_seconds_bucket[5m])) < 0.5
```

**Error Budget**: 5% of requests can exceed 500ms latency
- Monthly error budget (30 days): ~108,000 seconds of degraded performance
- Daily error budget: ~3,600 seconds

**Alert**: Triggered if p95 > 500ms for 5 consecutive minutes

**Actions**:
1. Check HPA status - are pods scaling correctly?
2. Review LLM service latency - is external API slow?
3. Check resource utilization - CPU/memory constraints?
4. Review recent deployments - did a change cause this?

---

### 2. Error Rate SLO

**Objective**: Error rate should be less than 1%

**Measurement**:
```promql
(
  sum(rate(api_gateway_requests_total{status=~"5.."}[5m]))
  /
  sum(rate(api_gateway_requests_total[5m]))
) * 100 < 1
```

**Error Budget**: 1% of requests can fail
- If 1M requests/month: 10,000 failed requests allowed
- If 100K requests/day: ~1,000 failed requests allowed

**Alert**: Triggered if error rate > 1% for 5 consecutive minutes

**Actions**:
1. Check error logs - what's causing failures?
2. Verify LLM service connectivity - network issues?
3. Check API key validity - authentication problems?
4. Review rate limiting - are we hitting external API limits?

---

### 3. Availability SLO

**Objective**: Service availability should be greater than 99.9%

**Measurement**:
```promql
(
  1 - (
    sum(rate(api_gateway_requests_total{status=~"5.."}[5m]))
    /
    sum(rate(api_gateway_requests_total[5m]))
  )
) * 100 > 99.9
```

**Downtime Budget**: 0.1% downtime allowed
- Monthly (30 days): ~43.2 minutes
- Daily: ~86.4 seconds
- Weekly: ~10.08 minutes

**Alert**: Triggered if any service is down for > 1 minute

**Actions**:
1. Check pod status - are pods running?
2. Review deployment status - rollout issues?
3. Check node health - infrastructure problems?
4. Verify service discovery - DNS issues?

---

## Service Level Indicators (SLI)

### Primary SLIs

1. **Request Latency**
   - p50: Median response time
   - p95: 95th percentile (SLO target)
   - p99: 99th percentile
   - Max: Maximum latency observed

2. **Error Rate**
   - 4xx errors: Client errors
   - 5xx errors: Server errors (counted in SLO)
   - Total errors: All failed requests

3. **Request Volume**
   - Requests per second (RPS)
   - Requests per minute (RPM)
   - Total requests

4. **Availability**
   - Uptime percentage
   - Pod availability
   - Service health status

### Secondary SLIs

1. **Token Usage**
   - Prompt tokens per request
   - Completion tokens per request
   - Total tokens per request
   - Tokens per second

2. **Cost Metrics**
   - Cost per request
   - Cost per 1K requests
   - Daily/monthly cost estimates

3. **Resource Utilization**
   - CPU usage percentage
   - Memory usage percentage
   - Network bandwidth

4. **HPA Metrics**
   - Current replica count
   - Desired replica count
   - Scaling events

---

## Monitoring & Alerting

### Alert Severity Levels

**Critical** (Immediate action required):
- Service completely down
- Error rate > 5%
- p95 latency > 2 seconds
- Multiple pods down

**Warning** (Action required within hours):
- Error rate 1-5%
- p95 latency 500ms-2s
- High resource utilization (> 85%)
- Single pod down

**Info** (Informational, no immediate action):
- High token usage
- Cost anomalies
- Scaling events

### Alert Response Playbook

#### High Latency Alert

1. **Immediate Actions** (0-5 minutes):
   - Check Grafana dashboard for latency trends
   - Verify HPA is scaling appropriately
   - Check LLM service latency

2. **Investigation** (5-15 minutes):
   - Review pod resource utilization
   - Check for memory leaks or CPU spikes
   - Examine recent code deployments
   - Review external API status (OpenAI/Claude)

3. **Remediation**:
   - Scale up pods manually if HPA is slow
   - Increase resource limits if constrained
   - Rollback recent deployment if problematic
   - Implement request queuing if needed

#### High Error Rate Alert

1. **Immediate Actions** (0-5 minutes):
   - Check error logs for patterns
   - Verify service connectivity
   - Check API key validity

2. **Investigation** (5-15 minutes):
   - Identify error types (4xx vs 5xx)
   - Check external API rate limits
   - Review network policies
   - Examine authentication issues

3. **Remediation**:
   - Fix API key issues if authentication errors
   - Implement retry logic if transient failures
   - Scale up if rate limited
   - Rollback if deployment caused errors

#### Service Down Alert

1. **Immediate Actions** (0-2 minutes):
   - Check pod status: `kubectl get pods -n ai-services`
   - Check recent events: `kubectl get events -n ai-services`
   - Verify node health

2. **Investigation** (2-10 minutes):
   - Check pod logs: `kubectl logs <pod> -n ai-services`
   - Review recent changes (GitOps, manual)
   - Check resource quotas

3. **Remediation**:
   - Restart failed pods if OOMKilled
   - Scale deployment if insufficient replicas
   - Fix configuration if CrashLoopBackOff
   - Rollback deployment if problematic

---

## Dashboard Recommendations

### 1. Executive Dashboard
**Audience**: Leadership, product managers
**Metrics**:
- Service availability (SLO compliance)
- Request volume trends
- Error rate
- Cost per 1K requests

**Refresh**: 1 minute

### 2. Operations Dashboard
**Audience**: SRE, DevOps engineers
**Metrics**:
- Real-time latency (p50, p95, p99)
- Error rate by status code
- Active alerts
- Pod resource utilization
- HPA status and scaling events

**Refresh**: 10 seconds

### 3. Cost Optimization Dashboard
**Audience**: FinOps, engineering managers
**Metrics**:
- Token usage trends
- Cost per request
- Cost by model
- Resource efficiency (requests per CPU)

**Refresh**: 5 minutes

---

## Performance Optimization

### Latency Optimization

1. **Application Level**:
   - Optimize prompt engineering (shorter prompts)
   - Use streaming responses where possible
   - Implement request batching
   - Add response caching

2. **Infrastructure Level**:
   - Right-size pod resources
   - Use faster instance types
   - Optimize network paths
   - Implement connection pooling

3. **External API**:
   - Choose faster models when appropriate
   - Implement circuit breakers
   - Use multiple API providers
   - Negotiate dedicated capacity

### Cost Optimization

1. **Token Efficiency**:
   - Optimize prompts to reduce token usage
   - Use cheaper models for simple tasks
   - Implement prompt templates
   - Cache common responses

2. **Resource Efficiency**:
   - Right-size pod requests/limits
   - Use spot instances for non-critical workloads
   - Implement request queuing to reduce idle time
   - Scale to zero during off-hours (if applicable)

3. **Rate Limiting**:
   - Implement per-user rate limits
   - Prioritize high-value requests
   - Use tiered service levels

---

## Capacity Planning

### Growth Projections

**Current Baseline** (Example):
- 1,000 requests/day
- Average 500 tokens/request
- 2 API Gateway pods, 2 LLM Inference pods

**6-Month Projection**:
- 10,000 requests/day (10x growth)
- Required pods: 6-8 API Gateway, 6-8 LLM Inference
- Estimated cost increase: 8-10x

**Planning Actions**:
1. Monitor growth trends weekly
2. Pre-provision capacity for known events
3. Test autoscaling behavior under load
4. Negotiate volume discounts with LLM providers

### Load Testing

**Recommended Tests**:
1. **Baseline Load Test**: Normal traffic patterns (1x current load)
2. **Peak Load Test**: Expected peak traffic (3x baseline)
3. **Stress Test**: Breaking point (10x baseline)
4. **Soak Test**: Sustained load for 24 hours

**Tools**: k6, Locust, JMeter

---

## Incident Response

### Incident Severity Definitions

**SEV1 - Critical**:
- Complete service outage
- Data loss
- Security breach
- SLO breach > 50%

**SEV2 - High**:
- Partial service degradation
- SLO breach < 50%
- Single region outage

**SEV3 - Medium**:
- Minor service degradation
- SLI trending towards SLO breach
- Non-critical component failure

**SEV4 - Low**:
- Informational
- Monitoring alert
- Potential future issue

### Post-Incident Review

**Required for**: SEV1 and SEV2 incidents

**Template**:
1. Incident timeline
2. Root cause analysis
3. Impact assessment
4. Resolution steps
5. Action items to prevent recurrence
6. SLO impact calculation

---

## Continuous Improvement

### Monthly SRE Review

**Agenda**:
1. SLO compliance review
2. Error budget consumption
3. Incident retrospectives
4. Performance trends
5. Cost analysis
6. Capacity planning updates

**Actionable Outputs**:
- SLO adjustments (if needed)
- Infrastructure improvements
- Runbook updates
- Monitoring enhancements
