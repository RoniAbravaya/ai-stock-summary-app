@echo off
echo Deploying Firebase Cloud Functions...
cd functions
call npm install
cd ..
call firebase use new-flutter-ai
call firebase deploy --only functions
echo Deployment complete!
pause
