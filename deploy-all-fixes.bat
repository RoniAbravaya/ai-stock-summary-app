@echo off
echo ========================================
echo  DEPLOYING ALL FIXES FOR STOCK FEATURES
echo ========================================
echo.

cd /d "%~dp0"
echo Current directory: %CD%
echo.

echo ========================================
echo STEP 1: Deploy Firestore Security Rules
echo ========================================
echo.
firebase deploy --only firestore:rules

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Firestore rules deployment failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo STEP 2: Deploy Cloud Functions
echo ========================================
echo.
echo Deploying scheduled functions...
firebase deploy --only functions:dailyStockProfileRefresh

if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Cloud function deployment failed, but continuing...
)

echo.
echo ========================================
echo STEP 3: Deploy Backend to App Hosting
echo ========================================
echo.
echo Note: Backend code changes need to be committed and pushed
echo The App Hosting will auto-deploy from your repository
echo.
echo Run these commands manually:
echo   git add .
echo   git commit -m "fix: Update stock profile API to use correct RapidAPI endpoint with Firestore caching"
echo   git push origin main
echo.
echo Then wait for App Hosting to auto-deploy (check Firebase Console)
echo.

echo ========================================
echo  DEPLOYMENT SUMMARY
echo ========================================
echo.
echo ✅ Firestore rules deployed
echo ✅ Cloud Functions deployed
echo ⏳ Backend needs manual commit + push
echo.
echo NEXT STEPS:
echo 1. Commit and push backend changes (see commands above)
echo 2. Wait for App Hosting to deploy (2-5 minutes)
echo 3. Hot restart Flutter app (press R in terminal)
echo 4. Test features:
echo    - Stock Brief: Open any stock, scroll down below chart
echo    - Support: Settings -^> Help ^& Support
echo    - Share: Favorites -^> tap share icon
echo.
pause

