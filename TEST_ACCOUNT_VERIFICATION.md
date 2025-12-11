# Test Account Verification Checklist

## Current Test Account
- **Email**: test@test.com
- **Password**: 123456

---

## Pre-Submission Verification

### Step 1: Test Login
- [ ] Open your app on a test device
- [ ] Sign in with test@test.com / 123456
- [ ] Verify login succeeds without errors

### Step 2: Test Core Features
- [ ] Can view stock list on home screen
- [ ] Can tap on a stock to see details
- [ ] Can generate AI summary for a stock
- [ ] Can add stocks to favorites
- [ ] Can view favorites tab
- [ ] Can browse news feed
- [ ] Can access settings/profile
- [ ] Can sign out and sign back in

### Step 3: Check Account Settings (Optional)
Go to Firebase Console to verify:
- [ ] Account exists in Authentication
- [ ] User document exists in Firestore `users/{uid}`
- [ ] Account has proper role/permissions
- [ ] Usage limits are configured (if applicable)

### Step 4: Test on Fresh Install (Important!)
- [ ] Uninstall the app
- [ ] Reinstall from Play Store (internal test track)
- [ ] Sign in with test credentials
- [ ] Verify everything works

---

## Common Issues to Check

### Issue: Login Fails
**Possible causes:**
- Account doesn't exist in Firebase
- Password is incorrect
- Email verification required
- Account is disabled

**Fix:** Check Firebase Console → Authentication → Users

### Issue: Features Don't Work
**Possible causes:**
- User document missing in Firestore
- Insufficient permissions
- API keys not configured
- Backend service issues

**Fix:** Check Firebase Console → Firestore → users collection

### Issue: App Crashes After Login
**Possible causes:**
- Missing user data in Firestore
- Null pointer exceptions
- Required fields not set

**Fix:** Create proper user document with all required fields

---

## Google Play Console Requirements

Your test account MUST meet these requirements:
- ✅ **Active 24/7**: Account must always be accessible
- ✅ **No location restrictions**: Must work from any country
- ✅ **English credentials**: Email and password in English characters
- ✅ **No expiration**: Credentials must remain valid
- ✅ **Full access**: Account can access ALL features
- ✅ **No MFA/2FA**: No two-factor authentication required
- ✅ **No CAPTCHA**: No additional verification steps

---

## Recommended User Configuration in Firestore

Ensure your test account has this structure in Firestore:

**Path**: `users/{uid}`

```javascript
{
  email: "test@test.com",
  displayName: "Test User",
  role: "user",
  subscriptionType: "premium",  // Give full access for testing
  summariesUsed: 0,
  summariesLimit: 100,          // High limit so reviewers can test freely
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastResetDate: Timestamp,
  fcmToken: null,               // Optional
  photoURL: null,               // Optional
  usageHistory: {}              // Optional
}
```

**Why Premium?** 
- Reviewers can test all features without hitting limits
- No interruptions during testing
- Better user experience for reviewers

---

## After Submission

### What Happens Next:
1. **Immediate**: Status changes to "Under review"
2. **Within 1 hour**: You receive email confirmation
3. **1-3 business days**: Google reviews your app
4. **Email notification**: You get approved/rejected notification

### Monitor Your Submission:
- Check Play Console → Publishing overview daily
- Watch for emails from Google Play
- Be ready to respond to any questions

### If Approved:
✅ Your app goes live on Google Play
✅ Users can download and install
✅ You can update anytime

### If Rejected Again:
❌ Read the rejection reason carefully
❌ Fix the specific issue mentioned
❌ Resubmit following their feedback
❌ Contact Play Console support if unclear

---

## Pro Tips

### Tip 1: Test Account Quality
Create a test account that demonstrates your app at its best:
- Give it premium/full access
- Pre-populate with sample favorites (optional)
- Ensure high usage limits
- Make sure all features work

### Tip 2: Clear Instructions
In Play Console, be very explicit:
- Exact email and password
- Step-by-step sign-in process
- What features to test
- Expected behavior

### Tip 3: Alternative Access Methods
If your app supports Google/Facebook sign-in:
- Mention this in the instructions
- Provide dedicated test credentials
- Explain any differences in functionality

### Tip 4: Keep Records
- Screenshot your Play Console configuration
- Document when you submitted
- Save any email correspondence
- Track your submission timeline

---

## Emergency Contact

If reviewers have issues accessing your app:
- They may email you directly
- Respond within 24 hours
- Provide clear troubleshooting steps
- Offer alternative credentials if needed

**Your Support Email**: Make sure this is set in Play Console → Store presence → Contact details

---

## Status Tracking

**Today's Date**: December 11, 2025

- [ ] Test account verified working
- [ ] Credentials added to Play Console
- [ ] Instructions saved in App Access
- [ ] Resubmitted for review
- [ ] Received confirmation email
- [ ] Waiting for review (1-3 days)

---

**Next Action**: Test your account, then configure Play Console!
