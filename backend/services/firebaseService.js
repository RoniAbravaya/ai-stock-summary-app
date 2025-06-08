/**
 * Firebase Admin SDK Service
 * Handles Firebase authentication, Firestore, and other Firebase services
 */

const admin = require('firebase-admin');

class FirebaseService {
  constructor() {
    this.isInitialized = false;
    this.init();
  }

  init() {
    if (this.isInitialized) {
      return;
    }

    try {
      // Check if running in Cloud Run
      if (process.env.K_SERVICE) {
        // In Cloud Run, use the default credentials
        admin.initializeApp({
          projectId: process.env.FIREBASE_CONFIG ? JSON.parse(process.env.FIREBASE_CONFIG).projectId : undefined,
          databaseURL: process.env.FIREBASE_CONFIG ? JSON.parse(process.env.FIREBASE_CONFIG).databaseURL : undefined,
          storageBucket: process.env.FIREBASE_CONFIG ? JSON.parse(process.env.FIREBASE_CONFIG).storageBucket : undefined
        });
      } else {
        // Local development - use service account
        if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_PRIVATE_KEY || !process.env.FIREBASE_CLIENT_EMAIL) {
          console.warn('⚠️ Firebase credentials not configured. Skipping Firebase initialization.');
          console.warn('📝 Please configure Firebase environment variables in .env file to enable Firebase features.');
          return;
        }

        const serviceAccount = {
          type: 'service_account',
          project_id: process.env.FIREBASE_PROJECT_ID,
          private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
          private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          client_email: process.env.FIREBASE_CLIENT_EMAIL,
          client_id: process.env.FIREBASE_CLIENT_ID,
          auth_uri: process.env.FIREBASE_AUTH_URI || 'https://accounts.google.com/o/oauth2/auth',
          token_uri: process.env.FIREBASE_TOKEN_URI || 'https://oauth2.googleapis.com/token',
          auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
          client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${encodeURIComponent(process.env.FIREBASE_CLIENT_EMAIL)}`
        };

        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          databaseURL: process.env.FIREBASE_DATABASE_URL,
          storageBucket: process.env.FIREBASE_STORAGE_BUCKET
        });
      }

      this.isInitialized = true;
      console.log('✅ Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
      console.error('Error details:', error);
      console.warn('⚠️ Continuing without Firebase. Some features may not work.');
    }
  }

  // ... rest of the class implementation stays the same ...
}