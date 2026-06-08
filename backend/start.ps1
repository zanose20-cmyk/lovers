$ErrorActionPreference = "SilentlyContinue"
Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  Lovers App - Dev Startup" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# 1. MongoDB
Write-Host "[1/4] MongoDB..." -ForegroundColor Yellow
$listening = netstat -ano | Select-String "27017.*LISTENING"
if ($listening) {
    Write-Host "  Already running" -ForegroundColor Green
} else {
    Write-Host "  Starting..." -ForegroundColor Yellow
    $dataDir = "C:\data\db"
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    Start-Process -FilePath "$env:TEMP\mongodb-portable\mongodb-win32-x86_64-windows-8.0.12\bin\mongod.exe" -ArgumentList "--dbpath $dataDir --port 27017" -WindowStyle Hidden
    Start-Sleep 4
    $listening = netstat -ano | Select-String "27017.*LISTENING"
    if ($listening) { Write-Host "  Started OK" -ForegroundColor Green }
    else { Write-Host "  Failed to start" -ForegroundColor Red }
}

# 2. Seed
Write-Host "[2/4] Seed data..." -ForegroundColor Yellow
$guest = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/guest" -Method POST -ContentType "application/json" -Body '{}' -ErrorAction SilentlyContinue
if (-not $guest) {
    # Server not running yet, check DB directly
    Write-Host "  Seeding..." -ForegroundColor Yellow
    Push-Location "$PSScriptRoot"
    node src/scripts/seedData.js 2>$null
    node src/scripts/seedVIP.js 2>$null
    node src/scripts/seedDailyTasks.js 2>$null
    Pop-Location
} else {
    Write-Host "  Data exists" -ForegroundColor Green
}

# 3. Backend
Write-Host "[3/4] Backend server..." -ForegroundColor Yellow
$health = Invoke-RestMethod -Uri "http://localhost:3000/health" -ErrorAction SilentlyContinue
if ($health.ok -eq $true) {
    Write-Host "  Already running" -ForegroundColor Green
} else {
    Push-Location "$PSScriptRoot"
    Start-Process -FilePath "node" -ArgumentList "src/server.js" -WindowStyle Hidden
    Pop-Location
    Start-Sleep 4
}

# 4. Verify
Write-Host "[4/4] Verify..." -ForegroundColor Yellow
$health = Invoke-RestMethod -Uri "http://localhost:3000/health" -ErrorAction SilentlyContinue
if ($health.ok -eq $true) {
    Write-Host ""
    Write-Host "===================================" -ForegroundColor Green
    Write-Host "  Server running!" -ForegroundColor Green
    Write-Host "  API:    http://localhost:3000" -ForegroundColor White
    Write-Host "  Admin:  http://localhost:3000/admin" -ForegroundColor White
    Write-Host "  Health: http://localhost:3000/health" -ForegroundColor White
    Write-Host "===================================" -ForegroundColor Green
} else {
    Write-Host "  Server may still be starting..." -ForegroundColor Yellow
}
