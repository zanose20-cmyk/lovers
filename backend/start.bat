@echo off
echo ===================================
echo   Lovers App - Dev Startup
echo ===================================

:: Check MongoDB
echo [1/4] Checking MongoDB...
netstat -ano | findstr "27017" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   Starting MongoDB...
    start "" "%TEMP%\mongodb-portable\mongodb-win32-x86_64-windows-8.0.12\bin\mongod.exe" --dbpath "C:\data\db" --port 27017
    timeout /t 5 >nul
) else (
    echo   MongoDB already running
)

:: Seed data (if empty)
echo [2/4] Seeding data...
cd /d "%~dp0"
node -e "const m=require('mongoose');m.connect('mongodb://localhost:27017/lovers').then(async()=>{const c=await m.connection.db.collection('gifts').countDocuments();if(c===0){console.log('Empty DB, seeding...');await m.disconnect();process.exit(1)}else{console.log('Data exists ('+c+' gifts)');process.exit(0)}})" 2>nul
if %ERRORLEVEL% neq 0 (
    node src/scripts/seedData.js
    node src/scripts/seedVIP.js
    node src/scripts/seedDailyTasks.js
)

:: Start server
echo [3/4] Starting backend server...
set NODE_ENV=development
start "" node src/server.js
timeout /t 3 >nul

:: Verify
echo [4/4] Verifying...
curl -s http://localhost:3000/health >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo.
    echo ===================================
    echo   Server running!
    echo   API:   http://localhost:3000
    echo   Admin: http://localhost:3000/admin
    echo   Health: http://localhost:3000/health
    echo ===================================
) else (
    echo   Server may still be starting, wait a moment...
)
pause
