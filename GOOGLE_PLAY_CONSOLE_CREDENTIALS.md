# Google Play Console - Test Account Credentials

## App Access Information for Google Play Reviewers

This document provides login credentials for Google Play Console reviewers to access and test all features of the AI Stock Summary App.

---

## Test Account Details

### Standard User Account (Free Tier)
**Purpose**: Test basic app functionality and AI summary limits

- **Email**: `reviewer-free@ai-stock-summary.test`
- **Password**: `PlayReviewer2025!`
- **Account Type**: Free User
- **AI Summary Limit**: 5 per month
- **Features**: 
  - View stock quotes and charts
  - Generate up to 5 AI summaries per month
  - Add stocks to favorites
  - Receive push notifications

### Premium User Account
**Purpose**: Test premium features with higher limits

- **Email**: `reviewer-premium@ai-stock-summary.test`
- **Password**: `PlayReviewer2025!`
- **Account Type**: Premium User
- **AI Summary Limit**: 100 per month
- **Features**: 
  - All free user features
  - Higher AI summary generation limit
  - Priority support

### Admin Account
**Purpose**: Test administrative features

- **Email**: `erolrony91@gmail.com`
- **Password**: `[Use your actual password - don't share publicly]`
- **Account Type**: Admin
- **Features**: 
  - Unlimited AI summaries
  - Admin dashboard access
  - User management
  - Push notification management
  - System statistics

---

## Quick Start Guide for Reviewers

### Step 1: Sign In
1. Open the AI Stock Summary App
2. Tap "Sign In" or "Get Started"
3. Select "Sign in with Email"
4. Use one of the test accounts above

### Step 2: Explore Main Features

#### Stock Market Data
- Browse the main stocks list on the home screen
- Tap any stock to view detailed information
- Check real-time price updates and charts

#### AI Summary Generation
1. Select a stock (e.g., AAPL, GOOGL, TSLA)
2. Tap the "Generate AI Summary" button
3. Wait for the AI-powered analysis
4. View comprehensive stock insights

#### Usage Limits (Free Account)
1. Go to Settings ? Account
2. View "AI Summary Usage" card
3. Shows: X/5 summaries used this month
4. Test limit warnings when near 5 summaries

#### Favorites
1. Tap the star icon on any stock
2. View favorites in the "Favorites" tab
3. Quick access to your tracked stocks

#### Push Notifications (Admin Only)
1. Sign in as admin
2. Go to Admin Panel
3. Navigate to "Notifications"
4. Send test notifications to users

---

## Feature Testing Checklist

### ? Authentication
- [ ] Email sign-in works
- [ ] Google Sign-In works (if available)
- [ ] Account creation flows properly
- [ ] Sign out and sign back in

### ? Stock Data
- [ ] Main stocks list loads correctly
- [ ] Stock details show accurate data
- [ ] Charts render properly
- [ ] Real-time price updates work

### ? AI Summary
- [ ] Summary generation works
- [ ] Content is relevant and accurate
- [ ] Usage counter increments
- [ ] Limit warnings appear (free account)
- [ ] Blocked at limit (free account)

### ? User Interface
- [ ] Navigation is intuitive
- [ ] All screens load properly
- [ ] Dark mode works (if applicable)
- [ ] Responsive on different screen sizes

### ? Admin Features (Admin Account Only)
- [ ] Admin dashboard accessible
- [ ] User statistics visible
- [ ] Push notifications can be sent
- [ ] System health monitoring works

---

## Account Setup Instructions

### Creating Test Accounts (For App Developers)

If you need to create fresh test accounts:

1. **Sign up through the app**:
   ```
   Email: reviewer-free@ai-stock-summary.test
   Password: PlayReviewer2025!
   Display Name: Play Reviewer (Free)
   ```

2. **Configure in Firebase Console**:
   - Navigate to Firebase Console ? Authentication
   - Manually create user with email/password
   - Set user role in Firestore:
     ```
     users/{userId}
       email: "reviewer-free@ai-stock-summary.test"
       role: "user"
       subscriptionType: "free"
       summariesLimit: 5
       summariesUsed: 0
     ```

3. **Premium account setup**:
   - Same as above, but set:
     ```
     subscriptionType: "premium"
     summariesLimit: 100
     ```

---

## Known Limitations

### Free Account
- **AI Summaries**: Limited to 5 per month
- **Resets**: Counter resets on the 1st of each month
- **Warning**: Shows warning at 4th summary
- **Block**: Cannot generate after reaching limit

### Premium Account
- **AI Summaries**: 100 per month
- **No warning dialogs** until close to limit
- **Same monthly reset** as free users

### Admin Account
- **Unlimited summaries**
- **No usage warnings**
- **Access to admin panel**
- **Can manage all users**

---

## Testing Scenarios

### Scenario 1: New User Experience
1. Sign up with a new account
2. Explore the main stocks list
3. Generate your first AI summary
4. Add stocks to favorites
5. Check usage statistics in settings

### Scenario 2: Usage Limit Testing (Free Account)
1. Sign in with `reviewer-free@ai-stock-summary.test`
2. Generate 4 AI summaries (should work fine)
3. On 5th attempt: Warning dialog appears
4. Continue to generate (5th works)
5. Try 6th: Should be blocked with upgrade prompt

### Scenario 3: Premium Experience
1. Sign in with `reviewer-premium@ai-stock-summary.test`
2. Generate multiple summaries (no early warnings)
3. Check higher limit in settings (100 summaries)
4. Verify all premium features work

### Scenario 4: Admin Features
1. Sign in as admin
2. Access Admin Dashboard
3. View user statistics
4. Send test push notification
5. Verify notification delivery

---

## Troubleshooting

### Issue: Cannot Sign In
- **Solution**: Verify credentials are exactly as shown (case-sensitive)
- **Alternative**: Try creating a new account through the app

### Issue: AI Summary Not Generating
- **Check**: Internet connection is stable
- **Check**: Account hasn't reached monthly limit
- **Solution**: Try again or sign in with different account

### Issue: Push Notifications Not Received
- **Check**: Notification permissions enabled in device settings
- **Check**: App is not in battery optimization mode
- **Solution**: Reinstall app and grant permissions

### Issue: Admin Panel Not Visible
- **Check**: Signed in with correct admin account
- **Solution**: Sign out and sign back in

---

## Privacy & Security Notes

### For Reviewers
- These test accounts contain **no real personal data**
- **No financial transactions** are possible
- All stock data is **informational only**
- Accounts are for **testing purposes only**

### For Developers
- **Do NOT use production credentials** in this document
- Test accounts should have **limited scope** in production
- Consider using **Firebase Test Lab** for automated testing
- **Rotate passwords** regularly for test accounts

---

## Support Contacts

### For Reviewers
If you encounter any issues during review:
- **Email**: erolrony91@gmail.com
- **Response Time**: Within 24 hours
- **Hours**: Mon-Fri, 9 AM - 5 PM EST

### For Developers
- **Firebase Support**: https://firebase.google.com/support
- **Flutter Support**: https://flutter.dev/community
- **Google Play Console**: https://support.google.com/googleplay/android-developer

---

## Document Updates

**Last Updated**: November 3, 2025
**Version**: 1.0
**Status**: Ready for Google Play Review
**Next Review Date**: December 1, 2025

---

## Appendix: Alternative Sign-In Methods

### Google Sign-In (if applicable)
Test accounts with Google OAuth:
- Use any valid Google account
- App will create user profile automatically
- Default to "free" tier

### Anonymous Sign-In (if available)
- No credentials needed
- Limited features
- For testing public features only

---

## Checklist for Submission

Before submitting to Google Play Console:

- [x] Test accounts created and verified
- [x] All credentials documented
- [x] Admin access details provided (privately)
- [x] Testing scenarios outlined
- [x] Known limitations documented
- [x] Support contact information included
- [ ] Upload this document to Google Play Console
- [ ] Add note in "App Access" section pointing to these credentials

---

**Important**: When submitting to Google Play Console, upload this document in the "App Access" section and specifically mention:

```
"Please use the test credentials provided in the attached GOOGLE_PLAY_CONSOLE_CREDENTIALS.md file. 
We have created dedicated reviewer accounts with full access to all app features including:
- Free tier account (limited features)
- Premium tier account (full features)
- Admin access credentials (available separately for security)

All accounts are pre-configured and ready for immediate testing."
```
