# Docker Images - Alternative Deployment Options

## Current Situation
- ✅ EKS cluster is being created (~11-16 minutes remaining)
- ❌ Docker is not installed on Windows machine
- ✅ GitHub token created with full permissions
- ✅ NAS server available at 192.168.1.173

## Option 1: Install Docker Desktop (Recommended)

**Pros**: Full control, can build and test locally
**Cons**: Requires installation and restart
**Time**: 15-20 minutes

### Steps:
1. Download: https://www.docker.com/products/docker-desktop
2. Install Docker Desktop
3. Restart computer
4. Build images:
   ```powershell
   docker build -t ghcr.io/vlamay/api-gateway:v1.0.0 apps/api-gateway/
   docker build -t ghcr.io/vlamay/llm-inference:v1.0.0 apps/llm-inference/
   ```
5. Login and push:
   ```powershell
   echo $GITHUB_TOKEN | docker login ghcr.io -u vlamay --password-stdin
   docker push ghcr.io/vlamay/api-gateway:v1.0.0
   docker push ghcr.io/vlamay/llm-inference:v1.0.0
   ```

## Option 2: Build on NAS Server (Fastest)

**Pros**: No installation needed, Docker likely already there
**Cons**: Need SSH access
**Time**: 5-10 minutes

### Steps:
```bash
# SSH to NAS
ssh Vladyslav@192.168.1.173

# Copy project (if not already there)
# Then build
cd ~/ai-platform-infra
docker build -t ghcr.io/vlamay/api-gateway:v1.0.0 apps/api-gateway/
docker build -t ghcr.io/vlamay/llm-inference:v1.0.0 apps/llm-inference/

# Login to GitHub Container Registry
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u vlamay --password-stdin

# Push images
docker push ghcr.io/vlamay/api-gateway:v1.0.0
docker push ghcr.io/vlamay/llm-inference:v1.0.0
```

## Option 3: Use AWS ECR (Cloud-Native)

**Pros**: Integrated with AWS, no local Docker needed
**Cons**: More complex setup
**Time**: 10-15 minutes

### Steps:
1. Create ECR repositories
2. Use AWS CodeBuild to build images from GitHub
3. Update Kubernetes manifests to use ECR URLs

## Option 4: Deploy with Test Images First

**Pros**: Can test infrastructure immediately
**Cons**: Not real application
**Time**: 2 minutes

### Steps:
Update manifests to use simple nginx images temporarily:
```yaml
image: nginx:alpine
```

Test infrastructure, then update with real images later.

## Recommendation

**Best approach**: Option 2 (Build on NAS)
- Fastest
- No installation needed
- Docker likely already available
- Can proceed immediately

**Alternative**: Option 1 (Install Docker Desktop)
- If you want local development capability
- More time but better for future work
