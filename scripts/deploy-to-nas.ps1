# AI Platform Infrastructure - NAS Deployment (PowerShell)
# Run from: z:\Проекты\ai-platform-infra\scripts

$SERVER = "Vladyslav@192.168.1.173"
$PROJECT_DIR = "z:\Проекты\ai-platform-infra"

Write-Host "🚀 AI Platform Infrastructure - NAS Deployment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Test SSH connection
Write-Host "📡 Testing SSH connection to $SERVER..." -ForegroundColor Yellow
try {
    ssh -o ConnectTimeout=5 $SERVER "exit" 2>$null
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host "✅ SSH connection successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot connect to server" -ForegroundColor Red
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. Server is running"
    Write-Host "  2. SSH is enabled"
    Write-Host "  3. You can connect manually: ssh $SERVER"
    exit 1
}
Write-Host ""

# Copy project using SCP
Write-Host "📦 Copying project files to server..." -ForegroundColor Yellow
scp -r "$PROJECT_DIR" "${SERVER}:~/"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Files copied successfully" -ForegroundColor Green
} else {
    Write-Host "❌ File copy failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Run deployment script on server
Write-Host "🔧 Running deployment on server..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes..." -ForegroundColor Gray
Write-Host ""

ssh $SERVER @"
cd ~/ai-platform-infra
chmod +x scripts/deploy-to-nas.sh
./scripts/deploy-to-nas.sh
"@

Write-Host ""
Write-Host "✨ Deployment initiated!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Configure OpenAI API key on server"
Write-Host "   2. Add to Windows hosts file: 192.168.1.173 ai-gateway.local"
Write-Host "   3. Test: curl http://ai-gateway.local/healthz"
Write-Host ""
