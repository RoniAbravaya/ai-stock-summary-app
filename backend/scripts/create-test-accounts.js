/**
 * Create Test Accounts for Google Play Console Review
 * 
 * This script creates reviewer accounts in Firebase Authentication and Firestore
 * for Google Play Console reviewers to test the app.
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
let serviceAccount;
try {
  // Try to load service account key from file
  serviceAccount = require('../../service-account-key.json');
} catch (error) {
  // Fall back to environment variables
  if (process.env.FIREBASE_PROJECT_ID) {
    serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    };
  } else {
    console.error('❌ Firebase credentials not found!');
    console.log('Please either:');
    console.log('1. Place service-account-key.json in backend/ directory');
    console.log('2. Set environment variables: FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL');
    process.exit(1);
  }
}

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.projectId,
  });
}

const auth = admin.auth();
const db = admin.firestore();

// Test account configurations
const testAccounts = [
  {
    email: 'reviewer-free@ai-stock-summary.test',
    password: 'PlayReviewer2025!',
    displayName: 'Play Reviewer (Free)',
    role: 'user',
    subscriptionType: 'free',
    summariesLimit: 5,
  },
  {
    email: 'reviewer-premium@ai-stock-summary.test',
    password: 'PlayReviewer2025!',
    displayName: 'Play Reviewer (Premium)',
    role: 'user',
    subscriptionType: 'premium',
    summariesLimit: 100,
  },
];

/**
 * Create or update a single test account
 */
async function createTestAccount(accountConfig) {
  const { email, password, displayName, role, subscriptionType, summariesLimit } = accountConfig;
  
  try {
    console.log(`\n📝 Processing account: ${email}`);
    
    let userRecord;
    
    // Try to get existing user
    try {
      const existingUser = await auth.getUserByEmail(email);
      console.log(`   ✓ User already exists in Authentication (UID: ${existingUser.uid})`);
      
      // Update password
      await auth.updateUser(existingUser.uid, {
        password: password,
        displayName: displayName,
        emailVerified: true,
      });
      console.log(`   ✓ Password and profile updated`);
      
      userRecord = existingUser;
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // Create new user
        console.log(`   → Creating new user in Authentication...`);
        userRecord = await auth.createUser({
          email: email,
          password: password,
          displayName: displayName,
          emailVerified: true,
        });
        console.log(`   ✓ User created in Authentication (UID: ${userRecord.uid})`);
      } else {
        throw error;
      }
    }
    
    // Create/update Firestore document
    console.log(`   → Updating Firestore document...`);
    const userDoc = db.collection('users').doc(userRecord.uid);
    
    await userDoc.set({
      email: email,
      displayName: displayName,
      role: role,
      subscriptionType: subscriptionType,
      summariesUsed: 0,
      summariesLimit: summariesLimit,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
      photoURL: null,
      fcmToken: null,
      usageHistory: {},
    }, { merge: true });
    
    console.log(`   ✓ Firestore document updated`);
    console.log(`   ✅ Account ready: ${email}`);
    
    return {
      success: true,
      email: email,
      uid: userRecord.uid,
      subscriptionType: subscriptionType,
    };
    
  } catch (error) {
    console.error(`   ❌ Error processing ${email}:`, error.message);
    return {
      success: false,
      email: email,
      error: error.message,
    };
  }
}

/**
 * Main function to create all test accounts
 */
async function createAllTestAccounts() {
  console.log('🚀 Creating Test Accounts for Google Play Console Review');
  console.log('=' .repeat(60));
  
  const results = [];
  
  for (const account of testAccounts) {
    const result = await createTestAccount(account);
    results.push(result);
  }
  
  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('📊 SUMMARY');
  console.log('='.repeat(60));
  
  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);
  
  console.log(`\n✅ Successfully processed: ${successful.length} accounts`);
  successful.forEach(r => {
    console.log(`   - ${r.email} (${r.subscriptionType}) - UID: ${r.uid}`);
  });
  
  if (failed.length > 0) {
    console.log(`\n❌ Failed: ${failed.length} accounts`);
    failed.forEach(r => {
      console.log(`   - ${r.email}: ${r.error}`);
    });
  }
  
  console.log('\n📋 TEST CREDENTIALS FOR GOOGLE PLAY CONSOLE:');
  console.log('='.repeat(60));
  console.log('\nFree Tier Account:');
  console.log(`   Email: reviewer-free@ai-stock-summary.test`);
  console.log(`   Password: PlayReviewer2025!`);
  console.log(`   Features: 5 AI summaries per month`);
  
  console.log('\nPremium Tier Account:');
  console.log(`   Email: reviewer-premium@ai-stock-summary.test`);
  console.log(`   Password: PlayReviewer2025!`);
  console.log(`   Features: 100 AI summaries per month`);
  
  console.log('\n📝 NEXT STEPS:');
  console.log('='.repeat(60));
  console.log('1. Go to Google Play Console');
  console.log('2. Navigate to: Your App → App Access');
  console.log('3. Select "All or some functionality is restricted"');
  console.log('4. Click "Add new instructions" under "App access"');
  console.log('5. Paste the credentials above');
  console.log('6. Add instructions:');
  console.log('   "Sign in with email/password using the test credentials provided."');
  console.log('   "Free account demonstrates usage limits (5 summaries/month)."');
  console.log('   "Premium account shows full functionality (100 summaries/month)."');
  console.log('7. Click "Save"');
  console.log('8. Go to Publishing Overview → Send for Review');
  console.log('\n✅ Done! Your app is ready for resubmission.\n');
}

// Run the script
createAllTestAccounts()
  .then(() => {
    console.log('🎉 Script completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  });
