
# Makefile for AI Platform Infrastructure

.PHONY: help setup deploy status clean validate build push

help: ## Show this help
	@echo "AI Platform Infrastructure Management"
	@echo "======================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Setup local kind cluster
	chmod +x scripts/setup-local.sh
	./scripts/setup-local.sh

deploy: ## Deploy all manifests to the current cluster
	kubectl apply -f kubernetes/base/namespaces.yaml
	kubectl apply -f kubernetes/platform/
	kubectl apply -f kubernetes/security/network-policies.yaml
	# Warning: You must create secrets manually
	kubectl apply -f kubernetes/ai-services/
	kubectl apply -f kubernetes/observability/

status: ## Check the status of the platform
	@echo ">>> Pods"
	kubectl get pods -A | grep -E 'ai-services|observability|platform'
	@echo "\n>>> Services"
	kubectl get svc -A | grep -E 'ai-services|observability|platform'
	@echo "\n>>> Ingress"
	kubectl get ingress -A

clean: ## Delete local kind cluster
	kind delete cluster --name ai-platform-local

validate: ## Validate Kubernetes manifests with dry-run
	find kubernetes -name '*.yaml' | xargs -I {} kubectl apply --dry-run=client -f {}

build: ## Build docker images
	docker build -t ghcr.io/vlamay/api-gateway:latest apps/api-gateway/
	docker build -t ghcr.io/vlamay/llm-inference:latest apps/llm-inference/

push: ## Push docker images
	docker push ghcr.io/vlamay/api-gateway:latest
	docker push ghcr.io/vlamay/llm-inference:latest

port-forward-api: ## Port forward API Gateway
	kubectl port-forward -n ai-services svc/api-gateway 8000:80

port-forward-prometheus: ## Port forward Prometheus
	kubectl port-forward -n observability svc/prometheus 9090:9090

logs-api: ## Tail API Gateway logs
	kubectl logs -n ai-services -l app=api-gateway -f

logs-llm: ## Tail LLM Inference logs
	kubectl logs -n ai-services -l app=llm-inference -f

scale-up: ## Scale services to 5 replicas
	kubectl scale deployment -n ai-services api-gateway --replicas=5
	kubectl scale deployment -n ai-services llm-inference --replicas=5

scale-down: ## Scale services to 2 replicas
	kubectl scale deployment -n ai-services api-gateway --replicas=2
	kubectl scale deployment -n ai-services llm-inference --replicas=2
