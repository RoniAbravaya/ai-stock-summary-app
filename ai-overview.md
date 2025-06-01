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
- Firebase Authentication (with Google Sign-In)
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

### Cloud Function: `processNotification`
- **Trigger**: Firestore document creation in `admin_notifications`
- **Batch Processing**: Handles up to 1000 tokens per batch (FCM limit)
- **Error Handling**: Logs failures and updates notification status
- **Retry Logic**: Built-in Firebase Functions retry on failure

## Data Models

### User Document (`users/{uid}`)
```javascript
{
  email: string,
  displayName: string,
  photoURL: string,
  role: "user" | "admin",
  subscriptionType: "free" | "premium" | "admin",
  summariesUsed: number,
  summariesLimit: number,
  fcmToken: string,           // FCM registration token
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

## Security Rules

### Firestore Rules
- Users can read/write their own documents
- Admins can create notifications
- Cloud Functions can process notifications (no auth required)
- FCM tokens are user-private

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

## Next Steps

### Planned Enhancements
1. Rich notifications with images
2. Scheduled notifications
3. A/B testing for notification content
4. Analytics integration for delivery tracking
5. Topic-based messaging for categories 