#!/usr/bin/env node
/**
 * Admin Claim Seeder Script
 *
 * Usage:
 *   node scripts/set-admin-claims.js user1@example.com user2@example.com
 *
 * Alternatively, provide a comma-separated list of emails via the
 * ADMIN_EMAIL_ALLOWLIST environment variable.
 *
 * Requirements:
 * - Firebase Admin credentials must be configured via environment variables
 *   (FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL, etc).
 * - Users must already exist in Firebase Authentication.
 */

const firebaseService = require('../services/firebaseService');

async function main() {
  const auth = firebaseService.auth;
  const firestore = firebaseService.firestore;

  if (!firebaseService.isInitialized || !auth) {
    console.error('❌ Firebase Admin SDK is not initialized.');
    console.error('   Ensure Firebase credentials are configured before running this script.');
    process.exit(1);
  }

  const cliEmails = process.argv.slice(2).filter((email) => email.includes('@'));
  const envEmails = (process.env.ADMIN_EMAIL_ALLOWLIST || '')
    .split(',')
    .map((email) => email.trim())
    .filter((email) => email.length > 0);

  const emailSet = new Set([...cliEmails, ...envEmails].map((email) => email.toLowerCase()));

  if (emailSet.size === 0) {
    console.error('❌ No admin emails provided.');
    console.error('   Pass emails as CLI arguments or set ADMIN_EMAIL_ALLOWLIST.');
    process.exit(1);
  }

  console.log('🔐 Updating custom admin claims for the following emails:');
  for (const email of emailSet) {
    console.log(`   • ${email}`);
  }

  const admin = firebaseService.admin;
  const FieldValue = admin.firestore.FieldValue;

  const successes = [];
  const failures = [];

  for (const email of emailSet) {
    try {
      const userRecord = await auth.getUserByEmail(email);
      const existingClaims = userRecord.customClaims || {};
      if (existingClaims.admin === true) {
        console.log(`ℹ️ ${email} already has admin claim. Skipping.`);
      } else {
        await auth.setCustomUserClaims(userRecord.uid, {
          ...existingClaims,
          admin: true,
        });
        console.log(`✅ Set admin claim for ${email}`);
      }

      if (firestore) {
        await firestore.collection('users').doc(userRecord.uid).set(
          {
            role: 'admin',
            updatedAt: FieldValue.serverTimestamp(),
            adminClaimUpdatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        console.log(`   ↳ Updated Firestore role for ${email}`);
      }

      successes.push(email);
    } catch (error) {
      console.error(`❌ Failed to set admin claim for ${email}: ${error.message}`);
      failures.push({ email, error: error.message });
    }
  }

  console.log('\n📊 Summary');
  console.log(`   ✔️ Succeeded: ${successes.length}`);
  console.log(`   ❌ Failed: ${failures.length}`);

  if (failures.length > 0) {
    failures.forEach(({ email, error }) => {
      console.log(`   - ${email}: ${error}`);
    });
    process.exitCode = 1;
  } else {
    console.log('   All admin claims applied successfully.');
  }
}

main().catch((error) => {
  console.error('❌ Unexpected error while setting admin claims:', error);
  process.exit(1);
});
