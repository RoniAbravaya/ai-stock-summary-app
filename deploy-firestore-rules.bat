@echo off
echo ========================================
echo  Deploying Firestore Security Rules
echo ========================================
echo.

cd /d "%~dp0"

echo Current directory: %CD%
echo.

echo Deploying Firestore rules...
firebase deploy --only firestore:rules

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  SUCCESS! Firestore rules deployed!
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Hot restart your Flutter app (press R in terminal)
    echo 2. Test Support messaging: Settings -^> Help ^& Support
    echo 3. Test Stock Brief: Open any stock, scroll down
    echo 4. Test Share: Favorites -^> tap share icon
    echo.
) else (
    echo.
    echo ========================================
    echo  ERROR: Deployment failed
    echo ========================================
    echo.
    echo Make sure you are logged in to Firebase:
    echo   firebase login
    echo.
)

pause

