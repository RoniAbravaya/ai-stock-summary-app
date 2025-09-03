/**
 * Upload AAB to Google Play Console via API
 * 
 * Prerequisites:
 * 1. Enable Google Play Developer API in Google Cloud Console
 * 2. Grant service account access in Play Console → Settings → Users and permissions
 * 3. Service account needs "Release to production, exclude devices, and use app signing by Google Play" permission
 * 
 * Usage:
 *   node scripts/upload-to-play.js <packageName> <aabPath> <serviceAccountPath> [track]
 * 
 * Example:
 *   node scripts/upload-to-play.js com.ai_stock_summary ../mobile-app/build/app/outputs/bundle/release/app-release.aab ../new-flutter-ai-17d01d151231.json internal
 */

const fs = require('fs');
const path = require('path');
const { google } = require('googleapis');

async function main() {
  const packageName = process.argv[2];
  const aabPath = process.argv[3];
  const serviceAccountPath = process.argv[4];
  const track = process.argv[5] || 'internal'; // internal, alpha, beta, production

  if (!packageName || !aabPath || !serviceAccountPath) {
    console.error('Usage: node scripts/upload-to-play.js <packageName> <aabPath> <serviceAccountPath> [track]');
    console.error('Example: node scripts/upload-to-play.js com.ai_stock_summary ../mobile-app/build/app/outputs/bundle/release/app-release.aab ../new-flutter-ai-17d01d151231.json internal');
    process.exit(1);
  }

  if (!fs.existsSync(aabPath)) {
    console.error(`AAB file not found: ${aabPath}`);
    process.exit(1);
  }

  if (!fs.existsSync(serviceAccountPath)) {
    console.error(`Service account JSON not found: ${serviceAccountPath}`);
    process.exit(1);
  }

  try {
    console.log('🔐 Authenticating with Google Play Console...');
    
    // Load service account credentials
    const credentials = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    
    // Create auth client
    const auth = new google.auth.GoogleAuth({
      credentials,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
    
    // Create Play Developer API client
    const androidPublisher = google.androidpublisher({ version: 'v3', auth });
    
    console.log('📝 Creating edit session...');
    
    // Create an edit session
    const editResponse = await androidPublisher.edits.insert({
      packageName: packageName,
    });
    
    const editId = editResponse.data.id;
    console.log(`✅ Edit session created: ${editId}`);
    
    console.log('📦 Uploading AAB...');
    
    // Upload the AAB
    const uploadResponse = await androidPublisher.edits.bundles.upload({
      packageName: packageName,
      editId: editId,
      media: {
        mimeType: 'application/octet-stream',
        body: fs.createReadStream(aabPath),
      },
    });
    
    const versionCode = uploadResponse.data.versionCode;
    console.log(`✅ AAB uploaded successfully. Version code: ${versionCode}`);
    
    console.log(`🚀 Assigning to ${track} track...`);
    
    // Assign to track
    await androidPublisher.edits.tracks.update({
      packageName: packageName,
      editId: editId,
      track: track,
      requestBody: {
        releases: [
          {
            versionCodes: [versionCode.toString()],
            status: 'draft',
            releaseNotes: [
              {
                language: 'en-US',
                text: 'Initial release with Play Integrity support and Firebase integration.',
              },
            ],
          },
        ],
      },
    });
    
    console.log(`✅ Assigned to ${track} track`);
    
    console.log('💾 Committing changes...');
    
    // Commit the edit
    await androidPublisher.edits.commit({
      packageName: packageName,
      editId: editId,
    });
    
    console.log('🎉 Upload completed successfully!');
    console.log(`📱 Package: ${packageName}`);
    console.log(`📦 Version: ${versionCode}`);
    console.log(`🛤️  Track: ${track}`);
    console.log('');
    console.log('Next steps:');
    console.log('1. Go to Play Console to review the release');
    console.log('2. Add app content, data safety, and other required info');
    console.log('3. Submit for review when ready');
    
  } catch (error) {
    console.error('❌ Upload failed:', error.message);
    
    if (error.code === 403) {
      console.error('');
      console.error('🔑 Permission denied. Make sure:');
      console.error('1. Google Play Developer API is enabled in Google Cloud');
      console.error('2. Service account has access in Play Console → Settings → Users and permissions');
      console.error('3. Service account has "Release to production" permission');
    }
    
    if (error.code === 404) {
      console.error('');
      console.error('📱 App not found. Make sure:');
      console.error('1. Package name is correct');
      console.error('2. App exists in Play Console');
      console.error('3. Service account has access to this specific app');
    }
    
    process.exit(1);
  }
}

main().catch(console.error);
