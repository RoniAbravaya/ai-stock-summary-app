#!/usr/bin/env node

/**
 * FCM Token Health Check Script
 * 
 * This script checks the health of FCM tokens across all users in the database
 * and provides options to trigger token refresh for users without tokens.
 * 
 * Usage:
 * node scripts/fcm-token-health-check.js [options]
 * 
 * Options:
 * --check-only    Only check token health, don't attempt fixes
 * --trigger-refresh    Trigger FCM token refresh for users without tokens
 * --verbose       Show detailed information about each user
 * --help          Show this help message
 */

const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

// Initialize Firebase Admin SDK
function initializeFirebase() {
  try {
    // Try to initialize with service account key
    const serviceAccountPath = path.join(__dirname, '../scripts/new-flutter-ai-17d01d151231.json');
    
    if (require('fs').existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: 'https://new-flutter-ai-default-rtdb.firebaseio.com'
      });
      
      console.log('✅ Firebase Admin SDK initialized with service account');
    } else {
      // Fallback to environment variables
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        databaseURL: 'https://new-flutter-ai-default-rtdb.firebaseio.com'
      });
      
      console.log('✅ Firebase Admin SDK initialized with application default credentials');
    }
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    process.exit(1);
  }
}

// Check FCM token health for all users
async function checkFCMTokenHealth(verbose = false) {
  try {
    console.log('🔍 Checking FCM token health for all users...');
    
    const db = getFirestore(admin.app(), 'flutter-database');
    const usersCollection = db.collection('users');
    const usersSnapshot = await usersCollection.get();

    const stats = {
      totalUsers: 0,
      usersWithTokens: 0,
      usersWithoutTokens: 0,
      usersWithoutTokensList: [],
      recentTokenUpdates: [],
      oldTokens: []
    };

    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000));

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      const userId = doc.id;
      
      stats.totalUsers++;
      
      if (userData.fcmToken && userData.fcmToken.trim() !== '') {
        stats.usersWithTokens++;
        
        // Check token age
        if (userData.fcmTokenUpdatedAt) {
          const updatedAt = userData.fcmTokenUpdatedAt.toDate ? 
            userData.fcmTokenUpdatedAt.toDate() : 
            new Date(userData.fcmTokenUpdatedAt);
          
          const tokenInfo = {
            email: userData.email || 'No email',
            userId: userId,
            updatedAt: updatedAt.toISOString(),
            tokenPrefix: userData.fcmToken.substring(0, 20) + '...',
            daysOld: Math.floor((now - updatedAt) / (1000 * 60 * 60 * 24))
          };
          
          if (updatedAt > thirtyDaysAgo) {
            stats.recentTokenUpdates.push(tokenInfo);
          } else {
            stats.oldTokens.push(tokenInfo);
          }
        }
        
        if (verbose) {
          console.log(`✅ ${userData.email || userId}: Has FCM token`);
        }
      } else {
        stats.usersWithoutTokens++;
        const userInfo = {
          userId: userId,
          email: userData.email || 'No email',
          displayName: userData.displayName || 'No display name',
          createdAt: userData.createdAt ? 
            (userData.createdAt.toDate ? userData.createdAt.toDate().toISOString() : userData.createdAt) : 
            'Unknown',
          role: userData.role || 'user'
        };
        
        stats.usersWithoutTokensList.push(userInfo);
        
        if (verbose) {
          console.log(`❌ ${userData.email || userId}: Missing FCM token`);
        }
      }
    });

    // Sort arrays
    stats.recentTokenUpdates.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    stats.oldTokens.sort((a, b) => a.daysOld - b.daysOld);

    return stats;
  } catch (error) {
    console.error('❌ Error checking FCM token health:', error.message);
    throw error;
  }
}

// Trigger FCM token refresh for users without tokens
async function triggerFCMTokenRefresh(usersWithoutTokens) {
  try {
    console.log(`🔄 Triggering FCM token refresh for ${usersWithoutTokens.length} users...`);
    
    if (usersWithoutTokens.length === 0) {
      console.log('✅ No users need FCM token refresh');
      return { success: true, message: 'No users need refresh' };
    }

    const db = getFirestore(admin.app(), 'flutter-database');
    const batch = db.batch();
    
    // Mark users for FCM token refresh
    usersWithoutTokens.forEach(user => {
      const userRef = db.collection('users').doc(user.userId);
      batch.update(userRef, {
        fcmTokenRefreshRequested: true,
        fcmTokenRefreshRequestedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();

    // Create an admin notification to inform about the refresh request
    const notificationRef = db.collection('admin_notifications').doc();
    await notificationRef.set({
      title: 'FCM Token Refresh Requested',
      message: `Requested FCM token refresh for ${usersWithoutTokens.length} users. Users will get new tokens on next app launch.`,
      target: 'admin_system',
      sentBy: 'fcm_health_script',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      processed: false,
      processing: false,
      metadata: {
        affectedUserCount: usersWithoutTokens.length,
        scriptTriggered: true
      }
    });

    console.log(`✅ Successfully marked ${usersWithoutTokens.length} users for FCM token refresh`);
    return { 
      success: true, 
      message: `Marked ${usersWithoutTokens.length} users for refresh`,
      affectedUsers: usersWithoutTokens.length
    };
    
  } catch (error) {
    console.error('❌ Error triggering FCM token refresh:', error.message);
    throw error;
  }
}

// Display help message
function showHelp() {
  console.log(`
FCM Token Health Check Script

Usage: node scripts/fcm-token-health-check.js [options]

Options:
  --check-only        Only check token health, don't attempt fixes
  --trigger-refresh   Trigger FCM token refresh for users without tokens  
  --verbose          Show detailed information about each user
  --help             Show this help message

Examples:
  node scripts/fcm-token-health-check.js --check-only
  node scripts/fcm-token-health-check.js --trigger-refresh
  node scripts/fcm-token-health-check.js --verbose --trigger-refresh
  `);
}

// Main function
async function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--help')) {
    showHelp();
    return;
  }

  const checkOnly = args.includes('--check-only');
  const triggerRefresh = args.includes('--trigger-refresh');
  const verbose = args.includes('--verbose');

  try {
    // Initialize Firebase
    initializeFirebase();

    // Check FCM token health
    const stats = await checkFCMTokenHealth(verbose);

    // Display results
    console.log('\n📊 FCM Token Health Report');
    console.log('=' .repeat(50));
    console.log(`Total Users: ${stats.totalUsers}`);
    console.log(`Users with FCM Tokens: ${stats.usersWithTokens} (${((stats.usersWithTokens/stats.totalUsers)*100).toFixed(1)}%)`);
    console.log(`Users without FCM Tokens: ${stats.usersWithoutTokens} (${((stats.usersWithoutTokens/stats.totalUsers)*100).toFixed(1)}%)`);
    console.log(`Recent Token Updates (last 30 days): ${stats.recentTokenUpdates.length}`);
    console.log(`Old Tokens (>30 days): ${stats.oldTokens.length}`);

    if (stats.usersWithoutTokens > 0) {
      console.log('\n❌ Users without FCM tokens:');
      stats.usersWithoutTokensList.forEach(user => {
        console.log(`  - ${user.email} (${user.role}) - Created: ${user.createdAt}`);
      });
    }

    if (stats.oldTokens.length > 0 && verbose) {
      console.log('\n⚠️ Users with old FCM tokens (>30 days):');
      stats.oldTokens.slice(0, 5).forEach(token => {
        console.log(`  - ${token.email} - ${token.daysOld} days old`);
      });
      if (stats.oldTokens.length > 5) {
        console.log(`  ... and ${stats.oldTokens.length - 5} more`);
      }
    }

    // Trigger refresh if requested and needed
    if (triggerRefresh && !checkOnly && stats.usersWithoutTokens > 0) {
      console.log('\n🔄 Triggering FCM token refresh...');
      const refreshResult = await triggerFCMTokenRefresh(stats.usersWithoutTokensList);
      
      if (refreshResult.success) {
        console.log(`✅ ${refreshResult.message}`);
        console.log('\n📱 Next steps:');
        console.log('- Users will get FCM tokens when they next launch the app');
        console.log('- Monitor the admin notifications for refresh status');
        console.log('- Run this script again in a few hours to verify improvements');
      }
    } else if (triggerRefresh && stats.usersWithoutTokens === 0) {
      console.log('\n✅ All users already have FCM tokens - no refresh needed');
    } else if (!triggerRefresh && stats.usersWithoutTokens > 0) {
      console.log('\n💡 To fix missing tokens, run:');
      console.log('node scripts/fcm-token-health-check.js --trigger-refresh');
    }

    console.log('\n✅ FCM token health check completed');
    
  } catch (error) {
    console.error('❌ Script failed:', error.message);
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  main().then(() => {
    process.exit(0);
  }).catch((error) => {
    console.error('❌ Unhandled error:', error);
    process.exit(1);
  });
}

module.exports = {
  checkFCMTokenHealth,
  triggerFCMTokenRefresh,
  initializeFirebase
};
