@echo off
echo ========================================
echo  PUSHING TO MAIN
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Adding any new files...
git add .

echo.
echo Step 2: Committing new documentation files...
git commit -m "docs: Add deployment scripts and documentation for stock profile fixes"

echo.
echo Step 3: Pushing to main (including yesterday's commit)...
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo  SUCCESS!
    echo ========================================
    echo.
    echo ✅ Code pushed to main branch
    echo ✅ App Hosting will auto-deploy in 3-5 minutes
    echo.
    echo NEXT: Run deploy-firestore-rules.bat
    echo.
) else (
    echo.
    echo ERROR: Push failed
    echo Try: git pull origin main
    echo.
)

pause

