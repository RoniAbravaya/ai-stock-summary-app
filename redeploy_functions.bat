@echo off
echo Redeploying Firebase Cloud Functions...
echo.

echo Step 1: Installing dependencies...
cd functions
call npm install --save firebase-functions@latest
cd ..

echo.
echo Step 2: Setting Firebase project...
call firebase use new-flutter-ai

echo.
echo Step 3: Deleting existing function (if any)...
call firebase functions:delete processNotification --force --project new-flutter-ai

echo.
echo Step 4: Deploying functions...
call firebase deploy --only functions --project new-flutter-ai --force

echo.
echo Deployment complete!
echo.
echo Checking function status...
call firebase functions:list

pause
