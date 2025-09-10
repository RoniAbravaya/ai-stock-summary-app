@echo off
echo FCM Token Health Check
echo ====================
echo.

cd backend

echo Checking FCM token health for all users...
node scripts/fcm-token-health-check.js --verbose

echo.
echo To trigger FCM token refresh for users without tokens, run:
echo node scripts/fcm-token-health-check.js --trigger-refresh
echo.
pause
