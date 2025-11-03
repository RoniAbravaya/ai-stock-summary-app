# Creating Test Accounts for Google Play Console Review

## Quick Setup Guide

This guide will help you create test accounts for Google Play Console reviewers to access your app.

---

## Option 1: Using Firebase Console (Recommended)

### Step 1: Create Authentication Users

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `new-flutter-ai`
3. Navigate to **Authentication** ? **Users**
4. Click **Add User**

#### Free User Account
- **Email**: `reviewer-free@ai-stock-summary.test`
- **Password**: `PlayReviewer2025!`
- Click **Add User**
- Copy the UID (you'll need it next)

#### Premium User Account
- **Email**: `reviewer-premium@ai-stock-summary.test`
- **Password**: `PlayReviewer2025!`
- Click **Add User**
- Copy the UID

### Step 2: Create Firestore User Documents

1. Navigate to **Firestore Database**
2. Select database: `flutter-database` (or default if different)
3. Go to the `users` collection

#### For Free User
Click **Add Document**:
- **Document ID**: [Paste the UID from Step 1]
- **Fields**:
  ```
  email (string): reviewer-free@ai-stock-summary.test
  displayName (string): Play Reviewer (Free)
  role (string): user
  subscriptionType (string): free
  summariesUsed (number): 0
  summariesLimit (number): 5
  createdAt (timestamp): [Auto]
  updatedAt (timestamp): [Auto]
  lastResetDate (timestamp): [Auto]
  ```

#### For Premium User
Click **Add Document**:
- **Document ID**: [Paste the UID from Step 1]
- **Fields**:
  ```
  email (string): reviewer-premium@ai-stock-summary.test
  displayName (string): Play Reviewer (Premium)
  role (string): user
  subscriptionType (string): premium
  summariesUsed (number): 0
  summariesLimit (number): 100
  createdAt (timestamp): [Auto]
  updatedAt (timestamp): [Auto]
  lastResetDate (timestamp): [Auto]
  ```

---

## Option 2: Using Firebase CLI

### Prerequisites
```bash
npm install -g firebase-tools
firebase login
firebase use new-flutter-ai
```

### Create Script

Create a file `create-test-accounts.js`:

```javascript
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./service-account-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

async function createTestAccounts() {
  console.log('?? Creating test accounts for Google Play reviewers...');

  try {
    // Create Free User
    console.log('?? Creating free user account...');
    const freeUser = await auth.createUser({
      email: 'reviewer-free@ai-stock-summary.test',
      password: 'PlayReviewer2025!',
      displayName: 'Play Reviewer (Free)',
      emailVerified: true,
    });

    await db.collection('users').doc(freeUser.uid).set({
      email: 'reviewer-free@ai-stock-summary.test',
      displayName: 'Play Reviewer (Free)',
      role: 'user',
      subscriptionType: 'free',
      summariesUsed: 0,
      summariesLimit: 5,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('? Free user created:', freeUser.uid);

    // Create Premium User
    console.log('?? Creating premium user account...');
    const premiumUser = await auth.createUser({
      email: 'reviewer-premium@ai-stock-summary.test',
      password: 'PlayReviewer2025!',
      displayName: 'Play Reviewer (Premium)',
      emailVerified: true,
    });

    await db.collection('users').doc(premiumUser.uid).set({
      email: 'reviewer-premium@ai-stock-summary.test',
      displayName: 'Play Reviewer (Premium)',
      role: 'user',
      subscriptionType: 'premium',
      summariesUsed: 0,
      summariesLimit: 100,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('? Premium user created:', premiumUser.uid);

    console.log('? All test accounts created successfully!');
    console.log('\nTest Accounts:');
    console.log('- Free: reviewer-free@ai-stock-summary.test / PlayReviewer2025!');
    console.log('- Premium: reviewer-premium@ai-stock-summary.test / PlayReviewer2025!');
    
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('??  Accounts already exist. To recreate, delete them first.');
    } else {
      console.error('? Error creating test accounts:', error);
    }
  }

  process.exit(0);
}

createTestAccounts();
```

### Run Script
```bash
node create-test-accounts.js
```

---

## Option 3: Using the Mobile App (Manual)

### Free User Account
1. Open the app
2. Tap "Sign Up"
3. Enter:
   - Email: `reviewer-free@ai-stock-summary.test`
   - Password: `PlayReviewer2025!`
   - Display Name: `Play Reviewer (Free)`
4. Sign up
5. **Note**: Account will be created with default "free" tier automatically

### Premium User Account
1. Sign up as above with:
   - Email: `reviewer-premium@ai-stock-summary.test`
   - Password: `PlayReviewer2025!`
   - Display Name: `Play Reviewer (Premium)`
2. After creation, manually update in Firestore:
   - Go to Firebase Console ? Firestore
   - Find the user document
   - Update `subscriptionType` to `"premium"`
   - Update `summariesLimit` to `100`

---

## Verification Checklist

After creating accounts, verify:

### Test Free Account
- [ ] Can sign in with credentials
- [ ] Shows 0/5 summaries in settings
- [ ] Can generate AI summary
- [ ] Counter increments after generation
- [ ] Shows warning at 4th summary
- [ ] Blocks at 5th summary

### Test Premium Account
- [ ] Can sign in with credentials
- [ ] Shows 0/100 summaries in settings
- [ ] Can generate multiple summaries
- [ ] No early warning dialogs
- [ ] Higher limit visible

### Both Accounts
- [ ] Can view stock data
- [ ] Can add favorites
- [ ] Can receive push notifications
- [ ] Settings load properly
- [ ] Sign out works

---

## Resetting Test Accounts

### Reset Usage Counters
```javascript
// In Firebase Console or CLI
await db.collection('users').doc(USER_UID).update({
  summariesUsed: 0,
  lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
});
```

### Reset Password
```bash
# Using Firebase CLI
firebase auth:reset-password reviewer-free@ai-stock-summary.test
```

### Delete and Recreate
```javascript
// Delete user
await admin.auth().deleteUser(USER_UID);
await db.collection('users').doc(USER_UID).delete();

// Then recreate using steps above
```

---

## Security Notes

### For Production
- ??  **Never commit passwords** to version control
- ??  Use **different passwords** for test vs production
- ??  **Rotate passwords** regularly
- ??  Consider using **Firebase Test Lab** for automated testing

### For Test Accounts
- ? Use isolated test emails
- ? Set strong but memorable passwords
- ? Mark accounts as "test" in Firestore (optional field)
- ? Limit production data access

---

## Troubleshooting

### Error: Email already exists
**Solution**: Delete existing user first, then recreate

### Error: Invalid password
**Solution**: Password must be at least 6 characters

### Error: Permission denied
**Solution**: Check Firebase security rules allow account creation

### Error: Firestore document not created
**Solution**: 
1. Check database name is correct (`flutter-database`)
2. Verify service account has Firestore permissions
3. Check security rules allow writes

---

## Next Steps

After creating test accounts:

1. **Test them yourself** first
2. **Document in GOOGLE_PLAY_CONSOLE_CREDENTIALS.md**
3. **Upload to Google Play Console** in "App Access" section
4. **Verify reviewers can access** all features

---

## Quick Reference

### Test Account Credentials
```
Free User:
  Email: reviewer-free@ai-stock-summary.test
  Password: PlayReviewer2025!
  Limit: 5 AI summaries/month

Premium User:
  Email: reviewer-premium@ai-stock-summary.test
  Password: PlayReviewer2025!
  Limit: 100 AI summaries/month
```

### Firebase Collections
```
Authentication ? Users
Firestore ? flutter-database ? users ? [UID]
```

### Support
- Firebase Console: https://console.firebase.google.com/
- Documentation: https://firebase.google.com/docs/auth
- Support: https://firebase.google.com/support

---

**Status**: Ready to Create
**Last Updated**: November 3, 2025
