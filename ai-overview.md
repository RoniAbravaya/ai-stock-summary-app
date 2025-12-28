# AI Stock Summary App - Technical Overview

## Project Structure

### Frontend (Flutter Mobile App)
- **Location**: `/mobile-app/`
- **Framework**: Flutter with Firebase integration
- **Architecture**: Clean architecture with services pattern
- **Key Features**: Stock tracking, AI summaries, push notifications, admin panel

### Backend Services
- **Location**: `/backend/`
- **Framework**: Node.js Express server
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth with custom claims

### Cloud Functions
- **Location**: `/functions/`
- **Runtime**: Node.js 18
- **Purpose**: Process admin notifications and send FCM push messages

## Firebase Configuration

### Project Details
- **Project ID**: `new-flutter-ai`
- **Messaging Sender ID**: `492701567937`
- **Storage Bucket**: `new-flutter-ai.firebasestorage.app`

### Services Used
- Firebase Authentication (with Google, Facebook, Twitter Sign-In)
  - **Automatic Account Linking**: When "One account per email" is enabled, the app automatically links social sign-in providers if a user tries to sign in with a different provider for an existing email address
- Cloud Firestore Database
- Firebase Cloud Messaging (FCM)
- Firebase Storage
- Firebase Cloud Functions

## Push Notification Architecture

### FCM Implementation Overview
The app follows Firebase Cloud Messaging REST API v1 specifications:

#### 1. Token Management (Flutter App)
```dart
// FCM token acquisition and storage
await _messaging.getToken() → Store in users/{uid}/fcmToken
```

#### 2. Notification Flow
```
Admin UI → Firestore admin_notifications → Cloud Function → FCM API → User Devices
```

#### 3. Message Structure (FCM REST API v1 Compliant)
```javascript
{
  notification: {
    title: "Notification Title",
    body: "Notification Body"
  },
  data: {
    notificationType: "admin_broadcast",
    sentBy: "admin",
    timestamp: "..."
  },
  android: {
    notification: {
      icon: "stock_icon",
      color: "#1976D2",
      sound: "default"
    }
  },
  apns: {
    payload: {
      aps: {
        alert: { title: "...", body: "..." },
        badge: 1,
        sound: "default"
      }
    }
  }
}
```

### Supported Notification Types
1. **All Users**: Broadcast to all app users
2. **User Type**: Target free or premium users
3. **Specific Users**: Send to selected users by email

### Cloud Functions

#### `processNotification`
- **Trigger**: Firestore document creation in `admin_notifications`
- **Batch Processing**: Handles up to 1000 tokens per batch (FCM limit)
- **Error Handling**: Logs failures and updates notification status
- **Retry Logic**: Built-in Firebase Functions retry on failure

#### `monthlyUsageReset`
- **Schedule**: Runs at 00:00 UTC on 1st of every month
- **Purpose**: Reset all users' AI summary usage counters
- **Process**:
  1. Fetches all user documents
  2. Saves current usage to history
  3. Resets `summariesUsed` to 0
  4. Updates `lastResetDate`
  5. Logs event to `system_logs`
- **Monitoring**: Check `system_logs` collection after 1st

## Data Models

### User Document (`users/{uid}`)
```javascript
{
  email: string,
  displayName: string,
  photoURL: string,
  role: "user" | "admin",
  subscriptionType: "free" | "premium" | "admin",
  summariesUsed: number,         // Current month usage
  summariesLimit: number,        // 5 for free, 100 for premium, 1000 for admin
  lastUsedAt: timestamp,         // Last AI summary generation time
  lastResetDate: timestamp,      // Last reset on 1st of month
  usageHistory: {                // Last 12 months of usage
    "2025-10": {
      used: number,
      limit: number,
      resetDate: timestamp
    }
  },
  fcmToken: string,              // FCM registration token
  fcmTokenUpdatedAt: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Admin Notification (`admin_notifications/{id}`)
```javascript
{
  title: string,
  message: string,
  target: "all_users" | "specific_user" | "user_type",
  targetUserEmail?: string,    // For specific_user
  targetUserType?: string,     // For user_type (free/premium)
  sentBy: string,
  sentAt: timestamp,
  processed: boolean,
  processing: boolean,
  results?: object[],          // FCM response details
  error?: string,
  processedAt?: timestamp
}
```

### Usage Log (`usage_logs/{id}`)
```javascript
{
  userId: string,
  userEmail: string,
  action: "ai_summary_generated",
  ticker: string,
  language: string,
  subscriptionType: string,
  timestamp: timestamp
}
```

### System Log (`system_logs/{id}`)
```javascript
{
  event: "monthly_usage_reset",
  monthKey: string,            // e.g., "2025-10"
  usersReset: number,
  usersSkipped: number,
  timestamp: timestamp
}
```

## Security Rules

### Firestore Rules
- Users can read/write their own documents
- Admins can create notifications
- Cloud Functions can process notifications (no auth required)
- FCM tokens are user-private
- **Usage Tracking**:
  - Users can create usage logs (when generating summaries)
  - Admins can read all usage logs
  - System logs are admin-only

### Firebase Storage Rules
- Users can manage their profile images
- Public read for stock/news assets
- Admin-only write for public assets

## Admin Features

### User Management
- Search users by email
- Promote/demote admin roles
- View user statistics and usage

### Push Notifications
- Target audience selection
- Real-time user search
- Batch notification processing
- Delivery status tracking

### Analytics Dashboard
- User registration trends
- Subscription statistics
- System health monitoring
- **AI Summary Usage Statistics**:
  - Total users by subscription type
  - Usage breakdown by user type
  - Users at/near limit tracking
  - Average usage per user
  - Top users by usage
  - Monthly generation counts
  - Individual user usage details

## AI Summary Usage & Limits

### Usage Limits
- **Free Users**: 5 AI summaries per month
- **Premium Users**: 100 AI summaries per month
- **Admin Users**: Unlimited summaries

### Monthly Reset
- Automatic reset on **1st of every month at 00:00 UTC**
- Cloud Function: `monthlyUsageReset`
- Previous month's usage saved to history (last 12 months)
- Client-side reset detection on app launch

### Usage Tracking
1. **Generation Request**:
   - Requires Firebase authentication
   - Checks current usage vs limit
   - Shows warning if near limit (free users)
   - Blocks if limit exceeded

2. **Counter Increment**:
   - After successful generation
   - Updates `summariesUsed` in user document
   - Logs to `usage_logs` collection for statistics

3. **History Management**:
   - Saves monthly usage to `usageHistory`
   - Keeps last 12 months
   - Displayed in user settings

### User Experience
- **Warning Dialog**: Shows when free user has 1 summary left
- **Limit Dialog**: Shows when limit exceeded with upgrade prompt
- **Usage Stats Card**: Visual progress bar and history in settings
- **Real-time Feedback**: Remaining summaries shown after each generation

## Environment Configuration

### Required Environment Variables
```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=new-flutter-ai
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-...@new-flutter-ai.iam.gserviceaccount.com
# ... other Firebase credentials

# API Configuration
OPENAI_API_KEY=sk-...
RAPIDAPI_KEY=...
```

## Development Setup

### 1. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and select project
firebase login
firebase use new-flutter-ai

# Deploy Cloud Functions
cd functions
npm install
firebase deploy --only functions
```

### 2. Flutter Setup
```bash
cd mobile-app
flutter pub get
flutter run
```

### 3. Backend Setup
```bash
cd backend
npm install
npm start
```

## Testing Push Notifications

### Prerequisites
1. Firebase project configured
2. Cloud Functions deployed
3. Flutter app with FCM token registered
4. Admin user authenticated

### Test Flow
1. Login as admin in Flutter app
2. Navigate to Admin Panel → Notifications
3. Create notification with target audience
4. Notification is processed by Cloud Function
5. Push message delivered to target devices

## Troubleshooting

### Common FCM Issues
1. **Tokens not found**: Check if users have FCM tokens in Firestore
2. **Cloud Function not triggering**: Verify deployment and Firestore rules
3. **Messages not received**: Check device notification permissions
4. **Batch failures**: Review Cloud Function logs for specific errors

### Debug Commands
```bash
# View Cloud Function logs
firebase functions:log --only processNotification

# Test locally
firebase emulators:start --only functions,firestore

# Check Firestore data
firebase firestore:data:read users
```

## Performance Considerations

### FCM Best Practices
- Batch notifications (max 1000 tokens)
- Handle token refresh gracefully
- Implement exponential backoff for failures
- Monitor delivery rates and adjust timing

### Firestore Optimization
- Use indexes for user queries
- Implement pagination for large collections
- Cache frequently accessed data locally
- Clean up processed notifications periodically

## Authentication & Account Linking

### Social Sign-In Providers
- **Google Sign-In**: OAuth 2.0 with automatic account linking
- **Facebook Sign-In**: OAuth with automatic account linking
- **Apple Sign-In**: OAuth with Supabase integration (App Store Guideline 4.8 compliance)
- **Twitter Sign-In**: OAuth with automatic account linking (temporarily disabled)
- **Email/Password**: Traditional authentication

### Apple Sign-In (Guideline 4.8 Compliance)
Required by App Store when using third-party login services (Google/Facebook).
Provides a privacy-preserving login option that:
- Limits data collection to name and email
- Allows users to hide their email address
- Does not collect interactions for advertising

**Implementation Details:**
- Package: `sign_in_with_apple` ^6.1.4
- Auth Service: `signInWithApple()` method in `auth_service.dart`
- UI: Apple Sign-In button on login screen (styled per Apple HIG)
- iOS Config: 
  - Entitlements file: `Runner.entitlements` with `com.apple.developer.applesignin`
  - Minimum iOS version: 13.0 (required for Apple Sign-In)
  - Xcode capability: "Sign in with Apple" must be enabled

### Automatic Account Linking
The app implements automatic account linking to handle the Firebase "One account per email" restriction:

1. **How it works**: When a user tries to sign in with a provider (e.g., Facebook) using an email already registered with another provider (e.g., Google), the system:
   - Detects the `account-exists-with-different-credential` error
   - Automatically prompts the user to sign in with their existing provider
   - Links the new provider credential to the existing account
   - Allows future sign-ins with either provider

2. **Implementation**: See `/workspace/ACCOUNT_LINKING_FIX.md` for detailed documentation

3. **Fallbacks**: 
   - Handles Email Enumeration Protection
   - Provides clear error messages when automatic linking fails
   - Gracefully handles user cancellation

## App Store Compliance

### Guideline 4.8 - Login Services
- **Requirement**: Apps using third-party login (Google/Facebook) must offer equivalent login option
- **Solution**: Implemented Sign in with Apple with privacy-preserving features
- **Status**: ✅ Implemented

### Guideline 2.1 - App Completeness
- **Requirement**: All IAP products must be configured in App Store Connect
- **Solution**: Product validation during initialization with graceful error handling
- **Product IDs**: 
  - `premium_monthly_subscription`
  - `premium_yearly_subscription`
- **Important**: Ensure these IDs match exactly in App Store Connect before submission
- **Status**: ✅ Validation logic implemented

### Guideline 2.3.10 - Accurate Metadata
- **Requirement**: No simulator watermarks or development references in screenshots/UI
- **Solution**: 
  - EnvironmentIndicator hidden in release builds using `kReleaseMode`
  - EnvironmentBanner hidden in production/release mode
  - Test ad unit IDs replaced with production IDs in release builds
- **Status**: ✅ Implemented

### Pre-Submission Checklist
1. ☐ Capture new screenshots on physical iOS device (no simulator)
2. ☐ Verify IAP products exist and are approved in App Store Connect
3. ☐ Replace test AdMob IDs with production IDs in `subscription_service.dart`
4. ☐ Enable "Sign in with Apple" capability in Xcode
5. ☐ Test Apple Sign-In on physical device
6. ☐ Verify all login flows work correctly
7. ☐ Remove any debug/development UI elements
8. ☐ Update App Store Connect metadata and screenshots

## Next Steps

### Planned Enhancements
1. Rich notifications with images
2. Scheduled notifications
3. A/B testing for notification content
4. Analytics integration for delivery tracking
5. Topic-based messaging for categories
6. UI improvements for account linking (success notifications, provider management) 