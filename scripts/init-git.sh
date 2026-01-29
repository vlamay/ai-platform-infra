#!/bin/bash

# scripts/init-git.sh
# Script to initialize the git repository and push to GitHub

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEFAULT_REPO="git@github.com:vlamay/ai-platform-infra.git"

echo -e "${BLUE}🤖 Initializing Git Repository...${NC}"

# Go to project root (assuming script is in scripts/)
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)
echo -e "${BLUE}Project root: ${PROJECT_ROOT}${NC}"

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    exit 1
fi

# Initialize git if not already
if [ -d ".git" ]; then
    echo -e "${YELLOW}Git repository already initialized.${NC}"
else
    echo -e "${BLUE}Running git init...${NC}"
    git init
    echo -e "${GREEN}Initialized empty Git repository${NC}"
fi

# Add files
echo -e "${BLUE}Adding files...${NC}"
git add .
# Unstage sensitive files just in case (though .gitignore should handle it)
# git reset -- kubernetes/security/secret-example.yaml # (Example if needed, but it IS using .gitignore)

# Show status
git status

# Commit
echo -e "${BLUE}Creating initial commit...${NC}"
COMMIT_MSG="Initial commit: Production-ready AI Platform Infrastructure

- Complete Kubernetes manifests for AI services
- FastAPI gateway and LLM inference service
- Prometheus monitoring and alerting
- Comprehensive documentation and SRE practices
- Autoscaling with HPA
- Security hardening with NetworkPolicies and Pod Security
- CI/CD pipeline with GitHub Actions"

# Check if there are changes to commit
if git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}No changes to commit (or already committed).${NC}"
else
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}Committed changes.${NC}"
fi

# Rename branch to main
git branch -M main

# Configure Remote
echo -e "${BLUE}Configuring remote...${NC}"
read -p "Enter remote URL [${DEFAULT_REPO}]: " REMOTE_URL
REMOTE_URL=${REMOTE_URL:-$DEFAULT_REPO}

if git remote | grep -q "origin"; then
    echo -e "${YELLOW}Remote 'origin' already exists. Updating URL...${NC}"
    git remote set-url origin "$REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
fi

echo -e "${GREEN}Remote set to: $REMOTE_URL${NC}"

# Push
echo -e "${BLUE}Ready to push to origin/main? (y/n)${NC}"
read -r CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Pushing...${NC}"
    if git push -u origin main; then
        echo -e "${GREEN}✅ Successfully pushed to GitHub!${NC}"
    else
        echo -e "${RED}Push failed. Please check your SSH keys or permissions.${NC}"
        echo -e "${YELLOW}You can try pushing manually: git push -u origin main${NC}"
    fi
else
    echo -e "${YELLOW}Push skipped. You can push later with: git push -u origin main${NC}"
fi

echo -e "${GREEN}Git setup complete!${NC}"
