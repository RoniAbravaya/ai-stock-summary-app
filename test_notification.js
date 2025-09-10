// Test script to manually send a push notification
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin (you'll need your service account key)
const serviceAccount = require('./new-flutter-ai-17d01d151231.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://new-flutter-ai-default-rtdb.firebaseio.com'
});

async function testNotification() {
  try {
    const db = getFirestore(admin.app(), 'flutter-database');
    const messaging = admin.messaging();

    // Get a user's FCM token
    const usersSnapshot = await db.collection('users').limit(1).get();
    
    if (usersSnapshot.empty) {
      console.log('No users found');
      return;
    }

    const userData = usersSnapshot.docs[0].data();
    if (!userData.fcmToken) {
      console.log('No FCM token found for user');
      return;
    }

    console.log(`Sending test notification to: ${userData.email}`);
    console.log(`FCM Token: ${userData.fcmToken.substring(0, 20)}...`);

    // Send the notification
    const message = {
      notification: {
        title: 'Test Notification',
        body: 'This is a test from the manual script'
      },
      token: userData.fcmToken
    };

    const response = await messaging.send(message);
    console.log('✅ Notification sent successfully:', response);

  } catch (error) {
    console.error('❌ Error sending notification:', error);
  }
}

testNotification();
