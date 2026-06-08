#!/bin/bash
# Firebase Setup Script for Lovers App
# Run: bash scripts/setup-firebase.sh

set -e

echo ""
echo "==================================="
echo "  Firebase Setup - Lovers App"
echo "==================================="
echo ""

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
  echo "Installing Firebase CLI..."
  npm install -g firebase-tools
fi

echo "Firebase CLI version: $(firebase --version)"
echo ""

# Step 1: Login
echo "[Step 1] Login to Firebase"
echo "  This will open your browser for Google authentication."
echo "  Sign in with your Google account."
echo ""
read -p "  Press Enter to continue..."
firebase login

# Step 2: Create project
echo ""
echo "[Step 2] Create Firebase Project"
echo "  Project ID will be: lovers-app"
echo ""

# Check if project exists
if firebase projects:list 2>/dev/null | grep -q "lovers-app"; then
  echo "  Project 'lovers-app' already exists"
else
  echo "  Creating project 'lovers-app'..."
  firebase projects:create lovers-app --name "Lovers App" || echo "  (Project creation may require manual setup in console.firebase.google.com)"
fi

# Step 3: Select project
echo ""
echo "[Step 3] Select project"
firebase use lovers-app 2>/dev/null || echo "  (Set project manually)"

# Step 4: Add Android app
echo ""
echo "[Step 4] Add Android app"
echo "  Package name: com.example.lovers_app"
firebase apps:create android com.example.lovers_app --display-name "Lovers Android" 2>/dev/null || echo "  (Android app may already exist)"

# Step 5: Download google-services.json
echo ""
echo "[Step 5] Download google-services.json"
ANDROID_APP_ID=$(firebase apps:list android 2>/dev/null | grep "com.example.lovers_app" | awk '{print $1}' | head -1)
if [ -n "$ANDROID_APP_ID" ]; then
  firebase apps:sdkconfig android "$ANDROID_APP_ID" --out ../flutter/android/app/google-services.json
  echo "  ✅ google-services.json saved"
else
  echo "  ⚠️  Please download google-services.json manually from Firebase Console"
  echo "  Console → Project Settings → Android app → Download google-services.json"
fi

# Step 6: Add iOS app
echo ""
echo "[Step 6] Add iOS app"
firebase apps:create ios com.example.loversApp --display-name "Lovers iOS" 2>/dev/null || echo "  (iOS app may already exist)"

# Step 7: Generate service account key
echo ""
echo "[Step 7] Generate service account key for backend"
firebase iam:createServiceAccount --accountId lovers-backend --display-name "Lovers Backend" 2>/dev/null || echo "  (Service account may exist)"
firebase iam:createKey lovers-backend --key-name "backend-key" --key-file ./serviceAccountKey.json 2>/dev/null || echo "  ⚠️  Please generate service account key manually:"
echo "  Console → Project Settings → Service accounts → Generate new private key"

# Step 8: Update .env
echo ""
echo "[Step 8] Update .env"
if [ -f "./serviceAccountKey.json" ]; then
  PROJECT_ID=$(cat ./serviceAccountKey.json | grep -o '"project_id": "[^"]*"' | cut -d'"' -f4)
  CLIENT_EMAIL=$(cat ./serviceAccountKey.json | grep -o '"client_email": "[^"]*"' | cut -d'"' -f4)
  PRIVATE_KEY=$(cat ./serviceAccountKey.json | grep -o '"private_key": "[^"]*"' | cut -d'"' -f4)
  
  sed -i "s|# FIREBASE_PROJECT_ID=.*|FIREBASE_PROJECT_ID=$PROJECT_ID|" .env
  sed -i "s|# FIREBASE_CLIENT_EMAIL=.*|FIREBASE_CLIENT_EMAIL=$CLIENT_EMAIL|" .env
  sed -i "s|# FIREBASE_PRIVATE_KEY=.*|FIREBASE_PRIVATE_KEY=$PRIVATE_KEY|" .env
  sed -i "s|# FIREBASE_SERVICE_ACCOUNT_JSON_PATH=.*|FIREBASE_SERVICE_ACCOUNT_JSON_PATH=./serviceAccountKey.json|" .env
  echo "  ✅ .env updated"
else
  echo "  ⚠️  Add these to .env manually:"
  echo "  FIREBASE_PROJECT_ID=your-project-id"
  echo "  FIREBASE_CLIENT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com"
  echo "  FIREBASE_PRIVATE_KEY=\"-----BEGIN PRIVATE KEY-----\n...\""
  echo "  FIREBASE_SERVICE_ACCOUNT_JSON_PATH=./serviceAccountKey.json"
fi

# Step 9: Enable Phone Auth
echo ""
echo "[Step 9] Enable Phone Authentication"
echo "  Please enable Phone Auth manually:"
echo "  Console → Authentication → Sign-in method → Phone → Enable"

echo ""
echo "==================================="
echo "  Setup Complete!"
echo "==================================="
echo ""
echo "  Next steps:"
echo "  1. Enable Phone Auth in Firebase Console"
echo "  2. Restart backend: node src/server.js"
echo "  3. Rebuild Flutter: flutter build apk --debug"
echo ""
