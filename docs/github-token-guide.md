# GitHub Personal Access Token - Creation Guide

## Quick Steps

1. **Go to**: https://github.com/settings/tokens/new

2. **Fill in the form**:
   - **Note**: `AI Platform - Container Registry`
   - **Expiration**: 90 days (or your preference)
   - **Select scopes**: 
     - ✅ `write:packages` - Upload packages to GitHub Package Registry
     - ✅ `read:packages` - Download packages from GitHub Package Registry
     - ✅ `delete:packages` - Delete packages from GitHub Package Registry

3. **Click**: "Generate token"

4. **IMPORTANT**: Copy the token immediately! It will only be shown once.
   - Token format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

5. **Save securely**: Store in password manager or safe location

## After Creating Token

Use the token to login to GitHub Container Registry:

```powershell
# Set token as environment variable
$env:GITHUB_TOKEN = "ghp_your_token_here"

# Login to GitHub Container Registry
echo $env:GITHUB_TOKEN | docker login ghcr.io -u vlamay --password-stdin
```

## What We'll Do Next

Once you have the token:

1. **Build Docker images**:
   ```powershell
   docker build -t ghcr.io/vlamay/api-gateway:v1.0.0 apps/api-gateway/
   docker build -t ghcr.io/vlamay/llm-inference:v1.0.0 apps/llm-inference/
   ```

2. **Push to registry**:
   ```powershell
   docker push ghcr.io/vlamay/api-gateway:v1.0.0
   docker push ghcr.io/vlamay/llm-inference:v1.0.0
   ```

3. **Make images public** (so EKS can pull them):
   - Go to https://github.com/vlamay?tab=packages
   - For each package: Settings → Change visibility → Public

## Alternative: Skip Registry (Use Local Build)

If you prefer not to use GitHub Container Registry, we can:
1. Build images locally
2. Push to AWS ECR (Elastic Container Registry) instead
3. Update manifests to use ECR URLs

Let me know which approach you prefer!
