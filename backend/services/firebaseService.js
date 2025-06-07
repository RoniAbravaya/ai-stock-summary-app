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
      // Check if Firebase credentials are configured
      if (!process.env.FIREBASE_PROJECT_ID || !process.env.FIREBASE_PRIVATE_KEY || !process.env.FIREBASE_CLIENT_EMAIL) {
        console.warn('⚠️ Firebase credentials not configured. Skipping Firebase initialization.');
        console.warn('📝 Please configure Firebase environment variables in .env file to enable Firebase features.');
        return;
      }

      // Initialize Firebase Admin with environment variables
      const serviceAccount = {
        type: 'service_account',
        project_id: process.env.FIREBASE_PROJECT_ID,
        private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
        private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
        client_id: process.env.FIREBASE_CLIENT_ID,
        auth_uri: process.env.FIREBASE_AUTH_URI,
        token_uri: process.env.FIREBASE_TOKEN_URI,
        auth_provider_x509_cert_url: `https://www.googleapis.com/oauth2/v1/certs`,
        client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${process.env.FIREBASE_CLIENT_EMAIL}`
      };

      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: process.env.FIREBASE_DATABASE_URL,
        storageBucket: process.env.FIREBASE_STORAGE_BUCKET
      });

      this.isInitialized = true;
      console.log('✅ Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
      console.warn('⚠️ Continuing without Firebase. Some features may not work.');
    }
  }

  // Firestore instance
  get firestore() {
    return admin.firestore();
  }

  // Authentication instance
  get auth() {
    return admin.auth();
  }

  // Storage instance
  get storage() {
    return admin.storage();
  }

  // Realtime Database instance
  get database() {
    return admin.database();
  }

  // Messaging instance
  get messaging() {
    return admin.messaging();
  }

  /**
   * Verify Firebase ID token
   * @param {string} idToken - Firebase ID token
   * @returns {Promise<Object>} Decoded token
   */
  async verifyIdToken(idToken) {
    try {
      const decodedToken = await this.auth.verifyIdToken(idToken);
      return decodedToken;
    } catch (error) {
      console.error('Error verifying ID token:', error);
      throw new Error('Invalid token');
    }
  }

  /**
   * Set custom claims for a user (e.g., admin role)
   * @param {string} uid - User UID
   * @param {Object} claims - Custom claims to set
   */
  async setCustomClaims(uid, claims) {
    try {
      await this.auth.setCustomUserClaims(uid, claims);
      console.log(`✅ Custom claims set for user ${uid}:`, claims);
    } catch (error) {
      console.error('Error setting custom claims:', error);
      throw error;
    }
  }

  /**
   * Create a new user
   * @param {Object} userData - User data
   * @returns {Promise<Object>} Created user record
   */
  async createUser(userData) {
    try {
      const userRecord = await this.auth.createUser(userData);
      
      // Create user document in Firestore
      await this.firestore.collection('users').doc(userRecord.uid).set({
        email: userData.email,
        displayName: userData.displayName || null,
        photoURL: userData.photoURL || null,
        role: 'user',
        subscriptionType: 'free',
        summariesUsed: 0,
        summariesLimit: 10,
        lastResetDate: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return userRecord;
    } catch (error) {
      console.error('Error creating user:', error);
      throw error;
    }
  }

  /**
   * Send push notification
   * @param {string} token - FCM token
   * @param {Object} notification - Notification payload
   */
  async sendPushNotification(token, notification) {
    try {
      const message = {
        token: token,
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: notification.data || {}
      };

      const response = await this.messaging.send(message);
      console.log('✅ Push notification sent successfully:', response);
      return response;
    } catch (error) {
      console.error('Error sending push notification:', error);
      throw error;
    }
  }

  /**
   * Send push notification to multiple tokens
   * @param {Array} tokens - Array of FCM tokens
   * @param {Object} notification - Notification payload
   */
  async sendMulticastNotification(tokens, notification) {
    try {
      const message = {
        tokens: tokens,
        notification: {
          title: notification.title,
          body: notification.body
        },
        data: notification.data || {}
      };

      const response = await this.messaging.sendMulticast(message);
      console.log('✅ Multicast notification sent:', response);
      return response;
    } catch (error) {
      console.error('Error sending multicast notification:', error);
      throw error;
    }
  }
}

// Export singleton instance
module.exports = new FirebaseService(); 