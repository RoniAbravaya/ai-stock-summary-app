# Feature Deployment Checklist

## New Features Added:
1. ✅ Social Sharing on Favorites Page
2. ✅ Stock Brief Info Section on Stock Details Screen  
3. ✅ Support Messaging (User & Admin)

## Deployment Steps Required:

### 1. Deploy Firestore Security Rules
The support messaging feature requires updated Firestore rules.

```bash
# From project root
firebase deploy --only firestore:rules
```

**What this does:**
- Adds `supportTickets` collection rules
- Allows users to create and read their own tickets
- Allows admins to read all tickets and update status

### 2. Rebuild and Reinstall Flutter App

```bash
# Navigate to mobile-app directory
cd mobile-app

# Clean build
flutter clean

# Get dependencies (verifies share_plus, intl, url_launcher are installed)
flutter pub get

# Build and run on Android
flutter run

# OR for release build:
flutter build apk --release
# Install: mobile-app/build/app/outputs/flutter-apk/app-release.apk
```

### 3. Verify Backend is Running
The stock profile feature requires the backend API endpoint `/api/stocks/:ticker/profile`.

**Check if backend is running:**
```bash
cd backend
node index.js
# OR
npm start
```

**Test the endpoint:**
```bash
curl http://localhost:3000/api/stocks/AAPL/profile
```

Expected response:
```json
{
  "success": true,
  "data": {
    "symbol": "AAPL",
    "companyName": "Apple Inc.",
    "sector": "Technology",
    "industry": "Consumer Electronics",
    "marketCap": 3000000000000,
    "fiftyTwoWeekHigh": 199.62,
    "fiftyTwoWeekLow": 164.08,
    "exchange": "NASDAQ",
    "country": "United States",
    "website": "https://www.apple.com",
    "longBusinessSummary": "..."
  }
}
```

If you're using Firebase App Hosting or another deployment, ensure the backend is deployed.

### 4. Set Admin Custom Claim (for Admin Support Dashboard)

Only users with the `admin` custom claim can access the Admin Support List.

**Option A: Using the existing script:**
```bash
cd backend/scripts
node set-admin-claims.js YOUR_ADMIN_EMAIL@example.com
```

**Option B: Using Firebase Console:**
1. Go to Firebase Console → Authentication
2. Select user → Add custom claim: `{"admin": true}`

**Option C: Using Firebase CLI:**
```bash
firebase auth:import --hash-algo=SCRYPT users.json
```

### 5. Testing the Features

#### Test 1: Social Sharing on Favorites
1. Sign in to the app
2. Add a stock to favorites (from Stocks screen)
3. Go to Favorites tab
4. Find the share icon (iOS share icon) at the top-right of each stock card
5. Tap share icon
6. If no summary exists, it will generate one first
7. Native share sheet should open with formatted text

**Expected share format:**
```
AAPL — Apple Inc.
Summary: [AI generated summary, max 500 chars]...
Learn more: https://finance.yahoo.com/quote/AAPL
Shared via AI Stock Summary
```

#### Test 2: Stock Brief Info Card
1. Go to Stocks screen
2. Tap any stock to open Stock Details
3. Scroll down below the chart
4. You should see a "Company Brief" card with:
   - Company name
   - Sector
   - Market cap (formatted like $1.23T)
   - 52-week range
   - Exchange
   - Country
   - Website button (if available)
   - About section with business summary

**Troubleshooting:**
- If card shows "Unable to load company details" → Check backend API
- If card shows loading spinner indefinitely → Check backend logs
- If card doesn't appear → Check `StockProfileRepository` logs in Flutter

#### Test 3: Support Messaging (User)
1. Go to Settings (bottom nav or drawer)
2. Tap "Help & Support"
3. Fill out Subject and Message fields
4. Tap "Send message"
5. Should see success message and return to Settings
6. Check Firestore console → `supportTickets` collection → verify document created

**Expected Firestore document:**
```json
{
  "ticketId": "auto-generated",
  "userId": "user-uid",
  "userEmail": "user@example.com",
  "subject": "...",
  "message": "...",
  "status": "open",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "lastReplyFrom": "user"
}
```

#### Test 4: Admin Support Dashboard
1. Sign in with admin account (with custom claim)
2. Go to Admin Panel
3. Tap "Support" tab (4th tab)
4. Should see list of all support tickets
5. Tap a ticket to open details
6. Change status dropdown (open/in_progress/closed)
7. Tap "Update status"
8. Should see success message
9. Verify status updated in list and Firestore

**Troubleshooting:**
- Support tab not visible → User doesn't have admin claim
- "Unable to load support messages" → Check Firestore rules deployed
- Can't update status → Check Firestore rules allow admin updates

## Common Issues & Solutions

### Issue 1: "Nothing changed in the app"
**Cause:** Flutter app not rebuilt after code changes
**Solution:** Run `flutter clean && flutter pub get && flutter run`

### Issue 2: Stock Brief shows error
**Cause:** Backend not running or endpoint failing
**Solution:** 
- Check backend is running
- Test endpoint: `curl http://localhost:3000/api/stocks/AAPL/profile`
- Check backend logs for errors
- Verify RapidAPI key is configured in backend/.env

### Issue 3: Share button not visible on Favorites
**Cause:** Flutter UI not refreshed
**Solution:**
- Hot restart the app (R in Flutter CLI)
- Or rebuild completely

### Issue 4: Support tickets not saving
**Cause:** Firestore rules not deployed
**Solution:**
```bash
firebase deploy --only firestore:rules
```

Verify rules in Firebase Console → Firestore Database → Rules

### Issue 5: Admin can't see Support tab
**Cause:** Admin custom claim not set
**Solution:**
```bash
cd backend/scripts
node set-admin-claims.js ADMIN_EMAIL@example.com
```

Then in the app, sign out and sign in again to refresh the token.

## Verification Commands

### Check Firestore Rules Deployed:
```bash
firebase firestore:rules:get
```

### Check Flutter Dependencies:
```bash
cd mobile-app
flutter pub deps | grep -E "share_plus|intl|url_launcher"
```

Expected output:
```
share_plus 7.2.2
intl 0.18.1
url_launcher 6.2.2
```

### Check Backend Health:
```bash
curl http://localhost:3000/api/health
```

### Check User Admin Status:
In Firebase Console → Authentication → Users → Select user → Custom claims

Should show:
```json
{
  "admin": true
}
```

## Next Steps After Deployment

1. Test each feature thoroughly on a real device
2. Monitor Firestore usage for support tickets
3. Check backend logs for any API errors
4. Get user feedback on share text format
5. Consider adding:
   - Reply functionality for support tickets
   - Email notifications for support messages
   - Rich text in share (if supported by platform)
   - Cache invalidation for stock profiles

## Questions?

If features still don't appear after following these steps, check:
- Flutter console for errors: `flutter logs`
- Backend console for errors: Check terminal where `node index.js` is running
- Firestore rules: Firebase Console → Firestore Database → Rules
- Network requests: Flutter DevTools → Network tab

