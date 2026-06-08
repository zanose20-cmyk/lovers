$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  Firebase Setup - Lovers App" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login
Write-Host "[1/6] Firebase Login" -ForegroundColor Yellow
Write-Host "  Browser will open. Sign in with your Google account." -ForegroundColor White
firebase login
if ($LASTEXITCODE -ne 0) {
  Write-Host "  Login failed!" -ForegroundColor Red
  exit 1
}
Write-Host "  Logged in!" -ForegroundColor Green

# Step 2: Create project
Write-Host ""
Write-Host "[2/6] Creating Firebase project..." -ForegroundColor Yellow
firebase projects:create lovers-app --name "Lovers App" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "  Project may already exist, continuing..." -ForegroundColor Yellow
}
firebase use lovers-app

# Step 3: Add Android app + SHA1
Write-Host ""
Write-Host "[3/6] Adding Android app + SHA1..." -ForegroundColor Yellow
firebase apps:create android com.example.lovers_app --display-name "Lovers Android" 2>$null

# Add SHA1 fingerprint
Write-Host "  Adding SHA1 fingerprint..." -ForegroundColor White
firebase apps:addhash android com.example.lovers_app --sha1 "F4:89:D5:8A:56:4F:50:6F:F0:D6:38:73:B8:BF:34:2C:6E:81:86:91" --sha256 "43:AB:2F:2A:C7:22:21:1E:3C:9D:6A:41:7D:5D:51:CF:4C:F0:04:22:CA:6C:EE:2E:C3:E5:1A:A7:F8:7C:F5:D8" 2>$null

# Download google-services.json
Write-Host "  Downloading google-services.json..." -ForegroundColor White
firebase apps:sdkconfig android --out "../flutter/android/app/google-services.json" 2>$null
if (Test-Path "../flutter/android/app/google-services.json") {
  Write-Host "  google-services.json saved!" -ForegroundColor Green
} else {
  Write-Host "  Download manually: Console > Project Settings > Android > google-services.json" -ForegroundColor Yellow
  Write-Host "  Save to: flutter/android/app/google-services.json" -ForegroundColor Yellow
}

# Step 4: Add iOS app
Write-Host ""
Write-Host "[4/6] Adding iOS app..." -ForegroundColor Yellow
firebase apps:create ios com.example.loversApp --display-name "Lovers iOS" 2>$null
firebase apps:sdkconfig ios --out "../flutter/ios/Runner/GoogleService-Info.plist" 2>$null
if (Test-Path "../flutter/ios/Runner/GoogleService-Info.plist") {
  Write-Host "  GoogleService-Info.plist saved!" -ForegroundColor Green
} else {
  Write-Host "  Download manually: Console > Project Settings > iOS > GoogleService-Info.plist" -ForegroundColor Yellow
}

# Step 5: Service account key
Write-Host ""
Write-Host "[5/6] Generating service account key..." -ForegroundColor Yellow
Write-Host "  Go to: https://console.firebase.google.com/project/lovers-app/settings/serviceaccounts/adminsdk" -ForegroundColor White
Write-Host "  Click 'Generate new private key'" -ForegroundColor White
Write-Host "  Save the JSON file to: D:\Lovers\backend\serviceAccountKey.json" -ForegroundColor White
Read-Host "  Press Enter after saving the key"

if (Test-Path "serviceAccountKey.json") {
  $key = Get-Content "serviceAccountKey.json" | ConvertFrom-Json
  $projectId = $key.project_id
  $clientEmail = $key.client_email
  $privateKey = $key.private_key
  
  # Update .env
  $env = Get-Content ".env" -Raw
  $env = $env -replace "# FIREBASE_PROJECT_ID=.*", "FIREBASE_PROJECT_ID=$projectId"
  $env = $env -replace "# FIREBASE_CLIENT_EMAIL=.*", "FIREBASE_CLIENT_EMAIL=$clientEmail"
  $env = $env -replace "# FIREBASE_PRIVATE_KEY=.*", "FIREBASE_PRIVATE_KEY=$privateKey"
  $env = $env -replace "# FIREBASE_SERVICE_ACCOUNT_JSON_PATH=.*", "FIREBASE_SERVICE_ACCOUNT_JSON_PATH=./serviceAccountKey.json"
  Set-Content ".env" $env -NoNewline
  Write-Host "  .env updated!" -ForegroundColor Green
} else {
  Write-Host "  serviceAccountKey.json not found, update .env manually" -ForegroundColor Yellow
}

# Step 6: Enable Phone Auth
Write-Host ""
Write-Host "[6/6] Enable Phone Authentication" -ForegroundColor Yellow
Write-Host "  Go to: https://console.firebase.google.com/project/lovers-app/authentication/providers" -ForegroundColor White
Write-Host "  Click 'Phone' > Enable > Save" -ForegroundColor White
Read-Host "  Press Enter after enabling Phone Auth"

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "  Firebase Setup Complete!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Restart backend:  node src/server.js" -ForegroundColor White
Write-Host "  Rebuild APK:      flutter build apk --debug" -ForegroundColor White
Write-Host "  Test:             Guest login or Phone Auth" -ForegroundColor White
Write-Host ""
