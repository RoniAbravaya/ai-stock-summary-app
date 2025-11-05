@echo off
echo ========================================
echo  PUSHING TO MAIN
echo ========================================
echo.

cd /d "%~dp0"

echo Your branch is ahead by 1 commit (from yesterday)
echo Pushing to main now...
echo.

git push origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  SUCCESS!
    echo ========================================
    echo.
    echo ✅ Yesterday's commit pushed to main
    echo ✅ App Hosting will auto-deploy in 3-5 minutes
    echo.
    echo WHILE YOU WAIT:
    echo 1. Run: deploy-firestore-rules.bat
    echo 2. Monitor: https://console.firebase.google.com/project/new-flutter-ai/apphosting
    echo 3. When deployed, press R in Flutter terminal
    echo.
) else (
    echo.
    echo ERROR: Push failed
    echo.
)

pause

