# Push Notification Troubleshooting Guide

## Issue: Notifications not being delivered despite no errors

### Root Cause Analysis ✅
- ✅ FCM tokens are being generated and stored
- ✅ Notification documents are created in Firestore
- ❌ Cloud Functions are not processing notifications (status remains "pending")

### Solutions

#### 1. Deploy Cloud Functions
```bash
# Run this command in your project root
firebase deploy --only functions --project new-flutter-ai
```

#### 2. Check Cloud Function Logs
```bash
firebase functions:log --only processNotification --limit 20
```

#### 3. Test Manual Notification
```bash
# Install dependencies and run test script
npm install firebase-admin
node test_notification.js
```

#### 4. Android Emulator Issues
The Google Play Services errors suggest emulator issues:

**Fix Option 1: Use a physical device**
- Connect your Android phone
- Enable USB debugging
- Run `flutter run` and select your physical device

**Fix Option 2: Update emulator**
- Open Android Studio
- Go to AVD Manager
- Create a new emulator with Google Play services
- Use API level 30 or higher

#### 5. Verify Firestore Rules
Make sure your Firestore rules allow Cloud Functions to read/write:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow Cloud Functions to process admin notifications
    match /admin_notifications/{document} {
      allow read, write: if true; // Cloud Functions need this
    }
    
    // Allow users to read their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### 6. Check Firebase Project Configuration
1. Verify you're using the correct project: `firebase use new-flutter-ai`
2. Ensure functions are enabled in Firebase Console
3. Check billing (Cloud Functions require Blaze plan for external API calls)

### Testing Steps

1. **Deploy functions**: `firebase deploy --only functions`
2. **Create test notification** in your Flutter app
3. **Check Firestore** - notification should change from "pending" to "processed"
4. **Check device** - notification should appear

### Debug Commands
```bash
# Check deployment status
firebase functions:list

# View recent logs
firebase functions:log --limit 50

# Test locally
firebase emulators:start --only functions,firestore
```

### Expected Behavior
When working correctly:
1. User creates notification in Flutter app
2. Document appears in `admin_notifications` with `status: "pending"`
3. Cloud Function triggers automatically
4. Function processes notification and sends to FCM
5. Status updates to `status: "processed"`
6. Users receive push notification on their devices
