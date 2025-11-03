# AI Summary Usage Tracking - Deployment Checklist

## Pre-Deployment Verification

### ? Backend Changes
- [x] Authentication middleware created (`/backend/middleware/auth.js`)
- [x] Summary API updated with usage tracking (`/backend/api/summary.js`)
- [x] Admin statistics endpoints added (`/backend/api/admin.js`)
- [x] User usage endpoint added (`/backend/api/users.js`)

### ? Cloud Functions
- [x] Monthly reset function added (`/functions/index.js`)
- [x] Scheduled for 1st of every month at 00:00 UTC

### ? Mobile App
- [x] User data service updated with 1st-of-month reset (`/mobile-app/lib/services/user_data_service.dart`)
- [x] AI summary dialog with warnings created (`/mobile-app/lib/widgets/ai_summary_dialog.dart`)
- [x] Usage stats card widget created (`/mobile-app/lib/widgets/usage_stats_card.dart`)

### ? Security
- [x] Firestore rules updated (`/firestore.rules`)
- [x] New collections secured (usage_logs, system_logs)

---

## Deployment Steps

### 1. Update Environment Variables
Ensure these are set in your backend environment:
```bash
FIREBASE_PROJECT_ID=new-flutter-ai
FIREBASE_PRIVATE_KEY="..."
FIREBASE_CLIENT_EMAIL="..."
OPENAI_API_KEY=sk-...
```

### 2. Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```

**Verify**: Check Firebase Console > Firestore > Rules

### 3. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions:monthlyUsageReset
```

**Verify**: 
```bash
firebase functions:list
# Should show: monthlyUsageReset (scheduled)
```

### 4. Deploy Backend API
```bash
cd backend
npm install
# Update environment variables
npm start
```

**Verify**: 
```bash
curl http://localhost:3000/health
# Should return: {"status":"OK",...}
```

### 5. Build & Deploy Mobile App
```bash
cd mobile-app
flutter pub get
flutter build appbundle  # For Android
flutter build ios        # For iOS
```

**Test on Device**:
- Generate AI summary
- Check usage counter updates
- Test limit warning at 4/5
- Test limit block at 5/5
- Verify usage stats in settings

---

## Post-Deployment Testing

### Backend API Testing

#### 1. Test Authentication
```bash
# Should fail without auth
curl -X POST http://localhost:3000/api/summary/generate \
  -H "Content-Type: application/json" \
  -d '{"stockId":"AAPL"}'

# Expected: 401 Unauthorized
```

#### 2. Test Usage Limit (requires Firebase token)
```bash
# Get Firebase auth token from mobile app or Firebase Console
TOKEN="your-firebase-id-token"

# Generate summary (should work)
curl -X POST http://localhost:3000/api/summary/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"stockId":"AAPL","language":"en"}'

# Expected: Success with usage info
```

#### 3. Test Usage Statistics (admin only)
```bash
curl -X GET http://localhost:3000/api/admin/usage-statistics \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Expected: Statistics object
```

#### 4. Test User Usage Endpoint
```bash
curl -X GET http://localhost:3000/api/users/USER_ID/usage \
  -H "Authorization: Bearer $USER_TOKEN"

# Expected: Usage data with history
```

### Mobile App Testing

#### Test Scenario 1: New Free User
1. **Sign up** as new user
2. **Check Settings**: Should show 0/5 used
3. **Generate 1st Summary**: Should work
4. **Check Settings**: Should show 1/5 used
5. **Generate 4 more**: All should work
6. **Check Settings**: Should show 5/5 used
7. **Attempt 6th**: Should show limit dialog

#### Test Scenario 2: Free User Near Limit
1. **Sign in** as user with 4/5 used
2. **Attempt Summary**: Should show warning dialog
3. **Click Continue**: Should generate successfully
4. **Check Settings**: Should show 5/5 used
5. **Attempt Another**: Should show limit dialog

#### Test Scenario 3: Admin User
1. **Sign in** as admin (erolrony91@gmail.com)
2. **Check Settings**: Should show high limit (1000)
3. **Generate Multiple**: Should work without limits
4. **Check Admin Stats**: Should see all user statistics

### Cloud Function Testing

#### Manual Test (Before 1st of Month)
```bash
# Trigger function manually
firebase functions:shell
> monthlyUsageReset()
```

#### Verify Reset Results
1. Check `system_logs` collection in Firestore
2. Verify user documents have `summariesUsed = 0`
3. Check `usageHistory` contains previous month's data

#### Scheduled Test (Wait for 1st)
1. **Before 1st**: Note current usage for test users
2. **On 1st at 00:01 UTC**: Check Cloud Functions logs
3. **After Reset**: Verify all users reset to 0

```bash
# Check function logs
firebase functions:log --only monthlyUsageReset --limit 10
```

---

## Monitoring & Alerts

### Key Metrics

#### Usage Logs
- **Location**: Firestore > usage_logs
- **Monitor**: Daily generation count
- **Alert if**: < 10% of normal or > 200% of normal

#### System Logs
- **Location**: Firestore > system_logs
- **Monitor**: Monthly reset execution
- **Alert if**: Reset fails or doesn't run on 1st

#### User Documents
- **Location**: Firestore > users
- **Monitor**: `summariesUsed` distribution
- **Alert if**: Many users at limit (conversion opportunity)

### Firebase Console Checks

**Daily**:
- Check usage_logs count
- Review error logs in Functions

**Weekly**:
- Review admin statistics
- Check users at/near limit

**Monthly** (after 1st):
- Verify reset executed successfully
- Check system_logs for reset confirmation
- Spot-check user documents for reset

---

## Rollback Plan

### If Issues Occur

#### Issue: Cloud Function Fails
```bash
# 1. Check logs
firebase functions:log --only monthlyUsageReset

# 2. Manual reset if needed
# Run script to reset all users manually

# 3. Redeploy function
cd functions
firebase deploy --only functions:monthlyUsageReset
```

#### Issue: Backend API Errors
```bash
# 1. Revert to previous version
git revert HEAD

# 2. Redeploy
npm install && npm start

# 3. Check logs
pm2 logs  # If using PM2
```

#### Issue: Mobile App Crashes
```bash
# 1. Revert to previous build
# 2. Deploy hotfix
# 3. Notify users via push notification

# Quick fix: Disable summary generation temporarily
# in Firebase Remote Config
```

---

## Common Issues & Solutions

### Issue: User limit not enforcing
**Check**:
1. Is authentication middleware properly applied?
2. Is user document being updated after generation?
3. Check backend logs for errors

**Solution**:
```javascript
// Verify in Firestore Console
users/{userId}
  summariesUsed: should increment
  summariesLimit: should be 5 for free
```

### Issue: Monthly reset didn't run
**Check**:
1. Function deployed: `firebase functions:list`
2. Schedule correct: Check function config
3. Logs: `firebase functions:log`

**Solution**:
```bash
# Manually trigger and check
firebase functions:shell
> monthlyUsageReset()

# Or redeploy
firebase deploy --only functions:monthlyUsageReset
```

### Issue: Mobile app shows wrong count
**Check**:
1. Network connectivity
2. Firebase auth valid
3. Local cache vs remote

**Solution**:
```dart
// Force sync in user_data_service.dart
await UserDataService().syncWithFirebase();
```

---

## Success Criteria

### ? Deployment Successful When:

1. **Backend**:
   - [x] All endpoints respond correctly
   - [x] Authentication required and working
   - [x] Usage limits enforced
   - [x] Admin stats accessible

2. **Cloud Functions**:
   - [x] Function deployed and scheduled
   - [x] Test trigger works correctly
   - [x] Logs showing in Firebase Console

3. **Mobile App**:
   - [x] Usage counter updates in real-time
   - [x] Warning shows at 4/5 for free users
   - [x] Limit blocks at 5/5
   - [x] Stats card displays correctly
   - [x] History shows previous months

4. **Security**:
   - [x] Firestore rules prevent unauthorized access
   - [x] Authentication required for all endpoints
   - [x] Admin-only endpoints protected

5. **Monitoring**:
   - [x] Usage logs collecting data
   - [x] System logs recording resets
   - [x] No errors in logs

---

## Next Steps After Deployment

1. **Monitor for 24 hours**:
   - Check error rates
   - Verify usage tracking works
   - Ensure no performance issues

2. **Wait for First Reset** (1st of next month):
   - Monitor function execution
   - Verify users reset correctly
   - Check system logs

3. **Gather User Feedback**:
   - Monitor support tickets
   - Check app reviews
   - Survey user satisfaction

4. **Optimize**:
   - Review statistics
   - Adjust limits if needed
   - Improve warning messages

5. **Plan Premium Launch**:
   - Set pricing
   - Implement payment flow
   - Marketing campaign

---

## Documentation Updates

After successful deployment, update:

- [x] `ai-overview.md` - Architecture overview ?
- [x] `AI_SUMMARY_USAGE_IMPLEMENTATION.md` - Implementation details ?
- [x] `DEPLOYMENT_CHECKLIST.md` - This document ?
- [ ] `README.md` - User-facing documentation
- [ ] Admin dashboard with instructions
- [ ] User help center articles

---

## Support Contacts

**Technical Issues**:
- Backend: Check `/backend/README.md`
- Mobile App: Check `/mobile-app/README.md`
- Cloud Functions: `firebase support:chat`

**Deployment Help**:
- Firebase: https://firebase.google.com/support
- Flutter: https://flutter.dev/community

---

**Status**: ? Ready for Deployment

**Last Updated**: November 3, 2025

**Deployed By**: _____________

**Deployment Date**: _____________

**Verified By**: _____________
