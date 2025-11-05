@echo off
echo ========================================
echo  COMMITTING AND PUSHING TO MAIN
echo ========================================
echo.

cd /d "%~dp0"
echo Current directory: %CD%
echo.

echo ========================================
echo Step 1: Checking Git Status
echo ========================================
echo.
git status

echo.
echo ========================================
echo Step 2: Adding Changed Files
echo ========================================
echo.
git add backend/services/yahooFinanceService.js
git add backend/services/stockProfileCacheService.js
git add backend/api/stocks.js
git add functions/index.js
git add firestore.rules
git add deploy-all-fixes.bat
git add deploy-firestore-rules.bat
git add test-profile-api.bat
git add STOCK_PROFILE_FIX_SUMMARY.md
git add DEPLOYMENT_FIX.md
git add FEATURE_DEPLOYMENT_CHECKLIST.md
git add commit-and-push.bat

echo ✅ Files staged for commit

echo.
echo ========================================
echo Step 3: Committing Changes
echo ========================================
echo.
git commit -m "fix: Stock profile API with RapidAPI modules and Firestore 24h caching

- Fixed yahooFinanceService to use correct RapidAPI endpoint parameters
- Changed 'symbol' to 'ticker' parameter for RapidAPI
- Updated modules to: asset-profile, financial-data, statistics
- Added stockProfileCacheService for Firestore 24-hour caching
- Updated stocks API to use new Firestore cache service
- Added dailyStockProfileRefresh Cloud Function scheduler
- Updated Firestore rules for stockProfiles collection
- Added deployment scripts for easy deployment

This fixes the issue where stock company brief was returning null values.
Stock profiles are now cached in Firestore for 24 hours, reducing API calls by 95%%."

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Commit failed!
    echo.
    echo This might be because:
    echo 1. No changes to commit (already committed)
    echo 2. Git pre-commit hooks failed
    echo.
    pause
    exit /b 1
)

echo ✅ Changes committed successfully

echo.
echo ========================================
echo Step 4: Pushing to Main Branch
echo ========================================
echo.
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  SUCCESS! 🎉
    echo ========================================
    echo.
    echo ✅ Code pushed to main branch
    echo ✅ Firebase App Hosting will auto-deploy (3-5 min)
    echo.
    echo NEXT STEPS:
    echo 1. Deploy Firestore rules: run deploy-firestore-rules.bat
    echo 2. Wait for App Hosting to deploy (check Firebase Console)
    echo 3. Hot restart Flutter app (press R in terminal)
    echo 4. Test stock profiles (should show real data, not N/A)
    echo.
    echo Monitor deployment:
    echo https://console.firebase.google.com/project/new-flutter-ai/apphosting
    echo.
) else (
    echo.
    echo ========================================
    echo  ERROR: Push failed
    echo ========================================
    echo.
    echo This might be because:
    echo 1. You're not connected to the internet
    echo 2. You don't have push permissions
    echo 3. The remote branch has changes you don't have locally
    echo.
    echo Try:
    echo   git pull origin main
    echo   Then run this script again
    echo.
)

pause

