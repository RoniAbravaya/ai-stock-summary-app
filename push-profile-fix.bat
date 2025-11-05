@echo off
echo ========================================
echo  PUSHING PROFILE API FIX
echo ========================================
echo.

cd /d "%~dp0"

echo Adding files...
git add backend/services/stockProfileCacheService.js
git add backend/services/yahooFinanceService.js
git add backend/api/stocks.js
git add functions/index.js
git add firestore.rules
git add QUICK_START_DEPLOYMENT.md
git add STOCK_PROFILE_FIX_SUMMARY.md
git add DEPLOYMENT_FIX.md
git add just-push.bat
git add push-profile-fix.bat

echo.
echo Committing...
git commit -m "fix: Stock profile API FieldValue reference and RapidAPI integration"

echo.
echo Pushing to main...
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  SUCCESS!
    echo ========================================
    echo.
    echo ✅ Pushed to main
    echo ✅ App Hosting will deploy in 3-5 min
    echo.
    echo NEXT STEPS:
    echo 1. Wait 5 minutes for deployment
    echo 2. Run: deploy-firestore-rules.bat
    echo 3. Press R in Flutter terminal
    echo 4. Test stock profiles
    echo.
    echo Monitor: https://console.firebase.google.com/project/new-flutter-ai/apphosting
    echo.
) else (
    echo ERROR: Push failed
)

pause

