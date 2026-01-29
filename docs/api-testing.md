# API Testing Examples

Collection of example API requests for testing the AI Platform.

## Prerequisites

- AI Platform is deployed and running
- `/etc/hosts` entry for `ai-gateway.local` is configured
- OpenAI API key is set in Kubernetes secret

## Basic Chat Request

```bash
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is Kubernetes?",
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

## Short Response (Cost Optimization)

```bash
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain Docker in one sentence.",
    "max_tokens": 30,
    "temperature": 0.5
  }'
```

## Creative Response (Higher Temperature)

```bash
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Write a haiku about cloud computing.",
    "max_tokens": 50,
    "temperature": 0.9
  }'
```

## Technical Question

```bash
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain the difference between HPA and VPA in Kubernetes.",
    "max_tokens": 200,
    "temperature": 0.3
  }'
```

## Different Model (GPT-4)

```bash
curl -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What are the best practices for Kubernetes security?",
    "max_tokens": 300,
    "temperature": 0.7,
    "model": "gpt-4"
  }'
```

## Health Check

```bash
curl http://ai-gateway.local/healthz
```

## Metrics Endpoint

```bash
curl http://ai-gateway.local/metrics
```

## Root Endpoint

```bash
curl http://ai-gateway.local/
```

## Load Testing

### Install hey (HTTP load generator)

```bash
# macOS
brew install hey

# Linux
go install github.com/rakyll/hey@latest

# Or download binary from: https://github.com/rakyll/hey
```

### Light Load (10 concurrent requests for 30 seconds)

```bash
hey -z 30s -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Test","max_tokens":10}' \
  http://ai-gateway.local/v1/chat
```

### Medium Load (50 concurrent requests for 60 seconds)

```bash
hey -z 60s -c 50 -m POST \
  -H "Content-Type: application/json" \
  -d '{"prompt":"What is AI?","max_tokens":50}' \
  http://ai-gateway.local/v1/chat
```

### Heavy Load (100 concurrent requests)

```bash
hey -z 120s -c 100 -m POST \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Explain machine learning","max_tokens":100}' \
  http://ai-gateway.local/v1/chat
```

## Using Python

```python
import requests
import json

url = "http://ai-gateway.local/v1/chat"
headers = {"Content-Type": "application/json"}
payload = {
    "prompt": "What are microservices?",
    "max_tokens": 150,
    "temperature": 0.7
}

response = requests.post(url, headers=headers, data=json.dumps(payload))
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")
```

## Using JavaScript (Node.js)

```javascript
const axios = require('axios');

async function testAPI() {
  try {
    const response = await axios.post('http://ai-gateway.local/v1/chat', {
      prompt: 'What is DevOps?',
      max_tokens: 100,
      temperature: 0.7
    }, {
      headers: {'Content-Type': 'application/json'}
    });
    
    console.log('Status:', response.status);
    console.log('Response:', response.data);
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testAPI();
```

## Monitoring Requests

### Watch logs in real-time

```bash
# API Gateway logs
kubectl logs -n ai-services -l app=api-gateway --tail=100 -f

# LLM Inference logs
kubectl logs -n ai-services -l app=llm-inference --tail=100 -f
```

### Check metrics

```bash
# Port-forward Prometheus
kubectl port-forward -n observability svc/prometheus 9090:9090

# In browser, go to http://localhost:9090 and run queries:
# - rate(api_gateway_requests_total[5m])
# - histogram_quantile(0.95, rate(api_gateway_request_duration_seconds_bucket[5m]))
# - sum(rate(llm_tokens_total[5m])) by (type)
```

## Expected Response Format

```json
{
  "response": "Kubernetes is an open-source container orchestration platform...",
  "tokens_used": 45,
  "latency_ms": 523.4,
  "model": "gpt-3.5-turbo"
}
```

## Error Responses

### Invalid API Key

```json
{
  "detail": "Invalid API key"
}
```

### Rate Limit Exceeded

```json
{
  "detail": "Rate limit exceeded"
}
```

### Service Unavailable

```json
{
  "detail": "LLM service unavailable"
}
```

## Performance Testing Script

Save as `test-api.sh`:

```bash
#!/bin/bash

echo "Testing AI Platform API..."
echo ""

# Test 1: Health check
echo "Test 1: Health check"
curl -s http://ai-gateway.local/healthz | jq .
echo ""

# Test 2: Simple chat
echo "Test 2: Simple chat request"
curl -s -X POST http://ai-gateway.local/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Hello","max_tokens":20}' | jq .
echo ""

# Test 3: Metrics
echo "Test 3: Check metrics endpoint"
curl -s http://ai-gateway.local/metrics | grep "api_gateway_requests_total" | head -5
echo ""

echo "Tests complete!"
```

Make it executable:

```bash
chmod +x test-api.sh
./test-api.sh
```

## Benchmarking

```bash
# Benchmark with Apache Bench (if available)
ab -n 100 -c 10 -p payload.json -T application/json \
  http://ai-gateway.local/v1/chat

# Benchmark with wrk (if available)
wrk -t4 -c10 -d30s --latency \
  -s post.lua \
  http://ai-gateway.local/v1/chat
```

## Tips

1. **Start small**: Begin with low concurrency and short duration
2. **Monitor resources**: Watch CPU/memory with `kubectl top pods -n ai-services`
3. **Check HPA**: Observe autoscaling with `kubectl get hpa -n ai-services -w`
4. **Review costs**: Monitor token usage in Prometheus metrics
5. **Analyze latency**: Check p95/p99 latencies during different load levels
