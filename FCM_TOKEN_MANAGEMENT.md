# FCM Token Management Guide

This guide explains how to manage FCM (Firebase Cloud Messaging) tokens for users who may not have them, and provides tools to identify and fix token issues.

## Problem Description

Some users may not have FCM tokens even after logging in and out multiple times. This can happen due to:
- Network connectivity issues during token generation
- App being killed during token registration
- Permission issues on the device
- Firebase SDK initialization problems
- Device-specific FCM service issues

## Solution Overview

We've implemented a comprehensive FCM token management system with the following components:

### 1. Admin API Endpoints

#### Check FCM Token Health
```bash
GET /api/admin/fcm-token-health
```

Returns detailed statistics about FCM token health across all users:
- Total users count
- Users with/without FCM tokens
- Recent token updates
- List of users missing tokens

#### Trigger FCM Token Refresh
```bash
POST /api/admin/trigger-fcm-refresh
```

Triggers FCM token refresh for users without tokens by:
- Finding all users without FCM tokens
- Marking them for token refresh
- Creating admin notification to track the process

### 2. Enhanced Flutter App Logic

#### Automatic Token Refresh on Sign-in
- Every sign-in now calls `ensureFCMTokenExists()`
- If no token is found, attempts to generate a new one
- Verifies token storage in Firestore

#### Refresh Request Processing
- App checks for `fcmTokenRefreshRequested` flag on startup
- Automatically refreshes token if requested
- Clears the refresh flag after processing

#### New Methods Added to FirebaseService:
- `ensureFCMTokenExists()` - Checks and refreshes missing tokens
- `refreshMissingFCMTokens()` - Admin bulk refresh function
- `_checkForFCMRefreshRequest()` - Processes refresh requests

### 3. Standalone Health Check Script

Location: `backend/scripts/fcm-token-health-check.js`

#### Usage:
```bash
# Check token health only
node scripts/fcm-token-health-check.js --check-only

# Check and trigger refresh for users without tokens
node scripts/fcm-token-health-check.js --trigger-refresh

# Verbose output with detailed user information
node scripts/fcm-token-health-check.js --verbose --trigger-refresh
```

#### Features:
- Comprehensive health reporting
- Identifies users with missing tokens
- Tracks token age (identifies old tokens)
- Bulk refresh triggering
- Admin notification creation

### 4. Enhanced Cloud Functions

Added support for `specific_users_bulk` notification target to handle bulk user notifications efficiently.

## How to Use

### For Immediate Issues

1. **Check current FCM token health:**
   ```bash
   # From project root
   check_fcm_tokens.bat
   
   # Or manually from backend folder
   cd backend
   node scripts/fcm-token-health-check.js --verbose
   ```

2. **Trigger token refresh for affected users:**
   ```bash
   cd backend
   node scripts/fcm-token-health-check.js --trigger-refresh
   ```

3. **Monitor results:**
   - Users will get new FCM tokens when they next launch the app
   - Check admin notifications in Firebase console
   - Run the health check again after a few hours

### For API-based Management

1. **Check token health via API:**
   ```bash
   curl -X GET "https://your-api-domain/api/admin/fcm-token-health"
   ```

2. **Trigger refresh via API:**
   ```bash
   curl -X POST "https://your-api-domain/api/admin/trigger-fcm-refresh"
   ```

### For App-level Solutions

Users experiencing notification issues can:
1. **Force app restart** - This will trigger automatic token refresh
2. **Log out and log back in** - Enhanced sign-in process will ensure token exists
3. **Check notification permissions** - Ensure the app has notification permissions

## Technical Implementation Details

### Database Fields Added

**User Document (`users/{uid}`):**
- `fcmTokenRefreshRequested: boolean` - Flag indicating token refresh needed
- `fcmTokenRefreshRequestedAt: timestamp` - When refresh was requested
- `fcmTokenRefreshProcessedAt: timestamp` - When refresh was completed

### Notification Flow for Token Refresh

1. Admin/Script identifies users without tokens
2. Users are marked with `fcmTokenRefreshRequested: true`
3. When user opens app, `_checkForFCMRefreshRequest()` runs
4. If flag is true, `forceFCMTokenUpdate()` is called
5. New token is generated and stored
6. Flag is cleared with `fcmTokenRefreshProcessedAt` timestamp

### Error Handling

- All operations include comprehensive error handling
- Failed token generations are logged with details
- Network timeouts are handled gracefully
- Partial failures in batch operations are tracked

## Monitoring and Maintenance

### Regular Health Checks
Run the health check script weekly to monitor token health:
```bash
node scripts/fcm-token-health-check.js --verbose
```

### Key Metrics to Monitor
- **Token Coverage**: Percentage of users with valid FCM tokens
- **Token Age**: Users with tokens older than 30 days
- **Refresh Success Rate**: How many refresh requests succeed
- **New User Token Generation**: Ensure new users get tokens on first sign-in

### Troubleshooting Common Issues

1. **Script fails to run:**
   - Ensure Firebase service account key is available
   - Check network connectivity to Firebase
   - Verify project permissions

2. **Tokens not generating on app launch:**
   - Check app notification permissions
   - Verify Firebase SDK initialization
   - Review app logs for FCM errors

3. **Bulk refresh not working:**
   - Ensure Cloud Functions are deployed
   - Check Firestore security rules
   - Verify admin notification processing

## Security Considerations

- Only admin users can trigger bulk token refresh
- FCM tokens are stored securely in Firestore
- Refresh requests are time-stamped for audit trail
- API endpoints require proper authentication

## Performance Considerations

- Batch operations are limited to prevent Firestore quota issues
- Token refresh is done asynchronously to avoid blocking app startup
- Health check script processes users in batches of 10 (Firestore limit)
- Old/invalid tokens are automatically cleaned up

## Future Enhancements

Potential improvements to consider:
- Automatic token refresh scheduling
- Push notification delivery analytics
- Token expiration monitoring
- Device-specific token management
- A/B testing for token refresh strategies

## Support

For issues with FCM token management:
1. Check the app logs for FCM-related errors
2. Run the health check script to identify affected users
3. Review Firebase console for Cloud Function logs
4. Check Firestore security rules if API calls fail

---

**Last Updated:** September 2025
**Version:** 1.0.0
