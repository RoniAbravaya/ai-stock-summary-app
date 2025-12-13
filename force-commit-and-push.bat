@echo off
echo ========================================
echo  FORCE COMMIT AND PUSH ALL CHANGES
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Add ALL modified files...
git add -A

echo.
echo Step 2: Check what will be committed...
git status

echo.
echo Step 3: Commit changes...
git commit -m "fix: Remove mock data fallback and clean up stock details UI"

echo.
echo Step 4: Push to main...
git push origin main

echo.
echo ========================================
if %ERRORLEVEL% EQU 0 (
    echo  SUCCESS! Changes pushed to main
) else (
    echo  Note: If you see 'Everything up-to-date', 
    echo  the changes are already pushed.
)
echo ========================================
echo.
echo Check deployment:
echo https://console.firebase.google.com/project/new-flutter-ai/apphosting
echo.

pause

